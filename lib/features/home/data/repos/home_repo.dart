import 'package:book/features/home/data/apis/home_apis.dart';
import 'package:book/features/home/data/models/add_favorite_request.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:book/features/home/data/models/category_tree_response.dart';

class HomeRepo {
  final HomeApis _api;
  HomeRepo(this._api);

  Future<BooksPageResponse> getAllBooks(
    String? search,
    String? categoryId,
    String? subCategoryId,
    String? language,
    int page,
    int limit,
  ) async {
    return await _api.getBooks(
      search: search,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      language: language,
      page: page,
      limit: limit,
    );
  }

  Future<List<String>> getAllBooksCategories() async {
    return await _api.getAllBooksCategories();
  }

  Future<List<CategoryTreeResponse>> getCategoryTree({String? language}) async {
    return await _api.getCategoryTree(language: language);
  }

  Future<CategoryTreeResponse> createCategory({
    required String name,
    String? parentId,
    String? language,
  }) async {
    final hasParent = parentId != null && parentId.isNotEmpty;
    return await _api.createCategory({
      'name': name,
      if (hasParent) 'parent': parentId,
      if (!hasParent && language != null && language.isNotEmpty)
        'language': language,
    });
  }

  Future<CategoryTreeResponse> updateCategory({
    required String categoryId,
    String? language,
  }) async {
    return await _api.updateCategory(categoryId, {
      if (language != null && language.isNotEmpty) 'language': language,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    return await _api.deleteCategory(categoryId);
  }

  Future<void> deleteSubCategory(String subCategoryId) async {
    return await _api.deleteSubCategory(subCategoryId);
  }

  Future<void> addToFavorite(AddFavoriteRequest body) async {
    return await _api.addToFavorite(body);
  }
}
