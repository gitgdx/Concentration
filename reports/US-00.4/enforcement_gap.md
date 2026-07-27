# Trou d'enforcement de la branche principale — constat, cause racine, portée et dettes

**US-00.4** · Branche `feat/US-00.4-ci-protection-branche` · **constat daté du 2026-07-26**
Rapport de tâche **T12** (Constitution Art. 3 — preuves). Rédigé par **@Developer**.

> ⛔ **Ce document n'affirme nulle part que `main` est ou devient protégée. Elle ne l'est pas, et
> cette US ne la protège pas.** Il énonce ce qui est vérifié, ce qui est inféré, et ce qui reste
> inconnu. Un exit 2 du contrôle distant n'est **ni un succès ni un échec** : c'est un constat à
> signaler, et il **maintient la dette ouverte**.

---

## 1. Constat daté — quatre faits, quatre preuves brutes

Toutes les preuves sont des **réponses de l'API**, archivées **telles quelles** dans ce répertoire,
chacune en-têtée de sa **commande exacte** et de son **horodatage UTC**. Aucune preuve documentaire
(bloc généré de `GIT_PROTECTION.md`, sortie de `factory_sync.py --check`, capture d'écran) n'est
recevable ici — c'est précisément ce type de « preuve » qui a laissé le défaut survivre.

| # | Fait vérifié | Preuve | Statut de la preuve |
|---|---|---|---|
| **(a)** | `main` **n'est pas protégée** : `"protected": false`, corroboré dans la même réponse par `"protection": {"enabled": false, "required_status_checks": {"enforcement_level": "off", "contexts": [], "checks": []}}` | `branch_main_before.json` (HTTP 200, `gh` exit 0) | **Lecture directe** |
| **(b)** | Les 4 status checks déclarés **s'exécutent** sur chaque PR et sont **verts**, mais **aucun n'est requis** | `check_runs.json` (HTTP 200) **+ inférence** — voir §1.1 | **Mixte : lecture directe + INFÉRENCE** |
| **(c)** | **Impossibilité de plateforme** : `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient **403 — « Upgrade to GitHub Pro or make this repository public to enable this feature. »** ; le dépôt est `{"private": true, "visibility": "private", "owner_type": "User"}` et le jeton porte `{"admin": true, "maintain": true, "push": true, "triage": true, "pull": true}` | `protection_api_403.json`, `rulesets_api_403.json` (+ leurs `.stderr.txt`), `repo_context.json` | **Lecture directe** |
| **(d)** | **Contradiction** : `CLAUDE.md` (règle 2, ligne 20) et la Constitution (Art. 4, ligne 49) déclarent la règle *enforced* « par protection de branche » | §4 de ce document | **Lecture de fichiers du dépôt** |

**Les trois codes HTTP ne disent pas la même chose — les confondre ferait diagnostiquer un problème
qui n'existe pas :**

| Code | Signification retenue ici | Ce que ce **n'est pas** |
|---|---|---|
| **403** + `Upgrade to GitHub Pro…` | **Indisponible sur ce plan** — la cause réelle | ❌ pas un défaut de **droits** (le jeton est `admin: true`), ❌ pas un défaut de **configuration** |
| **403** autre message | Droits / accès refusés | — |
| **401** | Non authentifié (jeton absent, expiré, invalide) | ❌ pas une limite de plan |
| **404** | **Ambigu** : branche non protégée **ou** droits insuffisants → levé en croisant `GET …/branches/{b}` (champ `protected`, lisible sans admin) | ❌ jamais interprété seul |

**La cause retenue est le PLAN, jamais « droits insuffisants ».** C'est vérifiable dans
`repo_context.json` : le jeton a `admin: true` et le 403 tombe quand même, sur les **deux**
mécanismes, avec un message **identique**.

### 1.1 Le fait (b) est prouvé en deux morceaux — dont une inférence, écrite comme telle

**Écart honnête, signalé et non masqué.** L'AC-1 exige que les preuves soient « les réponses brutes
datées de l'API ». Or la seconde moitié du fait (b) — « aucun n'est requis » — **n'est lisible dans
aucune réponse brute**, puisque l'endpoint autoritatif (`…/branches/main/protection`) est justement
celui qui renvoie **403**.

1. **Les 4 checks s'exécutent** → **lecture directe** de `check_runs.json` :
   `🔐 Secrets scan (gitleaks)`, `📋 Governance (SCB + traçabilité + synchro)`,
   `📱 App (gates run_gates.py)`, `check-branch-name` — tous `"conclusion": "success"`.
   *(Sha employé : `dd5b915`, tête de la branche de la **PR #9**, la plus récente fusionnée. La
   branche de cette US n'est pas encore poussée, donc sans check-run ; la tête de `main` `801a046`
   n'en aurait montré que **3** — `branch-naming.yml` ne se déclenche pas sur `main` — et n'aurait
   donc pas prouvé les 4. Le Story File autorise explicitement l'un ou l'autre.)*
2. **Aucun n'est requis** → **INFÉRENCE** depuis `"protected": false` : une branche non protégée n'a,
   par construction, **aucun** check requis. Corroborée par
   `"required_status_checks": {"enforcement_level": "off", "contexts": [], "checks": []}` dans la même
   réponse.

**Ce n'est pas une lecture directe, et ce document ne la présente pas comme telle.** C'est suffisant
et rigoureux ; le présenter autrement serait exactement le genre de raccourci que cette US corrige.

---

## 2. Cause racine — le défaut est ailleurs, et il est plus grave que le constat

Le défaut n'est **pas** « quelqu'un a oublié de lancer `apply_branch_protection.sh` ». Il est double,
et structurel :

1. **La factory déclarait un enforcement structurellement impossible sur son plan.**
   `factory.config.json` porte **depuis l'origine du dépôt** une cible de protection
   (`enforce_admins`, approbations, 4 status checks requis) que le compte **n'a jamais pu appliquer**.
   Ce n'était pas une régression : c'était faux dès le premier commit.

2. **Son propre contrôle de dérive était incapable de le voir.**
   `python scripts/factory_sync.py --check` affichait
   `Synchro factory conforme (env, protection, workflows, seuils).` alors qu'il **ne contacte jamais
   l'API** : il ne compare que des artefacts **documentaires** (bloc de `docs/GIT_PROTECTION.md`,
   présence des `name:` de jobs dans les workflows, seuils de couverture). Le mot « protection »
   y était employé comme un **fait vérifié** alors qu'il ne désignait qu'un tableau Markdown.

**Conséquence : une vérification verte a coexisté, sans la moindre contradiction, avec une branche
principale grande ouverte ET une cible inapplicable — depuis l'origine, à travers 8 fusions de PR et
3 certifications Prod.** C'est le pire défaut possible pour un dispositif dont l'unique produit est la
confiance : une **fausse confiance**, silencieuse et systématique.

**Ce que US-00.4 corrige réellement** : l'angle mort de vérification (le `--check` annonce désormais
« DOCUMENTAIRE » et renvoie vers `--check-remote`, qui interroge l'API et **refuse de conclure** quand
il ne peut pas vérifier). **Ce qu'elle ne corrige pas** : l'absence d'enforcement de plateforme, qui
reste entière.

---

## 3. Portée bornée — ce que ce constat ne remet PAS en cause

| Affirmation | Statut | Preuve |
|---|---|---|
| L'**historique Git n'est pas réécrit** | ✅ garanti | Aucun `rebase`, `filter-branch`, `push --force` dans cette US ; `origin/main` reste `801a046` |
| Les certifications de **US-00.1 / US-00.2 / US-00.3 restent VALIDES** | ✅ | Elles reposent sur des audits à **contexte frais** (`/audit-us`), des gates CI **réellement exécutés** et des preuves archivées — **indépendants** de la protection de branche. Aucune ne prétendait s'appuyer sur elle |
| **8 fusions de PR + exactement 2 commits directs** sur `main` | ✅ | `git log --first-parent --oneline origin/main` → 10 entrées : PR #1, #3, #4, #5, #6, #7, #8, #9 + `6483022` + `0a2e5ab` |
| Les 2 commits directs sont **exemptés**, sans `EVT_WORKFLOW_VIOLATION` rétroactif | ✅ décidé | `0a2e5ab` (initialisation) et `6483022` (fichiers EPIC + garde-fou) ont **créé** les règles en question. Exemption portée par **ADR-006** + `docs/GIT_PROTECTION.md` + le présent constat |
| `governance.grandfathering_date` reste **`null`** | ✅ | Voir dette #3 : la renseigner serait un **no-op** et masquerait une autre dette |

> ⚠️ **`git log --merges` ne prouve rien ici** : il renvoie **12** entrées, dont 4 fusions internes à
> des branches de travail, et ne peut **pas** établir l'absence de commit direct sur `main`. La seule
> commande probante est **`git log --first-parent --oneline origin/main`** : elle liste exactement ce
> qui a atterri sur `main`. Le décompte « 4 PR » de la première rédaction du Story File était **faux**
> (il omettait les PR de déploiement, de certification, le hotfix et la consolidation) et a été
> corrigé.

**Aucun test négatif serveur n'a été exécuté, et aucun ne pouvait l'être.** Sans protection, un
`git push origin main`, un force-push ou une suppression **réussiraient** : les exécuter modifierait
`main` hors PR **pour rien**. Conséquence assumée : l'**effet** (aucun chemin d'écriture directe)
reste **NON DÉMONTRÉ** — seule la règle *déclarée* est connue. `origin/main` est resté `801a046`
pendant toute la durée des travaux.

---

## 4. Contradiction avec le corpus de gouvernance (fait (d))

| Emplacement | Texte actuel | Statut |
|---|---|---|
| `CLAUDE.md`, règle 2, **ligne 20** | « *Enforced : hooks Claude Code + hooks git + **protection de branche**.* » | ❌ **FAUX** |
| `docs/governance/CONSTITUTION.md`, Art. 4, **ligne 49** | « **Enforcement** : CI `ci.yml` jobs qualité, **requis par la protection de branche** (`scripts/apply_branch_protection.sh`) » | ❌ **FAUX** |

Ces deux énoncés **restent faux après cette US**. L'hypothèse initiale (« US-00.4 les rendra vrais, il
n'y a donc rien à corriger ») est **tombée** avec le re-cadrage. Une dérogation humaine est tracée
(`EVT_WAIVER_GRANTED`, 2026-07-26 — ni GitHub Pro, ni dépôt public), et `CLAUDE.md` porte désormais un
encadré d'avertissement à lire avant tout audit ; mais **le texte des deux règles lui-même n'est pas
corrigé**. Voir §6 (transmission à US-00.5).

---

## 5. Dettes résiduelles — toutes OUVERTES

| # | Dette | Origine | Gravité |
|---|---|---|---|
| **1** | **Enforcement de plateforme ABSENT** : `main` n'est pas protégée et ne peut pas l'être sur ce plan. **Risque #2 d'EPIC_00 (« règles déclarées mais non enforced ») OUVERT** — la certification d'US-00.4 **ne le clôt pas**, et le critère de clôture « protection de branche vérifiée » d'EPIC_00 est **impossible à cocher** | Constat de cette US | 🔴 **majeure** |
| **2** | **Aucune détection automatique de dérive** config ↔ dépôt réel : le contrôle distant exige des droits **admin** absents du `GITHUB_TOKEN`, il est donc **manuel et hors CI** par construction. Entre deux `/audit-methodo`, **aucune** dérive n'est détectée | R5 | 🔴 restera vraie **après** le déblocage |
| **3** | **`governance.grandfathering_date` n'est lue par AUCUN script** — vérifié : la clé n'apparaît que dans `factory.config.json` (déclaration), une *description* de `scripts/factory.config.schema.json` et un *docstring* de `scripts/validate_trace.py` ; **aucune ligne de code ne la lit**. La renseigner serait un **no-op**. Sa sémantique documentée (« US sans trace tolérées avant la date ») est un **sujet différent** des commits hors PR. **Effet de bord écarté** : une date au 2026-07-24 aurait, si la sémantique était un jour implémentée, rendu tolérables les US sans trace antérieures et **masqué la dette US-INIT-01→06** | R2 | ⚠️ à implémenter, redocumenter ou **retirer du schéma** |
| **4** | **`scripts/check_branch_protection.py` produit la preuve mais n'est protégé par rien** : absent de la liste de `.claude/hooks/protect_files.sh` (vérifiée : `scripts/githooks/*`, `.claude/settings.json`, `.claude/hooks/*`, `.gitleaks.toml`, `scripts/install_hooks.sh`, `factory.config.json`, `scripts/factory_env.sh`, `scripts/factory_sync.py`, `scripts/run_gates.py`, `*.env*`). Un agent pourrait l'affaiblir — par exemple transformer un **exit 2 en exit 0**. Son ajout au hook est une **action humaine** (édition de `.claude/hooks/*`), hors périmètre de cette US | R6 | ⚠️ **le comparateur est de fait un fichier d'enforcement non protégé** |
| **5** | **Périmètre Art. 6 DÉCLARÉ ≠ APPLIQUÉ** : `.github/workflows/*` et `scripts/apply_branch_protection.sh` ne sont protégés **ni** par l'Art. 6, **ni** par le hook — alors qu'ils portent respectivement les gates CI et le seul chemin d'écriture de la protection. Même classe de défaut que #4 | R6 | ⚠️ à arbitrer |
| **6** | **Revue humaine de PR du track FULL sans barrière machine** : `docs/governance/TRACKS.md` l'exige, rien ne la soutient — ni aujourd'hui (rien n'est appliqué), ni après déblocage (la cible est à `0` approbation). **US-01.1 est en FULL** et sera la première US applicative concernée | R7 | ⚠️ **arbitrage à poser AVANT le lock de US-01.1** |
| **7** | **Point de contrôle sans déclencheur calendaire** : `/audit-methodo` est trimestriel « ou à la demande », sans échéance opposable. Rien ne garantit qu'un passage ait lieu | R9 | ⚠️ la dette la plus susceptible de **pourrir silencieusement** |
| **8** | **En-tête du bloc généré de `GIT_PROTECTION.md`** — « Status check **requis** » — laisse entendre que les 4 checks *sont* requis. Le corriger impose d'éditer `scripts/factory_sync.py` (**Art. 6**) → action humaine. Mitigé par un avertissement explicite placé **juste avant** le bloc | Constat T10/T14 | ⚠️ cosmétique mais c'est **exactement** le type de formulation qui a produit cette US |
| **9** | **Aucun test unitaire Python pour `check_branch_protection.py`** — décision assumée (arbitrage du 2026-07-26) : aucun harnais `pytest` n'existe dans le dépôt, `adapter.components` ne contient que `app`/Flutter, aucun gate de couverture Python n'existe, et le Story File tranche que la validation passe par les **critères de test sur fixtures**. Pas de nouvelle dépendance, pas de nouveau gate. **Conséquence** : la validation du comparateur est **exécutable mais non automatisée** — une régression future ne serait détectée par aucun gate. ➕ Les **8 chemins d'exécution** déjà exercés (exit 0 · exit 1 divergence · exit 1 404+`protected:false` · exit 2 404+`protected:true` · exit 2 403 réel · exit 2 sans transport · 3 exit 2 d'erreur d'usage) sont **directement transposables** en cas de test si un harnais `scripts/` s'ouvre plus tard | Arbitrage @Architect | ⚠️ dette **explicite** |
| **10** | **Repli `urllib` du comparateur JAMAIS exercé contre l'API réelle** : aucun `GH_TOKEN`/`GITHUB_TOKEN` disponible en session, le transport stdlib est implémenté mais non confronté à la plateforme. **Et le chemin 404 est validé sur FIXTURE uniquement** : sur ce dépôt l'API rend 403, jamais 404 — le comportement en 404 réel reste **non observé** | R3 + écart signalé par @Developer | ⚠️ à revérifier au déblocage (T17) |
| **11** | **Les fixtures peuvent dériver de la configuration** : `protection_conforme.json` est un instantané **statique** daté. Si `status_checks` ou `branch_protection` évoluent, le cas exit 0 **échouera bruyamment**. Choix assumé — une fixture auto-générée comparerait la config à elle-même et ne prouverait plus rien | R4 | ⚠️ échec **bruyant et immédiat**, préférable au silence |
| **12** | **Tentation d'exécuter le test négatif « pour vérifier »** : un intervenant lisant une version périmée du Story File pourrait lancer `git push origin main`. **Sans protection, ce push RÉUSSIRAIT** et modifierait `main` hors PR | R8 | 🔴 interdiction inscrite dans les Patterns imposés, T18 marquée **NE PAS EXÉCUTER** |

---

## 6. Transmission formelle à **US-00.5** — OBLIGATOIRE (T15)

> **Cette section est la sortie de la tâche T15.** Elle ne modifie ni le `BACKLOG.md`, ni le Story
> File de US-00.5 : cette inscription est **hors périmètre agent** et doit être **demandée
> explicitement à @ProductOwner**.

**Ce qui doit être corrigé, et pourquoi c'est obligatoire** : `CLAUDE.md` (règle 2) et la Constitution
(Art. 4) déclarent la règle « jamais de commit/push sur la branche principale » *enforced* « par
protection de branche ». **Cette déclaration reste FAUSSE après US-00.4** — et une factory dont la
constitution affirme un enforcement inexistant produit exactement la fausse confiance que cette US
dénonce.

> ⚠️ **Rectification du 2026-07-26 (finding B-1 de l'audit Revue).** Cette section affirmait que
> c'était « la **dernière** affirmation fausse restante du corpus de gouvernance ». **C'était faux.**
> Un balayage par motif **toutes extensions** en a trouvé d'autres — dont deux dans des artefacts
> d'**enforcement** (`.github/workflows/ci.yml`, `scripts/githooks/pre-push`) et une dans une **US
> certifiée** (`docs/stories/US-00.1-secrets-scan-depot.md`). Aucune revendication d'exhaustivité
> n'est maintenue : voir §6 quater pour la **méthode**, son **périmètre réel** et ce qui **reste
> ouvert**. La leçon est inscrite au §6 quater.

**Les emplacements exacts à corriger dans US-00.5** :

| # | Fichier | Emplacement | Texte à remplacer |
|---|---|---|---|
| **S1** | `CLAUDE.md` | **Règles dures**, règle **2**, ligne **20** | `*Enforced : hooks Claude Code + hooks git + protection de branche.*` |
| **S2** | `docs/governance/CONSTITUTION.md` | **Art. 4**, ligne **49** | `**Enforcement** : CI ci.yml jobs qualité, requis par la protection de branche (scripts/apply_branch_protection.sh) ; job governance (synchro).` |
| **S11** | `docs/stories/US-00.1-secrets-scan-depot.md` | **T8**, ligne **198** *et* **critère de test #6**, ligne **215** | « job `secrets-scan` **rouge** → **merge empêché par la protection de branche** » · « Job `secrets-scan` rouge + **merge bloqué par la protection de branche** » |

> 🔴 **S11 — pourquoi elle n'est PAS éditée ici, et pourquoi elle compte plus que les deux autres.**
> **US-00.1 est CERTIFIÉE Prod.** L'anti-pattern « modifier une US certifiée sans re-audit » (`CLAUDE.md`
> §Anti-patterns) impose une **ré-ouverture de cycle** : la corriger en catimini depuis US-00.4 serait
> précisément le contournement de process que la factory interdit. **Décision humaine rendue le
> 2026-07-26 : on signale et on transmet, sans toucher une ligne.**
> Sa gravité propre : c'est un **critère de test** et une **tâche** d'une US certifiée qui décrivent un
> mécanisme de blocage **inexistant**. Le test négatif CI de US-00.1 ne peut donc pas prouver ce qu'il
> annonce — le job `secrets-scan` devient rouge, mais **rien n'empêche la fusion**. La certification de
> US-00.1 n'est pas invalidée pour autant (elle repose sur gitleaks réellement exécuté, pas sur le
> blocage de fusion), mais **le libellé de son critère est faux** et doit être requalifié.

**Formulation de remplacement suggérée** (à arbitrer par @PO / @Architect) :

> *enforced par hook local `pre-push` + PR ; **protection de plateforme indisponible sur ce plan** —
> cf. ADR-006. Les status checks sont **rapportés, non requis** : une fusion avec CI rouge reste
> techniquement possible.*

**Actions attendues de @ProductOwner** :
1. Inscrire ces corrections (**S1**, **S2**, **S11**) au périmètre de **US-00.5**, par une **PR dédiée**.
2. Les qualifier **OBLIGATOIRES** (et non « nice to have ») : c'est la mise en cohérence de textes
   normatifs avec la réalité de la plateforme.
3. Pour **S11**, décider explicitement du **véhicule** : ré-ouverture de cycle sur US-00.1
   (nouveaux événements de trace, re-audit) **ou** requalification tracée depuis US-00.5. Ne pas
   trancher laisserait un critère de test faux dans une US certifiée.
4. Y joindre la dette **#8** ci-dessus (en-tête « Status check requis » du bloc généré de
   `GIT_PROTECTION.md`, dont la correction impose une édition de `scripts/factory_sync.py`, Art. 6).

**Hors périmètre de US-00.5, à arbitrer séparément** : la dette **#6** (revue humaine du track FULL
sans barrière machine) doit être tranchée **avant le lock de US-01.1**, qui est en track FULL.

### 6 bis. Occurrences S3→S6 — traitées par @Architect, **plus rien à transmettre** *(ajout du 2026-07-26)*

La relecture T14 a signalé 6 occurrences hors du périmètre @Developer. **Quatre ont été corrigées
directement** par @Architect à réception du rapport — elles ne survivront donc **pas** à US-00.4, et la
réserve de @Developer (« sans ajout explicite, S3 et S4 survivront à US-00.5 ») est **levée** :

| # | Fichier · ligne | Traitement |
|---|---|---|
| **S3** | `docs/SQUAD_GUIDE.md:321` | ✅ **CORRIGÉ** — « Exécuter `sh scripts/apply_branch_protection.sh` » barré + encadré ⛔ NE PAS EXÉCUTER + renvoi à `GIT_PROTECTION.md`/ADR-006. Les IDs `US-INIT-01→06` ont aussi été réalignés sur `US-00.1→00.6`. **Découverte de @Developer** : ce fichier n'était **ni** dans la liste de balayage T14, **ni** dans les fichiers déclarés de l'US — angle mort du périmètre lui-même. |
| **S4** | `docs/epics/EPIC_00-fondations.md:25` | ✅ **CORRIGÉ** — « protection de branche appliquée et vérifiée » barré et requalifié NON ATTEIGNABLE. Cette ligne **contredisait les critères de clôture du même fichier** (ligne 80), déjà corrigés le matin : preuve qu'une correction partielle d'un document laisse des affirmations fausses en place. |
| **S5** | `STORY_CERTIFICATION_BOARD.md:206` | ✅ **CORRIGÉ** — la décision du matin (« cette US rend la déclaration *enforced* vraie, il n'y a rien à corriger ») est désormais **barrée et explicitement marquée INVALIDÉE**, avec la prémisse qui l'a renversée et le renvoi à US-00.5. Elle n'est plus lisible comme une décision en vigueur. |
| **S6** | `STORY_CERTIFICATION_BOARD.md:208` | ✅ **CORRIGÉ** — « `gh` CLI n'est pas installé » était périmé ; remplacé par l'état réel (2.96.0, `admin: true`) **et** le piège `PATH` (sans lui, l'exit 2 a pour cause « `gh` introuvable » et non le 403 de plan). |
| **S1** | `CLAUDE.md:20` | ⏳ **Maintenu pour US-00.5** — texte normatif, PR dédiée (cf. §6). |
| **S2** | `CONSTITUTION.md:49` | ⏳ **Maintenu pour US-00.5** — idem. |

**Reste donc à transmettre à US-00.5 : S1 et S2 uniquement** (+ la dette #8). S3→S6 sont clos.

**Leçon méthodologique à porter à `/audit-methodo`** : S3 a échappé à la liste de balayage T14, qui
énumérait des fichiers *a priori*. Une relecture « aucune fausse affirmation » devrait balayer le dépôt
par **motif** (`apply_branch_protection`, « protection de branche », « enforced ») et non par liste de
fichiers présumés — sinon son exhaustivité dépend de la justesse de la liste, c'est-à-dire de ce qu'on
cherche justement à vérifier.

### 6 ter. Balayage par MOTIF — 3 occurrences supplémentaires *(2026-07-26, @Architect)*

La leçon ci-dessus a été **appliquée immédiatement** : un balayage par motif (`apply_branch_protection`,
`[Ee]nforced`, « protection de branche ») a trouvé **3 fausses affirmations que la relecture T14 par
liste de fichiers avait manquées**. Toutes **corrigées** :

> ⚠️ **Rectification du 2026-07-26 (finding B-1).** Cette section revendiquait un balayage « **sur tout
> le dépôt** ». **C'était inexact** : il était limité aux fichiers `*.md`, ce qui a laissé passer
> `.github/workflows/ci.yml` (**YAML**) et `scripts/githooks/pre-push` (**shell**) — les deux artefacts
> d'**enforcement**. Périmètre réel et résultats du balayage **toutes extensions** : §6 quater.

| # | Fichier · ligne | Ce qui était faux | Correction |
|---|---|---|---|
| **S7** | `docs/SQUAD_GUIDE.md:285` | « **Jobs requis par la protection de branche** » + titre « **Étage 3 — CI bloquante sur PR** ». **Deuxième** occurrence dans le fichier de S3 — donc même un fichier déjà identifié comme fautif avait été corrigé **partiellement** | Titre → « **rapportée, PAS bloquante** » ; « requis » → « **destinés** à être requis » ; encadré 🔴 rappelant qu'une fusion avec CI rouge reste possible et qu'il faut **lire** les checks |
| **S8** | `docs/epics/EPIC_00-fondations.md:13` | « À l'issue de cet EPIC, la factory est opérationnelle et **chaque règle de gouvernance est effectivement *enforced***. » — objectif présenté comme un acquis | Réserve 🔴 : objectif **non atteint**, impossible sur ce plan, dérogation tracée, **EPIC_00 non complétable** |
| **S9** | `.claude/commands/sprint-status.md:9` | « `factory_sync.py --check` — synchro config ↔ CI ↔ **protection de branche** ». **C'est la formulation qui a effectivement trompé l'orchestrateur au début de la session** : le rituel a rapporté « Synchro factory conforme (env, **protection**, …) » sur un dépôt à `main` grande ouverte | Requalifié **DOCUMENTAIRE**, avertissement « n'appelle jamais l'API », renvoi à `--check-remote`, sémantique de l'exit 2, et consigne explicite de **ne pas rapporter « protection conforme »** |

**S9 est la plus instructive de toute l'US** : le rituel de *constat d'état* portait lui-même la fausse
affirmation, et l'a propagée dans la synthèse d'ouverture de session. Un angle mort de vérification ne
se contente pas de ne rien voir — il **produit activement** de la fausse confiance chez qui le consulte.

### 6 quater. Balayage par motif **TOUTES EXTENSIONS** — méthode, périmètre réel, et ce qui reste ouvert *(2026-07-26, @Developer, correctif B-1)*

**Aucune revendication d'exhaustivité n'est faite ici.** Ce qui est énoncé, c'est une **méthode**, son
**périmètre**, et ses **limites connues** — la leçon du bloquant B-1 étant précisément qu'une relecture
qui se croit complète est plus dangereuse qu'une relecture qui déclare ses angles morts.

**Méthode** — deux passes `grep -rniE … --include="*"` (donc **toutes extensions** : Markdown, YAML,
shell, Python, JSON, `.feature`), exclusions explicites : `.git/`, `build/`, `.dart_tool/`,
`scripts/__pycache__/`, `.claude/settings.local.json`.

| Passe | Motifs |
|---|---|
| **1** | `requis par la protection` · `status checks requis` · `checks bloquants` · `gates? .{0,20}bloquants?` · `merge (empêché\|bloqué) par` · `protection de branche (active\|appliquée\|vérifiée\|en place)` · `est protégée` · `enforced par protection` · `effectivement.{0,5}enforced` |
| **2** *(ajoutée après constat que la passe 1 ratait `CLAUDE.md:20`)* | `\+ protection de branche` · `hooks git \+` · `insensibles? aux bypass` · `bloquantes? sur PR` · `Enforced *:.*protection` |

> 🔴 **Aveu de méthode, à ne pas enjoliver** : la **passe 1 ne trouvait pas `CLAUDE.md:20`**
> (`*Enforced : hooks Claude Code + hooks git + protection de branche.*`) — le motif
> `enforced par protection` ne matche pas une énumération. Il a fallu une **seconde passe**. Un
> balayage par motif est donc **exactement aussi complet que la liste de motifs**, ce qui reproduit,
> un cran plus haut, le défaut du balayage par liste de fichiers. **Conclusion honnête : ni la liste
> de fichiers, ni la liste de motifs ne garantit l'exhaustivité.** La seule garantie serait une
> relecture intégrale du corpus, qui n'a pas été faite.

**Résultats — 4 occurrences supplémentaires, aucune n'était déclarée avant l'audit** :

| # | Fichier · ligne | Ce qui est faux | Traitement | Par |
|---|---|---|---|---|
| **C12** | `.github/workflows/ci.yml:3-4` | « Gates qualité **bloquants** sur CHAQUE PR » + « Ces jobs **sont les status checks requis par la protection de branche** » | ✅ **CORRIGÉ** → « exécutés et **RAPPORTÉS** », « **RAPPORTÉS, PAS BLOQUANTS** », 403 de plan nommé, « une PR peut être fusionnée **AVEC LA CI ROUGE** », statut de **contextes de la cible armée** | @Developer |
| **S10** | `scripts/githooks/pre-push:2-3` | « Le merge passe par une PR (**protection de branche GitHub** : `scripts/apply_branch_protection.sh`) » — le hook justifie son existence par une protection **inexistante**, alors qu'il **est** l'élément (a) du filet de discipline de l'AC-7 | ⛔ **NON ÉDITÉ** — `scripts/githooks/*` est **Art. 6**. **Diff exact fourni** en tâche **T22 [action humaine]** du Story File | @Developer → humain |
| **S11** | `docs/stories/US-00.1-secrets-scan-depot.md:198,215` | « merge **empêché** / **bloqué** par la protection de branche » dans une **tâche** et un **critère de test** | ⛔ **NON ÉDITÉ — décision humaine** : US-00.1 est **certifiée Prod**, l'anti-pattern « modifier une US certifiée sans re-audit » impose une ré-ouverture de cycle. **Transmis à US-00.5** (§6) | @Developer → @PO |
| **S12** | `docs/SQUAD_GUIDE.md:36` *(nœud Mermaid)* | « 🚦 Gates CI **bloquants sur PR** … **insensibles aux bypass locaux** » — **deux** affirmations fausses : ils ne bloquent pas, et rien n'est insensible à un bypass puisque aucun check n'est requis | ⚠️ **SIGNALÉ, non édité** — hors des fichiers déclarés de l'US. **3ᵉ occurrence du même fichier** (après S3 et S7) | @Developer → @Architect |

**Observation complémentaire, sans action demandée** : `docs/epics/EPIC_00-fondations.md:13` (« chaque
règle de gouvernance est effectivement *enforced* ») a été traité par **ajout d'une réserve 🔴 adjacente**
(S8), la phrase elle-même étant conservée. Elle **reste donc fausse lue isolément** — c'est une
mitigation, pas une correction. Choix légitime (l'objectif d'EPIC est un texte de cadrage), mais à
connaître : un `grep` la remontera toujours.

**Ce qui reste OUVERT après ce balayage** :
1. **S1, S2, S11** → US-00.5 (textes normatifs + US certifiée).
2. **S10** → action humaine T22 (Art. 6).
3. **S12** → arbitrage @Architect.
4. **L'exhaustivité elle-même** → non garantie, par construction (voir l'aveu de méthode ci-dessus).

**Leçon à porter à `/audit-methodo`** — en trois temps, parce qu'elle a été apprise trois fois :
(i) balayer par **liste de fichiers** rate les fichiers non listés (S3) ; (ii) balayer par **motif sur
les `*.md`** rate les artefacts d'enforcement en YAML et shell (C12, S10) ; (iii) balayer par **motif
toutes extensions** rate encore ce que la liste de motifs ne prévoit pas (`CLAUDE.md:20`). Une
relecture « aucune fausse affirmation » doit donc **déclarer sa méthode et ses angles morts**, et
**jamais** revendiquer l'exhaustivité.

**Bilan consolidé de la relecture** : **12 corrections** dans le périmètre @Developer (C1→C12), **4**
occurrences hors périmètre corrigées par @Architect (S3→S6), **3** trouvées par balayage `*.md` et
corrigées (S7→S9), **3** signalées et non éditées (**S10** action humaine, **S11** US certifiée,
**S12** @Architect), **2** délibérément maintenues pour US-00.5 (S1, S2). **Exhaustivité : non
revendiquée.**

---

## 7. Index des preuves de ce répertoire

Voir [`README.md`](README.md).
