import 'package:benchmark_runner/benchmark_runner.dart' show Stats, Histogram;
import 'package:test/test.dart';

import 'samples/normal_random_sample.dart';

void main() {
  final stats = Stats(normalRandomSample);

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
    test('median', () {
      expect(stats.median, 10.232570379999999);
    });
    test('stdDev', () {
      expect(stats.stdDev, 5.370025848202738);
    });
    test('quartile1', () {
      expect(stats.quartile1, 6.1556007975);
    });
    test('quartile3', () {
      expect(stats.quartile3, 14.234971445);
    });
  });

  group('Histogram:', () {
    test('number of intervals', () {
      expect(stats.histogram(intervalNumber: 8).keys.length, 9);
    });
    test('range', () {
      final hist = stats.histogram(intervalNumber: 10);
      expect(hist.keys.first, stats.min);
      expect(hist.keys.last, stats.max);
    });
    test('normalization', () {
      final numberOfIntervals = 10;
      final hist = stats.histogram(
        intervalNumber: numberOfIntervals,
        normalize: true,
      );
      var sum = hist.values.fold<num>(0.0, (sum, current) => sum + current);
      expect(sum * (stats.max - stats.min) / numberOfIntervals,
          closeTo(1.0, 1e-12));
    });
    test('total count (non-normalized histograms)', () {
      final hist = stats.histogram(normalize: false);
      var sum = hist.values.fold<num>(0.0, (sum, current) => sum + current);
      expect(sum, normalRandomSample.length);
    });
  });
}
