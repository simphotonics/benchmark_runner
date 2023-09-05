import 'package:benchmark_harness/benchmark_harness.dart' show ScoreEmitter;
import 'package:benchmark_runner/benchmark_runner.dart';

extension ColorPrint on ScoreEmitter {
  /// Writes a colorized benchmark score to stdout.
  void emitStats({
    String description = '',
    required double mean,
    required double stdDev,
    required double median,
    required double interQuartileRange,
    String blockHistogram = '',
  }) {
    var score = 'mean: ${mean.toStringAsFixedDigits()} \u00B1 '
            '${stdDev.toStringAsFixedDigits()} \u00B5s,'
        .colorize(
      AnsiModifier.green,
    );

    score = score +
        ' median: ${median.toStringAsFixedDigits()} \u00B1 '
        '${interQuartileRange.toStringAsFixedDigits()} \u00B5s'
            .colorize(AnsiModifier.blue);

    print('$description $score $blockHistogram');
  }
}
