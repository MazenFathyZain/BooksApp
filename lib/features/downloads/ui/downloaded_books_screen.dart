import 'package:book/core/helpers/extension.dart';
import 'package:book/core/routing/routes.dart';
import 'package:book/core/theming/app_colors.dart';
import 'package:book/core/widgets/app_drawer.dart';
import 'package:book/features/downloads/data/downloaded_book.dart';
import 'package:book/features/downloads/data/downloaded_books_repo.dart';
import 'dart:io';

import 'package:book/features/home/ui/widgets/book_cover_image.dart';
import 'package:flutter/material.dart';

class DownloadedBooksScreen extends StatefulWidget {
  const DownloadedBooksScreen({super.key});

  @override
  State<DownloadedBooksScreen> createState() => _DownloadedBooksScreenState();
}

class _DownloadedBooksScreenState extends State<DownloadedBooksScreen> {
  final _repo = DownloadedBooksRepo();
  final _searchController = TextEditingController();
  late Future<List<DownloadedBook>> _downloadedBooksFuture;

  @override
  void initState() {
    super.initState();
    _downloadedBooksFuture = _repo.getDownloadedBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _downloadedBooksFuture = _repo.getDownloadedBooks();
    });
  }

  void _openBook(DownloadedBook downloadedBook) {
    Navigator.pushNamed(
      context,
      Routes.pdf,
      arguments: {
        'pdfUrl': downloadedBook.localPdfPath,
        'title': downloadedBook.book.title,
        'isLocal': true,
      },
    );
  }

  Future<void> _removeBook(DownloadedBook downloadedBook) async {
    await _repo.removeDownloadedBook(downloadedBook);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('downloaded_book_removed')),
        backgroundColor: AppColors.error,
      ),
    );
    _reload();
  }

  List<DownloadedBook> _filterBooks(List<DownloadedBook> books) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return books;
    }

    return books.where((item) {
      final book = item.book;
      return [
        book.title,
        book.author,
        book.category,
        book.subCategory,
        book.description,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          context.tr('downloaded_books'),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: context.tr('search_downloaded_books'),
                hintStyle: TextStyle(color: AppColors.whiteOpacity70),
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.white),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppColors.whiteOpacity20,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DownloadedBook>>(
              future: _downloadedBooksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final books = _filterBooks(snapshot.data ?? const []);
                if (books.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    itemBuilder:
                        (context, index) => DownloadedBookTile(
                          downloadedBook: books[index],
                          onTap: () => _openBook(books[index]),
                          onRemove: () => _removeBook(books[index]),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.download_done_rounded,
              size: 64,
              color: AppColors.primaryOpacity50,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? context.tr('no_books_found')
                  : context.tr('no_downloaded_books'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryOpacity70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? context.tr('try_different_search')
                  : context.tr('download_books_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadedBookTile extends StatelessWidget {
  final DownloadedBook downloadedBook;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const DownloadedBookTile({
    super.key,
    required this.downloadedBook,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final book = downloadedBook.book;
    final categoryLabel = [
      book.category,
      book.subCategory,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' / ');

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
                child: _DownloadedBookCover(downloadedBook: downloadedBook),
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
                            book.title ?? context.tr('no_title'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('delete'),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: onRemove,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('by')} ${book.author ?? context.tr('unknown')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                          categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.offline_pin_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('available_offline'),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _DownloadedBookCover extends StatelessWidget {
  final DownloadedBook downloadedBook;

  const _DownloadedBookCover({required this.downloadedBook});

  @override
  Widget build(BuildContext context) {
    final localImagePath = downloadedBook.localImagePath;
    if (localImagePath != null &&
        localImagePath.isNotEmpty &&
        File(localImagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(localImagePath), fit: BoxFit.cover),
      );
    }

    return BookCoverImage(
      imageUrl: downloadedBook.book.imageUrl,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
