# US-00.7 — Revue de code (`Audit Rev 🔍`)

> **Agent** : @CodeReviewer — **contexte frais** (Constitution Art. 2 / règle 5 : aucune connaissance de
> la session ayant produit le code).
> **Modèle** : `claude-opus-5[1m]`
> **Date** : 2026-07-28
> **Story File** : [`docs/stories/US-00.7-application-protection-branche.md`](../../docs/stories/US-00.7-application-protection-branche.md)
> **Plage auditée** : `f4400ca..HEAD` (`HEAD` = `2dea2bb`, branche `feat/US-00.7-certif`)

---

## ⚖️ VERDICT : **PASSED**

| Sévérité | Nombre | Effet sur le verdict |
|---|---|---|
| 🔴 **BLOQUANT** | **0** | — |
| 🟠 **Majeur (hors périmètre de ce verdict)** | **1** | Doit bloquer `/certify`, **pas** la revue de code |
| 🟡 **Mineur** | **4** | Suggestions d'amélioration |
| 🔵 **Suggestion** | **3** | Sans effet |

**Motivation du verdict** : aucun des critères bloquants du rôle n'est atteint — **0** erreur de lint,
**0** erreur de typecheck, **aucune** duplication de code, **aucune** requête N+1 *(sans objet : aucun
accès données)*, **aucun** code nouveau sans test, **aucun** AC dépendant du code laissé non couvert.
Les trois fichiers d'enforcement modifiés ne portent **aucune** ligne de logique changée — vérifié par
filtrage du diff, sortie citée au §3. Le seul changement fonctionnel est le correctif **NB-1** (3 lignes),
dont j'ai **reproduit indépendamment** les quatre scénarios : **la portée annoncée correspond exactement
à la portée réelle**.

⚠️ **Réserve explicite, sans effet sur ce verdict** : l'**AC-4 nominal n'est pas satisfait** (T11(d),
finding **M-1**). Il est **déclaré comme tel** par l'US elle-même, la case 13 de la DoD est **décochée**,
et aucun livrable ne prétend le contraire. Ce n'est pas un défaut de code : c'est une **preuve
opérationnelle manquante**, dont l'arbitrage appartient à @QA_Tester et au rituel `/certify`.

---

## 1. Vérification indépendante du périmètre du diff

La consigne reçue annonçait un piège de périmètre. **Vérifié plutôt que cru.**

```console
$ git log --oneline f4400ca..HEAD
2dea2bb docs(us-00.7): T11 partielle — PR #12 fusionnee, refus de fusion NON obtenu
9fdb7fd Merge pull request #12 from gitgdx/feat/US-00.7-application-protection-branche
2686538 chore(us-00.7): DoD levee case par case — 24/34, 10 motivees
0f6d63a feat(us-00.7): T20 — en-tete pre-push corrige par edition humaine (Art. 6)
fbd0e3c feat(us-00.7): T12-T23 coherence du corpus + ledgers + rectifications
66d2bab feat(us-00.7): T10 — test negatif SERVEUR, les 3 refus prouves
6932fea feat(us-00.7): T8+T9 — protection de branche APPLIQUEE, exit 0 REEL
27464a9 feat(us-00.7): phase 0 — correctif NB-1, controles prealables, plan de retour arriere
90fd1a6 docs(us-00.7): creation US-00.7 — application de la protection apres deblocage

$ git diff --stat f4400ca..HEAD | tail -1
 47 files changed, 7056 insertions(+), 256 deletions(-)

$ git diff --stat main...HEAD | tail -1
 6 files changed, 224 insertions(+), 16 deletions(-)
```

**Confirmé** : `main...HEAD` n'aurait montré que **6 fichiers sur 47**. L'avertissement était exact ;
l'audit porte bien sur `f4400ca..HEAD`.

---

## 2. Gates statiques — sorties réelles

### 2.1 Gates nommés dans la procédure du rôle : **ils n'existent pas dans ce stack profile**

```console
$ python scripts/run_gates.py --gate lint
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT_LINT=1

$ python scripts/run_gates.py --gate typecheck
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT_TYPECHECK=1
```

