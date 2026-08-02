#!/usr/bin/env python3
"""Mutants NON PUBLIES du 3e passage de revue -- @CodeReviewer, 2026-08-02.

SHA AUDITE : 173fb62348c5ca516505067c1ea29c97fa06b8a8 (173fb62)

POURQUOI CE FICHIER EXISTE
--------------------------
`reports/US-01.1/qa_exit_criterion.py` est une condition de sortie PUBLIEE :
le developpeur la connaissait avant d'ecrire son correctif. La faire passer
prouve donc quelque chose de FAIBLE -- exactement le motif que j'ai donne au
2e passage : << une condition connue a l'avance ne prouve pas grand-chose >>.

Ces 7 mutants n'ont ete publies NULLE PART avant l'execution de ce script.
Ils sont concus pour repondre a UNE question : le correctif est-il un
CORRECTIF, ou une reponse taillee aux 7 motifs du script de la QA ?

STRATEGIE : chacun est une version SUBTILE d'un mutant publie
-------------------------------------------------------------
La QA a mute par SUPPRESSION ou par valeur GROSSIERE (constante, blanc,
1 heure). Un test peut tuer un mutant grossier et rester decoratif. Mes
mutants degradent le comportement SANS le supprimer :

* X-1 vs QA-M1  : le degrade est COMPRIME (x0,5), pas fige.
* X-2 vs QA-M4  : la description est RENDUE mais TOUJOURS LA MEME -> teste
                  l'APPARIEMENT tuile <-> description, pas la presence.
* X-3 vs QA-M4  : la description est rendue POUR CERTAINES echeances
                  seulement -> teste que l'assertion porte sur CHAQUE tuile.
* X-4 vs QA-M3  : le FittedBox RESTE, seul son `fit` change -> teste que
                  l'assertion porte sur le COMPORTEMENT, pas sur la presence
                  d'un widget.
* X-5 vs QA-M2b : le mode devient CLAIR A CONTRASTE CONSTANT (les deux tokens
                  sont ECHANGES) -> `scaffoldBackgroundColor == fondApp` reste
                  VRAI (les deux cotes bougent ensemble) ; seule une assertion
                  qui traite << sombre >> comme une GRANDEUR peut le voir.
* X-6 vs QA-M5  : le module grise reste DIFFERENT de l'actif mais RESSORT
                  DAVANTAGE -> `grise == token` et `isNot(actif)` restent
                  VRAIS ; seule l'assertion de contraste peut le voir.
* X-7 vs QA-M7  : la periode passe a 61 s, soit 1 SECONDE au-dela du budget
                  RF-05 -> teste la BORNE, la ou 1 heure teste l'ordre de
                  grandeur.

CONVENTIONS DU PROJET RESPECTEES
--------------------------------
* Le depot n'est JAMAIS modifie : tout se passe dans une copie temporaire.
* Aucun mutant n'est designe par un NUMERO DE LIGNE : chacun l'est par son
  TEXTE, et un motif introuvable est un ECHEC, jamais un silence.
* Aucun verdict n'est ecrit a la main : il est LU dans la sortie de
  `flutter test`.
* CONTROLE POSITIF ET CONTROLE NEGATIF. Le positif (X-0) doit MOURIR : sans
  lui, une campagne ou tout survit peut simplement signifier que le harnais
  est casse. Le negatif (X-8) doit SURVIVRE : il change une valeur sans
  surface de specification ; s'il rougissait, mes tests seraient sur-ajustes
  et la campagne dirait n'importe quoi.
* `PYTHONIOENCODING` / sortie ASCII : trois instruments d'audit d'affilee ont
  plante en `cp1252` sur ce projet, dont le mien au 1er passage.

USAGE
-----
    python reports/US-01.1/code_review_delta2_mutants.py
    python reports/US-01.1/code_review_delta2_mutants.py --selftest

    exit 0 -> chaque mutant a rendu le verdict ATTENDU.
    exit 1 -> au moins un ecart.
"""

from __future__ import annotations

import argparse
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.stdout.reconfigure(encoding="ascii", errors="replace")

DEPOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

