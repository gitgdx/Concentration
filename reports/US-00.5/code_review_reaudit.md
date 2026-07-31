# US-00.5 — RE-AUDIT de revue (@CodeReviewer, 2ᵉ passage)

- **US** : US-00.5 — ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution
- **Objet** : vérification des **6 actions** du §7 de [`code_review.md`](code_review.md) — commit **`a78a997`**
- **PR** : #17 · branche `feat/US-00.5-adr-stack-constitution` · `main` = `856c366`
- **Auditeur** : @CodeReviewer — **même auditeur**, délibérément, pour vérifier **mes** actions et non
  ouvrir un second motif
- **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-07-30
- ⛔ **Ce rapport n'écrase pas `code_review.md`** : le `FAILED` du 1ᵉʳ passage reste lisible en entier.

---

## ✅ VERDICT : **PASSED**

| Sévérité | Nombre |
|---|---|
| 🔴 **Bloquant** | **0** — **B-1 est LEVÉ**, vérifié par **ma** commande, pas par la sienne |
| 🟠 Non bloquant **résiduel** | **5** *(RB-1 → RB-5)* |
| 🟢 Contrôles exécutés à charge sans faute | **27** |
| Findings du 1ᵉʳ passage | **10/10 traités** *(1 bloquant + 9 non bloquants)* |

**Les 6 actions sont tenues.** Le bloquant est levé **sur le fond** : j'ai refait le balayage avec **mon
propre** motif et il ne reste **aucune charge éteinte non marquée** au SCB — l'extension est couverte
**5/5**, là où elle l'était **2/5**. Les 9 non bloquants sont corrigés, et **8 d'entre eux ont été
vérifiés mécaniquement** (comparaison octet à octet config ↔ ADR, hook ↔ ADR, PRD ↔ ADR).

Les **5 résidus** sont **tous** dans des fichiers de **preuve**, **aucun** ne dissimule un défaut,
**aucun** ne falsifie un fait sur le livrable. Deux d'entre eux (**RB-1**, **RB-2**) relèvent pourtant de
la **même classe** que B-1 — un résultat ou un emplacement **écrit à la main à côté d'une commande** — et
je le dis sans l'atténuer : **la cause racine n'est pas éteinte, elle est seulement moins nuisible.**

---

## 1. Les 6 actions, vérifiées par exécution

### ✅ Action 1 (🔴 B-1) — marqueur sur les 3 lignes nues : **TENUE**

**Contrôle de présence** :
```
$ grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md
5                                    (avant : 2)
$ grep -n "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md | cut -d: -f1
212  291  368  431  545
```
✅ Les **3** lignes nues (`212`, `291`, **`368`**) portent désormais le marqueur **littéral**, **sur la
ligne même**, **jamais** `~~`. **`368` — celle que le Story File cite mot pour mot — est traitée**, et son
marqueur nomme explicitement le fait : « *C'est la ligne que le Story File d'US-00.5 cite mot pour mot, et
elle était la seule des 5 à n'avoir rien reçu* ».

