# Re-audit sécurité (delta 2) — US-01.2 « Gestion des échéances (CRUD) »

| Champ | Valeur |
|---|---|
| **Verdict** | ✅ **PASSED** |
| **Agent** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | claude-opus-5[1m] (Opus 5, 1M context) |
| **Date** | 2026-08-17 |
| **Commits audités** *(**NB-6** : `trace_append.py --help` **ne montre aucune option `--commit`** — vérifié §1.7 ⇒ les SHA vivent dans le `rationale`)* | **code = `28d9504`** · **HEAD = `b77e3cf`** *(branche `feat/US-01.2-design`)* |
| **Périmètre** | `git diff main...HEAD` — tout le code. Delta prioritaire : `git diff 2d77778..28d9504 -- lib test` *(5 fichiers, `+718 −26`)* |
| **Rapports précédents** | [`security.md`](security.md) *(`FAILED`, `B-1`, sur `5272ed1`)* · [`security_delta.md`](security_delta.md) *(`FAILED`, `B-2`, sur `2d77778`)* — ⛔ **ni l'un ni l'autre n'est écrasé** |
| **Statut de `B-1`** | ✅ **FERMÉ** *(établi au 2ᵉ tour)* — **non régressé**, re-mesuré ici *(§3.1, mutant `M-13`)* |
| **Statut de `B-2`** | ✅ **FERMÉ** — **prouvé par un déclencheur EXÉCUTÉ que j'ai fabriqué moi-même** *(un verrou ordinaire, ⛔ pas l'obstacle des tests livrés)*, plus **2 mutants de réintroduction TUÉS** *(§3.2)* |
| **Motif du verdict** | **0 finding BLOQUANT.** La famille « chemin d'erreur qui avale » est **refermée sur son axe destructif** : les **9 sites** de `catch`/`throw` de `lib/` sont énumérés et le **seul** `on Object` à corps de commentaire restant est **mesuré NON DESTRUCTIF** *(§4)* |
| **Isolation** | **`git worktree` dédié**, détaché sur `b77e3cf`. ⛔ **Aucun fichier de l'arbre principal modifié** hors ce rapport et la ligne de trace *(§9)* — remède au `NB-H` de mon prédécesseur |

> ⚖️ **Ce verdict porte sur `28d9504` et sur rien d'autre.** ⛔ **Il ne dit pas « le produit est sûr » :**
> il dit que **les trois questions posées à ce tour ont reçu une réponse mesurée**, qu'**aucun
> déclencheur destructif n'a pu être atteint depuis le produit**, et que **la surface non couverte est
> exactement celle du §8** — qui n'a pas bougé *(aucun SAST, aucun scan de CVE, aucun appareil)*.

---

## 1. Sorties d'outils — brutes, collées

### 1.0 Isolation et périmètre — **le code est-il figé à `28d9504` ? OUI, vérifié**

```
$ git rev-parse HEAD                       (dans MON worktree)
b77e3cf51e19b453a2500c69b6bc380181f3bcfc

$ git diff --name-only 28d9504..HEAD -- lib test scripts pubspec.yaml pubspec.lock
[fin liste]                                ← 0 fichier

$ git log --oneline -8
b77e3cf docs(us-01.2): peremption des visas apres le 2e cycle de correctif
e991749 chore(us-01.2): EVT_CODE_READY re-emis apres le 3e cycle de correctif
69844c2 docs(us-01.2): C4 a C7 — les 4 sujets du 2e tour, coches avec leurs mutants
28d9504 fix(echeances): NB-J — la doc de charger() dit ce qui EST, et dit sa borne
f42ec1a fix(echeances): NB-E — un rename echoue n abandonne plus les donnees en .tmp
e5d471e fix(echeances): B-2 — une mise de cote qui echoue REFUSE l ecriture
e26d791 fix(echeances): NB-F et NB-G — le TYPE de l occupant, pas son existence
89a0a42 docs(us-01.2): 2e tour d audit — revue PASSED, securite FAILED sur B-2

$ git diff --stat 2d77778..28d9504 -- lib test
 lib/features/echeances/data/document_store.dart            |  14 +-
 lib/features/echeances/data/document_store_io.dart         | 133 ++++++++-
 .../echeances/data/echeance_document_repository.dart       |  96 ++++++-
 test/features/echeances/data/document_store_test.dart      | 193 +++++++++++++
 .../data/echeance_document_repository_test.dart            | 308 +++++++++++++++++++++
 5 files changed, 718 insertions(+), 26 deletions(-)
```

**Surface hors code, mesurée et non supposée** :

```
$ git diff --name-only main...HEAD -- .github/
[fin]                                      ← 0 fichier sur TOUTE l'US

$ git diff --name-only 2d77778..28d9504 -- pubspec.yaml pubspec.lock
[fin]                                      ← 0 fichier sur le delta

$ git diff --name-only 2d77778..28d9504 -- scripts/
[fin]                                      ← 0 fichier
```

⇒ **les bornes CVE et SAST n'ont PAS bougé** : ni CI, ni dépendances, ni outillage.

### 1.1 `run_gates --gate sast` — ⛔ **LE GATE N'EXISTE TOUJOURS PAS**

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

Liste **LUE** dans `factory.config.json` → `adapter.components.app.gates` *(⛔ jamais recopiée)* :

```
format             {'cmd': 'dart format --output=none --set-exit-if-changed lib test'}
analyze            {'cmd': 'flutter analyze'}
test               {'cmd': 'flutter test --coverage && python scripts/check_flutter_coverage.py --min 80'}
deps_audit         {'cmd': 'dart pub outdated --show-all', 'blocking': False}
build              {'cmd': 'flutter build web --release'}
```

⇒ **5 gates, aucun SAST**, et **`deps_audit` porte `blocking: False`** — **re-vérifié par lecture**,
conformément à la consigne. **Toute la revue de ce rapport est HUMAINE**, donc **non exhaustive**.

### 1.2 `run_gates --gate deps_audit` — mesure l'**obsolescence**, ⛔ **pas la vulnérabilité**

```
▶ app.deps_audit — (.) $ dart pub outdated --show-all
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name                      Current   Upgradable  Resolvable  Latest
direct dependencies:
cupertino_icons                   1.0.9     1.0.9       1.0.9       1.0.9
flutter                           (sdk)     (sdk)       (sdk)       (sdk)
path_provider                     2.1.6     2.1.6       2.1.6       2.1.6
dev_dependencies:
flutter_lints                     6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                      (sdk)     (sdk)       (sdk)       (sdk)
[… 46 transitives, dont hooks *2.0.2, material_color_utilities *0.13.0, meta *1.18.0,
   record_use *0.6.0, vector_math *2.2.0, matcher *0.12.19, test_api *0.7.11 …]
You are already using the newest resolvable versions listed in the 'Resolvable' column.
Newer versions, listed in 'Latest', may not be mutually compatible.
✅ app.deps_audit
EXIT=0
```

🔴 **`dart pub outdated` compare des NUMÉROS DE VERSION et ne consulte AUCUNE base de CVE.**
⇒ **aucune ligne de ce rapport ne dit « pas de CVE » : le projet n'a toujours aucun moyen de le savoir.**

