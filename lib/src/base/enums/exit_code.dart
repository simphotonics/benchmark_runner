/// Predefined benchmark process exit codes.
enum ExitCode {
  allBenchmarksExecuted('All benchmarks executed.'),
  noBenchmarkFilesFound('No benchmark files found.'),
  someBenchmarksFailed('Some benchmarks failed.'),
  someGroupsFailed('Some groups failed.');

  const ExitCode(this.description);

  /// Integer exit code.
  int get code => index;

  /// Exit code description.
  final String description;
}
