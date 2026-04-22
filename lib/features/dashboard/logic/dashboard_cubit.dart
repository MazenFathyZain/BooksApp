import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:book/features/dashboard/data/models/add_book_response.dart';
import 'package:book/features/dashboard/data/repos/dashbaord_repo.dart';
import 'package:meta/meta.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepo _repo;
  DashboardCubit(this._repo) : super(DashboardInitial());

  addBook(
      String title,
      String author,
      String category,
      String description,
      File? image,           // Image is optional
      File pdf,              // PDF is required
      File? word,            // Word is optional
      File? doc,             // Doc is optional (not implemented)
      File? audio,           // Audio is optional
      int partsCount,
      String subject,
      String language,
      List<String> otherNames,
      List<String> translators,
      String publisher,
      String publishingPlace,
      int publicationYear,
      String bookVersion,
      String century,
      String authorDoctrine,
      ) async {
    emit(DashboardLoading());
    try {
      final response = await _repo.addBook(
        title,
        author,
        category,
        description,
        image,
        pdf,
        word,
        audio,
        partsCount,
        subject,
        language,
        otherNames,
        translators,
        publisher,
        publishingPlace,
        publicationYear,
        bookVersion,
        century,
        authorDoctrine,
      );
      emit(DashboardSuccess(response));
    } catch (error) {
      emit(DashboardFailed(error.toString()));
    }
  }
}