### 1.3 Fermeture transitive — comparée **par ENSEMBLES**, ⛔ pas par cardinaux

```
$ (lecture de pubspec.lock à trois références, comparaison d'ensembles par script)
main=27  2d77778=51  28d9504=51
ENSEMBLES 2d77778 vs 28d9504 IDENTIQUES ? True
  ajoutes par le delta : []
  retires par le delta : []
AJOUTES par toute l'US (main -> HEAD) : 24
  ['args', 'code_assets', 'crypto', 'ffi', 'hooks', 'jni', 'jni_flutter', 'jni_util',
   'logging', 'objective_c', 'package_config', 'path_provider', 'path_provider_android',
   'path_provider_foundation', 'path_provider_linux', 'path_provider_platform_interface',
   'path_provider_windows', 'platform', 'plugin_platform_interface', 'pub_semver',
   'record_use', 'typed_data', 'xdg_directories', 'yaml']
RETIRES par toute l'US : []
deps DIRECTES declarees a HEAD : ['cupertino_icons', 'flutter', 'path_provider']
```

⇒ ⛔ **`51 == 51` n'aurait rien prouvé** *(un ajout + un retrait donnent le même cardinal)* : ce sont
les **ensembles** qui sont identiques, **différence vide dans les deux sens**. **La surface de
dépendances de ce cycle est EXACTEMENT celle que `security_delta.md` a décrite** — ni aggravée, ni
levée.

### 1.4 `run_gates --all` — les 5 gates, **sur un arbre propre et ISOLÉ**

```
$ git status --porcelain                   ← VIDE, vérifié AVANT lancement

▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 0.58 seconds.
✅ app.format

▶ app.analyze — (.) $ flutter analyze
No issues found! (ran in 8.4s)
✅ app.analyze

▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
02:11 +369: All tests passed!
Couverture de lignes : 97.9% (941/961) — seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigné le 2026-08-02 — PR27
  [HAUSSE] 97.92% (941/961) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.9
✅ app.test

▶ app.deps_audit  ✅   (§1.2)

▶ app.build — (.) $ flutter build web --release
√ Built build\web
✅ app.build

Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

⚠️ **Cette fenêtre d'exécution est ATTRIBUABLE, et c'est neuf** : elle a tourné dans **mon worktree**,
`git status --porcelain` **vide de mon fait**. Mon prédécesseur ne pouvait pas l'affirmer *(`NB-H`)*.

🔴 **Cinquième confirmation de l'acquis d'US-01.1, et elle est ici la plus nette** : **5 gates verts**
et **couverture qui MONTE**, sur un code où **deux bloquants HIGH successifs** ont vécu. ⛔ **Ce n'est
pas la couverture qui a fermé `B-2`, ce sont les mutants** — et le Story File le mesure lui-même :
la correction d'un bloquant HIGH **et ses 3 tests** ont laissé la couverture **exactement identique**
*(`940/960` avant **et** après)*.

### 1.5 `gitleaks` — arbre **et** commits

```
$ gitleaks version
8.30.1

$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~63790956 bytes (63.79 MB) in 5.07s
INF no leaks found
EXIT=0

$ gitleaks git --log-opts="main..HEAD" --config .gitleaks.toml --redact -v .
INF 35 commits scanned.
INF scanned ~1090373 bytes (1.09 MB) in 3.75s
INF no leaks found
EXIT=0

$ gitleaks git --log-opts="2d77778..28d9504" --config .gitleaks.toml --redact -v .
INF 7 commits scanned.
INF scanned ~205819 bytes (205.82 KB) in 593ms
INF no leaks found
EXIT=0
```

✅ **Aucun secret en dur**, y compris dans les **6 commits du 2ᵉ cycle** *(27 → 35 commits scannés sur
`main..HEAD`)*. Les fixtures ajoutées sont des **octets de document métier**, jamais du matériel
cryptographique.

### 1.6 Revue manuelle ciblée — la grille du rôle, dite au lieu d'être laissée en blanc

```
$ grep -rn "allowMalformed" lib/
document_store.dart:50       /// `utf8.decode(..., allowMalformed: true)`. Il ne lève plus, mais il remplace
document_store_io.dart:90    // ⛔ Ni `allowMalformed`, ni valeur par défaut, ni fichier réparé : le
        ⇒ DEUX COMMENTAIRES QUI LE REFUSENT, ⛔ aucun appel

$ grep -rn "readAsString\|readAsBytes" lib/     (hors doc)
document_store_io.dart:88        return DocumentLu(await cible.readAsString());   ← site UNIQUE, gardé

$ grep -rn "\.delete\|deleteSync" lib/
document_store_io.dart:137       await provisoire.delete();        ← NEUF dans ce cycle (§5, NB-L)
ligne_echeance.dart:151          icone: Icons.delete_outline,      ← une icône
```

* **Injection** : `jsonDecode` / `jsonEncode` **seuls**, aucune requête, aucun template, aucun rendu
  HTML. Un `<script>` en description est **stocké verbatim et jamais interprété** *(re-mesuré, `P-7`)*.
* **Traversée de répertoire** : un `id` hostile *(`../../../../etc/passwd`)* est accepté **comme
  identifiant** et **n'entre dans AUCUNE construction de chemin** — mesuré : `reconnues=1`,
  `fichiers=[echeances.json]`. Le nom vit en un seul exemplaire *(`const String nomDocument`)*.
* **Secrets / mots de passe / hachage** : aucun — **aucun compte, aucune authentification**.
* ⛔ **Hors surface, et je le dis au lieu de laisser un blanc** : **IDOR**, **authz d'endpoint**,
  **CSRF**, **CORS**, **session**. Application **locale, mono-utilisateur, sans serveur, sans
  endpoint, sans réseau** *(dépendances d'exécution LUES : `flutter (sdk)`, `cupertino_icons`,
  `path_provider`)*. ⇒ **aucune ressource appartenant à un tiers, donc aucun contrôle d'appartenance
  à exiger.** ⛔ **Ce n'est pas « conforme », c'est « hors surface »** — cela changera à la première
  synchronisation *(`N-2`)*.

### 1.7 Trace et chaîne d'événements

```
$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
EXIT=0

$ (lecture de docs/trace/US-01.2/events.jsonl)
2026-08-05T10:54:42  EVT_STORY_CREATED            product-owner
2026-08-05T11:03:39  EVT_TRACK_SELECTED           architect
2026-08-05T11:49:56  EVT_STORY_READY              product-owner
2026-08-05T11:50:30  EVT_ARCHI_VALIDATED          architect
2026-08-06T10:13:26  EVT_UX_DESIGN_COMPLETED      ux-designer
2026-08-06T10:45:08  EVT_DATA_DESIGN_COMPLETED    data-engineer
2026-08-06T12:12:54  EVT_DESIGN_COMPLETED         architect
2026-08-07T15:24:06  EVT_CODE_READY               developer
2026-08-07T17:37:01  EVT_SECURITY_AUDIT_FAILED    cyber-security
2026-08-07T19:05:30  EVT_CODE_REVIEW_PASSED       code-reviewer
2026-08-10T19:13:49  EVT_CODE_READY               developer
2026-08-11T17:05:26  EVT_SECURITY_AUDIT_FAILED    cyber-security
2026-08-11T17:21:23  EVT_CODE_REVIEW_PASSED       code-reviewer
2026-08-11T20:06:18  EVT_CODE_READY               developer

