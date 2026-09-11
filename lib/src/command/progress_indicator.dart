import 'dart:async' show StreamSubscription;
import 'dart:io' show stdout;

import 'package:ansi_modifier/ansi_modifier.dart';

import '../extension/color_profile.dart' show ColorProfile;
import '../extension/duration_formatter.dart' show DurationFormatter;

StreamSubscription<String> progressIndicatorSubscription() {
  final stream = Stream<String>.periodic(
    const Duration(milliseconds: 250),
    (i) =>
        'Progress timer: '.style(ColorProfile.dim) +
        Duration(milliseconds: i * 250).ssms.style(Ansi.green),
  );
  const cursorToStartOfLine = Ansi.cursorToColumn(1);

  return stream.listen((event) {
    stdout.write(cursorToStartOfLine);
    stdout.write(event);
    stdout.write(cursorToStartOfLine);
  });
}
