import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../scanner/presentation/screens/scanner_screen.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddTransactionSheet — Bottom sheet tambah / edit transaksi
// ─────────────────────────────────────────────────────────────────────────────

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionEntity? existing;
  const AddTransactionSheet({super.key, this.existing});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _amountCtrl  = TextEditingController();
  final _noteCtrl    = TextEditingController();
  final _amountFocus = FocusNode();

  String   _selectedCategory = AppConstants.expenseCategories.first;
  DateTime _selectedDate     = DateTime.now();
  bool     _isLoading        = false;
  String   _type             = AppConstants.typeExpense;

  static const _quickAmounts = <int>[
    10_000, 25_000, 50_000, 100_000, 200_000, 500_000,
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2, vsync: this,
      initialIndex: widget.existing?.isExpense == false ? 1 : 0,
    );
    _tabCtrl.addListener(_onTabChange);
    _amountFocus.addListener(() => setState(() {}));

    if (widget.existing != null) {
      final tx = widget.existing!;
      _amountCtrl.text  = ThousandSeparatorInputFormatter.format(tx.amount);
      _noteCtrl.text    = tx.note ?? '';
      _selectedCategory = tx.category;
      _selectedDate     = tx.date;
      _type             = tx.type;
    }
  }

  void _onTabChange() {
    if (_tabCtrl.indexIsChanging) return;
    setState(() {
      _type = _tabCtrl.index == 0
          ? AppConstants.typeExpense
          : AppConstants.typeIncome;
      _selectedCategory = _type == AppConstants.typeExpense
          ? AppConstants.expenseCategories.first
          : AppConstants.incomeCategories.first;
    });
  }

  @override
  void dispose() {
    _tabCtrl
      ..removeListener(_onTabChange)
      ..dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  List<String> get _categories => _type == AppConstants.typeExpense
      ? AppConstants.expenseCategories
      : AppConstants.incomeCategories;

  bool get _isExpense => _type == AppConstants.typeExpense;

  // ── Pindai struk ──────────────────────────────────────────────────────────
  Future<void> _openScanner() async {
    final result = await Navigator.push<ScanReturn>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.total != null) {
        _amountCtrl.text =
            ThousandSeparatorInputFormatter.format(result.total!);
      }
      if (result.merchant != null) _noteCtrl.text = result.merchant!;
      _selectedDate = result.date;
      _type = AppConstants.typeExpense;
      _tabCtrl.animateTo(0);
      _selectedCategory = AppConstants.expenseCategories.first;
    });
    await HapticUtils.success();
  }

  // ── Simpan ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final amount = ThousandSeparatorInputFormatter.parse(_amountCtrl.text);
    if (amount <= 0) {
      await HapticUtils.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah yang valid')),);
      return;
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final walletDao = ref.read(walletDaoProvider);
      var wallets = await walletDao.getAllWallets();

      if (wallets.isEmpty) {
        await walletDao.insertWallet(WalletsCompanion.insert(
          id: const Uuid().v4(),
          name: 'Tunai',
          type: const Value('cash'),
          colorValue: const Value(0xFF00C48C),
          isDefault: const Value(true),
        ),);
        wallets = await walletDao.getAllWallets();
      }

      final noteText =
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

      if (widget.existing == null) {
        final entity = TransactionModel.create(
          walletId: wallets.first.id,
          amount: amount,
          type: _type,
          category: _selectedCategory,
          note: noteText,
          date: _selectedDate,
        );
        await ref.read(addTransactionUseCaseProvider).call(entity);
      } else {
        final updated = widget.existing!.copyWith(
          amount: amount,
          type: _type,
          category: _selectedCategory,
          note: noteText,
          date: _selectedDate,
        );
        await ref
            .read(updateTransactionUseCaseProvider)
            .call(widget.existing!.id, updated);
      }

      await HapticUtils.success();
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('[AddTransaction] Error: $e');
      debugPrint('[AddTransaction] Stack: $stack');
      await HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e')),);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Pilih tanggal ─────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await HapticUtils.light();
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.cardDark,
                  onSurface: AppColors.textPrimaryDark,)
              : const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.card,
                  onSurface: AppColors.textPrimary,),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,),),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor   = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor    = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim     = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec      = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtHint     = isDark ? AppColors.textHintDark      : AppColors.textHint;
    final accentColor = _isExpense ? AppColors.expense : AppColors.income;
    final bottomPad   = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
          blurRadius: 32, offset: const Offset(0, -4),
        ),],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              _DragHandle(isDark: isDark),

              // ── Header ───────────────────────────────────────────────────
              _SheetHeader(
                existing: widget.existing,
                isExpense: _isExpense,
                isDark: isDark,
                surfColor: surfColor,
                bdrColor: bdrColor,
                txtPrim: txtPrim,
                txtSec: txtSec,
                onClose: () => Navigator.pop(context),
                onScan: widget.existing == null ? _openScanner : null,
              ),
              const SizedBox(height: 16),

              // ── Pemilih tab ───────────────────────────────────────────────
              _TabSwitcher(
                tabCtrl: _tabCtrl,
                accentColor: accentColor,
                surfColor: surfColor,
                bdrColor: bdrColor,
                txtSec: txtSec,
              ),
              const SizedBox(height: 20),

              // ── Kolom jumlah ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4,),
                  decoration: BoxDecoration(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.06)
                        : accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _amountFocus.hasFocus
                          ? accentColor.withValues(alpha: 0.6)
                          : accentColor.withValues(alpha: 0.22),
                      width: _amountFocus.hasFocus ? 1.5 : 1,
                    ),
                    boxShadow: _amountFocus.hasFocus
                        ? [BoxShadow(
                            color: accentColor.withValues(alpha: 0.12),
                            blurRadius: 14,),]
                        : null,
                  ),
                  child: Row(children: [
                    Text('Rp', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: accentColor, letterSpacing: -0.2,
                    ),),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        focusNode: _amountFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandSeparatorInputFormatter()],
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: accentColor, letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: accentColor.withValues(alpha: 0.25),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_amountCtrl.text.isNotEmpty)
                      _AmountBadge(
                        amount: ThousandSeparatorInputFormatter
                            .parse(_amountCtrl.text),
                        color: accentColor,
                      ),
                  ],),
                ),
              ),
              const SizedBox(height: 16),

              // ── Nominal cepat ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Nominal Cepat', txtSec),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7, runSpacing: 7,
                      children: _quickAmounts.map((amount) {
                        final formatted = ThousandSeparatorInputFormatter
                            .format(amount.toDouble());
                        final selected = _amountCtrl.text == formatted;
                        return GestureDetector(
                          onTap: () async {
                            await HapticUtils.selection();
                            setState(() => _amountCtrl.text = formatted);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 8,),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(colors: [
                                      accentColor.withValues(alpha: 0.15),
                                      accentColor.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,)
                                  : null,
                              color: selected ? null : surfColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? accentColor.withValues(alpha: 0.5)
                                    : bdrColor,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              CurrencyFormatter.formatCompact(amount.toDouble()),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? accentColor : txtSec,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Kategori ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Kategori', txtSec),
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
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat      = _categories[i];
                        final selected = cat == _selectedCategory;
                        final catColor = CategoryUtils.getColor(cat);
                        return GestureDetector(
                          onTap: () async {
                            await HapticUtils.selection();
                            setState(() => _selectedCategory = cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6,),
                            decoration: BoxDecoration(
                              color: selected
                                  ? catColor.withValues(alpha: 
                                      isDark ? 0.18 : 0.12,)
                                  : surfColor,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: selected
                                    ? catColor.withValues(alpha: 0.55)
                                    : bdrColor,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CategoryUtils.getIcon(cat),
                                    size: 15,
                                    color: selected ? catColor : txtSec,),
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
              const SizedBox(height: 18),

              // ── Catatan + Tanggal ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surfColor,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: bdrColor),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 12),
                        Icon(Icons.edit_note_rounded, size: 18, color: txtSec),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            style: TextStyle(color: txtPrim, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Tambah catatan...',
                              hintStyle:
                                  TextStyle(color: txtHint, fontSize: 13.5),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              fillColor: Colors.transparent,
                              filled: false,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13,),
                      decoration: BoxDecoration(
                        color: surfColor,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: bdrColor),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 15, color: txtSec,),
                        const SizedBox(width: 7),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: txtPrim,
                          ),
                        ),
                      ],),
                    ),
                  ),
                ],),
              ),
              const SizedBox(height: 22),

              // ── Tombol simpan ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isLoading
                    ? Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5,),
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
                                accentColor,
                                Color.lerp(accentColor, Colors.white, 0.12)!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),],
                          ),
                          child: Center(child: Text(
                            widget.existing == null
                                ? 'Simpan Transaksi'
                                : 'Perbarui Transaksi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),),
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
// Sub-widget (dipisah untuk kode yang bersih)
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: isDark ? AppColors.borderDark : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final TransactionEntity? existing;
  final bool isExpense, isDark;
  final Color surfColor, bdrColor, txtPrim, txtSec;
  final VoidCallback onClose;
  final VoidCallback? onScan;

  const _SheetHeader({
    required this.existing,
    required this.isExpense,
    required this.isDark,
    required this.surfColor,
    required this.bdrColor,
    required this.txtPrim,
    required this.txtSec,
    required this.onClose,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            existing == null ? 'Tambah Transaksi' : 'Ubah Transaksi',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: txtPrim, letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isExpense ? 'Catat pengeluaran' : 'Catat pemasukan',
            style: TextStyle(fontSize: 12, color: txtSec),
          ),
        ],),
        const Spacer(),

        // Tombol pindai (hanya untuk transaksi baru)
        if (onScan != null) ...[
          GestureDetector(
            onTap: onScan,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.document_scanner_rounded,
                      color: AppColors.primary, size: 16,),
                  SizedBox(width: 5),
                  Text('Pindai', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),),
                ],
              ),
            ),
          ),
        ],

        // Tombol tutup
        IconButton(
          onPressed: onClose,
          icon: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: surfColor,
              shape: BoxShape.circle,
              border: Border.all(color: bdrColor),
            ),
            child: Icon(Icons.close_rounded, color: txtSec, size: 16),
          ),
        ),
      ],),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final TabController tabCtrl;
  final Color accentColor, surfColor, bdrColor, txtSec;

  const _TabSwitcher({
    required this.tabCtrl,
    required this.accentColor,
    required this.surfColor,
    required this.bdrColor,
    required this.txtSec,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48, padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdrColor),
        ),
        child: TabBar(
          controller: tabCtrl,
          onTap: (_) => HapticUtils.selection(),
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                Color.lerp(accentColor, Colors.white, 0.1)!,
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: accentColor.withValues(alpha: 0.28),
              blurRadius: 10, offset: const Offset(0, 3),
            ),],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: txtSec,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13.5,),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 13.5,),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
    );
  }
}

class _AmountBadge extends StatelessWidget {
  final double amount;
  final Color color;
  const _AmountBadge({required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        CurrencyFormatter.formatCompact(amount),
        style: TextStyle(
          fontSize: 10.5,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      fontSize: 11.5, fontWeight: FontWeight.w600,
      color: color, letterSpacing: 0.3,
    ),);
  }
}