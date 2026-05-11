import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show  kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC7zZMtnSnbbfTWWJlXU3qWS-hQ5LayAYE",
  authDomain: "mahsa-smart-campus-navig-81bae.firebaseapp.com",
  projectId: "mahsa-smart-campus-navig-81bae",
  storageBucket: "mahsa-smart-campus-navig-81bae.firebasestorage.app",
  messagingSenderId: "419359408974",
  appId: "1:419359408974:web:3f292a80724ed95653d41f",
  measurementId: "G-SR49F24WR6"

  );
}