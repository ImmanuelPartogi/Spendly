import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../domain/entities/budget_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetBudgetSheet
//
// Perubahan dari versi sebelumnya:
// - autofocus DIMATIKAN — keyboard tidak langsung muncul saat sheet dibuka
//   (UX improvement: terasa lebih natural dan tidak mengejutkan)
// ─────────────────────────────────────────────────────────────────────────────

class SetBudgetSheet extends ConsumerStatefulWidget {
  final BudgetEntity? existing;
  const SetBudgetSheet({super.key, this.existing});

  @override
  ConsumerState<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<SetBudgetSheet> {
  final _amountCtrl = TextEditingController();
  String _category  = AppConstants.expenseCategories.first;
  bool _isLoading   = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _category     = widget.existing!.category;
      _amountCtrl.text = ThousandSeparatorInputFormatter
          .format(widget.existing!.limitAmount);
    }
    _amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = ThousandSeparatorInputFormatter.parse(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah yang valid')));
      return;
    }
    // Tutup keyboard
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await ref.read(setBudgetUseCaseProvider).call(BudgetEntity(
            id: widget.existing?.id,
            category: _category,
            limitAmount: amount,
          ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor   = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor    = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim     = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec      = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtHint     = isDark ? AppColors.textHintDark      : AppColors.textHint;
    final bottomPad   = MediaQuery.of(context).viewInsets.bottom;
    final selColor    = CategoryUtils.getColor(_category);
    final parsedAmt   = ThousandSeparatorInputFormatter.parse(_amountCtrl.text);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: bottomPad + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: bdrColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ────────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Icon(
                  widget.existing == null
                      ? Icons.add_rounded
                      : Icons.edit_rounded,
                  color: Colors.white, size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.existing == null ? 'Set Budget' : 'Edit Budget',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: txtPrim, letterSpacing: -0.5,
                  ),
                ),
                Text('Atur batas pengeluaran bulanan',
                    style: TextStyle(
                        fontSize: 11, color: txtSec,
                        fontWeight: FontWeight.w400)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: surfColor, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                      size: 15, color: txtSec),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Amount field ──────────────────────────────────────────────
            _SheetSectionLabel(label: 'Batas Bulanan', isDark: isDark),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: parsedAmt > 0
                      ? AppColors.primary.withOpacity(0.40)
                      : bdrColor,
                  width: parsedAmt > 0 ? 1.5 : 1,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Rp', style: TextStyle(
                    color: parsedAmt > 0 ? AppColors.primary : txtSec,
                    fontSize: 16, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      // ✅ autofocus: false (default) — tidak buka keyboard otomatis
                      inputFormatters: [
                        ThousandSeparatorInputFormatter()
                      ],
                      style: TextStyle(
                        color: txtPrim, fontSize: 22,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: txtHint, fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (_amountCtrl.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        CurrencyFormatter.formatCompact(parsedAmt),
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Category ──────────────────────────────────────────────────
            _SheetSectionLabel(label: 'Kategori', isDark: isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.expenseCategories.map((cat) {
                final sel   = cat == _category;
                final color = CategoryUtils.getColor(cat);
                final icon  = CategoryUtils.getIcon(cat);
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: kDurationFast,
                    curve: kCurveDefault,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? color.withOpacity(isDark ? 0.18 : 0.10)
                          : surfColor,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: sel ? color : bdrColor,
                          width: sel ? 1.5 : 1),
                      boxShadow: sel
                          ? [BoxShadow(
                              color: color.withOpacity(0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )]
                          : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 13, color: sel ? color : txtSec),
                      const SizedBox(width: 5),
                      Text(
                        CategoryUtils.getShortLabel(cat),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: sel ? color : txtSec,
                        ),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selColor,
                  disabledBackgroundColor: selColor.withOpacity(0.38),
                  shadowColor: selColor.withOpacity(0.35),
                  elevation: _isLoading ? 0 : 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.existing == null
                            ? 'Simpan Budget'
                            : 'Update Budget',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SheetSectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
        letterSpacing: 0.2,
      )),
    ]);
  }
}