Cause établie, **et ce n'est pas un défaut de cette US** — `factory.config.json` (adapter `flutter`,
composant `app`) ne déclare que : `format`, `analyze`, `test`, `deps_audit`, `build`. En stack Dart,
**`analyze` est l'équivalent conjoint de lint et de typecheck**. Gates réels exécutés :

```console
$ python scripts/run_gates.py --gate analyze
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 11.5s)
✅ app.analyze
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).
EXIT=0

$ python scripts/run_gates.py --gate format
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 2 files (0 changed) in 0.03 seconds.
✅ app.format
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).
```

### 2.2 Python — le seul code réellement modifié par l'US

```console
$ python -m py_compile scripts/check_branch_protection.py tests/fixtures/US-00.7/nb1_harness.py
OK compile
```

### 2.3 Gates de gouvernance

```console
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md,
libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer
`python scripts/factory_sync.py --check-remote` (droits admin requis).
EXIT_SYNC=0

$ python scripts/validate_trace.py --us US-00.7
Traçabilité conforme.
EXIT_TRACE=0

$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.
EXIT_SCB=0
```

**Bilan §2 : 0 erreur de lint, 0 erreur de typecheck, 0 violation de gouvernance.**

---

## 3. Fichiers d'enforcement — aucune logique affaiblie

Point signalé comme à vérifier. Méthode : filtrer du diff toute ligne de commentaire et toute ligne
vide, puis constater ce qui **reste**.

```console
$ git diff f4400ca..HEAD -- .github/workflows/ci.yml \
  | grep -E "^[+-]" | grep -vE "^(\+\+\+|---)" | grep -vE "^[+-]\s*#" | grep -vE "^[+-]\s*$"
--- (vide = seuls des commentaires ont change) ---

$ git diff f4400ca..HEAD -- scripts/apply_branch_protection.sh | (idem)
--- (vide = OK) ---

$ git diff f4400ca..HEAD -- scripts/githooks/pre-push | (idem)
--- (vide = OK) ---
```

**Résultat** : pour `ci.yml`, `apply_branch_protection.sh` et `scripts/githooks/pre-push` (Art. 6),
**zéro ligne non-commentaire n'a changé**. Ni `on:`, ni `jobs:`, ni `name:`, ni `permissions:`, ni la
logique `PUT`, ni les lignes 15-29 du hook. La contrainte « ⛔ aucune ligne de logique » est **tenue**.

### 3.1 Aucun chemin d'écriture distante introduit dans l'outil déclaré en lecture seule

```console
$ grep -nE '\-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)|--method' \
        scripts/check_branch_protection.py
exit=1 (aucun resultat)
```

