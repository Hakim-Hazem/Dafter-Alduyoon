import 'package:flutter_test/flutter_test.dart';
import 'package:dayn_debt_manager/app.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(const DebtApp());
    expect(find.text('دَيْني'), findsOneWidget);
  });
}
