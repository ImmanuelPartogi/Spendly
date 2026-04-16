import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final String type;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id, required this.walletId, required this.amount,
    required this.type, required this.category, this.note,
    required this.date, required this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  TransactionEntity copyWith({
    String? id, String? walletId, double? amount, String? type,
    String? category, String? note, DateTime? date, DateTime? createdAt,
  }) => TransactionEntity(
    id: id ?? this.id, walletId: walletId ?? this.walletId,
    amount: amount ?? this.amount, type: type ?? this.type,
    category: category ?? this.category, note: note ?? this.note,
    date: date ?? this.date, createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, walletId, amount, type, category, note, date, createdAt];
}