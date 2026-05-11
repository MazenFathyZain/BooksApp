import 'package:flutter/material.dart';

import '../../../../core/helpers/media_url_helper.dart';
import '../../../../core/theming/app_colors.dart';

class BookCoverImage extends StatelessWidget {
  final String? imageUrl;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    this.fit = BoxFit.cover,
  });

  String? get _resolvedImageUrl {
    return resolveMediaUrl(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = _resolvedImageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: AppColors.primaryOpacity10,
        child:
            resolvedImageUrl == null
                ? const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                )
                : Image.network(
                  resolvedImageUrl,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
