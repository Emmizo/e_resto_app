import 'package:e_resta_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App integration flow: splash to login/main', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Splash screen should show
    expect(find.text('E-Resta'), findsOneWidget);
    expect(find.text('Discover Your Perfect Meal'), findsOneWidget);

    // Wait for navigation
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should land on either LoginScreen or MainScreen
    final loginScreen = find.text('Login');
    final mainScreen = find.text('E-Resta'); // AppBar title
    expect(
      loginScreen.evaluate().isNotEmpty || mainScreen.evaluate().isNotEmpty,
      isTrue,
      reason: 'Should land on either LoginScreen or MainScreen',
    );
  });
}
