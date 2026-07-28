# RE-AUDIT sécurité — US-00.7 (application de la protection de branche)

| | |
|---|---|
| **US** | US-00.7 — application de la protection de la branche `main` |
| **Agent** | @CyberSecurity — **contexte frais** (Constitution Art. 2), 2ᵉ cycle |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-07-28 |
| **Objet** | Vérifier ou **réfuter** le correctif `9465116` du bloquant **B-1** (HIGH) du 1ᵉʳ cycle |
| **Cycle 1** | `reports/US-00.7/security.md` — ❌ FAILED (1 bloquant HIGH). ⛔ **Non écrasé** |
| **HEAD** | `9465116` · branche `feat/US-00.7-certif` · `main` = `9fdb7fd` |

> **Méthode.** Rien n'est repris sur parole — ni du 1ᵉʳ audit, ni de l'orchestrateur. Les plages de
> diff ont été **recalculées**, l'empreinte SHA256 **recalculée**, et le correctif validé par **deux
> outils non-LLM indépendants** (`actionlint`, `zizmor`) plus des **contrôles négatifs**. Un contrôle
> négatif de ma propre main s'est révélé **invalide** ; il est rapporté et refait (§1.7, §2.4).

## VERDICT : ✅ **PASSED**

**0 bloquant.** Le correctif est **réel, vérifié par l'effet, et plus complet que le finding auquel
il répond**. Le step `actionlint`, audité **comme du code neuf**, est **sain** : empreinte **exacte**
(3 sources indépendantes), vérification **réellement fail-closed** (prouvée par contrôle négatif),
ordre **vérifier → extraire → exécuter** respecté, **aucun** contenu non vérifié exécuté, **aucun**
cache introduit. C'est un **progrès net**, pas un déplacement de risque.

**5 findings nouveaux** que mon indépendance ajoute (2 MEDIUM structurels, 1 MEDIUM plateforme,
2 LOW) — **aucun bloquant**, tous **pré-existants ou non exploitables**. Les 4 MEDIUM et 4 LOW du
cycle 1 sont **vérifiés ouverts, non traités, et aucun n'est aggravé**.

---

## 1. Sorties d'outils (brutes, réelles)

### 1.1 Périmètre du diff — recalculé, non repris sur parole

```
$ git merge-base main HEAD
9fdb7fd4fdecea5f7d102533843a932cb46a8338

$ git diff main...HEAD --stat | tail -1
 12 files changed, 1454 insertions(+), 25 deletions(-)     <-- TROMPEUR (branche post-fusion)

$ git diff f4400ca..HEAD --stat | tail -1
 50 files changed, 8280 insertions(+), 259 deletions(-)    <-- PERIMETRE REEL de l'US

$ git show 9465116 --name-only --format=""                 <-- LE CORRECTIF
.github/workflows/branch-naming.yml
.github/workflows/ci.yml
CLAUDE.md
PROJECT_LOG.md
STORY_CERTIFICATION_BOARD.md
docs/trace/US-00.7/events.jsonl
```

✅ Les deux plages annoncées sont **confirmées**. Le correctif ne touche **aucun script**, **aucune
configuration** : 2 workflows + 4 fichiers documentaires/trace.

### 1.2 `python scripts/run_gates.py --gate sast` → **le gate n'existe toujours pas**

```
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
=== EXIT: 1 ===
```

Constat du cycle 1 **reproduit à l'identique**. Voir N-4 : `actionlint` **compense partiellement**
(workflows), mais il n'existe toujours **aucun gate `sast`** ni SAST sur `scripts/**` / `lib/**`.

### 1.3 `python scripts/run_gates.py --gate deps_audit`

```
▶ app.deps_audit — (.) $ dart pub outdated --show-all
direct dependencies:
cupertino_icons               1.0.9     1.0.9       1.0.9       1.0.9
flutter                       (sdk)     (sdk)       (sdk)       (sdk)
dev_dependencies:
flutter_lints                 6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                  (sdk)     (sdk)       (sdk)       (sdk)
transitive dependencies (retards) : meta *1.18.0 · vector_math *2.2.0 · matcher *0.12.19 · test_api *0.7.11
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
=== EXIT: 0 ===
```

**Aucune CVE HIGH/CRITICAL sur dépendance directe.** ⚠️ **Justification exigée par mon mandat** :
`dart pub outdated` mesure l'**obsolescence**, **pas** la vulnérabilité — il ne consulte **aucune
base d'avis**. **Aucun PASS n'est donc prononcé sur la foi d'un scan de CVE : il n'y en a pas.** Les
2 dépendances directes sont à jour ; les 4 retards sont **transitifs et contraints par le SDK**
(colonne `Resolvable` = version courante), non actionnables. Ce gate est `"blocking": false`.

### 1.4 `gitleaks` 8.30.1 — arbre, historique, et commit correctif isolé

