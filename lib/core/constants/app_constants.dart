class AppConstants {
  AppConstants._();

  static const String appName = 'Spendly';
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // ── Expense Categories (18) ───────────────────────────────────────────────
  static const List<String> expenseCategories = [
    'Food & Drink',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health & Medical',
    'Bills & Utilities',
    'Education',
    'Personal Care',
    'Home & Furniture',
    'Electronics',
    'Travel',
    'Restaurant & Cafe',
    'Subscription',
    'Insurance',
    'Sport & Fitness',
    'Gifts & Charity',
    'Pets',
    'Others',
  ];

  // ── Income Categories (10) ────────────────────────────────────────────────
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Bonus',
    'Gift',
    'Rental',
    'Dividend',
    'Side Job',
    'Others',
  ];

  static const String periodMonthly = 'monthly';

  static const List<String> daysOfWeek = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static const List<String> daysOfWeekFull = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

  static const int defaultUserId = 1;
}