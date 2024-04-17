import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_runner/benchmark_runner.dart';

/// The script usage.
const usage =
    '------------------------------------------------------------------------\n'
    'Usage: benchmark_runner [options] [<benchmark-directory/benchmark-file>] '
    '\n\n'
    '  Note: If a benchmark-directory is specified, the program  will attempt \n'
    '        to run all dart files ending with \'_benchmark.dart.\'\n'
    '  Options:\n'
    '    -h, --help                Shows script usage.\n'
    '    -v, --verbose             Enables displaying error messages.\n'
    '    --isMonochrome            Disables color output.\n';

Future<void> main(List<String> args) async {
  final clock = Stopwatch()..start();
  final argsCopy = List.of(args);
  bool isUsingDefaultDirectory = false;

  // Reading script options.
  final isVerbose = args.contains('--verbose') || args.contains('-v');
  final isMonochrome = args.contains('--isMonochrome') ? true : false;
  Ansi.status = isMonochrome ? AnsiOutput.disabled : AnsiOutput.enabled;

  argsCopy.remove('--isMonochrome');
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
        ' path: ${argsCopy[0].style(ColorProfile.highlight)}');
    print(
      'Please specify a path to a benchmark directory '
      'containing benchmark files: \n'
      '\$  ${'dart run benchmark_runner'.style(ColorProfile.emphasize)} '
      '${'benchmark_directory'.style(ColorProfile.highlight)}',
    );
    print(usage);
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
      'dart',
      [
        '--define=isBenchmarkProcess=true',
        if (isVerbose) '--define=isVerbose=true',
        if (isMonochrome) '--define=isMonochrome=true',
        file.path,
      ],
    ));
  }

  final stream = Stream<String>.periodic(
      const Duration(milliseconds: 500),
      (i) => 'Progress timer: '
          '${Duration(milliseconds: i * 500).ssms.style(Ansi.green)}');

  const cursorToStartOfLine = Ansi.cursorToColumn(1);
  // intStream = intStream.take(3);
  final subscription = stream.listen((event) {
    stdout.write(event);
    stdout.write(cursorToStartOfLine);
  });

  final results = <BenchmarkProcessResult>[];

  //Printing results.
  for (final fResult in fResults) {
    fResult.then((result) {
      print('\n\nRunning: ${result.command}'.style(ColorProfile.dim));
      print(result.stdout.indentLines(2, indentMultiplierFirstLine: 2));
      if (isVerbose) {
        print(result.stderr.indentLines(4, indentMultiplierFirstLine: 4));
      }
      results.add(result);
    });
  }

  // Composing exit message.
  await Future.wait(fResults);

  subscription.cancel();
  final exitStatus = BenchmarkUtils.aggregatedExitStatus(
    results: results,
    duration: clock.elapsed,
    isVerbose: isVerbose,
  );

  print(exitStatus.message);
  exit(exitStatus.exitCode.code);
}
