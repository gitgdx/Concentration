#!/usr/bin/env python3
"""
Synchroniseur de la config factory — élimine les divergences entre factory.config.json
(source unique) et ses projections :

  --write                   régénère scripts/factory_env.sh (sourcé par les hooks) et le
                            bloc status-checks de docs/GIT_PROTECTION.md (entre marqueurs).
  --check                   exit 1 si une projection a dérivé de la config : factory_env.sh,
                            bloc GIT_PROTECTION.md, status checks absents des workflows CI,
                            seuils de couverture incohérents avec les fichiers de l'adapter.
                            Exécuté par le job CI `governance` — la synchro est un gate bloquant.
  --emit-branch-protection  imprime le JSON de protection de branche pour `gh api`
                            (consommé par scripts/apply_branch_protection.sh).
  --print-main-branch       imprime git.main_branch (usage shell).
"""
import argparse
import json
import re
import sys
from pathlib import Path

import factory_config

ROOT = factory_config.ROOT
ENV_PATH = ROOT / "scripts" / "factory_env.sh"
GIT_PROTECTION_PATH = ROOT / "docs" / "GIT_PROTECTION.md"
MARK_BEGIN = "<!-- FACTORY_SYNC:BEGIN — généré par scripts/factory_sync.py, ne pas éditer -->"
MARK_END = "<!-- FACTORY_SYNC:END -->"


def render_env(cfg: dict) -> str:
    exts = factory_config.get(cfg, "governance.code_extensions", ["py", "ts", "tsx", "js", "jsx"])
    types = factory_config.get(cfg, "git.commit_types", ["feat", "fix", "refactor", "test", "docs", "chore"])
    return (
        "# GÉNÉRÉ par scripts/factory_sync.py depuis factory.config.json — NE PAS ÉDITER À LA MAIN.\n"
        "# Les hooks (git + Claude Code) sourcent ce fichier avec des valeurs par défaut de secours :\n"
        "# ils restent fonctionnels si ce fichier est absent.\n"
        f'FACTORY_MAIN_BRANCH="{factory_config.get(cfg, "git.main_branch", "main")}"\n'
        f'FACTORY_BRANCH_HINT="{factory_config.get(cfg, "git.branch_hint", "feat/US-XX.X-description")}"\n'
        f"FACTORY_CODE_EXT_REGEX='\\.({'|'.join(exts)})$'\n"
        f'FACTORY_COMMIT_TYPES="{"|".join(types)}"\n'
    )


def render_protection_block(cfg: dict) -> str:
    lines = [MARK_BEGIN, "", "| Status check requis | Workflow |", "|---|---|"]
    for check in cfg.get("status_checks", []):
        lines.append(f"| `{check['name']}` | `{check['workflow']}` |")
    lines += ["", MARK_END]
    return "\n".join(lines)


def emit_branch_protection(cfg: dict) -> str:
    bp = cfg.get("branch_protection", {})
    payload = {
        "required_status_checks": {
            "strict": True,
            "contexts": [c["name"] for c in cfg.get("status_checks", [])],
        },
        "required_pull_request_reviews": {
            "required_approving_review_count": bp.get("required_approving_review_count", 1),
        },
        "enforce_admins": bp.get("enforce_admins", True),
        "restrictions": None,
        "allow_force_pushes": bp.get("allow_force_pushes", False),
        "allow_deletions": bp.get("allow_deletions", False),
        "required_linear_history": bp.get("required_linear_history", False),
        "required_conversation_resolution": bp.get("required_conversation_resolution", True),
    }
    return json.dumps(payload, indent=2, ensure_ascii=False)


def replace_block(text: str, block: str) -> str | None:
    """Remplace le contenu entre marqueurs ; None si les marqueurs sont absents."""
    pattern = re.compile(re.escape(MARK_BEGIN) + r".*?" + re.escape(MARK_END), re.DOTALL)
    if not pattern.search(text):
        return None
    return pattern.sub(block, text)


def do_write(cfg: dict) -> int:
    ENV_PATH.write_text(render_env(cfg), encoding="utf-8", newline="\n")
    print(f"[OK] {ENV_PATH.relative_to(ROOT)} régénéré.")
    if GIT_PROTECTION_PATH.exists():
        text = GIT_PROTECTION_PATH.read_text(encoding="utf-8")
        updated = replace_block(text, render_protection_block(cfg))
        if updated is None:
            print(f"[AVERTISSEMENT] marqueurs FACTORY_SYNC absents de {GIT_PROTECTION_PATH.name} — bloc non écrit.")
        else:
            GIT_PROTECTION_PATH.write_text(updated, encoding="utf-8", newline="\n")
            print(f"[OK] bloc status-checks de {GIT_PROTECTION_PATH.relative_to(ROOT)} régénéré.")
    return 0


