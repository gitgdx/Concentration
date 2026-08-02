import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// AC-8 « Nominal » — le **mode sombre de référence**, enfin assertionné.
///
/// ⛔ L'unique assertion qui visait le fond était
/// `expect(scaffold.backgroundColor ?? ConcentrationTokens.fondApp.couleur,
/// isNotNull)` : l'opérateur `??` retombait sur une constante **jamais nulle**,
/// donc l'assertion était vraie **quoi qu'il arrive** — y compris avec un fond
/// **blanc** (mutant `QA-M2b`, survivant au 2026-08-02). Une assertion
/// tautologique ne se renforce pas : elle se **remplace**.
void main() {
  group('AC-8 — mode sombre de référence', () {
    test('le fond du thème EST le token de fond, et rien d’autre', () {
      expect(
        ConcentrationTheme.sombre.scaffoldBackgroundColor,
        ConcentrationTokens.fondApp.couleur,
      );
      expect(ConcentrationTheme.sombre.brightness, Brightness.dark);
    });

    test('« sombre » est une GRANDEUR mesurée, pas un nom', () {
      final fond = ConcentrationTokens.fondApp;
      final texte = ConcentrationTokens.texteSurFond;

      // Définition opérante du mode sombre, indépendante des tokens retenus :
      // le fond est PLUS SOMBRE que le texte qu'il porte. Un fond blanc inverse
      // cette relation, quel que soit le nom qu'on lui donne.
      expect(
        fond.luminanceRelative,
        lessThan(texte.luminanceRelative),
        reason: 'un fond plus clair que son texte est un mode CLAIR',
      );

      // ...et le couple reste lisible au sens WCAG AA (RNF-06, AC-8).
      expect(
        fond.contrasteAvec(texte),
        greaterThanOrEqualTo(ConcentrationTokens.contrasteMinTexteNormal),
      );
    });

    test('la barre de titre partage le fond de l’application', () {
      expect(
        ConcentrationTheme.sombre.appBarTheme.backgroundColor,
        ConcentrationTokens.fondApp.couleur,
      );
    });
  });
}
