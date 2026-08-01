# US-00.6 — QA FINALE · @QA_Tester (contexte frais)

| Champ | Valeur |
|---|---|
| **US** | US-00.6 — Couverture initiale mesurée + cliquet (*ratchet*) réellement actif |
| **Verdict** | 🧪 **PASS** |
| **Date** | 2026-08-01 |
| **Agent · modèle** | @QA_Tester · `claude-opus-5[1m]` (contexte frais) |
| **Commit audité** | **`ed36525`** · PR **#20** · `headRefOid` de la PR = **`ed365252f346b4b50482abadce72821856340f06`** = **mon HEAD exact** |
| **Rapports précédents** | [`qa.md`](qa.md) *(FAILED, `3c56218`)* · [`qa_reaudit.md`](qa_reaudit.md) *(FAILED, `82ee9c1`)* — **aucun écrasé** |
| **Dépôt à l'issue** | `git status --porcelain` → **vide**. Aucun fichier du dépôt modifié par la QA |

> ⚠️ Tous les codes de sortie sont mesurés **hors de tout pipe**.

---

## 1. Verdict

# 🧪 PASS

**Mes deux bloquants sont levés.** `CS-3bis` → **exit 0**. `CS-4` → **substantiellement levé** — et son
échec littéral résiduel est **un défaut de MON instrument**, pas du livrable : je l'établis au §3 et je
l'assume.

**Ce que ce PASS atteste, et rien de plus** : le cliquet est **actif**, sa valeur est **lue et appliquée
sans transformation**, une régression d'**une seule ligne** est désormais **refusée** dans un contexte
**requis**, la capacité de refuser est **prouvée par un mutant qui tourne en CI**, et **la CI est verte sur
le commit exact** que j'ai audité. **Marge de régression silencieuse : 1 ligne → 0 ligne. Rien de plus.**

---

## 2. Rejeu des critères de sortie — les deux, et rien d'autre

### ✅ CS-3bis — **LEVÉ**, `exit 0`

**Action** → critère dont le format attendu est **dérivé de la table elle-même**.
**Attendu** → le risque nº 3 porte un statut. **Obtenu** :

```
[DERIVE] statuts : {1: 'AUCUN', 2: ['CLOS'], 3: ['CLOS'], 4: ['TRAIT'], 5: [...]}   -> exit 0
```

Le risque nº 3 est **statué**, au format déjà employé par le risque #2 de la même table, **avec ses
bornes**, dont l'angle mort structurel que j'avais tranché par expérience.

### ✅ CS-4 — **SUBSTANTIELLEMENT LEVÉ** · exit 1 **imputable à mon instrument**

**Action** → rejeu. **Obtenu** → **exit 1, 1 violation** : `docs/stories/…:607` *(DoD 6)*.

**Mais j'ai vérifié AU RENDU, sur le document ENTIER** *(et non sur un fragment — ma première tentative
découpait le fichier au milieu d'une liste et fabriquait des faux positifs, je l'ai jetée)* :

| Énoncé | Marqueur dans le même flux de lecture ? | Distance |
|---|---|---|
| **l. 23** — « Interdit explicitement » | ✅ **OUI** | 300 caractères |
| **l. 607** — **DoD 6** | ✅ **OUI** | **83 caractères** — immédiatement après |
| **l. 280-281** — **AC-2 « Erreur »** | ✅ **OUI**, dans la **même phrase** | le marqueur précède la clause |

⇒ **Les trois sont datés et LISIBLES.** Mon `CS-4` exige le marqueur **sur la même ligne physique** ; le
projet écrit les réserves de DoD sur une **ligne de continuation indentée** — c'est **la maison qui
l'écrit ainsi** *(les 4 cases « avec réserve » suivent le même patron)*, et le saut est **forcé**.

⛔ **Et surtout : j'avais DÉJÀ arbitré ce patron exact comme NON BLOQUANT** au tour précédent *(finding
**N-1**, le §7 ligne 149)*. **Bloquer ici serait m'être contredite.** Je ne le fais pas.

