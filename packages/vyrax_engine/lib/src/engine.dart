import 'package:vyrax_core/vyrax_core.dart';

/// Placeholder analyzer engine contract.
abstract interface class VyraxAnalyzerEngine {
  /// Runs analysis with the provided rules and context.
  Future<List<VyraxIssue>> run({
    required VyraxRuleContext context,
    required List<VyraxRule> rules,
  });
}

/// Default engine implementation that executes rules sequentially.
final class DefaultVyraxAnalyzerEngine implements VyraxAnalyzerEngine {
  /// Creates the default sequential engine.
  const DefaultVyraxAnalyzerEngine();

  @override
  Future<List<VyraxIssue>> run({
    required VyraxRuleContext context,
    required List<VyraxRule> rules,
  }) async {
    final issues = <VyraxIssue>[];

    for (final rule in rules) {
      final result = await rule.evaluate(context);
      issues.addAll(result);
    }

    return issues;
  }
}

/// Minimal context implementation used by the CLI.
final class DefaultVyraxRuleContext implements VyraxRuleContext {
  /// Creates a rule context for local project execution.
  const DefaultVyraxRuleContext({
    required this.configuration,
    required this.projectPath,
  });

  @override
  final VyraxConfiguration configuration;

  @override
  final String projectPath;
}
