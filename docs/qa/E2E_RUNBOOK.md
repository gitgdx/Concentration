# 🏃 Runbook E2E — adapter `flutter`

> 🧪 **Ce runbook dit COMMENT LANCER. Il ne dit pas ce qu'un vert atteste.**
> La carte complète des instruments de test du projet — et, pour chacun, ⛔ **ce qu'il ne mesure
> pas** — vit dans [`STRATEGIE_DE_TEST.md`](STRATEGIE_DE_TEST.md).

## Architecture des tests

| Niveau | Outil | Où ça tourne |
|---|---|---|
| Unitaire / widget | `flutter test` + couverture lcov (`scripts/check_flutter_coverage.py`) | racine du repo (`test/`) — job CI `app-quality` |
| Analyse statique | `dart format`, `flutter analyze` | job CI `app-quality` |
| E2E (smoke) | ré-exécution des gates (`run_gates.py --component app`) | `.github/workflows/e2e.yml` (nightly + manuel) |

> ⚖️ **PÉRIMÉ-2026-09-08 SUR UN POINT, ET UN SEUL — le paragraphe ci-dessous est conservé, pas
> repeint.** Il dit *« il n'exerce aucun parcours utilisateur réel »* et *« à enrichir dès que
> l'écran principal existe »*. **L'écran existe depuis US-01.1**, et `test/e2e/` porte **deux
> fichiers qui montent `ConcentrationApp` sur un disque réel** — choix **arbitré par
> [ADR-008](../adr/ADR-008-arbitrages-track-full.md)** *(un test montant l'application entière vaut
> scénario E2E pour une application offline-first sans backend ; `integration_test` était **absent**
> du projet et **aucun appareil ne tourne en CI**, donc la tâche qui l'exigeait était
> **inexécutable**)*. La contrepartie n'est pas facultative : **deux contrôles machine**,
> `check_gherkin_mapping.py` *(scénario ↔ test)* et `check_e2e_persistance.py` *(racine réellement
> montée, aucun magasin factice)*.
>
> ⛔ **CE QUI RESTE VRAI, et qu'il ne faut pas sur-lire** : le smoke d'`e2e.yml` **rejoue les
> gates** *(nightly)*, ⛔ ce n'est **pas** un parcours utilisateur supplémentaire — et `integration_test`
> est **toujours absent**. **On date, on ne repeint pas.**

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