**Lecture seule préservée** (critère de test #11 **levé**). Le seul écrivain reste
`apply_branch_protection.sh`, dont la logique est inchangée.

### 3.2 Aucun élargissement de périmètre vers la CI

```console
$ grep -rn "check-remote" .github/workflows/
exit=1 (aucun resultat)

$ grep -rniE "selftest|check_branch_protection" .github/workflows/
exit=1 (aucun resultat)
```

Le contrôle distant **reste hors CI** et **aucun `selftest` n'a été ajouté** : la dette est **maintenue
ouverte**, pas silencieusement close (critère #12 **levé**).

---

## 4. Le correctif NB-1 — portée annoncée **vs** portée réelle

### 4.1 Le correctif est bien de 3 lignes, et de 3 lignes seulement

Lignes fonctionnelles isolées du diff de `scripts/check_branch_protection.py` :

```diff
-def _guard_actual(actual: dict) -> tuple[list[str], list[str]]:                      # l. 501
+def _guard_actual(actual: dict, expected: dict) -> tuple[list[str], list[str]]:
-    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS, "")                   # l. 515
+    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")
-    neutral_ignored, uncovered_active = _guard_actual(actual)                        # l. 591
+    neutral_ignored, uncovered_active = _guard_actual(actual, expected)
```

Tout le reste du diff de ce fichier est **docstring et commentaire**. Contrôle du changement de
signature — **aucun appelant orphelin** :

```console
$ grep -rn "_guard_actual" --include="*.py" .
./scripts/check_branch_protection.py:501:def _guard_actual(actual: dict, expected: dict) -> ...
./scripts/check_branch_protection.py:591:    neutral_ignored, uncovered_active = _guard_actual(actual, expected)
./tests/fixtures/US-00.7/nb1_harness.py:9:signalée par `_guard_actual()`, qui filtrait ... (commentaire)
```

**Un seul site d'appel, correctement mis à jour.** `expected` y est garanti non-`None` : `compare()` le
reçoit en paramètre et `_guard_mapping(expected)` s'exécute juste avant.

### 4.2 J'ai re-exécuté les 4 scénarios moi-même, sans lire `nb1_fix.md` au préalable

```console
$ python tests/fixtures/US-00.7/nb1_harness.py --target <cible> --protection <fixture> \
                                               --branch tests/fixtures/US-00.4/branch_protected_true.json
SCENARIO A -> exit=2
     [SIMULATION] Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non
     couvert(s) ... : enforce_admins = {"enabled": true}.
SCENARIO B -> exit=0
     [SIMULATION] [IGNORÉ — NEUTRE] ... : allow_fork_syncing, block_creations, enforce_admins,
     lock_branch, ...
SCENARIO C -> exit=0
     [SIMULATION] [IGNORÉ — NEUTRE] ... : allow_fork_syncing, block_creations, lock_branch
SCENARIO D -> exit=2
     [SIMULATION] Code HTTP : 200 — MAPPING INCOMPLET — ... : required_status_checks = {...}
```

| Scénario | Annoncé par l'US | **Mesuré par moi** | Concordance |
|---|---|---|---|
| **A** — cible amputée de `enforce_admins`, réel `{"enabled": true}` | corrigé → exit ≠ 0 | **exit 2**, clé nommée | ✅ |
| **D** — cible amputée de `required_status_checks`, réel présent | corrigé → exit ≠ 0 | **exit 2**, clé nommée | ✅ |
| **B** — réel `{"enabled": false}` *(relâchement)* | **NON corrigé**, clé nommée `[IGNORÉ — NEUTRE]`, exit 0 | **exit 0**, `enforce_admins` listé en neutre | ✅ |
| **C** — clé absente **des deux côtés** | **NON corrigé**, clé **même pas nommée**, exit 0 | **exit 0**, `required_pull_request_reviews` **absent de toute liste** | ✅ |

**Jugement demandé — la portée annoncée correspond-elle à la portée réelle ? OUI, exactement.**
L'US n'affirme nulle part que NB-1 « ferme le trou » ; elle qualifie le correctif de « progrès strict,
pas une fermeture ». C'est **littéralement vrai**. Le Story File va jusqu'à **rectifier son propre AC-7**
(§Incohérences n° 1) et son propre décompte « une ligne → 3 lignes » (n° 2). Aucune sur-affirmation.

### 4.3 NB-1bis est réellement ouvert, et le correctif identifié est le bon

```console
$ sed -n '/^def _guard_mapping/,/^def /p' scripts/check_branch_protection.py
def _guard_mapping(expected: dict) -> None:
    unknown = sorted(set(expected) - MAPPED_TOP_KEYS)      # <-- clés EN TROP uniquement
    ...
```

**Confirmé** : `_guard_mapping` ne teste que `set(expected) - MAPPED_TOP_KEYS`. Le sens inverse —
`MAPPED_TOP_KEYS - set(expected)`, la **complétude de la cible** — n'est **pas** contrôlé. C'est bien le
correctif nommé par l'US, et il est bien **hors périmètre** (AC-7 erreur interdit l'élargissement).

### 4.4 Contrôle compensatoire — vérifié par moi, il tient

```console
cles payload   : 8 ['allow_deletions', 'allow_force_pushes', 'enforce_admins',
                    'required_conversation_resolution', 'required_linear_history',
                    'required_pull_request_reviews', 'required_status_checks', 'restrictions']
MAPPED_TOP_KEYS: 8 [idem]
EGALITE        : True
rpr present    : {'required_approving_review_count': 0}
restrictions   : None      strict : True      nb contextes : 4
```

La cible **n'est pas amputée** → aucun scénario B/C/D n'est atteignable aujourd'hui. L'`exit 0` invoqué
comme preuve par l'AC-2 est **fiable pour la bonne raison**, et cette raison est écrite.

---

## 5. Tests présents pour chaque AC dépendant du code — et non-régression

### 5.1 Les 12 chemins du comparateur, rejoués par mes soins

```console
1  exit0 conforme                    exit=0   (attendu 0)  ✅
2  exit1 divergente                  exit=1   (attendu 1)  ✅
3  404 + protected=false             exit=1   (attendu 1)  ✅
4  404 + protected=true              exit=2   (attendu 2)  ✅
5  403 plan                          exit=2   (attendu 2)  ✅
6  lock_branch actif                 exit=2   (attendu 2)  ✅
7  block_creations actif             exit=2   (attendu 2)  ✅
8  cle inconnue active               exit=2   (attendu 2)  ✅
9  cles additives NEUTRES            exit=0   (attendu 0)  ✅  <- critère #24 d'US-00.4
10 usage: --from-protection seul     exit=2   (attendu 2)  ✅
11 usage: --from-branch seul         exit=2   (attendu 2)  ✅
12 usage: fichier inexistant         exit=2   (attendu 2)  ✅
```

**Aucune issue ne change.** En particulier, le critère #24 (« une clé additive neutre ne fait pas
trébucher l'outil ») **reste vert** : le correctif ne rend pas l'outil rouge sur une évolution neutre de
l'API GitHub. **Aucune régression.**

### 5.2 Le harnais de simulation — ses propres garde-fous fonctionnent

```console
$ python tests/fixtures/US-00.7/nb1_harness.py --target <cible COMPLETE 8 cles>
[SIMULATION] REFUS : la cible injectée porte les 8 clés mappées — elle n'est pas amputée. Ce harnais
n'exerce que des cibles SIMULÉES amputées, jamais la cible générée réelle.
exit=1

symboles presents dans le module : ['make_reader', '_get_via_gh', '_get_via_urllib']

$ python tests/fixtures/US-00.7/nb1_harness.py | grep -vc "^\[SIMULATION\]"
0        <- 0 ligne sans prefixe [SIMULATION]
```

Les trois verrous **sont réels, pas déclarés** : (i) le refus d'injecter une cible complète **s'exerce**,
(ii) les trois symboles réseau monkeypatchés **existent** dans le module cible — le patch ne porte pas
dans le vide, (iii) **toutes** les lignes portent `[SIMULATION]`. L'étanchéité simulé/réel (risque R1
d'US-00.4) est **tenue au niveau du code**, pas seulement de la convention.

`__pycache__` **n'est pas suivi par git** (`git ls-files | grep pycache` → vide).

### 5.3 Couverture AC ↔ code

| AC | Nature | Couvert par du code ? | Test associé | Verdict |
|---|---|---|---|---|
| AC-1 | acte d'administration | non (opérationnel) | preuves brutes `applied_state/` | ✅ |
| AC-2 | outillage existant | non modifié | `check_remote_exit0_reel.txt` + re-exécuté §7 | ✅ |
| AC-3 | effet serveur | non | `negative_test_server.txt` | ✅ |
| **AC-4** | effet serveur | non | **preuve manquante** | 🟠 **M-1** |
| AC-5 / AC-6 | corpus | non | balayages, re-exécutés §8 | ✅ |
| **AC-7** | **3 lignes de Python** | **oui** | **8 exécutions de fixtures + 12 chemins, tous re-joués §4.2/§5.1** | ✅ |
| AC-8 | préalable de sûreté | non | `labels_verification.md` + ordre des commits §6 | ✅ |

**Aucun code nouveau sans test.** Le seul AC portant du code (AC-7) est le plus densément testé de l'US.

---

## 6. La séquence de sûreté imposée est **prouvable dans l'historique git**

L'US impose `AC-7 → AC-8 → AC-1 → AC-2 → AC-3`. Ce n'est pas une déclaration : c'est vérifiable.

```console
$ git log --oneline -S "Plan de retour arrière — verrouillage" -- docs/GIT_PROTECTION.md
27464a9 feat(us-00.7): phase 0 — correctif NB-1, controles prealables, plan de retour arriere

$ git log --oneline f4400ca..HEAD -- reports/US-00.7/applied_state/protection_applied.json
6932fea feat(us-00.7): T8+T9 — protection de branche APPLIQUEE, exit 0 REEL

$ git log --oneline --reverse f4400ca..HEAD | cat -n
     2  27464a9  phase 0 — correctif NB-1, controles prealables, plan de retour arriere
     3  6932fea  T8+T9 — protection de branche APPLIQUEE, exit 0 REEL
     4  66d2bab  T10 — test negatif SERVEUR, les 3 refus prouves
```

Le **correctif NB-1** et le **plan de retour arrière** sont dans le commit `27464a9`, **antérieur** au
commit `6932fea` qui archive le `PUT`, lui-même antérieur au test négatif `66d2bab`.
**Critère de test #9 levé, par l'historique et non par une affirmation.**

---

## 7. Vérification indépendante de l'état réel — lecture seule, par moi, maintenant

Je n'ai pas voulu m'appuyer sur les preuves archivées par la session auditée. Contrôle direct :

```console
=== VERIF INDEPENDANTE (lecture seule) — 2026-07-28T16:07:35Z ===
-- visibilite --
{"admin":true,"private":false,"visibility":"public"}
-- branches/main --
{"name":"main","protected":true}
-- protection (champs cles) --
{"contexts":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
             "check-branch-name","📱 App (gates run_gates.py)"],
 "conv":true,"del":false,"enforce_admins":true,"fp":false,"lin":false,
 "restrictions":false,"reviews":0,"strict":true}

$ python scripts/factory_sync.py --check-remote
Protection de gitgdx/Concentration:main — conforme à la cible générée par
`factory_sync.py --emit-branch-protection` (comparaison champ par champ ; aucun champ actif non
couvert dans la réponse).
EXIT_CHECK_REMOTE=0
```

**L'état réel du dépôt correspond, champ par champ, à ce que les livrables affirment.** `restrictions`
est bien **absente** de la réponse. L'`exit 0` de `--check-remote` est **reproduit par un tiers**, sans
préfixe `[SIMULATION]`. Les preuves archivées ne sont pas surévaluées.

---

## 8. Aucun artefact daté ou certifié réécrit — revendication vérifiée

```console
$ git diff --stat f4400ca..HEAD -- "docs/stories/US-00.4*" "reports/US-00.4/**" "docs/adr/ADR-006*" \
    "docs/stories/US-00.1*" "docs/trace/**" "tests/features/US-00.4*" "reports/US-00.3/**" \
    "factory.config.json" "scripts/factory_sync.py" "scripts/run_gates.py" ".claude/hooks/" \
    ".gitleaks.toml" ".claude/settings.json" "scripts/factory_env.sh" "scripts/install_hooks.sh"
 docs/trace/US-00.7/events.jsonl | 7 +++++++
 1 file changed, 7 insertions(+)
```

**Une seule entrée** : `docs/trace/US-00.7/events.jsonl`, **+7 / −0** — un ajout append-only dans le
répertoire de trace **de cette US**. `ADR-006`, `reports/US-00.4/**`, les Story Files d'US-00.4 et
d'US-00.1, `factory.config.json` et **tous** les fichiers Art. 6 hors `pre-push` : **intouchés**.

`tests/fixtures/US-00.4/README.md` (matériel de test d'une US certifiée) : **27 insertions / 0
suppression**, encadré daté en tête, **aucune ligne existante modifiée** — l'historisation additive
arbitrée est **respectée à la lettre**.

### 8.1 Balayage de sur-affirmation, re-exécuté

```console
$ grep -rniE "inviolable|tout est enforced|toutes? les r(è|e)gles sont|cha(î|i)ne de confiance|
              impossible (à|a) contourner" --include="*.md" --include="*.yml" --include="*.py" ...
```

**Toutes** les correspondances sont soit des **listes d'interdits** (« ⛔ Interdits dans tout livrable :
“inviolable”… »), soit des **négations explicites** (ADR-007 : « **et toujours pas “inviolable”** : la
règle reste révocable par un administrateur, sans détection automatique »).
**0 sur-affirmation réelle dans le corpus vivant.**

### 8.2 Balayage d'impossibilité, re-exécuté sur les 11 artefacts vivants

`docs/SQUAD_GUIDE.md` et `scripts/githooks/pre-push` : **0 correspondance**. Pour les autres, chaque
occurrence relève d'une des classes légitimes déjà inventoriées par `non_regression.md` §4.1 :
historisation datée, **conditionnel** exigé par ADR-007 D5 (« un retour en privé ramènerait le 403 »),
sémantique d'outil (le 403 de plan reste un cas d'erreur légitime du comparateur), ou négation du motif.
**Une** exception subsiste, arbitrée : voir finding **m-1**.

