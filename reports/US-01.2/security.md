# Audit sécurité — US-01.2 « Gestion des échéances (CRUD) »

| Champ | Valeur |
|---|---|
| **Verdict** | 🔴 **FAILED** |
| **Agent** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | claude-opus-5[1m] (Opus 5, 1M context) |
| **Date** | 2026-08-07 |
| **Commit audité** | **`5272ed1`** *(branche `feat/US-01.2-design`)* — **NB-6** : `trace_append.py` n'a aucun champ `--commit`, le SHA est donc inscrit dans le `--rationale` de l'événement |
| **Périmètre** | `git diff main...HEAD` — 57 fichiers, **+12 257 / −107** |
| **Motif du verdict** | **1 finding BLOQUANT** — `B-1`, déni de service local **permanent** au démarrage sur document non décodable en UTF-8, **prouvé par exécution**, contredisant l'AC-11 (**Must**) ; **aucun test livré ne couvre la classe** |

> ⛔ **Ce verdict ne porte pas sur la qualité générale du code.** La surface auditée est
> remarquablement défensive sur presque tous les axes (§4 liste ce qui est **prouvé bon**, par
> exécution). **Un seul chemin a été laissé sans garde, et c'est le premier que le code emprunte.**

---

## 1. Sorties d'outils — brutes, collées

### 1.1 `run_gates --gate sast` — ⛔ **LE GATE N'EXISTE PAS**

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

Liste **lue** dans `factory.config.json` → `adapter.components.app.gates` :

```
format     : dart format --output=none --set-exit-if-changed lib test
analyze    : flutter analyze
test       : flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
deps_audit : dart pub outdated --show-all          ← "blocking": false
build      : flutter build web --release
```

⇒ **5 gates, aucun SAST.** La dette « 🔴 Aucun SAST dans la factory » du `CLAUDE.md` est **inchangée
par ce diff** : elle n'est ni aggravée, ni levée. **Aucune ligne de ce rapport ne s'appuie sur un
SAST — il n'y en a pas.**

⚠️ **Relevé au passage, non signalé jusqu'ici** : `deps_audit` porte **`"blocking": false`**. Même
si un jour il détectait quelque chose, **il ne bloquerait pas**.

### 1.2 `run_gates --gate deps_audit` — mesure l'**obsolescence**, ⛔ **pas la vulnérabilité**

```
$ python scripts/run_gates.py --gate deps_audit
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
material_color_utilities 0.13.0 · meta *1.18.0 (latest 1.19.0) · objective_c 9.5.0
package_config 3.0.0 · path 1.9.1 · path_provider_android 2.3.1 · path_provider_foundation 2.6.0
path_provider_linux 2.2.2 · path_provider_platform_interface 2.1.3 · path_provider_windows 2.3.0
platform 3.1.6 · plugin_platform_interface 2.1.8 · pub_semver 2.2.0 · record_use *0.6.0 (latest 1.0.0)
sky_engine (sdk) · source_span 1.10.2 · string_scanner 1.4.1 · term_glyph 1.2.2 · typed_data 1.4.0
vector_math *2.2.0 (latest 2.4.2) · xdg_directories 1.1.0 · yaml 3.1.3
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
Tous les gates bloquants passent (1 exécutés).
EXIT=0
```

🔴 **Borne à ne pas sur-lire** : `dart pub outdated` compare des **numéros de version**. Il ne
consulte **aucune base de CVE**. ⇒ **aucune affirmation de ce rapport ne peut dire « pas de CVE » :
le projet n'a aucun moyen de le savoir.** Le `path_provider: ^2.1.6` ajouté par cette US et ses
**23 paquets transitifs** entrent dans le produit **sans avoir été scannés une seule fois** — la
seule barrière est la revue humaine, et le commentaire de `pubspec.yaml` le dit lui-même.

### 1.3 Fermeture transitive — **comptée par commande**, jamais recopiée

```
$ (lecture de pubspec.lock à main et à HEAD, comptage par script)
pubspec.lock main  : 27 paquets
pubspec.lock HEAD  : 51 paquets
AJOUTES (24) : ['args', 'code_assets', 'crypto', 'ffi', 'hooks', 'jni', 'jni_flutter', 'jni_util',
 'logging', 'objective_c', 'package_config', 'path_provider', 'path_provider_android',
 'path_provider_foundation', 'path_provider_linux', 'path_provider_platform_interface',
 'path_provider_windows', 'platform', 'plugin_platform_interface', 'pub_semver', 'record_use',
 'typed_data', 'xdg_directories', 'yaml']
RETIRES (0) : []
```

⇒ **24 paquets ajoutés au total**, dont `path_provider` **lui-même** ⇒ **23 transitifs**. Voir
finding **N-4** : le commentaire de `pubspec.yaml` annonce « ses **24** paquets **transitifs** ».

### 1.4 `run_gates --all` — les 5 gates

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 0.48 seconds.
✅ app.format

▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 10.8s)
✅ app.analyze

▶ app.test — 01:52 +344: All tests passed!
Couverture de lignes : 97.9% (926/946) — seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigné le 2026-08-02 — PR27
  [HAUSSE] 97.89% (926/946) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.8
✅ app.test

▶ app.build — (.) $ flutter build web --release
√ Built build\web
✅ app.build

Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

🔴 **Fait central pour la lecture de ce rapport** : **les 5 gates sont VERTS, 344 tests passent, la
couverture MONTE à 97,9 %, et le bloquant `B-1` est là.** C'est la troisième confirmation de
l'acquis d'US-01.1 — ⛔ **la couverture de lignes est aveugle à ce qui n'a jamais été essayé.**

### 1.5 `gitleaks` — arbre **et** commits du diff

```
$ gitleaks version
8.30.1

$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~189096614 bytes (189.10 MB) in 11.1s
INF no leaks found
EXIT=0

$ gitleaks git --log-opts="main..HEAD" --config .gitleaks.toml --redact -v .
INF 22 commits scanned.
INF scanned ~704488 bytes (704.49 KB) in 2.18s
INF no leaks found
EXIT=0
```

