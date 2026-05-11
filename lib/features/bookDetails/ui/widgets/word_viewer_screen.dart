import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/helpers/media_url_helper.dart';

class WordViewerScreen extends StatefulWidget {
  const WordViewerScreen({super.key});

  @override
  State<WordViewerScreen> createState() => _WordViewerScreenState();
}

class _WordViewerScreenState extends State<WordViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String wordUrl = args?['wordUrl'] as String? ?? '';
    final String bookTitle = args?['title'] as String? ?? 'Word Viewer';

    if (wordUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(bookTitle)),
        body: const Center(child: Text('Word document URL not provided')),
      );
    }

    // Use Google Docs Viewer to display Word files
    final String viewerUrl = 'https://docs.google.com/viewer?url=$wordUrl&embedded=true';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          bookTitle,
          style: const TextStyle(color: AppColors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.white),
            onPressed: () => _downloadWord(wordUrl, bookTitle),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _downloadWord(wordUrl, bookTitle),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                loadWithOverviewMode: true,
                useWideViewPort: true,
                supportZoom: true,
                builtInZoomControls: true,
                displayZoomControls: false,
              ),
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onReceivedError: (controller, request, error) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      'Failed to load document. You can download it instead.';
                });
              },
            ),
          if (_isLoading)
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _progress > 0
                          ? 'Loading... ${(_progress * 100).toInt()}%'
                          : 'Loading document...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadWord(String wordUrl, String bookTitle) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final resolvedUrl = resolveMediaUrl(wordUrl) ?? wordUrl;

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        final baseDir = await getExternalStorageDirectory();
        if (baseDir != null) {
          directory = Directory('${baseDir.path}/downloads');
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not find download directory');
      }
      await directory.create(recursive: true);

      // Create file name
      final fileName = bookTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final extension =
          resolvedUrl.toLowerCase().contains('.docx') ? '.docx' : '.doc';
      final filePath = '${directory.path}/$fileName$extension';

      // Download the file
      final dio = Dio();
      await dio.download(resolvedUrl, filePath);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded:\n$filePath'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
