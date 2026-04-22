// Anonymous Login Button
import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';

class AnonymousLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AnonymousLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
        label: Text(
          isLoading ? '...' : '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
