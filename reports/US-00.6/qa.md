# US-00.6 — Rapport QA · @QA_Tester (contexte frais)

| Champ | Valeur |
|---|---|
| **US** | US-00.6 — Couverture initiale mesurée + cliquet (*ratchet*) réellement actif |
| **Verdict** | 🧪 **FAILED** |
| **Date** | 2026-07-31 |
| **Agent · modèle** | @QA_Tester · `claude-opus-5[1m]` (contexte frais) |
| **Commit audité** | `3c56218` · branche `feat/US-00.6-couverture-ratchet` · parti de `main` = `309202a` |
| **Dépôt à l'issue de la QA** | `git status --porcelain` → **vide**. `git rev-parse --short HEAD` → `3c56218`. **Rien n'a été modifié** : toutes mes mutations ont eu lieu hors du dépôt |
| **Pré-conditions** | `python scripts/validate_trace.py --us US-00.6` → **exit 0** · `EVT_CODE_REVIEW_PASSED` ✅ *(21:41:45)* · `EVT_SECURITY_AUDIT_PASSED` ✅ *(21:05:06)* |

> ⚠️ **Tous les codes de sortie de ce rapport sont mesurés HORS DE TOUT PIPE** (`cmd > fichier 2>&1` puis
> `$?`). C'est la faute d'instrumentation que cette US a commise **deux fois** ; je ne la rejoue pas.

---

## 1. Verdict en une phrase

**Le mécanisme est SAIN, prouvé, et fait exactement ce qu'il annonce — je le certifie par 12 mutants de
configuration, 10 mutants de code et 6 fixtures. Mais l'US échoue sur son AC-6 :** le critère de clôture
d'EPIC_00, qui est sa **raison d'être déclarée**, n'est **pas coché** *(et son propre EPIC dit encore que
l'US est « à créer »)*, et **7 compteurs écrits à la main sont faux et non marqués** dans le corpus — dont
**3 dans le SCB** et **1 dans l'entrée `BACKLOG.md` que l'audit de revue avait érigée en condition de
clôture**. Or **AC-6 « Erreur » qualifie ce silence de « défaut BLOQUANT »**, et le **critère de test nº 17
exige « 0 non nommé »**. Je n'ai pas le pouvoir d'assouplir un AC.

⛔ **Ce FAIL ne porte PAS sur le cliquet.** Le cliquet est le meilleur livrable technique que j'aie mesuré
sur cette factory. Il porte sur la **cohérence du corpus**, qui est l'AC nº 6 de cette US.

---

## 2. Décomptes exacts

### 2.1 Tests réellement exécutés

| Suite | passed | skipped | failed | Commande, exit |
|---|---|---|---|---|
| **Tests Dart** *(`flutter test`)* | **2** | **0** | **0** | via `run_gates --gate test` → **exit 0** |
| **Gates de l'adapter** | **5** *(format, analyze, test, deps_audit, build)* | **0** | **0** | `run_gates --all` → **exit 0** |
| **Fixtures du cliquet** *(le MUTANT, tourne en CI requise)* | **6 attentes tenues** dont **4 REFUS** | **0** | **0** | `selftest_coverage_ratchet.py` → **exit 0** |
| **Mes mutants de configuration** | **12 cas dégradés, 12 comportements corrects** | 0 | 0 | 12 exécutions de `check_flutter_coverage.py` |
| **Mes mutants de code** | **10 posés → 6 VUS, 4 survivants** *(1 équivalent, 3 angles morts réels)* | 0 | 0 | 10 exécutions de l'autotest sur copie mutée |
| **Scénarios Gherkin** | ⛔ **0 exécuté** — **18 documentaires** | — | — | **ni runner ni step definitions** (§2.4) |

⚠️ **Aucun test réel n'a été cassé pour produire une preuve** : `git diff 309202a..HEAD -- lib/ test/` →
**vide**. La borne d'US-00.7 (« *on ne cassera pas un gate pour l'obtenir* ») est tenue.

### 2.2 Couverture

