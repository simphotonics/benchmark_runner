// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart';

import '../../benchmark_runner.dart';

class ReportCommand extends Command {
  @override
  final name = 'report';

  // @override
  // final category = 'benchmark';

  @override
  String get invocation => super.invocation + ' <path to directory|file>';

  @override
  final description = 'Runs benchmarks and prints a score report to stdout.';

  ReportCommand();

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading flags
    final isVerbose = globalResults!.flag(BenchmarkRunner.verbose);
    final isMonochrome = !globalResults!.flag(BenchmarkRunner.color);

    Ansi.status = isMonochrome ? AnsiOutput.disabled : AnsiOutput.enabled;

    final searchDirectory =
        globalResults!.rest.isEmpty ? 'benchmark' : argResults!.rest.first;

    // Resolving test files.
    final benchmarkFiles = await resolveBenchmarkFiles(searchDirectory);
    if (benchmarkFiles.isEmpty) {
      print('');
      print('Could not resolve any benchmark files using path: '
          '${searchDirectory.style(ColorProfile.highlight)}\n');
      print(
        'Please specify directory '
        'containing benchmark files: \n'
        '\$  ${'dart run benchmark_exporter'.style(ColorProfile.emphasize)} '
        '${'benchmark_directory'.style(ColorProfile.highlight)}',
      );
      exit(ExitCode.noBenchmarkFilesFound.index);
    } else {
      print('\nFinding benchmark files... '.style(ColorProfile.dim));
      for (final file in benchmarkFiles) {
        print('  ${file.path}');
      }
      print('');
    }

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

    final stream = Stream<String>.periodic(
        const Duration(milliseconds: 500),
        (i) =>
            'Progress timer: '.style(ColorProfile.dim) +
            Duration(milliseconds: i * 500).ssms.style(Ansi.green));
    const cursorToStartOfLine = Ansi.cursorToColumn(1);

    final subscription = stream.listen((event) {
      stdout.write(event);
      stdout.write(cursorToStartOfLine);
    });

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

    final results = await Future.wait(fResults);

    await subscription.cancel();

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
