# US-00.7 — Rapport de validation QA

> **Agent** : @QA_Tester · **Modèle** : `claude-opus-5[1m]` · **Contexte** : frais
> **Date** : 2026-07-28 · **Branche évaluée** : `feat/US-00.7-certif` (HEAD `1424d03`)
> **Périmètre réel de l'US** : `git diff f4400ca..HEAD` — **51 fichiers, 9 020 +/259 −**
> ⚠️ `git diff main...HEAD` est **trompeur** : la PR #12 est déjà fusionnée dans `main` (`9fdb7fd`).
> Périmètre vérifié par mes soins (§0.2), non repris sur la foi de la consigne.

---

## ⚖️ VERDICT : 🧪 **FAIL**

**Motif unique et décisif** : **l'AC-4 nominal n'est pas prouvé** — critère **26 NON LEVÉ**, case de
DoD **13** ouverte. La preuve du **refus d'une tentative de fusion** n'a jamais été produite : aucun
`gh pr merge` n'a été refusé, `applied_state/merge_refusal_raw.txt` n'existe pas. Ce qui a été capturé
est un `mergeStateStatus: BLOCKED` — un **état calculé**, **pas une action refusée**.

**Motifs aggravants (non suffisants seuls)** : critères **20** et **21** partiels.

⛔ **Ce FAIL n'est pas une sanction — c'est un renvoi actionnable.** La preuve manquante est
**obtenable sans travail artificiel** sur la PR de certification issue de cette branche même, selon la
procédure corrigée de [`merge_block.md`](merge_block.md) §*Comment cette preuve reste obtenable*.
Fenêtre utile mesurée : **~80 s**, pas « quelques minutes ».

✅ **Ce que je certifie par ailleurs** : **25 des 28 critères sont LEVÉS**, dont les 13 critères 🟢
**reproduits par moi-même** et non lus dans une archive. L'honnêteté du corpus est **remarquable** :
les trois défauts que je prononce (20, 21, 26) avaient **déjà été déclarés par l'US elle-même**
(É-8, É-9, `merge_block.md` en tête). **Je n'ai découvert aucune sur-affirmation.**

**Rappel d'autorité (Constitution Art. 5)** : je délivre un verdict `🧪`. La certification `🚀 OUI`
appartient au rituel `/certify` (@Architect), pas à moi.

---

## 0. Pré-conditions et exécutions de référence

### 0.1 Pré-conditions QA — **satisfaites**

```
$ python scripts/validate_trace.py --us US-00.7
Traçabilité conforme.
```

`docs/trace/US-00.7/events.jsonl` — **11 événements** :

| # | Événement | Agent |
|---|---|---|
| 8 | `EVT_SECURITY_AUDIT_FAILED` | cyber-security |
| **9** | **`EVT_CODE_REVIEW_PASSED`** | code-reviewer |
| 10 | `EVT_CODE_READY` | developer |
| **11** | **`EVT_SECURITY_AUDIT_PASSED`** | cyber-security |

→ Les deux pré-conditions d'`EVT_QA_PASSED` sont présentes. **Je peux statuer.**

### 0.2 Périmètre — vérifié, non supposé

```
$ git log --oneline origin/main..HEAD
1424d03 docs(us-00.7): N-1 traite — 4e ligne au plan de retour arriere
4faa272 docs(us-00.7): re-audit securite PASSED — double audit obtenu
9465116 fix(us-00.7): B-1 injection de commande dans branch-naming + actionlint en CI
0194078 docs(us-00.7): audits Rev + Sec — PASSED / FAILED (1 bloquant HIGH)
2dea2bb docs(us-00.7): T11 partielle — PR #12 fusionnee, refus de fusion NON obtenu

$ git ls-remote --heads origin
2686538…  refs/heads/feat/US-00.7-application-protection-branche
9fdb7fd…  refs/heads/main
```

→ **Les 5 commits ci-dessus ne sont sur AUCUNE référence distante.** Voir le finding **Q-1** (§5).

### 0.3 Gates — **exécutés**, tous verts

```
$ python scripts/run_gates.py --gate test
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:01 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test
Tous les gates bloquants passent (1 exécutés).   → exit 0
```

```
$ python scripts/run_gates.py --component app
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
Tous les gates bloquants passent (5 exécutés).   → exit 0
```

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (…).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : …
                                                                                    → exit 0

