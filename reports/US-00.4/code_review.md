# Audit Rev 🔍 — US-00.4 « Enforcement de la branche principale : constat, vérification honnête et cible armée »

**Agent** : @CodeReviewer · **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-26
**Contexte** : FRAIS (Constitution Art. 2 / règle 5 de `CLAUDE.md`) — je n'ai pas produit ce code et
n'ai pas accès à la session qui l'a produit. **Aucune affirmation des livrables n'a été prise pour
acquise** : chaque fait a été re-vérifié par outil, y compris les preuves déjà archivées.
**Branche auditée** : `feat/US-00.4-ci-protection-branche` (`da6d7d0`) · **Base** : `main` (`801a046`)

---

## ⛔ VERDICT : **FAILED**

| Sévérité | Nombre |
|---|---|
| 🔴 **Bloquants** | **2** |
| 🟠 Non bloquants (majeurs) | 5 |
| 🔵 Suggestions d'amélioration | 6 |

**Le verdict ne porte pas sur la qualité du travail**, qui est élevée : le livrable de code est
réellement en lecture seule, le mapping PUT → GET est correct, le marquage `[SIMULATION] ` est
intègre sur **toutes** les lignes, l'inférence de l'AC-1 fait (b) est écrite **explicitement comme
telle** (elle ne fraude pas), `origin/main` est intacte et aucun test négatif n'a été exécuté.

Il porte sur **deux points qui échouent au standard que l'US s'impose elle-même** :
1. la **prétention d'exhaustivité** de la relecture « aucune fausse affirmation » est **falsifiable
   par un grep avec les motifs déclarés par l'US** : il reste ≥ 4 fausses affirmations non déclarées,
   dont **2 dans des artefacts d'enforcement** (`ci.yml`, `pre-push`) — alors qu'un livrable écrit
   que S1/S2 sont « la **dernière** affirmation fausse restante du corpus de gouvernance » ;
2. le comparateur peut rendre **exit 0 « conforme »** sur une protection réelle **matériellement
   divergente** (clés réelles non mappées ignorées silencieusement) — un **faux vert**, contraire au
   pattern « Fail-explicit — jamais de faux vert » et à l'AC-3 nominal (« exit 0 **uniquement** si
   strictement conforme »). Démonstration reproductible fournie.

Les deux correctifs sont **peu coûteux** et ne remettent en cause ni le périmètre, ni l'architecture.

---

## 1. Gates statiques — sorties collées

### 1.1 Remarque de méthode sur `--gate lint` / `--gate typecheck`

Les gates nommés dans mon subagent n'existent pas dans cette factory : `factory.config.json` →
`adapter.components` ne contient que `app` (Flutter), et `docs/governance/STACK_PROFILE.md` précise
que « Dart n'a pas d'étape *typecheck* séparée, l'analyse couvre les deux ».

```
$ python scripts/run_gates.py --gate lint
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
```

