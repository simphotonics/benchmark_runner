import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../emitter/score_emitter.dart';
import '../extension/benchmark_helper.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import '../util/stats.dart';
import 'group.dart';
import 'score.dart';

/// A synchronous function that does nothing.
void doNothing() {}

/// A class used to benchmark synchronous functions.
/// The benchmarked function is provided as a constructor argument.
class Benchmark {
  /// Constructs a [Benchmark] object using the following arguments:
  /// * [description]: a [String] describing the benchmark,
  /// * [run]: the synchronous function to be benchmarked,
  /// * [setup]: a function that is executed once before running the benchmark,
  /// * [teardown]: a function that is executed once after the benchmark has
  /// completed.
  const Benchmark({
    required void Function() run,
    void Function() setup = doNothing,
    void Function() teardown = doNothing,
  })  : _run = run,
        _setup = setup,
        _teardown = teardown;

  final void Function() _run;
  final void Function() _setup;
  final void Function() _teardown;

  // The benchmark code.
  void run() => _run();

  /// Not measured setup code executed prior to the benchmark runs.
  void setup() => _setup();

  /// Not measures teardown code executed after the benchmark runs.
  void teardown() => _teardown();

  /// To opt into the reporting the time per run() instead of per 10 run() calls.
  void exercise() => _run();

  /// Generates a sample of benchmark scores.
  /// The benchmark scores represent the run time in microseconds. The integer
  /// `innerIter` is larger than 1 if each score entry was averaged over
  /// `innerIter` runs.
  ({List<double> scores, int innerIter}) sample() {
    _setup();
    final warmupRuns = 3;
    final sample = <int>[];
    final innerIters = <int>[];
    final overhead = <int>[];
    final watch = Stopwatch();
    var innerIterMean = 1;
    try {
      // Warmup (Default: For 200 ms with 3 pre-runs).
      final scoreEstimate = watch.warmup(_run);
      final sampleSize = BenchmarkHelper.sampleSize(
        scoreEstimate.ticks,
      );

      if (sampleSize.inner > 1) {
        final durationAsTicks = sampleSize.inner * scoreEstimate.ticks;
        for (var i = 0; i < sampleSize.outer + warmupRuns; i++) {
          // Averaging each score over at least 25 runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = watch.measure(
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
          _run();
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
      teardown();
    }
  }

  /// Returns a [Score] object holding the total benchmark duration
  /// and a [Stats] object created from the score samples.
  /// Note: The run time entries represent microseconds. 
  Score score() {
    final watch = Stopwatch()..start();
    final sample = this.sample();
    return Score(
      duration: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }
}

/// Defines a benchmark for the synchronous function [run]. The benchmark
/// scores are emitted to stdout.
/// * `run`: the benchmarked function,
/// * `setup`: exectued once before the benchmark,
/// * `teardown`: executed once after the benchmark runs.
/// * `report`: report to emit score as provided by benchmark_harness.
/// * `emitter`: An emitter for generating a custom benchmark report.
/// * `report`: A callback that can be used to call an emitter method.
void benchmark(
  String description,
  void Function() run, {
  void Function() setup = doNothing,
  void Function() teardown = doNothing,
  ScoreEmitter scoreEmitter = const StatsEmitter(),
}) {
  final group = Zone.current[#group] as Group?;
  var groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';
  final instance = Benchmark(
    run: run,
    setup: setup,
    teardown: teardown,
  );
  final watch = Stopwatch()..start();

  description = groupDescription + description.style(ColorProfile.benchmark);

  try {
    if (run is Future<void> Function()) {
      throw UnsupportedError('The callback "run" must not be marked async!');
    }
  } catch (error, stack) {
    reportError(
      error,
      stack,
      description: description,
      duration: watch.elapsed,
      errorMark: benchmarkError,
    );
    return;
  }

  runZonedGuarded(
    () {
      try {
        scoreEmitter.emit(description: description, score: instance.score());
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
