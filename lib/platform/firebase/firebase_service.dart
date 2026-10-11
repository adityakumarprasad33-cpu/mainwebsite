import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Production Firebase Auth Service for SamadhanAI
/// Handles Firebase Authentication (works anywhere - cloud)
/// Firestore sync is handled by Backend via /auth/firebase-sync endpoint
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  /// 1. Firebase Authentication - Register User (cloud, works anywhere)
  Future<Map<String, dynamic>> registerWithFirebase({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    String? stateCode,
    String? district,
    String? pincode,
  }) async {
    debugPrint(
      '[FirebaseService] Registering citizen via Firebase Auth ($email)...',
    );

    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
    final uid = credential.user!.uid;
    final idToken = await credential.user!.getIdToken() ?? '';
    await credential.user!.updateDisplayName(displayName);

    // Establish persistent session with Firebase token
    await SessionManager.instance.establishSession(
      token: idToken,
      id: uid,
      email: email,
      userRole: UserRoleEnum.citizen,
      name: displayName,
      userStateCode: (stateCode ?? '').isNotEmpty ? stateCode : null,
      userDistrict: (district ?? '').isNotEmpty ? district : null,
      userPhone: phone,
    );

    // Sync with backend (creates user in backend JSON store + Firestore via Admin SDK)
    final backendUser = await _syncWithBackend(
      uid: uid,
      email: email,
      idToken: idToken,
      displayName: displayName,
      phone: phone,
      stateCode: stateCode,
      district: district,
    );
    await SessionManager.instance.updateAuthorization(
      userRole: _roleFromBackend(backendUser['roleId'] as String?),
      userPermissions: _permissionSet(backendUser['permissions']),
    );

    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'idToken': idToken,
      'role': 'citizen',
    };
  }

  /// 2. Firebase Authentication - Sign In User (cloud, works anywhere)
  Future<Map<String, dynamic>> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    debugPrint(
      '[FirebaseService] Authenticating citizen with Firebase Auth ($email)...',
    );

    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final idToken = await credential.user!.getIdToken() ?? '';

    // Read minimal profile (Firebase Auth only, no Firestore REST call)
    final backendUser = await _syncWithBackend(
      uid: uid,
      email: email,
      idToken: idToken,
    );
    final role = _roleFromBackend(backendUser['roleId'] as String?);
    await SessionManager.instance.establishSession(
      token: idToken,
      id: uid,
      email: email,
      userRole: role,
      name: backendUser['displayName'] as String?,
      userStateCode: backendUser['stateCode'] as String?,
      userDistrict: backendUser['district'] as String?,
      userPhone: backendUser['phone'] as String?,
      userPermissions: _permissionSet(backendUser['permissions']),
    );

    return {'uid': uid, 'email': email, 'role': role.name, 'idToken': idToken};
  }

  /// Rebuilds the app session from Firebase's persisted web/mobile auth state.
  /// This is used when local session metadata is missing after a browser restart.
  Future<bool> restoreCurrentUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return false;
    final email = user.email ?? '';
    try {
      final backendUser = await _syncWithBackend(
        uid: user.uid,
        email: email,
        idToken: token,
        displayName: user.displayName,
        phone: user.phoneNumber,
      );
      await SessionManager.instance.establishSession(
        token: token,
        id: user.uid,
        email: email,
        userRole: _roleFromBackend(backendUser['roleId'] as String?),
        name: backendUser['displayName'] as String? ?? user.displayName,
        userStateCode: backendUser['stateCode'] as String?,
        userDistrict: backendUser['district'] as String?,
        userPhone: backendUser['phone'] as String? ?? user.phoneNumber,
        userPermissions: _permissionSet(backendUser['permissions']),
      );
    } catch (_) {
      // Firebase can still hold a valid signed-in identity when browser-local
      // app metadata or the profile-sync endpoint is temporarily unavailable.
      // Restore only the role/permissions explicitly present in signed claims;
      // API authorization remains enforced by the backend on every request.
      debugPrint('[FirebaseService] Restoring dashboard from Firebase claims.');
      final claims = (await user.getIdTokenResult()).claims ?? const {};
      final roleId = claims['roleId'] ?? claims['role'] ?? claims['userRole'];
      await SessionManager.instance.establishSession(
        token: token,
        id: user.uid,
        email: email,
        userRole: _roleFromBackend(roleId is String ? roleId : null),
        name: user.displayName,
        userPhone: user.phoneNumber,
        userPermissions: _permissionSet(claims['permissions']),
      );
    }
    return true;
  }

  Set<String> _permissionSet(dynamic value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};

  /// Refreshes cached UI capabilities from the backend's current employee record.
  /// The server remains authoritative for every request; this only gates controls.
  Future<void> refreshAuthorizationFromBackend() async {
    final session = SessionManager.instance;
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? session.accessToken : await user.getIdToken();
    if (token == null || token.isEmpty || session.userId == null) {
      throw StateError('A current authenticated session is required.');
    }
    final dio = ApiClientConfig.attach(
      Dio(
        BaseOptions(
          baseUrl: ApiClientConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ),
    );
    final response = await dio.get<Map<String, dynamic>>('/users/me');
    final data = response.data;
    if (data == null ||
        data['userId'] != session.userId ||
        data['roleId'] is! String) {
      throw const FormatException(
        'Backend returned an invalid authorization profile.',
      );
    }
    session.accessToken = token;
    await session.updateAuthorization(
      userRole: _roleFromBackend(data['roleId'] as String?),
      userPermissions: _permissionSet(data['permissions']),
    );
  }

  /// Sync user with backend via /auth/firebase-sync
  /// Backend creates/finds user in JSON store and returns backend session token
  Future<Map<String, dynamic>> _syncWithBackend({
    required String uid,
    required String email,
    required String idToken,
    String? displayName,
    String? phone,
    String? stateCode,
    String? district,
  }) async {
    try {
      final dio = ApiClientConfig.attach(
        Dio(
          BaseOptions(
            baseUrl: ApiClientConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ),
      );

      final backendResponse = await dio.post<Map<String, dynamic>>(
        '/auth/firebase-sync',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'firebaseUid': uid,
          'email': email,
          'idToken': idToken,
          if (displayName != null && displayName.trim().isNotEmpty)
            'displayName': displayName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (stateCode != null && stateCode.trim().isNotEmpty)
            'stateCode': stateCode.trim().toUpperCase(),
          if (district != null && district.trim().isNotEmpty)
            'district': district.trim(),
        },
      );

      final data = backendResponse.data;
      final user = data?['user'];
      if (data == null ||
          data['token'] != idToken ||
          user is! Map<String, dynamic>) {
        throw const FormatException(
          'Backend returned an invalid Firebase sync response',
        );
      }
      debugPrint('[FirebaseService] Backend sync successful');
      return user;
    } catch (e) {
      debugPrint('[FirebaseService] Backend sync failed: $e');
      await SessionManager.instance.terminateSession();
      rethrow;
    }
  }

  UserRoleEnum _roleFromBackend(String? roleId) {
    final normalized = (roleId ?? '').toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    if (normalized.contains('superadmin')) return UserRoleEnum.superAdmin;
    if (normalized.contains('departmentadmin') ||
        normalized == 'admin' ||
        normalized == 'deptadmin') {
      return UserRoleEnum.departmentAdmin;
    }
    if (normalized.contains('officer') || normalized.contains('official')) {
      return UserRoleEnum.nodalOfficer;
    }
    return UserRoleEnum.citizen;
  }
}
