import 'package:concentration/core/color/temporal_gradient.dart';
import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/features/echeances/domain/remaining_time.dart';
import 'package:concentration/features/echeances/domain/time_unit.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendu_couleur.dart';

/// 🔴 **T7 — `fondDeLaTuile` PORTE SON MUTANT.**
///
/// **Ce fichier existe parce qu'un outil de test peut mentir avec toute la
/// suite au vert**, et ce n'est pas une crainte : c'est le défaut **NB-7**, qui
/// a réellement laissé la tuile rendre *« toujours orange »* avec **112 tests
/// verts** en US-01.1. La sonde qui l'avait démontré était **jetable et hors
/// dépôt** ; ici elle devient **exécutable et rejouable à chaque `flutter
/// test`**.
///
/// ⛔ **Ce que ce fichier NE fait PAS** : il ne teste **aucun comportement
/// produit**. Il teste **l'instrument d'observation** — *« un contrôle portant
/// son mutant a été juste 7 fois sur 7 ; un contrôle purement lexical, faux
/// 7 fois sur 7 »* *(mesure d'US-00.5)*.
void main() {
  /// Le fond **intrus** : une couleur qui n'est **dans aucun token** et ne peut
  /// donc pas être confondue avec une couleur légitime du dégradé.
  const couleurIntruse = Color(0xFF00FF00);

  const progression = 0.25;
  const gradient = TemporalGradient();
  final fondAttendu = gradient.backgroundFor(progression).couleur;

  final temps = RemainingTime(
    unite: TimeUnit.heures,
    nombreAffiche: 6,
    progression: progression,
    estEchue: false,
    libelleAccessibilite: '6 heures',
  );

  /// La tuile **RÉELLE**, enveloppée dans un `Container` porteur d'une
  /// `decoration` — ⛔ le seul widget du SDK qui insère réellement une
  /// **seconde** `DecoratedBox` *(mesuré : `widgets/container.dart`, deux
  /// sites ; `Material` et `InkWell` ne la citent qu'en documentation)*.
  Future<Finder> monterAvecUneSecondeBoite(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 220,
              child: Container(
                key: const Key('enveloppe-de-la-sonde'),
                decoration: const BoxDecoration(color: couleurIntruse),
                child: EcheanceTile(
                  temps: temps,
                  description: '',
                  intention: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return find.byKey(const Key('enveloppe-de-la-sonde'));
  }

  /// ⛔ **L'ANCIEN sélecteur, reconstitué à l'identique** : par **position**,
  /// sans rien vérifier. Il vit **ici et nulle part ailleurs** — c'est le
  /// mutant, pas un utilitaire.
  Color selecteurParPosition(WidgetTester tester, Finder cible) {
    final boite = tester.widget<DecoratedBox>(
      find.descendant(of: cible, matching: find.byType(DecoratedBox)).first,
    );
    return (boite.decoration as BoxDecoration).color!;
  }

  /// ⛔ **L'état INTERMÉDIAIRE (US-01.2, T6)** : unicité assertée sur le
  /// **type**. Il ne mentait plus, mais il **rougissait** dès qu'une seconde
  /// boîte apparaissait — c'est ce que T7 devait lever **sans** relâcher
  /// l'unicité.
  Color selecteurParTypeUnique(WidgetTester tester, Finder cible) {
    final boites = find.descendant(
      of: cible,
      matching: find.byType(DecoratedBox),
    );
    expect(boites, findsOneWidget);
    final boite = tester.widget<DecoratedBox>(boites);
    return (boite.decoration as BoxDecoration).color!;
  }

  testWidgets('⛔ CONTRÔLE POSITIF — sans seconde boîte, les trois sélecteurs '
      's’accordent', (tester) async {
    // Sans lui, le test ci-dessous ne prouverait rien : « les sélecteurs
    // divergent » doit venir de la SECONDE BOÎTE, pas d’une divergence
    // permanente entre eux.
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 220,
              child: EcheanceTile(
                temps: temps,
                description: '',
                intention: null,
              ),
            ),
          ),
        ),
      ),
    );
    final cible = find.byType(EcheanceTile);

    expect(fondDeLaTuile(tester), fondAttendu);
    expect(selecteurParPosition(tester, cible), fondAttendu);
    expect(selecteurParTypeUnique(tester, cible), fondAttendu);
  });

  testWidgets(
    '🔴 avec une SECONDE boîte décorée, la sélection par CLÉ lit la BONNE',
    (tester) async {
      final cible = await monterAvecUneSecondeBoite(tester);

      // ⛔ CONTRÔLE POSITIF DU MONTAGE : le cas doit VRAIMENT porter deux
      // boîtes décorées, sinon tout ce qui suit est vide de sens.
      expect(
        find.descendant(of: cible, matching: find.byType(DecoratedBox)),
        findsNWidgets(2),
        reason:
            'le montage doit reproduire le cas de NB-7 : DEUX boîtes décorées '
            'sous la même cible',
      );

      expect(
        fondDeLaTuile(tester, tuile: cible),
        fondAttendu,
        reason:
            'la clé désigne la boîte de la TUILE, quelle que soit la boîte qui '
            'l’enveloppe',
      );
      expect(
        fondDeLaTuile(tester, tuile: cible),
        isNot(couleurIntruse),
        reason: 'et surtout : ⛔ jamais celle de l’enveloppe',
      );
    },
  );

  testWidgets(
    '🔴 LE MUTANT — le sélecteur par POSITION lit la MAUVAISE boîte, sans '
    'rougir',
    (tester) async {
      final cible = await monterAvecUneSecondeBoite(tester);

      // 🔴 C’est LE défaut NB-7, rendu exécutable : le sélecteur ne LÈVE PAS,
      // il rend une couleur — celle de l’ENVELOPPE. Un test de couleur écrit
      // dessus serait VERT en observant autre chose que la tuile.
      expect(
        selecteurParPosition(tester, cible),
        couleurIntruse,
        reason:
            'le faux vert de NB-7 : « .first » désigne l’EXTÉRIEURE, et rien '
            'ne le signale',
      );
      expect(
        selecteurParPosition(tester, cible),
        isNot(fondAttendu),
        reason:
            'et la couleur observée n’est PAS celle que la tuile peint — c’est '
            'exactement ce qui rendait AC-5 d’US-01.1 supprimable sans rouge',
      );
    },
  );

  testWidgets(
    '🔴 CE QUE T7 LÈVE — le sélecteur par TYPE, lui, ÉCHOUE sur le même arbre',
    (tester) async {
      final cible = await monterAvecUneSecondeBoite(tester);

      // ⛔ L’état d’US-01.2 ne mentait plus, mais il faisait rougir TOUS les
      // tests de couleur dès qu’une seconde boîte apparaissait (R-2). C’est
      // précisément pourquoi T7 passe AVANT T8 : le coût d’anticiper est nul,
      // le coût de découvrir est un faux rouge en masse.
      expect(
        () => selecteurParTypeUnique(tester, cible),
        throwsA(isA<TestFailure>()),
        reason:
            'si ceci cessait d’échouer, la démonstration de R-2 serait perdue '
            'et « T7 avant T8 » n’aurait plus de motif mesuré',
      );
    },
  );

  testWidgets(
    '🔴 la clé N’EST PAS DÉCORATIVE — sans elle, l’instrument ROUGIT au lieu '
    'de mentir',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ConcentrationTheme.sombre,
          home: const Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 220,
                // Une cible qui ne porte AUCUNE boîte portant la clé.
                child: DecoratedBox(
                  key: Key('sans-la-cle'),
                  decoration: BoxDecoration(color: couleurIntruse),
                ),
              ),
            ),
          ),
        ),
      );

      // ⛔ La propriété qui compte : l’instrument doit ÉCHOUER BRUYAMMENT, ⛔
      // jamais retomber sur « la première boîte trouvée ». Un jour où la clé
      // disparaîtrait du produit, aucun test de couleur ne doit rester vert.
      expect(
        () =>
            fondDeLaTuile(tester, tuile: find.byKey(const Key('sans-la-cle'))),
        throwsA(isA<TestFailure>()),
      );
    },
  );
}
