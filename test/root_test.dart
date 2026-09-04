import 'package:benchmark_runner/src/extension/root.dart' show Root;
import 'package:test/test.dart';

void main() {
  group('root:', (() {
    test('values', () {
      expect(8.root(3), 2);
      expect(4.root(2), 2);
      expect(27.root(3), 3);
    });
    test('negative values', () {
      expect((-8).root(3), isNaN);
    });
    test('nan', () {
      expect((0 / 0).root(2), isNaN);
    });
    test('infinity', () {
      expect((1 / 0).root(3), 1 / 0);
    });
    test('accuracy', () {
      expect(100.root(10), closeTo(1.5848931925, 1e-10));
    });
  }));
}
