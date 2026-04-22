import 'package:bloc/bloc.dart';
import 'package:book/features/bookDetails/data/repos/book_details_repo.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:meta/meta.dart';

part 'book_details_state.dart';

class BookDetailsCubit extends Cubit<BookDetailsState> {
  final BookDetailsRepo _repo;
  BookDetailsCubit(this._repo) : super(BookDetailsInitial());

  getBookById(String id) async {
    emit(BookDetailsLoading());
    try {
      final response = await _repo.getBookById(id);
      emit(BookDetailsSuccess(response));
    } catch (error) {
      emit(BookDetailsFailed(error.toString()));
    }
  }
}
