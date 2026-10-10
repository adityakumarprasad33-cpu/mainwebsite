/// ApplicationUser Domain Entity in Citizen App
class ApplicationUser {
  const ApplicationUser({
    required this.userId,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.roleId,
    required this.accountState,
    required this.verificationStatus,
    this.photoUrl,
    this.departmentId,
    this.designation,
  });

  final String userId;
  final String email;
  final String phone;
  final String displayName;
  final String roleId;
  final String accountState;
  final String verificationStatus;
  final String? photoUrl;
  final String? departmentId;
  final String? designation;

  bool get isActive => accountState == 'Active';
}
