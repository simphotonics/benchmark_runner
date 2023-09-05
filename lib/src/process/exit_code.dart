/// Predefined benchmark process exit codes.
enum ExitCode {
  allBenchmarksPassed('All benchmarks passed.'),
  noBenchmarkFilesFound('No benchmark files found.'),
  someBenchmarksFailed('Some benchmarks failed.');

  const ExitCode(this.description);

  /// Integer exit code.
  int get code => index;

  /// Exit code description.
  final String description;
}
