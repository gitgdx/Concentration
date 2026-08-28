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

  /// Taille du nombre sur une tuile **`ACTIVE`** — **valeur du design system**
  /// *(Design UX d'US-01.4 §7.1, inscrite dans `DESIGN_SYSTEM.md` par T16)*.
  ///
  /// 🔴 **POURQUOI CETTE VALEUR EST NOMMÉE ICI, et ce n'est pas un rangement**
  /// *(§G-8)* : elle vivait en **littéral, à l'intérieur d'un `TextStyle`**, et
  /// la table §Typographie de `DESIGN_SYSTEM.md` — qui se déclare **source
  /// unique** — ⛔ **ne donnait AUCUNE valeur** ⇒ **la retouche d'AC-1 se
  /// faisait à l'aveugle.**
  ///
  /// ⛔ **Ne pas dépasser 64 sans rejouer le calcul du Design UX §7.1** : à
  /// 4 tuiles sur 320 dp la boîte de contenu vaut **110 dp** et un nombre à
  /// **3 chiffres** *(le nombre d'années n'est pas borné)* mesure **≈ 115 dp**
  /// à 64 contre **≈ 130 dp** à 72 ⇒ **72 déclencherait `scaleDown` dans un cas
  /// courant**.
  static const double tailleNombre = 64;

  /// Taille du nombre sur une tuile **`ÉCHUE`** — ⛔ **celle d'US-01.1,
  /// INCHANGÉE**, et c'est une décision, pas un reste.
  ///
  /// 🔴 **R-8** : l'échue **conserve sa description affichée en permanence**
  /// *(verdict clarify nº 1 : son « 0 » n'a rien à dire, la description est ce
  /// qui l'identifie)*. Lui appliquer le token agrandi **pousserait sa
  /// description hors de la tuile** ⇒ ⛔ **le nombre agrandi et le centrage sont
  /// réservés aux `ACTIVE`.**
  static const double tailleNombreEchue = 48;

  /// Style du **nombre nu** : élément dominant, chiffres à chasse fixe.
  ///
  /// ⚠️ **La `FontFeature.tabularFigures()` est CONSERVÉE** — et ce qu'elle
  /// garantit exactement : *deux nombres du **même** nombre de chiffres
  /// occupent la même largeur*. ⛔ Elle ne garantit **rien** quand le nombre de
  /// chiffres change ; ce que la mise en page doit à `FittedBox` est une autre
  /// propriété *(Design UX §11.3)*.
  static const TextStyle styleNombre = TextStyle(
    fontFamily: policeNombre,
    fontFamilyFallback: ['monospace'],
    fontSize: tailleNombre,
    fontWeight: FontWeight.w700,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Le style du nombre **selon l'état de la tuile** — ⛔ **deux branches, et
  /// une seule ferait tomber l'un des deux côtés d'AC-1** *(R-8)*.
  ///
  /// ⛔ **Le style échu DÉRIVE du style actif** *(`copyWith`)* : deux
  /// `TextStyle` écrits côte à côte dériveraient sur la police, la graisse ou
  /// la fonction tabulaire — **seule la taille change**, et c'est visible ici.
  static TextStyle styleNombrePour({required bool estEchue}) => estEchue
      ? styleNombre.copyWith(fontSize: tailleNombreEchue)
      : styleNombre;

  /// Description en soutien discret — jamais concurrente du nombre.
  static const TextStyle styleDescription = TextStyle(
    fontFamily: policeTexte,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Courbe de l'animation de disparition (Design UX §7.3).
  ///
  /// ⚖️ **ÉCART ASSUMÉ ET DÉJÀ ARBITRÉ — la table §7 du Design UX la nomme
  /// « token », elle vit dans le THÈME.** C'est **exactement** l'arbitrage de
  /// T6 pour `tailleNombre`, et le Design UX §7 le prévoit lui-même : *« si
  /// c'est refusé, `courbeDisparition` vit dans le thème — ⛔ jamais dans un
  /// widget »* *(J-4)*. **Motif mesuré** : `concentration_tokens.dart`
  /// n'importe **aucune** bibliothèque Flutter, et `Curves` en exige une.
  ///
  /// 🔴 **ACCÉLÉRÉE, et le motif est une propriété du mouvement, pas un goût** :
  /// une sortie **part**. Une courbe **décélérée** ferait **s'attarder** la
  /// tuile — elle dirait *« je m'en vais… ou pas »*.
  /// ⛔ **`elastic*` et `bounce*` sont INTERDITS** *(rebond, dépassement —
  /// RNF-03, AC-8 « Erreur »)*.
  static const Curve courbeDisparition = Curves.easeIn;

  /// Typographie du message d'écriture (Design UX §5.1, §7 — `tailleMessage`).
  ///
  /// ⚖️ **Elle REMONTE ici, et le motif est mesuré** : la table §7 la note
  /// *« remonte — aujourd'hui **en dur** dans `formulaire_echeance.dart` »*.
  /// Elle y vivait à **un** exemplaire pour **un** ton ; le hub en introduit un
  /// second *(§5.1)*, et écrire `14/w500` **deux fois** ferait dériver la règle
  /// — *« deux copies d'un motif dérivent, vérifié trois fois sur ce corpus »*.
  ///
  /// ⛔ **La COULEUR n'est PAS ici** : c'est le seul paramètre que le `ton`
  /// change *(§5.1 — « la COULEUR, et rien d'autre »)*. Un style porteur d'une
  /// couleur par défaut ferait de l'un des deux tons un **cas particulier**, et
  /// le ton oublié rendrait la mauvaise couleur **sans qu'aucune assertion ne
  /// puisse le voir** — la couleur est donc **toujours** apposée par appel.
  static const double tailleMessage = 14;

  /// Style du message, ⛔ **sans couleur** — voir [tailleMessage].
  static const TextStyle styleMessage = TextStyle(
    fontFamily: 'Inter',
    fontSize: tailleMessage,
    fontWeight: FontWeight.w500,
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