```
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~120195018 bytes (120.20 MB) in 5.71s
INF no leaks found                                        === EXIT: 0 ===

$ gitleaks detect --source . --config .gitleaks.toml --redact -v      (historique)
INF 49 commits scanned.
INF scanned ~2130640 bytes (2.13 MB) in 3.89s
INF no leaks found                                        === EXIT: 0 ===

$ gitleaks detect --source . --config .gitleaks.toml --redact --log-opts "0194078..9465116" -v
INF 1 commits scanned.
INF no leaks found                                        === EXIT: 0 ===
```

> **Borne de méthode, reprise et re-vérifiée** : `git rev-list --count HEAD` = **64**, gitleaks
> annonce **49**. L'écart = les **commits de fusion**, dont `git log -p` n'émet pas le diff. Un
> « evil merge » y échapperait. Couverture non totale — aucun indice de présence.

Balayage manuel de 14 motifs sensibles sur le diff `.github/` du correctif → **exit grep = 1, zéro
occurrence**.

### 1.5 `actionlint` 1.7.12 — validation croisée AVANT / APRÈS (outil non-LLM n° 1)

Binaire téléchargé et **vérifié** par mes soins (§2.1).

```
$ actionlint            # sur l'ETAT AVANT CORRECTIF (0194078)
.github\workflows\branch-naming.yml:14:85: "github.head_ref" is potentially untrusted.
  avoid using it directly in inline scripts. instead, pass it through an environment variable.
  [expression]
=== EXIT: 1 ===

$ actionlint            # sur HEAD = 9465116
=== EXIT: 0 ===
```

### 1.6 `zizmor` 1.28.0 — second outil indépendant (non-LLM n° 2)

```
$ zizmor --offline --persona=regular <PREFIX>/.github/workflows/     # AVANT correctif
error[template-injection]: code injection via template expansion
  --> branch-naming.yml:16:25
16 |             BRANCH="${{ github.head_ref }}"
   |                         ^^^^^^^^^^^^^^^ may expand into attacker-controllable code

error[template-injection]: code injection via template expansion
  --> branch-naming.yml:18:25
18 |             BRANCH="${{ github.ref_name }}"
   |                         ^^^^^^^^^^^^^^^ may expand into attacker-controllable code

26 findings (7 suppressed): 0 informational, 0 low, 9 medium, 10 high
```

```
$ zizmor --offline --persona=regular .github/workflows/              # HEAD = 9465116
findings "template-injection" : 0
23 findings (6 suppressed): 0 informational, 0 low, 9 medium, 8 high
   8 error[unpinned-uses]        (pré-existants — voir §4)
   5 warning[excessive-permissions]
   4 warning[artipacked]
```

🟢 **Point que le cycle 1 avait manqué et que le correctif traite quand même** : `zizmor` relève
**DEUX** injections avant correctif — `github.head_ref` **et** `github.ref_name` (ancienne ligne 18,
chemin `push`). Le cycle 1 n'avait nommé que `head_ref`. **Le correctif ferme les deux.** Il est donc
**plus complet que le finding auquel il répond** — HIGH passe de **10 → 8**, les 8 restants étant
tous du `unpinned-uses` pré-existant.

### 1.7 État réel de la plateforme (GET uniquement — aucune écriture émise par ce re-audit)

```
$ gh api repos/gitgdx/Concentration/branches/main/protection --jq '{...}'
{"admins":true,
 "checks":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
           "check-branch-name","📱 App (gates run_gates.py)"],
 "del":false,"force":false,"reviews":0,"strict":true}

$ gh api repos/gitgdx/Concentration/actions/permissions/workflow
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}

$ gh api repos/gitgdx/Concentration --jq '{visibility,allow_forking,private}'
{"allow_forking":true,"private":false,"visibility":"public"}

$ gh api repos/gitgdx/Concentration/actions/permissions/fork-pr-contributor-approval
{"approval_policy":"first_time_contributors"}          <-- NON relevé par le cycle 1
```

### 1.8 Simulation locale du job **requis** `governance` (les 3 steps python)

```
$ python scripts/check_scb_compliance.py   -> SCB conforme — Aucune violation détectée.   exit=0
$ python scripts/validate_trace.py --all   -> Traçabilité conforme.                       exit=0
$ python scripts/factory_sync.py --check   -> Synchro factory conforme — vérification
     DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs, seuils).
     [AVERTISSEMENT] l'état RÉEL de la protection n'est PAS vérifié ici                   exit=0
```

✅ L'ajout du step `actionlint` **ne casse pas** la synchro des libellés : les 4 contextes requis
restent alignés.

### 1.9 Contrôle négatif exigé par le corpus

```
$ grep -rn "check-remote" .github/workflows/
--- fin (vide=OK, exit grep=1) ---
```

✅ Le nouveau commentaire de `ci.yml` évite délibérément le littéral (« la commande de comparaison
distante documentée dans `docs/GIT_PROTECTION.md` ») — la régression du cycle précédent **n'est pas
réintroduite**.

### 1.10 NB-1bis — fixtures rejouées par mes soins (MED-3 toujours ouvert ?)

```
$ python tests/fixtures/US-00.7/nb1_harness.py
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S)
              non couvert(s) […] : enforce_admins = {"enabled": true}
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 2
```

✅ Le correctif NB-1 fonctionne toujours ; NB-1bis reste **ouvert** — inchangé, non aggravé.

