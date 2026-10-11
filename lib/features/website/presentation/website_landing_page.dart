import 'dart:async';
import 'dart:ui';

import 'package:citizen_app/features/website/presentation/download_release_metadata.dart';
import 'package:citizen_app/features/website/presentation/website_staff_chat_button.dart';
import 'package:citizen_app/platform/bootstrap/bootstrap_manager.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Public, web-only SamadhanAI product page.
class WebsiteLandingPage extends StatefulWidget {
  const WebsiteLandingPage({super.key});

  @override
  State<WebsiteLandingPage> createState() => _WebsiteLandingPageState();
}

class _WebsiteLandingPageState extends State<WebsiteLandingPage> {
  final _scrollController = ScrollController();
  final GlobalKey _updatesKey = GlobalKey();
  final GlobalKey _capabilitiesKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  bool _scrolled = false;
  bool _menuOpen = false;
  bool _isAuthenticated = false;
  StreamSubscription<User?>? _authSubscription;

  static const _faqs = <(String, String)>[
    (
      'What is SamadhanAI?',
      'SamadhanAI is a digital experience for submitting public-service grievances and following their progress. It includes citizen workflows and tools for authorized case management.',
    ),
    (
      'What kinds of issues can I report?',
      'You can describe a local public-service issue in the application. Available categories and any suggested department depend on the configured services and information you provide.',
    ),
    (
      'How can I follow my grievance?',
      'After signing in, use My Grievances to view submitted cases and the status information available for each one.',
    ),
    (
      'How does AI assist with grievance management?',
      'When the AI service is configured and available, it can help classify a complaint, suggest wording, or analyze submitted details. Review suggestions before submitting; AI output is not a decision or guarantee.',
    ),
    (
      'Do I need an account?',
      'You need to sign in to submit a grievance or view your grievance history. You can explore this page without an account.',
    ),
    (
      'Are reports automatically sent to government departments?',
      'SamadhanAI provides grievance-management workflows. This website does not claim that every report is connected to or automatically delivered to a government department. Assignment depends on the application configuration and authorized workflows.',
    ),
    (
      'What if a grievance cannot be assigned automatically?',
      'The application may provide suggested classification where configured. Authorized personnel can review cases within their permissions; the platform does not promise automatic assignment or a response time.',
    ),
    (
      'Is the mobile app available?',
      'Android release information is shown on the Download App page when a verified release is configured. iOS availability has not been verified.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isAuthenticated = SessionManager.instance.isAuthenticated;
    _scrollController.addListener(_onScroll);
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        final next = user != null || SessionManager.instance.isAuthenticated;
        if (mounted && next != _isAuthenticated) {
          setState(() => _isAuthenticated = next);
        }
      });
    } on FirebaseException {
      // Firebase may be unavailable in a local public-site preview.
    }
  }

  Future<void> _openDashboard() async {
    setState(() => _menuOpen = false);
    final result = await BootstrapManager.initialize();
    if (!mounted) return;
    if (!result.isAuthenticated) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      result.initialRoute,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  void _onScroll() {
    final next = _scrollController.hasClients && _scrollController.offset > 12;
    if (next != _scrolled && mounted) setState(() => _scrolled = next);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    setState(() => _menuOpen = false);
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  void _go(String route) {
    setState(() => _menuOpen = false);
    unawaited(Navigator.of(context).pushNamed(route));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Keep the full wordmark and every desktop navigation action visible.
    final narrow = width < 1080;
    return Scaffold(
      backgroundColor: _LandingColors.paper,
      body: Column(
        children: [
          _AnnouncementBar(onViewUpdates: () => _scrollTo(_updatesKey)),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 52),
                  child: Column(
                    children: [
                      const _CivicMessageStrip(),
                      _HeroSection(
                        narrow: narrow,
                        scrollController: _scrollController,
                        onStart: _isAuthenticated
                            ? _openDashboard
                            : () => _go('/register'),
                        onHow: () => _go('/how-it-works'),
                      ),
                      _PublicUpdatesSection(
                        key: _updatesKey,
                        narrow: narrow,
                        onReport: _isAuthenticated
                            ? _openDashboard
                            : () => _go('/register'),
                        onTrack: _isAuthenticated
                            ? _openDashboard
                            : () => _go('/login'),
                        onDownload: () => _go('/download'),
                      ),
                      _CapabilitiesSection(
                        key: _capabilitiesKey,
                        narrow: narrow,
                      ),
                      _FaqSection(key: _faqKey, narrow: narrow),
                      _Footer(
                        onHow: () => _go('/how-it-works'),
                        onCapabilities: () => _scrollTo(_capabilitiesKey),
                        onFaq: () => _scrollTo(_faqKey),
                        onSignIn: () => _go('/login'),
                        onStart: _isAuthenticated
                            ? _openDashboard
                            : () => _go('/register'),
                        onDownload: () => _go('/download'),
                        authenticated: _isAuthenticated,
                        onDashboard: _openDashboard,
                      ),
                    ],
                  ),
                ),
                _NavigationBar(
                  scrolled: _scrolled,
                  narrow: narrow,
                  menuOpen: _menuOpen,
                  onMenu: () => setState(() => _menuOpen = !_menuOpen),
                  onHome: () => unawaited(
                    _scrollController.animateTo(
                      0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  onHow: () => _go('/how-it-works'),
                  onCapabilities: () => _scrollTo(_capabilitiesKey),
                  onFaq: () => _scrollTo(_faqKey),
                  onSignIn: () => _go('/login'),
                  onDownload: () => _go('/download'),
                  onStart: _isAuthenticated
                      ? _openDashboard
                      : () => _go('/register'),
                  authenticated: _isAuthenticated,
                  onDashboard: _openDashboard,
                ),
                const Positioned(
                  right: 22,
                  bottom: 22,
                  child: WebsiteStaffChatButton(),
                ),
                if (narrow && _menuOpen)
                  Positioned(
                    top: 68,
                    left: 16,
                    right: 16,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Material(
                          color: _LandingColors.paper,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _MobileMenuItem(
                                  label: 'How it works',
                                  onPressed: () => _go('/how-it-works'),
                                ),
                                _MobileMenuItem(
                                  label: 'Features',
                                  onPressed: () => _scrollTo(_capabilitiesKey),
                                ),
                                _MobileMenuItem(
                                  label: 'FAQ',
                                  onPressed: () => _scrollTo(_faqKey),
                                ),
                                _MobileMenuItem(
                                  label: 'Download app',
                                  onPressed: () => _go('/download'),
                                ),
                                const Divider(height: 12),
                                _MobileMenuItem(
                                  label: _isAuthenticated
                                      ? 'Dashboard'
                                      : 'Sign in',
                                  onPressed: _isAuthenticated
                                      ? _openDashboard
                                      : () => _go('/login'),
                                ),
                                if (!_isAuthenticated)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      8,
                                      6,
                                      4,
                                    ),
                                    child: _PrimaryButton(
                                      label: 'Get started',
                                      onPressed: () => _go('/register'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _LandingColors {
  static const paper = Color(0xFFF7F7F4);
  static const ink = Color(0xFF102C45);
  static const muted = Color(0xFF43596A);
  static const teal = Color(0xFF075078);
  static const green = Color(0xFF07966B);
  static const line = Color(0xFFDCE5E8);
}

class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar({required this.onViewUpdates});
  final VoidCallback onViewUpdates;

  @override
  Widget build(BuildContext context) {
    final androidReleaseAvailable =
        DownloadReleaseMetadata.current.isAndroidAvailable;
    return Container(
      width: double.infinity,
      color: _LandingColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFFB7F1DD),
                    size: 15,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'ANNOUNCEMENTS',
                    style: TextStyle(
                      color: Color(0xFFB7F1DD),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
              _AnnouncementItem(
                text: 'Report civic issues with SamadhanAI',
                showDivider: true,
              ),
              _AnnouncementItem(
                text: 'Follow available status updates after sign in',
                showDivider: true,
              ),
              _AnnouncementItem(
                text: androidReleaseAvailable
                    ? 'Android app download is available'
                    : 'Android app release is under verification',
              ),
              TextButton.icon(
                onPressed: onViewUpdates,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB7F1DD),
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('View updates'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.text, this.showDivider = false});
  final String text;
  final bool showDivider;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showDivider) ...[
        Container(width: 1, height: 12, color: Colors.white24),
        const SizedBox(width: 14),
      ],
      const Icon(Icons.circle, color: Color(0xFF54D6A5), size: 5),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );
}

class _CivicMessageStrip extends StatelessWidget {
  const _CivicMessageStrip();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _LandingColors.line)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 15,
                color: _LandingColors.green,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Clean cities, responsive governance and empowered citizens build a stronger India.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _LandingColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (constraints.maxWidth > 720) ...[
                const SizedBox(width: 22),
                const Text(
                  '- SamadhanAI',
                  style: TextStyle(color: _LandingColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.scrolled,
    required this.narrow,
    required this.menuOpen,
    required this.onMenu,
    required this.onHome,
    required this.onHow,
    required this.onCapabilities,
    required this.onFaq,
    required this.onSignIn,
    required this.onDownload,
    required this.onStart,
    required this.authenticated,
    required this.onDashboard,
  });

  final bool scrolled;
  final bool narrow;
  final bool menuOpen;
  final VoidCallback onMenu;
  final VoidCallback onHome;
  final VoidCallback onHow;
  final VoidCallback onCapabilities;
  final VoidCallback onFaq;
  final VoidCallback onSignIn;
  final VoidCallback onDownload;
  final VoidCallback onStart;
  final bool authenticated;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: scrolled ? .95 : .82),
            border: const Border(
              bottom: BorderSide(color: _LandingColors.line),
            ),
            boxShadow: scrolled
                ? const [
                    BoxShadow(
                      color: Color(0x100D2D43),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: onHome,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: _Wordmark(),
                      ),
                    ),
                    const Spacer(),
                    if (!narrow) ...[
                      _NavText('How It Works', onHow),
                      _NavText('Features', onCapabilities),
                      _NavText('FAQ', onFaq),
                      _NavText('Download App', onDownload),
                      const SizedBox(width: 14),
                      if (authenticated)
                        _PrimaryButton(
                          label: 'Dashboard',
                          onPressed: onDashboard,
                          compact: true,
                        )
                      else ...[
                        _TextButton(label: 'Sign In', onPressed: onSignIn),
                        const SizedBox(width: 10),
                        _PrimaryButton(
                          label: 'Get Started',
                          onPressed: onStart,
                          compact: true,
                        ),
                      ],
                    ] else
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5F1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7E5D9)),
                        ),
                        child: IconButton(
                          tooltip: menuOpen
                              ? 'Close navigation menu'
                              : 'Open navigation menu',
                          onPressed: onMenu,
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 27,
                          icon: Icon(menuOpen ? Icons.close : Icons.menu),
                          color: _LandingColors.ink,
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

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.inverse = false});
  final bool inverse;

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 19,
        letterSpacing: -.6,
        color: inverse ? Colors.white : _LandingColors.ink,
      ),
      children: [
        const TextSpan(text: 'Samadhan'),
        TextSpan(
          text: 'AI',
          style: TextStyle(color: _LandingColors.green),
        ),
      ],
    ),
  );
}

