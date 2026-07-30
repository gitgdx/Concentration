# US-00.7 — Rapport QA, 5ᵉ passage (re-audit 4) — @QA_Tester

| Champ | Valeur |
|---|---|
| **US** | US-00.7 — Protection de la branche principale : application effective, preuve par l'effet, mise en cohérence du corpus |
| **Agent** | @QA_Tester — **contexte frais** |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-07-30 |
| **Branche** | `feat/US-00.7-cloture` — HEAD **`dcc198c`**, 3 commits d'avance sur `origin/main` = **`cad24e8`**, **non poussée** |
| **Pré-conditions** | `validate_trace.py --us US-00.7` → **exit 0, « Traçabilité conforme »** · `EVT_CODE_REVIEW_PASSED` **×1** et `EVT_SECURITY_AUDIT_PASSED` **×1** présents *(décompte des événements ci-dessous)* |
| **Rapports antérieurs** | `qa.md` · `qa_reaudit.md` · `qa_reaudit2.md` · `qa_reaudit3.md` — **aucun écrasé, aucun modifié** |
| **Nouveauté auditée** | `c419a9e` *(passes 3 et 4 du balayage, 41 marqueurs, retrait du contrôle reflog)* et `dcc198c` *(arbitrage humain du critère 27)* |

---

## 0. VERDICT

# 🧪 FAIL

**Cinquième échec.** Je n'y arrive pas de bon cœur, et je commence par ce qui est acquis, parce que
c'est considérable et que quatre FAIL pourraient le faire oublier.

### Ce que je valide, par exécution, sans réserve

