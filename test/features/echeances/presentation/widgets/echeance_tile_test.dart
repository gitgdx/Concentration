import 'package:concentration/core/color/temporal_gradient.dart';
import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/features/echeances/domain/remaining_time.dart';
import 'package:concentration/features/echeances/domain/time_unit.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/rendu_couleur.dart';

/// Tests du **rendu** de la tuile (T7).
///
/// ⛔ Ce fichier existe parce que la campagne de mutation de la QA du
/// 2026-08-02 a montré que **trois comportements exigés par des AC** pouvaient
/// être retirés de `echeance_tile.dart` sans qu'aucun des 102 tests ne
/// rougisse : le fond cessant de suivre `temps.progression` (`QA-M1`), le
/// `FittedBox` anti-débordement retiré (`QA-M3`), la description jamais rendue
/// (`QA-M4`). Un AC dont le comportement est supprimable sans rougeur n'est pas
/// *couvert* par un test, il en est seulement *accompagné*.
void main() {
  RemainingTime temps(
    double progression, {
    int nombre = 6,
    bool estEchue = false,
    // ⚠️ Le libellé d'accessibilité PORTE DÉJÀ la description en production
    // (mesuré : `suffixe = ', ${echeance.description}'` dans
    // `remaining_time_calculator.dart`, injecté des deux côtés). Le reproduire
    // ici est ce qui rend les assertions de T8 comparables au réel — ⛔ et il
    // n'est PAS retouché par cette US : P-2 et les mutants X-2 / X-3 en
    // dépendent.
    String suffixeLibelle = '',
  }) => RemainingTime(
    unite: TimeUnit.heures,
    nombreAffiche: nombre,
    progression: progression,
    estEchue: estEchue,
    libelleAccessibilite:
        (estEchue ? 'échéance atteinte' : '$nombre heures') + suffixeLibelle,
  );

  Widget hote(Widget enfant, {double cote = 220}) => MaterialApp(
    theme: ConcentrationTheme.sombre,
    home: Scaffold(
      body: Center(
        child: SizedBox.square(dimension: cote, child: enfant),
      ),
    ),
  );

  Future<Color> fondPour(WidgetTester tester, double progression) async {
    await tester.pumpWidget(
      hote(
        EcheanceTile(
          temps: temps(progression),
          description: 'Rendez-vous',
          // ⛔ Les tests de rendu montent la tuile TELLE QU'ELLE VIT EN
          // PRODUCTION, enveloppe interactive comprise : sans intention, ils
          // n'exerceraient plus l'arbre réel après T8.
          intention: () {},
        ),
      ),
    );
    return fondDeLaTuile(tester);
  }

  // ⛔ CINQ points, jamais un seul. Tant que seul `p = 0` était vérifié sur le
  // rendu, la tuile pouvait ignorer ENTIÈREMENT `temps.progression` : forcée en
  // bleu elle faisait rougir un test, forcée en orange elle n'en faisait rougir
  // AUCUN. Cette asymétrie était le résultat le plus net de la QA — or « la
  // couleur reflète la proximité du prochain changement » EST AC-5.
  const points = <double>[0, 0.25, 0.5, 0.75, 1];

  group('AC-5 — le fond de la tuile est CÂBLÉ sur temps.progression', () {
    testWidgets('chaque progression rend le dégradé À CE POINT', (
      tester,
    ) async {
      const gradient = TemporalGradient();
      for (final p in points) {
        expect(
          await fondPour(tester, p),
          gradient.backgroundFor(p).couleur,
          reason:
              'à p = $p la tuile doit rendre le dégradé EN p, jamais une '
              'couleur figée',
        );
      }
    });

    testWidgets('la clarté DÉCROÎT strictement quand p augmente', (
      tester,
    ) async {
      // Propriété indépendante de l'implémentation du dégradé : quelle que soit
      // la façon dont la couleur est produite, s'approcher du changement doit
      // FAIRE BOUGER le rendu, toujours dans le même sens (ADR-003, « sens non
      // inversé »). Un fond constant échoue ici même s'il est « la bonne
      // couleur » en un point.
      final clartes = [
        for (final p in points) clarteDe(await fondPour(tester, p)),
      ];
      for (var i = 1; i < clartes.length; i++) {
        expect(
          clartes[i],
          lessThan(clartes[i - 1]),
          reason:
              'de p=${points[i - 1]} à p=${points[i]} le rendu doit avancer '
              'vers le bleu — clartés mesurées : $clartes',
        );
      }
    });
  });

  testWidgets(
    'AC-3 « Nominal » — la tuile PORTE la description de son échéance',
    (tester) async {
      // ⚖️ **T13 (2026-08-29) — L'ASSERTION EST BORNÉE, ⛔ PAS RETIRÉE.**
      // Une **`ÉCHUE`** peint toujours sa description sous son « 0 » ; une
      // **`ACTIVE`** porte le **nombre SEUL** et ne la peint plus au repos
      // *(AC-1 « Erreur » d'US-01.4)*. Le motif d'origine de ce test **reste
      // valable** : le corpus ne vérifiait que le cas vide, et la description
      // était supprimable sans rougeur *(mutant `QA-M4`)*.
      await tester.pumpWidget(
        hote(
          EcheanceTile(
            temps: temps(1, estEchue: true),
            description: 'Visite médicale',
            intention: () {},
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(EcheanceTile),
          matching: find.text('Visite médicale'),
        ),
        findsOneWidget,
        reason:
            'une ÉCHUE PEINT sa description : le corpus vérifiait le cas VIDE '
            'et jamais le cas peuplé, et la description était supprimable sans '
            'faire rougir un test',
      );

      // 🔴 **CONTRÔLE APPARIÉ — c'est lui qui porte la BORNE de T13** : la
      // MÊME description, sur une **`ACTIVE`**, ⛔ n'est PAS peinte…
      await tester.pumpWidget(
        hote(
          EcheanceTile(
            // ⛔ Le suffixe n'est PAS décoratif : en production le libellé
            // PORTE la description (`suffixe = ', ${echeance.description}'`,
            // mesuré dans `remaining_time_calculator.dart`). L'omettre ici
            // rendrait l'assertion de canal ci-dessous **inobservable**.
            temps: temps(0.5, suffixeLibelle: ', Visite médicale'),
            description: 'Visite médicale',
            intention: () {},
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(EcheanceTile),
          matching: find.text('Visite médicale'),
        ),
        findsNothing,
        reason:
            'une ACTIVE porte le nombre SEUL (Design UX §4.1), et la '
            'description au repos faisait DÉBORDER la tuile dès ×1,6 à '
            '9 tuiles sur 320 dp — mesuré par T11',
      );
      // …⛔ **et elle n'est pas PERDUE pour autant** : elle reste portée par le
      // libellé d'accessibilité, seul canal qui la rendait utile à une AT.
      // Sans cette moitié, T13 aurait l'air d'un simple retrait.
      expect(
        tester
            .widgetList<Semantics>(
              find.descendant(
                of: find.byType(EcheanceTile),
                matching: find.byType(Semantics),
              ),
            )
            .firstWhere((w) => w.properties.label != null)
            .properties
            .label,
        contains('Visite médicale'),
      );
    },
  );

  testWidgets(
    'AC-3 « Limite » — un nombre trop large est MIS À L’ÉCHELLE, jamais rogné',
    (tester) async {
      // 90 px : la largeur réelle d'une tuile quand 9 tuiles tiennent sur un
      // écran de 320. Le défaut d'origine — le nombre débordait à 9 tuiles — a
      // été trouvé en LANÇANT l'application, jamais par un test ; son correctif
      // (`FittedBox(scaleDown)`) n'était toujours adossé à aucune assertion.
      const cote = 90.0;
      const nombre = 108;
      final texte = '$nombre';

      await tester.pumpWidget(
        hote(
          EcheanceTile(
            temps: temps(0.5, nombre: nombre),
            description: 'Passeport',
            intention: () {},
          ),
          cote: cote,
        ),
      );

      // ⚠️ La largeur naturelle est LUE SUR LE PARAGRAPHE LUI-MÊME, jamais
      // reconstruite à côté : un `TextPainter` monté dans le test rendait
      // 144,75 px là où le paragraphe rendait 144,0 — deux mesures de la « même »
      // grandeur qui divergent, exactement la classe de défaut que ce projet
      // traque. `getMaxIntrinsicWidth` est la largeur que le texte DEMANDE, elle
      // ne dépend pas des contraintes reçues.
      final paragraphe = tester.renderObject<RenderBox>(find.text(texte));
      final naturelle = paragraphe.getMaxIntrinsicWidth(double.infinity);

      // ⛔ Garde-fou : sans lui, ce test cesserait de contrôler EN SILENCE le
      // jour où le nombre choisi tiendrait naturellement dans la tuile.
      expect(
        naturelle,
        greaterThan(cote),
        reason:
            'le cas doit être un VRAI débordement ($naturelle px de nombre '
            'pour $cote px de tuile), sinon il ne prouve rien',
      );

      // 1) La boîte du nombre vaut la largeur qu'il DEMANDE : rien n'est rogné.
      expect(
        paragraphe.size.width,
        closeTo(naturelle, 0.5),
        reason:
            'un nombre posé à une largeur CONTRAINTE est un nombre COUPÉ ; il '
            'doit être posé à sa taille naturelle puis réduit',
      );

      // 2) ...et le résultat PEINT tient entièrement dans la tuile.
      final nombreRect = tester.getRect(find.text(texte));
      final tuileRect = tester.getRect(find.byType(EcheanceTile));
      expect(nombreRect.left, greaterThanOrEqualTo(tuileRect.left - 0.5));
      expect(nombreRect.right, lessThanOrEqualTo(tuileRect.right + 0.5));
      expect(nombreRect.top, greaterThanOrEqualTo(tuileRect.top - 0.5));
      expect(nombreRect.bottom, lessThanOrEqualTo(tuileRect.bottom + 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  // ───────────────────────────────────────────────────────────────────────
  // 🔴 AC-1 d'US-01.4 (T6) — LE NOMBRE : PLUS GROS, CENTRÉ, ⛔ SUR LES
  // `ACTIVE` SEULEMENT.
  //
  // ⛔ TROIS PIÈGES MESURÉS, et chacun a son assertion :
  //   R-7 — `BoxFit.scaleDown` RE-RÉDUIT quand la cellule est petite ⇒ la
  //     taille RENDUE à 9 tuiles peut être IDENTIQUE à celle d'US-01.1 ⇒
  //     l'assertion de grandeur porte sur le `fontSize` du `TextStyle`,
  //     ⛔ JAMAIS sur la taille peinte.
  //   R-8 — le token agrandi sur une ÉCHUE pousserait sa description hors de
  //     la tuile ⇒ contrôle négatif OBLIGATOIRE sur l'échue.
  //   G-7 — `BoxFit.contain` ferait dépendre la taille du glyphe du NOMBRE DE
  //     CHIFFRES ⇒ un test comparant 9 et 10 doit ROUGIR. Celui-là, lui, se
  //     mesure sur la taille PEINTE : c'est la seule qui le voit.
  // ───────────────────────────────────────────────────────────────────────
  group('AC-1 (US-01.4) — le nombre en cadran sur les ACTIVE', () {
    /// Le `fontSize` **du style effectivement porté par le nombre** dans
    /// l'arbre — ⛔ pas la constante du thème relue à côté, qui rendrait
    /// l'assertion tautologique.
    double tailleDuNombre(WidgetTester tester, int nombre) => tester
        .widget<Text>(
          find.descendant(
            of: find.byType(EcheanceTile),
            matching: find.text('$nombre'),
          ),
        )
        .style!
        .fontSize!;

    Future<void> monter(
      WidgetTester tester, {
      required bool estEchue,
      int nombre = 6,
      String description = '',
      double cote = 220,
    }) => tester.pumpWidget(
      hote(
        EcheanceTile(
          temps: temps(0.5, nombre: nombre, estEchue: estEchue),
          description: description,
          intention: () {},
        ),
        cote: cote,
      ),
    );

    testWidgets(
      '🔴 la taille du nombre d’une ACTIVE est STRICTEMENT SUPÉRIEURE à celle '
      'd’une ÉCHUE — la relation, pas le chiffre',
      (tester) async {
        await monter(tester, estEchue: false);
        final active = tailleDuNombre(tester, 6);
        await monter(tester, estEchue: true, nombre: 0);
        final echue = tailleDuNombre(tester, 0);

        expect(
          active,
          greaterThan(echue),
          reason:
              'AC-1 « Nominal » fixe la RELATION (« token dédié strictement '
              'supérieur à celui d’US-01.1 »), et l’échue conserve celui '
              'd’US-01.1 (R-8) — mesuré : active $active, échue $echue',
        );
        // ⛔ Et l’échue garde EXACTEMENT le style d’US-01.1 : le grossissement
        // ⛔ ne fuit pas d’un côté à l’autre par une valeur intermédiaire.
        expect(echue, ConcentrationTheme.tailleNombreEchue);
      },
    );

    testWidgets('🔴 sur une ACTIVE le nombre est centré HORIZONTALEMENT et '
        'VERTICALEMENT — mesuré sur le rendu', (tester) async {
      // ⛔ Sans description : la colonne n’a plus qu’un enfant, donc « centré
      // dans la tuile » devient une grandeur OBSERVABLE. Avec une
      // description, l’`Expanded` ne couvre qu’une partie de la tuile et
      // l’assertion serait fausse pour une raison qui n’est pas le défaut.
      await monter(tester, estEchue: false);
      final nombre = tester.getRect(find.text('6'));
      final tuile = tester.getRect(find.byType(EcheanceTile));

      expect(
        nombre.center.dx,
        closeTo(tuile.center.dx, 0.5),
        reason: 'le rendu d’US-01.1 était en HAUT À GAUCHE',
      );
      expect(nombre.center.dy, closeTo(tuile.center.dy, 0.5));

      // Le localisateur du défaut : les DEUX alignements, un par axe. La
      // grandeur ci-dessus est ce qui PROUVE ; ceci dit OÙ corriger.
      expect(
        tester.widget<FittedBox>(find.byType(FittedBox)).alignment,
        Alignment.center,
      );
      expect(
        tester
            .widget<Column>(
              find.descendant(
                of: find.byType(EcheanceTile),
                matching: find.byType(Column),
              ),
            )
            .crossAxisAlignment,
        CrossAxisAlignment.center,
      );
    });

    testWidgets(
      '🔴 CONTRÔLE NÉGATIF — sur une ÉCHUE le nombre reste en HAUT À GAUCHE '
      '(R-8)',
      (tester) async {
        await monter(tester, estEchue: true, nombre: 0);
        final nombre = tester.getRect(find.text('0'));
        final tuile = tester.getRect(find.byType(EcheanceTile));

        expect(
          nombre.center.dx,
          lessThan(tuile.center.dx),
          reason:
              'centrer une échue pousserait sa description — qu’elle CONSERVE '
              'affichée (verdict clarify nº 1) — hors de la tuile',
        );
        expect(nombre.center.dy, lessThan(tuile.center.dy));
      },
    );

    testWidgets(
      '🔴 la taille PEINTE ne dépend PAS du nombre de chiffres — le mutant '
      'BoxFit.contain',
      (tester) async {
        // 🔴 CE QUE CE TEST TUE, et rien d’autre ne le verrait : `contain`
        // AGRANDIT jusqu’à remplir la boîte ⇒ « 9 » (1 chiffre) deviendrait
        // plus GRAND que « 10 » (2 chiffres), donc au rafraîchissement le
        // chiffre CHANGERAIT DE TAILLE sous les yeux du pratiquant, et 9
        // tuiles porteraient 9 tailles différentes.
        // ⚠️ La cellule est GRANDE exprès : `scaleDown` ne doit PAS entrer en
        // jeu, sinon les deux seraient réduits et le test ne mesurerait rien.
        await monter(tester, estEchue: false, nombre: 9);
        final hauteurNeuf = tester.getRect(find.text('9')).height;
        final largeurNeuf = tester.getRect(find.text('9')).width;
        await monter(tester, estEchue: false, nombre: 10);
        final hauteurDix = tester.getRect(find.text('10')).height;
        final largeurDix = tester.getRect(find.text('10')).width;

        // ⛔ CONTRÔLE POSITIF : les deux nombres portent bien un nombre de
        // chiffres DIFFÉRENT, et cela se VOIT sur la largeur peinte — sans
        // quoi l’égalité des hauteurs serait vraie quoi qu’il arrive.
        expect(
          largeurDix,
          greaterThan(largeurNeuf),
          reason:
              'contrôle positif : deux chiffres occupent plus de largeur '
              'qu’un seul — mesuré : 9 → $largeurNeuf, 10 → $largeurDix',
        );

        expect(
          hauteurDix,
          closeTo(hauteurNeuf, 0.5),
          reason:
              'la taille du glyphe doit venir du TOKEN, jamais du nombre de '
              'chiffres — mesuré : 9 → $hauteurNeuf, 10 → $hauteurDix',
        );
      },
    );
  });
  // ═══════════════════════════════════════════════════════════════════════
  // 🔴 T8 — L'ENVELOPPE INTERACTIVE EST **CONDITIONNELLE** (ADR-014 §A.1).
  //
  // ⛔ POURQUOI LA FORME « HABITUELLE » DE CE CONTRÔLE NE SUFFIT PAS, et
  // c'est MESURÉ : `T-P4` telle qu'ADR-013 §2 la prescrit lit le **widget
  // pointeur** ; or sur la tuile `ACTIVE` **sans description** le défaut J-1
  // est ENTIÈREMENT dans les couches sémantique et focus — la couche pointeur
  // y est **exactement conforme** (`pointeurs = 0`). ⇒ une `T-P4` écrite dans
  // cette forme serait **VERTE SUR LE DÉFAUT**. Pour ce régime, le contrôle
  // asserte donc **l'ABSENCE DU NŒUD** : les SEPT propriétés d'ADR-014 §A.2.
  //
  // ⛔ ET JAMAIS SUR LE NŒUD SÉMANTIQUE POUR LES DEUX AUTRES RÉGIMES : la
  // tuile échue **doit** porter `Semantics(onTap:)` — c'est le canal du
  // clavier et de l'AT — donc une assertion sémantique « l'échue ne porte pas
  // d'action tap » serait **incompatible avec AC-9** (mutant **M-20** : un
  // contrôle qui EXIGE le défaut, vert sur M-19 et rouge sur l'arbre juste).
  // ═══════════════════════════════════════════════════════════════════════
  group('T8 — l’enveloppe interactive, par RÉGIME de tuile', () {
    /// Tous les nœuds sémantiques de l'arbre monté.
    ///
    /// ⚠️ **Piège de mesure payé par la sonde d'ADR-014 §Contexte-4, à ne pas
    /// re-payer** : `isFocusable` ne vit **PAS** sur le nœud du label mais sur
    /// son **ANCÊTRE**, celui de `Focus` — une assertion écrite sur « le nœud
    /// du label » est donc **aveugle à la focusabilité** et **verte à tort**.
    /// ⇒ on lit **l'UNION** des drapeaux et des actions sur **tous** les
    /// nœuds ; l'absence d'apport de l'hôte est **assertée** ci-dessous.
    /// **TOUS** les nœuds sémantiques de la vue — ⛔ pas seulement celui du
    /// label.
    ///
    /// ⚠️ **Piège de mesure payé par la sonde d'ADR-014 §Contexte-4, à ne pas
    /// re-payer** : `isFocusable` ne vit **PAS** sur le nœud du label mais sur
    /// son **ANCÊTRE**, celui de `Focus` — une assertion écrite sur « le nœud
    /// du label » est donc **aveugle à la focusabilité**, et elle serait
    /// **verte à tort**. ⇒ on lit **l'UNION** des drapeaux et des actions sur
    /// **tous** les nœuds ; l'absence d'apport de l'hôte est **assertée**
    /// ci-dessous, sans quoi cette union ne serait pas attribuable à la tuile.
    Iterable<SemanticsNode> tousLesNoeuds() =>
        find.semantics.byPredicate((_) => true).evaluate();

    Set<String> actionsDeLArbre() => {
      for (final n in tousLesNoeuds())
        for (final a in SemanticsAction.values)
          if (n.getSemanticsData().hasAction(a)) a.name,
    };

    int boutonsDeLArbre() =>
        find.semantics.byFlag(SemanticsFlag.isButton).evaluate().length;

    int focusablesDeLArbre() =>
        find.semantics.byFlag(SemanticsFlag.isFocusable).evaluate().length;

    /// Les gestionnaires **POINTEUR** réellement branchés sous la tuile.
    /// ⛔ La sélection ne désigne aucun widget par sa POSITION (`.first`,
    /// `.at(n)`) : c'est la sélection par position qui a produit **NB-7**.
    List<GestureDetector> pointeursDeLaTuile(WidgetTester tester) => tester
        .widgetList<GestureDetector>(
          find.descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(GestureDetector),
          ),
        )
        .where(
          (g) =>
              g.onTap != null || g.onDoubleTap != null || g.onLongPress != null,
        )
        .toList(growable: false);

    int widgetsFocusDeLaTuile(WidgetTester tester) => tester
        .widgetList(
          find.descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(Focus),
          ),
        )
        .length;

    /// Le focus primaire est-il **DANS** la tuile après une tabulation ?
    /// C'est le mot littéral d'AC-9 — « atteignable au clavier » — et il lit
    /// un **parcours réellement effectué**, ⛔ pas un drapeau déclaré.
    Future<bool> tabulationAtteintLaTuile(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ctx = FocusManager.instance.primaryFocus?.context;
      return ctx != null &&
          ctx.findAncestorWidgetOfExactType<EcheanceTile>() != null;
    }

    Future<void> monterTuile(
      WidgetTester tester, {
      required bool estEchue,
      required String description,
      VoidCallback? intention,
    }) => tester.pumpWidget(
      hote(
        EcheanceTile(
          temps: temps(
            0.5,
            nombre: estEchue ? 0 : 6,
            estEchue: estEchue,
            suffixeLibelle: description.isEmpty ? '' : ', $description',
          ),
          description: description,
          intention: intention,
        ),
      ),
    );

    testWidgets(
      '⛔ CONTRÔLE POSITIF DE L’INSTRUMENT — l’hôte SEUL n’apporte ni action, '
      'ni bouton, ni focusable',
      (tester) async {
        // Sans cette mesure, « l’ensemble des actions du sous-arbre est vide »
        // pourrait être vrai POUR UNE AUTRE RAISON que l’absence d’enveloppe,
        // et les sept assertions seraient vertes sans rien observer.
        final poignee = tester.ensureSemantics();
        await tester.pumpWidget(hote(const SizedBox()));

        expect(actionsDeLArbre(), isEmpty);
        expect(boutonsDeLArbre(), 0);
        expect(focusablesDeLArbre(), 0);
        poignee.dispose();
      },
    );

    testWidgets(
      '🔴 T-P4 « ACTIVE avec description » — `onTap` SEUL sur la couche '
      'pointeur, et le nœud est annoncé BOUTON',
      (tester) async {
        final poignee = tester.ensureSemantics();
        await monterTuile(
          tester,
          estEchue: false,
          description: 'revue annuelle',
          intention: () {},
        );

        final pointeurs = pointeursDeLaTuile(tester);
        expect(pointeurs, hasLength(1));
        expect(pointeurs.single.onTap, isNotNull);
        // 🔴 LE MUTANT M-8, et rien d’autre ne le verrait : `onDoubleTap` en
        // plus imposerait `kDoubleTapTimeout` (300 ms) à la révélation et
        // ferait CLIGNOTER le 1ᵉʳ appui — ⛔ aucun scénario fonctionnel ne
        // rougirait, « la révélation marcherait, juste 300 ms plus tard ».
        expect(
          pointeurs.single.onDoubleTap,
          isNull,
          reason: 'M-8 : une ACTIVE ne porte JAMAIS onDoubleTap',
        );

        // Pendant sémantique — SÉPARÉ et POSITIF (ADR-014 §A.2).
        final noeud = tester.getSemantics(
          find.bySemanticsLabel('6 heures, revue annuelle'),
        );
        expect(noeud.hint, EcheanceTile.hintRevelation);
        expect(actionsDeLArbre(), contains(SemanticsAction.tap.name));
        expect(boutonsDeLArbre(), 1);
        poignee.dispose();
      },
    );

    testWidgets(
      '🔴 T-P4 « ÉCHUE » — `onDoubleTap` SEUL sur la couche pointeur, ET le '
      'nœud porte `tap` (sans quoi AC-9 tombe)',
      (tester) async {
        final poignee = tester.ensureSemantics();
        await monterTuile(
          tester,
          estEchue: true,
          description: 'revue annuelle',
          intention: () {},
        );

        final pointeurs = pointeursDeLaTuile(tester);
        expect(pointeurs, hasLength(1));
        expect(pointeurs.single.onDoubleTap, isNotNull);
        expect(
          pointeurs.single.onTap,
          isNull,
          reason:
              'un appui simple retirerait la tuile, contre l’arbitrage '
              'clarify nº 1',
        );

        // 🔴 M-19 — LE DÉFAUT LE PLUS SILENCIEUX DE CETTE US : une échue qui
        // ne porterait QUE `onDoubleTap` rend `tap=false focusable=true`,
        // clavier ET AT inopérants, ⛔ SANS lever aucune erreur. AC-9 tombe
        // entièrement et ⛔ aucun scénario au pointeur ne rougit.
        expect(actionsDeLArbre(), contains(SemanticsAction.tap.name));
        expect(boutonsDeLArbre(), 1);
        expect(focusablesDeLArbre(), 1);
        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel('échéance atteinte, revue annuelle'),
              )
              .hint,
          EcheanceTile.hintRetrait,
        );
        poignee.dispose();
      },
    );
    testWidgets(
      '🔴 SEPT ASSERTIONS — la tuile « ACTIVE SANS description » n’a AUCUNE '
      'enveloppe : le contrôle porte sur l’ABSENCE DU NŒUD (J-1)',
      (tester) async {
        final poignee = tester.ensureSemantics();
        // ⚠️ L’intention est FOURNIE : sans elle, les sept assertions
        // seraient vertes POUR LA MAUVAISE RAISON — « pas d’enveloppe faute
        // de rappel » au lieu de « pas d’enveloppe faute de description ».
        await monterTuile(
          tester,
          estEchue: false,
          description: '',
          intention: () {},
        );

        // 1 — aucun gestionnaire POINTEUR (la forme d’ADR-013 §2, conservée :
        //     c’est elle qui tue le `onTap` VIDE, mutant M-15).
        expect(pointeursDeLaTuile(tester), isEmpty);
        // 2 — l’ensemble des actions sémantiques est VIDE. ⛔ Pas
        //     `onTap == null` : un nœud de `Focus` publie à lui seul l’action
        //     `focus`, ce qui rend cette assertion PLUS forte que prévu.
        expect(actionsDeLArbre(), isEmpty);
        // 3 — aucun nœud ne porte `isButton`.
        expect(boutonsDeLArbre(), 0);
        // 4 — aucun nœud n’est focusable, LU SUR L’ARBRE et non sur le label.
        expect(focusablesDeLArbre(), 0);
        // 5 — aucun widget `Focus` sous la tuile.
        expect(widgetsFocusDeLaTuile(tester), 0);
        // 6 — une tabulation laisse le focus primaire HORS de la tuile.
        expect(await tabulationAtteintLaTuile(tester), isFalse);
        // 7 — ✅ CONTRÔLE : le label est PRÉSENT, UNIQUE et ÉGAL au libellé
        //     d’accessibilité. ⛔ Sans lui, « tout retirer » passerait — et
        //     la tuile deviendrait invisible aux lecteurs d’écran, défaut
        //     PIRE que celui qu’on corrige.
        expect(find.bySemanticsLabel('6 heures'), findsOneWidget);
        poignee.dispose();
      },
    );

    testWidgets(
      '🔴 CONTRÔLE NÉGATIF DES SEPT — la MÊME tuile, la MÊME intention, une '
      'description en plus : les sept basculent',
      (tester) async {
        // ⛔ Sans ce test, les sept assertions ci-dessus pourraient être
        // vertes sur un arbre où l’enveloppe n’existe POUR PERSONNE : elles
        // mesureraient l’absence de widget, pas la CONDITION.
        final poignee = tester.ensureSemantics();
        await monterTuile(
          tester,
          estEchue: false,
          description: 'revue annuelle',
          intention: () {},
        );

        expect(pointeursDeLaTuile(tester), hasLength(1));
        expect(actionsDeLArbre(), isNotEmpty);
        expect(boutonsDeLArbre(), 1);
        expect(focusablesDeLArbre(), 1);
        expect(widgetsFocusDeLaTuile(tester), 1);
        expect(await tabulationAtteintLaTuile(tester), isTrue);
        expect(
          find.bySemanticsLabel('6 heures, revue annuelle'),
          findsOneWidget,
        );
        poignee.dispose();
      },
    );

    testWidgets(
      '🔴 UNE intention, QUATRE canaux — pointeur, `Entrée`, `Espace`, action '
      '`tap` d’une AT (ADR-013 §3, mesuré)',
      (tester) async {
        final poignee = tester.ensureSemantics();
        var invocations = 0;
        await monterTuile(
          tester,
          estEchue: true,
          description: 'revue annuelle',
          intention: () => invocations++,
        );
        final tuile = find.byType(EcheanceTile);
        final centre = tester.getRect(tuile).center;

        // ⓪ Un appui SIMPLE sur une échue ⇒ RIEN (clause héritée d’US-01.2).
        await tester.tap(tuile);
        await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
        expect(invocations, 0, reason: 'un appui simple ne retire pas');

        // ① pointeur : DEUX appuis
        await tester.tapAt(centre);
        await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 10));
        await tester.tapAt(centre);
        await tester.pump();
        expect(invocations, 1);

        // ② clavier `Entrée` — après tabulation, donc le focus est ATTEINT
        expect(await tabulationAtteintLaTuile(tester), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(invocations, 2, reason: 'ActivateIntent');

        // ③ clavier `Espace`
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(invocations, 3, reason: 'ButtonActivateIntent');

        // ④ AT : l’action sémantique `tap`, sur le SEUL nœud annoncé
        tester.semantics.tap(
          find.semantics.byLabel('échéance atteinte, revue annuelle'),
        );
        await tester.pump();
        expect(invocations, 4, reason: 'canal de l’AT');

        // ⛔ UN SEUL nœud annoncé — `excludeFromSemantics: true` sur le
        // détecteur intérieur, ⛔ jamais deux.
        expect(
          find.bySemanticsLabel('échéance atteinte, revue annuelle'),
          findsOneWidget,
        );

        // ⚠️ Le reconnaisseur de double appui garde un minuteur de
        // `kDoubleTapTimeout` en attente : sans cette avance, le test échoue
        // sur `!timersPending` au démontage — et ⛔ ce n'est PAS un défaut du
        // produit, c'est la mécanique du reconnaisseur.
        await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
        poignee.dispose();
      },
    );

    testWidgets(
      '🔴 M-8 (l’autre face) — deux appuis RAPPROCHÉS sur une ACTIVE donnent '
      'DEUX révélations immédiates, ⛔ aucun `kDoubleTapTimeout`',
      (tester) async {
        var invocations = 0;
        await monterTuile(
          tester,
          estEchue: false,
          description: 'revue annuelle',
          intention: () => invocations++,
        );
        final centre = tester.getRect(find.byType(EcheanceTile)).center;

        await tester.tapAt(centre);
        await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 10));
        await tester.tapAt(centre);
        await tester.pump();

        // ⛔ C’est ici que M-8 meurt par le COMPORTEMENT et non par la
        // structure : avec `onDoubleTap` en plus, le 1ᵉʳ appui attendrait
        // 300 ms et cette mesure rendrait 1, jamais 2.
        expect(
          invocations,
          2,
          reason: 'SONDE-6b : deux appuis rapprochés ⇒ deux révélations',
        );
      },
    );

    testWidgets(
      '🔴 la surface du geste est la tuile PEINTE — un appui sur une zone '
      'VIDE agit (le détecteur n’entoure pas que le nombre)',
      (tester) async {
        var invocations = 0;
        await monterTuile(
          tester,
          estEchue: false,
          description: 'revue annuelle',
          intention: () => invocations++,
        );
        final tuile = tester.getRect(find.byType(EcheanceTile));

        // Deux points HORS du nombre et hors de la description : le bord
        // gauche à mi-hauteur (dans la marge de 16) et le bas de la boîte.
        // ⚠️ MESURÉ : la surface sensible est la tuile **PEINTE**
        // (`BoxDecoration.hitTest`), donc les quatre ergots hors du rayon de
        // 16 ne réagissent pas — ⛔ ce qui est le comportement VOULU : ces
        // pixels n’appartiennent pas à la tuile mais à la gouttière.
        await tester.tapAt(Offset(tuile.left + 2, tuile.center.dy));
        await tester.pump();
        expect(
          invocations,
          1,
          reason: 'le bord de la tuile fait partie de la cible',
        );
        await tester.tapAt(Offset(tuile.left + 20, tuile.bottom - 2));
        await tester.pump();
        expect(invocations, 2);
      },
    );

    testWidgets(
      '🔴 M-13, garde de NON-RETOUR — aucun `InkWell` sous la tuile, donc '
      'aucune ondulation ne peut encoder l’interaction (RF-04)',
      (tester) async {
        await monterTuile(
          tester,
          estEchue: true,
          description: 'revue annuelle',
          intention: () {},
        );
        // ⛔ Le risque R-11 a disparu STRUCTURELLEMENT : `InkWell` lie
        // l’activation clavier à `onTap` — interdit sur une échue — et son
        // `splashColor` ferait ENCODER L’INTERACTION PAR LA COULEUR.
        expect(
          find.descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(EcheanceTile),
            matching: find.byType(InkResponse),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '🔴 M-17 — le geste MARCHE et la tuile est ANNONCÉE : les deux dans le '
      'même test, sinon le défaut passe',
      (tester) async {
        final poignee = tester.ensureSemantics();
        var invocations = 0;
        await monterTuile(
          tester,
          estEchue: false,
          description: 'revue annuelle',
          intention: () => invocations++,
        );

        // `ExcludeSemantics` supprime la sémantique de TOUS ses descendants :
        // placer l’annonce DEDANS rendrait la tuile fonctionnelle et NON
        // ANNONCÉE — le geste marcherait, AC-9 tomberait, et ⛔ rien d’autre
        // ne le verrait. L’assertion de geste SEULE serait donc verte.
        await tester.tap(find.byType(EcheanceTile));
        await tester.pump();
        expect(invocations, 1);
        expect(
          find.bySemanticsLabel('6 heures, revue annuelle'),
          findsOneWidget,
        );
        expect(boutonsDeLArbre(), 1);
        poignee.dispose();
      },
    );

    test('🔴 les deux `hint` sont DISTINCTS, non vides, et ⛔ aucun ne nomme le '
        'geste POINTEUR', () {
      // ⛔ Un `hint` dit CE QUE ÇA FAIT, jamais COMMENT ON LE FAIT : il
      // n’existe AUCUNE action sémantique de double appui, donc « double
      // appui pour retirer » serait FAUX pour celui qui l’entend — une AT
      // active par sa propre convention, en UNE fois (ADR-013 §3).
      expect(EcheanceTile.hintRevelation, isNotEmpty);
      expect(EcheanceTile.hintRetrait, isNotEmpty);
      expect(
        EcheanceTile.hintRetrait,
        isNot(EcheanceTile.hintRevelation),
        reason: 'deux hints identiques annonceraient le mauvais effet',
      );
      for (final hint in [
        EcheanceTile.hintRevelation,
        EcheanceTile.hintRetrait,
      ]) {
        expect(
          hint.toLowerCase(),
          allOf(
            isNot(contains('appui')),
            isNot(contains('tap')),
            isNot(contains('clic')),
            isNot(contains('seconde')),
          ),
          reason: 'ni le GESTE ni la DURÉE ne s’écrivent dans un hint',
        );
      }
    });
  });
  // ═══════════════════════════════════════════════════════════════════════
  // 🔴 T9 — LE RENDU DE LA RÉVÉLATION : même endroit, même boîte, ⛔ le
  // nombre est ABSENT (AC-2, Design UX §3.2 et §7.2).
  // ═══════════════════════════════════════════════════════════════════════
  group('T9 — la description révélée', () {
    Future<void> monter(
      WidgetTester tester, {
      required bool revele,
      bool estEchue = false,
      String description = 'revue annuelle',
      double cote = 220,
      double echelle = 1,
    }) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
        child: hote(
          EcheanceTile(
            temps: temps(
              0.5,
              nombre: estEchue ? 0 : 6,
              estEchue: estEchue,
              suffixeLibelle: description.isEmpty ? '' : ', $description',
            ),
            description: description,
            revele: revele,
            intention: () {},
          ),
          cote: cote,
        ),
      ),
    );

    double tailleDe(WidgetTester tester, String texte) =>
        tester.widget<Text>(find.text(texte)).style!.fontSize!;

    testWidgets(
      '🔴 révélée — le nombre est ABSENT et la description occupe SA boîte, '
      'centrée sur les DEUX axes',
      (tester) async {
        // ⚖️ **T13 — L'ANCRE CHANGE, ET ELLE DEVIENT PLUS DIRECTE.** Ce test
        // comparait la position révélée à celle de la description **AU REPOS**,
        // qui n'existe plus sur une `ACTIVE`. La propriété à prouver est
        // *« la description prend LA PLACE DU NOMBRE »* : on mesure donc
        // contre **le nombre**, ⛔ pas contre un rendu disparu.
        await monter(tester, revele: false);
        expect(find.text('6'), findsOneWidget);
        final boiteDuNombre = tester.getRect(find.text('6')).center;
        expect(
          find.text('revue annuelle'),
          findsNothing,
          reason: 'au repos, une ACTIVE porte le nombre SEUL (T13)',
        );

        await monter(tester, revele: true);
        expect(
          find.text('6'),
          findsNothing,
          reason: 'la description prend LA PLACE du nombre (§3.2)',
        );
        // ⛔ Et elle n'est rendue qu'UNE fois : la description de repos ne
        // reste pas en bas pendant que la révélation est affichée.
        expect(find.text('revue annuelle'), findsOneWidget);

        final revelee = tester.getRect(find.text('revue annuelle')).center;
        final tuile = tester.getRect(find.byType(EcheanceTile));
        expect(revelee.dx, closeTo(tuile.center.dx, 1));
        expect(revelee.dy, closeTo(tuile.center.dy, 1));
        // Assertion de GRANDEUR — c'est elle qui prouve que la description
        // occupe **la boîte du nombre**, et ⛔ pas une place à elle.
        expect(
          (revelee.dy - boiteDuNombre.dy).abs(),
          lessThan(1),
          reason:
              'mesuré : révélée $revelee, nombre au repos $boiteDuNombre — '
              'MÊME boîte, ⛔ pas la ligne du bas',
        );
      },
    );

    testWidgets(
      '⛔ la description révélée n’est PAS bornée à `maxLines: 2` — c’est la '
      'valeur du rendu DE REPOS d’US-01.1',
      (tester) async {
        // ⚖️ **T13 — LE CONTRÔLE POSITIF DÉMÉNAGE SUR L'`ÉCHUE`**, seul rendu
        // DE REPOS qui peigne encore une description. ⛔ Il n'est pas
        // supprimé : sans lui, « la révélation n'est pas bornée » serait vrai
        // même si PLUS RIEN n'était borné nulle part.
        await tester.pumpWidget(
          hote(
            EcheanceTile(
              temps: temps(1, estEchue: true),
              description: 'revue annuelle',
              intention: () {},
            ),
          ),
        );
        expect(
          tester.widget<Text>(find.text('revue annuelle')).maxLines,
          2,
          reason: 'contrôle positif : le rendu de repos d’une ÉCHUE borne à 2',
        );

        await monter(tester, revele: true);
        expect(
          tester.widget<Text>(find.text('revue annuelle')).maxLines,
          isNot(2),
          reason: 'la révélation occupe TOUTE la boîte de contenu (§3.2)',
        );
      },
    );

    testWidgets(
      '⛔ AUCUNE animation sur la révélation — le verdict clarify nº 1 a été '
      'pris POUR L’IMMÉDIATETÉ',
      (tester) async {
        await monter(tester, revele: true);
        for (final animation in [
          find.byType(AnimatedSwitcher),
          find.byType(FadeTransition),
          find.byType(AnimatedOpacity),
          find.byType(AnimatedCrossFade),
        ]) {
          expect(
            find.descendant(of: find.byType(EcheanceTile), matching: animation),
            findsNothing,
            reason: 'une transition rendrait la révélation DIFFÉRÉE',
          );
        }
      },
    );

    testWidgets(
      '🔴 §7.2 — la description révélée se RÉDUIT jusqu’au PLANCHER, jamais '
      'en dessous, puis ELLIPSE',
      (tester) async {
        const longue =
            'préparation du projet de rénovation complète de la maison de '
            'famille avant la fin de la garantie décennale';

        // Une grande tuile : le texte tient à la taille de design.
        await monter(tester, revele: true, cote: 400);
        final grande = tailleDe(tester, 'revue annuelle');
        expect(grande, ConcentrationTheme.styleDescription.fontSize);

        // Une petite tuile avec un texte long : on descend AU PLANCHER, et on
        // s'y arrête — ⛔ jamais en dessous, sinon le réglage d'échelle de
        // l'utilisateur serait annulé par le produit (SC 1.4.4).
        await monter(tester, revele: true, description: longue, cote: 120);
        final petite = tailleDe(tester, longue);
        expect(petite, ConcentrationTokens.plancherDescriptionRevelee);
        // La RELATION, pas les chiffres : le plancher est strictement plus
        // petit que la taille de design, sinon « réduire » n'aurait aucun sens.
        expect(petite, lessThan(grande));
        // …et le texte est ELLIPSÉ, borné par les lignes qui TIENNENT.
        final rendu = tester.widget<Text>(find.text(longue));
        expect(rendu.overflow, TextOverflow.ellipsis);
        expect(rendu.maxLines, isNotNull);
        expect(rendu.maxLines, greaterThanOrEqualTo(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '🔴 SC 1.4.4 — la réduction porte sur la taille de DESIGN, ⛔ JAMAIS sur '
      'le facteur d’échelle : à ×2,0 le texte rendu DOUBLE',
      (tester) async {
        // ⚠️ La tuile est GRANDE exprès : aux deux échelles la taille de
        // design retenue est la MÊME, sinon la comparaison mesurerait la
        // réduction et non l'échelle.
        await monter(tester, revele: true, cote: 400);
        final hauteurX1 = tester.getRect(find.text('revue annuelle')).height;
        final tailleX1 = tailleDe(tester, 'revue annuelle');

        await monter(tester, revele: true, cote: 400, echelle: 2);
        final hauteurX2 = tester.getRect(find.text('revue annuelle')).height;

        expect(
          tailleDe(tester, 'revue annuelle'),
          tailleX1,
          reason: 'même taille de DESIGN aux deux échelles',
        );
        expect(
          hauteurX2,
          greaterThan(hauteurX1 * 1.9),
          reason:
              'le texte PEINT doit suivre le réglage système — mesuré : '
              '×1,0 → $hauteurX1, ×2,0 → $hauteurX2',
        );
      },
    );

    testWidgets(
      '🔴 la MESURE prend l’échelle de l’utilisateur en compte — sinon la '
      'réduction se décide sur un texte qui n’est PAS celui qui sera peint',
      (tester) async {
        // 🔴 CE TEST EXISTE PARCE QU’UN MUTANT A SURVÉCU : neutraliser
        // l’échelle DANS LE MESUREUR (`TextScaler.noScaling`) ne faisait
        // rougir AUCUN test, alors que le défaut est réel — la taille de
        // design serait choisie sur un texte deux fois plus petit que le
        // texte rendu, donc conservée à 13 là où elle doit descendre.
        // ⚠️ Le cas doit être une PETITE tuile : dans une grande, les deux
        // échelles retiennent la MÊME taille et le mutant est invisible.
        await monter(tester, revele: true, cote: 90);
        final aX1 = tailleDe(tester, 'revue annuelle');
        expect(
          aX1,
          ConcentrationTheme.styleDescription.fontSize,
          reason:
              'contrôle : à ×1,0 le texte TIENT dans cette tuile, donc la '
              'taille de design est CONSERVÉE — sans quoi le test ci-dessous '
              'serait vrai pour la mauvaise raison',
        );

        await monter(tester, revele: true, cote: 90, echelle: 2);
        expect(
          tailleDe(tester, 'revue annuelle'),
          ConcentrationTokens.plancherDescriptionRevelee,
          reason:
              'à ×2,0 le même texte NE TIENT PLUS : la réduction doit se '
              'déclencher, et elle ne peut le faire que si la mesure connaît '
              'l’échelle',
        );
      },
    );

    testWidgets(
      '🔴 CONTRÔLE NÉGATIF — `revele: true` ne change RIEN sur une ÉCHUE ni '
      'sur une ACTIVE SANS description',
      (tester) async {
        // Une échue affiche déjà sa description EN PERMANENCE (verdict
        // clarify nº 1) : son « 0 » ne disparaît pas.
        await monter(tester, revele: true, estEchue: true);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('revue annuelle'), findsOneWidget);

        // Une tuile sans description n'a RIEN à révéler (AC-3) : ⛔ aucun
        // texte inventé, aucun tiret, aucune date.
        await monter(tester, revele: true, description: '');
        expect(find.text('6'), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      },
    );
  });
}
