# ADR-009 : Stockage local — **document JSON unique, versionné, écrit atomiquement**, et instanciation d'ADR-005

- **Date** : 2026-08-04
- **Statut** : Accepté
- **US associée** : US-01.2 (Gestion des échéances — CRUD), EPIC_01, track FULL

> **Ce que cet ADR tranche, et que rien d'autre ne tranchait** : `STACK_PROFILE.md §DataEngineer`
> reporte le **choix du mécanisme de persistance** « à l'US de persistance + un ADR dédié », et
> [ADR-005](ADR-005-convention-migrations-reversibles.md) §5 le redit deux fois. Le choix est **ici**.
> ⚠️ **Désignation par le RÔLE, pas par l'ID** : `STACK_PROFILE` écrit « l'US de persistance (Epic E2
> du PRD, "Gestion des événements") » **sans citer `US-01.2`**. Le rattachement est une **déduction**,
> tenue pour vraie parce que le BACKLOG et EPIC_01 y placent la persistance. Le @PO l'avait relevée
> comme telle ; elle n'est pas levée, elle est **assumée**.

## Contexte

### Ce qui contraint la décision, et qui n'est pas négociable

1. **Le critère d'entrée transféré par EPIC_00** *(critère de clôture nº 112, transfert du 2026-08-01)* :
   **instancier ADR-005**. **Aucune migration n'a jamais été exécutée sur ce projet** et le **risque
   nº 4 d'EPIC_00 reste OUVERT** jusque-là. ⇒ Un mécanisme **dépourvu de notion de version de schéma
   et de couple `up`/`down`** rend ce critère **impossible** à satisfaire : ce n'est pas un
   désavantage à pondérer, c'est **éliminatoire**.
2. **L'application n'a JAMAIS tourné sur un appareil** — ni émulateur, ni JDK
   *(`STACK_PROFILE.md` §DevOps, « Limitations connues » nº 3)*. La chaîne de déploiement est l'objet
   d'**US-01.3**, **postérieure**. ⇒ Un mécanisme qui n'est exerçable que **sur appareil** est **hors
   de portée d'US-01.2**. Second critère **éliminatoire**.
3. **Aucun SAST, aucun scanner de CVE** : `run_gates --gate sast` **n'existe pas** et
   `dart pub outdated` mesure l'**obsolescence**, pas la vulnérabilité *(`STACK_PROFILE.md`
   §Sécurité)*. ⇒ **chaque paquet ajouté ne recevra qu'une revue HUMAINE**. Le **nombre** et la
   **nature** des dépendances transitives sont donc un critère de décision, pas un détail.
4. **Le gate `build` requis est `flutter build web --release`** *(`factory.config.json` →
   `adapter.components.app.gates.build`)*, choisi comme **preuve de constructibilité de repli** parce
   qu'aucun build mobile n'est possible sur ce poste. ⇒ Tout ce qui **casse la compilation web** rend
   un **contexte requis rouge**, quand bien même le web n'est pas une plateforme produit (RNF-08).
