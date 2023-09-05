// Extension on `num` providing the method
import 'dart:math' show exp, log;

import 'package:exception_templates/exception_templates.dart';

/// `root`.
extension Root on num {
  /// Returns the n-th root of this as a `double`.
  /// * Usage: `final n = 32.root(5);`
  /// * Only supported for positive numbers.
  ///
  /// Important: The dot operator has higher precedence than the minus sign.
  ///
  /// Therefore: `-32.root(5) == -(32.root(5)) == -2`.
  ///
  /// Whereas:  `(-32).root(5)` throws an error of
  /// type `ErrorOfType<InvalidFunctionParameter`.
  double root(num n) {
    if (isNegative) {
      throw ErrorOf<num>(
          message: 'Error in extension function root($this).',
          invalidState: '$this < 0',
          expectedState: 'A positive function argument.');
    }
    return exp(log(this) / n).toDouble();
  }
}
