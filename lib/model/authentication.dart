import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

class Auth {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createAccount(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<User> signIn(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return userCredential.user;
  }

  void signOut() {
    _auth.signOut();
  }

  String currentUser() {
    User user = _auth.currentUser;
    return user.uid;
  }

  get getAuthInstance => _auth;
}
