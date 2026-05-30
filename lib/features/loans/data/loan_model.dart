class Loan {
  const Loan({
    required this.id,
    required this.publicId,
    required this.loanNumber,
    required this.customerId,
    required this.customerName,
    required this.principalAmount,
    required this.interestRate,
    required this.totalAmount,
    required this.balanceAmount,
    required this.startDate,
    required this.dueDate,
    required this.status,
  });

  final int id;
  final String publicId;
  final String loanNumber;
  final int customerId;
  final String customerName;
  final double principalAmount;
  final double interestRate;
  final double totalAmount;
  final double balanceAmount;
  final String startDate;
  final String dueDate;
  final String status;

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: _asInt(map['id']),
      publicId: map['public_id']?.toString() ?? '',
      loanNumber: map['loan_number']?.toString() ?? '-',
      customerId: _asInt(map['customer_id']),
      customerName: map['customer_name']?.toString() ?? '-',
      principalAmount: _asDouble(map['principal_amount']),
      interestRate: _asDouble(map['interest_rate']),
      totalAmount: _asDouble(map['total_amount']),
      balanceAmount: _asDouble(map['balance_amount']),
      startDate: map['start_date']?.toString() ?? '',
      dueDate: map['due_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'UNKNOWN',
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
