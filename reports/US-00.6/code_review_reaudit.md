# US-00.6 · **RE-AUDIT** de revue de code — @CodeReviewer, contexte frais

> **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-31 · **Branche** : `feat/US-00.6-couverture-ratchet`
> **HEAD audité** : **`f22d311`** *(le précédent audit portait sur `f585e82`)* · base `main` : `309202a`
> **Premier rapport, non écrasé** : [`code_review.md`](code_review.md) *(verdict **FAILED**, B-1 + B-2 + 12 NB)*
> ⛔ **Aucun fichier du dépôt modifié** : `git status --porcelain` **vide**. Les **15 mutants** ont tourné
> sur des **copies** en répertoire temporaire, et le fichier muté a été **restauré à l'identique**
> *(contrôle de sortie exécuté : `True`)*.

---

## ✅ VERDICT : **PASSED**

| | |
|---|---|
| 🔴 **Bloquants** | **0** — **B-1 et B-2 sont LEVÉS** *(§1 et §2, chacun par exécution ou par lecture)* |
| 🟠 **Non bloquants** | **7** *(RA-1 → RA-7)* — dont **3 nouveaux**, trouvés par des mutants que personne n'avait écrits |
| 🎯 Mutants exécutés | **15** *(9 rejoués + 6 nouveaux visant le correctif lui-même)* → **8 vus**, **7 survivants** |
| ⚖️ Arbitrages demandés | **4 tranchés** *(§4)* — 1 **acceptable en l'état**, 2 **acceptables sous condition nommée**, 1 **non exigé** |

**Ce que je certifie** : le cliquet est **actif**, sa valeur est **réellement lue**, il **refuse** ce qu'il
annonce refuser, **le correctif B-1 porte son propre mutant** *(le retirer rend l'autotest rouge — vérifié)*,
et **aucun faux vert ne subsiste dans le périmètre littéral de l'AC**. **Ce que je ne certifie pas** est
écrit en §5, sans atténuation.

⛔ **Ce PASSED n'est pas un PASSED de complaisance** : j'ai **fabriqué 6 mutants neufs contre le correctif
que je venais d'obtenir**, dont **2 survivent** *(RA-2, RA-3)*, et j'ai trouvé **3 variantes de rapport
`lcov` qui font PLANTER le gate requis** *(RA-4)*. Rien de cela n'atteint le seuil bloquant — **et je dis
pourquoi, cas par cas, au lieu de le supposer.**

---

## 1. **B-1 — LEVÉ.** Le recoupement existe, il refuse, et il porte son mutant

### 1.1 Ce qui est exigé, mot pour mot, et ce que j'ai mesuré

AC-3 « Erreur » : « *un rapport dont les **totaux déclarés** contredisent les **lignes comptées** est
**refusé** : un rapport **tronqué** (exécution interrompue) ne doit **jamais** produire un vert* ».

| Cas | Attendu | **Obtenu** *(exécuté, codes sans pipe)* |
|---|---|---|
| Totaux déclarés contredits *(`LF:19` / `LH:5`, 19 lignes comptées toutes couvertes)* — **mon mutant du 1ᵉʳ audit, désormais versionné** | ROUGE | **`EXIT=1`** · `SE CONTREDIT — totaux declares differents des lignes comptees : LH: declare 5 …, 19 comptee(s)` |
| **`LF:` seul** mensonger *(`LF:42`, `LH:17` juste)* — cas que **la fixture n'exerce pas** | ROUGE | **`EXIT=1`** · `LF: declare 42 …, 19 comptee(s)` ⇒ **la branche `LF` fonctionne** *(mais elle n'est pas couverte — RA-2)* |
| **Troncature réelle** du vrai rapport *(fin coupée : plus de `LF:`/`LH:`/`end_of_record`)* | ROUGE | **`EXIT=1`** · refus **explicite** *(et non plus « rouge par le pourcentage »)* |
| **Dépôt inchangé** *(vrai `lcov`)* | VERT | **`EXIT=0`** · `89.5% (17/19) — seuil requis : 89.4% (cliquet)` |
| **Multi-fichiers légitime** *(2 enregistrements cohérents, 27/29)* | VERT | **`EXIT=0`** · `93.1% (27/29)` ⇒ ⚠️ **le point que je redoutais le plus est SAIN** : `LF`/`LH` sont **sommés**, donc **aucun faux rouge à l'arrivée d'un 2ᵉ fichier Dart** — le gate est requis, un faux rouge y **verrouillerait le dépôt** |
| Les **5 fixtures** du jeu, une par une | 1·0·0·1·1 | **`1 · 0 · 0 · 1 · 1`** — conforme |
| L'autotest complet | 5 attentes, 3 refus | **`EXIT=0`** · « *les 5 attentes sont tenues, dont 3 REFUS* » |