---

## 2. Revendication n° 1 — **B-1 est-il réellement neutralisé ?** → ✅ **OUI**

### 2.1 Lecture du code

`.github/workflows/branch-naming.yml:28-37` — les valeurs passent par `env:` puis sont lues comme des
**variables shell** :

```yaml
        env:
          EVENT_NAME: ${{ github.event_name }}
          HEAD_REF:   ${{ github.head_ref }}
          REF_NAME:   ${{ github.ref_name }}
        run: |
          if [ "$EVENT_NAME" = "pull_request" ]; then
            BRANCH="$HEAD_REF"
```

**Aucune** interpolation `${{ }}` ne subsiste dans un corps de `run:` — vérifié par énumération
exhaustive (§3).

### 2.2 Job id `check-branch-name` — **inchangé** (le contexte requis n'est pas cassé)

```
$ git show f4400ca:.github/workflows/branch-naming.yml | grep -E "^  [a-z-]+:"
  check-branch-name:
$ git show HEAD:.github/workflows/branch-naming.yml     | grep -E "^  [a-z-]+:"
  check-branch-name:

$ git diff f4400ca..HEAD -- .github/workflows/ci.yml | grep -E "^[+-].*name:"
+# ⛔ NE JAMAIS MODIFIER un `name:` de job de ce fichier sans mettre à jour factory.config.json
+      - name: 🔎 Lint des workflows (actionlint, épinglé par SHA256)
```

✅ Le job n'a **pas** de clé `name:`, donc son contexte **est** son id : `check-branch-name`. Seul un
**nom de step** a été ajouté. **Aucun `name:` de job n'a bougé** → pas de risque de verrouillage par
libellé divergent. Confirmé par `factory_sync.py --check` exit 0 (§1.8) et par l'état API (§1.7).

### 2.3 **Preuve par l'effet** — 4 charges rejouées par mes soins

Corps du `run:` corrigé extrait verbatim dans un fichier, exécuté avec `EVENT_NAME=pull_request` :

```
HEAD_REF='feat/US-1.1-$(id -un)'   -> Checking branch: feat/US-1.1-$(id -un)      exit=0  LITTERAL
HEAD_REF='feat/US-1.1-`id -un`'    -> Checking branch: feat/US-1.1-`id -un`       exit=0  LITTERAL
HEAD_REF='feat/US-1.1-";id -un;"'  -> Checking branch: feat/US-1.1-";id -un;"     exit=0  LITTERAL
HEAD_REF='*'                       -> KO Branch name '*' is NOT compliant!        exit=1  (glob non étendu)

RAPPEL — comportement AVANT correctif (interpolation textuelle) :
$ bash -c "BRANCH=\"feat/US-1.1-\$(id -un)\"; echo \"Checking branch: \$BRANCH\""
Checking branch: feat/US-1.1-guillaume.decroix          <-- la commande était EXECUTEE
```

⛔ **Aucune branche, aucune PR n'a été créée** : tout est resté local et inoffensif.

**Analyse résiduelle du script corrigé** — trois sinks examinés, tous sains :
- `[[ "$BRANCH" =~ $PATTERN ]]` : `$BRANCH` **quoté** → traité comme littéral ; `$PATTERN` non quoté
  (correct pour une regex) mais c'est un **littéral fixe**, non influençable.
- `echo "Checking branch: $BRANCH"` : pas d'injection de **commande de workflow** (`::set-env::`,
  `::add-mask::`) — celles-ci doivent commencer une ligne, or le texte est **préfixé**, et
  `git check-ref-format` **interdit les caractères de contrôle**, donc pas de retour à la ligne
  injectable dans un nom de branche.
- Pas d'écriture vers `$GITHUB_ENV` / `$GITHUB_OUTPUT` / `$GITHUB_PATH`.

### 2.4 Le motif subsiste-t-il **ailleurs** ? (le cycle 1 n'avait examiné qu'un fichier)

Le cycle 1 n'a jamais mentionné **`e2e.yml`**. Je l'ai lu et audité. Énumération **exhaustive** des
interpolations sur **les 3** workflows :

```
$ grep -rnoE '\$\{\{[^}]*\}\}' .github/workflows/ | sort | uniq -c
      1 ci.yml:59:           ${{ secrets.GITHUB_TOKEN }}   -> env: d'une action, usage normal
      1 ci.yml:38:           ${{ github.ref }}             -> clé concurrency:, PAS un run:
      1 branch-naming.yml:31:${{ github.ref_name }}        -> bloc env:  ✅
      1 branch-naming.yml:30:${{ github.head_ref }}        -> bloc env:  ✅
      1 branch-naming.yml:29:${{ github.event_name }}      -> bloc env:  ✅
      1 branch-naming.yml:17:${{ }}                        -> commentaire

$ grep -rn "pull_request_target" .github/      -> (vide, exit 1)
```

✅ **`e2e.yml` ne contient AUCUNE interpolation.** ✅ `ci.yml:38` — `github.ref` vaut
`refs/pull/N/merge` sur une PR : **non contrôlable** par l'attaquant, et c'est une clé
`concurrency:`, **pas** un corps de `run:`. ✅ **Aucun `pull_request_target`** → le vecteur « pwn
request » reste **absent**. Corroboré indépendamment par `zizmor` : **0 `template-injection`**
sur l'ensemble des 3 workflows (§1.6).

