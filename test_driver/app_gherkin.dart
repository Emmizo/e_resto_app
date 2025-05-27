import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'steps/step_definitions.dart';

Future<void> main() {
  return GherkinRunner().execute(
    FlutterTestConfiguration()
      ..features = [RegExp('test_driver/features/*.*')]
      ..stepDefinitions = steps
      ..restartAppBetweenScenarios = true
      ..targetAppPath = 'lib/main.dart',
  );
}
