import 'dart:convert';
import 'dart:io' show ProcessResult, Process, systemEncoding;

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_runner/src/extensions/color_profile.dart';
import 'package:benchmark_runner/src/extensions/duration_formatter.dart';
import 'package:benchmark_runner/src/extensions/string_utils.dart';

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

  /// Returns the number of benchmarks throwing an uncaught exception
  /// or error.
  int get numberOfFailedBenchmarks {
    return processResult.stderr.toString().countSubstring(benchmarkError);
  }

  /// Returns the number of groups throwing an uncaught exception or error.
  ///
  /// Note: Errors thrown within benchmark functions are counted separately.
  int get numberOfFailedGroups {
    return processResult.stderr.toString().countSubstring(groupErrorMark);
  }

  /// Returns the number of successfully completed benchmark runs.
  int get numberOfCompletedBenchmarks {
    return processResult.stderr.toString().countSubstring(successMark);
  }

  /// Standard output from the process as [String].
  String get stdout => (processResult.stdout as String);

  /// Returns the standard error output from the process.
  String get stderr => (processResult.stderr as String)
      .replaceAll(benchmarkError, '')
      .replaceAll(groupErrorMark, '')
      .replaceAll(successMark, '');

  /// Returns a record of type [ExitStatus].
  /// * Checks if the benchmark processes exited normally.
  /// * Checks if stderr contains the string `To do`.
  static ExitStatus aggregatedExitStatus({
    required List<BenchmarkProcessResult> results,
    required Duration duration,
    bool isVerbose = false,
  }) {
    var exitCode = ExitCode.allBenchmarksExecuted;
    var numberOfFailedBenchmarks = 0;
    var numberOfFailedGroups = 0;
    var numberOfCompletedBenchmarks = 0;
    final out = StringBuffer();

    out.writeln('-------      Summary     -------- '.style(ColorProfile.dim));
    out.write('Total run time: ${duration.mmssms.style(
      ColorProfile.success,
    )}');
    out.writeln('(Futures are awaited in parallel.)'.style(ColorProfile.dim));

    for (final result in results) {
      numberOfFailedBenchmarks += result.numberOfFailedBenchmarks;
      numberOfFailedGroups += result.numberOfFailedGroups;
      numberOfCompletedBenchmarks += result.numberOfCompletedBenchmarks;
    }

    out.writeln('Completed benchmarks: '
        '${numberOfCompletedBenchmarks.toString().style(
              ColorProfile.success,
            )}.');

    if (numberOfFailedBenchmarks > 0) {
      out.writeln('Benchmarks with errors: '
          '${numberOfFailedBenchmarks.toString().style(ColorProfile.error)}.');
      exitCode = ExitCode.someBenchmarksFailed;
    }

    if (numberOfFailedGroups > 0) {
      out.writeln('Groups with errors: '
          '${numberOfFailedGroups.toString().style(ColorProfile.error)}.\n'
          'Some benchmark may have been skipped!');
      exitCode = ExitCode.someGroupsFailed;
    }

    if ((numberOfFailedBenchmarks > 0 || numberOfFailedGroups > 0) &&
        !isVerbose) {
      out.writeln('Try using the option '
          '${'--verbose'.style(ColorProfile.emphasize)} or '
          '${'-v'.style(ColorProfile.emphasize)} '
          'for more details.');
    }

    switch (exitCode) {
      case ExitCode.someBenchmarksFailed:
        out.writeln('Exiting with code '
            '${ExitCode.someBenchmarksFailed.code}: '
            '${ExitCode.someBenchmarksFailed.description.style(
          ColorProfile.error,
        )}');
        break;
      case ExitCode.allBenchmarksExecuted:
        out.writeln('${'Completed successfully.'.style(ColorProfile.success)}\n'
            'Exiting with code: 0.');
        break;
      case ExitCode.someGroupsFailed:
        out.writeln('Exiting with code '
            '${ExitCode.someGroupsFailed.code}: '
            '${ExitCode.someGroupsFailed.description.style(
          ColorProfile.error,
        )}');
        break;
      default:
    }

    return (message: out.toString(), exitCode: exitCode);
  }
}
