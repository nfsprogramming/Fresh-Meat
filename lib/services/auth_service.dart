import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _auth {
    try {
      if (isFirebaseAvailable) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  User? get currentFirebaseUser => _auth?.currentUser;

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges();
    }
    return const Stream.empty();
  }

  /// Performs Google Sign-In and authenticates with Firebase.
  /// Returns a [UserProfile] if successful, or null if the user cancelled.
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the prompt
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Authenticate with Firebase if Firebase is available
      final auth = _auth;
      if (auth != null) {
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await auth.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          return UserProfile(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? googleUser.displayName ?? 'Customer',
            email: firebaseUser.email ?? googleUser.email,
            photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          );
        }
      }

      // Fallback if Firebase core is not connected
      return UserProfile(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Customer',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
      );
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Signs out of both Firebase Authentication and Google Sign-In
  Future<void> signOut() async {
    try {
      final auth = _auth;
      if (auth != null) {
        await auth.signOut();
      }
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
