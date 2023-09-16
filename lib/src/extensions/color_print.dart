import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart' show ScoreEmitter;

import '../extensions/duration_formatter.dart';
import '../extensions/precision.dart';
import '../extensions/color_profile.dart';
import '../extensions/histogram.dart';
import '../utils/stats.dart';

const plusMinus = '\u00B1';
// const microSeconds = '\u00B5s';

/// Provides a method for emitting colorized benchmark scores.
extension StatsEmitter on ScoreEmitter {
  /// Writes a colorized benchmark score to stdout.
  void emitStats({
    required Duration runtime,
    required String description,
    required Stats stats,
  }) {
    final indent = '${runtime.mmssms}  '.clearStyle().length;

    final part1 = '${runtime.mmssms.style(ColorProfile.dim)} $description';

    final part2 =
        // mean +- standard deviation
        ' mean: ${stats.mean.toStringAsFixedDigits()} $plusMinus '
                    '${stats.stdDev.toStringAsFixedDigits()} us, '
                .style(ColorProfile.mean) +
            // median +- inter quartile range
            'median: ${stats.median.toStringAsFixedDigits()} $plusMinus '
                    '${stats.iqr.toStringAsFixedDigits()} us'
                .style(ColorProfile.median);

    final part3 = '${' ' * indent}${stats.blockHistogram()} '
        '${'sample size: '
            '${stats.sample.length.toString()}'.style(ColorProfile.dim)}';

    print(part1 + part2);
    print(part3);
    print('');
  }
}
