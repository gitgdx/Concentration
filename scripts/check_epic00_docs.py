#!/usr/bin/env python3
"""Controle du critere de cloture 114 d'EPIC_00 : "Documentation a jour".

POURQUOI CE SCRIPT EXISTE
-------------------------
Le critere 114 disait "Documentation a jour" -- une formule INFALSIFIABLE : aucune
sortie ne peut la contredire, donc la cocher ou la laisser vide releve de l'opinion.
Le corpus du projet a deja tranche la methode a employer (reports/US-00.7/corpus_sweep.md) :
    "un critere de sortie se publie comme un SCRIPT EXECUTABLE, jamais recopie a la main".
Ce fichier EST ce critere. Il enumere les livrables documentaires d'EPIC_00 et, pour
chacun, un MARQUEUR LITTERAL qui atteste que le document est a jour -- pas seulement
present. Une phrase peut mentir ; un marqueur absent se voit.

CE QU'IL PROUVE / CE QU'IL NE PROUVE PAS
----------------------------------------
Il prouve : chaque livrable enumere existe ET porte son marqueur.
Il NE prouve PAS que le contenu est exact : aucune machine ne lit le sens d'un
paragraphe. C'est un controle de PRESENCE et de FRAICHEUR, pas de veracite.
Borne assumee : ce controle N'EST PAS en CI (comme selftest_coverage_ratchet.py avant
lui, il se lance a la main) -- meme dette que celle deja nommee dans CLAUDE.md.

CONVENTIONS DU PROJET APPLIQUEES ICI
------------------------------------
- Une regle n'existe qu'en UN SEUL exemplaire : LIVRABLES est la source unique, le
  compte n'est jamais ecrit a la main (len() partout).
- Aucun numero de ligne : un numero glisse en silence, un marqueur litteral non.
- Le script porte son AUTOTEST DE MUTATION (--selftest) et compare des ENSEMBLES,
  jamais des cardinaux : un decompte egal n'est pas une preuve d'equivalence.
- Sortie ASCII et stdout reconfigure : US-00.6 a paye deux fois le plantage cp1252.

Usage :
    python scripts/check_epic00_docs.py            # controle du depot
    python scripts/check_epic00_docs.py --selftest # autotest de mutation
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

# --- SOURCE UNIQUE : livrables documentaires d'EPIC_00 et marqueur de fraicheur ---
# (chemin relatif a la racine du depot, marqueur litteral attendu dans le fichier)
LIVRABLES: tuple[tuple[str, str], ...] = (
    ("docs/governance/CONSTITUTION.md", "Version 1.2"),
    ("docs/governance/STACK_PROFILE.md", "flutter"),
    ("docs/governance/TRACKS.md", "QUICK"),
    ("docs/governance/WORKFLOW.yaml", "epic_closure"),
    ("docs/adr/ADR-001-choix-de-stack.md", "Accepté"),
    ("docs/adr/ADR-005-convention-migrations-reversibles.md", "Accepté"),
    ("docs/adr/ADR-006-protection-branche-principale.md", "Accepté"),
    ("docs/adr/ADR-007-application-protection-branche.md", "ADR-006"),
    ("docs/architecture/MIGRATIONS.md", "réversible"),
    ("docs/GIT_PROTECTION.md", "Conditions de fusion"),
    ("docs/epics/EPIC_00-fondations.md", "Critères de clôture"),
)

ABSENT = "ABSENT"
MARQUEUR = "MARQUEUR"


def verifier(racine: Path) -> list[tuple[str, str]]:
    """Rend la liste des ecarts : (chemin, motif). Vide == conforme."""
    ecarts: list[tuple[str, str]] = []
    for chemin, marqueur in LIVRABLES:
        cible = racine / chemin
        if not cible.is_file():
            ecarts.append((chemin, ABSENT))
            continue
        texte = cible.read_text(encoding="utf-8", errors="replace")
        if marqueur not in texte:
            ecarts.append((chemin, MARQUEUR))
    return ecarts


def _ecrire_corpus_synthetique(racine: Path) -> None:
    """Corpus SYNTHETIQUE conforme : aucun fichier reel du depot n'est touche."""
    for chemin, marqueur in LIVRABLES:
        cible = racine / chemin
        cible.parent.mkdir(parents=True, exist_ok=True)
        cible.write_text(
            "corpus synthetique d autotest\n" + marqueur + "\nfin\n",
            encoding="utf-8",
        )