**Conclusion revendication 1 : VÉRIFIÉE, et au-delà** (le chemin `ref_name` est fermé lui aussi).

---

## 3. Revendication n° 2 — le step `actionlint`, **audité comme du code neuf**

### 3.1 L'empreinte SHA256 codée en dur est-elle **la bonne** ? → ✅ **OUI** (3 sources)

`SHA256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8`

```
(1) MON PROPRE TELECHARGEMENT + sha256sum
$ curl -fsSL -o actionlint_1.7.12_linux_amd64.tar.gz \
    "https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz"
$ sha256sum actionlint_1.7.12_linux_amd64.tar.gz
8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8 *actionlint_1.7.12_linux_amd64.tar.gz

(2) FICHIER DE CHECKSUMS OFFICIEL DE LA RELEASE
$ curl -fsSL ".../v1.7.12/actionlint_1.7.12_checksums.txt" | grep linux_amd64
8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8  actionlint_1.7.12_linux_amd64.tar.gz

(3) DIGEST COTE API GITHUB (source indépendante du CDN de téléchargement)
$ gh/curl api.github.com/repos/rhysd/actionlint/releases/tags/v1.7.12
tag: v1.7.12 | published: 2026-03-30T17:49:21Z | draft: False | prerelease: False
actionlint_1.7.12_linux_amd64.tar.gz | size: 2353908 |
  digest: sha256:8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
```

✅ **Concordance parfaite sur les 3.** Release **publiée**, ni *draft* ni *prerelease*.

### 3.2 La vérification échoue-t-elle **réellement** si l'asset change ? → ✅ **OUI, fail-closed**

> ⚠️ **Incident de méthode, consigné plutôt que masqué.** Mon **premier** contrôle négatif, écrit
> avec des **sous-shells en ligne** `( set -euo pipefail; … )`, a affiché
> `!!! LA SUITE S EST EXECUTEE MALGRE L ECHEC !!!` et `EXIT B=0` — ce qui aurait signifié que la
> vérification est **décorative**. **C'était un artefact de mon propre harnais**, pas un défaut du
> code audité. Je l'ai refait avec de **vrais fichiers de script**, ce qui est aussi **exactement**
> la façon dont Actions exécute un `run:` (corps écrit dans un fichier temporaire, lancé par
> `bash -e {0}`). Résultat authentique ci-dessous. Un contrôle négatif qui contredit le résultat
> attendu doit être **re-vérifié avant d'être publié** — c'est ici la doctrine de la factory
> appliquée à l'auditeur lui-même.

```
=== CTRL B : empreinte FALSIFIEE (asset remplacé en amont) ===
$ bash bad.sh          # set -euo pipefail ; SHA256=deadbeef… ; echo … | sha256sum -c - ; tar … ; echo …
actionlint.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
EXIT=1
  -> "### LIGNE APRES LA VERIFICATION — NE DOIT JAMAIS S AFFICHER ###"  N'A PAS ETE AFFICHEE
  -> `tar` N'A PAS ETE EXECUTE, le binaire N'A PAS ETE EXTRAIT

=== validation du harnais (set -e réellement honoré dans un fichier) ===
$ printf 'set -euo pipefail\nfalse\necho "APRES false"\n' > min.sh ; bash min.sh
EXIT min=1        ("APRES false" non affiché)
```

✅ **Un asset remplacé arrête la CI avant toute exécution.** L'ordre est **correct** :
`curl` → `sha256sum -c` → `tar` → `./actionlint`. **Aucun contenu non vérifié n'est jamais exécuté.**
`pipefail` est **nécessaire et présent** pour le pipeline `echo … | sha256sum -c -`.

### 3.3 Que se passe-t-il si le téléchargement échoue ? → fail-closed, **mais couplage réel** (N-1)

```
=== CTRL C : asset indisponible (404) ===
$ bash dl.sh          # set -euo pipefail ; curl -fsSL -o … <URL inexistante> ; echo "### NE DOIT JAMAIS S AFFICHER ###"
curl: (22) The requested URL returned error: 404
EXIT=22               ("### NE DOIT JAMAIS S AFFICHER ###" non affiché)
```

✅ Sûr (`-f` + `set -e`). ⚠️ Mais **le job requis échoue** → voir **N-1** (§5) pour la conséquence de
disponibilité, qui est le seul vrai reproche que j'adresse à ce step.

### 3.4 `set -euo pipefail` protège-t-il **tout** le chemin ? → ✅ OUI, avec 2 réserves mineures

| Ligne | Protection | Verdict |
|---|---|---|
| `VERSION=` / `SHA256=` | — | littéraux |
| `curl -fsSL -o …` | `-f` (échec HTTP) + `set -e` | ✅ prouvé §3.3 |
| `echo … \| sha256sum -c -` | `pipefail` + `set -e` | ✅ prouvé §3.2 |
| `tar -xzf … actionlint` | s'exécute **après** vérification | ✅ ordre correct |
| `./actionlint -color` | binaire **vérifié** | ✅ |
| `rm -f …` | non atteint si le lint échoue | sans effet (runner éphémère) |

