import 'dart:io';
import '../utils/environment.dart';

const errorMark = '. .-. .-. --- .-.';
const groupErrorMark = r'.--. ..- --- .-. --. / .-. --- .-. .-. .';
const successMark = '... ..- -.-. -.-. . ... ...';
const hourGlass = '\u29D6 ';

/// Writes a mark to stderr. Is used by `BenchmarkProcessResult` to
/// count errors.
void addErrorMark([String mark = errorMark]) {
  if (isBenchmarkProcess) {
    stderr.write(mark);
  }
}

void addSuccessMark([String mark = successMark]) {
  if (isBenchmarkProcess) {
    stderr.write(mark);
  }
}

extension StringBlock on String {
  /// Returns the [String] resulting by prefixing each
  /// line with `indentChars` (repeated `indentMultiplier` times).
  /// * By default the first line is not indented.
  /// * The indent the first line set [indentMultiplierFirstLine]
  /// to the required value.
  String indentLines(
    int indentMultiplier, {
    String indentChars = ' ',
    int indentMultiplierFirstLine = 0,
  }) {
    final indentString = indentChars * indentMultiplier;
    final indentStringFirstLine = indentChars * indentMultiplierFirstLine;

    if (isEmpty) {
      return indentStringFirstLine;
    }
    final lines = split('\n');
    final out = lines.map((line) => indentString + line).toList();
    out[0] = indentStringFirstLine + lines[0];
    return out.join('\n');
  }

  /// Returns the number of times `substring` is found in `this`.
  /// * Substrings are counted in a non-overlapping fashion.
  /// * Returns `1` if `substring` is the empty String.
  int countSubstring(String substring) {
    final skip = substring.length;
    var count = 0;
    var index = 0;

    do {
      index = indexOf(substring, index);
      if (index == -1) {
        break;
      } else {
        ++count;
        index += skip;
      }
    } while (index > 0);
    return count;
  }
}