### 8.3 Traçabilité des commits

```console
$ (pour chacun des 8 commits non-merge) git log -1 --format=%B | grep -c "^US: US-00.7"
2dea2bb  1    2686538  1    0f6d63a  1    fbd0e3c  1
66d2bab  1    6932fea  1    27464a9  1    90fd1a6  1
```

**8/8 commits portent le trailer `US: US-00.7`**. `PROJECT_LOG.md` : **+14 lignes**.
Aucun `--no-verify` (Art. 1 respecté ; le rapport `negative_test_server.txt` consigne d'ailleurs que le
test négatif a été **exécuté par l'humain** précisément parce que le hook
`.claude/hooks/block_dangerous_bash.sh` bloque l'agent — l'inverse d'un contournement).

### 8.4 Aucun secret dans les livrables

```console
$ grep -rnE "ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|
             Authorization:\s*(token|Bearer)" reports/US-00.7/ tests/fixtures/US-00.7/
exit=1 (aucun resultat)
```

---

## 9. Findings

> Format : `[Fichier:Ligne] | [Problème] | [Solution]`

### 🔴 Bloquants — **AUCUN**

Aucun finding n'atteint les critères bloquants du rôle (lint, typecheck, duplication, N+1, code sans
test, AC non couvert par le code).

---

### 🟠 M-1 — Majeur, **hors périmètre de ce verdict** : l'AC-4 nominal n'est pas prouvé

`[reports/US-00.7/merge_block.md:9-22]` · `[docs/stories/…US-00.7….md:1076 (T11), 1534 (DoD 13)]`
**Problème** : la **tentative de fusion réellement refusée** (T11(d)) n'a jamais eu lieu.
`applied_state/merge_refusal_raw.txt` **n'existe pas**. Ce qui est archivé est
`mergeStateStatus: BLOCKED` à `15:25:30Z` — un **état calculé par GitHub**, **pas une action refusée**.
Par conséquent, l'énoncé d'**ADR-007 D2** (`docs/adr/ADR-007-…md:228`) — « *l'US n'est pas livrable sans
eux* : 3 refus serveur **et 1 refus de fusion** » — pose une barre que l'US **n'a pas franchie**.
**Ce qui empêche d'en faire un bloquant de revue de code** : l'US **ne dissimule rien**. Le manque est
écrit **en tête** de `merge_block.md` (« ⛔ EN TÊTE, PARCE QU'ON NE L'ENTERRE PAS »), T11 et la case 13
sont **décochées**, `reports/US-00.7/README.md:178`, `docs/GIT_PROTECTION.md:26`,
`transmissions.md:237` et `CLAUDE.md:55` le répètent, et le rapport va jusqu'à nommer la **cause**
(fenêtre estimée « quelques minutes » par extrapolation d'une durée locale, réelle **~80 s**). Il ne
s'agit d'aucun défaut du diff.
**Solution** : appliquer la procédure corrigée déjà écrite (`merge_block.md` §« Comment cette preuve
reste obtenable ») sur la **PR de certification** `feat/US-00.7-certif` : tenter
`gh pr merge <n> --merge` **immédiatement après l'ouverture**, **avant** toute autre capture, et
archiver le refus brut. ⛔ **Sans cette preuve, la case 13 doit rester décochée et `/certify` doit
refuser** — l'arbitrage appartient à @QA_Tester puis au rituel de certification, **pas** à la revue de
code.

---

### 🟡 Mineurs

**m-1** · `[reports/US-00.7/t20_pre_push.md:82-83]` | **Sur-affirmation localisée, dans l'US même dont
la thèse est l'anti-sur-affirmation.** Le rapport écrit : « `scripts/githooks/pre-push` était le
**dernier** des 11 à porter encore une affirmation d'impossibilité au présent. Le critère devient
**entièrement levable**. » **C'est inexact** : j'ai vérifié que
`tests/fixtures/US-00.4/README.md:31` porte toujours, **au présent**, « *les chemins exit 0 et exit 1 …
ne sont pas observables sur ce dépôt : … 403* » — ligne dont la réécriture est **interdite** par
arbitrage. Le propre rapport `non_regression.md:466` est **plus juste** et **contredit** t20 :
« 🟡 **LEVÉ sur 9/11, avec 2 exceptions documentées** ». | **Solution** : aligner
`t20_pre_push.md` sur `non_regression.md` — remplacer « le dernier / entièrement levable » par « le
dernier **des exceptions traitables** ; subsiste `tests/fixtures/US-00.4/README.md:31`, **démentie en
amont** par l'encadré additif du 2026-07-28, réécriture interdite ». *(Le lecteur du fichier de fixtures
rencontre le démenti daté **avant** la ligne périmée : le risque pratique est faible ; c'est la
**revendication** qui dépasse la mesure, pas l'état du corpus.)*

**m-2** · `[docs/stories/US-00.7-application-protection-branche.md:1334]` | **Tâche T24 décochée alors
que son livrable existe et est validé.** `docs/adr/ADR-007-application-protection-branche.md` est
présent (569 lignes, `Statut : Accepté`, `Remplace : ADR-006`), `EVT_ARCHI_VALIDATED` est **tracé**, et
la **case 25 de la DoD est cochée**. Le décompte des tâches (22/24) sous-évalue donc l'avancement réel
et rend l'état de l'US ambigu pour un auditeur suivant. | **Solution** : cocher T24 (@Architect — hors
mon périmètre : je ne modifie pas le Story File), ou expliciter ce qui y resterait dû.

**m-3** · `[reports/US-00.7/applied_state/]` | **Les noms de fichiers livrés divergent de ceux prescrits
par T9 et par les critères 15/16/17.** Prescrits : `branch_after.json`, `protection_after.json`,
`check_remote_exit0.txt`. Livrés : `branch_main_after.json`, `protection_applied.json`,
`check_remote_exit0_reel.txt`. Le contenu est **conforme et complet** (vérifié §7), mais un audit
ultérieur qui suivrait le Story File à la lettre chercherait des fichiers absents. | **Solution** :
soit renommer, soit — préférable, la trace étant archivée — ajouter la correspondance
`prescrit → livré` dans `reports/US-00.7/README.md`.

**m-4** · `[docs/stories/US-00.7-application-protection-branche.md:1527 (DoD 6)]` | **Numéros de ligne
périmés dans la DoD** : « `MAPPED_TOP_KEYS & set(expected)`, **ligne 503** » — la ligne réelle est
**515** (signature **501**, appel **591**). L'US **signale déjà elle-même** cet écart (§État de la DoD,
« la numérotation a dérivé depuis la rédaction ») : le défaut est **honnêtement consigné**, il n'est pas
corrigé. | **Solution** : préférer une référence **symbolique** (`_guard_actual` / `_classify_extra`) à
un numéro de ligne dans les futures DoD — un numéro de ligne est périssable par construction.

