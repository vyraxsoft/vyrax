import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects high-level reactive wrappers that can cause large rebuild scopes.
final class LargeConsumerScopeRule implements VyraxRule {
  /// Creates a [LargeConsumerScopeRule].
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

/// Detects use of `setState` when a global state pattern is configured.
final class SetStateWithStateManagementRule implements VyraxRule {
  /// Creates a [SetStateWithStateManagementRule].
  const SetStateWithStateManagementRule();

  @override
  String get id => 'VYX006';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.state;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final stateManagement = _configuredStateManagement(
      context.configuration.values,
    );
    if (stateManagement == null || stateManagement == 'unknown') {
      return const <VyraxIssue>[];
    }

    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final pattern = RegExp(r'\bsetState\s*\(');

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in pattern.allMatches(source)) {
        final line = lineFromOffset(source, match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'setState used with state management',
            description:
                'Detected setState() in a project configured to use $stateManagement.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Mixing local setState with an app-wide state pattern can increase inconsistency and make UI updates harder to reason about.',
            recommendation:
                'Move UI state transitions to your configured state layer ($stateManagement) and keep widgets as simple renderers when possible.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

String? _configuredStateManagement(Map<String, Object?> values) {
  final state = values['state_management'];
  if (state is! Map<String, Object?>) {
    return null;
  }

  final type = state['type'];
  if (type is! String) {
    return null;
  }

  return type.toLowerCase();
}

/// Detects large build trees that subscribe reactively near the root.
final class BroadReactiveRebuildScopeRule implements VyraxRule {
  /// Creates a [BroadReactiveRebuildScopeRule].
  const BroadReactiveRebuildScopeRule();

  @override
  String get id => 'VYX013';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.state;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final broadReactivePattern = RegExp(
      r'(context\.watch\s*<|ref\.watch\s*\(|Provider\.of\s*<[^>]+>\s*\([^)]*listen\s*:\s*true|BlocBuilder\s*<|Consumer\s*<)',
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        if (!broadReactivePattern.hasMatch(block.content)) {
          continue;
        }

        final widgets = RegExp(
          r'\b[A-Z][A-Za-z0-9_]*\s*\(',
        ).allMatches(block.content).length;
        if (widgets < 16) {
          continue;
        }

        final match = broadReactivePattern.firstMatch(block.content);
        if (match == null) {
          continue;
        }
        final line = lineFromOffset(source, block.startOffset + match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Broad reactive rebuild scope',
            description:
                'Reactive state subscription appears inside a large build subtree (widgets: $widgets).',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Large reactive boundaries can trigger unnecessary rebuilds and degrade frame stability.',
            recommendation:
                'Move reactive listeners lower in the widget tree and use selectors/buildWhen to rebuild only affected widgets.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}
