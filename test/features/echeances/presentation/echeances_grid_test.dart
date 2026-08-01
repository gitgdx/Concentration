import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/echeances/presentation/widgets/empty_echeances_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de la tuile, du placeholder et de la grille (T7 / T8 / T9).
void main() {
  final maintenant = DateTime(2026, 8, 1, 12);

  Echeance e(String id, Duration dans, [String description = 'Libellé']) =>
      Echeance(
        id: id,
        description: description,
        dateEcheance: maintenant.add(dans),
      );

  Widget sous(List<Echeance> echeances) => MaterialApp(
    theme: ConcentrationTheme.sombre,
    home: Scaffold(
      body: EcheancesGrid(echeances: echeances, clock: FakeClock(maintenant)),
    ),
  );

  group('tuile — le nombre est NU (RF-01)', () {
    testWidgets('affiche le nombre, et AUCUNE unité ni signe', (tester) async {
      await tester.pumpWidget(sous([e('a', const Duration(hours: 6))]));
      expect(find.text('6'), findsOneWidget);
      for (final interdit in [
        'h',
        'heures',
        'jours',
        'j',
        '+',
        '-',
        '/',
        '%',
      ]) {
        expect(
          find.textContaining(interdit, findRichText: true),
          findsNothing,
          reason: 'la tuile ne doit porter aucun « $interdit »',
        );
      }
    });

    testWidgets('le libellé sémantique porte le temps complet AVEC son unité', (
      tester,
    ) async {
      await tester.pumpWidget(
        sous([e('a', const Duration(hours: 6), 'Départ du train')]),
      );
      expect(
        find.bySemanticsLabel('6 heures, Départ du train'),
        findsOneWidget,
      );
    });

    testWidgets(
      'description VIDE : la tuile reste rendue, le nombre subsiste (I-3)',
      (tester) async {
        await tester.pumpWidget(sous([e('a', const Duration(hours: 6), '')]));
        expect(find.byType(EcheanceTile), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
      },
    );

    testWidgets(
      'le nombre utilise des chiffres à CHASSE FIXE (pas de saut de mise en page)',
      (tester) async {
        await tester.pumpWidget(sous([e('a', const Duration(hours: 6))]));
        final texte = tester.widget<Text>(find.text('6'));
        expect(
          texte.style?.fontFeatures?.map((f) => f.feature),
          contains('tnum'),
          reason: 'exigence fonctionnelle de DESIGN_SYSTEM : tabularFigures',
        );
      },
    );

    testWidgets('état « à zéro » : affiche 0, ne disparaît pas (AC-7)', (
      tester,
    ) async {
      await tester.pumpWidget(
        sous([e('echue', const Duration(days: -2), 'Passeport')]),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.byType(EcheanceTile), findsOneWidget);
      expect(
        find.bySemanticsLabel('échéance atteinte, Passeport'),
        findsOneWidget,
      );
    });
  });

  group('grille — ordre et bornes', () {
    testWidgets('une tuile par échéance', (tester) async {
      await tester.pumpWidget(
        sous([
          e('a', const Duration(hours: 2)),
          e('b', const Duration(days: 3)),
        ]),
      );
      expect(find.byType(EcheanceTile), findsNWidgets(2));
    });

    testWidgets('ordre par date croissante', (tester) async {
      await tester.pumpWidget(
        sous([
          e('loin', const Duration(days: 40)),
          e('proche', const Duration(hours: 2)),
          e('milieu', const Duration(days: 5)),
        ]),
      );
      final cles = tester
          .widgetList<EcheanceTile>(find.byType(EcheanceTile))
          .map((t) => (t.key! as ValueKey<String>).value)
          .toList();
      expect(cles, ['proche', 'milieu', 'loin']);
    });

    testWidgets('une échéance DÉPASSÉE est EN TÊTE (AC-6, clarify nº 2)', (
      tester,
    ) async {
      await tester.pumpWidget(
        sous([
          e('futur', const Duration(days: 10)),
          e('echue', const Duration(days: -5)),
          e('proche', const Duration(hours: 1)),
        ]),
      );
      final premiere = tester
          .widgetList<EcheanceTile>(find.byType(EcheanceTile))
          .first;
      expect((premiere.key! as ValueKey<String>).value, 'echue');
    });

    testWidgets(
      '9 tuiles rendues sans débordement, la 10ᵉ est bornée (RF-15)',
      (tester) async {
        await tester.pumpWidget(
          sous([for (var i = 0; i < 12; i++) e('e$i', Duration(days: i + 1))]),
        );
        expect(
          find.byType(EcheanceTile),
          findsNWidgets(ConcentrationTokens.tuilesMax),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('grille vide -> placeholder sobre, hub conservé (AC-9)', (
      tester,
    ) async {
      await tester.pumpWidget(sous([]));
      expect(find.byType(EmptyEcheancesPlaceholder), findsOneWidget);
      expect(find.text(EmptyEcheancesPlaceholder.message), findsOneWidget);
      expect(find.byType(EcheanceTile), findsNothing);
    });

    testWidgets('le placeholder ne porte AUCUN élément anxiogène', (
      tester,
    ) async {
      await tester.pumpWidget(sous([]));
      for (final interdit in [
        'Erreur',
        'erreur',
        'Attention',
        '!',
        'Exception',
      ]) {
        expect(find.textContaining(interdit), findsNothing);
      }
    });

    testWidgets('recalcule après avancée de l’horloge (RF-05)', (tester) async {
      final horloge = FakeClock(maintenant);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EcheancesGrid(
              echeances: [
                Echeance(
                  id: 'a',
                  description: 'x',
                  dateEcheance: maintenant.add(const Duration(hours: 6)),
                ),
              ],
              clock: horloge,
            ),
          ),
        ),
      );
      expect(find.text('6'), findsOneWidget);
      horloge.avancerDe(const Duration(hours: 2));
      await tester.pump(ConcentrationTokens.periodeRafraichissement);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsNothing);
    });
  });
}