### 1.2 Le correctif est **falsifiable** — c'est ce qui décide de la levée

J'ai injecté **6 mutants neufs visant le recoupement lui-même** :

| Mutant | Vu ? |
|---|---|
| **M10** le bloc `if anomalies:` **supprimé** *(le correctif entier)* | ✅ **VU** *(exit 1)* — **c'est la levée de B-1 : le refus ne peut pas disparaître en silence** |
| **M12** branche **`LH`** neutralisée | ✅ **VU** |
| **M14** recoupement rendu **tolérant** *(`!=` → seuil large)* | ✅ **VU** |
| **M15** anomalies calculées mais **jamais renvoyées** | ✅ **VU** |
| **M11** branche **`LF`** neutralisée | ❌ **NON VU** → **RA-2** |
| **M13** `LF`/`LH` pris au **dernier** enregistrement au lieu d'être **sommés** | ❌ **NON VU** → **RA-3** |

⇒ **Le cœur du correctif porte son mutant.** Les deux survivants sont des **moitiés non couvertes**, pas
un contrôle inopérant : **les deux branches FONCTIONNENT** *(prouvé ligne 3 du tableau §1.1 pour `LF`, et
par le multi-fichiers pour la somme)* — ce qui manque est **leur fixture**, pas leur code.

### 1.3 Bornes de la levée — ce que le correctif ne fait **pas**

1. **Il ne détecte pas le rapport portant MOINS DE FICHIERS** *(17/17 = 100 %, `EXIT=0`, + invitation à
   consigner `100.0`)*. ⚖️ **Tranché en §4.1 : acceptable comme limite nommée.** Motif décisif : un tel
   rapport est **cohérent avec lui-même** — il ne « contredit ses totaux » ni n'est « tronqué », donc **il
   sort du texte de l'AC**, qui est ce que j'ai à faire respecter.
2. **Le recoupement porte sur les SOMMES**, jamais par enregistrement : deux divergences **compensatoires**
   *(fichier A déclare +2, fichier B déclare −2)* passent — mesuré, `EXIT=0` sur `100.0% (18/18)`. Hors
   d'atteinte d'un incident réel *(une troncature ne compense pas)*, dans le périmètre de la borne déjà
   nommée « **le cliquet n'authentifie pas le rapport** ».
3. **Il n'authentifie toujours rien** : un rapport **cohérent fabriqué à la main** passe. Borne inchangée,
   et elle est **écrite dans le code et dans l'autotest**.

---

## 2. **B-2 — LEVÉ.** Les trois clauses sont nommées avec citation, raison et destinataire

**Vérifié par lecture, clause par clause** *(et non sur parole)* : la rectification est présente dans
**trois** documents, avec le **marqueur `PÉRIMÉ-2026-07-31` sur la ligne même** de l'affirmation fausse
*(contrôle `grep` par ligne : couvert dans le Story File et dans le SCB)*.

