# Benchmark Runner - Example
[![Dart](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml)

## Usage

Include [`benchmark_runner`][benchmark_runner] as a `dev_dependency`
 in your `pubspec.yaml` file.

Write inline benchmarks using the functions:
 * [`benchmark`][benchmark]: Creates and runs a synchronous benchmark and
   reports the benchmark score.
 * [`asyncBenchmark`][asyncBenchmark]: Creates and runs an
   asynchronous benchmark.
 * [`group`][group]: Used to label a group of benchmarks.
   The callback `body` usually contains one or several calls to
   [`benchmark`][benchmark] and [`asyncBenchmark`][asyncBenchmark].
   Benchmark groups may not be nested.
 * Files must end with `_benchmark.dart` in order to be detected as
   benchmark files by `benchmark_runner`.

 The example below shows a benchmark file containing synchronous and
 asynchronous benchmarks.

  ```Dart
  // ignore_for_file: unused_local_variable

  import 'package:benchmark_runner/benchmark_runner.dart';

  /// Returns the value [t] after waiting for [duration].
  Future<T> later<T>(T t, [Duration duration = Duration.zero]) {
    return Future.delayed(duration, () => t);
  }

  void main(List<String> args) async {
    await group('Wait for duration', () async {
      await asyncBenchmark('10ms', () async {
        await later<int>(39, Duration(milliseconds: 10));
      });

      await asyncBenchmark('5ms', () async {
        await later<int>(27, Duration(milliseconds: 5));
      }, emitStats: false);
    });

    group('Set', () async {
      await asyncBenchmark('error test', () {
        throw ('Thrown in benchmark.');
      });

      benchmark('construct', () {
        final set = {for (var i = 0; i < 1000; ++i) i};
      });

      throw 'Error in group';
    });
  }

  ```
Run a *single* benchmark file as an executable:
```Console
$ dart benchmark/example_async_benchmark.dart
```

Run *several* benchmark files (ending with `_benchmark.dart`)
by calling the benchmark_runner and specifying a directory.
If no directory or file name is specified, then it defaults to `benchmark`:

```Console
$ dart run benchmark_runner
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/simphotonics/benchmark_runner/issues

[asyncBenchmark]: https://pub.dev/documentation/benchmark_runner/doc/api/benchmark_runner/asyncBenchmark.html

[asyncGroup]: https://pub.dev/documentation/benchmark_runner/doc/api/benchmark_runner/asyncGroup.html

[benchmark_harness]: https://pub.dev/packages/benchmark_harness

[benchmark_runner]: https://pub.dev/packages/benchmark_runner

[benchmark]: https://pub.dev/documentation/benchmark_runner/doc/api/benchmark_runner/benchmark.html

[ColorProfile]: https://pub.dev/documentation/benchmark_runner/doc/api/benchmark_runner/ColorProfile.html

[group]: https://pub.dev/documentation/benchmark_runner/doc/api/benchmark_runner/group.html