| Grandeur | Valeur mesurée |
|---|---|
| Couverture de lignes | **89,4737 %** — **affichée `89.5%`** |
| **Dénominateur explicite** | **17 / 19** *(imprimé par le contrôle à chaque exécution, succès inclus)* |
| Seuil appliqué | **89.4 % (cliquet)** — et le message le **nomme** |
| Plancher contractuel | **80.0 %** *(dormant : c'est le cliquet qui borde)* |
| Fichiers dans la mesure | **1** — `lib/main.dart` |
| Lignes non couvertes | **2**, nommées : `lib/main.dart:9` *(`void main()`)* et `:10` *(`runApp(...)`)* |
| Couverture de branches | ⛔ **AUCUNE** — le rapport ne porte **ni `BRF:` ni `BRDA:`** |
| Granularité | **1 ligne = 5,26 pt.** Aucune valeur n'existe entre **89,47 %** et **94,74 %** |

⛔ **Ce chiffre n'a aucune valeur statistique** : 19 lignes, un fichier, un compteur de démonstration,
zéro fonctionnalité métier. Je l'écris parce que l'AC l'exige et parce que c'est vrai.

### 2.3 Les 19 critères de test — **17 passés / 2 échoués**

Chacun est une commande ; chacune a été exécutée.

| # | Contrôle | Attendu | Obtenu | Verdict |
|---|---|---|---|---|
| 1 | `run_gates --gate test` | exit 0 + dénominateur | exit **0**, `89.5% (17/19)` | ✅ |
| 2 | Mesure archivée : commande verbatim + dénominateur + lignes nommées | 3/3 | 3/3 dans `mesure_initiale.txt` | ✅ |
| 3 | `app.coverage_ratchet` | objet `{value,date,motif}` | `{89.4, "2026-07-31", "…"}` | ✅ |
| 4 | 🔬 Mutant de la référence | le verdict CHANGE | `95` → **exit 1** · `89.4` remis → **exit 0** *(bidirectionnel)* | ✅ |
| **5** | `grep` d'un seuil **en dur** dans les artefacts **exécutés** | **rc=1** | **rc=0** — 3 occurrences | ❌ **ÉCHEC** |
| 6 | `git diff` `factory_sync.py` hors hunk T8 · `docs/adr/**` | 0 ligne | `factory_sync.py` = **+32/−0** *(le hunk T8 seul)* · ADR + Constitution = **0 ligne** | ✅ |
| 7 | 🔬 Fixture **16/19** | 🔴 ROUGE | **exit 1** — *« RÉGRESSION 84.21 % < 89.4 % (cliquet) »* | ✅ |
| 8 | 🔬 Fixture **17/19** | ✅ VERT | **exit 0** — aucun rouge sur dépôt inchangé | ✅ |
| 9 | 🔬 Fixture **18/19** | VERT + valeur à consigner | **exit 0** + `[HAUSSE] 94.74% (18/19) … Valeur a consigner : 94.7` | ✅ |
| 10 | 🔬 Fixture **0 ligne** | 🔴 ROUGE explicite | **exit 1** — *« ce n'est pas une mesure. Refuse. »* | ✅ |
| 11 | Clé retirée | plancher seul, exit 0 | **exit 0**, *« cliquet NON CONFIGURÉ (clé … absente) »* | ✅ |
| 12 | Clé mal formée | échec explicite | **4 formes testées → exit 1 explicite ×4** | ✅ |
| 13 | Référence < plancher | échec explicite | **exit 1** — *« configuration INCOHÉRENTE : cliquet 70.0 % < plancher 80.0 % »* | ✅ |
| 14 | Le message nomme **lequel** des deux | jamais « seuil » | **les 2 branches exercées** : `(cliquet)` et `(plancher contractuel)` | ✅ |
| 15 | Autotest **en CI**, job **requis** | présent | step `🔒 Autotest du cliquet (US-00.6)` dans le job `governance` = **contexte requis** | ✅ |
| 16 | `factory_sync --check` après T8 | exit 0 + valide le cliquet `app` | **exit 0** ; **5 mutations de config détectées sur 11** | ✅ |
| **17** | Énoncés rendus faux | **0 non nommé** | **7 non nommés** | ❌ **ÉCHEC** |
| 18 | Non-régression `--all` · SCB · trace · gitleaks | exit 0 | **4 × exit 0** *(gitleaks 8.30.1, 2 modes)* | ✅ |
| 19 | Runner BDD / step definitions | ABSENT | **absent** — 0 occurrence gherkin/cucumber/behave, `tests/features/**` **lu par rien en CI** | ✅ |

### 2.4 Scénarios Gherkin — **comptés à part, jamais comme verts**

`tests/features/US-00.6-couverture-ratchet.feature` porte **18 scénarios** *(comptés :
`grep -c "Scenario"` → **18**)*. **`0` est exécuté** — vérifié : `tests/steps`, `features/steps`,
`tests/step_definitions` **absents** ; `grep -rn "gherkin\|cucumber\|behave"` sur `pubspec.yaml` et les
workflows → **rc=1** ; `grep -rln "tests/features" .github/workflows/` → **rc=1**.

⇒ **18 documentaires, 0 passed, 0 skipped, 0 failed. Leur nombre ne mesure aucune couverture.**
⛔ **Ne pas les confondre avec les 6 fixtures**, qui **s'exécutent réellement** dans un job **requis**.

### 2.5 DoD — **0 / 20 cochée**

`grep -c '^- \[x\]'` → **0** · `grep -c '^- \[ \]'` → **20**.

⇒ **Aucune case n'est cochée à tort** *(la question posée)* — mais **aucune n'est cochée du tout**, y
compris celles que mes exécutions établissent. Répartition réelle :

| État | Cases | Fondement |
|---|---|---|
| **Substantiellement TENUES, non cochées** | **1, 3, 4, 5→non, 6, 7, 8→réserve, 9, 10, 12, 15, 16** | mes exécutions §2.3 |
| **TENUE grâce à ce rapport** | **2** *(question expérimentale)* | tranchée par expérience §5 — les deux auditeurs ne pouvaient pas |
| **NON tenue** | **5** *(seuil en dur — critère 5)* · **8** *(réserve : le README ne documente que 4 des 6 fixtures)* · **11** *(condition de clôture tenue, mais §3 F-2 la pollue)* · **17** *(ce rapport = FAILED)* · **20** *(rien n'est fait)* | §3 |
| **Hors de portée à cette date** | **13** *(PR)* · **14** *(fusion humaine)* · **18, 19** *(fin de cycle)* | légitime |

⚠️ La DoD annonce « *toutes les cases doivent être cochées avant de passer la phase
`quality_assurance`* » alors que son propre tableau de périmètre place les cases 15→20 en « fin de
cycle ». **Le texte se contredit lui-même** — défaut de gabarit, préexistant, **non imputé à cette US**.

---

## 3. Les échecs — « Action effectuée → Résultat attendu → Résultat obtenu »

### ❌ B-QA-1 · Critère 17 · AC-6 « Erreur » — **7 énoncés rendus faux, non nommés**
### *(la 13ᵉ manifestation demandée — et il y en a sept d'un coup)*

**Action effectuée** — j'ai dérivé la vérité des sources exécutables *(`len(CAS)` du selftest, décompte
réel des `*.info`, décompte des cas à exit 1)*, puis confronté **chaque compteur écrit à la main** dans le
périmètre US-00.6 du corpus. Sortie brute :

```
[DERIVE DES SOURCES] {'fixtures': 6, 'attentes': 6, 'refus': 4}
  VIOLATION tests/fixtures/US-00.6/README.md:41      -> ecrit '4 fixtures', derive = 6
  VIOLATION scripts/selftest_coverage_ratchet.py:18  -> ecrit '4 attentes', derive = 6
  VIOLATION .github/workflows/ci.yml:115             -> ecrit '4 fixtures', derive = 6
  VIOLATION BACKLOG.md:24                            -> ecrit '5 fixtures', derive = 6
  VIOLATION STORY_CERTIFICATION_BOARD.md:592         -> ecrit '4 fixtures', derive = 6
  VIOLATION STORY_CERTIFICATION_BOARD.md:593         -> ecrit '2 REFUS',    derive = 4
  VIOLATION STORY_CERTIFICATION_BOARD.md:593         -> ecrit '4 attentes', derive = 6
[BILAN] 7 compteur(s) US-00.6 ecrit(s) a la main en desaccord avec la source   → exit 1
```

**Résultat attendu** *(critère 17)* — **0 non nommé**.
**Résultat obtenu** — **7**, aucun ne portant de marqueur.

**Ce qui rend ce constat grave, et ce n'est pas le nombre :**

1. 🔴 **Les cinq premiers sont nés dans le commit `3c56218` LUI-MÊME** — celui qui ajoute la 6ᵉ fixture.
   Son propre message de commit écrit correctement « *l'autotest rend desormais **6 attentes tenues dont
   4 REFUS*** », et le PROJECT_LOG est juste. **Le nombre vivait en six endroits ; un seul a été
   rafraîchi.** C'est la définition exacte de la classe que `CLAUDE.md` nomme « **la dette la plus active
   du projet** » — *« une assertion chiffrée écrite à la main à côté d'une commande, jamais relue dans sa
   sortie »*. **Douze manifestations en trois jours ; voici les treizième à dix-neuvième**, et elles sont
   apparues **dans le commit qui corrigeait la douzième**.
2. 🔴 **Trois sont dans le SCB** — l'artefact que `/certify` lit et qu'un auditeur à contexte frais prend
   pour référence. Le SCB dit « **4 fixtures**, **2 REFUS sur 4 attentes** » : un relecteur en conclut que
   `totaux_incoherents.info` et `lf_menteur.info` **n'existent pas**, donc que les findings **B-1** et
   **RA-2** sont **encore ouverts**. ⇒ **Le corpus affirme qu'une chose manque alors qu'elle est acquise**
   — mot pour mot la classe que `CLAUDE.md` dit qu'« **US-00.7 a payée CINQ fois** ».
3. 🔴 **`BACKLOG.md:24` est l'entrée que l'audit de revue a érigée en CONDITION DE CLÔTURE**, précisément
   pour être le filet durable et `grep`-vérifiable. Le filet tient sur le fond *(§4)* — mais il porte,
   dans la même phrase, un compteur faux.
4. **Deux sont dans des artefacts EXÉCUTÉS** *(`selftest_coverage_ratchet.py:18`, `ci.yml:115`)*, dont un
   qui tourne dans un **job requis**.
5. **Le SCB porte en outre deux états périmés non comptés par mon instrument** *(il ne sait lire que des
   compteurs)* : « **⏳ DEUX ÉDITIONS HUMAINES, seules actions restantes** » alors qu'elles sont
   **APPLIQUÉES** depuis `f585e82` *(`factory.config.json` +6, `factory_sync.py` +32)*, et « fail-explicit
   sur les **4** cas dégradés » alors que j'en ai exercé **12**.

### ❌ B-QA-2 · Critère 5 · AC-2 « Nominal » — **le seuil est en dur dans un artefact exécuté**, et j'en mesure la conséquence

**Action effectuée** — `grep -rn` du seuil dans les artefacts **exécutés**
*(`scripts/*.py`, `.github/workflows/*.yml`, `.claude/hooks/*`, `factory.config.json`)*.
**Résultat attendu** *(critère 5)* — **rc=1**.
**Résultat obtenu** — **rc=0** :

```
scripts/selftest_coverage_ratchet.py:39 : REF_MUTANT = 89.4      <-- artefact EXECUTE en CI requise
factory.config.json:82                  : "value": 89.4
factory.config.json:98                  : "…check_flutter_coverage.py --min 80"   <-- toujours en dur
factory.config.json:80                  : "coverage_min": 80
```

⚠️ **Ce n'est pas un pinaillage : j'en ai mesuré l'effet.** Mon mutant **M-F** — *le cliquet écrit **en
dur** à `89.4` dans le contrôle, au lieu d'être lu dans la configuration* — **SURVIT à l'autotest** :

```
M-F    exit=0     SURVIVANT    cliquet ECRIT EN DUR (89.4) au lieu d etre LU dans la config
```

Il survit **parce que** `REF_MUTANT` vaut la même valeur que le projet. ⇒ **le jour où un développeur
figerait le seuil dans le contrôle, la CI resterait verte** : c'est exactement le défaut qu'AC-2 existe
pour interdire, et il est **causé** par la duplication que le critère 5 devait empêcher. *(La propriété
elle-même est **vraie dans le code livré** — je l'ai prouvée par mutation de configuration, critère 4.
C'est l'**autotest** qui ne la protège pas.)*

Et le §7 du Story File affirme, **sans marqueur** : « *Occurrences du seuil dans les artefacts exécutés :
**2 → 1** (la commande de gate cesse de porter le nombre en dur)* ». **Mesuré : c'est faux.** La commande
porte **toujours** `--min 80`, `coverage_min: 80` est **toujours** là, et `89.4` est **désormais**
dupliqué ⇒ **2 → 3**. La divergence que §3 redoutait n'est pas fermée — **prouvé** :

```
IGNORE | coverage_min releve a 85, gate toujours --min 80 (DIVERGENCE)   <-- factory_sync --check reste VERT
IGNORE | gate porte --min 95 alors que coverage_min=80 (DIVERGENCE)      <-- idem
```

### ❌ B-QA-3 · AC-6 « Nominal » (i) · T10 · DoD 20 — **le critère de clôture d'EPIC_00 n'est PAS coché**

**Action effectuée** — `git diff --stat 309202a..HEAD` puis lecture de `docs/epics/EPIC_00-fondations.md`.
**Résultat attendu** — le critère « Seuils de couverture mesurés et ratchet actif » **coché avec sa preuve
et ses bornes** ; risque nº 3 « Ratchet inopérant » **statué**.
**Résultat obtenu** — **`docs/epics/EPIC_00-fondations.md` n'apparaît PAS dans le diff de la branche**
*(dernière modification : `373f7ae`, US-00.5)*. État réel, ligne par ligne :

```
l.113 : - [ ] Seuils de couverture mesurés et ratchet actif                 <-- NON COCHE
l.85  : | US-00.6 … | _(à créer via `/us-new`)_ | ⏳ à venir |               <-- FAUX : le Story File existe
l.95  : | 3 | … | Ratchet inopérant. | Mesure réelle sur le squelette (US-00.6). |   <-- NON STATUE
```

⚠️ **C'est la raison d'être déclarée de l'US** *(« la DERNIÈRE US requise pour clore EPIC_00 »)*, et son
EPIC dit encore que l'US **reste à créer**. Le §7 revendique un critère « rendu **cochable** » : c'est
vrai — et il n'est **pas coché**.

---

## 4. Ce que je valide sans réserve — et les deux points qu'on m'a demandé d'attaquer

### ✅ Le mécanisme fait ce qu'il annonce — 12 mutants de configuration, **12 comportements corrects**

| Mutation | exit | Message obtenu |
|---|---|---|
| cliquet `95` *(au-dessus de la mesure)* | **1** | `RÉGRESSION : 89.47% < 95.0% (cliquet)` — écart et **~lignes** donnés |
| cliquet `89.5` *(le piège d'arrondi)* | **1** | `écart 0.03 pt` ⇒ **`89.4` est bien la SEULE valeur juste** : consigner l'affiché **verrouillait le dépôt** |
| cliquet `89.4` **remis** | **0** | verdict **revenu** ⇒ la valeur est **réellement lue** *(bidirectionnel)* |
| clé **absente** | **0** | `cliquet NON CONFIGURÉ (clé adapter.components.app.coverage_ratchet absente)` — plancher seul |
| clé = **chaîne** / **liste** | **1** / **1** | `MAL FORMÉ : … doit être un objet {value, date, motif}, reçu str` / `list` |
| **sans `value`** / `value` **texte** / `value` **null** | **1** ×3 | champ nommé, valeur citée |
| cliquet `70` **< plancher 80** | **1** | `configuration INCOHÉRENTE` — ⛔ jamais « le plus strict gagne » |
| `factory.config.json` **introuvable** | **0** | `cliquet IGNORÉ` *(borne §6)* |
| `lcov` **introuvable** | **1** | nomme la commande à lancer |

⛔ **Zéro plantage, zéro vert silencieux, zéro traceback** sur les 12. La doctrine « fail-explicit » tient.

### ✅ Mes 10 mutants de code — **6 VUS**, et les 4 survivants sont qualifiés

| Mutant | Ce qu'il casse | Autotest |
|---|---|---|
| **M-A** | neutralise la comparaison de régression | 🔴 **VU** |
| **M-B** | `max(plancher, cliquet)` → `min(…)` *(le plus lâche gagne)* | 🔴 **VU** |
| **M-C** | supprime le refus des totaux contradictoires *(correctif **B-1**)* | 🔴 **VU** ×2 |
| **M-E** | le cliquet n'est **jamais lu** | 🔴 **VU** |
| **M-G** | supprime la branche **`LF:`** *(le dénominateur)* | 🔴 **VU** |
| **M-H** | supprime la branche **`LH:`** | 🔴 **VU** |
| **M-D** | supprime la garde « 0 ligne mesurable » | 🟠 survivant — le cas **refuse quand même**, mais pour le **mauvais motif** *(`0 % < 89.4 %`)*. Le **code** est juste *(message vérifié : « ce n'est pas une mesure »)* ; c'est l'**autotest** qui ne discrimine pas |
| **M-F** | cliquet **en dur** | 🔴 **survivant → B-QA-2** |
| **M-I** | supprime le message de **HAUSSE** | 🟠 survivant — l'autotest n'assertionne que des codes de sortie. **Conséquence réelle** : le cliquet **ne monte jamais seul**, et cette ligne est le **seul** signal envoyé à l'humain ; sa disparition serait **invisible** — et c'est **le chemin exact où vivait le bug d'encodage** |
| **M-J** | `pct` depuis les totaux **déclarés** | ⚪ **équivalent** — la garde B-1 impose `déclaré == compté`, donc les deux formules coïncident. **C'est une bonne nouvelle** : elle montre que le correctif B-1 est **porteur** |

✅ **M-G et M-H VUS dans les deux sens** ⇒ le correctif **RA-2** *(6ᵉ fixture)* n'est pas décoratif :
les **deux** branches du recoupement sont désormais **exercées**.

### ✅ Le bug d'encodage — **le correctif tient, y compris sans `PYTHONIOENCODING`**

| Condition | exit |
|---|---|
| `selftest`, `PYTHONIOENCODING` **retirée** + `PYTHONLEGACYWINDOWSSTDIO=1` | **0** |
| `selftest`, `-X utf8=0` | **0** |
| chemin **HAUSSE** avec `ascii` / `cp1252` / `cp437` / `utf-8` | **0 / 0 / 0 / 0** |
| chemin **HAUSSE**, variable **retirée** | **0** |

⚠️ **Mais l'affirmation « les messages sont désormais en ASCII » est FAUSSE** — mesurée par AST sur les
seuls arguments de `print` : **9 caractères non-ASCII** dans `check_flutter_coverage.py`
*(U+2014 aux l. 186, 204, 225, 234 ; `É`/`é` aux l. 224, 225, 240, 241)* et **3** dans le selftest
*(l. 73, 122, 126)*. **C'est la garde `reconfigure(errors="replace")` qui sauve, pas la propreté ASCII
annoncée.** Déjà relevé par l'audit de revue comme non bloquant ; **je le confirme par exécution** et je
le laisse non bloquant **parce que la garde est mesurée efficace** — mais l'énoncé du script est faux.

### ✅ La condition de clôture posée par le @CodeReviewer — **TENUE**, et `grep`-vérifiable

`grep -c "n'est PAS en vigueur"` → **`CLAUDE.md:1`** et **`BACKLOG.md:1`**. Les **trois** clauses fausses
de l'Art. 4 sont **citées littéralement**, la **quatrième** est identifiée comme **vraie** *(32 lignes
ajoutées à `factory_sync.py` — vérifié : `+32/−0`)*, le traitement est arbitré et le motif de l'ordre des
PR est écrit. **Le filet durable existe.** ✅ Et `docs/adr/**` + `CONSTITUTION.md` → **0 ligne modifiée** :
aucun texte immuable n'a été repeint.

### ✅ L'ordre des PR — **je le juge ACCEPTABLE**, et pour le motif donné

Amender l'Art. 4 **avant** que le code d'US-00.6 soit sur `main` ferait affirmer au texte normatif que le
cliquet **est en vigueur** alors qu'il ne l'est **pas encore** — c'est **la même faute en sens inverse**,
et c'est celle qu'US-00.5 a payée. La séquence `#20 (code) → PR dédiée (Art. 4) → certification` est la
seule honnête. La condition qui la rend sûre *(dette nommée dans le corpus durable)* est **tenue**.
⚠️ **Borne** : rien de **machine** ne garantit que la PR dédiée soit ouverte. Le filet est **documentaire**
— je le dis, je ne le maquille pas.

---

## 5. 🔬 La question expérimentale d'AC-1 « Limite » — **TRANCHÉE, par exécution**

Les deux auditeurs l'ont laissée ouverte *(NB-9, puis RA-7 : « **je ne peux pas la trancher** : elle exige
d'écrire dans `lib/` »)*. **Je la tranche sans écrire dans `lib/`** : j'ai reconstitué le projet **hors du
dépôt** *(`pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `lib/`, `test/` copiés en bac à sable)*,
j'y ai ajouté `lib/orphelin_qa.dart` — **13 lignes exécutables qu'aucun test n'importe** — et lancé
`flutter test --coverage`.

**Question** : un fichier Dart qu'aucun test n'importe entre-t-il au dénominateur ?

**RÉPONSE : NON. Il n'y entre pas du tout.**

```
FLUTTER_TEST_EXIT=0   (2 tests passés)
SF: lib\main.dart          <-- SEUL fichier du rapport ; orphelin_qa.dart ABSENT
LF:19   LH:17              <-- IDENTIQUES au dépôt : 89,47 %, INCHANGÉ
ls lib/ -> main.dart  orphelin_qa.dart     (le fichier était bien là)
```

⛔ **Conséquence pour US-01.1, écrite comme l'AC l'exige :**

1. **Ajouter 500 lignes non testées ne fait PAS baisser la couverture — le cliquet ne les voit pas.**
   Il protège la couverture du code **déjà sous test**, et offre **zéro** protection contre l'arrivée de
   code **entièrement** non testé. C'est **l'angle mort le plus large du mécanisme**, et il est
   **structurel**, pas corrigible par un seuil.
2. **Asymétrie contre-intuitive** : ajouter un **fichier** non testé ⇒ **VERT** ; ajouter une **ligne**
   non testée dans un fichier déjà testé ⇒ **ROUGE**. Le cliquet punit le second et ignore le premier.
3. 🔴 **Chemin de contournement réel** : un refactor qui **déplace** du code non couvert de `main.dart`
   vers un fichier non importé **FAIT MONTER** la couverture. Le cliquet peut donc être satisfait en
   **sortant** le code non couvert du graphe d'import des tests.
4. ⇒ **À US-01.1, le cliquet seul ne suffira pas.** Le complément nécessaire est un contrôle du
   **dénominateur lui-même** *(nombre de fichiers/lignes attendus dans le rapport)*, ou l'usage d'une
   option de couverture forçant l'inclusion de tout `lib/`. **Rien n'est promis ici** : c'est un constat
   mesuré, à porter par US-01.1.

✅ **Contrôle de sortie exigé par l'AC** : `git status --porcelain` → **vide**, `git diff -- lib/` →
**vide**. **`lib/` du dépôt est INCHANGÉ** ; l'expérience a vécu et est morte hors du dépôt.

⇒ **DoD 2 est substantiellement satisfaite par ce rapport** *(la réponse est écrite, avec sa conséquence)*.

---

## 6. Couverture des AC — **0 orphelin**, 4 tenus, 1 partiel, 1 non tenu

| AC | Couvert par | Verdict |
|---|---|---|
| **AC-1** — mesure + dénominateur | C1, C2, C10 + **§5 (question expérimentale tranchée ici)** | ✅ **tenu** |
| **AC-2** — source unique **réellement lue** | C3, C4, C6, C11, C12, C16 ✅ | 🟠 **PARTIEL** — la clause « ⛔ aucun artefact exécuté ne porte le seuil en dur » est **violée** *(B-QA-2)* |
| **AC-3** — refuse la régression, capacité **prouvée** | C7, C8, C10, C15 + **6 fixtures** + **mes 10 mutants** | ✅ **tenu**, et c'est le mieux prouvé de l'US |
| **AC-4** — plancher et cliquet, rôles distincts | C13, C14 *(les 2 branches nommées)*, C16 *(`coverage_min` **réellement lue** : mutation `70 < 80` **détectée**)* | ✅ **tenu** *(borne §7)* |
| **AC-5** — hausse/baisse, gestes explicites et tracés | C9 *(valeur à consigner **+ dénominateur** imprimés)* | ✅ **tenu** *(borne : non assertionné — M-I survit)* |
| **AC-6** — corpus cohérent + critère EPIC coché | C17 ❌ · EPIC_00 ❌ | ❌ **NON TENU** *(B-QA-1, B-QA-3)* |

**AC orphelins** *(aucun test ne les couvre)* : **AUCUN**. Les 6 AC ont chacun au moins un critère
exécutable — l'échec porte sur des **résultats**, pas sur des trous de couverture.

---

## 7. Bornes de ce PASS partiel — ce que je n'ai PAS prouvé

1. ⛔ **Je n'ai pas exécuté la CI.** `actionlint` est absent de ma machine ; je n'emprunte pas la preuve
   des audits. **Les 4 contextes requis n'ont pas été observés verts** *(DoD 13)*.
2. ⛔ **Le cliquet n'authentifie pas le rapport `lcov`.** Un rapport **cohérent** fabriqué à la main
   passerait. Il atteste une **baisse du chiffre rapporté**, jamais la **réalité** des tests.
3. ⛔ **Il n'améliore pas la qualité des tests** — 19 lignes, 1 fichier, **aucune couverture de branches**,
   **aucune fonctionnalité métier**. Marge de régression : **1 ligne → 0 ligne. Rien de plus.**
4. ⛔ **Le cliquet ne monte jamais seul.** Il protège le dernier niveau **CONSIGNÉ**, jamais le dernier
   **ATTEINT**. Aucune détection de péremption. **Non mitigé, et je ne le maquille pas.**
5. ⛔ **La complaisance reste possible et est nommée** : couvrir `void main()` / `runApp(...)` ferait
   **+10,5 pt sans aucune garantie**.
6. 🟠 **Angles morts de `factory_sync --check`, mesurés — 6 sur 11 mutations IGNORÉES** : la forme
   `{value, date, motif}` **n'est pas exigée** *(un `{value}` nu passe, alors que **C-1** l'a arbitrée
   parce que « JSON ne porte aucun commentaire »)* · les **divergences** `coverage_min` ↔ `--min` passent
   **dans les deux sens** · `--no-ratchet` dans la commande du gate **neutralise le cliquet sans que
   `--check` s'en aperçoive** · clé **absente** = silence.
7. 🟠 **Fail-open sur `factory.config.json` introuvable** : `cliquet IGNORÉ` + **exit 0**. Inatteignable
   dans le chemin CI *(`run_gates` lit ce fichier avant, il échouerait le premier)* — **borne, pas trou**.
8. 🟠 **Le plancher opérant vient du littéral `--min 80`**, pas de la clé. `app.coverage_min` **est** lue
   *(par `factory_sync`, pour la cohérence)* — mais le **script qui mesure** ne la lit **pas**. La phrase
   d'ADR-001 *(« `coverage_min = 80`, mesuré par `lcov` via un script dédié »)* n'est donc **pas rendue
   littéralement vraie** : elle l'est **par un autre script que celui qui mesure**.
9. ⛔ **Aucun SAST, aucun scan de CVE** n'existe dans cette factory. Ce rapport ne s'appuie sur **aucun**
   des deux. Les **307 lignes de Python** livrées ne sont couvertes par **aucune** analyse statique.
10. ⛔ **Mes mutants sont FINIS.** 10 posés, 4 survivants. **Aucune exhaustivité n'est revendiquée** — et
    l'histoire de cette US le rappelle : **B-1 a été trouvé par un mutant que personne n'avait écrit.**

---

## 8. Critère de sortie — **atteignable, rejouable, et AUCUN côté n'est figé**

⚠️ **Leçon d'US-00.5 appliquée** : un critère dont un côté est **recopié dans le contrôle** devient
**inatteignable** dès que le corpus évolue. **Les deux côtés du mien sont DÉRIVÉS.** Aucun nombre n'y est
écrit — la vérité vient de `len(CAS)` et du décompte réel des `*.info`.

### CS-1 — les compteurs *(lève B-QA-1)*

```bash
python - <<'PY'
import re, sys, ast
from pathlib import Path
src = Path("scripts/selftest_coverage_ratchet.py").read_text(encoding="utf-8")
cas = ast.literal_eval(re.search(r"^CAS = (\[.*?^\])", src, re.S | re.M).group(1))
V = {"fixtures": len(list(Path("tests/fixtures/US-00.6").glob("*.info"))),
     "attentes": len(cas), "refus": sum(1 for c in cas if c[1] == 1)}
print("[DERIVE DES SOURCES]", V)
def bloc(f, debut=None, fin=None, filtre=None):
    L = list(enumerate(Path(f).read_text(encoding="utf-8").splitlines(), 1))
    if filtre: return [(i, l) for i, l in L if filtre in l]
    if debut is None: return L
    d = next(i for i, l in L if debut in l)
    a = next((i for i, l in L if i > d and fin and re.match(fin, l)), 10**9)
    return [(i, l) for i, l in L if d <= i < a]
P = [("tests/fixtures/US-00.6/README.md", bloc("tests/fixtures/US-00.6/README.md")),
     ("scripts/selftest_coverage_ratchet.py", bloc("scripts/selftest_coverage_ratchet.py")),
     (".github/workflows/ci.yml", bloc(".github/workflows/ci.yml", "AUTOTEST DU CLIQUET", r"^  \w")),
     ("BACKLOG.md", bloc("BACKLOG.md", filtre="| US-00.6 |")),
     ("STORY_CERTIFICATION_BOARD.md", bloc("STORY_CERTIFICATION_BOARD.md", "### [US-00.6]", r"^### \[")),
     ("CLAUDE.md", bloc("CLAUDE.md", filtre="fixtures"))]
M = re.compile(r"(\d+)\s+(fixtures|attentes|REFUS)", re.I); v = 0
for f, L in P:
    for i, l in L:
        if "PÉRIMÉ" in l or "PERIME" in l: continue
        for m in M.finditer(l):
            n, u = int(m.group(1)), m.group(2).lower()
            if n != V[u]: v += 1; print(f"  VIOLATION {f}:{i} -> ecrit '{m.group(0)}', derive = {V[u]}")
print(f"[BILAN] {v}"); sys.exit(1 if v else 0)
PY
```

**Aujourd'hui : exit 1, 7 violations. Attendu : exit 0.** ✅ **J'ai vérifié que cet instrument sait
rendre 0** : sur une copie hors dépôt où les 7 compteurs sont corrigés, il rend **exit 0, 0 violation**.
**Il porte donc son propre mutant, dans les deux sens.**
⚠️ **Bornes de mon instrument, écrites** : *(a)* il ne voit que les compteurs en **chiffres** suivis de
`fixtures | attentes | REFUS` — « **quatre** fixtures » lui échapperait ; *(b)* **première version
FAUSSE, et je le dis** : sans le cadrage par section, il comptait les fixtures d'**US-00.4** *(« 5 »,
« 26 », « 8 »)* comme des violations — **3 faux positifs**. Corrigé par cadrage au périmètre US-00.6.
⛔ **Il n'est PAS versé dans `scripts/`** : fabriquer un instrument permanent dans une US qui en compte
déjà assez serait le meilleur moyen d'en produire un faux — l'audit de revue l'a arbitré pour `verify.sh`,
la même règle s'applique à moi.

**Deux corrections restent hors de la portée de CS-1** *(à faire par édition, puis à vérifier à l'œil)* :
le SCB doit **DATER** *(jamais repeindre)* « ⏳ deux éditions humaines, seules actions restantes » — elles
sont **appliquées** ; et le **README des fixtures doit documenter les 6**, `totaux_incoherents.info` et
`lf_menteur.info` y étant **absentes du tableau** alors que **DoD 8 exige « ≥ 4 fixtures + README »**.

### CS-2 — le seuil en dur *(lève B-QA-2)*

```bash
grep -rn "89\.4" scripts/*.py .github/workflows/*.yml ; test $? -eq 1
```
**Aujourd'hui : `scripts/selftest_coverage_ratchet.py:39` ⇒ échoue.**
**Remède minimal, sans changer un comportement** : que l'autotest **dérive** `REF_MUTANT` d'une valeur
**distincte de celle du projet** *(ex. `lue depuis la config + 0.1`)*, ce qui **tue M-F**. Et **DATER**
la ligne du §7 « 2 → 1 », qui est **fausse** *(mesuré : 2 → 3, et les divergences passent)*.

### CS-3 — le critère de clôture d'EPIC_00 *(lève B-QA-3, DoD 20)*

```bash
grep -n "Seuils de couverture mesurés et ratchet actif" docs/epics/EPIC_00-fondations.md   # attendu : - [x] … + preuve + bornes
grep -n "US-00.6 (ex US-INIT-06)" docs/epics/EPIC_00-fondations.md                          # ne doit plus dire « à créer »
grep -n "Ratchet inopérant" docs/epics/EPIC_00-fondations.md                                # risque nº 3 STATUÉ
```

⛔ **Aucun de ces trois remèdes ne touche au cliquet.** Aucun ne demande de casser un test, d'éditer un
texte immuable, ni d'obtenir une action humaine. **Ils sont tous à portée d'agent, et rejouables.**

---

## 9. Verdict

# 🧪 FAILED

**17 critères de test sur 19 passés** · **DoD 0/20 cochée** *(aucune à tort ; 12 substantiellement
tenues, 1 tenue par ce rapport, 5 non tenues, 4 hors de portée)* · **AC : 4 tenus, 1 partiel (AC-2),
1 non tenu (AC-6)** · **0 AC orphelin** · **couverture 89,47 % (17/19)**, seuil appliqué **89.4 %
(cliquet)** · **2 tests Dart passed, 0 skipped, 0 failed** · **6 attentes de fixtures tenues dont
4 REFUS** · **18 scénarios Gherkin documentaires, 0 exécuté**.

**Motif, par extension :** l'AC-6 n'est pas tenu sur ses **deux** volets — le critère de clôture
d'EPIC_00 n'est **pas coché** *(et l'EPIC dit encore que l'US est « à créer »)*, et **7 compteurs faux
non marqués** subsistent dans le corpus, dont **3 dans le SCB** et **1 dans l'entrée `BACKLOG.md` érigée
en condition de clôture**. **AC-6 « Erreur » qualifie ce silence de « défaut BLOQUANT ».** S'y ajoute la
violation mesurée du critère 5, dont j'ai établi la conséquence : **le mutant M-F survit**.

**Ce que je refuse de faire, dans les deux sens :** je ne délivre pas un PASS parce qu'EPIC_00 attend —
et je ne retiens pas un PASS par prudence. **Le cliquet, lui, est bon** : il est actif, sa valeur est
réellement lue, `16/19` est désormais **ROUGE** alors qu'il passait **VERT**, aucun rouge n'apparaît sur
un dépôt inchangé, `89.4` est la **seule** valeur qui ne verrouille pas le dépôt, et **6 de mes 10
mutants sont vus**. Les trois remèdes ci-dessus sont **petits, mécaniques et rejouables** — je m'attends
à un re-QA court.

**Rappel d'autorité** *(Constitution Art. 5)* : je délivre un verdict `🧪`. La certification `🚀 OUI`
appartient au rituel `/certify` (@Architect), **pas à moi**.
