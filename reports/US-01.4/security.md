# Audit sécurité — US-01.4 « Gestes sur la tuile » (RF-06)

| Champ | Valeur |
|---|---|
| **US** | US-01.4 — Gestes sur la tuile : révélation de la description et retrait d'une échue |
| **SHA audité (NB-6)** | **`8509f44`** (`8509f44acfcc532918c53f3d12a5333d55e030b7`) |
| **Branche** | `feat/US-01.4-gestes-tuile`, **28 commits** vs `origin/main` (lu : `git rev-list --count`) |
| **Périmètre** | `git diff main...HEAD` — 71 fichiers, +17441 / −232 |
| **Date** | 2026-09-11 |
| **Agent / modèle** | @CyberSecurity / Opus 5 (1M context) — `claude-opus-5[1m]` |
| **VERDICT** | ✅ **PASSED** — **0 finding bloquant**, 2 non bloquants, 3 informatifs |

> ⚠️ **NB-6** : ce visa porte **exclusivement** sur `8509f44`. Tout commit
> postérieur **n'est pas couvert**. `trace_append.py` n'a **aucune option
> `--commit`** (vérifié par `--help`) ⇒ le rattachement passe par le
> `rationale`, **convention non enforcée**.

---

## 0. Ce que ce verdict N'ATTESTE PAS

⛔ **À lire avant le verdict.** Ces bornes ne sont pas des précautions de style :
ce sont des **absences d'instrument**, mesurées ci-dessous.

* ⛔ **AUCUN SAST n'a tourné. Il n'en existe aucun dans ce projet.**
  `python scripts/run_gates.py --gate sast` rend **exit 1** (« aucun gate ne
  correspond »). Les gates réellement configurés sont `format`, `analyze`,
  `test`, `deps_audit`, `build` — **aucun `sast`**. Il n'y a donc **aucune
  analyse statique de sécurité** derrière ce PASSED.
* ⛔ **AUCUN SCAN DE CVE N'A EU LIEU, et aucun n'était possible.**
  `deps_audit` exécute `dart pub outdated`, qui mesure l'**OBSOLESCENCE**, ⛔ pas
  la **VULNÉRABILITÉ**. La tentative d'interroger **OSV.dev** pour les
  dépendances directes a été **refusée** (accès réseau bloqué dans cet
  environnement). ⇒ **aucune affirmation d'absence de CVE n'est faite ici.**
* ⛔ **L'application n'a tourné sur AUCUN appareil pour cet audit** :
  `adb` n'est **pas dans le `PATH`** (`adb: command not found`). Le coût réel
  d'une écriture atomique sur un appareil physique reste **non mesuré**.
* ⛔ **Aucun contrôle dynamique** : pas de fuzzing, pas de test de charge, pas
  d'analyse de binaire signé (aucun keystore, aucun build signé n'existe).
* ⛔ **Les findings `N-1` et `N-2` des audits précédents restent OUVERTS** — ils
  vivent dans `document_store_io.dart`, que cette US **ne touche pas** (mesuré :
  `git diff --name-only main...HEAD` ne le liste pas). Ils sont **reportés, pas
  levés**.

---

## 1. Sorties d'outils

### 1.1 Gate SAST — IL N'EXISTE PAS

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

Gates réellement déclarés dans `factory.config.json` (`adapter.components.app.gates`) :

```
"format"     : dart format --output=none --set-exit-if-changed lib test
"analyze"    : flutter analyze
"test"       : flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
"deps_audit" : dart pub outdated --show-all      (blocking: false)
"build"      : flutter build web --release
```

⛔ **Aucune entrée `sast`.** La dette « aucun SAST dans la factory » du
`CLAUDE.md` est **confirmée par exécution**, pas reprise de confiance.

