# Audit Rev 🔍 — **CYCLE 2 (re-audit)** — US-00.4 « Enforcement de la branche principale : constat, vérification honnête et cible armée »

**Agent** : @CodeReviewer · **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-27
**Contexte** : **FRAIS** (Constitution Art. 2 / règle 5 de `CLAUDE.md`). Je ne suis **pas** l'auteur du
cycle 1 et je n'ai pas accès à sa session. **Rien n'a été pris pour acquis** : ni le code, ni
`reports/US-00.4/code_review.md`, ni les affirmations de correction du Story File, ni l'audit Sécurité.
Chaque fait de ce rapport est adossé à une commande que j'ai exécutée moi-même.
**Branche auditée** : `feat/US-00.4-ci-protection-branche` (`2b40e5a`) · **Base** : `main` (`801a046`)
**Ce fichier ne remplace pas `code_review.md`** — celui-ci reste la preuve du cycle 1 (verdict FAILED).

---

## ✅ VERDICT : **PASS**

| Sévérité | Nombre |
|---|---|
| 🔴 **Bloquants** | **0** |
| 🟠 Non bloquants | **11** |
| 🔵 Suggestions d'amélioration | 6 |

**Les 2 bloquants du cycle 1 sont fermés, et je l'ai vérifié en cherchant activement à les
rouvrir**, pas en lisant les affirmations de correction :

- **B-2 (faux vert)** — **fermé**. J'ai écrit **26 fixtures d'attaque hors du dépôt** et **je n'ai pas
  réussi** à fabriquer une réponse qui **relâche** l'enforcement réel et sorte en **exit 0**, pour
  toute forme que l'endpoint `…/branches/{b}/protection` de GitHub **émet réellement**. Le cas exact
  du cycle 1 (`lock_branch: {"enabled": true}`) sort désormais en **exit 2** en nommant la clé. La
  frontière de couverture à trois catégories est **juste** — §4.
