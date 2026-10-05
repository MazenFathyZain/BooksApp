class CategoryTreeResponse {
  final String id;
  final String name;
  final String? language;
  final String? parentId;
  final List<CategoryTreeResponse> children;

  const CategoryTreeResponse({
    required this.id,
    required this.name,
    this.language,
    this.parentId,
    this.children = const [],
  });

  factory CategoryTreeResponse.fromJson(Map<String, dynamic> json) {
    final rawChildren =
        json['children'] ?? json['subCategories'] ?? json['subcategories'];
    return CategoryTreeResponse(
      id: _readId(json) ?? '',
      name: json['name']?.toString() ?? '',
      language: json['language']?.toString(),
      parentId: _readParentId(json['parent']),
      children:
          rawChildren is List
              ? rawChildren
                  .whereType<Map<String, dynamic>>()
                  .map(CategoryTreeResponse.fromJson)
                  .toList()
              : const [],
    );
  }

  static String? _readId(Map<String, dynamic> json) {
    return (json['_id'] ?? json['id'])?.toString();
  }

  static String? _readParentId(dynamic parent) {
    if (parent is Map<String, dynamic>) {
      return _readId(parent);
    }
    return parent?.toString();
  }
}
