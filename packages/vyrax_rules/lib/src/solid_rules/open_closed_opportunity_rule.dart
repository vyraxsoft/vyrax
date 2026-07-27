import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';
import 'package:vyrax_rules/src/solid_rules/solid_rule_helpers.dart';

final class OpenClosedOpportunityRule implements VyraxRule {
  const OpenClosedOpportunityRule();

  @override
  String get id => 'VYX019';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final switchPattern = RegExp(r'switch\s*\([^\)]*\)\s*\{');
    final ifChainPattern = RegExp(r'else\s+if\s*\(');

    for (final file in files) {
      final source = file.readAsStringSync();

      for (final match in switchPattern.allMatches(source)) {
        final openBrace = source.indexOf('{', match.start);
        final closeBrace = matchBraceInSource(source, openBrace);
        if (openBrace == -1 || closeBrace == -1) {
          continue;
        }

        final body = source.substring(openBrace + 1, closeBrace);
        final caseCount = RegExp(r'(?m)^\s*case\s+').allMatches(body).length;
        if (caseCount < 4) {
          continue;
        }

        final line = lineFromOffset(source, match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Open/Closed Principle opportunity',
            description:
                'Detected a switch statement with $caseCount cases that can become harder to extend safely.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'When adding new cases requires editing the same branching block, regressions become more likely.',
            recommendation:
                'Consider replacing the branch chain with strategy objects, a dispatch map, or polymorphic handlers so new cases extend behavior without rewriting existing logic.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }

      final ifChains = ifChainPattern.allMatches(source).length;
      if (ifChains < 3) {
        continue;
      }

      final line = lineFromOffset(source, source.indexOf('else if'));
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Open/Closed Principle opportunity',
          description:
              'Detected a long else-if chain that can become harder to extend safely.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'Conditional branching that keeps growing tends to duplicate rules and increase maintenance cost.',
          recommendation:
              'Consider replacing the chain with a lookup table, strategy pattern, or sealed/polymorphic dispatch so new behavior can be added without changing the existing branch structure.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}
