// File generated for KittyCircle Firebase initialization.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyC-jZOcCrWLQRChh6wuMuuERW2oWi1rN4U',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:541062079623:android:daf08c29889d4b886f4422',
    messagingSenderId: '541062079623',
    projectId: 'kittycircle-firebase-prod',
    storageBucket: 'kittycircle-firebase-prod.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:541062079623:web:daf08c29889d4b886f4422',
    messagingSenderId: '541062079623',
    projectId: 'kittycircle-firebase-prod',
    storageBucket: 'kittycircle-firebase-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:541062079623:ios:daf08c29889d4b886f4422',
    messagingSenderId: '541062079623',
    projectId: 'kittycircle-firebase-prod',
    storageBucket: 'kittycircle-firebase-prod.firebasestorage.app',
    iosBundleId: 'in.mahato.kittycircle',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:541062079623:ios:daf08c29889d4b886f4422',
    messagingSenderId: '541062079623',
    projectId: 'kittycircle-firebase-prod',
    storageBucket: 'kittycircle-firebase-prod.firebasestorage.app',
    iosBundleId: 'in.mahato.kittycircle',
  );
}
