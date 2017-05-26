void main(List<String> arguments) {
  String output;
  if (arguments.isEmpty) {
    output = 'Custom local analyze task';
  } else {
    output = 'Custom local analyze task ${arguments.first}';
  }

  if (arguments.contains('--loud') || arguments.contains('-l')) {
    output = output.toUpperCase();
  }

  print(output);
}
