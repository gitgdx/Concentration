import 'package:flutter/material.dart';

import '../../../../core/color/temporal_gradient.dart';
import '../../../../core/theme/concentration_theme.dart';
import '../../../../core/theme/rgb_extension.dart';
import '../../domain/remaining_time.dart';

/// Tuile d'échéance (T7).
///
/// ⛔ **Le nombre est NU** : aucune unité, aucune fraction, aucun signe (RF-01).
/// L'unité n'existe que dans [RemainingTime.libelleAccessibilite], porté par
/// `Semantics` — c'est le seul endroit où elle devient un mot (AC-8).
class EcheanceTile extends StatelessWidget {
  const EcheanceTile({
    required this.temps,
    required this.description,
    super.key,
    this.gradient = const TemporalGradient(),
  });

  /// 🔴 **NB-7 (T7) — LA BOÎTE QUI PORTE LE FOND SE DÉSIGNE PAR SON IDENTITÉ,
  /// ⛔ JAMAIS PAR SA POSITION.**
  ///
  /// **Défaut DÉMONTRÉ, pas supposé** *(sonde d'US-01.2)* : quand **deux**
  /// boîtes décorées se retrouvent sous la tuile, un sélecteur en `.first`
  /// désigne l'**extérieure** ⇒ la tuile pouvait rendre **toujours orange** avec
  /// **112 tests VERTS**. La clé rend la cible **non ambiguë**, et
  /// ⛔ **l'assertion d'unicité reste** — sur la clé, désormais.
  ///
  /// ⚠️ **Cette constante est dans le produit et consommée par les tests, et
  /// c'est ASSUMÉ** : une clé est une propriété de l'**arbre de widgets**, et
  /// l'alternative — un nom de type ou une position — est **précisément** ce qui
  /// a produit le faux vert.
  static const Key cleFond = Key('echeance-tile-fond');

  final RemainingTime temps;
  final String description;
  final TemporalGradient gradient;

  @override
  Widget build(BuildContext context) {
    final fond = gradient.backgroundFor(temps.progression);
    // foregroundFor ÉCHOUE BRUYAMMENT si aucun token n'atteint le seuil : c'est
    // voulu (ADR-003 §5), un dégradé illisible est un défaut de tokens.
    final avant = gradient.foregroundFor(temps.progression).couleur;

    return Semantics(
      label: temps.libelleAccessibilite,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: cleFond,
          decoration: BoxDecoration(
            color: fond.couleur,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              // 🔴 AC-1 (T6) — LE CADRAN CONTRE L'ÉTIQUETTE, et ⛔ sur les
              // `ACTIVE` SEULEMENT (R-8). Une échue conserve sa description
              // affichée sous son « 0 » : la centrer et grossir son nombre
              // pousserait cette description hors de la tuile.
              // ⛔ Les DEUX alignements comptent : celui-ci place le nombre sur
              // l'axe HORIZONTAL, celui du `FittedBox` sur le VERTICAL. En
              // changer un seul laisse le nombre à moitié en haut à gauche.
              crossAxisAlignment: temps.estEchue
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                // Le nombre occupe la place disponible et se REDUIT s'il le faut :
                // AC-3 « Limite » exige que 9 tuiles restent embrassables d'un
                // regard, donc sans débordement, quelle que soit la taille de
                // cellule. Un `Text` nu débordait à 9 tuiles — mesuré par T12a.
                Expanded(
                  child: FittedBox(
                    // ⛔ `BoxFit.contain` est INTERDIT (§G-7) : il AGRANDIT
                    // jusqu'à remplir, donc la taille du glyphe dépendrait du
                    // NOMBRE DE CHIFFRES — au rafraîchissement, `10 → 9`
                    // doublerait le chiffre sous les yeux du pratiquant, et
                    // 9 tuiles porteraient 9 tailles différentes.
                    // ✅ La taille s'augmente dans le TOKEN ; `scaleDown` reste
                    // le FILET qui a fermé le débordement à 9 tuiles.
                    fit: BoxFit.scaleDown,
                    alignment: temps.estEchue
                        ? Alignment.topLeft
                        : Alignment.center,
                    child: Text(
                      '${temps.nombreAffiche}',
                      style: ConcentrationTheme.styleNombrePour(
                        estEchue: temps.estEchue,
                      ).copyWith(color: avant),
                    ),
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ConcentrationTheme.styleDescription.copyWith(
                      color: avant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