- **B-1 (over-claim d'exhaustivité)** — **fermé**. Les deux affirmations falsifiables ont **disparu du
  corpus** (vérifié par grep sur tout le dépôt) et `false_claims_sweep.md` §5 s'intitule désormais
  « **l'exhaustivité n'est PAS revendiquée** », avec ses trois angles morts nommés. Mon balayage
  indépendant, toutes extensions, avec **mes** motifs, remonte **1 occurrence résiduelle non
  déclarée** — mais elle **ne falsifie plus aucune affirmation**, puisque plus aucune n'est faite :
  c'est un **résiduel**, pas un mensonge. Non bloquante — §5.

**Ce que je ne valide pas par déférence** : je maintiens 11 findings non bloquants, dont **5 trous
résiduels du comparateur que j'ai démontrés par exécution** (NB-1 → NB-5). Aucun n'est atteignable
avec une réponse que l'API GitHub peut produire aujourd'hui, ou n'est atteignable qu'au prix de
l'édition d'un fichier **Art. 6** (action humaine). Ils ne satisfont donc pas mes critères bloquants.

---

## 1. Gates statiques — sorties collées

### 1.1 Remarque de méthode : les gates `lint` / `typecheck` n'existent pas dans cette factory

```
$ python scripts/run_gates.py --gate lint
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1

$ python scripts/run_gates.py --gate typecheck
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1

$ python -c "…factory.config.json → adapter.components…"
['app']
['format', 'analyze', 'test', 'deps_audit', 'build']
```

`adapter.components` ne contient que `app` (Flutter). **Aucun gate Python n'existe**, alors que
l'unique livrable de code de cette US est un script Python de **1023 lignes**. Aucun linter Python
n'est installé sur la machine :

```
$ python -m ruff --version / pyflakes / mypy / flake8 / pylint
No module named ruff · pyflakes · mypy · flake8 · pylint   (les 5)
$ python --version
Python 3.14.6
```

**Cette absence est une dette de la factory, pas de l'US** (déjà consignée dette #9). Elle est
**identique au cycle 1** — je la re-constate en propre. J'ai donc substitué : compilation, contrat de
module, gates de gouvernance, gates de l'adapter, et **rejeu exécutoire intégral** (§3, §4).

### 1.2 Substituts (compilation + contrat de module)

```
$ python -m py_compile scripts/check_branch_protection.py scripts/factory_sync.py
py_compile OK exit=0
```

### 1.3 Gates de gouvernance — ceux du job CI `governance`

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
EXIT=0

$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.
EXIT=0

$ python scripts/validate_trace.py --all
Traçabilité conforme.
EXIT=0
```

→ **`--check` exit 0 après modification de `ci.yml` : les 4 libellés de jobs résolvent toujours**
(critère #26 satisfait — c'était le risque de régression du correctif B-1).

### 1.4 Gates de l'adapter — non-régression

```
$ python scripts/run_gates.py --component app
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...                             58,2s
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

*(Aucun fichier Dart n'est touché par cette US : `git diff main...HEAD --name-only` ne contient aucun
`*.dart`. Les **5 gates de l'adapter passent** — non-régression confirmée. Le gate `app.build` a
dépassé le budget de temps d'un appel synchrone : je l'ai relancé en tâche de fond et j'en colle la
sortie finale ci-dessus.)*

⚠️ **La branche n'est pas poussée** : `git ls-remote --heads origin` ne renvoie que `main` et
`feat/US-01.1-…`. **Aucun run CI n'existe pour ce code** — les gates ci-dessus sont **mes exécutions
locales**. Le critère « 4 checks rapportés verts sur la PR » reste **non levé** (à lever par
@DevOps / @QA), et le gage `gitleaks` réel de la CI aussi.

---

## 2. Vérification indépendante du constat (AC-1) — je n'ai rien repris des preuves archivées

`gh` était absent du `PATH` de ma session ; j'ai employé le chemin absolu documenté par le Story File
(`C:\Program Files\GitHub CLI`) — **le piège documenté est réel et la parade fonctionne**.

```
$ gh --version                 → gh version 2.96.0 (2026-07-02)
$ gh auth status               → Logged in to github.com account gitgdx · Token scopes: 'gist','read:org','repo','workflow'

$ gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected}'
{"name":"main","protected":false}                                                    exit=0

$ gh api repos/gitgdx/Concentration/branches/main/protection
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"403"}
gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)   exit=1

$ gh api repos/gitgdx/Concentration/rulesets
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"https://docs.github.com/rest/repos/rules#get-all-repository-rulesets","status":"403"}
gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)   exit=1

$ gh api repos/gitgdx/Concentration --jq '{private, visibility, owner_type: .owner.type, permissions}'
{"owner_type":"User","permissions":{"admin":true,"maintain":true,"pull":true,"push":true,"triage":true},
 "private":true,"visibility":"private"}                                              exit=0
```

**Les faits (a), (c), (d) de l'AC-1 sont confirmés en propre** : message **identique** sur les **deux**
mécanismes, avec un jeton `admin: true` sur un dépôt `private: true`. La cause est bien **le plan** —
ni les droits, ni la configuration. Le périmètre re-cadré de l'US est **factuellement fondé**.

### 2.1 AC-1 fait (b) — l'inférence est-elle écrite comme telle, ou présentée en fraude ?

**Écrite comme telle. Pas de fraude — l'AC ne tombe pas sur sa propre règle de preuve.** Trois
artefacts distincts le disent, dont **la preuve elle-même** :

```
$ (relecture ciblée du motif « inférence », encodage UTF-8)
reports/US-00.4/enforcement_gap.md:23 : « check_runs.json (HTTP 200) + inférence — voir §1.1 »
reports/US-00.4/enforcement_gap.md:41 : « ### 1.1 Le fait (b) est prouvé en deux morceaux — dont une inférence, écrite comme telle »
reports/US-00.4/enforcement_gap.md:55 : « 2. Aucun n'est requis → INFÉRENCE depuis "protected": false »
docs/GIT_PROTECTION.md:38, :45       : « (exécution) + inférence » · « est une INFÉRENCE depuis "protected": false »
reports/US-00.4/check_runs.json:12-15 : « ⚠️ PORTÉE DE CETTE PREUVE — elle établit UNIQUEMENT que les 4
   checks S'EXÉCUTENT et sont verts. Elle NE dit RIEN de leur caractère requis ou bloquant. […]
   la seconde moitié du fait est une INFÉRENCE, pas une lecture d'API. »
```

La règle de preuve « réponses brutes datées de l'API » est honorée pour (a), (c), (d) ; pour (b), la
moitié lisible est brute (`check_runs.json`, HTTP 200, horodaté) et la moitié inférée est
**déclarée, datée, et bornée à l'endroit même où elle est produite**. C'est le traitement correct :
l'inférence est **inévitable** puisque l'endpoint autoritatif est en 403, et l'US **ne la maquille
pas en lecture directe**.

---

## 3. Lecture seule, R1, contrat de module — contrôles exécutoires

### 3.1 Lecture seule — contrôlée au-delà du critère #11

```
$ grep -nE '\-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)' scripts/check_branch_protection.py
grep_exit=1  (aucun résultat — critère #11 satisfait)

$ grep -nE 'method\s*=|data\s*=' scripts/check_branch_protection.py
373:        method="GET",                      ← unique occurrence, aucun `data=`

$ grep -nE '\bopen\(|write_text|write_bytes|mkdir|unlink|rmtree|os\.remove|shutil\.(copy|move|rmtree)' …
687:    out_path.parent.mkdir(…)   ┐ uniquement write_raw(), atteignable seulement par --raw-out,
709:    out_path.write_text(…)     ┘ lui-même REFUSÉ en mode fixture (vérifié §3.3)

$ grep -nE 'subprocess\.(run|check_output|Popen|call|check_call)' -A2 …
256: [sys.executable, SYNC_SCRIPT, flag]              (génération de la cible)
284: ["git", "remote", "get-url", "origin"]           (résolution du dépôt)
322: [gh_bin, "api", path]                            (GET, aucun drapeau de méthode)

$ grep -nE 'os\.system|shell\s*=\s*True|\beval\(|\bexec\(' …
grep_exit=1  (aucun résultat)
```

**Les 3 sous-processus sont en forme liste, sans `shell=True`** : aucune injection de commande n'est
possible. `urllib` est explicitement `method="GET"` sans `data=`.

### 3.2 Injection par `--repo` — sondée

```
$ python scripts/check_branch_protection.py --repo 'zzz-nope-owner/zzz --method DELETE'
Lecture SEULE de l'API GitHub (GET uniquement) — … · GET repos/zzz-nope-owner/zzz --method DELETE/branches/main → 404
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès                                       EXIT=2

$ python scripts/check_branch_protection.py --repo '../../user/repos'
… → repo rejeté par la garde (3 « / ») → dérivation depuis git remote → gitgdx/Concentration · 403   EXIT=2

$ python scripts/check_branch_protection.py --repo 'a/$(touch /tmp/PWNED)'
… → repo rejeté (garde `count("/") == 1`) → gitgdx/Concentration · 403                 EXIT=2
$ ls /tmp/PWNED  → No such file or directory
```

La valeur de `--repo` est **enchâssée au milieu** d'un chemin (`repos/{repo}/branches/{b}`) transmis
comme **un seul élément d'argv** : elle ne peut jamais être relue comme un drapeau par `gh`, et
`gh api` sans `-X` est un GET. **Aucune injection de méthode d'écriture n'est atteignable.**

```
$ git ls-remote origin refs/heads/main   (après toutes mes sondes hostiles)
801a046e7c2f833a4038c4080e0eb19ca0d28754   ← INCHANGÉE
```

### 3.3 R1 — le piège de la simulation : marquage `[SIMULATION] ` audité ligne par ligne, sur 16 invocations

J'ai capturé **stdout + stderr** de 16 formes d'invocation et compté les lignes non vides **non
préfixées** :

| Invocation | EXIT | lignes | **non préfixées** |
|---|---|---|---|
| conforme + branch | 0 | 18 | **0** |
| divergente | 1 | 21 | **0** |
| 404 + `protected:false` | 1 | 14 | **0** |
| 404 + `protected:true` | 2 | 6 | **0** |
| `lock_branch` actif | 2 | 20 | **0** |
| clés additives neutres | 0 | 18 | **0** |
| `--from-protection` seul | 2 | 3 | **0** |
| `--from-branch` seul | 2 | 3 | **0** |
| `--from-protection-status 404` seul | 2 | 3 | **0** |
| **`--from-protection-status 0` seul** | 2 | 3 | **3** ⚠️ **NB-7** |
| fixture inexistante | 2 | 4 | **0** |
| fixture non-JSON (`README.md`) | 2 | 4 | **0** |
| `--repo` en mode fixture | 2 | 3 | **0** |
| **`--raw-out` en mode fixture** | 2 | 3 | **0** |
| `--from-protection-status abc` (type invalide) | 2 | 5 | **5** ⚠️ argparse |
| drapeau inconnu (`--wat`) | 2 | 5 | **5** ⚠️ argparse |

**Conclusion R1** : le préfixe est sur **chaque ligne** que le comparateur émet **au sujet d'une
issue de vérification**, sans exception, y compris les erreurs d'usage et l'exit 2. Les **deux**
exceptions sont (i) le message d'usage d'**argparse** (hors du `Reporter`, exit 2, impossible à
confondre avec un résultat) et (ii) le cas **falsy** `--from-protection-status 0` (NB-7). **Aucune
des deux ne peut produire un exit 0 ni le mot « conforme » sans marquage.**

**`--raw-out` est bien refusé en mode fixture**, et le refus est effectif :

```
$ python scripts/check_branch_protection.py --from-protection …/protection_conforme.json \
        --from-branch …/branch_protected_true.json --raw-out /tmp/should_not_exist.txt
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Cause : ERREUR D'USAGE — --raw-out est refusé en mode fixture : archiver une réponse
               SIMULÉE comme une réponse brute de l'API la rendrait relisible comme une preuve d'état réel (R1)
EXIT=2
$ ls /tmp/should_not_exist.txt → No such file or directory   ← aucun fichier créé
```

**Un exit 0 archivé peut-il être relu comme une preuve d'état réel ?** Pour la sortie de l'outil :
**non** (préfixe sur 100 % des lignes + `SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt`). Pour
le **fichier d'archive** : réserve **NB-8** maintenue (les lignes d'encadrement de l'archiviste ne
portent pas le marquage).

