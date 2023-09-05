import 'dart:async';
import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart'
    show AsyncBenchmarkBase, PrintEmitter;

import 'extensions/color_print.dart';
import 'utils/stats.dart';

typedef AsyncFunction = Future<void> Function();

/// An asynchronous function that does nothing.
Future<void> futureDoNothing() async {}

/// A generic class used to benchmark asynchronous functions.
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
    super.emitter = const PrintEmitter(),
  })  : _run = run,
        _setup = setup ?? futureDoNothing,
        _teardown = teardown ?? futureDoNothing,
        super(description);

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

  Future<List<double>> sample() async {
    await _setup();
    final result = <double>[];
    try {
      // Warmup for at least 100ms. Discard result.
      // Note: Score in ms.
      final score = (await AsyncBenchmarkBase.measureFor(_run, 100)) ~/ 1000;

      // Set the runtime to minimum: 1ms and max: 2000 ms
      final minimumMillis = min(
        max((score*10), 1),
        2000,
      );

      /// Set the sampleSize to minimum: 11 and maximum: 75.
      final sampleSize = 75 - 8 * log(minimumMillis).ceil();
      for (var i = 0; i < sampleSize; i++) {
        result.add(await AsyncBenchmarkBase.measureFor(
          _run,
          minimumMillis,
        ));
      }
      return result;
    } finally {
      await _teardown();
    }
  }

  Future<void> reportStats() async {
    final stats = Stats(await sample());
    stats.removeOutliers(10);
    emitter.emitStats(
      description: description,
      mean: stats.mean,
      median: stats.median,
      stdDev: stats.stdDev,
      interQuartileRange: (stats.quartile3 - stats.quartile1).toDouble(),
      blockHistogram: stats.blockHistogram(),
    );
  }
}
