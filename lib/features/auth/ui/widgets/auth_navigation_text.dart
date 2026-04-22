// Auth Navigation Text
import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';

class AuthNavigationText extends StatelessWidget {
  final String questionKey;
  final String actionKey;
  final VoidCallback onPressed;

  const AuthNavigationText({
    Key? key,
    required this.questionKey,
    required this.actionKey,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionKey,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionKey,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
