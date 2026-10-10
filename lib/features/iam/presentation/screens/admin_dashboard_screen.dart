import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citizen_app/platform/session/session_manager.dart';

/// AdminDashboardScreen handles Department Admin operations & Government Account Provisioning
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final canProvision = session.hasPermission('iam.employee.provision');
    final canListEmployees = session.hasPermission('iam.employee.list');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Department Admin Portal - SamadhanAI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrative Operations & IAM Control',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Government Account Provisioning, Department Hierarchy, and Audit Trails.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Card 1: Provision Government Employee
            if (canProvision)
              _buildAdminActionCard(
                context,
                title: 'Provision Government Employee',
                subtitle:
                    'Admin-only creation of official personnel accounts with Sector, Dept, Post, and Jurisdiction.',
                icon: Icons.person_add_alt_1,
                color: const Color(0xFF0F4C81),
                onTap: () =>
                    Navigator.pushNamed(context, '/admin/create-employee'),
              ),
            if (canProvision && canListEmployees) const SizedBox(height: 12),

            // Quick Action Card 2: Employee Directory
            if (canListEmployees)
              _buildAdminActionCard(
                context,
                title: 'Government Personnel Directory',
                subtitle:
                    'Manage active officers, suspensions, transfers, and force session revocation.',
                icon: Icons.badge_outlined,
                color: const Color(0xFF1A5276),
                onTap: () => Navigator.pushNamed(context, '/admin/employees'),
              ),
            if (!canProvision && !canListEmployees)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Administrative access is not assigned to this account. Ask an authorized administrator to review your permissions.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF0F4C81)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
