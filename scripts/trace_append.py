#!/usr/bin/env python3
"""
Helper d'écriture d'un événement de trace (docs/trace/US-XXX/events.jsonl).

Usage :
  python scripts/trace_append.py --us US-01.1 --event EVT_CODE_READY \
      --agent developer --model <modèle réel> \
      --rationale "Code + tests poussés" \
      [--files chemin/fichier1 chemin/fichier2] \
      [--report reports/US-01.1/code_review.md] \
      [--command "lint -> 0 errors"] \
      [--session <id>]

L'événement est validé contre scripts/events_catalog.json AVANT écriture
(nom connu, préconditions présentes dans la trace existante).
"""
import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import factory_config

ROOT = factory_config.ROOT
_cfg = factory_config.load()
CATALOG_PATH = ROOT / "scripts" / "events_catalog.json"
TRACE_DIR = ROOT / factory_config.get(_cfg, "governance.trace_dir", "docs/trace")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--us", required=True)
    parser.add_argument("--event", required=True)
    parser.add_argument("--agent", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--rationale", required=True)
    parser.add_argument("--files", nargs="*", default=[])
    parser.add_argument("--report")
    parser.add_argument("--command", action="append", default=[], dest="commands")
    parser.add_argument("--session", default="")
    args = parser.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass

    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    events, aliases = catalog["events"], catalog.get("deprecated_aliases", {})

    if args.event in aliases:
        sys.exit(f"[ERREUR] '{args.event}' est déprécié — utiliser '{aliases[args.event]}'.")
    if args.event not in events:
        sys.exit(f"[ERREUR] événement inconnu '{args.event}' (voir scripts/events_catalog.json).")

    trace_file = TRACE_DIR / args.us / "events.jsonl"
    seen: list[str] = []
    if trace_file.exists():
        for line in trace_file.read_text(encoding="utf-8").splitlines():
            try:
                seen.append(json.loads(line).get("event", ""))
            except json.JSONDecodeError:
                pass

    preconditions = events[args.event].get("preconditions", [])
    missing = [p for p in preconditions if p not in seen]
    if missing and "EVT_WAIVER_GRANTED" not in seen:
        sys.exit(
            f"[ERREUR] '{args.event}' exige {missing} au préalable dans la trace de {args.us}.\n"
            "Émettre d'abord les événements manquants (ou une dérogation humaine EVT_WAIVER_GRANTED)."
        )

    if args.report and not (ROOT / args.report).exists():
        sys.exit(f"[ERREUR] evidence.report introuvable : {args.report}")

    event = {
        "ts": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "event": args.event,
        "us": args.us,
        "agent": args.agent,
        "model": args.model,
        "session": args.session,
        "files": args.files,
        "evidence": {"report": args.report, "commands": args.commands},
        "rationale": args.rationale,
    }

    trace_file.parent.mkdir(parents=True, exist_ok=True)
    with trace_file.open("a", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")

    print(f"[OK] {args.event} ajouté à {trace_file.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
