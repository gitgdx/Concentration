# 🛡️ Branche principale : enforcement réel, cible armée et vérification

> # ⛔ `main` N'EST PAS PROTÉGÉE — et ne peut pas l'être sur ce dépôt (constat du 2026-07-26)
>
> `GET /repos/gitgdx/Concentration/branches/main` renvoie **`"protected": false`**.
> `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient tous deux **403 —
> « Upgrade to GitHub Pro or make this repository public to enable this feature. »**, avec un jeton
> authentifié `gitgdx` disposant de `{"admin": true}` sur un dépôt `{"private": true}`.
>
> **Ce n'est ni un oubli, ni un défaut de droits, ni un défaut de configuration : c'est une limite de
> plan.** Les **deux** mécanismes de la plateforme (protection classique **et** rulesets) sont
> verrouillés à l'identique. **Aucune** commande, aucun script, aucun réglage ne peut protéger `main`
> en l'état — `scripts/apply_branch_protection.sh` **échouerait en 403**.
>
> Ce qui tient lieu d'enforcement aujourd'hui est un **filet de discipline**, pas une contrainte de
> plateforme : voir §[Ce qui protège réellement `main`](#-ce-qui-protège-réellement-main-aujourdhui).
>
> Décision humaine arbitrée le 2026-07-26 : **ni passage du dépôt en public, ni upgrade GitHub Pro.**
> La cible de protection est donc **armée** — déclarée, prête, applicable en une commande — et
> **NON active**. Voir [ADR-006](adr/ADR-006-protection-branche-principale.md).
>
> **Défense en profondeur locale** (inchangée, et toujours de la discipline) : les hooks versionnés
> (`scripts/install_hooks.sh`) bloquent commit et push directs sur la branche principale, et le hook
> Claude Code `block_dangerous_bash.sh` interdit à l'agent les commandes `--no-verify` / push direct.

---

## 📅 Constat daté du 2026-07-26 — quatre faits, quatre preuves

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

---

## 🕸️ Ce qui protège réellement `main` aujourd'hui

**Trois éléments, et ce sont trois filets de discipline — aucun n'est une contrainte de plateforme.**
Les présenter comme un enforcement de plateforme serait un défaut bloquant.

| Élément | Ce qu'il fait | **Ses limites — à ne jamais taire** |
|---|---|---|
| Hook **local** `pre-push` (`core.hooksPath = scripts/githooks`, posé par `scripts/install_hooks.sh`) | Refuse `refs/heads/main` depuis ce poste | **Absent d'un clone frais** (tant que `install_hooks.sh` n'est pas lancé) · contournable depuis un autre poste ou via l'**interface web** · `--no-verify` reste interdit (Constitution Art. 1) mais cette interdiction est **elle-même portée par un hook**, donc par la même discipline |
| CI (`ci.yml`, `branch-naming.yml`) | **Rapporte** 4 status checks sur chaque PR | Ces checks ne sont **requis par rien** : une PR peut être fusionnée **avec la CI rouge**. Ils informent, ils ne bloquent pas |
| Discipline de process | PR systématiques : **8 fusions** (#1, #3, #4, #5, #6, #7, #8, #9) | Repose sur la **volonté des intervenants**, pas sur une barrière. Seuls `0a2e5ab` et `6483022` (bootstrap) sont arrivés hors PR |

> **Test négatif serveur : explicitement REPORTÉ, jamais exécuté.** Sans protection, un
> `git push origin main`, un force-push ou une suppression **réussiraient** : les exécuter
> modifierait `main` hors PR **pour rien**. Cette documentation **ne produit donc aucune preuve de
> refus serveur et n'en exige aucune**. Conséquence assumée : l'**effet** (aucun chemin d'écriture
> directe) reste **non démontré** — seule la règle *déclarée* est connue.

---

## 🔓 Conditions de déblocage — deux voies, et seulement deux

*(État de plan **daté du 2026-07-26**, dépendant de la politique commerciale de la plateforme, qui
peut évoluer dans les deux sens. Re-vérifier avec la commande du §Vérification — ne jamais figer cet
état comme définitif.)*

| Voie | Coût | Exposition | À savoir avant de décider |
|---|---|---|---|
| **(a) Rendre le dépôt public** | **Nul** | **Exposition publique du code, de toute la gouvernance et de l'HISTORIQUE COMPLET** | ⚠️ **IRRÉVERSIBLE pour ce qui a été publié** : repasser le dépôt en privé ne dépublie pas ce qui a été vu, cloné ou indexé. `gitleaks` devient une barrière **critique**. Un dépôt rendu public « juste pour débloquer la CI » expose **définitivement** tout l'historique |
| **(b) GitHub Pro** | **Coût par utilisateur et par mois** | **Aucune** — le dépôt reste **privé** | Aucune exposition, mais une dépense récurrente à assumer |

**Ce qui serait débloqué est identique dans les deux cas** : protection classique **et** rulesets,
status checks **requis**, `enforce_admins` effectif, et le **test négatif serveur** reporté devient
exécutable.

> ⚠️ **Ajouter un collaborateur ne débloque RIEN.** La limitation porte sur le **plan** du compte et
> la **visibilité** du dépôt — **pas** sur le nombre de contributeurs.

**Engager l'une de ces voies est hors du pouvoir d'un agent** : cela exige une **décision humaine
explicite et tracée**.

---

## 🎯 Cible armée — déclarée, prête, **NON active**

`factory.config.json` est la **source unique**. La cible arbitrée le 2026-07-26 y est inscrite :

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

**Le jour du déblocage, l'application est UNE seule commande** — aucune nouvelle décision, aucun
arbitrage, aucun dossier à re-instruire :

```sh
# ⛔ NE PAS EXÉCUTER AUJOURD'HUI — échouerait en 403 (limite de plan).
#    Commande conservée telle quelle pour le jour du déblocage.
sh scripts/apply_branch_protection.sh gitgdx/Concentration
```

Ce script consomme le payload **généré** par `python scripts/factory_sync.py
--emit-branch-protection` (jamais un JSON écrit à la main). Il porte en en-tête la mention
**NON APPLICABLE au 2026-07-26 / PRÊT et CONDITIONNÉ AU DÉBLOCAGE** : il n'est **pas** « à
exécuter » — l'exécuter aujourd'hui **échouerait en 403**.

> « Armée » vaut **validation logique** (payload cohérent et complet), **pas** validation
> **fonctionnelle** : aucun `PUT` n'a jamais été accepté par la plateforme, donc le comportement réel
> de la règle reste **non démontré**. **Aucune preuve d'application ne peut être produite ni exigée.**
>
> Corollaire assumé : la « revue humaine explicite de la PR » du track **FULL**
> (`docs/governance/TRACKS.md`) et le rituel `/audit-us` restent des obligations **de process**, non
> enforced — et le resteront **même après le déblocage**, puisque la cible est à `0` approbation.

### Les 4 contextes de la cible

> ⚠️ **Lire l'en-tête du tableau ci-dessous avec prudence** : il est **généré** et intitulé « Status
> check requis », mais **aucun de ces 4 checks n'est requis aujourd'hui** — ils sont les contextes de
> la **cible armée**, et sont seulement **rapportés** par la CI. *(L'en-tête généré provient de
> `scripts/factory_sync.py`, fichier d'enforcement — sa reformulation est une action humaine, cf.
> §Dettes.)*

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

## 🔍 Vérification de l'état réel

Deux commandes, deux portées **qu'il ne faut jamais confondre** :

| Commande | Portée | Dans la CI ? |
|---|---|---|
| `python scripts/factory_sync.py --check` | **DOCUMENTAIRE uniquement, aucun appel réseau** : `factory_env.sh`, bloc généré ci-dessus, présence des libellés de jobs dans les workflows, seuils de couverture. **N'atteste RIEN** de l'état réel de la protection sur GitHub | **Oui** — gate bloquant du job `governance` |
| `python scripts/factory_sync.py --check-remote` | Interroge l'**API** et compare la protection **réelle** à la cible **générée**, champ par champ. **Lecture seule** (2 GET, aucun `PUT`/`POST`/`PATCH`/`DELETE`) | **Non, jamais** — voir ci-dessous |

### Sémantique des trois issues

| Code | Signification | Ce qu'il faut en faire |
|---|---|---|
| **0** | Protection **strictement conforme** à la cible générée. **Seul** chemin où le mot « conforme » est autorisé. ⚠️ **Cette issue n'a jamais été obtenue sur ce dépôt** — elle n'est démontrée que sur fixture | Signifierait que le déblocage a eu lieu **et** que la protection est appliquée (ce qui **n'est pas le cas au 2026-07-26**) → exécuter alors le **test négatif reporté** |
| **1** | **Dérive** : protection absente ou divergente. Une ligne `champ \| attendu \| réel` par écart, contextes listés séparément en *manquants* et *en trop* | Ré-appliquer **depuis la configuration** (`apply_branch_protection.sh`), jamais à la main dans l'interface |
| **2** | `VERIFICATION IMPOSSIBLE — ce n'est PAS un succès` : **403 de plan** (l'issue réelle sur ce dépôt au 2026-07-26), 403 de droits, **401** (non authentifié), **404 non désambiguïsé**, erreur réseau, `gh` absent **et** aucun jeton | **À SIGNALER.** Un exit 2 n'est **ni un succès ni un échec** : c'est un constat, et il **maintient la dette OUVERTE**. Ne jamais le consigner comme un succès, ne jamais s'en servir pour clore la dette |

