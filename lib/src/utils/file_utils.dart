import 'dart:io';

/// Returns a list of resolved test files as `Future<List<File>>`.
/// * Test files must end with `_test.dart`.
/// * Returns an empty list if no test files are found.
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
