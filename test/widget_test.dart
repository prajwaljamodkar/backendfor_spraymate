import 'package:flutter_test/flutter_test.dart';
import 'package:spraymate/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Spraymate'), findsOneWidget);
  });
}
