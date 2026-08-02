# Audit sécurité — US-01.1 · **DELTA 2** `6fe75df` → **`173fb62`**

| Champ | Valeur |
|---|---|
| **US** | US-01.1 (EPIC_01, track FULL) |
| **Auditeur** | @CyberSecurity — contexte frais (Constitution Art. 2), **3ᵉ passage** |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **SHA AUDITÉ** | **`173fb62348c5ca516505067c1ea29c97fa06b8a8`** (`173fb62`) |
| **Branche** | `feat/US-01.1-dev-presentation` — arbre propre au début de l'audit |
| **Visa précédent** | `6fe75df` ([`security_delta.md`](security_delta.md)) — **PÉRIMÉ**, remplacé par celui-ci |
| **1ᵉʳ visa** | `24fe59a` ([`security.md`](security.md)) — périmé depuis le 2ᵉ passage |
| **Outils** | Python 3.14.6 · Flutter (gates `run_gates.py`) · gitleaks 8.30.1 · gh 2.96.0 |

> ## 📌 SUR QUOI CE VISA PORTE
> **Ce visa porte sur le commit `173fb62` ET SUR LUI SEUL.** Il ne porte ni sur une intention, ni
> sur « le contenu d'US-01.1 », ni sur les fichiers **non suivis** présents dans l'arbre (§8).
> **Tout commit ultérieur touchant `lib/`, `test/`, `.github/`, `pubspec*`, `scripts/` ou un fichier
> d'enforcement PÉRIME ce visa** — et, comme l'établit **NB-6**, ⛔ **aucun mécanisme de la factory
> ne le signalera**. C'est un fait mesuré, pas une clause de style : c'est exactement ce qui s'est
> produit deux fois sur cette US.

---

## 1. ⛔ VERDICT : **PASSED** sur `173fb62` — aucun finding bloquant

| Critère bloquant de mon rôle | Constat sur `173fb62` | Preuve |
|---|---|---|
| Finding SAST de sévérité HIGH | **Aucun** — ⚠️ **mais aucun SAST n'existe** (§7) | `run_gates --gate sast` → **exit 1** |
| CVE HIGH/CRITICAL sur dépendance **directe** | **Aucune connue** — ⚠️ **aucun scanner de CVE n'existe** ; justification exigée par mon rôle au §7 | `deps_audit` → exit 0 · **`pubspec.lock` bit-à-bit identique** |
| IDOR | **Sans objet** — aucune ressource, aucun identifiant d'utilisateur, aucune appartenance | `dart:io` absent de `lib/` ; `lib/` **inchangé** |
| Secret en dur | **Aucun** | `gitleaks` → `no leaks found`, exit 0 |
| Endpoint sans contrôle d'authz | **Sans objet** — **aucun endpoint** | aucun `HttpClient`/`Socket`/`http(s)://` |

**Findings nouveaux : 2, tous deux non bloquants** (NB-7 INFO de méthode, NB-8 LOW) — §6.
**NB-1 à NB-6 : tous INCHANGÉS**, aucun aggravé, aucun résolu — §5.

---

## 2. Le périmètre réel — ⚠️ **la saisine annonçait 3 commits, la plage en contient 4**

Premier écart mesuré, et il agrandit mon périmètre :

```
$ git rev-list --oneline 6fe75df..173fb62
173fb62 docs(us-01.1): les 2 visas d audit sont PERIMES — colonnes remises a l attente
ddf839e chore(us-01.1): EVT_CODE_READY sur ade583e — les 6 mutants sont tues
ade583e test(us-01.1): les 6 mutants de la QA sont TUES, sans toucher une ligne de lib/
be9cc4a test(us-01.1): la QA REFUSE alors que TOUS LES GATES sont verts
$ git rev-list --count 6fe75df..173fb62
4
```

La saisine nommait `ade583e`, `ddf839e`, `173fb62`. **`be9cc4a` n'y figurait pas** — or c'est le
**plus gros commit de la plage** et **le seul qui apporte du code exécutable** :

```
$ git show --stat --oneline be9cc4a
 CLAUDE.md                            |  11 +
 PROJECT_LOG.md                       |   3 +
 STORY_CERTIFICATION_BOARD.md         | 103 ++++++-
 docs/trace/US-01.1/events.jsonl      |   3 +
 reports/US-01.1/code_review_delta.md | 262 ++++++++++++++++++
 reports/US-01.1/qa.md                | 515 +++++++++++++++++++++++++++++++++++
 reports/US-01.1/qa_exit_criterion.py | 314 +++++++++++++++++++++
 reports/US-01.1/security_delta.md    | 301 ++++++++++++++++++++
 8 files changed, 1511 insertions(+), 1 deletion(-)
```

⚠️ **Ce n'est pas une faille, et je ne la gonfle pas** : `be9cc4a` est dans la plage
`6fe75df..173fb62`, donc **il était dans mon périmètre quoi qu'il arrive**, et je l'ai audité (§4).
Mais c'est **exactement la classe de défaut la plus active du projet** — *« une assertion chiffrée
écrite à la main à côté d'une commande, jamais relue dans sa sortie »*. **Je l'ai relue dans sa
sortie.** Sans cela, un auditeur qui aurait fait confiance à l'énumération aurait manqué
`qa_exit_criterion.py` — que la saisine rattachait par ailleurs, à raison, au *« commit précédent »*.

