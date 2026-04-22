import 'package:bloc/bloc.dart';
import 'package:book/features/home/data/models/add_favorite_request.dart';
import 'package:book/features/home/data/repos/home_repo.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:meta/meta.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepo _repo;
  List<BooksResponse>? _currentBooks;

  HomeCubit(this._repo) : super(HomeInitial());

  // Get all books (no filters)
  Future<void> fetchAllBooks() async {
    emit(HomeLoading());
    try {
      final books = await _repo.getAllBooks(null, null);
      _currentBooks = books;
      emit(BooksLoaded(books));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // Get all categories
  Future<void> fetchCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await _repo.getAllBooksCategories();
      // Convert dynamic list to List<String>
      final categoryStrings = categories.map((e) => e.toString()).toList();
      emit(CategoriesLoaded(categoryStrings));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // Get books by category
  Future<void> fetchBooksByCategory(String category) async {
    emit(BooksLoading());
    try {
      final books = await _repo.getAllBooks(null, category);
      _currentBooks = books;
      emit(BooksLoaded(books));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // Search books
  Future<void> searchBooks(String query) async {
    emit(BooksLoading());
    try {
      final books = await _repo.getAllBooks(query, null);
      _currentBooks = books;
      emit(BooksLoaded(books));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // Search books with category filter
  Future<void> searchBooksInCategory(String query, String category) async {
    emit(BooksLoading());
    try {
      final books = await _repo.getAllBooks(query, category);
      _currentBooks = books;
      emit(BooksLoaded(books));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // Add To Favorite
  Future<void> addToFavorite(String id) async {
    try {
      await _repo.addToFavorite(AddFavoriteRequest(bookId: id));
      emit(FavoriteAdded(id));
      // Re-emit current books to maintain the list state
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks));
      }
    } catch (e) {
      emit(FavoriteError(e.toString()));
      // Re-emit current books even if favorite failed
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks));
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
        emit(BooksLoaded(_currentBooks));
      }
    } catch (e) {
      emit(FavoriteError(e.toString()));
      // Re-emit current books even if unfavorite failed
      if (_currentBooks != null) {
        emit(BooksLoaded(_currentBooks));
      }
    }
  }
}