import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';

void main() {
  testWidgets('MainScreen golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('goldens/main_screen_golden.png'),
    );
  });
}
