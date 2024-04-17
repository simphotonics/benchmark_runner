import 'dart:async';
import 'dart:isolate';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart'
    show AsyncBenchmarkBase;

import '../extensions/benchmark_helper.dart';
import '../extensions/color_profile.dart';
import '../extensions/duration_formatter.dart';
import '../extensions/string_utils.dart';
import '../utils/stats.dart';
import 'color_print_emitter.dart';
import 'group.dart';
import 'score.dart';

typedef AsyncFunction = Future<void> Function();

/// An asynchronous function that does nothing.
Future<void> futureDoNothing() async {}

/// A class used to benchmark asynchronous functions.
/// The benchmarked function is provided as a constructor argument.
class AsyncBenchmark extends AsyncBenchmarkBase {
  /// Constructs an [AsyncBenchmark] object using the following arguments:
  /// * [description]: a [String] describing the benchmark,
  /// * [run]: the asynchronous function to be benchmarked,
  /// * [setup]: an asynchronous function that is executed
  ///   once before running the benchmark,
  /// * [teardown]: an asynchronous function that is executed once after
  ///   the benchmark has completed.
  const AsyncBenchmark({
    required String description,
    required AsyncFunction run,
    AsyncFunction? setup,
    AsyncFunction? teardown,
    ColorPrintEmitter emitter = const ColorPrintEmitter(),
  })  : _run = run,
        _setup = setup ?? futureDoNothing,
        _teardown = teardown ?? futureDoNothing,
        super(description, emitter: emitter);

  // static void main() {
  //   const GenericBenchmark().report();
  // }

  final AsyncFunction _run;
  final AsyncFunction _setup;
  final AsyncFunction _teardown;

  // The benchmark code.
  @override
  Future<void> run() => _run();

  // Not measured setup code executed prior to the benchmark runs.
  @override
  Future<void> setup() => _setup();

  // Not measures teardown code executed after the benchmark runs.
  @override
  Future<void> teardown() => _teardown();

  // To opt into the reporting the time per run() instead of per 10 run() calls.
  @override
  Future<void> exercise() => run();

  /// Returns the benchmark description (corresponds to the getter name).
  String get description => name;

  /// Runs [measure] and emits the score and benchmark runtime.
  @override
  Future<void> report() async {
    final watch = Stopwatch()..start();
    final score = await measure();
    final runtime = watch.elapsed.msus.style(ColorProfile.dim);
    emitter.emit('$runtime $description', score);
  }

  /// Returns a sample of benchmark scores.
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

  /// Returns a record holding the total benchmark duration
  /// and a [Stats] object created from the score samples.
  Future<Score> score() async {
    final watch = Stopwatch()..start();
    final sample = await this.sample();
    watch.stop();
    //stats.removeOutliers(10);
    return Score(
      runtime: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }

  /// Emits score statistics.
  Future<void> reportStats() async {
    (emitter as ColorPrintEmitter).emitStats(
      description: description,
      score: await score(),
    );
  }
}

/// Defines an asynchronous benchmark.
/// * `run`: the benchmarked function,
/// * `setup`: exectued once before the benchmark,
/// * `teardown`: executed once after the benchmark runs.
/// * `emitStats`: Set to `false` to emit score as provided by benchmark_harness.
/// * `runInIsolate`: Set to `true` to run benchmarks in an isolate.
Future<void> asyncBenchmark(
  String description,
  Future<void> Function() run, {
  Future<void> Function()? setup,
  Future<void> Function()? teardown,
  bool emitStats = true,
  bool runInIsolate = true,
}) async {
  final group = Zone.current[#group] as Group?;
  final groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';

  final instance = AsyncBenchmark(
    description: groupDescription +
        (hourGlass + description).style(
          ColorProfile.asyncBenchmark,
        ),
    run: run,
    setup: setup,
    teardown: teardown,
  );
  final watch = Stopwatch()..start();

  await runZonedGuarded(
    () async {
      try {
        switch ((emitStats, runInIsolate)) {
          case (true, true):

            /// Run method sample() in an isolate.
            final score = await Isolate.run(instance.score);
            (instance.emitter as ColorPrintEmitter).emitStats(
              description: instance.description,
              score: score,
            );
            addSuccessMark();
            break;
          case (true, false):
            await instance.reportStats();
            addSuccessMark();
            break;
          case (false, true):

            /// Run method measure() in an isolate.
            final watch = Stopwatch()..start();
            final score = await Isolate.run(instance.measure);
            final runtime = watch.elapsed.ssms.style(ColorProfile.dim);
            instance.emitter.emit(
              '$runtime ${instance.description}',
              score,
            );
            addSuccessMark();
            break;
          case (false, false):
            await instance.report();
            addSuccessMark();
        }
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
