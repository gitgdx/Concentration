import 'package:concentration/core/color/rgb.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrastes des tokens d'US-01.2 — **dans le job REQUIS** (T9).
///
/// ⚖️ **Ce fichier REMPLACE `docs/design/us_01_2_contrastes.py`, qui est
/// SUPPRIMÉ dans le même commit.** *« Une règle n'existe qu'en un seul
/// exemplaire ; deux copies dérivent »* — vérifié trois fois sur ce corpus. Le
/// script était un **instrument de conception à durée de vie bornée** ; la
/// règle vit désormais là où un gate la voit.
///
/// ⛔ **Les ratios ne sont PAS recopiés** : ils sont **calculés** par
/// `Rgb.contrasteAvec`, la même formule que celle du produit. Un seuil recopié
/// périmerait au premier changement de token — c'est la classe de défaut nº 1
/// du projet.
///
/// ⚠️ **Borne NM-7, non levée** : le contraste est **CALCULÉ**, ⛔ jamais **VU**.
void main() {
  const normal = ConcentrationTokens.contrasteMinTexteNormal;
  const nonTextuel = ConcentrationTokens.contrasteMinTexteLarge;

  final fondApp = ConcentrationTokens.fondApp;
  final surfaceElevee = ConcentrationTokens.surfaceElevee;
  final texteSurFond = ConcentrationTokens.texteSurFond;
  final texteSecondaire = ConcentrationTokens.texteSecondaire;
  final erreur = ConcentrationTokens.erreur;
  final moduleActif = ConcentrationTokens.moduleActif;
  final moduleGrise = ConcentrationTokens.moduleGrise;
  final contour = ConcentrationTokens.contour;

  group('couples EXIGÉS — le seuil doit être ATTEINT', () {
    final exiges = <String, (Rgb, Rgb, double)>{
      'texteSurFond / fondApp': (texteSurFond, fondApp, normal),
      'texteSurFond / surfaceElevee': (texteSurFond, surfaceElevee, normal),
      'texteSecondaire / fondApp': (texteSecondaire, fondApp, normal),
      'texteSecondaire / surfaceElevee': (
        texteSecondaire,
        surfaceElevee,
        normal,
      ),
      'erreur / fondApp': (erreur, fondApp, normal),
      'erreur / surfaceElevee': (erreur, surfaceElevee, normal),
      'fondApp / moduleActif (texte du bouton plein)': (
        fondApp,
        moduleActif,
        normal,
      ),
      'moduleActif / fondApp (focus, icone active)': (
        moduleActif,
        fondApp,
        nonTextuel,
      ),
      'moduleActif / surfaceElevee (focus sur champ)': (
        moduleActif,
        surfaceElevee,
        nonTextuel,
      ),
      'contour / fondApp': (contour, fondApp, nonTextuel),
      'contour / surfaceElevee': (contour, surfaceElevee, nonTextuel),
    };

    exiges.forEach((nom, couple) {
      test(nom, () {
        final (avant, fond, seuil) = couple;
        expect(
          avant.contrasteAvec(fond),
          greaterThanOrEqualTo(seuil),
          reason: '$nom : ${avant.hex} sur ${fond.hex}',
        );
      });
    });
  });

  group('couples REFUSÉS — le CONTRÔLE NÉGATIF, il porte deux décisions', () {
    // ⛔ Sans ce groupe, une suite qui rougirait sur TOUT passerait pour
    // excellente. Chaque ligne ci-dessous doit rester SOUS son seuil : si l'un
    // d'eux passait, c'est que les tokens ont changé et que la décision qui les
    // a écartés doit être rejouée.
    test(
      '`outline-variant` de la maquette est ÉCARTÉ, et il doit le rester',
      () {
        final ecarte = Rgb.hex('#564338');
        expect(
          ecarte.contrasteAvec(fondApp),
          lessThan(nonTextuel),
          reason:
              'une bordure qui IDENTIFIE un composant est soumise à '
              'SC 1.4.11 — ce token ne peut pas la porter',
        );
      },
    );

    test('`texteSecondaire` à 40 % d’opacité est INTERDIT', () {
      // Composition en sRGB (gamma), hypothèse écrite du §6.5 : la couleur
      // effective est la moyenne pondérée des composantes 8 bits.
      Rgb composer(Rgb avant, Rgb fond, double alpha) => Rgb(
        (avant.r * alpha + fond.r * (1 - alpha)).round(),
        (avant.g * alpha + fond.g * (1 - alpha)).round(),
        (avant.b * alpha + fond.b * (1 - alpha)).round(),
      );
      final compose = composer(texteSecondaire, fondApp, 0.4);
      expect(
        compose.contrasteAvec(fondApp),
        lessThan(normal),
        reason:
            'une opacité FABRIQUE une couleur dont personne n’a calculé le '
            'contraste — et elle frapperait le groupe des échues, celui '
            'qu’il faut rendre ÉVIDENT',
      );
    });

    test('`moduleGrise` ne peut porter NI texte NI commande interactive', () {
      expect(moduleGrise.contrasteAvec(fondApp), lessThan(normal));
      expect(
        moduleGrise.contrasteAvec(fondApp),
        lessThan(nonTextuel),
        reason:
            'c’est pourquoi la commande « Gérer les échéances », devenue '
            'INTERACTIVE, passe à moduleActif (AC-1)',
      );
    });
  });

  group('constats « jamais la couleur seule » (SC 1.4.1)', () {
    test('erreur, moduleActif et texteSecondaire sont INDISCERNABLES', () {
      // ⚠️ Assertion de GRANDEUR : ces trois tokens ont une luminance quasi
      // identique ⇒ un message d'erreur doit porter UN MOT et UN SIGNE, un
      // état « indisponible » doit porter UN MOT. La couleur ne peut RIEN
      // porter seule ici, et c'est une conséquence arithmétique, pas un avis.
      for (final couple in [
        (erreur, moduleActif),
        (erreur, texteSecondaire),
        (texteSecondaire, moduleActif),
      ]) {
        expect(
          couple.$1.contrasteAvec(couple.$2),
          lessThan(1.1),
          reason:
              '${couple.$1.hex} et ${couple.$2.hex} ne sont pas '
              'séparables par la luminance',
        );
      }
    });
  });
}
