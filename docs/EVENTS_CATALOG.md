# 📡 Catalogue des événements — Software Factory

> ⚠️ **Source de vérité : [`scripts/events_catalog.json`](../scripts/events_catalog.json)**.
> Ce document est la vue humaine de ce fichier. Les événements sont tracés en JSONL dans
> `docs/trace/US-XXX/events.jsonl` via `scripts/trace_append.py` (qui valide le nom ET les
> préconditions) et vérifiés par `scripts/validate_trace.py` en pre-commit et en CI.
>
> **Alias dépréciés** (rejetés par le validateur) :
> `DATA_ENGINEER_COMPLETED` → `EVT_DATA_DESIGN_COMPLETED` · `UX_DESIGNER_COMPLETED` → `EVT_UX_DESIGN_COMPLETED`
> · `EVT_QA_READY_FOR_PROD` → `EVT_QA_PASSED` · `EVT_STORY_READY_FOR_TECH_VALIDATION` → `EVT_STORY_READY`

## 📋 Table des événements

| Événement | Émetteur | Consommateurs | Préconditions | Description |
|---|---|---|---|---|
| `EVT_STORY_CREATED` | product-owner | architect | — | Story File + ligne SCB + Gherkin créés (`/us-new`) |
| `EVT_TRACK_SELECTED` | architect | * | STORY_CREATED | Track QUICK/STANDARD/FULL choisi |
| `EVT_STORY_READY` | product-owner | architect | STORY_CREATED | AC + Gherkin rédigés, PO Visa ✅ |
| `EVT_ARCHI_VALIDATED` | architect | data-engineer, ux-designer | STORY_READY | Story validée techniquement |
| `EVT_DATA_DESIGN_COMPLETED` | data-engineer | architect | ARCHI_VALIDATED | Schéma + migration prêts |
| `EVT_UX_DESIGN_COMPLETED` | ux-designer | architect | ARCHI_VALIDATED | Wireframes + tokens prêts |
| `EVT_MIGRATION_SCRIPT_READY` | data-engineer | devops | DATA_DESIGN_COMPLETED | Migration réversible validée |
| `EVT_DESIGN_COMPLETED` | architect | developer | ARCHI_VALIDATED | Integration Lock — codage autorisé |
| `EVT_CODE_READY` | developer | code-reviewer, cyber-security | DESIGN_COMPLETED | Code + tests poussés |
| `EVT_CODE_REVIEW_PASSED` | code-reviewer | qa-tester, architect | CODE_READY | Revue validée (✅ 🔍) |
| `EVT_CODE_REVIEW_FAILED` | code-reviewer | developer, architect | CODE_READY | Revue refusée |
| `EVT_SECURITY_AUDIT_PASSED` | cyber-security | qa-tester, architect | CODE_READY | Audit sécurité validé (✅ 🛡️) |
| `EVT_SECURITY_AUDIT_FAILED` | cyber-security | developer, architect | CODE_READY | Audit sécurité refusé |
| `EVT_QA_PASSED` | qa-tester | architect | REVIEW_PASSED, SECURITY_PASSED | Tests validés (🧪 PASS) |
| `EVT_QA_FAILED` | qa-tester | developer | — | Échec des tests |
| `EVT_READY_FOR_DEPLOY` | architect | devops | QA_PASSED | Déploiement autorisé |
| `EVT_STAGING_DEPLOYED` | devops | architect, qa-tester | READY_FOR_DEPLOY | Staging réussi |
| `EVT_STAGING_FAILED` | devops | architect | READY_FOR_DEPLOY | Échec staging |
| `EVT_DEPLOYMENT_SUCCESS` | devops | architect, tech-writer | STAGING_DEPLOYED | Prod réussie (🚀 DEPLOYED) |
| `EVT_DEPLOYMENT_FAILURE` | devops | architect | — | Échec du déploiement |
| `EVT_DOCS_UPDATED` | tech-writer | architect | DEPLOYMENT_SUCCESS | Doc + CHANGELOG à jour |
| `EVT_DEV_BLOCKER` | developer | architect, product-owner | — | Blocage technique — arbitrage requis |
| `EVT_WORKFLOW_VIOLATION` | architect | * | — | Violation du workflow constatée |
| `EVT_WAIVER_GRANTED` | human | * | — | Dérogation humaine justifiée |
| `EVT_CERTIFIED_PROD` | architect | * | QA_PASSED, DEPLOYMENT_SUCCESS | Certification finale (🚀 OUI, via `/certify`) |

## 🛠️ Règles d'émission et de format

1. Chaque événement significatif est consigné dans `PROJECT_LOG.md` (colonne Action ou Statut).
2. Chaque intervention d'agent mentionne l'événement émis dans son résumé de fin.
3. Le nom et les préconditions sont validés par `scripts/trace_append.py` AVANT écriture — un
   événement inconnu ou prématuré est rejeté avec un message explicite.
