import '../extension/benchmark_helper.dart';
import '../util/stats.dart';
import 'score.dart';

/// A synchronous function that does nothing.
void doNothing() {}

/// A class used to benchmark synchronous functions.
/// The benchmarked function is provided as a constructor argument.
class ScoreGenerator {
  /// Constructs a [ScoreGenerator] object using the following arguments:
  /// * [description]: a [String] describing the benchmark,
  /// * [run]: the synchronous function to be benchmarked,
  /// * [setup]: a function that is executed once before running the benchmark,
  /// * [teardown]: a function that is executed once after the benchmark has
  /// completed.
  const ScoreGenerator({
    required void Function() run,
    void Function() setup = doNothing,
    void Function() teardown = doNothing,
  }) : _run = run,
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
  /// * The benchmark score entries represent the run time in microseconds.
  /// * The integer `innerIter` is larger than 1
  ///  if each score entry was averaged over
  /// `innerIter` runs.
  ({List<double> scores, int innerIter}) sample({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(milliseconds: 200),
  }) {
    _setup();
    final sample = <int>[];
    final innerIters = <int>[];
    final overhead = <int>[];
    final watch = Stopwatch();
    //
    int innerIterMean = 1;
    try {
      // Warmup (Default: For 200 ms with 3 pre-runs).
      final scoreEstimate = watch.warmUp(
        _run,
        duration: warmUpDuration,
        warmUpRuns: warmUpRuns,
      );
      final sampleSize = BenchmarkHelper.sampleSize(scoreEstimate.ticks);

      if (sampleSize.inner > 1) {
        final durationAsTicks = sampleSize.inner * scoreEstimate.ticks;
        for (var i = 0; i < sampleSize.outer + warmUpRuns; i++) {
          // Averaging each score over approx. sampleSize.inner runs.
          // For details see function BenchmarkHelper.sampleSize.
          final score = watch.measure(_run, durationAsTicks);
          sample.add(score.ticks);
          innerIters.add(score.iter);
        }
        innerIterMean =
            innerIters.reduce((sum, element) => sum + element) ~/
            innerIters.length;
      } else {
        for (var i = 0; i < sampleSize.outer + warmUpRuns; i++) {
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
        scores:
            sample
                .map<double>((e) => e * (1000000 / watch.frequency))
                .skip(warmUpRuns)
                .toList(),
        innerIter: innerIterMean,
      );
    } finally {
      teardown();
    }
  }

  /// Returns a [Score] object holding the total benchmark duration
  /// and a [Stats] object created from the score sample.
  /// Note: The run time entried represent durations in microseconds.
  Score score({
    final int warmUpRuns = 3,
    final Duration warmUpDuration = const Duration(microseconds: 200),
  }) {
    final watch = Stopwatch()..start();
    final sample = this.sample(
      warmUpDuration: warmUpDuration,
      warmUpRuns: warmUpRuns,
    );
    return Score(
      duration: watch.elapsed,
      sample: sample.scores,
      innerIter: sample.innerIter,
    );
  }
}
