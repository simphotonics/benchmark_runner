// ignore_for_file: unnecessary_string_escapes

import 'dart:io';

import 'package:ansi_modifier/ansi_modifier.dart';
import 'package:benchmark_runner/benchmark_runner.dart' show BenchmarkHelper;

final ticksList = [
  1,
  2,
  4,
  6,
  8,
  10,
  15,
  25,
  40,
  70,
  100,
  180,
  260,
  380,
  490,
  600,
  800,
  1001,
  1011,
  1070,
  1140,
  1196,
  1276,
  1387,
  1542,
  1760,
  2065,
  2492,
  3090,
  3926,
  5098,
  6738,
  9033,
  10000,
  11000,
  12248,
  16748,
  23047,
  31867,
  44215,
  61502,
  85703,
  100000,
  110000,
  119585,
  167020,
  233429,
  326401,
  456562,
  638787,
  893903,
  1000000,
  1100000,
  1251065,
  1751092,
  2451130,
  3431183,
  4803257,
  6724160,
  9413425,
  10000000,
  11000000,
  13178396,
  18449355,
  25828697,
  36159777,
  50623289,
  60000000,
  70000000,
  80000000,
  90000000,
  95000000,
  100000000,
  110000000,
  138908563,
  194471590,
];

final xAxisInMicroSeconds = ticksList.map(
  (e) => (e * 1e6) / BenchmarkHelper.frequency,
);

final gnuplotScript = '''
reset;
set samples 1000;
set term qt size 1000, 500 font "Sans, 14";
set grid lw 2;
set logscale x;
unset label;
set xlabel "Single Run time [us]";
set xrange [ 0 : 1e6 ] noreverse writeback;
set x2range [ * : * ] noreverse writeback;
set yrange [ 0 : 1500 ] noreverse writeback;
set y2range [ * : * ] noreverse writeback;
plot "sample_size.dat" using 1:2 with line lw 3 lt 2 lc "#0000FFFF" title "averaged over" at 0.6, 0.85, \
     "sample_size.dat" using 1:2 lw 3 lt 6 lc "#0000BBBB" title " " at 0.6, 0.85, \
     "sample_size.dat" using 1:3 with lines lw 3 lt 2 lc "#00FF8800" title "sample size" at 0.6, 0.75, \
     "sample_size.dat" using 1:3 lw 3 lt 6 lc "#00991100" title " " at 0.6, 0.75, \
     "sample_size.dat" using 1:4 with lines lw 3 lt 2 lc "#0000C77E" title "total sample generation time [ms]" at 0.6, 0.65, \
     "sample_size.dat" using 1:4 lw 3 lt 6 lc "#0000974e" title " " at 0.6, 0.65;
#
''';

// To print a graph showing the sample size as a function of the
// (estimated) benchmark score use the command:
// $ dart sample_size.dart
void main(List<String> args) async {
  // For custom sample sizes implement the function below:
  // ignore: unused_element
  ({int inner, int outer}) customSampleSize(int clockTicks) {
    // Use the number of clock ticks to calculate the number of entries in the
    // score sample (.outer) and the number of runs each score point is averaged
    // over (inner).
    return (inner: 10, outer: 10); // This is a stub!
  }

  // Uncomment the line below to use your custom function:
  // BenchmarkHelper.sampleSize = customSampleSize;

  final b = StringBuffer();
  b.writeln(
    '# Single Run Time [us]    Inner-Iterations     Sample Length      Total Run Time [ms]',
  );

  for (final ticks in ticksList) {
    final sampleSize = BenchmarkHelper.sampleSize(ticks);
    final singleRunTimeMicroseconds =
        ticks * Duration.microsecondsPerSecond / BenchmarkHelper.frequency;
    final totalRunTimeMilliseconds =
        ticks *
        sampleSize.innerIterations *
        sampleSize.length *
        Duration.millisecondsPerSecond /
        BenchmarkHelper.frequency;

    b.write(singleRunTimeMicroseconds.toString().padRight(20).padLeft(25));
    b.write(sampleSize.innerIterations.toString().padRight(20).padLeft(25));
    b.write(sampleSize.length.toString().padRight(20));
    b.write(totalRunTimeMilliseconds.toString().padRight(20));
    b.writeln();
  }

  final file = await File('sample_size.dat').writeAsString(b.toString());

  final process = Process.run('gnuplot', ['-p', '-e', gnuplotScript]);
  final result = await process;
  await file.delete();

  print(result.stdout);
  print(result.stderr);
  print(
    'Returning with gnuplot exit code:'
    ' ${result.exitCode.toString().style(Ansi.green)}',
  );
}
