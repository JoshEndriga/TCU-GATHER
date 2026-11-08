import 'package:flutter_test/flutter_test.dart';
import 'package:tcu_gather/main.dart';

void main() {
  testWidgets('TCU Gather smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TcuGatherApp());
    expect(find.text('TCU: GATHER'), findsOneWidget);
  });
}
