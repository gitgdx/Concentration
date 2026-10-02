#!/usr/bin/env python3
"""Critere L-4 de l'Integration Lock d'US-01.3 : egalite des ENSEMBLES de codes de cause.

CE QU'IL PROUVE
---------------
Les codes de la colonne `Code` du tableau §5.2 de docs/design/US-01.3-DESIGN-UX.md
forment, apres normalisation (minuscules, tiret -> souligne), EXACTEMENT le meme
ensemble que la colonne `Code` des tableaux §6.2 et §6.2 bis de
docs/architecture/REGISTRE_DEPLOIEMENTS.md. Il compare des ENSEMBLES, jamais des
cardinaux : un decompte egal n'est pas une preuve d'equivalence.

CE QU'IL NE PROUVE PAS
----------------------
Ni que chaque code a le bon message, ni la bonne issue, ni qu'un outil l'emet :
c'est un controle de CORRESPONDANCE entre deux documents de design. La colonne
« Devient » du §5.0 de l'UX (anciennes formes) est volontairement ignoree.

Origine : ecrit par @Architect pendant L-4 (2026-09-30) dans le scratchpad de
session, rendu durable ici par la session principale. A reprendre par T5
(verdicts.py devient alors l'exemplaire de reference).

Usage :
    python reports/US-01.3/egalite_codes_criterion.py            # 0 egal, 1 ecart
    python reports/US-01.3/egalite_codes_criterion.py --selftest # autotest de mutation
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
UX = RACINE / "docs" / "design" / "US-01.3-DESIGN-UX.md"
REGISTRE = RACINE / "docs" / "architecture" / "REGISTRE_DEPLOIEMENTS.md"


def _section(txt: str, debut: str, fin: str) -> str:
    a = txt.index(debut)
    return txt[a:txt.index(fin, a + len(debut))]


def _colonne(sec: str, nom: str) -> set[str]:
    lignes = [l for l in sec.splitlines() if l.startswith("|")]
    tete = [c.strip() for c in lignes[0].strip("|").split("|")]
    k = tete.index(nom)
    out: set[str] = set()
    for l in lignes[2:]:
        cells = [c.strip() for c in l.strip().strip("|").split("|")]
        if len(cells) != len(tete):
            raise ValueError("ligne mal formee : " + l[:80])
        out |= set(re.findall(r"`([^`]+)`", cells[k]))
    return out


def _norm(s: set[str]) -> set[str]:
    return {x.lower().replace("-", "_") for x in s}


def ensembles(ux: str, rg: str) -> tuple[set[str], set[str], set[str], set[str]]:
    u = _norm(_colonne(_section(ux, "### 5.2 ", "\n## 6."), "Code"))
    d62 = _norm(_colonne(_section(rg, "### 6.2 · ", "### 6.2 bis"), "Code"))
    d62b = _norm(_colonne(_section(rg, "### 6.2 bis", "### 6.3"), "Code"))
    return u, d62 | d62b, d62, d62b


def controle(ux: str, rg: str, bavard: bool = True) -> int:
    u, d, d62, d62b = ensembles(ux, rg)
    if bavard:
        print("UX (%d) : %s" % (len(u), " ".join(sorted(u))))
        print("REGISTRE (%d = 6.2:%d + 6.2bis:%d, intersection %d) : %s"
              % (len(d), len(d62), len(d62b), len(d62 & d62b), " ".join(sorted(d))))
        print("DANS 6.2 ET 6.2bis :", sorted(d62 & d62b))
        print("UX - REGISTRE :", sorted(u - d))
        print("REGISTRE - UX :", sorted(d - u))
    return 0 if u == d else 1


def selftest() -> int:
    """Mutants tires de la STRUCTURE des tableaux, jamais du vocabulaire des codes."""
    ux = UX.read_text(encoding="utf-8")
    rg = REGISTRE.read_text(encoding="utf-8")
    echecs = []
    if controle(ux, rg, bavard=False) != 0:
        echecs.append("corpus reel : attendu 0")
    u, _, _, _ = ensembles(ux, rg)
    un_code = sorted(u)[0]
    # M1 : un code de l'UX disparait (sa cellule est videe) -> ecart attendu
    sec = _section(ux, "### 5.2 ", "\n## 6.")
    for ligne in sec.splitlines():
        if ligne.startswith("|") and re.search(r"`%s`" % re.escape(un_code), ligne.replace("-", "_").lower()):
            break
    else:
        echecs.append("M1 : ligne du code introuvable")
        ligne = None
    if ligne is not None:
        cellules = ligne.split("|")
        mut = "|".join(re.sub(r"`[^`]+`", "", c) if re.search(r"`", c) else c for c in cellules)
        if controle(ux.replace(ligne, mut, 1), rg, bavard=False) != 1:
            echecs.append("M1 : code retire cote UX non detecte")
    # M2 : un code etranger apparait dans le registre (meme cardinal cote UX si M1 combine)
    sec_b = _section(rg, "### 6.2 bis", "### 6.3")
    lignes_b = [l for l in sec_b.splitlines() if l.startswith("|")]
    derniere = lignes_b[-1]
    etrangere = re.sub(r"`[^`]+`", "`zz_mutant_hors_jeu`", derniere, count=1)
    if controle(ux, rg.replace(derniere, derniere + "\n" + etrangere, 1), bavard=False) != 1:
        echecs.append("M2 : code etranger cote registre non detecte")
    # M3 : meme CARDINAL mais ensembles differents (M1 + M2) -> doit rester un ecart
    if ligne is not None and controle(ux.replace(ligne, mut, 1),
                                      rg.replace(derniere, derniere + "\n" + etrangere, 1),
                                      bavard=False) != 1:
        echecs.append("M3 : cardinaux egaux, ensembles differents non detecte")
    for e in echecs:
        print("ECHEC", e)
    print("selftest :", "OK (corpus reel + 3 mutants)" if not echecs else "%d echec(s)" % len(echecs))
    return 0 if not echecs else 1


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass
    if "--selftest" in sys.argv[1:]:
        sys.exit(selftest())
    sys.exit(controle(UX.read_text(encoding="utf-8"), REGISTRE.read_text(encoding="utf-8")))
