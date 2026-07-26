# Preuves — US-00.2 · Qualité statique de référence

Index des preuves exécutables (Constitution Art. 3). Branche : `feat/US-00.2-qualite-statique`.
US de **validation de l'existant** (`flutter_lints`) — aucun durcissement, aucune modification de code.

## État des tâches T1–T7

| Tâche | Description | Statut | Preuve |
|---|---|---|---|
| **T1** | Résoudre les dépendances (`flutter pub get`) | ✅ | `flutter_lints ^6.0.0` résolu |
| **T2** | Vérifier `analysis_options.yaml` (0 désactivation effective) | ✅ | §Config lint ci-dessous |
| **T3** | Gate `format` | ✅ | `Formatted 2 files (0 changed)`, exit 0 |
| **T4** | Gate `analyze` | ✅ | `No issues found!`, exit 0 |
| **T5** | Revue AC-3 (directives `// ignore`) | ✅ | aucune directive dans `lib/`/`test/` |
| **T6** | Preuves (ce fichier) | ✅ | — |
| **T7** | Reproductibilité local ↔ CI | ✅ | job `app-quality` vert sur la PR |

## Config lint (T2 — AC-3)

`analysis_options.yaml` (racine) :
- `include: package:flutter_lints/flutter.yaml` **présent** (set de base actif).
- `linter.rules` ne contient **que 2 lignes d'exemple commentées** (`# avoid_print: false`,
  `# prefer_single_quotes: true`) → **inertes, 0 désactivation effective**.
- Aucun durcissement ajouté (pas de very_good_analysis, pas de `--fatal-infos`) — conforme au
  périmètre figé de l'US.

## Gates (T3/T4 — AC-1/AC-2)

```
$ python scripts/run_gates.py --gate format
Formatted 2 files (0 changed) in 0.03 seconds.
✅ app.format   (exit 0 — aucun fichier de lib/test à reformater)

$ python scripts/run_gates.py --gate analyze
No issues found! (ran in 10.8s)
✅ app.analyze  (exit 0 — 0 error/warning/info)
```

## Revue AC-3 (T5 — contrôle manuel @CodeReviewer, pas un gate auto)

`grep -rnE "// ?ignore(_for_file)?:" lib test` → **aucune directive de suppression**. Aucune règle de
lint désactivée localement. AC-3 satisfait (0 désactivation effective, 0 suppression non justifiée).

> Rappel (Story File §Risques) : l'AC-3 n'est **pas** couvert par un gate automatisé — son enforcement
> est cette revue manuelle. Le « gate qualité échoue » du scénario Gherkin 4 se lit « le contrôle de
> revue échoue ».

## Reproductibilité (T7 — AC-4)

`python scripts/run_gates.py --component app` en local == job CI `app-quality` (même commandes issues
de `factory.config.json`, Flutter 3.44.7). Vérifié vert sur la PR de l'US.

## Synthèse

AC-1 (format), AC-2 (analyze), AC-3 (0 désactivation), AC-4 (reproductibilité) : **tous satisfaits**
par validation de l'existant. Aucun code modifié, aucune régression.
