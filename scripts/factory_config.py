#!/usr/bin/env python3
"""
Loader partagé de factory.config.json — la source unique de configuration de la factory
(nom du projet, branches, chemins de gouvernance, status checks, gates de l'adapter).

Les scripts d'enforcement l'utilisent avec fallback sur les valeurs historiques :
ils restent copiables seuls dans un projet sans config.
"""
import json
from pathlib import Path

ROOT = Path(__file__).parent.parent
CONFIG_PATH = ROOT / "factory.config.json"


def load(required: bool = False) -> dict | None:
    """Charge factory.config.json ; None si absent (sauf required=True)."""
    if not CONFIG_PATH.exists():
        if required:
            raise SystemExit(
                "[ERREUR] factory.config.json introuvable — le projet n'est pas initialisé "
                "(lancer : python init_factory.py --name <projet>)."
            )
        return None
    try:
        return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"[ERREUR] factory.config.json invalide : {exc}")


def get(cfg: dict | None, dotted_path: str, default=None):
    """Accès par chemin pointé : get(cfg, 'governance.scb_path', 'STORY_CERTIFICATION_BOARD.md')."""
    cur = cfg
    for key in dotted_path.split("."):
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur
