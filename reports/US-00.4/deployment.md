# US-00.4 — Rapport de déploiement (@DevOps_Engineer)

| Champ | Valeur |
|---|---|
| **US** | US-00.4 — Enforcement de la branche principale : constat, vérification honnête et cible armée |
| **Date** | 2026-07-27 |
| **Agent** | @DevOps_Engineer (`devops`) — modèle `claude-opus-5[1m]` |
| **Branche** | `feat/US-00.4-ci-protection-branche` |
| **HEAD déployé** | `e81eff80c3aa8f08d79ddb8737ba61305666de30` (10 commits, 46 fichiers, +7686 / -60) |
| **PR** | **#10** — https://github.com/gitgdx/Concentration/pull/10 |
| **Sha de fusion** | **`15121d8f4e471588081eed0fe91274c86ba5c3bb`** (2 parents : `801a046` + `e81eff8`) |
| **`main` avant** | `801a046e7c2f833a4038c4080e0eb19ca0d28754` |
| **`main` après** | **`15121d8f4e471588081eed0fe91274c86ba5c3bb`** |
| **Fusionné à** | 2026-07-27T13:15:45Z par `gitgdx` |

> [!WARNING]
> **Ce déploiement ne protège pas `main`.** Après cette fusion, `main` **n'est toujours pas
> protégée** et **ne peut pas l'être** sur ce dépôt (403 de plan sur la protection classique **et**
> sur les rulesets). `apply_branch_protection.sh` reste **armé mais NON appliqué**. **Aucun status
> check n'est requis.** Le **risque #2 d'EPIC_00 reste OUVERT**. Dérogation humaine tracée
> (`EVT_WAIVER_GRANTED`, Constitution Art. 5). **T16→T19 reportées et interdites** : aucun test
> négatif n'a été exécuté, `main` n'a jamais été poussée en direct.

---

## 1. Pré-vol (avant toute action)

| Contrôle | Commande | Résultat |
|---|---|---|
| Arbre propre | `git status` | `nothing to commit, working tree clean` |
| Gates qualité | `python scripts/run_gates.py --all` | **5/5 verts** — `Tous les gates bloquants passent (5 exécutés).` (test : 2 passed, couverture **89,5 % (17/19)** ≥ 80 % ; build web OK) |
| Conformité SCB | `python scripts/check_scb_compliance.py` | `SCB conforme — Aucune violation détectée.` |
| Traçabilité | `python scripts/validate_trace.py --us US-00.4` | `Traçabilité conforme.` |
| Référence distante | `git rev-parse origin/main` | `801a046e7c2f833a4038c4080e0eb19ca0d28754` (conforme au brief) |
| Visas SCB | ligne US-00.4 | `✅ @PO | N/A | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 PASS | ⏳ | ⏳` |

## 2. Comportement du hook `pre-push` (test réel, cas positif)

Le hook `scripts/githooks/pre-push` a été **modifié par l'humain en T22** ; ce push en est le
**premier exercice réel**.

- Câblage vérifié : `git config core.hooksPath` → `scripts/githooks` ;
  `git rev-parse --git-path hooks` → `scripts/githooks` ; `-rwxr-xr-x` (exécutable).
- **Commande** (jamais `--no-verify`) : `git push -u origin feat/US-00.4-ci-protection-branche`
- **Résultat : exit 0**, poussée acceptée, **aucune sortie produite par le hook**.

```
remote: Create a pull request for 'feat/US-00.4-ci-protection-branche' on GitHub by visiting:
remote:      https://github.com/gitgdx/Concentration/pull/new/feat/US-00.4-ci-protection-branche
To https://github.com/gitgdx/Concentration.git
 * [new branch]      feat/US-00.4-ci-protection-branche -> feat/US-00.4-ci-protection-branche
branch 'feat/US-00.4-ci-protection-branche' set up to track 'origin/feat/US-00.4-ci-protection-branche'.
=== PUSH_EXIT=0 ===
```

**Conclusion** : le hook laisse passer une branche `feat/*` **silencieusement** — comportement
attendu (sa boucle `while read` ne réagit que si `remote_ref = refs/heads/$FACTORY_MAIN_BRANCH`).

