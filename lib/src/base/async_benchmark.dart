import 'dart:async';
import 'dart:isolate';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../emitter/score_emitter.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import 'async_score_generator.dart';
import 'group.dart';
import 'sample_size.dart';

/// Runs an asynchronous benchmark.
/// * [run]: the benchmarked function,
/// * [setup]: executed once before the benchmark,
/// * [teardown]: executed once after the benchmark runs.
/// * [runInIsolate]: Set to `true` to run benchmark in a
///    separate isolate.
/// * [scoreEmitter]: A custom score emitter.
/// * [warmUpRuns]: The number of times [run] is called before the measurement.
/// * [warmUpDuration]: The duration used to create a score estimate.
/// * [sampleSize]: An optional parameter of type [SampleSize] that is used
/// to specify the
/// `length` of the benchmark score list and the `innerIterations` (the number
/// of time [run] is averaged over to generate a score entry).
///
Future<void> asyncBenchmark(
  String description,
  Future<void> Function() run, {
  Future<void> Function() setup = futureDoNothing,
  Future<void> Function() teardown = futureDoNothing,
  ScoreEmitter scoreEmitter = const StatsEmitter(),
  final int warmUpRuns = 3,
  final Duration warmUpDuration = const Duration(milliseconds: 200),
  SampleSize? sampleSize,
  bool runInIsolate = true,
}) async {
  final group = Zone.current[#group] as Group?;
  final groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';

  final scoreGenerator = AsyncScoreGenerator(
    run: run,
    setup: setup,
    teardown: teardown,
  );

  description =
      groupDescription +
      (hourGlass + description).style(ColorProfile.asyncBenchmark);

  final watch = Stopwatch()..start();

  await runZonedGuarded(
    () async {
      try {
        if (runInIsolate) {
          await Isolate.run(
            () async => scoreEmitter.emit(
              description: description,
              score: await scoreGenerator.score(
                warmUpDuration: warmUpDuration,
                warmUpRuns: warmUpRuns,
                sampleSize: sampleSize,
              ),
            ),
          );
        } else {
          scoreEmitter.emit(
            description: description,
            score: await scoreGenerator.score(),
          );
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
