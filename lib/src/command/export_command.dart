// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:path/path.dart' as p;

import '../base/benchmark_process_result.dart';
import '../extension/color_profile.dart';
import '../extension/path_helper.dart';
import '../extension/string_utils.dart';
import '../util/file_utils.dart';
import 'report_command.dart';

class ExportCommand extends ReportCommand {
  @override
  String get name => 'export';

  // @override
  // final category = 'benchmark';

  @override
  String get description =>
      'Exports benchmark scores. A custom file extension '
      'and directory may be specified.';

  static const _extension = 'extension';
  static const _outputDir = 'outputDir';

  ExportCommand() {
    argParser
      ..addOption(
        _extension,
        abbr: 'e',
        defaultsTo: 'txt',
        help: 'Set file extension of exported files.',
      )
      ..addOption(
        _outputDir,
        abbr: 'o',
        defaultsTo: null,
        help: 'Directory must exist. Score files will be written to it.',
      );
  }

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading flags
    final isVerbose = globalResults!.flag('verbose');
    final isMonochrome = globalResults!.flag('isMonochrome');

    Ansi.status = isMonochrome ? AnsiOutput.disabled : AnsiOutput.enabled;

    final searchDirectory =
        argResults!.rest.isEmpty ? 'benchmark' : argResults!.rest.first;

    final benchmarkFiles = await findBenchmarkFiles();

    // Reading options
    final outputDirectory = argResults!.option(_outputDir) ?? searchDirectory;

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

    final results = await Future.wait(fResults);

    for (final result in results) {
      print('\$ '.style(ColorProfile.dim) + result.command());
      if (isVerbose) {
        print(result.stdout.indentLines(2, indentMultiplierFirstLine: 2));
        print('\n');
      }

      final outputFileName = p
          .fromUri(result.benchmarkFile.uri)
          .basename
          .setExtension('.' + argResults!.option(_extension)!);

      final outputPath = outputDirectory.join(outputFileName);

      print('Writing scores to: '.style(ColorProfile.dim) + outputPath + '\n');

      await writeTo(path: outputPath, contents: result.stdout);

      if (isVerbose) {
        print(result.stderr.indentLines(4, indentMultiplierFirstLine: 4));
      }
    }

    // Close subscription to progress indicator.
    await progressIndicator.cancel();

    final exitStatus = BenchmarkUtils.aggregatedExitStatus(
      results: results,
      duration: clock.elapsed,
      isVerbose: isVerbose,
    );

    print(exitStatus.message);
    exit(exitStatus.exitCode.code);
  }
}
