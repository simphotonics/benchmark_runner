import '../util/stats.dart';

/// Object holding sample stats and the duration it took to generate the
/// score sample.
class Score<T extends num> {
  Score({
    required this.duration,
    required List<T> scoreSample,
    required List<int> innerLoopCounters,
  }) : scoreStats = Stats(scoreSample),
       innerLoopCounterStats = Stats(innerLoopCounters);

  /// Measured micro-benchmark duration
  final Duration duration;

  /// The number of times the benchmarked function was executed to generate a
  /// benchmark sample entry.
  final Stats<int> innerLoopCounterStats;

  /// Scores and score stats (in microseconds).
  final Stats<T> scoreStats;

  /// Time-scale when scores are divided by factor.
  late final ({String unit, int factor}) timeScale = switch (scoreStats.mean) {
    > 1000000 => (unit: 's', factor: 1000000),
    > 1000 => (unit: 'ms', factor: 1000),
    _ => (unit: 'us', factor: 1),
  };
}
