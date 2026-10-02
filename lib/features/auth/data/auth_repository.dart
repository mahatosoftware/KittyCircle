import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';
import '../../profile/data/profile_repository.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final ProfileRepository _profileRepository;

  UserModel? _demoUser;
  bool _hasSignedOut = false;

  factory AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    ProfileRepository? profileRepository,
  }) {
    if (auth != null || googleSignIn != null || profileRepository != null) {
      return AuthRepository._internal(
        auth: auth,
        googleSignIn: googleSignIn,
        profileRepository: profileRepository,
      );
    }
    return _instance;
  }

  AuthRepository._internal({
    this._auth,
    GoogleSignIn? googleSignIn,
    ProfileRepository? profileRepository,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _profileRepository = profileRepository ?? ProfileRepository();

  bool get isUserAuthenticated {
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final authInstance = _auth ?? FirebaseAuth.instance;
        if (authInstance.currentUser != null) return true;
      } catch (_) {}
    }
    return !_hasSignedOut;
  }

  User? get currentFirebaseUser {
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final authInstance = _auth ?? FirebaseAuth.instance;
        return authInstance.currentUser;
      } catch (_) {}
    }
    return null;
  }

  Stream<User?> get authStateChanges {
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final authInstance = _auth ?? FirebaseAuth.instance;
        return authInstance.authStateChanges();
      } catch (_) {}
    }
    return Stream.value(null);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentFirebaseUser;
    if (user != null) {
      final profile = await _profileRepository.getUserProfile(user.uid);
      if (profile != null) return profile;
      final newProfile = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Kitty Member',
        email: user.email,
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
      );
      await _profileRepository.saveUserProfile(newProfile);
      return newProfile;
    }

    if (_demoUser != null) return _demoUser;
    
    _demoUser = UserModel(
      uid: 'user_priya_1',
      displayName: 'Priya Sharma',
      phoneNumber: '+919876543210',
      email: 'priya@kittycircle.app',
      city: 'Bengaluru',
      language: 'en',
    );
    return _demoUser;
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    _hasSignedOut = false;
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final authInstance = _auth ?? FirebaseAuth.instance;
        final credential = await authInstance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = credential.user!.uid;
        var profile = await _profileRepository.getUserProfile(uid);
        if (profile == null) {
          profile = UserModel(
            uid: uid,
            displayName: email.split('@').first,
            email: email,
          );
          await _profileRepository.saveUserProfile(profile);
        }
        return profile;
      } catch (_) {}
    }

    _demoUser = UserModel(
      uid: 'user_email_${email.hashCode}',
      displayName: email.split('@').first,
      email: email,
      city: 'Bengaluru',
    );
    return _demoUser!;
  }

  Future<UserModel> registerWithEmail(String email, String password, String name) async {
    _hasSignedOut = false;
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final authInstance = _auth ?? FirebaseAuth.instance;
        final credential = await authInstance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = credential.user!.uid;
        final profile = UserModel(
          uid: uid,
          displayName: name,
          email: email,
        );
        await _profileRepository.saveUserProfile(profile);
        return profile;
      } catch (_) {}
    }

    _demoUser = UserModel(
      uid: 'user_demo_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
      email: email,
      city: 'Bengaluru',
    );
    return _demoUser!;
  }

  Future<UserModel?> signInWithGoogle() async {
    _hasSignedOut = false;
    if (Firebase.apps.isNotEmpty || _auth != null) {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final authInstance = _auth ?? FirebaseAuth.instance;
        final userCredential = await authInstance.signInWithCredential(credential);
        final user = userCredential.user!;

        var profile = await _profileRepository.getUserProfile(user.uid);
        if (profile == null) {
          profile = UserModel(
            uid: user.uid,
            displayName: user.displayName ?? 'Kitty Member',
            email: user.email,
            photoUrl: user.photoURL,
          );
          await _profileRepository.saveUserProfile(profile);
        }
        return profile;
      } catch (_) {}
    }

    _demoUser = UserModel(
      uid: 'user_google_demo',
      displayName: 'Google User',
      email: 'google@kittycircle.app',
      city: 'Bengaluru',
    );
    return _demoUser;
  }

  void setDemoUser(UserModel user) {
    _demoUser = user;
    _hasSignedOut = false;
  }

  Future<void> signOut() async {
    _hasSignedOut = true;
    try {
      await _googleSignIn.signOut();
      if (Firebase.apps.isNotEmpty || _auth != null) {
        final authInstance = _auth ?? FirebaseAuth.instance;
        await authInstance.signOut();
      }
    } catch (_) {}
    _demoUser = null;
  }

  Future<void> deleteAccount() async {
    _hasSignedOut = true;
    final user = currentFirebaseUser;
    if (user != null) {
      await _profileRepository.deleteUserProfile(user.uid);
      await user.delete();
    }
    _demoUser = null;
  }
}
