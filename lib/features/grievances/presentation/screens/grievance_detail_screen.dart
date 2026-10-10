import 'package:citizen_app/features/grievances/data/grievance_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GrievanceDetailScreen extends StatefulWidget {
  const GrievanceDetailScreen({super.key, required this.publicId});

  final String? publicId;

  @override
  State<GrievanceDetailScreen> createState() => _GrievanceDetailScreenState();
}

class _GrievanceDetailScreenState extends State<GrievanceDetailScreen> {
  final _service = GrievanceService();
  GrievanceResponse? _grievance;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.publicId == null || widget.publicId!.trim().isEmpty) {
      setState(() {
        _error = 'No grievance ID was provided.';
        _loading = false;
      });
      return;
    }
    try {
      final result = await _service.getGrievanceById(widget.publicId!.trim());
      if (!mounted) return;
      setState(() {
        _grievance = result;
        _error = result == null ? 'Grievance not found.' : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load grievance: $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grievance = _grievance;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        title: Text('Grievance Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _detail('Tracking ID', grievance!.publicId),
                    _detail('Status', grievance.state),
                    _detail('Title', grievance.title),
                    _detail('Description', grievance.description),
                    _detail('Department', grievance.department),
                    _detail('Priority', grievance.priority),
                    _detail('Target response window', '${grievance.slaHours} hours'),
                    _detail('District', grievance.location['district']?.toString() ?? 'Not provided'),
                    _detail('State', grievance.location['stateCode']?.toString() ?? 'Not provided'),
                    _detail('Submitted', grievance.submittedAt),
                  ],
                ),
    );
  }

  Widget _detail(String label, String value) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1F2937))),
          ]),
        ),
      );
}
