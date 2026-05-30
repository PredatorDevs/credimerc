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
      id: (map['id'] as num?)?.toInt() ?? 0,
      publicId: map['public_id']?.toString() ?? '',
      loanId: (map['loan_id'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method']?.toString() ?? 'UNKNOWN',
      paymentDate: map['payment_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'UNKNOWN',
      referenceNumber: map['reference_number']?.toString(),
      notes: map['notes']?.toString(),
      voidReason: map['void_reason']?.toString(),
    );
  }
}
