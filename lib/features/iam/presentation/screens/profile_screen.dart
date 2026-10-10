import 'dart:async';
import 'package:citizen_app/features/grievances/data/grievance_service.dart';
import 'package:citizen_app/platform/localization/language_provider.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comprehensive Production-Grade SamadhanAI Citizen Profile & Help Portal
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final session = SessionManager.instance;
  final _grievanceService = GrievanceService();
  int _lodgedCount = 0;
  int _resolvedCount = 0;
  int _escalatedCount = 0;
  bool _loadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    try {
      final list = await _grievanceService.fetchMyGrievances();

      int lodged = list.length;
      int resolved = list.where((g) {
        final st = g.state.toUpperCase();
        return st == 'RESOLVED' || st == 'CLOSED';
      }).length;
      int escalated = list.where((g) {
        final st = g.state.toUpperCase();
        return st == 'ESCALATED';
      }).length;

      if (mounted) {
        setState(() {
          _lodgedCount = lodged;
          _resolvedCount = resolved;
          _escalatedCount = escalated;
          _loadingMetrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMetrics = false;
        });
      }
    }
  }

  void _handleSignOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out of SamadhanAI?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your active session credentials and encrypted local tokens will be cleared from this device.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SessionManager.instance.terminateSession();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Signed out successfully.',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: const Color(0xFF0F4C81),
                ),
              );
              unawaited(
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showGatewaySettings() {
    unawaited(Navigator.of(context).pushNamed('/network-settings'));
  }

  String _formatDisplayName() {
    if (session.displayName != null && session.displayName!.trim().isNotEmpty) {
      return session.displayName!;
    }
    final email = session.userEmail ?? '';
    if (email.contains('@')) {
      final namePart = email.split('@').first.replaceAll('.', ' ');
      return namePart
          .split(' ')
          .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
          )
          .join(' ');
    }
    return 'Registered Citizen';
  }

  @override
  Widget build(BuildContext context) {
    final email = session.userEmail ?? 'citizen@samadhan.gov.in';
    final roleName = session.role == UserRoleEnum.citizen
        ? 'Citizen (Public User)'
        : (session.role == UserRoleEnum.nodalOfficer
              ? 'Nodal Officer (Departmental)'
              : 'Department Administrator');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Citizen Profile & Services',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Gateway Settings',
            onPressed: _showGatewaySettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Banner & Profile Avatar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071E3D),
                    Color(0xFF0F4C81),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : 'C',
                            style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _formatDisplayName(),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          roleName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Civic Activity Metrics
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricTile(
                          'Lodged',
                          _loadingMetrics ? '...' : '$_lodgedCount',
                          Icons.assignment_outlined,
                          const Color(0xFF0F4C81),
                        ),
                        _buildDivider(),
                        _buildMetricTile(
                          'Resolved',
                          _loadingMetrics ? '...' : '$_resolvedCount',
                          Icons.check_circle_outline,
                          const Color(0xFF10B981),
                        ),
                        _buildDivider(),
                        _buildMetricTile(
                          'Escalated',
                          _loadingMetrics ? '...' : '$_escalatedCount',
                          Icons.trending_up,
                          const Color(0xFFD97706),
                        ),
                        _buildDivider(),
                        _buildMetricTile(
                          'Trust Score',
                          '100%',
                          Icons.verified_user_outlined,
                          const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 3. Citizen Details Card
                  _buildSectionHeader(
                    'Citizen & Jurisdiction Details',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'User Identifier',
                            session.userId ?? 'usr-cit-auto',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'State / UT',
                            session.stateCode != null
                                ? 'State Code: ${session.stateCode}'
                                : 'Pan-India Coverage',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'District / City',
                            session.district ?? 'National Jurisdiction',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Contact Phone',
                            session.phone != null && session.phone!.isNotEmpty
                                ? session.phone!
                                : 'Email Authenticated',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Verification Status',
                            'Active Citizen Account',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Language & Regional Settings
                  _buildSectionHeader(
                    'Language & Preferences',
                    Icons.language_outlined,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select App Display Language',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildLangChip('English', AppLanguage.english),
                              _buildLangChip('हिन्दी', AppLanguage.hindi),
                              _buildLangChip('भोजपुरी', AppLanguage.bhojpuri),
                              _buildLangChip('मैथिली', AppLanguage.maithili),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Frequently Asked Questions (FAQ)
                  _buildSectionHeader(
                    'Frequently Asked Questions (FAQ)',
                    Icons.help_outline,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildFaqTile(
                          'Is SamadhanAI available across all of India?',
                          'Yes! SamadhanAI operates Pan-India across all 28 States and 8 Union Territories. It connects with Central Ministries (MoHUA, MoRTH, Jal Shakti), State Departments (PWD, Water, Electricity Discoms), and Urban Local Bodies (MCD, BMC, BBMP, GHMC, PMC).',
                        ),
                        const Divider(height: 1),
                        _buildFaqTile(
                          'How does SamadhanAI automatically route my grievance?',
                          'Our multimodal vision AI detects the defect from your photo (potholes, water pipeline burst, garbage overflow, blown transformer), computes GPS location, and auto-routes the issue to the exact local authority with zero manual forms needed.',
                        ),
                        const Divider(height: 1),
                        _buildFaqTile(
                          'What is the statutory redressal timeline?',
                          'Under the National Sevottam Framework and State Public Services Guarantee Acts, complaints are assigned with an initial 24-48 hour inspection SLA and must be resolved with photographic evidence within 7 to 30 days.',
                        ),
                        const Divider(height: 1),
                        _buildFaqTile(
                          'Can I appeal if the resolution is unsatisfactory?',
                          'Yes. You have a statutory right to appeal within 30 days. You can file a First Appeal to the Sub-Divisional Magistrate / Joint Commissioner and a Second Appeal to the District Magistrate or Municipal Commissioner.',
                        ),
                        const Divider(height: 1),
                        _buildFaqTile(
                          'Why should I upload photos of civic defects?',
                          'Photos provide verifiable visual evidence. The AI analyzes structural defects and embeds GPS metadata to help field maintenance engineers locate and resolve the hazard immediately.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Emergency & Government Helpline Directory
                  _buildSectionHeader(
                    'National & Emergency Helplines (Pan-India)',
                    Icons.phone_in_talk_outlined,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHelplineRow(
                            'National Emergency Number',
                            '112',
                            'Police, Fire, Ambulance & Disaster',
                          ),
                          const Divider(height: 20),
                          _buildHelplineRow(
                            'CPGRAMS National Portal',
                            '1800-11-0031',
                            'Central Govt Grievance Redressal',
                          ),
                          const Divider(height: 20),
                          _buildHelplineRow(
                            'Highway Helpline (MoRTH/NHAI)',
                            '1033',
                            'Accident & Highway Infrastructure',
                          ),
                          const Divider(height: 20),
                          _buildHelplineRow(
                            'Swachh Bharat Urban Local Bodies',
                            '1969',
                            'Sanitation & Solid Waste Management',
                          ),
                          const Divider(height: 20),
                          _buildHelplineRow(
                            'National Cyber Crime Helpline',
                            '1930',
                            'Cyber Fraud & Digital Safety',
                          ),
                          const Divider(height: 20),
                          _buildHelplineRow(
                            'SamadhanAI National Desk',
                            'support@samadhanai.gov.in',
                            'System & Digital Inquiries',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Interactive Help & AI Chat Launcher
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0F4C81).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          color: Color(0xFF0F4C81),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Instant Assistance?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF0F4C81),
                                ),
                              ),
                              Text(
                                'Chat with RunixGov AI Assistant for instant grievance help.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/ai-chat');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C81),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Start Chat'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 8. Security & Sign Out Button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                      label: Text(
                        'Sign Out from Account',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Version Footer
                  Center(
                    child: Text(
                      'SamadhanAI Civic Governance Portal • v0.7.0 Production\nGovernment of Bihar e-Governance Initiative',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F4C81)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String label, AppLanguage lang) {
    final isSelected = LanguageProvider.instance.value == lang;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0F4C81),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF1F2937),
      ),
      onSelected: (_) {
        setState(() {
          LanguageProvider.instance.setLanguage(lang);
        });
      },
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
      children: [
        Text(
          answer,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildHelplineRow(String service, String contact, String purpose) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent,
            color: Color(0xFF0F4C81),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                purpose,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        SelectableText(
          contact,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F4C81),
          ),
        ),
      ],
    );
  }
}
