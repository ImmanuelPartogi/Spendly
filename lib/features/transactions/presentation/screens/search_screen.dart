import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen — Upgraded
//
// Improvements vs v1:
// - Search bar: floating card style dengan shadow, rounded lebih besar
// - Filter chips: dengan icon di depan, lebih informatif
// - Result header: total income / expense ditampilkan dengan warna
// - Tiles: divider hanya dari icon (tidak full width) — konsisten dgn TransactionTile v2
// - Empty states: lebih polished dengan icon glow
// - Subtle gradient header background untuk depth
// ─────────────────────────────────────────────────────────────────────────────

enum _SortOption {
  newest('Terbaru'),
  oldest('Terlama'),
  largest('Terbesar'),
  smallest('Terkecil');

  final String label;
  const _SortOption(this.label);
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  _SortOption _sort = _SortOption.newest;
  String? _typeFilter; // null=all, 'expense', 'income'

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<TransactionEntity> _filter(List<TransactionEntity> all) {
    final result = all.where((tx) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!tx.category.toLowerCase().contains(q) &&
            !(tx.note?.toLowerCase().contains(q) ?? false) &&
            !tx.amount.toString().contains(q)) {
          return false;
        }
      }
      if (_typeFilter == 'expense' && !tx.isExpense) return false;
      if (_typeFilter == 'income'  &&  tx.isExpense) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _SortOption.newest:
        result.sort((a, b) => b.date.compareTo(a.date));
      case _SortOption.oldest:
        result.sort((a, b) => a.date.compareTo(b.date));
      case _SortOption.largest:
        result.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortOption.smallest:
        result.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtHint   = isDark ? AppColors.textHintDark      : AppColors.textHint;
    final divColor  = isDark ? AppColors.dividerDark       : AppColors.divider;

