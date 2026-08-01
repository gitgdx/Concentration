# US-00.6 · Revue **FINALE** — couverture du badge portée à `9ae8631`

> **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-08-01 · **Branche** : `feat/US-00.6-couverture-ratchet`
> **HEAD audité** : **`9ae8631`** · **badge précédent** : `3c56218` · **delta de CODE** : **`+43 / −3`**
> **Rapports antérieurs, aucun écrasé** : [`code_review.md`](code_review.md) *(FAILED, `f585e82`)* ·
> [`code_review_reaudit.md`](code_review_reaudit.md) *(PASSED, `f22d311`)*
> ⛔ **Aucun fichier du dépôt modifié** — `git status --porcelain` **vide**. Les mutants ont tourné sur des
> **copies**, fichier **restauré à l'identique** *(contrôle exécuté : `True`)*.

---

## ✅ VERDICT : **PASSED** — le badge `✅ 🔍` **peut être porté à `9ae8631`**

| | |
|---|---|
| 🔴 Bloquants | **0** |
| 🟠 Non bloquants | **4** *(RF-1 → RF-4)*, dont **2 que ni la QA ni moi n'avions vus** |
| 🎯 Mutants de ce passage | **8**, ciblés sur le **contrôle différentiel** → **3 vus, 5 survivants qualifiés** |
| ⚖️ Question posée *(D-4)* | **Je ne l'exige pas** — **et je corrige la qualification de la QA sur un point mesuré** |
| ✅ Résidus antérieurs | **RA-1, RA-2, RA-5 et le doublon `89.4` : FERMÉS**, vérifiés un par un |

**Le contrôle différentiel fait ce qu'il annonce, et je l'ai prouvé contre lui** : le mutant exact de la
QA — *cliquet figé à `89.4`* — est **tué**, et **c'est la ligne `DIFFERENTIEL` qui le signale**
*(`ref 95.0 -> exit 0 (attendu 1)`)*. **Aucun faux rouge n'est introduit** dans le job requis.

---

## 1. Le delta de code, ligne à ligne

| Fichier | Delta | Ce que j'ai vérifié |
|---|---|---|
| `scripts/selftest_coverage_ratchet.py` | **+40 / −2** | `REF_MUTANT` **`89.4` → `86.0`** · `CAS_DIFFERENTIEL` · bloc différentiel dans `main()` · 2 marqueurs `PERIME` sur des chiffres recopiés |
| `.github/workflows/ci.yml` | **+3 / −1** | ⚠️ **commentaire SEUL** — vérifié par exécution : **aucune ligne non-commentaire modifiée**, **aucun `name:` touché** ⇒ **zéro risque sur les 4 contextes requis** |
| `tests/fixtures/US-00.6/*.info` | **0** | **aucune fixture modifiée** depuis mon badge ⇒ mes vérifications antérieures **tiennent** |

**Cohérence des 6 fixtures, recalculée** *(et non relue)* :

```
hausse_18_sur_19      19/18  LF=19 LH=18  coherent=True
inchange_17_sur_19    19/17  LF=19 LH=17  coherent=True
regression_16_sur_19  19/16  LF=19 LH=16  coherent=True
zero_ligne_mesurable   0/0   LF= 0 LH= 0  coherent=True
totaux_incoherents    19/19  LF=19 LH= 5  coherent=False   <-- ment sur LH (mon mutant, versionne)
lf_menteur            19/17  LF=100 LH=17 coherent=False   <-- ment sur LF -> RA-2 FERME
```

**Exécutions** *(codes mesurés sans pipe : redirection, puis `echo $?` en instruction suivante)* :

```
$ python scripts/selftest_coverage_ratchet.py                  EXIT=0
  OK | regression 1·1 · inchange 0·0 · hausse 0·0 · zero 1·1 · totaux_incoherents 1·1 · lf_menteur 1·1
  OK | DIFFERENTIEL inchange_17_sur_19.info  ref 86.0 -> exit 0 (attendu 0) | ref 95.0 -> exit 1 (attendu 1)
  RESULTAT : les 6 attentes sont tenues, dont 4 REFUS.
$ python scripts/run_gates.py --gate test                      EXIT=0   89.5% (17/19) — seuil requis : 89.4% (cliquet)
$ python scripts/factory_sync.py --check                       EXIT=0
$ python scripts/check_scb_compliance.py                       EXIT=0
$ python scripts/validate_trace.py --all                       EXIT=0
$ python -m py_compile (2 scripts)                             EXIT=0
```

