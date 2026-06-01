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
// SetBudgetSheet — Atur / Perbarui anggaran bulanan per kategori
//
// Kategori = AppConstants.expenseCategories
// → SAMA PERSIS dengan tab Pengeluaran di AddTransactionSheet
// → Anggaran otomatis berkurang saat transaksi pengeluaran dicatat
// ─────────────────────────────────────────────────────────────────────────────

class SetBudgetSheet extends ConsumerStatefulWidget {
  final BudgetEntity? existing;
  const SetBudgetSheet({super.key, this.existing});

  @override
  ConsumerState<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<SetBudgetSheet> {
  final _amountCtrl  = TextEditingController();
  final _amountFocus = FocusNode();
  String _category   = AppConstants.expenseCategories.first;
  bool   _isLoading  = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _category        = widget.existing!.category;
      _amountCtrl.text = ThousandSeparatorInputFormatter.format(
          widget.existing!.limitAmount);
    }
    _amountCtrl.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = ThousandSeparatorInputFormatter.parse(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah yang valid')));
      return;
    }
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
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final selColor  = CategoryUtils.getColor(_category);
    final parsedAmt = ThousandSeparatorInputFormatter.parse(_amountCtrl.text);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: bdrColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.existing == null
                          ? Icons.add_rounded
                          : Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existing == null
                            ? 'Atur Anggaran'
                            : 'Perbarui Anggaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: txtPrim,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atur batas pengeluaran bulanan',
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: surfColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: bdrColor),
                      ),
                      child:
                          Icon(Icons.close_rounded, color: txtSec, size: 16),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Kolom jumlah ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Batas Bulanan', txtSec),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? selColor.withOpacity(0.06)
                            : selColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _amountFocus.hasFocus
                              ? selColor.withOpacity(0.6)
                              : selColor.withOpacity(0.22),
                          width: _amountFocus.hasFocus ? 1.5 : 1,
                        ),
                        boxShadow: _amountFocus.hasFocus
                            ? [
                                BoxShadow(
                                    color: selColor.withOpacity(0.12),
                                    blurRadius: 14),
                              ]
                            : null,
                      ),
                      child: Row(children: [
                        Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: selColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            focusNode: _amountFocus,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              ThousandSeparatorInputFormatter()
                            ],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: selColor,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: selColor.withOpacity(0.25),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              fillColor: Colors.transparent,
                              filled: false,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_amountCtrl.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              CurrencyFormatter.formatCompact(parsedAmt),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: selColor.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Kategori — GridView 3 kolom (sama dengan AddTransactionSheet) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Kategori Pengeluaran', txtSec),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: AppConstants.expenseCategories.length,
                      itemBuilder: (_, i) {
                        final cat      = AppConstants.expenseCategories[i];
                        final selected = cat == _category;
                        final catColor = CategoryUtils.getColor(cat);
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: AnimatedContainer(
                            duration: kDurationFast,
                            curve: kCurveDefault,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? catColor.withOpacity(
                                      isDark ? 0.18 : 0.12)
                                  : surfColor,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: selected
                                    ? catColor.withOpacity(0.55)
                                    : bdrColor,
                                width: selected ? 1.5 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: catColor.withOpacity(0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CategoryUtils.getIcon(cat),
                                  size: 15,
                                  color: selected ? catColor : txtSec,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    CategoryUtils.getShortLabel(cat),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected ? catColor : txtSec,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tombol simpan ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isLoading
                    ? Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: selColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _save,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                selColor,
                                Color.lerp(selColor, Colors.white, 0.12)!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: selColor.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.existing == null
                                  ? 'Simpan Anggaran'
                                  : 'Perbarui Anggaran',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widget
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}