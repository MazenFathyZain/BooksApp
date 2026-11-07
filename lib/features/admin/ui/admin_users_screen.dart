import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/theming/app_colors.dart';
import '../../chat/ui/chat_formatting.dart';
import '../data/admin_models.dart';
import '../data/admin_repo.dart';
import 'admin_widgets.dart';

/// Search, filter, edit and delete accounts. Making someone an admin happens
/// here (or on the website), never during sign-up.
class AdminUsersScreen extends StatefulWidget {
  final String initialRole;

  const AdminUsersScreen({super.key, this.initialRole = ''});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminRepo _repo = getIt<AdminRepo>();
  Timer? _searchDebounce;
  List<AdminUser> _users = const [];
  String _search = '';
  late String _role = widget.initialRole;
  bool _isLoading = true;
  bool _hasError = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    try {
      final users = await _repo.getUsers(search: _search, role: _role);
      // A newer search or filter has started; ignore this older answer.
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _users = users;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _selectRole(String role) {
    setState(() {
      _role = role;
      _isLoading = true;
    });
    _load();
  }

  Future<void> _editUser(AdminUser user) async {
    final saved = await showModalBottomSheet<AdminUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditUserSheet(user: user, repo: _repo),
    );
    if (saved != null && mounted) {
      showAdminMessage(context, context.tr('user_updated'));
      _load();
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await confirmAdminDelete(
      context,
      title: context.tr('delete_user'),
      message: '${context.tr('delete_user_confirmation')}\n\n${user.email}',
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await _repo.deleteUser(user.id);
      if (!mounted) {
        return;
      }
      showAdminMessage(context, context.tr('user_deleted'));
      _load();
    } catch (error) {
      if (mounted) {
        showAdminError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_users')),
        bottom: AdminSearchField(
          hint: context.tr('search_users'),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                _RoleChip(
                  label: context.tr('all'),
                  selected: _role.isEmpty,
                  onTap: () => _selectRole(''),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: context.tr('admin'),
                  selected: _role == 'admin',
                  onTap: () => _selectRole('admin'),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: context.tr('user'),
                  selected: _role == 'user',
                  onTap: () => _selectRole('user'),
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
    if (_users.isEmpty) {
      return AdminStateView(
        icon: Icons.person_search_outlined,
        message: context.tr('no_users_found'),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelf = user.id == currentUserId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _editUser(user),
            contentPadding: const EdgeInsetsDirectional.only(start: 14, end: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                chatInitial(user.name),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    isSelf ? '${user.name} (${context.tr('you')})' : user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                AdminRoleBadge(isAdmin: user.isAdmin),
              ],
            ),
            subtitle: Text(
              user.createdAt == null
                  ? user.email
                  : '${user.email}\n${context.tr('joined')}: ${chatDayLabel(context, user.createdAt!.toLocal())}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: user.createdAt != null,
            trailing:
                isSelf
                    ? null
                    : IconButton(
                      tooltip: context.tr('delete_user'),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () => _deleteUser(user),
                    ),
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _EditUserSheet extends StatefulWidget {
  final AdminUser user;
  final AdminRepo repo;

  const _EditUserSheet({required this.user, required this.repo});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  final _passwordController = TextEditingController();
  late String _role = widget.user.isAdmin ? 'admin' : 'user';
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isSelf => widget.user.id == currentUserId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final saved = await widget.repo.updateUser(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pop(context, saved);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        showAdminError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('edit_user'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: context.tr('full_name')),
                validator:
                    (value) =>
                        (value ?? '').trim().isEmpty
                            ? context.tr('name_required')
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: context.tr('email')),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) {
                    return context.tr('email_required');
                  }
                  return email.contains('@')
                      ? null
                      : context.tr('invalid_email');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: context.tr('account_type'),
                  helperText:
                      _isSelf ? context.tr('cant_change_own_role') : null,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'user',
                    child: Text(context.tr('user')),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text(context.tr('admin')),
                  ),
                ],
                onChanged:
                    _isSelf
                        ? null
                        : (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const <String>[],
                decoration: InputDecoration(
                  labelText: context.tr('password_optional'),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  return password.isNotEmpty && password.length < 6
                      ? context.tr('password_min_length')
                      : null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.white,
                          ),
                        )
                        : Text(context.tr('save_changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
