import 'package:test/test.dart';
import 'package:vyrax_rules/vyrax_rules.dart';

void main() {
  test('package loads', () {
    expect(vyraxRulesPackageName, 'vyrax_rules');
  });

  test('default rule set includes twenty three rules', () {
    final rules = createDefaultRules();

    expect(rules, hasLength(23));
    expect(
      rules.map((rule) => rule.id).toSet(),
      equals({
        'VYX001',
        'VYX002',
        'VYX003',
        'VYX004',
        'VYX005',
        'VYX006',
        'VYX007',
        'VYX008',
        'VYX009',
        'VYX010',
        'VYX011',
        'VYX012',
        'VYX013',
        'VYX014',
        'VYX015',
        'VYX016',
        'VYX017',
        'VYX018',
        'VYX019',
        'VYX020',
        'VYX021',
        'VYX022',
        'VYX023',
      }),
    );
  });
}

String get vyraxRulesPackageName => 'vyrax_rules';
