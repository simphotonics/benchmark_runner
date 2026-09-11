import 'dart:io' show File, exit;

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:args/command_runner.dart' show Command;

import '../enum/exit_code.dart';
import '../extension/color_profile.dart';
import '../util/file_utils.dart' show resolveBenchmarkFiles;

mixin BenchmarkFileExplorer on Command<void> {
  /// Attempts to find benchmark files and prints an error/success message.
  /// * Uses `argResults!.rest.first` as path.
  /// * If no path is provided, the directory `benchmark` is used instead.
  Future<List<File>> findBenchmarkFiles() async {
    final path = argResults!.rest.isEmpty
        ? 'benchmark'
        : argResults!.rest.first;

    // Resolving test files.
    final benchmarkFiles = await resolveBenchmarkFiles(path);
    if (benchmarkFiles.isEmpty) {
      print('');
      print(
        'Could not resolve any benchmark files using path: '
        '${path.style(ColorProfile.highlight)}\n',
      );
      exit(ExitCode.noBenchmarkFilesFound.index);
    } else {
      print('\nLocating benchmark files ... '.style(ColorProfile.dim));
      for (final file in benchmarkFiles) {
        print(file.path);
      }
      print('');
    }
    return benchmarkFiles;
  }
}
