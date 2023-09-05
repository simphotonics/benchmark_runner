import 'dart:collection';

import 'package:benchmark_runner/benchmark_runner.dart';

void main(List<String> args) {
  final originalList = <int>[for (var i = 0; i < 1000; ++i) i];

  group('List:', () {
    benchmark('construct list', () {
      // ignore: unused_local_variable
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    });
    benchmark('construct list', () {
      // ignore: unused_local_variable
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    },emitStats: false);
    benchmark('construct list view', () {
      // ignore: unused_local_variable
      final listView = UnmodifiableListView(originalList);
    });
    asyncBenchmark('nothing', () async {
      Future.delayed(Duration.zero, () async => Never);
    },emitStats: false);
    asyncBenchmark('nothing', () async {
      Future.delayed(Duration.zero, () async => Never);
    }, emitStats: true);
  });
}
