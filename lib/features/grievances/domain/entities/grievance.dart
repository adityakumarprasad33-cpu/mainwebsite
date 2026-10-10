/// Grievance Domain Entity in Citizen App
class Grievance {
  const Grievance({
    required this.publicId,
    required this.uuid,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.priority,
    required this.state,
    required this.submittedAt,
  });

  final String publicId;
  final String uuid;
  final String title;
  final String description;
  final String categoryId;
  final String priority;
  final String state;
  final DateTime submittedAt;
}
