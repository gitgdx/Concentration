#!/bin/bash
# Hook PostToolUse(Edit|Write) — feedback immédiat si le SCB édité viole ses règles
# croisées (au lieu d'attendre le pre-commit ou la CI).

input=$(cat)
path=$(printf '%s' "$input" | python -c "import sys,json;print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

case "$path" in
  *STORY_CERTIFICATION_BOARD.md)
    out=$(python scripts/check_scb_compliance.py 2>&1)
    if [ $? -ne 0 ]; then
      echo "SCB NON CONFORME après édition — corriger immédiatement :" >&2
      echo "$out" >&2
      exit 2
    fi
    ;;
esac

exit 0