TILE = "lib/features/echeances/presentation/widgets/echeance_tile.dart"
TOKENS = "lib/core/theme/concentration_tokens.dart"

# id, fichier, [(motif, remplacement), ...], intention, verdict ATTENDU
MUTANTS = [
    (
        "X-0",
        TILE,
        [("'${temps.nombreAffiche}',", "'${temps.nombreAffiche + 1}',")],
        "CONTROLE POSITIF -- COMPORTEMENTAL (pas une erreur de compilation, qui "
        "ne prouverait que la compilation) : la tuile affiche un nombre DECALE "
        "DE 1. La suite DOIT rougir ; si elle ne rougit pas, le harnais est "
        "casse et AUCUN autre resultat de ce script n'est interpretable.",
        "TUE",
    ),
    (
        "X-1",
        TILE,
        [
            (
                "final fond = gradient.backgroundFor(temps.progression);",
                "final fond = gradient.backgroundFor(temps.progression * 0.5);",
            )
        ],
        "AC-5 -- degrade COMPRIME : la tuile suit encore la progression (donc "
        "elle n'est pas figee comme dans QA-M1, et la clarte DECROIT toujours) "
        "mais p=1 ne rend plus le bleu. Seule une assertion d'EGALITE point par "
        "point peut le voir ; la seule monotonie ne suffit pas.",
        "TUE",
    ),
    (
        "X-2",
        TILE,
        [
            (
                "                  Text(\n                    description,\n                    maxLines: 2,",
                "                  Text(\n                    'Passeport',\n                    maxLines: 2,",
            )
        ],
        "AC-3 Nominal -- la description est TOUJOURS RENDUE mais c'est TOUJOURS "
        "LA MEME (un libelle qui existe reellement dans le jeu de donnees). "
        "QA-M4 supprimait l'affichage ; ici il reste, seul l'APPARIEMENT tuile "
        "<-> description est casse.",
        "TUE",
    ),
    (
        "X-3",
        TILE,
        [("                if (description.isNotEmpty)", "                if (description.length > 12)")],
        "AC-3 Nominal -- la description n'est rendue que pour les libelles "
        "LONGS. Une assertion portant sur UNE tuile bien choisie resterait "
        "verte ; il faut qu'elle porte sur CHAQUE tuile.",
        "TUE",
    ),
    (
        "X-4",
        TILE,
        [("fit: BoxFit.scaleDown,", "fit: BoxFit.none,")],
        "AC-3 Limite -- le FittedBox RESTE en place, seul son `fit` change : "
        "le nombre n'est plus reduit. QA-M3 retirait le widget ; un test qui se "
        "contenterait de constater sa PRESENCE passerait ici.",
        "TUE",
    ),
    (
        "X-5",
        TOKENS,
        [
            ("static final Rgb fondApp = Rgb.hex('#1B110C');", "static final Rgb fondApp = Rgb.hex('#F2DFD5');"),
            (
                "static final Rgb texteSurFond = Rgb.hex('#F2DFD5');",
                "static final Rgb texteSurFond = Rgb.hex('#1B110C');",
            ),
        ],
        "AC-8 Nominal -- MODE CLAIR A CONTRASTE CONSTANT : les deux tokens sont "
        "ECHANGES, donc le rapport de contraste est INCHANGE (il est symetrique) "
        "et `scaffoldBackgroundColor == fondApp.couleur` reste VRAI puisque les "
        "deux cotes bougent ensemble. Seule une definition OPERANTE de "
        "<< sombre >> (le fond est plus sombre que son texte) peut le voir.",
        "TUE",
    ),
    (
        "X-6",
        TOKENS,
        [("static final Rgb moduleGrise = Rgb.hex('#3E322C');", "static final Rgb moduleGrise = Rgb.hex('#FFFFFF');")],
        "AC-2 Nominal -- le module << grise >> reste DIFFERENT de l'actif mais "
        "RESSORT DAVANTAGE sur le fond. `grise == moduleGrise.couleur` reste "
        "vrai (tautologie : les deux cotes bougent ensemble) et `isNot(actif)` "
        "aussi. Seule l'assertion de CONTRASTE peut le voir.",
        "TUE",
    ),
    (
        "X-7",
        TOKENS,
        [
            (
                "static const Duration periodeRafraichissement = Duration(seconds: 30);",
                "static const Duration periodeRafraichissement = Duration(seconds: 61);",
            )
        ],
        "AC-4 Limite / RF-05 -- 61 secondes, soit UNE SECONDE au-dela du budget. "
        "QA-M7 testait l'ordre de grandeur (1 heure) ; celui-ci teste la BORNE.",
        "TUE",
    ),
    (
        "X-8",
        TILE,
        [("borderRadius: BorderRadius.circular(16),", "borderRadius: BorderRadius.circular(4),")],
        "CONTROLE NEGATIF -- le rayon d'arrondi de la tuile n'est specifie par "
        "AUCUN AC ni AUCUNE etape Gherkin de cette US. Il DOIT survivre : une "
        "suite qui rougirait ici serait sur-ajustee au rendu courant, et la "
        "mort des autres mutants cesserait d'etre informative.",
        "SURVIT",
    ),
]


