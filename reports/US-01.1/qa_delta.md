# Rapport QA — US-01.1 — **2ᵉ passage (delta)**

| Champ | Valeur |
|---|---|
| **Commit audité** | **`558a47592651d6c4384a519fab2dceee390e74d9`** (**`558a475`**) |
| **Commit du 1ᵉʳ passage** | `6fe75df720214a9bac74efd9b6f024f7cd561407` (`6fe75df`) — verdict `FAILED` |
| **Agent** | @QA_Tester — contexte frais |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **Branche** | `feat/US-01.1-dev-presentation` |
| **Rapport précédent** | [`qa.md`](qa.md) — ⛔ **non écrasé** : on date, on ne repeint pas |
| **Critère de sortie rejoué** | [`qa_exit_criterion.py`](qa_exit_criterion.py) |
| **Nouveaux instruments** | [`qa_delta_nb7_probe.py`](qa_delta_nb7_probe.py) · [`rnf02_exit_criterion.py`](rnf02_exit_criterion.py) |

---

## 🧪 VERDICT : **PASS**

**112 passed · 0 skipped · 0 failed · couverture 95,2 % · mon critère de sortie rend `exit 0`.**

Les **6 mutants survivants** qui motivaient mon `FAILED` sont **tués**. Les **3 AC orphelins**
tombent à **1**, et celui qui reste (**AC-1 « Limite » / RNF-02**) est celui dont **l'arbitrage ne
m'appartient pas** — aucun vert n'a été fabriqué dessus.

> ⛔ **CE QUE CE `PASS` N'ATTESTE PAS, et qui doit être lu avant `/certify`** :
> **AC-1 « Limite » (RNF-02, « < 500 ms ») reste NON VÉRIFIÉ.** Il n'est pas couvert, il est
> **ouvert**. `/certify` ne doit pas le compter comme couvert. §6.
> Et je ne délivre pas `🚀 OUI` : la certification appartient au rituel `/certify` (@Architect),
> Constitution Art. 5.

---

## 1. Périmètre — **mesuré moi-même**, la saisine ne fait pas foi

Au 3ᵉ passage d'audit, un périmètre de 3 commits en valait 4 et **les deux auditeurs ont repris le
chiffre**. Je n'ai donc rien admis :

```
$ git rev-parse HEAD                       -> 558a47592651d6c4384a519fab2dceee390e74d9
$ git rev-list --count 6fe75df..558a475    -> 5
$ git diff --name-only 6fe75df..558a475 -- lib/ test/ | wc -l   -> 6
$ git status --porcelain                   -> (vide, arbre propre)
```

✅ **5 commits, 6 fichiers, tous dans `test/`, aucun dans `lib/`** — conforme à la saisine.

**Preuve plus forte que le `--name-only`** : les deux révisions portent **le même arbre `lib/`**.

```
$ git rev-parse 6fe75df^{tree}:lib   -> d95a69c2cabe0da179f7680ebd18ea4692b20162
$ git rev-parse 558a475^{tree}:lib   -> d95a69c2cabe0da179f7680ebd18ea4692b20162
```

⇒ `lib/` est **bit-à-bit identique**. Les 6 mutants ont été tués **sans toucher une ligne de code
produit** : ce n'est pas le produit qui a changé, **c'est la suite qui a cessé de mentir**.

### 1.1 Fraîcheur des visas — vérifiée contre le critère que le visa énonce lui-même

`EVT_CODE_REVIEW_PASSED` (18:05:14) et `EVT_SECURITY_AUDIT_PASSED` (17:56:17) portent tous deux sur
**`173fb62`**, et `HEAD` est `558a475`. Le visa sécurité énonce que ce qui le périme est un commit
touchant `lib/`, `.github/`, `pubspec` ou un fichier d'enforcement. J'ai testé **cette clause-là** :

```
$ git diff --name-status 173fb62..558a475
M  PROJECT_LOG.md
M  STORY_CERTIFICATION_BOARD.md
M  docs/trace/US-01.1/events.jsonl
A  reports/US-01.1/code_review_delta2.md
A  reports/US-01.1/code_review_delta2_mutants.py
A  reports/US-01.1/security_delta2.md

$ git diff --name-only 173fb62..558a475 -- lib/ .github/ pubspec.yaml pubspec.lock \
      scripts/ .claude/ analysis_options.yaml factory.config.json
(vide)
```

✅ Delta **100 % documentaire**. **Les deux visas sont FRAIS** au sens de leur propre clause.
`python scripts/validate_trace.py --us US-01.1` → **`Traçabilité conforme.`**, exit 0.

---

## 2. Mon critère de sortie — rejoué, **et le script n'a pas bougé**

⛔ Un critère de sortie qu'on peut réécrire ne prouve rien. **Identité de blob vérifiée
moi-même**, à chaque commit du delta et sur le disque :

```
$ git log --oneline --follow -- reports/US-01.1/qa_exit_criterion.py
be9cc4a test(us-01.1): la QA REFUSE alors que TOUS LES GATES sont verts     <- unique commit

$ for c in be9cc4a ade583e ddf839e 173fb62 558a475; do git rev-parse $c:reports/US-01.1/qa_exit_criterion.py; done
e29d75d938d4aed31800c471e9ce308f8aa4e0f1   (x5, identiques)
$ git hash-object reports/US-01.1/qa_exit_criterion.py
e29d75d938d4aed31800c471e9ce308f8aa4e0f1   <- disque = index = toutes les revisions
```

