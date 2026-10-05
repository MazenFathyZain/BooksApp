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
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/di/dependency_injection.dart';
import '../../downloads/data/downloaded_books_repo.dart';
import '../../favorite/data/repos/favorite_repo.dart';
import '../../home/data/models/add_favorite_request.dart';
import '../../home/data/models/books_response.dart';
import '../../home/data/models/category_tree_response.dart';
import '../../home/data/repos/home_repo.dart';
import 'paged_pdf_reader_screen.dart';

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
  bool _openPdfWhenPagesReady = false;
  bool _isPollingPdfPages = false;
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
        await getIt<HomeRepo>().addToFavorite(
          AddFavoriteRequest(bookId: bookId),
        );
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

  Future<void> _handleDownload(
    String url,
    String fileName,
    String type, {
    BooksResponse? book,
  }) async {
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
        final lastSegment =
            uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
        final dotIndex = lastSegment.lastIndexOf('.');
        extension = dotIndex != -1 ? lastSegment.substring(dotIndex) : '.mp3';
      }

      final cleanFileName = fileName
          .trim()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final safeFileName =
          cleanFileName.isEmpty
              ? 'book_${DateTime.now().millisecondsSinceEpoch}'
              : cleanFileName;
      final filePath = '${directory.path}/$safeFileName$extension';

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

      if (type == 'pdf' && book != null) {
        final localImagePath = await _downloadBookCoverIfAvailable(
          dio: dio,
          directory: directory,
          book: book,
          safeFileName: safeFileName,
        );
        await DownloadedBooksRepo().saveDownloadedBook(
          book: book,
          localPdfPath: filePath,
          localImagePath: localImagePath,
        );
      }

      if (mounted) {
        setState(() {
          if (type == 'pdf') _isDownloadingPdf = false;
          if (type == 'word') _isDownloadingWord = false;
          if (type == 'audio') _isDownloadingAudio = false;
          _downloadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('downloaded')}:\n$filePath'),
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
            content: Text('${context.tr('download_failed')}: ${e.toString()}'),
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

  Future<String?> _downloadBookCoverIfAvailable({
    required Dio dio,
    required Directory directory,
    required BooksResponse book,
    required String safeFileName,
  }) async {
    final resolvedImageUrl = resolveMediaUrl(book.imageUrl);
    if (resolvedImageUrl == null || resolvedImageUrl.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.tryParse(resolvedImageUrl);
      final lastSegment =
          uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
      final dotIndex = lastSegment.lastIndexOf('.');
      final extension =
          dotIndex != -1 ? lastSegment.substring(dotIndex) : '.jpg';
      final imagePath = '${directory.path}/${safeFileName}_cover$extension';
      await dio.download(resolvedImageUrl, imagePath);
      return imagePath;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findDownloadedPdfPath(BooksResponse book) async {
    final bookId = book.id;
    final downloads = await DownloadedBooksRepo().getDownloadedBooks();
    for (final item in downloads) {
      final sameBook =
          bookId != null && bookId.isNotEmpty && item.book.id == bookId;
      final samePdf =
          book.pdfUrl != null &&
          book.pdfUrl!.isNotEmpty &&
          item.book.pdfUrl == book.pdfUrl;

      if ((sameBook || samePdf) && File(item.localPdfPath).existsSync()) {
        return item.localPdfPath;
      }
    }
    return null;
  }

  String _safeFileNameBase(BooksResponse book, String fallbackTitle) {
    final rawName =
        (book.id?.isNotEmpty == true ? book.id : fallbackTitle) ??
        'book_${DateTime.now().millisecondsSinceEpoch}';

    final cleanName = rawName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return cleanName.isEmpty
        ? 'book_${DateTime.now().millisecondsSinceEpoch}'
        : cleanName;
  }

  Future<String> _downloadPdfForReading({
    required BooksResponse book,
    required String resolvedPdfUrl,
    required String title,
  }) async {
    final Directory directory = await _getDownloadDirectory();
    await directory.create(recursive: true);

    final safeFileName = _safeFileNameBase(book, title);
    final filePath = '${directory.path}/$safeFileName.pdf';
    final tempPath = '$filePath.part';
    final file = File(filePath);

    if (await file.exists() && await file.length() > 0) {
      await DownloadedBooksRepo().saveDownloadedBook(
        book: book,
        localPdfPath: filePath,
      );
      return filePath;
    }

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 10),
      ),
    );

    await dio.download(
      resolvedPdfUrl,
      tempPath,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (!mounted || total <= 0) {
          return;
        }

        setState(() {
          _downloadProgress = received / total;
        });
      },
    );

    await tempFile.rename(filePath);

    final localImagePath = await _downloadBookCoverIfAvailable(
      dio: dio,
      directory: directory,
      book: book,
      safeFileName: safeFileName,
    );
    await DownloadedBooksRepo().saveDownloadedBook(
      book: book,
      localPdfPath: filePath,
      localImagePath: localImagePath,
    );

    return filePath;
  }

  Future<void> _handleReadPdf(BooksResponse book) async {
    if (_isDownloadingPdf) {
      return;
    }

    final pdfUrl = book.pdfUrl;
    final title = book.title ?? context.tr('pdf_viewer');
    final pdfPages = book.pdfPages ?? const [];
    final resolvedPdfUrl = resolveMediaUrl(pdfUrl);
    if (pdfPages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PagedPdfReaderScreen(
                title: title,
                pages: pdfPages,
                totalPageCount: book.pdfPageCount,
                originalPdfUrl: resolvedPdfUrl,
              ),
        ),
      );
      return;
    }

    if (resolvedPdfUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('failed_to_load_pdf')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (book.pdfPagesStatus == 'processing') {
      _openPdfWhenPagesReady = true;
      _pollPdfPagesUntilReady();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('loading_pdf')),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (book.pdfPagesStatus == 'failed') {
      _openOriginalPdf(resolvedPdfUrl, title);
      return;
    }

    try {
      final cachedPath = await _findDownloadedPdfPath(book);
      if (!mounted) {
        return;
      }

      if (cachedPath != null) {
        Navigator.pushNamed(
          context,
          '/pdf_reader',
          arguments: {'pdfUrl': cachedPath, 'title': title, 'isLocal': true},
        );
        return;
      }

      setState(() {
        _isDownloadingPdf = true;
        _downloadProgress = 0.0;
      });

      final localPath = await _downloadPdfForReading(
        book: book,
        resolvedPdfUrl: resolvedPdfUrl,
        title: title,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isDownloadingPdf = false;
        _downloadProgress = 0.0;
      });

      Navigator.pushNamed(
        context,
        '/pdf_reader',
        arguments: {'pdfUrl': localPath, 'title': title, 'isLocal': true},
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDownloadingPdf = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('failed_to_load_pdf')}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openOriginalPdf(String resolvedPdfUrl, String title) {
    Navigator.pushNamed(
      context,
      '/pdf_reader',
      arguments: {'pdfUrl': resolvedPdfUrl, 'title': title},
    );
  }

  void _pollPdfPagesUntilReady() {
    if (_isPollingPdfPages) {
      return;
    }

    final bookId = _bookId;
    if (bookId == null || bookId.isEmpty) {
      return;
    }

    _isPollingPdfPages = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_openPdfWhenPagesReady) {
        _isPollingPdfPages = false;
        return;
      }

      context.read<BookDetailsCubit>().getBookById(bookId);
      _isPollingPdfPages = false;
    });
  }

  void _handlePlayAudio(
    String audioUrl,
    String title,
    String author,
    String? imageUrl,
  ) {
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
      arguments: {'wordUrl': resolvedWordUrl, 'title': title},
    );
  }

  Future<void> _showEditBookDialog(BooksResponse book) async {
    final titleController = TextEditingController(text: book.title ?? '');
    final authorController = TextEditingController(text: book.author ?? '');
    final categoryController = TextEditingController(text: book.category ?? '');
    final descriptionController = TextEditingController(
      text: book.description ?? '',
    );
    File? selectedImage;
    File? selectedPdf;
    File? selectedWord;
    File? selectedAudio;
    String? imageFileName;
    String? pdfFileName;
    String? wordFileName;
    String? audioFileName;
    List<CategoryTreeResponse> categories = const [];
    CategoryTreeResponse? selectedCategory;
    CategoryTreeResponse? selectedSubCategory;

    CategoryTreeResponse? findCategoryById(
      List<CategoryTreeResponse> items,
      String? id,
    ) {
      if (id == null || id.isEmpty) {
        return null;
      }

      for (final item in items) {
        if (item.id == id) {
          return item;
        }
      }
      return null;
    }

    try {
      categories = await getIt<HomeRepo>().getCategoryTree();
      selectedCategory =
          findCategoryById(categories, book.categoryId) ??
          categories
              .where((category) => category.name == book.category)
              .cast<CategoryTreeResponse?>()
              .firstWhere((category) => category != null, orElse: () => null);
      selectedSubCategory =
          findCategoryById(
            selectedCategory?.children ?? const [],
            book.subCategoryId,
          ) ??
          (selectedCategory?.children ?? const [])
              .where((category) => category.name == book.subCategory)
              .cast<CategoryTreeResponse?>()
              .firstWhere((category) => category != null, orElse: () => null);
    } catch (_) {
      categories = const [];
    }

    Future<void> pickReplacementFile({
      required StateSetter setDialogState,
      required FileType type,
      List<String>? allowedExtensions,
      required void Function(File file, String fileName) onPicked,
    }) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: type,
          allowedExtensions: allowedExtensions,
        );

        final path = result?.files.single.path;
        if (path == null) {
          return;
        }

        setDialogState(() {
          onPicked(File(path), result!.files.single.name);
        });
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error_picking_file')} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOpacity10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dialogContext.tr('edit_book'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditSectionTitle(
                          dialogContext.tr('basic_information'),
                        ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          controller: titleController,
                          label: dialogContext.tr('book_title'),
                          icon: Icons.book,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          controller: authorController,
                          label: dialogContext.tr('author'),
                          icon: Icons.person,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        if (categories.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: selectedCategory?.id,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: dialogContext.tr('category'),
                              prefixIcon: const Icon(Icons.category),
                              border: const OutlineInputBorder(),
                            ),
                            items:
                                categories
                                    .map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category.id,
                                        child: Text(category.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (categoryId) {
                              setDialogState(() {
                                selectedCategory = findCategoryById(
                                  categories,
                                  categoryId,
                                );
                                selectedSubCategory = null;
                                categoryController.text =
                                    selectedCategory?.name ?? '';
                              });
                            },
                          ),
                          if ((selectedCategory?.children ?? const [])
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedSubCategory?.id,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: dialogContext.tr(
                                  'select_sub_category',
                                ),
                                prefixIcon: const Icon(Icons.account_tree),
                                border: const OutlineInputBorder(),
                              ),
                              items:
                                  selectedCategory!.children
                                      .map(
                                        (subCategory) =>
                                            DropdownMenuItem<String>(
                                              value: subCategory.id,
                                              child: Text(subCategory.name),
                                            ),
                                      )
                                      .toList(),
                              onChanged: (subCategoryId) {
                                setDialogState(() {
                                  selectedSubCategory = findCategoryById(
                                    selectedCategory?.children ?? const [],
                                    subCategoryId,
                                  );
                                });
                              },
                            ),
                          ],
                        ] else
                          _buildEditTextField(
                            controller: categoryController,
                            label: dialogContext.tr('category'),
                            icon: Icons.category,
                            textInputAction: TextInputAction.next,
                          ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          controller: descriptionController,
                          label: dialogContext.tr('description'),
                          icon: Icons.notes,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 22),
                        _buildEditSectionTitle(
                          dialogContext.tr('replacement_files'),
                        ),
                        const SizedBox(height: 12),
                        _buildReplacementFileTile(
                          icon: Icons.image,
                          title: dialogContext.tr('replace_image'),
                          subtitle:
                              imageFileName ??
                              (book.imageUrl?.isNotEmpty == true
                                  ? dialogContext.tr('current_file_exists')
                                  : dialogContext.tr('no_file_selected')),
                          isSelected: selectedImage != null,
                          onTap:
                              () => pickReplacementFile(
                                setDialogState: setDialogState,
                                type: FileType.image,
                                onPicked: (file, fileName) {
                                  selectedImage = file;
                                  imageFileName = fileName;
                                },
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildReplacementFileTile(
                          icon: Icons.picture_as_pdf,
                          title: dialogContext.tr('replace_pdf'),
                          subtitle:
                              pdfFileName ??
                              (book.pdfUrl?.isNotEmpty == true
                                  ? dialogContext.tr('current_file_exists')
                                  : dialogContext.tr('no_file_selected')),
                          isSelected: selectedPdf != null,
                          onTap:
                              () => pickReplacementFile(
                                setDialogState: setDialogState,
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                                onPicked: (file, fileName) {
                                  selectedPdf = file;
                                  pdfFileName = fileName;
                                },
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildReplacementFileTile(
                          icon: Icons.description,
                          title: dialogContext.tr('replace_word'),
                          subtitle:
                              wordFileName ??
                              (book.wordUrl?.isNotEmpty == true
                                  ? dialogContext.tr('current_file_exists')
                                  : dialogContext.tr('no_file_selected')),
                          isSelected: selectedWord != null,
                          onTap:
                              () => pickReplacementFile(
                                setDialogState: setDialogState,
                                type: FileType.custom,
                                allowedExtensions: ['doc', 'docx'],
                                onPicked: (file, fileName) {
                                  selectedWord = file;
                                  wordFileName = fileName;
                                },
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildReplacementFileTile(
                          icon: Icons.audiotrack,
                          title: dialogContext.tr('replace_audio'),
                          subtitle:
                              audioFileName ??
                              (book.audioUrl?.isNotEmpty == true
                                  ? dialogContext.tr('current_file_exists')
                                  : dialogContext.tr('no_file_selected')),
                          isSelected: selectedAudio != null,
                          onTap:
                              () => pickReplacementFile(
                                setDialogState: setDialogState,
                                type: FileType.custom,
                                allowedExtensions: [
                                  'mp3',
                                  'wav',
                                  'm4a',
                                  'aac',
                                  'ogg',
                                ],
                                onPicked: (file, fileName) {
                                  selectedAudio = file;
                                  audioFileName = fileName;
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(dialogContext.tr('cancel')),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, {
                        'title': titleController.text.trim(),
                        'author': authorController.text.trim(),
                        'category': categoryController.text.trim(),
                        'categoryId': selectedCategory?.id,
                        'subCategoryId': selectedSubCategory?.id,
                        'description': descriptionController.text.trim(),
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(dialogContext.tr('save_changes')),
                  ),
                ],
              );
            },
          );
        },
      );

      final bookId = _bookId;
      if (result == null || bookId == null || bookId.isEmpty || !mounted) {
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      context.read<BookDetailsCubit>().updateBookById(
        bookId,
        result,
        image: selectedImage,
        pdf: selectedPdf,
        word: selectedWord,
        audio: selectedAudio,
      );
    } finally {
      titleController.dispose();
      authorController.dispose();
      categoryController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _buildEditSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildReplacementFileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryOpacity20,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.upload_file,
              color: isSelected ? AppColors.success : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBook() async {
    final bookId = _bookId;
    if (bookId == null || bookId.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('delete_book')),
          content: Text(context.tr('delete_book_confirmation')),
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
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<BookDetailsCubit>().deleteBookById(bookId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookDetailsCubit, BookDetailsState>(
        listener: (context, state) {
          final BooksResponse? refreshedBook = switch (state) {
            BookDetailsSuccess(:final response) => response,
            BookDetailsUpdated(:final response) => response,
            _ => null,
          };

          if (_openPdfWhenPagesReady && refreshedBook != null) {
            final pages = refreshedBook.pdfPages ?? const [];
            if (pages.isNotEmpty) {
              _openPdfWhenPagesReady = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _handleReadPdf(refreshedBook);
                }
              });
            } else if (refreshedBook.pdfPagesStatus == 'processing') {
              _pollPdfPagesUntilReady();
            } else {
              _openPdfWhenPagesReady = false;
            }
          }

          if (state is BookDetailsUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('book_updated_successfully')),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is BookDetailsDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('book_deleted_successfully')),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          if (state is BookDetailsLoading || state is BookDetailsDeleting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is BookDetailsFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(context.tr('go_back')),
                    ),
                  ],
                ),
              ),
            );
          }

          final BooksResponse? book = switch (state) {
            BookDetailsSuccess(:final response) => response,
            BookDetailsUpdating(:final response) => response,
            BookDetailsUpdated(:final response) => response,
            _ => null,
          };

          if (book != null) {
            final isUpdating = state is BookDetailsUpdating;
            final String title = book.title ?? context.tr('untitled');
            final String author = book.author ?? context.tr('unknown');
            final String category = [
              book.category,
              book.subCategory,
            ].whereType<String>().where((v) => v.isNotEmpty).join(' / ');
            final String categoryLabel =
                category.isNotEmpty ? category : context.tr('general_category');
            final String description = book.description ?? '';

            final String? pdfUrl = book.pdfUrl;
            final String? wordUrl = book.wordUrl;
            final String? audioUrl = book.audioUrl;
            final String? imageUrl = book.imageUrl;
            final String? resolvedImageUrl = resolveMediaUrl(imageUrl);

            final bool hasContent =
                (pdfUrl != null && pdfUrl.isNotEmpty) ||
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
                    if (isAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        tooltip: context.tr('edit_book'),
                        onPressed:
                            isUpdating ? null : () => _showEditBookDialog(book),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                        tooltip: context.tr('delete_book'),
                        onPressed: isUpdating ? null : _confirmDeleteBook,
                      ),
                    ],
                    if (isUpdating)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
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
                          colors: [AppColors.primary, AppColors.primaryDark],
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
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      (resolvedImageUrl != null &&
                                              resolvedImageUrl.isNotEmpty)
                                          ? Image.network(
                                            resolvedImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
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
                          '${context.tr('by')} $author',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOpacity10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            categoryLabel,
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
                              label:
                                  _isDownloadingPdf
                                      ? context.tr('loading_pdf')
                                      : context.tr('read_pdf'),
                              color: AppColors.primary,
                              onTap: () => _handleReadPdf(book),
                              onDownload:
                                  _isDownloadingPdf
                                      ? null
                                      : () => _handleDownload(
                                        pdfUrl,
                                        title,
                                        'pdf',
                                        book: book,
                                      ),
                              isDownloading: _isDownloadingPdf,
                              progress: _downloadProgress,
                            ),

                          if (wordUrl != null && wordUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.description,
                              label: context.tr('open_word'),
                              color: Color(0xFF4CAF50),
                              onTap: () => _handleOpenWord(wordUrl, title),
                              onDownload:
                                  _isDownloadingWord
                                      ? null
                                      : () => _handleDownload(
                                        wordUrl,
                                        title,
                                        'word',
                                      ),
                              isDownloading: _isDownloadingWord,
                              progress: _downloadProgress,
                            ),
                          ],

                          if (audioUrl != null && audioUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.play_circle_filled,
                              label: context.tr('play_audio'),
                              color: Color(0xFFFF9800),
                              onTap:
                                  () => _handlePlayAudio(
                                    audioUrl,
                                    title,
                                    author,
                                    imageUrl,
                                  ),
                              onDownload:
                                  _isDownloadingAudio
                                      ? null
                                      : () => _handleDownload(
                                        audioUrl,
                                        title,
                                        'audio',
                                      ),
                              isDownloading: _isDownloadingAudio,
                              progress: _downloadProgress,
                            ),
                          ],
                        ],

                        // Description
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            context.tr('about'),
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
                          context.tr('details'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailsCard([
                          if (book.language != null &&
                              book.language!.isNotEmpty)
                            _DetailItem(
                              icon: Icons.language,
                              label: context.tr('language'),
                              value: book.language!,
                            ),
                          if (book.publisher != null &&
                              book.publisher!.isNotEmpty)
                            _DetailItem(
                              icon: Icons.business,
                              label: context.tr('publisher'),
                              value: book.publisher!,
                            ),
                          if (book.publicationYear != null)
                            _DetailItem(
                              icon: Icons.calendar_today,
                              label: context.tr('publication_year'),
                              value: book.publicationYear.toString(),
                            ),
                          if (book.partsCount != null)
                            _DetailItem(
                              icon: Icons.collections_bookmark,
                              label: context.tr('parts_count'),
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
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
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
          Container(width: 1, height: 40, color: AppColors.background),
          Expanded(
            flex: 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDownload,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child:
                      isDownloading
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
                          : Icon(Icons.download, color: color, size: 22),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            item.value,
            textAlign: TextAlign.end,
            softWrap: true,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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

  _DetailItem({required this.icon, required this.label, required this.value});
}
