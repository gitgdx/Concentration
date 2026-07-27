# Rapport QA — US-00.4 · Enforcement de la branche principale : constat, vérification honnête et cible armée

**Verdict : 🧪 PASS** *(avec 1 réserve à lever par l'humain **avant** `/certify` — §8, É-1)*

| Champ | Valeur |
|---|---|
| Agent | @QA_Tester — `claude-opus-5[1m]` |
| Date | 2026-07-27 |
| Branche | `feat/US-00.4-ci-protection-branche` · `HEAD = 2708254` |
| `origin/main` | `801a046` — **intacte**, vérifiée avant et après mes travaux |
| Audits amont | Rev 🔍 ✅ (`code_review_2.md`, cycle 2) · Sec 🛡️ ✅ (`security.md`) — pré-conditions `validate_trace --us US-00.4` → *Traçabilité conforme* |

**Nature de l'US** : gouvernance / plateforme, **aucun code Dart livré** → la couverture ne bouge pas et
aucun test unitaire Dart n'est attendu. La QA porte sur **conformité aux AC + couverture BDD +
non-régression + exécution réelle du livrable**, comme pour US-00.2 et US-00.3.

**Périmètre assumé, vérifié comme tel** : `main` **n'est pas protégée** et ne l'est pas devenue. Ce que
j'ai validé, c'est que l'US livre ce qu'elle promet **et n'affirme nulle part le contraire**.

---

## 1. Décomptes exacts

| Objet | Exécuté | Vert | Rouge | Skipped |
|---|---|---|---|---|
| Gates qualité (`run_gates.py --all`) | **5** | **5** | 0 | 0 |
| Tests unitaires Dart (`flutter test`) | **2** | **2** | **0** | **0** |
| Gates de gouvernance (`factory_sync --check`, `check_scb_compliance`, `validate_trace --all`) | **3** | **3** | 0 | 0 |
| Invocations de `check_branch_protection.py` (in vivo + fixtures + erreurs d'usage) | **16** | **16 conformes à la spécification** | 0 | 0 |
| Scans `gitleaks` 8.30.1 (working tree + 8 commits de la branche) | **2** | **2** (`no leaks found`) | 0 | 0 |
| Scénarios Gherkin | **20** | **20 couverts** | 0 non couvert | **0 skipped** |
| Critères de test du Story File | **26** | **24 pleinement satisfaits** | 0 en échec | **2 partiels** (#20, #21 — bloqués sur l'absence de PR) |
| AC | **8** | **8 conformes** | 0 orphelin | — |

**Couverture de lignes Dart : 89,5 % (17/19) — seuil requis 80,0 % → ✅ tenu.** Inchangée par cette US
(aucun fichier Dart au diff).

⚠️ **Aucun scénario Gherkin n'est exécuté par un runner** : la stack ne comporte **aucun harnais
Gherkin** (`tests/features/` sans step definitions ; `docs/qa/E2E_RUNBOOK.md` définit le E2E comme la
ré-exécution des gates, que j'ai faite). Les 20 scénarios sont donc couverts par **exécution d'outil**
(15) ou **revue d'artefact** (5) — jamais par un « vert » automatique. **Dette de stack, déclarée ici.**

---

## 2. Non-régression — sorties réelles

### 2.1 `run_gates.py --all` → **exit 0, 5/5**

```
$ python scripts/run_gates.py --all
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 2 files (0 changed) in 0.09 seconds.
✅ app.format
▶ app.analyze — (.) $ flutter analyze
No issues found! (ran in 45.9s)
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:11 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test
▶ app.deps_audit — (.) $ dart pub outdated --show-all
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

### 2.2 `factory_sync.py --check` → **exit 0**, et il annonce bien « DOCUMENTAIRE » + l'avertissement

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
EXIT=0
```

L'ancien libellé `Synchro factory conforme (env, protection, workflows, seuils).` a **disparu** (diff
T4 vérifié §7). Le mot « protection » n'apparaît plus que dans une **négation**. Le gate reste
**bloquant** : `.github/workflows/ci.yml:62` exécute `--check` dans le job `📋 Governance (SCB +
traçabilité + synchro)`, sans `continue-on-error`.

### 2.3 SCB + traçabilité

```
$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.
EXIT_SCB=0

$ python scripts/validate_trace.py --all
Traçabilité conforme.
EXIT_TRACE=0
```

---

## 3. Le livrable fonctionne-t-il vraiment ? — 16 invocations, toutes conformes

### 3.1 In vivo, chemin autoritatif — **exit 2 nommant le 403 de plan** (le seul chemin observable)

```
$ export PATH="/c/Program Files/GitHub CLI:$PATH"   # cf. É-6 : gh hors PATH de session
$ python scripts/factory_sync.py --check-remote
Lecture SEULE de l'API GitHub (GET uniquement) — gitgdx/Concentration:main · GET repos/gitgdx/Concentration/branches/main → 200 · GET repos/gitgdx/Concentration/branches/main/protection → 403
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Code HTTP : 403 — protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut lire ni appliquer la protection en l'état. Message API : 'Upgrade to GitHub Pro or make this repository public to enable this feature.'
  Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
EXIT_SYNC=2

$ python scripts/check_branch_protection.py      # invocation directe : issue identique
… EXIT_DIRECT=2
```

Mot « conforme » : **0 occurrence** sur ce chemin (vérifié aussi sur l'archive `check_remote_exit2.txt`
→ `grep -ci conform` = **0**).

### 3.2 Les 6 chemins sur fixtures — 8 invocations, `[SIMULATION] ` sur **100 %** des lignes

| # | Fixture | Exit attendu | Exit obtenu | Lignes sans `[SIMULATION] ` | Mot « conforme » |
|---|---|---|---|---|---|
| P1 | `protection_conforme` + `branch_protected_true` | 0 | **0** | **0** | présent (chemin autorisé) |
| P2 | `protection_divergente` | 1 | **1** | **0** | **0** |
| P3 | `http_404` (status 404) + `branch_protected_false` | 1 | **1** | **0** | **0** |
| P4 | `http_404` (status 404) + `branch_protected_true` | 2 | **2** | **0** | **0** |
| P5a | `protection_lock_branch_actif` | 2 | **2** | **0** | **0** |
| P5b | `protection_block_creations_actif` | 2 | **2** | **0** | **0** |
| P5c | `protection_cle_inconnue_active` | 2 | **2** | **0** | **0** |
| P6 | `protection_cles_additives_neutres` | 0 | **0** | **0** | présent (chemin autorisé) |

Extraits probants :

```
P1 → [SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
     [SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt        → EXIT 0

P2 → [SIMULATION]   champ | attendu | réel
     [SIMULATION]   required_status_checks.contexts (MANQUANT) | "📱 App (gates run_gates.py)" | <absent de la réponse GET>
     [SIMULATION]   required_status_checks.contexts (EN TROP) | <absent de la cible générée> | "🧪 E2E smoke (nightly)"
     [SIMULATION]   required_pull_request_reviews.required_approving_review_count | 0 | 1
     [SIMULATION]   enforce_admins (GET: enforce_admins.enabled) | true | false                            → EXIT 1

P3 → [SIMULATION] GET …/protection → 404 et GET …/branches/main → "protected": false : la branche n'est
     réellement PAS protégée (ce n'est pas un défaut de droits).                                           → EXIT 1
P4 → [SIMULATION]   Code HTTP : 404 — … annonce "protected": true → la protection existe mais reste
     ILLISIBLE : droits insuffisants (admin requis)                                                        → EXIT 2

P5a → MAPPING INCOMPLET … : lock_branch = {"enabled": true} … la comparaison est INCOMPLÈTE et ne peut
      donc RIEN conclure                                                                                   → EXIT 2
P5c → … 2 champ(s) : require_signed_commits_v2 = {"enabled": true} ·
      required_pull_request_reviews.bypass_pull_request_allowances = {"users": [{"login": "octocat"}], …}   → EXIT 2
P6  → 10 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s) … [IGNORÉ — NEUTRE] …
      future_flag_absent, future_liste_vide, require_signed_commits_v2, bypass_pull_request_allowances      → EXIT 0
```

**Le correctif B-2 tient** : une clé **ACTIVE** non mappée fait sortir en **2** en se **nommant** ;
une clé **additive neutre** est **nommée** (`[IGNORÉ — NEUTRE]`) sans faire trébucher l'outil. La
frontière porte bien sur la **valeur** et non sur la connaissance du **nom**.

### 3.3 Edge cases que j'ai ajoutés — 6 cas au-delà des chemins passants

| Edge case | Attendu | Obtenu |
|---|---|---|
| **E-1** `--from-protection` **seul** | exit 2 « erreur d'usage » | **exit 2** — `ERREUR D'USAGE — --from-protection et --from-branch vont obligatoirement PAR PAIRE …` |
| **E-2** `--from-branch` **seul** | idem | **exit 2**, message identique |
| **E-3** mode fixture **sans `gh` et sans jeton** (`PATH` réduit à Python, `GH_TOKEN`/`GITHUB_TOKEN` retirés) | exit 0, **aucun appel réseau** | **exit 0** — prouve l'absence de réseau en mode fixture |
| **E-4** **repli `urllib` in vivo** : `gh` hors `PATH` + jeton **invalide** | exit 2, **401** distingué du 403 | **exit 2** — `Code HTTP : 401 — NON AUTHENTIFIÉ (jeton absent, expiré ou invalide) — ce n'est ni un défaut de plan, ni une branche non protégée. Message API : 'Bad credentials'` → **transport `urllib` réellement atteint** (réserve levée, §9) |
| **E-5** `--raw-out` **en mode fixture** | refusé (R1) | **exit 2** — `--raw-out est refusé en mode fixture : archiver une réponse SIMULÉE … la rendrait relisible comme une preuve d'état réel (R1)` ; **fichier non créé** (vérifié) |
| **E-6** `--check-remote` **sans `gh` ni jeton** (PATH de session périmé) | exit 2, cause « `gh` introuvable » et **non** le 403 | **exit 2** — cause correcte. C'est le piège que `audit-methodo.md:27-30` documente **explicitement** : l'artefact avait anticipé mon propre mode de défaillance |

### 3.4 Lecture seule — prouvée, pas déclarée

```
$ grep -nE '\-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)' scripts/check_branch_protection.py
EXIT_GREP=1   (aucun résultat)

$ grep -nE 'method=|urlopen' scripts/check_branch_protection.py
373:        method="GET",          ← verbe figé côté transport urllib
376:        with urllib.request.urlopen(request, timeout=20) as response:

$ grep -n "shell=True|os.system" scripts/check_branch_protection.py
(aucun résultat — tous les subprocess sont en forme LISTE : pas de surface d'injection shell)
```

`origin/main` = `801a046` **avant et après** l'ensemble de mes exécutions. Aucune commande d'écriture
distante, aucun `PUT`, aucun `--no-verify`.

### 3.5 Import paresseux — prouvé empiriquement

```
$ python -X importtime scripts/factory_sync.py --check 2>&1 | grep -c "check_branch_protection"
0        ← --check n'importe JAMAIS le module : il ne peut pas casser le gate CI bloquant
```

### 3.6 Contrôle distant hors CI + payload armé

```
$ grep -rn "check-remote" .github/workflows/
EXIT_GREP=1   (aucun résultat)

$ python scripts/factory_sync.py --emit-branch-protection
{ "required_status_checks": { "strict": true, "contexts": [ "🔐 Secrets scan (gitleaks)",
  "📋 Governance (SCB + traçabilité + synchro)", "check-branch-name", "📱 App (gates run_gates.py)" ] },
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "enforce_admins": true, "restrictions": null, "allow_force_pushes": false,
  "allow_deletions": false, "required_linear_history": false,
  "required_conversation_resolution": true }        EXIT=0
```

`required_pull_request_reviews` **présent avec `0`** ; `emit_branch_protection()`
(`scripts/factory_sync.py:59-74`) l'émet **inconditionnellement** — lecture du code confirmée.

### 3.7 Re-vérification indépendante du constat, à **ma** date (2026-07-27)

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected,protection_enabled:.protection.enabled}'
{"name":"main","protected":false,"protection_enabled":false}

$ gh api repos/gitgdx/Concentration/branches/main/protection
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.", … "status":"403"}

$ gh api repos/gitgdx/Concentration/rulesets
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.", … "status":"403"}

$ gh api repos/gitgdx/Concentration --jq '{private,visibility,owner_type:.owner.type,admin:.permissions.admin}'
{"admin":true,"owner_type":"User","private":true,"visibility":"private"}

$ gh api repos/gitgdx/Concentration/collaborators --jq '[.[]|select(.permissions.push)|{login,admin:.permissions.admin}]'
[{"admin":true,"login":"gitgdx"}]      ← 1 seul compte en écriture : condition « retour à 1 approbation » NON déclenchée (< 2)
```

Le constat daté du 2026-07-26 est **reproduit à l'identique le 2026-07-27**, avec un jeton
`admin: true` sur un dépôt `private: true` : la cause est bien **le plan**, jamais les droits.

### 3.8 `gitleaks` — réserve confirmée levée

```
$ "$LOCALAPPDATA/Microsoft/WinGet/Packages/Gitleaks.Gitleaks_*/gitleaks.exe" version
8.30.1
$ gitleaks detect --source . --no-git --config .gitleaks.toml --redact
INF scanned ~118036205 bytes (118.04 MB) in 9.97s
INF no leaks found                                    EXIT=0
$ gitleaks detect --source . --config .gitleaks.toml --redact --log-opts="main..HEAD"
INF 8 commits scanned.
INF no leaks found                                    EXIT=0
```

Balayage jetons complémentaire sur `reports/US-00.4/` + `tests/fixtures/US-00.4/` : les seules
occurrences sont les **motifs regex eux-mêmes** cités dans les rapports d'audit et un placeholder
`ghp_ZZZZ…(factice)` — **aucun jeton réel**, aucun en-tête `Authorization` valorisé.

---

## 4. Couverture BDD — les 20 scénarios, un par un

Légende : **EXÉC** = couvert par une commande que j'ai lancée · **ART** = couvert par revue d'artefact
(énoncé portant sur le contenu d'un document ou d'un rituel — non exécutable par nature).

| # | Scénario (AC) | Statut | Preuve — commande que j'ai lancée ou fichier |
|---|---|---|---|
| 1 | Constat daté étayé par les réponses brutes (Nom. AC-1) | ✅ **EXÉC** | §3.7 (4 `gh api` rejoués à ma date) + `branch_main_before.json` (`"protected":false`), `check_runs.json` (4 checks `success`), `protection_api_403.json`, `rulesets_api_403.json`, `repo_context.json`, contradiction dans `enforcement_gap.md` §4. ⚠️ La moitié « aucun n'est requis » est une **inférence déclarée** (§5, AC-1) |
| 2 | Cause racine = plateforme, non droits (Lim. AC-1) | ✅ **EXÉC** | §3.7 : les **deux** mécanismes en 403 au message **identique** avec `admin:true` · §3.3 E-4 : **401 obtenu in vivo**, distingué du 403 · tableau 403/401/404 de `enforcement_gap.md:30-35` · date + commande de re-vérification (`GIT_PROTECTION.md` §Vérification, `audit-methodo.md:23-30`) |
| 3 | Aucune preuve documentaire substituée (Err. AC-1) | ✅ **EXÉC** | En-têtes des 5 `*.json` : **commande exacte + horodatage UTC + statut HTTP + code de sortie `gh`** (lus intégralement) · `enforcement_gap.md:15-18` récuse explicitement bloc généré / sortie `--check` / capture · mon balayage §6 : aucun énoncé affirmant que `main` est protégée |
| 4 | `--check` annonce un contrôle documentaire (Nom. AC-2) | ✅ **EXÉC** | §2.2 : « DOCUMENTAIRE », « aucun appel réseau », énumération des 4 objets comparés, avertissement, renvoi vers `--check-remote`, **exit 0** · reste gate bloquant (`ci.yml:62`, job `📋 Governance`, sans `continue-on-error`) |
| 5 | Un `--check` vert n'atteste jamais l'état réel (Err. AC-2) | ✅ **EXÉC** | §2.2 : l'ancien libellé `conforme (env, protection, workflows, seuils)` a **disparu** (diff T4, §7) ; « protection » n'y figure plus que dans une **négation** · cause de survie du défaut consignée : `enforcement_gap.md:75-85` (« une vérification verte a coexisté … depuis l'origine, à travers 8 fusions de PR et 3 certifications Prod ») |
| 6 | Le contrôle réel n'entre pas dans la CI (Lim. AC-2) | ✅ **EXÉC** | §3.6 : `grep -rn "check-remote" .github/workflows/` → **exit 1, aucun résultat** · raison écrite dans `GIT_PROTECTION.md:199` **et** le docstring `factory_sync.py:16-17` (« le `GITHUB_TOKEN` n'a pas ces droits ») · déclaré « MANUELLE, jamais exécutée par la CI » |
| 7 | Seule une conformité stricte est un succès (Nom. AC-3) | ✅ **EXÉC** *(fixture — déclaré)* | §3.2 P1 : exit 0, **12 champs comparés un par un**, `[SIMULATION] ` sur 100 % des lignes, mention « SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt ». « conforme » **absent** de P2/P3/P4/P5a/P5b/P5c et de `check_remote_exit2.txt`. Aucune écriture : §3.4 |
| 8 | Divergence signalée champ par champ (Err. AC-3) | ✅ **EXÉC** *(fixture — déclaré)* | §3.2 P2 : exit 1, **4 écarts**, en-tête `champ \| attendu \| réel`, contextes **MANQUANT** et **EN TROP** listés **séparément**. `origin/main` inchangée (§3.4) |
| 9 | Vérification impossible = constat, jamais succès (Lim. AC-3) | ✅ **EXÉC** *(in vivo)* | §3.1 : exit 2, `VERIFICATION IMPOSSIBLE — ce n'est PAS un succès`, **403 de plan nommé**. Les autres causes de l'énoncé exercées : **absence d'outil + de jeton** (E-6), **non-authentification 401** (E-4), **ambiguïté du 404 levée par la 2ᵉ lecture non privilégiée** (P3/P4). Archivé tel quel : `check_remote_exit2.txt`. *Erreur réseau (timeout) non exercée → §9* |
| 10 | Cible applicable en une seule commande (Nom. AC-4) | ✅ **EXÉC** | §3.6 : payload généré = 0 approbation, `enforce_admins: true`, `strict: true`, **4 contextes aux libellés exacts**, `restrictions: null` · consommable par `apply_branch_protection.sh` (`--input -`) · *Given* vérifié §3.7 : **1 seul collaborateur, admin** |
| 11 | Présenter la cible comme active est un défaut (Err. AC-4) | ✅ **EXÉC** | Mon balayage indépendant §6 : **aucune** affirmation non déclarée que `main` est/devient protégée · `apply_branch_protection.sh` porte l'en-tête **NON APPLICABLE … PRÊT et CONDITIONNÉ AU DÉBLOCAGE** · aucune preuve d'application produite : T16→T19 **décochées** et non exécutées (§8) |
| 12 | PR exigée malgré 0 approbation (Lim. AC-4) | ✅ **EXÉC** | §3.6 : `required_pull_request_reviews` **présent avec `0`** dans le payload émis ; `emit_branch_protection()` l'émet **inconditionnellement** (code lu) · « valide **logiquement**, jamais validée **fonctionnellement** » : Story File AC-4 limite + `GIT_PROTECTION.md` §Cible armée · réglage déclaré **daté et conditionnel** au dépôt mono-collaborateur (`audit-methodo.md:53-54`) |
| 13 | Deux conditions de déblocage documentées (Nom. AC-5) | ✅ **ART** | `GIT_PROTECTION.md:78-96` : tableau à **exactement deux** voies — (a) public, coût **nul**, `⚠️ IRRÉVERSIBLE pour ce qui a été publié … expose définitivement tout l'historique`, `gitleaks` barrière **critique** ; (b) GitHub Pro, **coût par utilisateur et par mois**, dépôt **privé** conservé · « ce qui serait débloqué est identique … et le **test négatif serveur** reporté devient exécutable » · « hors du pouvoir d'un agent : décision **humaine explicite et tracée** » |
| 14 | Ajouter un collaborateur ne débloque rien (Lim. AC-5) | ✅ **ART** | `GIT_PROTECTION.md:92-93` : « **Ajouter un collaborateur ne débloque RIEN.** La limitation porte sur le **plan** … et la **visibilité** — **pas** sur le nombre de contributeurs » · date + dépendance à la politique commerciale : `GIT_PROTECTION.md:79-81` |
| 15 | Point de contrôle périodique (Nom. AC-6) | ✅ **ART** | `.claude/commands/audit-methodo.md:19-60`, axe Gouvernance : exécution de `--check-remote` (a), **consignation du code de sortie** en tableau (b), réévaluation du **déblocage** via `visibility`/`plan` (c), réévaluation du **retour à `1`** via `collaborators` avec « si **≥ 2** : ouvrir une US » (d). *Le rituel lui-même est trimestriel — non exécuté ici, par construction* |
| 16 | Vérification impossible = dette maintenue (Err. AC-6) | ✅ **ART** | `audit-methodo.md:36-40` : exit **2** → « la dette reste **OUVERTE** et doit être **SIGNALÉE**. ⛔ Jamais consigné comme un succès, **jamais** utilisé pour clore la dette » · exit **0** → exécuter le test négatif reporté (T18) · exit **1** → ré-appliquer depuis la config · « **Aucune de ces trois issues ne peut rester silencieuse.** » |
| 17 | Enforcement réel = filet de discipline (Nom. AC-7) | ✅ **EXÉC + ART** | `GIT_PROTECTION.md:15` (« **filet de discipline**, pas une contrainte de plateforme ») et tableau `:65-66` : hook local `pre-push`, CI qui **rapporte** 4 checks « sans pouvoir bloquer ». Discipline de process **vérifiée par moi** : `git log --first-parent --oneline origin/main` → **8 fusions de PR** (#1,#3,#4,#5,#6,#7,#8,#9) · `git config --get core.hooksPath` → `scripts/githooks` |
| 18 | Présenter le hook/la CI comme contrainte de plateforme est un défaut (Err. AC-7) | ⚠️ **ART — écart résiduel déclaré, non corrigé** | Limites **nommées** dans `GIT_PROTECTION.md:65-66` : absent d'un **clone frais**, contournable depuis un autre poste ou via l'**interface web**, `--no-verify` interdit mais porté par la **même** discipline, fusion possible **avec CI rouge**. **MAIS** `scripts/githooks/pre-push:2-3` présente encore la protection GitHub comme la raison du hook → **É-1 (§8)**. Déclaré (S10 + T22, diff exact fourni), **Art. 6 → hors pouvoir agent** |
| 19 | Test négatif serveur reporté, non exécuté (Lim. AC-7) | ✅ **EXÉC** | T16→T19 **décochées**, en-tête « ⛔ NE PAS EXÉCUTER » · `origin/main` = **`801a046` inchangée** (mesurée avant/après) · balayage : **aucune commande de push actif** vers `main` dans les livrables (les seules occurrences sont des **interdictions** ou des explications du « réussirait ») · la charge d'injection `--repo 'a/$(git push --force origin main)'` du re-audit a été **bloquée par `block_dangerous_bash.sh`** et **jamais exécutée** (`code_review_2.md` §11) ; aucun `shell=True` dans le module (§3.4) · absence de démonstration de l'effet assumée : AC-7 limite + ADR-006 |
| 20 | Ni réécriture d'historique, ni certification remise en cause (Lim. AC-8) | ✅ **EXÉC** | `git log --first-parent --oneline origin/main` → **10 entrées = 8 fusions + exactement 2 commits directs** (`0a2e5ab`, `6483022`) · `origin/main` inchangée · **aucun `EVT_WORKFLOW_VIOLATION`** dans `docs/trace/*/events.jsonl` (l'unique occurrence est une **mention textuelle** dans le *rationale* de `EVT_STORY_READY`, pas un événement) · certifications déclarées valides : `enforcement_gap.md` §3 · transmission **OBLIGATOIRE** à US-00.5 : `enforcement_gap.md` §6 |

**Bilan BDD : 20 couverts / 0 non couvert / 0 skipped.** Un seul scénario (n° 18) porte un **écart
résiduel** dans le dépôt, déclaré et hors pouvoir agent.

---

## 5. Les 8 AC — conformité et preuve

| AC | Verdict | Preuve décisive | Point de vigilance |
|---|---|---|---|
| **AC-1** — constat daté, étayé, cause racine « plan » | ✅ **Conforme** | §3.7 (constat **reproduit** à ma date) + 5 preuves brutes en-têtées commande/UTC/statut/exit + contradiction `enforcement_gap.md` §4 | **Fait (b) — vérifié en détail** : l'inférence est écrite **explicitement comme telle**, en **2 endroits au moins** : en-tête de `check_runs.json` (« ⚠️ PORTÉE DE CETTE PREUVE — elle établit UNIQUEMENT que les 4 checks S'EXÉCUTENT … NE dit RIEN de leur caractère requis ou bloquant … la seconde moitié du fait est une INFÉRENCE, pas une lecture d'API ») et `enforcement_gap.md` §1.1 (« **INFÉRENCE** depuis `"protected": false` … **Ce n'est pas une lecture directe, et ce document ne la présente pas comme telle** »), plus la ligne du tableau §1 qui classe le statut de preuve en « **Mixte : lecture directe + INFÉRENCE** ». **Aucune présentation en lecture directe d'API. Conforme.** |
| **AC-2** — `--check` non lisible comme attestation | ✅ **Conforme** | §2.2 exécuté ; §3.6 grep CI vide ; gate resté bloquant | Le mot « protection » n'apparaît qu'en **négation**. Le contrôle négatif exigé par la limite (absence dans `.github/workflows/`) est **vérifié** |
| **AC-3** — 3 issues honnêtes dont « vérification impossible » | ✅ **Conforme** | §3.1 (exit 2 in vivo, 403 nommé) · §3.2 (exits 0/1/2 sur les 6 chemins) · §3.3 (6 edge cases) · §3.4 (lecture seule prouvée) | Exit 0 et exit 1 restent **prouvés sur fixtures** — déclaré (R1/R4) et **marqué structurellement** : `[SIMULATION] ` sur 100 % des lignes, `--raw-out` **refusé** en mode fixture (E-5) |
| **AC-4** — cible **armée**, explicitement NON active | ✅ **Conforme** | §3.6 payload généré ; en-tête `NON APPLICABLE` de `apply_branch_protection.sh` ; `false_claims_sweep.md` + mon balayage §6 | `required_pull_request_reviews` **conservé avec `0`** (piège (i)) ; caractère daté/conditionnel du `0` (piège (ii)) porté par `audit-methodo.md` (d) |
| **AC-5** — conditions de déblocage + conséquences | ✅ **Conforme** | `GIT_PROTECTION.md:78-96` (lu intégralement) | **Irréversibilité nommée en majuscules** ; « ajouter un collaborateur ne débloque RIEN » présent ; date + dépendance commerciale portées |
| **AC-6** — point de contrôle périodique porteur de la dette | ✅ **Conforme** | `audit-methodo.md:19-60` | Sémantique des 3 issues écrite, dont « exit 2 = dette **OUVERTE**, à SIGNALER, jamais un succès ». Bonus : `:27-30` documente le piège `gh` hors `PATH` — que j'ai **effectivement rencontré** (E-6) |
| **AC-7** — filet de discipline sans survente | ⚠️ **Conforme sur les livrables, écart résiduel hors périmètre** | `GIT_PROTECTION.md:15,65-66` ; T16→T19 décochées ; `origin/main` intacte | **É-1** : `scripts/githooks/pre-push:2-3` — l'élément (a) du filet contredit encore l'AC dans son propre commentaire. **Art. 6 → T22 [action humaine]**, diff exact fourni, déclaré S10 |
| **AC-8** — portée bornée, mise en cohérence déléguée | ✅ **Conforme** | §3.7 + `git log --first-parent` (8+2) ; aucun `EVT_WORKFLOW_VIOLATION` ; `enforcement_gap.md` §3 et §6 | Transmission à US-00.5 formulée comme **OBLIGATOIRE**, avec les 2 emplacements exacts (`CLAUDE.md:20`, `CONSTITUTION.md:49`) et la formulation de remplacement |

**AC orphelins : aucun.** Chaque AC a au moins un scénario Gherkin et au moins une preuve exécutée ou
un artefact vérifié.

---

## 6. Balayage QA indépendant « aucune fausse affirmation »

J'ai rejoué un balayage avec **mes propres motifs**, toutes extensions, hors `.git/`, `build/`,
`.dart_tool/` :

```
$ grep -rniE "protection de branche (GitHub )?(est |activ|en place|appliqu)|main est protégée|\
branche principale est protégée|status checks? (sont |est )?(requis|bloquants)|\
checks requis par la protection|protection active" --include="*" .
$ grep -rniE "empêch|bloqu|refus" --include="*.feature" --include="*.yml" --include="*.sh" . | grep -iE "protection|protégé"
```

**Résultat : aucune fausse affirmation NON DÉCLARÉE.** Toutes les occurrences remontées sont soit des
**négations** (« indisponible », « NON ATTEIGNABLE », « n'atteste PAS »), soit des **citations
d'énoncés démentis**, soit **déjà déclarées** avec leur porteur :

| Occurrence retrouvée | Statut |
|---|---|
| `.github/workflows/ci.yml:3-11` | ✅ **CORRIGÉ** (C12) — vérifié : « ⚠️ **RAPPORTÉS, PAS BLOQUANTS** », 403 de plan nommé, « une PR peut être fusionnée **AVEC LA CI ROUGE** », statut de **contextes de la cible armée** |
| `scripts/githooks/pre-push:2-3` | ⚠️ **NON corrigé** → **É-1**, T22 (Art. 6) |
| `docs/stories/US-00.1-*.md:198,215` | ⚠️ déclaré S11 → US-00.5 (US **certifiée**, non éditable) |
| `tests/features/US-00.1-*.feature:54` | ⚠️ **confirmé présent** — « la fusion vers la branche principale est **empêchée par la protection de branche** ». → **É-4** |
| `docs/SQUAD_GUIDE.md:36` · `docs/GIT_PROTECTION.md:149` (bloc généré) · `EPIC_00:13` | ⚠️ déclarés S12 / C6-dette #8 / S8, avec porteurs nommés |
| `.claude/settings.local.json:97` | Cache de permissions locales portant l'**ancien** rationale du 2026-07-26 ; hors corpus de gouvernance, exclu du balayage par `false_claims_sweep.md:105`. Non-problème |

Le §5 « **l'exhaustivité n'est PAS revendiquée** » de `false_claims_sweep.md` est **honnête et
vérifié** : il nomme ses trois échecs successifs de méthode et ne conclut plus à « 0 occurrence
subsistante ».

---

## 7. Enforcement intact — diff vérifié fichier par fichier

```
$ git diff --stat main...HEAD -- factory.config.json scripts/factory_sync.py scripts/run_gates.py \
    scripts/githooks/ .claude/hooks/ .gitleaks.toml .claude/settings.json scripts/factory_env.sh \
    scripts/install_hooks.sh
 factory.config.json     |  3 ++-
 scripts/factory_sync.py | 26 ++++++++++++++++++++++----
 2 files changed, 24 insertions(+), 5 deletions(-)
```

**Seuls les 2 fichiers légitimes sont touchés**, les deux par l'**humain** :

- `scripts/factory_sync.py` (**T4**) — diff intégral relu : **exactement** les 4 diffs spécifiés
  (docstring `--check`, docstring `--check-remote`, message de fin de `do_check` + avertissement,
  drapeau `--check-remote` + dispatch à import paresseux). **Aucune ligne de logique de détection
  touchée** — les fonctions de contrôle de `do_check` sont inchangées, donc **aucun affaiblissement du
  gate**.
- `factory.config.json` (**cible armée**) — `required_approving_review_count: 1 → 0` (édition humaine,
  Art. 6) **+ la ligne parasite de 2 espaces** → **É-2**.

**Intacts (aucune ligne au diff)** : `scripts/run_gates.py` · `scripts/githooks/*` · `.claude/hooks/*` ·
`.gitleaks.toml` · `.claude/settings.json` · `scripts/factory_env.sh` · `scripts/install_hooks.sh`.

**État de `main` et des tâches interdites**

```
$ git rev-parse origin/main        → 801a046e7c2f833a4038c4080e0eb19ca0d28754   ✅ = 801a046, intacte
$ git rev-parse HEAD              → 2708254af1c069c0f788a9e71c91d27a2d43b68d   ✅ = 2708254
$ git status --porcelain          → (vide)
$ git ls-remote --heads origin 'feat/US-00.4*'   → (vide : branche non poussée)
```

**T16 → T19 : décochées dans le Story File et NON exécutées.** Aucun `PUT`, aucun push vers `main`,
aucun force-push, aucune suppression, aucun clone-sonde. Conformément à l'interdiction, **je n'ai
exécuté aucun test négatif**.

---

## 8. Écarts constatés — format « Action → Attendu → Obtenu »

### É-1 — `scripts/githooks/pre-push` contredit l'AC-7 dont il est l'élément (a) · ⚠️ **à lever avant `/certify`**

- **Action effectuée** : `sed -n '1,3p' scripts/githooks/pre-push` puis
  `git diff --stat main...HEAD -- scripts/githooks/pre-push`
- **Résultat attendu** (AC-7 Erreur, scénario 18 : « présenter le hook local … comme une contrainte de
  plateforme est un défaut bloquant ») : aucun énoncé adossant le hook à une protection de plateforme.
- **Résultat obtenu** :
  ```
  #!/bin/sh
  # Refuse le push direct vers la branche principale. Le merge passe par une PR
  # (protection de branche GitHub : scripts/apply_branch_protection.sh).
  ```
  → le hook **justifie son existence par une protection inexistante**. Diff `main...HEAD` : **vide**
  (fichier non modifié).
- **Analyse** : c'est **exactement** la fausse confiance que l'US existe pour supprimer, et elle
  subsiste dans un **fichier d'enforcement** lu par toute la squad. **Mais** : `scripts/githooks/*` est
  **Art. 6** — ni @Developer, ni moi ne pouvons y toucher ; l'écart est **déclaré** (S10 du
  `false_claims_sweep.md`, §5 « non corrigeable / porteur T22 ») et le **diff exact est fourni** en
  T22. L'US a fait tout ce que ses pouvoirs permettent.
- **Mon appel** : **NON bloquant pour le `🧪 PASS`** — un FAILED renverrait l'US à un agent qui ne peut
  légalement pas la corriger : impasse, et sanction d'un respect correct de l'Art. 6.
  **MAIS BLOQUANT en entrée du `/certify`** : certifier `🚀 OUI` une US dont la valeur centrale est
  « zéro fausse confiance », en laissant la fausse affirmation dans le hook que l'AC-7 désigne comme
  élément (a), serait incohérent. → **T22 est une action humaine à exécuter avant `/certify`**,
  arbitrage @Architect (Art. 5).

### É-2 — T6 non faite : ligne parasite de 2 espaces dans `factory.config.json`

- **Action effectuée** : `git diff main...HEAD -- factory.config.json | cat -A`
- **Résultat attendu** (T6) : aucune ligne vide parasite avant `"branch_protection"`.
- **Résultat obtenu** :
  ```
   ],$
  +  $        ← ligne ajoutée, contenant exactement 2 espaces
   "branch_protection": {$
  -    "required_approving_review_count": 1,$
  +    "required_approving_review_count": 0,$
  ```
- **Mon appel** : **NON bloquant, ni pour le `🧪 PASS`, ni pour `/certify`.** Impact fonctionnel
  **nul** — le JSON parse, `factory_sync.py --check` est **exit 0** (§2.2), `--emit-branch-protection`
  est correct (§3.6), tous les gates passent. Aucun AC, aucun scénario, aucun critère de test ne porte
  sur la propreté du diff. C'est un confort de relecture. Recommandation : le faire **en même temps que
  T22**, puisque l'humain ouvrira de toute façon un fichier Art. 6 (coût marginal nul).
  `governance.grandfathering_date` reste bien **`null`** (R2) — vérifié.

### É-3 — Le préambule de la DoD sur-promet

- **Action effectuée** : lecture du préambule DoD (« **Cette DoD est intégralement cochable en l'état
  actuel du dépôt.** ») puis `git ls-remote --heads origin 'feat/US-00.4*'` et `gh pr checks`.
- **Résultat attendu** : toutes les cases cochables maintenant.
- **Résultat obtenu** : **2 cases ne le sont pas** — « PR ouverte (pas de commit direct sur la branche
  principale) » et « **4 status checks rapportés et verts sur la PR de cette US** ».
  `git ls-remote` → **vide** (branche non poussée) ; `gh pr checks` → `no pull requests found for
  branch "feat/US-00.4-ci-protection-branche"`.
- **Mon appel** : **NON bloquant.** Ces 2 cases relèvent de **@DevOps** (étape suivante) et ne sont pas
  empêchées par la limite de plan — la promesse du préambule visait la limite de plan, elle est juste
  formulée trop largement. À reformuler par @PO/@Architect si jugé utile.

### É-4 — `false_claims_sweep.md` ne liste pas la 4ᵉ occurrence résiduelle

- **Action effectuée** : balayage §6 sur `--include="*.feature"`.
- **Résultat attendu** : le §4 bis « balayage par motif **TOUTES EXTENSIONS** » liste toutes les
  occurrences retenues, `.feature` inclus.
- **Résultat obtenu** : `tests/features/US-00.1-secrets-scan-depot.feature:54` (« la fusion vers la
  branche principale est **empêchée par la protection de branche** ») **n'y figure pas**. Cause
  reproduite : le motif `merge (empêché|bloqué) par` exige le mot littéral « merge » et ne matche pas
  « la **fusion** … est empêchée par ». **C'est le 4ᵉ échec d'exhaustivité de la même méthode.**
- **Mon appel** : **NON bloquant.** L'occurrence **est consignée** ailleurs — `STORY_CERTIFICATION_BOARD.md:426`
  (« 1 fausse affirmation résiduelle non déclarée : `tests/features/US-00.1-secrets-scan-depot.feature:54` »)
  et `PROJECT_LOG.md` (ligne du 2026-07-27) — et transmise à **US-00.5**. Le §5 du rapport de balayage
  **ne revendique plus l'exhaustivité** et nomme ce type d'angle mort : il n'y a donc **pas de fausse
  affirmation** sur le rapport lui-même, seulement une **désynchronisation d'index**. À joindre à la
  transmission US-00.5.

### É-5 — 117 lignes sans `[SIMULATION] ` dans `check_remote_simulated.txt`

- **Action effectuée** : `grep -vc "^\[SIMULATION\] " reports/US-00.4/check_remote_simulated.txt` → **117**.
- **Résultat attendu** (R1) : chaque ligne de **sortie de l'outil** porte le préfixe.
- **Résultat obtenu** : les 117 lignes sont les **lignes d'encadrement de l'archive** (bandeaux,
  séparateurs `═`, commandes, codes de sortie), **pas** des lignes émises par l'outil. Contre-preuve
  décisive : sur mes **8 réexécutions** (§3.2), le compte de lignes de sortie sans préfixe est **0 sur
  8**. Le fichier porte en tête `⛔ CE FICHIER N'EST PAS UNE PREUVE DE L'ÉTAT RÉEL DU DÉPÔT. ⛔`.
- **Mon appel** : **NON bloquant.** L'exigence porte sur l'outil, et l'outil la respecte à 100 %. Déjà
  consigné NB-4 au cycle 1.

**Aucun autre écart.** Aucun échec de test, aucun gate rouge, aucune régression.

---

## 9. Réserves déclarées — je les ai vérifiées une par une

| Réserve annoncée | Mon verdict après exécution |
|---|---|
| Repli `urllib` **non exercé** in vivo | ⬆️ **PARTIELLEMENT LEVÉE par mon exécution** (E-4) : `gh` hors `PATH` + jeton invalide → le transport `urllib` est **réellement atteint sur le réseau** et rend `exit 2 / 401 « Bad credentials »`. **Reste non exercé** : `urllib` avec un jeton **valide** (exigerait de manipuler un secret réel — je m'en suis abstenu délibérément, cf. §11) |
| Chemin **404 non observable** sur ce dépôt (403) | ✅ **CONFIRMÉE et honnête** — §3.7 : 403 aux deux appels, à ma date encore. Validé **sur fixture uniquement** (P3/P4). Ne pas lire le critère #10 comme une preuve en conditions réelles |
| Exits 0/1 prouvés **sur fixtures uniquement** | ✅ **CONFIRMÉE et honnête** — et **structurellement marquée** : `[SIMULATION] ` sur 100 % des lignes, `--raw-out` refusé en mode fixture (E-5), fichiers d'archive distincts. R1 est réellement mitigé, pas seulement déclaré |
| « 4 status checks verts sur la PR » **non levable** | ✅ **CONFIRMÉE** — branche non poussée, `gh pr checks` → `no pull requests found`, `check-runs` sur `2708254` → **HTTP 422 « No commit found for SHA »**. **À lever par @DevOps** à l'ouverture de la PR : critères #20 (4 checks) et #21 (`gitleaks` en CI). Les **deux** ne dépendent que de la PR, pas du plan |
| `reports/US-00.4/*.json` **non parsables** en JSON | ✅ **CONFIRMÉE** — 5/5 non parsables (en-tête `#` + corps brut). **Sans impact** : (a) chaque en-tête le **déclare** et donne la commande d'isolation (`grep -v '^#'`) ; (b) les fichiers réellement **consommés par l'outil** sont les fixtures — **9/9 parsables** (vérifié). Le choix « corps non reformaté » est le bon pour une preuve brute |
| `branch_main_before.json` : bloc **PGP public** + e-mail committer | ✅ **CONFIRMÉE, et déclarée dans le fichier lui-même** (en-tête : « signature **PUBLIQUE** … ce n'est PAS une clé privée » + e-mail public du committer, « archivée TELLE QUELLE : tronquer une preuve brute la disqualifierait »). Tranché **acceptable** par l'audit sécurité. Je maintiens la **note §11** : l'adresse personnelle deviendrait publique si la voie de déblocage (a) était engagée |
| **`gitleaks`** — réserve initiale levée par l'audit sécurité | ✅ **RE-CONFIRMÉE par ma propre exécution** (§3.8) : binaire **8.30.1**, working tree (118 MB) → `no leaks found` ; **8 commits** de la branche → `no leaks found` |
| *(nouvelle, mineure — je l'ajoute)* **Erreur réseau / timeout** non exercée | Le chemin « erreur réseau » de l'AC-3 limite reste **non exercé** (le `timeout=20` de `urllib` et la branche `OSError` sont dans le code mais non déclenchés). Non bloquant : même classe d'issue (exit 2) que 3 chemins déjà prouvés in vivo. À joindre au `selftest` recommandé |

**Aucune réserve ne masquait un défaut.** Deux ont même été **renforcées** par mon exécution.

---

## 10. Dettes ouvertes — vérification de leur consignation (décision humaine : non bloquantes)

| Dette | Consignée ? | Vérification |
|---|---|---|
| **NB-1** — `check_branch_protection.py` passe `MAPPED_TOP_KEYS` (constante statique) au lieu de `MAPPED_TOP_KEYS & set(expected)` | ✅ **OUI, correctement** | `STORY_CERTIFICATION_BOARD.md:416-423` (« trou résiduel DÉMONTRÉ, correctif à 1 ligne … **Correctif** : `MAPPED_TOP_KEYS & set(expected)` ») + `PROJECT_LOG.md` (2026-07-27, @Architect, « CONFIRME ») + `code_review_2.md` §4.4 et tableau. **J'ai relu le code** : l'appel est bien `_classify_extra(actual, MAPPED_TOP_KEYS, "")`, et **non-atteignabilité confirmée** — `emit_branch_protection()` (`factory_sync.py:59-74`) émet les **8 clés inconditionnellement**, donc aucune clé mappée ne peut manquer de `expected` sans éditer un fichier **Art. 6**. **Traité en dette, pas en bloquant**, conformément à la décision humaine |
| `selftest` en CI (recommandation du re-audit) | ✅ OUI | `code_review_2.md` S-1 (« la plus utile ») ; à rattacher à une US ultérieure. **J'y ajoute** mes 6 edge cases (§3.3) et le chemin « erreur réseau » comme non-régressions à assertir |
| `tests/features/US-00.1-*.feature:54` (fausse affirmation résiduelle, US **certifiée**) | ⚠️ OUI **mais pas dans le rapport de balayage** | Consignée SCB:426 + PROJECT_LOG ; **absente** de `false_claims_sweep.md` §4 bis → **É-4** |
| **T22** (`scripts/githooks/pre-push`, Art. 6) | ✅ OUI (S10 + T22, diff exact) | **NON FAITE** → **É-1**, mon appel : bloquante pour `/certify`, pas pour le `🧪 PASS` |
| **T6** (ligne vide `factory.config.json:63`) | ✅ OUI (T6 + NB-10) | **NON FAITE** → **É-2**, mon appel : **non bloquante** |
| Autres (R2 `grandfathering_date` · R5 pas de détection auto · R6 comparateur hors `protect_files.sh` · R7 revue FULL sans barrière · R9 pas de déclencheur calendaire · périmètre Art. 6 déclaré ≠ appliqué) | ✅ OUI | `enforcement_gap.md` §dettes (7 entrées) + `GIT_PROTECTION.md` §Dettes |

---

## 11. Note de protection des données (instruction d'organisation)

Aucune donnée **C2/C3** n'a été manipulée. **Je n'ai à aucun moment extrait ni exposé de jeton réel** :
l'exercice du repli `urllib` (E-4) a utilisé une valeur factice (`dummy_invalid_not_a_real_token`), et
aucune de mes sorties n'en contient. `gitleaks` confirme l'absence de secret (§3.8).

⚠️ **Point d'attention non bloquant, à connaître de l'humain** : `reports/US-00.4/branch_main_before.json`
archive, dans son corps brut, une **adresse e-mail personnelle** et un bloc **PGP public**. Ce sont des
données publiques côté GitHub, l'audit sécurité l'a tranché acceptable, et l'en-tête du fichier le
déclare. **Mais** la voie de déblocage (a) de l'AC-5 est un passage du dépôt en **public déclaré
IRRÉVERSIBLE** : si cette voie était un jour engagée, cette donnée personnelle serait publiée
définitivement. À intégrer à la décision, pas à corriger ici.

---

## 12. Synthèse

**Verdict : 🧪 PASS.**

- **Non-régression** : 5/5 gates verts · 2 tests unitaires passed / 0 skipped / 0 failed · couverture
  **89,5 % ≥ 80 %** · SCB conforme · traçabilité conforme · `--check` **exit 0** annonçant
  « DOCUMENTAIRE » + l'avertissement.
- **Le livrable fonctionne** : **16 invocations**, **16 issues conformes à la spécification**. Le seul
  chemin observable in vivo (**exit 2 / 403 de plan**) est vérifié ; les 6 chemins sur fixtures le sont
  aussi, avec `[SIMULATION] ` sur **100 %** des lignes de sortie ; **6 edge cases** supplémentaires
  passent, dont l'un **lève partiellement une réserve** des deux audits.
- **Couverture** : **20/20 scénarios couverts** (0 non couvert, **0 skipped**) · **8/8 AC conformes,
  aucun AC orphelin** · **24/26 critères de test pleinement satisfaits**, **2 partiels** (#20, #21)
  bloqués **uniquement** sur l'absence de PR → @DevOps.
- **Honnêteté du périmètre** : l'US **n'affirme nulle part** que `main` est protégée ; l'inférence de
  l'AC-1 fait (b) est écrite **explicitement comme telle** ; l'exhaustivité du balayage **n'est plus
  revendiquée** ; `main` est **intacte** (`801a046`) et **aucun** test négatif n'a été exécuté.
- **Enforcement intact** : seuls `factory.config.json` et `scripts/factory_sync.py` modifiés, **par
  l'humain**, sans affaiblir aucune logique de détection.

**Condition que je transmets au rituel `/certify` (@Architect — Art. 5, la certification `🚀 OUI` ne
m'appartient pas)** :

1. **É-1 / T22 — à exécuter avant `/certify`** : `scripts/githooks/pre-push:2-3` porte encore la fausse
   affirmation que l'US existe pour éliminer, dans l'élément (a) de son propre AC-7. Action humaine,
   diff exact fourni en T22.
2. **É-2 / T6 — opportuniste**, à faire dans la même passe (coût nul, non bloquant).
3. **@DevOps** : à l'ouverture de la PR, lever les critères **#20** (4 status checks **rapportés** verts
   — *rapportés, non bloquants* : les lire activement, aucune barrière ne le fera) et **#21**
   (`gitleaks` vert dans le job `secrets-scan`).

→ **`EVT_QA_PASSED`.**
