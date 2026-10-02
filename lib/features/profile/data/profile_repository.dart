import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/constants/app_constants.dart';

class ProfileRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, UserModel> _localUserStore = {};

  ProfileRepository({this._firestore});

  Future<UserModel?> getUserProfile(String userId) async {
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final doc = await db.collection(AppConstants.usersCollection).doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final model = UserModel.fromMap(doc.data()!, doc.id);
          _localUserStore[userId] = model;
          return model;
        }
      } catch (_) {}
    }
    return _localUserStore[userId];
  }

  Future<void> saveUserProfile(UserModel user) async {
    _localUserStore[user.uid] = user;
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? city,
    String? language,
  }) async {
    final existing = await getUserProfile(userId);
    if (existing != null) {
      final updated = existing.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        city: city,
        language: language,
      );
      await saveUserProfile(updated);
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    _localUserStore.remove(userId);
    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection(AppConstants.usersCollection).doc(userId).delete();
      } catch (_) {}
    }
  }
}
