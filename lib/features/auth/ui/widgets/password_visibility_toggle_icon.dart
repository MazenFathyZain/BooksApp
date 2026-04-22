// Password Visibility Toggle Icon
import 'package:flutter/material.dart';

class PasswordVisibilityIcon extends StatelessWidget {
  final bool obscureText;
  final VoidCallback onPressed;

  const PasswordVisibilityIcon({
    Key? key,
    required this.obscureText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: const Color(0xFF8B4513),
      ),
      onPressed: onPressed,
    );
  }
}

