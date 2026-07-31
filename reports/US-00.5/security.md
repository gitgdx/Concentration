# US-00.5 — Audit de sécurité (@CyberSecurity, contexte frais)

| Champ | Valeur |
|---|---|
| **US** | US-00.5 — ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution |
| **Branche** | `feat/US-00.5-adr-stack-constitution` — **PR #17** *(PR nº 1 de la séquence C-1 : ADR-001 SEUL)* |
| **Base de comparaison** | `git diff main...HEAD` · merge-base **`856c366`** |
| **Agent** | @CyberSecurity — **contexte frais** (Constitution Art. 2) |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-07-30 |
| **Verdict** | ✅ **PASS** — **0 finding bloquant** · **5 findings non bloquants** *(dont 4 pré-existants)* |

---

## ⛔ BORNES DU VERDICT — à lire AVANT le verdict, jamais après

Ces bornes ne sont pas des précautions de style : elles délimitent **ce que ce PASS n'atteste pas**.

1. 🔴 **AUCUN scanner de CVE n'existe dans cette factory.** Vérifié par recherche outillée (§2.2) :
   ni `osv-scanner`, ni `trivy`, ni `snyk`, ni `grype`, ni `pip-audit`, ni Dependabot
   (`.github/dependabot.yml` **absent**). **Ce PASS ne s'appuie donc sur AUCUN scan de vulnérabilité** —
   il n'y en a pas un seul à exécuter. Mon critère bloquant « CVE HIGH/CRITICAL sur une dépendance
   directe » est **structurellement invérifiable sur ce dépôt** ; sa justification documentée est en §5.
2. 🔴 **AUCUN SAST ne couvre le code applicatif.** `run_gates.py --gate sast` → **exit 1, « aucun gate ne
   correspond »**. Le seul analyseur de sécurité de la factory, `actionlint`, couvre les **workflows
   GitHub Actions** — **rien** ne couvre le **code Dart**. Mon PASS ne repose sur **aucune** sortie de
   SAST applicatif.
3. ⛔ **Aucune recherche d'injection, d'IDOR, de XSS, de CSRF ou d'authz d'endpoint n'a été menée — parce
   qu'il n'y a AUCUNE surface applicative dans ce diff, et je ne le contourne pas.** Le diff porte
   **11 fichiers, tous documentaires** : **0 fichier Dart**, **0 script**, **0 workflow**, **0 endpoint**,
   **0 requête**, **0 rendu**, **0 dépendance**. Prétendre avoir « revu l'authz » ici serait un audit de
   complaisance. Ce que j'ai audité à la place est énoncé en §1.
4. ⚠️ **Le dépôt est PUBLIC** (`visibility: "public"`, vérifié ce jour) depuis le 2026-07-27 :
   toute fuite de secret serait **irréversible**. C'est ce qui rend `gitleaks` (§2.3) **critique** et non
   accessoire.
5. ⚠️ **Aucune détection automatique de dérive de la protection de `main`.** Mon constat du §4 est un
   relevé **manuel, daté d'aujourd'hui**, en lecture seule. Il ne vaut **pas** pour demain.

---

## 1. Ce que j'ai réellement audité — pourquoi cet audit n'est pas vide

L'US ne livre **aucun code**. Le risque de sécurité qu'elle porte est **d'une autre nature, et il est
réel** : *cette US écrit dans le texte normatif et dans le registre des décisions ce que la factory
garantit en matière de sécurité.* Un énoncé faux y est directement exploitable comme **fausse
assurance** — un contributeur ou un auditeur croirait couvert ce qui ne l'est pas.

L'objet de mon audit est donc : **la véracité, mesurée par exécution, de chaque affirmation de sécurité
introduite par ce diff** — plus les contrôles d'hygiène habituels (secrets, fichiers protégés, état de
l'enforcement).

---

## 2. Sorties d'outils — brutes

### 2.1 `python scripts/run_gates.py --gate sast`

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

🔴 **Le gate SAST n'existe pas.** Ce n'est pas un problème de nom : la **fonction** est absente de la
factory (§2.2 : aucun outil de SAST applicatif n'est installé, ni en local ni en CI).

### 2.2 `python scripts/run_gates.py --gate deps_audit`

```
$ python scripts/run_gates.py --gate deps_audit
▶ app.deps_audit — (.) $ dart pub outdated --show-all
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name                  Current   Upgradable  Resolvable  Latest
direct dependencies:
cupertino_icons               1.0.9     1.0.9       1.0.9       1.0.9
flutter                       (sdk)     (sdk)       (sdk)       (sdk)
dev_dependencies:
flutter_lints                 6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                  (sdk)     (sdk)       (sdk)       (sdk)
[... 24 dépendances transitives, dont 4 marquées * : meta, vector_math, matcher, test_api ...]
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).
EXIT=0
```

⚠️ **À ne PAS sur-lire, et c'est tout l'enjeu de cette US** : cette sortie est un **tableau
d'obsolescence**. Elle ne contient **aucune** information de vulnérabilité. Le `✅` ci-dessus signifie
« *les versions résolvables sont les plus récentes* », **pas** « *aucune CVE* ».

Recherche exhaustive d'un scanner de CVE dans le dépôt (hors `docs/` et `reports/`, pour ne pas compter
les mentions documentaires) :

