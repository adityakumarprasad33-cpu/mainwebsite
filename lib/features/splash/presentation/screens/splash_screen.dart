import 'dart:async';
import 'package:citizen_app/platform/bootstrap/bootstrap_manager.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Production-Grade Animated Splash Screen for SamadhanAI
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  String _statusText = 'Preparing SamadhanAI...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _statusText = 'Checking your sign-in and app services...';
    });

    BootstrapResult bootstrapResult;
    try {
      bootstrapResult = await BootstrapManager.initialize();
    } catch (e, stack) {
      debugPrint('[SplashScreen] Bootstrap failed: $e');
      debugPrint('[SplashScreen] Stack: $stack');
      // Fallback to login screen on any bootstrap error
      bootstrapResult = BootstrapResult(
        isAuthenticated: false,
        role: UserRoleEnum.citizen,
        initialRoute: '/login',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _statusText = 'Your workspace is ready.';
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    unawaited(
      Navigator.of(context).pushNamedAndRemoveUntil(
        bootstrapResult.initialRoute,
        (route) => false,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070E1E), // Deep Bihar midnight blue
              Color(0xFF0F2B48),
              Color(0xFF0F4C81), // Bihar official governance blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Glowing Emblem
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value * _glowAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFFFB300,
                            ).withValues(alpha: 0.25),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0F4C81),
                              child: const Icon(
                                Icons.shield_rounded,
                                size: 80,
                                color: Color(0xFFFFB300),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Title and Tagline Fade-In
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'समाधान AI',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SamadhanAI Citizen Portal',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFB300), // Bihar Gold
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        'Citizen Grievance Portal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const _StartupSkeletonPanel(),

              const Spacer(flex: 3),

              // Animated Progress & Status
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 190,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            minHeight: 5,
                            backgroundColor: Color(0x334B7090),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF23B58A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupSkeletonPanel extends StatelessWidget {
  const _StartupSkeletonPanel();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SkeletonBlock(
                width: 38,
                height: 38,
                radius: BorderRadius.circular(13),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(width: 148, height: 10),
                    SizedBox(height: 7),
                    _SkeletonBlock(width: 96, height: 7),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SkeletonBlock(width: double.infinity, height: 42),
          const SizedBox(height: 9),
          Row(
            children: [
              const Expanded(child: _SkeletonBlock(height: 28)),
              const SizedBox(width: 9),
              const Expanded(child: _SkeletonBlock(height: 28)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    this.radius = const BorderRadius.all(Radius.circular(6)),
  });

  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: radius,
      gradient: const LinearGradient(
        colors: [Color(0x1FFFFFFF), Color(0x35FFFFFF), Color(0x1FFFFFFF)],
      ),
    ),
  );
}
