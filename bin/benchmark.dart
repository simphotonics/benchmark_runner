import 'package:benchmark_runner/benchmark_runner.dart';

/// The script usage.
const usage =
    '------------------------------------------------------------------------\n'
    'Usage: benchmark_exporter [options] [<benchmark-directory/benchmark-file>]'
    '\n\n'
    'Note: Benchmark files are dart files ending with \'_benchmark.dart.\'\n\n';

Future<void> main(List<String> args) async {

  final commandRunner = BenchmarkRunner();
  commandRunner.run(args);

}
