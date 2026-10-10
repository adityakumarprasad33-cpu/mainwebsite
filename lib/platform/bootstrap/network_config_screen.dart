import 'package:citizen_app/platform/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NetworkConfigScreen extends StatefulWidget {
  const NetworkConfigScreen({super.key});

  @override
  State<NetworkConfigScreen> createState() => _NetworkConfigScreenState();
}

class _NetworkConfigScreenState extends State<NetworkConfigScreen> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ApiClientConfig.configuredBaseUrls.join('\n'),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    late final List<String> candidates;
    try {
      candidates = ApiClientConfig.normalizeBaseUrls(_urlController.text);
    } on FormatException catch (error) {
      setState(() => _testResult = error.message);
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final selected = await ApiClientConfig.testAndSelectBaseUrls(
        candidates.join('\n'),
      );
      if (mounted) {
        setState(
          () => _testResult = selected == null
              ? 'None of the configured APIs passed the database and storage readiness check.'
              : 'Ready. Selected $selected',
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _testResult =
              'Could not reach the backend: ${error.message ?? error.type.name}',
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final selected = await ApiClientConfig.testAndSelectBaseUrls(
        _urlController.text,
      );
      if (selected == null) {
        if (mounted) {
          setState(() {
            _testResult =
                'Cannot save these URLs: none passed the backend readiness check.';
          });
        }
        return;
      }
      await ApiClientConfig.setBaseUrls(
        _urlController.text,
        selectedUrl: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend URL saved on this device.')),
      );
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _reset() async {
    await ApiClientConfig.resetToBuildDefault();
    if (!mounted) return;
    setState(() {
      _urlController.text = ApiClientConfig.configuredBaseUrls.join('\n');
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Settings'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Enter one to three API replicas in priority order. The app checks readiness and selects the first available. URLs must serve the same environment and data.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Only use a backend you trust. Sign-in tokens and requests will be sent to this server.',
            style: TextStyle(color: Colors.deepOrange),
          ),
          const SizedBox(height: 20),
          SelectableText(
            'Active URL: ${ApiClientConfig.configuredBaseUrl ?? 'Not configured'}',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            minLines: 1,
            maxLines: 3,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'API base URLs (one per line)',
              hintText: 'https://api.example.com/api/v1',
              helperText: 'One to three replicas. Include /api/v1. Release apps require HTTPS.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_testResult != null) ...[
            SelectableText(_testResult!),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find),
                  label: const Text('Test'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to build configuration'),
          ),
        ],
      ),
    );
  }
}