### Contenu du delta

```
$ git diff 6fe75df..173fb62 --stat
 CLAUDE.md                                          |  11 +
 PROJECT_LOG.md                                     |   5 +
 STORY_CERTIFICATION_BOARD.md                       | 146 +++++-
 docs/trace/US-01.1/events.jsonl                    |   4 +
 reports/US-01.1/code_review_delta.md               | 262 +++++++++++
 reports/US-01.1/qa.md                              | 515 +++++++++++++++++++++
 reports/US-01.1/qa_exit_criterion.py               | 314 +++++++++++++++
 reports/US-01.1/security_delta.md                  | 301 ++++++++++++++
 test/core/theme/concentration_theme_test.dart      |  52 +++
 test/e2e/hub_echeances_test.dart                   | 138 ++++--
 .../presentation/echeances_grid_test.dart          |  39 +-
 .../presentation/widgets/echeance_tile_test.dart   | 170 +++++++
 test/features/hub/presentation/hub_page_test.dart  |  99 ++++
 test/support/rendu_couleur.dart                    |  65 +++
 14 files changed, 2083 insertions(+), 38 deletions(-)
```

---

## 3. Les 3 affirmations de la saisine — **mesurées, pas crues**

Je ne les ai pas vérifiées par `git diff` seul : un diff vide se lit, un **hachage d'arbre** se
compare. Le hachage d'objet Git d'un sous-arbre est une **égalité bit-à-bit récursive**.

```
$ git merge-base --is-ancestor 6fe75df 173fb62
6fe75df EST ancetre de 173fb62 -> le diff 2-points est complet
```

*(contrôle préalable indispensable : sur des commits non liés, un diff 2-points peut masquer.)*

```
=== ARBRES (hash d objet = egalite bit-a-bit du sous-arbre) ===
IDENTIQUE  lib              d95a69c2cabe0da179f7680ebd18ea4692b20162
IDENTIQUE  .github          2bafb845d3779f5d1c9974097e207b2a7372d446
IDENTIQUE  scripts          c7339d6055664db6b81398a6832377b08eecc436
DIFFERENT  test/support     (absent) -> 2428b8377ad3341cd356a88967b0350357b2bbef
IDENTIQUE  docs/governance  5acd79b28f25502ca8ae80607d347369193f93f6
=== BLOBS ===
IDENTIQUE  pubspec.yaml           8fc83b8808693cecc3e25c04204697d8c753c1cd
IDENTIQUE  pubspec.lock           582d01a211d092ab6d314168610739adba859554
IDENTIQUE  factory.config.json    6aaa8b128ca0aec80d948e36e40c66b1b80bf22b
IDENTIQUE  .gitleaks.toml         55feb41d45044d507ca9d13c4db7a85f541b3dae
IDENTIQUE  analysis_options.yaml  0d2902135caece481a035652d88970c80e29cc7e
IDENTIQUE  .github/workflows/ci.yml  4993669bd84e1cf4999e30245a778d9e9911915a
```

| # | Affirmation de la saisine | Verdict | Portée réelle de la preuve |
|---|---|---|---|
| 1 | `lib/` est intact | ✅ **VRAI** | Arbre `lib` **bit-à-bit identique** — plus fort qu'un diff vide |
| 2 | Aucune dépendance ajoutée | ✅ **VRAI** | `pubspec.yaml` **et** `pubspec.lock` : blobs identiques |
| 3 | Aucun fichier d'enforcement touché | ✅ **VRAI** | `.github`, `scripts`, `factory.config.json`, `.gitleaks.toml`, `analysis_options.yaml` : identiques |

⚠️ **Vérifié aussi contre le « toucher-puis-annuler »** : aucun des 4 commits ne modifie `lib/`
(§2 — `ade583e` porte d'ailleurs cette contrainte dans son propre message). L'état net **et** le
chemin sont donc propres.

⇒ **Conséquence méthodologique importante** : `.github/workflows/ci.yml` étant **bit-à-bit
identique** à celui qu'a analysé [`security.md`](security.md) §2 (libellés de jobs, blocs
`permissions:`, absence d'interpolation `${{ }}` dans les `run:`, absence de
`pull_request_target`), **cette analyse reste valide sans être rejouée**. Je ne la reconduis pas
par confiance : je la reconduis parce que **le fichier n'a pas changé d'un octet**.

---

## 4. La question centrale : **un delta 100 % `test/` modifie-t-il l'artefact livré ?**

**⛔ C'est le piège que la saisine me demandait de ne pas prendre pour une évidence. Je ne l'ai pas
raisonné — je l'ai MESURÉ.**

### 4.1 Protocole (et pourquoi il est construit ainsi)

