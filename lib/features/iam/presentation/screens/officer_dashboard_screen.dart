import 'dart:async';
import 'package:citizen_app/features/grievances/data/runix_ai_service.dart';
import 'package:citizen_app/platform/api/api_client.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final _aiService = RunixAiService();
  final _dio = ApiClientConfig.attach(
    Dio(BaseOptions(baseUrl: ApiClientConfig.baseUrl)),
  );
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;
  String? _loadError;
  String? _draftingCaseId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCases());
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final token = SessionManager.instance.accessToken;
      if (token == null || token.isEmpty)
        throw StateError('Sign in again to load cases.');
      final response = await _dio.get<Map<String, dynamic>>(
        '/cases',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final rows = response.data?['items'];
      if (rows is! List)
        throw const FormatException(
          'The cases service returned an invalid response.',
        );
      _cases = rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } on Object catch (error) {
      _loadError = error.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAiDraft(Map<String, dynamic> item) async {
    final caseId =
        (item['publicId'] ?? item['caseNumber'] ?? item['uuid'] ?? '')
            .toString();
    final description = (item['description'] ?? '').toString();
    if (caseId.isEmpty || description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This case has no ID or description for AI drafting.'),
        ),
      );
      return;
    }

    setState(() => _draftingCaseId = caseId);
    try {
      final draft = await _aiService.draftResolutionAssist(
        publicId: caseId,
        description: description,
      );
      final summary = draft['summary'];
      if (summary is! String || summary.trim().isEmpty) {
        throw const FormatException(
          'The AI service returned no resolution draft.',
        );
      }
      if (!mounted) return;
      final steps = draft['actionSteps'] is List
          ? (draft['actionSteps'] as List)
                .map((value) => value.toString())
                .toList()
          : <String>[];
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Draft Resolution'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(summary),
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Suggested actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('• $step'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI drafting failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _draftingCaseId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        title: Text(
          'Officer Work Queue',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => unawaited(_loadCases()),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh cases',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(
                    height: 360,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _loadError != null
            ? ListView(
                children: [
                  const SizedBox(height: 140),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_loadError!, textAlign: TextAlign.center),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => unawaited(_loadCases()),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _cases.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No cases are assigned to your department yet.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _cases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _cases[index];
                  final id =
                      (item['publicId'] ??
                              item['caseNumber'] ??
                              item['uuid'] ??
                              item['id'] ??
                              '')
                          .toString();
                  final title = (item['title'] ?? '').toString();
                  final status = (item['state'] ?? item['status'] ?? 'Unknown')
                      .toString();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$id · $title',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: $status'),
                          if (item['department'] is String)
                            Text('Department: ${item['department']}'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _draftingCaseId == id
                                ? null
                                : () => unawaited(_generateAiDraft(item)),
                            icon: _draftingCaseId == id
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('Generate AI draft'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
