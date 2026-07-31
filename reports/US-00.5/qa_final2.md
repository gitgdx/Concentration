# 🧪 QA — US-00.5 · **4ᵉ passage** · VERDICT `PASS`

> **@QA_Tester · contexte frais · 2026-07-31** — modèle réel `claude-opus-5[1m]`.
> Branche `feat/US-00.5-certif`, `HEAD` = **`1d19c1b`** *(`main` = `c62cdcc`)*.
> ⛔ N'écrase aucun rapport : [`qa.md`](qa.md) *(1ᵉʳ)* · [`qa_reaudit.md`](qa_reaudit.md) *(2ᵉ)* ·
> [`qa_final.md`](qa_final.md) *(3ᵉ)* sont **intacts**, y compris leurs `FAILED`.

---

# ✅ VERDICT : `🧪 PASS` — **DoD 18 COCHABLE. DoD 23/23.**

Je délivre le `🧪 PASS`. **La certification `🚀 OUI` appartient au rituel `/certify` (@Architect,
Art. 5)** — pas à moi.

**Et je le dis sans le retenir par prudence, parce que ce serait une autre forme de faute :** mon motif
bloquant du 3ᵉ passage était **F-1, un faux vert prouvé par mutation**. Il est **réparé, et je l'ai
vérifié par MA propre mutation, pas sur parole** : le contrôle de monotonie **rougit** maintenant sur la
régression injectée. Les deux autres griefs sont soldés. **Le produit était bon au 3ᵉ passage ; c'est
désormais l'appareil de preuve qui ne ment plus.**

---

## 0. La chose la plus importante de ce rapport : **le faux vert était le mien, et il portait sur la seule signature humaine**

@Architect me le transmet sans le maquiller. **Il a raison, et c'est pire que sa formulation.**

- **Action effectuée** — rejoué **ma** regex `§E` de `qa_exit_v3.sh` sur l'état `2407098` *(C-1 à C-3
  faits, attestation **non encore reçue**)*.
- **Résultat attendu** — `ECHEC` : `reviews = 0`, `reviewDecision` vide, **aucun fichier d'attestation**.
- **Résultat obtenu** — **`OK | une attestation humaine de l'amendement est consignee`.**

**Et voici la ligne que je dois écrire en entier.** J'ai isolé les fichiers responsables : ce sont
**`qa_final.md:323`, `:409`, `:477` — MON PROPRE RAPPORT**, précisément les lignes où j'écris
*« aucune attestation … `reviews=0` … action HUMAINE »*. **Preuve construite, deux corpus identiques
à un fichier près :**

| Corpus | Contenu | Ce que mon contrôle imprime |
|---|---|---|
| `t1` | SCB + rapports d'audit à `c62cdcc` | **`ECHEC`** *(aucune attestation — exact)* |
| `t2` | **le même**, + `qa_final.md`, **et rien d'autre** | **`OK`** *(attestation « consignée »)* |

> ⛔ **Le verdict d'une APPROBATION HUMAINE basculait de `ECHEC` à `OK` par le seul dépôt de MON RAPPORT,
> sans qu'aucun humain ne fasse quoi que ce soit.** C'est **exactement** le défaut que j'avais reproché
> au v1 de @Architect au 2ᵉ passage — *« son v1 a gagné un écart rien qu'en déposant ses deux
> fichiers »* — **retourné contre moi, en sens inverse : lui gagnait un rouge, moi un VERT.**
> Et il portait sur le **seul contrôle irremplaçable** du projet : le seul artefact normatif **sans
> prévention NI détection**. **Un gate qui valide une approbation humaine absente est pire que pas de
> gate.** C'est la **8ᵉ manifestation** de la classe, la **3ᵉ dans un instrument** — **et elle est de moi.**

✅ **Ce qui sauve cette US, et il faut le nommer** : **@Architect n'a pas consommé mon faux vert.** Il a
laissé la case **décochée**, **demandé** l'attestation à l'humain, et ne l'a cochée **qu'à réception**.
Le **process** a tenu là où l'**instrument** a menti. C'est la meilleure preuve produite par cette US —
et elle vaut plus que n'importe lequel de nos six outils.

