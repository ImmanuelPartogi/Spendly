import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/services/auth_service_firebase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/pin_screen.dart';
import '../widgets/profile_hero_card.dart';
import 'edit_profile_screen.dart';

// ─── Profile State Provider ───────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider<_ProfileNotifier, _ProfileState>(
        (_) => _ProfileNotifier(),);

class _ProfileState {
  final String name;
  final String avatar;
  final String? photoPath;
  const _ProfileState({this.name = '', this.avatar = '😎', this.photoPath});
}

class _ProfileNotifier extends StateNotifier<_ProfileState> {
  _ProfileNotifier() : super(const _ProfileState()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _ProfileState(
      name: prefs.getString('user_name') ?? '',
      avatar: prefs.getString('user_avatar') ?? '😎',
      photoPath: prefs.getString('user_photo'),
    );
  }

  Future<void> save({required String name, required String avatar, String? photoPath}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_avatar', avatar);
    photoPath != null
        ? await prefs.setString('user_photo', photoPath)
        : await prefs.remove('user_photo');
    state = _ProfileState(name: name, avatar: avatar, photoPath: photoPath);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final safeTop   = MediaQuery.of(context).padding.top;

    final profile        = ref.watch(profileProvider);
    final balance        = ref.watch(totalBalanceProvider);
    final isAnon         = ref.watch(isAnonymousProvider);
    final userEmail      = ref.watch(currentUserEmailProvider);
    final monthlyIncome  = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final themeMode      = ref.watch(themeProvider);

    String themeLabel; IconData themeIcon; Color themeIconColor;
    switch (themeMode) {
      case ThemeMode.dark:
        themeLabel = 'Gelap'; themeIcon = Icons.dark_mode_rounded; themeIconColor = AppColors.accentPurple;
      case ThemeMode.light:
        themeLabel = 'Terang'; themeIcon = Icons.light_mode_rounded; themeIconColor = AppColors.warning;
      default:
        themeLabel = 'Otomatis'; themeIcon = Icons.brightness_auto_rounded; themeIconColor = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _ProfileAppBar(
            isDark: isDark, safeTop: safeTop,
            onEdit: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ProfileHeroCard(
                  name: profile.name, avatar: profile.avatar,
                  photoPath: profile.photoPath, balance: balance,
                  isAnon: isAnon, userEmail: userEmail,
                ),
                const SizedBox(height: 14),

                if (isAnon) ...[
                  _UpgradeBanner(isDark: isDark),
                  const SizedBox(height: 14),
                ],

                Row(children: [
                  Expanded(child: _MonthlyStatCard(
                    label: 'Pemasukan', value: monthlyIncome,
                    color: AppColors.income, icon: Icons.arrow_downward_rounded, isDark: isDark,),),
                  const SizedBox(width: 10),
                  Expanded(child: _MonthlyStatCard(
                    label: 'Pengeluaran', value: monthlyExpense,
                    color: AppColors.expense, icon: Icons.arrow_upward_rounded, isDark: isDark,),),
                ],),
                const SizedBox(height: 24),

                // ── Akun ──────────────────────────────────────────────────────
                _SectionTitle(label: 'Akun', txtPrim: txtPrim),
                const SizedBox(height: 10),
                _SettingsGroup(
                  isDark: isDark,
                  items: [
                    _GroupItem(
                      icon: Icons.verified_user_rounded,
                      iconColor: isAnon ? AppColors.warning : AppColors.income,
                      label: 'Status',
                      trailing: _StatusPill(
                        label: isAnon ? 'Tamu' : 'Terautentikasi',
                        isActive: !isAnon, isDark: isDark,
                      ),
                    ),
                    if (!isAnon)
                      _GroupItem(
                        icon: Icons.alternate_email_rounded,
                        iconColor: AppColors.primary,
                        label: 'Email',
                        trailing: Text(userEmail ?? '-',
                          style: TextStyle(fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,),
                          overflow: TextOverflow.ellipsis,),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Keamanan ──────────────────────────────────────────────────
                _SectionTitle(label: 'Keamanan', txtPrim: txtPrim),
                const SizedBox(height: 10),
                _PinSection(isDark: isDark),
                const SizedBox(height: 20),

                // ── Pengaturan ────────────────────────────────────────────────
                _SectionTitle(label: 'Pengaturan', txtPrim: txtPrim),
                const SizedBox(height: 10),
                _SettingsGroup(
                  isDark: isDark,
                  items: [
                    _GroupItem(
                      icon: Icons.payments_rounded,
                      iconColor: AppColors.accentTeal,
                      label: 'Mata Uang',
                      trailing: Text('IDR', style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,),),
                    ),
                    _GroupItem(
                      icon: themeIcon, iconColor: themeIconColor,
                      label: 'Tema',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(themeLabel, style: TextStyle(fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,),),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16,
                          color: isDark ? AppColors.textHintDark : AppColors.textHint,),
                      ],),
                      onTap: () => _showThemeSheet(context, ref, themeMode, isDark),
                    ),
                    _GroupItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textSecondary,
                      label: 'Versi Aplikasi',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('v1.0.0', style: TextStyle(fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,),),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _LogoutButton(
                  isAnon: isAnon, isDark: isDark,
                  onTap: () => _confirmLogout(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref,
      ThemeMode current, bool isDark,) {
    final cardColor = isDark ? AppColors.cardDark     : AppColors.card;
    final txtPrim   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (_) {
        final options = [
          (ThemeMode.light,  Icons.light_mode_rounded,      AppColors.warning,      'Terang'),
          (ThemeMode.dark,   Icons.dark_mode_rounded,       AppColors.accentPurple, 'Gelap'),
          (ThemeMode.system, Icons.brightness_auto_rounded, AppColors.primary,      'Ikuti Sistem'),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Tema', style: TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w800, color: txtPrim, letterSpacing: -0.3,),),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final (mode, icon, color, label) = opt;
                final isSelected = current == mode;
                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(mode);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                          : (isDark ? AppColors.surfaceDark : AppColors.surface),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? color.withValues(alpha: 0.5)
                            : (isDark ? AppColors.borderDark : AppColors.border),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Icon(icon, color: color, size: 18)),
                      ),
                      const SizedBox(width: 14),
                      Text(label, style: TextStyle(fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : txtPrim,),),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                        ),
                    ],),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final txtPrim   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?', style: TextStyle(
            color: txtPrim, fontWeight: FontWeight.w700, letterSpacing: -0.3,),),
        content: Text(
          'Kamu akan keluar dari akun ini. Data lokal tetap tersimpan di perangkat.',
          style: TextStyle(color: txtSec, fontSize: 13.5, height: 1.5),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: txtSec)),),
          Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuthService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Keluar',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PIN Section ──────────────────────────────────────────────────────────────

