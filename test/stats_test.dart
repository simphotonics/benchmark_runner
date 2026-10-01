// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_runner/benchmark_runner.dart' show Stats, Histogram;
import 'package:test/test.dart';

import 'samples/normal_random_sample.dart';

void main() {
  final stats = Stats(normalRandomSample);

  // Mid mark
  final sampleOdd = [-10, -8, -5, -2, -1, 0, 1, 3, 6, 8, 10];

  // Mid mark
  final sampleEven = [
    -16,
    -12,
    -10,
    -8,
    -5,
    -2,
    -1,
    0, // <
    1, // <
    3,
    6,
    8,
    10,
    12,
    14,
    17,
  ];

  group('Basic:', () {
    test('min', () {
      expect(stats.min, -1.949079932);
    });
    test('max', () {
      expect(stats.max, 26.55182824);
    });
    test('mean', () {
      expect(stats.mean, closeTo(10.168769294545003, 1e-12));
    });
    test('median statsEven', () {
      final statsEven = Stats(sampleEven);
      expect(statsEven.median, 0.5);
    });
    test('median statsOdd', () {
      final statsOdd = Stats(sampleOdd);
      expect(statsOdd.median, 0);
    });
    test('stdDev', () {
      expect(stats.stdDev, 5.370025848202738);
    });
    test('quartile1 statsEven', () {
      final statsEven = Stats(sampleEven);
      expect(statsEven.quartile1, -6.5);
    });
    test('quartile1 statsOdd', () {
      final statsOdd = Stats(sampleOdd);
      expect(statsOdd.quartile1, -5);
    });
    test('quartile3 statsEven', () {
      final statsEven = Stats(sampleEven);
      expect(statsEven.quartile3, 9);
    });
    test('quartile3 statsOdd', () {
      final statsOdd = Stats(sampleOdd);
      expect(statsOdd.quartile3, 6);
    });
  });

  group('Histogram:', () {
    test('number of intervals', () {
      expect(stats.histogram(intervals: 8).keys.length, 9);
    });
    test('range', () {
      final hist = stats.histogram(intervals: 10);
      expect(hist.keys.first, stats.min);
      expect(hist.keys.last, stats.max);
    });
    test('normalization', () {
      final numberOfIntervals = 10;
      final hist = stats.histogram(
        intervals: numberOfIntervals,
        normalize: true,
      );
      var sum = hist.values.fold<num>(0.0, (sum, current) => sum + current);
      expect(
        sum * (stats.max - stats.min) / numberOfIntervals,
        closeTo(1.0, 1e-12),
      );
    });
    test('total count (non-normalized histograms)', () {
      final hist = stats.histogram(normalize: false);
      var sum = hist.values.fold<num>(0.0, (sum, current) => sum + current);
      expect(sum, normalRandomSample.length);
    });
  });

  group('BlockHistogram:', () {
    test('a', () {
      expect(
        stats.blockHistogram(),
        '▁▄█' + Ansi.cyan.code + '▉' + Ansi.reset.code + '▉█▂▁▁',
      );
    });
  });
}
