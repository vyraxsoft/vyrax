import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

final class DependencyInversionOpportunityRule implements VyraxRule {
  const DependencyInversionOpportunityRule();

  @override
  String get id => 'VYX020';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.testing;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final presentationOrDomainPath = RegExp(
      r'(^|/)(presentation|ui|view[s]?|screen[s]?|widget[s]?|domain)(/|$)',
    );
    final concreteDependencyPattern = RegExp(
      '\\b(?:Dio|HttpClient|SharedPreferences|FirebaseFirestore|\\w+(?:Repository|Service|Client|Gateway|Controller|Handler|DataSource|Datasource|Api))\\s*\\(',
    );

    for (final file in files) {
      if (!presentationOrDomainPath.hasMatch(file.path)) {
        continue;
      }

      final source = file.readAsStringSync();
      final match = concreteDependencyPattern.firstMatch(source);
      if (match == null) {
        continue;
      }

      final concreteName =
          match.group(0)?.split('(').first.trim() ?? 'concrete dependency';
      final line = lineFromOffset(source, match.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Dependency Inversion Principle opportunity',
          description:
              'Detected direct creation of `$concreteName` in a higher-level module.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'High-level modules depending on concrete implementations are harder to mock, replace, and test.',
          recommendation:
              'Depend on abstractions and inject the concrete implementation from the outside (constructor, provider, or locator). This usually improves testability and reduces coupling.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}
