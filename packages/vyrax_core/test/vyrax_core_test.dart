import 'package:test/test.dart';
import 'package:vyrax_core/vyrax_core.dart';

void main() {
  test('VyraxIssue can be instantiated', () {
    const issue = VyraxIssue(
      id: 'VYRAX001',
      title: 'Sample title',
      description: 'Sample message',
      severity: VyraxSeverity.info,
      category: VyraxIssueCategory.architecture,
      file: 'lib/main.dart',
      line: 1,
    );

    expect(issue.id, 'VYRAX001');
    expect(issue.location, 'lib/main.dart:1');
  });
}
