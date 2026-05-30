class CompanyMembership {
  const CompanyMembership({
    required this.id,
    required this.publicId,
    required this.name,
    required this.commercialName,
    required this.status,
    required this.companyUserId,
    required this.isOwner,
    required this.companyUserStatus,
  });

  final int id;
  final String publicId;
  final String name;
  final String? commercialName;
  final String status;
  final int companyUserId;
  final bool isOwner;
  final String companyUserStatus;

  factory CompanyMembership.fromMap(Map<String, dynamic> map) {
    return CompanyMembership(
      id: (map['id'] as num).toInt(),
      publicId: map['public_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      commercialName: map['commercial_name']?.toString(),
      status: map['status']?.toString() ?? 'UNKNOWN',
      companyUserId: (map['company_user_id'] as num?)?.toInt() ?? 0,
      isOwner: map['is_owner'] == true || map['is_owner'] == 1,
      companyUserStatus: map['company_user_status']?.toString() ?? 'UNKNOWN',
    );
  }
}
