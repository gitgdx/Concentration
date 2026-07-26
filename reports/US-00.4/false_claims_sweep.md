# Relecture ciblée « aucune fausse affirmation » — US-00.4

**Tâche T14** · 2026-07-26 · @Developer.
**Question posée à chaque fichier** : ce texte affirme-t-il, ou laisse-t-il croire, que `main` **est**
ou **devient** protégée · que les status checks sont **requis** ou **bloquants** · que la cible de
protection est **active**, **appliquée** ou **en vigueur** ?

Chaque occurrence est **corrigée** ou **justifiée** (négation, conditionnel explicite, ou citation
d'un énoncé démenti). Les occurrences trouvées **hors périmètre** sont **signalées, jamais éditées**.

---

> 🔴 **Rectification du 2026-07-26 — finding B-1 de l'audit Revue.** La première version de ce rapport
> concluait « **0 occurrence non justifiée subsistante** » sur la base de 7 balayages **limités à une
> liste de fichiers**. L'audit à contexte frais a démoli cette conclusion avec **mes propres motifs** :
> **4 occurrences** manquaient, dont **2 dans des artefacts d'enforcement** (`.github/workflows/ci.yml`
> en YAML, `scripts/githooks/pre-push` en shell) et **1 dans une US certifiée**. Elles sont ajoutées
> ci-dessous (**C12**, **S10**, **S11**, **S12**) avec un balayage **toutes extensions** (§Méthode bis).
> **Aucune revendication d'exhaustivité n'est maintenue** — voir §Verdict.

## Méthode — 7 balayages outillés

| # | Motif recherché | Cible |
|---|---|---|
| 1 | `protégée`, `protection active`, `est/sont appliquée(s)`, `en vigueur`, `protections appliquées` | livrables de l'US |
| 2 | `checks (sont/deviennent) requis/bloquants`, `devient effective`, `incontournable` | livrables de l'US |
| 3 | `exécuter/lancer … apply_branch_protection`, `sh scripts/apply_branch_protection` | `docs/`, `scripts/`, `reports/`, `.claude/commands/` |
| 4 | `protection de branche (active/appliquée/vérifiée/en place)`, `enforced par protection`, `requis par la protection` | fichiers **hors périmètre** (SCB, BACKLOG, EPIC_00, CLAUDE.md, Constitution, TRACKS) |
| 5 | affirmations **au présent** dans le Story File | `docs/stories/US-00.4-*.md` |
| 6 | encadrement du démenti | `docs/adr/ADR-006-*.md` |
| 7 | le mot autorisé au **seul** exit 0, hors exit 0 | `reports/US-00.4/check_remote_*.txt` |

Fichiers balayés : `docs/GIT_PROTECTION.md` · `docs/adr/ADR-006-protection-branche-principale.md` ·
`docs/stories/US-00.4-ci-protection-branche.md` · `scripts/apply_branch_protection.sh` ·
`scripts/check_branch_protection.py` · `.claude/commands/audit-methodo.md` · `reports/US-00.4/**` ·
`tests/fixtures/US-00.4/**`.

---

## 1. Occurrences CORRIGÉES (dans mon périmètre) — 11

