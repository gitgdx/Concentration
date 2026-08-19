# Audit de revue de code — **3ᵉ TOUR (delta 2)** — US-01.2 « Gestion des échéances (CRUD) »

> ⛔ **Ce fichier ne remplace NI [`code_review.md`](code_review.md) NI
> [`code_review_delta.md`](code_review_delta.md).** Les trois rapports restent lisibles côte à côte
> *(précédent d'US-01.1 : `*_delta2.md`, `qa_delta.md`)*. Le `PASSED` du 2026-08-11 portait sur
> `2d77778` ; il a été **périmé** par le 3ᵉ cycle de correctif *(application de **NB-6**)*.

| Champ | Valeur |
|---|---|
| **Verdict** | ✅ **PASSED** |
| **Visa de code porté sur** | **`28d9504`** *(dernier commit touchant `lib`/`test`/`scripts`/`pubspec*`)* |
| **HEAD audité** | **`b77e3cf`** — vérifié : `git diff --name-only 28d9504..b77e3cf -- lib test scripts pubspec.yaml pubspec.lock` rend **0 fichier** *(annexe A)* |
| **Delta examiné en priorité** | `git diff 2d77778..28d9504 -- lib test` — **5 fichiers, +718/−26** *(annexe A)* |
| **Revue portée** | tout le code de l'US, avec re-mesure des findings antérieurs |
| **Auditeur** | @CodeReviewer — contexte **frais**, n'a pas produit ce code, ⛔ n'a recyclé aucun rapport |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-08-17 |
| **Findings BLOQUANTS** | **0** |
| **Findings NON BLOQUANTS NOUVEAUX** | **4** — **NB-M** *(MEDIUM)* · **NB-N** *(MEDIUM)* · **NB-O** *(MEDIUM)* · **NB-P** *(LOW)* |
| **Findings antérieurs** | **5 FERMÉS et vérifiés par exécution** *(NB-D, NB-E, NB-F, NB-G de la sécurité · NB-J de la revue)* · **8 SUBSISTANTS**, **aucun aggravé** |
| **Mutants joués par l'auditeur** | **12 joués** — **10 TUÉS** · **1 SURVIVANT confirmé (M-E4)** · **1 NON REPRÉSENTABLE confirmé** *(échec de compilation)* · arbre restauré et **`git status --porcelain` VIDE après chacun** *(annexes F, G)* |
| **Isolation** | `git worktree` **détaché** dédié — ⛔ **aucune mutation dans l'arbre principal**, ⛔ aucune dans celui de l'audit sécurité *(annexe A)* |

> ⛔ **Aucun nombre et aucun emplacement ne sont écrits à la main ici.** Chaque chiffre est **lu dans
> une sortie collée en annexe** ; chaque emplacement est désigné **par son texte**. **Deux exceptions
> assumées et signalées** : les numéros de ligne de `lcov.info` *(annexe E)* et ceux de
> `echeance_document_repository.dart` cités en **NB-N** — ils **sont** la donnée mesurée.

---

## 0. Isolation — le remède au défaut nº 1 du 2ᵉ tour, et il a tenu

Le 2ᵉ tour a **observé** une contamination : deux audits mutants sur **un seul** arbre. Ce tour a
tourné dans un **worktree détaché**, et l'auditeur sécurité dans un **autre**.

```
$ git worktree list
…/Concentration                       b77e3cf [feat/US-01.2-design]     <- arbre PRINCIPAL, jamais mute
…/scratchpad/wt-rev                   b77e3cf (detached HEAD)           <- LE MIEN
…/scratchpad/wt-sec                   b77e3cf (detached HEAD)           <- audit SECURITE, jamais touche
```

**Toutes** mes exécutions *(gates, 12 mutants, 3 campagnes, 2 `checkout` de commits intermédiaires)*
ont eu lieu dans `wt-rev`. Après chaque mutant, `git status --porcelain` y a été **relevé et trouvé
vide** *(annexes F, G)*. À la clôture, l'arbre **principal** ne porte que ce rapport et la trace.

---

## 1. Verdict et son motif — les 5 critères bloquants, un par un

| Critère bloquant | Constat | Preuve |
|---|---|---|
| Erreur lint / typecheck sur le code de l'US | `dart format` : **`Formatted 59 files (0 changed)`** · `flutter analyze` : **`No issues found!`** | annexe B |
| Duplication manifeste | **Aucune, et le cycle en RETIRE une, mesurée** : la règle de nommage de la mise de côté vivait **en DEUX exemplaires** dans la boucle ; elle vit en **UN SEUL**, dans `destinationMiseDeCote`, **publique exprès** pour qu'un test **demande** le nom au lieu de le recopier — et le test le fait *(« ⛔ Le nom se DEMANDE au magasin : le recopier ici mesurerait ma copie »)*. La borne de la boucle vit dans **`essaisMiseDeCote`**, **lue** par le test *(« ⛔ Le NOMBRE se LIT dans `lib/` »)*. **Mutant M-ANTI-DÉRIVE joué** : un suffixe `-0` au premier rang **tombe** *(annexe G, M3 tue le test d'esquive ; le test relationnel épingle le couple rang 0 / rang 1)* | §2, §3 |
| Requête N+1 | **Sans objet mesuré** : aucune base relationnelle. Le magasin lit et écrit **le document entier**. ⚠️ **Le delta AJOUTE des accès disque, et je les ai comptés** : `lire()` passe de 1 `existsSync` + 1 `readAsString` à **1 `typeSync` + 1 `readAsString`** *(échange, pas ajout)* ; `mettreDeCote` fait **au plus `essaisMiseDeCote` `typeSync`** — **borné par une constante**, ⛔ pas par le contenu du disque. **Ce n'est pas un N+1** | §2③ |
| Code nouveau sans test | **Aucun.** **13 tests ajoutés, 0 retiré** *(lu dans le diff, annexe A)*, et **chacun des 5 sujets porte son mutant tueur** — **10 mutants tués par MOI**, ⛔ pas relus *(annexe G)*. ⚠️ **Une branche reste sans test défendeur et elle est NOMMÉE par le @Developer** : le survivant **M-E4**, que j'ai **rejoué et confirmé** *(annexe F)* | §4, §5 |
| AC non couvert par le code | **Aucun des 16 AC actifs** *(AC-9 vacant)*. **Mesuré, pas relu** : `git diff --name-only 2d77778..28d9504 -- test/e2e/ tests/features/` rend **0 fichier** ⇒ aucune assertion d'AC n'a bougé ; `check_gherkin_mapping.py` → **50 ↔ 50** et **13 ↔ 13** ; et **le contrôle anti-« bon titre, assertion absente » est VERT** : sur les **50** tests e2e d'US-01.2, **0 test a moins de 2 assertions** *(annexe D)* | §6, annexes C, D |

**Les 5 gates passent : `Tous les gates bloquants passent (5 exécutés)`** *(annexe B)*.
**Le critère d'entrée transféré par EPIC_00 reste satisfait** : `migration_roundtrip_criterion.py` →
`VERDICT|OK|`, **8 assertions vertes**, **exit 0** *(annexe C)*.

---

## 2. LE TEST DE `B-2` EST-IL VACUEUX ? — **NON, et je l'ai établi MOI-MÊME, par trois mesures**

