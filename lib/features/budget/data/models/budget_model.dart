import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetModel {
  static BudgetEntity fromDrift(Budget b) => BudgetEntity(
    id: b.id, category: b.category, limitAmount: b.limitAmount,
    period: b.period,
  );

  static BudgetsCompanion toCompanion(BudgetEntity e) =>
      BudgetsCompanion.insert(
        category: e.category, limitAmount: e.limitAmount,
        period: Value(e.period),
      );
}
