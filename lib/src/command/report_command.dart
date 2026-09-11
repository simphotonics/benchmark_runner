// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart';

import '../base/benchmark_process_result.dart';
import '../extension/color_profile.dart';
import '../extension/string_utils.dart';
import 'file_explorer.dart';
import 'progress_indicator.dart';

class ReportCommand extends Command<void> with BenchmarkFileExplorer {
  @override
  String get name => 'report';

  @override
  String get invocation => super.invocation + ' <path to directory|files>';

  @override
  String get description =>
      'Runs benchmarks and prints a score report to stdout.';

  new() {
    argParser.addFlag(
      'monochrome',
      abbr: 'm',
      negatable: false,
      defaultsTo: false,
      help: 'Disables colorized reporting.',
    );
  }

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading global flags
    final isVerbose = globalResults!.flag('verbose');

    // Reading local flags
    final isMonochrome = argResults!.flag('monochrome');
    if (isMonochrome) {
      Ansi.status = AnsiOutput.disabled;
    }

    final benchmarkFiles = await findBenchmarkFiles();

    // Starting processes.
    final fResults = <Future<BenchmarkProcessResult>>[];
    for (final file in benchmarkFiles) {
      fResults.add(
        BenchmarkProcess.runBenchmark(
          executable: 'dart',
          arguments: [
            '--define=isBenchmarkProcess=true',
            if (isVerbose) '--define=isVerbose=true',
            if (isMonochrome) '--define=isMonochrome=true',
          ],
          benchmarkFile: file,
        ),
      );
    }

    // Start subscription to progress indicator.
    final progressIndicator = progressIndicatorSubscription();

    // Printing benchmark scores.
    for (final fResult in fResults) {
      unawaited(
        fResult.then((result) {
          print('\$ '.style(ColorProfile.dim) + result.command());
          print(result.stdout.indentLines(2, indentMultiplierFirstLine: 2));
          print('\n');
          if (isVerbose) {
            print(result.stderr.indentLines(4, indentMultiplierFirstLine: 4));
          }
        }),
      );
    }

    // Close subscription to progress indicator.
    final results = await Future.wait(fResults);

    await progressIndicator.cancel();

    // Composing exit message.
    final exitStatus = BenchmarkUtils.aggregatedExitStatus(
      results: results,
      duration: clock.elapsed,
      isVerbose: isVerbose,
    );

    print(exitStatus.message);
    exit(exitStatus.exitCode.index);
  }
}
