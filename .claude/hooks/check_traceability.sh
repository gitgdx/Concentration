#!/bin/bash
# Stop hook — vérifie que PROJECT_LOG.md est mis à jour quand du code change.
# Exit 2 : bloque le stop et renvoie le message à Claude pour correction.

# Paramètres générés depuis factory.config.json (défauts de secours si absent)
[ -f scripts/factory_env.sh ] && . ./scripts/factory_env.sh
: "${FACTORY_CODE_EXT_REGEX:=\.(py|ts|tsx|js|jsx)$}"

# Pas de PROJECT_LOG.md du tout (ex. le dépôt du starter kit lui-même, avant toute
# initialisation d'un projet) : rien à faire respecter, on ne bloque pas indéfiniment
# sur une règle qui ne s'applique pas à ce dépôt.
[ -f PROJECT_LOG.md ] || exit 0

last_commit=$(git diff-tree --no-commit-id -r --name-only HEAD 2>/dev/null)
staged=$(git diff --cached --name-only 2>/dev/null)
modified=$(git diff --name-only 2>/dev/null)

filter_code() {
  grep -E "$FACTORY_CODE_EXT_REGEX" | grep -v -E '(\.test\.|\.spec\.|__tests__|/tests/|node_modules)'
}

code_in_commit=$(echo "$last_commit" | filter_code)
log_in_commit=$(echo "$last_commit" | grep -F 'PROJECT_LOG.md')

code_in_working=$(printf '%s\n%s' "$staged" "$modified" | filter_code | sort -u | grep -v '^$')
log_in_working=$(printf '%s\n%s' "$staged" "$modified" | grep -F 'PROJECT_LOG.md')

msg=""

if [ -n "$code_in_commit" ] && [ -z "$log_in_commit" ]; then
  msg="⚠️  DERNIER COMMIT sans PROJECT_LOG.md — fichiers de code committés :\n$(echo "$code_in_commit" | sed 's/^/  - /')"
fi

if [ -n "$code_in_working" ] && [ -z "$log_in_working" ]; then
  msg="${msg}\n⚠️  FICHIERS MODIFIÉS (non commités) sans PROJECT_LOG.md :\n$(echo "$code_in_working" | sed 's/^/  - /')"
fi

if [ -n "$msg" ]; then
  printf '\n=== TRAÇABILITÉ MANQUANTE ===\n'
  printf '%b\n' "$msg"
  printf '\nACTION REQUISE avant de terminer :\n'
  printf '  1. Ajouter une ligne dans PROJECT_LOG.md\n'
  printf '  2. Mettre à jour STORY_CERTIFICATION_BOARD.md si une US est impactée\n'
  printf '  3. Inclure PROJECT_LOG.md dans le prochain commit\n\n'
  exit 2
fi

exit 0
