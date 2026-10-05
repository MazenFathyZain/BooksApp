import 'dart:io';

import 'package:book/features/bookDetails/data/apis/book_details_apis.dart';
import 'package:book/features/home/data/models/books_response.dart';

class BookDetailsRepo {
  final BookDetailsApis _apis;
  BookDetailsRepo(this._apis);

  Future<BooksResponse> getBookById(String id) async {
    return await _apis.getBookDetails(id);
  }

  Future<BooksResponse> updateBookById(
    String id,
    Map<String, dynamic> body,
    File? image,
    File? pdf,
    File? word,
    File? audio,
  ) async {
    return await _apis.updateBook(
      id,
      body['title'] as String? ?? '',
      body['author'] as String? ?? '',
      body['category'] as String? ?? '',
      body['categoryId'] as String?,
      body['subCategoryId'] as String?,
      body['description'] as String? ?? '',
      image,
      pdf,
      word,
      audio,
    );
  }

  Future<void> deleteBookById(String id) async {
    return await _apis.deleteBook(id);
  }
}
