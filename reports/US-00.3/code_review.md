# Code Review — US-00.3 · Migrations réversibles

- **Auditeur** : @CodeReviewer (contexte frais, sans accès à la conversation de production)
- **Modèle** : claude-opus-4-8
- **Date** : 2026-07-26
- **Branche** : `feat/US-00.3-migrations-reversibles` (HEAD)
- **Nature** : US de plateforme / convention **agnostique de la techno** — aucun code Dart compilé,
  aucun schéma concret (choix de persistance reporté à US-01.2 + ADR). L'enforcement d'AC-4 au
  Sprint 0 est une **revue de conformité**, pas une exécution automatisée (celle-ci incombe à US-01.2).

## Verdict : ✅ PASSED

- **Bloquants (FAILED)** : 0
- **Suggestions d'amélioration** : 2 (non bloquantes)

---

## Périmètre du diff (commande + sortie)

```
$ git diff main...HEAD --stat
 PROJECT_LOG.md                                     |   3 +
 STORY_CERTIFICATION_BOARD.md                       |  12 +-
 .../ADR-005-convention-migrations-reversibles.md   |  60 ++++++++++
 docs/architecture/MIGRATIONS.md                    | 133 +++++++++++++++++++++
 docs/trace/US-00.3/events.jsonl                    |   5 +
 reports/US-00.3/README.md                          |  38 ++++++
 6 files changed, 247 insertions(+), 4 deletions(-)
```

```
$ git diff main...HEAD --name-only
PROJECT_LOG.md
STORY_CERTIFICATION_BOARD.md
docs/adr/ADR-005-convention-migrations-reversibles.md
docs/architecture/MIGRATIONS.md
docs/trace/US-00.3/events.jsonl
reports/US-00.3/README.md
```

→ Aucun fichier d'enforcement modifié : ni `factory.config.json`, ni `scripts/*`, ni `.github/*`,
ni `.claude/hooks/*` n'apparaît dans le diff. Contrainte architecturale (Art. 6) respectée.

*Note* : `tests/features/US-00.3-migrations-reversibles.feature` (6 scénarios) est **présent** sur
le disque mais absent du diff `main...HEAD` car déjà mergé sur `main` à la phase « définition »
(commit `bd4353f Merge US-00.3 (définition)`). Il a été relu pour vérifier la couverture (ci-dessous).

## Gate statique — analyze (commande + sortie)

```
$ python scripts/run_gates.py --gate analyze
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 17.9s)
✅ app.analyze
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).
```

→ Vert. Le canevas Dart de `MIGRATIONS.md §4` est en bloc de code markdown (pas un `.dart`
compilé) → aucun impact sur l'analyse statique, conforme à la limite Sprint 0.

*Gates non applicables* : `lint`/`typecheck` au sens front/back n'ont pas d'équivalent distinct de
`analyze` sur cette stack Flutter (source unique : `flutter analyze` via `run_gates.py`). Aucun
code Dart nouveau → pas de dette de test compilé.

## Vérification de la numérotation ADR (commande + sortie)

```
$ ls docs/adr/
ADR-005-convention-migrations-reversibles.md
ADR_TEMPLATE.md
```

→ Seul `ADR-005` (+ template) présent sur la branche. Numéro **sans collision** : ADR-001 réservé
au stack (US-00.5, non fait), ADR-002..004 pressentis pour US-01.1. Choix documenté dans l'ADR
(Conséquences) et cohérent avec le risque cross-branche signalé au Story File.

## Référence `EVT_WAIVER_GRANTED` (commande + sortie)

```
$ grep -o "EVT_WAIVER_GRANTED" scripts/events_catalog.json
EVT_WAIVER_GRANTED
```

→ L'événement de dérogation cité par `MIGRATIONS.md §3` et `ADR-005 §Décision` existe réellement
au catalogue : la référence n'est pas pendante.

---

## Revue de conformité par AC

