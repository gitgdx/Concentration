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

**Chantier actif** : — *(aucun)*. **US-00.4 CERTIFIÉE Prod 🚀 le 2026-07-27** (PR #10, `main` =
`15121d8` ; certification sur la branche post-merge `feat/US-00.4-certif`). ⚠️ **Sa portée est
étroite** : elle certifie la **valeur, l'honnêteté et la sûreté de l'outillage et du constat**, **pas**
la protection de `main` — voir l'encadré ci-dessous. **Prochaine US à décider** : **US-00.5** (ADR-001
stack + Constitution — **priorité relevée**, elle doit corriger le texte encore faux) ou **US-00.6**
(couverture + ratchet). US-01.1 (EPIC_01, FULL) reste en pause en `business_alignment`, **à rebaser sur
`main`**, et son Lock exige d'abord l'arbitrage `TRACKS.md` ci-dessous.

> 🔴 **À LIRE AVANT TOUT AUDIT** — La règle 2 ci-dessus (« jamais de commit/push sur la branche
> principale, *enforced par protection de branche* ») est **FAUSSE aujourd'hui**. La protection de
> branche est **indisponible** sur ce dépôt : `GET …/branches/main/protection` **et** `GET …/rulesets`
> renvoient un **403 « Upgrade to GitHub Pro or make this repository public »** (dépôt privé, jeton
> admin). Une **dérogation humaine** est tracée (`EVT_WAIVER_GRANTED`, Art. 5 : ni Pro, ni dépôt
> public). Ce qui protège `main` = hook `pre-push` **local** + CI qui **rapporte** sans pouvoir
> **bloquer** = **filet de discipline, pas contrainte de plateforme**. **Risque #2 d'EPIC_00 OUVERT** ;
> la certification d'US-00.4 ne le clôt pas. Correction du texte de la règle = **US-00.5**.
**Sprint 0 (EPIC_00) : 4 US sur 6 certifiées** — US-00.1, US-00.2, US-00.3, **US-00.4** 🚀 ; restent
US-00.5 (ADR-001 stack + Constitution), US-00.6 (couverture + ratchet). 🔴 **EPIC_00 ne pourra PAS être
déclarée complète** même après US-00.5/00.6 : son critère de clôture « protection de branche vérifiée »
est **impossible à cocher** sur ce plan (403), et le **risque #2 reste OUVERT**. ⚠️ La mention
« SPRINT 0 COMPLET » du PROJECT_LOG au 2026-07-26 était **inexacte** (rectifiée en fin de tableau).
US-01.1 (EPIC_01, track FULL) reste **en pause** en `business_alignment` — à rebaser sur `main`.
**Dettes ouvertes** :
- 🔴 **DETTE MAJEURE — `main` n'est PAS protégée et ne peut pas l'être sur ce plan** (403 sur la
  protection classique **et** les rulesets ; dépôt privé). **Risque #2 d'EPIC_00 OUVERT** ; le critère
  de clôture « protection de branche vérifiée » est **impossible à cocher** → **EPIC_00 ne peut pas
  être déclarée complète**. Déblocage : dépôt public **ou** GitHub Pro (~4 USD/mois), puis T16→T19
  d'US-00.4. Réévaluation à chaque `/audit-methodo`.
- 🔴 **Le texte de gouvernance affirme un enforcement inexistant** : règle 2 de ce fichier + Art. 4 de
  la Constitution. Correction = **US-00.5** (priorité relevée, à enchaîner juste après US-00.4).
- ✅ **RÉSOLU par US-00.4** : `factory_sync.py --check` annonce désormais une vérification
  **DOCUMENTAIRE** et avertit que l'état réel n'est pas vérifié ; `--check-remote` interroge l'API
  (hors CI, droits admin). **Actif sur `main`.**
- 🔴 **NB-1 — trou résiduel DÉMONTRÉ dans le comparateur, correctif à 1 ligne** :
  `scripts/check_branch_protection.py:503` passe `MAPPED_TOP_KEYS` (constante **statique**) au lieu de
  `MAPPED_TOP_KEYS & set(expected)` → **exit 0 possible sur un relâchement réel** avec une cible
  amputée. Verrouillé derrière une édition Art. 6, d'où le classement non bloquant.
- 🔴 **Aucun `selftest` en CI** pour `check_branch_protection.py` : les 12 chemins sont exercés par
  fixtures versionnées mais **lancées à la main**. Recommandation forte du re-audit — « c'est lui, pas
  le hook, qui arrête une régression » de la frontière de couverture.
- ⚠️ **Émetteurs d'événements déclarés mais NON enforced** : `scripts/trace_append.py` **ne lit jamais**
  le champ `emitter` de `events_catalog.json` (vérifié, 0 occurrence) → un agent peut émettre n'importe
  quel événement sous n'importe quel rôle. Même classe de défaut que celle qu'US-00.4 dénonce, dans le
  système de traçabilité lui-même. Candidat `/audit-methodo`.
- ⚠️ **`TRACKS.md` (track FULL) exige une « revue humaine explicite de la PR » qu'aucune barrière
  machine ne soutient** — ni maintenant, ni après déblocage (cible à `0` approbation). **US-01.1 est en
  FULL** → arbitrage à poser **avant son Integration Lock** : requalifier l'exigence en obligation de
  process avec preuve tracée, ou engager la voie « 2ᵉ compte relecteur ».
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
- ✅ **FAIT** : `gh` CLI installé (2.96.0) et authentifié `gitgdx` avec `admin: true`. Chemin absolu si
  absent du `PATH` d'une session ouverte avant l'install : `C:\Program Files\GitHub CLI\gh.exe`.
- ✅ **FAIT** : `factory.config.json` porte `required_approving_review_count: 0` (`enforce_admins: true`).
- ✅ **FAIT** : T4 (`scripts/factory_sync.py`), T5, T6 et T22 (`scripts/githooks/pre-push` — le hook ne
  se réclame plus de la protection de branche) — toutes les actions humaines d'US-00.4 sont soldées.
- 🔴 **Décider du déblocage de la protection de branche** (dépôt public vs GitHub Pro ~4 USD/mois vs
  statu quo) — la dérogation est tracée, mais c'est **la** dette majeure du projet. Le jour du
  déblocage : T16→T19 d'US-00.4 sont prêtes à être reprises **telles quelles**.
- **Planifier les dettes techniques d'US-00.4** : correctif NB-1 (1 ligne) et `selftest` en CI.
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
