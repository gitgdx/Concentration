import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/gestion_echeances_page.dart';
import 'package:concentration/features/echeances/presentation/widgets/confirmation_suppression.dart';
import 'package:concentration/features/echeances/presentation/widgets/formulaire_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/ligne_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/message_ecriture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// La page de gestion (T10) — AC-1, AC-5, AC-6, AC-8.
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

  Future<void> ouvrir(WidgetTester tester, {double hauteur = 600}) async {
    // ⚠️ `ListView` ne MATÉRIALISE que ce qui entre dans le viewport : une
    // assertion d'ORDRE sur 5 cartes serait fausse par TRONCATURE si la
    // fenêtre était trop courte — et elle passerait pour un défaut de tri.
    tester.view.physicalSize = Size(400, hauteur);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        darkTheme: ConcentrationTheme.sombre,
        themeMode: ThemeMode.dark,
        home: GestionEcheancesPage(
          notifier: notifier,
          clock: FakeClock(maintenant),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Écrit un document **directement sur le disque**, avant tout démarrage.
  void poser(List<(String, String, String)> entrees) {
    harnais.poser(
      '{"schemaVersion":2,"echeances":[${entrees.map((e) => '{"id":"${e.$1}",'
          '"description":"${e.$2}","dateEcheance":"${e.$3}"}').join(',')}]}',
    );
  }

  String civil(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T'
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  String dans(Duration d) => civil(maintenant.add(d));
  String avant(Duration d) => civil(maintenant.subtract(d));

  group('AC-1 — ouverture, mode sombre, état vide', () {
    testWidgets('la page s’ouvre en mode SOMBRE de référence', (tester) async {
      await ouvrir(tester);
      expect(find.text('Gérer les échéances'), findsOneWidget);
      final theme = Theme.of(tester.element(find.byType(GestionEcheancesPage)));
      expect(theme.brightness, Brightness.dark);
      expect(
        theme.scaffoldBackgroundColor,
        ConcentrationTokens.fondApp.couleur,
      );
    });

    testWidgets('sans échéance : un message SOBRE qui INVITE, sans erreur', (
      tester,
    ) async {
      await ouvrir(tester);
      expect(find.text('Aucune échéance enregistrée.'), findsOneWidget);
      expect(
        find.text('Ajoutez-en une pour commencer votre revue.'),
        findsOneWidget,
      );
      // ⛔ Ni erreur technique, ni écran nu, ni couleur d'urgence.
      expect(find.byType(MessageEcriture), findsNothing);
      for (final interdit in ['Exception', 'Error', 'null', 'échec']) {
        expect(find.textContaining(interdit), findsNothing);
      }
      // ⛔ L'affordance RESTE là : c'est l'invitation, pas une décoration.
      expect(find.text('Ajouter une échéance'), findsOneWidget);
    });

    testWidgets('⛔ la page de gestion ne porte PAS la barre basse', (
      tester,
    ) async {
      await ouvrir(tester);
      final echafaudage = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        echafaudage.bottomNavigationBar,
        isNull,
        reason:
            'la dupliquer ferait DEUX exemplaires d’un composant et '
            'rouvrirait le débordement du Row déjà payé',
      );
    });
  });

  group('AC-8 — deux groupes, et les ordres vérifiés DANS LES DEUX SENS', () {
    testWidgets('3 actives + 2 échues ⇒ 3 dans un groupe, 2 dans l’autre', (
      tester,
    ) async {
      poser([
        ('a3', 'Loin', dans(const Duration(days: 30))),
        ('a1', 'Proche', dans(const Duration(days: 2))),
        ('a2', 'Milieu', dans(const Duration(days: 10))),
        ('e2', 'Ancienne', avant(const Duration(days: 20))),
        ('e1', 'Recente', avant(const Duration(days: 3))),
      ]);
      await tester.runAsync(notifier.charger);
      await ouvrir(tester, hauteur: 2000);

      expect(find.text('Actives · 3'), findsOneWidget);
      expect(find.text('Échues · 2'), findsOneWidget);

      final ordre = tester
          .widgetList<LigneEcheance>(find.byType(LigneEcheance))
          .map((l) => l.echeance.id)
          .toList();
      // Actives : date CROISSANTE. Échues : de la plus RÉCEMMENT échue à la
      // plus ancienne. ⚠️ Les DEUX sens sont vérifiés — un seul groupe trié
      // laisserait l'autre libre.
      expect(ordre, ['a1', 'a2', 'a3', 'e1', 'e2']);
      expect(
        ordre.sublist(3),
        isNot(['e2', 'e1']),
        reason: 'l’historique va du RÉCENT vers l’ancien, pas l’inverse',
      );
    });

    testWidgets('une description VIDE reste LISTÉE et MANIPULABLE (I-3)', (
      tester,
    ) async {
      poser([('v', '', dans(const Duration(days: 5)))]);
      await tester.runAsync(notifier.charger);
      await ouvrir(tester);

      expect(find.byType(LigneEcheance), findsOneWidget);
      // ⛔ Jamais masquée : une donnée invisible est une donnée perdue.
      expect(
        find.text(dateLisible(maintenant.add(const Duration(days: 5)))),
        findsWidgets,
      );
      // ...et ses deux actions restent NOMMÉES et activables.
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('la gestion affiche l’unité, la TUILE ne l’affiche PAS', (
      tester,
    ) async {
      poser([('a', 'Visite', dans(const Duration(days: 3)))]);
      await tester.runAsync(notifier.charger);
      await ouvrir(tester);
      // ⛔ LES DEUX MOITIÉS : sans la seconde, « une unité partout »
      // satisferait la règle.
      expect(find.text('3 jours'), findsOneWidget);
      expect(
        find.text('3'),
        findsNothing,
        reason: 'en gestion, le nombre nu SEUL n’existe pas',
      );
    });
  });

  group('AC-5 — à 9 présentes : indication, ⛔ PAS barrière muette', () {
    Future<void> remplir(WidgetTester tester, int combien) async {
      await tester.runAsync(() async {
        for (var i = 0; i < combien; i++) {
          await notifier.creer(
            description: 'Echeance $i',
            date: '1${i + 1}/03/${maintenant.year + 1}',
            heure: '',
          );
        }
      });
    }

    testWidgets('l’affordance passe en CONTOUR et AFFICHE le message', (
      tester,
    ) async {
      await remplir(tester, 9);
      await ouvrir(tester);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(MessageEcriture), findsOneWidget);
      expect(find.textContaining('9'), findsWidgets);
      expect(find.textContaining('supprimer'), findsWidgets);
      // ⛔ Le message NE PROMET PAS un geste inexistant avant US-01.4.
      expect(find.textContaining('disparaît'), findsNothing);
    });

    testWidgets('🔴 elle RESTE ACTIVABLE : la tentative doit être OBSERVABLE', (
      tester,
    ) async {
      await remplir(tester, 9);
      await ouvrir(tester);
      final bouton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(
        bouton.onPressed,
        isNotNull,
        reason:
            'un bouton désactivé rendrait « je TENTE de créer une '
            'dixième » INTESTABLE',
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(find.byType(FormulaireEcheance), findsOneWidget);
    });

    testWidgets('à 8 présentes, l’affordance est PLEINE — contrôle négatif', (
      tester,
    ) async {
      await remplir(tester, 8);
      await ouvrir(tester);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(MessageEcriture), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // 🔴 AC-6 d'US-01.4 (T5) — LA SURFACE, et le décompte qui la gouverne.
  //
  // ⛔ Le message du domaine est LU, jamais recopié : ce groupe asserte des
  // PROPRIÉTÉS observables sur l'écran (variante annoncée, décompte).
  // ───────────────────────────────────────────────────────────────────────
  group('AC-6 (US-01.4) — le message de la limite sur la page de gestion', () {
    /// Écrit [echeances] sur le disque **à travers le codec de PRODUCTION**,
    /// puis recharge le notifier de la page. ⛔ Aucun seam, aucun faux dépôt :
    /// c'est le seul moyen d'obtenir une échéance **échue** ou **retirée**, que
    /// `creer()` refuse par construction (futur strict d'AC-4).
    Future<void> poserEtCharger(
      WidgetTester tester,
      List<Echeance> echeances,
    ) async {
      const codec = EcheanceDocumentCodec();
      harnais.poser(
        codec.encoder(codec.documentNeuf(versionCourante), echeances),
      );
      await tester.runAsync(notifier.charger);
    }

    Echeance active(int i) => Echeance(
      id: 'a$i',
      description: 'Active $i',
      dateEcheance: maintenant.add(Duration(days: i + 1)),
    );

    Echeance echue(int i, {bool retiree = false}) => Echeance(
      id: 'e$i',
      description: 'Echue $i',
      dateEcheance: maintenant.subtract(Duration(days: i + 1)),
      retiree: retiree,
    );

    /// Le mot du geste POINTEUR, celui que le message enseigne. ⛔ La durée, le
    /// nombre 9 et le reste de la prose ne sont pas répliqués ici.
    Finder annonceDuGeste() => find.textContaining('double appui');

    testWidgets('🔴 avec une échue PRÉSENTE, le message ANNONCE le retrait', (
      tester,
    ) async {
      await poserEtCharger(tester, [
        for (var i = 0; i < 8; i++) active(i),
        echue(0),
      ]);
      await ouvrir(tester);

      // ⛔ CONTRÔLE POSITIF D'ABORD : sans lui, « le message annonce » serait
      // vrai sur une page qui n'affiche aucun message.
      expect(notifier.presentes, hasLength(9));
      expect(find.byType(MessageEcriture), findsOneWidget);
      expect(
        annonceDuGeste(),
        findsWidgets,
        reason:
            'c’est le SEUL endroit du produit qui enseigne le double appui '
            '(lacune de découvrabilité, Design UX §2)',
      );
    });

    testWidgets(
      '🔴 sans échue, le message N’ANNONCE PAS le retrait — l’autre côté',
      (tester) async {
        await poserEtCharger(tester, [for (var i = 0; i < 9; i++) active(i)]);
        await ouvrir(tester);

        expect(notifier.presentes, hasLength(9));
        expect(find.byType(MessageEcriture), findsOneWidget);
        expect(
          annonceDuGeste(),
          findsNothing,
          reason:
              '⛔ JAMAIS un geste indisponible : aucune tuile n’est retirable '
              'ici. Sans ce test, un message UNIQUE satisferait la règle',
        );
      },
    );

    testWidgets('🔴 une échue RETIRÉE ne compte pas : 9 en base, 8 présentes, '
        'affordance PLEINE', (tester) async {
      // 🔴 LE MUTANT QUE CE TEST TUE, et il était EN PLACE avant T5 :
      // `refusDeLimite(notifier.echeances)` — la forme livrée par US-01.2,
      // restée telle quelle après T4. Elle comptait l’échéance RETIRÉE, donc
      // annonçait la limite alors que **8 tuiles seulement** sont sur la
      // grille, tandis que `creer()` — qui lit bien `presentes` — acceptait
      // la création. ⇒ AC-6 « Nominal » d’US-01.4 (*« après un retrait, la
      // création suivante aboutit »*) était FAUX **par le bouton**, pas par
      // la règle. C’est le symptôme que C-7 nomme, dans l’autre sens.
      await poserEtCharger(tester, [
        for (var i = 0; i < 8; i++) active(i),
        echue(0, retiree: true),
      ]);
      await ouvrir(tester);

      expect(notifier.echeances, hasLength(9), reason: 'contrôle positif');
      expect(notifier.presentes, hasLength(8));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(MessageEcriture), findsNothing);
    });
  });

  group('AC-6 « Limite » — éditer une ÉCHUE est refusé, pas empêché', () {
    testWidgets(
      '✎ sur une échue affiche le REFUS et n’ouvre PAS le formulaire',
      (tester) async {
        poser([('e', 'Passeport', avant(const Duration(days: 2)))]);
        await tester.runAsync(notifier.charger);
        await ouvrir(tester);

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        expect(
          find.byType(FormulaireEcheance),
          findsNothing,
          reason: '⛔ le formulaire ne s’ouvre PAS pour une échue',
        );
        expect(find.textContaining('se consulte'), findsOneWidget);
        expect(find.textContaining('se supprime'), findsOneWidget);
      },
    );

    testWidgets(
      '✎ sur une ACTIVE ouvre bien le formulaire — contrôle négatif',
      (tester) async {
        poser([('a', 'Convention', dans(const Duration(days: 5)))]);
        await tester.runAsync(notifier.charger);
        await ouvrir(tester);

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        expect(find.byType(FormulaireEcheance), findsOneWidget);
        expect(find.text('Convention'), findsWidgets);
      },
    );
  });

  group('AC-7 — la suppression passe par la confirmation', () {
    testWidgets('🗑 ouvre la modale, et RIEN n’est écrit avant confirmation', (
      tester,
    ) async {
      poser([('a', 'Convention', dans(const Duration(days: 5)))]);
      await tester.runAsync(notifier.charger);
      final octetsAvant = harnais.octets();
      await ouvrir(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationSuppression), findsOneWidget);
      expect(
        harnais.octets(),
        octetsAvant,
        reason: 'le fichier est INCHANGÉ entre la demande et la confirmation',
      );
    });
  });
}
