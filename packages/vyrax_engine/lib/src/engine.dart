import 'package:vyrax_core/vyrax_core.dart';

/// Placeholder analyzer engine contract.
abstract interface class VyraxAnalyzerEngine {
  /// Runs analysis with the provided rules and context.
  Future<List<VyraxIssue>> run({
    required VyraxRuleContext context,
    required List<VyraxRule> rules,
  });
}
