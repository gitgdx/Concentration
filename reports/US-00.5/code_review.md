# US-00.5 — Audit de revue (@CodeReviewer, contexte frais)

- **US** : US-00.5 — ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution
- **Branche** : `feat/US-00.5-adr-stack-constitution` · **PR nº 1 = #17** (OPEN, `mergeStateStatus: CLEAN`)
- **Diff audité** : `git diff main...HEAD` — 11 fichiers, 1341 insertions, 9 suppressions
- **Auditeur** : @CodeReviewer — subagent, **contexte frais** (aucun accès à la conversation de production)
- **Modèle** : `claude-opus-5[1m]`
- **Date** : 2026-07-30

---

## 🔴 VERDICT : **FAILED**

| Sévérité | Nombre |
|---|---|
| 🔴 **Bloquant** | **1** *(B-1 — extension de 3 lignes non marquées + 1 sur-affirmation d'exhaustivité)* |
| 🟠 Non bloquant | **9** *(NB-1 → NB-9)* |
| 🟢 Contrôles exécutés sans faute | **19** *(§5)* |

**Le livrable de fond — `ADR-001-choix-de-stack.md` — est SAIN.** J'ai vérifié ses affirmations une par
une contre des fichiers réels et des commandes ; les **4 honnêtetés dures sont écrites sans
adoucissement** et **chacune est vraie**. Le bloquant **ne porte pas sur l'ADR** : il porte sur le
**marquage des transmissions périmées du SCB (C-3 / DoD 20)**, où la correction a **suivi deux renvois
au lieu de couvrir l'extension du défaut** — et où la ligne que le Story File cite **littéralement**
est précisément **celle qui n'a pas été marquée**, tandis que `PROJECT_LOG.md` déclare l'opération
**complète** (« les **DEUX** transmissions périmées »). C'est, au mot près, le motif du 5ᵉ `FAIL`
d'US-00.7.

⚠️ **Nature de l'US prise en compte** : `Code (Dev) = N/A` justifié, **0 fichier `.dart`**, **0 script
modifié** — vérifié (§4.4). Je n'ai donc pas cherché de défaut de code ; j'ai audité la **véracité** et
la **cohérence** de ce qui est affirmé, comme demandé.

---

## 1. Gates statiques — sorties brutes

### 1.1 Gates nommés par ma procédure (`lint`, `typecheck`)

```
$ python scripts/run_gates.py --gate lint
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
rc=1

$ python scripts/run_gates.py --gate typecheck
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
rc=1
```

⚠️ **Ce n'est PAS un échec de l'US.** L'adapter `flutter` nomme ses gates `format`, `analyze`, `test`,
`deps_audit`, `build` — il n'y a **aucun** gate nommé `lint` ni `typecheck`. Les équivalents canoniques
sont `--gate format` et `--gate analyze`. Ce constat est **exploité en NB-2**, car il falsifie le
**critère de test nº 5** de cette US.

### 1.2 Gates réels — non-régression (`--all`)

```
$ python scripts/run_gates.py --all
▶ app.format   — (.) $ dart format --output=none --set-exit-if-changed lib test   ✅
▶ app.analyze  — (.) $ flutter analyze                                            ✅
▶ app.test     — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80  ✅
▶ app.deps_audit — (.) $ dart pub outdated --show-all
  You are already using the newest resolvable versions listed in the 'Resolvable' column.
  ✅ app.deps_audit
▶ app.build    — (.) $ flutter build web --release
  Compiling lib\main.dart for the Web...   140,8s
  √ Built build\web
  ✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
rc=0
```

Couverture recalculée **par moi**, indépendamment du gate : `coverage/lcov.info` → `LF:19` / `LH:17`
→ **89,47 %** ≈ **89,5 %**, seuil 80 %. ✅ **L'affirmation de couverture de l'ADR est exacte.**
⚠️ **Portée** : **0 fichier `.dart` touché** → cette couverture atteste une **non-régression**, **jamais
le livrable**.

### 1.3 Gates de gouvernance

```
$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.                                    rc=0

$ python scripts/validate_trace.py --us US-00.5
Traçabilité conforme.                                                        rc=0

$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (...).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici.
                                                                             rc=0
```

---

## 2. 🔴 FINDING BLOQUANT

### B-1 — Le marquage `PÉRIMÉ-2026-07-28` a suivi **deux renvois**, pas l'**extension** du défaut ; et la ligne nommée **littéralement** par C-3 est **celle qui manque**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `STORY_CERTIFICATION_BOARD.md:368` *(principal)* · `:212` · `:291` — **3 lignes non marquées** · + `PROJECT_LOG.md:110` *(sur-affirmation)* |
| **Problème** | Le Story File exige un marqueur **littéral** `PÉRIMÉ-2026-07-28` **sur la ligne même** de la transmission périmée vers US-00.5 (**C-3**, **R-3**, **AC-5**, **DoD 20**), et il **cite le texte visé mot pour mot** : *« Le SCB porte encore, dans le visa @Architect d'US-00.4, la mention **« transmis à US-00.5, @PO tranchera le véhicule »** : elle est PÉRIMÉE depuis le 2026-07-28 »*. **Cette ligne exacte — `SCB:368` — n'a PAS reçu le marqueur.** Les deux marqueurs posés (`:431`, `:545`) sont sur **d'autres** lignes. Deux autres transmissions périmées de la même section sont également nues (`:212`, `:291`). Et `PROJECT_LOG.md:110` **déclare l'opération complète** : « *marqueur PERIME-2026-07-28 pose SUR LA LIGNE MEME des **DEUX** transmissions perimees du SCB vers US-00.5* » — **il y en a cinq, dont trois nues.** |
| **Solution** | Poser le marqueur **littéral** `PÉRIMÉ-2026-07-28` **sur la ligne même** de `SCB:212`, `SCB:291` et `SCB:368` — ⛔ **sans réécrire ni supprimer** le visa daté d'US-00.4 (c'est exactement ce que C-3 prescrit). Puis **corriger la sur-affirmation** de `PROJECT_LOG.md:110` : remplacer « les **DEUX** transmissions périmées » par le décompte réel, ou retirer le quantificateur. **Critère de sortie rejouable** à publier : `grep -n "US-00\.5" STORY_CERTIFICATION_BOARD.md` puis, pour chaque ligne qui **assigne une charge** à US-00.5 et dont la charge est éteinte, exiger `PÉRIMÉ-2026-07-28` sur la même ligne. |

