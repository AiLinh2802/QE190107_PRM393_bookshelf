import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/book_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/widgets.dart';
import 'book_detail_screen.dart';

/// BookListScreen is the protected main dashboard.
/// Features:
/// - Header with user email and Logout
/// - Add Book collapsible form with strict validation
/// - Search & Filter controls (Genre, Status, Favorites only, Search query, and Clear button)
/// - Real-time Summary Card (Books: N, Favorites: N, status breakdown)
/// - Real-time filtered books list or "No books found" empty state
class BookListScreen extends StatefulWidget {
  final User user;

  const BookListScreen({
    super.key,
    required this.user,
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _ratingController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedGenre = '';
  String? _selectedStatus = '';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isSubmitting = false;
  String? _formErrorMessage;
  bool _isFormExpanded = true;

  @override
  void initState() {
    super.initState();
    // Initialize stream for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookProvider>().initUser(widget.user.uid);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) => BookValidators.validateTitle(value);
  String? _validateAuthor(String? value) => BookValidators.validateAuthor(value);
  String? _validateRating(String? value) => BookValidators.validateRating(value);
  String? _validateNotes(String? value) => BookValidators.validateNotes(value);

  Future<void> _handleSubmitBook() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _formErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ratingValue = _ratingController.text.trim().isNotEmpty
          ? int.parse(_ratingController.text.trim())
          : null;

      final newBook = Book.create(
        userId: widget.user.uid,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre!,
        status: _selectedStatus!,
        rating: ratingValue,
        favorite: false,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final bookProvider = context.read<BookProvider>();
      await bookProvider.addBook(newBook);

      if (!mounted) return;

      // Clean form fields and reset dropdowns
      _titleController.clear();
      _authorController.clear();
      _ratingController.clear();
      _notesController.clear();
      _formKey.currentState?.reset();

      setState(() {
        _selectedGenre = '';
        _selectedStatus = '';
        _autovalidateMode = AutovalidateMode.disabled;
        _formErrorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Book added', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formErrorMessage = e.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final authService = context.read<AuthService>();
    final bookProvider = context.read<BookProvider>();

    _searchController.clear();
    bookProvider.reset();
    await authService.signOut();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = widget.user.email ?? 'User';
    final bookProvider = context.watch<BookProvider>();
    final filteredBooks = bookProvider.filteredBooks;
    final summary = bookProvider.summary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'My BookShelf',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.errorColor),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 1. Add Book Form Section (Collapsible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autovalidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Book',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _isFormExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                tooltip: _isFormExpanded ? 'Collapse form' : 'Expand form',
                                onPressed: () {
                                  setState(() {
                                    _isFormExpanded = !_isFormExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isFormExpanded) ...[
                            const SizedBox(height: 12),

                            // Title Field
                            AppTextField(
                              controller: _titleController,
                              label: 'Title *',
                              hint: 'Enter book title',
                              textInputAction: TextInputAction.next,
                              validator: _validateTitle,
                              onChanged: (_) {
                                if (_formErrorMessage != null) {
                                  setState(() => _formErrorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Author Field
                            AppTextField(
                              controller: _authorController,
                              label: 'Author *',
                              hint: 'Enter author name',
                              textInputAction: TextInputAction.next,
                              validator: _validateAuthor,
                              onChanged: (_) {
                                if (_formErrorMessage != null) {
                                  setState(() => _formErrorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Genre Dropdown
                            const Text(
                              'Genre *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: '',
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Choose genre', style: TextStyle(color: Colors.grey)),
                                ),
                                DropdownMenuItem<String>(value: 'Fiction', child: Text('Fiction')),
                                DropdownMenuItem<String>(value: 'Non-Fiction', child: Text('Non-Fiction')),
                                DropdownMenuItem<String>(value: 'Academic', child: Text('Academic')),
                                DropdownMenuItem<String>(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedGenre = val;
                                  if (_formErrorMessage != null) {
                                    _formErrorMessage = null;
                                  }
                                });
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please choose a genre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Status Dropdown
                            const Text(
                              'Status *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: '',
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.bookmark_border_rounded),
                              ),
                              items: const [
                                DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Choose status', style: TextStyle(color: Colors.grey)),
                                ),
                                DropdownMenuItem<String>(value: 'To Read', child: Text('To Read')),
                                DropdownMenuItem<String>(value: 'Reading', child: Text('Reading')),
                                DropdownMenuItem<String>(value: 'Finished', child: Text('Finished')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedStatus = val;
                                  if (_formErrorMessage != null) {
                                    _formErrorMessage = null;
                                  }
                                });
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please choose a status';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Rating Field (Optional)
                            AppTextField(
                              controller: _ratingController,
                              label: 'Rating (0 - 5, optional)',
                              hint: 'Enter rating number (e.g. 5)',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.star_border_rounded),
                              validator: _validateRating,
                              onChanged: (_) {
                                if (_formErrorMessage != null) {
                                  setState(() => _formErrorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Notes Field (Optional)
                            AppTextField(
                              controller: _notesController,
                              label: 'Notes (optional)',
                              hint: 'Personal thoughts or summary',
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              validator: _validateNotes,
                              onChanged: (_) {
                                if (_formErrorMessage != null) {
                                  setState(() => _formErrorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Submit Button
                            AppButton(
                              text: 'Save Book',
                              isLoading: _isSubmitting,
                              icon: Icons.bookmark_add_rounded,
                              onPressed: _handleSubmitBook,
                            ),

                            // Firestore error message displayed directly on form
                            if (_formErrorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _formErrorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Search & Filters Section (Instant update, no Apply button)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Box (title or author, case-insensitive, trimmed)
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by title or author...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      bookProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {}); // refresh suffix icon
                            bookProvider.setSearchQuery(val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Genre Filter Chips (Wrap ensures narrow screens don't overflow)
                        const Text(
                          'Filter by Genre:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            'All',
                            'Fiction',
                            'Non-Fiction',
                            'Academic',
                            'Other',
                          ].map((genre) {
                            final isSelected = bookProvider.selectedGenre == genre;
                            return ChoiceChip(
                              label: Text(genre),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                bookProvider.setGenreFilter(genre);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Status Filter Chips (Wrap)
                        const Text(
                          'Filter by Status:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            'All',
                            'To Read',
                            'Reading',
                            'Finished',
                          ].map((status) {
                            final isSelected = bookProvider.selectedStatus == status;
                            return ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.secondaryColor : AppTheme.textPrimaryColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                bookProvider.setStatusFilter(status);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Bottom Row: Favorites only switch + Clear Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                const Text(
                                  'Favorites only',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: bookProvider.favoritesOnly,
                                  activeThumbColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    bookProvider.setFavoritesOnly(val);
                                  },
                                ),
                              ],
                            ),

                            // Clear Button (Resets all 4 filters and clears search box)
                            TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                bookProvider.clearFilters();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Summary Card (Reflects currently DISPLAYED / filtered books)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: AppCard(
                    color: const Color(0xFFF1F5F9),
                    border: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const Spacer(),
                            // Books: N and Favorites: N
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'Books: ${summary.totalBooks}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'Favorites: ${summary.totalFavorites}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Breakdown lines: each non-zero status on a separate line
                        if (summary.statusBreakdown.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 8),
                          ...summary.statusBreakdown.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getStatusDotColor(item.status),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.status,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${item.count}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Section Header: Filtered Books List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Books',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Showing ${filteredBooks.length} of ${bookProvider.books.length}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading State
              if (bookProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              // Empty State (Strictly displays "No books found")
              else if (filteredBooks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No books found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search or filters.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Filtered Books List
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = filteredBooks[index];
                        return _buildBookItem(context, book);
                      },
                      childCount: filteredBooks.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusDotColor(String status) {
    switch (status) {
      case 'To Read':
        return Colors.orange;
      case 'Reading':
        return Colors.blue;
      case 'Finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    final bookProvider = context.read<BookProvider>();

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Book Thumbnail
          Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Title, Author, Genre & Status Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTag(book.genre, const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                    _buildTag(book.status, const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
                    if (book.rating != null)
                      _buildTag('${book.rating} ★', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
          ),

          // Favorite Star Button (Bright amber when favorite)
          IconButton(
            icon: Icon(
              book.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: book.favorite ? Colors.amber : Colors.grey.shade400,
              size: 28,
            ),
            tooltip: book.favorite ? 'Marked as Favorite' : 'Mark as Favorite',
            onPressed: () {
              bookProvider.toggleFavorite(book);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
