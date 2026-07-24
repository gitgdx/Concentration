#!/bin/bash
# Hook PreToolUse(Edit|Write) — les fichiers d'ENFORCEMENT ne sont modifiables que par
# action humaine explicite (jamais par l'agent en autonomie).
# Périmètre : UNIQUEMENT les fichiers de CE dépôt (un autre dépôt a son propre enforcement).
# exit 2 = blocage + message renvoyé à Claude.

input=$(cat)
# Extrait le chemin et le rend RELATIF à la racine du dépôt ; vide si hors dépôt.
path=$(printf '%s' "$input" | python -c "
import sys, json, os
p = json.load(sys.stdin).get('tool_input', {}).get('file_path', '')
if not p:
    print(); raise SystemExit
root = os.environ.get('CLAUDE_PROJECT_DIR') or os.getcwd()
try:
    rel = os.path.relpath(os.path.abspath(p), os.path.abspath(root))
except ValueError:
    print(); raise SystemExit
print('' if rel.startswith('..') else rel.replace(os.sep, '/'))
" 2>/dev/null)
[ -z "$path" ] && exit 0

case "$path" in
  *.env.example) exit 0 ;;
  *.env|*.env.*)
    echo "BLOQUÉ : les fichiers .env (secrets) ne sont jamais édités par l'agent." >&2
    exit 2 ;;
  scripts/githooks/*|.claude/settings.json|.claude/hooks/*|.gitleaks.toml|scripts/install_hooks.sh|factory.config.json|scripts/factory_env.sh|scripts/factory_sync.py|scripts/run_gates.py)
    echo "BLOQUÉ : '$path' est un fichier d'enforcement de la factory — modification réservée à une action humaine explicite (désactiver temporairement ce hook dans .claude/settings.json si la modification est réellement voulue)." >&2
    exit 2 ;;
esac

exit 0