Recherche manuelle complémentaire sur **tous les fichiers du diff**
(`api[_-]?key|secret|token|password|bearer|private[_-]?key|BEGIN .*PRIVATE|aws_|ghp_|xox[baprs]-`) :
**0 occurrence hors du mot « token » au sens *design token*** (`ConcentrationTokens`, `concentration_tokens.dart`)
et de la ligne de BACKLOG qui décrit US-00.1. ⇒ ✅ **aucun secret en dur, aucune fixture porteuse de
secret.**

### 1.6 `validate_trace`

```
$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
EXIT=0
```

Chaîne d'événements relevée dans `docs/trace/US-01.2/events.jsonl` :
`EVT_STORY_CREATED → EVT_TRACK_SELECTED → EVT_STORY_READY → EVT_ARCHI_VALIDATED →
EVT_UX_DESIGN_COMPLETED → EVT_DATA_DESIGN_COMPLETED → EVT_DESIGN_COMPLETED → EVT_CODE_READY`
⇒ précondition `EVT_CODE_READY` de mon événement : **satisfaite**.

### 1.7 `check_e2e_persistance.py` (T13) — exécuté, **et son autotest**

```
$ python scripts/check_e2e_persistance.py
== ADR-010 §1 : la racine est montée, le magasin est RÉEL ==
   fichier : test/e2e/gestion_echeances_test.dart
   fichier : test/e2e/hub_echeances_test.dart
[OK ] contrôle « magasin » : 0 écart(s)
[OK ] contrôle « racine » : 0 écart(s)
CONFORME — les deux contrôles d'ADR-010 §1 passent.
EXIT=0

$ python scripts/check_e2e_persistance.py --selftest
[OK ] M0_conforme                        attendu=aucun       obtenu=aucun
[OK ] M1_sous_arbre_multiligne           attendu=['racine']  obtenu=['racine']
[OK ] M2_motif_seulement_en_commentaire  attendu=aucun       obtenu=aucun
[OK ] M3_magasin_factice                 attendu=['magasin'] obtenu=['magasin']
[OK ] M4_FakeClock_est_licite            attendu=aucun       obtenu=aucun
[OK ] M5_faux_depot                      attendu=['magasin'] obtenu=['magasin']
[OK ] M6_stub_de_plateforme              attendu=['magasin'] obtenu=['magasin']
[OK ] M7_pumpWidget_sans_argument_connu  attendu=['racine']  obtenu=['racine']
Contrôles tués par au moins un mutant : ['magasin', 'racine']
AUTOTEST OK : les deux contrôles savent rougir, et sur les bons cas.
EXIT=0
```

✅ **Les deux contrôles portent leur mutant et savent rougir.** ⚠️ Voir **N-3** : il **n'est pas en CI**.

---

## 2. 🔴 FINDING BLOQUANT

### `B-1` — Un document local non décodable en UTF-8 empêche **définitivement** l'application de démarrer

| Champ | Valeur |
|---|---|
| **Outil** | Sonde d'exécution fabriquée pour cet audit *(3 fichiers de test temporaires, supprimés — `git status` vide, vérifié)* |
| **Fichiers** *(désignés par leur texte, ⛔ jamais par un numéro de ligne)* | `lib/features/echeances/data/document_store_io.dart` — la méthode `lire()`, précisément l'instruction **`return cible.readAsString();`**<br>`lib/features/echeances/data/echeance_document_repository.dart` — `charger()`, l'instruction **`final texte = await magasin.lire();`** *(aucune garde)*<br>`lib/main.dart` — **`await notifier.charger();`**, placée **avant** `runApp(...)` |
| **Sévérité** | **HIGH** — disponibilité, **permanente**, sans issue depuis l'application |
| **Décision** | **BLOQUANT → FAILED** |
| **AC contredit** | **AC-11 « Erreur »** et **« Limite »** *(Must)* : « *un enregistrement **illisible ou invalide** (… **fichier tronqué**) est **ignoré** : l'application **s'ouvre**, le hub **reste debout*** » et « *⛔ **jamais** une erreur technique brute* » |

**Le mécanisme.** `File.readAsString()` de `dart:io` décode en UTF-8 **strict** et **lève une
`FileSystemException`** si les octets ne sont pas décodables. Cette exception n'est attrapée
**nulle part** :
`lire()` ne l'attrape pas → `EcheanceDocumentRepository.charger()` ne l'attrape pas *(son seul
`try` entoure l'**écriture** de migration, pas la lecture)* → `EcheancesNotifier.charger()` ne
l'attrape pas → `main()` l'`await` **avant** `runApp`. ⇒ **`runApp` n'est jamais appelé.**

⚠️ **La distinction qui fait tout, et elle est mesurée** : le chemin « **JSON syntaxiquement
invalide** » est, lui, parfaitement traité — `lireRacine` attrape la `FormatException`, le document
est **mis de côté par `rename`** *(⛔ jamais `delete`)*, l'application s'ouvre vide. **Le chemin
« octets non décodables » ne l'est pas, et il se produit AVANT lui** : l'échec a lieu à la lecture,
donc **`mettreDeCote()` n'est jamais atteint** ⇒ le document fautif **reste en place** ⇒ **chaque
démarrage suivant échoue à l'identique**. **Il n'y a aucun moyen, depuis l'application, d'en
sortir.**

**Scénario d'exploitation concret — et il n'est pas contrivé.** Le pratiquant ouvre
`echeances.json` avec l'éditeur de texte de son système *(sur bureau, le fichier est dans
`~/Documents` — voir **N-2**)* pour corriger un libellé, et l'enregistre. **Notepad, comme tout
éditeur Windows réglé par défaut, écrit l'accent en cp1252** : « révision » devient
`72 é(0xE9) 76 …`. Le JSON reste **parfaitement valide**, la structure est **intacte**, une seule
lettre a changé de codage — **et l'application ne redémarre plus jamais**.
⚠️ **Le projet a déjà payé cette exacte classe de bug deux fois** *(« plantage `cp1252` » d'US-00.6,
sur un outil de contrôle)*. **Trois autres voies produisent le même état** : une **troncature**
tombant au milieu d'une séquence multi-octets *(le mot littéral d'AC-11)*, une **restauration de
sauvegarde partielle** *(iOS sauvegarde ce répertoire dans iCloud par défaut — **N-2**)*, et
**tout processus du même utilisateur** sur bureau.

