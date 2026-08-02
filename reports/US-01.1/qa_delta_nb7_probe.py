#!/usr/bin/env python3
"""Sonde QA du 2e passage (US-01.1) : NB-7 permet-il un FAUX VERT SILENCIEUX ?

NB-7 (audit securite, INFO) : dans `test/support/rendu_couleur.dart`,
`fondDeLaTuile` selectionne PAR POSITION (`.first`, sans assertion d'unicite)
dans un helper importe par 3 suites, alors que son voisin `couleurDuLibelle`
enonce la regle contraire (`hasLength(1)`) et l'applique.

La question QA n'est pas << est-ce inelegant >> mais << mes mutants QA-M1 et
QA-M6, qui passent par ce helper, sont-ils AFFAIBLIS >>. On la tranche par
EXECUTION, pas par relecture.

PAIRE BIDIRECTIONNELLE sur la tuile (doctrine du projet : un mutant unique ne
dit pas QUELLE boite est lue) :
  NB7-B  boite EXTERIEURE correcte / boite REELLEMENT PEINTE figee en orange.
         Le rendu est FAUX. S'il SURVIT -> faux vert silencieux demontre.
  NB7-B2 miroir : boite EXTERIEURE figee / boite PEINTE correcte.
         Le rendu est BON. S'il est TUE -> `.first` lit bien l'EXTERIEURE,
         celle qui n'est pas peinte. Les deux ensemble LOCALISENT le defaut.

PAIRE sur le garde-fou voisin (borne exacte de `hasLength(1)`) :
  NB7-C  titre AppBar colore avec la MEME couleur que le module grise.
         `.toSet()` fusionne les deux -> le garde-fou peut ne pas voir.
  NB7-C2 titre AppBar colore avec une couleur DIFFERENTE.
         `.toSet()` ne peut plus fusionner -> le garde-fou doit rougir.

CONTROLE NEGATIF (principe repris de la revue du 3e passage) :
  NB7-N  ajout d'un commentaire, aucune alteration de comportement.
         Il DOIT SURVIVRE. Sans lui, une suite qui rougirait sur TOUT
         passerait pour excellente.

ETAT AU 2026-08-02 SUR 558a475 : exit 1 -- NB7-B et NB7-C SURVIVENT.

Le depot n'est JAMAIS modifie : tout se passe dans une copie temporaire.
Aucun mutant n'est designe par un NUMERO DE LIGNE : chacun l'est par son
TEXTE, et un motif introuvable est un ECHEC, jamais un silence.
"""

from __future__ import annotations

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
HUB = "lib/features/hub/presentation/hub_page.dart"

NL = chr(10)


def _bloc(*lignes: str) -> str:
    return NL.join(lignes)


NB7B_AVANT = _bloc(
    "        child: DecoratedBox(",
    "          decoration: BoxDecoration(",
    "            color: fond.couleur,",
    "            borderRadius: BorderRadius.circular(16),",
    "          ),",
    "          child: Padding(",
)

NB7B_APRES = _bloc(
    "        child: DecoratedBox(",
    "          decoration: BoxDecoration(",
    "            color: fond.couleur,",
    "            borderRadius: BorderRadius.circular(16),",
    "          ),",
    "          child: DecoratedBox(",
    "          decoration: BoxDecoration(",
    "            color: gradient.backgroundFor(0).couleur,",
    "            borderRadius: BorderRadius.circular(16),",
    "          ),",
    "          child: Padding(",
)

NB7B2_APRES = _bloc(
    "        child: DecoratedBox(",
    "          decoration: BoxDecoration(",
    "            color: gradient.backgroundFor(0).couleur,",
    "            borderRadius: BorderRadius.circular(16),",
    "          ),",
    "          child: DecoratedBox(",
    "          decoration: BoxDecoration(",
    "            color: fond.couleur,",
    "            borderRadius: BorderRadius.circular(16),",
    "          ),",
    "          child: Padding(",
)

NB7B_FERM_AVANT = _bloc(
    "              ],", "            ),", "          ),", "        ),", "      ),", "    );"
)

NB7B_FERM_APRES = _bloc(
    "              ],",
    "            ),",
    "          ),",
    "          ),",
    "        ),",
    "      ),",
    "    );",
)

NB7C_AVANT = "appBar: AppBar(title: const Text('Concentration')),"


def _appbar_colore(token: str) -> str:
    return _bloc(
        "appBar: AppBar(",
        "        title: Text(",
        "          'Concentration',",
        "          style: TextStyle(",
        "            color: ConcentrationTokens.%s.couleur," % token,
        "          ),",
        "        ),",
        "      ),",
    )


NB7N_AVANT = "import 'package:flutter/material.dart';"
NB7N_APRES = _bloc(
    "import 'package:flutter/material.dart';",
    "// sonde NB7-N : controle negatif, aucune alteration de comportement",
)

