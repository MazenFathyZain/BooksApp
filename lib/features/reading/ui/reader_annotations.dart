import 'package:flutter/material.dart';

import '../../../core/helpers/extension.dart';
import '../../../core/theming/app_colors.dart';
import '../../home/data/models/books_response.dart';
import '../data/reading_models.dart';
import '../data/reading_repo.dart';

/// Shared reading features for the reader screens: remembering the last page,
/// reopening the book after the app is closed, bookmarks and notes.
///
/// The host screen sets [bookKey] in `initState`, then reports the current
/// page through [annotationCurrentPage] and handles [annotationGoToPage].
mixin ReaderAnnotationsMixin<T extends StatefulWidget> on State<T> {
  final ReadingRepo readingRepo = ReadingRepo();
  final String readerInstanceId =
      DateTime.now().microsecondsSinceEpoch.toString();
  late final String bookKey;

  List<BookBookmark> bookmarks = const [];
  List<BookNote> notes = const [];

  /// The page currently shown, starting at 1.
  int get annotationCurrentPage;

  /// Moves the reader to [page], starting at 1.
  void annotationGoToPage(int page);

  bool get isCurrentPageBookmarked =>
      bookmarks.any((item) => item.page == annotationCurrentPage);

  Future<void> loadAnnotations() async {
    final loadedBookmarks = await readingRepo.getBookmarks(bookKey);
    final loadedNotes = await readingRepo.getNotes(bookKey);
    if (!mounted) {
      return;
    }
    setState(() {
      bookmarks = loadedBookmarks;
      notes = loadedNotes;
    });
  }

  /// Returns the saved page to resume from, or null to start at the beginning.
  Future<int?> loadSavedPage() async {
    final progress = await readingRepo.getProgress(bookKey);
    if (progress == null || progress.page <= 1) {
      return null;
    }
    return progress.page;
  }

  void saveReadingProgress(int page, int totalPages) {
    readingRepo.saveProgress(bookKey, page: page, totalPages: totalPages);
  }

  /// Remembers that this book is open, so it reopens if the app is closed
  /// while reading.
  void rememberOpenBook({
    required String? bookId,
    required String title,
    required ReaderSource source,
    String? path,
    List<BookPdfPage> pages = const [],
    int? totalPageCount,
  }) {
    readingRepo.saveOpenSession(
      OpenReaderSession(
        instanceId: readerInstanceId,
        bookKey: bookKey,
        bookId: bookId,
        title: title,
        source: source,
        path: path,
        pages: pages,
        totalPageCount: totalPageCount,
      ),
    );
  }

  /// Called when the reader closes normally (back button).
  void forgetOpenBook() {
    readingRepo.clearOpenSession(readerInstanceId);
  }

  void showResumeMessage(int page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('resumed_from_page').replaceAll('{page}', '$page'),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.tr('start_from_beginning'),
          textColor: AppColors.secondary,
          onPressed: () => annotationGoToPage(1),
        ),
      ),
    );
  }

  Future<void> toggleCurrentPageBookmark() async {
    final page = annotationCurrentPage;
    final added = await readingRepo.toggleBookmark(bookKey, page);
    await loadAnnotations();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? context.tr('bookmark_added').replaceAll('{page}', '$page')
                : context.tr('bookmark_removed'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> addNoteForCurrentPage() async {
    final page = annotationCurrentPage;
    final text = await showNoteEditorDialog(context, page: page);
    if (text == null || text.trim().isEmpty) {
      return;
    }
    await readingRepo.addNote(bookKey, page: page, text: text.trim());
    await loadAnnotations();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('note_saved')),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> openAnnotationsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => ReaderAnnotationsSheet(
            repo: readingRepo,
            bookKey: bookKey,
            currentPage: annotationCurrentPage,
            onGoToPage: (page) {
              Navigator.pop(sheetContext);
              annotationGoToPage(page);
            },
          ),
    );
    await loadAnnotations();
  }
}

/// Bottom sheet listing a book's bookmarks and notes.
class ReaderAnnotationsSheet extends StatefulWidget {
  final ReadingRepo repo;
  final String bookKey;
  final int currentPage;
  final ValueChanged<int> onGoToPage;

  const ReaderAnnotationsSheet({
    super.key,
    required this.repo,
    required this.bookKey,
    required this.currentPage,
    required this.onGoToPage,
  });

