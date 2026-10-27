import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookshelf/models/book.dart';

void main() {
  group('Book Model Tests', () {
    test('generateId correctly normalizes title, author and replaces slashes', () {
      final id1 = Book.generateId('user123', '  Dune  ', ' Frank Herbert ');
      expect(id1, 'user123_dune_frank herbert');

      // Case insensitive check
      final id2 = Book.generateId('user123', 'dune', 'FRANK HERBERT');
      expect(id2, id1);

      // Slash replacement check
      final idWithSlash = Book.generateId('u1', 'AC/DC Story', 'Bob/Alice');
      expect(idWithSlash, 'u1_ac_dc story_bob_alice');
    });

    test('Book.create sets all required fields and auto-computes id', () {
      final now = DateTime(2026, 1, 1, 10, 0);
      final book = Book.create(
        userId: 'user_456',
        title: 'Clean Architecture',
        author: 'Robert C. Martin',
        genre: BookGenre.academic,
        status: BookStatus.reading,
        rating: 5,
        favorite: true,
        notes: 'Great software design patterns.',
        createdAt: now,
      );

      expect(book.id, 'user_456_clean architecture_robert c. martin');
      expect(book.userId, 'user_456');
      expect(book.title, 'Clean Architecture');
      expect(book.author, 'Robert C. Martin');
      expect(book.genre, 'Academic');
      expect(book.status, 'Reading');
      expect(book.rating, 5);
      expect(book.favorite, isTrue);
      expect(book.notes, 'Great software design patterns.');
      expect(book.createdAt, now);
    });

    test('toMap and fromMap round-trip correctly', () {
      final now = DateTime(2026, 5, 20, 15, 30);
      final original = Book(
        id: 'user_1_clean code_uncle bob',
        userId: 'user_1',
        title: 'Clean Code',
        author: 'Uncle Bob',
        genre: BookGenre.academic,
        status: BookStatus.finished,
        rating: 4,
        favorite: true,
        notes: 'Readable code matters.',
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['id'], original.id);
      expect(map['userId'], original.userId);
      expect(map['title'], original.title);
      expect(map['author'], original.author);
      expect(map['genre'], original.genre);
      expect(map['status'], original.status);
      expect(map['rating'], original.rating);
      expect(map['favorite'], original.favorite);
      expect(map['notes'], original.notes);
      expect(map['createdAt'], isA<Timestamp>());

      final restored = Book.fromMap(map, original.id);
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.author, original.author);
      expect(restored.genre, original.genre);
      expect(restored.status, original.status);
      expect(restored.rating, original.rating);
      expect(restored.favorite, original.favorite);
      expect(restored.notes, original.notes);
      expect(restored.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Genre and Status constants contain all expected values', () {
      expect(BookGenre.all, containsAll(['Fiction', 'Non-Fiction', 'Academic', 'Other']));
      expect(BookGenre.isValid('Fiction'), isTrue);
      expect(BookGenre.isValid('Sci-Fi'), isFalse);

      expect(BookStatus.all, containsAll(['To Read', 'Reading', 'Finished']));
      expect(BookStatus.isValid('Finished'), isTrue);
      expect(BookStatus.isValid('Completed'), isFalse);
    });
  });
}