**Attribution honnête du code HTTP** — un **403** (plan) n'est ni un **401** (non authentifié) ni un
**404** (branche non protégée *ou* droits insuffisants). Confondre les trois ferait diagnostiquer un
problème de droits là où il n'en existe aucun. L'ambiguïté du **404** est levée en croisant avec
`GET …/branches/{branche}` (champ `protected`, lisible **sans** droits admin) : `protected == false`
→ **dérive réelle (exit 1)** ; `protected == true` malgré une protection illisible → **droits
insuffisants (exit 2)**.

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

### Point de contrôle périodique

Porté par `/audit-methodo` (axe Gouvernance) : exécuter `--check-remote`, **consigner le code de
sortie**, puis réévaluer (i) la **condition de déblocage** (visibilité du dépôt **et** plan du
compte) et (ii) la **condition de retour à `1` approbation** (`gh api
repos/gitgdx/Concentration/collaborators` — si **≥ 2** comptes en écriture, ouvrir une US remettant
`required_approving_review_count: 1`). **Aucune des trois issues ne peut rester silencieuse.**

> **Dette assumée** : ce contrôle est **périodique, manuel et humain**. Entre deux passages,
> **aucune** dérive n'est détectée — et cela **restera vrai après le déblocage**.

---

## 📋 Instructions de configuration manuelle (équivalent de la cible armée)