$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.                                            → exit 0
```

```
$ gitleaks detect --source . --config .gitleaks.toml --no-banner --redact
INF 51 commits scanned.
INF scanned ~2189183 bytes (2.19 MB) in 608ms
INF no leaks found                                                                   → exit 0
```

> ✅ **Correction d'un écart d'US-00.7 (É-7)** : @Developer n'avait **pas pu** exécuter `gitleaks`
> (absent de son `PATH`) et s'était rabattu sur un balayage par motif, **en le déclarant**. `gitleaks`
> **est** dans mon `PATH` : je l'ai exécuté sur **tout l'historique** (51 commits). **0 fuite.**
> L'É-7 est **refermé par exécution réelle**, plus fortement que le critère ne l'exigeait.

### 0.4 Décomptes de tests — **exigés par la Constitution Art. 3**

| Suite | passed | skipped | failed | Commentaire |
|---|---:|---:|---:|---|
| **Unitaires Flutter** (`flutter test`) | **2** | **0** | **0** | `widget_test.dart` — **non-régression** |
| **Couverture de lignes** | — | — | — | **89,5 % (17/19)** · seuil **80 %** → ✅ |
| **E2E BDD** *(scénarios Gherkin)* | **0** | **0** | **0** | **⚠️ voir ci-dessous — aucun n'est automatisé** |
| **Critères de test du Story File** | **25** | **0** | **3** | 28 critères, exécutés/vérifiés **un à un** (§2) |

> ⚠️ **AUCUN des 24 scénarios Gherkin n'est exécutable.** Contrôle : `tests/` ne contient que
> `features/` et `fixtures/` — **aucune step definition**, **aucun runner BDD** dans le dépôt.
> `e2e.yml` est un *smoke test* nocturne qui appelle `run_gates.py --component app`, **pas** un
> lanceur Gherkin, et il n'est **pas** un contexte requis.
> **Je ne compte donc AUCUN scénario Gherkin comme vert.** Ils sont **documentaires** : leur
> substance est portée par les **28 critères de test**, que j'ai exercés manuellement (§2).
> Conforme à la nature de l'US (plateforme/gouvernance, aucun code Dart) — mais **dit, pas tu**.

**Nature de l'US** : gouvernance et outillage. **0 fichier Dart** au périmètre → les suites unitaires
relèvent de la **non-régression**, pas d'un code neuf à couvrir. Le seul code modifié est **3 lignes
de Python** dans un comparateur en lecture seule.

---

## 1. Ce que j'ai **re-vérifié en direct**, plutôt que lu dans une archive

```
$ date -u                          → 2026-07-28T19:07:04Z
$ gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected}'
{"name":"main","protected":true}
$ gh api repos/gitgdx/Concentration --jq '{private,visibility,fork}'
{"fork":false,"private":false,"visibility":"public"}
$ python scripts/factory_sync.py --check-remote
… conforme à la cible générée par `factory_sync.py --emit-branch-protection` …    → exit 0
$ grep -c "SIMULATION" <sortie>    → 0
```

→ La protection est **toujours en vigueur au moment de ma mesure**, et l'`exit 0` est **réel**
(aucun préfixe `[SIMULATION]`). Je confirme les critères **15, 16, 17** par **observation directe**.

⚠️ **Portée de ma propre mesure** : elle vaut **à sa date** et **pour l'acteur employé** (jeton `gh`
de `gitgdx`, droits admin). Elle n'installe **aucune** surveillance : la dette « aucune détection
automatique de dérive » reste **OUVERTE**.

---

## 2. Les 28 critères de test — **verdict, preuve, commande**

> Légende : ✅ **LEVÉ** · ❌ **NON LEVÉ** · ⬜ **NON APPLICABLE**
> 🟢 = levable en branche · 🟠 = exige le `PUT` · 🔵 = exige une PR

| # | Cond. | Verdict | Preuve **obtenue par moi** | Commande exécutée |
|---|---|---|---|---|
| **1** | 🟢 | ✅ **LEVÉ** | **Faux vert REPRODUIT.** J'ai reconstruit un arbre temporaire portant le comparateur **d'avant le correctif** (`git show f4400ca:scripts/check_branch_protection.py`) : `exit 0`, « **conforme à la cible générée** », **11 alignés / 0 écart / 0 champ ACTIF non couvert** — sur une cible **amputée** de `enforce_admins` face à un réel `{"enabled": true}`. Toutes lignes préfixées `[SIMULATION]` | `git show f4400ca:scripts/check_branch_protection.py > <tmp>/scripts/…` puis `python <tmp>/tests/fixtures/US-00.7/nb1_harness.py` |
| **2** | 🟢 | ✅ **LEVÉ** | **exit 2** · `MAPPING INCOMPLET` · clé **nommée** : `enforce_admins = {"enabled": true}` · **1 champ ACTIF non couvert** · verdict « VERIFICATION IMPOSSIBLE — ce n'est PAS un succès ». ⚠️ *Nuance relevée* : le mot « conforme » apparaît **3×** dans la sortie, mais **jamais comme verdict** — uniquement dans la légende des codes de sortie (« 0 = « conforme » (**interdit** sur une comparaison incomplète) »). Exigence **substantiellement** tenue | `python tests/fixtures/US-00.7/nb1_harness.py` → `echo $?` = **2** |
| **3** | 🟢 | ✅ **LEVÉ** | **12 chemins rejoués par moi**, comparateur **pré-fixe vs post-fixe**, exits confrontés deux à deux : `0/0 · 1/1 · 1/1 · 2/2 · 2/2 · 2/2 · 2/2 · 2/2 · 0/0 · 2/2 · 2/2 · 2/2` → **12 × IDENTIQUE, 0 changement d'issue** | boucle `run2()` appelant les **deux** versions du comparateur sur les fixtures `US-00.4/*` |
| **4** | 🟢 | ✅ **LEVÉ** | **exit 0** · **10** champs additifs **NOMMÉS** `[IGNORÉ — NEUTRE]` (dont `bypass_pull_request_allowances`, `future_flag_absent`, `lock_branch`) · 12 alignés / 0 écart. Critère #24 d'US-00.4 **reste vert** | `python scripts/check_branch_protection.py --from-protection …/protection_cles_additives_neutres.json --from-branch …/branch_protected_true.json` |
| **5** | 🟢 | ✅ **LEVÉ** | **Résidu NB-1bis REPRODUIT par moi, il est réel.** **Scénario B** (cible amputée + réel **relâché** `enforce_admins: {"enabled": false}`) → **exit 0**, la clé est classée `[IGNORÉ — NEUTRE]` et l'outil dit « **conforme** » : *un relâchement réel passe en vert*. **Scénario C** (`required_pull_request_reviews` absent **des deux côtés**) → **exit 0**, la clé **n'est pas même nommée**. `nb1_fix.md` le documente **sans enjolivure** ; **aucune phrase n'affirme que NB-1 « ferme le trou »** | `nb1_harness.py --target …cible_amputee_enforce_admins.json --protection …protection_enforce_admins_false.json` *(idem pour C)* |
| **6** | 🟢 | ✅ **LEVÉ** | **8 clés** · `set(payload) == MAPPED_TOP_KEYS` → **`True`** (différence symétrique = `set()`) · `required_pull_request_reviews` **présent** `{"required_approving_review_count": 0}` · `restrictions: null` · `strict: true` · **4** contextes. **C'est ce contrôle qui rend l'`exit 0` fiable** : les scénarios B/C/D du critère 5 sont **inatteignables tant que la cible est complète** | `python scripts/factory_sync.py --emit-branch-protection` + comparaison à `cbp.MAPPED_TOP_KEYS` |
| **7** | 🟢 | ✅ **LEVÉ** | **Points de code imprimés par moi** : `U+1F510` · `U+1F4CB` · `U+1F4F1` · **aucun `U+FE0F`** · `ç` = **`U+00E7`**, `é` = **`U+00E9`** · `is_normalized('NFC')` → **`True`** pour les 4. Correspondance exacte : `ci.yml:43/62/108` (`name:`) et `branch-naming.yml:10` (**ID de job**, il n'a pas de `name:`) | script Python d'impression des points de code + `grep -n "^\s*name:" .github/workflows/*.yml` |
| **8** | 🟢 | ✅ **LEVÉ** | `--check` → **exit 0**, et sa **limite est écrite** : `labels_verification.md:152-154` — « `--check` compare la configuration au **FICHIER de workflow**, jamais au libellé que GitHub **rapporte** », renvoi explicite au critère **25** (l. 182) | `python scripts/factory_sync.py --check` |
| **9** | 🟢 | ✅ **LEVÉ** | Plan de retour arrière présent dans **`27464a9`** (`docs/GIT_PROTECTION.md:272`), et `git merge-base --is-ancestor 27464a9 6932fea` → **vrai** : **antérieur au commit du `PUT`**. Les 5 points y sont, dont la distinction décisive **`EXPECTED` (verrouillage) vs `FAILURE` (gate qui a fait son travail)** (l. 455-456) | `git log --oneline -- docs/GIT_PROTECTION.md` · `git show 27464a9:docs/GIT_PROTECTION.md` · `git merge-base --is-ancestor` |
| **10** | 🟢 | ✅ **LEVÉ** | `rollback_main.md` commité en **`27464a9`**, **avant** `66d2bab` (T10). SHA `f4400ca…`, chemin du miroir, commandes de restauration des 3 scénarios. **✅ J'ai vérifié que le miroir EXISTE RÉELLEMENT** — un plan renvoyant à une sauvegarde absente serait un défaut : `refs/heads/main` **et** `refs/remotes/origin/main` → **`f4400ca…`** | `git -C "…/_backup_US-00.7/Concentration-main-f4400ca.git" show-ref` |
| **11** | 🟢 | ✅ **LEVÉ** | **Aucun résultat** — le correctif NB-1 n'a introduit aucun chemin d'écriture. Confirmé par lecture du diff : seules la **signature** (l. 501), l'**intersection** (l. 515) et le **site d'appel** (l. 591) changent | `grep -nE "-X (PUT\|POST\|PATCH\|DELETE)\|requests\.(put\|post\|patch\|delete)" scripts/check_branch_protection.py` → exit 1 |
| **12** | 🟢 | ✅ **LEVÉ** | `grep -rn "check-remote" .github/workflows/` → **aucun résultat** (contrôle distant **toujours hors CI**, **aucun `selftest` ajouté** — dette maintenue). `git diff --stat f4400ca..HEAD` sur `factory.config.json`, `scripts/factory_sync.py`, `scripts/run_gates.py`, `.claude/hooks/`, `.gitleaks.toml`, `.claude/settings.json` → **VIDE, les 6 sont intacts** | `grep -rn "check-remote" .github/workflows/` · `git diff --stat f4400ca..HEAD -- <les 6>` |
| **13** | 🟢 | ✅ **LEVÉ** *(exigence dépassée)* | `corpus_sweep.md` porte **3 passes** (impossibilité · sur-affirmation · **routage vers ADR-006**, ajoutée), les **exclusions déclarées**, les **angles morts** (§2), l'inventaire des **11 artefacts vivants** avec leurs lignes, la liste des **artefacts datés à ne jamais réécrire** (§3.3), l'**aveu de méthode** (§ en-tête) et un **12ᵉ candidat** trouvé hors inventaire (§3.5). ⛔ **Exhaustivité explicitement NON revendiquée.** Un **piège de méthode rencontré est signalé** (§1.1 : exclusion silencieusement inopérante) | `grep -nE "^#+ \|Passe [12]\|exclusion\|angle mort\|exhaustivit" reports/US-00.7/corpus_sweep.md` |
| **14** | 🟠 | ✅ **LEVÉ** | `entry_state/` — **6 fichiers**, chacun en-tête de sa **commande exacte** et de son **horodatage UTC** (`07:11:32Z` → `07:12:15Z`). `…/protection` → **404** *(et non plus le 403 du 2026-07-26)* · `…/rulesets` → **200 `[]`** · `{"visibility":"public"}` · `--check-remote` → **exit 1**, **7 écarts**. **R3 d'US-00.4 est clos** — le chemin 404, déclaré « non observable in vivo », l'a été | lecture des 6 fichiers + `grep -nE "EXIT\|écart" entry_state/check_remote_exit1.txt` |
| **15** | 🟠 | ✅ **LEVÉ** | `branch_main_after.json` → **`"protected": true"`**, `PUT` émis par `apply_branch_protection.sh` consommant le payload **généré** (commande archivée). **Re-vérifié en direct par moi ce jour** → `{"name":"main","protected":true}`. ⚠️ *Dérive de nommage déclarée (É-2)* : le Story File annonçait `branch_after.json` | `gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected}'` |
| **16** | 🟠 | ✅ **LEVÉ** | `protection_applied.json` — **HTTP 200**. **9 points vérifiés un à un par moi** : `strict: true` · **4** contextes exacts · `required_pull_request_reviews` **PRÉSENT** avec `required_approving_review_count: 0` · `enforce_admins.enabled: true` · `required_conversation_resolution.enabled: true` · `allow_force_pushes.enabled: false` · `allow_deletions.enabled: false` · `required_linear_history.enabled: false` · clé **`restrictions` ABSENTE** ✅ | lecture intégrale de `applied_state/protection_applied.json` |
| **17** | 🟠 | ✅ **LEVÉ** | **Re-exécuté en direct** : `--check-remote` → **exit 0**, mot « conforme », **12 alignés / 0 écart / 0 champ ACTIF non couvert**, `grep -c SIMULATION` → **0**, aucune mention « SOURCE SIMULÉE ». **L'écart de preuve n° 3 d'US-00.4 est REFERMÉ** — et je l'observe **une seconde fois**, indépendamment | `python scripts/factory_sync.py --check-remote` → exit **0** |
| **18** | 🟠 | ✅ **LEVÉ** *(par vacuité + preuve négative opposable)* | L'`exit 0` a été obtenu **du premier coup** : ni `exit 1` ni `exit 2` à traiter. Le volet **opposable** est celui qui compte, et je l'ai vérifié : **`INERT_GET_KEYS` et le mapping n'ont PAS été ajustés** pour forcer le vert — le diff du comparateur ne montre que les **3 lignes** + docstring, et `scripts/factory_sync.py` est **intact** | `git diff f4400ca..HEAD -- scripts/check_branch_protection.py scripts/factory_sync.py` |
| **19** | 🟠 | ✅ **LEVÉ** | `negative_test_server.txt` — **3 sorties brutes** (stderr + code de retour). [1] et [2] : `remote: error: **GH006**: Protected branch update failed` · « *Changes must be made through a pull request* » · « ***4 of 4 required status checks are expected*** ». [3] : `! [remote rejected] main (refusing to delete the current branch)`. ⚠️ *Nuance* : [3] ne porte **pas** `GH006` — mais bien `[remote rejected]`, donc **refus serveur**. Le fichier **l'attribue lui-même honnêtement** (§Attribution) : ni `allow_force_pushes:false` ni `allow_deletions:false` ne sont **isolés** par ce test | lecture intégrale de `applied_state/negative_test_server.txt` |
| **20** | 🟠 | ❌ **NON LEVÉ** *(partiel)* | **Voir §3, défaut D-2.** Acquis : `origin/main` **inchangé** (`f4400ca`), **aucun** drapeau de contournement de hook. **Manquant** : (a) `git config --get core.hooksPath` → vide dans le clone jetable est **AFFIRMÉ** (« 0 hook exécutable, 0 configuration de hook »), **jamais archivé comme sortie brute** ; (b) la **suppression du clone jetable n'est attestée nulle part**. Écart **É-9, déclaré par @Developer** | `grep -rniE "hooksPath" reports/US-00.7/` → aucune occurrence dans `applied_state/` |
| **21** | 🟠 | ❌ **NON LEVÉ** *(partiel)* | **Voir §3, défaut D-3.** La garde est attestée **UNE FOIS** (l. 13 : « *Garde relue immediatement avant execution : protected=true, main=f4400ca* »), **pas avant chacune des 3 commandes**, et **sans** le triplet `{enforce_admins, allow_force_pushes, allow_deletions}` exigé. La **portée de la preuve** (« à sa date », « pour l'acteur employé », rien pour un autre acteur / un jeton d'application / l'interface web) est **ABSENTE du fichier de preuve** — je l'ai cherchée, `grep` ne rend **rien**. Elle existe ailleurs (`GIT_PROTECTION.md`, `CLAUDE.md`, `README.md`, `transmissions.md`), mais le critère **nomme ce fichier**. Écart **É-8, déclaré** | `grep -niE "acteur\|interface web\|jeton d.application\|a sa date" applied_state/negative_test_server.txt` → **exit 1, rien** |
| **22** | 🟠 | ✅ **LEVÉ** *(1 exception structurelle, contrainte par le critère 23)* | **Passe 1 rejouée par moi** sur les **11 artefacts vivants** : **10/11 propres**. Les 10 occurrences trouvées sont toutes **légitimes** — historisations **datées** (`EPIC_00:52,94` · `GIT_PROTECTION:5,69,84,339,559` · `audit-methodo:23`), la section explicitement titrée « *Les quatre faits du **2026-07-26*** », et **une constante de code** (`check_branch_protection.py:80` : `PLAN_MARKER = "upgrade to github pro"` — l'outil **doit** savoir reconnaître un 403 si le dépôt repassait en privé). **Seule exception** : `tests/fixtures/US-00.4/README.md:31`, artefact **daté** dont le critère **23 INTERDIT la réécriture** — démenti **en amont** par un encadré additif daté (l. 6). **Les deux critères sont en tension par construction ; l'US le déclare (É-3).** ✅ **Meilleur que ce que déclare @Developer (9/11)** : son décompte est **périmé**, T20 a depuis été fait (`0f6d63a`) et j'ai vérifié l'en-tête de `pre-push` — il dit désormais « **CE HOOK N'EST PLUS LE SEUL ENFORCEMENT** » | `grep -rniE "n.est PAS prot(e\|é)g(e\|é)e\|ne peut pas l.(e\|ê)tre\|NON ATTEIGNABLE\|impossible (a\|à) cocher\|DETTE MAJEURE\|Upgrade to GitHub Pro" <11 artefacts>` + classement manuel des 10 occurrences |
| **23** | 🟠 | ✅ **LEVÉ** | `git diff --stat f4400ca..HEAD` sur `docs/stories/US-00.4-*`, `reports/US-00.4/`, `docs/adr/ADR-006-*`, `docs/stories/US-00.1-*`, `tests/features/US-00.4-*`, `reports/US-00.3/` → **VIDE, 0 ligne**. `docs/trace/` → **+11 / −0**, exclusivement `US-00.7/events.jsonl` (**append-only respecté**). `tests/fixtures/US-00.4/README.md` → **27 ajouts, 0 suppression** — `grep -cE "^-[^-]"` = **0**, **purement additif** ✅ | `git diff --stat f4400ca..HEAD -- <familles>` · `git diff … -- tests/fixtures/US-00.4/README.md \| grep -cE "^-[^-]"` |
| **24** | 🟠 | ✅ **LEVÉ** | **Passe 2 rejouée par moi → 0 occurrence** de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance » sur les 11 artefacts. **Extinction de la dérogation** écrite et datée aux **3** emplacements, chacun **renvoyant à `EVT_WAIVER_GRANTED`** : `CLAUDE.md` (3 renvois) · `GIT_PROTECTION.md` (2) · `EPIC_00` risque #5 (1). **Conditionnalité** (retour en privé ⇒ 403 ⇒ dérogation **rouverte**) présente dans les 3. `/audit-methodo` **conservé et réorienté** vers la **PERSISTANCE** (l. 23) | `grep -rniE "inviolable\|tout est enforced\|impossible a contourner\|chaîne de confiance" <11>` → **exit 1** ; puis comptages `EVT_WAIVER_GRANTED` / `ÉTEINTE\|SANS OBJET` par fichier |
| **25** | 🔵 | ✅ **LEVÉ** | **Re-exécuté par moi.** Les **4** contextes requis de `protection_applied.json` sont rapportés **et tous `pass`**, aux libellés **identiques caractère pour caractère**. **R-1 ne se matérialise pas.** ⚠️ *Précision de décompte* : `gh pr checks 12` rend **5 lignes pour 4 libellés** — `check-branch-name` est rapporté **deux fois** (événements `push` **et** `pull_request`). Le critère dit « 4 checks » ; la réalité est **5 check-runs / 4 libellés distincts**, ce que `merge_block.md` documente déjà | `gh pr checks 12` → `check-branch-name` ×2 · `📋 Governance…` · `📱 App…` · `🔐 Secrets scan…`, **tous `pass`** |
| **26** | 🔵 | ❌ **NON LEVÉ** | **DÉFAUT BLOQUANT — voir §3, D-1.** `gh pr view 12 --json mergeableState` → `BLOCKED` **a bien été capturé** (`merge_block_pending.json`, `15:25:30Z`, antérieur à 3 des 4 contextes verts). **MAIS la seconde moitié, qui est le cœur de l'AC-4, manque** : **aucune tentative de fusion réelle n'a été lancée**, donc **aucun refus**, donc **aucun motif brut**. `merge_refusal_raw.txt` **n'existe pas**. Un `mergeStateStatus` est un **état calculé**, **pas une action refusée** — distinction que l'US pose elle-même. La **fin** du critère (« puis, les 4 verts, fusion acceptée ») **est** prouvée : fusion à `15:34:21Z`, **+7 min 32 s** après le dernier vert | `gh pr view 12 --json state,mergedAt,mergedBy` → `MERGED`, `2026-07-28T15:34:21Z`, `gitgdx` (`is_bot:false`) · `ls applied_state/merge_refusal_raw.txt` → **absent** |
| **27** | 🔵 | ✅ **LEVÉ** | **Aucun contournement — établi par la chronologie, pas par une déclaration** : la fusion a eu lieu à `15:34:21Z`, soit **7 min 32 s APRÈS** le passage au vert du dernier contexte requis (`📱 App`, `15:26:49Z`) → **aucun bypass n'était nécessaire**. Aucun `--admin`. **Aucun contexte retiré** : j'ai vérifié en direct que les **4** sont **toujours requis** (`--check-remote` exit 0 ce jour). **Règle non désactivée** : `protected: true` en continu. La **qualification honnête** est écrite (le refus démontré porte sur un contexte **`expected`**, **pas** rouge ; `strict: true` et `required_conversation_resolution` documentés comme **conditions supplémentaires**). **Revue humaine consignée** (R-c) **avec sa borne** : `reviewDecision` **vide**, `latestReviews` **tableau vide** → **aucune approbation GitHub formelle**, dette **R7 maintenue ouverte** | lecture de `merge_block.md` + recoupement chronologique via `gh pr view 12` et `--check-remote` |
| **28** | 🔵 | ✅ **LEVÉ** *(tel qu'écrit — mais lire le finding **Q-1**)* | **🟢 en branche, tout ré-exécuté par moi** : `factory_sync.py --check` **exit 0** · `check_scb_compliance.py` **exit 0** · `validate_trace.py --us US-00.7` **conforme** · `run_gates.py --component app` **5/5 exit 0** · `--emit-branch-protection` **inchangé, 8 clés** · **`gitleaks` exécuté pour de vrai : 0 fuite sur 51 commits** · aucun `ghp_`/`github_pat_`/`gho_`/`Authorization:` **porteur de valeur** dans `reports/US-00.7/` ni `tests/fixtures/US-00.7/` (les 8 correspondances sont des **auto-attestations** et des **motifs de grep cités**, pas des secrets). **🔵 sur PR** : les **4** contextes **verts en CI** sur la PR #12, dont `🔐 Secrets scan (gitleaks)`. ⚠️ **Observé sur le commit `2686538`, PAS sur `HEAD` (`1424d03`)** → **Q-1** | `gh pr checks 12` · `gitleaks detect --source .` · les 4 scripts de gouvernance |

### Décompte final des critères

| Verdict | Nombre | Numéros |
|---|---:|---|
| ✅ **LEVÉ** | **25** | 1-19, 22-25, 27, 28 |
| ❌ **NON LEVÉ** | **3** | **20**, **21**, **26** |
| ⬜ **NON APPLICABLE** | **0** | — |
| **Total** | **28** | |

**Par conditionnement** : 🟢 **13/13 levés** · 🟠 **9/11 levés** (20, 21 partiels) · 🔵 **3/4 levés** (26 non levé).

---

## 3. Défauts — format « Action effectuée → Résultat attendu → Résultat obtenu »

### 🔴 D-1 — BLOQUANT · AC-4 nominal non prouvé *(critère 26 · DoD case 13)*

> **Action effectuée** : recherche de la preuve du refus de fusion — `ls reports/US-00.7/applied_state/merge_refusal_raw.txt`, lecture intégrale de `merge_block.md`, interrogation de l'API sur la PR #12.
> **Résultat attendu** *(AC-4 nominal, critère 26)* : `mergeableState` = `BLOCKED` **ET** une **tentative de fusion réelle rejetée**, motif brut archivé (« *required status check … is expected / failing* »), pour le compte **administrateur** (`enforce_admins: true`).
> **Résultat obtenu** : **le premier terme seul.** `BLOCKED` capturé à `15:25:30Z` (`merge_block_pending.json`) — mais **aucun `gh pr merge` n'a jamais été lancé**, donc aucun refus, aucun motif brut, et `merge_refusal_raw.txt` **n'a jamais été créé**. Le fichier de preuve manquant est **déclaré absent** par l'US : « *Ce vide est la preuve de l'absence de preuve, il n'est pas comblé par un substitut.* »

**Cause racine, telle que l'US l'établit** : la fenêtre déterministe a été estimée « quelques minutes » en
extrapolant la durée **locale** du gate `📱 App` (build Flutter web, > 3 min sur le poste). **En CI ce
job a duré 1 min 23 s** → fenêtre réelle **~80 s**. La consigne humaine est arrivée après sa fermeture.

**Pourquoi c'est bloquant et non cosmétique** : `mergeStateStatus: BLOCKED` est un **état calculé par
GitHub**, pas une **action refusée**. C'est **exactement** la distinction — *prouvé par l'état de l'API*
vs *prouvé par l'effet* — que cette US et US-00.4 existent pour poser. La confondre ici reproduirait le
défaut fondateur qu'US-00.4 a passé deux jours à éliminer, **à l'endroit précis où il a été corrigé**.
Sur les **quatre** preuves annoncées comme neuves par le §*Règle du Pourquoi*, **trois** sont acquises
(push direct, force-push, suppression) ; **la quatrième — le refus de fusion — manque**.

**Correction attendue** : appliquer la procédure de `merge_block.md` sur la PR de certification issue de
`feat/US-00.7-certif`. **Lancer `gh pr merge <n> --merge` IMMÉDIATEMENT après l'ouverture, sans capture
préalable**, archiver le refus brut, **puis** constater les 4 verts et fusionner.
⛔ Interdits inchangés : `--admin`, désactivation temporaire de la règle, retrait d'un contexte,
**casse volontaire d'un gate** pour obtenir un rouge.

### 🟠 D-2 — MAJEUR · Critère 20 partiel — deux contrôles du clone jetable non attestés

> **Action effectuée** : `grep -rniE "hooksPath" reports/US-00.7/` ; recherche d'une attestation de suppression du clone jetable.
> **Résultat attendu** : dans le fichier de preuve, (a) `git config --get core.hooksPath` → **sortie vide archivée** ; (b) attestation que le clone jetable a été **supprimé**.
> **Résultat obtenu** : (a) le clone sans hooks est **AFFIRMÉ** en commentaire (« *0 hook executable, 0 configuration de hook dans le clone* ») mais **la commande n'est pas archivée** — aucune occurrence de `hooksPath` dans `applied_state/` ; (b) **aucune attestation de suppression**, nulle part.

**Circonstance atténuante réelle, et instructive** : le rapport `non_regression.md` (§ angle mort (a))
établit qu'un **hook d'enforcement de la factory empêche d'écrire ce contrôle de la façon la plus
naturelle** — `.claude/hooks/block_dangerous_bash.sh` bloque une **lecture** de `core.hooksPath`
imbriquée dans une substitution de commande, alors que son propre commentaire (l. 36-37) affirme
l'autoriser. **Écart « déclaré ≠ appliqué » DANS UN HOOK D'ENFORCEMENT** — candidat `/audit-methodo`.

**Ce qui EST acquis** : `origin/main` **inchangé** (`f4400ca`), **aucun** drapeau de contournement, et
l'attribution honnête de l'incident de procédure (première tentative lancée par erreur depuis le vrai
dépôt, refusée par le **hook local** — « *un refus LOCAL ne prouve rien* »). **Rien n'a été masqué.**

**Correction attendue** : action **humaine** — confirmer la suppression du clone jetable et, à la
prochaine exécution d'un test négatif, **archiver la sortie brute** de `git config --get core.hooksPath`.
⛔ **Ne pas modifier `negative_test_server.txt` a posteriori** : ce serait falsifier une archive.

### 🟠 D-3 — MAJEUR · Critère 21 partiel — garde de sûreté et portée de la preuve

> **Action effectuée** : `grep -niE "acteur|interface web|jeton d.application|a sa date" reports/US-00.7/applied_state/negative_test_server.txt`
> **Résultat attendu** : la garde `{enforce_admins, allow_force_pushes, allow_deletions}` archivée **immédiatement avant chacune des 3 commandes**, **et** la portée de la preuve écrite **dans ce fichier**.
> **Résultat obtenu** : **exit 1 — aucune occurrence.** La garde figure **une seule fois** (l. 13) et ne porte que `protected=true, main=f4400ca` — **pas** le triplet exigé. La portée n'est **pas** dans le fichier de preuve ; elle est dans `GIT_PROTECTION.md`, `CLAUDE.md`, `README.md` et `transmissions.md` — **mais le critère nomme ce fichier-là**.

**Correction attendue** : identique à D-2 — **ne pas retoucher l'archive**. Consigner la portée dans un
document d'accompagnement (c'est déjà fait dans 4 endroits) et **corriger la procédure** pour les
prochains tests négatifs.

---

## 4. Couverture des 8 AC — **aucun AC orphelin**, mais un AC **non prouvé**

| AC | Critères qui le couvrent | Couvert ? | Prouvé ? |
|---|---|---|---|
| **AC-1** — protection appliquée depuis la source unique | 14, 15, 16 | ✅ | ✅ **oui** |
| **AC-2** — `exit 0` réel, in vivo | 17, 18 | ✅ | ✅ **oui** *(re-observé par moi)* |
| **AC-3** — effet prouvé par le serveur | 10, 19, 20, 21 | ✅ | 🟡 **partiellement** — les **3 refus** sont prouvés (19) ; les **garanties de méthode** du clone ne le sont qu'en partie (20, 21) |
| **AC-4** — 4 status checks réellement bloquants | 26, 27 | ✅ | ❌ **NON — nominal non prouvé (D-1)** |
| **AC-5** — corpus sans affirmation périmée, sans falsification | 13, 22, 23, 24 | ✅ | ✅ **oui** *(1 exception structurelle déclarée)* |
| **AC-6** — dérogation déclarée sans objet | 24 | ✅ | ✅ **oui** |
| **AC-7** — dette NB-1 réduite, résidu nommé | 1, 2, 3, 4, 5, 6 | ✅ | ✅ **oui** *(intégralement reproduit par moi)* |
| **AC-8** — verrouillage traité, retour arrière écrit | 7, 8, 9, 25 | ✅ | ✅ **oui** |

> **AC orphelins : AUCUN.** Chaque AC est couvert par au moins deux critères, sauf AC-6 (un seul,
> le critère 24, qui porte à la fois AC-5 erreur et AC-6 — **couverture mince mais réelle**, et je l'ai
> vérifiée en direct sur les 3 emplacements).
>
> ⚠️ **La distinction qui compte** : *couvert* ≠ *prouvé*. **AC-4 a un test (critère 26) ; ce test n'a
> pas été exécuté.** Par la doctrine même de mon rôle — « *un scénario skipped n'est PAS un scénario
> vert* » (Constitution Art. 3) — **un test non exécuté ne vaut pas un test vert**. C'est le fondement
> du FAIL.

---

## 5. Findings QA propres — non couverts par les critères ni par les audits précédents

### 🟠 Q-1 — Le `ci.yml` et le `branch-naming.yml` **corrigés n'ont JAMAIS tourné en CI**, et ils touchent **deux contextes REQUIS**

**Fait établi** : `git ls-remote --heads origin` place la branche distante à `2686538` et `main` à
`9fdb7fd`. Les **5 commits** postérieurs — dont **`9465116`**, le correctif de sécurité B-1 — **ne sont
sur aucune référence distante**. Or `9465116` modifie :

1. **`branch-naming.yml`** — le job **`check-branch-name`**, **contexte REQUIS** ;
2. **`ci.yml`** — ajoute une étape `actionlint` **à l'intérieur du job `📋 Governance`**, **contexte REQUIS**.

**Pourquoi c'est sérieux** : avec `enforce_admins: true` et **4 contextes requis**, un contexte requis
qui devient **rouge** ou **jamais rapporté** rend **toute PR infusionnable, administrateur inclus** —
c'est le risque **R-1** que l'AC-8 existe pour prévenir. Or l'AC-8 vérifie les **libellés**, pas le
**comportement** des jobs. **Un correctif jamais exécuté dans son runner réel est une hypothèse.**

**Ce que j'ai fait plutôt que de m'en tenir au constat** — j'ai réduit le risque par exécution :

| Contrôle | Commande | Résultat |
|---|---|---|
| Empreinte épinglée d'`actionlint` **réellement valide** | `curl -fsSL …/actionlint_1.7.12_linux_amd64.tar.gz` + `sha256sum -c` | **`actionlint.tar.gz: OK`** — l'empreinte codée en dur est **exacte**, `sha256sum -c` ne fera pas échouer la CI |
| `actionlint` **passe** sur le dépôt tel qu'il est | `./actionlint` depuis la racine (les **3** workflows : `ci.yml`, `branch-naming.yml`, `e2e.yml`) | **exit 0, aucun diagnostic** → l'étape ne rendra pas `📋 Governance` rouge |
| Les **libellés de jobs** n'ont pas bougé | `git show 9465116 -- .github/workflows/` | **aucun `name:` ni ID de job modifié** → **aucun contexte requis cassé** |
| Le job `check-branch-name` **fonctionne encore** | simulation shell de son `run:` (7 cas, §6) | **cas passants OK, cas rejetants OK, injection neutralisée** |
| La branche est **à jour** (`strict: true`) | `git merge-base --is-ancestor origin/main HEAD` | **vrai** → pas de blocage pour branche périmée |

**Conclusion Q-1** : risque **résiduel FAIBLE** — mais **non nul et non prouvé dans le runner réel**.
Il **n'est pas un motif de FAIL** en soi. Il devient **sans objet** dès la PR de certification, qui
exécutera ces workflows — **et c'est la même PR qui doit produire la preuve manquante de D-1.**
**Les deux se règlent d'un seul geste.**

### 🟡 Q-2 — La DoD est **sous-comptée de 2** : elle annonce **28/34**, le réel est **30/34**

**Vérification de l'arithmétique** : cases décochées = **13, 23, 27, 28, 29, 31** → **6**. `34 − 6 = 28`.
**Le calcul est juste.** Mais **deux cases sont décochées à tort** :

| Case | Énoncé | Constat |
|---|---|---|
| **27** | `Audit Rev 🔍` validé par @CodeReviewer | **SATISFAITE** — `reports/US-00.7/code_review.md` (**PASSED**), `EVT_CODE_REVIEW_PASSED` en trace (l. 9), **SCB l. 17 = `✅ 🔍`** |
| **28** | `Audit Sec 🛡️` validé par @CyberSecurity | **SATISFAITE** — `security_reaudit.md` (**PASSED**, cycle 2), `EVT_SECURITY_AUDIT_PASSED` en trace (l. 11), **SCB l. 17 = `✅ 🛡️`** |

**Cause** : le bloc « État de la DoD — 28/34 » a été écrit au commit `2686538`, **antérieur** aux audits
(`0194078`, `4faa272`). Il est **périmé**, non faux à sa date. **Décompte réel au moment où j'écris :
30/34.**

**Les 4 cases restantes sont correctement ouvertes** : **13** (D-1, la seule case *livrable* encore
due) · **23** (arbitrage @PO sur le véhicule d'US-00.1) · **29** (QA — que je clos ici en **FAILED**) ·
**31** (SCB, fin de cycle). ⛔ **Je n'édite pas le Story File** (hors périmètre @QA).

**Aucune case cochée à tort** parmi les 28, avec **une réserve** :

> ⚠️ **Case 12** est cochée en affirmant « *`git rev-parse origin/main` **identique avant / après***».
> Ce couple **avant/après** n'est **pas archivé comme sortie brute** dans `negative_test_server.txt` ;
> l'invariance est établie **autrement** (relevé de garde + `GET …/git/ref/heads/main` → `f4400ca`) —
> ce qui **est** convaincant, mais **pas ce que la case décrit**. Même famille que D-2/D-3.

### 🟢 Q-3 — Aucun scénario Gherkin n'est automatisé, et rien dans le dépôt ne le prétend

`tests/` = `features/` + `fixtures/`. **Aucune step definition, aucun runner BDD.** Les **24 scénarios**
sont **documentaires**. **Ce n'est pas un défaut de cette US** (aucune UI, aucun code applicatif, et le
track STANDARD n'exige pas d'E2E dédiés) — mais je le **consigne** parce que l'arbitrage de track a
justifié le refus du track FULL par le fait que « *zéro E2E est possible* » : **c'est exact, et
vérifié**. Le décompte honnête est donc **0 passed / 0 skipped / 0 failed**, et **non** « 24 verts ».

---

## 6. Edge cases testés — au-delà des cas passants

| # | Edge case | Pourquoi | Résultat |
|---|---|---|---|
| 1 | Comparateur **pré-correctif** ressuscité depuis `git show f4400ca:…` dans un arbre isolé | Ne pas croire une archive du « avant » : **le reproduire** | **exit 0 « conforme »** — faux vert **confirmé** |
| 2 | **Scénario B** — cible amputée + réel **relâché** (`enforce_admins: {"enabled": false}`) | Un **relâchement réel** passe-t-il en vert après correctif ? | **exit 0** — ⚠️ **oui**. NB-1bis **réel** |
| 3 | **Scénario C** — clé absente **des deux côtés** (`required_pull_request_reviews`) | « Aucune PR exigée » est-il seulement **nommé** ? | **exit 0**, **pas même nommé**. NB-1bis **réel** |
| 4 | **12 chemins** d'US-00.4 rejoués **sur les deux versions** du comparateur | Le correctif casse-t-il un chemin existant ? | **12 × identique** — aucune régression |
| 5 | Fixture **additive neutre** (10 champs inconnus) | L'outil devient-il rouge à chaque évolution de l'API ? | **exit 0**, tous **nommés** `[IGNORÉ — NEUTRE]` |
| 6 | Empreinte **SHA256 épinglée** d'`actionlint` re-téléchargée et vérifiée | Un asset amont remplacé **arrêterait la CI** (finding N-1) | **`OK`** — empreinte exacte |
| 7 | `actionlint` exécuté sur **les 3** workflows, dont `e2e.yml` (hors périmètre du correctif) | La nouvelle étape peut rendre rouge un contexte **requis** | **exit 0**, aucun diagnostic |
| 8 | `check-branch-name` — **`chore/menage`** | Le job **rejette-t-il** encore ? | **exit 1** ✅ |
| 9 | `check-branch-name` — **injection `feat/US-1.1-$(id -un)`** *(le finding B-1)* | La charge est-elle **exécutée** ? | **chaîne littérale, exit 0** — `id -un` **non évalué** ✅ |
| 10 | `check-branch-name` — **injection par accents graves** `` feat/US-1.1-`id -un` `` | Variante non testée par l'audit sécurité | **chaîne littérale** — **neutralisée aussi** ✅ |
| 11 | `check-branch-name` — **`head_ref` vide** (PR de fork malformée) | Un vide passe-t-il en douce ? | **exit 1** ✅ |
| 12 | `check-branch-name` — événement **`push`** (`ref_name`) | Les deux branches du `if` fonctionnent-elles ? | **exit 0** ✅ |
| 13 | **Existence réelle** du clone miroir de sauvegarde | Un plan de secours qui renvoie au vide n'en est pas un | **présent**, `refs/heads/main` = **`f4400ca`** ✅ |
| 14 | `gitleaks` sur **tout l'historique** (51 commits), dépôt **public** | @Developer n'avait pas pu l'exécuter (É-7) | **0 fuite** ✅ |
| 15 | Recherche de la **phrase de portée** dans le fichier de preuve nommé par le critère 21 | Vérifier une **absence**, pas une présence | **absente** → D-3 |
| 16 | Recherche de `merge_refusal_raw.txt` | Vérifier que le vide déclaré **est** un vide | **absent** → D-1 confirmé |
| 17 | Chronologie fusion (`15:34:21Z`) vs dernier contexte vert (`15:26:49Z`) | Un bypass aurait-il été **nécessaire** ? | **+7 min 32 s** → **non** ✅ |
| 18 | `git merge-base --is-ancestor origin/main HEAD` | `strict: true` **sérialise** les merges | branche **à jour** ✅ |

---

## 7. Ce que ce rapport n'établit pas

1. **Rien n'est prouvé pour un autre acteur**, un **jeton d'application**, l'**interface web**, une PR
   issue d'un **fork** ou **réouverte**. Ma propre mesure vaut **à sa date** et **pour mon acteur**.
2. **Aucune surveillance n'est installée.** Mon `--check-remote` exit 0 est **ponctuel**. La dette
   « aucune détection automatique de dérive » reste **OUVERTE** — un administrateur peut supprimer la
   règle **sans qu'aucun mécanisme ne le signale**.
3. **Tout dépend de la visibilité PUBLIQUE du dépôt.** Un retour en privé ramènerait le **403**, rendrait
   la protection **indisponible** et **rouvrirait la dérogation**.
4. **`NB-1bis` est ouvert** et je l'ai **reproduit** : un **relâchement réel** passe en `exit 0`. Il n'est
   pas atteignable **aujourd'hui** (`set(payload) == MAPPED_TOP_KEYS` → `True`), il le deviendrait dès
   qu'une clé serait retirée de `factory.config.json`.
5. **Aucun `selftest` en CI** : tout ce que j'ai exécuté aux critères 1-6 l'a été **à la main**. Rien
   n'empêche une régression du comparateur.
6. **Je n'ai pas audité le code** — c'est le rôle de `code_review.md` et `security_reaudit.md`, tous deux
   **PASSED**, que je n'ai ni rejoués ni contredits.

---

## 8. Conclusion

**🧪 FAIL** — **25/28 critères levés**, **3 non levés** (**20**, **21**, **26**), **0 AC orphelin**,
**1 AC non prouvé (AC-4 nominal)**, **DoD réelle 30/34** *(et non 28/34)*.

**Le seul motif rédhibitoire est D-1.** Les défauts D-2 et D-3 sont des **manques d'archivage de
méthode**, réels mais non structurants, et **déjà déclarés** par l'US. Q-1 est un **risque maîtrisé**
que j'ai réduit par exécution.

**Ce qui me frappe, et que je consigne à décharge** : je n'ai trouvé **aucune sur-affirmation**. Les
trois défauts que je prononce avaient **tous été nommés par l'US elle-même** avant que je n'arrive —
`merge_block.md` place l'échec de T11(d) **en tête, en gras, avant toute réussite**, et
`non_regression.md` déclare 20 et 21 comme partiels. **Une US qui documente son propre échec au premier
paragraphe n'est pas une US qui triche** ; c'est exactement le comportement que la Constitution cherche
à produire. **Elle n'est simplement pas finie.**

**Chemin de sortie — un seul geste** : la PR de certification issue de `feat/US-00.7-certif` exécutera
les workflows jamais testés (**Q-1 se referme**) **et** rouvrira la fenêtre de ~80 s nécessaire au refus
de fusion (**D-1 se referme**). Le re-passage QA pourra alors être **strictement ciblé** sur le
critère **26**.

---

*Rapport produit par @QA_Tester (`claude-opus-5[1m]`), contexte frais, le 2026-07-28.
Toutes les sorties citées proviennent de commandes réellement exécutées pendant cette session.
Aucun fichier de code, aucun Story File, aucune entrée du SCB n'a été modifié.*
