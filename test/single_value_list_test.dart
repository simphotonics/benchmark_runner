import 'package:benchmark_runner/benchmark_runner.dart' as br;
import 'package:test/test.dart';

typedef SingleValueList = br.SingleValueList;

void main() {
  group(' List length:', () {
    test('default', () {
      final l1 = SingleValueList(value: 'a');
      expect(l1.length, 1);
    });
    test('-10', () {
      final l1 = SingleValueList(value: 'a', length: -10);
      expect(l1.length, 1);
    });
    test('10000', () {
      final l1 = SingleValueList(value: 'a', length: 10000);
      expect(l1.length, 10000);
    });
  });
  group(' Getters:', () {
    test('first', () {
      final l1 = SingleValueList(value: 'a');
      expect(l1.first, 'a');
    });
    test('last', () {
      final l1 = SingleValueList(value: 'a', length: 10);
      expect(l1.last, 'a');
    });
    test('at index 5', () {
      final l1 = SingleValueList(value: 'a', length: 10000);
      expect(l1[5], 'a');
    });
  });
  group('Operators:', () {
    test('[5]', () {
      final l1 = SingleValueList(value: 'a', length: 1000);
      expect(l1[5], 'a');
    });
    test('[out of range]', () {
      final l1 = SingleValueList(value: 'a', length: 1000);
      expect(() => l1[5000], throwsRangeError);
    });

    test('+', () {
      final l1 = SingleValueList(value: 'a', length: 2);
      final l2 = SingleValueList(value: 'b');
      expect(l1 + l2, ['a', 'a', 'b']);
    });
  });
}
