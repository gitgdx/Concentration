import 'package:flutter/material.dart';

import '../../../../core/theme/concentration_tokens.dart';
import '../../../../core/theme/rgb_extension.dart';
import '../../../../core/time/clock.dart';
import '../../domain/echeance.dart';
import '../../domain/remaining_time_calculator.dart';

const List<String> _moisFrancais = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// `15 mars 2027` — ⛔ **jamais `Oct 24, 2024`** *(anglais, et ordre mois/jour
/// ambigu pour un lecteur francophone)*.
///
/// ⛔ **UN SEUL EXEMPLAIRE** : la confirmation de suppression consomme la même
/// fonction, elle ne la réécrit pas.
String dateLisible(DateTime d) =>
    '${d.day} ${_moisFrancais[d.month - 1]} ${d.year}';

/// `23:59` — 24 h, zéro initial.
String heureLisible(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Carte d'échéance de la page de gestion — composant **C-1** (T9).
///
/// 🔴 **R-9 — ⛔ AUCUN CALCUL DE DURÉE ICI.** Le temps restant est
/// `nombreAffiche` + `unite.libelle(nombreAffiche)`, c'est-à-dire **exactement
/// ce que le moteur d'US-01.1 a produit**. Un second mode de calcul serait une
/// **fabrique à divergences** — la maquette affichait « 14 days left », hors
/// unité adaptative.
///
/// ⚠️ **Écart signalé par @UXDesigner (§4.2), et il est tenu** : la chaîne
/// `libelleAccessibilite` **embarque `', $description'`**, donc l'afficher
/// verbatim **dupliquerait la description** dans la carte. Elle est donc portée
/// **entière** par le `Semantics` — ce pour quoi elle a été écrite — et la
/// carte, elle, n'affiche que le nombre et l'unité.
class LigneEcheance extends StatelessWidget {
  const LigneEcheance({
    required this.echeance,
    required this.clock,
    required this.onModifier,
    required this.onSupprimer,
    super.key,
    this.calculateur = const RemainingTimeCalculator(),
  });

  final Echeance echeance;
  final Clock clock;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  final RemainingTimeCalculator calculateur;

  @override
  Widget build(BuildContext context) {
    final temps = calculateur.calculer(clock: clock, echeance: echeance);
    // ⛔ « Échéance atteinte » est un MOT, pas une teinte : l'état échu ne peut
    // pas reposer sur la couleur seule (SC 1.4.1, §6.4).
    final tempsRestant = temps.estEchue
        ? 'Échéance atteinte'
        : '${temps.nombreAffiche} ${temps.unite.libelle(temps.nombreAffiche)}';
    // AC-8 « Erreur » : une description VIDE ne masque pas la carte — la date
    // monte en ligne de titre. ⛔ Jamais une ligne de titre vide.
    final titre = echeance.description.isEmpty
        ? dateLisible(echeance.dateEcheance)
        : echeance.description;
    final designation = echeance.description.isEmpty
        ? 'l’échéance du ${dateLisible(echeance.dateEcheance)}'
        : echeance.description;

    return Semantics(
      container: true,
      label: temps.libelleAccessibilite,
      child: Container(
        key: ValueKey('ligne-${echeance.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ConcentrationTokens.surfaceElevee.couleur,
          borderRadius: BorderRadius.circular(16),
          // 🔴 SECONDE marque de l'état échu, à côté du MOT « Échéance
          // atteinte » — ⛔ l'état ne repose jamais sur la couleur seule.
          // ⚖️ **Écart nommé avec le wireframe** *(qui dessine un liseré
          // GAUCHE de 2 dp)* : Flutter **interdit** un `Border` non uniforme
          // avec un `borderRadius`, et le rayon 16 est une exigence du design
          // *(« même valeur que la tuile — une seule identité de surface »)*.
          // La marque devient donc une **bordure de 2 dp sur toute la carte**,
          // qui reste **mesurable** et **non colorimétrique**.
          border: Border.all(
            color: ConcentrationTokens.contour.couleur,
            width: temps.estEchue ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ConcentrationTokens.texteSurFond.couleur,
              ),
            ),
            Text(
              '${dateLisible(echeance.dateEcheance)} · '
              '${heureLisible(echeance.dateEcheance)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: ConcentrationTokens.texteSecondaire.couleur,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tempsRestant,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ConcentrationTokens.texteSecondaire.couleur,
                    ),
                  ),
                ),
                // 🔴 L'affordance ✎ est PRÉSENTE ET ACTIVABLE même sur une
                // échue : la retirer rendrait le scénario « je TENTE de
                // modifier cette échéance » INOBSERVABLE (§4.3).
                _Action(
                  icone: Icons.edit,
                  libelle: 'Modifier $designation',
                  onPressed: onModifier,
                ),
                const SizedBox(width: 8),
                _Action(
                  icone: Icons.delete_outline,
                  libelle: 'Supprimer $designation',
                  onPressed: onSupprimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cible tactile **≥ 48 × 48 dp** (A-4), au nom accessible **qui NOMME
/// l'échéance** (A-12) — à 9 cartes, neuf boutons « Modifier » sont neuf
/// boutons indistinguables.
class _Action extends StatelessWidget {
  const _Action({
    required this.icone,
    required this.libelle,
    required this.onPressed,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: libelle,
        icon: Icon(icone, color: ConcentrationTokens.texteSecondaire.couleur),
      ),
    );
  }
}