5. **Le cliquet de couverture est à `adapter.components.app.coverage_ratchet.value` avec une marge
   NULLE.** ⇒ toute ligne de `lib/` **non atteignable en test** coûte directement du rouge sur un
   contexte requis. Un mécanisme dont la couche d'accès n'est **pas exerçable sur l'hôte** est donc
   doublement pénalisant. *(La valeur se **lit** dans le fichier et le gate l'**imprime** — ⛔ elle
   n'est pas recopiée ici : une valeur recopiée périme.)*

### Ce que le produit demande réellement — mesuré sur les AC, pas supposé

- **Volume borné et minuscule** : au plus **9 échéances présentes** *(AC-5)* + un historique d'échues
  sans plafond *(clarify nº 10)*. **AC-10 « Limite » interdit explicitement** « ni pagination, ni
  index, ni recherche, ni chargement différé ».
- **Aucune requête** : le tri est en mémoire sur ≤ 9 éléments *(`MODELE_ECHEANCE.md` §Ordre)*, l'état
  `ÉCHUE` est **dérivé** et **jamais stocké** *(I-7, `REMAINING_TIME` non persistable)*.
- **Aucun réseau, aucun compte, aucune synchronisation** *(PRD §3.2, RNF-07, AC-10 « Erreur »)* ⇒
  **aucune concurrence multi-écrivains**, un seul isolate, un seul utilisateur.
- **Trois exigences qui portent sur les OCTETS PERSISTÉS, pas sur une API** :
  **AC-11** *(un enregistrement illisible / un fichier tronqué existe réellement et n'est ni réécrit
  ni supprimé)* · **AC-12** *(une migration interrompue laisse l'état antérieur intact ; le retour
  arrière restitue sans perte)* · **AC-14** *(la valeur persistée « ne porte ni fuseau, ni décalage,
  ni marque de temps universel » — le scénario dit littéralement « **j'examine la valeur
  persistée** »)*.

### Contrainte **imposée par le `.feature`, qui est NORMATIF** — et qui force le nombre de versions

Les trois scénarios d'AC-12 posent : *« Étant donné que le stockage local est **dans une version
antérieure** et **contient 3 échéances** »*. Or ADR-005 §1 définit **`v0` = aucun schéma**. ⇒ **une
version antérieure qui CONTIENT des échéances ne peut pas être `v0`**, donc **US-01.2 doit livrer au
moins DEUX versions de schéma**, et la migration exercée doit **transformer des données**, non
seulement créer un schéma. **Cette contrainte n'est pas un choix d'architecte : elle est déduite du
`.feature`**, qui fait foi.

## Décision

### 1 · Le mécanisme retenu : **un document JSON unique, versionné, écrit atomiquement**

- **Un seul fichier** dans le répertoire de documents de l'application :
  `echeances.json`, encodé **UTF-8**, contenant **un objet** :

  ```json
  {"schemaVersion": 2,
   "echeances": [{"id": "…", "description": "…", "dateEcheance": "2026-11-15T23:59"}]}
  ```

- **La version de schéma est portée par le document lui-même** *(clé de tête `schemaVersion`)* — c'est
  la forme que prend, pour ce mécanisme, l'exigence d'ADR-005 §1 « version **stockée par le mécanisme
  de persistance lui-même** » *(là où SQLite utiliserait `PRAGMA user_version`)*.
- **Lecture / écriture du document ENTIER**, jamais d'écriture partielle : le volume est de **9
  enregistrements**.
- **Écriture ATOMIQUE obligatoire** : écrire dans `echeances.json.tmp` avec `flush: true`, **puis
  `rename`** sur la cible. ⛔ **Jamais d'écriture en place.** C'est ce qui rend **AC-12 « Erreur »**
  *(migration interrompue ⇒ état antérieur intact)* **vrai par construction et non par surveillance**.
- **Dépendances** : **`dart:convert` + `dart:io`, qui sont du SDK ⇒ ZÉRO paquet** pour le magasin
  lui-même. **Une seule** dépendance d'exécution ajoutée : **`path_provider`**, appelée en **un seul
  endroit** pour obtenir le répertoire de documents de l'appareil. **Aucune** dépendance de
  développement ajoutée pour les tests.

### 2 · La compilation web est préservée par **import conditionnel**, et c'est une contrainte dure

`lib/` **ne doit jamais importer `dart:io` ni `path_provider` sur un chemin atteignable par le web**.
La forme imposée :

```dart
import 'document_store_stub.dart' if (dart.library.io) 'document_store_io.dart' as plateforme;
```

- La branche **IO** *(`dart:io` + `path_provider`)* est **exclue du bundle web** — mesuré ci-dessous.
- La branche **stub** rend un magasin qui **lit `null` et refuse d'écrire** par `UnsupportedError`
  explicite. ⛔ **Jamais un `catch` silencieux** : sur une plateforme sans stockage, l'application doit
  **dire** qu'elle ne persiste pas, pas faire semblant.

### 3 · L'instanciation d'ADR-005, **concrète et exécutée**

- **`v0`** = **aucun fichier** *(installation neuve — AC-13 « Erreur » : l'état vide est ici réellement
  atteignable)*.
- **`v1`** = document dont `dateEcheance` est un **instant ISO-8601 marqué UTC** (`…Z`) — c'est
  **exactement** ce que prescrivait la **note I-5** de `MODELE_ECHEANCE.md`, **en vigueur jusqu'au
  2026-08-02**.
- **`v2`** = document dont `dateEcheance` est une **date-heure CIVILE** `AAAA-MM-JJThh:mm`, **sans `Z`,
  sans décalage, sans fuseau** — la forme **arbitrée le 2026-08-03** *(AC-14, promu **Must**)*.
- **Le couple de migrations `v1 ⇄ v2` est donc la MATÉRIALISATION de l'arbitrage lui-même** : `up`
  convertit l'instant UTC en date-heure civile locale ; `down` reconstruit l'instant UTC depuis la
  date-heure civile, dans le fuseau local.
- **Le runner de migrations est une liste ORDONNÉE d'étapes** `(version, up, down)` opérant sur un
  `Map<String, Object?>` **décodé** — donc **des fonctions pures**, testables **sans disque**, et le
  patron aller-retour de `MIGRATIONS.md` §4 s'y instancie **littéralement** *(`readSchemaVersion` = la
  clé de tête ; `snapshotSchema` = le document encodé)*.
