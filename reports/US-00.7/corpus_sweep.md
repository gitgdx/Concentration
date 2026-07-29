# US-00.7 · T7 — **Balayage inverse du corpus** : deux passes, toutes extensions, exhaustivite NON revendiquee

> ## 🔴 AJOUT DU 2026-07-29 — **IL MANQUAIT UNE TROISIÈME PASSE. C'est la cause des QUATRE `🧪 FAIL`.**
>
> *(Établi par le 4ᵉ passage QA — `qa_reaudit3.md`. Cette section est **additive** : le corps du rapport
> ci-dessous, daté du 2026-07-28, n'est **pas** réécrit.)*
>
> Ce balayage comporte **deux** passes : **(1) affirmation d'impossibilité** et **(2) sur-affirmation**.
> **Aucune des deux ne détecte la classe qui a fait échouer l'US quatre fois** :
>
> ### 🆕 PASSE 3 — **SOUS-AFFIRMATION PÉRIMÉE**
> > *« Le corpus vivant affirme qu'une preuve **obtenue depuis** manque encore. »*
>
> Ce n'est **ni** une impossibilité, **ni** une sur-affirmation : c'est une **modestie devenue fausse**.
> Elle est **invisible** aux deux passes d'origine — et d'autant plus insidieuse qu'elle a l'apparence
> de la rigueur. **Une US qui prouve quelque chose crée mécaniquement cette classe de défaut** dans tout
> texte rédigé avant la preuve.
>
> ### 🆕 PASSE 4 — **ÉTAT DE DÉCISION PÉRIMÉ**
> > *« Le corpus affirme qu'une case / un critère / une dette est dans un état qu'il a quitté depuis. »*
>
> Révélée par la case 34, **décochée puis recochée le même jour** : le corpus s'est retrouvé
> **incohérent dans les deux sens simultanément**.
>
> ### Deux leçons de méthode, payées par quatre échecs
>
> 1. **⛔ `~~texte~~` est INVISIBLE à `grep`** — or ce projet audite son corpus **par `grep`**. Barrer
>    donne l'apparence de la rigueur **en la soustrayant à l'outil qui la vérifie**. → marqueur
>    **littéral** `PÉRIMÉ-<date>`, posé **sur la ligne même** de l'assertion, jamais sur une ligne voisine.
> 2. **La correction doit suivre le DÉFAUT, pas le RENVOI.** *« Un renvoi cite un exemple ; le défaut a
>    une extension. »* Trois corrections successives ont échoué pour avoir traité les lignes **citées**
>    au lieu de la **classe**. Méthode : **définir la classe → balayer tout le corpus → vérifier par
>    l'outil que 0 occurrence subsiste non marquée**.
>
> ⚠️ **Conséquence pour la grille des 28 critères de test** : elle **n'a aucun contrôle** pour ces deux
> classes. Les critères **22** et **24** sont **légitimement levés** — ils ne couvrent simplement pas ce
> cas. **C'est une lacune de la grille, pas une tricherie sur les critères.** → à porter en **US-00.8**.

> ⛔ **L'EXHAUSTIVITE DE CE BALAYAGE N'EST PAS REVENDIQUEE.** C'est la lecon des **quatre** echecs
> d'exhaustivite d'US-00.4 (liste de fichiers -> `*.md` -> toutes extensions -> index) : **ni une liste
> de fichiers, ni une liste de motifs ne garantit l'exhaustivite**. Ce qui est revendique ici : la
> **methode est ecrite**, le **perimetre est declare**, les **angles morts sont nommes**, et
> **chaque** resultat est classe. Rien de plus.
>
> **Ce document INVENTORIE. Il ne corrige rien** : les corrections relevent de T12 -> T20, apres le
> `PUT` (une assertion ne devient vraie qu'apres l'application).

| Champ | Valeur |
|---|---|
| Tache | **T7** — phase 0, aucune ecriture distante |
| AC | **AC-5** (corpus) et **AC-5 limite** (methode + angles morts) |
| Critere de test leve | **13** (conditionne AVANT `PUT`) |
| Date | **2026-07-27** |
| Etat du depot au balayage | branche `feat/US-00.7-application-protection-branche`, `HEAD` = `90fd1a6`, `origin/main` = `f4400ca` |

---

## 1. Methode — exactement ce qui a ete execute

**Deux passes obligatoires**, plus **une troisieme complementaire** que j'ai ajoutee (§5).

```sh
# exclusions declarees, communes aux trois passes
EXD='--exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=__pycache__'

# PASSE 1 — affirmations d'IMPOSSIBILITE (14 motifs)
for m in "n(e peut|'est) pas (l'être|protégée)" "indisponible" "NON APPLICABLE" \
         "impossible à cocher" "NE PAS EXÉCUTER" "Upgrade to GitHub Pro" "403 de plan" \
         "cible armée" "conditionné au déblocage" "report(é|ée) au déblocage" \
         "RAPPORTÉS, PAS BLOQUANTS" "DETTE MAJEURE" "NON ATTEIGNABLE" "non protégée" ; do
  grep -rniE $EXD --include="*" -- "$m" . | grep -v '^\./\.claude/settings\.local\.json:'
done

# PASSE 2 — SUR-AFFIRMATIONS (7 motifs) — le risque SYMETRIQUE, celui de cette US
for m in "inviolable" "tout est enforced" "toutes? les règles sont" "chaîne de confiance" \
         "impossible à contourner" "garantit" "ne peut plus" ; do
  grep -rniE $EXD --include="*" -- "$m" . | grep -v '^\./\.claude/settings\.local\.json:'
done

# PASSE 3 (complementaire, ajoutee) — routage vers ADR-006 comme decision COURANTE
grep -rniE $EXD --include="*" "ADR-006" . | grep -v '^\./\.claude/settings\.local\.json:'
```

`--include="*"` : **toutes extensions** — Markdown **et** YAML **et** shell **et** Python **et** JSON
**et** `.feature` **et** `.jsonl` **et** fichiers sans extension (`scripts/githooks/pre-push`).

**Volumetrie passe 1** : **352** couples *(fichier:ligne, motif)* distincts, repartis sur **40**
fichiers.

### 1.1 Un piege de methode rencontre, et signale

`--exclude=settings.local.json` **n'a PAS fonctionne** sur cette plateforme (GNU grep 3.0, MSYS,
racine de recherche `.`) : le fichier restait dans les resultats. Il fonctionne quand la racine est
`.claude/`, et pas quand elle est `.`. J'ai donc remplace l'exclusion par un **post-filtre explicite**
`grep -v '^\./\.claude/settings\.local\.json:'`, verifiable dans la commande ci-dessus.
**A retenir** : une exclusion qui echoue en silence est exactement la classe d'erreur de methode qui
a coute quatre iterations a US-00.4. Un balayage doit **prouver** que son perimetre est celui qu'il
declare, pas le supposer.

