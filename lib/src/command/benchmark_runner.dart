import 'dart:io';

import 'package:args/args.dart' show ArgResults;
import 'package:args/command_runner.dart';

import '../enum/exit_code.dart' show ExitCode;
import 'export_command.dart';
import 'report_command.dart';

class BenchmarkRunner._([
  super.executableName = 'benchmark_runner',
  super.description =
      'A command line utility for running benchmarks '
      'and printing/exporting score reports.',
]) extends CommandRunner<void> {
  static BenchmarkRunner? _instance;

  @override
  String? get usageFooter =>
      '\nNote: Benchmark files are Dart files ending with \'_benchmark.dart\'.';

  factory() {
    return _instance ?? BenchmarkRunner._()
      ..addCommand(ExportCommand())
      ..addCommand(ReportCommand())
      ..argParser.addFlag(
        'verbose',
        abbr: 'v',
        defaultsTo: false,
        negatable: false,
        help: 'Enable to show more info and error messages.',
      )
      ..argParser.addFlag(
        'isMonochrome',
        abbr: 'm',
        negatable: false,
        help: 'Disables colorized reporting.',
      );
  }

  @override
  final String invocation =
      'dart run benchmark_runner <command> '
      '[arguments] <path to directory|file>';

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    try {
      return await super.runCommand(topLevelResults);
    } on UsageException catch (e) {
      print(e.message);
      print(e.usage);
      exit(ExitCode.usageException.index);
    } on FileSystemException catch (e) {
      print(e);
      exit(ExitCode.pathNotFoundException.index);
    }
  }
}
