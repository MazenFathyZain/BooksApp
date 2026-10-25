import 'package:book/features/home/data/models/books_response.dart';

/// Last page the reader reached in a book.
class ReadingProgress {
  final int page;
  final int totalPages;
  final DateTime updatedAt;

  const ReadingProgress({
    required this.page,
    required this.totalPages,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'totalPages': totalPages,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// A page the reader marked to come back to.
class BookBookmark {
  final int page;
  final DateTime createdAt;

  const BookBookmark({required this.page, required this.createdAt});

  factory BookBookmark.fromJson(Map<String, dynamic> json) {
    return BookBookmark(
      page: (json['page'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// A free-text note attached to a page.
class BookNote {
  final String id;
  final int page;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookNote({
    required this.id,
    required this.page,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  BookNote copyWith({String? text, DateTime? updatedAt}) {
    return BookNote(
      id: id,
      page: page,
      text: text ?? this.text,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BookNote.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return BookNote(
      id: json['id']?.toString() ?? createdAt.microsecondsSinceEpoch.toString(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      text: json['text']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'page': page,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Which reader a book was open in.
enum ReaderSource {
  /// A PDF file stored on the device.
  localFile,

  /// A PDF streamed from a URL.
  networkPdf,

  /// Server-rendered page images.
  pageImages,
}

/// The book that was open in a reader when the app was closed, so it can be
/// reopened on the next launch.
class OpenReaderSession {
  /// Unique per reader screen, so a closing screen only clears its own entry.
  final String instanceId;
  final String bookKey;
  final String? bookId;
  final String title;
  final ReaderSource source;
  final String? path;
  final List<BookPdfPage> pages;
  final int? totalPageCount;

  const OpenReaderSession({
    required this.instanceId,
    required this.bookKey,
    required this.bookId,
    required this.title,
    required this.source,
    this.path,
    this.pages = const [],
    this.totalPageCount,
  });

  factory OpenReaderSession.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    return OpenReaderSession(
      instanceId: json['instanceId']?.toString() ?? '',
      bookKey: json['bookKey']?.toString() ?? '',
      bookId: json['bookId']?.toString(),
      title: json['title']?.toString() ?? '',
      source: ReaderSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => ReaderSource.localFile,
      ),
      path: json['path']?.toString(),
      pages:
          rawPages is List
              ? rawPages
                  .whereType<Map<String, dynamic>>()
                  .map(BookPdfPage.fromJson)
                  .toList()
              : const [],
      totalPageCount: (json['totalPageCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'bookKey': bookKey,
    'bookId': bookId,
    'title': title,
    'source': source.name,
    'path': path,
    'pages': pages.map((page) => page.toJson()).toList(),
    'totalPageCount': totalPageCount,
  };
}
