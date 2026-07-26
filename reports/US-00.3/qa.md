# Rapport QA — US-00.3 · Migrations réversibles

**Verdict : 🧪 PASS.** Branche : `feat/US-00.3-migrations-reversibles`. Date : 2026-07-26 · @QA_Tester.

US de **convention** : au Sprint 0 aucun schéma concret → la QA est une **revue de conformité** de la
convention + non-régression (l'exécution automatisée du round-trip incombe à US-01.2).

## 1. Non-régression (le canevas Dart est en markdown, pas compilé)

```
$ python scripts/run_gates.py --gate analyze
No issues found! (ran in 9.1s)          ✅ app.analyze (exit 0)

$ python scripts/run_gates.py --gate format
Formatted 2 files (0 changed)           ✅ app.format (exit 0)
```

- Fichiers d'enforcement (`factory.config.json`, `scripts/*`, `.github/*`, `.claude/*`) : **intacts**
  (`git diff main...HEAD` sur ces chemins = vide).

## 2. Revue de conformité de la convention (AC-1 → AC-4)

| AC | Vérifié dans `docs/architecture/MIGRATIONS.md` |
|---|---|
| **AC-1** | §1 — versionnement entier monotone, `v0`=aucun schéma, `+1` + couple up/down, cas de base `v0→v1` |
| **AC-2** | §2 — invariant aller-retour `up→down` = état équivalent, rejet des `down` non conformes |
| **AC-3** | §3 — additif par défaut (RF-21), destructif interdit sauf préservation + `EVT_WAIVER_GRANTED` |
| **AC-4** | §4 — patron round-trip `seed→up→assert@N→down→assert@N-1` documenté, à instancier par US-01.2 |

ADR-005 : statut **Accepté**. Agnosticisme techno (§5) confirmé, point d'application US-01.2 documenté.

## 3. Couverture BDD — 6/6 scénarios

`tests/features/US-00.3-migrations-reversibles.feature` : 6 scénarios (versionnement, aller-retour,
down non conforme, additif, destructif bloqué, patron de test au Sprint 0) — tous couverts par la
convention (le « gate échoue » = « contrôle de revue échoue », AC-4 non exécutable sans schéma).

## Synthèse

- Non-régression : analyze + format verts, enforcement intact.
- Conformité : AC-1..4 couverts, ADR-005 Accepté, 6/6 BDD.
- Audits amont : Rev 🔍 ✅ + Sec 🛡️ ✅.

→ **`EVT_QA_PASSED`.** Reste : déploiement (merge sur `main`) → `/certify`.
