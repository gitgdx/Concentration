#!/usr/bin/env python3
"""Critere de sortie EXECUTABLE de la QA d'US-01.1 (2026-08-02) -- @QA_Tester.

POURQUOI CE FICHIER EXISTE
--------------------------
Lecon d'US-00.7, inscrite a reports/US-00.7/corpus_sweep.md :
  << un critere de sortie se publie comme un SCRIPT EXECUTABLE, jamais recopie
     a la main >>.
Le verdict `EVT_QA_FAILED` du 2026-08-02 s'appuie sur une campagne de mutation.
Ce script REJOUE cette campagne. Il est le critere de reprise : la QA repassera
quand il rendra `exit 0`.

CE QU'IL MESURE
---------------
`scripts/check_gherkin_mapping.py` etablit une correspondance 13 <-> 13 entre
les scenarios du `.feature` et les tests Dart. Il ANNONCE lui-meme sa borne :
  << Controle de CORRESPONDANCE DE TITRES -- pas de semantique. >>
Ce script mesure ce que l'autre ne peut pas voir : est-ce que les ETAPES
Gherkin (les << Alors ... >>) sont reellement ADOSSEES A UNE ASSERTION ?
Methode : on casse le comportement decrit par l'etape ; la suite DOIT rougir.
Un mutant qui SURVIT prouve que l'etape est decorative.

CONVENTIONS DU PROJET RESPECTEES
--------------------------------
* Le depot n'est JAMAIS modifie : tout se passe dans une copie temporaire.
* Aucun resultat n'est ecrit a la main : chaque verdict est LU dans la sortie
  de `flutter test`.
* Aucun mutant n'est designe par un NUMERO DE LIGNE : chacun est designe par
  son TEXTE, qui doit etre present -- un motif introuvable est un ECHEC, pas
  un succes silencieux (sinon le controle se blanchirait tout seul le jour ou
  le code bouge).
* CONTROLE POSITIF OBLIGATOIRE (QA-M6) : un mutant dont on sait qu'il DOIT
  mourir. Sans lui, une campagne ou tout survit ne prouve rien -- elle peut
  simplement signifier que le harnais est casse. C'est la lecon des SIX
  instruments faux d'US-00.5.

USAGE
-----
    python reports/US-01.1/qa_exit_criterion.py
    python reports/US-01.1/qa_exit_criterion.py --selftest

    exit 0 -> tous les mutants attendus TUES : le critere de sortie est atteint.
    exit 1 -> au moins un mutant SURVIT : l'etape Gherkin / clause d'AC
              correspondante n'est adossee a aucune assertion.

ETAT AU 2026-08-02 SUR 6fe75df : exit 1 (6 mutants survivants sur 7).
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
THEME = "lib/core/theme/concentration_theme.dart"
TOKENS = "lib/core/theme/concentration_tokens.dart"
HUB = "lib/features/hub/presentation/hub_page.dart"

# id, fichier, motif (TEXTE, jamais un numero de ligne), remplacement,
# clause visee, verdict ATTENDU une fois le defaut corrige
MUTANTS = [
    (
        "QA-M1",
        TILE,
        "final fond = gradient.backgroundFor(temps.progression);",
        "final fond = gradient.backgroundFor(0);",
        'AC-5 Nominal / Sc.7 "la couleur de fond de la tuile est bleue" '
        "-- la tuile ignore la progression et rend TOUJOURS l'orange",
        "TUE",
    ),
    (
        "QA-M2b",
        THEME,
        "      scaffoldBackgroundColor: fond,",
        "      scaffoldBackgroundColor: const Color(0xFFFFFFFF),",
        'AC-8 Nominal / Sc.1 "le hub est affiche en MODE SOMBRE de reference" '
        "-- fond de l'application passe au BLANC",
        "TUE",
    ),
    (
        "QA-M3",
        TILE,
        "child: FittedBox(\n"
        "                    fit: BoxFit.scaleDown,\n"
        "                    alignment: Alignment.topLeft,\n"
        "                    child: Text(",
        "child: Align(\n"
        "                    alignment: Alignment.topLeft,\n"
        "                    child: Text(",
        "AC-3 Limite / N-3 de la revue (mutant M2) -- retrait du FittedBox, "
        "le correctif anti-debordement du nombre n'est pas assertionne",
        "TUE",
    ),
    (
        "QA-M4",
        TILE,
        "                if (description.isNotEmpty)",
        "                if (false)",
        'AC-3 Nominal / Sc.3 "chaque tuile porte la DESCRIPTION de son '
        'echeance" -- la description n\'est plus jamais rendue',
        "TUE",
    ),
    (
        "QA-M5",
        HUB,
        "    final couleur = estActif\n"
        "        ? ConcentrationTokens.moduleActif.couleur\n"
        "        : ConcentrationTokens.moduleGrise.couleur;",
        "    final couleur = ConcentrationTokens.moduleActif.couleur;",
        'AC-2 Nominal / Sc.2 "les modules Respiration et Concentration sont '
        'visibles mais GRISES" -- plus aucune entree n\'est estompee',
        "TUE",
    ),
    (
        "QA-M7",
        TOKENS,
        "static const Duration periodeRafraichissement = Duration(seconds: 30);",
        "static const Duration periodeRafraichissement = Duration(hours: 1);",
        "AC-4 Limite / RF-05 -- la periode de rafraichissement passe a 1 HEURE "
        "la ou l'AC exige AU MINIMUM une fois par MINUTE",
        "TUE",
    ),
    (
        "QA-M6",
        TILE,
        "final fond = gradient.backgroundFor(temps.progression);",
        "final fond = gradient.backgroundFor(1);",
        "CONTROLE POSITIF -- la tuile rend TOUJOURS le bleu. Ce mutant est deja "
        "tue au 2026-08-02 ; s'il survit, le HARNAIS est casse et AUCUN autre "
        "resultat de ce script n'est interpretable",
        "TUE",
    ),
]


def _lire(p: str) -> str:
    return io.open(p, encoding="utf-8").read()


def _ecrire(p: str, s: str) -> None:
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)


def _preparer_copie(dest: str) -> None:
    """Copie MINIMALE du projet : le depot d'origine n'est jamais touche."""
    os.makedirs(dest, exist_ok=True)
    for d in ("lib", "test"):
        shutil.copytree(os.path.join(DEPOT, d), os.path.join(dest, d))
    for f in ("pubspec.yaml", "pubspec.lock", "analysis_options.yaml"):
        src = os.path.join(DEPOT, f)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dest, f))
    subprocess.run(
        ["flutter", "pub", "get"],
        cwd=dest,
        capture_output=True,
        text=True,
        shell=True,
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
    racine = tempfile.mkdtemp(prefix="qa_us011_")
    travail = os.path.join(racine, "copie")
    print("Copie isolee : %s" % travail)
    print("Depot d'origine : %s (JAMAIS modifie)" % DEPOT)
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
        for mid, rel, motif, remplacement, clause, attendu in MUTANTS:
            chemin = os.path.join(travail, rel.replace("/", os.sep))
            origine = _lire(chemin)
            if motif not in origine:
                print("[ECHEC] %s : MOTIF INTROUVABLE dans %s" % (mid, rel))
                print("        Un motif introuvable n'est PAS un succes : le")
                print("        controle cesserait de controler en silence.")
                echecs.append(mid)
                continue
            _ecrire(chemin, origine.replace(motif, remplacement, 1))
            code, sortie = _flutter_test(travail)
            _ecrire(chemin, origine)

            obtenu = "TUE" if code != 0 else "SURVIT"
            rouges = _rouges(sortie)
            ok = obtenu == attendu
            print(
                "%-7s %-7s (attendu %s) %s | %d rouge(s)"
                % (mid, obtenu, attendu, "[OK]" if ok else "[ECHEC]", len(rouges))
            )
            print("        clause : %s" % clause)
            for r in rouges[:4]:
                print("        ROUGE: %s" % r)
            if not ok:
                echecs.append(mid)
            sys.stdout.flush()

        print()
        if echecs:
            print(
                "CRITERE DE SORTIE NON ATTEINT -- %d mutant(s) au mauvais verdict : %s"
                % (len(echecs), ", ".join(echecs))
            )
            return 1
        print("CRITERE DE SORTIE ATTEINT -- tous les mutants sont TUES.")
        return 0
    finally:
        shutil.rmtree(racine, ignore_errors=True)


def selftest() -> int:
    """Autotest de MUTATION du script lui-meme.

    Le projet exige que tout script de controle porte son autotest, avec des
    mutants qui ne sont PAS tires du vocabulaire de la regle testee. On verifie
    ici la seule logique propre au script : la lecture d'un verdict.
    """
    cas = [
        ("00:05 +102: All tests passed!", 0, []),
        (
            "00:03 +12 -1: chemin/x_test.dart: une assertion [E]\n"
            "00:03 +12 -1: Some tests failed.",
            1,
            ["une assertion"],
        ),
        (
            "00:03 +9 -2: a/b_test.dart: alpha [E]\n"
            "00:03 +9 -2: a/b_test.dart: beta [E]\n",
            1,
            ["alpha", "beta"],
        ),
    ]
    echecs = 0
    for sortie, code, attendus in cas:
        obtenus = _rouges(sortie)
        # comparaison en ENSEMBLES, jamais en cardinaux (lecon US-00.5)
        if set(obtenus) != set(attendus):
            print("[ECHEC] ensembles differents : %s != %s" % (obtenus, attendus))
            echecs += 1
        else:
            print("[OK] %d rouge(s) correctement extrait(s)" % len(obtenus))
    # un motif introuvable doit etre un ECHEC, pas un silence
    if "motif_qui_n_existe_pas" in _lire(os.path.join(DEPOT, TILE)):
        print("[ECHEC] le motif temoin ne devrait pas exister")
        echecs += 1
    else:
        print("[OK] un motif absent est bien detectable")
    # Chaque mutant doit avoir un motif REELLEMENT present dans le depot.
    # (Un `for ... else` imprimerait [OK] inconditionnellement : le `else` d'une
    #  boucle s'execute des lors qu'il n'y a pas eu de `break`. Defaut trouve et
    #  corrige pendant la QA du 2026-08-02 -- classe de defaut du projet, cette
    #  fois dans l'instrument de mesure lui-meme.)
    manquants = [
        mid
        for mid, rel, motif, _r, _c, _a in MUTANTS
        if motif not in _lire(os.path.join(DEPOT, rel.replace("/", os.sep)))
    ]
    if manquants:
        print("[ECHEC] motif(s) absent(s) du depot : %s" % ", ".join(manquants))
        echecs += len(manquants)
    else:
        print("[OK] les %d motifs de mutation existent dans le depot" % len(MUTANTS))
    # le controle positif doit exister, sinon la campagne ne prouve rien
    if not any(m[0] == "QA-M6" for m in MUTANTS):
        print("[ECHEC] aucun controle positif")
        echecs += 1
    else:
        print("[OK] le controle positif QA-M6 est present")
    print("\nAutotest : %d echec(s)." % echecs)
    return 1 if echecs else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    raise SystemExit(selftest() if args.selftest else campagne())
