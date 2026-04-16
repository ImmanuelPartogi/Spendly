import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final int? id;
  final String category;
  final double limitAmount;
  final String period;
  double spent;

  BudgetEntity({
    this.id, required this.category, required this.limitAmount,
    this.period = 'monthly', this.spent = 0.0,
  });

  double get percentage => limitAmount > 0 ? (spent / limitAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (limitAmount - spent).clamp(0.0, double.infinity);
  bool get isExceeded => spent > limitAmount;
  bool get isWarning => percentage >= 0.8;

  BudgetEntity copyWith({
    int? id, String? category, double? limitAmount,
    String? period, double? spent,
  }) => BudgetEntity(
    id: id ?? this.id, category: category ?? this.category,
    limitAmount: limitAmount ?? this.limitAmount, period: period ?? this.period,
    spent: spent ?? this.spent,
  );

  @override
  List<Object?> get props => [id, category, limitAmount, period];
}