**Preuve d'exécution.** Sonde nº 1, `P1` — octets arbitraires :

```
P1 => LEVE FileSystemException :: FileSystemException: Failed to decode data using
      encoding 'utf-8', path = 'C:\Users\GUILLA~1.DEC\AppData\Local\Temp\sonde_secu_5c6d4571\echeances.json'
```

Sonde nº 2 — le scénario **réaliste**, la **permanence**, et le **contrôle négatif**. La fonction
`demarrage()` reproduit **littéralement** la séquence de `lib/main.dart`
*(`await notifier.charger()` **puis** `runApp`)* :

```
S1 taille du fichier = 103 octets                     ← JSON VALIDE, un seul octet en cp1252
S1 1er demarrage  => runApp JAMAIS ATTEINT :: FileSystemException :: Failed to decode data using encoding 'utf-8', path = '…\echeances.json'
S1 fichiers apres => [echeances.json]                 ← ⛔ AUCUNE mise de côté
S1 2e demarrage   => runApp JAMAIS ATTEINT :: FileSystemException :: …
S1 3e demarrage   => runApp JAMAIS ATTEINT :: FileSystemException :: …
S1 => PERMANENCE : le document fautif est-il encore la ? true

S2 taille = 59 octets (JSON tronque, sequence amputee)
S2 demarrage => runApp JAMAIS ATTEINT :: FileSystemException :: …

S3 demarrage => runApp ATTEINT — 1 echeance(s)        ← ⛔ CONTRÔLE NÉGATIF : le MÊME document,
                                                        « révision » en UTF-8 valide ⇒ démarre.

S4 demarrage => runApp JAMAIS ATTEINT :: FileSystemException :: …
                                                      ← UN SEUL octet 0x80 ajouté à la fin
                                                        d'un document par ailleurs parfait.
```

🔬 **C'est une preuve par mutation, pas une relecture** : entre `S1` et `S3`, **un octet** diffère,
et le verdict **bascule**. Entre `S4` et un document sain, **un octet ajouté** suffit.

**Pourquoi aucun test livré ne l'a vu — mesuré, pas supposé.**

```
$ grep -rn "writeAsBytes|utf8.encode|latin1|0xFF|readAsBytes" test/
AUCUNE occurrence : aucun test livre ne pose des octets non-UTF-8
```

Le harnais `test/support/magasin_temporaire.dart` pose ses documents par
**`poser(String) → writeAsStringSync`** : par construction, **il ne peut produire que de l'UTF-8
valide**. Les trois tests d'AC-11 *(« Un enregistrement local illisible… », « …n'est ni réécrit ni
supprimé », « Un stockage entièrement illisible… »)* posent `'{ceci n est pas du JSON'` et
`"id":""` — c'est-à-dire du **JSON invalide** et des **champs invalides**, jamais des **octets
invalides**. ⇒ **la classe entière est hors d'atteinte du harnais**, et **97,9 % de couverture ne
le disent pas** : les lignes de `lire()` sont **couvertes**, c'est leur **absence de garde** qui ne
l'est pas.

**Correctif — 4 lignes, dans `lire()`** :

```dart
Future<String?> lire() async {
  final cible = _cible;
  if (!cible.existsSync()) return null;
  try {
    return await cible.readAsString();
  } on FileSystemException {
    // Octets non décodables, droit refusé, ou disparition entre le test et la
    // lecture : c'est « ILLISIBLE », pas « FATAL » (AC-11). ⛔ Rendre `null`
    // serait FAUX : `null` signifie « aucun fichier » (v0), et la première
    // écriture écraserait alors par `rename` un document qu'on n'a pas su lire.
    // Rendre une chaîne non-JSON fait échouer `lireRacine`, donc emprunter le
    // chemin DÉJÀ CORRECT : mise de côté par `rename`, état vide, rien de perdu.
    return '\u0000';
  }
}
```

⛔ **Et le correctif qu'il ne faut PAS retenir**, parce qu'il ressemble au bon :
`utf8.decode(await cible.readAsBytes(), allowMalformed: true)`. Il ne lève plus, mais il remplace
les octets fautifs par `U+FFFD` ⇒ le document **parse**, l'échéance **s'affiche altérée**, et la
**prochaine écriture réécrit le document avec la corruption figée**. C'est une **correction
silencieuse d'une donnée que l'utilisateur n'a pas saisie** — exactement ce que **AC-16 « Erreur »**
et **AC-11 « Erreur »** *(« ni affiché, ni réécrit »)* interdisent. **Le bon comportement est de
traiter le document comme illisible, pas de le réparer.**

**Test à livrer avec le correctif** *(la classe n'a aujourd'hui aucun test)* : poser des **octets**
via `writeAsBytesSync`, vérifier que **le hub s'ouvre**, que l'**état vide** s'affiche, et que le
document fautif est **conservé** sous `echeances.json.illisible-…` — soit exactement les trois
assertions du test existant « Un stockage entièrement illisible conduit à l'état vide », mais avec
un **document non décodable** au lieu d'un JSON malformé.

**Effet de bord secondaire du même défaut** : l'exception non attrapée **transporte le chemin
absolu du fichier**, nom d'utilisateur compris
*(`path = 'C:\Users\GUILLA~1.DEC\…'`)*. Sur un appareil, elle part au journal de plateforme. C'est
en tension directe avec **AC-17 « Nominal »** *(« ⛔ aucune trace technique, ⛔ aucun code d'erreur
brut »)* — clause qui, elle, est **parfaitement tenue** partout où le code **attrape**.

