// ============================================
// pdf_viewer_screen.dart
// Path: lib/features/pdfViewer/ui/pdf_viewer_screen.dart
// ============================================

import 'dart:io';
import 'package:book/core/helpers/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theming/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final bool isLocal; // true if file path, false if URL
  final String? bookTitle; // Optional book title for display

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.isLocal,
    this.bookTitle,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // 1.0 = fit the page naturally with no default zoom-in. The user can still
  // pinch/double-tap to zoom in from here.
  static const double _readerInitialZoom = 1.0;
  static const double _landscapeReaderZoom = 3;

  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isDownloading = false;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;
  double _verticalDragDistance = 0;
  double _horizontalDragDistance = 0;
  final Set<int> _activePointers = {};
  bool _handledPointerSwipe = false;
  bool _ignorePointerSwipe = false;
  bool _showControls = true;
  Offset? _pointerStartPosition;
  String? _errorMessage;

  // Tracks the last known device orientation so we can detect rotations and
  // re-align the viewer to the top of the current page afterwards.
  Orientation? _lastOrientation;

  // True when the user has zoomed in past the default reading zoom level.
  // While zoomed in, vertical/horizontal drags are meant to pan around the
  // page (handled natively by SfPdfViewer) rather than flip pages.
  bool get _isZoomedIn =>
      _pdfViewerController.zoomLevel > _readerInitialZoom + 0.01;

  @override
  void initState() {
    super.initState();
    // Debug print to verify the PDF path
    debugPrint('PdfViewerScreen initialized');
    debugPrint('PDF Path: ${widget.pdfPath}');
    debugPrint('Is Local: ${widget.isLocal}');
  }

  Future<void> _downloadPdf() async {
    if (widget.isLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('file_already_downloaded')),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Request storage permission
      var status = await Permission.storage.request();

      // For Android 13+ (API 33+), storage permission is not needed
      if (Platform.isAndroid) {
        final androidInfo = await Permission.storage.status;
        if (androidInfo.isPermanentlyDenied) {
          openAppSettings();
          setState(() => _isDownloading = false);
          return;
        }
      }

      if (status.isGranted || status.isLimited || Platform.isAndroid) {
        Directory? directory;

        if (Platform.isAndroid) {
          // Try to save to Downloads folder
          directory = Directory('/storage/emulated/0/Download');

          // Fallback to app directory if Download folder doesn't exist
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          // iOS
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final fileName =
              widget.bookTitle != null
                  ? '${widget.bookTitle!.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf'
                  : 'book_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final savePath = '${directory.path}/$fileName';

          // Download the file
          await Dio().download(
            widget.pdfPath,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final progress = (received / total * 100).toStringAsFixed(0);
                debugPrint('Download progress: $progress%');
              }
            },
          );

          if (mounted) {
            setState(() => _isDownloading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('pdf_downloaded_successfully'),
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                action: SnackBarAction(
                  label: context.tr('open'),
                  textColor: AppColors.white,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PdfViewerScreen(
                              pdfPath: savePath,
                              isLocal: true,
                              bookTitle: widget.bookTitle,
                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('download_failed')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (context) {
        int targetPage = _currentPage;
        return AlertDialog(
          title: Text(context.tr('go_to_page')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.tr('current_page')}: $_currentPage / $_totalPages',
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('page_number'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  targetPage = int.tryParse(value) ?? _currentPage;
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
                if (targetPage > 0 && targetPage <= _totalPages) {
                  _pdfViewerController.jumpToPage(targetPage);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${context.tr('please_enter_page_between')} 1 - $_totalPages',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(context.tr('go')),
            ),
          ],
        );
      },
    );
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });
    _applyOrientationZoom(MediaQuery.orientationOf(context));
  }

  void _handlePageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });

    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      _applyOrientationZoom(Orientation.landscape);
    }
  }

  void _handleDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() {
      _errorMessage = details.error;
      _isLoading = false;
    });
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) {
      return;
    }

    _pdfViewerController.jumpToPage(page);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  // Called whenever the device orientation flips (portrait <-> landscape).
  // Landscape uses a stronger reading zoom, then snaps back to the top of the
  // current page so the zoomed view starts in a predictable position.
  void _handleOrientationChanged(Orientation orientation) {
    final isFirstLandscape =
        _lastOrientation == null && orientation == Orientation.landscape;
    final didRotate =
        _lastOrientation != null && _lastOrientation != orientation;
    _lastOrientation = orientation;

    if (didRotate || isFirstLandscape) {
      _applyOrientationZoom(orientation);
    }
  }

  void _applyOrientationZoom(Orientation orientation) {
    if (_totalPages <= 0) {
      return;
    }

    final targetZoom =
        orientation == Orientation.landscape
            ? _landscapeReaderZoom
            : _readerInitialZoom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _totalPages <= 0) {
        return;
      }

      _pdfViewerController.zoomLevel = targetZoom;
      _pdfViewerController.jumpToPage(_currentPage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _pdfViewerController.jumpTo(yOffset: 0);
      });
    });
  }

  void _startPointerSwipe(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    _pointerStartPosition = event.position;
    if (_activePointers.length > 1) {
      _ignorePointerSwipe = true;
      _handledPointerSwipe = true;
      return;
    }

    _verticalDragDistance = 0;
    _horizontalDragDistance = 0;
    _handledPointerSwipe = false;
    _ignorePointerSwipe = false;
  }

  void _updatePointerSwipe(PointerMoveEvent event) {
    if (_ignorePointerSwipe ||
        _activePointers.length != 1 ||
        _handledPointerSwipe ||
        _isZoomedIn) {
      // When zoomed in, let SfPdfViewer's native pan handle the drag instead
      // of hijacking it as a page-flip swipe.
      return;
    }

    _verticalDragDistance += event.delta.dy;
    _horizontalDragDistance += event.delta.dx;

    final verticalDistance = _verticalDragDistance.abs();
    final horizontalDistance = _horizontalDragDistance.abs();
    if (verticalDistance < 24 || verticalDistance < horizontalDistance * 0.85) {
      return;
    }

    _handledPointerSwipe = true;
    if (_verticalDragDistance < 0) {
      _goToNextPage();
    } else {
      _goToPreviousPage();
    }
  }

  void _endPointerSwipe(PointerUpEvent event) {
    if (_ignorePointerSwipe || _activePointers.length != 1) {
      _activePointers.remove(event.pointer);
      if (_activePointers.isEmpty) {
        _ignorePointerSwipe = false;
        _handledPointerSwipe = false;
      }
      return;
    }

    _activePointers.remove(event.pointer);
    if (_handledPointerSwipe) {
      _pointerStartPosition = null;
      return;
    }

    final verticalDistance = _verticalDragDistance.abs();
    final horizontalDistance = _horizontalDragDistance.abs();
    final startPosition = _pointerStartPosition;
    final tapDistance =
        startPosition == null
            ? double.infinity
            : (event.position - startPosition).distance;

    _pointerStartPosition = null;

    if (tapDistance <= 12 && verticalDistance < 12 && horizontalDistance < 12) {
      // Taps (edge-navigation / center toggle) still work even while zoomed.
      _handlePageTap(event.position);
      return;
    }

    // Only treat this drag as a page-flip swipe if the user isn't zoomed in.
    if (_isZoomedIn) {
      return;
    }

    if (verticalDistance < 14 || verticalDistance < horizontalDistance * 0.85) {
      return;
    }

    if (_verticalDragDistance < 0) {
      _goToNextPage();
    } else {
      _goToPreviousPage();
    }
  }

  void _cancelPointerSwipe(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isNotEmpty) {
      return;
    }

    _verticalDragDistance = 0;
    _horizontalDragDistance = 0;
    _handledPointerSwipe = false;
    _ignorePointerSwipe = false;
    _pointerStartPosition = null;
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
      _toggleControls();
    }
  }

  Widget _buildPageSlider() {
    final totalPages = _totalPages;
    final currentPage = _currentPage.clamp(1, totalPages);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return SafeArea(
      top: false,
      child: Padding(
        padding:
            isLandscape
                ? const EdgeInsets.fromLTRB(18, 0, 18, 6)
                : const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                isLandscape
                    ? const EdgeInsets.fromLTRB(12, 4, 12, 4)
                    : const EdgeInsets.fromLTRB(10, 6, 10, 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLandscape)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currentPage',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ $totalPages',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                        icon: const Icon(Icons.chevron_left),
                        color:
                            currentPage > 1
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.35),
                        onPressed: currentPage > 1 ? _goToPreviousPage : null,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                        icon: const Icon(Icons.chevron_right),
                        color:
                            currentPage < totalPages
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.35),
                        onPressed:
                            currentPage < totalPages ? _goToNextPage : null,
                      ),
                    ],
                  ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: isLandscape ? 2 : 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      min: 1,
                      max: totalPages.toDouble(),
                      divisions:
                          totalPages > 1 && totalPages <= 1000
                              ? totalPages - 1
                              : null,
                      value: currentPage.toDouble(),
                      activeColor: AppColors.secondary,
                      inactiveColor: AppColors.white.withValues(alpha: 0.2),
                      thumbColor: AppColors.white,
                      onChanged: (value) => _goToPage(value.round()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.white,
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.bookTitle ?? context.tr('pdf_viewer'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_totalPages > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          '$_currentPage/$_totalPages',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!widget.isLocal)
                  IconButton(
                    icon:
                        _isDownloading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.download),
                    color: AppColors.white,
                    onPressed: _isDownloading ? null : _downloadPdf,
                    tooltip: context.tr('download_pdf'),
                  ),
                if (_totalPages > 0)
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered),
                    color: AppColors.white,
                    onPressed: _showPageNavigator,
                    tooltip: context.tr('go_to_page'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    final commonKey = ValueKey('${widget.pdfPath}-${widget.isLocal}');
    final viewer =
        widget.isLocal
            ? SfPdfViewer.file(
              File(widget.pdfPath),
              key: commonKey,
              controller: _pdfViewerController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.horizontal,
              pageSpacing: 0,
              initialZoomLevel: _readerInitialZoom,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              canShowPageLoadingIndicator: false,
              enableDoubleTapZooming: true,
              interactionMode: PdfInteractionMode.pan,
              onDocumentLoaded: _handleDocumentLoaded,
              onPageChanged: _handlePageChanged,
              onDocumentLoadFailed: _handleDocumentLoadFailed,
            )
            : SfPdfViewer.network(
              widget.pdfPath,
              key: commonKey,
              controller: _pdfViewerController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.horizontal,
              pageSpacing: 0,
              initialZoomLevel: _readerInitialZoom,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              canShowPageLoadingIndicator: false,
              enableDoubleTapZooming: true,
              interactionMode: PdfInteractionMode.pan,
              onDocumentLoaded: _handleDocumentLoaded,
              onPageChanged: _handlePageChanged,
              onDocumentLoadFailed: _handleDocumentLoadFailed,
            );

    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          inverseSurface: AppColors.white,
          onInverseSurface: AppColors.textPrimary,
        ),
      ),
      child: ColoredBox(color: AppColors.white, child: viewer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return OrientationBuilder(
      builder: (context, orientation) {
        _handleOrientationChanged(orientation);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: AppColors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: AppColors.white,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: SizedBox(
              // Force the body to occupy the FULL device width and height,
              // including the space normally reserved for the app bar/status bar.
              width: size.width,
              height: size.height,
              child:
                  _errorMessage != null
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('failed_to_load_pdf'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: Text(context.tr('go_back')),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: _startPointerSwipe,
                              onPointerMove: _updatePointerSwipe,
                              onPointerUp: _endPointerSwipe,
                              onPointerCancel: _cancelPointerSwipe,
                              child: _buildPdfViewer(),
                            ),
                          ),
                          if (_isLoading)
                            ColoredBox(
                              color: AppColors.white,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.tr('loading_pdf'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_showControls && !_isLoading)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: _buildTopControls(),
                            ),
                          if (_showControls && _totalPages > 0 && !_isLoading)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildPageSlider(),
                            ),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }
}