| # | Fichier | Ce qui était écrit | Pourquoi c'était un défaut | Correction |
|---|---|---|---|---|
| **C1** | `docs/GIT_PROTECTION.md` — **en-tête** | « ✅ **Application automatisée** : exécuter `sh scripts/apply_branch_protection.sh` … ⚠️ Tant que ce script n'a pas été exécuté, ces protections **ne sont PAS actives** » | Le défaut le plus grave du corpus : présentait l'application comme une **simple commande à lancer**, alors qu'elle **échoue en 403**. Un lecteur en concluait « il suffit de l'exécuter » — faux | **En-tête intégralement remplacé** par un encadré `⛔ main N'EST PAS PROTÉGÉE — et ne peut pas l'être sur ce dépôt (constat du 2026-07-26)`, avec les 403 sur les **deux** mécanismes et le renvoi à ADR-006 |
| **C2** | `docs/GIT_PROTECTION.md` §1 « Require a pull request » | « `Require approvals` **coché**, `Required number of approvals` réglé selon `factory.config.json` » | Incohérent avec la cible arbitrée (`0`) et laissait croire à un réglage **en vigueur** | Réécrit : `Require approvals` **décoché** (cible `0`), + l'avertissement « `0` approbation **≠** pas de PR exigée » et le caractère **daté** du réglage (2ᵉ collaborateur → retour à `1`) |
| **C3** | `docs/GIT_PROTECTION.md` §4 « Restrict who can push » | « Réserver la fusion finale à l'@Architect ou au release manager désigné » | Décrivait une restriction **absente** de la cible générée (`restrictions: null`) : l'appliquer créerait une **dérive** que `--check-remote` signalerait en exit 1. Et présentait une exigence de **process** comme une barrière machine | Réécrit : **ne pas activer** ; l'exigence de revue est **de process**, portée par **aucune** barrière machine — ni aujourd'hui, ni après déblocage |
| **C4** | `docs/GIT_PROTECTION.md` §Vérification, ligne du code **0** | « Le déblocage a eu lieu **et** la protection est appliquée → exécuter le test négatif » | Formulation **assertive** dans une cellule de tableau : lue hors contexte, elle se lit comme un état constaté | Reformulé au **conditionnel explicite** : « Signifierait que … (ce qui **n'est pas le cas au 2026-07-26**) », + mention que **cette issue n'a jamais été obtenue sur ce dépôt** |
| **C5** | `docs/GIT_PROTECTION.md` §Cible armée, bloc de commande | ```sh``` nu contenant `sh scripts/apply_branch_protection.sh gitgdx/Concentration` | Un bloc de commande **isolé** est ce qu'un lecteur pressé copie-colle en premier | Deux lignes de commentaire **dans le bloc lui-même** : `⛔ NE PAS EXÉCUTER AUJOURD'HUI — échouerait en 403` |
| **C6** | `docs/GIT_PROTECTION.md` — **bloc généré** `FACTORY_SYNC` | En-tête de colonne « **Status check requis** » | **Faux** : aucun de ces 4 checks n'est requis. ⚠️ **Non corrigeable ici** : le bloc est généré par `scripts/factory_sync.py` (**Art. 6**) et toute édition manuelle casse `--check`, donc le job CI `governance` | **Mitigé** par un avertissement placé **immédiatement avant** le bloc (« aucun de ces 4 checks n'est requis aujourd'hui — ce sont les contextes de la cible armée »). **Dette #8** de `enforcement_gap.md` → action humaine |
| **C7** | `scripts/apply_branch_protection.sh` — en-tête | « Applique **RÉELLEMENT** les protections de branche » sans réserve | Le script se présentait comme opérationnel | En-tête complété (T5) : `⚠️ NON APPLICABLE au 2026-07-26 … PRÊT et CONDITIONNÉ AU DÉBLOCAGE : il n'est PAS « à exécuter »`. **Logique `PUT` inchangée** |
| **C8** | `scripts/apply_branch_protection.sh` — sortie finale | `echo "✅ Protections appliquées. Vérifier : gh api …"` | Affirmait le **résultat** (« appliquées ») alors que seule la **requête** peut être constatée | `✅ Requête PUT acceptée par la plateforme.` + renvoi à `--check-remote` (vérification champ par champ) et à l'archivage de la réponse brute |
| **C9** | `reports/US-00.4/check_remote_exit2.txt` (**mon propre livrable**) | Ligne de contrôle : « occurrences de la racine « conform » : 0 » | **Auto-contradiction** : la ligne de contrôle contenait elle-même le mot dont elle affirmait l'absence → un audit par grep aurait trouvé 1 occurrence et invalidé le critère #9 | Ligne reformulée **sans** écrire le mot : « le mot autorisé au SEUL exit 0 (critère #9) est-il absent de tout ce fichier ? **OUI — 0 occurrence** ». Vérifié : `grep -ci "conform"` → **0** |
| **C10** | `.claude/commands/audit-methodo.md` (**mon propre livrable T11**) | Cellule du code **0** : « Protection applicable **et** appliquée » | Même défaut que C4 dans un tableau de sémantique : cellule **assertive**, lue hors contexte comme un état | Reformulé : « **Signifierait** que la protection est applicable et appliquée — **issue JAMAIS obtenue sur ce dépôt à ce jour** » |
| **C11** | `scripts/check_branch_protection.py` (docstring) | « Aucun `-X PUT/POST/PATCH/DELETE` » | Le contrôle négatif du critère #11 est **textuel** : il matchait cette **déclaration d'absence** et faisait échouer le critère | Reformulé (« aucune méthode d'écriture (PUT, POST, PATCH, DELETE), aucun drapeau de méthode ») + avertissement inscrit dans le docstring pour ne pas réintroduire la forme littérale. *(Corrigé dès T2, consigné ici pour la traçabilité.)* |
| **C12** | `.github/workflows/ci.yml:3-4` **(finding B-1)** | « Gates qualité **bloquants** sur CHAQUE PR » + « Ces jobs **sont les status checks requis par la protection de branche** (`scripts/apply_branch_protection.sh`) » | 🔴 **Deux affirmations fausses dans un artefact d'enforcement lu par toute la squad**, et porteur des 4 contextes. **Aggravant** : l'US a **examiné ce fichier** (vérification des 4 libellés vs `status_checks`) puis l'a déclaré « NON modifié » **sans voir son en-tête**. Manqué par tous les balayages précédents parce qu'ils se limitaient aux `*.md` | ✅ **CORRIGÉ** : « exécutés et **RAPPORTÉS** » ; encadré `⚠️ RAPPORTÉS, PAS BLOQUANTS` avec le 403 de plan sur les deux mécanismes, « une PR peut être fusionnée **AVEC LA CI ROUGE** », consigne de **lire** les checks (`gh pr checks`), et statut de **contextes de la cible armée** destinés à devenir requis au déblocage. **Aucune ligne de logique touchée** — `factory_sync.py --check` reste exit 0 (les 4 libellés résolvent) |

## 2. Occurrences JUSTIFIÉES — conservées telles quelles

| Fichier | Occurrence | Justification |
|---|---|---|
| `docs/GIT_PROTECTION.md`, `enforcement_gap.md`, ADR-006, `audit-methodo.md` | `main` **n'est pas** protégée · branche **non** protégée · protection **absente** | **Négations** — c'est le constat lui-même |
| `docs/GIT_PROTECTION.md` §Cause racine, `enforcement_gap.md` §2, ADR-006 | « `factory.config.json` déclarait … 4 status checks **requis** que le compte n'a jamais pu appliquer » | Décrit la **cible déclarée** au passé, explicitement suivie de « n'a jamais pu appliquer » |
| `docs/GIT_PROTECTION.md` §Conditions de déblocage, ADR-006 | « ce qui serait débloqué : … status checks **requis**, `enforce_admins` effectif » | **Conditionnel** portant sur un futur déblocage non advenu |
| `ADR-006` §193-198 | « la règle passe de déclarée à **effective** », « **incontournables**, administrateur inclus », « refusés par le serveur » | **Citations d'énoncés DÉMENTIS** : la section s'intitule « ⛔ Ce que cette décision ne fait PAS — démenti explicite » et conclut « **Ces quatre affirmations sont fausses et sont ici démenties** » |
| Story File, ligne 117 et 967 | « les 8 PR fusionnées l'ont toutes été **sans protection active** » | Négation, et fait exact |
| Story File, ligne 945 | critère #14, qui **énumère** les motifs interdits | C'est la **consigne de contrôle**, pas une affirmation |
| `reports/US-00.4/check_remote_simulated.txt` | « **conforme** à la cible générée » | Chemin **exit 0** — le seul où le mot est autorisé — et **encadré** de `[SIMULATION] ` + « SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt ». Le fichier porte en tête `⛔ CE FICHIER N'EST PAS UNE PREUVE DE L'ÉTAT RÉEL DU DÉPÔT ⛔` |
| `reports/US-00.4/branch_main_before.json` | « Aucun status check **requis**, aucune protection **en vigueur** » | Négations, adossées au corps brut (`"enforcement_level":"off"`) |

## 3. ⚠️ Occurrences SIGNALÉES — hors de mon périmètre, NON éditées

> **À traiter par @ProductOwner / @Architect.** Aucune de ces lignes n'a été modifiée : leurs fichiers
> relèvent du périmètre métier / gouvernance, ou ne figurent pas dans les fichiers déclarés de cette US.

| # | Fichier · ligne | Texte | Problème | Destinataire |
|---|---|---|---|---|
| **S1** | `CLAUDE.md` **:20** (règle 2) | « *Enforced : hooks Claude Code + hooks git + **protection de branche**.* » | **FAUX** et le reste après cette US. *(Le fichier porte déjà, lignes 57-66, un encadré d'avertissement — mais le texte de la règle lui-même n'est pas corrigé.)* | **US-00.5 — OBLIGATOIRE** (voir `enforcement_gap.md` §6) |
| **S2** | `docs/governance/CONSTITUTION.md` **:49** (Art. 4) | « **Enforcement** : CI `ci.yml` jobs qualité, **requis par la protection de branche** (`scripts/apply_branch_protection.sh`) » | **FAUX**. Aucun job n'est requis par quoi que ce soit | **US-00.5 — OBLIGATOIRE** |
| **S3** | `docs/SQUAD_GUIDE.md` **:321** (§6.3 Axes d'amélioration) | « Exécuter `sh scripts/apply_branch_protection.sh` (droits admin requis). » | **Présenté comme une action à exécuter** — elle **échouerait en 403**. C'est exactement le défaut C1, dans un autre fichier. ⚠️ **Ce fichier n'est ni dans la liste de balayage de T14, ni dans les fichiers déclarés de l'US** → je ne l'édite pas, mais c'est une **découverte à traiter** | **@Architect** — à rattacher à US-00.5 ou à une correction dédiée |
| **S4** | `docs/epics/EPIC_00-fondations.md` **:25** (§Critères de performance et sécurité) | « `ci.yml` vert sur une PR de test ; **protection de branche appliquée et vérifiée**. » | **Contredit la ligne 80 du même fichier**, qui porte déjà la version corrigée (« IMPOSSIBLE À COCHER SUR CE PLAN »). Deux critères contradictoires cohabitent | **@ProductOwner / @ScrumMaster** |
| **S5** | `STORY_CERTIFICATION_BOARD.md` **:206** | « **Aucun amendement de `CLAUDE.md` ni de la Constitution** : cette US rend la déclaration « *enforced par protection de branche* » **vraie** — il n'y a rien à corriger. » | **Décision périmée** du matin du 2026-07-26, **invalidée** par le re-cadrage, et laissée **sans marque de révision** dans le journal de décisions du SCB. Un auditeur en contexte frais peut la lire comme la position courante | **@ProductOwner / @Architect** — à marquer « révisée » |
| **S6** | `STORY_CERTIFICATION_BOARD.md` **:208** | « `gh` CLI **n'est pas installé** (`gh: not recognized`) » | **Périmé** : `gh 2.96.0` est installé et authentifié (`{"admin": true}`) — c'est avec lui que les preuves de cette US ont été obtenues | **@Architect** |
| **S10** | `scripts/githooks/pre-push` **:2-3** *(finding B-1)* | « Le merge passe par une PR (**protection de branche GitHub** : `scripts/apply_branch_protection.sh`) » | 🔴 Le hook **justifie son existence par une protection inexistante** — alors qu'il **EST** l'élément (a) du filet de discipline de l'AC-7. Son propre commentaire contredit l'AC qu'il sert. ⛔ **`scripts/githooks/*` est Art. 6** : un agent ne peut pas l'éditer | **[action humaine]** — **diff exact fourni** en **T22** du Story File |
| **S11** | `docs/stories/US-00.1-secrets-scan-depot.md` **:198** (T8) et **:215** (critère #6) *(finding B-1)* | « job `secrets-scan` **rouge** → **merge empêché par la protection de branche** » · « Job `secrets-scan` rouge + **merge bloqué par la protection de branche** » | 🔴 Une **tâche** et un **critère de test** d'une US **CERTIFIÉE Prod** décrivent un mécanisme de blocage **inexistant** : le test négatif CI ne peut pas prouver ce qu'il annonce. ⛔ **Décision humaine rendue** : US-00.1 étant certifiée, l'anti-pattern « modifier une US certifiée sans re-audit » impose une ré-ouverture de cycle → **on signale et on transmet, sans toucher une ligne** | **US-00.5** — transmis en `enforcement_gap.md` §6 |
| **S12** | `docs/SQUAD_GUIDE.md` **:36** *(nœud Mermaid — découverte du balayage toutes extensions)* | « 🚦 Gates CI **bloquants sur PR** … **insensibles aux bypass locaux** » | **Deux** affirmations fausses : ils ne bloquent pas la fusion, et rien n'est « insensible aux bypass » puisque **aucun check n'est requis** — un bypass local suivi d'une fusion avec CI rouge reste possible. ⚠️ **3ᵉ occurrence du même fichier** (après S3 ligne 321 et S7 ligne 285) : troisième démonstration qu'une correction **partielle** d'un document laisse des affirmations fausses en place | **@Architect** — hors des fichiers déclarés de l'US |

## 4. Contrôles finaux

```
$ grep -ci "conform" reports/US-00.4/check_remote_exit2.txt
0

$ grep -c "conforme à la cible générée — SOURCE SIMULÉE" reports/US-00.4/check_remote_simulated.txt
1

$ grep -nE "protection (est|sera) appliquée|main est protégée|protection active|devient effective|checks (sont|deviennent) (requis|bloquants)" docs/stories/US-00.4-ci-protection-branche.md
(aucun résultat)
```

## 4 bis. Méthode bis — balayage par motif **TOUTES EXTENSIONS** (correctif B-1)

Les 7 balayages du §Méthode portaient sur une **liste de fichiers**. C'est ce qui a produit le
bloquant B-1. Le balayage ci-dessous porte sur **tout le dépôt et toutes les extensions** (Markdown,
YAML, shell, Python, JSON, `.feature`), exclusions : `.git/`, `build/`, `.dart_tool/`,
`scripts/__pycache__/`, `.claude/settings.local.json`.

```
$ grep -rniE "requis par la protection|status checks requis|checks bloquants|gates? .{0,20}bloquants?|\
merge (empêché|bloqué) par|protection de branche (active|appliquée|vérifiée|en place)|est protégée|\
enforced par protection|effectivement.{0,5}enforced" . --include="*"
```

**Occurrences retenues comme fausses** (les autres sont des négations, des conditionnels, des
citations d'énoncés démentis, ou des emplois légitimes de « gate bloquant » au sens **CI**, où le job
fait bien échouer le run) :

```
./.github/workflows/ci.yml:3-4                     -> C12  ✅ CORRIGÉ
./scripts/githooks/pre-push:2-3                    -> S10  ⛔ Art. 6 → diff T22
./docs/stories/US-00.1-secrets-scan-depot.md:198   -> S11  ⛔ US certifiée → US-00.5
./docs/stories/US-00.1-secrets-scan-depot.md:215   -> S11  ⛔ idem
./docs/SQUAD_GUIDE.md:36                           -> S12  ⚠️ signalé @Architect
./docs/epics/EPIC_00-fondations.md:13              -> S8, mitigé par réserve adjacente (phrase conservée)
```

**Seconde passe, rendue nécessaire par un trou de la première** :

```
$ grep -rniE "\+ protection de branche|hooks git \+|insensibles? aux bypass|bloquantes? sur PR|Enforced *:.*protection" . --include="*"
./CLAUDE.md:20:   fichier `.env` ou d'enforcement. *Enforced : hooks Claude Code + hooks git + protection de branche.*
./docs/SQUAD_GUIDE.md:36:    C["🚦 Gates CI bloquants sur PR\n(… insensibles aux bypass locaux)"]
```

> 🔴 **À dire sans enjoliver : la passe 1 ne trouvait pas `CLAUDE.md:20`** — le motif
> `enforced par protection` ne matche pas l'énumération
> `*Enforced : hooks Claude Code + hooks git + protection de branche.*`. Il a fallu une **seconde
> passe** avec de nouveaux motifs. **Un balayage par motif n'est donc exactement aussi complet que sa
> liste de motifs** : c'est le même défaut que le balayage par liste de fichiers, un cran plus haut.

## 5. Verdict — **l'exhaustivité n'est PAS revendiquée**

**Dans mon périmètre : 12 occurrences corrigées** (C1→C12).
**Non corrigeables dans ce périmètre, et pourquoi** :

| Occurrence | Raison de non-correction | Porteur |
|---|---|---|
| **C6** — en-tête « Status check requis » du bloc **généré** de `GIT_PROTECTION.md` | Généré par `scripts/factory_sync.py` (**Art. 6**) ; toute édition manuelle casse `--check`, donc le job CI `governance` | Action humaine — mitigé par un avertissement adjacent, dette #8 |
| **S10** — `scripts/githooks/pre-push` | `scripts/githooks/*` est **Art. 6** | **T22 [action humaine]**, diff exact fourni |
| **S11** — `docs/stories/US-00.1-*.md` | US **certifiée Prod** : la modifier sans re-audit est un anti-pattern déclaré | **US-00.5**, décision humaine rendue |
| **S12** — `docs/SQUAD_GUIDE.md:36` | Hors des fichiers déclarés de l'US | **@Architect** |
| **S1, S2** — `CLAUDE.md:20`, `CONSTITUTION.md:49` | Textes normatifs | **US-00.5 — OBLIGATOIRE** |
| **S8** — `EPIC_00:13` | Traité par réserve adjacente ; la phrase reste fausse lue isolément | @PO / @ScrumMaster, si jugé nécessaire |

**Ce que ce rapport NE garantit PAS.** La version précédente concluait « 0 occurrence non justifiée
subsistante » : l'audit Revue l'a **falsifiée avec mes propres motifs**. Trois enseignements cumulés,
appris trois fois de suite :

1. Balayer par **liste de fichiers** rate les fichiers non listés → S3.
2. Balayer par **motif sur les `*.md`** rate les artefacts d'enforcement en **YAML** et **shell** →
   C12, S10.
3. Balayer par **motif toutes extensions** rate encore ce que la **liste de motifs** ne prévoit pas →
   `CLAUDE.md:20`, trouvé seulement en seconde passe.

**Conclusion honnête : aucune de ces méthodes ne garantit l'exhaustivité, et ce rapport ne la
revendique plus.** Ce qu'il garantit : la **méthode est écrite**, le **périmètre est déclaré**, les
**angles morts sont nommés**, et **tout ce qui a été trouvé est soit corrigé, soit signalé avec son
porteur** — jamais passé sous silence. La seule garantie d'exhaustivité serait une relecture intégrale
du corpus, qui **n'a pas été faite**.
