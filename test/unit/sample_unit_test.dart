import 'package:flutter_test/flutter_test.dart';

// A simple function to test
int add(int a, int b) => a + b;

void main() {
  group('add()', () {
    test('returns the sum of two positive numbers', () {
      expect(add(2, 3), 5);
    });

    test('returns the sum when one number is negative', () {
      expect(add(-2, 3), 1);
    });

    test('returns the sum when both numbers are negative', () {
      expect(add(-2, -3), -5);
    });
  });
}
