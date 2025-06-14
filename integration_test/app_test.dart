import 'package:e_resta_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows splash screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('E-Resto'), findsOneWidget);
    expect(find.text('Discover Your Perfect Meal'), findsOneWidget);
  });
}