> ⚠️ **Ces réglages décrivent la cible ARMÉE, PAS un état en vigueur.** Ils ne sont **pas atteignables
> aujourd'hui** : sur ce plan, l'écran **Settings → Branches** ne permet pas de créer de règle pour un
> dépôt privé (même 403 côté interface). **La voie normale est le script**, qui applique la cible
> **depuis la source unique** ; cette procédure manuelle n'est qu'un **équivalent de secours** — la
> saisie à la main est une source de **dérive** que `--check-remote` détecterait en exit 1.

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
  check *jamais rapporté*, qui bloquerait la PR indéfiniment après le déblocage.

### 3. Do not allow bypassing the above settings
- **Coché** (`enforce_admins: true`) : la règle vaut **aussi** pour les administrateurs et les jetons
  d'accès privilégiés des agents. C'est le point qui empêche l'auteur de la règle de la contourner.

### 4. Restrict who can push to matching branches
- **Ne pas activer** : la cible générée porte `restrictions: null` (aucune restriction d'acteurs).
- ⚠️ Ne **pas** « réserver la fusion à l'@Architect » ici : cette exigence est **de process** (revue
  humaine du track FULL, rituel `/audit-us`) et n'est portée par **aucune** barrière machine — ni
  aujourd'hui, ni après le déblocage. L'inscrire dans la protection créerait une divergence avec la
  source unique, que `--check-remote` signalerait en **dérive (exit 1)**.

---

## 🚨 En cas de violation détectée

