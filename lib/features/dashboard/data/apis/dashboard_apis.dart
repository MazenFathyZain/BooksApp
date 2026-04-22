import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/networking/api_constants.dart';
import '../models/add_book_response.dart';

part 'dashboard_apis.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class DashboardApis {
  factory DashboardApis(Dio dio, {String baseUrl}) = _DashboardApis;

  @POST("/books/upload")
  @MultiPart()
  Future<AddBookResponse> addBook(
      @Part(name: 'title') String title,
      @Part(name: 'author') String author,
      @Part(name: 'category') String category,
      @Part(name: 'description') String description,
      @Part() File? image,
      @Part() File? pdf,
      @Part() File? word,
      @Part() File? audio,
      @Part(name: 'partsCount') int partsCount,
      @Part(name: 'subject') String subject,
      @Part(name: 'language') String language,
      @Part(name: 'otherNames') List<String> otherNames,
      @Part(name: 'translators') List<String> translators,
      @Part(name: 'publisher') String publisher,
      @Part(name: 'publishingPlace') String publishingPlace,
      @Part(name: 'publicationYear') int publicationYear,
      @Part(name: 'bookVersion') String bookVersion,
      @Part(name: 'century') String century,
      @Part(name: 'authorDoctrine') String authorDoctrine,
      );
}