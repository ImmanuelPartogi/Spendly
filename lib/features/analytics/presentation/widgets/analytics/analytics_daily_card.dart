import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';

class AnalyticsDailyCard extends StatefulWidget {
  final Map<String, double> daily;
  final bool isDark;

  const AnalyticsDailyCard({
    super.key,
    required this.daily,
    required this.isDark,
  });

  @override
  State<AnalyticsDailyCard> createState() => _AnalyticsDailyCardState();
}

class _AnalyticsDailyCardState extends State<AnalyticsDailyCard> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    final card = widget.isDark ? AppColors.cardDark : AppColors.card;
    final bdr = widget.isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final sorted = widget.daily.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final hasData = sorted.any((e) => e.value > 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pengeluaran Harian',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,),),
              const SizedBox(height: 3),
              Text('Tap bar untuk melihat detail hari',
                  style: TextStyle(fontSize: 11, color: txtSec),),
            ],),
            const _ChartBadge(label: 'Harian', color: AppColors.expense),
          ],
        ),

        // Selected day detail (chart interaction filter)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          child: _selected >= 0 && _selected < sorted.length
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _DayDetailTile(
                    entry: sorted[_selected],
                    isDark: widget.isDark,
                    onDismiss: () => setState(() => _selected = -1),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 20),

        if (!hasData)
          const _EmptyChart()
        else
          _DailyBarChart(
            sorted: sorted,
            selected: _selected,
            isDark: widget.isDark,
            onSelect: (i) =>
                setState(() => _selected = (_selected == i) ? -1 : i),
          ),
      ],),
    );
  }
}

class _DayDetailTile extends StatelessWidget {
  final MapEntry<String, double> entry;
  final bool isDark;
  final VoidCallback onDismiss;

  const _DayDetailTile({
    required this.entry,
    required this.isDark,
    required this.onDismiss,
  });

  static const _days = [
    'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu',
  ];
  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agt','Sep','Okt','Nov','Des',
  ];

  String get _dateLabel {
    try {
      final d = DateTime.parse(entry.key);
      return '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
    } catch (_) {
      return entry.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.expense.withValues(alpha: 0.30), width: 1.0,),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_today_rounded,
              color: AppColors.expense, size: 17,),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_dateLabel,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: txtPrim,),),
            Text('Total pengeluaran', style: TextStyle(fontSize: 10, color: txtSec)),
          ],),
        ),
        Text(CurrencyFormatter.formatCompact(entry.value),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.expense,
                letterSpacing: -0.4,),),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(Icons.close_rounded,
              size: 16,
              color: isDark ? AppColors.textHintDark : AppColors.textHint,),
        ),
      ],),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final int selected;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _DailyBarChart({
    required this.sorted,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  static const _dayShort = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];

  String _label(String key) {
    try {
      return _dayShort[DateTime.parse(key).weekday - 1];
    } catch (_) {
      return key.split('-').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = isDark ? AppColors.textHintDark : AppColors.textHint;
    final div = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.border.withValues(alpha: 0.7);
    final maxVal = sorted.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final barW = sorted.length <= 7 ? 28.0 : 18.0;

    return SizedBox(
      height: 150,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal * 1.35 : 1000,
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              onSelect(response!.spot!.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (_, __, ___, ____) => null,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                final isSel = i == selected;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_label(sorted[i].key),
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppColors.expense : hint,),),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: div, strokeWidth: 0.5, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sorted.asMap().entries.map((e) {
          final val = e.value.value;
          final isSel = e.key == selected;
          final isMax = val == maxVal && maxVal > 0;

          final color = isSel
              ? AppColors.expense
              : isMax
                  ? AppColors.expense.withValues(alpha: 0.65)
                  : (isDark
                      ? AppColors.expense.withValues(alpha: 0.18)
                      : AppColors.expense.withValues(alpha: 0.14));

          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: val == 0 ? 0.01 : val,
              color: color,
              width: barW,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              backDrawRodData: BackgroundBarChartRodData(
                show: isSel,
                toY: maxVal * 1.35,
                color: AppColors.expense.withValues(alpha: 0.05),
              ),
            ),
          ],);
        }).toList(),
      ),),
    );
  }
}

class _ChartBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color,),),
      ],),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Center(
        child: Text('Belum ada data pengeluaran',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),),
      ),
    );
  }
}