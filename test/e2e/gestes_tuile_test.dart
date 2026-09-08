import 'package:concentration/app/app.dart';
import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_etat.dart';
import 'package:concentration/features/echeances/domain/echeance_repository.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/gestion_echeances_page.dart';
import 'package:concentration/features/echeances/presentation/widgets/confirmation_suppression.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/echeances/presentation/widgets/empty_echeances_placeholder.dart';
import 'package:concentration/features/echeances/presentation/widgets/formulaire_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/ligne_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/message_ecriture.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/gestes_tuile.dart';
import '../support/magasin_temporaire.dart';
import '../support/rendu_couleur.dart';

/// **Les scénarios d'US-01.4** — un test par scénario du `.feature`
/// **NORMATIF** (T14).
///
/// ⛔ **AUCUN TOTAL N'EST ÉCRIT ICI** *(défaut ⑤ : en US-01.2 le même nombre
/// dérivé vivait en 23 exemplaires)*. Il se **LIT** :
/// `grep -c "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature`, et
/// `grep "^  Scénario: " … | sort | uniq -d` doit rendre une sortie **vide**.
///
/// ⛔ **LES TITRES NE SONT PAS RETAPÉS** : ils sont **lus** dans le `.feature`.
/// En US-01.1, **13 scénarios et 13 lignes de résumé divergeaient par 5
/// titres** (R-8) — un titre recopié à la main **dérive**.
/// ℹ️ **Les apostrophes du `.feature` sont TOUTES ASCII** *(mesuré : 10 titres
/// en portent une, `0` porte l'apostrophe typographique)* ⇒ ces titres-là
/// s'écrivent en **chaîne à guillemets doubles**, comme le `.feature` le
/// prescrit lui-même.
///
/// 🔴 **CONTRAT D'ADR-010 §1, non négociable, vérifié par machine**
/// *(`check_e2e_persistance.py`)* :
/// 1. **monter la RACINE** (`ConcentrationApp`), ⛔ jamais un sous-arbre ;
/// 2. **traverser un magasin RÉEL** — un fichier réel, dans un répertoire
///    temporaire réel, lu et écrit par le **code de production** ;
/// 3. **assertionner l'ÉTAT PERSISTÉ** partout où le scénario parle du
///    stockage : l'assertion **lit les octets**, ⛔ jamais seulement le rendu.
///
/// ⚠️ **`FakeClock` n'est PAS un magasin factice** : c'est l'horloge injectée
/// d'ADR-002, du **code de production**.
///
/// ⛔ **AUCUNE DATE DE CALENDRIER EN DUR (R-13)** : tout se dérive de
/// [maintenant]. Une date en dur devient passée avec le temps et ferait pourrir
/// les tests **en silence**.
///
/// ⛔ **NI LA PÉRIODE DE RAFRAÎCHISSEMENT NI LA FENÊTRE DE RÉVÉLATION NE SONT
/// ÉCRITES ICI** : elles se **lisent** dans `ConcentrationTokens`. Les
/// scénarios disent *« un rafraîchissement se produit »*, ce qui reste vrai si
/// la période change.
void main() {
  final maintenant = DateTime(2026, 9, 8, 12);
  const periode = ConcentrationTokens.periodeRafraichissement;
  const fenetre = ConcentrationTokens.fenetreRevelation;
  const dureeAnim = ConcentrationTokens.dureeDisparition;
  const grain = Duration(milliseconds: 10);
  const codec = EcheanceDocumentCodec();

  late MagasinTemporaire harnais;
  late FakeClock horloge;
  late EcheancesNotifier notifier;

  setUp(() {
    harnais = MagasinTemporaire.creer();
    // ⛔ L'horloge est NEUVE à chaque test : partagée, une avance de temps
    // fuirait d'un test à l'autre et le verdict deviendrait dépendant de
    // l'ORDRE d'exécution — défaut mesuré à T11 sur les exceptions de mise en
    // page.
    horloge = FakeClock(maintenant);
  });
  tearDown(() => harnais.nettoyer());

  // ⛔ LA GARDE DU PHASAGE N'EST PAS RÉPÉTÉE ICI, ET C'EST UNE DÉCISION.
  // Le phasage n'est possible que si `fenetreRevelation < periodeRafraichissement` ;
  // sans cette garde, le scénario du rafraîchissement serait VERT SANS RIEN
  // OBSERVER. Mais elle existe DÉJÀ, en UN SEUL exemplaire, dans
  // `test/features/echeances/presentation/echeances_grid_test.dart` (T9) —
  // ⛔ la recopier ici en ferait DEUX, et « une règle n'existe qu'en un seul
  // exemplaire » (vérifié trois fois sur ce corpus).
  //
  // ⚠️ ET ELLE NE POUVAIT PAS VIVRE ICI DE TOUTE FAÇON, c'est MESURÉ :
  // `check_gherkin_mapping.py` capte `test(` **autant que** `testWidgets(`
  // (son `MOTIF_TEST`), donc toute assertion hors-scénario dans ce fichier
  // deviendrait un « TEST SANS SCÉNARIO » et rendrait le job REQUIS rouge dès
  // l'inscription du couple à T15.

  Echeance ech(String id, Duration dans, [String d = 'revue annuelle']) =>
      Echeance(id: id, description: d, dateEcheance: maintenant.add(dans));

  Echeance echue(String id, [String d = 'revue annuelle']) =>
      ech(id, const Duration(days: -2), d);

  /// Pose un document **directement sur le disque**, avant tout démarrage.
  void poser(List<Echeance> liste, {int version = versionCourante}) =>
      harnais.poser(codec.encoder(codec.documentNeuf(version), liste));

  /// Ce que le **FICHIER** contient — ⛔ pas ce que l'écran montre.
  List<Echeance> persistees() {
    final texte = harnais.octets();
    if (texte == null) return const <Echeance>[];
    return codec.decoder(texte)?.echeances ?? const <Echeance>[];
  }

  Echeance persistee(String id) => persistees().firstWhere((e) => e.id == id);

  /// ⛔ **LE SEUL `pumpWidget` DU FICHIER**, et il monte **la RACINE**.
  ///
  /// Chaque appel construit un dépôt et un notifier **NEUFS** sur le **même**
  /// répertoire : c'est exactement ce que « je rouvre l'application » veut
  /// dire, et ⛔ ce n'est pas le même objet en mémoire — sinon on ne testerait
  /// que la RAM.
  Future<void> ouvrirApplication(WidgetTester tester) async {
    notifier = EcheancesNotifier(
      depot: EcheanceDocumentRepository(harnais.magasin),
      clock: horloge,
    );
    await tester.runAsync(notifier.charger);
    await tester.pumpWidget(
      ConcentrationApp(notifier: notifier, clock: horloge),
    );
    await tester.pumpAndSettle();
  }

  Finder tuile(String id) => find.byKey(ValueKey(id));
  final enveloppe = find.byKey(EcheancesGrid.cleDisparition);

  Finder dansLaTuile(String id, Finder quoi) =>
      find.descendant(of: tuile(id), matching: quoi);

  /// 🔴 **SE CALER SUR UN TIC DE RAFRAÎCHISSEMENT, ET LE PROUVER.**
  ///
  /// ⛔ **Le phasage de T9 ne se transpose PAS tel quel en e2e, et c'est
  /// MESURÉ** : `ouvrirApplication` finit par `pumpAndSettle`, qui consomme un
  /// temps **INCONNU** ⇒ *« juste avant le tic »* n'est plus calculable depuis
  /// le montage, et un `pump(periode - grain)` peut **franchir** le tic au lieu
  /// de s'arrêter devant. Premier jet de ce fichier : le tic tombait **avant**
  /// l'appui, et le test rougissait pour la mauvaise raison.
  ///
  /// ⚠️ **Le défaut le plus utile trouvé au passage était dans MON contRÔLE, pas
  /// dans le produit** : *« aucun tic n'a encore eu lieu »* était asserté
  /// **sans avoir fait avancer l'horloge** ⇒ l'affichage ⛔ **ne pouvait pas
  /// changer**, tic ou pas. **Un contrôle qui ne peut pas échouer est nul.**
  /// C'est pourquoi l'appelant avance l'horloge **avant** de se caler, puis
  /// **encore** avant de se placer devant le tic suivant.
  ///
  /// Le pas est `grain` — ⛔ pas un pas grossier : au retour on est à
  /// `tic + err` avec `err ≤ grain`, et c'est cette borne qui rend le
  /// `periode - 3·grain` de l'appelant sûr.
  Future<void> seCalerSurUnTic(WidgetTester tester, Finder attendu) async {
    final pas = periode.inMilliseconds ~/ grain.inMilliseconds;
    for (var i = 0; i <= pas; i++) {
      if (tester.any(attendu)) return;
      await tester.pump(grain);
    }
    fail(
      'aucun tic de rafraîchissement observé en une période entière — le test '
      'ne mesurerait RIEN',
    );
  }

  /// Revient au hub **quel que soit l'écran empilé**.
  ///
  /// ⛔ **Un seul `pageBack` ne suffit pas, et c'est mesuré** : après un refus
  /// de création le **formulaire RESTE OUVERT** *(c'est exactement ce que le
  /// refus doit faire)*, donc un `pageBack` unique atterrit sur la page de
  /// gestion et ⛔ pas sur la grille. Premier jet de ce fichier : la tuile
  /// cherchée n'existait pas, et le test rougissait pour la mauvaise raison.
  Future<void> retournerAuHub(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      if (!tester.any(find.byType(FormulaireEcheance)) &&
          !tester.any(find.byType(GestionEcheancesPage))) {
        return;
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    fail('impossible de revenir au hub : un écran reste empilé');
  }

  /// Le double appui, **en un seul exemplaire** (`test/support/gestes_tuile.dart`).
  /// ⛔ Jamais deux `tap()` nus : un double appui mal séparé est reçu comme
  /// **deux appuis simples**, donc le test observerait la **révélation** au
  /// lieu du **retrait**, sans rougir pour la bonne raison.
  Future<void> doubleAppuiSur(WidgetTester tester, String id) =>
      doubleAppui(tester, tuile(id));

  /// Un retrait **mené à son terme** : le geste, l'écriture RÉELLE, puis
  /// l'animation. ⛔ `reglerEcritures` n'est pas décoratif — une écriture
  /// disque déclenchée par un tap **n'aboutit pas** sous `FakeAsync`.
  ///
  /// ⚠️ **`tours` est GÉNÉREUX, et la valeur vient d'une MESURE, ⛔ pas d'une
  /// précaution** : à 40 tours *(le défaut)*, ce fichier passait **en
  /// isolement** et rougissait **en suite** sur le seul scénario du réessai —
  /// celui qui enchaîne une écriture **échouée**, une écriture **réussie** et
  /// un **rechargement**, soit la chaîne d'entrées-sorties la plus longue de
  /// l'US. C'est exactement ce que la documentation de `reglerEcritures`
  /// annonce. ⛔ **Le coût n'est PAS payé dans les cas rapides** : la condition
  /// `jusqua` sort dès que l'effet est là.
  Future<void> retirer(WidgetTester tester, String id) async {
    await doubleAppuiSur(tester, id);
    await reglerEcritures(
      tester,
      jusqua: () => !tester.any(tuile(id)),
      tours: 200,
    );
    await purgerLeReconnaisseur(tester);
    await tester.pumpAndSettle();
  }

  /// Tous les libellés sémantiques de l'écran, concaténés.
  /// ⛔ **PAS `.first`** : `FocusableActionDetector` insère son propre
  /// `Semantics` **sans libellé** (mesuré à T8).
  String libelles(WidgetTester tester) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((w) => w.properties.label)
      .whereType<String>()
      .join(' | ');

  String hints(WidgetTester tester) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((w) => w.properties.hint)
      .whereType<String>()
      .join(' | ');

  /// Le texte du message d'écriture réellement monté, ou `null`.
  /// ⚠️ `find.byType(MessageEcriture)` le trouve **même sans message** : la
  /// hauteur est réservée en permanence (T19). C'est le **texte** qui dit s'il
  /// y a un message.
  String? messageAffiche(WidgetTester tester) {
    final trouves = tester.widgetList<MessageEcriture>(
      find.byType(MessageEcriture),
    );
    if (trouves.isEmpty) return null;
    final texte = trouves.first.texte;
    return texte.isEmpty ? null : texte;
  }

  Future<void> ouvrirGestion(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  Future<void> revenir(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  String jjmmaaaa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().padLeft(4, '0')}';

  /// Tente une création depuis la page de gestion — ⛔ le parcours COMPLET,
  /// jamais un appel direct au notifier : c'est le refus **à l'écran** que les
  /// scénarios de la limite décrivent.
  Future<void> tenterCreation(
    WidgetTester tester, {
    String description = 'nouvelle',
  }) async {
    await tester.tap(
      find.descendant(
        of: find.byType(GestionEcheancesPage),
        matching: find.text('Ajouter une échéance'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), description);
    await tester.enterText(
      find.byType(TextField).at(1),
      jjmmaaaa(maintenant.add(const Duration(days: 120))),
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await reglerEcritures(
      tester,
      jusqua: () => !tester.any(find.byType(FormulaireEcheance)),
    );
    await tester.pumpAndSettle();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AC-1 — LE REPOS : le nombre en cadran, la description bornée aux ÉCHUE
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Au repos la tuile active affiche son nombre seul et centré', (
    tester,
  ) async {
    poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
    await ouvrirApplication(tester);

    // ① Le nombre est le SEUL élément visible de la tuile.
    expect(dansLaTuile('a', find.text('6')), findsOneWidget);
    expect(
      dansLaTuile('a', find.byType(Text)),
      findsOneWidget,
      reason: 'le nombre SEUL : ⛔ aucun autre Text peint sur la tuile',
    );

    // ② Centré sur les DEUX axes — assertion de GÉOMÉTRIE sur le rendu réel,
    // ⛔ pas une lecture de `crossAxisAlignment` (qui serait tautologique).
    final centreTuile = tester.getRect(tuile('a')).center;
    final centreNombre = tester
        .getRect(dansLaTuile('a', find.text('6')))
        .center;
    expect((centreNombre.dx - centreTuile.dx).abs(), lessThan(1.0));
    expect((centreNombre.dy - centreTuile.dy).abs(), lessThan(1.0));

    // ③ Strictement plus gros que la taille livrée par US-01.1 — laquelle est
    // NOMMÉE dans le produit (`tailleNombreEchue`, « celle d'US-01.1,
    // INCHANGÉE »). Assertion de GRANDEUR : ⛔ pas une égalité au token.
    final style = tester.widget<Text>(dansLaTuile('a', find.text('6'))).style!;
    expect(
      style.fontSize,
      greaterThan(ConcentrationTheme.tailleNombreEchue),
      reason: 'AC-1 : le nombre d’une ACTIVE est AGRANDI par rapport à US-01.1',
    );
  });

  testWidgets("Au repos la description n'est pas affichée sur la tuile active", (
    tester,
  ) async {
    poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
    await ouvrirApplication(tester);

    expect(
      dansLaTuile('a', find.text('revue annuelle')),
      findsNothing,
      reason: 'T13 : une ACTIVE ne PEINT plus sa description au repos',
    );
    // ⛔ Aucune unité, fraction, signe ni texte parasite (RF-01).
    for (final parasite in [
      'j',
      'jour',
      'jours',
      'h',
      'heure',
      'mois',
      'an',
      '/',
      '~',
      '+',
      '-',
      '≈',
    ]) {
      expect(
        dansLaTuile('a', find.textContaining(parasite)),
        findsNothing,
        reason: '⛔ « $parasite » n’a rien à faire sur la tuile',
      );
    }
    // ✅ CONTRÔLE POSITIF APPARIÉ : l'unité EXISTE — dans le libellé
    // d'accessibilité, et nulle part ailleurs (AC-8). Sans lui, les assertions
    // ci-dessus seraient vraies sur un écran vide.
    expect(libelles(tester), contains('heures'));
  });

  testWidgets(
    'Une tuile échue conserve sa description affichée en permanence',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);

      // ⛔ AUCUN geste préalable : la description est là dès l'affichage.
      expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);
      expect(dansLaTuile('a', find.text('0')), findsOneWidget);
    },
  );

  testWidgets(
    "Le libellé d'accessibilité de la tuile contient toujours la description",
    (tester) async {
      poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
      await ouvrirApplication(tester);

      final lus = libelles(tester);
      expect(lus, contains('6'));
      expect(lus, contains('heures'), reason: 'le temps AVEC son unité');
      expect(lus, contains('revue annuelle'));
    },
  );

  testWidgets(
    'Neuf tuiles au nombre agrandi ne débordent pas à deux fois la taille de police système',
    (tester) async {
      // ⛔ `takeException()` NE SUFFIT PAS : à neuf tuiles le binding rend
      // l'AGRÉGAT « Multiple exceptions (9) », qui ⛔ ne contient pas le mot
      // « overflowed ». On intercepte pour dire CE QUI se passe et COMBIEN de
      // fois (technique mesurée à T11).
      final incidents = <String>[];
      final precedent = FlutterError.onError;
      FlutterError.onError = (details) =>
          incidents.add(details.exceptionAsString());
      addTearDown(() => FlutterError.onError = precedent);

      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      poser([
        for (var i = 0; i < ConcentrationTokens.tuilesMax; i++)
          ech('t$i', Duration(hours: 6 + i), 'description $i'),
      ]);
      await ouvrirApplication(tester);

      expect(find.byType(EcheanceTile), findsNWidgets(9));
      expect(
        incidents.where((m) => m.contains('overflowed')),
        isEmpty,
        reason: 'aucune tuile ne déborde de la grille',
      );
      // Chaque nombre est affiché EN ENTIER — ⛔ ni troncature ni ellipse.
      for (var i = 0; i < 9; i++) {
        final texte = tester.widget<Text>(
          dansLaTuile('t$i', find.text('${6 + i}')),
        );
        expect(texte.overflow, isNot(TextOverflow.ellipsis));
        expect(texte.data, '${6 + i}');
      }
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-2 — LA RÉVÉLATION : immédiate, 3 secondes, exclusive
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Un appui simple remplace le nombre par la description', (
    tester,
  ) async {
    poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
    await ouvrirApplication(tester);
    expect(dansLaTuile('a', find.text('6')), findsOneWidget);

    await tester.tap(tuile('a'));
    // ⛔ SANS ATTENDRE : aucune avance de temps entre l'appui et l'observation.
    // Une animation de transition ou un `kDoubleTapTimeout` ferait échouer ici
    // (verdict clarify nº 1, pris POUR L'IMMÉDIATETÉ).
    await tester.pump();

    expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);
    expect(
      dansLaTuile('a', find.text('6')),
      findsNothing,
      reason: 'À LA PLACE du nombre — ⛔ pas à côté',
    );

    await tester.pump(fenetre + grain);
  });

  testWidgets('Le nombre revient au bout de trois secondes', (tester) async {
    poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
    await ouvrirApplication(tester);

    await tester.tap(tuile('a'));
    await tester.pump();
    expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);

    // Le nombre revenu est celui du CALCUL COURANT, ⛔ pas celui mémorisé à
    // l'appui : l'horloge avance pendant la fenêtre.
    horloge.avancerDe(const Duration(hours: 2));
    await tester.pump(fenetre + grain);

    expect(dansLaTuile('a', find.text('4')), findsOneWidget);
    expect(
      dansLaTuile('a', find.text('6')),
      findsNothing,
      reason: 'un nombre MÉMORISÉ à l’appui réapparaîtrait à 6',
    );
    expect(dansLaTuile('a', find.text('revue annuelle')), findsNothing);
  });

  testWidgets('Appuyer une seconde tuile referme la première révélation', (
    tester,
  ) async {
    poser([
      ech('a', const Duration(hours: 6), 'revue annuelle'),
      ech('b', const Duration(hours: 8), 'passeport'),
    ]);
    await ouvrirApplication(tester);

    await tester.tap(tuile('a'));
    await tester.pump();
    expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);

    await tester.tap(tuile('b'));
    await tester.pump();

    expect(dansLaTuile('b', find.text('passeport')), findsOneWidget);
    // 🔴 Avec un minuteur PAR TUILE, les DEUX descriptions seraient révélées.
    expect(dansLaTuile('a', find.text('revue annuelle')), findsNothing);
    expect(dansLaTuile('a', find.text('6')), findsOneWidget);

    await tester.pump(fenetre + grain);
  });

  testWidgets(
    "Un rafraîchissement de la grille n'interrompt pas la révélation",
    (tester) async {
      // 🔴 PHASAGE (ADR-013 §4) : on se place JUSTE AVANT le tic, on appuie,
      // puis on franchit le tic SANS sortir de la fenêtre. ⇒ le test porte sur
      // la PÉRIODE RÉELLE DE PRODUCTION, ⛔ aucun seam.
      //
      // ⛔ CE QUI PROUVE QUE LE TIC A EU LIEU, sans espion : le nombre de la
      // tuile NON révélée change. Sans cette preuve, un test où le tic n'arrive
      // JAMAIS serait vert et ne prouverait rien.
      poser([
        ech('a', const Duration(hours: 6), 'revue annuelle'),
        ech('b', const Duration(hours: 8), 'passeport'),
      ]);
      await ouvrirApplication(tester);
      expect(dansLaTuile('b', find.text('8')), findsOneWidget);

      // ① Se caler sur un tic RÉELLEMENT OBSERVÉ — l'horloge avance d'abord,
      // sinon l'observation ne pourrait rien distinguer.
      horloge.avancerDe(const Duration(hours: 1));
      await seCalerSurUnTic(tester, dansLaTuile('b', find.text('7')));

      // ② Avancer encore, puis se placer JUSTE AVANT le tic suivant.
      horloge.avancerDe(const Duration(hours: 1));
      await tester.pump(periode - grain * 3);
      expect(
        dansLaTuile('b', find.text('7')),
        findsOneWidget,
        reason:
            'aucun tic n’a encore eu lieu — et ce contrôle PEUT échouer, '
            'l’horloge ayant déjà avancé : c’est ce qui le rend falsifiable',
      );

      // ③ Appuyer.
      await tester.tap(tuile('a'));
      await tester.pump();
      expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);

      // ④ Franchir le tic, SANS sortir de la fenêtre.
      await tester.pump(grain * 6);
      expect(
        dansLaTuile('b', find.text('6')),
        findsOneWidget,
        reason: 'le rafraîchissement a bien EU LIEU — il n’est pas supposé',
      );
      expect(
        dansLaTuile('a', find.text('revue annuelle')),
        findsOneWidget,
        reason: 'la fenêtre n’est pas COUPÉE par le rafraîchissement',
      );

      // ⑤ …et elle n'est pas PROLONGÉE : elle expire à son heure initiale.
      await tester.pump(fenetre - grain * 8);
      expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);
      await tester.pump(grain * 4);
      expect(dansLaTuile('a', find.text('revue annuelle')), findsNothing);
      expect(
        dansLaTuile('a', find.text('4')),
        findsOneWidget,
        reason: 'le nombre revenu est celui du calcul courant',
      );
    },
  );

  testWidgets(
    'Un nouvel appui pendant la révélation redémarre les trois secondes',
    (tester) async {
      poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
      await ouvrirApplication(tester);

      await tester.tap(tuile('a'));
      await tester.pump();
      // On consomme la MOITIÉ de la fenêtre…
      await tester.pump(fenetre ~/ 2);
      expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);

      // …puis on ré-appuie. Le minuteur précédent doit être ANNULÉ.
      await tester.tap(tuile('a'));
      await tester.pump();

      // 🔴 Le mutant que ce test tue : un `Timer` posé SANS annuler le
      // précédent refermerait la révélation à l'échéance de la PREMIÈRE —
      // donc ici, à la moitié restante.
      await tester.pump(fenetre - grain);
      expect(
        dansLaTuile('a', find.text('revue annuelle')),
        findsOneWidget,
        reason: 'trois secondes APRÈS LE NOUVEL APPUI, encore révélée',
      );

      await tester.pump(grain * 2);
      expect(
        dansLaTuile('a', find.text('revue annuelle')),
        findsNothing,
        reason: 'et le nombre revient ENSUITE',
      );
      expect(dansLaTuile('a', find.text('6')), findsOneWidget);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-2 « Erreur » — la description VIDE : ⛔ aucune enveloppe interactive
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets("Une tuile active sans description n'annonce aucune révélation", (
    tester,
  ) async {
    poser([ech('a', const Duration(hours: 6), '')]);
    await ouvrirApplication(tester);

    expect(dansLaTuile('a', find.text('6')), findsOneWidget);
    // ⛔ Elle ne s'annonce PAS comme révélant une description.
    expect(hints(tester), isNot(contains(EcheanceTile.hintRevelation)));
    // ⛔ Et elle ne porte AUCUN gestionnaire d'appui — l'enveloppe interactive
    // est CONDITIONNELLE (ADR-014 §A.1). `findsNothing` sur l'ANCÊTRE, ⛔ pas
    // un `tap` sans effet, qui passe aussi quand l'écran est mort.
    expect(
      find.ancestor(of: tuile('a'), matching: find.byType(GestureDetector)),
      findsNothing,
    );
    expect(
      dansLaTuile('a', find.byType(GestureDetector)),
      findsNothing,
      reason: 'ni au-dessus, ni au-dessous',
    );
  });

  testWidgets(
    'Un appui sur une tuile active sans description ne fait rien apparaître',
    (tester) async {
      poser([ech('a', const Duration(hours: 6), '')]);
      await ouvrirApplication(tester);

      await tester.tap(tuile('a'), warnIfMissed: false);
      await tester.pump();

      expect(dansLaTuile('a', find.text('6')), findsOneWidget);
      expect(
        dansLaTuile('a', find.byType(Text)),
        findsOneWidget,
        reason: '⛔ aucun texte de substitution',
      );
      expect(tester.takeException(), isNull);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-4 / AC-5 — LE RETRAIT : l'écriture d'abord, l'animation ensuite
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Une tuile échue sans description reste retirable', (
    tester,
  ) async {
    poser([echue('a', '')]);
    await ouvrirApplication(tester);
    expect(tuile('a'), findsOneWidget);

    await retirer(tester, 'a');

    expect(tuile('a'), findsNothing);
    // ASSERTION SUR LES OCTETS : conservée, ⛔ pas supprimée.
    expect(persistees(), hasLength(1));
    expect(persistee('a').retiree, isTrue);
  });

  testWidgets('Un double appui fait disparaître une tuile échue', (
    tester,
  ) async {
    poser([
      echue('a', 'revue annuelle'),
      ech('b', const Duration(hours: 6), 'passeport'),
    ]);
    await ouvrirApplication(tester);

    await doubleAppuiSur(tester, 'a');
    await reglerEcritures(tester, jusqua: () => tester.any(enveloppe));

    // ① Une animation de disparition se joue.
    expect(
      enveloppe,
      findsOneWidget,
      reason:
          'AC-8 : la disparition n’est jamais sèche quand les animations '
          'sont actives',
    );
    await tester.pumpAndSettle();
    await purgerLeReconnaisseur(tester);

    // ② La tuile est absente…
    expect(tuile('a'), findsNothing);
    // ③ …et la grille se recompose sans laisser de trou : la voisine reste
    // affichée et la grille ne porte plus qu'UNE tuile.
    expect(find.byType(EcheanceTile), findsOneWidget);
    expect(tuile('b'), findsOneWidget);
    expect(persistee('a').retiree, isTrue);
  });

  testWidgets("L'échéance retirée reste consultable dans la page de gestion", (
    tester,
  ) async {
    final heureEchue = maintenant.subtract(const Duration(days: 2));
    poser([echue('a', 'revue annuelle')]);
    await ouvrirApplication(tester);
    await retirer(tester, 'a');

    await ouvrirGestion(tester);

    // Listée dans le groupe des ÉCHUES — ⛔ aucun troisième groupe.
    expect(find.text('revue annuelle'), findsWidgets);
    expect(
      find.textContaining(LigneEcheance.marqueRetiree),
      findsOneWidget,
      reason: 'elle est SIGNALÉE retirée, et elle reste LISTÉE',
    );
    // Description, date et heure INCHANGÉES — lues sur les OCTETS.
    final relue = persistee('a');
    expect(relue.description, 'revue annuelle');
    expect(relue.dateEcheance, heureEchue);
  });

  testWidgets('Un double appui sur une tuile active ne produit aucun effet', (
    tester,
  ) async {
    poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
    await ouvrirApplication(tester);
    final avant = harnais.octets();

    await doubleAppuiSur(tester, 'a');
    await reglerEcritures(tester);
    await purgerLeReconnaisseur(tester);
    await tester.pumpAndSettle();

    expect(tuile('a'), findsOneWidget);
    expect(enveloppe, findsNothing, reason: '⛔ aucune animation');
    // RIEN n'est écrit — assertion sur les OCTETS, bit à bit.
    expect(harnais.octets(), avant);
    expect(persistee('a').retiree, isFalse);
  });

  testWidgets(
    'Un appui simple sur une tuile échue ne retire rien et ne révèle rien',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);
      final avant = harnais.octets();

      await tester.tap(tuile('a'));
      await reglerEcritures(tester);
      await tester.pumpAndSettle();

      expect(tuile('a'), findsOneWidget);
      // ⛔ Aucune description révélée À LA PLACE du nombre : le « 0 » est
      // toujours là (l'échue affiche les DEUX en permanence).
      expect(dansLaTuile('a', find.text('0')), findsOneWidget);
      expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);
      expect(harnais.octets(), avant);
    },
  );

  testWidgets('Un appui prolongé sur une tuile ne produit aucun effet', (
    tester,
  ) async {
    poser([echue('a', 'revue annuelle'), ech('b', const Duration(hours: 6))]);
    await ouvrirApplication(tester);
    final avant = harnais.octets();

    for (final id in ['a', 'b']) {
      await tester.longPress(tuile(id));
      await reglerEcritures(tester);
      await tester.pumpAndSettle();
    }

    expect(tuile('a'), findsOneWidget);
    expect(tuile('b'), findsOneWidget);
    expect(harnais.octets(), avant);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le retrait ne demande aucune confirmation', (tester) async {
    poser([echue('a', 'revue annuelle')]);
    await ouvrirApplication(tester);

    await doubleAppuiSur(tester, 'a');
    await tester.pump();

    // ⛔ Aucune demande de confirmation, à AUCUN moment.
    expect(find.byType(ConfirmationSuppression), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);

    await reglerEcritures(tester, jusqua: () => !tester.any(tuile('a')));
    await purgerLeReconnaisseur(tester);
    await tester.pumpAndSettle();

    // …et l'échéance n'est PAS supprimée du stockage.
    expect(persistees(), hasLength(1));
    expect(persistee('a').retiree, isTrue);
  });

  testWidgets(
    'Une échéance retirée ne revient pas sur la grille après réouverture',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);
      await retirer(tester, 'a');

      // « L'application est rouverte » : un dépôt et un notifier NEUFS sur le
      // MÊME répertoire — ⛔ pas le même objet en mémoire.
      await ouvrirApplication(tester);

      expect(tuile('a'), findsNothing);
      expect(find.byType(EcheanceTile), findsNothing);

      await ouvrirGestion(tester);
      expect(find.text('revue annuelle'), findsWidgets);
    },
  );

  testWidgets(
    'Les échéances enregistrées par la version antérieure restent présentes sur la grille',
    (tester) async {
      // Un stockage écrit par la version ANTÉRIEURE du schéma.
      // ⛔ Le numéro ne s'écrit pas à la main : il se DÉRIVE de la version
      // courante — sinon il périmerait à la migration suivante.
      poser([
        ech('a', const Duration(hours: 6), 'revue annuelle'),
        ech('b', const Duration(days: 30), 'passeport'),
        echue('c', 'contrôle technique'),
      ], version: versionCourante - 1);
      expect(
        harnais.octets(),
        contains('"schemaVersion":${versionCourante - 1}'),
        reason: 'la graine est bien à la version ANTÉRIEURE',
      );

      await ouvrirApplication(tester);

      expect(find.byType(EcheanceTile), findsNWidgets(3));
      // ⛔ AUCUNE échéance retirée sans geste — lu sur les OCTETS migrés.
      expect(persistees().where((e) => e.retiree), isEmpty);
      expect(presentesSurLaGrille(persistees()), hasLength(3));
      expect(
        harnais.octets(),
        contains('"schemaVersion":$versionCourante'),
        reason: 'la migration a bien eu lieu',
      );
    },
  );

  testWidgets(
    'Une échéance retirée reste supprimable définitivement en gestion',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);
      await retirer(tester, 'a');
      expect(persistees(), hasLength(1));

      await ouvrirGestion(tester);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await reglerEcritures(
        tester,
        jusqua: () => !tester.any(find.byType(ConfirmationSuppression)),
      );
      await tester.pumpAndSettle();

      expect(find.text('revue annuelle'), findsNothing);
      // SUPPRIMÉE : elle a quitté les OCTETS.
      expect(persistees(), isEmpty);

      await revenir(tester);
      await ouvrirApplication(tester);
      await ouvrirGestion(tester);
      expect(find.text('revue annuelle'), findsNothing);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-6 — LA LIMITE DE NEUF, et le message CONDITIONNEL
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Retirer une échue libère une place sur la grille', (
    tester,
  ) async {
    poser([
      for (var i = 0; i < 8; i++) ech('t$i', Duration(hours: 6 + i)),
      echue('z', 'revue annuelle'),
    ]);
    await ouvrirApplication(tester);
    expect(find.byType(EcheanceTile), findsNWidgets(9));

    // ① La création d'une dixième vient d'être refusée.
    await ouvrirGestion(tester);
    await tenterCreation(tester, description: 'refusee');
    expect(messageAffiche(tester), isNotNull);
    expect(persistees(), hasLength(9));

    // ② Je retire l'échue par un double appui, depuis le hub.
    // ⛔ `retournerAuHub`, ⛔ PAS un `pageBack` unique : le refus laisse le
    // formulaire OUVERT, donc un seul retour n'atteint pas la grille.
    await retournerAuHub(tester);
    await retirer(tester, 'z');
    expect(presentesSurLaGrille(persistees()), hasLength(8));

    // ③ Et je crée une nouvelle échéance : elle ABOUTIT.
    await ouvrirGestion(tester);
    await tenterCreation(tester, description: 'nouvelle');
    expect(
      find.byType(FormulaireEcheance),
      findsNothing,
      reason: 'le formulaire s’est refermé : la création a abouti',
    );
    expect(persistees(), hasLength(10));

    // ④ …et elle apparaît sur la grille SANS REDÉMARRAGE — ⛔ pas de
    // `ouvrirApplication` ici : c'est exactement ce que le scénario exige.
    await retournerAuHub(tester);
    expect(find.byType(EcheanceTile), findsNWidgets(9));
    expect(libelles(tester), contains('nouvelle'));
  });

  testWidgets(
    'Le message de la dixième tentative annonce le retrait quand une échue est sur la grille',
    (tester) async {
      poser([
        for (var i = 0; i < 8; i++) ech('t$i', Duration(hours: 6 + i)),
        echue('z', 'revue annuelle'),
      ]);
      await ouvrirApplication(tester);
      await ouvrirGestion(tester);

      await tenterCreation(tester);

      expect(find.byType(FormulaireEcheance), findsOneWidget);
      final message = messageAffiche(tester);
      expect(message, isNotNull, reason: 'la création est REFUSÉE');
      // ⛔ La phrase n'est PAS recopiée ici : le « 9 » se lit dans le produit.
      expect(message, contains('${ValidationEcheance.maxPresentesSurGrille}'));
      // Le message annonce LE RETRAIT **et** la suppression.
      expect(message, contains('retire'));
      expect(message, contains('supprim'));
      // ASSERTION SUR LES OCTETS : toujours neuf.
      expect(persistees(), hasLength(9));
    },
  );

  testWidgets(
    "Le message de la dixième tentative n'annonce que la suppression sans échue sur la grille",
    (tester) async {
      poser([
        for (var i = 0; i < ConcentrationTokens.tuilesMax; i++)
          ech('t$i', Duration(hours: 6 + i)),
      ]);
      await ouvrirApplication(tester);
      await ouvrirGestion(tester);

      await tenterCreation(tester);

      final message = messageAffiche(tester);
      expect(message, isNotNull);
      expect(message, contains('${ValidationEcheance.maxPresentesSurGrille}'));
      expect(message, contains('supprim'));
      // ⛔ Il n'annonce PAS le retrait : l'annoncer sans échue inviterait à un
      // geste INDISPONIBLE.
      expect(message, isNot(contains('retire')));
      expect(message, isNot(contains('double appui')));
      expect(persistees(), hasLength(9));
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-7 — LE SIGNALEMENT EN GESTION (Should, livré à T12)
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets(
    'Une échue encore sur la grille est signalée dans la page de gestion',
    (tester) async {
      // La plus récemment échue en premier : `p` échue d'un jour, `r` de trois.
      poser([
        ech('p', const Duration(days: -1), 'presente'),
        Echeance(
          id: 'r',
          description: 'retiree',
          dateEcheance: maintenant.subtract(const Duration(days: 3)),
          retiree: true,
        ),
      ]);
      await ouvrirApplication(tester);
      await ouvrirGestion(tester);

      // Les DEUX sont listées dans le groupe des échues — ⛔ aucun filtre.
      expect(find.text('presente'), findsWidgets);
      expect(find.text('retiree'), findsWidgets);

      expect(
        find.textContaining(LigneEcheance.marqueSurLaGrille),
        findsOneWidget,
        reason: 'celle qui est ENCORE sur la grille occupe une place',
      );
      expect(find.textContaining(LigneEcheance.marqueRetiree), findsOneWidget);

      // Ordonné de la plus récemment échue à la plus ancienne : `presente`
      // (1 jour) avant `retiree` (3 jours). ⛔ Assertion de POSITION, pas de
      // simple présence.
      final yPresente = tester.getCenter(find.text('presente').first).dy;
      final yRetiree = tester.getCenter(find.text('retiree').first).dy;
      expect(yPresente, lessThan(yRetiree));
    },
  );

  testWidgets("Le signalement d'une échue ne repose pas sur la couleur seule", (
    tester,
  ) async {
    poser([
      ech('p', const Duration(days: -1), 'presente'),
      Echeance(
        id: 'r',
        description: 'retiree',
        dateEcheance: maintenant.subtract(const Duration(days: 3)),
        retiree: true,
      ),
    ]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    // ① Le signalement porte un MOT — les deux états en portent un, parce
    // qu'une distinction par ABSENCE serait muette pour la ligne non marquée.
    expect(
      find.textContaining(LigneEcheance.marqueSurLaGrille),
      findsOneWidget,
    );
    expect(find.textContaining(LigneEcheance.marqueRetiree), findsOneWidget);

    // ② Et il est annoncé par le lecteur d'écran PAR CONSTRUCTION : la marque
    // vit dans un `Text` VISIBLE, ⛔ pas dans un tooltip (mesuré en US-01.2 :
    // `Tooltip` renseigne `SemanticsProperties.tooltip`, ⛔ pas le `label`).
    final rendu = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    expect(
      rendu.where(
        (t) => t != null && t.contains(LigneEcheance.marqueSurLaGrille),
      ),
      isNotEmpty,
      reason: 'la marque est un TEXTE PEINT, donc annoncée par construction',
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AC-8 — L'ANIMATION DE DISPARITION
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets(
    'La disparition passe par une animation avant que la tuile ne quitte la grille',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);

      await doubleAppuiSur(tester, 'a');
      await reglerEcritures(tester, jusqua: () => tester.any(enveloppe));

      // ① La tuile est ENCORE présente pendant l'animation.
      expect(enveloppe, findsOneWidget);
      expect(tuile('a'), findsOneWidget);

      // 🔴 ÉTAT INTERMÉDIAIRE — assertions de GRANDEUR, ⛔ pas d'égalité au
      // token : ce sont elles qui tuent un mutant (acquis d'US-01.1).
      await tester.pump(dureeAnim ~/ 2);
      final opacite = tester.widget<FadeTransition>(enveloppe).opacity.value;
      expect(opacite, allOf(greaterThan(0.0), lessThan(1.0)));
      expect(tuile('a'), findsOneWidget, reason: 'toujours là à mi-course');

      // ② Elle quitte la grille À LA FIN de l'animation.
      await tester.pumpAndSettle();
      await purgerLeReconnaisseur(tester);
      expect(tuile('a'), findsNothing);
      expect(enveloppe, findsNothing);
    },
  );

  testWidgets(
    'Le retrait aboutit même quand les animations système sont réduites',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);

      await doubleAppuiSur(tester, 'a');
      await reglerEcritures(tester, jusqua: () => !tester.any(tuile('a')));

      // ① La tuile quitte la grille IMMÉDIATEMENT — ⛔ aucune enveloppe
      // d'animation n'a été montée.
      expect(tuile('a'), findsNothing);
      expect(enveloppe, findsNothing);

      await purgerLeReconnaisseur(tester);
      await tester.pumpAndSettle();

      // ② L'état écrit est EXACTEMENT le même qu'avec l'animation : le mode
      // d'animation ⛔ ne change pas un octet de la donnée.
      expect(persistees(), hasLength(1));
      expect(persistee('a').retiree, isTrue);
    },
  );

  testWidgets(
    "Un second double appui pendant l'animation ne retire rien d'autre",
    (tester) async {
      poser([
        echue('a', 'revue annuelle'),
        Echeance(
          id: 'b',
          description: 'contrôle technique',
          dateEcheance: maintenant.subtract(const Duration(days: 1)),
        ),
      ]);
      await ouvrirApplication(tester);

      final centreAvant = tester.getRect(tuile('a')).center;
      await doubleAppuiSur(tester, 'a');
      await reglerEcritures(tester, jusqua: () => tester.any(enveloppe));
      expect(enveloppe, findsOneWidget, reason: 'l’animation est EN COURS');

      // Je double-appuie de nouveau AU MÊME ENDROIT, pendant l'animation.
      // ⛔ Le geste N'EST PAS réimplémenté ici : il vit en UN SEUL exemplaire
      // dans `test/support/gestes_tuile.dart` (T19), et le recopier ferait
      // dériver EN SILENCE une mécanique subtile — un double appui mal séparé
      // est reçu comme DEUX appuis simples.
      expect(
        tester.getRect(tuile('a')).center,
        centreAvant,
        reason:
            'l’échelle de l’animation joue autour du CENTRE : « au même '
            'endroit » est donc bien la même cible',
      );
      await doubleAppuiSur(tester, 'a');
      await reglerEcritures(tester);
      await purgerLeReconnaisseur(tester);
      await tester.pumpAndSettle();

      // ⛔ AUCUNE autre échéance retirée — lu sur les OCTETS.
      expect(persistee('a').retiree, isTrue);
      expect(
        persistee('b').retiree,
        isFalse,
        reason: 'le second geste ⛔ ne doit pas atteindre la voisine',
      );
      expect(tuile('b'), findsOneWidget);
      // ⛔ Aucune erreur affichée.
      expect(messageAffiche(tester), isNull);
      expect(tester.takeException(), isNull);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-9 / AC-10 — ACCESSIBILITÉ : annonce, focus, cibles tactiles
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets(
    'Une tuile interactive est annoncée actionnable avec son temps restant complet',
    (tester) async {
      poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
      await ouvrirApplication(tester);

      final noeud = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (w) => w.properties.label?.contains('revue annuelle') ?? false,
          );

      expect(noeud.properties.button, isTrue, reason: 'ANNONCÉE ACTIONNABLE');
      expect(noeud.properties.onTap, isNotNull);
      // Son NOM contient le temps, son unité et la description.
      expect(noeud.properties.label, contains('6'));
      expect(noeud.properties.label, contains('heures'));
      expect(noeud.properties.label, contains('revue annuelle'));
      // Et l'action disponible est annoncée — par un `hint` qui dit CE QUE ÇA
      // FAIT, ⛔ jamais comment on le fait.
      expect(noeud.properties.hint, EcheanceTile.hintRevelation);

      await tester.pump(fenetre + grain);
    },
  );

  testWidgets(
    'Les modules grisés et Réglages restent sans gestionnaire de geste',
    (tester) async {
      poser([ech('a', const Duration(hours: 6), 'revue annuelle')]);
      await ouvrirApplication(tester);
      expect(find.byType(HubPage), findsOneWidget);

      for (final module in ['Respiration', 'Concentration']) {
        // ⛔ `findsNothing` sur l'ANCÊTRE INTERACTIF — ⛔ pas un `tap` sans
        // effet, qui passe aussi quand l'écran est mort.
        expect(
          find.ancestor(
            of: find.text(module),
            matching: find.byType(GestureDetector),
          ),
          findsNothing,
        );
        await tester.tap(find.text(module).last, warnIfMissed: false);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(HubPage), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byIcon(Icons.settings),
          matching: find.byType(IconButton),
        ),
        findsNothing,
        reason: '« Réglages » reste NON-INTERACTIF',
      );
    },
  );

  testWidgets('Chaque tuile est atteignable au clavier avec un focus visible', (
    tester,
  ) async {
    // ⛔ La traversée CLAVIER est ce qui allume la mise en évidence, ⛔ pas un
    // appui : `onShowFocusHighlight`, jamais `onFocusChange` (mutant M-p).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    poser([
      for (var i = 0; i < 3; i++)
        ech('t$i', Duration(hours: 6 + i), 'description $i'),
    ]);
    await ouvrirApplication(tester);

    // ⛔ CONTRÔLE POSITIF PRÉALABLE : au repos, aucun anneau nulle part.
    expect(find.byKey(EcheanceTile.cleAnneauExterieur), findsNothing);

    final ordre = <double>[];
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final anneau = find.byKey(EcheanceTile.cleAnneauExterieur);
      expect(
        anneau,
        findsOneWidget,
        reason: 'la tuile focalisée porte un focus VISIBLE, et une seule',
      );
      expect(
        find.byKey(EcheanceTile.cleAnneauInterieur),
        findsOneWidget,
        reason:
            'l’anneau est BICOLORE : un anneau plat serait illisible sur '
            'un dégradé',
      );
      ordre.add(tester.getCenter(anneau).dy);
    }

    // Le focus parcourt les tuiles DANS L'ORDRE DE LA GRILLE.
    expect(ordre.length, 3);
    for (var i = 1; i < ordre.length; i++) {
      expect(
        ordre[i],
        greaterThanOrEqualTo(ordre[i - 1]),
        reason: 'l’ordre du focus suit celui de la grille',
      );
    }

    await tester.pump(fenetre + grain);
  });

  testWidgets(
    'À neuf tuiles chaque cible tactile atteint quarante-huit points',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      poser([
        for (var i = 0; i < ConcentrationTokens.tuilesMax; i++)
          ech('t$i', Duration(hours: 6 + i), 'description $i'),
      ]);
      await ouvrirApplication(tester);

      expect(find.byType(EcheanceTile), findsNWidgets(9));
      for (var i = 0; i < 9; i++) {
        final rect = tester.getRect(tuile('t$i'));
        // ⛔ Assertion de GRANDEUR contre la NORME (SC 2.5.8 / cible tactile),
        // ⛔ pas contre un token qui bougerait avec le produit.
        expect(rect.width, greaterThanOrEqualTo(48.0), reason: 'tuile t$i');
        expect(rect.height, greaterThanOrEqualTo(48.0), reason: 'tuile t$i');
      }
    },
  );

  // ═══════════════════════════════════════════════════════════════════════
  // AC-10 — LE GESTE EST NEUTRE, et le rafraîchissement CONTINUE
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets("Un appui simple ne change ni la couleur ni l'ordre des tuiles", (
    tester,
  ) async {
    poser([
      for (var i = 0; i < 3; i++)
        ech('t$i', Duration(hours: 6 + i), 'description $i'),
    ]);
    await ouvrirApplication(tester);

    // ⛔ Le lecteur de couleur N'EST PAS réécrit ici : `fondDeLaTuile` existe
    // en UN SEUL exemplaire dans `test/support/rendu_couleur.dart` et il PORTE
    // l'assertion d'unicité de NB-7 — un second lecteur en `.first` est
    // exactement le faux vert qui laissait la tuile « toujours orange » avec
    // 112 tests verts.
    Color fond(String id) => fondDeLaTuile(tester, tuile: tuile(id));

    final avantCouleur = fond('t1');
    final avantOrdre = [
      for (var i = 0; i < 3; i++) tester.getCenter(tuile('t$i')).dy,
    ];

    await tester.tap(tuile('t1'));
    await tester.pump();
    expect(
      dansLaTuile('t1', find.text('description 1')),
      findsOneWidget,
      reason: 'CONTRÔLE POSITIF : le geste a bien eu un effet',
    );

    expect(fond('t1'), avantCouleur, reason: 'tout retour d’appui est NEUTRE');
    expect([
      for (var i = 0; i < 3; i++) tester.getCenter(tuile('t$i')).dy,
    ], avantOrdre);

    await tester.pump(fenetre + grain);
  });

  testWidgets('Le rafraîchissement continue après un geste sur une tuile', (
    tester,
  ) async {
    // Une échéance dont le nombre change dans une heure : à 6 h + 1 min, le
    // `ceil` rend 7 ; une heure plus tard il rend 6.
    poser([ech('a', const Duration(hours: 6, minutes: 1), 'revue annuelle')]);
    await ouvrirApplication(tester);
    expect(dansLaTuile('a', find.text('7')), findsOneWidget);

    // ① J'appuie, puis la révélation se TERMINE.
    await tester.tap(tuile('a'));
    await tester.pump();
    expect(dansLaTuile('a', find.text('revue annuelle')), findsOneWidget);
    await tester.pump(fenetre + grain);
    expect(dansLaTuile('a', find.text('7')), findsOneWidget);

    // ② Le temps s'écoule jusqu'au changement de nombre.
    horloge.avancerDe(const Duration(hours: 1));
    await tester.pump(periode + grain);

    // 🔴 Le mutant que ce test tue : un minuteur de rafraîchissement ANNULÉ
    // par le geste — l'écran resterait figé à 7 pour toujours.
    expect(
      dansLaTuile('a', find.text('6')),
      findsOneWidget,
      reason: 'le rafraîchissement CONTINUE après le geste',
    );
    expect(dansLaTuile('a', find.text('7')), findsNothing);
  });

  testWidgets("Retirer la dernière tuile conduit à l'état vide sobre", (
    tester,
  ) async {
    poser([echue('a', 'revue annuelle')]);
    await ouvrirApplication(tester);
    expect(find.byType(EmptyEcheancesPlaceholder), findsNothing);

    await retirer(tester, 'a');

    expect(find.byType(EmptyEcheancesPlaceholder), findsOneWidget);
    expect(find.text(EmptyEcheancesPlaceholder.message), findsOneWidget);
    // ⛔ Ni erreur technique, ni code, ni trace.
    expect(messageAffiche(tester), isNull);
    for (final interdit in ['Exception', 'Error', 'errno', 'échec']) {
      expect(find.textContaining(interdit), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AC-11 — UN RETRAIT DONT L'ÉCRITURE ÉCHOUE (⚖️ ajouté le 2026-08-22)
  //
  // ⛔ AUCUN MAGASIN FACTICE (ADR-010 §1) : l'écriture est rendue RÉELLEMENT
  // impossible en plaçant un RÉPERTOIRE là où le code de production doit
  // écrire son fichier `.tmp`. La `FileSystemException` vient du SYSTÈME DE
  // FICHIERS, et le chemin traversé est EXACTEMENT celui de l'appareil.
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets(
    'Un retrait qui ne peut pas être écrit est annoncé et la tuile reste',
    (tester) async {
      poser([
        echue('a', 'revue annuelle'),
        ech('b', const Duration(hours: 6), 'passeport'),
      ]);
      await ouvrirApplication(tester);
      final avant = harnais.octets();
      final placeAvant = tester.getCenter(tuile('a'));
      harnais.bloquerEcriture();

      await doubleAppuiSur(tester, 'a');
      await reglerEcritures(
        tester,
        jusqua: () => messageAffiche(tester) != null,
        tours: 200,
      );
      await purgerLeReconnaisseur(tester);
      await tester.pumpAndSettle();

      // ① Un message indique que le retrait n'a pas eu lieu. ⛔ Le texte n'est
      // PAS recopié : il vit en un seul exemplaire dans `ActeEcriture`.
      expect(messageAffiche(tester), ActeEcriture.retrait.messageEchec);

      // ② La tuile est TOUJOURS là, À SA PLACE dans le tri.
      expect(tuile('a'), findsOneWidget);
      expect(tester.getCenter(tuile('a')), placeAvant);
      // …et le disque est INCHANGÉ, bit à bit.
      expect(harnais.octets(), avant);

      // ③ ⛔ Aucune trace technique ni code d'erreur.
      for (final interdit in [
        'Exception',
        'FileSystemException',
        'errno',
        'OS Error',
        harnais.fichier.path,
      ]) {
        expect(find.textContaining(interdit), findsNothing);
      }

      // ④ L'application reste UTILISABLE : la voisine répond encore.
      harnais.debloquerEcriture();
      await tester.tap(tuile('b'));
      await tester.pump();
      expect(dansLaTuile('b', find.text('passeport')), findsOneWidget);
      await tester.pump(fenetre + grain);
    },
  );

  testWidgets(
    'Un retrait qui ne peut pas être écrit ne joue aucune animation de disparition',
    (tester) async {
      poser([echue('a', 'revue annuelle')]);
      await ouvrirApplication(tester);
      harnais.bloquerEcriture();

      await doubleAppuiSur(tester, 'a');

      // 🔴 M-e, LE MUTANT LE PLUS LOURD DU LOT : l'ORDRE INVERSE (animation
      // ATTENDUE PUIS écriture) rendrait ce test rouge. On échantillonne
      // TOUTE la durée d'une animation, ⛔ pas seulement la fin.
      for (var i = 0; i < 12; i++) {
        await tester.pump(dureeAnim ~/ 4);
        expect(
          enveloppe,
          findsNothing,
          reason: '⛔ aucune animation de disparition, à AUCUN instant',
        );
        expect(
          tuile('a'),
          findsOneWidget,
          reason: 'la tuile ne quitte à AUCUN moment la grille',
        );
      }

      await reglerEcritures(
        tester,
        jusqua: () => messageAffiche(tester) != null,
        tours: 200,
      );
      await purgerLeReconnaisseur(tester);
      await tester.pumpAndSettle();

      expect(tuile('a'), findsOneWidget);
      expect(enveloppe, findsNothing);
      expect(persistee('a').retiree, isFalse);
    },
  );

  testWidgets(
    'Une échue dont le retrait a échoué compte toujours dans la limite de neuf',
    (tester) async {
      poser([
        for (var i = 0; i < 8; i++) ech('t$i', Duration(hours: 6 + i)),
        echue('z', 'revue annuelle'),
      ]);
      await ouvrirApplication(tester);
      harnais.bloquerEcriture();

      await doubleAppuiSur(tester, 'z');
      await reglerEcritures(
        tester,
        jusqua: () => messageAffiche(tester) != null,
        tours: 200,
      );
      await purgerLeReconnaisseur(tester);
      await tester.pumpAndSettle();
      expect(tuile('z'), findsOneWidget, reason: 'le retrait a ÉCHOUÉ');

      // Je tente de créer une nouvelle échéance : REFUSÉE, parce que l'échue
      // compte TOUJOURS parmi les présentes.
      await ouvrirGestion(tester);
      await tenterCreation(tester);

      expect(find.byType(FormulaireEcheance), findsOneWidget);
      expect(messageAffiche(tester), isNotNull);
      // ASSERTION SUR LES OCTETS : toujours neuf.
      expect(persistees(), hasLength(9));
      expect(presentesSurLaGrille(persistees()), hasLength(9));
    },
  );

  testWidgets('Après un échec de retrait le geste réessayé aboutit', (
    tester,
  ) async {
    poser([echue('a', 'revue annuelle')]);
    await ouvrirApplication(tester);
    harnais.bloquerEcriture();

    await doubleAppuiSur(tester, 'a');
    await reglerEcritures(
      tester,
      jusqua: () => messageAffiche(tester) != null,
      tours: 200,
    );
    await purgerLeReconnaisseur(tester);
    await tester.pumpAndSettle();
    expect(tuile('a'), findsOneWidget, reason: 'le retrait n’a PAS eu lieu');
    expect(persistee('a').retiree, isFalse);

    // Le stockage redevient inscriptible…
    harnais.debloquerEcriture();

    // …et je double-appuie DE NOUVEAU.
    await retirer(tester, 'a');

    expect(
      persistee('a').retiree,
      isTrue,
      reason:
          'les OCTETS d’abord : si CETTE assertion tombe, l’écriture a échoué ; '
          'si c’est la SUIVANTE, l’écran ne suit pas le disque',
    );
    expect(tuile('a'), findsNothing);
    expect(persistees(), hasLength(1));
    expect(
      persistee('a').retiree,
      isTrue,
      reason: 'CONSERVÉE dans le stockage, et retirée de la grille',
    );
    expect(
      messageAffiche(tester),
      isNull,
      reason: 'le message du premier échec est EFFACÉ par la réussite',
    );
  });
}
