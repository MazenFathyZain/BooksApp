part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class BooksLoading extends HomeState {}

final class CategoriesLoading extends HomeState {}

final class BooksLoaded extends HomeState {
  final List<BooksResponse?>? books;
  final BooksPagination pagination;
  final bool isLoadingMore;

  BooksLoaded(
    this.books, {
    this.pagination = const BooksPagination(),
    this.isLoadingMore = false,
  });
}

final class CategoriesLoaded extends HomeState {
  final List<CategoryTreeResponse> categories;
  CategoriesLoaded(this.categories);
}

final class HomeError extends HomeState {
  final String? message;

  /// True when the request failed because there is no internet connection.
  final bool isOffline;

  HomeError(this.message, {this.isOffline = false});
}

final class FavoriteAdded extends HomeState {
  final String bookId;
  FavoriteAdded(this.bookId);
}

final class FavoriteRemoved extends HomeState {
  final String bookId;
  FavoriteRemoved(this.bookId);
}

final class FavoriteError extends HomeState {
  final String message;
  FavoriteError(this.message);
}
