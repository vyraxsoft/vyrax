import 'package:test/test.dart';
import 'package:vyrax_core/vyrax_core.dart';

void main() {
  test('VyraxIssue can be instantiated', () {
    const issue = VyraxIssue(
      id: 'VYRAX001',
      message: 'Sample message',
      severity: VyraxSeverity.info,
      category: VyraxIssueCategory.architecture,
      location: 'lib/main.dart:1:1',
    );

    expect(issue.id, 'VYRAX001');
  });
}
