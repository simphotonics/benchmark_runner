extension DurationToTicks on Duration {
  static final frequency = Stopwatch().frequency;

  /// Returns `this` duration as clock ticks.
  int get inTicks => inMicroseconds * frequency ~/ 1000000;
}
