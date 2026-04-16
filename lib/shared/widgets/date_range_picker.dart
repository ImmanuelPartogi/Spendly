import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SpendlyDateRange {
  final DateTime start;
  final DateTime end;
  final String   label;
  const SpendlyDateRange({
    required this.start, required this.end, required this.label,
  });
}

class _Preset {
  final String label;
  final SpendlyDateRange Function() builder;
  const _Preset(this.label, this.builder);
}

class SpendlyDateRangePicker extends StatefulWidget {
  final SpendlyDateRange? initial;
  const SpendlyDateRangePicker({super.key, this.initial});

  static Future<SpendlyDateRange?> show(BuildContext context,
      {SpendlyDateRange? initial}) {
    return showModalBottomSheet<SpendlyDateRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpendlyDateRangePicker(initial: initial),
    );
  }

  @override
  State<SpendlyDateRangePicker> createState() =>
      _SpendlyDateRangePickerState();
}

class _SpendlyDateRangePickerState extends State<SpendlyDateRangePicker> {
  late DateTime _start;
  late DateTime _end;
  String _selectedPreset = '';

  static final _presets = <_Preset>[
    _Preset('Minggu ini', () {
      final now   = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      return SpendlyDateRange(
          start: DateTime(start.year, start.month, start.day),
          end: now, label: 'Minggu ini');
    }),
    _Preset('Bulan ini', () {
      final now = DateTime.now();
      return SpendlyDateRange(
          start: DateTime(now.year, now.month, 1), end: now, label: 'Bulan ini');
    }),
    _Preset('3 Bulan', () {
      final now = DateTime.now();
      return SpendlyDateRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now, label: '3 Bulan Terakhir');
    }),
    _Preset('Tahun ini', () {
      final now = DateTime.now();
      return SpendlyDateRange(
          start: DateTime(now.year, 1, 1), end: now,
          label: 'Tahun ${now.year}');
    }),
    _Preset('Bulan lalu', () {
      final now  = DateTime.now();
      final first = DateTime(now.year, now.month - 1, 1);
      final last  = DateTime(now.year, now.month, 0);
      return SpendlyDateRange(start: first, end: last, label: 'Bulan Lalu');
    }),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start          = widget.initial?.start ?? DateTime(now.year, now.month, 1);
    _end            = widget.initial?.end   ?? now;
    _selectedPreset = widget.initial?.label ?? '';
  }

  void _applyPreset(_Preset preset) {
    final range = preset.builder();
    setState(() {
      _start          = range.start;
      _end            = range.end;
      _selectedPreset = preset.label;
    });
  }

  // ── Dark-mode-aware date picker ───────────────────────────────────────────
  Future<DateTime?> _showDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: isDark ? AppColors.cardDark : AppColors.card,
            onSurface: isDark
                ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          dialogBackgroundColor: isDark ? AppColors.cardDark : AppColors.card,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await _showDatePicker(
        initialDate: _start, firstDate: DateTime(2020), lastDate: _end);
    if (picked != null) setState(() {
      _start = picked; _selectedPreset = 'Custom';
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _showDatePicker(
        initialDate: _end, firstDate: _start, lastDate: DateTime.now());
    if (picked != null) setState(() {
      _end = picked; _selectedPreset = 'Custom';
    });
  }

  void _apply() {
    final label = _selectedPreset.isNotEmpty
        ? _selectedPreset : '${_fmt(_start)} – ${_fmt(_end)}';
    Navigator.pop(context,
        SpendlyDateRange(start: _start, end: _end, label: label));
  }

  String _fmt(DateTime d)  => '${d.day}/${d.month}/${d.year}';
  String _dayDiff() {
    final diff = _end.difference(_start).inDays + 1;
    return '$diff hari';
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: bdrColor,
                borderRadius: BorderRadius.circular(2)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text('Pilih Periode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: txtPrim, letterSpacing: -0.3)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: txtSec),
                ),
              ],
            ),
          ),

          // Preset chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _presets.map((p) {
                final isSelected = _selectedPreset == p.label;
                return GestureDetector(
                  onTap: () => _applyPreset(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : surfColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? AppColors.primary : bdrColor),
                    ),
                    child: Text(p.label, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : txtSec,
                    )),
                  ),
                );
              }).toList(),
            ),
          ),

          // Date tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _DateTile(
                  label: 'Dari', date: _start,
                  isDark: isDark, onTap: _pickStart,
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: txtSec, size: 18),
                ),
                Expanded(child: _DateTile(
                  label: 'Sampai', date: _end,
                  isDark: isDark, onTap: _pickEnd,
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Durasi: ${_dayDiff()}',
            style: TextStyle(fontSize: 12, color: txtSec)),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Terapkan Periode'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String   label;
  final DateTime date;
  final bool     isDark;
  final VoidCallback onTap;

  const _DateTile({
    required this.label, required this.date,
    required this.isDark, required this.onTap,
  });

  String _fmt(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';
  String _month(int m)    => [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
  ][m - 1];

  @override
  Widget build(BuildContext context) {
    final surfColor = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark     : AppColors.border;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdrColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: txtSec)),
            const SizedBox(height: 3),
            Text(_fmt(date), style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: txtPrim,
            )),
          ],
        ),
      ),
    );
  }
}