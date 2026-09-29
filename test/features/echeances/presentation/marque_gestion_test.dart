import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/gestion_echeances_page.dart';
import 'package:concentration/features/echeances/presentation/widgets/ligne_echeance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// **T12 — LE SIGNALEMENT DES ÉCHUES ENCORE PRÉSENTES SUR LA GRILLE**
/// *(AC-7, `Should`)*.
///
/// ⚖️ **`Should` ne veut PAS dire « cochable sans être fait »** : la clause est
/// **tenue**, et si elle tombait un jour, **son abandon devrait être DATÉ**.
///
/// 🔴 **CE QUE CE FICHIER DOIT TUER** *(mutant nommé par la cellule T12)* : une
/// distinction **uniquement chromatique**. C'est pourquoi les assertions portent
/// sur le **TEXTE VISIBLE**, et qu'un contrôle vérifie que la **couleur est la
/// MÊME** dans les deux états — sans lui, on pourrait « distinguer » par la
/// teinte et croire la clause tenue.
void main() {
  final maintenant = DateTime(2026, 8, 29, 12);
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  Echeance echue(String id, String description, {bool retiree = false}) =>
      Echeance(
        id: id,
        description: description,
        dateEcheance: maintenant.subtract(const Duration(days: 3)),
        retiree: retiree,
      );

  Echeance active(String id, String description) => Echeance(
    id: id,
    description: description,
    dateEcheance: maintenant.add(const Duration(days: 20)),
  );

  Future<void> monter(WidgetTester tester, List<Echeance> jeu) async {
    final notifier = await notifierCharge(
      tester,
      harnais,
      jeu,
      clock: FakeClock(maintenant),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: GestionEcheancesPage(
          notifier: notifier,
          clock: FakeClock(maintenant),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Le texte de la 3ᵉ ligne d'une carte, désignée par sa description.
  String ligneEtat(WidgetTester tester, String description) {
    final carte = find.ancestor(
      of: find.text(description),
      matching: find.byType(LigneEcheance),
    );
    return tester
        .widgetList<Text>(
          find.descendant(of: carte, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((t) => t.startsWith('Échéance atteinte'));
  }

  Color couleurEtat(WidgetTester tester, String description) {
    final carte = find.ancestor(
      of: find.text(description),
      matching: find.byType(LigneEcheance),
    );
    return tester
        .widgetList<Text>(
          find.descendant(of: carte, matching: find.byType(Text)),
        )
        .firstWhere((t) => (t.data ?? '').startsWith('Échéance atteinte'))
        .style!
        .color!;
  }

  group('T12 — la marque « sur la grille / retirée » (AC-7)', () {
    testWidgets(
      '🔴 LES DEUX ÉTATS PORTENT UN MOT — ⛔ jamais « un mot / rien », qui '
      'serait MUET à l’oreille pour la ligne non marquée',
      (tester) async {
        await monter(tester, [
          echue('e1', 'Toujours sur la grille'),
          echue('e2', 'Deja retiree', retiree: true),
        ]);

        // ⛔ Les libellés se LISENT sur le produit : une chaîne recopiée dans
        // une assertion est la classe de défaut nº 1 de ce projet.
        expect(
          ligneEtat(tester, 'Toujours sur la grille'),
          contains(LigneEcheance.marqueSurLaGrille),
        );
        expect(
          ligneEtat(tester, 'Deja retiree'),
          contains(LigneEcheance.marqueRetiree),
        );

        // 🔴 CONTRÔLE NÉGATIF — les deux mots sont DISTINCTS. Sans lui, les
        // deux assertions ci-dessus seraient vraies avec un seul et même mot.
        expect(
          LigneEcheance.marqueSurLaGrille,
          isNot(LigneEcheance.marqueRetiree),
        );
        expect(
          ligneEtat(tester, 'Toujours sur la grille'),
          isNot(ligneEtat(tester, 'Deja retiree')),
        );
      },
    );

    testWidgets(
      '🔴 LE MUTANT QUE CETTE TÂCHE DOIT TUER — la distinction n’est PAS '
      'chromatique : la couleur est la MÊME dans les deux états',
      (tester) async {
        await monter(tester, [
          echue('e1', 'Toujours sur la grille'),
          echue('e2', 'Deja retiree', retiree: true),
        ]);

        expect(
          couleurEtat(tester, 'Deja retiree'),
          couleurEtat(tester, 'Toujours sur la grille'),
          reason:
              '`erreur`, `moduleActif` et `texteSecondaire` sont à 1,00:1 '
              'ENTRE EUX (mesuré) ⇒ une teinte ne distinguerait RIEN, et la '
              'distinction reposerait sur ce qu’aucun œil ne sépare (SC 1.4.1)',
        );
      },
    );

    testWidgets(
      '⛔ AUCUN TROISIÈME GROUPE, AUCUN FILTRE — la retirée reste DANS le '
      'groupe des échues (AC-7 « Limite »)',
      (tester) async {
        await monter(tester, [
          active('a1', 'Une active'),
          echue('e1', 'Toujours sur la grille'),
          echue('e2', 'Deja retiree', retiree: true),
        ]);

        // Les deux groupes, et EXACTEMENT deux.
        expect(find.textContaining('Actives'), findsOneWidget);
        expect(find.textContaining('Échues'), findsOneWidget);
        // ⛔ CONTRÔLE POSITIF : la retirée est bien LISTÉE — « signalée » ne
        // veut jamais dire « cachée ».
        expect(find.text('Deja retiree'), findsOneWidget);
        expect(find.byType(LigneEcheance), findsNWidgets(3));
        // Le décompte du groupe des échues les compte TOUTES LES DEUX.
        // ⛔ **LE FORMAT DU TITRE NE SE DEVINE PAS** : j'avais écrit
        // « Échues (2) », le produit rend « Échues · 2 ». Le test **LIT** donc
        // le rendu et n'assère que ce qui compte — le DÉCOMPTE.
        final titreEchues = tester
            .widgetList<Text>(find.textContaining('Échues'))
            .map((t) => t.data)
            .whereType<String>()
            .first;
        expect(
          titreEchues,
          contains('2'),
          reason:
              'les DEUX échues sont comptées dans leur groupe — une '
              'retirée n’est ni filtrée, ni déplacée ailleurs',
        );
      },
    );

    testWidgets(
      '⛔ UNE ACTIVE NE PORTE AUCUNE MARQUE — AC-7 ne parle que du groupe des '
      'échues, et ce serait du bruit sur la ligne la plus fréquente',
      (tester) async {
        await monter(tester, [active('a1', 'Une active')]);

        expect(
          find.textContaining(LigneEcheance.marqueSurLaGrille),
          findsNothing,
        );
        expect(find.textContaining(LigneEcheance.marqueRetiree), findsNothing);
        // Contrôle positif : la carte est bien là, et porte son temps restant.
        expect(find.text('Une active'), findsOneWidget);
      },
    );

    testWidgets(
      '⛔ LE LIBELLÉ DU DOMAINE N’EST PAS RETOUCHÉ — la marque vit dans le '
      'TEXTE VISIBLE, ⛔ pas dans `libelleAccessibilite` (mutants X-2 / X-3)',
      (tester) async {
        await monter(tester, [echue('e2', 'Deja retiree', retiree: true)]);

        // ✅ Elle est bien ANNONCÉE — par construction, puisque c'est un `Text`
        // visible et non un `tooltip` (mesuré en US-01.2 : un `Tooltip`
        // renseigne `SemanticsProperties.tooltip`, ⛔ pas le `label`).
        expect(
          find.textContaining(LigneEcheance.marqueRetiree),
          findsOneWidget,
        );
        // ⛔ …et ⛔ AUCUN libellé sémantique de la page ne la porte : la chaîne
        // du domaine reste INTACTE.
        final libelles = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((w) => w.properties.label)
            .whereType<String>()
            .join(' | ');
        expect(
          libelles,
          isNot(contains(LigneEcheance.marqueRetiree)),
          reason: 'retoucher `libelleAccessibilite` casserait X-2 / X-3',
        );
      },
    );
  });
}
