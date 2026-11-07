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
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book?.title ?? context.tr('no_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
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
                          tooltip: context.tr('saved_books'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('by')} ${book?.author ?? context.tr('unknown')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((book?.category ?? "").isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOpacity10,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          [book?.category, book?.subCategory]
                              .whereType<String>()
                              .where((v) => v.isNotEmpty)
                              .join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      book?.description ??
                          context.tr('no_description_available'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
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
