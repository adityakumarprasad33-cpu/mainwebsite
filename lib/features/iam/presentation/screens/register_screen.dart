import 'dart:async';
import 'package:citizen_app/platform/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Production-Grade Citizen Registration Portal
/// Uses Firebase Auth (works anywhere - cloud) + syncs with backend for API token.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedState = 'BR'; // Default to Bihar

  static const List<Map<String, String>> _indianStates = [
    {'code': 'DL', 'name': 'Delhi (NCT)'},
    {'code': 'MH', 'name': 'Maharashtra'},
    {'code': 'KA', 'name': 'Karnataka'},
    {'code': 'UP', 'name': 'Uttar Pradesh'},
    {'code': 'BR', 'name': 'Bihar'},
    {'code': 'TN', 'name': 'Tamil Nadu'},
    {'code': 'WB', 'name': 'West Bengal'},
    {'code': 'GJ', 'name': 'Gujarat'},
    {'code': 'RJ', 'name': 'Rajasthan'},
    {'code': 'KL', 'name': 'Kerala'},
    {'code': 'TG', 'name': 'Telangana'},
    {'code': 'MP', 'name': 'Madhya Pradesh'},
    {'code': 'PB', 'name': 'Punjab'},
    {'code': 'HR', 'name': 'Haryana'},
  ];

  bool _isPhoneMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final district = _districtController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty || contact.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill out all required fields.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _isPhoneMode || !contact.contains('@')
          ? '$contact@citizen.samadhan.gov.in'
          : contact;

      // 1. Register with Firebase Auth (works anywhere - cloud)
      await FirebaseService.instance.registerWithFirebase(
        email: email,
        password: password,
        displayName: name,
        phone: _isPhoneMode ? contact : null,
        stateCode: _selectedState,
        district: district.isNotEmpty ? district : null,
        pincode: pincode.isNotEmpty ? pincode : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account Created! Welcome $name.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      unawaited(
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
      );
    } catch (err) {
      String msg = err.toString();
      if (msg.contains('EMAIL_EXISTS') || msg.contains('email-already-in-use')) {
        msg = 'This email is already registered. Please sign in.';
      } else if (msg.contains('WEAK_PASSWORD') || msg.contains('weak-password')) {
        msg = 'Password is too weak. Please use at least 6 characters.';
      } else if (msg.contains('INVALID_EMAIL') || msg.contains('invalid-email')) {
        msg = 'Please enter a valid email address.';
      } else if (msg.contains('Exception:')) {
        msg = msg.replaceFirst('Exception:', '').trim();
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
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
          'Citizen Registration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Register New Citizen Account',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F4C81),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pan-India Civic Resolution & Citizen Services (Government of India).',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),

            // Assigned Role Policy Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0F4C81).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF0F4C81), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Access Level: Verified Citizen Account',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Legal Name',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0F4C81)),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Contact Mode
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    selected: !_isPhoneMode,
                    selectedColor: const Color(0xFF0F4C81),
                    labelStyle: TextStyle(color: !_isPhoneMode ? Colors.white : const Color(0xFF1A1A2E)),
                    onSelected: (val) {
                      setState(() {
                        _isPhoneMode = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text('Phone', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    selected: _isPhoneMode,
                    selectedColor: const Color(0xFF0F4C81),
                    labelStyle: TextStyle(color: _isPhoneMode ? Colors.white : const Color(0xFF1A1A2E)),
                    onSelected: (val) {
                      setState(() {
                        _isPhoneMode = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact Field
            TextField(
              controller: _contactController,
              keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isPhoneMode ? 'Mobile Phone Number (+91)' : 'Email Address',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: Icon(
                  _isPhoneMode ? Icons.phone_android : Icons.email_outlined,
                  color: const Color(0xFF0F4C81),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F4C81)),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F4C81)),
              ),
            ),
            const SizedBox(height: 16),

            // Jurisdiction: State / UT Dropdown
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                labelText: 'State / Union Territory',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF0F4C81)),
              ),
              items: _indianStates.map((st) {
                return DropdownMenuItem<String>(
                  value: st['code'],
                  child: Text(st['name']!, style: GoogleFonts.inter(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedState = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // District and Pincode Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _districtController,
                    decoration: InputDecoration(
                      labelText: 'District / City',
                      labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF0F4C81)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      prefixIcon: const Icon(Icons.pin_drop_outlined, color: Color(0xFF0F4C81)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Registering with Backend...'),
                        ],
                      )
                    : Text(
                        'Register Account',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already registered? ', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
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
    );
  }
}
