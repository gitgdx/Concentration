import 'package:flutter/material.dart';

import '../../../../core/color/temporal_gradient.dart';
import '../../../../core/theme/concentration_theme.dart';
import '../../../../core/theme/rgb_extension.dart';
import '../../domain/remaining_time.dart';

/// Tuile d'échéance (T7, T8).
///
/// ⛔ **Le nombre est NU** : aucune unité, aucune fraction, aucun signe (RF-01).
/// L'unité n'existe que dans [RemainingTime.libelleAccessibilite], porté par
/// `Semantics` — c'est le seul endroit où elle devient un mot (AC-8).
class EcheanceTile extends StatelessWidget {
  const EcheanceTile({
    required this.temps,
    required this.description,
    required this.intention,
    super.key,
    this.gradient = const TemporalGradient(),
  });

  /// `hint` de la tuile **`ACTIVE` avec description** (Design UX §4.4).
  ///
  /// 🔴 **RÈGLE DE RÉDACTION, et elle vient d'un fait MESURÉ par ADR-013 §3 :
  /// un `hint` dit CE QUE ÇA FAIT, ⛔ JAMAIS COMMENT ON LE FAIT.** Il n'existe
  /// **aucune** action sémantique de double appui *(17 rappels, 26 actions,
  /// aucun)* : une AT active par **sa propre** convention, en **une** fois. Un
  /// `hint` disant « double appui pour retirer » serait donc **faux pour celui
  /// qui l'entend**.
  ///
  /// ⛔ **La durée n'est PAS dans le texte** : y écrire « pendant 3 secondes »
  /// recopierait la valeur du token `fenetreRevelation` — classe de défaut
  /// nº 1 du projet — et il faudrait en plus gérer le pluriel.
  static const String hintRevelation = 'Affiche la description';

  /// `hint` de la tuile **`ÉCHUE`** (Design UX §4.4) : il dit **l'effet** et la
  /// **non-destruction**, seule information utile **avant** d'activer.
  static const String hintRetrait =
      "Retire l'échéance de la grille, sans la supprimer";

  /// 🔴 **NB-7 (T7) — LA BOÎTE QUI PORTE LE FOND SE DÉSIGNE PAR SON IDENTITÉ,
  /// ⛔ JAMAIS PAR SA POSITION.**
  ///
  /// **Défaut DÉMONTRÉ, pas supposé** *(sonde d'US-01.2)* : quand **deux**
  /// boîtes décorées se retrouvent sous la tuile, un sélecteur en `.first`
  /// désigne l'**extérieure** ⇒ la tuile pouvait rendre **toujours orange** avec
  /// **112 tests VERTS**. La clé rend la cible **non ambiguë**, et
  /// ⛔ **l'assertion d'unicité reste** — sur la clé, désormais.
  ///
  /// ⚠️ **Cette constante est dans le produit et consommée par les tests, et
  /// c'est ASSUMÉ** : une clé est une propriété de l'**arbre de widgets**, et
  /// l'alternative — un nom de type ou une position — est **précisément** ce qui
  /// a produit le faux vert.
  static const Key cleFond = Key('echeance-tile-fond');

  final RemainingTime temps;
  final String description;

  /// 🔴 **UNE intention par tuile, atteinte par QUATRE canaux** — ⛔ **pas
  /// quatre règles** *(ADR-013 §3)* : un seul rappel, invoqué par l'appui
  /// pointeur, par `Entrée`, par `Espace` et par l'action `tap` d'une AT.
  ///
  /// ⛔ **Nullable ET `required` : les deux, et c'est délibéré.** `required`
  /// interdit qu'un appelant l'**oublie** ; `VoidCallback?` l'oblige à **dire
  /// explicitement** qu'il n'y a rien à activer. ⛔ **Jamais un rappel vide**
  /// *(mutant **M-15**)* : un gestionnaire qui ne fait rien est la **barrière
  /// muette** que le pattern nº 13 interdit.
  final VoidCallback? intention;

  final TemporalGradient gradient;

