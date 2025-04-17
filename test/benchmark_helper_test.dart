import 'package:benchmark_runner/benchmark_runner.dart' hide group;
import 'package:test/test.dart';

Future<T> later<T>(T t, [Duration duration = Duration.zero]) =>
    Future.delayed(duration, () => t);

final watch = Stopwatch();
void main() {
  group('Converting ticks:', () {
    test(' to s', () {
      expect(BenchmarkHelper.ticksToSeconds(watch.frequency), 1);
    });
    test(' to ms', () {
      expect(BenchmarkHelper.ticksToMilliseconds(watch.frequency), 1000);
    });
    test(' to us', () {
      expect(BenchmarkHelper.ticksToMicroseconds(watch.frequency), 1000000);
    });
  });

  group('Converting:', () {
    test('1 s to ticks', () {
      expect(BenchmarkHelper.secondsToTicks(1), watch.frequency);
    });
    test('1 ms to ticks', () {
      expect(
        BenchmarkHelper.millisecondsToTicks(1),
        watch.frequency ~/ Duration.millisecondsPerSecond,
      );
    });
    test('1 us to ticks', () {
      expect(
        BenchmarkHelper.microsecondsToTicks(1),
        watch.frequency / Duration.microsecondsPerSecond,
      );
    });
  });

  group('sampleSizeDefault:', () {
    test('score estimate <= 1us', () {
      final sampleSize = BenchmarkHelper.sampleSizeDefault(0);
      expect(sampleSize.length, 300);
      expect(sampleSize.innerIterations, 400);
    });
    test('1us < score estimate <= 10us', () {
      final sampleSize = BenchmarkHelper.sampleSizeDefault(
        BenchmarkHelper.frequency ~/ Duration.microsecondsPerSecond,
      );
      expect(sampleSize.length, 200);
      expect(sampleSize.innerIterations, 250);
    });
  });
}
