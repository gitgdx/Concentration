# 🧪 QA FINALE — US-00.5 (ADR-001 + exactitude de l'Art. 4)

> **@QA_Tester · contexte frais · 2026-07-31 · 3ᵉ passage** — modèle réel `claude-opus-5[1m]`.
> Branche `feat/US-00.5-certif`, partie de `main` = **`c62cdcc`** *(merge de la PR #18)*.
> ⛔ Ce rapport n'écrase ni [`qa.md`](qa.md) *(1ᵉʳ passage)* ni [`qa_reaudit.md`](qa_reaudit.md) *(2ᵉ)*.
>
> **Discipline d'écriture appliquée à ce rapport lui-même** *(leçon payée cinq fois par ce projet)* :
> tout chiffre ci-dessous est **soit une SPÉCIFICATION** *(« 1 ADR doit exister »)*, **soit une CAPTURE
> explicitement datée du 2026-07-31 avec sa commande publiée**. La **source vive** des valeurs est
> [`qa_exit_v3.sh`](qa_exit_v3.sh) ; sa sortie brute du jour est déposée dans
> [`qa_exit_v3_output.txt`](qa_exit_v3_output.txt).

---

# ⛔ VERDICT : `🧪 FAILED` — **DoD 18 reste DÉCOCHÉE**

**Et il faut dire d'abord ce qui n'est pas en cause, parce que c'est la troisième fois :**

> ✅ **LE PRODUIT EST EXACT. LES DEUX LIVRABLES SONT BONS.** ADR-001 est conforme à AC-1 et AC-2 sur
> l'intégralité de ce qui est vérifiable par exécution. **L'amendement de l'Art. 4 est l'artefact le
> mieux vérifié de cette US** : j'ai contrôlé **à charge** chacune de ses affirmations, une par une, par
> exécution — **aucune n'est fausse**. La clause *Révision* est tenue **à la lettre** *(PR #18 dédiée :
> 2 fichiers, pas 3)*. **La contradiction ADR-001 ↔ Art. 4 est ÉTEINTE** *(§3)*. Mon `FAILED` porte,
> pour la troisième et dernière fois, sur les **PREUVES** et les **INSTRUMENTS** — jamais sur le produit.
> Si l'humain veut clore EPIC_00, **le contenu ne l'en empêche pas** ; ce qui l'en empêche est un
> **contrôle qui ne peut pas échouer** et un **ledger qui ignore la moitié de l'US**.

**Motif du FAILED, par EXTENSION** *(et non par renvoi)* — le défaut est :

> **« une règle, une valeur ou un état existe en DEUX exemplaires, et l'exemplaire de contrôle a dérivé
> derrière la source. »**

Son extension au 2026-07-31 couvre **quatre** emplacements, tous établis par exécution, **dont un
FAUX VERT démontré par mutation** :

| # | Emplacement | Nature | Bloquant |
|---|---|---|---|
| **F-1** | `verify.sh` §7 — contrôle de MONOTONIE | **TAUTOLOGIE** : compare l'ancien motif **à lui-même**. Recall **0/1** sur la seule régression qu'il existe pour voir. **7ᵉ manifestation.** | 🔴 **OUI** |
| **F-2** | Critère de test nº 5 + `verify.sh` §4 — table des catégories de l'Art. 4 | La **source** (l'article) a changé en PR #18 ; **les deux copies portent l'ancienne liste** et affirment **3 choses fausses** sur l'article livré | 🔴 **OUI** |
| **F-3** | `STORY_CERTIFICATION_BOARD.md` §`[US-00.5]` + DoD | Le **2ᵉ livrable est sur `main`** et le **ledger ne le sait pas** : le SCB annonce encore la PR nº 2 comme *à venir*, DoD **20 est cochée** | 🔴 **OUI** |
| **F-4** | `qa_detecteur_v2.sh` — **MON** instrument, critère nº 20 | Code de sortie **inopérant** *(exit 1 inconditionnel)* + §D à **numéros de ligne figés**. **Ma faute, je la solde ci-dessous** | 🟠 **oui, mais non imputable à @Architect** |

⚖️ **Rappel d'autorité (Art. 5)** : je délivre `🧪 PASS`/`FAILED`. Le `🚀 OUI` appartient à `/certify`.

---

## 1. Décomptes exacts — les 21 critères, tous EXERCÉS

> **Commande de relance globale** : `sh reports/US-00.5/qa_exit_v3.sh` *(+ les commandes unitaires
> ci-dessous, toutes rejouées ce jour)*.

**CAPTURE DU 2026-07-31 — 21 critères exécutés : `17 PASSÉS`, `4 NON PASSÉS` (nº 5, 19, 20, 21).**
Aucun critère « non applicable », aucun « hors diff » : **les 5 critères que mes deux passages
précédents laissaient hors périmètre (7, 8, 10, 11, 12) sont désormais exercés et PASSENT.**

