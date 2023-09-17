// ignore_for_file: unused_local_variable
import 'dart:collection';

import 'package:benchmark_runner/benchmark_runner.dart';

void main(List<String> args) {
  group('Set', () {
    benchmark('construct', () {
      final set = {for (var i = 0; i < 1000; ++i) i};
    });

    final list = [for (var i = 0; i < 1000; ++i) i];
    benchmark('construct from list', () {
      final set = Set<int>.of(list);
    });
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
