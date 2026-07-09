import 'package:equatable/equatable.dart';

/// Represents a budget limit for a category within a billing period.
///
/// This entity is immutable. The `spent` value is a computed projection
/// (typically derived from transactions in the data layer) and is part of
/// [props] so Equatable correctly detects changes when the UI rebuilds.
class BudgetEntity extends Equatable {
  final int? id;
  final String category;
  final double limitAmount;
  final String period;
  final double spent;

  const BudgetEntity({
    this.id,
    required this.category,
    required this.limitAmount,
    this.period = 'monthly',
    this.spent = 0.0,
  });

  /// Percentage of the budget consumed, clamped to [0.0, 1.0].
  double get percentage =>
      limitAmount > 0 ? (spent / limitAmount).clamp(0.0, 1.0) : 0.0;

  /// Remaining budget, never negative.
  double get remaining => (limitAmount - spent).clamp(0.0, double.infinity);

  /// True when spending has exceeded the limit.
  bool get isExceeded => spent > limitAmount;

  /// True at or above 80% consumption.
  bool get isWarning => percentage >= 0.8;

  BudgetEntity copyWith({
    int? id,
    String? category,
    double? limitAmount,
    String? period,
    double? spent,
  }) =>
      BudgetEntity(
        id: id ?? this.id,
        category: category ?? this.category,
        limitAmount: limitAmount ?? this.limitAmount,
        period: period ?? this.period,
        spent: spent ?? this.spent,
      );

  @override
  List<Object?> get props => [id, category, limitAmount, period, spent];
}