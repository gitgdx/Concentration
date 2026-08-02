# Audit sécurité — US-01.1 « Affichage Hub & grille d'échéances »

| Champ | Valeur |
|---|---|
| **US** | US-01.1 (EPIC_01, track FULL) |
| **Auditeur** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **Branche auditée** | `feat/US-01.1-dev-presentation` — `24fe59a1120d65960398b3455bcdb847ff57c590` |
| **Base** | `main` — `e8b7126650639bb79134c90cbf3fd206dd4d3c74` |
| **Périmètre** | `git diff main...HEAD` — **50 fichiers, +3913 / −119** |
| **Outils** | Python 3.14.6 · Flutter 3.44.7 · gitleaks 8.30.1 · actionlint 1.7.12 · gh 2.96.0 |

---

## ⛔ VERDICT : **PASSED** — aucun finding bloquant

**Aucun** des cinq critères bloquants de mon rôle n'est atteint :

| Critère bloquant | Constat | Preuve |
|---|---|---|
| Finding SAST de sévérité HIGH | **Aucun** — ⚠️ **mais aucun SAST n'existe** (voir Bornes) | `run_gates --gate sast` → exit 1 |
| CVE HIGH/CRITICAL sur dépendance **directe** | **Aucune connue** — ⚠️ **aucun scanner de CVE n'existe** ; justification obligatoire au §Bornes | `deps_audit` → exit 0, **0 dépendance ajoutée** |
| IDOR | **Sans objet** — aucune ressource, aucun identifiant d'utilisateur, aucun contrôle d'appartenance à exercer | Aucun endpoint : `dart:io` absent de `lib/` |
| Secret en dur | **Aucun** | `gitleaks` → `no leaks found` + grep ciblé |
| Endpoint sans contrôle d'authz | **Sans objet** — **aucun endpoint** | aucun `HttpClient`/`Socket`/`http(s)://` dans `lib/` |

> ⚠️ **Ce verdict est un verdict de REVUE ET D'EXÉCUTION D'OUTILS DE GOUVERNANCE, pas un verdict
> outillé de sécurité applicative.** Deux instruments manquent à la factory (§Bornes). Ce que
> j'atteste est **borné en conséquence** et doit être lu avec ces bornes, jamais sans elles.

---

## 0. Bornes assumées — ce que cet audit NE peut PAS attester

Ces bornes ne sont pas des réserves de style : elles **retirent** deux des cinq instruments que la
procédure de mon rôle prescrit. Les taire produirait exactement le faux vert que ce projet a payé
six fois (`reports/US-00.5/tension_structurelle.md`).

### B-1 — Il n'existe AUCUN SAST dans la factory

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

⇒ **Aucune analyse statique de sécurité n'a tourné sur les ~1 200 lignes de Dart neuves**, ni sur
les 253 lignes de Python. Ma couverture de ce code est une **revue humaine**, qui ne fournit
**aucune garantie d'exhaustivité**. Dette déjà inscrite au CLAUDE.md → candidate US-00.8.

### B-2 — Il n'existe AUCUN scanner de CVE

Le gate `deps_audit` exécute `dart pub outdated`, qui mesure l'**obsolescence**, **jamais la
vulnérabilité**. Un paquet à jour et vulnérable serait **vert**.

**Justification documentée du PASS malgré B-2** *(mon rôle interdit un PASS non justifié)* :

1. **Zéro dépendance ajoutée par cette US** — vérifié par diff vide, ci-dessous. La surface de
   dépendances est **rigoureusement celle que `main` porte déjà**, elle-même auditée aux US
   antérieures. Cette US n'introduit donc **aucun risque de chaîne d'approvisionnement nouveau**.
2. Les dépendances **directes** sont au nombre de trois hors SDK — `cupertino_icons 1.0.9`,
   `flutter_lints 6.0.0`, plus les SDK `flutter`/`flutter_test` — **toutes à la dernière version
   publiée** (colonne `Latest`), donc sans correctif de sécurité en attente.
