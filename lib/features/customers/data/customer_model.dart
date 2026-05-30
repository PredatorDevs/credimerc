class Customer {
  const Customer({
    required this.id,
    required this.publicId,
    required this.fullName,
    required this.phone,
    required this.documentNumber,
    required this.status,
  });

  final int id;
  final String publicId;
  final String fullName;
  final String? phone;
  final String? documentNumber;
  final String status;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: (map['id'] as num?)?.toInt() ?? 0,
      publicId: map['public_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '-',
      phone: map['phone']?.toString(),
      documentNumber: map['document_number']?.toString(),
      status: map['status']?.toString() ?? 'UNKNOWN',
    );
  }
}
