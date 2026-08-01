import '../../../core/time/clock.dart';
import '../domain/echeance.dart';

/// Données d'exemple injectées (T11).
///
/// ⚠️ **Remplacées par la persistance en US-01.2** — aucune écriture disque,
/// aucun CRUD ici.
///
/// Couverture exigée par `MODELE_ECHEANCE.md` : **au moins une échéance par
/// unité** (années, mois, semaines, jours, heures), **une échue**, **une à
/// description vide** (I-3), et **deux de même date** (départage par `id`).
/// ⛔ Le cas « 9 tuiles » et l'état vide relèvent des **tests** : l'application
/// démarre sur un jeu **lisible**, pas sur un cas limite.
class SampleEcheances {
  const SampleEcheances._();

  static List<Echeance> depuis(Clock clock) {
    final maintenant = clock.now();
    return [
      Echeance(
        id: 'projet',
        description: 'Préparation du projet',
        dateEcheance: DateTime(
          maintenant.year + 3,
          maintenant.month,
          maintenant.day,
        ),
      ),
      Echeance(
        id: 'impots',
        description: 'Déclaration des impôts',
        dateEcheance: DateTime(
          maintenant.year,
          maintenant.month + 9,
          maintenant.day,
        ),
      ),
      Echeance(
        id: 'demenagement',
        description: 'Déménagement',
        dateEcheance: maintenant.add(const Duration(days: 21)),
      ),
      Echeance(
        id: 'visite',
        description: 'Visite médicale',
        dateEcheance: maintenant.add(const Duration(days: 3)),
      ),
      Echeance(
        id: 'train',
        description: 'Départ du train',
        dateEcheance: maintenant.add(const Duration(hours: 6)),
      ),
      // I-3 : description VIDE — la tuile reste rendue, seul le nombre s'affiche.
      Echeance(
        id: 'sans-libelle',
        description: '',
        dateEcheance: maintenant.add(const Duration(days: 10)),
      ),
      // I-4 : date PASSÉE — état « à zéro », remonte EN TÊTE de la grille.
      Echeance(
        id: 'echue',
        description: 'Renouvellement de passeport',
        dateEcheance: maintenant.subtract(const Duration(days: 2)),
      ),
      // Deux échéances de MÊME date : le départage par `id` les rend stables.
      Echeance(
        id: 'a-meme-date',
        description: 'Rendez-vous',
        dateEcheance: maintenant.add(const Duration(days: 5)),
      ),
      Echeance(
        id: 'b-meme-date',
        description: 'Appel téléphonique',
        dateEcheance: maintenant.add(const Duration(days: 5)),
      ),
    ];
  }
}