class _NavText extends StatelessWidget {
  const _NavText(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: _LandingColors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: _LandingColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    ),
    child: Text(label),
  );
}

class _CivicCityPainter extends CustomPainter {
  const _CivicCityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9FC8E2), Color(0xFFF9D7B0), Color(0xFFE7D9C2)],
        stops: [0, .54, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final sun = Paint()..color = const Color(0xFFFFF1D7).withValues(alpha: .9);
    canvas.drawCircle(
      Offset(size.width * .77, size.height * .21),
      size.height * .075,
      sun,
    );
    final glow = Paint()
      ..color = const Color(0xFFFFF5E1).withValues(alpha: .23);
    canvas.drawCircle(
      Offset(size.width * .77, size.height * .21),
      size.height * .14,
      glow,
    );

    _land(canvas, size, const Color(0xFFB6C8B3), .55, .65, 0);
    _land(canvas, size, const Color(0xFF809F88), .64, .73, .14);

    final distant = <(double, double, double)>[
      (.30, .19, .23),
      (.37, .13, .34),
      (.45, .20, .22),
      (.53, .11, .38),
      (.61, .17, .27),
      (.69, .10, .40),
      (.78, .17, .27),
      (.88, .13, .34),
      (.96, .21, .20),
    ];
    for (var i = 0; i < distant.length; i++) {
      final (x, top, width) = distant[i];
      final building = Rect.fromLTWH(
        size.width * x,
        size.height * top,
        size.width * width * .55,
        size.height * (.70 - top),
      );
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFF9AAEB0) : const Color(0xFFB4B8AE);
      canvas.drawRect(building, paint);
      final windows = Paint()
        ..color = const Color(0xFFFFE7BB).withValues(alpha: .58);
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 3; col++) {
          canvas.drawRect(
            Rect.fromLTWH(
              building.left + 4 + col * 8,
              building.top + 8 + row * 15,
              3,
              5,
            ),
            windows,
          );
        }
      }
    }

    final water = Path()
      ..moveTo(0, size.height * .70)
      ..cubicTo(
        size.width * .22,
        size.height * .63,
        size.width * .30,
        size.height * .80,
        size.width * .49,
        size.height * .73,
      )
      ..lineTo(size.width * .57, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      water,
      Paint()..color = const Color(0xFF83B7C3).withValues(alpha: .88),
    );
    final shimmer = Paint()
      ..color = const Color(0xFFDCE9D9).withValues(alpha: .6);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (.73 + i * .027);
      canvas.drawLine(
        Offset(size.width * .04, y),
        Offset(size.width * (.28 + (i % 3) * .05), y - 2),
        shimmer..strokeWidth = 1.4,
      );
    }

    final road = Path()
      ..moveTo(size.width * .45, size.height)
      ..cubicTo(
        size.width * .54,
        size.height * .84,
        size.width * .64,
        size.height * .88,
        size.width * .67,
        size.height * .73,
      )
      ..cubicTo(
        size.width * .70,
        size.height * .62,
        size.width * .88,
        size.height * .62,
        size.width,
        size.height * .58,
      )
      ..lineTo(size.width, size.height * .80)
      ..cubicTo(
        size.width * .85,
        size.height * .82,
        size.width * .75,
        size.height * .84,
        size.width * .73,
        size.height,
      )
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF69736D));
    final roadEdge = Paint()
      ..color = const Color(0xFFE8D4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(road, roadEdge);
    final lane = Paint()
      ..color = const Color(0xFFFFF2CF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final lanePath = Path()
      ..moveTo(size.width * .70, size.height)
      ..cubicTo(
        size.width * .74,
        size.height * .86,
        size.width * .79,
        size.height * .80,
        size.width,
        size.height * .70,
      );
    canvas.drawPath(lanePath, lane);

    _tree(
      canvas,
      Offset(size.width * .05, size.height * .69),
      size.height * .18,
    );
    _tree(
      canvas,
      Offset(size.width * .20, size.height * .75),
      size.height * .14,
    );
    _tree(
      canvas,
      Offset(size.width * .93, size.height * .62),
      size.height * .22,
    );
    _tree(
      canvas,
      Offset(size.width * .98, size.height * .72),
      size.height * .16,
    );

    final mapLine = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final map = Path()
      ..moveTo(size.width * .63, size.height * .12)
      ..cubicTo(
        size.width * .70,
        size.height * .20,
        size.width * .75,
        size.height * .09,
        size.width * .82,
        size.height * .15,
      )
      ..cubicTo(
        size.width * .89,
        size.height * .23,
        size.width * .84,
        size.height * .31,
        size.width * .92,
        size.height * .34,
      );
    canvas.drawPath(map, mapLine);
    final mapDot = Paint()..color = Colors.white.withValues(alpha: .8);
    for (final p in <Offset>[
      Offset(size.width * .68, size.height * .18),
      Offset(size.width * .77, size.height * .16),
      Offset(size.width * .85, size.height * .25),
      Offset(size.width * .91, size.height * .33),
    ]) {
      canvas.drawCircle(p, 3.5, mapDot);
    }
  }

  void _land(
    Canvas canvas,
    Size size,
    Color color,
    double y,
    double height,
    double phase,
  ) {
    final path = Path()..moveTo(0, size.height * y);
    for (var i = 0; i <= 8; i++) {
      final x = i / 8;
      final wave = (i.isEven ? .035 : -.025) + phase;
      path.lineTo(size.width * x, size.height * (y + wave));
    }
    path
      ..lineTo(size.width, size.height * height)
      ..lineTo(0, size.height * height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _tree(Canvas canvas, Offset base, double radius) {
    canvas.drawLine(
      base,
      base.translate(0, -radius * .7),
      Paint()
        ..color = const Color(0xFF634D3C)
        ..strokeWidth = 4,
    );
    final foliage = Paint()..color = const Color(0xFF376F54);
    for (final offset in <Offset>[
      Offset(-radius * .48, -radius * .65),
      Offset(-radius * .12, -radius),
      Offset(radius * .28, -radius * .82),
      Offset(radius * .52, -radius * .52),
    ]) {
      canvas.drawCircle(base + offset, radius * .42, foliage);
    }
  }

  @override
  bool shouldRepaint(covariant _CivicCityPainter oldDelegate) => false;
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.narrow,
    required this.scrollController,
    required this.onStart,
    required this.onHow,
  });
  final bool narrow;
  final ScrollController scrollController;
  final VoidCallback onStart;
  final VoidCallback onHow;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final viewport = MediaQuery.sizeOf(context).height;
    final heroHeight = narrow
        ? (viewport < 980 ? 980.0 : viewport)
        : (viewport * .52).clamp(440.0, 520.0).toDouble();
    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: scrollController,
              builder: (context, _) {
                final parallax = reducedMotion || !scrollController.hasClients
                    ? 0.0
                    : (scrollController.offset * .035).clamp(0.0, 18.0);
                return Transform.translate(
                  offset: Offset(0, parallax),
                  child: const CustomPaint(painter: _CivicCityPainter()),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: .9),
                    Colors.white.withValues(alpha: .78),
                    Colors.white.withValues(alpha: .28),
                    Colors.white.withValues(alpha: .05),
                  ],
                  stops: const [0, .38, .68, 1],
                ),
              ),
            ),
          ),
          Align(
            alignment: narrow ? Alignment.topCenter : Alignment.center,
            child: _ContentWidth(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 22 : 34,
                  vertical: 20,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 760;
                    final copy = _HeroCopy(
                      onStart: onStart,
                      onHow: onHow,
                      narrow: narrow,
                    );
                    final phone = SizedBox(
                      height: stack ? 356 : heroHeight * .9,
                      child: const AspectRatio(
                        aspectRatio: .53,
                        child: _PhoneMockup(),
                      ),
                    );
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, child) => Opacity(
                        opacity: progress,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            reducedMotion ? 0 : 14 * (1 - progress),
                          ),
                          child: child,
                        ),
                      ),
                      child: stack
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                copy,
                                const SizedBox(height: 18),
                                phone,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 12, child: copy),
                                Expanded(
                                  flex: 8,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: phone,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
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
    required this.onStart,
    required this.onHow,
    required this.narrow,
  });
  final VoidCallback onStart;
  final VoidCallback onHow;
  final bool narrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          style: TextStyle(
            color: _LandingColors.ink,
            fontSize: narrow ? 39 : 51,
            height: 1.03,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.8,
          ),
          children: [
            const TextSpan(text: 'Your Voice.\n'),
            TextSpan(
              text: 'Better Communities.',
              style: const TextStyle(color: _LandingColors.green),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: const Text(
          'Report public issues, follow available status updates, and help build cleaner, safer communities with SamadhanAI.',
          style: TextStyle(
            color: _LandingColors.muted,
            fontSize: 17,
            height: 1.5,
          ),
        ),
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _PrimaryButton(label: 'Report an Issue', onPressed: onStart),
          _OutlineButton(label: 'Explore How It Works', onPressed: onHow),
        ],
      ),
    ],
  );
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Illustrative preview of the SamadhanAI citizen app interface',
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF14212A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF566570), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55304454),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Container(
          color: const Color(0xFFF7FAFC),
          padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _LandingColors.ink,
                    ),
                  ),
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 10,
                    color: _LandingColors.ink,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Samadhan',
                            style: TextStyle(
                              color: _LandingColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 8,
                            ),
                          ),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: _LandingColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: _LandingColors.ink,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Hello there',
                style: TextStyle(fontSize: 9, color: _LandingColors.muted),
              ),
              const SizedBox(height: 2),
              const Text(
                'How can we help?',
                style: TextStyle(
                  fontSize: 8,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _LandingColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              const _PreviewTile(
                icon: Icons.edit_note_rounded,
                title: 'Report Civic Issue',
                subtitle: 'Tell us what needs attention',
                tint: Color(0xFFDBEAFE),
                accent: Color(0xFF2563EB),
              ),
              const SizedBox(height: 6),
              const _PreviewTile(
                icon: Icons.track_changes_rounded,
                title: 'Track Progress',
                subtitle: 'Follow available updates',
                tint: Color(0xFFFFE8E2),
                accent: Color(0xFFEA5539),
              ),
              const SizedBox(height: 6),
              const _PreviewTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'See updates in your account',
                tint: Color(0xFFFFF0CF),
                accent: Color(0xFFE69A1B),
              ),
              const SizedBox(height: 6),
              const _PreviewTile(
                icon: Icons.groups_2_outlined,
                title: 'Better Communities',
                subtitle: 'A shared civic journey',
                tint: Color(0xFFDDF4E8),
                accent: Color(0xFF13966C),
              ),
              const Spacer(),
              const Divider(height: 1, color: _LandingColors.line),
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 14,
                      color: _LandingColors.teal,
                    ),
                    Icon(
                      Icons.assignment_outlined,
                      size: 14,
                      color: _LandingColors.muted,
                    ),
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: _LandingColors.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFE6ECEF)),
    ),
    child: Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: accent),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: _LandingColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 7,
                  color: _LandingColors.muted,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 13,
          color: _LandingColors.muted,
        ),
      ],
    ),
  );
}

