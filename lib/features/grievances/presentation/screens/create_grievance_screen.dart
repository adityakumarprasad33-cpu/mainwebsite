import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:citizen_app/features/grievances/data/grievance_service.dart';
import 'package:citizen_app/features/grievances/data/runix_ai_service.dart';
import 'package:citizen_app/platform/localization/language_provider.dart';
import 'package:citizen_app/platform/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Real Image Attachment Evidence Model
class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.mimeType,
    this.bytes,
    this.path,
    this.imageDescription,
  });

  final String id;
  final String fileName;
  final String fileSize;
  final String fileType;
  final String mimeType;
  final Uint8List? bytes;
  final String? path;
  final String? imageDescription;
}

/// Material 3 Create Grievance Screen with Automated Image Recognition,
/// AI assisted grievance drafting and backend classification.
class CreateGrievanceScreen extends StatefulWidget {
  const CreateGrievanceScreen({super.key});

  @override
  State<CreateGrievanceScreen> createState() => _CreateGrievanceScreenState();
}

class _CreateGrievanceScreenState extends State<CreateGrievanceScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _aiService = RunixAiService();
  final _grievanceService = GrievanceService();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _isAnalyzingImage = false;
  bool _isGeneratingDesc = false;
  String? _currentImageDescription;

  // 3-4 Dynamic Title Suggestions for Horizontal Scroll Menu
  List<String> _suggestedTitles = [];

  // Assigned Agent Information determined automatically by backend LLM
  AiAgentClassification? _assignedAgentInfo;

  final List<EvidenceItem> _attachedEvidence = [];

  String _imageMimeType(XFile image, Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    final declared = image.mimeType?.split(';').first.trim().toLowerCase();
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(declared)) {
      return declared!;
    }
    // image_picker re-encodes picked photos as JPEG when imageQuality is set.
    return 'image/jpeg';
  }

  @override
  void initState() {
    super.initState();
    final session = SessionManager.instance;
    final locationParts = [
      session.district,
      session.stateCode,
    ].whereType<String>().where((value) => value.trim().isNotEmpty);
    _locationController.text = locationParts.join(', ');
  }

  ({String? stateCode, String? district}) _resolveLocation() {
    final parts = _locationController.text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final typedState = parts
        .where((part) => RegExp(r'^[A-Za-z]{2}$').hasMatch(part))
        .lastOrNull;
    final profileState = SessionManager.instance.stateCode
        ?.trim()
        .toUpperCase();
    final state =
        profileState != null && RegExp(r'^[A-Z]{2}$').hasMatch(profileState)
        ? profileState
        : typedState?.toUpperCase();
    final district =
        (SessionManager.instance.district?.trim().isNotEmpty ?? false)
        ? SessionManager.instance.district!.trim()
        : parts.where((part) => part != typedState).firstOrNull;
    return (stateCode: state, district: district);
  }

  Future<({String stateCode, String district})?>
  _ensureAnalysisLocation() async {
    final current = _resolveLocation();
    final state = current.stateCode;
    final district = current.district;
    if (state != null && district != null && district.isNotEmpty) {
      await SessionManager.instance.updateLocation(
        userStateCode: state,
        userDistrict: district,
      );
      return (stateCode: state, district: district);
    }

    final stateController = TextEditingController(text: state ?? '');
    final districtController = TextEditingController(text: district ?? '');
    final formKey = GlobalKey<FormState>();
    try {
      final location = await showDialog<({String stateCode, String district})>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Set your location'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: districtController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'District'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your district.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stateController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration: const InputDecoration(
                    labelText: 'State code',
                    hintText: 'e.g. BR',
                    counterText: '',
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[A-Za-z]{2}$').hasMatch(value.trim())
                      ? 'Enter a two-letter state code.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop((
                  stateCode: stateController.text.trim().toUpperCase(),
                  district: districtController.text.trim(),
                ));
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (location == null || !mounted) return null;
      await SessionManager.instance.updateLocation(
        userStateCode: location.stateCode,
        userDistrict: location.district,
      );
      _locationController.text = '${location.district}, ${location.stateCode}';
      return location;
    } finally {
      stateController.dispose();
      districtController.dispose();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Real Image Capture & AI Recognition Flow (Camera or Gallery)
  Future<void> _captureRealImage(ImageSource source) async {
    try {
      final location = await _ensureAnalysisLocation();
      if (location == null || !mounted) return;

      final photo = await _imagePicker.pickImage(
        source: source,
        // Keep base64 IRM requests below serverless request-body limits while
        // preserving enough detail to recognize common civic infrastructure.
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );

      if (photo == null) return; // Citizen cancelled capture

      final bytes = await photo.readAsBytes();
      if (bytes.lengthInBytes > 3 * 1024 * 1024) {
        throw StateError(
          'This image is too large to analyze (over 3 MB after compression). Choose a smaller image and try again.',
        );
      }
      final sizeKb = (bytes.lengthInBytes / 1024).round();
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      final evidence = EvidenceItem(
        id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
        fileName: photo.name.isNotEmpty
            ? photo.name
            : 'civic_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileSize: sizeStr,
        fileType: 'IMAGE',
        mimeType: _imageMimeType(photo, bytes),
        bytes: bytes,
        path: photo.path,
      );

      setState(() {
        _attachedEvidence.add(evidence);
        _isAnalyzingImage = true;
      });

      // Send to Backend RunixGov AI Gateway for automated image recognition!
      final base64String = base64Encode(bytes);
      final userState = location.stateCode;
      final userDistrict = location.district;

      final result = await _aiService.analyzeImage(
        fileName: photo.name,
        mimeType: photo.mimeType,
        defectHint: photo.name,
        base64Data: base64String,
        district: userDistrict,
        stateCode: userState,
      );

      if (!mounted) return;

      setState(() {
        _isAnalyzingImage = false;
        _assignedAgentInfo = result.classification;
        _suggestedTitles = result.suggestedTitles;
        _currentImageDescription = result.imageDescription;

        // Auto-populate Title with top suggestion
        if (result.suggestedTitles.isNotEmpty) {
          _titleController.text = result.suggestedTitles.first;
        }

        // Auto-populate Description using LLM
        _descController.text = result.autoDescription;
      });

      // Show the fast-track auto dispatch warning modal with skip process
      _showAutoSubmitWarningModal(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image analysis failed: $e'),
          backgroundColor: Colors.orange.shade900,
        ),
      );
    }
  }

  /// Automated Fast-Track Grievance Dispatch Modal with 5-Second Warning Countdown & Skip Option
  void _showAutoSubmitWarningModal(ImageAnalysisResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Review AI suggestions',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.suggestedTitles.first,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Department: ${result.classification.department}'),
            Text(
              'Priority: ${result.classification.priority} • Target SLA: ${result.classification.slaHours}h',
            ),
            const SizedBox(height: 8),
            Text(
              result.autoDescription,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(modalContext).pop(),
                    child: const Text('Review & Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(modalContext).pop();
                      _submitGrievance();
                    },
                    child: const Text('Submit Grievance'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _removeEvidence(String id) {
    setState(() {
      _attachedEvidence.removeWhere((item) => item.id == id);
    });
  }

  /// When citizen taps any title suggestion pill in the horizontal scroll menu
  Future<void> _applyTitleSuggestion(String title) async {
    setState(() {
      _titleController.text = title;
      _isGeneratingDesc = true;
    });
    try {
      final newDescription = await _aiService.autoGenerateDescription(
        title: title,
        imageDescription: _currentImageDescription,
      );
      final session = SessionManager.instance;
      final classification = await _aiService.classifyGrievance(
        title: title,
        description: newDescription,
        district: session.district,
        stateCode: session.stateCode,
      );
      if (!mounted) return;
      setState(() {
        _descController.text = newDescription;
        _assignedAgentInfo = classification;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI suggestion failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDesc = false);
    }
  }

  /// Regenerates the grievance description using the LLM
  Future<void> _regenerateDescription() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title first.')),
      );
      return;
    }
    setState(() => _isGeneratingDesc = true);
    try {
      final description = await _aiService.autoGenerateDescription(
        title: title,
        imageDescription: _currentImageDescription,
      );
      if (!mounted) return;
      setState(() => _descController.text = description);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Description generation failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDesc = false);
    }
  }

  Future<void> _submitGrievance() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a title and description before submitting.'),
        ),
      );
      return;
    }
    final location = _resolveLocation();
    final stateCode = location.stateCode;
    final district = location.district;
    if (stateCode == null ||
        stateCode.isEmpty ||
        district == null ||
        district.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter district and a two-letter state code above before submitting.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Image analysis already produced a real classification. Reuse it instead
      // of making a second provider request that can fail during submission.
      final classification =
          _assignedAgentInfo ??
          await _aiService.classifyGrievance(
            title: title,
            description: description,
            district: district,
            stateCode: stateCode,
          );
      final locationText = _locationController.text.trim();
      final submission = GrievanceSubmission(
        title: title,
        description: description,
        department: classification.department,
        slaHours: classification.slaHours,
        priority: classification.priority,
        location: {
          'district': district,
          'stateCode': stateCode,
          if (locationText.isNotEmpty) 'addressText': locationText,
          'countryCode': 'IN',
        },
        aiClassification: {
          ...classification.toJson(),
          'model': classification.provider,
          if (classification.confidenceScore != null)
            'confidence': classification.confidenceScore,
        },
        evidenceList: _attachedEvidence
            .where((item) => item.bytes != null)
            .map(
              (item) => {
                'fileName': item.fileName,
                'contentType': item.mimeType,
                'dataBase64': base64Encode(item.bytes!),
              },
            )
            .toList(),
      );
      final grievance = await _grievanceService.submitGrievance(submission);
      if (!mounted) return;
      setState(() => _assignedAgentInfo = classification);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Color(0xFF2E7D32),
            size: 48,
          ),
          title: const Text('Grievance submitted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tracking ID: ${grievance.publicId}'),
              const SizedBox(height: 8),
              Text('Department: ${grievance.department}'),
              Text('Target response window: ${grievance.slaHours} hours'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit grievance: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          LanguageProvider.tr('btn_lodge'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lodge New Public Complaint',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add details and use AI suggestions if available. Review the information and submit when you are ready.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),

            // REAL IMAGE CAPTURE / EVIDENCE SECTION (Camera / Gallery)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0F4C81,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF0F4C81),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Click or Upload Defect Photo',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2E7D32,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'AI Vision',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Tap Camera to take a real photo. AI describes and routes it instantly.',
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
                      const SizedBox(height: 16),

                      // Real Capture Buttons (Camera & Gallery)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C81),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isAnalyzingImage
                                  ? null
                                  : () => _captureRealImage(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera, size: 20),
                              label: Text(
                                'Take Photo',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F4C81),
                                side: const BorderSide(
                                  color: Color(0xFF0F4C81),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isAnalyzingImage
                                  ? null
                                  : () =>
                                        _captureRealImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: Text(
                                'Choose Gallery',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // AI Vision Scanning Indicator
                      if (_isAnalyzingImage) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F4C81,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFF0F4C81,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F4C81),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'RunixGov AI Vision is scanning photo & determining department...',
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
                      ],

                      // Attached Real Images List
                      if (_attachedEvidence.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Images selected for analysis (not submitted)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _attachedEvidence.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Real thumbnail preview
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.bytes != null
                                        ? Image.memory(
                                            item.bytes!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            color: const Color(
                                              0xFF0F4C81,
                                            ).withValues(alpha: 0.1),
                                            child: const Icon(
                                              Icons.image,
                                              color: Color(0xFF0F4C81),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.fileName,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              item.fileSize,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF2E7D32,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'AI Verified',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF2E7D32,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeEvidence(item.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI DEPARTMENT AUTO-ROUTING LIVE CARD (Replaces manual dropdown)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F4C81),
                      const Color(0xFF1E3A8A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4C81).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.hub_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Department Auto-Routing (Active)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _assignedAgentInfo != null
                                ? 'Target response: ${_assignedAgentInfo!.slaHours}h'
                                : 'Auto SLA',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _assignedAgentInfo != null
                          ? _assignedAgentInfo!.department
                          : 'Capture / Attach Photo to Auto-Route',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _assignedAgentInfo != null
                          ? 'Assigned: ${_assignedAgentInfo!.agentTitle} • Priority: ${_assignedAgentInfo!.priority}'
                          : 'AI Image Recognition Model (IRM) inspects defect and routes to local authority.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No manual category selection required. Automated Pan-India routing based on visual defect analysis.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'District, State Code (required for IRM)',
                hintText: 'e.g. Patna, BR',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF0F4C81),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // GRIEVANCE TITLE INPUT
            Row(
              children: [
                Text(
                  'Grievance Title',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Text(
                  'Auto-set by AI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Severe Potholes on Main Road',
                prefixIcon: const Icon(Icons.title, color: Color(0xFF0F4C81)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F4C81)),
                ),
              ),
            ),

            // HORIZONTAL SCROLL MENU FOR 3-4 TITLE SUGGESTIONS
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: Color(0xFF0F4C81),
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Suggestions (Tap to apply & auto-generate description):',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F4C81),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestedTitles.map((title) {
                  final isSelected = _titleController.text == title;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.lightbulb_outline,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0F4C81),
                      ),
                      label: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      backgroundColor: isSelected
                          ? const Color(0xFF0F4C81)
                          : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0F4C81)
                            : const Color(0xFFD1D5DB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _applyTitleSuggestion(title),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // DETAILED DESCRIPTION (Auto-generated by LLM)
            Row(
              children: [
                Text(
                  'Detailed Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C81).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LLM Auto-Generated',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F4C81),
                    ),
                  ),
                ),
                const Spacer(),
                if (_isGeneratingDesc)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F4C81),
                    ),
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _regenerateDescription,
                    icon: const Icon(
                      Icons.refresh,
                      size: 14,
                      color: Color(0xFF0F4C81),
                    ),
                    label: Text(
                      'Regenerate',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'AI description assistance is available when configured.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F4C81)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // SUBMIT GRIEVANCE BUTTON
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
                onPressed: _isSubmitting ? null : _submitGrievance,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSubmitting
                      ? 'Registering Grievance...'
                      : 'Submit & Dispatch to Department',
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
