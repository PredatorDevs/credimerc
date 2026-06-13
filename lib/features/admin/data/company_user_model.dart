class CompanyUser {
  const CompanyUser({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.status,
    required this.isOwner,
    required this.employeeCode,
    required this.jobTitle,
  });

  final int id;
  final int companyId;
  final int userId;
  final String userEmail;
  final String userFullName;
  final String status;
  final bool isOwner;
  final String? employeeCode;
  final String? jobTitle;

  factory CompanyUser.fromMap(Map<String, dynamic> map) {
    return CompanyUser(
      id: _asInt(map['id']),
      companyId: _asInt(map['company_id']),
      userId: _asInt(map['user_id']),
      userEmail: map['user_email']?.toString() ?? '',
      userFullName: map['user_full_name']?.toString() ?? 'Sin nombre',
      status: map['status']?.toString() ?? 'INACTIVE',
      isOwner: map['is_owner'] == 1 || map['is_owner'] == true,
      employeeCode: _nullableString(map['employee_code']),
      jobTitle: _nullableString(map['job_title']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return text;
  }
}
