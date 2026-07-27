import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';
import 'package:vyrax_rules/src/solid_rules/solid_rule_helpers.dart';

final class SingleResponsibilityOpportunityRule implements VyraxRule {
  const SingleResponsibilityOpportunityRule();

  @override
  String get id => 'VYX018';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    return [
      for (final file in collectDartFiles(context.projectPath))
        ...inspectClassBodies(file, (className, body, line) {
          final fieldCount = RegExp(
            r'(?m)^\s*(?:final|late\s+final|late|var|const)?\s*[A-Za-z0-9_<>, ?]+\s+[a-zA-Z_][A-Za-z0-9_]*\s*;',
          ).allMatches(body).length;
          final methodCount = RegExp(
            r'(?m)^\s*(?:@[A-Za-z0-9_]+(?:\([^\)]*\))?\s*)*(?:static\s+)?(?:[A-Za-z0-9_<>, ?]+\s+)?[a-zA-Z_][A-Za-z0-9_]*\s*\([^;{}]*\)\s*(?:async\s*)?(?:\{|=>)',
          ).allMatches(body).length;

          if (fieldCount + methodCount < 10 || body.length < 1200) {
            return null;
          }

          return VyraxIssue(
            id: id,
            title: 'Single Responsibility Principle opportunity',
            description:
                'Class `$className` appears to group many fields and behaviors in one place.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Splitting responsibilities improves test isolation, reduces ripple effects, and makes the class easier to understand.',
            recommendation:
                'Consider extracting collaborating classes or moving secondary responsibilities to dedicated services, adapters, or widgets.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          );
        }),
    ];
  }
}
