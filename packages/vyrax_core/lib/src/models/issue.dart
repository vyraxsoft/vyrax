import 'package:vyrax_core/src/models/issue_category.dart';
import 'package:vyrax_core/src/models/severity.dart';

/// Immutable diagnostic issue produced by a Vyrax rule.
final class VyraxIssue {
  /// Creates a new issue.
  const VyraxIssue({
    required this.id,
    required this.message,
    required this.severity,
    required this.category,
    required this.location,
    this.suggestion,
  });

  /// Stable identifier for machine-readable output.
  final String id;

  /// Human-readable issue description.
  final String message;

  /// Issue severity.
  final VyraxSeverity severity;

  /// Domain category for reporting and dashboards.
  final VyraxIssueCategory category;

  /// Source location string (for example `lib/main.dart:12:4`).
  final String location;

  /// Optional quick remediation suggestion.
  final String? suggestion;
}