class _PinSection extends StatefulWidget {
  final bool isDark;
  const _PinSection({required this.isDark});

  @override
  State<_PinSection> createState() => _PinSectionState();
}

class _PinSectionState extends State<_PinSection> {
  bool _pinEnabled = false;
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final enabled = await AuthService.isPinEnabled();
    if (mounted) setState(() { _pinEnabled = enabled; _loading = false; });
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.income : AppColors.expense,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),);
  }

  Future<void> _enablePin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinScreen(
        mode: PinScreenMode.setup,
        onSuccess: () => Navigator.pop(context, true),
        onCancel:  () => Navigator.pop(context, false),
      ),),
    );
    if (result == true && mounted) {
      setState(() => _pinEnabled = true);
      _showSnack('PIN berhasil diaktifkan');
    }
  }

  Future<void> _disablePin() async {
    // Verifikasi PIN dulu sebelum nonaktifkan
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinScreen(
        mode: PinScreenMode.verify,
        onSuccess: () => Navigator.pop(context, true),
        onCancel:  () => Navigator.pop(context, false),
      ),),
    );
    if (verified != true || !mounted) return;

    await AuthService.disablePin();
    if (mounted) {
      setState(() => _pinEnabled = false);
      _showSnack('PIN berhasil dinonaktifkan');
    }
  }

  Future<void> _changePin() async {
    // Step 1: verifikasi PIN lama
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinScreen(
        mode: PinScreenMode.verify,
        onSuccess: () => Navigator.pop(context, true),
        onCancel:  () => Navigator.pop(context, false),
      ),),
    );
    if (verified != true || !mounted) return;

    // Step 2: setup PIN baru
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PinScreen(
        mode: PinScreenMode.setup,
        onSuccess: () => Navigator.pop(context),
        onCancel:  () => Navigator.pop(context),
      ),),
    );
    if (mounted) _showSnack('PIN berhasil diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = widget.isDark;
    final cardColor = isDark ? AppColors.cardDark   : AppColors.card;
    final bdrColor  = isDark ? AppColors.borderDark : AppColors.border;
    final divColor  = isDark ? AppColors.dividerDark : AppColors.divider;
    final txtPrim   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    if (_loading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bdrColor),
        ),
        child: const Center(child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdrColor),
      ),
      child: Column(
        children: [
          // Status baris
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: (_pinEnabled ? AppColors.income : AppColors.textSecondary)
                      .withValues(alpha: isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(child: Icon(
                  _pinEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 15,
                  color: _pinEnabled ? AppColors.income : AppColors.textSecondary,
                ),),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PIN Keamanan', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: txtPrim,),),
                  Text(_pinEnabled ? 'Aktif' : 'Tidak aktif',
                    style: TextStyle(fontSize: 11.5, color: txtSec),),
                ],
              ),),
              // Toggle enable / disable
              GestureDetector(
                onTap: _pinEnabled ? _disablePin : _enablePin,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pinEnabled
                        ? AppColors.expense.withValues(alpha: isDark ? 0.12 : 0.08)
                        : AppColors.income.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _pinEnabled
                          ? AppColors.expense.withValues(alpha: 0.35)
                          : AppColors.income.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _pinEnabled ? 'Nonaktifkan' : 'Aktifkan',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _pinEnabled ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ),
              ),
            ],),
          ),

          // Baris "Ubah PIN" — hanya tampil jika PIN aktif
          if (_pinEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Divider(height: 1, color: divColor),
            ),
            InkWell(
              onTap: _changePin,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(child: Icon(Icons.edit_rounded,
                        size: 15, color: AppColors.primary,),),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Ubah PIN', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: txtPrim,),),),
                  Icon(Icons.chevron_right_rounded, size: 16,
                      color: isDark ? AppColors.textHintDark : AppColors.textHint,),
                ],),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets (tidak berubah) ──────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final bool isDark;
  final double safeTop;
  final VoidCallback onEdit;
  const _ProfileAppBar({required this.isDark, required this.safeTop, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SliverAppBar(
      expandedHeight: 88, collapsedHeight: 56, pinned: true,
      backgroundColor: bgColor, surfaceTintColor: Colors.transparent,
      elevation: 0, scrolledUnderElevation: 0, automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final isCollapsed = constraints.maxHeight < 72 + safeTop;
        return Stack(clipBehavior: Clip.none, children: [
          AnimatedOpacity(
            opacity: isCollapsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Align(alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, safeTop + 12, 60, 14),
                child: OverflowBox(
                  alignment: Alignment.bottomLeft, maxHeight: double.infinity,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Akun &', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500, color: txtSec,),),
                      Text('Profil', style: TextStyle(fontSize: 26,
                          fontWeight: FontWeight.w800, color: txtPrim,
                          letterSpacing: -0.8, height: 1.1,),),
                    ],),
                ),
              ),),
          ),
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Align(alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 60, 14),
                child: Text('Profil', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w800, color: txtPrim, letterSpacing: -0.6,),),
              ),),
          ),
          Positioned(right: 16, bottom: 10,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.20), width: 0.5),
                ),
                child: const Text('Edit', style: TextStyle(
                    color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700,),),
              ),
            ),),
        ],);
      },),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final bool isDark;
  const _UpgradeBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Icon(Icons.cloud_upload_outlined,
                color: AppColors.warning, size: 18,),),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup data ke cloud', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning,),),
              SizedBox(height: 2),
              Text('Daftar atau masuk untuk menyimpan data', style: TextStyle(
                  fontSize: 11.5, color: AppColors.warning, fontWeight: FontWeight.w400,),),
            ],
          ),),
          const SizedBox(width: 8),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15), shape: BoxShape.circle,),
            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.warning, size: 13),
          ),
        ],),
      ),
    );
  }
}

