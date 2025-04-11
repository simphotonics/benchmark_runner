// ignore_for_file: unused_local_variable
import 'package:benchmark_runner/benchmark_runner.dart';

void main(List<String> args) {
  group('List:', () {
    final originalList = <int>[for (var i = 0; i < 1000; ++i) i];

    benchmark('construct', () {
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    });

    benchmark('construct', () {
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    }, scoreEmitter: MeanEmitter());
  });
}
