import 'dart:io';

import 'package:benchmark_runner/src/extensions/benchmark_helper.dart';

final ticksList = [
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
  12248,
  16748,
  23047,
  31867,
  44215,
  61502,
  85703,
  100000,
  119585,
  167020,
  233429,
  326401,
  456562,
  638787,
  893903,
  1000000,
  1251065,
  1751092,
  2451130,
  3431183,
  4803257,
  6724160,
  9413425,
  10000000,
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
  138908563,
  194471590,
  // 272259826,
  // 381163357,
  // 533628301,
  // 747079223,
  // 1045910512,
  // 1464274318,
];

void main(List<String> args) async {
  final b = StringBuffer();
  b.writeln(
      '# Ticks    Inner-Iterations Outer-Iterations      Run-Time [1 ms]');

  for (final ticks in ticksList) {
    final (inner: inner, outer: outer) = BenchmarkHelper.sampleSize(ticks);
    b.writeln('$ticks               $inner            '
        '$outer              ${ticks * inner * outer / 1000000}');
  }

  await File('sample_size.dat').writeAsString(b.toString());

  await Process.run('gnuplot',['-p', 'sample_size.gp']);
}
