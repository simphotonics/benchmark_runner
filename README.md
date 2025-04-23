# Benchmark Runner
[![Dart](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml)


## Introduction

Benchmarking is used to estimate and compare the execution speed of
numerical algorithms and programs.
The package [`benchmark_runner`][benchmark_runner] includes helper
functions for writing *inline* micro-benchmarks with the option of
printing a score **histogram** and reporting the score **mean** &#177;
**standard deviation**, and score **median** &#177; **inter quartile range**.

The benchmark runner allows executing several benchmark files and reports if
uncaught exceptions/errors were encountered. It has two sub-commands:
* [report](#2-using-the-benchmark-runner): Used to print a benchmark report to stdout,
* [export](#3-exporting-benchmark-scores): Used to write benchmark reports to a file.

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


The functions [`benchmark`][benchmark] and [`asyncBenchmark`][asyncBenchmark]
   accept the following optional parameters:
   * `setup`: A function that is executed *before* the benchmark runs.
   * `teardown`: A function that is executed *after* the benchmark runs,
   * `scoreEmitter`: An object responsible for formatting the score results.
     Its default value is: `StatsEmitter()`.
   * `warmUpDuration`: The time expended on warm-up runs used to generate a
   preliminary score estimate. The default warm-up duration is:
      `Duration(milliseconds: 200)`.
   * `sampleSize`: Used to manually specify the score sample size and
   over how many runs each score entry should be averaged.
   If this parameter is omitted,
   it will be calculated using the function [`sampleSize`][sampleSize].

 The example below shows a benchmark file containing synchronous benchmarks
 and two benchmark groups:

  ```Dart
  import 'package:benchmark_runner/benchmark_runner.dart';

  void main(List<String> args) {
    group('Set', () {
      benchmark('construct', () {
        final set = {for (var i = 0; i < 1000; ++i) i};
      });

      final list = [for (var i = 0; i < 1000; ++i) i];
      benchmark('construct from list', () {
        final set = Set<int>.of(list);
      });
    });
    group('List:', () {
      final originalList = <int>[for (var i = 0; i < 1000; ++i) i];

      benchmark('construct', () {
        var list = <int>[for (var i = 0; i < 1000; ++i) i];
      });

      benchmark('construct', () {
        var list = <int>[for (var i = 0; i < 1000; ++i) i];
      }, scoreEmitter: MeanEmitter());
    });
  }
  ```
### 1. Running a Single Benchmark File
A *single* benchmark file may be run as a Dart executable:
![Console Output Single](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/single_report.png)

The console output is shown above. By default,
the functions [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark]
emit benchmark score statistics.
* The first column shows the micro-benchmark runtime, followed by the group
  name and the benchmark name.
* The labels of asynchronous groups and benchmarks are marked with an hour-glass
symbol.
* The *mean* and the histogram block containing the *mean*
are printed using <span style="color:#11A874">*green*</span> foreground.
* The *median* and the block containg the *median* are printed
using <span style="color:#2370C4">*blue*</span> foreground.
* If the same block contains mean and median then it is printed
using <span style="color:#28B5D7">*cyan*</span> foreground.
* The number of data points used to calculate the score statistics is printed
below the histogram.
* Errors are printed using <span style="color:#CB605E"> *red* </span> foreground.

### 2. Using the Benchmark Runner
To run *several* benchmark files (with the format`*_benchmark.dart`)
and print a report, invoke the sub-command `report` and specify a directory.
If no directory is specified, it defaults to `benchmark`:

![Runner Report](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/runner_report.png)

A typical console output is shown above. In this example, the benchmark_runner
detected two benchmark files, ran the micro-benchmarks and produced a report.

* The summary shows the total number of completed benchmarks, the number of
benchmarks with errors and the number of groups with errors (that do not
occur within the scope of a benchmark function).
* To show a stack trace for each error, use the option ``-v`` or `--verbose`.
* The total benchmark run time may be shorter than the sum of the
micro-benchmark run times since each executable benchmark file is run in
a separate process.

### 3. Exporting Benchmark Scores

To export benchmark scores use the sub-command `export`:
```
$ dart run benchmark_runner export --outputDir=scores --extension=csv searchDirectory
```
In the example above, `searchDirectory` is scanned for `*_benchmark.dart`
files. For each benchmark file, a corresponding file `*_benchmark.csv` is
written to the directory `scores`.

Note: The directory must exist and the user
must have write access. When exporting benchmark scores to a file
and the emitter output is colorized,
it is recommended to use the option `--isMonochrome`, to
avoid spurious characters due to the use of Ansi modifiers.

The functions [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark] accept the optional parameters `scoreEmitter`.
The parameter expects an object of a type that implements the interface
`ScoreEmitter` and can be used to customize the score reports e.g.
to make the score format more suitable for writing to a file:

```Dart
import 'package:benchmark_runner/benchmark_runner.dart';

class CustomEmitter implements ScoreEmitter {
  @override
  void emit({required description, required Score score}) {
    print('# Mean               Standard Deviation');
    print('${score.stats.mean}  ${score.stats.stdDev}');
  }
}

void main(){
  benchmark(
      'construct list | use custom emitter',
      () {
        var list = <int>[for (var i = 0; i < 1000; ++i) i];
      },
      scoreEmitter: CustomEmitter(),
  );
}
```

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
[`asyncBenchmark`][asyncBenchmark] report score statistics. In order to print
the report similar to that produced by
[`benchmark_harness`][benchmark_harness], use the
optional argument `emitter: MeanEmitter()`.

- Color output can be switched off by using the option: `--isMonochrome` or `-m`
when calling the benchmark runner. When executing a single benchmark file the
corresponding option is `--define=isMonochrome=true`.

- The default colors used to style benchmark reports are best suited
for a dark terminal background.
They can, however, be altered by setting the *static* variables defined by
the class [`ColorProfile`][ColorProfile]. In the example below, the styling of
error messages and the mean value is altered.
  ```Dart
  import 'package:ansi_modifier/ansi_modifier.dart';
  import 'package:benchmark_runner/benchmark_runner.dart';

  void adjustColorProfile() {
    ColorProfile.error = Ansi.red + Ansi.bold;
    ColorProfile.mean = Ansi.green + Ansi.italic;
  }

  void main(List<String> args) {
    // Call function to apply the new custom color profile.
    adjustColorProfile();
  }
  ```

- When running **asynchronous** benchmarks, the scores are printed in order of
completion. To print the scores in sequential order (as they are listed in the
benchmark executable) it is required to *await* the completion
of the async benchmark functions and
the enclosing group.


## Score Sampling

For more information about benchmark score sampling see the dedicated [section](
   https://github.com/simphotonics/benchmark_runner/tree/main/gnuplot
).


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

[asyncBenchmark]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/asyncBenchmark.html

[asyncGroup]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/asyncGroup.html

[benchmark_harness]: https://pub.dev/packages/benchmark_harness

[benchmark_runner]: https://pub.dev/packages/benchmark_runner

[benchmark]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/benchmark.html

[ColorProfile]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/ColorProfile.html

[gnuplot]: https://sourceforge.net/projects/gnuplot/

[group]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/group.html

[measure]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/BenchmarkHelper/measure.html

[measureAsync]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/BenchmarkHelper/measureAsync.html

[sampleSize]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/BenchmarkHelper/sampleSize.html

[estimate]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/BenchmarkHelper/estimate.html

[estimateAsync]: https://pub.dev/documentation/benchmark_runner/latest/benchmark_runner/BenchmarkHelper/estimateUpAsync.html
