import 'dart:io';

import 'package:book/features/dashboard/data/apis/dashboard_apis.dart';
import 'package:book/features/dashboard/data/models/add_book_response.dart';

class DashboardRepo {
  final DashboardApis _api;
  DashboardRepo(this._api);


Future<AddBookResponse> addBook(
    String title,
    String author,
    String category,
    String description,
    File? image,
    File? pdf,
    File? word,
    File? audio,
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
  return await _api.addBook(
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
}
}