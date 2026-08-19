#!/usr/bin/env python3
"""Les DEUX controles qu'ADR-010 section 1 exige, EXECUTABLES (US-01.2, T13).

POURQUOI CE FICHIER EXISTE
--------------------------
ADR-008 section 1 exigeait deja de monter LA RACINE, et RIEN NE LE VERIFIAIT :
la revue du 2026-08-02 a releve que 11 tests sur 13 montaient
`MaterialApp(home: HubPage)`. Le controle existant, check_gherkin_mapping.py,
ne pouvait PAS le voir -- il compare des TITRES, pas des etapes, et il
l'imprime lui-meme. C'est ce trou qui a laisse passer le bloquant B-2.

ADR-010 section 1 durcit la clause et exige que les deux controles ci-dessous
« se publient comme des commandes EXECUTABLES, jamais comme une ligne de DoD
affirmee ».

  CONTROLE 1  tout `pumpWidget(` de test/e2e/** monte `ConcentrationApp`
  CONTROLE 2  test/e2e/** ne contient AUCUN magasin factice

DEUX PIEGES DEJA PAYES PAR CE DEPOT, ET TOUS DEUX PRESENTS DANS LE CORPUS REEL
------------------------------------------------------------------------------
  1. LA RECHERCHE DOIT ETRE MULTILIGNE. `dart format` reporte volontiers
     l'argument sur la ligne suivante : dans les DEUX fichiers de test/e2e/,
     `pumpWidget(` et son argument sont SUR DEUX LIGNES. Un controle ligne a
     ligne ne verrait AUCUN montage de racine et crierait sur tout.
  2. LES COMMENTAIRES DOIVENT ETRE IGNORES. hub_echeances_test.dart contient
     `MaterialApp(home: HubPage)` DANS UN COMMENTAIRE QUI EXPLIQUE LE DEFAUT.
     Un controle lexical naif BLANCHIRAIT (s'il excluait les lignes marquees)
     ou CRIERAIT A TORT (s'il ne les excluait pas).

CE QU'IL N'ATTESTE PAS
----------------------
  - Il ne dit RIEN de ce que les tests ASSERTENT. Monter la racine et
    traverser un vrai magasin sont des conditions NECESSAIRES, jamais
    suffisantes : un test peut faire les deux et n'assertionner que des
    widgets. C'est la colonne « Type d'assertion » des criteres de test qui
    couvre cela, et elle se lit par un humain.
  - Il ne verifie AUCUNE correspondance scenario <-> test : c'est
    check_gherkin_mapping.py, et lui compare des TITRES.

Usage :
    python scripts/check_e2e_persistance.py
    python scripts/check_e2e_persistance.py --selftest
"""

from __future__ import annotations

import argparse
import io
import re
import sys
from pathlib import Path

for _flux in (sys.stdout, sys.stderr):
    try:
        _flux.reconfigure(errors="replace")
    except (AttributeError, ValueError):
        pass

RACINE = Path(__file__).resolve().parents[1]
DOSSIER_E2E = RACINE / "test" / "e2e"
RACINE_ATTENDUE = "ConcentrationApp"

# CONTROLE 2 -- ce qui fait d'un identifiant un MAGASIN FACTICE.
#
# ⛔ LA DISCRIMINATION EST LE COEUR DE CETTE REGLE, et elle n'est pas
# cosmetique : `FakeClock` porte « Fake » et n'est PAS un magasin factice --
# c'est l'horloge injectee d'ADR-002, du CODE DE PRODUCTION, sans aucun
# rapport avec la couche de donnees. Un controle qui la signalerait rendrait
# le gate ROUGE sur un corpus conforme, donc il serait desactive, donc il ne
# protegerait plus rien. Le mutant M4 de l'autotest verifie ce point PRECIS.
_SUBSTITUT = r"(?:Fake|Mock|Stub|InMemory|EnMemoire|Factice|Faux|Bidon)"
_COUCHE_DONNEES = r"(?:Store|Magasin|Repository|Depot|Dao|Db|Database)"
MOTIFS_FACTICES = (
    re.compile(r"\b%s\w*%s\w*\b" % (_SUBSTITUT, _COUCHE_DONNEES)),
    re.compile(r"\b\w*%s\w*%s\b" % (_COUCHE_DONNEES, _SUBSTITUT)),
)


def sans_commentaires(source: str) -> str:
    """Retire les commentaires `//` et `/* */`, en PRESERVANT les positions.

    ⛔ Les caracteres retires sont remplaces par des espaces (et les sauts de
    ligne conserves) : un numero de ligne reste donc juste, et une recherche
    MULTILIGNE n'est pas faussee par un decalage.

    ⚠️ Les chaines de caracteres sont PRESERVEES : `find.text('MaterialApp')`
    resterait donc visible. C'est deliberement CONSERVATEUR -- ce controle
    prefere crier a tort (visible, corrigible) que blanchir en silence.
    """
    sortie = []
    i = 0
    n = len(source)
    while i < n:
        deux = source[i : i + 2]
        if deux == "//":
            while i < n and source[i] != "\n":
                sortie.append(" ")
                i += 1
        elif deux == "/*":
            while i < n and source[i : i + 2] != "*/":
                sortie.append("\n" if source[i] == "\n" else " ")
                i += 1
            sortie.append("  ")
            i += 2
        else:
            sortie.append(source[i])
            i += 1
    return "".join(sortie)


