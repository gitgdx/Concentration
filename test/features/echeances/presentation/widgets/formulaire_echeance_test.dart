import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/widgets/confirmation_suppression.dart';
import 'package:concentration/features/echeances/presentation/widgets/formulaire_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/ligne_echeance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/magasin_temporaire.dart';

/// Les trois widgets de saisie (T9) — AC-15, AC-7, AC-8 « Limite ».
///
/// ⚠️ **Ce fichier vit hors de `test/e2e/**`** : il monte des SOUS-ARBRES pour
/// éprouver un widget isolément. Les parcours complets, eux, montent la RACINE
/// et traversent la persistance (T12, ADR-010 §1).
void main() {
  final maintenant = DateTime(2026, 8, 6, 8);
  late MagasinTemporaire harnais;
  late EcheancesNotifier notifier;

  setUp(() async {
    harnais = MagasinTemporaire.creer();
    notifier = EcheancesNotifier(
      depot: EcheanceDocumentRepository(harnais.magasin),
      clock: FakeClock(maintenant),
    );
    await notifier.charger();
  });

  tearDown(() {
    notifier.dispose();
    harnais.nettoyer();
  });

  Future<void> monter(WidgetTester tester, Widget enfant) async {
    await tester.pumpWidget(
      MaterialApp(theme: ConcentrationTheme.sombre, home: enfant),
    );
    await tester.pump();
  }

  /// Monte le widget **DANS UNE ROUTE**, pour que `Navigator.pop` ait un sens :
  /// « la surface se ferme » et « la surface RESTE ouverte » sont deux
  /// observations distinctes, et la seconde est celle qui porte AC-17.
  Future<void> monterEnRoute(WidgetTester tester, Widget enfant) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => enfant),
        ),
      ),
    );
    await tester.pump();
  }

  Echeance echeance(String id, String description, {int joursAvant = 0}) =>
      Echeance(
        id: id,
        description: description,
        dateEcheance: joursAvant > 0
            ? maintenant.subtract(Duration(days: joursAvant))
            : DateTime(maintenant.year + 1, 3, 15, 23, 59),
      );

  group('AC-15 — libellés annoncés, et les QUATRE interdits du formulaire', () {
    testWidgets('chaque champ porte un libellé VISIBLE et ANNONCÉ', (
      tester,
    ) async {
      await monter(tester, FormulaireEcheance(notifier: notifier));
      for (final libelle in [
        'Description (obligatoire)',
        'Date (obligatoire)',
        'Heure (optionnel)',
      ]) {
        // Visible en permanence...
        expect(find.text(libelle), findsOneWidget, reason: '« $libelle »');
        // ...ET porté par la sémantique. ⚠️ Borne NM-6 : ⛔ rien ici ne prouve
        // qu'un TalkBack le PRONONCE.
        expect(
          find.bySemanticsLabel(libelle),
          findsWidgets,
          reason: '« $libelle » doit être un nom accessible',
        );
      }
      // Le caractère obligatoire ou optionnel est DANS le libellé — un seul
      // exemplaire, pas deux chaînes à tenir d'accord.
      expect(find.textContaining('optionnel'), findsOneWidget);
    });

    testWidgets('⛔ AUCUN maxLength : le 81ᵉ caractère PEUT être tapé', (
      tester,
    ) async {
      await monter(tester, FormulaireEcheance(notifier: notifier));
      final quatreVingtUn = 'a' * 81;
      await tester.enterText(find.byType(TextField).first, quatreVingtUn);
      await tester.pump();
      // 🔴 Si un `maxLength` bornait le champ, la valeur serait tronquée à 80
      // et le refus d'AC-2 « Limite » N'AURAIT JAMAIS LIEU.
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        hasLength(81),
      );
      for (final champ in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(champ.maxLength, isNull, reason: '⛔ aucun maxLength');
        expect(
          champ.inputFormatters,
          anyOf(isNull, isEmpty),
          reason:
              '⛔ aucun formateur : `31/02` doit rester TAPABLE, sinon '
              'AC-16 devient inobservable',
        );
      }
    });

    testWidgets('⛔ AUCUN compteur, badge, alerte animée ni gamification', (
      tester,
    ) async {
      await monter(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.pump();
      expect(find.text('3/80'), findsNothing);
      expect(find.textContaining('/80'), findsNothing);
      expect(find.byType(Badge), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('un refus est ANCRÉ sous son champ, avec un SIGNE et un mot', (
      tester,
    ) async {
      await monter(tester, FormulaireEcheance(notifier: notifier));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final message = find.byType(MessageValidation);
      expect(message, findsOneWidget, reason: '⛔ un refus n’est jamais muet');
      // ⛔ Jamais la couleur seule : le SIGNE est obligatoire (SC 1.4.1).
      expect(find.textContaining('⚠'), findsOneWidget);
      expect(find.textContaining('description'), findsWidgets);
      // Token `erreur`, autorisé nommément par AC-15 « Erreur ».
      final texte = tester.widget<Text>(
        find.descendant(of: message, matching: find.byType(Text)),
      );
      expect(texte.style!.color, ConcentrationTokens.erreur.couleur);
    });

    testWidgets("⛔ le message ne REMPLACE PAS l'aide de format", (
      tester,
    ) async {
      await monter(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Convention');
      await tester.enterText(find.byType(TextField).at(1), 'pas une date');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Format : JJ/MM/AAAA.'),
        findsOneWidget,
        reason:
            'l’aide porte l’information dont l’utilisateur a besoin AU '
            'MOMENT du refus',
      );
    });

    testWidgets('un refus d’HEURE s’ancre sous le champ HEURE (AC-16 L)', (
      tester,
    ) async {
      // ⚠️ Le refus d'une **heure civile inexistante** (02:30 le jour du saut
      // de printemps) n'est PAS observable sur cet hôte — borne **NM-9**. Ce
      // qui est éprouvé ici, c'est que le champ HEURE porte bien son ANCRAGE
      // de message, ce qui est vrai sous tout fuseau.
      await monter(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Convention');
      await tester.enterText(
        find.byType(TextField).at(1),
        '15/03/${maintenant.year + 1}',
      );
      await tester.enterText(find.byType(TextField).at(2), '25:00');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageValidation), findsOneWidget);
      expect(find.textContaining('25:00'), findsWidgets);
      expect(
        find.text("Sans heure, l'échéance est fixée à 23:59."),
        findsOneWidget,
        reason: '⛔ le message ne REMPLACE pas l’aide',
      );
    });

    testWidgets('le rendu tient à ×2,0 d’échelle de texte (A-6)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ConcentrationTheme.sombre,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: FormulaireEcheance(notifier: notifier),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // ⚠️ Borne NM-7 : ⛔ rien ici ne prouve que l'ŒIL le lit — seulement
      // qu'aucun débordement de mise en page n'est levé.
      expect(tester.takeException(), isNull);
    });
  });

  group('AC-5 — la limite est annoncée EN TÊTE, sans barrière muette', () {
    testWidgets('à 9 présentes, le formulaire s’ouvre AVEC le message', (
      tester,
    ) async {
      // ⛔ `runAsync` est OBLIGATOIRE : une écriture disque réelle n'aboutit
      // pas dans la zone `FakeAsync` d'un `testWidgets` (voir
      // `reglerEcritures`, où le fait est mesuré).
      await tester.runAsync(() async {
        for (var i = 0; i < 9; i++) {
          await notifier.creer(
            description: 'Echeance $i',
            date: '1${i + 1}/03/${maintenant.year + 1}',
            heure: '',
          );
        }
      });
      expect(notifier.echeances, hasLength(9));
      await monter(tester, FormulaireEcheance(notifier: notifier));

      expect(find.byType(MessageValidation), findsOneWidget);
      expect(find.textContaining('9'), findsWidgets);
      // 🔴 ⛔ AUCUNE BARRIÈRE MUETTE : « Enregistrer » reste ACTIVABLE, sinon
      // « je TENTE de créer une dixième » devient inobservable.
      final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(bouton.onPressed, isNotNull);
    });
  });

  group('AC-6 — le MÊME widget sert l’édition, valeurs pré-remplies', () {
    testWidgets('l’édition ouvre avec les valeurs d’origine et son titre', (
      tester,
    ) async {
      final origine = echeance('a', 'Convention');
      await monter(
        tester,
        FormulaireEcheance(notifier: notifier, original: origine),
      );
      expect(find.text("Modifier l'échéance"), findsOneWidget);
      expect(find.text('Nouvelle échéance'), findsNothing);
      expect(find.text('Convention'), findsOneWidget);
      expect(find.text('15/03/${maintenant.year + 1}'), findsOneWidget);
      expect(find.text('23:59'), findsOneWidget);
    });
  });

  group('AC-7 — la confirmation, seule modale du produit', () {
    testWidgets('elle NOMME la cible et met le focus initial sur Annuler', (
      tester,
    ) async {
      await monter(
        tester,
        ConfirmationSuppression(
          echeance: echeance('a', 'Convention'),
          notifier: notifier,
        ),
      );
      expect(find.text('Supprimer cette échéance ?'), findsOneWidget);
      expect(find.textContaining('« Convention »'), findsOneWidget);
      expect(find.textContaining('irréversible'), findsOneWidget);
      final annuler = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Annuler'),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        annuler.autofocus,
        isTrue,
        reason: '⛔ jamais le focus initial sur l’action destructive',
      );
    });

    testWidgets('à description VIDE, la cible est nommée par sa DATE', (
      tester,
    ) async {
      await monter(
        tester,
        ConfirmationSuppression(
          echeance: echeance('a', ''),
          notifier: notifier,
        ),
      );
      expect(
        find.textContaining('« »'),
        findsNothing,
        reason: '⛔ JAMAIS des guillemets vides',
      );
      expect(find.textContaining('15 mars'), findsOneWidget);
    });
  });

  group('AC-17 — une surface d’écriture NE SE FERME JAMAIS sur un échec', () {
    testWidgets('création réussie : la surface se ferme et le DISQUE porte', (
      tester,
    ) async {
      await monterEnRoute(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Convention');
      await tester.enterText(
        find.byType(TextField).at(1),
        '15/03/${maintenant.year + 1}',
      );
      await tester.tap(find.text('Enregistrer'));
      // ⚠️ La condition d'arrêt vise l'observation FINALE, ⛔ pas une étape
      // intermédiaire : le fichier apparaît AVANT que la chaîne
      // dépôt → rechargement → `setState` → `pop` n'ait fini de se dérouler.
      await reglerEcritures(
        tester,
        jusqua: () => !tester.any(find.byType(FormulaireEcheance)),
      );
      await tester.pumpAndSettle();

      expect(harnais.octets(), contains('Convention'));
      expect(
        find.byType(FormulaireEcheance),
        findsNothing,
        reason: 'sur un SUCCÈS avéré, la surface se ferme',
      );
    });

    testWidgets('🔴 échec d’écriture : la surface RESTE, la saisie AUSSI', (
      tester,
    ) async {
      harnais.bloquerEcriture();
      await monterEnRoute(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Jamais ecrite');
      await tester.enterText(
        find.byType(TextField).at(1),
        '15/03/${maintenant.year + 1}',
      );
      await tester.tap(find.text('Enregistrer'));
      await reglerEcritures(tester);

      // ⛔ Fermer, c'est dire « c'est fait ».
      expect(find.byType(FormulaireEcheance), findsOneWidget);
      // 🔴 La saisie est CONSERVÉE — ⛔ jamais un formulaire vidé.
      expect(find.text('Jamais ecrite'), findsOneWidget);
      expect(find.text('15/03/${maintenant.year + 1}'), findsOneWidget);
      // Le message est ancré AU PIED DE L'ACTION, ⛔ aucun champ n'est fautif.
      expect(find.byType(MessageValidation), findsOneWidget);
      // ⛔ Aucune trace technique, aucun code d'erreur.
      for (final interdit in ['Exception', 'errno', '.json', 'OS Error']) {
        expect(find.textContaining(interdit), findsNothing);
      }
      // ⛔ La garde « un seul vol » s'est RELÂCHÉE : sans cela, la nouvelle
      // tentative serait inobservable.
      final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(bouton.onPressed, isNotNull);
      expect(harnais.octets(), isNull, reason: 'rien n’a été écrit');
    });

    testWidgets('la NOUVELLE TENTATIVE aboutit SANS RESSAISIE', (tester) async {
      harnais.bloquerEcriture();
      await monterEnRoute(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Deuxieme essai');
      await tester.enterText(
        find.byType(TextField).at(1),
        '15/03/${maintenant.year + 1}',
      );
      await tester.tap(find.text('Enregistrer'));
      await reglerEcritures(tester);
      expect(harnais.octets(), isNull);

      harnais.debloquerEcriture();
      // ⛔ On ne ressaisit RIEN : on re-valide, c'est tout.
      await tester.tap(find.text('Enregistrer'));
      await reglerEcritures(tester, jusqua: () => harnais.octets() != null);
      await tester.pumpAndSettle();
      expect(harnais.octets(), contains('Deuxieme essai'));
    });

    testWidgets('« Annuler » ferme sans écrire, ⛔ sans confirmation', (
      tester,
    ) async {
      await monterEnRoute(tester, FormulaireEcheance(notifier: notifier));
      await tester.enterText(find.byType(TextField).first, 'Abandonnee');
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(FormulaireEcheance), findsNothing);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            '⛔ aucune confirmation d’abandon : la confirmation de '
            'suppression est la SEULE modale du produit',
      );
      expect(harnais.octets(), isNull);
    });

    testWidgets(
      'l’ÉDITION passe par le même bouton et écrit la nouvelle valeur',
      (tester) async {
        await tester.runAsync(
          () => notifier.creer(
            description: 'Avant',
            date: '15/03/${maintenant.year + 1}',
            heure: '',
          ),
        );
        final origine = notifier.echeances.single;
        await monterEnRoute(
          tester,
          FormulaireEcheance(notifier: notifier, original: origine),
        );
        await tester.enterText(find.byType(TextField).first, 'Apres');
        await tester.tap(find.text('Enregistrer'));
        await reglerEcritures(
          tester,
          jusqua: () => harnais.octets()!.contains('Apres'),
        );
        await tester.pumpAndSettle();
        expect(harnais.octets(), contains('Apres'));
        expect(harnais.octets(), isNot(contains('Avant')));
        expect(
          harnais.octets(),
          contains(origine.id),
          reason: 'l’édition CONSERVE l’id',
        );
      },
    );
  });

  group('AC-7 / AC-17 — le dialogue de confirmation', () {
    Future<Echeance> creerUne(WidgetTester tester) async {
      await tester.runAsync(
        () => notifier.creer(
          description: 'A supprimer',
          date: '15/03/${maintenant.year + 1}',
          heure: '',
        ),
      );
      return notifier.echeances.single;
    }

    testWidgets('« Annuler » laisse l’échéance en place, ⛔ AUCUNE écriture', (
      tester,
    ) async {
      final cible = await creerUne(tester);
      final avant = harnais.octets();
      await monterEnRoute(
        tester,
        ConfirmationSuppression(echeance: cible, notifier: notifier),
      );
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(
        harnais.octets(),
        avant,
        reason: 'le fichier est INCHANGÉ entre la demande et la confirmation',
      );
      expect(notifier.echeances, hasLength(1));
    });

    testWidgets('« Supprimer » écrit, puis le dialogue se ferme', (
      tester,
    ) async {
      final cible = await creerUne(tester);
      await monterEnRoute(
        tester,
        ConfirmationSuppression(echeance: cible, notifier: notifier),
      );
      await tester.tap(find.text('Supprimer'));
      await reglerEcritures(
        tester,
        jusqua: () => !tester.any(find.byType(ConfirmationSuppression)),
      );
      await tester.pumpAndSettle();
      expect(harnais.octets(), isNot(contains('A supprimer')));
      expect(find.byType(ConfirmationSuppression), findsNothing);
    });

    testWidgets('🔴 suppression IMPOSSIBLE : le dialogue RESTE ouvert', (
      tester,
    ) async {
      final cible = await creerUne(tester);
      final avant = harnais.octets();
      harnais.bloquerEcriture();
      await monterEnRoute(
        tester,
        ConfirmationSuppression(echeance: cible, notifier: notifier),
      );
      await tester.tap(find.text('Supprimer'));
      await reglerEcritures(tester);

      // ⛔ Fermer, c'est dire « c'est fait » — et l'utilisateur retrouverait
      // une liste qui A L'AIR NORMALE.
      expect(find.byType(ConfirmationSuppression), findsOneWidget);
      expect(find.byType(MessageValidation), findsOneWidget);
      // ⛔ Le corps est INCHANGÉ : la question reste posée, rien n'a été fait.
      expect(find.textContaining('irréversible'), findsOneWidget);
      expect(harnais.octets(), avant);
      expect(notifier.echeances, hasLength(1));
    });
  });

  group('formats d’affichage — un seul exemplaire, en français', () {
    test('la date est lisible et française, l’heure en 24 h', () {
      expect(dateLisible(DateTime(2027, 3, 15)), '15 mars 2027');
      expect(dateLisible(DateTime(2027, 8, 1)), '1 août 2027');
      expect(heureLisible(DateTime(2027, 3, 15, 9, 5)), '09:05');
      expect(heureLisible(DateTime(2027, 3, 15, 23, 59)), '23:59');
    });

    test('⛔ jamais de mois en anglais — contrôle négatif', () {
      for (var mois = 1; mois <= 12; mois++) {
        final rendu = dateLisible(DateTime(2027, mois, 1));
        for (final anglais in ['Jan', 'Mar', 'May', 'Oct', 'Dec']) {
          expect(rendu, isNot(contains(anglais)));
        }
      }
    });
  });

  group('LigneEcheance — R-9 : aucun calcul de durée dans la présentation', () {
    testWidgets('le temps restant est affiché AVEC son unité', (tester) async {
      final dans3Jours = Echeance(
        id: 'a',
        description: 'Visite',
        dateEcheance: maintenant.add(const Duration(days: 3)),
      );
      await monter(
        tester,
        Scaffold(
          body: LigneEcheance(
            echeance: dans3Jours,
            clock: FakeClock(maintenant),
            onModifier: () {},
            onSupprimer: () {},
          ),
        ),
      );
      expect(find.text('3 jours'), findsOneWidget);
      // ⛔ La chaîne `libelleAccessibilite` embarque « , Visite » : l'afficher
      // verbatim DUPLIQUERAIT la description dans la carte.
      expect(find.text('3 jours, Visite'), findsNothing);
      // ...mais le `Semantics` de la carte la porte ENTIÈRE — c'est
      // précisément ce pour quoi `libelleAccessibilite` a été écrit.
      final poignee = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('ligne-a'))).label,
        contains('3 jours, Visite'),
      );
      poignee.dispose();
    });

    testWidgets('une ÉCHUE porte le MOT et une bordure plus épaisse', (
      tester,
    ) async {
      await monter(
        tester,
        Scaffold(
          body: LigneEcheance(
            echeance: echeance('e', 'Passeport', joursAvant: 2),
            clock: FakeClock(maintenant),
            onModifier: () {},
            onSupprimer: () {},
          ),
        ),
      );
      // ⛔ Jamais la couleur seule : l'état échu porte un MOT.
      expect(find.text('Échéance atteinte'), findsOneWidget);
      final boite = tester.widget<Container>(
        find.byKey(const ValueKey('ligne-e')),
      );
      final bordure = (boite.decoration! as BoxDecoration).border!;
      expect(bordure.top.width, 2);
    });

    testWidgets('✎ et 🗑 sont PRÉSENTS sur une échue et NOMMENT l’échéance', (
      tester,
    ) async {
      var modifs = 0;
      await monter(
        tester,
        Scaffold(
          body: LigneEcheance(
            echeance: echeance('e', 'Passeport', joursAvant: 2),
            clock: FakeClock(maintenant),
            onModifier: () => modifs++,
            onSupprimer: () {},
          ),
        ),
      );
      // 🔴 Retirer ✎ d'une échue rendrait « je TENTE de modifier cette
      // échéance » INOBSERVABLE.
      expect(find.byTooltip('Modifier Passeport'), findsOneWidget);
      expect(find.byTooltip('Supprimer Passeport'), findsOneWidget);
      await tester.tap(find.byTooltip('Modifier Passeport'));
      expect(modifs, 1, reason: 'l’affordance est ACTIVABLE');
    });

    testWidgets('à description VIDE, la DATE monte en ligne de titre', (
      tester,
    ) async {
      await monter(
        tester,
        Scaffold(
          body: LigneEcheance(
            echeance: echeance('v', ''),
            clock: FakeClock(maintenant),
            onModifier: () {},
            onSupprimer: () {},
          ),
        ),
      );
      expect(find.text('15 mars ${maintenant.year + 1}'), findsOneWidget);
      expect(
        find.byTooltip('Modifier l’échéance du 15 mars ${maintenant.year + 1}'),
        findsOneWidget,
        reason: 'les actions restent NOMMÉES et manipulables (I-3)',
      );
    });

    testWidgets('les cibles tactiles font au moins 48 × 48 dp (A-4)', (
      tester,
    ) async {
      await monter(
        tester,
        Scaffold(
          body: LigneEcheance(
            echeance: echeance('a', 'Convention'),
            clock: FakeClock(maintenant),
            onModifier: () {},
            onSupprimer: () {},
          ),
        ),
      );
      for (final bouton in find.byType(IconButton).evaluate()) {
        final taille = tester.getSize(find.byWidget(bouton.widget));
        expect(taille.width, greaterThanOrEqualTo(48));
        expect(taille.height, greaterThanOrEqualTo(48));
      }
    });
  });
}
