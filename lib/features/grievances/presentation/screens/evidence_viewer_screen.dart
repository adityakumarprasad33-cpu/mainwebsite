import 'package:citizen_app/features/grievances/data/grievance_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EvidenceViewerScreen extends StatefulWidget {
  const EvidenceViewerScreen({super.key});

  @override
  State<EvidenceViewerScreen> createState() => _EvidenceViewerScreenState();
}

class _EvidenceViewerScreenState extends State<EvidenceViewerScreen> {
  late Future<List<Map<String, dynamic>>> _evidenceFuture;

  @override
  void initState() {
    super.initState();
    _evidenceFuture = GrievanceService().fetchMyEvidence();
  }

  void _reload() {
    setState(() => _evidenceFuture = GrievanceService().fetchMyEvidence());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        title: Text('Evidence Media Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your grievance evidence', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Images attached to grievances you submitted.', style: GoogleFonts.inter(fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _evidenceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.blueGrey),
                        const SizedBox(height: 12),
                        Text('Could not load evidence: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _reload, child: const Text('Retry')),
                      ]),
                    );
                  }
                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (items.isEmpty) {
                    return const Center(child: Text('No evidence has been attached to your grievances yet.'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final url = item['downloadUrl'] as String?;
                      final name = item['fileName'] as String? ?? 'Evidence image';
                      final title = item['grievanceTitle']?.toString() ?? 'Grievance';
                      final size = item['sizeBytes'] is num ? (item['sizeBytes'] as num).toInt() : 0;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: SizedBox.expand(
                              child: url == null || url.isEmpty
                                  ? const Center(child: Icon(Icons.broken_image_outlined, size: 48))
                                  : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 48))),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey)),
                              Text('${(size / 1024).ceil()} KB', style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey)),
                            ]),
                          ),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