3. Les seuls paquets non à jour sont **transitifs** (`meta`, `vector_math`, `matcher`,
   `test_api`), tous **épinglés par la résolution du SDK Flutter** (`Resolvable` = `Current`) :
   ils ne sont pas modifiables sans changer de SDK, et deux d'entre eux sont **dev-only**.

⚠️ **Ce raisonnement borne le risque, il ne le mesure pas.** Il reste **vrai** qu'aucune base CVE
n'a été interrogée.

### B-3 — Ce que je n'ai pas exercé

Aucun test dynamique (DAST), aucun fuzzing, aucune revue du code **transitif** du SDK Flutter,
aucune vérification du comportement **runtime** d'un binaire déployé (l'application n'est pas
déployée). Les 13 scénarios Gherkin d'US-01.1 **sont** exécutés (contrairement aux US-00.x), mais
ce sont des tests **fonctionnels**, pas des tests de sécurité.

---

## 1. Sorties d'outils (brutes)

### 1.1 `run_gates --gate sast` → **exit 1, le gate n'existe pas**

Voir B-1 ci-dessus.

### 1.2 `run_gates --gate deps_audit` → **exit 0**

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

transitive dependencies:
characters                    1.4.1     1.4.1       1.4.1       1.4.1
collection                    1.19.1    1.19.1      1.19.1      1.19.1
material_color_utilities      0.13.0    0.13.0      0.13.0      0.13.0
meta                          *1.18.0   *1.18.0     *1.18.0     1.19.0
sky_engine                    (sdk)     (sdk)       (sdk)       (sdk)
vector_math                   *2.2.0    *2.2.0      *2.2.0      2.4.2

transitive dev_dependencies:
async 2.13.1 · boolean_selector 2.1.2 · clock 1.1.2 · fake_async 1.3.3 ·
leak_tracker 11.0.2 · leak_tracker_flutter_testing 3.0.10 · leak_tracker_testing 3.0.2 ·
lints 6.1.0 · matcher *0.12.19 · path 1.9.1 · source_span 1.10.2 · stack_trace 1.12.1 ·
stream_channel 2.1.4 · string_scanner 1.4.1 · term_glyph 1.2.2 · test_api *0.7.11 ·
vm_service 15.2.0
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
EXIT=0
```

### 1.3 Aucune dépendance ajoutée — **diff VIDE**

```
$ git diff main...HEAD -- pubspec.yaml pubspec.lock
$ (aucune ligne)
EXIT_DIFF=0
```

⇒ **`pubspec.yaml` et `pubspec.lock` sont rigoureusement inchangés.** Point d'attention de la
commande d'audit : **satisfait, par exécution**. C'est cohérent avec T12a (« zéro dépendance
ajoutée : `flutter_test` suffit ») et avec ADR-008 qui **écarte** le paquet `integration_test`.

### 1.4 `gitleaks detect --no-git` → **exit 0, no leaks found**

```
$ gitleaks.exe version
8.30.1
$ gitleaks.exe detect --no-git --source . --config .gitleaks.toml --redact --verbose
7:57AM INF scanned ~154190546 bytes (154.19 MB) in 3.62s
7:57AM INF no leaks found
EXIT=0
```

### 1.5 `actionlint` (v1.7.12) → **exit 0, aucun diagnostic**

```
$ actionlint.exe --version
1.7.12
$ actionlint.exe -color
$ ACTIONLINT_EXIT=0
```

**Contrôle de chaîne d'approvisionnement, en bonus** : j'ai re-téléchargé l'artefact que la CI
épingle et **revérifié son SHA256 contre la valeur inscrite dans `ci.yml`** :

```
$ curl -fsSL -o al_linux.tar.gz ".../actionlint_1.7.12_linux_amd64.tar.gz"
$ echo "8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8  al_linux.tar.gz" | sha256sum -c -
al_linux.tar.gz: OK
PIN_CHECK_EXIT=0
```

⇒ **L'épinglage par SHA256 d'`actionlint` est valide et non périmé.**

### 1.6 `run_gates --all` → **exit 0 (5 gates)**

```
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
Tous les gates bloquants passent (5 exécutés).
GATES_EXIT=0
```

Détail du gate `test` (cliquet de couverture) :

```
$ python scripts/run_gates.py --gate test
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
Couverture de lignes : 94.1% (364/387) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigné le 2026-07-31 à US-00.6
  [HAUSSE] 94.06% (364/387) > cliquet 89.4%. Valeur a consigner (arrondie VERS LE BAS) : 94.0