✅ **Mon ancien NB-2 est FERMÉ** : `grep -rn "89\.4"` sur les artefacts **exécutés** ne rend plus que
`factory.config.json:82` *(la source)* — la seule autre occurrence est un **commentaire**. Le nombre du
projet **n'existe plus qu'en un exemplaire opérant**.

---

## 2. J'ai attaqué le contrôle différentiel — **8 mutants, résultats mesurés**

| Mutant injecté dans le *checker* | Vu ? | Par quoi |
|---|---|---|
| **Q1** cliquet **figé à `89.4`** — *le mutant exact de la QA (B-QA-2)* | ✅ **VU** | **le DIFFERENTIEL** : `ref 95.0 -> exit 0 (attendu 1)` |
| **Q2** cliquet **figé à `86.0`** *(= `REF_MUTANT`)* | ✅ **VU** | **le DIFFERENTIEL** ⇒ le correctif **n'est pas couplé** à la valeur choisie |
| **Q5** rabot **soustractif** *(cliquet − 3 pt)* | ✅ **VU** | une **fixture** *(`regression` repasse verte)*, **pas** le différentiel |
| **Q3a** **plafond à 90** posé **dans `read_ratchet`** | ❌ survit | — |
| **Q3b** **plafond à 90** posé **dans `main`** | ❌ survit | — |
| **Q4** rabot **multiplicatif** *(cliquet × 0,99)* | ❌ survit | — |
| **Q6** **plancher forcé à 0** *(le plancher contractuel disparaît)* | ❌ survit | — |
| **Q7** cliquet **ignoré au-delà de 90** *(contournement ciblé)* | ❌ survit | — |

### 2.1 Ce que le différentiel prouve **structurellement** — et c'est solide

Un checker qui **écrit** sa valeur au lieu de la **lire** rend, par construction, **le même verdict pour
les deux références** : la paire attendue `(0, 1)` lui est **inatteignable**. ⇒ **tout littéral, quel qu'il
soit, est tué** — ce n'est pas une propriété du couple `(86, 95)` choisi, c'est une propriété de la
méthode. **C'est la bonne réponse à B-QA-2**, et « comparer une valeur à elle-même ne prouve rien » est
exactement le bon diagnostic.

### 2.2 Ce qu'il **ne** prouve pas — et la QA a sous-estimé la famille

Le différentiel atteste une **dépendance monotone en deux points**, **jamais l'identité**. La famille
survivante n'est donc **pas** « un plafond à 90 » : c'est **toute transformation `f` telle que
`f(86) ≤ 89,47 < f(95)`** — mesuré : un **plafond** *(Q3a, Q3b)*, un **rabot multiplicatif** *(Q4)*, un
**contournement ciblé** *(Q7)*. **Nommer la famille plutôt que l'exemple change le prix du correctif**,
puisqu'un correctif qui ne viserait que « le plafond à 90 » laisserait Q4 et Q7 vivants.

### 2.3 ⚠️ Je **corrige** la qualification de la QA sur un point, et c'est mesuré

La QA qualifie D-4 de **« non silencieux »**, au motif que le checker imprimerait `seuil requis 90.0`
alors que `cliquet = 94.7`. **C'est vrai pour UN point d'injection seulement** :

