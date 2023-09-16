import 'dart:async';
import 'dart:math';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_harness/benchmark_harness.dart'
    show BenchmarkBase, PrintEmitter;
import 'package:benchmark_runner/src/extensions/duration_formatter.dart';

import 'color_print_emitter.dart';
import 'extensions/color_print.dart';
import 'extensions/color_profile.dart';
import 'extensions/string_utils.dart';
import 'group.dart';
import 'utils/environment.dart';
import 'utils/stats.dart';

typedef SyncFunction = void Function();

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
    required SyncFunction run,
    SyncFunction? setup,
    SyncFunction? teardown,
    super.emitter = const ColorPrintEmitter(),
  })  : _run = run,
        _setup = setup ?? doNothing,
        _teardown = teardown ?? doNothing,
        super(description);

  // static void main() {
  //   const GenericBenchmark().report();
  // }

  final SyncFunction _run;
  final SyncFunction _setup;
  final SyncFunction _teardown;

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

  List<double> sample() {
    _setup();
    final sample = <int>[];
    final overhead = <int>[];
    try {
      // Warmup for at least 100ms.
      final score = BenchmarkBase.measureFor(_run, 400);

      // Micro-benchmark exercise runtime < 1ms
      // Note: score units: [us]
      if (score < 1000) {
        final result = <double>[];
        // 1 <= minimumMillis <= 50
        // Note: score * 50 ~/1000 -> score ~/20
        final minimumMillis = max(score ~/ 20, 1);
        // 40 <= sampleSize <= 200
        final sampleSize = 120 - 20 * log(minimumMillis).ceil();
        for (var i = 0; i < sampleSize; i++) {
          result.add(BenchmarkBase.measureFor(
            _run,
            minimumMillis,
          ));
        }
        return result;
      } else {
        // Benchmark with exercise runtime > 1ms
        // 300  <= sampleSize <= 10
        var sampleSize = 300 - 41 * log(score ~/ 1000).ceil();
        sampleSize = sampleSize < 10 ? 10 : sampleSize;

        final watch = Stopwatch()..start();
        final warmupRuns = 3;
        for (var i = 0; i < sampleSize + warmupRuns; i++) {
          watch.reset();
          _run();
          sample.add(watch.elapsedTicks);
          watch.reset();
          overhead.add(watch.elapsedTicks);
        }
        for (var i = 0; i < sampleSize; i++) {
          sample[i] = sample[i] - overhead[i];
        }
        final frequency = watch.frequency / 1000000;
        return sample
            .map<double>(
              (e) => e / frequency,
            )
            .skip(warmupRuns)
            .toList();
      }
    } finally {
      teardown();
    }
  }

  /// Returns a record holding the total benchmark duration
  /// and a [Stats] object created from the score samples.
  RuntimeStats runtimeStats() {
    final watch = Stopwatch()..start();
    final stats = Stats(sample());
    return (runtime: watch.elapsed, stats: stats);
  }

  /// Runs the method [sample] and emits the benchmark score statistics.
  void reportStats() {
    final (:stats, :runtime) = runtimeStats();
    //stats.removeOutliers(10);
    emitter.emitStats(runtime: runtime, description: description, stats: stats);
  }

  /// Runs the method [measure] and emits the benchmark score.
  @override
  void report() {
    final watch = Stopwatch()..start();
    final score = measure();
    watch.stop();
    final runtime = watch.elapsed.mmssms.style(ColorProfile.dim);
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
  final groupDescription = group == null ? '' : '${group.description} ';
  final instance = Benchmark(
    description: groupDescription +
        description.style(
          ColorProfile.benchmark,
        ),
    run: run,
    setup: setup,
    teardown: teardown,
  );
  // Check for nested benchmarks.
  // final description = Zone.current[#_benchmarkDescription] as String?;
  // if (description != null) {
  //   throw UnsupportedError('${'Nested benchmarks are '
  //           'not supported! '.style(ColorProfile.error)}'
  //       'Check benchmarks: $description > ${benchmark.description}');
  // }
  final watch = Stopwatch()..start();
  runZonedGuarded(
    () {
      if (emitStats) {
        instance.reportStats();
      } else {
        instance.report();
      }
      addSuccessMark();
    },
    ((error, stack) {
      print(
        '${watch.elapsed.mmssms.style(ColorProfile.dim)} '
        '${instance.description}'
        '${' $error'.style(ColorProfile.error)} \n',
      );
      if (isVerbose) {
        print(stack.toString().indentLines(2, indentMultiplierFirstLine: 2));
      }
      addErrorMark();
    }),
    zoneValues: {#_benchmarkDescription: instance.description},
  );
}
