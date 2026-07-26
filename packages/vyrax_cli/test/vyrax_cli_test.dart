import 'package:test/test.dart';
import 'package:vyrax_cli/vyrax_cli.dart';

void main() {
  test('help message contains usage', () {
    expect(buildHelpMessage(), contains('Usage: vyrax <command> [arguments]'));
  });
}
