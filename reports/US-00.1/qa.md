# Rapport QA — US-00.1 · Secrets & scan de dépôt

**Verdict : 🧪 PASS.** Validation par exécution réelle d'outils (un PASS sans sortie d'outil serait invalide).

Branche : `feat/US-00.1-secrets-scan-depot` · Date : 2026-07-26 · Rôle : @QA_Tester.

## 1. Non-régression — `python scripts/run_gates.py --component app`

**Résultat : `Tous les gates bloquants passent (5 exécutés)`** (exit 0).

| Gate | Résultat |
|---|---|
| `app.format` (`dart format`) | ✅ |
| `app.analyze` (`flutter analyze`) | ✅ |
| `app.test` (`flutter test --coverage` + seuil 80 %) | ✅ (couverture inchangée — aucun code Dart ajouté) |
| `app.deps_audit` (`dart pub outdated`) | ✅ (non bloquant) |
| `app.build` (`flutter build web --release`) | ✅ (`√ Built build\web`) |

> US sans code applicatif Dart : les gates tournent en **non-régression**. La preuve QA propre à
> l'US = les exécutions **gitleaks** (ci-dessous), pas la couverture Flutter (aucune ligne à couvrir).

## 2. Preuve principale — scan secrets (gitleaks 8.30.1, config `.gitleaks.toml`)

- `gitleaks git --config .gitleaks.toml --redact` → **14 commits scannés, `no leaks found`** (exit 0).
- Historique + working tree à 0 fuite déjà archivés : `gitleaks-history.sarif`, `gitleaks-worktree.sarif`.

## 3. Couverture BDD — `tests/features/US-00.1-secrets-scan-depot.feature`

**8 scénarios** déclarés, mappés aux preuves :

| Scénario | Preuve |
|---|---|
| 1 — config présente/adaptée (AC-1) | `.gitleaks.toml` + `reports/US-00.1/README.md` §T2 |
| 2 — scan historique 0 fuite (AC-2) | `gitleaks-history.sarif` (T5) |
| 3 — scan working tree 0 fuite (AC-2) | `gitleaks-worktree.sarif` (T6) |
| 4 — placeholders/gitignorés non signalés (AC-1/2) | scan working tree 0 fuite (allowlist validée) |
| 5 — faux secret bloqué en pre-commit (AC-3) | `negative-precommit.txt` (T7, `leaks found:1`) |
| 6 — faux secret → CI rouge (AC-3) | run CI PR #2 `failure` (T8) |
| 7 — procédure de rotation accessible (AC-4) | `docs/security/SECRET_ROTATION.md` |
| 8 — aucun secret réel ⇒ « aucune rotation requise » (AC-4) | `SECRET_ROTATION.md` §5 |

## Synthèse

- Suites exécutées : **5 gates** app (5 pass / 0 fail / 0 skip) + confirmation secrets indépendante.
- Scénarios BDD : **8/8** couverts par preuves outillées.
- Régression : **aucune** (gates verts, aucun code Dart modifié).
- Audits amont : Rev 🔍 ✅ + Sec 🛡️ ✅ (préconditions `EVT_QA_PASSED` réunies).

→ **`EVT_QA_PASSED`.** Reste : décision de déploiement (@DevOps) puis `/certify`.
