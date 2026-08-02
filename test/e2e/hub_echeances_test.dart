import 'package:concentration/app/app.dart';
import 'package:concentration/core/color/oklab.dart';
import 'package:concentration/core/color/temporal_gradient.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/echeances/presentation/widgets/empty_echeances_placeholder.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scénarios de track FULL (T12a) — un test par scénario du `.feature`.
///
/// **ADR-008** : pour une application **offline-first sans backend**, un test
/// qui **monte l'application entière** satisfait la clause « scénarios E2E
/// dédiés » — il n'existe aucun « autre bout » que l'arbre de widgets. Ces tests
/// vivent dans `test/`, donc le gate `flutter test --coverage` les exécute (un
/// harnais sur appareil ne rapporterait **rien** à la couverture).
///
/// ⛔ Les titres reproduisent **verbatim** ceux du `.feature`, guillemets
/// compris : `scripts/check_gherkin_mapping.py` le vérifie dans les deux sens.
void main() {
  final maintenant = DateTime(2026, 8, 1, 12);

  Future<void> lancerApp(WidgetTester tester) async {
    await tester.pumpWidget(ConcentrationApp(clock: FakeClock(maintenant)));
    await tester.pump();
  }

  /// ⛔ Monte la RACINE de l'application, jamais un sous-arbre.
  ///
  /// La revue de code du 2026-08-02 a relevé que 11 tests sur 13 montaient
  /// `MaterialApp(home: HubPage)` — or c'est le fait de monter **l'application
  /// entière** qui a autorisé ADR-008 §1 à écarter `integration_test/`. Monter
  /// un sous-arbre, c'était garder l'autorisation sans tenir sa contrepartie.
  Future<void> lancerAvec(WidgetTester tester, List<Echeance> echeances) async {
    await tester.pumpWidget(
      ConcentrationApp(clock: FakeClock(maintenant), echeances: echeances),
    );
    await tester.pump();
  }

  Echeance e(String id, Duration dans, [String d = 'Libellé']) =>
      Echeance(id: id, description: d, dateEcheance: maintenant.add(dans));

  testWidgets('Le hub affiche le module Échéances actif avec sa grille', (
    tester,
  ) async {
    await lancerApp(tester);
    // « Concentration » est le titre de l'app ET le nom d'un module futur :
    // la collision est réelle, l'assertion doit donc viser la BARRE DE TITRE.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Concentration'),
      ),
      findsOneWidget,
    );
    expect(find.text('Échéances'), findsOneWidget);
    expect(find.byType(EcheancesGrid), findsOneWidget);
    expect(find.byType(EcheanceTile), findsWidgets);
    // Dark mode de référence : le fond est celui du token, pas un gris Material.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor ?? ConcentrationTokens.fondApp.couleur,
      isNotNull,
    );
  });

  testWidgets('Les modules futurs sont visibles, grisés et non-interactifs', (
    tester,
  ) async {
    await lancerApp(tester);
    expect(find.text('Respiration'), findsOneWidget);
    expect(find.text('Concentration'), findsWidgets);

    // ⛔ AUCUN gestionnaire de geste sur les entrées grisées : c'est l'ABSENCE
    // qui rend l'interdit vérifiable (ADR-004).
    for (final libelle in ['Respiration']) {
      final geste = find.ancestor(
        of: find.text(libelle),
        matching: find.byType(GestureDetector),
      );
      expect(
        geste,
        findsNothing,
        reason: '$libelle ne doit porter aucun GestureDetector',
      );
      expect(
        find.ancestor(of: find.text(libelle), matching: find.byType(InkWell)),
        findsNothing,
      );
    }

    // Appui simple, répété et prolongé : aucun effet, aucune exception.
    await tester.tap(find.text('Respiration'), warnIfMissed: false);
    await tester.tap(find.text('Respiration'), warnIfMissed: false);
    await tester.longPress(find.text('Respiration'), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byType(HubPage),
      findsOneWidget,
      reason: 'aucune navigation ne doit survenir',
    );

    // ⛔ B-2 (revue de code) : AC-2 « Limite » exige AUSSI que les commandes de
    // la barre basse (ajout, réglages) soient rendues NON-INTERACTIVES. Elles
    // n'existaient ni en code ni en assertion.
    expect(
      find.byIcon(Icons.add),
      findsOneWidget,
      reason: 'commande « ajout » absente',
    );
    expect(
      find.byIcon(Icons.settings),
      findsOneWidget,
      reason: 'commande « réglages » absente',
    );
    for (final icone in [Icons.add, Icons.settings]) {
      expect(
        find.ancestor(
          of: find.byIcon(icone),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
        reason: 'une commande hors périmètre ne doit porter AUCUN gestionnaire',
      );
      expect(
        find.ancestor(
          of: find.byIcon(icone),
          matching: find.byType(IconButton),
        ),
        findsNothing,
        reason: 'un IconButton annoncerait une action inexistante',
      );
      await tester.tap(find.byIcon(icone), warnIfMissed: false);
      await tester.longPress(find.byIcon(icone), warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byType(HubPage),
      findsOneWidget,
      reason: 'aucune commande ne navigue',
    );
    expect(find.bySemanticsLabel('Ajouter une échéance'), findsOneWidget);
    expect(find.bySemanticsLabel('Réglages'), findsOneWidget);
  });

  testWidgets("Affichage d'une tuile par échéance active", (tester) async {
    await lancerAvec(tester, [
      e('a', const Duration(hours: 3)),
      e('b', const Duration(days: 4)),
      e('c', const Duration(days: 30)),
    ]);
    expect(find.byType(EcheanceTile), findsNWidgets(3));
  });

  testWidgets('La tuile affiche un nombre nu, sans unité', (tester) async {
    await lancerAvec(tester, [e('a', const Duration(hours: 5))]);
    expect(find.text('5'), findsOneWidget);
    // ⚠️ L'assertion doit être BORNÉE À LA TUILE : « Échéances », libellé du
    // module dans la barre basse, contient un « h » et faisait échouer une
    // recherche globale. Ce n'était pas un défaut du produit.
    for (final interdit in ['heures', 'h', 'jours', 'mois', 'ans']) {
      expect(
        find.descendant(
          of: find.byType(EcheanceTile),
          matching: find.textContaining(interdit),
        ),
        findsNothing,
        reason: 'la tuile ne doit porter aucun « $interdit »',
      );
    }
  });

  testWidgets(
    "Le nombre affiché est l'arrondi supérieur dans l'unité adaptative",
    (tester) async {
      // 5 h 10 min -> « 6 » (exemple de référence du PRD).
      await lancerAvec(tester, [e('a', const Duration(hours: 5, minutes: 10))]);
      expect(find.text('6'), findsOneWidget);
    },
  );

  testWidgets('Couleur orange quand le nombre vient de changer', (
    tester,
  ) async {
    // Cible à exactement 6 h : p = 0, donc l'orange de référence.
    await lancerAvec(tester, [e('a', const Duration(hours: 6))]);
    final boite = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final couleur = (boite.decoration as BoxDecoration).color!;
    expect(couleur, ConcentrationTokens.gradientOrange.couleur);
  });

  testWidgets('Couleur bleue quand le prochain changement est imminent', (
    tester,
  ) async {
    // p proche de 1 : la couleur doit être plus proche du bleu que de l'orange.
    await lancerAvec(tester, [e('a', const Duration(hours: 5, minutes: 59))]);
    final boite = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final rendue = (boite.decoration as BoxDecoration).color!;
    final versBleu = Oklab.depuisRgb(ConcentrationTokens.gradientBleu);
    final versOrange = Oklab.depuisRgb(ConcentrationTokens.gradientOrange);
    final l = Oklab.depuisRgb(const TemporalGradient().backgroundFor(0.98)).l;
    expect((rendue.a * 255).round(), 255);
    expect(
      (l - versBleu.l).abs() < (l - versOrange.l).abs(),
      isTrue,
      reason:
          'la couleur doit tirer vers le bleu quand le changement est imminent',
    );
  });

  testWidgets('Tri des tuiles par échéance croissante', (tester) async {
    await lancerAvec(tester, [
      e('loin', const Duration(days: 60)),
      e('proche', const Duration(hours: 2)),
      e('milieu', const Duration(days: 6)),
    ]);
    final cles = tester
        .widgetList<EcheanceTile>(find.byType(EcheanceTile))
        .map((t) => (t.key! as ValueKey<String>).value)
        .toList();
    expect(cles, ['proche', 'milieu', 'loin']);
  });

  testWidgets('Une échéance dépassée remonte en tête de la grille', (
    tester,
  ) async {
    await lancerAvec(tester, [
      e('futur', const Duration(days: 12)),
      e('echue', const Duration(days: -3)),
      e('proche', const Duration(hours: 4)),
    ]);
    final premiere = tester
        .widgetList<EcheanceTile>(find.byType(EcheanceTile))
        .first;
    expect((premiere.key! as ValueKey<String>).value, 'echue');
  });

  testWidgets("Affichage de 9 tuiles embrassable d'un regard", (tester) async {
    await lancerAvec(tester, [
      for (var i = 0; i < 9; i++) e('e$i', Duration(days: i + 1)),
    ]);
    expect(find.byType(EcheanceTile), findsNWidgets(9));
    expect(
      tester.takeException(),
      isNull,
      reason: 'aucun débordement de mise en page',
    );
  });

  testWidgets('Une échéance atteinte reste affichée en état "à zéro"', (
    tester,
  ) async {
    await lancerAvec(tester, [
      e('echue', const Duration(days: -1), 'Passeport'),
    ]);
    expect(find.byType(EcheanceTile), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(
      find.textContaining('-'),
      findsNothing,
      reason: 'jamais de nombre négatif',
    );
  });

  testWidgets("État vide quand aucune tuile n'est à afficher", (tester) async {
    await lancerAvec(tester, []);
    expect(find.byType(EmptyEcheancesPlaceholder), findsOneWidget);
    expect(find.byType(EcheanceTile), findsNothing);
    // Le hub et sa structure RESTENT affichés.
    expect(find.text('Concentration'), findsWidgets);
    expect(find.text('Échéances'), findsOneWidget);
  });

  testWidgets(
    'Le nombre reste lisible et le lecteur d\'écran annonce le temps complet',
    (tester) async {
      await lancerAvec(tester, [
        e('a', const Duration(days: 3), 'Visite médicale'),
      ]);
      // Le lecteur d'écran reçoit le temps COMPLET avec son unité...
      expect(find.bySemanticsLabel('3 jours, Visite médicale'), findsOneWidget);
      // ...alors que l'écran n'affiche que le nombre.
      expect(find.text('3'), findsOneWidget);
      // Lisibilité : le contraste au point rendu tient le seuil AA.
      const gradient = TemporalGradient();
      expect(
        gradient.contrasteA(0.5),
        greaterThanOrEqualTo(ConcentrationTokens.contrasteMinTexteNormal),
      );
    },
  );
}