---

## 2. Angles morts DECLARES

| # | Angle mort | Pourquoi il subsiste |
|---|---|---|
| 1 | `.claude/settings.local.json` | **exclu par decision**. Contenu : liste de permissions d'outils generee par la machine — les correspondances y sont des **fragments de commandes passees** (bruit), pas des affirmations de gouvernance. Non lu par un auditeur. |
| 2 | `scripts/__pycache__/*.pyc` | binaires generes, non lisibles, regeneres a chaque execution. |
| 3 | `.git/`, `build/`, `.dart_tool/` | artefacts d'outillage, non versionnes comme corpus. |
| 4 | **L'historique Git** (messages de commit, contenus de revisions anterieures) | le balayage porte sur l'**arbre de travail courant**, jamais sur l'historique — que cette US **ne reecrit pas**. Une affirmation perimee dans un vieux message de commit **reste** et **doit** rester. |
| 5 | **Hors du depot** : descriptions de PR et d'issues GitHub, wiki, `README` de l'organisation, discussions | inatteignables par `grep`. **Non verifie, non revendique.** |
| 6 | **Motifs en anglais** | les 14 + 7 motifs sont quasi tous **francophones** (seule exception : `Upgrade to GitHub Pro`). Une affirmation d'impossibilite ecrite en anglais serait **manquee**. |
| 7 | **Paraphrases semantiques** | c'est **la** limite irreductible : « le serveur ne bloque rien aujourd'hui », « la CI est purement informative », « on ne peut pas encore compter sur GitHub » ne matchent **aucun** motif. Aucune liste de motifs ne ferme cet angle — **seule une relecture humaine le ferait**. |
| 8 | **Blocs generes** | le bloc `<!-- FACTORY_SYNC:BEGIN --> … END -->` de `docs/GIT_PROTECTION.md` est **regenere depuis `factory.config.json`** : le corriger a la main serait inutile (ecrase) et interdit. Sa dette propre (#6) est traitee separement. |
| 9 | **Fichiers binaires** | aucun trouve dans le perimetre, mais `grep` ne les inspecte pas : non revendique. |
| 10 | **Date du balayage** | constat du **2026-07-27** sur `HEAD = 90fd1a6`. Tout commit ulterieur peut reintroduire une affirmation perimee — c'est pourquoi T23 impose de **re-jouer** les deux passes en fin d'US. |

---

## 3. PASSE 1 — inventaire classe

### 3.1 Les **11 artefacts VIVANTS** de l'inventaire @Architect — **confirmes, avec leurs lignes**

Un artefact « vivant » est lu **au present** par un intervenant ou un auditeur, et son affirmation
d'impossibilite est donc **operante**.

| # | Artefact vivant | Occ. | Lignes (passe 1) | Motifs rencontres | Porteur | Tache |
|---|---|---|---|---|---|---|
| 1 | `CLAUDE.md` | **7** | 62, 63, 71, 75 (x2), 77, 117 | `indisponible` · `Upgrade to GitHub Pro` · `impossible à cocher` (x2) · `DETTE MAJEURE` (x2) · `n'est pas protégée` | agent | **T12** |
| 2 | `docs/epics/EPIC_00-fondations.md` | **6** | 15, 16, 33, 66, 76 (x2) | `ne peut pas l'être` · `indisponible` (x2) · `NON ATTEIGNABLE` · `cible armée` · `Upgrade to GitHub Pro` | agent | **T13** |
| 3 | `docs/GIT_PROTECTION.md` | **13** | 1, 3, 7, 37, 100, 121, 128, 143, 179, 182, 194, 217, 276 | `cible armée` (x4) · `n'est pas protégée` (x3) · `Upgrade to GitHub Pro` · `NE PAS EXÉCUTER` · `NON APPLICABLE` · `403 de plan` (x2) · `non protégée` | agent | **T14** |
| 4 | `.github/workflows/ci.yml` | **4** | 5, 6, 8, 13 | `RAPPORTÉS, PAS BLOQUANTS` · `ne peut pas l'être` · `Upgrade to GitHub Pro` · `NON APPLICABLE` | agent | **T15** |
| 5 | `scripts/apply_branch_protection.sh` | **3** | 6, 7, 8 | `NON APPLICABLE` · `indisponible` · `Upgrade to GitHub Pro` | agent | **T16** |
| 6 | `scripts/check_branch_protection.py` | **7** *(dont **2 seulement** a corriger)* | 12, **24**, 73, 74, 862, 870, 892 | voir **§3.2** — la majorite sont **legitimes** | agent | **T17** |
| 7 | `.claude/commands/audit-methodo.md` | **3** | 19, 30, 36 | `n'est pas protégée` · `403 de plan` (x2) | agent | **T18(a)** |
| 8 | `.claude/commands/sprint-status.md` | **2** | 13, 14 | `indisponible` · `403 de plan` | agent | **T18(b)** |
| 9 | `docs/SQUAD_GUIDE.md` | **6** | 32, 33, 300, 340, 341, 343 | `indisponible` (x3) · `Upgrade to GitHub Pro` · `NE PAS EXÉCUTER` · `conditionné au déblocage` | agent | **T19(a)** |
| 10 | `tests/fixtures/US-00.4/README.md` | **1** | 4 | `Upgrade to GitHub Pro` | agent — **historisation ADDITIVE seule** | **T19(b)** |
| 11 | **`scripts/githooks/pre-push`** | **3** | 6 (x2), 11 | `Upgrade to GitHub Pro` · `ne peut pas l'être` · `NON APPLICABLE` | **HUMAIN — Art. 6** | **T20** |

**Total corpus vivant : 55 occurrences** *(dont 5 legitimes dans `check_branch_protection.py`, cf.
§3.2 -> **50 a traiter**)*. Trois de ces artefacts — `ci.yml`, `pre-push`, `SQUAD_GUIDE.md` — ont ete
**crees par US-00.4 elle-meme** en reponse a son propre finding B-1 : les laisser reproduirait le
defaut **a l'endroit exact ou il a ete corrige**, en sens inverse.

### 3.2 `scripts/check_branch_protection.py` — **5 occurrences sur 7 sont LEGITIMES**

Distinction essentielle, a ne pas manquer en audit : ce module **traite** le 403 de plan comme un cas
**legitime de l'outil**. Ces mentions ne sont **pas** des affirmations d'etat, ce sont des
**messages d'erreur conditionnels**.

| Ligne | Contenu | Verdict |
|---|---|---|
| **24-25** | docstring : « `apply_branch_protection.sh`, **PRET mais CONDITIONNE AU DEBLOCAGE** (403 de plan au 2026-07-26…) » | 🔴 **AFFIRMATION D'ETAT devenue FAUSSE** -> seule cible de **T17** |
| 12 | docstring, tableau des issues : « 403 de plan » comme **cause possible** d'un exit 2 | ✅ **legitime** — decrit un comportement, pas un etat |
| 73-74 | commentaire de `PLAN_MARKER` : « quand la protection n'est pas incluse dans le plan du depot » | ✅ **legitime** — documente une detection |
| 862, 870 | messages de `_attribute()` pour les 403 (plan / droits) | ✅ **legitime** — le 403 **redeviendrait reel** si le depot repassait en prive |
| 892 | message du chemin 404 : « la branche n'est reellement PAS protegee » | ✅ **legitime** — c'est le message qui **decrit** un constat, et il vient precisement d'etre **verifie vrai** (`entry_state/check_remote_exit1.txt`) |

⛔ **T17 ne doit toucher QUE le docstring l. 24-25.** Retirer les autres appauvrirait l'outil : la
capacite de nommer un 403 de plan reste necessaire — c'est l'issue qui reviendrait si la visibilite
du depot changeait.

### 3.3 Artefacts **DATES / CERTIFIES** — ⛔ jamais reecrits, seulement references

Ils etaient **exacts a leur date**. Les « corriger » serait une **falsification**.

| Artefact | Occ. passe 1 | Statut |
|---|---|---|
| `docs/stories/US-00.4-ci-protection-branche.md` | **56** | US **certifiee** Prod le 2026-07-27 |
| `reports/US-00.4/**` (qa 20 · enforcement_gap 16 · code_review_2 13 · false_claims_sweep 8 · code_review 8 · security 7 · README 7 · check_remote_exit2 6 · non_regression 3 · deployment 3 · 4 preuves brutes 403) | **93** | **preuves brutes datees** du 2026-07-26 |
| `docs/adr/ADR-006-protection-branche-principale.md` | **14** | ADR **`Accepté`, commite, certifie** -> **immuable**, pas meme sa ligne `Statut` |
| `tests/features/US-00.4-ci-protection-branche.feature` | **12** | scenarios d'une US certifiee |
| `docs/trace/US-00.4/events.jsonl` | **6** | trace **append-only** |
| `reports/US-00.3/code_review.md` | **1** | rapport date |

**Total artefacts dates : 182 occurrences — ZERO a modifier.** `git diff --stat` doit le prouver
(critere 23).

### 3.4 Documents **de cette US** — ils **citent** les affirmations pour les corriger

| Artefact | Occ. | Nature |
|---|---|---|
| `docs/stories/US-00.7-application-protection-branche.md` | **61** | le Story File **decrit** les affirmations a corriger : les citer est son objet |
| `docs/adr/ADR-007-application-protection-branche.md` | **14** | ADR remplacant, en cours de redaction par @Architect — **hors perimetre @Developer** |
| `tests/features/US-00.7-…feature` | **3** | scenarios Gherkin de cette US |
| `docs/trace/US-00.7/events.jsonl` | **1** | trace **append-only** |
| `reports/US-00.7/entry_state/protection_404.json` | **2** | **preuve brute** que je viens de produire : elle **cite** le 403 du 2026-07-26 pour le **distinguer** du 404 du 2026-07-27 |
| `tests/fixtures/US-00.7/protection_403_plan_body.json` | **1** | corps de la preuve certifiee d'US-00.4, isole pour rejeu |

**Aucune de ces 82 occurrences n'est a corriger** : ce sont des **citations**, pas des assertions.

### 3.5 🔴 **DOUZIEME CANDIDAT — trois LEDGERS, absents de l'inventaire des 11**

Le balayage trouve **3 fichiers de gouvernance vivants** que l'inventaire @Architect ne liste pas,
parce qu'ils sont **hors perimetre @Developer** (`STORY_CERTIFICATION_BOARD.md`, `PROJECT_LOG.md`,
`BACKLOG.md` = ledgers @Architect / @PO). **Je les inventorie et je les transmets — je n'y touche
pas.**

