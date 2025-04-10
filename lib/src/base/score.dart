import '../util/stats.dart';

/// Object holding sample stats and the duration it took to generate the
/// score sample.
class Score<T extends num> {
  Score(
      {required this.duration,
      required List<T> sample,
      required this.innerIter})
      : stats = Stats(sample);

  /// Measured micro-benchmark duration
  final Duration duration;

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
