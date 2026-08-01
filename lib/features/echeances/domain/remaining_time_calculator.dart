import '../../../core/time/clock.dart';
import 'echeance.dart';
import 'remaining_time.dart';
import 'time_unit.dart';

/// Moteur d'unité adaptative (T4) — **implémente ADR-002**.
///
/// Fonction pure : `(Clock, Echeance) -> RemainingTime`. Aucune dépendance à
/// Flutter, aucun `DateTime.now()` interne.
///
/// Règle unique dont découlent les quatre exemples du PRD : on **choisit
/// l'unité par seuils**, puis on prend le **plus petit `n`** tel que
/// `maintenant + n unités >= cible` (c'est le `ceil` de RF-03).
class RemainingTimeCalculator {
  const RemainingTimeCalculator();

  RemainingTime calculer({required Clock clock, required Echeance echeance}) {
    final maintenant = clock.now();
    final cible = echeance.dateEcheance;
    final suffixe = echeance.description.isEmpty
        ? ''
        : ', ${echeance.description}';

    // T <= 0 : état d'affichage NORMAL, pas une erreur (AC-7).
    if (!cible.isAfter(maintenant)) {
      return RemainingTime(
        unite: TimeUnit.heures,
        nombreAffiche: 0,
        progression: 1,
        estEchue: true,
        libelleAccessibilite: 'échéance atteinte$suffixe',
      );
    }

    final unite = _choisirUnite(maintenant, cible);
    final nombre = _plafond(maintenant, cible, unite);

    // Les deux instants qui ENCADRENT le changement de nombre (ADR-002 §4) :
    // le nombre a pris sa valeur en tPrecedent, il changera en tSuivant.
    final tPrecedent = _ajouter(cible, -nombre, unite);
    final tSuivant = _ajouter(cible, -(nombre - 1), unite);

    return RemainingTime(
      unite: unite,
      nombreAffiche: nombre,
      progression: _progression(maintenant, tPrecedent, tSuivant),
      estEchue: false,
      libelleAccessibilite: '$nombre ${unite.libelle(nombre)}$suffixe',
    );
  }

  /// Seuils de RF-02. La bascule jours -> heures se fait **exactement à 24 h**
  /// (AC-4).
  TimeUnit _choisirUnite(DateTime maintenant, DateTime cible) {
    if (!cible.isBefore(_ajouterMois(maintenant, 12))) return TimeUnit.annees;
    if (!cible.isBefore(_ajouterMois(maintenant, 1))) return TimeUnit.mois;
    final restant = cible.difference(maintenant);
    if (restant >= const Duration(days: 7)) return TimeUnit.semaines;
    if (restant >= const Duration(hours: 24)) return TimeUnit.jours;
    return TimeUnit.heures;
  }

  /// Plus petit `n >= 1` tel que `maintenant + n unités >= cible`.
  ///
  /// L'estimation initiale n'a pas besoin d'être juste : les deux boucles de
  /// recalage la corrigent, ce qui rend le résultat indépendant des
  /// approximations de durée.
  int _plafond(DateTime maintenant, DateTime cible, TimeUnit unite) {
    final restant = cible.difference(maintenant);
    var n = switch (unite) {
      TimeUnit.annees => (restant.inDays / 365).ceil(),
      TimeUnit.mois => (restant.inDays / 30).ceil(),
      TimeUnit.semaines => (restant.inDays / 7).ceil(),
      TimeUnit.jours => (restant.inHours / 24).ceil(),
      TimeUnit.heures => (restant.inMinutes / 60).ceil(),
    };
    if (n < 1) n = 1;
    while (_ajouter(maintenant, n, unite).isBefore(cible)) {
      n++;
    }
    while (n > 1 && !_ajouter(maintenant, n - 1, unite).isBefore(cible)) {
      n--;
    }
    return n;
  }

  /// Deux régimes assumés (ADR-002 §3) : **calendaire** pour ans/mois,
  /// **durée absolue** pour semaines/jours/heures.
  DateTime _ajouter(DateTime instant, int n, TimeUnit unite) => switch (unite) {
    TimeUnit.annees => _ajouterMois(instant, 12 * n),
    TimeUnit.mois => _ajouterMois(instant, n),
    TimeUnit.semaines => instant.add(Duration(days: 7 * n)),
    TimeUnit.jours => instant.add(Duration(days: n)),
    TimeUnit.heures => instant.add(Duration(hours: n)),
  };

  /// Arithmétique calendaire réelle (RNF-05), avec **écrêtage du jour** : le
  /// 31 janvier + 1 mois donne le 28 (ou 29) février, jamais le 2 mars.
  DateTime _ajouterMois(DateTime instant, int n) {
    final totalMois = instant.month - 1 + n;
    final annee = instant.year + (totalMois / 12).floor();
    final mois = totalMois % 12 + 1;
    final dernierJour = DateTime(annee, mois + 1, 0).day;
    final jour = instant.day <= dernierJour ? instant.day : dernierJour;
    return DateTime(
      annee,
      mois,
      jour,
      instant.hour,
      instant.minute,
      instant.second,
      instant.millisecond,
      instant.microsecond,
    );
  }

  double _progression(
    DateTime maintenant,
    DateTime tPrecedent,
    DateTime tSuivant,
  ) {
    final total = tSuivant.difference(tPrecedent).inMicroseconds;
    if (total <= 0) return 1;
    final ecoule = maintenant.difference(tPrecedent).inMicroseconds;
    return (ecoule / total).clamp(0.0, 1.0);
  }
}
