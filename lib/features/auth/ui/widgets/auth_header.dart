// Auth Header Widget
import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final IconData? icon;
  final String? imageAssetPath;
  final String titleKey;
  final String subtitleKey;
  final Color iconBackgroundColor;

  const AuthHeader({
    Key? key,
    this.icon,
    this.imageAssetPath,
    required this.titleKey,
    required this.subtitleKey,
    this.iconBackgroundColor = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child:
              imageAssetPath != null
                  ? Image.asset(imageAssetPath!, fit: BoxFit.contain)
                  : Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ?? Icons.menu_book_rounded,
                      size: 60,
                      color: AppColors.white,
                    ),
                  ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          titleKey,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleKey,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
