import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../extension/color_profile.dart';
import '../extension/string_utils.dart';

abstract class const Group(
  /// The group description.
  final String description,
) {
  /// Throws an error if this group is defined within another group.
  void _throwIfNested() {
    // Check for nested groups:
    final parentGroup = Zone.current[#group] as Group?;
    if (parentGroup != null) {
      throw UnsupportedError(
        '${'Nested groups detected! '.style(ColorProfile.error)}'
        'Group ${description.style(ColorProfile.emphasize)} defined '
        'within group ${parentGroup.description.style(ColorProfile.emphasize)}',
      );
    }
  }
}

class const SyncGroup(
  super.description,

  /// Group body
  final void Function() body,
) extends Group {
  // Runs the callback body.
  void run() {
    _throwIfNested();
    final watch = Stopwatch()..start();
    runZonedGuarded(body, ((error, stack) {
      reportError(
        error,
        stack,
        description: description,
        duration: watch.elapsed,
        errorMark: groupErrorMark,
      );
    }), zoneValues: {#group: this});
  }
}

class const AsyncGroup(
  super.description,

  /// Group body
  final Future<void> Function() body,
) extends Group {
  /// Runs and awaits the callback body.
  Future<void> run() async {
    _throwIfNested();
    final watch = Stopwatch()..start();
    await runZonedGuarded(
      () async {
        try {
          await body();
        } catch (error, stack) {
          reportError(
            error,
            stack,
            description: description,
            duration: watch.elapsed,
            errorMark: groupErrorMark,
          );
        }
      },
      ((error, stack) {
        // Safeguard error should be caught in try block
        reportError(
          error,
          stack,
          description: description,
          duration: watch.elapsed,
          errorMark: groupErrorMark,
        );
      }),
      zoneValues: {#group: this},
    );
  }
}

/// Defines a benchmark group.
///
/// Note: Groups may not be nested.
void group(String description, void Function() body) {
  if (body is Future<void> Function()) {
    SyncGroup((hourGlass + description).style(ColorProfile.group), body).run();
  } else {
    SyncGroup(description.style(ColorProfile.group), body).run();
  }
}

Future<void> asyncGroup(
  String description,
  Future<void> Function() body,
) async {
  await AsyncGroup(
    (hourGlass + description).style(ColorProfile.group),
    body,
  ).run();
}
