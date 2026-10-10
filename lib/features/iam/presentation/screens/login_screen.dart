import 'dart:async';
import 'package:citizen_app/platform/firebase/firebase_service.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Production-Grade SamadhanAI Login & Authentication Portal
/// Uses Firebase Auth (works anywhere) + syncs with backend for API token.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPhoneMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter both your ${_isPhoneMode ? "phone number" : "email address"} and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _isPhoneMode || !identifier.contains('@')
          ? '$identifier@citizen.samadhan.gov.in'
          : identifier;

      // 1. Authenticate with Firebase (works anywhere - cloud)
      final userProfile = await FirebaseService.instance.signInWithFirebase(
        email: email,
        password: password,
      );

      final roleStr = (userProfile['role'] as String? ?? 'citizen')
          .toLowerCase();
      var role = UserRoleEnum.citizen;
      var targetRoute = '/';

      if (roleStr.contains('officer') || roleStr.contains('nodal')) {
        role = UserRoleEnum.nodalOfficer;
        targetRoute = '/officer-dashboard';
      } else if (roleStr.contains('admin')) {
        role = UserRoleEnum.departmentAdmin;
        targetRoute = '/admin-dashboard';
      }

      final roleLabel = role == UserRoleEnum.citizen
          ? 'Citizen'
          : (role == UserRoleEnum.nodalOfficer
                ? 'Nodal Officer'
                : 'Department Admin');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Firebase Auth Verified: $email ($roleLabel)',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F4C81),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      unawaited(
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(targetRoute, (route) => false),
      );
    } catch (err) {
      String msg = err.toString();
      if (msg.contains('EMAIL_NOT_FOUND') || msg.contains('user-not-found')) {
        msg = 'No user account found with this email. Please register first.';
      } else if (msg.contains('INVALID_PASSWORD') ||
          msg.contains('wrong-password') ||
          msg.contains('INVALID_LOGIN_CREDENTIALS')) {
        msg = 'Invalid credentials. Incorrect password.';
      } else if (msg.contains('USER_DISABLED')) {
        msg = 'This user account has been suspended by administration.';
      } else if (msg.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        msg =
            'Access temporarily blocked due to multiple failed attempts. Try again later.';
      } else if (msg.contains('Exception:')) {
        msg = msg.replaceFirst('Exception:', '').trim();
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  void _showServerSettings() {
    unawaited(Navigator.of(context).pushNamed('/network-settings'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'SamadhanAI Identity Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Gateway Settings',
            onPressed: _showServerSettings,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official Header with Emblem
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F4C81,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF0F4C81),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In to SamadhanAI',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F4C81),
                                ),
                              ),
                              Text(
                                'Bihar Public Grievance Portal',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Method Toggle (Email / Phone)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                'Email ID',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: !_isPhoneMode,
                            selectedColor: const Color(0xFF0F4C81),
                            labelStyle: TextStyle(
                              color: !_isPhoneMode
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _isPhoneMode = false;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                'Mobile Phone',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: _isPhoneMode,
                            selectedColor: const Color(0xFF0F4C81),
                            labelStyle: TextStyle(
                              color: _isPhoneMode
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _isPhoneMode = true;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFB91C1C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Identifier Field
                    TextField(
                      controller: _identifierController,
                      keyboardType: _isPhoneMode
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _isPhoneMode
                            ? 'Mobile Phone Number (+91)'
                            : 'Email Address',
                        hintText: _isPhoneMode
                            ? 'Enter registered mobile number'
                            : 'Enter registered email address',
                        labelStyle: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        prefixIcon: Icon(
                          _isPhoneMode
                              ? Icons.phone_android
                              : Icons.email_outlined,
                          color: const Color(0xFF0F4C81),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your account password',
                        labelStyle: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF0F4C81),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF6B7280),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C81),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),

                    // Public Citizen Registration Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New Citizen? ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            'Register Citizen Account',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4C81),
                            ),
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
    );
  }
}