  @override
  State<ReaderAnnotationsSheet> createState() => _ReaderAnnotationsSheetState();
}

class _ReaderAnnotationsSheetState extends State<ReaderAnnotationsSheet> {
  List<BookBookmark> _bookmarks = const [];
  List<BookNote> _notes = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final bookmarks = await widget.repo.getBookmarks(widget.bookKey);
    final notes = await widget.repo.getNotes(widget.bookKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _bookmarks = bookmarks;
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addNote() async {
    final text = await showNoteEditorDialog(context, page: widget.currentPage);
    if (text == null || text.trim().isEmpty) {
      return;
    }
    await widget.repo.addNote(
      widget.bookKey,
      page: widget.currentPage,
      text: text.trim(),
    );
    await _reload();
  }

  Future<void> _editNote(BookNote note) async {
    final text = await showNoteEditorDialog(
      context,
      page: note.page,
      initialText: note.text,
    );
    if (text == null || text.trim().isEmpty) {
      return;
    }
    await widget.repo.updateNote(widget.bookKey, note.id, text.trim());
    await _reload();
  }

  Future<void> _deleteNote(BookNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('delete')),
            content: Text(context.tr('delete_note_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(context.tr('delete')),
              ),
            ],
          ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.repo.deleteNote(widget.bookKey, note.id);
    await _reload();
  }

  Future<void> _removeBookmark(BookBookmark bookmark) async {
    await widget.repo.removeBookmark(widget.bookKey, bookmark.page);
    await _reload();
  }

  String _pageLabel(int page) =>
      context.tr('page_n').replaceAll('{page}', '$page');

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('bookmarks_and_notes'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _pageLabel(widget.currentPage),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondary,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.bookmark_rounded),
                    text: '${context.tr('bookmarks')} (${_bookmarks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.sticky_note_2_rounded),
                    text: '${context.tr('notes')} (${_notes.length})',
                  ),
                ],
              ),
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                        : TabBarView(
                          children: [_buildBookmarksTab(), _buildNotesTab()],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return _EmptyAnnotations(
        icon: Icons.bookmark_border_rounded,
        message: context.tr('no_bookmarks_yet'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _bookmarks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        return ListTile(
          leading: const Icon(
            Icons.bookmark_rounded,
            color: AppColors.secondary,
          ),
          title: Text(
            _pageLabel(bookmark.page),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(_formatDate(bookmark.createdAt)),
          trailing: IconButton(
            tooltip: context.tr('remove_bookmark'),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _removeBookmark(bookmark),
          ),
          onTap: () => widget.onGoToPage(bookmark.page),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(
                context
                    .tr('add_note_for_page')
                    .replaceAll('{page}', '${widget.currentPage}'),
              ),
            ),
          ),
        ),
        Expanded(
          child:
              _notes.isEmpty
                  ? _EmptyAnnotations(
                    icon: Icons.sticky_note_2_outlined,
                    message: context.tr('no_notes_yet'),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return ListTile(
                        onTap: () => widget.onGoToPage(note.page),
                        title: Text(
                          note.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_pageLabel(note.page)} · ${_formatDate(note.updatedAt)}',
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: context.tr('edit_note'),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _editNote(note),
                            ),
                            IconButton(
                              tooltip: context.tr('delete'),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () => _deleteNote(note),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

class _EmptyAnnotations extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyAnnotations({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primaryOpacity50),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog to write or edit a note. Returns the text, or null when the
/// dialog is cancelled.
Future<String?> showNoteEditorDialog(
  BuildContext context, {
  required int page,
  String? initialText,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteEditorDialog(page: page, initialText: initialText),
  );
}

class _NoteEditorDialog extends StatefulWidget {
  final int page;
  final String? initialText;

  const _NoteEditorDialog({required this.page, this.initialText});

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialText != null;
    return AlertDialog(
      title: Text(
        '${context.tr(isEditing ? 'edit_note' : 'add_note')} · '
        '${context.tr('page_n').replaceAll('{page}', '${widget.page}')}',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 4,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: context.tr('note_hint')),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder:
              (context, value, _) => ElevatedButton(
                onPressed:
                    value.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, _controller.text),
                child: Text(context.tr('save')),
              ),
        ),
      ],
    );
  }
}
