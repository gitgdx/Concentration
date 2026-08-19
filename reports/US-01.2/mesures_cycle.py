#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mesures du CYCLE d'US-01.2 — matière pour /audit-methodo.

⛔ CE SCRIPT MESURE, IL NE JUGE PAS.
Il n'a donc AUCUN verdict, AUCUN seuil, et il ne peut pas « échouer » sur un
chiffre : un cycle plus long ou plus court n'est ni un succès ni un échec pour
lui. La convention du projet « tout script de CONTRÔLE porte son autotest de
mutation » ne s'applique pas telle quelle — il n'y a pas de règle à falsifier.

CE QU'IL PORTE À LA PLACE, ET C'EST LE VRAI RISQUE ICI : une GARDE
D'ANTI-VACUITÉ sur chaque extraction. Un script de mesure dont le motif cesse
de matcher rend « 0 » — et 0 ressemble à une réponse légitime. C'est exactement
le défaut `NB-C` relevé sur `check_e2e_persistance.py` (« le contrôle racine
passe À VIDE »). Ici, toute extraction vide fait sortir en ERREUR, bruyamment.

⛔ AUCUN nombre n'est écrit en dur : tout est lu dans le dépôt à l'exécution.
C'est le remède du défaut nº 1 du projet — « ne jamais écrire à la main un
résultat qu'une commande produit ».

Usage :
    python reports/US-01.2/mesures_cycle.py
    python reports/US-01.2/mesures_cycle.py --selftest   (voir plus bas)

Le `--selftest` ne teste pas les chiffres : il vérifie que LES GARDES MORDENT,
en soumettant aux extracteurs des entrées vides ou hors-motif.
"""

from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

# Remède appliqué à ce script lui-même : `cp1252` a cassé TROIS instruments en
# deux jours sur ce projet (lanceur de mutants de @CyberSecurity, deux scripts
# de @QA_Tester), dans trois rôles différents. Une ligne suffisait.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RACINE = Path(__file__).resolve().parents[2]
TRACE = RACINE / "docs" / "trace" / "US-01.2" / "events.jsonl"
BASE = "main"

# Familles de fichiers : (libellé, prédicat sur le chemin). L'ordre compte —
# premier prédicat vrai gagne.
FAMILLES = [
    ("CODE   lib/", lambda p: p.startswith("lib/")),
    ("TESTS  test/", lambda p: p.startswith("test/")),
    ("SPEC   .feature", lambda p: p.startswith("tests/features/")),
    ("DOC    rapports d'audit", lambda p: p.startswith("reports/")),
    ("DOC    Story File", lambda p: p.startswith("docs/stories/")),
    ("DOC    SCB", lambda p: "STORY_CERTIFICATION_BOARD" in p),
    ("DOC    PROJECT_LOG", lambda p: "PROJECT_LOG" in p),
    ("DOC    docs/ (design, ADR)", lambda p: p.startswith("docs/")),
    ("OUTIL  scripts/", lambda p: p.startswith("scripts/")),
    ("AUTRE", lambda p: True),
]

EST_DOC = lambda libelle: libelle.startswith("DOC")
EST_PRODUIT = lambda libelle: libelle.startswith(("CODE", "TESTS"))


class Vacuite(RuntimeError):
    """Une extraction a rendu VIDE là où elle doit rendre quelque chose."""


def git(*args: str) -> str:
    """Exécute git avec une LISTE d'arguments — ⛔ jamais via un shell.

    Motif mesuré sur ce projet : un backtick dans une chaîne passée au shell a
    déclenché une substitution de commande et amputé un mot dans une trace
    append-only, que `validate_trace.py` a déclarée conforme.
    """
    sortie = subprocess.run(
        ["git", *args],
        cwd=RACINE,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if sortie.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} → {sortie.returncode}\n{sortie.stderr}")
    return sortie.stdout


def garde(valeur, quoi: str):
    """Refuse une extraction vide. C'est la seule chose que ce script sait rater."""
    if not valeur:
        raise Vacuite(
            f"EXTRACTION VIDE : {quoi}. ⛔ Ce n'est PAS un résultat — le motif a "
            f"cessé de matcher, ou le périmètre a bougé. Corriger l'extracteur, "
            f"⛔ jamais consigner ce vide comme une mesure."
        )
    return valeur


# --------------------------------------------------------------------------
# Extracteurs — chacun rend une donnée BRUTE, aucune interprétation
# --------------------------------------------------------------------------