✅ **Je valide aussi la décision de laisser DoD 6 DÉCOCHÉE.** Sa lettre exige un `git diff` **vide** là où
**T8** prescrit `+32/−0` : elle est **insatisfiable**, et la reformuler pour la faire coller au livrable
serait **réécrire l'exigence d'après le résultat**. **Une case insatisfiable se DATE, elle ne se coche pas** —
c'est le bon geste, et c'est celui que je demandais.

---

## 3. 🔴 Ce que je dois dire de MOI : mes instruments m'ont trahie **trois** fois

Je le consigne parce que c'est la meilleure pièce du dossier `/audit-methodo`, et parce qu'il serait
malhonnête de ne relever cette classe que chez les autres.

| # | Mon instrument | Le défaut, et il est de moi |
|---|---|---|
| **1** | `CS-1` v1 | **Faux positifs** : il comptait les fixtures d'**US-00.4** *(« 5 », « 26 », « 8 »)* comme des violations. **3 faux positifs**, corrigés par cadrage au périmètre |
| **2** | `CS-2` | **Un côté FIGÉ** — le littéral `89.4`. Il rendait `rc=0` sur un **commentaire** citant la valeur périmée, donc il **punissait la doctrine du projet** et devenait **inatteignable sans supprimer l'explication**. Remplacé par `CS-2bis`, **AST et dérivé** |
| **3** | `CS-4` | **Une hypothèse de forme FIGÉE** — « le marqueur doit être sur la **même ligne physique** ». Il ignore la **ligne de continuation**, forme employée par la DoD elle-même. ⇒ **il rend exit 1 sur un livrable correct** |
| **4** | mon script de contrôle | a **planté sur `cp1252`** avec un `UnicodeEncodeError` — **le bug même que le mutant de cette US avait trouvé en production**. Corrigé avec **la même garde** |
| **5** | ma 1ʳᵉ vérification de rendu | **découpait le document au milieu d'une liste** ⇒ **14 « astérisques orphelins » qui n'existaient pas**. Rejetée, refaite sur le document entier |

⇒ **Cinq fautes d'instrumentation en trois passages, toutes de ma main.** La dette versée à
`/audit-methodo` n'est **pas** une dette de @Architect : **c'est une dette de méthode, et elle atteint
les deux côtés du contrôle**. Je l'écris pour que la prochaine QA le sache avant de commencer.

---

## 4. Réponses aux deux questions posées

### Q1 — **D-4 : je ne l'exige PAS**, et j'ai maintenant une raison **mesurée**, pas procédurale

J'ai testé le scénario que j'avais chiffré — **la référence après la première hausse** *(`94.7`, cas déjà
présent dans les fixtures)* — contre le checker **sain** et contre le checker **muté D-4** *(plafond 90)* :

| | `seuil requis` | `cliquet =` | exit |
|---|---|---|---|
| checker **sain** | **94.7 %** | **94.7 %** | 1 |
| checker **muté D-4** | 🔴 **90.0 %** | **94.7 %** | 1 |

⇒ 🔎 **Le plafonnement laisse une CONTRADICTION IMPRIMÉE, à chaque exécution du gate** : la valeur
**appliquée** et la valeur **lue** cessent d'être identiques. **Le trou n'est donc pas SILENCIEUX — il est
NON ASSERTIONNÉ.** C'est une différence de nature : un contrôle qui dort ne dit rien ; celui-ci **crie sur
chaque ligne de log d'un job requis**, sans que personne n'écoute.

**Trois raisons de ne pas l'exiger maintenant, dans cet ordre :**
1. **Le code livré applique la valeur SANS transformation** — mesuré aujourd'hui : `seuil requis : 89.4%`
   **est identique** à `cliquet = 89.4%`. **Il n'y a aucun défaut à corriger dans le livrable** ; D-4 est un
   **détecteur de régression future** manquant, pas un trou ouvert.
2. **La fenêtre d'exposition est bornée** : `[valeur écrêtée, référence consignée)`. Aujourd'hui elle est
   **VIDE** *(89.4 < 90)*. Elle ne s'ouvre **qu'après** une hausse consignée.