def controle_racine(nom: str, source: str) -> list:
    """CONTROLE 1 : tout `pumpWidget(` monte la RACINE."""
    ecarts = []
    code = sans_commentaires(source)
    for occurrence in re.finditer(r"pumpWidget\s*\(", code):
        debut = occurrence.end()
        # ⛔ MULTILIGNE : on saute espaces ET sauts de ligne avant de lire le
        # premier identifiant. C'est le piege nº 1.
        reste = code[debut : debut + 400].lstrip()
        premier = re.match(r"(?:const\s+)?([A-Za-z_$][\w$]*)", reste)
        monte = premier.group(1) if premier else "(rien)"
        if monte != RACINE_ATTENDUE:
            ligne = code.count("\n", 0, occurrence.start()) + 1
            ecarts.append(
                "%s:%d : pumpWidget monte « %s » et non « %s »"
                % (nom, ligne, monte, RACINE_ATTENDUE)
            )
    return ecarts


def controle_magasin(nom: str, source: str) -> list:
    """CONTROLE 2 : aucun magasin factice."""
    ecarts = []
    code = sans_commentaires(source)
    for motif in MOTIFS_FACTICES:
        for occurrence in motif.finditer(code):
            ligne = code.count("\n", 0, occurrence.start()) + 1
            ecarts.append(
                "%s:%d : magasin factice « %s » — ADR-010 §1 l'interdit dans "
                "test/e2e/**" % (nom, ligne, occurrence.group(0))
            )
    return ecarts


CONTROLES = {"racine": controle_racine, "magasin": controle_magasin}


def evaluer(fichiers: dict) -> dict:
    """Rend {nom_du_controle: [ecarts]} — un DICTIONNAIRE, pas un compte."""
    resultat = {nom: [] for nom in CONTROLES}
    for nom_fichier, source in fichiers.items():
        for nom_controle, fonction in CONTROLES.items():
            resultat[nom_controle].extend(fonction(nom_fichier, source))
    return resultat


def corpus_reel() -> dict:
    if not DOSSIER_E2E.is_dir():
        return {}
    return {
        chemin.relative_to(RACINE).as_posix(): chemin.read_text(encoding="utf-8")
        for chemin in sorted(DOSSIER_E2E.rglob("*.dart"))
    }


def contre_corpus() -> int:
    print("== ADR-010 §1 : la racine est montée, le magasin est RÉEL ==")
    fichiers = corpus_reel()
    if not fichiers:
        print("[ERREUR] aucun fichier dans test/e2e/ — ce n'est pas une mesure.")
        return 1
    for nom in fichiers:
        print("   fichier : %s" % nom)
    resultat = evaluer(fichiers)
    total = 0
    for nom_controle in sorted(resultat):
        ecarts = resultat[nom_controle]
        total += len(ecarts)
        etat = "OK " if not ecarts else "ECHEC"
        print("[%s] contrôle « %s » : %d écart(s)" % (etat, nom_controle, len(ecarts)))
        for ecart in ecarts:
            print("        - %s" % ecart)
    if total:
        print("")
        print("REFUSÉ — un E2E qui ne monte pas la racine ou qui passe par un")
        print("magasin factice ne prouve RIEN de la persistance.")
        return 1
    print("")
    print("CONFORME — les deux contrôles d'ADR-010 §1 passent.")
    return 0


# ---------------------------------------------------------------------------
# AUTOTEST DE MUTATION.
#
# Les mutants sont COMPORTEMENTAUX : ils changent ce que le CORPUS CONTIENT,
# ⛔ pas la facon dont la regle est ecrite. Les verdicts sont compares en
# ENSEMBLES de controles en echec, ⛔ jamais en cardinaux -- un decompte egal
# n'est pas une preuve d'equivalence.
# ---------------------------------------------------------------------------
CONFORME = """
import 'package:concentration/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un test', (tester) async {
    await tester.pumpWidget(
      ConcentrationApp(notifier: notifier, clock: horloge),
    );
  });
}
"""