Le piège était armé : **`NB-F`/`NB-G` ont été corrigés AVANT `B-2`** *(`e26d791` précède `e5d471e`)*,
or le déclencheur choisi pour `B-2` — **des répertoires sur tous les noms de destination** — **était**
le point aveugle de `NB-G`. Si le test ne mesurait quelque chose que **grâce** aux correctifs qui le
précèdent, il serait un artefact. @Architect a conclu qu'il ne l'est pas ; **je ne l'ai pas cru, je
l'ai rejoué**.

### ① Le test survit-il au retour de la boucle AVEUGLE ? — **OUI**

**Mutant `M3`** : la boucle anti-collision revient à `File(destination).existsSync()`
*(exactement `NB-G`)*.

```
[M3_NBG_boucle_aveugle (CONTROLE D'INDEPENDANCE du test B-2)]
  00:07 +92 -1: Some tests failed.
  TESTS EN ECHEC (1) :
    - document_store_test.dart: … 🔴 NB-G — un RÉPERTOIRE sur la destination prédite est ESQUIVÉ, ⛔ le `rename` ne part plus droit dessus
```

⇒ **un seul test rouge, et c'est celui de `NB-G`.** Le test **`🔴 B-2 sur le magasin de PRODUCTION`**
est **VERT** sous ce mutant. **Les deux régimes échouent bien pour des raisons différentes** : boucle
corrigée ⇒ elle **épuise sa borne et lève** ; boucle aveugle ⇒ le `rename` **part droit sur le
répertoire et lève**. ⇒ **le déclencheur ne DOIT rien au correctif de `NB-G`.**

### ② Le test survit-il au retour d'`existsSync` dans `lire()` ? — **OUI**

**Mutant `M4`** : `lire()` revient à `File.existsSync()` *(exactement `NB-F`)*.

```
[M4_NBF_lire_existsSync (CONTROLE D'INDEPENDANCE du test B-2)]
  00:05 +92 -1: Some tests failed.
  TESTS EN ECHEC (1) :
    - document_store_test.dart: … 🔴 NB-F — un RÉPERTOIRE portant le nom du document : lire() rend DocumentIllisible, ⛔ PAS DocumentAbsent (ce n’est pas `v0`)
```

⇒ **un seul test rouge, celui de `NB-F`.** Le test de `B-2` est **VERT** : et c'est **structurellement
juste**, puisqu'il pose au nom du document un **VRAI fichier d'octets non décodables**, pas un
répertoire — la voie `DocumentIllisible` y passe par `readAsString`, ⛔ **pas** par le test de type.
✅ **Ce même mutant confirme la précision d'honnêteté écrite par le @Developer en C7** : le test
*« occupant non-fichier »* **vu depuis le dépôt** reste **VERT** sous `M4` ⇒ c'est bien une
**CARACTÉRISATION**, ⛔ **pas un discriminant**, et le discriminant vit **au niveau du magasin**.
**Il l'écrit lui-même dans le Story File** — c'est vérifié, pas cru.

### ③ Le test peut-il passer SANS son déclencheur ? — **NON**

**Mutant `M10` (anti-vacuité)** : les obstacles ne sont pas posés.

```
[M10_ANTIVACUITE_test_B2_sans_obstacles]
  00:09 +92 -1: Some tests failed.
  TESTS EN ECHEC (1) :
    - echeance_document_repository_test.dart: … 🔴 B-2 sur le magasin de PRODUCTION — un `rename` qui ÉCHOUE POUR DE VRAI : l’écriture est refusée, puis elle REDEVIENT possible
```

⇒ **sans obstacle, le test ROUGIT.** Il mesure donc bien l'**effet de l'obstacle**, ⛔ pas une
propriété vraie quoi qu'il arrive.

### ④ Et il tue le défaut d'origine, dans les deux formes

```
[M1_B2_documentNeuf_inconditionnel (le DEFAUT d'origine)]      00:05 +90 -3
[M2_catch_rend_true (l'echec perdu)]                           00:06 +90 -3
  TESTS EN ECHEC (3, IDENTIQUES pour les deux mutants) :
    - 🔴 B-2 sur le magasin de PRODUCTION …
    - 🔴 B-2 — mise de côté IMPOSSIBLE : charger() rend, l’écriture est REFUSÉE, et le document illisible est INTACT OCTET POUR OCTET
    - 🔴 NB-J … une mise de côté qui lève un UnsupportedError (le cas du STUB) ne traverse PAS charger()
```

⚠️ **Écart apparent avec le Story File, expliqué et NON retenu comme finding** : C4 annonce
*« 2 tests rouges »* par mutant, j'en mesure **3**. **Ce n'est pas une contradiction** : le 3ᵉ test est
celui de **C7**, qui **n'existait pas au commit de C4** — la sortie de C4 est datée *« AU COMMIT DE
C4 »*, ce qui est **exactement la bonne convention** de ce projet.

**⑤ Un cinquième mutant referme la porte de derrière** : **`M7`**, un `return` **muet** à la borne de
la boucle au lieu du `throw`, rend **2 tests rouges** dont **le test de `B-2` sur le magasin de
production** ⇒ le commentaire *« ⛔ surtout jamais un `return` muet ici — ce serait exactement
`B-2` »* est **VRAI, et il est DÉFENDU par un test**, pas seulement écrit.

> 🔴 **Conclusion de ce paragraphe, et c'est la question centrale du tour** : **le test de `B-2` n'est
> pas vacué.** Il est **indépendant** des deux correctifs qui le précèdent *(mesuré dans les deux
> sens)*, il **rougit sans son déclencheur**, et il **tue le défaut d'origine sous ses deux formes**.

---

## 3. Les 5 non bloquants traités — **chacun vérifié par exécution, ⛔ aucun par relecture**

