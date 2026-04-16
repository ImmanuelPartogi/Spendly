import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tables
// ─────────────────────────────────────────────────────────────────────────────

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Wallets extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get type => text().withDefault(const Constant('cash'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF00C48C))();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  // ← NEW: tracking sync status
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get walletId => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  // ← NEW: false = belum sync ke Firebase, true = sudah sync
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();
  // ← NEW: true = tidak bisa dihapus (locked)
  BoolColumn get isLocked =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get limitAmount => real()();
  TextColumn get period =>
      text().withDefault(const Constant('monthly'))();
  // ← NEW
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();
}

class Insights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Goals extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get emoji =>
      text().withDefault(const Constant('🎯'))();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount =>
      real().withDefault(const Constant(0.0))();
  DateTimeColumn get deadline => dateTime()();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF3A7AFE))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  // ← NEW
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Recurrings extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  TextColumn get frequency =>
      text().withDefault(const Constant('monthly'))();
  IntColumn get dayOfMonth =>
      integer().withDefault(const Constant(1))();
  IntColumn get dayOfWeek =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get nextDue => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDatabase
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Users, Wallets, Transactions, Budgets, Insights, Goals, Recurrings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3; // ← naik dari 2 ke 3

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultWallet();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2: UUID wallet, goals, recurrings
        if (from < 2) {
          await m.drop(transactions);
          await m.drop(wallets);
          await m.drop(budgets);
          await m.createTable(wallets);
          await m.createTable(transactions);
          await m.createTable(budgets);
          await m.createTable(goals);
          await m.createTable(recurrings);
          await _seedDefaultWallet();
        }
        // v2 → v3: Tambah kolom synced, isLocked
        if (from < 3) {
          // Transactions: tambah synced + isLocked
          await m.addColumn(
              transactions, transactions.synced);
          await m.addColumn(
              transactions, transactions.isLocked);
          // Wallets: tambah synced
          await m.addColumn(wallets, wallets.synced);
          // Budgets: tambah synced
          await m.addColumn(budgets, budgets.synced);
          // Goals: tambah synced
          await m.addColumn(goals, goals.synced);
        }
      },
    );
  }

  Future<void> _seedDefaultWallet() async {
    await into(wallets).insert(WalletsCompanion.insert(
      id: const Uuid().v4(),
      name: 'Cash',
      type: const Value('cash'),
      colorValue: const Value(0xFF00C48C),
      isDefault: const Value(true),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection
// ─────────────────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'spendly.db'));
    return NativeDatabase.createInBackground(file);
  });
}