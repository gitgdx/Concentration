import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_repository.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/gestion_echeances_page.dart';
import 'package:concentration/features/echeances/presentation/widgets/message_ecriture.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/gestes_tuile.dart';
import '../../../support/magasin_temporaire.dart';

/// **T19 — LA SURFACE DU MESSAGE D'ÉCHEC SUR LE HUB** *(AC-11, `U-2`,
/// ADR-014 §B)*.
///
/// 🔴 **Cette tâche a été AJOUTÉE le 2026-08-24 parce qu'elle MANQUAIT** : T4
/// avait ancré le refus **typé** du port et T10 avait garanti *« ⛔ aucune
/// animation quand l'écriture échoue »*, mais ⛔ **RIEN NE S'AFFICHAIT** — le
/// hub n'avait **aucune** surface de message *(mesuré : `MessageValidation`
/// n'était monté que par la page de gestion)*. AC-11 « Nominal » aurait été
/// livré **à moitié**, et ⛔ **cela ne devait pas se découvrir au `/certify`**.
///
/// ⛔ **Aucun magasin factice** *(ADR-010 §1)* : l'échec d'écriture est une
/// `FileSystemException` **réelle**, provoquée par un **répertoire** portant le
/// nom du fichier temporaire de l'écriture atomique.
void main() {
  final maintenant = DateTime(2026, 8, 28, 12);
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  Echeance echeance(String id, String description, Duration dans) => Echeance(
    id: id,
    description: description,
    dateEcheance: maintenant.add(dans),
  );

  /// Une **échue** *(retirable)* et deux **actives**.
  List<Echeance> leJeu() => [
    echeance('e1', 'Echue a retirer', const Duration(days: -3)),
    echeance('a1', 'Active une', const Duration(days: 10)),
    echeance('a2', 'Active deux', const Duration(days: 20)),
  ];

  Finder tuile(String id) => find.byKey(ValueKey(id));
  final zone = find.byKey(HubPage.cleZoneMessage);

  /// La zone est montée **en permanence** : ce qui se teste est donc sa
  /// **visibilité**, ⛔ jamais la présence de son type.
  bool messageVisible(WidgetTester tester) =>
      tester.widget<Visibility>(zone).visible;

  String texteDuMessage(WidgetTester tester) =>
      tester.widget<MessageEcriture>(find.byType(MessageEcriture)).texte;

  /// **Ce qui est INERTE.** 🔴 **MESURÉ par sonde jetable, et mes DEUX premières
  /// versions étaient fausses** *(elles cherchaient un `Opacity`)* :
  /// `Visibility(maintainSize: true)` insère
  /// `_VisibilityScope > _Visibility > IgnorePointer > ExcludeFocus`, et
  /// ⛔ **AUCUN `Opacity`, dans AUCUN des deux états**.
  ///
  /// **Ce qui bascule réellement, mesuré dans les deux sens** :
  /// `ignoring` **true→false**, `excluding` **true→false**, label sémantique
  /// **0→1** — et ⛔ **`find.textContaining('⚠')` rend 1 DANS LES DEUX CAS**,
  /// donc **un finder ne distingue rien du tout**.
  bool zoneInerte(WidgetTester tester) => tester
      .widget<IgnorePointer>(
        find.descendant(of: zone, matching: find.byType(IgnorePointer)),
      )
      .ignoring;

  /// **Ce qui est ANNONCÉ.** `Visibility(visible: false)` pose un
  /// `ExcludeSemantics` : le message réservé ⛔ ne doit pas être lu.
  bool annonceDuMessage(WidgetTester tester) =>
      find.bySemanticsLabel(RegExp('⚠')).evaluate().isNotEmpty;

  Color couleurDuMessage(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: zone, matching: find.byType(Text)))
      .style!
      .color!;

  Future<EcheancesNotifier> monter(WidgetTester tester) async {
    final notifier = await notifierCharge(
      tester,
      harnais,
      leJeu(),
      clock: FakeClock(maintenant),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: HubPage(notifier: notifier, clock: FakeClock(maintenant)),
      ),
    );
    await tester.pump();
    return notifier;
  }

  /// Le retrait de l'échue, **écriture réglée** : le geste seul ne suffit pas
  /// *(fait mesuré et documenté par `reglerEcritures`)*.
  Future<void> retirerLEchue(WidgetTester tester) async {
    await doubleAppui(tester, tuile('e1'));
    await reglerEcritures(tester);
    await purgerLeReconnaisseur(tester);
  }

  group('T19 — le message d\'échec du retrait, sur le hub', () {
    testWidgets(
      '🔴 CONTRÔLE POSITIF — sans message, la zone est MONTÉE, NON PEINTE et '
      'NON ANNONCÉE (sans lui, « il n\'y a pas de message » ne serait même pas '
      'dicible)',
      (tester) async {
        final semantique = tester.ensureSemantics();
        await monter(tester);

        // ⛔ La zone EXISTE, et son texte AUSSI : une assertion écrite sur le
        // TYPE — ou sur `find.textContaining('⚠')` — serait donc VRAIE sans
        // aucun message.
        // 🔴 FAIT MESURÉ, ET MA PREMIÈRE ASSERTION ÉTAIT FAUSSE POUR CETTE
        // RAISON : `maintainState: true` GARDE l'enfant dans l'arbre (c'est
        // ce qui réserve la hauteur), donc `find.textContaining('⚠')` rend
        // **1 widget** ici. ⇒ **un finder mesure l'ARBRE, jamais la
        // PEINTURE.**
        expect(zone, findsOneWidget);
        expect(find.byType(MessageEcriture), findsOneWidget);
        expect(find.textContaining('⚠'), findsOneWidget);

        // ✅ Les TROIS propriétés qui distinguent réellement les deux états :
        // le drapeau, la peinture, et l'annonce.
        expect(messageVisible(tester), isFalse);
        expect(zoneInerte(tester), isTrue);
        expect(
          annonceDuMessage(tester),
          isFalse,
          reason:
              '`Visibility(visible: false)` pose un `ExcludeSemantics` : un '
              'message réservé mais absent ⛔ ne doit pas être lu par un '
              'lecteur d\'écran.',
        );
        semantique.dispose();
      },
    );

    testWidgets(
      '✅ CONTRÔLE APPARIÉ — quand il y a un message, les trois propriétés '
      'BASCULENT (sinon les assertions ci-dessus seraient vraies TOUJOURS)',
      (tester) async {
        final semantique = tester.ensureSemantics();
        await monter(tester);
        harnais.bloquerEcriture();
        await retirerLEchue(tester);

        expect(messageVisible(tester), isTrue);
        expect(zoneInerte(tester), isFalse);
        expect(annonceDuMessage(tester), isTrue);
        semantique.dispose();
      },
    );

    testWidgets(
      '🔴 AC-11 « Nominal » — l\'écriture ÉCHOUE : le message S\'AFFICHE, avec '
      'le texte DU PORT, et la tuile RESTE',
      (tester) async {
        await monter(tester);
        expect(messageVisible(tester), isFalse); // contrôle positif préalable

        harnais.bloquerEcriture();
        await retirerLEchue(tester);

        expect(messageVisible(tester), isTrue);
        // ⛔ Le texte n'est PAS retapé : il se LIT sur l'acte du port, en un
        // seul exemplaire (pattern nº 6).
        expect(texteDuMessage(tester), ActeEcriture.retrait.messageEchec);
        expect(
          find.textContaining(ActeEcriture.retrait.messageEchec),
          findsOneWidget,
        );
        // 🔴 LA TUILE RESTE — c'est la moitié de l'AC que T4 avait ancrée et
        // que personne ne pouvait voir.
        expect(tuile('e1'), findsOneWidget);
        expect(find.byType(MessageEcriture), findsOneWidget);
      },
    );

    testWidgets('⛔ LE TON DU HUB N\'EST PAS `erreur`, ET C\'EST UNE MESURE — '
        '`texteSurFond`, et le glyphe ⚠ porte l\'alerte', (tester) async {
      await monter(tester);
      harnais.bloquerEcriture();
      await retirerLEchue(tester);

      // ✅ Ce que le hub porte.
      expect(
        couleurDuMessage(tester),
        ConcentrationTokens.texteSurFond.couleur,
      );
      // ⛔ CONTRÔLE NÉGATIF — sans lui, l'assertion ci-dessus serait vraie
      // aussi le jour où les deux tokens rendraient la même couleur.
      expect(
        couleurDuMessage(tester),
        isNot(ConcentrationTokens.erreur.couleur),
        reason:
            '`erreur`, `moduleActif` et `texteSecondaire` sont à 1,00:1 '
            'ENTRE EUX : le rouge ne distinguerait RIEN de la barre basse, '
            'tout en perdant 3,47 points de contraste (14,39:1 → 10,93:1).',
      );
      // 🔴 Ce qui porte l'alerte, puisque la teinte ne peut pas (SC 1.4.1).
      expect(find.textContaining('⚠'), findsOneWidget);
    });

    testWidgets(
      '🔴 SÛRETÉ (C-1, C-3) — ZÉRO REFLUX : la grille a le MÊME RECT avant et '
      'après l\'apparition du message',
      (tester) async {
        await monter(tester);
        // La grille est mesurée par le rect de ses tuiles : ce sont elles que
        // le pratiquant vise, et c'est leur déplacement qui est dangereux.
        final avant = tester.getRect(tuile('a1'));

        harnais.bloquerEcriture();
        await retirerLEchue(tester);
        expect(messageVisible(tester), isTrue); // le message est bien là

        final apres = tester.getRect(tuile('a1'));
        expect(
          apres,
          avant,
          reason:
              'Le bloc de grille est CENTRÉ : une bande qui apparaît le '
              'remonterait juste au moment où le pratiquant réessaie son '
              'double appui — et un double appui égaré retire la MAUVAISE '
              'échéance, ce qui est IRRÉVERSIBLE (risque nº 5).',
        );
      },
    );

    testWidgets(
      '✅ PREMIER EFFACEMENT — un retrait qui RÉUSSIT rend `null` : le message '
      'tombe, et la tuile quitte la grille',
      (tester) async {
        await monter(tester);
        harnais.bloquerEcriture();
        await retirerLEchue(tester);
        expect(messageVisible(tester), isTrue);

        // ✅ Le blocage est RÉVERSIBLE — le stockage redevient inscriptible.
        harnais.debloquerEcriture();
        await retirerLEchue(tester);

        expect(messageVisible(tester), isFalse);
        expect(tuile('e1'), findsNothing);
        // ⛔ Et les actives sont intactes : le retrait n'a pas emporté autre
        // chose.
        expect(tuile('a1'), findsOneWidget);
        expect(tuile('a2'), findsOneWidget);
      },
    );

    testWidgets(
      '✅ DEUXIÈME EFFACEMENT — un nouvel échec ÉCRASE : un champ unique ne '
      'peut pas porter deux messages (vrai PAR CONSTRUCTION)',
      (tester) async {
        await monter(tester);
        harnais.bloquerEcriture();
        await retirerLEchue(tester);
        await retirerLEchue(tester);

        // ⛔ Ce n'est pas « surveillé », c'est structurel : il n'existe qu'UNE
        // zone et qu'UN champ. L'assertion le CONSTATE.
        expect(find.byType(MessageEcriture), findsOneWidget);
        expect(find.textContaining('⚠'), findsOneWidget);
        expect(texteDuMessage(tester), ActeEcriture.retrait.messageEchec);
      },
    );

    testWidgets(
      '🔴 TROISIÈME EFFACEMENT — LE RETOUR DU `push`, et `dispose()` NE '
      'SUFFIRAIT PAS : il n\'est JAMAIS appelé',
      (tester) async {
        await monter(tester);
        harnais.bloquerEcriture();
        await retirerLEchue(tester);
        expect(messageVisible(tester), isTrue);

        // On quitte le hub par la commande réelle de la barre basse.
        await tester.tap(find.bySemanticsLabel(GestionEcheancesPage.titre));
        await tester.pumpAndSettle();

        // 🔴 LE PIÈGE MESURÉ : pendant la navigation, le hub n'est plus dans
        // l'arbre. ⇒ une assertion « le message a disparu » écrite ICI serait
        // VIDE DE SENS, et elle passerait pour une bonne raison.
        expect(find.byType(HubPage), findsNothing);
        expect(find.byType(GestionEcheancesPage), findsOneWidget);

        // On revient : c'est le `Future` du `push` qui l'apprend à l'état.
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(HubPage), findsOneWidget);
        expect(
          messageVisible(tester),
          isFalse,
          reason:
              'ADR-014 §B.2 : `Navigator.push` ⛔ NE DÉMONTE PAS la route '
              'du dessous (mesuré : `disposes=0`, même `State`), donc effacer '
              'dans `dispose()` laisserait le message SURVIVRE à '
              'l\'aller-retour.',
        );
        // ⛔ La tuile est toujours là : quitter l'écran n'a rien retiré.
        expect(tuile('e1'), findsOneWidget);
      },
    );

    testWidgets('⛔ LE RAPPEL EST BRANCHÉ — sans lui, l\'échue serait annoncée '
        'actionnable et le double appui ne ferait RIEN', (tester) async {
      final notifier = await monter(tester);
      // Contrôle positif : l'échue est bien présente et retirable.
      expect(notifier.presentes.map((e) => e.id), contains('e1'));

      harnais.debloquerEcriture();
      await retirerLEchue(tester);

      // ✅ L'état ÉCRIT a bougé — ⛔ pas seulement l'écran.
      expect(harnais.octets(), contains('"retiree":true'));
      expect(notifier.presentes.map((e) => e.id), isNot(contains('e1')));
      // ⛔ Et l'échéance est CONSERVÉE : retirer n'est pas supprimer.
      expect(notifier.echeances.map((e) => e.id), contains('e1'));
    });
  });
}
