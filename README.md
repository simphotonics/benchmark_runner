# Benchmark Runner


## Introduction

Benchmarking is used to estimate and compare the execution speed of
numerical algorithms and programs.
Benchmark runner is a lightweight package based on
[`benchmark_harness`][benchmark_harness].
The package includes helper
functions for writing *inline* micro-benchmarks with the option of reporting
the score statistics: mean, standard deviation, median, inter quartile range,
and a block histogram.

The benchmark runner allows executing several benchmark files and reports if
uncaught exceptions/errors were encountered.

## Usage

Include [`benchmark_runner`][benchmark_runner] as a dependency
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
*
Run a *single* benchmark file as an executable:
```Console
$ dart benchmark/list_benchmark.dart
```

Run *several* benchmark files (ending with `_benchmark.dart`)
by calling the benchmark_runner and specifying a directory.
If no directory or file name is specified it defaults to `benchmark`:

```Console
$ dart run benchmark_runner
```

![Console Output](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/console_output.png)

A typical console output is shown above. The following colours and coding
are used:
* The first columns shows the micro-benchmark runtime.
* The labels of asynchronous benchmarks and groups are marked with an hour-glass
symbol.
* The *mean* and the histogram block containing the *mean*
are printed using <span style="color:#11A874">*green*</span> foreground.
* The *median* and the block containg the *median* are printed
using <span style="color:#2370C4">*blue*</span> foreground.
* If the same block contains mean and median it is printed
using <span style="color:#28B5D7">*cyan*</span> foreground.
* Errors are printed using <span style="color:#CB605E"> *red* </span> foreground.
* The summary shows the total number of completed benchmars, the number of
benchmarks with errors and the number of groups with errors (that do not
occur within the scope of a benchmark function).

## Tips and Tricks

- The scores reported by [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark]
refer to a *single* run of the benchmarked function.

- Benchmarks do *not* need to be enclosed by a group.

- The program does check for name group and benchmark *description* clashes.

- A benchmark group may *not* contain another benchmark group.

- By default, [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark] report score statistics. In order to generate
the report provided by [`benchmark_harness`][benchmark_harness] use the
optional argument `emitStats: false`.

- Color output can be switched off by using the option: `--isMonochrome` when
calling the benchmark runner. When executing a single benchmark file the
corresponding option is `--define=isMonochrome=true`.

- The default colors used to style benchmark reports are best suited
for a dark terminal background.
They can, however, be altered by setting the static variables defined by
the class [`ColorProfile`][ColorProfile]. In the example below, the styling of
error messages and the mean value is altered.
  ```Dart
  import 'package:ansi_modifier/ansi_modifier.dart';
  import 'package:benchmark_runner/benchmark_runner.dart';

  void customColorProfile() {
    ColorProfile.error = Ansi.red + Ansi.bold;
    ColorProfile.mean = Ansi.green + Ansi.italic;
  }

  void main(List<String> args) {
    // Call function to apply the new custom color profile.
    customProfile();
  }
  ```

When running **asynchronous** benchmarks the score are printed in order of
completion. The print the scores in sequential order it is recommended
to *await* the completion of the async benchmark functions.

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
