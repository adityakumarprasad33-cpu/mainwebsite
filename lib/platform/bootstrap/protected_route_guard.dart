import 'dart:async';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:citizen_app/platform/firebase/firebase_service.dart';
import 'package:flutter/material.dart';

/// ProtectedRouteGuard is a hard application entry gate widget.
/// Ensures unauthenticated users MUST NOT render any protected application UI.
/// Checks authentication state and allowed roles before rendering child content.
/// Automatically restores session from storage on page reload / refresh.
class ProtectedRouteGuard extends StatefulWidget {
  const ProtectedRouteGuard({
    required this.child,
    super.key,
    this.allowedRoles,
    this.requiredPermissions,
  });

  final Widget child;
  final Set<UserRoleEnum>? allowedRoles;
  final Set<String>? requiredPermissions;

  @override
  State<ProtectedRouteGuard> createState() => _ProtectedRouteGuardState();
}

class _ProtectedRouteGuardState extends State<ProtectedRouteGuard> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = SessionManager.instance;
    if (session.state == SessionState.uninitialized) {
      await session.restoreSession();
    }
    if (session.isAuthenticated) {
      try {
        await FirebaseService.instance.refreshAuthorizationFromBackend();
      } catch (_) {
        await session.terminateSession();
      }
    }
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
        ),
      );
    }

    final session = SessionManager.instance;

    // Check 1: Authentication State Gate
    if (session.state != SessionState.authenticated ||
        !session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });

      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
        ),
      );
    }

    // Check 2: Role-Based Access Control Gate
    final missingPermissions =
        widget.requiredPermissions
            ?.where((permission) => !session.hasPermission(permission))
            .toList() ??
        const <String>[];
    if ((widget.allowedRoles != null &&
            !widget.allowedRoles!.contains(session.role)) ||
        missingPermissions.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F4C81),
          title: const Text('Access Denied'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gpp_bad,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '403 Forbidden',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  missingPermissions.isNotEmpty
                      ? 'This account is missing the required permission: ${missingPermissions.join(', ')}. Ask an authorized administrator to review your access.'
                      : 'Your account role (${session.role.name}) is not authorized to access this module.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final target = session.role == UserRoleEnum.nodalOfficer
                        ? '/officer-dashboard'
                        : session.role == UserRoleEnum.departmentAdmin ||
                              session.role == UserRoleEnum.superAdmin
                        ? '/admin-dashboard'
                        : '/';
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(target, (route) => false);
                  },
                  child: const Text('Return to Authorized Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
