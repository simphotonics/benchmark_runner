class SampleSize {
  const SampleSize({required this.length, this.innerIterations = 1});

  /// The size of the required score sample.
  final int length;

  /// The number of runs each measurement is averaged over.
  final int innerIterations;

  @override
  String toString() {
    return 'SampleSize(length: $length, innerIterations: $innerIterations)';
  }
}
