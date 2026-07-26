import 'package:vyrax_core/vyrax_core.dart';

/// Minimal registry abstraction for organizing rule instances.
abstract interface class VyraxRuleRegistry {
  /// All currently registered rules.
  List<VyraxRule> get rules;
}