- **Additif par défaut** *(ADR-005 §3, RF-21)* : une étape qui **retire** de la donnée est **refusée en
  revue** sauf préservation documentée + `EVT_WAIVER_GRANTED`.
- **La migration s'exécute UNE SEULE FOIS** *(AC-12 « Nominal »)* : après un `up` réussi, le document
  réécrit porte la nouvelle `schemaVersion` ⇒ la relecture suivante ne trouve plus rien à migrer.
  ⛔ **Vérifié par un compteur d'appels dans le test**, pas par relecture du code.

### 4 · Les enregistrements illisibles sont **CONSERVÉS VERBATIM** — conséquence directe du document unique

C'est la **contrepartie** du choix « document entier », et elle est **non négociable** :
le décodage sépare **les entrées reconnues** des **résidus** *(entrée non conforme : `id` absent ou
vide, date non interprétable, entrée non-objet)*. **Les résidus sont conservés tels quels** et
**ré-émis à l'identique, à leur place**, à la prochaine écriture. ⛔ **Aucune réparation, aucune
suppression, aucune normalisation** *(AC-11 « Erreur »)*.
En cas d'échec de décodage **du document entier** *(fichier tronqué)* : le fichier est **mis de côté**
par `rename` vers `echeances.json.illisible-<horodatage>` **avant** toute écriture neuve, et
l'application ouvre l'**état vide** *(AC-11 « Limite »)*. ⛔ **Jamais un `delete`.**

### 5 · Vocabulaire : **« échéance »** est le terme unique du produit *(tranché le 2026-08-04)*

`EPIC_01`, `BACKLOG.md` et le SCB intitulent l'US « Gestion des **événements** » ; le Story File et le
`.feature` disent « **échéances** ». **Décision** : le terme du domaine, du code et du schéma persisté
est **`echeance` / échéance**, en un seul exemplaire *(classe `Echeance` déjà livrée par US-01.1, clé
persistée `echeances`)*. **« événement » ne désigne dans ce projet qu'un événement de TRACE (`EVT_*`)**
— homonymie qui, maintenue dans le domaine, ferait collision avec le vocabulaire de traçabilité de la
factory elle-même.
⛔ **Les titres existants ne sont PAS repeints** : cette ADR pose l'**équivalence datée** — dans
`EPIC_01`, `BACKLOG.md` et le SCB, « Gestion des **événements** » **se lit** « Gestion des
**échéances** » *(divergence héritée du PRD §4.2)*. Leur harmonisation éventuelle appartient à leurs
propriétaires *(@ProductOwner)*, **datée**, jamais silencieuse.

## Mesures — les sorties d'outils qui étayent la décision

> ⛔ **Rien ici n'est écrit de mémoire.** Toutes les sorties viennent d'exécutions du 2026-08-04 sur ce
> poste *(Flutter **3.44.7**, Dart **3.12.2**, `windows_x64`)*, dans un projet **jetable** hors du
> dépôt — ⛔ **aucun fichier de `lib/` n'a été écrit pour ces mesures**.

### M-1 · Disponibilité réelle des candidats *(API pub.dev)*

| Paquet | Dernière version | Publiée | Contrainte SDK déclarée |
|---|---|---|---|
| `sqflite` | 2.4.3 | 2026-06-02 | `sdk ^3.12.0`, `flutter >=3.44.0` |
| `sqflite_common_ffi` | 2.4.2 | 2026-06-11 | `sdk ^3.12.0` |
| `drift` | 2.34.3 | 2026-07-27 | `sdk >=3.10.0 <4.0.0` |
| `sembast` | 3.8.9+1 | 2026-06-26 | `sdk ^3.12.0` |
| `objectbox` | 5.3.2 | 2026-05-20 | `sdk >=2.17.0 <4.0.0` |
| **`isar`** | **3.1.0+1** | **2023-04-25** | **`sdk >=2.17.0 <3.0.0`** |
| **`hive`** | **2.2.3** | **2022-06-30** | **`sdk >=2.12.0 <3.0.0`** |
| `hive_ce` *(fork maintenu)* | 2.19.3 | 2026-02-03 | `sdk ^3.4.0` |
| `path_provider` | 2.1.6 | 2026-06-15 | `sdk ^3.10.0` |

