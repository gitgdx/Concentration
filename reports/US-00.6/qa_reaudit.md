# US-00.6 — RE-QA · @QA_Tester (contexte frais)

| Champ | Valeur |
|---|---|
| **US** | US-00.6 — Couverture initiale mesurée + cliquet (*ratchet*) réellement actif |
| **Verdict** | 🧪 **FAILED** — **2 bloquants**, dont **1 que j'avais MANQUÉ au premier passage** |
| **Date** | 2026-07-31 |
| **Agent · modèle** | @QA_Tester · `claude-opus-5[1m]` (contexte frais) |
| **Commit audité** | **`82ee9c1`** *(le `FAILED` précédent portait sur `3c56218`)* |
| **Rapport précédent** | [`qa.md`](qa.md) — **non écrasé** |
| **Dépôt à l'issue** | `git status --porcelain` → **vide**. Aucun fichier du dépôt modifié par la QA |

> ⚠️ Tous les codes de sortie sont mesurés **hors de tout pipe**.
> ⚠️ **Au cours de ce re-audit, MON PROPRE script a planté sur `cp1252` avec un `UnicodeEncodeError`** —
> exactement le bug que le mutant de cette US avait trouvé en production. Je l'ai corrigé avec **la même
> garde** et rejoué. **Je le consigne** : la leçon de cette US m'a rattrapée pendant que je l'auditais.

---

## 1. Verdict, et pourquoi il change de motif

**Mes 3 bloquants sont traités — deux LEVÉS, un PARTIELLEMENT.** Et la méthode employée est la bonne :
⛔ **les nombres n'ont pas été mis à jour, ils ont été RETIRÉS et dérivés.** C'est la seule sortie de la
classe, et je la valide sans réserve.

**Mais je maintiens `FAILED`, et le motif principal n'est plus celui du premier tour** : en vérifiant
B-QA-3 j'ai découvert **une contradiction que j'avais manquée** — **trois énoncés du Story File
INTERDISENT ce que l'US a livré**, dont **AC-2 « Erreur »** qui écrit *« une livraison qui le touche est
**refusée**, quel que soit le bénéfice invoqué »*. **Aucun des trois n'est daté.** C'est la même classe que
B-QA-1, mais appliquée non à un compteur : à une **clause normative de refus**.

⛔ **Ce FAIL ne porte toujours PAS sur le cliquet.** Le mécanisme est le mieux prouvé de cette factory, et
le contrôle différentiel neuf **tue** le mutant que j'avais trouvé.

---

## 2. Tranchage sur mes 3 bloquants

### ✅ B-QA-1 — **LEVÉ.** Rejeu de **CS-1** : `exit 0`, **0 violation**

**Action** → `python` CS-1 *(les deux côtés dérivés)*.
**Attendu** → exit 0. **Obtenu** → **exit 0**.

```
[DERIVE DES SOURCES] {'fixtures': 6, 'attentes': 6, 'refus': 4}
[BILAN] 0 compteur(s) US-00.6 ecrit(s) a la main en desaccord avec la source
```

✅ **Je valide la MÉTHODE plus que le résultat.** Les 7 emplacements ont été traités en **retirant** le
nombre et en le **citant dans le marqueur** — donc l'histoire est conservée *(« on DATE »)* **et** la ligne
cesse d'affirmer faux. Vérifié un par un : `BACKLOG.md`, `README` des fixtures, `ci.yml`, **SCB ×3**, et
la 7ᵉ assertion *(« ⏳ … seules actions restantes »)* devenue **« ✅ APPLIQUÉES le 2026-07-31 (`f585e82`) »**
avec son marqueur **sur la ligne**.

**Sanité de mon propre instrument** *(le contrôle qu'on m'a demandé — ma v1 était fausse, 3 faux positifs)* :
- (a) **il dérive toujours correctement** malgré l'insertion de `CAS_DIFFERENTIEL` **avant** `CAS` : le
  regex `^CAS = ` ne l'avale pas → **6 entrées**, noms vérifiés un par un. ✅
