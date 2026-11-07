class Debt {
  final int? id;
  final String person;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String note;
  final double paid;

  const Debt({
    this.id,
    required this.person,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.dueDate,
    this.note = '',
    this.paid = 0,
  });

  double get remaining => (amount - paid).clamp(0, amount).toDouble();
  String get status => remaining <= 0 ? 'مسدد' : (paid > 0 ? 'مسدد جزئياً' : 'غير مسدد');

  Map<String, Object?> toMap() => {
    'id': id, 'person': person, 'amount': amount, 'currency': currency,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate?.toIso8601String(), 'note': note, 'paid': paid,
  };

  factory Debt.fromMap(Map<String, Object?> map) => Debt(
    id: map['id'] as int?,
    person: map['person'] as String,
    amount: (map['amount'] as num).toDouble(),
    currency: map['currency'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    dueDate: map['due_date'] == null ? null : DateTime.parse(map['due_date'] as String),
    note: (map['note'] as String?) ?? '',
    paid: ((map['paid'] as num?) ?? 0).toDouble(),
  );

  Debt copyWith({int? id, String? person, double? amount, String? currency,
    DateTime? createdAt, DateTime? dueDate, String? note, double? paid}) => Debt(
      id: id ?? this.id, person: person ?? this.person, amount: amount ?? this.amount,
      currency: currency ?? this.currency, createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate, note: note ?? this.note, paid: paid ?? this.paid,
    );
}
