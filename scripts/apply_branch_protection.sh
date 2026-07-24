#!/bin/sh
# Applique RÉELLEMENT les protections de branche — le JSON est GÉNÉRÉ depuis
# factory.config.json (source unique des status checks) par factory_sync.py.
# Pré-requis : gh CLI installé et authentifié avec droits admin sur le dépôt.
# Usage : sh scripts/apply_branch_protection.sh [owner/repo]
set -e

cd "$(dirname "$0")/.."

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
MAIN="$(python scripts/factory_sync.py --print-main-branch)"

echo "Application des protections sur ${REPO}:${MAIN} ..."

python scripts/factory_sync.py --emit-branch-protection \
  | gh api -X PUT "repos/${REPO}/branches/${MAIN}/protection" --input -

echo "✅ Protections appliquées. Vérifier : gh api repos/${REPO}/branches/${MAIN}/protection"