- `set -u` : **aucune** variable non définie utilisée. ✅
- Shell par défaut d'Actions = `bash -e {0}` → `set -euo pipefail` est **additif**, pas contradictoire. ✅
- Réserves mineures (N-5) : pas de `--max-time` / `--retry` / `--proto '=https'` sur `curl`.
- Mode stocké dans l'archive vérifié : `-rwxr-xr-x runner/runner … actionlint` → `./actionlint`
  **sera exécutable** sur le runner Linux. Chemin nominal rejoué verbatim :
  `actionlint.tar.gz: OK` puis `actionlint: ELF 64-bit LSB executable, x86-64, statically linked`.

### 3.5 Risque de **cache poisoning** ou d'exécution de contenu non vérifié ? → ❌ **AUCUN AJOUTÉ**

- Le step n'utilise **aucun** `actions/cache` : téléchargement **frais à chaque exécution**, rien
  n'est mis en cache ni relu depuis un cache. **Aucune surface de cache-poisoning n'est créée.**
- Rien de non vérifié n'est exécuté (§3.2).
- Le step **n'ajoute aucune permission** : `governance` n'a pas de bloc `permissions:` et hérite du
  défaut du dépôt, **vérifié en réel** : `default_workflow_permissions: "read"` (§1.7).
- 🟢 **Le cycle 1 signalait le cache-poisoning comme impact résiduel de B-1** (pivot possible vers le
  cache partagé de `flutter-action`, check requis). **B-1 étant fermé, ce pivot est fermé aussi.**

### 3.6 Divergence local ↔ runner : `shellcheck` — **risque identifié par moi, puis clos**

`actionlint` invoque **automatiquement `shellcheck`** sur chaque corps de `run:` si le binaire est
présent. **`shellcheck` est absent de mon poste — et pré-installé sur `ubuntu-latest`.** Toutes les
validations locales (celle du développeur comme mon §1.5) ont donc tourné **sans** cette intégration.
Si `shellcheck` remontait un problème, le job **requis** `governance` serait **ROUGE sur chaque PR**.
La revendication « exit 0 » était donc **non concluante pour l'environnement cible**.

J'ai téléchargé `shellcheck` 0.10.0 et **d'abord prouvé que l'intégration est réellement active**
(sinon un exit 0 ne prouve rien) :

```
=== CONTROLE NEGATIF sur un workflow volontairement fautif ===
A) actionlint -shellcheck ""                 -> EXIT A=0   (intégration désactivée : rien vu)
B) actionlint -shellcheck <shellcheck.exe>   -> EXIT B=1
   ctl.yml:7:9: shellcheck reported issue …: SC2086:info … Double quote to prevent globbing
   ctl.yml:7:9: shellcheck reported issue …: SC2115:warning … Use "${var:?}" …
   -> l'intégration shellcheck EST vivante dans mon harnais
```

```
=== FINAL : actionlint 1.7.12 + shellcheck 0.10.0 (configuration d'ubuntu-latest) sur HEAD=9465116 ===
=== EXIT: 0 ===
```

✅ **Risque de verrouillage par `shellcheck` : écarté empiriquement.** Vérifié aussi : aucun fichier
`.github/actionlint.yaml` / `.actionlint.yaml` ne vient assouplir la configuration.

### 3.7 **Progrès net ou déplacement de risque ?** → **progrès net**, avec un couplage assumé

| Axe | Avant | Après | Bilan |
|---|---|---|---|
| Détection d'injection dans un contexte **requis** | ❌ aucune | ✅ `actionlint` bloque `governance` | **+** décisif |
| Choix step vs job séparé | — | **step** d'un job **déjà requis** | **+** correct : un job neuf ne serait pas un contexte requis (4 figés, Art. 6) → rapporté **sans bloquer** |
| Épinglage de la nouvelle dépendance | — | version **+ SHA256** vérifiée | **+** la dépendance la **plus rigoureuse** du dépôt |
| Chaîne d'approvisionnement | 4 actions par tag mutable + `pip install jsonschema` nu | **inchangé** | **=** MED-4 non résolue, **non aggravée** |
| Disponibilité du chemin critique | 4 tiers déjà requis | **+1 tiers** (épinglé) | **−** marginal → **N-1** |

Le step est **strictement plus rigoureux** que le `pip install jsonschema` **nu** qui le suit dans le
**même job requis** (N-2). Le reproche de « dépendance tierce dans un contexte requis » est donc
**réel mais non spécifique** : il vaut déjà, et plus fort, pour du code **pré-existant**.

**Conclusion revendication 2 : le step est SAIN. Non bloquant.**

---

## 4. Revendication n° 3 — les MEDIUM/LOW du cycle 1 sont-ils **ouverts et non aggravés** ? → ✅ **EXACT**

Contrôle mécanique (`git diff --quiet 0194078 HEAD -- <fichier>`) :

