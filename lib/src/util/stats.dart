import 'dart:math' as math show sqrt, pow;

import 'package:lazy_memo/lazy_memo.dart';

/// Provides access to basic statistical entities of a
/// numerical random sample.
class Stats<T extends num>(List<T> sample) {
  /// Original random data sample. Must not be empty.
  final List<T> _sample = List.of(sample);

  /// Returns a copy of the random sample
  List<T> get sample => List.of(_sample);

  /// Sorted sample stored as lazy variable.
  late final LazyList<T> _sortedSample = LazyList<T>(() => sample..sort());

  /// Returns the sorted random sample.
  List<T> get sortedSample => _sortedSample();

  late final _sum = Lazy<T>(() {
    if (_sample.isEmpty) {
      throw RangeError.index(
        1,
        this,
        'sum',
        'List must have at least 1 element.',
      );
    }
    return _sample.reduce((value, current) => (value + current) as T);
  });

  /// Sample mean.
  late final _mean = Lazy<double>(() {
    if (_sample.isEmpty) {
      throw RangeError.index(
        1,
        _sample,
        'mean',
        'List must have at least 1 element.',
      );
    }
    return _sum() / _sample.length;
  });

  /// Corrected sample standard deviation.
  late final Lazy<double> _stdDev = Lazy<double>(() {
    if (_sample.length < 2) {
      throw RangeError.index(
        2,
        _sample,
        'stdDev',
        'List must have at least 2 elements.',
      );
    }
    final mean = _mean();
    double sum = 0.0;
    final it = _sample.iterator;
    while (it.moveNext()) {
      sum += math.pow(mean - it.current, 2);
    }
    return math.sqrt(sum / (_sample.length - 1));
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
    final midIndex = sample.length ~/ 2;
    if (sample.length.isEven) {
      return (_sortedSample()[midIndex - 1] + _sortedSample()[midIndex]) / 2;
    } else {
      return _sortedSample()[midIndex].toDouble();
    }
  });

  /// Returns the sample median (second quartile).
  double get median => _median();

  late final _quartile1 = Lazy<double>(() {
    final halfLength = sample.length ~/ 2;
    final quaterIndex = halfLength ~/ 2;
    if (halfLength.isEven) {
      return (_sortedSample()[quaterIndex - 1] + _sortedSample()[quaterIndex]) /
          2;
    } else {
      return _sortedSample()[quaterIndex].toDouble();
    }
  });

  /// Returns the first quartile.
  double get quartile1 => _quartile1();

  late final _quartile3 = Lazy<double>(() {
    final halfLength = sample.length ~/ 2;
    final quaterIndex = halfLength ~/ 2;

    if (halfLength.isEven) {
      return (_sortedSample()[halfLength + quaterIndex - 1] +
              _sortedSample()[halfLength + quaterIndex]) /
          2;
    } else {
      return _sortedSample()[halfLength + 1 + quaterIndex].toDouble();
    }
  });

  /// Returns the third quartile.
  double get quartile3 => _quartile3();

  late final _iqr = Lazy<double>(
    () => _quartile3(updateCache: true) - _quartile1(updateCache: true),
  );

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
    final lowerFence = quartile1 - iqrScaling.abs() * iqr;
    final upperFence = quartile3 + iqrScaling.abs() * iqr;
    _sample.removeWhere((current) {
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

  @override
  String toString() {
    final b = StringBuffer('sample: \n');
    b.writeln('  length:    ${sample.length}');
    b.writeln('  min:       $min');
    b.writeln('  max:       $max');
    b.writeln('  iqr:       $iqr');
    b.writeln('  stdDev:    $stdDev');
    b.writeln('  mean:      $mean');
    b.writeln('  median:    $median');
    b.writeln('  quartile1: $quartile1');
    b.writeln('  quartile3: $quartile3');
    b.writeln('  sum:       $sum');
    return b.toString();
  }
}