### 3.4 Exit 2 réel — reproduit à l'identique de l'archive

```
$ python scripts/factory_sync.py --check-remote        (avec gh dans le PATH)
Lecture SEULE de l'API GitHub (GET uniquement) — gitgdx/Concentration:main · GET repos/gitgdx/Concentration/branches/main → 200 · GET repos/gitgdx/Concentration/branches/main/protection → 403
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Code HTTP : 403 — protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut lire ni appliquer la protection en l'état. Message API : 'Upgrade to GitHub Pro or make this repository public to enable this feature.'
  Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
EXIT=2

$ python scripts/check_branch_protection.py            (invocation directe, idem)  EXIT=2
$ python scripts/factory_sync.py --check-remote         (SANS gh ni jeton)
  Cause : `gh` introuvable dans le PATH ET aucun jeton GH_TOKEN/GITHUB_TOKEN …      EXIT=2
$ grep -ci "conform" reports/US-00.4/check_remote_exit2.txt   →  0
```

L'attribution reste **honnête dans les deux cas** : le 403 de plan n'est jamais confondu avec un
défaut de droits, et l'absence de transport n'est jamais confondue avec un 403.

---

## 4. 🔬 B-2 — la frontière de couverture est-elle juste ? **26 fixtures d'attaque, écrites hors du dépôt**

**Réponse directe à la question centrale : NON, je n'ai pas réussi à fabriquer une réponse qui
relâche l'enforcement réel et sorte en exit 0**, pour toute forme que l'endpoint
`GET …/branches/{b}/protection` de GitHub **émet réellement**. Le faux vert B-2 est **fermé**.

Méthode : 25 fixtures dérivées de `protection_conforme.json` + 1 fixture de relâchement, **écrites
dans le scratchpad hors du dépôt**, jouées contre le comparateur du dépôt.

### 4.1 Cas où l'outil se comporte correctement (fail-explicit) — **13 / 26**

| # | Attaque | Attendu | **Obtenu** |
|---|---|---|---|
| a1 | clé active de **type inattendu** : `future_thing: 42` | 2 | **2** ✅ `MAPPING INCOMPLET` |
| a2 | **valeur limite `0`** : `future_thing: 0` | 2 | **2** ✅ (`0 is False` → faux en Python : correctement classé ACTIF) |
| a3 | chaîne non vide : `future_thing: "actif"` | 2 | **2** ✅ |
| a8 | `future_thing: true` | 2 | **2** ✅ |
| c2 | valeur active cachée à **profondeur 4** : `{"a":{"b":{"c":{"d":true}}}}` | 2 | **2** ✅ garde `NEUTRAL_MAX_DEPTH` **fail-safe** |
| c3 | valeur active à profondeur 2 | 2 | **2** ✅ récursion correcte |
| d1 | **sous-objet mappé** porteur d'une clé active : `required_status_checks.enforcement_level: "off"` | 2 | **2** ✅ |
| d2 | `required_pull_request_reviews.bypass_pull_request_allowances.users` **non vide** (= dispense de PR) | 2 | **2** ✅ |
| f1 | **`restrictions` NON nul** (présent dans la réponse) | 1 | **1** ✅ écart |
| f2 | **`required_pull_request_reviews` absent** | 1 | **1** ✅ « aucune pull request exigée » |
| f3 | `required_approving_review_count` absent de l'objet présent | 1 | **1** ✅ (piège `0 ≠ pas de PR` évité) |
| h1 | `checks[].context` divergent de `contexts` | 1 | **1** ✅ recoupement `_contexts_inconsistency` |
| — | `lock_branch` / `block_creations` actifs (fixtures livrées) | 2 | **2** ✅ **le cas exact de B-2** |

Extrait du cas B-2 rejoué :

```
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non
   couvert(s) par le mapping PUT → GET d'US-00.4 : lock_branch = {"enabled": true}. Ces champs peuvent
   modifier l'enforcement réel de la branche […] : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
EXIT=2                      ← avant correctif : EXIT=0 « conforme »
```

**Règle de dominance vérifiée** dans le module (`check_branch_protection.py:818-839`) : les écarts
déjà détectés sont imprimés sous `[ÉCARTS DÉJÀ DÉTECTÉS, liste NON exhaustive]`, **puis** l'issue est
exit 2. `uncovered_active` **domine** bien `diffs`.

### 4.2 Valeurs limites classées NEUTRES — conforme à la doctrine écrite, et **nommées**

| # | Valeur | Classement | Exit |
|---|---|---|---|
| a4 | `""` | NEUTRE (conteneur vide) | 0 |
| a5 | `[]` | NEUTRE | 0 |
| a6 | `{}` | NEUTRE | 0 |
| a7 | `null` | NEUTRE | 0 |

Ces 4 cas sont **exactement** ce que le module documente (`:108-113`) et ils sont **nommés** en
`[IGNORÉ — NEUTRE]` dans la sortie — **jamais silencieux**. Le `[IGNORÉ — NEUTRE]` récursif est donc
**correct** : c'est le comportement voulu, et il empêche l'outil de rougir en permanence sur une API
**additive** (choix de conception argumenté, et je le partage).

### 4.3 🟠 Les 5 trous résiduels que j'ai démontrés — **tous hors des formes que l'API émet**

