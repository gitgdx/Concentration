# US-00.7 — Rapport QA, 4ᵉ passage (re-audit 3) — @QA_Tester

| Champ | Valeur |
|---|---|
| **US** | US-00.7 — Application de la protection de branche |
| **Agent** | @QA_Tester — contexte frais |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-07-29 |
| **Branche** | `feat/US-00.7-cloture` — HEAD `511e02e` (post-fusion PR #14, `main` = `cad24e8`) |
| **Périmètre réel** | `git diff f4400ca..HEAD` — **61 fichiers, 11 638 +, 260 −** |
| **Pré-conditions** | `validate_trace.py --us US-00.7` → **« Traçabilité conforme »** (EVT_CODE_REVIEW_PASSED + EVT_SECURITY_AUDIT_PASSED présents) |
| **Rapports antérieurs** | `qa.md` (FAIL / 26) · `qa_reaudit.md` (FAIL / 27) · `qa_reaudit2.md` (FAIL / 27) — **aucun écrasé** |

---

## 0. VERDICT

# 🧪 FAIL

**Quatrième échec, sur un motif réel et de nouveau différent.**

Ce n'est **pas** un FAIL de principe. Trois des quatre revendications de l'orchestrateur sont
**authentiquement tenues** et je les valide par exécution : `merge_block.md` est **réellement**
assaini, `CLAUDE.md` §encadré est **réellement** corrigé, `docs/GIT_PROTECTION.md:22` est **réellement**
rectifié, et le **refus de fusion serveur est bel et bien prouvé** (HTTP 405, PR #14). Le travail de
fond est fait.

Ce qui échoue est la revendication **(A)** : « correction menée par l'**extension** du défaut, trois
classes balayées sur **tout** le corpus ». **Le balayage est de nouveau incomplet.** J'ai trouvé
**15 assertions invalidées survivantes réparties sur 5 documents vivants**, dont **deux documents
normatifs jamais touchés par aucune des quatre corrections** (`docs/SQUAD_GUIDE.md`, et le §*État
courant* de `CLAUDE.md`), et **une dans le fichier même que (C) déclare corrigé**
(`reports/US-00.7/README.md:86`).

Le diagnostic du 3ᵉ passage — « *la correction suit le renvoi au lieu de suivre le défaut* » — **n'est
donc pas levé** : il s'est **reproduit une quatrième fois**, cette fois masqué par un procédé de
marquage qui donne l'illusion de l'exhaustivité.

| Question posée | Réponse |
|---|---|
| **Critère 27** | ❌ **NON LEVÉ** — 2 volets sur 3 tenus ; le volet **R-c** ne l'est pas (§4) |
| **DoD 32/34** | ✅ **Décompte exact** — mais le Story File **n'est pas cohérent avec lui-même** (§5) |
| **Procédé de marquage (B)** | ❌ **Insuffisant, et reproduit le défaut sous une autre forme** (§3) |
| **Case 34 par attestation niveau 1 (D)** | ❌ **Non recevable comme levée de critère** ; recevable comme *consignation* (§4.2) |
| **Critères 20 / 21** | Raisonnement des passages 2-3 **repris et confirmé, mais re-fondé** sur une preuve, pas sur une déférence (§6) |
| **Tableau des 28 critères** | **25 LEVÉS / 3 NON LEVÉS** (20, 21, 27) — §7 |

---

## 1. Exécutions — toute affirmation de ce rapport est adossée à une commande

### 1.1 Gate de test et couverture (obligatoire)

```
$ python scripts/run_gates.py --gate test
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:00 +0: loading .../test/widget_test.dart
00:00 +0: affiche le titre du squelette
00:01 +1: incrémente le compteur au tap
00:04 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test
Tous les gates bloquants passent (1 exécutés).
```

**Décompte exact, Constitution Art. 3 :**

| | Passed | **Skipped** | Failed | Total |
|---|---|---|---|---|
| Unitaires (`flutter test`) | **2** | **0** | **0** | **2** |
| E2E BDD | **0** | **0** | **0** | **0** — *stack non démarrée ; US de plateforme, `tests/features/US-00.7-*.feature` est un fichier de spécification, non exécuté* |
| **TOTAL** | **2** | **0** | **0** | **2** |

**Couverture : 89,5 % (17/19 lignes) ≥ seuil 80,0 % → conforme.**
⚠️ **Portée honnête** : cette couverture porte sur le squelette Flutter, **sans rapport** avec le
livrable d'US-00.7 (0 fichier Dart modifié). Elle atteste une **non-régression**, pas une validation.

### 1.2 Gouvernance et non-régression

```
$ python scripts/validate_trace.py --us US-00.7      → Traçabilité conforme.
$ python scripts/check_scb_compliance.py             → SCB conforme — Aucune violation détectée.
$ python scripts/factory_sync.py --check             → Synchro factory conforme (vérification DOCUMENTAIRE)
$ python scripts/factory_sync.py --emit-branch-protection | (8 clés)
  ['allow_deletions','allow_force_pushes','enforce_admins','required_conversation_resolution',
   'required_linear_history','required_pull_request_reviews','required_status_checks','restrictions']
$ python tests/fixtures/US-00.7/nb1_harness.py
  → CODE DE SORTIE DU COMPARATEUR : 2 — MAPPING INCOMPLET … enforce_admins = {"enabled": true}
    (mot « conforme » ABSENT ; correctif NB-1 effectif)
$ grep -nE "-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)" scripts/check_branch_protection.py
  → aucun résultat (rc=1) — lecture seule préservée
$ grep -rn "check-remote" .github/workflows/
  → aucun résultat (rc=1) — contrôle négatif maintenu, --check-remote toujours hors CI
```

### 1.3 État réel du dépôt (lecture seule)

```
$ gh pr view 14 --json state,mergedAt,mergedBy,mergeCommit
{"state":"MERGED","mergedAt":"2026-07-29T14:20:00Z",
 "mergedBy":{"login":"gitgdx","is_bot":false},
 "mergeCommit":{"oid":"cad24e8acfc04ff620a21232213c691f60b50a6a"}}

$ git ls-remote origin refs/heads/main
cad24e8acfc04ff620a21232213c691f60b50a6a	refs/heads/main

$ gh pr view 14 --json reviewDecision,latestReviews,reviews
{"latestReviews":[],"reviewDecision":"","reviews":[]}
```

**La fusion de la PR #14 est un fait établi.** `main` = `cad24e8`. En revanche **aucune revue
n'existe** sur cette PR : `reviews: []`.

### 1.4 Le refus de fusion — je confirme qu'il EST prouvé

```
$ cat reports/US-00.7/applied_state/merge_refusal_server_405.txt
# gh api -X PUT repos/gitgdx/Concentration/pulls/14/merge -f merge_method=merge
# Horodatage UTC : 2026-07-29T08:49:14Z | contextes verts au moment de l appel : 1/4
# Aucun --admin, aucune regle desactivee, aucun contexte retire.
gh: 3 of 4 required status checks are expected. (HTTP 405)
{"message":"3 of 4 required status checks are expected.",...,"status":"405"}
exit=1
```

`gh api` n'étant qu'un transport HTTP, le **405 vient du serveur**. **D-1 est refermé, le critère 26
est LEVÉ.** Je le confirme sans réserve — et c'est précisément ce qui rend les 15 survivances du §2
fautives : elles nient un fait désormais acquis.

---

## 2. DÉFAUT BLOQUANT — R3-1 : le balayage par l'extension du défaut est de nouveau incomplet

> **Action effectuée** → **Résultat attendu** → **Résultat obtenu**

> **Action effectuée** : balayage indépendant de la classe (a) — « le refus de fusion n'est pas
> prouvé / T11 n'est pas exécutée » — sur **tout** le corpus, toutes extensions, sans me limiter aux
> fichiers cités en (C) :
> ```
> $ grep -rn "n'est pas satisfait\|n'est pas prouvé\|pas encore prouvé\|non prouvé\|
>   reste une inférence\|N'A PAS EU LIEU\|n'a pas eu lieu\|non exécutée\|NON ACQUIS" \
>   --include="*.md" --include="*.txt" --include="*.py" --include="*.sh" \
>   --include="*.yml" --include="*.json" .
> $ grep -rn "9fdb7fd\|US-00.7-certif\|Reste dû" CLAUDE.md STORY_CERTIFICATION_BOARD.md docs/ reports/US-00.7/README.md
> $ grep -rni "case 34" --include="*.md" .
> ```
>
> **Résultat attendu** : d'après la revendication (A), **zéro** assertion invalidée subsistante dans un
> document **vivant** — les seules survivances admissibles étant les **artefacts datés** (rapports
> d'audit, `PROJECT_LOG`, `reports/US-00.4/**`), que la DoD 19 et l'AC-5 *erreur* **interdisent** de
> réécrire.
>
> **Résultat obtenu** : **15 assertions invalidées survivantes dans 5 documents VIVANTS.**

### 2.1 Les 15 survivances

Je distingue strictement les **documents vivants** (normatifs, qui dirigent un lecteur futur — ils
**doivent** être exacts) des **artefacts datés** (qui enregistrent un état à leur date — ils **ne
doivent pas** être réécrits). Ce critère n'est pas de mon invention : c'est **exactement** celui que
l'orchestrateur a lui-même appliqué en corrigeant `GIT_PROTECTION.md`, le SCB et le Story File tout en
laissant `code_review.md` et `PROJECT_LOG.md` intacts. Je le lui applique intégralement.

| # | Fichier vivant | Ligne | Assertion survivante | Cité en (C) ? |
|---|---|---|---|---|
| 1 | `CLAUDE.md` | 53 | « **PR #12 FUSIONNÉE le 2026-07-28** (`main` = `9fdb7fd`) » — `main` vaut **`cad24e8`** | ❌ **non** |
| 2 | `CLAUDE.md` | 54 | « **DoD 28/34.** » — le décompte réel est **32/34** | ❌ **non** |
| 3 | `CLAUDE.md` | 55 | « Suite sur la branche post-fusion **`feat/US-00.7-certif`** » — la branche est **`feat/US-00.7-cloture`** | ❌ **non** |
| 4 | `CLAUDE.md` | 55-56 | « ⛔ **Reste dû : la preuve du REFUS de fusion (T11(d), case 13)** — à capturer sur la PR de certification » | ❌ **non** |
| 5 | `CLAUDE.md` | 94 | « `EVT_WORKFLOW_VIOLATION` tracé, **case 34 décochée** » — la case 34 est **cochée** depuis (D) | ❌ **non** |
| 6 | `docs/SQUAD_GUIDE.md` | 41-44 | « [le refus de fusion] **n'a pas encore été observée** … c'est la tâche **T11** d'US-00.7, **non exécutée à ce jour**. Écrire "aucune fusion possible avec la CI rouge" est donc une **inférence raisonnée, pas une preuve** » | ❌ **non** |
| 7 | `docs/SQUAD_GUIDE.md` | 316-318 | « le refus d'une **tentative de fusion** n'a **pas encore été observé** sur ce dépôt (tâche **T11** d'US-00.7, **non exécutée**) — il **découle** de l'état constaté, il n'en est pas la preuve » | ❌ **non** |
| 8 | `STORY_CERTIFICATION_BOARD.md` | 627-629 | « ⚠️ **Ce qui N'EST PAS prouvé — à lire avant tout audit** : le **refus d'une tentative de FUSION** n'a **pas** été observé (**T11 non exécutée**) » | ❌ **non** |
| 9 | `STORY_CERTIFICATION_BOARD.md` | 710 | « **Preuve encore obtenable** sur la **PR de certification** (`feat/US-00.7-certif`) » | ❌ **non** |
| 10 | `STORY_CERTIFICATION_BOARD.md` | 991-996 | « 🎯 **CHEMIN DE SORTIE — UN SEUL GESTE.** La PR de certification … **rouvrira la fenêtre de ~80 s** nécessaire au **refus de fusion** (*referme **D-1***) » | ❌ **non** |
| 11 | `reports/US-00.7/README.md` | 86 | ligne T11 du tableau d'index : « **⛔ NON EXÉCUTÉE** … Exige une PR ouverte + une tentative de fusion réelle » | ⚠️ **fichier cité, ligne manquée** |
| 12 | Story File | 1090 | case de tâche **`- [ ]` T11** décochée, alors que le corps de la même tâche écrit « ✅ **T11 COMPLÈTE au 2026-07-29** » | ❌ **non** |
| 13 | Story File | 1133 | « **l'AC-4 nominal n'est pas satisfait**. » — **ligne non marquée**, continuation de la l. 1132 marquée | ⚠️ **marqueur à côté** |
| 14 | Story File | 1557 | « **L'AC-4 nominal n'est pas satisfait.** » — **ligne non marquée**, continuation de la l. 1553 marquée | ⚠️ **marqueur à côté** |
| 15 | Story File | 1568 | tableau des cases bloquées : « ⏳ **Dépend de la PR** *(T11 non exécutée)* \| **2** · **13** · **14** · **26** · **34** \| **5** » — ces **5 cases sont toutes cochées** aujourd'hui | ❌ **non** |

### 2.2 Pourquoi ces trois-là sont les plus graves

**`CLAUDE.md` (survivances 1-5) est le fichier d'instructions injecté à chaque session.** Son §*État
courant* est resté figé au 2026-07-28. Résultat : **`CLAUDE.md` se contredit frontalement lui-même à
25 lignes d'intervalle** —

* **l. 55** : « ⛔ **Reste dû : la preuve du REFUS de fusion (T11(d), case 13)** »
* **l. 79** : « ✅ **Le refus d'une tentative de FUSION EST PROUVÉ — par le SERVEUR** »

L'encadré a été soigneusement corrigé ; le paragraphe qui le précède immédiatement ne l'a pas été.
C'est **la signature exacte du défaut diagnostiqué au 3ᵉ passage** : la correction est allée à
l'endroit désigné par le renvoi, et s'est arrêtée là. Or `CLAUDE.md` est le **document n° 1 nommé par
l'AC-5 nominal** — l'AC que cette tâche avait précisément pour objet de satisfaire.

**`docs/SQUAD_GUIDE.md` (survivances 6-7) n'a été touché par aucune des quatre corrections.** Dernier
commit : `fbd0e3c` (2026-07-28), soit **avant** l'obtention de la preuve. Il figure pourtant
**explicitement dans la liste des 11 artefacts vivants du critère 22**, et c'est le document que
**chaque agent de la squad est censé lire**. Il enseigne aujourd'hui, deux fois, une proposition
fausse — et l'enseigne sous une forme *méthodologique* (« ceci est une inférence, pas une preuve »),
donc particulièrement susceptible d'être reprise telle quelle par un futur agent.

**`reports/US-00.7/README.md:86` est dans le fichier que (C) déclare corrigé.** Les lignes 44, 183 et
184 ont été traitées ; la ligne 86 — la ligne T11 du **tableau d'index des tâches** — ne l'a pas été.
L'argument employé à la l. 184 du même fichier (« **Un index n'a pas de date : il décrit ce qui EST** »)
est juste, et **s'applique mot pour mot** à la ligne 86, qui y échappe pourtant.

### 2.3 Une classe que personne n'avait nommée — la classe (d)

Il m'était demandé de chercher aussi dans une classe non encore nommée. **En voici une, et elle est
créée par la correction (D) elle-même.**

En cochant la case 34, l'orchestrateur a **invalidé toutes les assertions « case 34 décochée »** du
corpus — sans les balayer. La classe (a) avait été identifiée *après* la preuve du 405 ; la classe (d)
naît *au moment même* de la levée de la case 34, et n'a été balayée nulle part.

Survivance vivante : **`CLAUDE.md:94`** — « `EVT_WORKFLOW_VIOLATION` tracé, **case 34 décochée** »,
énoncé au présent, dans une liste normative intitulée « Ce qui n'est PAS prouvé », en contradiction
directe avec la case `- [x] **34.**` du Story File et avec `SCB:990`.

**Le corpus est donc désormais incohérent sur la case 34 dans les deux sens** : le SCB et le Story File
la disent cochée, `CLAUDE.md` la dit décochée. C'est la démonstration structurelle que la méthode de
correction employée **ne se généralise pas** : elle traite la classe qu'on lui désigne, et engendre
silencieusement la suivante.

---

## 3. Jugement demandé sur le procédé de marquage (B)

**Verdict : le marqueur littéral est un progrès réel sur `~~texte~~`, mais il est insuffisant, et il
reproduit le défaut sous une forme plus difficile à détecter.** Trois raisons, toutes vérifiées.

### 3.1 Le décompte est exact — et c'est là le piège

`grep -rn "PÉRIMÉ-2026-07-29"` rend **16 occurrences**, conformes à la revendication. Le procédé est
donc **auditable**, ce que `~~texte~~` n'était pas. **C'est un vrai gain, je le reconnais.**

Mais un décompte exact de marqueurs **ne mesure que les corrections effectuées** — jamais les
corrections **omises**. Les 15 survivances du §2 sont, par construction, **invisibles à ce contrôle**.
Le procédé fournit une métrique rassurante qui **ne porte pas sur la question posée**. C'est le
troisième avatar du même défaut : compter les renvois traités au lieu de mesurer l'extension du défaut.

### 3.2 Le marqueur est *à la ligne*, l'assertion est *à la phrase* — preuve matérielle

Le marqueur est revendiqué « posé **sur la ligne même** de chaque assertion ». Or, dans un Markdown à
lignes repliées, **une assertion s'étale sur plusieurs lignes** — et `grep` travaille **ligne par
ligne**. Le marquage à la ligne est donc structurellement inadapté à l'outil qu'il prétend servir.

Story File, l. 1131-1133, texte réel :

```
1131       fusionnée en `9fdb7fd`. Rapport : `…/merge_block.md`.** ⛔ **LA CASE RESTE DÉCOCHÉE :
1132       **PÉRIMÉ-2026-07-29** *(vrai pour la PR #12 seule)* — le sous-pas (d) … N'A PAS EU LIEU**, donc
1133       **l'AC-4 nominal n'est pas satisfait**. **(a) ✅** PR ouverte · …
```

Un auditeur qui `grep` la proposition fausse obtient :

```
$ grep -rn "n'est pas satisfait" docs/stories/US-00.7-application-protection-branche.md
1133:      **l'AC-4 nominal n'est pas satisfait**. **(a) ✅** PR ouverte · les 4 libellés rapportés
1557:> refusée**. **L'AC-4 nominal n'est pas satisfait.** Détail, cause et procédure corrigée :
```

**Deux lignes, aucun marqueur.** L'assertion fausse est rendue **nue** à l'outil même que le projet
utilise pour s'auditer. La l. 1131 (« LA CASE RESTE DÉCOCHÉE ») est dans le même cas. Le procédé
**échoue sur son propre critère de conception**.

### 3.3 Le marqueur ne dit pas *ce qui* est périmé

Le même jeton est employé pour deux rôles opposés :

* `GIT_PROTECTION.md:22` : « ✅ **PÉRIMÉ-2026-07-29 — LE REFUS DE FUSION EST DÉSORMAIS PROUVÉ** » →
  le marqueur préfixe l'énoncé **vrai qui remplace**.
* `merge_block.md:43` : « **PÉRIMÉ-2026-07-29** — T11(d) … **n'a pas eu lieu** » →
  le marqueur préfixe l'énoncé **faux d'origine**.

Lu par `grep`, sans contexte, le premier se lit littéralement « *le refus de fusion est désormais
prouvé — périmé* », c'est-à-dire **l'inverse** de ce qui est voulu. Le marqueur signale qu'*il s'est
passé quelque chose* sur la ligne, sans indiquer **dans quel sens**. Un jeton discriminant
(`OBSOLETE:` / `RECTIFIE-EN:`) aurait levé l'ambiguïté à coût nul.

**Ce qui reste à faire** : porter le marquage **au niveau de l'assertion** (bloc/phrase, pas ligne
physique), employer **deux jetons distincts** selon le rôle, et surtout — **cesser de marquer et
commencer à balayer** : c'est l'exhaustivité du balayage, non la qualité du marqueur, qui est en cause
depuis quatre passages.

---

## 4. Critère 27 — NON LEVÉ

Texte normatif (Story File, l. 1427) :

> `merge_block.md` prouve qu'aucun `--admin` n'a été employé, qu'aucun contexte n'a été retiré, qu'aucune
> règle n'a été désactivée « pour ce merge ». **Écrit honnêtement** : le refus démontré porte sur un
> contexte **`expected`**, **pas** sur un contexte **rouge** ; `strict: true` et
> `required_conversation_resolution` sont deux **conditions supplémentaires**, documentées.
> **Revue humaine explicite de la PR consignée** (renforcement **R-c**).

| Volet | Verdict | Vérification |
|---|---|---|
| **1.** Aucun `--admin`, aucun contexte retiré, aucune règle désactivée | ✅ **TENU** | `merge_refusal_server_405.txt` l. 4 : « *Aucun --admin, aucune regle desactivee, aucun contexte retire* ». Lecture intégrale de `merge_block.md` : **plus aucune assertion fausse non marquée** — les 4 défauts du 3ᵉ passage (l. 36, 38-41, 48-49, 173) sont **tous traités**, y compris l'index l. 184 corrigé **en fait** et non historisé. **Je valide ce travail sans réserve.** |
| **2.** `expected` ≠ rouge, `strict`, `required_conversation_resolution` documentés | ✅ **TENU** | Borne écrite l. 56-60 du rapport et reprise à `GIT_PROTECTION.md:34` |
| **3.** **Revue humaine explicite de la PR consignée (R-c)** | ❌ **NON TENU** | `gh pr view 14 --json reviews` → **`[]`** · `reviewDecision` → **`""`** · `latestReviews` → **`[]`** |

**Les deux premiers volets sont tenus. Le troisième ne l'est pas. Un critère à trois volets n'est pas
levé aux deux tiers.**

### 4.1 L'assainissement de `merge_block.md` est réel — le motif du 27 a bougé, il n'a pas disparu

Je tiens à l'écrire nettement, parce que trois FAIL consécutifs sur le même numéro pourraient laisser
croire à un enlisement : **le motif retenu aux 2ᵉ et 3ᵉ passages est corrigé.** `merge_block.md` est
aujourd'hui un rapport honnête, qui conserve son constat d'origine barré, en date, et en explicite le
renversement. C'est du bon travail.

Le 27 reste non levé sur **son troisième volet**, qui n'avait jamais été isolé jusqu'ici parce que les
volets 1 et 2 échouaient avant lui.

### 4.2 Sur la recevabilité de l'attestation de niveau 1 (question (D))

L'attestation est **honnête** : elle déclare elle-même, sans complaisance, enregistrer « la **SORTIE**
de la commande, **PAS** la **PROVENANCE** de l'acte ». Ce n'est pas de la dissimulation, et je le porte
au crédit de l'orchestrateur. **Mais l'honnêteté sur une insuffisance ne la convertit pas en
suffisance.** Trois constats d'exécution :

**(i) La commande n'a pas accompli l'acte.** Sa sortie est `! Pull request #14 was already merged`,
`exit=0`. Elle **atteste un état, pas un acte** — et un état est indifférent à la provenance. Elle ne
peut donc pas distinguer une fusion humaine d'une fusion par un agent survenue quelques instants plus
tôt. Or **c'est très exactement le défaut pour lequel le projet a rejeté `is_bot`** au 2ᵉ passage. La
méthode change de nom ; sa faiblesse épistémique est **identique**.

**(ii) Le contrôle `reflog` invoqué à l'appui n'est pas probant — je l'ai exécuté.**

```
$ git reflog --date=iso | head -4
511e02e HEAD@{2026-07-29 16:27:25}: commit: docs(us-00.7): case 34 levee — attestation humaine datee
cad24e8 HEAD@{2026-07-29 16:24:02}: checkout: moving from main to feat/US-00.7-cloture
cad24e8 HEAD@{2026-07-29 16:23:59}: merge origin/main: Fast-forward
b7128cf HEAD@{2026-07-29 16:23:50}: checkout: moving from feat/US-00.7-violation-fusion-agent to main

$ git log -1 --format="author=%an <%ae> | committer=%cn <%ce>" cad24e8
author=gitgdx <guillaume.decroix@free.Fr> | committer=GitHub <noreply@github.com>
```

Le reflog ne montre qu'un **fast-forward local** d'un `main` **déjà fusionné côté serveur** : il
enregistre une **synchronisation**, pas une décision. Et le commit de fusion porte `committer=GitHub`
avec `author=gitgdx`, compte **partagé** entre l'humain et les agents — ce que le projet a lui-même
établi. **Le reflog n'apporte donc zéro information de provenance. Cette invocation doit être retirée.**

**(iii) Un écart d'une seconde subsiste dans l'attestation** : elle s'horodate `14:19:59Z` alors que
l'API donne `mergedAt: 14:20:00Z` — la commande aurait rapporté « déjà fusionnée » **une seconde avant**
la fusion. Vraisemblablement une dérive d'horloge ou un arrondi ; **je ne l'impute pas à une
falsification**, mais dans une pièce dont c'est l'unique valeur probante, l'incohérence mérite d'être
notée.

**Recevabilité, tranchée :**

* **Comme *consignation*** — le critère écrit « consignée » — **OUI**. Une trace écrite, datée, lucide
  sur ses limites existe. L'obligation de **process** est documentée.
* **Comme *levée de critère*** — **NON.** Les 2ᵉ et 3ᵉ passages ont posé qu'« **un arbitrage ne lève
  jamais un critère** ». Le même principe vaut ici, et pour la même raison : **une déclaration ne lève
  jamais un critère de preuve.** Admettre le contraire rendrait la case 34 levable par simple écriture,
  donc non falsifiable, donc vide.

**Ce que je ne fais pas** : je ne transforme pas cela en échec de l'AC-4. **R-c est un renforcement de
*process* emprunté au track FULL, pas un AC.** Le SCB le reconnaît d'ailleurs lui-même
(l. 986-989 : « *le renforcement R-c reste une obligation de process* … *NIVEAU 2 → US-00.8* »).
**AC-4 est pleinement prouvé** par le 405 serveur et l'acceptation à 4/4. La voie de sortie proposée —
identité distincte pour les agents, reportée en US-00.8 — est la bonne ; elle ne lève simplement pas le
critère **aujourd'hui**.

---

## 5. DoD 32/34 — décompte exact, Story File incohérent

### 5.1 Le décompte est bon

```
$ grep -c "^- \[x\] \*\*[0-9]" (cases 1→34)   → 32 cochées
Décochées : 29 (QA Status — la mienne) et 31 (SCB — fin de cycle)
```

**32/34 est exact**, et les deux cases ouvertes sont légitimement ouvertes. **Aucune contestation.**

### 5.2 Mais le Story File se contredit sur quatre points

> **Action effectuée** : contrôle de cohérence interne entre les cases de tâches (T1→T24), les cases de
> DoD (1→34), et les tableaux de synthèse du Story File.
> **Résultat attendu** : un document cohérent avec lui-même.
> **Résultat obtenu** : **4 incohérences**.

| # | Incohérence | Constat |
|---|---|---|
| **a** | **T11 est `- [ ]` décochée** (l. 1090) alors que son propre corps écrit « ✅ **T11 COMPLÈTE au 2026-07-29** … ⇒ **cases 13 et 23 COCHÉES** » (l. 1117-1124) — et que les cases 13 et 23 **sont** cochées | La tâche qui a produit la preuve reste marquée non faite |
| **b** | **T24 est `- [ ]` décochée** (l. 1368) alors que `docs/adr/ADR-007-application-protection-branche.md` **existe** (51 171 o) et que la case DoD **25**, qui en dépend, est cochée | Livrable produit, tâche non cochée |
| **c** | Tableau l. 1568 : « ⏳ **Dépend de la PR** *(T11 non exécutée)* → cases **2 · 13 · 14 · 26 · 34** » | Ces **5 cases sont cochées** ; la ligne devrait avoir disparu |
| **d** | l. 1128 et 1140 affirment « **case 34 DÉCOCHÉE** » ; l. 1522 affirme « **Case 34 levée** » ; la case l. 1621 est `- [x]` | Trois états pour une même case dans un seul fichier |

Le **décompte** est donc juste, mais **le document qui le porte ne l'est pas**. Pour une US dont l'objet
même est la **cohérence du corpus** (AC-5), l'incohérence du Story File avec lui-même n'est pas un
détail de forme.

---

## 6. Critères 20 et 21 — je reprends le raisonnement, en le re-fondant

Il m'est demandé de reprendre **ou de réfuter** la position des passages 2 et 3. **Je la confirme dans
sa conclusion, mais je refuse de la reprendre par déférence** : je la re-fonde sur une preuve exécutée,
car telle qu'elle était formulée (« *ce qui évite l'échec, c'est que l'AC-3 est prouvé par ailleurs* »)
elle ressemblait à une pétition de principe — « le critère n'est pas rempli mais ce n'est pas grave ».

**Ce qui manque réellement, re-mesuré :**

```
$ grep -ci "hooksPath"  reports/US-00.7/applied_state/negative_test_server.txt   → 0
$ grep -ci "no-verify"  reports/US-00.7/applied_state/negative_test_server.txt   → 0
```

Le critère 20 exige que le clone jetable ait été **attesté** dépourvu de hooks (`git config --get
core.hooksPath` → vide). **Cette attestation n'existe pas.** Le critère 21 exige la garde de sûreté
avant **chacune** des 3 commandes ; elle figure **une fois**. Les deux critères sont bien **NON LEVÉS**.

**Pourquoi cela n'emporte pas l'échec de l'AC-3 — la raison substantielle :**

```
$ grep -c "remote:" reports/US-00.7/applied_state/negative_test_server.txt      → 10
$ grep -o "GH006[^\"]*" …/negative_test_server.txt
GH006: Protected branch update failed for refs/heads/main.
```

Le critère 20 sert à écarter une hypothèse précise : *et si le refus venait d'un hook local plutôt que
du serveur ?* Or **le préfixe `remote:` et le code `GH006` sont émis par le serveur GitHub** et sont
**impossibles à produire par un hook local** — un hook `pre-push` échoue avant tout dialogue réseau et
n'écrit jamais `remote:`. **L'hypothèse que le critère 20 avait pour fonction d'écarter est donc écartée
par une voie indépendante et plus forte.**

**Conclusion, précisée :** ce n'est pas « l'AC-3 est prouvé par ailleurs, donc passons ». C'est que
**la preuve substituée est strictement plus forte que celle qui manque**. Les critères 20 et 21 restent
**NON LEVÉS** — un arbitrage ne lève jamais un critère, et je maintiens ce principe — mais **l'AC-3
nominal est établi**, et leur non-levée ne pèse pas dans mon verdict. **Elle n'est pas un motif de ce
FAIL.**

---

## 7. Tableau des 28 critères

Légende : 🟢 avant `PUT` · 🟠 après `PUT` · 🔵 sur PR.

| # | Cond. | Verdict | Vérification (exécutée par moi, sauf mention) |
|---|---|---|---|
| 1 | 🟢 | ✅ **LEVÉ** | Faux vert d'origine archivé `[SIMULATION]` dans `nb1_fix.md` |
| 2 | 🟢 | ✅ **LEVÉ** | `nb1_harness.py` **ré-exécuté** → **exit 2**, `MAPPING INCOMPLET`, `enforce_admins = {"enabled": true}` **nommée**, « conforme » **absent** |
| 3 | 🟢 | ✅ **LEVÉ** | 12 chemins d'US-00.4 rejoués et archivés (`nb1_fix.md`) ; aucune issue changée |
| 4 | 🟢 | ✅ **LEVÉ** | Champs neutres `[IGNORÉ — NEUTRE]` visibles dans la sortie du harness ré-exécutée |
| 5 | 🟢 | ✅ **LEVÉ** | Scénarios B/C documentés en exit 0 → **NB-1bis** ouverte, sans enjolivure |
| 6 | 🟢 | ✅ **LEVÉ** | `--emit-branch-protection` **ré-exécuté** → **8 clés**, `set(payload) == MAPPED_TOP_KEYS` |
| 7 | 🟢 | ✅ **LEVÉ** | `labels_verification.md` — points de code, NFC |
| 8 | 🟢 | ✅ **LEVÉ** | `factory_sync.py --check` **ré-exécuté** → exit 0 + avertissement de portée documentaire |
| 9 | 🟢 | ✅ **LEVÉ** | Plan de retour arrière antérieur au `PUT` (ordre des commits) |
| 10 | 🟢 | ✅ **LEVÉ** | `rollback_main.md` — SHA `f4400ca`, clone miroir, 3 procédures |
| 11 | 🟢 | ✅ **LEVÉ** | `grep -nE "-X (PUT\|POST\|PATCH\|DELETE)…"` **ré-exécuté** → **rc=1**, aucun résultat |
| 12 | 🟢 | ✅ **LEVÉ** | `grep -rn "check-remote" .github/workflows/` **ré-exécuté** → **rc=1** ; contrôle négatif tenu |
| 13 | 🟢 | ✅ **LEVÉ** | `corpus_sweep.md` — 2 passes, 10 angles morts déclarés, exhaustivité **non revendiquée** |
| 14 | 🟠 | ✅ **LEVÉ** | `entry_state/` — `public`, 404, rulesets `[]`, `--check-remote` exit 1 |
| 15 | 🟠 | ✅ **LEVÉ** | `branch_main_after.json` → `"protected": true` ; `PUT` depuis payload généré |
| 16 | 🟠 | ✅ **LEVÉ** | `protection_applied.json` — 4 contextes, `enforce_admins.enabled: true` |
| 17 | 🟠 | ✅ **LEVÉ** | `check_remote_exit0_reel.txt` — exit 0 **sans** `[SIMULATION]` |
| 18 | 🟠 | ✅ **LEVÉ** | Sans objet (pas d'échec rencontré) ; issues documentées |
| 19 | 🟠 | ✅ **LEVÉ** | `negative_test_server.txt` — **`remote:` ×10**, **`GH006` ×2**, 3 refus serveur |
| 20 | 🟠 | ❌ **NON LEVÉ** *(partiel assumé)* | `grep -ci hooksPath` → **0** · `grep -ci no-verify` → **0** · suppression du clone non attestée. **§6 : n'emporte pas AC-3** |
| 21 | 🟠 | ❌ **NON LEVÉ** *(partiel assumé)* | Garde attestée **1 fois**, pas avant chacune des 3 commandes. **§6 : n'emporte pas AC-3** |
| 22 | 🟠 | ✅ **LEVÉ** | Balayage **ré-exécuté** sur les 11 artefacts : toutes les occurrences sont **historisées et datées**, ou la constante `PLAN_MARKER`, ou des négations |
| 23 | 🟠 | ✅ **LEVÉ** | `git diff --stat f4400ca..HEAD` sur US-00.4/US-00.1/ADR-006/features → **vide** · `docs/trace/` **15+/0−** (append-only) · fixtures US-00.4 **27+/0−** (additif) |
| 24 | 🟠 | ✅ **LEVÉ** | Balayage **ré-exécuté** : toutes les occurrences de « inviolable / tout est enforced / impossible à contourner / chaîne de confiance » sont des **interdictions ou des négations** |
| 25 | 🔵 | ✅ **LEVÉ** | 4 requis / 4 rapportés, libellés identiques, 5 check-runs pour 4 libellés |
| 26 | 🔵 | ✅ **LEVÉ** | `merge_refusal_server_405.txt` **relu** : HTTP **405**, « 3 of 4 required status checks are expected », `exit=1`, 1/4 vert, aucun `--admin`. Acceptation à 4/4 : `{"merged": true}` |
| 27 | 🔵 | ❌ **NON LEVÉ** | **§4.** Volets 1 et 2 **tenus** ; volet 3 **R-c** non tenu : `reviews: []`, `reviewDecision: ""`, `latestReviews: []` — seule pièce = attestation déclarative, reflog **non probant** |
| 28 | 🟢+🔵 | ✅ **LEVÉ** | **Tout ré-exécuté** : `run_gates --gate test` **2/2, 0 skipped, 89,5 %** · `--check` exit 0 · `check_scb_compliance` exit 0 · `validate_trace` conforme · aucun jeton dans `reports/US-00.7/` |

### Décompte

| Verdict | Nb | Numéros |
|---|---|---|
| ✅ **LEVÉS** | **25** | 1-19, 22-26, 28 |
| ❌ **NON LEVÉS** | **3** | **20**, **21**, **27** |

**Identique en nombre au 3ᵉ passage — mais le motif du 27 a de nouveau changé** (volets 1-2 corrigés,
volet 3 isolé), et **s'y ajoute un défaut transverse (R3-1) que la grille des 28 critères ne capture
pas** : voir §8.

---

## 8. Couverture des AC — et un angle mort de la grille

| AC | Couvert par | État |
|---|---|---|
| **AC-1** | 14, 15, 16 | ✅ **Prouvé** |
| **AC-2** | 17, 18 | ✅ **Prouvé** |
| **AC-3** | 10, 19, 20, 21 | ✅ **Nominal prouvé** (19) ; *erreur/limite* partiels (20, 21) — §6 |
| **AC-4** | 25, 26, 27 | ✅ **Nominal prouvé** (26) ; *erreur/limite* **non tenu** sur R-c (27) — §4 |
| **AC-5** | 13, 22, 23, 24 | ❌ **NON SATISFAIT** — voir ci-dessous |
| **AC-6** | 24 | ✅ **Prouvé** — dérogation éteinte aux 3 emplacements, conditionnalité écrite |
| **AC-7** | 1-6 | ✅ **Prouvé** — correctif effectif, résidu NB-1bis nommé |
| **AC-8** | 7, 8, 9 | ✅ **Prouvé** |

**Aucun AC orphelin** au sens strict : chaque AC porte au moins un critère. **Mais AC-5 souffre d'un
angle mort de couverture, et c'est lui qui explique la série de quatre échecs.**

Les 4 critères qui couvrent AC-5 testent, littéralement :

* **22** — les affirmations d'**impossibilité** (« *n'est pas protégée* », « *NON ATTEIGNABLE* », « *DETTE MAJEURE* », « *Upgrade to GitHub Pro* ») ;
* **24** — les **sur-affirmations** (« *inviolable* », « *tout est enforced* »…) ;
* **23** — la **non-réécriture** des artefacts datés ;
* **13** — la **méthode** du balayage.

**Aucun de ces quatre ne teste la classe « le corpus vivant affirme qu'une preuve désormais obtenue
manque encore ».** Ce n'est ni une impossibilité, ni une sur-affirmation : c'est une
**sous-affirmation périmée**. Les critères 22 et 24 sont donc **légitimement LEVÉS** — je ne les
détourne pas — alors même que **l'AC-5 nominal n'est pas satisfait en fait**, `CLAUDE.md` étant le
**document n° 1 que l'AC-5 nomme**.

**C'est la cause structurelle des quatre passages** : la grille ne possède pas de contrôle capable
d'attraper R3-1, donc chaque correction est validée sur les critères qu'elle vise pendant que le
défaut se déplace. **Recommandation** : ajouter à la grille un critère de **cohérence temporelle du
corpus vivant** — « aucun document vivant n'affirme l'absence d'une preuve archivée dans
`reports/US-00.7/applied_state/` » — vérifiable par balayage et **falsifiable**.

---

## 9. Edge cases testés (au-delà des cas passants)

| # | Edge case | Pourquoi | Résultat |
|---|---|---|---|
| 1 | Périmètre réel `f4400ca..HEAD` et non `main...HEAD` | Branche post-fusion : `main...HEAD` masque le périmètre | **61 fichiers** — confirmé, l'avertissement était fondé |
| 2 | Balayage **hors** des fichiers cités en (C) | Trois passages ont montré le balayage de l'orchestrateur incomplet | **2 documents vivants jamais touchés** (SQUAD_GUIDE, CLAUDE.md §État courant) |
| 3 | Balayage **dans** un fichier déclaré corrigé | Une correction partielle est plus trompeuse qu'aucune | **README.md:86** manquée |
| 4 | Assertions **à cheval sur plusieurs lignes** | `grep` est à la ligne ; le marquage aussi | **2 assertions nues** (Story 1133, 1557) |
| 5 | Classe de défaut **créée par la correction (D)** | Une correction peut engendrer sa propre classe | **Classe (d)** : `CLAUDE.md:94` |
| 6 | Contre-vérification du **reflog** invoqué en (D) | Une preuve invoquée non vérifiée n'est pas une preuve | **Non probant** — fast-forward local, `committer=GitHub` |
| 7 | Cohérence **interne** du Story File (tâches ↔ DoD ↔ tableaux) | Le décompte peut être juste et le document faux | **4 incohérences** |
| 8 | Horodatage de l'attestation vs `mergedAt` API | Pièce à valeur probante unique | **Écart de 1 s** (14:19:59 vs 14:20:00) |
| 9 | Nommage de `merge_refusal_api_raw.txt` | Un fichier « refusal » qui contient un succès | Contient `{"merged":true}` — **nom trompeur**, contenu honnête et explicité en l. 186 |
| 10 | Distinction vivant / daté appliquée **symétriquement** | Ne pas exiger la réécriture d'artefacts datés | `code_review.md`, `po_arbitrage_s11.md`, `non_regression.md`, `PROJECT_LOG` : survivances **légitimes, non retenues** |
| 11 | `git diff` sur artefacts certifiés | Vérifier qu'aucune preuve n'a été réécrite | **0 ligne** — DoD 19 tenue, aucune falsification |
| 12 | Contrôle négatif `check-remote` hors CI | Régression de périmètre | **rc=1** — tenu |

---

## 10. Ce qu'il reste à faire pour un `🧪 PASS` (sans rien réécrire de daté)

1. 🔴 **Balayer la classe (a) sur les 5 documents vivants** — les **15 lignes** du §2.1. Non pas les
   corriger une par une : **définir la classe, puis balayer**, et **publier la commande de balayage**
   avec son résultat, pour qu'un auditeur puisse la rejouer.
2. 🔴 **Traiter `CLAUDE.md` §*État courant* (l. 52-56)** — `main` = `cad24e8`, DoD **32/34**, branche
   `feat/US-00.7-cloture`, et **supprimer « Reste dû : la preuve du REFUS de fusion »**, qui contredit
   la l. 79 du même fichier.
3. 🔴 **Traiter `docs/SQUAD_GUIDE.md` (l. 41-44 et 316-318)** — document normatif lu par toute la squad,
   inscrit au critère 22, **jamais touché**.
4. 🟠 **Balayer la classe (d)** — « case 34 décochée » — au moins `CLAUDE.md:94`.
5. 🟠 **Rendre le Story File cohérent** : cocher **T11** et **T24**, retirer la ligne l. 1568,
   trancher l'état unique de la case 34.
6. 🟠 **Retirer l'invocation du `reflog`** à l'appui de la case 34 : elle n'est pas probante (§4.2 ii).
7. 🟡 **Améliorer le marqueur** : jetons distincts (`OBSOLETE:` / `RECTIFIE-EN:`), portés au niveau de
   l'**assertion** et non de la ligne.
8. 🟡 **Case 34 / critère 27** : soit assumer explicitement le **niveau 1 comme non levant** le critère
   et reporter la levée à **US-00.8** (position que je recommande, cohérente avec `SCB:986-989`), soit
   obtenir une revue GitHub formelle sur une PR à venir.

---

## 11. Rappel d'autorité (Constitution Art. 5)

Je délivre un verdict **`🧪 FAIL`**. Je n'ai **modifié ni le code, ni le SCB, ni le Story File**, je
**n'ai rien fusionné**, et je n'ai écrit que dans `reports/US-00.7/qa_reaudit3.md` — **aucun rapport QA
antérieur n'a été écrasé**. La certification `🚀 OUI` relève du rituel `/certify` (@Architect), pas de
moi.

**Note finale, adressée à l'orchestrateur.** Quatre FAIL sur une même US pourraient donner à penser que
la barre monte à chaque passage. Elle n'a pas bougé : c'est **le même défaut**, à sa **quatrième**
manifestation — *corriger là où l'on est renvoyé, plutôt que là où le défaut s'étend*. La différence,
cette fois, est qu'on peut **nommer sa cause** : la grille des 28 critères n'a **aucun contrôle**
capable de l'attraper (§8), et le marquage adopté produit une **métrique de complétude qui ne mesure
pas la complétude** (§3.1). Tant que le balayage ne sera pas **publié comme commande rejouable** plutôt
que raconté comme résultat, un 5ᵉ passage trouvera vraisemblablement une 5ᵉ classe. **Le travail de
preuve, lui, est fait** — AC-1 à AC-4 sont établis, et solidement.
