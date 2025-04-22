import 'dart:math' show exp, log;

import 'package:exception_templates/exception_templates.dart';

import '../base/sample_size.dart';
import 'duration_to_ticks.dart';

typedef SampleSizeEstimator = SampleSize Function(int scoreEstimateAsTicks);

class TimeError extends ErrorType {}

extension BenchmarkHelper on Stopwatch {
  /// Starts, stops, and resets the [Stopwatch].
  void prime() {
    start();
    stop();
    reset();
  }

  /// Measures the runtime of [run] for [ticks] clock ticks and
  /// reports the average runtime expressed as clock ticks.
  ({int elapsedTicks, int loopCounter}) measure(
    void Function() run,
    int ticks,
  ) {
    var loopCounter = 0;
    prime();
    start();
    do {
      run();
      loopCounter++;
    } while (elapsedTicks < ticks);
    stop();
    return (
      elapsedTicks: elapsedTicks ~/ loopCounter,
      loopCounter: loopCounter,
    );
  }

  /// Measures the runtime of [f] for [ticks] clock ticks and
  /// reports the average runtime expressed as clock ticks.
  Future<({int elapsedTicks, int loopCounter})> measureAsync(
    Future<void> Function() f,
    int ticks,
  ) async {
    var loopCounter = 0;
    prime();
    start();
    do {
      await f();
      loopCounter++;
    } while (elapsedTicks < ticks);
    stop();
    return (
      elapsedTicks: elapsedTicks ~/ loopCounter,
      loopCounter: loopCounter,
    );
  }

  /// Measures the runtime of [run] for [duration] and
  /// reports the average runtime expressed as clock ticks.
  int estimate(
    void Function() run, {
    Duration duration = const Duration(milliseconds: 200),
  }) {
    prime();
    int warmUpTicks = duration.inTicks.abs();
    int loopCounter = 0;
    start();
    do {
      run();
      loopCounter++;
    } while (loopCounter < 10000 && elapsedTicks < warmUpTicks);
    stop();
    return elapsedTicks ~/ loopCounter;
  }

  /// Measures the runtime of [run] for [duration] and
  /// reports the average runtime expressed as clock ticks.
  Future<({int elapsedTicks, int loopCounter})> estimateAsync(
    Future<void> Function() run, {
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    int warmUpTicks = duration.inTicks.abs();
    int loopCounter = 0;
    prime();
    start();
    do {
      await run();
      loopCounter++;
    } while (loopCounter < 10000 && elapsedTicks < warmUpTicks);
    stop();
    return (
      elapsedTicks: elapsedTicks ~/ loopCounter,
      loopCounter: loopCounter,
    );
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
  static int secondsToTicks(int seconds) => seconds * frequency;

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

  /// Returns a record with type `({int length, int innerIterations})`
  /// holding the:
  /// * benchmark sample size `.length`,
  /// * number of runs each score is averaged over: `.innerIterations`.
  ///
  /// Note: An estimate of the total benchmark runtime in clock ticks is given by
  /// `length*innerIterations*clockTicks`. The estimate does not include any setup,
  /// warm-up, or teardown functionality.
  static SampleSize sampleSizeDefault(int scoreEstimateAsTicks) {
    // Estimates for the averaging used within `measure` and `measureAsync.
    const i1n1 = 400; // 0.1 us
    const i1e0 = 250; // 1 us
    const i1e1 = 100; // 10 us
    const i1e2 = 30; // 100 us
    const i1e3 = 1; // 1 ms
    const i1e4 = 1; // 10 ms
    const i1e5 = 1; // 100 ms

    // Sample size: length
    const s1n1 = 300; // 0.1 us
    const s1e0 = 200; // 1 us
    const s1e1 = 100; // 10 us
    const s1e2 = 70; // 100 us
    const s1e3 = 120; // 1 ms
    const s1e4 = 40; // 10 ms
    const s1e5 = 10; // 100 ms

    // Duration in us
    const t1n1 = 0.1; // 0.1 us
    const t1e0 = 1.0; // 1 us
    const t1e1 = 10.0; // 10 us
    const t1e2 = 100.0; // 100 us
    const t1e3 = 1000.0; // 1000 us = 1ms
    const t1e4 = 10000.0; // 10 ms
    const t1e5 = 100000.0; // 100 ms

    // Note: Of type double, to handle scoreEstimates < 1us.
    final scoreInMicroseconds =
        scoreEstimateAsTicks /
        BenchmarkHelper.frequency *
        Duration.microsecondsPerSecond;

    return switch (scoreInMicroseconds) {
      < t1n1 => SampleSize(length: s1n1, innerIterations: i1n1), // 1 us
      > t1n1 && <= t1e0 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1n1, s1n1, t1e0, s1e0).ceil(),
        innerIterations:
            interpolateExp(scoreInMicroseconds, t1n1, i1n1, t1e0, i1e0).ceil(),
      ), // 1 us
      > t1e0 && <= t1e1 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1e0, s1e0, t1e1, s1e1).ceil(),
        innerIterations:
            interpolateExp(scoreInMicroseconds, t1e0, i1e0, t1e1, i1e1).ceil(),
      ), // 10 us
      > t1e1 && <= t1e2 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1e1, s1e1, t1e2, s1e2).ceil(),
        innerIterations:
            interpolateExp(scoreInMicroseconds, t1e1, i1e1, t1e2, i1e2).ceil(),
      ), // 100 us
      > t1e2 && <= t1e3 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1e2, s1e2, t1e3, s1e3).ceil(),
        innerIterations:
            interpolateExp(scoreInMicroseconds, t1e2, i1e2, t1e3, i1e3).ceil(),
      ), // 1ms
      > t1e3 && <= t1e4 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1e3, s1e3, t1e4, s1e4).ceil(),
        innerIterations: i1e4,
      ), // 10 ms
      > t1e4 && <= t1e5 => SampleSize(
        length:
            interpolateExp(scoreInMicroseconds, t1e4, s1e4, t1e5, s1e5).ceil(),
        innerIterations: i1e5,
      ), // 100 ms
      _ => SampleSize(length: s1e5, innerIterations: i1e5),
    };
  }
}