Un commit direct sur la branche principale ou une PR fusionnée hors process déclenche un événement
d'incident `EVT_WORKFLOW_VIOLATION` et bloque la certification de production.

> **Portée bornée du constat du 2026-07-26** : l'historique Git **n'est pas réécrit**. Les
> certifications de **US-00.1 / US-00.2 / US-00.3 restent valides** (audits à contexte frais, gates CI
> réellement exécutés, preuves archivées — **indépendants** de la protection de branche). Les **deux**
> commits de bootstrap (`0a2e5ab`, `6483022`) sont les seuls jamais arrivés sur `main` hors PR : ils
> ont **créé** les règles en question et ne donnent lieu à **aucun `EVT_WORKFLOW_VIOLATION`
> rétroactif** — exemption portée par ADR-006 et par le présent document, **pas** par
> `governance.grandfathering_date` (clé morte, laissée `null`).

---

## 🛟 Plan de retour arrière — verrouillage du dépôt

> **Écrit le 2026-07-27, AVANT toute application de la protection** (US-00.7, AC-8, tâche T6). Ce
> plan existe pour un cas précis et unique : la protection appliquée avec `enforce_admins: true`
> **exige** quatre contextes de status checks ; si **l'un d'eux n'est jamais rapporté** par GitHub,
> **plus aucune pull request n'est fusionnable, administrateur inclus** — y compris celle qui
> voudrait corriger le problème. C'est le risque **R-1** de l'US, de probabilité faible et d'impact
> critique.

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

⚠️ Ne **jamais** confondre les deux premières lignes : `EXPECTED` se répare en administrant la règle,
`FAILURE` se répare en corrigeant le travail. Appliquer ce plan sur un `FAILURE` serait un
contournement de gate.

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

| # | Dette | Statut |
|---|---|---|
| 1 | **Enforcement de plateforme absent** — `main` n'est pas protégée ; risque #2 d'EPIC_00 (« règles déclarées mais non enforced ») **OUVERT** | Conditionnée au déblocage (§Conditions de déblocage) |
| 2 | **Aucune détection automatique de dérive** config ↔ dépôt réel : le contrôle distant est manuel et hors CI (droits admin) | Assumée ; restera vraie après le déblocage |
| 3 | **`CLAUDE.md` (règle 2) et Constitution (Art. 4)** déclarent la règle *enforced* « par protection de branche » : **factuellement faux, et le reste après US-00.4** | Correction **OBLIGATOIRE**, déléguée à **US-00.5** |
| 4 | **`governance.grandfathering_date`** n'est lue par **aucun** script (clé morte, sémantique décalée) | À implémenter, redocumenter ou retirer du schéma |
| 5 | **`scripts/check_branch_protection.py` produit la preuve mais n'est pas protégé** par `.claude/hooks/protect_files.sh` : un agent pourrait l'affaiblir (transformer un exit 2 en exit 0). Même classe de défaut pour `.github/workflows/*` et `scripts/apply_branch_protection.sh` | Périmètre Art. 6 **déclaré ≠ appliqué** — arbitrage humain |
| 6 | **En-tête du bloc généré** ci-dessus (« Status check requis ») laisse entendre que les checks **sont** requis. Sa reformulation impose d'éditer `scripts/factory_sync.py` (**Art. 6**) | Action humaine — mitigée ici par l'avertissement précédant le bloc |
| 7 | **Revue humaine de PR du track FULL** (`TRACKS.md`) sans aucune barrière machine, ni avant ni après déblocage. **US-01.1 est en FULL** | Arbitrage à poser **avant le lock de US-01.1** |
| 8 | **Point de contrôle sans déclencheur calendaire** (`/audit-methodo` est trimestriel « ou à la demande ») : rien ne garantit qu'un passage ait lieu | La dette la plus susceptible de pourrir silencieusement |
| 9 | **Repli `urllib` du comparateur non exercé** contre l'API réelle (aucun jeton disponible en session) ; **chemin 404 validé sur fixture uniquement** — jamais observé en réel | À revérifier au déblocage |

**Détail complet, cause racine et transmission à US-00.5** :
[`reports/US-00.4/enforcement_gap.md`](../reports/US-00.4/enforcement_gap.md).