---

### 🔵 Suggestions d'amélioration — sans effet sur le verdict

**s-1** · `[reports/US-00.7/rollback_plan.md]` | **44 %** de ses lignes significatives (57/131) sont
**identiques** à `docs/GIT_PROTECTION.md`. Ce n'est **pas** une duplication de code, et son en-tête
**explique** la raison (artefact de préparation T6, rédigé hors du fichier cible faute de droit
d'édition en phase 0) ; mais l'insertion a eu lieu depuis, et deux copies d'un plan de récupération
peuvent diverger au pire moment. | Convertir le corps en renvoi vers la section canonique de
`GIT_PROTECTION.md`, en conservant l'en-tête d'écart de périmètre à valeur d'historique.

**s-2** · `[tests/features/US-00.7-application-protection-branche.feature:124-131]` | Le scénario AC-4
nominal (« La fusion est refusée… ») ne porte **aucun marqueur** indiquant qu'il **n'a pas été
démontré**. Un fichier `.feature` est une **spécification**, pas un journal de résultats — l'absence
n'est donc pas fautive —, mais la traçabilité QA y gagnerait. | Ajouter un tag `@non-demontre-T11d` ou
un commentaire renvoyant à `reports/US-00.7/merge_block.md`.

**s-3** · `[factory.config.json — adapter.components.app.gates]` | Les gates `lint` et `typecheck`,
nommés par la procédure standard d'audit, **n'existent pas** dans ce stack profile : `run_gates.py`
répond « aucun gate ne correspond » et sort **1**. Un auditeur pressé pourrait lire cet exit 1 comme un
**échec de gate** au lieu d'une **absence de gate** — faux positif de la même famille que ceux
qu'US-00.4 traque. | **Hors périmètre d'US-00.7** — candidat `/audit-methodo` : soit déclarer des alias
`lint` → `analyze` et `typecheck` → `analyze`, soit corriger la nomenclature des rituels d'audit.

---

## 10. Ce que cette revue a contrôlé **et n'a pas pu établir**

* **Contrôlé par re-exécution indépendante** : gates statiques · les 4 scénarios NB-1 · les 12 chemins
  de non-régression · les garde-fous du harnais · l'état **réel** de la protection (lecture seule) ·
  `--check-remote` → exit 0 · les deux passes de balayage du corpus · l'absence de chemin d'écriture ·
  l'absence de réécriture d'artefact daté · l'ordre des commits · les trailers · l'absence de secret.
* **Non établi par cette revue** : le **refus de fusion** (M-1) · le comportement pour un **autre
  acteur**, un **jeton d'application**, l'**interface web**, une PR issue d'un **fork** ou **réouverte**
  · la **persistance** de l'état (aucune détection automatique de dérive — dette **maintenue ouverte**,
  correctement re-consignée) · la **correction de NB-1bis** (résidu **ouvert**, correctement nommé).
