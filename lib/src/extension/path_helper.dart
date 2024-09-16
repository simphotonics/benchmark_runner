import 'package:path/path.dart' as p;

extension PathHelper on String {
  String join([
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
    String? part7,
    String? part8,
    String? part9,
    String? part10,
    String? part11,
    String? part12,
    String? part13,
    String? part14,
    String? part15,
    String? part16,
  ]) =>
      p.join(
        this,
        part2,
        part3,
        part4,
        part5,
        part6,
        part7,
        part8,
        part9,
        part10,
        part11,
        part12,
        part13,
        part14,
        part15,
        part16,
      );

  /// Returns the part the of path before the last separator.
  String get dirname => p.dirname(this);

  /// Returns the part of the path after the last separator.
  String get basename => p.basename(this);

  /// Returns the extension of the current path.
  String get extension => p.extension(this);

  /// Return the path with the trailing extension set to [extension].
  String setExtension(String extension) => p.setExtension(this, extension);

  /// Removes the trailing extension from the last part of `this`.
  String get withoutExtension => p.withoutExtension(this);
}
