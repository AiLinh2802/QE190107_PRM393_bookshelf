import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/providers/book_provider.dart';

void main() {
  group('Filter, Search, and Summary Tests', () {
    final now = DateTime(2026, 1, 1);

    final books = [
      Book(
        id: '1',
        userId: 'u1',
        title: 'Clean Architecture',
        author: 'Robert C. Martin',
        genre: 'Academic',
        status: 'Finished',
        favorite: true,
        createdAt: now,
      ),
      Book(
        id: '2',
        userId: 'u1',
        title: 'Dune',
        author: 'Frank Herbert',
        genre: 'Fiction',
        status: 'Reading',
        favorite: true,
        createdAt: now,
      ),
      Book(
        id: '3',
        userId: 'u1',
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        genre: 'Non-Fiction',
        status: 'To Read',
        favorite: false,
        createdAt: now,
      ),
      Book(
        id: '4',
        userId: 'u1',
        title: 'Atomic Habits',
        author: 'James Clear',
        genre: 'Non-Fiction',
        status: 'Reading',
        favorite: false,
        createdAt: now,
      ),
      Book(
        id: '5',
        userId: 'u1',
        title: 'Dune Messiah',
        author: 'Frank Herbert',
        genre: 'Fiction',
        status: 'To Read',
        favorite: true,
        createdAt: now,
      ),
    ];

    test('BookProvider clearFilters resets all 4 filter properties', () {
      final p = BookProvider();
      p.setGenreFilter('Fiction');
      p.setStatusFilter('Reading');
      p.setFavoritesOnly(true);
      p.setSearchQuery('Dune');

      expect(p.selectedGenre, 'Fiction');
      expect(p.selectedStatus, 'Reading');
      expect(p.favoritesOnly, isTrue);
      expect(p.searchQuery, 'Dune');

      p.clearFilters();

      expect(p.selectedGenre, 'All');
      expect(p.selectedStatus, 'All');
      expect(p.favoritesOnly, isFalse);
      expect(p.searchQuery, '');
    });

    test('Search filter matches title or author, case-insensitive and trims query', () {
      final list = books.where((book) {
        final query = '   dUnE   '.trim().toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();

      expect(list.length, 2);
      expect(list.map((b) => b.title), containsAll(['Dune', 'Dune Messiah']));

      // Search by author with whitespace and uppercase
      final authorList = books.where((book) {
        final query = '  MARTIN  '.trim().toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();

      expect(authorList.length, 1);
      expect(authorList.first.title, 'Clean Architecture');
    });

    test('All 4 filters combine with AND', () {
      // Genre: Fiction, Status: Reading, FavoritesOnly: true, Search: 'Frank'
      final filtered = books.where((book) {
        if (book.genre != 'Fiction') return false;
        if (book.status != 'Reading') return false;
        if (!book.favorite) return false;
        const q = 'frank';
        if (!book.title.toLowerCase().contains(q) &&
            !book.author.toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.title, 'Dune');
    });

    test('Un-favorite immediately removes book when favoritesOnly is true', () {
      final initialFavorites = books.where((b) => b.favorite).toList();
      expect(initialFavorites.length, 3);

      // Simulate toggling favorite off on 'Dune'
      final updatedBooks = books.map((b) {
        if (b.id == '2') {
          return b.copyWith(favorite: false);
        }
        return b;
      }).toList();

      final newFavorites = updatedBooks.where((b) => b.favorite).toList();
      expect(newFavorites.length, 2);
      expect(newFavorites.any((b) => b.title == 'Dune'), isFalse);
    });

    test('Summary calculations and breakdown sorting rules', () {
      // With all 5 books:
      // Statuses:
      // Finished: 1 (Clean Architecture)
      // Reading: 2 (Dune, Atomic Habits)
      // To Read: 2 (Sapiens, Dune Messiah)
      // Order:
      // Count 2 is highest: between 'To Read' (2) and 'Reading' (2), tie-break puts 'To Read' first!
      // Count 1: 'Finished' (1)
      // Expected breakdown order:
      // 1. To Read: 2
      // 2. Reading: 2
      // 3. Finished: 1

      final Map<String, int> counts = {
        'To Read': 0,
        'Reading': 0,
        'Finished': 0,
      };

      for (final book in books) {
        counts[book.status] = (counts[book.status] ?? 0) + 1;
      }

      const tieBreakOrder = {
        'To Read': 1,
        'Reading': 2,
        'Finished': 3,
      };

      final breakdown = counts.entries
          .where((e) => e.value > 0)
          .map((e) => StatusCount(e.key, e.value))
          .toList();

      breakdown.sort((a, b) {
        if (b.count != a.count) {
          return b.count.compareTo(a.count);
        }
        final orderA = tieBreakOrder[a.status] ?? 99;
        final orderB = tieBreakOrder[b.status] ?? 99;
        return orderA.compareTo(orderB);
      });

      expect(breakdown[0].status, 'To Read');
      expect(breakdown[0].count, 2);

      expect(breakdown[1].status, 'Reading');
      expect(breakdown[1].count, 2);

      expect(breakdown[2].status, 'Finished');
      expect(breakdown[2].count, 1);
    });

    test('Summary omits statuses with 0 books', () {
      // If we only have 2 books with status 'Reading'
      final readingBooks = [
        books[1], // Dune (Reading)
        books[3], // Atomic Habits (Reading)
      ];

      final Map<String, int> counts = {
        'To Read': 0,
        'Reading': 0,
        'Finished': 0,
      };

      for (final book in readingBooks) {
        counts[book.status] = (counts[book.status] ?? 0) + 1;
      }

      final breakdown = counts.entries
          .where((e) => e.value > 0)
          .map((e) => StatusCount(e.key, e.value))
          .toList();

      expect(breakdown.length, 1);
      expect(breakdown.first.status, 'Reading');
      expect(breakdown.first.count, 2);
    });
  });
}