- (b) **faux positifs** : mesuré, le périmètre SCB `[US-00.6]` *(l. 558→611)* **contient des mentions
  d'US-00.4** → **aucun compteur numérique** aujourd'hui, donc **0 faux positif réel**, mais
  ⚠️ **le risque subsiste** : un « 5 fixtures d'US-00.4 » écrit dans le bloc US-00.6 me ferait mentir.
  **Borne de mon instrument, écrite.**
- (c) 🔴 **DÉFAUT SÉMANTIQUE NOUVEAU DE MON INSTRUMENT, et il est de moi** : je dérive
  `attentes = len(CAS) = 6`, or l'autotest exécute désormais **7** assertions *(6 `CAS` + le
  différentiel)*. ⇒ si le corpus écrivait « **7 attentes** » — **ce qui serait plus juste** — **mon CS-1
  le signalerait comme une violation**. Remède : dériver de la **sortie exécutée** *(compter les lignes
  `OK |`)* plutôt que de la source. **Même classe que celle que je traque.**

### ✅ B-QA-2 — **LEVÉ**, et le contrôle différentiel **tue bien mon mutant**

**Action** → j'ai rejoué **M-F** *(le cliquet écrit **en dur** dans le checker)*, qui **survivait** avant.
**Attendu** → l'autotest **rougit**. **Obtenu** → **exit 1**, avec la ligne fautive nommée :

```
D-1  exit=1  VU (rouge)   cliquet EN DUR a 89.4
     > ECHEC | DIFFERENTIEL inchange_17_sur_19.info ref 86.0 -> exit 0 (attendu 0) | ref 95.0 -> exit 0 (attendu 1)
```

✅ **Et aucune constante ne peut survivre** — je l'ai vérifié aux deux références du différentiel :
**D-2** *(en dur à `86.0`, la référence basse)* → **VU** · **D-3** *(en dur à `95.0`, la haute)* → **VU**.
C'est structurel : **une constante rend le MÊME verdict pour les deux références**, donc elle échoue
toujours l'une des deux. **Le raisonnement « comparer une valeur à elle-même ne prouve rien » est correct,
et son remède est correct.**

✅ **§7 daté avec MA mesure** : « **2 → 3** » remplace « 2 → 1 », l'US reconnaît qu'elle **a aggravé** la
duplication, et la résorption est **versée à US-00.8** avec son motif *(deux actions humaines sur fichier
protégé)*. ✅ **Le gate réel applique toujours la vraie valeur** : `seuil requis : 89.4% (cliquet)`.
✅ **Les 6 attentes de fixtures tiennent** malgré `REF_MUTANT : 89.4 → 86.0` *(`16/19 = 84,21 % < 86` reste
ROUGE ; marge resserrée de 5,19 pt à 1,79 pt — suffisante, et le grain est de 5,26 pt)*.

⚠️ **Mon CS-2 était MAL CONÇU, et c'est MA faute** — c'est exactement le piège dont on m'avait avertie.
J'avais écrit `grep -rn "89\.4" scripts/*.py … ; test $? -eq 1` : **un côté FIGÉ**. Il rend `rc=0`, mais sur
**un COMMENTAIRE** — `selftest_coverage_ratchet.py:42`, qui **cite** l'ancienne valeur pour expliquer le
correctif. **Citer une valeur périmée EST la doctrine du projet** ; mon critère punissait donc la bonne
pratique et devenait **inatteignable sans supprimer l'explication**. Je le remplace par **CS-2bis**, dérivé
et **AST** *(seules les constantes EXÉCUTABLES comptent, jamais les commentaires)* :

```
[DERIVE de factory.config.json] seuils du projet = [80.0, 89.4]
  VIOLATION scripts\selftest_coverage_ratchet.py:52 -> constante EXECUTABLE 80.0 = un seuil du projet
[BILAN CS-2bis] 1
```

⇒ **`89.4` a disparu du code exécutable** ✅. Il reste **`PLANCHER = 80.0`**, égal à `coverage_min` —
**résidu PRÉEXISTANT**, de la même classe, **explicitement nommé et versé à US-00.8** par le §7 rectifié.
⇒ **non bloquant** : il est **nommé**, ce qui est exactement ce qu'AC-6 exige.