| # | Attaque | Exit | Nommé ? | Pourquoi ce n'est **pas** bloquant |
|---|---|---|---|---|
| b1 | `_lock_branch: {"enabled": true}` | **0** | **non** | **NB-3** — préfixe `_` inerte. L'API GitHub n'émet **aucune** clé `_*` (hypothèse vérifiée sur les réponses réelles de ce dépôt) : inatteignable sur une réponse réelle |
| b2 | `_bypass_everything: ["gitgdx"]` | **0** | **non** | idem |
| c1 | `lock_branch: {"enabled": false, "bypass_actors":[{…}]}` | **0** | **oui** (parent NEUTRE) | **NB-5** — `_is_neutral` s'arrête à `.enabled`. Forme non émise par l'API ; et `enabled: false` = fonction désactivée |
| e1 | `enforce_admins: {"enabled": true, "bypass_actors":[{…}]}` | **0** | **non** | **NB-2** — `_guard_actual` ne descend pas dans les 5 wrappers booléens mappés. L'API n'y émet que `url` + `enabled` |
| e2 | `allow_force_pushes: {"enabled": false, "for_everyone": true}` | **0** | **non** | idem |
| g1 | `required_status_checks.checks: {"bypass": true}` (dict, pas liste) | **0** | **non** | **NB-4** — `checks` inerte, et `_contexts_inconsistency` abandonne si ce n'est pas une liste. L'API émet toujours une liste |
| g2 | `protection: {"enabled": false, "lock": true}` | **0** | **non** | **NB-4** — `protection`, `name`, `protection_url` sont des clés de la réponse **`…/branches/{b}`**, jamais de `…/protection` : liste inerte **trop large** pour l'objet réellement classé |
| g3/g4 | `name`, `url` détournés | **0** | **non** | idem |

**Analyse** : chacun de ces contournements exige une **forme de réponse que l'endpoint de protection
de branche de GitHub ne produit pas**. La frontière retenue — classer par la **sémantique de la
valeur** plutôt que par la connaissance du **nom** — est le bon arbitrage, et il est **documenté avec
sa justification** (`:115-121`). Le durcissement souhaitable est **cheap** (§7 S-2, S-3) mais ne
change pas le verdict.

**Sur l'hypothèse `_*`** : elle tient pour l'API. Elle ne tient **pas** pour une **fixture**, et je
l'ai démontré (b1, b2) : une fixture portant une clé active sous `_` sort en **exit 0 sans même la
nommer**. Conséquence bornée : cet exit 0 porte `[SIMULATION] ` sur 100 % de ses lignes et le message
« n'atteste PAS l'état réel du dépôt » — il ne peut pas devenir une preuve d'état réel. C'est
pourquoi je classe NB-3 non bloquant, **tout en recommandant** de restreindre l'inertie `_` au mode
fixture **et** de nommer les clés `_` ignorées.

### 4.4 🟠 NB-1 — le trou de symétrie que j'ai trouvé, et sa condition d'atteignabilité

`[scripts/check_branch_protection.py:86-93 + 503 + 651-652]` | `MAPPED_TOP_KEYS` est une **constante
statique**, pas un ensemble **dérivé de `expected`**. Conséquence : une clé présente dans la réponse
réelle **et** dans `MAPPED_TOP_KEYS` **mais absente de la cible générée** est **ni comparée** (`if
key not in expected: continue`, l.652) **ni classée** (`if key in mapped: continue`, l.485) → **trou
silencieux**. | **Démonstration par exécution** (cible amputée dans une **copie hors du dépôt**,
aucun fichier du dépôt modifié) :

```
$ (copie de scripts/ + factory.config.json dans le scratchpad ; emit_branch_protection privée
   de la ligne `"allow_force_pushes": bp.get(...)`)
$ python <scratch>/clone/scripts/factory_sync.py --emit-branch-protection | (clés)
['allow_deletions','enforce_admins','required_conversation_resolution','required_linear_history',
 'required_pull_request_reviews','required_status_checks','restrictions']      ← allow_force_pushes ABSENT

$ python <scratch>/clone/scripts/check_branch_protection.py \
    --from-protection <scratch>/atk/x1_force_push_autorise.json   (allow_force_pushes: {"enabled": true})
    --from-branch tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   [IGNORÉ — NEUTRE] … allow_fork_syncing, block_creations, lock_branch, …
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
EXIT=0            ← FAUX VERT sur un RELÂCHEMENT RÉEL (force-push AUTORISÉ), clé jamais nommée

$ (contrôle) même fixture, comparateur du DÉPÔT (cible complète) :
[SIMULATION]   allow_force_pushes (GET: allow_force_pushes.enabled) | false | true
EXIT=1            ← correctement détecté
```

**Pourquoi ce n'est pas bloquant** : `emit_branch_protection()`
(`scripts/factory_sync.py:60-77`) construit le payload avec les **8 clés en dur** (`bp.get(clé,
défaut)`) — **aucune valeur de `factory.config.json` ne peut retirer une clé de la cible**. Atteindre
ce trou exige donc d'éditer **`scripts/factory_sync.py`**, fichier **Art. 6** protégé par
`.claude/hooks/protect_files.sh` : hors de portée d'un agent, et une telle édition humaine serait
elle-même l'anomalie. Contrairement à B-2, qui était atteignable **sans aucune modification du
dépôt**, celui-ci ne l'est pas. | **Solution (1 ligne)** : dériver l'ensemble de classement de la
cible — `_classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")` — pour qu'une clé mappée mais
absente de la cible retombe dans la classification par valeur.

---

## 5. 🔬 B-1 — mon balayage indépendant, toutes extensions, avec **mes** motifs

### 5.1 L'over-claim a-t-il réellement disparu ?

```
$ grep -rniE "derni[eè]re affirmation fausse|sur tout le d[eé]p[oô]t|0 occurrence non justifi" --exclude-dir=.git .
./reports/US-00.4/false_claims_sweep.md:14   « concluait « 0 occurrence non justifiée subsistante » » ← AUTO-CITATION de la
./reports/US-00.4/false_claims_sweep.md:154  « La version précédente concluait « 0 occurrence … » »      revendication RETIRÉE
./docs/trace/US-00.4/events.jsonl:10         EVT_CODE_REVIEW_FAILED du cycle 1 (trace historique, immuable)
```

**Les deux affirmations falsifiables ont disparu du corpus.** Il ne subsiste que leurs
**auto-citations au passé** dans le paragraphe qui les rétracte, et la trace du cycle 1 — ce qui est
exactement ce qu'on attend. `false_claims_sweep.md:140` s'intitule désormais
« **Verdict — l'exhaustivité n'est PAS revendiquée** » et §154-168 énonce sans enjoliver les **trois
angles morts cumulés** (liste de fichiers → motifs sur `*.md` → liste de motifs), en concluant :
« *aucune de ces méthodes ne garantit l'exhaustivité, et ce rapport ne la revendique plus […] La
seule garantie serait une relecture intégrale du corpus, qui n'a pas été faite.* »

### 5.2 `ci.yml` (C12) — corrigé, et sans régresser le gate `governance`

