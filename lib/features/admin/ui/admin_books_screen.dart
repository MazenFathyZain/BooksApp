import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../home/data/models/books_response.dart';
import '../../home/ui/widgets/book_cover_image.dart';
import '../data/admin_repo.dart';
import 'admin_widgets.dart';

/// Every book in one searchable list. Tapping one opens its details page, which
/// already has the admin edit and delete actions.
class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final AdminRepo _repo = getIt<AdminRepo>();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<BooksResponse> _books = const [];
  String _search = '';
  int _page = 1;
  int _total = 0;
  bool _hasNextPage = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    try {
      final result = await _repo.getBooks(search: _search);
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _books = result.books;
        _page = 1;
        _total = result.pagination.totalBooks;
        _hasNextPage = result.pagination.hasNextPage;
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

  void _handleScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _repo.getBooks(search: _search, page: _page + 1);
      if (!mounted || requestId != _requestId) {
        return;
      }
      final knownIds = _books.map((book) => book.id).toSet();
      setState(() {
        _books = [
          ..._books,
          ...result.books.where((book) => !knownIds.contains(book.id)),
        ];
        _page += 1;
        _hasNextPage = result.pagination.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _addBook() async {
    final didAdd = await Navigator.pushNamed(
      context,
      Routes.dashboardScreen,
      arguments: true,
    );
    if (didAdd == true && mounted) {
      showAdminMessage(context, context.tr('book_added_successfully'));
      _load();
    }
  }

  Future<void> _openBook(BooksResponse book) async {
    final id = book.id;
    if (id == null || id.isEmpty) {
      return;
    }
    final didChange = await Navigator.pushNamed(
      context,
      Routes.bookDetailsScreen,
      arguments: {'id': id, 'isSaved': false},
    );
    if (didChange == true && mounted) {
      _load();
    }
  }

  Future<void> _deleteBook(BooksResponse book) async {
    final id = book.id;
    if (id == null) {
      return;
    }
    final confirmed = await confirmAdminDelete(
      context,
      title: context.tr('delete_book'),
      message:
          '${context.tr('delete_book_confirmation')}\n\n${book.title ?? ''}',
    );
    if (!confirmed) {
      return;
    }
    try {
      await _repo.deleteBook(id);
      if (!mounted) {
        return;
      }
      showAdminMessage(context, context.tr('book_deleted_successfully'));
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
        title: Text(
          _total > 0
              ? '${context.tr('manage_books')} ($_total)'
              : context.tr('manage_books'),
        ),
        bottom: AdminSearchField(
          hint: context.tr('search_books'),
          onChanged: _onSearchChanged,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBook,
        icon: const Icon(Icons.add),
        label: Text(context.tr('add_book')),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildList(),
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
    if (_books.isEmpty) {
      return AdminStateView(
        icon: Icons.menu_book_outlined,
        message: context.tr('no_books_found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
      itemCount: _books.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _books.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final book = _books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _openBook(book),
            contentPadding: const EdgeInsetsDirectional.only(
              start: 12,
              end: 4,
              top: 4,
              bottom: 4,
            ),
            leading: SizedBox(
              width: 40,
              height: 58,
              child: BookCoverImage(
                imageUrl: book.imageUrl,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            title: Text(
              book.title ?? context.tr('no_title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              book.author ?? context.tr('unknown'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: context.tr('delete_book'),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteBook(book),
            ),
          ),
        );
      },
    );
  }
}
