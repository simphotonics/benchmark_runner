import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  group('Main command:', () {
    test('usage', () async {
      final process = await TestProcess.start(
        'dart',
        ['run', 'benchmark_runner'],
      );

      final rest = process.stdout.rest;
      final result = await rest.join('\n');

      expect(
        result,
        'Runs benchmarks. Prints and exports score reports.\n'
        '\n'
        'Usage: dart run benchmark_runner <command> [arguments] <path to directory|file>\n'
        '\n'
        'Global options:\n'
        '-h, --help          Print this usage information.\n'
        '-v, --verbose       Enable to show more info and error messages.\n'
        '-c, --[no-]color    Enables colorized reporting.\n'
        '                    (defaults to on)\n'
        '\n'
        'Available commands:\n'
        '  export   Exports benchmark scores. A custom file extension and directory may be specified.\n'
        '  report   Runs benchmarks and prints a score report to stdout.\n'
        '\n'
        'Run "benchmark_runner help <command>" for more information about a command.\n'
        '\n'
        'Note: Benchmark files are dart files ending with \'_benchmark.dart\'.',
      );

      // Assert that the process exits with code 0.
      await process.shouldExit(0);
    });
  });
  group('Sub-command report:', () {
    test('usage', () async {
      final process = await TestProcess.start(
        'dart',
        ['run', 'benchmark_runner', 'report', '-h'],
      );

      final usage = await process.stdout.rest.join('\n');

      expect(
          usage,
          'Runs benchmarks and prints a score report to stdout.\n'
          '\n'
          'Usage: benchmark_runner report [arguments] <path to directory|file>\n'
          '-h, --help    Print this usage information.\n'
          '\n'
          'Run "benchmark_runner help" to see global options.');

      // Assert that the process exits with code 0.
      await process.shouldExit(0);
    });
    test('run benchmark file', () async {
      final process = await TestProcess.start(
        'dart',
        ['run', 'benchmark_runner', 'report', 'test/samples/sample_benchmark.dart'],
      );
      await process.shouldExit(0);
    });
    test('scan directory', () async {
      final process = await TestProcess.start(
        'dart',
        ['run', 'benchmark_runner', 'report', 'test/samples'],
      );
      await process.shouldExit(0);
    });
  });
  group('Sub-command export:', () {
    test('usage', () async {
      final process = await TestProcess.start(
        'dart',
        ['run', 'benchmark_runner', 'export', '-h'],
      );

      final usage = await process.stdout.rest.join('\n');

      expect(
        usage,
        'Exports benchmark scores. A custom file extension and directory may be specified.\n'
        '\n'
        'Usage: benchmark_runner export [arguments]\n'
        '-h, --help         Print this usage information.\n'
        '-e, --extension    Set file extension of exported files.\n'
        '                   (defaults to "txt")\n'
        '-o, --outputDir    Directory must exist. Score files will be written to it.\n'
        '\n'
        'Run "benchmark_runner help" to see global options.',
      );

      // Assert that the process exits with code 0.
      await process.shouldExit(0);
    });
  });
}
