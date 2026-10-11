import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:citizen_app/platform/firebase/firebase_service.dart';
import 'package:flutter/foundation.dart';

/// BootstrapResult contains startup decision metadata
class BootstrapResult {
  const BootstrapResult({
    required this.isAuthenticated,
    required this.role,
    required this.initialRoute,
  });

  final bool isAuthenticated;
  final UserRoleEnum role;
  final String initialRoute;
}

/// BootstrapManager handles app initialization and silent session restore.
class BootstrapManager {
  static Future<BootstrapResult> initialize() async {
    debugPrint('[BootstrapManager] Restoring Session from Secure Storage...');
    final session = SessionManager.instance;
    if (session.isAuthenticated) {
      return BootstrapResult(
        isAuthenticated: true,
        role: session.role,
        initialRoute: dashboardRouteFor(session.role),
      );
    }

    var isAuthenticated = false;
    try {
      isAuthenticated = await session.restoreSession();
    } catch (e, stack) {
      debugPrint('[BootstrapManager] Session restore failed: $e');
      debugPrint('[BootstrapManager] Stack: $stack');
    }
    if (!isAuthenticated) {
      try {
        isAuthenticated = await FirebaseService.instance
            .restoreCurrentUserSession();
      } catch (e, stack) {
        debugPrint('[BootstrapManager] Firebase restore failed: $e');
        debugPrint('[BootstrapManager] Stack: $stack');
      }
    }

    if (isAuthenticated) {
      final role = SessionManager.instance.role;
      debugPrint('[BootstrapManager] Session Restored cleanly. Role: $role');

      return BootstrapResult(
        isAuthenticated: true,
        role: role,
        initialRoute: dashboardRouteFor(role),
      );
    }

    debugPrint(
      '[BootstrapManager] No active session found. Redirecting to Login.',
    );
    return const BootstrapResult(
      isAuthenticated: false,
      role: UserRoleEnum.citizen,
      initialRoute: '/login',
    );
  }

  static String dashboardRouteFor(UserRoleEnum role) {
    switch (role) {
      case UserRoleEnum.nodalOfficer:
        return '/officer-dashboard';
      case UserRoleEnum.departmentAdmin:
      case UserRoleEnum.superAdmin:
        return '/admin-dashboard';
      case UserRoleEnum.citizen:
        return '/citizen-dashboard';
    }
  }
}