```
$ git diff main...HEAD -- .github/workflows/ci.yml
-# Gates qualité bloquants sur CHAQUE PR (et sur la branche principale).
-# Ces jobs sont les status checks requis par la protection de branche
+# Gates qualité exécutés et RAPPORTÉS sur CHAQUE PR (et sur la branche principale).
+# ⚠️ RAPPORTÉS, PAS BLOQUANTS — constat daté du 2026-07-26 : aucun de ces jobs n'est un status
+#    check REQUIS, parce que `main` n'est PAS protégée et ne peut pas l'être sur ce plan […]
+#    Conséquence à assumer : une PR peut être fusionnée AVEC LA CI ROUGE. […]
$ python scripts/factory_sync.py --check → EXIT=0   ← les 4 libellés de jobs résolvent toujours
```

**Aucune ligne de logique du workflow n'est touchée** (le diff ne porte que sur l'en-tête de
commentaires + la mise en forme). Critère #26 **satisfait**.

### 5.3 Les 3 non-corrections délibérées — vérifiées comme telles

```
$ sed -n '20p' CLAUDE.md
   fichier `.env` ou d'enforcement. *Enforced : hooks Claude Code + hooks git + protection de branche.*
$ git diff main...HEAD -- CLAUDE.md | grep "Enforced : hooks"   → (ligne 20 NON touchée)
$ sed -n '49p' docs/governance/CONSTITUTION.md
**Enforcement** : CI `ci.yml` jobs qualité, requis par la protection de branche
$ grep -n … docs/stories/US-00.1-secrets-scan-depot.md
198: … → merge empêché par la protection de branche.
215: | Job `secrets-scan` rouge + merge bloqué par la protection de branche | Haute |
$ grep -nE "^- \[[ x]\] \*\*T22 " docs/stories/US-00.4-…md
950:- [ ] **T22 — [action humaine]** — Éditer scripts/githooks/pre-push (Art. 6 …)   ← NON cochée
$ sed -n '2,3p' scripts/githooks/pre-push   (fichier Art. 6 — NON édité par l'agent : correct)
# Refuse le push direct vers la branche principale. Le merge passe par une PR
# (protection de branche GitHub : scripts/apply_branch_protection.sh).
```

Les 4 emplacements sont **déclarés avec leur porteur** (`false_claims_sweep.md` S1, S2, S10, S11 ;
`enforcement_gap.md` §transmission). **Ce sont des décisions, pas des oublis** — et le respect
d'Art. 6 sur `pre-push` est **exactement** le comportement attendu d'un agent.

### 5.4 🟠 NB-9 — 1 occurrence **résiduelle non déclarée** trouvée par mes motifs

```
$ grep -rniE "(fusion|merge|push).{0,40}(empêch|bloqu|interdit|refus).{0,40}(protection|branch protection)|\
est protégée|checks? .{0,15}(requis|obligatoire)|protégée par" . --include="*" \
  --exclude-dir=.git --exclude-dir=build --exclude-dir=__pycache__ --exclude=settings.local.json
…
./tests/features/US-00.1-secrets-scan-depot.feature:54:
    Et la fusion vers la branche principale est empêchée par la protection de branche
```

`[tests/features/US-00.1-secrets-scan-depot.feature:54]` | **Même famille que S11, même US certifiée,
fichier différent — non listé** ni dans `false_claims_sweep.md`, ni dans la transmission US-00.5. Les
motifs du balayage `4 bis` ne le capturent pas (« *la fusion … est empêchée* » ≠ « *merge empêché* »
et ≠ « *est protégée* »). | **Pourquoi ce n'est pas bloquant** : le rapport ne revendique **plus**
l'exhaustivité et **prédit explicitement** ce type de résiduel (« *un balayage par motif n'est
exactement aussi complet que sa liste de motifs* ») ; ce que le rapport garantit — « tout ce qui a
été trouvé est soit corrigé, soit signalé avec son porteur » — **reste vrai** : cette ligne n'avait
pas été trouvée, elle n'a donc pas été dissimulée. **Aucune affirmation n'est falsifiée.** |
**Solution** : ajouter cette ligne à la transmission **US-00.5** aux côtés de S11 (même fichier
d'US certifiée, même décision de non-édition).

### 5.5 Deux occurrences **limites** que je signale sans les compter comme fausses affirmations

| Emplacement | Texte | Mon appréciation |
|---|---|---|
| `docs/epics/EPIC_01-module-echeances.md:4` | « **Dépendances amont :** EPIC_00 — Fondations : socle qualité, CI, **protection de branche**, stack Flutter. » | **Périmé** après le re-cadrage : EPIC_00 ne livre pas de protection de branche. Inventaire de dépendances, pas une assertion d'état → **NB-11**, à traiter par @PO/@Architect avec US-00.5 |
| `.github/workflows/e2e.yml:6-7` | « **Non requis** par la protection de branche (nightly / manuel uniquement) : son échec n'empêche pas de merger une PR. » | **Littéralement vrai** (rien n'est requis) mais **présuppose** l'existence d'une protection qui rendrait d'autres jobs requis. Formulation à réaligner un jour ; **je ne la compte pas** comme fausse affirmation |

---

## 6. Non-régression, périmètre, Art. 6

