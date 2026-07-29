# Preuves — US-00.7 · Protection de la branche principale : application effective, preuve par l'effet, cohérence du corpus

> ## ✅ `main` **EST PROTÉGÉE** — appliquée le **2026-07-28**
>
> `GET …/branches/main` → **`"protected": true"`** · `GET …/branches/main/protection` → **200** portant la
> cible générée · `python scripts/factory_sync.py --check-remote` → **exit 0 RÉEL** (12 champs alignés,
> 0 écart) · **3 refus émis par le SERVEUR** depuis un clone sans hooks.
> *(Cet index remplace l'index partiel de phase 0, qui portait — **exactement** — l'avertissement inverse.)*

> 🔴 **Distinction à ne JAMAIS perdre en audit — trois familles de fichiers, jamais interchangeables :**
> * **ÉTAT RÉEL** : `entry_state/**` et `applied_state/**` — réponses **brutes** d'API (`GET` seuls),
>   horodatées **UTC**, en-têtées de leur **commande exacte**, **sans** préfixe `[SIMULATION]`.
> * **SIMULATIONS** : `nb1_fix.md` et tout `tests/fixtures/US-00.7/**` — **chaque** ligne de sortie de
>   comparateur y porte `[SIMULATION] `. **Jamais** une preuve d'état réel.
> * **ANALYSES ET PROCÉDURES** : `labels_verification.md`, `rollback_main.md`, `rollback_plan.md`,
>   `corpus_sweep.md`, `transmissions.md`, `non_regression.md` — raisonnements et inventaires, qui
>   **citent** les preuves sans en être.