⚠️ **`isar` et `hive` déclarent une borne haute `<3.0.0`** alors que le SDK du projet est **3.12.2** :
leurs dernières publications datent de **2023** et **2022**. *(Elles se **résolvent** malgré tout —
mesuré : `flutter pub add isar` → `+ isar 3.1.0+1`, `+ js 0.6.7 (0.7.2 available)` — mais la borne
déclarée et la date de publication sont des faits.)*

### M-2 · Surface transitive réellement ajoutée *(comptée dans `.dart_tool/package_config.json`, base = 28 paquets)*

| Candidat | Δ paquets | Paquets ajoutés |
|---|---|---|
| **document JSON** *(`dart:convert` + `dart:io`)* | **+0** | — *(bibliothèques du SDK)* |
| `sembast` | +2 | `sembast synchronized` |
| `objectbox` | +3 | `ffi flat_buffers objectbox` |
| `hive_ce` | +6 | `crypto hive_ce isolate_channel json_annotation typed_data web` |
| `sqflite` + `sqflite_common_ffi` *(dev)* | +23 | `code_assets crypto ffi file glob hooks logging native_toolchain_c platform plugin_platform_interface pub_semver record_use sqflite sqflite_android sqflite_common sqflite_common_ffi sqflite_darwin sqflite_platform_interface sqlite3 synchronized typed_data web yaml` |
| **`path_provider`** *(retenu)* | **+24** | `args code_assets crypto ffi hooks jni jni_flutter jni_util logging objective_c package_config path_provider path_provider_android path_provider_foundation path_provider_linux path_provider_platform_interface path_provider_windows platform plugin_platform_interface pub_semver record_use typed_data xdg_directories yaml` |
| `drift` + `drift_dev` + `build_runner` | **+49** | dont `analyzer _fe_analyzer_shared build_runner build_daemon dart_style shelf shelf_web_socket web_socket_channel source_gen sqlparser sqlite3 …` |

📌 **Fait qui interdit de plaider « zéro dépendance »** : le magasin JSON coûte **+0**, mais obtenir le
répertoire de documents **sur un appareil** exige `path_provider` ⇒ **+24**, soit **un de plus** que
`sqflite`, qui n'en a pas besoin *(il expose son propre `getDatabasesPath()`)*. **Le critère nº 3 ne
tranche donc PAS entre ces deux-là par le nombre** — il tranche par la **nature** : les 24 de
`path_provider` servent **une seule ligne** *(« donne-moi un chemin »)* et sont **exclus du bundle
web** *(M-4)*, là où les 23 de `sqflite` embarquent un **moteur SQL**, une **liaison FFI** et un
**pilote de chaîne C** qui **traitent la donnée persistée**.

### M-3 · `dart:io` et le web : ce qui est vrai, et ce qui aurait été faux de supposer

`dart-sdk/lib/libraries.json` *(SDK 3.12.2)* déclare `dart:io` **pour les compilateurs web**, avec un
patch, et `support_conditional_import: false` :

```
_dart2js_common io= {"uri": "io/io.dart", "patches": "_internal/js_runtime/lib/io_patch.dart", "support_conditional_import": false}
dartdevc       io= {"uri": "io/io.dart", "patches": "_internal/js_dev_runtime/patch/io_patch.dart", "support_conditional_import": false}
wasm_common    io= {"uri": "io/io.dart", "patches": "_internal/wasm/lib/io_patch.dart", "support_conditional_import": false}
```

Conséquences **mesurées de bout en bout** *(dart2js + node v24.18.0)* :

```
######## A. dart2js sur un import dart:io DIRECT
Compiled 10,315,265 input bytes ... to 134,140 characters JavaScript in 0.63 seconds
exit=0
compile OK avec import dart:io direct
RUNTIME REFUS: UnsupportedError: Unsupported operation: _Namespace
######## B. dart2js sur un import CONDITIONNEL
Compiled 10,315,247 input bytes ... to 12,474 characters JavaScript
branche retenue = STUB (pas de dart:io)
######## C. la MEME source, compilee pour la VM
branche retenue = IO (dart:io present)
```

⇒ ⚠️ **Un `import 'dart:io'` COMPILE pour le web : le gate `build` resterait VERT tout en produisant un
artefact qui casse à l'exécution** (`UnsupportedError: _Namespace`). **C'est un piège**, et c'est
précisément pourquoi l'import conditionnel est **imposé** et non recommandé : il est la seule forme qui
transforme un **plantage silencieux** en **dégradation déclarée**. La chute de **134 140 → 12 474
caractères** est la preuve que la branche IO est **exclue**, pas seulement inerte.

