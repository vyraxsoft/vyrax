/// Shared configuration model passed to engines, rules, and plugins.
final class VyraxConfiguration {
  /// Creates a configuration wrapper around normalized values.
  const VyraxConfiguration({required this.values});

  /// Flat key-value configuration map.
  final Map<String, Object?> values;
}