| AC | Exigence | Emplacement | Constat |
|---|---|---|---|
| **AC-1** | Versionnement entier monotone (`v0`=aucun schéma), `+1` par changement, couple `up`/`down` obligatoire, cas de base `v0→v1` | `MIGRATIONS.md §1` | ✅ Conforme. Entier monotone + `v0`=absence de schéma ; stockage version délégué au mécanisme (reporté US-01.2) ; incrément de exactement 1 ; couple up/down obligatoire ; non-conformité (up sans down / sans incrément) explicitée ; cas de base `v0→v1` documenté (down légitime car n'annule que sa propre création). |
| **AC-2** | Invariant aller-retour `up` puis `down` = état équivalent ; rejet des `down` non conformes ; limite transformation non réversible → préservation | `MIGRATIONS.md §2` | ✅ Conforme. Invariant formalisé (schéma diagrammé + « fonctionnellement équivalent ») ; deux critères (pas de structure orpheline, pas de perte au-delà du delta) ; violation = rejet ; limite « suppression de colonne porteuse » → stratégie de préservation documentée, renvoi au §3. |
| **AC-3** | Additif par défaut (RF-21) + destructif interdit sauf exception encadrée (préservation documentée **+** validation humaine tracée) | `MIGRATIONS.md §3` | ✅ Conforme. Additif par défaut (naturellement réversible, RF-21) ; définition du destructif ; interdiction par défaut + blocage en revue ; exception **cumulative** (préservation + waiver `EVT_WAIVER_GRANTED` tracé + invariant §2 préservé) ; « exception, jamais la norme ». |
| **AC-4** | Patron round-trip réutilisable `seed→up→assert@N→down→assert@N-1`, documenté comme canevas à instancier par US-01.2 | `MIGRATIONS.md §4` | ✅ Conforme. Patron textuel 5 étapes (seed avec lignes non concernées pour détecter les pertes collatérales) + esquisse Dart `assertMigrationRoundTrip(n)` en bloc de code, explicitement « à instancier par US-01.2 » ; limite Sprint 0 énoncée (canevas documenté, exécution réelle en US-01.2). |
| **Agnosticisme** | Aucun package présupposé ; choix reporté à US-01.2 | `MIGRATIONS.md §5` | ✅ Conforme. `sqflite`/`drift`/`isar`/`hive` explicitement non présupposés ; convention exprimée en version/up/down/round-trip ; report du choix à US-01.2 + ADR (renvoi `STACK_PROFILE.md §DataEngineer`). |
| **ADR-005** | Présent, Accepté, sections Contexte/Décision/Alternatives/Conséquences, cohérent, sans collision | `docs/adr/ADR-005-*.md` | ✅ Conforme. Statut **Accepté** ; 4 sections présentes ; 3 alternatives argumentées (rien formaliser / choisir techno maintenant / forward-only) ; conséquences positif/coût/dette ; cohérent avec la convention ; numéro sans collision (vérifié ci-dessus). |
| **Gherkin** | 6 scénarios couverts par la convention | `tests/features/US-00.3-*.feature` | ✅ Conforme. Sc.1→§1, Sc.2→§2, Sc.3→§2 (violation/rejet), Sc.4→§3 (additif), Sc.5→§3 (destructif bloqué + condition d'aboutissement), Sc.6→§4 (patron prêt pour US-01.2). Chaque scénario a un pendant textuel dans la convention. |
| **Non-régression** | analyze vert, aucun fichier d'enforcement touché | diff --stat / run_gates | ✅ Conforme (voir sorties ci-dessus). |

---

## Findings

### Bloquants (FAILED) — aucun

Aucune erreur d'analyse statique, aucune duplication manifeste, aucun N+1 (pas de code exécuté),
aucun AC non couvert, aucun code nouveau sans test (aucun code Dart compilé n'est produit — AC-4
limite Sprint 0 respectée). Rien ne justifie un FAILED.

### Suggestions d'amélioration (non bloquantes)

- `[docs/architecture/MIGRATIONS.md:100]` | L'assertion `expect(await snapshotSchema(), before)`
  suppose une comparaison de snapshots déterministe/normalisée. | Recommander à US-01.2, lors de
  l'instanciation réelle, de normaliser le snapshot (ordre des colonnes/index) pour éviter des
  faux négatifs de round-trip. Note pour la future US, non bloquant pour la convention.
- `[docs/architecture/MIGRATIONS.md:64]` | La convention cite `EVT_WAIVER_GRANTED` comme trace de
  la validation humaine du destructif encadré. | Vérifié : l'événement existe au catalogue. À la
  première application (US-01.2), s'assurer que la machine à états autorise sa transition dans le
  contexte migration. Suivi US-01.2, non bloquant.

---

## Conclusion

La convention `MIGRATIONS.md`, l'`ADR-005` (Accepté) et le rapport de preuves `reports/US-00.3/README.md`
couvrent **intégralement** AC-1→AC-4, sont **agnostiques de la techno** avec report explicite du choix
à US-01.2, et sont **cohérents avec les 6 scénarios Gherkin**. Le gate `analyze` est vert et **aucun
fichier d'enforcement n'est modifié**. Les deux suggestions relèvent de l'instanciation future par
US-01.2 et ne conditionnent pas la validité de la convention.

**Verdict : PASSED.**
