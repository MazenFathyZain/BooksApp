import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/networking/connectivity_service.dart';
import '../../../core/routing/routes.dart';
import '../../bookDetails/ui/paged_pdf_reader_screen.dart';
import '../../downloads/data/downloaded_books_repo.dart';
import '../data/reading_models.dart';
import '../data/reading_repo.dart';

bool _didTryReopen = false;

/// If the app was closed while a book was open, opens that book again. The
/// reader then resumes on the last page. Runs once per app launch.
Future<void> reopenBookLeftOpen(BuildContext context) async {
  if (_didTryReopen) {
    return;
  }
  _didTryReopen = true;

  final repo = ReadingRepo();
  final session = await repo.getOpenSession();
  if (session == null) {
    return;
  }

  // Prefer a downloaded copy: it works offline and opens faster.
  final localPath = await _findLocalPdf(session);
  final isOnline = await getIt<ConnectivityService>().isOnline();
  if (!context.mounted) {
    return;
  }

  if (localPath != null) {
    Navigator.pushNamed(
      context,
      Routes.pdf,
      arguments: {
        'pdfUrl': localPath,
        'title': session.title,
        'isLocal': true,
        'bookId': session.bookId,
      },
    );
    return;
  }

  if (!isOnline) {
    // Keep the session so the book reopens once the connection is back.
    return;
  }

  switch (session.source) {
    case ReaderSource.pageImages when session.pages.isNotEmpty:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PagedPdfReaderScreen(
                title: session.title,
                pages: session.pages,
                totalPageCount: session.totalPageCount,
                originalPdfUrl: session.path,
                bookId: session.bookId,
              ),
        ),
      );
    case ReaderSource.networkPdf when session.path?.isNotEmpty == true:
      Navigator.pushNamed(
        context,
        Routes.pdf,
        arguments: {
          'pdfUrl': session.path,
          'title': session.title,
          'bookId': session.bookId,
        },
      );
    default:
      await repo.clearOpenSession(session.instanceId);
  }
}

Future<String?> _findLocalPdf(OpenReaderSession session) async {
  final path = session.path;
  if (session.source == ReaderSource.localFile &&
      path != null &&
      path.isNotEmpty &&
      File(path).existsSync()) {
    return path;
  }

  final bookId = session.bookId;
  if (bookId == null || bookId.isEmpty) {
    return null;
  }
  final downloads = await DownloadedBooksRepo().getDownloadedBooks();
  for (final item in downloads) {
    if (item.book.id == bookId) {
      return item.localPdfPath;
    }
  }
  return null;
}
