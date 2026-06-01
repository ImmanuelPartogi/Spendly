import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/transaction_entity.dart';
import 'add_transaction_screen.dart';

bool _isLocked(TransactionEntity tx) {
  final age = DateTime.now().difference(tx.createdAt).inDays;
  return age >= 3;
}

class TransactionDetailScreen extends ConsumerWidget {
  final TransactionEntity transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final cardColor = isDark ? AppColors.cardDark       : AppColors.card;
    final bdrColor  = isDark ? AppColors.borderDark     : AppColors.border;
    final divColor  = isDark ? AppColors.dividerDark    : AppColors.divider;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final isExpense = transaction.isExpense;
    final color     = isExpense ? AppColors.expense : AppColors.income;
    final catColor  = CategoryUtils.getColor(transaction.category);
    final locked    = _isLocked(transaction);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Header ────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: color,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Edit — disabled saat locked
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(locked ? 0.08 : 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: locked
                              ? Colors.white30
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                      onPressed: locked ? null : () => _edit(context),
                    ),
                  ),
                  // Delete / Lock
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                              locked ? 0.08 : 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          locked
                              ? Icons.lock_rounded
                              : Icons.delete_outline_rounded,
                          color: locked
                              ? Colors.white38
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                      onPressed: locked
                          ? () => _showLockedInfo(context)
                          : () => _confirmDelete(context, ref),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroBackground(
                    color: color,
                    catColor: catColor,
                    catIcon: CategoryUtils.getIcon(transaction.category),
                    category: transaction.category,
                    amount: CurrencyFormatter.format(transaction.amount),
                    isExpense: isExpense,
                    isLocked: locked,
                  ),
                ),
              ),

              // ── Detail card ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _DetailCard(
                    transaction: transaction,
                    cardColor: cardColor,
                    bdrColor: bdrColor,
                    divColor: divColor,
                    txtPrim: txtPrim,
                    txtSec: txtSec,
                    catColor: catColor,
                    color: color,
                    isDark: isDark,
                    isExpense: isExpense,
                    isLocked: locked,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(existing: transaction),
    );
  }

  void _showLockedInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Transaksi > 3 hari tidak dapat dihapus untuk menjaga akurasi data'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Transaksi?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'Transaksi ini akan dihapus permanen dan saldo wallet akan dikembalikan.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(deleteTransactionUseCaseProvider)
                      .call(transaction.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi dihapus')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero background ──────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  final Color color;
  final Color catColor;
  final IconData catIcon;
  final String category;
  final String amount;
  final bool isExpense;
  final bool isLocked;

  const _HeroBackground({
    required this.color,
    required this.catColor,
    required this.catIcon,
    required this.category,
    required this.amount,
    required this.isExpense,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Content — fix overflow: hapus top padding 56, pakai SafeArea
          // mainAxisAlignment.end sudah push konten ke bawah
          SafeArea(
            child: Padding(
              // Hapus top:56 → jadi 0, bottom diperbesar jadi 28
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Category icon — ukuran dikecilkan dari 54 → 46
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Center(
                      child: Icon(catIcon, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(height: 8), // dikurangi dari 10

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpense
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isExpense ? 'Pengeluaran' : 'Pemasukan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5), // dikurangi dari 6

                  // Amount
                  Text(
                    '${isExpense ? '− ' : '+ '}$amount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28, // dikurangi dari 30
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Locked badge — tambah padding bawah eksplisit
                  if (isLocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              color: Colors.white70, size: 11),
                          SizedBox(width: 5),
                          Text(
                            'Terkunci · lebih dari 3 hari',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail card ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final TransactionEntity transaction;
  final Color cardColor, bdrColor, divColor;
  final Color txtPrim, txtSec;
  final Color catColor, color;
  final bool isDark, isExpense, isLocked;

  const _DetailCard({
    required this.transaction,
    required this.cardColor,
    required this.bdrColor,
    required this.divColor,
    required this.txtPrim,
    required this.txtSec,
    required this.catColor,
    required this.color,
    required this.isDark,
    required this.isExpense,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdrColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _Row(
            icon: Icons.category_rounded,
            iconColor: catColor,
            label: 'Kategori',
            value: transaction.category,
            valueColor: catColor,
            isDark: isDark,
          ),
          _Divider(color: divColor),
          _Row(
            icon: isExpense
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            iconColor: color,
            label: 'Tipe',
            value: isExpense ? 'Pengeluaran' : 'Pemasukan',
            valueColor: color,
            isDark: isDark,
          ),
          _Divider(color: divColor),
          _Row(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            label: 'Tanggal',
            value: _formatDate(transaction.date),
            isDark: isDark,
          ),
          _Divider(color: divColor),
          _Row(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.accentTeal,
            label: 'Waktu',
            value: _formatTime(transaction.date),
            isDark: isDark,
          ),
          if (transaction.note?.isNotEmpty == true) ...[
            _Divider(color: divColor),
            _Row(
              icon: Icons.edit_note_rounded,
              iconColor: AppColors.accentOrange,
              label: 'Catatan',
              value: transaction.note!,
              isDark: isDark,
            ),
          ],
          if (isLocked) ...[
            _Divider(color: divColor),
            _LockedRow(txtSec: txtSec),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: color),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _Row({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Icon(icon, size: 15, color: iconColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: txtSec,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? txtPrim,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedRow extends StatelessWidget {
  final Color txtSec;
  const _LockedRow({required this.txtSec});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(Icons.lock_outline_rounded,
                  size: 15, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Transaksi ini sudah > 3 hari dan tidak dapat dihapus.',
              style: TextStyle(
                  fontSize: 12.5, color: txtSec, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}