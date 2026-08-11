# Re-audit sécurité (delta) — US-01.2 « Gestion des échéances (CRUD) »

| Champ | Valeur |
|---|---|
| **Verdict** | 🔴 **FAILED** |
| **Agent** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | claude-opus-5[1m] (Opus 5, 1M context) |
| **Date** | 2026-08-11 |
| **Commits audités** *(NB-6 : `trace_append.py` n'a **aucune** option `--commit`, vérifié par `--help` ⇒ les SHA vivent dans le `rationale`)* | **code = `2d77778`** · **HEAD = `c2a5d0d`** *(branche `feat/US-01.2-design`)* |
| **Périmètre** | `git diff main...HEAD` — **tout** le code, pas seulement le delta. Delta prioritaire : `git diff 5272ed1..2d77778` |
| **Rapport précédent** | [`security.md`](security.md) — verdict `FAILED` sur `5272ed1`. ⛔ **Non écrasé** |
| **Statut de `B-1`** | ✅ **FERMÉ** — prouvé par exécution *(§2)*, sur le magasin `io` **de production**, avec contrôle négatif et **3 mutants tués** |
| **Motif du verdict** | **1 finding BLOQUANT NOUVEAU** — `B-2` : quand la **mise de côté échoue**, le dépôt **avale l'échec** puis **autorise l'écriture** ⇒ le document illisible est **ÉCRASÉ EN SILENCE**. **Réfutation littérale d'AC-11 « Erreur » (Must)**. ⚠️ **PRÉ-EXISTANT à `5272ed1` — mesuré, ⛔ pas supposé** : ce n'est **pas** une régression du correctif, c'est un défaut que le correctif **rend atteignable par la classe réaliste** et que **mon prédécesseur a manqué** |

> ⚖️ **Ce verdict ne dévalue pas le correctif de `B-1`, qui est bon et mieux que ce que
> l'audit précédent demandait.** Le type scellé, le `switch` exhaustif et la garde étroite sont
> **prouvés par mutant** *(§2.3)*. `B-2` n'est pas dans le correctif : il est dans le **chemin que le
> correctif emprunte désormais**, et il y était déjà.

---

## 1. Sorties d'outils — brutes, collées

### 1.0 Périmètre : le code est-il figé depuis `2d77778` ? — **OUI, vérifié**

```
$ git rev-parse HEAD
c2a5d0dee0db0693afd58c4a54d4c63f707fc48d

$ git diff --name-only 2d77778..HEAD -- lib test scripts pubspec.yaml pubspec.lock
[fin liste]          ← 0 fichier

$ git log --oneline -6
c2a5d0d docs(us-01.2): peremption des deux visas d audit actee, cellules remises a l attente
cd789d5 chore(us-01.2): EVT_CODE_READY re-emis apres correctif de B-1, NB-B, NB-A
2d77778 fix(echeances): NB-B l'acte reel dans le refus, NB-A la doc dit ce qui EST
ca05128 fix(echeances): B-1 — un document non decodable n'empeche plus le demarrage
eb69b0f docs(us-01.2): /audit-us — revue PASSED, securite FAILED sur B-1
5272ed1 docs(us-01.2): arbitrage humain — le cliquet RESTE a 95,2
```

Fichiers de **production** touchés par le delta *(5, tous lus)* : `document_store.dart`,
`document_store_io.dart`, `document_store_stub.dart`, `echeance_document_repository.dart`,
`echeance_repository.dart`.
⛔ **`.github/**` : 0 fichier touché par cette US** — `git diff --name-only main...HEAD -- .github/`
rend **vide**. ⛔ **`pubspec.yaml` / `pubspec.lock` : 0 fichier touché par le delta** ⇒ la surface de
dépendances est **identique** à celle du rapport précédent, donc ni aggravée ni levée.

### 1.1 `run_gates --gate sast` — ⛔ **LE GATE N'EXISTE TOUJOURS PAS**

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

Liste **lue** dans `factory.config.json` → `adapter.components.app.gates` *(⛔ jamais recopiée)* :

```
format     : dart format --output=none --set-exit-if-changed lib test
analyze    : flutter analyze
test       : flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
deps_audit : dart pub outdated --show-all              blocking= False
build      : flutter build web --release
coverage_ratchet : {"value": 95.2, "date": "2026-08-02", "motif": "PR27"}
```

⇒ **5 gates, aucun SAST.** **Toute la revue de ce rapport est HUMAINE**, donc **non exhaustive** —
et `B-2` en est la démonstration : il a survécu à **un audit sécurité complet**, à **une revue de
code `PASSED`**, à **un visa @Dev**, à **une vérification de @Architect** et à **356 tests**.
⚠️ **`deps_audit` porte `"blocking": false`** *(lu ci-dessus)* : même s'il détectait quelque chose,
**il ne bloquerait pas**.

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
transitive dependencies:
args 2.7.0 · characters 1.4.1 · code_assets 1.2.1 · collection 1.19.1 · crypto 3.0.7 · ffi 2.2.0
hooks *2.0.2 (latest 2.1.0) · jni 1.0.3 · jni_flutter 1.0.2 · jni_util 1.0.0 · logging 1.3.0
material_color_utilities *0.13.0 (latest 0.13.1) · meta *1.18.0 (latest 1.19.0) · objective_c 9.5.0
package_config 3.0.0 · path 1.9.1 · path_provider_android 2.3.1 · path_provider_foundation 2.6.0
path_provider_linux 2.2.2 · path_provider_platform_interface 2.1.3 · path_provider_windows 2.3.0
platform 3.1.6 · plugin_platform_interface 2.1.8 · pub_semver 2.2.0 · record_use *0.6.0 (latest 1.1.0)
sky_engine (sdk) · source_span 1.10.2 · string_scanner 1.4.1 · term_glyph 1.2.2 · typed_data 1.4.0
vector_math *2.2.0 (latest 2.4.2) · xdg_directories 1.1.0 · yaml 3.1.3
transitive dev_dependencies:
async 2.13.1 · boolean_selector 2.1.2 · clock 1.1.2 · fake_async 1.3.3 · leak_tracker 11.0.2
leak_tracker_flutter_testing 3.0.10 · leak_tracker_testing 3.0.2 · lints 6.1.0
matcher *0.12.19 (latest 0.12.20) · stack_trace 1.12.1 · stream_channel 2.1.4
test_api *0.7.11 (latest 0.7.13) · vm_service 15.2.0
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
EXIT=0
```

🔴 **`dart pub outdated` compare des NUMÉROS DE VERSION et ne consulte AUCUNE base de CVE.**
⇒ **aucune ligne de ce rapport ne dit « pas de CVE » : le projet n'a aucun moyen de le savoir.**

### 1.3 Fermeture transitive — **comparée par ENSEMBLES, ⛔ pas par cardinaux**

```
$ (lecture de pubspec.lock à `main` et à `HEAD`, comptage par script)
main : 27 paquets | HEAD : 51 paquets
AJOUTES   24 : ['args', 'code_assets', 'crypto', 'ffi', 'hooks', 'jni', 'jni_flutter', 'jni_util',
 'logging', 'objective_c', 'package_config', 'path_provider', 'path_provider_android',
 'path_provider_foundation', 'path_provider_linux', 'path_provider_platform_interface',
 'path_provider_windows', 'platform', 'plugin_platform_interface', 'pub_semver', 'record_use',
 'typed_data', 'xdg_directories', 'yaml']
RETIRES    0 : []
deps directes declarees : ['sdk', 'flutter', 'cupertino_icons', 'path_provider']
```

⇒ **24 ajoutés**, dont `path_provider` **lui-même** ⇒ **23 transitifs**. Le commentaire de
`pubspec.yaml` dit toujours « ses **24** paquets **transitifs** » — **finding `N-4` du rapport
précédent, INCHANGÉ** *(§5)*.

### 1.4 `run_gates --all` — les 5 gates

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 0.56 seconds.
✅ app.format

▶ app.analyze — (.) $ flutter analyze
No issues found! (ran in 28.6s)
✅ app.analyze

▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
02:24 +356: All tests passed!
Couverture de lignes : 97.9% (938/958) — seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigné le 2026-08-02 — PR27
  [HAUSSE] 97.91% (938/958) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.9
✅ app.test

▶ app.deps_audit  ✅   (§1.2)

▶ app.build — (.) $ flutter build web --release
√ Built build\web
✅ app.build

Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

🔴 **Quatrième confirmation de l'acquis d'US-01.1, et elle porte cette fois sur un bloquant qui
n'est PAS neuf** : **5 gates verts**, **356 tests**, **couverture qui MONTE à 97,9 %** — et `B-2`
est là **depuis avant `5272ed1`**. ⛔ **La couverture est aveugle à ce qui n'a jamais été essayé** :
`B-2` vit dans un `catch` dont **le corps est un commentaire**, donc **sans aucune ligne à
couvrir** — il est **invisible à l'instrument par construction**, pas par malchance.

⚠️ **Fenêtre d'exécution, à ne pas sur-lire** : ce `--all` a tourné sur un arbre **propre**
(`git status --porcelain` vide, vérifié avant lancement). Voir `NB-H` : pendant cet audit, une
session **concurrente** a déposé puis retiré des fichiers de sonde dans `test/`, dont un portant une
**erreur de compilation** — pendant cette fenêtre, `flutter analyze` sur l'arbre partagé aurait été
**ROUGE pour une raison étrangère au produit**.

### 1.5 `gitleaks` — arbre **et** commits

```
$ gitleaks version
8.30.1

$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~189291784 bytes (189.29 MB) in 6.55s
INF no leaks found
EXIT=0

$ gitleaks git --log-opts="main..HEAD" --config .gitleaks.toml --redact -v .
INF 27 commits scanned.
INF scanned ~877961 bytes (877.96 KB) in 2.96s
INF no leaks found
EXIT=0
```

✅ **Aucun secret en dur, aucune fixture porteuse de secret** — y compris dans les **5 nouveaux
commits** (`22 → 27` commits scannés). Les fixtures de `B-1` ajoutées au harnais sont des **octets
de document métier**, jamais un matériel cryptographique.

### 1.6 `validate_trace` et la chaîne d'événements

```
$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
EXIT=0

$ (lecture de docs/trace/US-01.2/events.jsonl)
2026-08-05T10:54:42+02:00 | EVT_STORY_CREATED           | product-owner
2026-08-05T11:03:39+02:00 | EVT_TRACK_SELECTED          | architect
2026-08-05T11:49:56+02:00 | EVT_STORY_READY             | product-owner
2026-08-05T11:50:30+02:00 | EVT_ARCHI_VALIDATED         | architect
2026-08-06T10:13:26+02:00 | EVT_UX_DESIGN_COMPLETED     | ux-designer
2026-08-06T10:45:08+02:00 | EVT_DATA_DESIGN_COMPLETED   | data-engineer
2026-08-06T12:12:54+02:00 | EVT_DESIGN_COMPLETED        | architect
2026-08-07T15:24:06+02:00 | EVT_CODE_READY              | developer
2026-08-07T17:37:01+02:00 | EVT_SECURITY_AUDIT_FAILED   | cyber-security
2026-08-07T19:05:30+02:00 | EVT_CODE_REVIEW_PASSED      | code-reviewer
2026-08-10T19:13:49+02:00 | EVT_CODE_READY              | developer
```

Précondition d'un événement de sécurité, **lue** dans `scripts/events_catalog.json` :
`"preconditions": ["EVT_CODE_READY"]` ⇒ **satisfaite** *(dernier `EVT_CODE_READY` = 2026-08-10)*.
⚠️ **Fait relevé, non recopié** : `EVT_CODE_REVIEW_PASSED` est **antérieur** au dernier
`EVT_CODE_READY`. C'est exactement la borne que @Architect a inscrite au PROJECT_LOG — **rien dans
la machine à états ne l'interdit**, la péremption est une **décision humaine**.

---

## 2. `B-1` — statut : ✅ **FERMÉ**, et c'est prouvé par exécution

### 2.1 Rejeu du repro exact, sur le magasin `io` **de production**

Sonde fabriquée pour cet audit, **fixtures indépendantes du harnais du projet** *(⛔ je ne réutilise
pas `documentNonDecodable()` : un harnais qui mentirait ferait passer mon test aussi)*.
`test/zz_audit_secu_delta_test.dart`, **17 tests, supprimé en fin d'audit** *(§8)*.

```
[SONDE] P-A1 taille posée = 104 octets, JSON valide
[SONDE] P-A1 charger() => leve=null rendu=0
[SONDE] P-A1 fichiers apres = [echeances.json.illisible-1786383466995666]
[SONDE] P-A1 mis de cote = echeances.json.illisible-1786383466995666
[SONDE] P-A1 OCTET POUR OCTET identiques ? true
[SONDE] P-A1 delete ? cible presente=false (attendu false, DEPLACEE)

[SONDE] P-A2 charger() => 0 echeance(s) ; fichiers=[echeances.json.illisible-1786383467084302]
        ← UN SEUL octet 0x80 AJOUTÉ à la fin d'un document parfait

[SONDE] P-A3 charger() => 1 echeance(s) desc="révision"
[SONDE] P-A3 fichiers = [echeances.json] (attendu : AUCUN rename)
        ← ⛔ CONTRÔLE NÉGATIF : le MÊME document, « révision » en UTF-8 valide.
          UN OCTET diffère, et le verdict BASCULE.

[SONDE] P-A4 demarrage 1 => OK, 0 echeance(s), fichiers=[echeances.json.illisible-1786383467205825]
[SONDE] P-A4 demarrage 2 => OK, 0 echeance(s), fichiers=[echeances.json.illisible-1786383467205825]
[SONDE] P-A4 demarrage 3 => OK, 0 echeance(s), fichiers=[echeances.json.illisible-1786383467205825]
[SONDE] P-A4 ecriture apres reprise => estReussi=true
[SONDE] P-A4 fichiers finaux = [echeances.json, echeances.json.illisible-1786383467205825]
        ← la PERMANENCE est FERMÉE : 3 démarrages aboutissent, 1 SEULE mise de côté,
          et l'écriture redevient possible.
```

**Les quatre exigences du rapport précédent sont satisfaites, chacune assertionnée** : `charger()`
**REND au lieu de LEVER** · le document fautif est **mis de côté par `rename`** · ⛔ **jamais
supprimé** · **inchangé OCTET POUR OCTET** *(assertion sur `readAsBytesSync`, ⛔ pas sur une chaîne
décodée — une assertion sur `String` **lèverait** précisément sur le cas à vérifier)*.

⚠️ **Borne, dite au lieu d'être déguisée** : **`main()` n'est PAS exécutable en test hôte**
*(`path_provider` absent — **NM-8**)*. Le niveau atteint est **`charger()` sur le magasin `io`
réel**. Que `runApp` s'exécute ensuite et que le hub se dresse **reste NON OBSERVÉ**, et **NM-10**
est **entière**.

### 2.2 Le correctif proscrit a-t-il bien été écarté ? — **OUI**

```
$ grep -rn "allowMalformed" . --include=*.dart --include=*.md --include=*.py
lib/features/echeances/data/document_store.dart:50   /// `utf8.decode(..., allowMalformed: true)`. Il ne lève plus, mais il remplace
lib/features/echeances/data/document_store_io.dart:65 // ⛔ Ni `allowMalformed`, ni valeur par défaut, ni fichier réparé : le
test/.../document_store_test.dart:150                 'par allowMalformed, qui figerait la corruption (AC-11, AC-16)',
test/.../echeance_document_repository_test.dart:193   '⛔ `allowMalformed` aurait figé la corruption ici',
(+ docs/stories, PROJECT_LOG, STORY_CERTIFICATION_BOARD, reports/US-01.2/security.md)
```

⇒ **dans `lib/`, `allowMalformed` n'apparaît QUE dans deux commentaires qui le REFUSENT.** Aucun
appel. Idem `delete` :

```
$ grep -rn "\.delete\|deleteSync" lib/
lib/features/echeances/presentation/widgets/ligne_echeance.dart:151  icone: Icons.delete_outline,
```

⇒ **une icône, aucun appel de suppression de fichier dans toute la couche `data`.** ✅

Et `readAsString` n'a **qu'un seul site**, celui qui porte la garde :

```
$ grep -rn "readAsString\|readAsBytes" lib/
document_store_io.dart:41   /// `File.readAsString()` décode en UTF-8 **STRICT** …   (doc)
document_store_io.dart:63       return DocumentLu(await cible.readAsString());       (le site gardé)
```

### 2.3 Trois mutants, **tous tués** — ⛔ pas une relecture

⚠️ **Ces mutants ont été joués dans une COPIE ISOLÉE du dépôt**
*(`scratchpad/mut`, `lib`+`test`+`pubspec*`+`.dart_tool/package_config.json`)*, **et le motif n'est
pas la commodité** : une session d'audit **concurrente** travaillait sur le même arbre
*(voir `NB-H`)*, et deux campagnes de mutation simultanées sur un arbre unique **se falsifient l'une
l'autre**. ⛔ **Aucun fichier de `lib/` du dépôt n'a été modifié à aucun moment** *(§8)*.
Ligne de base dans la copie : `flutter test test/features/echeances/data/` → **80 tests verts**.

| Mutant | Ce qu'il conteste | Sortie **littérale** | Verdict |
|---|---|---|---|
| **M1** — la garde `on FileSystemException` ne couvre plus l'échec de décodage | « la garde ferme `B-1` » | `+75 -5: Some tests failed.` · `FileSystemException: Failed to decode data using encoding 'utf-8', path = '…\us012_…\echeances.json'` *(5 chemins temporaires distincts)* | 🟢 **TUÉ, 5 tests** |
| **M2** — `utf8.decode(await cible.readAsBytes(), allowMalformed: true)` *(le correctif **proscrit**)* | « `allowMalformed` serait équivalent » | `+75 -5: Some tests failed.` · `Expected: <Instance of 'DocumentIllisible'> / Actual: <Instance of 'DocumentLu'>` · **`Expected: empty / Actual: [Instance of 'Echeance']`** | 🟢 **TUÉ, 5 tests** |
| **M3** — un **quatrième** cas ajouté au type scellé | « le `switch` est une **barrière de compilation**, pas une discipline » | `error - The type 'LectureDocument' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'DocumentQuatrieme()'` — `echeance_document_repository.dart:35:5` — **`non_exhaustive_switch_statement`** | 🟢 **TUÉ, `analyze` ROUGE** |

🔬 **M2 est le mutant qui compte le plus, et il est reproduit indépendamment du développeur** :
`Expected: empty / Actual: [Instance of 'Echeance']` **prouve par exécution** que le correctif
proscrit ferait **AFFICHER l'échéance altérée**. **L'analyse de mon prédécesseur est confirmée par
la mesure.**
🔬 **M3 valide le motif que @Developer a opposé à la sentinelle non-JSON** : la barrière est
**réelle** — le compilateur refuse le fichier. **Le choix du type scellé était le bon**, et il est
**meilleur** que ce que l'audit précédent demandait.

### 2.4 Le `switch` ferme-t-il le chemin ? — **le dispatch OUI, le handler NON**

```
$ grep -rn "\.lire()" lib/
lib/features/echeances/data/echeance_document_repository.dart:35:    switch (await magasin.lire()) {
```

⇒ **un SEUL site d'appel dans tout `lib/`**, exhaustif *(M3)*, et **aucun appelant n'avale
`DocumentIllisible`** : le cas est **routé** vers `_misDeCotePuisEtatVide()`.
⛔ **Mais c'est le HANDLER qui avale sa propre défaillance** — et c'est `B-2`.

---

## 3. 🔴 FINDING BLOQUANT NOUVEAU

### `B-2` — Une mise de côté qui **échoue** est avalée, puis l'écriture est **autorisée** ⇒ le document illisible est **ÉCRASÉ EN SILENCE**

| Champ | Valeur |
|---|---|
| **Outil** | Sondes d'exécution fabriquées pour cet audit *(`P-B3` … `P-B7`, `P-B4`)* + mutant du correctif candidat *(`M4`)* |
| **Fichiers** *(désignés par leur TEXTE, ⛔ jamais par un numéro de ligne)* | `lib/features/echeances/data/echeance_document_repository.dart` — la méthode **`_mettreDeCoteSansBruit()`**, précisément son bloc **`on Object { }`** dont le corps est **vide** ; et **`_misDeCotePuisEtatVide()`**, précisément l'instruction **`_document = codec.documentNeuf(versionCourante);`**, qui s'exécute **que la mise de côté ait réussi ou non** |
| **Sévérité** | **HIGH** — **intégrité** : perte **totale, silencieuse et irréversible** des données locales du pratiquant |
| **Décision** | **BLOQUANT → FAILED** |
| **AC contredit** | **AC-11 « Erreur » (Must)**, dans sa **lettre** : « *⛔ L'enregistrement fautif n'est **ni affiché, ni réécrit, ni supprimé** — **aucune réparation destructive silencieuse*** ». Et la **table anti-orphelin** du Story File donne pour **réfutation** d'`AC-11 E` : « *l'enregistrement fautif est **réécrit ou supprimé*** » — ⛔ **`B-2` produit littéralement cette réfutation**, exactement comme `B-1` produisait « *l'application refuse de s'ouvrir* » |
| **Antériorité** | ⚠️ **PRÉ-EXISTANT à `5272ed1`, mesuré** *(§3.4)* — ⛔ **pas une régression du correctif**, mais un défaut **manqué par l'audit précédent**, dont le correctif **élargit la portée à la classe réaliste** |

#### 3.1 Le mécanisme

`_misDeCotePuisEtatVide()` enchaîne **inconditionnellement** deux actes :

1. `await _mettreDeCoteSansBruit()` — qui entoure `magasin.mettreDeCote()` d'un `try` / `on Object`
   au **corps vide** ⇒ **tout échec du `rename` est perdu, sans valeur de retour, sans indicateur** ;
2. `_document = codec.documentNeuf(versionCourante);` — ce qui **autorise l'écriture suivante**
   *(`_ecrire` refuse si et seulement si `_document == null`)*.

⇒ si le `rename` a échoué, le document illisible est **toujours sur le disque**, l'application
affiche l'**état vide comme s'il était normal**, et la **première écriture du pratiquant** fait
`.tmp` + `rename` **par-dessus lui** ⇒ **destruction totale**, **sans message**, **sans copie
`.illisible-`**, **sans trace**.

🔴 **L'asymétrie est la preuve que le code SAIT se protéger ailleurs** : le chemin
« document de **version FUTURE** » pose délibérément `_document = null` avec le commentaire
*« Écrire ici ÉCRASERAIT un document qu'on n'a pas su lire »* — **exactement le même danger, traité
correctement**. Le chemin « illisible » ne le fait pas.

#### 3.2 Preuve d'exécution — le déclencheur RÉALISTE, **sans aucun adversaire**

`P-B7` : le document de `B-1` *(JSON parfaitement valide, **un seul octet cp1252** — Notepad)* et
**une poignée ouverte avec un verrou ordinaire** par un autre processus. ⛔ **Aucun privilège, aucune
frontière franchie** : c'est ce que font un **antivirus** en cours de scan, **OneDrive / iCloud** en
cours de synchronisation *(et **`N-2`** a établi que le document atterrit dans `Documents`)*, un
agent de **sauvegarde**, ou une **seconde instance** de l'application.

```
[SONDE] P-B7 verrou exclusif pose sur echeances.json
[SONDE] P-B7 lire() sous verrou => DocumentIllisible                  ← la garde de B-1 FONCTIONNE
[SONDE] P-B7 mettreDeCote() sous verrou => leve=PathAccessException ; cible la=true
[SONDE] P-B7 charger() => 0 echeance(s) ; illisible la=true           ← l'echec est AVALE
[SONDE] P-B7 verrou relache ; le pratiquant saisit dans un hub VIDE
[SONDE] P-B7 creer() => estReussi=true                                ← l'ecriture est AUTORISEE
[SONDE] P-B7 >>> illisible ECRASE ? true                              ← ⛔ DONNEES DETRUITES
[SONDE] P-B7 fichiers = [echeances.json]                              ← ⛔ AUCUNE copie .illisible-
```

⚠️ **Le verrou n'a même pas besoin de persister** — `P-B5`, obstacle **transitoire** :

```
[SONDE] P-B5 apres charger() : illisible present=true (mise de cote AVALEE, etat vide affiche)
[SONDE] P-B5 obstacle retire ; le pratiquant voit un hub VIDE et saisit
[SONDE] P-B5 creer() => estReussi=true ; document illisible ECRASE ? true
[SONDE] P-B5 fichiers = [echeances.json]
```

**Séquence complète, telle que le pratiquant la vit** : il ouvre l'application → **toutes ses
échéances ont disparu** → il en ressaisit une → **ses données d'origine sont détruites à cet
instant**, définitivement. ⛔ **Rien ne le lui dit.** Avant le correctif, dans cette même
configuration, l'application **refusait de s'ouvrir** *(bruyant, `B-1`)* mais **le document
survivait et restait récupérable à la main**.

#### 3.3 La même chose au **port**, et le contrôle par comparaison

`P-B4` — un magasin qui **lit réellement le disque** mais dont `mettreDeCote()` lève :

```
[SONDE] P-B4 charger() => 0 echeance(s), tentatives mise de cote=1
[SONDE] P-B4 illisible encore present ? true
[SONDE] P-B4 creer() => estReussi=true acte=null
[SONDE] P-B4 >>> document illisible ECRASE ? true
[SONDE] P-B4 comparaison : le chemin VERSION FUTURE, lui, refuse l ecriture
[SONDE] P-B4 version FUTURE => creer().estReussi=false (protection par _document=null)
```

⇒ **la protection existe dans le fichier, à vingt lignes de là, et ne couvre pas ce chemin.**

`P-B3` — variante **sans verrou** : un **répertoire** occupant la destination de mise de côté.
Elle révèle au passage que la boucle anti-collision est **aveugle** à un occupant non-fichier
*(`File().existsSync()` rend **false** pour un répertoire — `NB-G`)* :

```
[SONDE] P-B3 destination PREDITE depuis l horloge = echeances.json.illisible-1786356000000000
[SONDE] P-B3 File(destination).existsSync() = false (la boucle de collision est AVEUGLE a un repertoire)
[SONDE] P-B3 mettreDeCote() SEULE => leve PathAccessException
[SONDE] P-B3 creer() apres mise de cote ECHOUEE => estReussi=true
[SONDE] P-B3 >>> le document illisible a-t-il ete ECRASE ? true
[SONDE] P-B3 contenu final = {"schemaVersion":2,"echeances":[{"id":"x","description":"Ecrase",…}]}
```

⛔ **Un déclencheur que je n'ai PAS reproduit, et je le dis** : l'hypothèse « le chemin
`.illisible-<16 chiffres>` dépasse `MAX_PATH` là où `.tmp` passe » est **infirmée sur ce poste** —

```
[SONDE] P-B6 longueur cible=234 | .tmp=238 | .illisible-<16>=261
[SONDE] P-B6 mettreDeCote() => leve=null
[SONDE] P-B6 >>> MAX_PATH NON ATTEINT sur ce poste : la mise de cote a REUSSI, declencheur NON REPRODUIT ici
```

**261 caractères ne font pas échouer le `rename` ici.** ⇒ ce déclencheur-là est une **hypothèse
non vérifiée**, ⛔ pas un fait. `B-2` **ne repose pas sur lui** : `P-B7` suffit.

#### 3.4 **Antériorité** — mesurée sur les deux versions du code, ⛔ pas supposée

Le même scénario, réduit à sa forme commune *(JSON invalide + une poignée ouverte : la **lecture**
réussit, le **`rename`** échoue)*, joué sur **deux copies isolées** — l'une portant `lib/` **au
commit `5272ed1`** *(`git archive 5272ed1 lib`)*, l'autre `lib/` **au HEAD** :

```
########## 5272ed1 (PRE-correctif) ##########
[CMP] charger() => rendu=0 leve=null ; illisible la=true
[CMP] creer() => estReussi=true
[CMP] >>> le document illisible a-t-il ete ECRASE ? true
[CMP] fichiers = [echeances.json]

########## 2d77778 (POST-correctif) ##########
[CMP] charger() => rendu=0 leve=null ; illisible la=true
[CMP] creer() => estReussi=true
[CMP] >>> le document illisible a-t-il ete ECRASE ? true
[CMP] fichiers = [echeances.json]
```

⇒ **RIGOUREUSEMENT IDENTIQUE.** Trois conséquences, et il faut les tenir ensemble :

1. ⛔ **Ce n'est PAS une régression du correctif**, et il serait faux de le lui imputer. Le
   `_mettreDeCoteSansBruit()` avalant et le `documentNeuf` inconditionnel **existaient déjà**.
2. ⚠️ **Le correctif en ÉLARGIT la portée** — et c'est la partie qui compte pour le produit : avant,
   la classe **réaliste** *(un octet cp1252 posé par l'éditeur du système)* butait sur `B-1` et **ne
   parvenait jamais** au chemin de mise de côté. Elle y parvient maintenant. **Le trou n'est pas
   neuf ; il est devenu ATTEIGNABLE par la porte que les utilisateurs empruntent.**
3. 🔴 **Mon prédécesseur l'a manqué, et le motif est instructif** : sa sonde `P2bis` a vérifié la
   mise de côté **dans son cas de SUCCÈS** *(`fichiers restants => [echeances.json.illisible-…]`)*.
   ⛔ **Il n'a jamais fait ÉCHOUER le `rename`.** C'est la règle du projet appliquée à l'envers :
   *un contrôle qui n'a pas vu sa barrière rougir n'a rien mesuré* — ici, **la barrière n'a jamais
   été mise en défaut, donc son mode de défaillance est resté invisible.**

#### 3.5 Pourquoi **aucun** des 356 tests ne le voit — mesuré

```
$ grep -rn "mettreDeCote" test/          (hors mes sondes)
document_store_test.dart:70   'mettreDeCote() CONSERVE le fichier et n’en supprime AUCUN'      ← succès
document_store_test.dart:94   'mettreDeCote() sur un répertoire vide ne fait rien et ne lève pas'
document_store_test.dart:112  await fige.magasin.mettreDeCote();   (×2, horloge figée)          ← succès
document_store_test.dart:203  'mettreDeCote() lève aussi'  →  await expectLater(stub.mettreDeCote(), throwsUnsupportedError);
echeance_document_repository_test.dart:36  Future<void> mettreDeCote() => _delegue.mettreDeCote();  ← délégation
```

⇒ **AUCUN test livré ne fait échouer `mettreDeCote()` sur le magasin `io`.** Le seul test où elle
lève interroge le **stub**, **directement**, **sans passer par le dépôt** — donc il n'observe
**jamais** ce que le dépôt en fait.
⇒ Et le `catch` fautif a un **corps vide (commentaire seul)** : **il n'a aucune ligne à couvrir**,
donc **la couverture ne peut structurellement pas signaler qu'il n'est pas exercé**, même à 100 %.

#### 3.6 Le commentaire qui **justifie** l'avalement est **devenu FAUX** — et il protège le défaut

Le corps du `on Object` porte : *« Une plateforme sans stockage lève ici (stub). »*
⛔ **Ce n'est plus vrai depuis le correctif**, et c'est démontrable par structure **et** par
exécution : le stub rend **toujours** `DocumentAbsent`, le `switch` **retourne** sur ce cas, donc
`_misDeCotePuisEtatVide()` est **INATTEIGNABLE sur le stub**.

```
[SONDE] P-C stub.lire() => DocumentAbsent
[SONDE] P-C stub.ecrire() => leve UnsupportedError : Cette plateforme ne fournit aucun stockage local.
[SONDE] P-C stub.mettreDeCote() => leve UnsupportedError
[SONDE] P-C depot sur stub : charger() => 0 echeance(s), NE LEVE PAS
[SONDE] P-C depot sur stub : creer() => estReussi=false acte=ActeEcriture.enregistrement
                                        message="L'échéance n'a pas été enregistrée."
[SONDE] P-C depot sur stub : supprimer() => acte=ActeEcriture.suppression
                                        message="La suppression n'a pas eu lieu."
```

⇒ **le seul cas que le commentaire invoque n'existe plus**, et **l'unique effet résiduel de
l'avalement est `B-2`**. **Même famille exacte que `NB-A`** *(une doc qui promettait ce que le code
ne faisait pas)* — mais **plus grave** : ici la doc périmée **explique** et donc **légitime** un
comportement dangereux, et **elle décourage de le regarder**.

#### 3.7 Correctif — **2 lignes de logique**, et il est **exécuté**, ⛔ pas proposé

Rendre l'échec de mise de côté **signifiant**, et refuser l'écriture — **exactement ce que le chemin
« version FUTURE » fait déjà**, donc **aucun précédent nouveau à créer** :

```dart
Future<List<Echeance>> _misDeCotePuisEtatVide() async {
  final misDeCote = await _mettreDeCoteSansBruit();
  // ⛔ Si le document n'a PAS pu être mis de côté, il est TOUJOURS sur le
  // disque : autoriser l'écriture l'ÉCRASERAIT (AC-11 « ni réécrit »).
  // `null` ⇒ toute écriture est refusée, avec le message du port (AC-17).
  _document = misDeCote ? codec.documentNeuf(versionCourante) : null;
  return const <Echeance>[];
}

Future<bool> _mettreDeCoteSansBruit() async {
  try {
    await magasin.mettreDeCote();
    return true;
  } on Object {
    return false;
  }
}
```

**Mesuré dans la copie isolée** *(mutant `M4`)* :

```
--- SUITE COMPLETE avec le correctif candidat ---
02:14 +373: All tests passed!        ← 356 tests livrés + 17 de mes sondes, AUCUN cassé

--- MA SONDE P-B7 sous le correctif candidat ---
[SONDE] P-B7 mettreDeCote() sous verrou => leve=PathAccessException ; cible la=true
[SONDE] P-B7 creer() => estReussi=false                ← l'ecriture est REFUSEE
[SONDE] P-B7 >>> illisible ECRASE ? false              ← ✅ DONNEES PRESERVEES
```

⇒ **① le correctif ferme `B-2`** *(le verdict de la sonde BASCULE)* et **② il ne casse RIEN** —
`373/373`. Ce second point est un **fait de portée** : **aucun test livré n'assertionne le
comportement actuel**, donc rien dans le corpus ne défend l'écrasement.
⚠️ **État résultant, assumé et non destructeur** : hub vide **et** écriture refusée avec le message
du port — **le même compromis que le chemin « version FUTURE »**, déjà arbitré par le Story File
*(« le pratiquant voit l'état vide sans explication — mais ⛔ aucune donnée n'est touchée »)*. Et il
**s'auto-répare** : au démarrage suivant, l'obstacle disparu, la mise de côté aboutit.

**Test à livrer AVEC le correctif** *(la classe n'en a aucun)* : faire **échouer réellement**
`mettreDeCote()` sur le magasin `io` — un **verrou** ou un **répertoire** à la destination — et
assertionner **trois** choses : `charger()` **rend**, `creer()` **refuse**, et le document fautif est
**inchangé OCTET POUR OCTET**. ⛔ **Avec son contrôle négatif** : la **même** séquence **sans**
obstacle doit mettre de côté **et** autoriser l'écriture *(sinon un dépôt qui refuserait toujours
passerait)*.

---

## 4. Findings NON BLOQUANTS **nouveaux**

| # | Outil | Fichier *(désigné par son texte)* | Sév. | Décision |
|---|---|---|---|---|
| NB-D | Sonde `P-C` + structure | `echeance_document_repository.dart` — le commentaire *« Une plateforme sans stockage lève ici (stub) »* | LOW | **Corollaire de `B-2`, à corriger avec lui** |
| NB-E | Sonde `P-D` | `document_store_io.dart` — `ecrire()`, l'instruction `await provisoire.rename(_cible.path);` | LOW | **Accepté** |
| NB-F | Sonde `P-D` | `document_store_io.dart` — `lire()`, l'instruction `if (!cible.existsSync()) return const DocumentAbsent();` | LOW | **Accepté** |
| NB-G | Sonde `P-B3` | `document_store_io.dart` — `mettreDeCote()`, la condition `while (File(destination).existsSync())` | LOW | **Accepté** |
| NB-H | Observation d'exécution | `/audit-us` — le rituel, ⛔ pas ce code | MEDIUM | ➡️ **`/audit-methodo`** |
| NB-I | Grep + structure | `echeance_document_repository.dart` — le bloc `on Object { }` de `_mettreDeCoteSansBruit` | INFO | **Constat, versé à `/audit-methodo`** |

### NB-D — Le commentaire qui légitime l'avalement désigne un cas **inatteignable**
Détaillé au §3.6. **À réécrire en même temps que `B-2`**, faute de quoi le prochain lecteur
re-conclura que l'avalement est motivé. ⛔ **Ne pas se contenter de retirer la phrase** : le motif
réel de l'avalement doit être écrit, ou l'avalement doit disparaître.

### NB-E — Un `rename` échoué laisse `echeances.json.tmp` **avec les données de l'utilisateur**
```
[SONDE] P-D creer() => estReussi=false message="L'échéance n'a pas été enregistrée."
[SONDE] P-D fichiers = [, echeances.json.tmp]
```
Le refus est **correct et typé**, la cible est **intacte** — mais le provisoire **subsiste**, à un
nom **prévisible**, dans un répertoire **partagé sur bureau** *(`N-2`)*. ⛔ **Inerte pour le
produit** *(`lire()` ne regarde que la cible — vérifié, et c'est une propriété voulue d'AC-12)*,
mais c'est une **rémanence de données** que personne n'efface. **Même remède que `N-1`** : créer le
provisoire en **exclusif** et le **supprimer** en cas d'échec.

### NB-F — `File.existsSync()` confond « aucun fichier » et « pas un fichier »
```
[SONDE] P-D File.existsSync() sur un repertoire = false
[SONDE] P-D lire() => DocumentAbsent (donc traite comme v0)
[SONDE] P-D charger() => 0 echeance(s), NE LEVE PAS
[SONDE] P-D creer() => estReussi=false message="L'échéance n'a pas été enregistrée."
[SONDE] P-D le repertoire est-il intact ? true
```
✅ **Non destructif, et l'échec est dit** : l'application s'ouvre, l'écriture est refusée **avec le
message du port**, l'occupant est intact. C'est le bon comportement par accident plutôt que par
intention : `v0` est **annoncé à tort** *(il y a bien quelque chose)*, et seule l'atomicité de
l'écriture évite le dommage. **À noter, pas à corriger en urgence.**

### NB-G — La boucle anti-collision de `mettreDeCote()` ne voit pas un occupant non-fichier
Son commentaire dit : *« Le nom ne doit JAMAIS écraser une mise de côté antérieure »*. La boucle
tient cette promesse **pour un fichier** — ✅ **vérifié dans les deux régimes d'horloge** :
```
[SONDE] P-B1 fichiers = [echeances.json.illisible-1786383467288773, echeances.json.illisible-1786383467348302]
[SONDE] P-B1 les deux documents distincts survivent ? true | f1 present ? true | f2 present ? true
[SONDE] P-B2 horloge FIGEE, fichiers = [echeances.json.illisible-1786356000000000,
                                        echeances.json.illisible-1786356000000000-1]
[SONDE] P-B2 les deux survivent ? true (boucle de collision -$rang)
```
⇒ **la piste « nom fixe ⇒ la 2ᵉ corruption écrase la 1ʳᵉ » est INFIRMÉE** *(elle était déjà fermée
à `5272ed1`, le code de `mettreDeCote` n'a pas changé — vérifié par `git show`)*. ⚠️ **Ce qu'elle ne
couvre pas** : `File(destination).existsSync()` rend **false** pour un **répertoire**, donc la boucle
**n'esquive pas** cet occupant et le `rename` lève — porte d'entrée de `P-B3`.
⚠️ **La destination reste PRÉVISIBLE** *(`echeances.json.illisible-<microsecondes>`)*, **même
famille que `N-1`** ; sur bureau POSIX + répertoire partagé, elle mériterait la même réponse
*(création en exclusif / suffixe aléatoire)*. ⛔ **Non exécuté sous POSIX**, comme `N-1`.

### NB-H — 🔴 `/audit-us` fait tourner des audits parallèles sur **UN SEUL arbre de travail**, alors que les deux rôles doivent **muter le code**
**Observé, ⛔ pas déduit.** Pendant cette session, `git status` a fait apparaître puis disparaître
`test/zz_sonde_revue_delta.dart` et `test/zz_sonde_revue_delta2.dart`, dont l'en-tête déclare
`// SONDE D'AUDIT — @CodeReviewer, revue delta d'US-01.2` — une session **concurrente**. Et l'un des
deux portait une **erreur de compilation**, relevée par mon `flutter analyze` :
```
error - The function 'DocumentStoreFichier' isn't defined … - test\zz_sonde_revue_delta2.dart:47:23 - undefined_function
```
⇒ **pendant cette fenêtre, `flutter analyze` sur l'arbre partagé était ROUGE pour une raison
étrangère au produit**, et un `run_gates --all` lancé à cet instant aurait rendu un verdict
**faux dans les deux sens possibles**.
**Trois conséquences, toutes structurelles** : ⛔ un `git checkout -- lib/` par un auditeur
**détruit le mutant de l'autre en pleine mesure** · ⛔ un `git status --porcelain` vide n'est plus
un critère de propreté **attribuable** *(je ne peux pas prouver que l'arbre final est propre **de mon
fait**)* · ⛔ deux campagnes de mutation simultanées **se falsifient mutuellement en silence**.
**Ma parade, appliquée et vérifiable** : **tous** mes mutants ont tourné dans une **copie isolée**
et **aucun fichier de `lib/` du dépôt n'a été touché** *(§8)*. ⚠️ **Ce n'est qu'une discipline
d'auditeur : rien dans le rituel ne l'impose ni ne la vérifie.** **Même famille que la dette
`emitter` non enforcé.** ➡️ **`/audit-methodo`** ; remède évident à instruire : un `git worktree`
par auditeur, ou l'interdiction explicite de muter l'arbre partagé.

### NB-I — Un `catch` au corps vide est **structurellement invisible** à la couverture
Le bloc `on Object { }` de `_mettreDeCoteSansBruit` **n'a aucune ligne exécutable** : même à
**100 %** de couverture, **rien** ne signalerait qu'il n'est jamais emprunté. Or c'est **là** que
`B-2` vit. ⇒ **cinquième instance de la dette « la couverture est aveugle »**, sous une forme
**nouvelle et pire** : non pas *« la ligne est couverte mais l'assertion est faible »*, mais
*« il n'y a pas de ligne du tout »*. ➡️ **`/audit-methodo`**, au dossier mutation.

---

## 5. Statut des findings du rapport précédent — **re-mesuré, ⛔ pas recopié**

| # | Objet | Statut au `c2a5d0d` | Aggravé par le correctif ? |
|---|---|---|---|
| N-1 | `.tmp` prévisible, suit un lien symbolique | **OUVERT** — code de `ecrire()` **inchangé** par le delta | **NON.** ⚠️ Mais `NB-G` ajoute **une seconde destination prévisible** de la même famille, et `NB-E` montre sa **rémanence**. Toujours **NON EXÉCUTÉ sous POSIX** |
| N-2 | `Documents` partagé (Win/Linux), iCloud (iOS) ⇒ tension avec AC-10 | **OUVERT** — ➡️ arbitrage @PO, **US-01.3** *(hors périmètre, constaté)* | **NON** par le code. ⚠️ **Mais c'est le terrain de `B-2`** : ces mêmes clients de synchronisation sont les porteurs du verrou de `P-B7` |
| N-3 | `check_e2e_persistance.py` absent de la CI | **OUVERT** — `grep -rn "check_e2e_persistance" .github/` → **exit 1, vide** | **NON** — ➡️ US-00.8 / `/audit-methodo` |
| N-4 | « ses **24 paquets transitifs** » écrit à la main | **OUVERT** — `pubspec.yaml:41` porte toujours la phrase ; la mesure (§1.3) donne **24 ajoutés dont 23 transitifs** | **NON** |
| N-5 | Chemin de poste en dur, dépôt **public** | **OUVERT** — `reports/US-01.2/generer_e2e.py:13` : `RACINE = Path(r"c:/Users/guillaume.decroix/…")` | **NON** |
| N-6 | Aucune borne de taille **à la lecture** | **OUVERT**, re-mesuré : `description 4 Mo => reconnues=1 longueur lue=4000000` · `profondeur 100000 => reconnues=0 leve=null` *(⛔ aucun débordement de pile)* | **NON** |
| N-7 | `codec.decoderDocument(migrer(racine)!)` | **OUVERT** — le `!` est **toujours là**, les gardes amont aussi | **NON** |
| N-8 | Le port n'impose ni la limite de 9 ni les 80 caractères | **OUVERT** — ⚠️ **clarifié** par `NB-A` : le contrat de `remplacer` **dit maintenant ce qu'il fait** | **NON** |
| N-9 | Permissions du fichier créé | **NON MESURÉ**, borne **maintenue** — Windows rend une valeur synthétique | **NON** |
| N-10 | `U+202E` accepté en description | **OUVERT**, re-mesuré : `RLO dans description => reconnues=1` | **NON** |
| N-11 | `.claude/settings.json` élargi par effet de bord | ✅ **NON REPRODUIT** dans cette session — `git status --porcelain .claude/` → **vide** | — |

⇒ **Aucun finding précédent n'est aggravé par le correctif.** Les deux corrections annexes du delta
sont **bonnes et vérifiées** : `NB-B` *(l'acte réel dans le refus)* et `NB-A` *(la doc dit ce qui
EST)* — voir §6.

---

## 6. Ce que cet audit a **re-vérifié et trouvé BON** — par exécution

⛔ **Rien de ce paragraphe n'est repris du rapport précédent : tout est ré-exécuté sur `c2a5d0d`.**

**Désérialisation hostile — résidus, jamais interprétés, jamais réparés** :
```
[SONDE] P-E id absent              => reconnues=0 ids=[] fichiers=[echeances.json]
[SONDE] P-E id entier              => reconnues=0 ids=[] fichiers=[echeances.json]
[SONDE] P-E date absente           => reconnues=0 ids=[] fichiers=[echeances.json]
[SONDE] P-E date non canonique     => reconnues=0 ids=[] fichiers=[echeances.json]   ← 2026-02-31, règle V-1
[SONDE] P-E date avec Z            => reconnues=0 ids=[] fichiers=[echeances.json]
[SONDE] P-E description objet      => reconnues=0 ids=[] fichiers=[echeances.json]
[SONDE] P-E traversee dans id      => reconnues=1 ids=[../../../../etc/passwd] fichiers=[echeances.json]
[SONDE] P-E NUL dans id            => reconnues=1 ids=[ ] fichiers=[echeances.json]
[SONDE] P-E RLO dans description   => reconnues=1 ids=[e] fichiers=[echeances.json]
[SONDE] P-E script dans description => reconnues=1 ids=[f] fichiers=[echeances.json]
[SONDE] P-E cle inconnue           => reconnues=1 ids=[g] fichiers=[echeances.json]
[SONDE] P-E2 doublon d id => reconnues=1 desc=[PREMIERE]
[SONDE] P-E2 apres creation, le DOUBLON survit ? true
```
✅ **Aucune traversée de répertoire** : un `id` hostile est accepté **comme identifiant** et
**n'entre dans aucune construction de chemin** — le nom vit en **un seul exemplaire**
*(`const String nomDocument`)* et la seule construction de tout `lib/` est
`File('${repertoire.path}${Platform.pathSeparator}$nomDocument')`. **`R-2` tient** : le doublon
survit à une écriture ultérieure. **Aucune injection** : `jsonDecode`/`jsonEncode` seuls, un
`<script>` est **stocké verbatim et jamais interprété** *(ni SQL, ni template, ni rendu HTML dans
tout le produit)*.

**Écriture atomique — la cible n'est jamais ouverte en écriture, et l'échec ne détruit rien** :
```
[SONDE] P-G creer() bloquee => estReussi=false message="L'échéance n'a pas été enregistrée."
[SONDE] P-G cible INCHANGEE octet pour octet ? true
[SONDE] P-G apres deblocage => estReussi=true
```
✅ **AC-12 « Erreur » est vrai par construction**, et le refus est **typé** *(⛔ jamais `void`, ⛔
aucune mise à jour optimiste)*.

**Aucune fuite d'information dans les messages** :
```
[SONDE] P-F enregistrement => "L'échéance n'a pas été enregistrée."
[SONDE] P-F suppression => "La suppression n'a pas eu lieu."
```
Assertionné : ⛔ aucun `.json`, ⛔ aucun séparateur de chemin, ⛔ aucun `Exception`. **Deux textes
distincts, en un seul exemplaire dans `ActeEcriture`** — et le correctif `NB-B` **est vérifié ici**
*(`P-C` : le stub rend bien `suppression` pour une suppression et `enregistrement` pour une
création)*.
⚠️ **La fuite du chemin absolu relevée en effet de bord de `B-1` est FERMÉE** : `M1` montre que sans
la garde l'exception transportait `path = 'C:\Users\GUILLA~1.DEC\…'` ; avec la garde, **elle ne sort
plus**.

**Hors surface, et je le dis au lieu de laisser un blanc** : **IDOR**, **authz d'endpoint**,
**CSRF**, **CORS**, **hachage de mot de passe**, **session**. Application **locale,
mono-utilisateur, sans compte, sans serveur, sans endpoint, sans réseau** — dépendances d'exécution
**lues** : `flutter (sdk)`, `cupertino_icons`, `path_provider` *(§1.3)*. ⇒ **aucune ressource
appartenant à un tiers, donc aucun contrôle d'appartenance à exiger.** ⛔ **Ce n'est pas
« conforme », c'est « hors surface »**, et cela changera à la première synchronisation.

---

## 7. ⛔ Ce que cet audit **N'ATTESTE PAS**

* ⛔ **Aucun SAST n'a tourné : il n'en existe pas** *(exit 1, §1.1)*. **Toute la revue est humaine,
  donc non exhaustive** — et `B-2` le prouve deux fois : il a survécu à **un audit sécurité
  complet**, à une **revue `PASSED`**, à un **visa @Dev**, à une **vérification de @Architect** et à
  **356 tests**.
* ⛔ **AUCUN SCAN DE CVE, sur RIEN.** `dart pub outdated` mesure l'**obsolescence**. Les **24
  paquets** ajoutés par cette US *(dont `jni`, `objective_c`, `crypto`, `yaml`, `ffi`)* entrent dans
  le produit **sans qu'aucune base de vulnérabilités n'ait été consultée**. Le Python de `scripts/`
  et de `reports/US-01.2/` n'est couvert par **aucun outil**. ⇒ **la mention « pas de CVE » est
  absente de ce rapport parce qu'elle serait un mensonge.**
* ⛔ **`main()` n'a PAS été exécuté** *(NM-8, `path_provider` absent en test hôte)*. Le niveau prouvé
  au §2 est **`charger()` sur le magasin `io` réel**. Que `runApp` s'exécute et que **le hub se
  dresse** reste **NON OBSERVÉ** — donc **la moitié « l'application s'ouvre » d'AC-11 « Nominal »
  n'est prouvée qu'AU NIVEAU DU DÉPÔT**.
* ⛔ **L'application n'a jamais tourné sur un appareil** *(NM-10, entière)* ni **sur le web**
  *(`flutter build web --release` **construit** et **n'exécute jamais**)*. Le comportement du stub
  est prouvé **en test hôte**, pas dans un navigateur.
* ⛔ **`B-2` n'est mesuré que sous Windows.** Les mécanismes d'échec du `rename` **diffèrent** sous
  POSIX *(un `rename` y écrase silencieusement, et une poignée ouverte n'y bloque rien)* ⇒ **le
  déclencheur `P-B7` est propre à Windows**, même si le **défaut de logique** est indépendant de la
  plateforme *(prouvé au port par `P-B4`)*. **À rejouer sous POSIX et sur appareil.**
* ⛔ **Le déclencheur `MAX_PATH` de `B-2` est INFIRMÉ sur ce poste** *(`P-B6`)*. Ne pas le citer.
* ⛔ **`N-1` n'est toujours pas exécuté** *(lien symbolique refusé sous Windows)*, **`N-2` n'est
  toujours pas observé sur un appareil**, **`N-9` reste non mesurable ici**. **Trois bornes
  reconduites à l'identique.**
* ⛔ **Aucune mesure de concurrence réelle.** `P-B7` **provoque** un conflit d'accès, mais **deux
  instances de l'application écrivant simultanément** n'ont pas été testées. Le
  `existsSync()` + `readAsString()` de `lire()` reste une **fenêtre TOCTOU** — désormais **sans
  conséquence à la lecture** *(la garde attrape)*, mais **non explorée à l'écriture**.
* ⛔ **Je n'ai vérifié aucun `.github/workflows/**`** : cette US n'en touche **aucun** *(mesuré,
  §1.0)*. Les findings ouverts d'US-00.7 *(actions non épinglées, `emitter` non enforcé,
  `enforce_admins`, **NB-1bis**)* sont **NON AGGRAVÉS et NON RECOMPTÉS**.
* ⛔ **Je ne peux pas prouver que l'état final du dépôt est propre DE MON SEUL FAIT** — une session
  concurrente écrivait dans le même arbre *(`NB-H`)*. Ce que je peux prouver : **je n'ai modifié
  aucun fichier suivi** *(§8)*.
* ⛔ **Ce visa porte sur `2d77778` (code) et `c2a5d0d` (HEAD), et sur rien d'autre** *(**NB-6** :
  `trace_append.py --help` **ne montre aucune option `--commit`**)*. **Aucune machine ne pourra
  signaler qu'il a périmé** : tout commit ultérieur touchant `lib/`, `test/`, `scripts/` ou
  `pubspec*` **invalide ce rapport, en silence**.

---

## 8. Restauration de l'état du dépôt

```
$ git status --porcelain
[fin]                                   ← vide

$ git diff --stat -- lib test scripts pubspec.yaml pubspec.lock factory.config.json
[fin diff]                              ← aucun fichier suivi modifié

$ ls test/zz_audit_secu_delta_test.dart
ls: cannot access 'test/zz_audit_secu_delta_test.dart': No such file or directory

$ git rev-parse HEAD
c2a5d0dee0db0693afd58c4a54d4c63f707fc48d
```

* **1 fichier de sonde** créé sous `test/` *(17 tests)*, **supprimé**.
* **Tous les mutants** *(`M1`, `M2`, `M3`, `M4`, et la comparaison `5272ed1` ↔ `HEAD`)* ont tourné
  dans des **copies isolées** hors du dépôt, **effacées**. ⛔ **Aucun fichier de `lib/` du dépôt
  n'a été modifié à aucun instant** — motif au `NB-H`.
* ⛔ **Non touchés** : `STORY_CERTIFICATION_BOARD.md`, `PROJECT_LOG.md`, `lib/`, `test/`,
  `scripts/`, `factory.config.json`. **Jamais `--no-verify`.**
* Sorties de cet audit : **`reports/US-01.2/security_delta.md`** *(ce fichier, **NOUVEAU** — ⛔
  `security.md` n'est pas écrasé, son `FAILED` reste lisible)* et
  `docs/trace/US-01.2/events.jsonl`.

---

## 9. Conditions de lever du verdict

1. **Corriger `B-2`** : sur **échec** de mise de côté, ⛔ **ne pas autoriser l'écriture** —
   `_document = null`, comme le chemin « version FUTURE ». **Le correctif est écrit et exécuté au
   §3.7 : 2 lignes de logique, `373/373` tests verts.**
2. **Livrer AVEC lui le test qui manque à la classe entière** : faire **réellement échouer**
   `mettreDeCote()` sur le magasin `io` *(verrou ou répertoire à la destination)*, assertionner
   `charger()` **rend**, `creer()` **refuse**, document **inchangé octet pour octet** — **et son
   contrôle négatif** *(§3.7)*.
3. **Réécrire le commentaire de `NB-D`** : il **justifie** l'avalement par un cas devenu
   **inatteignable**, et c'est ce qui l'a soustrait à l'examen.
4. **Rejouer** `run_gates --all` **sur un arbre propre**, plus `check_e2e_persistance.py`
   *(+ `--selftest`)*, puis **redemander un audit sécurité sur le NOUVEAU commit** — ⛔ **ce rapport
   ne se transporte pas** *(NB-6)*.
5. **Cumulables** *(courts, non bloquants)* : `NB-E`, `NB-G` **avec** `N-1` *(même remède : création
   en exclusif + suppression du provisoire résiduel)*, `N-4`, `N-5`, `N-7`.
   **`N-2`** ➡️ **arbitrage @PO / US-01.3**. **`N-3`, `NB-H`, `NB-I`** ➡️ **US-00.8 /
   `/audit-methodo`**.
6. ⚠️ **Le cliquet est à `95,2`** *(valeur **lue** dans `factory.config.json`)* **et la couverture à
   97,9 %** : le correctif ajoute des lignes **exécutées par ses tests** ⇒ **aucun risque de
   régression du cliquet**. ⛔ **Et surtout : la couverture n'est pas un argument de sécurité** — le
   `catch` de `B-2` n'a **aucune ligne à couvrir** *(`NB-I`)*.
