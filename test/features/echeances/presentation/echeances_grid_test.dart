import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/remaining_time.dart';
import 'package:concentration/features/echeances/domain/remaining_time_calculator.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/echeances/presentation/widgets/empty_echeances_placeholder.dart';
import 'package:flutter/gestures.dart';
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
      body: EcheancesGrid(
        echeances: echeances,
        clock: FakeClock(maintenant),
        // ⛔ `null` EXPLICITE : ces tests-là n'exercent AUCUN retrait, donc
        // l'échue n'a rien à activer. Le retrait a son propre fichier.
        onRetirer: null,
      ),
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
  });

  // ⛔ Le budget est INDÉPENDANT de la source qu'il contrôle. L'assertion
  // précédente pumpait `ConcentrationTokens.periodeRafraichissement`
  // ELLE-MÊME : elle restait donc vraie pour 30 s comme pour 1 HEURE (mutant
  // `QA-M7`, survivant). Une assertion auto-référentielle ne se renforce pas,
  // elle se REMPLACE — c'est la classe de défaut exacte de B-1.
  //
  // La valeur vient de l'AC-4 « Limite » / RF-05 — « au minimum une fois par
  // minute, indispensable pour l'unité heures ». Elle est écrite UNE fois, et
  // les deux assertions ci-dessous la partagent : deux copies d'un même seuil
  // dérivent.
  const budgetRf05 = Duration(minutes: 1);

  group('RF-05 — le rafraîchissement tient dans UNE MINUTE', () {
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
              onRetirer: null,
            ),
          ),
        ),
      );
      expect(find.text('6'), findsOneWidget);
      horloge.avancerDe(const Duration(hours: 2));
      // Une minute de temps écoulé — pas « la période », quelle qu'elle soit.
      await tester.pump(budgetRf05);
      expect(
        find.text('4'),
        findsOneWidget,
        reason:
            'le recalcul doit avoir eu lieu au plus tard après $budgetRf05, '
            'sans quoi une échéance en unité « heures » resterait fausse à '
            'l’écran pendant plus d’une minute',
      );
      expect(find.text('6'), findsNothing);
    });

    test('la période configurée NE DÉPASSE PAS ce budget', () {
      expect(
        ConcentrationTokens.periodeRafraichissement,
        lessThanOrEqualTo(budgetRf05),
        reason: 'RF-05 exige au minimum un recalcul par minute',
      );
      expect(
        ConcentrationTokens.periodeRafraichissement,
        greaterThan(Duration.zero),
        reason: 'une période nulle ferait tourner la reconstruction en boucle',
      );
    });
  });
  // ═══════════════════════════════════════════════════════════════════════
  // 🔴 T9 — L'ÉTAT DE RÉVÉLATION : UN minuteur, INDÉPENDANT, ⛔ AUCUN seam.
  //
  // ⛔ CE QUI A ÉTÉ RENVERSÉ PAR LA MESURE, et qu'il ne faut pas re-litiger :
  // §G-11 affirmait que le scénario d'AC-2 « Limite » est INOBSERVABLE sans
  // injecter la période. C'est FAUX (ADR-013 §4) : la technique est le
  // PHASAGE de l'appui — on se place JUSTE AVANT le tic, on appuie, puis on
  // franchit le tic SANS sortir de la fenêtre. ⇒ le test porte sur la
  // PÉRIODE RÉELLE DE PRODUCTION, et non sur une configuration qui n'existe
  // pas. ⛔ Un seam licite mais INUTILE reste un coût : une entrée publique
  // de plus, une valeur qui DUPLIQUE le token, et une porte qu'un test futur
  // peut régler pour contourner ce qu'il devait observer.
  //
  // ⛔ AUCUN NOMBRE DÉRIVÉ N'EST ÉCRIT À LA MAIN : les deux avances se
  // CALCULENT depuis les deux tokens, et la garde `fenetre < periode` est
  // ASSERTÉE — sans elle le phasage est impossible et le test deviendrait
  // VERT SANS RIEN OBSERVER.
  // ═══════════════════════════════════════════════════════════════════════
  group('T9 — la révélation (AC-2)', () {
    const periode = ConcentrationTokens.periodeRafraichissement;
    const fenetre = ConcentrationTokens.fenetreRevelation;
    const grain = Duration(milliseconds: 10);

    Widget grille(
      List<Echeance> echeances,
      Clock horloge, [
      RemainingTimeCalculator? calculateur,
    ]) => MaterialApp(
      theme: ConcentrationTheme.sombre,
      home: Scaffold(
        body: EcheancesGrid(
          echeances: echeances,
          clock: horloge,
          calculateur: calculateur ?? const RemainingTimeCalculator(),
          onRetirer: null,
        ),
      ),
    );

    Finder tuile(String id) => find.byKey(ValueKey(id));

    /// 🔴 **LE CRITÈRE DE RÉVÉLATION EST L'ABSENCE DU NOMBRE, ⛔ PAS LA
    /// PRÉSENCE DU TEXTE — et ce n'est pas un détail de style : deux de mes
    /// premières assertions étaient VIDES DE SENS pour cette raison exacte,
    /// et la mesure les a tuées.**
    ///
    /// Jusqu'à **T13**, la description est **aussi** rendue **au repos**, en
    /// bas de la tuile *(rendu d'US-01.1)* ⇒ `find.text(description)` rend
    /// **1** dans les DEUX états, donc *« la description est visible »* serait
    /// **vraie même si la révélation ne s'était jamais produite**.
    void verifier({
      required String nombre,
      required String description,
      required bool revelee,
      bool estEchue = false,
    }) {
      expect(
        find.text(nombre),
        revelee ? findsNothing : findsOneWidget,
        reason: revelee
            ? 'révélée : le nombre est ABSENT, la description a SA boîte'
            : 'au repos : le nombre est de retour',
      );
      // ⛔ **PÉRIMÉ-2026-08-29 (T13)** : cette assertion portait
      //   `expect(find.text(description), findsOneWidget);`
      // avec le commentaire *« Vraie dans les deux états AUJOURD'HUI »*.
      // **C'était vrai jusqu'au 2026-08-28, c'est FAUX depuis** : une `ACTIVE`
      // AU REPOS porte le **nombre SEUL** et ⛔ ne peint plus sa description
      // *(AC-1 « Erreur », et c'est ce qui referme le débordement mesuré par
      // T11 à ×1,6)*. ⛔ On date, on ne repeint pas.
      //
      // ✅ **L'attente devient DÉPENDANTE DE L'ÉTAT, et c'est un GAIN** :
      // l'ancienne forme était vraie partout, donc elle ⛔ **ne distinguait
      // rien** ; celle-ci rougit si la description apparaît là où elle ne doit
      // pas, **et** si elle disparaît là où elle doit être.
      expect(
        find.text(description),
        revelee || estEchue ? findsOneWidget : findsNothing,
        reason: revelee
            ? 'révélée : la description occupe la boîte du nombre'
            : estEchue
            ? 'une ÉCHUE peint sa description EN PERMANENCE'
            : 'au repos, une ACTIVE porte le nombre SEUL (T13)',
      );
    }

    test('🔴 GARDE DU PHASAGE — la fenêtre est STRICTEMENT plus courte que la '
        'période de rafraîchissement', () {
      // ⛔ Sans cette garde, un rafraîchissement ne pourrait JAMAIS tomber
      // pendant la fenêtre, et le scénario d'AC-2 « Limite » serait vert sans
      // exercer son cas. C'est le fait que §G-11 avait à l'envers.
      expect(fenetre, lessThan(periode));
      expect(fenetre, greaterThan(Duration.zero));
    });

    testWidgets(
      'AC-2 « Nominal » — un appui remplace le nombre par la description '
      'IMMÉDIATEMENT, et le nombre revient au bout de la fenêtre',
      (tester) async {
        final horloge = FakeClock(maintenant);
        await tester.pumpWidget(
          grille([e('a', const Duration(hours: 6), 'revue annuelle')], horloge),
        );
        expect(find.text('6'), findsOneWidget);

        await tester.tap(tuile('a'));
        await tester.pump();

        // ⛔ IMMÉDIATEMENT : aucune avance de temps entre l'appui et
        // l'observation — une animation de transition ou un
        // `kDoubleTapTimeout` ferait échouer ici (verdict clarify nº 1).
        verifier(nombre: '6', description: 'revue annuelle', revelee: true);

        // Le nombre revenu est celui du CALCUL COURANT, ⛔ pas celui de
        // l'instant de l'appui : l'horloge avance pendant la fenêtre.
        horloge.avancerDe(const Duration(hours: 2));
        await tester.pump(fenetre + grain);
        expect(find.text('4'), findsOneWidget);
        expect(
          find.text('6'),
          findsNothing,
          reason: 'un nombre MÉMORISÉ à l’appui réapparaîtrait à 6',
        );
      },
    );

    testWidgets(
      '🔴 verdict nº 7 — appuyer une SECONDE tuile referme la première : '
      'l’exclusivité est STRUCTURELLE',
      (tester) async {
        await tester.pumpWidget(
          grille([
            e('a', const Duration(hours: 6), 'revue annuelle'),
            e('b', const Duration(hours: 8), 'passeport'),
          ], FakeClock(maintenant)),
        );

        await tester.tap(tuile('a'));
        await tester.pump();
        verifier(nombre: '6', description: 'revue annuelle', revelee: true);
        verifier(nombre: '8', description: 'passeport', revelee: false);

        await tester.tap(tuile('b'));
        await tester.pump();
        // 🔴 M-9 — avec un `Timer` (et un état) PAR TUILE, les DEUX nombres
        // seraient absents en même temps : DEUX descriptions révélées.
        verifier(nombre: '6', description: 'revue annuelle', revelee: false);
        verifier(nombre: '8', description: 'passeport', revelee: true);

        await tester.pump(fenetre + grain);
      },
    );

    testWidgets(
      '🔴 un NOUVEL appui REDÉMARRE la fenêtre — le minuteur précédent est '
      'annulé, ⛔ jamais laissé courir',
      (tester) async {
        // ⛔ Le mutant que ce test tue : `_minuterieRevelation = Timer(…)`
        // SANS annuler le précédent. La seconde révélation se refermerait
        // alors à l'échéance de la PREMIÈRE — donc trop tôt, et pour une
        // raison invisible à tout autre test.
        await tester.pumpWidget(
          grille([
            e('a', const Duration(hours: 6), 'revue annuelle'),
            e('b', const Duration(hours: 8), 'passeport'),
          ], FakeClock(maintenant)),
        );

        await tester.tap(tuile('a'));
        await tester.pump();
        // On consomme la MOITIÉ de la fenêtre de « a »…
        await tester.pump(fenetre ~/ 2);
        await tester.tap(tuile('b'));
        await tester.pump();
        // …puis on franchit l'échéance de « a » SANS atteindre celle de « b ».
        await tester.pump(fenetre ~/ 2 + grain);
        // ⛔ « la fenêtre de b est repartie à ZÉRO » : le minuteur de « a »
        // ne doit pas la refermer.
        verifier(nombre: '8', description: 'passeport', revelee: true);

        await tester.pump(fenetre);
        verifier(nombre: '8', description: 'passeport', revelee: false);
      },
    );

    testWidgets(
      '🔴 AC-2 « Limite » PAR PHASAGE — un rafraîchissement tombe PENDANT la '
      'fenêtre : elle n’est ni COUPÉE ni PROLONGÉE (M-10)',
      (tester) async {
        final espion = _CalculateurEspion();
        final horloge = FakeClock(maintenant);
        await tester.pumpWidget(
          grille(
            [e('a', const Duration(hours: 6), 'revue annuelle')],
            horloge,
            espion,
          ),
        );

        // ① Se placer JUSTE AVANT le tic, et vérifier qu'AUCUN n'a eu lieu.
        final avantAppui = espion.appels;
        await tester.pump(periode - grain);
        expect(
          espion.appels,
          avantAppui,
          reason:
              'aucun tic ne doit avoir eu lieu : sans cette vérification, un '
              'test où le tic n’arrive JAMAIS serait vert et ne prouverait '
              'rien',
        );

        // ② Appuyer.
        await tester.tap(tuile('a'));
        await tester.pump();
        verifier(nombre: '6', description: 'revue annuelle', revelee: true);
        final apresAppui = espion.appels;

        // ③ Franchir le tic, SANS sortir de la fenêtre. Le tic est OBSERVÉ.
        horloge.avancerDe(const Duration(hours: 2));
        await tester.pump(grain * 2);
        expect(
          espion.appels,
          greaterThan(apresAppui),
          reason: 'le rafraîchissement a bien EU LIEU, il n’est pas supposé',
        );
        // 🔴 M-10 : le rafraîchissement ⛔ ne referme PAS la révélation, donc
        // le nombre — désormais 4 et non plus 6 — reste ABSENT. La fenêtre
        // n'est pas COUPÉE.
        verifier(nombre: '4', description: 'revue annuelle', revelee: true);

        // ④ …et elle n'est pas PROLONGÉE non plus : elle expire à son heure.
        await tester.pump(fenetre - grain * 4);
        verifier(nombre: '4', description: 'revue annuelle', revelee: true);
        await tester.pump(grain * 8);
        verifier(nombre: '4', description: 'revue annuelle', revelee: false);
      },
    );

    testWidgets(
      '⛔ une tuile ÉCHUE n’est PAS révélable — et à ce commit elle n’a AUCUNE '
      'intention (le retrait arrive avec T10/T19)',
      (tester) async {
        // Sa description est affichée EN PERMANENCE (verdict clarify nº 1) :
        // il n'y a rien à révéler, et un appui ne doit RIEN changer.
        await tester.pumpWidget(
          grille([
            e('a', const Duration(hours: -2), 'revue annuelle'),
          ], FakeClock(maintenant)),
        );
        expect(find.text('0'), findsOneWidget);
        expect(find.text('revue annuelle'), findsOneWidget);

        await tester.tap(tuile('a'));
        await tester.pump(kDoubleTapTimeout + grain);
        verifier(
          nombre: '0',
          description: 'revue annuelle',
          revelee: false,
          estEchue: true,
        );
      },
    );

    testWidgets(
      '🔴 `dispose` ANNULE le minuteur de révélation — un minuteur survivant '
      'ferait `setState` sur un `State` démonté',
      (tester) async {
        await tester.pumpWidget(
          grille([
            e('a', const Duration(hours: 6), 'revue annuelle'),
          ], FakeClock(maintenant)),
        );
        await tester.tap(tuile('a'));
        await tester.pump();
        verifier(nombre: '6', description: 'revue annuelle', revelee: true);

        // Démontage PENDANT la fenêtre.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(fenetre + grain);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Calculateur qui COMPTE ses appels — l'instrument qui rend le tic
/// **OBSERVABLE** sans introduire le moindre seam de durée.
///
/// ⚠️ Il compte des **constructions**, pas des tics : c'est pour cela que le
/// test lit une **variation** autour d'un point de référence pris juste avant
/// l'avance, et jamais une valeur absolue.
class _CalculateurEspion extends RemainingTimeCalculator {
  int appels = 0;

  @override
  RemainingTime calculer({required Clock clock, required Echeance echeance}) {
    appels++;
    return super.calculer(clock: clock, echeance: echeance);
  }
}
