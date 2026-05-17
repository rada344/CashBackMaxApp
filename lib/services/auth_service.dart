import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name,
      'email': email,
    });

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = await _auth.signInWithPopup(googleProvider);

      await _db.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': userCredential.user!.displayName ?? 'Google User',
        'email': userCredential.user!.email ?? '',
      }, SetOptions(merge: true));

      return userCredential;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
