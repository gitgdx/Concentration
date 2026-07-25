# Preuves — US-00.1 · Secrets & scan de dépôt

Index des preuves pour l'audit (`/audit-us`) et la QA. Branche : `feat/US-00.1-secrets-scan-depot`.

## État des tâches d'implémentation (T1–T10)

| Tâche | Description | Statut | Preuve |
|---|---|---|---|
| **T1** | Créer `.gitleaks.toml` (fichier verrouillé) | ✅ Fait (HUMAIN) | Config posée à la racine, identique à [`gitleaks.toml.proposed`](gitleaks.toml.proposed) |
| **T2** | Vérifier le job CI `secrets-scan` | ✅ Fait | §Vérification CI ci-dessous |
| **T3** | Installer `gitleaks` localement | ✅ Fait (HUMAIN) | gitleaks **8.30.1** installé (winget) |
| **T4** | Committer `.gitleaks.toml` | ✅ Fait | ce commit |
| **T5** | Scan historique complet → 0 fuite | ✅ Fait | [`gitleaks-history.sarif`](gitleaks-history.sarif) — 11 commits, `no leaks found` |
| **T6** | Scan working tree → 0 fuite | ✅ Fait | [`gitleaks-worktree.sarif`](gitleaks-worktree.sarif) — 89 MB scannés, `no leaks found` |
| **T7** | Test négatif pre-commit (faux secret détecté) | ✅ Fait | [`negative-precommit.txt`](negative-precommit.txt) — `leaks found: 1`, exit 1 |
| **T8** | Test négatif CI (faux secret → job rouge) | ⏳ (nécessite un PR) | lien run Actions (branche jetable) |
| **T9** | Documenter la procédure de rotation | ✅ Fait | [`docs/security/SECRET_ROTATION.md`](../../docs/security/SECRET_ROTATION.md) |
| **T10** | Indexer les preuves | ✅ (ce fichier) | — |

Légende : ✅ fait · ⏳ en attente · (HUMAIN) = étape réalisée par l'humain (fichier verrouillé / outil local).

### Résultats des scans (gitleaks 8.30.1, config `.gitleaks.toml`)

- **T5 — historique** (`gitleaks git`) : 11 commits, ~396 KB → **`no leaks found`** (exit 0).
- **T6 — working tree** (`gitleaks dir`) : ~89 MB (inclut `.claude/settings.local.json`, qui contient
  la **vraie** clé Stitch) → **`no leaks found`** (exit 0) → **valide l'allowlist** (pas de faux positif
  sur la clé locale légitime).
- **T7 — négatif** (`gitleaks protect --staged` sur un faux `AQ.<token>` injecté) → **`leaks found: 1`,
  exit 1** → le garde-fou détecte ; le hook `pre-commit` (section 4) appelle alors `fail` et bloque le
  commit. Faux secret retiré immédiatement, jamais committé.

> **Note outillage** : gitleaks 8.30.1 ne liste plus `detect`/`protect` dans `--help` (remplacés par
> `git`/`dir`), mais `gitleaks protect --staged` reste un **alias déprécié fonctionnel** → le hook
> `pre-commit` du dépôt (qui l'utilise) **fonctionne sans modification**. Vérifié empiriquement.

## Vérification CI — job `secrets-scan` (T2)

Vérifié dans [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) :

- ✅ **`fetch-depth: 0`** présent sur `actions/checkout@v4` → le scan couvre **l'historique complet**
  (indispensable à AC-2, sinon gitleaks ne verrait qu'un shallow clone).
- ✅ **`gitleaks/gitleaks-action@v2`** : auto-détection d'un `.gitleaks.toml` à la racine → une fois
  T1 fait, CI **et** pre-commit partagent la **même** config (AC-1 / AC-3).
- ✅ **Bloc `permissions:`** (`contents: read`, `pull-requests: write`) ajouté en amont (corrige
  l'erreur `Resource not accessible by integration` — le job passe désormais au vert sur les PR).
- ℹ️ Tant que `.gitleaks.toml` n'existe pas, la CI tourne sur les **règles par défaut** de gitleaks.
  T1 calibre le filet à la stack réelle (Stitch, `.env`, signature mobile).

**Conclusion T2** : aucune édition de `ci.yml` requise pour US-00.1 (le job est correctement câblé).

## Preuve restante — T8 (test négatif CI)

Seul **T8** reste : prouver qu'un faux secret poussé sur une PR fait **échouer** le job CI
`secrets-scan`. Il nécessite une **branche jetable + PR** (le job tourne sur `pull_request`), puis
la suppression de la branche/commit (le faux secret n'est **jamais** mergé). À réaliser au moment
de l'ouverture de la PR US-00.1. Tous les rapports archivés ici utilisent `--redact`.
