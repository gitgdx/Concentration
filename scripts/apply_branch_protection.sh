#!/bin/sh
# Applique RÉELLEMENT les protections de branche — le JSON est GÉNÉRÉ depuis
# factory.config.json (source unique des status checks) par factory_sync.py.
# Pré-requis : gh CLI installé et authentifié avec droits admin sur le dépôt.
#
# ⚠️ NON APPLICABLE au 2026-07-26 sur gitgdx/Concentration : la protection de branche est
#    indisponible sur ce plan (dépôt privé, compte User) — GET/PUT .../protection ET .../rulesets
#    renvoient 403 « Upgrade to GitHub Pro or make this repository public to enable this feature. »
#    Ce script est PRÊT et CONDITIONNÉ AU DÉBLOCAGE (dépôt public OU GitHub Pro) : il n'est PAS
#    « à exécuter ». Voir docs/adr/ADR-006-protection-branche-principale.md et docs/GIT_PROTECTION.md.
# Usage : sh scripts/apply_branch_protection.sh [owner/repo]
set -e

cd "$(dirname "$0")/.."

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
MAIN="$(python scripts/factory_sync.py --print-main-branch)"

echo "Application des protections sur ${REPO}:${MAIN} ..."

python scripts/factory_sync.py --emit-branch-protection \
  | gh api -X PUT "repos/${REPO}/branches/${MAIN}/protection" --input -

echo "✅ Requête PUT acceptée par la plateforme."
echo "   Vérifier (champ par champ, état réel) : python scripts/factory_sync.py --check-remote"
echo "   Réponse brute à archiver dans reports/ : gh api repos/${REPO}/branches/${MAIN}/protection"