3. ⛔ **Le remède coûterait plus qu'il ne rapporte MAINTENANT** : il ajouterait du **code neuf, revu par
   personne**, dans un **gate requis**, sur une branche dont les badges d'audit ont déjà **3 commits de
   retard**. **On ne ferme pas un trou théorique en ouvrant un risque réel.**
4. Et j'avais écrit que ma liste était **exhaustive**. **Une QA qui ajoute une exigence à chaque tour est
   une QA qui ne converge jamais** — c'est ce qui a coûté 5 `FAIL` à US-00.7.

✅ **Ce que j'exige à la place, et qui ne coûte rien** : que le remède parte en **US-00.8** avec un
**déclencheur non calendaire** — ⛔ **avant la PREMIÈRE remontée de la référence** *(c'est-à-dire avant
qu'une valeur soit consignée au-dessus de la valeur écrêtée possible)*, et **au plus tard à US-01.1**.
Remède, une assertion : **`seuil requis` doit être ÉGAL au `cliquet` lu** ⇒ **tue D-4 et D-5 d'un coup**
*(toute `f ≠ identité`)*. Pour **D-6** *(plancher ignoré)*, un **7ᵉ cas** exerçant une violation du plancher
— je l'ai exercé à la main : `exit 1`, message `(plancher contractuel)`.

### Q2 — **Re-revue : je ne l'exige PAS non plus**, mais **mon PASS ne blanchit pas les badges**

**Le fait qui change tout, et je l'ai mesuré moi-même** — `gh pr checks 20` :

```
check-branch-name                              pass
📋 Governance (SCB + traçabilité + synchro)    pass    <-- c est CE job qui exécute le contrôle différentiel
📱 App (gates run_gates.py)                    pass
🔐 Secrets scan (gitleaks)                     pass
PR #20 · state OPEN · MERGEABLE · headRefOid = ed36525… = mon HEAD exact
```

⇒ ✅ **Ma borne N-5 est CLOSE** : les **4 contextes requis sont observés VERTS**, sur **le commit exact**.
⇒ ✅ **Le risque opérationnel des ~40 lignes non revues est MESURÉ, pas supposé** : le contrôle
différentiel **tourne en CI, dans le job requis, et ne verrouille pas le dépôt**. C'était le risque R-5
*(« une fixture cassée verrouille toute PR »)* — **il ne s'est pas matérialisé**, et c'est observé.
⇒ ✅ **Et je l'ai attaqué** : **7 mutants neufs**, dont un **contrôle négatif** de ma propre attaque.
⇒ ✅ **Le code n'a pas bougé depuis mon attaque** : `git diff 82ee9c1..HEAD -- scripts/ tests/ .github/
factory.config.json` → **vide**. **Mes 17 mutants restent valables sur le commit certifié.**

⛔ **Ce que je refuse de laisser passer sous silence** : `EVT_CODE_REVIEW_PASSED` porte sur **`3c56218`** et
`EVT_SECURITY_AUDIT_PASSED` sur **`f585e82`**. **Les badges `✅ 🔍` et `✅ 🛡️` du SCB ne couvrent donc PAS
`82ee9c1` ni `ed36525`** — dont **~40 lignes de Python exécutées dans un job requis**.
**Une QA n'est pas une revue de code**, et **mon `🧪 PASS` ne vaut pas revue.**

⇒ **Ce n'est pas ma décision.** Sous l'**Art. 5**, décider si un badge d'audit peut couvrir un commit
postérieur à son émission appartient au rituel **`/certify` (@Architect)**, **pas au @QA_Tester**. **Je ne
l'exige pas, je ne l'excuse pas : je le NOMME**, et je demande qu'il soit **tranché explicitement à
`/certify`** — soit par un re-passage court cadré sur les 40 lignes, soit par un arbitrage écrit disant
pourquoi il n'est pas nécessaire. ⛔ **Ce qui serait malhonnête, c'est de ne pas poser la question.**

### Q3 *(non posée, mais je dois y répondre)* — **DoD 13 : je ne la conteste PAS, je la CONFIRME**

J'avais écrit « non cochable **par moi** » — ce qui n'est pas « non cochable ». **Je l'ai vérifiée
moi-même** *(sortie ci-dessus)* : **4 contextes requis `pass` sur le SHA exact de la PR**. La case est
**légitimement cochée**, et elle l'a été **par observation**, pas sur mon autorité. ✅ **Le geste est
correct, et il corrige une lacune de mon propre rapport.**

---

## 5. Décomptes finaux — tout est exécuté

### 5.1 Exécutions

| Contrôle | Exit | Décompte |
|---|---|---|
| `run_gates --all` | **0** | **5 gates** · **2 tests Dart passed · 0 skipped · 0 failed** |
| `run_gates --gate test` | **0** | `89.5% (17/19)` · seuil **`89.4% (cliquet)`** |
| `selftest_coverage_ratchet.py` | **0** | **6 attentes tenues dont 4 REFUS** **+ 1 DIFFÉRENTIEL OK** *(`ref 86.0 → 0` · `ref 95.0 → 1`)* |
| `factory_sync.py --check` | **0** | valide le cliquet pour `app` *(5 mutations détectées / 11)* |
| `check_scb_compliance.py` | **0** | — |
| `validate_trace.py --all` | **0** | — |
| `gitleaks` 8.30.1 *(`--no-git` et `309202a..HEAD`)* | **0** · **0** | 0 fuite |
| **CI réelle, PR #20, SHA `ed36525`** | **pass ×4** | **4 contextes REQUIS verts** |
| `CS-1` | **0** | 0 compteur faux |
| `CS-2bis` *(AST, dérivé)* | 1 résidu | `PLANCHER = 80.0` — **nommé et versé à US-00.8** |
| `CS-3bis` | **0** | risque nº 3 statué |
| `CS-4` | 1 | **imputable à mon instrument** *(§3)* |

**Mutants, cumulés sur les trois passages : 29** — 12 de configuration *(12 comportements corrects, 0
plantage, 0 vert silencieux)*, 10 de code *(6 vus)*, 7 contre le différentiel *(3 vus, 1 contrôle négatif,
3 survivants **qualifiés et nommés**)*.

### 5.2 Scénarios Gherkin — **comptés à part, jamais comme verts**

**18 scénarios documentaires · `0` exécuté · 0 passed · 0 skipped · 0 failed.** Vérifié : aucun runner,
aucune step definition, `tests/features/**` **lu par rien en CI**. ⛔ **Leur nombre ne mesure aucune
couverture** — à ne pas confondre avec les **6 fixtures**, qui s'exécutent réellement.

### 5.3 DoD — **17 / 20**, et les 3 décochées sont **exactement** les miennes

`grep -c '^- \[x\]'` → **17** · `grep -c '^- \[ \]'` → **3** : **6**, **14**, **17**.

- **6** — **insatisfiable**, **DATÉE** et non cochée. ✅ **C'est le bon geste.**
- **14** — fusion humaine sans `--admin`, **non encore faite** et **non prouvable par la machine**.
- **17** — **ma case : ce rapport la lève.**

✅ **Les 4 cases « avec réserve » portent leur réserve DANS la case**, comme je l'exigeais — dont la **5**,
qui écrit noir sur blanc que **la duplication n'est pas résorbée mais AGGRAVÉE (2 → 3)**. ⛔ **Rien n'a été
coché au-delà de ma table.**

### 5.4 AC — **0 orphelin, 6 tenus**

| AC | Verdict |
|---|---|
| **AC-1** mesure + dénominateur | ✅ **tenu** — dénominateur imprimé à chaque exécution ; question expérimentale **tranchée par expérience** et **inscrite dans EPIC_00** |
| **AC-2** source unique réellement lue | ✅ **tenu** — mutant bidirectionnel + **aucune constante ne survit** au différentiel. Réserve `PLANCHER = 80.0` **nommée et versée** |
| **AC-3** refuse la régression, capacité prouvée | ✅ **tenu** — le mieux prouvé de l'US |
| **AC-4** plancher et cliquet, rôles distincts | ✅ **tenu** — les 2 branches nommées ; `coverage_min` réellement lue |
| **AC-5** hausse/baisse explicites | ✅ **tenu** — valeur à consigner **+ dénominateur** imprimés |
| **AC-6** corpus cohérent + critère EPIC coché | ✅ **tenu** — `CS-1` exit 0, `CS-3bis` exit 0, les 3 interdits datés, ADR et Constitution **0 ligne** |

---

## 6. Bornes de ce PASS — ce qu'il n'atteste PAS

1. ⛔ **Le cliquet n'authentifie pas le rapport `lcov`.** Un rapport **cohérent** fabriqué à la main
   passerait. Il atteste une **baisse du chiffre rapporté**, jamais la **réalité** des tests.
2. ⛔ **Il n'améliore pas la qualité des tests** : **19 lignes, 1 fichier, aucune couverture de branches,
   aucune fonctionnalité métier**. **89,47 % de 19 lignes n'a aucune valeur statistique** ; le grain est de
   **5,26 pt** et **aucune valeur n'existe entre 89,47 % et 94,74 %**.
3. ⛔ **Le cliquet ne monte JAMAIS seul.** Il protège le dernier niveau **CONSIGNÉ**, jamais le dernier
   **ATTEINT**. **Aucune détection de péremption.** Non mitigé.
4. ⛔ **Angle mort STRUCTUREL** *(tranché par mon expérience, `qa.md` §5)* : un fichier Dart **non importé
   par un test n'entre PAS au dénominateur**. **Ajouter 500 lignes non testées ne fait pas baisser la
   couverture**, et **déplacer du code non couvert vers un fichier non importé la FAIT MONTER**. → **US-01.1**.
5. ⛔ **La complaisance reste possible, nominativement** : couvrir `void main()` / `runApp(...)` ferait
   **+10,5 pt sans aucune garantie**.
6. 🟠 **D-4 / D-5 / D-6 survivent** à l'autotest : il prouve que la référence est **LUE**, **pas** qu'elle
   est **APPLIQUÉE TELLE QUELLE**. Trou **non silencieux mais non assertionné** *(§4 Q1)* → **US-00.8**,
   **avant la première remontée de la référence**.
7. ⛔ **Les badges d'audit ne couvrent pas `82ee9c1` ni `ed36525`** *(§4 Q2)* — **à trancher à `/certify`**.
8. ⛔ **Aucun SAST, aucun scan de CVE** n'existe dans cette factory ; **ce PASS ne s'appuie sur aucun des
   deux**. Les **~350 lignes de Python** livrées ne sont couvertes par **aucune analyse statique**.
9. ⛔ **Mes mutants sont FINIS.** 29 posés, **aucune exhaustivité revendiquée** — et l'histoire de cette US
   l'impose : **B-1 a été trouvé par un mutant que personne n'avait écrit**, et **B-QA-4 par un croisement
   que j'avais moi-même manqué au premier passage.**

---

## 7. Ce que je délivre

# 🧪 PASS

**17/20 DoD** *(les 3 décochées sont exactement 6, 14, 17)* · **6 AC tenus, 0 orphelin** · **2 tests Dart
passed / 0 skipped / 0 failed** · **89,4737 % (17/19)**, seuil **89.4 % (cliquet)** · **6 attentes de
fixtures dont 4 REFUS + 1 différentiel** · **29 mutants** · **4 contextes CI requis VERTS sur le SHA
exact** · **18 scénarios Gherkin documentaires, 0 exécuté**.

**Trois passages, trois verdicts, et je maintiens les trois** : les deux `FAILED` étaient mérités —
**B-QA-4, le plus important, je l'avais moi-même manqué au premier tour**. Le `PASS` l'est aussi : tout ce
que j'ai exigé est fait, **je n'ai rien ajouté**, et les deux questions qui me restaient ont été tranchées
**par mesure** et non par prudence.

⚠️ **Ce que je laisse explicitement à `/certify`** : le **périmètre des badges d'audit** *(§4 Q2)*.

**Rappel d'autorité** *(Constitution Art. 5)* : je délivre `🧪 PASS`. La certification `🚀 OUI` appartient
au rituel `/certify` (@Architect), **pas à moi** — et un `🧪 PASS` **n'est pas** un `🚀 OUI`.