def check_workflows(cfg: dict) -> list[str]:
    """Chaque status check déclaré doit correspondre à un job du workflow cité — soit via un
    `name:` explicite, soit (GitHub Actions par défaut) via l'ID du job lui-même quand aucun
    `name:` n'est présent (ex. `check-branch-name:` sans name: affiche "check-branch-name")."""
    errors: list[str] = []
    for check in cfg.get("status_checks", []):
        wf_path = ROOT / ".github" / "workflows" / check["workflow"]
        if not wf_path.exists():
            errors.append(f"status check '{check['name']}' : workflow {check['workflow']} introuvable")
            continue
        content = wf_path.read_text(encoding="utf-8")
        name_pattern = re.compile(r"^\s*name:\s*[\"']?" + re.escape(check["name"]) + r"[\"']?\s*$", re.MULTILINE)
        job_id_pattern = re.compile(r"^\s{2}" + re.escape(check["name"]) + r":\s*$", re.MULTILINE)
        if not name_pattern.search(content) and not job_id_pattern.search(content):
            errors.append(
                f"status check '{check['name']}' absent des `name:` de jobs (ni comme ID de job) de "
                f"{check['workflow']} (la protection de branche attendrait un check qui n'existe pas)"
            )
    return errors


def check_thresholds(cfg: dict) -> list[str]:
    """Les seuils déclarés en config doivent correspondre aux fichiers de l'adapter (si présents)."""
    errors: list[str] = []
    components = factory_config.get(cfg, "adapter.components", {}) or {}

    backend = components.get("backend", {})
    cov_min = backend.get("coverage_min")
    if cov_min is not None:
        pytest_ini = ROOT / backend.get("path", "backend") / "pytest.ini"
        if pytest_ini.exists():
            content = pytest_ini.read_text(encoding="utf-8")
            m = re.search(r"--cov-fail-under=(\d+)", content)
            if not m:
                errors.append(f"{pytest_ini.relative_to(ROOT)} : --cov-fail-under absent (config exige {cov_min})")
            elif int(m.group(1)) < int(cov_min):
                errors.append(
                    f"{pytest_ini.relative_to(ROOT)} : --cov-fail-under={m.group(1)} < coverage_min config ({cov_min})"
                )

    frontend = components.get("frontend", {})
    ratchet = frontend.get("coverage_ratchet") or {}
    if ratchet:
        vitest_cfg = ROOT / frontend.get("path", "frontend") / "vitest.config.ts"
        if vitest_cfg.exists():
            content = vitest_cfg.read_text(encoding="utf-8")
            for key, expected in ratchet.items():
                m = re.search(rf"\b{key}\s*:\s*(\d+)", content)
                if not m:
                    errors.append(f"{vitest_cfg.relative_to(ROOT)} : seuil '{key}' introuvable (config exige {expected})")
                elif int(m.group(1)) < int(expected):
                    errors.append(
                        f"{vitest_cfg.relative_to(ROOT)} : {key}={m.group(1)} < ratchet config ({expected})"
                    )
    return errors


def do_check(cfg: dict) -> int:
    errors: list[str] = []

    if not ENV_PATH.exists():
        errors.append(f"{ENV_PATH.relative_to(ROOT)} absent — lancer `python scripts/factory_sync.py --write`")
    elif ENV_PATH.read_text(encoding="utf-8") != render_env(cfg):
        errors.append(f"{ENV_PATH.relative_to(ROOT)} a dérivé de factory.config.json — relancer --write")

    if GIT_PROTECTION_PATH.exists():
        text = GIT_PROTECTION_PATH.read_text(encoding="utf-8")
        expected = replace_block(text, render_protection_block(cfg))
        if expected is not None and expected != text:
            errors.append(f"{GIT_PROTECTION_PATH.relative_to(ROOT)} : bloc status-checks périmé — relancer --write")

    errors += check_workflows(cfg)
    errors += check_thresholds(cfg)

    if errors:
        print("SYNCHRO FACTORY NON CONFORME :")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("Synchro factory conforme (env, protection, workflows, seuils).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true")
    group.add_argument("--check", action="store_true")
    group.add_argument("--emit-branch-protection", action="store_true")
    group.add_argument("--print-main-branch", action="store_true")
    args = parser.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass

    cfg = factory_config.load(required=True)

    if args.write:
        return do_write(cfg)
    if args.check:
        return do_check(cfg)
    if args.emit_branch_protection:
        print(emit_branch_protection(cfg))
        return 0
    if args.print_main_branch:
        print(factory_config.get(cfg, "git.main_branch", "main"))
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
