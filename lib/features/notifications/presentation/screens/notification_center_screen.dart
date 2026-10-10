import 'dart:async';
import 'dart:ui';
import 'package:citizen_app/features/notifications/data/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NotificationCenterScreen displays real-time system and security notifications
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onNotificationsUpdated);
    unawaited(_service.load());
  }

  @override
  void dispose() {
    _service.removeListener(_onNotificationsUpdated);
    super.dispose();
  }

  void _onNotificationsUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
    } on Object catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update notification: $error')));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
    } on Object catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update notifications: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _service.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notification Center',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                unawaited(_markAllAsRead());
              },
              child: Text(
                'Mark All Read',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0F4C81),
        onRefresh: () async {
          await _service.load();
        },
        child: _service.isLoading && notifications.isEmpty
            ? ListView(children: const [SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))])
            : _service.errorMessage != null && notifications.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 140),
                    Center(child: Text(_service.errorMessage!, textAlign: TextAlign.center)),
                    Center(child: TextButton(onPressed: () => unawaited(_service.load()), child: const Text('Retry'))),
                  ])
                : notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final isRead = item.isRead;
                  final isSecurity = item.type == 'SECURITY';
                  final isGrievance = item.type == 'GRIEVANCE';

                  IconData iconData = Icons.notifications_active_outlined;
                  Color iconBg = const Color(0xFF0F4C81);

                  if (isSecurity) {
                    iconData = Icons.shield_outlined;
                    iconBg = const Color(0xFFD97706);
                  } else if (isGrievance) {
                    iconData = Icons.assignment_turned_in_outlined;
                    iconBg = const Color(0xFF2E7D32);
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white.withValues(alpha: 0.70)
                              : const Color(0xFF0F4C81).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFF0F4C81).withValues(alpha: 0.15),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? const Color(0xFFE5E7EB)
                                : iconBg,
                            child: Icon(
                              iconData,
                              color: isRead
                                  ? const Color(0xFF6B7280)
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F4C81),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSecurity
                                          ? const Color(0xFFD97706).withValues(alpha: 0.1)
                                          : const Color(0xFF0F4C81).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSecurity
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF0F4C81),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.formattedTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            unawaited(_markAsRead(item.id));
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
