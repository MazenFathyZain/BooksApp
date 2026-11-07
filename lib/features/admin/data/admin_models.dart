import '../../home/data/models/books_response.dart';

/// An account as shown in the admin users list. Never includes the password.
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

/// The numbers and recent activity on the admin dashboard.
class AdminStats {
  final int booksCount;
  final int usersCount;
  final int adminsCount;
  final int categoriesCount;
  final int favoritesCount;
  final List<BooksResponse> recentBooks;
  final List<AdminUser> recentUsers;

  const AdminStats({
    required this.booksCount,
    required this.usersCount,
    required this.adminsCount,
    required this.categoriesCount,
    required this.favoritesCount,
    required this.recentBooks,
    required this.recentUsers,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final items = json[key];
      return items is List
          ? items.whereType<Map<String, dynamic>>().map(parse).toList()
          : <T>[];
    }

    return AdminStats(
      booksCount: count('booksCount'),
      usersCount: count('usersCount'),
      adminsCount: count('adminsCount'),
      categoriesCount: count('categoriesCount'),
      favoritesCount: count('favoritesCount'),
      recentBooks: list('recentBooks', BooksResponse.fromJson),
      recentUsers: list('recentUsers', AdminUser.fromJson),
    );
  }
}
