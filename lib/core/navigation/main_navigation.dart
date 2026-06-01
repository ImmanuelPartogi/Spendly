import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

// ─── Daftar layar ─────────────────────────────────────────────────────────────
const List<Widget> _screens = [
  DashboardScreen(),
  TransactionsScreen(),
  AnalyticsScreen(),
  BudgetScreen(),
  ProfileScreen(),
];

const double kScrollPaddingBottom = 100.0;

const _navItems = [
  _NavMeta(icon: Icons.home_rounded,         label: 'Beranda'),
  _NavMeta(icon: Icons.receipt_long_rounded, label: 'Transaksi'),
  _NavMeta(icon: Icons.bar_chart_rounded,    label: 'Analitik'),
  _NavMeta(icon: Icons.savings_rounded,      label: 'Anggaran'),
  _NavMeta(icon: Icons.person_rounded,       label: 'Profil'),
];

class _NavMeta {
  final IconData icon;
  final String label;
  const _NavMeta({required this.icon, required this.label});
}

// ─── Shell utama ──────────────────────────────────────────────────────────────

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      // extendBody agar konten bisa scroll di balik nav bar
      extendBody: true,
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: index,
        onTap: (i) {
          HapticFeedback.selectionClick();
          ref.read(bottomNavIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}

// ─── Nav Bar Mengambang ───────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: bdrColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : AppColors.primary.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: List.generate(
                _navItems.length,
                (i) => Expanded(
                  child: _NavItem(
                    meta: _navItems[i],
                    index: i,
                    currentIndex: currentIndex,
                    isDark: isDark,
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Item Navigasi ────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavMeta meta;
  final int index;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.meta,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected    = currentIndex == index;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textHint;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Kontainer ikon animasi ─────────────────────────────────────
          AnimatedContainer(
            duration: kDurationFast,
            curve: kCurveDefault,
            width:  isSelected ? 48 : 40,
            height: isSelected ? 34 : 30,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: kDurationFast,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.75, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: kCurveSpring)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  meta.icon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected ? AppColors.primary : inactiveColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // ── Label animasi ──────────────────────────────────────────────
          AnimatedDefaultTextStyle(
            duration: kDurationFast,
            curve: kCurveDefault,
            style: TextStyle(
              fontSize:   10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color:      isSelected ? AppColors.primary : inactiveColor,
            ),
            child: Text(meta.label),
          ),
        ],
      ),
    );
  }
}