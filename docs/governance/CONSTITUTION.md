# 📜 Constitution de la Factory Concentration

> Principes **non-négociables**, référencés à chaque phase du workflow (inspiré du
> `constitution.md` de GitHub Spec Kit). Chaque article indique son **enforcement** : une règle
> sans mécanisme d'application est un vœu, pas une règle. Version 1.2 — 2026-08-01.
>
> **Historique des versions** — *(la clause de Révision exige une PR dédiée, une ligne PROJECT_LOG et
> un incrément de version ; l'historique est tenu ici pour que l'incrément soit **vérifiable** et non
> seulement déclaré)* :
> * **1.0** — 2026-07-24 : version initiale.
> * **1.1** — 2026-07-31 : **Art. 4 uniquement** (US-00.5). Le corps annonçait des gates
>   **inexistants ou non bloquants** et un seuil **absent** de la configuration ; le bloc
>   *Enforcement* ne nommait **qu'un** des **deux** workflows porteurs de contextes requis. Motif
>   détaillé dans l'article. **Aucun autre article touché.**
> * **1.2** — 2026-08-01 : **Art. 4 uniquement** (US-00.6). Le cliquet de couverture est **entré en
>   vigueur** ; l'article affirmait encore le contraire. Motif détaillé dans l'article.
>   **Aucun autre article touché.**

---

## Art. 1 — Traçabilité totale

Tout commit contenant du code (extensions déclarées dans `factory.config.json` →
`governance.code_extensions`) inclut une ligne **ajoutée** au tableau de `PROJECT_LOG.md` et un
trailer `US: US-XX.X` (ou `US: none — <justification>`). Tout événement de workflow est tracé en
JSONL dans `docs/trace/US-XXX/events.jsonl` avec agent, modèle réel, rationale et preuves.
`--no-verify` est interdit.

**Enforcement** : hook git `pre-commit` + `commit-msg` (scripts/githooks) · hook Claude Code
`block_dangerous_bash.sh` (--no-verify bloqué) · CI job `governance` (`validate_trace.py --all`).

## Art. 2 — Séparation des pouvoirs

**Celui qui produit ne certifie pas.** Les audits (revue, sécurité, QA) sont réalisés par des
subagents à **contexte frais** (`.claude/agents/code-reviewer.md`, `cyber-security.md`,
`qa-tester.md`) qui n'ont pas accès à la conversation ayant produit le code. Un agent ne coche
jamais sa propre colonne d'audit dans le SCB.

