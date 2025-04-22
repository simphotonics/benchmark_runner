import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../emitter/score_emitter.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import 'group.dart';
import 'sample_size.dart';
import 'score_generator.dart';

/// Runs a benchmark for the synchronous function [run].
/// The benchmark scores are emitted to stdout.
/// * [run]: the benchmarked function,
/// * [setup]: exectued once before the benchmark,
/// * [teardown]: executed once after the benchmark runs.
/// * [scoreEmitter]: An emitter for generating a custom benchmark report.
/// * [warmUpDuration]: The duration used to create a score estimate.
/// * [sampleSize]: An object of type [SampleSize] that is used to specify the
/// `length` of the benchmark score list and the `innerIterations` (the number
/// of time [run] is averaged over to generate a score entry).
void benchmark(
  String description,
  void Function() run, {
  void Function() setup = doNothing,
  void Function() teardown = doNothing,
  ScoreEmitter scoreEmitter = const StatsEmitter(),
  final Duration warmUpDuration = const Duration(milliseconds: 200),
  SampleSize? sampleSize,
}) {
  final group = Zone.current[#group] as Group?;
  var groupDescription =
      group == null ? '' : '${group.description.addSeparator(':')} ';
  final scoreGenerator = ScoreGenerator(
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
        scoreEmitter.emit(
          description: description,
          score: scoreGenerator.score(
            warmUpDuration: warmUpDuration,
            sampleSize: sampleSize,
          ),
        );
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
