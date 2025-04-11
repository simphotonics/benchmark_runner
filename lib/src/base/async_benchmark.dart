import 'dart:async';
import 'dart:isolate';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../emitter/score_emitter.dart';
import '../extension/benchmark_helper.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import '../util/stats.dart';
import 'group.dart';
import 'score.dart';

typedef AsyncFunction = Future<void> Function();

/// An asynchronous function that does nothing.
Future<void> futureDoNothing() async {}

/// A class used to benchmark asynchronous functions.
/// The benchmarked function is provided as a constructor argument.
class AsyncBenchmark {
  /// Constructs an [AsyncBenchmark] object using the following arguments:

  /// * [run]: the asynchronous function to be benchmarked,
  /// * [setup]: an asynchronous function that is executed
  ///   once before running the benchmark,
  /// * [teardown]: an asynchronous function that is executed once after
  ///   the benchmark has completed.
  const AsyncBenchmark({
    required AsyncFunction run,
    AsyncFunction setup = futureDoNothing,
    AsyncFunction teardown = futureDoNothing,
  })  : _run = run,
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
  Future<({List<double> scores, int innerIter})> sample() async {
    await _setup();
    int warmupRuns = 3;
    final sample = <int>[];
    final innerIters = <int>[];
    final overhead = <int>[];
    final watch = Stopwatch();
    var innerIterMean = 1;

    try {
      // Warmup (Default: For 200 ms with 3 pre-runs).
      final scoreEstimate = await watch.warmupAsync(_run);
      final sampleSize = BenchmarkHelper.sampleSize(
        scoreEstimate.ticks,
      );

      if (sampleSize.inner > 1) {
        final durationAsTicks = sampleSize.inner * scoreEstimate.ticks;
        for (var i = 0; i < sampleSize.outer + warmupRuns; i++) {
          // Averaging each score over at least 25 runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = await watch.measureAsync(
            _run,
            durationAsTicks,
          );
          sample.add(score.ticks);
          innerIters.add(score.iter);
        }
        innerIterMean = innerIters.reduce((sum, element) => sum + element) ~/
            innerIters.length;
      } else {
        for (var i = 0; i < sampleSize.outer + warmupRuns; i++) {
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
        scores: sample
            .map<double>(
              (e) => e * (1000000 / watch.frequency),
            )
            .skip(warmupRuns)
            .toList(),
        innerIter: innerIterMean
      );
    } finally {
      await _teardown();
    }
  }

  /// Returns an instance of [Score] holding the total benchmark duration
  /// and a [Stats] object created from the score samples.
  /// Note: The run time entries represent microseconds.
  Future<Score> score() async {
    final watch = Stopwatch()..start();
    final sample = await this.sample();
    watch.stop();
    //stats.removeOutliers(10);
    return Score(
      duration: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }
}

/// Defines an asynchronous benchmark.
/// * [run]: the benchmarked function,
/// * [setup]: executed once before the benchmark,
/// * [teardown]: executed once after the benchmark runs.
/// * [runInIsolate]: Set to `true` to run benchmark in a
///    separate isolate.
/// * [scoreEmitter]: A custom score emitter.
/// * [report]: A callback that calls the custom emitter.
Future<void> asyncBenchmark(
  String description,
  Future<void> Function() run, {
  Future<void> Function() setup = futureDoNothing,
  Future<void> Function() teardown = futureDoNothing,
  ScoreEmitter scoreEmitter = const StatsEmitter(),
  bool runInIsolate = true,
}) async {
  final group = Zone.current[#group] as Group?;
  final groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';

  final instance = AsyncBenchmark(
    run: run,
    setup: setup,
    teardown: teardown,
  );

  description = groupDescription +
      (hourGlass + description).style(ColorProfile.asyncBenchmark);

  final watch = Stopwatch()..start();

  await runZonedGuarded(
    () async {
      try {
        if (runInIsolate) {
          await Isolate.run(() async => scoreEmitter.emit(
              description: description, score: await instance.score()));
        } else {
          scoreEmitter.emit(
              description: description, score: await instance.score());
        }
        addSuccessMark();
      } catch (error, stack) {
        reportError(
          error,
          stack,
          description: description,
          duration: watch.elapsed,
          errorMark: benchmarkError,
        );
      }
    },
    ((error, stack) {
      // Safequard: Errors should be caught in the try block above.
      reportError(
        error,
        stack,
        description: description,
        duration: watch.elapsed,
        errorMark: benchmarkError,
      );
    }),
  );
}
