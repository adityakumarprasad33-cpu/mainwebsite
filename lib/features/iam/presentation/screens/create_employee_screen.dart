import 'dart:async';
import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Supporting data models for Admin Provisioning dropdown selectors
class SectorItem {
  const SectorItem({required this.id, required this.code, required this.name});
  final String id;
  final String code;
  final String name;
}

class DepartmentItem {
  const DepartmentItem({
    required this.id,
    required this.sectorId,
    required this.code,
    required this.name,
  });
  final String id;
  final String sectorId;
  final String code;
  final String name;
}

class PostItem {
  const PostItem({
    required this.id,
    required this.departmentId,
    required this.code,
    required this.name,
    required this.rolePolicy,
  });
  final String id;
  final String departmentId;
  final String code;
  final String name;
  final String rolePolicy;
}

class JurisdictionItem {
  const JurisdictionItem({required this.id, required this.name});
  final String id;
  final String name;
}

/// CreateEmployeeScreen provides complete Government Account Provisioning for Admins.
/// Enforces dependent selectors: Sector -> Department -> Post -> Jurisdiction -> Role.
class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _fullNameController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingHierarchy = true;
  String? _hierarchyError;
  late final Dio _dio;

  // Organization hierarchy must come from the backend; there are no local/demo records.
  final List<SectorItem> _sectors = [];
  final List<DepartmentItem> _allDepartments = [];
  final List<PostItem> _allPosts = [];
  final List<JurisdictionItem> _jurisdictions = [];

  // Active Selections
  SectorItem? _selectedSector;
  DepartmentItem? _selectedDepartment;
  PostItem? _selectedPost;
  JurisdictionItem? _selectedJurisdiction;
  String _selectedRole = 'GovernmentOfficial';

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
    unawaited(_loadHierarchy());
  }

  List<Map<String, dynamic>> _items(Response<dynamic> response) {
    final items = response.data is Map ? response.data['items'] : null;
    if (items is! List)
      throw const FormatException('Invalid organization hierarchy response.');
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _id(Map<String, dynamic> item, String key) =>
      (item['id'] ?? item[key] ?? '').toString();

  Future<void> _loadHierarchy() async {
    setState(() {
      _isLoadingHierarchy = true;
      _hierarchyError = null;
    });
    try {
      final response = await _dio.get<dynamic>('/hierarchy/sectors');
      final sectors = _items(response)
          .map(
            (item) => SectorItem(
              id: _id(item, 'sectorId'),
              code: (item['code'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _sectors
          ..clear()
          ..addAll(sectors);
        _selectedSector = sectors.isEmpty ? null : sectors.first;
        _allDepartments.clear();
        _allPosts.clear();
        _jurisdictions.clear();
        _selectedDepartment = null;
        _selectedPost = null;
        _selectedJurisdiction = null;
      });
      if (_selectedSector != null) await _loadDepartments(_selectedSector!);
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      setState(
        () => _hierarchyError = body is Map && body['message'] is String
            ? body['message'] as String
            : 'Could not load the verified government hierarchy.',
      );
    } catch (error) {
      if (mounted) setState(() => _hierarchyError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingHierarchy = false);
    }
  }

  Future<void> _loadDepartments(SectorItem sector) async {
    try {
      final response = await _dio.get<dynamic>(
        '/hierarchy/departments',
        queryParameters: {'sectorId': sector.id},
      );
      final departments = _items(response)
          .map(
            (item) => DepartmentItem(
              id: _id(item, 'departmentId'),
              sectorId: (item['sectorId'] ?? sector.id).toString(),
              code: (item['code'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
            ),
          )
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.sectorId == sector.id &&
                item.name.isNotEmpty,
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _allDepartments
          ..clear()
          ..addAll(departments);
        _selectedDepartment = departments.isEmpty ? null : departments.first;
        _allPosts.clear();
        _jurisdictions.clear();
        _selectedPost = null;
        _selectedJurisdiction = null;
      });
      if (_selectedDepartment != null)
        await _loadPostAndJurisdictions(_selectedDepartment!);
    } catch (error) {
      if (mounted)
        setState(() => _hierarchyError = 'Could not load departments: $error');
    }
  }

  Future<void> _loadPostAndJurisdictions(DepartmentItem department) async {
    try {
      final values = await Future.wait([
        _dio.get<dynamic>(
          '/hierarchy/posts',
          queryParameters: {'departmentId': department.id},
        ),
        _dio.get<dynamic>(
          '/hierarchy/jurisdictions',
          queryParameters: {'departmentId': department.id},
        ),
      ]);
      final posts = _items(values[0])
          .map(
            (item) => PostItem(
              id: _id(item, 'postId'),
              departmentId: (item['departmentId'] ?? '').toString(),
              code: (item['code'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
              rolePolicy: (item['rolePolicy'] ?? 'GovernmentOfficial')
                  .toString(),
            ),
          )
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.departmentId == department.id &&
                item.name.isNotEmpty,
          )
          .toList();
      final jurisdictions = _items(values[1])
          .map(
            (item) => JurisdictionItem(
              id: _id(item, 'jurisdictionId'),
              name: (item['name'] ?? item['districtName'] ?? item['code'] ?? '')
                  .toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _allPosts
          ..clear()
          ..addAll(posts);
        _jurisdictions
          ..clear()
          ..addAll(jurisdictions);
        _selectedPost = posts.isEmpty ? null : posts.first;
        _selectedRole = _selectedPost?.rolePolicy ?? 'GovernmentOfficial';
        _selectedJurisdiction = jurisdictions.isEmpty
            ? null
            : jurisdictions.first;
        _hierarchyError = null;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _allPosts.clear();
          _jurisdictions.clear();
          _selectedPost = null;
          _selectedJurisdiction = null;
          _hierarchyError = 'Could not load posts and jurisdictions: $error';
        });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitProvisioning() async {
    if (_selectedSector == null ||
        _selectedDepartment == null ||
        _selectedPost == null ||
        _selectedJurisdiction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Provisioning is unavailable: configure the organization hierarchy in Firestore first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_fullNameController.text.trim().isEmpty ||
        _employeeCodeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Full Name, Employee Code, and Email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String employeeId;
    try {
      final token = SessionManager.instance.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Your session has expired. Please sign in again.');
      }
      final response =
          await ApiClientConfig.attach(
            Dio(
              BaseOptions(
                baseUrl: ApiClientConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Authorization': 'Bearer $token'},
              ),
            ),
          ).post<Map<String, dynamic>>(
            '/admin/government-employees',
            data: {
              'fullName': _fullNameController.text.trim(),
              'employeeCode': _employeeCodeController.text.trim(),
              'email': _emailController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
              'sectorId': _selectedSector?.id,
              'departmentId': _selectedDepartment?.id,
              'departmentName': _selectedDepartment?.name,
              'postId': _selectedPost?.id,
              'postName': _selectedPost?.name,
              'jurisdictionIds': _selectedJurisdiction == null
                  ? <String>[]
                  : [_selectedJurisdiction!.id],
              'role': _selectedRole,
            },
          );
      employeeId =
          (response.data?['employee'] as Map?)?['employeeId']?.toString() ?? '';
      if (employeeId.isEmpty)
        throw const FormatException(
          'The server did not confirm employee creation.',
        );
    } on DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Could not provision the employee. Check the backend connection and permissions.';
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFF5F5F7),
          icon: const Icon(
            Icons.verified_user,
            color: Color(0xFF2E7D32),
            size: 48,
          ),
          title: Text(
            'Government Account Provisioned!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee: ${_fullNameController.text}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              Text(
                'Code: ${_employeeCodeController.text}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                'Department: ${_selectedDepartment?.name}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                'Post: ${_selectedPost?.name}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                'Assigned Role: $_selectedRole',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF0F4C81),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A one-time Firebase password setup email was sent. The account remains unavailable to staff workflows until identity verification and activation are completed.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF0F4C81),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Return to Directory'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDepts = _allDepartments
        .where((d) => d.sectorId == _selectedSector?.id)
        .toList();
    final availablePosts = _allPosts
        .where((p) => p.departmentId == _selectedDepartment?.id)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Provision Government Employee',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Official Employee Provisioning Gate',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Admin-only initialization of official accounts with sector, department, post, and jurisdiction scope.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            if (_isLoadingHierarchy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Loading verified organization hierarchy…'),
            ] else if (_hierarchyError != null) ...[
              const SizedBox(height: 12),
              Text(_hierarchyError!, style: const TextStyle(color: Colors.red)),
              TextButton.icon(
                onPressed: _loadHierarchy,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ] else if (_sectors.isEmpty ||
                _allDepartments.isEmpty ||
                _allPosts.isEmpty ||
                _jurisdictions.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Employee provisioning is unavailable because the backend has no complete active sector, department, post, and jurisdiction hierarchy for this account.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),

            // Employee Identity Section
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name (As per Govt Service Book)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _employeeCodeController,
              decoration: InputDecoration(
                labelText: 'Official Employee Code / ID (e.g. PWD-PAT-108)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Govt Mobile (+91)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Govt Email (@bihar.gov.in)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dependent Dropdown 1: Sector
            Text(
              '1. Select Sector',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<SectorItem>(
              initialValue: _selectedSector,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _sectors
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.name,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _sectors.isEmpty || _isLoadingHierarchy
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSector = val;
                          _hierarchyError = null;
                        });
                        unawaited(_loadDepartments(val));
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Dependent Dropdown 2: Department (Filtered by Sector)
            Text(
              '2. Select Department (Filtered by Sector)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<DepartmentItem>(
              initialValue: _selectedDepartment,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: availableDepts
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d.name,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: availableDepts.isEmpty || _isLoadingHierarchy
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDepartment = val;
                          _selectedPost = null;
                          _selectedJurisdiction = null;
                        });
                        unawaited(_loadPostAndJurisdictions(val));
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Dependent Dropdown 3: Post / Designation (Filtered by Department)
            Text(
              '3. Select Post / Designation',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<PostItem>(
              initialValue: _selectedPost,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: availablePosts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: availablePosts.isEmpty || _isLoadingHierarchy
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPost = val;
                          _selectedRole = val.rolePolicy;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Dropdown 4: Jurisdiction
            Text(
              '4. Assign Operational Jurisdiction Scope',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<JurisdictionItem>(
              initialValue: _selectedJurisdiction,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _jurisdictions
                  .map(
                    (j) => DropdownMenuItem(
                      value: j,
                      child: Text(
                        j.name,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _jurisdictions.isEmpty || _isLoadingHierarchy
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedJurisdiction = val;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Assigned Role Display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF0F4C81)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Role Policy',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        _selectedRole,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F4C81),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _isSubmitting ||
                        _isLoadingHierarchy ||
                        _sectors.isEmpty ||
                        _selectedSector == null ||
                        _selectedDepartment == null ||
                        _selectedPost == null ||
                        _selectedJurisdiction == null
                    ? null
                    : _submitProvisioning,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(
                  _isSubmitting
                      ? 'Provisioning Employee Account...'
                      : 'Provision Government Employee',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