```
$ grep -rniE "osv-scanner|trivy|snyk|grype|dependabot|pip-audit|npm audit|dart pub audit|safety check" \
    --include="*.yml" --include="*.yaml" --include="*.json" --include="*.py" --include="*.sh" --include="*.toml" .
(aucun résultat)

$ ls .github/dependabot.yml
ls: cannot access '.github/dependabot.yml': No such file or directory
```

🔴 **Zéro scanner de CVE. Zéro Dependabot.** Confirmé.

### 2.3 `gitleaks` — 8.30.1, **trois passes**

```
$ gitleaks version
8.30.1

# Passe 1 — arbre de travail complet
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~120845021 bytes (120.85 MB) in 11.3s
INF no leaks found
EXIT=0

# Passe 2 — HISTORIQUE des commits de la branche (856c366..HEAD)
$ gitleaks detect --source . --config .gitleaks.toml --log-opts="856c366..HEAD" --redact -v
INF 2 commits scanned.
INF scanned ~131346 bytes (131.35 KB) in 904ms
INF no leaks found
EXIT=0

# Passe 3 — ciblée sur les livrables de l'US
$ gitleaks detect --no-git --source docs/adr   --config .gitleaks.toml --redact -v
INF scanned ~93859 bytes (93.86 KB) in 278ms
INF no leaks found        EXIT=0
$ gitleaks detect --no-git --source reports/US-00.5 --config .gitleaks.toml --redact -v
INF scanned ~7221 bytes (7.22 KB) in 255ms
INF no leaks found        EXIT=0
```

✅ **Aucun secret, ni dans l'arbre, ni dans l'historique de la branche, ni dans les livrables.**

> ⚠️ **Piège du projet, explicitement évité** *(il a été rencontré trois fois)* : je n'ai **pas** conclu
> par un `grep` de motifs de secret, qui **matche la documentation des motifs**. Le démenti ci-dessus est
> rendu par **`gitleaks` avec la configuration du dépôt** — l'outil de référence — sur **trois périmètres
> distincts, dont l'historique git**. Aucun `grep` naïf n'entre dans ce verdict.

### 2.4 Contrôle des fichiers protégés — absents du diff

```
$ git diff --name-status main...HEAD
M	BACKLOG.md
M	PROJECT_LOG.md
M	STORY_CERTIFICATION_BOARD.md
A	docs/adr/ADR-001-choix-de-stack.md
M	docs/epics/EPIC_00-fondations.md
A	docs/stories/US-00.5-adr-stack-constitution.md
A	docs/trace/US-00.5/events.jsonl
A	reports/US-00.5/conformite_ac.txt
A	reports/US-00.5/entry_state/art4_vs_gates_reels.txt
A	reports/US-00.5/entry_state/registre_et_sast.txt
A	tests/features/US-00.5-adr-stack-constitution.feature
(11 fichiers, 1341 insertions, 9 suppressions)

$ git diff --name-only main...HEAD | grep -E "factory\.config\.json|^\.claude/hooks/|^scripts/githooks/|\.gitleaks\.toml|run_gates\.py|factory_sync\.py|^\.github/workflows/|CONSTITUTION\.md"
rc=1   ← AUCUNE correspondance
```

✅ **Aucun fichier d'enforcement touché** : `factory.config.json`, `.claude/hooks/*`,
`scripts/githooks/*`, `.gitleaks.toml`, `run_gates.py`, `factory_sync.py`, `.github/workflows/*` sont
**tous absents du diff**. ✅ **`CONSTITUTION.md` est également absent** — conforme à la séquence AC-4
(PR nº 1 = ADR-001 seul).

### 2.5 Surface applicative — mesurée, pas supposée

```
$ ls -d android ios web linux macos windows
android    web
ios, linux, macos, windows : No such file or directory

$ ls -R lib test
lib:  main.dart
test: widget_test.dart

$ grep -rniE "http|socket|dio|websocket|shared_preferences|sqflite|hive|path_provider|dart:io" lib/
(aucun résultat)

$ pubspec.yaml → dependencies : flutter (sdk), cupertino_icons ^1.0.8
                 dev_dependencies : flutter_test (sdk), flutter_lints ^6.0.0
```

✅ **0 dépendance réseau, 0 dépendance de persistance, 1 fichier applicatif** (`lib/main.dart`),
**2 dépendances directes** dont une seule tierce (`cupertino_icons`, à sa dernière version).
**iOS absent, Web et Android présents.**

---

## 3. 🔴 LE POINT CENTRAL — les quatre affirmations de sécurité d'ADR-001, vérifiées une par une

**Méthode : exécution, pas relecture.** Chaque ligne ci-dessous est adossée à une commande du §2.

