import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

/// BookService handles all CRUD operations and real-time streams for books in Firestore.
/// - addBook: Inserts a new book with deterministic ID.
/// - updateBook: Updates in-place if title/author are identical; otherwise performs
///   an atomic transaction (create new doc + delete old doc) to prevent duplicates and data loss.
/// - deleteBook: Deletes a book by ID.
/// - setFavorite: Toggles or sets favorite status.
/// - streamBooks: Real-time stream of user's books filtered by userId.
class BookService {
  final FirebaseFirestore? firestoreInstance;

  BookService({this.firestoreInstance});

  FirebaseFirestore get firestore =>
      firestoreInstance ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      firestore.collection('books');

  /// Stream list of books belonging to the specified user.
  /// Strictly filters by `userId` to comply with security rules.
  Stream<List<Book>> streamBooks(String userId) {
    return _booksCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs.map((doc) => Book.fromDoc(doc)).toList();
      // Sort in-memory by createdAt descending to avoid requiring composite indexes
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return books;
    });
  }

  /// Add a new book to Firestore.
  /// Uses book.id (deterministic: userId_title_author).
  /// If a duplicate exists, Firestore rules will reject with permission-denied.
  Future<void> addBook(Book book) async {
    final docRef = _booksCollection.doc(book.id);
    await docRef.set(book.toMap());
  }

  /// Update an existing book.
  /// If title or author changes, document ID must change:
  /// Performs an atomic transaction to ensure the new ID doesn't already exist,
  /// creates the new document (preserving createdAt & favorite), and deletes the old one.
  Future<void> updateBook(Book oldBook, Book newBook) async {
    final oldTitle = oldBook.title.trim().toLowerCase();
    final newTitle = newBook.title.trim().toLowerCase();
    final oldAuthor = oldBook.author.trim().toLowerCase();
    final newAuthor = newBook.author.trim().toLowerCase();

    final isTitleOrAuthorChanged = oldTitle != newTitle || oldAuthor != newAuthor;

    if (!isTitleOrAuthorChanged) {
      // In-place update (title and author remain identical)
      final docRef = _booksCollection.doc(oldBook.id);
      await docRef.update(newBook.toMap());
    } else {
      // Title or author changed: new document ID required
      final newId = Book.generateId(newBook.userId, newBook.title, newBook.author);

      await firestore.runTransaction((transaction) async {
        final newDocRef = _booksCollection.doc(newId);
        final oldDocRef = _booksCollection.doc(oldBook.id);

        final newDocSnapshot = await transaction.get(newDocRef);
        if (newDocSnapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
            message: 'A book with this title and author already exists in your library.',
          );
        }

        final updatedBook = newBook.copyWith(
          id: newId,
          createdAt: oldBook.createdAt,
          favorite: newBook.favorite,
        );

        transaction.set(newDocRef, updatedBook.toMap());
        transaction.delete(oldDocRef);
      });
    }
  }

  /// Delete a book document by ID
  Future<void> deleteBook(String bookId) async {
    await _booksCollection.doc(bookId).delete();
  }

  /// Toggle or update the favorite status of a book
  Future<void> setFavorite(String bookId, bool favorite) async {
    await _booksCollection.doc(bookId).update({
      'favorite': favorite,
    });
  }
}
