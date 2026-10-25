import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'reading_models.dart';

/// Stores reading progress, bookmarks and notes on the device so they work
/// without an internet connection.
class ReadingRepo {
  static const _progressPrefix = 'reading_progress_';
  static const _bookmarksPrefix = 'reading_bookmarks_';
  static const _notesPrefix = 'reading_notes_';
  static const _openSessionKey = 'reading_open_session';

  /// Builds the storage key for a book. The server id is preferred so the
  /// online reader and the downloaded PDF share the same progress.
  static String bookKeyFor({String? bookId, required String fallback}) {
    if (bookId != null && bookId.isNotEmpty) {
      return bookId;
    }
    return 'path:$fallback';
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Future<ReadingProgress?> getProgress(String bookKey) async {
    final json = await _readMap('$_progressPrefix$bookKey');
    return json == null ? null : ReadingProgress.fromJson(json);
  }

  Future<void> saveProgress(
    String bookKey, {
    required int page,
    required int totalPages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_progressPrefix$bookKey',
      jsonEncode(
        ReadingProgress(
          page: page,
          totalPages: totalPages,
          updatedAt: DateTime.now(),
        ).toJson(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  Future<List<BookBookmark>> getBookmarks(String bookKey) async {
    final items = await _readList('$_bookmarksPrefix$bookKey');
    final bookmarks =
        items.map(BookBookmark.fromJson).toList()
          ..sort((a, b) => a.page.compareTo(b.page));
    return bookmarks;
  }

  /// Adds a bookmark on [page], or removes it if it already exists.
  /// Returns true when the page is bookmarked after the call.
  Future<bool> toggleBookmark(String bookKey, int page) async {
    final bookmarks = await getBookmarks(bookKey);
    final exists = bookmarks.any((item) => item.page == page);
    if (exists) {
      bookmarks.removeWhere((item) => item.page == page);
    } else {
      bookmarks.add(BookBookmark(page: page, createdAt: DateTime.now()));
    }
    await _writeList(
      '$_bookmarksPrefix$bookKey',
      bookmarks.map((item) => item.toJson()).toList(),
    );
    return !exists;
  }

  Future<void> removeBookmark(String bookKey, int page) async {
    final bookmarks = await getBookmarks(bookKey);
    bookmarks.removeWhere((item) => item.page == page);
    await _writeList(
      '$_bookmarksPrefix$bookKey',
      bookmarks.map((item) => item.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes
  // ---------------------------------------------------------------------------

  Future<List<BookNote>> getNotes(String bookKey) async {
    final items = await _readList('$_notesPrefix$bookKey');
    final notes =
        items.map(BookNote.fromJson).toList()..sort((a, b) {
          final byPage = a.page.compareTo(b.page);
          return byPage != 0 ? byPage : a.createdAt.compareTo(b.createdAt);
        });
    return notes;
  }

  Future<void> addNote(
    String bookKey, {
    required int page,
    required String text,
  }) async {
    final notes = await getNotes(bookKey);
    final now = DateTime.now();
    notes.add(
      BookNote(
        id: '${now.microsecondsSinceEpoch}_${notes.length}',
        page: page,
        text: text,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _saveNotes(bookKey, notes);
  }

  Future<void> updateNote(String bookKey, String noteId, String text) async {
    final notes = await getNotes(bookKey);
    final updated = [
      for (final note in notes)
        note.id == noteId
            ? note.copyWith(text: text, updatedAt: DateTime.now())
            : note,
    ];
    await _saveNotes(bookKey, updated);
  }

  Future<void> deleteNote(String bookKey, String noteId) async {
    final notes = await getNotes(bookKey);
    notes.removeWhere((note) => note.id == noteId);
    await _saveNotes(bookKey, notes);
  }

  Future<void> _saveNotes(String bookKey, List<BookNote> notes) {
    return _writeList(
      '$_notesPrefix$bookKey',
      notes.map((note) => note.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Open reader session (reopen the book on next launch)
  // ---------------------------------------------------------------------------

  Future<OpenReaderSession?> getOpenSession() async {
    final json = await _readMap(_openSessionKey);
    if (json == null) {
      return null;
    }
    final session = OpenReaderSession.fromJson(json);
    return session.bookKey.isEmpty ? null : session;
  }

  Future<void> saveOpenSession(OpenReaderSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openSessionKey, jsonEncode(session.toJson()));
  }

  /// Clears the session, but only if it still belongs to the reader screen
  /// [instanceId], so a screen that closes late does not wipe a newer one.
  Future<void> clearOpenSession(String instanceId) async {
    final current = await getOpenSession();
    if (current == null || current.instanceId == instanceId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_openSessionKey);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // Ignore corrupted data and start fresh for this book.
    }
    return [];
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }
}
