import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';
import '../../data/models/books_response.dart';
import 'book_cover_image.dart';

class BookCoverTile extends StatelessWidget {
  final BooksResponse? book;
  final VoidCallback onTap;

  const BookCoverTile({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(16));

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: BookCoverImage(
              imageUrl: book?.imageUrl,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
