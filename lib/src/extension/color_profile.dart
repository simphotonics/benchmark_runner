import 'package:ansi_modifier/ansi_modifier.dart';

/// Defines styles and colors used to print benchmark reports to a terminal.
extension ColorProfile on Ansi {
  /// Style of an error message
  static Ansi error = Ansi.red;

  /// Style of a group label.
  static Ansi group = Ansi.defaultFont;

  /// Style of a benchmark label.
  static Ansi benchmark = Ansi.defaultFg;

  /// Style of an asynchronous benchmark label.
  static Ansi asyncBenchmark = Ansi.defaultFont;

  /// Style used to print a sample mean.
  static Ansi mean = Ansi.green;

  /// Style used to print a sample median.
  static Ansi median = Ansi.blue;

  /// Style used to color the histogram block containing the mean value.
  static Ansi meanHistogramBlock = mean;

  /// Style used to print the histogram block containing the median value.
  static Ansi medianHistogramBlock = median;

  /// Style used to print the histogram block containing mean and median.
  static Ansi meanMedianHistogramBlock = Ansi.cyan;

  /// Style used to print dimmed console messages.
  static Ansi dim = Ansi.grey;

  /// Style used to print emphasized console messages.
  static Ansi emphasize = Ansi.bold;

  /// Style used to print highlighted console messages.
  static Ansi highlight = Ansi.yellow;

  /// Style used to print success messages.
  static Ansi success = Ansi.green;
}
