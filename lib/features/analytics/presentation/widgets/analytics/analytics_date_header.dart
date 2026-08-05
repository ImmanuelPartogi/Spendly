import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';

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

  ({String title, String subtitle}) _labels(BuildContext context) {
    if (weekOffset == -1) {
      return (title: 'this_month'.tr(), subtitle: _monthLabel(context));
    }
    if (weekOffset < 0) {
      return (title: 'custom_range'.tr(), subtitle: 'custom_filter_applied'.tr());
    }
    if (weekOffset == 0) {
      return (title: 'this_week'.tr(), subtitle: _weekLabel(context, 0));
    }
    return (
      title: 'weeks_ago'.tr(namedArgs: {'count': '$weekOffset'}),
      subtitle: _weekLabel(context, weekOffset),
    );
  }

  String _weekLabel(BuildContext context, int offset) {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1 + offset * 7));
    final sun = mon.add(const Duration(days: 6));
    final loc = context.locale.languageCode;
    if (mon.month == sun.month) {
      final monthStr = DateFormatter.formatMonthYear(mon, locale: loc);
      return '${mon.day}–${sun.day} $monthStr';
    }
    final monStr = DateFormatter.formatDayMonth(mon, locale: loc);
    final sunStr = DateFormatter.formatDayMonth(sun, locale: loc);
    return '$monStr – $sunStr';
  }

  String _monthLabel(BuildContext context) {
    final now = DateTime.now();
    return DateFormatter.formatMonthYear(now, locale: context.locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
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
      ],),
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
          color: active ? AppColors.primary.withValues(alpha: 0.10) : Colors.transparent,
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