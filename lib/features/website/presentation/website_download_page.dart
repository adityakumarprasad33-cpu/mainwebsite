import 'dart:ui';

import 'package:citizen_app/features/website/presentation/download_launcher.dart';
import 'package:citizen_app/features/website/presentation/download_release_metadata.dart';
import 'package:flutter/material.dart';

class WebsiteDownloadPage extends StatefulWidget {
  const WebsiteDownloadPage({
    this.release = DownloadReleaseMetadata.current,
    this.downloadLauncher,
    super.key,
  });

  final DownloadReleaseMetadata release;
  final Future<bool> Function(Uri uri, String fileName)? downloadLauncher;

  @override
  State<WebsiteDownloadPage> createState() => _WebsiteDownloadPageState();
}

class _WebsiteDownloadPageState extends State<WebsiteDownloadPage> {
  bool _openingDownload = false;

  Future<void> _download() async {
    final uri = widget.release.downloadUri;
    if (!widget.release.isAndroidAvailable || uri == null || _openingDownload)
      return;
    setState(() => _openingDownload = true);
    final opened = await (widget.downloadLauncher ?? launchAndroidDownload)(
      uri,
      widget.release.downloadFileName,
    );
    if (!mounted) return;
    setState(() => _openingDownload = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The download could not be opened. Check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1080;
    final available = widget.release.isAndroidAvailable;
    return Scaffold(
      backgroundColor: _C.paper,
      body: Column(
        children: [
          const _Announcement(),
          _Navigation(compact: compact),
          const _CivicStrip(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Hero(
                    compact: compact,
                    available: available,
                    release: widget.release,
                    opening: _openingDownload,
                    onDownload: _download,
                  ),
                  _Sections(compact: compact, available: available),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _C {
  static const navy = Color(0xFF09243A);
  static const blue = Color(0xFF0A4865);
  static const teal = Color(0xFF0E817D);
  static const green = Color(0xFF079A69);
  static const ink = Color(0xFF102B45);
  static const muted = Color(0xFF53677A);
  static const paper = Color(0xFFF8FAFB);
  static const line = Color(0xFFE3EAF0);
  static const pale = Color(0xFFE7F5F1);
}

class _Announcement extends StatelessWidget {
  const _Announcement();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: _C.blue,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1380),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined, color: Colors.white, size: 15),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report. Track. Build a better tomorrow together.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (MediaQuery.sizeOf(context).width >= 600)
              const Text(
                'A cleaner, safer and more livable India.',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Navigation extends StatelessWidget {
  const _Navigation({required this.compact});
  final bool compact;

  void _go(BuildContext context, String route) {
    if (route.startsWith('/#')) route = '/';
    if (route == '/') {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withValues(alpha: .97),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 22,
            vertical: 10,
          ),
          child: Row(
            children: [
              InkWell(onTap: () => _go(context, '/'), child: const _Brand()),
              const Spacer(),
              if (compact || MediaQuery.sizeOf(context).width < 1250)
                PopupMenuButton<String>(
                  tooltip: 'Open website navigation',
                  icon: const Icon(Icons.menu_rounded, color: _C.ink),
                  onSelected: (route) => _go(context, route),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: '/', child: Text('Home')),
                    PopupMenuItem(
                      value: '/#how-it-works',
                      child: Text('How It Works'),
                    ),
                    PopupMenuItem(value: '/#features', child: Text('Features')),
                    PopupMenuItem(value: '/#faq', child: Text('FAQ')),
                    PopupMenuItem(
                      value: '/download',
                      child: Text('Download App'),
                    ),
                    PopupMenuItem(value: '/login', child: Text('Sign In')),
                    PopupMenuItem(
                      value: '/register',
                      child: Text('Get Started'),
                    ),
                  ],
                )
              else ...[
                for (final item in const [
                  ('Home', '/'),
                  ('How It Works', '/#how-it-works'),
                  ('Features', '/#features'),
                  ('FAQ', '/#faq'),
                  ('Download App', '/download'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextButton(
                      onPressed: () => _go(context, item.$2),
                      style: TextButton.styleFrom(foregroundColor: _C.ink),
                      child: Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: item.$1 == 'Download App'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          decoration: item.$1 == 'Download App'
                              ? TextDecoration.underline
                              : null,
                          decorationColor: _C.green,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () => _go(context, '/login'),
                  child: const Text('Sign In'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () => _go(context, '/register'),
                  style: FilledButton.styleFrom(backgroundColor: _C.green),
                  child: const Text('Get Started'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Samadhan',
          style: TextStyle(
            color: _C.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -.65,
          ),
        ),
        TextSpan(
          text: 'AI',
          style: TextStyle(
            color: _C.green,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CivicStrip extends StatelessWidget {
  const _CivicStrip();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
    decoration: const BoxDecoration(
      color: Color(0xFFF8FAFB),
      border: Border(bottom: BorderSide(color: _C.line)),
    ),
    child: const Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [
          Icon(Icons.format_quote_rounded, size: 16, color: _C.green),
          Text(
            'Small actions from citizens can create big changes in our cities and communities.',
            style: TextStyle(
              color: _C.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text('— SamadhanAI', style: TextStyle(color: _C.muted, fontSize: 11)),
        ],
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.compact,
    required this.available,
    required this.release,
    required this.opening,
    required this.onDownload,
  });
  final bool compact, available, opening;
  final DownloadReleaseMetadata release;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _DownloadCityPainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: .93),
                    Colors.white.withValues(alpha: .74),
                    Colors.white.withValues(alpha: .10),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 22 : 56,
                  compact ? 36 : 54,
                  compact ? 22 : 56,
                  30,
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCopy(
                            available: available,
                            release: release,
                            opening: opening,
                            onDownload: onDownload,
                            narrow: narrow,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: _PhoneMockup(height: narrow ? 520 : 500),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _HeroCopy(
                              available: available,
                              release: release,
                              opening: opening,
                              onDownload: onDownload,
                              narrow: false,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Center(child: _PhoneMockup(height: 500)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.available,
    required this.release,
    required this.opening,
    required this.onDownload,
    required this.narrow,
  });
  final bool available, opening, narrow;
  final DownloadReleaseMetadata release;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'SamadhanAI,\n',
              style: TextStyle(color: _C.ink),
            ),
            TextSpan(
              text: 'in Your Pocket',
              style: TextStyle(color: _C.teal),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: narrow ? 39 : 50,
          height: 1.02,
          letterSpacing: -1.9,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520),
        child: Text(
          'Use the SamadhanAI mobile app to report civic issues, add photos, and follow updates wherever you are.',
          style: TextStyle(color: _C.ink, fontSize: 15, height: 1.45),
        ),
      ),
      const SizedBox(height: 18),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          children: [
            _DownloadOption(
              title: 'Download for Android',
              subtitle: available
                  ? 'Verified official release · ${release.versionName}'
                  : 'Official release will be available here when verified.',
              icon: Icons.android_rounded,
              color: const Color(0xFF36A848),
              enabled: available,
              loading: opening,
              onPressed: onDownload,
            ),
            const SizedBox(height: 9),
            _DownloadOption(
              title: 'Download APK (Direct)',
              subtitle: available
                  ? 'Download the verified APK directly.'
                  : 'Direct APK will be available here when verified.',
              icon: Icons.download_for_offline_outlined,
              color: _C.green,
              enabled: available,
              loading: false,
              onPressed: onDownload,
            ),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFF287DE1),
                    size: 16,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      available
                          ? 'Use the verified release details shown below before installing.'
                          : 'The download links will be enabled once the official release artifact is verified and available.',
                      style: const TextStyle(
                        color: _C.ink,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DownloadOption extends StatelessWidget {
  const _DownloadOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool enabled, loading;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _C.line),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100C2438),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _C.pale,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _C.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _C.muted,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              loading ? Icons.hourglass_top : Icons.arrow_forward_rounded,
              color: enabled ? _C.blue : _C.ink,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustration of the SamadhanAI app on a phone',
    image: true,
    child: Container(
      height: height,
      width: height * .51,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF52606B), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4809233A),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: const Color(0xFFF7FAFC),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Container(
                      height: 26,
                      color: const Color(0xFFF7FAFC),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _C.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.public, color: _C.green, size: 16),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'SamadhanAI',
                              style: TextStyle(
                                color: _C.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.notifications_none,
                            color: _C.ink.withValues(alpha: .8),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: height * .20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4ECF2), Color(0xFFB8DBD4)],
                        ),
                      ),
                      child: const Stack(
                        children: [
                          Positioned(
                            left: 10,
                            top: 15,
                            child: Text(
                              'Report for a\nBetter Tomorrow',
                              style: TextStyle(
                                color: _C.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 4,
                            child: Icon(
                              Icons.location_city,
                              color: _C.teal,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PhoneAction(
                              'Report Issue',
                              Icons.add_a_photo_outlined,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _PhoneAction(
                              'Track Status',
                              Icons.track_changes_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 2, 10, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'My Recent Issues',
                              style: TextStyle(
                                fontSize: 10,
                                color: _C.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'View All',
                            style: TextStyle(fontSize: 8, color: _C.teal),
                          ),
                        ],
                      ),
                    ),
                    for (final item in const [
                      (
                        'Street Light Not Working',
                        Icons.lightbulb_outline,
                        Color(0xFFFFA64D),
                      ),
                      (
                        'Garbage Not Collected',
                        Icons.delete_outline,
                        Color(0xFFFF7777),
                      ),
                      (
                        'Road Repair Required',
                        Icons.add_road,
                        Color(0xFF58B99E),
                      ),
                    ])
                      Container(
                        margin: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _C.line),
                        ),
                        child: Row(
                          children: [
                            Icon(item.$2, color: item.$3, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.$1,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: _C.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.circle, color: _C.green, size: 7),
                          ],
                        ),
                      ),
                    const Spacer(),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.home_outlined, color: _C.green, size: 14),
                          Icon(
                            Icons.receipt_long_outlined,
                            color: _C.muted,
                            size: 14,
                          ),
                          Icon(Icons.add_circle, color: _C.green, size: 23),
                          Icon(
                            Icons.notifications_none,
                            color: _C.muted,
                            size: 14,
                          ),
                          Icon(Icons.person_outline, color: _C.muted, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PhoneAction extends StatelessWidget {
  const _PhoneAction(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _C.line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 11, color: _C.green),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              color: _C.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Sections extends StatelessWidget {
  const _Sections({required this.compact, required this.available});
  final bool compact, available;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1380),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 56,
          18,
          compact ? 20 : 56,
          26,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Why use the app?'),
            const SizedBox(height: 12),
            _ResponsiveGrid(
              compact: compact,
              children: const [
                _Benefit(
                  Icons.phone_android,
                  'Report on the go',
                  'Submit issues with photos and details from anywhere.',
                ),
                _Benefit(
                  Icons.monitor_heart_outlined,
                  'Track real-time updates',
                  'Check status and available progress in one place.',
                ),
                _Benefit(
                  Icons.notifications_active_outlined,
                  'Get notified',
                  'Receive updates when notification services are available.',
                ),
                _Benefit(
                  Icons.groups_2_outlined,
                  'A cleaner, safer community',
                  'Be part of positive change in your area.',
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionTitle('How to install (Android)'),
            const SizedBox(height: 12),
            _ResponsiveGrid(
              compact: compact,
              children: [
                _StepCard(
                  1,
                  'Download',
                  available
                      ? 'Get the verified APK using either download option above.'
                      : 'The official download button will appear above when the APK is verified.',
                ),
                const _StepCard(
                  2,
                  'Install',
                  'Open the downloaded file and follow Android installation prompts. Keep device protections on.',
                ),
                const _StepCard(
                  3,
                  'Open & sign in',
                  'Open SamadhanAI and sign in or create an account to start reporting issues.',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle('Platform availability'),
            const SizedBox(height: 12),
            _ResponsiveGrid(
              compact: compact,
              children: [
                _PlatformCard(
                  icon: Icons.android,
                  title: 'Android',
                  status: available
                      ? 'Verified release available'
                      : 'Not currently available · pending release verification',
                  color: const Color(0xFF36A848),
                ),
                const _PlatformCard(
                  icon: Icons.phone_iphone,
                  title: 'iOS',
                  status:
                      'Not currently available. No verified App Store listing is configured.',
                  color: Color(0xFF8995A2),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          color: _C.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
      Container(
        width: 28,
        height: 2,
        margin: const EdgeInsets.only(top: 4),
        color: _C.green,
      ),
    ],
  );
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.compact, required this.children});
  final bool compact;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 600
        ? 1
        : width < 950
        ? 2
        : 2;
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 9,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - 10 * (columns - 1)) / columns,
              child: child,
            ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.body);
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => _CardShell(
    child: Row(
      children: [
        _IconBadge(icon: icon, color: _C.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard(this.number, this.title, this.body);
  final int number;
  final String title, body;
  @override
  Widget build(BuildContext context) => _CardShell(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _C.green,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
  });
  final IconData icon;
  final String title, status;
  final Color color;
  @override
  Widget build(BuildContext context) => _CardShell(
    child: Row(
      children: [
        Icon(icon, color: color, size: 27),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 43,
    height: 43,
    decoration: const BoxDecoration(color: _C.pale, shape: BoxShape.circle),
    child: Icon(icon, color: color, size: 21),
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 66),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _C.line),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0809233A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final links = Wrap(
      alignment: compact ? WrapAlignment.center : WrapAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/'),
          child: const Text('Home', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/login'),
          child: const Text('Sign In', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/register'),
          child: const Text(
            'Get Started',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      color: _C.navy,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 21),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1380),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const _Brand(), const SizedBox(height: 10), links],
                )
              : Row(children: [const _Brand(), const Spacer(), links]),
        ),
      ),
    );
  }
}

class _DownloadCityPainter extends CustomPainter {
  const _DownloadCityPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFEADB), Color(0xFFCBE3F1), Color(0xFF91C8CD)],
        ).createShader(rect),
    );
    final sun = Paint()..color = const Color(0xFFFFE5B4).withValues(alpha: .9);
    canvas.drawCircle(
      Offset(size.width * .70, size.height * .25),
      size.height * .10,
      sun,
    );
    final ground = Paint()..color = const Color(0xFF5B9588);
    final hill = Path()
      ..moveTo(0, size.height * .65)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .49,
        size.width * .68,
        size.height * .67,
      )
      ..quadraticBezierTo(
        size.width * .86,
        size.height * .48,
        size.width,
        size.height * .62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, ground);
    final building = Paint()
      ..color = const Color(0xFF557C89).withValues(alpha: .7);
    for (var i = 0; i < 15; i++) {
      final x = size.width * (i / 15);
      final w = size.width * .035;
      final h = size.height * (.16 + ((i * 17) % 11) / 100);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * .62 - h, w, h),
          const Radius.circular(2),
        ),
        building,
      );
      final window = Paint()
        ..color = const Color(0xFFFFE9BD).withValues(alpha: .7);
      for (var row = 0; row < 3; row++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x + w * .25,
            size.height * .62 - h + 8 + row * 12,
            3,
            4,
          ),
          window,
        );
      }
    }
    final road = Paint()
      ..color = const Color(0xFF9A9D91)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * .16;
    final roadPath = Path()
      ..moveTo(size.width * .50, size.height)
      ..cubicTo(
        size.width * .55,
        size.height * .80,
        size.width * .40,
        size.height * .76,
        size.width * .63,
        size.height * .64,
      );
    canvas.drawPath(roadPath, road);
    final mark = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(roadPath, mark);
  }

  @override
  bool shouldRepaint(covariant _DownloadCityPainter oldDelegate) => false;
}
