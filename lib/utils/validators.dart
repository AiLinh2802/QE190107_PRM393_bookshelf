/// Shared validator functions reused across Add Book and Edit Book forms
class BookValidators {
  /// Title: required, max 100 characters, whitespace-only rejected
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.length > 100) {
      return 'Title must be at most 100 characters';
    }
    return null;
  }

  /// Author: required, max 60 characters, whitespace-only rejected
  static String? validateAuthor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Author is required';
    }
    if (value.length > 60) {
      return 'Author must be at most 60 characters';
    }
    return null;
  }

  /// Genre: required selection
  static String? validateGenre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please choose a genre';
    }
    return null;
  }

  /// Status: required selection
  static String? validateStatus(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please choose a status';
    }
    return null;
  }

  /// Rating: optional; if provided, must be whole number between 0 and 5
  static String? validateRating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0 || n > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  /// Notes: optional, max 300 characters
  static String? validateNotes(String? value) {
    if (value != null && value.length > 300) {
      return 'Notes must be at most 300 characters';
    }
    return null;
  }
}
