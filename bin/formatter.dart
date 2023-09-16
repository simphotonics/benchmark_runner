import 'package:benchmark_runner/src/extensions/duration_formatter.dart';

void main(List<String> args) {
  final d = Duration(days: 1234, hours: 3, minutes: 45, seconds: 10);
  print(d);
  print(d.mmssms);
}
