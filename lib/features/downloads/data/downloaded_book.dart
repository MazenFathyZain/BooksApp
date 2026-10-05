import 'package:book/features/home/data/models/books_response.dart';

class DownloadedBook {
  final BooksResponse book;
  final String localPdfPath;
  final String? localImagePath;
  final DateTime downloadedAt;

  const DownloadedBook({
    required this.book,
    required this.localPdfPath,
    this.localImagePath,
    required this.downloadedAt,
  });

  factory DownloadedBook.fromJson(Map<String, dynamic> json) {
    final rawBook = json['book'];
    return DownloadedBook(
      book: BooksResponse.fromJson(
        rawBook is Map<String, dynamic> ? rawBook : <String, dynamic>{},
      ),
      localPdfPath: json['localPdfPath']?.toString() ?? '',
      localImagePath: json['localImagePath']?.toString(),
      downloadedAt:
          DateTime.tryParse(json['downloadedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book.toJson(),
      'localPdfPath': localPdfPath,
      'localImagePath': localImagePath,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }
}