### ⚖️ Statut de mon gate — **RETIRÉ** *(demande nº 2)*

`qa_exit_v3.sh` **cesse d'être un gate**, comme mon v1 et mon v2 avant lui. **Ni réparé, ni justifié :
retiré.** Je ne répare pas un instrument dont la panne porte sur la signature humaine — je l'aurais
« corrigé » par un mot-clé de plus, ce qui est la définition du 9ᵉ tour.
Il **reste au dossier, désarmé, en trace datée** *(le régime que @Architect a réservé à son
`assertions_vives.sh`, pour la même raison)*.

**Ce qui survit, et ce n'est pas rien** : ses **§A**, **§B** et la **logique de §C** *(monotonie par jeu
de TEXTES + mutant embarqué)* n'ont produit **aucun faux positif ni faux négatif**. Ce sont les
**seules parties qui portent un mutant**. **Tout ce qui reposait sur une correspondance de mots-clés a
failli — §D et §E, 7 fois sur 7.** Ce n'est pas une coïncidence, c'est **la mesure du §4 ci-dessous**.

---

## 1. Les 7 `ECHEC` de mon gate — **tranchés un par un** *(demande nº 1)*

**Verdict : 7 faux positifs sur 7. Aucun défaut réel derrière.** Chacun est établi par exécution, et je
donne la **cause** — jamais « c'est un faux positif » sans preuve.

| # | `ECHEC` rendu | Contrôle exécuté | Verdict |
|---|---|---|---|
| 1 | `verify.sh` §7 tautologique | **MUTATION RÉELLE** *(voir §2)* : la chaîne cherchée ne survit **qu'à la ligne 157, qui est un COMMENTAIRE** documentant la réparation | **FAUX POSITIF** |
| 2 | catégorie « audit de dépendances » absente de `verify.sh` | elle est **présente**, ligne 71 : `audit de dependances -> app.deps_audit` — **sans accent**. Mon `grep -qiF` cherchait la forme **accentuée** lue dans l'article | **FAUX POSITIF** — et la cause est une **fragilité lexicale DE MON INSTRUMENT**, pas un défaut du corpus |
| 3 | « typecheck » traité en catégorie | **2 occurrences, les DEUX en COMMENTAIRE** (L61-62), et elles disent : *« « lint et typecheck ne sont PAS touchés » — C'EST INEXACT »* — c'est **la correction de F-2 qui se documente** | **FAUX POSITIF** |
| 4 | « SAST » traité en catégorie | L47 = boucle des **4 honnêtetés d'ADR-001** *(usage différent, légitime)* ; L73-74-84 = **l'attendu RÉVISÉ** qui dit que SAST **ne figure plus** | **FAUX POSITIF** |
| 5 | SCB annonce encore la PR nº 2 | la « **Prochaine étape** » réelle est *« **C-4 (action humaine)**, puis **4ᵉ passage QA** »*. Mon unique match est **L304, la citation `PÉRIMÉ` qui documente F-3** | **FAUX POSITIF** |
| 6 | DoD 14 porte encore « pas encore d'amendement » | la case **est `- [x]`** ; la chaîne ne survit que sous un marqueur **`PÉRIMÉ-2026-07-31`** | **FAUX POSITIF** |
| 7 | DoD 5 porte encore « Art. 4 non amendé » | la case **est `- [x]`** ; idem, sous **`PÉRIMÉ-2026-07-31`** | **FAUX POSITIF** |
| 8 | critère de clôture EPIC_00 décoché | il **est `- [x]`** — ma regex exigeait le libellé **d'avant** (`ADR-001 (stack) publié et Constitution ajustée si besoin`) ; le libellé est désormais `**ADR-001 (stack) publié ET Constitution ajustée**` | **FAUX POSITIF** — **valeur attendue recopiée à la main dans mon propre contrôle.** Même classe, chez moi |

> ⚠️ **Note d'honnêteté sur le décompte** : mon gate imprime **7** lignes `ECHEC` ; elles portent **8**
> griefs *(deux sont agrégés sous « 2 catégorie(s) périmée(s) »)*. Je détaille les 8 pour ne pas
> masquer un grief derrière un compteur — c'est la faute que ce projet a payée cinq fois.