| Injection | Message produit | Verdict |
|---|---|---|
| **Q3b** — plafond posé dans `main`, **après** la construction du message | `cliquet = 94.7` **et** `seuil requis : 90.0` | **divergence visible** ✅ la qualification tient |
| **Q3a** — plafond posé **dans `read_ratchet`**, là où la valeur est lue *(l'endroit le plus naturel)* | `cliquet = 90.0` **et** `seuil requis : 90.0` | 🔴 **sortie AUTO-COHÉRENTE : le trou est SILENCIEUX** |

⇒ **la mitigation « non silencieux » ne couvre pas le cas le plus probable.** Cela **ne change pas** mon
arbitrage — mais cela **change ce qu'on a le droit d'écrire** à côté.

### 2.4 🎁 Le correctif complet coûte **une assertion par branche**, et je l'ai **MESURÉ** avant de le proposer

Assertionner que la sortie du checker **porte la référence qu'on lui a donnée** :

```
ref=95.0 | checker SAIN            exit=1 | sortie porte "seuil requis : 95.0%" -> True
ref=95.0 | Q3a plafond 90          exit=1 |                                     -> False   <-- tue
ref=95.0 | Q4  rabot x0.99         exit=1 |                                     -> False   <-- tue
ref=95.0 | Q7  ignore au-dela 90   exit=1 |                                     -> False   <-- tue
```

**Une ligne par branche du différentiel tue les trois survivants**, sans toucher au checker et sans
fixture nouvelle. ⛔ **Je ne l'exige pas** *(§3)* — **je le chiffre**, pour que le refus comme
l'acceptation soient un choix informé.

---

## 3. ⚖️ **D-4 : je ne l'exige pas** — et voici la règle que j'applique, la même qu'aux deux passages précédents

**Critère unique, appliqué sans exception depuis le premier audit** : *un finding est bloquant s'il peut
produire un **faux vert dans le code LIVRÉ***. Les cinq survivants sont des **mutations hypothétiques** :
le checker livré n'a **ni** plafond, **ni** rabot, **ni** contournement. Ce qui manque est la **couverture
du contrôle**, pas le contrôle.

**Ce serait incohérent de le bloquer aujourd'hui** : j'ai laissé passer la même classe *(§4.3 du
re-audit)* quand elle jouait **contre** le livrable ; la retourner maintenant qu'elle joue **pour** lui
serait de la sévérité de circonstance, pas de la rigueur. **La QA est arrivée à la même conclusion
indépendamment, avec un chiffrage** — deux instruments séparés, même verdict.

**Ce que j'exige en revanche, et qui ne coûte rien** : que la limite soit **écrite avec sa vraie
extension**. « Un plafond à 90 » sous-décrit le trou ; l'énoncé juste est : *« le différentiel atteste une
dépendance monotone en deux points, jamais l'identité — toute transformation `f` vérifiant
`f(86) ≤ 89,47 < f(95)` survit, et elle est **silencieuse** si elle est posée dans `read_ratchet` »*.
**Destinataire : US-00.8**, avec les autres assertions de message.

---

## 4. Findings **NON BLOQUANTS** — 4

| # | `[Fichier:Ligne]` | Problème | Solution |
|---|---|---|---|
| **RF-1** | `[scripts/selftest_coverage_ratchet.py:52]` *(`CAS_DIFFERENTIEL`)* | La famille survivante est **plus large que « un plafond à 90 »** : plafond, rabot multiplicatif et contournement ciblé survivent *(Q3a/Q3b/Q4/Q7 mesurés)*, et **Q3a est SILENCIEUX** — sortie auto-cohérente | **1 assertion par branche** : la sortie doit porter `seuil requis : {ref}%`. **Mesuré : tue les 3 survivants**, laisse passer le checker sain |
| **RF-2** 🆕 | `[scripts/selftest_coverage_ratchet.py:44-50]` *(`CAS`)* | 🔴 **Le PLANCHER CONTRACTUEL n'a AUCUN cas discriminant** : forcer `--min` à `0` **survit** *(Q6)*. C'est **structurel** — dans **tous** les cas du jeu, le cliquet est **au-dessus** du plancher, donc **le plancher ne décide jamais**. Conséquence : **AC-4** *(« deux nombres, deux rôles »)* **et** AC-2 *(« clé absente ⇒ plancher seul, exit 0 »)* ne sont **assertionnés nulle part en CI** — ils ne le sont que par les critères **manuels** nº 11 et nº 14. ⚠️ **Ni la QA ni moi ne l'avions vu** | **8ᵉ cas** : une configuration temporaire **SANS** la clé `coverage_ratchet`, exit attendu **0**, avec assertion du message `plancher contractuel`. Le différentiel montre déjà **comment** fabriquer la config — ≈ 6 lignes |
| **RF-3** | `[docs/stories/US-00.6-couverture-ratchet.md:281-282]` | Le marqueur `PÉRIMÉ` de **B-QA-4** est inséré **au milieu** de la phrase : la suite de l'interdiction — *« une livraison qui le touche est **refusée**, quel que soit le bénéfice invoqué »* — **retombe sur des lignes SANS marqueur**. `grep -n "bénéfice invoqué"` rend une ligne **non couverte**. ⚠️ **C'est exactement mon RA-5**, corrigé l. 322 et **reproduit ici** : la cause n'est pas l'occurrence, c'est la **méthode** *(insérer le marqueur dans la phrase)* | **Reflow** : marqueur **en tête du bloc**, ou phrase et marqueur sur la **même ligne**. ⛔ Ne **pas** supprimer la phrase d'origine — **la conserver est le bon choix, et il a été fait** |
| **RF-4** | `[scripts/selftest_coverage_ratchet.py:158-160]` | Le total imprimé — « **les 6 attentes** sont tenues, dont 4 REFUS » — est **dérivé de `CAS` seul** alors que l'exécution en réalise **7** *(le différentiel n'y est pas compté)*. ⚠️ **Ironie mesurable** : ce commit vient de **dater deux chiffres recopiés** pour cette raison exacte ; celui-ci est **dérivé**, mais **du mauvais ensemble** | Compter les assertions **réellement exécutées** *(`len(CAS) + 1`, ou un compteur incrémenté)* |

