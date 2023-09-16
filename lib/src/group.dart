import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_runner/src/extensions/duration_formatter.dart';

import 'extensions/color_profile.dart';
import 'extensions/string_utils.dart';
import 'utils/environment.dart';

class Group {
  Group(this.description, this.body);

  /// Group description
  final String description;

  /// Group body
  final FutureOr<void> Function() body;

  FutureOr<void> run() async{
    // Check for nested groups:
    final parentGroup = Zone.current[#group] as Group?;
    if (parentGroup != null) {
      throw UnsupportedError('${'Nested benchmark groups are '
              'not supported! '.style(ColorProfile.error)}'
          'Check group ${description.style(ColorProfile.emphasize)} defined '
          'within group ${parentGroup.description.style(
        ColorProfile.emphasize,
      )}');
    }
    final watch = Stopwatch()..start();
    await runZonedGuarded(
      body,
      ((error, stack) {
        addErrorMark(groupErrorMark);
        print(
          '${watch.elapsed.mmssms.style(ColorProfile.dim)} '
          '$description '
          '${error.toString().style(ColorProfile.error)}',
        );
        if (isVerbose) {
          print(stack.toString().indentLines(2, indentMultiplierFirstLine: 2));
        }
      }),
      zoneValues: {#group: this},
    );
  }
}

/// Defines a benchmark group.
///
/// Note: Groups may not be nested.
FutureOr<void> group(
  String description,
  FutureOr<void> Function() body,
) {
  description = description.trimRight();
  description = description.endsWith(':') ? description : '$description:';
  final instance = Group(
    description.style(ColorProfile.group),
    body,
  );
  return instance.run();
}
