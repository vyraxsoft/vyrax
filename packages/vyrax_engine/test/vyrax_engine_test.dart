import 'package:test/test.dart';
import 'package:vyrax_engine/vyrax_engine.dart';

void main() {
  test('exports engine contract', () {
    expect(VyraxAnalyzerEngine, isNotNull);
  });
}
