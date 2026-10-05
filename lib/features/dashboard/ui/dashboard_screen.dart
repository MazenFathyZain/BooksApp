import 'dart:io';
import 'package:book/core/di/dependency_injection.dart';
import 'package:book/core/helpers/book_language.dart';
import 'package:book/core/helpers/extension.dart';
import 'package:book/core/helpers/session_helper.dart';
import 'package:book/core/routing/routes.dart';
import 'package:book/features/dashboard/logic/dashboard_cubit.dart';
import 'package:book/features/home/data/models/category_tree_response.dart';
import 'package:book/features/home/data/repos/home_repo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theming/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final bool returnToHomeAfterSave;

  const DashboardScreen({super.key, this.returnToHomeAfterSave = false});

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
  List<CategoryTreeResponse> _availableCategories = [];
  CategoryTreeResponse? _selectedCategory;
  CategoryTreeResponse? _selectedSubCategory;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _languageController.text = bookLanguageApiValueFromCode(
      context.currentLanguage,
    );
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await getIt<HomeRepo>().getCategoryTree(
        language: _languageController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        final available =
            categories.where((category) => category.name.isNotEmpty).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        _availableCategories = available;
        if (_selectedCategory != null &&
            _findCategoryById(available, _selectedCategory!.id) == null) {
          _selectedCategory = null;
          _selectedSubCategory = null;
          _categoryController.clear();
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _availableCategories = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  CategoryTreeResponse? _findCategoryById(
    List<CategoryTreeResponse> categories,
    String? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
      final child = _findCategoryById(category.children, id);
      if (child != null) {
        return child;
      }
    }
    return null;
  }

  CategoryTreeResponse? _findParentOfCategory(
    List<CategoryTreeResponse> categories,
    String childId,
  ) {
    for (final category in categories) {
      if (category.children.any((child) => child.id == childId)) {
        return category;
      }
      final parent = _findParentOfCategory(category.children, childId);
      if (parent != null) {
        return parent;
      }
    }
    return null;
  }

  CategoryTreeResponse? _findCategoryByName(
    List<CategoryTreeResponse> categories,
    String name,
  ) {
    for (final category in categories) {
      if (category.name == name) {
        return category;
      }
    }
    return null;
  }

  Future<void> _createCategory({CategoryTreeResponse? parent}) async {
    final controller = TextEditingController();
    final createdName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final title =
            parent == null
                ? dialogContext.tr('create_category')
                : dialogContext.tr('create_sub_category');
        void closeDialog([String? value]) {
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(value?.trim());
            }
          });
        }

        return AlertDialog(
          title: Text(title),
          content: CupertinoTextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            placeholder: dialogContext.tr('enter_category'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryOpacity20),
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            placeholderStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            onSubmitted: closeDialog,
          ),
          actions: [
            TextButton(
              onPressed: closeDialog,
              child: Text(dialogContext.tr('cancel')),
            ),
            TextButton(
              onPressed: () => closeDialog(controller.text),
              child: Text(dialogContext.tr('save')),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || createdName == null || createdName.isEmpty) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final created = await getIt<HomeRepo>().createCategory(
        name: createdName,
        parentId: parent?.id,
        language: parent == null ? _languageController.text : null,
      );
      final categories = await getIt<HomeRepo>().getCategoryTree(
        language: _languageController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _availableCategories =
            categories.where((category) => category.name.isNotEmpty).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        if (parent == null) {
          _selectedCategory =
              _findCategoryById(_availableCategories, created.id) ??
              _findCategoryByName(_availableCategories, createdName);
          _selectedSubCategory = null;
          _categoryController.text = _selectedCategory?.name ?? createdName;
        } else {
          _selectedCategory =
              _findCategoryById(_availableCategories, parent.id) ??
              _findParentOfCategory(_availableCategories, created.id);
          _selectedSubCategory =
              _findCategoryById(
                _selectedCategory?.children ?? const [],
                created.id,
              ) ??
              _findCategoryByName(
                _selectedCategory?.children ?? const [],
                createdName,
              );
          _categoryController.text = _selectedCategory?.name ?? parent.name;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('category_created')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(
    CategoryTreeResponse category, {
    required bool isSubCategory,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(dialogContext.tr('delete')),
            content: Text(
              isSubCategory
                  ? dialogContext.tr('delete_sub_category_confirmation')
                  : dialogContext.tr('delete_category_confirmation'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(dialogContext.tr('delete')),
              ),
            ],
          ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      if (isSubCategory) {
        await getIt<HomeRepo>().deleteSubCategory(category.id);
      } else {
        await getIt<HomeRepo>().deleteCategory(category.id);
      }

      final categories = await getIt<HomeRepo>().getCategoryTree(
        language: _languageController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _availableCategories =
            categories.where((item) => item.name.isNotEmpty).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        if (isSubCategory) {
          if (_selectedSubCategory?.id == category.id) {
            _selectedSubCategory = null;
          }
          if (_selectedCategory != null) {
            _selectedCategory = _findCategoryById(
              _availableCategories,
              _selectedCategory!.id,
            );
          }
        } else if (_selectedCategory?.id == category.id) {
          _selectedCategory = null;
          _selectedSubCategory = null;
          _categoryController.clear();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSubCategory
                  ? context.tr('sub_category_deleted')
                  : context.tr('category_deleted'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

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
      List<String> otherNames =
          _otherNamesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      // Parse translators (comma-separated)
      List<String> translators =
          _translatorsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      context.read<DashboardCubit>().addBook(
        _titleController.text.trim(),
        _authorController.text.trim(),
        _categoryController.text.trim(),
        _selectedCategory?.id ?? '',
        _selectedSubCategory?.id,
        _descriptionController.text.trim(),
        _selectedImage, // ✅ Image first
        _selectedPdf!, // ✅ Then PDF (required)
        _selectedWord, // ✅ Then Word
        null, // doc parameter (not implemented)
        _selectedAudio, // ✅ Then Audio
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
    _languageController.text = bookLanguageApiValueFromCode(
      context.currentLanguage,
    );
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
      _selectedCategory = null;
      _selectedSubCategory = null;
    });
    _formKey.currentState?.reset();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  Widget _buildCategorySelector(bool isLoading) {
    final canPickExisting = _availableCategories.isNotEmpty;
    final selectedCategory = _selectedCategory;
    final subCategories = selectedCategory?.children ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('category'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (canPickExisting)
          DropdownButtonFormField<String>(
            value: _selectedCategory?.id,
            isExpanded: true,
            decoration: _fieldDecoration(
              hint: context.tr('select_category'),
              icon: Icons.category,
            ),
            items: [
              ..._availableCategories.map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
              ),
            ],
            onChanged:
                isLoading
                    ? null
                    : (categoryId) {
                      final category = _findCategoryById(
                        _availableCategories,
                        categoryId,
                      );
                      setState(() {
                        _selectedCategory = category;
                        _selectedSubCategory = null;
                        _categoryController.text = category?.name ?? '';
                      });
                    },
            validator: (_) {
              if (_selectedCategory == null) {
                return context.tr('please_select_category');
              }
              return null;
            },
          )
        else if (_isLoadingCategories)
          LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.primaryOpacity10,
          )
        else
          _CustomTextField(
            controller: _categoryController,
            label: context.tr('category'),
            hint: context.tr('enter_category'),
            icon: Icons.edit,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('please_select_category');
              }
              return null;
            },
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed:
                  isLoading || _isLoadingCategories
                      ? null
                      : () => _createCategory(),
              icon: const Icon(Icons.add),
              label: Text(context.tr('create_category')),
            ),
            if (selectedCategory != null)
              OutlinedButton.icon(
                onPressed:
                    isLoading || _isLoadingCategories
                        ? null
                        : () => _deleteCategory(
                          selectedCategory,
                          isSubCategory: false,
                        ),
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('delete')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
          ],
        ),
        if (canPickExisting && selectedCategory != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('select_sub_category'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    isLoading || _isLoadingCategories
                        ? null
                        : () => _createCategory(parent: selectedCategory),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('create_sub_category')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSubCategoryOption(
            label: context.tr('add_to_category_only'),
            isSelected: _selectedSubCategory == null,
            isEnabled: !isLoading,
            onTap: () {
              setState(() {
                _selectedSubCategory = null;
              });
            },
          ),
          if (subCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...subCategories.map(
              (subCategory) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSubCategoryOption(
                  label: subCategory.name,
                  isSelected: _selectedSubCategory?.id == subCategory.id,
                  isEnabled: !isLoading,
                  onDelete:
                      isLoading || _isLoadingCategories
                          ? null
                          : () =>
                              _deleteCategory(subCategory, isSubCategory: true),
                  onTap: () {
                    setState(() {
                      _selectedSubCategory = subCategory;
                    });
                  },
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              context.tr('no_sub_categories_available'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSubCategoryOption({
    required String label,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Material(
      color: isSelected ? AppColors.primaryOpacity10 : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.primaryOpacity20,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: context.tr('delete'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(bool isLoading) {
    final currentValue =
        bookLanguages.any(
              (language) => language.apiValue == _languageController.text,
            )
            ? _languageController.text
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('language'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          isExpanded: true,
          decoration: _fieldDecoration(
            hint: context.tr('select_language'),
            icon: Icons.language,
          ),
          items:
              bookLanguages
                  .map(
                    (language) => DropdownMenuItem<String>(
                      value: language.apiValue,
                      child: Text(localizedBookLanguageName(context, language)),
                    ),
                  )
                  .toList(),
          onChanged:
              isLoading
                  ? null
                  : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _languageController.text = value;
                      _selectedCategory = null;
                      _selectedSubCategory = null;
                      _categoryController.clear();
                    });
                    _loadCategories();
                  },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.tr('please_enter_language');
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryOpacity20),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryOpacity20),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryOpacity10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

                    _buildCategorySelector(isLoading),
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

                    _buildLanguageDropdown(isLoading),
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
                            color:
                                _selectedImage != null
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
                                      color:
                                          _selectedImage != null
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
                            color:
                                _selectedPdf != null
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
                                      color:
                                          _selectedPdf != null
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
                            color:
                                _selectedWord != null
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
                                      color:
                                          _selectedWord != null
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
                            color:
                                _selectedAudio != null
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
                                      color:
                                          _selectedAudio != null
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
                        child:
                            isLoading
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
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryOpacity20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryOpacity20),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryOpacity10),
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
