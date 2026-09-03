class const SampleSize({
  /// The size of the required score sample.
  required final int length,

  /// The number of runs each measurement is averaged over.
  final int innerIterations = 1,
}) {
  @override
  String toString() {
    return 'SampleSize(length: $length, innerIterations: $innerIterations)';
  }
}