| Exigence d'AC-6 (ii) | État |
|---|---|
| (a) **citation littérale** des énoncés rendus faux | ✅ les **3** clauses sont citées mot pour mot *(« n'est PAS en vigueur » · « absente de `factory.config.json` » · « lue seulement pour un composant `frontend` »)* |
| (b) **raison** de la fausseté | ✅ « c'est le **succès même** d'US-00.6 qui les rend fausses », avec la preuve de chacune |
| (c) **destinataire** | ✅ **Art. 4 → amendement en PR dédiée** *(`1.1` → `1.2`, attestation humaine)* · **ADR-001 → nommé et NON corrigé** *(immuable)* |
| ⛔ aucun texte immuable édité | ✅ `git diff main...HEAD -- docs/adr docs/governance` → **0 ligne** |
| l'affirmation fausse « RESTENT VRAIS » est **retirée**, pas repeinte | ✅ marquée **PÉRIMÉ** sur la ligne *(Story File, SCB)* et **rectifiée par APPEND** au PROJECT_LOG — **correct** : ce fichier est **append-only**, l'éditer serait repeindre l'histoire |

**Je valide aussi le raisonnement, parce qu'il est juste** : la clause « l'activation exige **du code** dans
`factory_sync.py` » **est** sauvée *(32 lignes y sont)*, et **rien ne pouvait sauver** une phrase qui
décrit l'**absence** de la clé — **toute** implémentation la rendait fausse. Le refus d'un ADR-008 est
également fondé : **la décision d'ADR-001 est inchangée**, seul son **constat d'état** a vieilli, et un
ADR ne se réécrit pas.

⚠️ **Un résidu, et il n'est pas cosmétique — RA-1** : dans le Story File, la rectification a été ajoutée
comme **4ᵉ cellule d'un tableau à 3 colonnes** *(vérifié : en-tête = 3 colonnes, ligne `A-1` = **4
cellules**)*. Or **la spécification GFM ignore les cellules en excès** : la rectification est **présente
dans la source et invisible au rendu**. Un lecteur du Story File **sur GitHub** voit donc encore
« ✅ **L'Art. 4 et ADR-001 RESTENT VRAIS** » **sans** sa rectification. **Pourquoi cela ne bloque pas
malgré tout** : l'exigence d'AC-6 est de **nommer**, et c'est fait — **de façon rendue** — dans le **SCB**
*(tableau de bord normatif du projet)*, dans le **PROJECT_LOG**, dans le **code**, dans le **README des
fixtures** et dans **R-2**. Le défaut porte sur **une occurrence sur cinq**, et son correctif est un
**déplacement de texte entre deux cellules**. ⚖️ **Je le dis pour que le choix soit explicite : si l'on
tient l'état RENDU du Story File pour la référence, RA-1 redevient bloquant** — mon PASSED ne le dissimule
pas, il le classe.

---

## 3. Sorties d'outils — **collées**, codes mesurés **sans pipe**

```
$ python scripts/selftest_coverage_ratchet.py
  OK    | regression_16_sur_19.info    exit attendu=1 obtenu=1
  OK    | inchange_17_sur_19.info      exit attendu=0 obtenu=0
  OK    | hausse_18_sur_19.info        exit attendu=0 obtenu=0
  OK    | zero_ligne_mesurable.info    exit attendu=1 obtenu=1
  OK    | totaux_incoherents.info      exit attendu=1 obtenu=1
 RESULTAT : les 5 attentes sont tenues, dont 3 REFUS.
EXIT_SELFTEST=0

$ python scripts/run_gates.py --gate test
Couverture de lignes : 89.5% (17/19) — seuil requis : 89.4% (cliquet)     ✅ app.test
EXIT_GATE_TEST=0

fixtures une par une :  regression=1 · inchange=0 · hausse=0 · zero=1 · totaux_incoherents=1

$ python scripts/run_gates.py --all        EXIT_ALL=0   (5 gates : format, analyze, test, deps_audit, build)
$ python scripts/factory_sync.py --check   EXIT_FSYNC=0
$ python scripts/check_scb_compliance.py   EXIT_SCB=0
$ python scripts/validate_trace.py --all   EXIT_TRACE=0
$ python -m py_compile (3 scripts)         EXIT_PYCOMPILE=0
```

