import 'dart:convert';
import 'dart:io';

import 'package:book/features/downloads/data/downloaded_book.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedBooksRepo {
  static const _storageKey = 'downloaded_books';

  Future<List<DownloadedBook>> getDownloadedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];
    final books = <DownloadedBook>[];

    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map<String, dynamic>) {
          final item = DownloadedBook.fromJson(decoded);
          if (item.localPdfPath.isNotEmpty &&
              File(item.localPdfPath).existsSync()) {
            books.add(item);
          }
        }
      } catch (_) {
        // Ignore corrupted local rows and keep the rest of the library usable.
      }
    }

    books.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    if (books.length != rawItems.length) {
      await _saveAll(books);
    }
    return books;
  }

  Future<bool> isDownloaded(String? bookId) async {
    if (bookId == null || bookId.isEmpty) {
      return false;
    }
    final books = await getDownloadedBooks();
    return books.any((item) => item.book.id == bookId);
  }

  Future<void> saveDownloadedBook({
    required BooksResponse book,
    required String localPdfPath,
    String? localImagePath,
  }) async {
    final books = await getDownloadedBooks();
    final bookId = book.id;
    books.removeWhere(
      (item) =>
          bookId != null && bookId.isNotEmpty
              ? item.book.id == bookId
              : item.localPdfPath == localPdfPath,
    );
    books.insert(
      0,
      DownloadedBook(
        book: book,
        localPdfPath: localPdfPath,
        localImagePath: localImagePath,
        downloadedAt: DateTime.now(),
      ),
    );
    await _saveAll(books);
  }

  Future<void> removeDownloadedBook(DownloadedBook downloadedBook) async {
    final books = await getDownloadedBooks();
    books.removeWhere(
      (item) =>
          item.localPdfPath == downloadedBook.localPdfPath ||
          (item.book.id != null && item.book.id == downloadedBook.book.id),
    );
    final file = File(downloadedBook.localPdfPath);
    if (await file.exists()) {
      await file.delete();
    }
    final imagePath = downloadedBook.localImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
    await _saveAll(books);
  }

  Future<void> _saveAll(List<DownloadedBook> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      books.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
