import 'package:dio/dio.dart';

import '../../../core/networking/api_constants.dart';
import '../../home/data/models/books_response.dart';
import '../../home/data/models/category_tree_response.dart';
import 'admin_models.dart';

/// The same admin operations the website offers. The server checks the admin
/// role on every one of these; hiding screens in the app is not the protection.
class AdminRepo {
  final Dio _dio;

  AdminRepo(this._dio);

  static const String _base = ApiConstants.apiBaseUrl;

  Future<AdminStats> getStats() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_base}admin/stats',
    );
    return AdminStats.fromJson(response.data ?? const {});
  }

  // ---------------- Users ----------------

  Future<List<AdminUser>> getUsers({
    String search = '',
    String role = '',
  }) async {
    final response = await _dio.get<dynamic>(
      '${_base}admin/users',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (role.isNotEmpty) 'role': role,
      },
    );
    final data = response.data;
    final items = data is Map ? data['users'] : data;
    return items is List
        ? items
            .whereType<Map<String, dynamic>>()
            .map(AdminUser.fromJson)
            .toList()
        : const [];
  }

  Future<AdminUser> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
    String password = '',
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${_base}admin/users/$id',
      data: {
        'name': name,
        'email': email,
        'role': role,
        if (password.isNotEmpty) 'password': password,
      },
    );
    return AdminUser.fromJson(response.data ?? const {});
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete<void>('${_base}admin/users/$id');
  }

  // ---------------- Categories ----------------

  /// Every category in every language; the screen filters locally.
  Future<List<CategoryTreeResponse>> getCategories() async {
    final response = await _dio.get<dynamic>('${_base}categories/tree');
    final data = response.data;
    final items = data is Map ? data['categories'] : data;
    return items is List
        ? items
            .whereType<Map<String, dynamic>>()
            .map(CategoryTreeResponse.fromJson)
            .toList()
        : const [];
  }

  Future<void> createCategory({
    required String name,
    String? language,
    String? parentId,
  }) async {
    await _dio.post<void>(
      '${_base}categories',
      data: {
        'name': name,
        if (parentId != null) 'parent': parentId else 'language': language,
      },
    );
  }

  Future<void> renameCategory({
    required String id,
    required String name,
  }) async {
    await _dio.patch<void>('${_base}categories/$id', data: {'name': name});
  }

  Future<void> deleteCategory(CategoryTreeResponse category) async {
    final isSubCategory = (category.parentId ?? '').isNotEmpty;
    await _dio.delete<void>(
      isSubCategory
          ? '${_base}categories/subcategories/${category.id}'
          : '${_base}categories/${category.id}',
    );
  }

  // ---------------- Books ----------------

  Future<BooksPageResponse> getBooks({
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      '${_base}books',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      },
    );
    return BooksPageResponse.fromJson(response.data);
  }

  Future<void> deleteBook(String id) async {
    await _dio.delete<void>('${_base}books/$id');
  }
}
