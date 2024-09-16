import 'package:args/command_runner.dart';

import 'export_command.dart';
import 'report_command.dart';

class BenchmarkRunner extends CommandRunner {
  BenchmarkRunner._()
      : super(
          'benchmark_runner',
          'Runs benchmarks. Prints and exports score reports.',
        );

  static BenchmarkRunner? _instance;

  @override
  String? get usageFooter =>
      '\nNote: Benchmark files are dart files ending with \'_benchmark.dart\'.';

  factory BenchmarkRunner() {
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
      'dart run benchmark_runner <command> [arguments] <path to directory|file>';
}
