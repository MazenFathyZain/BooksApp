import 'dart:io';

import 'package:book/features/home/data/models/books_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/networking/api_constants.dart';

part 'book_details_apis.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class BookDetailsApis {
  factory BookDetailsApis(Dio dio, {String baseUrl}) = _BookDetailsApis;

  @GET(ApiConstants.getBookById)
  Future<BooksResponse> getBookDetails(@Path('id') String bookId);

  @PUT(ApiConstants.updateBookById)
  @MultiPart()
  Future<BooksResponse> updateBook(
    @Path('id') String bookId,
    @Part(name: 'title') String title,
    @Part(name: 'author') String author,
    @Part(name: 'category') String category,
    @Part(name: 'categoryId') String? categoryId,
    @Part(name: 'subCategoryId') String? subCategoryId,
    @Part(name: 'description') String description,
    @Part() File? image,
    @Part() File? pdf,
    @Part() File? word,
    @Part() File? audio,
  );

  @DELETE(ApiConstants.deleteBookById)
  Future<void> deleteBook(@Path('id') String bookId);
}
