import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/recurring_entity.dart';
import '../../domain/usecases/recurring_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Recurring Screen
// ─────────────────────────────────────────────────────────────────────────────

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text('Gagal memuat data',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔄', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada transaksi berulang',
                    style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final active = items.where((r) => r.isActive).toList();
          final inactive = items.where((r) => !r.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _SectionLabel('Aktif (${active.length})'),
                const SizedBox(height: 8),
                ...active.map((r) => _RecurringCard(
                      item: r,
                      onToggle: (id, val) => ref
                          .read(toggleRecurringUseCaseProvider)
                          .call(id, isActive: val),
                      onEdit: () =>
                          _openAddEdit(context, existing: r),
                      onDelete: () =>
                          _confirmDelete(context, ref, r),
                    )),
              ],
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionLabel('Nonaktif (${inactive.length})'),
                const SizedBox(height: 8),
                ...inactive.map((r) => _RecurringCard(
                      item: r,
                      onToggle: (id, val) => ref
                          .read(toggleRecurringUseCaseProvider)
                          .call(id, isActive: val),
                      onEdit: () =>
                          _openAddEdit(context, existing: r),
                      onDelete: () =>
                          _confirmDelete(context, ref, r),
                    )),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEdit(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _openAddEdit(BuildContext context,
      {RecurringEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecurringSheet(existing: existing),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, RecurringEntity item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus?'),
        content: const Text(
            'Transaksi berulang ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(deleteRecurringUseCaseProvider).call(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringEntity item;
  final void Function(String, bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecurringCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _nextDueLabel() {
    final diff = item.nextDue.difference(DateTime.now()).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff < 0) return 'Terlambat ${diff.abs()}h';
    return '$diff hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        item.isExpense ? AppColors.expense : AppColors.income;
    final catColor = CategoryUtils.getColor(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            item.isActive ? AppColors.card : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive
              ? AppColors.border
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                CategoryUtils.getIcon(item.category),
                color: catColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: item.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.frequency.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Jatuh tempo: ${_nextDueLabel()}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.isExpense ? '-' : '+'} ${CurrencyFormatter.formatCompact(item.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus',
                            style:
                                TextStyle(color: AppColors.expense)),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: item.isActive,
                    onChanged: (v) => onToggle(item.id, v),
                    activeColor: AppColors.primary,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Recurring Sheet
// ─────────────────────────────────────────────────────────────────────────────

class AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringEntity? existing;
  const AddRecurringSheet({super.key, this.existing});

  @override
  ConsumerState<AddRecurringSheet> createState() =>
      _AddRecurringSheetState();
}

class _AddRecurringSheetState
    extends ConsumerState<AddRecurringSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = AppConstants.typeExpense;
  String _category = AppConstants.expenseCategories.first;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int _dayOfMonth = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _noteCtrl.text = e.note ?? '';
      _type = e.type;
      _category = e.category;
      _frequency = e.frequency;
      _dayOfMonth = e.dayOfMonth;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final nextDue = computeNextDue(
        _frequency,
        dayOfMonth: _dayOfMonth,
        dayOfWeek: widget.existing?.dayOfWeek ?? 1,
      );

      final entity = RecurringEntity(
        id: widget.existing?.id ?? '',
        title: title,
        amount: amount,
        type: _type,
        category: _category,
        frequency: _frequency,
        dayOfMonth: _dayOfMonth,
        dayOfWeek: widget.existing?.dayOfWeek ?? 1,
        isActive: widget.existing?.isActive ?? true,
        nextDue: nextDue,
        note: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
      );

      if (widget.existing == null) {
        await ref.read(addRecurringUseCaseProvider).call(entity);
      } else {
        await ref.read(updateRecurringUseCaseProvider).call(entity);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == AppConstants.typeExpense
        ? AppConstants.expenseCategories
        : AppConstants.incomeCategories;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null
                  ? 'Tambah Transaksi Berulang'
                  : 'Edit Transaksi Berulang',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            // Type selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = AppConstants.typeExpense;
                      _category =
                          AppConstants.expenseCategories.first;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == AppConstants.typeExpense
                            ? AppColors.expense.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == AppConstants.typeExpense
                              ? AppColors.expense
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _type == AppConstants.typeExpense
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color: _type == AppConstants.typeExpense
                                ? AppColors.expense
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = AppConstants.typeIncome;
                      _category =
                          AppConstants.incomeCategories.first;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == AppConstants.typeIncome
                            ? AppColors.income.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == AppConstants.typeIncome
                              ? AppColors.income
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _type == AppConstants.typeIncome
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color: _type == AppConstants.typeIncome
                                ? AppColors.income
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Nominal', prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categories.contains(_category)
                  ? _category
                  : categories.first,
              decoration:
                  const InputDecoration(labelText: 'Kategori'),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            Text('Frekuensi',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: RecurringFrequency.values.map((f) {
                final isSel = f == _frequency;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_frequency == RecurringFrequency.monthly) ...[
              const SizedBox(height: 16),
              Text('Tanggal Jatuh Tempo',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(28, (i) {
                  final day = i + 1;
                  final isSel = day == _dayOfMonth;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _dayOfMonth = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSel
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}