// ignore_for_file: unused_local_variable

import 'package:benchmark_runner/benchmark_runner.dart';

/// Returns the value [t] after waiting for [duration].
Future<T> later<T>(T t, [Duration duration = Duration.zero]) {
  return Future.delayed(duration, () => t);
}

void main(List<String> args) async {
  await group('Wait for duration', () async {
    await asyncBenchmark('10ms', () async {
      await later<int>(39, Duration(milliseconds: 10));
    });

    await asyncBenchmark('5ms', () async {
      await later<int>(27, Duration(milliseconds: 5));
    }, report: reportLegacyStyleAsync);
  });

  group('Set', () async {
    await asyncBenchmark('error test', () {
      throw ('Thrown in benchmark.');
    });

    benchmark('construct', () {
      final set = {for (var i = 0; i < 1000; ++i) i};
    });

    throw 'Error in group';
  });
}
