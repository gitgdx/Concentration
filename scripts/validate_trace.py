#!/usr/bin/env python3
"""
Validateur de traçabilité machine-parsable de la factory.

Vérifie :
  1. Le format des traces JSONL (docs/trace/US-XXX/events.jsonl) : schéma,
     événements connus (scripts/events_catalog.json), chronologie, préconditions
     de la machine à états, existence des rapports référencés en evidence.
  2. La cohérence croisée SCB ↔ trace : une US qui possède un répertoire de trace
     doit avoir un événement pour chaque visa d'audit affiché dans le SCB.
     (Un projet issu du starter kit n'a pas de legacy : toute US a une trace.
     Si un historique pré-factory existe, dater la bascule dans
     factory.config.json → governance.grandfathering_date.)
  3. Le format du tableau PROJECT_LOG.md (6 colonnes datées).

Modes :
  --staged   : valide les fichiers de trace stagés + PROJECT_LOG (pre-commit)
  --us US-X  : valide la chaîne complète d'une US (utilisé par /certify)
  --all      : valide tout (CI)

Sortie : exit 0 si conforme, exit 1 + liste des erreurs sinon.
"""
import argparse
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import factory_config

ROOT = factory_config.ROOT
_cfg = factory_config.load()
CATALOG_PATH = ROOT / "scripts" / "events_catalog.json"
TRACE_DIR = ROOT / factory_config.get(_cfg, "governance.trace_dir", "docs/trace")
SCB_PATH = ROOT / factory_config.get(_cfg, "governance.scb_path", "STORY_CERTIFICATION_BOARD.md")
LOG_PATH = ROOT / factory_config.get(_cfg, "governance.log_path", "PROJECT_LOG.md")

REQUIRED_FIELDS = ("ts", "event", "us", "agent", "rationale")
# La cellule Agent accepte plusieurs agents : "@A", "@A & @B", "@A + @B"
LOG_ROW_RE = re.compile(
    r"^\| *\d{4}-\d{2}-\d{2} *\| *@[\w-]+( *[&+] *@[\w-]+)* *\|[^|]+\|[^|]+\|[^|]+\|[^|]*\|?\s*$"
)
# Correspondance colonne SCB → événement de trace exigé
SCB_EVENT_REQUIREMENTS = [
    ("audit_rev", "✅", "EVT_CODE_REVIEW_PASSED"),
    ("audit_sec", "✅", "EVT_SECURITY_AUDIT_PASSED"),
    ("qa_status", "🧪 PASS", "EVT_QA_PASSED"),
    ("certified", "🚀 OUI", "EVT_CERTIFIED_PROD"),
]


def load_catalog() -> tuple[dict, dict]:
    data = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    return data["events"], data.get("deprecated_aliases", {})


def parse_iso(ts: str) -> datetime | None:
    try:
        return datetime.fromisoformat(ts)
    except (ValueError, TypeError):
        return None


def validate_trace_file(path: Path, events_catalog: dict, aliases: dict) -> list[str]:
    errors: list[str] = []
    rel = path.relative_to(ROOT)
    us_id = path.parent.name
    seen_events: list[str] = []
    last_ts: datetime | None = None

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return [f"{rel}: illisible ({exc})"]

    for i, line in enumerate(lines, 1):
        if not line.strip():
            continue
        loc = f"{rel}:{i}"
        try:
            evt = json.loads(line)
        except json.JSONDecodeError as exc:
            errors.append(f"{loc}: JSON invalide ({exc})")
            continue

        for field in REQUIRED_FIELDS:
            if not evt.get(field):
                errors.append(f"{loc}: champ obligatoire manquant ou vide : '{field}'")

        name = evt.get("event", "")
        if name in aliases:
            errors.append(f"{loc}: événement déprécié '{name}' — utiliser '{aliases[name]}'")
        elif name and name not in events_catalog:
            errors.append(f"{loc}: événement inconnu '{name}' (voir scripts/events_catalog.json)")

        if evt.get("us") and evt["us"] != us_id:
            errors.append(f"{loc}: champ us='{evt['us']}' incohérent avec le répertoire {us_id}")

        ts = parse_iso(evt.get("ts", ""))
        if ts is None:
            errors.append(f"{loc}: ts non ISO-8601 : {evt.get('ts')!r}")
        elif last_ts and ts < last_ts:
            errors.append(f"{loc}: chronologie violée ({ts.isoformat()} < {last_ts.isoformat()})")
        else:
            last_ts = ts

        # Machine à états : préconditions (une dérogation humaine tracée les couvre)
        spec = events_catalog.get(name, {})
        if spec.get("preconditions") and "EVT_WAIVER_GRANTED" not in seen_events:
            missing = [p for p in spec["preconditions"] if p not in seen_events]
            if missing:
                errors.append(
                    f"{loc}: '{name}' émis sans précondition(s) {missing} dans la trace de {us_id}"
                )

        # Les preuves référencées doivent exister
        report = (evt.get("evidence") or {}).get("report")
        if report and not (ROOT / report).exists():
            errors.append(f"{loc}: evidence.report introuvable : {report}")

        if name:
            seen_events.append(name)

    return errors


