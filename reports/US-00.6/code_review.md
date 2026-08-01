# US-00.6 · Audit de revue de code — @CodeReviewer, **contexte frais**

> **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-31 · **Branche** : `feat/US-00.6-couverture-ratchet`
> **HEAD** : `f585e82` · **base `main`** : `309202a` *(vérifié : `git merge-base main HEAD` → `309202a`)*
> **Je n'ai pas eu accès à la conversation qui a produit ce code** *(Art. 2 — anti-auto-certification)*.
> ⛔ **Je n'ai modifié aucun fichier du dépôt** : `git status --porcelain` **vide** après tous mes essais.
> Tous les mutants ont été exécutés sur des **copies** en répertoire temporaire.

---

## 🔴 VERDICT : **FAILED**

| Sévérité | Nombre |
|---|---|
| 🔴 **BLOQUANTS** | **2** *(B-1 : code · B-2 : cohérence du corpus, AC-6)* |
| 🟠 Non bloquants | **12** *(NB-1 → NB-12)* |
| ✅ Établi VRAI par exécution | **11 constats** *(§3)* |

**Le mécanisme livré fonctionne, et il fonctionne mieux que ce que je craignais** : le cliquet est
**réellement actif**, sa valeur est **réellement lue** depuis la source unique *(prouvé par mutant)*, la
capacité de **refuser** est **prouvée**, la valeur `89.4` est **la bonne** *(et `89.5` aurait bien
verrouillé le dépôt — je l'ai mesuré)*, et le correctif d'encodage **tient**, y compris sans
`PYTHONIOENCODING` et sous un codepage plus strict que `cp1252`.

**Ce qui bloque n'est pas une préférence de style.** Ce sont deux exigences **littérales** d'AC **Must**,
chacune **réfutée par exécution ou par lecture** :

* **B-1** — AC-3 « Erreur » exige qu'un rapport dont les **totaux déclarés contredisent les lignes
  comptées** soit **refusé**, et qu'un rapport **tronqué** ne produise **jamais** un vert. **Ce n'est pas
  implémenté** : `LF:` / `LH:` ne sont **jamais lus**. J'obtiens un **VERT à 100 %** sur un rapport
  incohérent — et, dans le même souffle, le script **invite un humain à consigner `100.0`**, c'est-à-dire
  à exécuter **exactement** le geste que le risque **R-1** décrit comme « verrouillage du dépôt ».
  **Un faux vert est le seul état que cette US existe pour supprimer.**
* **B-2** — AC-6 « Erreur » déclare **BLOQUANT** le fait de **taire** un énoncé rendu faux. **Trois
  clauses** de l'**Art. 4** et d'**ADR-001 §4** *(immuable)* sont **devenues fausses** par le succès de
  cette US, **aucune n'est nommée** dans un livrable — et **trois documents affirment le contraire**
  (« ✅ **L'Art. 4 et ADR-001 RESTENT VRAIS** »).

**Les deux corrections sont courtes** : ~6 lignes de Python + 1 fixture pour B-1 ; **trois paragraphes
documentaires** pour B-2, **sans** amendement de la Constitution, **sans** attestation humaine, **sans**
PR dédiée *(c'est l'option **(b)** que l'arbitrage A-1 n'a pas interdite)*. ⛔ **Je n'ai retenu aucun
FAILED « par prudence », et je n'ai adouci aucun constat parce que c'est la dernière US d'EPIC_00.**

---

## 1. Gates statiques imposés par mon rôle — sortie **collée**

```
$ python scripts/run_gates.py --gate lint
EXIT_LINT=1
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).

$ python scripts/run_gates.py --gate typecheck
EXIT_TYPECHECK=1
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
```

⚠️ **Ces deux `exit 1` ne sont PAS des erreurs de l'US** : **les gates `lint` et `typecheck` n'existent
pas** dans cet adapter. Les gates réels du composant `app` sont **`format`, `analyze`, `test`,
`deps_audit`, `build`** *(lus dans `factory.config.json`)*. **Le dire est obligatoire** : un rapport qui
collerait « lint : exit 1 » sans cette phrase fabriquerait un faux bloquant — et un rapport qui écrirait
« lint : OK » fabriquerait un faux vert. **C'est le même défaut que celui qu'US-00.5 a payé six fois.**

**Substituts réellement exécutés, pour ne pas laisser un trou** *(aucun linter Python n'est installé :
`ruff`, `flake8`, `pyflakes`, `pylint`, `mypy` → **tous absents**, vérifié)* :

```
$ python -m py_compile scripts/check_flutter_coverage.py scripts/selftest_coverage_ratchet.py scripts/factory_sync.py
EXIT_PYCOMPILE=0        (Python 3.14.6)

$ python scripts/run_gates.py --all
...
✅ app.format  ✅ app.analyze  ✅ app.test  ✅ app.deps_audit  ✅ app.build
Tous les gates bloquants passent (5 exécutés).
EXIT_ALL_GATES=0
```

---

## 2. Sorties d'outils — le gate réel et la non-régression

```
$ python scripts/run_gates.py --gate test
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:01 +2: All tests passed!
Couverture de lignes : 89.5% (17/19) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigné le 2026-07-31 — US-00.6 — couverture
  initiale mesuree 17/19 = 89,4737 %, arrondie VERS LE BAS. [...]
✅ app.test
EXIT_GATE_TEST=0

$ python scripts/selftest_coverage_ratchet.py
  OK    | regression_16_sur_19.info    exit attendu=1 obtenu=1
  OK    | inchange_17_sur_19.info      exit attendu=0 obtenu=0
  OK    | hausse_18_sur_19.info        exit attendu=0 obtenu=0
  OK    | zero_ligne_mesurable.info    exit attendu=1 obtenu=1
 RESULTAT : les 4 attentes sont tenues, dont 2 REFUS.
EXIT_SELFTEST=0

$ python scripts/factory_sync.py --check      EXIT_FSYNC=0
$ python scripts/check_scb_compliance.py      EXIT_SCB=0     (« SCB conforme »)
$ python scripts/validate_trace.py --all      EXIT_TRACE=0   (« Traçabilité conforme »)
```

> ⚠️ **Méthode de mesure des codes de sortie** — la faute signalée dans le lancement de cette revue est
> **évitée par construction** : **aucun pipe** n'intervient entre la commande et `$?`. Chaque sortie est
> **redirigée dans un fichier** (`> f 2>&1`), `echo "EXIT=$?"` est **la première instruction suivante**,
> et le fichier est affiché **ensuite**. Les codes ci-dessus sont ceux **des scripts**, jamais ceux d'un
> `sed`, d'un `grep` ou d'un `Select-Object`.

---

## 3. Ce que j'ai établi **VRAI par exécution** — un FAILED n'efface pas les acquis

| # | Constat | Preuve exécutée |
|---|---|---|
| V-1 | **Le cliquet est ACTIF** : le seuil appliqué est `89.4 (cliquet)`, plus `80 (plancher)` | gate `test` → `seuil requis : 89.4% (cliquet)` |
| V-2 | **Le trou d'entrée est FERMÉ** : `16/19 = 84,21 %` était **VERT**, il est **ROUGE** | fixture `regression_16_sur_19` → **exit 1** |
| V-3 | ⛔ **Aucun rouge sur un dépôt inchangé** | `run_gates --gate test` → **exit 0** ; fixture `17/19` → **exit 0** |
| V-4 | **La valeur est RÉELLEMENT LUE** *(mutant de la référence)* | même fixture `17/19` : config à `95` → **exit 1** · config à `89.4` → **exit 0** |
| V-5 | **`89.4` est la bonne valeur, et `89.5` aurait VERROUILLÉ le dépôt** | sur le **vrai** `lcov` : réf `89.5` → **exit 1** · réf `89.4737` → **exit 1** · réf `89.47` → exit 0 |
| V-6 | **Fail-explicit** : 8 cas d'erreur sur 8 corrects *(clé absente ⇒ plancher seul exit 0 · objet mal formé · `value` absente · `value` non numérique · `value: null` · réf < plancher · `lcov` absent · 0 ligne)* | §5, tableau des mutants de configuration |
| V-7 | **Le message nomme TOUJOURS lequel des deux seuils est violé** (`(cliquet)` / `(plancher contractuel)`) | sorties de toutes les fixtures |
| V-8 | **Le correctif d'encodage TIENT**, y compris **sans** `PYTHONIOENCODING` | `cp1252` (défaut du poste) **exit 0/1 corrects** · `PYTHONIOENCODING=ascii` **exit 0** · `cp437` **exit 1** · autotest complet en `ascii` **exit 0** · **et le caractère fautif `⬆️` réinjecté (mutant M9) ne casse plus rien** |
| V-9 | **Le step d'autotest est bien dans un job REQUIS**, et **aucun libellé de job n'a bougé** | `ci.yml:125` sous le job `governance` = `📋 Governance (SCB + traçabilité + synchro)`, **présent dans `status_checks`** · la **seule** ligne `name:` ajoutée est celle du **step** ; **0 ligne `name:` supprimée ou modifiée** |
| V-10 | **Les deux éditions humaines sont des AJOUTS PURS** et le bloc `frontend` est **intact** | `git diff --numstat` → `factory.config.json 6/0` · `scripts/factory_sync.py 32/0` · les 4 chemins d'erreur du nouveau bloc **fonctionnent** *(exercés à la main, §5)* |
| V-11 | ⛔ **Aucun test réel cassé, aucune couverture de complaisance** | `git diff --stat main...HEAD -- lib test` → **vide** · `docs/adr`, `docs/governance`, `BACKLOG.md`, `docs/epics`, `CLAUDE.md` → **0 ligne** |

---

## 4. 🔴 Findings **BLOQUANTS**

### B-1 · Un rapport `lcov` **incohérent ou amputé** produit un **VERT à 100 %** — et une **invitation à verrouiller le dépôt**

`[scripts/check_flutter_coverage.py:65-75]` *(`line_coverage_percent`)* · `[…:142]` *(`if total == 0`)` ·
`[…:184-189]` *(message `[HAUSSE]`)* · `[tests/fixtures/US-00.6/]` *(fixture manquante)*

| | |
|---|---|
| **Problème** | Le pourcentage est calculé **uniquement** à partir des enregistrements `DA:`. Les **totaux déclarés** `LF:` / `LH:` ne sont **jamais lus**, et `end_of_record` n'est **jamais exigé**. AC-3 « Erreur » exige littéralement : « *un rapport dont les **totaux déclarés** contredisent les **lignes comptées** est **refusé** : un rapport **tronqué** ne doit **jamais** produire un vert* ». Le risque **R-2** annonce « ⛔ **échec explicite dans les trois cas** » : **2 sur 3** sont tenus *(absent ✅, 0 ligne ✅)*, **le troisième ne l'est pas**. |
| **Preuve** *(exécutée, sur copies)* | `A_totaux_contredits.info` — **19 `DA:` toutes couvertes** mais **`LF:19` / `LH:5` déclarés** *(soit 26 %)* → **`EXIT=0`**, `Couverture de lignes : 100.0% (19/19)`, **`[HAUSSE] … Valeur a consigner : 100.0`**. <br> `C_sous_ensemble.info` — le **vrai** rapport privé de son fichier mal couvert *(cas quotidien : `flutter test --coverage test/un_seul_test.dart` ne réinstrumente qu'un sous-ensemble)* → **`EXIT=0`**, `100.0% (17/17)`, **même invitation à consigner `100.0`**. |
| **Extension** *(ce n'est pas un exemple isolé)* | 1) **Le dénominateur n'est pas authentifié** : `if total == 0` est une garde **de borne, à zéro exactement**. **Tout** dénominateur de **1 à 18** passe en silence — la règle d'AC-1 « un vert obtenu sur un rapport sans ligne mesurable est un faux vert » est appliquée **au seul point 0**, pas à la **plausibilité** de la mesure. 2) **Aggravation par couplage avec R-1** : dans les deux cas ci-dessus, la **seule action humaine que le script sollicite** est de consigner `100.0` ; consignée, cette valeur rend **toute PR infusionnable, administrateur inclus** *(la couverture réelle vaut 89,47 %)*. **Le contrôle transforme un incident bénin en invitation à verrouiller le dépôt.** 3) La valeur imprimée par `[HAUSSE]` est **dérivée d'un rapport non authentifié** sans **aucun** garde-fou. |
| **Solution** | Dans `line_coverage_percent`, **lire aussi `LF:` et `LH:`** et **refuser explicitement** si `LF ≠ lignes comptées` ou `LH ≠ lignes couvertes comptées`, ou si `end_of_record` est absent *(≈ 6 lignes)*. **Et/ou** porter le **dénominateur attendu** dans l'objet du cliquet — la forme retenue en **C-1** le permet déjà : `{"value": 89.4, "lines": 19, …}` ; toute variation du dénominateur devient alors un **échec explicite** au lieu d'un pourcentage recalculé en silence. ⇒ **Ajouter une 5ᵉ fixture** `totaux_incoherents.info` *(exit attendu **1**)* : sans elle, le correctif serait, lui aussi, **un contrôle sans mutant**. |

### B-2 · **Trois clauses** de l'Art. 4 et d'ADR-001 §4 sont devenues **FAUSSES**, **aucune n'est nommée** — et trois documents affirment l'inverse

`[docs/governance/CONSTITUTION.md:67-70]` · `[docs/adr/ADR-001-choix-de-stack.md:96-104]` *(immuable)* ·
`[docs/stories/US-00.6-couverture-ratchet.md:195]` · `[STORY_CERTIFICATION_BOARD.md:571]` ·
`[PROJECT_LOG.md:125]`

| Clause **citée littéralement** | État après cette US | Preuve |
|---|---|---|
| Art. 4 : « ⛔ **`coverage_ratchet` n'est PAS en vigueur** » | 🔴 **FAUX** — il est en vigueur | gate `test` → `seuil requis : 89.4% (cliquet)` ; fixture `16/19` refusée |
| Art. 4 + ADR-001 §4 : « la clé existe au schéma … mais est **absente de `factory.config.json`** » | 🔴 **FAUX** — elle y est | `factory.config.json:81-85` |
| Art. 4 : « (la clé n'y est lue que pour un composant **`frontend`**, absent de l'adapter courant) » · ADR-001 §4 : « **Ajouter la clé sous `app` serait purement et simplement ignoré** » | 🔴 **FAUX** — `factory_sync.py` la lit désormais pour `app` **et** `check_flutter_coverage.py` l'applique | `scripts/factory_sync.py:156-185` ; §3 V-1/V-4 |
| Art. 4 : « **À activer par US-00.6.** » | ⚠️ **PÉRIMÉ** — c'est fait | — |

| | |
|---|---|
| **Problème** | **AC-6 « Erreur » énonce : « taire un énoncé rendu faux est un défaut BLOQUANT — cette US en serait la productrice ».** Or **aucun** livrable de l'US ne nomme ces clauses *(les 3 rapports de `reports/US-00.6/` ne mentionnent ni l'Art. 4 ni ADR-001 ; `BACKLOG.md`, `CLAUDE.md`, `EPIC_00` : **0 ligne** touchée)*. **Pire** : trois documents affirment le contraire — « ✅ **L'Art. 4 et ADR-001 RESTENT VRAIS** » *(Story File §9, SCB, PROJECT_LOG)*. **Un auditeur qui ne lirait que ces trois documents conclurait qu'il n'y a rien à nommer.** C'est **exactement** le mécanisme des six instruments faux d'US-00.5, et cette US en devient la productrice. |
| **Où est l'erreur de raisonnement** *(elle est fine, et c'est pourquoi elle est passée)* | Le Story File §4 avait **correctement** identifié **deux moitiés** : (a) « la clé sera **présente et en vigueur** » et (b) « son activation n'aura exigé **aucun code** dans `factory_sync.py` ». Le changement de route **sauve (b)** — du code **a** été ajouté dans `factory_sync.py`. **Il ne sauve pas (a)**, et **rien ne pouvait la sauver** : **toute** implémentation rend fausse une phrase qui décrit l'**absence** de la clé. L'arbitrage a donc conclu « **SANS OBJET** » sur une prémisse **vraie pour une moitié seulement**. ⚠️ Nuance à charge supplémentaire : même (b) n'est sauvée qu'**à la lettre** — retirer le bloc de `factory_sync.py` **ne désactiverait pas** le cliquet *(c'est `check_flutter_coverage.py` qui l'applique)*, donc la **causalité** affirmée par ADR-001 (« son activation **exige** du code dans `factory_sync.py` ») est fausse ; je ne fonde pas le bloquant sur ce point, mais il doit être écrit. |
| **Solution — courte, et elle NE requiert AUCUNE action humaine nouvelle** | Appliquer l'option **(b)** d'A-1, que l'arbitrage n'a **pas** interdite *(il n'a écarté que l'**amendement**)* : **nommer** les 3 clauses avec (a) leur **citation littérale**, (b) la raison de leur fausseté, (c) leur **destinataire** — dans un rapport de balayage `reports/US-00.6/`, dans `CLAUDE.md` §Dettes et dans `BACKLOG.md`, **le même jour**, **versées à US-00.8** *(véhicules : amendement de l'Art. 4 en **PR dédiée** + **nouvel ADR** pour rectifier ADR-001, jamais son édition)*. ⛔ **Je ne demande NI d'amender la Constitution** *(clause de Révision : PR dédiée + attestation humaine — hors de portée d'un agent)* **NI d'éditer ADR-001** *(immuable)*. ⚠️ **Et il faut retirer, non « mettre à jour », l'affirmation « RESTENT VRAIS »** aux trois emplacements : une valeur fausse **se retire** *(remède d'US-00.5)* — elle est vraie **pour la route**, fausse **pour l'état**, et cette distinction doit être **écrite**, pas repeinte. |

---

## 5. 🟠 Findings **NON BLOQUANTS** *(aucun ne justifie à lui seul un FAILED)*

### NB-1 · L'autotest n'assertionne **que des codes de sortie** : **5 de mes 9 mutants survivent**

`[scripts/selftest_coverage_ratchet.py:103]` *(`ok = code == attendu`)*

J'ai injecté **9 mutants** dans une **copie** du contrôle et exigé que l'autotest **rougisse** :

| Mutant | Vu par l'autotest ? |
|---|---|
| **M1** condition de comparaison neutralisée (`if pct < -1`) | ✅ **VU** (exit 1) |
| **M2** le cliquet n'est plus **LU** (config ignorée) | ✅ **VU** |
| **M3** valeur du cliquet **écrite en dur** (`80.0`) | ✅ **VU** |
| **M5** `max(plancher, cliquet)` → `min(...)` | ✅ **VU** |
| **M4** garde « 0 ligne mesurable » **supprimée** | ❌ **NON VU** (exit 0) |
| **M6** impression de la **HAUSSE** supprimée | ❌ **NON VU** |
| **M7** le message ne nomme plus **lequel** des deux seuils | ❌ **NON VU** |
| **M8** détection « cliquet < plancher » **supprimée** | ❌ **NON VU** |
| **M9** caractère hors `cp1252` **réinjecté** dans un `print` | ❌ **NON VU** — *et c'est ici une **bonne** nouvelle : la garde `errors="replace"` neutralise le bug du 2026-07-31. **Le correctif tient.*** |

**Le cœur est falsifiable** *(valeur, lecture, condition : **vus**)* — **c'est l'essentiel, et je le dis
sans réserve**. Mais : **M4 signifie que la fixture `zero_ligne_mesurable` passe pour la MAUVAISE
raison** *(`0 % < 89,4 %` suffit à la rendre rouge, garde ou pas)* : la règle « un `OK` sur ensemble vide
est faux » **n'a donc aucun mutant discriminant**. Et **M6/M7/M8** correspondent aux critères de test
**#9, #13, #14** du Story File, qu'**aucun contrôle en CI** n'assertionne.
**Solution** : assertionner **un fragment de message** par cas *(≈ 1 ligne chacun)* et ajouter **2 cas**
alimentés par des configurations temporaires — l'autotest **sait déjà** en fabriquer.

### NB-2 · Le nombre `89.4` est **dupliqué dans un artefact exécuté**

`[scripts/selftest_coverage_ratchet.py:39]` — `REF_MUTANT = 89.4`

Le critère de test **#5** d'AC-2 annonce `grep -rn` d'un seuil en dur → **rc=1**. **Il ne rend pas 1** :
`grep -rn "89\.4"` sur les artefacts **exécutés** trouve `factory.config.json:82` *(la source, légitime)*
**et** `selftest_coverage_ratchet.py:39`. Que le mutant **ne lise pas** la source testée est **juste**
*(un contrôle ne doit jamais tirer son attente du vocabulaire de la règle qu'il teste)* — mais **choisir
exactement la valeur du projet** crée un couplage sémantique que personne ne verra bouger.
**Solution** : `REF_MUTANT = 85.0` *(toute valeur de l'intervalle `]84.21 ; 89.47]` conserve les 4
verdicts)* + un commentaire disant **pourquoi elle doit différer** de la valeur du projet.

### NB-3 · Le **plancher `80` reste écrit deux fois**, et le Story File affirme le contraire

`[factory.config.json:80]` *(`coverage_min: 80`)* · `[factory.config.json:98]` *(`--min 80` dans la
commande du gate)* · `[docs/stories/US-00.6-couverture-ratchet.md:149]`

Le §7 « Valeur ajoutée » affirme : « **Occurrences du seuil dans les artefacts exécutés : 2 → 1** *(la
commande de gate cesse de porter le nombre en dur)* ». **C'est faux** : la commande porte toujours
`--min 80`. Le Story File **se contredit lui-même** *(§Patterns imposés dit, à raison, que résorber cette
duplication est **hors périmètre**)*, et **DoD 5** *(« commande de gate … **exempte** »)* **n'est pas
cochable à la lettre**. **Aucun contrôle ne vérifie l'égalité des deux `80`** : mesuré — `coverage_min: 10`
en config **avec** `--min 80` dans la commande → `factory_sync --check` **conforme**.
⚠️ Corollaire sur une revendication d'AC-4 (iii) : `coverage_min` est **désormais lue**, mais **par
`factory_sync.py`**, qui ne **mesure** rien. La phrase d'ADR-001 « `coverage_min = 80`, **mesuré par
`lcov` via un script dédié** » **n'est donc toujours pas littéralement vraie** : le script dédié ne lit
pas `coverage_min`.
**Solution** *(elle rendrait la phrase d'ADR-001 vraie pour de bon)* : `check_flutter_coverage.py`
**ouvre déjà** `factory.config.json` — y lire `app.coverage_min` et faire de `--min` un **override
optionnel**. À défaut : **retirer** l'affirmation « 2 → 1 » du §7 et **reformuler DoD 5**.

### NB-4 · `--no-ratchet` neutralise le cliquet **sans que `--check` s'en aperçoive**

`[scripts/check_flutter_coverage.py:143-152]` *(option `--no-ratchet`)* · `[scripts/factory_sync.py:180-185]`

Le nouveau bloc humain vérifie que la commande du gate **appelle** `check_flutter_coverage.py` — pas que
le cliquet **s'applique**. Mesuré sur `check_thresholds` :

| Commande du gate mutée | `--check` |
|---|---|
| `… check_flutter_coverage.py --min 80 --no-ratchet` | **AUCUNE ERREUR** *(cliquet totalement neutralisé)* |
| `… check_flutter_coverage.py --min 80 --config /tmp/rien.json` | **AUCUNE ERREUR** *(cliquet « IGNORÉ », exit 0 sur le plancher seul)* |
| `flutter test --coverage` *(script retiré)* | ✅ erreur levée |

⚠️ **Portée honnête** : ces trois cas exigent d'éditer `factory.config.json`, fichier **protégé**
*(action humaine)* — **ce n'est pas une faille exploitable par un agent**, c'est un **défaut de défense en
profondeur** dans le contrôle dont le but déclaré est précisément d'empêcher que « **le cliquet soit
IGNORÉ** ». **Solution** : rejeter `--no-ratchet` et tout `--config` différent de `factory.config.json`
dans la commande du gate *(2 conditions)*.

### NB-5 · La forme `{value, date, motif}` **n'est exigée nulle part**

`[scripts/factory_sync.py:161-164]` · `[scripts/check_flutter_coverage.py:110-118]`
L'arbitrage **C-1** exige un objet portant « **au moins** la valeur, la **date** et le **motif** ». Les
deux scripts n'exigent que **`value`** : `{"value": 89.4}` seul passe partout. Le lien
valeur↔justification reste donc la **« convention non enforced »** que le projet dénonce ailleurs.
**Solution** : 2 lignes dans `factory_sync.py` *(le lieu naturel : il valide la **forme**)*.

### NB-6 · Source unique **introuvable** ⇒ vert sur le plancher seul

`[scripts/check_flutter_coverage.py:81-82]`
Mesuré : `--config chemin/inexistant.json` → `cliquet IGNORÉ : … introuvable` puis **exit 0**. Le
comportement est **annoncé** *(donc pas « silencieux »)*, mais **lancer le contrôle depuis un autre
répertoire de travail restaure exactement l'état d'avant US-00.6**. « Clé absente ⇒ plancher seul » est
un choix **arbitré** ; « **source unique introuvable** » est un **symptôme d'invocation erronée** et
mériterait un traitement distinct *(avertissement appuyé, ou échec si un drapeau `--require-config`)*.

### NB-7 · « Les messages sont désormais **en ASCII** » — **c'est faux**

`[scripts/check_flutter_coverage.py:51]` · `[reports/US-00.6/bug_trouve_par_le_mutant.md]` *(§Correctif, point 1)*
**Vérifié par AST** *(mon propre script, sur les seuls arguments de `print`)* : il reste `É` (0xC9),
`é` (0xE9) et `—` (U+2014) dans les messages des **deux** scripts. La propriété **réellement** vraie est
« **encodable en `cp1252`** » — que le rapport énonce **à la ligne suivante**, à côté de l'affirmation
fausse. **La garde rend l'écart inoffensif** *(prouvé : V-8 et M9)*, mais **rien ne maintient la
propriété** : le « contrôle par AST » du rapport **n'est pas un script versionné** *(vérifié : aucun)*.
C'est le **remède 1** d'US-00.5 — *ne jamais écrire un résultat à la main à côté d'une commande*.
**Solution** : **retirer** le mot « ASCII » *(la garde, elle, est le vrai correctif)*, ou **versionner**
le contrôle AST et le brancher dans le step d'autotest déjà requis *(≈ 10 lignes)*.

### NB-8 · `reports/US-00.6/verify.sh`, annoncé comme « **la source vive** », **n'existe pas**

`[docs/stories/US-00.6-couverture-ratchet.md:542-543]`
Le préambule des critères de test énonce : « **la source vive est `sh reports/US-00.6/verify.sh`** — c'est
la leçon la plus chère d'US-00.5 ». **`ls` → No such file or directory.** Un auditeur qui suit le Story
File à la lettre tombe sur un **emplacement écrit à la main qui n'existe pas** — **exactement** le défaut
que la phrase prétend éviter. **Solution** : créer le script *(les commandes de ce rapport sont
directement réutilisables)*, ou **retirer la phrase**.

### NB-9 · La **question expérimentale** d'AC-1 « Limite » n'est **pas tranchée**

`[reports/US-00.6/]` *(absent)* · `[docs/stories/…:261-266]` · **DoD case 2**
« ⛔ **La réponse est écrite quelle qu'elle soit** » : *un fichier Dart qu'aucun test n'importe entre-t-il
au dénominateur ?* **Aucun rapport n'y répond** *(grep sur `reports/US-00.6/` : rien)*. C'est l'item qui
**décide si le cliquet aura le moindre mordant à partir d'US-01.1** — si un fichier non importé n'entre
pas au dénominateur, **ajouter 500 lignes non testées ne fait pas baisser la couverture**. ⛔ **Je ne
l'ai pas tranchée moi-même** : l'expérience exige de créer un fichier dans `lib/`, ce que mon rôle
m'interdit *(et le contrôle de sortie de l'AC exige `lib/` inchangé)*.

### NB-10 · « Une troncature **AUGMENTE** le pourcentage » est **faux**, et écrit comme « **vérifié** »

`[tests/fixtures/US-00.6/README.md:19]` · `[docs/stories/…:319]` · `[docs/stories/…:503]` *(R-2)*
Le vrai rapport porte ses lignes non couvertes **en tête** (`DA:9,0`, `DA:10,0`), donc **une troncature
de fin PRÉSERVE les non couvertes et détruit les couvertes** : le pourcentage **BAISSE**. Mesuré sur le
vrai `lcov`, en retirant `k` enregistrements de la fin — **87,50 % → 84,62 % → 77,78 % → 50,00 %** *(k =
3, 6, 10, 15)*, **tous ROUGES**. ⇒ un `lcov` **tronqué** est **conservateur**, pas dangereux ; la phrase
inverse le sens, et le README la donne comme « **contre-intuitive et vérifiée** ». **Le vrai chemin de
faux vert est ailleurs** : un rapport portant **moins de FICHIERS** *(→ **B-1**)*. **Solution** :
corriger la phrase **par la mesure** aux trois emplacements — c'est aussi le **motif exact** de B-1.

### NB-11 · La copie humaine de **T8** diverge du diff transmis

`[scripts/factory_sync.py:156]` *(commentaire indenté à **24** espaces)* · `[…:188]` *(ligne blanche avec
espaces de fin après `return errors`)* · `[reports/US-00.6/transmissions_humaines.md §T8]`
Le diff transmis prévoyait le commentaire à **4** espaces, une ligne blanche avant le bloc, et un second
commentaire *(« Le cliquet n'a d'effet QUE si le gate l'applique … »)* **absent du fichier appliqué**.
**Aucune conséquence fonctionnelle** *(vérifié : `--check` exit 0 et les 4 chemins d'erreur corrects ;
`git diff --numstat` = **32/0**, ajout pur, `frontend` intact)*. Mais le commentaire mal indenté **est
visuellement à l'intérieur de la boucle `for` du bloc `frontend`** : la prochaine ligne ajoutée « à sa
suite » atterrirait **dans la boucle**. **Solution** : réaligner à 4 espaces et supprimer la ligne
blanche à espaces de fin *(édition **humaine** — fichier protégé)*.

### NB-12 · Le nouveau bloc de `factory_sync.py` **n'a aucun test**

`[scripts/factory_sync.py:156-185]`
Ses **4** chemins d'erreur ne sont exercés par **rien** en CI. Je les ai exercés **à la main** — ils
**fonctionnent tous les 4** *(§NB-4)* —, mais c'est **précisément la dette du `selftest` de
`check_branch_protection.py` qui dort depuis US-00.4**, celle que l'arbitrage **C-3** de cette US se
félicite de ne pas reproduire. **Solution** : l'autotest fabrique déjà des configurations temporaires ;
lui faire appeler `check_thresholds` couvre les 4 chemins pour ~15 lignes.

---

## 6. Couverture **AC ↔ livrable ↔ preuve**

| AC | Verdict | Fondement |
|---|---|---|
| **AC-1** *(mesure + dénominateur)* | 🟠 **partiel** | dénominateur imprimé à chaque exécution ✅ · mesure brute datée archivée ✅ · **question expérimentale non tranchée** *(NB-9)* · « 0 ligne ⇒ refus » vrai **mais sans mutant discriminant** *(NB-1/M4)* |
| **AC-2** *(source unique réellement lue)* | 🟠 **partiel** | **lecture prouvée par mutant** ✅ *(V-4)* · fail-explicit 8/8 ✅ · **le seuil apparaît plus d'une fois dans les artefacts exécutés** *(NB-2, NB-3)* · message d'absence ne dit pas **où** écrire la clé *(le fichier n'est pas nommé)* |
| **AC-3** *(refus prouvé)* | 🔴 **NON tenu** | refus réel et prouvé ✅ *(V-2)*, 4 fixtures ✅, aucun test cassé ✅ — **mais la clause « totaux déclarés contredits / rapport tronqué ⇒ refusé » n'est pas implémentée** *(**B-1**)* |
| **AC-4** *(plancher ≠ cliquet)* | ✅ **tenu** | deux rôles distincts, message nommant lequel est violé ✅ *(V-7)* · `réf < plancher` refusé explicitement ✅ · réserve : `coverage_min` lue par `factory_sync` **seulement** *(NB-3)* |
| **AC-5** *(hausse / baisse volontaire)* | ✅ **tenu** *(Should)* | hausse **non bloquante** + valeur exacte imprimée ✅ · aucune remontée automatique ✅ · réserve : l'impression n'est pas assertionnée *(NB-1/M6)* et la valeur imprimée peut venir d'un rapport amputé *(B-1)* |
| **AC-6** *(cohérence du corpus)* | 🔴 **NON tenu** | ADR-001 et la Constitution **non édités** ✅ *(0 ligne — exigence respectée)* — **mais 3 clauses rendues fausses ne sont nommées nulle part, et 3 documents affirment l'inverse** *(**B-2**)*. Le critère de clôture d'EPIC_00 *(DoD 20)* n'est pas coché : **normal**, il est explicitement « fin de cycle » |

---

## 7. **Bornes de ce verdict** — ce que je n'ai **pas** vérifié

1. **Je n'ai pas exécuté la CI.** `ci.yml` a été vérifié **par lecture et par cohérence de configuration**
   *(le job `governance` est bien un contexte requis, aucun libellé n'a bougé)*. **`actionlint` n'est pas
   installé sur ce poste** : la validité YAML du step ajouté **n'est pas prouvée par outil** — seule
   l'absence de modification de ligne `name:` l'est.
2. **Je n'authentifie rien du côté GitHub** : ni la protection de branche, ni l'existence d'une PR, ni la
   provenance d'une fusion. Ces bornes-là appartiennent à US-00.7 et restent entières.
3. **Aucun linter ni type-checker Python n'existe dans cette factory** *(5 outils testés, tous absents ;
   les gates `lint`/`typecheck` **n'existent pas**)*. Mon jugement de qualité de code est donc **manuel**,
   appuyé sur `py_compile` et sur **9 mutants exécutés** — **pas** sur une analyse statique.
4. **Mes mutants sont finis** : **9** sur le contrôle, **7** sur la configuration, **6** sur `lcov`,
   **4** sur la commande du gate, **3** codepages. **Aucune exhaustivité n'est revendiquée** — B-1 a été
   trouvé par un mutant que **personne n'avait écrit**, ce qui est la meilleure raison de supposer qu'il
   en reste.
5. **Je n'ai pas mesuré la qualité des tests**, et le cliquet non plus : **19 lignes**, **1 fichier**,
   `89,47 %` **sans aucune valeur statistique**, **aucune couverture de branches**. Le mécanisme **date un
   niveau et interdit d'en reculer** — rien de plus. **La valeur réelle de cette US reste celle qu'elle
   annonce : marge de régression 1 ligne → 0 ligne.**
6. **Le cliquet ne monte jamais seul** : ce que j'ai validé, c'est qu'il protège le dernier niveau
   **CONSIGNÉ**. **Rien** n'oblige la référence à suivre la réalité, et **aucune détection de péremption
   n'existe** — la borne AC-5 est **exacte et non fermée**.
7. **Ni B-1 ni B-2 ne remettent en cause les 11 constats du §3.** Corrigés, ils n'exigent **aucun**
   changement d'architecture : le mécanisme est **sain**, il est **incomplet sur une clause d'AC** et son
   **corpus est en retard d'un constat**.

---

## 8. Rejouabilité — **le banc de mutation, verbatim** *(remède 1 d'US-00.5)*

⛔ **Aucun résultat de ce rapport n'a été écrit à la main à côté d'une commande absente.** Le harnais
ci-dessous est **celui que j'ai exécuté** ; il travaille sur des **copies** *(le dépôt reste intact)*.
Placer les copies de `scripts/check_flutter_coverage.py`, `scripts/selftest_coverage_ratchet.py` et de
`tests/fixtures/US-00.6/` dans un répertoire temporaire, puis :

```python
# banc de mutation — chaque mutant DOIT rendre l'autotest ROUGE (exit != 0)
import subprocess, sys, os
from pathlib import Path
SANDBOX = Path(os.environ["SANDBOX"])          # copie du dépôt (scripts/ + tests/fixtures/)
CHECKER = SANDBOX / "scripts" / "check_flutter_coverage.py"
ORIG = CHECKER.read_text(encoding="utf-8")
MUTANTS = [
 ("M1 condition",   "    if pct < required:", "    if pct < -1:  # MUTANT"),
 ("M2 lecture",     '            ratchet, ratchet_msg = read_ratchet(Path(args.config))',
                    "            ratchet, ratchet_msg = (None, 'MUTANT')"),
 ("M3 valeur dure", '        value = float(node["value"])', "        value = 80.0  # MUTANT"),
 ("M4 garde zero",  "    if total == 0:", "    if False:  # MUTANT"),
 ("M5 max->min",    "    required = max(args.min, ratchet) if ratchet is not None else args.min",
                    "    required = min(args.min, ratchet) if ratchet is not None else args.min"),
]
env = dict(os.environ); env.pop("PYTHONIOENCODING", None)
for nom, avant, apres in MUTANTS:
    assert ORIG.count(avant) == 1, nom                      # ancrage unique, jamais lexical approximatif
    CHECKER.write_text(ORIG.replace(avant, apres), encoding="utf-8")
    p = subprocess.run([sys.executable, "scripts/selftest_coverage_ratchet.py"], cwd=SANDBOX,
                       capture_output=True, text=True, encoding="utf-8", errors="replace", env=env)
    print(f"{'VU' if p.returncode else 'NON VU'} | exit={p.returncode} | {nom}")