> **Limite de preuve, déclarée honnêtement** : la **branche de refus** (`main`) **n'a pas été
> exercée** — interdiction explicite du brief, et sur ce dépôt un push direct sur `main`
> **réussirait** côté serveur. Le refus n'est donc établi ici que par **lecture du code**, pas par
> exécution. C'est exactement la nature du sujet de cette US : le seul rempart est **local** et
> **non prouvé côté plateforme**.

## 3. Pull Request #10

- Gabarit trouvé et respecté : `.github/pull_request_template.md`.
- Corps rédigé pour énoncer **ce que l'US livre** et **ce qu'elle ne livre pas** ; **aucune
  formulation n'y affirme que `main` est ou devient protégée**.
- État à l'ouverture : `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, `reviewDecision: ""`.

> `CLEAN` **ne signifie pas** « checks requis satisfaits » : il signifie « rien ne bloque ».
> **Aucun check n'était requis** — la PR était fusionnable **même en rouge**. La lecture manuelle
> des checks était donc le **seul** contrôle réel. C'est la thèse de l'US, vérifiée sur sa propre PR.

## 4. Status checks — lus, non supposés

### 4.1 `gh pr checks 10` (sortie brute, état final)

```
🔐 Secrets scan (gitleaks)	pass	11s	https://github.com/gitgdx/Concentration/actions/runs/30268876665/job/89986180532
📱 App (gates run_gates.py)	pass	1m54s	https://github.com/gitgdx/Concentration/actions/runs/30268876665/job/89986180610
check-branch-name	pass	3s	https://github.com/gitgdx/Concentration/actions/runs/30266827316/job/89979403409
check-branch-name	pass	4s	https://github.com/gitgdx/Concentration/actions/runs/30268876620/job/89986180295
📋 Governance (SCB + traçabilité + synchro)	pass	9s	https://github.com/gitgdx/Concentration/actions/runs/30268876665/job/89986180459
```

`gh pr checks 10 --watch --interval 20` → **exit 0** (toutes complétions atteintes).

### 4.2 `gh api repos/gitgdx/Concentration/commits/e81eff8…/check-runs`

Réponse brute archivée dans **`reports/US-00.4/pr_checks.json`**. Dépouillement :

```
total_count = 5
 - '📱 App (gates run_gates.py)'                    | status= completed | conclusion= success
 - '🔐 Secrets scan (gitleaks)'                     | status= completed | conclusion= success
 - '📋 Governance (SCB + traçabilité + synchro)'    | status= completed | conclusion= success
 - 'check-branch-name'                             | status= completed | conclusion= success
 - 'check-branch-name'                             | status= completed | conclusion= success
```

**4/4 libellés attendus présents à l'identique**, tous `success`. Aucun `failure`, aucun `skipped`,
aucun `neutral`, aucun check jamais rapporté. **Condition d'arrêt levée → merge autorisé.**

### 4.3 Point de vigilance `check-branch-name` — levé

`check-branch-name` provient de `branch-naming.yml` (autre workflow). Il est **bien rapporté à
l'ouverture de la PR, sans nouveau commit**, et même **deux fois** sur le même sha :

| Run | Événement déclencheur | Conclusion |
|---|---|---|
| `30266827316` | `push` (`branches-ignore: [main]`) | `pass` (3s) |
| `30268876620` | `pull_request` (`types: [opened, …]`) | `pass` (4s) |

D'où `total_count = 5` pour **4** libellés distincts. Aucune anomalie.

## 5. Merge

```
gh pr merge 10 --merge  →  MERGE_EXIT=0
state: MERGED · mergeCommit.oid: 15121d8f4e471588081eed0fe91274c86ba5c3bb
mergedAt: 2026-07-27T13:15:45Z · mergedBy: gitgdx
git log -1 15121d8 → parents = 801a046 e81eff8   (commit de fusion, conforme au précédent PR #8/#9)
```

Branche `feat/US-00.4-ci-protection-branche` **conservée** (aucune suppression).

## 6. Synchronisation locale de `main`

**Piège du dépôt confirmé** : `main` local était **sans upstream** et resté à `801a046` ; le
`--ff-only` explicite était bien nécessaire.