| Ledger | Occ. | Nature des occurrences | Recommandation |
|---|---|---|---|
| `STORY_CERTIFICATION_BOARD.md` | **19** | melange : (a) **visas dates** d'US-00.4 (l. 159, 168, 214, 231, 251, 270, 273, 334, 380, 493, 520) — historiques par nature ; (b) l'entree **d'US-00.7 elle-meme** (l. 543-550) qui **decrit** le probleme ; (c) l. 3 = **faux positif** (legende « N/A Non applicable ») | ⚠️ **Arbitrage @Architect / @PO.** Les l. **493** et **520** sont les plus genantes : elles portent « `main` **n'est toujours pas protegee** et **ne peut pas l'etre**  » **au present**, dans un visa **date**. **Recommandation** : ne **pas** reecrire le bloc de visa d'US-00.4 (artefact date), mais **ajouter** au bloc d'US-00.7 une mention datee d'extinction — pour qu'un auditeur qui lit le SCB **de haut en bas** rencontre la mise a jour. |
| `PROJECT_LOG.md` | **7** | journal **date**, append-only par convention | ⛔ **jamais reecrit** — historique. |
| `BACKLOG.md` | **4** | l. 22 : « cible armee — *re-cadree le 2026-07-26* » et le libelle d'US-00.4 | ⚠️ @PO : le **libelle** d'US-00.4 au backlog restera « cible armee », ce qui est **exact a sa date**. Rien a corriger, mais **a ne pas confondre** avec une affirmation courante. |

