import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/rendu_couleur.dart';

/// **T11 — ACCESSIBILITÉ MESURÉE : clavier, anneau BICOLORE, cible tactile**
/// *(AC-9, AC-1 « Limite », `P-7`, Design UX §6)*.
///
/// ⛔ **À MESURER, JAMAIS À AFFIRMER.** US-01.2 a dû **déclarer une exception**
/// à 40 × 48 dp après un débordement **réel de 63 px** que 90 tests n'avaient pas
/// vu — parce qu'ils tournaient **tous** au gabarit par défaut de `flutter_test`.
///
/// ⛔ **L'échelle de texte se règle par `platformDispatcher`, JAMAIS par un
/// `MediaQuery` enveloppant la racine** *(§G-5)* : un `MediaQuery` posé au-dessus
/// de `MaterialApp` est **écrasé** par celui que `MaterialApp` construit — le
/// test passerait en n'ayant **rien mis à l'échelle**.
void main() {
  final maintenant = DateTime(2026, 8, 28, 12);

  Echeance echeance(String id, Duration dans) => Echeance(
    id: id,
    description: 'Rendez-vous $id',
    dateEcheance: maintenant.add(dans),
  );

  /// `n` échéances **actives**, toutes distinctes dans le temps.
  List<Echeance> jeu(int n) => [
    for (var i = 0; i < n; i++) echeance('t$i', Duration(days: 3 + i * 7)),
  ];

  Widget hote(
    List<Echeance> echeances, {
    double largeur = 320,
    double? hauteur,
  }) => MaterialApp(
    theme: ConcentrationTheme.sombre,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: largeur,
          height: hauteur ?? largeur,
          child: EcheancesGrid(
            echeances: echeances,
            clock: FakeClock(maintenant),
            onRetirer: null,
          ),
        ),
      ),
    ),
  );

  Finder tuile(String id) => find.byKey(ValueKey(id));
  Finder anneauExterieur(String id) => find.descendant(
    of: tuile(id),
    matching: find.byKey(EcheanceTile.cleAnneauExterieur),
  );
  Finder anneauInterieur(String id) => find.descendant(
    of: tuile(id),
    matching: find.byKey(EcheanceTile.cleAnneauInterieur),
  );

  Color couleurDuLisere(WidgetTester tester, Finder lisere) {
    final deco =
        tester.widget<DecoratedBox>(lisere).decoration as BoxDecoration;
    return deco.border!.top.color;
  }

  double largeurDuLisere(WidgetTester tester, Finder lisere) {
    final deco =
        tester.widget<DecoratedBox>(lisere).decoration as BoxDecoration;
    return deco.border!.top.width;
  }

  double rayonDuLisere(WidgetTester tester, Finder lisere) {
    final deco =
        tester.widget<DecoratedBox>(lisere).decoration as BoxDecoration;
    return (deco.borderRadius! as BorderRadius).topLeft.x;
  }

  /// La traversée clavier — c'est **elle** qui allume la mise en évidence, et
  /// ⛔ **pas un appui**.
  Future<void> tabuler(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }

  group('T11 — l’anneau de focus BICOLORE', () {
    testWidgets(
      '🔴 L’ANNEAU N’APPARAÎT QU’À LA TRAVERSÉE CLAVIER — ⛔ jamais au contact '
      'd’un doigt (AC-10 « Erreur » : tout retour d’appui est NEUTRE)',
      (tester) async {
        await tester.pumpWidget(hote(jeu(2)));

        // ⛔ CONTRÔLE POSITIF PRÉALABLE : au repos, aucun anneau nulle part.
        expect(anneauExterieur('t0'), findsNothing);
        expect(anneauInterieur('t0'), findsNothing);

        // 🔴 UN APPUI N’ALLUME RIEN. `onFocusChange` aurait suffi à faire
        // rougir ce test — c'est précisément pourquoi le produit écoute
        // `onShowFocusHighlight`.
        await tester.tap(tuile('t0'));
        await tester.pumpAndSettle();
        expect(
          anneauExterieur('t0'),
          findsNothing,
          reason:
              'un liseré `moduleActif` allumé sous le doigt serait un '
              'retour d’appui COLORÉ, sur la surface où la couleur n’encode que '
              'la proximité temporelle',
        );

        // ✅ LA TRAVERSÉE CLAVIER, elle, l’allume.
        await tabuler(tester);
        expect(anneauExterieur('t0'), findsOneWidget);
        expect(anneauInterieur('t0'), findsOneWidget);
      },
    );

    testWidgets(
      '🔴 LE TEST QUI TUE VRAIMENT LE MUTANT — focus PRIS en mode TACTILE : ⛔ '
      'aucun anneau, alors que le nœud A le focus',
      (tester) async {
        // ⚠️ **CE TEST EXISTE PARCE QUE LE MUTANT `M-p` A SURVÉCU.** Remplacer
        // `onShowFocusHighlight` par `onFocusChange` laissait **les 11 tests
        // VERTS** : dans un test widget, `tap()` ⛔ **ne donne pas le focus**,
        // donc l’assertion « jamais au contact d’un doigt » ⛔ **ne pouvait pas
        // voir le défaut** — une clause sans prise sur la surface.
        //
        // ✅ **Ce qui discrimine, mesuré** : en mode `alwaysTouch`, le nœud
        // **PREND** le focus mais le framework ⛔ **ne le MET PAS en
        // évidence**. C’est exactement la distinction entre les deux rappels.
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTouch;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.pumpWidget(hote(jeu(2)));

        // Le focus est RÉELLEMENT pris — contrôle positif, sans lequel
        // l’absence d’anneau ne prouverait rien.
        // ⛔ **`Focus.of` cherche un ANCÊTRE** : appelé depuis le détecteur
        // lui-même, il lève *« no Focus widget ancestor »* — le `Focus` que
        // `FocusableActionDetector` construit est son DESCENDANT. On part donc
        // d'un élément situé SOUS lui.
        final noeud = Focus.of(
          tester.element(
            find.descendant(
              of: tuile('t0'),
              matching: find.byKey(EcheanceTile.cleFond),
            ),
          ),
        );
        noeud.requestFocus();
        await tester.pumpAndSettle();
        expect(noeud.hasFocus, isTrue, reason: 'le nœud a bien le focus…');

        // ⛔ …et pourtant AUCUN anneau : c’est la clause du design.
        expect(
          anneauExterieur('t0'),
          findsNothing,
          reason:
              '`onFocusChange` s’allumerait ICI — et l’accent orange du '
              'produit deviendrait un retour d’appui coloré (AC-10 « Erreur »)',
        );

        // ✅ CONTRÔLE APPARIÉ : en mode traditionnel, le MÊME focus l’allume.
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        noeud.unfocus();
        await tester.pumpAndSettle();
        noeud.requestFocus();
        await tester.pumpAndSettle();
        expect(anneauExterieur('t0'), findsOneWidget);
      },
    );

    testWidgets(
      '🔴 GÉOMÉTRIE MESURÉE — extérieur HORS de la tuile, intérieur SUR la '
      'tuile, contigus, et les rayons suivent la FORMULE',
      (tester) async {
        await tester.pumpWidget(hote(jeu(2)));
        final rectTuile = tester.getRect(tuile('t0'));
        await tabuler(tester);

        const e = ConcentrationTokens.epaisseurAnneauFocus;

        // Le liseré EXTÉRIEUR déborde de `e` sur les QUATRE côtés.
        expect(tester.getRect(anneauExterieur('t0')), rectTuile.inflate(e));
        // Le liseré INTÉRIEUR est PEINT SUR la tuile : même rect, ⛔ aucun
        // écart — un écart laisserait voir la peinture du PARENT, et le
        // contraste deviendrait une propriété du parent au lieu d’une décision.
        expect(tester.getRect(anneauInterieur('t0')), rectTuile);

        // ⛔ Les rayons ne sont pas des nombres, ce sont des formules.
        expect(
          rayonDuLisere(tester, anneauExterieur('t0')),
          ConcentrationTokens.rayonSurface + e,
        );
        expect(
          rayonDuLisere(tester, anneauInterieur('t0')),
          ConcentrationTokens.rayonSurface,
        );

        // ═══════════════════════════════════════════════════════════════════
        // 🔴 **ASSERTIONS DE GRANDEUR — ET ELLES EXISTENT PARCE QU'UN MUTANT A
        // SURVÉCU.** Ramener `epaisseurAnneauFocus` de 2 dp à **1 dp** laissait
        // **les 12 tests VERTS**.
        //
        // **Cause, et c'est l'acquis d'US-01.1 appliqué à mes propres
        // assertions** : tout ce qui précède est une **égalité AU TOKEN**, donc
        // **TAUTOLOGIQUE** — `rectTuile.inflate(e)` avec `e` = le token bouge
        // *avec* le mutant. ⇒ **seules les assertions de GRANDEUR tuent un
        // mutant**, et ce sont justement celles qui ont l'air de faire doublon.
        //
        // ⛔ **2 dp n'est PAS un choix du projet, c'est le minimum de
        // SC 2.4.11** — une NORME, donc une borne légitime à écrire ici.
        // ═══════════════════════════════════════════════════════════════════
        const minimumSc2411 = 2.0;
        expect(
          largeurDuLisere(tester, anneauExterieur('t0')),
          greaterThanOrEqualTo(minimumSc2411),
        );
        expect(
          largeurDuLisere(tester, anneauInterieur('t0')),
          greaterThanOrEqualTo(minimumSc2411),
        );
        // La largeur TOTALE de l'indicateur vaut le DOUBLE du minimum — et
        // c'est nécessaire : il faut DEUX bandes pour tenir les deux côtés du
        // contraste.
        expect(
          largeurDuLisere(tester, anneauExterieur('t0')) +
              largeurDuLisere(tester, anneauInterieur('t0')),
          greaterThanOrEqualTo(2 * minimumSc2411),
        );
        // ⛔ Et l'empreinte HORS de la tuile reste sous l'espacement de 12 dp
        // (⇒ aucun chevauchement avec la voisine) : une borne SUPÉRIEURE, que
        // les égalités au token ne donnent pas non plus.
        expect(
          tester.getRect(anneauExterieur('t0')).width -
              tester.getRect(tuile('t0')).width,
          lessThan(12),
        );
      },
    );

    testWidgets(
      '🔴 LES DEUX COULEURS, avec leur CONTRÔLE NÉGATIF — une seule couleur ne '
      'tiendrait pas les deux côtés (mesuré : 101/101 points sous 3:1)',
      (tester) async {
        await tester.pumpWidget(hote(jeu(2)));
        await tabuler(tester);

        expect(
          couleurDuLisere(tester, anneauExterieur('t0')),
          ConcentrationTokens.moduleActif.couleur,
        );
        expect(
          couleurDuLisere(tester, anneauInterieur('t0')),
          ConcentrationTokens.fondApp.couleur,
        );
        // ⛔ Sans ce contrôle, les deux assertions ci-dessus resteraient vraies
        // le jour où les deux tokens rendraient la MÊME couleur — et l’anneau
        // serait alors monochrome sans que rien ne le dise.
        expect(
          couleurDuLisere(tester, anneauExterieur('t0')),
          isNot(couleurDuLisere(tester, anneauInterieur('t0'))),
        );
      },
    );

    testWidgets(
      '🔴 RIEN NE ROGNE L’ANNEAU DES TUILES DE BORD — assertion sur l’objet '
      'qui rogne VRAIMENT, ⛔ pas sur un finder',
      (tester) async {
        // ⚠️ **CE TEST EXISTE PARCE QUE LE MUTANT `M-v` A SURVÉCU** : remettre
        // `clipBehavior: Clip.hardEdge` sur la grille laissait **les 12 tests
        // VERTS**. Un `GridView` est une vue défilante et rogne **au bord du
        // viewport** ; une tuile de bord est **à fleur** ⇒ son liseré extérieur
        // *(peint HORS de la tuile)* tombait, sur les quatre côtés.
        //
        // 🔴 **MÊME LEÇON QUE PARTOUT AUJOURD’HUI : le rognage est une
        // propriété de la PEINTURE**, et ⛔ **aucun finder, aucun rect ne le
        // voit** — le liseré reste dans l’arbre et garde son rect, il n’est
        // simplement **pas peint**. L’assertion porte donc sur le RENDER OBJECT
        // qui rogne.
        //
        // ⚠️ **BORNE, et il faut la dire** : ceci atteste que **rien n’est
        // configuré pour rogner**, ⛔ **pas** que les pixels du liseré sont
        // là — la peinture n’est pas observable ici *(il faudrait un golden,
        // que ce projet n’utilise pas)*.
        await tester.pumpWidget(hote(jeu(9)));
        await tabuler(tester);

        expect(
          tester
              .renderObject<RenderViewport>(find.byType(Viewport))
              .clipBehavior,
          Clip.none,
          reason:
              'avec `Clip.hardEdge`, le liseré des tuiles de bord serait '
              'ROGNÉ — et ⛔ aucune autre assertion de ce fichier ne le verrait',
        );

        // ✅ Et le débordement RESTE sans risque : `Padding(all: 12)` laisse
        // 12 dp autour du viewport contre 2 dp d’empreinte.
        final rectAnneau = tester.getRect(anneauExterieur('t0'));
        final rectViewport = tester.getRect(find.byType(Viewport));
        expect(
          rectViewport.inflate(12).contains(rectAnneau.topLeft),
          isTrue,
          reason: 'l’anneau reste DANS la zone réservée par le padding',
        );
      },
    );

    testWidgets(
      '🔴 SÛRETÉ — L’ANNEAU NE PREND AUCUNE PLACE : la tuile a le MÊME RECT '
      'avec et sans focus (⛔ zéro reflux, même clause qu’à T19)',
      (tester) async {
        await tester.pumpWidget(hote(jeu(9)));
        final avant = [
          for (var i = 0; i < 9; i++) tester.getRect(tuile('t$i')),
        ];

        await tabuler(tester);
        expect(anneauExterieur('t0'), findsOneWidget); // le focus est bien pris

        final apres = [
          for (var i = 0; i < 9; i++) tester.getRect(tuile('t$i')),
        ];
        expect(
          apres,
          avant,
          reason:
              'un anneau qui occuperait de la place ferait REFLUER la '
              'grille à chaque déplacement du focus — donc déplacerait les '
              'tuiles sous le doigt',
        );
      },
    );

    testWidgets('⛔ LE FOCUS NE CHANGE RIEN D’AUTRE (§6.2 règle 3)', (
      tester,
    ) async {
      await tester.pumpWidget(hote(jeu(2)));
      final fondAvant = fondDeLaTuile(tester, tuile: tuile('t0'));
      final nombreAvant = tester
          .widget<Text>(
            find.descendant(of: tuile('t0'), matching: find.byType(Text)).first,
          )
          .data;

      await tabuler(tester);

      expect(
        fondDeLaTuile(tester, tuile: tuile('t0')),
        fondAvant,
        reason: 'ni la couleur de fond…',
      );
      expect(
        tester
            .widget<Text>(
              find
                  .descendant(of: tuile('t0'), matching: find.byType(Text))
                  .first,
            )
            .data,
        nombreAvant,
        reason: '…ni le contenu',
      );
      // 🔴 **MON ASSERTION ÉTAIT FAUSSE ICI, et le produit avait raison** :
      // j'avais écrit « la description n'apparaît pas ». Or **jusqu'à T13 la
      // description est AUSSI rendue au repos** sur une tuile `ACTIVE` — le
      // corpus le sait depuis T9. ⇒ le critère de « rien n'est révélé » est la
      // **présence du NOMBRE**, ⛔ jamais l'absence de la description.
      expect(
        find.descendant(of: tuile('t0'), matching: find.text(nombreAvant!)),
        findsOneWidget,
        reason: 'le nombre est toujours là ⇒ aucune révélation n’a eu lieu',
      );
    });

    testWidgets(
      '🔴 NB-7 ATTERRIT ICI, ET LE FILET DE T7 TIENT — trois boîtes décorées '
      'sous la tuile, et le fond LU est toujours le BON',
      (tester) async {
        await tester.pumpWidget(hote(jeu(2)));
        final fondAuRepos = fondDeLaTuile(tester, tuile: tuile('t0'));
        await tabuler(tester);

        // 🔴 LE FAIT QUE T8 AVAIT MESURÉ : l’enveloppe interactive insère ZÉRO
        // boîte décorée, donc c’est l’ANNEAU qui apporte les suivantes — ce que
        // `C-4` annonçait. Le compte passe de 1 à 3.
        final boites = find.descendant(
          of: tuile('t0'),
          matching: find.byType(DecoratedBox),
        );
        expect(boites, findsNWidgets(3));

        // ✅ Et le sélecteur PAR CLÉ de T7 lit toujours la bonne : avec un
        // sélecteur en `.first`, la tuile aurait rendu la couleur du LISERÉ.
        expect(
          fondDeLaTuile(tester, tuile: tuile('t0')),
          fondAuRepos,
          reason:
              'NB-7 : avec trois boîtes, un sélecteur positionnel '
              'désignerait le liseré et la tuile paraîtrait TOUJOURS orange',
        );
        expect(
          fondDeLaTuile(tester, tuile: tuile('t0')),
          isNot(ConcentrationTokens.moduleActif.couleur),
        );
      },
    );
  });

  group('T11 — clavier et cible tactile, MESURÉS', () {
    testWidgets(
      '⌨️ L’ORDRE DE TABULATION SUIT L’ORDRE DE LA GRILLE — 9 tuiles, 9 arrêts, '
      '⛔ aucun saut, ⛔ aucun retour',
      (tester) async {
        await tester.pumpWidget(hote(jeu(9)));

        final visitees = <String>[];
        for (var i = 0; i < 9; i++) {
          await tabuler(tester);
          for (var j = 0; j < 9; j++) {
            if (anneauExterieur('t$j').evaluate().isNotEmpty) {
              visitees.add('t$j');
            }
          }
        }

        // ⛔ Chaque tabulation met en évidence EXACTEMENT une tuile : sans ce
        // décompte, deux anneaux simultanés passeraient inaperçus.
        expect(visitees.length, 9, reason: 'un arrêt par tabulation, pas deux');
        expect(
          visitees,
          [for (var i = 0; i < 9; i++) 't$i'],
          reason:
              'l’ordre de lecture de la grille, ⛔ pas un ordre de création '
              'accidentel',
        );
      },
    );

    testWidgets(
      '👆 CIBLE TACTILE À 9 TUILES SUR 320 dp — mesurée, ⛔ jamais affirmée',
      (tester) async {
        await tester.pumpWidget(hote(jeu(9), largeur: 320));

        for (var i = 0; i < 9; i++) {
          final r = tester.getRect(tuile('t$i'));
          // ⛔ Le seuil de SC 2.5.5 est 44 × 44 ; celui de Material est
          // 48 × 48. On assère le PLUS EXIGEANT des deux, et US-01.2 a montré
          // qu’une exception se DÉCLARE au lieu de se supposer.
          expect(
            r.width,
            greaterThanOrEqualTo(48),
            reason: 'tuile t$i : largeur ${r.width.toStringAsFixed(1)} dp',
          );
          expect(
            r.height,
            greaterThanOrEqualTo(48),
            reason: 'tuile t$i : hauteur ${r.height.toStringAsFixed(1)} dp',
          );
        }
      },
    );

    // ═══════════════════════════════════════════════════════════════════
    // 🔴 DÉFAUT RÉEL TROUVÉ PAR T11, MESURÉ ET DATÉ — ⛔ pas une borne de
    // mesure, un DÉBORDEMENT que l'utilisateur verrait.
    //
    // **Enveloppe EXACTE, mesurée par sonde jetable** (9 tuiles, 320 dp) :
    //   ×1,0 et ×1,5 AVEC description ......... aucune exception
    //   ×1,6 · ×1,8 · ×2,0 AVEC description ... DÉBORDE (9, une par tuile)
    //   ×2,0 et même ×3,0 SANS description .... aucune exception
    // ⇒ **LA CAUSE EST ÉTABLIE, pas supposée : la description rendue AU
    // REPOS.** À 4 tuiles, ou à 390 dp, il n'y a AUCUN débordement.
    //
    // ➡️ **T13 le referme** : c'est la tâche qui borne l'étape « chaque tuile
    // porte la description » aux ÉCHUES. La mesure « sans description, OK
    // jusqu'à ×3,0 » **est** la preuve que T13 suffit.
    //
    // ⛔ **UN TEST PAR CAS, et ce n'est pas du zèle** : les exceptions de mise
    // en page **FUIENT d'une itération à l'autre** dans un même `testWidgets`
    // — ma première sonde a rendu « ×1,6 déborde, ×1,7 OK, ×2,0 OK », ce qui
    // est FAUX. L'isolement est la condition pour que la mesure veuille dire
    // quelque chose.
    // ═══════════════════════════════════════════════════════════════════
    testWidgets(
      '✅ ×1,5 — 9 tuiles sur 320 dp tiennent SANS débordement (contrôle '
      'positif : sans lui, le test suivant ne prouverait rien)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(hote(jeu(9), largeur: 320));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '✅ ×1,6 — LE DÉBORDEMENT MESURÉ PAR T11 EST REFERMÉ PAR T13, et la '
      'cible tactile tient toujours',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        // ⛔ **`takeException()` NE SUFFIT PAS ICI, et c'est mesuré** : les
        // neuf tuiles lèvent, et le binding rend alors l'AGRÉGAT
        // « Multiple exceptions (9) » — un message qui ⛔ **ne contient pas
        // « overflowed »**. Intercepter `FlutterError.onError` est la seule
        // façon de dire CE QUI s'est passé, et COMBIEN de fois.
        final erreurs = <FlutterErrorDetails>[];
        final precedent = FlutterError.onError;
        FlutterError.onError = erreurs.add;
        await tester.pumpWidget(hote(jeu(9), largeur: 320));
        FlutterError.onError = precedent;

        // ⚖️ **CETTE ASSERTION A ÉTÉ RETOURNÉE LE 2026-08-29, ET C'ÉTAIT
        // ANNONCÉ.** Écrite par T11, elle CONSTATAIT un défaut réel — à
        // 9 tuiles / 320 dp la tuile débordait dès ×1,6 — et disait « devra
        // rougir quand T13 retirera la description au repos ».
        // ✅ **T13 est arrivée, elle a rougi, le défaut est refermé.** La cause
        // avait été mesurée DANS LES DEUX SENS : sans description, aucun
        // débordement même à ×3,0.
        // ⛔ Le test n'est PAS supprimé : il garde le cas le plus étroit du
        // produit sous surveillance, du bon côté cette fois — et un décompte à
        // ZÉRO est une assertion plus forte qu'une absence d'exception.
        expect(
          erreurs,
          isEmpty,
          reason:
              'T13 borne la description aux ÉCHUES ⇒ plus aucun débordement ; '
              '⛔ toute réapparition ici serait une RÉGRESSION du cas le plus '
              'étroit du produit (9 tuiles, 320 dp, ×1,6)',
        );

        // ✅ Et ce que T11 doit garantir TIENT : la cible reste ≥ 48 dp.
        for (var i = 0; i < 9; i++) {
          final r = tester.getRect(tuile('t$i'));
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
        }
      },
    );

    testWidgets(
      '✅ LA CAUSE, MESURÉE DANS LES DEUX SENS — SANS description, ×2,0 ne '
      'déborde PAS : c’est ce qui prouve que T13 suffit',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          hote([
            for (var i = 0; i < 9; i++)
              Echeance(
                id: 't$i',
                description: '',
                dateEcheance: maintenant.add(Duration(days: 3 + i * 7)),
              ),
          ], largeur: 320),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
