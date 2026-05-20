import 'package:flutter_test/flutter_test.dart';
import 'package:pinjamin_mobile/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const PinjamINApp());
    expect(find.text('PinjamIN'), findsOneWidget);
  });
}
