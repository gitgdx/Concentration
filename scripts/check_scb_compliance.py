#!/usr/bin/env python3
"""
SCB Compliance Checker
Vérifie que le STORY_CERTIFICATION_BOARD.md est cohérent avec les phases workflow.
Exécuté par : le hook git pre-commit, le hook Claude Code PostToolUse (édition du SCB),
le job CI `governance` (ci.yml) et le rituel /certify.
"""
import sys
import re
from pathlib import Path

import factory_config

_cfg = factory_config.load()
SCB_PATH = factory_config.ROOT / factory_config.get(
    _cfg, "governance.scb_path", "STORY_CERTIFICATION_BOARD.md"
)

# Phases qui bloquent le déploiement si le QA Status est encore en attente (⏳)
BLOCKING_PHASES = [
    "quality_assurance",
    "prepare_deployment",
    "deployment_staging",
    "deployment_prod",
    "epic_closure",
]


def is_satisfied(cell: str) -> bool:
    """Une exigence est satisfaite si validée (✅) ou explicitement non applicable (N/A)."""
    return "✅" in cell or cell.strip().upper().startswith("N/A")


def parse_scb(file_path: Path) -> list[dict]:
    """Parse le tableau Markdown du SCB et retourne une liste de stories."""
    if not file_path.exists():
        print(f"ERREUR: STORY_CERTIFICATION_BOARD.md introuvable à {file_path}")
        sys.exit(1)

    stories = []
    in_table = False

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            in_table = False
            continue

        # Détection de l'en-tête du tableau principal
        if "US ID" in stripped and "Phase Workflow" in stripped:
            in_table = True
            continue

        if not in_table:
            continue

        # Ignorer les lignes de séparation (|:---|:---|...)
        if re.match(r"^\|[\s:|-]+\|$", stripped):
            continue

        cells = [c.strip() for c in stripped.split("|")]
        # Format : | vide | US ID | Titre | Phase | PO | Data | UX | Code | AuditRev | AuditSec | QA | Deploy | Certified | vide |
        if len(cells) < 13:
            continue

        us_id = cells[1]

        # Filtrer les lignes de titre d'EPIC (en gras) et les lignes vides
        if not us_id.startswith("US-"):
            continue

        stories.append({
            "id": us_id,
            "title": cells[2],
            "phase": cells[3].strip(),
            "po_visa": cells[4],
            "design_data": cells[5],
            "design_ux": cells[6],
            "code_dev": cells[7],
            "audit_rev": cells[8],
            "audit_sec": cells[9],
            "qa_status": cells[10],
            "deployment": cells[11],
            "certified": cells[12],
        })

    return stories


def check_compliance() -> list[str]:
    """
    Vérifie la conformité du SCB selon les règles du workflow.

    Règles vérifiées :
    1. Toute US en phase bloquante (>= quality_assurance) ne doit pas avoir QA Status = ⏳
    2. Toute US en phase epic_closure doit avoir Certifié Prod != ⏳
    3. Contraintes croisées : cohérence entre les colonnes
    """
    stories = parse_scb(SCB_PATH)

    if not stories:
        print("AVERTISSEMENT: Aucune US parsée depuis STORY_CERTIFICATION_BOARD.md!")
        return []

    violations = []

    for story in stories:
        us_id = story["id"]
        phase = story["phase"]
        title = story["title"]
        label = f"[{us_id}] '{title}' (phase: {phase})"

        # Règle 1 : QA Status ne doit pas être ⏳ pour les phases bloquantes
        if phase in BLOCKING_PHASES:
            qa = story["qa_status"]
            if qa == "⏳" or qa.strip() == "⏳":
                violations.append(
                    f"{label} — QA Status est ⏳ alors que la phase est bloquante ({phase})"
                )

        # Règle 2 : epic_closure exige Certifié Prod renseigné (pas ⏳)
        if phase == "epic_closure":
            certified = story["certified"]
            if certified == "⏳" or certified.strip() == "⏳":
                violations.append(
                    f"{label} — Certifié Prod est ⏳ alors que la phase est epic_closure"
                )

        # Règle 3 : Contraintes croisées
        # Code approuvé => designs approuvés (ou explicitement N/A)
        if "✅" in story["code_dev"]:
            if not is_satisfied(story["design_data"]):
                violations.append(
                    f"{label} — Code (Dev) validé mais Design Data non approuvé"
                )
            if not is_satisfied(story["design_ux"]):
                violations.append(
                    f"{label} — Code (Dev) validé mais Design UX non approuvé"
                )

        # QA PASS => audits approuvés (ou explicitement N/A)
        if "🧪 PASS" in story["qa_status"]:
            if not is_satisfied(story["audit_rev"]):
                violations.append(
                    f"{label} — QA PASS mais Audit Rev non approuvé"
                )
            if not is_satisfied(story["audit_sec"]):
                violations.append(
                    f"{label} — QA PASS mais Audit Sec non approuvé"
                )

        # Déployé => QA PASS
        if "🚀 DEPLOYED" in story["deployment"]:
            if "🧪 PASS" not in story["qa_status"]:
                violations.append(
                    f"{label} — Déploiement effectué mais QA Status n'est pas PASS"
                )

        # Certifié Prod => déployé + QA PASS
        if "🚀 OUI" in story["certified"]:
            if "🧪 PASS" not in story["qa_status"]:
                violations.append(
                    f"{label} — Certifié Prod OUI mais QA Status n'est pas PASS"
                )
            if "🚀 DEPLOYED" not in story["deployment"]:
                violations.append(
                    f"{label} — Certifié Prod OUI mais Déploiement n'est pas DEPLOYED"
                )

        # Règles par phase
        if phase == "parallel_audit":
            if "✅" not in story["code_dev"]:
                violations.append(
                    f"{label} — Phase parallel_audit mais Code (Dev) non validé"
                )
        elif phase == "quality_assurance":
            if "✅" not in story["audit_rev"] and "✅" not in story["audit_sec"]:
                violations.append(
                    f"{label} — Phase quality_assurance mais aucun audit approuvé (Audit Rev + Audit Sec absents)"
                )
        elif phase == "prepare_deployment":
            if "🧪 PASS" not in story["qa_status"]:
                violations.append(
                    f"{label} — Phase prepare_deployment mais QA Status n'est pas PASS"
                )
        elif phase == "deployment_prod":
            if "🚀 DEPLOYED" not in story["deployment"]:
                violations.append(
                    f"{label} — Phase deployment_prod mais Déploiement non effectué"
                )

    return violations


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass  # Environnements sans reconfigure (Python < 3.7)

    print(f"Lecture du SCB : {SCB_PATH}")
    violations = check_compliance()

    if violations:
        print("SCB NON CONFORME — Violations détectées :")
        for v in violations:
            print(f"  - {v}")
        sys.exit(1)
    else:
        print("SCB conforme — Aucune violation détectée.")
        sys.exit(0)
