/// Outillage de **lecture du rendu**, partagé par les tests de widgets.
///
/// ⛔ **Un exemplaire, un seul.** Ces quatre helpers allaient être recopiés dans
/// trois fichiers de test ; deux copies d'un même motif **dérivent** — le projet
/// l'a vérifié trois fois. Ils vivent ici et nulle part ailleurs.
///
/// ⚠️ Ce fichier n'est **pas** un fichier de test (`*_test.dart`) : il n'est pas
/// exécuté par `flutter test`, il est importé.
library;

import 'package:concentration/core/color/oklab.dart';
import 'package:concentration/core/color/rgb.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Inverse de `RgbVersColor` — **réservé aux tests**.
///
/// La frontière `Rgb -> Color` est unique et vit dans `lib/` (`rgb_extension`).
/// Le chemin retour n'existe que pour **assertionner** une couleur observée dans
/// l'arbre de widgets : il n'a rien à faire dans le produit.
Rgb rgbDe(Color couleur) => Rgb(
  (couleur.r * 255).round(),
  (couleur.g * 255).round(),
  (couleur.b * 255).round(),
);

/// Clarté OKLab (`L`) d'une couleur **observée dans le rendu**.
double clarteDe(Color couleur) => Oklab.depuisRgb(rgbDe(couleur)).l;

/// Couleur de fond **réellement peinte** par une tuile.
///
/// Sans ce point d'observation, « la couleur de fond de la tuile est bleue »
/// restait une étape Gherkin décorative : le test comparait une valeur
/// **recalculée à côté**, jamais celle que la tuile rend.
Color fondDeLaTuile(WidgetTester tester, {Finder? tuile}) {
  final cible = tuile ?? find.byType(EcheanceTile).first;
  final boite = tester.widget<DecoratedBox>(
    find.descendant(of: cible, matching: find.byType(DecoratedBox)).first,
  );
  return (boite.decoration as BoxDecoration).color!;
}

/// Couleur **explicitement appliquée** au libellé `libelle`.
///
/// ⚠️ « Concentration » est **à la fois** le titre de l'application et le nom
/// d'un module futur. Le titre de l'`AppBar` ne porte **aucun style propre** (il
/// hérite du thème) : ne retenir que les libellés portant une couleur
/// **explicite** lève la collision — sans jamais désigner un widget par sa
/// position dans l'arbre, qui glisserait en silence.
Color couleurDuLibelle(WidgetTester tester, String libelle) {
  final couleurs = tester
      .widgetList<Text>(find.text(libelle))
      .map((t) => t.style?.color)
      .whereType<Color>()
      .toSet();
  expect(
    couleurs,
    hasLength(1),
    reason:
        'un seul libellé PORTANT UNE COULEUR explicite est attendu pour '
        '« $libelle » — sinon l\'assertion de couleur ne désigne rien',
  );
  return couleurs.single;
}
