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

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Persists the new display name to the Firestore user doc and
  /// Firebase Auth profile. Throws on failure.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    await user.updateDisplayName(name);
    await _db.collection('users').doc(user.uid).set(
      {'name': name},
      SetOptions(merge: true),
    );
  }

  /// Returns true if the current user signed in with an email/password
  /// credential (vs Google, etc.) — i.e. their password is changeable here.
  bool get hasEmailPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  /// Throws [FirebaseAuthException] on bad credentials or weak passwords,
  /// [StateError] if not signed in or signed in with a non-password provider.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final email = user.email;
    if (email == null || !hasEmailPasswordProvider) {
      throw StateError(
        "This account doesn't use a password. Manage it through your sign-in provider.",
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
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

  /// Permanently deletes the user account:
  ///  1. Re-authenticates with [currentPassword] (Firebase requirement).
  ///  2. Wipes the user's Firestore subcollections + profile doc.
  ///  3. Deletes the FirebaseAuth user.
  ///
  /// Throws [FirebaseAuthException] on bad password or `requires-recent-login`,
  /// [StateError] if not signed in or signed in via Google (we don't accept a
  /// password for Google accounts — they should manage deletion via Google).
  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final email = user.email;
    if (email == null || !hasEmailPasswordProvider) {
      throw StateError(
        "This account doesn't use a password. Sign in again to confirm deletion.",
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;
    await _wipeUserData(uid);

    await user.delete();
  }

  Future<void> _wipeUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    Future<void> deleteSubcollection(String name) async {
      final snap = await userRef.collection(name).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await Future.wait([
      deleteSubcollection('cards'),
      deleteSubcollection('notifications'),
      deleteSubcollection('preferences'),
    ]);

    await userRef.delete();
  }
}
