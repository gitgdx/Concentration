import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/hub/domain/practice_module_registry.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';
import '../../../support/rendu_couleur.dart';

/// AC-2 « Nominal » — les modules futurs sont **rendus** estompés.
///
/// ⛔ Le statut `grise` du **descripteur** était assertionné (registre) et la
/// non-interactivité l'était solidement (absence de gestionnaire), mais le
/// **rendu estompé** ne l'était nulle part : forcer toutes les entrées à la
/// couleur du module actif laissait les 102 tests verts (mutant `QA-M5`).
/// *« Visibles mais grisés »* est une étape Gherkin — la moitié « grisés »
/// n'était adossée à rien.
void main() {
  final maintenant = DateTime(2026, 8, 1, 12);
  const registre = PracticeModuleRegistry();
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  Future<void> monter(WidgetTester tester) async {
    // ⚖️ US-01.2 (T11) : le seam `echeances:` a disparu (ADR-011 §5).
    final notifier = await notifierCharge(tester, harnais, [
      Echeance(
        id: 'a',
        description: 'Rendez-vous',
        dateEcheance: maintenant.add(const Duration(hours: 6)),
      ),
    ], clock: FakeClock(maintenant));
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: HubPage(notifier: notifier, clock: FakeClock(maintenant)),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'le module ACTIF et les modules GRISÉS ne portent pas la même couleur',
    (tester) async {
      await monter(tester);
      // ⛔ La liste des modules vient du REGISTRE, jamais recopiée ici : une liste
      // écrite à la main dérive au premier module ajouté (RF-21).
      expect(
        registre.grises,
        isNotEmpty,
        reason: 'sans module grisé au registre, ce test ne contrôle rien',
      );

      final actif = couleurDuLibelle(tester, registre.actif.libelle);
      expect(actif, ConcentrationTokens.moduleActif.couleur);

      for (final module in registre.grises) {
        final grise = couleurDuLibelle(tester, module.libelle);
        expect(
          grise,
          ConcentrationTokens.moduleGrise.couleur,
          reason: '« ${module.libelle} » doit être RENDU estompé',
        );
        expect(
          grise,
          isNot(actif),
          reason: 'un module grisé rendu comme l’actif n’est plus grisé',
        );
      }
    },
  );

  testWidgets(
    '« grisé » est une GRANDEUR : moins de contraste que le module actif',
    (tester) async {
      // Propriété indépendante des tokens retenus : « estompé » veut dire
      // RESSORTIR MOINS sur le fond de l'application. Deux couleurs simplement
      // différentes ne suffiraient pas — un module « grisé » plus éclatant que
      // l'actif satisferait l'égalité de couleur et trahirait l'AC.
      await monter(tester);
      final fond = ConcentrationTokens.fondApp;
      final contrasteActif = fond.contrasteAvec(
        rgbDe(couleurDuLibelle(tester, registre.actif.libelle)),
      );

      for (final module in registre.grises) {
        expect(
          fond.contrasteAvec(rgbDe(couleurDuLibelle(tester, module.libelle))),
          lessThan(contrasteActif),
          reason:
              '« ${module.libelle} » doit ressortir MOINS que le module actif '
              '(contraste actif mesuré : $contrasteActif)',
        );
      }
    },
  );
}
