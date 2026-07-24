import 'package:flutter_test/flutter_test.dart';

import 'package:concentration/main.dart';

void main() {
  testWidgets('affiche le titre du squelette', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Squelette prêt'), findsOneWidget);
  });

  testWidgets('incrémente le compteur au tap', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Compteur : 0'), findsOneWidget);

    await tester.tap(find.text('Incrémenter'));
    await tester.pump();

    expect(find.text('Compteur : 1'), findsOneWidget);
  });
}
