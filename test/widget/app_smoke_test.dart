import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_resta_app/main.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';
import 'package:e_resta_app/features/auth/presentation/screens/login_screen.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/features/auth/data/models/user_model.dart';
import 'package:e_resta_app/core/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

// Generate mocks using build_runner:
// flutter pub run build_runner build
@GenerateMocks([SharedPreferences, AuthProvider])
import 'app_smoke_test.mocks.dart';

void setupFirebaseMocks() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_core');
  TestWidgetsFlutterBinding.ensureInitialized();
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'initializeCore' ||
        methodCall.method == 'initializeApp') {
      return null;
    }
    return null;
  });
}

void main() {
  setupFirebaseMocks();

  TestWidgetsFlutterBinding.ensureInitialized();

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
        fcmToken: null,
        google2faSecret: null,
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
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(mockPrefs)),
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
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(mockPrefs)),
          ],
          child: MyApp(prefs: mockPrefs),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
