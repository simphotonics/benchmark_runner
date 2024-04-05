# Benchmark Runner
[![Dart](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml)


## Introduction

Benchmarking is used to estimate and compare the execution speed of
numerical algorithms and programs.
The package [benchmark_runner][benchmark_runner] is based on
[`benchmark_harness`][benchmark_harness] and includes helper
functions for writing *inline* micro-benchmarks with the option of
printing a score **histogram** and reporting the score **mean**,
**standard deviation**, **median**, and **inter quartile range**.

The benchmark runner allows executing several benchmark files and reports if
uncaught exceptions/errors were encountered. 

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
 * Benchmark files must end with `_benchmark.dart` in order to be detected
   by the `benchmark_runner`.

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

![Console Output](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/console_output.png)

A typical console output is shown above. The following colours and coding
are used:
* The first column shows the micro-benchmark runtime.
* The labels of asynchronous benchmarks and groups are marked with an hour-glass
symbol.
* The *mean* and the histogram block containing the *mean*
are printed using <span style="color:#11A874">*green*</span> foreground.
* The *median* and the block containg the *median* are printed
using <span style="color:#2370C4">*blue*</span> foreground.
* If the same block contains mean and median it is printed
using <span style="color:#28B5D7">*cyan*</span> foreground.
* Errors are printed using <span style="color:#CB605E"> *red* </span> foreground.
* The summary shows the total number of completed benchmarks, the number of
benchmarks with errors and the number of groups with errors (that do not
occur within the scope of a benchmark function).

## Tips and Tricks

- The scores reported by [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark]
refer to a *single* run of the benchmarked function.

- Benchmarks do *not* need to be enclosed by a group.

- A benchmark group may *not* contain another benchmark group.

- The program does **not** check for group *description*
and benchmark *description* clashes. It can be useful to have a second
benchmark with the same name for example to compare the standard score
as reported by [`benchmark_harness`][benchmark_harness] and the
score statistics.

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

- When running **asynchronous** benchmarks, the scores are printed in order of
completion. The print the scores in sequential order (as they are listed in the
benchmark executable) it is required to *await* the completion
of the async benchmark functions and
the enclosing group.

## Contributions

Help and enhancement requests are welcome. Please file requests via the [issue
tracker][tracker].

The To-Do list currently includes:
* Add tests.

* Add color profiles optimized for terminals with light background color.

* Improve the way benchmark score samples are generated.

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
