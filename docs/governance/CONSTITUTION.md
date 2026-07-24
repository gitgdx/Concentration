# 📜 Constitution de la Factory Concentration

> Principes **non-négociables**, référencés à chaque phase du workflow (inspiré du
> `constitution.md` de GitHub Spec Kit). Chaque article indique son **enforcement** : une règle
> sans mécanisme d'application est un vœu, pas une règle. Version 1.0 — 2026-07-24.

---

## Art. 1 — Traçabilité totale

Tout commit contenant du code (extensions déclarées dans `factory.config.json` →
`governance.code_extensions`) inclut une ligne **ajoutée** au tableau de `PROJECT_LOG.md` et un
trailer `US: US-XX.X` (ou `US: none — <justification>`). Tout événement de workflow est tracé en
JSONL dans `docs/trace/US-XXX/events.jsonl` avec agent, modèle réel, rationale et preuves.
`--no-verify` est interdit.

**Enforcement** : hook git `pre-commit` + `commit-msg` (scripts/githooks) · hook Claude Code
`block_dangerous_bash.sh` (--no-verify bloqué) · CI job `governance` (`validate_trace.py --all`).

## Art. 2 — Séparation des pouvoirs

**Celui qui produit ne certifie pas.** Les audits (revue, sécurité, QA) sont réalisés par des
subagents à **contexte frais** (`.claude/agents/code-reviewer.md`, `cyber-security.md`,
`qa-tester.md`) qui n'ont pas accès à la conversation ayant produit le code. Un agent ne coche
jamais sa propre colonne d'audit dans le SCB.

**Enforcement** : rituel `/audit-us` (lance les subagents en parallèle) · `validate_trace.py`
(un visa SCB sans événement tracé par l'agent auditeur est une violation).

## Art. 3 — Preuves exécutables

Un verdict (audit, QA, certification) s'appuie sur des **exécutions d'outils reproductibles**
(les gates de l'adapter, exécutés via `python scripts/run_gates.py`) dont les sorties figurent
dans le rapport `reports/US-XXX/<type>.md`. Un visa SCB sans `evidence` dans la trace est invalide.
Un scénario E2E *skipped* n'est pas un scénario vert : les rapports QA indiquent le décompte
passed/skipped/failed.

**Enforcement** : `validate_trace.py` (existence des rapports référencés) · rituels `/audit-us`
et `/certify` (rejettent un rapport sans sortie d'outil).

## Art. 4 — Seuil qualité unique

Les seuils de couverture et les gates bloquants (lint, typecheck, SAST, audit de dépendances,
tests) sont définis en **un seul endroit** : `factory.config.json` →
`adapter.components.*.gates` et `coverage_min` / `coverage_ratchet`. Ils sont vérifiés par
`python scripts/factory_sync.py --check` (cohérence config ↔ fichiers de l'adapter) et exécutés
par `python scripts/run_gates.py`.

**Enforcement** : CI `ci.yml` jobs qualité, requis par la protection de branche
(`scripts/apply_branch_protection.sh`) ; job `governance` (synchro).

## Art. 5 — Autorité de certification

- **@QA_Tester** délivre `🧪 PASS` (constat outillé, jamais plus).
- **@DevOps_Engineer** constate `🚀 DEPLOYED` (health-check vert, jamais plus).
- **@Architect** appose `Certifié Prod = 🚀 OUI` **si et seulement si** le rituel `/certify`
  (gate scripté) passe — y compris `Déploiement = 🚀 DEPLOYED`. L'Architecte n'a pas le pouvoir
  de passer outre le script.
- Toute dérogation est **humaine uniquement**, tracée `EVT_WAIVER_GRANTED` avec justification.

**Enforcement** : `check_scb_compliance.py` (règle `🚀 OUI ⇒ DEPLOYED`) en PostToolUse,
pre-commit et CI · machine à états de `trace_append.py` (préconditions d'`EVT_CERTIFIED_PROD`).

## Art. 6 — Secrets et fichiers d'enforcement

Les secrets ne vivent que dans les variables d'environnement de la plateforme d'hébergement et les
`.env` locaux jamais commités. Les fichiers d'enforcement (`scripts/githooks/`,
`.claude/settings.json`, `.claude/hooks/`, `.gitleaks.toml`, `factory.config.json`,
`scripts/factory_env.sh`) ne sont modifiables que par action humaine explicite.

**Enforcement** : gitleaks (pre-commit + CI `secrets-scan`) · hook `protect_files.sh` ·
`.gitignore`.

## Art. 7 — Workflow scale-adaptive

Chaque US passe par un track proportionné à son risque — QUICK, STANDARD ou FULL — choisi sur
critères objectifs à la création (`/us-new`) et tracé `EVT_TRACK_SELECTED`.
Définitions : `docs/governance/TRACKS.md`.

**Enforcement** : rituel `/us-new` · `validate_trace.py` (présence de l'événement).

## Art. 8 — Spécification avant code

Aucun développement ne démarre sans Story File complet (AC Nominal/Erreur/Limite + Gherkin) et
`EVT_DESIGN_COMPLETED` tracé. Les Story Files **rétroactifs sont interdits** : le Story File
précède le code (spec-driven). Gates pré-développement : clarify → checklist → analyze (intégrés
à `/us-new`).

**Enforcement** : subagent `developer.md` (refus explicite sans EVT_DESIGN_COMPLETED) ·
machine à états (EVT_CODE_READY exige EVT_DESIGN_COMPLETED).

---

## Révision

La Constitution s'amende par PR dédiée approuvée par l'humain (jamais en side-effect d'une US),
avec ligne PROJECT_LOG et incrément de version. Le rituel `/audit-methodo` (périodique) évalue
l'application réelle de chaque article et propose des amendements.
