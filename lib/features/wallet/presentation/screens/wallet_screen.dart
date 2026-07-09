import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/wallet_entity.dart';
import 'add_wallet_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dompet Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddWalletScreen()),
            ),
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.expense,),
              const SizedBox(height: 12),
              Text('Gagal memuat dompet', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('$e',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,),),
            ],
          ),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👛', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Belum ada dompet',
                      style: TextStyle(color: AppColors.textSecondary),),
                ],
              ),
            );
          }

          final total = wallets.fold(0.0, (s, w) => s + w.balance);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Total Saldo card ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Saldo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${wallets.length} dompet aktif',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Wallet list ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _WalletCard(
                      wallet: wallets[i],
                      onDelete: () => _confirmDelete(context, ref, wallets[i]),
                    ),
                    childCount: wallets.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: walletsAsync.maybeWhen(
        data: (wallets) => wallets.length >= 2
            ? FloatingActionButton.extended(
                onPressed: () => _showTransferSheet(context, wallets),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.swap_horiz_rounded,
                    color: Colors.white,),
                label: const Text('Transfer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,),),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _showTransferSheet(
      BuildContext context, List<WalletEntity> wallets,) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferSheet(wallets: wallets),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, WalletEntity wallet,) {
    if (wallet.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dompet utama tidak bisa dihapus')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text(
            '"${wallet.name}" akan dihapus permanen beserta semua riwayat transaksinya.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(deleteWalletUseCaseProvider).call(wallet.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback onDelete;
  const _WalletCard({required this.wallet, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: wallet.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(wallet.type.emoji,
                  style: const TextStyle(fontSize: 22),),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      wallet.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (wallet.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.type.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(wallet.balance),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: wallet.balance >= 0
                  ? AppColors.textPrimary
                  : AppColors.expense,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus',
                    style: TextStyle(color: AppColors.expense),),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TransferSheet extends ConsumerStatefulWidget {
  final List<WalletEntity> wallets;
  const _TransferSheet({required this.wallets});

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  WalletEntity? _from;
  WalletEntity? _to;
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    setState(() => _errorMsg = null);

    if (_from == null || _to == null) {
      setState(() => _errorMsg = 'Pilih wallet asal dan tujuan');
      return;
    }
    if (_from!.id == _to!.id) {
      setState(() => _errorMsg = 'Pilih wallet yang berbeda');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMsg = 'Masukkan jumlah yang valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(transferFundsUseCaseProvider).call(
            fromId: _from!.id,
            toId: _to!.id,
            amount: amount,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Transfer ${CurrencyFormatter.format(amount)} berhasil ✓',),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),),
              ),
            ),
            const SizedBox(height: 20),
            Text('Transfer Antar Dompet',
                style: Theme.of(context).textTheme.headlineSmall,),
            const SizedBox(height: 20),
            _WalletDropdown(
              label: 'Dari',
              wallets: widget.wallets,
              value: _from,
              onChanged: (w) => setState(() => _from = w),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: AppColors.primary, size: 18,),
              ),
            ),
            const SizedBox(height: 12),
            _WalletDropdown(
              label: 'Ke',
              wallets: widget.wallets,
              value: _to,
              onChanged: (w) => setState(() => _to = w),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: const TextStyle(
                    color: AppColors.expense, fontSize: 12,),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _transfer,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2,),
                      )
                    : const Text('Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletDropdown extends StatelessWidget {
  final String label;
  final List<WalletEntity> wallets;
  final WalletEntity? value;
  final ValueChanged<WalletEntity?> onChanged;

  const _WalletDropdown({
    required this.label,
    required this.wallets,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<WalletEntity>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: wallets
          .map((w) => DropdownMenuItem(
                value: w,
                child: Row(
                  children: [
                    Text(w.type.emoji),
                    const SizedBox(width: 8),
                    Text(w.name),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatCompact(w.balance),
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,),
                    ),
                  ],
                ),
              ),)
          .toList(),
      onChanged: onChanged,
    );
  }
}