**Contrôle « ni réécrit ni supprimé »** — le diff est un **ajout pur**, le texte d'origine subsiste
octet pour octet :
```
$ git diff 4f5b837 a78a997 -- STORY_CERTIFICATION_BOARD.md
-     … relève de **US-00.5**, aux deux
+     … relève de **US-00.5**, aux deux **PÉRIMÉ-2026-07-28 : charge ÉTEINTE — …**
-  → textes normatifs, PR dédiée en US-00.5.
+  → textes normatifs, PR dédiée en US-00.5. **PÉRIMÉ-2026-07-28 : charge ÉTEINTE — …**
-    … → transmis à **US-00.5**, @PO tranchera le véhicule.
+    … → transmis à **US-00.5**, @PO tranchera le véhicule. **PÉRIMÉ-2026-07-28 : destinataire RÉEL = US-00.8 …**
```
✅ **Aucune suppression, aucune réécriture** : les 3 visas datés sont intacts, le marqueur est **accolé**.
*(Réserve de forme sur l'un des trois → **RB-3**.)*

**🔎 MON PROPRE BALAYAGE — le contrôle qui compte, et il est indépendant du sien** *(j'ai refusé de me
fier à son motif : c'est la précaution même qu'il me demande)* :
```
$ grep -n "US-00\.5" STORY_CERTIFICATION_BOARD.md | grep -v "PÉRIMÉ-2026-07-28"
17 · 541 · 549 · 555 · 557 · 560 · 635 · 650 · 674 · 676 · 693 · 694 · 695 · 783 · 867 · 1114 · 1246
-> 17 lignes, triées UNE PAR UNE ci-dessous
```

| Lignes | Nature | Charge éteinte ? | Marqueur dû ? |
|---|---|---|---|
| `17` | ligne de tableau d'US-00.5 (état **courant**) | non | non |
| `541` · `555` · `1246` | **constats vrais** *(« il faut en outre US-00.5 et US-00.6 », « 4 sur 6 »)* | non — **VRAIS au 2026-07-30** | ⛔ non — les marquer serait une **régression documentaire** |
| `549` | membre du bloc **déjà marqué** en `545` | couverte | déjà |
| `557`→`560` · `635` · `650` · `674`→`695` | prose **courante** de la section US-00.5 | non | non |
| `783` · `867` | « le périmètre d'US-00.5 **se réduit** » — **vrai**, il s'est réduit | non | non |
| `1114` | « **US-00.5 GAGNE un item** » — incomplétude de l'*Enforcement* | **NON : charge VIVANTE** | ⛔ non — la marquer serait **FAUX** |

⇒ **0 charge éteinte non marquée. L'extension est couverte 5/5.** 🔴 **B-1 est LEVÉ.**

**Sur ton classement de l'exception, que tu m'invites à contester** : **je le confirme, il est juste.**
L'incomplétude du bloc *Enforcement* (l'Art. 4 ne nomme que `ci.yml` alors que le 4ᵉ contexte requis vient
de `branch-naming.yml`) est **encore due** et part en **PR nº 2** — je l'ai revérifiée à la source :
`factory.config.json → status_checks` porte bien **4** contextes, **3** de `ci.yml` + **1** de
`branch-naming.yml`, et `CONSTITUTION.md` est **byte-identique** à `main`. La charge est **vivante et
vraie** ; la marquer périmée aurait été une fausseté.

### ✅ Action 2 (🔴 sur-affirmation « les DEUX ») — **TENUE, et le traitement est LE BON**

```
$ git diff 4f5b837 a78a997 -- PROJECT_LOG.md   →  3 lignes AJOUTÉES, 0 modifiée, 0 supprimée
Nouvelle ligne @Architect : « ma ligne précédente de ce journal déclare "marqueur posé SUR LA LIGNE MÊME
des DEUX transmissions périmées du SCB" — IL Y EN AVAIT CINQ, DONT TROIS NUES. Je ne réécris pas cette
ligne (append-only), je la corrige ici. Et je note l'ironie sans m'en excuser : c'est le même défaut mot
pour mot que celui commis pendant US-00.7 ("trois endroits alors qu'il y en avait CINQ"). »
```

**Tu me demandes si la correction devait être *dans* la ligne. Réponse : NON, et ton choix est le bon.**
Trois raisons, dont deux sont des faits du projet :

1. **Un journal est un ledger append-only, un tableau d'état ne l'est pas.** Le `PROJECT_LOG` se lit **en
   avançant** ; le SCB se lit par **accès direct** à une ligne. D'où la règle correcte, et la seule qui
   soit cohérente : **marqueur sur la ligne** dans le SCB, **rectification en aval** dans le journal. Ta
   distinction n'est pas une commodité, elle suit la nature des deux artefacts.
2. **C'est la doctrine déjà payée par ce projet** : la dérogation `EVT_WAIVER_GRANTED` d'US-00.4 a été
   **éteinte** et non **effacée**, avec le motif explicite « *la trace n'est pas réécrite (append-only) :
   on éteint une dérogation, on ne l'efface pas* ».
3. **Réécrire aurait détruit la partie instructive.** L'erreur « les DEUX » **est** la preuve que le motif
   de fond d'US-00.7 se reproduit ; l'effacer aurait supprimé la seule chose qui rende la leçon
   falsifiable. Ta nouvelle ligne fait mieux que corriger : elle **nomme le précédent**.

⚠️ **Borne que j'assume avec toi** : `grep "DEUX transmissions"` rend `PROJECT_LOG:110` **sans** marqueur
sur la ligne. C'est le **prix accepté** de l'append-only, pas un oubli — et il est réglé par le fait que
la rectification vit **deux lignes plus bas**, dans le même écran.

### ✅ Action 3 (🟠 critère de sortie = script exécutable) — **TENUE sur le fond → mais son résultat publié est périmé (RB-1)**