    final txAsync = ref.watch(allTransactionsStreamProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Sticky header ─────────────────────────────────────────
            _SearchHeader(
              ctrl: _ctrl,
              focus: _focus,
              query: _query,
              isDark: isDark,
              surfColor: surfColor,
              bdrColor: bdrColor,
              txtPrim: txtPrim,
              txtHint: txtHint,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
              onBack: () => Navigator.pop(context),
            ),

            // ── Filters ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _TypeChip(
                    label: 'Semua',
                    icon: Icons.list_rounded,
                    isSelected: _typeFilter == null,
                    isDark: isDark,
                    onTap: () => setState(() => _typeFilter = null),
                  ),
                  const SizedBox(width: 7),
                  _TypeChip(
                    label: 'Keluar',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: _typeFilter == 'expense',
                    color: AppColors.expense,
                    isDark: isDark,
                    onTap: () => setState(() => _typeFilter = 'expense'),
                  ),
                  const SizedBox(width: 7),
                  _TypeChip(
                    label: 'Masuk',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: _typeFilter == 'income',
                    color: AppColors.income,
                    isDark: isDark,
                    onTap: () => setState(() => _typeFilter = 'income'),
                  ),
                  const Spacer(),
                  _SortButton(
                    current: _sort,
                    isDark: isDark,
                    onChanged: (s) => setState(() => _sort = s),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1, color: divColor),
            ),

            // ── Results ───────────────────────────────────────────────
            Expanded(
              child: txAsync.when(
                loading: () => ShimmerScope(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4,),
                    itemCount: 8,
                    itemBuilder: (_, __) => const _TileShimmer(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Terjadi kesalahan: $e',
                      style: TextStyle(color: txtSec),),
                ),
                data: (all) {
                  final results = _filter(all);

                  if (_query.isEmpty &&
                      _typeFilter == null &&
                      results.isEmpty) {
                    return _EmptyHint(isDark: isDark);
                  }

                  if (results.isEmpty) {
                    return _NoResults(
                        query: _query, isDark: isDark,);
                  }

                  return Column(
                    children: [
                      // Result summary bar
                      _ResultBar(
                        results: results,
                        typeFilter: _typeFilter,
                        txtSec: txtSec,
                        surfColor: surfColor,
                        bdrColor: bdrColor,
                      ),
                      // List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              0, 0, 0, 100,),
                          physics: const BouncingScrollPhysics(),
                          itemCount: results.length,
                          itemBuilder: (_, i) => _SearchTile(
                            tx: results[i],
                            isDark: isDark,
                            query: _query,
                            showDivider: i < results.length - 1,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TransactionDetailScreen(
                                        transaction: results[i],),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search header ────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String query;
  final bool isDark;
  final Color surfColor, bdrColor, txtPrim, txtHint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _SearchHeader({
    required this.ctrl, required this.focus, required this.query,
    required this.isDark, required this.surfColor, required this.bdrColor,
    required this.txtPrim, required this.txtHint,
    required this.onChanged, required this.onClear, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focus.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bdrColor),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isFocused
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : bdrColor,
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isFocused
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textHintDark
                            : AppColors.textHint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: TextStyle(color: txtPrim, fontSize: 14),
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: 'Kategori, catatan, nominal...',
                        hintStyle:
                            TextStyle(color: txtHint, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.textHintDark
                                : AppColors.textHint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result summary bar ───────────────────────────────────────────────────────

class _ResultBar extends StatelessWidget {
  final List<TransactionEntity> results;
  final String? typeFilter;
  final Color txtSec, surfColor, bdrColor;

  const _ResultBar({
    required this.results, required this.typeFilter,
    required this.txtSec, required this.surfColor, required this.bdrColor,
  });

  @override
  Widget build(BuildContext context) {
    final income = results
        .where((t) => !t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = results
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            '${results.length} transaksi',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: txtSec,
            ),
          ),
          const Spacer(),
          // Income chip
          if (typeFilter != 'expense' && income > 0)
            _AmountBadge(
              amount: income,
              isExpense: false,
            ),
          if (typeFilter == null && income > 0 && expense > 0)
            const SizedBox(width: 6),
          // Expense chip
          if (typeFilter != 'income' && expense > 0)
            _AmountBadge(
              amount: expense,
              isExpense: true,
            ),
        ],
      ),
    );
  }
}

class _AmountBadge extends StatelessWidget {
  final double amount;
  final bool isExpense;

  const _AmountBadge({required this.amount, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '${isExpense ? '−' : '+'} ${CurrencyFormatter.formatCompact(amount)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ─── Individual search tile ───────────────────────────────────────────────────

class _SearchTile extends StatelessWidget {
  final TransactionEntity tx;
  final bool isDark;
  final String query;
  final bool showDivider;
  final VoidCallback onTap;

  const _SearchTile({
    required this.tx, required this.isDark,
    required this.query, required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense   = tx.isExpense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final catColor    = CategoryUtils.getColor(tx.category);
    final catIcon     = CategoryUtils.getIcon(tx.category);
    final txtPrim     = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec      = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final divColor    = isDark ? AppColors.dividerDark       : AppColors.divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: catColor.withValues(alpha: 0.04),
            highlightColor: catColor.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          catColor.withValues(alpha: isDark ? 0.20 : 0.14),
                          catColor.withValues(alpha: isDark ? 0.10 : 0.07),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: catColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(catIcon, color: catColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 13),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightText(
                          text: tx.category,
                          query: query,
                          baseStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: txtPrim,
                            letterSpacing: -0.15,
                          ),
                          highlightStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.10),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tx.note?.isNotEmpty == true
                              ? tx.note!
                              : DateFormatter.formatRelative(tx.date),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: txtSec,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Amount + date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4,),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 
                              isDark ? 0.14 : 0.09,),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isExpense ? '−' : '+'} ${CurrencyFormatter.formatCompact(tx.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormatter.formatDayMonth(tx.date),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: txtSec.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 73),
            child: Divider(height: 1, color: divColor),
          ),
      ],
    );
  }
}

// ─── Type filter chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label, required this.icon,
    required this.isSelected, required this.isDark,
    required this.onTap, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    final surfColor   = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdrColor    = isDark ? AppColors.borderDark  : AppColors.border;
    final txtSec      = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kDurationFast,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.10) : surfColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : bdrColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? activeColor : txtSec,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : txtSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sort button ──────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final _SortOption current;
  final bool isDark;
  final ValueChanged<_SortOption> onChanged;

  const _SortButton({
    required this.current,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surfColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark  : AppColors.border;
    final txtPrim   = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final txtSec    = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<_SortOption>(
          context: context,
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.background,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(22)),),
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Urutkan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: txtPrim,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                ..._SortOption.values.map((s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: s == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: s == current
                              ? AppColors.primary
                              : txtPrim,
                        ),
                      ),
                      trailing: s == current
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, s),
                    ),),
              ],
            ),
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bdrColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 14, color: txtSec),
            const SizedBox(width: 5),
            Text(
              current.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: txtSec,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: txtSec,),
          ],
        ),
      ),
    );
  }
}

// ─── Highlight matching text ──────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text, required this.query,
    required this.baseStyle, required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: baseStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,);
    }
    final lower  = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx    = lower.indexOf(qLower);
    if (idx == -1) {
      return Text(text,
          style: baseStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        if (idx > 0)
          TextSpan(text: text.substring(0, idx), style: baseStyle),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlightStyle,
        ),
        if (idx + query.length < text.length)
          TextSpan(
            text: text.substring(idx + query.length),
            style: baseStyle,
          ),
      ],),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final bool isDark;
  const _EmptyHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final txtSec  = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.09),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.search_rounded,
                size: 32, color: AppColors.primary,),
          ),
          const SizedBox(height: 18),
          Text(
            'Cari Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: txtPrim,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Ketik nama kategori,\ncatatan, atau nominal',
            style: TextStyle(
              fontSize: 13,
              color: txtSec,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final bool isDark;
  const _NoResults({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final txtSec  = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textHint.withValues(alpha: 0.10),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: isDark
                  ? AppColors.textHintDark
                  : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tidak Ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: txtPrim,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tidak ada hasil untuk\n"$query"',
            style: TextStyle(
              fontSize: 13,
              color: txtSec,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer tile ─────────────────────────────────────────────────────────────

class _TileShimmer extends StatelessWidget {
  const _TileShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: 13),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 110, height: 12, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 72, height: 10, borderRadius: 5),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerBox(width: 76, height: 26, borderRadius: 8),
                  SizedBox(height: 6),
                  ShimmerBox(width: 36, height: 10, borderRadius: 5),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 57),
          child: Divider(height: 1, color: divColor),
        ),
      ],
    );
  }
}