def lire_evenements(chemin: Path = TRACE) -> list[dict]:
    lignes = [l for l in chemin.read_text(encoding="utf-8").splitlines() if l.strip()]
    garde(lignes, f"aucun événement dans {chemin}")
    evts = [json.loads(l) for l in lignes]
    for e in evts:
        e["_t"] = datetime.fromisoformat(e["ts"])
    return evts


def volume_par_famille(diff_numstat: str) -> dict[str, int]:
    """Somme les lignes AJOUTÉES par famille de fichiers."""
    garde(diff_numstat.strip(), f"`git diff --numstat {BASE}...HEAD` n'a rien rendu")
    total: dict[str, int] = defaultdict(int)
    vues = 0
    for ligne in diff_numstat.splitlines():
        champs = ligne.split("\t")
        if len(champs) < 3 or champs[0] == "-":  # binaire
            continue
        ajouts, chemin = int(champs[0]), champs[2].replace("\\", "/")
        for libelle, predicat in FAMILLES:
            if predicat(chemin):
                total[libelle] += ajouts
                vues += 1
                break
    garde(vues, "aucun fichier classé — les prédicats de FAMILLES ne matchent plus")
    return dict(total)


def intervalles(evts: list[dict], seuil_heures: float) -> list[tuple[float, str, str]]:
    grands = []
    for precedent, suivant in zip(evts, evts[1:]):
        heures = (suivant["_t"] - precedent["_t"]).total_seconds() / 3600
        if heures >= seuil_heures:
            grands.append((heures, precedent["event"], suivant["event"]))
    return grands


# --------------------------------------------------------------------------
# Rendu
# --------------------------------------------------------------------------

def titre(texte: str) -> None:
    print(f"\n{texte}\n" + "─" * len(texte))


def mesurer() -> int:
    tete = git("rev-parse", "--short", "HEAD").strip()
    print(f"MESURES DU CYCLE US-01.2 — dépôt à {tete}, base « {BASE} »")
    print("⛔ Aucun chiffre n'est écrit en dur : tout est lu à l'exécution.")

    evts = lire_evenements()

    titre("① CHRONOLOGIE — tous les événements tracés")
    print(f"   source : docs/trace/US-01.2/events.jsonl")
    for e in evts:
        print(f"   {e['_t']:%Y-%m-%d %H:%M}  {e['event']:<32} {e['agent']}")
    duree = (evts[-1]["_t"] - evts[0]["_t"]).total_seconds() / 3600
    print(f"\n   DURÉE TOTALE du cycle : {duree:.1f} h ({duree / 24:.1f} jours calendaires)")

    titre("② LES PLUS GROS INTERVALLES (≥ 12 h)")
    grands = garde(intervalles(evts, 12.0), "aucun intervalle ≥ 12 h — seuil ou trace inattendus")
    for heures, avant, apres in sorted(grands, reverse=True):
        print(f"   {heures:7.1f} h  {avant}  →  {apres}")

    titre("③ TOURS D'AUDIT ET CYCLES DE CORRECTIF")
    compte = Counter(e["event"] for e in evts)
    revues = compte["EVT_CODE_REVIEW_PASSED"] + compte["EVT_CODE_REVIEW_FAILED"]
    secus = compte["EVT_SECURITY_AUDIT_PASSED"] + compte["EVT_SECURITY_AUDIT_FAILED"]
    prets = compte["EVT_CODE_READY"]
    garde(revues, "aucun verdict de revue dans la trace")
    garde(secus, "aucun verdict de sécurité dans la trace")
    print(f"   verdicts de revue      : {revues}")
    print(f"   verdicts de sécurité   : {secus}")
    print(f"   EVT_CODE_READY émis    : {prets}   ⇒ cycles de correctif : {prets - 1}")
    echecs = compte["EVT_CODE_REVIEW_FAILED"] + compte["EVT_SECURITY_AUDIT_FAILED"]
    print(f"   verdicts FAILED        : {echecs}")

    titre("④ VOLUME PRODUIT — lignes AJOUTÉES par famille")
    print(f"   commande : git diff --numstat {BASE}...HEAD")
    volumes = volume_par_famille(git("diff", "--numstat", f"{BASE}...HEAD"))
    for libelle, lignes in sorted(volumes.items(), key=lambda kv: -kv[1]):
        print(f"   {libelle:<28} {lignes:7d}")
    doc = sum(v for k, v in volumes.items() if EST_DOC(k))
    produit = sum(v for k, v in volumes.items() if EST_PRODUIT(k))
    garde(produit, "0 ligne de code ou de test — périmètre inattendu")
    print(f"\n   DOCUMENTATION : {doc}")
    print(f"   CODE + TESTS  : {produit}")
    print(f"   RATIO doc / (code+tests) : {doc / produit:.2f}")
    rapports = volumes.get("DOC    rapports d'audit", 0)
    code = volumes.get("CODE   lib/", 0)
    if code:
        print(f"   RATIO rapports d'audit / lib/ : {rapports / code:.2f}")

    titre("⑤ COMMITS PAR JOUR (branche, hors base)")
    jours = git("log", f"{BASE}..HEAD", "--date=short", "--format=%ad").split()
    garde(jours, f"aucun commit dans {BASE}..HEAD")
    for jour, n in sorted(Counter(jours).items()):
        print(f"   {jour}  {n:3d}  {'█' * n}")
    print(f"\n   TOTAL : {len(jours)} commits sur {len(set(jours))} jours actifs")

    print("\n⛔ CE QUE CES MESURES N'ÉTABLISSENT PAS")
    print("   · Elles ne disent RIEN de la QUALITÉ : un cycle court n'est pas meilleur.")
    print("   · Les durées sont du temps CALENDAIRE, ⛔ pas du temps de travail —")
    print("     elles incluent les nuits, les attentes et les interruptions.")
    print("   · Le nombre d'exécutions de `run_gates` par commit audité n'est PAS")
    print("     mesurable ici : rien dans le dépôt ne les enregistre.")
    return 0