> ⚠️ **Rappel de méthode, inchangé** : les gates **`lint` et `typecheck` n'existent pas** dans cet adapter
> *(`run_gates --gate lint` → **exit 1 « aucun gate ne correspond »**, ce qui **n'est pas** une erreur de
> l'US)*, et **aucun linter Python n'est installé** *(`ruff`, `flake8`, `pyflakes`, `pylint`, `mypy` :
> tous absents)*. Mon jugement de code repose sur `py_compile` **et sur 15 mutants exécutés**.

---

## 4. Les **quatre arbitrages** demandés — tranchés

### 4.1 · La limite « rapport portant moins de fichiers » ⇒ ✅ **ACCEPTABLE comme limite nommée**

**Je ne l'exige pas.** Trois raisons, toutes vérifiables :
1. **Elle est hors du texte de l'AC** : un rapport restreint à un sous-ensemble est **cohérent avec
   lui-même**. AC-3 exige le refus des rapports qui **se contredisent** ou sont **tronqués** — c'est fait.
2. **Le risque n'a aucun déclencheur aujourd'hui** : il existe **un** fichier `lib/` et **un** fichier de
   test. Produire un sous-ensemble exige une **manipulation manuelle**, déjà couverte par la borne
   « le cliquet n'authentifie pas le rapport ». Le risque **naît avec le 2ᵉ fichier Dart**.
3. **Tes deux options coûtent plus que le risque** : un dénominateur **en dur** violerait le critère nº 5 ;
   une **clé de plus** est une **3ᵉ édition humaine** d'un fichier protégé pour un risque **non atteignable
   en l'état**.

**Conditions de mon accord** *(elles ne coûtent rien et sont `grep`-vérifiables)* :
**(i)** la limite est nommée **dans la docstring du contrôle**, pas seulement dans un rapport d'audit — un
lecteur du code doit la voir ; **(ii)** elle est versée à **US-01.1** *(et non US-00.8)* : c'est **elle** qui
amène le 2ᵉ fichier, donc le déclencheur ; **(iii)** le véhicule est déjà prêt — la forme **objet** de
`coverage_ratchet` *(arbitrage C-1)* accueillera un champ `lines`, donc la décision est **différée, pas
perdue**.
🎁 **Mitigation gratuite que je recommande sans l'exiger** : faire imprimer au message `[HAUSSE]` le
**dénominateur** sur lequel la valeur a été calculée. C'est **une f-string**, et cela répare le point le
plus tranchant : **la seule action humaine que le script sollicite** est de consigner un nombre, et un
humain à qui l'on tend « `100.0` » **verrait** « `17/17` » et pourrait remarquer que le dénominateur a bougé.

### 4.2 · Le **report** de l'amendement de l'Art. 4 ⇒ ✅ **ACCEPTABLE, sous une condition nommée**

**Ton argument de séquence est juste et je le reprends** : amender maintenant ferait affirmer au texte
normatif que le cliquet est en vigueur alors que son code n'est **pas** sur `main` — ce serait **la même
faute en sens inverse**, et une fausseté **plus** grave car **prospective**. Ordre correct : **PR d'US-00.6
→ PR dédiée de l'amendement → certification**.

⚠️ **Condition, et elle est le cœur du sujet** : aujourd'hui l'amendement dû est nommé **uniquement dans
des documents à portée d'US** *(Story File, entrée SCB, ligne PROJECT_LOG)*. **Vérifié : ni `CLAUDE.md`
§Dettes, ni `BACKLOG.md` ne le mentionnent** *(0 ligne dans le diff)*. **Si la PR dédiée glisse, rien dans
le corpus durable ne signalera que l'Art. 4 est faux** — et ce dépôt a **déjà nommé** ce mode de
pourrissement *(« la dette la plus susceptible de pourrir silencieusement », « aucun événement
d'extinction », « aucun déclencheur calendaire »)*. ⇒ **La dette doit être inscrite là où elle survit à
l'US**, avant certification. C'est une exigence de **clôture** *(T9 / DoD 11)*, pas de mon PASSED : elle est
`grep`-vérifiable et elle n'appartient pas au code.

### 4.3 · Les **assertions de message** *(mutants M4, M6, M7, M8, M11, M13)* ⇒ 🟠 **dette nommée, NON exigée**

**Je ne les exige pas comme bloquantes**, et voici le critère que j'applique : **aucun** de ces mutants ne
peut produire un **faux vert dans le code livré**. Ils signifient qu'une **régression future** sur une
**sous-règle** partirait en silence — c'est une **dette de couverture du contrôle**, pas un défaut du
contrôle. Elle mérite d'être nommée avec son prix : **7 survivants sur 15**, dont deux (**RA-2**, **RA-3**)
touchent le correctif **que tu viens d'écrire**. **Le remède est petit** : assertionner **un fragment de
message** par cas *(1 ligne chacun)*, **une 6ᵉ fixture** mentant sur **`LF` seul**, **une 7ᵉ** en
**multi-fichiers**. Destinataire : **US-00.8** *(même classe que le `selftest` de
`check_branch_protection.py` qui dort depuis US-00.4)*, **sauf** la fixture multi-fichiers, qui va avec
**US-01.1**.

### 4.4 · `reports/US-00.6/verify.sh` ⇒ 🟠 **NON exigé, mais l'écart doit être fermé**

**Je ne l'exige pas** : la **substance** — des commandes rejouables — existe désormais dans **deux**
rapports d'audit *(le §8 de mon premier rapport contient le banc complet)*. **Mais l'écart doit être fermé
dans un sens ou dans l'autre** : soit le script existe, soit **la phrase qui l'annonce disparaît**. Laisser
un Story File désigner « la source vive » d'un fichier absent est **exactement** le remède 1 d'US-00.5 —
*ne jamais écrire un emplacement à la main à côté d'une commande*. ⛔ **Je ne le crée pas moi-même** : je
deviendrais le producteur d'un artefact que j'audite.

---

## 5. Findings **NON BLOQUANTS** — 7, dont 3 nouveaux

| # | `[Fichier:Ligne]` | Problème | Solution |
|---|---|---|---|
| **RA-1** 🆕 | `[docs/stories/US-00.6-couverture-ratchet.md:195]` | La rectification de B-2 est une **4ᵉ cellule dans un tableau à 3 colonnes** *(en-tête : 3 · ligne : 4 — vérifié)*. **GFM ignore les cellules en excès** ⇒ **présente dans la source, invisible au rendu**. Le lecteur du Story File sur GitHub voit la phrase fausse **seule** | **Déplacer le bloc `PÉRIMÉ` à l'intérieur de la cellule 2** *(même ligne, donc toujours couvert par un `grep` par ligne, et **rendu**)*. Coût : un déplacement de texte |
| **RA-2** 🆕 | `[scripts/check_flutter_coverage.py:97-101]` · `[tests/fixtures/US-00.6/totaux_incoherents.info]` | **La branche `LF` du recoupement n'a aucun mutant** : la fixture déclare `LF:19` **juste** et ne mente que sur `LH:5` ⇒ **M11 (branche `LF` neutralisée) survit**. Or `LF` est le **dénominateur** — la moitié qui **pilote le pourcentage** | **6ᵉ fixture** mentant sur **`LF` seul** *(je l'ai exécutée : le code refuse bien — c'est la **fixture** qui manque, pas la logique)* |
| **RA-3** 🆕 | `[scripts/check_flutter_coverage.py:88-96]` | Le recoupement **somme** `LF`/`LH` sur tous les enregistrements ; **aucune fixture n'est multi-fichiers** ⇒ **M13 (`+=` → `=`) survit**. **Déclencheur daté : US-01.1**, où un 2ᵉ fichier Dart rendrait cette sommation porteuse — et une sommation cassée produirait un **faux ROUGE** dans un contexte **requis**, donc un **verrouillage** *(R-1)*. ⚠️ **Le comportement actuel est CORRECT** *(multi-fichiers légitime → `EXIT=0`, 27/29)* : c'est sa **protection** qui manque. Corollaire : deux divergences **compensatoires** entre fichiers passent *(mesuré : `EXIT=0` sur 18/18)* | **7ᵉ fixture multi-fichiers** *(à joindre à **US-01.1**)* ; et pour les compensations, recouper **par enregistrement** au lieu de la somme *(comparer à chaque `end_of_record`)* |
| **RA-4** 🆕 | `[scripts/check_flutter_coverage.py:78]` *(`int(hits)`, sans garde)* | **3 variantes de `lcov` font PLANTER le gate requis** *(traceback `ValueError`, pas de message)* : `DA:9,0,aBcD1234` *(variante **avec somme de contrôle**, produite par `lcov --checksum` ou une fusion de rapports)*, `DA:9,abc`, `DA:9`. La doctrine de l'US écrit pourtant « ⛔ **jamais un plantage** ». ⚠️ **PRÉEXISTANT — pas une régression d'US-00.6** : la version de `main` plante **à l'identique** *(vérifié)*, et l'US n'a pas touché cette ligne. ⚠️ **Et cela échoue en ROUGE** *(exit 1)* : **aucune régression ne peut se cacher derrière** | `try/except ValueError` → **anomalie explicite** nommant la ligne fautive *(≈ 3 lignes)*. Même classe que le `except ValueError: pass` des lignes `LF:`/`LH:`, qui rend un message trompeur *(« LF: declare 0 »)* au lieu de « `LF:` illisible » |
| **RA-5** | `[docs/stories/US-00.6-couverture-ratchet.md:321]` | **Le fragment `**augmenterait** mécaniquement le pourcentage.` subsiste SEUL sur sa ligne, SANS marqueur** — le marqueur `PÉRIMÉ` a été inséré **avant** lui, donc **la ligne qui porte l'affirmation fausse n'est pas couverte** *(contrôle `grep` par ligne : **NON COUVERT**)*. C'est **RB-3/RB-4 d'US-00.5**, **le défaut même que le README rectifié cite comme corrigé** — et donc la **12ᵉ manifestation**, dans la rectification de la 11ᵉ | **Reflow** : ramener l'affirmation et son marqueur sur la **même ligne** *(le README, lui, le fait correctement — s'en inspirer)* |
| **RA-6** | *(inchangés du 1ᵉʳ audit)* `[scripts/selftest_coverage_ratchet.py:39]` · `[factory.config.json:80,98]` · `[…:143-152]` · `[factory_sync.py:161-164]` · `[check_flutter_coverage.py:51,81-82]` | **Rappel, non traités et non représentés comme traités** : `89.4` dupliqué dans l'autotest · le plancher `80` **toujours écrit deux fois** *(et le §7 affirme « 2 → 1 »)* · `--no-ratchet` neutralise le cliquet sans que `--check` le voie · la forme `{value,date,motif}` n'est exigée nulle part · « messages **en ASCII** » **faux** *(mais garde efficace)* · source unique introuvable ⇒ vert sur le plancher seul | Voir §5 de [`code_review.md`](code_review.md) — **aucun n'est bloquant, aucun n'est fermé** |
| **RA-7** | `[reports/US-00.6/]` · **DoD 2** | La **question expérimentale d'AC-1** *(un fichier Dart qu'aucun test n'importe entre-t-il au dénominateur ?)* **reste sans réponse écrite**. C'est l'item qui décide si le cliquet aura **le moindre mordant à partir d'US-01.1** — et il est **directement lié à RA-3** *(même angle mort : le dénominateur)* | La trancher **par expérience**, fichier **temporaire non livré**, contrôle de sortie `lib/` inchangé. ⛔ **Je ne peux pas la trancher** : elle exige d'écrire dans `lib/` |

---

## 6. Couverture **AC ↔ preuve** — après correctifs

| AC | Verdict | Fondement |
|---|---|---|
| **AC-1** | ✅ **tenu** *(réserve RA-7)* | dénominateur imprimé à chaque exécution · mesure brute datée archivée · « 0 ligne ⇒ refus » **et** « rapport incohérent ⇒ refus » · ⚠️ question expérimentale non tranchée *(RA-7)* |
| **AC-2** | ✅ **tenu** *(réserves RA-6)* | lecture **prouvée par mutant** · fail-explicit **8/8** · réserves connues sur l'unicité du nombre |
| **AC-3** | ✅ **TENU — c'était le bloquant B-1** | refus prouvé *(16/19)* · **totaux contredits refusés** · **troncature refusée explicitement** · **5 fixtures, 3 refus** · **le correctif porte son mutant (M10 vu)** · ⛔ aucun test réel cassé |
| **AC-4** | ✅ tenu | deux rôles, message nommant le seuil violé, `réf < plancher` refusée |
| **AC-5** | ✅ tenu *(Should)* | hausse non bloquante + valeur exacte imprimée · aucune remontée automatique |
| **AC-6** | ✅ **TENU — c'était le bloquant B-2** *(réserves RA-1, RA-5)* | 3 clauses **citées, expliquées, destinées** · ADR et Constitution **non édités** *(0 ligne)* · PROJECT_LOG rectifié **par append** · ⚠️ **une occurrence non rendue** *(RA-1)* et **une ligne non couverte** *(RA-5)*. Le critère de clôture d'EPIC_00 *(DoD 20)* reste dû — **normal, c'est « fin de cycle »** |

---

## 7. **Bornes de ce PASSED** — à lire avant de s'en servir

1. **Je n'ai pas exécuté la CI.** `actionlint` n'est pas installé sur ce poste ; ⚠️ l'audit sécurité, lui,
   déclare l'avoir passé — **ce n'est pas ma preuve, je ne l'emprunte pas**. Ce que j'ai vérifié moi-même :
   le step vit dans le job **`governance`** = **`📋 Governance (SCB + traçabilité + synchro)`**, présent
   dans `status_checks`, et **aucune ligne `name:` de job n'a été modifiée**.
2. **Rien n'est vérifié côté GitHub** : ni protection de branche, ni PR, ni provenance de fusion.
3. **Mes mutants sont finis** : **15** sur le contrôle, **8** rapports `lcov` forgés, **7** configurations,
   **4** commandes de gate, **3** codepages. **Aucune exhaustivité n'est revendiquée** — **B-1 avait été
   trouvé par un mutant que personne n'avait écrit, et ce re-audit vient d'en trouver 3 de plus** *(RA-2,
   RA-3, RA-4)*. **C'est la meilleure raison de penser qu'il en reste.**
4. **Le mécanisme reste petit, et sa valeur est celle annoncée** : **19 lignes**, **1 fichier**, `89,47 %`
   **sans valeur statistique**, **aucune couverture de branches**, **marge de régression 1 ligne → 0**.
   Un cliquet **interdit de reculer** ; il ne fait **jamais avancer** la qualité des tests.
5. **Le cliquet ne monte jamais seul** : il protège le dernier niveau **CONSIGNÉ**, jamais **ATTEINT** —
   **aucune détection de péremption n'existe**, et cette US ne la ferme pas.
6. **Mon PASSED porte sur le CODE et sur la COHÉRENCE, à `f22d311`.** Il ne dit rien de la QA
   *(case 17)*, du déploiement, ni de la clôture d'EPIC_00. **Deux exigences de clôture restent dues et
   sont `grep`-vérifiables** : la **dette de l'amendement inscrite dans le corpus durable** *(§4.2)* et
   **l'écart `verify.sh`** *(§4.4)*.
7. **Si le rendu du Story File est tenu pour la référence, RA-1 redevient bloquant** *(§2)*. **Je classe,
   je ne masque pas** : le fait est écrit, la décision reste ouverte à l'humain.

---

## 8. Rejouabilité — le banc, **augmenté**

Le banc du 1ᵉʳ audit *(§8 de [`code_review.md`](code_review.md))* reste valide **tel quel**. Ajouts de ce
re-audit, à appliquer sur une **copie** *(le dépôt n'est jamais modifié ; contrôle de sortie :
`fichier restauré == original`)* :

```python
# mutants visant le CORRECTIF B-1 — chacun DOIT rendre l'autotest ROUGE
("M10 refus supprime",        "    if anomalies:",                 "    if False:"),          # VU
("M11 branche LF",            "    if lf_declare != total:",       "    if False:"),          # NON VU -> RA-2
("M12 branche LH",            "    if lh_declare != covered:",     "    if False:"),          # VU
("M13 somme -> dernier",      "                lf_declare += int(line[3:].strip())",
                              "                lf_declare = int(line[3:].strip())"),          # NON VU -> RA-3
("M15 anomalies non rendues", "    return pct, covered, total, anomalies",
                              "    return pct, covered, total, []"),                          # VU
```

```sh
# rapports lcov forges — attendus a gauche, obtenus mesures sans pipe
D1 multi-fichiers legitime (2 enregistrements coherents) .......... EXIT 0   93.1% (27/29)
D2 divergences compensatoires entre 2 fichiers .................... EXIT 0   100.0% (18/18)   <-- borne
D3 variante lcov AVEC somme de controle (DA:9,0,aBcD1234) ......... EXIT 1   TRACEBACK        <-- RA-4
D4 hits non numerique (DA:9,abc) .................................. EXIT 1   TRACEBACK        <-- RA-4
D5 DA sans virgule (DA:9) ......................................... EXIT 1   TRACEBACK        <-- RA-4
D6 LF/LH absents = troncature reelle de la fin .................... EXIT 1   refus EXPLICITE
D7 sous-ensemble de fichiers, coherent ............................ EXIT 0   100.0% (17/17)   <-- limite §4.1
D8 LF seul mensonger (LF:42, LH:17 juste) ......................... EXIT 1   refus EXPLICITE
```

```sh
# controle de la RECTIFICATION documentaire, par grep par ligne (le seul qui ne se laisse pas raconter)
grep -rn "AUGMENTE\|augmenterait" --include=*.md --include=*.py .   # chaque ligne doit porter PERIME/INVERSE/DIMINUE
#   -> 1 ligne NON COUVERTE : docs/stories/US-00.6-couverture-ratchet.md:321   (RA-5)
grep -rn "RESTENT VRAIS" --include=*.md .                            # idem, hors PROJECT_LOG (append-only)
#   -> Story File 195 : couvert (mais 4e cellule, NON RENDUE -> RA-1) · SCB 571 : couvert et rendu
python - <<'EOF'   # compte les cellules du tableau des decisions clarify
from pathlib import Path
for i,l in enumerate(Path("docs/stories/US-00.6-couverture-ratchet.md").read_text(encoding="utf-8").splitlines(),1):
    if l.startswith("| # | Décision au gate") or l.startswith("| **A-1**"):
        print(i, len(l.strip().strip("|").split("|")), "cellules")   # attendu : 3 et 3 -> obtenu : 3 et 4
EOF
```

---

## 9. Décision

**PASSED** — **0 bloquant**, **7 non bloquants** *(3 nouveaux)*.
**B-1 est levé** parce que le refus exigé **existe, refuse, et ne peut plus disparaître en silence** —
c'est le mutant M10 qui le prouve, pas une déclaration. **B-2 est levé** parce que les trois clauses sont
**citées, expliquées et destinées**, sans qu'aucun texte immuable ait été édité.
**Ce qui reste est nommé, chiffré et daté** : deux moitiés de contrôle sans fixture *(RA-2, RA-3)*, un
plantage **préexistant** sur trois variantes de `lcov` *(RA-4)*, une rectification **non rendue** *(RA-1)*,
une ligne **non couverte** par son marqueur *(RA-5)*, et deux écarts de clôture *(§4.2, §4.4)*.

> ⛔ Ce rapport ne coche **aucune** case du SCB, ne modifie **aucun** code, ne touche **ni** `CLAUDE.md`
> **ni** le Story File. Le rituel `/audit-us` reporte ce verdict. Le premier rapport
> [`code_review.md`](code_review.md) **n'a pas été écrasé** — il reste la trace du FAILED et de ce qui l'a
> motivé.
