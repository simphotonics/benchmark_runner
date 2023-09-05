import 'dart:async';
import 'dart:io';

import 'package:benchmark_runner/benchmark_runner.dart';

/// The script usage.
const usage =
    '---------------------------------------------------------------\n'
    'Usage: benchmark_runner [<benchmark-directory/benchmark-file>] '
    '[options]\n\n'
    '  Note: If a benchmark-directory is specified, the program  will attempt \n'
    '        to run all dart files ending with \'_benchmark.dart.\'\n'
    '  Options:\n'
    '    -h, --help                Shows script usage.\n'
    '    -v, --verbose             Enables displaying error messages.\n'
    '    --disable-color           Disables color output.\n';

Future<void> main(List<String> args) async {
  final clock = Stopwatch()..start();
  final argsCopy = List.of(args);
  bool isUsingDefaultDirectory = false;

  // Reading script options.

  final isVerbose = args.contains('--verbose') || args.contains('-v');
  final isMonochrome = args.contains('--disable-color') ? true : false;
  AnsiModifier.colorOutput = isMonochrome ? ColorOutput.off : ColorOutput.on;

  argsCopy.remove('--disable-color');
  argsCopy.remove('--verbose');
  argsCopy.remove('-v');

  switch (argsCopy) {
    case ['-h'] || ['--help']:
      print(usage);
      exit(0);
    case []:
      argsCopy.add('benchmark');
      isUsingDefaultDirectory = true;
    default:
  }

  // Resolving test files.
  final benchmarkFiles = await resolveBenchmarkFiles(argsCopy[0]);
  if (benchmarkFiles.isEmpty) {
    print('');
    print('Could not resolve any benchmark files using '
        '${isUsingDefaultDirectory ? 'default' : ''}'
        ' path: ${argsCopy[0].colorize(AnsiModifier.yellow)}');
    print(
      'Please specify a path to a benchmark directory '
      'containing benchmark files: \n'
      '\$  ${'dart run benchmark_runner'.colorize(AnsiModifier.whiteBold)} '
      '${'benchmark_directory'.colorize(AnsiModifier.yellow)}',
    );
    print(usage);
    exit(ExitCode.noBenchmarkFilesFound.index);
  } else {
    print('\nFinding test files... '.colorize(AnsiModifier.grey));
    for (final file in benchmarkFiles) {
      print('  ${file.path}');
    }
  }

  // Starting processes.
  final fResults = <Future<BenchmarkProcessResult>>[];
  for (final file in benchmarkFiles) {
    fResults.add(BenchmarkProcess.runBenchmark(
      'dart',
      [
        '--define=isBenchmarkProcess=true',
        '--define=isVerbose=${isVerbose ? 'true': 'false'}',
        '--define=isMonochrome=${isMonochrome ? 'true': 'false'}',
        file.path,
      ],
    ));
  }

  // Printing results.
  for (var fResult in fResults) {
    fResult.then((result) {
      print('\nRunning: ${result.command}'.colorize(AnsiModifier.grey));
      print(result.formattedStdout(
        indentMultiplier: 2,
      ));
      if (isVerbose) {
        // Indenting stderr output by 10 spaces.
        print(result.formattedStderr(
          indentMultiplier: 2,
        ));
      }
    });
  }

  // Composing exit message.
  final results = await Future.wait(fResults);
  final exitStatus = BenchmarkUtils.aggregatedExitStatus(
    results: results,
    isVerbose: isVerbose,
  );

  // Exiting.
  if (isVerbose) {
    print('Total run time: '
        '${clock.elapsed.toString().colorize(AnsiModifier.greenBright)}');
  }
  print(exitStatus.message);
  exit(exitStatus.exitCode.code);
}