**Résidus antérieurs — vérifiés FERMÉS un par un** : **RA-1** *(contrôle refait **par tableau**, en dérivant le
nombre de colonnes de **chaque en-tête** : **aucune** ligne divergente)* · **RA-2** *(fixture `lf_menteur`
présente et exercée)* · **RA-5** *(marqueur sur la ligne, l. 322)* · **doublon `89.4`** *(absent des
artefacts exécutés)*. **Non fermés et toujours nommés** : RA-3 *(fixture multi-fichiers → US-01.1)*, RA-4
*(plantage `int(hits)`, **préexistant**)*, RA-7 *(question expérimentale d'AC-1)*.

---

## 5. Le point documentaire — **je ne re-audite pas la QA**, je réponds à la seule question posée

**Aucun point documentaire n'est bloquant à mes yeux**, et sur le seul qui touche mon périmètre *(AC-2,
qui gouverne l'édition humaine que j'ai auditée)* je confirme le traitement **par lecture** :

- l'interdiction d'origine est **CONSERVÉE mot pour mot** — **rien n'a été supprimé ni reformulé**
  *(vérifié : le texte est toujours là, l. 281-282)* ;
- **DoD 6 reste `- [ ]` décochée**, avec son motif daté. ✅ **C'est le bon choix, et c'est le point le plus
  difficile de toute l'US** : la case est **insatisfaisable** *(sa lettre exige un `git diff` **vide** là où
  **T8 prescrit `+32/−0`**)*, et **reformuler l'exigence d'après le résultat** aurait été réécrire la règle
  pour la faire coller au livrable. **Une case qu'on ne peut pas satisfaire se DATE, elle ne se coche pas** —
  et une DoD **volontairement incomplète et expliquée** vaut mieux qu'une DoD complète et fausse.
- réserve unique : **RF-3**, sur la **forme** du marqueur, pas sur le fond.

⚠️ **Et je note l'inversion pour ce qu'elle vaut** : ces trois énoncés **interdisaient** ce que l'US a
livré, ils étaient **dans le Story File que j'ai lu deux fois**, et **je ne les ai pas vus**. C'est la QA
qui les a trouvés, **à son deuxième passage, contre elle-même**.

---

## 6. Symétrie — ce que **mes** instruments ont fait dans cette session

Puisqu'il est écrit que la dette de méthode « atteint les deux côtés du contrôle », voici la mienne, **de
ce passage-ci** : mon premier contrôle de RA-1 comparait le nombre de cellules de chaque ligne à **`3`,
un nombre que j'avais écrit à la main** — il a signalé une ligne « à 4 cellules » qui appartenait en
réalité à un tableau **à 4 colonnes**. **J'ai failli publier un finding faux**, et il n'a été évité que
parce que j'ai refait le contrôle en **dérivant** le nombre de colonnes de **l'en-tête de chaque
tableau**. **C'est le remède 5 d'US-00.5, et je venais de l'enfreindre en l'appliquant.** ⇒ le constat de
la QA est juste, et il n'épargne personne : **un contrôle qui porte un nombre écrit à la main est faux
avant d'être utile.**

---

## 7. Bornes de ce PASSED

1. **Il porte sur `9ae8631`**, sur le **code** *(`*.py`, `*.yml`)* et sur la **cohérence** de ce que j'ai
   vérifié. ⛔ **Je n'ai pas re-audité le delta documentaire** — c'est la QA qui l'a couvert, et
   **je ne prends pas son verdict à mon compte** : je constate seulement qu'aucun point documentaire
   entrant dans mon périmètre n'est bloquant.
2. **CI non exécutée** *(`actionlint` absent de ce poste)*. Ce que j'ai vérifié moi-même : `ci.yml` ne
   change **que des commentaires**, **aucun `name:` de job**, donc **aucun effet possible** sur les
   contextes requis. ⛔ Je n'emprunte la preuve d'aucun autre auditeur.
