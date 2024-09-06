// ignore_for_file: unused_local_variable
import 'package:benchmark_runner/benchmark_runner.dart';

const n = 1000;

final list = List.generate(n, (j) => j);
final it = Iterable<int>.generate(n);

void main(List<String> args) {
  benchmark('create set', () {
    final set = {for (var i = 0; i < n; i++) i};
  });
  benchmark('create list, list -> set', () {
    final set = List.generate(n, (j) => j).toSet();
  });
  benchmark('create iterable, iterable -> set', () {
    final set = Iterable.generate(n).toSet();
  });
  benchmark('list -> set', () {
    final set = list.toSet();
  });
  benchmark('list -> set', () {
    final set = {for (var i in it) i};
  });
  benchmark('create list', () {
    final list = List.generate(n, (j) => j);
  });
}