✅ app.test
```

### 1.7 Job REQUIS « 📋 Governance » rejoué localement → **4/4 exit 0**

```
$ python scripts/check_scb_compliance.py       → SCB conforme — Aucune violation détectée.   (0)
$ python scripts/validate_trace.py --all       → Traçabilité conforme.                       (0)
$ python scripts/factory_sync.py --check       → Synchro factory conforme (DOCUMENTAIRE)     (0)
$ python scripts/selftest_coverage_ratchet.py  → les 9 assertions sont tenues, dont 5 REFUS  (0)
```

---

## 2. Les deux nouveaux steps CI — analyse dédiée

### 2.1 Aucun libellé de job n'a bougé — **vérifié par comparaison, pas par lecture**

Le risque nommé par la commande d'audit (un `name:` divergent périmerait un contexte requis et
**rendrait toute PR infusionnable, ou pire, la fusionnerait sans contrôle**) est **écarté par
mesure** : j'ai comparé les lignes de clés de job, de `name:` et de `permissions:` entre `main` et
`HEAD`.

```
$ diff <(git show main:.github/workflows/ci.yml | grep -nE '^  [a-z0-9_-]+:|^    name:|permissions:') \
       <(grep -nE '^  [a-z0-9_-]+:|^    name:|permissions:' .github/workflows/ci.yml)
10,11c10,11
< 130:  app-quality:
< 131:    name: 📱 App (gates run_gates.py)
---
> 143:  app-quality:
> 144:    name: 📱 App (gates run_gates.py)
```

⇒ **Le SEUL écart est le NUMÉRO DE LIGNE** (130→143, 131→144), conséquence mécanique des 13 lignes
insérées plus haut. **Les libellés et les blocs `permissions:` sont identiques au caractère près.**

**Confirmation croisée par le serveur** — les 4 contextes réellement exigés par GitHub
correspondent aux libellés du fichier :

```
$ gh api repos/gitgdx/Concentration/branches/main/protection --jq '{contexts:...}'
{"contexts":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
             "check-branch-name","📱 App (gates run_gates.py)"],
 "del":false,"enforce_admins":true,"force":false,"pr_reviews":0,"strict":true}
```

Et `factory_sync.py --check` **contrôle les libellés de jobs des workflows** en propre (message de
sortie : « *libellés de jobs des workflows* ») : il rend **exit 0**. Ce point est donc couvert par
**trois instruments indépendants**.

### 2.2 Aucune permission n'a bougé, et le jeton par défaut est en lecture seule

Le seul bloc `permissions:` du fichier est celui, **préexistant**, du job `secrets-scan`
(`contents: read` + `pull-requests: write`, justifié en commentaire pour `gitleaks-action`). Le job
`governance` — celui qui reçoit les deux nouveaux steps — **n'a pas de bloc `permissions:`** et
hérite donc du défaut du dépôt, que j'ai lu :

```
$ gh api repos/gitgdx/Concentration/actions/permissions/workflow
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}
```

⇒ **Le nouveau code s'exécute avec un `GITHUB_TOKEN` en lecture seule et sans capacité
d'approbation de PR.** Voir tout de même **NB-4** (durcissement de défense en profondeur).

### 2.3 Aucune injection de script — `${{ }}` absent des blocs `run:`

Le vecteur classique des workflows (interpolation d'une donnée contrôlée par l'attaquant — titre de
PR, nom de branche — dans un `run:`) est **absent du fichier entier**, pas seulement des nouveaux
steps :

```
$ (balayage des blocs run: à la recherche de '${{')
  -> 0 interpolation(s) dans un run:
