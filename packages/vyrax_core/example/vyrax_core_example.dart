import 'package:vyrax_core/vyrax_core.dart';

void main() {
  const issue = VyraxIssue(
    id: 'VYRAX_EXAMPLE',
    message: 'Core package is wired correctly.',
    severity: VyraxSeverity.info,
    category: VyraxIssueCategory.testing,
    location: 'example/vyrax_core_example.dart:1:1',
  );

  // Keep example intentionally minimal while still using the value.
  final message = issue.message;
  if (message.isEmpty) {
    throw StateError('Example message must not be empty.');
  }
}
