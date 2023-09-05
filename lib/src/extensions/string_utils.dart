import 'dart:io';
import '../utils/environment.dart';

const errorMark = '  . .-. .-. --- .-.';

// /// Writes [input] to stdout. If the environment is a benchmark process
// /// the String [marker] is prepended.
// void write(String input) {
//   if (isBenchmarkProcess) {
//     stdout.write('$marker$input');
//   } else {
//     stdout.write(input);
//   }
// }

// /// Writes [input] to stdout adding a newline symbol.
// /// If the environment is a benchmark process
// /// the String [marker] is prepended.
// void writeln(String input) {
//   if (isBenchmarkProcess) {
//     stdout.write('$marker$input\n');
//   } else {
//     stdout.write('$input\n');
//   }
// }

/// Writes mark to stderr.
void addErrorMark([String mark = errorMark]) {
  if (isBenchmarkProcess) {
    stderr.writeln(mark);
  }
}

extension StringBlock on String {
  /// Returns the [String] resulting by prefixing each
  /// line with `chars` (repeated `indentMultiplier` times).
  String indentLines(
    int indentMultiplier, {
    String indentChars = ' ',
    bool skipFirstLine = false,
  }) {
    var indentString = indentChars * indentMultiplier;
    if (isEmpty) {
      return (skipFirstLine) ? '' : indentString;
    }
    final lines = split('\n');
    if (skipFirstLine) {
      final out = lines.map((item) => indentString + item).toList();
      out[0] = lines[0];
      return out.join('\n').trimRight();
    } else {
      return lines.map((item) => indentString + item).join('\n').trimRight();
    }
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
