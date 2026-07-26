/// CLI utilities for rendering command help.
library;

/// Returns the current help output for the Vyrax CLI.
String buildHelpMessage() {
  final buffer = StringBuffer()
    ..writeln('Vyrax - Flutter Architecture & Performance Analyzer')
    ..writeln('')
    ..writeln('Usage: vyrax <command> [arguments]')
    ..writeln('')
    ..writeln('Current support:')
    ..writeln('  --help, -h    Show this help message')
    ..writeln('')
    ..writeln('Planned commands:')
    ..writeln('  init, analyze, doctor, score, explain, fix');

  return buffer.toString();
}
