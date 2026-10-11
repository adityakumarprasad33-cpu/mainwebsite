import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Central API configuration and same-environment endpoint failover.
/// Only public endpoint URLs belong in the client; credentials stay on the API.
class ApiClientConfig {
  ApiClientConfig._();

  static const _retryBaseKey = 'samadhanFailoverBaseUrl';
  static const _retriedKey = 'samadhanFailoverRetried';
  static const String _environmentUrlList = String.fromEnvironment(
    'API_BASE_URLS',
    defaultValue: '',
  );
  static const String _environmentUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const bool _requireHttps =
      kReleaseMode ||
      bool.fromEnvironment('REQUIRE_HTTPS', defaultValue: false);
  static const Duration _probeTimeout = Duration(seconds: 2);
  static const Duration _healthyCacheDuration = Duration(seconds: 15);

  static String? _activeUrl;
  static DateTime? _activeUrlExpiresAt;

  @visibleForTesting
  static Future<bool> Function(String baseUrl)? readinessCheckOverride;

  static List<String> get configuredBaseUrls {
    final configured = _environmentUrlList.trim().isNotEmpty
        ? _environmentUrlList.trim()
        : _environmentUrl.trim();
    if (configured.isNotEmpty) return normalizeBaseUrls(configured);
    // For a local web preview, target the same host that served the website.
    // A fixed 127.0.0.1 breaks when another device opens the preview over LAN.
    if (kIsWeb && kDebugMode && Uri.base.host.isNotEmpty) {
      return normalizeBaseUrls('http://${Uri.base.host}:5000/api/v1');
    }
    return const [];
  }

  static String? get configuredBaseUrl =>
      _activeUrl ??
      (configuredBaseUrls.isEmpty ? null : configuredBaseUrls.first);

  static String get baseUrl =>
      configuredBaseUrl ??
      (throw StateError(
        'Backend URL is not configured. Set API_BASE_URL in the build environment.',
      ));

  static bool get isConfigured => configuredBaseUrls.isNotEmpty;
  static String get aiBaseUrl => '$baseUrl/ai';
  static String get currentHost => Uri.parse(baseUrl).host;

  /// Probes build-environment endpoints before creating API clients.
  static Future<void> initialize() async {
    final urls = configuredBaseUrls;
    if (urls.isNotEmpty) {
      _activeUrl = await _findHealthyUrl(urls);
      _activeUrlExpiresAt = _activeUrl == null
          ? null
          : DateTime.now().add(_healthyCacheDuration);
    }
  }

  static List<String> normalizeBaseUrls(String value, {bool? release}) {
    final inputs = value
        .split(RegExp(r'[,;\n\r]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (inputs.isEmpty || inputs.length > 3) {
      throw const FormatException('Enter one to three API URLs, one per line.');
    }

    final urls = <String>[];
    for (final input in inputs) {
      final normalized = _normalizeBaseUrl(input, release: release);
      if (!urls.contains(normalized)) urls.add(normalized);
    }
    if (urls.length != inputs.length) {
      throw const FormatException('Each fallback URL must be unique.');
    }
    if (urls.map((url) => Uri.parse(url).scheme).toSet().length != 1) {
      throw const FormatException(
        'All fallback URLs must use the same protocol.',
      );
    }
    return List.unmodifiable(urls);
  }

  static String _normalizeBaseUrl(String value, {bool? release}) {
    final input = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(input);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Enter a complete URL such as https://api.example.com/api/v1.',
      );
    }
    if (uri.path.isNotEmpty && uri.path != '/api/v1') {
      throw const FormatException('The URL path must be /api/v1.');
    }
    if (uri.scheme == 'http' && (release ?? _requireHttps)) {
      throw const FormatException('Release builds require HTTPS.');
    }
    return '${uri.origin}/api/v1';
  }

  static Future<String?> _ensureHealthyUrl() async {
    if (_activeUrl != null &&
        _activeUrlExpiresAt != null &&
        DateTime.now().isBefore(_activeUrlExpiresAt!)) {
      return _activeUrl;
    }
    _activeUrl = await _findHealthyUrl(configuredBaseUrls);
    _activeUrlExpiresAt = _activeUrl == null
        ? null
        : DateTime.now().add(_healthyCacheDuration);
    return _activeUrl;
  }

  static Future<String?> _findHealthyUrl(List<String> urls) async {
    for (final url in urls) {
      if (await _isReady(url)) return url;
    }
    return null;
  }

  static Future<String?> _findNextHealthyUrl(String currentUrl) async {
    final urls = configuredBaseUrls;
    if (urls.length < 2) return null;
    final currentIndex = urls.indexOf(currentUrl);
    for (var offset = 1; offset < urls.length; offset++) {
      final candidate = urls[(currentIndex + offset) % urls.length];
      if (candidate != currentUrl && await _isReady(candidate))
        return candidate;
    }
    return null;
  }

  static Future<bool> _isReady(String baseUrl) async {
    final override = readinessCheckOverride;
    if (override != null) return override(baseUrl);
    final dio = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
      ),
    );
    try {
      final response = await dio.get<dynamic>(
        '${Uri.parse(baseUrl).origin}/ready',
        options: Options(validateStatus: (status) => status != null),
      );
      final body = response.data;
      return response.statusCode == 200 &&
          body is Map &&
          (body['status'] == 'READY' || body['status'] == 'DEGRADED') &&
          body['checks'] is Map &&
          body['checks']['database'] == true &&
          body['checks']['rateGuard'] == true;
    } on DioException {
      return false;
    } finally {
      dio.close();
    }
  }

  /// Redirects all API clients and retries only failures that occur before a
  /// connection is established, avoiding duplicate writes after server receipt.
  static Dio attach(Dio dio) {
    final isAiClient = dio.options.baseUrl.endsWith('/api/v1/ai');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final retryBase = options.extra[_retryBaseKey];
            final endpoint = retryBase is String
                ? retryBase
                : await _ensureHealthyUrl();
            if (endpoint == null) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: configuredBaseUrls.isEmpty
                      ? 'API_BASE_URL is missing from this build. Configure the backend URL in the build environment and rebuild.'
                      : 'No configured backend passed /ready. Check that its URL resolves, allows this website origin in CORS, and reports database, storage, and rateGuard ready.',
                ),
              );
              return;
            }
            options.baseUrl = isAiClient ? '$endpoint/ai' : endpoint;
            handler.next(options);
          } on Object catch (error, stackTrace) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                stackTrace: stackTrace,
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final retryAlreadyUsed = options.extra[_retriedKey] == true;
          final connectFailed =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout;
          if (retryAlreadyUsed || !connectFailed) {
            handler.next(error);
            return;
          }

          try {
            final failedBase = _activeUrl ?? baseUrl;
            final fallback = await _findNextHealthyUrl(failedBase);
            if (fallback == null) {
              handler.next(error);
              return;
            }
            _activeUrl = fallback;
            _activeUrlExpiresAt = DateTime.now().add(_healthyCacheDuration);
            final extra = Map<String, dynamic>.from(options.extra)
              ..[_retryBaseKey] = fallback
              ..[_retriedKey] = true;
            final response = await dio.fetch<dynamic>(
              options.copyWith(
                baseUrl: isAiClient ? '$fallback/ai' : fallback,
                extra: extra,
              ),
            );
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          } on Object {
            handler.next(error);
          }
        },
      ),
    );
    return dio;
  }

  static String get debugInfo =>
      'Configured API endpoints: ${configuredBaseUrls.length}\n'
      'Selected API: ${configuredBaseUrl ?? 'not configured'}';
}
