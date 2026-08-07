import 'package:flutter/material.dart';

import '../../../core/theme/concentration_tokens.dart';
import '../../../core/theme/rgb_extension.dart';
import '../../../core/time/clock.dart';
import '../domain/echeance.dart';
import 'echeances_notifier.dart';
import 'widgets/confirmation_suppression.dart';
import 'widgets/formulaire_echeance.dart';
import 'widgets/ligne_echeance.dart';

/// Page de gestion (T10) — **une ROUTE, ⛔ pas un onglet**, et elle ne porte
/// **PAS la barre basse**.
///
/// *Motif* : le scénario « Ouvrir la gestion ne rend pas interactifs les
/// modules grisés » vérifie les modules **sur le hub, après retour**. Dupliquer
/// la barre ici ferait **deux exemplaires d'un composant** et **rouvrirait le
/// risque de débordement du `Row`**, déjà payé une fois (63 px à 390 de large).
class GestionEcheancesPage extends StatelessWidget {
  const GestionEcheancesPage({
    required this.notifier,
    required this.clock,
    super.key,
  });

  final EcheancesNotifier notifier;
  final Clock clock;

  static const String titre = 'Gérer les échéances';

  Future<void> _ouvrirFormulaire(BuildContext context, [Echeance? original]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FormulaireEcheance(notifier: notifier, original: original),
      ),
    );
  }

  Future<void> _confirmerSuppression(BuildContext context, Echeance cible) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          ConfirmationSuppression(echeance: cible, notifier: notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(titre)),
      body: Semantics(
        namesRoute: true,
        label: titre,
        child: ListenableBuilder(
          listenable: notifier,
          builder: (context, _) {
            final maintenant = clock.now();
            // AC-8 « Nominal » — actives par date CROISSANTE (RF-07)...
            final actives =
                notifier.echeances
                    .where((e) => e.dateEcheance.isAfter(maintenant))
                    .toList()
                  ..sort();
            // ...et échues de la plus RÉCEMMENT échue à la plus ancienne : la
            // consultation d'un historique va du récent vers l'ancien.
            final echues =
                notifier.echeances
                    .where((e) => !e.dateEcheance.isAfter(maintenant))
                    .toList()
                  ..sort((a, b) => b.compareTo(a));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AffordanceAjout(
                  notifier: notifier,
                  onPressed: () => _ouvrirFormulaire(context),
                ),
                if (actives.isEmpty && echues.isEmpty) const _EtatVide(),
                if (actives.isNotEmpty) ...[
                  _TitreGroupe(libelle: 'Actives', nombre: actives.length),
                  for (final e in actives) _ligne(context, e),
                ],
                if (echues.isNotEmpty) ...[
                  _TitreGroupe(libelle: 'Échues', nombre: echues.length),
                  for (final e in echues) _ligne(context, e),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, Echeance echeance) => LigneEcheance(
    echeance: echeance,
    clock: clock,
    // 🔴 L'affordance ✎ d'une ÉCHUE est PRÉSENTE ET ACTIVABLE : son activation
    // n'ouvre pas le formulaire, elle affiche le REFUS. La retirer rendrait
    // « je TENTE de modifier cette échéance » inobservable.
    onModifier: () {
      final refus = notifier.validation.refusEditionEchue(echeance);
      if (refus == null) {
        _ouvrirFormulaire(context, echeance).ignore();
        return;
      }
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: ConcentrationTokens.surfaceElevee.couleur,
          content: MessageValidation(texte: refus.message),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ).ignore();
      // ⛔ `.ignore()` : l'ouverture d'une route n'a pas d'issue à traiter, et
      // `unawaited_futures` est activé. ⚠️ Sa portée est PARTIELLE (aveugle
      // dans un appelant synchrone) — ce n'est donc PAS lui qui protège les
      // écritures : c'est le REFUS TYPÉ du port.
    },
    onSupprimer: () => _confirmerSuppression(context, echeance).ignore(),
  );
}

/// AC-1 « Erreur » — l'état vide **de la gestion**, ⛔ distinct de celui de la
/// grille.
///
/// La grille dit *« Aucune échéance pour l'instant. »* : c'est une surface de
/// **pratique**, sans action. La gestion est un **outil**, elle porte une
/// action ⇒ **elle invite**. ⛔ Ne pas « harmoniser » les deux textes : ce sont
/// deux messages pour deux surfaces, ⛔ pas deux copies d'une même règle.
class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Aucune échéance enregistrée.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: ConcentrationTokens.texteSurFond.couleur,
            ),
          ),
          Text(
            'Ajoutez-en une pour commencer votre revue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: ConcentrationTokens.texteSecondaire.couleur,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitreGroupe extends StatelessWidget {
  const _TitreGroupe({required this.libelle, required this.nombre});

  final String libelle;
  final int nombre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        '$libelle · $nombre',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ConcentrationTokens.texteSecondaire.couleur,
        ),
      ),
    );
  }
}

/// 🔴 **⛔ AUCUNE BARRIÈRE MUETTE** (clarify nº 3 : *« indication, pas
/// barrière »*).
///
/// À 9 présentes, l'affordance change d'apparence *(plein → contour)* et
/// **AFFICHE le message du domaine**, mais elle **RESTE ACTIVABLE** : le
/// `.feature` dit *« je **TENTE** de créer une dixième échéance valide »*, et
/// un bouton désactivé rendrait **la tentative inobservable**, donc le scénario
/// **intestable**.
///
/// ⛔ Le message n'est **pas réécrit ici** : c'est celui de la validation, en un
/// seul exemplaire (pattern nº 10).
class _AffordanceAjout extends StatelessWidget {
  const _AffordanceAjout({required this.notifier, required this.onPressed});

  final EcheancesNotifier notifier;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final limite = notifier.validation.refusDeLimite(notifier.echeances);
    final disponible = limite == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: disponible
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ConcentrationTokens.moduleActif.couleur,
                    foregroundColor: ConcentrationTokens.fondApp.couleur,
                  ),
                  onPressed: onPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une échéance'),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        ConcentrationTokens.texteSecondaire.couleur,
                    side: BorderSide(
                      color: ConcentrationTokens.contour.couleur,
                    ),
                  ),
                  // ⛔ `onPressed` n'est JAMAIS null : c'est ce qui distingue
                  // « indisponible » de « désactivé ».
                  onPressed: onPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une échéance'),
                ),
        ),
        if (limite != null) MessageValidation(texte: limite.message),
      ],
    );
  }
}
