// ignore_for_file: unused_local_variable
import 'package:benchmark_runner/benchmark_runner.dart';

class CustomEmitter implements ScoreEmitter {
  @override
  void emit({required description, required Score score}) {
    print('Mean               Standard Deviation');
    print('${score.stats.mean}  ${score.stats.stdDev}');
  }
}

void main(List<String> args) {
  benchmark('construct | Custom emitter', () {
    var list = <int>[for (var i = 0; i < 1000; ++i) i];
  }, scoreEmitter: CustomEmitter());
}