**Conséquence** : **il n'existe aucun gate lint/typecheck Python dans ce dépôt**, alors que l'unique
livrable de code de cette US est un script Python de 818 lignes. Aucun linter Python n'est par
ailleurs installé sur la machine (`ruff`, `pyflakes`, `mypy`, `flake8` → tous absents). J'ai donc
substitué : gates `app` complets, compilation, contrôle du contrat de module, et **rejeu intégral**
des chemins d'exécution (§3). Cette absence est une dette de la factory, pas de l'US (elle est
d'ailleurs consignée en dette #9 par @Developer).

### 1.2 Gates de l'adapter — `run_gates.py --component app`

```
$ python scripts/run_gates.py --component app
… ✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

### 1.3 Substituts Python

```
$ python -m py_compile scripts/check_branch_protection.py scripts/factory_sync.py
py_compile OK (exit 0)

$ python -c "import check_branch_protection as m; print(callable(m.main_from_sync), m.main_from_sync.__annotations__)"
main_from_sync callable : True
main callable           : True
annotation retour       : {'return': <class 'int'>}
```
→ Le **contrat imposé** (`main_from_sync() -> int` + `main()` CLI) est respecté à l'identique : le
drapeau `--check-remote` du fichier d'enforcement ne cassera pas.

### 1.4 Gates de gouvernance (ceux du job CI `governance`)

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

⚠️ **La branche n'est pas poussée** (`git ls-remote --heads origin` → seulement `main` et
`feat/US-01.1-…`) : **aucun run CI n'existe pour ce code**. Les gates ci-dessus sont des exécutions
**locales** faites par moi. Le critère « 4 checks verts sur la PR » et le gage `gitleaks` réel
restent **non levés** (réserve @Developer confirmée, cf. §6).

---

## 2. Vérification indépendante du constat (AC-1) — je n'ai rien pris des preuves archivées

`gh` était absent du `PATH` de ma session ; j'ai employé le chemin absolu documenté.

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected}'
{"name":"main","protected":false}                                            exit=0

$ gh api repos/gitgdx/Concentration/branches/main/protection
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"…/branch-protection#get-branch-protection","status":"403"}   exit=1

$ gh api repos/gitgdx/Concentration/rulesets
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"…/rules#get-all-repository-rulesets","status":"403"}         exit=1

$ gh api repos/gitgdx/Concentration --jq '{private, visibility, owner_type: .owner.type, permissions}'
{"owner_type":"User","permissions":{"admin":true,"maintain":true,"pull":true,"push":true,"triage":true},
 "private":true,"visibility":"private"}                                      exit=0
```

**Les 4 faits de l'AC-1 sont confirmés en propre**, avec les messages **identiques** sur les deux
mécanismes et un jeton `admin: true` : la cause est bien **le plan**, ni les droits, ni la
configuration.

### AC-1 fait (b) — l'inférence est-elle écrite comme telle, ou frauduleusement présentée comme une lecture d'API ?

**Écrite comme telle — pas de fraude.** Trois emplacements le disent explicitement :

| Emplacement | Formulation |
|---|---|
| `reports/US-00.4/enforcement_gap.md:23` | « `check_runs.json` (HTTP 200) **+ inférence** — voir §1.1 » · statut : « **Mixte : lecture directe + INFÉRENCE** » |
| `reports/US-00.4/enforcement_gap.md:41-61` | §1.1 dédiée : « **Écart honnête, signalé et non masqué** … Ce n'est pas une lecture directe, et ce document ne la présente pas comme telle » |
| `reports/US-00.4/check_runs.json:14-16` (en-tête de la preuve elle-même) | « ⚠️ PORTÉE DE CETTE PREUVE — elle établit UNIQUEMENT que les 4 checks S'EXÉCUTENT … Elle NE dit RIEN de leur caractère requis ou bloquant » |
| `docs/GIT_PROTECTION.md:42-47` | « Le fait (b) n'est pas entièrement lisible dans une réponse brute — et c'est dit franchement … ne jamais le présenter comme telle » |

L'AC-1 ne tombe donc **pas** sur sa propre règle de preuve : la règle « réponses brutes datées de
l'API » est honorée pour (a), (c), (d) ; pour (b) la moitié inférée est **déclarée**, datée, et son
support (`"protected": false` + `"enforcement_level": "off"`) est lisible dans la réponse brute
archivée. C'est le traitement correct.

---

## 3. `scripts/check_branch_protection.py` — rejeu intégral par mes soins

### 3.1 Lecture seule — contrôlée, y compris au-delà du critère #11

```
$ grep -nE '\-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)' scripts/check_branch_protection.py
(aucun résultat — grep_exit=1)

$ grep -nE 'method\s*=|data\s*=|--method|-X ' scripts/check_branch_protection.py
312:        method="GET",

$ grep -nE '\bopen\(|write_text|write_bytes|mkdir|unlink|rmtree|os\.remove' scripts/check_branch_protection.py
514:    out_path.parent.mkdir(parents=True, exist_ok=True)
536:    out_path.write_text(…)          ← uniquement --raw-out

$ grep -nE 'subprocess\.(run|check_output|Popen|call)' scripts/check_branch_protection.py
195: factory_sync.py <flag>   ·  223: git remote get-url origin   ·  261: gh api <path>
```
**Aucun chemin d'écriture distante n'est atteignable** : `urllib` est explicitement `method="GET"`
sans `data=`, `gh api` est appelé sans drapeau de méthode, les 3 sous-processus sont en lecture. La
seule écriture disque est `--raw-out`, refusée en mode fixture (vérifié §3.3).

### 3.2 Mapping PUT → GET — correct et complet sur les clés de la cible

Payload généré (source unique) vérifié :
```
$ python scripts/factory_sync.py --emit-branch-protection
{"required_status_checks":{"strict":true,"contexts":["🔐 Secrets scan (gitleaks)",
 "📋 Governance (SCB + traçabilité + synchro)","check-branch-name","📱 App (gates run_gates.py)"]},
 "required_pull_request_reviews":{"required_approving_review_count":0},"enforce_admins":true,
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false,
 "required_linear_history":false,"required_conversation_resolution":true}
```

| Règle d'asymétrie | Implémentation | Vérdict |
|---|---|---|
| `enforce_admins` bool ↔ `.enabled` | `_unwrap_enabled()` (l.365-376) + garde `isinstance(act_val, bool)` (l.489) — évite le piège `1 == True` | ✅ correct |
| `restrictions: null` ↔ clé **absente** | l.494-502 : absence = OK, **présence = écart** | ✅ correct |
| `required_pull_request_reviews` **objet absent = écart**, pas un zéro | l.457-474 : objet absent **et** clé absente traités séparément, message « aucune pull request exigée » | ✅ correct — le piège majeur est évité |
| `contexts` ensembliste, *manquants* / *en trop* séparés | l.440-453, avec repli `checks[].context` (l.348-362) | ✅ correct |
| clé de la cible non mappée | `MappingGap` → **exit 2** (l.379-407), jamais ignorée | ✅ excellent |

### 3.3 Les 8 chemins d'exécution, rejoués (codes de sortie obtenus par moi)

| # | Invocation | Attendu | **Obtenu** |
|---|---|---|---|
| 1 | `--from-protection protection_conforme.json --from-branch branch_protected_true.json` | 0 | **0** ✅ |
| 2 | `--from-protection protection_divergente.json --from-branch branch_protected_true.json` | 1 | **1** ✅ (4 écarts, MANQUANT/EN TROP séparés) |
| 3 | `--from-protection http_404.json --from-branch branch_protected_false.json --from-protection-status 404` | 1 | **1** ✅ (7 écarts, « la branche n'est réellement PAS protégée ») |
| 4 | idem avec `branch_protected_true.json` | 2 | **2** ✅ (« protection ILLISIBLE : droits insuffisants ») |
| 5 | `--from-protection` seul | 2 usage | **2** ✅ |
| 6 | `--from-branch` seul | 2 usage | **2** ✅ |
| 7 | fixtures + `--raw-out` | 2 usage (refus R1) | **2** ✅ (« archiver une réponse SIMULÉE … la rendrait relisible comme une preuve d'état réel ») |
| 8 | `factory_sync.py --check-remote` (dépôt réel, `gh` présent) | 2 / 403 plan | **2** ✅ |

Sortie réelle du chemin 8, reproduite à l'identique de l'archive `check_remote_exit2.txt` :
```
Lecture SEULE de l'API GitHub (GET uniquement) — gitgdx/Concentration:main · GET repos/gitgdx/Concentration/branches/main → 200 · GET repos/gitgdx/Concentration/branches/main/protection → 403
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Code HTTP : 403 — protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut lire ni appliquer la protection en l'état. Message API : 'Upgrade to GitHub Pro or make this repository public to enable this feature.'
  Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
EXIT=2
```
Sans `gh` ni jeton, le même appel rend **2** avec la cause « `gh` introuvable … » — l'attribution
reste honnête (piège correctement documenté dans `audit-methodo.md` et `GIT_PROTECTION.md:188-195`).

### 3.4 Le piège de la simulation (R1) — marquage contrôlé ligne par ligne

**Aucune exception trouvée.** Sur les 4 invocations fixture, **100 %** des lignes émises par le
comparateur portent `[SIMULATION] `, y compris les lignes `[OK]`, les lignes d'écart, les messages
d'erreur d'usage et les lignes d'exit 2. Le mécanisme est structurel (`Reporter.line()` est le seul
émetteur, l.141-152) et le préfixe est **appliqué même à une invocation fixture incomplète**
(l.724-727 : « toute invocation portant un drapeau `--from-*` est une simulation, même incomplète »)
— point de conception excellent. Aucune ligne vide n'est émise, ce qui interdit une ligne non
préfixée. L'exit 0 lit bien `conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel
du dépôt`, et `--raw-out` est refusé en mode fixture.

**Un exit 0 archivé pourrait-il être relu comme une preuve d'état réel ?** Non pour la sortie de
l'outil. Réserve mineure sur le fichier d'archive : voir 🟠 NB-4.

---

## 4. 🔴 Findings BLOQUANTS

### 🔴 B-1 — La relecture « aucune fausse affirmation » se prétend exhaustive alors qu'elle ne l'est pas ; ≥ 4 occurrences non déclarées subsistent, dont 2 dans des artefacts d'enforcement

`[reports/US-00.4/enforcement_gap.md:161-163]` | Le rapport écrit : « Cette déclaration reste FAUSSE
après US-00.4. **C'est la dernière affirmation fausse restante du corpus de gouvernance** » (S1/S2),
et `§6 ter:213-215` revendique « un balayage par motif (`apply_branch_protection`, `[Ee]nforced`,
« protection de branche ») **sur tout le dépôt** ». **Les deux affirmations sont fausses** : mon
balayage indépendant, avec **les motifs déclarés par l'US elle-même**, remonte des occurrences non
listées ni comme corrigées, ni comme signalées. | **Solution** : (a) retirer ou borner la mention
« dernière affirmation fausse restante » ; (b) corriger `ci.yml` (agent autorisé : ni Art. 6, ni
`protect_files.sh` — cf. dette #5 du rapport lui-même) ; (c) **signaler** `pre-push` (Art. 6 → action
humaine) et le Story File d'US-00.1 (@PO) ; (d) ajouter ces emplacements à la transmission US-00.5.

Preuves brutes de mon balayage :

```
$ grep -rn --exclude-dir=.git "apply_branch_protection" .
./.github/workflows/ci.yml:5:# (scripts/apply_branch_protection.sh). Constitution : …
./scripts/githooks/pre-push:3:# (protection de branche GitHub : scripts/apply_branch_protection.sh).

$ sed -n '1,5p' .github/workflows/ci.yml
name: ✅ CI
# Gates qualité bloquants sur CHAQUE PR (et sur la branche principale).
# Ces jobs sont les status checks requis par la protection de branche
# (scripts/apply_branch_protection.sh). Constitution : docs/governance/CONSTITUTION.md.

$ sed -n '1,3p' scripts/githooks/pre-push
#!/bin/sh
# Refuse le push direct vers la branche principale. Le merge passe par une PR
# (protection de branche GitHub : scripts/apply_branch_protection.sh).

$ grep -rn -E "merge (empêché|bloqué) par la protection" .
./docs/stories/US-00.1-secrets-scan-depot.md:198: … → merge empêché par la protection de branche.
./docs/stories/US-00.1-secrets-scan-depot.md:215: … Job `secrets-scan` rouge + merge bloqué par la protection de branche | Haute |
```

| Emplacement | Problème | Gravité propre |
|---|---|---|
| `.github/workflows/ci.yml:3` | « Gates qualité **bloquants** sur CHAQUE PR » — **faux** : aucun n'est requis | 🔴 fichier lu par toute la squad, porteur des 4 contextes ; l'US a **examiné ce fichier** (elle vérifie que « les 4 libellés correspondent déjà aux `status_checks` ») et l'a déclaré « NON modifié » sans voir l'en-tête |
| `.github/workflows/ci.yml:4` | « Ces jobs **sont les status checks requis par la protection de branche** » — **faux**, famille exacte policée par l'AC-1 erreur | 🔴 |
| `scripts/githooks/pre-push:2-3` | « Le merge passe par une PR (**protection de branche GitHub** …) » — présente une protection de plateforme **inexistante** comme la raison du hook. C'est l'élément (a) du « filet de discipline » de l'AC-7, dont l'AC exige que les limites soient **nommées** : son propre commentaire dit le contraire | 🔴 fichier **Art. 6** → non éditable par un agent, donc **devait être signalé** ; il ne l'est pas |
| `docs/stories/US-00.1-secrets-scan-depot.md:198, :215` | « merge empêché / bloqué par la protection de branche » — critère de test d'une US **CERTIFIÉE**, techniquement impossible à satisfaire depuis l'origine | 🟠 hors périmètre d'édition, mais devait être **signalé** (T14 impose : « signalées à @PO/@Architect, jamais éditées ici ») |

**Pourquoi c'est bloquant** : l'US érige la relecture « aucune fausse affirmation » en garde-fou
central (DoD, AC-1 erreur, AC-4 erreur) et tire de son propre balayage la **leçon méthodologique**
que l'exhaustivité par liste de fichiers est illusoire (`enforcement_gap.md:205-209`). Elle applique
cette leçon… et manque des occurrences que ses motifs déclarés capturent en une commande. Le
livrable produit donc **la fausse confiance qu'il dénonce** : un lecteur de `enforcement_gap.md`
conclut que le corpus est propre hors S1/S2, ce qui est faux — et deux des occurrences restantes
sont dans les artefacts qui *portent* l'enforcement.

### 🔴 B-2 — `check_branch_protection.py` peut rendre **exit 0 « conforme »** sur une protection réelle matériellement divergente (faux vert)

`[scripts/check_branch_protection.py:379-407 + 410-504]` | `_guard_mapping()` protège **uniquement
le côté attendu** (clés de la cible). Aucune garde symétrique n'existe côté **réponse réelle** : une
clé présente dans le `GET …/protection` mais absente de la cible est **ignorée silencieusement**.
Une protection réelle portant `lock_branch: {"enabled": true}` (branche **entièrement verrouillée en
lecture seule**, plus aucune fusion possible) et `block_creations: {"enabled": true}` est déclarée
**« conforme à la cible générée »** avec **exit 0**. | **Solution** : appliquer au côté réel la même
règle que celle déjà appliquée au côté attendu — soit lever `MappingGap` → **exit 2** sur toute clé
de la réponse non couverte par le mapping (liste blanche des clés inertes : `url`, `contexts_url`,
`protection_url`, `required_signatures`…), soit à minima faire dire à l'exit 0 **quelles clés n'ont
pas été comparées**. Le message actuel (« conforme à la cible générée par `--emit-branch-protection` »)
est bien *portée-limitée*, mais l'AC-3 nominal exige « exit 0 **uniquement** si la protection est
**strictement conforme** ».

Démonstration reproductible (fixture dérivée écrite **hors du dépôt**, aucune écriture distante) :
```
$ python - <<'PY'   # copie de protection_conforme.json + lock_branch/block_creations = true
… fixture derivee ecrite hors du depot : %TEMP%\audit_lock_branch.json
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
EXIT = 0
PY
```
Les fixtures livrées portent d'ailleurs déjà ces clés (`lock_branch`, `block_creations`,
`allow_fork_syncing`, toutes à `false`) : le trou est donc **matérialisé dans le jeu de test** sans
être testé.

**Pourquoi c'est bloquant** : c'est le **seul chemin de faux vert** de tout le dispositif, dans le
seul livrable de code, et il contredit frontalement le pattern imposé « **Fail-explicit — jamais de
faux vert** » ainsi que la doctrine écrite dans le module lui-même (`MappingGap`, l.99-104 : « une
clé non comparée serait un trou silencieux dans la vérification — exactement le défaut que cette US
corrige »). Le risque n'est pas opérationnel **aujourd'hui** (exit 0 inatteignable, 403), mais il se
matérialise **le jour du déblocage**, c'est-à-dire précisément quand l'outil deviendra la seule
source de vérité — et l'US se définit comme un outillage destiné à survivre au déblocage.

---

## 5. 🟠 Findings NON BLOQUANTS (majeurs)

### 🟠 NB-1 — `false_claims_sweep.md` affirme que des fichiers n'ont pas été modifiés alors que le même commit les modifie

`[reports/US-00.4/false_claims_sweep.md:63-64, 70-73, 96-100]` | §3 est titrée « Occurrences
SIGNALÉES — hors de mon périmètre, **NON éditées** » et affirme « **Aucune de ces lignes n'a été
modifiée** » ; S3 porte « je ne l'édite pas » ; le verdict §5 conclut « il faut les y ajouter
explicitement, **sinon elles survivront** ». **Or le commit `da6d7d0` — celui qui livre ce rapport —
modifie `docs/SQUAD_GUIDE.md` (S3, S7), `docs/epics/EPIC_00-fondations.md` (S4, S8),
`STORY_CERTIFICATION_BOARD.md` (S5, S6) et `.claude/commands/sprint-status.md` (S9).** |
**Solution** : ajouter dans `false_claims_sweep.md` un renvoi explicite à
`enforcement_gap.md §6 bis/§6 ter` et un bandeau « §3 est l'état **au moment de la relecture T14** ;
S3→S6 ont été corrigées ensuite par @Architect ».

```
$ git show --stat --format="" da6d7d0 | grep -E "SQUAD_GUIDE|EPIC_00|STORY_CERT|sprint-status"
 .claude/commands/sprint-status.md   |   7 +-
 STORY_CERTIFICATION_BOARD.md        |  65 ++++--
 docs/SQUAD_GUIDE.md                 |  29 ++-
 docs/epics/EPIC_00-fondations.md    |  14 +-
```
*Atténuation retenue* : la réconciliation **existe** (`enforcement_gap.md:188-229` : S3→S6 corrigées
par @Architect, S7→S9 ajoutées, bilan 11+4+3, S1/S2 maintenues) et le message de commit la détaille.
Le défaut est donc l'absence de renvoi dans le fichier trompeur, pas un mensonge global — d'où le
classement non bloquant.

### 🟠 NB-2 — `--check-remote` rend **exit 1** (= « dérive ») si le module de vérification est cassé ou absent

`[scripts/factory_sync.py:207-213]` | La garantie d'import paresseux **tient parfaitement** pour
`--check` (gate CI bloquant), mais l'`ImportError` du dispatch n'est pas capturée : Python sort en
**code 1**, qui dans la sémantique de l'outil signifie « **DÉRIVE DÉTECTÉE — protection absente ou
divergente** », c'est-à-dire une assertion sur un état jamais lu. | **Solution** : envelopper
l'import (`try: … except Exception: print(MSG_IMPOSSIBLE…); return 2`). ⚠️ Fichier **Art. 6** → exige
un **nouveau diff humain**.

Test de la garantie, avec un module cassé simulé **sans toucher au dépôt** (bloqueur `sitecustomize`
sur `PYTHONPATH`, dans le scratchpad) :
```
$ PYTHONPATH=<scratch> python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (…)
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici …
EXIT_CHECK=0                    ← ✅ la garantie de l'import paresseux TIENT

$ PYTHONPATH=<scratch> python scripts/factory_sync.py --check-remote
  File "…/scripts/factory_sync.py", line 213, in main
    import check_branch_protection
ImportError: SIMULATION AUDIT : module casse/absent
EXIT_CHECK_REMOTE=1             ← ⚠️ 1 = « dérive » au lieu de 2 = « vérification impossible »
```

### 🟠 NB-3 — Le comparateur produit la preuve mais n'est protégé par rien, et **aucun test automatisé** ne le garde

`[scripts/check_branch_protection.py:1-818]` | Aucun harnais de test n'existe (dette #9 assumée) et
le fichier est absent de `.claude/hooks/protect_files.sh` (dette #4) : un agent peut transformer un
exit 2 en exit 0 sans qu'aucun gate ne s'en aperçoive. | **Solution** : ajouter le fichier au hook
(action humaine) et, à défaut de `pytest`, un script `scripts/selftest_check_branch_protection.py`
rejouant les 8 chemins et comparant les codes de sortie, appelable depuis le job `governance`.
*Je ne bloque pas sur « code nouveau sans test »* : les 8 chemins **sont** couverts par des vecteurs
de test versionnés (`tests/fixtures/US-00.4/`), archivés et **rejoués intégralement par moi** (§3.3),
et l'absence de harnais est un arbitrage @Architect tracé.

### 🟠 NB-4 — Dans `check_remote_simulated.txt`, les lignes d'encadrement ne portent pas le marquage

`[reports/US-00.4/check_remote_simulated.txt:38, 60, 82, 104]` | Les lignes ajoutées par
l'archiviste — « `→ code de sortie OBTENU : 0 (attendu 0)` » et les titres « [1/4] Fixture CONFORME
(200) » — ne sont **pas** préfixées `[SIMULATION] `. Extraites hors contexte par un grep
(« `code de sortie OBTENU : 0` »), elles pourraient se lire comme un exit 0 réel. | **Solution** :
préfixer aussi les lignes d'encadrement, ou les écrire « code de sortie **SIMULÉ** obtenu ».
*Atténuation* : le fichier ouvre sur « ⛔ CE FICHIER N'EST PAS UNE PREUVE DE L'ÉTAT RÉEL DU DÉPÔT ⛔ »
et le nom de fichier est distinct de l'archive réelle (mitigation R1 respectée).

### 🟠 NB-5 — `check_runs.json` contient **5** entrées pour « 4 checks », sans explication

`[reports/US-00.4/check_runs.json:24]` | Le corps porte `check-branch-name` **deux fois** (5 objets,
4 noms distincts) ; l'en-tête annonce « les 4 checks S'EXÉCUTENT » sans mentionner le doublon (dû au
double déclenchement `push` + `pull_request`). | **Solution** : une ligne d'en-tête expliquant le
doublon. Le fait prouvé (4 contextes distincts, tous `success`) reste exact — je l'ai relu
intégralement.

---

## 6. Évaluation des réserves déclarées par @Developer — honnêtes ou masquantes ?

| Réserve | Vérification indépendante | Verdict |
|---|---|---|
| `gitleaks` non installé localement | `which gitleaks` → absent. Mon grep indépendant (`ghp_`, `gho_`, `ghs_`, `github_pat_`, `Authorization:`, `Bearer …`) sur `reports/US-00.4/` **et** `tests/fixtures/US-00.4/` ne remonte **que les motifs regex documentés** dans `non_regression.md:125,139` — **aucun jeton réel** | ✅ **honnête et suffisante** ; le gage CI reste dû (branche non poussée) |
| Repli `urllib` non exercé in vivo | Code relu : `method="GET"`, en-tête `Authorization` **jamais** archivé (commande archivée : « Bearer <JETON NON ARCHIVÉ> », l.300-302). Non exécuté faute de jeton en session | ✅ honnête ; risque résiduel faible |
| Chemin 404 non observable | Confirmé : l'API rend 403, jamais 404. Validé sur fixture uniquement (chemins 3 et 4 ci-dessus) | ✅ honnête (R3 consigné) |
| Exits 0/1 sur fixtures uniquement | Confirmé et **rejoué**. Marquage `[SIMULATION] ` intègre | ✅ honnête |
| « 4 checks verts sur la PR » non levable | Confirmé : `git ls-remote --heads origin` → la branche **n'est pas poussée**, aucune PR, aucun run CI | ✅ honnête — **à lever par @DevOps/@QA** |
| `reports/US-00.4/*.json` non parsables en JSON | Confirmé (en-tête en lignes `#` + corps brut). Chaque fichier documente `grep -v '^#'` pour isoler le corps | ✅ honnête ; **suggestion S-5** ci-dessous |
| PGP + e-mail committer dans `branch_main_before.json` | Confirmé : bloc `-----BEGIN PGP SIGNATURE-----` (signature **publique** de vérification GitHub, **pas** une clé privée) + `guillaume.decroix@free.Fr` dans `commit.author.email` / `verification.payload`. Signalé volontairement dans l'en-tête plutôt que masqué, et **tronquer une preuve brute la disqualifierait** | ✅ honnête. ⚠️ **Point d'attention hors périmètre @CodeReviewer** : une **adresse e-mail personnelle** est archivée en clair dans un dépôt qui pourrait devenir **public** (voie de déblocage (a), déclarée **irréversible**). À arbitrer par @CyberSecurity / l'humain — je le signale, je ne le tranche pas |

**Aucune réserve ne masque un défaut.** Les deux findings bloquants que je remonte ne figurent dans
**aucune** réserve : ils n'avaient pas été vus.

---

## 7. Contrôles de périmètre et de non-régression

| Contrôle | Commande | Résultat |
|---|---|---|
| `origin/main` intacte | `git ls-remote origin refs/heads/main` | `801a046e7c2f…` = **inchangée** ✅ |
| Aucun push de la branche | `git ls-remote --heads origin` | seuls `main` et `feat/US-01.1-…` ✅ |
| Aucun test négatif exécuté (T16→T19) | historique de `main` + absence de tout `git push`/`--force`/`--delete` dans les livrables | ✅ **aucune** tâche reportée n'a été exécutée |
| Historique non réécrit | `git log --first-parent --oneline origin/main` | **10 entrées** : 8 fusions de PR (#1, #3, #4, #5, #6, #7, #8, #9) + `6483022`, `0a2e5ab` ✅ décompte du Story File **confirmé** |
| Art. 6 — fichiers d'enforcement | `git diff main...HEAD --name-only` filtré sur la liste de `protect_files.sh` | **uniquement** `factory.config.json` + `scripts/factory_sync.py` (les 2 déclarés **[action humaine]**) ✅ ; `scripts/githooks/*`, `.claude/hooks/*`, `.claude/settings.json`, `.gitleaks.toml`, `install_hooks.sh`, `factory_env.sh`, `run_gates.py` **intacts** |
| Bloc généré `FACTORY_SYNC` non édité à la main | extraction + comparaison `main` vs `HEAD` entre marqueurs | **BLOC IDENTIQUE : True** ✅ (et `--check` vert, qui le revalide contre la config) |
| Contrôle négatif « hors CI » | `grep -rn "check-remote" .github/workflows/` | **aucun résultat** ✅ |
| `apply_branch_protection.sh` — logique `PUT` | `git diff` | inchangée ; seuls en-tête et `echo` final modifiés ✅ ; « ✅ Protections appliquées » → « ✅ Requête PUT acceptée par la plateforme » (correction pertinente : seule la requête est constatable) |
| Payload directement consommable | `--emit-branch-protection` (§3.2) | 4 contextes exacts, `required_approving_review_count: 0` **présent**, `restrictions: null` ✅ AC-4 et sa limite (i) satisfaites |
| Fixtures : 4 libellés à l'octet près | exit 0 du chemin 1 (comparaison contre le payload **généré**) | ✅ prouvé par construction |

---

## 8. Couverture des 8 AC

| AC | Couvert ? | Preuve (§ de ce rapport) |
|---|---|---|
| **AC-1** constat daté + cause racine + 4 faits, preuves brutes | ✅ | §2 (re-vérifié en propre) ; inférence du fait (b) **déclarée comme telle** ; 403 ≠ 401 ≠ 404 distingués dans le code (l.648-716) et dans `enforcement_gap.md:27-39` |
| **AC-2** `--check` DOCUMENTAIRE, reste vert et bloquant | ✅ | §1.4 ; contrôle négatif « hors CI » §7 ; docstring et message de fin conformes au diff humain |
| **AC-3** 3 issues honnêtes, lecture seule | ⚠️ **partiel** | §3.1 (lecture seule ✅), §3.3 (les 3 issues ✅) — **mais** 🔴 **B-2** : exit 0 atteignable sur un état matériellement divergent |
| **AC-4** cible armée, applicable en 1 commande, **NON active** | ✅ | §7 ; `GIT_PROTECTION.md:100-137` (dont le bloc `sh` porté par « ⛔ NE PAS EXÉCUTER AUJOURD'HUI ») ; `apply_branch_protection.sh` en-tête NON APPLICABLE |
| **AC-5** deux voies de déblocage + conséquences | ✅ | `GIT_PROTECTION.md:77-96` : irréversibilité **nommée**, coût nommé, « ajouter un collaborateur ne débloque RIEN » **nommé** |
| **AC-6** point de contrôle périodique | ✅ | `.claude/commands/audit-methodo.md:15-60` : `--check-remote`, **code de sortie consigné**, sémantique des 3 issues (exit 2 = dette OUVERTE, jamais un succès), condition de déblocage, condition de retour à `1` (`collaborators` ≥ 2) |
| **AC-7** filet de discipline sans survente | ⚠️ **partiel** | `GIT_PROTECTION.md:58-73` : 3 éléments + limites nommées ✅ — **mais** 🔴 **B-1** : le commentaire du hook `pre-push` lui-même présente une protection de plateforme inexistante |
| **AC-8** portée bornée + transmission US-00.5 | ⚠️ **partiel** | §7 (historique, 8+2, certifications) ✅ ; transmission T15 rédigée ✅ — **mais** l'assertion « dernière affirmation fausse restante » est **falsifiée** (🔴 B-1) |

---

## 9. 🔵 Suggestions d'amélioration (ne bloquent pas)

| # | Emplacement | Suggestion |
|---|---|---|
| S-1 | `scripts/check_branch_protection.py:616-716` | `_attribute()` concentre 6 branches d'attribution sur ~100 lignes : extraire une table `{status: handler}` améliorerait la testabilité de chaque cause. Complexité actuelle **acceptable** et linéaire. |
| S-2 | `scripts/check_branch_protection.py:751` | `opts.from_protection_status or 200` : un `--from-protection-status 0` serait silencieusement transformé en 200. Utiliser `if … is not None`. |
| S-3 | `scripts/check_branch_protection.py:494-502` | `restrictions` présent avec des listes vides est compté en écart. Conforme au mapping imposé, mais un commentaire évitera un faux diagnostic futur. |
| S-4 | `scripts/factory_sync.py:181-184, 212` | Le diff humain a introduit 2 lignes vides non prévues par le diff exact de T4 (aucun impact fonctionnel). À aligner lors du prochain diff humain. |
| S-5 | `reports/US-00.4/*.json` | Extension `.json` pour des fichiers non parsables : préférer `.txt`/`.raw` (ou un `.json` strict + un `.meta.txt` d'en-tête) pour qu'un outil de CI puisse les parser. |
| S-6 | `factory.config.json:63` | La ligne blanche à 2 espaces (T6, non cochée) est **committée** dans un fichier Art. 6. Sans impact (`--check` vert, JSON valide), à nettoyer par l'humain comme prévu. |

---

## 10. Conclusion

Travail d'une rigueur inhabituelle : le recadrage est assumé, le constat est **reproductible**
(je l'ai reproduit), le comparateur est réellement en lecture seule, le mapping asymétrique est
correct sur les clés de la cible — y compris les deux pièges (`enforce_admins.enabled`,
`required_pull_request_reviews` absent ≠ zéro) —, le marquage `[SIMULATION] ` est **structurellement
intègre**, l'inférence de l'AC-1 fait (b) est **déclarée** et non maquillée, la garantie d'import
paresseux **tient**, le bloc généré est **intact**, `origin/main` est **intacte**, et **aucune** tâche
reportée n'a été exécutée. Les réserves de @Developer sont **toutes honnêtes** et aucune ne masque un
défaut.

Je prononce néanmoins **FAILED**, sans complaisance et en assumant le désaccord : cette US juge la
factory sur l'exactitude de ses affirmations et sur l'interdiction du faux vert. Elle doit être tenue
au même standard.
- **B-1** : elle affirme une exhaustivité qu'un grep avec **ses propres motifs** démolit — et deux
  des occurrences restantes sont dans `ci.yml` et `pre-push`, c'est-à-dire dans les artefacts
  d'enforcement dont elle parle.
- **B-2** : son unique livrable de code contient l'unique chemin de **faux vert** du dispositif,
  contredisant sa propre doctrine (`MappingGap`) et l'AC-3 nominal.

Les deux correctifs sont peu coûteux (un commentaire de workflow, une garde symétrique de mapping,
deux renvois de rapport, un diff humain pour `pre-push`/`factory_sync.py`) et **ne remettent en cause
ni le périmètre re-cadré, ni la dérogation humaine, ni la valeur livrée**. Après correction, je
n'anticipe aucun obstacle à un PASS.

**Rappel de mon périmètre** : je n'ai modifié ni le code, ni le SCB, ni `PROJECT_LOG.md`, ni le Story
File. Ce rapport et mon événement de trace sont mes seules sorties. Aucune commande d'écriture n'a
été émise sur `main`, sur le dépôt distant, ni sur la protection de branche : mes seuls appels
réseau ont été **4 `GET` d'API** (§2) et la lecture de `git ls-remote`.
