import 'package:vyrax_core/vyrax_core.dart';

/// Minimal registry abstraction for organizing rule instances.
abstract interface class VyraxRuleRegistry {
  /// All currently registered rules.
  List<VyraxRule> get rules;
}

/// In-memory registry for a fixed list of rules.
final class ListVyraxRuleRegistry implements VyraxRuleRegistry {
  /// Creates a registry with a preloaded immutable rule list.
  const ListVyraxRuleRegistry(this.rules);

  @override
  final List<VyraxRule> rules;
}
