#!/bin/bash
# Hook SessionStart — injecte automatiquement le contexte de gouvernance
# (remplace la checklist déclarative "lire les 5 dernières lignes du LOG").

echo "=== CONTEXTE FACTORY (injecté par session_start.sh) ==="

if [ ! -f factory.config.json ]; then
  echo "⚠️ PROJET NON INITIALISÉ — lancer : python init_factory.py --name <projet>"
fi

hooks_path=$(git config core.hooksPath 2>/dev/null)
if [ "$hooks_path" != "scripts/githooks" ]; then
  echo "⚠️ HOOKS GIT NON INSTALLÉS sur ce clone — exécuter : sh scripts/install_hooks.sh"
fi

if [ -f PROJECT_LOG.md ]; then
  echo ""
  echo "--- 5 dernières entrées du PROJECT_LOG ---"
  grep -E '^\| *[0-9]{4}-' PROJECT_LOG.md | tail -5
fi

if [ -f STORY_CERTIFICATION_BOARD.md ]; then
  echo ""
  echo "--- Conformité SCB ---"
  python scripts/check_scb_compliance.py 2>&1 | tail -3
fi

echo ""
echo "Rappels : Constitution docs/governance/CONSTITUTION.md · tracks docs/governance/TRACKS.md · normes stack docs/governance/STACK_PROFILE.md · rituels /us-new /audit-us /certify"
exit 0
