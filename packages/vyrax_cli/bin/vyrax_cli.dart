import 'dart:io';

import 'package:vyrax_cli/vyrax_cli.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--version') ||
      arguments.contains('-v') ||
      (arguments.isNotEmpty && arguments.first == 'version')) {
    stdout.writeln(buildVersionMessage());
    return;
  }

  if (arguments.isEmpty ||
      arguments.contains('--help') ||
      arguments.contains('-h')) {
    stdout.writeln(buildHelpMessage());
    return;
  }

  if (arguments.first == 'analyze') {
    final code = await runAnalyzeCommand(
      arguments.skip(1).toList(growable: false),
    );
    exitCode = code;
    return;
  }

  if (arguments.first == 'init') {
    final code = await runInitCommand(
      arguments.skip(1).toList(growable: false),
    );
    exitCode = code;
    return;
  }

  stdout.writeln('Unknown command.');
  stdout.writeln(buildHelpMessage());
  exitCode = 64;
}