### 🟠 B-QA-3 — **PARTIELLEMENT LEVÉ : 2 moitiés sur 3**

**Action** → rejeu de **CS-3**.

| Sous-critère | Attendu | Obtenu | |
|---|---|---|---|
| Critère de clôture **coché avec preuve ET bornes** | `- [x]` | **`- [x]`** + mesure `89,4737 % (17/19)`, valeur `89.4`, arrondi vers le bas, mutant en CI requise, **et les bornes** *(19 lignes, 5,26 pt, aucune couverture de branches, cliquet ne monte jamais seul, `lcov` non authentifié)* | ✅ |
| Ligne US-00.6 de l'EPIC | ne doit plus dire « à créer » | `grep -c "à créer via"` → **0** ; la ligne pointe le Story File, `🔨 en cours`, PR #20 | ✅ |
| **Risque nº 3 « Ratchet inopérant » STATUÉ** | statué | ⛔ **NON — ligne 95 inchangée** | ❌ |

✅ **Et j'y ai lu ma propre contribution, inscrite mot pour mot** : « *un fichier Dart **non importé par un
test n'entre PAS au dénominateur**, donc **ajouter 500 lignes non testées ne fait pas baisser la
couverture**, et **déplacer du code non couvert vers un fichier non importé la FAIT MONTER*** » → porté par
**US-01.1**. **C'est la bonne façon de traiter un angle mort : l'inscrire là où il bloquera une décision.**

---

## 3. 🔴 B-QA-4 *(NOUVEAU — et je l'avais MANQUÉ au premier passage)*

### Trois énoncés du Story File **INTERDISENT ce que l'US a livré**, aucun n'est daté

**Action effectuée** → j'ai confronté l'**état réel** du fichier à ce que le corpus en dit. Les deux côtés
sont dérivés : `git diff --numstat` d'un côté, les énoncés de l'autre.

**Résultat attendu** *(AC-6 Nominal (ii))* → tout énoncé rendu faux est **nommé**.
**Résultat obtenu** → **3 énoncés non datés, contredits par l'état réel** :

```
[DERIVE de git] base=309202a · numstat = 32  0  scripts/factory_sync.py -> le fichier est TOUCHE ? True
  VIOLATION docs/stories/US-00.6-couverture-ratchet.md:23   sans marqueur
  VIOLATION docs/stories/US-00.6-couverture-ratchet.md:280  sans marqueur
  VIOLATION docs/stories/US-00.6-couverture-ratchet.md:602  sans marqueur
[BILAN CS-4] 3
```

| Ligne | Texte, cité littéralement |
|---|---|
| **l. 23** *(Métadonnées, « Interdit explicitement »)* | « ⛔ **`scripts/factory_sync.py` n'est PAS touché** — arbitrage humain du 2026-07-31 : fichier **protégé** et le plus sensible du dépôt » |
| **l. 280** *(**AC-2 « Erreur »** — **Must**)* | « ⛔ **`scripts/factory_sync.py` n'est PAS modifié** *(arbitrage humain du 2026-07-31 …)* : **une livraison qui le touche est REFUSÉE, quel que soit le bénéfice invoqué** » |
| **l. 602** *(**DoD 6**)* | « ⛔ **`scripts/factory_sync.py` NON modifié** — `git diff` sur ce fichier **vide** » |

**Or le MÊME fichier exige l'inverse**, et c'est la route **retenue** :

| Ligne | Texte |
|---|---|
| **l. 455** *(Contexte technique)* | « **`scripts/factory_sync.py`** · lecture du cliquet **pour `app`** · 🔒 **HUMAIN** · diff exact fourni en **T8** » |
| **l. 534** *(**T8**)* | « 🔒 **[HUMAIN]** Diff exact pour `factory_sync.py` : lire `coverage_ratchet` **pour le composant `app`** » |

**Mesuré : `+32/−0`. Le fichier EST modifié, comme T8 le prescrit.**

