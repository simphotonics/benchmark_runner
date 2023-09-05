import 'dart:math' as math show min, max, sqrt, pow;

import 'package:benchmark_runner/src/utils/ansi_modifier.dart';
import 'package:lazy_memo/lazy_memo.dart';

import '../extensions/root.dart';

/// Provides access to basic statistical entities of a
/// numerical random sample.
class Stats<T extends num> {
  Stats(this.sample);

  /// Numerical data sample. Must not be empty.
  final List<T> sample;

  /// Sorted sample stored as lazy variable.
  late final _sortedSample = LazyList<T>(() => sample..sort());

  late final _sum = Lazy<T>(() {
    if (sample.isEmpty) {
      throw RangeError.index(
        1,
        this,
        'sum',
        'List must have at least 1 element.',
      );
    }
    return sample.reduce((value, current) => (value + current) as T);
  });

  /// Sample mean.
  late final _mean = Lazy<double>(() {
    if (sample.isEmpty) {
      throw RangeError.index(
        1,
        this,
        'mean',
        'List must have at least 1 element.',
      );
    }
    return _sum() / sample.length;
  });

  /// Corrected sample standard deviation.
  late final Lazy<double> _stdDev = Lazy<double>(() {
    if (sample.length < 2) {
      throw RangeError.index(
        2,
        this,
        'stdDev',
        'List must have at least 2 elements.',
      );
    }
    final mean = _mean();
    double sum = 0.0;
    final it = sample.iterator;
    while (it.moveNext()) {
      sum += math.pow(mean - it.current, 2);
    }
    return math.sqrt(sum / (sample.length - 1));
  });

  /// Returns the smallest sample value.
  late final _min = Lazy<T>(() => _sortedSample().first);

  /// Returns the smallest sample value.
  T get min => _min();

  /// Returns the largest sample value.
  late final _max = Lazy<T>(() => _sortedSample().last);

  /// Return the largest sample value.
  T get max => _max();

  /// Returns the sum of the sample values.
  T get sum => _sum();

  late final _quartile1 = Lazy<double>(() {
    final length = _sortedSample().length;
    final halfLength = (length.isOdd) ? length ~/ 2 + 1 : length ~/ 2;
    final q1 = halfLength ~/ 2;
    return (halfLength.isEven)
        ? (_sortedSample()[q1 - 1] + _sortedSample()[q1]) / 2
        : _sortedSample()[q1].toDouble();
  });

  /// Returns the first quartile.
  num get quartile1 => _quartile1();

  late final _median = Lazy<double>(() {
    final q2 = _sortedSample().length ~/ 2;
    return (sample.length.isEven)
        ? (_sortedSample()[q2 - 1] + _sortedSample()[q2]) / 2
        : _sortedSample()[q2].toDouble();
  });

  /// Returns the sample median (second quartile).
  double get median => _median();

  late final _quartile3 = Lazy<double>(() {
    final length = _sortedSample().length;
    final halfLength = (length.isOdd) ? length ~/ 2 + 1 : length ~/ 2;
    final q3 = length ~/ 2 + halfLength ~/ 2;
    return (halfLength.isEven)
        ? (_sortedSample()[q3 - 1] + _sortedSample()[q3]) / 2
        : _sortedSample()[q3].toDouble();
  });

  /// Returns the third quartile.
  num get quartile3 => _quartile3();

  List<T> get sortedSample => _sortedSample();

  /// Returns the sample mean.
  ///
  /// Throws an exception of type `ExceptionOf<SampleStats>` if the
  /// sample is empty.
  double get mean => _mean();

  /// Returns the corrected sample standard deviation.
  /// * The sample must contain at least 2 entries.
  /// * The normalization constant for the corrected standard deviation is
  ///   `sample.length - 1`.
  double get stdDev => _stdDev();

  /// Returns the interval size
  /// taking into account the inter-quartile range and the sample size.
  /// (Freedman-Diaconis rule)
  double get optimalIntervalSize =>
      2 * (quartile3 - quartile1) / (_sortedSample().length.root(3));

  /// Returns the optimal number of intervals. The interval size
  /// is estimated using the Freedman-Diaconis rule.
  int get optimalIntervalNumber =>
      math.max((max - min).abs() ~/ optimalIntervalSize, 3);

