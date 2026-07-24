# 📜 PROJECT_LOG.md - Suivi de la Software Factory

## 🚦 État du Workflow : SPRINT_0_INIT

| Date | Agent | Modèle LLM | Action | Statut | Fichiers Impactés |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 2026-07-24 | @Architect | init-script | Initialisation de la factory depuis factory-starter-kit v1.0.0 | SUCCESS | factory.config.json, .claude/, scripts/, .github/workflows/ |
| 2026-07-24 | @ProductOwner | claude-opus-4-8 | Création US-01.1 (EPIC_01, track FULL) via /us-new : Story File (9 AC, 13 scénarios Gherkin), SCB, traces EVT_STORY_CREATED+EVT_TRACK_SELECTED ; maquettes Stitch rapatriées | SUCCESS | BACKLOG.md, STORY_CERTIFICATION_BOARD.md, docs/stories/US-01.1-affichage-hub-grille.md, tests/features/US-01.1-affichage-hub-grille.feature, docs/design/stitch/, docs/trace/US-01.1/events.jsonl |
| 2026-07-24 | @Architect | claude-opus-4-8 | Recadrage workflow : création des fichiers EPIC manquants (bootstrap EPIC_00 + EPIC_01) + colonne Fichier EPIC au backlog ; correction péremption SCB (9 AC/13 scénarios) | SUCCESS | docs/epics/EPIC_00-fondations.md, docs/epics/EPIC_01-module-echeances.md, BACKLOG.md, STORY_CERTIFICATION_BOARD.md |
| 2026-07-24 | @ProductOwner | claude-opus-4-8 | Création US-00.1 (EPIC_00, track STANDARD) via /us-new : Story File (4 AC, 8 scénarios Gherkin), SCB (Design N/A justifié), traces EVT_STORY_CREATED+EVT_TRACK_SELECTED ; découverte : .gitleaks.toml absent (à créer) | SUCCESS | STORY_CERTIFICATION_BOARD.md, docs/stories/US-00.1-secrets-scan-depot.md, tests/features/US-00.1-secrets-scan-depot.feature, docs/epics/EPIC_00-fondations.md, docs/trace/US-00.1/events.jsonl |
| 2026-07-24 | @ProductOwner | claude-opus-4-8 | Création US-00.2 (EPIC_00, track STANDARD) via /us-new : Story File (4 AC, 6 scénarios Gherkin), SCB (Design N/A justifié), traces EVT_STORY_CREATED+EVT_TRACK_SELECTED | SUCCESS | STORY_CERTIFICATION_BOARD.md, docs/stories/US-00.2-qualite-statique.md, tests/features/US-00.2-qualite-statique.feature, docs/epics/EPIC_00-fondations.md, docs/trace/US-00.2/events.jsonl |
| 2026-07-24 | @ProductOwner | claude-opus-4-8 | Création US-00.3 (EPIC_00, track STANDARD) via /us-new : Story File (4 AC, 6 scénarios Gherkin, cadrage « convention de migrations réversibles » — techno de persistance reportée à US-01.2), SCB, EPIC_00 + backlog alignés US-00.x, traces EVT_STORY_CREATED+EVT_TRACK_SELECTED | SUCCESS | docs/stories/US-00.3-migrations-reversibles.md, tests/features/US-00.3-migrations-reversibles.feature, STORY_CERTIFICATION_BOARD.md, docs/epics/EPIC_00-fondations.md, BACKLOG.md, docs/trace/US-00.3/events.jsonl |

> **Format (enforced par `scripts/validate_trace.py` + hooks)** : ce fichier ne contient QUE le
> tableau ci-dessus — une ligne par action, pas de blocs narratifs. Le détail machine-parsable vit
> dans `docs/trace/US-XXX/events.jsonl`.
