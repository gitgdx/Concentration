import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';

/// Données d'exemple — ⚖️ **DÉPLACÉES de `lib/` vers `test/` par US-01.2 (T11)**.
///
/// 🔴 **Elles ne sont plus DANS LE PRODUIT, et c'est tout l'objet d'AC-13** :
/// *« sur une installation neuve, la grille affiche l'état vide — ⛔ JAMAIS des
/// échéances d'exemple »*. Tant qu'elles vivaient dans `lib/`, l'état vide
/// spécifié par US-01.1 était **inatteignable**.
///
/// ⚠️ **Elles restent ici pour une raison précise** : le scénario *« aucune
/// échéance d'exemple ne figure sur la grille »* a besoin de **NOMMER** une
/// description du jeu d'exemple pour exiger `findsNothing`. Une assertion qui
/// n'aurait aucun exemple à citer serait **vraie quoi qu'il arrive**.
///
/// Couverture exigée par `MODELE_ECHEANCE.md` : **au moins une échéance par
/// unité** (années, mois, semaines, jours, heures), **une échue**, **une à
/// description vide** (I-3), et **deux de même date** (départage par `id`).
/// ⛔ Le cas « 9 tuiles » et l'état vide relèvent des **tests** : l'application
/// démarre sur un jeu **lisible**, pas sur un cas limite.
class EcheancesExemple {
  const EcheancesExemple._();

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
