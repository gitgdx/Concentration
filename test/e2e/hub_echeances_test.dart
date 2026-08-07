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
import 'package:concentration/features/hub/domain/practice_module_registry.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/echeances_exemple.dart';
import '../support/magasin_temporaire.dart';
import '../support/rendu_couleur.dart';

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
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  /// ⛔ Monte la RACINE de l'application, jamais un sous-arbre.
  ///
  /// La revue de code du 2026-08-02 a relevé que 11 tests sur 13 montaient
  /// `MaterialApp(home: HubPage)` — or c'est le fait de monter **l'application
  /// entière** qui a autorisé ADR-008 §1 à écarter `integration_test/`. Monter
  /// un sous-arbre, c'était garder l'autorisation sans tenir sa contrepartie.
  ///
  /// ⚖️ **US-01.2 (T11) — le seam `echeances:` A DISPARU** (ADR-011 §5). Le
  /// jeu de données ne s'injecte plus : il est **ÉCRIT SUR LE DISQUE**, puis
  /// **relu par le code de production**. ⛔ Aucun titre de scénario n'est
  /// modifié ; c'est le CHEMIN qui change, pas ce qui est vérifié — et il
  /// traverse désormais de vrais octets, comme ADR-010 §1 l'exige.
  Future<void> lancerAvec(WidgetTester tester, List<Echeance> echeances) async {
    final notifier = await notifierCharge(
      tester,
      harnais,
      echeances,
      clock: FakeClock(maintenant),
    );
    await tester.pumpWidget(
      ConcentrationApp(notifier: notifier, clock: FakeClock(maintenant)),
    );
    await tester.pump();
  }

  Future<void> lancerApp(WidgetTester tester) async {
    // Le jeu d'exemple ne vit plus dans `lib/` (AC-13) : il est POSÉ sur le
    // disque comme n'importe quelle donnée de pratiquant.
    await lancerAvec(tester, EcheancesExemple.depuis(FakeClock(maintenant)));
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

    // ⛔ « affiché en MODE SOMBRE de référence » est désormais ASSERTIONNÉ.
    // L'assertion précédente — `scaffold.backgroundColor ?? token, isNotNull` —
    // retombait sur une constante jamais nulle : elle restait vraie avec un
    // fond BLANC (mutant QA-M2b, survivant).
    final theme = Theme.of(tester.element(find.byType(HubPage)));
    expect(theme.scaffoldBackgroundColor, ConcentrationTokens.fondApp.couleur);
    expect(theme.brightness, Brightness.dark);
    // ...et c'est bien cette couleur qui est PEINTE sous la grille.
    final materiau = tester.widget<Material>(
      find
          .ancestor(
            of: find.byType(EcheancesGrid),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(materiau.color, ConcentrationTokens.fondApp.couleur);
  });

  testWidgets('Les modules futurs sont visibles, grisés et non-interactifs', (
    tester,
  ) async {
    await lancerApp(tester);
    expect(find.text('Respiration'), findsOneWidget);
    expect(find.text('Concentration'), findsWidgets);

    // ⛔ « GRISÉS » était le seul mot de l'étape que RIEN n'assertionnait :
    // forcer toutes les entrées à la couleur du module actif laissait les 102
    // tests verts (mutant QA-M5). Le statut du descripteur ne dit rien du RENDU.
    // La liste des modules vient du REGISTRE, jamais recopiée ici.
    const registre = PracticeModuleRegistry();
    final couleurActif = couleurDuLibelle(tester, registre.actif.libelle);
    expect(couleurActif, ConcentrationTokens.moduleActif.couleur);
    expect(registre.grises, isNotEmpty);
    for (final module in registre.grises) {
      final couleurGrise = couleurDuLibelle(tester, module.libelle);
      expect(
        couleurGrise,
        ConcentrationTokens.moduleGrise.couleur,
        reason: '« ${module.libelle} » doit être rendu ESTOMPÉ',
      );
      expect(
        couleurGrise,
        isNot(couleurActif),
        reason: 'un module grisé rendu comme l’actif n’est plus grisé',
      );
    }

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
    // ⚖️ **AMENDEMENT US-01.2 (T11), et il était ANNONCÉ ET MESURÉ** — l'étape
    // du `.feature` est désormais bornée « au périmètre d'US-01.1 » (décision
    // humaine du 2026-08-04), parce qu'AC-1 d'US-01.2 active UNE commande.
    // ⛔ La boucle est RESSERRÉE sur `Icons.settings`, ⛔ PAS SUPPRIMÉE :
    // « Réglages » doit RESTER non-interactif (AC-1 « Limite » d'US-01.2).
    // ⛔ Le titre du scénario est INCHANGÉ.
    for (final icone in [Icons.settings]) {
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
      reason: 'aucune commande HORS PÉRIMÈTRE ne navigue',
    );
    // ⚖️ Le libellé de la commande d'ajout devient « Gérer les échéances » :
    // annoncer « Ajouter » en ouvrant une liste MENTIRAIT au lecteur d'écran.
    expect(find.bySemanticsLabel('Gérer les échéances'), findsWidgets);
    expect(
      find.bySemanticsLabel('Ajouter une échéance'),
      findsNothing,
      reason: '⛔ l’ancien libellé ne doit subsister NULLE PART',
    );
    expect(find.bySemanticsLabel('Réglages'), findsOneWidget);
  });

  testWidgets("Affichage d'une tuile par échéance active", (tester) async {
    // ⚠️ L'étape du scénario dit « 4 échéances actives » et « exactement 4
    // tuiles » ; le test en injectait 3. La donnée suit désormais sa
    // spécification, et le décompte se LIT dans la table, il ne se réécrit pas.
    const jeu = <String, (Duration, String)>{
      'a': (Duration(hours: 3), 'Passeport'),
      'b': (Duration(days: 4), 'Visite médicale'),
      'c': (Duration(days: 30), 'Contrôle technique'),
      'd': (Duration(days: 200), 'Assurance habitation'),
    };
    await lancerAvec(tester, [
      for (final entree in jeu.entries)
        e(entree.key, entree.value.$1, entree.value.$2),
    ]);
    expect(find.byType(EcheanceTile), findsNWidgets(jeu.length));

    // ⛔ « chaque tuile porte la DESCRIPTION de son échéance » : l'étape était
    // décorative — la description pouvait n'être JAMAIS rendue sans qu'un seul
    // test ne rougisse (mutant QA-M4). L'assertion est bornée à CHAQUE tuile,
    // par sa clé, donc elle vérifie aussi l'appariement description ↔ tuile.
    jeu.forEach((id, valeur) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.text(valeur.$2),
        ),
        findsOneWidget,
        reason: 'la tuile « $id » doit porter « ${valeur.$2} »',
      );
    });
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
    // Cible à exactement 6 h : le nombre affiché VIENT de passer à 6 (il a pris
    // sa valeur à l'instant même), donc p = 0 et l'orange de référence.
    await lancerAvec(tester, [e('a', const Duration(hours: 6))]);
    expect(find.text('6'), findsOneWidget);
    expect(fondDeLaTuile(tester), ConcentrationTokens.gradientOrange.couleur);
  });

  testWidgets('Couleur bleue quand le prochain changement est imminent', (
    tester,
  ) async {
    // ⛔ DONNÉE CALCULÉE, pas choisie au jugé. Unité « heures », cible dans
    // 5 h 1 min : le nombre affiché est 6 et il tombera à 5 dans UNE minute —
    // le prochain changement est donc réellement imminent. Les deux instants
    // qui l'encadrent (ADR-002 §4) sont `cible − 6 h` et `cible − 5 h`, soit
    // 60 minutes dont 59 déjà écoulées ⇒ p = (60 − 1) / 60. Dérivé de RF-04,
    // indépendamment du calculateur.
    //
    // ⚠️ La donnée PRÉCÉDENTE (5 h 59) donnait en réalité p = 1/60 — l'ORANGE.
    // Le test restait vert parce qu'il n'observait JAMAIS la couleur rendue :
    // il ne lisait que l'alpha, puis comparait une clarté RECALCULÉE À CÔTÉ par
    // `backgroundFor(0.98)`. D'où le mutant QA-M1 : la tuile pouvait rendre
    // TOUJOURS l'orange sans qu'un seul test ne rougisse.
    const pAttendu = (60 - 1) / 60;
    await lancerAvec(tester, [e('a', const Duration(hours: 5, minutes: 1))]);
    expect(find.text('6'), findsOneWidget);

    final rendue = fondDeLaTuile(tester);
    expect(
      rendue,
      const TemporalGradient().backgroundFor(pAttendu).couleur,
      reason: 'la tuile doit rendre le dégradé À SA progression',
    );
    expect((rendue.a * 255).round(), 255);

    // « Bleue » est une grandeur, mesurée SUR LA COULEUR RENDUE.
    final l = clarteDe(rendue);
    final versBleu = Oklab.depuisRgb(ConcentrationTokens.gradientBleu);
    final versOrange = Oklab.depuisRgb(ConcentrationTokens.gradientOrange);
    expect(
      (l - versBleu.l).abs(),
      lessThan((l - versOrange.l).abs()),
      reason:
          'la couleur RENDUE doit tirer vers le bleu quand le changement est '
          'imminent (clarté mesurée : $l)',
    );
    expect(rendue, isNot(ConcentrationTokens.gradientOrange.couleur));
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
