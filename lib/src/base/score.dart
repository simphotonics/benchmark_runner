import '../util/stats.dart';

/// Object holding sample stats and the sample generation runtime.
class Score<T extends num> {
  Score(
      {required this.runtime, required List<T> sample, required this.innerIter})
      : stats = Stats(sample);

  /// Micro-benchmark duration
  final Duration runtime;

  /// Indicates if the a sample point was averaged over [iter] runs.
  final int innerIter;

  /// Scores and score stats (in microseconds).
  final Stats<T> stats;

  /// Time-scale when scores are divided by factor.
  late final ({String unit, int factor}) timeScale = switch (stats.mean) {
    > 1000000 => (unit: 's', factor: 1000000),
    > 1000 => (unit: 'ms', factor: 1000),
    _ => (unit: 'us', factor: 1)
  };
}
