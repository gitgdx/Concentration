import '../color/rgb.dart';

/// Design tokens (T1) — **projection en Dart** de `docs/design/DESIGN_SYSTEM.md`.
///
/// ⛔ Ce fichier n'est pas l'autorité : `DESIGN_SYSTEM.md` l'est. Aucune couleur
/// ni dimension ne s'écrit dans un widget ; tout passe par ici.
///
/// ⚠️ Les deux extrémités du dégradé ont été retenues **par calcul de
/// contraste** et non par goût (DESIGN_SYSTEM §Palette) : le bleu de la
/// maquette `#005AB3` rend 3,81:1 au pire point et **échoue les 4,5:1** exigés
/// pour la description. La marge du couple retenu est de **0,03 point** — toute
/// retouche de ces trois tokens **exige de rejouer le calcul**.
class ConcentrationTokens {
  const ConcentrationTokens._();

  /// `p = 0` — le nombre vient de changer, loin du prochain changement.
  static final Rgb gradientOrange = Rgb.hex('#FF8C42');

  /// `p = 1` — changement imminent.
  static final Rgb gradientBleu = Rgb.hex('#3D7DD8');

  /// Fond de l'application (dark mode de référence, forcé — AC-8).
  static final Rgb fondApp = Rgb.hex('#1B110C');

  /// Texte sur le fond sombre de l'application.
  static final Rgb texteSurFond = Rgb.hex('#F2DFD5');

  /// Accent du module actif dans le hub.
  static final Rgb moduleActif = Rgb.hex('#FFB68D');

  /// Modules futurs : estompés, non-interactifs.
  ///
  /// 🔴 **US-01.2 — usage restreint** : `moduleGrise / fondApp` rend **1,50:1**,
  /// licite pour un composant **inactif** *(exempté SC 1.4.3)* et **illicite
  /// dès qu'un composant devient interactif** *(SC 1.4.11, ≥ 3:1)*. ⛔ Il ne
  /// reste donc que « Réglages » et les modules grisés.
  static final Rgb moduleGrise = Rgb.hex('#3E322C');

  // ─── Tokens AJOUTÉS par US-01.2 (Design UX §6.2) — quatre, pas un de plus.
  // ⛔ Aucun token d'US-01.1 n'est modifié : la marge du dégradé est de
  //    0,03 point, et toute retouche exigerait de rejouer son calcul.

  /// Fond des cartes de gestion et des champs de saisie.
  static final Rgb surfaceElevee = Rgb.hex('#231914');

  /// Bordure 1 dp, liseré du groupe des échues, séparateur porteur de sens.
  ///
  /// ⚠️ **Le token `outline-variant` de la maquette (`#564338`) a été ÉCARTÉ
  /// PAR CALCUL** : il rend **1,99:1**, sous les 3:1 de SC 1.4.11 — or une
  /// bordure qui **identifie** une carte ou un champ est un composant
  /// d'interface.
  static final Rgb contour = Rgb.hex('#A48C7F');

  /// Date, heure, temps restant, libellés de champ, textes d'aide.
  ///
  /// ⛔ **AUCUNE OPACITÉ sur ce token** *(règle du §6.5)* : à 40 % il donne
  /// `#69574F`, soit **2,72:1** — et il frapperait **précisément** le groupe des
  /// échues, celui qu'il faut rendre **évident**. La hiérarchie se fait par
  /// **token mesuré**, **taille** et **graisse**, ⛔ jamais par l'alpha.
  static final Rgb texteSecondaire = Rgb.hex('#DDC1B3');

  /// Message de refus de validation et d'échec d'écriture.
  ///
  /// ⚠️ AC-15 « Erreur » l'autorise **nommément** : l'interdiction du rouge
  /// posée par US-01.1 porte sur **les tuiles et l'ambiance de pratique**, ⛔ pas
  /// sur un message lisible — sans quoi un refus serait **silencieux**.
  static final Rgb erreur = Rgb.hex('#FFB4AB');

  /// Candidats de texte **sur tuile**, dans l'ordre de préférence.
  ///
  /// `foregroundFor(p)` **choisit** parmi eux (ADR-003 §5). Sur cette palette,
  /// le premier gagne sur toute la plage — mais le mécanisme reste requis,
  /// puisque les tokens peuvent changer.
  static final List<Rgb> texteSurTuileCandidats = [
    Rgb.hex('#1B110C'),
    Rgb.hex('#F2DFD5'),
  ];