### M-4 · Le patron retenu, éprouvé contre les **trois gates**, dans un vrai projet Flutter

```
######## 1. flutter analyze            -> 0 erreur sur le magasin (2 issues du squelette jetable)
######## 2. flutter test (branche IO reelle, hote)
00:00 +1: All tests passed!
OCTETS REELS SUR LE DISQUE: 19 octets
######## 3. GATE REQUIS : flutter build web --release, avec path_provider au depot
Compiling lib\main.dart for the Web...                             87,8s
√ Built build\web
######## exit=0
######## 4. la branche IO est-elle EXCLUE du bundle web ?
grep -c "path_provider\|_Namespace" build/web/main.dart.js  ->  0
```

⇒ **Les trois critères tiennent simultanément** : le magasin fichier est **exerçable dans `test/` sur
l'hôte, sans appareil** *(19 octets réellement écrits et relus)*, le **gate `build` requis reste
vert**, et `path_provider` **n'entre pas** dans le bundle web.

### M-5 · Le critère ÉLIMINATOIRE nº 1, mesuré paquet par paquet *(occurrences dans `lib/` du paquet)*

| Paquet | `onUpgrade` | `onDowngrade` | `onVersionChanged` | `schemaVersion` | `user_version` | Verdict critère nº 1 |
|---|---|---|---|---|---|---|
| `sqflite_common` | 25 | **24** | 0 | 0 | 2 | ✅ `up`/`down` de **première classe** |
| `drift` | 15 | **0** | 0 | 57 | 17 | ⚠️ version + `up` ; **descente refusée** *(cf. citation)* |
| `sembast` | 0 | 0 | **17** | 0 | 0 | ⚠️ version présente, **un seul rappel**, pas de couple |
| **`hive_ce`** | **0** | **0** | **0** | **0** | **0** | ⛔ **DISQUALIFIÉ** |
| **`objectbox`** | **0** | **0** | **0** | **0** | **0** | ⛔ **DISQUALIFIÉ** |
| **`isar`** | **0** | **0** | **0** | **0** | **0** | ⛔ **DISQUALIFIÉ** |

`drift`, dans son propre code, **refuse** la descente :

```
drift-2.34.3/lib/internal/versioned_schema.dart:99:  "runMigrationSteps was asked to downgrade from versions $from to $to. "
drift-2.34.3/lib/internal/versioned_schema.dart:101: 'downgrade app versions.',
```

`sqflite` fournit un `down` **destructif prêt à l'emploi**, ce qu'ADR-005 §3 interdit par défaut :

```
sqflite_common-2.5.11/lib/sqlite_api.dart:427: /// To set in [OpenDatabaseOptions.onDowngrade] if you want to delete everything on downgrade.
sqflite_common-2.5.11/lib/sqlite_api.dart:428: const OnDatabaseVersionChangeFn onDatabaseDowngradeDelete =
```

`isar` **télécharge son moteur natif depuis GitHub** — dans un projet **sans scanner de CVE** :

```
isar-3.1.0+1/lib/src/native/isar_core.dart:40: const String _githubUrl = 'https://github.com/isar/isar/releases/download';
isar-3.1.0+1/lib/src/native/isar_core.dart:70:        return _downloadIsarCore(downloadPath).then(...
```

`sqlite3` **compile du C** au moment du build/test *(native assets)* — d'où `native_toolchain_c`,
`code_assets` et `hooks` dans sa fermeture :

```
$PUB_CACHE/hosted/pub.dev/sqlite3-3.5.1/hook/build.dart   (présent)
```

### M-6 · Les deux finalistes, mis à l'épreuve **par exécution** sous `flutter test`, sur l'hôte

**`sqflite` + `sqflite_common_ffi`, base sur FICHIER** — `up` **et** `down` réellement observés :

```
JOURNAL SQFLITE: [onCreate v1, onUpgrade 1->2, v=2, lignes=1, onDowngrade 2->1, v=1,
                  date brute=2026-11-15T23:59]
00:04 +1  (4 secondes)
```

**Document JSON** — version, `up`, `down`, aller-retour, écriture atomique, interruption, troncature :

