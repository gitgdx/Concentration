# ADR-012 : Représentation persistante de l'état `ÉCHUE RETIRÉE` et migration `v2 → v3`

- **Date** : 2026-08-22
- **Statut** : Accepté *(2026-08-22 — @Architect, après relecture des §Décision et **rejeu des sondes** : `flutter test` sur les 3 fichiers de sonde ⇒ **10 tests passés**, dont le mutant `SONDE-5b` **TUÉ**. ⚠️ Un ADR accepté est **IMMUABLE**.)*
- **US associée** : US-01.4 (Gestes sur la tuile — RF-06), EPIC_01, track FULL
- **Remplace** : dans **[ADR-010](ADR-010-clauses-track-full-avec-persistance.md) §2**, sous
  *« Ce qui NE change PAS, et qu'il serait faux d'étendre »*, **la seule puce qui reconduit l'invariant
  `I-7`** — et **uniquement pour le champ qui porte l'état `ÉCHUE RETIRÉE`**. ⛔ **Rien d'autre
  d'ADR-010 n'est touché** : sa décision nº 1 *(E2E : racine montée, magasin réel, assertion sur les
  octets)* et sa décision nº 3 *(la barrière est du code exécuté en release, ⛔ jamais un `assert`)*
  **restent en vigueur et sont APPLIQUÉES par cette US**. Les interdictions de `createdAt`, `dirty` et
  `version` dans l'entité sont **reconduites mot pour mot** ci-dessous.

> **Forme suivie, et elle a deux précédents mesurés dans ce dépôt** : ADR-007 porte
> `Remplace : ADR-006` et **ADR-006 n'a PAS été édité** ; ADR-010 remplace la décision nº 1 d'ADR-008
> et **ADR-008 n'a PAS été édité**. Un ADR accepté est **immuable** : c'est le **remplaçant** qui nomme
> ce qu'il remplace. ⛔ **ADR-010 n'est donc pas modifié.**

## Contexte

### 1 · Le fait produit qui ouvre la décision

US-01.4 introduit un état de **vocabulaire produit** : `ÉCHUE RETIRÉE` — *tuile absente de la grille,
échéance conservée et consultable en gestion*. Il est exigé par **RF-06** et par les **AC-4** et
**AC-5** de cette US, et il doit **survivre à la fermeture de l'application** *(AC-5 : « le retrait est
durable »)*. ⇒ **c'est un fait qui doit être écrit sur le disque.**

### 2 · Un ADR **ACCEPTÉ** dit le contraire, et il est immuable

**Texte en cause, cité verbatim** — ADR-010 §2 :

