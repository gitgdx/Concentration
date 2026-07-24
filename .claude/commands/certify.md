---
description: Gate de certification scripté d'une US — la certification est un constat d'outils, pas une opinion
argument-hint: <US-ID>
---

Rituel de certification de l'US : $ARGUMENTS

**Principe (Constitution Art. 5)** : `Certifié Prod = 🚀 OUI` est apposé par @Architect **si et
seulement si** chaque gate ci-dessous passe. Aucun gate ne peut être sauté sans dérogation humaine
tracée (`EVT_WAIVER_GRANTED`).

Exécute dans l'ordre et ARRÊTE-TOI au premier échec en expliquant ce qui manque :

1. `python scripts/check_scb_compliance.py` → exit 0.
2. `python scripts/validate_trace.py --us $ARGUMENTS` → exit 0 (chaîne d'événements complète :
   STORY → DESIGN → CODE_READY → REVIEW_PASSED + SECURITY_PASSED → QA_PASSED, preuves existantes).
3. **Rapports** : `reports/$ARGUMENTS/code_review.md`, `security.md`, `qa.md` existent et contiennent
   des sorties d'outils.
4. **DoD** : ouvrir le Story File `docs/stories/$ARGUMENTS-*.md` — toutes les cases de la DoD sont cochées.
5. **Gates techniques à blanc** : `python scripts/run_gates.py --all`.
6. **Déploiement** : la colonne SCB `Déploiement (DevOps)` vaut `🚀 DEPLOYED`
   (sinon la certification s'arrête à `🧪 PASS`).

Si TOUT passe :
- SCB : `Certifié Prod` → `🚀 OUI`, phase → `epic_closure` ;
- `python scripts/trace_append.py --us $ARGUMENTS --event EVT_CERTIFIED_PROD --agent architect --model <modèle réel> --rationale "Gates /certify tous verts"` ;
- ligne PROJECT_LOG.

Termine par : résultat de chaque gate (✅/❌) et l'action effectuée.