| Champ | Valeur |
|---|---|
| Branche | `feat/US-00.7-application-protection-branche` *(basée sur `main` = `f4400ca`)* |
| Phases couvertes | **0** (préalables) · **1** (application) · **2 partielle** (test négatif) · **3** (corpus) · **4** (clôture) |
| Dates | phase 0 : **2026-07-27** · phases 1-2 : **2026-07-28** · phases 3-4 : **2026-07-28** |
| `origin/main` | **`f4400ca2edd5a53e8879a7568818650eeb32d0d4`** — **inchangée sur tout le cycle** |
| Opérations à confirmation humaine explicite | **T8** (le `PUT`) et **T10** (test négatif) — **exécutées par l'humain**, jamais par l'agent |
| ⛔ **Non exécuté** | **T11** (PR · libellés rapportés · refus de fusion · fusion après 4 verts) |
| ✅ **Exécuté depuis** *(mise à jour du 2026-07-28)* | **T20** — `scripts/githooks/pre-push`, **Art. 6**, **copie humaine** → `t20_pre_push.md` · **T24** — ADR-007 **rédigé et `Accepté`** (`EVT_ARCHI_VALIDATED`) |
| 🟠 **Preuve PARTIELLE, assumée** *(arbitrage humain du 2026-07-28)* | **Critères 20 et 21** — `negative_test_server.txt` **ne contient pas** : la sortie de `core.hooksPath`, le couple `rev-parse` avant/après, la preuve de suppression du clone, la garde de sûreté avant **chacune** des 3 commandes, ni la phrase de portée. ⛔ **Non retro-archivables** (le clone jetable n'existe plus) et **le fichier n'est PAS retouché** — l'y ajouter serait **fabriquer une preuve**. Détail en regard des critères dans le Story File |

---

## 1. Ce qui est PROUVÉ — et rien de plus

| # | Fait prouvé | Fichier de preuve |
|---|---|---|
| **P1** | `"protected": true` sur `main` | `applied_state/branch_main_after.json` |
| **P2** | La règle en vigueur est **exactement** la cible générée : `strict: true` · **4** contextes · `required_pull_request_reviews` **présent** avec `0` · `enforce_admins.enabled: true` · `required_conversation_resolution: true` · `allow_force_pushes: false` · `allow_deletions: false` · `required_linear_history: false` · `restrictions` **absente** | `applied_state/protection_applied.json` |
| **P3** | L'**administrateur est inclus** — `required_status_checks.enforcement_level: "everyone"` | `applied_state/branch_main_after.json` |
| **P4** | Comparaison config ↔ dépôt réel **conforme** : **12** champs alignés, **0** écart, **7** champs additionnels neutres **nommés**, **0** champ **ACTIF** non couvert · **exit 0 RÉEL**, ni `[SIMULATION]`, ni « SOURCE SIMULÉE » | `applied_state/check_remote_exit0_reel.txt` |
| **P5** | **EFFET** : les 3 opérations d'écriture directe sur `main` **refusées par le SERVEUR**, depuis un clone **sans hooks** — `GH006 Protected branch update failed` · « *Changes must be made through a pull request* » · « ***4 of 4 required status checks are expected*** » · `protected branch hook declined` · suppression → « *refusing to delete the current branch* ». `origin/main` **identique avant/après** | `applied_state/negative_test_server.txt` |

### 🔴 Ce qui n'est PAS prouvé — à lire AVANT tout audit

1. ✅ **PÉRIMÉ-2026-07-29 — LE REFUS DE FUSION EST PROUVÉ, PAR LE SERVEUR.** *(Cet énoncé affirmait le
   contraire ; il était exact jusqu'au matin du 2026-07-29.)* PR **#14**, `08:49:14Z`, **par l'humain**,
   **1/4** contexte vert → `gh api -X PUT …/pulls/14/merge` → **HTTP 405**, *« 3 of 4 required status
   checks are expected »*. **`gh api` est un transport HTTP** ⇒ refus **serveur**, pas client.
   **Administrateur inclus**, `main` inchangée, **aucun `--admin`**. Acceptation à **4/4** prouvée par
   `{"merged": true}` (PR #13) ⇒ **AC-4 nominal COMPLET**.
   Preuve : [`applied_state/merge_refusal_server_405.txt`](applied_state/merge_refusal_server_405.txt).
   ⚠️ **Borne subsistante** : contextes **`expected`**, **pas `failing`**.
2. **`allow_force_pushes: false`** et **`allow_deletions: false`** ne sont **pas isolés** par le test
   négatif : le **même** `GH006` sort pour le force-push (la règle « PR obligatoire » se déclenche avant),
   et GitHub refuse la suppression de la **branche par défaut** indépendamment du réglage. Prouvés par
   l'**état de l'API** (P2), **pas** par l'effet.
3. Rien n'est prouvé pour un **autre acteur**, un **jeton d'application**, l'**interface web**, une PR
   issue d'un **fork** ou **réouverte**, ni pour la **persistance** de l'état.
4. ⚠️ **CONDITIONNEL** : tout dépend de la **visibilité PUBLIQUE** du dépôt. Retour en privé ⇒ retour du
   **403** ⇒ protection **indisponible** ⇒ **dérogation rouverte**.

### 🎁 Un résultat non programmé

« **4 of 4 required status checks are expected** » est une **LECTURE DIRECTE** de ce qu'US-00.4 ne pouvait
établir que par **INFÉRENCE** (son AC-1 fait **(b)**, explicitement déclaré comme une inférence et non
comme une lecture d'API). **L'inférence d'US-00.4 est CONFIRMÉE A POSTERIORI** — sans qu'une seule ligne de
son texte ait eu besoin d'être corrigée. C'est la **deuxième** fois que son honnêteté méthodologique est
récompensée par la réalité, après la désambiguïsation du **404** (**R3**, clos par l'observation).
Détail : `transmissions.md` §1 · `docs/GIT_PROTECTION.md` (encadré du 2026-07-28).

---

## 2. État des **24 tâches**

| Tâche | Description | Statut | Preuve / renvoi |
|---|---|---|---|
| **T1** | Correctif **NB-1** (3 lignes) + démonstration **avant/après** + **13 chemins d'US-00.4 rejoués** sans changement d'issue | ✅ | `nb1_fix.md` §2, §4, §5, §6 · `tests/fixtures/US-00.7/**` |
| **T2** | Contrôle compensatoire de **complétude de la cible** — `set(payload) == MAPPED_TOP_KEYS` → **`True`** | ✅ | `nb1_fix.md` §7 · re-vérifié `non_regression.md` §1.6 |
| **T3** | **4 libellés vérifiés caractère par caractère** (points de code, `U+FE0F`, NFC) + `--check` **exit 0** | ✅ | `labels_verification.md` |
| **T4** | **État d'entrée archivé** — 6 réponses brutes datées UTC, `GET` seuls · **404 ≠ 403** · **R3 CLOS** | ✅ | `entry_state/` |
| **T5** | **Sauvegarde de `main`** (SHA + clone miroir) + **3 procédures de restauration** écrites **avant** T10 | ✅ | `rollback_main.md` |
| **T6** | **Plan de retour arrière** écrit **AVANT** le `PUT` | ✅ | `rollback_plan.md` → **inséré** dans `docs/GIT_PROTECTION.md` §🛟 par @Architect le 2026-07-27, **avant** le `PUT` ; **conservé et renforcé** par T14 |
| **T7** | **Balayage inverse** — 2 passes + 1 complémentaire, **toutes extensions**, **10 angles morts déclarés** | ✅ | `corpus_sweep.md` |
| **T8** | 🔴 **LE `PUT`** — appliquer la protection depuis la source unique | ✅ **2026-07-28** | **[confirmation humaine explicite]** — payload **généré** par `--emit-branch-protection`, consommé par `apply_branch_protection.sh`. Accepté |
| **T9** | **Prouver l'état appliqué** — `protected: true` · `GET` 200 conforme · **exit 0 RÉEL** | ✅ | `applied_state/branch_main_after.json` · `protection_applied.json` · `check_remote_exit0_reel.txt` |
| **T10** | 🔴 **TEST NÉGATIF SERVEUR** — 3 refus, clone sans hooks | ✅ **2026-07-28** | **[confirmation humaine explicite]** — `applied_state/negative_test_server.txt`. **Incident de procédure consigné, non masqué** |
| **T11** | 4 status checks démontrés **BLOQUANTS sur la PR**, administrateur inclus | ⛔ **NON EXÉCUTÉE** | Exige une **PR ouverte** + une **tentative de fusion réelle** → @DevOps + confirmation humaine. Critères **25 → 27**, DoD **2/13/14/34** |
| **T12** | **`CLAUDE.md`** — état appliqué, périmètre **exact** de la règle 2, dettes, extinction de la dérogation | ✅ | `git diff CLAUDE.md` · ⛔ **règle 2 (l. 14-30) NON éditée** — elle est devenue **vraie telle quelle** |
| **T13** | **`docs/epics/EPIC_00-fondations.md`** — réserve **levée**, ligne barrée **rétablie et cochée**, **risques #2 et #5 CLOS**, critère de clôture **coché** | ✅ | `git diff docs/epics/EPIC_00-fondations.md` · ⛔ EPIC_00 **n'est pas** déclarée complète |
| **T14** | **`docs/GIT_PROTECTION.md`** — en-tête, constat **historisé**, §*Ce qui protège*, déblocage, **§Cible APPLIQUÉE**, 3 issues, config manuelle, **§Dettes (12 lignes)**, **§Conditions de fusion (R-4)** | ✅ | `git diff docs/GIT_PROTECTION.md` · ⛔ bloc `FACTORY_SYNC` **NON édité** (`--check` **exit 0**) · §🛟 **conservé et renforcé** |
| **T15** | **`.github/workflows/ci.yml`** — en-tête seul | ✅ | ⛔ **aucun** `on:`/`jobs:`/`name:`/`permissions:` modifié (vérifié) · ⚠️ **régression introduite puis corrigée** : `non_regression.md` §6.2 |
| **T16** | **`scripts/apply_branch_protection.sh`** — en-tête seul | ✅ | ⛔ **logique `PUT` intacte** — le script vient d'être **validé en production** |
| **T17** | **`scripts/check_branch_protection.py`** — docstring | ✅ | ⛔ tableau d'attribution HTTP, `PLAN_MARKER`, §*Frontière de couverture* **intacts** · ⚠️ **angle mort #7 matérialisé** : `non_regression.md` §6.1 |
| **T18** | **Rituels** — `audit-methodo.md` (point 1 bis **conservé et RÉORIENTÉ**, 6 points) · `sprint-status.md` (**exit 0 = état attendu**) | ✅ | `git diff .claude/commands/` |
| **T19** | **`docs/SQUAD_GUIDE.md`** (étages 1-3, Mermaid, roadmap) · **`tests/fixtures/US-00.4/README.md`** (**additif seul : 27+/0−**) | ✅ | `non_regression.md` §3.1 |
| **T20** | 🔒 **`scripts/githooks/pre-push`** — en-tête **devenu faux** | ✅ **FAIT le 2026-07-28** *(action humaine, Art. 6)* | **Diff appliqué** : celui de `transmissions.md` §8 — **pas** celui du Story File *(2 inexactitudes : date de l'application, chemin de preuve inexistant)*. Preuves et vérifications : [`t20_pre_push.md`](t20_pre_push.md) — un seul hunk, blob identique à la proposition, LF pur, logique **exercée sans réseau** |
| **T21** | **ÉTEINDRE la dérogation `EVT_WAIVER_GRANTED`** | ✅ | Consignée **datée** aux **3** emplacements : `CLAUDE.md` · `docs/GIT_PROTECTION.md` · `EPIC_00` **risque #5**. ⛔ Trace **non réécrite** (`git diff docs/trace/` **vide**). ⚠️ Extinction **DOCUMENTAIRE** → **dette du système de traçabilité** |
| **T22** | **Transmissions nommées** | ✅ | `transmissions.md` — 11 sections |
| **T23** | **Non-régression, re-balayage, index** | ✅ | `non_regression.md` + le présent fichier |
| **T24** | **ADR-007** *(hors périmètre @Developer)* | ✅ | `docs/adr/ADR-007-application-protection-branche.md` — **remplace ADR-006**, non modifié par @Developer |

---

## 3. Fichiers

### 3.1 `entry_state/` — **état réel**, avant l'application *(2026-07-27)*

| Fichier | Contenu |
|---|---|
| `repo_context.json` | `{"private": false, "visibility": "public", "owner_type": "User"}` + `permissions.admin: true` |
| `protection_404.json` | `GET …/branches/main/protection` → **404 « Branch not protected »** *(et non plus 403)* |
| `protection_404.stderr.txt` | stderr de `gh` + explication de son **exit 1** *(= la preuve attendue, pas un échec de tâche)* |
| `rulesets_200_empty.json` | `GET …/rulesets` → **200 `[]`** *(disponibles — écartés par **sobriété**, ADR-007 D4)* |
| `branch_main_before.json` | `{"name": "main", "protected": false}` |
| `check_remote_exit1.txt` | `--check-remote` → **exit 1**, `protection ABSENTE`, **7 écarts**, `gh` vérifié présent (R-10) |

> **Ces fichiers restent VRAIS à leur date.** Ils datent le **fait nouveau** (404 ≠ 403) et **closent
> R3** d'US-00.4 (« chemin 404 non observable in vivo »). ⛔ **Ne jamais les lire comme l'état courant.**

### 3.2 `applied_state/` — **état réel**, après l'application *(2026-07-28)*

| Fichier | Contenu | ⚠️ Nom annoncé par le Story File |
|---|---|---|
| `branch_main_after.json` | `"protected": true` + `enforcement_level: "everyone"` + les 4 contextes | *(`branch_after.json`)* |
| `protection_applied.json` | `GET …/protection` → **200**, cible **exacte**, `restrictions` **absente** | *(`protection_after.json`)* |
| `check_remote_exit0_reel.txt` | **exit 0 RÉEL** — 12 alignés / 0 écart / 7 neutres nommés / **0 champ ACTIF non couvert** | *(`check_remote_exit0.txt`)* |
| `negative_test_server.txt` | **3 refus SERVEUR** bruts + **attribution honnête** + **incident de procédure consigné** | *(`negative_test.md`, à la racine)* |

> ⚠️ **Écart de nommage assumé (É-2)** : les fichiers **n'ont pas été renommés** — ce sont des preuves déjà
> commitées. La correspondance est donnée ci-dessus. **Conséquence** : le diff de T20 du Story File renvoie
> à un fichier **inexistant** → corrigé dans `transmissions.md` §8.

### 3.3 Simulations, analyses et procédures

| Fichier | Contenu | Nature |
|---|---|---|
| `nb1_fix.md` | T1 + T2 : diff exact, **4 scénarios** avant/après, **13 rejeux**, complétude de la cible, **NB-1bis** | **simulations** |
| `labels_verification.md` | T3 : **points de code** des 4 libellés, appariement config ↔ workflows, **limite** de `--check` | analyse |
| `rollback_main.md` | T5 : SHA `f4400ca`, chemin du miroir, **3** procédures de restauration, contrôle de garde de T10 | procédure |
| `rollback_plan.md` | T6 : plan de retour arrière en cas de **verrouillage** + point d'insertion | procédure |
| `corpus_sweep.md` | T7 : 2 passes + 1, **11 artefacts vivants confirmés** + **3 ledgers** transmis, **10 angles morts** | inventaire |
| `transmissions.md` | T22 : socle de preuve · US-00.5 **réduite** · US-00.1 · **11 dettes ouvertes** · dérogation · `TRACKS.md` · **diff T20 corrigé** · **3 faux positifs de hook** · **3 ledgers** | transmissions |
| `non_regression.md` | T23 : gates réels · **contrôles négatifs** · `git diff` fichier par fichier · **2 passes rejouées** · **11 écarts** | contrôle |

---

## 4. Dérogation `EVT_WAIVER_GRANTED` — **ÉTEINTE / SANS OBJET au 2026-07-28**

Elle portait sur « **ni upgrade GitHub Pro, ni passage du dépôt en public** » (2026-07-26, US-00.4,
Constitution Art. 5). **L'humain a choisi la voie (a) — dépôt public — le 2026-07-27**, et la protection a
été appliquée le **2026-07-28**. Son **motif n'existe plus**.

⛔ **La trace est append-only** : l'événement du 2026-07-26 n'est **ni supprimé, ni édité, ni réécrit**.
**On éteint une dérogation ; on ne l'effface pas.**

🔴 **L'extinction est DOCUMENTAIRE, et c'est une DETTE** : **aucun** des **25** événements du catalogue
(+ 4 alias dépréciés) ne permet de révoquer, éteindre ou faire expirer une dérogation → **une dérogation y
est irrévocable par construction**. **Corollaire** : le champ `emitter` (`"human"` pour
`EVT_WAIVER_GRANTED`) n'est lu par **aucun** script ni hook → **un agent peut émettre une dérogation qu'il
ne peut pas éteindre**. Détail : `transmissions.md` §5.

---

## 5. Dettes — **11 OUVERTES** (dont **4 nouvelles**) · **6 closes ou sans objet**

**OUVERTES** *(numéros de `docs/GIT_PROTECTION.md` §Dettes)* : **#2** aucune détection automatique de
dérive *(aggravée)* · **#4** `grandfathering_date` · **#5** périmètre Art. 6 déclaré ≠ appliqué
*(aggravée)* · **#7** revue humaine du track FULL sans barrière machine *(inchangée)* · **#8** point de
contrôle sans déclencheur calendaire *(devenue la plus critique)* · **#9** repli `urllib` *(moitié close)* ·
🆕 **#10 `NB-1bis`** · 🆕 **#11** pas de `selftest` CI · 🆕 **#12** aucun événement d'extinction +
`emitter` non lu · 🆕 **#13** `TRACKS.md:14` (« admin » → « **applicative** ») · 🆕 **#14** 3 faux positifs
de `block_dangerous_bash.sh`.

**CLOSES / SANS OBJET, chacune avec sa preuve** : **R3** d'US-00.4 · **écart de preuve n° 3** d'US-00.4 ·
**risques #2 et #5 d'EPIC_00** · **critère de clôture** d'EPIC_00 · dettes **#1**, **#3**, **#6** de
`GIT_PROTECTION.md`.

⛔ **NB-1 est CORRIGÉ mais PAS FERMÉ** — c'est un **progrès strict**, non une fermeture.

---

## 6. Ce que ce répertoire n'établit pas

* ✅ **PÉRIMÉ-2026-07-29 — le refus de FUSION EST prouvé** *(PR #14, HTTP 405, refus **serveur**)*.
  ~~**PÉRIMÉ-2026-07-29** — Le refus de FUSION n'est pas prouvé, **T11** non exécutée.~~ Le refus **également** prouvé porte sur le **push
  direct**.
* ~~**`scripts/githooks/pre-push` porte encore 3 affirmations fausses**~~ → **CORRIGÉ le 2026-07-28**
  par **T20** (action humaine, Art. 6) : [`t20_pre_push.md`](t20_pre_push.md). ⚠️ **`corpus_sweep.md`
  (T7) et `non_regression.md` (T23) sont ANTÉRIEURS à T20** — leurs mentions « `pre-push` reste à
  faire » et « critère 22 levé sur **9/11** » étaient **exactes à leur date** et **ne sont pas
  réécrites** *(rapports datés, Art. 3)*. **État courant : 10/11**, la 11ᵉ exception étant
  `tests/fixtures/US-00.4/README.md`, arbitrée en **historisation additive**.
* **L'exhaustivité du balayage n'est pas revendiquée** : **10 angles morts déclarés**, dont **un s'est
  matérialisé** en phase 3 (`non_regression.md` §6.1). L'angle **#7** (paraphrases sémantiques) **ne se
  ferme que par relecture humaine**.
* **`gitleaks` n'a pas pu être exécuté** en phase 4 (absent du `PATH`) : le contrôle est un **balayage par
  motif**, et le critère **26** n'est levé qu'à **moitié** — reste dû au `pre-commit` et au contexte
  **requis** en CI.
* **Deux critères sont partiels** : **20** (suppression du clone jetable non attestée) et **21** (garde de
  sûreté attestée **une fois**, pas avant **chaque** commande). ⛔ **Les preuves brutes n'ont pas été
  modifiées a posteriori.**
* Les **3 ledgers** (**SCB**, **PROJECT_LOG**, **BACKLOG**) sont **hors périmètre @Developer** et n'ont pas
  été touchés — ce qui y reste à corriger est **transmis** (`transmissions.md` §10), en particulier les
  **l. 493 et 520 du SCB**.
* L'état est **daté, révocable et conditionné à la visibilité publique** du dépôt.
