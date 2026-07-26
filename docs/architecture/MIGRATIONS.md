# Convention de migrations de schéma local réversibles

> **US-00.3 — Fondation (EPIC_00).** Convention **agnostique de la techno** de persistance, établie
> **avant** l'apparition du premier schéma. Elle est *appliquée* et son patron de test *instancié* par
> **US-01.2** (première persistance). Décision structurante : [`ADR-005`](../adr/ADR-005-convention-migrations-reversibles.md).
>
> **Portée** : Concentration est **offline-first** (RNF-01/07) — toutes les données vivent localement
> sur l'appareil. Toute évolution du modèle (nouveau champ, futur module Respiration/Concentration —
> RF-21) doit migrer les données locales **sans perte** et **de façon réversible**.

---

## 1. Versionnement de schéma (AC-1)

- La base locale porte un **numéro de version de schéma entier, monotone croissant** : `v0` = **aucun
  schéma** (application fraîchement installée, avant toute persistance).
- Cette version est **stockée par le mécanisme de persistance lui-même** (p. ex. `PRAGMA user_version`
  pour SQLite, ou l'équivalent du package retenu — le mécanisme concret est **reporté à US-01.2 + ADR**,
  cf. `STACK_PROFILE.md §DataEngineer`).
- **Règle** : tout changement de schéma **incrémente la version de exactement 1** et fournit un
  **couple de migrations** :
  - `up(N-1 → N)` : applique le changement en montant d'une version ;
  - `down(N → N-1)` : annule exactement ce changement en redescendant d'une version.
- **Non-conformité (revue @CodeReviewer/@QA)** : un changement de schéma **sans incrément**, ou un `up`
  **sans** `down` (ou l'inverse).
- **Cas de base (limite)** : la première migration `v0 → v1` (introduite par US-01.2) a un `up` de
  **création** du schéma initial ; son `down` **ramène à v0** (« aucun schéma ») en supprimant ce qui a
  été créé par ce même `up` — c'est le seul `down` dont la suppression est légitime (il n'annule que sa
  propre création, aucune donnée utilisateur préexistante n'est perdue).

## 2. Contrat de réversibilité aller-retour (AC-2)

**Invariant (non négociable)** : pour toute version `N`, l'enchaînement

```
état@(N-1)  --up-->  état@N  --down-->  état@(N-1)'
```

doit produire un `état@(N-1)'` **fonctionnellement équivalent** à `état@(N-1)` :

- même structure de schéma (aucune table/colonne/index résiduel introduit par `up` et non retiré par `down`) ;
- aucune corruption ni perte des données **non concernées** par la migration.

- **Violation (rejet)** : un `down` qui ne restaure pas l'état antérieur — structures orphelines, ou
  perte de données **au-delà du delta** réellement migré.
- **Limite — transformation intrinsèquement non réversible** (p. ex. suppression d'une colonne porteuse
  de données) : interdite « en l'état » ; elle exige une **stratégie de préservation documentée**
  (archivage / mise de côté de la donnée avant suppression, permettant au `down` de la restaurer) —
  jamais de perte silencieuse. À défaut, relève du §3 (destructif encadré).

## 3. Interdiction de migration destructive par défaut (AC-3, RF-21)

- **Par défaut, les migrations sont ADDITIVES** : ajout de table, de colonne (avec valeur par défaut ou
  nullable), d'index. Les évolutions pour les futurs modules (Respiration, Concentration — extensibilité
  RF-21) sont additives **donc naturellement réversibles** (le `down` retire ce que le `up` a ajouté).
- Est **destructive** toute migration comportant un `DROP`/suppression ou un changement **non additif**
  entraînant une **perte de donnée utilisateur** (drop de table/colonne peuplée, changement de type
  lossy, fusion/écrasement).
- **Interdiction par défaut** : une migration destructive **sans** stratégie de préservation **ni**
  justification documentée est **bloquée en revue**.
