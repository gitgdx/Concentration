# US-00.7 · T23 — **Non-régression, re-balayage et écarts** (phases 3-4)

| Champ | Valeur |
|---|---|
| Tâche | **T23** — phase 4 (clôture) |
| Date | **2026-07-28** |
| Branche | `feat/US-00.7-application-protection-branche` |
| `origin/main` | **`f4400ca2edd5a53e8879a7568818650eeb32d0d4`** — **INCHANGÉE** *(aucune écriture distante n'a été émise en phases 3-4)* |
| Écritures distantes en phases 3-4 | **AUCUNE.** Aucun `PUT`/`POST`/`PATCH`/`DELETE`, aucun `git push`, aucun nouveau test négatif |
| Portée | **T12 → T19, T21, T22, T23.** ⛔ **T20 est une action humaine (Art. 6)** — diff exact fourni dans [`transmissions.md`](transmissions.md) §8. **T11 non exécutée** |

> ⛔ **Ce document ne conclut rien qu'il n'ait exécuté.** Chaque sortie est collée **telle quelle**.
> ⛔ **L'exhaustivité du balayage n'est pas revendiquée** — voir §5 et les **10 angles morts déclarés**
> de [`corpus_sweep.md`](corpus_sweep.md) §2, dont deux se sont **matérialisés** pendant cette phase (§6).

---

## 1. Gates et contrôles de gouvernance — sorties réelles

### 1.1 `python scripts/factory_sync.py --check` → **exit 0**

```text
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
EXIT=0
```

**Ce que cela prouve** : le bloc `<!-- FACTORY_SYNC:BEGIN/END -->` de `docs/GIT_PROTECTION.md` **n'a pas
été édité à la main** malgré la réécriture lourde du fichier, et les **4 libellés** résolvent toujours
vers un `name:` de job (ou un **ID de job** pour `check-branch-name`, qui n'a pas de `name:`).
⚠️ **Sa limite, inchangée et à redire** : il compare la config au **fichier de workflow**, **jamais** au
libellé que GitHub **rapporte**.

### 1.2 `python scripts/check_scb_compliance.py` → **exit 0**

```text
Lecture du SCB : C:\Users\guillaume.decroix\MesProjets\Concentration\STORY_CERTIFICATION_BOARD.md
SCB conforme — Aucune violation détectée.
EXIT=0
```

### 1.3 `python scripts/validate_trace.py --us US-00.7` → **exit 0**

```text
Traçabilité conforme.
EXIT=0
```

### 1.4 `python scripts/run_gates.py --component app` → **exit 0**

```text
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
Compiling lib\main.dart for the Web...                             45,2s
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

### 1.5 `python scripts/run_gates.py --all` → **exit 0**

```text
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
Compiling lib\main.dart for the Web...                             40,3s
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

⚠️ **Portée réelle de ces deux gates, à ne pas surinterpréter** : cette US **ne contient aucun fichier de
code Dart**. Les gates `app` ne valent donc **que non-régression** — ils ne mesurent **rien** du livrable.
**Aucun gate de couverture Python n'existe** (`adapter.components` = `app`/Flutter uniquement) : le
correctif NB-1 et son harnais ne sont couverts par **aucun gate automatique** (dette **#11**).

### 1.6 `python scripts/factory_sync.py --emit-branch-protection` — cible **complète**, inchangée

```text
nb cles                       : 8
cles                          : ['allow_deletions', 'allow_force_pushes', 'enforce_admins',
                                 'required_conversation_resolution', 'required_linear_history',
                                 'required_pull_request_reviews', 'required_status_checks', 'restrictions']
set(payload)==MAPPED_TOP_KEYS : True
rpr present                   : True | approvals = 0
restrictions                  : None
strict                        : True
nb contextes                  : 4
  contexte : 🔐 Secrets scan (gitleaks)
  contexte : 📋 Governance (SCB + traçabilité + synchro)
  contexte : check-branch-name
  contexte : 📱 App (gates run_gates.py)
```

**Ce que cela prouve** : le **contrôle compensatoire de T2 tient toujours** — la cible **n'est pas
amputée**, donc le résidu **`NB-1bis`** reste **non atteignable** aujourd'hui. `factory.config.json` n'a
**pas** été modifié par cette US.

### 1.7 Validation des workflows — `name:`, `on:` et `permissions:` **inchangés**

```text
.github/workflows/ci.yml -> YAML VALIDE ; on = {"pull_request": null, "push": {"branches": ["main"]}}
    job id = secrets-scan | name = '🔐 Secrets scan (gitleaks)' | permissions = {'contents': 'read', 'pull-requests': 'write'}
    job id = governance | name = '📋 Governance (SCB + traçabilité + synchro)' | permissions = None
    job id = app-quality | name = '📱 App (gates run_gates.py)' | permissions = None
.github/workflows/branch-naming.yml -> YAML VALIDE ; on = {"push": {"branches-ignore": ["main"]}, "pull_request": {"types": ["opened", "edited", "synchronize", "reopened"]}}
    job id = check-branch-name | name = None | permissions = None
```

Contrôle ciblé sur le diff de `ci.yml` (aucune ligne structurelle touchée) :

```text
$ git diff .github/workflows/ci.yml | grep -E '^[+-](on:|jobs:|  [a-z-]+:|    name:|    permissions:|permissions:)'
(aucune ligne)
$ git diff --numstat .github/workflows/ci.yml
23  11  .github/workflows/ci.yml
```

**Seul l'en-tête de commentaires a changé.** Les 4 libellés sont **intacts** → **aucun risque de
verrouillage introduit** (R-1).

> 🟢 **Deux faits utiles relevés au passage** *(non demandés, mais ils bornent des risques du Story File)* :
> 1. `branch-naming.yml` se déclenche sur `pull_request: types: [opened, edited, synchronize, **reopened**]`
>    → le contexte `check-branch-name` **est bien rapporté sur une PR, y compris réouverte**. Le point de
>    vigilance de l'AC-8 limite (« workflow qui ne se déclenche pas sur l'événement de la PR ») est donc
>    **réduit** pour ce contexte — sans être annulé : il ne se déclenche **pas** sur `push` vers `main`.
> 2. Le job `secrets-scan` demande `permissions: {pull-requests: write}` — ce qui **confirme** la contrainte
>    **R-4** transmise : une PR issue d'un **fork** reçoit un `GITHUB_TOKEN` **restreint** et pourrait ne pas
>    obtenir cette permission, alors que ce job est un **contexte requis**.

---

## 2. Contrôles NÉGATIFS — les deux gardes qui doivent rester vides

### 2.1 Le contrôle distant reste HORS CI · aucun `selftest` ajouté

```text
$ grep -rn "check-remote" .github/workflows/
(aucun résultat — exit 1)
```

### 2.2 Lecture seule du comparateur PRÉSERVÉE

```text
$ grep -nE "-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)" scripts/check_branch_protection.py
(aucun résultat — exit 1)
```

### 2.3 `INERT_GET_KEYS` et le mapping **n'ont PAS été ajustés pour forcer le vert**

```text
$ git diff main..HEAD -- scripts/check_branch_protection.py | grep -E "^[+-].*(INERT_GET_KEYS|MAPPED_RSC_KEYS|MAPPED_PRR_KEYS|MAPPED_TOP_KEYS)"
+    la constante statique `MAPPED_TOP_KEYS` couvrait des clés que la cible ne portait pas.
-    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS, "")
+    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")
```

**Les seules modifications de code du cycle sont les 3 lignes du correctif NB-1** (T1), et rien d'autre :

```text
-def _guard_actual(actual: dict) -> tuple[list[str], list[str]]:
+def _guard_actual(actual: dict, expected: dict) -> tuple[list[str], list[str]]:
-    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS, "")
+    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")
-    neutral_ignored, uncovered_active = _guard_actual(actual)
+    neutral_ignored, uncovered_active = _guard_actual(actual, expected)
```

**`INERT_GET_KEYS` : zéro modification.** Aucune clé n'a été déplacée vers « neutre » pour obtenir l'exit 0
réel — ce qui aurait été reproduire le **finding B-2** dans l'outil de preuve lui-même.

### 2.4 L'outil reste fonctionnel après l'édition de son docstring

```text
$ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_cles_additives_neutres.json \
                                           --from-branch     tests/fixtures/US-00.4/branch_protected_true.json
EXIT=0
```

Le critère **#24 d'US-00.4** (« une clé additive **neutre** ne fait pas trébucher l'outil ») **reste vert**.

### 2.5 `core.hooksPath` du dépôt de travail — inchangé

```text
$ git config --get core.hooksPath
scripts/githooks
```

---

## 3. `git diff --stat` revu FICHIER PAR FICHIER — aucun artefact daté, certifié ou d'enforcement touché

```text
 .claude/commands/audit-methodo.md  |  64 ++++--
 .claude/commands/sprint-status.md  |  13 +-
 .github/workflows/ci.yml           |  36 ++--
 CLAUDE.md                          | 161 ++++++++++-----
 docs/GIT_PROTECTION.md             | 388 +++++++++++++++++++++++++++----------
 docs/SQUAD_GUIDE.md                |  95 +++++----
 docs/epics/EPIC_00-fondations.md   |  56 ++++--
 scripts/apply_branch_protection.sh |  21 +-
 scripts/check_branch_protection.py |  10 +-
 tests/fixtures/US-00.4/README.md   |  27 +++
 10 files changed, 622 insertions(+), 249 deletions(-)

?? reports/US-00.7/transmissions.md      (nouveau)
?? reports/US-00.7/non_regression.md     (nouveau — le présent fichier)
```

### 3.1 ⛔ **Artefacts datés / certifiés — ABSENTS du diff, donc 0 ligne modifiée**

| Artefact protégé | Présent dans le diff ? |
|---|---|
| `docs/stories/US-00.4-ci-protection-branche.md` | ❌ **non** |
| `reports/US-00.4/**` *(dont les 4 preuves brutes 403, `enforcement_gap.md`, les 6 rapports d'audit)* | ❌ **non** |
| **`docs/adr/ADR-006-protection-branche-principale.md`** — *pas même sa ligne `Statut`* | ❌ **non** |
| `docs/stories/US-00.1-secrets-scan-depot.md` | ❌ **non** |
| `tests/features/US-00.4-ci-protection-branche.feature` | ❌ **non** |
| `docs/trace/**` — `git diff docs/trace/` rend **vide** | ❌ **non** |
| `reports/US-00.3/**` | ❌ **non** |
| **`docs/adr/ADR-007-…md`** *(périmètre @Architect)* | ❌ **non** |

**Seule exception cadrée** : `tests/fixtures/US-00.4/README.md` — diff **strictement additif**, vérifié :

```text
$ git diff --numstat tests/fixtures/US-00.4/README.md
27  0   tests/fixtures/US-00.4/README.md
$ git diff -U0 tests/fixtures/US-00.4/README.md | grep -E "^-[^-]"
(aucune suppression)
```

**27 insertions, 0 suppression** — **aucune ligne existante n'a été modifiée**, conformément à l'arbitrage
@Architect (matériel de test **vivant** d'une US **certifiée** → historisation **additive** seule).

### 3.2 ⛔ **Fichiers d'enforcement — ABSENTS du diff**

| Fichier d'enforcement | Présent dans le diff ? |
|---|---|
| `factory.config.json` | ❌ **non** — la cible **n'a pas été touchée** (§1.6) |
| `scripts/factory_sync.py` · `scripts/run_gates.py` | ❌ **non** |
| `.claude/hooks/*` · `.claude/settings.json` | ❌ **non** |
| `.gitleaks.toml` · `scripts/factory_env.sh` · `scripts/install_hooks.sh` | ❌ **non** |
| **`scripts/githooks/*`** *(dont `pre-push`)* | ❌ **non** — **T20 reste à faire par l'humain** |

### 3.3 ⛔ **Les 3 LEDGERS — ABSENTS du diff** *(périmètre @Architect / @PO)*

`STORY_CERTIFICATION_BOARD.md`, `PROJECT_LOG.md`, `BACKLOG.md` : **aucune modification**.
**Ce qui y reste à corriger est transmis** dans [`transmissions.md`](transmissions.md) §10 — en particulier
les **l. 493 et 520 du SCB**, qui portent « `main` **n'est toujours pas protégée** et **ne peut pas
l'être** » **au présent**, dans un visa **daté** d'US-00.4.

---

## 4. Re-balayage — **PASSE 1** (14 motifs d'impossibilité) sur les **11 artefacts vivants**

> 🔴 **Point de méthode capital, à lire avant de compter.** Le critère de test **22** demande
> « **aucune** occurrence » des 14 motifs. **Pris au pied de la lettre, ce critère est INATTEIGNABLE — et
> son atteinte serait un DÉFAUT** : la tâche **T14** impose d'**historiser** le constat du 2026-07-26
> (« conservé comme historique, **jamais supprimé ni falsifié** »), la décision **D5** impose d'écrire
> partout la **conditionnalité** (« un retour en privé ramènerait le 403 »), et le comparateur **doit**
> conserver sa capacité à **nommer** un 403 de plan. Les trois produisent mécaniquement des
> correspondances.
>
> **Le critère est donc lu comme il doit l'être** : *zéro **affirmation d'impossibilité au présent***.
> Chaque occurrence est **classée** ci-dessous, et **aucune classe n'est laissée sans justification**.

### 4.1 Classement des **35 couples `fichier:ligne` distincts** trouvés *(état final, après toutes les corrections)*

| Classe | Occ. | Lignes exactes | Verdict |
|---|---|---|---|
| **A — assertion au PRÉSENT, hors de mon périmètre** | **2** *(3 motifs)* | `scripts/githooks/pre-push:6` *(`ne peut pas l'être` **+** `Upgrade to GitHub Pro`)*, `:11` *(`NON APPLICABLE`)* | 🔒 **T20 — action humaine, Art. 6.** Un agent en est **techniquement bloqué** par `.claude/hooks/protect_files.sh`. Diff exact **corrigé** fourni : [`transmissions.md`](transmissions.md) §8 |
| **B — assertion au PRÉSENT dont la réécriture est INTERDITE** | **1** | `tests/fixtures/US-00.4/README.md:31` — « les chemins exit 0 et exit 1 **ne sont pas observables** sur ce dépôt : 403 » | ⚖️ **Arbitrage @Architect appliqué** : historisation **additive seule**. La ligne est **démentie en amont** par l'encadré daté ajouté en **l. 3-27** — un lecteur rencontre le démenti **AVANT** l'affirmation. La réécrire falsifierait un livrable **certifié** |
| **C — citations HISTORISÉES et datées** | **11** | `GIT_PROTECTION.md:5, 6, 69, 84, 114, 541` · `EPIC_00:52, 83, 94` · `CLAUDE.md:185` · `fixtures/US-00.4/README.md:6` | ✅ **légitimes** — chacune porte sa date et son statut (`historisé`, `exact à sa date`, `CLOSE`, `devenu faux`, `validé a posteriori`). C'est **exactement** ce que T14 exige |
| **D — CONDITIONNELS (obligatoires par ADR-007 D5)** | **8** | `CLAUDE.md:89` · `GIT_PROTECTION.md:40, 346, 525` · `ci.yml:22` · `apply_branch_protection.sh:21` · `audit-methodo.md:49` · `sprint-status.md:18` | ✅ **légitimes et EXIGÉS** — « un retour en privé rendrait la protection indisponible ». Les **omettre** remplacerait une affirmation périmée par une autre |
| **E — sémantique d'OUTIL** *(messages d'erreur conditionnels)* | **10** | `check_branch_protection.py:14, 79, 80, 868, 876, 898` · `GIT_PROTECTION.md:304, 307, 326` · `audit-methodo.md:43` | ✅ **légitimes** — déjà classées telles par `corpus_sweep.md` §3.2 *(mêmes lignes, décalées de +6 par l'édition du docstring)*. Le **403 de plan reste un cas légitime de l'outil** : il **redeviendrait réel** si le dépôt repassait en privé. Les retirer **appauvrirait** l'outil |
| **F — négation explicite du motif** | **2** | `GIT_PROTECTION.md:339` et `audit-methodo.md:23` — « il **ne porte plus** la dette “`main` n'est pas protégée” » | ✅ **légitimes** — le motif est cité **pour être démenti dans la même phrase** |
| **G — homonymie (faux positif)** | **1** | `GIT_PROTECTION.md:376` — « si **le script** est indisponible » *(parle du script, pas de la protection)* | ✅ **faux positif** |
| **H — motifs à ZÉRO correspondance** | — | `impossible à cocher` · `NE PAS EXÉCUTER` · `conditionné au déblocage` · `report(é/ée) au déblocage` · `RAPPORTÉS, PAS BLOQUANTS` · `DETTE MAJEURE` | ✅ **6 motifs sur 14 totalement éliminés du corpus vivant** |

**Total : 2 + 1 + 11 + 8 + 10 + 2 + 1 = 35** — **aucune occurrence n'est laissée sans classe**.
*(Rappel de méthode : `pre-push:6` porte **deux** motifs et `EPIC_00:94` également ; le décompte
ci-dessus est en **couples `fichier:ligne` distincts**, pas en correspondances de motif.)*

### 4.2 Verdict de la passe 1

* **9 des 11 artefacts vivants** ne portent **plus aucune** affirmation d'impossibilité **au présent**.
* **2 exceptions, toutes deux DOCUMENTÉES et ARBITRÉES** : `scripts/githooks/pre-push` (**T20, humain,
  Art. 6** — diff fourni) et `tests/fixtures/US-00.4/README.md:31` (réécriture **interdite**, démenti
  **en amont**).
* **6 motifs sur 14** ont **disparu du corpus vivant**.

⚠️ **Ce que ce verdict n'établit pas** : qu'il n'y a rien d'autre. Voir §5 et §6.

---

## 5. Re-balayage — **PASSE 2** (7 motifs de SUR-AFFIRMATION) : le risque propre à cette US

```text
--- MOTIF : inviolable                → 0
--- MOTIF : tout est enforced         → 0
--- MOTIF : toutes? les règles sont   → 1  (EPIC_00:15)
--- MOTIF : chaîne de confiance       → 0
--- MOTIF : impossible à contourner   → 0
--- MOTIF : garantit                  → 1  (GIT_PROTECTION.md:548)
--- MOTIF : ne peut plus              → 1  (check_branch_protection.py:486)
```

| Occurrence | Nature | Verdict |
|---|---|---|
| `EPIC_00:15` — « L'objectif ci-dessus **ne dit pas** “toutes les règles sont enforced” » | **garde que j'ai ajoutée** | ✅ c'est l'**inverse** d'une sur-affirmation |
| `GIT_PROTECTION.md:548` — « rien **ne garantit** qu'un passage ait lieu » *(dette #8)* | **auto-limitation** | ✅ idem |
| `check_branch_protection.py:486` — « aucune clé de la réponse réelle **ne peut plus** être écartée en silence » | **affirmation technique bornée**, préexistante, vérifiée par les 13 rejeux de `nb1_fix.md` | ✅ inchangée par cette phase |

**Verdict : ZÉRO sur-affirmation** dans les 10 artefacts vivants modifiés **et** dans les 3 rapports
produits — après la correction du §5.1.

### 5.1 🔴 **Une SUR-AFFIRMATION que j'ai moi-même introduite, détectée par cette passe et corrigée**

C'est le résultat le plus utile de la passe 2, et il valide sa raison d'être. J'avais écrit dans
`docs/SQUAD_GUIDE.md` :

> « Une PR **ne peut plus être fusionnée avec la CI rouge** »

**C'était une sur-affirmation.** Ce qui est **prouvé** est que les **4 contextes sont REQUIS** (état de
l'API + lecture directe du serveur). Que la **fusion** soit refusée en **découle** logiquement, mais
**n'a pas été observée** : la tâche **T11** (PR ouverte, tentative de fusion réelle refusée, puis fusion
après 4 verts) **n'est pas exécutée**. Le refus **prouvé** porte sur le **push direct**, qui n'est **pas la
même opération**.

**Corrigé, et borné de façon uniforme dans les 4 documents concernés** :

| Fichier | Correction apportée |
|---|---|
| `docs/SQUAD_GUIDE.md` | phrase **supprimée** ; borne **(0)** ajoutée en tête de l'encadré des 3 étages, et borne explicite au §Étage 3 |
| `docs/GIT_PROTECTION.md` | §« Ce que ces preuves n'établissent PAS » **restructuré en 3 points**, dont le **point 1** est ce manque ; borne ajoutée au tableau §Ce qui protège `main` et en tête du §Conditions de fusion |
| `CLAUDE.md` | §« Ce qui n'est PAS prouvé » **restructuré en 3 puces**, la **première** étant ce manque |
| `.github/workflows/ci.yml` | « AUCUNE fusion n'est possible » → « la fusion est **CONDITIONNÉE** » + borne explicite T11 |

⚠️ **Leçon** : la passe 2 n'est pas un contrôle de forme. Sans elle, ce livrable aurait affirmé, dans
quatre documents dont le guide de la squad, un fait **non démontré** — reproduisant en sens inverse le
défaut exact que cette US existe pour éliminer (**R-6**).

---

## 6. 🔴 **Deux ANGLES MORTS DÉCLARÉS qui se sont MATÉRIALISÉS** — et une régression que j'ai introduite

### 6.1 Angle mort **#7** (paraphrase sémantique) — matérialisé

`corpus_sweep.md` §2 déclarait l'angle mort **#7** comme *« la limite irréductible … aucune liste de motifs
ne ferme cet angle — **seule une relecture humaine le ferait** »*. **Il s'est matérialisé.**

`scripts/check_branch_protection.py`, **docstring l. 36** *(numérotation d'avant correction)* :

> « il sert à exercer les chemins exit 0 et exit 1, **non observables sur ce dépôt** »

**Affirmation d'impossibilité, devenue FAUSSE** (exit 1 observé le 2026-07-27, exit 0 le 2026-07-28) —
et **AUCUN des 14 motifs ne la détecte**. Elle n'apparaît **ni** dans les 7 occurrences que
`corpus_sweep.md` §3.2 relève pour ce fichier, **ni** dans l'inventaire des lignes à corriger de T17
(qui ne cible que l. 24-25).

**Traitement** : corrigée par **lecture intégrale du docstring**, en conservant la **raison d'être** des
fixtures (les chemins ne sont **pas reproductibles à volonté** — les reproduire exigerait de **dégrader la
protection**). ⛔ **Périmètre non élargi au-delà du docstring** : tableau d'attribution HTTP, `PLAN_MARKER`
et §*Frontière de couverture* **intacts**.

**Conclusion de méthode** : le balayage par motif a **manqué** une affirmation fausse dans un artefact
**explicitement inscrit** à son inventaire. C'est la **cinquième** manifestation de la leçon d'exhaustivité
d'US-00.4, et elle confirme l'aveu de `corpus_sweep.md` : **la méthode par motif ne se referme pas
elle-même.**

### 6.2 🔴 Une **RÉGRESSION que j'ai introduite puis corrigée** : documenter un contrôle a cassé le contrôle

En rédigeant l'en-tête de `ci.yml` (**T15**), j'ai écrit la commande de vérification distante pour aider le
lecteur. **Cela a cassé un contrôle négatif du Story File** :

```text
$ grep -rn "check-remote" .github/workflows/
.github/workflows/ci.yml:21:#    `python scripts/factory_sync.py --check-remote` (exit 0 attendu).
```

Le critère **12** et **T23** exigent que ce `grep` **ne renvoie rien** — c'est la garde qui prouve que le
contrôle distant **reste hors CI** et qu'**aucun `selftest` n'a été ajouté**.

**Corrigé** : l'en-tête renvoie désormais au **§Vérification de l'état réel** de `docs/GIT_PROTECTION.md`
**sans citer le littéral**, et ajoute l'interdiction explicite de l'ajouter à un workflow. Re-vérifié :

```text
$ grep -rn "check-remote" .github/workflows/
(aucun résultat — exit 1)
```

⚠️ **C'est la MÊME famille que les 3 faux positifs de hook du §7 ci-dessous** :
**documenter une interdiction déclenche son détecteur**. Ici, le détecteur avait **raison** de se
déclencher — la garde a fonctionné, et c'est elle qui a rattrapé mon erreur. ⛔ **Je n'ai pas affaibli le
contrôle pour faire passer ma rédaction** ; j'ai changé la rédaction.

---

## 7. #14 — **3 faux positifs du hook `block_dangerous_bash.sh`** rencontrés en conditions réelles

> ⚠️ **Aucun contournement n'a été employé.** Dans les trois cas : **reformulation**, puis **changement
> d'outil** (écriture de fichier au lieu d'une commande shell). Le hook a **fait son travail**.

Détail complet, cause vérifiée dans le code du hook, et recommandation bornée :
[`transmissions.md`](transmissions.md) §9. En résumé :

| # | Cas | Cause exacte |
|---|---|---|
| **(a)** | Une **LECTURE** de `core.hooksPath` **imbriquée dans une substitution de commande** est **bloquée**, alors que le commentaire du hook (l. 36-37) affirme l'autoriser | La condition l. **39** n'accepte le motif qu'en **fin de commande** (`*($|[;&\|])`) : imbriquée, la chaîne est suivie d'une **parenthèse fermante** → la branche « lecture seule » n'est pas prise, puis le `elif` l. 43 bloque. 🔴 **Écart déclaré ≠ appliqué DANS UN HOOK D'ENFORCEMENT** |
| **(b)** | Le **littéral** du drapeau de contournement de hook, écrit **pour attester qu'il n'a PAS été employé**, déclenche le blocage | l. 21-23 : correspondance **textuelle**, sans distinction **usage** / **mention** |
| **(c)** | Les **commandes du test négatif (T10)**, citées **dans un fichier de preuve**, déclenchent les gardes « push direct » et « force-push » | l. 25-29 : `grep -qE` sur la chaîne complète, sans distinction **exécution** / **citation** |

⛔ **Hors périmètre @Developer** — `.claude/hooks/*` est **Art. 6**. **Recommandation minimale** : pour
**(a)**, soit élargir la classe de fin de motif l. 39, soit — **mieux** — corriger le **commentaire**
l. 36-37 pour qu'il décrive ce que le code fait réellement. ⚠️ **Ne pas relâcher (b) ni (c)** : le coût est
faible (changer d'outil), le bénéfice de la garde est élevé, et **un faux positif gênant vaut mieux qu'un
faux négatif silencieux.**

---

## 8. Sécurité des preuves — aucun jeton

```text
$ grep -rnE "ghp_|github_pat_|gho_|ghs_|ghu_|Authorization" reports/US-00.7/ tests/fixtures/US-00.7/
reports/US-00.7/entry_state/branch_main_before.json:7:# Redaction : aucun en-tete Authorization, aucun jeton dans ce fichier.
reports/US-00.7/entry_state/protection_404.json:7:#   idem
reports/US-00.7/entry_state/repo_context.json:7:#   idem
reports/US-00.7/entry_state/rulesets_200_empty.json:7:#   idem
tests/fixtures/US-00.7/README.md:32:Aucune donnée sensible : aucun jeton, aucun en-tête `Authorization`, `OWNER/REPO` en placeholder.
```

**Les 5 correspondances sont des AUTO-ATTESTATIONS** (« aucun en-tête `Authorization`, aucun jeton ») —
**aucun secret réel**, aucun motif de jeton GitHub. Les preuves brutes ne contiennent que des **réponses
d'API** et des **stderr** ; l'authentification passe par `gh`, jamais par un en-tête écrit.

> ⚠️ **LIMITE HONNÊTE, à ne pas maquiller** : **`gitleaks` n'est pas dans le `PATH` de cette session**
> (`command -v gitleaks` → introuvable). Je **n'ai donc PAS pu exécuter le scanner lui-même** : le contrôle
> ci-dessus est un **balayage par motif**, **plus faible** qu'un passage de `gitleaks`.
> **Ce qui reste dû** : le **hook `pre-commit`** exécute `gitleaks` au commit *(à vérifier au moment du
> commit)*, et le job **`🔐 Secrets scan (gitleaks)`** l'exécute en CI *(contexte **requis** : il ne peut
> plus être ignoré)*. Le critère **26** n'est donc **levé qu'à moitié** par ce document.

---

## 9. Récapitulatif des **11 critères 🟠 « levables après le `PUT` »** (14 → 24)

| # | Critère | État | Preuve / réserve |
|---|---|---|---|
| **14** | État d'entrée daté, **distinct du 2026-07-26** (404 ≠ 403) · R3 clos | ✅ **LEVÉ** | `entry_state/` (6 fichiers, commande + UTC) |
| **15** | Protection appliquée depuis la **SOURCE UNIQUE** | ✅ **LEVÉ** | `applied_state/branch_main_after.json` → `"protected": true` ; `PUT` émis par `apply_branch_protection.sh` |
| **16** | **Cible exacte, champ par champ** | ✅ **LEVÉ** | `applied_state/protection_applied.json` — 9 points vérifiés, `restrictions` **absente** |
| **17** | **`exit 0` RÉEL**, jamais simulé · écart de preuve n° 3 **refermé** | ✅ **LEVÉ** | `applied_state/check_remote_exit0_reel.txt` — 12 alignés / 0 écart / 0 champ actif non couvert, ni `[SIMULATION]` ni « SOURCE SIMULÉE » |
| **18** | Issues d'échec **traitées, pas contournées** | ✅ **LEVÉ** *(par vacuité + preuve négative)* | L'`exit 0` a été obtenu **du premier coup** : ni `exit 1` ni `exit 2` à traiter. Le volet **opposable** est prouvé : `INERT_GET_KEYS` et le mapping **non ajustés** (§2.3) |
| **19** | **3 refus émis par le SERVEUR** | ✅ **LEVÉ** | `applied_state/negative_test_server.txt` — `remote: error: GH006`, `protected branch hook declined` |
| **20** | Ni hook local, ni contournement · **rien n'a bougé** | 🟡 **LEVÉ avec une réserve** | Clone **sans hooks** attesté (« 0 hook exécutable, 0 configuration de hook ») ; `origin/main` **identique** (`f4400ca`) ; aucun drapeau de contournement. ⚠️ **La SUPPRESSION du clone jetable n'est pas attestée** dans le fichier de preuve → **@QA à vérifier auprès de l'humain** |
| **21** | Garde de sûreté **avant chaque** commande · portée de la preuve écrite | 🟡 **PARTIEL** | La garde est attestée **une fois** (« Garde relue immédiatement avant exécution : `protected=true`, `main=f4400ca` `»`), **pas pour chacune des 3 commandes**, et **sans** le triplet `{admins, fp, del}`. La **portée** (« à sa date », « pour l'acteur employé ») **n'est pas écrite dans le fichier de preuve** — elle l'est dans `GIT_PROTECTION.md`, `CLAUDE.md` et `transmissions.md` §0. ⛔ **Je n'ai PAS modifié le fichier de preuve brute a posteriori** |
| **22** | **0 affirmation d'impossibilité** dans les 11 artefacts vivants | 🟡 **LEVÉ sur 9/11, avec 2 exceptions documentées** | §4. Restent : `pre-push` (**T20**, humain, Art. 6) et `fixtures/US-00.4/README.md:31` (réécriture **interdite**, démenti **en amont**). ⚠️ La lecture littérale « 0 occurrence » est **incompatible** avec l'obligation d'historiser (§4, préambule) |
| **23** | **Aucun artefact daté ou certifié falsifié** | ✅ **LEVÉ** | §3.1 — 8 familles **absentes du diff** ; `fixtures/US-00.4/README.md` **27+/0−** ; `git diff docs/trace/` **vide** ; **aucun document vivant ne route vers ADR-006 comme décision courante** (tous relibellés « *remplacé par ADR-007* », sauf `pre-push:12` → **T20**) |
| **24** | Pas de sur-affirmation · dérogation **éteinte** · conditionnalité écrite | ✅ **LEVÉ** *(après la correction du §5.1)* | Passe 2 propre ; extinction datée aux **3** emplacements avec renvoi à l'événement d'origine ; `git diff docs/trace/` **vide** ; conditionnalité écrite dans **8** endroits ; `/audit-methodo` **conservé et réorienté** (6 points) |

**Bilan : 8 levés · 3 levés avec réserve explicite (20, 21, 22) · 0 en échec.**

⚠️ **Les 4 critères 🔵 (25 → 28, moitié CI) restent NON LEVÉS** : ils exigent une **PR ouverte** et une
**tentative de fusion réelle** — **T11**, non exécutée. Cases de DoD correspondantes : **2**, **13**,
**14**, **26** *(moitié CI)*, **34**.

---

## 10. Écarts constatés — tous signalés, aucun corrigé en silence

| # | Écart | Traitement |
|---|---|---|
| **É-1** | **Le Story File date l'application au 2026-07-27** (« levé le 2026-07-27 » dans T14, T16, T17, T20, et le diff de T20 dit « depuis le 2026-07-27 … la protection est APPLIQUÉE »). **Le `PUT` a eu lieu le 2026-07-28** *(preuves horodatées `2026-07-28T07:52:16Z`)*. Le Story File anticipait une exécution le 27 | ✅ **Corrigé dans les livrables** : partout **deux dates distinctes** — *dépôt public le **2026-07-27**, protection appliquée le **2026-07-28***. ⛔ Le Story File n'est pas réécrit sur ce point *(périmètre @Architect / @PO)* ; le **diff de T20 est corrigé** dans `transmissions.md` §8 |
| **É-2** | **Les noms des fichiers de preuve diffèrent de ceux annoncés** par le Story File T9/T10 : `branch_after.json` → **`branch_main_after.json`** · `protection_after.json` → **`protection_applied.json`** · `check_remote_exit0.txt` → **`check_remote_exit0_reel.txt`** · `negative_test.md` → **`applied_state/negative_test_server.txt`** *(et non à la racine de `reports/US-00.7/`)* | ✅ **Signalé, fichiers NON renommés** (preuves déjà commitées en `6932fea`/`66d2bab`). Les chemins réels sont utilisés partout et l'index [`README.md`](README.md) fait la correspondance. ⚠️ **Conséquence directe** : le diff de T20 du Story File renvoie à un **fichier inexistant** → corrigé dans `transmissions.md` §8 |
| **É-3** | **Le critère 22 est inatteignable au sens littéral** : « 0 occurrence » contredit l'obligation d'**historiser** (T14), d'écrire la **conditionnalité** (D5) et de conserver le **403 comme cas légitime** de l'outil | ✅ **Nommé et classé** (§4, préambule + 8 classes). **Aucune** occurrence laissée sans justification |
| **É-4** | **Angle mort #7 matérialisé** : une affirmation d'impossibilité **non détectable par motif** subsistait dans le docstring de `check_branch_protection.py` | ✅ **Corrigée** par relecture intégrale, périmètre **non élargi** (§6.1) |
| **É-5** | **Régression introduite par moi** : l'en-tête T15 cassait le contrôle négatif `grep -rn "check-remote" .github/workflows/` | ✅ **Corrigée sans affaiblir le contrôle** (§6.2) |
| **É-6** | **Sur-affirmation introduite par moi** : « une PR ne peut plus être fusionnée avec la CI rouge » — le refus de **fusion** n'est **pas** prouvé (T11) | ✅ **Corrigée et bornée dans 4 documents** (§5.1) |
| **É-7** | `gitleaks` **absent du `PATH`** : le contrôle du critère 26/28 est un **balayage par motif**, plus faible qu'un passage du scanner | ⚠️ **Limite écrite** (§8). Reste dû : `pre-commit` au commit, et le contexte **requis** `🔐 Secrets scan (gitleaks)` en CI |
| **É-8** | **Critère 21 partiel** : la garde de sûreté est attestée **une fois**, pas **avant chaque** commande, et la portée de la preuve n'est pas écrite **dans le fichier de preuve** | ⚠️ **Signalé** (§9). ⛔ **Preuve brute non modifiée a posteriori** — ce serait falsifier une archive |
| **É-9** | **Critère 20 partiel** : la **suppression du clone jetable** n'est pas attestée | ⚠️ **Signalé** (§9) — à confirmer par l'humain qui a exécuté T10 |
| **É-10** | **Le Story File annonce 26 événements** au catalogue ; il y en a **25** (+ 4 alias dépréciés) | ⚠️ **Signalé** (déjà relevé par ADR-007 D3). **Sans conséquence** : la conclusion est l'**absence** d'un événement d'extinction, qui est vérifiée |
| **É-11** | **`reports/US-00.7/rollback_plan.md`** (T6) était marqué « rédigé, **NON inséré** » dans l'index de phase 0 | ✅ **Résolu** : la section `## 🛟 Plan de retour arrière` **est** dans `docs/GIT_PROTECTION.md` (insérée par @Architect le 2026-07-27, **avant** le `PUT`) — **conservée et RENFORCÉE** par T14 (le risque est désormais **réel et actif**) |

---

## 11. Ce que cette phase établit — et ce qu'elle n'établit pas

**Établi** :

1. Les **9 artefacts vivants** de mon périmètre ne portent **plus aucune** affirmation d'impossibilité au
   présent ; **6 motifs sur 14** ont disparu du corpus vivant.
2. La **dérogation** est **éteinte**, datée, aux **3** emplacements exigés, avec renvoi à l'événement
   d'origine — et l'**absence d'un événement d'extinction** est nommée comme **dette structurelle**, avec
   son **corollaire** : le champ `emitter` n'étant lu par **aucun** script, **un agent peut émettre
   `EVT_WAIVER_GRANTED`**.
3. **Aucun** artefact daté, certifié ou d'enforcement n'a été touché ; les **3 ledgers** sont intacts et ce
   qui y reste à corriger est **transmis**.
4. **Aucune sur-affirmation** ne subsiste — **une a été introduite par moi et corrigée**, ce qui est la
   preuve que la passe 2 sert à quelque chose.
5. Les gates de non-régression sont **verts** (§1), et les **deux contrôles négatifs** structurants
   (contrôle distant hors CI · lecture seule du comparateur) sont **intacts** — dont un **rattrapé après
   une régression que j'avais introduite**.
6. **Onze dettes** restent explicitement **OUVERTES**, dont **quatre nouvelles** ; **aucune** n'est close
   par effet de bord.

**Non établi — et à ne pas laisser croire** :

* **Le refus d'une tentative de FUSION n'est pas prouvé** (T11 non exécutée). Seul le refus du **push
  direct** l'est.
* **`allow_force_pushes: false`** et **`allow_deletions: false`** ne sont **pas isolés** par le test
  négatif : prouvés par l'**état de l'API**, pas par l'effet.
* **`scripts/githooks/pre-push` porte encore 3 affirmations fausses** → **T20, action humaine (Art. 6)**.
* **L'exhaustivité du balayage n'est pas revendiquée** : **10 angles morts déclarés**, dont **un s'est
  matérialisé** pendant cette phase (§6.1). L'angle **#7** (paraphrases sémantiques) **ne se ferme que par
  relecture humaine**.
* **`gitleaks` n'a pas été exécuté** (absent du `PATH`) : le critère 26 n'est levé qu'à moitié.
* Tout l'édifice reste **conditionné à la visibilité PUBLIQUE** du dépôt, **révocable** par un
  administrateur, **sans aucune détection automatique**.

---

*Rédigé par @Developer — 2026-07-28. Toutes les sorties de commande de ce document ont été exécutées ; aucune n'est reconstituée.*
