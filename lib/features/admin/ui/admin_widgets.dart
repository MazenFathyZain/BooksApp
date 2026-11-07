import 'package:flutter/material.dart';

import '../../../core/helpers/extension.dart';
import '../../../core/networking/api_error_handler.dart';
import '../../../core/theming/app_colors.dart';

void showAdminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.primaryDark),
  );
}

void showAdminError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ApiErrorFormatter.getMessage(error)),
      backgroundColor: AppColors.error,
    ),
  );
}

/// Asks before a destructive action. Returns true only on an explicit yes.
Future<bool> confirmAdminDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(context.tr('delete')),
            ),
          ],
        ),
  );
  return confirmed == true;
}

/// Full-area message for empty lists and load failures. Scrollable so that
/// pull-to-refresh keeps working on it.
class AdminStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const AdminStateView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        Icon(icon, size: 56, color: AppColors.textHint),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('retry')),
            ),
          ),
        ],
      ],
    );
  }
}

/// Green search field that sits under an admin screen's app bar.
class AdminSearchField extends StatelessWidget implements PreferredSizeWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class AdminRoleBadge extends StatelessWidget {
  final bool isAdmin;

  const AdminRoleBadge({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? AppColors.secondary : AppColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          context.tr(isAdmin ? 'admin' : 'user'),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
