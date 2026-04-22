import 'package:book/features/home/data/models/books_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/networking/api_constants.dart';
import '../models/add_favorite_request.dart';

part 'home_apis.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class HomeApis {
  factory HomeApis(Dio dio, {String baseUrl}) = _HomeApis;

  // Get all books
  @GET(ApiConstants.getAllBooksEP)
  Future<List<BooksResponse>> getBooks({
    @Query('search') String? search,
    @Query('category') String? category,
  });

  // Get all categories
  @GET(ApiConstants.getAllBooksCategoriesEP)
  Future<List<String>> getAllBooksCategories();

  // Add to favorites
  @POST(ApiConstants.addToFavorite)
  Future<void> addToFavorite(
      @Body() AddFavoriteRequest body,
      );
}