- **Exception encadrée (limite)** : une migration destructive réellement nécessaire n'est admise
  qu'avec, cumulativement :
  1. une **étape de préservation** documentée (sauvegarde/archivage de la donnée impactée, restituable par le `down`) ;
  2. une **validation humaine explicite tracée** (événement de dérogation `EVT_WAIVER_GRANTED` ou visa humain équivalent) ;
  3. l'invariant d'aller-retour (§2) préservé via la donnée archivée.
  Le geste reste **l'exception, jamais la norme**.

## 4. Patron de test de migration réversible (AC-4)

Toute migration se fusionne **avec** son test aller-retour. Patron réutilisable, agnostique de la techno :

```text
Test « round-trip » pour la migration vers la version N :
  1. seed        : préparer une base à l'état v=(N-1) avec un jeu de données représentatif
                   (dont des lignes NON concernées par la migration, pour détecter les pertes collatérales).
  2. up          : exécuter up(N-1 → N).
  3. assert @N   : vérifier le schéma cible v=N (tables/colonnes/index attendus) ET l'intégrité
                   des données migrées + non concernées.
  4. down        : exécuter down(N → N-1).
  5. assert @N-1 : vérifier que le schéma ET les données sont fonctionnellement équivalents à l'étape 1
                   (invariant §2). Aucune structure orpheline, aucune perte au-delà du delta.
```

Esquisse Dart (canevas — **à instancier réellement par US-01.2**, quand la techno et le premier schéma
existeront ; aucun schéma concret n'existe au Sprint 0) :

```dart
// À instancier par US-01.2 avec le mécanisme de persistance retenu (ADR à venir).
// db, applyUp, applyDown, readSchemaVersion, snapshotSchema sont fournis par cette techno.
Future<void> assertMigrationRoundTrip(int n) async {
  await seedAt(n - 1);                       // 1. état v=(N-1) + données représentatives
  final before = await snapshotSchema();

  await applyUp(n);                          // 2. up(N-1 -> N)
  expect(await readSchemaVersion(), n);      // 3. assert @N (schéma + intégrité données)
  await assertDataIntegrityAt(n);

  await applyDown(n);                        // 4. down(N -> N-1)
  expect(await readSchemaVersion(), n - 1);  // 5. assert @N-1 (invariant round-trip)
  expect(await snapshotSchema(), before);    //    schéma fonctionnellement équivalent
}
```

- **Non-conformité** : une migration fusionnée **sans** son test aller-retour.
- **Limite Sprint 0** : aucun schéma concret n'existe (techno reportée à US-01.2) → ce patron est ici
  **documenté et validé en tant que canevas** ; son **exécution réelle** sur une migration concrète
  incombe à **US-01.2**.

## 5. Agnosticisme techno & point d'application

- La convention ne présuppose **ni** `sqflite`, `drift`, `isar`, `hive`, ni aucun autre package : elle
  s'exprime uniquement en termes de **version / up / down / round-trip**, applicables à n'importe quel
  mécanisme. Le **choix du mécanisme** est délibérément **reporté à US-01.2 + ADR** (`STACK_PROFILE.md
  §DataEngineer`).
- **Point d'application (T4)** : **US-01.2 — Gestion des événements / persistance** introduit le premier
  schéma (entité *Échéance*), **applique** cette convention (migration `v0 → v1` avec `up`/`down`) et
  **instancie** le patron de test §4 sur cette première migration réelle. La convention n'est réputée
  « appliquée et prouvée » qu'à ce moment-là.

## 6. Checklist de conformité (revue @CodeReviewer / @QA)

Pour toute future migration :

- [ ] Version de schéma **incrémentée de 1** (monotone).
- [ ] Couple `up` **et** `down` fournis.
- [ ] Invariant aller-retour (§2) respecté — vérifié par le test round-trip (§4).
- [ ] Migration **additive** ; si destructive → préservation documentée **+** validation humaine tracée (§3).
- [ ] Test aller-retour présent et vert (à partir d'US-01.2).

---

**Références** : PRD (RNF-01/07 offline-first, RF-21 extensibilité) · `docs/governance/STACK_PROFILE.md §DataEngineer` ·
[`ADR-005`](../adr/ADR-005-convention-migrations-reversibles.md) · Story File `docs/stories/US-00.3-migrations-reversibles.md`.
