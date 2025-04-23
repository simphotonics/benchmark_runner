import 'dart:async';

import '../extension/benchmark_helper.dart';
import '../util/stats.dart';
import 'sample_size.dart';
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
    required this.run,
    this.setup = futureDoNothing,
    this.teardown = futureDoNothing,
  });

  // The benchmarked function.
  final AsyncFunction run;

  // Function executed prior to the benchmark runs.
  final AsyncFunction setup;

  // Function executed after the benchmark runs.
  final AsyncFunction teardown;

  /// Returns a sample of benchmark scores.
  /// The benchmark scores represent the run time in microseconds. The integer
  /// `innerIter` is larger than 1 if each score entry was averaged over
  /// `innerIter` runs.
  ///
  Future<({List<double> scores, int innerIterations})> sample({
    final Duration warmUpDuration = const Duration(milliseconds: 200),
    SampleSize? sampleSize,
  }) async {
    await setup();
    final sample = <int>[];
    final watch = Stopwatch();
    watch.prime();
    try {
      final scoreEstimate = await watch.estimateAsync(
        run,
        duration: warmUpDuration,
      );

      sampleSize ??= BenchmarkHelper.sampleSize(scoreEstimate.elapsedTicks);

      if (sampleSize.innerIterations > 1) {
        final durationAsTicks =
            sampleSize.innerIterations * scoreEstimate.elapsedTicks;
        for (var i = 0; i < sampleSize.length; i++) {
          // Averaging each score over approx. sampleSize.inner runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = await watch.measureAsync(run, durationAsTicks);
          sample.add(score);
        }
      } else {
        for (var i = 0; i < sampleSize.length; i++) {
          watch.reset();
          watch.start();
          await run();
          // These scores are not averaged.
          sample.add(watch.elapsedTicks);
        }
      }

      // Rescale to microseconds.
      // Note: frequency is expressed in Hz (ticks/second).
      return (
        scores:
            sample
                .map<double>(
                  (e) => e * (Duration.microsecondsPerSecond / watch.frequency),
                )
                .toList(),
        innerIterations: sampleSize.innerIterations,
      );
    } finally {
      await teardown();
    }
  }

  /// Returns an instance of [Score] holding the total benchmark duration
  /// and a [Stats] object created from the score sample.
  /// Note: The run time entries represent microseconds.
  Future<Score> score({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(microseconds: 200),
    SampleSize? sampleSize,
  }) async {
    final watch = Stopwatch()..start();
    final sample = await this.sample(
      warmUpDuration: warmUpDuration,
      sampleSize: sampleSize,
    );
    watch.stop();
    //stats.removeOutliers(10);
    return Score(
      duration: watch.elapsed,
      scoreSample: sample.scores,
      innerIterations: sample.innerIterations,
    );
  }
}