**Pourquoi c'est grave, et pourquoi ce n'est pas un détail de rédaction :**

1. 🔴 **AC-2 « Erreur » est une clause de REFUS d'un AC *Must*.** Un auditeur à contexte frais qui lit le
   Story File **a un motif littéral de refuser cette US**. Ce n'est pas une imprécision : c'est une **règle
   d'acceptation** que la livraison viole.
2. 🔴 **DoD 6 est LITTÉRALEMENT INSATISFIABLE** : « `git diff` sur ce fichier **vide** » ne peut plus
   devenir vrai. La case ne doit **pas** être cochée — elle doit être **DATÉE comme sans objet**.
3. **La grille de test, elle, avait été réconciliée** : le critère nº 6 porte le correctif
   « *(hors le hunk de **T8**)* » — **c'est pourquoi je l'ai mesuré ✅ au premier tour, et pourquoi j'ai
   manqué le reste.** ⇒ **la grille a été rattrapée, l'AC et la DoD ne l'ont pas été.**
4. **C'est la classe déjà payée** : ces trois lignes sont un **résidu de la route abandonnée le
   2026-07-31** *(« valeur en config + logique dans `check_flutter_coverage.py` »)*. L'arbitrage a changé de
   route, les livrables ont suivi, **les interdits ne l'ont pas**. `AC-6 « Erreur »` qualifie ce silence de
   **« défaut BLOQUANT »** — je n'assouplis pas un AC.
5. ⚠️ **Ma part** : je l'ai **manqué** au premier passage parce que j'ai mesuré le **critère nº 6** *(qui
   porte sa réconciliation)* **sans le recouper avec l'AC et la DoD qu'il est censé vérifier**. **C'est la
   même erreur que celle que je reproche : faire confiance à un énoncé au lieu de croiser les sources.**

⛔ **Ce que je ne demande PAS** : de « corriger » l'arbitrage, ni de revenir en arrière sur `factory_sync.py`.
La route retenue est **la bonne** *(elle préserve la clause « l'activation exige du code dans
`factory_sync.py` »)*. Je demande que **les trois interdits soient DATÉS**, comme les 7 compteurs l'ont été.

---

## 4. 🔴 B-QA-5 — Risque nº 3 d'EPIC_00 **non statué** *(résidu de B-QA-3, DoD 20)*

**Action effectuée** → **CS-3bis**, dont le côté « format attendu » est **dérivé de la table elle-même**.
**Résultat attendu** *(DoD 20, T10)* → risque nº 3 **statué**.
**Résultat obtenu** :

```
[DERIVE de la table] risques presents = [1, 2, 3, 4, 5]
   risque 1 : AUCUN     risque 2 : ['CLOS']     risque 3 : AUCUN
   risque 4 : ['TRAIT']  risque 5 : ['CLOS','STATU','TRAIT','LEVÉ','FERM']
[PRECEDENT dans la meme table] risque(s) STATUE(S) : [2, 4, 5]
[BILAN CS-3bis] risque no 3 statue ? NON
```

État réel de la ligne, inchangé depuis US-00.5 :
`| 3 | Seuils de couverture arbitraires non mesurés sur le code réel. | Ratchet inopérant. | Mesure réelle sur le squelette (US-00.6). |`

⇒ **La table d'EPIC_00 présente encore comme risque OUVERT, d'impact « Ratchet inopérant », un risque que
cette US FERME** — une ligne sous le critère de clôture qui vient, lui, d'être coché. **C'est exactement
« le corpus affirme qu'une chose manque alors qu'elle est acquise »**, dans le fichier même dont l'US
prépare la clôture. **Le précédent de format existe deux lignes plus haut** *(risque #2 : « ✅ CLOS le
2026-07-28 (US-00.7) »)*, donc le geste est **connu, court et sans risque**.

---

## 5. Ce que j'ai attaqué et qui tient — l'instrument neuf, que personne n'avait éprouvé

**7 mutants NEUFS contre le contrôle différentiel**, dont **1 contrôle négatif de ma propre attaque** :