```
JOURNAL JSON: v1 sur disque={"schemaVersion":1,"echeances":[{"id":"a","description":"Convent","dateEcheance":"2026-11-15T23:59"}]}
              v2 sur disque={"schemaVersion":2,"echeances":[{"id":"a","description":"Convent","dateEcheance":"2026-11-15T23:59","note":null}]}
              ROUND-TRIP identique=true
              octets identiques=true
              apres interruption, fichier intact=true
              tronque: FormatException reelle -> Unexpected end of input
00:05 +2  (~1 seconde pour ce test)
```

⇒ **Les deux passent les critères 1 et 2.** Ce qui les sépare est mesuré, pas ressenti :
le document JSON prouve l'invariant d'aller-retour **sur les OCTETS** (`octets identiques=true`), prouve
**AC-12 « Erreur »** *(`fichier intact=true` après interruption)* et prouve **AC-11** *(une troncature
réelle produit une `FormatException` réelle)* — **trois assertions que `sqflite` ne permet qu'au prix
d'un moteur, d'une liaison FFI et d'une chaîne C**, et **avec une liaison DIFFÉRENTE en test et sur
l'appareil** *(FFI sur l'hôte, greffon Android/Darwin en production)*.

## Alternatives considérées

- **`sqflite` (+ `sqflite_common_ffi` en dev)** — **le finaliste sérieux, écarté**, et pas pour un motif
  de goût :
  **(a)** en test l'exécution passe par **FFI + sqlite3 compilé sur l'hôte**, sur l'appareil par le
  **greffon Android/Darwin** ⇒ **le code de migration n'est jamais éprouvé sur le moteur qui tournera
  en production** — borne que le document JSON **n'a pas** *(même code, seul le répertoire diffère)* ;
  **(b)** il apporte un **moteur SQL, une liaison FFI et un pilote de chaîne C** *(`native_toolchain_c`,
  `hook/build.dart` de `sqlite3`)* pour **9 enregistrements** dont **AC-10 « Limite » interdit** index,
  pagination, recherche et chargement différé ⇒ **excédent fonctionnel assumé comme tel** ;
  **(c)** sa couche de composition *(fabrique de base de données côté application)* est **inatteignable
  sous `flutter test`** ⇒ des **lignes non couvertes** dans `lib/`, avec un cliquet à **marge nulle** ;
  **(d)** il expose `onDatabaseDowngradeDelete`, un `down` **destructif** que la revue devrait
  interdire à la main *(ADR-005 §3)*.
  ⚠️ **Ce qu'il avait pour lui, et qui est réel** : `MIGRATIONS.md` §1 le **nomme comme exemple**
  (`PRAGMA user_version`), son couple `up`/`down` est de **première classe** *(24 + 25 occurrences)*, et
  il **évite `path_provider`**. **Réexaminable** dès qu'une US demandera de **requêter** la donnée
  *(recherche, filtre, historique volumineux, second module persisté)* — ce sera **un nouvel ADR**, pas
  une extension de celui-ci.
- **`drift`** — **écarté**. **+49 paquets** dont `build_runner`, `analyzer`, `dart_style`, `shelf`,
  `web_socket_channel`, dans un projet **sans SAST ni scan de CVE** ; **précédent direct** : ADR-008 a
  déjà écarté `bdd_widget_test` pour **exactement** ce motif *(« grosse arborescence transitive » +
  « dérive génération ↔ source »)*. Et **sa descente est refusée par son propre code**, ce qui heurte
  frontalement ADR-005 §1 *(couple `up`/`down` obligatoire)*.
- **`isar`** — **écarté, deux fois éliminatoire**. **Zéro** API de version ou de migration *(M-5)* ⇒
  critère nº 1 **impossible** ; et son **moteur natif se TÉLÉCHARGE depuis GitHub** pour tourner sur
  l'hôte ⇒ un **binaire non scanné**, exécuté par les tests, dans un projet **sans scanner de CVE**.
  Dernière publication **2023-04-25**, borne SDK déclarée **`<3.0.0`**.
- **`hive` / `hive_ce`** — **écarté, éliminatoire**. `hive` : dernière publication **2022-06-30**, borne
  `<3.0.0`. `hive_ce` *(fork maintenu, +6 paquets seulement)* : **0 occurrence** de `schemaVersion`,
  `onUpgrade`, `onDowngrade` ou équivalent ⇒ **aucune notion de version de schéma** ⇒ ADR-005 **ne peut
  pas s'y instancier**, donc le **critère d'entrée transféré par EPIC_00 serait IMPOSSIBLE** à
  satisfaire. C'est le cas d'école que la clause éliminatoire visait.
