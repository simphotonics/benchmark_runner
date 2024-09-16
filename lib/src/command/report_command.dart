// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart';

import '../base/benchmark_process_result.dart';
import '../enum/exit_code.dart';
import '../extension/color_profile.dart';
import '../extension/duration_formatter.dart';
import '../extension/string_utils.dart';
import '../util/file_utils.dart';

class ReportCommand extends Command {
  @override
  String get name => 'report';

  @override
  String get invocation => super.invocation + ' <path to directory|file>';

  @override
  String get description =>
      'Runs benchmarks and prints a score report to stdout.';

  StreamSubscription<String> progressIndicatorSubscription() {
    final stream = Stream<String>.periodic(
      const Duration(milliseconds: 250),
      (i) =>
          'Progress timer: '.style(ColorProfile.dim) +
          Duration(milliseconds: i * 250).ssms.style(Ansi.green),
    );
    const cursorToStartOfLine = Ansi.cursorToColumn(1);

    return stream.listen((event) {
      stdout.write(cursorToStartOfLine);
      stdout.write(event);
      stdout.write(cursorToStartOfLine);
    });
  }

  /// Attempts to find benchmark files and prints an error/success message.
  /// * Uses `argResults!.rest.first` as path.
  /// * If no path is provided, the directory `benchmark` is used.
  Future<List<File>> findBenchmarkFiles() async {
    final searchDirectory =
        argResults!.rest.isEmpty ? 'benchmark' : argResults!.rest.first;

    // Resolving test files.
    final (benchmarkFiles: benchmarkFiles, entityType: entityType) =
        await resolveBenchmarkFiles(searchDirectory);
    if (benchmarkFiles.isEmpty) {
      print('');
      print('Could not resolve any benchmark files using path: '
          '${searchDirectory.style(ColorProfile.highlight)}\n');
      exit(ExitCode.noBenchmarkFilesFound.index);
    } else {
      if (entityType == FileSystemEntityType.directory) {
        print(
          '\nFinding benchmark files in '.style(ColorProfile.dim) +
              searchDirectory +
              ' ...'.style(ColorProfile.dim),
        );
      } else {
        print('\nFinding benchmark files ... '.style(ColorProfile.dim));
      }
      for (final file in benchmarkFiles) {
        print('  ${file.path}');
      }
      print('');
    }
    return benchmarkFiles;
  }

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading flags
    final isVerbose = globalResults!.flag('verbose');
    final isMonochrome = globalResults!.flag('isMonochrome');

    Ansi.status = isMonochrome ? AnsiOutput.disabled : AnsiOutput.enabled;

    final benchmarkFiles = await findBenchmarkFiles();

    // Starting processes.
    final fResults = <Future<BenchmarkProcessResult>>[];
    for (final file in benchmarkFiles) {
      fResults.add(BenchmarkProcess.runBenchmark(
        executable: 'dart',
        arguments: [
          '--define=isBenchmarkProcess=true',
          if (isVerbose) '--define=isVerbose=true',
          if (isMonochrome) '--define=isMonochrome=true',
        ],
        benchmarkFile: file,
      ));
    }

    // Start subscription to progress indicator.
    final progressIndicator = progressIndicatorSubscription();

    // Printing benchmark scores.
    for (final fResult in fResults) {
      fResult.then((result) {
        print('\$ '.style(ColorProfile.dim) + result.command());
        print(result.stdout.indentLines(2, indentMultiplierFirstLine: 2));
        print('\n');
        if (isVerbose) {
          print(result.stderr.indentLines(4, indentMultiplierFirstLine: 4));
        }
      });
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
    exit(exitStatus.exitCode.code);
  }
}
