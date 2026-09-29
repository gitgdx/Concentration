# Convention de migrations de schéma local réversibles

> **US-00.3 — Fondation (EPIC_00).** Convention **agnostique de la techno** de persistance, établie
> **avant** l'apparition du premier schéma. Elle est *appliquée* et son patron de test *instancié* par
> **US-01.2** (première persistance). Décision structurante : [`ADR-005`](../adr/ADR-005-convention-migrations-reversibles.md).
>
> **Portée** : Concentration est **offline-first** (RNF-01/07) — toutes les données vivent localement
> sur l'appareil. Toute évolution du modèle (nouveau champ, futur module Respiration/Concentration —
> RF-21) doit migrer les données locales **sans perte** et **de façon réversible**.

> ⚖️ **AMENDÉ le 2026-08-24 — @DataEngineer, branche `data_design` d'US-01.4** *(track FULL,
> `parallel_design`)*, sous [ADR-012](../adr/ADR-012-etat-echue-retiree-persistance-migration-v3.md)
> *(accepté, donc **immuable** : ⛔ aucune de ses décisions n'est rouverte ici)*.
> **Ce qui est amendé, et rien d'autre** : le **§1** *(deux étapes contiguës, et le couple exige **deux
> fonctions distinctes** — mesuré)*, le **§2** *(ce que « fonctionnellement équivalent » signifie pour
> un magasin **document**, et le sens qui manquait)*, le **§3** *(la migration qui ne transforme **rien**
> est additive — et la forme « explicite partout » **fabrique** le `down` destructif)*, le **§4**
> *(🔴 **la graine du patron doit contenir une instance de ce dont la migration parle** — établi par
> **mutation**, pas par raisonnement)* et la **checklist du §6**.
> ⛔ **On date, on ne repeint pas** : chaque texte antérieur reste visible et marqué ; le nouvel énoncé
> est ajouté **au-dessous**.

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
  ⛔ **PÉRIMÉ-2026-08-06 pour ce projet, et la ligne reste** : **aucune étape `v0 → v1` n'existe** —
  déviation **assumée et datée** au §4 de [`SCHEMA_STOCKAGE_ECHEANCES.md`](SCHEMA_STOCKAGE_ECHEANCES.md)
  et dans le module lui-même. **Rien n'est repeint** : la règle générale reste juste pour un magasin qui
  a un DDL ; elle n'a **pas d'objet** pour un magasin document.

> ⚖️ **AJOUT DATÉ-2026-08-24 (US-01.4) — la chaîne compte désormais DEUX étapes, et deux choses que
> personne ne devrait re-découvrir.**
>
> **① La contiguïté se VÉRIFIE PAR LE CALCUL, jamais par confiance.** Le critère de sortie exige
> `versions[i] == versionCourante - versions.length + 1 + i` pour tout `i`, **et**
> `versions.last == versionCourante`. Avec `versionCourante = 3` et `[Étape(2), Étape(3)]` ⇒ `len = 2` :
> `i = 0` → `3 − 2 + 1 + 0 = 2` ✅ · `i = 1` → `3 − 2 + 1 + 1 = 3` ✅ · `last = 3` ✅.
> ⛔ **Et ce n'est pas resté un calcul** : le mutant *« `versionCourante` bumpé **sans** son étape »* a
> été **exécuté** et rend **7 des 8 assertions du critère ROUGES**. ⇒ **ce mutant-là est déjà couvert,
> il ne doit PAS être testé une seconde fois** *(« une règle n'existe qu'en un seul exemplaire »)*.
>
> **② 🔴 Le couple exige DEUX FONCTIONS DISTINCTES, et c'est une contrainte de LANGAGE, pas de style.**
> **Mesuré** *(Dart 3.12.2)* : les tear-offs d'une fonction de premier niveau sont **canonicalisés** dans
> une liste `const` ⇒ `EtapeMigration(3, _identite, _identite)` rend `identical(up, down)` **vrai**, et
> l'assertion `A1` du critère **ROUGIT**. ⇒ ⛔ **une étape « identité » ne se code JAMAIS avec une seule
> fonction partagée** : il en faut **deux**, nommées par leur sens *(`_v2VersV3`, `_v3VersV2`)*.
> ⚠️ **Et il faut dire ce que cette assertion NE prouve pas** : deux fonctions **identiques en effet**
> la satisfont *(mesuré : la source conforme passe, et trois mutants destructeurs aussi — §4)*.
> **`A1` atteste une PRÉSENCE, ⛔ jamais une CORRECTION.**

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