Comparer deux bundles construits dans deux répertoires différents ne prouverait rien : une
différence pourrait venir du **chemin de construction**, pas du code. J'ai donc construit les
**deux révisions dans le MÊME chemin absolu**, l'une après l'autre, le répertoire de travail
devenant une **constante** de l'expérience. Les révisions sont extraites par `git archive`
(**aucun `checkout`, aucun `worktree`** : le dépôt n'est pas touché).

**Contrôle positif obligatoire** — leçon d'US-00.5, *« un contrôle portant son mutant a été juste
7 fois sur 7 ; un contrôle purement lexical, faux 7 fois sur 7 »* : sans lui, une **égalité** de
hachages ne prouverait rien, elle pourrait signifier que la mesure est **aveugle**. Troisième
construction : `173fb62` + mutation d'**une seule constante** de `lib/`
(`Duration(seconds: 30)` → `Duration(seconds: 31)`).

### 4.2 Résultat brut

```
etiquette|revision|sha256(build/web/main.dart.js)|octets
AVANT |6fe75df|43921808223352ee0d0c2da6f3ea40483189d952217c17422b5278debbc1b972|2031554
APRES |173fb62|43921808223352ee0d0c2da6f3ea40483189d952217c17422b5278debbc1b972|2031554
MUTANT|173fb62|9817366c6f27f1dd0fa00ee594b6b48dcd3aa31eb5ea54bb926efca0f4e71215|2031555

  [1] delta 100% test/ : main.dart.js IDENTIQUE bit-a-bit (AVANT == APRES)
  [2] CONTROLE POSITIF OK : muter UNE constante de lib/ change le hash
```

### 4.3 Réponse

✅ **NON — ce delta ne modifie pas l'artefact livré, et je peux le mesurer.** Le bundle de release
`main.dart.js` est **bit-à-bit identique** avant et après, **et** la mesure est **prouvée capable
de détecter une différence** (un caractère de `lib/` suffit à faire bouger le hachage **et** la
taille). L'argument « c'est du test, donc c'est anodin » était **vrai ici**, mais il ne l'était
**pas par nature** : il l'est **par mesure**, et c'est la seule forme sous laquelle je l'accepte.

**Corroboration indépendante** — la couverture est restée **numériquement identique** :

```
sur 6fe75df : Couverture de lignes : 95.2% (380/399)
sur 173fb62 : Couverture de lignes : 95.2% (380/399)
```

Même **dénominateur** (399 lignes mesurables ⇒ `lib/` n'a pas bougé) et même **numérateur**
(380 ⇒ les 2 083 lignes de tests ajoutées **renforcent des assertions sur des lignes déjà
couvertes**, elles n'atteignent aucune ligne neuve). Deux instruments indépendants concordent.

### 4.4 ⚠️ Ce que cette mesure n'atteste PAS

Elle porte sur la **cible web** (`flutter build web --release`, la seule que le gate `app.build`
construise). Elle **ne dit rien** d'une cible Android/iOS, non construite par la factory. Et elle
atteste une **égalité d'artefact**, pas une **absence de risque** : un delta test-only pourrait
encore nuire en **affaiblissant les contrôles** — question traitée aux §5 (NB-7) et §6.

---

## 5. `reports/US-01.1/qa_exit_criterion.py` — audité **comme du code**

314 lignes de Python neuves qui **exécutent des mutations de code** et lancent `flutter test`.
C'est l'artefact le plus sensible du delta. Réponses aux questions posées, une par une.

### 5.1 Est-il exécuté par la CI ? — **NON, et c'est déterminant**

```
$ grep -rn "qa_exit_criterion" .github/ scripts/ factory.config.json .claude/
AUCUNE reference dans .github/, scripts/, factory.config.json, .claude/
$ grep -rn "reports/" .github/workflows/
ci.yml:11:#    (reports/US-00.7/applied_state/negative_test_server.txt).   <- COMMENTAIRE
ci.yml:16:#    reports/US-00.7/applied_state/merge_refusal_server_405.txt  <- COMMENTAIRE
```

⇒ **Aucun workflow, aucun hook, aucun gate ne l'invoque.** Il ne s'exécute **jamais** sur
l'infrastructure CI, donc **jamais avec un `GITHUB_TOKEN`**. Sa surface d'exposition est celle d'un
outil lancé **manuellement, en local, par quelqu'un qui a déjà les droits d'écriture sur le dépôt**.
Cela **borne fortement** tout ce qui suit.

### 5.2 `eval` / `exec` / réseau / `subprocess` ?

```
$ grep -nE "eval\(|exec\(|os\.system|pickle|marshal|__import__|compile\(|urllib|
           requests|socket|shell=True|input\(|subprocess" reports/US-01.1/qa_exit_criterion.py
56:import subprocess
163:    subprocess.run(
168:        shell=True,
173:    p = subprocess.run(
180:        shell=True,
```

- **`eval`, `exec`, `os.system`, `pickle`, `marshal`, `__import__`, `compile`, `input` : ZÉRO.**
- **`urllib`, `requests`, `socket` : ZÉRO** — le script n'ouvre **aucune** connexion en propre.
- **`subprocess` : 2 appels**, dont les `argv` sont des **littéraux constants**
  (`["flutter","pub","get"]` et `["flutter","test","--reporter","expanded"]`). **Aucune donnée
  externe n'entre dans une ligne de commande** ⇒ **aucune injection de commande**.
- ⚠️ `shell=True` est **inutile** ici → **NB-8** (§6).
- ⚠️ Réseau **indirect** : `flutter pub get` contacte pub.dev. **Atténué** : le script copie
  `pubspec.lock`, donc la résolution est **épinglée** (versions + hachages) et n'ouvre pas de
  latitude de substitution.

### 5.3 Chemins dérivés d'`argv` ?

**Non.** L'analyseur d'arguments n'expose qu'un **booléen** :

```python
ap.add_argument("--selftest", action="store_true")
```

Aucune option de chemin. La racine est dérivée de `__file__` :
`DEPOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))`, et les cibles de
mutation sont **4 constantes littérales** du module (`TILE`, `THEME`, `TOKENS`, `HUB`).
⇒ **Aucune traversée de répertoire possible : il n'existe aucun chemin d'exécution où une entrée
utilisateur atteigne un chemin de fichier.**

### 5.4 Écrit-il dans le dépôt ?

**Non — par construction, puis vérifié par exécution.** Toutes les écritures visent `travail`,
sous `tempfile.mkdtemp(prefix="qa_us011_")` (nom **imprévisible**, donc **ni symlink ni TOCTOU**
sur un `/tmp/nom-fixe`). Le dépôt d'origine n'est ouvert qu'en **lecture** (`copytree`, `copy2`,
`_lire`). Chaque mutant est **restauré** juste après son test (`_ecrire(chemin, origine)`), et la
racine temporaire est supprimée dans un `finally`.

### 5.5 ⇒ **Le dépôt est-il intact après son exécution ? — MESURÉ : OUI**

Manifeste de hachage SHA-256 des 35 fichiers de `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`,
`analysis_options.yaml`, pris **avant**, puis **après la campagne complète**, puis **après le
`--selftest`**, puis **à la fin de tout mon audit** :

```
avant  : 620769144692c60feb36d8439ee2d80869e4910ce3b00a46535b53dadfde464b
apres  : 620769144692c60feb36d8439ee2d80869e4910ce3b00a46535b53dadfde464b
final  : (diff avant/final vide) -> IDENTIQUES : 35/35 fichiers, octet pour octet
$ git status --porcelain      (apres la campagne)  -> vide
$ ls -d %TEMP%/qa_us011_*                          -> AUCUN residu : rmtree a nettoye
```

⇒ **Aucun octet du dépôt n'a bougé**, la copie temporaire a été **nettoyée**, `HEAD` est resté
`173fb62`. **La promesse de l'en-tête du script (« le dépôt n'est JAMAIS modifié ») est TENUE, et
je l'ai vérifiée par mesure, pas en lisant son commentaire.**

### 5.6 Sortie de la campagne (exécutée réellement)

```
Copie isolee : ...\Temp\qa_us011_w03i8a4i\copie
Depot d'origine : ...\Concentration (JAMAIS modifie)
Baseline : 112 test(s) verts.

QA-M1   TUE  (attendu TUE) [OK] | 3 rouge(s)
QA-M2b  TUE  (attendu TUE) [OK] | 2 rouge(s)
QA-M3   TUE  (attendu TUE) [OK] | 1 rouge(s)
QA-M4   TUE  (attendu TUE) [OK] | 2 rouge(s)
QA-M5   TUE  (attendu TUE) [OK] | 3 rouge(s)
QA-M7   TUE  (attendu TUE) [OK] | 2 rouge(s)
QA-M6   TUE  (attendu TUE) [OK] | 4 rouge(s)   <- CONTROLE POSITIF

CRITERE DE SORTIE ATTEINT -- tous les mutants sont TUES.
EXIT=0

$ python reports/US-01.1/qa_exit_criterion.py --selftest
[OK] les 7 motifs de mutation existent dans le depot
[OK] le controle positif QA-M6 est present
Autotest : 0 echec(s).      EXIT=0
```

*(Le verdict fonctionnel appartient à la QA, pas à moi. Je le consigne parce que le
**contrôle positif QA-M6 est tué**, ce qui rend les six autres résultats **interprétables** — sans
lui je n'aurais rien pu conclure de cette exécution.)*

### 5.7 Appréciation de sécurité

Le script est **sain**. Il respecte les conventions les plus dures du projet (mutants désignés par
leur **texte** et jamais par un numéro de ligne ; **motif introuvable = ÉCHEC**, jamais un succès
silencieux ; **contrôle positif** ; comparaison en **ensembles**). Son commentaire des lignes
285-289 documente même un `for…else` fautif **trouvé et corrigé dans l'instrument de mesure
lui-même** — c'est la bonne pratique du corpus, appliquée.
**Deux réserves mineures, sans exploitabilité (NB-8), et le fait qu'il vive dans `reports/`
c'est-à-dire hors de tout gate.**

---

## 6. Les scripts du job **REQUIS** `Governance` sont-ils intacts ?

**Oui — vérifié par hachage de blob, puis rejoué step par step.**

```
scripts/check_gherkin_mapping.py    80bf3fcd...  [=6fe75df]           (neuf dans cette US, deja audite)
scripts/check_scb_compliance.py     227340a8...  [=6fe75df, =main]
scripts/validate_trace.py           f602b216...  [=6fe75df, =main]
scripts/factory_sync.py             fdd30fe9...  [=6fe75df, =main]
scripts/selftest_coverage_ratchet.py c7c1bbb5...  [=6fe75df, =main]
scripts/run_gates.py                79e85a1f...  [=6fe75df, =main]
scripts/check_flutter_coverage.py   b3bf8fcf...  [=6fe75df, =main]
scripts/trace_append.py             0ebf8610...  [=6fe75df, =main]
$ git diff HEAD --name-only -- scripts/     -> vide (arbre de travail conforme a HEAD)
```

⚠️ **Point important** : sept de ces huit scripts sont **identiques à `main`** ; seul
`check_gherkin_mapping.py` diffère de `main` — parce qu'il est **livré par cette US**, et il avait
déjà été audité en détail dans [`security.md`](security.md) §3 (stdlib seule, aucun `subprocess`,
écritures confinées à `tempfile`, pas de ReDoS). **Son blob n'a pas bougé depuis.**

Rejeu local du job requis (tous les steps, dans l'ordre du `ci.yml`) :

```
python scripts/check_scb_compliance.py        -> EXIT=0   SCB conforme — Aucune violation détectée.
python scripts/validate_trace.py --all        -> EXIT=0   Traçabilité conforme.
python scripts/factory_sync.py --check        -> EXIT=0   Synchro factory conforme (DOCUMENTAIRE)
python scripts/selftest_coverage_ratchet.py   -> EXIT=0   les 9 assertions sont tenues, dont 5 REFUS
python scripts/check_gherkin_mapping.py       -> EXIT=0   13 scenarios <-> 13 tests
python scripts/check_gherkin_mapping.py --selftest -> EXIT=0   6 assertions, 0 echec(s)
```

### Gates et scans

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (verifier factory.config.json / --component / --gate).
SAST_EXIT=1

$ python scripts/run_gates.py --gate deps_audit
  direct dependencies:  cupertino_icons 1.0.9 (Latest 1.0.9) · flutter (sdk)
  dev_dependencies:     flutter_lints 6.0.0 (Latest 6.0.0)  · flutter_test (sdk)
  You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit                                                    DEPS_EXIT=0

$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact --verbose
INF scanned ~154430854 bytes (154.43 MB) in 7.05s
INF no leaks found                                                   GITLEAKS_EXIT=0

$ python scripts/run_gates.py --all
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
Tous les gates bloquants passent (5 executes).                       GATES_EXIT=0
```

### État de `main` sur GitHub — **lecture seule** (`GET` uniquement)

```
{"protected":true}
{"contexts":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
             "check-branch-name","📱 App (gates run_gates.py)"],
 "enforce_admins":true,"reviews":0,"strict":true}
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}

$ python scripts/factory_sync.py --check-remote
Protection de gitgdx/Concentration:main — conforme a la cible generee.   REMOTE_EXIT=0
```

⇒ Protection intacte, **0 écart**. **Aucune écriture GitHub** n'a été effectuée durant cet audit.

---

## 7. Findings

Format : `[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

### 7.1 Bloquants

**AUCUN.**

### 7.2 État de NB-1 → NB-6 (rapports précédents)

| # | Sév. | État sur `173fb62` | Fondement |
|---|---|---|---|
| **NB-1** | LOW | **INCHANGÉ** — ni aggravé, ni résolu | Re-mesuré §7.3 |
| **NB-2** | LOW | **INCHANGÉ** — `depuisDonnee` conserve **0 appelant dans `lib/`** | Sa **définition est sa seule occurrence** dans `lib/` (7 occurrences, toutes dans `test/`) |
| **NB-3** | INFO | **INCHANGÉ** | `lib/core/color/temporal_gradient.dart` **non touché** (arbre `lib` identique) |
| **NB-4** | INFO | **INCHANGÉ** | `.github/` **bit-à-bit identique** ; défaut du dépôt re-mesuré : `"read"` |
| **NB-5** | LOW | **INCHANGÉ** | **Aucune action ajoutée** ; les 8 `uses:` sont les mêmes qu'auparavant |
| **NB-6** | LOW (méthode) | **INCHANGÉ — et re-mesuré** | ci-dessous |

**NB-6 re-mesuré** (c'est le finding qui gouverne ma propre saisine) :

```
$ python scripts/trace_append.py --help
  options : --us --event --agent --model --rationale --files --report --command --session
            => AUCUNE option --commit / --sha
$ champs du dernier evenement :
  ['agent','event','evidence','files','model','rationale','session','ts','us']
  un champ commit/sha existe ? False
```

⇒ **Toujours vrai : un visa n'est rattachable à aucun commit, donc il périme en silence.** Mon
prédécesseur avait appliqué la mitigation « SHA dans le champ libre » ; **je l'applique aussi**, et
je répète sa borne : ⚠️ **c'est une convention NON enforcée** (`validate_trace.py` ne valide pas ce
champ). Elle **réduit** le risque, elle ne le supprime pas. ➡️ **US-00.8** (correctif réel = champ
`commit` validé ⇒ touche le schéma de la trace ⇒ **exige son propre ADR**).

📌 **Cet épisode est la 2ᵉ occurrence RÉELLE de NB-6 sur la seule US-01.1.** La 1ʳᵉ avait été
rattrapée par un humain. La 2ᵉ aussi (@Architect a remis les colonnes du SCB à ⏳). **Deux fois sur
deux, c'est le process qui a rattrapé, jamais un mécanisme.** C'est un argument mesuré pour
prioriser cette dette, pas une remarque de style.

### 7.3 NB-1 re-mesuré sur le bundle de release construit **à l'instant** sur `173fb62`

La question posée était précise : *« les nouveaux tests changent-ils quelque chose à son
exposition ? »*

```
$ ls -l build/web/main.dart.js            -> 2031554 octets
$ grep -c "atteinte"    build/web/main.dart.js  -> 1   (CONTROLE POSITIF : le grep SAIT trouver)
$ grep -c "id non vide" build/web/main.dart.js  -> 0
$ grep -c "I-2"         build/web/main.dart.js  -> 0
$ grep -c "I-6"         build/web/main.dart.js  -> 0
```

⇒ **L'invariant I-2 reste absent du bundle de release** (`assert(id != '', 'I-2 : id non vide')`
est retiré à la compilation release). **Inchangé.**

**Les nouveaux tests modifient-ils son exposition ? NON, et c'est mesuré** :

```
$ git diff 6fe75df..173fb62 -- test/ | grep '^+' | grep -E "depuisDonnee|I-2"
  (aucune occurrence)
```

Les lignes ajoutées ne contiennent **aucun appel à `depuisDonnee`** et **aucune assertion sur
I-2** ; la seule construction d'`Echeance` ajoutée utilise un `id` valide (`id: 'a'`).
⇒ **Exposition de NB-1 strictement inchangée : ni réduite, ni élargie.**

⚠️ **Et la recommandation R-1 reste entière** : NB-1 devient atteignable **dès qu'US-01.2 lira des
données persistées**. Ce delta **ne l'a pas traité**, et **ne prétend pas l'avoir traité**. Le fait
que 2 083 lignes de tests aient été ajoutées **sans toucher cette frontière** est en soi une
information utile pour US-01.2 : **le renforcement a porté sur le rendu, pas sur la validation
d'entrée.**

### 7.4 Findings **nouveaux** — 2, non bloquants

| # | Outil | Fichier:Ligne | Sév. | Décision |
|---|---|---|---|---|
| **NB-7** | Revue + campagne de mutation | `test/support/rendu_couleur.dart:37,39` | **INFO (méthode, non-sécurité)** | **Accepté — signalé à @QA / @CodeReviewer** |
| **NB-8** | Revue | `reports/US-01.1/qa_exit_criterion.py:168,180` (+ 163, 147) | **LOW** | **Accepté — durcissement conseillé, non bloquant** |

#### NB-7 — Le helper partagé sélectionne **par position dans l'arbre**, en silence

`test/support/rendu_couleur.dart` est un **point de confiance concentré** : il est importé par
**trois** suites.

```
$ grep -rln "support/rendu_couleur" test/
test/e2e/hub_echeances_test.dart
test/features/echeances/presentation/widgets/echeance_tile_test.dart
test/features/hub/presentation/hub_page_test.dart
```

Le fichier **énonce lui-même la règle** dans le commentaire de `couleurDuLibelle` :
*« sans jamais désigner un widget par sa position dans l'arbre, qui glisserait en silence »* — et
`couleurDuLibelle` l'applique correctement, en asservissant sa sélection à `expect(couleurs,
hasLength(1))`, donc en **échouant bruyamment** si la désignation devient ambiguë.

Mais son voisin `fondDeLaTuile` fait l'inverse, **sans aucune assertion d'unicité** :

```
37:  final cible = tuile ?? find.byType(EcheanceTile).first;
39:    find.descendant(of: cible, matching: find.byType(DecoratedBox)).first,
```

Si l'arbre gagnait un `DecoratedBox` ancêtre, le helper lirait **une autre couleur** et les trois
suites deviendraient **fausses ensemble**, **sans rougir**. C'est la classe de défaut nº 1 du
projet — *« une règle n'existe qu'en un seul exemplaire »* — ici sous sa variante la plus
sournoise : **la règle est écrite et son voisin immédiat y déroge**.

⚠️ **Ce n'est PAS un finding de sécurité, et je ne le déguise pas en tel** : ce code n'est pas
livré (§4), il ne peut pas nuire à un utilisateur. Il peut seulement **produire un faux vert**.

📌 **Contre-preuve empirique que je dois donner, car elle m'oblige** : la campagne de mutation
**tue QA-M1 et QA-M6 à travers ce helper** (§5.6) ⇒ **il lit aujourd'hui bel et bien la couleur
réellement peinte, il n'est pas décoratif**. Le risque est donc de **régression future**, pas
d'inexactitude actuelle. **Remède d'un coût nul** : appliquer à `fondDeLaTuile` l'assertion
d'unicité que son voisin porte déjà.

#### NB-8 — `shell=True` inutile, et code de retour de `pub get` non lu

```python
163:    subprocess.run(["flutter", "pub", "get"], cwd=dest, capture_output=True,
                        text=True, shell=True)        # <- retour NON lu
