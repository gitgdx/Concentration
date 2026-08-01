/// Unités internes du temps restant (RF-02).
///
/// ⛔ Ces unités n'apparaissent **jamais** à l'écran (RF-01) : elles n'existent
/// que dans le calcul et dans le libellé d'accessibilité (AC-8).
enum TimeUnit {
  annees,
  mois,
  semaines,
  jours,
  heures;

  /// Libellé français accordé en nombre — **uniquement** pour le lecteur
  /// d'écran. Produit en français, seule langue du produit.
  String libelle(int nombre) {
    final pluriel = nombre > 1;
    switch (this) {
      case TimeUnit.annees:
        return pluriel ? 'ans' : 'an';
      case TimeUnit.mois:
        return 'mois';
      case TimeUnit.semaines:
        return pluriel ? 'semaines' : 'semaine';
      case TimeUnit.jours:
        return pluriel ? 'jours' : 'jour';
      case TimeUnit.heures:
        return pluriel ? 'heures' : 'heure';
    }
  }
}
