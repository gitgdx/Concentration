#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Critere de contraste du Design UX d'US-01.2 — @UXDesigner, 2026-08-06.

POURQUOI CE FICHIER EXISTE
--------------------------
« Aucun contraste n'a JAMAIS ete vu par un oeil sur ce projet — tous sont
CALCULES. »  C'est une borne inscrite dans la certification d'US-01.1.  La
consequence de methode, elle, est une lecon du projet (US-00.7) :

    un critere de sortie se publie comme un SCRIPT EXECUTABLE,
    jamais recopie a la main a cote d'une commande.

Ce fichier est donc l'AUTORITE sur les ratios du Design UX d'US-01.2.  Toute
valeur ecrite ailleurs (document de design, Story File, rapport d'audit) est une
TRANSCRIPTION : si elle diverge de la sortie de ce programme, c'est la
transcription qui se RETIRE — jamais ce programme qui « se met a jour ».

DUREE DE VIE BORNEE — A SUPPRIMER EN T9
---------------------------------------
Cet instrument existe parce que @UXDesigner concoit sans runtime Flutter.  Des
que `test/core/theme/contraste_tokens_test.dart` existe (tache T9), c'est LUI
l'autorite : il tourne dans le job REQUIS `App gates`, pas ce fichier.
=> T9 doit SUPPRIMER `docs/design/us_01_2_contrastes.py`.
Motif : « une regle n'existe qu'en un seul exemplaire ; deux copies derivent »
(verifie trois fois sur ce corpus).  Deux tables de couples de couleurs qui
survivent l'une a l'autre finiraient par se contredire en silence.

CE QUE CE PROGRAMME NE PROUVE PAS
---------------------------------
* Il calcule un ratio WCAG 2.x.  Il ne dit RIEN de la lisibilite reelle, ni du
  rendu sur un ecran, ni de la perception d'un daltonien.  L'oeil reste
  hors d'atteinte (borne NM-7 du Story File, levee par US-01.3 seulement).
* Il ne connait pas le degrade temporel (couples `p` variables) : celui-la est
  couvert par `test/core/color/temporal_gradient_test.dart` depuis US-01.1, et
  US-01.2 NE LE TOUCHE PAS.
* Il ne verifie aucune taille de cible, aucun ordre de focus, aucun libelle.

SORTIE ASCII PURE, DELIBEREMENT
-------------------------------
Aucun accent, aucun symbole hors ASCII n'est IMPRIME : une console Windows en
`cp1252` a deja fait planter un instrument de controle de ce depot (US-00.6),
et c'etait la classe de bug meme que l'US corrigeait.

USAGE
-----
    python docs/design/us_01_2_contrastes.py            # verdict, exit 0 / 1
    python docs/design/us_01_2_contrastes.py --selftest # autotest de mutation
"""

from __future__ import annotations

import argparse
import sys

# --------------------------------------------------------------------------
# Formule WCAG 2.x — une seule fois, ici.
# --------------------------------------------------------------------------


def _canal_lineaire(octet: int) -> float:
    """Linearisation sRGB d'un canal 8 bits (WCAG 2.1, meme seuil que `Rgb`)."""
    v = octet / 255.0
    if v <= 0.04045:
        return v / 12.92
    return ((v + 0.055) / 1.055) ** 2.4


def octets(couleur: str) -> tuple[int, int, int]:
    h = couleur.lstrip("#")
    if len(h) != 6:
        raise ValueError("attendu #RRGGBB, recu: %r" % couleur)
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def luminance(couleur: str) -> float:
    r, g, b = octets(couleur)
    return (
        0.2126 * _canal_lineaire(r)
        + 0.7152 * _canal_lineaire(g)
        + 0.0722 * _canal_lineaire(b)
    )


def contraste(a: str, b: str) -> float:
    la, lb = luminance(a), luminance(b)
    clair, sombre = max(la, lb), min(la, lb)
    return (clair + 0.05) / (sombre + 0.05)


def composer(premier_plan: str, fond: str, alpha: float) -> str:
    """Aplatit `premier_plan` a l'opacite `alpha` sur `fond`.

    ATTENTION, HYPOTHESE EXPLICITE : Flutter compose `Opacity` en espace sRGB
    (gamma), pas en lumiere lineaire.  La couleur effective est donc la moyenne
    ponderee des composantes 8 BITS.  Composer en lineaire donnerait un resultat
    plus clair, donc un contraste plus FLATTEUR — c'est precisement pourquoi
    l'hypothese est ecrite ici plutot que supposee.
    """
    fr, fg, fb = octets(premier_plan)
    br, bg, bb = octets(fond)
    melange = [round(alpha * f + (1.0 - alpha) * b) for f, b in ((fr, br), (fg, bg), (fb, bb))]
    return "#" + "".join("%02x" % c for c in melange)


# --------------------------------------------------------------------------
# Le corpus : ce que le Design UX d'US-01.2 EXIGE, et ce qu'il REFUSE.
#
# Les deux listes comptent autant l'une que l'autre.  Un controle qui ne verifie
# que ses succes ne mesure rien : sans les REFUS, rien n'empecherait de
# reintroduire demain le token de la maquette qui echoue aujourd'hui.
# --------------------------------------------------------------------------

# Seuils WCAG 2.1 AA.
TEXTE_NORMAL = 4.5  # SC 1.4.3
TEXTE_LARGE = 3.0  # SC 1.4.3, >= 24 px, ou >= 18.66 px gras
NON_TEXTUEL = 3.0  # SC 1.4.11 (composants d'interface et graphiques)

FOND_APP = "#1B110C"
SURFACE_ELEVEE = "#231914"
TEXTE_SUR_FOND = "#F2DFD5"
TEXTE_SECONDAIRE = "#DDC1B3"
MODULE_ACTIF = "#FFB68D"
MODULE_GRISE = "#3E322C"
CONTOUR = "#A48C7F"
ERREUR = "#FFB4AB"

EXIGES = [
    # (nom, premier plan, fond, seuil, usage)
    ("texteSurFond / fondApp", TEXTE_SUR_FOND, FOND_APP, TEXTE_NORMAL,
     "titre de page, description d'une ligne de gestion, etat vide"),
    ("texteSurFond / surfaceElevee", TEXTE_SUR_FOND, SURFACE_ELEVEE, TEXTE_NORMAL,
     "description dans une carte, texte saisi dans un champ"),
    ("texteSecondaire / fondApp", TEXTE_SECONDAIRE, FOND_APP, TEXTE_NORMAL,
     "titre de groupe, libelle de champ, texte d'aide"),
    ("texteSecondaire / surfaceElevee", TEXTE_SECONDAIRE, SURFACE_ELEVEE, TEXTE_NORMAL,
     "date, heure, temps restant dans une carte"),
    ("erreur / fondApp", ERREUR, FOND_APP, TEXTE_NORMAL,
     "message de refus de validation (AC-15)"),
    ("erreur / surfaceElevee", ERREUR, SURFACE_ELEVEE, TEXTE_NORMAL,
     "message de refus rendu a l'interieur d'une carte"),
    ("fondApp / moduleActif", FOND_APP, MODULE_ACTIF, TEXTE_NORMAL,
     "libelle du bouton plein 'Ajouter une echeance'"),
    ("moduleActif / fondApp", MODULE_ACTIF, FOND_APP, NON_TEXTUEL,
     "anneau de focus, icone de la commande ACTIVE de la barre basse"),
    ("moduleActif / surfaceElevee", MODULE_ACTIF, SURFACE_ELEVEE, NON_TEXTUEL,
     "anneau de focus sur un champ"),
    ("contour / fondApp", CONTOUR, FOND_APP, NON_TEXTUEL,
     "bordure 1 dp d'une carte ou d'un champ posee sur le fond"),
    ("contour / surfaceElevee", CONTOUR, SURFACE_ELEVEE, NON_TEXTUEL,
     "bordure interne, separateur porteur de sens"),
]

REFUSES = [
    # (nom, premier plan, fond, seuil que l'on DOIT manquer, motif du refus)
    ("outline-variant #564338 / fondApp", "#564338", FOND_APP, NON_TEXTUEL,
     "bordure proposee par la maquette Stitch : ECARTEE, une bordure qui "
     "identifie un composant est soumise a SC 1.4.11"),
    ("texteSecondaire a 40% / fondApp", composer(TEXTE_SECONDAIRE, FOND_APP, 0.40),
     FOND_APP, TEXTE_NORMAL,
     "traitement 'opacity-40' de la maquette sur le groupe des echues : "
     "ECARTE, une opacite appliquee a un token de texte fabrique une couleur "
     "dont le contraste n'a jamais ete mesure"),
    ("moduleGrise / fondApp", MODULE_GRISE, FOND_APP, TEXTE_NORMAL,
     "token des modules INACTIFS : exempte par SC 1.4.3 en tant que composant "
     "desactive, donc INTERDIT pour tout texte porteur d'information et pour "
     "toute commande devenue INTERACTIVE (AC-1)"),
]

# Couples volontairement NON separables par la luminance : ils fondent la regle
# « jamais la couleur seule » (SC 1.4.1).  Ce ne sont ni des exigences ni des
# refus — ce sont des CONSTATS, imprimes pour qu'ils ne se perdent pas.
CONSTATS_COULEUR_SEULE = [
    ("erreur / moduleActif", ERREUR, MODULE_ACTIF),
    ("erreur / texteSecondaire", ERREUR, TEXTE_SECONDAIRE),
    ("texteSecondaire / moduleActif", TEXTE_SECONDAIRE, MODULE_ACTIF),
]


# --------------------------------------------------------------------------
# Evaluation
# --------------------------------------------------------------------------


def evaluer(exiges, refuses):
    """Rend (lignes affichables, ensemble des NOMS en echec).

    Les verdicts sont rendus comme un ENSEMBLE de noms, jamais comme un
    decompte : « un decompte egal n'est pas une preuve d'equivalence »
    (lecon US-00.5/00.7).
    """
    lignes = []
    echecs = set()

    for nom, av, ar, seuil, usage in exiges:
        r = contraste(av, ar)
        ok = r >= seuil
        if not ok:
            echecs.add(nom)
        lignes.append(
            "  [%s] %-34s %s sur %s = %6.2f:1  (requis >= %.1f)  %s"
            % ("OK " if ok else "ECHEC", nom, av.upper(), ar.upper(), r, seuil, usage)
        )

    for nom, av, ar, seuil, motif in refuses:
        r = contraste(av, ar)
        ok = r < seuil  # on EXIGE l'echec du seuil
        if not ok:
            echecs.add(nom)
        lignes.append(
            "  [%s] %-34s %s sur %s = %6.2f:1  (doit rester < %.1f)  %s"
            % ("OK " if ok else "ECHEC", nom, av.upper(), ar.upper(), r, seuil, motif)
        )

    return lignes, echecs


def rapport() -> int:
    print("Contrastes du Design UX d'US-01.2 — calcul WCAG 2.1, sRGB 8 bits")
    print("=" * 78)
    print("EXIGES (le seuil doit etre atteint) :")
    lignes, echecs = evaluer(EXIGES, [])
    for ligne in lignes:
        print(ligne)

    print("")
    print("REFUSES (le seuil doit rester MANQUE — controle negatif) :")
    lignes_r, echecs_r = evaluer([], REFUSES)
    for ligne in lignes_r:
        print(ligne)
    echecs |= echecs_r

    print("")
    print("CONSTATS 'jamais la couleur seule' (SC 1.4.1) — ni exigence ni refus :")
    for nom, a, b in CONSTATS_COULEUR_SEULE:
        print(
            "  .    %-34s %s sur %s = %6.2f:1"
            % (nom, a.upper(), b.upper(), contraste(a, b))
        )
    print(
        "       Un ratio proche de 1,00:1 signifie que ces deux tokens ne sont"
    )
    print(
        "       PAS separables par la luminance : l'information qu'ils portent"
    )
    print("       doit donc etre portee AUSSI par un mot ou une forme.")

    print("")
    print("=" * 78)
    if echecs:
        print("VERDICT : ECHEC — %d couple(s) hors regle :" % len(echecs))
        for nom in sorted(echecs):
            print("  - %s" % nom)
        return 1
    print("VERDICT : OK — tous les couples exiges passent, tous les refus tiennent.")
    return 0


# --------------------------------------------------------------------------
# Autotest de mutation
#
# Regle du projet : tout script de controle porte son autotest, avec des
# mutants JAMAIS tires du vocabulaire de la regle testee (sinon il ne mesure
# rien).  Les ancres ci-dessous viennent de WCAG lui-meme (noir/blanc = 21:1),
# pas de la palette Concentration.
# --------------------------------------------------------------------------


def selftest() -> int:
    resultats = []

    def verifier(intitule, condition):
        resultats.append((intitule, bool(condition)))

    # A1 — ancre externe : noir sur blanc vaut exactement 21:1.
    verifier("A1 noir/blanc = 21.00", abs(contraste("#000000", "#FFFFFF") - 21.0) < 1e-9)

    # A2 — une couleur contre elle-meme vaut exactement 1:1.
    verifier("A2 identite = 1.00", abs(contraste("#3D7DD8", "#3D7DD8") - 1.0) < 1e-12)

    # A3 — symetrie : l'ordre des arguments n'a aucun effet.
    verifier(
        "A3 symetrie",
        abs(contraste(TEXTE_SUR_FOND, FOND_APP) - contraste(FOND_APP, TEXTE_SUR_FOND))
        < 1e-12,
    )

    # M1 — MUTANT DE FORMULE : linearisation gamma retiree.
    #      Point important, et c'est pour cela que le mutant est ici : l'ancre
    #      A1 NE LE VOIT PAS (0 et 1 sont invariants par la gamma).  Il faut une
    #      valeur intermediaire, hors palette du projet, pour le tuer.
    def contraste_sans_gamma(a: str, b: str) -> float:
        def lum(c: str) -> float:
            r, g, b8 = octets(c)
            return (0.2126 * r + 0.7152 * g + 0.0722 * b8) / 255.0

        la, lb = lum(a), lum(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)

    verifier(
        "M1a l'ancre noir/blanc NE tue PAS le mutant de gamma",
        abs(contraste_sans_gamma("#000000", "#FFFFFF") - 21.0) < 1e-9,
    )
    sain = contraste("#808080", "#FFFFFF")
    mute = contraste_sans_gamma("#808080", "#FFFFFF")
    verifier("M1b gris moyen : le mutant de gamma est TUE", abs(sain - mute) > 1.5)
    verifier("M1c gris moyen sain > 3.5", sain > 3.5)
    verifier("M1d gris moyen mute < 2.5", mute < 2.5)

    # M2 — MUTANT DE CORPUS, cote EXIGENCES : un couple dont le premier plan est
    #      remplace par son propre fond rend 1:1 et DOIT etre signale.
    #      Verdicts compares en ENSEMBLES, pas en cardinaux.
    exiges_mutes = list(EXIGES)
    exiges_mutes[0] = ("MUTANT invisible", FOND_APP, FOND_APP, TEXTE_NORMAL, "mutant")
    _, echecs_m2 = evaluer(exiges_mutes, [])
    verifier("M2 exigence mutee : ensemble d'echecs == {MUTANT invisible}",
             echecs_m2 == {"MUTANT invisible"})

    # M3 — MUTANT DE CORPUS, cote REFUS : un refus qui passerait le seuil doit
    #      etre signale lui aussi (sinon le controle negatif serait decoratif).
    refuses_mutes = [("MUTANT trop lisible", "#FFFFFF", "#000000", NON_TEXTUEL, "mutant")]
    _, echecs_m3 = evaluer([], refuses_mutes)
    verifier("M3 refus mute : ensemble d'echecs == {MUTANT trop lisible}",
             echecs_m3 == {"MUTANT trop lisible"})

    # M4 — le corpus reel doit etre VERT : si ce test echoue, ce n'est pas
    #      l'instrument qui est faux, ce sont les tokens.
    _, echecs_reels = evaluer(EXIGES, REFUSES)
    verifier("M4 corpus reel sans echec", echecs_reels == set())

    # M5 — la composition d'opacite doit vraiment assombrir un texte clair sur
    #      un fond sombre (garde-fou sur `composer`, dont l'hypothese sRGB est
    #      la partie la plus contestable de ce fichier).
    verifier(
        "M5 composer() assombrit",
        contraste(composer(TEXTE_SECONDAIRE, FOND_APP, 0.40), FOND_APP)
        < contraste(TEXTE_SECONDAIRE, FOND_APP),
    )
    verifier("M5b composer(alpha=1) est neutre",
             composer(TEXTE_SECONDAIRE, FOND_APP, 1.0).upper() == TEXTE_SECONDAIRE.upper())

    print("Autotest de mutation — %d assertions" % len(resultats))
    print("=" * 78)
    echecs = [i for i, ok in resultats if not ok]
    for intitule, ok in resultats:
        print("  [%s] %s" % ("OK " if ok else "ECHEC", intitule))
    print("=" * 78)
    if echecs:
        print("SELFTEST : ECHEC (%d)" % len(echecs))
        return 1
    print("SELFTEST : OK — 0 echec")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Critere de contraste du Design UX d'US-01.2")
    parser.add_argument("--selftest", action="store_true",
                        help="autotest de mutation de cet instrument")
    args = parser.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:  # pragma: no cover - console exotique
            pass
    return selftest() if args.selftest else rapport()


if __name__ == "__main__":
    raise SystemExit(main())
