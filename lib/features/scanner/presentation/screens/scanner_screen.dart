import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/services/ocr_service.dart';

// ─── Model publik untuk dikembalikan ke pemanggil ─────────────────────────────

class ScanReturn {
  final double? total;
  final String? merchant;
  final DateTime date;

  const ScanReturn({
    required this.total,
    required this.merchant,
    required this.date,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  bool _isProcessing = false;
  _ScanResult? _result;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _isProcessing = true;
      _result = null;
    });

    try {
      final text = await OcrService.extractText(_image!);
      final total = OcrService.extractTotal(text);
      final date = OcrService.extractDate(text);
      final merchant = OcrService.extractMerchant(text);

      setState(() {
        _result = _ScanResult(
          total: total,
          date: date ?? DateTime.now(),
          merchant: merchant,
          rawText: text,
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    }
  }

  void _proceed() {
    if (_result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReviewScreen(result: _result!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text('Scan Struk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ────────────────────────────────────────────────
            GestureDetector(
              onTap: _showSourcePicker,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: surfColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _image != null
                        ? AppColors.primary.withOpacity(0.4)
                        : bdrColor,
                    width: 1.5,
                  ),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text('Tap untuk foto atau pilih gambar struk',
                              style: TextStyle(color: txtSec, fontSize: 14),
                              textAlign: TextAlign.center),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_image!,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover),
                          ),
                          if (_isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        color: Colors.white),
                                    SizedBox(height: 12),
                                    Text('Memproses struk…',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showSourcePicker,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Scan result ───────────────────────────────────────────────
            if (_result != null) ...[
              Text('Hasil Scan',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bdrColor),
                ),
                child: Column(
                  children: [
                    _ResultRow(
                      icon: Icons.store_rounded,
                      label: 'Nama Toko',
                      value: _result!.merchant ?? 'Tidak terdeteksi',
                      isDetected: _result!.merchant != null,
                    ),
                    const Divider(height: 16),
                    _ResultRow(
                      icon: Icons.payments_rounded,
                      label: 'Total',
                      value: _result!.total != null
                          ? CurrencyFormatter.format(_result!.total!)
                          : 'Tidak terdeteksi',
                      isDetected: _result!.total != null,
                      highlight: true,
                    ),
                    const Divider(height: 16),
                    _ResultRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal',
                      value:
                          '${_result!.date.day}/${_result!.date.month}/${_result!.date.year}',
                      isDetected: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Kamu bisa mengedit semua detail sebelum menyimpan.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.8)))),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _proceed,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Lanjut & Konfirmasi'),
                ),
              ),
            ],

            // ── Empty state ───────────────────────────────────────────────
            if (_image == null && !_isProcessing) ...[
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: _SourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Ambil Foto',
                        onTap: () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(
                    child: _SourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Dari Galeri',
                        onTap: () => _pickImage(ImageSource.gallery))),
              ]),
              const SizedBox(height: 24),
              const _HowItWorks(),
            ],
          ],
        ),
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review Screen ────────────────────────────────────────────────────────────

class _ReviewScreen extends StatefulWidget {
  final _ScanResult result;
  const _ReviewScreen({required this.result});

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  late final TextEditingController _amountCtrl;
  late DateTime _date;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.result.total?.toStringAsFixed(0) ?? '',
    );
    _date = widget.result.date;
    _note = widget.result.merchant ?? '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final total = double.tryParse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    final returnData = ScanReturn(
      total: total,
      merchant: _note.trim().isEmpty ? null : _note.trim(),
      date: _date,
    );
    // Pop ReviewScreen
    Navigator.pop(context);
    // Pop ScannerScreen dengan membawa data
    Navigator.pop(context, returnData);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text('Konfirmasi Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.income, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Struk berhasil discan. Periksa sebelum melanjutkan.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.income.withOpacity(0.9),
                            fontWeight: FontWeight.w500))),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Nominal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: 'Rp '),
            ),
            const SizedBox(height: 16),
            Text('Catatan / Nama Toko',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _note,
              onChanged: (v) => _note = v,
              decoration:
                  const InputDecoration(hintText: 'Nama toko atau catatan'),
            ),
            const SizedBox(height: 16),
            Text('Tanggal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bdrColor),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirm,
                child: const Text('Gunakan Data Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets & models ──────────────────────────────────────────────────

class _ScanResult {
  final double? total;
  final DateTime date;
  final String? merchant;
  final String rawText;

  const _ScanResult(
      {required this.total,
      required this.date,
      required this.merchant,
      required this.rawText});
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDetected, highlight;

  const _ResultRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDetected,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon,
          size: 16, color: isDetected ? AppColors.primary : AppColors.textHint),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value,
          style: TextStyle(
            fontSize: highlight ? 16 : 13,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: isDetected
                ? (highlight ? AppColors.primary : AppColors.textPrimary)
                : AppColors.textHint,
          )),
    ]);
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('📸', 'Foto struk belanja'),
      ('🔍', 'ML Kit membaca teks secara otomatis'),
      ('✅', 'Review dan data terisi otomatis'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Kerja', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary))),
                ),
                const SizedBox(width: 10),
                Text(e.value.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(e.value.$2,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary))),
              ]),
            )),
      ],
    );
  }
}