CHECKER.write_text(ORIG, encoding="utf-8")
assert CHECKER.read_text(encoding="utf-8") == ORIG          # contrôle de sortie
```

**Fixtures de B-1, à créer telles quelles** *(elles sont la 5ᵉ et la 6ᵉ fixtures manquantes)* :

```
# A_totaux_contredits.info  -> attendu ROUGE, obtenu VERT 100.0% (19/19)
TN:
SF:lib/a.dart
DA:1,1 ... DA:19,1        (19 enregistrements, tous couverts)
LF:19
LH:5                       <-- totaux DECLARES contredisant les lignes COMPTEES
end_of_record

# C_sous_ensemble.info      -> attendu ROUGE, obtenu VERT 100.0% (17/17)
#   le vrai coverage/lcov.info privé de ses 2 enregistrements « ,0 » (DA:9,0 / DA:10,0)
```

**Contrôles de configuration** *(sur des copies de `factory.config.json`, via `--config`)* :
`value: 95` → **exit 1** · `value: 70` → **exit 1 « INCOHÉRENTE »** · clé retirée → **exit 0 plancher
seul** · `"89.4"` *(chaîne)* → **exit 1** · sans `value` → **exit 1** · `value: "abc"` / `null` →
**exit 1** · `value: 89.5` sur le **vrai** `lcov` → **exit 1** *(la preuve du piège d'arrondi)*.

**Encodage** : `PYTHONIOENCODING` **non défini** *(cp1252)*, `=ascii`, `=cp437` sur la fixture de
**hausse** → **exit 0** attendu dans les trois cas.

---

## 9. Décision

**FAILED** — **2 findings bloquants**, **12 non bloquants**.
**Ce n'est pas un refus du mécanisme** : le cliquet fait ce qu'il annonce, sa valeur est juste, son mutant
a déjà payé son prix en trouvant un **vrai bug de production**. **C'est un refus de deux clauses non
tenues**, l'une dans le code *(un faux vert reste possible, et il invite à verrouiller le dépôt)*, l'autre
dans le corpus *(trois énoncés devenus faux, non nommés, et trois documents qui affirment l'inverse)*.
**Les deux se corrigent en une passe courte, et aucune ne remet en cause la route arbitrée.**

> ⛔ Ce rapport ne coche **aucune** case du SCB, ne modifie **aucun** code, ne touche **ni** `CLAUDE.md`
> **ni** le Story File. Le rituel `/audit-us` reporte ce verdict.