**Enforcement** : rituel `/audit-us` (lance les subagents en parallèle) · `validate_trace.py`
(un visa SCB sans événement tracé par l'agent auditeur est une violation).

## Art. 3 — Preuves exécutables

Un verdict (audit, QA, certification) s'appuie sur des **exécutions d'outils reproductibles**
(les gates de l'adapter, exécutés via `python scripts/run_gates.py`) dont les sorties figurent
dans le rapport `reports/US-XXX/<type>.md`. Un visa SCB sans `evidence` dans la trace est invalide.
Un scénario E2E *skipped* n'est pas un scénario vert : les rapports QA indiquent le décompte
passed/skipped/failed.

**Enforcement** : `validate_trace.py` (existence des rapports référencés) · rituels `/audit-us`
et `/certify` (rejettent un rapport sans sortie d'outil).

## Art. 4 — Seuil qualité unique

Les seuils de couverture et les gates de qualité (**mise en forme, lint, typage statique, tests,
audit de dépendances**) sont définis en **un seul endroit** : `factory.config.json` →
`adapter.components.*.gates`, `coverage_min` **et `coverage_ratchet`**. Ils sont vérifiés par
`python scripts/factory_sync.py --check` (cohérence config ↔ fichiers de l'adapter) et exécutés
par `python scripts/run_gates.py`. **La liste des gates et leurs valeurs ne sont recopiées
nulle part** : cet article les **nomme**, la configuration en **fait foi**.

**Ce que cet article ne garantit PAS — et le taire serait un vœu, pas une règle** :

- ⛔ **Aucun gate SAST n'existe** pour le code applicatif. `actionlint` (épinglé par SHA256, job
  requis `governance`) couvre les **workflows GitHub Actions** ; **rien** ne couvre le code Dart.
  **Dette ouverte** — aucun verdict de sécurité ne peut s'adosser à une analyse statique de code.
- ⛔ **L'audit de dépendances n'est PAS bloquant** (`deps_audit` porte `"blocking": false`) et il
  mesure l'**obsolescence**, **pas la vulnérabilité** : **aucun scan de CVE n'existe**. **Dette
  ouverte.**
- ✅ **`coverage_ratchet` EST en vigueur depuis le 2026-08-01** (US-00.6). Le seuil appliqué est
  `max(coverage_min, coverage_ratchet.value)` — le gate **imprime lequel des deux décide**. La valeur
  vit **dans `factory.config.json` seul**, sous la forme `{value, date, motif}` ; elle est **lue**,
  jamais recopiée dans le code. **Enforcement** : `scripts/check_flutter_coverage.py`, appelé par le
  gate `test` du composant `app`, et **`scripts/selftest_coverage_ratchet.py`**, qui s'exécute dans
  le job **requis** `governance` et prouve **par ses propres fixtures** que le checker sait
  **refuser** — dont un contrôle **différentiel** qui rejoue la même fixture sous **deux** références
  et exige que le verdict **change**, ce qui interdit à un checker d'**écrire** sa valeur au lieu de
  la **lire**.
  ⚠️ **Bornes, car les taire serait un vœu** : le cliquet **ne monte jamais seul** — une hausse est
  **signalée** par le gate, jamais **consignée** sans une édition humaine de la configuration ·
  la mesure porte sur un dénominateur **très petit** *(grain minimal de plusieurs points)* et
  **aucune couverture de branches** n'est mesurée · ⛔ **angle mort STRUCTUREL** : un fichier source
  **non importé par un test** n'entre **pas** au dénominateur, si bien qu'ajouter du code non testé
  **ne fait pas baisser** la couverture et que **déplacer** du code non couvert vers un fichier non
  importé la **fait monter** — porté par **US-01.1**.
- ⚠️ Le gate **`build`** est **bloquant** et prouve la **constructibilité**. Sur l'adapter courant,
  il s'appuie sur une cible de **repli** : un vert signifie « le code compile pour cette cible »,
  **pas** « l'application est constructible pour sa cible de distribution ».

**Enforcement** : CI **`ci.yml`** (jobs qualité, `secrets-scan`, `governance`) **et
`branch-naming.yml`** (`check-branch-name`) — ensemble, ils portent les **quatre** contextes
**requis** par la protection de branche appliquée depuis le 2026-07-28
(`scripts/apply_branch_protection.sh`). **La liste des contextes requis n'est pas recopiée ici** :
elle vit dans `factory.config.json` → `status_checks`, **source unique**. Conséquence pratique d'un
nom de branche non conforme — **PR définitivement infusionnable** : voir
[`docs/GIT_PROTECTION.md`](../GIT_PROTECTION.md) §*Conditions de fusion*.

> 📜 **Amendement du 2026-07-31 (US-00.5) — motif écrit, comme l'exige la clause de Révision.**
> Le corps de cet article annonçait des **gates bloquants « SAST »** et un **audit de dépendances
> bloquant** qui **n'existent pas comme tels**, et citait **`coverage_ratchet`** comme seuil en
> vigueur alors que la clé est **absente** de la configuration. Établi **par exécution**, non par
> lecture : `run_gates.py --gate sast` rend « *aucun gate ne correspond* ».
> ⚠️ **Le plus grave n'est pas l'erreur, c'est sa durée** : l'article était faux **depuis le
> 2026-07-24, premier jour du projet**, et l'absence de SAST était **déjà consignée dans un rapport
> de sécurité dès le 2026-07-26**. **Aucun des cinq audits de sécurité qui l'ont constatée n'a
> jamais ouvert cet article.** La factory a **su** et **affirmé le contraire simultanément**, en
> certifiant cinq US — dont US-00.7, dont l'objet même était la cohérence du corpus.
> ⛔ **Cet amendement ne crée aucun gate** : il fait dire à l'article ce qui **est**, et **nomme les
> dettes** au lieu de les taire. Le bloc *Enforcement* nommait par ailleurs `ci.yml` **seul**, alors
> que le **4ᵉ** contexte requis — celui qui rend une PR *définitivement* infusionnable — provient de
> `branch-naming.yml`. Décision de stack associée : [ADR-001](../adr/ADR-001-choix-de-stack.md).

> 📜 **Amendement du 2026-08-01 (US-00.6) — motif écrit, comme l'exige la clause de Révision.**
> Le cliquet de couverture est **entré en vigueur** ; la clause qui le décrivait affirmait encore
> **trois choses devenues fausses** — qu'il *« n'est pas en vigueur »*, que la clé serait *« absente
> de `factory.config.json` »*, et qu'elle *« n'y est lue que pour un composant `frontend` »*.
> Établi **par exécution**, non par lecture : la clé porte `{value: 89.4, date, motif}`, le gate
> imprime « *seuil requis : 89.4% (cliquet)* », et `factory_sync.py` la valide pour le composant
> `app`. La **quatrième** clause — *« son activation exige du code »* — était **exacte** : 32 lignes
> ont été ajoutées à `factory_sync.py`, en ajout pur.
> ⛔ **Cet amendement ne crée aucun gate** : le gate existait **avant** lui. Il fait dire à l'article
> ce qui **est** — et il corrige une **sous-affirmation**, c'est-à-dire un texte qui déclarait la
> couverture **non protégée** alors qu'elle l'**est**. C'est la classe de défaut exacte qu'US-00.7 a
> payée **cinq fois** ; elle est ici traitée **avant** d'être découverte par un audit.
> ⚠️ **Ce qu'il ne corrige pas, délibérément** : [ADR-001](../adr/ADR-001-choix-de-stack.md) §4 porte
> les **mêmes** clauses et **ne sera pas réécrit** — un ADR est **immuable**, et son §*Conséquences*
> décrivait l'état du monde **à sa date**. **L'immuabilité existe précisément pour qu'on ne repeigne
> pas l'histoire** : il est **nommé ici**, jamais corrigé. **Aucun ADR-008** n'est ouvert, la
> **décision** d'ADR-001 étant inchangée — c'est son **constat** qui a vieilli, pas son choix.

## Art. 5 — Autorité de certification

- **@QA_Tester** délivre `🧪 PASS` (constat outillé, jamais plus).
- **@DevOps_Engineer** constate `🚀 DEPLOYED` (health-check vert, jamais plus).
- **@Architect** appose `Certifié Prod = 🚀 OUI` **si et seulement si** le rituel `/certify`
  (gate scripté) passe — y compris `Déploiement = 🚀 DEPLOYED`. L'Architecte n'a pas le pouvoir
  de passer outre le script.
- Toute dérogation est **humaine uniquement**, tracée `EVT_WAIVER_GRANTED` avec justification.

**Enforcement** : `check_scb_compliance.py` (règle `🚀 OUI ⇒ DEPLOYED`) en PostToolUse,
pre-commit et CI · machine à états de `trace_append.py` (préconditions d'`EVT_CERTIFIED_PROD`).

## Art. 6 — Secrets et fichiers d'enforcement

Les secrets ne vivent que dans les variables d'environnement de la plateforme d'hébergement et les
`.env` locaux jamais commités. Les fichiers d'enforcement (`scripts/githooks/`,
`.claude/settings.json`, `.claude/hooks/`, `.gitleaks.toml`, `factory.config.json`,
`scripts/factory_env.sh`) ne sont modifiables que par action humaine explicite.

**Enforcement** : gitleaks (pre-commit + CI `secrets-scan`) · hook `protect_files.sh` ·
`.gitignore`.

## Art. 7 — Workflow scale-adaptive

Chaque US passe par un track proportionné à son risque — QUICK, STANDARD ou FULL — choisi sur
critères objectifs à la création (`/us-new`) et tracé `EVT_TRACK_SELECTED`.
Définitions : `docs/governance/TRACKS.md`.

**Enforcement** : rituel `/us-new` · `validate_trace.py` (présence de l'événement).

## Art. 8 — Spécification avant code

Aucun développement ne démarre sans Story File complet (AC Nominal/Erreur/Limite + Gherkin) et
`EVT_DESIGN_COMPLETED` tracé. Les Story Files **rétroactifs sont interdits** : le Story File
précède le code (spec-driven). Gates pré-développement : clarify → checklist → analyze (intégrés
à `/us-new`).

**Enforcement** : subagent `developer.md` (refus explicite sans EVT_DESIGN_COMPLETED) ·
machine à états (EVT_CODE_READY exige EVT_DESIGN_COMPLETED).

---

## Révision

La Constitution s'amende par PR dédiée approuvée par l'humain (jamais en side-effect d'une US),
avec ligne PROJECT_LOG et incrément de version. Le rituel `/audit-methodo` (périodique) évalue
l'application réelle de chaque article et propose des amendements.