* **Conditionnalité** : tout l'édifice repose sur la **visibilité publique** du dépôt, que j'ai
  re-constatée (`"visibility":"public"`) et que les livrables énoncent partout comme condition.

---

## 11. Conclusion

**PASSED.** Le diff est propre au sens des critères bloquants du rôle : gates verts, aucune logique
d'enforcement affaiblie, aucun chemin d'écriture acquis par un outil déclaré en lecture seule, correctif
minimal et **exactement** de la portée annoncée, non-régression prouvée sur 12 chemins, aucune
duplication de code, aucun artefact daté ou certifié falsifié.

Le point remarquable de cette US, du point de vue d'un relecteur à contexte frais, est que **ses
livrables résistent à la vérification hostile** : chaque affirmation que j'ai cherché à mettre en défaut
— portée du correctif, réalité de l'`exit 0`, non-réécriture des artefacts certifiés, attribution des
refus serveur, absence de sur-affirmation — s'est révélée **exacte ou déjà qualifiée par l'US
elle-même**. Les rapports vont jusqu'à consigner un **incident de procédure** (`negative_test_server.txt`
§Incident) et une **preuve manquée** (`merge_block.md`) qu'il aurait été facile de taire.

Le **seul** écart que ma vérification indépendante ajoute au dossier est **m-1** : une revendication de
`t20_pre_push.md` que le rapport voisin `non_regression.md` contredit déjà, et qui reste **mineure**.

**Réserve à transmettre à la suite du cycle** : l'**AC-4 nominal n'est pas satisfait** (**M-1**). La
case 13 doit rester **décochée** et le rituel `/certify` doit **refuser** tant que le refus de fusion
n'est pas archivé brut. Ce n'est pas une réserve de revue de code — c'est une réserve de certification,
et elle appartient à @QA_Tester puis à `/certify`.

---

*Rapport produit par @CodeReviewer (contexte frais, `claude-opus-5[1m]`), 2026-07-28. Aucun fichier de
code, de gouvernance, le SCB ou le Story File n'a été modifié par cette revue — seuls ce rapport et la
ligne de trace correspondante.*
