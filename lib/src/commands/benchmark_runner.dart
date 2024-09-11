import 'package:args/command_runner.dart';

import 'export_command.dart';
import 'report_command.dart';

class BenchmarkRunner extends CommandRunner {
  BenchmarkRunner._()
      : super(
          'benchmark',
          'Runs benchmarks, exports score reports.',
        );

  static BenchmarkRunner? _instance;

  /// Name of the command option
  /// that enables displaying error messages.
  static const verbose = 'verbose';

  /// Name of the command option that enables colorized
  /// outout.
  static const color = 'color';

  @override
  String? get usageFooter =>
    '\nNote: Benchmark files are dart files ending with \'_benchmark.dart\'.';

  factory BenchmarkRunner() {
    return _instance ?? BenchmarkRunner._()
      ..addCommand(ExportCommand())
      ..addCommand(ReportCommand())
      ..argParser.addFlag(
        verbose,
        abbr: 'v',
        defaultsTo: false,
        negatable: false,
        help: 'Enable to show more info and error messages.',
      )
      ..argParser.addFlag(
        color,
        abbr: 'c',
        defaultsTo: true,
        help: 'Enables colorized reporting.',
      );
  }

  @override
  final String invocation = 'dart run benchmark <command> [arguments] [path to directory or file]';
}