def selftest() -> int:
    """Autotest de MUTATION : le controle doit REFUSER ce qui est faux.

    Les mutants ne sont pas tires du vocabulaire de la regle : on SUPPRIME un
    fichier et on VIDE un marqueur, sans jamais reutiliser les motifs testes.
    Les verdicts sont compares en ENSEMBLES, pas en nombres.
    """
    resultats: list[tuple[str, bool, str]] = []

    def poser(nom: str, ok: bool, detail: str) -> None:
        resultats.append((nom, ok, detail))

    with tempfile.TemporaryDirectory() as tmp:
        racine = Path(tmp)

        # CAS 1 -- corpus conforme : aucun ecart attendu.
        _ecrire_corpus_synthetique(racine)
        ecarts = verifier(racine)
        poser("corpus conforme => 0 ecart", ecarts == [], "ecarts=%r" % (ecarts,))

        # CAS 2 -- MUTANT "fichier supprime" : l'ecart doit nommer CE fichier.
        victime_absente = LIVRABLES[0][0]
        (racine / victime_absente).unlink()
        attendu = {(victime_absente, ABSENT)}
        obtenu = set(verifier(racine))
        poser(
            "mutant fichier supprime => refus qui NOMME le fichier",
            obtenu == attendu,
            "attendu=%r obtenu=%r" % (sorted(attendu), sorted(obtenu)),
        )

        # CAS 3 -- MUTANT "marqueur retire" : present mais perime.
        _ecrire_corpus_synthetique(racine)  # remise a zero
        victime_marqueur = LIVRABLES[-1][0]
        (racine / victime_marqueur).write_text(
            "document present mais sans son marqueur\n", encoding="utf-8"
        )
        attendu = {(victime_marqueur, MARQUEUR)}
        obtenu = set(verifier(racine))
        poser(
            "mutant marqueur retire => refus DISTINCT de l absence",
            obtenu == attendu,
            "attendu=%r obtenu=%r" % (sorted(attendu), sorted(obtenu)),
        )

        # CAS 4 -- les deux mutants ne rendent PAS le meme motif (sinon le
        # controle ne distinguerait pas "absent" de "perime").
        poser(
            "les deux motifs sont DISTINCTS",
            ABSENT != MARQUEUR,
            "%s vs %s" % (ABSENT, MARQUEUR),
        )

    refus = sum(1 for _, ok, _ in resultats if not ok)
    for nom, ok, detail in resultats:
        print("  [%s] %s" % ("OK" if ok else "ECHEC", nom))
        if not ok:
            print("        %s" % detail)
    print(
        "\nAutotest : %d assertions, %d echec(s), %d livrables sous controle."
        % (len(resultats), refus, len(LIVRABLES))
    )
    return 1 if refus else 0


def main() -> int:
    if "--selftest" in sys.argv[1:]:
        return selftest()

    racine = Path(__file__).resolve().parent.parent
    ecarts = verifier(racine)
    motifs = dict(ecarts)

    print("Critere 114 d'EPIC_00 -- livrables documentaires (racine : %s)" % racine)
    for chemin, marqueur in LIVRABLES:
        motif = motifs.get(chemin)
        etat = "OK     " if motif is None else motif.ljust(7)
        print("  [%s] %-56s <<%s>>" % (etat, chemin, marqueur))

    if ecarts:
        print(
            "\nECHEC : %d ecart(s) sur %d livrables. Le critere 114 n est PAS satisfait."
            % (len(ecarts), len(LIVRABLES))
        )
        return 1
    print(
        "\nOK : %d livrables presents et porteurs de leur marqueur."
        " Controle de PRESENCE et de FRAICHEUR -- pas de veracite du contenu."
        % len(LIVRABLES)
    )
    return 0


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass  # environnements sans reconfigure : la sortie reste ASCII
    sys.exit(main())
