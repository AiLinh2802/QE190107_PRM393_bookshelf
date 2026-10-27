import 'package:firebase_auth/firebase_auth.dart';

/// AuthService handles all Firebase Authentication operations:
/// - authStateChanges: Stream emitting User when state changes
/// - registerWithEmailAndPassword: Creates new user account
/// - signInWithEmailAndPassword: Authenticates existing user
/// - signOut: Ends user session
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream of authentication state changes (null when logged out, User when logged in)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user (or null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Register a new account with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
