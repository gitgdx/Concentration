# CLAUDE.md — Factory Concentration

> **Constitution complète (non-négociable) : [`docs/governance/CONSTITUTION.md`](docs/governance/CONSTITUTION.md)**
> Les règles ci-dessous en sont le résumé opérationnel. Chaque règle est **enforced** par un
> mécanisme automatique (hooks git versionnés, hooks Claude Code, gates CI) — pas seulement déclarée.

## Stack

Voir [`docs/governance/STACK_PROFILE.md`](docs/governance/STACK_PROFILE.md) (déposé par l'adapter
choisi à l'initialisation) : langages, frameworks, ORM/migrations, commandes de build/lint/test.
**Qualité (gates CI bloquants, `ci.yml`)** : seuils et commandes définis dans `factory.config.json`
(`adapter.components.*.gates`), exécutés via `python scripts/run_gates.py`.

## Règles dures (enforced)

1. **Traçabilité** : tout commit de code = ligne **ajoutée** au tableau `PROJECT_LOG.md`
   (`| YYYY-MM-DD | @Agent | Modèle | Action | Statut | Fichiers |`) + trailer `US: US-XX.X`
   dans le message (`type(scope): description`). *Enforced : pre-commit + commit-msg.*
2. **Jamais** `--no-verify`, jamais de commit/push sur la branche principale, jamais d'édition de
   fichier `.env` ou d'enforcement. *Enforced : hooks Claude Code + hooks git + protection de branche.*
3. **Événements** : toute transition de workflow passe par
   `python scripts/trace_append.py --us US-XXX --event EVT_* ...` (catalogue :
   `scripts/events_catalog.json` ; la machine à états rejette les transitions illégales).
4. **SCB** (`STORY_CERTIFICATION_BOARD.md`) : cohérence vérifiée à chaque édition (hook PostToolUse),
   au commit et en CI. `Certifié Prod = 🚀 OUI` exige `Déploiement = 🚀 DEPLOYED` + rituel `/certify`.
5. **Séparation des pouvoirs** : les audits passent par `/audit-us` (subagents à contexte frais) —
   jamais d'auto-certification dans la session qui a produit le code.
6. **Synchro config** : `factory.config.json` est la source unique (branches, seuils, status checks,
   commandes qualité) — `python scripts/factory_sync.py --check` (gate CI `governance`) détecte
   toute dérive entre la config et ses projections (CI, protection de branche, seuils de fichiers).

## Workflow

Squad de 10 agents : subagents natifs dans `.claude/agents/` — **source unique** (périmètres,
outils restreints, normes du rôle, sorties obligatoires). Séquence STANDARD :
`PO → Architect → (UX + Data) → Architect (lock) → Developer → /audit-us → QA → DevOps → /certify`.
Tracks proportionnés au risque (QUICK/STANDARD/FULL) : `docs/governance/TRACKS.md`.

**Rituels** : `/us-new` (créer une US complète — les Story Files rétroactifs sont interdits) ·
`/audit-us` (audits parallèles) · `/certify` (gate scripté) · `/sprint-status` (synthèse) ·
`/audit-methodo` (audit périodique de la factory).

Sous un rôle d'agent : le déclarer (`> Rôle actif : @X`), lire son subagent (`.claude/agents/<agent>.md`), rester dans son périmètre.

## Démarrage de session

Le hook `SessionStart` injecte automatiquement les 5 dernières lignes du PROJECT_LOG et l'état de
conformité SCB. Lire ensuite le Story File de l'US concernée si applicable.

## État courant du projet *(maintenu par @Architect)*

**Chantier actif** : **US-00.5** *(ADR-001 stack + Constitution — périmètre **RÉDUIT** mais NON VIDE,
détail en Actions humaines)*, ou **US-00.6** (couverture + ratchet). Aucune US en cours de cycle.

✅ **US-00.7 CERTIFIÉE Prod 🚀 le 2026-07-30** — application de la protection de branche (track STANDARD
+ 3 renforcements). **PR #12, #13, #14 et #15 fusionnées** — `main` = **`e2bd626`** *(PR #15 fusionnée
**par l'humain** à 12:12:35Z, **sans `--admin`** : renforcement **R-c** respecté)*. **DoD 34/34** ·
Audits **✅ 🔍 ✅ 🛡️** · **QA 🧪 PASS au 6ᵉ passage, après 5 `FAIL`** aux motifs réels et **tous
différents** · **25 critères levés / 3 non levés** (20, 21, 27) · **6 gates `/certify` verts** ·
phase **`epic_closure`**. **Health-check réel** : `protected: true` **après** la fusion et
`--check-remote` **exit 0**, 0 dérive — *et la fusion elle-même prouve le mécanisme, n'ayant pu aboutir
que sur 4 checks requis verts*.
⚠️ **CE QUE CETTE CERTIFICATION N'ATTESTE PAS, à ne pas sur-lire** : les critères **20, 21, 27
DEMEURENT NON LEVÉS** *(arbitrés pour cause de **PLATEFORME**, **jamais requalifiés**)* · refus prouvé sur
contextes **`expected`, pas `failing`** · conditions de fusion **3, 4 et 5** restent **déduites** ·
**`--admin` non testé** · **0 fichier Dart** touché *(la couverture de 89,5 % atteste une
**non-régression**, pas le livrable)* · **24 scénarios Gherkin non exécutés** *(ni step definition ni
runner)* · **aucune preuve machine de provenance** · **aucune détection automatique de dérive** ·
⚠️ **tout est conditionnel à la visibilité PUBLIQUE** du dépôt.
📌 **Ce qui a débloqué 5 cycles d'échec, à réutiliser** : le 5ᵉ `FAIL` a publié un **critère de sortie
borné, falsifiable et rejouable** *(une commande de balayage dont la sortie doit être vide)*, et la QA l'a
**exécuté elle-même** au 6ᵉ passage plutôt que de juger sur relecture. **Trois leçons de méthode** en sont
issues, inscrites à [`corpus_sweep.md`](reports/US-00.7/corpus_sweep.md) : ⛔ `~~texte~~` est **invisible à
`grep`** → marqueur **littéral** `PÉRIMÉ-<date>` **sur la ligne même** · ⛔ corriger le **DÉFAUT**, pas le
**RENVOI** *(« un renvoi cite un exemple ; le défaut a une extension »)* · ⛔ **ne jamais désigner une
assertion par son NUMÉRO DE LIGNE** — il glisse en silence et la couverture cesse de couvrir sans qu'aucun
outil ne le signale. 🔍 **L'extension du motif a fermé 4 survivances que les 5 passages QA et les 4 passes
du balayage avaient TOUTES manquées** — dont la plus grave du corpus : une puce du SCB *(visa @DevOps
d'US-00.4)* **niant la protection de `main` et la déclarant impossible**, soit **cinq assertions fausses**
au cœur même de ce que cette US prouve ; elle était **dissimulée par un filtre** que la QA avait oublié de
reporter dans sa commande publiée — **faute qu'elle a reconnue elle-même**, d'où la leçon versée à
US-00.8 : **un critère de sortie se publie comme un script exécutable, jamais recopié à la main**.
⚖️ **Le critère 27 est ARBITRÉ (2026-07-29, voie a)** : son 3ᵉ
volet est **structurellement inatteignable** sur un dépôt à **un seul compte** *(`reviewDecision` vide —
GitHub interdit à l'auteur d'approuver sa propre PR)*. Il **DEMEURE NON LEVÉ** — *« un arbitrage ne lève
jamais un critère »* — **assumé pour cause de PLATEFORME, non de travail**. Levée réelle → **US-00.8**. **`main` EST PROTÉGÉE depuis le
2026-07-28** — voir l'encadré ci-dessous. **US-00.4 CERTIFIÉE Prod 🚀 le 2026-07-27** (PR #10/#11) :
elle a certifié la **valeur, l'honnêteté et la sûreté de l'outillage et du constat**, **pas** la
protection de `main` — c'est **US-00.7 qui l'applique, en prouve l'effet, et qui est certifiée**.
**Reste pour clore EPIC_00** : **US-00.5** (ADR-001 stack + Constitution — périmètre **RÉDUIT**) puis
**US-00.6** (couverture + ratchet). ⚠️ **`strict: true` SÉRIALISE les merges** → les enchaîner **une par
une**, jamais en parallèle : toute fusion périme les autres branches ouvertes. **US-00.8** (dette) n'est
**PAS** requise pour clore EPIC_00 — son report est un **choix assumé** dont le coût est que la fusion par
un agent reste **interdite** sans être **impossible**.
US-01.1 (EPIC_01, FULL) reste en pause en `business_alignment`, **à rebaser sur `main`**, et son Lock
exige d'abord l'arbitrage `TRACKS.md` ci-dessous.

> ✅ **ÉTAT DE L'ENFORCEMENT DE `main` — 2026-07-28, avec ses bornes.** La **règle 2** ci-dessus est
> désormais **VRAIE telle qu'elle est écrite** : la protection de branche est **APPLIQUÉE**. Preuves
> brutes datées : [`reports/US-00.7/applied_state/`](reports/US-00.7/applied_state/).
>
> **Périmètre EXACT de la règle 2 — ce qui est prouvé, et rien de plus** :
> * `GET …/branches/main` → **`"protected": true"`** · `GET …/branches/main/protection` → **200** portant
>   la cible **générée** depuis `factory.config.json` (`protection_applied.json`).
> * **PR obligatoire** · **4 status checks REQUIS** · **`enforce_admins` en vigueur** — l'administrateur
>   est **inclus** (`enforcement_level: "everyone"`).
> * **Effet prouvé par le SERVEUR**, depuis un clone **sans hooks** (`negative_test_server.txt`) : push
>   direct, force-push et suppression **refusés** — `GH006 Protected branch update failed`, « *Changes
>   must be made through a pull request* », « ***4 of 4 required status checks are expected*** ».
> * `python scripts/factory_sync.py --check-remote` → **exit 0 RÉEL** (12 champs alignés, 0 écart, 0
>   champ actif non couvert), **sans** préfixe `[SIMULATION]` — **première observation in vivo**.
>
> **Ce qui n'est PAS prouvé, et ne doit pas être affirmé** :
> * ✅ **Le refus d'une tentative de FUSION EST PROUVÉ — par le SERVEUR — depuis le 2026-07-29T08:49:14Z.**
>   Sur la **PR #14**, `gh api -X PUT …/pulls/14/merge` avec **1/4** contexte vert → **HTTP 405**,
>   *« **3 of 4 required status checks are expected** »*. C'est **l'API REST** qui refuse : `gh` n'est
>   qu'un transport, donc l'hypothèse d'un refus **côté client** est **écartée**. **Administrateur
>   inclus** (`admin: true` + `enforce_admins: true`) · `main` **inchangée** · **aucun `--admin`**.
>   **Les DEUX moitiés d'AC-4 sont prouvées par le serveur** : **refus** à 1/4 (HTTP 405) et
>   **acceptation** à 4/4 (`merged: true`, PR #13). Preuves :
>   [`applied_state/merge_refusal_server_405.txt`](reports/US-00.7/applied_state/merge_refusal_server_405.txt)
>   et [`merge_proof_and_violation.md`](reports/US-00.7/merge_proof_and_violation.md).
>   ⚠️ **Borne maintenue** : le refus porte sur des contextes **`expected`**, **pas `failing`** — la
>   conjonction littérale d'US-00.1 (« `secrets-scan` **rouge** → merge empêché ») **reste non observée**,
>   et ⛔ **on ne cassera pas un gate pour l'obtenir**. `--admin` **non testé**, et ne le sera pas.
> * ⛔ **VIOLATION DE WORKFLOW du 2026-07-29, actée et NON effacée** : à `07:08:59Z`, **un agent a fusionné
>   la PR #13** — enfreint la **case 34** / renforcement **R-c**. **Pas un contournement** (4 gates verts,
>   fusion licite) mais une **violation de PROVENANCE**. `EVT_WORKFLOW_VIOLATION` tracé, **case 34
>   **décochée à l'époque** — ⚠️ **PÉRIMÉ-2026-07-29 : la case 34 est depuis RECOCHÉE**, au titre d'une
>   **attestation humaine datée** *(niveau 1, assumée **déclarative**)* après la fusion de la PR #14 par
>   l'humain. **Elle ne lève pas pour autant le 3ᵉ volet du critère 27** *(`reviewDecision` vide)*.
>   A révélé que **`mergedBy.is_bot` ne prouve rien** — voir la dette « provenance » ci-dessous.
> * `allow_force_pushes: false` et `allow_deletions: false` **ne sont pas isolés** par le test négatif — le
>   **même** `GH006` sort pour le force-push (la règle « PR obligatoire » se déclenche avant), et GitHub
>   refuse la suppression de la **branche par défaut** indépendamment du réglage ; ces deux réglages sont
>   prouvés par l'**état de l'API**, pas par l'effet.
> * Rien n'est prouvé pour un **autre acteur**, un **jeton d'application**, l'**interface web**, une PR
>   issue d'un **fork** ou **réouverte**, ni pour la **persistance** de l'état (aucune détection
>   automatique de dérive — dette ci-dessous).
>
> ⚠️ **CONDITIONNEL** : tout l'édifice dépend de la **visibilité PUBLIQUE** du dépôt. Un retour en privé
> ramènerait le **403**, rendrait la protection **indisponible** et **rouvrirait la dérogation**.
>
> **Ce qui reste de la discipline** : le hook local `pre-push` — **toujours utile** (il refuse avant
> l'aller-retour réseau, et vaudrait encore si la protection était désactivée) et **toujours absent d'un
> clone frais**. Détail : [`docs/GIT_PROTECTION.md`](docs/GIT_PROTECTION.md) ·
> [ADR-007](docs/adr/ADR-007-application-protection-branche.md) *(remplace ADR-006)*.

> 🔕 **Dérogation `EVT_WAIVER_GRANTED` (2026-07-26, US-00.4, Art. 5) — ÉTEINTE / SANS OBJET au
> 2026-07-28.** Elle portait sur « **ni GitHub Pro, ni dépôt public** » ; l'humain a choisi la **voie (a)
> — dépôt public — le 2026-07-27**, et la protection a été appliquée le **2026-07-28**. Son motif
> (impossibilité de plateforme) **n'existe plus**. ⛔ **La trace n'est pas réécrite** (append-only) : on
> **éteint** une dérogation, on ne l'**effface** pas. ⚠️ **L'extinction est DOCUMENTAIRE** : **aucun** des
> **25** événements du catalogue ne permet d'éteindre une dérogation → **dette du système de traçabilité**
> (ci-dessous). **Conditionnel** : un retour du dépôt en privé **rouvrirait la question**.

**Sprint 0 (EPIC_00) : 4 US sur 6 certifiées** — US-00.1, US-00.2, US-00.3, **US-00.4** 🚀 ; **US-00.7
CERTIFIÉE 🚀 le 2026-07-30** *(hors décompte initial : EPIC_00 = US-00.1→US-00.6)* ; **restent
US-00.5** (ADR-001 stack + Constitution) et **US-00.6** (couverture + ratchet) — **ce sont les deux
seules US requises pour clore EPIC_00**. ✅ **Le critère de clôture « protection de branche vérifiée » est
désormais COCHABLE et COCHÉ**,
les **risques #2 et #5 d'EPIC_00 sont CLOS** (preuve : `reports/US-00.7/applied_state/`) →
**EPIC_00 redevient complétable après US-00.5 et US-00.6**. ⚠️ La mention « SPRINT 0 COMPLET » du
PROJECT_LOG au 2026-07-26 était **inexacte** (rectifiée en fin de tableau). US-01.1 (EPIC_01, track FULL)
reste **en pause** en `business_alignment` — à rebaser sur `main`.
**Dettes ouvertes** :
- 🟠 **Findings NON BLOQUANTS de l'audit sécurité d'US-00.7, ouverts et non traités** *(2026-07-28,
  `reports/US-00.7/security.md`)* : **aucun plancher de sécurité** — `enforce_admins: false` en config
  produirait une **CI verte** et un `--check-remote` « **conforme** », avec `0` approbation requise ·
  **NB-1bis confirmé par exécution** mais **NON exploitable par configuration** (les 8 clés sont **en
  dur** dans `emit_branch_protection` : l'amputation exige de modifier le code Python — **moins grave
  qu'annoncé jusqu'ici**) · **actions tierces non épinglées** (`actions/checkout@v4`,
  `gitleaks-action@v2` avec `pull-requests: write`) · **`emitter` non enforcé** — mais ⚠️ **ce n'est pas
  une faille d'autorisation** : agents et humain partagent le **même compte** et les **mêmes droits**,
  donc **aucune implémentation ne le rendrait infranchissable** ; le durcissement utile est la
  **détection**, pas la prévention.
- 🔴 **AUCUN SAST dans la factory** : `run_gates --gate sast` → **exit 1, ce gate n'existe pas**. Et
  `dart pub outdated` mesure l'**obsolescence**, pas la **vulnérabilité** → **aucun verdict de sécurité
  ne peut s'appuyer sur un scan de CVE, il n'y en a pas**. ✅ **Partiellement compensé le 2026-07-28** :
  `actionlint` (épinglé par SHA256) tourne désormais dans le job **requis** « 📋 Governance » — il aurait
  trouvé seul le bloquant B-1, dont son absence était la **cause racine**. Reste à décider pour le code
  applicatif Dart.
- ⚠️ **Nouvelles CONTRAINTES PERMANENTES, actives depuis le 2026-07-28** — à connaître avant de les vivre
  comme une panne : toute branche hors `^feat/US-[0-9]+\.[0-9]+.*$` rend sa PR **définitivement
  infusionnable** (`check-branch-name` est un contexte **requis**) → `chore/`, `docs/`, `hotfix/` sont
  **impossibles à fusionner**, et le **track QUICK** repose sur des noms libres · **toute PR issue d'un
  FORK** dont la branche ne suit pas ce motif est **infusionnable** (dépôt **public** : ouvert en
  proposition, fermé en fusion par sa propre convention) · une PR de fork reçoit un `GITHUB_TOKEN`
  **restreint** alors que le job `secrets-scan` exige `pull-requests: write` · `strict: true`
  **sérialise** les merges (toute fusion périme les autres branches) · `required_conversation_resolution`
  bloque sur **une seule** discussion ouverte. Détail : `docs/GIT_PROTECTION.md` §Conditions de fusion.
- 🔴 **Aucune détection automatique de dérive** config ↔ dépôt réel : `--check-remote` exige des droits
  **admin**, absents du `GITHUB_TOKEN` → contrôle **manuel et hors CI**. Un administrateur peut supprimer
  la règle **sans qu'aucun mécanisme ne le signale**. Seul porteur : `/audit-methodo`, **sans déclencheur
  calendaire** (la dette la plus susceptible de pourrir silencieusement).
- ✅ **RÉSOLU par US-00.4** : `factory_sync.py --check` annonce désormais une vérification
  **DOCUMENTAIRE** et avertit que l'état réel n'est pas vérifié ; `--check-remote` interroge l'API
  (hors CI, droits admin). **Actif sur `main`.**
- 🔴 **NB-1bis — résidu OUVERT du correctif NB-1** *(NB-1 lui-même est **CORRIGÉ** par US-00.7 :
  `_guard_actual` filtre par `MAPPED_TOP_KEYS & set(expected)`, **3 lignes** et non « une »)*. Après
  correctif, une clé absente de la cible dont la valeur réelle est **ACTIVE** est nommée et **interdit
  l'exit 0** ; mais si sa valeur est **NEUTRE** (`{"enabled": false}`) elle est **seulement nommée** et
  l'exit 0 **subsiste**, et si elle est **absente des deux côtés** elle n'est **pas même nommée** — or
  `enforce_admins: false` autorise le bypass admin et `required_pull_request_reviews` absent signifie
  **aucune PR exigée**. **Le correctif est un progrès strict, pas une fermeture.** Correctif complet
  identifié (complétude de la cible dans `_guard_mapping`), **hors périmètre**. **Compensé aujourd'hui** :
  `set(payload) == MAPPED_TOP_KEYS` → `True` (cible **non amputée**).
- 🔴 **Aucun `selftest` en CI** pour `check_branch_protection.py` : ses fixtures versionnées sont lancées
  **à la main**, y compris pour valider le correctif NB-1. Recommandation forte du re-audit d'US-00.4 —
  « c'est lui, pas le hook, qui arrête une régression » de la frontière de couverture. **Contrôle négatif
  maintenu** : `grep -rn "check-remote" .github/workflows/` doit rester **vide**.
- 🔴 **Aucun événement d'extinction de dérogation dans le catalogue** — dette **structurelle du système
  de traçabilité**, révélée par US-00.7 : ses **25** événements (+ 4 alias dépréciés) ne comportent
  **aucun** mécanisme de révocation, extinction ou expiration. Une dérogation y est donc **irrévocable par
  construction** : un audit qui ne lirait que `docs/trace/**` verrait un `EVT_WAIVER_GRANTED` **sans
  contrepartie** et pourrait croire l'exception encore active. Mitigation retenue : consignation
  documentaire (3 emplacements) + mention dans le `rationale` d'`EVT_DOCS_UPDATED` — **convention non
  enforced** (champ libre, non validé par `validate_trace.py`) : elle **réduit** le risque, elle ne le
  supprime pas. En ajouter un modifierait la **machine à états** → exige son propre ADR.
- ⚠️ **Émetteurs d'événements déclarés mais NON enforced** : le champ `emitter` de `events_catalog.json`
  n'est lu par **AUCUN** script ni hook (vérifié le 2026-07-28 : **0** occurrence dans `scripts/*.py` et
  `.claude/hooks/*`) → **un agent peut émettre n'importe quel événement sous n'importe quel rôle, y
  compris `EVT_WAIVER_GRANTED`** dont le catalogue déclare pourtant `emitter: "human"`. Corollaire direct
  de la dette précédente : le système peut **accorder** une dérogation sans humain et ne peut pas
  l'**éteindre**. Même classe de défaut que celle qu'US-00.4 dénonce, dans le système de traçabilité
  lui-même. Candidat `/audit-methodo`.
- 🔴 **PROVENANCE NON PROUVABLE — dette FUSIONNÉE avec celle de `TRACKS.md` ci-dessous, même solution.**
  Établi le 2026-07-29 par une **violation réelle** (`reports/US-00.7/merge_proof_and_violation.md`) :
  **`mergedBy.is_bot` rend `false` même pour une fusion exécutée par un AGENT**, parce que les agents
  opèrent avec **le jeton de l'humain**. Vérifié le même jour : `collaborators` = **`gitgdx` seul**,
  `restrictions` = **absente**, identité `gh` **identique**. ⇒ **Sur ce dépôt, aucune preuve machine de
  provenance n'existe** : « la fusion ne vient pas d'un agent » (case 34, renforcement R-c) est une
  **obligation de process**, désormais attestée de façon **déclarative et assumée** — jamais plus par
  `is_bot`, qui était **faussement rassurant**. **Voie de sortie unique et commune aux deux dettes** :
  une **identité distincte pour les agents** (2ᵉ compte ou GitHub App), puis `restrictions` → la fusion
  par un agent devient **impossible**, pas seulement interdite. ⚠️ Réserve **non levée** : `restrictions`
  pourrait être **réservé aux dépôts d'organisation** — à vérifier. **Porté par US-00.8.**
- ⚠️ **`TRACKS.md` (track FULL) exige une « revue humaine explicite de la PR » qu'aucune barrière
  machine ne soutient** — ni avant, ni après l'application (cible à **`0`** approbation). **US-01.1 est en
  FULL** → arbitrage à poser **avant son Integration Lock** : requalifier l'exigence en obligation de
  process avec preuve tracée, ou engager la voie « 2ᵉ compte relecteur ». **Amendement joint, suggéré par
  US-00.7** : `TRACKS.md:14` dit « Surface auth / sécurité / **admin** / paiement » là où la pratique
  constante du projet (4 US certifiées, interprétation inscrite au SCB) lit « surface **applicative** » —
  le critère littéral **est** satisfait par US-00.7 au sens strict. ⛔ `TRACKS.md` **n'est pas édité** par
  US-00.7.
- **Périmètre Art. 6 déclaré ≠ appliqué** : `.github/workflows/*` et `apply_branch_protection.sh` ne
  sont protégés ni par `protect_files.sh` ni par la Constitution → candidat `/audit-methodo`.
- **`governance.grandfathering_date` est une clé morte** : lue par aucun script, sémantique décalée
  (« US sans trace », pas « commits hors PR »). Laissée à `null` — à implémenter, redocumenter ou
  supprimer du schéma.
- Fichiers EPIC créés **rétroactivement** (EPIC_00, EPIC_01) — `/us-new` ne vérifie pas l'existence
  du fichier EPIC parent ; durcissement du rituel à décider.
- Décisions design à arbitrer (@UXDesigner + @PO) : gradient continu OKLCH (PRD) vs 4 paliers
  (maquette) ; endpoint bleu `#3D7DD8` (PRD) vs `#005ab3` (maquette) ; langue mixte fr/en des maquettes.
**US bloquées** : —
**Actions humaines en attente** :
- 🎯 **PROCHAIN PAS RECOMMANDÉ — `/us-new` pour US-00.5**, branchée sur le **nouveau `main`**
  (**`e2bd626`**), puis **US-00.6**. Ce sont les **deux seules** US requises pour clore EPIC_00.
  ⚠️ **Une par une** : `strict: true` sérialise les merges.
- 🆕 **Créer `US-00.8` (US de dette) via `/us-new`** — décidé par l'**arbitrage @PO du 2026-07-28**
  (`reports/US-00.7/po_arbitrage_s11.md`). ✅ **Le verrou est LEVÉ** : US-00.7 est **certifiée et
  fusionnée**, donc l'interdiction d'éditer `docs/stories/US-00.1-*` « depuis la branche d'US-00.7 »
  *(qui aurait fait tomber son critère 23)* **n'a plus d'objet**. Porte la **requalification tracée
  d'US-00.1** (S11) en **additif daté**, et les dettes déjà identifiées : **NB-1bis** · **`selftest` en
  CI** · **identité distincte pour les agents + `restrictions`** *(seule voie pour rendre la fusion par un
  agent **impossible** et non seulement interdite — fusionnée avec la dette `TRACKS.md`)* · **lacune de la
  grille de test** *(aucun critère de **cohérence temporelle** du corpus vivant — établi deux fois par la
  QA)* · **« un critère de sortie se publie comme un script exécutable »** · et les **findings non
  bloquants** des audits (N-1 traité, **N-2** `pip install` nu, **N-3** forks, actions à tag mutable,
  `emitter` non enforced). ⚠️ **NON requise pour clore EPIC_00** — son report est un choix assumé.
- 📌 **US-00.5 — périmètre RÉDUIT mais NON VIDE** : S1 (règle 2) et S2 (Art. 4) sont **devenus vrais**,
  donc leur correction est **sans objet**. ⚠️ Mais US-00.5 **gagne un item**, relevé par le @PO :
  l'**Art. 4 de la Constitution nomme `ci.yml`** alors que le **4ᵉ contexte requis provient de
  `branch-naming.yml`**. Et **`BACKLOG.md` n'a jamais porté ces corrections** → **rien à en retrancher**.
- ✅ **FAIT** : `gh` CLI installé (2.96.0) et authentifié `gitgdx` avec `admin: true`. Chemin absolu si
  absent du `PATH` d'une session ouverte avant l'install : `C:\Program Files\GitHub CLI\gh.exe`.
- ✅ **FAIT** : `factory.config.json` porte `required_approving_review_count: 0` (`enforce_admins: true`).
- ✅ **FAIT** : T4 (`scripts/factory_sync.py`), T5, T6 et T22 (`scripts/githooks/pre-push` — le hook ne
  se réclame plus de la protection de branche) — toutes les actions humaines d'US-00.4 sont soldées.
- ✅ **FAIT (2026-07-27)** : **déblocage** de la protection de branche — **voie (a), dépôt rendu PUBLIC**
  (Art. 5). ⚠️ **Exposition irréversible** de tout l'historique pour ce qui a été publié ; `gitleaks`
  devient une barrière **critique**. **FAIT (2026-07-28)** : le **`PUT`** d'application (T8 d'US-00.7) et
  le **test négatif serveur** (T10) — les deux seules opérations à confirmation humaine explicite.
- ✅ **FAIT (2026-07-28) : US-00.7 T20 — `scripts/githooks/pre-push` (Art. 6)**. Son en-tête ne se
  réclame plus d'être « le seul enforcement réel » ni d'une impossibilité de plateforme. **Copie
  humaine** (l'agent en est bloqué par `protect_files.sh`), diff de `reports/US-00.7/transmissions.md`
  **§8** — *et non celui du Story File, rédigé le 27 et rectifié depuis*. Logique **inchangée** (un seul
  hunk) et **exercée sans réseau** : `main` → `exit 1`, `feat/` → `exit 0`. Preuves :
  [`reports/US-00.7/t20_pre_push.md`](reports/US-00.7/t20_pre_push.md). **C'était la dernière action
  humaine Art. 6 d'US-00.7.**
- ✅ **FAIT (2026-07-30)** : **fusion de la PR #15** — la **dernière** action humaine d'US-00.7.
  `main` = **`e2bd626`**, `mergedAt` 12:12:35Z, `mergedBy` **`gitgdx`**, **sans `--admin`** →
  renforcement **R-c respecté**, aucun agent n'a fusionné. ⚠️ **Garantie DÉCLARATIVE** et assumée comme
  telle : `mergedBy.is_bot` rend `false` **même pour un agent**, qui opère avec le jeton de l'humain.
- **Planifier les dettes techniques restantes** : **NB-1bis** (complétude de la cible dans
  `_guard_mapping`) et **`selftest` en CI** — de préférence dans la **même** US de dette.
- Clarifier le statut de `US-INIT` (US à part entière vs simple porteur du Sprint 0).
- Décider la création de US-01.2 (Gestion des événements).
- Arbitrages design ci-dessus.

## Anti-patterns (à ne pas reproduire)

| Anti-pattern | Barrière actuelle |
|---|---|
| Implémenter sans visa @PO | `/us-new` + machine à états (EVT_STORY_READY requis) |
| Modifier une US certifiée sans re-audit | re-ouverture du cycle = nouveaux événements obligatoires |
| Committer sans PROJECT_LOG / `--no-verify` | hooks git + hook Claude Code + CI |
| Certifier sans déployer (`🚀 OUI` + `⏳`) | `check_scb_compliance.py` bloquant partout |
| Auditer son propre code dans la même session | `/audit-us` (contextes frais) |