173:    p = subprocess.run(["flutter", "test", "--reporter", "expanded"], ..., shell=True)
```

1. **`shell=True` est inutile** et interpose `cmd.exe`. ⚠️ **Exploitabilité : NULLE en l'état, et
   je le dis franchement** — les `argv` sont des **littéraux constants**, donc **aucune injection
   n'est possible**. La réserve est de **défense en profondeur** : `cmd.exe` résout un nom de
   commande **contre le répertoire courant avant le `PATH`**, et le répertoire courant est ici la
   copie mutée. **Vérifié : ce chemin n'est pas atteignable** — `_preparer_copie` ne copie que
   `lib/`, `test/` et trois fichiers nommés, donc **aucun `flutter.bat`/`.exe` ne peut atterrir à
   la racine de la copie**. Remède : retirer `shell=True`.
2. **Le code de retour de `flutter pub get` n'est pas lu.** ⚠️ **Échoue en sécurité** : si la
   récupération échoue, la baseline est rouge et le script s'arrête sur
   `[ABANDON] la BASELINE est deja rouge` (chemin présent, l. 200-203). **Pas de faux vert
   possible** — c'est la bonne propriété. Le lire rendrait seulement le diagnostic plus net.
3. Détails sans portée sécurité : `_lire`/`_ecrire` n'utilisent pas de gestionnaire de contexte
   (descripteurs laissés à la finalisation) ; la restauration du mutant n'est pas dans un
   `finally` — **sans conséquence**, la mutation ne vivant que dans la copie temporaire, elle-même
   supprimée par le `finally` de `campagne()`.

---

## 8. ⚠️ Un fichier NON SUIVI est apparu **pendant** mon audit — je le déclare

Mon instantané initial montrait un arbre **propre**. À la fin, `git status --porcelain` rend :

```
?? reports/US-01.1/code_review_delta2_mutants.py
```

Mesuré :

```
$ git cat-file -e 173fb62:reports/US-01.1/code_review_delta2_mutants.py
  NON : absent de 173fb62 -> fichier NON SUIVI, hors de mon perimetre de visa
  ABSENT de mon instantane initial -> cree PENDANT mon audit, par un autre acteur
  en-tete : """Mutants NON PUBLIES du 3e passage de revue -- @CodeReviewer, 2026-08-02.
             SHA AUDITE : 173fb62348c5ca516505067c1ea29c97fa06b8a8"""
