import 'dart:async';
import 'dart:ui';

import 'package:citizen_app/features/grievances/presentation/screens/comments_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/create_grievance_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/draft_management_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/evidence_viewer_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/feedback_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/grievance_detail_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/my_grievances_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/runix_ai_chat_screen.dart';
import 'package:citizen_app/features/grievances/presentation/screens/timeline_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/admin_dashboard_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/create_employee_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/employee_management_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/login_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/officer_dashboard_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/profile_screen.dart';
import 'package:citizen_app/features/iam/presentation/screens/register_screen.dart';
import 'package:citizen_app/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:citizen_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:citizen_app/features/website/presentation/website_root_router.dart';
import 'package:citizen_app/features/website/presentation/website_how_it_works_page.dart';
import 'package:citizen_app/features/website/presentation/website_download_page.dart';
import 'package:citizen_app/platform/bootstrap/bootstrap_manager.dart';
import 'package:citizen_app/platform/bootstrap/protected_route_guard.dart';
import 'package:citizen_app/platform/bootstrap/network_config_screen.dart';
import 'package:citizen_app/platform/localization/language_provider.dart';
import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

/// Global crash details for UI display
class CrashDetails {
  static String? error;
  static String? stackTrace;
  static DateTime? timestamp;

  static void capture(Object error, StackTrace stack) {
    CrashDetails.error = error.toString();
    CrashDetails.stackTrace = stack.toString();
    CrashDetails.timestamp = DateTime.now();
  }

  static void clear() {
    error = null;
    stackTrace = null;
    timestamp = null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A public website page does not need backend readiness to render. Start
  // endpoint discovery in the background on Web so a CORS/API outage cannot
  // leave the whole site on a blank startup screen.
  if (kIsWeb) {
    unawaited(_initializeWebApiConfig());
  } else {
    await ApiClientConfig.initialize();
  }

  // Keep the public web page responsive while Firebase warms up. Native
  // entry points still wait for Firebase before opening the app.
  if (kIsWeb) {
    unawaited(_initializeFirebase());
  } else {
    await _initializeFirebase();
  }

  // Setup crash handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashDetails.capture(
      details.exception,
      details.stack ?? StackTrace.current,
    );
    if (kDebugMode) FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashDetails.capture(error, stack);
    if (kDebugMode) debugPrintStack(stackTrace: stack);
    return true;
  };

  runApp(AppRestart(child: const SamadhanApp()));
}

