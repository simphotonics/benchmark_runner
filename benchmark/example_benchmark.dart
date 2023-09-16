// ignore_for_file: unused_local_variable
import 'dart:collection';

import 'package:benchmark_runner/benchmark_runner.dart';

void main(List<String> args) async {
  group('Set', () async {
    await asyncBenchmark('future values', () async {
      final set = {for (var i = 0; i < 100; ++i) Future.value(i)};
    });
    await asyncBenchmark(
      'awaited future values',
      () async {
        final set = {for (var i = 0; i < 10; ++i) await Future.value(i)};
      },
    );
  });
  group('List:', () {
    final originalList = <int>[for (var i = 0; i < 1000; ++i) i];

    benchmark('construct', () {
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    });

    benchmark('construct', () {
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    }, emitStats: false);

    benchmark('construct list view', () {
      final listView = UnmodifiableListView(originalList);
    });
  });
}