| # | Ce qu'ADR-001 affirme | Vérification | Verdict |
|---|---|---|---|
| **1** | « `deps_audit` … mesure l'**obsolescence** … ⛔ **pas** la vulnérabilité » | `factory.config.json` → `app.deps_audit.cmd` = **`dart pub outdated --show-all`** ; sortie = tableau de versions, **0 information de vulnérabilité** (§2.2) | ✅ **EXACT** |
| **2** | « `deps_audit` n'est **PAS** bloquant » | `factory.config.json` → `app.deps_audit` porte **`"blocking": false"`** — le **seul** gate à le porter. Contre-vérifié dans `run_gates.py:67` : `blocking = gate.get("blocking", True)` → **l'absence de la clé vaut bloquant**, donc `format`, `analyze`, `test` et `build` **sont** bloquants et `deps_audit` **seul** ne l'est pas | ✅ **EXACT** |
| **3** | « **aucun scan de CVE n'existe dans cette factory** » | `grep` exhaustif sur `*.yml/*.yaml/*.json/*.py/*.sh/*.toml` → **0 résultat** ; `.github/dependabot.yml` **absent** (§2.2) | ✅ **EXACT** |
| **4** | « **AUCUN SAST** … `actionlint` … couvre les **workflows**, **rien** ne couvre le **code Dart** » | `--gate sast` → **exit 1** (§2.1). `actionlint` est un **step du job `governance`** (`ci.yml:90`), **épinglé par SHA256** (`v1.7.12`, `8aca8db9…a3d8`, vérifié par `sha256sum -c -`), et le job `📋 Governance (SCB + traçabilité + synchro)` est bien l'un des **4 contextes REQUIS** (§4). Son périmètre est `./actionlint` = **les workflows** | ✅ **EXACT** |

> ✅ **Aucune des quatre affirmations n'est ni trop pessimiste ni trop rassurante.** J'ai cherché les deux
> sens, comme demandé. En particulier, ADR-001 **ne minimise pas** `actionlint` (il le crédite
> explicitement, avec son épinglage) et **ne le sur-vend pas** (il borne son périmètre aux workflows) :
> la formulation « **partiellement compensé** … rien ne couvre le code Dart » est **exactement** ce que
> mesure l'outil.

**Contre-vérification des deux affirmations voisines, non demandées mais adjacentes** — un ADR
**immuable** ne doit porter aucune affirmation fausse :

| Affirmation ADR-001 | Vérification | Verdict |
|---|---|---|
| « **iOS n'est PAS scaffoldé** » | `ls -d ios` → **absent** ; `android` et `web` présents (§2.5) | ✅ **EXACT** |
| « le gate `build` = `flutter build web --release`, **preuve de repli**, un `build` vert signifie *compile pour le web*, **pas** *constructible pour sa cible* » | `factory.config.json` → `app.build.cmd` = **`flutter build web --release`** | ✅ **EXACT** |
| « l'absence de backend **supprime** une surface entière de risques : ni API publique, ni authentification, ni transport de données » | `lib/` = **1 fichier** · **0** dépendance réseau ou de persistance (§2.5) | ✅ **VRAI AUJOURD'HUI** — mais **non borné dans le temps** → **finding NB-2** |

---

## 4. Art. 4 de la Constitution — la fausse assurance, et sa **gravité mesurée**

### 4.1 Le fait

Texte **actuel** de l'Art. 4, sur `main` **et** sur `HEAD` *(cité littéralement — jamais par numéro de
ligne, 3ᵉ leçon de méthode d'US-00.7)* :

> « Les seuils de couverture et les gates bloquants (lint, typecheck, **SAST**, **audit de dépendances**,
> tests) sont définis en **un seul endroit** : `factory.config.json` → `adapter.components.*.gates` et
> `coverage_min` / **`coverage_ratchet`**. »

Confronté à l'exécution :

| L'Art. 4 annonce | Réel, par exécution | Nature |
|---|---|---|
| **`SAST`** parmi les **gates bloquants** | `--gate sast` → **exit 1**, « aucun gate ne correspond » ; **aucun** outil de SAST applicatif dans le dépôt | 🔴 **FAUX — fausse assurance de SÉCURITÉ** |
| **audit de dépendances** parmi les **bloquants** | `app.deps_audit` → **`"blocking": false"`**, et il mesure l'**obsolescence** | 🔴 **FAUX ×2** *(propriété **et** fonction)* |
| seuils dont **`coverage_ratchet`** | clé **absente** de `factory.config.json` *(schéma seulement)* | 🔴 **FAUX** *(qualité, hors sécurité)* |

**✅ L'US a donc raison, et sur les trois points.** Je confirme aussi, indépendamment, l'**interprétation
restrictive** que @Architect s'est imposée dans `reports/US-00.5/entry_state/art4_vs_gates_reels.txt` :
`lint` et `typecheck` sont des **catégories génériques** réalisées par `dart format` et
`flutter analyze` — les compter comme faussetés aurait été une **sur-affirmation**. Les faussetés sont
**trois**, pas cinq. **L'US ne charge pas son propre dossier.**

### 4.2 La gravité — **depuis combien de temps ce texte est-il faux ?**

```
$ git log --date=short --format="%h %ad %s" -- docs/governance/CONSTITUTION.md
0a2e5ab 2026-07-24 chore(init): initialisation factory Concentration
```

🔴 **`CONSTITUTION.md` n'a JAMAIS été modifié depuis sa création.** L'Art. 4 annonce donc un
**SAST bloquant inexistant depuis le 2026-07-24 — soit 6 jours, et l'intégralité de la vie du projet.**

Et voici la mesure qui donne à ce finding sa vraie gravité :