Future<void> _initializeWebApiConfig() async {
  try {
    await ApiClientConfig.initialize();
    debugPrint(ApiClientConfig.debugInfo);
  } catch (error, stack) {
    debugPrint('[Main] Web API endpoint discovery failed: $error');
    debugPrintStack(stackTrace: stack);
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase initialized successfully');
  } catch (error, stack) {
    debugPrint('[Main] Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stack);
  }
}

/// Restarts the app subtree without calling runApp again from inside a frame.
class AppRestart extends StatefulWidget {
  AppRestart({required this.child}) : super(key: _restartKey);

  final Widget child;
  static final GlobalKey<_AppRestartState> _restartKey =
      GlobalKey<_AppRestartState>();

  static void restartApp() => _restartKey.currentState?._restart();

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _childKey = UniqueKey();

  void _restart() {
    setState(() => _childKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: _childKey,
    child: widget.child,
  );
}

/// SamadhanApp is the root widget of the SamadhanAI Citizen Platform.
class SamadhanApp extends StatelessWidget {
  const SamadhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Show crash UI if there was a crash during initialization
    if (CrashDetails.error != null) {
      return MaterialApp(
        title: 'SamadhanAI - Crash Report',
        debugShowCheckedModeBanner: false,
        home: CrashReportScreen(),
      );
    }

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageProvider.instance,
      builder: (context, currentLang, _) {
        return MaterialApp(
          title: LanguageProvider.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F4C81),
              primary: const Color(0xFF0F4C81),
              secondary: const Color(0xFF2E7D32),
              surface: const Color(0xFFF5F5F7),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          ),
          // Error boundary for unhandled errors
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return Material(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details.exceptionAsString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: AppRestart.restartApp,
                          child: const Text('Restart App'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            };
            return child!;
          },
          // Flutter Web opens the requested deep link (normally '/') directly;
          // Android/iOS retain the existing splash-first startup.
          initialRoute: kIsWeb ? null : '/splash',
          routes: {
            '/network-settings': (context) => const NetworkConfigScreen(),
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/download': (context) => const WebsiteDownloadPage(),
            '/how-it-works': (context) => const WebsiteHowItWorksPage(),
            '/': (context) => kIsWeb
                ? WebsiteRootRouter(
                    authenticatedBuilder: (context, result) {
                      if (result.role == UserRoleEnum.nodalOfficer) {
                        return ProtectedRouteGuard(
                          allowedRoles: const {
                            UserRoleEnum.nodalOfficer,
                            UserRoleEnum.departmentAdmin,
                            UserRoleEnum.superAdmin,
                          },
                          child: const OfficerDashboardScreen(),
                        );
                      }
                      if (result.role == UserRoleEnum.departmentAdmin ||
                          result.role == UserRoleEnum.superAdmin) {
                        return ProtectedRouteGuard(
                          allowedRoles: const {
                            UserRoleEnum.departmentAdmin,
                            UserRoleEnum.superAdmin,
                          },
                          child: const AdminDashboardScreen(),
                        );
                      }
                      return ProtectedRouteGuard(
                        allowedRoles: const {UserRoleEnum.citizen},
                        child: const CitizenDashboardScreen(),
                      );
                    },
                  )
                : ProtectedRouteGuard(
                    allowedRoles: {
                      UserRoleEnum.citizen,
                      UserRoleEnum.nodalOfficer,
                      UserRoleEnum.departmentAdmin,
                      UserRoleEnum.superAdmin,
                    },
                    child: CitizenDashboardScreen(),
                  ),
            '/officer-dashboard': (context) => ProtectedRouteGuard(
              allowedRoles: {
                UserRoleEnum.nodalOfficer,
                UserRoleEnum.departmentAdmin,
                UserRoleEnum.superAdmin,
              },
              child: OfficerDashboardScreen(),
            ),
            '/admin-dashboard': (context) => ProtectedRouteGuard(
              allowedRoles: {
                UserRoleEnum.departmentAdmin,
                UserRoleEnum.superAdmin,
              },
              child: AdminDashboardScreen(),
            ),
            '/citizen-dashboard': (context) => ProtectedRouteGuard(
              allowedRoles: const {UserRoleEnum.citizen},
              child: CitizenDashboardScreen(),
            ),
            '/admin/create-employee': (context) => ProtectedRouteGuard(
              allowedRoles: {
                UserRoleEnum.departmentAdmin,
                UserRoleEnum.superAdmin,
              },
              requiredPermissions: {'iam.employee.provision'},
              child: CreateEmployeeScreen(),
            ),
            '/admin/employees': (context) => ProtectedRouteGuard(
              allowedRoles: {
                UserRoleEnum.departmentAdmin,
                UserRoleEnum.superAdmin,
              },
              requiredPermissions: {'iam.employee.list'},
              child: EmployeeManagementScreen(),
            ),
            '/profile': (context) => ProtectedRouteGuard(
              child: ProfileScreen(),
            ),
            '/create-grievance': (context) => ProtectedRouteGuard(
              child: CreateGrievanceScreen(),
            ),
            '/my-grievances': (context) => ProtectedRouteGuard(
              child: MyGrievancesScreen(),
            ),
            '/grievance-detail': (context) => ProtectedRouteGuard(
              child: GrievanceDetailScreen(
                publicId: ModalRoute.of(context)?.settings.arguments as String?,
              ),
            ),
            '/timeline': (context) => ProtectedRouteGuard(
              child: TimelineScreen(),
            ),
            '/evidence': (context) => ProtectedRouteGuard(
              child: EvidenceViewerScreen(),
            ),
            '/comments': (context) => ProtectedRouteGuard(
              child: CommentsScreen(),
            ),
            '/feedback': (context) => ProtectedRouteGuard(
              child: FeedbackScreen(),
            ),
            '/drafts': (context) => ProtectedRouteGuard(
              child: DraftManagementScreen(),
            ),
            '/notifications': (context) => ProtectedRouteGuard(
              child: NotificationCenterScreen(),
            ),
            '/ai-assistant': (context) => ProtectedRouteGuard(
              child: RunixAiChatScreen(),
            ),
          },
        );
      },
    );
  }
}

