import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/book_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/widgets.dart';

/// BookDetailScreen is the protected detail screen.
/// Features:
/// - View Mode: Displays complete title, author, genre, status, rating, notes, and favorite star.
/// - Edit Mode: Turns same fields into inputs with Save and Cancel buttons.
///   Reuses shared BookValidators. Error only appears upon Save.
///   Handles ID change via atomic transaction on title/author change.
/// - Delete: Confirmation dialog with "Cancel" and "Delete" buttons. Deletes from Firestore and returns to List.
/// - Reads real-time data from BookProvider so all changes reflect instantly.
class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late String _currentBookId;
  bool _isEditing = false;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  String? _formErrorMessage;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _ratingController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedGenre;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _currentBookId = widget.book.id;
    _populateFields(widget.book);
  }

  void _populateFields(Book book) {
    _titleController.text = book.title;
    _authorController.text = book.author;
    _ratingController.text = book.rating?.toString() ?? '';
    _notesController.text = book.notes ?? '';
    _selectedGenre = book.genre;
    _selectedStatus = book.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _enterEditMode(Book book) {
    setState(() {
      _populateFields(book);
      _isEditing = true;
      _autovalidateMode = AutovalidateMode.disabled;
      _formErrorMessage = null;
    });
  }

  void _cancelEditMode(Book book) {
    FocusScope.of(context).unfocus();
    setState(() {
      _populateFields(book);
      _isEditing = false;
      _formErrorMessage = null;
      _autovalidateMode = AutovalidateMode.disabled;
    });
  }

  Future<void> _handleSave(Book currentBook) async {
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
      _isSaving = true;
    });

    final bookProvider = context.read<BookProvider>();

    try {
      final ratingValue = _ratingController.text.trim().isNotEmpty
          ? int.parse(_ratingController.text.trim())
          : null;

      final updatedBook = currentBook.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre,
        status: _selectedStatus,
        rating: ratingValue,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Perform update (if title or author changed, atomic transaction creates new doc + deletes old doc)
      await bookProvider.updateBook(currentBook, updatedBook);

      if (!mounted) return;

      // Update current book ID tracking if title/author changed
      final newId = Book.generateId(updatedBook.userId, updatedBook.title, updatedBook.author);

      setState(() {
        _currentBookId = newId;
        _isEditing = false;
        _autovalidateMode = AutovalidateMode.disabled;
        _formErrorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book updated', style: TextStyle(fontWeight: FontWeight.bold)),
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
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete(Book currentBook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${currentBook.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final bookProvider = context.read<BookProvider>();
      await bookProvider.deleteBook(currentBook.id);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookProvider = context.watch<BookProvider>();

    // Read real-time book from provider by current ID, falling back to initial widget
    final currentBook = bookProvider.books.firstWhere(
      (b) => b.id == _currentBookId,
      orElse: () => widget.book,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Book' : currentBook.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Favorite Star Button (Active in both modes)
          IconButton(
            icon: Icon(
              currentBook.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: currentBook.favorite ? Colors.amber : Colors.grey,
              size: 28,
            ),
            tooltip: currentBook.favorite ? 'Marked as Favorite' : 'Mark as Favorite',
            onPressed: () {
              bookProvider.toggleFavorite(currentBook);
            },
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () => _enterEditMode(currentBook),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _isEditing ? _buildEditMode(currentBook) : _buildViewMode(currentBook, theme),
        ),
      ),
    );
  }

  /// 1. VIEW MODE
  Widget _buildViewMode(Book book, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Book Header Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${book.author}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildBadge(book.genre, const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                        _buildBadge(book.status, const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Rating Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.rating != null ? '${book.rating} / 5' : 'Not rated yet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Notes Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notes_rounded, color: AppTheme.primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                book.notes?.isNotEmpty == true
                    ? book.notes!
                    : 'No notes added for this book.',
                style: TextStyle(
                  fontSize: 14,
                  color: book.notes?.isNotEmpty == true
                      ? AppTheme.textPrimaryColor
                      : AppTheme.textSecondaryColor,
                  fontStyle: book.notes?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Action Buttons: Edit & Delete
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Edit',
                icon: Icons.edit_rounded,
                onPressed: () => _enterEditMode(book),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppButton(
                text: 'Delete',
                isOutlined: true,
                backgroundColor: AppTheme.errorColor,
                textColor: AppTheme.errorColor,
                icon: Icons.delete_outline_rounded,
                onPressed: () => _handleDelete(book),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. EDIT MODE
  Widget _buildEditMode(Book book) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Input
          AppTextField(
            controller: _titleController,
            label: 'Title *',
            hint: 'Enter book title',
            textInputAction: TextInputAction.next,
            validator: BookValidators.validateTitle,
            onChanged: (_) {
              if (_formErrorMessage != null) {
                setState(() => _formErrorMessage = null);
              }
            },
          ),
          const SizedBox(height: 14),

          // Author Input
          AppTextField(
            controller: _authorController,
            label: 'Author *',
            hint: 'Enter author name',
            textInputAction: TextInputAction.next,
            validator: BookValidators.validateAuthor,
            onChanged: (_) {
              if (_formErrorMessage != null) {
                setState(() => _formErrorMessage = null);
              }
            },
          ),
          const SizedBox(height: 14),

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
            initialValue: _selectedGenre,
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
            validator: BookValidators.validateGenre,
          ),
          const SizedBox(height: 14),

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
            initialValue: _selectedStatus,
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
            validator: BookValidators.validateStatus,
          ),
          const SizedBox(height: 14),

          // Rating Input
          AppTextField(
            controller: _ratingController,
            label: 'Rating (0 - 5, optional)',
            hint: 'Enter rating number (e.g. 5)',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.star_border_rounded),
            validator: BookValidators.validateRating,
            onChanged: (_) {
              if (_formErrorMessage != null) {
                setState(() => _formErrorMessage = null);
              }
            },
          ),
          const SizedBox(height: 14),

          // Notes Input
          AppTextField(
            controller: _notesController,
            label: 'Notes (optional)',
            hint: 'Personal thoughts or summary',
            maxLines: 3,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.edit_note_rounded),
            validator: BookValidators.validateNotes,
            onChanged: (_) {
              if (_formErrorMessage != null) {
                setState(() => _formErrorMessage = null);
              }
            },
          ),
          const SizedBox(height: 18),

          // Firestore error message displayed directly on form
          if (_formErrorMessage != null) ...[
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
            const SizedBox(height: 18),
          ],

          // Save and Cancel Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Save',
                  isLoading: _isSaving,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _handleSave(book),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  isOutlined: true,
                  icon: Icons.cancel_outlined,
                  onPressed: _isSaving ? null : () => _cancelEditMode(book),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
