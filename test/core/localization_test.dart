import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/localization/app_strings.dart';

void main() {
  group('AppStrings Localization Unit Tests', () {
    test('key parity exists between ID and EN dictionaries', () {
      expect(AppStrings.hasKeyParity(), isTrue,
          reason: 'ID and EN dictionaries must have identical set of keys');
    });

    test('get returns Indonesian string for id locale including expanded keys', () {
      const locale = Locale('id');
      expect(AppStrings.get('dashboard', locale), 'Dashboard');
      expect(AppStrings.get('income', locale), 'Pemasukan');
      expect(AppStrings.get('expense', locale), 'Pengeluaran');
      expect(AppStrings.get('monthly_budget', locale), 'Anggaran Bulanan');
      expect(AppStrings.get('financial_goals', locale), 'Target Keuangan');
      expect(AppStrings.get('scanner_review', locale), 'Hasil Scan Struk');
      expect(AppStrings.get('logout', locale), 'Keluar');
      expect(AppStrings.get('weekly_recap', locale), 'Rekap Mingguan');
      expect(AppStrings.get('inactivity_reminder', locale), 'Pengingat Transaksi');
    });

    test('get returns English string for en locale including expanded keys', () {
      const locale = Locale('en');
      expect(AppStrings.get('dashboard', locale), 'Dashboard');
      expect(AppStrings.get('income', locale), 'Income');
      expect(AppStrings.get('expense', locale), 'Expense');
      expect(AppStrings.get('monthly_budget', locale), 'Monthly Budget');
      expect(AppStrings.get('financial_goals', locale), 'Financial Goals');
      expect(AppStrings.get('scanner_review', locale), 'Scan Results');
      expect(AppStrings.get('logout', locale), 'Log Out');
      expect(AppStrings.get('weekly_recap', locale), 'Weekly Recap');
      expect(AppStrings.get('inactivity_reminder', locale), 'Transaction Reminder');
    });

    test('get falls back to Indonesian for unknown key', () {
      const locale = Locale('en');
      expect(AppStrings.get('non_existent_key', locale), 'non_existent_key');
    });

    test('AppStrings resolves monthly_budget and financial_goals in ID & EN', () {
      expect(AppStrings.get('monthly_budget', const Locale('id')), 'Anggaran Bulanan');
      expect(AppStrings.get('monthly_budget', const Locale('en')), 'Monthly Budget');
      expect(AppStrings.get('financial_goals', const Locale('id')), 'Target Keuangan');
      expect(AppStrings.get('financial_goals', const Locale('en')), 'Financial Goals');
    });

    test('AppStrings resolves scanner_review and logout in ID & EN', () {
      expect(AppStrings.get('scanner_review', const Locale('id')), 'Hasil Scan Struk');
      expect(AppStrings.get('scanner_review', const Locale('en')), 'Scan Results');
      expect(AppStrings.get('logout', const Locale('id')), 'Keluar');
      expect(AppStrings.get('logout', const Locale('en')), 'Log Out');
    });

    test('AppStrings resolves weekly_recap and inactivity_reminder in ID & EN', () {
      expect(AppStrings.get('weekly_recap', const Locale('id')), 'Rekap Mingguan');
      expect(AppStrings.get('weekly_recap', const Locale('en')), 'Weekly Recap');
      expect(AppStrings.get('inactivity_reminder', const Locale('id')), 'Pengingat Transaksi');
      expect(AppStrings.get('inactivity_reminder', const Locale('en')), 'Transaction Reminder');
    });

    test('AppStrings resolves content keys (total_budget, used, remaining) in ID & EN', () {
      expect(AppStrings.get('total_budget', const Locale('id')), 'Total Anggaran');
      expect(AppStrings.get('total_budget', const Locale('en')), 'Total Budget');
      expect(AppStrings.get('used', const Locale('id')), 'Terpakai');
      expect(AppStrings.get('used', const Locale('en')), 'Used');
      expect(AppStrings.get('remaining', const Locale('id')), 'Sisa');
      expect(AppStrings.get('remaining', const Locale('en')), 'Remaining');
    });

    test('AppStrings resolves content keys (savings_target, collected, deadline) in ID & EN', () {
      expect(AppStrings.get('savings_target', const Locale('id')), 'Target Tabungan');
      expect(AppStrings.get('savings_target', const Locale('en')), 'Savings Target');
      expect(AppStrings.get('collected', const Locale('id')), 'Terkumpul');
      expect(AppStrings.get('collected', const Locale('en')), 'Collected');
      expect(AppStrings.get('deadline', const Locale('id')), 'Batas Waktu');
      expect(AppStrings.get('deadline', const Locale('en')), 'Deadline');
    });

    test('AppStrings resolves scanner content keys (confirm_scan, suggested_category) in ID & EN', () {
      expect(AppStrings.get('confirm_scan', const Locale('id')), 'Konfirmasi Hasil Scan');
      expect(AppStrings.get('confirm_scan', const Locale('en')), 'Confirm Scan Results');
      expect(AppStrings.get('suggested_category', const Locale('id')), 'Kategori Disarankan');
      expect(AppStrings.get('suggested_category', const Locale('en')), 'Suggested Category');
    });

    test('AppStrings resolves Dashboard Batch 1 keys (good_morning, balance, empty_transactions_sub) in ID & EN', () {
      expect(AppStrings.get('good_morning', const Locale('id')), 'Selamat Pagi');
      expect(AppStrings.get('good_morning', const Locale('en')), 'Good Morning');
      expect(AppStrings.get('good_afternoon', const Locale('id')), 'Selamat Siang');
      expect(AppStrings.get('good_afternoon', const Locale('en')), 'Good Afternoon');
      expect(AppStrings.get('good_evening', const Locale('id')), 'Selamat Malam');
      expect(AppStrings.get('good_evening', const Locale('en')), 'Good Evening');
      expect(AppStrings.get('balance', const Locale('id')), 'Saldo');
      expect(AppStrings.get('balance', const Locale('en')), 'Balance');
      expect(AppStrings.get('empty_transactions_sub', const Locale('id')), 'Transaksi kamu akan muncul di sini');
      expect(AppStrings.get('empty_transactions_sub', const Locale('en')), 'Your transactions will appear here');
    });

    test('AppStrings resolves AddTransaction Batch 1 keys (quick_amounts, write_note, save_transaction, etc) in ID & EN', () {
      expect(AppStrings.get('quick_amounts', const Locale('id')), 'Nominal Cepat');
      expect(AppStrings.get('quick_amounts', const Locale('en')), 'Quick Amounts');
      expect(AppStrings.get('write_note', const Locale('id')), 'Tulis catatan');
      expect(AppStrings.get('write_note', const Locale('en')), 'Write a note');
      expect(AppStrings.get('save_transaction', const Locale('id')), 'Simpan Transaksi');
      expect(AppStrings.get('save_transaction', const Locale('en')), 'Save Transaction');
      expect(AppStrings.get('amount_required', const Locale('id')), 'Nominal wajib diisi');
      expect(AppStrings.get('amount_required', const Locale('en')), 'Amount is required');
      expect(AppStrings.get('scan', const Locale('id')), 'Pindai');
      expect(AppStrings.get('scan', const Locale('en')), 'Scan');
    });

    test('AppStrings resolves TransactionsScreen Batch 2 keys (all_transactions, records_and) in ID & EN', () {
      expect(AppStrings.get('all_transactions', const Locale('id')), 'Semua Transaksi');
      expect(AppStrings.get('all_transactions', const Locale('en')), 'All Transactions');
      expect(AppStrings.get('records_and', const Locale('id')), 'Catatan &');
      expect(AppStrings.get('records_and', const Locale('en')), 'Records &');
    });

    test('AppStrings resolves BudgetScreen Batch 2 keys (active_budgets, manage_and, total_monthly_budget) in ID & EN', () {
      expect(AppStrings.get('active_budgets', const Locale('id')), 'Anggaran Aktif');
      expect(AppStrings.get('active_budgets', const Locale('en')), 'Active Budgets');
      expect(AppStrings.get('manage_and', const Locale('id')), 'Kelola &');
      expect(AppStrings.get('manage_and', const Locale('en')), 'Manage &');
      expect(AppStrings.get('total_monthly_budget', const Locale('id')), 'Total Budget Bulan Ini');
      expect(AppStrings.get('total_monthly_budget', const Locale('en')), 'Total Monthly Budget');
    });

    test('all supportedKeys return non-empty non-key values for both ID and EN locales', () {
      for (final key in AppStrings.supportedKeys) {
        final idVal = AppStrings.get(key, const Locale('id'));
        final enVal = AppStrings.get(key, const Locale('en'));
        expect(idVal.isNotEmpty, isTrue, reason: 'Key $key in ID must not be empty');
        expect(enVal.isNotEmpty, isTrue, reason: 'Key $key in EN must not be empty');
        expect(idVal, isNot(equals(key)), reason: 'Key $key in ID should not fall back to key name');
        expect(enVal, isNot(equals(key)), reason: 'Key $key in EN should not fall back to key name');
      }
    });
  });
}
