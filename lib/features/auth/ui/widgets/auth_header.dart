// Auth Header Widget
import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final Color iconBackgroundColor;

  const AuthHeader({
    Key? key,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    this.iconBackgroundColor = const Color(0xFF8B4513),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconBackgroundColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 60,
            color: const Color(0xFFF5F1E8),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          titleKey,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleKey,
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF5D4037).withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}