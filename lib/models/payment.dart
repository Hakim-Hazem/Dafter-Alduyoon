class Payment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paidAt;
  final String note;
  const Payment({this.id, required this.debtId, required this.amount, required this.paidAt, this.note = ''});
  Map<String, Object?> toMap() => {
    'id': id, 'debt_id': debtId, 'amount': amount,
    'paid_at': paidAt.toIso8601String(), 'note': note,
  };
  factory Payment.fromMap(Map<String, Object?> m) => Payment(
    id: m['id'] as int?, debtId: m['debt_id'] as int,
    amount: (m['amount'] as num).toDouble(),
    paidAt: DateTime.parse(m['paid_at'] as String), note: (m['note'] as String?) ?? '',
  );
}
