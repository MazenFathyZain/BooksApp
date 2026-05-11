import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/media_url_helper.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/routing/routes.dart';
import '../logic/book_details_cubit.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/di/dependency_injection.dart';
import '../../favorite/data/repos/favorite_repo.dart';
import '../../home/data/models/add_favorite_request.dart';
import '../../home/data/repos/home_repo.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isDownloadingPdf = false;
  bool _isDownloadingWord = false;
  bool _isDownloadingAudio = false;
  double _downloadProgress = 0.0;
  String? _bookId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      String? id;
      bool? isSaved;

      if (args is String) {
        id = args;
      } else if (args is Map) {
        final dynamic rawId = args['id'] ?? args['bookId'];
        if (rawId is String) {
          id = rawId;
        }
        final dynamic rawSaved = args['isSaved'];
        if (rawSaved is bool) {
          isSaved = rawSaved;
        }
      }

      if (id == null || id.isEmpty) {
        return;
      }

      _bookId = id;
      if (isSaved == true) {
        setState(() => _isSaved = true);
      }

      context.read<BookDetailsCubit>().getBookById(id);

      // If caller didn't know whether it's saved, verify from server in background.
      if (isLoggedInUser && isSaved != true) {
        _hydrateSavedStatus(id);
      }
    });
  }

  Future<void> _hydrateSavedStatus(String bookId) async {
    try {
      final favorites = await getIt<FavoriteRepo>().getFavoriteBooks();
      if (!mounted) {
        return;
      }

      final isFavorite = favorites.any((book) => book.id == bookId);
      if (isFavorite && !_isSaved) {
        setState(() => _isSaved = true);
      }
    } catch (_) {
      // Ignore: not critical for details screen.
    }
  }

  Future<void> _toggleSave() async {
    if (!isLoggedInUser) {
      await _confirmLoginRequired('login_to_save_books');
      return;
    }

    final bookId = _bookId;
    if (bookId == null || bookId.isEmpty) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Backend currently exposes "add to favorite/saved" only.
      // We keep the UI simple: saving calls the API; unsaving is local-only.
      if (!_isSaved) {
        await getIt<HomeRepo>().addToFavorite(AddFavoriteRequest(bookId: bookId));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('book_saved')),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_occurred')} ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmLoginRequired(String messageKey) async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('login_required')),
            content: Text(context.tr(messageKey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr('login')),
              ),
            ],
          ),
    );

    if (shouldLogin == true && mounted) {
      await context.pushNamed(Routes.loginScreen);
    }
  }

  Future<void> _handleDownload(String url, String fileName, String type) async {
    setState(() {
      if (type == 'pdf') _isDownloadingPdf = true;
      if (type == 'word') _isDownloadingWord = true;
      if (type == 'audio') _isDownloadingAudio = true;
      _downloadProgress = 0.0;
    });

    try {
      final resolvedUrl = resolveMediaUrl(url);
      if (resolvedUrl == null) {
        throw Exception('Invalid file url');
      }

      final Directory directory = await _getDownloadDirectory();
      await directory.create(recursive: true);

      String extension = '';
      if (type == 'pdf') {
        extension = '.pdf';
      } else if (type == 'word') {
        extension = url.toLowerCase().contains('.docx') ? '.docx' : '.doc';
      } else if (type == 'audio') {
        final uri = Uri.tryParse(resolvedUrl);
        final lastSegment = uri?.pathSegments.isNotEmpty == true
            ? uri!.pathSegments.last
            : '';
        final dotIndex = lastSegment.lastIndexOf('.');
        extension =
            dotIndex != -1 ? lastSegment.substring(dotIndex) : '.mp3';
      }

      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final filePath = '${directory.path}/$cleanFileName$extension';

      final dio = Dio();
      await dio.download(
        resolvedUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          if (type == 'pdf') _isDownloadingPdf = false;
          if (type == 'word') _isDownloadingWord = false;
          if (type == 'audio') _isDownloadingAudio = false;
          _downloadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded:\n$filePath'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (type == 'pdf') _isDownloadingPdf = false;
          if (type == 'word') _isDownloadingWord = false;
          if (type == 'audio') _isDownloadingAudio = false;
          _downloadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        return Directory('${baseDir.path}/downloads');
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  void _handleReadPdf(String pdfUrl, String title) {
    final resolvedPdfUrl = resolveMediaUrl(pdfUrl);
    if (resolvedPdfUrl == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/pdf_reader',
      arguments: {
        'pdfUrl': resolvedPdfUrl,
        'title': title,
      },
    );
  }

  void _handlePlayAudio(String audioUrl, String title, String author, String? imageUrl) {
    final resolvedAudioUrl = resolveMediaUrl(audioUrl);
    if (resolvedAudioUrl == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/audio_player',
      arguments: {
        'audioUrl': resolvedAudioUrl,
        'title': title,
        'author': author,
        'imageUrl': resolveMediaUrl(imageUrl),
      },
    );
  }

  void _handleOpenWord(String wordUrl, String title) {
    final resolvedWordUrl = resolveMediaUrl(wordUrl);
    if (resolvedWordUrl == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/word_viewer',
      arguments: {
        'wordUrl': resolvedWordUrl,
        'title': title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<BookDetailsCubit, BookDetailsState>(
        builder: (context, state) {
          if (state is BookDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is BookDetailsFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is BookDetailsSuccess) {
            final book = state.response;
            final String title = book.title ?? 'Untitled';
            final String author = book.author ?? 'Unknown';
            final String category = book.category ?? 'General';
            final String description = book.description ?? '';

            final String? pdfUrl = book.pdfUrl;
            final String? wordUrl = book.wordUrl;
            final String? audioUrl = book.audioUrl;
            final String? imageUrl = book.imageUrl;
            final String? resolvedImageUrl = resolveMediaUrl(imageUrl);

            final bool hasContent = (pdfUrl != null && pdfUrl.isNotEmpty) ||
                (wordUrl != null && wordUrl.isNotEmpty) ||
                (audioUrl != null && audioUrl.isNotEmpty);

            return CustomScrollView(
              slivers: [
                // Simplified App Bar
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                              ),
                      onPressed: _isSaving ? null : _toggleSave,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 60),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Book Cover
                              Container(
                                width: 140,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty)
                                      ? Image.network(
                                    resolvedImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholderCover(),
                                  )
                                      : _buildPlaceholderCover(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Author
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'by $author',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOpacity10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        if (hasContent) ...[
                          const SizedBox(height: 24),

                          // Content Buttons
                          if (pdfUrl != null && pdfUrl.isNotEmpty)
                            _buildActionButton(
                              icon: Icons.picture_as_pdf,
                              label: 'Read PDF',
                              color: AppColors.primary,
                              onTap: () => _handleReadPdf(pdfUrl, title),
                              onDownload: _isDownloadingPdf
                                  ? null
                                  : () => _handleDownload(pdfUrl, title, 'pdf'),
                              isDownloading: _isDownloadingPdf,
                              progress: _downloadProgress,
                            ),

                          if (wordUrl != null && wordUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.description,
                              label: 'Open Word',
                              color: Color(0xFF4CAF50),
                              onTap: () => _handleOpenWord(wordUrl, title),
                              onDownload: _isDownloadingWord
                                  ? null
                                  : () => _handleDownload(wordUrl, title, 'word'),
                              isDownloading: _isDownloadingWord,
                              progress: _downloadProgress,
                            ),
                          ],

                          if (audioUrl != null && audioUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.play_circle_filled,
                              label: 'Play Audio',
                              color: Color(0xFFFF9800),
                              onTap: () => _handlePlayAudio(audioUrl, title, author, imageUrl),
                              onDownload: _isDownloadingAudio
                                  ? null
                                  : () => _handleDownload(audioUrl, title, 'audio'),
                              isDownloading: _isDownloadingAudio,
                              progress: _downloadProgress,
                            ),
                          ],
                        ],

                        // Description
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],

                        // Book Details
                        const SizedBox(height: 32),
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailsCard([
                          if (book.language != null && book.language!.isNotEmpty)
                            _DetailItem(
                              icon: Icons.language,
                              label: 'Language',
                              value: book.language!,
                            ),
                          if (book.publisher != null && book.publisher!.isNotEmpty)
                            _DetailItem(
                              icon: Icons.business,
                              label: 'Publisher',
                              value: book.publisher!,
                            ),
                          if (book.publicationYear != null)
                            _DetailItem(
                              icon: Icons.calendar_today,
                              label: 'Year',
                              value: book.publicationYear.toString(),
                            ),
                          if (book.partsCount != null)
                            _DetailItem(
                              icon: Icons.collections_bookmark,
                              label: 'Parts',
                              value: book.partsCount.toString(),
                            ),
                        ]),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: AppColors.surface,
      child: Icon(
        Icons.menu_book_rounded,
        size: 70,
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback? onDownload,
    required bool isDownloading,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.background,
          ),
          Expanded(
            flex: 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDownload,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: isDownloading
                      ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  )
                      : Icon(
                    Icons.download,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(List<_DetailItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildDetailRow(items[i]),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.background),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 20,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