### 3.6 Faux positifs identifies

| Fichier:ligne | Motif declenche | Pourquoi c'est un faux positif |
|---|---|---|
| `scripts/check_scb_compliance.py:30` | `NON APPLICABLE` | docstring : « validee (✅) ou explicitement **non applicable** (N/A) » — parle des **visas SCB**, aucun rapport avec la protection de branche |
| `STORY_CERTIFICATION_BOARD.md:3` | `NON APPLICABLE` | legende des symboles (`N/A (Non applicable — justifie…)`) |

---

## 4. PASSE 2 — **SUR-AFFIRMATION** : le risque symetrique, et celui de cette US

**Resultat : ZERO sur-affirmation dans le corpus.** Les 66 lignes de resultat se rangent, sans
exception, dans **trois** categories inoffensives :

1. **Interdictions et citations du vocabulaire prohibe** — `ADR-006:275-276`, `ADR-007:314-315`,
   Story File US-00.7 l. 277, 566, 679, 1362, 1475. Ces textes **interdisent** « inviolable », « tout
   est enforced », « impossible a contourner », « chaine de confiance » : les trouver la est le signe
   que la garde **existe**.
2. **Enonces de LIMITE honnetes** — `rien ne garantit qu'un passage ait lieu` (dette #8 du point de
   controle sans declencheur calendaire : `GIT_PROTECTION.md:283`, `ADR-006:300`,
   `US-00.4:616`), `aucune de ces methodes ne garantit l'exhaustivite`
   (`false_claims_sweep.md:154,164,165`, `code_review_2.md:440,497`, `enforcement_gap.md:275`,
   `SCB:378`). Ce sont des **auto-limitations**, l'inverse d'une sur-affirmation.