### 1.2 Gate `deps_audit` — obsolescence, PAS vulnérabilité

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
[... transitives ...]
5 upgradable dependencies are locked (in pubspec.lock) to older versions.
✅ app.deps_audit
EXIT=0
```

Dépendances **directes** et leur résolution **épinglée** dans `pubspec.lock`
(fichier **suivi par git** : `git ls-files --error-unmatch pubspec.lock` → OK) :

```
cupertino_icons      direct main  source=hosted  version=1.0.9
flutter              direct main  source=sdk     version=0.0.0
flutter_lints        direct dev   source=hosted  version=6.0.0
flutter_test         direct dev   source=sdk     version=0.0.0
path_provider        direct main  source=hosted  version=2.1.6
```

**Constat** : les 3 dépendances non-SDK sont à la **dernière version
disponible**, et le lock est versionné. ⛔ **Cela ne dit RIEN de leur
vulnérabilité** — voir §0.

**Fait mesuré décisif pour cet audit** :

```
$ git diff --stat main...HEAD -- android/ ios/ pubspec.yaml pubspec.lock .github/
(sortie VIDE)
```

⇒ **US-01.4 ne modifie AUCUNE dépendance, AUCUN manifeste de plateforme,
AUCUN workflow CI.** La surface d'attaque par dépendance est **inchangée**.

### 1.3 `gitleaks` 8.30.1 — secrets

Le dépôt est **PUBLIC depuis le 2026-07-27** ⇒ barrière critique.

**Scan du système de fichiers :**
```
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact
INF scanned ~449724419 bytes (449.72 MB) in 29.7s
INF no leaks found
EXIT=0
```

**Scan de l'HISTORIQUE des 28 commits de la branche :**
```
$ gitleaks detect --source . --config .gitleaks.toml --redact --log-opts="main...HEAD"
INF 28 commits scanned.
INF scanned ~1366762 bytes (1.37 MB) in 4.43s
INF no leaks found
EXIT=0
```

#### 1.3.1 CONTRÔLE NÉGATIF — sans lui, « no leaks found » ne vaut rien

Un scanner muet et un dépôt propre rendent **la même sortie**. Quatre mutants
plantés **hors du dépôt**, avec **la config du projet** :

**Premier essai — ÉCHEC, et l'échec était le MIEN :**
```
m1 = AKIAIOSFODNN7EXAMPLE / wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY  ->  0 finding
```
⛔ **Mutant tiré du vocabulaire de la règle testée** : ce sont les clés
d'**exemple de la documentation AWS**, allowlistées par la config par défaut de
gitleaks (elles contiennent littéralement `EXAMPLE`). Exactement la faute que la
règle du projet interdit. **Mutant refait.**

**Second essai — le cardinal MENTAIT :**
```
WRN leaks found: 4     <- 4 findings pour 4 mutants : ça a l'air juste
```
Comparaison des **ENSEMBLES**, ⛔ pas des cardinaux :
```
m1_aiza.dart -> google-api-key-stitch
m1_aiza.dart -> gcp-api-key          <- m1 produit DEUX findings
m2_aq.dart   -> stitch-token-aq
m4_pem.key   -> private-key
MANQUANTS (attendu - vus) = ['m3_ghp.dart']     <- m3 n'a produit AUCUN finding
ENSEMBLES EGAUX : False
```
⇒ **4 findings ≠ 4 mutants tués.** Un décompte égal n'est pas une preuve
d'équivalence — la règle du projet, vérifiée ici en situation.

**Cause du manquant, mesurée et non supposée :**
```
$ printf '%s' "7Kd2Mq9Xz4Rv1Ns6Tp3Wc8Yh5Jf0Lg2Bq7T" | wc -c
35          <- la règle par défaut `github-pat` attend 36
```
⛔ **Mutant malformé, ⛔ pas un trou du scanner.** Repris à 36 caractères :
```
m1_aiza.dart   -> gcp-api-key
m1_aiza.dart   -> google-api-key-stitch
m2_aq.dart     -> stitch-token-aq
m3bis_ghp.dart -> github-pat
m4_pem.key     -> private-key
MANQUANTS = []
ENSEMBLES EGAUX : True
EXIT_MUTANTS=1
```

✅ **Le scan est ARMÉ et FALSIFIABLE** : il tue les **2 règles propres au
projet** (`google-api-key-stitch`, `stitch-token-aq`) **et** 2 règles par
défaut. **« no leaks found » est donc une MESURE, pas un silence d'outil.**

#### 1.3.2 Grep ciblé sur les lignes AJOUTÉES du diff

```
$ git diff main...HEAD -- lib/ test/ | grep -E "^\+" \
    | grep -inE "password|secret|token|api[_-]?key|credential|bearer|md5|sha1|encrypt|auth"
