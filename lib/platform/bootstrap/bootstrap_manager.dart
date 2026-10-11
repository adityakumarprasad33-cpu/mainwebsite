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
    // Keep the authenticated app shell when navigation returns to `/`.
    // The public site also lives at `/`, so restoring from storage alone can
    // briefly (or, on web, incorrectly) classify an already signed-in user as
    // a visitor while they move between dashboard pages.
    final activeSession = SessionManager.instance;
    if (activeSession.isAuthenticated) {
      return BootstrapResult(
        isAuthenticated: true,
        role: activeSession.role,
        initialRoute: _dashboardRoute(activeSession.role),
      );
    }

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

      return BootstrapResult(
        isAuthenticated: true,
        role: role,
        initialRoute: _dashboardRoute(role),
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

  static String _dashboardRoute(UserRoleEnum role) {
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
