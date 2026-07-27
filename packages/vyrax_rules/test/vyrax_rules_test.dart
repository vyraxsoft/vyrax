import 'package:test/test.dart';
import 'package:vyrax_rules/vyrax_rules.dart';

void main() {
  test('package loads', () {
    expect(vyraxRulesPackageName, 'vyrax_rules');
  });

  test('mvp rule set includes five rules', () {
    final rules = createMvpRules();

    expect(rules, hasLength(5));
    expect(
      rules.map((rule) => rule.id).toSet(),
      equals({'VYX001', 'VYX002', 'VYX003', 'VYX004', 'VYX005'}),
    );
  });
}

String get vyraxRulesPackageName => 'vyrax_rules';
