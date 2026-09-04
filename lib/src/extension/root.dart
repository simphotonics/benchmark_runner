import 'dart:math' show pow;

extension Root on num {
  /// Returns the n-th root of this as a `double`.
  /// ```
  /// // Usage
  /// final a = 32.root(5);
  /// ```
  /// * Only supported for positive numbers: `(-32).root(5)` is NaN.
  /// * The dot operator has higher precedence than the minus sign: <br/>
  ///   `-32.root(5) == -(32.root(5)) == -2` <br/>
  double root(int n) {
    return pow(this, 1 / n).toDouble();
  }
}
