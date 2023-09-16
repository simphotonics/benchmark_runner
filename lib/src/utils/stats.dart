import 'dart:math' as math show sqrt, pow;

import 'package:lazy_memo/lazy_memo.dart';

/// A record holding sample stats and the sample generation runtime.
typedef RuntimeStats<T extends num> = ({
  Duration runtime,
  Stats<T> stats,
});

/// Provides access to basic statistical entities of a
/// numerical random sample.
class Stats<T extends num> {
  Stats(this.sample);

  /// Random data sample. Must not be empty.
  final List<T> sample;

  /// Sorted sample stored as lazy variable.
  late final _sortedSample = LazyList<T>(() => sample..sort());

  /// Returns the sorted random sample.
  List<T> get sortedSample => _sortedSample();

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

  late final _median = Lazy<double>(() {
    final q2 = _sortedSample().length ~/ 2;
    return (sample.length.isEven)
        ? (_sortedSample()[q2 - 1] + _sortedSample()[q2]) / 2
        : _sortedSample()[q2].toDouble();
  });

  /// Returns the sample median (second quartile).
  double get median => _median();

  late final _quartile1 = Lazy<double>(() {
    final length = _sortedSample().length;
    final halfLength = (length.isOdd) ? length ~/ 2 + 1 : length ~/ 2;
    final q1 = halfLength ~/ 2;
    return (halfLength.isEven)
        ? (_sortedSample()[q1 - 1] + _sortedSample()[q1]) / 2
        : _sortedSample()[q1].toDouble();
  });

  /// Returns the first quartile.
  double get quartile1 => _quartile1();

  late final _quartile3 = Lazy<double>(() {
    final length = _sortedSample().length;
    final halfLength = (length.isOdd) ? length ~/ 2 + 1 : length ~/ 2;
    final q3 = length ~/ 2 + halfLength ~/ 2;
    return (halfLength.isEven)
        ? (_sortedSample()[q3 - 1] + _sortedSample()[q3]) / 2
        : _sortedSample()[q3].toDouble();
  });

  /// Returns the third quartile.
  double get quartile3 => _quartile3();

  late final _iqr = Lazy<double>(
      () => _quartile3(updateCache: true) - _quartile1(updateCache: true));

  /// Returns the inter quartile range.
  double get iqr => _iqr();

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

  /// Removes outliers in place and returns the removed values. Lazy variables
  /// are marked stale and are recalculated when next accessed.
  /// The following values are considered outliers:
  /// * values smaller than `quartile1 - iqrScaling * iqr`
  /// * values larger than `quartile3 + iqrScaling * iqr`
  List<T> removeOutliers([double iqrScaling = 2.5]) {
    final outliers = <T>[];
    iqrScaling = iqrScaling.abs();
    final lowerFence = quartile1 - iqrScaling * iqr;
    final upperFence = quartile3 + iqrScaling * iqr;
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
    _iqr.updateCache();
  }
}