3. **Affirmations techniques BORNEES** — `check_branch_protection.py:480` (« aucune cle de la reponse
   reelle **ne peut plus** etre ecartee en silence » : vrai, et **verifie** par les 13 rejeux de
   `nb1_fix.md`), `ADR-006:148,260`, `US-00.4:216,931`, `security.md:299` (dont la phrase se
   **conclut** par « mais un futur script qui… » — la borne est dans la phrase meme).

Deux mentions hors sujet : `docs/stories/US-01.1-…md:77` (« le contraste **garantit** la lisibilite »
— accessibilite d'interface) et `US-00.4:1034` (critere de test #24). Aucun motif
`toutes? les règles sont` n'a de correspondance.

> ⚠️ **Cette passe devra etre REJOUEE en T23**, apres les corrections T12 -> T20. C'est **la** que le
> risque de sur-affirmation se materialisera : au moment de reecrire les textes, la tentation sera
> d'ecrire « la factory est enforced ». Ce qui sera prouve se limitera a : **4 contextes requis + PR
> obligatoire + `enforce_admins`, a la date de la mesure, pour les contextes effectivement rapportes
> et pour l'acteur employe** — pas davantage.

```text
--- MOTIF : inviolable
docs/adr/ADR-006-protection-branche-principale.md:275:  « **friction + audit périodique** », pas « inviolable ». Un auditeur qui lirait « enforced » comme
docs/adr/ADR-007-application-protection-branche.md:130:| 14 | Conséquences : « Le niveau de garantie obtenu est “**friction + audit périodique**”, pas “inviolable” » | Devient « **contrainte de plateforme + audit périodique** » — **et toujours pas “inviolable”** : la règle reste **révocable** par un administrateur, **sans détection automatique** | ⏳ **T8** — la **seconde moitié** de l'énoncé reste **vraie et conservée** |
docs/adr/ADR-007-application-protection-branche.md:314:administrateur sans détection automatique** ». ⛔ **Interdits dans tout livrable** : « inviolable » ·
docs/adr/ADR-007-application-protection-branche.md:556:   règle** ». C'est très supérieur à un hook local — ce n'est pas « inviolable ».
docs/stories/US-00.7-application-protection-branche.md:277:  sont enforced », « la chaîne de confiance est désormais inviolable ») reproduirait le défaut d'origine
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
docs/stories/US-00.7-application-protection-branche.md:679:  « inviolable », « tout est enforced », « chaîne de confiance désormais sûre », « impossible à
docs/stories/US-00.7-application-protection-branche.md:1362:| 24 | 🟠 | **AC-5 erreur / AC-6 — pas de sur-affirmation, dérogation éteinte, conditionnalité écrite** | Passe 2 → **aucune** occurrence de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance ». L'extinction de la dérogation est écrite **datée** aux **3** emplacements (`CLAUDE.md`, `GIT_PROTECTION.md`, `EPIC_00` risque #5) **avec renvoi à l'événement d'origine** ; `git diff docs/trace/` **vide** hors ajouts US-00.7 ; la **conditionnalité à la visibilité publique** (retour en privé ⇒ 403 ⇒ dérogation **rouverte**) est écrite ; `/audit-methodo` est **conservé et réorienté** | **Haute** |
docs/stories/US-00.7-application-protection-branche.md:1475:- [ ] **20.** **Aucune sur-affirmation** : aucun livrable ne prétend plus que ce qu'AC-1 → AC-4 prouvent (pas de « tout est enforced », pas d'« inviolable ») (AC-5 erreur)
reports/US-00.4/security.md:299:le gate (point e), et la sortie textuelle est inviolable (points a/b) — mais un futur script qui
reports/US-00.4/security.md:555:| L3 | Test d'attaque | `check_branch_protection.py:639-646` | **LOW** | Le mode fixture renvoie **exit 0** sans marqueur : un consommateur ne testant que `$?` ne distingue pas simulé/réel | **NON BLOQUANT** — inatteignable depuis le gate (`main_from_sync()` `:785-788`) ; sortie textuelle prouvée inviolable |

--- MOTIF : tout est enforced
docs/adr/ADR-007-application-protection-branche.md:315:« tout est enforced » · « chaîne de confiance désormais sûre » · « impossible à contourner ». Ne sont
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
docs/stories/US-00.7-application-protection-branche.md:679:  « inviolable », « tout est enforced », « chaîne de confiance désormais sûre », « impossible à
docs/stories/US-00.7-application-protection-branche.md:1362:| 24 | 🟠 | **AC-5 erreur / AC-6 — pas de sur-affirmation, dérogation éteinte, conditionnalité écrite** | Passe 2 → **aucune** occurrence de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance ». L'extinction de la dérogation est écrite **datée** aux **3** emplacements (`CLAUDE.md`, `GIT_PROTECTION.md`, `EPIC_00` risque #5) **avec renvoi à l'événement d'origine** ; `git diff docs/trace/` **vide** hors ajouts US-00.7 ; la **conditionnalité à la visibilité publique** (retour en privé ⇒ 403 ⇒ dérogation **rouverte**) est écrite ; `/audit-methodo` est **conservé et réorienté** | **Haute** |
docs/stories/US-00.7-application-protection-branche.md:1475:- [ ] **20.** **Aucune sur-affirmation** : aucun livrable ne prétend plus que ce qu'AC-1 → AC-4 prouvent (pas de « tout est enforced », pas d'« inviolable ») (AC-5 erreur)

--- MOTIF : toutes? les règles sont

--- MOTIF : chaîne de confiance
docs/adr/ADR-006-protection-branche-principale.md:229:  dénoncé**. Toute la chaîne de confiance (`Certifié Prod = 🚀 OUI`, audits, gates) reposerait sur la
docs/adr/ADR-007-application-protection-branche.md:315:« tout est enforced » · « chaîne de confiance désormais sûre » · « impossible à contourner ». Ne sont
docs/stories/US-00.7-application-protection-branche.md:277:  sont enforced », « la chaîne de confiance est désormais inviolable ») reproduirait le défaut d'origine
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
docs/stories/US-00.7-application-protection-branche.md:679:  « inviolable », « tout est enforced », « chaîne de confiance désormais sûre », « impossible à
docs/stories/US-00.7-application-protection-branche.md:1362:| 24 | 🟠 | **AC-5 erreur / AC-6 — pas de sur-affirmation, dérogation éteinte, conditionnalité écrite** | Passe 2 → **aucune** occurrence de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance ». L'extinction de la dérogation est écrite **datée** aux **3** emplacements (`CLAUDE.md`, `GIT_PROTECTION.md`, `EPIC_00` risque #5) **avec renvoi à l'événement d'origine** ; `git diff docs/trace/` **vide** hors ajouts US-00.7 ; la **conditionnalité à la visibilité publique** (retour en privé ⇒ 403 ⇒ dérogation **rouverte**) est écrite ; `/audit-methodo` est **conservé et réorienté** | **Haute** |

--- MOTIF : impossible à contourner
docs/adr/ADR-006-protection-branche-principale.md:276:  « impossible à contourner » **surestimerait la garantie** : sur ce dépôt, `enforced` signifie
docs/adr/ADR-007-application-protection-branche.md:315:« tout est enforced » · « chaîne de confiance désormais sûre » · « impossible à contourner ». Ne sont
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
docs/stories/US-00.7-application-protection-branche.md:1362:| 24 | 🟠 | **AC-5 erreur / AC-6 — pas de sur-affirmation, dérogation éteinte, conditionnalité écrite** | Passe 2 → **aucune** occurrence de « inviolable », « tout est enforced », « impossible à contourner », « chaîne de confiance ». L'extinction de la dérogation est écrite **datée** aux **3** emplacements (`CLAUDE.md`, `GIT_PROTECTION.md`, `EPIC_00` risque #5) **avec renvoi à l'événement d'origine** ; `git diff docs/trace/` **vide** hors ajouts US-00.7 ; la **conditionnalité à la visibilité publique** (retour en privé ⇒ 403 ⇒ dérogation **rouverte**) est écrite ; `/audit-methodo` est **conservé et réorienté** | **Haute** |

--- MOTIF : garantit
docs/adr/ADR-006-protection-branche-principale.md:300:   **aucune** dérive n'est détectée, et rien ne garantit qu'un passage ait lieu. Cette limite restera
docs/GIT_PROTECTION.md:283:| 8 | **Point de contrôle sans déclencheur calendaire** (`/audit-methodo` est trimestriel « ou à la demande ») : rien ne garantit qu'un passage ait lieu | La dette la plus susceptible de pourrir silencieusement |
docs/stories/US-00.4-ci-protection-branche.md:616:  dette la **plus susceptible de pourrir silencieusement** : rien ne garantit qu'un passage ait lieu.
docs/stories/US-00.4-ci-protection-branche.md:1034:| 24 | **B-2 — une clé additive NEUTRE ne fait pas trébucher l'outil** | `protection_cles_additives_neutres.json` → **exit 0** ; les champs neutres sont **NOMMÉS** en `[IGNORÉ — NEUTRE]` (jamais silencieux) mais n'altèrent pas l'issue. Garantit que l'outil ne devient pas rouge en permanence à chaque évolution additive de l'API GitHub | **Haute** |
docs/stories/US-00.7-application-protection-branche.md:281:  US-00.4 : ni une liste de fichiers, ni une liste de motifs ne garantit l'exhaustivité. La **méthode et
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
docs/stories/US-00.7-application-protection-branche.md:964:      c'est le gate qui garantit la résolution des 4 libellés) et **nommer sa limite** : il compare la
docs/stories/US-00.7-application-protection-branche.md:1005:      *ni une liste de fichiers ni une liste de motifs ne garantit l'exhaustivité*), l'**inventaire des
docs/stories/US-00.7-application-protection-branche.md:1342:| 4 | 🟢 | **AC-7 erreur — évolution additive NEUTRE non pénalisée** | `--from-protection tests/fixtures/US-00.4/protection_cles_additives_neutres.json --from-branch …/branch_protected_true.json` → **exit 0**, champs neutres **NOMMÉS** `[IGNORÉ — NEUTRE]`. *(Critère #24 d'US-00.4 — garantit que l'outil ne devient pas rouge à chaque évolution de l'API.)* | **Haute** |
docs/stories/US-00.7-application-protection-branche.md:1351:| 13 | 🟢 | **AC-5 limite — méthode de balayage et angles morts** | `corpus_sweep.md` porte les **2 passes** (impossibilité **et** sur-affirmation), les **exclusions déclarées**, l'**inventaire des 11 artefacts vivants** avec leur porteur, la **liste des artefacts datés à ne jamais réécrire**, et l'**aveu de méthode** (*ni liste de fichiers ni liste de motifs ne garantit l'exhaustivité*). ⛔ **Exhaustivité NON revendiquée** | **Haute** |
docs/stories/US-01.1-affichage-hub-grille.md:77:- **Limite** : Sur toute la plage du dégradé, le contraste garantit la lisibilité du nombre (RNF-06) ; aux extrêmes, `p = 0` atteint l'orange de référence et `p = 1` le bleu de référence.
reports/US-00.4/code_review_2.md:440:« *aucune de ces méthodes ne garantit l'exhaustivité, et ce rapport ne la revendique plus […] La
reports/US-00.4/code_review_2.md:497:exactement aussi complet que sa liste de motifs* ») ; ce que le rapport garantit — « tout ce qui a
reports/US-00.4/code_review_2.md:637:| S-6 | `check_branch_protection.py` (docstring `:18-22`) | le docstring garantit « aucune méthode d'écriture » : y ajouter le renvoi au **selftest** quand il existera, pour que la garantie soit **exécutable** et pas seulement déclarée |
reports/US-00.4/enforcement_gap.md:144:| **7** | **Point de contrôle sans déclencheur calendaire** : `/audit-methodo` est trimestriel « ou à la demande », sans échéance opposable. Rien ne garantit qu'un passage ait lieu | R9 | ⚠️ la dette la plus susceptible de **pourrir silencieusement** |
reports/US-00.4/enforcement_gap.md:275:> de fichiers, ni la liste de motifs ne garantit l'exhaustivité.** La seule garantie serait une
reports/US-00.4/false_claims_sweep.md:154:**Ce que ce rapport NE garantit PAS.** La version précédente concluait « 0 occurrence non justifiée
reports/US-00.4/false_claims_sweep.md:164:**Conclusion honnête : aucune de ces méthodes ne garantit l'exhaustivité, et ce rapport ne la
reports/US-00.4/false_claims_sweep.md:165:revendique plus.** Ce qu'il garantit : la **méthode est écrite**, le **périmètre est déclaré**, les
STORY_CERTIFICATION_BOARD.md:378:    Aucune de ces méthodes ne garantit l'exhaustivité ; **la seule garantie serait une relecture

--- MOTIF : ne peut plus
docs/adr/ADR-006-protection-branche-principale.md:148:    CI bloquant. Le mot « protection » ne peut plus y figurer comme un **fait vérifié**.
docs/adr/ADR-006-protection-branche-principale.md:260:- **Zéro fausse confiance produite par la factory** : `--check` ne peut plus être lu comme une
docs/stories/US-00.4-ci-protection-branche.md:216:### AC-2 : Le contrôle de synchronisation ne peut plus être lu comme une attestation de l'état réel
docs/stories/US-00.4-ci-protection-branche.md:931:      repli — une divergence entre les deux vues de l'API ne peut plus passer inaperçue).
docs/stories/US-00.7-application-protection-branche.md:566:| **2 — sur-affirmation** *(risque symétrique, celui de cette US)* | `inviolable` · `tout est enforced` · `toutes? les règles sont` · `chaîne de confiance` · `impossible à contourner` · `garantit` · `ne peut plus` | affirmations **excédant la preuve** |
reports/US-00.7/nb1_fix.md:499:cible amputee, une cle reelle **ACTIVE** ne peut plus etre ecartee en silence. Ce qui reste ouvert :
scripts/check_branch_protection.py:480:    de la réponse réelle ne peut plus être écartée en silence.
```

---

## 5. PASSE 3 (complementaire, ajoutee) — **routage vers ADR-006 comme decision courante**

Motif : **ADR-007 remplacera ADR-006**, et ADR-006 restera **immuable**. Un lecteur qui suivrait un
lien vers ADR-006 depuis un document vivant le croirait **en vigueur**. Le Story File impose cette
mitigation (T24, DoD 33, critere 23) sans en fournir l'inventaire : le voici.

| Artefact vivant | Liens/mentions ADR-006 | Lignes | A relibeller « ADR-006 *(remplace par ADR-007)* » ou rediriger |
|---|---|---|---|
| `docs/SQUAD_GUIDE.md` | **4** | 38, 46, 301, 345 | T19(a) |
| `docs/GIT_PROTECTION.md` | **2** | 20, 267 | T14 |
| `scripts/check_branch_protection.py` | **2** | 4, 25 | T17 *(l. 25 est deja dans son perimetre)* |
| `.claude/commands/audit-methodo.md` | **2** | 17, 59 | T18(a) |
| `docs/epics/EPIC_00-fondations.md` | **1** | 17 | T13 |
| `.github/workflows/ci.yml` | **1** | 14 | T15 |
| `scripts/apply_branch_protection.sh` | **1** | 10 | T16 |
| `.claude/commands/sprint-status.md` | **1** | 14 | T18(b) |
| `tests/fixtures/US-00.4/README.md` | **1** | 4 | T19(b) — **historisation additive seule** |
| **`scripts/githooks/pre-push`** | **1** | 12 | **T20 — HUMAIN, Art. 6** |
| `CLAUDE.md` | **0** | — | rien a faire |

**10 des 11 artefacts vivants routent vers ADR-006** — `CLAUDE.md` est le seul qui ne le cite pas.
Ledgers (hors perimetre @Developer) : `STORY_CERTIFICATION_BOARD.md` **7**, `PROJECT_LOG.md` **3**,
`BACKLOG.md` **1**.

---

## 6. Synthese

| Categorie | Fichiers | Occurrences passe 1 | Action |
|---|---|---|---|
| **Corpus VIVANT** (inventaire @Architect) | **11** | **55** *(50 a traiter, 5 legitimes)* | **T12 -> T20**, apres le `PUT` |
| **Ledgers** (12e candidat, hors perimetre @Developer) | **3** | **30** | **transmis** a @Architect / @PO |
| **Artefacts DATES / CERTIFIES** | **6 (+ sous-fichiers)** | **182** | ⛔ **jamais reecrits** |
| **Documents de cette US** (citations) | **6** | **82** | rien a corriger |
| **Faux positifs** | **2** | **2** | rien a corriger |
| **PASSE 2 — sur-affirmations** | — | **0** | a **rejouer en T23** |
| **PASSE 3 — routage ADR-006** | **10 vivants + 3 ledgers** | **16 + 11** | **T12 -> T20** + **T24** |

**Ce que ce balayage etablit** : le compte de **11 artefacts vivants** de @Architect est **confirme,
ligne par ligne**, et il en manquait un douzieme *candidat* — les **3 ledgers**, hors de mon
perimetre. **Ce qu'il n'etablit pas** : qu'il n'y a rien d'autre. Voir §2 : **10 angles morts
declares**, dont un irreductible (les **paraphrases semantiques**), qui ne se ferme que par
**relecture humaine**.