- **`objectbox`** — **écarté, éliminatoire**. **0 occurrence** de version/`up`/`down` *(M-5)* : son
  évolution de schéma est **automatique et non réversible**. Exige en outre un **binaire natif
  installé hors `pub`**.
- **`sembast`** — **le plus proche runner-up, écarté**. Beaucoup à son crédit : **+2 paquets
  seulement**, **Dart pur**, même auteur que `sqflite`, exerçable sur l'hôte, et une **notion de
  version** *(`onVersionChanged`, 17 occurrences)*. **Écarté** parce que : **(a)** son rappel est
  **unique et non orienté** — **aucun couple `up`/`down`** ⇒ nous écririons **le même runner de
  migrations** que pour le document JSON, mais **avec une dépendance de plus** ; **(b)** il reste
  tributaire de `path_provider` pour un chemin de fichier, donc **+26 au total** contre **+24** ;
  **(c)** son magasin de documents *(clés auto-incrémentées, `StoreRef`, filtres, transactions)* est un
  appareillage **sans emploi** pour **9 enregistrements lus et écrits en bloc**. ⚠️ **Il redeviendra le
  candidat naturel** si le volume cesse d'être borné **sans** qu'un besoin de requêtes apparaisse.
- **`shared_preferences`** — **écarté**. **+17 paquets**, et surtout : son histoire de test sur l'hôte
  est `setMockInitialValues`, une **carte en mémoire** ⇒ un E2E ne traverserait **aucun octet réel**,
  ce qu'[ADR-010](ADR-010-clauses-track-full-avec-persistance.md) **interdit**. Sémantique de
  **préférences**, détournée en base de données.
- **Un fichier par échéance** *(au lieu d'un document unique)* — **écarté**. Rendrait l'écriture
  atomique **par enregistrement** mais **détruirait l'atomicité de la MIGRATION** : 9 renommages ne
  sont pas une transaction, et **AC-12 « Erreur »** *(état antérieur intact après interruption)*
  deviendrait **infaisable sans journal**. Un journal pour 9 enregistrements, c'est réécrire une base.
- **Chiffrement au repos** — **hors périmètre, et nommé** : aucun AC ne le demande, `STACK_PROFILE`
  §Sécurité borne la surface au « stockage local de l'appareil », et le PRD ne classe aucune donnée
  d'échéance comme sensible. ⚠️ **À rouvrir** si une US future y stocke autre chose que des libellés
  saisis par le pratiquant.

## Conséquences

**Positif**

- **Le critère d'entrée transféré par EPIC_00 devient réellement atteignable** : la convention d'ADR-005
  s'instancie **littéralement** *(`schemaVersion` = version monotone, couple `up`/`down` par étape,
  patron aller-retour de `MIGRATIONS.md` §4 sur des **fonctions pures**)*, et **le `down` n'est pas une
  option du paquet mais du code du projet, donc testable sans réserve**.
- **Trois AC deviennent prouvables sur les OCTETS et non sur une API** : AC-11 *(troncature réelle,
  résidus conservés)*, AC-12 *(interruption ⇒ fichier intact, mesuré)*, AC-14 *(`"2026-11-15T23:59"`
  sur le disque, ⛔ ni `Z`, ni décalage — le scénario demande d'« examiner la valeur persistée », il
  suffit de lire le fichier)*.
- **Le test et l'appareil exécutent LE MÊME code** ; seul le répertoire diffère. C'est ce qui autorise
  l'exigence durcie d'[ADR-010](ADR-010-clauses-track-full-avec-persistance.md) *(« les E2E traversent
  la persistance RÉELLE »)* **sans fiction**.
- **Surface ajoutée minimale et de première partie** : **+0** pour le magasin, **+24** pour
  `path_provider` *(publié par `flutter.dev`, exclu du bundle web, appelé en un seul endroit)*.
  **Aucune** dépendance de développement, **aucun** binaire téléchargé, **aucune** compilation C —
  ce qui compte quand la seule barrière est **une revue humaine**.
- **Couverture** : toute la couche de données *(décodage, validation, migration, encodage)* est du
  **Dart pur exerçable sur l'hôte** ⇒ elle **contribue** au cliquet au lieu de le menacer. Seuls
  l'appel à `path_provider` et le stub web restent hors d'atteinte.
- **Le gate `build` requis reste vert**, mesuré, **avec** `path_provider` au dépôt.

**Négatif, et à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve rien sur l'application** : il fixe le mécanisme. **Aucune ligne de `lib/`
  n'est écrite à sa date**, aucune migration n'a encore tourné **dans le produit**, et le **risque
  nº 4 d'EPIC_00 reste OUVERT** jusqu'à ce que les tests d'US-01.2 l'exécutent réellement.
