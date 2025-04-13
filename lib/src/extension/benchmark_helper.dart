import 'dart:math' show exp, log;

import 'package:exception_templates/exception_templates.dart';

typedef SampleSizeEstimator = ({int outer, int inner}) Function(int clockTicks);

class TimeError extends ErrorType {}

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
    Future<void> Function() f,
    int ticks,
  ) async {
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
  ({int ticks, int iter}) warmUp(
    void Function() f, {
    Duration duration = const Duration(milliseconds: 200),
    int warmUpRuns = 3,
  }) {
    int ticks = durationToTicks(duration);
    int iter = 0;
    for (var i = 0; i < warmUpRuns; i++) {
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
  Future<({int ticks, int iter})> warmUpAsync(
    Future<void> Function() f, {
    Duration duration = const Duration(milliseconds: 200),
    int warmUpRuns = 3,
  }) async {
    int ticks = durationToTicks(duration);
    int iter = 0;
    reset();
    for (var i = 0; i < warmUpRuns; i++) {
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

  /// Convert [duration] to clock ticks.
  static int durationToTicks(Duration duration) =>
      microsecondsToTicks(duration.inMicroseconds);

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

  /// Returns the result of the linear interpolation between the
  /// points (x1,y1) and (x2, y2).
  static double interpolateLin(num x, num x1, num y1, num x2, num y2) =>
      y1 + ((y2 - y1) * (x - x1) / (x2 - x1));

  /// Returns the result of the exponential interpolation between the
  /// points (x1,y1) and (x2, y2).
  static double interpolateExp(num x, num x1, num y1, num x2, num y2) {
    final t = log(y1 / y2) / (x2 - x1);
    final A = y1 * exp(t * x1);
    return A * exp(-t * x);
  }

  static SampleSizeEstimator sampleSize = sampleSizeDefault;

  /// Returns a record with type `({int outer, int inner})`
  /// holding the:
  /// * benchmark sample size `.outer`,
  /// * number of runs each score is averaged over: `.inner`.
  ///
  /// Note: An estimate of the benchmark runtime in clock ticks is given by
  /// `outer*inner*clockTicks`. The estimate does not include any setup,
  /// warm-up, or teardown functionality.
  static ({int outer, int inner}) sampleSizeDefault(int clockTicks) {
    // Estimates for the averaging used within `measure` and `measureAsync.

    if (clockTicks < 1) {
      throw ErrorOfType<TimeError>(
        message: 'Unsuitable duration detected.',
        expectedState: 'clockTicks > 0',
        invalidState: 'clockTicks: $clockTicks',
      );
    }

    const i1e3 = 200;
    const i1e4 = 100;
    const i1e5 = 15;
    const i1e6 = 1;
    const i1e7 = 1;
    const i1e8 = 1;

    // Sample size
    const s1e3 = 100;
    const s1e4 = 30;
    const s1e5 = 25;
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

    // Rescale clock ticks for other platforms. For example, on the web
    // 1 clock tick corresponds to 1 microsecond.
    if (frequency < 1e9) {
      clockTicks = 1e9 ~/ frequency * clockTicks;
    }

    return switch (clockTicks) {
      <= t1e3 => (outer: s1e3, inner: i1e3), // 1 us
      > t1e3 && <= t1e4 => (
        // 10 us
        outer: interpolateExp(clockTicks, t1e3, s1e3, t1e4, s1e4).ceil(),
        inner: interpolateExp(clockTicks, t1e3, i1e3, t1e4, i1e4).ceil(),
      ),
      > t1e4 && <= t1e5 => (
        // 100 us
        outer: interpolateExp(clockTicks, t1e4, s1e4, t1e5, s1e5).ceil(),
        inner: interpolateExp(clockTicks, t1e4, i1e4, t1e5, i1e5).ceil(),
      ),
      > t1e5 && <= t1e6 => (
        // 1ms
        outer:
            interpolateExp(
              clockTicks,
              t1e5,
              s1e5 * i1e5 / 2,
              t1e6,
              s1e6,
            ).ceil(),
        inner: i1e6,
      ),
      > t1e6 && <= t1e7 => (
        outer: interpolateExp(clockTicks, t1e6, s1e6, t1e7, s1e7).ceil(),
        inner: i1e7,
      ), // 10 ms
      > t1e7 && <= t1e8 => (
        outer: interpolateExp(clockTicks, t1e7, s1e7, t1e8, s1e8).ceil(),
        inner: i1e8,
      ), // 100 ms
      _ => (outer: s1e8, inner: i1e8),
    };
  }
}
