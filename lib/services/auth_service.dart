import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<({User? user, String? error})> signUp(
      String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _firestore.createUserDoc(email);
      }
      return (user: result.user, error: null);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signUp error: ${e.code}');
      return (user: null, error: _mapError(e.code));
    } catch (e) {
      debugPrint('[Auth] signUp unexpected: $e');
      return (user: null, error: 'Something went wrong. Please try again.');
    }
  }

  Future<({User? user, String? error})> signIn(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (user: result.user, error: null);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signIn error: ${e.code}');
      return (user: null, error: _mapError(e.code));
    } catch (e) {
      debugPrint('[Auth] signIn unexpected: $e');
      return (user: null, error: 'Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
