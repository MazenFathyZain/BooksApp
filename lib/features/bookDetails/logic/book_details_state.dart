part of 'book_details_cubit.dart';

@immutable
sealed class BookDetailsState {}

final class BookDetailsInitial extends BookDetailsState {}
final class BookDetailsLoading extends BookDetailsState {}
final class BookDetailsSuccess extends BookDetailsState {
  final BooksResponse response;
  BookDetailsSuccess(this.response);
}
final class BookDetailsFailed extends BookDetailsState {
  final String error;
  BookDetailsFailed(this.error);
}
