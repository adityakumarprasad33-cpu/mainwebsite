/// Offline Draft Queue Service
///
/// Stores offline grievance drafts locally and manages queued sync requests.
class OfflineDraftQueue {
  final List<Map<String, dynamic>> _drafts = [];

  List<Map<String, dynamic>> get drafts => List.unmodifiable(_drafts);

  void saveDraft(Map<String, dynamic> draft) {
    _drafts.add(draft);
  }

  void removeDraft(int index) {
    if (index >= 0 && index < _drafts.length) {
      _drafts.removeAt(index);
    }
  }
}