| # | Objet | Statut | Le mutant qui le prouve, et ce qu'il rend |
|---|---|---|---|
| **NB-D** *(sécurité)* | le commentaire qui **légitimait** l'avalement invoquait le **stub**, cas **inatteignable** | ✅ **FERMÉ** | Le motif écrit est désormais le **magasin fichier** *(rename refusé, occupant non-fichier, tous les noms pris)* — **et il est mesurable** : `M1`/`M2` prouvent que ce chemin est **atteint** et que son issue **change le comportement**. ⛔ Le `catch` **reste**, et son devoir n'est plus de **taire** mais de **CONVERTIR** — `M8` prouve que le rétrécir rouvrirait `B-1` |
| **NB-E** *(sécurité)* | un `rename` échoué laissait `echeances.json.tmp` **avec les données du pratiquant** | ✅ **FERMÉ** | **`M5`** *(aucun ménage)* → **1 rouge**, le test de `NB-E` · **`M6`** *(pas de `rethrow`)* → **1 rouge**, le même test. ⇒ **les deux moitiés** — *le provisoire disparaît* **et** *l'échec reste un échec* — sont **chacune** défendues. ✅ Le **CONTRÔLE** livré est le bon : l'obstacle d'AC-17 **SURVIT** et le blocage reste **RÉVERSIBLE** |
| **NB-F** *(sécurité)* | `File.existsSync()` confondait « aucun fichier » et « pas un fichier » | ✅ **FERMÉ** | **`M4`** → **1 rouge**, et le **CONTRÔLE NÉGATIF** est réel *(un VRAI fichier au même nom est **LU**, l'absence reste `v0`)* ⇒ ⛔ un magasin déclarant **tout** occupant illisible ne passerait pas |
| **NB-G** *(sécurité)* | la boucle anti-collision était **aveugle** à un occupant non-fichier | ✅ **FERMÉ** | **`M3`** → **1 rouge** *(esquive)* · **`M7`** → **2 rouges** *(la borne LÈVE)*. `followLinks: false` fait compter **un lien mort**. ⚠️ **Ce qui n'est PAS fermé, et le code le dit** : la **PRÉVISIBILITÉ** du nom reste ouverte *(`N-1`)* |
| **NB-J** *(ma grille, 2ᵉ tour)* | `charger()` promettait **« ⛔ NE LÈVE JAMAIS »** sans que rien ne le garantisse | ✅ **FERMÉ, et bien fermé** | La promesse absolue devient une **énumération** *(chaque classe a son test)* **plus une BORNE ÉPINGLÉE**. **`M9`** *(un `charger()` qui **avalerait** la violation de contrat)* → **1 rouge**, le test **`⛔ LA BORNE`** ⇒ ⛔ la borne n'est **pas** laissée à la relecture. **`M8`** *(`on Exception`)* → **1 rouge** ⇒ le `on Object` est **défendu**, et `B-1` ne peut pas revenir par cette porte |

✅ **La voie retenue pour `NB-J` est la même que pour `NB-A`** — *« la doc dit ce qui EST »* — et c'est
**cohérent avec le corpus** : ce projet a déjà tranché deux fois qu'**un contrat écrit qui n'est pas
garanti dérive**. ⚠️ **Un résidu de cette énumération est nommé en NB-P.**

---

## 4. Les affirmations du Story File (C4 → C7) — **LUES dans une sortie, jamais recopiées**

| Affirmation | Ma mesure | Verdict |
|---|---|---|
| **13 tests ajoutés** | `git diff 2d77778..28d9504 -- test \| grep -cE "^\+\s*(test\|testWidgets)\("` → **13** ; **0 supprimé** *(annexe A)* | ✅ **EXACTE** |
| **AUCUN dans `test/e2e`** | `git diff --name-only 2d77778..28d9504 -- test/e2e/ tests/features/` → **liste vide** | ✅ **EXACTE** |
| **50 ↔ 50 et 13 ↔ 13 intacts** | `check_gherkin_mapping.py` → **`EXIT=0`**, les 4 décomptes lus *(annexe C)* | ✅ **EXACTE** |
| **369 tests, 97,9 % (941/961)** | `run_gates --gate test` **dans mon worktree** → `+369: All tests passed!` · `Couverture de lignes : 97.9% (941/961)` *(annexe B)* | ✅ **EXACTE** |
| **cliquet à 95,2, `factory.config.json` non édité** | `git diff --name-only main...HEAD -- factory.config.json` → **0 fichier** ; valeur **LUE** : `{"value": 95.2, "date": "2026-08-02", "motif": "PR27"}` | ✅ **EXACTE** |
| 🔴 **« la correction d'un bloquant HIGH et ses 3 tests ont laissé la couverture EXACTEMENT identique — 940/960 avant ET après »** | **REJOUÉ SUR LES DEUX COMMITS** *(annexe F)* : `e26d791` → `+361`, **`97.9% (940/960)`** · `e5d471e` → `+364`, **`97.9% (940/960)`** | ✅ **EXACTE, et c'est le fait le plus important du cycle** |
| **1 SURVIVANT nommé `M-E4`** | **REJOUÉ** : `try` élargi à `writeAsString` ⇒ **`+93: All tests passed!`, `echecs : AUCUN`** *(annexe F)* | ✅ **SURVIT — caractérisation EXACTE** |
| **1 mutant NON REPRÉSENTABLE** | **REJOUÉ** : `on FileSystemException` dans le dépôt ⇒ **`Compilation failed`**. Vérifié : `grep "^import"` sur ce fichier ne rend **aucun `dart:io`** *(la seule occurrence du texte est un **commentaire**)* | ✅ **EXACTE** |
| **2 contrôles d'indépendance / 1 anti-vacuité rouge** | `M3` et `M4` **verts** sur le test de `B-2` ; `M10` **rouge** *(§2)* | ✅ **EXACTES** |
| ⚠️ **« 11 mutants joués … dont 8 TUÉS »** | **Somme des tâches du Story File** *(commande, annexe A)* : **2 + 4 + 2 + 2 = 10 TUÉS** | 🟠 **INEXACTE — voir NB-M** |

### Le survivant `M-E4` est-il correctement caractérisé, et sa borne honnête ? — **OUI**

Le Story File écrit : *« élargir le `try` pour couvrir aussi `writeAsString` laisse 51 tests verts,
parce que `File.delete` refuse un répertoire de toute façon ⇒ la différence est INOBSERVABLE, et la
portée étroite du `try` est un choix de conception que AUCUN test ne défend »*.

**Rejoué : le mutant SURVIT** *(93/93 verts sur `test/features/echeances/data/`)*. La **cause** écrite
est **vérifiable par lecture du chemin** : l'obstacle d'AC-17 est un **répertoire** au nom du
provisoire ⇒ `writeAsString` échoue **avant** le `try`, et si le `try` l'englobait, le `delete` porterait
sur un **répertoire**, que `File.delete` refuse ⇒ l'inner `catch` l'avale et le `rethrow` sort à
l'identique. **La caractérisation est exacte** ; ⛔ **elle est déclarée « inobservable », pas
« équivalente »** — nuance juste, puisqu'un `writeAsString` **partiellement écrit** puis échoué serait,
lui, effacé par la version élargie. **La borne « mesuré sous Windows seulement » est écrite.**

🎓 **Et l'acquis de méthode de C6 est réel** : un mutant a fait **RETIRER du code** *(une garde de type
**inatteignable**)* au lieu d'ajouter un test. ⛔ **C'est le bon sens de la leçon** — *une branche
qu'aucun mutant ne peut tuer est une fausse sécurité*, et ce projet en a déjà payé une *(NB-7)*.

---

## 5. Findings NOUVEAUX — **0 bloquant**

> Format : `[Fichier désigné par son texte] | [Problème] | [Correctif attendu]`

### 🟠 NB-M · non bloquant · **MEDIUM** · le décompte de mutants annoncé **contredit** le Story File, et il est **gelé dans une trace append-only**

`docs/trace/US-01.2/events.jsonl`, `EVT_CODE_READY` du 2026-08-11T20:06:18, et la ligne
`PROJECT_LOG.md` correspondante : *« **11 MUTANTS** joués DANS LES DEUX SENS : **8 TUÉS** … »*. |
**La somme des tâches C4 → C7 du Story File, lue par commande** *(annexe A)*, donne
**`2 + 4 + 2 + 2 = 10` tués** — et **≥ 15 joués** *(10 tués + 2 contrôles d'indépendance + 1
anti-vacuité + `M-E3` + `M-E4`)*. **L'arithmétique de l'écart est reconstituable** : `2 + 4 + 2 = 8`
**omet les 2 mutants de C7**. ⚠️ **C'est la classe de défaut nº 1 du projet** — *un nombre dérivé écrit
à la main à côté d'une commande, jamais relu dans sa sortie* — et elle frappe ici **le paragraphe même
qui revendique d'avoir relu son rationale**. 🔴 **Aggravant structurel** : la trace est
**append-only** ⇒ **cette ligne ne peut pas être corrigée**, exactement comme le mot amputé du 2ᵉ tour. |
⚖️ **Pourquoi NON BLOQUANT** : l'écart **SOUS-ESTIME** *(10 tués annoncés 8)*, il ne gonfle rien ; il
ne porte **ni sur le code, ni sur une couverture d'AC** ; et j'ai **rejoué la campagne moi-même**, donc
le fait établi ne dépend pas du chiffre. |
**Correctif attendu** *(⛔ pas une réécriture de la trace)* : inscrire le **rectificatif daté** dans le
Story File, et porter à `/audit-methodo` la seule vraie sortie — **un décompte de mutants doit être
produit par le script de campagne, jamais recopié dans un `rationale`.**

