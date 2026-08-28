import 'dart:async';

import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le retrait d'une échue : **l'écriture d'abord, l'animation ensuite** (T10 —
/// AC-8, AC-11 « Erreur »).
///
/// 🔴 **CE QUE CE FICHIER MESURE, ET CE QU'IL NE MESURE PAS.** Il asserte
/// **l'ORDRE** *(écriture ⇒ animation, jamais l'inverse)*, la **présence d'un
/// état intermédiaire**, et l'**indépendance de l'état écrit** vis-à-vis du
/// mode d'animation. ⛔ Il ne mesure **PAS la fluidité perçue** — **borne
/// NM-3**, héritée d'US-01.2 et non levée : elle exige un appareil, et aucune
/// assertion de `flutter_test` ne la remplace. **Le nombre de frames qu'un
/// téléphone produit réellement n'est pas observable ici.**
void main() {
  final maintenant = DateTime(2026, 8, 1, 12);
  const duree = ConcentrationTokens.dureeDisparition;
  const grain = Duration(milliseconds: 10);

  Echeance echue(String id, [String description = 'revue annuelle']) =>
      Echeance(
        id: id,
        description: description,
        dateEcheance: maintenant.subtract(const Duration(days: 2)),
      );

  Echeance activeDans(String id, Duration dans) => Echeance(
    id: id,
    description: 'passeport',
    dateEcheance: maintenant.add(dans),
  );

  Finder tuile(String id) => find.byKey(ValueKey(id));
  final enveloppe = find.byKey(EcheancesGrid.cleDisparition);

  /// Le **double appui**, tel que le corpus l'exerce déjà
  /// (`echeance_tile_test.dart`) — ⛔ jamais deux `tap()` nus : le premier
  /// appui doit être séparé du second d'au moins `kDoubleTapMinTime`.
  ///
  /// ⛔ **Aucun `pump` après le second appui** : c'est l'appelant qui décide,
  /// parce que l'instant *« juste après le geste, avant toute frame »* est
  /// précisément ce que le contrôle de **M-14** observe.
  Future<void> doubleAppui(WidgetTester tester, String id) async {
    final centre = tester.getRect(tuile(id)).center;
    await tester.tapAt(centre);
    await tester.pump(kDoubleTapMinTime + grain);
    await tester.tapAt(centre);
  }

  /// ⚠️ Le reconnaisseur de double appui laisse un minuteur de
  /// `kDoubleTapTimeout` en attente : sans cette avance, le démontage échoue
  /// sur `!timersPending`. ⛔ **Ce n'est pas un défaut du produit**, c'est la
  /// mécanique du reconnaisseur — le corpus le documente déjà (T8).
  Future<void> purgerLeReconnaisseur(WidgetTester tester) =>
      tester.pump(kDoubleTapTimeout + grain);

  double opacite(WidgetTester tester) =>
      tester.widget<FadeTransition>(enveloppe).opacity.value;

  double echelle(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(of: enveloppe, matching: find.byType(ScaleTransition)),
      )
      .scale
      .value;

  // ═══════════════════════════════════════════════════════════════════════
  // T10 — L'ANIMATION DE DISPARITION (AC-8)
  // ═══════════════════════════════════════════════════════════════════════
  group('T10 — l’animation de disparition (AC-8)', () {
    testWidgets(
      'AC-8 « Nominal » — l’écriture ABOUTIT, puis la tuile s’efface par un '
      'état INTERMÉDIAIRE, et elle quitte la grille à la fin',
      (tester) async {
        final ecriture = _Ecriture();
        await tester.pumpWidget(
          _hote(
            [echue('a'), activeDans('b', const Duration(hours: 6))],
            ecriture,
            maintenant,
          ),
        );
        expect(tuile('a'), findsOneWidget);

        await doubleAppui(tester, 'a');
        await tester.pump();

        expect(ecriture.appels, <String>['a'], reason: 'AC-4 : le geste écrit');
        expect(
          enveloppe,
          findsOneWidget,
          reason:
              'AC-8 : la disparition passe par une animation — ⛔ elle n’est '
              'jamais sèche quand les animations sont actives',
        );

        // 🔴 L'ÉTAT INTERMÉDIAIRE — assertions de GRANDEUR, ⛔ pas d'égalité au
        // token : ce sont elles qui tuent un mutant (acquis d'US-01.1).
        await tester.pump(duree ~/ 2);
        expect(
          opacite(tester),
          allOf(greaterThan(0.0), lessThan(1.0)),
          reason: 'à mi-course la tuile est PARTIELLEMENT effacée',
        );
        expect(
          echelle(tester),
          allOf(
            greaterThan(ConcentrationTokens.echelleDisparition),
            lessThan(1.0),
          ),
          reason: 'à mi-course la tuile est PARTIELLEMENT réduite',
        );
        expect(
          tuile('a'),
          findsOneWidget,
          reason: 'elle est encore rendue PENDANT l’animation (ADR-013 §1)',
        );

        await tester.pump(duree);
        expect(
          tuile('a'),
          findsNothing,
          reason: 'AC-4 : la tuile a quitté la grille',
        );
        expect(enveloppe, findsNothing);
        expect(
          tuile('b'),
          findsOneWidget,
          reason: 'AC-10 : les autres restent',
        );
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 M-14 — l’écriture est ÉMISE dans le tour du geste, ⛔ AVANT toute '
      'frame d’animation : l’animation n’est JAMAIS attendue (C-6)',
      (tester) async {
        final ecriture = _Ecriture();
        await tester.pumpWidget(_hote([echue('a')], ecriture, maintenant));

        await doubleAppui(tester, 'a');
        // ⛔ AUCUN `pump` : pas une seule frame n'a été produite depuis le
        // geste. Si l'écriture était `await`ée APRÈS l'animation (M-14), cette
        // liste serait VIDE.
        expect(
          ecriture.appels,
          <String>['a'],
          reason:
              'M-14 : « l’écriture est attendue après l’animation » ⇒ le '
              'retrait deviendrait tributaire du feedback',
        );

        await tester.pump();
        await tester.pump(duree + grain);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 M-14, LA FORME COÛTEUSE — la grille est DÉMONTÉE juste après le '
      'geste : le retrait est écrit quand même, ⛔ jamais perdu',
      (tester) async {
        final ecriture = _Ecriture();
        await tester.pumpWidget(_hote([echue('a')], ecriture, maintenant));

        await doubleAppui(tester, 'a');
        // Démontage IMMÉDIAT : le pratiquant quitte l'écran dans la seconde.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(duree * 4);

        expect(
          ecriture.appels,
          <String>['a'],
          reason:
              'un retrait suspendu à un `TickerFuture` que le démontage annule '
              'ne serait JAMAIS écrit — c’est le « retrait perdu » de M-14',
        );
        expect(tester.takeException(), isNull);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 AC-8 « Erreur » — « animations réduites » : DÉPART IMMÉDIAT, ⛔ '
      'aucune enveloppe montée, à aucun instant',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final ecriture = _Ecriture();
        await tester.pumpWidget(
          _hote(
            [echue('a'), activeDans('b', const Duration(hours: 6))],
            ecriture,
            maintenant,
          ),
        );

        await doubleAppui(tester, 'a');
        await tester.pump();

        expect(
          enveloppe,
          findsNothing,
          reason: 'départ immédiat : ⛔ AUCUN état intermédiaire n’est monté',
        );
        expect(
          tuile('a'),
          findsNothing,
          reason: 'la tuile est PARTIE sans attendre une seule frame',
        );
        expect(tuile('b'), findsOneWidget);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 AC-8 « Erreur » — L’ÉTAT ÉCRIT EST EXACTEMENT LE MÊME dans les DEUX '
      'modes (avec son contrôle négatif : deux listes vides seraient égales)',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        Future<List<String>> jouer({required bool reduites}) async {
          if (reduites) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
          } else {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
          final ecriture = _Ecriture();
          await tester.pumpWidget(
            // ⛔ Une CLÉ, et ce n'est pas un détail : sans elle le second
            // montage RÉUTILISE le `State` du premier (même type, même
            // position), donc sa liste — déjà amputée de « a ». Le test
            // échouait sur « 0 widget de clé a », ⛔ pas sur le produit.
            _hote(
              [echue('a'), echue('b', 'passeport')],
              ecriture,
              maintenant,
              cle: ValueKey('mode-$reduites'),
            ),
          );
          await doubleAppui(tester, 'a');
          await tester.pump();
          await tester.pump(duree + grain);
          await purgerLeReconnaisseur(tester);
          return ecriture.appels;
        }

        final avecAnimation = await jouer(reduites: false);
        final sansAnimation = await jouer(reduites: true);

        expect(avecAnimation, isNotEmpty, reason: '⛔ contrôle négatif');
        expect(
          sansAnimation,
          avecAnimation,
          reason:
              'AC-8 : « l’état écrit est exactement le même » — l’animation '
              'est le FEEDBACK, ⛔ jamais la CONDITION du résultat',
        );
      },
    );

    testWidgets(
      '🔴 AC-11 « Erreur » — l’écriture ÉCHOUE : ⛔ AUCUNE animation, et la '
      'tuile RESTE',
      (tester) async {
        final ecriture = _Ecriture(
          refus: const RefusValidation(ChampEcheance.action, 'échec simulé'),
        );
        await tester.pumpWidget(_hote([echue('a')], ecriture, maintenant));

        await doubleAppui(tester, 'a');
        await tester.pump();
        expect(ecriture.appels, <String>['a']);
        expect(
          enveloppe,
          findsNothing,
          reason:
              'AC-11 : une animation ferait PARAÎTRE le geste abouti alors que '
              'rien n’a été écrit',
        );

        // …et elle ne se joue pas non plus « un peu plus tard ».
        await tester.pump(duree * 4);
        expect(enveloppe, findsNothing);
        expect(
          tuile('a'),
          findsOneWidget,
          reason: 'AC-11 : la tuile RESTE — ⛔ jamais de retrait optimiste',
        );
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 L’ORDRE EST LA CLAUSE — PENDANT l’écriture, ⛔ aucune enveloppe : '
      'elle n’apparaît qu’une fois l’issue CONNUE',
      (tester) async {
        final ecriture = _Ecriture(differee: true);
        await tester.pumpWidget(_hote([echue('a')], ecriture, maintenant));

        await doubleAppui(tester, 'a');
        await tester.pump();
        expect(ecriture.appels, <String>['a'], reason: 'l’écriture est LANCÉE');
        expect(
          enveloppe,
          findsNothing,
          reason:
              'l’issue n’est pas connue : animer ici, c’est animer AVANT de '
              'savoir — la faute exacte qu’AC-11 interdit',
        );
        await tester.pump(duree * 2);
        expect(enveloppe, findsNothing);

        // L'écriture aboutit ENFIN.
        // ⚠️ DEUX `pump`, et le motif est MESURÉ dans le binding : `pump()`
        // exécute la frame AVANT de vider les micro-tâches (`binding.dart`
        // — `handleDrawFrame()` puis `flushMicrotasks()`). La reprise de
        // l'écriture a donc lieu APRÈS la frame ; c'est le second `pump` qui
        // la rend. ⛔ Ce n'est pas une tolérance accordée au produit : la
        // frame suivante DOIT porter l'enveloppe.
        ecriture.terminer();
        await tester.pump();
        await tester.pump();
        expect(enveloppe, findsOneWidget);
        await tester.pump(duree + grain);
        expect(tuile('a'), findsNothing);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 AC-8 « Limite » — un second double appui PENDANT l’animation : '
      'REÇU, ⛔ sans effet, ⛔ ne retire rien d’autre, ⛔ ne lève rien',
      (tester) async {
        final ecriture = _Ecriture();
        await tester.pumpWidget(
          _hote([echue('a'), echue('b', 'passeport')], ecriture, maintenant),
        );

        await doubleAppui(tester, 'a');
        await tester.pump();
        expect(enveloppe, findsOneWidget);

        // …au beau milieu de l'animation, l'AUTRE tuile est double-appuyée.
        await tester.pump(duree ~/ 3);
        await doubleAppui(tester, 'b');
        await tester.pump();

        expect(
          ecriture.appels,
          <String>['a'],
          reason:
              'AC-8 « Limite » : ⛔ le second geste ne retire RIEN D’AUTRE — un '
              'champ nullable unique ne peut pas porter deux retraits',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'AC-8 « Limite » : ⛔ il ne produit AUCUNE erreur',
        );

        await tester.pump(duree + grain);
        expect(tuile('a'), findsNothing);
        expect(
          tuile('b'),
          findsOneWidget,
          reason: 'la seconde tuile est TOUJOURS là : le geste fut sans effet',
        );
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '⛔ un second double appui PENDANT L’ÉCRITURE : même clause, même garde '
      '— deux écritures concurrentes se disputeraient le même document',
      (tester) async {
        final ecriture = _Ecriture(differee: true);
        await tester.pumpWidget(
          _hote([echue('a'), echue('b', 'passeport')], ecriture, maintenant),
        );

        await doubleAppui(tester, 'a');
        await tester.pump();
        await doubleAppui(tester, 'b');
        await tester.pump();

        expect(ecriture.appels, <String>['a']);
        expect(tester.takeException(), isNull);

        ecriture.terminer();
        await tester.pump();
        await tester.pump(duree + grain);
        expect(tuile('b'), findsOneWidget);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 L’ENVELOPPE SE MONTE PAR ELLE-MÊME — ⛔ ni la frame lancée AVANT '
      'l’écriture, ni le rechargement du parent ne la portent',
      (tester) async {
        // ⚖️ **INSTRUMENT DE FALSIFICATION, et son objet est nommé.** Il retire
        // les DEUX sources accidentelles de reconstruction :
        //   ① l'écriture est **différée**, donc la frame planifiée par le
        //      `setState` d'entrée est **consommée avant** que l'issue soit
        //      connue — c'est le cas RÉEL d'une écriture disque plus lente
        //      qu'une frame, c'est-à-dire le cas NORMAL sur un appareil ;
        //   ② le parent ⛔ **ne recharge pas**, donc aucune notification
        //      n'arrive de l'extérieur.
        // ⇒ Si la grille n'appelle pas `setState` au DÉMARRAGE de l'animation,
        // l'enveloppe n'est jamais montée : la tuile disparaît **sèchement** et
        // ⛔ **aucun autre test ne le voit**.
        final ecriture = _Ecriture(differee: true);
        await tester.pumpWidget(
          _hote([echue('a')], ecriture, maintenant, recharge: false),
        );

        await doubleAppui(tester, 'a');
        await tester.pump();
        // La frame d'entrée est passée, et l'issue n'est toujours pas connue.
        expect(enveloppe, findsNothing);

        ecriture.terminer();
        await tester.pump();
        await tester.pump();
        expect(
          enveloppe,
          findsOneWidget,
          reason:
              'la grille se reconstruit ELLE-MÊME au démarrage de l’animation',
        );
        await tester.pump(duree + grain);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '🔴 ⛔ AUCUNE FUITE — le contrôleur d’animation ET le minuteur de '
      'révélation sont libérés au démontage',
      (tester) async {
        final ecriture = _Ecriture();
        await tester.pumpWidget(
          _hote(
            [echue('a'), activeDans('b', const Duration(hours: 6))],
            ecriture,
            maintenant,
          ),
        );

        // Une révélation EN COURS (minuteur de T9) …
        await tester.tap(tuile('b'));
        await tester.pump();
        // … et une animation EN COURS (contrôleur de T10).
        await doubleAppui(tester, 'a');
        await tester.pump();
        await tester.pump(duree ~/ 3);
        expect(enveloppe, findsOneWidget);
        expect(
          tester.binding.transientCallbackCount,
          greaterThan(0),
          reason:
              '⛔ contrôle négatif : sans un ticker RÉELLEMENT actif, '
              'l’assertion suivante serait vraie sans rien prouver',
        );

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason:
              '`dispose` libère le contrôleur : un ticker survivant ferait '
              'battre une animation sur un `State` démonté',
        );
        await tester.pump(ConcentrationTokens.fenetreRevelation * 2);
        expect(tester.takeException(), isNull);
        await purgerLeReconnaisseur(tester);
      },
    );

    testWidgets(
      '⛔ LA RECOMPOSITION DE LA GRILLE N’EST JAMAIS ANIMÉE — à la frame qui '
      'suit la fin, les tuiles restantes sont DÉJÀ à leur place finale',
      (tester) async {
        final liste = [
          echue('a'),
          activeDans('b', const Duration(hours: 6)),
          activeDans('c', const Duration(hours: 8)),
          activeDans('d', const Duration(hours: 10)),
          activeDans('e', const Duration(hours: 12)),
        ];
        await tester.pumpWidget(_hote(liste, _Ecriture(), maintenant));
        // 5 tuiles ⇒ 3 colonnes, 4 tuiles ⇒ 2 : la recomposition est MAXIMALE,
        // donc une animation de recomposition serait maximalement visible.
        await doubleAppui(tester, 'a');
        await tester.pump();
        await tester.pump(duree + grain);
        final apresRetrait = tester.getTopLeft(tuile('e'));

        // Référence : la MÊME grille, construite d'emblée sans « a ».
        await tester.pumpWidget(
          _hote(liste.sublist(1), _Ecriture(), maintenant),
        );
        expect(
          apresRetrait,
          tester.getTopLeft(tuile('e')),
          reason:
              'Design UX §7.3 : ⛔ aucune animation de la recomposition — la '
              'grille est à sa géométrie finale dès la frame suivante',
        );
        await purgerLeReconnaisseur(tester);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // LES VALEURS DU DESIGN — bornes et PROPRIÉTÉS, ⛔ jamais des égalités au
  // token (tautologiques : les deux côtés bougent ensemble).
  // ═══════════════════════════════════════════════════════════════════════
  group('T10 — les valeurs de l’animation (Design UX §7.3)', () {
    test('la durée est PERCEPTIBLE et BRÈVE — les deux bornes du design', () {
      // ⛔ Ce ne sont pas des valeurs dérivées recopiées : ce sont les DEUX
      // BORNES que le Design UX §7.3 énonce comme MOTIF — « en dessous
      // d'≈120 ms l'œil enregistre une disparition sèche », « au-delà d'≈300 ms
      // elle frictionne le geste le plus fréquent ». ⛔ La valeur, elle, n'est
      // écrite nulle part ici.
      expect(duree, greaterThanOrEqualTo(const Duration(milliseconds: 120)));
      expect(duree, lessThanOrEqualTo(const Duration(milliseconds: 300)));
    });

    test('l’échelle RÉDUIT, et de peu — ⛔ jamais un effondrement', () {
      expect(ConcentrationTokens.echelleDisparition, lessThan(1.0));
      expect(ConcentrationTokens.echelleDisparition, greaterThan(0.8));
    });

    test('🔴 la courbe est ACCÉLÉRÉE, MONOTONE et SANS DÉPASSEMENT — ⛔ ni '
        '`easeOut`, ni `elastic*`, ni `bounce*`', () {
      const courbe = ConcentrationTheme.courbeDisparition;

      // ① ACCÉLÉRÉE : à mi-parcours, moins de la moitié du chemin est faite.
      // ⛔ `Curves.easeOut` rend ≈0,68 ici et ferait S'ATTARDER la tuile.
      expect(
        courbe.transform(0.5),
        lessThan(0.5),
        reason: 'une sortie PART ; une courbe décélérée fait s’attarder',
      );

      // ② MONOTONE et ③ SANS DÉPASSEMENT, sur 101 points — c'est ce qui tue
      // `elasticIn` (valeurs hors [0, 1]) et `bounceIn` (non monotone).
      var precedent = courbe.transform(0);
      for (var i = 0; i <= 100; i++) {
        final v = courbe.transform(i / 100);
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThanOrEqualTo(1.0));
        expect(
          v,
          greaterThanOrEqualTo(precedent - 1e-9),
          reason: 'aucun rebond, aucun retour en arrière (RNF-03)',
        );
        precedent = v;
      }
    });

    testWidgets(
      '🔴 LE RENDU SUIT LA COURBE ET LES TOKENS — opacité 1 → 0, échelle '
      '1 → échelleDisparition, ⛔ jamais l’inverse',
      (tester) async {
        await tester.pumpWidget(_hote([echue('a')], _Ecriture(), maintenant));
        await doubleAppui(tester, 'a');
        await tester.pump();

        const fraction = 0.25;
        await tester.pump(duree * fraction);
        final t = ConcentrationTheme.courbeDisparition.transform(fraction);

        expect(
          opacite(tester),
          closeTo(1 - t, 1e-6),
          reason: 'l’opacité DESCEND de 1 vers 0 le long de la courbe',
        );
        expect(
          echelle(tester),
          closeTo(1 + (ConcentrationTokens.echelleDisparition - 1) * t, 1e-6),
          reason: 'l’échelle DESCEND de 1 vers le token, le long de la courbe',
        );
        await tester.pump(duree + grain);
        await purgerLeReconnaisseur(tester);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // L'ENVELOPPE INTERACTIVE RESTE CONDITIONNELLE (ADR-014 §A.1) — vue depuis
  // la GRILLE, qui est ce qui décide s'il y a une intention.
  // ═══════════════════════════════════════════════════════════════════════
  group('T10 — l’intention de l’échue vient du RAPPEL', () {
    // ⛔ Les drapeaux et les hints se lisent sur l'UNION des nœuds, ⛔ jamais
    // sur « le nœud du label » : le piège est mesuré par le corpus (T8) —
    // certains drapeaux vivent sur un ANCÊTRE, donc une assertion écrite sur
    // un seul nœud serait VERTE À TORT.
    int boutonsDeLArbre() =>
        find.semantics.byFlag(SemanticsFlag.isButton).evaluate().length;

    Set<String> hintsDeLArbre() => {
      for (final n in find.semantics.byPredicate((_) => true).evaluate())
        if (n.hint.isNotEmpty) n.hint,
    };

    testWidgets(
      'AVEC un rappel : l’échue est annoncée ACTIONNABLE et porte le hint du '
      'retrait',
      (tester) async {
        final poignee = tester.ensureSemantics();
        await tester.pumpWidget(_hote([echue('a')], _Ecriture(), maintenant));
        expect(boutonsDeLArbre(), 1);
        expect(hintsDeLArbre(), {EcheanceTile.hintRetrait});
        poignee.dispose();
      },
    );

    testWidgets(
      '⛔ SANS rappel : ⛔ aucune enveloppe, aucun hint — une surface annoncée '
      'sans effet est le mensonge d’interface d’AC-9 « Erreur »',
      (tester) async {
        final poignee = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: ConcentrationTheme.sombre,
            home: Scaffold(
              body: EcheancesGrid(
                echeances: [echue('a')],
                clock: FakeClock(maintenant),
                onRetirer: null,
              ),
            ),
          ),
        );
        expect(boutonsDeLArbre(), 0);
        expect(hintsDeLArbre(), isEmpty);
        // ✅ CONTRÔLE : le label est PRÉSENT — « aucune enveloppe » ⛔ ne veut
        // pas dire « aucune sémantique », ce serait un défaut PIRE.
        expect(
          find.bySemanticsLabel('échéance atteinte, revue annuelle'),
          findsOneWidget,
        );
        poignee.dispose();
      },
    );
  });
}

/// L'écriture de retrait, **CONTRÔLÉE par le test** : elle enregistre ses
/// appels, décide de l'issue, et peut être **différée** pour rendre observable
/// l'instant *« l'écriture est lancée, son issue n'est pas connue »*.
class _Ecriture {
  _Ecriture({this.refus, this.differee = false});

  /// `null` ⇒ **succès** — la convention du port, ⛔ pas une invention du test.
  final RefusValidation? refus;
  final bool differee;

  final List<String> appels = <String>[];
  Completer<RefusValidation?>? _attente;

  Future<RefusValidation?> appeler(String id) {
    appels.add(id);
    if (!differee) return Future<RefusValidation?>.value(refus);
    final attente = Completer<RefusValidation?>();
    _attente = attente;
    return attente.future;
  }

  void terminer() => _attente!.complete(refus);
}

/// Le hôte : **miroir exact d'`EcheancesNotifier`** — il **recharge après
/// succès**, ⛔ jamais avant, et ⛔ jamais de mise à jour optimiste.
///
/// ⚖️ **`recharge: false` est un INSTRUMENT, pas un régime de production** :
/// il isole ce qui monte l'enveloppe d'animation *(test d'indépendance)*.
Widget _hote(
  List<Echeance> echeances,
  _Ecriture ecriture,
  DateTime maintenant, {
  bool recharge = true,
  Key? cle,
}) => _Hote(
  key: cle,
  echeances: echeances,
  ecriture: ecriture,
  maintenant: maintenant,
  recharge: recharge,
);

class _Hote extends StatefulWidget {
  const _Hote({
    required this.echeances,
    required this.ecriture,
    required this.maintenant,
    required this.recharge,
    super.key,
  });

  final List<Echeance> echeances;
  final _Ecriture ecriture;
  final DateTime maintenant;
  final bool recharge;

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  late List<Echeance> _liste = List<Echeance>.of(widget.echeances);

  Future<RefusValidation?> _retirer(String id) async {
    final refus = await widget.ecriture.appeler(id);
    if (refus == null && widget.recharge) {
      // ⛔ On RECHARGE, on ne mute pas en place — et seulement après SUCCÈS.
      setState(() {
        _liste = _liste.where((e) => e.id != id).toList(growable: false);
      });
    }
    return refus;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ConcentrationTheme.sombre,
    home: Scaffold(
      body: EcheancesGrid(
        echeances: _liste,
        clock: FakeClock(widget.maintenant),
        onRetirer: _retirer,
      ),
    ),
  );
}