```

Et le déclencheur est **`pull_request`**, **jamais `pull_request_target`** :

```
$ grep -rn "pull_request_target" .github/workflows/
AUCUN pull_request_target (bon)
```

⇒ Le code d'une PR de fork s'exécute donc **sans** les secrets du dépôt et **sans** jeton
privilégié. C'est la configuration correcte.

---

## 3. `scripts/check_gherkin_mapping.py` (253 lignes, job REQUIS) — revue

C'est le seul code neuf qui **s'exécute sur l'infrastructure CI**. Il mérite donc l'examen le plus
serré du diff. **Surface d'attaque : nulle.**

### 3.1 Aucune primitive dangereuse — vérifié par balayage

```
$ grep -nE "^(import|from) |subprocess|os\.system|eval\(|exec\(|pickle|shell=True|input\(|urllib|requests|socket" \
       scripts/check_gherkin_mapping.py
41:from __future__ import annotations
43:import re
44:import sys
45:import tempfile
46:from pathlib import Path
```

⇒ **`subprocess`, `os.system`, `eval`, `exec`, `pickle`, `input`, `urllib`, `socket` : ZÉRO
occurrence.** Le point d'attention « `subprocess` » de la commande d'audit tombe : **il n'y en a
pas**. Quatre imports, tous stdlib, tous inoffensifs.

### 3.2 Chemins : aucun n'est dérivé d'une entrée

`sys.argv` n'est lu **qu'une fois** (`if '--selftest' in sys.argv[1:]`, l. 224) : c'est un test
d'**appartenance**, jamais une valeur utilisée. Les chemins viennent exclusivement de la constante
`COUPLES` (l. 51-56) et de `Path(__file__).resolve().parent.parent` (l. 227).

⇒ **Aucune traversée de répertoire possible** : il n'existe aucun chemin d'exécution où une donnée
externe atteigne un `Path`.

### 3.3 Écritures fichier : uniquement dans un répertoire temporaire sûr, jamais dans le dépôt

`_corpus_synthetique()` (seule fonction qui écrit) n'est appelée que depuis `selftest()`, dont la
racine est un `tempfile.TemporaryDirectory()` (l. 147) — nom **imprévisible**, **nettoyé** par le
gestionnaire de contexte. Pas de `/tmp/nom-fixe`, donc **pas de vulnérabilité de lien symbolique ni
de course TOCTOU**.

**Vérifié par exécution**, et non par lecture :

```
$ python scripts/check_gherkin_mapping.py
T12b -- correspondance scenario <-> test (racine : ...\Concentration)
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
OK : chaque scenario a son test et chaque test son scenario.
EXIT=0

$ python scripts/check_gherkin_mapping.py --selftest
  [OK] corpus conforme => 0 ecart
  [OK] mutant test retire => refus qui NOMME le scenario
  [OK] mutant test orphelin => refus DISTINCT du manquant
  [OK] mutant titre renomme => manquant ET orphelin
  [OK] un titre a apostrophe est lu correctement
  [OK] les deux motifs sont DISTINCTS
Autotest : 6 assertions, 0 echec(s), 1 couple(s) sous controle.
EXIT=0

