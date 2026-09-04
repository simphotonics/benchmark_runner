import '../util/stats.dart';

/// Object aggreggating the score sample, score stats
/// and the duration it took to generate the
/// score sample.
class Score<T extends num>({
  /// Measured micro-benchmark duration
  required final Duration duration,

  /// The number of times the benchmarked function was executed to generate one
  /// benchmark sample entry.
  required final int innerIterations,

  /// Benchmark score sample in microseconds.
  /// Must have at least 2 entries. 
  required List<T> scoreSample,
}) {
  /// Scores (in microseconds) and score stats.
  final Stats<T> scoreStats = Stats(scoreSample);

  /// Time-scale when scores are divided by factor.
  late final ({String unit, int factor}) timeScale = switch (scoreStats.mean) {
    > 1000000 => (unit: 's', factor: 1000000),
    > 1000 => (unit: 'ms', factor: 1000),
    _ => (unit: 'us', factor: 1),
  };
}
