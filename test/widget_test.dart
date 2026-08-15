import 'package:LoveQuiz/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_mock.dart';

void main() {
  setUpAll(setUpFirebaseMocks);

  testWidgets('Al arrancar sin sesión, el splash lleva a la pantalla de login',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LoveQuizApp());

    // The splash screen shows the app title while loading.
    expect(find.text('LoveQuiz'), findsOneWidget);

    // Advance past the splash delay and the navigation to the login screen.
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
