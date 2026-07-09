  import 'package:flutter/material.dart';
  import '../../core/theme/app_colors.dart';

  /// Tipe empty state — masing-masing punya ilustrasi berbeda.
  enum EmptyStateType {
    dashboard,
    transactions,
    analytics,
    budget,
    goals,
    search,
    notifications,
  }

  class IllustratedEmptyState extends StatefulWidget {
    final EmptyStateType type;
    final String? title;
    final String? subtitle;
    final String? actionLabel;
    final VoidCallback? onAction;

    const IllustratedEmptyState({
      super.key,
      required this.type,
      this.title,
      this.subtitle,
      this.actionLabel,
      this.onAction,
    });

    @override
    State<IllustratedEmptyState> createState() =>
        _IllustratedEmptyStateState();
  }

  class _IllustratedEmptyStateState extends State<IllustratedEmptyState>
      with SingleTickerProviderStateMixin {
    late final AnimationController _ctrl;
    late final Animation<double> _scale;

    @override
    void initState() {
      super.initState();
      // Breathing animation
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);

      _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      );
    }

    @override
    void dispose() {
      _ctrl.dispose();
      super.dispose();
    }

    _EmptyConfig get _config {
      switch (widget.type) {
        case EmptyStateType.dashboard:
          return const _EmptyConfig(
            emoji: '💸',
            color: Color(0xFF3A7AFE),
            defaultTitle: 'Mulai Catat Keuanganmu',
            defaultSubtitle:
                'Tambahkan transaksi pertamamu dan mulai kontrol keuanganmu.',
          );
        case EmptyStateType.transactions:
          return const _EmptyConfig(
            emoji: '📋',
            color: Color(0xFF7C5CBF),
            defaultTitle: 'Belum Ada Transaksi',
            defaultSubtitle:
                'Tap tombol + di bawah untuk menambah transaksi baru.',
          );
        case EmptyStateType.analytics:
          return const _EmptyConfig(
            emoji: '📊',
            color: Color(0xFF00C48C),
            defaultTitle: 'Belum Ada Data',
            defaultSubtitle:
                'Catat beberapa transaksi agar insight bisa ditampilkan.',
          );
        case EmptyStateType.budget:
          return const _EmptyConfig(
            emoji: '🎯',
            color: Color(0xFFFF7D45),
            defaultTitle: 'Belum Ada Budget',
            defaultSubtitle:
                'Buat budget per kategori agar pengeluaranmu terkontrol.',
          );
        case EmptyStateType.goals:
          return const _EmptyConfig(
            emoji: '🏆',
            color: Color(0xFFFFB020),
            defaultTitle: 'Belum Ada Goals',
            defaultSubtitle:
                'Tentukan target keuanganmu dan pantau progresnya.',
          );
        case EmptyStateType.search:
          return const _EmptyConfig(
            emoji: '🔍',
            color: Color(0xFF6B7080),
            defaultTitle: 'Tidak Ada Hasil',
            defaultSubtitle:
                'Coba kata kunci atau filter yang berbeda.',
          );
        case EmptyStateType.notifications:
          return const _EmptyConfig(
            emoji: '🔔',
            color: Color(0xFF3A7AFE),
            defaultTitle: 'Tidak Ada Notifikasi',
            defaultSubtitle: 'Semua notifikasi sudah dibaca.',
          );
      }
    }

    @override
    Widget build(BuildContext context) {
      final cfg = _config;
      final title = widget.title ?? cfg.defaultTitle;
      final subtitle = widget.subtitle ?? cfg.defaultSubtitle;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Breathing illustration ──────────────────────────────────
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cfg.emoji,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Text ───────────────────────────────────────────────────
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cfg.color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12,),
                  ),
                  child: Text(widget.actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  class _EmptyConfig {
    final String emoji;
    final Color color;
    final String defaultTitle;
    final String defaultSubtitle;

    const _EmptyConfig({
      required this.emoji,
      required this.color,
      required this.defaultTitle,
      required this.defaultSubtitle,
    });
  }