class _MonthlyStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isDark;
  const _MonthlyStatCard({required this.label, required this.value,
      required this.color, required this.icon, required this.isDark,});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor  = isDark ? AppColors.borderDark : AppColors.border;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: bdrColor),),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              color.withValues(alpha: isDark ? 0.20 : 0.14),
              color.withValues(alpha: isDark ? 0.10 : 0.07),
            ], begin: Alignment.topLeft, end: Alignment.bottomRight,),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.18 : 0.12)),
          ),
          child: Center(child: Icon(icon, color: color, size: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: txtSec, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuart,
            builder: (_, val, __) => Text(CurrencyFormatter.formatCompact(val),
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800,
                  color: color, letterSpacing: -0.4,),),
          ),
        ],),),
      ],),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final Color txtPrim;
  const _SectionTitle({required this.label, required this.txtPrim});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2),),),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700,
          color: txtPrim, letterSpacing: -0.2,),),
    ],);
  }
}

class _GroupItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _GroupItem({
    required this.icon, required this.iconColor,
    required this.label, required this.trailing, this.onTap,
  });
}

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final List<_GroupItem> items;
  const _SettingsGroup({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final bdrColor  = isDark ? AppColors.borderDark : AppColors.border;
    final divColor  = isDark ? AppColors.dividerDark : AppColors.divider;
    final txtPrim   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(color: cardColor,
          borderRadius: BorderRadius.circular(20), border: Border.all(color: bdrColor),),
      child: Column(children: [
        for (int i = 0; i < items.length; i++) ...[
          _SettingsRow(item: items[i], isDark: isDark, txtPrim: txtPrim),
          if (i < items.length - 1)
            Padding(padding: const EdgeInsets.only(left: 60),
                child: Divider(height: 1, color: divColor),),
        ],
      ],),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _GroupItem item;
  final bool isDark;
  final Color txtPrim;
  const _SettingsRow({required this.item, required this.isDark, required this.txtPrim});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: item.iconColor.withValues(alpha: isDark ? 0.15 : 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: Icon(item.icon, size: 15, color: item.iconColor)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(item.label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: txtPrim, letterSpacing: -0.1,),),),
        item.trailing,
      ],),
    );
    if (item.onTap != null) {
      return InkWell(onTap: item.onTap,
          borderRadius: BorderRadius.circular(20), child: content,);
    }
    return content;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isActive, isDark;
  const _StatusPill({required this.label, required this.isActive, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.income : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      ],),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final bool isAnon, isDark;
  final VoidCallback onTap;
  const _LogoutButton({required this.isAnon, required this.isDark, required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: widget.isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.expense.withValues(alpha: 0.30)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.logout_rounded, size: 17, color: AppColors.expense),
            const SizedBox(width: 8),
            Text(widget.isAnon ? 'Keluar (data lokal)' : 'Keluar',
              style: const TextStyle(color: AppColors.expense,
                  fontSize: 14.5, fontWeight: FontWeight.w700,),),
          ],),
        ),
      ),
    );
  }
}