> *« **I-7** (aucun champ de persistance dans l'entité) **reste vrai** : `schemaVersion` est porté par
> le **DOCUMENT**, pas par `Echeance`. ⛔ Ni `createdAt`, ni `dirty`, ni **`deletedAt`**, ni `version`
> dans l'entité — la modélisation spéculative reste interdite. »*

**Même prohibition, deux autres porteurs** *(documents de design, donc maintenables)* :
`MODELE_ECHEANCE.md` **I-7** *(qui nomme `deletedAt`)* et `SCHEMA_STOCKAGE_ECHEANCES.md` §1, **ligne
3NF** *(« Aucun fait dérivable n'est stocké : ni `estEchue`, ni `RemainingTime`, ni `createdAt`, ni
`dirty`, ni `deletedAt` »)*.

⛔ **Ce que je refuse de faire, et il faut le dire avant d'argumenter** : plaider que `retiree` **n'est
pas littéralement listé** dans l'énumération d'ADR-010. C'est vrai à la lettre, et **ce serait un
raisonnement d'avocat** : `deletedAt` est le nom canonique du **marqueur de retrait logique**, notre
champ **est** ce marqueur, et tout relecteur lirait légitimement la prohibition comme le couvrant.
⇒ **on remplace, on ne contourne pas.**

### 3 · Pourquoi le motif d'`I-7` était **BORNÉ**, et non faux — et sa borne est dans son propre texte

Motif d'`I-7`, cité verbatim depuis `MODELE_ECHEANCE.md` :

> *« Ils n'ont **aucun sens sans stockage** ; les ajouter « pour plus tard » serait de la
> **modélisation spéculative**, et **US-01.2 les introduira avec son ADR**. »*

Deux constats, tous deux **lus dans le texte** et non déduits :

1. **Le motif interdit le SPÉCULATIF, pas le NÉCESSAIRE.** Sa prémisse — *« aucun sens sans
   stockage »* — est **fausse pour ce champ** : il y a désormais un stockage *(ADR-009)*, **et** deux AC
   qui exigent le champ *(AC-4, AC-5)*. On ne réutilise pas un motif dont la prémisse a changé —
   **exactement** l'erreur qu'aurait été de transférer « déploiement = fusion sur `main` » à US-01.1,
   dont la prémisse *(« 0 fichier Dart livré »)* était devenue fausse.
2. **`I-7` a lui-même PRÉVU ce moment** : *« US-01.2 les introduira **avec son ADR** »*. L'US a changé
   *(c'est US-01.4, non US-01.2)*, **la forme prescrite est celle-ci** : un ADR. ⇒ **cet ADR n'est pas
   une entorse à I-7, c'est le mécanisme qu'I-7 désignait.**

**Précision qui tranche la famille, et qui manquait** : l'énumération d'`I-7` mélange **deux natures**.
`dirty`, `version`, `createdAt` sont des **artefacts techniques de persistance** *(drapeau de synchro,
compteur de verrouillage optimiste, horodatage d'audit)* — ils n'ont **effectivement** aucun sens sans
stockage, et **leur interdiction est reconduite ici sans réserve**. `deletedAt`, lui, est un **fait
métier** *(« l'utilisateur a retiré cet objet »)* dont l'usage classique se trouve être la persistance.
**`retiree` est de la seconde nature**, et il a maintenant sa justification **métier** : il figure dans
le **vocabulaire d'état** de l'US, entre `ÉCHUE` et `SUPPRIMÉE`.

### 4 · La ligne 3NF porte un motif **TROP LARGE** — et c'est un défaut, pas une nuance

Elle justifie l'exclusion de `deletedAt` par *« aucun fait **dérivable** n'est stocké »*. Or :

| Fait | Se dérive de | Verdict 3NF |
|---|---|---|
| `estEchue` | `(dateEcheance, Clock)` | ⛔ **Non stockable** — il serait **faux à la seconde suivante**. La ligne 3NF a raison |
| *« le pratiquant a retiré cette tuile »* | **rien** | ✅ **Stockable** : aucune redondance, aucune dérivation possible |

⇒ **la 3NF n'a JAMAIS interdit ce champ** ; `retiree` la **respecte**. C'est **la même classe de défaut
qu'ADR-010 dénonce chez ADR-008** — *une portée annoncée plus large que la portée du motif* — et elle
est ici **nommée**, puis **amendée et datée** dans le document de design, jamais repeinte.

### 5 · L'état du code, **mesuré** *(commandes et fichiers nommés, aucun chiffre de mémoire)*

| Fait | Où il se lit |
|---|---|
| `versionCourante = 2`, une seule étape `EtapeMigration(2, _v1VersV2, _v2VersV1)` | `lib/features/echeances/data/echeance_schema_migrations.dart` |
| Le port compte **quatre** opérations *(`charger`, `creer`, `remplacer`, `supprimer`)* et `ActeEcriture` **deux** valeurs | `lib/features/echeances/domain/echeance_repository.dart` *(son propre commentaire écrit « Le port : quatre opérations »)* |
| Toute écriture passe par **un seul** `_ecrire(acte, muter)` | `lib/features/echeances/data/echeance_document_repository.dart` |
| `_encoderEntree` **copie les clés d'origine AVANT** les clés explicites | `lib/features/echeances/data/echeance_document_codec.dart` |
| Un document de version **supérieure** à `versionCourante` ⇒ **état vide, AUCUNE écriture, document strictement intact** | même fichier, branche `if (version > versionCourante)` ; doctrine au §5 de `SCHEMA_STOCKAGE_ECHEANCES.md` |

### 6 · 🔴 Le critère de sortie d'US-01.2 **NE PEUT PAS** réfuter un `down` destructif — mesuré en le lisant

Deux faits **lus dans `reports/US-01.2/migration_roundtrip_criterion.py`**, pas supposés :

* `A1_contrat_couple` n'exige, sur le couple, que `exige(!identical(e.up, e.down), …)` ⇒ **deux
  fonctions distinctes suffisent, même identiques en effet**.
* La graine `GRAINE_V1` énumère `a1, a2, a3, a4, a6` et une ligne non-objet — ⛔ **aucune entrée ne
  porte de clé `retiree`**. ⇒ `A3_aller_retour`, qui compare `jsonEncode(bas) == jsonEncode(graine())`,
  **ne peut pas observer** la destruction d'une information qui n'est pas dans sa graine.

⇒ **la garde du couple `v2 ⇄ v3` exige son PROPRE test unitaire, portant ses mutants.** Le critère
d'US-01.2 reste néanmoins **exigé, exécuté et bit-à-bit inchangé** — comme **non-régression du couple
`v1 ⇄ v2`**, et parce que *« c'est le fait de ne pas l'avoir touché qui rendait sa mesure croyable »*.

### 7 · La contiguïté, **vérifiée par le calcul et non par confiance**

`A1_contrat_couple` exige `versions[i] == versionCourante - versions.length + 1 + i` pour tout `i`, et
`versions.last == versionCourante`. Avec `versionCourante = 3` et `[Etape(2), Etape(3)]` ⇒ `len = 2` :
`i = 0` → `3 − 2 + 1 + 0 = 2` ✅ · `i = 1` → `3 − 2 + 1 + 1 = 3` ✅ · `last = 3 = versionCourante` ✅.
**La contrainte est satisfaite.**

### 8 · ADR-009 est **nommé, jamais édité** — et son constat vieilli gouverne le `down`

ADR-009 §*Conséquences* dit l'aller-retour *« exact dans un fuseau donné »*. La sonde
`python reports/US-01.2/migration_roundtrip_criterion.py --sonde` montre, **dans le seul fuseau Paris**,
`ALLER_RETOUR_EXACT=false` pour toute **seconde** ou **milliseconde** non nulle **et** pour la **2ᵉ
occurrence de la bascule d'automne**. ⛔ **ADR-009 n'est pas édité** *(immuable ; sa **décision** n'est
pas touchée — c'est son **constat** qui a vieilli)*. ⇒ **la garde d'inversibilité est la CONDITION du
couple, pas une élégance**, et elle s'applique désormais au couple `v2 ⇄ v3`.

## Décision

### 1 · Le champ, sur l'ENTITÉ : `bool retiree`, défaut `false`

`Echeance` porte `final bool retiree` *(défaut `false`)*, intégré à `==`, `hashCode` et `avec()`
*(où `null` signifie **inchangé**, jamais « effacé » — contrat existant d'`avec()`)*.
⛔ **`compareTo` est INCHANGÉ** : l'ordre reste `dateEcheance` puis `id`, sans quoi le tri de la grille
et **AC-6 « Erreur » d'US-01.1** *(ordre déterministe)* changeraient de sens sans qu'aucun AC ne le
demande.

**Ce qui reste interdit dans l'entité, et ne bouge pas d'un mot** : `createdAt`, `dirty`, `version`
— **et `retireeLe`**. ⛔ **Aucun AC ne demande la date du retrait** ⇒ l'y mettre **serait** la
modélisation spéculative qu'`I-7` refuse. L'interdiction d'`I-7` n'est donc **pas levée** : elle est
**réduite d'un champ, nommément**.

### 2 · Sur le DISQUE : une clé d'entrée **optionnelle**, **booléenne**, **écrite seulement si `true`**

| Cas | Forme persistée |
|---|---|
| échéance **présente** | ⛔ **aucune clé `retiree`** dans l'entrée |
| échéance **retirée** | `"retiree":true` |

**Trois conséquences voulues, et chacune est une propriété, pas un espoir** :

1. **L'absence signifie « présente »** ⇒ **AC-5 « Erreur »** *(« les échéances déjà enregistrées restent
   présentes »)* est vrai **PAR CONSTRUCTION**, ⛔ pas par un test de garde : aucun document existant ne
   porte la clé.
2. **Additif par défaut** *(ADR-005 §3, RF-21)* : la montée **n'ajoute rien** aux entrées.
3. 🔴 **À l'écriture, la clé est ÉMISE si et seulement si l'entité est retirée, et RETIRÉE sinon.**
   ⛔ **Un `if (echeance.retiree) 'retiree': true` seul est INSUFFISANT** : `_encoderEntree` copie les
   clés d'`origine` **avant** les clés explicites *(mesuré)* ⇒ un `retiree: true` d'origine
   **survivrait** à une entité non retirée. **Le retrait explicite de la clé est la décision, pas un
   détail d'implémentation.**

### 3 · La grammaire de `retiree`, et **ce qu'un codec fait d'une valeur illicite** — règle **V-1** appliquée sans exception

| Valeur lue | Comportement **exigé** | ⛔ Interdit |
|---|---|---|
| **clé absente** | l'échéance est **PRÉSENTE** | ⛔ Deviner « c'était peut-être retiré » |
| `true` | **`ÉCHUE RETIRÉE`** : absente de la grille, **listée en gestion**, **supprimable** | ⛔ La faire disparaître de la gestion |
| `false` | **PRÉSENTE** — forme **licite**, ⛔ jamais écrite par le produit | ⛔ La traiter en résidu |
| **présente, non booléenne** | 🔴 **l'ENTRÉE ENTIÈRE est un RÉSIDU** : conservée **verbatim à sa place**, **non affichée** | ⛔ Réparer · ⛔ normaliser · ⛔ supprimer · ⛔ **lever une exception** · ⛔ **retomber sur `false`** |

**Motif, et c'est la règle V-1 prise à la lettre — *la barrière est la FORME CANONIQUE, pas une
exception levée*** : le projet a **mesuré** que `DateTime.parse("2026-02-31T23:59")` **ne lève pas** et
rend `2026-03-03T23:59`. La leçon n'est pas *« attraper l'exception »*, c'est *« comparer à la forme
canonique »*. Pour un booléen, la forme canonique est **`value is bool`**, et une valeur hors domaine
suit **exactement** le sort des trois autres clés reconnues hors domaine *(`id`, `description`,
`dateEcheance`)* : **résidu**.

🔬 **Deux raisons de préférer le résidu à un repli sur `false`, et la seconde est décisive** :
**①** un repli **afficherait** une tuile que le pratiquant a retirée — l'application **contredirait une
action de l'utilisateur sur la base d'une valeur qu'elle n'a pas su lire** ;
**②** ⛔ **le résidu n'ajoute AUCUNE règle nouvelle** : la règle existe déjà *(AC-11 d'US-01.2, §5 du
schéma)*, et *« une règle n'existe qu'en un seul exemplaire »*. Un repli spécifique à `retiree` serait
un **deuxième exemplaire** d'une politique de tolérance — et deux copies dérivent, vérifié trois fois
sur ce corpus.

⚠️ **Contrepartie nommée, non gommée** : une entrée à `retiree` illicite **disparaît aussi de la page de
gestion** *(un résidu n'est pas affiché)*. **Aucun octet n'est perdu**, l'entrée est ré-émise verbatim à
chaque écriture, et elle redevient visible dès que sa valeur redevient booléenne. **C'est le
comportement déjà spécifié pour toute entrée non conforme**, et cette décision ⛔ **n'en crée pas
d'exception**.

### 4 · La migration `v2 → v3` : **identité sur les entrées, dans les DEUX sens**

* `versionCourante = 3` ; `etapesMigration = [EtapeMigration(2, …), EtapeMigration(3, _v2VersV3, _v3VersV2)]`
  *(contiguïté vérifiée par le calcul, §Contexte 7)*.
* **`up` (v2 → v3)** : ⛔ **ne touche AUCUNE entrée** — aucune n'est retirée en `v2` et la clé est
  optionnelle. Seul `schemaVersion` change.
* **`down` (v3 → v2)** : ⛔ **ne touche AUCUNE entrée** — une entrée portant `retiree: true` est
  **laissée VERBATIM, clé CONSERVÉE**. En `v2`, *« toute autre clé est préservée verbatim »* : la clé y
  est donc **licite et inerte**.

⇒ **`up ∘ down` est l'identité sur les octets des entrées** ⇒ `A3_aller_retour` **reste vrai**, et
⛔ **aucune information de retrait n'est détruite** : **AC-12 « Erreur » d'US-01.2** *(« aucune migration
ne supprime ni ne tronque une donnée existante »)* — **une US en aval** — **tient**.

**Deux formes explicitement INTERDITES, et le motif de chacune** :

| Forme | ⛔ Pourquoi elle est interdite |
|---|---|
| un `down` qui **retire** la clé `retiree` | Il **détruit** le retrait ⇒ AC-12 « Erreur » tombe. ⚠️ Et ⛔ **le critère d'US-01.2 ne le verrait PAS** *(§Contexte 6)* |
| un `up` qui écrit `retiree: false` **sur chaque entrée** | Son `down` devrait alors **retirer** la clé pour restaurer l'état — donc **détruire un `true`** préexistant. La forme « explicite partout » **fabrique** le `down` destructif qu'on vient d'interdire |

⚠️ **Le `down` n'est emprunté par AUCUN chemin de production** : `charger` migre toujours **vers**
`versionCourante`. Sa valeur est la **garantie exigée par ADR-005 §2** et son **test**. ⛔ **Le dire
autrement serait une fiction.**

### 5 · La garde de `v3` porte **son propre test unitaire, avec ses mutants**

**Exigé, et ⛔ non substituable par le critère d'US-01.2** *(mesuré, §Contexte 6)* :

| Mutant qui doit **MOURIR** | Assertion qui le tue |
|---|---|
| le `down` **retire** `retiree` | une entrée `retiree: true` **survit** à `v3 → v2` **et** à l'aller-retour, **octets identiques** |
| le `up` écrit `retiree: false` partout | l'aller-retour sur une graine **contenant `retiree: true`** est **identique aux octets près** |
| le `up`/`down` **recompose** l'entrée | une **clé inconnue** de l'entrée retirée **survit à sa place** |
| `versionCourante` bumpé **sans** l'étape | ✅ **celui-là, le critère d'US-01.2 le voit** *(contiguïté, `versions.last`)* — il est nommé pour que personne ne le teste deux fois |

⛔ **La graine de ce test contient au moins une entrée retirée** — c'est précisément ce que la graine du
critère d'US-01.2 n'a pas. ✅ **Critère de sortie conservé, exécuté, ⛔ jamais édité** :
`python reports/US-01.2/migration_roundtrip_criterion.py` → **exit 0**, avec `git diff` **vide** sur ce
fichier.

### 6 · Le chemin d'écriture : **5ᵉ opération du port**, **3ᵉ `ActeEcriture`**, **même `_ecrire`**

**Signature décidée** : `Future<ResultatEcriture> retirer(String id)`.

⚖️ **Elle DIFFÈRE de la note que j'avais portée au Story File** *(`retirer(Echeance)`)*, et le motif est
mesurable, pas esthétique :

* `_ecrire(acte, muter)` applique `muter` à **`document.echeances`**, c'est-à-dire à la liste **du
  document**. Avec un `id`, le retrait s'écrit
  `[for (e in liste) if (e.id == id) e.avec(retiree: true) else e]` ⇒ ⛔ **aucun autre champ ne peut être
  écrasé**, quelle que soit la fraîcheur de ce que détient l'appelant.
* Avec une **entité**, l'appelant fournit sa propre copie : une copie **périmée** réécrirait la
  description et la date **de l'ancien état** — une **mise à jour perdue**, silencieuse, et
  ⛔ **qu'aucun AC de cette US ne fait rougir**.
* **Symétrie du port** : `supprimer(String id)` est déjà l'autre opération déclenchée depuis une tuile
  identifiée par son `id`. Deux opérations du même geste prennent le même genre d'argument.

**Contraintes attachées** :

* ⛔ **Pas de second chemin d'écriture** : `retirer` passe par **`_ecrire`**, avec **son propre acte**
  *(**C-8**)*.
* ⛔ **Pas de `remplacer` détourné.** `remplacer` porte `ActeEcriture.enregistrement`, donc un retrait
  refusé annoncerait *« L'échéance n'a pas été enregistrée »* — **reproduction exacte du bloquant
  `NB-B`** d'US-01.2, ouvert pour ce défaut précis.
* **Le TEXTE du 3ᵉ acte appartient à @UXDesigner** *(entrée **U-1**)*. ⛔ **Je ne l'invente pas** :
  *inventer un libellé, c'est fabriquer une assertion de test que le vrai texte rendra fausse.*
  ✅ **Ce que j'impose et qui est vérifiable sans lui** : `ActeEcriture` reste **le seul porteur licite**
  du message, et les **trois** `messageEchec` sont **deux à deux distincts** — contrôle **greppable**,
  ⛔ pas une ligne de DoD affirmée.
* Le commentaire *« Le port : quatre opérations »* devient **faux** ⇒ corrigé **dans le même commit**.

### 7 · Les amendements du corpus sont **DATÉS**, ⛔ jamais repeints

| Document | Ce qui est amendé |
|---|---|
| `MODELE_ECHEANCE.md` | **I-7** : le texte dépassé **reste visible et marqué**, le nouvel invariant est **ajouté au-dessous** — `retiree` **autorisé**, `createdAt` / `dirty` / `version` / `retireeLe` **toujours interdits** |
| `SCHEMA_STOCKAGE_ECHEANCES.md` | **ligne 3NF** *(motif **inapplicable** : un retrait n'est pas un fait dérivable)* · **grammaire** *(la clé `retiree` et son hors-domaine)* · **table des versions** étendue à `v3` |

**Patron suivi** : celui d'`I-5` *(ADR-010 §2)* — *« on date, on ne repeint pas »*. Un lecteur d'audit
doit pouvoir constater **ce qui était prescrit** avant de lire **ce qui a été décidé**.

## Alternatives considérées

- **Un horodatage `DateTime? retireeLe`** *(la forme littérale de `deletedAt`)* — **écarté** : ⛔ **aucun
  AC ne demande la date du retrait**, donc ce serait exactement la **modélisation spéculative** qu'`I-7`
  interdit — et cette interdiction, elle, **n'est pas remplacée**. Un booléen est **le plus petit
  domaine** qui satisfait AC-4 et AC-5.
- **Un `enum EtatEcheance` persisté** *(`active` / `echue` / `echueRetiree`)* — **écarté, et c'est ici
  que la 3NF s'applique VRAIMENT** : `ACTIVE` et `ÉCHUE` se **dérivent** de `(dateEcheance, Clock)` ⇒
  les stocker les rendrait **faux à la seconde suivante**, et le document porterait un état que
  l'horloge contredit. **Seul le retrait n'est pas dérivable** ⇒ **seul le retrait est stocké**.
- **Une collection séparée à la racine** *(`"retirees":["a1","a3"]`)* — **écarté** : deux emplacements
  pour l'état d'une même entité, **intégrité référentielle à la main**, et une suppression devrait
  purger **deux** endroits — sinon un `id` orphelin subsiste, cas que la règle de **résidu** *(qui porte
  sur une **entrée**)* ⛔ **ne couvre pas**. Le codec est bâti sur *« une entrée = une ligne, transportée
  verbatim »* : cette forme le contredirait.
- **Une chaîne au lieu d'un booléen** *(`"etat":"retiree"`)* — **écarté** : domaine plus large sans
  aucun besoin, donc **plus de valeurs hors domaine à traiter**, et une graphie à figer *(un
  `"Retiree"` capitalisé deviendrait un résidu)*. Le booléen n'a **que deux** formes canoniques.
- **⛔ Ne PAS incrémenter la version** *(la clé est optionnelle, donc un document `v2` est un document
  `v3` valide)* — **écarté**, et c'est l'alternative la plus tentante, donc celle qui mérite le motif le
  plus précis. **① ADR-005 §1 l'exige à la lettre** : *« tout changement `+1` avec un couple `up`/`down`
  obligatoire »*, et la **grammaire** change *(une clé reconnue de plus)*. **② Le motif de fond est
  mesuré dans le code** : sans bump, un binaire **antérieur** *(US-01.2)* lit le document, ⛔ **ne
  comprend pas `retiree`**, **affiche comme présente une tuile que le pratiquant a retirée**, **et
  continue d'écrire** — c'est-à-dire il **devine** *(« ⛔ Jamais deviner une version »)*. Avec le bump,
  il prend la branche `version > versionCourante` : **état vide, AUCUNE écriture, document strictement
  intact**. ⚠️ **Ce n'est pas gratuit et il faut le dire** : le pratiquant d'un binaire antérieur verrait
  un **hub vide sans explication** *(compromis déjà arbitré le 2026-08-06, voie b)*. **Entre « ne rien
  toucher et ne rien écrire » et « réinterpréter silencieusement une action de l'utilisateur et écrire
  par-dessus », le versionnement existe pour choisir le premier.**
- **Un `down` qui retire la clé** *(« redescendre proprement à `v2` »)* — **écarté** : il **détruit** le
  retrait, fait tomber **AC-12 « Erreur » d'US-01.2**, et ⛔ **le critère d'US-01.2 le laisserait
  passer** *(§Contexte 6)*. C'est le cas d'école d'un défaut que le vert d'un instrument ne verrait pas.
- **Éditer ADR-010, `MODELE_ECHEANCE.md` I-7 ou la ligne 3NF pour les « mettre à jour »** — **écarté sur
  deux plans** : ADR-010 est **immuable** *(on remplace)* ; les documents de design **sont** maintenus,
  mais le corpus a **payé cinq fois** l'effacement d'un texte fautif — *« un correctif qui s'explique
  produit mécaniquement des occurrences de ce qu'il corrige »*, et **effacer** empêche l'audit de
  vérifier ce qui était prescrit. ⇒ **marquage daté + énoncé ajouté au-dessous.**
- **Faire porter le retrait par `remplacer`** — **écarté** : reproduit `NB-B` *(le message dirait « n'a
  pas été enregistrée » pour un retrait)*, et `remplacer` porte en outre le contrat *« sans
  correspondance d'`id` ⇒ succès »*, qui rendrait un retrait **sans effet** indiscernable d'un succès.
  Le port lui-même l'avait anticipé : *« il faudrait un troisième acte dans `ActeEcriture` — ⛔ pas une
  lecture inversée de ce succès. »*
- **`retirer(Echeance)`** — **écarté** : voir §Décision 6 *(mise à jour perdue possible, asymétrie avec
  `supprimer`)*.
- **Fondre cette décision dans [ADR-013](ADR-013-etat-interaction-grille-observabilite-gestes.md)** —
  **écarté** : les deux ont des **causes** et des **objets** distincts *(ici, un fait persistant non
  dérivable et sa forme sur le disque ; là, l'observabilité d'une interaction)*, et les fondre
  **dupliquerait le motif** — la faute qu'ADR-010 s'interdit explicitement.

## Conséquences

**Positif**

- L'état `ÉCHUE RETIRÉE` devient **durable** et **AC-5 est vrai par construction** *(l'absence de clé
  signifie « présente »)* — ⛔ pas surveillé par un test de garde.
- La **contradiction avec un ADR accepté est LEVÉE par la seule voie licite** : un remplacement **nommé
  et borné**, sans éditer ADR-010, et **sans plaider** que le champ échapperait à sa lettre.
- Le couple `v2 ⇄ v3` est **inversible PAR CONSTRUCTION** *(identité sur les entrées dans les deux
  sens)* ⇒ **AC-12 « Erreur » d'US-01.2 tient**, et cela ne repose sur aucune vigilance.
- **La borne du critère d'US-01.2 est nommée et compensée** : il reste exigé comme non-régression du
  couple `v1 ⇄ v2`, et **la garde de `v3` a son propre test portant ses mutants**.
- **Aucune dépendance nouvelle, aucun paquet, aucune infrastructure.**
- `retirer(String id)` **rend impossible** l'écrasement d'un autre champ, au lieu de l'interdire par
  convention.

**Négatif, et à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve RIEN sur l'application.** À sa date : **aucune ligne de `lib/` n'est écrite pour
  US-01.4**, **`versionCourante` vaut encore 2**, **aucun test n'existe**, **aucune migration `v3` n'a
  jamais été exécutée**. Il fixe ce qui devra être prouvé.
- ⚠️ **Le `down` n'est emprunté par aucun chemin de production.** Il est une **garantie testée**, pas un
  comportement observé par un utilisateur.
- ⚠️ **Le bump de version a un coût produit assumé** : un binaire antérieur montre un **hub vide sans
  explication**. ⛔ **Aucune donnée n'est touchée**, et l'état **s'auto-répare** à la mise à jour — mais
  **personne n'a mesuré ce que vaut cette expérience**, et aucun AC ne la couvre.
- ⚠️ **Une valeur `retiree` illicite fait disparaître l'entrée de la GESTION aussi**, pas seulement de la
  grille. C'est la règle de résidu existante, appliquée sans exception ; **elle n'est pas améliorée
  ici**, et **aucun AC de cette US ne l'observe** *(règle de contrat interne, **voie (b)** — test
  unitaire **déclaré**)*.
- ⚠️ **Le texte du 3ᵉ acte d'écriture est MANQUANT à la date de cet ADR** *(entrée **U-1**,
  @UXDesigner)*. Or `ActeEcriture` **ne compile pas sans une chaîne** ⇒ **T4 ne peut pas être commité
  avec un texte inventé** : le contrôle « trois messages deux à deux distincts » **ne détecte pas un
  texte provisoire plausible**. ⛔ **C'est une dépendance dure, pas une remarque** — et ⛔ **elle ne doit
  pas se découvrir au `/certify`** *(lacune **§A-1** / risque **R-6** du Story File, toujours ouverte)*.
- ⚠️ **La surface d'affichage du message sur le hub n'existe pas** *(mesuré : `MessageValidation` n'est
  monté que par la page de gestion)*. Cet ADR **ancre le refus typé** — donc *« la tuile ne disparaît
  pas »* est **assertable** — mais ⛔ **rien ne s'affiche encore**. **Entrée U-2, @UXDesigner.**
- ⚠️ **Aucun événement de trace ne porte cette décision** : le catalogue n'a **aucun** événement
  d'arbitrage, d'amendement documentaire ni de **remplacement d'ADR**, et `trace_append.py` n'a
  **aucune option `--commit`** ⇒ **rien ne rattache ce document à un état du code** *(dette **NB-6**)*.
  ⛔ **Aucun événement n'est détourné.** La décision vit dans le **corpus durable**.
- 📌 **Dette nommée, non traitée ici** : `EVT_MIGRATION_SCRIPT_READY` a pour `emitter` déclaré
  `data-engineer` et ⛔ **aucune phase de `WORKFLOW.yaml` ne rappelle @DataEngineer après
  `development_start`** ⇒ **il ne sera jamais émis si personne ne le réclame** *(défaut ② du `CLAUDE.md`,
  **2ᵉ occasion de le payer**)*. Il est **réclamé par une tâche dédiée**, ⛔ pas espéré.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
