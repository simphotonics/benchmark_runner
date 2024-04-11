extension DurationFormatter on Duration {
  /// Converts the duration into a String with
  /// format: days:hours:minutes:seconds.
  ///
  /// * Omits the entries for days and hours if these are zero.
  /// * Pads integers to width 2.
  ///
  /// Usage:
  /// ```
  /// final d = Duration(days: 1234, hours: 3, minutes: 45, seconds: 10);
  /// print(d.format()); // Prints: 1234d:03h:45m:10s
  /// ```
  String get mmss {
    final days = inDays;
    final hours = inHours - 24 * days;
    final minutes = inMinutes - 60 * hours - 1440 * days;
    final seconds = inSeconds - 60 * minutes - 3600 * hours - 86400 * days;

    final out = StringBuffer();
    if (days > 0) {
      out.write(days.toString().padLeft(2, '0'));
      out.write('d:');
    }
    if (hours > 0) {
      out.write(hours.toString().padLeft(2, '0'));
      out.write('h:');
    }
    out.write(minutes.toString().padLeft(2, '0'));
    out.write('m:');
    out.write(seconds.toString().padLeft(2, '0'));
    out.write('s');
    return out.toString();
  }

  /// Converts the duration into a String with
  /// format: minutes:seconds:microseconds.
  ///
  /// * Omits the entry for minutes if it is zero.
  /// * Pads integers to width 2.
  String get ssms {
    final minutes = inMinutes;
    final seconds = inSeconds - 60 * minutes;
    final milliseconds = inMilliseconds - 1000 * seconds - 60000 * minutes;
    final out = StringBuffer('[');

    if (minutes > 0) {
      out.write(minutes.toString().padLeft(2, '0'));
      out.write('m:');
    }
    out.write(seconds.toString().padLeft(2, '0'));
    out.write('s:');

    out.write(milliseconds.toString().padLeft(3, '0'));
    out.write('ms]');
    return out.toString();
  }

  /// Converts the duration into a String with
  /// format: seconds:milliseconds:microseconds.
  ///
  /// * Omits the entry for seconds if it is zero.
  /// * Pads integers to width 2.
  String get msus {
    final seconds = inSeconds;
    final milliseconds = inMilliseconds - 1000 * seconds;
    final microseconds =
        inMicroseconds - 1000 * milliseconds - 1000000 * seconds;
    final out = StringBuffer('[');

    if (seconds > 0) {
      out.write(seconds.toString().padLeft(2, '0'));
      out.write('s:');
    }
    out.write(milliseconds.toString().padLeft(3, '0'));
    out.write('ms:');

    out.write(microseconds.toString().padLeft(3, '0'));
    out.write('us]');
    return out.toString();
  }
}
