import 'package:flutter/material.dart';

import '../../../../core/theme/concentration_tokens.dart';
import '../../../../core/theme/rgb_extension.dart';
import '../../domain/echeance.dart';
import '../echeances_notifier.dart';
import 'formulaire_echeance.dart';
import 'ligne_echeance.dart';

/// Confirmation de suppression — composant **C-7**, et **la SEULE modale du
/// produit** (T9, AC-7).
///
/// *La friction est ici une **fonctionnalité**, pas un oubli de sobriété* : la
/// suppression est le **seul acte destructif**, donc le seul qui la mérite.
///
/// 🔴 **⛔ RIEN N'EST ÉCRIT AVANT LE GESTE « Supprimer »** — Échap, retour
/// système et appui hors du cadre valent **Annuler**, et le fichier doit être
/// **inchangé entre la demande et la confirmation** (C-7).
///
/// 🔴 **2ᵉ état, ajouté par AC-17 : « échec »** — ⛔ **le dialogue NE SE FERME
/// PAS.** Fermer, c'est dire « c'est fait » ; l'utilisateur retrouverait une
/// liste qui **a l'air normale**. La question reste posée puisque **rien n'a
/// été fait**, et le corps du dialogue est **inchangé**.
class ConfirmationSuppression extends StatefulWidget {
  const ConfirmationSuppression({
    required this.echeance,
    required this.notifier,
    super.key,
  });

  final Echeance echeance;
  final EcheancesNotifier notifier;

  @override
  State<ConfirmationSuppression> createState() =>
      _ConfirmationSuppressionState();
}

class _ConfirmationSuppressionState extends State<ConfirmationSuppression> {
  String? _echec;
  bool _enVol = false;

  Future<void> _supprimer() async {
    if (_enVol) return;
    setState(() => _enVol = true);
    final refus = await widget.notifier.supprimer(widget.echeance.id);
    if (!mounted) return;
    setState(() {
      _enVol = false;
      _echec = refus?.message;
    });
    if (refus == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final echeance = widget.echeance;
    // ⛔ JAMAIS des guillemets vides : à description vide, la cible est nommée
    // par sa DATE. Une confirmation anonyme est une confirmation sans
    // information — à 9 lignes qui se ressemblent, elle ne protège personne.
    final cible = echeance.description.isEmpty
        ? "L'échéance du ${dateLisible(echeance.dateEcheance)} à "
              '${heureLisible(echeance.dateEcheance)} sera définitivement '
              'supprimée.'
        : '« ${echeance.description} » sera définitivement supprimée.';

    return AlertDialog(
      backgroundColor: ConcentrationTokens.surfaceElevee.couleur,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ConcentrationTokens.contour.couleur),
      ),
      title: const Text('Supprimer cette échéance ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$cible Cette action est irréversible.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: ConcentrationTokens.texteSurFond.couleur,
            ),
          ),
          if (_echec != null) MessageValidation(texte: _echec!),
        ],
      ),
      actions: [
        // ⛔ « Annuler » d'ABORD, et il porte le focus initial : jamais
        // l'action destructive.
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        // ⛔ La distinction ne repose PAS sur la couleur (les tokens `erreur`
        // et `texteSecondaire` rendent 1,00:1 entre eux) : elle repose sur LE
        // MOT et sur l'ORDRE.
        TextButton(
          onPressed: _supprimer,
          style: TextButton.styleFrom(
            foregroundColor: ConcentrationTokens.erreur.couleur,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
