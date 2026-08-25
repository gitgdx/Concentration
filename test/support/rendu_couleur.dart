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
///
/// 🔴 **CORRECTIF NB-7, DEUXIÈME ÉTAT (US-01.4, T7) — LA BOÎTE SE DÉSIGNE PAR
/// SON IDENTITÉ.** La sélection porte sur [EcheanceTile.cleFond], ⛔ **jamais
/// sur un type ni sur une position**, et ⛔ **l'assertion d'unicité RESTE** —
/// elle porte désormais sur la **clé**, ce qui la rend vraie *même* quand une
/// seconde boîte décorée apparaît sous la tuile.
///
/// ⚖️ **PÉRIMÉ-2026-08-25 — l'état PRÉCÉDENT de cette documentation est
/// conservé, et il était PLUS LARGE QUE LE FAIT** *(on date, on ne repeint
/// pas)* : *« US-01.2 rend le défaut IMMINENT : ses cartes, champs et boutons
/// introduisent des `Material`, `InkWell` et `Container`, qui en apportent tous
/// une seconde. »*
///
/// 🔬 **CE QUI EST, MESURÉ dans les sources du SDK (Flutter 3.44.7)** :
/// `grep -n "DecoratedBox"` dans `material/ink_well.dart` et
/// `material/material.dart` ne rend que des **commentaires de documentation** ⇒
/// ⛔ **ni `Material` ni `InkWell` n'en insèrent une**. **Le seul widget qui en
/// INSÈRE réellement une est `Container` porteur d'une `decoration`**
/// *(`widgets/container.dart`, deux sites)*, et `FocusableActionDetector` en
/// insère **0** *(mesuré)*. ⇒ ⛔ **un `GestureDetector` seul n'ajoute rien**, et
/// ⛔ **`find.byType` compare le type EXACT**, jamais une sous-classe.
///
/// ⚠️ **Le déclenchement ⛔ ne s'affirme donc pas — il se MESURE** : un anneau
/// de focus fait d'un `Container(decoration:)` ou d'un `DecoratedBox` en ajoute
/// une ; un anneau peint par un `CustomPaint`, une `FadeTransition` ou une
/// `ScaleTransition` n'en ajoutent **aucune**. **Le juge est la sortie de
/// `echeance_tile_test.dart`**, ⛔ pas ce commentaire.
///
/// 🔴 **Le défaut fermé ici est DÉMONTRÉ et REJOUÉ** *(sonde d'US-01.2, rendue
/// exécutable par `rendu_couleur_test.dart`)* : avec deux boîtes décorées, un
/// sélecteur en `.first` lisait l'**extérieure** ⇒ la tuile pouvait rendre
/// **toujours orange** avec **112 tests verts**.
Color fondDeLaTuile(WidgetTester tester, {Finder? tuile}) {
  final cible = tuile ?? find.byType(EcheanceTile).first;
  final boites = find.descendant(
    of: cible,
    matching: find.byKey(EcheanceTile.cleFond),
  );
  expect(
    boites,
    findsOneWidget,
    reason:
        'NB-7 : la boîte du fond se désigne par SA CLÉ. Zéro ⇒ la clé a été '
        'retirée du produit et l’observation ne porte plus sur rien ; '
        'plusieurs ⇒ la cible est ambiguë et « la première » désignerait '
        'peut-être la mauvaise — le faux vert que rien d’autre ne verrait',
  );
  final boite = tester.widget<DecoratedBox>(boites);
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