---

## 2. `C-1` — la réparation de F-1, vérifiée **PAR MUTATION**, pas sur parole

C'était mon motif bloquant. **Je ne l'accepte pas sur déclaration.**

- **Action effectuée** — j'ai **réinjecté dans `sweep_transmissions.sh` la régression exacte** de F-1
  *(amputation des alternatives littérales `transmission US-00.5` et `US-00\.5 :`)*, puis exécuté
  `sh reports/US-00.5/verify.sh`. *(Fichier **restauré** depuis git aussitôt après — `git status` propre.)*
- **Résultat attendu** — le contrôle **rougit**.
- **Résultat obtenu** :
  ```
  ECART  | lignes de l ANCIEN motif PERDUES par le COURANT (sur-ensemble strict)  attendu=0  obtenu=2
  OK     | autotest de monotonie   le mutant est VU (2 ligne(s)) => controle FALSIFIABLE
  RESULTAT : AU MOINS UN ECART
  ```
  **Le contrôle qui rendait `PERDUES=0` sur cette même régression rend maintenant `2`.** Il porte en
  outre son **propre autotest de falsifiabilité**.

**Cause racine réellement traitée** : `perdues() { comm -23 <(lignes "$1") <(lignes "$2") …; }` est
appelé avec **`$ASSIGNE`** — le motif **effectivement lu** dans le sweep — et non plus avec `$ANCIEN`.
La substitution morte *(`>/dev/null; echo "$ANCIEN"`)* a disparu du code et **ne subsiste qu'en
commentaire, pour mémoire de la faute**. ⇒ **F-1 est CLOS.**

## 3. `C-2`, `C-3`, `C-4` — vérifiés

| Action | Contrôle exécuté | État |
|---|---|---|
| **C-2** | `verify.sh` §4 **LIT** désormais les catégories dans l'article *(`CATS=$(sed -n '/^## Art\. 4/,…' CONSTITUTION.md …)`)* ; la table est réalignée sur `mise_en_forme / lint / typage_statique / tests / audit_deps` ; l'attendu du critère nº 5 est **révisé à `0 échec`**, avec le motif écrit *(« c'est un PROGRÈS, pas une régression »)* ; la fausse affirmation sur « format » est **retirée** | ✅ **CLOS** |
| **C-3** | SCB §`[US-00.5]` enregistre le 2ᵉ livrable · « Prochaine étape » à jour · **DoD 22 cochées / 1 décochée (la 18, la mienne)** · `EPIC_00` critère **`- [x]`** avec ses deux moitiés et leurs commits · ligne `PROJECT_LOG` dédiée présente | ✅ **CLOS** |
| **C-4** | `attestation_humaine_amendement.md` : **verbatim**, **datée**, **niveau 1 déclaratif**, et ses **4 non-preuves écrites dedans** — dont, en nº 4, **la dénonciation du faux `OK` de mon propre gate, refusé et non utilisé** | ✅ **CLOS** |

**Contrôle négatif, exécuté** : `git diff c62cdcc..HEAD` sur `docs/adr/`, `CONSTITUTION.md`,
`factory.config.json`, `.github/`, `lib/`, `test/` → **0 octet**. **Les livrables n'ont PAS été touchés**
pour faire passer la QA. C'est la vérification que je devais faire avant toute autre.

### Non-régression — exécutée, jamais déclarée *(CAPTURE DU 2026-07-31)*

`run_gates --all` → **exit 0** · tests **2 passed / 0 failed / 0 skipped** · couverture **89,5 % ≥ 80 %** ·
`gitleaks` → **0 fuite** · `check_scb_compliance` → **0** · `validate_trace --us US-00.5` → **0** ·
`factory_sync --check` → **0**. **21 scénarios Gherkin : 0 exécuté** *(0 step-def, 0 référence CI —
re-vérifié)* ⇒ ils ne sont **pas 21 skipped**, ils sont **non exécutables**, et leur nombre ne mesure
**aucune** couverture. Les 21 critères non-flutter **rejoués** : **aucune régression**.

---

