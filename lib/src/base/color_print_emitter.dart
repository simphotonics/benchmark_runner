import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import '../extension/histogram.dart';
import '../extension/precision.dart';
import '../extension/duration_formatter.dart';
import '../extension/color_profile.dart';
import 'score.dart';

const plusMinus = '\u00B1';

class ColorPrintEmitter extends PrintEmitter {
  const ColorPrintEmitter();

  /// Prints a colorized benchmark score.
  @override
  void emit(String testName, double value) {
    print('$testName(RunTime): ${'$value us.'.style(ColorProfile.mean)}\n');
  }

  /// Prints a colorized benchmark score report.
  void emitStats({
    required String description,
    required Score score,
  }) {
    //final indentCharacters = score.runtime.msus.length;
    final indent = '  ';
    final part1 = '${score.runtime.msus.style(ColorProfile.dim)} $description';

    final mean = score.stats.mean / score.timeScale.factor;
    final stdDev = score.stats.stdDev / score.timeScale.factor;
    final median = score.stats.median / score.timeScale.factor;
    final iqr = score.stats.iqr / score.timeScale.factor;
    final unit = score.timeScale.unit;

    final part2 = '${indent}mean: ${mean.toStringAsFixedDigits()} $plusMinus '
                '${stdDev.toStringAsFixedDigits()} $unit, '
            .style(ColorProfile.mean) +
        'median: ${median.toStringAsFixedDigits()} $plusMinus '
                '${iqr.toStringAsFixedDigits()} $unit'
            .style(ColorProfile.median);

    final part3 = '$indent${score.stats.blockHistogram()} '
        'sample size: ${score.stats.sortedSample.length}';
    final part4 =
        score.innerIter > 1 ? ' (averaged over ${score.innerIter} runs)' : '';

    // final rulerLength = part1.clearStyle().length;
    // final ruler = (' ' * (rulerLength~/4)).style(ColorProfile.dim);
    // print(ruler);
    print(part1);
    print(part2);
    print(part3 + part4.style(ColorProfile.dim));
    print('');
  }
}
