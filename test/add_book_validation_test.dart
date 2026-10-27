import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/models/book.dart';

void main() {
  group('Add Book Validation & Sorting Tests', () {
    String? validateTitle(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Title is required';
      }
      if (value.length > 100) {
        return 'Title must be at most 100 characters';
      }
      return null;
    }

    String? validateAuthor(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Author is required';
      }
      if (value.length > 60) {
        return 'Author must be at most 60 characters';
      }
      return null;
    }

    String? validateGenre(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please choose a genre';
      }
      return null;
    }

    String? validateStatus(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please choose a status';
      }
      return null;
    }

    String? validateRating(String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      final n = int.tryParse(value.trim());
      if (n == null || n < 0 || n > 5) {
        return 'Rating must be a whole number from 0 to 5';
      }
      return null;
    }

    String? validateNotes(String? value) {
      if (value != null && value.length > 300) {
        return 'Notes must be at most 300 characters';
      }
      return null;
    }

    test('Title validation checks empty, spaces, and max length 100', () {
      expect(validateTitle(''), 'Title is required');
      expect(validateTitle('     '), 'Title is required');
      expect(validateTitle('A' * 101), 'Title must be at most 100 characters');
      expect(validateTitle('Dune'), isNull);
    });

    test('Author validation checks empty, spaces, and max length 60', () {
      expect(validateAuthor(''), 'Author is required');
      expect(validateAuthor('     '), 'Author is required');
      expect(validateAuthor('A' * 61), 'Author must be at most 60 characters');
      expect(validateAuthor('Frank Herbert'), isNull);
    });

    test('Genre and Status dropdown validations', () {
      expect(validateGenre(''), 'Please choose a genre');
      expect(validateGenre(null), 'Please choose a genre');
      expect(validateGenre('Fiction'), isNull);

      expect(validateStatus(''), 'Please choose a status');
      expect(validateStatus(null), 'Please choose a status');
      expect(validateStatus('To Read'), isNull);
    });

    test('Rating validation checks optional integer 0-5', () {
      expect(validateRating(''), isNull);
      expect(validateRating(null), isNull);
      expect(validateRating('   '), isNull);
      expect(validateRating('abc'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('-1'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('6'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('4.5'), 'Rating must be a whole number from 0 to 5');
      expect(validateRating('0'), isNull);
      expect(validateRating('5'), isNull);
      expect(validateRating('3'), isNull);
    });

    test('Notes validation checks max length 300', () {
      expect(validateNotes(null), isNull);
      expect(validateNotes(''), isNull);
      expect(validateNotes('Short note'), isNull);
      expect(validateNotes('N' * 301), 'Notes must be at most 300 characters');
      expect(validateNotes('N' * 300), isNull);
    });

    test('Sorting books by title case-insensitive then author case-insensitive', () {
      final now = DateTime.now();
      final books = [
        Book(id: '3', userId: 'u', title: 'dune', author: 'Brian Herbert', genre: 'Fiction', status: 'To Read', createdAt: now),
        Book(id: '1', userId: 'u', title: 'clean architecture', author: 'Robert Martin', genre: 'Academic', status: 'Reading', createdAt: now),
        Book(id: '2', userId: 'u', title: 'Dune', author: 'Alan Moore', genre: 'Fiction', status: 'Finished', createdAt: now),
        Book(id: '4', userId: 'u', title: 'Zorba the Greek', author: 'Nikos Kazantzakis', genre: 'Fiction', status: 'Finished', createdAt: now),
      ];

      books.sort((a, b) {
        final titleCompare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (titleCompare != 0) return titleCompare;
        return a.author.toLowerCase().compareTo(b.author.toLowerCase());
      });

      expect(books[0].title, 'clean architecture');
      // 'Dune' vs 'dune' have equal title, so author 'Alan Moore' comes before 'Brian Herbert'
      expect(books[1].title, 'Dune');
      expect(books[1].author, 'Alan Moore');
      expect(books[2].title, 'dune');
      expect(books[2].author, 'Brian Herbert');
      expect(books[3].title, 'Zorba the Greek');
    });
  });
}
