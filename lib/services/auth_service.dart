
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Listen to login/logout changes
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // Create new account

  Future<UserCredential> signUp(
      String name,
      String email,
      String password,
      ) async {
    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());

    await credential.user?.reload();

    return credential;
  }


  // Login existing user
  Future<UserCredential> login(
      String email,
      String password,
      ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
}
