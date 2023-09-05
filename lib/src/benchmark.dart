import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart'
    show BenchmarkBase, PrintEmitter;

import 'extensions/color_print.dart';
import 'utils/stats.dart';

typedef SyncFunction = void Function();

/// A synchronous function that does nothing.
void doNothing() {}

/// A generic class used to benchmark synchronous functions.
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
    super.emitter = const PrintEmitter(),
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
  void exercise() => run();

  /// Returns the benchmark description (corresponds to the getter name).
  String get description => name;

  List<double> sample() {
    _setup();
    final result = <double>[];
    try {
      // Warmup for at least 100ms.
      // Score is transformed to microseconds.
      final score = BenchmarkBase.measureFor(warmup, 200) ~/ 1000;

      // Set the runtime to minimum: 10*score and max: 2000 ms
      final minimumMillis = min(
        max((score * 10), 1),
        2000,
      );

      /// Set the sampleSize to minimum: 11 and maximum: 75.
      final sampleSize = 75 - 8 * log(minimumMillis).ceil();
      for (var i = 0; i < sampleSize; i++) {
        result.add(BenchmarkBase.measureFor(
          exercise,
          minimumMillis,
        ));
      }
      return result;
    } finally {
      teardown();
    }
  }

  /// Runs the method [sample()] and emits the benchmark scores.
  void reportStats() {
    final stats = Stats(sample());
    //stats.removeOutliers(7.5);
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
