# US-00.7 — RE-QA ciblée en contexte frais (3ᵉ passage)

> **Agent** : @QA_Tester · **Modèle** : `claude-opus-5[1m]` · **Contexte** : frais
> **Date** : 2026-07-29 · **Branche évaluée** : `feat/US-00.7-violation-fusion-agent` — HEAD **`7d9b73e`**
> **Périmètre réel vérifié par moi** : `git diff f4400ca..HEAD` = **59 fichiers, 10 931 + / 259 −**
> *(`git diff main...HEAD` = 12 fichiers — **trompeur**, branche post-fusion. Vérifié, non repris de la consigne.)*
> ⛔ **Ce rapport n'écrase ni [`qa.md`](qa.md) ni [`qa_reaudit.md`](qa_reaudit.md)** — preuves datées, laissées intactes.

---

## ⚖️ VERDICT : 🧪 **FAIL**

**Le critère 27 n'est PAS levé.** Le fichier qu'il nomme — [`merge_block.md`](merge_block.md) — **porte
encore quatre assertions fausses**, dont **une qui n'est pas « périmée » mais matériellement démentie par
le contenu du dépôt** : le rapport déclare qu'un fichier de preuve **« N'existe pas »** alors qu'il existe,
qu'il fait 298 octets, et qu'il est commité depuis `cb73997`.

**Ce que je confirme comme authentiquement corrigé** : l'assertion `is_bot` est **barrée aux 4 emplacements
annoncés** · le décompte DoD **31/34 est EXACT** et le **Story File est cohérent avec lui-même** · le
critère **26 reste LEVÉ** (le 405 tient, revérifié). **Les corrections 2, 3 et 4 sont faites et bonnes.**

**Ce qui échoue est la correction n° 1 — la seule qui portait le motif du 2ᵉ FAIL.** Elle a été appliquée
**à une phrase** au lieu de l'être **au fichier**. Le résultat est pire qu'avant : un encadré en tête
annonce « **deux énoncés de ce rapport sont FAUX** », puis **six lignes plus bas** une section `##` en gras,
non barrée, titrée « **⛔ EN TÊTE, PARCE QU'ON NE L'ENTERRE PAS : la preuve du REFUS DE FUSION n'a PAS été
obtenue** » affirme le contraire de la vérité établie — et se clôt par : « ***Aucune formulation de ce
rapport ne doit laisser croire l'inverse.*** »

**Décomptes** : **25/28 critères LEVÉS** · **3 NON LEVÉS** (**20**, **21**, **27**) · **0 AC orphelin** ·
**DoD 31/34 — exact, recompté** · unitaires **2 passed / 0 skipped / 0 failed** · couverture **89,5 %** ·
E2E BDD **0 passed / 0 skipped / 0 failed**.

> 🟢 **Le renvoi reste actionnable et peu coûteux** : **rien à fabriquer, rien à ré-exécuter**. Le travail
> technique d'US-00.7 est **fait et prouvé** — je le certifie après ré-exécution intégrale. Ce qui manque
> est **documentaire** (§8).

**Rappel d'autorité (Constitution Art. 5)** : je délivre un verdict `🧪`. La certification `🚀 OUI`
appartient au rituel `/certify` (@Architect), pas à moi.

---

## 0. Pré-conditions — satisfaites

```
$ python scripts/validate_trace.py --us US-00.7
Traçabilité conforme.                                                            → exit 0
```

