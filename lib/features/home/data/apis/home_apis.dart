import 'package:book/features/home/data/models/books_response.dart';
import 'package:book/features/home/data/models/category_tree_response.dart';
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
  Future<BooksPageResponse> getBooks({
    @Query('search') String? search,
    @Query('categoryId') String? categoryId,
    @Query('subCategoryId') String? subCategoryId,
    @Query('language') String? language,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  // Get all categories
  @GET(ApiConstants.getAllBooksCategoriesEP)
  Future<List<String>> getAllBooksCategories();

  @GET(ApiConstants.getCategoryTreeEP)
  Future<List<CategoryTreeResponse>> getCategoryTree({
    @Query('language') String? language,
  });

  @POST(ApiConstants.categoriesEP)
  Future<CategoryTreeResponse> createCategory(
    @Body() Map<String, dynamic> body,
  );

  @PATCH('${ApiConstants.categoriesEP}/{categoryId}')
  Future<CategoryTreeResponse> updateCategory(
    @Path('categoryId') String categoryId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${ApiConstants.categoriesEP}/{categoryId}')
  Future<void> deleteCategory(@Path('categoryId') String categoryId);

  @DELETE('${ApiConstants.categoriesEP}/subcategories/{subCategoryId}')
  Future<void> deleteSubCategory(@Path('subCategoryId') String subCategoryId);

  // Add to favorites
  @POST(ApiConstants.addToFavorite)
  Future<void> addToFavorite(@Body() AddFavoriteRequest body);
}
