import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../domain/models/scanned_transaction_result.dart';
import '../../domain/services/ocr_parser_service.dart';
import '../widgets/scan_result_edit_sheet.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model — ScanResultItem
// ─────────────────────────────────────────────────────────────────────────────

/// Data class lokal yang membungkus hasil scan + metadata UI untuk review.
class ScanResultItem {
  final ScannedTransactionResult result;
  final String imagePath;

  /// Apakah user ingin menyimpan item ini.
  final bool isSelected;

  /// Apakah item ini sudah diedit manual oleh user.
  final bool isEdited;

  const ScanResultItem({
    required this.result,
    required this.imagePath,
    this.isSelected = false,
    this.isEdited = false,
  });

  ScanResultItem copyWith({
    ScannedTransactionResult? result,
    String? imagePath,
    bool? isSelected,
    bool? isEdited,
  }) {
    return ScanResultItem(
      result: result ?? this.result,
      imagePath: imagePath ?? this.imagePath,
      isSelected: isSelected ?? this.isSelected,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State — StateNotifier
// ─────────────────────────────────────────────────────────────────────────────

class ScanReviewNotifier extends StateNotifier<List<ScanResultItem>> {
  ScanReviewNotifier(List<ScanResultItem> initial) : super(initial);

  void toggleSelection(int index) {
    final items = List<ScanResultItem>.from(state);
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    items[index] = item.copyWith(isSelected: !item.isSelected);
    state = items;
  }

  void updateItem(int index, ScanResultItem updatedItem) {
    final items = List<ScanResultItem>.from(state);
    if (index < 0 || index >= items.length) return;
    items[index] = updatedItem.copyWith(isEdited: true);
    state = items;
  }

  void selectAll() {
    state = [
      for (final item in state)
        if (item.result.success) item.copyWith(isSelected: true) else item,
    ];
  }

  void deselectAll() {
    state = [for (final item in state) item.copyWith(isSelected: false)];
  }
}

/// Provider lokal — di-override via ProviderScope di layar ini.
///
/// Saat navigasi ke [ScanReviewScreen], bungkus dengan:
/// ```
/// ProviderScope(
///   overrides: [
///     scanReviewProvider.overrideWith(
///       (ref) => ScanReviewNotifier(items),
///     ),
///   ],
///   child: const ScanReviewScreen(),
/// )
/// ```
final scanReviewProvider =
    StateNotifierProvider.autoDispose<ScanReviewNotifier, List<ScanResultItem>>(
  (ref) => ScanReviewNotifier(const []),
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen — ScanReviewScreen
// ─────────────────────────────────────────────────────────────────────────────

class ScanReviewScreen extends ConsumerWidget {
  const ScanReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = ref.watch(scanReviewProvider);

    // Hitung summary.
    final selectedCount =
        allItems.where((e) => e.isSelected).length;
    final failedCount =
        allItems.where((e) => !e.result.success).length;
    final editedCount = allItems.where((e) => e.isEdited).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('review_scan_results', locale)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: AppStrings.get('select_all', locale),
            icon: const Icon(Icons.select_all_rounded, size: 20),
            onPressed: () =>
                ref.read(scanReviewProvider.notifier).selectAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Section 1 — Summary bar ────────────────────────────────────
          _SummaryBar(
            selectedCount: selectedCount,
            failedCount: failedCount,
            editedCount: editedCount,
          ),

          // ── Section 2 — List of results ────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = allItems[i];
                if (!item.result.success) {
                  return _FailedResultCard(
                    item: item,
                    isDark: isDark,
                    onToggle: () =>
                        ref.read(scanReviewProvider.notifier).toggleSelection(i),
                    onEdit: () => _openEditSheet(context, ref, i),
                  );
                }
                return _SuccessResultCard(
                  item: item,
                  isDark: isDark,
                  onToggle: () =>
                      ref.read(scanReviewProvider.notifier).toggleSelection(i),
                  onEdit: () => _openEditSheet(context, ref, i),
                );
              },
            ),
          ),

          // ── Section 3 — Bottom action bar ──────────────────────────────
          _BottomActionBar(
            selectedCount: selectedCount,
            onCancel: () => Navigator.pop(context),
            onSave: () => _onSave(context, ref, allItems),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _openEditSheet(BuildContext context, WidgetRef ref, int index) async {
    final notifier = ref.read(scanReviewProvider.notifier);
    final current = ref.read(scanReviewProvider)[index];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScanResultEditSheet(
        item: current,
        onSave: (updated) => notifier.updateItem(index, updated),
      ),
    );
  }

  Future<void> _onSave(
    BuildContext context,
    WidgetRef ref,
    List<ScanResultItem> allItems,
  ) async {
    final locale = ref.read(localeProvider);
    final selected = allItems.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return;

    // ── Dialog konfirmasi ──────────────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('confirm_save', locale)),
        content: Text(
          '${selected.length} ${AppStrings.get('save_transactions_confirm_sub', locale)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('check_again', locale)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.get('save_now', locale)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // ── Pilih dompet ───────────────────────────────────────────────────────────
    final walletsAsync = ref.read(walletListProvider);
    List<WalletEntity> wallets = [];
    walletsAsync.whenData((data) => wallets = data);
    if (wallets.isEmpty) {
      wallets = await ref.read(getWalletsUseCaseProvider).getAll();
    }

    if (wallets.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('no_wallets_warning', locale)),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final wallet = await showDialog<WalletEntity>(
      context: context,
      builder: (ctx) {
        var selected = wallets.firstWhere(
          (w) => w.isDefault,
          orElse: () => wallets.first,
        );
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text(AppStrings.get('select_wallet', locale)),
            content: DropdownButtonFormField<WalletEntity>(
              value: selected,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Text('${w.type.emoji} ${w.name}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setSt(() => selected = v);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.get('cancel', locale)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: Text(AppStrings.get('save', locale)),
              ),
            ],
          ),
        );
      },
    );

    if (wallet == null || !context.mounted) return;

    // ── Simpan transaksi satu per satu ──────────────────────────────────────────
    var successCount = 0;
    var failCount = 0;

    for (final item in selected) {
      final r = item.result;

      // Lewati bila amount null.
      if (r.amount == null) {
        debugPrint('[ScanReview] Melewatkan item tanpa nominal: ${r.source}');
        continue;
      }

      try {
        final type = r.type == ScannedDocumentType.salarySlip
            ? AppConstants.typeIncome
            : AppConstants.typeExpense;

        final entity = TransactionModel.create(
          walletId: wallet.id,
          amount: r.amount!,
          type: type,
          category: _mapCategory(r),
          note: r.description,
          date: r.date ?? DateTime.now(),
        );
        await ref.read(addTransactionUseCaseProvider).call(entity);
        successCount++;
      } catch (e) {
        debugPrint('[ScanReview] Gagal menyimpan transaksi: $e');
        failCount++;
      }
    }

    if (!context.mounted) return;
    await HapticUtils.success();

    // ── Snackbar hasil ──────────────────────────────────────────────────────────
    final snackbarMsg = failCount > 0
        ? '$successCount ${AppStrings.get('save_transaction', locale)}'
        : '$successCount ${AppStrings.get('save_transaction', locale)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackbarMsg)),
    );

