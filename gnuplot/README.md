# Benchmark Runner - Score Sampling
[![Dart](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/benchmark_runner/actions/workflows/dart.yml)


## Introduction

When benchmarking a function, one has to take into consideration that
the benchmark is not performed on an isolated system that is only handling the
instructions provided by our piece of code. Instead, the CPUs is very likely
busy performing other tasks before eventually executing the benchmarked code.
This introduces latency that is typically larger for the first few runs
and then has a certain degree of randomness. The initial latency
can be reduced to some extend by introducing a warm-up phase,
where the first few runs are discarded.

A second factor to consider are systematic measuring errors due to the fact
that it takes (a small amount of) time to increment loop counters, perform
loop checks, or access the elapsed time. The overhead introduced by
repeatedly accessing the
elapsed time can be reduced by averaging the
benchmark score over many runs.

The question is how to generate a score sample while minimizing
systematic errors and keeping the
total benchmark run times within acceptable limits.


## Score Estimate

In a first step, benchmark scores are *estimated* using the
functions [`estimate`][estimate]
or [`estimateAsync`][estimateAsync].
The function [`BenchmarkHelper.sampleSize`][sampleSize]
uses the score estimate to determine a suitable sample size and number of inner
iterations (for short run times each sample entry is averaged).

### Default Sampling Method
The graph below shows the sample size (orange curve) as calculated by the function
[`BenchmarkHelper.sampleSize`][sampleSize].

The green curve shows the lower limit of the total microbenchmark duration
in microseconds.

![Sample Size](https://raw.githubusercontent.com/simphotonics/benchmark_runner/main/images/sample_size.png)

For short run times below 1 microsecond each score sample is generated
using the functions [`measure`][measure] or the equivalent
asynchronous method [`measureAsync`][measureAsync]. The cyan curve shows
over how many runs each score entry is averaged.

### Custom Sampling Method

The parameter `sampleSize` of the functions [`benchmark`][benchmark] and
[`asyncBenchmark`][asyncBenchmark]  can be used to specify the lenght of the score
sample list and the number of inner iterations used to generate each entry.

To customize the score sampling process, *without* having to specify the parameter
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
The graph shown above may be re-generated using a user defined
custom `sampleSize` function by
amending the file `gnuplot/sample_size.dart`. For more instruction see
the comments in the function `main()`.

To print the graph use the command:
```Console
dart sample_size.dart
```
Note: The command above lauches a process and runs a [`gnuplot`][gnuplot] script.
For this reason, the program [`gnuplot`][gnuplot] must be installed (with
the `qt` terminal enabled).

</details>


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