3. **Mutants finis** : **8** ce passage, **23** en tout sur cette US. **Aucune exhaustivité n'est
   revendiquée** — et le compte des trois passages parle de lui-même : **B-1** a été trouvé par un mutant
   que personne n'avait écrit, le re-audit en a trouvé **3**, la QA en a trouvé **1 que j'avais manqué**
   *(B-QA-2)*, et ce passage en trouve **1 que personne n'avait vu** *(RF-2, le plancher sans cas
   discriminant)*. **Il en reste.**
4. **Le mécanisme n'a pas grandi** : **19 lignes**, **1 fichier**, **aucune couverture de branches**,
   **marge de régression 1 ligne → 0**. Un cliquet **empêche de reculer** ; il ne fait **jamais avancer**.
   Le cliquet **ne monte jamais seul**, et **rien ne détecte sa péremption**.
5. **Ce PASSED ne certifie pas l'US** : il autorise le badge `✅ 🔍` sur `9ae8631`. Restent la fusion et
   la clôture, ainsi que **deux écarts que j'ai posés comme conditions de certification** et qui ne sont
   **pas** de ma main : la **dette de l'amendement de l'Art. 4** inscrite dans le corpus **durable**, et
   l'écart **`verify.sh`** *(§4.2 et §4.4 du re-audit)*.
6. ⚠️ **Si l'on juge que le badge doit couvrir aussi le contenu documentaire audité par la QA**, alors mon
   `✅ 🔍` **ne suffit pas seul** — il faut **les deux badges ensemble** sur `9ae8631`. **Je le dis parce
   que c'est précisément le trou que la QA a nommé**, et il serait absurde de le refermer d'un côté en le
   rouvrant de l'autre.

---

## 8. Rejouabilité — le banc de ce passage

```python
# 8 mutants contre le CONTROLE DIFFERENTIEL. Ancrages (1 occurrence exacte, verifiee par assert) :
A_READ = '    try:\n        value = float(node["value"])'
A_MAIN = "    required = max(args.min, ratchet) if ratchet is not None else args.min"
Q1 = A_READ -> '    try:\n        value = 89.4\n        float(node["value"])'          # VU (differentiel)
Q2 = A_READ -> '    try:\n        value = 86.0\n        float(node["value"])'          # VU (differentiel)
Q3a= A_READ -> '    try:\n        value = min(float(node["value"]), 90.0)'             # survit, SILENCIEUX
Q3b= A_MAIN -> "    ratchet = min(ratchet, 90.0) if ratchet is not None else None\n"+A_MAIN   # survit
Q4 = A_READ -> '    try:\n        value = float(node["value"]) * 0.99'                 # survit
Q5 = A_READ -> '    try:\n        value = float(node["value"]) - 3.0'                  # VU (fixture)
Q6 = A_MAIN -> "    args.min = 0.0\n"+A_MAIN                                           # survit -> RF-2
Q7 = A_READ -> '    try:\n        value = float(node["value"])\n        value = value if value <= 90.0 else 0.0'  # survit
# executer `python scripts/selftest_coverage_ratchet.py` en sandbox, exit != 0 attendu, puis RESTAURER
```

```sh
# efficacite MESUREE du correctif propose pour RF-1 (checker sain + 3 mutants, ref=95.0)
#   la sortie doit porter la chaine "seuil requis : 95.0%"  ->  sain=True, Q3a/Q4/Q7=False
# controle des tableaux : DERIVER le nombre de colonnes de l en-tete de CHAQUE tableau,
#   jamais d un nombre ecrit a la main (c est l erreur que j ai commise, cf. §6)
# controle des marqueurs : grep -n par LIGNE ; toute ligne portant l enonce perime doit porter le marqueur
```

---

## 9. Décision

**PASSED — le badge `✅ 🔍` est porté à `9ae8631`.** Le contrôle différentiel **tue le mutant qu'il visait**
*(prouvé, et par la bonne ligne)*, **ne peut pas produire de faux rouge**, et **ferme trois de mes
résidus**. **D-4 n'est pas exigé** — au même critère que celui que j'ai appliqué quand il jouait contre le
livrable —, mais sa **famille réelle est plus large que ce qui était écrit**, elle est **silencieuse dans
le cas le plus probable**, et son correctif complet coûte **une assertion par branche**, **mesurée**.
**RF-2 est le vrai gain de ce passage** : le **plancher contractuel** n'a **aucun cas discriminant**, et
personne ne l'avait vu.

> ⛔ Ce rapport ne coche **aucune** case du SCB, ne modifie **aucun** code, ne touche **ni** le Story File
> **ni** `CLAUDE.md`. Aucun rapport antérieur n'a été écrasé.
