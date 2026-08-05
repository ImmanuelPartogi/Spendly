import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../../../notification/domain/providers/notification_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pinEnabled = false;
  bool _budgetNotif = true;
  bool _recurringNotif = true;
  bool _monthlyReport = true;
  String _currency = 'IDR';
  String _language = 'Bahasa Indonesia';
  String _firstDayOfWeek = 'Senin';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final pinEnabled = await AuthService.isPinEnabled();
    if (mounted) {
      setState(() {
        _pinEnabled = pinEnabled;
        _budgetNotif = prefs.getBool('notif_budget') ?? true;
        _recurringNotif = prefs.getBool('notif_recurring') ?? true;
        _monthlyReport = prefs.getBool('notif_monthly') ?? true;
        _currency = prefs.getString('currency') ?? 'IDR';
        _language = prefs.getString('language') ?? 'Bahasa Indonesia';
        _firstDayOfWeek = prefs.getString('first_day_week') ?? 'Senin';
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_budget', _budgetNotif);
    await prefs.setBool('notif_recurring', _recurringNotif);
    await prefs.setBool('notif_monthly', _monthlyReport);
    await prefs.setString('currency', _currency);
    await prefs.setString('language', _language);
    await prefs.setString('first_day_week', _firstDayOfWeek);
  }

  void _togglePin(bool value) async {
    if (value) {
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              mode: PinScreenMode.setup,
              onSuccess: () {
                Navigator.pop(context);
                setState(() => _pinEnabled = true);
              },
            ),
          ),
        ),
      );
    } else {
      await AuthService.disablePin();
      setState(() => _pinEnabled = false);
    }
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('dialog_delete_title'.tr()),
        content: Text(
          'Ini akan menghapus SEMUA transaksi, budget, dan pengaturan secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('dialog_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('snackbar_all_data_deleted'.tr())),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: Text('dialog_delete'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final currentLocale = context.locale;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
          style: TextStyle(
            color: txtPrim,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tampilan ────────────────────────────────────────────────────────
          _SectionHeader('TAMPILAN & WILAYAH', txtSec: txtSec),
          _SettingsCard(
            isDark: isDark,
            children: [
              _DropdownTile(
                icon: Icons.attach_money_rounded,
                label: 'Mata Uang',
                value: _currency,
                options: const ['IDR', 'USD', 'SGD', 'MYR', 'EUR'],
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _currency = v);
                  _savePrefs();
                },
              ),
              _Divider(isDark: isDark),
              _DropdownTile(
                icon: Icons.language_rounded,
                label: 'language'.tr(),
                value: switch (currentLocale.languageCode) {
                  'en' => 'English',
                  'ms' => 'Bahasa Melayu',
                  'es' => 'Español',
                  'zh' => '中文',
                  'hi' => 'हिन्दी',
                  'fr' => 'Français',
                  'pt' => 'Português',
                  'ja' => '日本語',
                  'de' => 'Deutsch',
                  'ru' => 'Русский',
                  'ko' => '한국어',
                  'vi' => 'Tiếng Việt',
                  _ => 'Bahasa Indonesia',
                },
                options: const [
                  'Bahasa Indonesia',
                  'English',
                  'Bahasa Melayu',
                  'Español',
                  '中文',
                  'हिन्दी',
                  'Français',
                  'Português',
                  '日本語',
                  'Deutsch',
                  'Русский',
                  '한국어',
                  'Tiếng Việt',
                ],
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _language = v);
                  _savePrefs();
                  final langCode = switch (v) {
                    'English' => 'en',
                    'Bahasa Melayu' => 'ms',
                    'Español' => 'es',
                    '中文' => 'zh',
                    'हिन्दी' => 'hi',
                    'Français' => 'fr',
                    'Português' => 'pt',
                    '日本語' => 'ja',
                    'Deutsch' => 'de',
                    'Русский' => 'ru',
                    '한국어' => 'ko',
                    'Tiếng Việt' => 'vi',
                    _ => 'id',
                  };
                  context.setLocale(Locale(langCode));
                },
              ),
              _Divider(isDark: isDark),
              _DropdownTile(
                icon: Icons.calendar_today_rounded,
                label: 'Awal Minggu',
                value: _firstDayOfWeek,
                options: const ['Senin', 'Minggu'],
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _firstDayOfWeek = v);
                  _savePrefs();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Notifikasi ──────────────────────────────────────────────────────
          _SectionHeader('NOTIFIKASI', txtSec: txtSec),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.income,
                label: 'Pengingat Inaktivitas & Rekap',
                subtitle: 'Pengingat transaksi harian & rekap mingguan',
                value: ref.watch(notificationEnabledProvider),
                isDark: isDark,
                onChanged: (v) {
                  ref
                      .read(notificationEnabledProvider.notifier)
                      .toggleNotification(v);
                },
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                label: 'Peringatan Budget',
                subtitle: 'Notifikasi saat budget hampir habis',
                value: _budgetNotif,
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _budgetNotif = v);
                  _savePrefs();
                },
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.repeat_rounded,
                iconColor: AppColors.accentPurple,
                label: 'Transaksi Berulang',
                subtitle: 'Reminder sebelum jatuh tempo',
                value: _recurringNotif,
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _recurringNotif = v);
                  _savePrefs();
                },
              ),
              _Divider(isDark: isDark),
              _SwitchTile(
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.primary,
                label: 'Laporan Bulanan',
                subtitle: 'Ringkasan keuangan setiap awal bulan',
                value: _monthlyReport,
                isDark: isDark,
                onChanged: (v) {
                  setState(() => _monthlyReport = v);
                  _savePrefs();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Keamanan ────────────────────────────────────────────────────────
          _SectionHeader('KEAMANAN', txtSec: txtSec),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                icon: Icons.lock_rounded,
                iconColor: AppColors.primary,
                label: 'Kunci PIN',
                subtitle: 'Wajib PIN saat buka app',
                value: _pinEnabled,
                isDark: isDark,
                onChanged: _togglePin,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Data ────────────────────────────────────────────────────────────
          _SectionHeader('DATA', txtSec: txtSec),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ArrowTile(
                icon: Icons.upload_rounded,
                iconColor: AppColors.income,
                label: 'Cadangkan Data',
                isDark: isDark,
                onTap: () {},
              ),
              _Divider(isDark: isDark),
              _ArrowTile(
                icon: Icons.download_rounded,
                iconColor: AppColors.accentPurple,
                label: 'Pulihkan Data',
                isDark: isDark,
                onTap: () {},
              ),
              _Divider(isDark: isDark),
              _ArrowTile(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.primary,
                label: 'Ekspor Data',
                isDark: isDark,
                onTap: () {},
              ),
              _Divider(isDark: isDark),
              _ArrowTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.expense,
                label: 'Hapus Semua Data',
                labelColor: AppColors.expense,
                isDark: isDark,
                onTap: _clearAllData,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tentang ─────────────────────────────────────────────────────────
          _SectionHeader('TENTANG', txtSec: txtSec),
          _SettingsCard(
            isDark: isDark,
            children: [
              _InfoTile(label: 'Versi Aplikasi', value: '1.0.0', isDark: isDark),
              _Divider(isDark: isDark),
              _ArrowTile(
                icon: Icons.description_rounded,
                iconColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                label: 'Kebijakan Privasi',
                isDark: isDark,
                onTap: () {},
              ),
              _Divider(isDark: isDark),
              _ArrowTile(
                icon: Icons.star_rounded,
                iconColor: AppColors.warning,
                label: 'Beri Rating',
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color txtSec;
  const _SectionHeader(this.title, {required this.txtSec});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: txtSec,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconContainer(icon: icon, color: iconColor, isDark: isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconContainer(
            icon: icon,
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            underline: const SizedBox.shrink(),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ArrowTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = labelColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _IconContainer(icon: icon, color: iconColor, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: txtColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _IconContainer({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: isDark
          ? AppColors.borderDark.withValues(alpha: 0.5)
          : AppColors.border.withValues(alpha: 0.5),
    );
  }
}