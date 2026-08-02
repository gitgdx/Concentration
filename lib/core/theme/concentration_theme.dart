import 'package:flutter/material.dart';

import 'concentration_tokens.dart';
import 'rgb_extension.dart';

/// Thème de l'application (T1) — projection de `DESIGN_SYSTEM.md`.
///
/// ⛔ **Mode sombre de référence FORCÉ** (AC-8) : aucun thème clair n'est
/// défini, car en définir un prétendrait qu'un mode clair est supporté.
///
/// ⚠️ **DETTE ASSUMÉE ET NOMMÉE — les polices ne sont PAS embarquées.**
/// `DESIGN_SYSTEM.md` demande **JetBrains Mono** (le nombre) et **Inter** (le
/// texte). Aucun fichier de police n'est dans le dépôt et aucune dépendance de
/// polices n'est ajoutée (le projet n'a **ni SAST ni scanner de CVE** : toute
/// dépendance est une surface non scannée — même motif qu'ADR-008). Les familles
/// sont donc **demandées par leur nom** : si elles sont absentes du système,
/// Flutter retombe silencieusement sur la police par défaut.
/// ⇒ **Ce qui est réellement garanti est l'EXIGENCE FONCTIONNELLE** de
/// `DESIGN_SYSTEM.md` — `FontFeature.tabularFigures()`, pour que le nombre
/// change **sans saut de mise en page** au rafraîchissement. La police exacte
/// est une dette de livraison, pas un contrat tenu.
class ConcentrationTheme {
  const ConcentrationTheme._();

  static const String policeNombre = 'JetBrains Mono';
  static const String policeTexte = 'Inter';

  /// Style du **nombre nu** : élément dominant, chiffres à chasse fixe.
  static const TextStyle styleNombre = TextStyle(
    fontFamily: policeNombre,
    fontFamilyFallback: ['monospace'],
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Description en soutien discret — jamais concurrente du nombre.
  static const TextStyle styleDescription = TextStyle(
    fontFamily: policeTexte,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static ThemeData get sombre {
    final fond = ConcentrationTokens.fondApp.couleur;
    final texte = ConcentrationTokens.texteSurFond.couleur;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fond,
      colorScheme: ColorScheme.dark(
        surface: fond,
        onSurface: texte,
        primary: ConcentrationTokens.moduleActif.couleur,
        onPrimary: ConcentrationTokens.fondApp.couleur,
      ),
      fontFamily: policeTexte,
      appBarTheme: AppBarTheme(
        backgroundColor: fond,
        foregroundColor: texte,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: policeTexte,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: texte,
        ),
        bodyMedium: TextStyle(fontFamily: policeTexte, color: texte),
      ),
    );
  }
}
