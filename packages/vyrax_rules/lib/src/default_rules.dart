import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rules/architecture/architecture_rules.dart';
import 'package:vyrax_rules/src/rules/domain/domain_rules.dart';
import 'package:vyrax_rules/src/rules/lifecycle/lifecycle_rules.dart';
import 'package:vyrax_rules/src/rules/performance/performance_rules.dart';
import 'package:vyrax_rules/src/rules/state/state_rules.dart';
import 'package:vyrax_rules/src/rules/testing/testing_rules.dart';
import 'package:vyrax_rules/src/rules/widgets/widget_tree_rules.dart';
import 'package:vyrax_rules/src/solid_rules/dependency_inversion_opportunity_rule.dart';
import 'package:vyrax_rules/src/solid_rules/open_closed_opportunity_rule.dart';
import 'package:vyrax_rules/src/solid_rules/single_responsibility_opportunity_rule.dart';
import 'package:vyrax_rules/src/solid_rules/solid_opportunity_rule.dart';

/// Creates the default Vyrax rule set.
List<VyraxRule> createDefaultRules() => const [
  FutureInsideBuildRule(),
  NetworkInsideBuildRule(),
  MultiplePublicClassesRule(),
  BuildComplexityRule(),
  LargeConsumerScopeRule(),
  SetStateWithStateManagementRule(),
  UnboundedScrollableInColumnRule(),
  CleanArchitectureWithoutUseCasesRule(),
  PresentationDependsOnDataLayerRule(),
  DirectExternalPackageInPresentationRule(),
  SingletonOveruseRule(),
  MissingInternationalizationRule(),
  BroadReactiveRebuildScopeRule(),
  ErrorModelWithoutFactoryRule(),
  HardcodedUiTextRule(),
  RepeatedMagicNumbersRule(),
  LargeFileRule(),
  WidgetLifecycleRule(),
  WidgetTreeComplexityRule(),
  SingleResponsibilityOpportunityRule(),
  OpenClosedOpportunityRule(),
  DependencyInversionOpportunityRule(),
  SolidOpportunityRule(),
];

/// Computes category quality scores based on detected issues.
Map<String, double> computeQualityScores(List<VyraxIssue> issues) {
  final penalties = <String, int>{
    'performance': 0,
    'maintainability': 0,
    'testability': 0,
  };

  for (final issue in issues) {
    final impact = issue.severity == VyraxSeverity.critical
        ? 20
        : issue.severity == VyraxSeverity.error
        ? 15
        : issue.severity == VyraxSeverity.warning
        ? 7
        : 2;

    switch (issue.category) {
      case VyraxIssueCategory.performance:
        penalties['performance'] = penalties['performance']! + impact;
        break;
      case VyraxIssueCategory.widgets:
      case VyraxIssueCategory.architecture:
      case VyraxIssueCategory.domain:
      case VyraxIssueCategory.network:
        penalties['maintainability'] = penalties['maintainability']! + impact;
        break;
      case VyraxIssueCategory.state:
      case VyraxIssueCategory.testing:
        penalties['testability'] = penalties['testability']! + impact;
        break;
    }
  }

  return penalties.map((key, value) => MapEntry(key, _scoreFromPenalty(value)));
}

double _scoreFromPenalty(int penalty) {
  if (penalty <= 0) {
    return 100;
  }

  // Non-linear decay avoids hard-clamping to zero and reflects incremental
  // improvements when issue count drops significantly.
  const normalization = 70.0;
  return 100 / (1 + (penalty / normalization));
}

/// Computes the overall quality score from per-category scores.
double computeOverallQualityScore(Map<String, double> scores) {
  if (scores.isEmpty) {
    return 100;
  }

  final total = scores.values.fold<double>(0, (sum, value) => sum + value);
  return total / scores.length;
}
