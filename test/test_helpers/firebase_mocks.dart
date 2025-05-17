import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel firebaseCoreChannel =
      MethodChannel('plugins.flutter.io/firebase_core');
  // ignore: deprecated_member_use
  firebaseCoreChannel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake',
            'appId': 'fake',
            'messagingSenderId': 'fake',
            'projectId': 'fake',
          },
          'pluginConstants': {
            'firebase_auth': {},
            'firebase_messaging': {},
            'cloud_firestore': {},
            'firebase_analytics': {},
          },
        }
      ];
    }
    if (methodCall.method == 'initializeApp') {
      return {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': 'fake',
          'appId': 'fake',
          'messagingSenderId': 'fake',
          'projectId': 'fake',
        },
        'pluginConstants': {
          'firebase_auth': {},
          'firebase_messaging': {},
          'cloud_firestore': {},
          'firebase_analytics': {},
        },
      };
    }
    return null;
  });
}
