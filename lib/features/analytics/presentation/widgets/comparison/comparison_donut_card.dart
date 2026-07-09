import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/category_utils.dart';
import '../../../../../core/utils/currency_formatter.dart';

class ComparisonDonutCard extends StatefulWidget {
  final Map<String, double> incomeCats;
  final Map<String, double> expenseCats;
  final double totalIncome;
  final double totalExpense;
  final bool isDark;

  const ComparisonDonutCard({
    super.key,
    required this.incomeCats,
    required this.expenseCats,
    required this.totalIncome,
    required this.totalExpense,
    required this.isDark,
  });

  @override
  State<ComparisonDonutCard> createState() => _ComparisonDonutCardState();
}

class _ComparisonDonutCardState extends State<ComparisonDonutCard> {
  int _touchedIncome = -1;
  int _touchedExpense = -1;

  @override
  Widget build(BuildContext context) {
    final card = widget.isDark ? AppColors.cardDark : AppColors.card;
    final bdr = widget.isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = widget.isDark ? AppColors.dividerDark : AppColors.divider;

    final incomeEntries = widget.incomeCats.entries.take(5).toList();
    final expenseEntries = widget.expenseCats.entries.take(5).toList();

    final hasData = widget.totalIncome > 0 || widget.totalExpense > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Distribusi Keuangan',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: txtPrim,
                letterSpacing: -0.3,),),
        const SizedBox(height: 3),
        Text('Komposisi pemasukan dan pengeluaran per kategori',
            style: TextStyle(fontSize: 11, color: txtSec),),
        const SizedBox(height: 20),

        if (!hasData)
          SizedBox(
            height: 100,
            child: Center(
              child: Text('Belum ada data',
                  style: TextStyle(fontSize: 12, color: txtSec),),
            ),
          )
        else
          Row(children: [
            // Income donut
            Expanded(
              child: _DonutSection(
                label: 'Pemasukan',
                entries: incomeEntries,
                total: widget.totalIncome,
                touched: _touchedIncome,
                isDark: widget.isDark,
                accentColor: AppColors.income,
                onTouch: (i) => setState(() {
                  _touchedIncome = _touchedIncome == i ? -1 : i;
                  _touchedExpense = -1;
                }),
              ),
            ),

            Container(width: 0.5, height: 160, color: div),

            // Expense donut
            Expanded(
              child: _DonutSection(
                label: 'Pengeluaran',
                entries: expenseEntries,
                total: widget.totalExpense,
                touched: _touchedExpense,
                isDark: widget.isDark,
                accentColor: AppColors.expense,
                onTouch: (i) => setState(() {
                  _touchedExpense = _touchedExpense == i ? -1 : i;
                  _touchedIncome = -1;
                }),
              ),
            ),
          ],),
      ],),
    );
  }
}

class _DonutSection extends StatelessWidget {
  final String label;
  final List<MapEntry<String, double>> entries;
  final double total;
  final int touched;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<int> onTouch;

  const _DonutSection({
    required this.label,
    required this.entries,
    required this.total,
    required this.touched,
    required this.isDark,
    required this.accentColor,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    if (total == 0 || entries.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: isDark ? AppColors.textHintDark : AppColors.textHint,),
            ),
            const SizedBox(height: 6),
            Text('Tidak ada data', style: TextStyle(fontSize: 11, color: txtSec)),
          ],),
        ),
      );
    }

    final touchedEntry = touched >= 0 && touched < entries.length
        ? entries[touched]
        : null;

    return Column(children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,),),
      const SizedBox(height: 12),
      SizedBox(
        height: 110,
        child: Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (ev, res) {
                if (!ev.isInterestedForInteractions ||
                    res?.touchedSection == null) {
                  onTouch(-1);
                } else {
                  onTouch(res!.touchedSection!.touchedSectionIndex);
                }
              },
            ),
            sections: entries.asMap().entries.map((e) {
              final isOn = e.key == touched;
              return PieChartSectionData(
                color: CategoryUtils.getColor(e.value.key),
                value: e.value.value,
                title: '',
                radius: isOn ? 40 : 32,
              );
            }).toList(),
            centerSpaceRadius: 28,
            sectionsSpace: 2,
          ),),
          // Center label
          touchedEntry != null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '${(touchedEntry.value / total * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: CategoryUtils.getColor(touchedEntry.key),
                        letterSpacing: -0.3,),
                  ),
                ],)
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    CurrencyFormatter.formatCompact(total),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: txtPrim,
                        letterSpacing: -0.3,),
                  ),
                  Text('total',
                      style: TextStyle(fontSize: 8, color: txtSec),),
                ],),
        ],),
      ),
      const SizedBox(height: 8),
      // Mini legend
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.take(3).map((e) {
          final color = CategoryUtils.getColor(e.key);
          final pct = (e.value / total * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2),),),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  CategoryUtils.getShortLabel(e.key),
                  style: TextStyle(fontSize: 9.5, color: txtSec),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: color,),),
            ],),
          );
        }).toList(),
      ),
    ],);
  }
}