**Le script est HONNÊTE, et je l'ai audité ligne à ligne avant de l'exécuter** :
- ses **3** filtres sont **déclarés en commentaire** (l. 33-34 pour `se réduit` / `réduit (`, l. 39 pour le
  marqueur) — **aucun filtre silencieux**, ce qui était l'exigence centrale ;
- l'exception **n'est pas filtrée** : elle **sort** et reste **visible** — exactement ce qu'il fallait ;
- elle est désignée **par son TEXTE** dans le script, avec la 3ᵉ leçon citée et le glissement de numéro
  **avoué** en commentaire.

**Mon exécution** :
```
$ sh reports/US-00.5/sweep_transmissions.sh
STORY_CERTIFICATION_BOARD.md:695:  … l'exception nommée et justifiée** *(la charge « US-00.5 GAGNE un item » est **VIVANTE et VRAIE** …
STORY_CERTIFICATION_BOARD.md:1114: … Et **US-00.5 GAGNE un item** : l'Art. 4 nomme `ci.yml`
=== FIN — toute ligne ci-dessus est un DEFAUT NON COUVERT ===
-> 2 LIGNES
```
⛔ **Le rapport déclare « il rend UNE SEULE ligne ». Il en rend DEUX.** → **RB-1**, non bloquant, détaillé
au §2 : la 2ᵉ ligne est **ta propre prose**, ajoutée **après** la capture, et **aucun défaut n'y est
dissimulé** — je l'ai établi indépendamment en Action 1.

### ✅ Action 4 (🟠 NB-1, diagnostic git faux) — **TENUE : 0 assertion vivante**

J'ai refait le balayage **et trié les 5 occurrences une par une**, sans me fier à ton tableau :

| Emplacement | Statut réel |
|---|---|
| `code_review.md:172-173` | **mon** rapport daté qui cite la phrase **pour la réfuter** — légitime |
| `conformite_ac.txt:45` | **citation dans sa propre rectification** *(« J'avais écrit : … C'EST FAUX »)* — légitime |
| `correctifs_failed_revue.txt:27` | **la commande de `grep` elle-même** — l'outil se matche |
| `SCB:638-639` | **citation dans sa propre rectification**, sous marqueur `PÉRIMÉ-2026-07-30` — légitime |
| `PROJECT_LOG:110` | ligne d'origine **non réécrite** (append-only), rectifiée en aval |

⇒ **5 occurrences, 0 assertion vivante.** Ton classement est **exact**, et ton analyse de la cause du
faux motif est **juste** : « *un `grep` de motifs matche la documentation des motifs — un correctif qui
s'explique produit mécaniquement des occurrences de ce qu'il corrige* ». ✅ Les **3** emplacements portent
la **bonne** explication : *un diff compare des **COMMITS***, et ADR-001 n'était pas commité.

### ✅ Action 5 (🟠 NB-2, critère nº 5) — **TENUE, et vérifiée par MA propre implémentation**

Le critère est reformulé en lecture **par catégorie**, avec la correspondance **publiée** dans le Story
File. ⛔ **Je ne me suis pas fié à sa sortie** : j'ai réécrit le contrôle et je l'ai exécuté sur
`factory.config.json`.

```
$ (implémentation indépendante du critère nº 5 reformulé)
  lint                   -> ['analyze']    RÉALISÉ et BLOQUANT            => OK
  typecheck              -> ['analyze']    RÉALISÉ et BLOQUANT            => OK
  tests                  -> ['test']       RÉALISÉ et BLOQUANT            => OK
  SAST                   -> AUCUN gate ne le réalise                      => ÉCHEC (critère 5)
  audit de dépendances   -> ['deps_audit'] RÉALISÉ mais blocking=False    => ÉCHEC (critère 6)

  échecs critère 5 : ['SAST'] | échecs critère 6 : ['audit de dépendances']
  TOTAL : 2 échecs — attendus par le Story File : 2
  gate omis par l'Art. 4 (aucune catégorie) : ['build']
```
✅ **2 échecs attendus, 2 obtenus, et ce sont les bons.** Le critère **n'est plus falsifié par son propre
outil**, et il le restera **après** la PR nº 2 puisqu'il n'exige plus qu'un gate **porte** le nom de la
catégorie. Le gate **`build`** ressort proprement comme celui qu'aucune catégorie ne couvre — l'omission
qu'AC-3 doit combler.

### ✅ Action 6 (🟠 NB-3→NB-6, NB-8, NB-9) — **TENUE, et 4 des 6 vérifiées MÉCANIQUEMENT**

