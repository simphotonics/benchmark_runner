/// Used to enable/disable color output.
enum ColorOutput { on, off }

/// Enumeration representing Ansi modifiers.
///
/// Used to print colorizd output to Anis compliant terminals.
enum AnsiModifier {
  // Ansi color modifier: Reset to default.
  reset('\u001B[0m'),

  /// Ansi color modifier: red foreground.
  red('\u001B[31m'),

  /// Ansi color modifier: bright red foreground.
  redBright('\u001B[91m'),

  /// Ansi color modifier: green foreground.
  green('\u001B[32m'),

  /// Ansi color modifier: bright green foreground.
  greenBright('\u001B[92m'),

  /// Ansi color modifier: yellow foreground.
  yellow('\u001B[33m'),

  /// Ansi color modifier: bright yellow foreground.
  yellowBright('\u001B[93m'),

  /// Ansi color modifier: blue foreground.
  blue('\u001B[34m'),

  /// Ansi color modifier: bright blue foreground.
  blueBright('\u001B[94m'),

  /// Ansi color modifier: magenta foreground.
  magenta('\u001B[35m'),

  /// Ansi color modifier: magenta foreground.
  magentaBright('\u001B[95m'),

  /// Ansi color modifier: magenta bold foreground.
  magentaBold('\u001B[1;35m'),

  /// Ansi color modifier: cyan foreground.
  cyan('\u001B[36m'),

  /// Ansi color modifier: cyan bold text.
  cyanBold('\u001B[1;36m'),

  /// Ansi color modifier: grey foreground
  grey('\u001B[2;37m'),

  /// Ansi color modifier: grey bold foreground
  greyBold('\u001B[1;90m'),

  /// Ansi color modifier: white bold foreground
  whiteBold('\u001B[1;97m');

  const AnsiModifier(this.code);

  /// Returns the Ansi code.
  final String code;

  /// Returns a set of all registered Ansi modifiers.
  static final Set<String> modifiers = AnsiModifier.values
      .map(
        (e) => e.code,
      )
      .toSet();

  /// Used to globally enable/disable color output.
  static ColorOutput colorOutput = bool.fromEnvironment(
    'isMonochrome',
  )
      ? ColorOutput.off
      : ColorOutput.on;

  /// Applies an Ansi compliant color modifier to a [String] and returns it.
  ///
  /// Note: Returns [message] unmodified if [colorOutput] is set to
  /// [ColorOutput.on].
  /// Usage:
  /// ```Dart
  /// final message = 'Green foreground';
  /// final greenMessage = message.colorize(AnsiModifier.green);
  /// // greenMessage: '\u001B[32mGreen foreground\u001B[0m';
  /// ```
  static String _colorize(
    String message,
    AnsiModifier modifier,
  ) {
    switch (colorOutput) {
      case ColorOutput.off:
        return message;
      case ColorOutput.on:
        // Strip previous starting modifiers
        if (message.startsWith('\u001B[')) {
          // Find Ansi code
          final end = message.indexOf('m', 0);
          final ansiCode = message.substring(0, end + 1);
          if (modifiers.contains(ansiCode)) {
            message = message.substring(ansiCode.length);
          }
        }
        return '${modifier.code}$message${AnsiModifier.reset.code}';
    }
  }
}

extension Color on String {
  /// Applies an Ansi compliant color modifier to the string and returns it.
  ///
  /// Note: Returns the string unmodified if [AnsiModifier.colorOutput] is set to
  /// [ColorOutput.off].
  ///
  /// Usage:
  /// ```Dart
  /// final message = 'Green foreground';
  /// final greenMessage = message.colorize(AnsiModifier.green);
  /// // greenMessage: '\u001B[32mGreen foreground\u001B[0m';
  /// ```
  String colorize(AnsiModifier modifier) => AnsiModifier._colorize(
        this,
        modifier,
      );
}
