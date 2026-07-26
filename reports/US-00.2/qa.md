# Rapport QA — US-00.2 · Qualité statique de référence

**Verdict : 🧪 PASS.** Validation par exécution réelle d'outils. Branche : `feat/US-00.2-qualite-statique`.
Date : 2026-07-26 · Rôle : @QA_Tester.

## 1. Gates cœur de l'US (AC-1 / AC-2)

```
$ python scripts/run_gates.py --gate format
Formatted 2 files (0 changed) in 0.07 seconds.   ✅ app.format (exit 0)

$ python scripts/run_gates.py --gate analyze
No issues found! (ran in 14.9s)                  ✅ app.analyze (exit 0)
```

## 2. Non-régression — `run_gates.py --component app`

`Tous les gates bloquants passent (5 exécutés)` (exit 0) : format, analyze, test (couverture ≥ 80 %),
deps_audit, build web. Aucune régression (aucun code Dart modifié par l'US).

## 3. Couverture BDD — `tests/features/US-00.2-qualite-statique.feature`

**6 scénarios** déclarés, mappés aux preuves :

| Scénario | Preuve |
|---|---|
| 1 — format conforme (AC-1) | gate `format` exit 0 |
| 2 — analyse 0 issue (AC-2) | gate `analyze` « No issues found! » |
| 3 — 0 règle désactivée sans justification (AC-3) | `analysis_options.yaml` 0 désactivation effective + audit revue |
| 4 — règle désactivée sans justif → contrôle de revue échoue (AC-3) | enforcement = revue @CodeReviewer (pas un gate auto) |
| 5 — fichier mal formaté → gate `format` échoue (AC-1) | comportement `--set-exit-if-changed` |
| 6 — reproductibilité local ↔ CI (AC-4) | mêmes commandes `factory.config.json`, job `app-quality` vert |

## Synthèse

- Suites : **5 gates** app verts (0 fail/0 skip) + gates cœur format/analyze verts.
- Scénarios BDD : **6/6** couverts.
- Régression : **aucune**.
- Audits amont : Rev 🔍 ✅ + Sec 🛡️ ✅.

→ **`EVT_QA_PASSED`.** Reste : déploiement (merge sur `main`) → `/certify`.
