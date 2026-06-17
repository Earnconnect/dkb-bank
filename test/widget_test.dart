import 'package:flutter_test/flutter_test.dart';
import 'package:dkb_bank/main.dart';

void main() {
  testWidgets('DKB app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DkbApp());
    expect(find.byType(DkbApp), findsOneWidget);
  });
}
