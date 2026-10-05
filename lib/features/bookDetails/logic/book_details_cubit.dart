import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:book/features/bookDetails/data/repos/book_details_repo.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:flutter/foundation.dart';

import '../../../core/networking/api_error_handler.dart';

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
      emit(BookDetailsFailed(ApiErrorFormatter.getMessage(error)));
    }
  }

  updateBookById(
    String id,
    Map<String, dynamic> body, {
    File? image,
    File? pdf,
    File? word,
    File? audio,
  }) async {
    final currentState = state;
    if (currentState is BookDetailsSuccess) {
      emit(BookDetailsUpdating(currentState.response));
    } else if (currentState is BookDetailsUpdated) {
      emit(BookDetailsUpdating(currentState.response));
    } else {
      emit(BookDetailsLoading());
    }

    try {
      final response = await _repo.updateBookById(
        id,
        body,
        image,
        pdf,
        word,
        audio,
      );
      emit(BookDetailsUpdated(response));
    } catch (error) {
      emit(BookDetailsFailed(ApiErrorFormatter.getMessage(error)));
    }
  }

  deleteBookById(String id) async {
    emit(BookDetailsDeleting());
    try {
      await _repo.deleteBookById(id);
      emit(BookDetailsDeleted());
    } catch (error) {
      emit(BookDetailsFailed(ApiErrorFormatter.getMessage(error)));
    }
  }
}