---

## 3. Findings NON BLOQUANTS

| # | Outil | Fichier *(désigné par son texte)* | Sév. | Décision |
|---|---|---|---|---|
| N-1 | Revue + sonde `P12` | `document_store_io.dart` — `File get _provisoire => File('${_cible.path}.tmp')` | MEDIUM | **Accepté, à traiter** |
| N-2 | Revue + source des paquets | `document_store_io.dart` — `creerMagasin()` → `getApplicationDocumentsDirectory()` | MEDIUM | **Accepté, à arbitrer** |
| N-3 | Grep CI | `scripts/check_e2e_persistance.py` — **absent de `.github/workflows/`** | LOW | **Accepté** |
| N-4 | Comptage par commande | `pubspec.yaml` — commentaire « ses **24 paquets transitifs** » | LOW | **Accepté** |
| N-5 | Revue | `reports/US-01.2/generer_e2e.py` — `RACINE = Path(r"c:/Users/guillaume.decroix/…")` | LOW | **Accepté** |
| N-6 | Sondes `P4`, `P5` | `echeance_document_codec.dart` — `_reconnaitre`, aucune borne de taille en LECTURE | LOW | **Accepté, informatif** |
| N-7 | Revue | `echeance_document_repository.dart` — `codec.decoderDocument(migrer(racine)!)` | LOW | **Accepté** |
| N-8 | Sonde nº 3 | `echeance_repository.dart` — le **port** n'impose ni la limite de 9 ni les 80 caractères | LOW | **Accepté, défense en profondeur** |
| N-9 | Sonde `P10` | permissions du fichier créé | **NON MESURÉ** | **Borne déclarée** |
| N-10 | Sonde `D5` | `validation_echeance.dart` — `U+202E` accepté en description | INFO | **Signalé** |
| N-11 | `git status` | `.claude/settings.json` | INFO | **Restauré** |

### N-1 — Le fichier provisoire est **prévisible**, et sur bureau son répertoire est **partagé**

Le provisoire est **exactement** `echeances.json.tmp`, sans aléa. L'écriture atomique fait
`provisoire.writeAsString(contenu, flush: true)` puis `rename`. Or `writeAsString` ouvre en
`O_WRONLY|O_CREAT|O_TRUNC`, ce qui **suit un lien symbolique**. ⇒ un processus du **même
utilisateur** capable de créer `echeances.json.tmp` **avant** la première écriture obtient une
primitive : *faire écrire l'application dans un fichier de son choix, et le tronquer* (CWE-59,
suivi de lien / fichier temporaire non sûr).

⛔ **NON EXÉCUTÉ, et je le dis plutôt que de l'affirmer.** Sonde `P12`, sortie littérale :

```
P12 NON EXECUTE sur ce poste : FileSystemException (creation de lien refusee) — a rejouer sous POSIX
```

Windows refuse la création de lien symbolique sans privilège. **À rejouer sous POSIX avant de
conclure.** ⚠️ **Et à ne pas surévaluer** : les deux acteurs sont le **même utilisateur**, donc
aucune frontière de privilège n'est franchie sur bureau, et sur **Android/iOS le répertoire est
propre à l'application** ⇒ **impact réel très faible aujourd'hui**. C'est une **rigidité de
construction** plus qu'une faille exploitée.

