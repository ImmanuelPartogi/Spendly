import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../domain/models/scanned_transaction_result.dart';
import '../../domain/services/ocr_parser_service.dart';
import '../../domain/services/ocr_service.dart';
import 'scan_review_screen.dart';

// ─── Model publik untuk dikembalikan ke pemanggil (backward-compat) ────────────

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

// ─── Scanner State ─────────────────────────────────────────────────────────────

enum _ScannerStep { select, scanning }

/// Status tiap gambar selama proses scan.
enum _ImageStatus { waiting, scanning, done, failed }

class _ImageItem {
  final XFile xfile;
  _ImageStatus status;
  ScannedTransactionResult? result;

  _ImageItem({required this.xfile, this.status = _ImageStatus.waiting});
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  /// Batas jumlah gambar yang memicu dialog peringatan (non-blocking).
  static const _warnThreshold = 20;

  final _picker = ImagePicker();
  final _images = <_ImageItem>[];

  _ScannerStep _step = _ScannerStep.select;
  int _scannedCount = 0;

  @override
  void dispose() {
    OcrService.dispose();
    super.dispose();
  }

  // ── Pick images ─────────────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _images.add(_ImageItem(xfile: picked)));
    await HapticUtils.selection();
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        _images.add(_ImageItem(xfile: x));
      }
    });
    await HapticUtils.selection();
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _clearAll() {
    setState(() {
      _images.clear();
      _scannedCount = 0;
      _step = _ScannerStep.select;
    });
  }

  // ── Start batch scan ────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    if (_images.isEmpty) return;

    // Peringatan untuk batch besar (> 20 gambar).
    if (_images.length > _warnThreshold) {
      final proceed = await _showBatchWarning(_images.length);
      if (!proceed) return;
    }

    setState(() {
      _step = _ScannerStep.scanning;
      _scannedCount = 0;
      for (final item in _images) {
        item.status = _ImageStatus.waiting;
        item.result = null;
      }
    });

    // Proses setiap gambar secara sekuensial.
    // Constraint 9: gambar yang gagal tidak pernah memblokir gambar berikutnya.
    for (var i = 0; i < _images.length; i++) {
      // Step 1: tandai sedang scan.
      if (mounted) setState(() => _images[i].status = _ImageStatus.scanning);

      try {
        final file = File(_images[i].xfile.path);

        // Step 2: panggil ML Kit.
        final rawText = await OcrService.extractText(file);

        // Step 3: jika teks kosong → hasil gagal.
        if (rawText.isEmpty) {
          if (mounted) {
            setState(() {
              _images[i].result = ScannedTransactionResult(
                source: null,
                type: ScannedDocumentType.unknown,
                amount: null,
                date: null,
                description: '',
                rawText: '',
                success: false,
                errorMessage:
                    'Teks tidak terdeteksi. Pastikan gambar cukup jelas.',
                imagePath: _images[i].xfile.path,
              );
              _images[i].status = _ImageStatus.failed;
              _scannedCount = i + 1;
            });
          }
          continue; // Step 7: lanjut ke gambar berikutnya.
        }

        // Step 4: parse teks.
        ScannedTransactionResult parsed;
        try {
          parsed = OcrParserService.parse(rawText,
              imagePath: _images[i].xfile.path);
        } catch (e) {
          // Step 5: parse gagal → hasil gagal.
          if (mounted) {
            setState(() {
              _images[i].result = ScannedTransactionResult(
                source: null,
                type: ScannedDocumentType.unknown,
                amount: null,
                date: null,
                description: '',
                rawText: rawText,
                success: false,
                errorMessage:
                    'Gagal memproses gambar ini. Coba lagi atau lewati.',
                imagePath: _images[i].xfile.path,
              );
              _images[i].status = _ImageStatus.failed;
              _scannedCount = i + 1;
            });
          }
          continue; // Step 7: lanjut ke gambar berikutnya.
        }

        // Step 6: simpan hasil.
        if (mounted) {
          setState(() {
            _images[i].result = parsed;
            _images[i].status =
                parsed.success ? _ImageStatus.done : _ImageStatus.failed;
            _scannedCount = i + 1;
          });
        }
      } catch (e) {
        // Error tak terduga — tetap lanjut ke gambar berikutnya.
        if (mounted) {
          setState(() {
            _images[i].result = ScannedTransactionResult(
              source: null,
              type: ScannedDocumentType.unknown,
              amount: null,
              date: null,
              description: '',
              rawText: '',
              success: false,
              errorMessage: 'Gagal memproses gambar ini. Coba lagi atau lewati.',
              imagePath: _images[i].xfile.path,
            );
            _images[i].status = _ImageStatus.failed;
            _scannedCount = i + 1;
          });
        }
      }
    }

    // Setelah selesai → navigasi ke layar review.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final reviewItems = _images
        .where((e) => e.result != null)
        .map((e) => ScanResultItem(
              result: e.result!,
              imagePath: e.xfile.path,
              isSelected: e.result!.success,
            ))
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            scanReviewProvider.overrideWith(
              (ref) => ScanReviewNotifier(reviewItems),
            ),
          ],
          child: const ScanReviewScreen(),
        ),
      ),
    );
  }

  /// Tampilkan dialog peringatan untuk batch besar.
  Future<bool> _showBatchWarning(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perhatian'),
        content: Text(
          'Anda memilih $count gambar. Proses scan mungkin membutuhkan '
          'waktu lebih lama. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _step != _ScannerStep.scanning,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Text(_appBarTitle()),
          leading: _step == _ScannerStep.scanning
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: _step == _ScannerStep.select && _images.isNotEmpty
              ? [
                  IconButton(
                    tooltip: 'Hapus Semua',
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    onPressed: _clearAll,
                  ),
                ]
              : null,
        ),
        body: _buildBody(),
      ),
    );
  }

  String _appBarTitle() {
    switch (_step) {
      case _ScannerStep.select:
        return 'Scan Struk / Slip Gaji';
      case _ScannerStep.scanning:
        return 'Memproses...';
    }
  }

  Widget _buildBody() {
    switch (_step) {
      case _ScannerStep.select:
        return _SelectStep(
          images: _images,
          onPickCamera: _pickFromCamera,
          onPickGallery: _pickFromGallery,
          onRemove: _removeImage,
          onScan: _startScan,
        );
      case _ScannerStep.scanning:
        return _ScanningStep(
          images: _images,
          scannedCount: _scannedCount,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Input Selection
// ─────────────────────────────────────────────────────────────────────────────

class _SelectStep extends StatelessWidget {
  final List<_ImageItem> images;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<int> onRemove;
  final VoidCallback onScan;

  const _SelectStep({
    required this.images,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Source buttons ──────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Ambil Foto',
                      onTap: onPickCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Pilih dari Galeri',
                      onTap: onPickGallery,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                if (images.isEmpty) ...[
                  const SizedBox(height: 8),
                  _EmptyHint(txtSec: txtSec),
                ] else ...[
                  Row(children: [
                    Text(
                      '${images.length} gambar dipilih',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: txtSec,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onPickGallery,
                      child: Text(
                        '+ Tambah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: images.length,
                    itemBuilder: (_, i) => _ImageThumbCard(
                      item: images[i],
                      index: i,
                      onRemove: () => onRemove(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Scan button ─────────────────────────────────────────────────────
        if (images.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.background,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.document_scanner_rounded, size: 20),
                label: Text('Scan Semua (${images.length} gambar)'),
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final Color txtSec;
  const _EmptyHint({required this.txtSec});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('📸', 'Foto / pilih struk atau slip gaji'),
      ('🔍', 'ML Kit membaca teks tiap gambar'),
      ('✅', 'Tinjau hasil & tambah transaksi sekaligus'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded,
                size: 32, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Pilih struk atau slip gaji untuk dipindai',
            style: TextStyle(color: txtSec, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),
        Text('Cara Kerja', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.value.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.value.$2,
                      style: TextStyle(fontSize: 13, color: txtSec)),
                ),
              ]),
            )),
      ],
    );
  }
}

class _ImageThumbCard extends StatelessWidget {
  final _ImageItem item;
  final int index;
  final VoidCallback onRemove;

  const _ImageThumbCard({
    required this.item,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(item.xfile.path),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      Positioned(
        left: 6,
        bottom: 6,
        right: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.xfile.name,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Scanning Progress
// ─────────────────────────────────────────────────────────────────────────────

class _ScanningStep extends StatelessWidget {
  final List<_ImageItem> images;
  final int scannedCount;

  const _ScanningStep({
    required this.images,
    required this.scannedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = images.isEmpty ? 0.0 : scannedCount / images.length;

    return Column(children: [
      // Progress bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 10),
              Text(
                '$scannedCount / ${images.length} selesai',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.surfaceDark : AppColors.surface,
              ),
            ),
          ],
        ),
      ),

      // List
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = images[i];
            return _ScanningRow(item: item, index: i + 1);
          },
        ),
      ),
    ]);
  }
}

class _ScanningRow extends StatelessWidget {
  final _ImageItem item;
  final int index;

  const _ScanningRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdrColor),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(item.xfile.path),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.xfile.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _StatusChip(status: item.status),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _ImageStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _ImageStatus.waiting:
        return _chip('Menunggu', AppColors.textHint, Colors.transparent);
      case _ImageStatus.scanning:
        return _chip('Memindai...', AppColors.primary,
            AppColors.primary.withValues(alpha: 0.1));
      case _ImageStatus.done:
        return _chip('Selesai ✓', AppColors.income,
            AppColors.income.withValues(alpha: 0.1));
      case _ImageStatus.failed:
        return _chip('Gagal ✗', AppColors.error,
            AppColors.error.withValues(alpha: 0.1));
    }
  }

  Widget _chip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == _ImageStatus.scanning)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: fg,
                ),
              ),
            ),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              )),
        ],
      ),
    );
  }
}