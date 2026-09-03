/// Benchmark process exit codes.
/// The enum index represents the integer exit code.
enum ExitCode(
  /// Exit code description.
  final String description,
) {
  /// Exit code: 0. All benchmarks executed.
  allBenchmarksExecuted('All benchmarks executed.'),

  /// Exit code: 1. A "UsageException occurred."
  usageException('A "UsageException" occurred.'),

  /// Exit code:2. No benchmark files found.
  noBenchmarkFilesFound('No benchmark files found.'),

  /// Exit code: 3. A "PathNotFoundException" occurred.
  pathNotFoundException('A "PathNotFoundException" occurred.'),

  /// Exit code: 4. Some benchmarks failed.
  someBenchmarksFailed('Some benchmarks failed.'),

  /// Exit code: 5 Some groups failed.
  someGroupsFailed('Some groups failed.'),
}