```
Toutes les occurrences de `token` sont des **tokens du design system**
(`ConcentrationTokens.dureeDisparition`, `fenetreRevelation`, `rayonSurface`…).
⛔ **Aucun jeton d'authentification, aucun secret, aucun MD5/SHA1, aucune
primitive de chiffrement.** `TODO|FIXME|HACK|XXX` dans les lignes ajoutées de
`lib/` : **aucune**.

### 1.4 Gates de qualité — état réel au SHA audité

```
$ flutter analyze
No issues found! (ran in 19.9s)              EXIT=0   (reproduit 2 fois)

$ python scripts/run_gates.py --gate format
Formatted 74 files (0 changed) in 0.95 seconds.
✅ app.format                                 EXIT=0

$ python scripts/run_gates.py --gate test
06:47 +562: All tests passed!
Couverture de lignes : 98.1% (1122/1144) — seuil requis : 95.2% (cliquet)
  [HAUSSE] 98.08% (1122/1144) > cliquet 95.2%
✅ app.test                                   EXIT=0
```

**562 tests verts, couverture 98,1 %.** ⛔ Rappel du projet : la couverture de
lignes est **aveugle à la force des assertions** — elle ne vaut ici que comme
constat de non-régression, ⛔ **pas comme preuve de sécurité**.

---

## 2. Revue manuelle ciblée

### 2.1 Classes OWASP — applicabilité RÉELLE, mesurée

L'applicabilité n'est pas supposée : elle est **établie par recherche sur
`lib/`**.

```
$ grep -rnE "dart:io|dart:html|HttpClient|http://|https://|WebView|Html|url_launcher|Process\.|Socket|eval|Uri\.parse" lib/
```
Seules occurrences : `document_store_io.dart:1: import 'dart:io';` et des
**commentaires** affirmant l'absence de `dart:io` ailleurs.

| Classe | Verdict | Base du verdict |
|---|---|---|
| **IDOR / contrôle d'appartenance** | **N/A** | ⛔ Aucun serveur, aucun compte, aucun multi-utilisateur. Aucune ressource n'a de propriétaire à vérifier. |
| **Injection (SQL/NoSQL/commande)** | **N/A** | ⛔ Aucune base, aucun ORM, aucun `Process.` ni shell. La seule sérialisation est `jsonEncode`/`jsonDecode` — ⛔ **aucune interpolation de chaîne dans une requête**. |
| **XSS / injection de rendu** | **N/A** | ⛔ Aucun `Html`, aucune `WebView`, aucun `innerHTML`. Le texte utilisateur ne transite que par des `Text(...)` et `Semantics(label:)`, qui **ne parsent aucun balisage**. |
| **Authz sur endpoint** | **N/A** | ⛔ **Aucun endpoint.** |
| **CSRF** | **N/A** | ⛔ Aucun cookie, aucune session, aucune requête sortante. |
| **CORS** | **N/A** | ⛔ Aucune origine, aucun appel réseau. |
| **Mots de passe / hachage** | **N/A** | ⛔ Le produit n'a **aucune authentification** et ne stocke **aucun identifiant**. |
| **Secrets en dur** | ✅ **Conforme** | §1.3, contrôle négatif inclus. |

⚠️ **Ces `N/A` sont des constats de PÉRIMÈTRE, pas des exemptions** : ils
deviendront faux le jour où un backend, un compte ou une synchronisation
apparaîtra.

### 2.2 Persistance — intégrité des données (la surface RÉELLE de cette US)

**Chemin d'écriture atomique** (`document_store_io.dart`, ⛔ **non modifié par
cette US**) : `.tmp` + `flush: true` + `rename`, ménage du provisoire si le
`rename` échoue, exception **relancée telle quelle**. Les correctifs des audits
antérieurs (`B-1`, `B-2`, `NB-E`, `NB-F`, `NB-G`) sont **toujours en place**.

**Migration `v2 ⇄ v3`** (ADR-012) — revue ligne à ligne :
* `_v2VersV3` et `_v3VersV2` sont deux **identités distinctes** ; ⛔ **aucune
  entrée n'est touchée dans aucun des deux sens** ⇒ `up ∘ down` est l'identité
  **sur les octets**, l'inversibilité est obtenue **par construction**.
* `migrer` **refuse** une version absente, non entière, `< 1` ou **FUTURE**
  (`return null`) ⇒ ⛔ aucun `up` n'est appliqué sur une forme incomprise.
* ✅ **La forme dangereuse est bien évitée** : un `down` qui « redescendrait
  proprement en retirant la clé » détruirait le retrait et ferait tomber
  **AC-12 « Erreur » d'US-01.2**. Le code ne le fait pas.

**Résidus** (`echeance_document_codec.dart`) : une entrée non reconnue est
**ré-émise octet pour octet à sa place** ; une valeur `retiree` hors domaine
rend l'entrée **résiduelle** (⛔ ni réparée, ni repliée sur `false`) ; la
présence se teste par **`containsKey`**, ⛔ jamais par la nullité (D-4).
✅ Conforme.

**Validation des entrées** (`validation_echeance.dart`) : description bornée à
**80 caractères après `trim`** ; date et heure filtrées par des regex
**ancrées et sans quantificateur imbriqué** (`^(\d{2})/(\d{2})/(\d{4})$`,
`^(\d{2}):(\d{2})$`) ⇒ ⛔ **aucun risque de ReDoS** ; `int.parse` sur des groupes
de 2 à 4 chiffres ⇒ ⛔ **aucun débordement possible** ; la barrière de date est
la **forme canonique**, ⛔ pas une exception (règle V-1). ✅ Conforme.

**Journalisation** :
```
$ grep -rnE "print\(|debugPrint|log\(|stderr|stdout|developer\.log|Logger" lib/
lib/.../gestion_echeances_page.dart:115:  builder: (_) => AlertDialog(
lib/.../widgets/confirmation_suppression.dart:67:  return AlertDialog(
```
Les 2 occurrences sont des `AlertDialog` (le motif `log(` matche `Dialog(`).
⇒ ✅ **ZÉRO journalisation dans `lib/`** ⇒ ⛔ **aucune fuite de description
utilisateur par les logs**.

---

## 3. Findings

### 3.1 BLOQUANTS

**AUCUN.**

Aucun finding ne relève des critères bloquants : pas de finding SAST HIGH
(⛔ aucun SAST), pas de CVE HIGH/CRITICAL sur dépendance directe (⛔ aucun scan
possible — **et l'absence de scan n'est PAS comptée comme un PASS**, elle est
déclarée en §0), pas d'IDOR, pas de secret en dur, pas d'endpoint sans authz.

### 3.2 NON BLOQUANTS

| # | Outil | Emplacement (désigné par son TEXTE) | Sév. | Décision |
|---|---|---|---|---|
| **S-1** | Critère exécutable (mesure) | `validation_echeance.dart` → `_idLibre`, appelé avec `presentes` depuis `valider` | **MOYENNE** | **À CORRIGER** — non bloquant (atteignabilité négligeable en production) |
| **S-2** | Critère exécutable (mesure) | `echeance_document_codec.dart` → `encoder` ; arbitrage **D-8** | **BASSE** | **ACCEPTÉ, borné** |

---

#### S-1 — La garde d'unicité d'`id` ne couvre pas les échéances RETIRÉES

**Cause racine — un paramètre pour DEUX sémantiques.** `valider` reçoit
`presentes`, dont `presentesSurLaGrille` **exclut les retirées**. C'est **juste**
pour la limite de 9 (C-7 : une retirée ne doit pas occuper une place). Mais
`_idLibre(presentes)` **réutilise la même liste** pour un but **différent** :
garantir qu'un `id` est « unique dans la collection ». ⇒ **la collection
vérifiée n'est pas la collection écrite.**

**Conséquence mesurée, ⛔ pas déduite.** Critère exécutable livré :
`reports/US-01.4/id_collision_retiree_criterion.dart` — harnais **réel** (octets
sur disque, `DocumentStoreFichier` + `EcheanceDocumentRepository` de production).

```
$ flutter test reports/US-01.4/id_collision_retiree_criterion.dart

M1  entrees sur disque         = 1
M1  ids sur disque             = {1789120800000000}
M1  entrees RETIREES restantes = 0
M1  document brut = [{"id":"1789120800000000","description":"nouvelle echeance",
                     "dateEcheance":"2027-12-31T23:59"}]
[E] Expected: <1>  Actual: <0>
    ECHEC = la retiree a ete detruite sans confirmation

CN  entrees sur disque         = 2
CN  entrees RETIREES restantes = 1        <- CONTRÔLE NÉGATIF VERT
```

⇒ **L'échéance retirée est SILENCIEUSEMENT DÉTRUITE** et remplacée par la
nouvelle. Le contrôle négatif (même scénario, `id` non colliding) **reste vert**
⇒ le verdict **bascule sur la seule mutation de la fixture** : c'est une
**mesure**, ⛔ pas un artefact.

**Mécanisme** : `encoder` construit `parId = {for (final e in echeances) e.id: e}`.
Dans un littéral de `Map` Dart, **la dernière entrée écrase la précédente** ⇒ la
nouvelle échéance prend la place de la retirée, la ligne de la retirée est
réécrite avec les données de la nouvelle, et la nouvelle n'est pas ré-ajoutée.

**Ce que cela viole** : la garantie écrite dans `encoder` — « une entrée absente
est supprimée — **c'est le seul acte destructif, et il vient d'une confirmation
explicite (AC-7)** ». Ici **aucune confirmation** n'a eu lieu. Et ADR-012 promet
qu'un retrait **conserve** l'échéance.

**⛔ POURQUOI CE N'EST PAS BLOQUANT — la borne, énoncée honnêtement.**
`_idLibre` dérive l'`id` de `clock.now().microsecondsSinceEpoch`. En production
la `Clock` est `SystemClock`, dont la valeur **avance** ; l'`id` d'une retirée
appartient au **passé**. Une collision exige donc que l'horloge **recule** ET
retombe sur **la microseconde exacte** d'une création passée. ⇒ **atteignabilité
négligeable**, et **aucun attaquant** n'est en position d'y contribuer (⛔ aucune
entrée réseau, produit mono-utilisateur, le seul acteur est le propriétaire de
l'appareil). **C'est un défaut d'INVARIANT et de défense en profondeur, ⛔ pas
une vulnérabilité exploitable.**

**Correctif proposé (sans changer aucun comportement d'AC)** : faire porter la
recherche d'`id` libre sur la liste **complète**, en la distinguant de la liste
servant à la limite de 9 — les deux besoins ne doivent pas continuer à partager
un seul paramètre. ➡️ **À porter à US-00.8** si l'arbitrage le veut hors de ce
cycle.

---

#### S-2 — Croissance non bornée (D-8) : pas un épuisement de stockage, une amplification d'écriture

`grep -rniE "plafond|purge|limite.*historique|prune|compact" lib/` ne rend
**aucune** occurrence pertinente ⇒ **l'absence de plafond est confirmée dans le
code**, conformément à l'arbitrage D-8.

Critère exécutable livré : `reports/US-01.4/croissance_retirees_criterion.dart`
(chemin de **production**, ⛔ pas une copie du format).

```
n=    0 retirees  ->      115 octets
n=   10 retirees  ->     1215 octets
n=  100 retirees  ->    11295 octets
n= 1000 retirees  ->   113895 octets
OCTETS PAR RETIREE (marge 0 -> 1000) = 113.8
EXTRAPOLATION a n=10 000             = 1137915 octets

borne LUE du domaine (longueurMaxDescription) = 80
PIRE CAS octets par retiree      = 166.9
PIRE CAS extrapolation n=10 000  = 1669015 octets

taille AVANT ecriture = 113813 octets
taille APRES ecriture = 113916 octets
=> octets REECRITS par UNE creation = 113916 (le document ENTIER)
```

**Verdict de disponibilité — constat BORNÉ :**
* ⛔ **L'épuisement de stockage n'est PAS un risque réaliste** : **1,1 à 1,7 Mo**
  à 10 000 retirées. Chaque retirée exige un **double appui manuel sur une
  échue** ⇒ ⛔ aucun chemin automatisable, ⛔ aucun acteur distant.
* ⚠️ **Le risque réel est l'AMPLIFICATION D'ÉCRITURE, et il est mesuré** :
  **toute** écriture (création, édition, suppression, retrait) réécrit le
  **document ENTIER** — `113 916` octets pour ajouter **une** échéance à
  n=1000. Le coût d'une écriture croît donc **linéairement avec l'historique**,
  **sans borne**, et il est **payé deux fois** (écriture du `.tmp` + `rename`).
* ⛔ **Ce que cela n'atteste pas** : **jamais mesuré sur un appareil réel**
  (`adb: command not found`). La question même de D-8 reste donc **ouverte**.

**Décision : ACCEPTÉ.** C'est un arbitrage humain daté (« mesurer d'abord,
borner ensuite »), et une purge serait un acte **destructif**. ⛔ **Aucun
plafond n'est recommandé ici** — la recommandation est de **mesurer sur
appareil** avant de borner.

### 3.3 INFORMATIFS

| # | Emplacement | Observation |
|---|---|---|
| **S-3** | `CLAUDE.md` → « 141,0 octets par retirée » | ⛔ **Ce n'est pas une constante, c'est une valeur de FIXTURE.** Mes deux mesures l'**encadrent** : **113,8** (description de 26 car.) et **166,9** (description à la borne **80**, valeur **LUE** dans `ValidationEcheance.longueurMaxDescription`). Le coût dépend de la **description saisie par l'utilisateur** ⇒ à lire comme un **intervalle**, ⛔ jamais comme un chiffre. Même classe que le facteur de durée déjà déclaré non reproductible. |
| **S-4** | `document_store_io.dart` (⛔ **non touché** par cette US) | **`N-1`** (lien symbolique, création non exclusive en répertoire partagé) et **`N-2`** (répertoire partagé sous Windows/Linux) **restent OUVERTS**. La destination de mise de côté reste **PRÉVISIBLE** (`NB-G`, résidu assumé). **Reportés, ⛔ pas levés.** |
| **S-5** | `android/app/src/main/AndroidManifest.xml` (⛔ **non touché** par cette US) | `android:allowBackup` **n'est pas déclaré** ⇒ valeur **par défaut `true`** sur Android. `echeances.json` (descriptions du pratiquant) est donc **éligible à la sauvegarde automatique** vers le cloud et à `adb backup`. ⚠️ La permission `INTERNET` n'est présente que dans les manifestes **`debug` et `profile`** (défaut Flutter), **absente du `main`** — ✅ correct. ➡️ **À trancher par US-01.3** (chaîne de déploiement mobile), ⛔ hors périmètre d'US-01.4. |

---

## 4. Note de méthode — incidents de mon propre outillage, consignés

⛔ **Les instruments de contrôle se trompent aussi ; ce projet en a déjà payé le
prix. Ces incidents sont écrits pour qu'ils ne soient pas rejoués.**

1. **Mon premier contrôle négatif gitleaks était FAUX**, et pour la faute même
   que la règle du projet nomme : **mutant tiré du vocabulaire de la règle
   testée** (les clés d'exemple AWS, allowlistées). Puis **le cardinal a menti**
   (`leaks found: 4` pour 3 fichiers vus). Seule la comparaison d'**ENSEMBLES**
   l'a révélé.
2. **Mon artefact d'audit a rendu un gate REQUIS ROUGE.** Un fichier `.dart`
   déposé dans `reports/` **entre dans le paquet analysé** :
   `flutter analyze` → **exit 1**, 6 × `avoid_print`. **C'est pourquoi les
   critères existants du projet dans `reports/` sont en Python.** Corrigé par une
   directive `ignore_for_file` **documentée dans le fichier** ; état final
   **vérifié : `No issues found!`, exit 0, reproduit 2 fois**.
3. ⚠️ **Une alerte `dead_code` sur `validation_echeance.dart` est apparue à un
   seul relevé, puis NE S'EST PAS REPRODUITE** (4 exécutions ultérieures :
   fichiers séparés, puis les deux ensemble ×2 ⇒ toutes `No issues found!`,
   exit 0). `git diff -- lib/` : **vide**. ⇒ **artefact d'analyse transitoire**
   (relevé pendant la réécriture du fichier). ⛔ **Un relevé unique n'est pas une
   mesure** — consigné plutôt que tu.

---

## 5. Reproduire cet audit

```bash
git checkout 8509f44
python scripts/run_gates.py --gate sast          # attendu : exit 1, LE GATE N'EXISTE PAS
python scripts/run_gates.py --gate deps_audit
python scripts/run_gates.py --gate format
python scripts/run_gates.py --gate test
flutter analyze
gitleaks detect --no-git --source . --config .gitleaks.toml --redact
gitleaks detect --source . --config .gitleaks.toml --redact --log-opts="main...HEAD"
flutter test reports/US-01.4/id_collision_retiree_criterion.dart   # ROUGE = S-1 présent
flutter test reports/US-01.4/croissance_retirees_criterion.dart    # imprime les mesures S-2
```

⛔ **`id_collision_retiree_criterion.dart` est ROUGE AU SHA AUDITÉ, et c'est
VOULU** : il devient **VERT** le jour où S-1 est corrigé. C'est son **critère de
sortie**, ⛔ pas un test cassé.

---

## 6. Verdict

# ✅ PASSED — `8509f44`

**0 bloquant** · **2 non bloquants** (S-1 MOYENNE *à corriger*, S-2 BASSE
*acceptée*) · **3 informatifs** (S-3, S-4, S-5).

Le code de cette US **ne crée aucune surface d'attaque nouvelle** : ⛔ aucun
réseau, ⛔ aucune dépendance ajoutée, ⛔ aucun secret, ⛔ aucune journalisation,
⛔ aucun manifeste de plateforme touché. Les garanties d'intégrité de la
persistance (écriture atomique, migration inversible par construction,
conservation des résidus) sont **en place et vérifiées**.

⛔ **Ce PASSED est conditionné aux bornes du §0** — en particulier **l'absence
totale de SAST et de scan de CVE**, qui ne sont **pas** des résultats négatifs
mais des **instruments manquants**.