**Correctif** *(une ligne, et il ferme la question sans rien changer d'autre)* : créer le provisoire
en **exclusif** avant d'écrire — `await provisoire.create(exclusive: true)` échoue si le nom existe
déjà, lien compris ⇒ le pré-positionnement devient inopérant. **À combiner** avec la suppression du
provisoire résiduel en cas d'échec.
⚠️ **Attention à ne pas casser le harnais** : `MagasinTemporaire.bloquerEcriture()` provoque
justement l'échec d'écriture d'AC-17 **en créant un RÉPERTOIRE de ce nom** — un correctif
`exclusive: true` **conserve** ce comportement *(la création échoue, l'écriture échoue, AC-17 est
toujours observable)*. **Vérifié en lisant le harnais, à rejouer après correctif.**

### N-2 — Où le document atterrit réellement : **partagé sur bureau, sauvegardé sur iOS**

Mesuré **dans la source des paquets**, jamais de mémoire :

```
path_provider-2.1.6/lib/path_provider.dart, doc de getApplicationDocumentsDirectory :
  /// Path to a directory where the application may place data that is
  /// user-generated, or that cannot otherwise be recreated by your application.
  /// Example implementations:
  /// - `NSDocumentDirectory` on iOS and macOS.
  /// - The Flutter engine's `PathUtils.getDataDirectory` API on Android.

path_provider_windows-2.3.0 : getApplicationDocumentsPath() => getPath(WindowsKnownFolder.Documents)
path_provider_linux-2.2.2   : getApplicationDocumentsPath() => xdg.getUserDirectory('DOCUMENTS')?.path
path_provider_android-2.3.1 : _applicationContext.getDir('flutter', Context.MODE_PRIVATE)
```

⇒ **Android : propre à l'application** *(`MODE_PRIVATE`)* — ✅ conforme.
⇒ **Windows / Linux : le répertoire `Documents` de l'UTILISATEUR**, partagé avec **toute** autre
application, et **couramment synchronisé** par OneDrive / Dropbox / Nextcloud.
⇒ **iOS / macOS : `NSDocumentDirectory`** du conteneur — **inclus par défaut dans la sauvegarde
iCloud**, dont l'exclusion exige `NSURLIsExcludedFromBackupKey`, que **rien dans le diff ne pose**.

**Ce que cela fait à AC-10.** La clause « Erreur » d'AC-10 promet « *aucune donnée ne quitte
l'appareil* » et se donne pour **forme falsifiable** l'« *absence de toute dépendance réseau et de
tout appel réseau dans le code livré* ». **Cette forme est SATISFAITE — vérifiée par commande** :

```
$ grep -rniE "package:http|dart:html|HttpClient|Socket|WebSocket|dio|Uri\.parse|launchUrl|WebView|fetch\(" lib/
AUCUNE occurrence reseau dans lib/
$ dépendances d'exécution déclarées : flutter (sdk) · cupertino_icons ^1.0.8 · path_provider ^2.1.6
```

⚠️ **Mais la PROMESSE est plus large que sa forme falsifiable** : sur iOS, la donnée quitte
l'appareil **par la sauvegarde du système**, sans qu'une seule ligne de code n'émette de requête.
⛔ **Ce n'est pas un défaut du code ; c'est un écart entre l'emplacement choisi et la promesse
écrite**, et il n'est **pas observable** aujourd'hui *(l'application n'a jamais tourné sur un
appareil — borne **NM-10**)*.
**Deux issues, toutes deux légitimes, et c'est un arbitrage produit, pas un correctif technique** :
soit `getApplicationSupportDirectory()` + exclusion de sauvegarde, soit **assumer et écrire** dans
AC-10 que la sauvegarde du système est hors périmètre. ⛔ **Ce que je ne fais pas : trancher à la
place du @PO.** ➡️ **À porter à US-01.3**, qui construit la chaîne mobile réelle et est le seul
endroit d'où cela sera **observable**.

### N-3 — Le contrôle de T13 **n'est pas en CI**

```
$ grep -rn "check_e2e_persistance" .github/ .claude/ scripts/   (hors le script lui-même)
AUCUNE reference hors du script lui-meme => IL N'EST PAS EN CI
$ grep -n "check_gherkin_mapping" .github/workflows/ci.yml
139:        run: python scripts/check_gherkin_mapping.py
141:        run: python scripts/check_gherkin_mapping.py --selftest
```

`ADR-010 §1` exige que ses deux contrôles « *se publient comme des commandes **EXÉCUTABLES***. Ils
le sont, et **ils portent leur mutant** *(§1.7, 8/8)*. Mais ils **se lancent à la main** : une
future US pourrait réintroduire un magasin factice dans `test/e2e/**` **sans qu'aucun gate ne
rougisse**. **Même famille exacte** que la dette ouverte « aucun `selftest` en CI » —
⛔ **non aggravée par ce diff**, mais **une nouvelle instance**. ➡️ `/audit-methodo` ou US-00.8.

### N-4 — Un nombre dérivé, écrit à la main à côté d'une mesure

`pubspec.yaml` porte : « *ses **24 paquets transitifs** sont EXCLUS du bundle web* ». La mesure
(§1.3) donne **24 paquets AJOUTÉS**, dont `path_provider` **lui-même** ⇒ **23 transitifs**.
L'écart est de **1**, sans conséquence technique — mais c'est **littéralement la classe de défaut
nº 1 du projet** *(« une assertion chiffrée écrite à la main à côté d'une commande »)*, et le projet
a déjà produit un `N-1` par ce moyen. **Remède conforme à sa propre règle** : retirer le nombre et
laisser la **commande qui le produit**.

### N-5 — Chemin de poste **en dur** dans un dépôt **public**

`reports/US-01.2/generer_e2e.py` ouvre par `RACINE = Path(r"c:/Users/guillaume.decroix/MesProjets/Concentration")`.
Deux conséquences : le **nom d'utilisateur et l'arborescence du poste** sont publiés *(le dépôt est
**public** depuis le 2026-07-27)*, et le générateur **n'est rejouable sur aucun autre poste** — or
son intérêt est précisément de **relire les titres au lieu de les retaper** (R-8).
**Correctif** : `Path(__file__).resolve().parents[2]` — **c'est déjà ce que fait**
`reports/US-01.2/migration_roundtrip_criterion.py` *(`RACINE = Path(__file__).resolve().parents[2]`)*,
donc le dépôt porte **les deux formes du même besoin**, dont une fausse.

### N-6 — Aucune borne de taille **à la lecture** (mesuré)

```
P5 => 1 reconnue(s) ; longueur description lue = 8388608
P4 50000 entrees  => CHARGE OK — 50000 echeance(s) lisible(s) en 3585 ms
P4 200000 entrees => CHARGE OK — 200000 echeance(s) lisible(s) en 9113 ms
P3 profondeur 200000 => CHARGE OK — 0 echeance(s) lisible(s)   ← ⛔ aucun débordement de pile
```

✅ **Bonne nouvelle mesurée d'abord** : l'imbrication profonde **ne fait pas exploser** `jsonDecode`
*(200 000 niveaux, aucun `StackOverflowError`)* — l'hypothèse de l'analyseur récursif est **écartée
par l'expérience**.
⚠️ Une description de **8 Mo** et **200 000** entrées sont acceptées depuis le disque. AC-2 assume
explicitement que la borne de 80 caractères vit **au point de saisie** *(« l'invariant I-3 reste
vrai pour une donnée lue du stockage »)* — mais l'AC parle d'une description **vide**, pas d'une
description **géante**. **Impact : gel de l'interface, données locales, auto-infligé** ⇒ pas une
faille. Si une borne est ajoutée un jour, elle doit produire un **RÉSIDU** *(entrée non reconnue,
conservée verbatim)*, ⛔ **jamais une troncature** *(AC-11, AC-16)*.

### N-7 — Un `!` qui ne tient que par un invariant distant

`charger()` écrit `codec.decoderDocument(migrer(racine)!)`. **Vérifié sûr aujourd'hui** : les trois
chemins qui font rendre `null` à `migrer` *(version absente/non entière/`< 1`, version future,
cible hors bornes)* sont **tous** gardés en amont, et `cible` vaut `versionCourante` par défaut.
Mais la garde et le `!` sont **séparés par une vingtaine de lignes** : le jour où un appelant passe
une `cible` explicite, l'assertion devient fausse et **lève à l'ouverture** — soit la famille de
`B-1`. **Correctif** : `final migre = migrer(racine); if (migre == null) { … mise de côté … }`.

### N-8 — Le **port** n'impose pas les règles métier (défense en profondeur)

Sonde nº 3 : **toutes** les barrières de saisie vivent bien **au domaine**, pas dans le widget
*(preuve au §4)*. Mais `EcheanceRepository.creer` n'impose **ni** la limite de 9, **ni** les 80
caractères : un futur appelant qui court-circuiterait `EcheancesNotifier` écrirait une 10ᵉ échéance.
**Aucun appelant tel n'existe** *(vérifié)*. C'est une remarque de robustesse, pas un défaut actuel.

### N-9 — Permissions du fichier créé : ⛔ **NON MESURÉ**, et je ne l'affirmerai pas

```
P10 mode=rw-rw-rw- type=file taille=96
P10 repertoire mode=rwxrwxrwx
```

⛔ **Cette sortie ne prouve rien** : Windows n'a pas de mode POSIX, et Dart y rend une valeur
**synthétique**. Il serait faux d'écrire « le fichier est accessible en écriture à tous ». **À
mesurer sur POSIX ou sur appareil** — **borne**, du même ordre que **NM-10**. ⚠️ Sur bureau POSIX,
cette mesure se combinerait à **N-2** *(répertoire partagé)* : c'est là qu'elle a un sens.

### N-10 — `U+202E` accepté en description

Sonde `D5` : une description contenant `U+202E` *(RIGHT-TO-LEFT OVERRIDE)* est **acceptée et
stockée**. Elle peut inverser l'apparence d'un libellé dans la liste et **dans la modale de
confirmation de suppression**. ⚠️ **Produit local, mono-utilisateur, données saisies par
l'utilisateur lui-même** ⇒ aucune escalade, aucun tiers à tromper. **Signalé pour mémoire**, ⛔ pas
une exigence.

### N-11 — Observation sur l'audit **lui-même**

Pendant cette session, le système de permissions a ajouté **deux fois** à
`.claude/settings.json` une entrée d'autorisation **large** d'exécution Python arbitraire —
d'abord **`"Bash(python -c ' *)"`**, puis **`"Bash(PYTHONIOENCODING=utf-8 python -c ' *)"`**.
⛔ **Un audit ne doit pas élargir la surface de permissions du dépôt** : les **deux** ont été
**restaurées** (`git checkout -- .claude/settings.json`), et l'état final du dépôt ne porte que
mes deux sorties autorisées *(`docs/trace/US-01.2/events.jsonl` et `reports/US-01.2/security.md`)*.
➡️ **Si ces autorisations sont voulues, elles doivent être accordées délibérément par l'humain, pas
héritées d'un audit.** ⚠️ **Et c'est une observation qui dépasse cet audit** : un fichier de
configuration de sécurité qui **s'élargit par effet de bord de l'exécution** et dont **aucun gate ne
lit le contenu** est de la **même famille** que les dettes déjà ouvertes *(`emitter` non enforcé,
aucune détection de dérive de la protection de branche)*. ➡️ **Candidat `/audit-methodo`.**

---

## 4. Ce que cet audit a vérifié **et trouvé BON** — par exécution, pas par relecture

Ces points portent le verdict autant que les findings : ⛔ un « PASSED » sans preuve ne vaut rien,
un « FAILED » qui tairait ce qui tient serait tout aussi faux.

**Validation d'entrée — elle vit au DOMAINE, et les DEUX côtés de chaque borne sont exercés.**
Sonde nº 3, appelant `ValidationEcheance` **directement, sans monter aucun widget** *(si une
barrière était portée par le formulaire, elle serait absente ici)* :

```
D1 80 car.  => ACCEPTE          D1 81 car. => REFUSE [description] La description ne doit pas dépasser 80 caractères.
D1 80 car. + blancs de bordure => ACCEPTE      D1 81 car. apres trim => REFUSE
D1 vide => REFUSE [description]                D1 que des blancs => REFUSE [description]
D2 9e creation (8 presentes)  => ACCEPTE       D2 10e creation (9 presentes) => REFUSE [formulaire]
D2 EDITION a 9 presentes => ACCEPTE            ← la limite ne doit PAS s'appliquer : correct
D3 31/02/2027 => REFUSE [date] Le 31/02/2027 n'existe pas au calendrier.
D3 29/02/2028 (existe) => ACCEPTE              D3 29/02/2027 => REFUSE     D3 30/02/2028 => REFUSE
D3 32/01/2027 => REFUSE   D3 00/01/2027 => REFUSE   D3 15/13/2027 => REFUSE
D3 heure 25:00 => REFUSE [heure]   D3 heure 23:60 => REFUSE [heure]
D3 heure 02:30 le 29/03/2026 (saut DST) => REFUSE [heure] L'heure 02:30 n'existe pas ce jour-là.
D3 date 2027-01-15 (mauvais gabarit) => REFUSE  D3 15/1/2027 => REFUSE
D3 EDITION 31/02/2027 (R-10) => REFUSE [date]  ← MÊME refus, MÊME message
D4 hier => REFUSE [date] La date doit être dans le futur.
D4 T=0 exactement => REFUSE       D4 T=+1 minute => ACCEPTE
D4 EDITION vers le passe => REFUSE [date]      ← ⛔ le contournement en 2 gestes est FERMÉ (R-10)
```

🔬 **Trois choses que je souligne parce qu'elles sont rares** : **①** la barrière d'AC-16 est bien
la **forme canonique** et non une exception — `31/02/2027` est refusé *(et `DateTime.parse` ne lève
pas, le projet l'a mesuré)* ; **②** l'**heure inexistante du saut d'heure** est **réellement
refusée sur ce poste**, ce que la borne **NM-9** annonce comme non scénarisable *(le fuseau de ce
poste pratique le changement d'heure ; sous `TZ=UTC` ce chemin est inatteignable)* — **la borne est
donc honnête, pas un prétexte** ; **③** **R-10 est prouvé** : l'édition passe par la **même**
fonction, donc le futur strict n'est **pas** contournable en deux gestes.

**Aucune traversée de répertoire, et le chemin ne dérive d'AUCUNE entrée utilisateur.**
Le nom vit en **un seul exemplaire** *(`const String nomDocument = 'echeances.json'`)* ; la seule
construction de chemin de tout `lib/` est
`File('${repertoire.path}${Platform.pathSeparator}$nomDocument')`. Sonde `P9`, la vérification par
l'attaque :

```
P9 id="../../../../etc/passwd" => reconnues=1 id_lu="../../../../etc/passwd"
P9 id="\u0000"                 => reconnues=1 id_lu="\u0000"
P9 id="" / 123 / null / true / {"a":1} => reconnues=0    ← résidus, conformes à la grammaire §2
```

⇒ un `id` hostile est **accepté comme identifiant** *(la grammaire n'exige que « non vide »)* et
**n'est jamais utilisé pour construire un chemin** ⇒ **aucune traversée possible**.

**Écriture atomique, et l'échec ne détruit rien** — sonde `P11` :

```
P11 echec attendu : estReussi=false message=L'échéance n'a pas été enregistrée.
P11 cible INCHANGEE = true
P11 nouvelle tentative apres deblocage : estReussi=true
```

`.tmp` + `flush: true` + `rename` : la cible **n'est jamais ouverte en écriture**, donc une
interruption la laisse **intacte**. Le refus est **typé** *(`ResultatEcriture`, ⛔ jamais `void`)*,
l'état mémoire **n'est jamais muté avant succès** ⇒ **aucune mise à jour optimiste**, et l'écran
reste **l'image du disque**. **AC-17 tient, y compris son second tour.**

**Version de schéma FUTURE — le piège est évité, et aucune donnée n'est touchée** *(`P7`)* :

```
P7 reconnues=0 ecriture_reussie=false message=L'échéance n'a pas été enregistrée.
P7 disque INCHANGE = true
P7 fichiers = [echeances.json]        ← ⛔ AUCUNE mise de côté d'un document parfaitement valide
```

**Document illisible → `rename`, ⛔ JAMAIS `delete`** *(`P2bis`)* :

```
P2bis => CHARGE OK — 0 echeance(s)
P2bis fichiers restants => [echeances.json.illisible-1786113263301980]
```

**Doublons d'`id` — la 1ʳᵉ reconnue, les suivantes RÉSIDUS, ré-émises VERBATIM à leur place**
*(`P6`)* : le disque après une création montre les **trois** entrées, dont le doublon **intact**,
dans **l'ordre d'origine**. ✅ **R-2 tient** : réécrire le document entier ne détruit pas les
résidus.

**Dates non canoniques venues du disque : résidus, jamais réparées** *(`P8`)* — `2026-02-31T23:59`,
`…T23:59:00Z`, `2026-11-15`, `…T23:59:30`, `+275760-09-13T00:00` ⇒ **`reconnues=0`** pour les cinq,
et le document est **conservé**.

**Aucune injection.** Seuls `jsonDecode` / `jsonEncode` sont employés ; **0 construction manuelle
de JSON dans `lib/`** *(vérifié par commande)*. Sonde `D5` : `<script>`, `"; DROP TABLE …`, un
faux objet JSON complet et `\",\"id\":\"vole` sont **stockés verbatim** et **jamais interprétés** —
l'échappement est celui de la bibliothèque standard. **Aucune requête, aucun template, aucun rendu
HTML**, donc **ni SQLi, ni XSS** : `grep -rniE "rawQuery|execute\(|sqlite|dart:mirrors" lib/` → une
seule occurrence, `jsonDecode`.

**Aucun `print`, aucun `debugPrint`, aucune `StackTrace`, aucun `catch (e)` diffusant un message
technique dans `lib/`** *(vérifié par commande)*. Les deux textes d'échec vivent en **un seul
exemplaire** dans `ActeEcriture`, et **ne contiennent ni chemin, ni nom de fichier, ni code
d'erreur** — conforme à AC-17 « Nominal ». ⚠️ **La seule exception est `B-1`**, précisément parce
qu'il n'attrape pas.

**Sans objet, et je le dis au lieu de laisser un blanc** : **IDOR**, **authz d'endpoint**, **CSRF**,
**CORS**, **hachage de mot de passe**, **gestion de session**. L'application est **locale,
mono-utilisateur, sans compte, sans serveur, sans endpoint et sans réseau** *(vérifié par
commande ci-dessus)* ⇒ **il n'existe aucune ressource appartenant à un tiers, donc aucun contrôle
d'appartenance à exiger.** ⛔ **Ce n'est pas « conforme », c'est « hors surface »** — et cela
changera à la première fonction de synchronisation.

**Les 2 scripts Python de contrôle** : **0** `shell=True`, **0** `eval`, **0** `exec`, **0**
`os.system`, **0** `pickle`. `check_e2e_persistance.py` n'a **aucun** `subprocess` et lit en
**`encoding="utf-8"` explicite** ; `check_gherkin_mapping.py` lit en `utf-8` avec
`errors='replace'` et **reconfigure `sys.stdout`** *(« la classe de bug cp1252 a coûté deux
fois »)*. Leurs écritures vont dans un **`tempfile.TemporaryDirectory()`**, jamais dans le dépôt.
`migration_roundtrip_criterion.py` appelle `subprocess.run` avec une **liste d'arguments** *(⛔
jamais une chaîne de shell)*, résout `dart` par `shutil.which`, et écrit sous
`RACINE/.dart_tool/us012_migration_criterion` — **dans le dépôt, dans un répertoire de travail**.
✅ **Rien à signaler côté injection de commande.**
🔬 **Et l'ironie mérite d'être inscrite** : *ma propre* commande d'inspection a planté sur
`UnicodeEncodeError: 'charmap' codec … cp1252` en lisant le catalogue d'événements. **Les scripts
audités s'en protègent ; l'auditeur, non.** C'est la **quatrième** occurrence de cette classe dans
ce dépôt, et elle confirme le remède déjà inscrit : **la protection doit être dans le script, pas
dans la discipline de celui qui le lance.**

---

## 5. ⛔ Ce que cet audit N'ATTESTE PAS

* ⛔ **Aucun SAST n'a tourné — il n'en existe pas.** `run_gates --gate sast` rend **exit 1** en
  disant que le gate n'existe pas (§1.1). **Toute la revue de code de ce rapport est HUMAINE**, avec
  ce que cela implique : **elle n'est pas exhaustive**. Une seconde lecture pourrait trouver ce que
  j'ai manqué — **et `B-1` prouve que c'est possible**, puisque **quatre relectures** *(design Data,
  design UX, Integration Lock, visa @Dev)* et **344 tests** l'ont laissé passer.
* ⛔ **AUCUN SCAN DE CVE, sur RIEN.** `dart pub outdated` mesure l'**obsolescence**. Les **24
  paquets** ajoutés par cette US *(dont 23 transitifs, `jni`, `objective_c`, `crypto`, `yaml`,
  `ffi`…)* entrent dans le produit **sans qu'aucune base de vulnérabilités n'ait été consultée**.
  Les **~342 lignes de Python** des deux scripts de contrôle, ni les **2 246 lignes** de
  `reports/US-01.2/*.py`, **ne sont couvertes par aucun outil**. ⇒ **la mention « pas de CVE » est
  absente de ce rapport parce qu'elle serait un mensonge.**
* ⛔ **`N-1` n'a PAS été exécuté** : Windows a refusé la création du lien symbolique *(sortie
  citée)*. La conclusion « le `writeAsString` suit le lien » est une **analyse**, pas une mesure.
  **À rejouer sous POSIX.**
* ⛔ **`N-2` n'a PAS été observé sur un appareil** : les emplacements viennent de la **source des
  paquets**, pas d'une exécution. **Borne NM-10** — l'application **n'a jamais tourné sur un
  appareil**, ⛔ et cette borne **ne se lèvera pas avec US-01.3 pour le web**.
* ⛔ **`N-9` (permissions) n'est PAS mesuré** : la valeur rendue sur ce poste est un **artefact
  Windows**. Ne pas la citer comme une preuve.
* ⛔ **Le chemin `path_provider` lui-même n'est pas exercé** : `creerMagasin()` est la ligne que
  **NM-8** déclare non testable. **Je n'ai donc jamais vu le répertoire réel** — toutes mes sondes
  passent par un répertoire temporaire, comme le harnais livré.
* ⛔ **Aucune mesure de concurrence.** Deux instances de l'application écrivant le même document,
  ou l'application concurrencée par un client de synchronisation, **n'ont pas été testées**. Le
  `existsSync()` suivi de `readAsString()` de `lire()` est une **fenêtre TOCTOU** dont
  l'aboutissement est **exactement `B-1`** *(la lecture lève, personne n'attrape)* — le correctif de
  `B-1` la ferme aussi, mais **la course elle-même n'a pas été provoquée**.
* ⛔ **La version web n'a pas été exécutée** *(NM-10)* : que `DocumentStoreStub.ecrire` lève et que
  le message d'AC-17 s'affiche **reste non observé**. `flutter build web --release` **construit** et
  **n'exécute jamais**.
* ⛔ **Aucune revue des `.github/workflows/**` de ce diff** : ils ne sont pas modifiés par cette US.
  Les findings ouverts d'US-00.7 *(actions tierces non épinglées, `emitter` non enforcé,
  `enforce_admins`, **NB-1bis**)* ⇒ **NON AGGRAVÉS par ce diff, et donc non recomptés**, conformément
  au périmètre reçu.
* ⛔ **Ce visa porte sur `5272ed1` et sur rien d'autre** *(NB-6)*. `trace_append.py` n'ayant aucun
  champ `--commit`, **aucune machine ne pourra signaler qu'il a périmé.** Tout commit ultérieur
  touchant `lib/`, `test/`, `scripts/` ou `pubspec.yaml` **invalide ce rapport**, en silence.

---

## 6. Restauration de l'état du dépôt

Trois fichiers de sonde ont été créés sous `test/` puis **supprimés**. ⛔ **Aucun fichier de `lib/`,
`test/`, `scripts/`, ni le SCB, ni le PROJECT_LOG n'ont été modifiés.** `.claude/settings.json` a
été **restauré DEUX FOIS** *(N-11)*.

```
$ git status --porcelain
[vide]
$ ls test/zz_audit_securite*
aucune sonde residuelle
$ git log --oneline -1
5272ed1 docs(us-01.2): arbitrage humain — le cliquet RESTE a 95,2
```

---

## 7. Conditions de lever du verdict

1. **Corriger `B-1`** dans `lire()` *(garde `on FileSystemException`, sentinelle non-JSON — ⛔ **pas**
   `allowMalformed: true`, motif au §2)*.
2. **Livrer AVEC lui** le test qui pose des **octets** *(`writeAsBytesSync`)* et assertionne les
   trois choses : le **hub s'ouvre**, l'**état vide** s'affiche, le document fautif est **conservé**
   sous `echeances.json.illisible-…`. ⚠️ **Le cliquet est à 95,2 et la couverture à 97,9 %** : le
   correctif ajoute des lignes couvertes, **aucun risque de régression du cliquet**.
3. **Rejouer** `run_gates --all`, `check_e2e_persistance.py` *(+ `--selftest`)* et **la sonde de
   `B-1`**, puis **redemander un audit sécurité sur le NOUVEAU commit** *(NB-6 : ce rapport ne se
   transporte pas)*.
4. **N-1, N-4, N-5, N-7** sont des correctifs courts, **cumulables** avec le point 1.
   **N-2** est un **arbitrage @PO / humain**, ➡️ **US-01.3**. **N-3** ➡️ `/audit-methodo` ou US-00.8.
