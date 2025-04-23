import '../util/stats.dart';

/// Object aggreggating the score sample, score stats
/// and the duration it took to generate the
/// score sample.
class Score<T extends num> {
  Score({
    required this.duration,
    required this.innerIterations,
    required List<T> scoreSample,
  }) : scoreStats = Stats(scoreSample);

  /// Measured micro-benchmark duration
  final Duration duration;

  /// The number of times the benchmarked function was executed to generate one
  /// benchmark sample entry.
  final int innerIterations;

  /// Scores (in microseconds) and score stats.
  final Stats<T> scoreStats;

  /// Time-scale when scores are divided by factor.
  late final ({String unit, int factor}) timeScale = switch (scoreStats.mean) {
    > 1000000 => (unit: 's', factor: 1000000),
    > 1000 => (unit: 'ms', factor: 1000),
    _ => (unit: 'us', factor: 1),
  };
}
