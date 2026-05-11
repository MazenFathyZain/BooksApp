import 'dart:io';
import 'package:book/core/helpers/extension.dart';
import 'package:book/core/helpers/session_helper.dart';
import 'package:book/core/routing/routes.dart';
import 'package:book/features/dashboard/logic/dashboard_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theming/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final bool returnToHomeAfterSave;

  const DashboardScreen({
    super.key,
    this.returnToHomeAfterSave = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _partsCountController = TextEditingController();
  final _subjectController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishingPlaceController = TextEditingController();
  final _publicationYearController = TextEditingController();
  final _bookVersionController = TextEditingController();
  final _centuryController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _categoryController = TextEditingController();
  final _languageController = TextEditingController();
  final _doctrineController = TextEditingController();
  final _translatorsController = TextEditingController();

  File? _selectedPdf;
  String? _pdfFileName;
  File? _selectedImage;
  String? _imageFileName;
  File? _selectedWord;
  String? _wordFileName;
  File? _selectedAudio;
  String? _audioFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _partsCountController.dispose();
    _subjectController.dispose();
    _publisherController.dispose();
    _publishingPlaceController.dispose();
    _publicationYearController.dispose();
    _bookVersionController.dispose();
    _centuryController.dispose();
    _otherNamesController.dispose();
    _categoryController.dispose();
    _languageController.dispose();
    _doctrineController.dispose();
    _translatorsController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_picking_file')} $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _imageFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_picking_image')} $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickWordFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedWord = File(result.files.single.path!);
          _wordFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_picking_file')} $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (result != null) {
        setState(() {
          _selectedAudio = File(result.files.single.path!);
          _audioFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_picking_file')} $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPdf == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('please_select_pdf')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Parse other names (comma-separated)
      List<String> otherNames = _otherNamesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Parse translators (comma-separated)
      List<String> translators = _translatorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      context.read<DashboardCubit>().addBook(
        _titleController.text.trim(),
        _authorController.text.trim(),
        _categoryController.text.trim(),
        _descriptionController.text.trim(),
        _selectedImage,              // ✅ Image first
        _selectedPdf!,               // ✅ Then PDF (required)
        _selectedWord,               // ✅ Then Word
        null,                        // doc parameter (not implemented)
        _selectedAudio,              // ✅ Then Audio
        int.parse(_partsCountController.text.trim()),
        _subjectController.text.trim(),
        _languageController.text.trim(),
        otherNames,
        translators,
        _publisherController.text.trim(),
        _publishingPlaceController.text.trim(),
        int.parse(_publicationYearController.text.trim()),
        _bookVersionController.text.trim(),
        _centuryController.text.trim(),
        _doctrineController.text.trim(),
      );
    }
  }
  void _resetForm() {
    _titleController.clear();
    _authorController.clear();
    _descriptionController.clear();
    _partsCountController.clear();
    _subjectController.clear();
    _publisherController.clear();
    _publishingPlaceController.clear();
    _publicationYearController.clear();
    _bookVersionController.clear();
    _centuryController.clear();
    _otherNamesController.clear();
    _categoryController.clear();
    _languageController.clear();
    _doctrineController.clear();
    _translatorsController.clear();
    setState(() {
      _selectedPdf = null;
      _pdfFileName = null;
      _selectedImage = null;
      _imageFileName = null;
      _selectedWord = null;
      _wordFileName = null;
      _selectedAudio = null;
      _audioFileName = null;
    });
    _formKey.currentState?.reset();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('are_you_sure_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await clearSession();
              if (context.mounted) {
                context.pushNamedAndRemoveUntil(
                  Routes.loginScreen,
                  predicate: (route) => false,
                );
              }
            },
            child: Text(
              context.tr('logout'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
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
          context.tr('add_book'),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions:
            widget.returnToHomeAfterSave
                ? const []
                : [
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.white),
                    onPressed: _showLogoutDialog,
                  ),
                ],
      ),
      body: BlocConsumer<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state is DashboardSuccess) {
            if (widget.returnToHomeAfterSave) {
              Navigator.pop(context, true);
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('book_added_successfully')),
                backgroundColor: AppColors.success,
              ),
            );
            _resetForm();
          }

          if (state is DashboardFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DashboardLoading;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      context.tr('add_book'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('fill_in_details'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Basic Information Section
                    _SectionHeader(title: context.tr('basic_information')),
                    const SizedBox(height: 16),

                    // Book Title Field
                    _CustomTextField(
                      controller: _titleController,
                      label: context.tr('book_title'),
                      hint: context.tr('enter_book_title'),
                      icon: Icons.book,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_title');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Author Field
                    _CustomTextField(
                      controller: _authorController,
                      label: context.tr('author'),
                      hint: context.tr('enter_author_name'),
                      icon: Icons.person,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_author');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category Field
                    _CustomTextField(
                      controller: _categoryController,
                      label: context.tr('category'),
                      hint: context.tr('enter_category'),
                      icon: Icons.category,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_select_category');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    _CustomTextField(
                      controller: _descriptionController,
                      label: context.tr('description'),
                      hint: context.tr('enter_book_description'),
                      icon: Icons.description,
                      maxLines: 4,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_description');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Book Details Section
                    _SectionHeader(title: context.tr('book_details')),
                    const SizedBox(height: 16),

                    // Parts Count
                    _CustomTextField(
                      controller: _partsCountController,
                      label: context.tr('parts_count'),
                      hint: context.tr('enter_number_of_parts'),
                      icon: Icons.format_list_numbered,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_parts_count');
                        }
                        if (int.tryParse(value) == null) {
                          return context.tr('please_enter_valid_number');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subject
                    _CustomTextField(
                      controller: _subjectController,
                      label: context.tr('subject'),
                      hint: context.tr('enter_subject'),
                      icon: Icons.subject,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_subject');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Language Field
                    _CustomTextField(
                      controller: _languageController,
                      label: context.tr('language'),
                      hint: context.tr('enter_language'),
                      icon: Icons.language,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_language');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Other Names
                    _CustomTextField(
                      controller: _otherNamesController,
                      label: context.tr('other_names'),
                      hint: context.tr('enter_other_names'),
                      icon: Icons.text_fields,
                      maxLines: 2,
                      enabled: !isLoading,
                      validator: (value) {
                        // Optional field
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Translators Field
                    _CustomTextField(
                      controller: _translatorsController,
                      label: context.tr('translators'),
                      hint: context.tr('enter_translator_names'),
                      icon: Icons.translate,
                      maxLines: 2,
                      enabled: !isLoading,
                      validator: (value) {
                        // Optional field
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Publishing Information Section
                    _SectionHeader(title: context.tr('publishing_information')),
                    const SizedBox(height: 16),

                    // Publisher
                    _CustomTextField(
                      controller: _publisherController,
                      label: context.tr('publisher'),
                      hint: context.tr('enter_publisher_name'),
                      icon: Icons.business,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_publisher');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Publishing Place
                    _CustomTextField(
                      controller: _publishingPlaceController,
                      label: context.tr('publishing_place'),
                      hint: context.tr('enter_publishing_place'),
                      icon: Icons.location_on,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_publishing_place');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Publication Year
                    _CustomTextField(
                      controller: _publicationYearController,
                      label: context.tr('publication_year'),
                      hint: context.tr('enter_publication_year'),
                      icon: Icons.calendar_today,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_publication_year');
                        }
                        final year = int.tryParse(value);
                        if (year == null) {
                          return context.tr('please_enter_valid_year');
                        }
                        if (year < 1000 || year > DateTime.now().year) {
                          return context.tr('please_enter_valid_year');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Book Version
                    _CustomTextField(
                      controller: _bookVersionController,
                      label: context.tr('book_version'),
                      hint: context.tr('enter_book_version'),
                      icon: Icons.numbers,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_book_version');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Author Information Section
                    _SectionHeader(title: context.tr('author_information')),
                    const SizedBox(height: 16),

                    // Century
                    _CustomTextField(
                      controller: _centuryController,
                      label: context.tr('century'),
                      hint: context.tr('enter_century'),
                      icon: Icons.history,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_century');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Author Doctrine Field
                    _CustomTextField(
                      controller: _doctrineController,
                      label: context.tr('author_doctrine'),
                      hint: context.tr('enter_author_doctrine'),
                      icon: Icons.school,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('please_enter_author_doctrine');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // File Upload Section
                    _SectionHeader(title: context.tr('file_uploads')),
                    const SizedBox(height: 16),

                    // Image Upload (Optional)
                    InkWell(
                      onTap: isLoading ? null : _pickImageFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedImage != null
                                ? AppColors.primary
                                : AppColors.primaryOpacity20,
                            width: _selectedImage != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOpacity10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedImage != null
                                    ? Icons.image
                                    : Icons.add_photo_alternate,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedImage != null
                                        ? context.tr('book_cover_selected')
                                        : context.tr('select_book_cover_image'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedImage != null
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _imageFileName ?? context.tr('optional'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedImage != null)
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryOpacity20,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.primaryOpacity50,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PDF Upload (Required)
                    InkWell(
                      onTap: isLoading ? null : _pickPdfFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPdf != null
                                ? AppColors.primary
                                : AppColors.primaryOpacity20,
                            width: _selectedPdf != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOpacity10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedPdf != null
                                    ? Icons.picture_as_pdf
                                    : Icons.upload_file,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPdf != null
                                        ? context.tr('pdf_selected')
                                        : context.tr('select_pdf_file'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedPdf != null
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _pdfFileName ?? context.tr('required'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primaryOpacity50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Word Upload (Optional)
                    InkWell(
                      onTap: isLoading ? null : _pickWordFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedWord != null
                                ? AppColors.primary
                                : AppColors.primaryOpacity20,
                            width: _selectedWord != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOpacity10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedWord != null
                                    ? Icons.description
                                    : Icons.upload_file,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedWord != null
                                        ? context.tr('word_selected')
                                        : context.tr('select_word_file'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedWord != null
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _wordFileName ?? context.tr('optional'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primaryOpacity50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Audio Upload (Optional)
                    InkWell(
                      onTap: isLoading ? null : _pickAudioFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAudio != null
                                ? AppColors.primary
                                : AppColors.primaryOpacity20,
                            width: _selectedAudio != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOpacity10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedAudio != null
                                    ? Icons.audiotrack
                                    : Icons.upload_file,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAudio != null
                                        ? context.tr('audio_selected')
                                        : context.tr('select_audio_file'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedAudio != null
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _audioFileName ?? context.tr('optional'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primaryOpacity50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primaryOpacity50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('adding_book'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          context.tr('submit'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// Custom Widgets
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryOpacity20,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryOpacity20,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryOpacity10,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
