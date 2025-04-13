import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../emitter/score_emitter.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import 'group.dart';
import 'score_generator.dart';

/// Runs a benchmark for the synchronous function [run].
/// The benchmark scores are emitted to stdout.
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
  warmUpDuration = const Duration(),
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
          score: scoreGenerator.score(),
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
