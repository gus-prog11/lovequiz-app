import 'package:LoveQuiz/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_mock.dart';

void main() {
  setUpAll(setUpFirebaseMocks);

  testWidgets('App loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LoveQuizApp());

    // Verify that the app title is present on the splash screen.
    expect(find.text('LoveQuiz'), findsOneWidget);

    // Advance past the splash delay and the navigation to the login screen.
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