| Finding | Mon contrôle | Verdict |
|---|---|---|
| **NB-3** *(renvoi `fastapi-react`)* | Renvoi ajouté ; ses 3 faits revérifiés : `factory_sync.py` porte bien `backend`+`pytest.ini`/`--cov-fail-under` et `frontend`+`vitest.config.ts` ; `run_gates.py:8` documente `--component backend` ; **aucun** de ces 2 composants n'existe dans l'adapter *(composant unique `app`)* | ✅ **exact** |
| **NB-4** *(`coverage_ratchet`)* | « *il ne suffira PAS d'ajouter la clé* » — `factory_sync.py:142-143` ne la lit que sur `frontend`, inexistant ici. **La charge d'US-00.6 est désormais correctement dimensionnée** : du **code**, pas une clé | ✅ **exact** |
| **NB-5** *(commandes verbatim)* | **Comparaison mécanique** des **5** `cmd` de `factory.config.json` → présence **littérale** dans l'ADR : **5/5 OK**. `dart format --output=none --set-exit-if-changed lib test` remplace l'abrégé qui **inversait l'effet** | ✅ **5/5 verbatim** |
| **NB-6** *(9 motifs du hook)* | **Comparaison mécanique** hook → ADR : **9/9 motifs présents**, dans l'ordre du hook ; `docs/governance` **absent du hook** *(contrôle négatif : `False`)* | ✅ **9/9** |
| **NB-8** *(motif RNF-08)* | `PRD:146` cite « *qualité du rendu visuel (dégradés, typographie, animations)* » et « *animations fluides et audio pour Respiration* » → **repris exactement**. Corroborations jointes : `PRD:74` grille de **tuiles**, `PRD:104` **interpolation continue** orange→bleu *(OKLCH cité)* | ✅ **exact, et bien sourcé** |
| **NB-9** *(contradiction nommée)* | Ligne ajoutée au tableau des écarts, avec le destinataire **« PR nº 2 de CETTE US »** et la mention « *la contradiction est VIVE et VOULUE jusqu'à la fusion suivante* ». **L'ADR est désormais autosuffisant** pour un lecteur de `docs/adr/` seul | ✅ **exact** |

---

## 2. 🟠 Les 5 résidus — non bloquants, nommés avec leur extension

### RB-1 — Le critère de sortie publié rend **2 lignes** là où **3 artefacts** déclarent **1**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `reports/US-00.5/correctifs_failed_revue.txt:8-10` · `STORY_CERTIFICATION_BOARD.md:694` · `PROJECT_LOG.md` *(nouvelle ligne @Architect)* — **extension : 3 artefacts vivants** |
| **Problème** | La sortie capturée montre **1** ligne (`SCB:1044`) et les 3 artefacts déclarent « **il rend UNE SEULE ligne** ». **Mon exécution sur l'état commité rend 2 lignes** : `695` et `1114`. **Cause établie** : la capture a été faite **avant** l'ajout des ~70 lignes de la section d'audit du SCB — dont la **`695`**, qui **cite** le texte de l'exception (« *la charge « US-00.5 GAGNE un item » est VIVANTE et VRAIE* ») et que le motif `US-00.5 GAGNE` matche **mécaniquement**. Le script n'a pas été **re-exécuté** après la dernière édition. C'est **la forme exacte du 5ᵉ `FAIL` d'US-00.7** : « *le round s'est fixé lui-même son critère de réussite ET CE CRITÈRE EST FAUX PAR SON PROPRE OUTIL — il rend 2, pas 0* ». |
| **Pourquoi NON bloquant** | **La 2ᵉ ligne n'est pas un défaut** : c'est ta prose, et elle est **vraie**. J'ai établi **indépendamment** (Action 1, mon propre motif) qu'il ne reste **0** charge éteinte non marquée. **Le critère atteint donc son but** — détecter une charge éteinte nue — et rend **0** sur ce que le défaut désigne. Contrairement à US-00.7, **le décompte faux ne dissimule rien**, et je l'ai vérifié avant de le dire. |
| **Solution** | Au choix : **(a)** re-exécuter et recoller la sortie *(la plus simple, et la seule vraiment durable)* ; **(b)** rendre le motif insensible aux **citations** — c'est le piège que tu documentes toi-même en FAUTE 1, et il frappe ici ton propre script ; **(c)** dater la capture explicitement *(« sortie au commit X »)* et publier la commande de re-vérification. ⚠️ **Le script est un artefact durable, sa sortie est un instantané** : tout critère de sortie publié doit dire **de quel état** il parle. |

