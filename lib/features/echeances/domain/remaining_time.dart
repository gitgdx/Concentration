import 'time_unit.dart';

/// Résultat **immuable** du calcul de temps restant (T2).
///
/// Le widget ne recalcule rien : il consomme un résultat prêt.
/// ⛔ Ce type n'est **pas persistable** — le stocker le rendrait faux à la
/// seconde suivante (`docs/architecture/MODELE_ECHEANCE.md`).
class RemainingTime {
  const RemainingTime({
    required this.unite,
    required this.nombreAffiche,
    required this.progression,
    required this.estEchue,
    required this.libelleAccessibilite,
  });

  /// Unité retenue — jamais rendue visuellement (RF-01).
  final TimeUnit unite;

  /// Entier affiché : `ceil` du temps restant dans [unite] (RF-03). `0` si échue.
  final int nombreAffiche;

  /// Proximité du **prochain changement de nombre**, dans `[0;1]` (RF-04).
  ///
  /// `0` = le nombre vient de changer (loin du prochain) ⇒ orange ;
  /// `1` = changement imminent ⇒ bleu. ⛔ Ne dépend **ni** de la grandeur du
  /// nombre, **ni** de l'urgence de l'échéance (AC-5).
  final double progression;

  /// `T <= 0` — état d'affichage **normal**, pas une erreur (AC-7).
  final bool estEchue;

  /// Temps complet **avec** son unité, pour le lecteur d'écran (AC-8).
  /// Seul endroit du produit où l'unité devient un mot.
  final String libelleAccessibilite;

  @override
  bool operator ==(Object other) =>
      other is RemainingTime &&
      other.unite == unite &&
      other.nombreAffiche == nombreAffiche &&
      other.progression == progression &&
      other.estEchue == estEchue &&
      other.libelleAccessibilite == libelleAccessibilite;

  @override
  int get hashCode => Object.hash(
    unite,
    nombreAffiche,
    progression,
    estEchue,
    libelleAccessibilite,
  );
}