✅ **Un seul commit dans son historique, un seul blob.** Le critère jugé aujourd'hui est
**exactement** celui que j'ai publié le 2026-08-02.

### 2.1 Autotest

```
$ python reports/US-01.1/qa_exit_criterion.py --selftest
[OK] 0 rouge(s) correctement extrait(s)
[OK] 1 rouge(s) correctement extrait(s)
[OK] 2 rouge(s) correctement extrait(s)
[OK] un motif absent est bien detectable
[OK] les 7 motifs de mutation existent dans le depot
[OK] le controle positif QA-M6 est present

Autotest : 0 echec(s).                                                   exit 0
```

📌 **`les 7 motifs de mutation existent dans le depot` n'est pas décoratif** : c'est ce qui
interdit au critère de se blanchir en silence. Si le développeur avait tué mes mutants en
**déplaçant le code muté**, les motifs seraient devenus introuvables et le script aurait rendu
**`[ECHEC] MOTIF INTROUVABLE`**, pas un succès. Il ne l'a pas fait.

### 2.2 Campagne — sortie brute, non retouchée

```
$ python reports/US-01.1/qa_exit_criterion.py
Baseline : 112 test(s) verts.

QA-M1   TUE     (attendu TUE) [OK] | 3 rouge(s)
QA-M2b  TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M3   TUE     (attendu TUE) [OK] | 1 rouge(s)
QA-M4   TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M5   TUE     (attendu TUE) [OK] | 3 rouge(s)
QA-M7   TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M6   TUE     (attendu TUE) [OK] | 4 rouge(s)

CRITERE DE SORTIE ATTEINT -- tous les mutants sont TUES.                 exit 0
```

| Mutant | Clause | 1ᵉʳ passage (`6fe75df`) | **2ᵉ passage (`558a475`)** |
|---|---|---|---|
| QA-M1 | AC-5 Nominal — tuile figée en orange | 🔴 SURVIT | ✅ **TUÉ** (3 rouges) |
| QA-M2b | AC-8 Nominal — fond blanc | 🔴 SURVIT | ✅ **TUÉ** (2 rouges) |
| QA-M3 | AC-3 Limite — `FittedBox` retiré | 🔴 SURVIT | ✅ **TUÉ** (1 rouge) |
| QA-M4 | AC-3 Nominal — description jamais rendue | 🔴 SURVIT | ✅ **TUÉ** (2 rouges) |
| QA-M5 | AC-2 Nominal — plus rien n'est grisé | 🔴 SURVIT | ✅ **TUÉ** (3 rouges) |
| QA-M7 | AC-4 Limite — période portée à 1 h | 🔴 SURVIT | ✅ **TUÉ** (2 rouges) |
| **QA-M6** | **CONTRÔLE POSITIF** | ✅ TUÉ | ✅ **TUÉ** (4 rouges) |

✅ **7/7 au verdict attendu.** Le contrôle positif meurt toujours ⇒ le harnais détecte réellement,
et les 6 morts ne sont **pas** un artefact de mesure.

---

## 3. Décomptes exacts — lus dans une sortie (Art. 3)

### 3.1 Gate

```
$ python scripts/run_gates.py --gate test
00:15 +112: All tests passed!
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigné le 2026-07-31
  [HAUSSE] 95.24% (380/399) > cliquet 89.4%. Valeur a consigner : 95.2
✅ app.test
Tous les gates bloquants passent (1 exécutés).                           exit 0
```

### 3.2 passed / **skipped** / failed — lus dans le flux JSON

Le rapporteur `expanded` n'expose qu'un cumul ; seul le flux JSON porte le drapeau `skipped`.

```
$ flutter test --reporter json > tests.json
testDone retenus (hors 'loading ' / hidden) : 112
resultats                                   : {'success': 112}
skipped=true                                : 0  []
hidden/loading                              : 11
done.success                                : True
nb fichiers de test                         : 11
```

| Décompte | 1ᵉʳ passage | **2ᵉ passage** |
|---|---:|---:|
| **passed** | 102 | **112** |
| **skipped** | 0 | **0** |
| **failed** | 0 | **0** |
| **errors** | 0 | **0** |
| Fichiers de test | 8 | **11** |

⚠️ **`0 skipped` est MESURÉ, pas constaté par absence** : le drapeau a été lu pour chacun des
**112** tests. La liste des `skipped` est **vide** (`[]`), pas absente. Aucun scénario n'est vert
par défaut.

Répartition (lue dans le flux) — les 3 fichiers **nouveaux** sont en gras :

| Tests | Fichier |
|---:|---|
| 27 | `test/features/echeances/domain/remaining_time_calculator_test.dart` |
| 18 | `test/core/color/temporal_gradient_test.dart` |
| 13 | `test/e2e/hub_echeances_test.dart` |
| 13 | `test/features/echeances/presentation/echeances_grid_test.dart` (+1) |
| 11 | `test/features/echeances/domain/echeance_test.dart` |
| 10 | `test/features/echeances/presentation/grille_gabarits_test.dart` |
| 7 | `test/features/hub/domain/practice_module_registry_test.dart` |
| 4 | `test/core/time/clock_test.dart` |
| **4** | **`test/features/echeances/presentation/widgets/echeance_tile_test.dart`** |
| **3** | **`test/core/theme/concentration_theme_test.dart`** |
| **2** | **`test/features/hub/presentation/hub_page_test.dart`** |