class _PublicUpdatesSection extends StatelessWidget {
  const _PublicUpdatesSection({
    super.key,
    required this.narrow,
    required this.onReport,
    required this.onTrack,
    required this.onDownload,
  });

  final bool narrow;
  final VoidCallback onReport;
  final VoidCallback onTrack;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final releaseAvailable = DownloadReleaseMetadata.current.isAndroidAvailable;
    final updates = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _UpdatesHeading(
          title: 'What’s new',
          subtitle: 'SamadhanAI platform updates',
        ),
        const SizedBox(height: 10),
        _UpdateRow(
          icon: Icons.phone_android_rounded,
          color: const Color(0xFF149447),
          title: 'Android app',
          body: releaseAvailable
              ? 'A verified release is available on the Download App page.'
              : 'Release checks are underway. Download links will open after verification and publication.',
          badge: releaseAvailable ? 'AVAILABLE' : 'IN REVIEW',
        ),
        const Divider(height: 1),
        const _UpdateRow(
          icon: Icons.assignment_outlined,
          color: Color(0xFF2878D5),
          title: 'Report and follow civic issues',
          body:
              'Sign in to submit a report and view the status information available to your account.',
          badge: 'SERVICE INFO',
        ),
      ],
    );
    final happening = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _UpdatesHeading(
          title: 'What’s happening',
          subtitle: 'Citizen services and local action',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F8),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _LandingColors.line),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _LandingColors.teal,
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Use SamadhanAI to raise local concerns such as missed waste collection, broken streetlights, damaged roads, or water access. For urgent matters, contact your local authority directly.',
                  style: TextStyle(
                    color: _LandingColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ServiceAction(
              icon: Icons.add_circle_outline,
              label: 'Report an issue',
              onTap: onReport,
            ),
            _ServiceAction(
              icon: Icons.track_changes_outlined,
              label: 'Track a report',
              onTap: onTrack,
            ),
            _ServiceAction(
              icon: Icons.download_outlined,
              label: 'Get the app',
              onTap: onDownload,
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F8F9),
      child: _ContentWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: narrow ? 20 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    color: _LandingColors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Citizen Services & Latest Updates',
                      style: TextStyle(
                        color: _LandingColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                  ),
                  if (!narrow) const _OfficialSourceLabel(),
                ],
              ),
              const SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 760
                    ? Column(
                        children: [
                          updates,
                          const SizedBox(height: 14),
                          happening,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: updates),
                          const SizedBox(width: 22),
                          Expanded(flex: 5, child: happening),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdatesHeading extends StatelessWidget {
  const _UpdatesHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _LandingColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _LandingColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _OfficialSourceLabel extends StatelessWidget {
  const _OfficialSourceLabel();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _LandingColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'SamadhanAI information',
      style: TextStyle(
        color: _LandingColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.badge,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _LandingColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: _LandingColors.muted,
                  fontSize: 12,
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

class _ServiceAction extends StatelessWidget {
  const _ServiceAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 13)),
    style: OutlinedButton.styleFrom(
      foregroundColor: _LandingColors.teal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      side: const BorderSide(color: _LandingColors.line),
      backgroundColor: Colors.white,
    ),
  );
}

class _HowSection extends StatelessWidget {
  const _HowSection({super.key, required this.narrow});
  final bool narrow;

  static const _steps = <(String, String, IconData)>[
    (
      'Report Easily',
      'Describe the issue and add details or evidence when available.',
      Icons.edit_note_outlined,
    ),
    (
      'Track Progress',
      'Follow the status updates available for your grievance.',
      Icons.search_rounded,
    ),
    (
      'Build Better Communities',
      'Share local concerns to support safer, cleaner public spaces.',
      Icons.groups_2_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    child: _ContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: narrow ? 28 : 34,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'How It Works',
                  style: TextStyle(
                    color: _LandingColors.ink,
                    fontSize: narrow ? 23 : 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.45,
                  ),
                ),
                const Spacer(),
                if (!narrow)
                  const Text(
                    'A simple process for a stronger community',
                    style: TextStyle(color: _LandingColors.muted, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 690
                  ? Column(
                      children: [
                        for (var i = 0; i < _steps.length; i++) ...[
                          _StepRow(index: i + 1, step: _steps[i]),
                          if (i < _steps.length - 1) const SizedBox(height: 14),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        for (var i = 0; i < _steps.length; i++) ...[
                          Expanded(
                            child: _StepColumn(index: i + 1, step: _steps[i]),
                          ),
                          if (i < _steps.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: _LandingColors.teal,
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.step});
  final int index;
  final (String, String, IconData) step;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _StepIcon(icon: step.$3),
      const SizedBox(width: 12),
      Expanded(
        child: _StepText(index: index, step: step),
      ),
    ],
  );
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({required this.index, required this.step});
  final int index;
  final (String, String, IconData) step;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _StepIcon(icon: step.$3),
      const SizedBox(width: 12),
      Expanded(
        child: _StepText(index: index, step: step),
      ),
    ],
  );
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: const BoxDecoration(
      color: Color(0xFFE3F5EF),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: _LandingColors.green, size: 22),
  );
}

class _StepText extends StatelessWidget {
  const _StepText({required this.index, required this.step});
  final int index;
  final (String, String, IconData) step;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$index. ${step.$1}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _LandingColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        step.$2,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _LandingColors.muted,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _CapabilitiesSection extends StatelessWidget {
  const _CapabilitiesSection({super.key, required this.narrow});
  final bool narrow;

  static const _items = <(IconData, String, String, Color, Color)>[
    (
      Icons.assignment_outlined,
      'Grievance Submission',
      'Report civic issues with useful details and evidence.',
      Color(0xFFDDF4E8),
      Color(0xFF15976D),
    ),
    (
      Icons.track_changes_rounded,
      'Status Tracking',
      'Follow progress with the updates available to you.',
      Color(0xFFDFEEFF),
      Color(0xFF2678DB),
    ),
    (
      Icons.auto_awesome_rounded,
      'AI Assistance',
      'Get help drafting and classifying your issue when configured.',
      Color(0xFFF0E7FF),
      Color(0xFF8050CB),
    ),
    (
      Icons.notifications_active_outlined,
      'Notifications',
      'See updates in your account; delivery depends on service setup.',
      Color(0xFFFFEBDD),
      Color(0xFFE97932),
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFFAFCFC),
    child: _ContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: narrow ? 26 : 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Features',
              style: TextStyle(
                color: _LandingColors.ink,
                fontSize: narrow ? 23 : 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -.45,
              ),
            ),
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 430
                    ? 1
                    : constraints.maxWidth < 780
                    ? 2
                    : 4;
                return GridView.builder(
                  itemCount: _items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 92,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) =>
                      _CapabilityItem(item: _items[index]),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _CapabilityItem extends StatelessWidget {
  const _CapabilityItem({required this.item});
  final (IconData, String, String, Color, Color) item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEBF0F1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080C3045),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: item.$4, shape: BoxShape.circle),
          child: Icon(item.$1, color: item.$5, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _LandingColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _LandingColors.muted,
                  height: 1.25,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({super.key, required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    child: _ContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: narrow ? 30 : 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Frequently Asked Questions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _LandingColors.ink,
                      fontSize: narrow ? 21 : 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
                if (!narrow) const Spacer(),
                if (!narrow)
                  const Text(
                    'Have another question?',
                    style: TextStyle(color: _LandingColors.muted, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final questions = _WebsiteLandingPageState._faqs;
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      for (var i = 0; i < questions.length; i++)
                        _FaqItem(
                          question: questions[i].$1,
                          answer: questions[i].$2,
                          initiallyExpanded: false,
                        ),
                    ],
                  );
                }
                final split = (questions.length + 1) ~/ 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (final item in questions.take(split))
                            _FaqItem(question: item.$1, answer: item.$2),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          for (final item in questions.skip(split))
                            _FaqItem(question: item.$1, answer: item.$2),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });
  final String question;
  final String answer;
  final bool initiallyExpanded;
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  late bool _expanded = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7ECEF)),
      ),
      child: Semantics(
        container: true,
        button: true,
        expanded: _expanded,
        label: widget.question,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            color: _LandingColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: duration,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _LandingColors.teal,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 13, right: 34, bottom: 13),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      color: _LandingColors.muted,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: duration,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onHow,
    required this.onCapabilities,
    required this.onFaq,
    required this.onSignIn,
    required this.onStart,
    required this.onDownload,
    required this.authenticated,
    required this.onDashboard,
  });
  final VoidCallback onHow;
  final VoidCallback onCapabilities;
  final VoidCallback onFaq;
  final VoidCallback onSignIn;
  final VoidCallback onStart;
  final VoidCallback onDownload;
  final bool authenticated;
  final VoidCallback onDashboard;
  @override
  Widget build(BuildContext context) => Container(
    color: _LandingColors.ink,
    width: double.infinity,
    child: _ContentWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 45, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 650;
                final brand = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Wordmark(inverse: true),
                    const SizedBox(height: 14),
                    const SizedBox(
                      width: 350,
                      child: Text(
                        'A digital place to submit public-service grievances and follow the information available in your account.',
                        style: TextStyle(
                          color: Color(0xFFBBC8C5),
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
                final links = Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    _FooterLink('How it works', onHow),
                    _FooterLink('Features', onCapabilities),
                    _FooterLink('FAQ', onFaq),
                    _FooterLink('Download app', onDownload),
                    if (authenticated)
                      _FooterLink('Dashboard', onDashboard)
                    else ...[
                      _FooterLink('Sign in', onSignIn),
                      _FooterLink('Get started', onStart),
                    ],
                  ],
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [brand, const SizedBox(height: 28), links],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: brand),
                          const SizedBox(width: 30),
                          Flexible(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: links,
                            ),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 36),
            const Divider(color: Color(0xFF405153), height: 1),
            const SizedBox(height: 17),
            const Text(
              'Â© SamadhanAI',
              style: TextStyle(color: Color(0xFFBBC8C5), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFD8E1DE),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    ),
    child: Text(label),
  );
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1600),
      child: child,
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool compact;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _LandingColors.green,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 17 : 22,
        vertical: compact ? 13 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: compact ? 13 : 15,
      ),
    ),
    child: Text(label),
  );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _LandingColors.ink,
        side: const BorderSide(color: _LandingColors.green, width: 1),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 20,
          vertical: compact ? 12 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline_rounded, size: compact ? 15 : 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _LandingColors.ink,
      side: const BorderSide(color: _LandingColors.green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    ),
    child: Text(label),
  );
}
