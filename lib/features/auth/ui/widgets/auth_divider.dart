// Auth Divider with Text
import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';

class AuthDivider extends StatelessWidget {
  final String textKey;

  const AuthDivider({Key? key, required this.textKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.primary.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            textKey,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.primary.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