```

⇒ C'est l'artefact d'un **auditeur pair travaillant en parallèle** sur le **même SHA**. **Il n'est
pas dans `173fb62`, donc mon visa ne le couvre pas** — ni en bien ni en mal. Je le signale
uniquement parce qu'⛔ **un auditeur sécurité ne déclare jamais « arbre propre » quand il ne l'est
plus** : le lecteur qui rejouerait mes commandes verrait cette ligne et devrait pouvoir l'expliquer.
**L'intégrité de `lib/`, `test/` et `pubspec*` reste, elle, prouvée intacte (§5.5).**

---

## 9. ⚠️ Incident d'instrumentation — **mon propre harnais a imprimé un verdict FAUX**

Je le consigne parce que le corpus l'exige (*« les trois instruments d'audit se sont pris à leur
propre piège »*, US-00.6) et parce que le taire serait précisément le faux vert que ce projet a
payé six fois.

**Ce qui s'est passé** : mon script d'expérience du §4 écrivait chaque mesure dans un fichier via
`tee`, puis calculait le verdict en relisant ces fichiers. Le répertoire parent n'existait pas
encore au premier `tee` ⇒ `r1.txt` **n'a jamais été écrit** ⇒ la variable `AVANT` était **vide** ⇒
la comparaison a imprimé :

```
VERDICT test-only : bundles DIFFERENTS -> le delta touche le livrable OU la construction
                    n'est pas reproductible          <- FAUX
