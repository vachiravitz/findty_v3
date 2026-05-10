// ignore_for_file: type=lint
//
// ค่าทั้งหมดมาจาก:
//   Android -> android/app/google-services.json
//   iOS     -> ios/Runner/GoogleService-Info.plist
// project: findty-a7695

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions ยังไม่รองรับ web - '
            'ถ้าต้องการ ให้เพิ่ม Web app ใน Firebase Console',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ยังไม่รองรับ platform นี้',
        );
    }
  }

  // ---- Android ----
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDl5zmoJZMeUl7bqR8Yr8ei4kPlUmcPGN8',
    appId: '1:598414350738:android:adad0c2622644e23f5094b',
    messagingSenderId: '598414350738',
    projectId: 'findty-a7695',
    storageBucket: 'findty-a7695.firebasestorage.app',
  );

  // ---- iOS ----
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD9aUWQb-fdAenyv7iXBqv9KNsZADBsek',
    appId: '1:598414350738:ios:4714c16ca492aa16f5094b',
    messagingSenderId: '598414350738',
    projectId: 'findty-a7695',
    storageBucket: 'findty-a7695.firebasestorage.app',
    iosBundleId: 'com.vachiravit.findty',
  );
}