import 'dart:io';

/// Returns a list of resolved benchmark files.
/// * Benchmark files must end with `_benchmark.dart`.
/// * Returns an empty list if no benchmark files were found.
Future<({List<File> benchmarkFiles, FileSystemEntityType entityType})>
    resolveBenchmarkFiles(String path) async {
  final benchmarkFiles = <File>[];
  final entityType = await FileSystemEntity.type(path);
  if ((entityType == FileSystemEntityType.directory)) {
    final directory = Directory(path);
    await for (final entity in directory.list()) {
      if (entity is File) {
        if (entity.path.endsWith('_benchmark.dart')) {
          benchmarkFiles.add(entity);
        }
      }
    }
  } else if ((entityType == FileSystemEntityType.file)) {
    benchmarkFiles.add(File(path));
  }
  return (benchmarkFiles:benchmarkFiles, entityType: entityType);
}

/// Opens a file using [path], writes [contents], and closes the file.
/// Returns `Future<File>` on success. Throws a [FileSystemException]
/// on failure.
Future<File> writeTo({
  required String path,
  String contents = '',
  FileMode mode = FileMode.write,
}) async {
  final entityType = await FileSystemEntity.type(path);
  switch (entityType) {
    case FileSystemEntityType.file ||
          FileSystemEntityType.notFound ||
          FileSystemEntityType.pipe:
      final file = File(path);
      return await file.writeAsString(contents, mode: mode);
    case FileSystemEntityType.directory:
      throw FileSystemException('Could not write to $path. It is a directory!');
    default:
      throw FileSystemException(
        'Could not write to file with path: $path.',
        path,
      );
  }
}
