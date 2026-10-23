import 'dart:math';

import 'package:benchmark_runner/src/base/score_generator.dart';
import 'package:sample_statistics/sample_statistics.dart';

final rand = Random();
void run() {
  // ignore: unused_local_variable
  final d = pow(sqrt(rand.nextDouble()), 10);
}

String numToString(num arg) => arg.toStringAsExponential();

void main(List<String> args) {
  final generator = ScoreGenerator(run: run);

  final stats = generator.score().stats;

  print(
    stats.blockHistogram(
      infoOption: HistogramInfoOption.showMedian,
      numToString: (x) => x.toStringAsFixed(4),
    ),
  );
}