/// Premium Citizen Dashboard with modern government styling
class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  int _selectedIndex = 0;

  void _showLanguageSelector(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7).withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageProvider.tr('select_language'),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...AppLanguage.values.map((lang) {
                      final isSelected =
                          LanguageProvider.instance.value == lang;
                      return ListTile(
                        leading: Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          lang.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF0F4C81)
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0F4C81),
                              )
                            : null,
                        onTap: () {
                          LanguageProvider.instance.setLanguage(lang);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ); // semicolon for return statement
        }, // closes builder function
      ), // closes showModalBottomSheet
    ); // closes unawaited
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LanguageProvider.tr('app_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    LanguageProvider.tr('app_subtitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Language / भाषा',
            icon: const Icon(Icons.language_outlined),
            onPressed: () => _showLanguageSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              unawaited(Navigator.pushNamed(context, '/notifications'));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              unawaited(Navigator.pushNamed(context, '/profile'));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero Banner with Glassmorphism ──
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1A5276)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            LanguageProvider.tr('banner_tag'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          LanguageProvider.tr('banner_title'),
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LanguageProvider.tr('banner_subtitle'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F4C81),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                unawaited(
                                  Navigator.pushNamed(
                                    context,
                                    '/create-grievance',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(
                                LanguageProvider.tr('btn_lodge'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                unawaited(
                                  Navigator.pushNamed(
                                    context,
                                    '/my-grievances',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.assignment_outlined),
                              label: Text(
                                LanguageProvider.tr('btn_my_complaints'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stat Cards with Glass Effect ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard(
                    LanguageProvider.tr('stat_active'),
                    '1',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    LanguageProvider.tr('stat_resolved'),
                    '0',
                    Icons.check_circle_outline,
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    LanguageProvider.tr('stat_drafts'),
                    '0',
                    Icons.drafts_outlined,
                    const Color(0xFF0F4C81),
                  ),
                ],
              ),
            ),
          ),

          // ── Services Section Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                LanguageProvider.tr('section_services'),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),

          // ── Module Grid Tiles ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
              children: [
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_lodge_title'),
                  subtitle: LanguageProvider.tr('mod_lodge_sub'),
                  icon: Icons.edit_document,
                  color: const Color(0xFF0F4C81),
                  route: '/create-grievance',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_track_title'),
                  subtitle: LanguageProvider.tr('mod_track_sub'),
                  icon: Icons.track_changes,
                  color: const Color(0xFF1A5276),
                  route: '/my-grievances',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_notif_title'),
                  subtitle: LanguageProvider.tr('mod_notif_sub'),
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFB8860B),
                  route: '/notifications',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_timeline_title'),
                  subtitle: LanguageProvider.tr('mod_timeline_sub'),
                  icon: Icons.timeline,
                  color: const Color(0xFF2E7D32),
                  route: '/timeline',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_evidence_title'),
                  subtitle: LanguageProvider.tr('mod_evidence_sub'),
                  icon: Icons.perm_media_outlined,
                  color: const Color(0xFF6A1B9A),
                  route: '/evidence',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_comments_title'),
                  subtitle: LanguageProvider.tr('mod_comments_sub'),
                  icon: Icons.comment_bank_outlined,
                  color: const Color(0xFFBF360C),
                  route: '/comments',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_feedback_title'),
                  subtitle: LanguageProvider.tr('mod_feedback_sub'),
                  icon: Icons.rate_review_outlined,
                  color: const Color(0xFFB8860B),
                  route: '/feedback',
                ),
                _buildModuleTile(
                  context,
                  title: LanguageProvider.tr('mod_profile_title'),
                  subtitle: LanguageProvider.tr('mod_profile_sub'),
                  icon: Icons.person_pin_outlined,
                  color: const Color(0xFF0F4C81),
                  route: '/profile',
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              unawaited(Navigator.pushNamed(context, '/my-grievances'));
            }
            if (index == 2) {
              unawaited(Navigator.pushNamed(context, '/create-grievance'));
            }
            if (index == 3) {
              unawaited(Navigator.pushNamed(context, '/profile'));
            }
          },
          backgroundColor: const Color(0xFFF5F5F7),
          elevation: 0,
          selectedItemColor: const Color(0xFF0F4C81),
          unselectedItemColor: const Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: LanguageProvider.tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt),
              label: LanguageProvider.tr('nav_complaints'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle),
              label: LanguageProvider.tr('nav_lodge'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: LanguageProvider.tr('nav_profile'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          unawaited(Navigator.pushNamed(context, '/ai-assistant'));
        },
        icon: const Icon(Icons.psychology),
        label: Text(
          'RunixGov AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        unawaited(Navigator.pushNamed(context, route));
      },
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CrashReportScreen extends StatelessWidget {
  const CrashReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              Text(
                'App Crashed During Startup',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The app encountered an error during initialization. Please screenshot this screen and share with the developer.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error Details:',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      CrashDetails.error ?? 'Unknown error',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        color: Colors.red[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Timestamp: ${CrashDetails.timestamp?.toIso8601String() ?? 'Unknown'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Stack Trace:',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  CrashDetails.stackTrace ?? 'No stack trace available',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CrashDetails.clear();
                        AppRestart.restartApp();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Copy to clipboard would need permission, just show toast
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error details shown above - take screenshot',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
