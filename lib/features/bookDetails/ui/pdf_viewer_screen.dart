// ============================================
// pdf_viewer_screen.dart
// Path: lib/features/pdfViewer/ui/pdf_viewer_screen.dart
// ============================================

import 'dart:io';
import 'package:book/core/helpers/extension.dart';
import 'package:book/core/theming/colors.dart';
import 'package:flutter/material.dart';
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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isDownloading = false;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _errorMessage;

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
          final fileName = widget.bookTitle != null
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
                    const Text(
                      'PDF Downloaded Successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved to: ${directory.path}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Open',
                  textColor: AppColors.white,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
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
              content: const Text('Storage permission is required to download PDF'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Settings',
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
            content: Text('Download failed: ${e.toString()}'),
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
          title: const Text('Go to Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current page: $_currentPage of $_totalPages'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Page number',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (targetPage > 0 && targetPage <= _totalPages) {
                  _pdfViewerController.jumpToPage(targetPage);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a page between 1 and $_totalPages'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          widget.bookTitle ?? 'PDF Viewer',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Download button (only for online PDFs)
          if (!widget.isLocal)
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
                  : const Icon(Icons.download, color: AppColors.white),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Download PDF',
            ),

          // Page navigator
          if (_totalPages > 0)
            IconButton(
              icon: const Icon(Icons.format_list_numbered, color: AppColors.white),
              onPressed: _showPageNavigator,
              tooltip: 'Go to page',
            ),

          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out, color: AppColors.white),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 1) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
              }
            },
            tooltip: 'Zoom out',
          ),

          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in, color: AppColors.white),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
            tooltip: 'Zoom in',
          ),
        ],
      ),
      body: _errorMessage != null
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
                'Failed to load PDF',
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
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          // PDF Viewer
          widget.isLocal
              ? SfPdfViewer.file(
            File(widget.pdfPath),
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (details) {
              setState(() {
                _errorMessage = details.error;
                _isLoading = false;
              });
            },
          )
              : SfPdfViewer.network(
            widget.pdfPath,
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (details) {
              setState(() {
                _errorMessage = details.error;
                _isLoading = false;
              });
            },
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: AppColors.background,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Page indicator at bottom
          if (_totalPages > 0 && !_isLoading)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showPageNavigator,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Navigation FABs
      floatingActionButton: _totalPages > 0 && !_isLoading
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous page
          FloatingActionButton(
            heroTag: 'previous',
            mini: true,
            backgroundColor: _currentPage > 1
                ? AppColors.primary
                : AppColors.primaryOpacity50,
            onPressed: _currentPage > 1
                ? () => _pdfViewerController.previousPage()
                : null,
            child: const Icon(
              Icons.arrow_upward,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Next page
          FloatingActionButton(
            heroTag: 'next',
            mini: true,
            backgroundColor: _currentPage < _totalPages
                ? AppColors.primary
                : AppColors.primaryOpacity50,
            onPressed: _currentPage < _totalPages
                ? () => _pdfViewerController.nextPage()
                : null,
            child: const Icon(
              Icons.arrow_downward,
              color: AppColors.white,
            ),
          ),
        ],
      )
          : null,
    );
  }
}

// ============================================
// Add to localization files:
// ============================================
/*
English (en.json):
{
  "file_already_downloaded": "File already downloaded"
}

Arabic (ar.json):
{
  "file_already_downloaded": "الملف محمل بالفعل"
}
*/