> ⚖️ **AJOUT DATÉ-2026-08-24 (US-01.4) — deux précisions, et la seconde est un TROU de cet énoncé.**
>
> **① Pour un magasin DOCUMENT, « fonctionnellement équivalent » se durcit en « ÉGAL AUX OCTETS ».**
> Le §2 ci-dessus est écrit pour un schéma à structures *(tables, colonnes, index)*, où « équivalent »
> est le seul critère praticable. Ici il n'y a **ni DDL ni structure** : il n'y a qu'**un texte JSON**.
> ⇒ le critère praticable **le plus fort** est disponible, donc c'est lui qui s'applique :
> `jsonEncode(down(up(doc))) == jsonEncode(doc)`. ⛔ **Ne jamais retomber sur « équivalent » quand
> « identique » est mesurable** : c'est la porte par laquelle un octet se perd sans qu'aucune assertion
> ne rougisse.
>
> **② 🔴 CE §2 NE PARLE QUE D'UN SEUL SENS — `up` puis `down` — et l'autre sens existe.** Un document
> **redescendu** *(rollback d'une mise à jour défaillante, exactement le cas pour lequel ADR-005 a refusé
> le « forward-only »)* est ensuite **remonté** par le binaire suivant. **L'invariant à tenir est donc
> DOUBLE** : `down ∘ up = identité` **et** `up ∘ down = identité`, chacun sur les octets.
> ⛔ **Ce n'est pas une symétrie gratuite, et c'est mesuré** : sur le couple `v2 ⇄ v3`, un `up` qui
> « **nettoierait** » une clé que la version basse ne connaît pas est **invisible** au premier sens
> *(le document de départ n'a pas la clé)* et **détruit la donnée** au second *(le document redescendu
> l'a)*. **C'est l'assertion `B3` du §8 de [`SCHEMA_STOCKAGE_ECHEANCES.md`](SCHEMA_STOCKAGE_ECHEANCES.md)
> qui le tue, et elle seule.**

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

> ⚖️ **AJOUT DATÉ-2026-08-24 (US-01.4) — ce que « additif » veut dire quand il n'y a pas de colonne, et
> le piège qui se cache dans le mot « explicite ».**
>
> **① La forme la plus additive qui existe est la transformation VIDE.** L'étape `v2 → v3` **ne touche
> aucune entrée** : ce qui change est la **grammaire** *(une clé reconnue de plus, **optionnelle**)*, pas
> la donnée. ⇒ **aucun `DROP`, aucun changement de type, aucune fusion, aucune écriture** sur une entrée
> existante ⇒ ⛔ **elle n'est destructive à aucun titre du §3**, et **aucune `EVT_WAIVER_GRANTED` n'est
> demandée**. **Mesuré sur un document du parc** *(9 entrées, aucune clé `retiree`)* —
> `python reports/US-01.4/migration_v3_guard_criterion.py --parc` : **1149 octets avant, 1149 après**,
> **préfixe commun 17**, **suffixe commun 1131** ⇒ **la totalité de l'effet du `up`
> est un caractère : `2` → `3`**. C'est ce qui rend *« aucune tuile ne disparaît sans geste »*
> **falsifiable sur les octets**, pas seulement sur un décompte de tuiles.
>
> **② 🔴 Le piège : une migration « explicite partout » FABRIQUE le `down` destructif qu'on vient
> d'interdire.** Écrire la nouvelle clé **sur chaque entrée** au `up` *(la variante qui « ne laisse rien
> d'implicite »)* oblige son `down` à **retirer la clé** pour restaurer l'état antérieur — donc à
> **détruire** une valeur préexistante. ⛔ **Le §3 ne le voit pas** : rien n'est droppé, aucun type ne
> change, la migration **a l'air additive**. **Mesuré** : ce mutant **passe** le critère de sortie
> d'US-01.2 *(8/8 vertes)* et fait **rougir 8 assertions sur 8** de la garde dédiée.
> ⇒ **Règle générale, à opposer à l'intuition** : **la clé optionnelle absente est préférable à la clé
> explicite**, parce qu'elle est la seule forme dont le `down` n'a **rien** à retirer.

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

> 🔴 **AMENDEMENT DATÉ-2026-08-24 (US-01.4) — L'ÉTAPE 1 DU PATRON EST INCOMPLÈTE, ET LE PROJET L'A PAYÉ
> AVANT DE LE VOIR.** ⛔ **L'étape 1 ci-dessus n'est PAS repeinte** : elle demande *« un jeu de données
> représentatif, **dont des lignes NON concernées** par la migration, pour détecter les pertes
> collatérales »*. **C'est juste, et insuffisant** — elle demande la moitié éloignée du delta et **oublie
> le delta lui-même**.
>
> **➡️ CLAUSE AJOUTÉE, non négociable** : la graine doit contenir **au moins une instance de la donnée
> dont la migration PARLE**, dans **chaque forme** que sa grammaire déclare *(pour une clé optionnelle
> booléenne : **présente à `true`**, **présente à `false`**, **absente**, et **présente hors domaine**)*.
> ⛔ **Une graine qui ne porte pas la donnée du delta ne peut pas observer sa destruction** — ce n'est pas
> une faiblesse d'assertion, c'est une **impossibilité logique**.
>
> **La mesure qui l'établit, et elle se REJOUE — ⛔ elle ne se croit pas sur parole** :
>
> ```
> python reports/US-01.4/migration_v3_guard_criterion.py --croise
> ```
>
> Sept sources Dart, chacune **un seul** comportement changé, jugées par **deux** instruments *(verdicts
> comparés en **ENSEMBLES**, ⛔ jamais en cardinaux ; toute source **identique** à la conforme est refusée
> par un contrôle négatif)*. **La table ci-dessous est une transcription de cette sortie ; en cas de
> désaccord, c'est la COMMANDE qui fait foi.**
>
> | Mutant *(comportemental)* | Critère de sortie d'US-01.2 *(graine **sans** la clé)* | Garde dédiée *(graine **avec** la clé)* |
> |---|---|---|
> | le `down` **retire** la clé | ✅ **8/8 VERTES — il ne voit rien** | ❌ **6 assertions rouges** |
> | le `down` ne « nettoie » que les `false` | ✅ **8/8 VERTES** | ❌ **3 assertions rouges** |
> | le `up` écrit la clé **partout** | ✅ **8/8 VERTES** | ❌ **8 assertions rouges** |
> | le `up` **retire** la clé *(« la version basse ne la connaît pas »)* | ✅ **8/8 VERTES** | ❌ **5 assertions rouges** |
> | `versionCourante` bumpé **sans** son étape | ❌ **7 rouges** | ❌ 8 rouges |
> | `up`/`down` **recomposent** l'entrée | ❌ **2 rouges** *(`A3`, `A5`)* | ❌ 5 rouges |
> | `up` et `down` = **une seule** fonction partagée | ❌ **1 rouge** *(`A1`)* | ✅ **VERTE — elle ne voit rien** |
>
> **Trois conclusions, et aucune n'était devinable** :
> **⓵ QUATRE mutants destructeurs sur sept passent un patron aller-retour parfaitement vert.** Le patron
> **n'était pas faux** — sa **graine** ne portait pas la donnée. ⇒ ⛔ **un aller-retour vert n'atteste
> jamais plus que ce que sa graine contient.**
> **⓶ Les deux instruments ne sont PAS redondants, et c'est mesuré dans les DEUX SENS** : le dernier
> mutant meurt **uniquement** sur le critère *(`A1`)*, les quatre premiers **uniquement** sur la garde.
> ⇒ **on garde les deux, et on ne duplique aucune de leurs assertions.**
> **⓷ Le mutant le plus dangereux est celui qui a l'air le plus propre** — *« redescendre proprement en
> retirant la clé »* : il **détruit** l'information, et **aucun** des huit contrôles du critère ne bouge.



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
  ⚖️ **DATÉ-2026-08-24** : la migration livrée par US-01.2 est **`v1 ⇄ v2`**, ⛔ **pas `v0 → v1`** *(voir
  la déviation datée du §1)*. **US-01.4 produit la DEUXIÈME étape réelle du projet** — `v2 ⇄ v3`, sous
  [ADR-012](../adr/ADR-012-etat-echue-retiree-persistance-migration-v3.md) — et c'est **elle** qui a
  révélé les quatre trous du patron amendés ci-dessus. ⚠️ **Ce que cette convention n'a toujours JAMAIS
  eu** : **aucun gate CI** ne l'applique. Le critère de sortie exige le SDK Dart et se lance **à la
  main** ; les assertions de la garde vivent, elles, dans `flutter test`, qui **est** un gate requis.
  ⇒ ⛔ **la moitié de cette convention repose sur une commande qu'un humain doit penser à taper.**

## 6. Checklist de conformité (revue @CodeReviewer / @QA)

Pour toute future migration :

- [ ] Version de schéma **incrémentée de 1** (monotone).
- [ ] Couple `up` **et** `down` fournis.
- [ ] Invariant aller-retour (§2) respecté — vérifié par le test round-trip (§4).
- [ ] Migration **additive** ; si destructive → préservation documentée **+** validation humaine tracée (§3).
- [ ] Test aller-retour présent et vert (à partir d'US-01.2).

**⚖️ AJOUTÉ le 2026-08-24 (US-01.4) — cinq cases dont AUCUNE n'est cochable sur relecture** *(chacune
nomme la commande ou l'assertion qui la produit ; ⛔ un résultat se **lit**, il ne s'affirme pas)* :

- [ ] La **graine** du test aller-retour porte **une instance de la donnée du delta**, dans **chaque
      forme** de sa grammaire *(§4 amendé)*. **Réfutation** : la graine ne contient pas le nom de la clé
      introduite par la migration.
- [ ] L'aller-retour est asserté **dans les DEUX SENS** — `down ∘ up` **et** `up ∘ down` *(§2 amendé)*.
- [ ] `up` et `down` sont **deux fonctions distinctes** *(§1 amendé — une seule fonction partagée fait
      rougir `A1`, mesuré)*, **et** ⛔ le fait qu'elles diffèrent **n'est pas compté comme une preuve de
      correction**.
- [ ] Le test aller-retour porte **ses mutants**, et les verdicts sont comparés **en ENSEMBLES**. ⛔ Un
      mutant dont la source est **identique** à la source conforme est **refusé** *(contrôle négatif)*.
- [ ] Si un instrument existant est **conservé comme non-régression**, son fichier est **bit-à-bit
      inchangé** — `git diff` **vide** sur lui. *(Motif : « c'est le fait de ne pas l'avoir touché qui
      rendait sa mesure croyable ».)*

---

**Références** : PRD (RNF-01/07 offline-first, RF-21 extensibilité) · `docs/governance/STACK_PROFILE.md §DataEngineer` ·
[`ADR-005`](../adr/ADR-005-convention-migrations-reversibles.md) · Story File `docs/stories/US-00.3-migrations-reversibles.md`.
**Ajoutées le 2026-08-24** : [`SCHEMA_STOCKAGE_ECHEANCES.md`](SCHEMA_STOCKAGE_ECHEANCES.md) §4 et §8
*(l'instanciation réelle : table des versions, sémantique de chaque étape, garde, campagne de mutants)* ·
[ADR-009](../adr/ADR-009-stockage-local-document-json-versionne.md) *(le magasin document — **nommé, jamais
édité** : son constat d'aller-retour « exact dans un fuseau donné » est **contredit par la mesure**)* ·
[ADR-012](../adr/ADR-012-etat-echue-retiree-persistance-migration-v3.md) *(l'étape `v2 ⇄ v3`)*.
