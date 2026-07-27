/// Severity levels used by Vyrax issues.
enum VyraxSeverity {
  /// Informational diagnostics.
  info,

  /// Warnings that should be reviewed.
  warning,

  /// Errors that require changes.
  error,

  /// Critical diagnostics that should block delivery.
  critical,
}
