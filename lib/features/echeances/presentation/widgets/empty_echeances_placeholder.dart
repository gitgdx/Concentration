import 'package:flutter/material.dart';

import '../../../../core/theme/concentration_tokens.dart';
import '../../../../core/theme/rgb_extension.dart';

/// État vide de la grille (T8 / AC-9).
///
/// ⛔ Message **sobre** : aucun rouge, aucune couleur d'urgence, aucune
/// gamification, aucune erreur technique (RNF-03, AC-9 « Erreur »). Le hub et sa
/// structure restent affichés — seule la zone de grille change.
class EmptyEcheancesPlaceholder extends StatelessWidget {
  const EmptyEcheancesPlaceholder({super.key});

  /// Texte en **français**, seule langue du produit.
  static const String message = "Aucune échéance pour l'instant.";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: ConcentrationTokens.texteSurFond.couleur,
          ),
        ),
      ),
    );
  }
}