```
scripts/factory_sync.py                    INCHANGE
scripts/check_branch_protection.py         INCHANGE
scripts/trace_append.py                    INCHANGE
scripts/events_catalog.json                INCHANGE
.gitleaks.toml                             INCHANGE
factory.config.json                        INCHANGE
```

| Cycle 1 | Statut vérifié | Preuve |
|---|---|---|
| MED-2 — pas de plancher de sécurité | **OUVERT, non aggravé** | `factory_sync.py` inchangé |
| MED-3 — NB-1bis | **OUVERT, non aggravé** | fixtures rejouées §1.10 (exit 2) ; `check_branch_protection.py` inchangé |
| MED-4 — actions tierces non épinglées | **OUVERT, non aggravé** | 8 `unpinned-uses` (§1.6) ; `git diff f4400ca..HEAD -- .github/workflows/ \| grep "uses:"` → **VIDE** |
| MED-5 — `emitter` non enforcé | **OUVERT, non aggravé** | `events_catalog.json` + `trace_append.py` inchangés |
| LOW-6 — allowlist `.env` gitleaks | **OUVERT, non aggravé** | `.gitleaks.toml` inchangé |
| LOW-7 — divulgation de posture | **ACCEPTÉ** (inchangé) | — |
| LOW-8 — `Authorization` sur redirection | **OUVERT, non aggravé** | `check_branch_protection.py` inchangé |
| LOW-9 — aucun SAST | **PARTIELLEMENT TRAITÉ** | `actionlint` ajouté ; mais `--gate sast` → **exit 1** (§1.2), toujours aucun SAST sur `scripts/**` / `lib/**` |

✅ **Aucun finding n'a été aggravé. Aucun n'a été silencieusement refermé.** La déclaration
d'ouverture portée par le SCB et `CLAUDE.md` est **exacte**.

### Justification exigée : pourquoi les **8 HIGH de `zizmor` ne sont pas bloquants**

Mon mandat impose `FAILED` sur un « finding SAST de sévérité HIGH ». `zizmor` en rapporte **8**
(`unpinned-uses`). Je **ne bloque pas**, et je le motive :

1. **`unpinned-uses` est une *blanket policy*** de durcissement (elle vise **toute** action non
   épinglée par SHA, y compris `actions/checkout@v4` **first-party**) — ce n'est pas un défaut
   exploitable constaté, c'est un écart à une politique optionnelle.
2. **Tous sont strictement PRÉ-EXISTANTS** : `git diff f4400ca..HEAD -- .github/workflows/` filtré sur
   `uses:` et `permissions:` → **VIDE**. Ni l'US ni le correctif n'ont ajouté ou modifié une seule
   action tierce. La seule dépendance **ajoutée** (actionlint) est **épinglée par empreinte** — donc
   plus stricte que la politique.
3. Le cycle 1 les a classés **MEDIUM (MED-4)** en toute connaissance de cause. Bloquer aujourd'hui sur
   un élément **inchangé** que le cycle précédent a consciemment jugé non bloquant serait
   **incohérent** et sanctionnerait le correctif pour un défaut qu'il ne touche pas.

Je les maintiens donc en **MEDIUM**, **ouverts**, et je réitère la recommandation d'épinglage par SHA.
De même, les **5 `excessive-permissions`** de `zizmor` sont **atténués en fait** : l'outil tourne
`--offline` et ne peut pas voir le réglage du dépôt, or j'ai vérifié en réel
`default_workflow_permissions: "read"` (§1.7). Les **4 `artipacked`** sont de confiance **basse** et
pré-existants.

---

## 5. Findings **nouveaux** que ce re-audit ajoute

### 🟠 N-1 — MEDIUM — Interblocage de disponibilité : le plan de retour arrière **s'interdit lui-même** sur ce cas

**Fichier** : `.github/workflows/ci.yml:76-86` + `docs/GIT_PROTECTION.md` §Plan de retour arrière.

Si l'asset `actionlint` devient indisponible (release supprimée, dépôt amont retiré, incident CDN),
le step échoue (§3.3) → le contexte **requis** `📋 Governance` passe en **`FAILURE`** sur **toute** PR.
**Corriger exige de modifier `ci.yml` → donc de fusionner une PR → donc que `governance` soit vert →
donc que le téléchargement fonctionne. C'est circulaire.** `enforce_admins: true` interdit le bypass.

**Ce qui rend ce finding spécifique — et non une redite :** la taxonomie du plan de retour arrière
distingue `EXPECTED` (= verrouillage, appliquer le plan) de `FAILURE` (= « corriger la cause, **pas la
règle** »), et écrit noir sur blanc :

> « Appliquer ce plan sur un `FAILURE` serait un contournement de gate. »

Or ce scénario produit un **`FAILURE` dont la cause est *hors du dépôt* et non corrigeable par une
PR**. **La seule porte de sortie documentée s'interdit explicitement d'être empruntée ici.** Le
tableau §1 du plan a besoin d'une **troisième ligne**.

