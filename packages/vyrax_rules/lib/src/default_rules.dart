// ignore_for_file: public_member_api_docs

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

Map<String, double> computeQualityScores(List<VyraxIssue> issues) {
  final scores = <String, double>{
    'performance': 100,
    'maintainability': 100,
    'testability': 100,
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
        scores['performance'] = (scores['performance']! - impact).clamp(0, 100);
        break;
      case VyraxIssueCategory.widgets:
      case VyraxIssueCategory.architecture:
      case VyraxIssueCategory.domain:
      case VyraxIssueCategory.network:
        scores['maintainability'] = (scores['maintainability']! - impact).clamp(
          0,
          100,
        );
        break;
      case VyraxIssueCategory.state:
      case VyraxIssueCategory.testing:
        scores['testability'] = (scores['testability']! - impact).clamp(0, 100);
        break;
    }
  }

  return scores.map((key, value) => MapEntry(key, value.toDouble()));
}

double computeOverallQualityScore(Map<String, double> scores) {
  if (scores.isEmpty) {
    return 100;
  }

  final total = scores.values.fold<double>(0, (sum, value) => sum + value);
  return total / scores.length;
}
