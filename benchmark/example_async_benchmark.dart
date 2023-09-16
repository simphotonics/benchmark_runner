import 'package:benchmark_runner/benchmark_runner.dart';

/// Returns the value [t] after waiting for [duration].
Future<T> later<T>(T t, [Duration duration = Duration.zero]) {
  return Future.delayed(duration, () => t);
}

void main(List<String> args) async {
  await group('Group 1', () async {
    await asyncBenchmark('wait 5ms', () async {
      await later<int>(27, Duration(microseconds: 5));
    });
   benchmark('throws', () {
      throw UnsupportedError('Thrown in benchmark.');
    });
  });
  await group('Group 2', () async {
    await asyncBenchmark('wait 10ms', () async {
      await later<int>(39, Duration(microseconds: 5));
    });
    await asyncBenchmark('wait 20ms', () async {
      await later<int>(87, Duration(microseconds: 5));
    });
  });
}