**Commandes qui l'établissent** :

```
$ grep -n "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md
431:    — même famille que **S11** (US **certifiée**) → **PÉRIMÉ-2026-07-28 : à joindre à la transmission US-0…
545:    (`trace_append.py` ne lit jamais `emitter`) · **PÉRIMÉ-2026-07-28 — « US-00.5 : `CLAUDE.md:20`,
-> 2 marqueurs
```

**Extension du défaut — les 5 transmissions vers US-00.5 du SCB, toutes dans la MÊME section**
(`### [US-00.4] Enforcement de la branche principale : constat, vérification honnête et cible armée`,
soit **le visa @Architect d'US-00.4** que le Story File nomme) :

| Ligne | Texte (extrait) | Charge éteinte depuis | Marqueur |
|---|---|---|---|
| **212-213** | « la déclaration *enforced par protection de branche* **reste FAUSSE après cette US**. Son amendement devient **OBLIGATOIRE** et relève de **US-00.5**, aux deux emplacements exacts `CLAUDE.md:20` (règle 2) et `CONSTITUTION.md:49` » | 2026-07-28 — **S1/S2 sont devenus VRAIS**, les corriger vaudrait **régression documentaire** *(le Story File le dit lui-même, §3)* | ⛔ **ABSENT** |
| **291** | « **S1** (`CLAUDE.md:20`) et **S2** (`CONSTITUTION.md:49`) sont **délibérément maintenues** → textes normatifs, **PR dédiée en US-00.5** » | idem | ⛔ **ABSENT** |
| **368** | « **S11** `US-00.1:198,215` → **non édité** … → **transmis à US-00.5, @PO tranchera le véhicule** » | 2026-07-28 — **S11 versé à US-00.8** *(arbitrage @PO)* | ⛔ **ABSENT** ← **ligne citée MOT POUR MOT par C-3 et par §6 du Story File** |
| 431 | NB-9 `…US-00.1-secrets-scan-depot.feature:54` « à joindre à la transmission US-00.5 » | idem | ✅ présent |
| 545 | « US-00.5 : `CLAUDE.md:20`, `CONSTITUTION.md:49`, et `US-00.1` (S11) » | idem | ✅ présent |

**Vérification que les 5 lignes sont bien dans la même section** *(donc qu'aucune ne relève d'un régime
différent qui dispenserait du marqueur)* :

```
$ python - (recherche du dernier en-tête '### ' avant chaque ligne)
212 -> (156, '### [US-00.4] Enforcement de la branche principale : constat, vérification honnête et cible armée')
291 -> (156, idem)
368 -> (156, idem)
431 -> (156, idem)
545 -> (156, idem)
```

**Vérification que ces 3 lignes n'ont pas été effleurées par cette US** *(ce n'est pas un oubli d'écriture,
c'est une absence de couverture)* : le diff du SCB ne porte que **3 hunks** — l'insertion de la ligne
US-00.5 (`@@ -14,6 +14,7 @@`), la ligne 431 (`@@ -427,7 +428,7 @@`) et le bloc 542-645
(`@@ -541,12 +542,105 @@`). Les lignes **212**, **291** et **368** sont **intactes**.

**Pourquoi c'est bloquant, et pas une pinaillerie de forme** — trois raisons cumulatives :

1. **Une exigence explicite de l'US n'est pas tenue à l'endroit que l'US nomme elle-même.** C-3, R-3 et
   la DoD 20 ne demandent pas « des marqueurs » : ils désignent **une mention par son texte littéral**,
   précisément pour échapper au piège du renvoi. La mention désignée est la seule à ne rien porter.
2. **Un ledger vivant déclare complète une opération qui ne l'est pas** (`PROJECT_LOG.md:110`, « les
   **DEUX** »). C'est une **sur-affirmation**, falsifiable par `grep` en une commande — la classe de
   défaut que ce projet sanctionne, et qui a produit le **5ᵉ `FAIL`** d'US-00.7 (« *déclarer corrigé ce
   qui n'a pas été effleuré* »).
3. **C'est le motif de fond des cinq échecs d'US-00.7, répété** : *« la correction a suivi le RENVOI, pas
   le DÉFAUT — un renvoi cite un exemple, le défaut a une EXTENSION »*. Le défaut ici est « *le visa
   @Architect d'US-00.4 transmet encore à US-00.5 des charges éteintes* » ; son **extension** est de
   **5 lignes**, la couverture obtenue de **2**.

⚖️ **Ce que je ne reproche PAS**, pour que la correction ne dérape pas : ⛔ **ne réécrivez pas** et **ne
supprimez pas** ces trois lignes. Ce sont des **visas datés, exacts à leur date**. Le marqueur sur la
ligne — **sans** réécriture — est exactement le remède prescrit par C-3, et c'est la doctrine que
l'US-00.7 a payée cinq fois. Deux des cinq lignes ont d'ailleurs déjà été traitées **de la bonne
manière** : il n'y a **rien à inventer**, seulement à **étendre**.

---

## 3. 🟠 FINDINGS NON BLOQUANTS

### NB-1 — Le faux vert auto-dénoncé est bien conservé, sa correction est **juste**, mais son **diagnostic est FAUX** — et propagé dans **3** artefacts vivants

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `reports/US-00.5/conformite_ac.txt:42-43` · `PROJECT_LOG.md:110` · `STORY_CERTIFICATION_BOARD.md:633` |
| **Problème** | Le texte écrit : « *`git diff origin/main...HEAD` ne compare que le **DERNIER COMMIT*** ». **C'est faux.** La forme à **trois points** compare `merge-base(origin/main, HEAD)` à `HEAD`, donc **TOUS** les commits de la branche. **Preuve sur cette branche même** (2 commits, `c6ef9c6` puis `4f5b837`) : `git diff --stat main...HEAD` rend **11 fichiers** couvrant les **deux** commits — le Story File (venu de `c6ef9c6`) **et** `ADR-001` (venu de `4f5b837`). La cause réelle du faux vert est autre, et plus intéressante : un diff **commit-à-commit** ne peut pas voir un fichier **pas encore commité**, et `ADR-001` ne l'était pas. |
| **Solution** | Remplacer, dans les **3** emplacements, « *ne compare que le dernier commit* » par « *compare des **COMMITS**, or le livrable n'était pas encore commité* ». La **leçon** que le texte tire (« *le contrôle doit porter sur l'objet réel de la livraison* ») est **juste** — c'est son **motif** qui est faux. |

