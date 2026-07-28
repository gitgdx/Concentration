#!/bin/sh
# Applique RÉELLEMENT les protections de branche — le JSON est GÉNÉRÉ depuis
# factory.config.json (source unique des status checks) par factory_sync.py.
# Pré-requis : gh CLI installé et authentifié avec droits admin sur le dépôt.
#
# ✅ APPLICABLE depuis le 2026-07-27 sur gitgdx/Concentration (dépôt rendu PUBLIC, décision humaine
#    Art. 5) — et VALIDÉ EN PRODUCTION le 2026-07-28 : le PUT a été accepté, la protection est en
#    vigueur, son effet est prouvé (reports/US-00.7/applied_state/). Ce script est la VOIE NORMALE
#    de (ré-)application de la protection depuis la source unique factory.config.json.
#    Toute divergence entre le dépôt et la config se corrige en RÉ-APPLIQUANT ce script — jamais en
#    alignant la config sur l'état constaté, jamais via l'écran Settings → Branches, jamais avec un
#    JSON écrit à la main.
#
# ⚠️ CE SCRIPT MODIFIE L'ENFORCEMENT DE LA BRANCHE PRINCIPALE et exige des DROITS ADMIN. Ce n'est
#    pas une commande de lecture : après lui, tout merge dépend d'une PR à 4 status checks verts,
#    SANS bypass administrateur. Lire docs/GIT_PROTECTION.md §Plan de retour arrière AVANT de
#    l'exécuter — un libellé de contexte divergent rendrait toute PR infusionnable (verrouillage).
#    Décision de référence : docs/adr/ADR-007-application-protection-branche.md (remplace ADR-006).
#
# ⚠️ CONDITIONNEL : l'applicabilité dépend de la VISIBILITÉ PUBLIQUE du dépôt. Un retour en privé
#    ramènerait le 403 de plan et ce script échouerait de nouveau.
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
