import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String category;
  final Map<String, double> monthlyTrend; // { 'Jan': 250000, ... }

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.monthlyTrend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = CategoryUtils.getColor(category);

    // TODO: replace with real provider
    final transactions = <TransactionEntity>[];
    final total = transactions.fold(0.0, (s, t) => s + t.amount);
    final avg = transactions.isEmpty
        ? 0.0
        : total / DateTime.now().day;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero app bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: catColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white,),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: catColor,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Total Bulan Ini',
                          value: CurrencyFormatter.format(total),
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'Rata-rata/Hari',
                          value: CurrencyFormatter.formatCompact(avg),
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'Transaksi',
                          value: '${transactions.length}x',
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 3-month trend ────────────────────────────────────────
                  Text(
                    'Tren 3 Bulan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _TrendChart(
                      data: monthlyTrend, color: catColor,),
                  const SizedBox(height: 24),

                  // ── Transactions ─────────────────────────────────────────
                  Text(
                    'Transaksi Bulan Ini',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (transactions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Text('📭',
                          style: TextStyle(fontSize: 40),),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                            color: AppColors.textSecondary,),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => TransactionTile(
                    transaction: transactions[i],
                    index: i,
                    onTap: () {},
                  ),
                  childCount: transactions.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final Map<String, double> data;
  final Color color;
  const _TrendChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Belum ada data')),
      );
    }

    final entries = data.entries.toList();
    final maxVal =
        data.values.reduce((a, b) => a > b ? a : b);
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider, strokeWidth: 1,),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entries[i].key,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint,),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (entries.length - 1).toDouble(),
          minY: 0,
          maxY: maxVal * 1.3,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: color,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}