*(`test/support/rendu_couleur.dart` n'est pas un `*_test.dart` : il est importé, jamais exécuté
comme suite — cohérent avec les 11 suites relevées.)*

### 3.3 E2E — les 13 scénarios montent toujours la racine

```
$ grep -c "testWidgets(" test/e2e/hub_echeances_test.dart -> 13   (13 tests au flux JSON)
$ python scripts/check_gherkin_mapping.py                 -> exit 0  (13 <-> 13)
$ python scripts/check_gherkin_mapping.py --selftest      -> exit 0  (6 assertions)
```

⚠️ L'outil **imprime lui-même sa borne** : *« Controle de CORRESPONDANCE DE TITRES — pas de
semantique. »* C'est précisément l'angle mort que ma campagne de mutation mesure, et c'est pourquoi
**son exit 0 ne vaut pas couverture** — au 1ᵉʳ passage il rendait déjà `13 ↔ 13` avec 5 étapes
décoratives.

---

## 4. Couverture — **recomptée** depuis `lcov.info`

Je n'ai pas repris le « 95,2 % » du gate : j'ai réagrégé les `DA:` avec mon propre compteur.

```
TOTAL DA lignes instrumentees : 399
TOTAL couvertes               : 380   NON couvertes : 19
POURCENTAGE RECOMPTE          : 95.2381%  -> arrondi VERS LE BAS 1 dec : 95.2
nb fichiers dans lcov         : 19
```

✅ **380/399 = 95,2381 % → 95,2.** Mon recompte tombe sur la valeur du gate.
**> cliquet 89,4 %** · **> plancher 80,0 %** · **aucune régression**.

### 📌 Le résultat le plus instructif du delta : **la couverture n'a pas bougé d'une ligne**

| | 1ᵉʳ passage | 2ᵉ passage |
|---|---:|---:|
| Lignes couvertes / instrumentées | **380 / 399** | **380 / 399** |
| Pourcentage | **95,2381 %** | **95,2381 %** |
| Lignes de test ajoutées | — | **+526** |
| Mutants tués en plus | — | **+6** |
| AC orphelins | 3 | **1** |

⛔ **+526 lignes de test et 6 comportements d'AC passés de « régressibles en silence » à
« protégés » ont produit exactement ZÉRO variation de couverture.** C'est la **première
démonstration du projet sur du code produit réel** que la couverture de lignes est **aveugle à la
force des assertions** : elle mesure ce qui est **exécuté**, jamais ce qui est **vérifié**. Le
cliquet de couverture n'aurait **rien vu** de ce delta — ni du défaut, ni de sa correction.
➡️ **À verser au corpus de méthode.**

**Les 19 lignes non couvertes** (inchangées, `lib/` étant identique) :

| Non couvertes | Fichier | Lignes |
|---:|---|---|
| 14 | `features/echeances/domain/remaining_time.dart` | 37, 39-44, 46-52 |
| 2 | `core/color/rgb.dart` | 59, 60 |
| 1 | `core/theme/concentration_theme.dart` | 23 |
| 1 | `core/theme/concentration_tokens.dart` | 14 |
| 1 | `features/echeances/data/sample_echeances.dart` | 15 |

⏳ **N-7 confirmé** : `remaining_time.dart` concentre **14 des 19** lignes non couvertes.
⚠️ **Angle mort du dénominateur, re-confirmé** : `lib/` = **20** fichiers `.dart`, `lcov.info` en
liste **19** — **`lib/main.dart` est absent du dénominateur**, aucun test ne l'important.

---

## 5. Les 3 AC orphelins du 1ᵉʳ passage, repris **un par un**

> La question posée est la bonne : *« corrigés, ou seulement autrement ? »* Je l'ai tranchée par
> **mutation**, pas par relecture.

### 5.1 AC-8 « Nominal » — mode sombre · ✅ **RÉELLEMENT corrigé**

**Le défaut** : `expect(scaffold.backgroundColor ?? ConcentrationTokens.fondApp.couleur, isNotNull)`
— le `??` retombait sur une constante jamais nulle ⇒ **vraie quoi qu'il arrive**.

**Ce qui a été fait** : l'assertion tautologique a été **supprimée** (elle n'a pas été « renforcée »),
et remplacée par **deux assertions de nature différente** :

| Assertion | Nature | Ce qu'elle tue |
|---|---|---|
| `ConcentrationTheme.sombre.scaffoldBackgroundColor == ConcentrationTokens.fondApp.couleur` | **égalité au token** | une mutation du **thème** (QA-M2b) |
| `fond.luminanceRelative < texte.luminanceRelative` | **GRANDEUR** | une mutation du **token** lui-même |

✅ **C'est exactement la parade au piège identifié par la revue** : une égalité au token est
tautologique **si l'on mute le token** (les deux côtés bougent ensemble) ; la **grandeur** — *« un
fond plus clair que son texte est un mode CLAIR »* — reste vraie indépendamment des tokens retenus.
Les deux ensemble couvrent **les deux directions de mutation**. **QA-M2b : 2 rouges.**

### 5.2 AC-4 « Limite » — RF-05 · ✅ **RÉELLEMENT corrigé**

**Le défaut** : le test `pump`ait `ConcentrationTokens.periodeRafraichissement` **elle-même** —
assertion **auto-référentielle**, verte à 30 s comme à 1 h.

