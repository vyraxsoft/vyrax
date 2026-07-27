// ignore_for_file: public_member_api_docs

import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

List<VyraxRule> createMvpRules() => const [
  FutureInsideBuildRule(),
  NetworkInsideBuildRule(),
  MultiplePublicClassesRule(),
  BuildComplexityRule(),
  LargeConsumerScopeRule(),
];

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

final class MultiplePublicClassesRule implements VyraxRule {
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

final class BuildComplexityRule implements VyraxRule {
  const BuildComplexityRule();

  @override
  String get id => 'VYX004';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        final widgets = RegExp(
          r'\b[A-Z][A-Za-z0-9_]*\s*\(',
        ).allMatches(block.content).length;
        final conditions = RegExp(
          r'\bif\s*\(',
        ).allMatches(block.content).length;
        final builders = RegExp(
          r'\b[A-Za-z0-9_]*Builder\s*\(',
        ).allMatches(block.content).length;

        final isComplex = widgets > 24 || conditions > 4 || builders > 4;
        if (!isComplex) {
          continue;
        }

        final line = lineFromOffset(source, block.startOffset);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Build complexity',
            description:
                'build() seems too complex (widgets: $widgets, conditions: $conditions, builders: $builders).',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Complex build methods reduce readability and increase regressions.',
            recommendation:
                'Split UI into smaller widgets and move logic outside build().',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

final class LargeConsumerScopeRule implements VyraxRule {
  const LargeConsumerScopeRule();

  @override
  String get id => 'VYX005';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.state;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final pattern = RegExp(
      r'(Consumer|BlocBuilder|ValueListenableBuilder)[\s\S]{0,400}Scaffold\s*\(',
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      final match = pattern.firstMatch(source);
      if (match == null) {
        continue;
      }

      final line = lineFromOffset(source, match.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Large Consumer scope',
          description:
              'Consumer/BlocBuilder appears to wrap a high-level widget like Scaffold.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'Large reactive scope can rebuild more of the UI than necessary.',
          recommendation:
              'Move the reactive boundary deeper in the widget tree when possible.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}
