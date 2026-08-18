# Rapport QA — US-01.2 « Gestion des échéances (CRUD) »

| Champ | Valeur |
|---|---|
| **Verdict** | 🧪 **PASS** |
| **Agent** | @QA_Tester — contexte **frais**, n'a produit ni le code ni les audits |
| **Modèle** | claude-opus-5[1m] (Opus 5, 1M context) |
| **Date** | 2026-08-18 |
| **Commits** *(**NB-6** : `trace_append.py` n'a **aucune** option `--commit` ⇒ les SHA vivent dans le `rationale`)* | **code = `28d9504`** · **HEAD = `ef87d8f`** *(branche `feat/US-01.2-design`)* |
| **Code figé ?** | ✅ **vérifié moi-même** : `git diff --name-only 28d9504..HEAD -- lib test scripts pubspec.yaml pubspec.lock` → **0 fichier** *(§1)* |
| **Décompte de tests** | **369 passed · 0 failed · 0 skipped** — **LU dans le reporter `json`**, ⛔ pas dans une ligne de résumé *(§2)* |
| **Couverture** | **97.9 % (941/961)** · cliquet **95.2** **LU** dans `factory.config.json` *(§3)* |
| **AC couverts** | **16 / 16 actifs** *(AC-9 vacant, conforme à la déclaration)* — ⛔ **0 AC orphelin** *(§5)* |
| **Findings BLOQUANTS** | **0** |
| **Findings NON BLOQUANTS** | **5** — `Q-1` (MEDIUM) · `Q-2` (MEDIUM) · `Q-3` (LOW) · `Q-4` (LOW) · `Q-5` (LOW) *(§8)* |
| **Campagne de mutation QA** | **10 mutants joués sur `lib/`** — **8 TUÉS**, **2 « survivants » de la seule suite e2e**, tous deux **TUÉS par la suite complète**, et le **contrôle `MQA8` les tue jusque dans l'e2e** *(§6)* |
| **Isolation** | `git worktree` **détaché** dédié, **sans `.dart_tool` ni `build`** au départ. ⛔ Arbre principal **jamais muté** — `git status --porcelain` **vide** dans les **deux** arbres à la clôture *(§10)* |

> ⛔ **Aucun nombre de ce rapport n'est écrit à la main.** Chaque chiffre est **lu dans une sortie
> collée** ; chaque emplacement est **désigné par son texte**, ⛔ jamais par un numéro de ligne.

---

## 0. Préconditions — refusées si absentes, vérifiées par exécution

```
$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
EXIT=0
```

Les deux visas exigés par mon rôle sont présents **et postérieurs au dernier `EVT_CODE_READY`** —
lu dans `docs/trace/US-01.2/events.jsonl` :

```
2026-08-11T20:06:18  EVT_CODE_READY            developer
2026-08-17T18:13:18  EVT_CODE_REVIEW_PASSED    code-reviewer
2026-08-17T18:23:39  EVT_SECURITY_AUDIT_PASSED cyber-security
```

⇒ **précondition satisfaite**, et **sur le bon code** : les deux visas suivent le 3ᵉ cycle de
correctif, ⛔ ils ne sont pas hérités d'un tour antérieur.

⚠️ **Le `🧪 PASS` d'US-01.1 est PÉRIMÉ** *(§Effet de bord du Story File)* et ⛔ **il ne me couvre
pas** : le présent rapport porte sur **US-01.2 seule**.

---

## 1. Le code est-il figé à `28d9504` ? — **OUI, vérifié, pas cru**

```
$ git log --oneline -3
ef87d8f docs(us-01.2): 3e tour d audit — DOUBLE VISA, revue et securite PASSED
b77e3cf docs(us-01.2): peremption des visas apres le 2e cycle de correctif
e991749 chore(us-01.2): EVT_CODE_READY re-emis apres le 3e cycle de correctif

$ git diff --name-only 28d9504..HEAD -- lib test scripts pubspec.yaml pubspec.lock
(fin liste)                                   <-- 0 FICHIER

$ git diff --name-only 28d9504..HEAD
PROJECT_LOG.md
STORY_CERTIFICATION_BOARD.md
docs/stories/US-01.2-gestion-echeances.md
docs/trace/US-01.2/events.jsonl
reports/US-01.2/code_review_delta2.md
reports/US-01.2/security_delta2.md
```

⇒ depuis `28d9504`, **seuls** le SCB, le PROJECT_LOG, le Story File, la trace et les deux rapports
d'audit ont bougé. **Mon verdict porte donc sur le même code que les deux visas.**

---

## 2. Suite complète — **369 passed · 0 failed · 0 skipped**

Un `skipped` **n'est pas un vert** *(Constitution Art. 3)*, et la ligne `All tests passed!` **ne
distingue pas** un test ignoré. Le décompte ci-dessous est donc **lu dans le reporter `json`**,
événement par événement :

```
$ flutter test --reporter json    (dans le worktree QA, vierge)
DECOMPTE MACHINE (reporter json) :
  passed  = 369
  failed  = 0
  skipped = 0
  hidden (evenements loading/compil) = 22
  TOTAL comptes = 369
```

**Contrôle croisé**, sortie brute de l'exécution ordinaire :

```
$ flutter test
01:30 +369: All tests passed!
[flutter test exit=0]
```

⇒ **369 = 369**, et **`skipped = 0` est MESURÉ**, ⛔ pas déduit de l'absence du signe `~`.

---

## 3. Les 5 gates — `run_gates.py --all`, dans le worktree QA

```
$ python scripts/run_gates.py --all
▶ app.format   — dart format --output=none --set-exit-if-changed lib test   ✅
▶ app.analyze  — flutter analyze                                            ✅
▶ app.test     — flutter test --coverage && check_flutter_coverage --min 80 ✅
▶ app.deps_audit — dart pub outdated --show-all                             ✅
▶ app.build    — flutter build web --release        √ Built build\web       ✅
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
[run_gates --all exit=0]
```

### Couverture et cliquet — la valeur du cliquet est **LUE**, ⛔ jamais recopiée

```
$ python scripts/check_flutter_coverage.py --min 80
Couverture de lignes : 97.9% (941/961) - seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigne le 2026-08-02 a PR27
  [HAUSSE] 97.92% (941/961) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.9
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
[exit=0]

$ python -c "... factory.config.json -> adapter.components.app.coverage_ratchet"
{"value": 95.2, "date": "2026-08-02", "motif": "PR27"}
gates declares : ['format', 'analyze', 'test', 'deps_audit', 'build']
```

⚖️ **La ligne `[HAUSSE]` est un AVIS informatif, ⛔ PAS un échec** — le cliquet **reste à 95,2** par
**arbitrage humain du 2026-08-07**. ⛔ Je ne le re-litige pas et **je n'ai touché aucun fichier de
configuration**. ⚠️ **Ce que la marge confortable ne dit pas** : ⛔ *la couverture de lignes est
aveugle à la force des assertions* — établi **6 fois** sur ce projet, **re-mesuré au 3ᵉ tour**
*(`940/960` **avant et après** la correction d'un bloquant HIGH)*. **97,9 % n'est donc pas un
argument de qualité de test** ; ce qui en tient lieu ici est **la mutation** *(§6)*.

---

## 4. Les contrôles propres au projet — **chacun avec son exit code**

| Contrôle | Sortie | Exit |
|---|---|---|
| `check_gherkin_mapping.py` | `US-01.1 : 13 scenarios / 13 tests` · `US-01.2 : 50 scenarios / 50 tests` · *« Controle de CORRESPONDANCE DE TITRES -- pas de semantique »* | **0** |
| `check_gherkin_mapping.py --selftest` | `Autotest : 6 assertions, 0 echec(s), 2 couple(s) sous controle.` | **0** |
| `check_e2e_persistance.py` | `[OK] controle « magasin » : 0 ecart(s)` · `[OK] controle « racine » : 0 ecart(s)` | **0** |
| `check_e2e_persistance.py --selftest` | `8 sources (1 conforme + 7 mutants COMPORTEMENTAUX)` · `Controles tues par au moins un mutant : ['magasin', 'racine']` | **0** |
| `reports/US-01.2/migration_roundtrip_criterion.py` | `A1…A8 = OK` · `VERDICT|OK|` · `CONTEXTE|dart=3.12.2|offset_janvier=1:00:00|offset_juillet=2:00:00` | **0** |
| `validate_trace.py --us US-01.2` | `Traçabilité conforme.` | **0** |
| `check_scb_compliance.py` | `SCB conforme — Aucune violation détectée.` | **0** |
| `factory_sync.py --check` | `Synchro factory conforme — vérification DOCUMENTAIRE` + son avertissement sur l'état réel non vérifié | **0** |

🔴 **Le critère d'entrée transféré par EPIC_00 est SATISFAIT, et c'est le fait le plus important de
cette US** : `migration_roundtrip_criterion.py` rend **`exit 0`** en imprimant
*« Le patron de MIGRATIONS.md section 4 est INSTANCIE ET EXECUTE sur le premier schema reel du
projet »*. Il **rendait `exit 1` en le disant** avant T5. ⇒ **le risque nº 4 d'EPIC_00 est
refermé au niveau du stockage** — ⚠️ **et à ce niveau seulement** *(borne **NM-4**, §7)*.

---

## 5. LES 50 SCÉNARIOS SONT-ILS RÉELLEMENT EXÉCUTÉS ? — **OUI, et voici ce qu'ils assertent**

C'est le point où ce projet a le plus menti à lui-même : pendant tout EPIC_00, des DoD annonçaient
« N scénarios Gherkin » pour **0 step definition et 0 runner**. **Ici, ce n'est plus le cas — et je
l'établis par trois mesures indépendantes, ⛔ aucune par relecture.**

### ① Les 50 titres existent et sont uniques — commande **publiée par le Story File**, exécutée

```
$ grep -c "^  Scénario: " tests/features/US-01.2-gestion-echeances.feature
50
$ grep "^  Scénario: " tests/features/US-01.2-gestion-echeances.feature | sort | uniq -d
(sortie VIDE)                          <-- 0 titre en double
```

⇒ le décompte du Story File est **confirmé par sa propre commande**, et l'unicité — que le @PO
signalait comme **lue et non prouvée** — est désormais **prouvée par `uniq -d`**.

### ② Les 50 tests s'exécutent — nommés un par un dans la sortie

Les 50 apparaissent individuellement dans la sortie de `flutter test`, de
`gestion_echeances_test.dart` : *« Une échéance placée dans le passé est refusée »*, … ,
*« Une suppression qui ne peut pas être écrite laisse l'échéance en place »*. **Exécution mesurée
isolément** : `flutter test test/e2e/gestion_echeances_test.dart` → **`50 passes, 0 en echec`**.

### ③ 🔴 Ce que `check_gherkin_mapping.py` NE DIT PAS — et ma sonde le mesure

Le contrôle **imprime lui-même** *« Controle de CORRESPONDANCE DE TITRES -- pas de semantique »*.
J'ai donc mesuré **sur quoi portent les assertions**, avec une sonde **portant son autotest de
mutation** *(source complète en annexe B, autotest **8/8**)* :

```
== test/e2e/gestion_echeances_test.dart -- 50 tests
   tests avec MOINS DE 2 expect()            : 0
   tests SANS aucune assertion sur le DISQUE : 12
```

⇒ **38 / 50 assertionnent l'état PERSISTÉ** *(`persistees()`, `harnais.octets()`)*, ⛔ pas seulement
le rendu — c'est le contrat d'ADR-010 §1, et il est tenu. **Aucun test n'est un titre nu.**

**Les 12 qui n'assertionnent que des widgets, nommés, ⛔ pas dissimulés** :

```
   [ 5 expect] Ouvrir la gestion ne rend pas interactifs les modules grisés
   [ 4 expect] La modification de la description est reflétée sur la grille sans redémarrage
   [ 3 expect] La modification de la date recalcule le nombre affiché sur la tuile
   [ 4 expect] La page de gestion liste les échéances actives et les échues dans deux groupes
   [ 3 expect] La page de gestion affiche le temps restant avec son unité
   [ 4 expect] Les échéances et leur état sont restitués à l'identique après réouverture
   [ 5 expect] Un enregistrement local illisible est ignoré sans empêcher l'ouverture
   [ 5 expect] Un stockage entièrement illisible conduit à l'état vide et jamais à une erreur technique
   [ 3 expect] La grille affiche les échéances persistées et non plus les données d'exemple
   [ 2 expect] Une échéance créée apparaît sur la grille sans redémarrage
   [ 4 expect] Les champs du formulaire portent un libellé annoncé par le lecteur d'écran
   [ 7 expect] Un message de validation reste sobre et sans élément anxiogène
```

⚖️ **Onze des douze sont LÉGITIMEMENT des scénarios d'ÉCRAN** *(interactivité, reflet sur la grille,
groupes, unité affichée, `Semantics`, sobriété)* : leur objet **est** le rendu. **Le douzième
mérite d'être nommé** — `AC-10 N`, *« Les échéances et leur état sont restitués à l'identique après
réouverture »*, dont l'énoncé parle de **persistance**. ⛔ **Il n'est pas vacueux pour autant** :
`ouvrirApplication` construit un **dépôt et un notifier NEUFS sur le même répertoire**, donc la
restitution **traverse réellement le disque** ; c'est l'**assertion** qui reste à l'écran, pas le
chemin. ➡️ **Finding `Q-5`**, non bloquant.

### ④ Couverture des AC — **16 / 16, aucun orphelin**, mesuré par croisement `.feature` ↔ `.dart`

Instrument dédié **portant son autotest de mutation** *(5 mutants, **5/5**, dont un **contrôle
négatif** : renommer un titre ne doit rien changer)*, source en annexe C :

```
AC      declares  retrouves  verdict
AC-1           3          3  couvert par des tests EXECUTES
AC-2           5          5  couvert par des tests EXECUTES
AC-3           3          3  couvert par des tests EXECUTES
AC-4           3          3  couvert par des tests EXECUTES
AC-5           4          4  couvert par des tests EXECUTES
AC-6           5          5  couvert par des tests EXECUTES
AC-7           4          4  couvert par des tests EXECUTES
AC-8           3          3  couvert par des tests EXECUTES
AC-9           0          0  AC SANS SCENARIO (vacant ou orphelin)
AC-10          2          2  couvert par des tests EXECUTES
AC-11          3          3  couvert par des tests EXECUTES
AC-12          3          3  couvert par des tests EXECUTES
AC-13          3          3  couvert par des tests EXECUTES
AC-14          2          2  couvert par des tests EXECUTES
AC-15          2          2  couvert par des tests EXECUTES
AC-16          2          2  couvert par des tests EXECUTES
AC-17          3          3  couvert par des tests EXECUTES

TOTAL         50         50
AC porteurs d'au moins un scenario : 16
AC en defaut : ['AC-9']
Titres de test n'appartenant a AUCUN groupe d'AC : AUCUN
```

⇒ **`AC-9` est le numéro VACANT**, déplacé en US-01.4 par arbitrage du 2026-08-03 — **ce n'est pas
un orphelin**, c'est la déclaration du Story File, **confirmée par la mesure**.
⇒ **`50` scénarios déclarés = `50` titres retrouvés comme tests**, et **aucun test ne flotte hors
d'un groupe d'AC** *(comparaison d'**ENSEMBLES**, ⛔ pas de cardinaux)*.

**Clauses** : **48**, dont **44 couvertes** et **4 déclarées non scénarisées** — décompte confirmé
par commande : `grep -cE "⛔ \*\*Aucun scénario|Partiellement non mesurable"` → **4**
*(AC-10 L, AC-14 L, AC-15 L, AC-17 L)*.

---

## 6. 🔴 CES 50 SCÉNARIOS TUENT-ILS QUOI QUE CE SOIT ? — **la mesure que personne n'avait faite**

**Fait de contexte, et c'est lui qui justifie cette campagne** : la revue du 3ᵉ tour a joué
**12 mutants**, mais elle **écrit elle-même sa borne** — *« mes mutants ont tourné sur
`test/features/echeances/data/` (93 tests), pas sur la suite entière »*. ⇒ **le pouvoir
discriminant des 50 scénarios n'avait jamais été mesuré.** Un titre qui correspond et un test qui
s'exécute **ne prouvent toujours pas** qu'une règle est défendue.

**Méthode** : chaque mutant modifie **`lib/`** — la **règle** que le scénario prétend défendre — puis
on exécute **uniquement** `test/e2e/gestion_echeances_test.dart`. Arbre restauré après **chacun**,
`git status --porcelain` **relevé et vide**. Base : `50 passes, 0 en echec`.

| # | Mutant — ce qu'il RÉINTRODUIT | Verdict e2e | Test(s) qui rougissent |
|---|---|---|---|
| `MQA1` | **AC-2 L** : `longueurMaxDescription` 80 → **81** *(le 81ᵉ caractère devient accepté)* | ✅ **TUÉ** | *Une description trop longue est refusée* |
| `MQA2` | **AC-3 N** : `heureParDefaut` 23 → **22** *(l'heure implicite n'est plus 23:59)* | ✅ **TUÉ (2)** | *…enregistrée à 23h59* · *…du jour courant sans heure reste valide avant 23h59* |
| `MQA3` | **AC-5 E** : `maxPresentesSurGrille` 9 → **10** *(la 10ᵉ création passe)* | ✅ **TUÉ (2)** | *La dixième création est refusée…* · *Une échéance échue présente… compte dans la limite de neuf* |
| `MQA4` | **AC-4 L** : `!isAfter` → `isBefore` *(la borne stricte tombe, `T = 0` accepté)* | ✅ **TUÉ** | *Une échéance dont le temps restant est nul est refusée* |
| `MQA5` | **AC-16** : **la barrière de forme canonique (règle V-1) NEUTRALISÉE** | ⚠️ **SURVIT à l'e2e** | *(aucun)* — voir ci-dessous |
| `MQA6` | **AC-16** : **la garde de calendrier RETIRÉE** | ⚠️ **SURVIT à l'e2e** | *(aucun)* — voir ci-dessous |
| `MQA7` | **AC-17** : `if (!ecriture.estReussi)` neutralisé *(un échec d'écriture ne produit plus AUCUN message)* | ✅ **TUÉ (3)** | *Un échec d'écriture est annoncé…* · *…la saisie est conservée et la nouvelle tentative aboutit* · *Une suppression qui ne peut pas être écrite…* |

```
  TUES = 5 / 7   SURVIVANTS = ['MQA5_AC16_barriere_V1_NEUTRALISEE', 'MQA6_AC16_garde_CALENDRIER_retiree']
  git status final : ''
```

### 🔬 Les deux survivants : **redondance de gardes, ⛔ pas règle non défendue** — établi par 3 mesures

**AC-16 est protégé par DEUX gardes indépendantes** : la **garde de calendrier**
*(`jourExisteAuCalendrier`, dont le rôle déclaré est l'**ancrage du message**)* et **la barrière
V-1** *(comparaison à la forme canonique)*. **Chacune suffit à refuser le 31 février** ⇒ en retirer
**une seule** laisse les 2 scénarios verts. **Je n'en suis pas resté à ce constat** : j'ai rejoué
les deux mutants **sur la suite complète**, puis ajouté un **contrôle `MQA8`** retirant **LES DEUX**.

| Mutant | Suite complète | Ce qui le tue — ⛔ **nommé, pas supposé** |
|---|---|---|
| `MQA5` *(V-1 neutralisée)* | ✅ **TUÉ — 360 passes, 9 rouges** | `date_civile_test.dart` *(« LA barrière (règle V-1) — le 31 février est REFUSÉ, sans exception, par la FORME », « une date SANS heure est refusée », « des secondes rendent la forme non canonique »…)* · `echeance_document_codec_test.dart` · `echeance_schema_migrations_test.dart` |
| `MQA6` *(calendrier retiré)* | ✅ **TUÉ — 367 passes, 2 rouges** | `validation_echeance_test.dart` *(« le 31 février est REFUSÉ / le 28 février est ACCEPTÉ — même test », « l'ÉDITION refuse la même date, par la MÊME fonction (R-10) »)* |
| **`MQA8`** *(**contrôle** : LES DEUX retirées)* | ✅ **TUÉ — 354 passes, 15 rouges** | …et **cette fois les 2 scénarios e2e d'AC-16 rougissent** : *« Une date qui n'existe pas au calendrier est refusée sans correction silencieuse »* et *« Une édition vers une date qui n'existe pas au calendrier est refusée »* |

🔴 **Conclusion, et elle est précise** : **aucune règle d'AC-16 n'est laissée sans défenseur.**
Le contrôle `MQA8` **prouve que les 2 scénarios e2e ne sont PAS vacueux** — ils rougissent dès que
la propriété observable disparaît réellement. Les « survivants » `MQA5`/`MQA6` mesurent une
**redondance de conception**, pas un trou de test.
⚠️ **Mais ils établissent un fait que le Story File énonce autrement** ➡️ **finding `Q-1`**.

**Bilan de ma campagne : 10 mutants joués — 8 TUÉS par l'e2e seule, 2 TUÉS par la suite complète,
0 survivant réel, 0 mutant non représentable. Arbre restauré et `git status` vide après chacun.**

---

## 7. Les bornes NM-6 → NM-10 sont-elles honnêtes, ou déguisées en test vert ?

**Vérifié par contrôle NÉGATIF** *(chercher ce qui ne doit PAS exister)*, ⛔ pas par relecture :

| Borne | Ce qu'elle déclare non observable | Ma vérification | Verdict |
|---|---|---|---|
| **NM-6** | **annonce réelle** par un lecteur d'écran | Le test d'AC-15 asserte `find.bySemanticsLabel(...)` et les `Semantics(liveRegion:)` — et porte **en clair** *« ⚠️ Borne NM-6 : ⛔ rien ici ne prouve qu'un lecteur d'écran les PRONONCE »*. **Aucun test ne prétend l'observer** | ✅ **HONNÊTE** |
| **NM-7** | contraste **VU**, rendu à grande police | `contraste_tokens_test.dart` **calcule** les ratios *(`Rgb.contrasteAvec`)* et écrit *« le contraste est CALCULÉ, ⛔ jamais VU »*. ✅ **Et le doublon a été SUPPRIMÉ** : `docs/design/us_01_2_contrastes.py` **n'existe plus** *(`ls` → `No such file`)* ⇒ la règle vit **en un seul exemplaire**, comme T9 l'exigeait | ✅ **HONNÊTE** |
| **NM-8** | `main()` **jamais exécuté** *(`path_provider` absent en test hôte)* | `grep -n "main.dart"` dans `coverage/lcov.info` → **AUCUNE ligne** ⇒ `main.dart` **n'entre même pas au dénominateur**. La borne est nommée dans 2 fichiers de test | ✅ **HONNÊTE** — et **encore vraie** |
| **NM-9** | refus d'une **heure civile inexistante localement** *(`02:30` au saut de printemps)* | Dans le `.feature`, la seule occurrence du sujet est une **ligne de COMMENTAIRE `#`**, ⛔ **jamais un `Scénario:`**. Les tests **nomment la borne** : *« ⚠️ Ce fichier ne teste PAS une bascule d'heure d'été — borne NM-9 »*, *« Le volet "heure civile inexistante" N'A PAS DE TEST : borne NM-9 »* | ✅ **HONNÊTE** — ⛔ **jamais déguisée** *(⚠️ mais voir `Q-1`)* |
| **NM-10** | comportement de l'**application web EXÉCUTÉE** | `grep -rn "NM-10" test/` → **sortie VIDE** ⇒ **aucun test ne prétend l'observer**. Le gate `build` **construit** et **n'exécute jamais** | ✅ **HONNÊTE** |

```
$ grep -rnoE "NM-[0-9]+" test/ | sort | uniq -c
   1 NM-2    2 NM-6    2 NM-7    2 NM-8    3 NM-9
```

⛔ **Aucune des cinq n'a été silencieusement transformée en test vert.** ⚠️ **NM-10 ne se lèvera pas
avec US-01.3** *(qui vise iOS/Android)* — la borne le dit elle-même, et je la confirme.

---

## 8. Findings — **0 BLOQUANT**, 5 non bloquants

> Format imposé : **Action effectuée → Résultat attendu → Résultat obtenu**.

### 🟠 `Q-1` · non bloquant · **MEDIUM** · la **compensation déclarée de NM-9** est imprécise — **mesuré**

* **Action effectuée** : mutant `MQA5` — neutraliser **la barrière de forme canonique (V-1)** seule,
  puis exécuter les 50 scénarios e2e.
* **Résultat attendu**, si la ligne NM-9 du Story File est exacte : au moins un des 2 scénarios
  d'AC-16 rougit. Elle écrit que ce qui est mesuré à la place de l'heure inexistante est
  *« **le MÊME prédicat de forme canonique**, en un seul exemplaire (règle V-2), **éprouvé sur la
  date inexistante au calendrier** — reproductible sous tout fuseau (**2 scénarios** : création,
  édition) »*.
* **Résultat obtenu** : **`50 passes, 0 en echec`**. Les 2 scénarios **n'atteignent jamais V-1**
  pour le 31 février — la **garde de calendrier court-circuite** avant. Ce qui éprouve réellement
  V-1, ce sont les **tests unitaires** de `date_civile_test.dart` *(9 rouges sous `MQA5`)*, que la
  **même ligne NM-9 nomme** dans sa seconde moitié *(« plus un test unitaire de la validation sur la
  forme canonique »)*.

⇒ **La seconde moitié de la compensation est VRAIE ; la première est imprécise.** ⛔ **Ce n'est pas
un trou de couverture** *(`MQA8` prouve que les 2 scénarios rougissent dès que la propriété
disparaît vraiment)* — c'est une **affirmation de dossier que la mesure ne soutient pas telle
qu'elle est écrite**.
**Correctif attendu** : **borner la phrase** *(« les 2 scénarios éprouvent le REFUS observable du
31 février ; le prédicat V-1 lui-même est éprouvé par `date_civile_test.dart` — mesuré : retirer V-1
seule laisse les 50 scénarios verts »)*. ⚖️ **Pourquoi NON BLOQUANT** : la règle est défendue, deux
fois ; l'écart porte sur la **description de l'instrument**, ⛔ pas sur le produit.

### 🟠 `Q-2` · non bloquant · **MEDIUM** · la **DoD est cochée 1 / 25**, et une case est **factuellement fausse**

* **Action effectuée** : compter les cases de la DoD du Story File, puis vérifier **chacune par
  exécution** *(§9)*.
* **Résultat attendu** : la DoD dit **« Toutes les cases doivent être cochées avant de passer la
  phase `quality_assurance` »**.
* **Résultat obtenu** : `grep -cE "^- \[x\]"` → **1** ; `grep -cE "^- \[[ x]\]"` → **25**.
  **Une seule case cochée sur 25**, alors que **19 sont matériellement satisfaites** *(§9)*.
  Et la case **« PR ouverte »** est **fausse** : `gh pr list --head feat/US-01.2-design --state all`
  → **`[]`**, **aucune PR n'existe**.

⚖️ **Pourquoi NON BLOQUANT pour la QA** : ⓵ **la substance de la case est tenue** — `git rev-list
--count HEAD..main` → **0** et `main` est **ancêtre** de `HEAD` ⇒ ⛔ **aucun commit direct sur la
branche principale**, qui est ce que la case protège ; ⓶ l'ouverture de la PR relève de
**@Developer / @DevOps** en `prepare_deployment`, ⛔ pas de moi ; ⓷ **ma grille de blocage** est
*tests en échec, AC non couvert, seuil de couverture non tenu* — **aucun des trois**.
🔴 **Mais c'est la 2ᵉ fois que ce projet observe la même chose** : *« la DoD n'exige la couverture
d'aucun AC »* *(US-01.1)*, et ici *« la DoD n'est pas tenue à jour du tout »*. ➡️ **`/audit-methodo`**.

### ⚠️ `Q-3` · non bloquant · **LOW** · le Story File déclare une **branche qui n'existe pas**

* **Action effectuée** : lire la métadonnée puis mesurer la branche réelle.
* **Résultat attendu** : les deux coïncident.
* **Résultat obtenu** : Story File → **`feat/US-01.2-gestion-echeances`** ;
  `git rev-parse --abbrev-ref HEAD` → **`feat/US-01.2-design`**.

⚠️ **Conséquence réelle, non théorique** : la contrainte permanente du projet impose le motif
`^feat/US-[0-9]+\.[0-9]+.*$` — **les deux noms le respectent**, donc ⛔ **aucune PR ne deviendra
infusionnable** de ce fait. Le coût est **documentaire** : un lecteur cherchant la branche annoncée
ne la trouvera pas. **Correctif attendu** : inscrire le nom réel, **daté**, ⛔ sans repeindre l'ancien.

### ⚠️ `Q-4` · non bloquant · **LOW** · le **point ②** renvoyé à l'humain n'a **pas de verdict daté** là où la DoD le cherche

* **Action effectuée** : la case DoD *« Les 2 points renvoyés à @ProductOwner + humain sont ARBITRÉS
  et DATÉS (§Contexte technique) »* — chercher les deux verdicts **dans le Story File**.
* **Résultat attendu** : deux verdicts datés.
* **Résultat obtenu** : le **point ①** *(l'étape non bornée du `.feature` d'US-01.1)* **est arbitré,
  daté et APPLIQUÉ** — vérifié dans le fichier : marqueur littéral **`PÉRIMÉ-2026-08-04`** sur la
  ligne, et l'étape porte désormais *« …non-interactives **au périmètre d'US-01.1** »*.
  Le **point ②** *(séquencement de la certification d'US-01.1)* ne porte **aucun verdict** :
  `grep -n "séquencement"` ne rend que l'**énoncé** du point et **deux renvois**.

⚖️ **La décision EXISTE ailleurs** *(le plan arrêté le 2026-08-03 diffère la certification d'US-01.1
après US-01.3)*, ⛔ **mais pas à l'endroit que la DoD désigne**. Même famille que la dette **NB-6** :
*le corpus ne modélise pas ce sur quoi une décision porte.*

### ⚠️ `Q-5` · non bloquant · **LOW** · `AC-10 N` parle de **persistance** et n'asserte que l'**écran**

* **Action effectuée** : sonde d'assertions *(§5 ③)* sur *« Les échéances et leur état sont restitués
  à l'identique après réouverture »*.
* **Résultat attendu**, la clause portant sur le stockage : au moins une assertion sur les octets.
* **Résultat obtenu** : **4 `expect`, aucune voie disque**.

⛔ **Ce n'est PAS un faux vert** : `ouvrirApplication` reconstruit un **dépôt et un notifier NEUFS
sur le même répertoire** ⇒ la restitution **traverse le fichier réel**, et `check_e2e_persistance.py`
le certifie *(« magasin » : 0 écart)*. L'observation est simplement **prise à l'écran** plutôt
qu'aux octets. **Correctif attendu** *(peu coûteux)* : ajouter `expect(persistees(), hasLength(3))`
et l'ordre attendu, pour que la clause soit réfutable **au niveau où elle est écrite**.

### Findings ANTÉRIEURS — ⛔ **je ne les re-instruis pas**

⚖️ **Report assumé au titre du GEL d'US-00.6** : `N-1`, `N-2`, `REV-NB-C`, `N-3`, `N-5` → `N-10`,
`REV-NB-H`, ainsi que les **4 nouveaux de chaque audit du 3ᵉ tour** *(`NB-M`, `NB-N`, `NB-O`, `NB-P`
côté revue)*. ⛔ **Aucun n'est devenu bloquant à l'exécution** : les 5 gates et les 8 contrôles
passent. **Un report n'est pas une levée.**

---

## 9. La DoD, case par case, **avec la preuve de chacune**

⚠️ **Fait établi, à ne pas re-découvrir** : *la DoD générique n'exige la couverture d'AUCUN AC* — ses
10 premières cases sont **intégralement cochables avec la moitié des AC orphelins**. **Je ne m'y suis
donc pas fié** : la couverture des 16 AC est mesurée **séparément** au §5 ④, et leur **force** au §6.

| # | Case | État **mesuré** | Preuve |
|---|---|---|---|
| 1 | Code livré sur sa branche dédiée | ✅ | `main` ancêtre de `HEAD`, **36** commits propres ⚠️ *(nom : `Q-3`)* |
| 2 | PR ouverte (pas de commit direct sur la principale) | 🟠 **PARTIEL** | `gh pr list` → **`[]`** ; mais `git rev-list --count HEAD..main` → **0** ⇒ **substance tenue** ➡️ `Q-2` |
| 3 | Tests unitaires conformes aux seuils | ✅ | **97,9 % ≥ 95,2** *(cliquet)* **et ≥ 80,0** *(plancher)*, gate `app.test` vert |
| 4 | Aucune régression sur les US précédentes | ✅ | **369 verts** ; **13 titres d'US-01.1 INCHANGÉS** *(`diff` main↔HEAD sur les `Scénario:` → vide)* ; mapping **13 ↔ 13** |
| 5 | `Audit Rev 🔍` validé | ✅ | `EVT_CODE_REVIEW_PASSED` 2026-08-17 · `code_review_delta2.md` |
| 6 | `Audit Sec 🛡️` validé | ✅ | `EVT_SECURITY_AUDIT_PASSED` 2026-08-17 · `security_delta2.md` |
| 7 | `QA Status 🧪 PASS` | ✅ | **le présent rapport** |
| 8 | PROJECT_LOG à jour | ✅ | dernière ligne **2026-08-17** *(double visa)* ⚠️ ma propre ligne reste due au commit |
| 9 | SCB à jour | 🟠 **EN COURS** | `parallel_audit`, `✅ 🔍 ✅ 🛡️`, **QA `⏳`** — **c'est mon verdict qui la change**, ⛔ pas moi qui édite le SCB |
| 10 | Story File archivé dans `docs/stories/` | ✅ | `docs/stories/US-01.2-gestion-echeances.md` |
| 11 | Chaque clause d'AC a sa ligne en §Traçabilité | ✅ | **48 clauses** : **44 couvertes**, **4 déclarées** *(`grep -c` → **4**)* |
| 12 | Bornes NM-1, NM-2, NM-4 → NM-7 vraies ou levées | ✅ | §7 — **aucune déguisée en test vert**, contrôle négatif exécuté |
| 13 | 10 points *clarify* + découpage arbitrés | ✅ | **seule case déjà cochée** — 2026-08-03, 11 arbitrages |
| 14 | `.feature` et Story File ne divergent pas | ✅ | `grep -c` → **50** · `uniq -d` → **vide** · mapping **50 ↔ 50**, exit 0 |
| 15 | **AC-16 et AC-17 couverts par des scénarios EXÉCUTÉS** | ✅ | **2 et 3 scénarios**, exécutés et nommés dans la sortie ; **`MQA7` et `MQA8` les font rougir** ⇒ ⛔ ni l'un ni l'autre n'a fini en borne déclarée |
| 16 | 3 règles sans AC couvertes par tests unitaires déclarés | ✅ | *version FUTURE* → groupe dédié `🔴 version FUTURE — état vide ET AUCUNE écriture, AUCUN rename` · *`id` en double* → `⛔ le doublon est CONSERVÉ, jamais supprimé` · *`schemaVersion`* → `document_store_test.dart` |
| 17 | Aucun élément de RF-06 ré-embarqué | ✅ | `grep -rniE "double.?tap|onDoubleTap|AnimatedOpacity"` sur `lib/` → **0 occurrence** *(les 4 lignes « retirée » trouvées parlent de clés JSON et de code mort, ⛔ pas du geste)* |
| 18 | Péremption du `🧪 PASS` d'US-01.1 transmise | ✅ | §Effet de bord présent et daté ; **13 titres inchangés** vérifiés |
| 19 | **Patron aller-retour d'ADR-005 EXÉCUTÉ et PORTANT SES MUTANTS** | ✅ | `migration_roundtrip_criterion.py` → **`VERDICT|OK|`, 8 assertions, exit 0** ; `echeance_schema_migrations_test.dart` porte **`MUTANT (a)` un `down` qui ne restaure pas** et **`MUTANT (b)` un `up` qui ne transforme rien** |
| 20 | Aucun `dart:io` / `path_provider` dans `lib/` hors `*_io.dart` | ✅ | Seul `document_store_io.dart` les importe, atteint par **import conditionnel** : `if (dart.library.io) 'document_store_io.dart'` |
| 21 | E2E montent la RACINE et traversent un magasin RÉEL | ✅ | `check_e2e_persistance.py` → **0 écart** sur les **2** contrôles · selftest **8/8** |
| 22 | Enregistrement illisible **octet pour octet** inchangé | ✅ | *« Un enregistrement illisible n'est ni réécrit ni supprimé »* — voie **`octets`** mesurée par ma sonde |
| 23 | Couverture **LUE** dans la sortie ; cliquet **jamais recopié** | ✅ | §3 — les deux valeurs **lues**, l'une dans le gate, l'autre dans `factory.config.json` |
| 24 | Borne **NM-8** encore vraie ou levée | ✅ | **encore vraie** : `main.dart` **absent de `lcov.info`** |
| 25 | Les 2 points renvoyés ARBITRÉS et DATÉS | 🟠 **1 / 2** | ① **oui** *(`PÉRIMÉ-2026-08-04` appliqué au `.feature`)* · ② **aucun verdict** ➡️ `Q-4` |

**Bilan : 22 satisfaites · 3 partielles (2, 9, 25) · 0 en échec.** ⚠️ **L'état des CASES du fichier
est 1/25** — c'est `Q-2`, et **c'est un défaut de tenue de dossier, ⛔ pas un défaut de produit**.

---

## 10. Edge cases réellement exercés — au-delà des cas passants

⛔ **Relevés dans les titres exécutés et dans mes mutants, jamais supposés** :

* **Les DEUX côtés de chaque borne** — `80` accepté / `81` refusé · `31 février` refusé / **`28 février`
  accepté** *(sans lui, un validateur refusant **tout** passerait)* · `9ᵉ` créée / `10ᵉ` refusée ·
  `T = 0` refusé / `T > 0` accepté.
* **Refus qui ne doivent RIEN écrire** : description vide, **uniquement des blancs**, sans date,
  date passée, édition vers le passé, édition d'une **échue** — assertions **sur les octets**.
* **Annulations** : annuler une édition, annuler une confirmation de suppression ⇒ **le fichier est
  inchangé**, ⛔ vérifié aux octets et non à l'écran.
* **Données hostiles venues du disque** : enregistrement **illisible**, stockage **entièrement**
  illisible, **description vide héritée** *(invariant I-3)*, document de **version FUTURE**,
  **`id` en double**, `schemaVersion` absent — et le résidu reste **octet pour octet** intact.
* **Migration** : aller-retour `v1 → up → v2 → down → v1`, **idempotence**, **interruption** laissant
  les octets inchangés, **clés inconnues** conservées, **version non supportée**.
* **Échec d'écriture réel** *(⛔ sans magasin factice — ADR-010 §1)* : création, **suppression**, puis
  **réessai qui aboutit sans ressaisie** — c'est cette dernière observation qui distingue *« saisie
  conservée »* d'un *« formulaire figé »*.
* **Le piège que le corpus signalait d'avance** : ⛔ **aucune date de calendrier en dur** — le
  31 février se **dérive de l'horloge injectée** et **ne devient jamais passé**, ⛔ et **aucune
  assertion sur la date de dérive** *(elle change les années bissextiles)*.

---

## 11. ⛔ CE QUE CE VERDICT N'ATTESTE PAS

* ⛔ **Je n'ai vu AUCUN écran.** Aucun appareil, aucun émulateur, aucun navigateur. Mon verdict porte
  sur des **sorties d'outils**, des **assertions** et **10 mutants**.
* ⛔ **`main()` n'a jamais été exécuté** *(borne **NM-8**, `main.dart` absent du `lcov`)* : que
  `runApp` démarre et que le hub se dresse **reste non observé**.
* ⛔ **L'application n'a JAMAIS tourné sur un appareil** — c'est l'objet d'**US-01.3**. Les bornes
  **NM-1** *(redémarrage réel)*, **NM-2** *(mode avion)*, **NM-4** *(mise à jour installée)*,
  **NM-6** *(lecteur d'écran)*, **NM-7** *(l'œil, la grande police)* **restent NON LEVÉES**.
* ⛔ **NM-10 ne se lèvera PAS avec US-01.3** *(qui vise iOS/Android)* : le comportement de
  l'application **web exécutée** — où **toute** écriture échoue par conception — reste hors d'atteinte.
  Le gate `build` **construit** et **n'exécute jamais**.
* ⛔ **NM-9** *(heure civile inexistante)* reste non observable : le fuseau du processus Dart est lu
  au démarrage et n'est **pas pilotable** depuis un test. ⚠️ **Et sa compensation déclarée est
  imprécise** — c'est `Q-1`.
* ⛔ **AUCUN SAST, AUCUN scan de CVE.** `run_gates --gate sast` → **exit 1, le gate n'existe pas** ;
  `dart pub outdated` mesure l'**obsolescence**, ⛔ pas la vulnérabilité. **Bornes CONNUES,
  réénoncées**, ⛔ pas des découvertes.
* ⛔ **Tout est mesuré sous Windows, un seul système de fichiers, UN seul fuseau** — le critère
  l'imprime : `offset_janvier=1:00:00 offset_juillet=2:00:00`. Les mécanismes d'échec du `rename`
  **diffèrent sous POSIX**, et c'est ce dont dépend la famille `B-2`/`NB-E`/`NB-G`.
* ⛔ **Ma campagne n'est pas exhaustive** : **10 mutants** sur un code qui en admet beaucoup plus. Un
  mutant que je n'ai pas imaginé **survivrait sans que ce rapport le sache**.
* ⛔ **97,9 % de couverture n'atteste pas la qualité des assertions** — ce projet l'a mesuré **6 fois**,
  la dernière au 3ᵉ tour *(`940/960` **avant et après** un bloquant HIGH)*. Et **`NB-N` montre pire** :
  la branche d'échec de `_tenterMiseDeCote` **n'a AUCUNE ligne instrumentée**. ⇒ **ce qui porte la
  preuve ici, c'est la mutation, ⛔ pas le pourcentage.**
* ⛔ **Je n'ai pas rejoué les campagnes des deux auditeurs** ni relu leurs verdicts pour les
  reprendre à mon compte : **trois grilles, trois verdicts indépendants**.
* ⛔ **Mon `🧪 PASS` n'est PAS `🚀 OUI`** *(Constitution Art. 5)* : la certification appartient au
  rituel `/certify` (@Architect). Il restera **`Déploiement ⏳`**, et le **gate 6 s'arrêtera** tant
  qu'aucun déploiement réel n'existe.
* ⛔ **Le verdict QA d'US-01.1 reste PÉRIMÉ** : ce rapport **ne le rafraîchit pas**.
* ⚠️ **Une leçon que j'applique à moi-même** : là où je n'ai **pas** trouvé — aucune instabilité de
  test observée sur mes **6** exécutions de la suite complète — j'écris **« non observé »**,
  ⛔ jamais « réfuté ». *Une sonde qui ne trouve pas ne prouve rien.*

---

## 12. 🔬 Défaut de MON PROPRE instrument — **v1 RETIRÉE**, et le mutant qui la tue est publié

⛔ **Ce projet compte le retrait d'un contrôle faux comme un acquis, pas comme un échec** *(la QA
d'US-00.5 a retiré son v1, son v2 **et** son v3)*. **Ma sonde v1 était FAUSSE et je l'ai retirée.**

* **Action effectuée** : mesurer les assertions des 50 tests avec ma sonde v1.
* **Résultat attendu** : le nombre d'`expect(` réellement écrits dans chaque test.
* **Résultat obtenu** : **`94 expect`** pour *« La page de gestion affiche le temps restant avec son
  unité »* — alors que **le fichier en porte 3**, vérifié en lisant le test.

**Cause racine, nommée** : v1 comptait les accolades **sur le source brut**. Un **apostrophe français
dans un commentaire** *(« la TUILE **n'**affiche que le nombre NU »)* y ouvrait une pseudo-chaîne qui
courait jusqu'à l'apostrophe suivant, **avalait les accolades** et **désynchronisait le découpage** :
les corps de tests **fusionnaient**. ⇒ **v1 gonflait les mesures et aurait rendu le §5 faussement
rassurant.**

**v2 tokenise en UN SEUL passage** *(chaînes simples, triples, brutes, échappements, `//`, `/* */`)*
et **porte le mutant qui tue v1** :

```
$ python sonde_assertions_e2e_v2.py --selftest
[OK ] M0_conforme                                attendu={...} obtenu={...}
[OK ] M1_un_test_perd_toute_assertion            ...
[OK ] M2_voie_disque_reduite_a_un_COMMENTAIRE    ...
[OK ] M3_titre_renomme_NE_CHANGE_RIEN            ...      <-- CONTROLE NEGATIF
[OK ] M4_troisieme_test_ajoute                   ...
[OK ] M5_apostrophe_dans_un_commentaire_TUE_v1   ...      <-- LE mutant discriminant
[OK ] M6_double_slash_dans_une_chaine            ...
[OK ] M7_accolades_dans_une_chaine               ...
AUTOTEST OK -- 8/8

$ (preuve que M5 discrimine bien les deux versions)
  v1 -> [('Un titre ordinaire', 4), ('Un titre qui ne regarde que la tuile', 2)]
  v2 -> [('Un titre ordinaire', 2), ('Un titre qui ne regarde que la tuile', 2)]
  attendu : 2 tests a 2 expect chacun          <-- v1 FAUSSE, v2 JUSTE
```

⛔ **Les mutants sont écrits dans un vocabulaire ÉTRANGER à la règle testée** *(« Réglages »,
« bleu », « tuile »)* — sinon l'autotest ne mesurerait que lui-même.

🎓 **Et un second défaut du même instrument, de la classe que ce dépôt a déjà payée** : mes scripts
ont **planté deux fois sur `cp1252`** *(console Windows)* en imprimant `⛔` puis un nom de test
portant `🔴`. **Même bug que celui qui a fait tomber un contrôle en US-00.6.** Corrigé par
translittération explicite des sorties. ➡️ **À verser à `/audit-methodo`** : *sur ce poste, tout
script de contrôle doit translittérer ce qu'il imprime — la règle n'est écrite nulle part et elle a
maintenant frappé trois fois.*

---

## 13. Isolation et propreté — **relevé, pas affirmé**

```
$ git rev-parse HEAD                      # arbre PRINCIPAL
ef87d8fd7d3a25316ced6658f466658224e1dc1a
$ git rev-parse HEAD                      # worktree QA (detache, VIERGE au depart)
ef87d8fd7d3a25316ced6658f466658224e1dc1a

$ git status --porcelain                  # arbre PRINCIPAL, avant ce rapport
(fin)                                     <-- VIDE
$ git status --porcelain                  # worktree QA, APRES les 10 mutants
(fin)                                     <-- VIDE
```

* **Toutes** mes exécutions *(pub get, 6 suites complètes, 8 exécutions e2e, 5 gates, 8 contrôles,
  10 mutants)* ont eu lieu dans le **worktree détaché**, créé **sans `.dart_tool` ni `build`** ⇒ ce
  qui y est mesuré est ce qu'obtiendrait **un dépôt frais**.
* Après **chaque** mutant : `git checkout -- <fichier>` puis `git status --porcelain` **relevé et
  vide** *(imprimé dans la sortie de campagne, ligne `restaure -> git status : ''`)*.
* ⛔ **Aucun fichier de l'arbre principal n'a été modifié** hors **ce rapport** et **la ligne de
  trace**. ⛔ Ni `STORY_CERTIFICATION_BOARD.md`, ni `PROJECT_LOG.md`, ni `factory.config.json`.
* ⛔ **Aucun commit.**

---

## 14. Ce qui reste dû à d'autres rôles — ⛔ je ne le tranche pas

* **`Q-1` → @ProductOwner** *(borner la phrase de NM-9)* · **`Q-3`, `Q-4` → @Architect** *(nom de
  branche daté ; verdict du point ②)* · **`Q-5` → @Developer** *(une assertion sur les octets dans
  `AC-10 N`)* · **`Q-2` → @Architect + `/audit-methodo`**.
* La **hausse du cliquet** est **signalée par le gate** et **ne m'appartient pas** : `factory.config.json`
  est **protégé**, ⛔ aucun agent ne l'édite. **Le cliquet RESTE à 95,2** *(arbitrage du 2026-08-07)*.
* **`NB-6` appliqué à mon propre visa** : il porte sur **`28d9504`** *(code)* et **`ef87d8f`** *(HEAD)*.
  ⛔ **`trace_append.py` n'a aucune option `--commit`** ⇒ les deux SHA vivent dans le `--rationale`,
  **convention NON enforcée** qui réduit le risque sans le supprimer.
* **Trois candidats `/audit-methodo`** issus de cette passe : **`Q-2`** *(une DoD non tenue ne
  déclenche rien)* · **`Q-1`/`Q-4`** *(le corpus ne modélise pas ce sur quoi une affirmation porte —
  même famille que `NB-6` et `NB-O`)* · **la translittération `cp1252`**, qui a frappé **trois fois**.

---

# Annexes

## Annexe A — commandes exécutées, dans l'ordre

```
git diff --name-only 28d9504..HEAD -- lib test scripts pubspec.yaml pubspec.lock   -> 0 fichier
flutter pub get                                                                    -> exit 0
flutter test                                                                       -> +369, exit 0
flutter test --reporter json        (decompte machine)                             -> 369/0/0
python scripts/run_gates.py --all                                                  -> 5 gates, exit 0
python scripts/check_flutter_coverage.py --min 80                                  -> 97.9% (941/961)
python scripts/check_gherkin_mapping.py            [+ --selftest]                  -> exit 0 / exit 0
python scripts/check_e2e_persistance.py            [+ --selftest]                  -> exit 0 / exit 0
python reports/US-01.2/migration_roundtrip_criterion.py                            -> VERDICT|OK|, exit 0
python scripts/validate_trace.py --us US-01.2                                      -> exit 0
python scripts/check_scb_compliance.py                                             -> exit 0
python scripts/factory_sync.py --check                                             -> exit 0
grep -c "^  Scénario: " tests/features/US-01.2-gestion-echeances.feature           -> 50
grep    "^  Scénario: " ... | sort | uniq -d                                       -> VIDE
sonde_assertions_e2e_v2.py --selftest              [+ sur le fichier e2e]          -> 8/8 ; 50 tests
couverture_ac.py --selftest                        [+ feature x e2e]               -> 5/5 ; 16/16 AC
campagne_mutants_e2e.py           (7 mutants, cible e2e)                           -> 5 tues, 2 survivants
campagne_ac16_v2.py               (2 mutants + controle, suite complete)           -> 3 tues, 0 survivant
gh pr list --head feat/US-01.2-design --state all                                  -> []
```

## Annexe B — sonde d'assertions **v2** *(⛔ v1 retirée, §12)*

> ⚖️ **Publiée comme SCRIPT EXÉCUTABLE, ⛔ jamais recopiée à la main** *(leçon US-00.7)*. Elle vit
> dans mon espace de travail et **sa source intégrale est ici** : la sauvegarder et la lancer suffit
> à rejouer la mesure. ⛔ **Je n'ai pas créé de fichier hors `reports/US-01.2/qa.md`** dans l'arbre
> principal, conformément au périmètre qui m'a été fixé.

Principe : **un seul passage de tokenisation** connaissant **ensemble** les chaînes (`'`, `"`,
`'''`, `"""`, brutes `r'…'`, échappements) **et** les commentaires (`//`, `/* */`) ; puis, par test,
comptage des `expect(` **dans le code seul** et détection des voies disque
`persistees( · octets( · octetsBruts( · existeFichier( · harnais.chemin`.
**Autotest de mutation `--selftest` : 8 sources, 8/8**, dont le **contrôle négatif `M3`** *(renommer
un titre ne doit RIEN changer)* et le **discriminant `M5`** *(apostrophe français en commentaire —
il **tue v1** et **passe sur v2**)*.

## Annexe C — instrument de couverture des AC

Principe : lecture des en-têtes `# AC-N —` du `.feature` pour grouper les `Scénario:`, lecture des
titres de `testWidgets(` du fichier e2e, puis **croisement en ENSEMBLES** — ⛔ jamais en cardinaux.
Rend, par AC : *déclarés / retrouvés / manquants*, plus **les titres de test n'appartenant à aucun
groupe d'AC**. **Autotest de mutation : 5 sources, 5/5** — *un test manquant*, *un AC devenu
orphelin*, *un test hors de tout AC*, *un titre renommé* **(qui doit produire LES DEUX symptômes)**.

## Annexe D — campagne de mutation, sortie brute

```
=== BASE (arbre propre) ===
  e2e : 50 passes, 0 en echec  []

MQA1_AC2_borne_80_devient_81            -> 49 passes,  1 rouge  -> TUE
MQA2_AC3_heure_defaut_23_devient_22     -> 48 passes,  2 rouges -> TUE
MQA3_AC5_limite_9_devient_10            -> 48 passes,  2 rouges -> TUE
MQA4_AC4_futur_strict_devient_LARGE     -> 49 passes,  1 rouge  -> TUE
MQA5_AC16_barriere_V1_NEUTRALISEE       -> 50 passes,  0 rouge  -> SURVIVANT (e2e)
MQA6_AC16_garde_CALENDRIER_retiree      -> 50 passes,  0 rouge  -> SURVIVANT (e2e)
MQA7_AC17_echec_ecriture_NON_ANNONCE    -> 47 passes,  3 rouges -> TUE
  TUES = 5 / 7    git status final : ''

--- les 2 survivants, rejoues sur la SUITE COMPLETE (369 tests) ---
MQA5  -> 360 passes,  9 rouges -> TUE   (date_civile_test, codec_test, migrations_test)
MQA6  -> 367 passes,  2 rouges -> TUE   (validation_echeance_test : 31 fevrier / 28 fevrier ; EDITION R-10)
MQA8  -> 354 passes, 15 rouges -> TUE   (CONTROLE : les DEUX gardes retirees)
        ...dont, cette fois, DANS L'E2E :
          - Une date qui n'existe pas au calendrier est refusee sans correction silencieuse
          - Une edition vers une date qui n'existe pas au calendrier est refusee
git status final : ''
```

---

**Verdict : 🧪 PASS** — **369 passed · 0 failed · 0 skipped** · couverture **97,9 % (941/961)** ·
**16/16 AC actifs couverts, 0 orphelin** · **0 finding bloquant**, **5 non bloquants**.
⛔ **`🧪 PASS` n'est pas `🚀 OUI`** : la certification appartient au rituel `/certify` (@Architect).