$ git status --porcelain
$ (vide)
```

⇒ **Après les deux exécutions, l'arbre de travail est intact : aucune écriture dans le dépôt.**

### 3.4 Expressions régulières : pas de ReDoS

`MOTIF_TEST` (l. 66-69) contient `(?:[^'\\]|\\.)*`, la **forme sûre** du motif de chaîne échappée :
les deux branches de l'alternance sont **disjointes sur le premier caractère** (`[^'\\]` exclut la
barre oblique inverse, `\\.` l'exige), donc l'automate est **déterministe** et le retour arrière
**linéaire**. La forme dangereuse (`(?:.|\\.)*`, ambiguë, à explosion exponentielle) **n'est pas
utilisée**. Les entrées sont de toute façon des fichiers versionnés du dépôt, pas des données
distantes.

### 3.5 Lecture : robuste au contenu

`read_text(encoding='utf-8', errors='replace')` (l. 110-111, 233-234) : un fichier binaire ou mal
encodé produit des caractères de remplacement, **jamais une exception**. Sortie ASCII et
`sys.stdout.reconfigure` sous `try/except` (l. 249-252). Pas de faux vert d'encodage.

**Conclusion 3 : aucun finding, même informatif, sur ce script.** Il est, du point de vue sécurité,
exemplaire pour un script de CI : stdlib seule, aucune entrée, aucune écriture hors `tempfile`,
et il **porte son propre autotest de mutation** — ce que ce projet a établi comme le seul contrôle
qui ne ment pas (7/7 contre 0/7, `reports/US-00.5/tension_structurelle.md`).

---

## 4. Code Dart neuf — revue

### 4.1 Aucun réseau, aucune E/S disque, aucun processus — vérifié par l'ensemble des imports

```
$ grep -rhn "^import " lib/ | sed "s/.*import //" | sort -u
'dart:async'  ·  'dart:math' as math  ·  'dart:ui'  ·  'package:flutter/material.dart'
(+ 30 imports relatifs, tous internes au dépôt)
```

⇒ **`dart:io` est ABSENT.** Sans `dart:io`, il n'existe dans `lib/` **ni `File`, ni `Directory`, ni
`Socket`, ni `HttpClient`, ni `Process`**. Le balayage ciblé le confirme : les seules occurrences
du mot « token » sont les **design tokens** (`concentration_tokens.dart`), aucune occurrence de
`apiKey`, `secret`, `password`, `Bearer`, `AKIA`, `BEGIN … PRIVATE KEY`, ni d'URL `http(s)://`.

Les trois points d'attention Dart de la commande d'audit — **secret en dur / appel réseau /
écriture disque** — sont donc **écartés structurellement**, pas seulement par recherche de motifs :
les API nécessaires ne sont pas importées.

### 4.2 Contraintes d'architecture qui portent une valeur de sécurité

- **Données strictement statiques** : `SampleEcheances.depuis(clock)` construit une liste
  **en mémoire** à partir de constantes du dépôt. Aucune désérialisation, aucun `jsonDecode`,
  aucune source externe ⇒ **aucune donnée non fiable n'entre dans le système en US-01.1**.
- **Pas de `DateTime.now()` disséminé** : seul `SystemClock.now()` consulte l'horloge. Réduit la
  surface non déterministe.
- **`Timer.periodic` correctement libéré** : `_minuterie?.cancel()` dans `dispose()`
  (`echeances_grid.dart:47-51`) ⇒ **pas de fuite de ressource** ni de `setState` après démontage.
- **Pas de gestionnaire de geste sur les modules grisés** (ADR-004 : « non-interactif par
  **absence** de gestionnaire, jamais par `onTap: () {}` ») ⇒ **aucune action inatteignable
  réactivable par accident**.
- **XSS / injection : sans objet.** Pas de `WebView`, pas de rendu HTML, pas de base de données,
  pas de requête. Le seul texte d'origine « donnée » (`description`) est rendu par un `Text`
  Flutter, qui **ne fait aucune interprétation de balisage**.
- **CSRF / CORS / authz / hachage de mot de passe : sans objet.** Ni serveur, ni session, ni
  cookie, ni compte, ni identifiant. Les items correspondants de ma procédure sont **inapplicables
  à cette US**, et je le dis plutôt que de cocher un « conforme » vide de sens.

---

## 5. Tableau des findings

Format : `[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

### 5.1 Bloquants

**AUCUN.**

### 5.2 Non bloquants

| # | Outil | Fichier:Ligne | Sév. | Décision |
|---|---|---|---|---|
| **NB-1** | Revue + probe `dart run` | `lib/features/echeances/domain/echeance.dart:16` | **LOW** | **Accepté pour US-01.1, à traiter en US-01.2** |
| **NB-2** | Revue + probe `dart run` | `lib/features/echeances/domain/echeance.dart:27-39` ↔ `remaining_time_calculator.dart:99-115` | **LOW** | **Accepté (non atteignable aujourd'hui), à traiter en US-01.2** |
| **NB-3** | Revue | `lib/core/color/temporal_gradient.dart:48-55` | **INFO** | **Accepté — comportement voulu (ADR-003 §5)** |
| **NB-4** | Revue + `gh api` | `.github/workflows/ci.yml:67` (job `governance`) | **INFO** | **Accepté — atténué par le défaut du dépôt** |
| **NB-5** | `grep` sur `uses:` | `ci.yml:60,63,101,147` · `e2e.yml:19,20` | **LOW** | **Préexistant, reconduit — hors périmètre US-01.1** |

---

### NB-1 — L'invariant I-2 (`id` non vide) n'est **PAS** appliqué en configuration release

`Echeance` porte son invariant par un `assert` (l. 16). En Dart, **les `assert` sont retirés à la
compilation release** — précisément la configuration du gate `app.build`
(`flutter build web --release`). L'invariant **n'existe donc que dans les tests**.

**Mesuré, dans les deux sens**, par un programme sonde exécutant le code réel du dépôt :

```
=== asserts DESACTIVES (configuration release) ===
I-2 constructeur, id vide -> ACCEPTE (id=<>)
=== asserts ACTIVES (configuration debug/test) ===
I-2 constructeur, id vide -> REFUSE : Failed assertion: line 16 pos 15: 'id != ''': I-2 : id non vide
```

Confirmé indépendamment sur le **bundle release** effectivement produit, avec **contrôle positif**
*(sans lui, un `0` ne prouverait rien — leçon d'US-00.5)* :

```
$ grep -c "atteinte"     build/web/main.dart.js   → 1   (contrôle positif : le grep SAIT trouver)
$ grep -c "id non vide"  build/web/main.dart.js   → 0   (le message d'assertion est ABSENT)
```

**Pourquoi ce n'est PAS bloquant en US-01.1** : le seul producteur d'`Echeance` en production est
`sample_echeances.dart`, une liste de **constantes du dépôt** dont tous les `id` sont non vides. La
condition n'est **pas atteignable**.

**Pourquoi il faut le traiter en US-01.2** : cette US ouvre la persistance, donc des `Echeance`
construites depuis des **données stockées**. Un enregistrement à `id` vide ou dupliqué passerait
alors **silencieusement** en release. Conséquence identifiée — ⚠️ **raisonnée, NON mesurée** :
`echeances_grid.dart:92` utilise `key: ValueKey(e.id)`, et la détection de clés dupliquées de
Flutter est **elle-même assertionnelle**, donc également absente en release.

**Remède suggéré** *(hors périmètre, je ne modifie pas le code)* : remplacer l'`assert` par un
`throw ArgumentError` dans le constructeur, ou n'exposer que `depuisDonnee`, qui valide **vraiment**.

### NB-2 — Le validateur de frontière `depuisDonnee` **ne borne pas** `dateEcheance`

`depuisDonnee` (I-6, « une donnée invalide rend `null`, jamais fatale ») vérifie le **type** de
`dateEcheance`, **pas son domaine**. Une date extrême est donc **acceptée à la frontière**, puis
fait **lever une exception** en aval, dans `_ajouterMois` :

```
an=3000   -> n=974    TimeUnit.annees  p=0.583...  en 2 ms
an=100000 -> n=97974  TimeUnit.annees  p=0.583...  en 5 ms
an=275759 -> EXCEPTION apres 0 ms : Invalid argument(s): (275941, 9, 0, 0, 0, 0, 0, 0)
```

Deux enseignements **positifs** de cette mesure : les boucles `while` non bornées de `_plafond`
(l. 78-83) **terminent en quelques millisecondes** même à 97 974 itérations d'estimation ⇒ **pas de
déni de service par CPU** ; et l'échec est **immédiat**, pas un gel.

Mais la promesse « une donnée illisible est **ignorée**, jamais fatale » **ne tient pas** pour cette
classe de valeur : elle n'est pas ignorée, elle **traverse** la frontière et casse plus loin.

**Pourquoi ce n'est PAS bloquant** : `depuisDonnee` a **zéro appelant dans `lib/`** — vérifié, ses 7
seules occurrences hors définition sont dans `test/`. C'est du **code de frontière encore
inutilisé**, préparé pour US-01.2. Le chemin n'est **pas atteignable en production aujourd'hui**.

**Remède suggéré pour US-01.2** : borner `dateEcheance` dans `depuisDonnee` (l'intervalle
raisonnable du produit, très en deçà des limites de `DateTime`), et couvrir le cas par un test.

### NB-3 — `foregroundFor` lève une `StateError` depuis l'arbre de widgets

`temporal_gradient.dart:48-55` lève si aucun candidat n'atteint le contraste requis, et l'appel a
lieu dans `echeance_tile.dart` — donc **pendant `build()`**. Une exception y **casse le rendu de
l'écran**, ce qui heurte l'AC-1 « Erreur » (« le hub reste affiché sans planter »).

**Décision : accepté.** C'est une **décision d'architecture explicite et tracée** (ADR-003 §5 :
« échoue bruyamment … un dégradé illisible est un défaut de tokens »). Le déclenchement dépend
**exclusivement de constantes de compilation** (`ConcentrationTokens`) et d'un `p` **borné par
`clamp(0,1)`** ; **aucune donnée d'utilisateur n'entre dans cette condition**. Le contraste est
mesuré par test sur **101 points** de `p`. Le risque est donc un **risque de régression de tokens
au moment du développement**, pas un risque d'exécution — et c'est exactement ce que l'ADR veut
rendre visible.

⚠️ **À réévaluer si un jour les tokens deviennent configurables** (thème utilisateur) : la même
ligne deviendrait alors un plantage pilotable par une donnée.

### NB-4 — Le job `governance` n'a pas de bloc `permissions:` explicite

Il hérite du défaut du dépôt, aujourd'hui `read` (mesuré au §2.2). **Aucune exposition actuelle.**
Mais le défaut est un **réglage de dépôt modifiable hors du dépôt** : un basculement en
`read-write` élargirait **silencieusement** le jeton de tous les steps de ce job, dont les deux
nouveaux. C'est la **même classe de dette** que « aucune détection automatique de dérive »
(CLAUDE.md). Durcissement d'un coût nul : ajouter `permissions: {contents: read}` au job.
⚠️ **Préexistant** : le diff ne l'introduit pas, il en **augmente la portée** de deux steps.

### NB-5 — Actions tierces épinglées par **tag mutable**

`actions/checkout@v4`, `gitleaks/gitleaks-action@v2`, `actions/setup-python@v5`,
`subosito/flutter-action@v2` : un tag peut être **redirigé** par le mainteneur ou un attaquant ayant
compromis son compte. `gitleaks-action@v2` est le plus sensible — il s'exécute avec
`pull-requests: write`. **Finding déjà ouvert depuis l'audit d'US-00.7**, reconduit ici **sans
aggravation** : le diff n'ajoute **aucune** action. À épingler par SHA de commit, comme le fait
déjà — et bien — le step `actionlint` (§1.5). **Hors périmètre d'US-01.1**, à verser à US-00.8.

---

## 6. État de `main` — inchangé (contrôle en lecture seule)

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{protected:.protected}'
{"protected":true}

$ python scripts/factory_sync.py --check-remote
Comparaison champ par champ — gitgdx/Concentration:main · 12 champ(s) alignés, 0 écart(s),
7 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
  [OK] required_status_checks.strict                                   | true  | true
  [OK] required_status_checks.contexts (les 4)                         | =     | =
  [OK] required_pull_request_reviews.required_approving_review_count   | 0     | 0
  [OK] enforce_admins                                                  | true  | true
  [OK] allow_force_pushes                                              | false | false
  [OK] allow_deletions                                                 | false | false
  [OK] required_linear_history                                         | false | false
  [OK] required_conversation_resolution                                | true  | true
  [OK] restrictions                                                    | null  | absente
Protection de gitgdx/Concentration:main — conforme à la cible générée.
REMOTE_EXIT=0
```

⇒ **Protection de branche intacte, 0 écart.** Aucune opération d'écriture n'a été effectuée sur
GitHub durant cet audit : **seuls des `gh api` en lecture** (`GET`) ont été émis.

**Fichiers d'enforcement et de configuration — non touchés par le diff** :

```
$ git diff main...HEAD --name-only | grep -E "factory.config.json|\.gitleaks|protect_files|githooks|\.env|analysis_options"
  AUCUN (config, gitleaks, hooks, .env, lints : intacts)
```

⇒ **Aucun seuil de qualité abaissé, aucune règle `gitleaks` désactivée, aucun hook affaibli,
aucun fichier `.env` touché.** Le cliquet de couverture n'a pas été déplacé (il **monte** : 94,1 %
mesuré contre 89,4 % requis).

---

## 7. Synthèse

Ce diff est, du point de vue sécurité, **d'un profil de risque bas et bien maîtrisé** :

- **Aucune dépendance ajoutée** — la surface d'approvisionnement est inchangée ;
- **Aucune capacité dangereuse importée** dans le Dart (`dart:io` absent) : ni réseau, ni disque,
  ni processus, donc aucun endpoint, aucune authz à contrôler, aucun IDOR possible ;
- **Aucun secret** (gitleaks, 154 Mo scannés) ;
- Le seul code exécuté en CI est **stdlib pure, sans entrée, sans `subprocess`, sans écriture hors
  `tempfile`** — et **porte son autotest de mutation** ;
- Les **contextes requis** et la **protection de `main`** sont **prouvés inchangés** par trois
  instruments indépendants.

Les cinq findings non bloquants sont soit **préexistants** (NB-4, NB-5), soit **des dettes de
robustesse dont le chemin d'atteinte n'existe pas encore** (NB-1, NB-2 — ils s'ouvriront avec la
persistance d'US-01.2), soit **une décision d'architecture tracée et assumée** (NB-3).

⚠️ **Et il reste vrai que ce verdict ne s'appuie sur AUCUN SAST et AUCUN scan de CVE** — les deux
instruments manquent à la factory. Ce que j'atteste est une **revue humaine outillée par des
contrôles de gouvernance**, pas une analyse de sécurité automatisée. **NB-1 et NB-2 ont d'ailleurs
été trouvés à la main, puis prouvés par exécution : ils illustrent exactement ce qu'un SAST
aurait pu signaler seul** — argument concret pour la dette US-00.8.

---

## 8. Recommandations (aucune n'est bloquante)

| # | Recommandation | Porteur suggéré |
|---|---|---|
| R-1 | Remplacer l'`assert` d'`Echeance` par une validation active, **avant** d'ouvrir la persistance | **US-01.2** (NB-1) |
| R-2 | Borner `dateEcheance` dans `depuisDonnee` + test de la borne | **US-01.2** (NB-2) |
| R-3 | Ajouter `permissions: {contents: read}` au job `governance` | US-00.8 (NB-4) |
| R-4 | Épingler les actions tierces par SHA de commit, comme `actionlint` | US-00.8 (NB-5) |
| R-5 | Doter la factory d'un SAST Dart et d'un scan de CVE — **cet audit en démontre le besoin par l'exemple** | US-00.8 |

---

*Rapport produit en contexte frais par @CyberSecurity (`claude-opus-5[1m]`). Toutes les sorties
d'outils ci-dessus ont été réellement exécutées le 2026-08-02 sur le commit `24fe59a`. Aucune
modification du code, du SCB ou de l'état GitHub n'a été effectuée.*
