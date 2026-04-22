part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class BooksLoading extends HomeState {}

final class CategoriesLoading extends HomeState {}

final class BooksLoaded extends HomeState {
  final List<BooksResponse?>? books;
  BooksLoaded(this.books);
}

final class CategoriesLoaded extends HomeState {
  final List<String> categories;
  CategoriesLoaded(this.categories);
}

final class HomeError extends HomeState {
  final String? message;
  HomeError(this.message);
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