## 4. La tension structurelle : **je la valide, et je la RENFORCE d'une mesure** *(demandes nº 3 et 4)*

@Architect soumet que **(A)** la convention *« marquer, dater, ne pas repeindre »* **conserve** le texte
fautif, et que **(B)** un gate par mots-clés **ne peut pas** distinguer une **assertion** d'une
**citation-dans-sa-réfutation** — d'où deux issues fausses : **exclure** ⇒ **blanchiment**, **ne pas
exclure** ⇒ **faux positifs**.

**Je confirme, et par exécution** : mes **§D** et **§E** sont **entièrement** lexicaux et rendent
**8 griefs, 8 faux**. Ses exclusions étaient lexicales et **blanchissaient**. Ce sont bien les **deux
seules** issues d'un contrôle lexical sur ce corpus.

### 🎯 Ce que j'ajoute, et qui est falsifiable — **la mesure sur les 6 instruments**

J'ai classé les six instruments de cette US selon **un seul axe** : *porte-t-il un mutant embarqué ?*

| Instrument | Mutant embarqué | Résultat réel |
|---|---|---|
| `qa_assertions_chiffrees.sh` *(moi, v1)* | ❌ | attendu = **transcription de mesure** ⇒ périmé, **retiré** |
| `assertions_vives.sh` *(@Architect)* | ❌ | exclusion lexicale ⇒ **BLANCHIMENT**, **retiré** |
| `verify.sh` §7 **recall** *(1ʳᵉ version)* | ❌ *(mutants tirés du motif testé)* | **tautologique**, recall réel **0/8** |
| `verify.sh` §7 **monotonie** *(2ᵉ version)* | ❌ | **tautologique** *(F-1)* — comparait l'ancien à lui-même |
| `qa_detecteur_v2.sh` *(moi, v2)* | ✅ *(§C)* **mais** exit code cassé + §D à numéros figés | vert **impossible**, résidu **artefact** |
| `qa_exit_v3.sh` *(moi, v3)* | ✅ **sur §A/§B/§C** · ❌ **sur §D/§E** | **§A/§B/§C : 0 faute** · **§D/§E : 8 faux sur 8** |
| **`verify.sh` §7 (3ᵉ version, aujourd'hui)** | ✅ **autotest de falsifiabilité** | **détecte la régression injectée : `obtenu=2`** |

> **Constat mesuré, et falsifiable** *(il suffirait d'un contre-exemple pour le casser)* :
> **dans cette US, 100 % des contrôles portant un mutant embarqué ont été justes, et 100 % des contrôles
> purement lexicaux ont été faux — dans les DEUX camps, six fois.**

⇒ **La voie de sortie n'est pas lexicale, et il ne faut pas en chercher une.** Elle est en deux points,
et **aucun des deux n'est un mot-clé de plus** :

1. **Contrôler l'ÉTAT STRUCTURÉ, jamais la PROSE.** Une case `- [x]`, une clé de `factory.config.json`,
   un champ d'API, un code de sortie : un `grep` ne peut pas les confondre avec un récit **parce qu'ils
   ne sont pas du récit**. Toutes mes assertions justes portent sur de l'état structuré *(diffs, exit
   codes, `status_checks`, `reviews`)* ; toutes mes fausses portaient sur de la **prose**.
   ⚠️ **Et la limite, dite d'avance** : `- [x]` **n'est pas** une preuve de véracité — c'est une
   **déclaration structurée**. Elle **déplace** le problème du lexique vers la **véracité**, elle ne le
   supprime pas. Ce qui la rend acceptable ici est que **j'ai vérifié la substance des 22 cases
   séparément**, par exécution.
2. **Aucun contrôle n'est admissible sans son mutant.** Non pas « il devrait en avoir un » : **s'il ne
   rougit pas sur un défaut injecté, il est déclaré NUL et retiré.** C'est la seule règle qui a
   discriminé, et elle a discriminé **7 fois sur 7** dans le tableau ci-dessus.
3. ⛔ **Et un corollaire que je dois écrire contre moi** : **un contrôle ne doit jamais scanner le
   répertoire où son propre rapport est déposé.** Mon §E s'auto-alimentait ; @Architect avait déjà
   rencontré la même boucle sur son sweep *(RB-1)*. **Deux instruments, deux camps, même boucle** ⇒
   ce n'est pas une inattention, c'est un **invariant de conception**.

⚖️ **Réponse directe à ta question nº 3 — « le produit est-il certifiable alors que l'appareil de preuve
porte une dette structurelle nommée ? »** **OUI**, et voici la ligne que j'applique, la même aux quatre
passages :

> **Je bloque sur un contrôle qui MENT** *(un vert qu'il ne peut pas justifier)*. **Je ne bloque jamais
> sur une ABSENCE de contrôle qui est NOMMÉE.** Une absence nommée est une **dette** ; un faux vert est
> un **mensonge**. Aux 3 premiers passages, l'appareil **mentait** — 7 assertions recopiées, puis un
> détecteur qui blanchissait, puis un contrôle infalsifiable. **Aujourd'hui il ne mente plus** : le seul
> faux vert restant **était le mien, et je le retire**. Ce qui subsiste — l'impossibilité d'un contrôle
> lexical fiable — est **nommé, documenté, versé à `/audit-methodo`, et explicitement NON IMPLÉMENTÉ**.
> C'est une dette. **Je ne fais pas payer au produit une dette que le corpus déclare.**

---

## 5. 🟠 Résidus **NON BLOQUANTS**, nommés — trouvés en cherchant une 9ᵉ manifestation

Je les livre **avec leur qualification**, et je **ne bloque sur aucun**.

1. **4 lignes d'attente PÉRIMÉES sous une case COCHÉE, sans marqueur** — `grep` exécuté sur les
   sous-lignes `⏳`/`🟠` suivant une case `- [x]` : cases **6** *(« ⏳ PR nº 2 — même motif »)*,
   **15** *(« ⏳ la fusion de la PR nº 1 t'appartient, celle de la PR nº 2 ensuite »)*,
   **19** *(« 🟠 PARTIEL … appartient à la PR nº 2 »)*, **23** *(« le critère est explicitement laissé
   décoché dans EPIC_00 »)*. Or les cases **5** et **14** ont **reçu** leur `PÉRIMÉ-2026-07-31` ⇒ ce
   n'est **pas un choix doctrinal, c'est une passe incomplète**, même classe.
   ⚖️ **Non bloquant, et voici pourquoi c'est un jugement et non une indulgence** : le risque est
   **l'inverse** d'un faux vert — la case dit *fait* **(vrai, vérifié par moi séparément)** et la
   sous-ligne dit *en attente* **(faux)**. Cela **crée de la confusion, jamais de la fausse assurance**.
   **Correctif : le même marqueur `PÉRIMÉ-2026-07-31` sur ces 4 lignes**, comme pour 5 et 14.
2. **`verify.sh` §4 LIT l'article mais ne le CONFRONTE pas** : `CATS` est **affiché** (`i "categories
   LUES"`) et **jamais comparé** à la liste `for pair in …`, qui reste **écrite à la main**. Un futur
   amendement de l'Art. 4 **désynchroniserait de nouveau en silence**. ⚖️ **Non bloquant, et je ne peux
   pas exiger mieux de bonne foi** : ce mécanisme de confrontation **était** mon §D, et **mon §D est
   faux sur un accent**. Je le **nomme** et je le verse à `/audit-methodo` **avec** la tension — c'est
   le même problème, et sa solution ne peut pas être lexicale.
3. **Case 14, contradiction interne bornée** : sous la case `- [x]`, une sous-ligne `PÉRIMÉ-2026-07-31`
   contient encore *« CETTE CASE RESTE DÉCOCHÉE, ET C'EST EXACT »*. ⚖️ **Acceptable** : elle est
   **précédée de son marqueur daté** — la convention est appliquée. C'est **l'illustration la plus nette
   de la tension (A)↔(B)** : le texte conservé **contredit littéralement** l'état courant, **et c'est
   la convention qui l'exige**. À verser telle quelle à `/audit-methodo` comme **cas d'école**.
4. **Ma propre dette d'instrument** : `qa_exit_v3.sh` retiré ⇒ les critères de test **nº 20 et nº 21**
   n'ont plus de gate autoritaire **de mon côté**. Ils sont couverts par **`verify.sh` §7**, qui est
   désormais le seul instrument **prouvé falsifiable** du dossier. **Je le dis plutôt que de laisser
   croire à une double barrière qui n'existe plus.**

---

## 6. Décomptes finaux et bornes

| Mesure | Valeur *(CAPTURE DU 2026-07-31, commande publiée)* |
|---|---|
| Critères de test | **21 exercés** · **21 PASSÉS** *(nº 5 sur son attendu **révisé** à 0 échec, motif écrit ; nº 19 sur `verify.sh` **falsifiable** ; nº 20/21 sur `verify.sh` §7, mon gate étant **retiré**)* |
| DoD | **22 cochées / 1 décochée** → **la 18 devient cochable** ⇒ **23/23** |
| Tests unitaires | **2 passed · 0 failed · 0 skipped** |
| Couverture | **89,5 % (17/19)** ≥ **80 %** — **NON-RÉGRESSION**, jamais le livrable *(0 fichier de code)* |
| Gates bloquants | **5/5**, `run_gates --all` exit **0** |
| Scénarios BDD | **21 · 0 exécuté · 0 passed · 0 failed** — **non exécutables** |
| AC | **6/6 couverts** · **1 orphelin exécutable maintenu** *(AC-1 « Erreur », 2ᵉ moitié → US-00.8)* |
| Manifestations de la classe | **8** — la **7ᵉ** *(F-1)* **CLOSE et prouvée close par mutation** ; la **8ᵉ est MIENNE** et son instrument est **retiré** |

### ⛔ Bornes de ce `PASS` — ce qu'il ne prouve PAS

- **Il ne prouve pas l'absence d'une 9ᵉ manifestation.** J'ai cherché, j'ai trouvé **4 résidus** que je
  qualifie **non bloquants** *(§5)* et **8 faux positifs de mon propre gate**. **Aucun gate CI ne voit
  cette classe de défaut** *(B-9, dette ouverte)* : rien n'a changé sur ce point.
- **Il ne prouve pas la véracité des 22 cases par la machine.** `- [x]` est une **déclaration**. J'ai
  vérifié leur **substance** par exécution *(diffs des PR sur les parents réels des merges, version lue,
  `status_checks`, `reviews`, `EPIC_00`)* — mais **une case cochée ne sera jamais une preuve**.
- **L'approbation humaine reste DÉCLARATIVE, niveau 1.** `reviews = 0`, `reviewDecision` vide,
  auto-approbation interdite, `is_bot` **ne prouve rien**. Le **critère 27 d'US-00.7 demeure NON LEVÉ** ;
  la levée réelle *(identité distincte + `restrictions`)* est **US-00.8**. **Mon `PASS` ne lève pas ce
  constat et ne prétend pas s'y substituer.**
- **L'exactitude de l'Art. 4 est DATÉE et CONDITIONNELLE** : un 5ᵉ contexte requis, ou un retour du
  dépôt **en privé**, la rouvrirait — **aucune détection automatique de dérive n'existe**.
- **Rien n'est prouvé sur la CI de `feat/US-00.5-certif`** *(pas de PR ouverte)*. Les contextes verts
  constatés sont ceux de **`6d36d48`** *(PR #17)* et **`0f4cf69`** *(PR #18)*, **4/4 SUCCESS**.
- **`gitleaks` et les gates ont tourné LOCALEMENT.** Je n'ai pas rejoué les jobs CI.
- **La voie de sortie du §4 est une PROPOSITION, non un acquis.** Elle doit être **éprouvée par mutation
  avant d'être crue** — c'est la position de @Architect, et je la contresigne : **nous avons produit six
  instruments et six fautes ; le septième ne mérite aucune confiance a priori.**

---

## 7. Ce que ce `PASS` certifie, et par quelle commande

| Affirmation | Commande qui l'établit |
|---|---|
| ADR-001 publié, `Accepté`, rubriques du template, ADR acceptés non édités, aucun texte barré | `ls` · `grep -c 'Accepté'` · `git diff --stat 856c366...6d36d48 -- ADR-005* ADR-006* ADR-007*` → **0** · `grep -rn '~~'` → **rc=1** |
| Les 4 honnêtetés dures nommées | `grep -ciE 'iOS\|Android\|deps_audit\|SAST'` → **15** |
| Art. 4 **exact** sur chacune de ses affirmations | `run_gates --gate sast` → *« aucun gate ne correspond »* · `factory.config.json` → `deps_audit.blocking = false` · `grep -n coverage_ratchet scripts/factory_sync.py` → lu **pour `frontend` seulement** · `status_checks` → **4 (3+1)** · `ci.yml` → `actionlint` épinglé **SHA256** dans le job **requis** |
| Clause *Révision* tenue **à la lettre** | `git diff --name-only 488b074...0f4cf69` → **2 fichiers** · version **LUE** → `1.1 2026-07-31` · `grep -cE '^[+-]## Art\. [^4]'` → **0** · `git diff 856c366...6d36d48 -- CONSTITUTION.md` → **0 octet** |
| Contradiction ADR-001 ↔ Art. 4 **éteinte** | confrontation ligne à ligne des 3 faussetés + l'omission — **4/4 levées** |
| **F-1 clos** | **mutation réelle** : régression réinjectée → `attendu=0 obtenu=2`, autotest *« mutant VU ⇒ FALSIFIABLE »* |
| Livrables non altérés pour faire passer la QA | `git diff c62cdcc..HEAD -- docs/adr/ CONSTITUTION.md factory.config.json .github/ lib/ test/` → **0 octet** |
| Non-régression | `run_gates --all` → **0** · `gitleaks` → **0 fuite** · `check_scb_compliance` → **0** · `validate_trace` → **0** |

---

## 8. Conclusion

**`🧪 PASS`. DoD 18 cochable ⇒ 23/23.**

J'ai rendu **trois `FAILED`** en écrivant chaque fois que le motif portait sur **les preuves et les
instruments, jamais sur le produit**. Cette phrase m'oblige aujourd'hui : **les trois motifs sont
soldés, et le dernier faux vert du dossier était le MIEN.** Le maintenir en FAIL aurait signifié faire
payer au produit une faute de mon instrument — c'est-à-dire **exactement la complaisance inversée**.

**Ce que je certifie** : le produit est exact, l'appareil de preuve **ne mente plus**, et sa faiblesse
résiduelle est **nommée, mesurée et versée** *(avec, en plus, un critère de discrimination falsifiable :
**mutant embarqué ⇔ contrôle juste, 7 fois sur 7, dans les deux camps**)*.

**Ce que je ne certifie pas** : ni l'absence d'une 9ᵉ manifestation, ni la véracité machine d'une case
cochée, ni une approbation humaine autrement que **déclarative**. Et **ce n'est pas moi qui prononce
`🚀 OUI`** : cela appartient à `/certify`.

> **Une dernière chose, pour l'auditeur à contexte frais qui lira ce dossier.** Cette US a produit
> **huit manifestations d'un même défaut, six instruments fautifs, quatre `FAILED` et un `PASS`** —
> **quatre fautes de chaque côté**. Le seul mécanisme qui ait discriminé, à chaque fois et dans les deux
> camps, est celui-ci : **injecter le défaut et vérifier que le contrôle rougit.** Si une seule chose
> doit survivre d'US-00.5 dans la méthode de cette factory, **c'est cela** — pas la Constitution 1.1,
> pas ADR-001. **Et la preuve la plus forte du dossier n'est pas outillée** : c'est qu'un agent, mis
> devant un `OK` qui l'autorisait à cocher une signature humaine absente, **a refusé de s'en servir**.

---
*@QA_Tester — 2026-07-31 · `claude-opus-5[1m]` · contexte frais · 4ᵉ passage*
*⛔ `qa_exit_v3.sh` est **RETIRÉ comme gate** *(trace datée, désarmé)*. Instrument de référence
survivant : [`verify.sh`](verify.sh) §7, **seul contrôle prouvé falsifiable** du dossier.*
*⛔ Je délivre `🧪 PASS`. La certification `🚀 OUI` appartient au rituel `/certify` (@Architect, Art. 5).*
