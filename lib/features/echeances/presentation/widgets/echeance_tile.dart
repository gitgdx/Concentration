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
          decoration: BoxDecoration(
            color: fond.couleur,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le nombre occupe la place disponible et se REDUIT s'il le faut :
                // AC-3 « Limite » exige que 9 tuiles restent embrassables d'un
                // regard, donc sans débordement, quelle que soit la taille de
                // cellule. Un `Text` nu débordait à 9 tuiles — mesuré par T12a.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: Text(
                      '${temps.nombreAffiche}',
                      style: ConcentrationTheme.styleNombre.copyWith(
                        color: avant,
                      ),
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