MUTANTS = {
    # (source, ENSEMBLE des controles qui doivent echouer)
    "M0_conforme": (CONFORME, set()),
    # PIEGE nº 1 : l'argument est sur la LIGNE SUIVANTE. Un controle ligne a
    # ligne ne le verrait pas -- ni ici, ni dans le corpus reel.
    "M1_sous_arbre_multiligne": (
        CONFORME.replace(
            "      ConcentrationApp(notifier: notifier, clock: horloge),",
            "      MaterialApp(home: HubPage(notifier: notifier)),",
        ),
        {"racine"},
    ),
    # PIEGE nº 2 : le motif interdit n'est QUE dans un commentaire. Le corpus
    # REEL est dans ce cas -- un controle qui crierait ici serait faux.
    "M2_motif_seulement_en_commentaire": (
        CONFORME.replace(
            "  testWidgets('un test', (tester) async {",
            "  // La revue a releve que 11 tests montaient MaterialApp(home: HubPage)\n"
            "  // et qu un FakeDocumentStore circulait. C est un COMMENTAIRE.\n"
            "  testWidgets('un test', (tester) async {",
        ),
        set(),
    ),
    "M3_magasin_factice": (
        CONFORME.replace(
            "void main() {",
            "class MagasinFactice implements DocumentStore {}\n\nvoid main() {",
        ),
        {"magasin"},
    ),
    # ⛔ DISCRIMINATION : `FakeClock` porte « Fake » et n'est PAS un magasin.
    # Sans ce mutant, un controle trop large passerait pour rigoureux.
    "M4_FakeClock_est_licite": (
        CONFORME.replace(
            "clock: horloge",
            "clock: FakeClock(DateTime(2026, 8, 6, 8))",
        ),
        set(),
    ),
    "M5_faux_depot": (
        CONFORME.replace(
            "  testWidgets('un test', (tester) async {",
            "  final depot = FakeEcheanceRepository();\n"
            "  testWidgets('un test', (tester) async {",
        ),
        {"magasin"},
    ),
    # Le stub de plateforme est du CODE DE PRODUCTION, mais dans test/e2e/**
    # il court-circuite la persistance : ADR-010 §1 l'interdit AUSSI.
    "M6_stub_de_plateforme": (
        CONFORME.replace(
            "  testWidgets('un test', (tester) async {",
            "  final magasin = const DocumentStoreStub();\n"
            "  testWidgets('un test', (tester) async {",
        ),
        {"magasin"},
    ),
    "M7_pumpWidget_sans_argument_connu": (
        CONFORME.replace(
            "      ConcentrationApp(notifier: notifier, clock: horloge),",
            "      const SizedBox(),",
        ),
        {"racine"},
    ),
}


def selftest() -> int:
    print("== AUTOTEST DE MUTATION de check_e2e_persistance ==")
    print("   %d sources (1 conforme + %d mutants COMPORTEMENTAUX)"
          % (len(MUTANTS), len(MUTANTS) - 1))
    print("   Verdicts comparés en ENSEMBLES, ⛔ jamais en cardinaux.")
    print("")
    ecarts = []
    couverture = set()
    for nom in sorted(MUTANTS):
        source, attendu = MUTANTS[nom]
        # CONTROLE NEGATIF : un mutant qui ne mute rien ne mesure rien.
        if nom != "M0_conforme" and source == CONFORME:
            ecarts.append("%s : la source du mutant est IDENTIQUE à la conforme" % nom)
            continue
        resultat = evaluer({"mutant.dart": source})
        obtenu = {c for c, e in resultat.items() if e}
        couverture |= obtenu
        etat = "OK " if obtenu == attendu else "ECART"
        print("[%s] %-34s attendu=%s obtenu=%s"
              % (etat, nom, sorted(attendu) or "aucun", sorted(obtenu) or "aucun"))
        if obtenu != attendu:
            ecarts.append(
                "%s : manquants=%s inattendus=%s"
                % (nom, sorted(attendu - obtenu), sorted(obtenu - attendu))
            )
            for controle, details in resultat.items():
                for detail in details:
                    print("        %s : %s" % (controle, detail))
    print("")
    non_tues = sorted(set(CONTROLES) - couverture)
    print("Contrôles tués par au moins un mutant : %s" % sorted(couverture))
    if non_tues:
        print("Contrôles qu'AUCUN mutant ne tue (⛔ à ne PAS lire comme éprouvés)"
              " : %s" % non_tues)
        ecarts.append("contrôles non éprouvés : %s" % non_tues)
    if ecarts:
        print("")
        print("AUTOTEST EN ÉCHEC :")
        for e in ecarts:
            print("  - %s" % e)
        return 1
    print("")
    print("AUTOTEST OK : les deux contrôles savent rougir, et sur les bons cas.")
    return 0


def main() -> int:
    parseur = argparse.ArgumentParser(description=__doc__)
    parseur.add_argument(
        "--selftest",
        action="store_true",
        help="mesurer le POUVOIR des deux contrôles sur 1 source conforme "
        "et 7 mutants",
    )
    args = parseur.parse_args()
    return selftest() if args.selftest else contre_corpus()


if __name__ == "__main__":
    sys.exit(main())