  @override
  Widget build(BuildContext context) {
    final fond = gradient.backgroundFor(temps.progression);
    // foregroundFor ÉCHOUE BRUYAMMENT si aucun token n'atteint le seuil : c'est
    // voulu (ADR-003 §5), un dégradé illisible est un défaut de tokens.
    final avant = gradient.foregroundFor(temps.progression).couleur;

    final rendu = DecoratedBox(
      key: cleFond,
      decoration: BoxDecoration(
        color: fond.couleur,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // 🔴 AC-1 (T6) — LE CADRAN CONTRE L'ÉTIQUETTE, et ⛔ sur les
          // `ACTIVE` SEULEMENT (R-8). Une échue conserve sa description
          // affichée sous son « 0 » : la centrer et grossir son nombre
          // pousserait cette description hors de la tuile.
          // ⛔ Les DEUX alignements comptent : celui-ci place le nombre sur
          // l'axe HORIZONTAL, celui du `FittedBox` sur le VERTICAL. En
          // changer un seul laisse le nombre à moitié en haut à gauche.
          crossAxisAlignment: temps.estEchue
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            // Le nombre occupe la place disponible et se REDUIT s'il le faut :
            // AC-3 « Limite » exige que 9 tuiles restent embrassables d'un
            // regard, donc sans débordement, quelle que soit la taille de
            // cellule. Un `Text` nu débordait à 9 tuiles — mesuré par T12a.
            Expanded(
              child: FittedBox(
                // ⛔ `BoxFit.contain` est INTERDIT (§G-7) : il AGRANDIT
                // jusqu'à remplir, donc la taille du glyphe dépendrait du
                // NOMBRE DE CHIFFRES — au rafraîchissement, `10 → 9`
                // doublerait le chiffre sous les yeux du pratiquant, et
                // 9 tuiles porteraient 9 tailles différentes.
                // ✅ La taille s'augmente dans le TOKEN ; `scaleDown` reste
                // le FILET qui a fermé le débordement à 9 tuiles.
                fit: BoxFit.scaleDown,
                alignment: temps.estEchue
                    ? Alignment.topLeft
                    : Alignment.center,
                child: Text(
                  '${temps.nombreAffiche}',
                  style: ConcentrationTheme.styleNombrePour(
                    estEchue: temps.estEchue,
                  ).copyWith(color: avant),
                ),
              ),
            ),
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ConcentrationTheme.styleDescription.copyWith(
                  color: avant,
                ),
              ),
          ],
        ),
      ),
    );

    // ═══════════════════════════════════════════════════════════════════════
    // 🔴 L'ENVELOPPE INTERACTIVE EST **CONDITIONNELLE** (ADR-014 §A.1, trou
    // J-1 de l'Integration Lock). L'arbre d'ADR-013 §3 vaut pour DEUX régimes
    // sur trois ; le troisième garde l'arbre d'US-01.1, MOT POUR MOT.
    //
    // ⛔ Pourquoi ce n'est pas un détail : appliqué sans condition, l'arbre
    // donnait à une tuile `ACTIVE` SANS description un `Semantics(button:
    // true, onTap:)` et un `FocusableActionDetector` — elle **s'annonçait
    // bouton activable avec RIEN à activer**. C'est le MIROIR de `SONDE-1`
    // *(là : actionnable et non annoncé ; ici : annoncé et sans effet)* et les
    // DEUX violent AC-9 « Erreur » — le mensonge d'interface.
    // 🔴 Et la forme d'assertion prescrite par ADR-013 §2 est AVEUGLE à ce
    // défaut : sur la source fautive elle rend `pointeurs = 0`, donc elle
    // serait VERTE SUR LE DÉFAUT ⇒ le contrôle asserte **l'absence du NŒUD**
    // (ADR-014 §A.2, sept propriétés), ⛔ jamais `onTap == null`.
    // ═══════════════════════════════════════════════════════════════════════
    final activer = intention;

    // ⛔ La condition porte sur « y a-t-il quelque chose à activer », ⛔ pas sur
    // l'état de la tuile : une `ÉCHUE` a toujours son retrait, une `ACTIVE`
    // n'a une révélation que si elle a une description à révéler (AC-3).
    // ⚠️ `activer == null` est le MÊME motif appliqué à l'autre cause
    // d'absence : une enveloppe sans rappel serait le mensonge d'interface
    // ci-dessus, et ⛔ un rappel vide serait la barrière muette (M-15).
    if (activer == null || (!temps.estEchue && description.isEmpty)) {
      // ⛔ LE LABEL N'EST PAS RETIRÉ — c'est la moitié qui compte : sans lui,
      // « aucune enveloppe » se lirait « aucune sémantique » et la tuile
      // deviendrait INVISIBLE aux lecteurs d'écran, défaut PIRE que celui
      // qu'on corrige. La tuile est **nommée**, simplement pas activable.
      // Précédent du dépôt : `hub_page.dart` rend les modules grisés sans
      // aucun gestionnaire — « l'absence de gestionnaire rend l'interdit
      // vérifiable, là où un callback vide le laisserait révocable ».
      return Semantics(
        label: temps.libelleAccessibilite,
        child: ExcludeSemantics(child: rendu),
      );
    }

    // UNE intention, QUATRE canaux (ADR-013 §3, mesuré sur les quatre) :
    // `Entrée` et `Espace` par les deux intentions d'activation, l'action
    // `tap` d'une AT par `Semantics(onTap:)`, le pointeur par le détecteur.
    // ⛔ PAS `InkWell` : il lie l'activation clavier à `onTap`, donc une échue
    // devrait porter un `onTap` POINTEUR — que l'arbitrage interdit — et son
    // `splashColor` ferait ENCODER L'INTERACTION PAR LA COULEUR (RF-04 rompu,
    // mutant M-13). Un `GestureDetector` nu n'apporte aucune ondulation.
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            activer();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            activer();
            return null;
          },
        ),
      },
      // ⛔ LE GESTE ET L'ANNONCE VIVENT AU-DESSUS D'`ExcludeSemantics` (C-4) :
      // ce widget supprime la sémantique de TOUS ses descendants, donc un
      // détecteur placé DEDANS rendrait la tuile fonctionnelle et NON
      // ANNONCÉE — le geste marcherait, AC-9 tomberait, et ⛔ rien d'autre ne
      // le verrait (mutant M-17).
      child: Semantics(
        label: temps.libelleAccessibilite,
        button: true,
        onTap: activer,
        hint: temps.estEchue ? hintRetrait : hintRevelation,
        child: ExcludeSemantics(
          // `excludeFromSemantics` en plus de l'exclusion ci-dessus : le
          // détecteur ne crée AUCUN second nœud annoncé (mesuré :
          // `noeuds_portant_ce_label = 1`).
          child: GestureDetector(
            excludeFromSemantics: true,
            // 🔴 UN SEUL GESTE POINTEUR PAR TUILE (C-3, contrôle T-P4) :
            // les deux sur la même surface imposeraient `kDoubleTapTimeout`
            // (300 ms) à la révélation et feraient CLIGNOTER le 1ᵉʳ appui d'un
            // double appui — ⛔ invisibles à tout scénario fonctionnel.
            onTap: temps.estEchue ? null : activer,
            onDoubleTap: temps.estEchue ? activer : null,
            child: rendu,
          ),
        ),
      ),
    );
  }
}
