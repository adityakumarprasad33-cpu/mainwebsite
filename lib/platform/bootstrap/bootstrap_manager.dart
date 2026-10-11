import 'package:citizen_app/platform/session/session_manager.dart';
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
    bool isAuthenticated = false;
    try {
      isAuthenticated = await SessionManager.instance.restoreSession();
    } catch (e, stack) {
      debugPrint('[BootstrapManager] Session restore failed: $e');
      debugPrint('[BootstrapManager] Stack: $stack');
      isAuthenticated = false;
    }

    if (isAuthenticated) {
      final role = SessionManager.instance.role;
      debugPrint('[BootstrapManager] Session Restored cleanly. Role: $role');

      var targetRoute = '/';
      if (role == UserRoleEnum.nodalOfficer) {
        targetRoute = '/officer-dashboard';
      } else if (role == UserRoleEnum.departmentAdmin) {
        targetRoute = '/admin-dashboard';
      } else {
        targetRoute = '/citizen-dashboard';
      }

      return BootstrapResult(
        isAuthenticated: true,
        role: role,
        initialRoute: targetRoute,
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
}
