import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/profile_screen.dart' show profileProvider;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  String? _photoPath;
  String _avatar = '😎';
  bool _isLoading = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;

  static const _avatarEmojis = [
    '😎',
    '🦁',
    '🐯',
    '🦊',
    '🐻',
    '🐼',
    '🐸',
    '🦄',
    '🐙',
    '🦋',
    '🌟',
    '🚀',
  ];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _nameFocus.addListener(() => setState(() {}));
    final p = ref.read(profileProvider);
    _nameCtrl.text = p.name;
    _photoPath = p.photoPath;
    _avatar = p.avatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;
    final picker = ImagePicker();

    final result = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: bdrColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ganti Foto Profil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: txtPrim,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            _BottomSheetTile(
              icon: Icons.camera_alt_rounded,
              iconColor: AppColors.primary,
              label: 'Ambil Foto',
              txtPrim: txtPrim,
              isDark: isDark,
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (mounted) Navigator.pop(context, img);
              },
            ),
            _BottomSheetTile(
              icon: Icons.photo_library_rounded,
              iconColor: AppColors.accentPurple,
              label: 'Dari Galeri',
              txtPrim: txtPrim,
              isDark: isDark,
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (mounted) Navigator.pop(context, img);
              },
            ),
            if (_photoPath != null)
              _BottomSheetTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.expense,
                label: 'Hapus Foto',
                txtPrim: AppColors.expense,
                isDark: isDark,
                onTap: () => Navigator.pop(context, null),
              ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _photoPath = result.path;
        _avatar = '';
      });
    } else if (result == null && _photoPath != null) {
      setState(() => _photoPath = null);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama tidak boleh kosong'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(profileProvider.notifier).save(
          name: name,
          avatar: _avatar.isEmpty ? '😎' : _avatar,
          photoPath: _photoPath,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtHint = isDark ? AppColors.textHintDark : AppColors.textHint;
    final isFocused = _nameFocus.hasFocus;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Back button ──────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: surfColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: bdrColor, width: 0.5),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: txtPrim,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Title ────────────────────────────────────────────────
              Text(
                'Edit Profil',
                style: TextStyle(
                  color: txtPrim,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        // ── Save action ────────────────────────────────────────────────
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _entranceFade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar Picker ────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _EditableAvatar(
                    photoPath: _photoPath,
                    avatar: _avatar,
                    isDark: isDark,
                    bgColor: bgColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap untuk ganti foto',
                  style: TextStyle(
                    fontSize: 12,
                    color: txtSec,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Name field ───────────────────────────────────────────────
              _FieldLabel(
                label: 'Nama',
                color: isFocused ? AppColors.primary : txtSec,
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: surfColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary.withOpacity(0.55)
                        : bdrColor,
                    width: isFocused ? 1.5 : 1,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.09),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  style: TextStyle(
                    color: txtPrim,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama kamu',
                    hintStyle: TextStyle(color: txtHint, fontSize: 14),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: isFocused ? AppColors.primary : txtSec,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    fillColor: Colors.transparent,
                    filled: false,
                    isDense: true,
                  ),
                ),
              ),

              // ── Avatar grid ──────────────────────────────────────────────
              if (_photoPath == null) ...[
                const SizedBox(height: 28),
                _FieldLabel(label: 'Pilih Avatar', color: txtSec),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: _avatarEmojis.map((e) {
                    final sel = e == _avatar;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _avatar = e;
                        _photoPath = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary
                                        .withOpacity(isDark ? 0.22 : 0.14),
                                    AppColors.accentPurple
                                        .withOpacity(isDark ? 0.14 : 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: sel ? null : surfColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel
                                ? AppColors.primary.withOpacity(0.55)
                                : bdrColor,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            e,
                            style: TextStyle(fontSize: sel ? 24 : 22),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────────
              _SaveButton(
                isLoading: _isLoading,
                onTap: _isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Editable Avatar ──────────────────────────────────────────────────────────

class _EditableAvatar extends StatelessWidget {
  final String? photoPath;
  final String avatar;
  final bool isDark;
  final Color bgColor;

  const _EditableAvatar({
    required this.photoPath,
    required this.avatar,
    required this.isDark,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: photoPath == null ? AppColors.primaryGradient : null,
            color: photoPath != null
                ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                : null,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.50),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipOval(
            child: photoPath != null
                ? Image.file(File(photoPath!), fit: BoxFit.cover)
                : Center(
                    child: Text(
                      avatar.isEmpty ? '😎' : avatar,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: bgColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _FieldLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ─── Bottom Sheet Tile ────────────────────────────────────────────────────────

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color txtPrim;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomSheetTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.txtPrim,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Icon(icon, size: 17, color: iconColor)),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: txtPrim,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _SaveButton({required this.isLoading, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color.lerp(
                          AppColors.primary, AppColors.accentPurple, 0.4)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.isLoading ? AppColors.primary.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Simpan Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
