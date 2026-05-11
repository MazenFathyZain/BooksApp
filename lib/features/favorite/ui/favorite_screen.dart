import 'package:book/core/helpers/extension.dart';
import 'package:book/core/helpers/constants.dart';
import 'package:book/features/favorite/logic/favorite_cubit.dart';
import 'package:book/features/home/ui/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final _searchController = TextEditingController();
  final Set<String> _savedBookIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (!isLoggedInUser) {
        context.pushReplacementNamed(Routes.loginScreen);
        return;
      }

      context.read<FavoriteCubit>().getFavoriteBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSaveBook(String bookId) {
    if (_savedBookIds.contains(bookId)) {
      _savedBookIds.remove(bookId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('book_removed')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      _savedBookIds.add(bookId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('book_saved')),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Always refresh the favorite list after toggling
    context.read<FavoriteCubit>().getFavoriteBooks();
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
          context.tr('saved_books'),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => context.read<FavoriteCubit>().getFavoriteBooks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: context.tr('search_saved_books'),
                hintStyle: TextStyle(color: AppColors.whiteOpacity70),
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                suffixIcon: _searchController.text.isNotEmpty
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
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Books List
          Expanded(
            child: BlocBuilder<FavoriteCubit, FavoriteState>(
              builder: (context, state) {
                if (state is FavoriteLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is FavoriteFailed) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<FavoriteCubit>().getFavoriteBooks(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: Text(context.tr('retry')),
                        ),
                      ],
                    ),
                  );
                }

                if (state is FavoriteSuccess) {
                  // Filter based on search
                  var favoriteBooks = state.response.whereType<dynamic>().toList();

                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    favoriteBooks = favoriteBooks.where((book) {
                      final title = (book?.title ?? '').toLowerCase();
                      final author = (book?.author ?? '').toLowerCase();
                      return title.contains(query) || author.contains(query);
                    }).toList();
                  }

                  if (favoriteBooks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isNotEmpty ? Icons.search_off : Icons.bookmark_border,
                            size: 64,
                            color: AppColors.primaryOpacity50,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? context.tr('no_books_found')
                                : context.tr('no_saved_books'),
                            style: TextStyle(
                              color: AppColors.primaryOpacity70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? context.tr('try_different_search')
                                  : context.tr('start_saving_books'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Update saved IDs once
                  if (_savedBookIds.isEmpty) {
                    _savedBookIds.addAll(favoriteBooks.map((book) => book.id));
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context.read<FavoriteCubit>().getFavoriteBooks();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteBooks.length,
                      itemBuilder: (context, index) {
                        final book = favoriteBooks[index];
                        final isSaved = _savedBookIds.contains(book.id);

                        return BookCard(
                          book: book,
                          isSaved: isSaved,
                          onSaveToggle: () => _toggleSaveBook(book.id),
                          onTap: () {
                            context.pushNamed(
                              Routes.bookDetailsScreen,
                              arguments: {
                                'id': book.id,
                                'isSaved': true,
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