**Pourquoi NON bloquant** : (a) **récupérable en pratique** — `enforce_admins` interdit de
*contourner*, pas d'*administrer* : `gh api -X DELETE …/branches/main/protection` reste ouvert à
l'administrateur ; (b) **classe de risque déjà présente** — `pip install jsonschema`,
`actions/checkout@v4`, `subosito/flutter-action@v2`, `gitleaks-action@v2` ont **exactement** la même
propriété, sans épinglage ; (c) probabilité faible ; (d) **auto-révélateur** au moment de la PR.
**Recommandation** : ajouter la 3ᵉ ligne au tableau du plan (« `FAILURE` d'origine externe non
corrigeable par PR → administrer »).

### 🟠 N-2 — MEDIUM — `pip install jsonschema` **nu** dans le job requis `governance` (pré-existant, manqué par le cycle 1)

**Fichier** : `.github/workflows/ci.yml:91` — `run: pip install jsonschema`

Aucune **version**, aucune **empreinte**, pas de `--require-hashes`, pas d'index épinglé. Une
compromission de PyPI ou une attaque de confusion de dépendance injecterait du code **dans un
contexte requis** de l'enforcement. **Strictement plus faible que le step `actionlint` qui le précède
dans le même job.** Pré-existant, **non aggravé** par le correctif, mais il rend le reproche
« actionlint télécharge depuis Internet » **non spécifique**. À traiter avec MED-4.

### 🟠 N-3 — MEDIUM (plateforme, informationnel) — Sur une PR de **fork**, la définition même des checks requis est fournie par l'attaquant

Pour un événement `pull_request`, GitHub exécute les workflows **du commit de fusion** — donc la
version des fichiers `.github/workflows/**` **apportée par la PR**. Un fork peut nommer sa branche
`feat/US-9.9-x` (motif satisfait) **et** réécrire `ci.yml` pour vider `governance`, `secrets-scan`
et `app-quality` tout en **conservant les libellés exacts** → **4/4 vert** sur une PR dont aucun gate
n'a réellement tourné.

Cela **qualifie** l'affirmation du cycle 1 (« les 4 checks sont désormais la seule barrière
substantielle ») : **la barrière est verte parce que l'attaquant l'a rendue verte.** Corollaire
direct : **l'épinglage SHA256 d'`actionlint` ne protège pas contre une PR de fork** qui modifie le
pin — il protège contre une altération **en amont**, ce qui reste sa valeur réelle.

**Pourquoi NON bloquant** : inhérent à **tout** dépôt public, **non introduit** par cette US ;
atténué par `approval_policy: "first_time_contributors"` (§1.7 — un contributeur externe inconnu ne
déclenche **aucun** workflow sans approbation manuelle), par le `GITHUB_TOKEN` en **lecture seule** et
l'absence de secrets ; et un fork **ne peut pas fusionner lui-même**. Le résidu est
l'**ingénierie sociale du mainteneur**, amplifiée par `required_approving_review_count: 0`.
**Recommandation** : inscrire dans `docs/GIT_PROTECTION.md` que « 4/4 vert » sur une PR de **fork**
n'atteste **pas** que les gates ont tourné — la revue du diff des workflows est obligatoire.

### 🟡 N-4 — LOW — L'épinglage d'`actionlint` va **rancir**

`VERSION=1.7.12` est figé sans mécanisme de mise à jour ni surveillance. Les règles ajoutées par les
versions ultérieures ne seront jamais appliquées. Épinglage = déterminisme (bon) **et** immobilisme.
À rattacher à la dette « `selftest` en CI ». *(À l'inverse, LOW-9 est **partiellement soldée** : c'est
`actionlint` qui empêchera désormais la régression de B-1.)*

### 🟡 N-5 — LOW — Le `ci.yml` corrigé **n'a jamais tourné** en CI, et `curl` n'a ni délai ni réessai

```
$ git status -sb | head -1        -> ## feat/US-00.7-certif      (aucun suivi distant)
$ git log --oneline origin/feat/US-00.7-certif -1
   -> pas de remote tracking pour cette branche
```