### RB-2 — `correctifs_failed_revue.txt:10` désigne l'exception par un **numéro de ligne écrit à la main**, **contredit par sa propre sortie** et **périmé pour la 3ᵉ fois**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `reports/US-00.5/correctifs_failed_revue.txt:10` |
| **Problème** | Le fichier écrit `-> 1 seule ligne : **SCB:1036**`, alors que **sa propre sortie capturée, deux lignes plus haut**, dit `STORY_CERTIFICATION_BOARD.md:**1044**` — et que la réalité d'aujourd'hui est **`1114`**. Trois valeurs pour un même renvoi. **FAUTE 2 a corrigé le SCRIPT et laissé le RAPPORT** : la correction a de nouveau **suivi le renvoi au lieu de couvrir l'extension**, dans le fichier qui **énonce la règle** à sa ligne 100 (« *l'emplacement se DÉSIGNE par son texte* ») et qui l'**enfreint** 90 lignes plus haut. Et le mécanisme est celui que la ligne 100 nomme aussi : **un emplacement écrit à la main à côté d'une commande**. |
| **Pourquoi NON bloquant** | Le renvoi **durable** — celui du script — est correctement fait **par le TEXTE**, et c'est lui qui sera rejoué. Le numéro fautif vit dans un **instantané daté**, à deux lignes de la sortie qui le démentit : le lecteur qui suit la sortie ne se trompe pas. Le préjudice est **contenu**. |
| **Solution** | Une édition : remplacer « `SCB:1036` » par « *la ligne portant « **US-00.5 GAGNE un item** »* ». ⚠️ **Et vérifier l'extension au lieu du renvoi cette fois** : `grep -nE "SCB:[0-9]+|:[0-9]{3,}" reports/US-00.5/*.txt` avant de déclarer la faute close. |

### RB-3 — Le marqueur de `SCB:212` est **interpolé au milieu d'une phrase**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `STORY_CERTIFICATION_BOARD.md:212-213` |
| **Problème** | Le marqueur est inséré entre « *aux deux* » et « *emplacements exacts `CLAUDE.md:20`…* », qui poursuit à la ligne 213. Le visa daté se lit désormais : « *…relève de US-00.5, aux deux* **PÉRIMÉ-2026-07-28 : … non réécrit.** *emplacements exacts…* ». Le visa n'est **ni réécrit ni supprimé** — l'exigence est tenue — mais il est rendu **illisible**. Les deux autres marqueurs (`291`, `368`) sont posés en **fin de phrase** : ils sont **propres**. L'extension est donc de **1 ligne sur 3**. |
| **Solution** | Déplacer le marqueur en **fin de phrase** (fin de la l. 213) ou en fin de l'alinéa 4 (l. 216). La visibilité au `grep` est préservée : l'alinéa entier reste dans le même paragraphe, et un lecteur qui tombe sur la l. 212 lit la suite. |

### RB-4 — La ligne du **3ᵉ faux vert** ne porte **aucun marqueur sur la ligne même**, et son auto-dénonciation est **en fin de fichier**

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `reports/US-00.5/correctifs_failed_revue.txt:28` |
| **Problème** | La ligne fautive « `-> 0 = corrige aux 3 emplacements` » est **conservée** — c'est bien — mais elle ne porte **aucun renvoi** vers sa réfutation, laquelle vit **35 lignes plus bas** sous le titre *FAUTE 1*. C'est **exactement la doctrine que cette US impose au SCB** (marqueur **littéral**, **sur la ligne même**), non appliquée à son propre rapport. Et la structure est **l'inverse du précédent que le projet cite en bien** : la QA d'US-00.7 a porté au crédit de `merge_block.md` d'avoir placé son échec « *en tête et en gras avant toute réussite* » — ici les 8 contrôles verts précèdent les 2 fautes. |
| **Solution** | **(a)** accoler sur la ligne 28 un marqueur littéral du type `⛔ FAUX VERT — voir FAUTE 1 ci-dessous` ; **(b)** remonter le bloc *DEUX FAUTES* **en tête** du fichier. |

### RB-5 *(micro)* — `sweep_transmissions.sh:44` : `rc=$?` est du code mort

