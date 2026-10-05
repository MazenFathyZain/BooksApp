import 'package:book/core/helpers/extension.dart';
import 'package:book/core/helpers/constants.dart';
import 'package:book/core/helpers/shared_pref_helper.dart';
import 'package:book/core/di/dependency_injection.dart';
import 'package:book/features/downloads/data/downloaded_book.dart';
import 'package:book/features/downloads/data/downloaded_books_repo.dart';
import 'package:book/features/downloads/ui/downloaded_books_screen.dart';
import 'package:book/features/favorite/data/repos/favorite_repo.dart';
import 'package:book/features/home/logic/home_cubit.dart';
import 'package:book/features/home/ui/widgets/book_card.dart';
import 'package:book/features/home/ui/widgets/book_cover_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/localization_cubit.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../data/models/books_response.dart';
import '../data/models/category_tree_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  CategoryTreeResponse? _selectedCategory;
  CategoryTreeResponse? _selectedSubCategory;
  bool _isCoverOnlyView = false;
  bool _offlineSnackShown = false;
  final Set<String> _savedBookIds = {};
  List<CategoryTreeResponse> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadSavedDisplayMode();
    _loadSavedBookIds();
    context.read<HomeCubit>().setLanguageCode(context.currentLanguage);
    context.read<HomeCubit>().fetchCategories();
    context.read<HomeCubit>().fetchAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (_selectedCategory != null) {
      if (query.isEmpty) {
        await context.read<HomeCubit>().fetchBooksByCategory(
          _selectedCategory!.id,
          subCategoryId: _selectedSubCategory?.id,
        );
      } else {
        await context.read<HomeCubit>().searchBooksInCategory(
          query,
          _selectedCategory!.id,
          subCategoryId: _selectedSubCategory?.id,
        );
      }
    } else {
      if (query.isEmpty) {
        await context.read<HomeCubit>().fetchAllBooks();
      } else {
        await context.read<HomeCubit>().searchBooks(query);
      }
    }
  }

  void _applyCategoryFilter(
    CategoryTreeResponse? category, {
    CategoryTreeResponse? subCategory,
  }) {
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = subCategory;
    });

    if (_selectedCategory == null) {
      if (_searchController.text.isEmpty) {
        context.read<HomeCubit>().fetchAllBooks();
      } else {
        context.read<HomeCubit>().searchBooks(_searchController.text);
      }
    } else {
      if (_searchController.text.isEmpty) {
        context.read<HomeCubit>().fetchBooksByCategory(
          _selectedCategory!.id,
          subCategoryId: _selectedSubCategory?.id,
        );
      } else {
        context.read<HomeCubit>().searchBooksInCategory(
          _searchController.text,
          _selectedCategory!.id,
          subCategoryId: _selectedSubCategory?.id,
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

    CategoryTreeResponse? pendingCategory = _selectedCategory;
    CategoryTreeResponse? pendingSubCategory =
        pendingCategory?.id == _selectedCategory?.id
            ? _selectedSubCategory
            : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final pendingSubCategories = pendingCategory?.children ?? const [];

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOpacity10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('filter_categories'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterSectionHeader(
                                icon: Icons.category_rounded,
                                label: context.tr('select_category'),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _categories.map((category) {
                                      return _buildFilterChoiceChip(
                                        label: category.name,
                                        count: category.children.length,
                                        isSelected:
                                            pendingCategory?.id == category.id,
                                        onTap: () {
                                          setSheetState(() {
                                            pendingCategory = category;
                                            pendingSubCategory = null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 22),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child:
                                    pendingCategory == null
                                        ? _buildEmptyFilterHint(
                                          context.tr('select_category'),
                                        )
                                        : Column(
                                          key: ValueKey(pendingCategory!.id),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFilterSectionHeader(
                                              icon: Icons.account_tree_rounded,
                                              label: context.tr(
                                                'select_sub_category',
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _buildFilterChoiceChip(
                                              label: context.tr(
                                                'all_books_in_category',
                                              ),
                                              isSelected:
                                                  pendingSubCategory == null,
                                              isWide: true,
                                              onTap: () {
                                                setSheetState(() {
                                                  pendingSubCategory = null;
                                                });
                                              },
                                            ),
                                            if (pendingSubCategories
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                    pendingSubCategories.map((
                                                      subCategory,
                                                    ) {
                                                      return _buildFilterChoiceChip(
                                                        label: subCategory.name,
                                                        isSelected:
                                                            pendingSubCategory
                                                                ?.id ==
                                                            subCategory.id,
                                                        onTap: () {
                                                          setSheetState(() {
                                                            pendingSubCategory =
                                                                subCategory;
                                                          });
                                                        },
                                                      );
                                                    }).toList(),
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 10),
                                              _buildEmptyFilterHint(
                                                context.tr(
                                                  'no_sub_categories_available',
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _applyCategoryFilter(null);
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: Text(context.tr('all_categories')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  pendingCategory == null
                                      ? null
                                      : () {
                                        Navigator.pop(sheetContext);
                                        _applyCategoryFilter(
                                          pendingCategory,
                                          subCategory: pendingSubCategory,
                                        );
                                      },
                              icon: const Icon(Icons.check_rounded),
                              label: Text(context.tr('apply')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    _offlineSnackShown = false;
    await context.read<HomeCubit>().fetchCategories();
    await _onSearch(_searchController.text);
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

  Future<void> _openAddBookScreen() async {
    final didAddBook = await context.pushNamed(
      Routes.dashboardScreen,
      arguments: true,
    );

    if (didAddBook == true && mounted) {
      context.read<HomeCubit>().fetchCategories();
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

  String _activeFilterLabel() {
    final category = _selectedCategory;
    if (category == null) {
      return '';
    }

    final subCategory = _selectedSubCategory;
    if (subCategory == null) {
      return category.name;
    }

    return '${category.name} / ${subCategory.name}';
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
          BlocListener<LocaleCubit, LocaleState>(
            listener: (context, state) {
              if (state is LocaleChanged) {
                context.read<HomeCubit>().setLanguageCode(
                  state.locale.languageCode,
                );
                setState(() {
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                });
                context.read<HomeCubit>().fetchCategories();
                context.read<HomeCubit>().fetchAllBooks();
              }
            },
          ),
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
                    current is HomeError || current is BooksLoaded,
            listener: (context, state) {
              if (state is BooksLoaded) {
                _offlineSnackShown = false;
                return;
              }

              if (state is HomeError && !_offlineSnackShown) {
                _offlineSnackShown = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('no_internet_connection')),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                            hintStyle: TextStyle(
                              color: AppColors.whiteOpacity70,
                            ),
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
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: AppColors.whiteOpacity20,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => _applyCategoryFilter(null),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.filter_alt_rounded,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _activeFilterLabel(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    return _buildOfflineDownloadsOrError(state);
                  }

                  if (state is BooksLoaded) {
                    final allBooks = state.books ?? [];

                    if (allBooks.isEmpty) {
                      return _buildRefreshable(
                        Center(
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
                        ),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 420 &&
                            state.pagination.hasNextPage &&
                            !state.isLoadingMore) {
                          context.read<HomeCubit>().loadNextBooksPage();
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refreshBooks,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child:
                              _isCoverOnlyView
                                  ? _buildBookCoverGrid(
                                    allBooks,
                                    isLoadingMore: state.isLoadingMore,
                                  )
                                  : _buildBookList(
                                    allBooks,
                                    isLoadingMore: state.isLoadingMore,
                                  ),
                        ),
                      ),
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

  Widget _buildOfflineDownloadsOrError(HomeError state) {
    return FutureBuilder<List<DownloadedBook>>(
      future: DownloadedBooksRepo().getDownloadedBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final downloadedBooks = snapshot.data ?? const [];
        if (downloadedBooks.isEmpty) {
          return _buildRefreshable(
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message ?? context.tr('no_internet_connection'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshBooks,
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
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshBooks,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: downloadedBooks.length,
            itemBuilder: (context, index) {
              final downloadedBook = downloadedBooks[index];
              return DownloadedBookTile(
                downloadedBook: downloadedBook,
                onTap: () => _openDownloadedBook(downloadedBook),
                onRemove: () => _removeDownloadedBook(downloadedBook),
              );
            },
          ),
        );
      },
    );
  }

  void _openDownloadedBook(DownloadedBook downloadedBook) {
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

  Future<void> _removeDownloadedBook(DownloadedBook downloadedBook) async {
    await DownloadedBooksRepo().removeDownloadedBook(downloadedBook);
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('downloaded_book_removed')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildFilterSectionHeader({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
    bool isWide = false,
  }) {
    return Material(
      color: isSelected ? AppColors.primaryOpacity10 : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 42,
            maxWidth: isWide ? double.infinity : 240,
          ),
          child: Container(
            width: isWide ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.primaryOpacity20,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.primaryOpacity10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterHint(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryOpacity10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryOpacity20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshable(Widget child) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBooks,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookList(
    List<BooksResponse?> allBooks, {
    bool isLoadingMore = false,
  }) {
    return ListView.builder(
      key: const PageStorageKey('home-book-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: allBooks.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= allBooks.length) {
          return _buildLoadMoreIndicator();
        }

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

  Widget _buildBookCoverGrid(
    List<BooksResponse?> allBooks, {
    bool isLoadingMore = false,
  }) {
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: allBooks.length + (isLoadingMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.64,
          ),
          itemBuilder: (context, index) {
            if (index >= allBooks.length) {
              return _buildLoadMoreIndicator();
            }

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

  Widget _buildLoadMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _openBookDetails(String bookId) async {
    if (bookId.isEmpty) {
      return;
    }

    final didChange = await context.pushNamed(
      Routes.bookDetailsScreen,
      arguments: {'id': bookId, 'isSaved': _savedBookIds.contains(bookId)},
    );

    await _loadSavedBookIds();
    if (didChange == true && mounted) {
      await _refreshBooks();
    }
  }
}
