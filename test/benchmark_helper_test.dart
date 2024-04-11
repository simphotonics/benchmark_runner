import 'package:benchmark_runner/benchmark_runner.dart' hide group;
import 'package:test/test.dart';

Future<T> later<T>(T t, [Duration duration = Duration.zero]) =>
    Future.delayed(duration, () => t);

final watch = Stopwatch();
void main() {
  group('Converting:', () {
    test('ticks to s', () {
      expect(BenchmarkHelper.ticksToSeconds(watch.frequency), 1);
    });
    test('ticks to ms', () {
      expect(BenchmarkHelper.ticksToMilliseconds(watch.frequency), 1000);
    });
    test('ticks to us', () {
      expect(BenchmarkHelper.ticksToMicroseconds(watch.frequency), 1000000);
    });
  });

  group('Converting:', () {
    test('1 s to ticks: ${BenchmarkHelper.secondsToTicks(1)}', () {
      expect(BenchmarkHelper.secondsToTicks(1), watch.frequency);
    });
    test('1 ms to ticks: ${BenchmarkHelper.millisecondsToTicks(1)}', () {
      expect(BenchmarkHelper.millisecondsToTicks(1), watch.frequency / 1000);
    });
    test('1 us to ticks: ${BenchmarkHelper.microsecondsToTicks(1)}', () {
      expect(BenchmarkHelper.microsecondsToTicks(1), watch.frequency / 1000000);
    });
  });
}
