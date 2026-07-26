import 'package:vyrax_engine/vyrax_engine.dart';

void main() {
  // Placeholder import usage proving package wiring.
  const registryType = VyraxRuleRegistry;
  if (registryType.toString().isEmpty) {
    throw StateError('Registry type should be available.');
  }
}
