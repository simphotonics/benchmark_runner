// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../benchmark_runner.dart';
import '../extensions/path_helper.dart';

class ExportCommand extends Command {
  @override
  final name = 'export';

  // @override
  // final category = 'benchmark';

  @override
  final description = 'Exports benchmark scores. A custom file extension '
      'and directory may be specified.';

  static const extension = 'extension';
  static const outputDir = 'outputDir';

  ExportCommand() {
    argParser
      ..addOption(
        extension,
        abbr: 'e',
        defaultsTo: 'txt',
        help: 'Set file extension of exported files.',
      )
      ..addOption(
        outputDir,
        abbr: 'o',
        defaultsTo: null,
        help: 'Directory must exist. Score files will be written to it.',
      );
  }

  @override
  Future<void> run() async {
    final clock = Stopwatch()..start();

    // Reading flags
    final isVerbose = globalResults!.flag(BenchmarkRunner.verbose);
    final noColor = !globalResults!.flag(BenchmarkRunner.color);

    Ansi.status = noColor ? AnsiOutput.disabled : AnsiOutput.enabled;

    final searchDirectory =
        argResults!.rest.isEmpty ? 'benchmark' : argResults!.rest.first;

    // Resolving test files.
    final (benchmarkFiles: benchmarkFiles, entityType: entityType) =
        await resolveBenchmarkFiles(
      searchDirectory,
    );
    if (benchmarkFiles.isEmpty) {
      print('');
      print('Could not resolve any benchmark files using path: '
          '${searchDirectory.style(ColorProfile.highlight)}\n');
      print(
        'Please specify a directory '
        'containing benchmark files: \n'
        '\$  ${'dart run benchmark_exporter'.style(ColorProfile.emphasize)} '
        '${'benchmark_directory'.style(ColorProfile.highlight)}',
      );
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

    // Reading options
    final outputDirectory = argResults!.option(outputDir) ?? searchDirectory;

    // Starting processes.
    final fResults = <Future<BenchmarkProcessResult>>[];
    for (final file in benchmarkFiles) {
      fResults.add(BenchmarkProcess.runBenchmark(
        executable: 'dart',
        arguments: [
          '--define=isBenchmarkProcess=true',
          if (isVerbose) '--define=isVerbose=true',
          if (noColor) '--define=noColor=true',
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

    final results = await Future.wait(fResults);
    stdout.writeln('\n');

    for (final result in results) {
      print('\$ '.style(ColorProfile.dim) + result.command());
      if (isVerbose) {
        print(result.stdout.indentLines(2, indentMultiplierFirstLine: 2));
        print('\n');
      }

      final outputFileName = p
          .fromUri(result.benchmarkFile.uri)
          .basename
          .setExtension('.' + argResults!.option(extension)!);

      final outputPath = outputDirectory.join(outputFileName);

      print(
        'Writing scores to: '.style(ColorProfile.dim) + outputPath + '\n',
      );

      await writeTo(path: outputPath, contents: result.stdout);

      if (isVerbose) {
        print(result.stderr.indentLines(4, indentMultiplierFirstLine: 4));
      }
    }

    await subscription.cancel();

    final exitStatus = BenchmarkUtils.aggregatedExitStatus(
      results: results,
      duration: clock.elapsed,
      isVerbose: isVerbose,
    );

    print(exitStatus.message);
    exit(exitStatus.exitCode.code);
  }
}
