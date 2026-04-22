// Auth Navigation Text
import 'package:flutter/material.dart';

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
            color: const Color(0xFF5D4037).withOpacity(0.7),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionKey,
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}