import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';

class AiAgentClassification {
  const AiAgentClassification({
    required this.category,
    required this.assignedAgent,
    required this.agentTitle,
    required this.department,
    required this.slaHours,
    required this.priority,
    required this.confidenceScore,
    required this.provider,
    this.reasoning = '',
  });

  factory AiAgentClassification.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('AI response is missing $key.');
      }
      return value;
    }

    final sla = json['slaHours'];
    final confidence = json['confidence_score'] ?? json['confidenceScore'];
    final provider = json['provider'];
    if (sla is! num ||
        (confidence != null && confidence is! num) ||
        provider is! String ||
        provider.trim().isEmpty) {
      throw const FormatException(
        'AI response has invalid SLA, provider, or confidence values.',
      );
    }
    return AiAgentClassification(
      category: requiredString('category'),
      assignedAgent: requiredString('assignedAgent'),
      agentTitle: requiredString('agentTitle'),
      department: requiredString('department'),
      slaHours: sla.toInt(),
      priority: requiredString('priority'),
      confidenceScore: confidence is num ? confidence.toDouble() : null,
      provider: provider,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  final String category;
  final String assignedAgent;
  final String agentTitle;
  final String department;
  final int slaHours;
  final String priority;
  final double? confidenceScore;
  final String provider;

  Map<String, dynamic> toJson() => {
    'category': category,
    'assignedAgent': assignedAgent,
    'agentTitle': agentTitle,
    'department': department,
    'slaHours': slaHours,
    'priority': priority,
    'provider': provider,
    if (confidenceScore != null) 'confidenceScore': confidenceScore,
    if (reasoning.isNotEmpty) 'reasoning': reasoning,
  };
  final String reasoning;
}

class ImageAnalysisResult {
  const ImageAnalysisResult({
    required this.imageDescription,
    required this.suggestedTitles,
    required this.autoDescription,
    required this.detectedDefectType,
    required this.classification,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    final titles = json['suggestedTitles'];
    final classification = json['classification'];
    if (titles is! List ||
        titles.isEmpty ||
        classification is! Map<String, dynamic>) {
      throw const FormatException('AI image analysis response is incomplete.');
    }
    return ImageAnalysisResult(
      imageDescription: _requiredString(json, 'imageDescription'),
      suggestedTitles: titles.map((value) => value.toString()).toList(),
      autoDescription: _requiredString(json, 'autoDescription'),
      detectedDefectType: _requiredString(json, 'detectedDefectType'),
      classification: AiAgentClassification.fromJson(classification),
    );
  }

  final String imageDescription;
  final List<String> suggestedTitles;
  final String autoDescription;
  final String detectedDefectType;
  final AiAgentClassification classification;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Service response is missing $key.');
  }
  return value;
}

class RunixAiService {
  RunixAiService({Dio? dio})
    : _dio = ApiClientConfig.attach(
        dio ??
            Dio(
              BaseOptions(
                baseUrl: '${ApiClientConfig.baseUrl}/ai',
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: {'Content-Type': 'application/json'},
              ),
            ),
      );

  final Dio _dio;

  Options get _authOptions {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty)
      throw StateError('Sign in to use AI services.');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<ImageAnalysisResult> analyzeImage({
    String? fileName,
    String? mimeType,
    String? defectHint,
    String? base64Data,
    String? district,
    String? stateCode,
  }) async {
    if (base64Data == null || base64Data.isEmpty)
      throw ArgumentError('Image data is required.');
    final state = stateCode ?? SessionManager.instance.stateCode;
    final location = district ?? SessionManager.instance.district;
    if (state == null ||
        state.isEmpty ||
        location == null ||
        location.isEmpty) {
      throw StateError(
        'Set your state and district before requesting image analysis.',
      );
    }
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/analyze-image',
        data: {
          'fileName': fileName,
          'mimeType': mimeType,
          'defectHint': defectHint,
          'base64Data': base64Data,
          'district': location,
          'stateCode': state,
        },
        options: _authOptions,
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map<String, dynamic> && body['message'] is String
          ? body['message'] as String
          : 'IRM request failed (${error.response?.statusCode ?? 'network error'}).';
      throw StateError(message);
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>)
      throw const FormatException(
        'AI service returned an invalid image analysis response.',
      );
    return ImageAnalysisResult.fromJson(data);
  }

  Future<List<String>> getTitleSuggestions({
    required String contextText,
  }) async {
    if (contextText.trim().isEmpty)
      throw ArgumentError('Complaint details are required.');
    final response = await _dio.post<Map<String, dynamic>>(
      '/suggest-titles',
      data: {'contextText': contextText},
      options: _authOptions,
    );
    final titles = (response.data?['data'] as Map?)?['titles'];
    if (titles is! List || titles.isEmpty)
      throw const FormatException('AI service returned no title suggestions.');
    return titles.map((value) => value.toString()).toList();
  }

  Future<String> autoGenerateDescription({
    required String title,
    String? imageDescription,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/generate-description',
      data: {'title': title, 'imageDescription': imageDescription},
      options: _authOptions,
    );
    final data = response.data?['data'];
    if (data is! Map)
      throw const FormatException(
        'AI service returned an invalid description response.',
      );
    return _requiredString(Map<String, dynamic>.from(data), 'description');
  }

  Future<AiAgentClassification> classifyGrievance({
    required String title,
    required String description,
    String? district,
    String? stateCode,
  }) async {
    final location = district ?? SessionManager.instance.district;
    final state = stateCode ?? SessionManager.instance.stateCode;
    if (location == null ||
        location.isEmpty ||
        state == null ||
        state.isEmpty) {
      throw StateError(
        'Set your state and district before requesting classification.',
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/classify',
      data: {
        'title': title,
        'description': description,
        'district': location,
        'stateCode': state,
      },
      options: _authOptions,
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>)
      throw const FormatException(
        'AI service returned an invalid classification.',
      );
    final metadata = response.data?['metadata'];
    final provider = metadata is Map<String, dynamic>
        ? metadata['provider']
        : null;
    if (provider is! String || provider.isEmpty) {
      throw const FormatException('AI service did not identify the provider.');
    }
    return AiAgentClassification.fromJson({...data, 'provider': provider});
  }

  Future<Map<String, dynamic>> draftResolutionAssist({
    required String publicId,
    required String description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/draft-assist',
      data: {'publicId': publicId, 'description': description},
      options: _authOptions,
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>)
      throw const FormatException(
        'AI service returned an invalid resolution draft.',
      );
    return data;
  }

  Future<String> sendCustomPrompt({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.3,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/prompt',
      data: {
        'prompt': prompt,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
      },
      options: _authOptions,
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>)
      throw const FormatException('AI service returned an invalid response.');
    return _requiredString(data, 'text');
  }
}
