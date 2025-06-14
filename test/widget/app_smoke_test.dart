// ignore_for_file: unused_element
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:e_resta_app/app.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/providers/theme_provider.dart';
import 'package:e_resta_app/features/auth/data/models/user_model.dart';
import 'package:e_resta_app/features/auth/presentation/screens/login_screen.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../test_helpers/geolocator_mocks.dart';
import 'app_smoke_test.mocks.dart';

void _setupFirebaseCoreMock() {
  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
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
            'pluginConstants': {},
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
          'pluginConstants': {},
        };
      }
      return null;
    },
  );
  // Mock other common Firebase plugin channels
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (_) async => null,
  );
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/cloud_firestore'),
    (_) async => null,
  );
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_messaging'),
    (_) async => null,
  );
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_storage'),
    (_) async => null,
  );
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_analytics'),
    (_) async => null,
  );
}

void _setupFirebaseMessagingMock() {
  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_messaging'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getToken') {
        return 'test-fcm-token';
      }
      return null;
    },
  );
}

class MockConnectivity extends Mock implements Connectivity {}

class MockConnectivityProvider extends ConnectivityProvider {
  MockConnectivityProvider() : super(connectivity: MockConnectivity());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _setupFirebaseCoreMock();
  _setupFirebaseMessagingMock();
  setupMockGeolocator();
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('App Widget Test', () {
    late MockSharedPreferences mockPrefs;
    late MockAuthProvider mockAuthProvider;
    late UserModel mockUser;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockAuthProvider = MockAuthProvider();
      mockUser = UserModel(
        id: 1,
        firstName: 'Test',
        lastName: 'User',
        profilePicture: '',
        email: 'test@example.com',
        phoneNumber: '1234567890',
        has2faEnabled: false,
        status: 1,
        address: '123 Test St',
      );
      when(mockPrefs.getBool('isDarkMode')).thenReturn(false);
    });

    testWidgets('shows splash and navigates to correct screen', (tester) async {
      // Simulate not logged in
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.token).thenReturn(null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            // ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(mockPrefs)),
            // ChangeNotifierProvider<ConnectivityProvider>(
            //     create: (_) => MockConnectivityProvider()),
          ],
          child: MyApp(prefs: mockPrefs),
        ),
      );

      // Splash screen should show
      expect(find.text('E-Resta'), findsOneWidget);
      expect(find.text('Discover Your Perfect Meal'), findsOneWidget);

      // Wait for navigation
      await tester.pump(const Duration(seconds: 3));

      // Should navigate to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Simulate logged in
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockAuthProvider.token).thenReturn('token');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            // ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(mockPrefs)),
            // ChangeNotifierProvider<ConnectivityProvider>(
            //     create: (_) => MockConnectivityProvider()),
          ],
          child: MyApp(prefs: mockPrefs),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