  /// Seuils WCAG AA (RNF-06, AC-8).
  static const double contrasteMinTexteNormal = 4.5;
  static const double contrasteMinTexteLarge = 3.0;

  /// Bornes de la grille (RF-15).
  static const int tuilesMin = 1;
  static const int tuilesMax = 9;

  /// Période de rafraîchissement (RF-05 : au moins une fois par minute).
  static const Duration periodeRafraichissement = Duration(seconds: 30);

  // ─── Tokens AJOUTÉS par US-01.4 (Design UX §7.1 et §7.3).
  // ⚖️ Cette ligne annonçait « deux, pas un de plus » jusqu'au 2026-08-27 :
  //    elle est FAUSSE dès l'ajout des tokens de l'animation (T10), et le
  //    décompte est RETIRÉ plutôt que mis à jour — un nombre dérivé écrit à
  //    la main dans un commentaire ne se met pas à jour tout seul, et une
  //    valeur fausse se retire (classe de défaut nº 1 du projet).
  //    Le compte se LIT : grep -c "^  static const" sous cette ligne.

  /// Durée pendant laquelle la description remplace le nombre (AC-2).
  ///
  /// ⛔ **Cette valeur ne s'écrit NULLE PART ailleurs** : ni dans un widget,
  /// ni dans un `hint` *(« pendant 3 secondes » y serait une **copie** de ce
  /// token — classe de défaut nº 1 — et il faudrait gérer le pluriel)*, ni
  /// dans une avance de test *(elles se **calculent** depuis ce token et
  /// depuis [periodeRafraichissement])*.
  ///
  /// ⚠️ **Elle est STRICTEMENT INFÉRIEURE à [periodeRafraichissement], et
  /// c'est ce qui rend AC-2 « Limite » observable** *(un rafraîchissement peut
  /// tomber PENDANT la fenêtre)*. La garde est **assertée par un test**,
  /// ⛔ pas seulement écrite ici.
  static const Duration fenetreRevelation = Duration(seconds: 3);

  /// Plancher de taille de la **description révélée** (Design UX §7.2).
  ///
  /// 🔴 **La réduction porte sur la taille de DESIGN, ⛔ JAMAIS sur le facteur
  /// d'échelle de l'utilisateur** : le plancher **effectif** est
  /// `11 × échelle`, soit **22 à ×2,0**. Un ajustement qui « ferait rentrer »
  /// le texte en annulant le réglage système reprendrait d'une main ce que
  /// l'accessibilité donne de l'autre *(SC 1.4.4)* ⇒ **ratio de réduction
  /// maximal `11/13`, et rien de plus.**
  static const double plancherDescriptionRevelee = 11;

  /// Durée de l'animation de disparition d'une échue retirée (Design UX §7.3).
  ///
  /// 🔴 **VALEUR CHIFFRÉE ET SES DEUX BORNES, ⛔ pas un goût** : en dessous
  /// d'≈ 120 ms l'œil enregistre une **disparition sèche** *(l'animation
  /// cesserait d'être le feedback qui remplace la modale)*, au-delà d'≈ 300 ms
  /// elle **frictionne** le geste le plus fréquent du produit. ⛔ **Ne pas la
  /// changer sans rejouer ce raisonnement.**
  ///
  /// ⛔ **Elle ne s'écrit NULLE PART ailleurs** : ni dans un widget, ni dans une
  /// avance de test *(elles se **calculent** depuis ce token)*.
  static const Duration dureeDisparition = Duration(milliseconds: 200);

  /// Échelle finale de la tuile qui disparaît (Design UX §7.3).
  ///
  /// ⚖️ **Token AJOUTÉ, non prévu par la table §7 du Design UX — et le motif est
  /// la règle du fichier lui-même** : *« aucune couleur ni dimension ne s'écrit
  /// dans un widget »*. La valeur **est** donnée par §7.3 *(« échelle
  /// 1 → 0,92 »)* ; l'écrire dans `echeances_grid.dart` en aurait fait le
  /// **27ᵉ** nombre en dur de `lib/`. ➡️ **T16 doit l'inscrire dans
  /// `DESIGN_SYSTEM.md` avec les deux autres.**
  ///
  /// ⛔ **AUCUN déplacement n'accompagne cette réduction** : un glissement
  /// suggérerait *« ça va quelque part »*, or l'échéance **reste en gestion**.
  static const double echelleDisparition = 0.92;
}
