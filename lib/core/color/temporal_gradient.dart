import '../theme/concentration_tokens.dart';
import 'oklab.dart';
import 'rgb.dart';

/// Moteur de dégradé temporel (T5) — **implémente ADR-003**.
///
/// Fonctions pures : aucune dépendance à Flutter, aucun token en dur (ils
/// viennent de [ConcentrationTokens], lui-même projection de `DESIGN_SYSTEM.md`).
class TemporalGradient {
  const TemporalGradient();

  /// Couleur de fond pour une progression `p` (RF-04, AC-5).
  ///
  /// `p = 0` rend **exactement** l'orange de référence, `p = 1` **exactement**
  /// le bleu. Entre les deux : interpolation **OKLab cartésienne**, donc jamais
  /// de passage par le rouge.
  Rgb backgroundFor(double p) {
    final t = p.clamp(0.0, 1.0);
    if (t == 0) return ConcentrationTokens.gradientOrange;
    if (t == 1) return ConcentrationTokens.gradientBleu;
    return Oklab.interpoler(
      Oklab.depuisRgb(ConcentrationTokens.gradientOrange),
      Oklab.depuisRgb(ConcentrationTokens.gradientBleu),
      t,
    ).versRgb();
  }

  /// Couleur de texte **choisie** parmi les candidats, celle qui maximise le
  /// contraste sur le fond correspondant à `p` (ADR-003 §5).
  ///
  /// ⛔ **Échoue bruyamment** si aucun candidat n'atteint le seuil demandé : un
  /// dégradé illisible est un **défaut de tokens**, il doit se voir au test et
  /// non à l'usage.
  Rgb foregroundFor(
    double p, {
    double contrasteMin = ConcentrationTokens.contrasteMinTexteNormal,
  }) {
    final fond = backgroundFor(p);
    var meilleur = ConcentrationTokens.texteSurTuileCandidats.first;
    var meilleurContraste = fond.contrasteAvec(meilleur);
    for (final candidat in ConcentrationTokens.texteSurTuileCandidats.skip(1)) {
      final c = fond.contrasteAvec(candidat);
      if (c > meilleurContraste) {
        meilleur = candidat;
        meilleurContraste = c;
      }
    }
    if (meilleurContraste < contrasteMin) {
      throw StateError(
        'Contraste insuffisant sur le dégradé : ${meilleurContraste.toStringAsFixed(2)}:1 '
        'à p=${p.toStringAsFixed(2)} sur le fond ${fond.hex}, seuil requis '
        '${contrasteMin.toStringAsFixed(1)}:1. Défaut de TOKENS (DESIGN_SYSTEM.md), '
        'pas de code : rejouer le calcul de contraste avant de modifier une extrémité.',
      );
    }
    return meilleur;
  }

  /// Contraste effectivement obtenu à `p` — exposé pour que les tests
  /// **mesurent** au lieu de croire.
  double contrasteA(double p) {
    final fond = backgroundFor(p);
    return ConcentrationTokens.texteSurTuileCandidats
        .map(fond.contrasteAvec)
        .reduce((a, b) => a > b ? a : b);
  }
}
