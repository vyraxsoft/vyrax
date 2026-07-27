import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects broad SOLID improvement opportunities at file level.
final class SolidOpportunityRule implements VyraxRule {
  /// Creates a [SolidOpportunityRule].
  const SolidOpportunityRule();

  @override
  String get id => 'VYX021';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.testing;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);

    for (final file in files) {
      final source = file.readAsStringSync();
      final suggestions = <String>[];

      final hasLongMethod =
          RegExp(
            r'(?m)^\s*(?:[A-Za-z0-9_<>, ?]+\s+)?[a-zA-Z_][A-Za-z0-9_]*\s*\([^\)]*\)\s*\{',
          ).allMatches(source).length >=
          10;
      final hasManyCases =
          RegExp(r'(?m)^\s*case\s+').allMatches(source).length >= 4;
      final hasConcreteImports = RegExp(
        "import\\s+['\"][^'\"]*(data|infra|service|repository|client|api)/[^'\"]*['\"];",
      ).hasMatch(source);

      if (hasLongMethod) {
        suggestions.add('SRP');
      }
      if (hasManyCases) {
        suggestions.add('OCP');
      }
      if (hasConcreteImports) {
        suggestions.add('DIP');
      }

      if (suggestions.isEmpty) {
        continue;
      }

      final recommendation = suggestions.contains('SRP')
          ? 'Consider splitting this class or module so each part has one reason to change (SRP).'
          : suggestions.contains('OCP')
          ? 'Consider replacing branching with dispatch/strategy so new cases extend behavior without editing the same block (OCP).'
          : 'Consider depending on abstractions and injecting concrete implementations from the outside to improve testability (DIP).';

      final principle = suggestions.length == 1
          ? suggestions.first
          : suggestions.join(', ');

      issues.add(
        VyraxIssue(
          id: id,
          title: 'SOLID opportunity detected',
          description:
              'This file matches patterns that suggest applying: $principle.',
          severity: VyraxSeverity.info,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: 1,
          impact:
              'Applying the relevant SOLID principle usually reduces coupling, improves testability, and makes future changes safer.',
          recommendation: recommendation,
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}
