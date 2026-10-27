import 'package:cloud_firestore/cloud_firestore.dart';

/// Predefined genres for Book entity
class BookGenre {
  static const String fiction = 'Fiction';
  static const String nonFiction = 'Non-Fiction';
  static const String academic = 'Academic';
  static const String other = 'Other';

  static const List<String> all = [fiction, nonFiction, academic, other];

  static bool isValid(String value) => all.contains(value);
}

/// Predefined reading statuses for Book entity
class BookStatus {
  static const String toRead = 'To Read';
  static const String reading = 'Reading';
  static const String finished = 'Finished';

  static const List<String> all = [toRead, reading, finished];

  static bool isValid(String value) => all.contains(value);
}

/// Book model matching Firestore schema:
/// - id: Document ID (deterministic: userId_normalizedTitle_normalizedAuthor)
/// - userId: Owner UID
/// - title: Title of the book (max 100 chars, non-empty trimmed)
/// - author: Author name (max 60 chars, non-empty trimmed)
/// - genre: One of 'Fiction', 'Non-Fiction', 'Academic', 'Other'
/// - status: One of 'To Read', 'Reading', 'Finished'
/// - rating: Integer from 0 to 5 (optional)
/// - favorite: Boolean flag
/// - notes: Optional notes (max 300 chars)
/// - createdAt: Timestamp of creation
class Book {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String? notes;
  final DateTime createdAt;

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes,
    required this.createdAt,
  });

  /// Deterministic ID generator to enforce title+author uniqueness per user.
  /// Replaces '/' with '_' to guarantee a safe document ID path.
  static String generateId(String userId, String title, String author) {
    final cleanTitle = title.trim().toLowerCase().replaceAll('/', '_');
    final cleanAuthor = author.trim().toLowerCase().replaceAll('/', '_');
    return '${userId}_${cleanTitle}_$cleanAuthor';
  }

  /// Create a Book instance with auto-generated deterministic ID
  factory Book.create({
    required String userId,
    required String title,
    required String author,
    required String genre,
    required String status,
    int? rating,
    bool favorite = false,
    String? notes,
    DateTime? createdAt,
  }) {
    final effectiveCreatedAt = createdAt ?? DateTime.now();
    final generatedId = generateId(userId, title, author);
    return Book(
      id: generatedId,
      userId: userId,
      title: title.trim(),
      author: author.trim(),
      genre: genre,
      status: status,
      rating: rating,
      favorite: favorite,
      notes: notes?.trim(),
      createdAt: effectiveCreatedAt,
    );
  }

  /// Factory constructor to deserialize from a Firestore DocumentSnapshot
  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Book.fromMap(data, doc.id);
  }

  /// Factory constructor to deserialize from a Map with explicit id
  factory Book.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Book(
      id: (data['id'] as String?)?.isNotEmpty == true ? (data['id'] as String) : id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      genre: data['genre'] as String? ?? BookGenre.other,
      status: data['status'] as String? ?? BookStatus.toRead,
      rating: data['rating'] is num ? (data['rating'] as num).toInt() : null,
      favorite: data['favorite'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  /// Serialize Book instance to a Firestore-compatible Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'favorite': favorite,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (rating != null) {
      map['rating'] = rating;
    }
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }

    return map;
  }

  /// Create a clone with modified fields
  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? genre,
    String? status,
    int? rating,
    bool? favorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          author == other.author &&
          genre == other.genre &&
          status == other.status &&
          rating == other.rating &&
          favorite == other.favorite &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      author.hashCode ^
      genre.hashCode ^
      status.hashCode ^
      rating.hashCode ^
      favorite.hashCode ^
      notes.hashCode;

  @override
  String toString() {
    return 'Book(id: $id, title: "$title", author: "$author", status: $status, rating: $rating, favorite: $favorite)';
  }
}
