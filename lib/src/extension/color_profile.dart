import 'package:ansi_modifier/ansi_modifier.dart';

/// Defines styles and colors used to print benchmark reports to a terminal.
extension ColorProfile on FontModifier {
  /// Style of an error message
  static FontModifier error = Ansi.red;

  /// Style of a group label.
  static FontModifier group = Ansi.defaultFont;

  /// Style of a benchmark label.
  static FontModifier benchmark = Ansi.defaultForeground;

  /// Style of an asynchronous benchmark label.
  static FontModifier asyncBenchmark = Ansi.defaultFont;

  /// Style used to print a sample mean.
  static FontModifier mean = Ansi.green;

  /// Style used to print a sample median.
  static FontModifier median = Ansi.blue;

  /// Style used to color the histogram block containing the mean value.
  static FontModifier meanHistogramBlock = mean;

  /// Style used to print the histogram block containing the median value.
  static FontModifier medianHistogramBlock = median;

  /// Style used to print the histogram block containing mean and median.
  static FontModifier meanMedianHistogramBlock = Ansi.cyan;

  /// Style used to print dimmed console messages.
  static FontModifier dim = Ansi.grey;

  /// Style used to print emphasized console messages.
  static FontModifier emphasize = Ansi.bold;

  /// Style used to print highlighted console messages.
  static FontModifier highlight = Ansi.yellow;

  /// Style used to print success messages.
  static FontModifier success = Ansi.green;
}
