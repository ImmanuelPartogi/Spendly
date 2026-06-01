import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _format = 'pdf'; // 'pdf' | 'csv'
  String _period = 'month'; // 'month' | 'range' | '3months' | 'year'
  DateTimeRange? _customRange;
  bool _isLoading = false;

  static const _periods = [
    _Period('Bulan ini', 'month', Icons.calendar_month_rounded),
    _Period('3 Bulan', '3months', Icons.date_range_rounded),
    _Period('Tahun ini', 'year', Icons.calendar_today_rounded),
_Period('Kustom', 'range', Icons.tune_rounded),
  ];

  Future<void> _export() async {
    setState(() => _isLoading = true);
    try {
      // TODO: fetch transactions from provider based on period
      final transactions = <dynamic>[];

      if (_format == 'csv') {
        final file = await ExportService.exportToCsv(
          transactions.cast(),
          filename: 'spendly_${DateTime.now().millisecondsSinceEpoch}',
        );
        await ExportService.shareFile(file,
            subject: 'Spendly Export CSV');
      } else {
        final file = await ExportService.exportToPdf(
          transactions.cast(),
          monthLabel: _getPeriodLabel(),
          filename: 'spendly_${DateTime.now().millisecondsSinceEpoch}',
        );
        await ExportService.shareFile(file,
            subject: 'Spendly Laporan PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _customRange = range);
    }
  }

  String _getPeriodLabel() {
    switch (_period) {
      case 'month':
        final n = DateTime.now();
        return '${_month(n.month)} ${n.year}';
      case '3months':
        return '3 Bulan Terakhir';
      case 'year':
        return 'Tahun ${DateTime.now().year}';
      case 'range':
        if (_customRange != null) {
          return '${_fmt(_customRange!.start)} – ${_fmt(_customRange!.end)}';
        }
        return 'Custom';
      default:
        return '';
    }
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
  String _month(int m) => [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
appBar: AppBar(title: const Text('Ekspor Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Format selector ───────────────────────────────────────────
            Text('Format Export',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormatCard(
                    label: 'PDF',
                    subtitle: 'Laporan siap cetak',
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFFF4B6E),
                    selected: _format == 'pdf',
                    onTap: () => setState(() => _format = 'pdf'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatCard(
                    label: 'CSV',
                    subtitle: 'Buka di Excel',
                    icon: Icons.table_chart_rounded,
                    color: const Color(0xFF00C48C),
                    selected: _format == 'csv',
                    onTap: () => setState(() => _format = 'csv'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Period selector ───────────────────────────────────────────
            Text('Periode',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3,
              children: _periods.map((p) {
                final isSelected = _period == p.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => _period = p.value);
                    if (p.value == 'range') _pickCustomRange();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(p.icon,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_period == 'range' && _customRange != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_fmt(_customRange!.start)} — ${_fmt(_customRange!.end)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickCustomRange,
                      child: const Text('Ubah',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Preview info ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Info Export',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                      label: 'Format', value: _format.toUpperCase()),
                  _InfoRow(
                      label: 'Periode', value: _getPeriodLabel()),
                  const _InfoRow(
                      label: 'Isi', value: 'Semua transaksi'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Export button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _export,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(_isLoading
                    ? 'Mengekspor…'
                    : 'Ekspor & Bagikan'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
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

class _Period {
  final String label;
  final String value;
  final IconData icon;
  const _Period(this.label, this.value, this.icon);
}

class _FormatCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? color : AppColors.textSecondary,
                size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}