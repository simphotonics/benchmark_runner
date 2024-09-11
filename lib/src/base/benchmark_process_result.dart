import 'dart:collection';
import 'dart:convert' show Encoding, Utf8Codec;
import 'dart:io' show File, Process, ProcessResult;

import 'package:ansi_modifier/ansi_modifier.dart';
import '../enums/exit_code.dart';
import '../extensions/color_profile.dart';
import '../extensions/duration_formatter.dart';
import '../extensions/string_utils.dart';

/// A class holding:
/// * the name of the executable that was used to run the benchmark,
/// * the list of arguments,
/// * and the resulting [ProcessResult] object.
class BenchmarkProcessResult {
  BenchmarkProcessResult({
    required this.executable,
    required List<String> arguments,
    required this.processResult,
    required this.benchmarkFile,
  }) : arguments = UnmodifiableListView(arguments);

  final String executable;
  final UnmodifiableListView<String> arguments;
  final ProcessResult processResult;
  final File benchmarkFile;

  /// Returns the command used to generate the benchmark scores.
  ///
  /// Set [isBrief] to true to strips the argument
  /// `--define=isBenchmarkProcess=true`.
  String command({bool isBrief = true}) {
    final args = switch (isBrief) {
      true => arguments
          .where((arg) => arg != '--define=isBenchmarkProcess=true')
          .join(' '),
      false => arguments.join(' ')
    };
    return executable +
        (args.isEmpty
            ? ' ${benchmarkFile.path}'
            : ' $args ${benchmarkFile.path}');
  }
}

/// A record holding:
/// * an exit message,
/// * an exit code.
typedef ExitStatus = ({String message, ExitCode exitCode});

/// Extension on [Process].
/// Adds the static method `runBenchmark`.
extension BenchmarkProcess on Process {
  /// Runs a benchmark and returns an instance of
  /// [BenchmarkProcessResult].
  static Future<BenchmarkProcessResult> runBenchmark({
    required String executable,
    List<String> arguments = const [],
    required File benchmarkFile,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = const Utf8Codec(), // Enables histogram output
    Encoding? stderrEncoding = const Utf8Codec(), //               on windows.
  }) {
    return Process.run(executable, [...arguments, benchmarkFile.path],
            workingDirectory: workingDirectory,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            runInShell: runInShell,
            stdoutEncoding: stdoutEncoding,
            stderrEncoding: stderrEncoding)
        .then<BenchmarkProcessResult>((processResult) {
      return BenchmarkProcessResult(
        executable: executable,
        arguments: arguments,
        processResult: processResult,
        benchmarkFile: benchmarkFile,
      );
    });
  }
}

extension BenchmarkUtils on BenchmarkProcessResult {
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
  String get stdout => (processResult.stdout as String).trimRight();

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
    out.writeln('Total run time: ${duration.ssms.style(
      ColorProfile.success,
    )}');

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
          'Some benchmarks may have been skipped!');
      exitCode = ExitCode.someGroupsFailed;
    }

    if ((numberOfFailedBenchmarks > 0 || numberOfFailedGroups > 0) &&
        !isVerbose) {
      out.writeln('Try using the option '
          '${'--verbose'.style(ColorProfile.emphasize + Ansi.yellow)} or '
          '${'-v'.style(ColorProfile.emphasize + Ansi.yellow)} '
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
