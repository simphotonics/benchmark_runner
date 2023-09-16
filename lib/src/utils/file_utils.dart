import 'dart:io';

/// Returns a list of resolved benchmark files.
/// * Benchmark files must end with `_benchmark.dart`.
/// * Returns an empty list if no benchmark files were found.
Future<List<File>> resolveBenchmarkFiles(String path) async {
  final benchmarkFiles = <File>[];
  final entityType = FileSystemEntity.typeSync(path);
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
  return benchmarkFiles;
}