$ (lecture de scripts/events_catalog.json)
EVT_SECURITY_AUDIT_PASSED   preconditions : ['EVT_CODE_READY']   emitter : cyber-security
EVT_SECURITY_AUDIT_FAILED   preconditions : ['EVT_CODE_READY']   emitter : cyber-security

$ python scripts/trace_append.py --help    (options extraites)
--agent --command --event --files --help --model --rationale --report --session --us
```

⇒ **précondition satisfaite** *(dernier `EVT_CODE_READY` = 2026-08-11T20:06)*, et **`NB-6` est
CONFIRMÉ par la commande** : ⛔ **aucune option `--commit`** ⇒ **aucune machine ne pourra signaler que
ce visa a périmé.**

---

## 2. Méthode — pourquoi ce rapport s'adosse à des **mutants**, et où ils ont tourné

**Isolation, appliquée et vérifiable.** Tout — sondes, mutants, gates — a tourné dans un
**`git worktree` dédié** détaché sur `b77e3cf`. C'est le remède au `NB-H` de mon prédécesseur *(deux
audits mutants sur un seul arbre, contamination **observée**)*. **Après chaque mutant** :
`git checkout -- lib/` puis `git status --porcelain`, **relevé à chaque itération** — la sortie est
`VIDE` **14 fois sur 14** *(§9)*.

⚠️ **Un incident RÉEL pendant cette campagne, et il vaut d'être écrit** : mon lanceur de mutants a
**planté sur `cp1252`** en imprimant un nom de test contenant un emoji — **la classe de bug exacte que
ce projet traîne**, et qui avait déjà pris l'auditeur de revue d'US-00.6. Le plantage est survenu
**après** l'application du mutant et **avant** la restauration ⇒ **l'arbre est resté MUTÉ**. Je l'ai
constaté par `git status --porcelain` *(` M lib/.../document_store_io.dart`)* et restauré avant de
continuer. ➡️ **Deux leçons** : `PYTHONIOENCODING=utf-8` sur tout lanceur, et **la restauration
appartient à un `finally`, jamais à la fin du corps** — sinon **l'isolation ne protège que tant que le
lanceur ne meurt pas**. ⛔ **Sans le worktree, cet incident aurait mutilé l'arbre partagé pendant que
l'auditeur de revue y travaillait.**

**Campagne : 14 mutants.** ⛔ **Comparés en ENSEMBLES, jamais annoncés par un cardinal seul.**

* **TUÉS (11)** : `M-1`, `M-2`, `M-3`, `M-4`, `M-5`, `M-6`, `M-8`, `M-10`, `M-12`, `M-13`, `M-14`.
* **SURVIVANTS (3)** : `M-7`, `M-9`, `M-11` — **tous les trois NOMMÉS et caractérisés** *(§5)*.
  Deux d'entre eux *(`M-7`, `M-11`)* se sont révélés **NON REPRÉSENTABLES sous Windows**, ⛔ **et ce
  n'est pas une excuse : c'est une mesure**, faite en jouant le mutant **contre trois classes
  d'obstacle** et en comparant les sorties **témoin ↔ mutant** *(§5.1, §5.3)*.

---

## 3. Les questions de ce tour, une par une

### 3.1 `B-1` — **non régressé**

`M-13` *(rendre `DocumentIllisible` pour un fichier **absent**, donc brouiller `v0`)* est **TUÉ par
3 tests**, dont le **contrôle négatif** :

```
### M-13 lire() : le try couvre AUSSI le test de type
  test EXIT=1 | 00:03 +90 -3: Some tests failed.   >>> TUE
   TUE PAR : … aucun fichier ⇒ lire() rend DocumentAbsent (c'est `v0`)
   TUE PAR : … 🔴 un `.tmp` laissé par une INTERRUPTION n'est JAMAIS lu
   TUE PAR : … 🔴 CONTRÔLE NÉGATIF de NB-F — un VRAI fichier au MÊME nom est LU, et l'absence reste `v0`
```

### 3.2 🔴 `B-2` — **RÉELLEMENT FERMÉ**, et le déclencheur est le mien

⛔ **Je n'ai pas rejoué le déclencheur des tests livrés** *(des répertoires occupant les 8
destinations)*. J'ai rejoué **celui de mon prédécesseur** — un **verrou ordinaire**, la classe
réaliste *(antivirus, OneDrive, seconde instance)* — avec **mes propres fixtures** *(un document JSON
parfaitement valide portant **un seul octet cp1252**, fabriqué dans ma sonde, ⛔ pas emprunté au
harnais du projet)*, sur le **magasin `io` de PRODUCTION** :

```
[SONDE] P-1 verrou exclusif pose sur echeances.json
[SONDE] P-1 lire() sous verrou => DocumentIllisible          ← la garde de B-1 fonctionne
[SONDE] P-1 mettreDeCote() sous verrou => leve=PathAccessException
[SONDE] P-1 cible toujours la ? true
[SONDE] P-1 charger() => 0 echeance(s), NE LEVE PAS          ← l'application s'ouvre
[SONDE] P-1 creer() sous verrou => estReussi=false           ← ✅ L'ECRITURE EST REFUSEE
[SONDE] P-1 >>> document INTACT octet pour octet ? true      ← ✅ DONNEES PRESERVEES
[SONDE] P-1 fichiers = [echeances.json]                      ← aucune copie, rien n'a bougé
[SONDE] P-1 apres deverrouillage : charger()=0 creer()=true  ← ✅ S'AUTO-REPARE
[SONDE] P-1 fichiers finaux = [echeances.json, echeances.json.illisible-1786980490521569]
```

**Contrôle négatif `P-2`** *(⛔ sans lui, un dépôt qui refuserait TOUJOURS d'écrire passerait)* :

```
[SONDE] P-2 charger()=0 creer()=true
[SONDE] P-2 fichiers = [echeances.json, echeances.json.illisible-1786980490575151]
```

⇒ **la sonde BASCULE avec l'obstacle**, dans les deux sens. Comparé au verdict de mon prédécesseur sur
la même sonde *(`creer() => estReussi=true` · `illisible ECRASE ? true`)*, **l'inversion est totale**.

**Et ce n'est pas une propriété accidentelle** — les **deux** façons de réintroduire `B-2` sont
**TUÉES par les tests livrés** :

| Mutant | Ce qu'il conteste | Sortie littérale | Verdict |
|---|---|---|---|
| **`M-2`** — `documentNeuf` **INCONDITIONNEL** *(le défaut d'origine, littéralement)* | « le correctif est ce qui refuse l'écriture » | `00:12 +97 -3: Some tests failed.` | 🟢 **TUÉ, 3 tests** |
| **`M-3`** — `_tenterMiseDeCote` rend **`true`** dans son `catch` | « c'est la **VALEUR** rendue qui porte le refus, pas la structure » | `00:09 +97 -3: Some tests failed.` | 🟢 **TUÉ, 3 tests** |

🔬 **`M-3` est celui qui compte** : il prouve que la conversion `exception → booléen` est **lue**, et
pas seulement **écrite**. ⇒ **`NB-I` disparaît avec `B-2`** — le `catch` **n'a plus un corps de
commentaires** : il porte un `return false` **instrumentable**, donc **visible de la couverture**.

### 3.3 `NB-E` — fermé **sur le chemin du `rename`**, **OUVERT** sur l'interruption *(portée vérifiée)*

**Ce qui est fermé**, mesuré et défendu par un test *(`M-4` **TUÉ**)* :

```
[SONDE] P-3a rename echoue => leve=PathAccessException
[SONDE] P-3a fichiers = [echeances.json]        ← le .tmp a DISPARU (seul l'obstacle reste)

### M-4 NB-E : plus de menage du .tmp
  test EXIT=1 | 00:08 +99 -1: Some tests failed.   >>> TUE
   TUE PAR : … 🔴 NB-E — un `rename` qui ÉCHOUE ne laisse AUCUN `.tmp` porteur des données
             du pratiquant, et l'échec est RELANCÉ
```

**Ce qui reste OUVERT — la question exacte posée à ce tour, et la réponse est MESURÉE** :

```
[SONDE] Q-4 charger() => 0 echeance(s)
[SONDE] Q-4 apres 1 demarrage, orphelin encore la ? true
[SONDE] Q-4 apres 4 demarrages SANS ecriture, fichiers = [echeances.json.tmp]
[SONDE] Q-4 >>> la donnee privee est-elle TOUJOURS lisible sur disque ? true
```

⇒ **un `.tmp` déposé par une interruption brutale du processus PERSISTE indéfiniment**, porteur des
données du pratiquant, à un nom **prévisible**, dans un répertoire que `N-2` dit **partagé**. ⛔ **Le
correctif ne pouvait pas le fermer** *(il n'y a plus de processus pour faire le ménage)*, et
**@Developer l'écrit lui-même en C6** — *« la rémanence n'est fermée que sur le chemin du `rename` »*.
✅ **Elle s'auto-résorbe à la première écriture réussie** *(mesuré `P-3c` : après une écriture,
`fichiers = [echeances.json]`)*. **Constat confirmé, ⛔ pas un finding nouveau.**

### 3.4 `NB-F` et `NB-G` — la boucle regarde bien le **TYPE**, la destination reste **PRÉVISIBLE**

```
[SONDE] P-4 NB-F File().existsSync() sur repertoire = false        ← la confusion d'origine
[SONDE] P-4 NB-F lire() => DocumentIllisible  (attendu Illisible)  ← ✅ corrigé
[SONDE] P-4 NB-F charger() => 0, NE LEVE PAS
[SONDE] P-4 NB-F creer() => estReussi=false                        ← ✅ non destructif
[SONDE] P-4 NB-F repertoire intact ? true ; fichiers=[echeances.json]

[SONDE] P-4 NB-G destination rang0 OCCUPEE par un repertoire
[SONDE] P-4 NB-G File(dest0).existsSync() = false                  ← la boucle d'avant était AVEUGLE
[SONDE] P-4 NB-G mettreDeCote() => leve=Null (attendu null : rang 1)
[SONDE] P-4 NB-G fichiers = [echeances.json.illisible-1786431600000000,
                             echeances.json.illisible-1786431600000000-1]
```

⇒ **`File.existsSync()` rend `false` et la boucle l'esquive quand même** : c'est bien
`FileSystemEntity.typeSync` qui est lu. `M-5` et `M-6` *(retours aux `existsSync`)* sont **TUÉS,
chacun par son propre test**.

⚠️ **`followLinks: false` n'est PAS exercé** : la création d'un lien symbolique est **refusée sur ce
poste** *(`FileSystemException`, privilège absent)* ⇒ **le cas « lien mort à la destination » reste
NON MESURÉ** — borne inscrite au §8.

⚠️ **La destination reste PRÉVISIBLE**, comme `N-1` le dit et comme C5 l'assume explicitement. **Deux
faits neufs la concernent — voir `NB-K` au §5.2.**

### 3.5 🔬 La **piste nº 5** de l'orchestrateur — **MESURÉE, et elle est FAUSSE dans sa seconde moitié**

La piste demandait : *le `throw FileSystemException('Aucun nom libre…')` est-il défendu par un test, et
un `return` muet y reproduirait-il `B-2` ?*

**Réponse mesurée, dans les deux moitiés** :

1. **Oui, un `return` muet y reproduirait `B-2` en nature** — le contrat du port l'énonce, et le
   mécanisme est identique *(`mettreDeCote` rendrait normalement ⇒ `_tenterMiseDeCote` rendrait `true`
   ⇒ `documentNeuf` ⇒ écriture autorisée par-dessus un document toujours présent)*.
2. ⛔ **NON, la branche n'est PAS sans défense — et c'est le contraire qui était supposé.** Le mutant
   **`M-1`** *(le `throw` remplacé par un `return;` muet)* est **TUÉ par DEUX tests** :

```
### M-1 return muet a la borne de mettreDeCote
  analyze ROUGE ? False
  test EXIT=1 | 00:07 +98 -2: Some tests failed.   >>> TUE
```

Et `M-8` *(la borne portée de `essaisMiseDeCote` à `100000`)* est **TUÉ** lui aussi ⇒ **la valeur de la
borne est LUE par les tests, pas recopiée**. La branche est en outre exercée de bout en bout depuis le
dépôt *(`P-5`)* :

```
[SONDE] P-5 essaisMiseDeCote (lu du code) = 8, tous occupes
[SONDE] P-5 mettreDeCote() => leve=FileSystemException
[SONDE] P-5 charger() => 0, NE LEVE PAS
[SONDE] P-5 creer() => estReussi=false  acte=ActeEcriture.enregistrement
[SONDE] P-5 >>> document INTACT octet pour octet ? true
```

⇒ **la piste était légitime et son résultat est NÉGATIF.** ⛔ **Elle est dite fausse**, conformément
au précédent du projet *(une piste d'orchestrateur s'est déjà révélée fausse et a été dite telle)*.

---

## 4. 🔬 **LA QUESTION CENTRALE DU TOUR** — la famille est-elle refermée ?

**Méthode : énumération EXHAUSTIVE, ⛔ pas un échantillon.** Tous les sites de `catch` / `throw` /
`rethrow` de `lib/`, extraits par commande :

```
$ grep -rn "catch\|on Object\|on FileSystemException\|on FormatException\|rethrow\|throw " lib/
```

**9 sites de contrôle de flux d'erreur**, chacun classé :

| # | Site *(désigné par son texte)* | Forme | Verdict |
|---|---|---|---|
| 1 | `document_store_io.dart` — `lire()`, `on FileSystemException` | **convertit** en `DocumentIllisible` | ✅ typé, **étroit par choix** |
| 2 | `document_store_io.dart` — `ecrire()`, `on Object` autour du `rename` | ménage puis **`rethrow`** | ✅ **l'échec n'est jamais perdu** |
| 3 | `document_store_io.dart` — `ecrire()`, `on Object` autour de `provisoire.delete()` | **corps de commentaires** | ⚠️ n'avale que l'échec du **ménage** ; l'échec réel est **relancé** *(site 2)* — **résidu = `NB-E`** |
| 4 | `document_store_io.dart` — la **borne** de `mettreDeCote()` | **`throw`** | ✅ défendu *(§3.5)* |
| 5 | `document_store_stub.dart` — `ecrire` / `mettreDeCote` | **`throw UnsupportedError`** | ✅ par conception |
| 6 | `echeance_document_codec.dart` — `lireRacine`, `on FormatException` | rend **`null`** | ✅ typé |
| 7 | `echeance_schema_migrations.dart` — `instantVersCivil`, `on FormatException` | rend **`null`** | ✅ typé |
| 8 | `echeance_document_repository.dart` — `_ecrire`, `on Object` | rend **`ResultatEcriture.echec(acte)`** | ✅ **refus TYPÉ** |
| 9 | `echeance_document_repository.dart` — `_tenterMiseDeCote`, `on Object` | rend **`false`** | ✅ **c'était `B-2`, désormais converti** |
| **10** | `echeance_document_repository.dart` — **`charger()`, la réécriture post-migration**, `on Object` | 🔴 **corps de commentaires** | **LE SEUL RESTANT — mesuré ci-dessous** |

⇒ **Un seul `on Object` à corps de commentaires subsiste dans toute la couche** *(site 10)*, plus le
site 3 qui est un sous-cas du ménage. **C'est exactement la forme où `B-2` habitait.** ⛔ **Je ne l'ai
pas jugé sur sa forme : je l'ai déclenché.**

**Déclencheur** : un document **`v1` réel** sur le disque, un **répertoire occupant `echeances.json.tmp`**
pour faire échouer la réécriture qui suit la migration montante.

```
[SONDE] P-6 charger() => 1 echeance(s) — migration v1->v2 SERVIE
[SONDE] P-6 disque encore en v1 ? true
[SONDE] P-6 la reecriture a-t-elle ete AVALEE ? true          ← l'avalement est CONFIRMÉ
[SONDE] P-6 creer() apres reecriture avalee => estReussi=true ← l'écriture est AUTORISÉE
[SONDE] P-6 disque final version = v2
[SONDE] P-6 >>> le RESIDU v1 a-t-il SURVECU ? true            ← ✅
[SONDE] P-6 >>> la donnee m1 a-t-elle SURVECU ? true          ← ✅
[SONDE] P-6 fichiers = [echeances.json]
```

**Et le cas le plus tendu de cette classe** — une entrée `v1` **NON INVERSIBLE** *(secondes non
nulles : `22:59:30Z`, précisément ce que la garde d'inversibilité refuse de convertir)*, donc
**dégradée en résidu**, dans le même scénario de réécriture avalée :

```
[SONDE] Q-3 charger() => 1 reconnue(s) : [ok]
[SONDE] Q-3 reecriture avalee (disque en v1) ? true
[SONDE] Q-3 creer() => true
[SONDE] Q-3 >>> les 30 SECONDES ont-elles SURVECU ? true      ← ✅ octets préservés
[SONDE] Q-3 >>> l entree inversible est-elle en CIVIL ? true
[SONDE] Q-3 >>> la neuve est-elle la ? true
```

🔬 **VERDICT SUR LA FAMILLE : refermée sur son axe destructif.** Le dernier avalement **autorise**
bien une écriture ultérieure — comme `B-2` — mais **le disque qu'elle réécrit est un document
PARFAITEMENT LU**, dont **toutes** les entrées reconnues **et** tous les résidus sont **transportés**
*(`R-2`)*. ⛔ **Il n'y a donc rien à écraser** : la différence avec `B-2` n'est pas de degré, elle est
de nature — `B-2` écrivait par-dessus un document **qu'on n'avait PAS su lire**.

⚠️ **Mais ce comportement n'est assertionné dans AUCUN sens** — voir le survivant **`M-9`** au §5.4.

---

## 5. Findings NON BLOQUANTS **nouveaux**

| # | Outil | Fichier *(désigné par son TEXTE, ⛔ jamais par un numéro de ligne)* | Sév. | Décision |
|---|---|---|---|---|
| `NB-K` | Sondes `Q-2`, `C-1`, `K-1`→`K-3` | `document_store_io.dart` — `mettreDeCote()`, la boucle `if (FileSystemEntity.typeSync(destination, …) != …notFound) continue;` puis `await cible.rename(destination)` | **MEDIUM** | **Accepté** — famille `N-1`, ⛔ **aucune séquence destructive atteinte depuis le produit** |
| `NB-L` | `grep` + mutants `M-10`, `M-11`, `M-12` | `document_store_io.dart` — `ecrire()`, l'instruction `await provisoire.delete();` | LOW | **Accepté** — correct par construction |
| `NB-M` | Mutant `M-9` + sondes `P-6`, `Q-3` | `echeance_document_repository.dart` — `charger()`, le `on Object` de la **réécriture post-migration** | LOW | **Accepté** ➡️ à couvrir avec `NB-E` |
| `NB-N` | Incident d'exécution | `/audit-us` — **le rituel** et les lanceurs de mutants, ⛔ pas ce code | LOW | ➡️ **`/audit-methodo`** |

### 5.1 `M-7` *(= `M-E4` de @Developer)* — **SURVIVANT confirmé**, et sa **caractérisation est VÉRIFIÉE**

@Developer **nomme lui-même** ce survivant en C6 et affirme que *« la différence est INOBSERVABLE »*.
⛔ **Je ne l'ai pas cru sur parole : je l'ai mesuré**, en jouant le mutant contre **trois** classes
d'occupant du nom du provisoire, et en comparant **témoin ↔ mutant** :

```
===== CODE LIVRE (try ETROIT) =====            ===== MUTANT M-7 (try ELARGI) =====
[M7-a] repertoire   | occupant survit ? true   [M7-a] repertoire   | occupant survit ? true
[M7-b] fichier tiers RO | survit ? true        [M7-b] fichier tiers RO | survit ? true
[M7-c] fichier tiers verrouille | survit ? true [M7-c] fichier tiers verrouille | survit ? true
```

⇒ ✅ **la caractérisation de @Developer est EXACTE, et elle est même plus large qu'il ne l'écrit** :
il justifie par *« `File.delete` refuse un répertoire »*, or l'occupant survit **aussi** s'il est un
**fichier tiers en lecture seule** ou **verrouillé**. **La primitive, elle, est bien destructrice** —
mesuré isolément :

```
[SONDE] Q-1 File(repertoire).delete() => leve=PathAccessException | survit ? true
[SONDE] Q-1 repertoire NON VIDE .delete() => leve=PathAccessException | survit=true
[SONDE] Q-1 FICHIER tiers .delete() => leve=Null | survit=false   <<< DETRUIT sans discuter
```

⇒ **le `try` étroit n'est pas seulement « non testable », il est STRICTEMENT PLUS SÛR**, et **le
commentaire du code donne la bonne raison** *(« il n'efface que ce que cet appel a créé »)*.
**Survivant NON REPRÉSENTABLE sous Windows**, ⛔ pas un test manquant.

### 5.2 🔴 `NB-K` — **`File.rename` ÉCRASE SILENCIEUSEMENT sous Windows AUSSI**, et cela réfute une phrase écrite

**Fait mesuré, contre-intuitif, et qui contredit `security_delta.md`** — dont le §7 écrivait *« les
mécanismes d'échec du `rename` **diffèrent** sous POSIX *(un `rename` y écrase silencieusement…)* »*,
laissant entendre que **Windows, lui, refuserait**. ⛔ **C'est faux, et voici la mesure** :

```
[SONDE] Q-2 rename sur destination EXISTANTE => leve=Null
[SONDE] Q-2 contenu de la destination = NOUVEAU
[SONDE] Q-2 >>> l anterieure a-t-elle ete ECRASEE ? true
[SONDE] Q-2 plateforme = windows
```

**Conséquence exacte** : la promesse écrite dans le code — *« Le nom ne doit JAMAIS écraser une mise de
côté antérieure »* — **ne repose sur AUCUNE garantie du système**. Elle repose **entièrement** sur la
boucle `typeSync`, qui **n'est pas atomique** *(fenêtre TOCTOU entre le test et le `rename`)*.

**Second fait, qui aggrave l'apparence sans aggraver le fond** — l'espace des noms est **1000 fois plus
étroit que le format ne le suggère** :

```
[SONDE] C-1 20000 appels => 4 valeurs DISTINCTES
[SONDE] C-1 plus petit pas NON NUL = 1006 us
[SONDE] C-1 tous multiples de 1000 us ? false
[SONDE] C-1 plateforme = windows
```

⇒ `microsecondsSinceEpoch` porte un suffixe à **16 chiffres** mais l'horloge a une granularité
**≈ 1 ms** sur ce poste. **La destination est donc bien plus prévisible que son nom ne le laisse
croire.**

⛔ **ET POURTANT, JE N'AI PAS PU DÉTRUIRE UNE MISE DE CÔTÉ DEPUIS LE PRODUIT — je l'ai cherché** :

```
[K-1] apres A : [echeances.json.illisible-1786431600000000]
[K-1] apres B : [echeances.json.illisible-1786431600000000, …-1]
[K-1] contenus = [DOCUMENT nº1 DU PRATIQUANT, DOCUMENT nº2 DU PRATIQUANT]
[K-1] >>> les DEUX documents survivent ? true      ← MEME horloge figée, MEME milliseconde

[K-2] rename direct sur destination occupee => leve=Null
[K-2] >>> l anterieure a-t-elle ete DETRUITE ? true ← ⚠️ mais ceci mesure la PRIMITIVE

[K-3] contenus = [MISE DE COTE ANTERIEURE, NOUVEAU DOCUMENT]
[K-3] >>> l anterieure SURVIT ? true                ← ✅ LE PRODUIT, LUI, PROTEGE
```

⇒ **la boucle fait son travail** : elle voit l'occupant et passe au rang suivant. **Le résidu est une
COURSE** — il faudrait qu'un acteur concurrent crée la destination **exacte** dans la fenêtre entre le
`typeSync` et le `rename`. **Je n'ai pas atteint cette séquence.**

**Classement, et il applique la règle du projet** : *« un déclencheur EXÉCUTÉ bat un raisonnement »* —
**la réciproque vaut aussi**. J'ai **la primitive** et **le raisonnement**, ⛔ **pas le déclencheur** ⇒
**MEDIUM, NON BLOQUANT**. ⚠️ **Ce serait malhonnête d'en faire un bloquant, et malhonnête de le taire.**
**Remède, identique à `N-1`** : création en **exclusif** *(`FileMode.writeOnlyAppend` + échec si
existe)* ou **suffixe aléatoire** — décision qui appartient à `N-1`, **hors périmètre**.

### 5.3 `NB-L` — un **`delete` est entré dans `lib/`**, pour la première fois du projet

`grep` : `document_store_io.dart` → `await provisoire.delete();`. **Fait nouveau** — le rapport
précédent pouvait écrire *« aucun appel de suppression de fichier dans toute la couche `data` »*,
**ce n'est plus vrai**. Or **AC-11 « Limite » dit « JAMAIS un `delete` »** *(du document)*.

**✅ Correct par construction, et vérifié** : la cible est `_provisoire`, construit **uniquement** de
`_cible.path + '.tmp'`, lui-même bâti sur `const String nomDocument` et le répertoire de
`path_provider` ⇒ **aucune composante contrôlée par l'utilisateur**, **jamais** le document, **jamais**
une mise de côté.

**Défendu par mutation** :

| Mutant | Sortie | Verdict |
|---|---|---|
| **`M-10`** — supprimer **LA CIBLE** au lieu du provisoire | `+92 -1` — tué par *« 🔴 NB-E — un `rename` qui ÉCHOUE ne laisse AUCUN `.tmp` … »* | 🟢 **TUÉ** |
| **`M-12`** — faire le ménage **AUSSI quand le `rename` RÉUSSIT** | `+81 -12` — **12 tests rouges** | 🟢 **TUÉ** |
| **`M-11`** — supprimer la cible **EN PLUS** du provisoire | `+93` — **All tests passed** | ⚠️ **SURVIVANT** |

⛔ **`M-11` est NON REPRÉSENTABLE sous Windows, et c'est MESURÉ, pas supposé** — j'ai joué le mutant
contre les trois classes d'échec du `rename` :

```
===== CODE LIVRE (temoin) =====             ===== MUTANT M-11 =====
[M11-a] cible = REPERTOIRE  | survit ? true [M11-a] cible = REPERTOIRE  | survit ? true
[M11-b] cible = VERROUILLEE | survit ? true [M11-b] cible = VERROUILLEE | survit ? true
[M11-b] contenu = DONNEES DU PRATIQUANT     [M11-b] contenu = DONNEES DU PRATIQUANT
[M11-c] cible = LECTURE SEULE | survit ? true [M11-c] cible = LECTURE SEULE | survit ? true
```

🔬 **La raison est structurelle et vaut d'être écrite** : **les conditions qui font échouer le `rename`
sont exactement celles qui font échouer le `delete`**. La propriété « la cible survit à un `rename`
échoué » tient donc par **coïncidence de plateforme**, ⛔ **pas par un test**. ⚠️ **À rejouer sous
POSIX**, où `unlink` ne demande que le droit d'écriture sur **le répertoire** *(un fichier en lecture
seule y EST supprimable)* ⇒ **la coïncidence pourrait ne pas tenir**.

### 5.4 `NB-M` — le dernier `on Object` à corps de commentaires n'est assertionné **dans aucun sens**

```
### M-9 migration : reecriture avalee -> ecriture REFUSEE ensuite
  conteste : le comportement actuel du dernier catch a corps vide est-il ASSERTIONNE ?
  analyze ROUGE ? False | test EXIT=0 | 00:03 +100: All tests passed!   >>> SURVIVANT
```

Remplacer le corps par `_document = null;` — c'est-à-dire **inverser la décision produit** *(refuser
toute écriture après une réécriture de migration échouée)* — laisse **100 tests verts**.
⇒ **rien ne défend le choix actuel**, et **rien ne défendrait le choix inverse**. ⛔ **Ce n'est PAS une
perte de données** *(mesuré §4)* : c'est un **angle mort d'assertion** sur le dernier membre de la
famille. **Sixième instance de « la couverture est aveugle »** : ce `catch` **n'a aucune ligne à
instrumenter**, donc **même à 100 % rien ne signalerait qu'il n'est jamais emprunté** — exactement
`NB-I`, sur le site **survivant**.
**Remède court** : un test qui fait échouer la réécriture post-migration et assertionne les **trois**
choses mesurées en `Q-3` *(données servies · disque en `v1` · écriture ultérieure non destructive)*.

### 5.5 `NB-N` — la restauration d'un mutant doit vivre dans un `finally`, et l'encodage tue les lanceurs

Détaillé au §2. **Observé, ⛔ pas déduit** : mon lanceur est mort sur `cp1252` **entre** l'application
du mutant et la restauration, laissant `lib/` **muté**. **Deux remèdes, tous deux triviaux** :
`PYTHONIOENCODING=utf-8`, et **restauration en `finally`**. ➡️ **`/audit-methodo`**, au dossier
mutation — **avec `NB-H`**, dont ce rapport est la première application : ✅ **l'isolation par
`git worktree` a fonctionné**, et **cet incident en est la démonstration**.

---

## 6. Statut des findings précédents — **re-mesuré, ⛔ pas recopié**

| # | Objet | Statut au `28d9504` | Aggravé ? |
|---|---|---|---|
| `N-1` | `.tmp` prévisible, suit un lien symbolique | **OUVERT** — arbitré **hors périmètre** par C5/C6, qui le disent | **NON.** ⚠️ Mais **`NB-K`** montre que la prévisibilité porte plus loin qu'on ne croyait *(§5.2)* |
| `N-2` | `Documents` partagé (Win/Linux), iCloud (iOS) | **OUVERT** ➡️ @PO / US-01.3 | **NON** par le code. ⚠️ **Reste le terrain de `NB-E` et `NB-K`** |
| `N-3` | `check_e2e_persistance.py` absent de la CI | **OUVERT** — `grep -rn "check_e2e_persistance" .github/` → **exit 1, vide** | **NON** |
| `N-4` | « ses **24 paquets transitifs** » écrit à la main | **OUVERT** — `pubspec.yaml:41` porte toujours la phrase ; la mesure §1.3 donne **24 ajoutés dont 23 transitifs** *(`path_provider` est direct)* | **NON** |
| `N-5` | Chemin de poste en dur, dépôt **public** | **OUVERT** — `reports/US-01.2/generer_e2e.py:13` : `RACINE = Path(r"c:/Users/guillaume.decroix/…")` | **NON** |
| `N-6` | Aucune borne de taille **à la lecture** | **OUVERT**, re-mesuré : `description 4 Mo => reconnues=1 longueur lue=4000000` | **NON** |
| `N-7` | `codec.decoderDocument(migrer(racine)!)` | **OUVERT** — le `!` demeure. ✅ **Balayage : INATTEIGNABLE** *(`Q-5`, 9 formes de `schemaVersion` : `0, 1, 2, 3, 99, -1, "2", 2.0, null` ⇒ **`leve=Null` 9 fois sur 9**)* — protégé par les **gardes amont**, ⛔ pas par le type | **NON** |
| `N-8` | Le port n'impose ni la limite de 9 ni les 80 caractères | **OUVERT** | **NON** |
| `N-9` | Permissions du fichier créé | **NON MESURÉ**, borne **maintenue** *(Windows rend une valeur synthétique)* | **NON** |
| `N-10` | `U+202E` accepté en description | **OUVERT**, re-mesuré : `RLO => reconnues=1` | **NON** |
| `NB-D` | Le commentaire qui légitimait l'avalement | ✅ **FERMÉ** — le motif réel est écrit, le stub n'est plus invoqué *(lu dans `_tenterMiseDeCote`)* | — |
| `NB-I` | `catch` au corps vide, invisible à la couverture | ✅ **FERMÉ SUR LE SITE DE `B-2`** *(`return false` est instrumentable)* · ⚠️ **le mécanisme SUBSISTE** sur le site de la migration ⇒ **`NB-M`** | — |
| `NB-H` | Audits parallèles sur un seul arbre | ✅ **TRAITÉ pour cet audit** *(worktree dédié)* · ⛔ **le rituel ne l'impose toujours pas** ➡️ `/audit-methodo` | — |

⇒ ✅ **Aucun finding précédent n'est aggravé.** **`NB-E`, `NB-F`, `NB-G`, `NB-J`, `NB-D`** sont
**vérifiés fermés dans leur périmètre annoncé**, chacun par un mutant TUÉ.

---

## 7. Ce que cet audit a **re-vérifié et trouvé BON** — par exécution

⛔ **Rien de ce paragraphe n'est repris des rapports précédents : tout est ré-exécuté sur `28d9504`.**

```
[SONDE] P-7 N-6 description 4 Mo => reconnues=1 longueur lue=4000000
[SONDE] P-7 N-10 RLO => reconnues=1
[SONDE] P-7 N-7 v1 vide => reconnues=0, NE LEVE PAS
[SONDE] P-7 traversee dans id => reconnues=1 fichiers=[echeances.json]
```

* ✅ **Aucune traversée de répertoire** : `../../../../etc/passwd` en `id` reste **un identifiant** —
  `fichiers=[echeances.json]`, **aucun fichier créé ailleurs**.
* ✅ **Écriture atomique préservée** : la cible n'est **jamais ouverte en écriture**, et le refus est
  **TYPÉ** *(⛔ jamais `void`, ⛔ aucune mise à jour optimiste)* — re-mesuré `P-3`, `P-4`, `P-5`.
* ✅ **Aucune fuite d'information dans les messages** : `estReussi=false` porte
  `acte=ActeEcriture.enregistrement`, ⛔ aucun chemin, ⛔ aucun nom de fichier, ⛔ aucun type
  d'exception. La fuite de chemin absolu qu'`M1` avait révélée au 2ᵉ tour **reste fermée**.
* ✅ **`R-2` tient** : résidus et clés inconnues **transportés**, y compris à travers une **migration
  montante** et une **réécriture échouée** *(`P-6`, `Q-3`)*.
* ✅ **Le refus est CONDITIONNEL et RÉVERSIBLE** — jamais un cul-de-sac : `P-1` et `P-5` montrent
  l'auto-réparation dès l'obstacle levé.

---

## 8. ⛔ Ce que cet audit **N'ATTESTE PAS**

* ⛔ **Aucun SAST n'a tourné : il n'en existe pas** *(exit 1, §1.1, re-vérifié)*. **Toute la revue est
  HUMAINE, donc NON EXHAUSTIVE.** ⚠️ **Et l'historique interdit de sur-lire ce `PASSED`** : les deux
  tours précédents ont **chacun** trouvé un bloquant HIGH **qu'aucun gate n'avait vu**, et le second
  était **pré-existant au premier**. **Un troisième défaut de la même nature ne serait pas contredit
  par ce rapport.**
* ⛔ **AUCUN SCAN DE CVE, sur RIEN.** Les **24 paquets** ajoutés par cette US *(dont `jni`,
  `objective_c`, `crypto`, `yaml`, `ffi`)* entrent dans le produit **sans qu'aucune base de
  vulnérabilités n'ait été consultée**. Le Python de `scripts/` et de `reports/` n'est couvert par
  **aucun outil**. ⇒ **la mention « pas de CVE » est absente de ce rapport parce qu'elle serait un
  mensonge.** ⚠️ **`deps_audit` porte `blocking: false`** : même s'il détectait quelque chose, **il ne
  bloquerait pas**.
* ⛔ **`main()` n'a PAS été exécuté** *(`NM-8`, `path_provider` absent en test hôte)*. Le niveau atteint
  est **`charger()` / `creer()` sur le magasin `io` réel**. Que `runApp` s'exécute et que **le hub se
  dresse** reste **NON OBSERVÉ**.
* ⛔ **L'application n'a jamais tourné sur un appareil** *(`NM-10`, entière)* ni **sur le web**
  *(`flutter build web --release` **construit** et **n'exécute jamais**)*. **Aucun écran n'a été vu.**
* ⛔ **TOUT EST MESURÉ SOUS WINDOWS, et deux findings en dépendent explicitement** : `M-7` et `M-11`
  sont **non représentables ici** parce que `File.delete` échoue là où le `rename` échoue — ⚠️ **sous
  POSIX, `unlink` ne demande que le droit sur le RÉPERTOIRE** ⇒ **la coïncidence pourrait ne pas
  tenir**. **`NB-K` doit être rejoué sous POSIX**, où le `rename` écrase **aussi**.
* ⛔ **`followLinks: false` n'est PAS exercé** : la création d'un lien symbolique est **refusée sur ce
  poste** *(privilège absent)* ⇒ le cas **« lien mort à la destination »** de `NB-G` reste **NON
  MESURÉ**, et `N-1` *(lien symbolique)* reste **non exécuté**, comme aux deux tours précédents.
* ⛔ **Aucune mesure de CONCURRENCE RÉELLE.** `P-1` **provoque** un conflit d'accès et `K-1` joue deux
  magasins, mais **deux PROCESSUS écrivant simultanément** n'ont pas été testés. **La fenêtre TOCTOU de
  `NB-K` n'a donc pas été franchie** — ⛔ **elle n'a pas non plus été réfutée.**
* ⛔ **`N-9` reste non mesurable ici** *(permissions : Windows rend une valeur synthétique)*.
* ⛔ **Je n'ai vérifié aucun `.github/workflows/**`** : cette US n'en touche **aucun** *(mesuré, §1.0)*.
  Les findings ouverts d'US-00.7 *(actions non épinglées, `emitter` non enforcé, `enforce_admins`,
  `NB-1bis`)* sont **NON AGGRAVÉS et NON RECOMPTÉS**.
* ⛔ **Une énumération n'est pas une preuve d'exhaustivité.** Le §4 énumère les **9 sites** que
  `grep` trouve pour un jeu de motifs **que j'ai choisi**. Un chemin d'erreur exprimé **autrement**
  *(un `?.`, un `??`, une valeur par défaut silencieuse, un `Future` non attendu)* **n'y figure pas**.
  ⚠️ **`unawaited_futures` est actif mais sa portée est PARTIELLE** *(acquis du design : il ne voit
  rien dans un appelant synchrone)*.
* ⛔ **Ce visa porte sur `28d9504` (code) et `b77e3cf` (HEAD), et sur rien d'autre** *(**NB-6** :
  `trace_append.py --help` **ne montre aucune option `--commit`**, §1.7)*. **Aucune machine ne pourra
  signaler qu'il a périmé** : tout commit ultérieur touchant `lib/`, `test/`, `scripts/` ou `pubspec*`
  **invalide ce rapport, en silence**.

---

## 9. Restauration de l'état — **isolation, et ce qu'elle prouve**

```
$ git status --porcelain                   (MON worktree, après suppression des sondes)
[fin]                                      ← VIDE

$ git diff --stat -- lib test
[fin]                                      ← aucun fichier suivi modifié

$ git rev-parse HEAD
b77e3cf51e19b453a2500c69b6bc380181f3bcfc
```

* **Worktree dédié**, détaché sur `b77e3cf` — ⛔ **aucun fichier de l'arbre principal touché** par
  aucune sonde ni aucun mutant.
* **4 fichiers de sonde** créés sous `test/` du worktree *(`zz_sonde_secu_delta2`,
  `…2b`, `…2c`, `zz_nbk`)*, plus 2 temporaires *(`zz_m7`, `zz_m11`)* — **tous supprimés**.
* **14 mutants** joués, **restauration vérifiée après CHACUN** : `git status --porcelain` relevé
  **14 fois**, **VIDE 14 fois** *(la seule entrée observée en cours de campagne était mon propre
  fichier de sonde, `?? test/zz_sonde_secu_delta2_test.dart`)*. ⚠️ **Une exception, dite au §2** :
  l'incident `cp1252` a laissé l'arbre **muté** le temps d'un constat, **restauré immédiatement** —
  `git status` avant/après **collé au §2**.
* ⛔ **Non touchés** : `STORY_CERTIFICATION_BOARD.md`, `PROJECT_LOG.md`, `factory.config.json`,
  `lib/`, `test/`, `scripts/` de l'arbre principal. **Jamais `--no-verify`. Aucun commit.**
* Sorties de cet audit, dans l'arbre principal : **`reports/US-01.2/security_delta2.md`** *(ce fichier,
  **NOUVEAU** — ⛔ `security.md` et `security_delta.md` ne sont **pas** écrasés, leurs `FAILED` restent
  lisibles)* et **une ligne** dans `docs/trace/US-01.2/events.jsonl`.

---

## 10. Recommandations — ⛔ **aucune n'est bloquante**

1. **`NB-M`** *(court, à faire avec le prochain correctif)* — un test sur la **réécriture
   post-migration échouée**, assertionnant les trois faits de `Q-3`. **Sinon le dernier membre de la
   famille reste sans assertion dans aucun sens.**
2. **`NB-K`** ➡️ **à verser à `N-1`**, qui devient plus large qu'écrit : la fermeture demande une
   **création en exclusif** ou un **suffixe aléatoire**. ⚠️ **Et à rejouer sous POSIX.**
3. **`NB-L`** ➡️ **rejouer `M-11` sous POSIX** : la non-représentabilité mesurée est une propriété
   **de Windows**, pas du code.
4. **`NB-N`** ➡️ **`/audit-methodo`**, avec **`NB-H`** : `PYTHONIOENCODING=utf-8` et restauration en
   `finally` sur tout lanceur de mutants ; **inscrire l'isolation par `git worktree` dans le rituel**
   plutôt que dans la discipline d'un auditeur.
5. **Inchangé et prioritaire** : **aucun SAST**, **aucun scan de CVE**. ⇒ **US-00.8 /
   `/audit-methodo`** — c'est la borne qui rend ce `PASSED` étroit.
