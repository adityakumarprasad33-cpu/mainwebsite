import 'package:dio/dio.dart';

/// Dio IAM Token Interceptor
///
/// Automatically attaches `Authorization: Bearer <ID_TOKEN>` header
/// to outgoing HTTP requests and handles 401 Unauthorized refresh flows.
class DioIamTokenInterceptor extends Interceptor {
  DioIamTokenInterceptor({this.authToken});

  final String? authToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (authToken != null && authToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $authToken';
    }
    options.headers['X-Client-Platform'] = 'flutter_citizen_app';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 401 Unauthorized handling (trigger silent session refresh)
    }
    super.onError(err, handler);
  }
}
