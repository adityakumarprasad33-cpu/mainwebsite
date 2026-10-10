import 'dart:ui';
import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeRecord {
  EmployeeRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.post,
    required this.role,
    required this.status,
    required this.identityStatus,
  });

  final String id;
  final String code;
  final String name;
  final String department;
  final String post;
  final String role;
  String status;
  final String identityStatus;
}

/// EmployeeManagementScreen displays directory of provisioned government accounts
/// with administrative action controls (Suspend, Disable, Reactivate, Transfer).
class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final List<EmployeeRecord> _employees = [];
  late final Dio _dio;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final token = SessionManager.instance.accessToken;
    _dio = ApiClientConfig.attach(
      Dio(
        BaseOptions(
          baseUrl: ApiClientConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      ),
    );
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/government-employees',
      );
      final items = response.data?['items'];
      if (items is! List)
        throw const FormatException('Invalid employee list response.');
      final employees = items.map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        return EmployeeRecord(
          id: json['employeeId'] as String? ?? '',
          code: json['employeeCode'] as String? ?? '',
          name: json['fullName'] as String? ?? '',
          department:
              json['departmentName'] as String? ??
              json['departmentId'] as String? ??
              '',
          post: json['postName'] as String? ?? json['postId'] as String? ?? '',
          role: json['primaryRole'] as String? ?? '',
          status: json['accountStatus'] as String? ?? 'PendingActivation',
          identityStatus:
              json['identityVerificationStatus'] as String? ?? 'Unverified',
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _employees
          ..clear()
          ..addAll(employees);
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      setState(() {
        _isLoading = false;
        _errorMessage = body is Map && body['message'] is String
            ? body['message'] as String
            : 'Could not load employees. Check your connection and permissions.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _updateStatus(EmployeeRecord emp, String newStatus) async {
    if (!SessionManager.instance.hasPermission('iam.employee.status.update'))
      return;
    try {
      await _dio.put<Map<String, dynamic>>(
        '/admin/government-employees/${Uri.encodeComponent(emp.id)}/status',
        data: {'status': newStatus},
      );
      if (!mounted) return;
      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Employee ${emp.name} account status updated to $newStatus.',
          ),
          backgroundColor: newStatus == 'Active'
              ? const Color(0xFF2E7D32)
              : Colors.orange,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Could not update employee status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyIdentity(EmployeeRecord employee) async {
    if (!SessionManager.instance.hasPermission('iam.employee.verify')) return;
    final reasonController = TextEditingController();
    final evidenceReferenceController = TextEditingController();
    final verificationInput = await showDialog<(String, String)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record identity verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Verification reason (8-500 characters)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: evidenceReferenceController,
              decoration: const InputDecoration(
                labelText:
                    'Approved evidence system reference (no document contents)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              reasonController.text.trim(),
              evidenceReferenceController.text.trim(),
            )),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    final reason = verificationInput?.$1;
    final evidenceReference = verificationInput?.$2;
    reasonController.dispose();
    evidenceReferenceController.dispose();
    if (reason == null ||
        reason.length < 8 ||
        reason.length > 500 ||
        evidenceReference == null ||
        evidenceReference.length < 4 ||
        evidenceReference.length > 160)
      return;
    try {
      await _dio.post<Map<String, dynamic>>(
        '/admin/government-employees/${Uri.encodeComponent(employee.id)}/verify-identity',
        data: {'reason': reason, 'evidenceReference': evidenceReference},
      );
      if (mounted) await _loadEmployees();
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Could not record identity verification.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _managePermissions(EmployeeRecord employee) async {
    final session = SessionManager.instance;
    final canGrant = session.hasPermission('iam.permissions.grant');
    final canRevoke = session.hasPermission('iam.permissions.revoke');
    var oneChangeSaved = false;
    if (!canGrant && !canRevoke) return;
    try {
      final results = await Future.wait([
        _dio.get<Map<String, dynamic>>(
          '/admin/government-employees/${Uri.encodeComponent(employee.id)}/permissions',
        ),
        _dio.get<Map<String, dynamic>>('/admin/permissions/catalog'),
        _dio.get<Map<String, dynamic>>(
          '/admin/government-employees/${Uri.encodeComponent(employee.id)}/audit-history',
        ),
      ]);
      final current = (results[0].data?['permissions'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      final catalog = (results[1].data?['items'] as List? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final audit = (results[2].data?['items'] as List? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final selected = Set<String>.from(current);
      final reasonController = TextEditingController();
      if (!mounted) return;
      final submit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Permissions · ${employee.name}'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Capabilities (only permissions you hold can be granted or revoked).',
                    ),
                    const SizedBox(height: 8),
                    ...catalog.map((item) {
                      final id = item['id']?.toString() ?? '';
                      final grantable = item['grantableByCaller'] == true;
                      final mayEdit =
                          grantable &&
                          ((selected.contains(id) && canRevoke) ||
                              (!selected.contains(id) && canGrant));
                      return CheckboxListTile(
                        dense: true,
                        value: selected.contains(id),
                        title: Text(id, style: const TextStyle(fontSize: 13)),
                        subtitle: mayEdit
                            ? null
                            : const Text(
                                'View only for your current authority.',
                              ),
                        onChanged: mayEdit
                            ? (value) => setDialogState(() {
                                if (value == true)
                                  selected.add(id);
                                else
                                  selected.remove(id);
                              })
                            : null,
                      );
                    }),
                    const Divider(),
                    const Text(
                      'Recent audit history',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...audit
                        .take(10)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${item['timestamp'] ?? ''} · ${item['event'] ?? ''} · actor ${item['actorUid'] ?? 'unknown'}'
                              '${item['reason'] is String ? ' · ${item['reason']}' : ''}'
                              '${item['evidenceReference'] is String ? ' · evidence ${item['evidenceReference']}' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    if (audit.isEmpty)
                      const Text('No recorded employee administration events.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText:
                            'Reason for permission changes (8–500 characters)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save changes'),
              ),
            ],
          ),
        ),
      );
      final reason = reasonController.text.trim();
      reasonController.dispose();
      if (submit != true || reason.length < 8 || reason.length > 500) return;
      final toGrant = selected.difference(current).toList();
      final toRevoke = current.difference(selected).toList();
      if (toGrant.isEmpty && toRevoke.isEmpty) return;
      if (toGrant.isNotEmpty) {
        if (!canGrant)
          throw StateError(
            'Your current permissions do not allow granting capabilities.',
          );
        await _dio.post<void>(
          '/admin/government-employees/${Uri.encodeComponent(employee.id)}/permissions/grant',
          data: {'permissionIds': toGrant, 'reason': reason},
        );
        oneChangeSaved = true;
      }
      if (toRevoke.isNotEmpty) {
        if (!canRevoke)
          throw StateError(
            'Your current permissions do not allow revoking capabilities.',
          );
        await _dio.post<void>(
          '/admin/government-employees/${Uri.encodeComponent(employee.id)}/permissions/revoke',
          data: {'permissionIds': toRevoke, 'reason': reason},
        );
        oneChangeSaved = true;
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission changes recorded and audited.'),
          ),
        );
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final responseMessage = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Permission change was denied or could not be saved.';
      final message = oneChangeSaved
          ? 'Some permission changes were recorded; the remaining changes failed. Reload employee permissions and audit history. $responseMessage'
          : responseMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _resendInvitation(EmployeeRecord employee) async {
    if (!SessionManager.instance.hasPermission('iam.employee.invite')) return;
    try {
      await _dio.post<void>(
        '/admin/government-employees/${Uri.encodeComponent(employee.id)}/invitation',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'If eligible, an invitation was sent to the registered work email.',
            ),
          ),
        );
      }
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Invitation request could not be processed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProvision = SessionManager.instance.hasPermission(
      'iam.employee.provision',
    );
    final canChangeStatus = SessionManager.instance.hasPermission(
      'iam.employee.status.update',
    );
    final canVerify = SessionManager.instance.hasPermission(
      'iam.employee.verify',
    );
    final canManagePermissions =
        SessionManager.instance.hasPermission('iam.permissions.grant') ||
        SessionManager.instance.hasPermission('iam.permissions.revoke');
    final canInvite = SessionManager.instance.hasPermission(
      'iam.employee.invite',
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Government Personnel Directory',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canProvision)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () {
                Navigator.pushNamed(context, '/admin/create-employee');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadEmployees,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _employees.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No government employees found.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadEmployees,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _employees.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final emp = _employees[index];
                  final isActive = emp.status == 'Active';

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                            Row(
                              children: [
                                if (canManagePermissions &&
                                    emp.id != SessionManager.instance.userId)
                                  OutlinedButton.icon(
                                    onPressed: () => _managePermissions(emp),
                                    icon: const Icon(
                                      Icons.admin_panel_settings_outlined,
                                    ),
                                    label: const Text('Permissions & audit'),
                                  ),
                                if (canInvite &&
                                    emp.status == 'PendingActivation')
                                  OutlinedButton.icon(
                                    onPressed: () => _resendInvitation(emp),
                                    icon: const Icon(
                                      Icons.mark_email_unread_outlined,
                                    ),
                                    label: const Text('Resend invite'),
                                  ),
                                CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF0F4C81,
                                  ).withValues(alpha: 0.10),
                                  child: const Icon(
                                    Icons.badge,
                                    color: Color(0xFF0F4C81),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      Text(
                                        'ID: ${emp.code} • ${emp.post}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(
                                            0xFF2E7D32,
                                          ).withValues(alpha: 0.10)
                                        : Colors.orange.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    emp.status,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? const Color(0xFF2E7D32)
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Department: ${emp.department}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text('Identity: ${emp.identityStatus}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (canVerify &&
                                    emp.identityStatus != 'Verified')
                                  OutlinedButton(
                                    onPressed: () => _verifyIdentity(emp),
                                    child: const Text('Verify identity'),
                                  ),
                                if (canChangeStatus &&
                                    emp.identityStatus == 'Verified' &&
                                    isActive)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _updateStatus(emp, 'Suspended'),
                                    child: const Text('Suspend'),
                                  )
                                else if (canChangeStatus &&
                                    emp.identityStatus == 'Verified')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _updateStatus(emp, 'Active'),
                                    child: const Text('Reactivate'),
                                  ),
                                if (canChangeStatus &&
                                    emp.identityStatus == 'Verified')
                                  const SizedBox(width: 8),
                                if (canChangeStatus &&
                                    emp.identityStatus == 'Verified')
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _updateStatus(emp, 'Disabled'),
                                    child: const Text('Disable'),
                                  ),
                                if (!canChangeStatus && !canVerify)
                                  const Text(
                                    'No employee actions are granted.',
                                  ),
                              ],
                            ),
                          ],
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
