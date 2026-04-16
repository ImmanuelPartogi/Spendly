import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AnalyticsDateHeader extends StatelessWidget {
  final int weekOffset;
  final bool isDark;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const AnalyticsDateHeader({
    super.key,
    required this.weekOffset,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  ({String title, String subtitle}) _labels() {
    if (weekOffset == -1) {
      return (title: 'Bulan Ini', subtitle: _monthLabel());
    }
    if (weekOffset < 0) {
      return (title: 'Rentang Kustom', subtitle: 'Filter kustom diterapkan');
    }
    if (weekOffset == 0) {
      return (title: 'Minggu Ini', subtitle: _weekLabel(0));
    }
    return (
      title: '$weekOffset Minggu Lalu',
      subtitle: _weekLabel(weekOffset),
    );
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agt','Sep','Okt','Nov','Des',
  ];

  String _weekLabel(int offset) {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1 + offset * 7));
    final sun = mon.add(const Duration(days: 6));
    if (mon.month == sun.month) {
      return '${mon.day}–${sun.day} ${_months[mon.month - 1]} ${mon.year}';
    }
    return '${mon.day} ${_months[mon.month - 1]} – '
        '${sun.day} ${_months[sun.month - 1]}';
  }

  String _monthLabel() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '1–$lastDay ${_months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels();
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final showNav = weekOffset >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Row(children: [
        if (showNav)
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            active: true,
            isDark: isDark,
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels.title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                labels.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: txtPrim,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (showNav)
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            onTap: canGoNext ? onNext : null,
            active: canGoNext,
            isDark: isDark,
          )
        else
          const SizedBox(width: 8),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool isDark;

  const _NavBtn({
    required this.icon,
    required this.onTap,
    required this.active,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active
              ? AppColors.primary
              : (isDark ? AppColors.textHintDark : AppColors.textHint),
        ),
      ),
    );
  }
}