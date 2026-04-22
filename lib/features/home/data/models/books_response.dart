import 'package:json_annotation/json_annotation.dart';

part 'books_response.g.dart';

@JsonSerializable()
class BooksResponse {
  @JsonKey(name: '_id')
  final String? id;
  final String? title;
  final String? author;
  final String? category;
  final String? description;

  // 📄 File URLs
  final String? pdfUrl;
  final String? wordUrl;      // ✅ Added
  final String? audioUrl;     // ✅ Added
  final String? imageUrl;

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
    this.description,
    this.pdfUrl,
    this.wordUrl,      // ✅ Added
    this.audioUrl,     // ✅ Added
    this.imageUrl,
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
}