**Ce qui a été fait** : un budget **indépendant de la source qu'il contrôle**, écrit **une seule
fois**, et une assertion **directe** :

```dart
const budgetRf05 = Duration(minutes: 1);       // vient de l'AC, pas du token
await tester.pump(budgetRf05);                 // une minute, pas « la periode »
expect(ConcentrationTokens.periodeRafraichissement, lessThanOrEqualTo(budgetRf05));
expect(ConcentrationTokens.periodeRafraichissement, greaterThan(Duration.zero));
```

✅ **Le budget est une SPÉCIFICATION (l'AC dit « au minimum une fois par minute »), pas la
transcription d'une mesure** — c'est la distinction exacte qui avait fait retirer le v1 de la QA
d'US-00.5. Et `greaterThan(Duration.zero)` **borne l'autre côté** : sans lui, `Duration.zero`
satisferait l'inégalité en faisant tourner la reconstruction en boucle. **QA-M7 : 2 rouges.**

### 5.3 AC-1 « Limite » — RNF-02 · ⛔ **TOUJOURS NON VÉRIFIÉ** → §6

Aucun vert n'a été fabriqué dessus. **C'est le bon comportement** et je le dis explicitement : il
valait mieux le laisser ouvert que le repeindre.

### 5.4 Les 3 autres survivants (hors « orphelins ») — également tués

| Mutant | Ce qui l'a tué | Nature de l'assertion |
|---|---|---|
| **QA-M1** (AC-5) | 5 points de `p` + **clarté strictement décroissante** | égalité **et** GRANDEUR |
| **QA-M4** (AC-3) | description assertionnée **par clé de tuile** (`ValueKey`) | vérifie aussi l'**appariement** |
| **QA-M5** (AC-2) | couleur par module **issue du registre** + **contraste moindre** | égalité **et** GRANDEUR |
| **QA-M3** (AC-3 Lim.) | largeur naturelle **lue sur le paragraphe**, + **garde-fou** | grandeur + garde-fou |

📌 **Trois garde-fous ont été posés là où un test aurait pu cesser de contrôler en silence** — et
ils méritent d'être relevés parce qu'ils relèvent de la classe de défaut n° 1 du projet :
`expect(naturelle, greaterThan(cote))` (*« le cas doit être un VRAI débordement »*),
`expect(registre.grises, isNotEmpty)` (*« sans module grisé, ce test ne contrôle rien »*),
`expect(couleurs, hasLength(1))`. **Chacun transforme un futur silence en rouge.**

---

## 6. **RNF-02** — état factuel et **critère de levée exécutable**

> ⛔ **La décision de reporter cet AC n'est PAS la mienne** (@PO / @Architect). Ce que je livre :
> l'**état factuel**, puis **l'instrument, le seuil et la cible**, sous forme **exécutable**.

### 6.1 ⚠️ Je corrige d'abord une imprécision de **mon propre rapport précédent**

J'y ai écrit *« aucun émulateur, aucun JDK »* et *« aucun appareil »*. **Mesuré aujourd'hui, c'est
inexact** — je le retire plutôt que de le « mettre à jour » :

```
$ flutter devices        -> 3 connected devices : Windows (desktop) | Chrome (web) | Edge (web)
$ flutter emulators      -> No emulators available.
$ flutter doctor
[!] Android toolchain ... X No Java Development Kit (JDK) found
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps
```

**Il y a bien 3 appareils.** Ce qui manque est **plus précis** : **aucun appareil de la cible du
produit**. Formulation exacte :

| Cible | Appareil | Runner dans le dépôt | Verdict |
|---|---|---|---|
| **android** | ⛔ aucun (0 émulateur, **pas de JDK**) | ✅ `android/` | **indisponible** |
| **ios** | ⛔ aucun | ⛔ absent | **indisponible** |
| windows | ✅ détecté | ⛔ `windows/` **absent** | écarté (le créer modifierait le produit — hors périmètre QA) |
| web | ✅ Chrome, Edge | ✅ `web/` | écarté (**pas la plateforme cible**) |

### 6.2 Le critère de levée, **livré comme un script**, pas comme un souhait

**[`reports/US-01.1/rnf02_exit_criterion.py`](rnf02_exit_criterion.py)**

| | |
|---|---|
| **Instrument** | `flutter run --profile --trace-startup` → `build/start_up_info.json`, clé **`timeToFirstFrameRasterizedMicros`** — le seul chiffre du toolchain qui couvre « l'ouverture » **jusqu'au premier frame RASTERISÉ**, donc réellement visible |
| **Seuil** | **LU** dans le Story File, jamais écrit dans le script (*une règle n'existe qu'en un seul exemplaire*) — phrase désignée par son **texte**, jamais par un numéro de ligne |
| **Cible** | `--device` **obligatoire** — le script **refuse de deviner** : « 500 ms » n'a de sens que sur une machine nommée |
| **Sorties** | `0` LEVÉ · `1` mesuré et **DÉPASSE** · `2` **NON MESURABLE** (⚠️ ni succès ni échec produit) · `3` défaut de l'instrument |

```
$ python reports/US-01.1/rnf02_exit_criterion.py --selftest
[OK] la frontiere est stricte sur 5 cas
[OK] seuil lu dans le Story File : 500
[OK] phrase retiree -> ECHEC franc, pas de valeur inventee
[OK] deux seuils divergents -> ECHEC franc
[OK] cle de mesure absente -> ECHEC franc
[OK] la mesure est lue telle quelle
[OK] controle negatif : les 2 cas evidents se comportent bien
Autotest : 0 echec(s).                                                   exit 0

$ python reports/US-01.1/rnf02_exit_criterion.py
... NON MESURABLE ICI -- et ce n'est ni un succes ni un echec du produit. exit 2
```

📌 **Le mutant de corpus est le cœur du script** : sur un Story File d'où la phrase du seuil est
retirée, il **échoue franchement** au lieu d'inventer une valeur ; sur un Story File qui en porte
**deux**, il refuse aussi. ⇒ **le jour où RNF-02 est reformulé, ce critère le dit** au lieu de se
blanchir.

**Les deux voies de levée, et elles n'appartiennent pas à la QA :**

1. **Mesurer pour de vrai** — JDK + émulateur Android (ou téléphone), puis
   `--mesurer --device <id>` : `exit 0` ou `exit 1`, **un chiffre lu dans un fichier**, jamais une
   impression.
2. **Reformuler RNF-02** en budget de `build + layout` du **premier frame**, mesurable dans le
   harnais headless et donc **protégé par le gate `test`**.
   ⚠️ **Ce serait un AC DIFFÉRENT et plus faible** — il exclut moteur, VM, polices, shaders et
   rasterisation. **L'écrire serait honnête ; l'appeler encore « RNF-02 » sans le dire ne le serait
   pas.**

⛔ **Tant que l'une des deux n'est pas faite, AC-1 « Limite » n'est pas couvert** — et **aucun gate
de la factory ne surveille cette grandeur**.

---

## 7. Les deux findings d'audit qu'on me demande de qualifier

### 7.1 **NB-7** — ⚠️ **CONFIRMÉ, et je le RELÈVE de INFO à « défaut démontré »** · **non bloquant**

La sécurité posait un **risque de régression future**. Je ne l'ai pas jugé sur relecture : je l'ai
**mesuré**, avec une **paire bidirectionnelle** et un **contrôle négatif**.
Sonde rejouable : **[`qa_delta_nb7_probe.py`](qa_delta_nb7_probe.py)**.

```
Baseline        : 112 test(s) verts.

NB7-B   SURVIT  (attendu TUE   ) [ECHEC] | 0 rouge(s)
NB7-B2  TUE     (attendu TUE   ) [OK]    | 3 rouge(s)
NB7-C   SURVIT  (attendu TUE   ) [ECHEC] | 0 rouge(s)
NB7-C2  TUE     (attendu TUE   ) [OK]    | 3 rouge(s)
NB7-N   SURVIT  (attendu SURVIT) [OK]    | 0 rouge(s)      <- controle NEGATIF
```

**F-Δ1 · `fondDeLaTuile` autorise un FAUX VERT SILENCIEUX — démontré**
- **Action effectuée** : dans une copie isolée, la tuile reçoit **deux** `DecoratedBox` imbriquées —
  l'**extérieure** garde `fond.couleur` (correcte, suit la progression), l'**intérieure**, celle qui
  est **réellement peinte**, est **figée en orange**. La tuile rend donc **toujours orange** : c'est
  **exactement le défaut de QA-M1**.
- **Résultat attendu** : au moins un rouge — AC-5 exige que la couleur suive la progression.
- **Résultat obtenu** : **`112 verts, 0 rouge`**. ⛔ **Faux vert silencieux confirmé.**

**Le miroir LOCALISE le défaut** (un mutant seul n'aurait pas dit *quelle* boîte est lue) :
**NB7-B2** — extérieure figée / **peinte correcte**, donc **rendu BON** — produit **3 rouges**.
⇒ **`.first` lit la boîte EXTÉRIEURE, celle qui n'est pas nécessairement peinte.** Faux vert d'un
côté, **faux rouge** de l'autre. **`NB7-N` survit**, donc la suite ne rougit pas sur tout et ces
verdicts sont interprétables.

**Corollaire que je n'attendais pas, et qui nuance la formulation de l'audit** : `couleurDuLibelle`
n'énonce pas tout à fait « la règle contraire ». Son `hasLength(1)` porte sur un **`.toSet()` de
COULEURS**, pas sur un **nombre de widgets** :
- **NB7-C** (2ᵉ libellé, **même** couleur) → **SURVIT** : le `.toSet()` **fusionne**, le garde-fou ne
  voit rien.
- **NB7-C2** (2ᵉ libellé, couleur **différente**) → **TUÉ** : le garde-fou **est vivant**.
⇒ Le garde-fou est **réel mais plus étroit que sa propre justification** (*« un seul libellé portant
une couleur explicite est attendu »*). **Borne à connaître, pas un faux.**

**Ma position — pourquoi ce n'est PAS bloquant, et je le motive :**
1. ✅ **Mes mutants ne sont pas affaiblis aujourd'hui.** QA-M1 et QA-M6 **meurent** ; `lib/` ne
   contient **qu'une** `DecoratedBox` par tuile, donc `.first` désigne un élément **non ambigu**.
2. ⚖️ **NB7-B n'est pas une mutation minimale : il ajoute un LEURRE DEVANT le point d'observation.**
   Tout point d'observation peut être défait ainsi. Ce mutant éprouve le **harnais**, pas le
   **produit** — et la norme d'une campagne de mutation est la mutation **minimale et naturelle**,
   qui, elle, meurt.
3. 📌 **Précédent du projet** : le **GEL** d'US-00.6 — le développeur a satisfait le critère de
   sortie **que j'avais publié** ; transformer en bloquant un défaut découvert **après** relancerait
   la régression infinie que ce précédent a close. *Un bloquant l'aurait été quel qu'en soit le
   coût* — celui-ci n'en est pas un.
4. ⚠️ **Mais le risque est réel et le coût du correctif est d'UNE LIGNE.** `Container`,
   `Card`, `Material`, un `InkWell` : tout wrapper courant en Flutter introduit une seconde
   `DecoratedBox`. Le jour où cela arrive, **la protection d'AC-5 tombe sans un seul rouge**.

**Correctif recommandé** (au développeur — je ne touche pas aux tests) : dans `fondDeLaTuile`,
remplacer la sélection positionnelle par une sélection **assertée**, alignée sur la règle que
`couleurDuLibelle` énonce déjà, par exemple `expect(candidats, findsOneWidget)` sur le finder
descendant **avant** de lire la décoration. **La sonde `qa_delta_nb7_probe.py` rendra `exit 0`
quand NB7-B et NB7-C seront tués** — critère borné, falsifiable, rejouable.
➡️ **À défaut de correction ici : US-00.8.**

### 7.2 **N-5 PARTIEL** — ✅ confirmé présent · **NON bloquant pour moi**

**F-Δ2 · le scénario 5 promet une donnée que son test n'emploie pas**
- **Action effectuée** : lecture du `.feature` puis du test E2E homonyme.
- **Résultat attendu** : le scénario *« Étant donné qu'une échéance est atteinte dans **8 mois et
  12 jours** … Alors le nombre affiché est **"9"** »* est exercé avec ses propres données.
- **Résultat obtenu** : `test/e2e/hub_echeances_test.dart:245` →
  `lancerAvec(tester, [e('a', const Duration(hours: 5, minutes: 10))])` — **`5 h 10 → 6`**.

**Pourquoi non bloquant** : la **règle du PRD est bel et bien couverte**, en unitaire —
`test/features/echeances/domain/remaining_time_calculator_test.dart:32` :
`test('8 mois 12 jours -> 9 mois', …)`. **L'AC-4 « Nominal » n'est donc pas orphelin.**
✅ Les **2 autres divergences** relevées par la revue **sont corrigées** (le scénario *« 4 échéances
actives »* injecte désormais **4** échéances et non 3 ; la donnée « bleu imminent » est passée de
`5 h 59` — qui donnait en réalité **p = 1/60, l'ORANGE** — à `5 h 1`, **dérivée par calcul**).

⚠️ **Mais c'est le même mécanisme que les 6 faux verts** : *un titre qui promet plus que son
assertion*. Et `check_gherkin_mapping.py` **ne peut pas le voir** — il l'annonce lui-même. Ce n'est
plus une couverture manquante, c'est une **traçabilité scénario ↔ donnée** trompeuse.
➡️ **À corriger dans cette US si le coût est nul, sinon US-00.8.**

---

## 8. Couverture des AC — **re-mesurée**, 9 AC × 3 clauses = **27**

Légende : ✅ couvert · 🟠 partiel · ⛔ **orphelin** · ➖ sans objet

| AC | Clause | 1ᵉʳ | **2ᵉ** | Preuve / manque |
|---|---|:--:|:--:|---|
| **AC-1** | Nominal | 🟠 | 🟠 | Structure ✅ · **dark mode ✅ (QA-M2b tué)**. ⚠️ Conformité à la maquette **jamais observée** (aucun rendu vu). |
| | Erreur | 🟠 | 🟠 | Données absentes ✅ (placeholder) · **illisibles ⛔** : `depuisDonnee` a **0 appelant** dans `lib/` (N-6 inchangé). |
| | **Limite** | ⛔ | ⛔ | **RNF-02 : ni mesuré ni testé** — §6. **Seul orphelin restant.** |
| **AC-2** | Nominal | 🟠 | ✅ | Visibles ✅ · **grisés ✅ (QA-M5 tué)** — égalité **et** contraste moindre, sur **`registre.grises`** donc **Respiration ET Concentration** *(la réserve du 1ᵉʳ passage tombe pour la couleur)* · non-interactifs ✅. ⚠️ La boucle de **non-interactivité** e2e ne porte toujours que sur `Respiration`. |
| | Erreur | ✅ | ✅ | Appui simple / répété / prolongé → `takeException() isNull`. |
| | Limite | ✅ | ✅ | 2 modules affichés · commandes non-interactives (`Semantics(enabled: false)`). |
| **AC-3** | Nominal | 🟠 | ✅ | 1 tuile / échéance ✅ · carrées ✅ (5 gabarits) · **description ✅ (QA-M4 tué)**, assertée **par clé**. |
| | Erreur | 🟠 | 🟠 | Description vide ✅ · **donnée invalide ⛔** (même cause que AC-1 Erreur). |
| | Limite | ✅⚠️ | ✅ | 9 tuiles ✅ · 10ᵉ bornée ✅ · 5 gabarits ✅ · **`FittedBox` désormais assertionné (QA-M3 tué)** — la réserve tombe. |
| **AC-4** | Nominal | ✅ | ✅ | 27 tests, **4 exemples du PRD** dont `8 mois 12 jours -> 9 mois`. ⚠️ N-5 (§7.2). |
| | Erreur | ✅ | ✅ | Ni unité, ni fraction, ni signe — assertions bornées à la tuile. |
| | **Limite** | ⛔ | ✅ | **Budget 1 min indépendant du token + `≤` direct (QA-M7 tué)** — §5.2. |
| **AC-5** | Nominal | 🟠 | ✅ | **5 points de `p` + clarté strictement décroissante (QA-M1 tué)**. ⚠️ Réserve NB-7 (§7.1). |
| | Erreur | ✅ | ✅ | `p` indépendant de la grandeur du nombre ✅ · aucun rouge saturé (101 pts) ✅. |
| | Limite | ✅ | ✅ | Contraste sur 101 points · extrémités exactes. |
| **AC-6** | Nominal | ✅ | ✅ | Ordre par date croissante (e2e + grille + domaine). |
| | Erreur | ✅ | ✅ | Ex æquo départagés par `id` — comparateur **total**. |
| | Limite | ✅ | ✅ | Échue **en tête**. |
| **AC-7** | Nominal | ✅ | ✅ | État « à zéro » : affiche `0`, ne disparaît pas. |
| | Erreur | ✅ | ✅ | Jamais de nombre négatif. |
| | Limite | ➖ | ➖ | Geste de disparition **explicitement hors périmètre** (→ US-01.2). |
| **AC-8** | **Nominal** | ⛔ | ✅ | **Mode sombre : égalité au token + GRANDEUR (QA-M2b tué)** — §5.1. |
| | Erreur | 🟠 | 🟠 | « Aucun élément anxiogène » ✅ mais **borné au placeholder**, jamais à l'écran complet. |
| | Limite | 🟠 | 🟠 | Contraste WCAG AA ✅ · lecteur d'écran ✅. **« Tailles de police système » ⛔** : `grep -rn "textScaler\|textScaleFactor\|TextScaler" lib/ test/` → **aucune occurrence**. |
| **AC-9** | Nominal | ✅ | ✅ | Placeholder sobre à 0 échéance. |
| | Erreur | ✅ | ✅ | Ni erreur technique, ni « ! », ni rouge, ni gamification. |
| | Limite | ✅ | ✅ | Spécifié **et rendu** dès US-01.1. |

### Bilan

| État | 1ᵉʳ passage | **2ᵉ passage** |
|---|---:|---:|
| ✅ Couvert | 15 | **20** |
| 🟠 Partiel | 8 | **5** |
| ⛔ **Orphelin** | **3** | **1** |
| ➖ Sans objet | 1 | 1 |
| **Total** | 27 | **27** |

### ⛔ AC ORPHELIN — il n'en reste **qu'un**

1. **AC-1 « Limite »** — **RNF-02, « prêt au regard » < 500 ms** : ni mesuré ni testé.
   ⚖️ **Arbitrage @PO / @Architect** — critère de levée exécutable livré (§6).

### 🟠 Clauses partielles dont la **moitié manquante est nommée**

| Clause | Moitié manquante | Mesure |
|---|---|---|
| AC-1 Nominal | conformité à la maquette | **aucun rendu jamais observé** |
| AC-1 Erreur · AC-3 Erreur | donnée **illisible** atteignant l'écran | `depuisDonnee` : **0 appelant** dans `lib/` (N-6) |
| AC-8 Erreur | « aucun élément anxiogène » **hors placeholder** | 1 test, borné au placeholder |
| AC-8 Limite | **tailles de police système** | **0 occurrence** de `textScaler` dans `lib/` et `test/` |

---

## 9. Edge cases éprouvés — au-delà des cas passants

**Nouveaux au 2ᵉ passage** (relevés dans les sorties, pas listés de mémoire) :
- **5 points de progression** `{0 ; 0,25 ; 0,5 ; 0,75 ; 1}` sur le **rendu** de la tuile, plus la
  **monotonie stricte** de la clarté entre points consécutifs.
- **Débordement réel provoqué** : nombre `108` dans une tuile de **90 px**, avec **garde-fou**
  vérifiant que le cas **est** un vrai débordement (`naturelle > cote`), largeur naturelle **lue sur
  le paragraphe** (`getMaxIntrinsicWidth`) et non reconstruite à côté, puis **4 bornes de rectangle**.
- **Période de rafraîchissement bornée des DEUX côtés** : `≤ 1 min` **et** `> 0`.
- **Mode sombre comme grandeur** : `luminance(fond) < luminance(texte)`, indépendant des tokens.
- **Grisé comme grandeur** : contraste sur fond **strictement moindre** que celui du module actif.
- **Appariement description ↔ tuile** par `ValueKey`, sur **4** échéances distinctes.

**Repris du 1ᵉʳ passage et toujours verts** : `T ≤ 0` · `p` aux bornes · balayage de **400 instants** ·
**29 février** · écrêtage du jour · bascule jours→heures à **exactement 24 h** · **101 points** de
contraste · hors gamut (**seule la chroma bouge**) · échec **bruyant** si seuil inatteignable ·
`id` vide refusé · `null` / `'pas une map'` / date `'demain'` → `null` **sans lever** · ex æquo ·
**5 gabarits** 320×568 → 1920×1080 · 10ᵉ tuile bornée · appui simple/répété/prolongé · DST.

**Cherchés et toujours inexistants** : `textScaler` · densité de pixels · orientation paysage ·
locale ≠ `fr` · > 10 échéances au niveau écran · **donnée invalide atteignant la grille**.

---

## 10. Mes propres instruments — ce qui a raté, dit plutôt que tu

⚠️ **Mon critère de levée RNF-02 a été REFUSÉ par son propre autotest au premier lancement** : son
**contrôle négatif inversait les deux arguments** de `verdict(mesure_us, seuil_ms)` et affirmait
`NON LEVE` là où la fonction rend `LEVE`. **C'est la classe de défaut récurrente n° 1 du projet** —
*une valeur posée à la main à côté d'une commande* — **cette fois dans l'instrument de mesure
lui-même, pour la deuxième QA d'affilée**. Le mutant l'a arrêtée avant moi ; le contrôle a été
**réécrit en table comparée en ENSEMBLES**, et le défaut est **consigné dans le script**, non effacé.

✅ `PYTHONIOENCODING=utf-8` forcé sur **toutes** les commandes ; mes deux scripts imposent en outre
`sys.stdout.reconfigure(encoding="ascii", errors="replace")`. **Aucun plantage `cp1252`** ce
passage-ci — le 1ᵉʳ en avait connu un.

**Intégrité du dépôt — vérifiée après les 12 mutations exécutées** :

```
$ git status --porcelain
?? reports/US-01.1/qa_delta_nb7_probe.py
?? reports/US-01.1/rnf02_exit_criterion.py
$ git diff --stat -- lib/ test/      -> (vide)
$ git rev-parse HEAD                 -> 558a475... (inchange)
```

✅ **Aucune ligne de `lib/` ni de `test/` touchée** : toutes les mutations ont eu lieu dans des
copies temporaires. **Écritures confinées à `reports/US-01.1/`.** **SCB non modifié.**

---

## 11. Ce que ce rapport **n'atteste pas**

- ⛔ **AC-1 « Limite » / RNF-02 n'est PAS couvert** — §6. `/certify` ne doit pas le lire comme tel.
- ⛔ **Aucun rendu visuel n'a été observé.** L'application n'a **jamais** été lancée. Tous les
  contrastes sont **calculés** ; **aucun n'a été vu par un œil**. Conformité à la maquette
  `hub_de_pratiques.png` : **non vérifiée**.
- ⛔ **Aucun runner BDD n'existe.** Les 13 scénarios sont exécutés par des **tests Dart qui
  reproduisent leurs titres**, pas par un moteur Gherkin. Les **103 scénarios de gouvernance**
  restent **« SPÉCIFICATION — NON EXÉCUTÉE »**.
- ⛔ **Aucune couverture de branches** — 95,2 % est une couverture **de lignes**, et §4 montre
  qu'elle **n'a pas bougé** alors que la qualité des assertions changeait du tout au tout.
- ⛔ **`lib/main.dart` n'est ni couvert ni compté.**
- ⛔ **NB-7 reste ouvert** : un faux vert silencieux **démontré** est possible sur AC-5 après un
  refactor banal (§7.1).
- ⛔ **Aucun SAST, aucun scan de CVE** dans la factory — hors de mon périmètre, rappelé pour que ce
  `PASS` ne soit pas lu comme portant sur la sécurité.
- ⛔ **Ce verdict porte sur `558a475` et sur lui seul.** La trace n'ayant **aucun champ `commit`**
  (**NB-6**), le SHA est inscrit dans le **champ libre** : **convention non enforcée**. Tout commit
  ultérieur touchant `lib/` ou `test/` **périme ce verdict en silence**.
- ⛔ **Je ne délivre pas `🚀 OUI`** — Constitution Art. 5. Je délivre **`🧪 PASS`**.

---

## 12. Traçabilité

| Élément | Valeur |
|---|---|
| **Événement émis** | `EVT_QA_PASSED` |
| **Commit couvert** | `558a47592651d6c4384a519fab2dceee390e74d9` |
| **Exécutions** | `validate_trace.py` → exit 0 · `run_gates.py --gate test` → exit 0 (**112 tests**, 95,2 %) · `flutter test --reporter json` → **112 passed / 0 skipped / 0 failed** · recompte indépendant de `lcov.info` → **380/399 = 95,2381 %** · `check_gherkin_mapping.py` (+ `--selftest`) → exit 0 · `qa_exit_criterion.py --selftest` → exit 0 · **`qa_exit_criterion.py` → exit 0 (7 mutants, 7 tués)** · **`qa_delta_nb7_probe.py` → exit 1 (5 mutants : 2 survivants, 2 tués, 1 contrôle négatif conforme)** · `rnf02_exit_criterion.py --selftest` → exit 0 · `rnf02_exit_criterion.py` → **exit 2 (non mesurable)** · vérification d'identité de blob du critère de sortie · `flutter devices` / `emulators` / `doctor` |
| **Mutations exécutées** | **12**, toutes en copie temporaire |
| **Dépôt modifié ?** | **NON** — `lib/` et `test/` intacts ; écritures confinées à `reports/US-01.1/` |
| **SCB modifié ?** | **NON** |
| **Verdict** | 🧪 **PASS** — 112/0/0 · 95,2 % · **1 AC orphelin** (AC-1 Limite / RNF-02, arbitrage @PO/@Architect) · 2 findings non bloquants (**NB-7 relevé et démontré**, **N-5 partiel**) |
