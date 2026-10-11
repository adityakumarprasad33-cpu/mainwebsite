import 'package:citizen_app/features/website/presentation/website_landing_page.dart';
import 'package:citizen_app/platform/bootstrap/bootstrap_manager.dart';
import 'package:flutter/material.dart';

/// Chooses the public website or the existing authenticated app entry point.
/// Session restoration is shared with the app bootstrap and protected routes.
class WebsiteRootRouter extends StatefulWidget {
  const WebsiteRootRouter({required this.authenticatedBuilder, super.key});

  final Widget Function(BuildContext context, BootstrapResult result)
  authenticatedBuilder;

  @override
  State<WebsiteRootRouter> createState() => _WebsiteRootRouterState();
}

class _WebsiteRootRouterState extends State<WebsiteRootRouter> {
  late final Future<BootstrapResult> _bootstrap = BootstrapManager.initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<BootstrapResult>(
    future: _bootstrap,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _WebsiteStartupError();
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          backgroundColor: Color(0xFFF7F7F4),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1E4E55)),
          ),
        );
      }
      final result = snapshot.requireData;
      if (!result.isAuthenticated) return const WebsiteLandingPage();
      return widget.authenticatedBuilder(context, result);
    },
  );
}

class _WebsiteStartupError extends StatelessWidget {
  const _WebsiteStartupError();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F4),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36),
            const SizedBox(height: 14),
            const Text('The application could not start.'),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}
