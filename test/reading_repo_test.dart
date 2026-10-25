import 'package:book/features/home/data/models/books_response.dart';
import 'package:book/features/reading/data/reading_models.dart';
import 'package:book/features/reading/data/reading_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ReadingRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = ReadingRepo();
  });

  test('saves and restores the last page per book', () async {
    expect(await repo.getProgress('book-1'), isNull);

    await repo.saveProgress('book-1', page: 42, totalPages: 300);
    await repo.saveProgress('book-2', page: 7, totalPages: 50);

    final progress = await repo.getProgress('book-1');
    expect(progress?.page, 42);
    expect(progress?.totalPages, 300);
    expect((await repo.getProgress('book-2'))?.page, 7);
  });

  test('toggles bookmarks and keeps them sorted', () async {
    expect(await repo.toggleBookmark('book-1', 30), isTrue);
    expect(await repo.toggleBookmark('book-1', 5), isTrue);
    expect((await repo.getBookmarks('book-1')).map((b) => b.page), [5, 30]);

    expect(await repo.toggleBookmark('book-1', 30), isFalse);
    expect((await repo.getBookmarks('book-1')).map((b) => b.page), [5]);

    await repo.removeBookmark('book-1', 5);
    expect(await repo.getBookmarks('book-1'), isEmpty);
  });

  test('adds, edits and deletes notes', () async {
    await repo.addNote('book-1', page: 12, text: 'Important idea');
    await repo.addNote('book-1', page: 3, text: 'Intro');

    var notes = await repo.getNotes('book-1');
    expect(notes.map((n) => n.page), [3, 12]);

    await repo.updateNote('book-1', notes.last.id, 'Edited');
    notes = await repo.getNotes('book-1');
    expect(notes.last.text, 'Edited');

    await repo.deleteNote('book-1', notes.first.id);
    notes = await repo.getNotes('book-1');
    expect(notes.map((n) => n.text), ['Edited']);
    expect(await repo.getNotes('book-2'), isEmpty);
  });

  test('open session is only cleared by the reader that owns it', () async {
    const session = OpenReaderSession(
      instanceId: 'reader-a',
      bookKey: 'book-1',
      bookId: 'book-1',
      title: 'Title',
      source: ReaderSource.pageImages,
      pages: [BookPdfPage(pageNumber: 1, imageUrl: 'p1.jpg')],
    );
    await repo.saveOpenSession(session);

    await repo.clearOpenSession('reader-b');
    final restored = await repo.getOpenSession();
    expect(restored?.source, ReaderSource.pageImages);
    expect(restored?.pages.single.imageUrl, 'p1.jpg');

    await repo.clearOpenSession('reader-a');
    expect(await repo.getOpenSession(), isNull);
  });

  test('book key prefers the server id', () {
    expect(ReadingRepo.bookKeyFor(bookId: 'abc', fallback: '/x.pdf'), 'abc');
    expect(
      ReadingRepo.bookKeyFor(bookId: '', fallback: '/x.pdf'),
      'path:/x.pdf',
    );
  });
}
