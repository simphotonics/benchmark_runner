// ignore_for_file: unused_local_variable
import 'package:benchmark_runner/benchmark_runner.dart';

class CustomEmitter extends ColorPrintEmitter {
  void emitMean({required Score score}) {
    print('Mean               Standard Deviation');
    print('${score.stats.mean}  ${score.stats.stdDev}');
  }
}

void main(List<String> args) {
  group('List:', () {
    final originalList = <int>[for (var i = 0; i < 1000; ++i) i];

    benchmark(
      'construct | Custom emitter',
      () {
        var list = <int>[for (var i = 0; i < 1000; ++i) i];
      },
      emitter: CustomEmitter(),
      report: (instance, emitter) => emitter.emitMean(
        score: instance.score(),
      ),
    );

    benchmark('construct', () {
      var list = <int>[for (var i = 0; i < 1000; ++i) i];
    }, report: reportMean);
  });
}
