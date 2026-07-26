import 'dart:io';

import 'package:vyrax_cli/vyrax_cli.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty ||
      arguments.contains('--help') ||
      arguments.contains('-h')) {
    stdout.writeln(buildHelpMessage());
    return;
  }

  stdout.writeln('Unknown command.');
  stdout.writeln(buildHelpMessage());
  exitCode = 64;
}