| Mutant | Ce qu'il fait au checker | Autotest |
|---|---|---|
| **D-1** | cliquet **en dur** à `89.4` *(= mon M-F)* | 🔴 **VU** |
| **D-2** | cliquet **en dur** à `86.0` *(= la référence basse)* | 🔴 **VU** |
| **D-3** | cliquet **en dur** à `95.0` *(= la référence haute)* | 🔴 **VU** *(3 lignes en échec)* |
| **D-7** | mutant **neutre** *(contrôle négatif : il DOIT survivre)* | ⚪ **survit** ⇒ **mon attaque n'est pas systématiquement rouge** |
| **D-4** | cliquet **lu puis PLAFONNÉ à 90** | 🟠 **SURVIT** |
| **D-5** | cliquet **lu puis MINORÉ de 1 pt** | 🟠 **SURVIT** |
| **D-6** | **plancher contractuel purement IGNORÉ** | 🟠 **SURVIT** |

**Le contrôle différentiel est-il contournable ? OUI, et la classe est exactement caractérisable :**

> **Il prouve que la référence est LUE. Il ne prouve PAS qu'elle est APPLIQUÉE TELLE QUELLE.**
> Toute transformation `f` de la valeur lue telle que `f(86) ≤ 89,47 < f(95)` **survit** — plafonnement,
> décalage, mise à l'échelle.

**Conséquence chiffrée, non hypothétique** — **D-4** est le cas à retenir : un plafond à 90 est **inoffensif
aujourd'hui** *(89.4 < 90)*, mais **dès la première hausse de couverture** *(18/19 = 94,74 %, cas déjà
présent dans les fixtures)*, la référence consignée serait **silencieusement écrêtée à 90** et une
régression de 94,7 % à 90,1 % passerait **VERTE**. **C'est précisément le trou que cette US existe pour
fermer, et il survit à son propre autotest.**

✅ **Remède, petit et précis — je le recommande, je ne l'exige pas** : que le différentiel assertionne aussi
que la sortie imprime `seuil requis : <la référence donnée>%`. Une seule assertion de **message** **tue D-4
et D-5 d'un coup** *(toute `f ≠ identité`)*. Pour **D-6**, un **7ᵉ cas** exerçant une violation du
**plancher** *(cliquet absent + `--min` au-dessus de la mesure — je l'ai exercé à la main : `exit 1`,
message `(plancher contractuel)`)*. **Destinataire : US-00.8.**

### Non-régression — tout est vert

| Contrôle | Exit | Décompte |
|---|---|---|
| `run_gates --gate test` | **0** | **2 passed · 0 skipped · 0 failed** · `89.5% (17/19)` · seuil `89.4 % (cliquet)` |
| `selftest_coverage_ratchet.py` | **0** | **6 attentes tenues dont 4 REFUS**, **+ 1 différentiel OK** *(`ref 86.0 → 0` · `ref 95.0 → 1`)* |
| Copie hors dépôt non mutée *(sanité du banc)* | **0** | — |

### Résidus non bloquants supplémentaires, mesurés

