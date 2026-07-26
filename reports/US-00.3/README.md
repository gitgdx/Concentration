# Preuves — US-00.3 · Migrations réversibles

US de **plateforme / convention** (agnostique de la techno). Branche : `feat/US-00.3-migrations-reversibles`.
Aucun schéma concret au Sprint 0 (choix de persistance reporté à US-01.2 + ADR) → l'enforcement est une
**revue de conformité** de la convention (comme l'AC-3 de US-00.2), l'exécution automatisée du round-trip
incombant à US-01.2.

## Livrables (T1–T5)

| Tâche | Description | Statut | Livrable |
|---|---|---|---|
| **T1** | Convention de migrations réversibles | ✅ | [`docs/architecture/MIGRATIONS.md`](../../docs/architecture/MIGRATIONS.md) |
| **T2** | ADR de décision | ✅ | [`docs/adr/ADR-005-convention-migrations-reversibles.md`](../../docs/adr/ADR-005-convention-migrations-reversibles.md) (Accepté) |
| **T3** | Patron de test aller-retour réutilisable | ✅ | `MIGRATIONS.md §4` (canevas + esquisse Dart, à instancier par US-01.2) |
| **T4** | Point d'application documenté | ✅ | `MIGRATIONS.md §5` (US-01.2 applique + instancie) |
| **T5** | Revue de conformité + preuves | ✅ | ce fichier |

## Auto-revue de conformité (AC-1 → AC-4)

| AC | Exigence | Couverture dans `MIGRATIONS.md` |
|---|---|---|
| **AC-1** | Versionnement monotone + couple up/down | §1 : entier monotone, `v0`=aucun schéma, `+1` par changement, `up`/`down` obligatoires, cas de base `v0→v1` |
| **AC-2** | Invariant aller-retour up→down | §2 : invariant explicite, rejet des `down` non conformes, limite « transformation non réversible » → préservation |
| **AC-3** | Additif par défaut, destructif interdit sauf exception encadrée | §3 : additif RF-21 par défaut ; destructif bloqué sauf préservation **+** validation humaine tracée (`EVT_WAIVER_GRANTED`) |
| **AC-4** | Patron de test round-trip réutilisable | §4 : canevas `seed→up→assert@N→down→assert@N-1` + esquisse Dart, instanciation par US-01.2 |

## Non-régression

- `docs/architecture/MIGRATIONS.md` et l'ADR sont des documents `.md` — le canevas Dart y est en **bloc
  de code** (pas un fichier `.dart` compilé) → **aucun impact sur `flutter analyze`**.
- Aucun fichier d'enforcement (`factory.config.json`, `scripts/*`, `.github/*`, `.claude/hooks/*`) modifié.
- `python scripts/run_gates.py --gate analyze` reste vert (voir QA).

## Périmètre / limites (explicites)

- **Aucun schéma concret**, aucun package de persistance sélectionné (reporté à US-01.2 + ADR).
- AC-4 : le patron est **documenté et validé en tant que canevas** ; son **exécution réelle** sur une
  migration concrète relève de **US-01.2**. C'est le « si applicable » du backlog rendu explicite.
