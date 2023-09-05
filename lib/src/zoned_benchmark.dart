import 'dart:async' show Zone, runZonedGuarded;

import 'benchmark.dart';
import 'extensions/string_utils.dart';
import 'utils/ansi_modifier.dart';
import 'utils/environment.dart';

class ZonedBenchmark {
  ZonedBenchmark({
    required String description,
    required void Function() run,
    void Function()? setup,
    void Function()? teardown,
    this.emitStats = true,
  }) : benchmark = Benchmark(
          description: description.colorize(AnsiModifier.cyan),
          run: run,
          setup: setup,
          teardown: teardown,
        );
  final Benchmark benchmark;
  final bool emitStats;

  /// Runs the benchmark
  void run() {
    // Check for nested benchmarks.
    final description = Zone.current[#_benchmarkDescription] as String?;
    if (description != null) {
      throw UnsupportedError('${'Nested benchmarks are '
              'not supported! '.colorize(AnsiModifier.red)}'
          'Check benchmarks: $description > ${benchmark.description}');
    }
    return runZonedGuarded(
      emitStats ? benchmark.reportStats: benchmark.report,
      ((error, stack) {
        print(benchmark.description + ' $error'.colorize(AnsiModifier.red));
        if (isVerbose) {
          print(stack.toString().indentLines(2, skipFirstLine: true));
        }
        addErrorMark();
      }),
      zoneValues: {#_benchmarkDescription: benchmark.description},
    );
  }
}

/// Defines a benchmark for the synchronous function [run]. The benchmark
/// scores are emitted to stdout.
void benchmark(
  String description,
  void Function() run, {
  void Function()? setup,
  void Function()? teardown,
  bool emitStats = true,
}) {
  final instance = ZonedBenchmark(
    description: description,
    run: run,
    setup: setup,
    teardown: teardown,
    emitStats: emitStats,
  );
  instance.run();
}
