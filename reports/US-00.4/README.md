# Preuves — US-00.4 · Enforcement de la branche principale : constat, vérification honnête et cible armée

Index des preuves exécutables (Constitution Art. 3). Branche : `feat/US-00.4-ci-protection-branche`.
US de **plateforme / gouvernance**, requalifiée en **CONSTAT + OUTILLAGE** après le re-cadrage du
2026-07-26 : **aucun code Dart**, un seul livrable de code (comparateur **en lecture seule**).

> ⛔ **Rien dans ce répertoire n'atteste que `main` est protégée. Elle ne l'est pas.**
> `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient **403 — « Upgrade to GitHub Pro
> or make this repository public to enable this feature. »** (dépôt privé, jeton `admin: true`).
> La cible de protection est **armée** — déclarée, prête, applicable en une commande — et **NON
> active**. Le **risque #2 d'EPIC_00 reste OUVERT** ; la certification de cette US ne le clôt pas.

> 🔴 **Distinction à ne jamais perdre de vue en audit** :
> `check_remote_exit2.txt` = **état RÉEL** du dépôt (exit 2, 403 de plan).
> `check_remote_simulated.txt` = **FIXTURES** (exits 0 et 1), **jamais** une preuve d'état réel.
> Deux fichiers **distincts** exprès (mitigation du risque **R1**) ; toute ligne du second porte le
> préfixe `[SIMULATION] `.

## État des tâches T1–T15

| Tâche | Description | Statut | Preuve |
|---|---|---|---|
| **T1** | ADR-006 réécrit en place (statut `Accepté`) | ✅ | `docs/adr/ADR-006-protection-branche-principale.md` |
| **T2** | `scripts/check_branch_protection.py` — comparateur **lecture seule**, exits 0/1/2 | ✅ | `check_remote_exit2.txt`, `check_remote_simulated.txt`, `non_regression.md` §5 |
| **T3** | Fixtures `tests/fixtures/US-00.4/` (5 fichiers + README) | ✅ | `check_remote_simulated.txt` |
| **T4** | `scripts/factory_sync.py` — libellé **DOCUMENTAIRE** + `--check-remote` (import paresseux) — *action humaine, Art. 6* | ✅ | `non_regression.md` §1, `check_remote_exit2.txt` [2/2] |
| **T5** | `scripts/apply_branch_protection.sh` — en-tête **NON APPLICABLE / conditionné au déblocage** ; logique `PUT` **inchangée** | ✅ | `false_claims_sweep.md` C7/C8 |
| **T6** | `factory.config.json` — nettoyage cosmétique — *action humaine, Art. 6* | ⏳ **due** | `non_regression.md` §Réserve T6 (`grep -nE '^  +$'` → `63:  $`) |
| **T7** | Preuves brutes du constat (AC-1) | ✅ | `branch_main_before.json`, `protection_api_403.json`, `rulesets_api_403.json`, `repo_context.json`, `check_runs.json` (+ 2 `.stderr.txt`) |
| **T8** | **Exit 2 réel** archivé tel quel | ✅ | `check_remote_exit2.txt` |
| **T9** | **Exits 0 et 1** démontrés sur fixtures (4 invocations) | ✅ | `check_remote_simulated.txt` |
| **T10** | `docs/GIT_PROTECTION.md` réécrit (constat, filet de discipline, déblocage, cible armée, vérification, dettes) | ✅ | `false_claims_sweep.md` C1→C6 ; `non_regression.md` §1 (bloc `FACTORY_SYNC` intact) |
| **T11** | Point de contrôle périodique dans `/audit-methodo` | ✅ | `.claude/commands/audit-methodo.md` §1 bis |
| **T12** | Constat, cause racine, portée, dettes | ✅ | `enforcement_gap.md` |
| **T13** | Non-régression (10 contrôles + 3 réserves) | ✅ | `non_regression.md` |
| **T14** | Relecture « aucune fausse affirmation » | ✅ | `false_claims_sweep.md` — 10 corrigées, 6 signalées hors périmètre |
| **T15** | Transmission formelle à **US-00.5** (OBLIGATOIRE) | ✅ | `enforcement_gap.md` §6 |
| **T16→T19** | Application, preuve `"protected": true`, **test négatif serveur**, checks bloquants | ⛔ **REPORTÉES — NON EXÉCUTÉES** | Interdites : sans protection, un push direct sur `main` **réussirait**. `origin/main` est resté `801a046` |
| **T20** | **Correctif B-2** — garde **symétrique** côté réponse réelle (fin du faux vert) + 4 fixtures | ✅ | `check_remote_simulated.txt` cas **[5/8]→[8/8]** · `scripts/check_branch_protection.py` §Frontière de couverture |
| **T21** | **Correctif B-1** — `ci.yml` rectifié, over-claim retiré, balayage **toutes extensions** | ✅ | `false_claims_sweep.md` **C12/S10/S11/S12** + §Méthode bis · `enforcement_gap.md` §6 quater |
| **T22** | Diff `scripts/githooks/pre-push` — *son commentaire contredit l'AC-7 dont il est l'élément (a)* | ⏳ **due** | **[action humaine]**, Art. 6 — diff exact dans le Story File §Tâches |

### Suites de l'audit `/audit-us` (contextes frais, 2026-07-26)

| Audit | Verdict | Effet sur ce répertoire |
|---|---|---|
| **Sécurité** | ✅ **PASS** — 0 bloquant | **Réserve gitleaks LEVÉE** : le binaire a été retrouvé hors `PATH` et le scan réellement exécuté → `no leaks found` sur le **working tree** et sur **30 commits**. La réserve §2 ci-dessous n'a plus cours (conservée pour la traçabilité de la méthode). |
| **Revue** | ❌ **FAILED** — 2 bloquants | **B-2** (faux vert du comparateur) et **B-1** (relecture surestimant son exhaustivité), tous deux **reproduits** par l'orchestrateur → corrigés en **T20/T21**, résiduel en **T22**. L'auditeur a par ailleurs constaté que **toutes les réserves de @Developer étaient honnêtes et qu'aucune ne masquait un défaut** — les 2 bloquants n'y figuraient pas. Rapport : `code_review.md`. |

## Fichiers de ce répertoire

| Fichier | Contenu | Nature de la preuve |
|---|---|---|
| `branch_main_before.json` | `GET /repos/gitgdx/Concentration/branches/main` → **200**, `"protected": false` | **Réponse brute** (fait a) |
| `protection_api_403.json` (+ `.stderr.txt`) | `GET …/branches/main/protection` → **403**, message de plan | **Réponse brute** (fait c) |
| `rulesets_api_403.json` (+ `.stderr.txt`) | `GET …/rulesets` → **403**, message **identique** | **Réponse brute** (fait c) |
| `repo_context.json` | `{"private": true, "visibility": "private", "owner_type": "User"}` + `{"admin": true, …}` | **Projection `--jq`** de la réponse |
| `check_runs.json` | Les **4** status checks **exécutés** et verts sur la tête de la PR #9 | **Projection `--jq`** — prouve l'**exécution**, **pas** le caractère requis |
| `check_remote_exit2.txt` | **Exit 2 RÉEL** (2 invocations) : `VERIFICATION IMPOSSIBLE — ce n'est PAS un succès`, cause **403 de plan** | Sortie d'outil sur le **dépôt réel** |
| `check_remote_simulated.txt` | **Exits 0 / 1 / 2 SIMULÉS** — **8 invocations** (4 d'origine + 4 du correctif B-2), 8/8 codes conformes à l'attendu | ⚠️ **SIMULATION** — n'atteste **rien** du réel |
| `enforcement_gap.md` | Constat (4 faits) · **cause racine** · portée bornée · **12 dettes** · **transmission à US-00.5** | Analyse adossée aux preuves |
| `non_regression.md` | 10 contrôles verts + **3 réserves explicites** | Sorties d'outils |
| `false_claims_sweep.md` | 7 balayages · **10** occurrences corrigées · **6** signalées hors périmètre | Revue outillée |

### 📌 Convention de lecture des `.json` de ce répertoire

Chaque `.json` porte un **en-tête de provenance** en lignes `#` (commande **exacte**, **horodatage
UTC**, statut HTTP, code de sortie de `gh`, mention de rédaction). Ces fichiers ne sont donc **pas du
JSON parsable en l'état** — c'est le prix de la traçabilité de la preuve, JSON n'admettant pas de
commentaires. Pour isoler le corps :

```sh
grep -v '^#' reports/US-00.4/branch_main_before.json
```

> ⚠️ **`gh` sort en code 1 sur une erreur HTTP alors que la capture est un SUCCÈS de preuve** : le
> corps JSON part sur **stdout**, le message humain sur **stderr**. Les en-têtes de
> `protection_api_403.json` et `rulesets_api_403.json` consignent explicitement `exit=1` et
> `"status":"403"`. **Ne jamais lire cet exit 1 comme un échec de tâche.**

## Réserves — ce que ce répertoire ne prouve PAS

1. **Aucune preuve d'application de la protection** — aucune n'est produite, aucune n'est exigée.
2. ~~**`gitleaks` n'était pas installé** dans la session de production des preuves~~ → **RÉSERVE LEVÉE
   par l'audit Sécurité** (2026-07-26) : binaire retrouvé hors `PATH`, scan réellement exécuté →
   `no leaks found` sur le working tree **et** sur 30 commits. *(Énoncé conservé barré : la méthode de
   substitution employée à défaut d'outil — grep de motifs — reste documentée en
   `non_regression.md` §6.)*
3. **Les 4 status checks de la PR n'ont pas pu être lus** (`gh pr checks`) : la branche n'était pas
   poussée et aucune PR n'existait au moment de T13 (`non_regression.md` §Réserve PR).
4. **Le chemin 404 et le repli `urllib`** du comparateur ne sont **jamais** validés en conditions
   réelles — fixture uniquement, et transport stdlib non exercé (dette #10).
5. **`branch_main_before.json` contient un bloc `PGP SIGNATURE`** (signature **publique** de
   vérification du commit de fusion — **pas** une clé privée) et l'e-mail **public** du committer.
   Archivé **sans troncature** : tronquer une preuve brute la disqualifierait.
