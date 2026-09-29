import 'package:flutter/material.dart';

import '../../../../core/theme/concentration_theme.dart';
import '../../../../core/theme/concentration_tokens.dart';
import '../../../../core/theme/rgb_extension.dart';

/// Le ton du message — ⛔ **il change la COULEUR, et RIEN D'AUTRE**
/// (Design UX §5.1).
///
/// 🔴 **Deux tons, ⛔ pas deux composants**, et le motif est mesuré : l'anatomie
/// est **identique** dans les deux cas *(`liveRegion`, `Padding(vertical: 8)`,
/// le glyphe `⚠`, la typographie)*. Deux composants écriraient **deux fois** la
/// même règle de typographie et le même glyphe — *deux copies d'un motif
/// dérivent, vérifié trois fois sur ce corpus*.
enum TonMessage {
  /// Formulaire, dialogue de confirmation, page de gestion — `erreur`.
  ///
  /// **Couple de contraste EXISTANT** *(US-01.2)* : `erreur / fondApp` =
  /// **10,93:1**, et `≥ 4,5:1` sur `surfaceElevee`. ⛔ Comportement d'US-01.2
  /// **inchangé** : c'est le ton que portait `MessageValidation`.
  surfaceDeSaisie,

  /// Le hub — `texteSurFond`.
  ///
  /// 🔴 **Le token `erreur` N'ENTRE PAS sur le hub, et ce n'est pas une
  /// préférence — c'est une MESURE** *(Design UX §5.1)* : `erreur`,
  /// `moduleActif` et `texteSecondaire` sont à **1,00:1 ENTRE EUX**, donc la
  /// teinte rouge ⛔ **ne distinguerait rien** de la barre basse ni du texte
  /// secondaire, tout en **perdant 3,47 points** de contraste
  /// *(`texteSurFond / fondApp` = **14,39:1** contre **10,93:1**)*.
  /// ⇒ ce qui porte l'alerte est le **glyphe `⚠`** et la `liveRegion`,
  /// ⛔ **jamais la couleur seule** *(SC 1.4.1)*.
  surfaceDePratique,
}

/// Composant **C-5** — message d'écriture, **UN exemplaire, DEUX tons**
/// (Design UX §5.1, [ADR-014](../../../../../docs/adr/ADR-014-enveloppe-interactive-conditionnelle-etat-message-hub.md) §B).
///
/// ⚖️ **EXTRAIT de `formulaire_echeance.dart`, ⛔ PAS copié** — c'était
/// `MessageValidation`, qui portait déjà **trois** consommateurs *(formulaire,
/// page de gestion, dialogue de confirmation)*. Le hub en ajoute un
/// **quatrième**, avec un ton différent : le composant remonte donc dans son
/// propre fichier et prend un paramètre `ton`. ⛔ **Le dupliquer pour le hub
/// aurait fait deux composants pour une seule règle d'affichage.**
///
/// ⛔ **Il ne RÉDIGE rien** : son texte vient du domaine, en un seul exemplaire
/// — un `ResultatEcriture.message` *(donc `ActeEcriture.*.messageEchec`)* ou un
/// `RefusValidation.message`. ⛔ **Jamais une chaîne écrite dans un widget.**
///
/// ⛔ **Jamais tronqué, jamais centré** *(§5.1)* : un message multi-ligne centré
/// se lit mal, et une troncature cacherait précisément ce que l'utilisateur doit
/// lire. ⇒ ⛔ **aucun `maxLines`, aucun `overflow`, aucun `textAlign.center`.**
class MessageEcriture extends StatelessWidget {
  const MessageEcriture({required this.texte, required this.ton, super.key});

  final String texte;

  /// ⛔ **`required`, sans valeur par défaut.** Un défaut ferait de l'autre ton
  /// un cas particulier, et un appelant qui l'oublie rendrait la mauvaise
  /// couleur **sans qu'aucune assertion ne puisse le voir**.
  final TonMessage ton;

  /// La couleur du ton — ⛔ **le seul point du composant qui en dépend**.
  Color get _couleur => switch (ton) {
    TonMessage.surfaceDeSaisie => ConcentrationTokens.erreur.couleur,
    TonMessage.surfaceDePratique => ConcentrationTokens.texteSurFond.couleur,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        liveRegion: true,
        child: Text(
          // Le signe ⚠ est **obligatoire** dans les DEUX tons : trois tokens de
          // luminance quasi identique (1,00:1) rendent la teinte incapable de
          // porter l'alerte seule (SC 1.4.1).
          '⚠ $texte',
          style: ConcentrationTheme.styleMessage.copyWith(color: _couleur),
        ),
      ),
    );
  }
}
