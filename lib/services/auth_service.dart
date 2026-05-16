import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ─── REGISTER ───────────────────────────────────────────
  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Username unique check
      final usernameCheck = await _db
          .collection('users')
          .where('usernameLower', isEqualTo: username.toLowerCase())
          .get();
      if (usernameCheck.docs.isNotEmpty) {
        return 'Username already taken. Choose another.';
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'email': email,
        'bio': '',
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'trips': 0,
        'places': 0,
        'countries': 0,
      });

      await cred.user!.updateDisplayName(name);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  // ─── LOGIN (email ya username dono se) ──────────────────
  Future<String?> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername.trim();

      // Agar '@' nahi hai to username samjho — Firestore se email dhundo
      if (!email.contains('@')) {
        final query = await _db
            .collection('users')
            .where('usernameLower', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          return 'No account found with this username.';
        }
        email = query.docs.first.data()['email'];
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  // ─── LOGOUT ─────────────────────────────────────────────
  Future<void> logout() async => await _auth.signOut();

  // ─── GET USER DATA ───────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── UPDATE PROFILE ──────────────────────────────────────
  Future<String?> updateProfile({
    required String name,
    String? phone,
    String? bio,
  }) async {
    try {
      final uid = currentUser!.uid;
      await _db.collection('users').doc(uid).update({
        'name': name,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
      });
      await currentUser!.updateDisplayName(name);
      return null;
    } catch (e) {
      return 'Update failed. Try again.';
    }
  }

  // ─── RESET PASSWORD ──────────────────────────────────────
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  // ─── ERROR MESSAGES ──────────────────────────────────────
  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already registered.';
      case 'invalid-email': return 'Invalid email address.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-credential': return 'Incorrect email/username or password.';
      case 'too-many-requests': return 'Too many attempts. Try later.';
      default: return 'Something went wrong. Try again.';
    }
  }
}