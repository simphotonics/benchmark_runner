import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart' show BenchmarkBase;
import 'package:exception_templates/exception_templates.dart';

import '../extension/benchmark_helper.dart';
import '../extension/color_profile.dart';
import '../extension/duration_formatter.dart';
import '../extension/string_utils.dart';
import '../util/stats.dart';
import 'color_print_emitter.dart';
import 'group.dart';
import 'score.dart';

/// A synchronous function that does nothing.
void doNothing() {}

/// Generates a report that includes benchmark score statistics.
void reportStats(Benchmark instance, ColorPrintEmitter emitter) {
  emitter.emitStats(
    description: instance.description,
    score: instance.score(),
  );
}

/// Generates a BenchmarkHarness style report. Score times refer to
/// a single execution of the function `run`.
void reportMean(Benchmark instance, ColorPrintEmitter emitter) {
  final watch = Stopwatch()..start();
  final value = instance.measure();
  watch.stop();
  final runtime = watch.elapsed.msus.style(ColorProfile.dim);
  emitter.emit('$runtime ${instance.description}', value);
}

/// Generic function that reports benchmark scores by calling an emitter [E].
typedef Reporter<E extends ColorPrintEmitter> = void Function(Benchmark, E);

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
    void Function() setup = doNothing,
    void Function() teardown = doNothing,
  })  : _run = run,
        _setup = setup,
        _teardown = teardown,
        super(description, emitter: const ColorPrintEmitter());

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
  Score score() {
    final watch = Stopwatch()..start();
    final sample = this.sample();
    return Score(
      runtime: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }

  /// Runs the method [measure] and emits the benchmark score.
  @override
  void report() => reportMean(this, emitter as ColorPrintEmitter);
}

/// Defines a benchmark for the synchronous function [run]. The benchmark
/// scores are emitted to stdout.
/// * `run`: the benchmarked function,
/// * `setup`: exectued once before the benchmark,
/// * `teardown`: executed once after the benchmark runs.
/// * `report`: report to emit score as provided by benchmark_harness.
/// * `emitter`: An emitter for generating a custom benchmark report.
/// * `report`: A callback that can be used to call an emitter method.
void benchmark<E extends ColorPrintEmitter>(
  String description,
  void Function() run, {
  void Function() setup = doNothing,
  void Function() teardown = doNothing,
  E? emitter,
  Reporter<E> report = reportStats,
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
        if (emitter == null) {
          switch (report) {
            case reportStats:
              reportStats(
                instance,
                instance.emitter as ColorPrintEmitter,
              );
              break;
            case reportMean:
              reportMean(
                instance,
                instance.emitter as ColorPrintEmitter,
              );
            default:
              throw ErrorOf<Reporter<E>>(
                  message: 'Could not run benchmark.',
                  invalidState: 'Emitter is missing.',
                  expectedState: 'Please specify an emitter of type <$E>.');
          }
        } else {
          report(instance, emitter);
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
