import 'dart:math' show exp, log;

extension BenchmarkHelper on Stopwatch {
  /// Measures the runtime of [f] for [ticks] clock ticks and
  /// reports the average runtime expressed as clock ticks.
  ({int ticks, int iter}) measure(void Function() f, int ticks) {
    var iter = 0;
    reset();
    start();
    do {
      f();
      iter++;
    } while (elapsedTicks < ticks);
    return (ticks: elapsedTicks ~/ iter, iter: iter);
  }

  /// Measures the runtime of [f] for [ticks] clock ticks and
  /// reports the average runtime expressed as clock ticks.
  Future<({int ticks, int iter})> measureAsync(
      Future<void> Function() f, int ticks) async {
    var iter = 0;
    reset();
    start();
    do {
      await f();
      iter++;
    } while (elapsedTicks < ticks);
    return (ticks: elapsedTicks ~/ iter, iter: iter);
  }

  /// Measures the runtime of [f] for [duration] and
  /// reports the average runtime expressed as clock ticks.
  ({int ticks, int iter}) warmup(
    void Function() f, {
    Duration duration = const Duration(milliseconds: 200),
    int preRuns = 3
  }) {
    var ticks = microsecondsToTicks(duration.inMicroseconds);
    var iter = 0;
    for (var i = 0; i < preRuns; i++) {
      f();
    }
    reset();
    start();
    do {
      f();
      iter++;
    } while (elapsedTicks < ticks);
    return (ticks: elapsedTicks ~/ iter, iter: iter);
  }

  /// Measures the runtime of [f] for [duration] and
  /// reports the average runtime expressed as clock ticks.
  Future<({int ticks, int iter})> warmupAsync(Future<void> Function() f,
      {Duration duration = const Duration(milliseconds: 200),
      int preRuns = 3}) async {
    var ticks = microsecondsToTicks(duration.inMicroseconds);
    var iter = 0;
    reset();
    for (var i = 0; i < preRuns; i++) {
      await f();
    }
    start();
    do {
      await f();
      iter++;
    } while (elapsedTicks < ticks);
    return (ticks: elapsedTicks ~/ iter, iter: iter);
  }

  /// Stopwatch frequency: ticks per second.
  static final frequency = Stopwatch().frequency;

  /// Converts clock [ticks] to seconds.
  static double ticksToSeconds(int ticks) => ticks / BenchmarkHelper.frequency;

  /// Converts clock [ticks] to microseconds.
  static double ticksToMicroseconds(int ticks) =>
      ticks / (BenchmarkHelper.frequency / 1000000);

  /// Converts clock [ticks] to milliseconds.
  static double ticksToMilliseconds(int ticks) =>
      ticks / (BenchmarkHelper.frequency / 1000);

  /// Converts [seconds] to clock ticks.
  static int secondsToTicks(int seconds) => seconds * BenchmarkHelper.frequency;

  /// Converts [milliseconds] to clock  ticks.
  static int millisecondsToTicks(int milliseconds) =>
      milliseconds * frequency ~/ 1000;

  /// Converts [microseconds] to clock ticks.
  static int microsecondsToTicks(int microseconds) =>
      microseconds * frequency ~/ 1000000;

  /// Returns a benchmark sample size given a benchmark runtime in clock ticks.
  static ({int outer, int inner}) sampleSizeStep(int ticks) => switch (ticks) {
        < 1000 => (outer: 100, inner: 300),
        < 10000 => (outer: 100, inner: 200),
        < 100000 => (outer: 100, inner: 25),
        < 1000000 => (outer: 100, inner: 10),
        < 10000000 => (outer: 100, inner: 0),
        < 100000000 => (outer: 20, inner: 0),
        _ => (outer: 10, inner: 0),
      };

  /// Returns the result of the linear interpolation between the
  /// points (x1,y1) and (x2, y2).
  static double interpolateLin(
    num x,
    num x1,
    num y1,
    num x2,
    num y2,
  ) =>
      y1 + ((y2 - y1) * (x - x1) / (x2 - x1));

  /// Returns the result of the exponential interpolation between the
  /// points (x1,y1) and (x2, y2).
  static double interpolateExp(num x, num x1, num y1, num x2, num y2) {
    final t = log(y1 / y2) / (x2 - x1);
    final A = y1 * exp(t * x1);
    return A * exp(-t * x);
  }

  /// Returns a benchmark sample size given an estimate score expressed
  /// in clock ticks.
  static ({int outer, int inner}) sampleSize(int ticks) {
    // Estimates for the averaging used within `measure` and `measureAsync.
    const i1e3 = 200;
    const i1e4 = 100;
    const i1e5 = 1;
    const i1e6 = 1;
    const i1e7 = 1;
    const i1e8 = 1;

    // Sample size
    const s1e3 = 150;
    const s1e4 = 75;
    const s1e5 = 150;
    const s1e6 = 60;
    const s1e7 = 50;
    const s1e8 = 10;

    // Clock ticks
    const t1e3 = 1000; // 1 us
    const t1e4 = 10000; // 10 us
    const t1e5 = 100000; // 100 us
    const t1e6 = 1000000; // 1000 us = 1ms
    const t1e7 = 10000000; // 10 ms;
    const t1e8 = 100000000; // 100 ms;

    return switch (ticks) {
      < t1e3 => (outer: s1e3, inner: i1e3), // 1 us
      < t1e4 => (
          // 10 us
          outer: interpolateExp(ticks, t1e3, s1e3, t1e4, s1e4).ceil(),
          inner: interpolateExp(ticks, t1e3, i1e3, t1e4, i1e4).ceil()
        ),
      < t1e5 => (
          // 100 us
          outer: interpolateExp(ticks, t1e4, s1e4, t1e5, s1e5).ceil(),
          inner: interpolateExp(ticks, t1e4, i1e4, t1e5, i1e5).ceil()
        ),
      < t1e6 => (
          // 1ms
          outer: interpolateExp(ticks, t1e5, s1e5, t1e6, s1e6).ceil(),
          inner: interpolateExp(ticks, t1e5, i1e5, t1e6, i1e6).ceil(),
        ),
      < t1e7 => (
          outer: interpolateExp(ticks, t1e6, s1e6, t1e7, s1e7).ceil(),
          inner: i1e7
        ), // 10 ms
      < t1e8 => (
          outer: interpolateExp(ticks, t1e7, s1e7, t1e8, s1e8).ceil(),
          inner: i1e8
        ), // 100 ms
      _ => (outer: s1e8, inner: i1e8),
    };
  }
}