def _lire(p: str) -> str:
    return io.open(p, encoding="utf-8").read()


def _ecrire(p: str, s: str) -> None:
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)


def _preparer_copie(dest: str) -> None:
    os.makedirs(dest, exist_ok=True)
    for d in ("lib", "test"):
        shutil.copytree(os.path.join(DEPOT, d), os.path.join(dest, d))
    for f in ("pubspec.yaml", "pubspec.lock", "analysis_options.yaml"):
        src = os.path.join(DEPOT, f)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dest, f))
    subprocess.run(
        ["flutter", "pub", "get"], cwd=dest, capture_output=True, text=True, shell=True
    )


def _flutter_test(cwd: str) -> tuple[int, str]:
    p = subprocess.run(
        ["flutter", "test", "--reporter", "expanded"],
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=True,
    )
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def _rouges(sortie: str) -> list[str]:
    trouves = re.findall(r"^\d\d:\d\d \+\d+ -\d+: (.+?) \[E\]$", sortie, re.M)
    return sorted({t.split(".dart: ")[-1] for t in trouves})


def campagne() -> int:
    racine = tempfile.mkdtemp(prefix="rev3_us011_")
    travail = os.path.join(racine, "copie")
    print("Copie isolee   : %s" % travail)
    print("Depot d'origine: %s (JAMAIS modifie)" % DEPOT)
    try:
        _preparer_copie(travail)
        code, sortie = _flutter_test(travail)
        if code != 0:
            print("[ABANDON] la BASELINE est deja rouge -- rien n'est mesurable.")
            for r in _rouges(sortie):
                print("   ROUGE: %s" % r)
            return 1
        base = re.search(r"\+(\d+): All tests passed!", sortie)
        print("Baseline : %s test(s) verts.\n" % (base.group(1) if base else "?"))

        echecs = []
        for mid, rel, paires, intention, attendu in MUTANTS:
            chemin = os.path.join(travail, rel.replace("/", os.sep))
            origine = _lire(chemin)
            mute = origine
            absent = False
            for motif, remplacement in paires:
                if motif not in mute:
                    print("[ECHEC] %s : MOTIF INTROUVABLE dans %s" % (mid, rel))
                    print("        Un motif introuvable n'est PAS un succes.")
                    absent = True
                    break
                mute = mute.replace(motif, remplacement, 1)
            if absent:
                echecs.append(mid)
                continue
            _ecrire(chemin, mute)
            code, sortie = _flutter_test(travail)
            _ecrire(chemin, origine)

            obtenu = "TUE" if code != 0 else "SURVIT"
            rouges = _rouges(sortie)
            ok = obtenu == attendu
            print(
                "%-5s %-7s (attendu %-7s) %s | %d rouge(s)"
                % (mid, obtenu, attendu, "[OK]" if ok else "[ECHEC]", len(rouges))
            )
            print("      intention : %s" % intention)
            for r in rouges[:5]:
                print("      ROUGE: %s" % r)
            if not ok:
                echecs.append(mid)
            sys.stdout.flush()

        print()
        if echecs:
            print(
                "CAMPAGNE NON CONCLUANTE -- %d mutant(s) au mauvais verdict : %s"
                % (len(echecs), ", ".join(echecs))
            )
            return 1
        print("CAMPAGNE CONCLUANTE -- chaque mutant a rendu le verdict attendu.")
        return 0
    finally:
        shutil.rmtree(racine, ignore_errors=True)


