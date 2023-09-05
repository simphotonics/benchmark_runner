import 'dart:async';

import 'extensions/string_utils.dart';
import 'utils/ansi_modifier.dart';
import 'utils/environment.dart';

class _Group {
  _Group(this.description, this.body);

  /// Group description
  final String description;

  /// Group body
  final FutureOr<void> Function() body;

  void run() {
    // Check for nested groups:
    final parentGroup = Zone.current[#_group] as _Group?;
    if (parentGroup != null) {
      throw UnsupportedError('${'Nested benchmark groups are '
              'not supported! '.colorize(AnsiModifier.red)}'
          'Check groups: ${parentGroup.description} > $description');
    }
    return runZonedGuarded(
      body,
      ((error, stack) {
        print('  $error'.colorize(AnsiModifier.red));
        if (isVerbose) {
          print(stack.toString().indentLines(2, skipFirstLine: true));
        }
      }),
      zoneValues: {#_group: this},
      zoneSpecification: ZoneSpecification(
        print: (Zone self, parent, zone, String value) {
          // Add indent
          parent.print(zone, '  $value');
        },
      ),
    );
  }

  Future<void> asyncRun() async {
    // Check for nested groups:
    final parentGroup = Zone.current[#_group] as _Group?;
    if (parentGroup != null) {
      throw UnsupportedError('${'Nested benchmark groups are '
              'not supported! '.colorize(AnsiModifier.red)}'
          'Check groups: ${parentGroup.description} > $description');
    }
    return runZonedGuarded(
      body,
      ((error, stack) {
        print('  $error'.colorize(AnsiModifier.red));
        if (isVerbose) {
          print(stack.toString().indentLines(2, skipFirstLine: true));
        }
      }),
      zoneValues: {#_group: this},
      zoneSpecification: ZoneSpecification(
        print: (Zone self, parent, zone, String value) {
          // Add indent
          parent.print(zone, '  $value');
        },
      ),
    );
  }
}

/// Defines a benchmark group.
///
/// Note: Groups may not be nested.
void group(
  String description,
  void Function() body,
) {
  print(description.colorize(AnsiModifier.cyanBold));
  final instance = _Group(description, body);
  instance.run();
}

/// Defines an asynchronous benchmark group.
///
/// Note: Groups may not be nested.
Future<void> asyncGroup(
  String description,
  Future<void> Function() body,
) async {
  print(description.colorize(AnsiModifier.magentaBold));
  final instance = _Group(description, body);
  return instance.asyncRun();
}
