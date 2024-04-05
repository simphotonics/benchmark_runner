import 'dart:async';

import 'package:ansi_modifier/ansi_modifier.dart';

import '../extensions/color_profile.dart';
import '../extensions/string_utils.dart';

class Group {
  const Group(this.description, this.body);

  /// Group description
  final String description;

  /// Group body
  final FutureOr<void> Function() body;

  /// Throws an error if this group is defined within another group.
  void _throwIfNested() {
    // Check for nested groups:
    final parentGroup = Zone.current[#group] as Group?;
    if (parentGroup != null) {
      throw UnsupportedError(
          '${'Nested groups detected! '.style(ColorProfile.error)}'
          'Group ${description.style(ColorProfile.emphasize)} defined '
          'within group ${parentGroup.description.style(
        ColorProfile.emphasize,
      )}');
    }
  }

  /// Runs and awaits the callback body.
  Future<void> runAsync() async {
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
            runtime: watch.elapsed,
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
          runtime: watch.elapsed,
          errorMark: groupErrorMark,
        );
      }),
      zoneValues: {#group: this},
    );
  }

  // Runs the callback body.
  void run() {
    _throwIfNested();
    final watch = Stopwatch()..start();
    runZonedGuarded(
      body,
      ((error, stack) {
        reportError(
          error,
          stack,
          description: description,
          runtime: watch.elapsed,
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
FutureOr<void> group(
  String description,
  FutureOr<void> Function() body,
) async {
  final isAsync = (body is Future<void> Function());

  if (isAsync) {
    description = hourGlass + description;
  }

  final instance = Group(
    description.style(ColorProfile.group),
    body,
  );
  if (isAsync) {
    return instance.runAsync();
  } else {
    instance.run();
  }
}
