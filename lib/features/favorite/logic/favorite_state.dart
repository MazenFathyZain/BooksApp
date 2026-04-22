part of 'favorite_cubit.dart';

@immutable
sealed class FavoriteState {}

final class FavoriteInitial extends FavoriteState {}
final class FavoriteLoading extends FavoriteState {}
final class FavoriteSuccess extends FavoriteState {
  final List<BooksResponse> response;
  FavoriteSuccess(this.response);
}
final class FavoriteFailed extends FavoriteState {
  final String message;
  FavoriteFailed(this.message);
}
