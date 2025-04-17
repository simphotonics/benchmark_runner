import 'package:benchmark_runner/src/extension/duration_to_ticks.dart';
import 'package:test/test.dart';

void main() {
  group('Conversion:', () {
    test('1s', () {
      expect(Duration(seconds: 1).inTicks, DurationToTicks.frequency);
    });
    test('1ms', () {
      expect(
        Duration(milliseconds: 1).inTicks,
        DurationToTicks.frequency ~/ 1000,
      );
    });
    test('1us', () {
      expect(
        Duration(microseconds: 1).inTicks,
        DurationToTicks.frequency ~/ 1000000,
      );
    });
  });
}