- 🟠 **N-1 · la 20ᵉ manifestation de la classe, dans la rectification de la 13ᵉ→19ᵉ.** `§7`, ligne **149** :
  l'assertion **« 2 → 1 » subsiste sur sa ligne SANS marqueur** ; le marqueur est sur la ligne **150**.
  **Test par ligne** *(la méthode que le projet s'impose : « marqueur littéral sur la ligne même »)* → **1
  hit réel**. ⚠️ **MAIS je l'ai mesuré au RENDU, avec un moteur markdown** : la ligne 149 se termine par un
  **saut forcé** *(2 espaces)*, le marqueur s'affiche **immédiatement dessous dans le même bullet**, et il
  y a **0 astérisque orphelin** malgré l'imbrication d'emphases. ⇒ **aucun lecteur ne peut être trompé**
  *(à la différence de RA-1, qui était **invisible** au rendu)*. **Les 6 autres corrections passent le test
  par ligne** — elles ont **retiré** le nombre. ⇒ **je ne bloque pas**, mais **c'est le seul des 7 traité
  autrement**, et le geste homogène coûterait une ligne.
- 🟠 **N-2 · le README des fixtures ne détaille toujours que 4 des 6** : `totaux_incoherents.info` et
  `lf_menteur.info` — **les deux nées des findings B-1 et RA-2** — n'ont **pas de ligne dans son tableau**.
  Le compteur faux est levé, la **documentation** ne l'est pas. **DoD 8 exige « ≥ 4 fixtures + README ».**
- 🟠 **N-3 · le résumé de l'autotest sous-compte** : « les **6** attentes … dont **4** REFUS » est **dérivé
  de `CAS` seul** et **n'inclut pas le différentiel** ⇒ **7 assertions exécutées, 6 annoncées**. Dérivé
  donc non pourrissable, mais **sous-déclaré** — et **mon CS-1 hérite du même défaut** *(§2, point (c))*.
- 🟠 **N-4 · les audits ne portent PAS sur `82ee9c1`** : `EVT_CODE_REVIEW_PASSED` porte sur `3c56218` et
  `EVT_SECURITY_AUDIT_PASSED` sur `f585e82`. ⇒ **les ~40 lignes du contrôle différentiel n'ont été revues
  par AUCUN auditeur.** **C'est moi qui les ai attaquées** *(§5)*, et je le dis pour que la borne soit
  connue : **une QA n'est pas une revue de code.**
- 🟠 **N-5 · borne inchangée** : **CI non exécutée**, rien observé côté GitHub, **les 4 contextes requis ne
  sont pas observés verts**.

---

## 6. Réponse à la question posée : **quelles cases de la DoD sont cochables**

⚠️ **Fondé sur mes exécutions à `82ee9c1`, pas sur une relecture.** J'ai signalé **deux cases piégées**.

| # | Cochable ? | Fondement mesuré |
|---|---|---|
| **1** | ✅ **OUI** | `mesure_initiale.txt` : commande verbatim + dénominateur `19` + lignes `9`/`10` nommées — 3/3 |
| **2** | ✅ **OUI** | tranchée **par expérience** *(`qa.md` §5)*, conséquence US-01.1 écrite, **inscrite dans EPIC_00** ; `git diff -- lib/` **vide** |
| **3** | ✅ **OUI** | clé présente, objet `{value, date, motif}`, appliquée en `f585e82` |
| **4** | ✅ **OUI** | mutant **bidirectionnel** *(95→1 · 89.4→0)* **+ D-1/D-2/D-3 tués par le différentiel** |
| **5** | 🟠 **OUI, mais AVEC SA RÉSERVE CITÉE** | `89.4` **absent du code exécutable** (AST) ; **`PLANCHER = 80.0` subsiste**, **nommé** et versé à US-00.8. ⛔ **Ne pas la cocher en silence** |
| **6** | ❌ **NON, ET JAMAIS** — **à DATER** | `git diff` = **`+32/−0`**. **La case est INSATISFIABLE et contredit T8** → **B-QA-4** |
| **7** | ✅ **OUI** | **12 mutants de configuration → 12 comportements explicites**, 0 plantage, 0 vert silencieux |
| **8** | 🟠 **OUI avec réserve** | **6 fixtures** ; `lib/` et `test/` **intacts** ; ⚠️ **le README n'en documente que 4** *(N-2)* |
| **9** | ✅ **OUI** | gate `exit 0` après consignation, rejoué **2 fois** |
| **10** | ✅ **OUI** | **les 2 branches nommées** *(`(cliquet)` / `(plancher contractuel)`)* ; mutation `70 < 80` **détectée** par `factory_sync` ⇒ `coverage_min` **réellement lue** |
| **11** | ✅ **OUI** *(option **(b)**)* | dette nommée dans **`CLAUDE.md` ET `BACKLOG.md`**, `grep`-vérifiable. ⚠️ **borne** : l'amendement en **PR dédiée reste DÛ** |
| **12** | 🟠 **la 2ᵉ moitié OUI** | `git diff docs/adr/**` = **0 ligne** ✅. La 1ʳᵉ *(ADR-008)* est **SANS OBJET par arbitrage** → **à DATER**, pas à cocher |
| **13** | ❌ **NON par moi** | **je n'ai pas exécuté la CI** ni rien observé côté GitHub |
| **14** | ❌ **NON** | pas encore fusionné ; **non prouvable par la machine** sur ce dépôt |
| **15** · **16** | ✅ **OUI** | événements présents. ⚠️ **borne N-4** : ils **ne portent pas sur `82ee9c1`** |
| **17** | ❌ **NON** | **ce rapport = FAILED** |
| **18** | 🟠 **à @Architect** | hors de ma mesure ; le SCB porte `⏳` en QA/Déploiement/Certifié — **correct à cette date** |
| **19** | ✅ **OUI** | Story File dans `docs/stories/`, feature dans `tests/features/` |
| **20** | ❌ **NON** | 1ʳᵉ moitié ✅ *(coché, preuve, bornes)* · **2ᵉ moitié ❌** → **B-QA-5** |

⇒ **11 cochables sans réserve · 4 cochables avec réserve écrite · 2 à DATER (6, moitié de 12) · 5 non
cochables (6, 13, 14, 17, 20).**

---

## 7. Critère de sortie — **exhaustif**, et **aucun côté n'est figé**

⛔ **Ceci est la liste COMPLÈTE de ce que j'exige. Je n'y ajouterai rien au prochain tour.** Les deux
bloquants sont **documentaires**, **à portée d'agent**, **sans action humaine**, et **ne touchent pas au
cliquet**.

### CS-4 *(lève B-QA-4)* — les deux côtés dérivés : `git` d'un côté, le corpus de l'autre

```bash
python - <<'PY'
import re, subprocess, sys
from pathlib import Path
for f in (sys.stdout, sys.stderr):
    try: f.reconfigure(errors="replace")
    except Exception: pass
CIBLE = "scripts/factory_sync.py"
base = subprocess.run(["git","merge-base","HEAD","origin/main"],capture_output=True,text=True).stdout.strip()
ns = subprocess.run(["git","diff","--numstat",f"{base}..HEAD","--",CIBLE],capture_output=True,text=True).stdout.strip()
touche = bool(ns)
print(f"[DERIVE de git] {ns or '(vide)'} -> touche ? {touche}")
viol = [(i, l.strip()[:110]) for i, l in
        enumerate(Path("docs/stories/US-00.6-couverture-ratchet.md").read_text(encoding="utf-8").splitlines(), 1)
        if "factory_sync" in l and re.search(r"n'est PAS (modifi|touch)|NON modifi|PAS touch", l)
        and not (("PÉRIMÉ" in l) or ("PERIME" in l))]
if touche:
    for i, t in viol: print(f"  VIOLATION l.{i} affirme le CONTRAIRE de l etat reel, sans marqueur")
print(f"[BILAN CS-4] {len(viol) if touche else 0}"); sys.exit(1 if (touche and viol) else 0)
PY
```

**Aujourd'hui : exit 1, 3 violations. Attendu : exit 0.**
**Remède** : **DATER sur la ligne** les l. **23**, **280** et **602** — *« PÉRIMÉ-2026-07-31 : la route
retenue le 2026-07-31 EXIGE au contraire cette lecture (T8) ; le fichier est modifié en **ajout pur
`+32/−0`**, par édition HUMAINE, et c'est cette route qui **préserve** la clause d'ADR-001 »*. ⛔ **Ne rien
supprimer**, ne rien coder, ne pas toucher `factory_sync.py`.
✅ **Le critère se lève AUSSI si l'inverse était vrai** *(fichier non touché)* : **aucun côté n'est figé**,
il compare deux mesures.

### CS-3bis *(lève B-QA-5)* — le format attendu est **dérivé de la table elle-même**

```bash
python - <<'PY'
import re, sys
from pathlib import Path
for f in (sys.stdout, sys.stderr):
    try: f.reconfigure(errors="replace")
    except Exception: pass
rows = {}
for l in Path("docs/epics/EPIC_00-fondations.md").read_text(encoding="utf-8").splitlines():
    m = re.match(r"^\|\s*(?:\*\*)?(\d+)(?:\*\*)?\s*\|", l)
    if m: rows[int(m.group(1))] = l
J = ("CLOS","STATU","TRAIT","PÉRIM","PERIM","LEVÉ","LEVE","FERM")
st = {n: [j for j in J if j in r.upper()] for n, r in rows.items()}
print("[DERIVE] statuts par risque :", {n: (st[n] or "AUCUN") for n in sorted(rows)})
print("[PRECEDENT dans la meme table] statues :", sorted(n for n in rows if st[n]))
sys.exit(0 if st.get(3) else 1)
PY
```

**Aujourd'hui : exit 1. Attendu : exit 0.**
**Remède** : une cellule, **au format déjà employé par le risque #2 de la même table** — *« ✅ **CLOS le
2026-07-31 (US-00.6)** — mesure réelle `89,4737 % (17/19)`, cliquet `89.4` **actif et lu**, mutant en CI
requise ; ⚠️ **bornes** : 19 lignes, aucune couverture de branches, le cliquet **ne monte jamais seul**, et
**un fichier non importé n'entre pas au dénominateur** → US-01.1 »*.

### Ce que je NE demande pas *(pour que la boucle se ferme)*

⛔ **N-1 à N-5 sont NON BLOQUANTS.** Le résidu du §7 *(marqueur ligne 150 et non 149)* est **propre au
rendu, vérifié par moteur markdown** ; le README, le sous-comptage de l'autotest, les 3 survivants du
différentiel et l'absence de revue de `82ee9c1` sont **nommés ici** et **relèvent d'US-00.8** *(sauf N-4,
qui est une **borne**, pas une dette)*. **Je ne rouvrirai aucun de ces points.**

---

## 8. Verdict

# 🧪 FAILED — 2 bloquants documentaires, 0 sur le mécanisme

**Mes 3 bloquants : 2 LEVÉS, 1 partiellement** *(B-QA-1 ✅ · B-QA-2 ✅ · B-QA-3 🟠 2 moitiés sur 3)*.
**Restent : B-QA-4** *(3 interdits non datés, dont **AC-2 « Erreur »** qui déclare la livraison **refusée**
— **que j'avais manqué**)* **et B-QA-5** *(risque nº 3 d'EPIC_00 non statué)*.

**Décomptes** : `run_gates --gate test` **exit 0** — **2 passed · 0 skipped · 0 failed** · **89,4737 %
(17/19)**, seuil **89.4 % (cliquet)** · autotest **exit 0**, **6 attentes dont 4 REFUS + 1 différentiel** ·
**7 mutants neufs contre le différentiel → 3 VUS, 3 survivants qualifiés, 1 contrôle négatif** · **18
scénarios Gherkin documentaires, 0 exécuté** · **DoD 0/20 cochée** ⇒ **11 cochables, 4 avec réserve, 2 à
DATER, 5 non cochables**.

**Ce que je certifie sans réserve** : le cliquet est **actif**, sa valeur est **réellement lue et non
écrite** — et **c'est désormais PROUVÉ par un contrôle qu'aucune constante ne franchit** *(D-1, D-2, D-3
tous VUS)*. La méthode du correctif est **la bonne** : les nombres ont été **retirés et dérivés**, jamais
mis à jour. Et **mon propre CS-2 était mal conçu** — un côté figé, la faute exacte contre laquelle on
m'avait mise en garde ; **je l'ai remplacé par un critère AST dérivé**.

**Les deux remèdes qui restent sont : trois marqueurs de date, et une cellule de tableau.** Aucun ne
touche au code, aucun n'exige d'action humaine, les deux sont vérifiables par une commande dont **aucun
côté n'est figé**. **Ma liste est exhaustive et je n'y ajouterai rien.**

**Rappel d'autorité** *(Constitution Art. 5)* : je délivre un verdict `🧪`. La certification `🚀 OUI`
appartient au rituel `/certify` (@Architect), **pas à moi**.
