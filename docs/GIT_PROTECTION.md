# 🛡️ Branche principale : enforcement appliqué, effet prouvé et vérification

> # ✅ `main` EST PROTÉGÉE — appliquée le **2026-07-28** (US-00.7)
>
> *(Le constat inverse du **2026-07-26** — « `main` n'est pas protégée, et ne peut pas l'être sur ce
> dépôt », 403 de plan — était **exact à sa date**. Il est **historisé** au §suivant, jamais supprimé :
> il a été **levé le 2026-07-27** par une décision humaine, **voie (a) — dépôt rendu PUBLIC** — puis la
> protection a été **appliquée le 2026-07-28**.)*
>
> **Ce qui est PROUVÉ, avec sa preuve brute datée** — [`reports/US-00.7/applied_state/`](../reports/US-00.7/applied_state/) :
>
> | Fait | Lecture | Preuve |
> |---|---|---|
> | La branche est protégée | `GET …/branches/main` → **`"protected": true`** | `branch_main_after.json` |
> | La règle est **exactement** la cible générée | `GET …/branches/main/protection` → **200** : `strict: true` · **4** contextes · `required_pull_request_reviews` **présent** avec `0` · `enforce_admins.enabled: true` · `required_conversation_resolution: true` · `allow_force_pushes: false` · `allow_deletions: false` · `required_linear_history: false` · `restrictions` **absente** | `protection_applied.json` |
> | L'administrateur est **inclus** | `required_status_checks.enforcement_level: **"everyone"**` — manifestation d'`enforce_admins` | `branch_main_after.json` |
> | La comparaison config ↔ dépôt réel est **conforme** | `--check-remote` → **exit 0 RÉEL** : **12** champs alignés, **0** écart, **7** champs additionnels neutres **nommés**, **0** champ actif non couvert. **Sans** `[SIMULATION]`, sans « SOURCE SIMULÉE » | `check_remote_exit0_reel.txt` |
> | L'**effet** : aucun chemin d'écriture directe | Depuis un clone **sans hooks**, **3 refus émis par le SERVEUR** : `GH006 Protected branch update failed` · « *Changes must be made through a pull request* » · « ***4 of 4 required status checks are expected*** » · suppression → « *refusing to delete the current branch* » | `negative_test_server.txt` |
>
> ⚠️ **Ce que ces preuves n'établissent PAS — à lire avant tout audit.**
>
> 1. ✅ **PÉRIMÉ-2026-07-29 — LE REFUS DE FUSION EST DÉSORMAIS PROUVÉ, PAR LE SERVEUR.**
>    *(Cet énoncé affirmait le contraire ; il était exact jusqu'au 2026-07-29 inclus au matin.)*
>    **Preuve** : PR **#14**, `2026-07-29T08:49:14Z`, **lancée par l'humain**, avec **1/4** contexte vert →
>    `gh api -X PUT repos/gitgdx/Concentration/pulls/14/merge` → **HTTP 405**,
>    *« **3 of 4 required status checks are expected** »*. **`gh api` n'est qu'un transport HTTP** : le refus
>    **n'est pas** un pré-contrôle client. **Administrateur inclus** (`admin: true` + `enforce_admins: true`),
>    `main` **inchangée**, ⛔ **aucun `--admin`**. L'autre moitié — **acceptation seulement après passage au
>    vert** — est prouvée par `{"merged": true}` à **4/4** (PR #13).
>    ⇒ **AC-4 nominal COMPLET.** Ce n'est plus une inférence.
>    Preuves : [`reports/US-00.7/applied_state/merge_refusal_server_405.txt`](../reports/US-00.7/applied_state/merge_refusal_server_405.txt)
>    · [`reports/US-00.7/merge_proof_and_violation.md`](../reports/US-00.7/merge_proof_and_violation.md).
>    ⚠️ **Borne qui SUBSISTE** : le refus porte sur des contextes **`expected`**, **pas `failing`** — une
>    phrase de la forme « *aucune fusion possible avec la CI **rouge*** » reste une **inférence**, ⛔ et on ne
>    casse pas un gate pour l'obtenir. **`--admin` n'a pas été testé** et ne le sera pas.
> 2. **`allow_force_pushes: false` et `allow_deletions: false` ne sont pas isolés** par le test négatif :
>    le **même** `GH006` sort pour le force-push (la règle « PR obligatoire » se déclenche **avant** toute
>    évaluation propre au force-push), et GitHub refuse la suppression de la **branche par défaut**
>    indépendamment du réglage. Ces deux-là sont prouvés par l'**état de l'API** (P2), **pas** par l'effet.
> 3. Ne sont pas prouvés non plus : le comportement pour un **autre acteur**, un **jeton d'application**,
>    l'**interface web**, une PR issue d'un **fork** ou **réouverte**, ni la **persistance** de l'état
>    (aucune détection automatique — dette **#2**).
>
> ⚠️ **CONDITIONNEL — la condition d'invalidation de tout ce document.** L'édifice repose sur la
> **visibilité PUBLIQUE** du dépôt. Un retour en **privé** ramènerait le **403**, rendrait la protection
> **indisponible** et **rouvrirait la dérogation éteinte**. Vérifier par
> `python scripts/factory_sync.py --check-remote` (**exit 0** attendu) et
> `gh api repos/gitgdx/Concentration --jq '{private,visibility}'`.
>
> 🔕 **Dérogation `EVT_WAIVER_GRANTED` (2026-07-26, US-00.4, Constitution Art. 5) — ÉTEINTE / SANS OBJET
> au 2026-07-28.** Elle portait sur « **ni upgrade GitHub Pro, ni passage du dépôt en public** » ; l'humain
> a choisi la **voie (a) — dépôt public — le 2026-07-27**. Son motif (impossibilité de plateforme)
> **n'existe plus**. ⛔ **La trace est append-only** : l'événement du 2026-07-26 n'est **ni supprimé, ni
> édité, ni réécrit** — on **éteint** une dérogation, on ne l'**effface** pas. ⚠️ **L'extinction est
> DOCUMENTAIRE** : **aucun** des **25** événements de `scripts/events_catalog.json` (+ 4 alias dépréciés)
> ne permet de révoquer, éteindre ou faire expirer une dérogation → **dette du système de traçabilité**
> (§Dettes, ligne **10**). **Conditionnel** : un retour en privé **rouvrirait la question**.
>
> **Décision de référence** : [ADR-007](adr/ADR-007-application-protection-branche.md) — *remplace*
> [ADR-006](adr/ADR-006-protection-branche-principale.md) *(immuable, `Accepté` le 2026-07-26 : à lire
> comme un état historique, **jamais** comme la décision courante)*.
>
> **Défense en profondeur locale** (inchangée, et toujours de la discipline — elle s'**ajoute** désormais
> à une contrainte de plateforme au lieu de la remplacer) : les hooks versionnés
> (`scripts/install_hooks.sh`) bloquent commit et push directs sur la branche principale, et le hook
> Claude Code `block_dangerous_bash.sh` interdit à l'agent les commandes de contournement de hook et le
> push direct.

---

## 📅 Constat daté du 2026-07-26 — HISTORISÉ (levé le 2026-07-27, protection appliquée le 2026-07-28)

> 🕓 **Section conservée telle quelle, à valeur d'HISTORIQUE.** Elle était **exacte à sa date** et
> **n'est pas réécrite** : c'est la référence qui permet à un audit à contexte frais de mesurer le delta.
> **Ce qui a changé depuis** : `…/protection` est passé de **403** (« *Upgrade to GitHub Pro…* ») à
> **404** (« *Branch not protected* » — **disponible**, non appliquée) le **2026-07-27**, puis à **200**
> avec la cible appliquée le **2026-07-28**. Le fait **(b)** ci-dessous, établi par **inférence** faute
> d'endpoint lisible, a été **confirmé a posteriori par lecture directe** — voir l'encadré à la fin de
> cette section.

### Les quatre faits du 2026-07-26 — quatre preuves

Preuves **brutes datées de l'API**, archivées telles quelles dans
[`reports/US-00.4/`](../reports/US-00.4/). Chaque fichier porte sa **commande exacte** et son
**horodatage UTC**. Aucune preuve documentaire (bloc généré, sortie de `--check`, capture d'écran)
n'est recevable ici.

| # | Fait | Preuve brute |
|---|---|---|
| **(a)** | La branche principale **n'est pas protégée** — `"protected": false`, corroboré par `"protection": {"enabled": false, "required_status_checks": {"enforcement_level": "off", "contexts": [], "checks": []}}` | `reports/US-00.4/branch_main_before.json` |
| **(b)** | Les 4 status checks déclarés **s'exécutent** sur chaque PR (tous verts) mais **aucun n'est requis** | `reports/US-00.4/check_runs.json` (exécution) **+ inférence** depuis `"protected": false` — voir l'avertissement ci-dessous |
| **(c)** | **Impossibilité de plateforme** : `…/branches/main/protection` **et** `…/rulesets` → **403**, message **identique** | `reports/US-00.4/protection_api_403.json`, `reports/US-00.4/rulesets_api_403.json` (+ leurs `.stderr.txt`) |
| **(d)** | **Contradiction** : `CLAUDE.md` (règle 2) et la Constitution (Art. 4) déclarent la règle *enforced* « par protection de branche » | `reports/US-00.4/enforcement_gap.md` §Contradiction |

> ⚠️ **Le fait (b) n'est pas entièrement lisible dans une réponse brute** — et c'est dit franchement :
> l'endpoint qui l'énoncerait (`…/branches/main/protection`) est justement celui qui renvoie **403**.
> La première moitié (« les 4 checks s'exécutent ») est une **lecture directe** de `check-runs`. La
> seconde (« aucun n'est requis ») est une **INFÉRENCE** depuis `"protected": false` : une branche non
> protégée n'a, par construction, aucun check requis. C'est rigoureux, mais ce **n'est pas** une
> lecture d'API — ne jamais le présenter comme telle.

**Cause racine — le défaut est plus grave que le constat.** `factory.config.json` déclarait **depuis
l'origine du dépôt** une protection (`enforce_admins`, approbations, 4 status checks requis) que le
compte **n'a jamais pu appliquer** ; et le contrôle de dérive de la factory était **incapable de le
voir**, puisqu'il ne compare que des artefacts *documentaires* sans jamais appeler l'API. Une
vérification verte a donc coexisté, sans la moindre contradiction, avec une branche principale grande
ouverte **et** une cible inapplicable. C'est cet **angle mort de vérification** que US-00.4 ferme.

> ### ✅ Le fait (b) est CONFIRMÉ A POSTERIORI par lecture directe — 2026-07-28
>
> US-00.4 ne pouvait établir « **aucun check n'est requis** » que par **INFÉRENCE** depuis
> `"protected": false`, et l'a **déclaré comme telle** plutôt que de la présenter comme une lecture d'API.
> Le test négatif d'US-00.7 a produit la **lecture directe** qui manquait : le serveur répond
>
> ```text
> remote: - 4 of 4 required status checks are expected.
> ```
>
> — le serveur **énumère lui-même** les contextes requis. Le mécanisme d'inférence d'US-00.4 est donc
> **validé a posteriori** : sur une branche non protégée, il n'y avait effectivement aucun check requis ;
> sur une branche protégée par la même cible, il y en a **4 sur 4**. C'est un **résultat**, et pas un
> détail de forme : l'honnêteté méthodologique d'US-00.4 (nommer une inférence comme telle) se trouve
> **récompensée par la confirmation**, sans qu'une ligne de son texte ait eu besoin d'être corrigée.
> Preuve : `reports/US-00.7/applied_state/negative_test_server.txt`.

---

## 🕸️ Ce qui protège `main` — contrainte de plateforme **plus** filet de discipline résiduel

**Depuis le 2026-07-28, l'enforcement de la branche principale est une contrainte de plateforme.** Ce
qui subsiste de discipline locale ne la **remplace** plus : il s'y **ajoute**. La distinction reste
essentielle — les présenter comme équivalents serait un défaut.

| Élément | Nature | Ce qu'il fait | **Ses limites — à ne jamais taire** |
|---|---|---|---|
| **Protection de branche GitHub** (`…/branches/main/protection`) | 🔒 **contrainte de PLATEFORME** | Refuse toute mise à jour de `refs/heads/main` hors PR, **pour tout acteur**, y compris l'administrateur (`enforce_admins` → `enforcement_level: "everyone"`). **4 status checks REQUIS.** Refus **prouvés** : `GH006`, « *Changes must be made through a pull request* », « *4 of 4 required status checks are expected* » | **Révocable** par un administrateur à tout moment, **sans aucune détection automatique** (dette **#2**) · vaut **à la date de la mesure** · **conditionnée à la visibilité publique** du dépôt · rien n'est prouvé pour un jeton d'application ni pour l'interface web |
| CI (`ci.yml`, `branch-naming.yml`) | 🔒 **contrainte de plateforme** *(via les contextes requis)* | Les **4** contextes **SONT REQUIS** — état de l'API, et le serveur les énumère lui-même (« *4 of 4 required status checks are expected* ») : la fusion y est **conditionnée** | ⚠️ Le refus d'une **tentative de fusion** n'a **pas encore été observé** (T11 non exécutée) : il **découle** de l'état, il n'en est pas la preuve. Et ne démontre le caractère bloquant que des contextes **effectivement rapportés** : un contexte requis **jamais rapporté** produit un blocage **définitif** (§Plan de retour arrière) |
| Hook **local** `pre-push` (`core.hooksPath = scripts/githooks`, posé par `scripts/install_hooks.sh`) | 🕸️ **filet de discipline** *(résiduel, et toujours utile)* | Refuse `refs/heads/main` **avant l'aller-retour réseau** (retour immédiat) ; vaudrait encore si la protection serveur était un jour désactivée | **Absent d'un clone frais** — c'est précisément la condition du test négatif d'US-00.7 · l'interdiction des options de contournement de hook (Constitution Art. 1) reste portée par la **même** discipline locale |
| Discipline de process | 🕸️ **filet de discipline** | PR systématiques : **10 fusions** (#1, #3 → #11) et **2** commits directs, tous deux de bootstrap | Repose sur la volonté des intervenants — mais elle n'est **plus le seul** rempart : `0a2e5ab` et `6483022` (bootstrap) sont les seuls commits jamais arrivés sur `main` hors PR, et un tel commit est désormais **refusé par le serveur** |

> ✅ **Test négatif serveur : EXÉCUTÉ le 2026-07-28** *(il était « explicitement REPORTÉ, jamais
> exécuté » au 2026-07-26 — le report est soldé)*. Depuis un **clone jetable sans hooks**, hors du dépôt
> de travail, **sans aucune option de contournement de hook** : les **3** commandes sont **refusées par le
> serveur**, et `git rev-parse origin/main` est **identique avant et après les trois**. L'**effet** —
> aucun chemin d'écriture directe vers la branche principale — est donc **démontré**, et non plus
> seulement déclaré. Preuve brute : `reports/US-00.7/applied_state/negative_test_server.txt`.
>
> ⚠️ **Deux précisions d'attribution, à ne pas escamoter.** (1) Le test prouve l'**effet global**, il
> n'**isole pas** chaque réglage : `allow_force_pushes: false` et `allow_deletions: false` sont prouvés par
> l'**état de l'API**, pas par ce test (même `GH006` pour le force-push ; refus de supprimer la branche
> **par défaut** indépendamment du réglage). (2) La preuve vaut **à sa date** et **pour l'acteur employé**.
>
> 💡 **Leçon de procédure consignée** : une première tentative lancée **par erreur depuis le vrai dépôt**
> a vu la suppression refusée par le **hook local** `pre-push`, sans jamais atteindre le serveur. **Un
> refus local ne prouve rien** — c'est toute la raison d'être du clone sans hooks. L'incident est consigné
> dans le fichier de preuve, non masqué.

---

## 🔓 Conditions de déblocage — HISTORISÉ : la **voie (a) a été retenue** le 2026-07-27

> ✅ **Décision humaine tracée (Constitution Art. 5) : le dépôt a été rendu PUBLIC le 2026-07-27** —
> c'est la **voie (a)** du tableau ci-dessous. La section est **conservée** parce qu'elle documente le
> **coût assumé** de ce choix, et parce que la conditionnalité qu'elle décrit reste **active** : un retour
> en privé ramènerait le **403**.
>
> ⚠️ **L'exposition est IRRÉVERSIBLE, et il faut continuer de le dire.** Repasser le dépôt en privé ne
> dépublie pas ce qui a été vu, cloné ou indexé : **tout l'historique** du dépôt, y compris la totalité de
> sa gouvernance, est **définitivement** exposé. **`gitleaks` est désormais une barrière CRITIQUE**, et
> c'est l'un des 4 contextes requis. L'analyse de coût du 2026-07-26 — qui écartait cette voie — **n'est
> pas invalidée** par le renversement : elle a été **arbitrée** par l'autorité humaine, seule compétente.
> **Corollaire opérationnel nouveau** : n'importe qui peut désormais **forker** le dépôt et **ouvrir une
> PR** (§Conditions de fusion, point 4).

*(État de plan **daté du 2026-07-26**, dépendant de la politique commerciale de la plateforme, qui
peut évoluer dans les deux sens. Re-vérifier avec la commande du §Vérification — ne jamais figer cet
état comme définitif.)*

| Voie | Coût | Exposition | À savoir avant de décider |
|---|---|---|---|
| **(a) Rendre le dépôt public** — ✅ **RETENUE le 2026-07-27** | **Nul** | **Exposition publique du code, de toute la gouvernance et de l'HISTORIQUE COMPLET** | ⚠️ **IRRÉVERSIBLE pour ce qui a été publié** : repasser le dépôt en privé ne dépublie pas ce qui a été vu, cloné ou indexé. `gitleaks` devient une barrière **critique**. Un dépôt rendu public « juste pour débloquer la CI » expose **définitivement** tout l'historique |
| **(b) GitHub Pro** | **Coût par utilisateur et par mois** | **Aucune** — le dépôt reste **privé** | Aucune exposition, mais une dépense récurrente à assumer |

**Ce qui a été débloqué** *(identique dans les deux cas)* : protection classique **et** rulesets,
status checks **requis**, `enforce_admins` effectif, et le **test négatif serveur** reporté est devenu
exécutable — **il a été exécuté le 2026-07-28**. *(Les rulesets, désormais disponibles (**200 `[]`**),
ne sont **pas** retenus : la protection classique est déjà outillée, auditée et certifiée de bout en
bout — arbitrage **ADR-007 D4**, par sobriété et non par indisponibilité.)*

> ⚠️ **Ajouter un collaborateur ne débloque RIEN.** La limitation portait sur le **plan** du compte et
> la **visibilité** du dépôt — **pas** sur le nombre de contributeurs. **Cet énoncé était exact et le
> reste** : c'est bien la visibilité qui a débloqué.

**Engager l'une de ces voies était hors du pouvoir d'un agent** : cela exigeait une **décision humaine
explicite et tracée** — elle a été prise le 2026-07-27.

---

## 🎯 Cible APPLIQUÉE — déclarée, appliquée, vérifiée

`factory.config.json` est la **source unique** — **non modifiée** par l'application. La cible arbitrée le
2026-07-26 (ADR-006 décision 3, **conservée sans rediscussion** par ADR-007) y est inscrite, et c'est
**exactement** elle qui est en vigueur depuis le **2026-07-28** :

| Clé | Valeur | Pourquoi |
|---|---|---|
| `required_approving_review_count` | **`0`** | Dépôt **mono-collaborateur** (`gitgdx`, administrateur) : exiger une approbation se **verrouillerait** lui-même. Réglage **daté et conditionnel** → devient une **anomalie dès un 2ᵉ collaborateur** (voir §Vérification, point de contrôle périodique) |
| `enforce_admins` | **`true`** | La règle doit valoir **aussi** pour l'administrateur et les jetons privilégiés des agents |
| `required_conversation_resolution` | `true` | Aucune discussion ouverte à la fusion |
| `allow_force_pushes` / `allow_deletions` | `false` | Ni réécriture, ni suppression de la branche |
| `required_linear_history` | `false` | Les fusions de PR restent des commits de merge |
| `required_status_checks.strict` | `true` | La branche doit être à jour avant fusion |

> 🔴 **Piège à garder visible** : `required_pull_request_reviews` doit **rester présent avec `0`**.
> Le **retirer** désactiverait « Require a pull request before merging » — **`0` approbation ≠ pas de
> PR exigée**. `emit_branch_protection()` l'émet **toujours** : ne jamais « optimiser » son omission.

**L'(ré-)application est UNE seule commande** — c'est la **voie normale**, et la **seule** autorisée :

```sh
sh scripts/apply_branch_protection.sh gitgdx/Concentration
```

⚠️ Elle **exige des droits admin** et **modifie l'enforcement de `main`** : ce n'est pas une commande de
lecture. Ce script consomme le payload **généré** par `python scripts/factory_sync.py
--emit-branch-protection` (**jamais** un JSON écrit à la main, **jamais** l'écran *Settings → Branches*).
**Toute divergence future entre le dépôt et la configuration se corrige en RÉ-APPLIQUANT depuis la
config** — jamais en alignant la config sur l'état constaté.

> ✅ **La validation est désormais FONCTIONNELLE, et non plus seulement logique.** Au 2026-07-26,
> « armée » ne valait que **validation logique** (payload cohérent et complet) : aucun `PUT` n'avait jamais
> été accepté par la plateforme. Le `PUT` du **2026-07-28** a été **accepté**, et l'**effet** de la règle
> est **prouvé** (3 refus serveur + `exit 0` réel de `--check-remote`). Le script vient donc d'être
> **validé en production**.
>
> ⚠️ **Ce qui n'a PAS changé** : la « revue humaine explicite de la PR » du track **FULL**
> (`docs/governance/TRACKS.md`) et le rituel `/audit-us` restent des obligations **de process, non
> enforced** — la cible est à **`0`** approbation, donc **aucune barrière machine** ne les soutient. Dette
> **#7**, arbitrage **dû avant le lock d'US-01.1**.

### Les 4 contextes de la cible — **REQUIS**

> ✅ **L'en-tête généré du tableau ci-dessous — « Status check requis » — est désormais EXACT.** Ces 4
> contextes **sont** requis depuis le 2026-07-28 : aucune PR n'est fusionnable tant qu'ils ne sont pas
> tous verts, administrateur inclus. *(Au 2026-07-26 cet en-tête était trompeur et devait être encadré
> d'un avertissement ; sa reformulation aurait exigé d'éditer `scripts/factory_sync.py`, fichier
> **Art. 6**. Cette **dette #6 est devenue SANS OBJET** : l'énoncé est vrai tel quel, il n'y a plus rien
> à corriger.)* Vérifié le 2026-07-28 : les 4 libellés rapportés par l'API sont **identiques caractère
> pour caractère** à ceux de `factory.config.json` — `reports/US-00.7/labels_verification.md` et
> `applied_state/protection_applied.json`.

<!-- FACTORY_SYNC:BEGIN — généré par scripts/factory_sync.py, ne pas éditer -->

| Status check requis | Workflow |
|---|---|
| `🔐 Secrets scan (gitleaks)` | `ci.yml` |
| `📋 Governance (SCB + traçabilité + synchro)` | `ci.yml` |
| `check-branch-name` | `branch-naming.yml` |
| `📱 App (gates run_gates.py)` | `ci.yml` |

<!-- FACTORY_SYNC:END -->

⛔ **Ne jamais éditer entre `<!-- FACTORY_SYNC:BEGIN -->` et `<!-- FACTORY_SYNC:END -->`** : ce bloc
est régénéré par `python scripts/factory_sync.py --write`. Toute édition manuelle fait échouer
`--check`, donc le job CI `governance`, qui est un gate **bloquant**.

---

## 🚧 Conditions de fusion désormais ACTIVES — à connaître, pas à découvrir comme une panne

> **Depuis le 2026-07-28, toute PR vers `main` doit satisfaire SIMULTANÉMENT les cinq conditions
> ci-dessous — administrateur inclus.** Elles ne sont pas des recommandations : ce sont des **conditions
> de fusion**. Aucune n'est un défaut ; chacune est un **coût assumé** de l'enforcement.
>
> ⚠️ **Statut de ce tableau** : il décrit la **configuration appliquée** (état de l'API, prouvé) et le
> comportement qui en découle **selon la plateforme**. Le **refus effectif d'une tentative de fusion** n'a
> **pas encore été observé** sur ce dépôt (tâche **T11** d'US-00.7) — à lire comme une inférence
> documentée, pas comme une preuve.

| # | Condition | Ce qui bloque, concrètement | Comment s'y conformer |
|---|---|---|---|
| 1 | **PR obligatoire** (`required_pull_request_reviews` présent) | Tout `git push` direct sur `main` est refusé par le serveur (`GH006`) | Passer par une PR — il n'y a plus d'autre chemin |
| 2 | **4 status checks REQUIS et verts** | `mergeable_state = blocked` tant qu'un contexte n'est pas vert *(ou n'est pas encore rapporté : « *4 of 4 required status checks are expected* »)* | Attendre `gh pr checks <n>` → **4/4**. Un contexte **jamais rapporté** est un **verrouillage** : voir §Plan de retour arrière |
| 3 | **Nom de branche conforme** — 🔴 **la contrainte la plus facile à percuter** | `check-branch-name` (`.github/workflows/branch-naming.yml`) sort en **`exit 1`** pour toute branche hors `^feat/US-[0-9]+\.[0-9]+.*$` → contexte requis **ROUGE** → PR **définitivement infusionnable**. **`chore/`, `docs/`, `hotfix/` sont donc impossibles à fusionner.** Touche directement le **track QUICK**, dont les hotfix reposent sur des noms libres | Nommer la branche `feat/US-XX.X-description`, **même** pour un commit de gouvernance ou un correctif urgent. Toute exception exige un arbitrage humain tracé |
| 4 | **Corollaire du dépôt PUBLIC** — PR issues de **forks** | Le contrôle porte sur `github.head_ref` : **toute PR de fork** dont la branche ne suit pas le motif est **structurellement infusionnable**. Le dépôt est ouvert **en lecture et en proposition**, **fermé en fusion** par sa propre convention. S'y ajoute que le `GITHUB_TOKEN` d'une PR de fork est **restreint**, alors que le job `secrets-scan` demande `pull-requests: write` | **Non résolu — arbitrage requis** si une contribution externe se présente. Ce n'est pas un défaut : c'est un **choix** à assumer explicitement |
| 5 | **Branche à jour** (`strict: true`) **et zéro discussion ouverte** (`required_conversation_resolution: true`) | `strict: true` **sérialise les merges** : chaque fusion périme toutes les autres branches ouvertes. `required_conversation_resolution` bloque sur **un seul** commentaire d'audit non résolu | Rebaser/mettre à jour avant de fusionner ; **résoudre** les discussions d'audit (elles ne se perdent pas — c'est voulu) |

⚠️ **Distinguer un blocage NORMAL d'un VERROUILLAGE** : un contexte en `FAILURE` est un gate qui a fait
son travail → **corriger la cause**. Un contexte en `EXPECTED`/absent est un contexte **jamais rapporté**
→ **appliquer le §Plan de retour arrière**. Confondre les deux conduirait à administrer la règle au lieu
de corriger le travail — c'est-à-dire à contourner un gate.

---

## 🔍 Vérification de l'état réel

Deux commandes, deux portées **qu'il ne faut jamais confondre** :

| Commande | Portée | Dans la CI ? |
|---|---|---|
| `python scripts/factory_sync.py --check` | **DOCUMENTAIRE uniquement, aucun appel réseau** : `factory_env.sh`, bloc généré ci-dessus, présence des libellés de jobs dans les workflows, seuils de couverture. **N'atteste RIEN** de l'état réel de la protection sur GitHub | **Oui** — gate bloquant du job `governance` |
| `python scripts/factory_sync.py --check-remote` | Interroge l'**API** et compare la protection **réelle** à la cible **générée**, champ par champ. **Lecture seule** (2 GET, aucun `PUT`/`POST`/`PATCH`/`DELETE`) | **Non, jamais** — voir ci-dessous |

### Sémantique des trois issues

| Code | Signification | Ce qu'il faut en faire |
|---|---|---|
| **0** | Protection **strictement conforme** à la cible générée. **Seul** chemin où le mot « conforme » est autorisé. ✅ **Issue OBTENUE EN RÉEL le 2026-07-28** — 12 champs alignés, 0 écart, 0 champ actif non couvert (`reports/US-00.7/applied_state/check_remote_exit0_reel.txt`). C'est **l'état attendu aujourd'hui**, et la **première observation in vivo** de ce chemin *(il n'était démontré que sur fixture jusque-là — écart de preuve n° 3 d'US-00.4, **refermé**)* | **Rien à faire** — consigner le code. ⚠️ L'exit 0 vaut **à l'instant de la mesure** : il n'installe **aucune** surveillance continue |
| **1** | **Dérive** : protection absente ou divergente. Une ligne `champ \| attendu \| réel` par écart, contextes listés séparément en *manquants* et *en trop* | **Ré-appliquer depuis la configuration** (`sh scripts/apply_branch_protection.sh gitgdx/Concentration`), jamais à la main dans l'interface, puis re-vérifier — et **archiver les deux passages** |
| **2** | `VERIFICATION IMPOSSIBLE — ce n'est PAS un succès` : **403 de plan** *(l'issue réelle au 2026-07-26 ; elle **redeviendrait** réelle si le dépôt repassait en privé — c'est pourquoi ce cas reste dans l'outil)*, 403 de droits, **401** (non authentifié), **404 non désambiguïsé**, erreur réseau, `gh` absent **et** aucun jeton, `MAPPING INCOMPLET` | **À SIGNALER.** Un exit 2 n'est **ni un succès ni un échec** : c'est un constat. Sa cause doit être **NOMMÉE**. ⛔ **Jamais** d'ajustement d'`INERT_GET_KEYS` ni du mapping « pour forcer le vert » |

**Attribution honnête du code HTTP** — un **403** (plan) n'est ni un **401** (non authentifié) ni un
**404** (branche non protégée *ou* droits insuffisants). Confondre les trois ferait diagnostiquer un
problème de droits là où il n'en existe aucun. L'ambiguïté du **404** est levée en croisant avec
`GET …/branches/{branche}` (champ `protected`, lisible **sans** droits admin) : `protected == false`
→ **dérive réelle (exit 1)** ; `protected == true` malgré une protection illisible → **droits
insuffisants (exit 2)**.

> ✅ **La désambiguïsation du 404 a été VALIDÉE IN VIVO le 2026-07-27** — elle était jusque-là
> « non observable in vivo » (risque **R3** d'US-00.4, **CLOS par l'observation**). Après le passage du
> dépôt en public et **avant** l'application, `…/protection` a renvoyé un **404 « Branch not protected »**
> avec `protected == false` → l'outil a rendu **exit 1** (dérive réelle) et **jamais** exit 2, exactement
> comme prévu. Preuve : `reports/US-00.7/entry_state/protection_404.json` et `check_remote_exit1.txt`.
> ⚠️ **Reste non exercé** : le repli `urllib` du comparateur contre l'API réelle (dette **#9**, partielle).

### ⚠️ Prérequis d'exécution : `gh` doit être joignable dans le `PATH`

Le transport utilise `gh api` si `shutil.which("gh")` le trouve, sinon `urllib` (stdlib) avec
`GH_TOKEN`/`GITHUB_TOKEN`. **Piège constaté le 2026-07-26** : `gh` peut être installé
(`C:\Program Files\GitHub CLI\gh.exe`) tout en étant **absent du `PATH`** d'une session ouverte
**avant** son installation. Dans ce cas `--check-remote` rend bien **2**, mais avec la cause
**« `gh` introuvable … et aucun jeton »** — et **non** le 403 de plan : **le constat attendu serait
manqué**. Vérifier `gh --version` avant de conclure, et rouvrir le terminal si nécessaire.

### Pourquoi ce contrôle n'est PAS dans la CI

Il exige des droits **admin** que le `GITHUB_TOKEN` de la CI **n'a pas**. L'y mettre produirait soit
un **faux rouge permanent**, soit la tentation de le rendre non bloquant — donc **décoratif**. C'est
une commande d'**administration manuelle**, et cette séparation est **testée** par un contrôle
négatif : `grep -rn "check-remote" .github/workflows/` doit ne rien renvoyer.

### Point de contrôle périodique — **conservé, et RÉORIENTÉ**

Porté par `/audit-methodo` (axe Gouvernance). **Son objet a changé le 2026-07-28 ; il n'a pas
disparu** — il ne porte plus la dette « `main` n'est pas protégée » mais la **surveillance de sa
persistance**, qui est désormais la seule barrière contre une révocation silencieuse. À chaque passage :

1. `python scripts/factory_sync.py --check-remote` — **exit 0 attendu**. **exit 1** = **dérive** → ré-appliquer
   **depuis la config**. **exit 2** = **à signaler**, cause **nommée**. **Consigner le code**, pas une paraphrase.
2. **Vérifier que la VISIBILITÉ du dépôt n'a pas changé** :
   `gh api repos/gitgdx/Concentration --jq '{private,visibility}'` → un retour en **privé** ramènerait le
   **403**, rendrait la protection **indisponible** et **rouvrirait la dérogation éteinte**.
3. **Vérifier que les 4 libellés rapportés** correspondent toujours aux 4 contextes requis (`gh pr checks`
   sur une PR ouverte, ou `…/protection --jq '.required_status_checks.contexts'`) — un libellé divergent
   produirait un **verrouillage** (§Plan de retour arrière).
4. **Réévaluer la condition de retour à `1` approbation** :
   `gh api repos/gitgdx/Concentration/collaborators --jq '[.[] | select(.permissions.push) | .login]'` — si
   **≥ 2** comptes en écriture, ouvrir une US remettant `required_approving_review_count: 1`
   *(ADR-006 décision 13, **entièrement valable**)*. En dessous, consigner le décompte.

**Aucune des trois issues ne peut rester silencieuse.**

> 🔴 **Dette assumée, et elle est désormais PLUS lourde qu'avant** : ce contrôle est **périodique, manuel
> et humain**, et **sans déclencheur calendaire** (`/audit-methodo` est trimestriel « ou à la demande »).
> Entre deux passages, **aucune** dérive n'est détectée — et c'est maintenant la **protection elle-même**
> qui en dépend. C'est la dette la plus susceptible de **pourrir silencieusement** (dettes **#2** et **#8**).

---

## 📋 Instructions de configuration manuelle — **équivalent de secours, jamais la voie normale**

> ⚠️ **Ces réglages décrivent la cible EN VIGUEUR** *(appliquée le 2026-07-28)*, à titre de **référence
> lisible** et d'**équivalent de secours**. Ils **sont** désormais atteignables via l'écran
> **Settings → Branches** — le dépôt étant **public**, il n'y a plus de 403 côté interface. *(L'énoncé
> antérieur « pas atteignables aujourd'hui / même 403 côté interface » était exact au 2026-07-26 et est
> **devenu faux** ; il est corrigé ici, daté.)*
>
> ⛔ **Ce n'est POUR AUTANT PAS la voie autorisée.** La voie normale est **le script**, qui applique la
> cible **depuis la source unique**. Une saisie à la main est une source de **dérive** que `--check-remote`
> signalerait en **exit 1**, et le §Plan de retour arrière l'interdit explicitement pendant une
> récupération de verrouillage. Cette procédure ne sert qu'à **relire** la cible ou à dépanner si le script
> est indisponible — et toute correction ainsi faite doit être **immédiatement** reportée dans
> `factory.config.json` puis ré-appliquée par le script.

1. Onglet **Settings** du dépôt → **Code and automation** → **Branches**.
2. **Add branch protection rule** (ou éditer la règle existante).
3. Nom de la branche : la valeur de `factory.config.json` → `git.main_branch`.

### 1. Require a pull request before merging
- **Cocher la case elle-même** : c'est elle qui interdit le push direct.
- `Require approvals` : **décoché** — la cible est `required_approving_review_count: 0`
  (`factory.config.json` → `branch_protection`), dépôt mono-collaborateur.
  ⚠️ Décocher `Require approvals` ne dispense **pas** de la PR : l'exigence de PR est portée par la
  case du point 1. **`0` approbation ≠ pas de PR exigée.**
- ⚠️ **Ce réglage est daté** : dès un **2ᵉ** compte en écriture, il devient une anomalie et doit
  repasser à `1` (point de contrôle périodique ci-dessus).

### 2. Require status checks to pass before merging
- `Require branches to be up to date before merging` **coché** (`strict: true`).
- Ajouter les **4** contextes du tableau généré ci-dessus, **au libellé exact** — emoji, sélecteur de
  variante, espaces et parenthèses compris. Un libellé divergent d'un seul caractère produirait un
  check *jamais rapporté*, qui bloquerait la PR **indéfiniment** — c'est le risque de **verrouillage**,
  désormais **réel et actif** : voir §Plan de retour arrière. *(Vérifié le 2026-07-27 : les 4 libellés
  portent `U+1F510`, `U+1F4CB`, `U+1F4F1`, **aucun `U+FE0F`**, et `ç`/`é` sont **précomposés** en NFC —
  `reports/US-00.7/labels_verification.md`.)*

### 3. Do not allow bypassing the above settings
- **Coché** (`enforce_admins: true`) : la règle vaut **aussi** pour les administrateurs et les jetons
  d'accès privilégiés des agents. C'est le point qui empêche l'auteur de la règle de la contourner.

### 4. Restrict who can push to matching branches
- **Ne pas activer** : la cible générée porte `restrictions: null` (aucune restriction d'acteurs).
- ⚠️ Ne **pas** « réserver la fusion à l'@Architect » ici : cette exigence est **de process** (revue
  humaine du track FULL, rituel `/audit-us`) et n'est portée par **aucune** barrière machine — elle ne
  l'était pas avant l'application, elle ne l'est **toujours pas** après (la cible est à **`0`**
  approbation). Dette **#7**. L'inscrire dans la protection créerait une divergence avec la source
  unique, que `--check-remote` signalerait en **dérive (exit 1)**.

---

## 🚨 En cas de violation détectée

Un commit direct sur la branche principale ou une PR fusionnée hors process déclenche un événement
d'incident `EVT_WORKFLOW_VIOLATION` et bloque la certification de production.

> **Portée bornée du constat du 2026-07-26** : l'historique Git **n'est pas réécrit**. Les
> certifications de **US-00.1 / US-00.2 / US-00.3 restent valides** (audits à contexte frais, gates CI
> réellement exécutés, preuves archivées — **indépendants** de la protection de branche). Les **deux**
> commits de bootstrap (`0a2e5ab`, `6483022`) sont les seuls jamais arrivés sur `main` hors PR : ils
> ont **créé** les règles en question et ne donnent lieu à **aucun `EVT_WORKFLOW_VIOLATION`
> rétroactif** — exemption portée par ADR-006 *(remplacé par ADR-007, qui la **conserve**)* et par le
> présent document, **pas** par `governance.grandfathering_date` (clé morte, laissée `null`).

> ✅ **Depuis le 2026-07-28, un commit direct sur `main` est REFUSÉ PAR LE SERVEUR** : la détection de
> violation n'est plus le seul recours, elle devient un **filet pour ce que la plateforme ne couvre pas**
> (fusion hors process, contexte retiré de la cible, règle désactivée « juste pour ce merge »). Relevé au
> 2026-07-27 par `git log --first-parent --oneline origin/main` : **10 fusions de PR** (#1, #3 → #11) et
> **exactement 2** commits directs, tous deux de bootstrap. ⛔ L'historique **n'est pas réécrit**.

---

## 🛟 Plan de retour arrière — verrouillage du dépôt

> **Écrit le 2026-07-27, AVANT toute application de la protection** (US-00.7, AC-8, tâche T6) — et
> **conservé tel quel**. 🔴 **Ce plan n'est plus une précaution théorique : depuis l'application du
> 2026-07-28, le risque qu'il traite est RÉEL ET ACTIF.** La protection est en vigueur avec
> `enforce_admins: true` et **exige** quatre contextes de status checks ; si **l'un d'eux n'est jamais
> rapporté** par GitHub, **plus aucune pull request n'est fusionnable, administrateur inclus** — y compris
> celle qui voudrait corriger le problème. C'est le risque **R-1** de l'US, de probabilité faible et
> d'impact **critique**. **Ne pas supprimer cette section** : c'est la seule porte de sortie documentée.

### 1. Symptôme — et comment le distinguer d'un échec normal

```sh
gh pr view <n> --json mergeableState,statusCheckRollup
gh pr checks <n>
```

| Observation | Interprétation | Action |
|---|---|---|
| `mergeableState: BLOCKED` **et** un contexte requis en **`EXPECTED`** / **absent** de `gh pr checks` | **VERROUILLAGE** — le contexte n'est **jamais rapporté** (libellé divergent, ou workflow qui ne se déclenche pas sur cet événement). L'attente est **définitive**. | **appliquer ce plan** |
| `mergeableState: BLOCKED` **et** un contexte en **`FAILURE`** | **échec normal d'un gate** : le code ou la gouvernance sont en faute. | **corriger la cause**, pas la règle |
| `mergeableState: BLOCKED` **et** tous les checks verts | autre condition de fusion non satisfaite : `strict: true` (**branche pas à jour**) ou `required_conversation_resolution: true` (**discussion ouverte**). | rebaser / résoudre les discussions |
| `mergeableState: BLOCKED` **et** un contexte requis en **`FAILURE`** dont la cause est **HORS DU DÉPÔT** et **non corrigeable par une PR** — asset amont supprimé, dépôt tiers retiré, incident CDN, index de paquets indisponible | **INTERBLOCAGE** — ni un verrouillage de libellé, ni une faute du travail. Corriger exigerait de modifier un workflow ⇒ de fusionner une PR ⇒ que ce **même contexte** soit vert ⇒ que le tiers soit revenu. **C'est circulaire.** *(Ajouté le 2026-07-28 — finding **N-1** du re-audit sécurité d'US-00.7.)* | **appliquer ce plan** *(§2 — **administrer**, pas contourner)*, puis **corriger la cause en amont** et **ré-appliquer la règle** |

⚠️ Ne **jamais** confondre les trois premières lignes : `EXPECTED` se répare en **administrant la
règle**, `FAILURE` se répare en **corrigeant le travail**, et « tous verts » se répare en **rebasant ou
en résolvant les discussions**.

> **⚠️ NUANCE AJOUTÉE LE 2026-07-28 — l'avertissement ci-dessus était TROP ABSOLU.** Il disait :
> « *Appliquer ce plan sur un `FAILURE` serait un contournement de gate* ». **C'est vrai d'un `FAILURE`
> dont la cause est DANS le dépôt** — et c'est l'écrasante majorité des cas. **C'est faux du cas de la
> 4ᵉ ligne** : un `FAILURE` d'origine **externe** n'est pas un gate qui fait son travail, c'est une
> **panne de disponibilité** qui a pris la forme d'un gate. Le distinguer n'est pas un assouplissement :
> le test reste « **la cause est-elle corrigeable par une PR ?** ». **Oui ⇒ corriger le travail. Non
> ⇒ administrer, en le traçant.** ⛔ Dans les **deux** cas, `gh pr merge --admin` reste **interdit** :
> administrer, c'est **modifier la règle**, jamais **fusionner malgré elle**.
>
> **Surface exposée à ce risque, nommée** — toute dépendance téléchargée par un job **requis** :
> `actionlint` *(épinglé par version **et** empreinte SHA256 — la plus rigoureuse du dépôt)* ·
> `pip install jsonschema` **nu, sans version ni empreinte** *(finding **N-2**, **pré-existant** et
> **strictement plus faible**)* · `actions/checkout@v4`, `subosito/flutter-action@v2`,
> `gitleaks-action@v2` *(tags **mutables**, finding MEDIUM 4)*. **La probabilité est faible et la panne
> est auto-révélatrice** — elle se manifeste à la première PR, jamais silencieusement.
> Détail : [`reports/US-00.7/security_reaudit.md`](../reports/US-00.7/security_reaudit.md) §5.

### 2. Mécanisme de sortie — **éditer ou supprimer ≠ contourner**

`enforce_admins: true` interdit à l'administrateur de **contourner** la règle (*bypass* : fusionner
malgré elle). Il **ne lui interdit pas** de l'**éditer** ni de la **supprimer** :

```sh
# lire l'état courant (toujours en premier)
gh api repos/gitgdx/Concentration/branches/main/protection

# supprimer la règle — porte de sortie du verrouillage
gh api -X DELETE repos/gitgdx/Concentration/branches/main/protection

# ré-appliquer depuis la SOURCE UNIQUE (jamais un JSON écrit à la main)
sh scripts/apply_branch_protection.sh gitgdx/Concentration
```

> **Ce n'est pas un contournement : c'est de l'administration.** La distinction est la clé de ce
> plan. Contourner = fusionner une PR que la règle refuse (`gh pr merge --admin`). Administrer =
> modifier la règle elle-même, de façon **tracée**, puis la remettre en place depuis la
> configuration. La porte de sortie existe toujours, et elle exige des droits admin.

### 3. Séquence imposée — 5 étapes, dans cet ordre

1. **`DELETE` tracé** de la règle : `gh api -X DELETE repos/gitgdx/Concentration/branches/main/protection`
   — sortie **archivée brute** (commande + horodatage UTC) dans `reports/US-00.7/`.
2. **Corriger le libellé dans la SOURCE UNIQUE** : `factory.config.json` → `status_checks[].name`
   (fichier **Art. 6** → **action humaine**) **ou** le `name:` du job dans
   `.github/workflows/<workflow>.yml`. ⛔ **Jamais** dans l'interface GitHub.
3. **Ré-appliquer depuis la configuration** : `sh scripts/apply_branch_protection.sh gitgdx/Concentration`
   — le script consomme le payload **généré** par `python scripts/factory_sync.py --emit-branch-protection`.
4. **Re-vérifier** : `python scripts/factory_sync.py --check-remote` → **exit 0** attendu. Un `exit 1`
   impose de recommencer à l'étape 2 ; un `exit 2` doit être **nommé** (403, 401, 404, `gh`
   introuvable, `MAPPING INCOMPLET`) et **signalé**.
5. **Consigner** : ligne dans `PROJECT_LOG.md` + événement `EVT_DEV_BLOCKER` +
   `python scripts/factory_sync.py --check` (exit 0) pour prouver que config et workflows sont
   redevenus cohérents.

### 4. Interdits absolus — chacun invalide l'AC-4 et vaut `EVT_WORKFLOW_VIOLATION`

* ⛔ **`gh pr merge --admin`** (ou toute fusion en contournement de la règle).
* ⛔ **Retirer un contexte requis** de la cible « pour débloquer » — y compris temporairement.
* ⛔ **Corriger le libellé dans l'interface web** (*Settings → Branches*) : la correction ne
  remonterait pas dans la source unique, et la prochaine ré-application la perdrait.
* ⛔ **Aligner `factory.config.json` sur l'état constaté** au lieu de l'inverse. La configuration est
  la référence ; le dépôt s'y conforme, jamais le contraire.
* ⛔ **Retirer `required_pull_request_reviews`** du payload : `0` approbation **≠** pas de PR exigée.
  Le supprimer désactiverait « Require a pull request before merging ».
* ⛔ **`--no-verify`** (Constitution Art. 1), en toute circonstance.

### 5. Obligation de tracer — jamais de correction silencieuse

Toute exécution de ce plan produit, **sans exception** : la sortie **brute** du `DELETE` et de la
ré-application, une ligne `PROJECT_LOG.md`, un événement `EVT_DEV_BLOCKER`, et la mention de
l'incident dans le Story File. Un verrouillage réparé **en silence** laisserait croire que le
mécanisme n'a jamais failli — c'est précisément la classe de fausse confiance que cette US existe
pour éliminer.

### 6. Ce que ce plan ne couvre pas

* Il suppose des **droits admin** sur le dépôt. Sans eux, ni le `DELETE` ni la ré-application ne sont
  possibles : la sortie du verrouillage exige alors l'intervention du propriétaire.
* Il suppose que la protection soit **disponible** : si le dépôt repassait en **privé**, la
  protection redeviendrait **indisponible (403)** — le verrouillage disparaîtrait de lui-même, mais
  l'enforcement aussi.
* Il ne prévient pas le verrouillage : il en sort. La prévention est la vérification des libellés
  **avant** application (`reports/US-00.7/labels_verification.md`) et le constat des libellés
  **réellement rapportés** sur la PR (`gh pr checks`, critère 25) **avant** toute tentative de fusion.

---

## 🧾 Dettes ouvertes

> **Mise à jour du 2026-07-28 (US-00.7).** ⛔ **Aucune dette n'est close par effet de bord** : chacune est
> statuée nommément ci-dessous, et **cinq restent OUVERTES**. Les numéros sont **conservés** pour que les
> renvois existants (ADR-006, `reports/US-00.4/**`, Story Files) restent valides.

| # | Dette | Statut |
|---|---|---|
| 1 | **Enforcement de plateforme absent** — `main` n'est pas protégée ; risque #2 d'EPIC_00 (« règles déclarées mais non enforced ») **OUVERT** | ✅ **CLOSE le 2026-07-28** — protection **appliquée** et **effet prouvé** (`reports/US-00.7/applied_state/`) ; risques **#2 et #5 d'EPIC_00 CLOS**, critère de clôture **coché**. ⚠️ **Conditionnel** à la visibilité publique |
| 2 | **Aucune détection automatique de dérive** config ↔ dépôt réel : le contrôle distant est manuel et hors CI (droits admin) | 🔴 **OUVERTE — et désormais plus lourde** : c'est la protection elle-même qui en dépend. Un administrateur peut révoquer la règle **sans aucun signal**. Seul porteur : `/audit-methodo` (voir #8) |
| 3 | **`CLAUDE.md` (règle 2) et Constitution (Art. 4)** déclarent la règle *enforced* « par protection de branche » : **factuellement faux, et le reste après US-00.4** | ✅ **SANS OBJET le 2026-07-28** — les deux textes sont devenus **factuellement VRAIS sans être édités**. La correction transmise « OBLIGATOIRE » à **US-00.5** est **sans objet** : ⛔ US-00.5 ne doit **pas** « corriger » un texte redevenu exact. Son périmètre s'en trouve **réduit** |
| 4 | **`governance.grandfathering_date`** n'est lue par **aucun** script (clé morte, sémantique décalée) | 🔴 **OUVERTE** — à implémenter, redocumenter ou retirer du schéma. Laissée `null` **délibérément** |
| 5 | **`scripts/check_branch_protection.py` produit la preuve mais n'est pas protégé** par `.claude/hooks/protect_files.sh` : un agent pourrait l'affaiblir (transformer un exit 2 en exit 0). Même classe de défaut pour `.github/workflows/*` et `scripts/apply_branch_protection.sh` | 🔴 **OUVERTE — aggravée** : `.github/workflows/*` porte désormais les **libellés des contextes REQUIS** (donc le risque de **verrouillage**), et `apply_branch_protection.sh` est le **seul chemin d'écriture** de la protection. Périmètre Art. 6 **déclaré ≠ appliqué** — traitement = édition de `.claude/hooks/*`, **action humaine** |
| 6 | **En-tête du bloc généré** ci-dessus (« Status check requis ») laisse entendre que les checks **sont** requis. Sa reformulation impose d'éditer `scripts/factory_sync.py` (**Art. 6**) | ✅ **SANS OBJET le 2026-07-28** — les checks **sont** requis : l'en-tête généré est devenu **exact**. L'édition **Art. 6** qu'elle exigeait n'a **plus lieu d'être**, et l'avertissement qui l'encadrait a été remplacé par une confirmation datée |
| 7 | **Revue humaine de PR du track FULL** (`TRACKS.md`) sans aucune barrière machine, ni avant ni après déblocage. **US-01.1 est en FULL** | 🔴 **OUVERTE, INCHANGÉE** — la cible est à **`0`** approbation : l'application n'apporte **aucune** barrière ici. **La moitié « ni après déblocage » de l'énoncé reste exacte.** Arbitrage **dû avant le lock d'US-01.1**, avec l'amendement suggéré de `TRACKS.md:14` (« surface **applicative** … ») |
| 8 | **Point de contrôle sans déclencheur calendaire** (`/audit-methodo` est trimestriel « ou à la demande ») : rien ne garantit qu'un passage ait lieu | 🔴 **OUVERTE — et c'est maintenant la plus critique** : elle porte la surveillance de la protection (#2). Reste la dette la plus susceptible de **pourrir silencieusement** |
| 9 | **Repli `urllib` du comparateur non exercé** contre l'API réelle (aucun jeton disponible en session) ; **chemin 404 validé sur fixture uniquement** — jamais observé en réel | 🟡 **PARTIELLEMENT CLOSE le 2026-07-27** — le **chemin 404 réel** a été **observé** (404 + `protected: false` → **exit 1**), ce qui **clôt R3** d'US-00.4. **Le repli `urllib` reste NON exercé** contre l'API réelle : cette moitié demeure **OUVERTE** |
| **10** | 🔴 **NOUVELLE — `NB-1bis`** : après le correctif NB-1 *(3 lignes, `MAPPED_TOP_KEYS & set(expected)`)*, une clé absente de la cible dont la valeur réelle est **ACTIVE** est nommée et **interdit l'exit 0** ; mais si sa valeur est **NEUTRE** (`{"enabled": false}`) elle est **seulement nommée** et **l'exit 0 subsiste**, et si elle est **absente des deux côtés** elle n'est **pas même nommée**. Or `enforce_admins: false` **autorise le bypass admin** et `required_pull_request_reviews` absent signifie **aucune PR exigée** : la doctrine de neutralité assimile à tort « valeur fausse » et « inerte ». **NB-1 est un progrès strict, PAS une fermeture** | 🔴 **OUVERTE.** Correctif identifié : contrôle de **complétude de la cible** dans `_guard_mapping()` (`MAPPED_TOP_KEYS - set(expected)` non vide → exit 2). **Compensé aujourd'hui** : `set(payload) == MAPPED_TOP_KEYS` → `True` (cible **non amputée**) → aucun scénario atteignable tant que `factory.config.json` n'est pas amputé (**Art. 6**, action humaine). À porter **avec** #11 |
| **11** | 🔴 **NOUVELLE — aucun `selftest` en CI** pour `check_branch_protection.py` : ses fixtures versionnées sont lancées **à la main**, y compris pour valider le correctif NB-1 | 🔴 **OUVERTE.** Contrôle négatif **maintenu** : `grep -rn "check-remote" .github/workflows/` doit rester **vide** — le contrôle distant reste **hors CI** par construction. À porter dans la **même** US de dette que #10 |
| **12** | 🔴 **NOUVELLE — aucun événement d'extinction de dérogation** dans `scripts/events_catalog.json` (**25** événements + 4 alias dépréciés, vérifiés) : une dérogation y est **irrévocable par construction**. L'extinction d'`EVT_WAIVER_GRANTED` est donc **documentaire**. **Corollaire** : le champ `emitter` (`"human"` pour `EVT_WAIVER_GRANTED`) n'est lu par **aucun** script ni hook → **un agent peut émettre une dérogation** qu'il ne peut pas éteindre | 🔴 **OUVERTE.** Dette du **système de traçabilité**. Mitigation retenue : consignation aux **3** emplacements + mention dans le `rationale` d'`EVT_DOCS_UPDATED` — **convention non enforced**. En ajouter un modifierait la **machine à états** → exige son propre **ADR**. Candidat `/audit-methodo` |

**Détail complet, cause racine et transmission** :
[`reports/US-00.4/enforcement_gap.md`](../reports/US-00.4/enforcement_gap.md) *(constat du 2026-07-26 —
document daté, à référencer et non à corriger)* · [`reports/US-00.7/transmissions.md`](../reports/US-00.7/transmissions.md)
*(mise à jour du 2026-07-28 : périmètres réduits, dettes closes et maintenues)*.
