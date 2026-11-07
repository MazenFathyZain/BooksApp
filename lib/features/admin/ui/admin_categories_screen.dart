import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/book_language.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/theming/app_colors.dart';
import '../../home/data/models/category_tree_response.dart';
import '../data/admin_repo.dart';
import 'admin_widgets.dart';

/// Add, rename and delete main categories and subcategories.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final AdminRepo _repo = getIt<AdminRepo>();
  List<CategoryTreeResponse> _categories = const [];
  BookLanguage _language = bookLanguages.first;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final categories = await _repo.getCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// The website stores a language as its code ("tg") and the app as its name
  /// ("Tajik"), so both count as the same language here.
  bool _isInSelectedLanguage(CategoryTreeResponse category) {
    final language = (category.language ?? '').trim().toLowerCase();
    return language == _language.code ||
        language == _language.apiValue.toLowerCase();
  }

  Future<String?> _askForName({
    required String title,
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      builder:
          (_) => _CategoryNameDialog(title: title, initialValue: initialValue),
    );
  }

  /// Runs a change, shows the outcome and reloads the list.
  Future<void> _apply(Future<void> Function() change, String doneKey) async {
    try {
      await change();
      if (!mounted) {
        return;
      }
      showAdminMessage(context, context.tr(doneKey));
      await _load();
    } catch (error) {
      if (mounted) {
        showAdminError(context, error);
      }
    }
  }

  Future<void> _addMain() async {
    final name = await _askForName(title: context.tr('create_category'));
    if (name == null) {
      return;
    }
    await _apply(
      () => _repo.createCategory(name: name, language: _language.apiValue),
      'category_created',
    );
  }

  Future<void> _addSub(CategoryTreeResponse parent) async {
    final name = await _askForName(title: context.tr('create_sub_category'));
    if (name == null) {
      return;
    }
    await _apply(
      () => _repo.createCategory(name: name, parentId: parent.id),
      'category_created',
    );
  }

  Future<void> _rename(CategoryTreeResponse category) async {
    final name = await _askForName(
      title: context.tr('edit_category'),
      initialValue: category.name,
    );
    if (name == null || name == category.name) {
      return;
    }
    await _apply(
      () => _repo.renameCategory(id: category.id, name: name),
      'category_updated',
    );
  }

  Future<void> _delete(CategoryTreeResponse category) async {
    final isSubCategory = (category.parentId ?? '').isNotEmpty;
    final confirmed = await confirmAdminDelete(
      context,
      title: context.tr('delete'),
      message:
          '${context.tr(isSubCategory ? 'delete_sub_category_confirmation' : 'delete_category_confirmation')}\n\n${category.name}',
    );
    if (!confirmed) {
      return;
    }
    await _apply(
      () => _repo.deleteCategory(category),
      isSubCategory ? 'sub_category_deleted' : 'category_deleted',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('manage_categories'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMain,
        icon: const Icon(Icons.add),
        label: Text(context.tr('create_category')),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              children: [
                for (final language in bookLanguages)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(localizedBookLanguageName(context, language)),
                      selected: language.code == _language.code,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            language.code == _language.code
                                ? AppColors.white
                                : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _language = language),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_hasError) {
      return AdminStateView(
        icon: Icons.cloud_off,
        message: context.tr('error_occurred'),
        onRetry: _load,
      );
    }

    final categories = _categories.where(_isInSelectedLanguage).toList();
    if (categories.isEmpty) {
      return AdminStateView(
        icon: Icons.account_tree_outlined,
        message: context.tr('no_categories_found'),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: PageStorageKey(category.id),
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(
              Icons.folder_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${context.tr('subcategories_count')}: ${category.children.length}',
            ),
            trailing: _CategoryMenu(
              onAddSub: () => _addSub(category),
              onRename: () => _rename(category),
              onDelete: () => _delete(category),
            ),
            children: [
              for (final child in category.children)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 32,
                    end: 4,
                  ),
                  leading: const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  title: Text(child.name),
                  trailing: _CategoryMenu(
                    onRename: () => _rename(_withParent(child, category.id)),
                    onDelete: () => _delete(_withParent(child, category.id)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Tree children may omit their parent; deleting needs to know they have one.
  CategoryTreeResponse _withParent(
    CategoryTreeResponse child,
    String parentId,
  ) {
    return CategoryTreeResponse(
      id: child.id,
      name: child.name,
      language: child.language,
      parentId: parentId,
    );
  }
}

class _CategoryMenu extends StatelessWidget {
  final VoidCallback? onAddSub;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _CategoryMenu({
    this.onAddSub,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onSelected: (action) => action(),
      itemBuilder:
          (context) => [
            if (onAddSub != null)
              PopupMenuItem(
                value: onAddSub,
                child: Text(context.tr('create_sub_category')),
              ),
            PopupMenuItem(
              value: onRename,
              child: Text(context.tr('edit_category')),
            ),
            PopupMenuItem(
              value: onDelete,
              child: Text(
                context.tr('delete'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _CategoryNameDialog({required this.title, required this.initialValue});

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: context.tr('category_name')),
          validator:
              (value) =>
                  (value ?? '').trim().isEmpty
                      ? context.tr('category_name_required')
                      : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(context.tr('save'))),
      ],
    );
  }
}
