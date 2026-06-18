// Generated Firebase options for ShowMyName.
// Keep these values in sync with the Firebase project showmyname-liisgo.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase options are not configured for web.');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia =>
        throw UnsupportedError(
          'Firebase options are only configured for Android and iOS.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4-8UD43lcb8VpgwI-uneKdHBqZLWBDo0',
    appId: '1:90639649444:android:81c571f7d74f8e0c753431',
    messagingSenderId: '90639649444',
    projectId: 'showmyname-liisgo',
    storageBucket: 'showmyname-liisgo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB10NmVRFUAS9NBeAR-dgCIacixLMEwFuo',
    appId: '1:90639649444:ios:f64096e7d8762074753431',
    messagingSenderId: '90639649444',
    projectId: 'showmyname-liisgo',
    storageBucket: 'showmyname-liisgo.firebasestorage.app',
    iosBundleId: 'com.liisgo.showmyname.ios',
  );
}
