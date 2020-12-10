import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/authentication.dart';

class Data extends ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Auth _auth;

  Data() {
    _auth = Auth();
  }

  String _message;

  Stream<User> get authStateChanged => auth.getAuthInstance.authStateChanges();

  get auth => _auth;

  Future<String> signIn(String email, String password) async {
    try {
      await _auth.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      _message = e.code;
    }
    return _message;
  }

  Future<String> createAccount(String email, String password) async {
    try {
      await _auth.createAccount(email, password);
    } catch (e) {
      _message = e.code;
    }
    return _message;
  }

  String getUser() {
    return _auth.currentUser();
  }

  void signOut() {
    _auth.signOut();
    notifyListeners();
  }

  Future<void> uploadItem(
      String itemName, String itemLocation, String user) async {
    try {
      await firestore.collection(user).doc(itemName).set({
        'itemName': itemName,
        'itemLocation': itemLocation,
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> uploadLocation(
      String itemName, String itemLocation, String user) async {
    Map<String, dynamic> data = Map();

    data[itemLocation] = itemLocation;

    try {
      await firestore
          .collection(user)
          .doc(itemName)
          .collection('pastLocations')
          .doc('listOfLocations')
          .set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      print(e);
    }
  }

  Future<List<dynamic>> getLocationList(String user, String itemName) async {
    List<dynamic> locationList = [];
    try {
      DocumentSnapshot results = await firestore
          .collection(user)
          .doc(itemName)
          .collection('pastLocations')
          .doc('listOfLocations')
          .get();
      if (results.data() != null) {
        results.data().forEach((key, value) {
          locationList.add(value);
        });
      }
    } catch (e) {
      print(e);
    }
    return locationList;
  }

  void deleteItem(String itemName, String user) async {
    try {
      firestore
          .collection(user)
          .doc(itemName)
          .collection('pastLocations')
          .doc('listOfLocations')
          .delete();
      firestore.collection(user).doc(itemName).delete();
    } catch (e) {
      print(e);
    }
  }
}
