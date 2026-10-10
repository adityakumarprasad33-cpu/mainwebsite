import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';

/// Grievance data model for backend API
class GrievanceSubmission {
  GrievanceSubmission({
    required this.title,
    required this.description,
    required this.department,
    required this.slaHours,
    required this.priority,
    required this.location,
    this.aiClassification,
    this.evidenceList,
  });

  final String title;
  final String description;
  final String department;
  final int slaHours;
  final String priority;
  final Map<String, dynamic> location;
  final Map<String, dynamic>? aiClassification;
  final List<Map<String, dynamic>>? evidenceList;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'department': department,
      'slaHours': slaHours,
      'priority': priority,
      'location': location,
      if (aiClassification != null) 'aiClassification': aiClassification,
      if (evidenceList != null) 'evidenceList': evidenceList,
    };
  }
}

class GrievanceResponse {
  GrievanceResponse({
    required this.publicId,
    required this.uuid,
    required this.title,
    required this.description,
    required this.department,
    required this.slaHours,
    required this.citizenUserId,
    required this.citizenEmail,
    required this.priority,
    required this.state,
    required this.location,
    required this.aiClassification,
    required this.submittedAt,
  });

  final String publicId;
  final String uuid;
  final String title;
  final String description;
  final String department;
  final int slaHours;
  final String citizenUserId;
  final String citizenEmail;
  final String priority;
  final String state;
  final Map<String, dynamic> location;
  final Map<String, dynamic> aiClassification;
  final String submittedAt;

  factory GrievanceResponse.fromJson(Map<String, dynamic> json) {
    return GrievanceResponse(
      publicId: json['publicId'] as String,
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      department: json['department'] as String,
      slaHours: (json['slaHours'] as num).toInt(),
      citizenUserId: json['citizenUserId'] as String,
      citizenEmail: json['citizenEmail'] as String,
      priority: json['priority'] as String,
      state: json['state'] as String,
      location: json['location'] as Map<String, dynamic>,
      aiClassification: json['aiClassification'] as Map<String, dynamic>,
      submittedAt: json['submittedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'uuid': uuid,
      'title': title,
      'description': description,
      'department': department,
      'slaHours': slaHours,
      'citizenUserId': citizenUserId,
      'citizenEmail': citizenEmail,
      'priority': priority,
      'state': state,
      'location': location,
      'aiClassification': aiClassification,
      'submittedAt': submittedAt,
    };
  }
}

/// Service class for grievance operations via Backend API
class GrievanceService {
  GrievanceService({Dio? dio})
    : _dio = ApiClientConfig.attach(
        dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiClientConfig.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            ),
      );

  final Dio _dio;

  /// Submit grievance via Backend API (which writes to Firestore using Admin SDK)
  Future<GrievanceResponse> submitGrievance(
    GrievanceSubmission submission,
  ) async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/grievances',
        data: submission.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null) {
        return GrievanceResponse.fromJson(response.data!);
      }
      throw Exception('Empty response from server');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final message = errorData is Map
            ? errorData['message'] ?? 'Invalid request'
            : 'Invalid request';
        throw Exception(message);
      } else if (e.response?.statusCode == 503) {
        final errorData = e.response?.data;
        final message = errorData is Map && errorData['message'] is String
            ? errorData['message'] as String
            : 'The grievance service is temporarily unavailable. Please try again.';
        throw Exception(message);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your network and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server. Please ensure backend is running and you are on the same network.',
        );
      }
      throw Exception('Failed to submit grievance: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch all grievances for current user
  Future<List<GrievanceResponse>> fetchMyGrievances() async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/grievances',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null && response.data!['items'] is List) {
        final items = response.data!['items'] as List;
        return items
            .map(
              (item) =>
                  GrievanceResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception('Failed to fetch grievances: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get grievance by ID
  Future<GrievanceResponse?> getGrievanceById(String id) async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/grievances/$id',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null) {
        return GrievanceResponse.fromJson(response.data!);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch grievance: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get grievance timeline
  Future<List<Map<String, dynamic>>> fetchMyEvidence() async {
    final token = SessionManager.instance.accessToken;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final grievancesResponse = await _dio.get<Map<String, dynamic>>(
      '/grievances',
      options: Options(headers: headers),
    );
    final grievances = grievancesResponse.data?['items'];
    if (grievances is! List) throw Exception('The backend returned an invalid grievances response.');
    final evidenceRequests = grievances.whereType<Map<String, dynamic>>().map((grievance) async {
      final id = grievance['publicId'] ?? grievance['id'];
      if (id is! String || id.isEmpty) return <Map<String, dynamic>>[];
      final response = await _dio.get<Map<String, dynamic>>(
        '/grievances/$id/attachments',
        options: Options(headers: headers),
      );
      final attachments = response.data?['items'];
      if (attachments is! List) return <Map<String, dynamic>>[];
      return attachments.whereType<Map<String, dynamic>>().map((attachment) => {
        ...attachment,
        'grievanceId': id,
        'grievanceTitle': grievance['title'] ?? grievance['issue']?['title'] ?? id,
      }).toList();
    });
    return (await Future.wait(evidenceRequests)).expand((items) => items).toList();
  }

  /// Get grievance timeline
  Future<List<Map<String, dynamic>>> getGrievanceTimeline(String id) async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/grievances/$id/timeline',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null && response.data!['events'] is List) {
        return (response.data!['events'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch timeline: $e');
    }
  }

  /// Add comment to grievance
  Future<Map<String, dynamic>> addComment(
    String grievanceId,
    String message,
    String visibility,
  ) async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/grievances/$grievanceId/comments',
        data: {'message': message, 'visibility': visibility},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data ?? {};
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Submit feedback for grievance resolution
  Future<Map<String, dynamic>> submitFeedback(
    String grievanceId,
    int rating,
    String feedbackText,
  ) async {
    final session = SessionManager.instance;
    final token = session.accessToken;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/grievances/$grievanceId/feedback',
        data: {'rating': rating, 'feedbackText': feedbackText},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data ?? {};
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
