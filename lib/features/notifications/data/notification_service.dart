import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (timestamp == null ||
        json['id'] is! String ||
        json['title'] is! String ||
        json['body'] is! String) {
      throw const FormatException(
        'Notification response is missing required fields.',
      );
    }
    return AppNotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: timestamp,
      type: json['channel'] as String? ?? 'IN_APP',
      isRead: json['isRead'] == true,
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  bool isRead;

  String get formattedTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationService extends ChangeNotifier {
  NotificationService._internal()
    : _dio = ApiClientConfig.attach(
        Dio(
          BaseOptions(
            baseUrl: ApiClientConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
      );

  static final NotificationService instance = NotificationService._internal();

  final Dio _dio;
  final List<AppNotificationItem> _notifications = [];
  bool isLoading = false;
  String? errorMessage;

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Options get _authOptions {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to load notifications.');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        options: _authOptions,
      );
      final rows = response.data?['notifications'];
      if (rows is! List)
        throw const FormatException('Invalid notifications response.');
      _notifications
        ..clear()
        ..addAll(
          rows.map(
            (row) => AppNotificationItem.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          ),
        );
    } on DioException catch (error) {
      errorMessage =
          error.response?.data is Map &&
              error.response?.data['message'] is String
          ? error.response?.data['message'] as String
          : 'Could not load notifications from the service.';
    } on Object catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>('/notifications/$id/read', options: _authOptions);
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index >= 0) _notifications[index].isRead = true;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _dio.patch<void>('/notifications/read-all', options: _authOptions);
    for (final item in _notifications) {
      item.isRead = true;
    }
    notifyListeners();
  }
}
