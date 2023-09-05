import 'dart:async' show Zone, runZonedGuarded;
import 'dart:isolate';

import 'async_benchmark.dart';
import 'extensions/color_print.dart';
import 'extensions/string_utils.dart';
import 'utils/ansi_modifier.dart';
import 'utils/environment.dart';
import 'utils/stats.dart';

class _ZonedAsyncBenchmark {
  _ZonedAsyncBenchmark({
    required String description,
    required Future<void> Function() run,
    Future<void> Function()? setup,
    Future<void> Function()? teardown,
    this.emitStats = true,
    this.runInIsolate = false,
  }) : asyncBenchmark = AsyncBenchmark(
          description: description.colorize(AnsiModifier.magenta),
          run: run,
          setup: setup,
          teardown: teardown,
        );
  final AsyncBenchmark asyncBenchmark;
  final bool runInIsolate;
  final bool emitStats;

  /// Runs the benchmark
  Future<void> run() async {
    final parentDescription = Zone.current[#_benchmarkDescription] as String?;
    if (parentDescription != null) {
      throw UnsupportedError('${'Nested benchmarks are '
              'not supported! '.colorize(AnsiModifier.red)}'
          'Check benchmarks: '
          '$parentDescription > ${asyncBenchmark.description}');
    }

    return runZonedGuarded(
      switch ((emitStats, runInIsolate)) {
        (true, true) => () async {
            final stats =
                Stats(await Isolate.run(() => asyncBenchmark.sample()));
            asyncBenchmark.emitter.emitStats(
                description: asyncBenchmark.description,
                mean: stats.mean,
                median: stats.median,
                stdDev: stats.stdDev,
                interQuartileRange:
                    (stats.quartile3 - stats.quartile1).toDouble(),
                blockHistogram: stats.blockHistogram());
          },
        (true, false) => asyncBenchmark.reportStats,
        (false, true) => () async {
            final score = await Isolate.run(() => asyncBenchmark.measure());
            asyncBenchmark.emitter.emit(
              asyncBenchmark.description,
              score,
            );
          },
        (false, false) => asyncBenchmark.report,
      },
      ((error, stack) {
        print('${asyncBenchmark.description} '
            '${error.toString().colorize(AnsiModifier.red)}');
        if (isVerbose) {
          print(stack.toString().indentLines(2, skipFirstLine: true));
        }
        addErrorMark();
      }),
      zoneValues: {#_benchmarkDescription: asyncBenchmark.description},
    );
  }
}

/// Defines an asynchronous benchmark.
Future<void> asyncBenchmark(
  String description,
  Future<void> Function() run, {
  Future<void> Function()? setup,
  Future<void> Function()? teardown,
  bool emitStats = true,
  bool runInIsolate = true,
}) {
  final instance = _ZonedAsyncBenchmark(
    description: description,
    run: run,
    setup: setup,
    teardown: teardown,
    emitStats: emitStats,
    runInIsolate: runInIsolate,
  );
  return instance.run();
}
