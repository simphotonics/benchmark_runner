import '../util/stats.dart';
import 'root.dart';
import 'color_profile.dart';
import 'dart:math' as math show min, max;
import 'package:ansi_modifier/ansi_modifier.dart';

extension Histogram on Stats {
  /// Returns the interval size
  /// taking into account the inter-quartile range and the sample size.
  /// (Freedman-Diaconis rule)
  double get intervalSizeFreedman => 2 * iqr / (sortedSample.length.root(3));

  /// Returns the optimal number of intervals. The interval size
  /// is estimated using the Freedman-Diaconis rule.
  int get intervalNumberFreedman =>
      iqr == 0 ? 3 : math.max((max - min).abs() ~/ intervalSizeFreedman, 3);

  /// Returns a map representing a sample histogram.
  /// * keys: The map keys correspond to the histogram interval mid-points.
  /// * values: The map values represent a count of how many
  ///   sample values fall into to the corresponding interval:
  ///  `midPoint - h/2, ..., midPoint + h/2`, where `h` is the interval size.
  /// * If `normalize == true`, the histogram count
  ///   will be normalized using the factor: `sampleSize * h`, such
  ///   that the total area of the histogram bars is equal to one.
  ///   This is useful when comparing the histogram to a
  ///   probability distribution.
  /// * intervalNumber: To specify the number of intervals provide a number > 2.
  ///   Otherwise the interval number is calculated using the Freedman-Diaconis
  ///   rule.
  Map<double, double> histogram({
    bool normalize = false,
    int intervalNumber = -1,
  }) {
    final sampleSize = sortedSample.length;
    intervalNumber =
        intervalNumber < 3 ? intervalNumberFreedman : intervalNumber;

    final intervalSize = (max - min) / intervalNumber;
    final gridPoints = intervalNumber + 1;

    final midPoints = List<double>.generate(
      gridPoints,
      (i) => min + i * intervalSize,
      growable: false,
    );
    final counts = List<double>.filled(gridPoints, 0.0);

    final leftBorder = min - intervalSize / 2;

    // Generating histogram
    for (final current in sortedSample) {
      // Calculate interval index of current.
      final index = (current - leftBorder) ~/ intervalSize;
      ++counts[index];
    }

    if (normalize) {
      for (var i = 0; i < gridPoints; ++i) {
        counts[i] = counts[i] / (sampleSize * intervalSize);
      }
    }
    return Map<double, double>.fromIterables(midPoints, counts);
  }

  static final blocks = switch (Ansi.status) {
    AnsiOutput.enabled => [
      '_'.style(ColorProfile.dim),
      '_',
      // '\u2581'.colorize(AnsiModifier.grey),
      '\u2581',
      // '\u2582'.colorize(AnsiModifier.grey),
      '\u2582',
      '\u2583',
      '\u2584',
      '\u2585',
      '\u2586',
      '\u2587',
      '\u2588',
      '\u2589',
    ],
    AnsiOutput.disabled => [
      '_',
      '\u2581',
      '\u2582',
      '\u2583',
      '\u2584',
      '\u2585',
      '\u2586',
      '\u2587',
      '\u2588',
      '\u2589',
    ],
  };

  /// Returns a block histogram in the form of a [String].
  /// * The single block containing the *mean and median* is colored cyan.
  /// * To disable color output set:
  /// `AnsiModifier.colorOutput = ColoOutput.off;`
  /// Sample output (with color output disabled):
  ///
  /// ▉
  String _singleBlockHistogram() =>
      '${blocks.first}'
      '${blocks.last.style(ColorProfile.meanMedianHistogramBlock)}'
      '${blocks.first}';

  /// Returns a block histogram in the form of a [String].
  /// * The block containing the *mean* value is colored green.
  /// * The block containing the *median* is colored blue.
  /// * The block containing the *mean and median* is colored cyan.
  /// * If the sample range is high resulting in a large number of
  ///   histogram intervals only the first 20 and last 20 intervals
  ///   are displayed and the
  ///   number of skipped intervals is shown.
  /// * To disable color output set:
  /// `AnsiModifier.colorOutput = ColoOutput.off;`
  ///
  /// Usage:
  /// ```
  /// final stats = Stats(sample);
  /// print(stats.blockHistogram);
  /// ```
  /// Sample output (with color output disabled):
  ///
  /// ▉▂__________________ 177  ____________________
  ///
  ///
  String blockHistogram({bool normalize = false, int intervalNumber = 0}) {
    intervalNumber =
        intervalNumber < 2 ? intervalNumberFreedman : intervalNumber;

    /// Make sure we have at least 2 intervals
    while (intervalNumber < 2) {
      intervalNumber++;
    }

    final intervalSize = (max - min) / intervalNumber;

    if (intervalSize == 0.0) {
      return _singleBlockHistogram();
    }

    final gridPoints = intervalNumber + 1;
    final counts = List<double>.filled(gridPoints, 0);
    final leftBorder = min - intervalSize / 2;

    // Generating histogram
    for (final current in sortedSample) {
      // Calculate interval index of current.
      final index = (current - leftBorder) ~/ intervalSize;
      counts[index]++;
    }
    final sampleSize = sortedSample.length;
    for (var i = 0; i < gridPoints; ++i) {
      counts[i] = counts[i] / (sampleSize * intervalSize);
    }

    final countsMax = counts.reduce(
      (value, element) => math.max(value, element),
    );
    final deltaCounts = countsMax / (blocks.length - 1);
    final result = List<String>.filled(gridPoints, ' ');
    final blockCount = blocks.length;
    // Assign a block string to each value.
    for (var i = 0; i < gridPoints; i++) {
      final j = math.min((counts[i] / deltaCounts).ceil(), blockCount);
      result[i] = blocks[j];
    }
    final length = result.length;

    final indexOfMean = (mean - leftBorder) ~/ intervalSize;

    final indexOfMedian = (median - leftBorder) ~/ intervalSize;

    if (indexOfMedian == indexOfMean) {
      // Colorize block containing mean and median
      result[indexOfMedian] = result[indexOfMedian].style(
        ColorProfile.meanMedianHistogramBlock,
      );
    } else {
      // Colorize block containing the median value.
      result[indexOfMedian] = result[indexOfMedian].style(
        ColorProfile.meanMedianHistogramBlock,
      );
      // Colorize block containing the mean value.
      result[indexOfMean] = result[indexOfMean].style(
        ColorProfile.meanHistogramBlock,
      );
    }

    /// Avoid situations where iqr = 0
    final iqrStandIn = iqr == 0.0 ? 20 * intervalSize : iqr;

    if (length > 40) {
      var indexLeft = (quartile1 - 3 * iqrStandIn - leftBorder) ~/ intervalSize;
      indexLeft = indexLeft < 0 ? 0 : indexLeft;

      var indexRight =
          (quartile3 + 5 * iqrStandIn - leftBorder) ~/ intervalSize;
      indexRight = indexRight > length - 1 ? length - 1 : indexRight;
      final rightBlocks = 5;
      final skippedRight = length - rightBlocks - indexRight;

      // Make histogram more compact
      return '${result.skip(indexLeft).take(indexRight - indexLeft).join()}  '
          '$skippedRight  '
          '${result.skip(length - rightBlocks).take(rightBlocks).join()}';
    } else {
      return result.join();
    }
  }
}
