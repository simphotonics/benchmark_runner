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
      }, scoreEmitter: MeanEmitter());
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
The parameter expects an object of type `ScoreEmitter` and
can be used to customize the score reports e.g.
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

In order to calculate benchmark score *statistics* a sample of scores is
required. The question is how to generate the score sample while minimizing
systematic errors (like overheads) and keeping the
total benchmark run times within acceptable limits.

<details> <summary> Click to show details. </summary>

In a first step, benchmark scores are estimated using the
functions [`estimate`][estimate]
or [`estimateAsync`][estimateAsync]. The function [`BenchmarkHelper.sampleSize`][sampleSize]
uses the score estimate to determine the sample size and the number of inner
iterations (for short run times each sample entry is averaged).

### 1. Default Sampling Method
The graph below shows the sample size (orange curve) as calculated by the function
[`BenchmarkHelper.sampleSize`][sampleSize] (the of the list containing the
benchmark scores).

The green curve shows the lower limit of the total microbenchmark duration
in microseconds.

![Sample Size](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/sample_size.png)

For short run times below 1 microsecond each score sample is generated
using the functions [`measure`][measure] or the equivalent
asynchronous method [`measureAsync`][measureAsync]. The cyan curve shows
approx. over how many runs a score entry is averaged.

### 2. Custom Sampling Method
The parameter `sampleSize` of the functions [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark]  can be used to specify the lenght of the score
sample list and the number of inner iterations used to generate each entry.

To customize the score sampling process, without having to specify the parameter
`sampleSize` for each call of [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark], the static function
[`BenchmarkHelper.sampleSize`][sampleSize] can be replaced with a custom function:
```Dart
/// Generates a sample containing 100 benchmark scores.
BenchmarkHelper.sampleSize = (int clockTicks) {
  return (outer: 100, inner: 1)
}
```
To restore the default score sampling settings use:
```Dart
BenchmarkHelper.sampleSize = BenchmarkHelper.sampleSizeDefault;
```
----
The graph shown above may be re-generated using the custom `sampleSize`
function by copying and amending the file `gnuplot/sample_size.dart`
and using the command:
```Console
dart sample_size.dart
```
The command above lauches a process and runs a [`gnuplot`][gnuplot] script.
For this reason, the program [`gnuplot`][gnuplot] must be installed (with
the `qt` terminal enabled).

</details>

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
