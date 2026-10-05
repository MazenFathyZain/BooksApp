import 'package:json_annotation/json_annotation.dart';

part 'books_response.g.dart';

@JsonSerializable()
class BooksResponse {
  @JsonKey(name: '_id')
  final String? id;
  final String? title;
  final String? author;
  final String? category;
  final String? categoryId;
  final String? subCategory;
  final String? subCategoryId;
  final String? description;

  // 📄 File URLs
  final String? pdfUrl;
  final String? wordUrl; // ✅ Added
  final String? audioUrl; // ✅ Added
  final String? imageUrl;
  final String? pdfPagesStatus;
  final int? pdfPageCount;
  final String? pdfPagesError;
  final List<BookPdfPage>? pdfPages;

  final int? partsCount;
  final String? subject;
  final String? language;
  final String? publisher;
  final String? publishingPlace;
  final int? publicationYear;
  final String? century;
  final String? authorDoctrine;
  final String? bookVersion;
  final List<String>? otherNames;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BooksResponse({
    this.id,
    this.title,
    this.author,
    this.category,
    this.categoryId,
    this.subCategory,
    this.subCategoryId,
    this.description,
    this.pdfUrl,
    this.wordUrl, // ✅ Added
    this.audioUrl, // ✅ Added
    this.imageUrl,
    this.pdfPagesStatus,
    this.pdfPageCount,
    this.pdfPagesError,
    this.pdfPages,
    this.partsCount,
    this.subject,
    this.language,
    this.publisher,
    this.publishingPlace,
    this.publicationYear,
    this.century,
    this.authorDoctrine,
    this.bookVersion,
    this.otherNames,
    this.createdAt,
    this.updatedAt,
  });

  factory BooksResponse.fromJson(Map<String, dynamic> json) =>
      _$BooksResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BooksResponseToJson(this);

  static String? readName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['name']?.toString();
    }
    return value?.toString();
  }

  static String? readId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return (value['_id'] ?? value['id'])?.toString();
    }
    return value?.toString();
  }
}

@JsonSerializable()
class BookPdfPage {
  final int pageNumber;
  final String imageUrl;

  const BookPdfPage({required this.pageNumber, required this.imageUrl});

  factory BookPdfPage.fromJson(Map<String, dynamic> json) =>
      _$BookPdfPageFromJson(json);

  Map<String, dynamic> toJson() => _$BookPdfPageToJson(this);
}

class BooksPageResponse {
  final List<BooksResponse> books;
  final BooksPagination pagination;

  const BooksPageResponse({required this.books, required this.pagination});

  factory BooksPageResponse.fromJson(dynamic json) {
    if (json is List) {
      final books =
          json
              .whereType<Map<String, dynamic>>()
              .map(BooksResponse.fromJson)
              .toList();
      return BooksPageResponse(
        books: books,
        pagination: BooksPagination(
          totalBooks: books.length,
          totalPages: 1,
          currentPage: 1,
          perPage: books.length,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );
    }

    if (json is Map<String, dynamic>) {
      final rawBooks = json['books'];
      final books =
          rawBooks is List
              ? rawBooks
                  .whereType<Map<String, dynamic>>()
                  .map(BooksResponse.fromJson)
                  .toList()
              : <BooksResponse>[];
      return BooksPageResponse(
        books: books,
        pagination: BooksPagination.fromJson(json['pagination']),
      );
    }

    return const BooksPageResponse(books: [], pagination: BooksPagination());
  }
}

class BooksPagination {
  final int totalBooks;
  final int totalPages;
  final int currentPage;
  final int perPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const BooksPagination({
    this.totalBooks = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.perPage = 10,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });

  factory BooksPagination.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const BooksPagination();
    }

    return BooksPagination(
      totalBooks: _readInt(json['totalBooks']),
      totalPages: _readInt(json['totalPages'], fallback: 1),
      currentPage: _readInt(json['currentPage'], fallback: 1),
      perPage: _readInt(json['perPage'], fallback: 10),
      hasNextPage: json['hasNextPage'] == true,
      hasPreviousPage: json['hasPreviousPage'] == true,
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