| Contrôle | Commande | Résultat |
|---|---|---|
| `origin/main` intacte | `git ls-remote origin refs/heads/main` | `801a046e7c2f833a…` = **inchangée** ✅ (revérifiée **après** mes sondes hostiles) |
| Branche non poussée | `git ls-remote --heads origin` | seuls `main` et `feat/US-01.1-…` ✅ **aucun run CI** |
| **Aucun test négatif exécuté** (T16→T19) | états de cases + historique | `- [ ]` × 4, **toutes décochées** ✅ ; aucune commande de push/force/delete dans les livrables (les 2 seules occurrences de `git push` sont des **interdictions** : `enforcement_gap.md:112`, `non_regression.md:202`) |
| Historique non réécrit (AC-8) | `git log --first-parent --oneline origin/main` | **10 entrées = 8 fusions de PR** (#1,#3,#4,#5,#6,#7,#8,#9) **+ exactement 2 commits directs** (`6483022`, `0a2e5ab`) ✅ **décompte du Story File confirmé en propre** |
| **Art. 6** | `git diff main...HEAD --name-only` ∩ liste de `protect_files.sh` | **uniquement `factory.config.json` + `scripts/factory_sync.py`** — les 2 déclarés **[action humaine]** ✅. `scripts/githooks/*`, `.claude/hooks/*`, `.claude/settings.json`, `.gitleaks.toml`, `install_hooks.sh`, `factory_env.sh`, `run_gates.py` : **intacts** |
| Bloc généré `FACTORY_SYNC` **byte-identique** | extraction + `sha256` `main` vs `HEAD` | `main` : `len=362 sha256=9c7045ed…bd45` · `HEAD` : `len=362 sha256=9c7045ed…bd45` → **BLOC BYTE-IDENTIQUE : True** ✅ |
| Contrôle négatif « hors CI » (AC-2 limite) | `grep -rn "check-remote" .github/workflows/` | `grep_exit=1` → **aucun résultat** ✅ |
| Aucun jeton archivé | `grep -rnE "gh[pousr]_…|github_pat_…|Authorization: (Bearer\|token) …" reports/US-00.4 tests/fixtures/US-00.4` | `grep_exit=1` → **aucun résultat** ✅ |
| `apply_branch_protection.sh` — logique `PUT` | `git diff` | **inchangée** ✅ ; seuls l'en-tête (`NON APPLICABLE / CONDITIONNÉ AU DÉBLOCAGE`) et l'`echo` final (« Requête PUT acceptée » ≠ « Protections appliquées ») |
| Arbre de travail | `git status --porcelain` | **propre** ✅ (mes fixtures sont **hors du dépôt**, dans le scratchpad) |

### 6.1 La garantie d'**import paresseux** tient-elle si le module est cassé ou absent ?

Testé **sans toucher au dépôt**, via un bloqueur `sys.meta_path` posé par un `sitecustomize.py`
**dans le scratchpad** (le `PYTHONPATH` seul ne suffit pas : `sys.path[0]` = `scripts/` masquerait le
shim) :

```
$ PYTHONPATH=<scratch>/shim python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (…)
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : …
EXIT_CHECK=0            ← ✅ LA GARANTIE TIENT : le gate CI bloquant `governance` est intact

$ PYTHONPATH=<scratch>/shim python scripts/factory_sync.py --check-remote
    import check_branch_protection
ImportError: SIMULATION AUDIT : module casse/absent
EXIT_CHECK_REMOTE=1     ← ⚠️ NB-6 : 1 = « dérive » au lieu de 2 = « vérification impossible »

$ PYTHONPATH=<scratch>/shim python scripts/factory_sync.py --print-main-branch → main, EXIT=0
```

**La garantie demandée est vérifiée** : une défaillance du nouveau module **ne peut pas** casser
`--check`. Le pattern imposé par le Story File est donc respecté à la lettre. La réserve NB-6 porte
sur la sémantique du code de sortie de `--check-remote` dans ce cas, pas sur la garantie.

---

## 7. Arbitrage demandé — comparateur non protégé et non couvert par un test automatisé

**Écart déclaré par @Developer** : `scripts/check_branch_protection.py` porte désormais la frontière
de couverture, n'est **pas** couvert par `.claude/hooks/protect_files.sh`, et **aucun test
automatisé** ne l'exerce (les 12 chemins passent par des fixtures versionnées **lancées à la main**).

### Ma décision : **acceptable en l'état — NON bloquant.** Motivé, pas par déférence.

1. **Mon critère bloquant « code nouveau sans test » n'est pas déclenché.** Le code n'est pas non
   testé : **12 chemins d'exécution** sont couverts par **8 fixtures versionnées**, archivés avec
   code attendu / code obtenu (`check_remote_simulated.txt`, 8/8 concordants), **et je les ai
   intégralement rejoués**, plus **26 fixtures adverses de mon cru**. Ce qui manque est le
   **harnais**, pas les **vecteurs**. Or **aucun harnais `pytest` n'existe dans cette factory** —
   c'est un arbitrage @Architect tracé, assumé par le Story File (R6, dette #9), pas une omission de
   cette US.
2. **Le sens de l'affaiblissement compte.** Les deux gestes cités par @Developer sont **bruyants** :
   *retirer* une clé de `INERT_GET_KEYS` fait sortir l'outil en **exit 2** dès la première réponse
   réelle (rouge permanent, immédiatement visible) ; *inverser* `_is_neutral` fait exit 2 sur chaque
   clé additive neutre (idem). Le geste **silencieux et dangereux** est l'inverse : **ajouter** des
   noms à `INERT_GET_KEYS` ou rendre `_is_neutral` plus permissif. C'est précisément ce qu'un
   selftest attraperait — et **pas** ce que le hook `protect_files.sh` attraperait (le hook n'arrête
   qu'un **agent**, pas une **régression**).
3. **Le risque n'est pas actuel, et il est déclaré avec un porteur.** L'exit 0 est **inatteignable**
   sur ce dépôt (403 sur les deux mécanismes) : le trou ne se matérialise **qu'au déblocage**. Il est
   consigné en R6, en dette #5 de `docs/GIT_PROTECTION.md:280`, et dans les dettes de
   `enforcement_gap.md`.
4. **Fermer la moitié « hook » est hors périmètre par la règle même que l'US respecte** : ajouter le
   fichier à `.claude/hooks/protect_files.sh` est une édition **Art. 6** → action humaine. Bloquer
   l'US sur une action que l'agent n'a pas le droit d'exécuter serait incohérent.

### Recommandation (non bloquante, à porter par une US de suivi)

- **Prioritaire** : `scripts/selftest_check_branch_protection.py` rejouant les **12 chemins** et
  **assertant les codes de sortie**, appelé depuis le job CI `governance`. C'est la barrière qui
  protège réellement la frontière de couverture — sans nouvelle dépendance, sans `pytest`.
  Y ajouter mes cas NB-1 → NB-5 comme non-régressions.
- **Complémentaire** : ajouter `scripts/check_branch_protection.py` (et
  `scripts/apply_branch_protection.sh`, et `.github/workflows/*`) à `protect_files.sh` — **action
  humaine**. Utile, mais **insuffisant seul** : le hook n'empêche pas une régression humaine.

---

## 8. Couverture des 8 AC

| AC | Couvert ? | Preuve (§ de ce rapport) |
|---|---|---|
| **AC-1** constat daté, 4 faits, cause racine, preuves brutes | ✅ | §2 — les 4 faits **re-vérifiés en propre** ; 403 ≠ 401 ≠ 404 distingués dans le code (`:852-921`) et dans les livrables ; **inférence du fait (b) déclarée comme telle** dans 3 artefacts (§2.1) → l'AC **ne tombe pas** sur sa propre règle de preuve ; aucun jeton archivé (§6) |
| **AC-2** `--check` DOCUMENTAIRE, reste vert et bloquant | ✅ | §1.3 (exit 0, mot « DOCUMENTAIRE », avertissement, renvoi) ; contrôle négatif « hors CI » §6 ; garantie d'import paresseux **vérifiée** §6.1 |
| **AC-3** 3 issues honnêtes, lecture seule, exit 0 **uniquement** si strictement conforme | ✅ | §3.1-3.2 (lecture seule prouvée, injection sondée), §3.4 (exit 2 réel), §4 (**B-2 fermé** : 13 attaques correctement en exit 1/2, aucun exit 0 atteignable sur une forme réelle de l'API) |
| **AC-4** cible armée, applicable en 1 commande, **NON active** | ✅ | payload généré (`required_approving_review_count: 0` **présent**, `enforce_admins: true`, 4 contextes, `restrictions: null`) ; `apply_branch_protection.sh` en-tête **NON APPLICABLE** et logique `PUT` intacte (§6) ; nulle part présentée comme active (§5) |
| **AC-5** deux voies de déblocage + conséquences | ✅ | `docs/GIT_PROTECTION.md` : irréversibilité de l'exposition **nommée**, coût **nommé**, « ajouter un collaborateur ne débloque rien » **nommé** |
| **AC-6** point de contrôle périodique | ✅ | `.claude/commands/audit-methodo.md` : `--check-remote`, **code de sortie consigné**, sémantique des 3 issues (exit 2 = dette **ouverte**, jamais un succès), condition de déblocage, condition de retour à `1` (`collaborators` ≥ 2) |
| **AC-7** filet de discipline sans survente | ✅ | 3 éléments + limites nommées ; **le défaut du cycle 1 est traité** : le commentaire de `pre-push` est désormais **déclaré** (S10) avec son diff exact en **T22 [action humaine]**, non édité car **Art. 6** — c'est le traitement correct, pas un contournement ; **aucun test négatif exécuté** (§6) |
| **AC-8** portée bornée, transmission US-00.5 | ✅ | §6 (10 entrées = 8+2, historique non réécrit, certifications antérieures intactes) ; **over-claim retiré** (§5.1) ; transmission S1/S2/S11 nommée avec porteur. Réserve **NB-9** : 1 emplacement résiduel à joindre à la transmission — ne falsifie aucune affirmation |

---

## 9. 🟠 Findings NON BLOQUANTS

| # | Emplacement | Problème | Solution |
|---|---|---|---|
| **NB-1** | `scripts/check_branch_protection.py:86-93, 485, 651-652` | `MAPPED_TOP_KEYS` **statique** au lieu d'être dérivé de `expected` : une clé mappée **absente de la cible** mais présente dans la réponse n'est **ni comparée ni classée** → **exit 0 démontré sur un relâchement réel** (force-push autorisé, §4.4). **Atteignable seulement en éditant `scripts/factory_sync.py` (Art. 6)** — `emit_branch_protection()` code les 8 clés en dur | `_classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")` |
| **NB-2** | `scripts/check_branch_protection.py:495-513` | `_guard_actual` ne descend **que** dans `required_status_checks` et `required_pull_request_reviews` : une clé active dans un **wrapper booléen mappé** (`enforce_admins`, `allow_force_pushes`, …) sort en **exit 0 silencieusement** (e1, e2). Forme non émise par l'API | étendre la descente aux 5 `BOOL_KEYS` avec `{"enabled"}` comme ensemble mappé |
| **NB-3** | `scripts/check_branch_protection.py:132-135, 440-442` | l'inertie du préfixe `_` s'applique **aussi aux réponses réelles**, et **sans nommer** la clé : une **fixture** portant `_lock_branch: {"enabled": true}` sort **exit 0** en silence (b1, b2). L'hypothèse « l'API n'émet jamais de clé `_*` » tient pour l'API, **pas** pour une fixture | restreindre l'inertie `_` au **mode fixture** et **nommer** les clés `_` ignorées |
| **NB-4** | `scripts/check_branch_protection.py:122-131` | `INERT_GET_KEYS` **trop large** pour l'objet réellement classé : `name`, `protection`, `protection_url` appartiennent à la réponse `…/branches/{b}`, **jamais** classée ; et `checks` non-liste échappe à `_contexts_inconsistency` (g1→g4 → exit 0 silencieux) | séparer les listes inertes par endpoint ; traiter `checks` non-liste comme **actif** |
| **NB-5** | `scripts/check_branch_protection.py:456-458` | `_is_neutral` s'arrête à `.enabled` : `{"enabled": false, "bypass_actors": [...]}` est **NEUTRE** (parent nommé, frère actif non inspecté) | inspecter aussi les frères de `enabled` |
| **NB-6** | `scripts/factory_sync.py:207-213` | `--check-remote` avec module cassé/absent → ``ImportError`` non capturée → **exit 1** (= « **dérive détectée** », assertion sur un état jamais lu) + traceback. **La garantie d'import paresseux tient pour `--check`** (§6.1) | `try: … except Exception: print(MSG_IMPOSSIBLE…); return 2`. ⚠️ **Art. 6 → nouveau diff humain** |
| **NB-7** | `scripts/check_branch_protection.py:931, 956` | `--from-protection-status 0` est **falsy** : (a) `Reporter(bool(0))` → **3 lignes sans `[SIMULATION] `** (§3.3) ; (b) `opts.from_protection_status or 200` transforme `0` en **200** | `is not None` dans les deux endroits |
| **NB-8** | `reports/US-00.4/check_remote_simulated.txt:44, 71, 91, 103, 137, 163, 189, 213` | les lignes d'encadrement de l'archiviste (« `→ code de sortie OBTENU : 0 (attendu 0)` », titres `[n/8]`) **ne portent pas** `[SIMULATION] ` : 137 lignes préfixées sur 254. Extraites par grep, elles pourraient se lire comme un exit 0 réel. *Atténué* : le fichier ouvre sur « ⛔ CE FICHIER N'EST PAS UNE PREUVE DE L'ÉTAT RÉEL DU DÉPÔT ⛔ » et son nom diffère de l'archive réelle | préfixer aussi ces lignes, ou écrire « code de sortie **SIMULÉ** obtenu » |
| **NB-9** | `tests/features/US-00.1-secrets-scan-depot.feature:54` | fausse affirmation **résiduelle non déclarée** (« la fusion … est empêchée par la protection de branche »), même famille et même US certifiée que S11. **Ne falsifie aucune affirmation** du rapport, qui ne revendique plus l'exhaustivité (§5.4) | joindre à la transmission **US-00.5** aux côtés de S11 |
| **NB-10** | `factory.config.json:63` | ligne blanche à **2 espaces** committée dans un fichier **Art. 6** (T6 **non cochée**). Sans impact : JSON valide, `--check` vert | nettoyage par l'humain, comme prévu en T6 |
| **NB-11** | `docs/epics/EPIC_01-module-echeances.md:4` | « Dépendances amont : EPIC_00 … **protection de branche** … » — **périmé** après le re-cadrage (EPIC_00 ne la livre pas) | @PO / @Architect, à rattacher à US-00.5 |

---

## 10. 🔵 Suggestions d'amélioration

| # | Emplacement | Suggestion |
|---|---|---|
| S-1 | `scripts/` | **La plus utile** : `selftest_check_branch_protection.py` rejouant les 12 chemins + les cas NB-1→NB-5, assertant les codes de sortie, câblé au job CI `governance` (§7) |
| S-2 | `check_branch_protection.py:789-921` | `_attribute()` concentre 6 branches d'attribution sur ~130 lignes ; une table `{status: handler}` améliorerait la testabilité. Complexité **acceptable** et linéaire aujourd'hui |
| S-3 | `check_branch_protection.py:469-473` | `_summarize` tronque à 120 caractères : une clé active très verbeuse serait nommée de façon partielle. Sans conséquence sur l'issue (exit 2), mais à connaître au diagnostic |
| S-4 | `check_branch_protection.py:136-137` | `NEUTRAL_MAX_DEPTH = 3` est **fail-safe** (au-delà → actif → exit 2) : ajouter un commentaire disant que **c'est voulu**, pour éviter qu'un futur contributeur ne « corrige » ce qu'il prendrait pour un bug |
| S-5 | `reports/US-00.4/*.json` | extension `.json` pour des fichiers non parsables (en-tête en `#`) : préférer `.txt`/`.raw`, ou un `.json` strict + un `.meta.txt` |
| S-6 | `check_branch_protection.py` (docstring `:18-22`) | le docstring garantit « aucune méthode d'écriture » : y ajouter le renvoi au **selftest** quand il existera, pour que la garantie soit **exécutable** et pas seulement déclarée |

---

## 11. Note de méthode — un blocage de hook rencontré pendant l'audit

Une de mes commandes de sonde a été **refusée par la factory elle-même** :

```
$ python scripts/check_branch_protection.py --repo 'a/$(git push --force origin main)'
PreToolUse:Bash hook error: [bash .claude/hooks/block_dangerous_bash.sh]:
BLOQUÉ par la factory : force-push interdit.
```

Le hook a bloqué la commande sur le **littéral** de la chaîne, alors qu'elle n'était qu'une **charge
d'injection inerte** destinée à être passée à `--repo`. J'ai **reformulé la sonde** (`a/$(touch
/tmp/PWNED)`, §3.2) — **sans jamais contourner le hook** (aucun `--no-verify`, aucune
dé-configuration de `core.hooksPath`, aucune édition de `.claude/hooks/*`).

**Ce blocage est un constat d'audit en soi**, et il éclaire l'AC-7 : sur ce dépôt, l'enforcement
**réellement opposable** est celui des **hooks locaux** — il fonctionne, il a agi contre l'auditeur
lui-même, et il est en effet la seule barrière qui ait dit « non » pendant tout cet audit. La
plateforme, elle, n'a rien refusé : elle ne peut rien refuser. C'est exactement la thèse de l'US.

**Limites de méthode assumées** : (i) la branche n'étant pas poussée, **aucun run CI n'existe** :
les 4 checks rapportés verts et le gage `gitleaks` de CI restent **non levés** ; (ii) le repli
`urllib` n'a pas été exercé in vivo (`gh` présent) — relu statiquement (`method="GET"`, en-tête
`Authorization` **jamais** archivé) ; (iii) le chemin **404 réel** reste non observable (l'API rend
403) — validé sur fixture seulement (R3) ; (iv) une sonde d'injection a dû être reformulée à cause
d'un hook (ci-dessus) — le cas « littéral de commande destructive » n'a donc pas été sondé tel quel.

---

## 12. Conclusion

Le re-audit **confirme la fermeture des deux bloquants**, et il la confirme **par l'attaque**, pas
par la lecture des correctifs annoncés :

- **B-2** : la frontière de couverture à trois catégories est **juste**. Sur **26 fixtures d'attaque
  écrites hors du dépôt**, aucune ne parvient à **relâcher l'enforcement** tout en sortant en
  **exit 0**, dès lors qu'elle respecte une forme que l'API GitHub émet réellement. Le choix de
  classer par la **sémantique de la valeur** plutôt que par une liste blanche de noms est le bon
  arbitrage pour une API **additive**, et il est documenté avec sa justification. Les 5 trous
  résiduels que je démontre (NB-1 → NB-5) portent tous sur des formes **que l'API ne produit pas**,
  ou exigent l'édition d'un fichier **Art. 6**.
- **B-1** : l'over-claim a **disparu du corpus** et a été remplacé par un aveu de méthode explicite —
  « l'exhaustivité n'est PAS revendiquée », avec ses trois angles morts nommés. `ci.yml` est corrigé
  **sans** casser le gate `governance`. L'occurrence résiduelle que je trouve (NB-9) **ne falsifie
  plus rien** : elle illustre au contraire ce que le rapport annonce désormais.

Le reste tient : lecture seule **prouvée** (y compris contre injection par `--repo`), marquage
`[SIMULATION] ` **intègre sur 100 % des lignes de résultat**, `--raw-out` **refusé** en mode fixture,
garantie d'**import paresseux vérifiée** sur module cassé, bloc généré **byte-identique**,
`origin/main` **intacte à `801a046`**, **aucune** tâche reportée exécutée (T16→T19 décochées),
Art. 6 **respecté** (seuls les 2 fichiers déclarés [action humaine] sont touchés — et `pre-push`,
qu'un agent n'a pas le droit d'éditer, est **déclaré** avec son diff en T22 plutôt que corrigé en
fraude).

Sur l'arbitrage demandé : le comparateur non protégé et sans harnais automatisé est **acceptable en
l'état**, parce que ses vecteurs de test **existent, sont versionnés et concordent**, parce que les
affaiblissements redoutés sont **bruyants**, parce que le risque ne se matérialise **qu'au
déblocage**, et parce que la moitié « hook » de la parade est **hors du pouvoir d'un agent** par la
règle même que cette US respecte. Je recommande fermement le **selftest** en CI, sans en faire une
condition de ce cycle.

**Je prononce PASS.** Cette US juge la factory sur l'exactitude de ses affirmations : elle satisfait
désormais ce standard, y compris là où l'exactitude consistait à **retirer une garantie** qu'elle ne
pouvait pas tenir.

**Rappel de mon périmètre** : je n'ai modifié ni le code, ni le SCB, ni `PROJECT_LOG.md`, ni le Story
File, ni `reports/US-00.4/code_review.md`. Ce rapport et mon événement de trace sont mes seules
sorties. Mes 26 fixtures d'attaque et mon bloqueur d'import sont **hors du dépôt** (scratchpad) —
`git status` est **propre**. Aucune commande d'écriture n'a été émise sur `main`, sur le dépôt
distant ni sur la protection de branche : mes seuls appels réseau ont été des **`GET` d'API** et des
`git ls-remote`.
