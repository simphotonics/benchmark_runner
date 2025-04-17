import 'dart:async';

import '../collection/single_value_list.dart';
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
  Future<({List<double> scores, List<int> innerLoopCounters})> sample({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(milliseconds: 200),
    SampleSize? sampleSize,
  }) async {
    await _setup();
    final sample = <int>[];
    final innerLoopCounters = <int>[];
    final watch = Stopwatch();
    watch.prime();
    try {
      final scoreEstimate = await watch.estimateAsync(
        _run,
        duration: warmUpDuration,
        warmUpRuns: warmUpRuns,
      );

      sampleSize ??= BenchmarkHelper.sampleSize(scoreEstimate.elapsedTicks);

      if (sampleSize.innerIterations > 1) {
        final durationAsTicks =
            sampleSize.innerIterations * scoreEstimate.elapsedTicks;
        for (var i = 0; i < sampleSize.length; i++) {
          // Averaging each score over approx. sampleSize.inner runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = await watch.measureAsync(
            _run,
            durationAsTicks,
            warmUpRuns: warmUpRuns,
          );
          sample.add(score.elapsedTicks);
          innerLoopCounters.add(score.loopCounter);
        }
      } else {
        // Warmup
        for (var i = 0; i < warmUpRuns; i++) {
          await _run();
        }
        for (var i = 0; i < sampleSize.length; i++) {
          watch.reset();
          watch.start();
          await _run();
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
        innerLoopCounters:
            (sampleSize.innerIterations > 1)
                ? innerLoopCounters
                : SingleValueList(value: 1, length: sample.length),
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
    SampleSize? sampleSize,
  }) async {
    final watch = Stopwatch()..start();
    final sample = await this.sample(
      warmUpDuration: warmUpDuration,
      warmUpRuns: warmUpRuns,
      sampleSize: sampleSize,
    );
    watch.stop();
    //stats.removeOutliers(10);
    return Score(
      duration: watch.elapsed,
      scoreSample: sample.scores,
      innerLoopCounters: sample.innerLoopCounters,
    );
  }
}
