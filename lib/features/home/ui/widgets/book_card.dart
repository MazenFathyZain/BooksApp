import 'package:book/core/helpers/extension.dart';
import 'package:flutter/material.dart';

import '../../../../core/theming/app_colors.dart';
import '../../data/models/books_response.dart';
import 'book_cover_image.dart';

class BookCard extends StatelessWidget {
  final BooksResponse? book;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 120,
                child: BookCoverImage(
                  imageUrl: book?.imageUrl,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book?.title ?? "No Title",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: AppColors.primary,
                          ),
                          onPressed: onSaveToggle,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('by')} ${book?.author ?? "Unknown"}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((book?.category ?? "").isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOpacity10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book?.category ?? "Uncategorized",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if ((book?.category ?? "").isNotEmpty)
                      const SizedBox(height: 8),
                    Text(
                      book?.description ?? "No description available.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
