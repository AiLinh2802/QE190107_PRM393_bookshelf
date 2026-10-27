import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_service.dart';

/// Status count model for summary breakdown
class StatusCount {
  final String status;
  final int count;
  const StatusCount(this.status, this.count);
}

/// BookSummary model representing aggregated statistics of currently displayed books
class BookSummary {
  final int totalBooks;
  final int totalFavorites;
  final List<StatusCount> statusBreakdown;

  const BookSummary({
    required this.totalBooks,
    required this.totalFavorites,
    required this.statusBreakdown,
  });
}

/// BookProvider manages the real-time list of books for the authenticated user,
/// along with instant client-side filtering, searching, and summary computations.
class BookProvider extends ChangeNotifier {
  final BookService _bookService;

  BookProvider({BookService? bookService})
      : _bookService = bookService ?? BookService();

  List<Book> _books = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  StreamSubscription<List<Book>>? _subscription;

  // Filter States
  String _selectedGenre = 'All';
  String _selectedStatus = 'All';
  bool _favoritesOnly = false;
  String _searchQuery = '';

  List<Book> get books => List.unmodifiable(_books);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  String get selectedGenre => _selectedGenre;
  String get selectedStatus => _selectedStatus;
  bool get favoritesOnly => _favoritesOnly;
  String get searchQuery => _searchQuery;

  /// Filtered books calculated in memory across 4 combined AND conditions:
  /// 1. Genre filter (All or specific genre)
  /// 2. Status filter (All or specific status)
  /// 3. Favorites only (toggle)
  /// 4. Search query (title OR author contains query, case-insensitive, trimmed)
  List<Book> get filteredBooks {
    final trimmedQuery = _searchQuery.trim().toLowerCase();

    return _books.where((book) {
      // 1. Genre
      if (_selectedGenre != 'All' && book.genre != _selectedGenre) {
        return false;
      }

      // 2. Status
      if (_selectedStatus != 'All' && book.status != _selectedStatus) {
        return false;
      }

      // 3. Favorites only
      if (_favoritesOnly && !book.favorite) {
        return false;
      }

      // 4. Search box (title OR author contains trimmedQuery, case-insensitive)
      if (trimmedQuery.isNotEmpty) {
        final titleMatches = book.title.toLowerCase().contains(trimmedQuery);
        final authorMatches = book.author.toLowerCase().contains(trimmedQuery);
        if (!titleMatches && !authorMatches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Summary of currently DISPLAYED (filtered) books:
  /// - Total books: Books: N
  /// - Total favorites: Favorites: N
  /// - Breakdown of statuses with count > 0, ordered by count descending;
  ///   ties broken by: To Read, Reading, Finished.
  BookSummary get summary {
    final currentList = filteredBooks;
    final total = currentList.length;
    final favorites = currentList.where((b) => b.favorite).length;

    final Map<String, int> counts = {
      BookStatus.toRead: 0,
      BookStatus.reading: 0,
      BookStatus.finished: 0,
    };

    for (final book in currentList) {
      counts[book.status] = (counts[book.status] ?? 0) + 1;
    }

    // Tie-break priority order: To Read, Reading, Finished
    const tieBreakOrder = {
      BookStatus.toRead: 1,
      BookStatus.reading: 2,
      BookStatus.finished: 3,
    };

    // Filter out statuses with 0 books
    final breakdown = counts.entries
        .where((e) => e.value > 0)
        .map((e) => StatusCount(e.key, e.value))
        .toList();

    // Sort: highest count first; tie-break: To Read, Reading, Finished
    breakdown.sort((a, b) {
      if (b.count != a.count) {
        return b.count.compareTo(a.count);
      }
      final orderA = tieBreakOrder[a.status] ?? 99;
      final orderB = tieBreakOrder[b.status] ?? 99;
      return orderA.compareTo(orderB);
    });

    return BookSummary(
      totalBooks: total,
      totalFavorites: favorites,
      statusBreakdown: breakdown,
    );
  }

  /// Update genre filter (immediate update, no Apply button needed)
  void setGenreFilter(String genre) {
    if (_selectedGenre != genre) {
      _selectedGenre = genre;
      notifyListeners();
    }
  }

  /// Update status filter (immediate update)
  void setStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  /// Toggle or set favorites only filter (immediate update)
  void setFavoritesOnly(bool value) {
    if (_favoritesOnly != value) {
      _favoritesOnly = value;
      notifyListeners();
    }
  }

  /// Update search query (immediate update)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Reset all 4 filters (Genre to 'All', Status to 'All', favorites to false, query to empty)
  void clearFilters() {
    _selectedGenre = 'All';
    _selectedStatus = 'All';
    _favoritesOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  /// Initialize and listen for books of the given user.
  void initUser(String? userId) {
    if (userId == null) {
      reset();
      return;
    }

    if (userId == _currentUserId && _subscription != null) {
      return;
    }

    _subscription?.cancel();
    _currentUserId = userId;
    _books = [];
    _isLoading = true;
    _errorMessage = null;
    clearFilters();
    notifyListeners();

    _subscription = _bookService.streamBooks(userId).listen(
      (newBooks) {
        newBooks.sort((a, b) {
          final titleCompare =
              a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (titleCompare != 0) return titleCompare;
          return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        });

        _books = newBooks;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Reset provider state on logout
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _books = [];
    _isLoading = false;
    _errorMessage = null;
    clearFilters();
    notifyListeners();
  }

  /// Add book
  Future<void> addBook(Book book) async {
    await _bookService.addBook(book);
  }

  /// Toggle favorite
  Future<void> toggleFavorite(Book book) async {
    final newFavorite = !book.favorite;
    await _bookService.setFavorite(book.id, newFavorite);
  }

  /// Update book
  Future<void> updateBook(Book oldBook, Book newBook) async {
    await _bookService.updateBook(oldBook, newBook);
  }

  /// Delete book
  Future<void> deleteBook(String bookId) async {
    await _bookService.deleteBook(bookId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