| # | Commande exécutée | Attendu | Obtenu | |
|---|---|---|---|---|
| 1 | `ls docs/adr/ADR-001-*.md` | 1 fichier | `ADR-001-choix-de-stack.md` | ✅ |
| 2 | `grep -c "Accepté" docs/adr/ADR-001-*.md` | ≥ 1 | 3 | ✅ |
| 3 | `git diff --stat <base1>...<head1> -- ADR-005* ADR-006* ADR-007*` | 0 ligne | 0 | ✅ |
| 4 | `grep -ciE "iOS\|Android\|deps_audit\|SAST" ADR-001` | ≥ 4 | 15 | ✅ |
| 5 | catégories de l'Art. 4 → gate qui les réalise | **1 échec : `SAST`** | **0 échec** + table dérivée | ❌ |
| 6 | le gate réalisant chaque catégorie n'est pas `"blocking": false` | **1 échec : audit de dépendances** | **exactement 1** (`app.deps_audit` → `False`) | ✅ |
| 7 | `grep -c "branch-naming" CONSTITUTION.md` | ≥ 1 | 2 | ✅ |
| 8 | `grep -nE "coverage_ratchet" CONSTITUTION.md` + contexte | cité **uniquement** comme *à activer par US-00.6* | 2 occurrences, **aucune** ne le présente en vigueur *(détail §2)* | ✅ |
| 9 | `git diff <base1>...<head1> -- CONSTITUTION.md` | **VIDE** | **0 octet** | ✅ |
| 10 | `git diff --name-only <base2>...<head2>` | `CONSTITUTION.md` + `PROJECT_LOG.md`, rien d'autre | **exactement ces 2** | ✅ |
| 11 | `sed -n 's/.*Version \([0-9]\+\.[0-9]\+\) — \([0-9-]\{10\}\).*/\1 \2/p' CONSTITUTION.md \| head -1` | version **> 1.0** + date | `1.1 2026-07-31` | ✅ |
| 12 | `git diff <base2>...<head2> -- CONSTITUTION.md \| grep -cE "^[+-]## Art\. [^4]"` | 0 | 0 *(et **0** ligne `+/-` commençant par `#`)* | ✅ |
| 13 | 3 écarts hors périmètre nommés **avec destinataire** | 3/3 | 3/3 *(SAST→US-00.8 · `coverage_ratchet`→US-00.6 · `CONSTITUTION.md` non protégé→US-00.8)* | ✅ |
| 14 | `grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md` | ≥ 1 | 5 | ✅ |
| 15 | `grep -rn "~~" docs/adr/ADR-001-*.md` | rc=1 | rc=1 | ✅ |
| 16 | `python scripts/run_gates.py --all` | exit 0 | **exit 0**, 5 gates bloquants | ✅ |
| 17 | `check_scb_compliance.py` · `validate_trace.py --us US-00.5` | exit 0 | **0** et **0** *(+ `factory_sync.py --check` → 0)* | ✅ |
| 18 | runner BDD / step definitions | **ABSENT** → 21 documentaires, 0 exécuté | **absent** *(0 dépendance gherkin, 0 step def, 0 référence CI)* | ✅ |
| 19 | `sh reports/US-00.5/verify.sh` | exit 0 | **exit 0**, mais **§7 tautologique** et **§4 faux** | ❌ |
| 20 | `sh reports/US-00.5/qa_detecteur_v2.sh` | 4 conjoncts | conjoncts **atteints**, **exit code inopérant** | ❌ |
| 21 | `verify.sh` §7 | **8/8 détectés ET 0 ligne perdue** | 8/8 **réel**, « 0 ligne perdue » est une **CONSTANTE** | ❌ |

