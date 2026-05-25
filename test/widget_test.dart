import 'package:flutter_test/flutter_test.dart';
import 'package:lovequiz_app/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LoveQuizApp());

    // Verify that the app title is present
    expect(find.text('LoveQuiz'), findsOneWidget);
  });
}
