import 'package:vyrax_core/src/models/issue_category.dart';
import 'package:vyrax_core/src/models/severity.dart';

/// Immutable diagnostic issue produced by a Vyrax rule.
final class VyraxIssue {
  /// Creates a new issue.
  const VyraxIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.file,
    required this.line,
    this.impact,
    this.recommendation,
    this.documentationUrl,
  });

  /// Stable identifier for machine-readable output.
  final String id;

  /// Human-readable title.
  final String title;

  /// Human-readable issue description.
  final String description;

  /// Issue severity.
  final VyraxSeverity severity;

  /// Domain category for reporting and dashboards.
  final VyraxIssueCategory category;

  /// Project-relative file path where the issue was found.
  final String file;

  /// 1-based line number where the issue was found.
  final int line;

  /// Optional impact explanation.
  final String? impact;

  /// Optional remediation recommendation.
  final String? recommendation;

  /// Optional documentation URL.
  final String? documentationUrl;

  /// Backward-compatible message alias.
  String get message => description;

  /// Source location string (for example `lib/main.dart:12`).
  String get location => '$file:$line';
}
