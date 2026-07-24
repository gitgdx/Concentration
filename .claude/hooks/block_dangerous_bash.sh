#!/bin/bash
# Hook PreToolUse(Bash) — bloque les commandes qui contournent l'enforcement de la factory.
# exit 2 = blocage + message renvoyé à Claude pour correction.
# Constitution : docs/governance/CONSTITUTION.md (Art. 1, 2, 6).

# Paramètres générés depuis factory.config.json (défauts de secours si absent)
[ -f scripts/factory_env.sh ] && . ./scripts/factory_env.sh
: "${FACTORY_MAIN_BRANCH:=main}"
: "${FACTORY_BRANCH_HINT:=feat/US-XX.X-description}"

input=$(cat)
cmd=$(printf '%s' "$input" | python -c "import sys,json;print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
[ -z "$cmd" ] && exit 0

block() {
  echo "BLOQUÉ par la factory : $1" >&2
  exit 2
}

case "$cmd" in
  *--no-verify*)
    block "l'option --no-verify est interdite (Constitution Art. 1). Corriger la cause du refus du hook au lieu de le contourner." ;;
esac

echo "$cmd" | grep -qE "git +push +[^ ]+ +${FACTORY_MAIN_BRANCH}\b" && \
  block "push direct vers ${FACTORY_MAIN_BRANCH} interdit — passer par une Pull Request."

echo "$cmd" | grep -qE 'push +(-f|--force)' && \
  block "force-push interdit."

echo "$cmd" | grep -qE 'filter-branch|filter-repo' && \
  block "la réécriture d'historique est une décision humaine — jamais prise par l'agent en autonomie."

# Ne s'applique qu'à une VRAIE invocation "git config ... core.hooksPath" — pas à une commande
# qui mentionne juste ce mot dans un message de commit ou un commentaire.
# Une simple LECTURE ("git config core.hooksPath" / "--get core.hooksPath") est autorisée —
# seule une réécriture vers une valeur différente de scripts/githooks (ou un --unset) est bloquée.
if echo "$cmd" | grep -qE 'git +config +[^|;&]*core\.hooksPath'; then
  if echo "$cmd" | grep -qE 'git +config +(--get +)?core\.hooksPath *($|[;&|])'; then
    :  # lecture seule — autorisé
  elif echo "$cmd" | grep -qE -- '--unset'; then
    block "la dé-configuration de core.hooksPath est interdite (désactiverait les hooks de traçabilité)."
  elif ! echo "$cmd" | grep -q 'scripts/githooks'; then
    block "la dé-configuration de core.hooksPath est interdite (désactiverait les hooks de traçabilité)."
  fi
fi

# Écriture vers un fichier .env (redirection ou copie) — les secrets ne se manipulent qu'à la main
echo "$cmd" | grep -qE '(>|>>|tee +(-a +)?)[^|]*\.env($|[^.a-zA-Z])' && \
  block "écriture dans un fichier .env interdite à l'agent — les secrets sont gérés par l'humain."

# git commit exécuté depuis la branche principale (les hooks git le bloquent aussi ; double barrière)
if echo "$cmd" | grep -qE '(^|[;&| ])git +commit\b'; then
  branch=$(git branch --show-current 2>/dev/null)
  [ "$branch" = "$FACTORY_MAIN_BRANCH" ] && block "commit sur ${FACTORY_MAIN_BRANCH} interdit — créer une branche ${FACTORY_BRANCH_HINT}."
fi

exit 0