### 🟠 NB-N · non bloquant · **MEDIUM** · `NB-I` est présenté comme « fermé par C4 » : **le DÉFAUT l'est, l'AVEUGLEMENT de l'instrument NON — et je l'ai MESURÉ**

Story File, en-tête des correctifs : *« `NB-I` est le **même mécanisme que `B-2`**, donc fermé par
**C4** »*. | **La phrase est vraie du défaut et fausse de l'instrument.** `NB-I` disait :
*« un `catch` au corps vide est **structurellement invisible** à la couverture »*. Le corps n'est plus
vide *(il porte `return false;`)*, ce qui **suggère** que la branche est redevenue visible. **Mesuré
dans `lcov.info` du commit audité** *(annexe E)* : sur `_tenterMiseDeCote` **(lignes 235 → 243)**, les
**seules** lignes instrumentées sont **`{235: 2, 237: 4}`** — ⛔ **ni le `return true` (238), ni le
`return false` (241) n'ont d'entrée `DA`**. ⇒ **aucune couverture, à aucun seuil, ne peut dire si la
branche d'échec est exercée** ; **97,9 % ne dit toujours RIEN de ce chemin**. |
**Correctif attendu** : **borner la phrase du Story File** *(« `C4` ferme le **défaut** que `NB-I`
dissimulait ; l'**angle mort de mesure** demeure et il est **re-mesuré** »)*, et verser la mesure au
dossier `/audit-methodo`. 🔬 **C'est la 7ᵉ instance de la thèse du projet, et la plus nette : ici la
couverture est aveugle non pas à la force des assertions, mais à l'EXISTENCE de la branche — même
après correction.**

### 🟠 NB-O · non bloquant · **MEDIUM** · **collision d'identifiants** : `NB-D`, `NB-E`, `NB-F`, `NB-G` désignent **DEUX choses différentes** selon le rapport, et le Story File coche **une seule** des deux séries

`docs/stories/US-01.2-gestion-echeances.md` §Correctifs post-audit, tâches **C5** *(« `NB-F` +
`NB-G` »)* et **C6** *(« `NB-E` »)*, contre `reports/US-01.2/code_review.md` §findings du 2026-08-07. |
**Les mêmes étiquettes portent deux jeux de findings** :

| Étiquette | Dans `security_delta.md` *(coché par C5/C6)* | Dans `code_review.md` *(1ᵉʳ tour — **TOUJOURS OUVERT**)* |
|---|---|---|
| `NB-D` | le commentaire qui légitime l'avalement | `generer_e2e.py` : chemin absolu d'un poste, pas de `--check` |
| `NB-E` | le `.tmp` rémanent | R-13 dévié dans les fixtures + fragilité de fuseau |
| `NB-F` | `File.existsSync()` confond les types | `refusEditionEchue` n'a qu'un point d'application, dans un widget |
| `NB-G` | la boucle anti-collision aveugle | une ligne non couverte non nommée *(bouton « Fermer »)* |

**Vérifié par exécution que les quatre de la revue SUBSISTENT** *(annexe C)* :
`RACINE = Path(r"c:/Users/guillaume.decroix/…")` toujours en dur · `refusEditionEchue` toujours **un
seul** appelant, `gestion_echeances_page.dart` · `lcov` : `gestion_echeances_page.dart`
**NON COUVERTES = [117]**, et **117** est bien `onPressed: () => Navigator.of(context).pop()`. 🔴 **Et
la liste « hors périmètre, non touchés » du Story File ne les nomme PAS** — elle nomme `NB-C`, `NB-H`,
`NB-I`, `NB-K`, `NB-L`. ⇒ **un lecteur d'audit conclura que `NB-D` → `NB-G` sont fermés. Ils le sont
pour la sécurité, ⛔ pas pour la revue.** |
**Correctif attendu** : **préfixer les identifiants par leur grille** *(`SEC-NB-F` / `REV-NB-F`)*, ou
au minimum inscrire dans le Story File la **table de correspondance** ci-dessus. ⚠️ **Même famille que
`NB-6`** : *le corpus ne modélise pas ce sur quoi un identifiant porte.* ➡️ `/audit-methodo`.

### ⚠️ NB-P · non bloquant · **LOW** · l'énumération de `charger()` nomme **une** classe de levée ; il en existe **deux autres**, sûres aujourd'hui et **non nommées**

`lib/features/echeances/data/echeance_document_repository.dart`, doc de `charger()` : *« ⛔ **CE QUI
N'EST PAS GARANTI** … elle **LÈVE** si le magasin **viole son contrat** en levant depuis
[DocumentStore.lire] »*. | **Deux autres sites peuvent lever depuis ce corps** :
**①** `codec.decoderDocument(migrer(racine)!)` — un `!` **séparé de ses gardes** par une vingtaine de
lignes ; **②** `_etapePour` = `etapesMigration.firstWhere((e) => e.version == version)` **sans
`orElse`** ⇒ `StateError` si une étape manquait pour une version déclarée. **✅ Les deux sont SÛRS
AUJOURD'HUI, et je l'ai vérifié dans le code, pas supposé** : au site d'appel, `version != null`,
`version ≤ versionCourante` et `cible = versionCourante` ⇒ **les trois gardes qui font rendre `null` à
`migrer` sont exclues**. ⚠️ **Mais l'énumération ne les mentionne pas**, alors que sa valeur entière
tient à ce qu'elle soit **complète pour ce qui est connu**. ✅ **Le Story File pose déjà le caveat
générique** *(« une énumération n'est pas une preuve d'exhaustivité »)* — **ce finding le rend
CONCRET** : ce ne sont pas des classes « non imaginées », ce sont **deux sites lisibles dans le même
corps**. |
**Correctif attendu** : ajouter à la borne *« … ou si l'invariant de version est rompu — `migrer` rend
`null`, ou aucune étape ne correspond à une version déclarée : ce sont des erreurs de PROGRAMMATION et
elles doivent sortir »*. ⛔ Ne pas ajouter de `catch` : ce serait **contredire** le motif que la même
doc défend.

---

## 6. Statut des non bloquants **NON traités** — chacun re-mesuré, ⛔ aucun supposé

| # | Objet | Statut | Comment je l'ai vérifié |
|---|---|---|---|
| **NB-C** *(revue, 1ᵉʳ tour)* | `check_e2e_persistance.py` : 2 angles morts | ⏳ **SUBSISTANT, ⛔ non aggravé** | `git diff --name-only 2d77778..28d9504 -- scripts/` → **0 fichier**. Le script **passe** et son **autotest de mutation** est vert *(8 sources, verdicts comparés **en ensembles**, annexe C)* |
| **NB-H** *(revue, 1ᵉʳ tour)* | 2 assertions tautologiques `textContaining('9')` | ⏳ **SUBSISTANT, ⛔ non aggravé** | `grep -rn "textContaining('9')" test/` → **toujours 2 occurrences dans l'e2e** *(+2 hors e2e)*, **aucune ajoutée** *(annexe C)* |
| **NB-K** *(revue, 2ᵉ tour)* | le motif écrit dans le stub est réfuté par la mesure | ⏳ **SUBSISTANT, ⛔ non aggravé** | `document_store_stub.dart` porte toujours *« « illisible » ferait tenter un `rename` qui lève »*. ⚠️ **Sa conséquence a CHANGÉ, pas sa fausseté** : avant, l'avalement laissait **écrire** ; désormais `_document` resterait **`null`** ⇒ écriture **refusée**. **Le motif reste faux, le danger a disparu** |
| **NB-L** *(revue, 2ᵉ tour)* | une exécution non déterministe observée **une fois** | ⏳ **SUBSISTANT — observation** | **Aucune instabilité observée sur ce tour** : **13 exécutions de la suite `data/`** *(1 base + 12 mutants)* + **4 exécutions de la suite complète** *(3 gates + 1 régénération lcov)*, **verdicts constants**. ⛔ **Cela ne réfute pas l'observation** — un test intermittent ne se réfute pas par des passages verts |
| **NB-D/E/F/G** *(revue, 1ᵉʳ tour)* | *(voir la table de **NB-O**)* | ⏳ **SUBSISTANTS, ⛔ non aggravés** | Mesurés un par un *(annexe C)* |
| **N-1, N-2, N-3, N-5 → N-10** *(sécurité)* | hors périmètre déclaré | ⏳ **hors de MA grille** | ⛔ Je ne les tranche pas ; **`N-1` est explicitement re-nommé dans le code** *(`followLinks`, prévisibilité du nom)* plutôt que tranché au passage — **c'est la bonne discipline** |

⚖️ **Report assumé au titre du GEL d'US-00.6** : dans un cycle de correctif, un non bloquant antérieur
non traité est **reporté, pas re-instruit**. ⛔ **Aucun des 8 n'est devenu bloquant, et aucun n'a été
aggravé** — vérifié un par un, ⛔ pas déduit de « le fichier n'a pas bougé ».

---

## 7. Couverture des 16 AC actifs — **et le contrôle anti-`B-2`-d'US-01.1**

**Aucun AC ne perd de couverture, et c'est mesuré** : le cycle **ne touche aucun fichier de
`test/e2e/**` ni de `tests/features/**`** *(annexe A)*, `check_gherkin_mapping.py` rend
**50 ↔ 50** et **13 ↔ 13**, et `check_e2e_persistance.py` rend **0 écart** sur ses **deux** contrôles.

🔴 **Le contrôle qui compte, celui de la classe « bon titre, assertion absente »** *(le bloquant `B-2`
d'US-01.1)* — **exécuté, ⛔ pas relu** *(annexe D)* :

```
== test/e2e/gestion_echeances_test.dart -- 50 tests
   tests avec MOINS DE 2 assertions : 0
```

⇒ **aucun des 50 scénarios d'US-01.2 n'est un titre nu.** *(Les 3 tests à une seule assertion relevés
dans `hub_echeances_test.dart` appartiennent à **US-01.1** et ne sont pas dans mon périmètre — je les
signale plutôt que de les taire.)*

**Les AC touchés par le cycle** :

| AC | Effet | Vérification |
|---|---|---|
| **AC-11** *(robustesse aux données illisibles)* | 🔴 **C'est l'AC du bloquant.** Sa clause « Erreur » — *« l'enregistrement fautif est **réécrit ou supprimé** »*, **la réfutation littérale de sa propre table** — était **produite** par le code. Elle ne l'est plus | `M1`, `M2`, `M7`, `M10` → §2 · assertions **sur les OCTETS** *(`harnais.octetsBruts() == fautif`)*, ⛔ pas sur l'écran |
| **AC-17** *(échec d'écriture)* | La branche « mise de côté échouée » **refuse d'écrire** avec le message du port, et l'état **s'auto-répare** | Le test de production **retire les obstacles** et exige que l'écriture **REDEVIENNE** possible ⇒ ⛔ le refus n'est pas un cul-de-sac déguisé en sûreté |
| **AC-12** *(migration)* | **inchangé et non régressé** | `migration_roundtrip_criterion.py` → **`VERDICT|OK|`, 8 assertions, exit 0** *(annexe C)* |
| **AC-1 → AC-8, AC-10, AC-13 → AC-16** | **aucun fichier de test touché** | annexe A |

**Les bornes `NM-*` sont-elles honnêtes ?** — **OUI, vérifié par le contrôle négatif** *(annexe D)* :
**`NM-9`** *(heure civile inexistante)* n'a **AUCUN scénario** dans le `.feature` — la seule occurrence
du sujet y est un **commentaire `#`**, et les tests unitaires **nomment la borne** au lieu de la
contourner ; **`NM-10`** *(web exécuté)* n'a **aucun test** qui prétendrait l'observer ;
**`NM-8`** *(`main()` non exécutable)* est **nommée dans les tests**. ⛔ **Aucune borne n'est déguisée
en test vert.**

---

## 8. Qualité du cycle — DRY, complexité, lisibilité

* ✅ **Le cycle RETIRE de la duplication** *(la règle de nommage : 2 exemplaires → 1)* **et retire du
  code mort** *(la garde de type inatteignable de C6)*. Les deux avec leur **motif écrit là où le choix
  vit**.
* ✅ **Les deux chemins du fichier CONVERGENT** : le traitement de la « version FUTURE » *(`_document`
  reste `null` ⇒ écriture refusée)* et celui de l'illisible non déplaçable font **désormais la même
  chose**. C'était **la** faiblesse de conception derrière `B-2` — deux dangers identiques traités
  différemment à vingt lignes d'écart. **Elle est fermée.**
* ✅ **Complexité maîtrisée** : `mettreDeCote` passe d'une boucle `while` **non bornée sur un état du
  disque qu'un tiers contrôle** à un `for` **borné par une constante nommée**, dont la sortie **lève**.
  `lire()` gagne **une** branche.
* ✅ **La portée des `try` est étroite et son motif est écrit** *(le `try` de `ecrire` n'entoure que le
  `rename`)*. ⚠️ C'est un choix **qu'aucun test ne défend** — et **le @Developer le dit lui-même**
  *(`M-E4`)*. **Nommer un survivant vaut mieux qu'un test qui ne mesure rien.**
* ⚠️ **Le ratio commentaire/code reste très élevé** *(≈ 96 lignes ajoutées à
  `echeance_document_repository.dart` pour **1 méthode** et 1 ternaire)*. ⛔ **Ce n'est pas un
  finding** : le corpus l'exige et ces commentaires sont **falsifiables**. ⚠️ **Sauf le résidu de
  NB-P**, et **NB-K**, qui reste faux.

---

## 9. ⛔ CE QUE CET AUDIT N'ATTESTE PAS

* ⛔ **Je n'ai vu AUCUN écran.** Mon verdict porte sur du code, des assertions, **12 mutants** et des
  sorties d'outils.
* ⛔ **`main()` n'a jamais été exécuté** *(borne **NM-8** : `path_provider` absent en test hôte)*. Le
  niveau réellement prouvé est **`charger()` sur le magasin `io` réel**. Que `runApp` s'exécute et que
  le hub se dresse **reste non observé**.
* ⛔ **TOUT est mesuré sous Windows, sur un seul système de fichiers, sous UN seul fuseau**
  *(le critère l'imprime : `offset_janvier=1:00:00`)* — or **les mécanismes d'échec du `rename`
  diffèrent sous POSIX**, et c'est précisément ce dont dépend la famille `B-2`/`NB-E`/`NB-G`.
  **La couverture de `M-E4` en particulier est bornée à `File.delete` refusant un répertoire sous
  Windows.**
* ⛔ **`check_gherkin_mapping.py` compare des TITRES — il l'imprime lui-même.** **50 ↔ 50 inchangé**
  signifie ici quelque chose de précis : **le cycle n'a ajouté aucun test e2e**, donc ce contrôle
  **n'a rien vu du correctif**. Ce qui a vu le correctif, ce sont **13 tests unitaires** et **mes 12
  mutants**.
* ⛔ **La couverture n'a rien vu non plus, et je l'ai MESURÉ deux fois** : `940/960` **avant et après**
  la correction du bloquant HIGH *(annexe F)*, et **la branche d'échec n'a toujours aucune ligne
  instrumentée** *(NB-N)*. ⇒ **la preuve de ce cycle repose ENTIÈREMENT sur les mutants.**
* ⛔ **Ma campagne n'est pas exhaustive.** **12 mutants** sur un code qui en admet beaucoup plus ; un
  mutant que je n'ai pas imaginé survivrait sans que ce rapport le sache. ⚠️ **Et mes mutants ont
  tourné sur `test/features/echeances/data/` (93 tests), pas sur la suite entière** — un effet
  collatéral hors de ce répertoire m'aurait échappé.
* ⛔ **Je n'ai PAS lu `reports/US-01.2/security_delta2.md`** *(s'il existe)* ni communiqué avec
  l'auditeur sécurité : **deux grilles, deux verdicts indépendants**. Mon `PASSED` **n'atteste rien sur
  la grille sécurité** — le précédent des deux tours est explicite là-dessus.
* ⛔ **Ma grille borne le blocage à** *lint/typecheck, duplication, N+1, code nouveau sans test, AC non
  couvert*. **NB-M**, **NB-N**, **NB-O** relèvent de la **méthode et des instruments**, ⛔ pas du
  produit — et je les classe hors de mon mandat **en les nommant**, ⛔ pas pour les enterrer.
* ⛔ **Aucun SAST, aucun scan de CVE** ; `deps_audit` mesure l'**obsolescence**.
* ⛔ **Le report des 8 non bloquants subsistants n'est pas une levée.** Il est **assumé** au titre du
  GEL et **daté**.
* ⚠️ **Une leçon du 2ᵉ tour que j'applique à moi-même** : *une sonde qui ne trouve pas ne prouve rien.*
  Là où je n'ai **pas** trouvé — l'instabilité de **NB-L** — j'écris **« non observé »**, ⛔ jamais
  « réfuté ».

---

## 10. Ce qui reste dû à d'autres rôles — ⛔ je ne le tranche pas

* La **hausse du cliquet** est signalée par le gate *(`[HAUSSE] 97.92% (941/961) > cliquet 95.2%` +
  `Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite`)*. ⚖️ **Le cliquet RESTE
  à 95,2 par arbitrage humain du 2026-08-07** : ⛔ je ne le re-litige pas et **je n'ai touché aucun
  fichier de configuration** *(`git diff --name-only main...HEAD -- factory.config.json` → 0 fichier)*.
* **NB-6 appliqué à mon propre visa** : il porte sur **`28d9504`** *(code)* et **`b77e3cf`** *(HEAD)*.
  ⛔ **Aucun champ `--commit` n'existe** dans `trace_append.py` ⇒ les deux SHA sont inscrits dans le
  `--rationale`, **convention non enforcée** qui réduit le risque sans le supprimer.
* **`NB-M`, `NB-N` et `NB-O` sont des candidats `/audit-methodo`**, et `NB-O` vise le **rituel
  `/audit-us` lui-même** *(collision d'identifiants entre deux grilles qui travaillent en parallèle —
  même famille que `NB-H` de la sécurité, l'arbre unique)*.

---

# Annexes — sorties BRUTES

## Annexe A — périmètre, isolation, décomptes

```
$ git log --oneline -8                                   (dans le worktree)
b77e3cf docs(us-01.2): peremption des visas apres le 2e cycle de correctif
e991749 chore(us-01.2): EVT_CODE_READY re-emis apres le 3e cycle de correctif
69844c2 docs(us-01.2): C4 a C7 — les 4 sujets du 2e tour, coches avec leurs mutants
28d9504 fix(echeances): NB-J — la doc de charger() dit ce qui EST, et dit sa borne
f42ec1a fix(echeances): NB-E — un rename echoue n abandonne plus les donnees en .tmp
e5d471e fix(echeances): B-2 — une mise de cote qui echoue REFUSE l ecriture
e26d791 fix(echeances): NB-F et NB-G — le TYPE de l occupant, pas son existence
89a0a42 docs(us-01.2): 2e tour d audit — revue PASSED, securite FAILED sur B-2

$ git diff --name-only 28d9504..b77e3cf -- lib test scripts pubspec.yaml pubspec.lock
(fin)                       <-- 0 FICHIER : le visa de code porte bien sur 28d9504

$ git diff --stat 2d77778..28d9504 -- lib test
 lib/features/echeances/data/document_store.dart          |  14 +-
 lib/features/echeances/data/document_store_io.dart       | 133 ++++++++-
 .../data/echeance_document_repository.dart               |  96 ++++++-
 .../echeances/data/document_store_test.dart              | 193 +++++++++++++
 .../data/echeance_document_repository_test.dart          | 308 +++++++++++++++++++++
 5 files changed, 718 insertions(+), 26 deletions(-)

$ git diff 2d77778..28d9504 -- test | grep -cE "^\+\s*(test|testWidgets)\("
13                          <-- 13 tests AJOUTES
$ git diff 2d77778..28d9504 -- test | grep -cE "^-\s*(test|testWidgets)\("
0                           <-- 0 test RETIRE

$ git diff --name-only 2d77778..28d9504 -- test/e2e/ tests/features/
(fin liste)                 <-- AUCUN e2e, AUCUN .feature : le couple 50<->50 est INTACT

$ git diff --name-only 2d77778..28d9504 -- scripts/ reports/US-01.2/generer_e2e.py
(fin)                       <-- 0 FICHIER : NB-C et NB-D(revue) non traites

$ git diff --name-only main...HEAD -- factory.config.json
(fin)                       <-- factory.config.json NON EDITE

$ python -c "... json.load('factory.config.json') ... coverage_ratchet"
{"value": 95.2, "date": "2026-08-02", "motif": "PR27"}      <-- valeur LUE, jamais recopiee

$ grep -oE '\*\*[0-9]+ mutants?( du correctif)?, [0-9]+ TUÉS?|\*\*[0-9]+ mutants? TUÉS\*\*' \
      docs/stories/US-01.2-gestion-echeances.md
**2 mutants du correctif, 2 TUÉS          (C4)
**4 mutants, 4 TUÉS                       (C5)
**2 mutants TUÉS**                        (C6)
**2 mutants TUÉS**                        (C7)
=> SOMME = 10 TUES  (la trace annonce 8 : NB-M)

$ git worktree list
…/Concentration      b77e3cf [feat/US-01.2-design]     <- PRINCIPAL, jamais mute
…/scratchpad/wt-rev  b77e3cf (detached HEAD)           <- LE MIEN
…/scratchpad/wt-sec  b77e3cf (detached HEAD)           <- audit SECURITE, jamais touche

$ git status --porcelain                 # arbre PRINCIPAL, avant ce rapport
(fin)                                    <-- VIDE
$ git status --porcelain                 # worktree wt-rev, apres les 12 mutants
(fin)  + git rev-parse HEAD -> b77e3cf…  <-- VIDE et revenu a b77e3cf
```

## Annexe B — `python scripts/run_gates.py --all` **dans mon worktree**

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 1.04 seconds.
✅ app.format
▶ app.analyze — (.) $ flutter analyze
Analyzing wt-rev...
No issues found! (ran in 30.0s)
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
01:51 +369: All tests passed!
Couverture de lignes : 97.9% (941/961) - seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigne le 2026-08-02 a PR27
  [HAUSSE] 97.92% (941/961) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.9
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
✅ app.test
▶ app.deps_audit — (.) $ dart pub outdated --show-all
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...                             43,6s
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

## Annexe C — contrôles de gouvernance, critère d'entrée, et re-mesure des subsistants

```
$ python scripts/check_gherkin_mapping.py
T12b -- correspondance scenario <-> test (racine : …/scratchpad/wt-rev)      <-- MON worktree
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
  tests/features/US-01.2-gestion-echeances.feature     50 scenarios
  test/e2e/gestion_echeances_test.dart                 50 tests
OK : chaque scenario a son test et chaque test son scenario. Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
EXIT=0

$ python scripts/check_gherkin_mapping.py --selftest
Autotest : 6 assertions, 0 echec(s), 2 couple(s) sous controle.
EXIT=0

$ python scripts/check_e2e_persistance.py
[OK ] controle « magasin » : 0 ecart(s)
[OK ] controle « racine » : 0 ecart(s)
CONFORME — les deux controles d'ADR-010 §1 passent.
EXIT=0

$ python scripts/check_e2e_persistance.py --selftest
   8 sources (1 conforme + 7 mutants COMPORTEMENTAUX)
   Verdicts compares en ENSEMBLES, jamais en cardinaux.
[OK ] M0_conforme … M7_pumpWidget_sans_argument_connu      (8/8)
Controles tues par au moins un mutant : ['magasin', 'racine']
AUTOTEST OK : les deux controles savent rougir, et sur les bons cas.
EXIT=0

$ python reports/US-01.2/migration_roundtrip_criterion.py
ASSERTION|A1_contrat_couple|OK|      ASSERTION|A5_cles_inconnues|OK|
ASSERTION|A2_montee_transforme|OK|   ASSERTION|A6_jamais_de_conversion_avec_perte|OK|
ASSERTION|A3_aller_retour|OK|        ASSERTION|A7_version_non_supportee|OK|
ASSERTION|A4_idempotence|OK|         ASSERTION|A8_forme_canonique_civile|OK|
VERDICT|OK|
SATISFAIT -- 8 assertions vertes. Le patron de MIGRATIONS.md section 4
est INSTANCIE ET EXECUTE sur le premier schema reel du projet.
EXIT=0

$ python scripts/validate_trace.py --us US-01.2   ->  Tracabilite conforme.  EXIT=0
$ python scripts/check_scb_compliance.py          ->  SCB conforme — Aucune violation detectee.
   (SCB : US-01.2 en `parallel_audit`, Audit Rev ⏳ et Audit Sec ⏳ — visas bien remis a l'attente)
   (trace : EVT_CODE_READY re-emis le 2026-08-11T20:06:18 => precondition d'EVT_CODE_REVIEW_* SATISFAITE)

--- RE-MESURE DES SUBSISTANTS (NB-O) ---
$ grep -n "RACINE" reports/US-01.2/generer_e2e.py
13:RACINE = Path(r"c:/Users/guillaume.decroix/MesProjets/Concentration")   <-- NB-D(revue) SUBSISTE

$ grep -rn "refusEditionEchue" lib/ --include=*.dart
lib/…/domain/validation_echeance.dart:86:  RefusValidation? refusEditionEchue(…)     <-- declaration
lib/…/presentation/gestion_echeances_page.dart:104: … refusEditionEchue(echeance)    <-- SEUL appelant
                                                     <-- NB-F(revue) SUBSISTE

$ grep -rn "textContaining('9')" test/ --include=*.dart
test/e2e/gestion_echeances_test.dart:489   test/e2e/gestion_echeances_test.dart:523
test/…/gestion_echeances_page_test.dart:208  test/…/formulaire_echeance_test.dart:241
                                                     <-- NB-H(revue) SUBSISTE, 2 en e2e

$ grep -n "rename" lib/features/echeances/data/document_store_stub.dart
26:  /// « illisible » ferait tenter un `rename` qui leve *(voir [mettreDeCote])*.
                                                     <-- NB-K SUBSISTE (motif faux)
```

## Annexe D — contrôle anti-« bon titre, assertion absente », et honnêteté des bornes `NM-*`

```
$ python <comptage des assertions par testWidgets, sur les fichiers e2e>
== test/e2e/gestion_echeances_test.dart -- 50 tests
   tests avec MOINS DE 2 assertions : 0            <-- AUCUN titre nu dans US-01.2
== test/e2e/hub_echeances_test.dart -- 13 tests
   tests avec MOINS DE 2 assertions : 3            <-- US-01.1, hors perimetre ; signale, pas tu
     [1] Le nombre affiche est l'arrondi superieur dans l'unite adaptative
     [1] Tri des tuiles par echeance croissante
     [1] Une echeance depassee remonte en tete de la grille

$ grep -niE "heure d'ét|02:30|heure inexistante" tests/features/US-01.2-gestion-echeances.feature
439:  # ⚠️ L'HEURE CIVILE INEXISTANTE du passage a l'heure d'ete (02:30 …)
   ^ ligne de COMMENTAIRE `#`, PAS un `Scénario:` => NM-9 n'est PAS deguisee en test vert

$ grep -rniE "NM-9|heure civile inexistante" test/features/echeances/domain/
date_civile_test.dart:6:      /// ⚠️ Ce fichier ne teste PAS une bascule d'heure d'ete — borne NM-9
validation_echeance_test.dart:313: // ⚠️ Le volet « heure civile inexistante » N'A PAS DE TEST : borne NM-9

$ grep -rn "NM-10" test/
(fin)                          <-- aucun test ne pretend observer le web execute

$ grep -rnoE "NM-[0-9]+" test/ | ... | sort | uniq -c
   1 NM-2    2 NM-6    2 NM-7    2 NM-8    3 NM-9      <-- bornes DECLAREES dans les tests
```

## Annexe E — couverture : l'ensemble des non-couvertes, et **la mesure de NB-N**

```
$ python <extraction depuis coverage/lcov.info, au commit AUDITE>
TOTAL LF=961 LH=941 -> non couvertes = 20
  lib\core\color\rgb.dart                                LF=  32 LH=  30 NON COUVERTES=[59, 60]
  lib\core\theme\concentration_theme.dart                LF=  12 LH=  11 NON COUVERTES=[23]
  lib\core\theme\concentration_tokens.dart               LF=  14 LH=  13 NON COUVERTES=[14]
  lib\features\echeances\data\document_store_stub.dart   LF=   7 LH=   6 NON COUVERTES=[42]
  lib\features\echeances\domain\remaining_time.dart      LF=  15 LH=   1 NON COUVERTES=[37,39,…,52]
  lib\…\presentation\gestion_echeances_page.dart         LF=  88 LH=  87 NON COUVERTES=[117]

  gestion_echeances_page.dart ligne 117 : onPressed: () => Navigator.of(context).pop(),
```

**Lecture** : **même ENSEMBLE qu'au 2ᵉ tour** *(comparaison d'**ensembles**, ⛔ pas de cardinaux)* ⇒
**`NB-G` de la revue subsiste à l'identique**, et **aucune ligne non couverte n'est apparue** malgré
**+718 lignes de diff**.

```
$ python <extraction des lignes INSTRUMENTEES de _tenterMiseDeCote>
_tenterMiseDeCote demarre ligne 235 ; corps :
   235:   Future<bool> _tenterMiseDeCote() async {
   236:     try {
   237:       await magasin.mettreDeCote();
   238:       return true;
   239:     } on Object {
   240:       // ⛔ Le document est TOUJOURS la. L'appelant doit REFUSER d'ecrire.
   241:       return false;
   242:     }
   243:   }
  DA instrumentees dans la zone : {235: 2, 237: 4}
```

🔴 **C'est la mesure de `NB-N`** : le corps du `catch` **n'est plus vide** *(il porte `return false;`)*
et **il n'a TOUJOURS aucune ligne instrumentée** — pas plus que le `return true`. ⇒ ⛔ **la couverture
ne peut toujours pas dire si la branche d'échec est exercée**, et elle ne le pourra pas.
**`NB-I` fermait un DÉFAUT, ⛔ pas un ANGLE MORT DE MESURE.**

## Annexe F — le SURVIVANT, le NON REPRÉSENTABLE, et la couverture **avant / après** le bloquant

```
########## M-E4 — REJEU DU SURVIVANT ANNONCE ##########
(mutant : le `try` de `ecrire` elargi pour couvrir aussi `writeAsString`)
ancre trouvee : 1
  00:04 +93: All tests passed!
  echecs : AUCUN -> LE MUTANT SURVIT
  restaure -> git status : ''

########## MUTANT NON REPRESENTABLE — `on FileSystemException` dans le DEPOT ##########
  ! Failed to load "…/test/features/echeances/…"
  ! Compilation failed for testPath=…
  ! Error: The Dart compiler exited unexpectedly.
  restaure -> git status : ''
$ grep -n "^import" lib/features/echeances/data/echeance_document_repository.dart
1: '../domain/echeance.dart'  2: '../domain/echeance_repository.dart'
3: 'document_store.dart'      4: 'echeance_document_codec.dart'
5: 'echeance_schema_migrations.dart'
$ grep -n "dart:io" lib/…/echeance_document_repository.dart
10:/// ⛔ **Aucun `dart:io` ici** : il ne connait du disque que le port    <-- COMMENTAIRE seul
=> `FileSystemException` n'est PAS dans la portee : le mutant est bien NON REPRESENTABLE

########## COUVERTURE : e26d791 (avant B-2) vs e5d471e (B-2) ##########
  [e26d791] AVANT le correctif B-2 (= apres C5)
     01:36 +361: All tests passed!
     Couverture de lignes : 97.9% (940/960) — seuil requis : 95.2% (cliquet)
  [e5d471e] APRES le correctif B-2 (= C4)
     01:36 +364: All tests passed!
     Couverture de lignes : 97.9% (940/960) — seuil requis : 95.2% (cliquet)

RETOUR : b77e3cf51e19b453a2500c69b6bc380181f3bcfc
git status : ''
```

🔴 **`940/960` AVANT, `940/960` APRÈS** — pour la correction d'un **bloquant HIGH** et **+3 tests**.
**Je l'ai rejoué moi-même sur les deux commits** : l'affirmation du Story File est **EXACTE**, et c'est
**la 6ᵉ instance mesurée** de *« la couverture de lignes est aveugle »* sur ce projet.

## Annexe G — mes 10 mutants tués, extraction **STRICTE** des échecs *(lignes ` [E]`)*

**Base, arbre propre, cible `test/features/echeances/data/`** : `00:06 +93: All tests passed!` ·
`echecs : []` · `git status : ''`.

```
[M1_B2_documentNeuf_inconditionnel (le DEFAUT d'origine)]      00:05 +90 -3
    - 🔴 B-2 sur le magasin de PRODUCTION — un `rename` qui ECHOUE POUR DE VRAI …
    - 🔴 B-2 — mise de cote IMPOSSIBLE : charger() rend, l'ecriture est REFUSEE, et le document illisible est INTACT OCTET POUR OCTET
    - 🔴 NB-J … une mise de cote qui leve un UnsupportedError (le cas du STUB) ne traverse PAS charger()

[M2_catch_rend_true (l'echec perdu)]                           00:06 +90 -3
    - (les 3 MEMES tests)

[M3_NBG_boucle_aveugle (CONTROLE D'INDEPENDANCE du test B-2)]  00:07 +92 -1
    - 🔴 NB-G — un REPERTOIRE sur la destination predite est ESQUIVE …
      => le test de B-2 reste VERT : INDEPENDANT du correctif NB-G

[M4_NBF_lire_existsSync (CONTROLE D'INDEPENDANCE du test B-2)] 00:05 +92 -1
    - 🔴 NB-F — un REPERTOIRE portant le nom du document : lire() rend DocumentIllisible …
      => le test de B-2 reste VERT : INDEPENDANT du correctif NB-F
      => et le test « occupant non-fichier » VU DU DEPOT reste VERT : c'est une CARACTERISATION,
         exactement ce que le @Developer ecrit en C7

[M5_NBE_pas_de_menage]                                         00:06 +92 -1
    - 🔴 NB-E — un `rename` qui ECHOUE ne laisse AUCUN `.tmp` …
[M6_NBE_pas_de_rethrow]                                        00:04 +92 -1
    - 🔴 NB-E — (le MEME test : les deux moities sont defendues)

[M7_NBG_borne_return_muet (ce serait B-2 par une autre porte)] 00:07 +91 -2
    - 🔴 NB-G — la boucle est BORNEE : tous les candidats occupes ⇒ mettreDeCote LEVE …
    - 🔴 B-2 sur le magasin de PRODUCTION …
      => le commentaire « un `return` muet ici serait EXACTEMENT B-2 » est DEFENDU par un test

[M8_NBJ_catch_on_Exception (B-1 par une autre porte)]          00:05 +92 -1
    - 🔴 NB-J … une mise de cote qui leve un UnsupportedError (le cas du STUB) …

[M9_NBJ_charger_avale_la_violation_de_contrat]                 00:07 +92 -1
    - ⛔ LA BORNE — si le magasin VIOLE son contrat et leve a la lecture, charger() LEVE …
      => la BORNE de NB-J est EPINGLEE, pas laissee a la relecture

[M10_ANTIVACUITE_test_B2_sans_obstacles]                       00:09 +92 -1
    - 🔴 B-2 sur le magasin de PRODUCTION …
      => sans son declencheur, le test ROUGIT : IL N'EST PAS VACUE

Apres CHACUN : `git checkout -- <fichier>` puis `git status --porcelain` -> '' (VIDE).
```

**Bilan de ma campagne : 12 mutants joués — 10 TUÉS, 1 SURVIVANT confirmé (`M-E4`, nommé par le
@Developer), 1 NON REPRÉSENTABLE confirmé (échec de compilation). 0 survivant non annoncé.**
