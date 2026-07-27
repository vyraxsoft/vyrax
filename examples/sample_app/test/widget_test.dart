import 'package:flutter_test/flutter_test.dart';

import 'package:sample_app/main.dart';

void main() {
  testWidgets('Bad practices screen renders and responds to tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bad Practices Playground'), findsOneWidget);
    expect(find.text('Increment counter'), findsOneWidget);
    expect(find.text('Even value'), findsOneWidget);

    await tester.ensureVisible(find.text('Increment counter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment counter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 0 -> 1, so "Even value" should no longer be visible.
    expect(find.text('Even value'), findsNothing);
  });
}