def selftest() -> int:
    """Autotest de MUTATION du script lui-meme."""
    echecs = 0
    cas = [
        ("00:05 +112: All tests passed!", []),
        ("00:03 +12 -1: chemin/x_test.dart: une assertion [E]", ["une assertion"]),
        (
            "00:03 +9 -2: a/b_test.dart: alpha [E]\n00:03 +9 -2: a/b_test.dart: beta [E]\n",
            ["alpha", "beta"],
        ),
    ]
    for sortie, attendus in cas:
        obtenus = _rouges(sortie)
        # comparaison en ENSEMBLES, jamais en cardinaux (lecon US-00.5)
        if set(obtenus) != set(attendus):
            print("[ECHEC] ensembles differents : %s != %s" % (obtenus, attendus))
            echecs += 1
        else:
            print("[OK] %d rouge(s) correctement extrait(s)" % len(obtenus))

    # Chaque motif doit REELLEMENT exister dans le depot : sinon le controle
    # cesserait de controler en silence.
    manquants = []
    for mid, rel, paires, _i, _a in MUTANTS:
        contenu = _lire(os.path.join(DEPOT, rel.replace("/", os.sep)))
        for motif, _r in paires:
            if motif not in contenu:
                manquants.append("%s(%s)" % (mid, rel))
    if manquants:
        print("[ECHEC] motif(s) absent(s) du depot : %s" % ", ".join(manquants))
        echecs += len(manquants)
    else:
        print("[OK] les %d mutants ont TOUS leurs motifs dans le depot" % len(MUTANTS))

    # Un motif temoin qui n'existe pas doit etre detecte comme absent.
    if "motif_temoin_qui_n_existe_pas" in _lire(os.path.join(DEPOT, TILE)):
        print("[ECHEC] le motif temoin ne devrait pas exister")
        echecs += 1
    else:
        print("[OK] un motif absent est bien detectable")

    # Le remplacement doit CHANGER le texte : un mutant identique a l'original
    # serait un faux vert silencieux.
    inertes = []
    for mid, _rel, paires, _i, _a in MUTANTS:
        if any(motif == remplacement for motif, remplacement in paires):
            inertes.append(mid)
    if inertes:
        print("[ECHEC] mutant(s) INERTE(S) : %s" % ", ".join(inertes))
        echecs += len(inertes)
    else:
        print("[OK] aucun mutant inerte (motif != remplacement partout)")

    # Les deux controles doivent exister, et avec des verdicts OPPOSES.
    attendus = {m[0]: m[4] for m in MUTANTS}
    if attendus.get("X-0") != "TUE" or attendus.get("X-8") != "SURVIT":
        print("[ECHEC] controle positif X-0 et/ou controle negatif X-8 absent")
        echecs += 1
    else:
        print("[OK] controle POSITIF (X-0, TUE) et NEGATIF (X-8, SURVIT) presents")

    # Les deux controles doivent viser le MEME FICHIER : sinon << X-8 survit >>
    # pourrait s'expliquer par un fichier non compile plutot que par une suite
    # correctement calibree, et le controle negatif ne controlerait rien.
    f0 = [m for m in MUTANTS if m[0] == "X-0"][0][1]
    f8 = [m for m in MUTANTS if m[0] == "X-8"][0][1]
    if f0 != f8:
        print("[ECHEC] les deux controles ne visent pas le meme fichier")
        echecs += 1
    else:
        print("[OK] les deux controles visent le meme fichier (%s)" % f0)

    print("\nAutotest : %d echec(s)." % echecs)
    return 1 if echecs else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    raise SystemExit(selftest() if args.selftest else campagne())