| Champ | Contenu |
|---|---|
| **Fichier:Ligne** | `reports/US-00.5/sweep_transmissions.sh:44` |
| **Problème** | `rc=$?` capture le code de retour de `sed` (dernier élément du pipe), **jamais celui du `grep`**, et la variable **n'est jamais utilisée** — `exit 0` est inconditionnel. Sans effet, mais trompeur pour qui croirait le script capable de rendre un code d'échec. |
| **Solution** | Supprimer `rc=$?`, ou faire porter au script un **vrai** code de sortie *(ex. `exit 1` si la sortie contient une ligne autre que l'exception nommée)* — ce qui en ferait un gate rejouable en CI plutôt qu'un rapport. |

---

## 3. Réponses aux trois questions posées

### (a) Le **3ᵉ faux vert** — ton classement des 5 occurrences est **EXACT**, refait par moi

Je les ai triées une par une (§Action 4) : **5 occurrences, 0 assertion vivante**. Ton analyse de la cause
est juste et vaut d'être conservée : *« un correctif qui s'explique produit mécaniquement des occurrences
de ce qu'il corrige »*. ⚠️ **Et elle se retourne contre ton propre script** : c'est **exactement** ce qui
produit **RB-1** — la ligne `695` n'est rien d'autre qu'une **citation** du texte de l'exception, matchée
par un motif incapable de distinguer une **assertion** d'une **citation**. Le piège que tu documentes en
FAUTE 1 est celui qui te prend en Action 3. **Le nommer une fois ne l'éteint pas ; il faut le coder.**
⛔ Résidu **RB-4** : la ligne fautive reste sans marqueur sur la ligne même.

### (b) La phase désalignée — **NON, ce n'est PAS un défaut de l'US.** C'est un défaut du gate, et ton refus est la bonne posture

**Ton diagnostic est exact, vérifié :**
```
scripts/check_scb_compliance.py:29-31   def is_satisfied(cell): return "✅" in cell or cell.strip().upper().startswith("N/A")
scripts/check_scb_compliance.py:175     if "✅" not in story["code_dev"]:   ← contourne is_satisfied()
```
⇒ Une US à `Code (Dev) = N/A` **ne peut pas** entrer légalement en `parallel_audit`. **L'incohérence est
dans le script**, pas dans l'US.

**Et ton refus de la contourner est la bonne posture, avec une circonstance que tu ne revendiques pas** :
```
$ grep -c "check_scb_compliance" .claude/hooks/protect_files.sh
0        ← le fichier n'est PAS protégé
```
**Tu POUVAIS l'éditer, aucun hook ne t'en empêchait, et tu ne l'as pas fait.** C'est la différence entre
une barrière et une discipline, et c'est ici la discipline qui a tenu.

**🔎 J'ÉTENDS TON CONSTAT — et c'est le point utile de cette réponse.** Ce n'est **pas une règle**, c'est
une **famille de 7 contrôles littéraux** là où `is_satisfied()` existe et est utilisé 5 fois :
```
$ grep -n '"✅" not in\|"🧪 PASS" not in\|"🚀 DEPLOYED" not in' scripts/check_scb_compliance.py
157 · 164 · 168 · 175 · 180 · 185 · 190      -> 7 contrôles littéraux
```
Deux sont réellement exposés à un `N/A` **légitime** :
- **l. 175** `code_dev` — **ton cas**, rencontré aujourd'hui ;
- **l. 180** `audit_rev` / `audit_sec` — **non encore rencontré, et il le sera** : il bloquera toute US en
  track **QUICK** dont les audits sont `N/A`, or `TRACKS.md` prévoit précisément ce cas.

⇒ **À verser à US-00.8 avec cette EXTENSION**, et non avec la seule règle rencontrée. **C'est la leçon de
B-1 appliquée à la dette elle-même** : corriger `code_dev` seul serait corriger le **renvoi**.

### (c) La borne de sécurité — **aucune incohérence**, et je l'ai vérifiée par exécution

**Les faits nouveaux qu'elle avance sont vrais** :
```
$ find lib -type f
lib/main.dart                                                   -> 1 SEUL fichier ✅
$ grep -rnE "dart:io|package:http|HttpClient|Socket|shared_preferences|sqflite|hive|drift" lib/
rc=1  -> AUCUNE occurrence : ni réseau, ni persistance, ni dart:io ✅
$ pubspec.yaml -> dependencies : flutter, cupertino_icons uniquement ✅
```
**Cohérence avec le reste de l'ADR** : ✅ **totale**, et la borne **renforce** plutôt qu'elle ne fissure.
- La nuance **Web** (« *un build web s'exécute dans un navigateur, avec son modèle de stockage et
  d'origine propre ; l'énoncé RNF-07 vaut pour la cible mobile* ») est **cohérente** avec l'honnêteté
  nº 2 *(« le Web n'est pas une plateforme cible produit »)* et avec **§Décision 5** *(« Plateformes
  matérialisées : Android et Web »)*. Elle **précise** sans contredire.
- ⚠️ **Une tension résiduelle, que je signale sans en faire un finding** : **§Décision 2** énonce toujours
  « *l'application est offline-first (RNF-07), **aucune donnée ne quitte l'appareil*** » **sans** la
  nuance Web, laquelle vit 50 lignes plus bas en §Conséquences. Ce n'est **pas** une contradiction — la
  §Décision cite RNF-07, qui est une **exigence produit** portant sur la cible mobile — mais un lecteur
  pressé de la seule §Décision ne verra pas la réserve. **Un renvoi d'une parenthèse** *(« nuance Web :
  voir Conséquences »)* fermerait la question. Je ne l'exige pas.
