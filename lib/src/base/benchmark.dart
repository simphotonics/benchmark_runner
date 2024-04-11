import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart' show BenchmarkBase;

import '../extensions/benchmark_helper.dart';
import '../extensions/color_profile.dart';
import '../extensions/duration_formatter.dart';
import '../extensions/string_utils.dart';
import '../utils/stats.dart';
import 'color_print_emitter.dart';
import 'group.dart';
import 'score.dart';

/// A synchronous function that does nothing.
void doNothing() {}

/// A class used to benchmark synchronous functions.
/// The benchmarked function is provided as a constructor argument.
class Benchmark extends BenchmarkBase {
  /// Constructs a [Benchmark] object using the following arguments:
  /// * [description]: a [String] describing the benchmark,
  /// * [run]: the synchronous function to be benchmarked,
  /// * [setup]: a function that is executed once before running the benchmark,
  /// * [teardown]: a function that is executed once after the benchmark has
  /// completed.
  const Benchmark({
    required String description,
    required void Function() run,
    void Function()? setup,
    void Function()? teardown,
    ColorPrintEmitter emitter = const ColorPrintEmitter(),
  })  : _run = run,
        _setup = setup ?? doNothing,
        _teardown = teardown ?? doNothing,
        super(description, emitter: emitter);

  final void Function() _run;
  final void Function() _setup;
  final void Function() _teardown;

  // The benchmark code.
  @override
  void run() => _run();

  /// Not measured setup code executed prior to the benchmark runs.
  @override
  void setup() => _setup();

  /// Not measures teardown code executed after the benchmark runs.
  @override
  void teardown() => _teardown();

  /// To opt into the reporting the time per run() instead of per 10 run() calls.
  @override
  void exercise() => _run();

  /// Returns the benchmark description (corresponds to the getter name).
  String get description => name;

  ({List<double> scores, int innerIter}) sample() {
    _setup();
    final warmupRuns = 3;
    final sample = <int>[];
    final innerIters = <int>[];
    final overhead = <int>[];
    final watch = Stopwatch();
    var innerIterMean = 1;
    try {
      // Warmup for at least 100ms.
      final scoreEstimate = (watch.measure(
        _run,
        BenchmarkHelper.millisecondsToTicks(200),
      ));
      final sampleSize = BenchmarkHelper.sampleSize(scoreEstimate.ticks);

      if (sampleSize.inner > 0) {
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
  Score score() {
    final watch = Stopwatch()..start();
    final sample = this.sample();
    return Score(
      runtime: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }

  /// Runs the method [sample] and emits the benchmark score statistics.
  void reportStats() {
    //stats.removeOutliers(10);
    (emitter as ColorPrintEmitter).emitStats(
      description: description,
      score: score(),
    );
  }

  /// Runs the method [measure] and emits the benchmark score.
  @override
  void report() {
    final watch = Stopwatch()..start();
    final score = measure();
    watch.stop();
    final runtime = watch.elapsed.msus.style(ColorProfile.dim);
    emitter.emit('$runtime $description', score);
    print(' ');
  }
}

/// Defines a benchmark for the synchronous function [run]. The benchmark
/// scores are emitted to stdout.
/// * `run`: the benchmarked function,
/// * `setup`: exectued once before the benchmark,
/// * `teardown`: executed once after the benchmark runs.
/// * `emitStats`: Set to `false` to emit score as provided by benchmark_harness.
void benchmark(
  String description,
  void Function() run, {
  void Function()? setup,
  void Function()? teardown,
  bool emitStats = true,
}) {
  final group = Zone.current[#group] as Group?;
  var groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';
  final instance = Benchmark(
    description: groupDescription +
        description.style(
          ColorProfile.benchmark,
        ),
    run: run,
    setup: setup,
    teardown: teardown,
  );
  final watch = Stopwatch()..start();

  try {
    if (run is Future<void> Function()) {
      throw UnsupportedError('The callback "run" must not be marked async!');
    }
  } catch (error, stack) {
    reportError(
      error,
      stack,
      description: instance.description,
      runtime: watch.elapsed,
      errorMark: benchmarkError,
    );
    return;
  }

  runZonedGuarded(
    () {
      try {
        if (emitStats) {
          instance.reportStats();
        } else {
          instance.report();
        }
        addSuccessMark();
      } catch (error, stack) {
        reportError(
          error,
          stack,
          description: instance.description,
          runtime: watch.elapsed,
          errorMark: benchmarkError,
        );
      }
    },
    ((error, stack) {
      // Safequard: Errors should be caught in the try block above.
      reportError(
        error,
        stack,
        description: instance.description,
        runtime: watch.elapsed,
        errorMark: benchmarkError,
      );
    }),
  );
}