✅ **Sur les deux questions posées** : (i) la **correction est juste** — je l'ai **re-vérifiée moi-même
sur l'état commité et sur la PR réelle**, pas sur l'index (§4.4) ; (ii) le **contrôle fautif n'a PAS été
effacé** — il figure aux lignes 26-36 de `conformite_ac.txt`, la correction étant **ajoutée à sa suite**
(l. 41-65) et non **substituée**. C'est la bonne pratique, et elle est tenue.

### NB-2 — Le **critère de test nº 5** de cette US est **falsifié par son propre outil** sur **3** noms, pas 1 — et il le restera **après** la PR nº 2

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/stories/US-00.5-adr-stack-constitution.md` — §*Critères de test*, ligne du critère **nº 5** ; et **AC-3** §*Nominal — contrôle de sortie, borné et rejouable* |
| **Problème** | Le critère publié est : « **Pour chaque gate nommé par l'Art. 4** : `python scripts/run_gates.py --gate <nom>` → **existe** — ⛔ aucun gate cité qui n'existe pas ». Or l'Art. 4 nomme **lint, typecheck, SAST, audit de dépendances, tests** et **les quatre** premiers noms rendent la **même** erreur. Le critère encode une lecture **par NOM**, alors que l'US défend — à raison, cf. §6 — une lecture **par CATÉGORIE**, et **conserve délibérément** `lint` et `typecheck` dans l'article. Après la PR nº 2, l'exécution **littérale** de ce critère rendra donc **encore 2 échecs** (`lint`, `typecheck`), voire 3 si `tests` n'est pas renommé `test`. Deux issues, toutes deux mauvaises : rapporter « vert » = **faux vert** ; rapporter « rouge » = **FAIL mal motivé**. |
| **Solution** | Reformuler le contrôle dans les termes que l'US défend, et le **publier comme script exécutable** *(leçon d'US-00.7)* : « pour chaque catégorie nommée par l'Art. 4, il existe **au moins un gate** de `factory.config.json` qui la **réalise**, et il est **bloquant** » — la catégorie sans gate réalisant (`SAST`) et la catégorie réalisée mais non bloquante (`audit de dépendances`) étant les deux seuls échecs attendus. ⚠️ **Porte sur AC-3 / PR nº 2**, pas sur ADR-001. |

**Sortie brute** :

```
$ for g in lint typecheck tests sast; do python scripts/run_gates.py --gate $g; echo "rc=$?"; done
[ERREUR] aucun gate ne correspond (...).   rc=1     # lint
[ERREUR] aucun gate ne correspond (...).   rc=1     # typecheck
[ERREUR] aucun gate ne correspond (...).   rc=1     # tests
[ERREUR] aucun gate ne correspond (...).   rc=1     # sast
```

### NB-3 — `ADR-001:25-26` et `:95` — « le kit ne fournissait qu'un adapter `fastapi-react` » est affirmé **deux fois sans renvoi**, alors que la corroboration existe **dans le dépôt**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:25-26` et `:95` |
| **Problème** | AC-1 *Erreur* : « toute affirmation qui **ne peut pas** être établie par lecture d'un fichier du dépôt est **retirée**, ou **explicitement marquée comme non vérifiée** — jamais affirmée ». `grep -rn "fastapi-react"` ne rend **que** les artefacts de cette US elle-même (`ADR-001`, `PROJECT_LOG:110`, `SCB:616`) : **aucune source**. L'affirmation est pourtant portée **deux fois** comme un fait plat, et elle est **structurante** (c'est la 4ᵉ alternative écartée). |
| **Solution** | Ajouter le renvoi — la corroboration est **en dur dans le dépôt** : `scripts/factory_sync.py:128-139` code un composant **`backend`** avec `pytest.ini` / `--cov-fail-under`, `:142-146` un composant **`frontend`** avec `vitest.config.ts`, et `scripts/run_gates.py:8` prend **`--component backend`** comme exemple d'usage. Ce sont des **résidus non ambigus** d'un adapter FastAPI + React dans les scripts génériques du kit. À défaut, marquer l'affirmation « *non vérifiable depuis ce dépôt* ». |

### NB-4 — `ADR-001:72-74` — `coverage_ratchet` n'est pas seulement **non configuré**, il est **non implémenté pour cet adapter** ; l'ADR n'en dit que la moitié, et c'est la moitié qui **sous-estime** la charge d'US-00.6

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:72-74` |
| **Problème** | L'ADR écrit : « la clé existe au **schéma** de configuration mais est **absente** de `factory.config.json` — son activation appartient à **US-00.6** ». **Vrai, et vérifié** (`scripts/factory.config.schema.json:82` la déclare · absente de la config). **Mais incomplet** : `scripts/factory_sync.py:142-143` ne lit `coverage_ratchet` que sur un composant **`frontend`** (`components.get("frontend", {})`), lequel **n'existe pas** dans l'adapter `flutter` (composant unique `app`). **Ajouter la clé sous `app` serait donc purement et simplement ignoré.** Le lecteur — et US-00.6 — en déduit à tort qu'une ligne de configuration suffirait. |
| **Solution** | Une phrase : « *son activation exige du **code** dans `factory_sync.py` (la clé n'est lue que pour un composant `frontend`, absent de cet adapter), pas seulement une clé de configuration* ». ⚠️ **La même précision est due dans l'amendement de la PR nº 2**, qui prévoit de désigner la clé « à activer par US-00.6 ». |

### NB-5 — `ADR-001:63-69` — la colonne *Commande* abrège **deux** commandes en leur retirant leur sémantique

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:65` *(`app.format`)* et `:68` *(`app.deps_audit`)* |
| **Problème** | L'ADR écrit `dart format` là où le gate réel est `dart format --output=none --set-exit-if-changed lib test`, et `dart pub outdated` là où il est `dart pub outdated --show-all`. Pour `format`, l'abrégé **inverse l'effet** : `dart format` **réécrit** les fichiers, `--output=none --set-exit-if-changed` **vérifie sans écrire** — ce n'est pas un détail pour un document censé décrire un **gate**. La portée (`lib test`) disparaît aussi. |
| **Solution** | Citer les commandes **verbatim**, ou a minima `dart format --set-exit-if-changed …`. **Atténuation réelle** : l'ADR écrit explicitement que « *la config fait foi* » et que les valeurs sont **datées** (`:81-84`) — ce n'est donc **pas** une fausseté, c'est une abréviation qui trompe. |

### NB-6 — `ADR-001:159` — l'énumération de ce que couvre `protect_files.sh` omet **3** des **9** motifs

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:159` |
| **Problème** | L'ADR écrit que le hook « couvre les hooks git, `.gitleaks.toml`, `factory.config.json`, `factory_sync.py`, `run_gates.py`, **mais pas `docs/governance/**`** ». Le motif réel (`.claude/hooks/protect_files.sh:28`) est : `scripts/githooks/*` · `.claude/settings.json` · `.claude/hooks/*` · `.gitleaks.toml` · `scripts/install_hooks.sh` · `factory.config.json` · `scripts/factory_env.sh` · `scripts/factory_sync.py` · `scripts/run_gates.py`. **`.claude/settings.json`, `scripts/install_hooks.sh` et `scripts/factory_env.sh` manquent.** ✅ **L'affirmation porteuse est VRAIE et vérifiée** : `docs/governance/**` n'est **pas** couvert. |
| **Solution** | Ajouter « **notamment** », ou compléter la liste. Dans un projet aussi sévère sur les revendications d'exhaustivité, une énumération nue amputée de 3 entrées sur 9 est une prise inutile. |

### NB-7 — `.metadata` déclare toujours une plateforme `ios` que `git ls-files` ne trouve pas — hors périmètre, mais à nommer

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `.metadata` — `migration.platforms[]: ios` et `unmanaged_files: ios/Runner.xcodeproj/project.pbxproj` |
| **Problème** | `git ls-files ios` → **0 fichier**. L'ADR a donc **raison** : iOS n'est **pas** scaffoldé. Mais un fichier **versionné** déclare le contraire, et un lecteur qui `grep`-erait `ios` sur les fichiers suivis pourrait conclure l'inverse. **À décharge, cela CORROBORE le récit de l'ADR** (iOS créé puis retiré, `PathNotFoundException`). |
| **Solution** | ⛔ **Ne pas corriger ici** : `.metadata` porte « *should not be manually edited* », et l'US n'y touche pas. **Destinataire** : l'US qui scaffoldera iOS, ou `/audit-methodo`. |

### NB-8 — `ADR-001` ne porte **nulle part** le motif que le PRD donne **réellement** au choix de Flutter

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:51-52` *(Décision 1)* et §*Alternatives considérées* |
| **Problème** | AC-1 *Nominal* précise entre parenthèses : « *le PRD RNF-08 motive Flutter par le **rendu visuel** et les besoins d'**animation/audio** des modules futurs* ». Or `grep -niE "rendu\|animation\|audio\|typographi\|dégradé" docs/adr/ADR-001-*.md` → **rc=1, aucune occurrence**. Le PRD (`docs/product/PRD-application-concentration.md:146`) écrit pourtant : « *choix motivé par la qualité du rendu visuel (dégradés, typographie, animations) et par les besoins des modules futurs (animations fluides et audio pour Respiration)* ». L'ADR ne motive Flutter que par « *cross-platform depuis une base de code unique … sans doubler l'effort* ». **Le registre répond donc à « pourquoi Flutter ? » plus faiblement que le PRD qu'il cite** — or combler exactement ce trou est la raison d'être déclarée de cette US. |
| **Solution** | Une ligne en §*Décision 1* ou en tête des *Alternatives* reprenant le motif RNF-08 avec son renvoi. **Non bloquant** : l'obligation littérale de l'AC (« nomment **au moins** les options écartées et **pourquoi** ») est **tenue** — 6 alternatives, chacune avec sa raison. |

### NB-9 — ADR-001 nomme les **faits** de l'écart, jamais la **contradiction avec la Constitution** ni son destinataire (PR nº 2)

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `docs/adr/ADR-001-choix-de-stack.md:150-160` *(§Écarts constatés hors du périmètre)* |
| **Problème** | Le tableau des écarts route « *Aucun SAST pour le code Dart* » → **US-00.8** et « *`coverage_ratchet` absent* » → **US-00.6**. Il ne dit **nulle part** que **l'Art. 4 de la Constitution affirme aujourd'hui le contraire** (SAST **bloquant**, audit de dépendances **bloquant**, `coverage_ratchet` **en vigueur**) ni que son amendement part en **PR nº 2 de cette même US**. Un auditeur qui n'ouvrirait que `docs/adr/` — le lecteur que cet ADR existe pour servir — voit la contradiction sans la voir nommée. |
| **Solution** | Une ligne au tableau : « *le corps de l'Art. 4 affirme aujourd'hui le contraire → amendement en **PR nº 2 d'US-00.5*** ». **Non bloquant** : AC-5 admet explicitement « *ADR-001 §Conséquences, **ou rapport de l'US*** », et le **rapport** le fait de façon exemplaire (`reports/US-00.5/entry_state/art4_vs_gates_reels.txt` §4). L'AC est donc **satisfait** ; c'est l'**autosuffisance de l'ADR** qui y perd. |

---

## 4. Contrôles à charge demandés — résultats

### 4.1 ADR-001 dit-il VRAI ? — chaque affirmation confrontée à un fichier ou une commande

| Affirmation de l'ADR | Contrôle exécuté | Verdict |
|---|---|---|
| Factory instanciée le **2026-07-24** | `factory.config.json` → `kit.initialized_at = 2026-07-24T09:59:00+02:00` | ✅ **VRAI** |
| Le kit ne fournissait qu'un adapter **`fastapi-react`** | `grep -rn "fastapi-react"` → **aucune source** hors artefacts de cette US | 🟠 **NON SOURCÉ** → **NB-3** *(corroborable in-repo, non cité)* |
| **5 US certifiées Prod** (00.1→00.4 + 00.7) | SCB, colonne `Certifié Prod` → `🚀 OUI` ×5, exactement ces cinq | ✅ **VRAI** |
| **Flutter channel `stable`** | `.metadata` → `channel: "stable"` | ✅ **VRAI** |
| **SDK Dart `^3.12.2`** | `pubspec.yaml` → `environment: sdk: ^3.12.2` | ✅ **VRAI** |
| **null-safety strict** | Aucun `strict-casts`/`strict-inference`/`strict-raw-types` dans `analysis_options.yaml` ; la base réelle est la **sound null safety obligatoire de Dart 3** + `STACK_PROFILE.md:8` | ⚠️ **VRAI par renvoi**, non par drapeau d'analyseur — voir §6 *bornes* |
| **Un seul composant `app`, à la racine** | `factory.config.json` → `components: {app: {path: "."}}`, **un seul** | ✅ **VRAI** |
| **Pas de séparation back/front** (offline-first) | `PRD:145` RNF-07 « aucune donnée ne quitte l'appareil » · `PRD:139` RNF-01 offline-first | ✅ **VRAI** |
| **5 gates** et leur `blocking` | `factory.config.json` → `format`, `analyze`, `test`, `deps_audit` **(`blocking: false`)**, `build` ; défaut bloquant confirmé dans `run_gates.py:59,67` (`gate.get("blocking", True)`) | ✅ **VRAI** *(commandes abrégées → NB-5)* |
| **`coverage_min = 80`** | `factory.config.json` → `coverage_min: 80` | ✅ **VRAI** |
| **`coverage_ratchet` absent de la config, présent au schéma** | absent de `factory.config.json` · `scripts/factory.config.schema.json:82` | ✅ **VRAI** *(mais incomplet → NB-4)* |
| **Android + Web matérialisés, iOS non** | `ls` racine → `android/`, `web/`, **pas de `ios/`** · `git ls-files ios` → **0** | ✅ **VRAI** |
| **Runners CI `ubuntu-latest`** | `grep -rn "runs-on" .github/workflows/` → 5/5 `ubuntu-latest` | ✅ **VRAI** |
| **Couverture 89,5 % pour un seuil de 80** | `coverage/lcov.info` → `LF:19`, `LH:17` = **89,47 %** | ✅ **VRAI** |
| **`actionlint` épinglé par SHA256 dans le job requis « 📋 Governance »** | `ci.yml:68` `name: 📋 Governance…` · `:90-99` step actionlint avec `sha256sum -c -` · `status_checks[1]` = ce job | ✅ **VRAI** |
| **Rôles référencent `STACK_PROFILE.md`, aucune commande en propre** | `grep -rl "STACK_PROFILE" .claude/agents/` → **6** subagents | ✅ **VRAI** |
| **`CONSTITUTION.md` non protégé par `protect_files.sh`** | `.claude/hooks/protect_files.sh:28` → `docs/governance/**` **absent** du motif | ✅ **VRAI** *(énumération incomplète → NB-6)* |
| **`scripts/check_flutter_coverage.py` existe** | `ls -la` → présent, 1770 o | ✅ **VRAI** |
| **PRD cible iOS + Android, RF-21 extensibilité** | `PRD:146` RNF-08 « mobile **iOS et Android** » · `PRD:131` RF-21 | ✅ **VRAI** |

**Bilan §4.1** : **19 affirmations contrôlées, 18 établies, 1 non sourcée (NB-3), 1 vraie par renvoi
seulement (null-safety strict).** ⛔ **Aucune fausseté.**

### 4.2 Les 4 honnêtetés dures sont-elles réellement écrites, et non adoucies ?

| Honnêteté | Écrite ? | Établie par |
|---|---|---|
| **iOS non scaffoldé**, alors que le **PRD cible iOS** | ✅ `ADR-001:121-127`, titre en gras, 🔴, « *laisse **la moitié de la cible du PRD non matérialisée*** » | `git ls-files ios` → **0** · pas de `ios/` à la racine · `PRD:146` cible **iOS et Android** |
| **Build Android non validé** | ✅ `:129-134` — « *le gate `build` **vert** signifie « le code compile pour le web », **pas** « l'application est constructible pour sa cible »* » | `factory.config.json` → `build.cmd = flutter build web --release` · JDK absent : `STACK_PROFILE.md:73-76` |
| **`deps_audit` = obsolescence, PAS vulnérabilité, non bloquant** | ✅ `:136-141` — « ***aucun scan de CVE n'existe dans cette factory***, donc **aucun verdict de sécurité ne peut s'adosser à un audit de dépendances** » | `factory.config.json` → `"blocking": false` · `cmd = dart pub outdated --show-all` |
| **Aucun SAST** | ✅ `:143-148` — « ***AUCUN SAST n'existe pour le code applicatif***… `actionlint` couvre les **workflows**, **rien** ne couvre le **code Dart** » | **exécuté par moi** : `run_gates.py --gate sast` → `[ERREUR] aucun gate ne correspond`, rc=1 |

✅ **Aucune des quatre n'est édulcorée.** Elles sont en **gras**, en tête de la rubrique *Négatives*, sous
le titre « *les quatre honnêtetés dures* », précédées de « ***Un ADR qui les tairait serait faux*** », et
chacune porte sa **conséquence pratique** + son **renvoi**. La formule la plus exposée — « *un gate
`build` vert signifie « compile pour le web », pas « constructible pour sa cible »* » — est celle qui
**dessert** le plus l'auteur : c'est le signe qu'elle n'est pas cosmétique. **iOS est réellement absent
et le PRD cible réellement iOS** : les deux moitiés du grief sont vraies.

### 4.3 Immuabilité des ADR

```
$ git diff --stat main...HEAD -- docs/adr/ADR-005* docs/adr/ADR-006* docs/adr/ADR-007* docs/adr/ADR_TEMPLATE.md
(sortie VIDE)   rc=0
```
✅ **Aucun ADR accepté n'est édité**, template inclus. Le seul fichier d'ADR au diff est la **création**
de `ADR-001-choix-de-stack.md` (177 lignes ajoutées, 0 supprimée).
✅ `grep -rn "~~" docs/adr/ADR-001-*.md` → **rc=1**, aucun texte barré *(critère nº 15)*.
✅ Rubriques du template : **Date** · **Statut** *(= `Accepté`)* · **US associée** *(= US-00.5)* ·
**Contexte** · **Décision** · **Alternatives considérées** · **Conséquences** → **7/7 présentes**.

### 4.4 Critère de sortie AC-4 — **vérifié sur la PR réelle**, pas sur l'index

```
$ gh pr view 17 --json ...
PR 17 OPEN feat/US-00.5-adr-stack-constitution -> main   mergeState CLEAN   reviewDecision ''
  BACKLOG.md · PROJECT_LOG.md · STORY_CERTIFICATION_BOARD.md
  docs/adr/ADR-001-choix-de-stack.md
  docs/epics/EPIC_00-fondations.md
  docs/stories/US-00.5-adr-stack-constitution.md
  docs/trace/US-00.5/events.jsonl
  reports/US-00.5/conformite_ac.txt
  reports/US-00.5/entry_state/art4_vs_gates_reels.txt
  reports/US-00.5/entry_state/registre_et_sast.txt
  tests/features/US-00.5-adr-stack-constitution.feature
-> 11 fichiers

$ git diff --name-only main...HEAD | grep -c "CONSTITUTION"        -> 0   ✅
$ git diff --name-only main...HEAD | grep -c "factory.config.json" -> 0   ✅
$ git diff --name-only main...HEAD | grep -c "\.dart$"             -> 0   ✅
```

✅ **AC-4 / critère nº 9 TENU**, et **sur l'objet réel de la livraison** : `CONSTITUTION.md` **absent**,
`factory.config.json` **absent** *(fichier protégé — respecté)*, **0 fichier `.dart`**. `Code (Dev) =
N/A` est donc **factuellement justifié**. La clause *Révision* (« PR dédiée ») est **respectée à la
lettre** pour la PR nº 1.

### 4.5 Les 3 faussetés de l'Art. 4 — vérifiées **une par une, par moi**

Texte de l'Art. 4 (`docs/governance/CONSTITUTION.md:42-49`, cité littéralement) : « *Les seuils de
couverture et les gates bloquants (lint, typecheck, **SAST**, **audit de dépendances**, tests) sont
définis en un seul endroit : `factory.config.json` → `adapter.components.*.gates` et `coverage_min` /
**`coverage_ratchet`*** ». Bloc *Enforcement* : « *CI `ci.yml` jobs qualité, requis par la protection de
branche… ; job `governance`* ».

| Fausseté alléguée | Mon contrôle | Verdict |
|---|---|---|
| **SAST** annoncé bloquant, **inexistant** | `python scripts/run_gates.py --gate sast` → `[ERREUR] aucun gate ne correspond`, **rc=1**. Et aucun équivalent sous un autre nom parmi les 5 gates. | ✅ **FAUSSETÉ CONFIRMÉE** |
| **Audit de dépendances** annoncé **bloquant** | `factory.config.json` → `deps_audit: {"blocking": false}`. Sémantique confirmée dans `run_gates.py:15` (« *un gate peut porter `"blocking": false` — tout le reste est bloquant* ») et `:67-72`. | ✅ **FAUSSETÉ CONFIRMÉE** |
| **`coverage_ratchet`** cité comme seuil, **absent** | Absent de `factory.config.json` ; présent au **schéma** (`factory.config.schema.json:82`). **Aggravant que l'US ne relève pas** : lu **uniquement** pour un composant `frontend` inexistant (`factory_sync.py:142-143`) → **NB-4**. | ✅ **FAUSSETÉ CONFIRMÉE**, et **plus profonde qu'annoncé** |
| *(omission)* `app.build` non couvert | Gate **réel** et **bloquant** (pas de clé `blocking`), aucune catégorie de l'Art. 4 ne le couvre. | ✅ **OMISSION CONFIRMÉE** |
| *(incomplétude)* Enforcement ne nomme que `ci.yml` | `factory.config.json → status_checks` = **4** contextes : `🔐 Secrets scan`, `📋 Governance`, `📱 App` *(ci.yml)* + **`check-branch-name`** *(**branch-naming.yml**)*. | ✅ **INCOMPLÉTUDE CONFIRMÉE** |

**Les 3 faussetés + l'omission + l'incomplétude sont RÉELLES, toutes les cinq.** Le diagnostic de l'US
est exact, et il est établi **par exécution** comme elle le prétend.

### 4.6 🔍 **La distinction « `lint` et `typecheck` ne sont PAS faux » tient-elle, ou est-ce une commodité ?**

**Elle TIENT. Ce n'est pas une commodité.** Trois raisons, dont deux sont des faits du dépôt :

1. **La lecture « par catégorie » n'est pas un choix de circonstance, c'est la seule lecture possible du
   texte.** L'Art. 4 est un texte **agnostique de la stack** d'un kit **multi-adapters**, et le dépôt en
   porte la preuve matérielle : `scripts/factory_sync.py:128-139` code en dur un composant **`backend`**
   avec `pytest.ini`/`--cov-fail-under`, `:142-146` un composant **`frontend`** avec `vitest.config.ts`,
   et `scripts/run_gates.py:8` documente `--component backend`. Sous **aucun** adapter ces catégories ne
   seraient des **clés de gate** : elles nomment des **fonctions**.
2. **Le test qui sépare les cas est objectif, et il est appliqué uniformément aux cinq items** — « existe-t-il
   un gate **bloquant** qui **réalise** la fonction ? » : `lint` → `app.analyze` + `app.format`
   (bloquants) ✅ · `typecheck` → `app.analyze`, l'analyseur Dart **étant** le vérificateur de types, ce
   que `STACK_PROFILE.md:14-15` écrit noir sur blanc (« *Dart n'a pas d'étape « typecheck » séparée,
   l'analyse couvre les deux* ») ✅ · `tests` → `app.test` ✅ · **`SAST` → aucun gate, sous aucun nom** ❌ ·
   **`audit de dépendances` → gate réel mais `blocking: false`** ❌. Le critère ne fléchit pas selon
   l'item : il **exonère 3 fois et condamne 2 fois**, plus `coverage_ratchet` sur un autre motif.
3. **La lecture retenue est celle qui DESSERT l'auteur.** La lecture « par nom » aurait produit « *l'Art. 4
   est faux **4 fois sur 5*** » — un constat plus spectaculaire, donc plus flatteur pour l'US. Elle est
   **explicitement refusée**, avec son motif écrit (`entry_state/art4_vs_gates_reels.txt` §4 : « *corriger
   ce qui est exact vaudrait régression documentaire — c'est la leçon S1/S2 d'US-00.7, appliquée ici
   **contre ma propre tentation d'élargir*** »). Un raisonnement de commodité ne renonce pas au plus gros
   butin.

⚠️ **Ce qui, en revanche, ne tient pas** : l'**encodage** de cette distinction dans la grille de test.
Le critère nº 5 est rédigé **en lecture par nom** et se falsifie donc lui-même sur 3 items → **NB-2**.
La distinction est juste ; son **contrôle publié** est faux. C'est une faute de **forme**, sur un point
où ce projet a déjà payé cinq fois.

### 4.7 Cohérence du corpus — l'US prétend-elle avoir fait ce qui est reporté en PR nº 2 ?

**NON — et sur les deux points nommément visés, elle est exemplaire.**

- **Critère de clôture d'EPIC_00** (`docs/epics/EPIC_00-fondations.md:111`) : la case reste **`- [ ]`
  DÉCOCHÉE**, et le texte dit explicitement : « ⏳ **La seconde moitié reste due** : l'amendement de
  l'Art. 4 part en **PR nº 2 DÉDIÉE**… **Ce critère ne sera cochable qu'après la fusion de cette seconde
  PR.** » ✅ **Aucune sur-affirmation.** *(La DoD 23, qui exige la case cochée, est donc **honnêtement non
  levée** — cohérent avec la répartition « fin de cycle ».)*
- **`BACKLOG.md:23`** : la note datée du 2026-07-30 énonce les **2** livrables et présente le second comme
  **du périmètre**, jamais comme fait ; la **conditionnalité** exigée par C-6 est présente (« *un retour en
  privé ramènerait le **403**… et **rouvrirait** la correction* »). ✅ **DoD 22 tenue.**
- **`docs/epics/EPIC_00-fondations.md:108`** et `:84` : marqueurs **`PÉRIMÉ-2026-07-30`** posés **sur la
  ligne même**, l'énoncé antérieur **conservé** et non réécrit. ✅
- **SCB, section US-00.5** : décrit la PR nº 1 comme livrée et la PR nº 2 comme « **Prochaine étape** ». ✅

⛔ **La seule sur-affirmation trouvée dans tout le corpus est celle de B-1** (`PROJECT_LOG.md:110`, « les
**DEUX** transmissions périmées »), et elle porte précisément sur le **marquage**.

### 4.8 Marqueurs périmés — voir **B-1**

`grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md` → **2**, et `grep -rn "~~"` ne rend **aucune**
occurrence dans les artefacts de cette US : ✅ **le marquage effectué l'est de la bonne façon** — texte
**littéral**, **sur la ligne même**, **jamais** `~~texte~~`, **jamais** de renvoi par numéro de ligne.
⛔ **Mais il est INCOMPLET : 2 lignes sur 5**, et la manquante est celle que C-3 **cite mot pour mot**.
→ **B-1**.

### 4.9 Le faux vert auto-dénoncé — voir **NB-1**

✅ Le contrôle **fautif** est **conservé** (`conformite_ac.txt:26-36`), la correction **ajoutée à sa
suite** (l. 41-65) et non substituée. ✅ La **conclusion** de la correction est **juste** — je l'ai
re-établie moi-même sur l'état **commité** et sur la **PR réelle** (§4.4). ⛔ Son **diagnostic** est
**faux** et propagé dans **3** artefacts vivants → **NB-1**.

---

## 5. Contrôles exécutés **sans faute** — à décharge

1. `run_gates.py --all` → **exit 0**, 5 gates. 2. `check_scb_compliance.py` → **exit 0**.
3. `validate_trace.py --us US-00.5` → **exit 0**. 4. `factory_sync.py --check` → **exit 0**.
5. Immuabilité des ADR → diff **vide**. 6. `~~` dans ADR-001 → **rc=1**.
7. 7/7 rubriques du template. 8. `Statut = Accepté` + rétroactivité **écrite dans l'ADR lui-même**, en
tête, avant tout le reste. 9. Registre déclaré **ni chronologique ni complet** (002-004 réservés, non
écrits). 10. 6 alternatives écartées **avec leur raison**. 11. Les **4 honnêtetés** dures, non adoucies.
12. `CONSTITUTION.md` **absent** de la PR. 13. `factory.config.json` **absent** *(protégé)*.
14. **0** fichier `.dart`. 15. 4 `status_checks` = 3 `ci.yml` + 1 `branch-naming.yml` — claim exact.
16. **21** scénarios dans le `.feature`, conformes au décompte annoncé.
17. **Aucun runner BDD** : `grep -rn "gherkin\|cucumber\|bdd_widget" pubspec.yaml pubspec.lock
.github/workflows/` → **aucune occurrence** → la portée « **documentaire, 0 exécuté** » est **VRAIE**.
18. Trace : **6** événements cohérents (`EVT_STORY_CREATED` → `EVT_CODE_READY`), `EVT_CODE_READY` émis en
`architect` avec l'**écart de nomenclature déclaré** — le catalogue attend `developer`, et **aucun
@Developer n'intervient** : l'émettre en `developer` **aurait été faux**. Le choix est le bon et il est
**écrit**. 19. Critère nº 4 rapporté **par mot** (iOS 6 · Android 7 · deps_audit 2 · SAST 2) là où le
Story File ne demandait qu'un `grep -ciE` **agrégé** — c'est **plus fort** que demandé : un total ≥ 4
peut être atteint par **un seul** mot répété. **Contrôle mieux fait que spécifié.**

**Mot à décharge.** Cette US ne triche pas. Sur **19** affirmations de stack confrontées à des fichiers
réels, **aucune fausseté** — et les seules faiblesses trouvées (NB-3 à NB-6, NB-8, NB-9) sont des
**renvois manquants** ou des **abréviations**, jamais des affirmations contraires aux faits. Les 4
honnêtetés dures sont écrites **contre** l'intérêt de l'auteur. Le seul faux vert commis a été
**auto-dénoncé**, **conservé**, et sa correction est **juste**. Et sur le point de méthode le plus
délicat — `lint`/`typecheck` — l'US a refusé le constat le plus spectaculaire au profit du plus exact.
**Le bloquant B-1 n'est pas un mensonge : c'est une couverture incomplète déclarée complète.** La
différence compte, et elle est réparable en quatre éditions.

---

## 6. Bornes de mon verdict — ce que cet audit **n'atteste pas**

- ⛔ **Aucun gate `lint`/`typecheck` n'a pu être exécuté sur du code de l'US** : il n'y a **pas de code**.
  Les gates rapportés attestent une **NON-RÉGRESSION**, **jamais** le livrable. La couverture de
  **89,5 %** porte sur `lib/main.dart`, **squelette**, non sur une fonctionnalité métier.
- ⛔ **Aucun des 21 scénarios Gherkin n'est exécuté** — ni runner, ni step definitions (vérifié). Leur
  nombre **ne mesure aucune couverture**.
- ⛔ **Je n'audite que la PR nº 1.** **AC-3** (exactitude de l'Art. 4) et la seconde moitié d'**AC-4**
  (PR nº 2 dédiée, version `1.0 → 1.1`, ligne PROJECT_LOG, aucun autre article) sont **hors de ce diff**
  et **NON audités** : les critères de test **5, 6, 7, 8, 10, 11, 12** restent **non exercés**. **NB-2 est
  une alerte pour cette PR nº 2, pas un constat sur elle.**
- ⚠️ **À la fusion de la PR nº 1, le corpus portera une contradiction VIVE et VOULUE** : ADR-001 écrira
  « *aucun SAST n'existe* » pendant que l'Art. 4 l'annonce **bloquant**. C'est la **conséquence assumée**
  de l'arbitrage **C-1** (deux PR) ; l'écart est **nommé** dans le **rapport** de l'US, ce que l'AC-5
  autorise expressément. **Elle ne se refermera qu'avec la PR nº 2** — et jusque-là, un lecteur de
  `docs/adr/` seul ne la verra pas nommée (**NB-9**).
- ⚠️ **« null-safety strict »** n'est adossé à **aucun** drapeau d'analyseur (`analysis_options.yaml` ne
  porte ni `strict-casts`, ni `strict-inference`, ni `strict-raw-types`) : la base réelle est la
  **soundness obligatoire de Dart 3** + l'énoncé de `STACK_PROFILE.md`. Vrai **par renvoi**, non par
  configuration.
- ⛔ **Aucune exhaustivité revendiquée pour mon balayage.** Mon extension de B-1 est établie sur
  `STORY_CERTIFICATION_BOARD.md` par `grep -n "US-00\.5"` (**16** occurrences triées à la main, dont **5**
  sont des transmissions de charge). Je n'ai **pas** balayé la même classe de défaut sur les 15 autres
  documents vivants du corpus : **d'autres transmissions périmées vers US-00.5 peuvent exister ailleurs**
  *(`CLAUDE.md:271-272` en est une candidate évidente — « périmètre RÉDUIT mais NON VIDE » — mais
  `CLAUDE.md` est **hors du diff** de cette US et son état est **exact**)*.
- ⛔ **Je n'ai vérifié aucune affirmation sur l'état RÉEL de GitHub** : `factory_sync.py --check` est
  **documentaire** et le dit ; `--check-remote` exige des droits admin et **n'a pas été lancé**. Tout ce
  qui touche à la protection de branche est ici **repris d'US-00.7**, non re-prouvé.
- ⛔ **`reviewDecision` de la PR #17 est VIDE** : il n'existe **aucune barrière machine** d'approbation
  humaine sur ce dépôt (`required_approving_review_count: 0`, auto-approbation interdite par GitHub).
  Mon verdict **ne vaut pas** approbation humaine, et **aucun message d'agent** ne la remplace.
- ⛔ **Ma propre position** : je n'ai **pas** accès à la conversation qui a produit ces fichiers. Tous mes
  constats reposent sur des **fichiers lus** et des **commandes exécutées** dans cette session, dont les
  sorties sont **collées ci-dessus**. Là où je n'ai pas exécuté, je l'ai écrit.

---

## 7. Ce qu'il faut faire pour repasser en `PASSED`

| # | Action | Fichier |
|---|---|---|
| **1** 🔴 | Poser `PÉRIMÉ-2026-07-28` **sur la ligne même**, **sans réécrire** le visa daté | `STORY_CERTIFICATION_BOARD.md:212`, `:291`, **`:368`** |
| **2** 🔴 | Retirer la sur-affirmation « les **DEUX** transmissions périmées » | `PROJECT_LOG.md:110` |
| **3** 🟠 | Publier le critère de sortie du marquage comme **commande rejouable** *(leçon d'US-00.7)*, et l'**exécuter** au lieu de compter les marqueurs | rapport de l'US |
| **4** 🟠 | Corriger le diagnostic git *(NB-1)* dans les **3** emplacements | `conformite_ac.txt:42-43`, `PROJECT_LOG.md:110`, `SCB:633` |
| **5** 🟠 | Reformuler le **critère de test nº 5** en lecture « par catégorie » **avant** la PR nº 2 *(NB-2)* | Story File |
| **6** 🟠 | NB-3 à NB-6, NB-8, NB-9 — renvois et précisions dans ADR-001 | `docs/adr/ADR-001-choix-de-stack.md` |

⚠️ **Pour les actions 1, 2 et 6 : ADR-001 est déjà `Accepté`.** Les corrections NB-3→NB-9 portent sur un
ADR **non encore fusionné** — elles sont donc légitimes **maintenant**, dans la PR nº 1. **Après la
fusion, l'immuabilité s'appliquera** et il faudra un **nouvel ADR**. C'est **le** moment de les faire.

---

*Rapport produit par @CodeReviewer (subagent, contexte frais) le 2026-07-30 · modèle
`claude-opus-5[1m]` · toutes les sorties d'outils ci-dessus ont été obtenues dans cette session.*
