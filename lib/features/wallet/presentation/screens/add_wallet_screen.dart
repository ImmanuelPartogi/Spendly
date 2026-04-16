import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/wallet_entity.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  WalletType _selectedType = WalletType.cash;
  Color _selectedColor = const Color(0xFF3A7AFE);
  WalletPreset? _selectedPreset;
  bool _isLoading = false;

  final _colors = [
    const Color(0xFF3A7AFE),
    const Color(0xFF00C48C),
    const Color(0xFFFF4B6E),
    const Color(0xFF7C5CBF),
    const Color(0xFFFF7D45),
    const Color(0xFFFFB020),
    const Color(0xFF00C9B1),
    const Color(0xFF0066AE),
  ];

  void _applyPreset(WalletPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _nameCtrl.text = preset.name;
      _selectedType = preset.type;
      _selectedColor = preset.color;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama wallet tidak boleh kosong')),
      );
      return;
    }

    // ✅ Parse saldo awal (boleh kosong → 0)
    final rawBalance = _balanceCtrl.text.trim().replaceAll('.', '').replaceAll(',', '');
    final initialBalance = double.tryParse(rawBalance) ?? 0.0;

    setState(() => _isLoading = true);
    try {
      // ✅ Buat entity wallet baru
      final entity = WalletEntity(
        id: const Uuid().v4(),
        name: name,
        balance: initialBalance,
        type: _selectedType,
        color: _selectedColor,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // ✅ Simpan ke Drift + upload ke Firebase (via AddWalletUseCase)
      await ref.read(addWalletUseCaseProvider).call(entity);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan wallet: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tambah Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preset chips ─────────────────────────────────────────────────
            Text('Pilih Cepat',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WalletPreset.all.map((p) {
                final isSelected = _selectedPreset?.name == p.name;
                return GestureDetector(
                  onTap: () => _applyPreset(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? p.color.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? p.color : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? p.color
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Name ─────────────────────────────────────────────────────────
            Text('Nama Wallet',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: BCA Tabungan',
              ),
            ),
            const SizedBox(height: 20),

            // ── Initial balance ───────────────────────────────────────────────
            Text('Saldo Awal',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 20),

            // ── Type ─────────────────────────────────────────────────────────
            Text('Tipe', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WalletType.values.map((t) {
                final isSelected = t == _selectedType;
                return ChoiceChip(
                  label: Text('${t.emoji} ${t.label}'),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedType = t),
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
            const SizedBox(height: 20),

            // ── Color ─────────────────────────────────────────────────────────
            Text('Warna', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: _colors.map((c) {
                final isSelected = c.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // ── Save button ───────────────────────────────────────────────────
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
                    : const Text('Simpan Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}