# 🏃 Runbook E2E — adapter `flutter`

## Architecture des tests

| Niveau | Outil | Où ça tourne |
|---|---|---|
| Unitaire / widget | `flutter test` + couverture lcov (`scripts/check_flutter_coverage.py`) | racine du repo (`test/`) — job CI `app-quality` |
| Analyse statique | `dart format`, `flutter analyze` | job CI `app-quality` |
| E2E (smoke) | ré-exécution des gates (`run_gates.py --component app`) | `.github/workflows/e2e.yml` (nightly + manuel) |

Le smoke test E2E livré avec l'adapter vérifie seulement que l'application s'analyse, se teste et
se construit (`flutter build web`) sans erreur — il n'exerce aucun parcours utilisateur réel. **À
enrichir** dès que l'écran principal (hub de pratiques, grille de tuiles) existe : ajouter le
package `integration_test` (fourni avec le SDK Flutter), des scénarios dans
`integration_test/*.dart`, puis étendre `e2e.yml` pour les exécuter — soit sur Chrome
(`flutter test integration_test --platform=chrome`, rapide, sans émulateur), soit sur émulateur
Android via `reactivecircus/android-emulator-runner` pour un test plus proche du produit réel.

## Lancer localement

```bash
flutter pub get
flutter analyze
flutter test --coverage
flutter build web --release   # preuve de constructibilité (voir STACK_PROFILE.md §DevOps)
```

## Règle de certification (Constitution Art. 3)

Un scénario E2E *skipped* n'est pas un scénario vert. Dès que des scénarios `integration_test`
existent, le rapport `reports/US-XXX/qa.md` doit indiquer le décompte passed/skipped/failed —
jamais seulement « PASS ».
