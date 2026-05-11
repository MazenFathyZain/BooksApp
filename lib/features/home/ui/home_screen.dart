import 'package:book/core/helpers/extension.dart';
import 'package:book/core/helpers/constants.dart';
import 'package:book/core/helpers/shared_pref_helper.dart';
import 'package:book/core/helpers/session_helper.dart';
import 'package:book/core/di/dependency_injection.dart';
import 'package:book/features/favorite/data/repos/favorite_repo.dart';
import 'package:book/features/home/logic/home_cubit.dart';
import 'package:book/features/home/ui/widgets/book_card.dart';
import 'package:book/features/home/ui/widgets/book_cover_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../data/models/books_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isCoverOnlyView = false;
  final Set<String> _savedBookIds = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadSavedDisplayMode();
    _loadSavedBookIds();
    context.read<HomeCubit>().fetchCategories();
    context.read<HomeCubit>().fetchAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (_selectedCategory != null) {
      if (query.isEmpty) {
        context.read<HomeCubit>().fetchBooksByCategory(_selectedCategory!);
      } else {
        context.read<HomeCubit>().searchBooksInCategory(
          query,
          _selectedCategory!,
        );
      }
    } else {
      if (query.isEmpty) {
        context.read<HomeCubit>().fetchAllBooks();
      } else {
        context.read<HomeCubit>().searchBooks(query);
      }
    }
  }

  void _applyCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
    });

    if (_selectedCategory == null) {
      if (_searchController.text.isEmpty) {
        context.read<HomeCubit>().fetchAllBooks();
      } else {
        context.read<HomeCubit>().searchBooks(_searchController.text);
      }
    } else {
      if (_searchController.text.isEmpty) {
        context.read<HomeCubit>().fetchBooksByCategory(_selectedCategory!);
      } else {
        context.read<HomeCubit>().searchBooksInCategory(
          _searchController.text,
          _selectedCategory!,
        );
      }
    }
  }

  Future<void> _showCategoryFilterSheet() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('no_categories_available')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOpacity20,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('filter_categories'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategorySheetOption(
                  label: context.tr('all_categories'),
                  isSelected: _selectedCategory == null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _applyCategoryFilter(null);
                  },
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategorySheetOption(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _applyCategoryFilter(category);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSaveBook(String bookId) {
    if (!isLoggedInUser) {
      _confirmLoginRequired('login_to_save_books');
      return;
    }

    final isCurrentlySaved = _savedBookIds.contains(bookId);

    if (isCurrentlySaved) {
      // Remove from favorites
      context.read<HomeCubit>().removeFromFavorite(bookId);
    } else {
      // Add to favorites
      context.read<HomeCubit>().addToFavorite(bookId);
    }
  }

  Future<void> _loadSavedDisplayMode() async {
    final savedView = await SharedPrefHelper.getBool(
      AppConstants.homeDisplayCoverOnly,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCoverOnlyView = savedView == true;
    });
  }

  Future<void> _loadSavedBookIds() async {
    if (!isLoggedInUser) {
      if (!mounted) {
        return;
      }

      if (_savedBookIds.isNotEmpty) {
        setState(() => _savedBookIds.clear());
      }
      return;
    }

    try {
      final favorites = await getIt<FavoriteRepo>().getFavoriteBooks();
      if (!mounted) {
        return;
      }

      setState(() {
        _savedBookIds
          ..clear()
          ..addAll(
            favorites
                .map((book) => book.id)
                .whereType<String>()
                .where((id) => id.isNotEmpty),
          );
      });
    } catch (_) {
      // Ignore: saving is optional, and we don't want to block home loading.
    }
  }

  Future<void> _toggleDisplayMode() async {
    final nextView = !_isCoverOnlyView;

    setState(() {
      _isCoverOnlyView = nextView;
    });

    await SharedPrefHelper.setData(AppConstants.homeDisplayCoverOnly, nextView);
  }

  Future<void> _refreshBooks() async {
    _onSearch(_searchController.text);
  }

  Future<void> _confirmLoginRequired(String messageKey) async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('login_required')),
            content: Text(context.tr(messageKey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr('login')),
              ),
            ],
          ),
    );

    if (shouldLogin == true && mounted) {
      await context.pushNamed(Routes.loginScreen);
    }
  }

  Future<void> _openSavedBooks() async {
    if (!isLoggedInUser) {
      await _confirmLoginRequired('login_to_view_saved_books');
      return;
    }

    await context.pushNamed(Routes.favoriteBooksScreen);
    await _loadSavedBookIds();
  }

  Future<void> _handleAuthAction() async {
    if (!isLoggedInUser) {
      await context.pushNamed(Routes.loginScreen);
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('logout')),
            content: Text(context.tr('logout_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(context.tr('logout')),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      await clearSession();
      if (mounted) {
        context.pushNamedAndRemoveUntil(
          Routes.loginScreen,
          predicate: (route) => false,
        );
      }
    }
  }

  Future<void> _openAddBookScreen() async {
    final didAddBook = await context.pushNamed(
      Routes.dashboardScreen,
      arguments: true,
    );

    if (didAddBook == true && mounted) {
      await _refreshBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('book_added_successfully')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      floatingActionButton:
          isAdmin
              ? FloatingActionButton.extended(
                onPressed: _openAddBookScreen,
                icon: const Icon(Icons.add),
                label: Text(context.tr('add_book')),
              )
              : null,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 0,


        actions: [
          IconButton(
            icon: Icon(
              _isCoverOnlyView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: AppColors.white,
            ),
            onPressed: _toggleDisplayMode,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: AppColors.white),
                onPressed: _openSavedBooks,
              ),
              if (_savedBookIds.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_savedBookIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (previous, current) => current is CategoriesLoaded,
            listener: (context, state) {
              if (state is CategoriesLoaded) {
                setState(() {
                  _categories = state.categories;
                });
              }
            },
          ),
          BlocListener<HomeCubit, HomeState>(
            listenWhen:
                (previous, current) =>
                    current is FavoriteAdded ||
                    current is FavoriteRemoved ||
                    current is FavoriteError,
            listener: (context, state) {
              if (state is FavoriteAdded) {
                setState(() {
                  _savedBookIds.add(state.bookId);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.tr('book_saved'))),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } else if (state is FavoriteRemoved) {
                setState(() {
                  _savedBookIds.remove(state.bookId);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.tr('book_removed'))),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } else if (state is FavoriteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            // Search Bar
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                        _onSearch(value);
                      },
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: context.tr('search_books'),
                        hintStyle: TextStyle(color: AppColors.whiteOpacity70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.white,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppColors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {});
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: AppColors.whiteOpacity20,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: AppColors.whiteOpacity20,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _showCategoryFilterSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 52,
                            height: 52,
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedCategory != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD166),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            BlocBuilder<HomeCubit, HomeState>(
              buildWhen: (previous, current) => current is CategoriesLoading,
              builder: (context, state) {
                if (state is CategoriesLoading && _categories.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Books List
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                buildWhen:
                    (previous, current) =>
                        current is HomeLoading ||
                        current is BooksLoading ||
                        current is BooksLoaded ||
                        current is HomeError,
                builder: (context, state) {
                  if (state is HomeLoading || state is BooksLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (state is HomeError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.message ?? context.tr('unknown_error'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<HomeCubit>().fetchAllBooks();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('retry')),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is BooksLoaded) {
                    final allBooks = state.books ?? [];

                    if (allBooks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: AppColors.primaryOpacity50,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('no_books_found'),
                              style: TextStyle(
                                color: AppColors.primaryOpacity70,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                _selectedCategory != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  context.tr('try_adjusting_filters'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child:
                          _isCoverOnlyView
                              ? _buildBookCoverGrid(allBooks)
                              : _buildBookList(allBooks),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySheetOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primaryOpacity10 : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.primaryOpacity20,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookList(List<BooksResponse?> allBooks) {
    return ListView.builder(
      key: const PageStorageKey('home-book-list'),
      padding: const EdgeInsets.all(16),
      itemCount: allBooks.length,
      itemBuilder: (context, index) {
        final book = allBooks[index];
        final bookId = book?.id ?? '';
        final isSaved = _savedBookIds.contains(bookId);

        return BookCard(
          book: book,
          isSaved: isSaved,
          onSaveToggle: () {
            if (bookId.isNotEmpty) {
              _toggleSaveBook(bookId);
            }
          },
          onTap: () => _openBookDetails(bookId),
        );
      },
    );
  }

  Widget _buildBookCoverGrid(List<BooksResponse?> allBooks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= 1000
                ? 5
                : constraints.maxWidth >= 720
                ? 4
                : constraints.maxWidth >= 520
                ? 3
                : 2;

        return GridView.builder(
          key: const PageStorageKey('home-book-cover-grid'),
          padding: const EdgeInsets.all(16),
          itemCount: allBooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.64,
          ),
          itemBuilder: (context, index) {
            final book = allBooks[index];
            final bookId = book?.id ?? '';

            return BookCoverTile(
              book: book,
              onTap: () => _openBookDetails(bookId),
            );
          },
        );
      },
    );
  }

  void _openBookDetails(String bookId) {
    if (bookId.isEmpty) {
      return;
    }

    context
        .pushNamed(
          Routes.bookDetailsScreen,
          arguments: {
            'id': bookId,
            'isSaved': _savedBookIds.contains(bookId),
          },
        )
        .then((_) => _loadSavedBookIds());
  }
}