```
$ grep -rln "gate sast\|aucun gate ne correspond" reports/
reports/US-00.2/security.md      (2026-07-26)
reports/US-00.3/security.md
reports/US-00.4/security.md
reports/US-00.7/security.md      (2026-07-28)
reports/US-00.7/security_reaudit.md

$ grep -rn "Art. 4" reports/US-00.4/security.md reports/US-00.7/security.md
(aucun résultat)
```

⛔ **L'absence du gate SAST était consignée dans un rapport de sécurité depuis le 2026-07-26. Aucun des
5 audits de sécurité qui l'ont constatée n'a jamais ouvert l'Art. 4 pour vérifier si le texte suprême
prétendait le contraire.** Pendant **4 jours**, la factory a donc simultanément :

* **su**, par écrit et par exécution, qu'aucun SAST n'existait ;
* **affirmé**, dans son texte normatif, qu'un SAST **bloquant** était en place ;
* **certifié 5 US** dans cet état — dont **US-00.7**, l'US même dont l'objet était la mise en cohérence
  du corpus.

**Portée de la fausse assurance** : un contributeur ou un auditeur lisant l'Art. 4 — le seul article qui
énumère les gates bloquants — en conclut que **le code applicatif est couvert par une analyse statique de
sécurité**. Il ne l'est pas, et rien dans le corpus normatif ne le démentait. C'est **la classe de défaut
la plus grave qu'un texte de gouvernance puisse porter** : non pas une règle absente, mais une **règle
annoncée comme appliquée alors qu'elle n'existe pas** — précisément ce que la Constitution elle-même
condamne (« *une règle sans mécanisme d'application est un vœu, pas une règle* »).

### 4.3 Ce que cette US en fait — et pourquoi ce n'est **pas** un finding contre elle

⚠️ **Point de méthode que je souligne, parce qu'il détermine mon verdict** : cette fausse assurance
**existe sur `main` avant cette US** et n'est **pas** introduite par elle. US-00.5 est la **première** à
la détecter, à la mesurer par exécution, et à la programmer en correction (**AC-3**, **PR nº 2 dédiée**).
Elle publie même, dans son diff, la sortie brute qui l'établit
(`reports/US-00.5/entry_state/art4_vs_gates_reels.txt`).

⛔ **Mais l'exactitude de l'Art. 4 n'est PAS encore livrée** : `CONSTITUTION.md` est **absent du diff**
(§2.4), conformément à la séquence C-1. **Au moment où j'écris, la fausse assurance de sécurité de
l'Art. 4 est TOUJOURS EN VIGUEUR sur `main`.** Le correctif est **programmé, pas acquis**. → **NB-4**,
et **je borne explicitement mon PASS là-dessus** : je certifie qu'ADR-001 dit vrai, **pas** que le corpus
normatif est devenu exact.

### 4.4 Contrôle de non-régression documentaire

✅ Ce diff **ne « corrige » aucun énoncé devenu vrai** : `CLAUDE.md` **absent du diff**,
`docs/GIT_PROTECTION.md` **absent du diff**, phrase « *requis par la protection de branche* »
**non touchée**. Aucune régression documentaire en sens inverse.

---

## 5. État de l'enforcement de `main` — relevé manuel, lecture seule, daté

```
$ gh api repos/gitgdx/Concentration/branches/main/protection --jq '{...}'
{
  "contexts": ["🔐 Secrets scan (gitleaks)", "📋 Governance (SCB + traçabilité + synchro)",
               "check-branch-name", "📱 App (gates run_gates.py)"],
  "strict": true,
  "enforce_admins": true,
  "force_push": false,
  "deletions": false,
  "conv_res": true,
  "reviews": { "required_approving_review_count": 0, "dismiss_stale_reviews": false,
               "require_last_push_approval": false }
}

$ gh api repos/gitgdx/Concentration/branches/main --jq '.protected'
true

$ gh api repos/gitgdx/Concentration --jq '{visibility, private}'
{"private": false, "visibility": "public"}
```

✅ **La protection de `main` est TOUJOURS EN VIGUEUR au 2026-07-30** : `protected: true`, **4 contextes
requis** conformes à `factory.config.json` → `status_checks`, **`enforce_admins: true`**,
`strict: true`, force-push et suppression refusés, résolution des discussions exigée.

⚠️ **Bornes de ce constat, que je ne masque pas** :
* Il est **manuel et daté d'aujourd'hui**. **Aucune détection automatique de dérive n'existe** — un
  administrateur peut retirer la règle sans qu'aucun mécanisme ne le signale.
* `required_approving_review_count: 0` → **aucune barrière machine** n'exige une approbation. C'est le
  constat du **critère 27 d'US-00.7, demeuré NON LEVÉ**. Il pèse directement sur la **PR nº 2**
  (amendement constitutionnel), dont l'approbation humaine sera **déclarative**.
* Tout l'édifice reste **conditionnel à la visibilité PUBLIQUE** du dépôt.

---

## 6. Findings

### 6.1 🟢 Findings BLOQUANTS : **AUCUN**

Balayage explicite de mes **cinq** critères bloquants, avec la **justification documentée** exigée par
mon rôle :

| Critère bloquant | Constat | Justification |
|---|---|---|
| **Finding SAST de sévérité HIGH** | **Aucun** | ⛔ **Et je ne peux pas prétendre le contraire : le gate SAST n'existe pas** (§2.1). Il n'y a **aucune** sortie de SAST applicatif dans ce verdict. En revanche, le diff contient **0 ligne de code** — aucun SAST, existant ou non, n'aurait eu quoi que ce soit à analyser. |
| **CVE HIGH/CRITICAL sur une dépendance directe** | **Non établi — et INVÉRIFIABLE sur ce dépôt** | 🔴 **Justification documentée, exigée par mon rôle** : **aucun scanner de CVE n'existe** (§2.2). Ce que je peux établir par l'outil, et qui borne strictement le risque **introduit par cette US** : le diff **n'ajoute, ne retire ni ne modifie AUCUNE dépendance** (`pubspec.yaml` et `pubspec.lock` **absents du diff**, §2.4) ; la surface directe est de **2 dépendances** (`flutter` SDK + `cupertino_icons 1.0.9`), **toutes à leur dernière version résolvable**. ⛔ **Ceci n'est PAS un verdict d'absence de CVE** — c'est un verdict d'**absence de delta**. Le risque de CVE du dépôt est **inchangé, non mesuré, et non mesurable ici**. |
| **IDOR** | **Sans objet** | **0 ressource, 0 endpoint, 0 contrôle d'appartenance** dans le diff (§2.5, borne 3). |
| **Secret en dur** | **Aucun** | `gitleaks` 8.30.1, **3 passes** dont l'**historique de la branche** → **`no leaks found`** ×4 (§2.3). Dépôt **public** → contrôle traité comme critique. |
| **Endpoint sans contrôle d'authz** | **Sans objet** | **Aucun endpoint** n'existe dans le projet (§2.5). Voir toutefois **NB-1** pour le contrôle d'écriture sur le texte normatif, que je qualifie **sans** le classer bloquant. |

### 6.2 🟠 Findings NON BLOQUANTS

`[Outil] | [Fichier:Repère littéral] | [Sévérité] | [Décision]`

---

#### **NB-1** · 🟠 **MEDIUM** · `CONSTITUTION.md` : ni prévention, ni **détection**
`[Lecture du hook + grep outillé]` | `.claude/hooks/protect_files.sh` — clause `case` des fichiers
d'enforcement | **MEDIUM** | **ACCEPTÉ, pré-existant, correctement versé à US-00.8 — reQUALIFIÉ par moi**

**Contre-vérifié, confirmé.** Le hook couvre exactement :

```
scripts/githooks/*  |  .claude/settings.json  |  .claude/hooks/*  |  .gitleaks.toml
scripts/install_hooks.sh  |  factory.config.json  |  scripts/factory_env.sh
scripts/factory_sync.py   |  scripts/run_gates.py                        + *.env
```

⛔ **`docs/governance/**` n'y figure pas.** Le constat de l'US (R-2, et le tableau des écarts d'ADR-001)
est **exact**.

**🔍 Ma qualification — elle diffère de la lecture spontanée, et c'est le cœur de ce finding.**

**Ce n'est PAS une faille d'autorisation, et aucune implémentation ne pourrait en faire une.** Trois
raisons, chacune vérifiée :

1. **Agents et humain partagent le même compte et les mêmes droits.** `collaborators` = `gitgdx` seul ;
   `mergedBy.is_bot` rend **`false`** même pour une fusion exécutée par un agent, qui opère avec le
   **jeton de l'humain**. **Aucune preuve machine de provenance n'existe sur ce dépôt.** Un contrôle
   d'autorisation suppose deux identités distinctes ; il n'y en a qu'une.
2. **`protect_files.sh` est un hook `PreToolUse(Edit|Write)`** — vérifié dans `.claude/settings.json`.
   Il n'intercepte **que** les outils `Edit` et `Write`. Le hook `PreToolUse(Bash)`,
   `block_dangerous_bash.sh`, que j'ai lu intégralement, bloque `--no-verify`, le push direct sur `main`,
   le force-push, la réécriture d'historique, l'altération de `core.hooksPath`, l'écriture dans un `.env`
   et le commit sur `main` — mais **rien concernant les fichiers d'enforcement**. ⚠️ **Conséquence que je
   souligne parce qu'elle change la lecture du périmètre** : **même les fichiers que
   `protect_files.sh` protège** (y compris `factory.config.json`) restent **écrivables par un agent via
   `Bash`** (`sed -i`, redirection, `python -c "open(...,'w')"`). Le mécanisme entier est un
   **garde-fou d'accident et de délibération**, **pas une frontière d'autorisation**. Ajouter
   `docs/governance/**` au hook élèverait la barre du **geste involontaire** — bénéfice réel, il rend
   l'édition **explicite et visible** — mais ne rendrait l'édition **ni impossible ni prouvable**.
3. Le durcissement utile est donc la **détection**, exactement comme pour la dette `emitter`.

**🔴 Et c'est là que je durcis le constat de l'US** — voici ce que ni le Story File ni ADR-001 ne disent :

```
$ grep -rn "CONSTITUTION" scripts/*.py scripts/githooks/* .github/workflows/*.yml .claude/hooks/*
scripts/githooks/pre-commit:5      # Constitution : docs/governance/CONSTITUTION.md      ← COMMENTAIRE
.github/workflows/ci.yml:36        # Constitution : docs/governance/CONSTITUTION.md.     ← COMMENTAIRE
.claude/hooks/block_dangerous_bash.sh:4  # Constitution : ... (Art. 1, 2, 6)             ← COMMENTAIRE
.claude/hooks/session_start.sh:29        echo "Rappels : Constitution ..."               ← RAPPEL
```

⛔ **Les quatre seules occurrences de `CONSTITUTION` dans tout l'outillage sont des COMMENTAIRES et un
message d'accueil. Aucun script, aucun hook, aucun gate CI ne lit, ne vérifie ni ne surveille son
contenu.** L'**asymétrie** est le vrai finding : `factory.config.json` dispose de **deux** couches — le
hook **et** `factory_sync.py --check`, gate **requis** du job `📋 Governance`, qui détecte toute dérive
entre la config et ses projections. **`CONSTITUTION.md` est le seul artefact normatif du projet à
n'avoir NI prévention NI détection** — alors qu'il est la source de tous les articles que les autres
mécanismes appliquent.

**Pourquoi non bloquant** : (i) **pré-existant** — `protect_files.sh` est **inchangé depuis le
2026-07-24** (`git log` → commit unique `0a2e5ab`), cette US ne le dégrade pas ; (ii) le diff **ne touche
pas** `CONSTITUTION.md` (§2.4) ; (iii) `protect_files.sh` étant **lui-même** dans son propre périmètre,
la correction est une **action humaine** — l'US a raison de ne pas la tenter ; (iv) le constat est
**nommé avec son destinataire** (US-00.8) dans ADR-001, le SCB **et** le Story File — **jamais tu**.

**⚠️ Recommandation opérationnelle, pour la PR nº 2 — la seule que je formule avec insistance** :
la **PR nº 2 va éditer le seul fichier normatif sans aucun filet, ni préventif ni détectif**. Son diff
n'est vérifié par **aucune machine** — ni hook, ni gate, ni `factory_sync.py`. **La relecture humaine du
diff, ligne par ligne, EST le seul contrôle existant.** Et `required_approving_review_count: 0` (§5)
signifie qu'aucune barrière n'exige même cette relecture. Corollaire à écrire dans le rapport de la
PR nº 2 : rien n'empêchera techniquement cet amendement d'en modifier **plus** que l'Art. 4 —
seul le contrôle de sortie **AC-4 / critère de test 12** le détectera, et **il devra être exécuté**.

---

#### **NB-2** · 🟠 **LOW-MEDIUM** · Affirmation de sécurité **positive et non bornée** dans un ADR **immuable**
`[Revue manuelle + vérification outillée]` | `docs/adr/ADR-001-choix-de-stack.md` — §*Conséquences ·
Positives*, phrase « *L'absence de backend supprime une surface entière de risques : ni API publique, ni
authentification, ni transport de données* » | **LOW-MEDIUM** | **NON BLOQUANT — recommandation à
FENÊTRE FERMANTE**

**L'affirmation est VRAIE aujourd'hui**, et je l'ai vérifiée par l'outil plutôt que de l'accepter :
`lib/` = **1 fichier**, **0** dépendance réseau (`http`, `dio`, `socket`, `websocket`), **0** dépendance
de persistance (`shared_preferences`, `sqflite`, `hive`, `path_provider`), **0** import `dart:io`
(§2.5). ✅ **Ce n'est donc pas une fausse assurance.**

**Le finding porte sur son ASYMÉTRIE TEMPORELLE**, et il est structurel :

* les **quatre affirmations négatives** (les « honnêtetés dures ») sont **explicitement datées** — le §
  *Portée exacte* écrit « *les limitations listées sont celles **connues au 2026-07-30*** » ;
* l'affirmation **positive** de sécurité, elle, est au **présent atemporel** : « *supprime* une surface
  entière de risques ». **Aucune borne de date ne la couvre** — le §*Portée exacte* ne borne que les
  *limitations*.
* Or ADR-001 est **immuable** par sa propre règle, et l'ADR le rappelle : « *toute évolution passera par
  un **nouvel ADR** — ⛔ jamais par une édition de ce fichier* ».

⚠️ **Conséquence concrète** : le jour où **US-01.2** ajoute la persistance — elle est **déjà planifiée**
(`ADR-005` la prépare, le PRD RF-21 l'exige) — ou le jour où une dépendance tierce entre au `pubspec`,
cette phrase deviendra une **fausse assurance de sécurité gelée dans un document immuable**, et il
faudra **un nouvel ADR** pour la démentir. C'est **exactement le mécanisme** qui a produit la fausse
assurance de l'Art. 4 (§4.2) : un énoncé exact à sa date, jamais rattrapé par le réel.

⚠️ **Nuance supplémentaire, vérifiée** : la plateforme **Web est matérialisée** (`ls -d web` → présent)
alors que la décision énonce « *offline-first, **aucune donnée ne quitte l'appareil*** ». Sur Web,
« l'appareil » est un **navigateur servi depuis une origine distante**, dont le stockage est exposé à
cette origine et au modèle de sécurité du Web. La contradiction n'est **pas actuelle** (0 code de
stockage, 0 code réseau) — mais la conjonction « *offline-first, rien ne quitte l'appareil* » +
« *Web matérialisé* » mérite un mot dans un document immuable.

**🕐 FENÊTRE** — c'est le seul point de ce rapport qui **expire** : ADR-001 **n'est pas encore fusionné**
(PR #17 ouverte). La règle d'immuabilité mordra **à la fusion**. **Ajouter une borne temporelle à cette
phrase est possible MAINTENANT, à coût nul** ; après la fusion, il faudra **un ADR entier**.
**Formulation suggérée, minimale, sans élargir le périmètre** : « *À la date de cet ADR (2026-07-30) et
en l'état du code livré — `lib/` ne contient aucun appel réseau ni aucune persistance, vérifié — cette
architecture supprime … . Cette propriété est **datée** : l'introduction d'une persistance (US-01.2) ou
d'une dépendance tierce la rouvrirait, et exigerait un nouvel ADR.* »
⛔ **Je ne le rends pas bloquant** : l'affirmation est **vraie**, donc aucun lecteur n'est trompé
aujourd'hui — et un audit ne bloque pas sur un risque **futur**. Mais je le signale **maintenant**
parce que **c'est le dernier moment où il coûte une phrase**.

---

#### **NB-3** · 🟡 **LOW** · Actions tierces non épinglées *(pré-existant, hors diff)*
`[grep outillé]` | `.github/workflows/ci.yml` et `e2e.yml` — directives `uses:` | **LOW** |
**HORS PÉRIMÈTRE — déjà ouvert depuis US-00.7, rappelé pour non-régression**

```
$ grep -rnE "uses: " .github/workflows/ | grep -vE "@[0-9a-f]{40}"
ci.yml:60   actions/checkout@v4          ci.yml:63   gitleaks/gitleaks-action@v2
ci.yml:71   actions/checkout@v4          ci.yml:101  actions/setup-python@v5
ci.yml:117  actions/checkout@v4          ci.yml:118  subosito/flutter-action@v2
e2e.yml:19  actions/checkout@v4          e2e.yml:20  subosito/flutter-action@v2
```

**8 actions sur tags MUTABLES**, dont `gitleaks/gitleaks-action@v2` qui reçoit
`pull-requests: write`. Un tag repointé exécuterait du code arbitraire dans un job **requis**.
✅ **Contrepoint établi** : `actionlint` **est** correctement épinglé (**SHA256 vérifié par
`sha256sum -c -`**), et ADR-001 le décrit exactement ainsi. ⚠️ **Toujours ouvert** : le
`pip install jsonschema` **nu** (finding N-2 d'US-00.7).
⛔ **Sans lien avec cette US** : `.github/workflows/*` est **absent du diff** (§2.4). Aucune
dégradation. Reste dû à **US-00.8**.

---

#### **NB-4** · 🟠 **MEDIUM** · La fausse assurance de l'Art. 4 est **toujours en vigueur sur `main`**
`[git log + run_gates + factory.config.json]` | `docs/governance/CONSTITUTION.md` — Art. 4, énumération
« *lint, typecheck, SAST, audit de dépendances, tests* » | **MEDIUM** | **PRÉ-EXISTANT — non introduit
par cette US, correctif PROGRAMMÉ en PR nº 2, NON ACQUIS**

Détail complet en **§4**. Résumé du finding, avec sa mesure : le texte normatif annonce un **SAST
bloquant** qui **n'existe pas**, **depuis le 2026-07-24 — 6 jours, toute la vie du projet** ; l'absence
du gate était **consignée dans un rapport de sécurité depuis le 2026-07-26** ; **aucun des 5 audits de
sécurité** qui l'ont constatée n'a vérifié le texte normatif ; **5 US ont été certifiées** dans cet état,
dont US-00.7 dont l'objet même était la cohérence du corpus.

**Pourquoi non bloquant contre US-00.5, et non-négociable sur ce point** : (i) le défaut **pré-existe** ;
(ii) US-00.5 est la **première** à le détecter **par exécution**, à en publier la sortie brute et à le
programmer en correction ; (iii) le bloquer contre elle **pénaliserait la détection au lieu du défaut**.
⛔ **Mais je borne mon PASS sans ambiguïté** : `CONSTITUTION.md` est **absent du diff**, donc **au moment
où j'écris, la fausse assurance de sécurité DEMEURE sur `main`**. Ce PASS certifie **qu'ADR-001 dit
vrai** — **pas** que le corpus normatif est exact. **Le finding NE SERA CLOS qu'à la fusion de la
PR nº 2**, et un audit de sécurité de cette PR nº 2 **devra le rouvrir et le vérifier**.

---

#### **NB-5** · 🟡 **LOW** · Champ `emitter` non enforcé — `EVT_CODE_READY` émis sous un autre rôle
`[Lecture de la trace]` | `docs/trace/US-00.5/events.jsonl` — `EVT_CODE_READY`, `agent: "architect"` |
**LOW** | **ACCEPTÉ — écart DÉCLARÉ, dette pré-existante du système de traçabilité**

`events_catalog.json` déclare `emitter: "developer"` pour `EVT_CODE_READY` ; l'événement est émis avec
`--agent architect`. **C'est justifié et déclaré** : décision C-5, **aucun @Developer n'intervient**
(0 fichier de code) — l'émettre en `developer` aurait été **factuellement faux**. L'écart est écrit dans
le `rationale` **et** dans `PROJECT_LOG.md`.
⚠️ **Le finding n'est pas l'écart, c'est ce qu'il révèle une fois de plus** : le champ `emitter`
**n'est lu par AUCUN script ni hook** → n'importe quel rôle peut émettre n'importe quel événement,
**`EVT_WAIVER_GRANTED`** compris, dont le catalogue déclare `emitter: "human"`. **Même classe de défaut
que NB-1** : ce qui manque est la **détection**, pas la prévention — et sur un dépôt à identité unique,
la prévention est **inatteignable**. Dette **pré-existante**, versée à `/audit-methodo` / US-00.8.
✅ `python scripts/validate_trace.py --us US-00.5` → **exit 0, « Traçabilité conforme »**.

---

### 6.3 ⚖️ Préoccupation ÉVALUÉE puis ÉCARTÉE — divulgation de faiblesses sur un dépôt public

Je la consigne au lieu de l'ignorer, parce qu'un auditeur à contexte frais la poserait
légitimement. **Ce diff publie, sur un dépôt PUBLIC** : « *aucun SAST n'existe* », « *aucun scan de CVE
n'existe* », « *le texte suprême est éditable par un agent en autonomie* », « *aucune détection de
dérive n'existe* », « *`required_approving_review_count` = 0* ».

**Écartée**, pour trois raisons vérifiées :
1. **Aucune information n'est ajoutée à un attaquant** : `factory.config.json`, `protect_files.sh`,
   `.github/workflows/*` et l'API de protection de branche sont **déjà publics et lisibles**. Les
   faiblesses sont **déductibles en trois commandes** par quiconque clone le dépôt.
2. **Aucun modèle de menace ne s'applique** : `collaborators` = **`gitgdx` seul**, **aucun tiers n'a de
   droit d'écriture**, **aucune application n'est déployée**, **aucune donnée** n'est traitée. Il n'y a
   **rien à attaquer** — et une PR de tiers reste soumise aux **4 contextes requis**.
3. **Le bénéfice est structurellement supérieur au risque** : l'exemple de l'Art. 4 (§4.2) démontre que
   **c'est le silence, et non la publication, qui a produit 4 jours de fausse assurance**.
   ⛔ Taire ces constats serait **précisément** le défaut que cette US corrige.

---

## 7. Verdict

# ✅ PASS — `EVT_SECURITY_AUDIT_PASSED`

**0 finding bloquant · 5 findings non bloquants (NB-1 · NB-2 · NB-3 · NB-4 · NB-5, dont 4 pré-existants
et hors diff).**

**Ce que ce PASS atteste, exactement** :
* les **quatre affirmations de sécurité** d'ADR-001 sont **vérifiées EXACTES par exécution** — ni trop
  pessimistes, ni trop rassurantes (§3) ;
* **aucun secret** n'entre dans le dépôt public : `gitleaks` 8.30.1, **3 passes** dont l'historique de la
  branche, **`no leaks found`** ×4 (§2.3) ;
* **aucun fichier d'enforcement** n'est touché, `CONSTITUTION.md` inclus (§2.4) ;
* la **protection de `main`** est **en vigueur ce jour**, `enforce_admins: true`, 4 contextes requis (§5) ;
* le diff **n'introduit aucune surface applicative** et **aucune dépendance** (§2.5) ;
* **aucune régression documentaire** : aucun énoncé devenu vrai n'a été « corrigé » (§4.4).

**Ce que ce PASS n'atteste PAS — et ne peut pas attester** :
* ⛔ **rien qui repose sur un scan de vulnérabilité** : **il n'en existe aucun dans cette factory** ;
* ⛔ **rien qui repose sur un SAST applicatif** : **il n'en existe aucun** ;
* ⛔ **l'exactitude du corpus normatif** : la fausse assurance de sécurité de l'**Art. 4 demeure sur
  `main`** (NB-4) — son correctif est **programmé en PR nº 2**, pas acquis ;
* ⛔ **la persistance** de la protection de `main` au-delà d'aujourd'hui : le contrôle est **manuel** ;
* ⛔ **la provenance** de quoi que ce soit : **aucune preuve machine n'existe** sur ce dépôt.

⚠️ **Deux points de sortie à ne pas perdre** :
1. **NB-2 a une fenêtre qui se ferme à la fusion** de la PR nº 1 (immuabilité de l'ADR) — une phrase
   maintenant, un ADR entier après.
2. **La PR nº 2 éditera le seul fichier normatif sans aucun contrôle machine.** Sa relecture humaine
   **est** le contrôle. Un audit de sécurité de la PR nº 2 est **dû**, et devra **rouvrir NB-4**.

---
*@CyberSecurity — contexte frais · claude-opus-5[1m] · 2026-07-30*
*Outils : `run_gates.py` (sast, deps_audit) · `gitleaks 8.30.1` (×4) · `gh api` (lecture seule) ·
`git log`/`git diff` · `validate_trace.py` · lecture intégrale de `protect_files.sh` et
`block_dangerous_bash.sh`*