`docs/trace/US-00.7/events.jsonl` — **14 événements**. Les deux pré-conditions de mon rôle sont présentes :
`EVT_CODE_REVIEW_PASSED` (#9, code-reviewer) et `EVT_SECURITY_AUDIT_PASSED` (#11, cyber-security).
S'y ajoutent `EVT_QA_FAILED` ×2 (#12, #14) et `EVT_WORKFLOW_VIOLATION` (#13). → **Je peux statuer.**

### 0.1 Périmètre — vérifié par moi

```
$ git rev-parse HEAD                             → 7d9b73e
$ git diff --shortstat f4400ca..HEAD             → 59 files changed, 10931 insertions(+), 259 deletions(-)
$ git diff --shortstat main...HEAD               → 12 files changed, 1032 insertions(+), 19 deletions(-)   ← TROMPEUR
$ git merge-base --is-ancestor f4400ca HEAD      → VRAI (aucune réécriture d'historique)
$ git merge-base --is-ancestor b7128cf HEAD      → VRAI
$ gh api …/branches/main                         → {"name":"main","protected":true,"sha":"b7128cf…"}
```

✅ `main` **n'a pas bougé** (`b7128cf`) · ⛔ **PR #14 NON fusionnée par moi** — `mergedAt: null` (§7).

### 0.2 Exécutions de référence — toutes relancées par moi, sorties brutes

```
$ python scripts/run_gates.py --gate test
00:03 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test · Tous les gates bloquants passent (1 exécutés).                     → exit 0

$ python scripts/run_gates.py --component app
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
Tous les gates bloquants passent (5 exécutés).                                   → exit 0

$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.                                        → exit 0

$ python scripts/validate_trace.py --us US-00.7
Traçabilité conforme.                                                            → exit 0

$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (…)
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici (…)
                                                                                 → exit 0

$ python scripts/factory_sync.py --check-remote
  [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
  [OK] allow_force_pushes … | false | false          [OK] allow_deletions … | false | false
  [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
  [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
Protection de gitgdx/Concentration:main — conforme à la cible générée …          → exit 0
$ (grep -c SIMULATION <sortie>)                                                  → 0

$ gitleaks detect --source . --config .gitleaks.toml --no-banner --redact
INF 60 commits scanned. · INF no leaks found                                     → exit 0

$ python tests/fixtures/US-00.7/nb1_harness.py
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   MAPPING INCOMPLET — … 1 champ(s) ACTIF(S) non couvert(s) … enforce_admins = {"enabled": true}
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 2
```

> ⚠️ **Portée de ma mesure** : elle vaut **à sa date** (`2026-07-29`) et **pour l'acteur employé**
> (jeton `gh` de `gitgdx`, `admin: true`). Elle **n'installe aucune surveillance** — la dette « aucune
> détection automatique de dérive » reste **OUVERTE**.

### 0.3 Décomptes exigés par la Constitution Art. 3

| Suite | passed | skipped | failed | Commentaire |
|---|---:|---:|---:|---|
| **Unitaires Flutter** | **2** | **0** | **0** | `test/widget_test.dart` — **non-régression** (0 fichier Dart au périmètre) |
| **Couverture de lignes** | — | — | — | **89,5 % (17/19)** · seuil **80 %** → ✅ |
| **Gates `--component app`** | **5** | **0** | **0** | format · analyze · test · deps_audit · build |
| **E2E BDD (Gherkin)** | **0** | **0** | **0** | ⚠️ **aucun des 24 scénarios n'est automatisé** |
| **Critères de test du Story File** | **25** | **0** | **3** | 28 critères, ré-exercés un à un (§6) |
| **Contextes CI requis (PR #14, `7d9b73e`)** | **4** | **0** | **0** | 5 check-runs / 4 libellés distincts |

> ⚠️ **AUCUN scénario Gherkin n'est exécutable — re-vérifié par moi ce jour.**
> `grep -rniE "behave|pytest-bdd|cucumber|@given|@when|@then|Given\(|When\(|Then\(" tests/ lib/ test/`
> → **aucun résultat**. `tests/features/US-00.7-….feature` porte **24** scénarios, **documentaires**.
> `e2e.yml` est un *smoke test* **nocturne** (`on: schedule` + `workflow_dispatch`), **pas** un lanceur
> Gherkin, et **n'est pas un contexte requis**. **Je ne compte AUCUN scénario comme vert. Dit, pas tu.**

---

## 1. Réponses directes aux quatre questions posées

| Question | Ma réponse, après exécution |
|---|---|
| **Le critère 27 est-il réellement levé ?** | **NON.** Et pour **deux** raisons indépendantes, pas une (§2 et §3) |
| **Le fichier qu'il nomme porte-t-il encore une assertion fausse ?** | **OUI — quatre**, dont **une matériellement démentie** par le dépôt lui-même (§2) |
| **« Barrer sans supprimer » est-il recevable ?** | **Recevable en doctrine, RATÉ en exécution ici — et le ratage est aggravant** (§4) |
| **Le décompte 31/34 est-il exact, le Story File cohérent ?** | **OUI aux deux.** Recompté par programme. Corrections 2 et 3 **bonnes** (§5) |

---

## 2. 🔴 R2-1 — **BLOQUANT** · `merge_block.md` porte encore QUATRE assertions fausses

> **Action effectuée** : lecture **intégrale** de `merge_block.md` (173 lignes) ; `cat` du fichier dont le
> rapport nie l'existence ; `git log` de ce fichier ; comptage des marques de barré.
> **Résultat attendu** *(critère 27 · AC-5 erreur, et le standard que le rapport s'applique à lui-même en
> l. 8-9 : « **tant qu'il porte une assertion fausse, le critère n'est pas levé** »)* : **zéro** assertion
> fausse non rétractée.
> **Résultat obtenu** : **4 assertions fausses subsistent, non barrées.** `grep -c "~~"` → **2 lignes
> seulement** (l. 118-119, l'unique passage `is_bot`). Tout le reste est **intact**.

### 2.1 L'inventaire, ligne par ligne

| # | Ligne | Texte porté aujourd'hui | Réalité vérifiée par moi | Barré ? |
|---|---|---|---|---|
| **a** | **36** | `## ⛔ EN TÊTE, PARCE QU'ON NE L'ENTERRE PAS :` **la preuve du REFUS DE FUSION n'a PAS été obtenue** | **Obtenue** le 2026-07-29T08:49:14Z — HTTP **405** | ❌ **non** |
| **b** | **38-41** | « **T11(d) … n'a pas eu lieu** … aucun `gh pr merge` n'a été refusé ; **aucun message de refus n'existe** ; `…/merge_refusal_raw.txt` **n'a jamais été créé** » | **T11(d) a eu lieu** · un `gh pr merge` **a été refusé** (07:07:11Z) · le fichier **EXISTE** | ❌ **non** |
| **c** | **48-49** | « **l'AC-4 nominal n'est pas satisfait** et la **case 13 de la DoD reste décochée**. ***Aucune formulation de ce rapport ne doit laisser croire l'inverse.*** » | **AC-4 nominal COMPLET** · case 13 = **`[x]`** | ❌ **non** |
| **d** | **173** | *(tableau « Fichiers de preuve »)* « `applied_state/merge_refusal_raw.txt` — **N'existe pas.** … **Ce vide est la preuve de l'absence de preuve** » | **Le fichier EXISTE** | ❌ **non** |
| **e** | **133** | « Ce qui n'est PAS prouvé », point 1 — le refus de fusion | **Nommé PÉRIMÉ dans l'encadré ②**, mais **non annoté sur place** | ❌ **non** |
| ✅ | 118-119 | `is_bot` → case 34 satisfaite | Correctement **barré + annoté** | ✅ **oui** |

### 2.2 Le point (d) n'est pas une affirmation périmée — c'est une affirmation **matériellement fausse**

```
$ ls -la reports/US-00.7/applied_state/merge_refusal_raw.txt
-rw-r--r-- … 298 Jul 29 09:07 merge_refusal_raw.txt

$ cat reports/US-00.7/applied_state/merge_refusal_raw.txt
X Pull request gitgdx/Concentration#13 is not mergeable: the base branch policy prohibits the merge.
To have the pull request merged after all the requirements have been met, add the `--auto` flag.
To use administrator privileges to immediately merge the pull request, add the `--admin` flag.

$ cat reports/US-00.7/applied_state/merge_refusal_raw.meta.txt
PR=13 | exit=1 | 2026-07-29T07:07:11Z

$ git log --oneline -- reports/US-00.7/applied_state/merge_refusal_raw.txt
cb73997 docs(us-00.7): VIOLATION DE WORKFLOW auto-denoncee — fusion par un agent
```

**Distinction qui fait la gravité.** Les points (a), (b), (c) sont des **faits datés devenus faux** — on
peut débattre de les historiser. Le point **(d) n'est pas cela** : c'est l'**index des fichiers de preuve**
du rapport, c'est-à-dire l'endroit qu'un auditeur consulte **pour savoir ce qui existe**, et il **oriente
vers le vide un lecteur qui cherche une preuve présente dans le même répertoire**. Ce n'est pas un état
ancien conservé, c'est un **index faux**. Un index ne s'historise pas : il décrit le présent ou il ne sert
à rien.

### 2.3 Pourquoi c'est bloquant, et non cosmétique

1. **Le critère 27 NOMME ce fichier** comme porteur de la « preuve qualifiée ». Il ne peut pas être levé
   par un document dont la section la plus visible affirme que la preuve n'a pas été obtenue.
2. **Le rapport énonce lui-même le standard auquel il échoue.** Ses lignes 8-9, ajoutées par la
   correction : « *Ce rapport est **nommé par le critère 27** : tant qu'il porte une assertion fausse, le
   critère **n'est pas levé**.* » **Il en porte quatre.**
3. **L'encadré ② désigne la mauvaise cible.** Il nomme « §*Ce qui n'est PAS prouvé*, point 1 » (l. 133) —
   il **ne nomme jamais** la section `##` de la l. 36, qui est pourtant **le titre le plus fort du
   document** et dit la même chose en plus gros.
4. **La phrase de la l. 49 retourne la correction contre elle-même** : « *Aucune formulation de ce rapport
   ne doit laisser croire l'inverse* » **interdit maintenant au lecteur de croire ce qui est vrai**.
5. **C'est la deuxième fois consécutive** que le critère 27 échoue **sur le même fichier** et pour la
   **même classe de défaut** — une assertion fausse vivante dans le document qu'il nomme. Seule la phrase
   a changé.

---

## 3. 🔴 R2-2 — Le critère 27 échoue **aussi** par sa seconde moitié : R-c toujours non consigné

> **Action effectuée** : `gh pr view 14 --json reviewDecision,latestReviews,state,mergedAt` (lecture seule).
> **Résultat attendu** *(critère 27, dernier élément)* : « **Revue humaine explicite de la PR consignée**
> (renforcement **R-c**) ».
> **Résultat obtenu** :
> ```
> {"latestReviews":[],"mergeStateStatus":"CLEAN","mergeable":"MERGEABLE",
>  "mergedAt":null,"number":14,"reviewDecision":"","state":"OPEN"}
> ```
> **`reviewDecision` vide · `latestReviews` vide · non fusionnée.**

**Sur les trois PR de cette US, R-c n'est consigné de façon valide nulle part** : **PR #12** — consignation
par `is_bot`, méthode désormais **barrée comme invalide** ; **PR #13** — **fusionnée par un AGENT**
(violation actée, case 34 décochée) ; **PR #14** — **aucune revue, non fusionnée**.

⚠️ **Part irréversible, signalée sans en faire un grief** : le contenu d'US-00.7 est déjà sur `main` par la
fusion agent de la PR #13. La protection que R-c devait offrir **pour l'atterrissage de cette US est
perdue** — pas suspendue. Elle reste honorable pour la PR #14 (NIVEAU 1 déclaratif) et structurellement
soluble en **US-00.8** (NIVEAU 2).

**Les autres éléments du critère 27 sont, eux, LEVÉS et vérifiés par moi** : aucun `--admin`
(l'endpoint REST `PUT /pulls/{n}/merge` **n'expose aucun paramètre de bypass** — contournement
structurellement impossible par la voie employée) · aucun contexte retiré (**4 requis / 4 rapportés**,
comparaison d'ensembles §6) · aucune règle désactivée (`--check-remote` **exit 0**, 12 champs alignés) ·
qualification **`expected` ≠ `failing` écrite** · `strict: true` et `required_conversation_resolution`
**documentés**.

---

## 4. Mon jugement sur « barrer sans supprimer » — la question m'était posée, je la tranche

**La doctrine est RECEVABLE. Je l'endosse, contre la suppression.** Barrer + annoter avec une date et un
renvoi préserve la piste d'audit, respecte la discipline *append-only* du projet, et permet à un lecteur de
voir **qu'une correction a eu lieu**, ce qu'une suppression efface. Sur les 4 emplacements `is_bot`
(`merge_block.md:118`, Story File `:1139` et `:1541`, `SCB:694`), **le procédé est bien exécuté** : texte
barré, ⛑️ visible, date, cause, conséquence, renvoi. **Rien à redire.**

**Mais elle est assortie de trois conditions, et deux sont violées ici.**

### 4.1 Condition d'EXHAUSTIVITÉ — violée, et c'est ce qui rend le procédé dangereux

**Une rectification partielle est pire qu'aucune rectification.** La présence visible de ⛑️ et de texte
barré **signale au lecteur que le document a été revu**, ce qui l'autorise à faire confiance au reste. Un
lecteur pressé de `merge_block.md` lit un encadré affirmant « deux énoncés sont FAUX, rien n'est supprimé »,
en déduit — raisonnablement — que **ce qui n'est pas barré est à jour**, puis tombe six lignes plus bas sur
un titre `##` en gras affirmant l'inverse de la vérité. **La rectification partielle a fabriqué la
crédibilité qui rend l'erreur restante plus convaincante qu'elle ne l'était avant.**

⇒ **Règle que je pose** : *barrer sans supprimer* n'est recevable **que** si l'énoncé invalidé est traité à
**100 %** de ses occurrences **dans le document rectifié**. En deçà, il faut **soit** l'exhaustivité,
**soit** un bandeau de tête qui **interdit** de lire le corps comme courant.

### 4.2 Condition de VISIBILITÉ À L'OUTIL — violée, et personne ne l'a vue

⚠️ **`~~texte~~` est invisible à `grep`.** Il ne s'agit pas d'une chicane : **ce projet audite son corpus
par `grep`** — `corpus_sweep.md` est intégralement construit sur des passes `grep`, et le balayage de
l'orchestrateur en était un. Un futur balayage **remontera le texte barré comme s'il était vivant**, et
inversement un auditeur qui compte des occurrences ne saura pas lesquelles sont rétractées.

De plus, aux l. 118-119 (et `SCB:694`), le `~~` **enjambe un saut de ligne** : le rendu GitHub est correct,
mais `grep -n "~~"` ne remonte que **2 lignes** pour un passage qui en occupe **quatre**.

⇒ **Recommandation transmissible** : adjoindre au barré un **marqueur textuel greppable** — le ⛑️ y sert
déjà de fait ; l'ériger en **convention déclarée** et en faire un contrôle du `corpus_sweep`.

### 4.3 Condition de FORME — un titre de section ne se barre pas

Le défaut (a) est une **section `##` entière**. On ne barre pas convaincamment un titre : il faut un
**bandeau daté à l'intérieur du bloc**. Le procédé « barrer » n'était pas le bon outil ici, et c'est
peut-être pourquoi il n'a pas été tenté.

---

## 5. Le décompte 31/34 et la cohérence du Story File — **exacts tous les deux**

```
$ python - (regex ^- \[( |x)\] \*\*(\d+)\.\*\* sur le Story File)
total cases : 34   |   manquants : []   |   doublons : []
COCHEES   : 31
DECOCHEES : [29, 31, 34]
```

✅ **« 31/34, restent 29 · 31 · 34 » est EXACT** — recompté par programme, sans reprendre le décompte annoncé.

✅ **Le Story File est cohérent avec lui-même.** Les quatre blocs d'état coexistent **sans se contredire**,
parce qu'ils sont **explicitement ordonnés dans le temps** :

| Ligne | Bloc | Étiquetage |
|---|---|---|
| **1519** | **31 / 34** *(mise à jour du 2026-07-29)* | ✅ **courant**, restent **29 · 31 · 34** |
| 1527 | 30 / 34 | ✅ « *Bloc précédent — état du 2026-07-28, après la QA, conservé* » |
| 1538 | 28 / 34 | ✅ « *Table précédente — état avant les audits, conservé* » |
| 1552 | 24 / 34 | ✅ « *Table d'origine — état avant la PR #12, conservé* » |

Et la l. 1524 pose la règle de lecture : « *Les blocs datés ci-dessous sont **conservés** comme états
successifs — **le décompte courant est celui-ci**.* » **C'est la bonne méthode**, et c'est exactement ce
qui manque à `merge_block.md`.

✅ **Correction n° 3 (bloc T11) — bien faite** : l'annotation « **✅ T11 COMPLÈTE au 2026-07-29 — mise à jour
en tête, le bloc ci-dessous décrit l'ÉTAT DU 28 et est conservé tel quel** » (l. 1117-1127) **précède** et
**encadre** l'état du 28, séparé par un `---`. Les mentions « AC-4 nominal n'est pas satisfait » (l. 1133) et
« case 13 N'EST PAS levée » (l. 1545) tombent **à l'intérieur de blocs correctement étiquetés**. **Aucun
grief.**

🟡 **Nit sans conséquence** : la l. 1524 énumère « (**28/34**, **30/34**) » et **omet le bloc 24/34** de la
l. 1552 — lequel porte néanmoins sa propre étiquette. **Cosmétique, non retenu contre le verdict.**

---

## 6. Les 28 critères — verdict, preuve obtenue par moi, commande

> ✅ **LEVÉ** · ❌ **NON LEVÉ** · 🟢 avant `PUT` · 🟠 après `PUT` · 🔵 sur PR
> **Les 28 ont été ré-exercés ce jour** — aucun n'est repris sur la foi des passages précédents.

| # | Cond. | Verdict | Preuve **obtenue par moi** | Commande |
|---|---|---|---|---|
| **1** | 🟢 | ✅ **LEVÉ** | Faux vert **reproduit** : comparateur d'avant correctif → **exit 0** « conforme » sur cible amputée face à un réel `{"enabled": true}` ; toutes lignes `[SIMULATION]` | arbre isolé `git show f4400ca:…` + `nb1_harness.py` |
| **2** | 🟢 | ✅ **LEVÉ** | **exit 2** · « **VERIFICATION IMPOSSIBLE — ce n'est PAS un succès** » · `MAPPING INCOMPLET` · clé **nommée** `enforce_admins = {"enabled": true}` · **1 champ ACTIF non couvert** | `python tests/fixtures/US-00.7/nb1_harness.py` |
| **3** | 🟢 | ✅ **LEVÉ** | **12 chemins d'US-00.4 rejoués sur les deux versions** — exits identiques, **0 changement d'issue** | boucle pré-fixe / post-fixe |
| **4** | 🟢 | ✅ **LEVÉ** | **exit 0**, **10** champs additifs **NOMMÉS** `[IGNORÉ — NEUTRE]`. Critère #24 d'US-00.4 **reste vert** | `--from-protection …cles_additives_neutres.json` |
| **5** | 🟢 | ✅ **LEVÉ** | **NB-1bis reproduit — réel.** **B** (réel relâché `enforce_admins:{"enabled":false}`) → **exit 0** ; **C** (clé absente des deux côtés) → **exit 0**, **pas même nommée** | `nb1_harness.py --target …cible_amputee_*.json` |
| **6** | 🟢 | ✅ **LEVÉ** | **8 clés** · `set(payload) == MAPPED_TOP_KEYS` → **`True`** · diff symétrique **`set()`** · `required_pull_request_reviews` **présent** `{count: 0}` · `restrictions: None` · `strict: True` · **4** contextes | `--emit-branch-protection` + comparaison à `cbp.MAPPED_TOP_KEYS` |
| **7** | 🟢 | ✅ **LEVÉ** | Points de code des 4 libellés conformes, **aucun `U+FE0F`**, NFC ×4 ; correspondance `ci.yml` / `branch-naming.yml` | impression des points de code |
| **8** | 🟢 | ✅ **LEVÉ** | **exit 0** et **sa limite imprimée** : « vérification **DOCUMENTAIRE**, aucun appel réseau » + `[AVERTISSEMENT] l'état RÉEL … n'est PAS vérifié ici` | `python scripts/factory_sync.py --check` |
| **9** | 🟢 | ✅ **LEVÉ** | Plan de retour arrière présent dans **`27464a9`**, **antérieur** au commit du `PUT` ; distinction `EXPECTED` vs `FAILURE` présente | `git show 27464a9:docs/GIT_PROTECTION.md` · `merge-base` |
| **10** | 🟢 | ✅ **LEVÉ** | `rollback_main.md` commité en **`27464a9`**, avant T10. **Miroir vérifié RÉELLEMENT PRÉSENT** : `refs/heads/main` = **`f4400ca`** | `git -C ../_backup_US-00.7/…git show-ref` |
| **11** | 🟢 | ✅ **LEVÉ** | Aucun verbe d'écriture distante ajouté au comparateur ; seuls signature, intersection et site d'appel changent | `grep -nE "-X (PUT\|POST\|PATCH\|DELETE)"` |
| **12** | 🟢 | ✅ **LEVÉ** | `grep -rn "check-remote" .github/workflows/` → **vide** (hors CI, **aucun `selftest`** — dette maintenue). Diff des **6** fichiers sensibles → **VIDE** | `grep -rn` · `git diff --stat f4400ca..HEAD -- <6>` |
| **13** | 🟢 | ✅ **LEVÉ** | `corpus_sweep.md` : 3 passes, exclusions déclarées, angles morts, 11 artefacts, ⛔ exhaustivité **non revendiquée** | lecture + `grep -nE "Passe [12]\|angle mort"` |
| **14** | 🟠 | ✅ **LEVÉ** | `entry_state/` — **6 fichiers** présents, chacun en-têté de sa commande et de son horodatage UTC ; `…/protection` → **404** · `…/rulesets` → **200 `[]`** · `--check-remote` **exit 1** | `ls` + lecture des 6 fichiers |
| **15** | 🟠 | ✅ **LEVÉ** | `branch_main_after.json` → **`"protected": true`**, `enforcement_level: "everyone"`, 4 contextes. **Re-vérifié EN DIRECT** → `{"name":"main","protected":true,"sha":"b7128cf…"}` | `gh api …/branches/main` |
| **16** | 🟠 | ✅ **LEVÉ** | `protection_applied.json` — HTTP 200 ; 9 points conformes ; `restrictions` **absente** | lecture intégrale du JSON |
| **17** | 🟠 | ✅ **LEVÉ** | **Re-exécuté en direct** → **exit 0**, 12 alignés, **0 écart**, 0 champ actif non couvert, **`grep -c SIMULATION` = 0** | `python scripts/factory_sync.py --check-remote` |
| **18** | 🟠 | ✅ **LEVÉ** | Volet **opposable** vérifié : `INERT_GET_KEYS` et le mapping **non ajustés** ; `factory_sync.py` **intact** | `git diff f4400ca..HEAD -- scripts/check_branch_protection.py scripts/factory_sync.py` |
| **19** | 🟠 | ✅ **LEVÉ** | 3 sorties **brutes** lues par moi : `remote: error: **GH006**` (l. 31, 42) · « *Changes must be made through a pull request* » · « ***4 of 4 required status checks are expected*** » · `[remote rejected] … (refusing to delete the current branch)` (l. 54). **Attribution honnête écrite** | lecture intégrale de `negative_test_server.txt` |
| **20** | 🟠 | ❌ **NON LEVÉ** *(partiel, assumé — §7.1)* | **Manquant, reconfirmé par comptage** : `grep -ci hooksPath` → **0** · `grep -ci rev-parse` → **0** · suppression du clone **non attestée**. **Acquis** : aucune option de contournement, `main` inchangée | `grep -ciE` sur `negative_test_server.txt` |
| **21** | 🟠 | ❌ **NON LEVÉ** *(partiel, assumé — §7.1)* | `grep -ci "garde relue"` → **1** (l. 13), **pas avant chacune des 3** commandes, **sans le triplet**. Phrase de portée : `grep -ciE "autre acteur\|jeton d.application\|interface web\|à sa date"` → **0** | `grep -ciE` sur le fichier **nommé par le critère** |
| **22** | 🟠 | ✅ **LEVÉ** *(1 exception structurelle)* | Passe 1 rejouée sur les **11 artefacts** : **6 occurrences, toutes légitimes** — historisations **datées** (`EPIC_00:52,94` · `GIT_PROTECTION:69` · fixtures `README:6`) et une **constante de code** (`check_branch_protection.py:80 : PLAN_MARKER`). Exception connue : `tests/fixtures/US-00.4/README.md:31`, artefact **daté** démenti en amont | `grep -rniE "n.est PAS protégée\|NON ATTEIGNABLE\|DETTE MAJEURE\|Upgrade to GitHub Pro"` |
| **23** | 🟠 | ✅ **LEVÉ** | `git diff --stat f4400ca..HEAD` sur `US-00.4-*`, `reports/US-00.4/`, `ADR-006-*`, `US-00.1-*`, `tests/features/US-00.4-*`, `reports/US-00.1..3/` → **VIDE, 0 ligne**. `docs/trace/` : lignes supprimées = **0** (**append-only**). `tests/fixtures/US-00.4/README.md` → **27 + / 0 −**, purement additif | `git diff --stat` / `--numstat` par famille |
| **24** | 🟠 | ✅ **LEVÉ** | Passe 2 → **0 occurrence** de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance ». Extinction de la dérogation **datée** aux **3** emplacements ; conditionnalité écrite | `grep -rniE <4 motifs>` → exit 1 |
| **25** | 🔵 | ✅ **LEVÉ** | **Comparaison d'ensembles programmatique sur `7d9b73e`** : **4 requis / 4 rapportés** · `requis NON rapportés = aucun` · `rapportés NON requis = aucun` · **tous `success`** · **5 check-runs / 4 libellés** (`check-branch-name` ×2 : `push` + `pull_request`) | `gh api …/branches/main/protection` ↔ `…/commits/7d9b73e/check-runs` |
| **26** | 🔵 | ✅ **LEVÉ** | **Preuve brute relue** : `gh api -X PUT …/pulls/14/merge` → **HTTP 405**, `{"message":"3 of 4 required status checks are expected.","documentation_url":"…about-protected-branches","status":"405"}`, `exit=1`, à `08:49:14Z` avec **1/4** vert. Acceptation à 4/4 : `{"merged":true}`. **Aucun `--admin`** *(sans équivalent sur cet endpoint)*. `main` inchangée | lecture de `merge_refusal_server_405.txt` et `merge_refusal_api_raw.txt` |
| **27** | 🔵 | ❌ **NON LEVÉ** | **§2 et §3.** ✅ Aucun `--admin` · aucun contexte retiré · aucune règle désactivée · `expected`≠`failing` écrit · `strict`/`required_conversation_resolution` documentés. ❌ **Le fichier nommé porte QUATRE assertions fausses non barrées** (l. 36, 38-41, 48-49, 173) dont **une matériellement démentie** par un fichier de 298 o présent dans le dépôt. ❌ **R-c non consigné** : `reviewDecision` **vide**, `latestReviews` **`[]`**, PR #14 non fusionnée | `cat merge_block.md` · `cat …/merge_refusal_raw.txt` · `gh pr view 14 --json …` |
| **28** | 🟢+🔵 | ✅ **LEVÉ** | **Tout ré-exécuté** : `--check` **exit 0** · `check_scb_compliance` **exit 0** · `validate_trace` **conforme** · `run_gates --component app` **5/5** · `--emit-branch-protection` **8 clés** · **`gitleaks` : 0 fuite / 60 commits** · aucun jeton porteur de valeur dans `reports/US-00.7/` ni `tests/fixtures/US-00.7/` *(les correspondances sont des motifs de `grep` cités)*. **🔵** : **4/4** contextes verts sur `7d9b73e` | 6 commandes + `grep -rnE <motifs de jetons>` |

### Décompte final

| Verdict | Nb | Numéros |
|---|---:|---|
| ✅ **LEVÉ** | **25** | 1-19, 22-26, 28 |
| ❌ **NON LEVÉ** | **3** | **20**, **21**, **27** |
| ⬜ **N/A** | **0** | — |
| **Total** | **28** | |

**Par conditionnement** : 🟢 **13/13** · 🟠 **9/11** *(20, 21)* · 🔵 **3/4** *(27)*.

> 📌 **Mouvement depuis le 2ᵉ passage** : **aucun**. Le total (25) **et sa composition** (20, 21, 27) sont
> **identiques**. ⛔ **Le motif du 27, lui, a changé** : la phrase `is_bot` est corrigée, **quatre autres
> ne le sont pas**. **Ne pas lire « toujours 25/28 » comme « rien n'a été fait »** — trois corrections sur
> quatre sont bonnes ; c'est la quatrième, celle qui portait le FAIL, qui est incomplète.

---

## 7. Les critères 20 et 21 — je reprends le raisonnement du 2ᵉ passage à mon compte, et je le renforce

### 7.1 Sur le principe : **un arbitrage ne lève jamais un critère** — je confirme

**J'adopte intégralement ce raisonnement.** Un arbitrage enregistre qu'un collectif **accepte sciemment un
risque résiduel** ; il n'a pas le pouvoir de transformer une **absence de preuve** en **preuve**. Prétendre
l'inverse rendrait tout critère levable par décision, c'est-à-dire **abolirait la notion de critère**.
Les critères **20** et **21** sont donc **NON LEVÉS**, arbitrage ou pas — et je les ai **reconfirmés par
comptage** ce jour (`hooksPath` → 0 · `rev-parse` → 0 · `garde relue` → 1 · portée → 0).

### 7.2 Sur ce qui évite l'échec **sur eux** : je confirme, et j'ajoute une précision

**Ce n'est pas l'arbitrage — c'est que l'AC-3 est prouvé par ailleurs, et je l'ai vérifié moi-même.**
J'ai lu `negative_test_server.txt` intégralement : les trois sorties portent **`remote:`** et
**`GH006: Protected branch update failed`** / `[remote rejected]` — **marqueurs d'origine serveur, qu'un
hook local ne peut pas produire**. Et la non-modification de `main` est corroborée **hors du fichier de
preuve** : le miroir de sauvegarde, **dont j'ai vérifié l'existence réelle**, porte `refs/heads/main` =
**`f4400ca`**. Les manques des critères 20 et 21 sont des **manques d'ARCHIVAGE DE MÉTHODE**, pas des trous
de preuve. **Si l'AC-3 avait reposé sur eux seuls, j'aurais FAIL sur eux.**

**Ma précision, qui n'était pas dite** : il en résulte que **« 25/28 » n'est jamais en soi un score
passant**. Un `PASS` sur ce dossier exigerait, en plus de l'arithmétique, l'énoncé explicite que la
substance de l'AC-3 est portée par les critères **10** et **19**. **Le verdict ne repose donc jamais sur le
décompte** — et c'est pourquoi je ne peux pas non plus laisser passer le 27 « parce qu'il n'y en a qu'un ».

✅ **J'approuve sans réserve le refus de retoucher `negative_test_server.txt`.** Y inscrire aujourd'hui une
garde qui n'a pas été relue trois fois serait **fabriquer une preuve** — infiniment plus grave que le
manque. **Rien n'a été fabriqué ; je le certifie après lecture intégrale.**

---

## 8. Findings QA propres — mon balayage, refait entièrement

L'orchestrateur a annoncé un balayage `is_bot` ayant trouvé **quatre** occurrences. **J'ai refait le
balayage moi-même, sur tout le dépôt et toutes extensions.** Voici ce qu'il rend en plus.

### 🟠 R2-3 — MAJEUR · L'énoncé invalidé n° ② vit dans **trois documents que la correction n'a pas touchés**

L'encadré de `merge_block.md` déclare « périmé » l'énoncé « *le refus de fusion n'est pas prouvé* ». **Cet
énoncé est vivant ailleurs, et l'encadré ne le dit pas.** Le balayage n'a cherché que `is_bot`.

> **Action effectuée** : `grep -rniE "refus d.une tentative de FUSION|T11.{0,40}non exécut"` sur tout le
> dépôt, puis `git log a6301ba..HEAD -- <fichier>` sur chaque résultat.
> **Résultat attendu** *(AC-5 · corpus vivant sans affirmation périmée)* : l'énoncé est rectifié **partout
> où il est vivant**, ou porte une date qui le circonscrit.
> **Résultat obtenu** : **3 documents non datés / maintenus le portent encore, et n'ont jamais été
> touchés depuis la preuve du 405.**

| Emplacement | Nature | Texte porté | Touché depuis `a6301ba` ? |
|---|---|---|---|
| **`docs/GIT_PROTECTION.md:22`** | **Document de gouvernance VIVANT** | « ⚠️ *Ce que ces preuves n'établissent PAS — **à lire avant tout audit***. 1. **Le refus d'une tentative de FUSION n'a pas encore été observé** … c'est la tâche **T11** …, **non exécutée à ce jour** » | 🔴 **NON** |
| **`reports/US-00.7/README.md:26`** | **Index maintenu** des preuves | `⛔ **Non exécuté** \| **T11** (PR · libellés rapportés · refus de fusion · fusion après 4 verts)` | 🔴 **NON** |
| **`reports/US-00.7/README.md:44`** | idem | « 🔴 *Ce qui n'est PAS prouvé — **à lire AVANT tout audit*** … **Le refus d'une tentative de FUSION n'a pas été observé** … c'est **T11**, **non exécutée** » | 🔴 **NON** |
| `STORY_CERTIFICATION_BOARD.md:625` | Board de certification | « ⚠️ *Ce qui N'EST PAS prouvé — **à lire avant tout audit*** : le refus … n'a **pas** été observé (**T11 non exécutée**) » | 🟡 rectifié **326 lignes plus bas** (l. 951), **sans renvoi au point de lecture** |
| `STORY_CERTIFICATION_BOARD.md:701-705` | idem, **dans le bullet T11** | « ⛔ **NON ACQUIS** … T11(d) n'a pas eu lieu … ⇒ **AC-4 nominal NON satisfait, case 13 DÉCOCHÉE** … **Preuve encore obtenable** » | 🟡 **la l. 694 du MÊME bullet a été corrigée**, la 701 non |
| `reports/US-00.7/non_regression.md:518` · `code_review.md:453` · `po_arbitrage_s11.md:133` | Rapports **datés** d'audit | idem | 🟢 **historisation défendable** |

**Ce n'est pas de l'historisation — c'est une propagation incomplète, et je le prouve :**

```
$ git show a6301ba --stat        # « refus de fusion PROUVE PAR LE SERVEUR — AC-4 complet, D-1 referme »
 CLAUDE.md                                     | 25 +++++++++-----     ← liste « ce qui n'est pas prouvé » MISE À JOUR
 PROJECT_LOG.md                                |  1 +
 STORY_CERTIFICATION_BOARD.md                  | 16 +++++++++
 docs/stories/US-00.7-….md                     |  4 +--
 reports/US-00.7/applied_state/merge_refusal_server_405.txt | 8 +++
 reports/US-00.7/merge_proof_and_violation.md  | 38 ++++++++++++++++

$ git log --oneline a6301ba..HEAD -- docs/GIT_PROTECTION.md      → (vide)
$ git log --oneline a6301ba..HEAD -- reports/US-00.7/README.md   → (vide)
$ grep -c "405\|pull/14\|PR #14\|08:49" docs/GIT_PROTECTION.md   → 0
$ grep -c "405\|pull/14\|PR #14\|08:49" reports/US-00.7/README.md → 0
```

**`CLAUDE.md` et `docs/GIT_PROTECTION.md` portent la MÊME liste, parallèle.** Le commit du 405 a mis à jour
**l'une** et laissé **l'autre**. Si c'était une historisation délibérée, `CLAUDE.md` aurait été laissé
aussi. **C'est un oubli**, et il produit une **contradiction frontale entre deux documents vivants** :

> `CLAUDE.md:80` — « ✅ **Le refus d'une tentative de FUSION EST PROUVÉ — par le SERVEUR — depuis le
> 2026-07-29T08:49:14Z.** »
> `docs/GIT_PROTECTION.md:22` — « **Le refus d'une tentative de FUSION n'a pas encore été observé.** »

⚠️ **`CLAUDE.md` renvoie nommément à `GIT_PROTECTION.md` pour le détail.** Un lecteur qui suit le renvoi
depuis l'affirmation vraie atterrit sur l'affirmation fausse.

🟡 **Nuance que je pose honnêtement** : ce défaut **sous-affirme** — il nie une preuve acquise, il n'en
invente pas. **Il ne crée aucune confiance injustifiée dans la protection**, et c'est pourquoi je **ne le
retiens pas comme motif de FAIL** ni contre le critère 22 (dont les motifs littéraux — « n'est pas
protégée », « NON ATTEIGNABLE », « DETTE MAJEURE », « Upgrade to GitHub Pro » — sont **absents**, vérifié).
**Mais il contredit la thèse de l'US**, il vise l'auditeur (« à lire avant tout audit »), et il devra être
soldé avant `/certify`.

### 🟡 R2-4 — MINEUR · Une **cinquième** occurrence de `is_bot`, absente du décompte annoncé

Le balayage annoncé conclut à **quatre** emplacements (`merge_block.md`, Story File ×2, SCB). **J'en trouve
un cinquième** :

> `PROJECT_LOG.md:76` — « *…FUSIONNEE (main = 9fdb7fd) … par gitgdx (**is_bot: false -> case 34 de la DoD
> satisfaite, la fusion ne vient pas d un agent**)…* »

🟢 **Je ne le retiens pas comme défaut de fond** : le `PROJECT_LOG` est un **ledger strictement append-only**
dont la doctrine du projet est de rectifier **en fin de tableau** — ce qui **a été fait** (l. 92-93).
🟠 **Je le retiens comme défaut de MÉTHODE** : la ligne de rectification (l. 93) affirme « *figurait à
**TROIS** endroits* » et le message de commit « *TROIS endroits, pas un* ». **Le chiffre est faux dans le
document qui corrige un chiffre faux.** Le balayage a été **présenté comme exhaustif** alors qu'il portait
sur `--include="*.md"` — `PROJECT_LOG.md` **est** un `.md` et a bien été balayé, mais l'occurrence n'a pas
été comptée. **Troisième fois dans cette US qu'un balayage se déclare plus complet qu'il n'est.**

### 🟢 R2-5 — Ce que j'ai cherché et **N'AI PAS** trouvé — contrôles négatifs

| Hypothèse à écarter | Contrôle exécuté | Résultat |
|---|---|---|
| Autre méthode invalidée résiduelle | `grep` sur `mergeStateStatus` comme preuve de refus | **Aucune** — la distinction *état* vs *action* est correctement tenue partout |
| Hook `pre-push` se réclamant encore du seul enforcement | `grep -niE "SEUL ENFORCEMENT"` sur `scripts/githooks/pre-push` | **Corrigé** (l. 4 : « **N'EST PLUS LE SEUL** ») — **T20 tenu** |
| Sur-affirmation ajoutée | `grep` des 4 motifs du critère 24 | **0 occurrence** |
| Artefact daté falsifié | `git diff --stat` par famille | **0 ligne** |
| Trace réécrite | `git diff docs/trace/ \| grep -cE "^-[^-]"` | **0** — append-only |
| Historique réécrit | `merge-base --is-ancestor f4400ca HEAD` | **VRAI** |
| Contexte requis retiré | comparaison d'ensembles requis ↔ rapportés | **0 manquant, 0 hors cible** |
| Règle affaiblie | `--check-remote` | **exit 0**, 12 alignés, **0 écart** |
| Secret exposé | `gitleaks` sur 60 commits | **no leaks found** |
| PR #14 fusionnée | `gh pr view 14 --json mergedAt` | **`null`** — ⛔ **je ne l'ai pas fusionnée** |

---

## 9. ⚠️ AVERTISSEMENT OPÉRATIONNEL — reconduit et aggravé

**`gh pr view 14` → `mergeStateStatus: CLEAN` · `mergeable: MERGEABLE` · `mergedAt: null`.**

**La PR #14 est fusionnable à l'instant, par n'importe qui — y compris par un agent, y compris par
accident.** C'est la configuration exacte qui a produit la violation du `07:08:59Z`.

⛔ **Seul l'humain doit fusionner la PR #14**, avec l'**attestation datée** (NIVEAU 1) prévue par la case 34
refondue. **Je ne l'ai pas fusionnée et je ne le ferai pas.** Une seconde fusion par un agent rendrait R-c
violé deux fois et la certification sans fondement.

---

## 10. Ce qu'il faut faire pour lever ce FAIL — 3 corrections, aucune fabrication

| # | Action | Fichier | Coût |
|---|---|---|---|
| **1** | 🔴 **BLOQUANT** — traiter les **4** assertions restantes de `merge_block.md` : **bandeau daté à l'intérieur** de la section l. 36-49 *(on ne barre pas un titre)* · **barrer** l. 133 · **corriger la l. 173** — ⚠️ **cette ligne n'est pas à historiser mais à RENDRE VRAIE** : c'est un **index de fichiers**, il doit décrire ce qui existe. Écrire : *« `merge_refusal_raw.txt` — **EXISTE depuis `cb73997`** : refus `gh pr merge 13` du 2026-07-29T07:07:11Z, `exit=1` »*, puis ajouter la ligne `merge_refusal_server_405.txt` **absente de l'index** | `reports/US-00.7/merge_block.md` | 4 blocs |
| **2** | 🟠 Propager la rectification du 405 dans les **documents vivants oubliés** : `docs/GIT_PROTECTION.md:22` *(aligner sur `CLAUDE.md:80`)* · `reports/US-00.7/README.md:26` et `:44` · **renvoi croisé** à `SCB:625` et `SCB:701` vers `SCB:951` | 4 emplacements | 4 paragraphes |
| **3** | 🟡 Rectifier le **chiffre** du balayage : « trois endroits » → **cinq** (`PROJECT_LOG.md:76` inclus, **non modifié**, ledger append-only) | `PROJECT_LOG.md` *(ligne de fin)* | 1 ligne |

⛔ **Ce qui n'est PAS demandé** : retoucher `negative_test_server.txt` · ré-exécuter le test négatif ·
casser un gate pour obtenir un `failing` · tester `--admin` · rouvrir les critères 20/21 · **annuler la
fusion de la PR #13** · **supprimer** la moindre ligne · **fusionner la PR #14**.

📌 **Recommandation de méthode, transmissible à `/audit-methodo`** : ériger en convention que *barrer sans
supprimer* exige **(i)** l'exhaustivité dans le document rectifié, **(ii)** un **marqueur greppable**
(le ⛑️ y sert déjà), **(iii)** un **bandeau** — et non un barré — lorsque l'énoncé faux est un **titre de
section**. Cf. §4.

---

## 11. Couverture des 8 AC — **0 AC orphelin**

| AC | Critères | Couvert | Prouvé |
|---|---|---|---|
| **AC-1** — protection appliquée depuis la source unique | 14, 15, 16 | ✅ | ✅ **oui** *(re-observé en direct)* |
| **AC-2** — `exit 0` réel, in vivo | 17, 18 | ✅ | ✅ **oui** *(re-observé, 0 `[SIMULATION]`)* |
| **AC-3** — effet prouvé par le serveur | 10, 19, 20, 21 | ✅ | 🟡 **substance OUI** (3 refus `GH006` lus par moi) ; **garanties de méthode partielles** (20, 21) |
| **AC-4** — 4 status checks bloquants | 26, 27 | ✅ | 🟡 **nominal OUI, par le SERVEUR** (405) ; **erreur/limite NON** — le rapport de preuve est faux (27) |
| **AC-5** — corpus sans affirmation périmée, sans falsification | 13, 22, 23, 24 | ✅ | 🟡 **motifs littéraux absents et 0 falsification** ; **mais 3 documents vivants portent un énoncé périmé** *(R2-3)* |
| **AC-6** — dérogation déclarée sans objet | 24 | ✅ | ✅ **oui** *(3 emplacements)* |
| **AC-7** — dette NB-1 réduite, résidu nommé | 1-6 | ✅ | ✅ **oui** *(NB-1bis reproduit par moi)* |
| **AC-8** — verrouillage traité, retour arrière écrit | 7, 8, 9, 25 | ✅ | ✅ **oui** *(miroir vérifié présent)* |

> **AC orphelins : AUCUN.** Chaque AC est couvert par ≥ 2 critères, sauf **AC-6** (seul critère 24 —
> couverture mince mais réelle).
> ⚠️ **L'AC en défaut est AC-4 par sa clause *erreur/limite*** — le refus **est** prouvé, mais le document
> qui doit en administrer la preuve qualifiée **affirme qu'il ne l'est pas**.

---

## 12. Edge cases testés — au-delà des cas passants

| # | Edge case | Pourquoi | Résultat |
|---|---|---|---|
| 1 | **`cat` du fichier que le rapport déclare inexistant** | Ne pas croire une affirmation d'absence | **298 o, contenu réel, commit `cb73997`** → R2-1(d) 🔴 |
| 2 | **Comptage des marques `~~`** dans `merge_block.md` | Mesurer l'étendue réelle de la rectification | **2 lignes sur 173** → rectification **ponctuelle** |
| 3 | **`git log a6301ba..HEAD` sur `GIT_PROTECTION.md` et `README.md`** | Distinguer historisation délibérée d'oubli | **vide** → **oubli prouvé** 🔴 |
| 4 | Comparaison des **listes parallèles** `CLAUDE.md` ↔ `GIT_PROTECTION.md` | Deux documents portant la même liste ont-ils été traités pareil ? | **Non** → contradiction frontale |
| 5 | Balayage `is_bot` **toutes extensions**, pas seulement `.md` | Le balayage annoncé était-il complet ? | **5ᵉ occurrence** trouvée → R2-4 |
| 6 | **Comptage programmatique** des 34 cases (regex) | Ne pas croire le décompte annoncé | **31/34 exact**, 0 manquant, 0 doublon ✅ |
| 7 | Inventaire des **4 blocs d'état** de DoD et de leur étiquetage | Trois décomptes coexistants sont-ils une contradiction ? | **Non — ordonnés dans le temps** ✅ |
| 8 | `set(payload) == MAPPED_TOP_KEYS` | C'est ce contrôle qui rend l'`exit 0` fiable | **`True`**, diff symétrique `set()` ✅ |
| 9 | **Scénario B** — relâchement réel `enforce_admins:{"enabled":false}` | Un relâchement passe-t-il en vert ? | **exit 0** ⚠️ NB-1bis **réel** |
| 10 | **Scénario C** — clé absente des deux côtés | Est-elle seulement nommée ? | **exit 0**, **pas même nommée** ⚠️ |
| 11 | **Existence réelle** du clone miroir | Un plan de secours qui renvoie au vide n'en est pas un | **présent**, `main` = `f4400ca` ✅ |
| 12 | Recherche d'une **absence** : `hooksPath` / `rev-parse` / portée | Vérifier une absence, pas une présence | **0 / 0 / 0** → critères 20, 21 non levés |
| 13 | Comparaison d'ensembles **requis ↔ rapportés** (programmatique) | Un libellé peut diverger d'un caractère invisible | **0 manquant, 0 hors cible**, tous verts ✅ |
| 14 | Recherche d'un **runner BDD** | Les 24 scénarios sont-ils exécutables ? | **Aucun** → **0/0/0**, jamais « 24 verts » ✅ |
| 15 | `mergeStateStatus` de la PR #14 **à ma date** | Danger opérationnel ? | **`CLEAN`/`MERGEABLE`** → §9 ⚠️ |
| 16 | Recherche de jetons dans les preuves | Une preuve peut fuiter un secret | **0 porteur de valeur** ; `gitleaks` **0 fuite / 60 commits** ✅ |
| 17 | `grep` « SEUL ENFORCEMENT » sur le hook `pre-push` | T20 tient-il toujours ? | **Corrigé**, l. 4 ✅ |
| 18 | `merge-base --is-ancestor` ×2 | La fusion agent a-t-elle réécrit l'historique ? | **VRAI ×2** ✅ |

---

## 13. Ce que ce rapport n'établit PAS

1. **Rien n'est prouvé pour un autre acteur**, un **jeton d'application**, l'**interface web**, une PR issue
   d'un **fork** ou **réouverte**. Ma mesure vaut **à sa date** et **pour mon acteur**.
2. **Aucune surveillance n'est installée.** Mon `--check-remote` exit 0 est **ponctuel**. La dette « aucune
   détection automatique de dérive » reste **OUVERTE**.
3. **Tout dépend de la visibilité PUBLIQUE du dépôt.** Un retour en privé ramènerait le **403** et
   **rouvrirait la dérogation**.
4. **`NB-1bis` est OUVERT**, reproduit par moi. Non atteignable **aujourd'hui**
   (`set(payload) == MAPPED_TOP_KEYS` → `True`).
5. **Aucun `selftest` en CI** : tout ce que j'ai exécuté aux critères 1-6 l'a été **à la main**.
6. Le refus porte sur des contextes **`expected`**, **pas `failing`** : la conjonction littérale d'US-00.1
   (« `secrets-scan` **rouge** → merge empêché ») **reste non observée**. ⛔ Et je **ne demande pas** de
   casser un gate pour l'obtenir.
7. **La PROVENANCE n'est pas vérifiable par la machine sur ce dépôt** (un seul compte). Je m'appuie sur la
   **déclaration** du PROJECT_LOG pour dire que le 405 a été lancé par l'humain. **La substance du critère
   26 n'en dépend pas** (le serveur refuse quel que soit l'acteur) ; **la case 34 en dépend entièrement**,
   et c'est pourquoi elle est décochée.
8. **Je n'ai pas audité le code** — c'est l'office de `code_review.md` et `security_reaudit.md`, tous deux
   **PASSED**, que je n'ai ni rejoués ni contredits.
9. **Je n'absous ni ne sanctionne la violation de workflow.** Elle est actée, tracée, la case 34 est
   décochée ; cela relève de `/certify` et de l'humain, **pas de la QA**.

---

## 14. Conclusion

**🧪 FAIL** — **25/28 critères levés** · **3 non levés** (**20**, **21**, **27**) · **0 AC orphelin** ·
**DoD 31/34 (exact)** · unitaires **2/0/0**, couverture **89,5 %**, E2E BDD **0/0/0**.

**Ce que je certifie sans réserve** : **le travail technique d'US-00.7 est FAIT et PROUVÉ**, et je l'ai
intégralement ré-exécuté. La protection est appliquée depuis la source unique, son `exit 0` est réel et
sans `[SIMULATION]`, ses trois refus serveur sont archivés et portent `GH006`, **son refus de fusion est
prouvé par le serveur** (HTTP 405), la dette NB-1 est réduite avec son résidu nommé, **aucun artefact daté
ou certifié n'a été falsifié** *(0 ligne)*, la trace est **append-only** *(0 suppression)*, et **`gitleaks`
ne trouve aucune fuite sur 60 commits**. **Trois des quatre corrections demandées sont faites, et bien
faites** — le décompte DoD et la cohérence du Story File sont désormais **irréprochables**.

**Ce qui échoue est la quatrième — celle qui portait le motif du FAIL.** Elle a été appliquée **à la phrase
citée dans le renvoi** plutôt qu'**au fichier**. Le renvoi disait « *l'affirmation §3* » ; il a été lu au
pied de la lettre, et les quatre autres assertions fausses du même document — dont son **titre de section
le plus visible** et son **index de fichiers de preuve** — sont restées intactes. Le même réflexe explique
R2-3 : l'énoncé ② a été déclaré périmé **dans le document où on le corrigeait**, sans qu'on cherche où il
vivait ailleurs — et il vit dans **`GIT_PROTECTION.md`**, qui contredit maintenant **`CLAUDE.md`** sur un
fait porteur.

**Le motif de fond est le même qu'aux deux passages précédents, et il est temps de le nommer comme tel** :
**la correction suit le renvoi au lieu de suivre le défaut.** Un renvoi cite un exemple ; le défaut, lui, a
une extension. Tant que la remédiation se calera sur la citation, un quatrième passage trouvera une
cinquième occurrence.

**Ce n'est pas un détail de forme.** Une US dont la thèse entière est *« un document de gouvernance ne doit
jamais affirmer un état que la preuve contredit »* **ne peut pas être certifiée** avec, dans le livrable
qu'un de ses critères nomme, une section intitulée « *la preuve du REFUS DE FUSION n'a PAS été obtenue* »
suivie de « *Aucune formulation de ce rapport ne doit laisser croire l'inverse* » — **alors que la preuve
est obtenue, archivée, et citée douze lignes plus haut dans le même fichier**.

**Le coût de la correction reste de quelques paragraphes. Le coût de la complaisance serait la thèse de
l'US.**

---

*Rapport produit par @QA_Tester (`claude-opus-5[1m]`), contexte frais, le 2026-07-29.
Toutes les sorties citées proviennent de commandes réellement exécutées pendant cette session.
Aucun fichier de code, aucun Story File, aucune entrée du SCB, aucun fichier de preuve — et en particulier
ni [`qa.md`](qa.md) ni [`qa_reaudit.md`](qa_reaudit.md) — n'a été modifié. La PR #14 n'a pas été fusionnée.*
