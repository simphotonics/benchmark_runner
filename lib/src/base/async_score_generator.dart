import 'dart:async';

import '../extension/benchmark_helper.dart';
import '../util/stats.dart';
import 'score.dart';

typedef AsyncFunction = Future<void> Function();

/// An asynchronous function that does nothing.
Future<void> futureDoNothing() async {}

/// A class used to benchmark asynchronous functions.
/// The benchmarked function is provided as a constructor argument.
class AsyncScoreGenerator {
  /// Constructs an [AsyncScoreGenerator] object using the following arguments:

  /// * [run]: the asynchronous function to be benchmarked,
  /// * [setup]: an asynchronous function that is executed
  ///   once before running the benchmark,
  /// * [teardown]: an asynchronous function that is executed once after
  ///   the benchmark has completed.
  const AsyncScoreGenerator({
    required AsyncFunction run,
    AsyncFunction setup = futureDoNothing,
    AsyncFunction teardown = futureDoNothing,
  }) : _run = run,
       _setup = setup,
       _teardown = teardown;

  final AsyncFunction _run;
  final AsyncFunction _setup;
  final AsyncFunction _teardown;

  // The benchmark code.
  Future<void> run() => _run();

  // Not measured setup code executed prior to the benchmark runs.
  Future<void> setup() => _setup();

  // Not measures teardown code executed after the benchmark runs.
  Future<void> teardown() => _teardown();

  // To opt into the reporting the time per run() instead of per 10 run() calls.
  Future<void> exercise() => run();

  /// Returns a sample of benchmark scores.
  /// The benchmark scores represent the run time in microseconds. The integer
  /// `innerIter` is larger than 1 if each score entry was averaged over
  /// `innerIter` runs.
  ///
  Future<({List<double> scores, int innerIter})> sample({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(milliseconds: 200),
  }) async {
    await _setup();
    final sample = <int>[];
    final innerIters = <int>[];
    final overhead = <int>[];
    final watch = Stopwatch();
    int innerIterMean = 1;

    try {
      // Warmup (Default: For 200 ms with 3 pre-runs).
      final scoreEstimate = await watch.warmUpAsync(
        _run,
        duration: warmUpDuration,
        warmUpRuns: warmUpRuns,
      );
      final sampleSize = BenchmarkHelper.sampleSize(scoreEstimate.ticks);

      if (sampleSize.inner > 1) {
        final durationAsTicks = sampleSize.inner * scoreEstimate.ticks;
        for (var i = 0; i < sampleSize.outer + warmUpRuns; i++) {
          // Averaging each score over approx. sampleSize.inner runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = await watch.measureAsync(_run, durationAsTicks);
          sample.add(score.ticks);
          innerIters.add(score.iter);
        }
        innerIterMean =
            innerIters.reduce((sum, element) => sum + element) ~/
            innerIters.length;
      } else {
        for (var i = 0; i < sampleSize.outer + warmUpRuns; i++) {
          watch.reset();
          await _run();
          // These scores are not averaged.
          sample.add(watch.elapsedTicks);
          watch.reset();
          overhead.add(watch.elapsedTicks);
        }
        for (var i = 0; i < sampleSize.outer; i++) {
          // Removing overhead of calling elapsedTicks and adding list element.
          // overhead scores are of the order of 0.1 us.
          sample[i] = sample[i] - overhead[i];
        }
      }

      // Rescale to microseconds.
      // Note: frequency is expressed in Hz (ticks/second).
      return (
        scores:
            sample
                .map<double>((e) => e * (1000000 / watch.frequency))
                .skip(warmUpRuns)
                .toList(),
        innerIter: innerIterMean,
      );
    } finally {
      await _teardown();
    }
  }

  /// Returns an instance of [Score] holding the total benchmark duration
  /// and a [Stats] object created from the score sample.
  /// Note: The run time entries represent microseconds.
  Future<Score> score({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(microseconds: 200),
  }) async {
    final watch = Stopwatch()..start();
    final sample = await this.sample(
      warmUpDuration: warmUpDuration,
      warmUpRuns: warmUpRuns,
    );
    watch.stop();
    //stats.removeOutliers(10);
    return Score(
      duration: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }
}