  /// Returns an object of type `List<List<num>>` containing a sample histogram.
  /// * The first list contains the interval mid points. The left most interval
  ///   has boundaries: `min - h/2 ... min + h/2. The right most interval has
  ///   boundaries: `max - h/2 ... max + h/2`.
  ///
  /// * The second list represent a count of how many sample values fall into
  ///   each interval. If `normalize == true`, the histogram count
  ///   will be normalized using the factor: `sampleSize * intervalSize`, such
  ///   that the total area of the histogram bar is equal to one.
  ///   This is useful when comparing the histogram to a
  ///   probability distribution.
  ({List<double> intervalMidPoints, List<double> counts}) histogram({
    bool normalize = true,
    int intervals = 0,
  }) {
    final sampleSize = _sortedSample().length;

    intervals = intervals < 2 ? optimalIntervalNumber : intervals;

    /// Make sure we have at least 2 intervals
    while (intervals < 2) {
      intervals++;
    }

    final intervalSize = (max - min) / intervals;
    final gridPoints = intervals + 1;

    final xValues = List<double>.generate(
      gridPoints,
      (i) => min + i * intervalSize,
      growable: false,
    );
    final yValues = List<double>.filled(gridPoints, 0.0);

    final leftBorder = min - intervalSize / 2;

    // Generating histogram
    for (final current in _sortedSample()) {
      // Calculate interval index of current.
      final index = (current - leftBorder) ~/ intervalSize;
      ++yValues[index];
    }

    if (normalize) {
      for (var i = 0; i < gridPoints; ++i) {
        yValues[i] = yValues[i] / (sampleSize * intervalSize);
      }
    }
    return (intervalMidPoints: xValues, counts: yValues);
  }

  static final blocks = switch (AnsiModifier.colorOutput) {
    ColorOutput.on => [
        '_'.colorize(AnsiModifier.grey),
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
    ColorOutput.off => [
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
  String blockHistogram({bool normalize = true, int intervals = 0}) {
    intervals = intervals < 2 ? optimalIntervalNumber : intervals;

    /// Make sure we have at least 2 intervals
    while (intervals < 2) {
      intervals++;
    }

    final intervalSize = (max - min) / intervals;
    final gridPoints = intervals + 1;
    final yValues = List<double>.filled(gridPoints, 0);

    final leftBorder = min - intervalSize / 2;

    // Generating histogram
    for (final current in _sortedSample()) {
      // Calculate interval index of current.
      final index = (current - leftBorder) ~/ intervalSize;
      yValues[index]++;
    }
    final sampleSize = sample.length;
    for (var i = 0; i < gridPoints; ++i) {
      yValues[i] = yValues[i] / (sampleSize * intervalSize);
    }

    final yMax = yValues.reduce((value, element) => math.max(value, element));
    final deltaY = yMax / (blocks.length - 1);
    final result = List<String>.filled(gridPoints, ' ');
    final blockCount = blocks.length;
    // Assign a block string to each value.
    for (var i = 0; i < gridPoints; i++) {
      final j = math.min((yValues[i] / deltaY).ceil(), blockCount);
      result[i] = blocks[j];
    }
    // Colorize block containing the mean value.
    final indexOfMean = (mean - leftBorder) ~/ intervalSize;
    result[indexOfMean] = result[indexOfMean].colorize(AnsiModifier.green);

    // Colorize block containing the median value.
    final indexOfMedian = (median - leftBorder) ~/ intervalSize;
    if (indexOfMedian == indexOfMean) {
      result[indexOfMedian] = result[indexOfMedian].colorize(AnsiModifier.cyan);
    } else {
      result[indexOfMedian] = result[indexOfMedian].colorize(AnsiModifier.blue);
    }
    // Make histogram more compact
    final length = result.length;
    if (length > 70) {
      // ignore: prefer_interpolation_to_compose_strings
      return result.take(20).join() +
          ' ${length - 40}  ' +
          result.skip(length - 20).join();
    } else {
      return result.join();
    }
  }

  List<T> removeOutliers([num factor = 2.5]) {
    final outliers = <T>[];
    factor = factor.abs();
    final iqr = quartile3 - quartile1;
    final lowerFence = quartile1 - factor * iqr;
    final upperFence = quartile3 + factor * iqr;
    sample.removeWhere((current) {
      if (current < lowerFence || current > upperFence) {
        outliers.add(current);
        return true;
      } else {
        return false;
      }
    });
    update();
    return outliers;
  }

  /// Requests an update of the cached variables:
  /// * `sortedSample`,
  /// * `mean`,
  /// * `median`,
  /// * `stdDev`,
  /// * `min`,
  /// * `max`,
  /// * `quartile1`,
  /// * `quartile2`,
  void update() {
    _sortedSample.updateCache();
    _mean.updateCache();
    _median.updateCache();
    _stdDev.updateCache();
    _min.updateCache();
    _max.updateCache();
    _quartile1.updateCache();
    _quartile3.updateCache();
  }
}
