import 'dart:convert';

import 'package:citizen_app/platform/session/secure_storage_adapter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// SessionState defines current authentication state
enum SessionState {
  uninitialized,
  authenticated,
  unauthenticated,
  expired,
}

/// UserRoleEnum defines platform roles
enum UserRoleEnum {
  citizen,
  nodalOfficer,
  departmentAdmin,
  superAdmin,
}

/// SessionManager handles tokens, refresh cycles, and session validation.
class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  SessionState state = SessionState.uninitialized;
  String? userId;
  String? userEmail;
  String? displayName;
  String? stateCode;
  String? district;
  String? phone;
  UserRoleEnum role = UserRoleEnum.citizen;
  String? accessToken;
  String? refreshToken;
  Set<String> permissions = <String>{};

  bool hasPermission(String permission) => permissions.contains(permission);

  bool get isAuthenticated =>
      state == SessionState.authenticated &&
      accessToken != null &&
      accessToken!.isNotEmpty;

  Future<void> updateLocation({
    required String userStateCode,
    required String userDistrict,
  }) async {
    final normalizedState = userStateCode.trim().toUpperCase();
    final normalizedDistrict = userDistrict.trim();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalizedState) ||
        normalizedDistrict.isEmpty) {
      throw ArgumentError('A district and two-letter state code are required.');
    }
    stateCode = normalizedState;
    district = normalizedDistrict;
    await SecureStorageAdapter.write(key: 'stateCode', value: normalizedState);
    await SecureStorageAdapter.write(
      key: 'district',
      value: normalizedDistrict,
    );
  }

  Future<bool> restoreSession() async {
    var token = await SecureStorageAdapter.read(key: 'accessToken');
    final storedRole = await SecureStorageAdapter.read(key: 'userRole');
    final storedId = await SecureStorageAdapter.read(key: 'userId');
    final storedEmail = await SecureStorageAdapter.read(key: 'userEmail');
    final storedName = await SecureStorageAdapter.read(key: 'displayName');
    final storedState = await SecureStorageAdapter.read(key: 'stateCode');
    final storedDistrict = await SecureStorageAdapter.read(key: 'district');
    final storedPhone = await SecureStorageAdapter.read(key: 'phone');
    final storedPermissions = await SecureStorageAdapter.read(
      key: 'permissions',
    );

    try {
      final refreshedToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        token = refreshedToken;
        await SecureStorageAdapter.write(
          key: 'accessToken',
          value: refreshedToken,
        );
      }
    } on FirebaseException catch (_) {
      // The cached token remains available; the backend will reject it if expired.
    }

    if (token != null && token.isNotEmpty && storedId != null) {
      accessToken = token;
      userId = storedId;
      userEmail = storedEmail;
      displayName = storedName;
      stateCode = storedState;
      district = storedDistrict;
      phone = storedPhone;
      try {
        final decoded = jsonDecode(storedPermissions ?? '[]');
        permissions = decoded is List
            ? decoded.whereType<String>().toSet()
            : <String>{};
      } on FormatException {
        permissions = <String>{};
      }

      final normalizedRole = (storedRole ?? '').toLowerCase();
      if (normalizedRole.contains('nodal') ||
          normalizedRole.contains('official')) {
        role = UserRoleEnum.nodalOfficer;
      } else if (normalizedRole.contains('departmentadmin') ||
          normalizedRole.contains('admin')) {
        role = UserRoleEnum.departmentAdmin;
      } else if (normalizedRole.contains('superadmin')) {
        role = UserRoleEnum.superAdmin;
      } else {
        role = UserRoleEnum.citizen;
      }

      state = SessionState.authenticated;
      return true;
    }

    state = SessionState.unauthenticated;
    return false;
  }

  Future<void> establishSession({
    required String token,
    required String id,
    required String email,
    required UserRoleEnum userRole,
    String? name,
    String? userStateCode,
    String? userDistrict,
    String? userPhone,
    Set<String> userPermissions = const <String>{},
  }) async {
    accessToken = token;
    userId = id;
    userEmail = email;
    displayName = name;
    stateCode = userStateCode;
    district = userDistrict;
    phone = userPhone;
    role = userRole;
    permissions = Set<String>.of(userPermissions);
    state = SessionState.authenticated;

    await SecureStorageAdapter.write(key: 'accessToken', value: token);
    await SecureStorageAdapter.write(key: 'userId', value: id);
    await SecureStorageAdapter.write(key: 'userEmail', value: email);
    await SecureStorageAdapter.write(key: 'userRole', value: userRole.name);
    await SecureStorageAdapter.write(
      key: 'permissions',
      value: jsonEncode(permissions.toList()..sort()),
    );
    if (name != null) {
      await SecureStorageAdapter.write(key: 'displayName', value: name);
    }
    if (userStateCode != null) {
      await SecureStorageAdapter.write(key: 'stateCode', value: userStateCode);
    }
    if (userDistrict != null) {
      await SecureStorageAdapter.write(key: 'district', value: userDistrict);
    }
    if (userPhone != null) {
      await SecureStorageAdapter.write(key: 'phone', value: userPhone);
    }
  }

  Future<void> updateAuthorization({
    required UserRoleEnum userRole,
    required Set<String> userPermissions,
  }) async {
    role = userRole;
    permissions = Set<String>.of(userPermissions);
    await SecureStorageAdapter.write(key: 'userRole', value: userRole.name);
    await SecureStorageAdapter.write(
      key: 'permissions',
      value: jsonEncode(permissions.toList()..sort()),
    );
  }

  Future<void> terminateSession() async {
    accessToken = null;
    userId = null;
    userEmail = null;
    displayName = null;
    stateCode = null;
    district = null;
    phone = null;
    permissions = <String>{};
    state = SessionState.unauthenticated;
    await SecureStorageAdapter.clear();
  }
}