```

alors que les **mesures brutes imprimées trois lignes plus haut étaient correctes et égales**.

**Classe de défaut : exactement celle du CLAUDE.md** — *un verdict dérivé d'un support jamais relu,
imprimé à côté de la donnée juste*. Une comparaison contre une valeur **absente** avait rendu
`différent` au lieu d'**abandonner**.

**Correctif appliqué** : verdict **recalculé à partir des mesures brutes elles-mêmes**, avec
**refus explicite de conclure si une mesure manque** (`[ABANDON] mesure absente -- aucun verdict`).
Le verdict corrigé (§4.2) est **`IDENTIQUE`**, et il est **adossé à un contrôle positif qui passe**.

⚠️ **Portée exacte** : le défaut était dans **l'agrégation**, jamais dans **la mesure** — les trois
hachages ont été produits par `sha256sum` sur les fichiers réellement construits. **Aucune autre
conclusion de ce rapport n'en dépend.** *(Incident annexe et amusant : le hook `block_dangerous_bash`
a refusé une de mes commandes parce que mon **motif de recherche** contenait le nom d'un drapeau
interdit — le motif « citation-dans-sa-réfutation », vivant, dans un garde-fou.)*

---

## 10. Bornes assumées — inchangées, redites sans être gonflées

- ⛔ **AUCUN SAST** : `run_gates --gate sast` → **exit 1, le gate n'existe pas**. Les 314 lignes de
  Python et les ~1 700 lignes de Dart de test de ce delta n'ont reçu qu'une **revue humaine**,
  **sans garantie d'exhaustivité**. Dette inscrite au CLAUDE.md ➡️ **US-00.8**.
- ⛔ **AUCUN scanner de CVE** : `dart pub outdated` mesure l'**obsolescence**, jamais la
  **vulnérabilité** ; un paquet à jour et vulnérable serait **vert**.
  **Justification documentée du PASS malgré cette borne** *(mon rôle interdit un PASS non
  justifié)* : **`pubspec.lock` est bit-à-bit identique** à celui de `6fe75df` et de `main` (§3)
  ⇒ **zéro dépendance ajoutée, zéro version modifiée** ⇒ la surface d'approvisionnement est
  **rigoureusement celle déjà justifiée** dans [`security.md`](security.md) §0/B-2, et **ce delta
  n'introduit aucun risque de chaîne d'approvisionnement nouveau**. Les deux dépendances directes
  hors SDK (`cupertino_icons 1.0.9`, `flutter_lints 6.0.0`) restent à la dernière version publiée.
  ⚠️ **Ce raisonnement borne le risque, il ne le mesure pas** : **aucune base CVE n'a été
  interrogée.**
- Aucun DAST, aucun fuzzing, aucune revue du code transitif du SDK Flutter.
- La mesure du §4 porte sur la **cible web** uniquement.
- **NB-7 et NB-8 ont été trouvés à la main** : ils illustrent une fois de plus, par l'exemple, ce
  qu'un SAST pourrait signaler seul.

---

## 11. Conclusion

Le delta `6fe75df` → `173fb62` est **neutre en sécurité** :

- **`lib/` est bit-à-bit identique** ⇒ aucune capacité applicative nouvelle ; `dart:io` toujours
  absent ⇒ ni réseau, ni disque, ni processus ⇒ **IDOR / authz / CSRF / CORS / injection / XSS
  demeurent sans objet, structurellement** ;
- **l'artefact livré est PROUVÉ inchangé** — `main.dart.js` bit-à-bit identique, **contrôle positif
  à l'appui** ; le delta ne peut donc **rien** changer pour un utilisateur ;
- **aucune dépendance**, **aucun fichier d'enforcement**, **aucun script du job requis** n'a bougé ;
- **aucun secret** (gitleaks, 154 Mo scannés) ;
- le seul code exécutable neuf (`qa_exit_criterion.py`) **n'est invoqué par aucune CI**, n'a
  **aucune entrée dérivée d'`argv`**, **aucun `eval`/`exec`**, des `argv` de sous-processus
  **constants**, et **laisse le dépôt intact — mesuré par manifeste de hachage**.

Les six findings antérieurs sont **inchangés** ; les deux nouveaux sont **non bloquants** et
portent sur la **robustesse d'instruments de test** (NB-7) et un **durcissement de défense en
profondeur** (NB-8).

⚠️ **Et il reste vrai que ce verdict ne s'appuie sur AUCUN SAST et AUCUN scan de CVE.** Ce que
j'atteste est une **revue humaine outillée par des contrôles de gouvernance et par deux expériences
portant leur contrôle positif**, pas une analyse de sécurité automatisée.

**⇒ VERDICT : PASSED sur `173fb62`.**

---

## 12. Recommandations (aucune n'est bloquante)

| # | Recommandation | Porteur suggéré |
|---|---|---|
| R-1 | Remplacer l'`assert` d'`Echeance` par une validation active, **avant** d'ouvrir la persistance | **US-01.2** (NB-1) — *reconduite, non traitée par ce delta* |
| R-2 | Borner `dateEcheance` dans `depuisDonnee` + test de la borne | **US-01.2** (NB-2) |
| R-3 | Ajouter `permissions: {contents: read}` au job `governance` | US-00.8 (NB-4) |
| R-4 | Épingler les actions tierces par SHA de commit, comme `actionlint` | US-00.8 (NB-5) |
| R-5 | Champ `commit` **validé** dans le schéma de trace — **exige son propre ADR** | US-00.8 (NB-6) |
| R-6 | Doter la factory d'un SAST Dart/Python et d'un scan de CVE | US-00.8 |
| R-7 | Asservir `fondDeLaTuile` à une assertion d'unicité, comme `couleurDuLibelle` | **@QA / US-01.1** (NB-7) |
| R-8 | Retirer `shell=True` et lire le code de retour de `flutter pub get` | @QA (NB-8) |

---

*Rapport produit en contexte frais par @CyberSecurity (`claude-opus-5[1m]`). Toutes les sorties
ci-dessus ont été réellement exécutées le 2026-08-02 sur **`173fb62`**. Aucune modification du code,
des tests, du SCB ni de l'état GitHub ; `gh api` en **lecture seule** (`GET`) uniquement.
⛔ **`security.md` et `security_delta.md` n'ont pas été écrasés** — leurs verdicts restent vrais
**à leur date et sur leur commit**, et périmés pour tout autre.*
