import 'dart:convert';
import 'dart:io' show ProcessResult, Process, systemEncoding;

import 'package:benchmark_runner/src/extensions/string_utils.dart';

import '../utils/ansi_modifier.dart';
import 'exit_code.dart';

/// A record holding:
/// * the name of the executable that was used to start the process,
/// * the list of arguments,
/// * and the resulting [ProcessResult] object.
typedef BenchmarkProcessResult = ({
  String executable,
  List<String> arguments,
  ProcessResult processResult
});

/// A record holding:
/// * an exit message,
/// * an exit code.
typedef ExitStatus = ({String message, ExitCode exitCode});

/// Extension on [Process].
/// Adds the static method `runBenchmark`.
extension BenchmarkProcess on Process {
  /// Runs a benchmark and returns an instance of
  /// [BenchmarkProcessResult].
  static Future<BenchmarkProcessResult> runBenchmark(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    return Process.run(executable, arguments,
            workingDirectory: workingDirectory,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            runInShell: runInShell,
            stdoutEncoding: stdoutEncoding,
            stderrEncoding: stderrEncoding)
        .then<BenchmarkProcessResult>((processResult) {
      return (
        executable: executable,
        arguments: arguments,
        processResult: processResult,
      );
    });
  }
}

extension BenchmarkUtils on BenchmarkProcessResult {
  /// Returns the command and the options used to start this process.
  String get command => '$executable ${arguments.join(' ')}';

  /// Returns the process exit code.
  int get exitCode => processResult.exitCode;

  /// Note: Every time a benchmark fails a
  /// message is written to `stderr`.
  int get numberOfFailedBenchmarks {
    return processResult.stderr.toString().countSubstring(errorMark);
  }

  /// Indents `stdout`.
  ///
  /// Each line of output will start with
  /// `indentChars` repeated `indentMultiplier` times.
  String formattedStdout({
    String indentChars = ' ',
    int indentMultiplier = 1,
  }) =>
      (processResult.stdout as String).indentLines(
        indentMultiplier,
        indentChars: indentChars,
      );

  /// Indents and colorizes `this.stderr`.
  ///
  /// Each line of output will start with
  /// `indentChars` repeated `indentMultiplier` times.
  String formattedStderr({
    String indentChars = ' ',
    int indentMultiplier = 1,
  }) =>
      (processResult.stderr as String)
          .replaceAllMapped(errorMark, (match) => '')
          .indentLines(
            indentMultiplier,
            indentChars: indentChars,
          );

  /// Returns a record of type [ExitStatus].
  /// * Checks if the benchmark processes exited normally.
  /// * Checks if stderr contains the string `To do`.
  static ExitStatus aggregatedExitStatus({
    required List<BenchmarkProcessResult> results,
    bool isVerbose = false,
  }) {
    var msg = '\nSummary:';
    var exitCode = ExitCode.allBenchmarksPassed;
    var numberOfFailedBenchmarks = 0;

    for (final result in results) {
      final failedBenchmarks = result.numberOfFailedBenchmarks;
      numberOfFailedBenchmarks += failedBenchmarks;
    }

    if (numberOfFailedBenchmarks > 0) {
      msg = '${msg}Benchmarks resulting in an uncaught exception: '
          '${numberOfFailedBenchmarks.toString().colorize(
                AnsiModifier.red,
              )}.'
          '${isVerbose ? '' : '\nTry using the option ${'--verbose'.colorize(
              AnsiModifier.whiteBold,
            )} '
              'for more details.'}';
      exitCode = ExitCode.someBenchmarksFailed;
    }

    switch (exitCode) {
      case ExitCode.someBenchmarksFailed:
        msg = '$msg\nExiting with code '
            '${ExitCode.someBenchmarksFailed.code}: '
            '${ExitCode.someBenchmarksFailed.description.colorize(
          AnsiModifier.red,
        )}';
        break;
      case ExitCode.allBenchmarksPassed:
        msg = '${'Completed successfully.'.colorize(AnsiModifier.green)}\n'
            'Exiting with code: 0.';
        break;
      default:
    }

    return (message: msg, exitCode: exitCode);
  }
}
