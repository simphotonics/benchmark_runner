// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart' show Command;
import 'package:path/path.dart' as p;

import '../base/benchmark_process_result.dart';
import '../extension/color_profile.dart';
import '../extension/path_helper.dart';
import '../extension/string_utils.dart';
import '../util/file_utils.dart';
import 'file_explorer.dart';
import 'progress_indicator.dart';

class ExportCommand extends Command<void> with BenchmarkFileExplorer {
  @override
  String get name => 'export';

  // @override
  // final category = 'benchmark';

  @override
  String get description =>
      'Exports benchmark scores. A file extension '
      'and output directory may be specified.';

  static const _extension = 'extension';
  static const _outputDir = 'output-dir';
  static const _colorOutput = "color-output";

  new() {
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
        defaultsTo: 'benchmark',
        help: 'Set directory where score files will be written.',
      )
      ..addFlag(
        _colorOutput,
        abbr: 'c',
        defaultsTo: false,
        negatable: true,
        help: 'Enables colorized reporting.',
      );
  }

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading global flags
    final isVerbose = globalResults!.flag('verbose');

    // Reading local flags
    final isMonochrome = !argResults!.flag(_colorOutput);
    if (isMonochrome) {
      Ansi.status = AnsiOutput.disabled;
    }

    final benchmarkFiles = await findBenchmarkFiles();

    // Reading options
    final outputDirectory = argResults!.option(_outputDir) ?? "benchmark";
    final extension = argResults!.option(_extension) ?? "txt";

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
          .setExtension('.' + extension);

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
    exit(exitStatus.exitCode.index);
  }
}
