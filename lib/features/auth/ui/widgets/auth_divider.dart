
// Auth Divider with Text
import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String textKey;

  const AuthDivider({Key? key, required this.textKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: const Color(0xFF5D4037).withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            textKey,
            style: TextStyle(
              color: const Color(0xFF5D4037).withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: const Color(0xFF5D4037).withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}