import 'package:bloc/bloc.dart';
import 'package:book/features/home/data/models/add_favorite_request.dart';
import 'package:book/features/home/data/repos/home_repo.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:book/features/home/data/models/category_tree_response.dart';
import 'package:flutter/foundation.dart';

import '../../../core/helpers/book_language.dart';
import '../../../core/networking/api_error_handler.dart';
import '../../../core/networking/connectivity_service.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepo _repo;
  final ConnectivityService _connectivity;
  List<BooksResponse>? _currentBooks;
  BooksPagination _pagination = const BooksPagination();
  String _language = bookLanguageApiValueFromCode('tg');
  String? _currentSearch;
  String? _currentCategoryId;
  String? _currentSubCategoryId;
  bool _isLoadingMore = false;
  static const int _pageLimit = 10;

  HomeCubit(this._repo, this._connectivity) : super(HomeInitial());

  /// Requests can finish after the home screen is closed (slow or offline
  /// server). Drop those late results instead of crashing.
  @override
  void emit(HomeState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<HomeError> _errorFor(Object error) async {
    final isConnectionError = ConnectivityService.isConnectionError(error);
    final hasInternet = await _connectivity.hasInternet();
    return HomeError(
      ApiErrorFormatter.getMessage(error),
      isOffline: !hasInternet,
      isServerUnreachable: hasInternet && isConnectionError,
    );
  }

  void setLanguageCode(String languageCode) {
    _language = bookLanguageApiValueFromCode(languageCode);
  }

  // Get all books (no filters)
  Future<void> fetchAllBooks() async {
    await _fetchBooks();
  }

  // Get all categories
  Future<void> fetchCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await _repo.getCategoryTree(language: _language);
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(await _errorFor(e));
    }
  }

  // Get books by category
  Future<void> fetchBooksByCategory(
    String categoryId, {
    String? subCategoryId,
  }) async {
    await _fetchBooks(categoryId: categoryId, subCategoryId: subCategoryId);
  }

  // Search books
  Future<void> searchBooks(String query) async {
    await _fetchBooks(search: query);
  }

  // Search books with category filter
  Future<void> searchBooksInCategory(
    String query,
    String categoryId, {
    String? subCategoryId,
  }) async {
    await _fetchBooks(
      search: query,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
  }

  Future<void> loadNextBooksPage() async {
    if (_isLoadingMore || !_pagination.hasNextPage) {
      return;
    }

    _isLoadingMore = true;
    emit(
      BooksLoaded(_currentBooks, pagination: _pagination, isLoadingMore: true),
    );

    try {
      final nextPage = _pagination.currentPage + 1;
      final response = await _repo.getAllBooks(
        _currentSearch,
        _currentCategoryId,
        _currentSubCategoryId,
        _language,
        nextPage,
        _pageLimit,
      );
      _currentBooks = [...?_currentBooks, ...response.books];
      _pagination = response.pagination;
      emit(BooksLoaded(_currentBooks, pagination: _pagination));
    } catch (e) {
      emit(await _errorFor(e));
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _fetchBooks({
    String? search,
    String? categoryId,
    String? subCategoryId,
  }) async {
    emit(BooksLoading());
    _currentSearch = search?.trim().isEmpty == true ? null : search;
    _currentCategoryId = categoryId;
    _currentSubCategoryId = subCategoryId;

    try {
      final response = await _repo.getAllBooks(
        _currentSearch,
        _currentCategoryId,
        _currentSubCategoryId,
        _language,
        1,
        _pageLimit,
      );
      _currentBooks = response.books;
      _pagination = response.pagination;
      emit(BooksLoaded(_currentBooks, pagination: _pagination));
    } catch (e) {
      emit(await _errorFor(e));
    }
  }

  // Add To Favorite
  Future<void> addToFavorite(String id) async {
    try {
      await _repo.addToFavorite(AddFavoriteRequest(bookId: id));
      emit(FavoriteAdded(id));
      // Re-emit current books to maintain the list state
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks, pagination: _pagination));
      }
    } catch (e) {
      emit(FavoriteError(ApiErrorFormatter.getMessage(e)));
      // Re-emit current books even if favorite failed
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks, pagination: _pagination));
      }
    }
  }

  // Remove From Favorite
  Future<void> removeFromFavorite(String id) async {
    try {
      // If you have a remove API endpoint, uncomment and use it:
      // await _repo.removeFromFavorite(id);

      emit(FavoriteRemoved(id));
      // Re-emit current books to maintain the list state
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks, pagination: _pagination));
      }
    } catch (e) {
      emit(FavoriteError(ApiErrorFormatter.getMessage(e)));
      // Re-emit current books even if unfavorite failed
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks, pagination: _pagination));
      }
    }
  }
}
