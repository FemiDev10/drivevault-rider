import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const DriveVaultApp());
    expect(find.byType(DriveVaultApp), findsOneWidget);
  });
}