MUTANTS = [
    (
        "NB7-B",
        TILE,
        [(NB7B_AVANT, NB7B_APRES), (NB7B_FERM_AVANT, NB7B_FERM_APRES)],
        "boite EXTERIEURE correcte / boite REELLEMENT PEINTE figee en orange. "
        "Le RENDU EST FAUX (tuile toujours orange = defaut QA-M1) mais `.first` "
        "lit la boite exterieure, restee correcte",
        "TUE",
    ),
    (
        "NB7-B2",
        TILE,
        [(NB7B_AVANT, NB7B2_APRES), (NB7B_FERM_AVANT, NB7B_FERM_APRES)],
        "MIROIR : boite EXTERIEURE figee en orange / boite PEINTE correcte. "
        "Le RENDU EST BON -- un rouge ici prouve que `.first` lit "
        "l'EXTERIEURE, celle qui n'est pas peinte",
        "TUE",
    ),
    (
        "NB7-C",
        HUB,
        [(NB7C_AVANT, _appbar_colore("moduleGrise"))],
        "titre AppBar colore avec la MEME couleur que le module grise -- "
        "`.toSet()` fusionne les deux valeurs",
        "TUE",
    ),
    (
        "NB7-C2",
        HUB,
        [(NB7C_AVANT, _appbar_colore("moduleActif"))],
        "titre AppBar colore avec une couleur DIFFERENTE -- `.toSet()` ne peut "
        "plus fusionner : borne EXACTE du garde-fou hasLength(1)",
        "TUE",
    ),
    (
        "NB7-N",
        TILE,
        [(NB7N_AVANT, NB7N_APRES)],
        "CONTROLE NEGATIF -- aucune alteration. DOIT SURVIVRE, sinon la suite "
        "rougit sur tout et aucun autre resultat n'est interpretable",
        "SURVIT",
    ),
]


def _lire(p: str) -> str:
    return io.open(p, encoding="utf-8").read()


def _ecrire(p: str, s: str) -> None:
    io.open(p, "w", encoding="utf-8", newline=NL).write(s)


def _flutter_test(cwd: str):
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


def _rouges(sortie: str):
    t = re.findall(r"^\d\d:\d\d \+\d+ -\d+: (.+?) \[E\]$", sortie, re.M)
    return sorted({x.split(".dart: ")[-1] for x in t})


def main() -> int:
    racine = tempfile.mkdtemp(prefix="qa_nb7_")
    travail = os.path.join(racine, "copie")
    print("Copie isolee    : %s" % travail)
    print("Depot d'origine : %s (JAMAIS modifie)" % DEPOT)
    try:
        os.makedirs(travail, exist_ok=True)
        for d in ("lib", "test"):
            shutil.copytree(os.path.join(DEPOT, d), os.path.join(travail, d))
        for f in ("pubspec.yaml", "pubspec.lock", "analysis_options.yaml"):
            s = os.path.join(DEPOT, f)
            if os.path.exists(s):
                shutil.copy2(s, os.path.join(travail, f))
        subprocess.run(
            ["flutter", "pub", "get"],
            cwd=travail,
            capture_output=True,
            text=True,
            shell=True,
        )

        code, sortie = _flutter_test(travail)
        if code != 0:
            print("[ABANDON] la BASELINE est deja rouge -- rien n'est mesurable.")
            for r in _rouges(sortie):
                print("   ROUGE: %s" % r)
            return 1
        b = re.search(r"\+(\d+): All tests passed!", sortie)
        print("Baseline        : %s test(s) verts." % (b.group(1) if b else "?"))
        print()

        echecs = []
        for mid, rel, paires, clause, attendu in MUTANTS:
            chemin = os.path.join(travail, rel.replace("/", os.sep))
            origine = _lire(chemin)
            texte = origine
            introuvable = None
            for motif, remplacement in paires:
                if motif not in texte:
                    introuvable = motif[:70]
                    break
                texte = texte.replace(motif, remplacement, 1)
            if introuvable is not None:
                print("[ECHEC] %s : MOTIF INTROUVABLE -> %r" % (mid, introuvable))
                print("        Un motif introuvable n'est PAS un succes.")
                echecs.append(mid)
                continue
            _ecrire(chemin, texte)
            code, sortie = _flutter_test(travail)
            _ecrire(chemin, origine)
            obtenu = "TUE" if code != 0 else "SURVIT"
            rouges = _rouges(sortie)
            ok = obtenu == attendu
            print(
                "%-7s %-7s (attendu %-7s) %s | %d rouge(s)"
                % (mid, obtenu, attendu, "[OK]" if ok else "[ECHEC]", len(rouges))
            )
            print("        clause : %s" % clause)
            for r in rouges[:5]:
                print("        ROUGE: %s" % r)
            if not ok:
                echecs.append(mid)
            sys.stdout.flush()

        print()
        if echecs:
            print(
                "SONDE NB-7 : %d mutant(s) au mauvais verdict : %s"
                % (len(echecs), ", ".join(echecs))
            )
            return 1
        print("SONDE NB-7 : tous les verdicts sont conformes a l'attendu.")
        return 0
    finally:
        shutil.rmtree(racine, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