La branche **n'est pas poussée** : le step `actionlint` n'a **jamais** été exécuté par GitHub Actions.
Toute ma validation (§3) est une **simulation locale fidèle mais locale**. Selon la doctrine de la
factory (**preuve par l'effet** vs **inférence**), la borne doit être écrite : *le comportement en CI
est déduit, pas observé.* **Non bloquant** : le défaut serait **auto-révélé et fail-closed** dès la
première PR. S'y ajoute l'absence de `--max-time` / `--retry` sur `curl` : un réseau qui pend fait
traîner le job jusqu'au timeout au lieu d'échouer vite.

---

## 6. Tableau des findings

`[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

| # | Outil | Fichier:Ligne | Sév. | Décision |
|---|---|---|---|---|
| **B-1** | `actionlint` 1.7.12 + `zizmor` 1.28.0 + PoC | `.github/workflows/branch-naming.yml:28-37` | ~~HIGH~~ | ✅ **CORRIGÉ — vérifié par 3 moyens indépendants. Bloquant LEVÉ** |
| N-1 | Revue + CTRL C exécuté | `ci.yml:76-86` + `GIT_PROTECTION.md` §plan | MEDIUM | Nouveau — doc à compléter (3ᵉ ligne) |
| N-2 | Revue manuelle | `.github/workflows/ci.yml:91` | MEDIUM | Nouveau — pré-existant, à joindre à MED-4 |
| N-3 | Revue + API | `.github/workflows/**` (modèle `pull_request`) | MEDIUM | Nouveau — plateforme, à documenter |
| MED-2 | Revue manuelle | `scripts/factory_sync.py:60-77`, `:159-186` | MEDIUM | **Ouvert** — inchangé |
| MED-3 | Fixtures rejouées | `scripts/check_branch_protection.py:498-518` | MEDIUM | **Ouvert** — inchangé |
| MED-4 | `zizmor` (8 `unpinned-uses`) | `ci.yml:54,57,65,87,103,104` · `e2e.yml:19,20` | MEDIUM | **Ouvert** — pré-existant, **non aggravé** (downgrade motivé §4) |
| MED-5 | `grep` + revue | `scripts/events_catalog.json`, `trace_append.py:35,81` | MEDIUM | **Ouvert** — inchangé |
| N-4 | Revue manuelle | `.github/workflows/ci.yml:79` | LOW | Nouveau — dette d'entretien |
| N-5 | `git status` + revue | `ci.yml:76-86` / branche non poussée | LOW | Nouveau — borne de preuve à écrire |
| LOW-6 | Revue manuelle | `.gitleaks.toml:44` | LOW | **Ouvert** — inchangé |
| LOW-7 | Revue manuelle | `reports/US-00.7/applied_state/protection_applied.json` | LOW | Accepté |
| LOW-8 | Revue manuelle | `scripts/check_branch_protection.py:371-382` | LOW | **Ouvert** — inchangé |
| LOW-9 | `run_gates.py` | `factory.config.json` (gates) | LOW | **Partiellement traité** (`actionlint`) ; `--gate sast` toujours exit 1 |

| Sévérité | Nombre | Bloquants |
|---|---|---|
| CRITICAL | 0 | 0 |
| **HIGH** | **0** | **0** |
| MEDIUM | 7 (4 reportés + 3 nouveaux) | 0 |
| LOW | 6 (4 reportés + 2 nouveaux) | 0 |

**Bloquants numérotés : AUCUN.**

---

## 7. Ce que ce re-audit **corrige** du cycle 1

1. **Le cycle 1 n'a nommé qu'une injection ; il y en avait DEUX.** `zizmor` relève aussi
   `github.ref_name` (ancienne ligne 18, chemin `push`). Le correctif ferme les deux — il est **plus
   complet que le finding**.
2. **Le cycle 1 n'a jamais examiné `e2e.yml`.** Fait ici : **0 interpolation**, propre.
3. **Le cycle 1 a manqué `pip install jsonschema`** (N-2), plus faible que tout ce qu'il reprochait.
4. **Le cycle 1 n'avait pas relevé `approval_policy: "first_time_contributors"`**, qui **atténuait**
   réellement l'exploitabilité de B-1 par un attaquant **inconnu**. Cela ne change pas son verdict
   (un contributeur déjà fusionné, ou tout collaborateur via le trigger `push`, passait sans
   approbation) mais la posture méritait d'être citée.
5. **Le cycle 1 ne pouvait pas voir le risque `shellcheck`** (§3.6), créé par le correctif lui-même.
   Identifié ici, puis **clos empiriquement**.

## 8. Conclusion

**VERDICT : ✅ PASSED — 0 bloquant.**

Le bloquant **B-1 est authentiquement fermé** : par lecture du code, par **preuve d'effet** sur
4 charges, et par **deux outils non-LLM indépendants** dont l'un (`zizmor`) montre que le correctif va
**au-delà** du finding. Le job requis `check-branch-name` est **intact**. Le step `actionlint` a été
audité **comme du code neuf** et **tient** : empreinte exacte (3 sources), échec **réellement**
fail-closed (contrôle négatif), ordre vérifier-puis-exécuter respecté, aucun cache, aucune permission
ajoutée, et compatible `shellcheck` (vérifié). **C'est un progrès net.**

Le seul reproche substantiel au correctif est **N-1** : il ajoute un tiers de plus au chemin critique
d'un contexte requis, et le plan de retour arrière **s'interdit** de couvrir ce cas. C'est un défaut
de **documentation**, pas de sécurité, sur une classe de risque **déjà présente** et **moins bien
gérée** ailleurs dans le même job.

**Ce qui reste dû, et n'est pas bloquant** : les 4 MEDIUM et 4 LOW du cycle 1 sont **ouverts, non
traités, non aggravés** — la déclaration du SCB est **exacte**. J'y ajoute N-1, N-2, N-3 (MEDIUM) et
N-4, N-5 (LOW). Aucun ne relève de ce correctif.

⚠️ **Deux bornes à ne pas escamoter** : (1) **aucun scan de CVE n'existe** dans cette factory — mon
PASS ne s'appuie sur **aucun** scan de vulnérabilité de dépendances ; (2) le `ci.yml` corrigé
**n'a jamais tourné en CI** (N-5) — mon verdict sur son comportement en environnement cible est une
**inférence solidement outillée**, pas une observation.
