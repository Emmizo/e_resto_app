import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter_driver/flutter_driver.dart';

StepDefinitionGeneric fillFieldStep() {
  return when2<String, String, FlutterWorld>(
    'I fill the {string} field with {string}',
    (fieldKey, value, context) async {
      final fieldFinder = find.byValueKey(fieldKey);
      await context.world.driver?.tap(fieldFinder);
      await context.world.driver?.enterText(value);
      await context.world.driver?.waitFor(fieldFinder);
    },
  );
}

StepDefinitionGeneric tapButtonStep() {
  return when1<String, FlutterWorld>(
    'I tap the {string} button',
    (buttonKey, context) async {
      final buttonFinder = find.byValueKey(buttonKey);
      await context.world.driver?.tap(buttonFinder);
      await context.world.driver?.waitFor(buttonFinder);
    },
  );
}

StepDefinitionGeneric expectToSeeStep() {
  return then1<String, FlutterWorld>(
    'I expect to see {string}',
    (text, context) async {
      await context.world.driver?.waitFor(find.text(text));
    },
  );
}

List<StepDefinitionGeneric> steps = [
  fillFieldStep(),
  tapButtonStep(),
  expectToSeeStep(),
];
