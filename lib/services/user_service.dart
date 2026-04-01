import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kissanfresh/model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "users";

  Future<bool> checkUserExists(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(collectionName)
          .doc(uid)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint("Error checking if user exists: $e");
      return false;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      debugPrint("Error creating user: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(collectionName)
          .doc(uid)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user: $e");
      return null;
    }
  }
}
