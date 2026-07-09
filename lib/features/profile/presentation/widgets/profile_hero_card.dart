import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../shared/widgets/spendly_card.dart';

class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String? photoPath;
  final double balance;
  final bool isAnon;
  final String? userEmail;

  const ProfileHeroCard({
    super.key,
    required this.name,
    required this.avatar,
    required this.photoPath,
    required this.balance,
    required this.isAnon,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Akun Saya' : name;

    return SpendlyCard(
      gradient: AppColors.primaryGradient,
      elevated: true,
      glowColor: AppColors.primary,
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Stack(children: [
        // Decorative circles
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: 100,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              ProfileAvatarWidget(
                  photoPath: photoPath, avatar: avatar, size: 64,),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAnon ? AppColors.warning : AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isAnon ? 'Mode Tamu' : (userEmail ?? ''),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],),
                  ],
                ),
              ),
            ],),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
            const SizedBox(height: 16),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Total Saldo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ],),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Aktif',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),),
                ],),
              ),
            ],),
          ],),
        ),
      ],),
    );
  }
}

class ProfileAvatarWidget extends StatelessWidget {
  final String? photoPath;
  final String avatar;
  final double size;

  const ProfileAvatarWidget({
    super.key,
    required this.photoPath,
    required this.avatar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photoPath != null
            ? Image.file(File(photoPath!), fit: BoxFit.cover)
            : Center(
                child: Text(
                  avatar.isEmpty ? '😎' : avatar,
                  style: TextStyle(fontSize: size * 0.40),
                ),
              ),
      ),
    );
  }
}
