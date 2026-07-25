# Preuves — US-00.1 · Secrets & scan de dépôt

Index des preuves pour l'audit (`/audit-us`) et la QA. Branche : `feat/US-00.1-secrets-scan-depot`.

## État des tâches d'implémentation (T1–T10)

| Tâche | Description | Statut | Preuve |
|---|---|---|---|
| **T1** | Créer `.gitleaks.toml` (fichier verrouillé) | ⏳ **HUMAIN** | Proposition prête : [`gitleaks.toml.proposed`](gitleaks.toml.proposed) → `cp` vers racine |
| **T2** | Vérifier le job CI `secrets-scan` | ✅ Fait | §Vérification CI ci-dessous |
| **T3** | Installer `gitleaks` localement | ⏳ **HUMAIN/DevOps** | `gitleaks version` (v8+) |
| **T4** | Committer les configs secrets dans le bon ordre | ⏳ (après T1) | `.gitleaks.toml` avant/avec `.env.example`+`.mcp.json` (déjà sur `main`) |
| **T5** | Scan historique complet → 0 fuite | ⏳ (après T1+T3) | `gitleaks-history.sarif` (à générer) |
| **T6** | Scan working tree / index → 0 fuite | ⏳ (après T1+T3) | `gitleaks-worktree.sarif` (à générer) |
| **T7** | Test négatif pre-commit (faux secret bloqué) | ⏳ **HUMAIN** (après T1+T3) | `negative-precommit.txt` (redacted) |
| **T8** | Test négatif CI (faux secret → job rouge) | ⏳ (après T1) | lien run Actions (branche jetable) |
| **T9** | Documenter la procédure de rotation | ✅ Fait | [`docs/security/SECRET_ROTATION.md`](../../docs/security/SECRET_ROTATION.md) |
| **T10** | Indexer les preuves | ✅ (ce fichier) | — |

Légende : ✅ fait · ⏳ en attente · **HUMAIN** = action non réalisable par l'agent (fichier verrouillé ou outil local).

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

## Preuves restantes

Elles nécessitent d'abord les actions humaines T1 (poser `.gitleaks.toml`) et T3 (installer
gitleaks). Une fois faites, @Developer génère T5/T6 (scans redacted) et T8 (test négatif CI) ;
l'humain réalise T7 (test négatif pre-commit local). Tous les rapports gitleaks archivés ici
utilisent `--redact` (aucune valeur de secret, même fausse, n'est écrite).
