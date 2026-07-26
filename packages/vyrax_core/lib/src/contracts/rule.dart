import 'package:vyrax_core/src/models/configuration.dart';
import 'package:vyrax_core/src/models/issue.dart';
import 'package:vyrax_core/src/models/issue_category.dart';

/// Context passed to rules by the execution engine.
abstract interface class VyraxRuleContext {
  /// Normalized project configuration.
  VyraxConfiguration get configuration;

  /// Absolute path to the project under analysis.
  String get projectPath;
}

/// Contract implemented by every rule in the Vyrax ecosystem.
abstract interface class VyraxRule {
  /// Stable rule identifier.
  String get id;

  /// Rule category used for grouping and filtering.
  VyraxIssueCategory get category;

  /// Runs the rule against a context and returns reported issues.
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context);
}
