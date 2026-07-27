import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

final class FutureInsideBuildRule implements VyraxRule {
  const FutureInsideBuildRule();

  @override
  String get id => 'VYX001';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.performance;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final futurePattern = RegExp(r'FutureBuilder[\s\S]*?future\s*:');

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        final match = futurePattern.firstMatch(block.content);
        if (match == null) {
          continue;
        }

        final line = lineFromOffset(source, block.startOffset + match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Future inside build',
            description:
                'FutureBuilder recreates its Future every time build() executes.',
            severity: VyraxSeverity.error,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact: 'This may trigger unnecessary work and repeated requests.',
            recommendation:
                'Move the Future outside build(), cache it, or use state management.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

final class NetworkInsideBuildRule implements VyraxRule {
  const NetworkInsideBuildRule();

  @override
  String get id => 'VYX002';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.performance;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final networkPattern = RegExp(
      r'(await\s+)?(dio|http|client)\s*\.\s*(get|post|put|patch|delete)\s*\(',
      caseSensitive: false,
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        final match = networkPattern.firstMatch(block.content);
        if (match == null) {
          continue;
        }

        final line = lineFromOffset(source, block.startOffset + match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Network request inside build',
            description:
                'Detected an HTTP call inside build(), which can execute repeatedly.',
            severity: VyraxSeverity.error,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact: 'May trigger duplicated network traffic and UI jank.',
            recommendation:
                'Move network requests to a controller, initState(), or state layer.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}
