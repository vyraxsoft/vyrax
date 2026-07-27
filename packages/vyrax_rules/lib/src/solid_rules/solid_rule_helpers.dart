import 'dart:io';

import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

typedef SolidIssueBuilder =
    VyraxIssue? Function(String className, String body, int line);

List<VyraxIssue> inspectClassBodies(File file, SolidIssueBuilder builder) {
  final issues = <VyraxIssue>[];
  final source = file.readAsStringSync();
  final classPattern = RegExp(
    r'class\s+([A-Z][A-Za-z0-9_]*)\b[^\{]*\{',
    multiLine: true,
  );

  for (final match in classPattern.allMatches(source)) {
    final className = match.group(1);
    if (className == null) {
      continue;
    }

    final openBrace = source.indexOf('{', match.start);
    final closeBrace = matchBraceInSource(source, openBrace);
    if (openBrace == -1 || closeBrace == -1) {
      continue;
    }

    final body = source.substring(openBrace + 1, closeBrace);
    final line = lineFromOffset(source, match.start);
    final issue = builder(className, body, line);
    if (issue != null) {
      issues.add(issue);
    }
  }

  return issues;
}

int matchBraceInSource(String source, int openIndex) {
  if (openIndex < 0 || openIndex >= source.length) {
    return -1;
  }

  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final char = source.codeUnitAt(i);
    if (char == 123) {
      depth++;
    } else if (char == 125) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}
