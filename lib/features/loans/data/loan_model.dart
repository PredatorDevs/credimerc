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
      id: (map['id'] as num?)?.toInt() ?? 0,
      publicId: map['public_id']?.toString() ?? '',
      loanNumber: map['loan_number']?.toString() ?? '-',
      customerId: (map['customer_id'] as num?)?.toInt() ?? 0,
      customerName: map['customer_name']?.toString() ?? '-',
      principalAmount: (map['principal_amount'] as num?)?.toDouble() ?? 0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (map['balance_amount'] as num?)?.toDouble() ?? 0,
      startDate: map['start_date']?.toString() ?? '',
      dueDate: map['due_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'UNKNOWN',
    );
  }
}
