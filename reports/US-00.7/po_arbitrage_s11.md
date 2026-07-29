# Arbitrage @ProductOwner — **S11** (US-00.1) et volet **S1/S2** de la case 23 d'US-00.7

> **Agent** : @ProductOwner · **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-28
> **Saisine** : case **23** de la DoD d'US-00.7 — dernière case non technique ouverte, bloquante pour `/certify`.
> **Périmètre de ce document** : une **décision**, pas son application. Aucun artefact n'est édité par
> cet arbitrage : ni US-00.1, ni le SCB, ni le Story File d'US-00.7, ni `BACKLOG.md`, ni le code.
> **Méthode** : rien n'est repris sur la foi de la saisine ni de `transmissions.md`. Chaque fait ci-dessous
> a été relu à la source. **Deux prémisses de la case 23 se sont révélées inexactes** (§1.3 et §2.2).

---

## ⚖️ DÉCISION EN TÊTE

| # | Question posée | Décision |
|---|---|---|
| **1** | Véhicule pour **S11** | **(a) requalification tracée — sur le fond ADOPTÉE, mais NI aujourd'hui, NI dans US-00.7.** Différée, conditionnée, forme imposée, portée par une **US de dette à créer (US-00.8)**. **(b) ré-ouverture de cycle : REFUSÉE sur le fond** — et pas seulement pour disproportion : **aucun AC d'US-00.1 n'est en cause** (§1.2) |
| **2** | Volet **S1/S2** (périmètre d'US-00.5 réduit) | **CONFIRMÉ**, avec **2 précisions** et **1 rectification** : le périmètre de `BACKLOG.md` n'a **jamais** contenu ces corrections — il n'y a donc **rien à réduire dans le backlog** (§2.2). Et US-00.5 **gagne** un petit item (§2.4) |
| **3** | Case 23 cochable en l'état ? | **NON.** Non pas faute d'arbitrage — je le rends ici — mais parce que **le texte de la case affirme un fait qui n'existe pas** (« preuve fournie par AC-4 »). Deux conditions alternatives de déblocage en §3 |
| **4** | Conséquences backlog | US-00.5 : **charge éteinte**, note datée due · US-00.1 : **rien maintenant, certification NON rouverte** · **US-00.8** à créer via `/us-new` (§4) |

---

## 1. S11 — analyse

### 1.1 Ce que S11 vise exactement — trois emplacements, aucun n'est normatif

| Emplacement | Nature | Texte |
|---|---|---|
| `docs/stories/US-00.1-secrets-scan-depot.md:198` | **Tâche T8** — une *instruction*, case `- [ ]` **non cochée** (comme les 10 tâches du fichier) | « job `secrets-scan` **rouge** → merge **empêché par la protection de branche** » |
| `docs/stories/US-00.1-secrets-scan-depot.md:215` | **Critère de test #6**, colonne *« Résultat attendu »* | « Job `secrets-scan` rouge + merge **bloqué par la protection de branche** » |
| `tests/features/US-00.1-secrets-scan-depot.feature:54` | Étape `Alors` d'un scénario Gherkin **non automatisé** | « Et la fusion vers la branche principale est **empêchée par la protection de branche** » |

Aucun de ces trois textes n'est une **affirmation au présent sur l'état du dépôt**. Ce sont des **résultats
attendus d'un test** et une **consigne d'exécution**. La distinction n'est pas cosmétique : elle commande
le choix du véhicule (§1.2).

> **Note de contexte** : les 24 scénarios Gherkin du projet sont **documentaires** — `tests/` ne contient
> ni step definition ni runner BDD (établi par la QA d'US-00.7, finding **Q-3**). La ligne 54 n'est donc
> exécutée par rien ; elle est **lue**, pas jouée.

### 1.2 🔴 FAIT DÉCISIF — **aucun AC d'US-00.1 n'est en cause**, j'ai vérifié le texte de l'AC-3

C'est le point qui tranche le débat (a)/(b), et il n'apparaît nulle part dans la saisine.

**AC-3 d'US-00.1** (`docs/stories/US-00.1-secrets-scan-depot.md:85-94`), *in extenso* sur son volet Erreur :

> « **Erreur** : un commit contenant un **faux secret injecté volontairement** (test négatif) est
> **bloqué** par le hook `pre-commit` **et** fait échouer le job CI `secrets-scan` — preuve que le
> garde-fou n'est pas décoratif. »

**L'AC ne mentionne pas la protection de branche.** Il exige deux choses : le blocage au `pre-commit`
**et** l'échec du job CI. **Les deux ont été prouvées le 2026-07-25** (§1.3). Son volet *Limite* dit
« la CI reste le filet ultime avant fusion sur `main` » — formulation prudente, qui ne revendique
aucun mécanisme de blocage de plateforme.

**Trois conséquences, toutes fermes** :

1. **La certification d'US-00.1 est SAINE.** Elle n'a jamais reposé sur la protection de branche. Rien,
   dans ce dossier, ne justifie de la remettre en cause — ni totalement, ni partiellement.
2. **L'anti-pattern invoqué ne se déclenche pas.** La règle du projet vise la « **modification des AC**
   d'une US certifiée », qui rouvre le cycle d'audit. **Aucun AC ne sera modifié.** Une annotation
   **additive et datée**, laissant AC-1 → AC-4 intacts, ne rouvre donc **rien**.
3. **L'option (b) est sans objet, pas seulement disproportionnée.** Rouvrir un cycle d'audit suppose
   qu'il y ait quelque chose à ré-auditer. Il n'y a **aucun AC faux**, **aucun code en cause**, **aucun
   livrable invalidé**. Un cycle complet (3 audits + QA + `/certify`) pour aligner la colonne
   « résultat attendu » d'un tableau de test serait, en outre, un **précédent dangereux** : il
   poserait que toute évolution du monde extérieur rouvre les US certifiées qu'elle rend plus vraies.

### 1.3 🔴 RECTIFICATION — « le test négatif d'US-00.1 n'a JAMAIS été exécuté » est **FAUX**

`transmissions.md` l. 112 l'écrit, et **le Story File d'US-00.7 le reprend dans le texte même d'un AC**
(AC-5 limite, l. 290 : « *et le fait que son test négatif n'ait jamais été exécuté demeure vrai* »).
**Aucun des trois audits ni la QA ne l'a relevé.** Les sources disent le contraire :

| Source | Ce qu'elle établit |
|---|---|
| `reports/US-00.1/README.md:51-58` — « **T8 — test négatif CI (fait)** » | Faux secret `AQ.<token>` poussé sur branche jetable `feat/US-00.1-negtest-ci`, PR draft **#2** → job **`🔐 Secrets scan (gitleaks)` = `failure`** ([run 30155284206](https://github.com/gitgdx/Concentration/actions/runs/30155284206/job/89672154938), **2026-07-25**). Branche + PR supprimées, faux secret jamais fusionné |
| `reports/US-00.1/qa.md:38` | Critère **6** — « faux secret → CI rouge (AC-3) » — preuve : « run CI PR #2 `failure` (T8) » |
| `reports/US-00.1/security.md:118-119` | « Preuve test négatif CI : job `secrets-scan = failure` sur PR jetable #2 (run 30155284206) … **Crédible** » |

**Le test négatif a bien eu lieu et a bien produit un `secrets-scan` ROUGE réel.** Ce qui n'a jamais été
observé, c'est la **conséquence** de ce rouge sur une fusion — pour la raison évidente qu'aucune
protection n'existait alors.

**À décharge d'US-00.1** : son propre rapport écrit « → la CI **aurait** empêché la fusion » —
**au conditionnel**. Les *rapports* d'US-00.1 étaient honnêtes à leur date ; seuls le libellé de la
tâche, celui du critère et l'étape Gherkin étaient absolus.

**Portée de cette rectification** : elle **rétrécit** l'écart réel (la moitié « rouge » est acquise
depuis 2026-07-25, archivée, corroborée trois fois) **et** elle oblige à corriger deux documents
d'US-00.7 (§5).

### 1.4 L'affirmation est-elle **devenue vraie**, ou seulement **plus proche du vrai** ?

Décomposons le critère #6 en ses deux conjoints :

| | Conjoint | État au 2026-07-28 | Nature de la preuve |
|---|---|---|---|
| **(i)** | « job `secrets-scan` **rouge** » | ✅ **VRAI** | **par l'effet**, run 30155284206 du **2026-07-25** |
| **(ii)** | « → merge **bloqué par la protection de branche** » | 🟡 **VRAI PAR INFÉRENCE** | **par l'état de l'API** : `🔐 Secrets scan (gitleaks)` est l'**un des 4 contextes requis** (`protection_applied.json`, re-vérifié par la QA en contexte frais, `--check-remote` exit 0 réel) |

**Réponse : plus proche du vrai, pas encore vrai au sens où ce projet emploie ce mot depuis US-00.4.**

Le passage d'état est réel et massif — sur la PR #10 (2026-07-27, sans protection) `mergeStateStatus`
valait **`CLEAN`** avec des checks non verts : la PR était **fusionnable en rouge**. Sur la PR #12
(2026-07-28, protection appliquée) il vaut **`BLOCKED`**. Même dépôt, même compte, même commande.
Mais :

* **`BLOCKED` est un état calculé, pas une action refusée** — la QA a rendu **`🧪 FAIL`** sur ce motif
  exact (D-1) ; `merge_block.md` le déclare **en tête**, en gras, avant toute réussite ;
* la **conjonction littérale** du critère #6 — *`secrets-scan` **ROUGE** bloquant une **fusion*** —
  **n'a été observée dans aucun état du monde**, ni avant ni après l'application ;
* le refus qui sera capturé sur la PR de certification portera sur des contextes **`expected`**, pas
  **rouges** — il ne rendra donc pas la conjonction littérale observable non plus.

**La doctrine du projet n'interdit pas la preuve par l'état** : `allow_force_pushes: false` et
`allow_deletions: false` sont admis sur cette base, **explicitement étiquetés** « prouvés par l'état de
l'API, pas par l'effet ». La règle n'est pas « l'état ne prouve rien » ; elle est « **nomme la nature de
ta preuve** ». C'est cette règle qui gouverne la forme imposée en §1.6.

### 1.5 Pourquoi (a) est le bon véhicule — mais **pas aujourd'hui, et jamais dans US-00.7**

**Trois motifs, du plus contraignant au plus discutable.**

**Motif 1 — 🔴 Rédhibitoire et vérifiable : écrire dans US-00.1 depuis US-00.7 *casserait* la QA
d'US-00.7.** Le **critère de test 23** d'US-00.7 exige que `git diff --stat f4400ca..HEAD` sur
`docs/stories/US-00.1-*` soit **VIDE**. La QA l'a vérifié et l'a coté **✅ LEVÉ**. Toute édition
d'US-00.1 depuis cette branche **ferait passer un critère actuellement levé à NON LEVÉ**, ajoutant un
second motif de FAIL à une US qui n'en a plus qu'un. **La requalification ne peut donc pas être portée
par US-00.7, en aucune circonstance.** Cela règle la question du porteur : ce sera une **autre US**.

**Motif 2 — La prémisse de la case 23 n'existe pas.** Elle écrit « **preuve fournie par AC-4** ». **AC-4
nominal n'est pas prouvé** : aucun `gh pr merge` n'a été refusé, `merge_refusal_raw.txt` n'a jamais
été créé, critère **26 NON LEVÉ**, DoD case **13** ouverte, QA **`🧪 FAIL`**. Requalifier aujourd'hui
en s'appuyant sur AC-4 reviendrait à **fonder une décision de gouvernance sur une preuve inexistante**
— exactement le défaut fondateur qu'US-00.4 puis US-00.7 ont passé trois jours à éliminer, commis dans
la semaine même où la QA vient de le sanctionner. **Le coût de crédibilité serait hors de proportion
avec le bénéfice** (aligner trois libellés).

**Motif 3 — Le bon moment est gratuit.** D-1 doit être fermé de toute façon : c'est la case 13 et le
verdict QA. La PR de certification issue de `feat/US-00.7-certif` rouvre la fenêtre de ~80 s. **Attendre
ne coûte rien** et transforme une inférence en un pas d'inférence **borné et nommable**.

**Application de la Règle du Pourquoi** — quelle valeur chaque option crée-t-elle ?

| Option | Valeur créée | Coût | Verdict |
|---|---|---|---|
| **(b)** ré-ouverture du cycle d'US-00.1 | **Aucune** — il n'y a pas d'AC à ré-auditer | 3 audits + QA + `/certify`, + un précédent délétère | ⛔ **Refusée** |
| **(a) aujourd'hui** | Coche une case plus tôt | Casse le critère 23 d'US-00.7 ; grave une inférence comme un fait | ⛔ **Refusée en l'état** |
| **(a) différée et conditionnée** | Un corpus dont **chaque affirmation porte l'étiquette de sa preuve** | Une US de dette, mutualisée | ✅ **Retenue** |
| **Rejeu intégral de T8** (§1.7) | Preuve littérale complète | Faux secret poussé sur un dépôt **désormais PUBLIC** | 🟡 **Could / Won't for now** |

### 1.6 🔒 Forme imposée à la requalification — non négociable

1. **Purement additive.** ⛔ **Aucune ligne d'US-00.1 n'est supprimée, réécrite ou déplacée** — ni la
   tâche T8, ni le critère #6, ni l'étape Gherkin. Ce sont des **artefacts datés**.
   **Contrôle opposable** : `git diff -- docs/stories/US-00.1-*.md | grep -cE "^-[^-]"` → **doit rendre `0`**.
2. **Patron déjà validé par le projet** : l'encadré additif daté de `tests/fixtures/US-00.4/README.md`
   (**+27 / −0**), que la QA d'US-00.7 a expressément coté conforme au critère 23.
3. **Emplacement** : un encadré daté **en amont** des lignes 198 et 215 (démenti rencontré **avant**
   l'affirmation par un lecteur séquentiel) ; pour le `.feature`, un **commentaire Gherkin `#`**
   au-dessus du scénario — il ne modifie ni `Scénario`, ni `Alors`, et aucun runner ne le lit.
4. **⛔ Aucun AC touché.** AC-1 → AC-4 d'US-00.1 restent **au caractère près** ce qu'ils sont.
5. **Contenu obligatoire — quatre mentions, aucune facultative** :
   - (i) ce qui est prouvé **par l'effet** : le job `secrets-scan` **rouge** (run 30155284206, 2026-07-25)
     et le refus **de fusion** par le serveur sur contexte requis non vert *(à citer une fois D-1 fermé)* ;
   - (ii) ce qui est prouvé **par l'état de l'API seulement** : que `🔐 Secrets scan (gitleaks)` est
     l'un des **4 contextes requis** ;
   - (iii) ce qui **n'a jamais été observé** : la conjonction littérale « `secrets-scan` **rouge** →
     fusion refusée », **et qu'elle ne sera pas recherchée** (interdiction de casser un gate à dessein
     et de faire vivre un faux secret sur un dépôt public) ;
   - (iv) la **conditionnalité** : tout dépend de la visibilité **publique** du dépôt ; un retour en
     privé ramènerait le 403 et **rendrait l'annotation caduque**.
6. **Traçabilité** : événement, ligne PROJECT_LOG et mention **datée** dans le bloc SCB **de l'US
   porteuse**. ⛔ **Jamais** dans la trace d'US-00.1 (append-only, cycle clos) ; ⛔ **jamais** par
   réécriture de ses visas datés.

### 1.7 Sur l'obtention de la preuve littérale — **Could**, et je recommande **Won't for now**

Elle **est** obtenable, par un rejeu de T8 : faux secret sur branche jetable → PR → `secrets-scan`
**failure** → `gh pr merge` refusé, motif brut archivé → PR et branche détruites, jamais fusionnées.
Le patron est **déjà un précédent du projet** (2026-07-25) et ne casse **aucun** gate de `main`.

**Je ne le rends pas obligatoire, et voici pourquoi** :

* le dépôt est **PUBLIC depuis le 2026-07-27** — y pousser un faux secret laisse un commit atteignable
  publiquement ; le bénéfice ne vaut pas ce geste, et `gitleaks` est désormais une barrière critique ;
* le **gain probatoire marginal est faible** : GitHub bloque sur tout contexte requis **qui n'est pas
  `success`** ; `failure` et `expected` relèvent du même mécanisme. ⚠️ **Ceci est un raisonnement,
  pas une observation** — je l'étiquette comme tel, conformément à la doctrine que cet arbitrage
  applique par ailleurs ;
* la mention (iii) de §1.6 **dit** l'écart plutôt que de le combler : un corpus qui nomme sa lacune
  vaut mieux qu'un corpus qui la comble par un geste risqué.

**MoSCoW** : **Could**. À rouvrir seulement si un audit futur juge l'inférence insuffisante.

---

## 2. Volet **S1/S2** — vérifié, pas tenu pour acquis

### 2.1 ✅ S1 — `CLAUDE.md`, règle 2 : **CONFIRMÉ VRAI**, et c'est le plus solide des deux

Texte relu : « *jamais de commit/push sur la branche principale … **Enforced** : hooks Claude Code +
hooks git + **protection de branche*** ». La protection **existe** et le **serveur a refusé le push
direct** (`GH006`, depuis un clone sans hooks). **Preuve par l'EFFET**, pas par l'état. ✅ Correction
**sans objet**.

> **Précision, pour qu'US-00.5 ne la manque pas** : la règle 2 énumère **trois** interdits (`--no-verify`,
> push sur la principale, édition de fichier d'enforcement) pour **trois** mécanismes. La protection de
> branche n'adosse **que le deuxième**. La phrase reste exacte — c'est une ligne de synthèse, pas une
> matrice — mais elle ne doit pas être lue comme si la protection couvrait les trois.

### 2.2 ✅ S2 — `CONSTITUTION.md` Art. 4 : **CONFIRMÉ VRAI** — 🔴 mais la conclusion « périmètre d'US-00.5 réduit » est **imprécise**

Texte relu (l. 49-50) : « **Enforcement** : CI `ci.yml` jobs qualité, **requis par la protection de
branche** (`scripts/apply_branch_protection.sh`) ». Les trois jobs qualité de `ci.yml` **sont** requis,
et le `PUT` a bien été émis **par ce script**. ✅ Exact.

**🔴 Rectification** : j'ai lu `BACKLOG.md`. La ligne US-00.5 y porte, **et n'a jamais porté que** :

> « **US-00.5 — ADR-001 stack + Constitution adaptée** — `docs/adr/ADR-001-*.md` documentant les choix
> de stack ; Constitution relue et ajustée si besoin »

**Aucune mention de S1, de S2 ni de la dette #6.** Aucun Story File US-00.5 n'existe (vérifié :
`docs/stories/US-00.5*` → aucun fichier — conforme, `/us-new` n'a pas été lancé). La charge S1/S2
vivait **exclusivement** dans `reports/US-00.4/enforcement_gap.md §6`, un rapport **daté et certifié**,
⛔ **à ne jamais réécrire**.

**Conséquence** : il n'y a **rien à retrancher du backlog** — l'inflation ne l'avait jamais atteint.
Ce qui s'éteint est une **charge transmise**, pas un périmètre inscrit. La formulation « périmètre
d'US-00.5 **réduit** » est donc **substantiellement juste et formellement inexacte** : elle laisserait
croire qu'une ligne du backlog rétrécit.

### 2.3 ✅ Dette #6 (`GIT_PROTECTION.md`, en-tête généré) : **CONFIRMÉE sans objet**

Elle exigeait d'éditer `scripts/factory_sync.py` (**Art. 6**, action humaine) pour reformuler un
en-tête « Status check requis » alors trompeur. L'en-tête est **devenu exact**. L'action humaine
**n'a plus lieu d'être**. ✅ Une dette se ferme sans une ligne de code — parce que le monde a changé,
non par mérite.

### 2.4 ⚠️ Ce que la transmission ne dit pas : US-00.5 **gagne** un item

Art. 4 nomme « CI `ci.yml` jobs qualité ». **3 des 4** contextes requis viennent de `ci.yml` ; le
quatrième, **`check-branch-name`**, vient de **`branch-naming.yml`**. Cela **ne falsifie pas** l'article
(il ne revendique aucune exclusivité), mais la relecture de Constitution — remit légitime d'US-00.5 —
devrait envisager de mentionner `branch-naming.yml`. **MoSCoW : Should**, non bloquant.

### 2.5 ⚠️ Conditionnalité — la réduction est **datée**, pas définitive

Si le dépôt repassait en **privé** : 403, protection indisponible, **S1 et S2 redeviendraient faux** et
leur correction redeviendrait **due**, la dérogation `EVT_WAIVER_GRANTED` **rouvrirait**, et
l'annotation d'US-00.1 (§1.6) deviendrait **caduque**. À écrire dans la note de backlog.

**Verdict du volet S1/S2 : CONFIRMÉ.** ⛔ **Ne « corrigez » pas ces trois textes** — les toucher
rendrait faux un énoncé exact, le même défaut en sens inverse.

---

## 3. La case 23 peut-elle être cochée ?

### ❌ **NON en l'état** — et la raison n'est pas l'absence d'arbitrage

Texte de la case : « … **S11** (US-00.1 certifiée) **devenu vrai**, **preuve fournie par AC-4**,
véhicule à trancher par @PO, US-00.1 non éditée ».

Elle porte **deux** exigences et **une** affirmation :

| Élément | État |
|---|---|
| S1/S2 nommés, non corrigés en silence | ✅ **satisfait** (§2) |
| S11 nommé, US-00.1 **non éditée** | ✅ **satisfait** — `git diff` sur `docs/stories/US-00.1-*` **vide** (critère 23) |
| **Véhicule tranché par @PO** | ✅ **satisfait par le présent document** |
| **« S11 devenu vrai, preuve fournie par AC-4 »** | ❌ **FAUX** — AC-4 nominal non prouvé (D-1, critère 26, QA `🧪 FAIL`) |

**Cocher une case dont le libellé contient une affirmation fausse serait précisément l'anti-pattern que
cette US existe pour éliminer.** Je refuse de le couvrir.

### ✅ Conditions de déblocage — **l'une OU l'autre suffit**

> **C-1 — fermer D-1** *(voie préférée, elle ne coûte rien de plus)*. Sur la PR de certification :
> `gh pr merge <n> --merge` **immédiatement après l'ouverture**, refus brut archivé dans
> `merge_refusal_raw.txt`, puis fusion après les 4 verts. Critère **26** levé, **AC-4 nominal prouvé**,
> case **13** cochable, QA repassable en **`🧪 PASS`**. « Preuve fournie par AC-4 » devient alors vrai
> **au sens borné** — la chaîne « contexte requis non vert → fusion refusée par le serveur » est prouvée
> **par l'effet**, et `🔐 Secrets scan (gitleaks)` **est** l'un de ces contextes.
>
> **C-2 — rectifier le libellé de la case** *(@Architect, si C-1 devait tarder)*. Ce n'est **pas** un
> affaiblissement : aligner un énoncé sur sa preuve **est** la doctrine de cette US. US-00.7 n'étant
> pas certifiée, son Story File se rectifie sans cérémonie. **Rédaction proposée** :
>
> > « **S11** (US-00.1 certifiée) : la moitié « `secrets-scan` **rouge** » était **déjà prouvée** (run
> > 30155284206, 2026-07-25) ; la moitié « **fusion bloquée** » est établie **par l'état de l'API** —
> > `🔐 Secrets scan (gitleaks)` est l'un des 4 contextes requis — **et non par l'effet** : la conjonction
> > littérale n'a jamais été observée. **Véhicule tranché par @PO** (`reports/US-00.7/po_arbitrage_s11.md`) :
> > **requalification tracée additive, différée, portée par US-00.8**. **US-00.1 non éditée.** »

⚠️ **Sans effet sur le calendrier de `/certify`** : les cases **13**, **29** et **31** restent ouvertes
de toute manière. La case 23 **n'est plus le chemin critique** — elle l'était faute d'arbitrage, elle
ne l'est plus.

---

## 4. Conséquences sur le backlog

| Élément | Décision | MoSCoW | Quand |
|---|---|---|---|
| **US-00.5** — *ADR-001 stack + Constitution adaptée* | **Périmètre inchangé au backlog** (§2.2). Note **datée** à ajouter à sa ligne : « *charge S1/S2 + dette #6 transmise par `reports/US-00.4/enforcement_gap.md §6` — **ÉTEINTE au 2026-07-28**, textes redevenus exacts. ⛔ Ne pas « corriger » `CLAUDE.md` règle 2 ni `CONSTITUTION.md` Art. 4. ⚠️ Rouvre si le dépôt repasse en privé.* » + item §2.4 | **Must** (US) · **Should** (item `branch-naming.yml`) | Note : prochaine intervention @PO. ⛔ Pas dans US-00.7 |
| **US-00.1** — *Secrets & scan de dépôt* | **Aucune modification maintenant.** **Certification NON rouverte** — aucun AC n'est en cause (§1.2). Annotation additive datée **plus tard**, via US-00.8, selon la forme §1.6 | **Should** | Après **C-1** *et* après clôture d'US-00.7 |
| **US-00.8** *(à créer — dette d'outillage et de véracité)* | Porte : **#10 `NB-1bis`** (complétude de la cible dans `_guard_mapping`) · **#11 `selftest` en CI** de `check_branch_protection.py` · **la requalification S11**. Mutualisation assumée : trois dettes, **un** cycle | **Should** | Après US-00.7. ⛔ **Création exclusivement par `/us-new`** — les Story Files rétroactifs sont interdits |
| **Rejeu intégral de T8** (preuve littérale) | **Non retenu** (§1.7) — dépôt public, gain marginal faible | **Could** | Sur demande d'un audit |
| **US-00.6**, **US-01.1** | **Aucun impact** de cet arbitrage | — | — |

**Ce que cet arbitrage ne fait pas** : il ne coche aucune case, ne modifie aucun ledger, n'édite aucun
Story File. Il **décide**.

---

## 5. Transmissions issues de cet arbitrage

| # | Destinataire | Objet | Nature |
|---|---|---|---|
| **A-1** | **@Architect** | 🔴 **`transmissions.md` l. 112** et **Story File US-00.7 AC-5 limite l. 290** affirment que le **test négatif d'US-00.1 n'a jamais été exécuté** : **c'est faux** (§1.3), trois artefacts d'US-00.1 le contredisent. **Non relevé par les 3 audits ni par la QA.** À rectifier — un texte d'AC ne peut pas porter un fait faux | **rectification due** |
| **A-2** | **@Architect** | Case 23 : appliquer **C-1** ou **C-2** (§3) | **décision de forme** |
| **A-3** | **@Architect / @DevOps** | ⛔ **Interdiction ferme** : ne pas éditer `docs/stories/US-00.1-*` ni `tests/features/US-00.1-*` depuis la branche d'US-00.7 — cela ferait tomber le **critère 23**, aujourd'hui levé | **garde-fou** |
| **A-4** | **@PO** *(moi, prochaine intervention)* | Note datée sur la ligne US-00.5 de `BACKLOG.md` + entrée US-00.7 | **édition @PO** |
| **A-5** | **`/audit-methodo`** | 🔴 **Nouvelle instance de la dette #12** : **aucun événement du catalogue ne couvre un arbitrage @PO** (§6). Une décision de gouvernance dont dépend une case de DoD n'a **aucune trace machine** | **dette structurelle** |
| **A-6** | **`/audit-methodo`** | Un **critère de test** peut être coté « levé » sur la foi d'**une moitié** de son énoncé (critère #6 d'US-00.1, 2026-07-25 : le rouge prouvé, le blocage jamais observé, aucune réserve consignée). **Défaut de méthode, pas de personne** — rien n'oblige à décomposer un critère conjonctif | **leçon de méthode** |

---

## 6. ⛔ Pourquoi aucun événement n'est émis pour cet arbitrage

Le catalogue (`scripts/events_catalog.json`, **25** événements + 4 alias dépréciés) **ne contient aucun
événement d'arbitrage, de décision produit ou de requalification**. Les candidats et leur rejet :

| Événement | Rejet |
|---|---|
| `EVT_STORY_READY` | **Accepté par la machine à états** (sa précondition `EVT_STORY_CREATED` est remplie) — et **c'est le danger**. Il affirmerait qu'US-00.7 est *prête pour validation technique* alors qu'elle est en `parallel_audit` après un **`🧪 FAIL`**. **Une trace append-only ne se pollue pas d'un fait faux pour satisfaire une consigne de format** |
| `EVT_DEV_BLOCKER` | Émetteur `developer` ; sémantique inverse (je **lève** un blocage) |
| `EVT_WORKFLOW_VIOLATION` | Aucune violation constatée |
| `EVT_WAIVER_GRANTED` | ⛔ **Humain uniquement** (Art. 5). Je ne rends **aucune dérogation** : je constate qu'une preuve manque et j'en tire les conséquences |

**Décision : aucun événement émis.** Traçabilité assurée par **ce document** + la **ligne PROJECT_LOG**
du 2026-07-28. Le manque est **consigné en A-5** — il illustre la dette #12 sous un angle neuf : le
système sait tracer du **code** et des **audits**, il ne sait tracer **aucune décision de valeur métier**.

---

*Arbitrage rendu par @ProductOwner (`claude-opus-5[1m]`), le 2026-07-28. Aucun artefact du dépôt n'a été
modifié par cet arbitrage, hormis la ligne PROJECT_LOG qui l'enregistre. Les deux rectifications de
§1.3 et §2.2 portent sur des documents **d'US-00.7**, pas sur des artefacts certifiés.*
