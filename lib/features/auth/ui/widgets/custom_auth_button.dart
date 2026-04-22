// Custom Auth Button
import 'package:flutter/material.dart';

class CustomAuthButton extends StatelessWidget {
  final String textKey;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomAuthButton({
    Key? key,
    required this.textKey,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          textKey,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}