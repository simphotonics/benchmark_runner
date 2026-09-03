// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:benchmark_runner/benchmark_runner.dart';

/// Returns the value [t] after waiting for [duration].
Future<T> later<T>(T t, [Duration duration = Duration.zero]) async {
  sleep(duration); // Has lower overhead compared to Future.pause.
  return t;
}

void main(List<String> args) async {
  await asyncGroup('1: Wait for duration', () async {
    await asyncBenchmark('10ms', () async {
      await later<int>(39, Duration(milliseconds: 10));
    });

    await asyncBenchmark('5ms', () async {
      await later<String>('result', Duration(milliseconds: 5));
    }, scoreEmitter: MeanEmitter());
  });

  group('2: Set', () {
    benchmark('error test', () {
      throw ('Thrown in benchmark: error test.');
    });

    benchmark('construct', () {
      final set = {for (var i = 0; i < 1000; ++i) i};
    });

    throw 'Error in group';
  });
}
