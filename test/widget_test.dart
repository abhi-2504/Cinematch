import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/main.dart';

void main() {
  testWidgets('CineMatch app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CineMatchApp());

    expect(find.text('CineMatch'), findsOneWidget);
  });
}