```
git fetch origin        → 801a046..15121d8  main -> origin/main
git checkout main       → Switched to branch 'main'   (sha après checkout : 801a046)
git merge --ff-only origin/main → Updating 801a046..15121d8 / Fast-forward
                                  46 files changed, 7686 insertions(+), 60 deletions(-)
git rev-parse HEAD      → 15121d8f4e471588081eed0fe91274c86ba5c3bb
```

**Incident mineur rencontré et résolu sans forçage** : le premier `git checkout main` a été refusé
(`Your local changes to … docs/trace/US-00.4/events.jsonl would be overwritten`). Diagnostic mené
avant toute action : le blob committé est **identique** sur `e81eff8` et `origin/main`
(`3d9569e65d810d00a2dd5a14fcb3cff30c47e10f`) — le refus venait d'une **normalisation de fins de
ligne en attente** (`LF will be replaced by CRLF`), qui oblige git à réécrire le fichier. Résolution :
`git stash push -- docs/trace/US-00.4/events.jsonl` → checkout → `--ff-only` → `git stash pop`
(exit 0, sans conflit). Trace intègre après restauration : **15 événements**.

## 7. Health-check post-déploiement

### 7.1 CI sur `main` (déclenchée par la fusion, `push: branches: [main]`)

```
run 30269458325  sha 15121d8  event=push  →  conclusion: success
 - 📱 App (gates run_gates.py)                  | completed | success
 - 📋 Governance (SCB + traçabilité + synchro)  | completed | success
 - 🔐 Secrets scan (gitleaks)                   | completed | success
```

### 7.2 Contrôles locaux sur `main` à jour

| Contrôle | Résultat |
|---|---|
| `python scripts/check_scb_compliance.py` | `SCB conforme — Aucune violation détectée.` |
| `python scripts/validate_trace.py --us US-00.4` | `Traçabilité conforme.` |
| `python scripts/factory_sync.py --check` | `Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (…)` + `[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici` |
| Outillage présent sur `main` | `scripts/check_branch_protection.py`, `docs/adr/ADR-006-protection-branche-principale.md` |

**Le livrable central de l'US est constaté actif en production** : `factory_sync.py --check`, qui
affichait auparavant « Synchro factory conforme (env, **protection**, …) » sans jamais contacter
l'API, **annonce désormais explicitement son caractère DOCUMENTAIRE** et avertit que l'état réel
n'est pas vérifié. L'angle mort de fausse confiance est fermé.

**Health-check : VERT.**

## 8. Plan de retour

Version stable précédente : **`801a046`**. Retour arrière = `git revert -m 1 15121d8` via une PR
dédiée (jamais de push direct sur `main`). Aucun état runtime, aucune migration de schéma, aucune
donnée à restaurer : le retour est purement documentaire et immédiat.

## 9. Événements tracés (`docs/trace/US-00.4/events.jsonl`)

| Ordre | Événement | Agent | Note |
|---|---|---|---|
| 13 | `EVT_READY_FOR_DEPLOY` | `devops` | **Écart tracé** : le catalogue déclare `emitter: architect` (précédent US-00.1/00.2/00.3 = `architect`). Émis ici par `devops` sur instruction de l'orchestrateur relayant l'autorisation humaine. À confirmer ou rectifier par @Architect. |
| 14 | `EVT_STAGING_DEPLOYED` | `devops` | **N/A justifié** — aucun runtime ; validation pré-prod équivalente = CI verte sur la PR #10. |
| 15 | `EVT_DEPLOYMENT_SUCCESS` | `devops` | Déploiement = merge sur `main` ; health-check vert. |

`EVT_CERTIFIED_PROD` **non émis** — la certification relève du rituel `/certify` (@Architect).

## 10. Hors périmètre de ce déploiement (à la charge de l'orchestrateur / @Architect)

- **SCB** colonne `Déploiement (DevOps)` → `🚀 DEPLOYED` : **non modifiée** par @DevOps (consigne
  explicite du brief). Reste à `⏳`.
- **`PROJECT_LOG.md`** : **non modifié** (consigne explicite du brief).
- Dettes ouvertes rappelées dans la PR : **NB-1** (correctif 1 ligne,
  `MAPPED_TOP_KEYS & set(expected)`), **`selftest` en CI**, **transmission US-00.5** (1 fausse
  affirmation résiduelle famille S11 ; `CLAUDE.md` règle 2 et Constitution Art. 4 encore faux),
  **ADR-006** à remplacer/amender.
