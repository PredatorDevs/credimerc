class Payment {
  const Payment({
    required this.id,
    required this.publicId,
    required this.loanId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    required this.referenceNumber,
    required this.notes,
    required this.voidReason,
  });

  final int id;
  final String publicId;
  final int loanId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String status;
  final String? referenceNumber;
  final String? notes;
  final String? voidReason;

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _asInt(map['id']),
      publicId: map['public_id']?.toString() ?? '',
      loanId: _asInt(map['loan_id']),
      amount: _asDouble(map['amount']),
      paymentMethod: map['payment_method']?.toString() ?? 'UNKNOWN',
      paymentDate: map['payment_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'UNKNOWN',
      referenceNumber: map['reference_number']?.toString(),
      notes: map['notes']?.toString(),
      voidReason: map['void_reason']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
