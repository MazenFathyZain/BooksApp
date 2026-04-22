class AddBookResponse {
  final String id;
  final String title;
  final String author;
  final String category;
  final String description;

  // ✅ Multiple files
  final String? pdfUrl;
  final String? wordUrl;
  final String? audioUrl;
  final String? imageUrl;

  final int? partsCount;
  final String? subject;
  final String? language;
  final List<String>? otherNames;
  final List<String>? translators;
  final String? publisher;
  final String? publishingPlace;
  final int? publicationYear;
  final String? bookVersion;
  final String? century;
  final String? authorDoctrine;

  final DateTime createdAt;
  final DateTime updatedAt;

  AddBookResponse({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    this.pdfUrl,
    this.wordUrl,
    this.audioUrl,
    this.imageUrl,
    this.partsCount,
    this.subject,
    this.language,
    this.otherNames,
    this.translators,
    this.publisher,
    this.publishingPlace,
    this.publicationYear,
    this.bookVersion,
    this.century,
    this.authorDoctrine,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddBookResponse.fromJson(Map<String, dynamic> json) {
    return AddBookResponse(
      id: json['_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      pdfUrl: json['pdfUrl'] as String?,
      wordUrl: json['wordUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      partsCount: json['partsCount'] != null ? json['partsCount'] as int : null,
      subject: json['subject'] as String?,
      language: json['language'] as String?,
      otherNames: json['otherNames'] != null
          ? List<String>.from(json['otherNames'])
          : null,
      translators: json['translators'] != null
          ? List<String>.from(json['translators'])
          : null,
      publisher: json['publisher'] as String?,
      publishingPlace: json['publishingPlace'] as String?,
      publicationYear: json['publicationYear'] != null
          ? json['publicationYear'] as int
          : null,
      bookVersion: json['bookVersion'] as String?,
      century: json['century'] as String?,
      authorDoctrine: json['authorDoctrine'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'pdfUrl': pdfUrl,
      'wordUrl': wordUrl,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'partsCount': partsCount,
      'subject': subject,
      'language': language,
      'otherNames': otherNames,
      'translators': translators,
      'publisher': publisher,
      'publishingPlace': publishingPlace,
      'publicationYear': publicationYear,
      'bookVersion': bookVersion,
      'century': century,
      'authorDoctrine': authorDoctrine,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