    // Kembali ke layar utama.
    Navigator.pop(context); // tutup review
    Navigator.pop(context); // tutup scanner
  }

  /// Map source → kategori terdekat yang tersedia via OcrParserService.
  String _mapCategory(ScannedTransactionResult r) {
    return OcrParserService.suggestCategory(type: r.type, source: r.source);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends ConsumerWidget {
  final int selectedCount;
  final int failedCount;
  final int editedCount;

  const _SummaryBar({
    required this.selectedCount,
    required this.failedCount,
    required this.editedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              count: selectedCount,
              label: AppStrings.get('will_be_saved', locale),
              color: AppColors.income,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              count: failedCount,
              label: AppStrings.get('failed', locale),
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              count: editedCount,
              label: AppStrings.get('edited', locale),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SuccessResultCard extends ConsumerWidget {
  final ScanResultItem item;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _SuccessResultCard({
    required this.item,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
  });

  String _typeLabel(Locale locale) {
    switch (item.result.type) {
      case ScannedDocumentType.receipt:
        return AppStrings.get('receipt', locale);
      case ScannedDocumentType.salarySlip:
        return AppStrings.get('salary_slip', locale);
      case ScannedDocumentType.unknown:
        return AppStrings.get('unknown', locale);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final dateStr = item.result.date != null
        ? DateFormat('dd MMM yyyy').format(item.result.date!)
        : AppStrings.get('date_not_detected', locale);

    final amountStr = item.result.amount != null
        ? CurrencyFormatter.format(item.result.amount!)
        : AppStrings.get('amount_not_detected', locale);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdrColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(item.imagePath),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.surface,
                child: const Icon(Icons.broken_image_rounded, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with merchant + edited badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.result.source ?? AppStrings.get('unknown', locale),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isEdited) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppStrings.get('edited', locale),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _typeLabel(locale),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: txtSec),
                ),
                const SizedBox(height: 2),
                Text(
                  amountStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.result.amount != null
                        ? AppColors.primary
                        : txtSec,
                  ),
                ),
                const SizedBox(height: 6),
                // Edit button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppStrings.get('edit', locale),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isSelected
                        ? AppColors.primary
                        : bdrColor,
                    width: 2,
                  ),
                  color: item.isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                child: item.isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedResultCard extends ConsumerWidget {
  final ScanResultItem item;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _FailedResultCard({
    required this.item,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                  child: Image.file(
                    File(item.imagePath),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.error_rounded,
                      color: AppColors.error, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('scan_failed', locale),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.result.errorMessage ??
                      AppStrings.get('scan_failed_sub', locale),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppStrings.get('try_edit', locale),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isSelected ? AppColors.primary : bdrColor,
                    width: 2,
                  ),
                  color: item.isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                child: item.isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _BottomActionBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppStrings.get('cancel', locale)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: selectedCount == 0 ? null : onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('${AppStrings.get('save', locale)} $selectedCount ${AppStrings.get('transactions', locale)}'),
            ),
          ),
        ],
      ),
    );
  }
}