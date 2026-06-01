import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../screens/search_screen.dart';

enum TransactionSortOption {
  newest('Terbaru'),
  oldest('Terlama'),
  largest('Terbesar'),
  smallest('Terkecil');

  final String label;
  const TransactionSortOption(this.label);
}

class TransactionFilter {
  final String? type;
  final List<String> categories;
  final double? amountMin;
  final double? amountMax;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const TransactionFilter({
    this.type,
    this.categories = const [],
    this.amountMin,
    this.amountMax,
    this.dateFrom,
    this.dateTo,
  });

  TransactionFilter copyWith({
    String? type,
    List<String>? categories,
    double? amountMin,
    double? amountMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      categories: categories ?? this.categories,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final TransactionFilter currentFilter;
  final TransactionSortOption currentSort;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.currentSort,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TransactionFilter _filter;
  late TransactionSortOption _sort;
  RangeValues _amountRange = const RangeValues(0, 10000000);

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _sort = widget.currentSort;
    if (_filter.amountMin != null || _filter.amountMax != null) {
      _amountRange = RangeValues(
        _filter.amountMin ?? 0,
        _filter.amountMax ?? 10000000,
      );
    }
  }

  void _toggleCategory(String cat) {
    final list = List<String>.from(_filter.categories);
    if (list.contains(cat)) {
      list.remove(cat);
    } else {
      list.add(cat);
    }
    setState(() => _filter = _filter.copyWith(categories: list));
  }

  void _reset() {
    setState(() {
      _filter = const TransactionFilter();
      _sort = TransactionSortOption.newest;
      _amountRange = const RangeValues(0, 10000000);
    });
  }

  void _apply() {
    Navigator.pop(context,
        _FilterResult(_filter.copyWith(
          amountMin: _amountRange.start > 0 ? _amountRange.start : null,
          amountMax: _amountRange.end < 10000000
              ? _amountRange.end
              : null,
        ), _sort));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text('Filter & Urutkan',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                    onPressed: _reset, child: const Text('Atur Ulang')),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sort ─────────────────────────────────────────────────
                  Text('Urutkan',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TransactionSortOption.values.map((s) {
                      final isSelected = s == _sort;
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _sort = s),
                        selectedColor:
                            AppColors.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Type ─────────────────────────────────────────────────
                  Text('Tipe',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: ['expense', 'income', null].map((t) {
                      final label = t == null
                          ? 'Semua'
                          : t == 'expense'
                              ? 'Pengeluaran'
                              : 'Pemasukan';
                      final isSelected = _filter.type == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(
                              () => _filter =
                                  _filter.copyWith(type: t)),
                          selectedColor:
                              AppColors.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Categories ────────────────────────────────────────────
                  Text('Kategori',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AppConstants.expenseCategories,
                      ...AppConstants.incomeCategories
                    ].map((cat) {
                      final isSelected =
                          _filter.categories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => _toggleCategory(cat),
                        selectedColor:
                            AppColors.primary.withOpacity(0.12),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Amount range ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rentang Nominal',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${CurrencyFormatter.formatCompact(_amountRange.start)} – '
                        '${CurrencyFormatter.formatCompact(_amountRange.end)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _amountRange,
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    activeColor: AppColors.primary,
                    inactiveColor:
                        AppColors.primary.withOpacity(0.2),
                    onChanged: (v) =>
                        setState(() => _amountRange = v),
                  ),
                  const SizedBox(height: 24),

                  // ── Date range ────────────────────────────────────────────
                  Text('Rentang Tanggal',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: _filter.dateFrom == null
                              ? 'Dari tanggal'
                              : _formatDate(_filter.dateFrom!),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _filter.dateFrom ??
                                  DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) {
                              setState(() => _filter =
                                  _filter.copyWith(dateFrom: d));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateButton(
                          label: _filter.dateTo == null
                              ? 'Sampai tanggal'
                              : _formatDate(_filter.dateTo!),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate:
                                  _filter.dateTo ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) {
                              setState(() => _filter =
                                  _filter.copyWith(dateTo: d));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Terapkan Filter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export so search_screen.dart can use _FilterResult
class _FilterResult {
  final TransactionFilter filter;
  final TransactionSortOption sort;
  const _FilterResult(this.filter, this.sort);
}