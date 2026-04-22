import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Color? selectedBackgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? borderColor;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = selectedBackgroundColor ?? AppColors.primary;
    final unselectedBg = unselectedBackgroundColor ?? AppColors.white;
    final selectedFg = selectedTextColor ?? AppColors.white;
    final unselectedFg = unselectedTextColor ?? AppColors.primary;
    final chipBorderColor = borderColor ?? AppColors.primary;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: chipBorderColor, width: 1),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primaryOpacity30,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedFg : unselectedFg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
