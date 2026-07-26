import 'package:vyrax_core/src/contracts/rule.dart';

/// Plugin contract for external rule bundles.
abstract interface class VyraxPlugin {
  /// Stable plugin identifier.
  String get id;

  /// Rules contributed by this plugin.
  List<VyraxRule> get rules;
}
