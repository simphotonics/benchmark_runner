// ignore_for_file: unused_local_variable

import 'package:benchmark_runner/benchmark_runner.dart';

Future<T> later<T>(T t) async {
  return await Future.delayed(Duration(microseconds: 100), () => t);
}

void main(List<String> args) async {
  final originalSet = <int>{for (var i = 0; i < 1000; ++i) i};

  await asyncGroup('Set 1:', () async {
    await asyncBenchmark('construct future set', () async {
      final set = {for (var i = 0; i < 100; ++i) await Future.value(i)};
    });
   await asyncBenchmark('wait 1 ms await', () async {
      await later<int>(10);
    });
  });
  // asyncBenchmark('construct set view 99', run: () async {});
  await asyncGroup('Set 2:', () async {
    await asyncBenchmark('construct future list', () async {
      final list = [for (var i = 0; i < 100; ++i) await Future.value(i)];
      throw UnsupportedError('');
    });
    await asyncBenchmark('wait 100 ms', () async {
      await later<int>(10);
    });
  });
}