*`<base1>...<head1>` = `856c366...6d36d48` (parents réels du merge de la PR #17) ·
`<base2>...<head2>` = `488b074...0f4cf69` (parents réels du merge de la PR #18).*

### Suites de tests et couverture — exécutées

| Mesure | Commande | Résultat (CAPTURE DU 2026-07-31) |
|---|---|---|
| Tests unitaires | `python scripts/run_gates.py --gate test` | **2 passed · 0 failed · 0 skipped** |
| Couverture de lignes | idem *(gate intégré)* | **89,5 % (17/19)** — seuil requis **80 %** ✅ |
| Gates bloquants | `python scripts/run_gates.py --all` | **5/5 verts** *(format, analyze, test, deps_audit non bloquant, build)* — exit 0 |
| Secrets | `gitleaks detect --no-banner --redact -c .gitleaks.toml` | **no leaks found**, 75 commits — exit 0 |
| Scénarios E2E / BDD | — | **21 scénarios · 0 exécutés · 0 passed · 0 failed · 21 NON EXÉCUTABLES** |

> ⚠️ **Le décompte des « skipped » exigé par l'Art. 3, dit sans détour** : les **21** scénarios Gherkin
> ne sont **pas 21 skipped** — ils ne sont **pas exécutables du tout**. Ni runner, ni step definitions,
> ni lecture de `tests/features/**` en CI *(re-vérifié ce jour, les trois)*. **Leur nombre ne mesure
> aucune couverture**, et la couverture de 89,5 % porte sur le **squelette Flutter**, pas sur cette US :
> elle atteste une **NON-RÉGRESSION**, **jamais le livrable** *(0 fichier de code dans l'US)*.

---

## 2. L'amendement, vérifié **À CHARGE** — c'est le livrable neuf

J'ai pris chaque exigence de la demande et chaque affirmation de l'article, et je les ai **exécutées**.

| Exigence | Contrôle exécuté | Résultat |
|---|---|---|
| Version **lue**, non supposée | `sed -n 's/.*Version …/\1 \2/p'` | **`1.1 2026-07-31`** — l'article porte en outre un **Historique des versions** *(1.0 → 1.1)* qui rend l'incrément **vérifiable** et non seulement déclaré ✅ |
| `branch-naming` nommé | `grep -c "branch-naming"` | **2** — `branch-naming.yml` **et** son contexte `check-branch-name` ✅ |
| `coverage_ratchet` **uniquement** « à activer par US-00.6 » | lecture des 2 occurrences | occ. 1 : « **n'est PAS en vigueur** … **À activer par US-00.6** » · occ. 2 : mention **historique** dans le motif d'amendement *(« l'article **citait** … »)*. **Aucune ne le présente en vigueur** ✅ |
| **Aucun autre article** touché | `git diff … \| grep -cE "^[+-]## Art\. [^4]"` + inspection de **toutes** les lignes `+/-` en `#` | **0** et **0**. Le diff = **en-tête de version** + **Art. 4**, rien d'autre ✅ |
| `lint` et `typecheck` **non touchés** | `grep -n "typecheck" CONSTITUTION.md` | 🟠 **TA DEMANDE EST INEXACTE, et je te le dis** : **`typecheck` a DISPARU de toute la Constitution** *(0 occurrence)*, remplacé par **« typage statique »**, et **« mise en forme » a été AJOUTÉ**. C'est une **amélioration de fond** *(les deux correspondent à des gates réels)* — mais ce n'est pas « non touché », et c'est la **cause directe de F-2** |
| Clause *Révision* à la lettre | parents réels du merge #18 | **PR dédiée** : `PROJECT_LOG.md` + `CONSTITUTION.md`, **2 fichiers** · **ligne de journal dédiée** présente · **incrément vérifiable** · **4/4 contextes requis SUCCESS** sur `0f4cf69` · `mergedBy = gitgdx` ✅ |

### Chaque affirmation de l'article amendé, confrontée au dépôt

| L'article affirme | Contrôle exécuté | Verdict |
|---|---|---|
| catégories = mise en forme, lint, typage statique, tests, audit de dépendances | `run_gates --gate {format,analyze,test,deps_audit}` | **exact** — chacune est réalisée par un gate existant ✅ |
| « Aucun gate SAST n'existe » | `run_gates --gate sast` | **« aucun gate ne correspond »** ✅ |
| `actionlint` **épinglé par SHA256** dans le job **requis** `governance` | lecture de `ci.yml` | **step** du job `governance` *(délibérément, pour être bloquant)*, `VERSION=1.7.12` + `SHA256=8aca8d…` + `sha256sum -c` ✅ |
| `deps_audit` porte `"blocking": false` | lecture de `factory.config.json` | **exact** ✅ |
| `coverage_ratchet` : activation exige **du code**, la clé n'étant lue que pour un composant `frontend` **absent** | `grep -n "coverage_ratchet" scripts/factory_sync.py` | **exact** — `frontend.get("coverage_ratchet")`, et `frontend` n'existe pas dans l'adapter `flutter` ✅ |
| `build` bloquant, sur une **cible de repli** | `factory.config.json` → `flutter build web --release` | **exact**, et la borne est **écrite** ✅ |
| **4** contextes requis, **3** de `ci.yml` + **1** de `branch-naming.yml` | `factory.config.json` → `status_checks` | **exact** *(secrets-scan, governance, app-quality | check-branch-name)* ✅ |
| l'absence de SAST « déjà consignée dans un rapport de sécurité dès le 2026-07-26 » | `grep -c SAST reports/*/security.md` | **exact** — elle figure dans les rapports d'US-00.1 à US-00.4 et US-00.7 ✅ |

> ✅ **Conclusion, sans réserve** : **je ne trouve aucune fausseté dans l'Art. 4 amendé.** Il est,
> au 2026-07-31, **le texte le plus exact du corpus**, et son bloc « ce que cet article ne garantit
> PAS » est le premier endroit du projet où une **dette est inscrite dans le texte normatif lui-même**.

### 🟠 Deux résidus NON BLOQUANTS, nommés (ils sont **prescrits par l'AC**, donc pas des défauts d'exécution)

1. **L'article recopie 2 valeurs de configuration** : le cardinal « **quatre** contextes » et
   `"blocking": false`. Or le **même paragraphe** écrit « *La liste des contextes requis n'est pas
   recopiée ici : elle vit dans `factory.config.json` → `status_checks`, source unique* ». Le
   **cardinal d'une liste est une valeur dérivée de cette liste** : un 5ᵉ contexte requis rendrait
   l'article faux **sans qu'aucun mécanisme ne le signale** *(la dette « aucune détection de dérive »
   est déjà ouverte)*. ⚖️ **Ce n'est PAS un défaut d'exécution** : **AC-3 prescrit littéralement**
   d'écrire « *4 contextes sont requis, 3 viennent de `ci.yml`, 1 de `branch-naming.yml`* ». @Architect
   a fait ce qui lui était demandé. → **`/audit-methodo`** *(« un texte normatif ne devrait porter aucun
   cardinal de configuration »)*.
2. **ADR-001 §Écarts porte désormais une ligne périmée par construction, dans un document IMMUABLE** :
   « *Le corps de l'Art. 4 affirme **aujourd'hui** LE CONTRAIRE … la contradiction est **VIVE*** ».
   Elle **ne l'est plus**. ⚖️ **Acceptable** : la ligne porte son **échéance explicite** *(« jusqu'à la
   fusion suivante », destinataire « PR nº 2 de CETTE US »)*, ce qui est exactement la précaution que
   l'ADR s'impose ailleurs. **Mais l'extinction doit être consignée ailleurs** — et **F-3 montre qu'elle
   ne l'est pas**. Un ADR accepté ne s'édite pas : c'est le **SCB** qui doit porter l'extinction.

---

## 3. La contradiction ADR-001 ↔ Art. 4 est-elle ÉTEINTE ? — **OUI**

J'avais écrit qu'elle était **acceptable mais vive jusqu'à la PR nº 2**, et posé une réserve sur le
`🚀 OUI`. **Je lève cette réserve.** Les trois faussetés sont confrontées **une par une** :

| Point de contradiction | ADR-001 dit | Art. 4 disait (avant #18) | Art. 4 dit (après #18) | État |
|---|---|---|---|---|
| SAST | « **AUCUN SAST** n'existe » | SAST parmi les **gates bloquants** | « **Aucun gate SAST n'existe** … **Dette ouverte** » | ✅ **éteinte** |
| audit de dépendances | « **non bloquant**, mesure l'obsolescence, **pas** la vulnérabilité » | audit de dépendances **bloquant** | « **n'est PAS bloquant** … **aucun scan de CVE n'existe** » | ✅ **éteinte** |
| `coverage_ratchet` | « **PAS en vigueur**, absent de la config, exige **du code** » | seuil **en vigueur** | « **n'est PAS en vigueur** … **À activer par US-00.6** » | ✅ **éteinte** |
| `app.build` | gate réel, preuve de **repli** | **omis** | **nommé**, avec sa borne de repli | ✅ **comblée** |

⇒ **Aucune contradiction résiduelle entre les deux livrables.** Mieux : les deux textes se **renvoient
l'un à l'autre** *(l'Art. 4 pointe ADR-001, ADR-001 pointe la PR nº 2)*. **La réserve du 2ᵉ passage sur
le `🚀 OUI` est LEVÉE** ; ce qui reste à `/certify` est de nature **ledger** *(F-3)*, pas de fond.

---

## 4. La SEPTIÈME manifestation — **F-1**, prouvée par MUTATION

**Tu m'as demandé le contrôle qui compte le plus. Je l'ai trouvé, et il est dans l'outil.**

### F-1 — `verify.sh` §7 : le contrôle de MONOTONIE compare l'ancien motif **à lui-même**

- **Action effectuée** — j'ai injecté dans une **copie** de `sweep_transmissions.sh` **exactement la
  régression que ce contrôle a été ajouté pour voir** *(B-4 : perte des alternatives littérales
  `transmission US-00.5` et `US-00\.5 :`, celles-là mêmes que la version précédente avait perdues)*,
  puis rejoué le code de `verify.sh` §7 **verbatim** contre ce mutant.
- **Résultat attendu** — le contrôle nommé *« lignes de l'ANCIEN motif PERDUES par le nouveau
  (sur-ensemble strict) »* rapporte une **perte ≥ 1**, comme un contrôle de monotonie doit le faire.
- **Résultat obtenu** — il rapporte **`PERDUES=0`**. Un contrôle honnête, lisant réellement le motif du
  mutant, rapporte **`PERDUES=2`** et **nomme les deux lignes**. Et le test de recall **rapporte encore
  `8/8`** sur le même mutant : **aucune autre barrière ne voit la régression.**

**Cause racine, et c'est elle qui fait la classe** — la ligne qui calcule le côté « nouveau motif » est :

```sh
N=$(grep -nE "$(sed -n 's/^ASSIGNE="//p;…' reports/US-00.5/sweep_transmissions.sh >/dev/null 2>&1; echo "$ANCIEN")" …)
```

La **lecture de la source est redirigée vers `/dev/null`** et la valeur substituée est **`$ANCIEN`
lui-même** — un littéral **recopié à la main** quelques lignes plus haut. `comm -23 A N` est donc **vide
PAR CONSTRUCTION**, et « PERDUES » est une **CONSTANTE publiée comme une mesure**.

- **Preuve indépendante que la lecture est morte** : j'ai remplacé le chemin du fichier par un
  **chemin INEXISTANT**. La substitution rend **exactement la même chaîne**. Un contrôle dont le
  résultat ne change pas quand on lui retire son fichier d'entrée ne lit rien.

**Pourquoi c'est la 7ᵉ manifestation, et pas une coquille** — le script écrit, **19 lignes plus haut** :
« *⛔ LE MOTIF N'EST PAS RECOPIÉ ICI : il est LU dans `sweep_transmissions.sh`, sa source unique. […]
DEUX COPIES D'UNE RÈGLE DÉRIVENT* ». C'est **vrai** pour le test de recall *(§7, 1ʳᵉ moitié — celui-là
lit réellement)* et **faux** pour le contrôle de monotonie *(2ᵉ moitié)*. Signature **identique** à la
6ᵉ manifestation *(le défaut est dans l'INSTRUMENT)*, avec une aggravation : **il est né dans la
correction du finding B-4 que j'avais moi-même ouvert sur la tautologie des mutants.** Le remède à un
test tautologique est un test tautologique d'un cran plus haut.

⇒ **Le 2ᵉ conjonct du critère nº 21 (« ET 0 ligne perdue ») est INFALSIFIABLE.** Un vert non
falsifiable est interdit — c'est la règle que ce projet a adoptée de mon re-audit, et je l'applique
d'abord contre moi *(F-4)*, ensuite ici.

### F-2 — la source a bougé, les deux copies de contrôle sont restées

- **Action effectuée** — extraction de la liste des catégories **depuis l'article** *(jamais recopiée)*,
  puis confrontation avec la table de correspondance **arbitrée le 2026-07-31** *(critère nº 5)* et avec
  `verify.sh` §4.
- **Résultat attendu** — les deux décrivent l'article livré.
- **Résultat obtenu** — l'article nomme **mise en forme / lint / typage statique / tests / audit de
  dépendances**. La table de contrôle nomme **lint / typecheck / tests / audit_deps / SAST**. Donc :
  1. **3 catégories de l'article sont absentes de la table** *(« mise en forme », « typage statique »,
     « audit de dépendances » sous cette forme)* ;
  2. **2 catégories de la table ne sont plus nommées comme gates par l'article** — dont **`typecheck`,
     qui a 0 occurrence dans toute la Constitution** alors que l'arbitrage du critère nº 5 **est
     entièrement construit dessus** ;
  3. `verify.sh:63` affirme **« ⛔ « format » n'est PAS une catégorie de l'Art. 4 »** — l'article
     **nomme « mise en forme » en PREMIER**. L'instrument affirme le contraire du livrable, en
     commentaire **porteur** *(il justifie la table)*, et **exit 0** ;
  4. `verify.sh:74` publie **« SAST : ÉCHEC ATTENDU 1/2 »** — il n'y a plus d'échec attendu ;
  5. `verify.sh:76-79` publie **« `app.build` … ⇒ AC-3 prescrit de le NOMMER »** — **c'est fait**,
     l'article le nomme.
- **Conséquence sur le critère nº 5** : *« 1 seul échec attendu : SAST »* est devenu **improducible**.
  Exécuté fidèlement, il rend **0 échec**. Les deux issues sont celles que le critère nº 5 s'était
  lui-même interdites au 2ᵉ passage : *« rapporter vert = **faux vert**, rapporter rouge = **FAIL mal
  motivé** »*. **Il faut le réécrire, pas le réinterpréter.**

> ⚖️ **Qualification honnête** : le mouvement est un **PROGRÈS du texte**. Le défaut n'est pas d'avoir
> amélioré l'article — c'est d'avoir bougé la **source** le jour même où on **arbitrait** ses deux
> copies, **sans les mettre à jour**. C'est « corriger le défaut **et laisser le renvoi** », version
> miroir de B-8.

### F-3 — le SCB ne sait pas que le 2ᵉ livrable existe

- **Action effectuée** — lecture de la section `### [US-00.5]` du SCB et des cases de DoD, comparées à
  l'état réel de `main` *(`gh api …/pulls/18` : `merged: true`, `merged_at 2026-07-31T11:00:05Z`)*.
- **Résultat attendu** — le ledger de certification décrit l'US **livrée**.
- **Résultat obtenu** — la section se **termine** par : *« **Prochaine étape** : 3ᵉ passage QA. Ensuite
  **rebase** (T9) et **PR nº 2 DÉDIÉE** pour l'amendement de l'Art. 4 (T10 → T12) »*. Aucune mention
  de **`#18`**, ni de l'**incrément 1.1**, ni de **T10-T12**. Les cases **5, 6, 14, 15, 19, 23** portent
  encore leur motif d'attente *(« ⏳ **PR nº 2** — il n'y a pas encore d'amendement à approuver »)*.
  Le critère de clôture d'EPIC_00 est encore `- [ ]` avec « *état au **2026-07-30** (PR nº 1)* ».
  Et **la case 20 — « SCB mis à jour (toutes colonnes) » — est COCHÉE `[x]`.**
- **Aggravant, et c'est ce qui le rend bloquant plutôt que cosmétique** : `/certify` **lit le SCB**.
  Passer la QA ici enverrait en certification un ledger qui décrit **une US à un livrable**, et
  **`check_scb_compliance.py` rend exit 0** — il vérifie la **cohérence structurelle**, **pas** la
  **véracité**. C'est exactement le trou par lequel les faux verts de cette US sont passés.
- **Non bloquant mais à savoir** : `docs/trace/US-00.5/events.jsonl` ne porte **aucun événement** pour
  la livraison de l'amendement *(le dernier est `EVT_QA_FAILED`)*. `validate_trace --us US-00.5` rend
  **exit 0** — la machine à états ne l'exige pas. Je le **nomme** sans en faire un motif.

### F-4 — **MON** instrument : je tranche, et je le remplace

Tu m'as posé deux réserves. **Les deux sont justes. Voilà mes verdicts, par exécution.**

**(a) Mon code de sortie est inopérant — et c'est PIRE que ce que tu décris.**
- **Action effectuée** — rejoué la condition finale de `qa_detecteur_v2.sh:165` avec **TOUS les
  compteurs à leur valeur PASSANTE** *(`ECART=0 SANS_MARQUEUR=0 AUTO_OK=8 DES_VIDES=0 NB1_FAUX=0`)*.
- **Résultat attendu** — exit **0**.
- **Résultat obtenu** — `[: missing ']'` puis **exit 1**. La même condition **sans** le `\n` littéral
  rend **exit 0**. ⇒ **mon gate rend exit 1 INCONDITIONNELLEMENT.** Il ne « ne peut pas être vert » :
  il **ne distingue rien**, et son rouge d'aujourd'hui **ne porte aucune information**. Le critère
  nº 20, **tel que publié, est INATTEIGNABLE** — exactement le reproche que je faisais à mon v1, une
  couche plus haut. **Je l'assume sans atténuation.**

**(b) Ton diagnostic sur mon §D est exact : `NB-1-faux=2` est un ARTEFACT DE MON INSTRUMENT, pas un
défaut de ton corpus. TRANCHÉ.**
- **Action effectuée** — recherche du motif NB-1 **par texte** dans tout le corpus.
- **Résultat obtenu** — le motif est **INTACT** ; il a **BOUGÉ** : `conformite_ac.txt` **45 → 66**,
  SCB **638 → 644**. Les deux emplacements portent leur qualification *(« **c'est faux** »)*.
- **Verdict** : **artefact**. Et l'ironie que tu relèves est **exacte et entière** : mon sous-contrôle
  intitulé *« un numéro glisse en silence »* **codait des numéros de ligne**, et il a glissé **parce que
  @Architect a obéi à mon B-7**. Un instrument qui punit l'application de sa propre recommandation est
  un instrument à jeter. **Je le jette.**

**(c) Résidu de mon v2 que tu n'as pas relevé, et que je dois dire** : `VERIFIEES=0`. Mon détecteur
**ne vérifie plus rien** — puisque les rapports ne publient plus de commande. Son **`ECART=0` est donc
VRAI PAR VIDE**. Il établit que *les rapports ne chiffrent plus*, **pas** qu'un chiffre serait juste.
C'est un progrès réel, mais **ce n'est pas la même affirmation**, et la présenter comme un vert de fond
serait le 8ᵉ tour du même manège. *(La borne est désormais **imprimée par le script**.)*

**(d) Autre copie divergente, de ma main croisée avec la tienne** : le critère nº 20 du Story File
publie **4** conjoncts ; mon script en imprime et en implémente **5** *(il ajoute `NB-1-faux=0`)*.
Même classe. Résolu par le remplacement ci-dessous.

---

## 5. 🎯 CRITÈRE DE SORTIE — **ATTEIGNABLE et REJOUABLE**, publié comme un script

> ⛔ Tu as raison de me le rappeler : j'ai écrit qu'il ne fallait **pas** chercher une voie vers
> `ECART=0` sur mon v1. **Je ne réédite pas la faute** : le composite ci-dessous ne contient **aucune
> transcription de mesure**. Chaque valeur attendue est une **spécification** ; chaque valeur mesurée est
> **lue dans sa source** ; et **chaque contrôle bloquant porte son propre mutant** — s'il ne peut pas
> échouer, **il échoue**.

### `sh reports/US-00.5/qa_exit_v3.sh` → **exit 0**

**Il remplace `qa_detecteur_v2.sh` comme gate autoritaire (critère nº 20 + nº 21).** Contenu :

| § | Contrôle | Attendu | Mutant embarqué | État au 2026-07-31 |
|---|---|---|---|---|
| **A** | chiffres-résultats du corpus rejoués | `ECART=0` · `SANS_MARQUEUR=0` | 8 formes de chiffre-résultat | ✅ *(avec la borne « vrai par vide » imprimée)* |
| **B** | motif NB-1 **désigné par TEXTE** *(remplace §D)* | 0 occurrence non qualifiée | une occurrence nue doit être vue | ✅ |
| **C** | **monotonie HONNÊTE** : référence = jeu de **TEXTES** versionné (`monotonie_baseline.txt`), motif **lu** dans le sweep | 0 texte perdu | motif amputé → la perte **doit** être vue | ✅ *(mutant détecté)* + ❌ **diagnostic `verify.sh` §7** |
| **D** | catégories **lues dans l'Art. 4** ↔ table de correspondance | aucune catégorie absente, aucune périmée, aucune affirmation contredite | les 5 gates doivent exister | ❌ **×3** |
| **E** | **ledgers** : le 2ᵉ livrable est enregistré | SCB porte `#18`/`1.1` · la « prochaine étape » ne l'annonce plus · DoD à jour · attestation présente · EPIC_00 coché | — | ❌ **×6** |
| **F** | non-régression | `verify.sh`, `run_gates --all`, `check_scb_compliance`, `validate_trace` → 0 | — | ✅ |

### Les 4 actions qui font passer ce gate à `exit 0`

| # | Action | Où | Vérifiée par |
|---|---|---|---|
| **C-1** | **Réparer `verify.sh` §7** : le côté « nouveau motif » doit être **LU** dans `sweep_transmissions.sh` *(la substitution actuelle est `>/dev/null; echo "$ANCIEN"`)*, et `ANCIEN` doit cesser d'être un littéral recopié. **Puis prouver la réparation par le mutant** : amputer le motif du sweep dans une copie ⇒ la perte **doit** être rapportée ≥ 1 | `reports/US-00.5/verify.sh` §7 | `qa_exit_v3.sh` §C |
| **C-2** | **Réaligner la table des catégories sur l'article livré** : mettre `verify.sh` §4 **et** le critère de test nº 5 sur **mise en forme / lint / typage statique / tests / audit de dépendances** ; retirer le commentaire « *format n'est PAS une catégorie de l'Art. 4* » *(faux)* et l'« ÉCHEC ATTENDU » sur SAST *(sans objet)*. ⚠️ **Le nouvel attendu du critère nº 5 est `0 échec`, et c'est un PROGRÈS** — le dire, ne pas le maquiller | `verify.sh` §4 + Story File critère nº 5 | `qa_exit_v3.sh` §D |
| **C-3** | **Enregistrer le 2ᵉ livrable au SCB** : PR **#18**, incrément **1.0 → 1.1**, T10-T12 faites, **extinction de la contradiction ADR-001 ↔ Art. 4** *(l'ADR étant immuable, c'est ici que ça se consigne)*, et retirer la « prochaine étape » périmée. Puis **cocher 5, 6*, 19, 23** et mettre à jour le critère de clôture d'EPIC_00. *(**6\*** : sa formulation — « diff limité au bloc *Enforcement* » — **précède l'arbitrage A-1** qui a étendu l'amendement au **corps** ; la reformuler sur AC-4 **avant** de la cocher, sinon c'est une case cochée contre un énoncé faux)* | SCB · Story File DoD · `EPIC_00` | `qa_exit_v3.sh` §E |
| **C-4** | **Attestation humaine datée de l'amendement (DoD 14)** — **action HUMAINE, pas d'agent** : `reviewDecision` est vide et `reviews=0` côté API *(vérifié)*, donc **aucune barrière machine**. Méthode de **niveau 1**, assumée **déclarative**, comme la case 34 d'US-00.7. ⛔ **Aucun message d'agent ne vaut approbation** | SCB ou `reports/US-00.5/` | `qa_exit_v3.sh` §E |

⛔ **Ce que je NE demande PAS** : ni de toucher au **fond** des deux livrables *(ils sont bons)*, ni de
recopier un chiffre, ni de « rendre vert » mon `qa_detecteur_v2.sh` — **il est retiré comme gate**, à
conserver comme **trace datée** de la 7ᵉ manifestation *(le même traitement que tu as réservé à ton
`assertions_vives.sh`, et pour la même raison)*.

---

## 6. AC couverts / **AC ORPHELINS**

| AC | Critères exécutables | Couvert |
|---|---|---|
| **AC-1** ADR-001 publié | 1 · 2 · 3 · 15 *(+ `verify.sh` §1)* | ✅ |
| **AC-2** limitations dites | 4 *(+ `verify.sh` §2)* | ✅ |
| **AC-3** Art. 4 exact | 5 ⚠️ · 6 · 7 · 8 | ✅ *(nº 5 à réécrire)* |
| **AC-4** clause *Révision* | 9 · 10 · 11 · 12 | ✅ |
| **AC-5** aucune contradiction nouvelle | 13 · 14 · 15 · 21 ⚠️ | ✅ *(nº 21 à moitié infalsifiable)* |
| **AC-6** preuves + portée | 16 · 17 · 18 · 19 ⚠️ · 20 ⚠️ | ✅ *(nº 19 et 20 défectueux)* |

**Aucun AC entier n'est orphelin.** Restent **3 volets d'AC sans critère exécutable** — je les nomme,
et je ne les compte pas comme des faux verts puisque leur nature est documentaire :

1. 🟠 **ORPHELIN RÉEL — AC-1 « Erreur », 2ᵉ moitié** : « *toute affirmation qui ne peut pas être établie
   par lecture d'un fichier du dépôt est retirée ou marquée comme non vérifiée* ». **Aucun** des 21
   critères ne l'exerce. Elle a été tenue par la **revue documentaire** *(findings NB-3, NB-5, NB-8 du
   @CodeReviewer)*, ce qui est réel mais **n'est pas un critère rejouable**. → à porter en **US-00.8**
   avec la « lacune de la grille de test » déjà versée.
2. **AC-4 « Nominal », attestation humaine** : aucun critère ne la vérifie *(les nº 9-12 couvrent le
   périmètre du diff, la version, les autres articles — pas l'approbation)*. **Comblé par
   `qa_exit_v3.sh` §E**, faute de quoi la case 14 serait cochable sans artefact.
3. **AC-2/AC-3 « Limite »** *(« nommer ne lève pas », « un texte complet ne crée aucun enforcement »)* :
   **non testables par construction** — ce sont des énoncés de portée. Ils sont **écrits** dans les deux
   livrables, ce qui est le maximum atteignable.

> ⚖️ **Note d'honnêteté sur AC-6 « Erreur »** : cet orphelin avait été comblé au 2ᵉ passage par le
> critère nº 19 *(`verify.sh`)*. **F-1 le rouvre partiellement** : la clôture était **nominale**, un
> contrôle infalsifiable ne comblant rien. Elle redeviendra réelle avec **C-1**.

---

## 7. Edge cases testés — au-delà des cas passants

1. **Régression INJECTÉE dans le motif du sweep** *(perte de 2 alternatives littérales, celles-là mêmes
   que B-4 avait relevées)* → `verify.sh` §7 : **PERDUES=0** · contrôle honnête : **PERDUES=2** avec les
   lignes nommées · recall des 8 mutants : **8/8**. **Aucune barrière ne la voit.**
2. **Chemin de fichier INEXISTANT** substitué dans `verify.sh:150` → **résultat identique**. Preuve que
   la lecture est morte, indépendamment de tout raisonnement sur le code.
3. **Tous les compteurs de mon v2 forcés à leur valeur passante** → **exit 1** quand même
   *(`[: missing ']'`)*, et **exit 0** dès qu'on retire le `\n`. Isole la panne du code de sortie de la
   valeur des compteurs — sans quoi j'aurais pu croire que `NB-1-faux=2` expliquait le rouge.
4. **Emplacements figés de mon §D confrontés au texte réel** → 45→**66**, 638→**644**, contenu
   **intact**. Artefact isolé du défaut.
5. **`coverage_ratchet` : les DEUX occurrences lues, pas comptées** → la 2ᵉ est une mention
   **historique** du défaut corrigé. Un critère qui aurait compté « ≤ 1 occurrence » aurait rendu un
   **FAIL mal motivé**.
6. **Critère nº 5 exercé dans les DEUX sens** : article → gate *(5/5 couverts)* **et** gate → article
   *(`app.build` désormais **nommé**)*. Le raisonnement publié du critère nº 5 — « *le SEUL gate non
   couvert est `app.build`, et c'est celui qu'AC-3 prescrit de nommer* » — **a basculé** : sa prémisse
   est devenue sa conclusion.
7. **Diffs de PR recalculés depuis les PARENTS RÉELS des merges** et non depuis la branche courante.
   ⚠️ **Ce détour n'est pas du zèle** : `origin/main...HEAD` est **vide** maintenant que les deux PR sont
   fusionnées, donc **`verify.sh` §3 passe désormais À VIDE** *(« CONSTITUTION.md dans le diff = 0 »
   n'atteste plus rien)*. Le critère nº 9 n'est **vérifiable que sur `856c366...6d36d48`** — et il
   **PASSE** : **0 octet**.
8. **Occurrence NUE du motif NB-1** injectée *(mutant de mon §B)* → **détectée**.
9. **Provenance de la fusion** : `mergedBy = gitgdx`, `type != Bot`, `reviews = 0`, **4/4** contextes
   `SUCCESS` sur `0f4cf69`. ⚠️ **Et `is_bot` ne prouve rien** *(dette établie par US-00.7 : les agents
   opèrent avec le jeton de l'humain)* — je ne m'en sers **pas** comme preuve, seulement comme constat.
10. **Nom de branche de la PR nº 2** : `feat/US-00.5-amendement-art4` → conforme à
    `^feat/US-[0-9]+\.[0-9]+.*$`, donc `check-branch-name` a pu passer. La contrainte permanente du
    2026-07-28 est **tenue**.

---

## 8. Statut de la DoD — **je statue** *(demande nº 4)*

**Case 18 — `QA Status 🧪 PASS` : DÉCOCHÉE.** Motif : F-1 *(faux vert prouvé)*, F-2, F-3.
Critère de sortie : **`sh reports/US-00.5/qa_exit_v3.sh` → exit 0**.

Les **7** cases décochées, réexaminées une par une contre l'état réel de `main` :

| Case | Objet | Statut au 2026-07-31 |
|---|---|---|
| **5** | Art. 4 amendé : `branch-naming.yml` **et** `check-branch-name` nommés · 4 contextes désignés · renvoi `GIT_PROTECTION.md` · aucune liste dupliquée | ✅ **SATISFIABLE MAINTENANT** — les 4 sous-conditions sont **vérifiées par exécution**. Son motif d'attente *(« l'Art. 4 n'est pas amendé ici »)* est **périmé** |
| **6** | version `1.0 → 1.1` + date · diff **limité** | 🟠 **SATISFIABLE SUR LE FOND**, mais **reformuler d'abord** : sa lettre dit « *diff limité au bloc **Enforcement*** », or l'arbitrage **A-1** a **étendu** l'amendement au **corps** — et le diff livré touche le corps. AC-4 a été mis à jour, **cette case ne l'a pas été**. La cocher telle quelle = cocher contre un énoncé faux |
| **14** | **[HUMAIN]** approbation de l'amendement, attestation datée | ❌ **NON SATISFIABLE AUJOURD'HUI** — **aucune attestation** dans le SCB ni dans `reports/US-00.5/`, et `reviews=0` côté API. **Action humaine, pas d'agent** |
| **15** | **[HUMAIN]** fusion par l'humain, sans `--admin` | ✅ **SATISFIABLE** — `mergedBy = gitgdx`, **4/4** contextes verts *(donc `--admin` inutile)*. ⚠️ Avec sa borne **inchangée** : la provenance **n'est pas prouvable par machine** *(dette US-00.8)* ⇒ **niveau 1, déclaratif** |
| **18** | QA 🧪 PASS | ❌ **DÉCOCHÉE** — c'est ma décision, motivée ci-dessus |
| **19** | PROJECT_LOG, **dont la ligne dédiée à l'amendement** | ✅ **SATISFIABLE MAINTENANT** — la ligne dédiée **existe** *(entrée @Architect du 2026-07-31 : « AMENDEMENT CONSTITUTIONNEL — Art. 4, version 1.0 → 1.1 »)*. Le « 🟠 PARTIEL » est **périmé** |
| **23** | critère de clôture d'EPIC_00 coché **avec sa preuve** | ✅ **SATISFIABLE MAINTENANT** sur le fond *(les 2 livrables sont sur `main`)`*, mais **matériellement non fait** : la case d'`EPIC_00` est encore `- [ ]` et son texte dit « *état au **2026-07-30** (PR nº 1)* » |

⇒ **4 cases immédiatement levables (5, 15, 19, 23)**, **1 après reformulation (6)**, **1 réservée à
l'humain (14)**, **1 à moi (18)**. La DoD peut donc passer de **16/23** à **21/23** par les seules
actions **C-2/C-3**, sans toucher aux livrables. **Reste 14 (humain) et 18 (QA).**

---

## 9. Bornes de ce verdict — ce que je n'ai PAS prouvé

- **Aucune exhaustivité.** Le corpus fait des dizaines de milliers de mots ; j'ai exercé **21 critères**,
  ~40 commandes, et **cherché** une 7ᵉ manifestation. J'en ai trouvé **une** *(F-1)* et **deux dérives
  jointes** *(F-2, F-3)*. **Une 8ᵉ peut exister ailleurs** — l'absence de preuve n'est pas une preuve
  d'absence, et **aucun gate CI ne voit cette classe de défaut** *(B-9, déjà versé aux dettes)*.
- **Rien n'est prouvé sur la CI de la branche courante** : `feat/US-00.5-certif` n'a pas de PR ouverte.
  Les 4 contextes verts constatés sont ceux de **`0f4cf69`** *(PR #18)* et **`6d36d48`** *(PR #17)*.
- **Le fond des livrables est vérifié par LECTURE OUTILLÉE, jamais par exécution du produit** — l'US ne
  livre **aucun code**. Les 5 gates et la couverture attestent une **NON-RÉGRESSION**, **rien de plus**.
- **`gitleaks` a été exécuté LOCALEMENT** ; le gate CI est le même mais je n'ai pas rejoué le job.
- **`factory_sync.py --check` est DOCUMENTAIRE** *(il le dit lui-même)*. `--check-remote` exige des
  droits admin : **je ne l'ai pas exécuté**, l'état réel du dépôt n'est donc pas revérifié ici.
- **L'exactitude de l'Art. 4 est DATÉE et CONDITIONNELLE** : elle dépend de `factory.config.json` **et**
  de l'état réel du dépôt, dont **aucune détection automatique de dérive n'existe**. Un 5ᵉ contexte
  requis, ou un retour du dépôt **en privé**, la **rouvrirait** — l'article porte lui-même cette borne.
- **Mon `qa_exit_v3.sh` n'est pas au-dessus du soupçon.** Il porte des mutants sur §A/§B/§C ; **§D et §E
  n'en ont pas** *(ils comparent des textes lus des deux côtés, ce qui limite le risque de tautologie,
  mais ne l'annule pas)*. Il ne sera **jamais** exécuté par la CI. **C'est un instrument d'audit, pas un
  enforcement**, et je le dis avant qu'on me le reproche.

---

## 10. Ce que ce 3ᵉ passage confirme d'ACQUIS *(à ne pas re-litiger)*

- **B-1 → B-9 : traités.** Vérifié par exécution, pas par lecture des réponses.
- **B-2** — `assertions_vives.sh` est **retiré et désarmé** *(`exit 2`, en-tête expliquant la faute,
  non supprimé)*. **Le bon traitement**, et je l'applique désormais à mon propre v2.
- **B-3/B-4** — mes 8 mutants sont repris **verbatim** ; le recall **8/8 est RÉEL** *(mesuré, y compris
  contre un motif amputé)*. Seule la **moitié monotonie** est défaillante.
- **B-5** — le critère nº 20 **est** mon v2, **ni réécrit ni adouci**. Confirmé au diff.
- **B-7/B-8** — désignations par **texte** ; les **9** motifs de `protect_files.sh` corrigés au SCB
  *(c'est d'ailleurs cette correction qui a fait glisser mes numéros de ligne : la preuve que B-7 a été
  appliqué)*.
- **Les 3 causes structurelles** que tu as trouvées en corrigeant *(motif recopié / deux listes de
  verbes asymétriques / motif non sur-ensemble)* sont **réelles et réparées** — le motif **est** lu
  depuis sa source unique pour le **recall**. **F-1 montre que la 3ᵉ réparation n'a pas abouti**, pas
  qu'elle était feinte.
- **ADR-001** : 4 rubriques du template, en-tête complet, statut `Accepté`, rétroactivité **écrite**,
  incomplétude du registre **écrite**, 5 alternatives **avec leur raison**, 4 honnêtetés dures avec
  **conséquence + renvoi**, `0` ADR accepté édité, `0` texte barré.
- **Les 6 items du §Hors périmètre** sont **transmis nommément** ; les **3 écarts** portent leur
  **destinataire**.

---

## 11. Formulaire des échecs — « Action → Attendu → Obtenu »

| # | Action effectuée | Résultat attendu | Résultat obtenu |
|---|---|---|---|
| **É-1** *(F-1)* | Injecter dans une copie de `sweep_transmissions.sh` la perte des alternatives `transmission US-00.5` et `US-00\.5 :`, puis rejouer `verify.sh` §7 verbatim | perte rapportée **≥ 1** | **`PERDUES=0`** — le contrôle honnête rapporte **2** (lignes nommées) ; recall des 8 mutants **8/8** ⇒ **aucune barrière ne voit la régression** |
| **É-2** *(F-1)* | Remplacer le chemin de `sweep_transmissions.sh` par un **chemin inexistant** dans la substitution de `verify.sh:150` | chaîne **différente** *(ou erreur)* | **chaîne identique** — la lecture est **morte**, `N` vaut **`$ANCIEN`** |
| **É-3** *(F-2)* | `grep -n "typecheck" docs/governance/CONSTITUTION.md` | ≥ 1 *(le critère nº 5 arbitre `typecheck → app.analyze`)* | **0 occurrence** dans **toute** la Constitution |
| **É-4** *(F-2)* | Lire les catégories **dans l'article** et les confronter à `verify.sh` §4 | table alignée sur l'article | **3** catégories de l'article absentes de la table · **2** catégories périmées dans la table · `verify.sh:63` affirme « *format n'est PAS une catégorie de l'Art. 4* » alors que l'article **nomme « mise en forme » en premier** |
| **É-5** *(F-2)* | Exécuter le critère nº 5 tel que publié | **1 seul échec : `SAST`** | **0 échec** — `SAST` n'est plus une catégorie de gate. L'attendu est **improducible** |
| **É-6** *(F-3)* | Lire la fin de la section `### [US-00.5]` du SCB, `main` portant déjà la PR #18 | l'amendement **enregistré** | *« **Prochaine étape** : 3ᵉ passage QA. Ensuite **rebase** et **PR nº 2 DÉDIÉE** »* — **0** mention de `#18` ou de `1.1`, **DoD 20 cochée** |
| **É-7** *(F-3)* | Chercher une attestation humaine datée de l'amendement *(DoD 14)* dans SCB + `reports/US-00.5/` + API | **1** artefact daté | **0** — et `reviews=0` côté API ⇒ aucune barrière machine, **aucune trace déclarative** non plus |
| **É-8** *(F-3)* | `grep -E "^- \[x\] ADR-001 \(stack\) publié" docs/epics/EPIC_00-fondations.md` | coché | **décoché**, texte figé au « *état au 2026-07-30 (PR nº 1)* » |
| **É-9** *(F-4, MOI)* | Rejouer la condition finale de `qa_detecteur_v2.sh` avec **tous** les compteurs passants | exit **0** | `[: missing ']'` puis **exit 1** — inconditionnel. Sans le `\n` : **exit 0** |
| **É-10** *(F-4, MOI)* | Vérifier les 4 emplacements figés de mon §D | motif présent aux lignes codées | **déplacé** *(45→66, 638→644)*, **contenu intact** ⇒ **ARTEFACT** de mon instrument, **pas** un défaut du corpus |

---

## 12. Conclusion

**`🧪 FAILED` — 3ᵉ passage. DoD 18 décochée. Motif : F-1 (7ᵉ manifestation, faux vert prouvé par
mutation), F-2 (table de catégories dérivée après la PR #18), F-3 (le SCB ignore le 2ᵉ livrable).**

Et la phrase que je dois écrire **sans la retenir par prudence** :

> **Le produit d'US-00.5 est bon, et il est prêt.** ADR-001 est conforme. **L'Art. 4 amendé est exact
> sur chacune de ses affirmations, vérifiées à charge, une par une, par exécution.** La contradiction
> ADR-001 ↔ Art. 4 est **éteinte**, et **je lève la réserve** que j'avais posée sur le `🚀 OUI` à ce
> titre. **Il ne reste pas de travail de fond** : il reste **un contrôle à rendre falsifiable, deux
> copies à réaligner sur leur source, un ledger à mettre à jour et une signature humaine.**
> C'est **court, mécanique et rejouable** — et c'est **exactement** pour ne pas laisser une 8ᵉ
> manifestation entrer dans la Constitution que je ne le passe pas.

**Un mot sur la boucle, puisque c'est mon 3ᵉ `FAILED`** : je ne monte pas d'un cran en exigence. Ma
ligne est la **même** aux trois passages, et c'est celle que le projet a adoptée de mon re-audit :
**un vert non falsifiable est interdit.** F-1 est un vert non falsifiable, **démontré par mutation** —
je l'aurais laissé passer que la règle n'aurait plus de sens, y compris quand elle me visera.
Et **je l'ai d'abord appliquée contre moi** : mon propre gate est **retiré**, remplacé, et son résidu
tranché comme **artefact**.

---
*@QA_Tester — 2026-07-31 · `claude-opus-5[1m]` · contexte frais*
*Source vive des valeurs : [`qa_exit_v3.sh`](qa_exit_v3.sh) · sortie brute :
[`qa_exit_v3_output.txt`](qa_exit_v3_output.txt) · référence de monotonie :
[`monotonie_baseline.txt`](monotonie_baseline.txt)*
*⛔ Je délivre `🧪 PASS`/`FAILED`. La certification `🚀 OUI` appartient au rituel `/certify` (@Architect).*
