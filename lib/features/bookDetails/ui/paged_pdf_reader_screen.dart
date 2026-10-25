import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/helpers/extension.dart';
import '../../../core/helpers/media_url_helper.dart';
import '../../../core/theming/app_colors.dart';
import '../../home/data/models/books_response.dart';
import '../../reading/data/reading_models.dart';
import '../../reading/data/reading_repo.dart';
import '../../reading/ui/reader_annotations.dart';

class PagedPdfReaderScreen extends StatefulWidget {
  final String title;
  final List<BookPdfPage> pages;
  final int? totalPageCount;
  final String? originalPdfUrl;
  final String? bookId; // Used to remember the last page, bookmarks and notes

  const PagedPdfReaderScreen({
    super.key,
    required this.title,
    required this.pages,
    this.totalPageCount,
    this.originalPdfUrl,
    this.bookId,
  });

  @override
  State<PagedPdfReaderScreen> createState() => _PagedPdfReaderScreenState();
}

class _PagedPdfReaderScreenState extends State<PagedPdfReaderScreen>
    with ReaderAnnotationsMixin<PagedPdfReaderScreen> {
  /// Created once the saved page is known, so the reader opens on it.
  PageController? _pageController;
  int _currentIndex = 0;
  bool _showControls = true;
  bool _isDownloading = false;
  int? _sliderPreviewPage;

  late final List<BookPdfPage> _pages = [...widget.pages]
    ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

  @override
  int get annotationCurrentPage => _currentPageNumber;

  @override
  void annotationGoToPage(int page) => _goToPageNumber(page);

  int get _totalPageCount {
    final highestLoadedPage = _pages.fold<int>(
      0,
      (highest, page) => page.pageNumber > highest ? page.pageNumber : highest,
    );
    final backendPageCount = widget.totalPageCount ?? 0;
    final total =
        backendPageCount > highestLoadedPage
            ? backendPageCount
            : highestLoadedPage;
    return total > 0 ? total : _pages.length;
  }

  int get _currentPageNumber {
    if (_pages.isEmpty || _currentIndex >= _pages.length) {
      return 1;
    }

    return _pages[_currentIndex].pageNumber;
  }

  @override
  void initState() {
    super.initState();
    bookKey = ReadingRepo.bookKeyFor(
      bookId: widget.bookId,
      fallback: _pages.isNotEmpty ? _pages.first.imageUrl : widget.title,
    );
    rememberOpenBook(
      bookId: widget.bookId,
      title: widget.title,
      source: ReaderSource.pageImages,
      path: widget.originalPdfUrl,
      pages: _pages,
      totalPageCount: widget.totalPageCount,
    );
    loadAnnotations();
    _restoreLastPage();
  }

  Future<void> _restoreLastPage() async {
    final savedPage = await loadSavedPage();
    if (!mounted) {
      return;
    }
    final initialIndex = savedPage == null ? 0 : _indexForPageNumber(savedPage);
    setState(() {
      _currentIndex = initialIndex;
      _pageController = PageController(initialPage: initialIndex);
    });
    if (initialIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showResumeMessage(_currentPageNumber);
        }
      });
    }
  }

  @override
  void dispose() {
    forgetOpenBook();
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    saveReadingProgress(_pages[index].pageNumber, _totalPageCount);
  }

  void _goToPage(int pageIndex) {
    final controller = _pageController;
    if (controller == null || pageIndex < 0 || pageIndex >= _pages.length) {
      return;
    }

    controller.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goToPageNumber(int pageNumber) {
    if (_pages.isEmpty) {
      return;
    }
    _goToPage(_indexForPageNumber(pageNumber));
  }

  /// Index of the loaded page closest to [pageNumber].
  int _indexForPageNumber(int pageNumber) {
    if (_pages.isEmpty) {
      return 0;
    }

    final normalizedPage = pageNumber.clamp(1, _totalPageCount);
    final exactIndex = _pages.indexWhere(
      (page) => page.pageNumber == normalizedPage,
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }

    var nearestIndex = 0;
    var nearestDistance = (_pages.first.pageNumber - normalizedPage).abs();
    for (var i = 1; i < _pages.length; i++) {
      final distance = (_pages[i].pageNumber - normalizedPage).abs();
      if (distance < nearestDistance) {
        nearestIndex = i;
        nearestDistance = distance;
      }
    }

    return nearestIndex;
  }

  void _goToPreviousPage() {
    if (_currentIndex > 0) {
      _goToPage(_currentIndex - 1);
    }
  }

  void _goToNextPage() {
    if (_currentIndex < _pages.length - 1) {
      _goToPage(_currentIndex + 1);
    }
  }

  void _handlePageTap(Offset position) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftZoneEnd = screenWidth / 3;
    final rightZoneStart = screenWidth * 2 / 3;

    if (position.dx < leftZoneEnd) {
      _goToPreviousPage();
    } else if (position.dx > rightZoneStart) {
      _goToNextPage();
    } else {
      setState(() => _showControls = !_showControls);
    }
  }

  void _handleVerticalPageSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -240) {
      _goToNextPage();
    } else if (velocity > 240) {
      _goToPreviousPage();
    }
  }

  Future<void> _downloadPdf() async {
    final pdfUrl = widget.originalPdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('failed_to_load_pdf')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final status = await Permission.storage.request();

      if (Platform.isAndroid && await Permission.storage.isPermanentlyDenied) {
        await openAppSettings();
        if (mounted) {
          setState(() => _isDownloading = false);
        }
        return;
      }

      if (status.isGranted || status.isLimited || Platform.isAndroid) {
        Directory? directory;

        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          throw Exception(context.tr('download_failed'));
        }

        final safeTitle = widget.title
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_');
        final fileName =
            '${safeTitle.isEmpty ? 'book' : safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final savePath = '${directory.path}/$fileName';

        await Dio().download(pdfUrl, savePath);

        if (!mounted) {
          return;
        }

        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('pdf_downloaded_successfully'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.tr('saved_to')}: ${directory.path}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('storage_permission_required_download_pdf'),
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: context.tr('settings'),
              textColor: AppColors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('download_failed')}: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showPageNavigator() {
    var targetPage = _currentPageNumber;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('go_to_page')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.tr('current_page')}: $_currentPageNumber / $_totalPageCount',
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('page_number'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  targetPage = int.tryParse(value) ?? _currentPageNumber;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToPageNumber(targetPage);
              },
              child: Text(context.tr('go_to_page')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage(BookPdfPage page) {
    final imageUrl = resolveMediaUrl(page.imageUrl) ?? page.imageUrl;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) => _handlePageTap(details.localPosition),
      onVerticalDragEnd: _handleVerticalPageSwipe,
      child: ColoredBox(
        color: AppColors.white,
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                final expectedBytes = loadingProgress.expectedTotalBytes;
                final progress =
                    expectedBytes == null || expectedBytes <= 0
                        ? null
                        : loadingProgress.cumulativeBytesLoaded / expectedBytes;

                return Center(
                  child: CircularProgressIndicator(
                    value: progress,
                    color: AppColors.primary,
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('failed_to_load_pdf'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final pageLabel = '$_currentPageNumber / $_totalPageCount';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: AppColors.white,
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Text(
                  pageLabel,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr(
                  isCurrentPageBookmarked ? 'remove_bookmark' : 'bookmark_page',
                ),
                icon: Icon(
                  isCurrentPageBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                ),
                color:
                    isCurrentPageBookmarked
                        ? AppColors.secondary
                        : AppColors.white,
                onPressed: toggleCurrentPageBookmark,
              ),
              IconButton(
                tooltip: context.tr('bookmarks_and_notes'),
                icon: Badge(
                  isLabelVisible: bookmarks.isNotEmpty || notes.isNotEmpty,
                  label: Text('${bookmarks.length + notes.length}'),
                  backgroundColor: AppColors.secondary,
                  child: const Icon(Icons.collections_bookmark_outlined),
                ),
                color: AppColors.white,
                onPressed: openAnnotationsSheet,
              ),
              PopupMenuButton<String>(
                icon:
                    _isDownloading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.white),
                          ),
                        )
                        : const Icon(Icons.more_vert, color: AppColors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'note':
                      addNoteForCurrentPage();
                    case 'go_to_page':
                      _showPageNavigator();
                    case 'download':
                      _downloadPdf();
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'note',
                        child: ListTile(
                          leading: const Icon(Icons.add_comment_outlined),
                          title: Text(context.tr('add_note')),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'go_to_page',
                        child: ListTile(
                          leading: const Icon(Icons.format_list_numbered),
                          title: Text(context.tr('go_to_page')),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'download',
                        enabled:
                            !_isDownloading && widget.originalPdfUrl != null,
                        child: ListTile(
                          leading: const Icon(Icons.download),
                          title: Text(context.tr('download_pdf')),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalPages = _totalPageCount;
    final sliderPageNumber = _sliderPreviewPage ?? _currentPageNumber;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color:
                    _currentIndex > 0
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.35),
                onPressed: _currentIndex > 0 ? _goToPreviousPage : null,
              ),
              Expanded(
                child: Slider(
                  min: 1,
                  max: totalPages.toDouble(),
                  divisions: totalPages > 1 ? totalPages - 1 : null,
                  value: sliderPageNumber.clamp(1, totalPages).toDouble(),
                  activeColor: AppColors.secondary,
                  inactiveColor: AppColors.white.withValues(alpha: 0.25),
                  thumbColor: AppColors.white,
                  onChanged: (value) {
                    setState(() => _sliderPreviewPage = value.round());
                  },
                  onChangeEnd: (value) {
                    setState(() => _sliderPreviewPage = null);
                    _goToPageNumber(value.round());
                  },
                ),
              ),
              Text(
                '$sliderPageNumber/$totalPages',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color:
                    _currentIndex < _pages.length - 1
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.35),
                onPressed:
                    _currentIndex < _pages.length - 1 ? _goToNextPage : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final pageController = _pageController;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (pageController == null)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _buildPage(pages[index]),
              ),
            if (_showControls)
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
          ],
        ),
      ),
    );
  }
}
