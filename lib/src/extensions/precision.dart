import 'dart:math' show log;

const ln10 = 2.3025850929940456;

extension Precision on double {
  /// Returns the number of leading zeros.
  /// Usage:
  /// ```
  /// int zeros = 0.00045.leadingZeros; // zeros == 3
  /// ```
  int get leadingZeros {
    var result = (log(1.0 / abs()) ~/ ln10);
    return result.isNegative ? 0 : result;
  }

  /// Returns a decimal-string point representation of this number
  /// with [leadingZeros] + [nonZeroFractionalDigits] digits after the decimal
  /// point.
  String toStringAsFixedDigits([int nonZeroFractionalDigits = 2]) =>
      toStringAsFixed(
        leadingZeros + nonZeroFractionalDigits,
      );
}