# --------------------------------------------------------------------------
# Selftest — il ne teste pas les CHIFFRES, il teste que LES GARDES MORDENT
# --------------------------------------------------------------------------

def selftest() -> int:
    cas = []

    def attendu_vide(nom, fn):
        try:
            fn()
        except Vacuite:
            cas.append((nom, True, "Vacuité levée"))
        except Exception as exc:  # noqa: BLE001
            cas.append((nom, False, f"mauvaise exception : {type(exc).__name__} {exc}"))
        else:
            cas.append((nom, False, "⛔ AUCUNE exception — la garde ne mord pas"))

    # M1 : un diff vide doit être refusé, ⛔ jamais rendu comme « 0 ligne ».
    attendu_vide("M1 diff vide", lambda: volume_par_famille(""))

    # M2 : un diff dont AUCUNE ligne n'est exploitable (que du binaire) — le
    # motif « matche » au sens du split mais ne classe rien.
    attendu_vide("M2 diff 100% binaire", lambda: volume_par_famille("-\t-\timage.png\n"))

    # M3 : une trace vide.
    vide = RACINE / "reports" / "US-01.2" / ".selftest_trace_vide.jsonl"
    vide.write_text("", encoding="utf-8")
    try:
        attendu_vide("M3 trace vide", lambda: lire_evenements(vide))
    finally:
        vide.unlink(missing_ok=True)

    # M4 : CONTRÔLE NÉGATIF — une entrée VALIDE ne doit PAS lever. Sans lui,
    # une garde qui lèverait TOUJOURS passerait les trois cas ci-dessus.
    try:
        resultat = volume_par_famille("12\t0\tlib/a.dart\n")
        ok = resultat == {"CODE   lib/": 12}
        cas.append(("M4 contrôle négatif (entrée valide)", ok, f"rendu : {resultat}"))
    except Exception as exc:  # noqa: BLE001
        cas.append(("M4 contrôle négatif (entrée valide)", False, f"a levé : {exc}"))

    print("SELFTEST — les gardes d'anti-vacuité mordent-elles ?\n")
    for nom, ok, detail in cas:
        print(f"   {'🟢' if ok else '🔴'} {nom:<38} {detail}")
    reussis = sum(1 for _, ok, _ in cas if ok)
    print(f"\n   {reussis}/{len(cas)} — ⛔ un selftest vert ne dit RIEN de l'exactitude")
    print("   des chiffres : il dit seulement qu'un vide ne peut pas se faire")
    print("   passer pour une mesure.")
    return 0 if reussis == len(cas) else 1


if __name__ == "__main__":
    try:
        sys.exit(selftest() if "--selftest" in sys.argv else mesurer())
    except Vacuite as exc:
        print(f"\n🔴 ERREUR — {exc}", file=sys.stderr)
        sys.exit(1)