- **Le finding sécurité lui-même est juste et son mécanisme bien identifié** : une affirmation **positive
  non bornée** dans un document **immuable**, alors qu'**US-01.2 est planifiée**, aurait produit une
  fausse assurance **gelée** — le mécanisme **exact** de l'Art. 4. Le borner **dans l'US qui dénonce ce
  mécanisme** est cohérent.

---

## 4. Contrôles à charge — les 27, tous exécutés

**md5 : ce qui est déclaré corrigé l'est-il ?**
```
STORY_CERTIFICATION_BOARD.md    8c9105ddf0 -> cfb5cf1e96   MODIFIÉ ✅
PROJECT_LOG.md                  05606ae28c -> d6c4f4283b   MODIFIÉ ✅
docs/adr/ADR-001-choix-de-stack.md  7eb4034424 -> 2d0e147bdb   MODIFIÉ ✅
docs/stories/US-00.5-*.md       1ec99eb5ef -> f41a262ee7   MODIFIÉ ✅
reports/US-00.5/conformite_ac.txt  c9722d90d7 -> a4e21e02a4   MODIFIÉ ✅
-> 5/5 RÉELLEMENT modifiés, aucun byte-identique déclaré corrigé
```

**Contrôle négatif : ce qu'il était INTERDIT de toucher** *(md5 `main` vs `HEAD`)*
```
ADR-005 · ADR-006 · ADR-007 · CONSTITUTION.md · factory.config.json · CLAUDE.md
-> 6/6 BYTE-IDENTIQUES ✅        (⛔ aucune dérive de périmètre, aucun ADR accepté édité)
```

**Critères de sortie, sur l'état COMMITÉ**
```
git diff --stat main...HEAD -- docs/adr/ADR-005* ADR-006* ADR-007* ADR_TEMPLATE.md  -> VIDE ✅
CONSTITUTION.md dans le diff : 0 ✅   factory.config.json : 0 ✅   fichiers .dart : 0 ✅
grep -c "~~" ADR-001 : 0 ✅           rubriques du template : 7/7 ✅   Statut Accepté : 1 ✅
scénarios Gherkin : 21 ✅  (aucun exécuté — ni runner ni step definitions)
```

**Non-régression**
```
run_gates.py --all              -> exit 0, « Tous les gates bloquants passent (5 exécutés) » ✅
check_scb_compliance.py         -> « SCB conforme — Aucune violation détectée » exit 0 ✅
validate_trace.py --us US-00.5  -> « Traçabilité conforme » ✅
factory_sync.py --check         -> « Synchro factory conforme » exit 0 ✅
```

**Comparaisons mécaniques** *(aucune relecture)* : **5/5** commandes `cmd` verbatim config ↔ ADR ·
**9/9** motifs hook ↔ ADR · **2/2** échecs attendus du critère nº 5 reformulé, par implémentation
indépendante · **17** mentions SCB triées une par une · **5** occurrences NB-1 triées une par une.

---

## 5. Bornes de mon `PASSED` — écrites, non négociées