def parse_scb() -> dict[str, dict]:
    """Réutilise la logique de parsing du SCB (colonnes indexées comme check_scb_compliance)."""
    stories: dict[str, dict] = {}
    in_table = False
    for line in SCB_PATH.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            in_table = False
            continue
        if "US ID" in stripped and "Phase Workflow" in stripped:
            in_table = True
            continue
        if not in_table or re.match(r"^\|[\s:|-]+\|$", stripped):
            continue
        cells = [c.strip() for c in stripped.split("|")]
        if len(cells) < 13 or not cells[1].startswith("US-"):
            continue
        stories[cells[1]] = {
            "audit_rev": cells[8],
            "audit_sec": cells[9],
            "qa_status": cells[10],
            "certified": cells[12],
        }
    return stories


def validate_scb_cross(us_filter: str | None) -> list[str]:
    """Une US disposant d'une trace doit tracer chaque visa affiché dans le SCB."""
    errors: list[str] = []
    if not TRACE_DIR.exists():
        return errors
    stories = parse_scb()
    for us_dir in sorted(TRACE_DIR.iterdir()):
        if not us_dir.is_dir():
            continue
        us_id = us_dir.name
        if us_filter and us_id != us_filter:
            continue
        trace_file = us_dir / "events.jsonl"
        traced = set()
        if trace_file.exists():
            for line in trace_file.read_text(encoding="utf-8").splitlines():
                try:
                    traced.add(json.loads(line).get("event"))
                except json.JSONDecodeError:
                    pass
        scb_row = stories.get(us_id)
        if scb_row is None:
            errors.append(f"docs/trace/{us_id}: aucune ligne correspondante dans le SCB")
            continue
        for column, marker, required_event in SCB_EVENT_REQUIREMENTS:
            if marker in scb_row[column] and required_event not in traced:
                errors.append(
                    f"SCB[{us_id}].{column} affiche '{marker}' mais {required_event} "
                    f"absent de docs/trace/{us_id}/events.jsonl"
                )
    return errors


def validate_project_log() -> list[str]:
    errors: list[str] = []
    if not LOG_PATH.exists():
        return ["PROJECT_LOG.md introuvable"]
    in_table = False
    for i, line in enumerate(LOG_PATH.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("| Date") or stripped.startswith("| :"):
            in_table = True
            continue
        if not stripped.startswith("|"):
            in_table = False
            continue
        if in_table and re.match(r"^\| *\d{4}", stripped) and not LOG_ROW_RE.match(stripped):
            errors.append(
                f"PROJECT_LOG.md:{i}: ligne de tableau non conforme au format "
                "'| YYYY-MM-DD | @Agent | Modèle | Action | Statut | Fichiers |'"
            )
    return errors


def staged_trace_files() -> list[Path]:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True, text=True, cwd=ROOT, check=False,
    ).stdout.splitlines()
    return [ROOT / p for p in out if p.startswith("docs/trace/") and p.endswith(".jsonl")]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--staged", action="store_true")
    group.add_argument("--us")
    group.add_argument("--all", action="store_true")
    args = parser.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass

    events_catalog, aliases = load_catalog()
    errors: list[str] = []

    if args.staged:
        for path in staged_trace_files():
            if path.exists():
                errors += validate_trace_file(path, events_catalog, aliases)
        errors += validate_project_log()
    else:
        if TRACE_DIR.exists():
            for trace_file in sorted(TRACE_DIR.glob("US-*/events.jsonl")):
                if args.us and trace_file.parent.name != args.us:
                    continue
                errors += validate_trace_file(trace_file, events_catalog, aliases)
        errors += validate_scb_cross(args.us)
        errors += validate_project_log()
        if args.us and not (TRACE_DIR / args.us / "events.jsonl").exists():
            errors.append(f"docs/trace/{args.us}/events.jsonl absent — trace obligatoire pour certifier")

    if errors:
        print("TRAÇABILITÉ NON CONFORME :")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("Traçabilité conforme.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