* **AC-1 → AC-4 sont établis et solides.** Le refus de fusion **vient du serveur** (HTTP 405), la
  protection est **appliquée** (`"protected": true` relu aujourd'hui), les 3 refus d'écriture directe
  portent **`remote:` ×10** et **`GH006` ×3**.
* **Les 5 gates passent** : `run_gates.py` → **exit 0, 5 gates exécutés** · tests **2 passed / 0 skipped /
  0 failed** · couverture **89,5 %** ≥ 80 % · `gitleaks` → **0 fuite sur 64 commits**.
* **Toute la gouvernance est verte** : `factory_sync --check`, `check_scb_compliance`, `validate_trace`.
* **Le travail du 4ᵉ round est en majorité réel** : **14 des 15** survivances que j'avais listées en
  `qa_reaudit3.md` sont **effectivement traitées** — `CLAUDE.md` §*État courant* est **entièrement**
  rectifié *(y compris sa contradiction interne avec sa propre l. 79)*, `docs/SQUAD_GUIDE.md` est
  **enfin** touché aux deux endroits, `README.md:86` est corrigé, **T11 et T24 sont cochées**, le
  Story File est cohéré, et le **contrôle `reflog` non probant a été retiré** — retrait explicite,
  assumé, auto-critique. **C'est du travail honnête.**
* **L'arbitrage du critère 27 est bien construit** : sa base factuelle est **vraie**, je l'ai vérifiée
  à la source, et il ne coche **rien** de plus. **Je le déclare recevable** (§5).

### Ce qui échoue

Le défaut est **le même qu'au 4ᵉ passage, à sa 5ᵉ manifestation** — mais cette fois je peux
l'établir **sans aucune interprétation**, parce que **le round s'est fixé lui-même son critère de
réussite et que ce critère est faux par son propre outil** :

> Message de commit `c419a9e`, dernière ligne du corps :
> **« 41 marqueurs. **0 occurrence non marquée sur les 11 artefacts vivants**. »**
>
> Et `corpus_sweep.md`, additif du 2026-07-29, §*Deux leçons de méthode* :
> **« Méthode : définir la classe → balayer tout le corpus → **vérifier par l'outil que 0 occurrence
> subsiste non marquée**. »**

**J'ai appliqué exactement cette méthode, avec exactement cet outil. Elle rend 2, pas 0** — dans **2
des 11 artefacts nommément énumérés par le critère 22**. Et **une survivance que j'avais citée
nommément au 4ᵉ passage, et que le message de commit déclare corrigée, est byte-identique**.

| Question | Réponse |
|---|---|
| Grille des 28 critères | **25 LEVÉS / 3 NON LEVÉS** (20, 21, 27) — **inchangé** (§6) |
| Critères 20, 21, 27 non levés par arbitrage : **recevable pour un PASS de la case 29 ?** | ✅ **OUI, recevable** — et ce n'est **pas** mon motif de FAIL (§5) |
| DoD | **32/34 — décompte exact**, cases ouvertes **29** (moi) et **31** (fin de cycle) (§7) |
| Classe de défaut du 4ᵉ FAIL réellement close ? | ❌ **NON** — **6 lignes / 5 assertions / 4 documents vivants** (§3) |
| AC orphelins | **AUCUN** (§8) |

---

## 1. Exécutions — aucune affirmation de ce rapport n'est sans commande

### 1.1 Pré-conditions (refus si absentes)

```
$ python scripts/validate_trace.py --us US-00.7
Traçabilité conforme.                                                   exit=0

$ grep -o '"event": "EVT_[A-Z_]*"' docs/trace/US-00.7/events.jsonl | sort | uniq -c
      1 EVT_ARCHI_VALIDATED        1 EVT_STORY_CREATED
      2 EVT_CODE_READY             1 EVT_STORY_READY
      1 EVT_CODE_REVIEW_PASSED  ←  1 EVT_TRACK_SELECTED
      1 EVT_DESIGN_COMPLETED       1 EVT_WORKFLOW_VIOLATION
      1 EVT_DEV_BLOCKER            1 EVT_SECURITY_AUDIT_FAILED
      4 EVT_QA_FAILED              1 EVT_SECURITY_AUDIT_PASSED  ←
```

**Pré-conditions satisfaites.** Je peux auditer.

### 1.2 Gate de test et couverture — décompte exact (Constitution Art. 3)

```
$ python scripts/run_gates.py --gate test
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:00 +0: affiche le titre du squelette
00:00 +1: incrémente le compteur au tap
00:01 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test        Tous les gates bloquants passent (1 exécutés).        exit=0
```

| Suite | Passed | **Skipped** | Failed | **Non exécutés** | Total |
|---|---|---|---|---|---|
| Unitaires `flutter test` | **2** | **0** | **0** | 0 | **2** |
| **E2E BDD** | **0** | **0** | **0** | **24** | **24** |
| **TOTAL** | **2** | **0** | **0** | **24** | **26** |

**Sur les 24 scénarios Gherkin — je les compte, et je refuse de les compter comme verts.**
`tests/features/US-00.7-application-protection-branche.feature` porte **24 scénarios**.
Vérifié : **aucun répertoire de step definitions**, **aucun runner BDD dans `pubspec.yaml`**.
Ils sont **documentaires** : `0` exécuté. Un scénario non exécuté n'est **ni passed, ni skipped** — il
n'apporte **aucune preuve**. Je le mets dans une colonne à part pour qu'on ne puisse pas le lire de
travers.

**Couverture : 89,5 % (17/19) ≥ 80 % → conforme.**
⚠️ **Portée honnête, inchangée depuis 4 passages** : cette couverture porte sur le **squelette
Flutter** et **0 fichier Dart n'est modifié** par US-00.7. Elle atteste une **non-régression**, elle ne
valide **rien** du livrable.

### 1.3 Les 5 gates, la gouvernance, la sécurité

```
$ python scripts/run_gates.py                → Tous les gates bloquants passent (5 exécutés).  exit=0
   ✅ app.format  ✅ app.lint  ✅ app.test  ✅ app.deps_audit  ✅ app.build
$ python scripts/factory_sync.py --check     → Synchro factory conforme (vérification DOCUMENTAIRE)  exit=0
   + [AVERTISSEMENT] l'état RÉEL de la protection n'est PAS vérifié ici  ← portée annoncée, correct
$ python scripts/check_scb_compliance.py     → SCB conforme — Aucune violation détectée.       exit=0
$ python scripts/validate_trace.py --us US-00.7  → Traçabilité conforme.                       exit=0
$ gitleaks detect --source . --no-banner     → 64 commits scanned · no leaks found
```

⛔ **`--check-remote` non employé** : hors CI il exige des droits admin ; le contrôle négatif
`grep -rn "check-remote" .github/workflows/` → **rc=1** confirme qu'il n'a **pas** été glissé en CI.

### 1.4 État réel du dépôt (lecture seule stricte)

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{protected:.protected}'
{"protected": true}

$ git ls-remote origin refs/heads/main
cad24e8acfc04ff620a21232213c691f60b50a6a	refs/heads/main

$ gh pr view 14 --json reviewDecision,latestReviews,reviews,state,mergedBy
{"latestReviews":[],"mergedBy":{"is_bot":false,"login":"gitgdx"},
 "reviewDecision":"","reviews":[],"state":"MERGED"}

$ gh api repos/gitgdx/Concentration/collaborators --jq '.[].login'
gitgdx                                  ← UN SEUL collaborateur : base de l'arbitrage, VÉRIFIÉE
```

### 1.5 Le refus de fusion — je le confirme, il est prouvé

```
$ cat reports/US-00.7/applied_state/merge_refusal_server_405.txt
# gh api -X PUT repos/gitgdx/Concentration/pulls/14/merge -f merge_method=merge
# Horodatage UTC : 2026-07-29T08:49:14Z | contextes verts au moment de l appel : 1/4
# Aucun --admin, aucune regle desactivee, aucun contexte retire.
gh: 3 of 4 required status checks are expected. (HTTP 405)
{"message":"3 of 4 required status checks are expected.",...,"status":"405"}   exit=1
```

`gh api` est un transport HTTP : le **405 est serveur**. **Critère 26 LEVÉ, D-1 refermé.** Sans réserve.

---

## 2. Fait nouveau que j'établis, et que personne n'a encore consigné : **Q-1 et N-5 sont clos**

Ce n'est pas un reproche, c'est un **acquis non enregistré** — et il aggrave le §3, parce qu'il
étend la classe de défaut d'un cran supplémentaire.

> **Action effectuée** : déterminer si le `ci.yml` corrigé a réellement tourné en CI.
>
> ```
> $ git log --oneline --follow -- .github/workflows/ci.yml | head -2
> 1424d03 docs(us-00.7): N-1 traite — 4e ligne au plan de retour arriere
> 9465116 fix(us-00.7): B-1 injection de commande dans branch-naming + actionlint en CI
>
> $ git merge-base --is-ancestor 1424d03 origin/main && echo OUI
> OUI                          ← le ci.yml corrigé EST sur main
>
> $ git log --first-parent --oneline origin/main | head -3
> cad24e8 Merge pull request #14 …   b7128cf Merge pull request #13 from gitgdx/feat/US-00.7-certif
>
> $ gh pr checks 13
> check-branch-name                              pass
> 📋 Governance (SCB + traçabilité + synchro)     pass
> 📱 App (gates run_gates.py)                     pass       ← 1m11s
> 🔐 Secrets scan (gitleaks)                      pass
> ```
>
> **Résultat obtenu** : la **PR #13 est issue de `feat/US-00.7-certif`** — la branche **même** qui
> portait le `ci.yml` corrigé — et **les 4 contextes requis y sont PASS en CI réelle**.

⇒ **La « PR de certification depuis `feat/US-00.7-certif` » n'est pas à venir : c'est la PR #13, déjà
fusionnée.** Les workflows corrigés **ont tourné**. **Q-1 et N-5 sont clos en fait.**

C'est précisément ce que le corpus vivant continue d'annoncer comme **à faire** (§3, survivance S3).

---

## 3. DÉFAUT BLOQUANT — R4-1 : la classe du 4ᵉ FAIL n'est pas close, et le critère de clôture que le round s'est donné est faux

> **Action effectuée** → **Résultat attendu** → **Résultat obtenu**

### 3.1 Le contrôle, tel que le round l'a lui-même prescrit

> **Action effectuée** : appliquer **littéralement** la méthode publiée par l'additif du
> 2026-07-29 à `corpus_sweep.md` — « *définir la classe → balayer tout le corpus → vérifier par
> l'outil que 0 occurrence subsiste non marquée* » — sur les **11 artefacts vivants énumérés par le
> critère 22**, avec le motif de la classe (a) *sous-affirmation périmée* :
>
> ```
> $ for f in <les 11 artefacts du critère 22>; do
>     grep -nE "pas encore été observ|n'a pas été observ|pas encore prouvé|n'est pas prouvé|
>               n'a pas eu lieu|non exécutée|reste une inférence|n'en est pas la preuve" "$f" \
>     | grep -v "PÉRIMÉ-2026-07-29"
>   done
> ```
>
> | Artefact vivant (critère 22) | occ. | marqueurs | **NON MARQUÉES** |
> |---|---|---|---|
> | `CLAUDE.md` | 0 | 1 | **0** |
> | `docs/epics/EPIC_00-fondations.md` | 0 | 0 | **0** |
> | **`docs/GIT_PROTECTION.md`** | 2 | 2 | 🔴 **1** |
> | **`.github/workflows/ci.yml`** | 1 | **0** | 🔴 **1** |
> | `scripts/apply_branch_protection.sh` | 0 | 0 | **0** |
> | `scripts/check_branch_protection.py` | 0 | 0 | **0** |
> | `.claude/commands/audit-methodo.md` | 0 | 0 | **0** |
> | `.claude/commands/sprint-status.md` | 0 | 0 | **0** |
> | `docs/SQUAD_GUIDE.md` | 2 | 5 | **0** ✅ *(réellement corrigé)* |
> | `tests/fixtures/US-00.4/README.md` | 0 | 0 | **0** |
> | `scripts/githooks/pre-push` | 0 | 0 | **0** |
> | **TOTAL** | | | 🔴 **2** |
>
> **Résultat attendu**, d'après le message de commit `c419a9e` : **`0`**.
>
> **Résultat obtenu** : **`2`**, dans **2 des 11 artefacts explicitement énumérés**.

**Ce n'est pas un désaccord d'interprétation.** Le critère de réussite a été fixé par le round
lui-même, la liste des fichiers est **close et énumérée** par le critère 22, le motif est celui du
round précédent, l'outil est celui que la méthode prescrit. **Le contrôle rend 2. Il devait rendre 0.**

### 3.2 Le balayage complet — extension de la classe sur tout le corpus vivant

J'étends le corpus vivant aux **13** documents qui dirigent un lecteur futur : les **11** du critère
22 + le **SCB** + l'**index** `reports/US-00.7/README.md`. *(Le Story File est traité au §7 : il
contient légitimement des blocs datés conservés.)* J'élargis le motif à la classe **(d)** *état de
décision périmé*, ajoutée par la passe 4.

**Commande de balayage — publiée, rejouable, et c'est mon critère de sortie (§9) :**

```sh
VIVANTS="CLAUDE.md docs/epics/EPIC_00-fondations.md docs/GIT_PROTECTION.md .github/workflows/ci.yml
scripts/apply_branch_protection.sh scripts/check_branch_protection.py .claude/commands/audit-methodo.md
.claude/commands/sprint-status.md docs/SQUAD_GUIDE.md tests/fixtures/US-00.4/README.md
scripts/githooks/pre-push STORY_CERTIFICATION_BOARD.md reports/US-00.7/README.md"

MOTIF="pas encore été observ|n'a pas été observ|pas encore prouvé|n'est pas prouvé|n'a pas eu lieu|\
non exécutée|Non exécuté|reste une inférence|n'en est pas la preuve|encore obtenable|\
jamais passés en CI|CHEMIN DE SORTIE|referme \*\*D-1|referme D-1|ciblé sur le seul critère"

for f in $VIVANTS; do [ -f "$f" ] && grep -nE "$MOTIF" "$f" | grep -v "PÉRIMÉ-2026-07-29" \
  | sed "s|^|$f:|"; done
```

**Sortie obtenue — 7 lignes, dont 6 fautives :**

```
1  docs/GIT_PROTECTION.md:277:> **pas encore été observé** sur ce dépôt (tâche **T11** d'US-00.7) …
2  .github/workflows/ci.yml:13:#    encore été observé (tâche T11 d'US-00.7) : … il n'en est pas la preuve.
3  STORY_CERTIFICATION_BOARD.md:268:  déblocage et **non exécutées**. Livrables : …      ← ⚪ LÉGITIME
4  STORY_CERTIFICATION_BOARD.md:1015:- **🎯 CHEMIN DE SORTIE — UN SEUL GESTE.** La **PR de certification** …
5  STORY_CERTIFICATION_BOARD.md:1016:  **(a)** exécutera les workflows corrigés **jamais passés en CI** …
6  STORY_CERTIFICATION_BOARD.md:1017:  **(b)** rouvrira la **fenêtre de ~80 s** nécessaire au **refus de fusion** …
7  reports/US-00.7/README.md:26:| ⛔ **Non exécuté** | **T11** (PR · libellés rapportés · refus de fusion …
```

**La ligne 3 est écartée par moi comme LÉGITIME** : c'est l'entrée **datée d'US-00.4** au SCB
(« T16→T19 non exécutées »), **exacte à sa date**, et que la **DoD 19** / l'**AC-5 *erreur*** m'interdisent
d'exiger qu'on réécrive. **Je maintiens la distinction vivant/daté dans les deux sens** — c'est la même
qui m'a fait écarter `code_review.md`, `security.md`, `po_arbitrage_s11.md`, `non_regression.md` et
`PROJECT_LOG.md` du décompte.

### 3.3 Les 5 assertions retenues, et pourquoi chacune compte

| # | Fichier vivant | Ligne | Assertion survivante, **non marquée** | Statut au 4ᵉ passage |
|---|---|---|---|---|
| **S1** | **`.github/workflows/ci.yml`** | **12-13** | « ⚠️ BORNE : le refus PROUVÉ porte sur le PUSH DIRECT. **Le refus d'une tentative de FUSION n'a pas encore été observé** (tâche T11 d'US-00.7) : il découle de l'état constaté, **il n'en est pas la preuve**. » | ❌ **jamais cité, jamais touché** |
| **S2** | **`docs/GIT_PROTECTION.md`** | **276-278** | « Le **refus effectif d'une tentative de fusion** n'a **pas encore été observé** sur ce dépôt (tâche **T11**) — **à lire comme une inférence documentée, pas comme une preuve**. » | ❌ **jamais cité, jamais touché** |
| **S3** | **`STORY_CERTIFICATION_BOARD.md`** | **1015-1020** | « 🎯 **CHEMIN DE SORTIE — UN SEUL GESTE.** La **PR de certification** depuis `feat/US-00.7-certif` **(a)** exécutera les workflows corrigés **jamais passés en CI** *(referme Q-1/N-5)* **et (b)** rouvrira la **fenêtre de ~80 s** nécessaire au **refus de fusion** *(referme **D-1**)* … Le re-passage QA pourra être **ciblé sur le seul critère 26**. » | 🔴 **CITÉ (item #10) et DÉCLARÉ CORRIGÉ** |
| **S4** | **`STORY_CERTIFICATION_BOARD.md`** | **1021** | « **Prochaine étape** : PR de certification → **capture du refus (D-1)** → re-QA ciblée → `/certify`. » | 🔴 **même bloc** |
| **S5** | **`reports/US-00.7/README.md`** | **26** | tableau de synthèse en tête : « ⛔ **Non exécuté** \| **T11** (PR · libellés rapportés · **refus de fusion** · fusion après 4 verts) » | ❌ **3ᵉ round de correction partielle du même fichier** |

### 3.4 Preuve matérielle que S3/S4 ne relèvent PAS de la non-exhaustivité, mais d'une correction annoncée et non faite

C'est le point qui rend ce FAIL différent des quatre précédents, et **indiscutable**.

Le message de commit `c419a9e` écrit : « Corrigés : … **SCB:628,710,991** … ». Or **la ligne 991 du SCB
dans la version que j'auditais au 4ᵉ passage (`511e02e`) est exactement le bloc *CHEMIN DE SORTIE*** —
c'est mon item **#10**. Vérification :

```
$ git show 511e02e:STORY_CERTIFICATION_BOARD.md | sed -n '991,997p' | md5sum
167ed8fdae3f1664efec9129d3e5e81d  -
$ sed -n '1015,1021p' STORY_CERTIFICATION_BOARD.md | md5sum
167ed8fdae3f1664efec9129d3e5e81d  -          ← IDENTIQUE OCTET POUR OCTET

$ git blame -L 1015,1021 -- STORY_CERTIFICATION_BOARD.md
2a156168 (gitgdx 2026-07-28)  ← 7 lignes sur 7, aucune touchée depuis le 28
```

**Les hachages sont identiques. Le bloc déclaré corrigé n'a pas été effleuré.**

⚠️ **Distinction que je pose nettement, parce qu'elle est le cœur du verdict.** L'US **ne revendique
pas** l'exhaustivité de son balayage — c'est écrit, c'est légitime, et **c'est pourquoi je maintiens le
critère 13 LEVÉ**. Cette réserve couvre **ce qu'on ne trouve pas**. Elle **ne couvre pas** :

* une occurrence dans un fichier **nommément énuméré** par le critère (S1 : `ci.yml` est l'item n° 4 de
  la liste du critère 22), atteignable par le **même motif** que le round précédent ;
* une occurrence **citée nommément par la QA** et **déclarée corrigée** (S3/S4).

**Déclarer corrigé ce qui n'a pas été touché n'est pas une limite de balayage : c'est une
sur-affirmation** — la classe même que l'AC-5 *erreur* nomme (« *affirmer plus que ce qui est
prouvé* »), appliquée cette fois **au balayage lui-même**.

### 3.5 Gravité — pourquoi ce ne sont pas quatre lignes anodines

**S1 et S2 sont les deux emplacements de plus fort trafic pour le fait même que cette US existe pour
prouver.**

* **S2** est l'en-tête de statut du § *Conditions de fusion désormais ACTIVES* de
  `docs/GIT_PROTECTION.md` — **la section que `CLAUDE.md` désigne comme la référence** (« *Détail :
  `docs/GIT_PROTECTION.md` §Conditions de fusion* »). `GIT_PROTECTION.md` est le **document n° 3
  nommé par l'AC-5 nominal**. Le fichier **se contredit lui-même** : l. 22 en capitales « **LE REFUS DE
  FUSION EST DÉSORMAIS PROUVÉ, PAR LE SERVEUR** » ; l. 277 « **pas encore été observé** … à lire comme
  une inférence, pas comme une preuve ». **C'est la signature exacte du défaut du 4ᵉ passage
  (`CLAUDE.md` l. 55 vs l. 79), déplacée d'un fichier.**
* **S1** est dans `.github/workflows/ci.yml`, **artefact vivant n° 4 du critère 22**. Et l'omission n'a
  **aucune excuse de permission** : `git blame` montre que **cette phrase a été écrite par US-00.7
  elle-même** (`fbd0e3c`, T15 « *ci.yml — en-tête seul* »), et `.claude/hooks/protect_files.sh` **ne
  protège pas** `.github/workflows/*` *(la dette de périmètre Art. 6 le dit déjà)*. **La tâche qui a
  écrit la phrase est celle qui devait la corriger.**
* **S3/S4** sont la **route de sortie officielle** inscrite au SCB. Elles envoient un lecteur futur
  **refaire une PR déjà fusionnée** (#13), pour **fermer des findings déjà fermés** (Q-1/N-5 — §2), et
  **capturer un refus déjà capturé** (D-1), puis lancer une QA « **ciblée sur le seul critère 26** »,
  lequel est **levé depuis deux passages**. Dans un dépôt piloté par le SCB, c'est l'assertion la plus
  dommageable de la liste.
* **S5** fait que `reports/US-00.7/README.md` **se contredit à 60 lignes d'intervalle** : l. 26
  « T11 **non exécuté** » contre l. 86 « T11 ✅ **PÉRIMÉ-2026-07-29 : EXÉCUTÉE** ». C'est le **troisième
  round consécutif** où ce fichier est corrigé **à la ligne citée** et **pas à sa jumelle** (l. 44 puis
  l. 184, puis l. 86 — jamais l. 26). L'argument écrit par le round lui-même à la l. 184 — « *un index
  n'a pas de date : il décrit ce qui EST* » — s'applique **mot pour mot** à la l. 26.

### 3.6 Le procédé de marquage : jugement révisé — le progrès est réel

Je reviens sur la sévérité du 4ᵉ passage. **Le marqueur littéral fonctionne** : il est **auditable**,
et c'est **grâce à lui** que j'ai pu produire le tableau du §3.1 en une commande — impossible avec
`~~texte~~`. **48 occurrences** dans le corpus, dont **44 hors rapports QA**. Sur `docs/SQUAD_GUIDE.md`,
**5 marqueurs pour 2 occurrences** : le fichier est **sur-marqué**, donc réellement traité.

**Le défaut n'est plus le marqueur. Il est que le décompte de marqueurs ait été présenté comme
équivalent au décompte d'occurrences restantes.** Compter 41 marqueurs mesure ce qu'on a fait ;
seul le balayage du §3.1 mesure ce qui reste. Le round a publié la **bonne méthode** dans son additif
et a **rapporté la mauvaise métrique** dans son commit.

---

## 4. Ce qui a été réellement corrigé — vérifié pièce par pièce

Je le consigne parce qu'un FAIL qui n'énumère que les manques est un FAIL malhonnête.

| Item du 4ᵉ passage | État vérifié aujourd'hui |
|---|---|
| 1-4 · `CLAUDE.md:53-56` (`main`, DoD, branche, « Reste dû ») | ✅ **CORRIGÉ** — l. 53-57 : `main` = **`cad24e8`**, **DoD 32/34**, branche **`feat/US-00.7-cloture`**, « Reste dû : **la QA (case 29)** ». Contradiction avec la l. 79 **levée** |
| 5 · `CLAUDE.md:94` « case 34 décochée » | ✅ **CORRIGÉ** — marqueur + « **RECOCHÉE** » sur la ligne |
| 6-7 · `docs/SQUAD_GUIDE.md:41-44`, `:316-318` | ✅ **CORRIGÉ** — 2 occurrences, **5 marqueurs** |
| 8 · `SCB:627-629` | ✅ **CORRIGÉ** (l. 628) |
| 9 · `SCB:710` | ✅ **CORRIGÉ** — « **preuve OBTENUE** (PR #14, HTTP 405) » |
| **10 · `SCB:991-996` (CHEMIN DE SORTIE)** | ❌ **NON CORRIGÉ** — **byte-identique** (§3.4) |
| 11 · `README.md:86` | ✅ **CORRIGÉ** — mais **l. 26 manquée** (S5) |
| 12 · Story File T11 décochée | ✅ **CORRIGÉ** — `- [x] **T11**` (l. 1090) |
| 13-14 · Story 1133, 1557 | ✅ **CORRIGÉ** — marqueurs **sur la ligne** |
| 15 · Story 1568 | ✅ **CORRIGÉ** — « *PÉRIMÉ-2026-07-29 : T11 **exécutée*** » |
| T24 décochée | ✅ **CORRIGÉ** — `- [x] **T24**` (l. 1368) |
| Retrait du contrôle `reflog` | ✅ **FAIT** — `SCB:984-992`, retrait **explicite**, avec l'auto-critique. **Aucun** document vivant n'invoque plus le `reflog` comme preuve *(vérifié : 3 occurrences, toutes dans le paragraphe de retrait)* |
| Passes 3 et 4 ajoutées au balayage | ✅ **FAIT** — additif **daté**, corps du 2026-07-28 **non réécrit** |

**14 items sur 15 tenus. Le 15ᵉ est celui qui échoue, et c'est celui qui était cité nommément.**

---

## 5. Question posée : les critères 20, 21 et 27 non levés par arbitrage sont-ils **recevables** pour un PASS de la case 29 ?

**Réponse : OUI, recevables. Et je ne requalifie rien.** Les trois restent **NON LEVÉS** dans mon
tableau — « *un arbitrage ne lève jamais un critère* », doctrine que je reprends et applique.
**Aucun d'eux n'est un motif de ce FAIL.** Voici pourquoi, re-fondé sur exécution et non sur déférence.

### 5.1 Critères 20 et 21 — recevables

> **Action effectuée** : re-mesurer ce qui manque, dans le fichier que les critères nomment.
> ```
> $ F=reports/US-00.7/applied_state/negative_test_server.txt
> $ grep -ci hooksPath "$F"     → 0        $ grep -ci "autre acteur" "$F"   → 0
> $ grep -ci no-verify "$F"     → 0        $ grep -ci "jeton d" "$F"        → 0
> $ grep -ci rev-parse "$F"     → 0        $ grep -ci "interface web" "$F"  → 0
> $ grep -c  Garde "$F"         → 1  (le critère 21 en exige 3)
> ```
> **Résultat obtenu** : les deux critères sont bien **NON LEVÉS**. Rien n'a été fabriqué pour les
> sauver — **et c'est à porter au crédit du projet** : le clone jetable n'existe plus, y ajouter
> aujourd'hui une garde non relue trois fois serait **falsifier une preuve**.

**Pourquoi cela n'emporte pas l'AC-3 — raison substantielle, ré-exécutée :**

```
$ grep -c "remote:" "$F"  → 10        $ grep -c "GH006" "$F"  → 3
GH006: Protected branch update failed for refs/heads/main.
```

Le critère 20 existe pour écarter **une** hypothèse : *et si le refus venait d'un hook local ?* Or le
préfixe **`remote:`** et le code **`GH006`** sont émis par **le serveur GitHub** et sont **impossibles
à produire par un hook `pre-push`**, qui échoue **avant tout dialogue réseau** et n'écrit jamais
`remote:`. **La preuve substituée est strictement plus forte que celle qui manque.** AC-3 nominal est
établi ; la non-levée de 20/21 ne pèse pas.

### 5.2 Critère 27 — recevable, et l'arbitrage est bien construit

**J'ai vérifié la base factuelle à la source, je ne l'ai pas prise pour argent comptant :**

```
$ gh api repos/gitgdx/Concentration/collaborators --jq '.[].login'   → gitgdx      (UN SEUL)
$ gh pr view 14 --json reviewDecision,reviews,latestReviews
  {"reviewDecision":"","reviews":[],"latestReviews":[]}
$ python scripts/factory_sync.py --emit-branch-protection
  required_pull_request_reviews: {'required_approving_review_count': 0}
```

**Les trois faits sont vrais.** Un dépôt à un seul collaborateur, GitHub interdisant à l'auteur
d'approuver sa propre PR ⇒ `reviewDecision` et `reviews` sont **structurellement vides**. Exiger `1`
approbation rendrait **toute fusion impossible** — l'arbitrage d'US-00.4 est cohérent.

| Volet du critère 27 | Verdict | Vérification |
|---|---|---|
| 1. Aucun `--admin`, aucun contexte retiré, aucune règle désactivée | ✅ **TENU** | `merge_refusal_server_405.txt` l. 4, relu ce jour |
| 2. `expected` ≠ rouge ; `strict` et `required_conversation_resolution` documentés | ✅ **TENU** | Bornes écrites, `GIT_PROTECTION.md` §Conditions de fusion |
| 3. **Revue humaine explicite consignée (R-c)** | ❌ **NON TENU / NON TENABLE** | `reviews: []` — impossibilité de **plateforme**, vérifiée |

**Recevable pour un PASS de la case 29, pour quatre raisons cumulatives :**

1. **R-c est un renforcement de *process* emprunté au track FULL, pas un AC.** **AC-4 est pleinement
   prouvé** par le serveur : refus **HTTP 405** à 1/4 **et** acceptation `{"merged": true}` à 4/4.
   Aucun AC ne dépend du volet 3.
2. **La cause est la plateforme, pas le travail** — et c'est **vérifié**, pas allégué.
3. **L'arbitrage ne coche RIEN.** J'ai contrôlé : **DoD toujours 32/34**, critère 27 toujours **NON
   LEVÉ**, la doctrine « un arbitrage ne lève jamais un critère » est **citée et respectée** dans le
   texte de l'arbitrage lui-même. C'est **exactement** la bonne forme — l'inverse d'une complaisance.
4. **Précédent constant du projet** : même classe que le `403` d'US-00.4 et que les critères 20/21. Une
   impossibilité de plateforme se règle par un **arbitrage humain tracé**, pas par un cycle de plus.
   **La levée réelle est versée à US-00.8** (identité distincte pour les agents + `restrictions`).

⛔ **Ce que je refuse quand même** : que la **case 34** soit tenue pour *prouvée*. L'attestation
niveau 1 est **honnête et recevable comme *consignation*** — le critère écrit « consignée » — mais elle
enregistre un **état** (« *was already merged* »), **pas un acte**. Comme **levée de preuve de
provenance**, **non**. Le SCB l'écrit lui-même (« *assumée DÉCLARATIVE* », « *NIVEAU 2 → US-00.8* »), et
c'est la bonne position. **Ce point n'est pas un motif de FAIL** : il est correctement borné.

---

## 6. Grille des 28 critères de test — décompte

Légende : 🟢 avant `PUT` · 🟠 après `PUT` · 🔵 sur PR. **Tout ce qui est marqué « ré-exécuté » l'a été
par moi ce jour.**

| # | Cond. | Verdict | Vérification |
|---|---|---|---|
| 1 | 🟢 | ✅ **LEVÉ** | Faux vert d'origine archivé `[SIMULATION]` dans `nb1_fix.md` |
| 2 | 🟢 | ✅ **LEVÉ** | `nb1_harness.py` **ré-exécuté** → **exit 2**, `MAPPING INCOMPLET`, `enforce_admins = {"enabled": true}` **nommée**, « conforme » **absent** |
| 3 | 🟢 | ✅ **LEVÉ** | 12 chemins d'US-00.4 rejoués, archivés ; aucune issue changée |
| 4 | 🟢 | ✅ **LEVÉ** | `[IGNORÉ — NEUTRE]` visible dans la sortie **ré-exécutée** (6 champs neutres nommés) |
| 5 | 🟢 | ✅ **LEVÉ** | Scénarios B/C en exit 0 documentés → **NB-1bis** ouverte, sans enjolivure |
| 6 | 🟢 | ✅ **LEVÉ** | `--emit-branch-protection` **ré-exécuté** → **8 clés**, `required_pull_request_reviews` **présent avec 0**, `restrictions: null`, `strict: true`, **4** contextes |
| 7 | 🟢 | ✅ **LEVÉ** | `labels_verification.md` — points de code, NFC |
| 8 | 🟢 | ✅ **LEVÉ** | `factory_sync --check` **ré-exécuté** → exit 0 **+ avertissement de portée documentaire** |
| 9 | 🟢 | ✅ **LEVÉ** | Plan de retour arrière antérieur au `PUT` (ordre des commits) |
| 10 | 🟢 | ✅ **LEVÉ** | `rollback_main.md` — SHA `f4400ca`, clone miroir, 3 procédures |
| 11 | 🟢 | ✅ **LEVÉ** | `grep -nE "-X (PUT\|POST\|PATCH\|DELETE)…"` **ré-exécuté** → **rc=1** — lecture seule préservée |
| 12 | 🟢 | ✅ **LEVÉ** | `grep -rn "check-remote" .github/workflows/` **ré-exécuté** → **rc=1** ; contrôle négatif tenu |
| 13 | 🟢 | ✅ **LEVÉ** | `corpus_sweep.md` : **4 passes** désormais, angles morts déclarés, **exhaustivité non revendiquée**. ⚠️ *La méthode est bonne ; c'est son **application** qui échoue (§3) — je ne détourne pas ce critère* |
| 14 | 🟠 | ✅ **LEVÉ** | `entry_state/` — `public`, 404, rulesets `[]`, `--check-remote` exit 1 |
| 15 | 🟠 | ✅ **LEVÉ** | `branch_main_after.json` → `"protected": true` ; `PUT` depuis payload **généré** |
| 16 | 🟠 | ✅ **LEVÉ** | `protection_applied.json` — 4 contextes, `enforce_admins.enabled: true` |
| 17 | 🟠 | ✅ **LEVÉ** | `check_remote_exit0_reel.txt` — exit 0 **sans** `[SIMULATION]` |
| 18 | 🟠 | ✅ **LEVÉ** | Sans objet (aucun échec rencontré) ; issues documentées |
| 19 | 🟠 | ✅ **LEVÉ** | **Ré-exécuté** : `remote:` **×10**, `GH006` **×3**, 3 refus serveur |
| 20 | 🟠 | ❌ **NON LEVÉ** *(arbitré, partiel assumé)* | `hooksPath`→0 · `no-verify`→0 · `rev-parse`→0. **§5.1 : recevable, n'emporte pas AC-3** |
| 21 | 🟠 | ❌ **NON LEVÉ** *(arbitré, partiel assumé)* | Garde ×**1** (3 exigées) · portée absente du fichier nommé. **§5.1 : recevable** |
| 22 | 🟠 | ✅ **LEVÉ** | Passe 1 **rejouée** sur les 11 artefacts : **aucune** affirmation d'**impossibilité** ni de **dette majeure d'enforcement**. ⚠️ **Je maintiens ce critère LEVÉ en toute rigueur** : sa lettre porte sur l'impossibilité, **pas** sur la sous-affirmation périmée — la lacune de grille reste **hors grille** (§8) |
| 23 | 🟠 | ✅ **LEVÉ** | `git diff --stat f4400ca..HEAD` sur `US-00.4-*`, `reports/US-00.4/**`, `ADR-006-*`, `US-00.1-*`, `features/US-00.4-*`, `reports/US-00.3/**` → **0 ligne** · `docs/trace/` **+16/−0** (append-only) |
| 24 | 🟠 | ✅ **LEVÉ** | Passe 2 **rejouée** : « inviolable / tout est enforced / impossible à contourner / chaîne de confiance » → **interdictions ou négations** uniquement |
| 25 | 🔵 | ✅ **LEVÉ** | `gh pr checks 13` **ré-exécuté** → **4 libellés, 4 pass**, identiques aux contextes requis |
| 26 | 🔵 | ✅ **LEVÉ** | `merge_refusal_server_405.txt` **relu** : **HTTP 405**, 1/4 vert, aucun `--admin` · acceptation `{"merged": true}` à 4/4 |
| 27 | 🔵 | ❌ **NON LEVÉ** *(arbitré 2026-07-29, voie a)* | Volets 1-2 **tenus** ; volet 3 **R-c** non tenable : `reviews: []`, `reviewDecision: ""`, **1 seul collaborateur** — tous **vérifiés par moi**. **§5.2 : recevable** |
| 28 | 🟢+🔵 | ✅ **LEVÉ** | **Tout ré-exécuté** : `run_gates` **5/5 exit 0** (test 2/2, couv. 89,5 %) · `--check` · `check_scb_compliance` · `validate_trace` · `--emit-branch-protection` 8 clés · **`gitleaks` 0 fuite / 64 commits** · **aucun jeton porteur de valeur** dans `reports/US-00.7/` ni `tests/fixtures/US-00.7/` *(grep strict → rc=1)*. 🔵 : **4 contextes pass** sur la PR #13 |

### Décompte

| Verdict | Nb | Numéros |
|---|---|---|
| ✅ **LEVÉS** | **25** | 1-19, 22-26, 28 |
| ❌ **NON LEVÉS** | **3** | **20**, **21**, **27** — *les trois arbitrés, les trois **recevables** (§5)* |

**Aucune régression de critère par rapport au 4ᵉ passage.** Le motif du FAIL est **R4-1**, un défaut
transverse que **la grille ne capture pas** — voir §8.

---

## 7. DoD 32/34 — décompte exact, et Story File désormais cohérent

```
$ awk '/^## 🚦 Definition of Done/,/^## 📎/' <Story File> | grep -cE "^- \[x\] \*\*[0-9]+\."
32
$ … grep -nE "^- \[ \] \*\*[0-9]+\."
- [ ] **29.** `QA Status 🧪 PASS` validé par @QA_Tester      ← la mienne
- [ ] **31.** SCB mis à jour (toutes colonnes concernées)     ← fin de cycle
```

**32/34 est exact.** Les deux cases ouvertes sont **légitimement** ouvertes. **Aucune case cochée à tort.**

✅ **Les 4 incohérences internes du Story File relevées au 4ᵉ passage sont RÉSOLUES** : T11 cochée
(l. 1090), T24 cochée (l. 1368), le tableau l. 1568 porte « *PÉRIMÉ-2026-07-29 : T11 **exécutée*** »,
et l'état de la case 34 est unique et cohérent (l. 1522 « levée », l. 1621 `- [x]`, blocs datés
antérieurs **marqués**). Les blocs « 24/34 », « 28/34 », « 30/34 » sont **conservés et étiquetés comme
états successifs** — **c'est correct**, ce sont des artefacts datés. **Je ne retiens plus rien contre
le Story File.**

---

## 8. Couverture des AC — aucun orphelin, et la lacune de grille confirmée

| AC | Couvert par | État |
|---|---|---|
| **AC-1** | 14, 15, 16 | ✅ **Prouvé** |
| **AC-2** | 17, 18 | ✅ **Prouvé** |
| **AC-3** | 10, 19, 20, 21 | ✅ **Nominal prouvé** (19, ré-exécuté) ; *erreur/limite* partiels (20, 21) — **recevable** §5.1 |
| **AC-4** | 25, 26, 27 | ✅ **Nominal COMPLET** (26 : 405 + `merged:true`) ; volet R-c de 27 non tenable — **recevable** §5.2 |
| **AC-5** | 13, 22, 23, 24 | ⚠️ **Lettre satisfaite, esprit non** — voir ci-dessous |
| **AC-6** | 24 | ✅ **Prouvé** — dérogation éteinte aux 3 emplacements, conditionnalité écrite |
| **AC-7** | 1-6 | ✅ **Prouvé** — correctif effectif (exit 2 ré-exécuté), résidu NB-1bis nommé |
| **AC-8** | 7, 8, 9 | ✅ **Prouvé** |

**AC orphelins : AUCUN.** Chacun des 8 AC porte au moins un critère de test.

**Sur AC-5, je suis précise, parce que c'est là que se joue le verdict.**
La **lettre** d'AC-5 nominal porte sur les affirmations d'**impossibilité** et de **dette majeure
d'enforcement** : à ce titre, elle est **satisfaite**, et c'est pourquoi les critères 22 et 24
restent **LEVÉS**. **Je refuse d'étirer un critère pour lui faire dire ce qu'il ne dit pas.**

Mais l'**esprit** d'AC-5 est écrit noir sur blanc au §*Contexte métier* du Story File : « **Le problème
qui justifie cette US : le corpus est devenu FAUX.** » Une US dont l'objet est la **véracité du corpus
vivant** livre aujourd'hui un corpus qui, dans **son propre fichier de CI** et dans **la section même
que `CLAUDE.md` désigne comme référence**, affirme le **contraire** de sa preuve centrale. **Cela
échoue sur l'objet de l'US, pas sur un détail de forme.**

**La lacune de grille est donc confirmée pour la deuxième fois**, et je la reformule à l'intention
d'US-00.8 : la grille ne possède **aucun critère de cohérence temporelle du corpus vivant**. Le
critère manquant, rédigé pour être **falsifiable et rejouable** :

> *Aucun document vivant n'affirme l'absence d'une preuve archivée dans
> `reports/US-00.7/applied_state/`, ni un état de décision qu'il a quitté — vérifié par la commande de
> balayage publiée au §3.2, dont la sortie doit être **vide**, et **publiée avec le rapport**.*

⚠️ **Je ne fais pas de cette lacune mon motif de FAIL** — elle est **hors périmètre d'US-00.7** et
déjà versée à US-00.8. **Mon motif est l'application défaillante de la méthode que le round s'est
lui-même donnée (§3.1, §3.4).**

---

## 9. Ce qu'il faut pour un `🧪 PASS` — **borné, fini et vérifiable par machine**

Quatre FAIL ont pu donner le sentiment d'une barre qui monte. **Je la fixe ici de façon
falsifiable, pour que ce cycle puisse se terminer.**

> ### 🎯 CRITÈRE DE SORTIE UNIQUE
> **La commande de balayage publiée au §3.2 doit rendre une sortie vide**, à la seule exception de
> `STORY_CERTIFICATION_BOARD.md:268` *(entrée datée d'US-00.4, qu'il est **interdit** de réécrire)*.
> **Sa sortie doit être collée dans `corpus_sweep.md`**, en additif daté.
> **Si elle est vide, ce motif meurt et je n'en cherche pas un autre.**

Concrètement, **5 assertions, dans 4 fichiers** — rien d'autre :

1. 🔴 **`.github/workflows/ci.yml:12-13`** *(S1)* — marquer/rectifier la borne : le refus de fusion
   **A** été observé (PR #14, HTTP 405). Fichier **non protégé** par `protect_files.sh`, et **écrit par
   T15 de cette US**.
2. 🔴 **`docs/GIT_PROTECTION.md:276-278`** *(S2)* — même correction. Le fichier **se contredit** avec sa
   propre l. 22 ; c'est le **document n° 3 nommé par l'AC-5 nominal**.
3. 🔴 **`STORY_CERTIFICATION_BOARD.md:1015-1021`** *(S3, S4)* — le bloc **CHEMIN DE SORTIE** et la
   **Prochaine étape** : D-1 **refermé**, **Q-1/N-5 clos** (§2 — la « PR de certification » **est** la PR
   #13, déjà fusionnée), critère 26 **levé**. À remplacer par l'état réel : *reste la QA (case 29) puis
   la clôture (case 31)*.
4. 🟠 **`reports/US-00.7/README.md:26`** *(S5)* — aligner sur la l. 86 déjà corrigée.
5. 🟡 **Rapporter la bonne métrique** : publier la **sortie du balayage** (0 ligne), et **non** un
   décompte de marqueurs. C'est la seule différence entre « j'ai corrigé ce qu'on m'a montré » et
   « la classe est close ».

⛔ **Ce que je ne demande pas** : aucune réécriture d'artefact daté *(`code_review.md`, `security*.md`,
`po_arbitrage_s11.md`, `non_regression.md`, `merge_block.md`, `PROJECT_LOG.md`, `SCB:268`, blocs datés
du Story File)* — ils sont **exacts à leur date** et la **DoD 19** l'interdit. **Aucune** modification
de `TRACKS.md`, d'US-00.1 ou d'un livrable certifié. **Aucun** nouveau critère de grille : il va à
**US-00.8**. **Rien sur les critères 20, 21, 27** : ils sont **recevables en l'état**.

---

## 10. Edge cases testés — au-delà des cas passants

| # | Edge case | Pourquoi | Résultat |
|---|---|---|---|
| 1 | Appliquer **la méthode publiée par le round lui-même**, avec son outil | Un critère de réussite auto-imposé est le test le plus loyal | **Rend 2, devait rendre 0** — §3.1 |
| 2 | Balayer les fichiers **jamais cités** | Deux rounds ont montré le balayage borné aux renvois | **`ci.yml`** (artefact vivant n° 4) et **`GIT_PROTECTION.md:277`** trouvés |
| 3 | Vérifier par **hachage** un item déclaré corrigé | Une correction annoncée n'est pas une correction faite | **md5 identique** — §3.4 |
| 4 | `git blame` sur chaque survivance | Distinguer l'oubli de l'inatteignable | **4/4 datées du 2026-07-28**, deux écrites **par cette US** (`fbd0e3c`, T15/T14) |
| 5 | Vérifier que l'omission n'a pas d'**excuse de permission** | Art. 6 pourrait bloquer l'agent | `protect_files.sh` **ne couvre pas** `.github/workflows/*` → **atteignable** |
| 6 | Chercher un fait **acquis et non consigné** (et non que des manques) | Un audit qui ne cherche que des fautes en fabrique | **Q-1 / N-5 clos** par la PR #13, 4 contextes **pass** — §2 |
| 7 | Balayer la **3ᵉ table** du même index | Deux rounds ont corrigé 3 lignes sur 4 dans ce fichier | **`README.md:26`** — le fichier **se contredit** |
| 8 | Contre-vérifier la **base factuelle de l'arbitrage** 27 | Un arbitrage fondé sur un fait faux ne vaut rien | **`collaborators` = `gitgdx` seul** — **vrai**, arbitrage sain |
| 9 | Vérifier que l'arbitrage **ne coche rien** | C'est la frontière entre arbitrage et complaisance | **DoD toujours 32/34**, 27 toujours non levé — **conforme** |
| 10 | Vérifier le **retrait** du contrôle `reflog` | Une preuve invalidée doit disparaître, pas se déplacer | **3 occurrences, toutes dans le paragraphe de retrait** — correct |
| 11 | Distinction vivant/daté appliquée **contre moi-même** | Ne pas exiger la réécriture d'un artefact daté | **`SCB:268` écartée** de mon décompte — US-00.4, exacte à sa date |
| 12 | `git diff` sur les artefacts certifiés | Vérifier qu'aucune preuve n'a été réécrite | **0 ligne** · `docs/trace/` **+16/−0** — DoD 19 tenue |
| 13 | Chercher un **jeton porteur de valeur** (grep strict, pas le motif nu) | Les 5 correspondances brutes sont des motifs cités | **rc=1** — aucun secret · `gitleaks` **0 fuite / 64 commits** |
| 14 | Compter les scénarios Gherkin **non exécutés** dans une colonne à part | Un scénario non exécuté n'est ni passed ni skipped | **24 documentaires, 0 exécutés** — §1.2 |
| 15 | Vérifier la **protection réelle** de `main` en lecture publique | Aucune détection de dérive n'existe (dette) | **`"protected": true`** — toujours en vigueur ce jour |

---

## 11. Rappel d'autorité (Constitution Art. 5)

Je délivre **`🧪 FAIL`**. Je n'ai **modifié aucun** fichier de code, de gouvernance, ni le SCB, ni
`CLAUDE.md`, ni le Story File ; **rien n'a été fusionné ni poussé** ; je n'ai écrit **que**
`reports/US-00.7/qa_reaudit4.md` et **ajouté** un événement à `docs/trace/US-00.7/events.jsonl`.
**Aucun rapport QA antérieur n'est écrasé.** La certification `🚀 OUI` appartient au rituel `/certify`
(@Architect), **pas à moi**.

**Note finale, à l'orchestrateur et à l'humain.** Le travail de **preuve** de cette US est **fini et
bon** : AC-1 à AC-4 sont établis, la protection est réelle, le refus de fusion vient du serveur,
l'arbitrage du 27 est **exactement** de la bonne forme — il assume sans rien s'accorder. Ce qui reste
n'est **pas** un problème de rigueur : **14 des 15 points du round précédent sont tenus**. C'est un
problème de **méthode de vérification** : le round a écrit la bonne méthode dans son additif, puis a
rapporté un **décompte de marqueurs** au lieu d'**exécuter le balayage**. Les **5 assertions**
restantes sont dans **4 fichiers**, à **6 lignes**, et **une commande** dit quand c'est fini.
**Exécutez la commande du §3.2, collez sa sortie vide, et cette US passe.**