- ⛔ **Ce `PASSED` porte sur la PR nº 1 SEULE.** **AC-3** *(exactitude de l'Art. 4)* et la seconde moitié
  d'**AC-4** *(PR nº 2 dédiée, version `1.0 → 1.1`, ligne PROJECT_LOG, aucun autre article)* sont **hors
  de ce diff** : les critères de test **5, 6, 7, 8, 10, 11, 12** restent **NON EXERCÉS**. Le critère nº 5
  est désormais **correctement formulé** — il n'est pas pour autant **passé**.
- ⛔ **`0` fichier de code.** Les gates attestent une **NON-RÉGRESSION**, **jamais le livrable**. La
  couverture de **89,5 %** porte sur `lib/main.dart`, squelette. **Aucun** des 21 scénarios Gherkin n'est
  exécuté.
- ⚠️ **À la fusion, le corpus portera une contradiction VIVE entre ADR-001 et l'Art. 4** — assumée,
  arbitrée (C-1), et désormais **nommée dans l'ADR lui-même** avec son destinataire. **Seule la PR nº 2 la
  referme.**
- ⚠️ **La cause racine de B-1 n'est PAS éteinte.** Elle a produit, en deux jours : le faux vert du gate 4
  de `/certify`, celui d'AC-4 en T7, celui de NB-1, et maintenant **RB-1** et **RB-2**. **Cinq
  occurrences, une seule cause** : *un résultat ou un emplacement écrit à la main à côté d'une commande*.
  Le projet en a désormais la **règle** *(`correctifs_failed_revue.txt:100-102`)* mais **aucun mécanisme**.
  ⇒ **Candidat sérieux pour `/audit-methodo`**, pas pour une bonne résolution.
- ⛔ **Aucune exhaustivité revendiquée.** Mon balayage de B-1 porte sur le **SCB seul** (`grep -n
  "US-00\.5"` → 17 lignes non marquées, triées à la main). Je n'ai **pas** balayé la même classe de défaut
  sur les autres documents vivants du corpus.
- ⛔ **Je n'ai vérifié aucune affirmation sur l'état RÉEL de GitHub** : `--check` est **documentaire** et
  le dit ; `--check-remote` exige des droits admin et **n'a pas été lancé**.
- ⛔ **`reviewDecision` de la PR #17 est VIDE.** **Mon `PASSED` ne vaut PAS approbation humaine**, et
  **aucun message d'agent** ne la remplace. La fusion appartient à l'humain, **sans `--admin`**.
- ⚠️ **Le SCB porte `Audit Rev = ❌`** *(le `FAILED` du 1ᵉʳ passage)* et la phase reste
  **`development_start`** — conséquence du défaut de gate du §(b), **non imputable à l'US**. Sa mise à jour
  appartient à `/audit-us` et à @Architect : ⛔ **je n'édite pas le SCB.**
- ⛔ **Même auditeur, 2ᵉ passage** : je vérifie **mes** actions. C'est le mandat qui m'a été donné, et sa
  limite est réelle — **un contexte neuf pourrait trouver un motif que je ne cherche pas**. Mes 6 actions
  sont vérifiées ; je n'ai **pas** rouvert le périmètre au-delà, sauf là où l'extension d'un finding m'y
  conduisait *(§b : 7 contrôles littéraux au lieu d'un)*.

---

## 6. Ce qui reste à faire — **aucun de ces items ne bloque la fusion**

| # | Action | Fichier | Sévérité |
|---|---|---|---|
| 1 | Re-exécuter le script et recoller sa sortie **datée** *(2 lignes, pas 1)* | `correctifs_failed_revue.txt` · `SCB:694` | 🟠 RB-1 |
| 2 | Remplacer « `SCB:1036` » par la **désignation par texte** | `correctifs_failed_revue.txt:10` | 🟠 RB-2 |
| 3 | Déplacer le marqueur en **fin de phrase** | `SCB:212-213` | 🟠 RB-3 |
| 4 | Marqueur sur la ligne du faux vert, ou bloc *FAUTES* **en tête** | `correctifs_failed_revue.txt:28` | 🟠 RB-4 |
| 5 | Supprimer le `rc=$?` mort, ou donner un vrai code de sortie au script | `sweep_transmissions.sh:44` | 🟠 RB-5 |
| 6 | **US-00.8** : porter le défaut de `check_scb_compliance.py` avec son **extension** *(l. 175 **et** l. 180, famille de 7)* | — | 🟠 dette |
| 7 | *(suggestion)* renvoi vers la nuance Web depuis **§Décision 2** d'ADR-001 | `ADR-001` | 🟢 |

⚠️ **Item 7 : dernière fenêtre.** ADR-001 n'est **pas encore fusionné** ; après la fusion,
**l'immuabilité s'applique** et toute retouche exigera un **nouvel ADR**.

---

*Re-audit produit par @CodeReviewer (2ᵉ passage, même auditeur, par mandat explicite) le 2026-07-30 ·
modèle `claude-opus-5[1m]` · toutes les sorties d'outils ci-dessus ont été obtenues dans cette session, sur
le commit `a78a997`. Le `FAILED` du 1ᵉʳ passage n'est pas effacé : il vit dans
[`code_review.md`](code_review.md).*
