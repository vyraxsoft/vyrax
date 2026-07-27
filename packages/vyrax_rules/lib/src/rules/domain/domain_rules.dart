import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects files that declare more than one public class.
final class MultiplePublicClassesRule implements VyraxRule {
  /// Creates a [MultiplePublicClassesRule].
  const MultiplePublicClassesRule();

  @override
  String get id => 'VYX003';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.domain;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final classPattern = RegExp(
      r'^\s*class\s+([A-Z][A-Za-z0-9_]*)\b',
      multiLine: true,
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      final matches = classPattern.allMatches(source).toList(growable: false);
      if (matches.length <= 1) {
        continue;
      }

      final firstExtra = matches[1];
      final line = lineFromOffset(source, firstExtra.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Multiple public classes',
          description:
              'Found ${matches.length} public classes in a single file.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact: 'Large files are harder to navigate and maintain.',
          recommendation:
              'Split each public class into its own file when possible.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}
