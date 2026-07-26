# CLAUDE.md — Factory Concentration

> **Constitution complète (non-négociable) : [`docs/governance/CONSTITUTION.md`](docs/governance/CONSTITUTION.md)**
> Les règles ci-dessous en sont le résumé opérationnel. Chaque règle est **enforced** par un
> mécanisme automatique (hooks git versionnés, hooks Claude Code, gates CI) — pas seulement déclarée.

## Stack

Voir [`docs/governance/STACK_PROFILE.md`](docs/governance/STACK_PROFILE.md) (déposé par l'adapter
choisi à l'initialisation) : langages, frameworks, ORM/migrations, commandes de build/lint/test.
**Qualité (gates CI bloquants, `ci.yml`)** : seuils et commandes définis dans `factory.config.json`
(`adapter.components.*.gates`), exécutés via `python scripts/run_gates.py`.

## Règles dures (enforced)

1. **Traçabilité** : tout commit de code = ligne **ajoutée** au tableau `PROJECT_LOG.md`
   (`| YYYY-MM-DD | @Agent | Modèle | Action | Statut | Fichiers |`) + trailer `US: US-XX.X`
   dans le message (`type(scope): description`). *Enforced : pre-commit + commit-msg.*
2. **Jamais** `--no-verify`, jamais de commit/push sur la branche principale, jamais d'édition de
   fichier `.env` ou d'enforcement. *Enforced : hooks Claude Code + hooks git + protection de branche.*
3. **Événements** : toute transition de workflow passe par
   `python scripts/trace_append.py --us US-XXX --event EVT_* ...` (catalogue :
   `scripts/events_catalog.json` ; la machine à états rejette les transitions illégales).
4. **SCB** (`STORY_CERTIFICATION_BOARD.md`) : cohérence vérifiée à chaque édition (hook PostToolUse),
   au commit et en CI. `Certifié Prod = 🚀 OUI` exige `Déploiement = 🚀 DEPLOYED` + rituel `/certify`.
5. **Séparation des pouvoirs** : les audits passent par `/audit-us` (subagents à contexte frais) —
   jamais d'auto-certification dans la session qui a produit le code.
6. **Synchro config** : `factory.config.json` est la source unique (branches, seuils, status checks,
   commandes qualité) — `python scripts/factory_sync.py --check` (gate CI `governance`) détecte
   toute dérive entre la config et ses projections (CI, protection de branche, seuils de fichiers).

## Workflow

Squad de 10 agents : subagents natifs dans `.claude/agents/` — **source unique** (périmètres,
outils restreints, normes du rôle, sorties obligatoires). Séquence STANDARD :
`PO → Architect → (UX + Data) → Architect (lock) → Developer → /audit-us → QA → DevOps → /certify`.
Tracks proportionnés au risque (QUICK/STANDARD/FULL) : `docs/governance/TRACKS.md`.

**Rituels** : `/us-new` (créer une US complète — les Story Files rétroactifs sont interdits) ·
`/audit-us` (audits parallèles) · `/certify` (gate scripté) · `/sprint-status` (synthèse) ·
`/audit-methodo` (audit périodique de la factory).

Sous un rôle d'agent : le déclarer (`> Rôle actif : @X`), lire son subagent (`.claude/agents/<agent>.md`), rester dans son périmètre.

## Démarrage de session

Le hook `SessionStart` injecte automatiquement les 5 dernières lignes du PROJECT_LOG et l'état de
conformité SCB. Lire ensuite le Story File de l'US concernée si applicable.

## État courant du projet *(maintenu par @Architect)*

**Chantier actif** : **US-00.4 — CI + protection de branche réelles** (EPIC_00, track STANDARD), phase
`business_alignment`, branche `feat/US-00.4-ci-protection-branche`. Story File complet (7 AC, 13
scénarios, T1→T14). Prochaine étape : `EVT_STORY_READY` → `EVT_ARCHI_VALIDATED` **avec ADR-006** →
Lock (Data N/A + UX N/A) → développement.
**Sprint 0 (EPIC_00) : 3 US sur 6 certifiées** — US-00.1, US-00.2, US-00.3 🚀 ; restent US-00.4 (en
cours), US-00.5 (ADR-001 stack + Constitution), US-00.6 (couverture + ratchet). ⚠️ La mention
« SPRINT 0 COMPLET » du PROJECT_LOG au 2026-07-26 était **inexacte** (rectifiée en fin de tableau).
US-01.1 (EPIC_01, track FULL) reste **en pause** en `business_alignment` — à rebaser sur `main`.
**Dettes ouvertes** :
- 🔴 **`main` n'était pas protégée** (constaté 2026-07-26, `"protected": false`) alors que la règle
  est déclarée *enforced* → corrigé par **US-00.4** (risque #2 d'EPIC_00 matérialisé).
- 🔴 **`factory_sync.py --check` n'appelle jamais l'API GitHub** et annonce pourtant « protection
  conforme » — angle mort traité par US-00.4 (libellé *documentaire* + `--check-remote` hors CI).
- **Périmètre Art. 6 déclaré ≠ appliqué** : `.github/workflows/*` et `apply_branch_protection.sh` ne
  sont protégés ni par `protect_files.sh` ni par la Constitution → candidat `/audit-methodo`.
- **`governance.grandfathering_date` est une clé morte** : lue par aucun script, sémantique décalée
  (« US sans trace », pas « commits hors PR »). Laissée à `null` — à implémenter, redocumenter ou
  supprimer du schéma.
- Fichiers EPIC créés **rétroactivement** (EPIC_00, EPIC_01) — `/us-new` ne vérifie pas l'existence
  du fichier EPIC parent ; durcissement du rituel à décider.
- Décisions design à arbitrer (@UXDesigner + @PO) : gradient continu OKLCH (PRD) vs 4 paliers
  (maquette) ; endpoint bleu `#3D7DD8` (PRD) vs `#005ab3` (maquette) ; langue mixte fr/en des maquettes.
**US bloquées** : —
**Actions humaines en attente** :
- 🔴 **US-00.4, chemin critique** : installer + authentifier `gh` CLI (droits admin) — absent du poste
  alors que `apply_branch_protection.sh` en dépend.
- 🔴 **US-00.4, T5** : éditer `factory.config.json` (Art. 6) → `required_approving_review_count: 1 → 0`
  (`enforce_admins` reste `true`). Diff exact dans le Story File. **Ne pas toucher
  `grandfathering_date`.** Puis T6/T6b (`factory_sync.py`, `apply_branch_protection.sh`).
- Clarifier le statut de `US-INIT` (US à part entière vs simple porteur du Sprint 0).
- Décider la création de US-01.2 (Gestion des événements).
- Arbitrages design ci-dessus.

## Anti-patterns (à ne pas reproduire)

| Anti-pattern | Barrière actuelle |
|---|---|
| Implémenter sans visa @PO | `/us-new` + machine à états (EVT_STORY_READY requis) |
| Modifier une US certifiée sans re-audit | re-ouverture du cycle = nouveaux événements obligatoires |
| Committer sans PROJECT_LOG / `--no-verify` | hooks git + hook Claude Code + CI |
| Certifier sans déployer (`🚀 OUI` + `⏳`) | `check_scb_compliance.py` bloquant partout |
| Auditer son propre code dans la même session | `/audit-us` (contextes frais) |
