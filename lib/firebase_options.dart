// File generated for PrecisionCare Diagnostic Centre
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your PrecisionCare Diagnostic Centre Firebase project (precision-care-2ab84).
class DefaultFirebaseOptions {
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
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0AWDQaQ-h9FrsbEc7wojPs2V3R0EzbT4',
    appId: '1:59309205465:web:9f8866300d969fdded9bc8',
    messagingSenderId: '59309205465',
    projectId: 'precision-care-2ab84',
    authDomain: 'precision-care-2ab84.firebaseapp.com',
    storageBucket: 'precision-care-2ab84.firebasestorage.app',
    measurementId: 'G-7JXFY2G6X7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtL7bY4bWb8xupP6n099Ik_Kr88zeQ9Bo',
    appId: '1:59309205465:android:05b49fbb7688ff96ed9bc8',
    messagingSenderId: '59309205465',
    projectId: 'precision-care-2ab84',
    storageBucket: 'precision-care-2ab84.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCsVfEGPgGUxy8gX0P6PH09T2bE63gn4w',
    appId: '1:59309205465:ios:e65c3f08da42bc3aed9bc8',
    messagingSenderId: '59309205465',
    projectId: 'precision-care-2ab84',
    storageBucket: 'precision-care-2ab84.firebasestorage.app',
    iosBundleId: 'com.precisioncare.precisioncareApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDCsVfEGPgGUxy8gX0P6PH09T2bE63gn4w',
    appId: '1:59309205465:ios:e65c3f08da42bc3aed9bc8',
    messagingSenderId: '59309205465',
    projectId: 'precision-care-2ab84',
    storageBucket: 'precision-care-2ab84.firebasestorage.app',
    iosBundleId: 'com.precisioncare.precisioncareApp',
  );
}
