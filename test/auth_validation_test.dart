import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Validation Tests', () {
    String? validateEmail(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Email is required';
      }
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
      return null;
    }

    String? validateRegisterPassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      return null;
    }

    String? validateLoginPassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      return null;
    }

    String? validateConfirmPassword(String? value, String password) {
      if (value == null || value.isEmpty) {
        return 'Confirm password is required';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    }

    test('Email validation returns exact strings', () {
      expect(validateEmail(''), 'Email is required');
      expect(validateEmail('   '), 'Email is required');
      expect(validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(validateEmail('test@'), 'Please enter a valid email address');
      expect(validateEmail('user@domain.com'), isNull);
    });

    test('Register password validation returns exact strings', () {
      expect(validateRegisterPassword(''), 'Password is required');
      expect(validateRegisterPassword('12345'), 'Password must be at least 6 characters');
      expect(validateRegisterPassword('123456'), isNull);
    });

    test('Login password validation checks only empty', () {
      expect(validateLoginPassword(''), 'Password is required');
      expect(validateLoginPassword('123'), isNull);
    });

    test('Confirm password validation returns exact strings', () {
      expect(validateConfirmPassword('', 'secret123'), 'Confirm password is required');
      expect(validateConfirmPassword('secret321', 'secret123'), 'Passwords do not match');
      expect(validateConfirmPassword('secret123', 'secret123'), isNull);
    });
  });
}