- ⚠️ **Nous écrivons le runner de migrations**, là où `sqflite` l'aurait fourni. **C'est du code de
  plus à tester** — assumé, parce que c'est aussi du code **dont le `down` existe** et qui est
  **exerçable sans moteur**. ⛔ **Il doit porter son propre autotest de mutation** *(un `down` qui ne
  restaure pas doit faire ÉCHOUER le patron)*, sinon il ne mesure rien — leçon du corpus, vérifiée sept
  fois sur sept.
- ⚠️ **`v1` n'est PAS un héritage de production** : **aucun utilisateur n'a jamais détenu de document
  `v1`**, puisque **rien n'a jamais été distribué**. `v1` est la forme que **le modèle documenté du
  projet prescrivait** *(note I-5, jusqu'au 2026-08-02)*, conservée comme **format lisible** pour que
  la première migration du projet **transforme de la donnée** au lieu de créer un schéma vide — ce que
  le `.feature`, **normatif**, exige *(« une version antérieure … contient 3 échéances »)*. **La valeur
  de cette migration est la preuve du MÉCANISME, pas le sauvetage de données réelles.** ⛔ Le dire
  autrement serait une fiction.
- ⚠️ **`down(v2→v1)` reconstruit un instant depuis une date civile, dans le fuseau LOCAL** :
  l'aller-retour est **exact dans un fuseau donné** *(ce que le patron asserte)* et **ne l'est pas
  d'un fuseau à l'autre**. Cette asymétrie **n'est pas un défaut du runner** : c'est **la mesure même**
  de ce qui a motivé AC-14 et le dépassement d'I-5 *(cf. ADR-010)*. Au sens de `MIGRATIONS.md` §2
  « Limite », **ce paragraphe est la documentation de cette borne** ; ⛔ **aucune donnée n'est perdue**
  *(seule l'ancre de fuseau est re-dérivée)*, donc le §3 « destructif encadré » **n'est pas
  déclenché** et **aucune dérogation n'est demandée**.
- ⚠️ **Sur le WEB, l'application ne persiste rien** *(branche stub)*. C'est **assumé** : RNF-08 vise
  iOS/Android, et le web n'est qu'un **gate de constructibilité** *(`STACK_PROFILE` §DevOps)*. ⛔ Mais
  cela doit rester **dit** : `flutter build web` **restera vert** en produisant un artefact **sans
  stockage**. **Aucune barrière machine ne signale cet écart** — dette nommée ci-dessous.
- ⚠️ **`path_provider` n'est exerçable ni en test hôte, ni sur le web, ni en CI** : il n'existe qu'au
  **point de composition** de l'application, sur un appareil que **ce projet n'a jamais eu**. ⇒ le
  chemin « le vrai répertoire de documents de l'appareil » **reste NON VÉRIFIÉ** jusqu'à **US-01.3**.
  **C'est une borne de mesure nouvelle**, de la même famille que NM-1/NM-4, et elle doit être portée
  comme telle. ⛔ **Ne pas la déguiser en test vert.**
- ⚠️ **Le document unique impose la conservation des résidus** *(§4)*. C'est une **contrainte subtile
  et facile à casser** : un développeur qui recompose le document depuis les seules entités **détruit
  silencieusement** l'enregistrement illisible, et **AC-11 tombe sans qu'aucun test générique ne le
  voie**. ⇒ **elle exige son propre test, avec mutant.**
- ⚠️ **Aucun événement de trace ne porte cette décision** : le catalogue n'a **aucun** événement de
  choix technologique, et `EVT_MIGRATION_SCRIPT_READY` porte sur un **script**, pas sur un ADR.
  Même famille structurelle que l'absence d'événement de **clôture d'EPIC** et d'**extinction de
  dérogation** — dettes déjà nommées. La décision vit dans le **corpus durable**.
- 📌 **Dette ouverte, à verser à US-00.8** : **rien ne vérifie par machine** que `lib/` n'importe pas
  `dart:io` hors de la branche conditionnelle. Le gate `build` **ne le voit pas** *(M-3 : ça compile)*.
  Un contrôle greppable — *« aucun `import 'dart:io'` dans `lib/` hors des fichiers `*_io.dart` »* —
  **coûterait quelques lignes** et fermerait un piège **déjà mesuré**. ⛔ **Non fait dans cette US** :
  ce serait un gate de gouvernance de plus dans une US produit.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
