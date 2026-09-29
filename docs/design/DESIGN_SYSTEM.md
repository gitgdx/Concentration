# 🎨 Design System — Concentration

> Rempli et maintenu par @UXDesigner. Référencé par chaque US touchant l'interface.
> **Renseigné le 2026-08-01** pour US-01.1. ⛔ **Ce fichier est l'autorité sur les VALEURS** ;
> `lib/core/theme/concentration_tokens.dart` n'en est que la **projection en Dart** — aucune couleur ni
> dimension ne s'écrit dans un widget.

## 🌍 Langue du produit — FRANÇAIS UNIQUEMENT

**Décision humaine du 2026-08-01.** Toute chaîne visible par l'utilisateur est en **français**.
⚠️ **Conséquence directe** : les maquettes Stitch *(`docs/design/stitch/`)* sont **en anglais mêlé de
français** *(« Deadlines », « Breathing », `text-on-primary-container`…)*. ⛔ **Leurs libellés ne sont
donc PAS des tokens de contenu** — ce sont des **repères de mise en page**. Tout libellé repris d'une
maquette doit être **traduit**, y compris les noms de modules : **Échéances**, **Respiration**,
**Concentration**. *(Cette décision clôt l'arbitrage « langue mixte fr/en des maquettes ».)*

## Palette et tokens

### Dégradé temporel — les deux extrémités, TRANCHÉES PAR MESURE

| Token | Valeur | Usage |
|---|---|---|
| `gradientOrange` | **`#FF8C42`** | Extrémité `p = 0` — le nombre **vient de changer** *(loin du prochain changement)* |
| `gradientBleu` | **`#3D7DD8`** | Extrémité `p = 1` — changement **imminent** |
| `texteSurTuile` | **`#1B110C`** | **Unique** couleur de texte sur tuile, sur **toute** la plage |
| `fondApp` | `#1B110C` | Fond de l'application *(dark mode de référence)* |
| `texteSurFond` | `#F2DFD5` | Texte sur le fond sombre de l'application |
| `moduleActif` | `#FFB68D` | Accent du module actif dans le hub |
| `moduleGrise` | `#3E322C` | Modules futurs — estompés, **non-interactifs** |

🔬 **Le bleu n'a PAS été choisi par autorité mais par CALCUL de contraste**, comme l'exige
[ADR-003](../adr/ADR-003-degrade-temporel-espace-colorimetrique.md) §5. Interpolation **OKLab**, 101
points sur `p ∈ [0;1]`, **meilleure** des deux couleurs de texte candidates à chaque point, puis **pire cas
sur la plage** :

| Candidat | Pire cas | Bascule de texte | Verdict |
|---|---|---|---|
| `#FF8C42` → **`#3D7DD8`** *(proposition PRD §« Palette du dégradé »)* | **4,53:1** à `p = 1` | ⛔ **aucune** | ✅ **passe 4,5:1 ET 3:1** |
| `#FF8C42` → `#005AB3` *(palier 4 de la maquette)* | **3,81:1** à `p = 0,73` | requise à `p = 0,74` | ⚠️ passe **3:1** *(le nombre)*, ⛔ **échoue 4,5:1** *(la description)* |

➡️ **`#3D7DD8` retenu** : c'est le seul qui satisfait **les deux** seuils, et il le fait **sans bascule de
couleur de texte** — donc avec **un seul token de texte** et une règle plus simple à tenir.
🔴 **FRAGILITÉ À CONNAÎTRE : la marge est de 0,03 point** *(4,53 contre 4,50 requis)*. ⛔ **Assombrir le
bleu, éclaircir le texte de tuile, ou changer l'espace d'interpolation FERA TOMBER l'AA de la
description.** Toute retouche de ces trois tokens **exige de rejouer le calcul** — c'est précisément
pourquoi `foregroundFor(p)` **échoue bruyamment** au lieu de dégrader en silence.

### ⛔ Le sens du dégradé de la maquette est INVERSÉ — confirmé par ses propres commentaires

La maquette déclare `.temporal-gradient-1 { background-color: #ff8c42; } /* Orange - **Immediate** */`
et `.temporal-gradient-4 { background-color: #005ab3; } /* Blue - **Far** */`.
⛔ **C'est l'inverse d'AC-5** : orange = **loin** *(`p = 0`)*, bleu = **imminent** *(`p = 1`)*.
**Le PRD et l'AC font foi ; la maquette est une référence de mise en page, jamais de sémantique.**
⚠️ Ce n'est plus une hypothèse : **le commentaire de la maquette le dit littéralement**, donc quiconque
reprendra ses classes CSS réintroduira l'inversion. **Les tokens ci-dessus sont nommés par leur RÔLE**
*(`gradientOrange` / `gradientBleu`)* et **jamais par un palier**, pour rendre l'erreur difficile.

### Surfaces interactives — **4 tokens AJOUTÉS le 2026-08-06** *(US-01.2)*

> ⛔ **Rien de ce bloc ne modifie un token existant.** Le dégradé temporel et ses trois tokens sont
> **intouchés** *(leur marge est de **0,03 point**)*. Détail, wireframes et calculs :
> [`US-01.2-DESIGN-UX.md`](US-01.2-DESIGN-UX.md).

| Token | Valeur | Usage | Origine |
|---|---|---|---|
| `surfaceElevee` | **`#231914`** | fond des cartes de gestion et des champs de saisie | maquette `surface-container-low` |
| `contour` | **`#A48C7F`** | bordure 1 dp d'une carte ou d'un champ, liseré du groupe des échues | maquette **`outline`** |
| `texteSecondaire` | **`#DDC1B3`** | date, heure, temps restant, libellé de champ, texte d'aide | maquette `on-surface-variant` |
| `erreur` | **`#FFB4AB`** | message de refus de validation *(AC-15 d'US-01.2 l'autorise nommément)* | maquette `error` |

⛔ **`focus` n'est PAS un token** : l'anneau de focus **est** `moduleActif` — une seconde valeur pour
la même intention dériverait.

> ⚖️ **PÉRIMÉ-2026-09-08 SUR SA SECONDE MOITIÉ, ET SUR ELLE SEULE** *(US-01.4 — §G-10 du Story File,
> `US-01.4-DESIGN-UX.md` §6.1)*. ⛔ **La phrase ci-dessus n'est pas retirée** : *on date, on ne
> repeint pas.*
>
> ✅ **« `focus` n'est PAS un token » RESTE VRAI, et c'est vérifiable** : l'anneau livré ⛔ **n'ajoute
> AUCUN token de couleur** — il n'emploie que `moduleActif` et `fondApp`, déjà là.
>
> 🔴 **« l'anneau de focus EST `moduleActif` » est FAUX dès que la surface adjacente est le DÉGRADÉ —
> et un anneau PLAT y est IMPOSSIBLE, par CALCUL sur 101 points** : `moduleActif` contre le dégradé
> rend **1,36:1**, soit **101 points sur 101 sous 3:1**. ⛔ **Aucune couleur plate ne tient les deux
> côtés** — ni un token, ni le **blanc pur** *(2,31:1 sur le dégradé)*, ni le **noir pur**
> *(5,12:1 sur le dégradé mais **1,13:1** contre `fondApp`)*. Ce n'est pas un manque de palette,
> c'est **arithmétique** : le dégradé va d'un orange **clair** à un bleu **médian** quand `fondApp`
> est **quasi noir** ⇒ toute couleur assez claire pour contraster avec `fondApp` est **trop claire**
> pour l'orange, et l'inverse.
>
> ➡️ **Sur une tuile, le focus se peint en DEUX LISERÉS CONTIGUS** *(la technique même de SC 2.4.11)*,
> et **la mesure est ce qui porte la décision** :
>
> | Composant | Rôle | Mesure | Seuil |
> |---|---|---|---|
> | **liseré INTÉRIEUR** `fondApp`, **peint SUR** la tuile | contraste contre **la tuile** *(le dégradé)* | **4,53 → 8,02:1** — **0/101 points sous 3:1** | 3,0 ✅ |
> | **liseré EXTÉRIEUR** `moduleActif`, **HORS** de la tuile | contraste contre **le fond d'écran** | **10,89:1** | 3,0 ✅ |
> | **les deux entre eux** | séparabilité des deux bandes | **10,89:1** | 3,0 ✅ |
>
> | Grandeur | Valeur | Motif |
> |---|---|---|
> | Épaisseur d'**UN** liseré | **2 dp** — `ConcentrationTokens.epaisseurAnneauFocus` | **UN SEUL token pour LES DEUX** : ⛔ deux valeurs dériveraient. La largeur totale de l'indicateur vaut donc **4 dp**, soit **le double** du minimum de SC 2.4.11 — et **c'est nécessaire** : il faut **deux bandes** pour tenir les **deux** côtés |
> | Décalage entre les deux liserés | **0** — ils sont **contigus** | un écart y ferait apparaître **une troisième couleur non calculée** |
> | Rayons | ⛔ **des FORMULES, jamais des nombres**, sur `rayonSurface` *(**16** — **LU** dans `concentration_tokens.dart`)* : extérieur `rayonSurface + épaisseur` = **18**, jonction `rayonSurface` = **16** | des rayons **constants** pinceraient les angles ; la formule **survit** à un changement de `rayonSurface`. 🔬 **Précision LUE dans `echeance_tile.dart`, parce qu'elle corrige un énoncé plus large** : le code ne porte que **DEUX** boîtes décorées ⇒ le « rayon intérieur » **14** ⛔ **n'est pas un troisième nombre**, il **résulte** du tracé vers l'intérieur de la bordure |
> | Empreinte **hors** de la tuile | **2 dp** | l'espacement de la grille vaut **12 dp** *(**LU** : `mainAxisSpacing` / `crossAxisSpacing` d'`echeances_grid.dart`)* ⇒ il reste **10 dp** jusqu'à la voisine : ⛔ **aucun chevauchement**, et l'écart reste **≥ 8 dp**. ⛔ **L'anneau n'occupe AUCUNE place** *(`Positioned` à décalage négatif sous un `Stack(clipBehavior: Clip.none)`)* — sinon il **déplacerait les tuiles sous le doigt** |
>
> 🔴 **DEUX RÈGLES QUI VONT AVEC LA GÉOMÉTRIE, et qui sont l'une et l'autre réfutables** :
> **①** **le liseré intérieur SE PEINT, il ne se DEVINE pas** — un anneau posé **avec un décalage**
> laisserait voir **la peinture du parent** dans l'écart *(ici `fondApp`, **par coïncidence**, parce
> que le hub est sombre)* : le contraste serait **une propriété du parent, pas une décision**, et il
> tomberait le jour où la tuile serait posée ailleurs. **②** **l'anneau n'apparaît QUE pour la mise en
> évidence du focus** *(`onShowFocusHighlight` — traversée clavier / AT)*, ⛔ **jamais au contact d'un
> doigt** : un liseré `moduleActif` qui s'allume sous le doigt serait **un retour d'appui COLORÉ** sur
> la seule surface où la couleur ⛔ n'encode **que** la proximité temporelle.
>
> 🔬 **CE QUI REND CETTE DÉCISION VÉRIFIABLE, ET C'EST UN CONTRÔLE NÉGATIF** *(`test/core/color/temporal_gradient_test.dart`,
> là où la boucle sur 101 points **existe déjà** — ⛔ jamais recopiée ailleurs)* : le test asserte
> `fondApp` **≥ 3:1 sur les 101 points**, **et** que `moduleActif` **posé SEUL échoue sur les 101
> points**. ⇒ **sans ce second volet, une couleur plate « suffirait » et la géométrie bicolore serait
> une décoration** — c'est lui qui rend l'anneau bicolore **NÉCESSAIRE**.
>
> ⚠️ **Défaut de forme signalé au passage, ⛔ non corrigé ici** : l'espacement de la grille vaut
> **12 dp**, **hors de l'échelle base 8 / demi-pas 4** de ce document, et la « **Dette de cohérence
> NOMMÉE** » du §*Espacement, rayons* ne nomme que `hub_page.dart` — **elle est donc plus étroite que
> le fait**. ⛔ **Aucune retouche** : `echeances_grid.dart` n'est pas modifié pour un motif d'échelle.

**Ratios calculés** *(WCAG 2.1 ; **autorité** = `python docs/design/us_01_2_contrastes.py`, à
supprimer en T9 quand `test/core/theme/contraste_tokens_test.dart` existera)* :
`texteSurFond/fondApp` **14,39** · `texteSurFond/surfaceElevee` **13,35** ·
`texteSecondaire/fondApp` **10,91** · `erreur/fondApp` **10,93** · `fondApp/moduleActif` **10,89** ·
`contour/fondApp` **5,86** · `contour/surfaceElevee` **5,44**.

> ⚖️ **PÉRIMÉ-2026-09-08 — L'AUTORITÉ NOMMÉE CI-DESSUS EST UN RENVOI MORT, et il a été trouvé en
> cherchant autre chose.** ⛔ **La phrase n'est pas réécrite.** **Mesuré** : `docs/design/*.py` rend
> **AUCUN fichier** *(`us_01_2_contrastes.py` a bien été **supprimé**, comme la phrase le prévoyait)*
> et `test/core/theme/contraste_tokens_test.dart` **existe**.
> ➡️ **L'autorité des ratios de tokens est donc CE TEST**, ⛔ **plus aucun script de `docs/`**.
> 🔬 **Ce que ce cas apprend, et il vaut au-delà de cette ligne** : *la prévision était juste et
> l'énoncé est devenu faux quand même* — parce qu'il **nommait le fichier à supprimer comme
> l'autorité présente**. ⇒ ⛔ **un énoncé qui annonce sa propre péremption doit désigner son
> SUCCESSEUR, jamais garder le nom du prédécesseur en position d'autorité.**
> ⚠️ **Borne** : ⛔ **je n'ai PAS exécuté ce test** *(aucun outil d'exécution dans mon périmètre)* —
> j'atteste que **le fichier existe**, ⛔ **pas qu'il est vert aujourd'hui**.
> ✅ **BORNE FERMÉE-2026-09-08, par une EXÉCUTION — et l'énoncé ci-dessus reste, parce qu'il était
> vrai de son auteur.** **Mesure REJOUABLE, datée du 2026-09-08** :
> `flutter test test/core/color/temporal_gradient_test.dart test/core/theme/contraste_tokens_test.dart`
> → **`All tests passed!`**. ⇒ **les ratios de tokens ET le contrôle négatif de l'anneau bicolore**
> *(`moduleActif` seul doit échouer sur les 101 points)* **sont verts à cette date**.
> ⛔ **Le NOMBRE de tests n'est pas recopié ici** : c'est un **nombre dérivé**, il dériverait au
> prochain test ajouté — **il se LIT dans la sortie de la commande ci-dessus.**
> ⛔ **AUCUN NOM D'AGENT N'EST INSCRIT COMME CAUTION DE CETTE MESURE, et c'est délibéré** *(une
> attribution à « @Architect » figurait ici, elle est **retirée** : elle était **inexacte** — un
> @Architect réel travaillait en parallèle sur **T18** — et **une signature ne prouve rien** sur ce
> projet : `mergedBy.is_bot` rend `false` même pour un agent, et le champ `emitter` du catalogue
> n'est lu par **aucun** script)*. ⇒ **l'autorité d'une mesure est sa COMMANDE REJOUABLE et sa DATE,
> ⛔ jamais la signature de qui l'a lancée.**
>
> ⚠️ **ET LE DÉFAUT A UNE EXTENSION BIEN PLUS LARGE QUE CETTE LIGNE — c'est le point à retenir.**
> Le renvoi à `us_01_2_contrastes.py` vit en **plusieurs exemplaires** :
> * dans les **trois documents de design** *(celui-ci, `US-01.2-DESIGN-UX.md` — qui en porte **le
>   plus**, dont sa **déclaration d'autorité**, datée le même jour — et `US-01.4-DESIGN-UX.md`)* ⇒
>   🔴 **c'est LÀ que le défaut vit** : un script **supprimé** y est présenté comme **l'autorité
>   COURANTE** ;
> * dans la **trace append-only** *(`PROJECT_LOG.md`, `STORY_CERTIFICATION_BOARD.md`,
>   `reports/US-01.2/**`, `docs/stories/US-01.2-*`)* ⇒ ✅ **il y RESTE JUSTE et ⛔ ne se touche
>   JAMAIS** : ces lignes enregistrent ce qui était vrai **à leur date**, et les réécrire serait
>   **repeindre l'histoire**.
>
> ⛔ **Le COMPTE ne s'écrit pas ici — il se LIT**, et sa décomposition avec lui :
> `grep -rc "us_01_2_contrastes" --include=*.md .`
> *(un nombre recopié à la main serait faux au prochain fichier touché : **classe de défaut nº 1**, et
> elle a déjà frappé **deux fois dans cette seule session** — un compte de marqueurs annoncé de
> mémoire, et un motif de `grep` mal échappé.)*
> ➡️ **Ce que US-01.4 fait, et ⛔ ce qu'elle ne fait pas** : elle **date les DEUX déclarations
> d'autorité** *(ici et dans `US-01.2-DESIGN-UX.md` §6.3)* et ⛔ **ne chasse PAS les autres renvois un
> par un** — *« corriger le DÉFAUT, pas le RENVOI ; un renvoi cite un exemple, le défaut a une
> extension »*, et la chasse au renvoi a déjà coûté **quatre survivances** à ce projet *(leçon
> US-00.7)*. **Dette PORTÉE et NOMMÉE**, candidate à **US-00.8 / `/audit-methodo`** : ⛔ **US-01.4
> n'a pas à solder une dette d'US-01.2**, mais ⛔ **elle ne la laisse pas anonyme.**

🔴 **Trois REFUS, par mesure — ce sont eux qui portent la décision** :

| Écarté | Ratio | Conséquence |
|---|---|---|
| `outline-variant` **`#564338`** *(bordure de la maquette)* | **1,99:1** | **Remplacé par `#A48C7F`** — une bordure qui identifie un composant relève de SC 1.4.11 *(≥ 3:1)* |
| **Toute opacité sur un token de texte** *(la maquette empile `/40`, `/50`, `/60`, `/80`)* | `texteSecondaire` à 40 % = `#69574F` ⇒ **2,72:1** | ⛔ **INTERDITE.** La hiérarchie se fait par un **token mesuré**, la **taille** et la **graisse** — une opacité fabrique une couleur dont personne n'a calculé le contraste |
| `moduleGrise` **`#3E322C`** pour un élément **devenu interactif** | **1,50:1** | Licite pour un composant **inactif** *(exempté SC 1.4.3)*, ⛔ **interdit** pour un texte porteur d'information et pour la commande activée par US-01.2 |

🔴 **`erreur`, `moduleActif` et `texteSecondaire` sont à `1,00:1` ENTRE EUX** *(luminances 0,5684 ·
0,5664 · 0,5677)* : ils **ne sont pas séparables par la luminance**. ⇒ **règle permanente** : tout
état porte **un mot ou une forme**, ⛔ **jamais la couleur seule** *(SC 1.4.1)*.

### Espacement, rayons — **posés le 2026-08-06** *(US-01.2)*

Échelle base 8, demi-pas 4 : `xs 4` · `sm 8` · `md 16` · `lg 24` · `xl 32`.
Marge de contenu **16** *(⛔ pas les 24 de la maquette : à 320 dp, 48 dp de marges = 15 % de la
largeur — la maquette est centrée, c'est un réglage **desktop**)*.
Rayons : `rayonSurface 16` *(cartes — **même valeur que la tuile**)* · `rayonChamp 8`.
⚠️ **Dette de cohérence NOMMÉE, non corrigée** : `hub_page.dart` porte `vertical: 12` et
`horizontal: 10`, **hors échelle**. ⛔ **Non retouchés** — ce fichier n'est modifié que pour activer
une commande, et son `Row` a **déjà débordé** *(63 px à 390, 133 px à 320)*.

### ⛔ Les 4 paliers ne sont PAS retenus

`#FFB68D` et `#AAC7FF` *(paliers 2 et 3)* **ne sont pas des tokens de dégradé** : AC-5 exige une
**interpolation continue** et `#FFB68D` est réaffecté à l'accent du module actif. Le dégradé est
**calculé**, jamais tabulé.

## Typographie

| Rôle | Police | Traitement |
|---|---|---|
| **Le nombre** *(élément dominant)* | **JetBrains Mono** | **Chiffres à chasse fixe** — `FontFeature.tabularFigures()`. **Motif mesurable** : au rafraîchissement *(≥ 1×/min)* le nombre change **sans saut de mise en page** |
| Description de tuile | Inter | Discrète, en soutien — **jamais** concurrente du nombre |
| Titre « Concentration », libellés de modules | Inter | Sobriété *(RNF-03)* |

> ⚖️ **PÉRIMÉ-2026-09-08 — LA LIGNE « Description de tuile » NE DÉCRIT PLUS LE PRODUIT.** ⛔ **Elle
> n'est ni effacée ni réécrite** *(on date, on ne repeint pas)* ; ce qui la borne est écrit ici.
> *(US-01.4 — verdict clarify **nº 10** du 2026-08-21, `US-01.4-DESIGN-UX.md` §7.2 et §11.1.)*
>
> **① *« discrète, en soutien, ⛔ jamais concurrente du nombre »* est SANS OBJET PENDANT LA
> RÉVÉLATION.** Pendant les **3 s** de `fenetreRevelation`, **le nombre est ABSENT de la tuile** et la
> description occupe **SA** boîte *(le même endroit, la même boîte — AC-2 d'US-01.4)* ⇒ ⛔ **il n'y a
> rien à concurrencer.** L'énoncé reste **vrai au repos d'une tuile `ÉCHUE`**, seul cas où les deux
> cohabitent encore. ⛔ **Aucun token nouveau** *(verdict nº 10)* : c'est **le même** token de
> description, **réduit** jusqu'au plancher, puis **ellipsé** *(valeurs ci-dessous)*.
>
> **② CE QUI EST VRAI DEPUIS T13 (2026-08-29), et qui se LIT dans le code** *(`echeance_tile.dart` :
> la description au repos est peinte sous `if (temps.estEchue && description.isNotEmpty)`)* :
> * une tuile **`ACTIVE`** ⛔ **ne peint PLUS sa description au repos** — elle porte **le NOMBRE SEUL,
>   centré**. Sa description **vit dans le libellé d'accessibilité** *(**LU** :
>   `remaining_time_calculator.dart` y compose le suffixe `', <description>'`)* et **ne réapparaît à
>   l'écran qu'à la révélation, à la place du nombre** ;
> * une tuile **`ÉCHUE`** **CONSERVE la sienne EN PERMANENCE**, sous son « 0 », **alignée à gauche**
>   *(verdict clarify nº 1 : « son « 0 » n'a rien à dire, **la description est ce qui l'identifie** »)*.
>
> 🔬 **Et ce n'est pas une préférence de maquette : le retrait de la description au repos a REFERMÉ un
> débordement MESURÉ** — à **9 tuiles / 320 dp** la tuile débordait **dès ×1,6** *(une exception par
> tuile)* ; ⛔ **aucun débordement à 4 tuiles, à 390 dp, ni à ×1,5** ; et **sans description, aucun
> débordement même à ×3,0**. **C'est cette mesure qui a désigné la cause, donc le remède.**

### Valeurs de typographie — **AJOUTÉES le 2026-09-08** *(US-01.4, §G-8)*

> 🔴 **POURQUOI CETTE TABLE EXISTE : elle referme un DÉFAUT, ⛔ elle ne range pas.** Ce document se
> déclare **autorité sur les VALEURS** *(en-tête)* et `concentration_tokens.dart` écrit *« Ce fichier
> n'est pas l'autorité : `DESIGN_SYSTEM.md` l'est »* — or la table §Typographie ⛔ **ne donnait AUCUNE
> valeur** jusqu'à aujourd'hui ⇒ **la retouche de la taille du nombre *(AC-1 d'US-01.4)* se faisait à
> l'aveugle.** ⛔ **Les nombres ci-dessous sont LUS dans le code**, jamais recopiés d'un document.

| Rôle | Valeur | Projection en Dart | Ce qui la borne |
|---|---|---|---|
| **Nombre d'une tuile `ACTIVE`** | **64** *(w700, `height: 1`)* | `ConcentrationTheme.tailleNombre` | ⛔ **ne pas dépasser 64 sans rejouer le calcul ci-dessous** |
| **Nombre d'une tuile `ÉCHUE`** | **48** — ⛔ **celle d'US-01.1, INCHANGÉE** | `ConcentrationTheme.tailleNombreEchue` | 🔴 **C'est une DÉCISION, pas un reste** : l'échue garde **sa description sous son « 0 »** ⇒ un nombre agrandi **la pousserait hors de la tuile**. ⇒ **le nombre agrandi ET le centrage sont réservés aux `ACTIVE`** |
| **Description de tuile** *(repos d'une échue, et révélation)* | **13** *(w400)* | `ConcentrationTheme.styleDescription` | ⛔ **aucun second token de description** *(verdict nº 10 — deux tokens dériveraient)* |
| **Plancher de la description RÉVÉLÉE** | **11** | `ConcentrationTokens.plancherDescriptionRevelee` | 🔴 Le plancher **EFFECTIF** est **`11 × échelle utilisateur`** *(**22** à ×2,0)* ⇒ **ratio de réduction maximal `11/13`** : ⛔ **la réduction porte sur la taille de DESIGN, JAMAIS sur le facteur d'échelle** — un ajustement qui « ferait rentrer » le texte en annulant le réglage système **reprendrait d'une main ce que l'accessibilité donne de l'autre** *(SC 1.4.4)*. Au-delà : **ellipse**, et le texte complet reste **en gestion** et dans le **libellé d'accessibilité**, où ⛔ aucune troncature n'a lieu |
| **Message d'écriture** | **14 / w500** | `ConcentrationTheme.tailleMessage` | ⛔ **la COULEUR n'est PAS dans le style** : elle est apposée **par appel** *(c'est le seul paramètre que le ton change)* |

🔴 **LA BORNE DES 64 EST UN CALCUL, ⛔ PAS UN GOÛT — et le produit la porte déjà** *(docstring de
`tailleNombre`)* : à **4 tuiles sur 320 dp**, la boîte de contenu vaut **110 dp** ; un nombre à
**3 chiffres** *(⛔ le nombre d'années **n'est pas borné**)* mesure **≈ 115 dp à 64** contre
**≈ 130 dp à 72** **[ESTIMATION : 0,6 em par chiffre en chasse fixe]** ⇒ **72 déclencherait
`scaleDown` dans un cas courant**, quand **64 le laisse au bord**.
⇒ **la taille s'augmente dans le TOKEN**, et `BoxFit.scaleDown` **reste le FILET** *(c'est lui qui a
fermé le débordement à 9 tuiles)*. ⛔ **`BoxFit.contain` est INTERDIT** : il **agrandit** aussi, donc
la taille du glyphe dépendrait du **nombre de chiffres** et `10 → 9` **doublerait** le chiffre au
rafraîchissement — **9 tuiles porteraient 9 tailles différentes**.

🔬 **PRÉCISION DATÉE-2026-09-08 SUR LES CHIFFRES TABULAIRES, parce que la formulation de la 1ʳᵉ ligne
de la table promet plus que la mécanique ne donne** *(et c'est vrai **depuis US-01.1** — ⛔ ce n'est
pas un défaut d'US-01.4)* : `FontFeature.tabularFigures()` garantit que **deux nombres du MÊME nombre
de chiffres occupent la même largeur** ; ⛔ **elle ne garantit RIEN quand le nombre de chiffres
CHANGE** — `FittedBox(scaleDown)` réduit alors le glyphe, donc **la taille rendue varie** au passage
`10 → 9`. **Ce que la phrase protège réellement est la MISE EN PAGE** *(la boîte, elle, ne bouge
pas)*, ⛔ **pas la taille du glyphe**. Et ⛔ **aucun token ne pourrait supprimer cette variation** :
3 chiffres sont possibles, et aucune taille ne les fait tous tenir.

⛔ **L'unité ne s'écrit JAMAIS en pixels** *(RF-01)* : ni suffixe, ni exposant, ni fraction, ni signe.
Elle n'existe **que** dans le `semanticLabel` d'accessibilité.
⚠️ **Tailles de police système respectées** : le nombre doit rester lisible **et la tuile ne doit pas
casser** quand l'utilisateur agrandit la police du système *(AC-8)*.

## Composants réutilisables

| Composant | Emplacement | États couverts |
|---|---|---|
| **Tuile d'échéance** | `echeance_tile.dart` | **rempli** *(nombre + description)* · **description vide** *(le nombre reste)* · **« à zéro »** *(échue)* |
| **Grille** | `echeances_grid.dart` | **1 à 9 tuiles** · **vide → placeholder** · **donnée illisible → tuile ignorée**, grille intacte |
| **Placeholder d'état vide** | `empty_echeances_placeholder.dart` | **vide** uniquement |
| **Entrée de module** | hub | **actif** · **grisé non-interactif** |

⛔ **Aucun état « chargement »** : les données sont **injectées en mémoire** au périmètre d'US-01.1 — un
spinner serait un mensonge d'interface. ⛔ **Aucun état « erreur » visible** : une donnée illisible est
**ignorée silencieusement**, le hub reste debout *(AC-1/AC-3 « Erreur »)*.

> ⚖️ **PÉRIMÉ-2026-09-08 SUR DEUX POINTS *(US-01.4)*, et ils sont datés ici parce que le DÉFAUT a une
> EXTENSION** : la même modification de produit *(T13)* rend faux **un énoncé de §Typographie ET une
> cellule de cette table** — *« corriger le défaut, pas le renvoi »*. ⛔ **Rien n'est réécrit.**
>
> **① « Tuile d'échéance — **rempli** *(nombre + description)* »** ne décrit plus qu'un cas :
> une tuile **`ACTIVE`** porte **le nombre SEUL** *(voir §Typographie, amendement daté)*. **Les
> QUATRE états de rendu** sont désormais : **repos actif** *(nombre seul, centré)* · **révélé**
> *(description **à la place** du nombre, 3 s)* · **actif sans description** *(nombre seul, ⛔ **et
> aucune enveloppe interactive** : rien à révéler ⇒ **la tuile est nommée mais NON activable**, ⛔
> jamais un gestionnaire vide)* · **échue** *(« 0 » + description **en permanence**, alignés à
> gauche)*. **Un SEUL geste pointeur par tuile** *(appui simple sur une `ACTIVE`, double appui sur une
> `ÉCHUE`)* et **un anneau de focus bicolore**.
> ⛔ **La marque « sur la grille » / « retirée de la grille » n'est PAS sur la tuile** *(**LU** :
> elle vit dans la **carte de gestion**, `LigneEcheance`)* — et c'est **un MOT dans le texte
> visible**, ⛔ jamais une couleur, ⛔ jamais un `tooltip` seul.
>
> **② « ⛔ Aucun état « erreur » visible »** reste vrai **pour son objet** *(une donnée illisible est
> **toujours** ignorée en silence)* et **il est FAUX comme énoncé général depuis US-01.4** : le hub
> porte désormais une **zone de message**, **montée en permanence** *(sa hauteur est **réservée**, ⛔
> pour que l'apparition d'un message **ne décale JAMAIS les tuiles**)*, `liveRegion`, ⛔ **jamais
> fugace** *(⛔ pas de `SnackBar`)*, qui dit **qu'un retrait n'a pas eu lieu**.
> ⚖️ **ET SA COULEUR EST UN ARBITRAGE, pas un oubli** *(**LU** dans `hub_page.dart`)* : ⛔ **AUCUNE
> couleur d'erreur sur le hub** — le ton y est `texteSurFond`, ⛔ **pas `erreur`** — parce que
> l'interdiction du rouge d'US-01.1 porte sur *« les tuiles **et l'ambiance de pratique** »*, **et le
> hub EST l'ambiance de pratique**. ⇒ **le message porte un MOT et une FORME** *(le glyphe ⚠)*, ⛔
> **jamais une couleur seule** *(règle permanente : trois tokens à **1,00:1** entre eux)*.

### Composants **AJOUTÉS le 2026-08-06** *(US-01.2 — anatomie complète dans [`US-01.2-DESIGN-UX.md`](US-01.2-DESIGN-UX.md))*

| Composant | Emplacement prévu | États couverts |
|---|---|---|
| **Carte d'échéance** | `presentation/widgets/ligne_echeance.dart` | **active** *(nombre + unité)* · **échue** *(« Échéance atteinte » + liseré)* · **description vide** *(la date monte en ligne de titre)* |
| **Bouton principal** | gestion + formulaire + dialogue | **disponible** *(plein)* · **indisponible mais ACTIVABLE** *(contour + message)* — ⛔ **jamais « désactivé »** |
| **Champ de saisie** | `presentation/widgets/formulaire_echeance.dart` | **vide** · **rempli** · **en erreur** · **focus** |
| **Message de validation** | sous le champ visé, ou en tête de formulaire | **absent** · **présent** *(`liveRegion`)* |
| **Dialogue de confirmation** | `presentation/widgets/confirmation_suppression.dart` | un seul état — **seul acte destructif du produit** |

📌 **Règle née d'US-01.2, et elle vaut désormais partout : ⛔ AUCUNE BARRIÈRE MUETTE.** Toute règle qui
refuse est **atteignable par un geste** et **rend un message**. Motif **mesurable** : deux scénarios du
`.feature` normatif disent *« je **tente** de créer une dixième »* et *« je **tente** de modifier cette
échéance »* — un bouton **désactivé** rendrait ces deux clauses **inobservables**.

✅ **`⛔ Aucun état « chargement »` est CONFIRMÉ pour US-01.2, mais pour un motif DIFFÉRENT** *(la
ligne ci-dessus reste vraie à sa date, et n'est pas repeinte)* : les données ne sont plus « en
mémoire », elles viennent **du disque** — mais la composition se fait **dans `main()` seul, avant
`runApp`**, donc **le premier rendu a déjà les données**. ⚠️ **Réfutation** : l'apparition d'un
indicateur de progression signifierait que la composition a quitté `main()`.

## Wireframes textuels — mobile-first

```
┌─────────────────────────────┐   État NOMINAL (mobile, dark)
│  Concentration              │ ← top bar, texte #F2DFD5 sur #1B110C
├─────────────────────────────┤
│  ┌───────┐ ┌───────┐        │   Grille 2 colonnes en mobile,
│  │  3    │ │  9    │        │   3 colonnes à partir de md
│  │ projet│ │ impôts│        │   Tuile CARRÉE, fond = gradientFor(p),
│  └───────┘ └───────┘        │   nombre nu en JetBrains Mono,
│  ┌───────┐ ┌───────┐        │   description discrète dessous
│  │  0    │ │  12   │        │   ← « 0 » = état à zéro, EN TÊTE
│  └───────┘ └───────┘        │
├─────────────────────────────┤
│  ⏳ Échéances   ○ Respiration │ ← module ACTIF + modules GRISÉS
│                 ○ Concentration│   (non-interactifs)
└─────────────────────────────┘
```

> ⚖️ **PÉRIMÉ-2026-09-08 *(US-01.4, T13)* — ⛔ le wireframe n'est PAS redessiné** *(on date, on ne
> repeint pas ; un schéma repeint efface la trace de ce qu'on croyait)*. **Ce qui est faux, tuile par
> tuile — et il y a DEUX erreurs de sens OPPOSÉ, ce que « la description a bougé » ne dirait pas** :
> * **`3 / projet` et `9 / impôts`** *(actives **avec** description)* ⇒ 🔴 **FAUX** : une tuile
>   `ACTIVE` porte **le nombre SEUL, centré**. La légende *« description discrète dessous »* est donc
>   **fausse pour ces deux-là**, et sa description ne vit plus qu'au **libellé d'accessibilité**, puis
>   **à la place du nombre** pendant la révélation ;
> * **`0`** *(échue, dessinée **sans** description)* ⇒ 🔴 **FAUX DANS L'AUTRE SENS, et c'est
>   l'erreur qu'on ne cherchait pas** : une **`ÉCHUE` CONSERVE sa description en permanence** ⇒ **il
>   en MANQUE une** sous ce « 0 ». *(La note *« « 0 » = état à zéro, EN TÊTE »*, elle, **reste
>   vraie**.)* ;
> * **`12`** *(active, dessinée sans description)* ⇒ ✅ **conforme à la règle actuelle** — ⚠️ **par
>   coïncidence**, ⛔ pas parce que ce schéma l'avait prévu.
> ➡️ **Rendus à jour** : [`US-01.4-DESIGN-UX.md`](US-01.4-DESIGN-UX.md) §3.2 à §3.6 *(dont la **zone de
> message** du hub, **absente** de ce schéma)*.

```
┌─────────────────────────────┐   État VIDE (AC-9)
│  Concentration              │
├─────────────────────────────┤
│                             │
│   Aucune échéance pour      │ ← message sobre, texte #F2DFD5
│   l'instant.                │   ⛔ pas de rouge, pas d'illustration
│                             │      guillerette, pas de gamification
├─────────────────────────────┤
│  ⏳ Échéances   ○ ...        │ ← le hub et sa structure RESTENT
└─────────────────────────────┘
```

### Placement des modules futurs — la décision qu'AC-2 me déléguait

**Retenu : barre basse, avec les modules futurs en entrées estompées** *(et non des tuiles grisées dans la
grille)*.
**Motif** : AC-3 exige que **9 tuiles restent embrassables d'un regard** ; insérer deux tuiles grisées
dans la même grille **volerait de la surface au contenu** et rendrait le comptage « 1 à 9 » ambigu à
l'œil. La barre basse **montre la vision produit sans concurrencer la grille**.
⛔ **Non-interactifs par ABSENCE de gestionnaire** — jamais par un `onTap` vide
*([ADR-004](../adr/ADR-004-registre-modules-hub.md))* : `Semantics(enabled: false)`, **aucun retour visuel
d'appui**, aucune ondulation.
⚠️ **Ce placement n'est PAS dans le registre** : le registre porte **ordre et statut**, jamais la position
— c'est ce qui permettra de le déplacer sans toucher au domaine.

## Accessibilité (WCAG AA)

- **Contraste** : texte normal **≥ 4,5:1**, texte large **≥ 3:1**. ✅ **Vérifié par calcul sur 101 points
  du dégradé** *(voir §Palette)* — **pire cas 4,53:1**. ⛔ Ce n'est **pas** une intention : c'est une mesure,
  et elle doit être **rejouée** à chaque retouche de token.
- **Lecteur d'écran** : chaque tuile porte le **temps complet AVEC son unité** *(« 3 ans, préparation du
  projet »)* alors que l'écran n'affiche que le nombre — c'est le **seul** endroit où l'unité devient un mot.
- **Modules grisés** : `Semantics(enabled: false)` — ⛔ **ne jamais** les annoncer actionnables.
- **Tailles système** respectées *(pas de taille de police figée en dur pour la description)*.
- ⚠️ **Navigation clavier et focus visible : SANS OBJET au périmètre d'US-01.1**, et je le dis plutôt que
  de cocher une ligne générique — **il n'existe aucun élément interactif** *(aucun bouton actif, aucun
  champ)*. Cette exigence redeviendra due dès **US-01.2** *(CRUD)*. ⛔ **Aucun label ARIA de formulaire**
  n'est requis ici, pour la même raison.
  ✅ **ÉCHUE-2026-08-06 : l'exigence est DUE et elle est servie.** *(La ligne ci-dessus reste vraie à sa
  date — on date, on ne repeint pas.)* US-01.2 introduit **cinq surfaces interactives**, donc
  **15 exigences chiffrées** *(A-1 → A-15)* dans [`US-01.2-DESIGN-UX.md`](US-01.2-DESIGN-UX.md), §7.
  ✅ **COMPLÉTÉ-2026-09-08 *(US-01.4)*, et la borne du complément de 2026-08-06 doit être lue** : les
  15 exigences d'US-01.2 servent **ses cinq surfaces**, ⛔ **jamais la TUILE**, qui devient ici le
  **premier élément interactif de la grille** ⇒ **clavier, focus visible et cible tactile sont dus
  pour la tuile**, et sont chiffrés en **A-16 → A-26** dans
  [`US-01.4-DESIGN-UX.md`](US-01.4-DESIGN-UX.md) §8. **La géométrie de l'anneau est au §Surfaces
  interactives ci-dessus** *(elle ⛔ **n'est pas** celle d'A-7 — voir son amendement daté)*.

### ⚖️ Registre des écarts WCAG déclarés — **CRÉÉ le 2026-09-08** *(US-01.4)*

> 🔴 **POURQUOI CE REGISTRE EXISTE, et c'est un défaut de ce document qu'il referme.** Ce fichier
> affirme « **WCAG AA** » *(titre du §Accessibilité, RNF-06)* et ⛔ **ne tenait AUCUN registre
> d'écarts** ⇒ **l'affirmation était plus large que la mesure**, et laissée telle quelle elle
> devenait **une entrée réfutée par le corpus qu'elle résume**. ➡️ **Toute lecture de « WCAG AA » dans
> ce document se fait AVEC ce registre.**
>
> ⛔ **RÈGLES DE TENUE — elles font partie du registre, pas de son introduction** :
> * une entrée ⛔ **ne migre JAMAIS vers les bornes `NM-*`** — *« on ne sait pas mesurer »* **n'est
>   pas** *« on ne se conforme pas »* : confondre les deux transforme un **écart assumé** en
>   **lacune d'instrument**, et le fait disparaître ;
> * une entrée se **ferme** par une **mesure** ou une **décision datée**, ⛔ **jamais par
>   suppression** — et sa ligne **reste** *(on date, on ne repeint pas)* ;
> * ⛔ **il n'est écrit NULLE PART qu'une entrée de ce registre est CONFORME** — un écart déclaré
>   **est** une non-conformité assumée, et l'écrire autrement serait le blanchir ;
> * une entrée nomme **ce qu'il faudrait pour la LEVER** : sans cette colonne, un écart n'a **aucun
>   critère de sortie** et se transmet indéfiniment.

| # | Critère WCAG | Niveau | Surface concernée | Ce qui s'en écarte *(mesuré / lu)* | Motif de l'écart | Déclaré le | **Ce qu'il faudrait pour le LEVER** |
|---|---|---|---|---|---|---|---|
| **É-1** | **SC 2.2.1 « Timing Adjustable »** | **A** — ⚠️ **donc INCLUS dans AA** | **révélation de la description** sur une tuile `ACTIVE` *(US-01.4, AC-2)* | La description est remplacée par le nombre au bout de **3 s** *(`ConcentrationTokens.fenetreRevelation` — **LU**)*. Ce délai ⛔ **n'est ni désactivable, ni ajustable, ni prolongeable** : il n'existe **aucune page de réglages** *(« Réglages » est **inerte** depuis US-01.2)*. Le geste est **ré-appuyable sans limite** *(la fenêtre redémarre)*, et ⛔ **le ré-appui n'est AUCUNE des exceptions littérales du SC** | **Décision humaine du 2026-08-21** *(gate clarify, option (a) : 3 s + ré-appui illimité)*. **Ce que le produit tient malgré l'écart** : ⛔ rien n'est **définitivement perdu** *(le texte complet est en gestion et dans le libellé d'accessibilité)*, et la fenêtre ⛔ **n'est ni interrompue ni prolongée** par le rafraîchissement de la grille *(AC-2 « Limite »)*. **Ce que l'écart achète** : la grille **reste l'exercice** — un affichage permanent la dissoudrait en liste de libellés. ➡️ **Décision et motif COMPLETS** : [Story File d'US-01.4](../stories/US-01.4-gestes-tuile.md) §⚖️ *Écart déclaré à WCAG 2.2.1* — ⚠️ **cette cellule le RÉSUME, elle ne le remplace pas** *(et c'est le 3ᵉ exemplaire de cette entrée : ⛔ **le registre est l'INDEX, le Story File porte la décision**)* | **2026-08-21** *(inscrit ici le **2026-09-08**)* | **Une durée réglable** *(⇒ activer « Réglages », classé **Could (V2)**)*, **ou** une option *« la description reste jusqu'au prochain appui »* *(⇒ elle **dissoudrait** le SC au lieu de le satisfaire, et **contredit la lettre** de la décision du 2026-08-21)*. ⛔ **Aucune des deux voies n'est ouverte au MVP** — l'écart est donc **ouvert, et il reste ouvert** |

⛔ **Ce que ce registre n'est PAS** : il ⛔ **ne contient aucune borne de mesure** *(celles-là sont les
`NM-*` des Story Files : **NM-12** « l'annonce réelle d'un lecteur d'écran », **NM-13** « le focus
**vu** »)*, et ⛔ **aucun contraste** — les contrastes de ce document sont **calculés**, donc ils sont
soit **tenus**, soit **des refus documentés** *(voir les trois refus du §Palette)*, ⛔ jamais des
écarts.

### Exigences chiffrées des surfaces interactives — **2026-08-06** *(US-01.2)*

| Exigence | Valeur | Référence |
|---|---|---|
| Contraste texte normal / texte large / **non textuel** | **≥ 4,5:1** · **≥ 3:1** · **≥ 3:1** | SC 1.4.3 · SC 1.4.11 |
| **Cible tactile** | **≥ 48 × 48 dp**, **sauf** la commande de barre basse : **≥ 40 × 48 dp** *(exception **déclarée** : élargir ce `Row` a déjà coûté un débordement de 63 px ; WCAG 2.2 SC 2.5.8 n'exige que **24 × 24**, donc le seuil normatif reste **largement** tenu)* | Material · SC 2.5.8 |
| Écart entre deux cibles adjacentes | **≥ 8 dp** | prévention du mé-appui près d'un acte destructif |
| **Échelle de texte** supportée | **jusqu'à ×2,0**, sans troncature ni chevauchement | SC 1.4.4 |
| **Focus visible** | anneau **2 dp**, décalage **2 dp**, `moduleActif`, **≥ 3:1** contre les **deux** surfaces adjacentes | SC 2.4.7 |
| **Clavier** | tout interactif atteignable, ordre haut→bas / gauche→droite, ⛔ aucun piège ; **focus capturé** dans le dialogue, **focus initial sur « Annuler »**, **Échap = Annuler** | SC 2.1.1, 2.1.2, 2.4.3 |
| **Libellés** | libellé **visible en permanence** ⛔ **jamais un `placeholder`** ; `Semantics` portant le nom **et** « obligatoire »/« optionnel » | SC 1.3.1, 3.3.2 |
| **Message d'erreur** | `liveRegion`, **ancré sous le champ visé**, **le focus s'y déplace** | SC 3.3.1, 4.1.3 |
| **Nom d'une action de liste** | contient **la description de l'échéance** *(9 boutons « Modifier » sont 9 boutons indistinguables)* | SC 2.4.6 |
| **Jamais la couleur seule** | tout état porte **un mot ou une forme** | SC 1.4.1 — **rendu obligatoire ici par la mesure** *(3 tokens à 1,00:1 entre eux)* |
| **Mouvement** | **0** animation en US-01.2 *(RF-06 est **US-01.4**)* | SC 2.2.2, 2.3.1 |

> ⚖️ **PÉRIMÉ-2026-09-08 — DEUX LIGNES DE LA TABLE CI-DESSUS.** ⛔ **Aucune n'est réécrite.**
>
> **① « Focus visible — anneau 2 dp, décalage 2 dp, `moduleActif`, ≥ 3:1 contre les deux surfaces
> adjacentes » est FAUSSE SUR UN FOND EN DÉGRADÉ** *(US-01.4, §G-10)*. Elle **reste vraie pour les
> cinq surfaces d'US-01.2**, dont les fonds sont **FIXES** *(`fondApp`, `surfaceElevee`)*.
> **Mesuré** : `moduleActif` contre le dégradé rend **1,36:1**, **101/101 points sous 3:1** ⇒ sur une
> tuile, **l'anneau est BICOLORE**, **décalage 0**, bande intérieure **PEINTE**
> *(géométrie, mesures et contrôle négatif : §Surfaces interactives ci-dessus)*.
> ⚠️ **Et le défaut de forme mérite d'être nommé, il n'est pas anecdotique** : **cette exigence
> existait en DEUX exemplaires** — cette ligne **et** **A-7** de
> [`US-01.2-DESIGN-UX.md`](US-01.2-DESIGN-UX.md) §7 — donc **il a fallu la dater DEUX FOIS**. *« Une
> règle n'existe qu'en un seul exemplaire ; deux copies dérivent. »* ➡️ **La géométrie de l'anneau
> n'est écrite QU'À UN endroit** *(§Surfaces interactives)*, et les deux lignes y **renvoient**.
>
> **② « Mouvement : 0 animation en US-01.2 (RF-06 est US-01.4) » est ÉCHUE PAR SA PROPRE PRÉVISION** :
> ⛔ **elle n'a pas été réfutée, elle avait daté son terme** — et **l'animation arrive ici**. Elle
> reste **exacte pour US-01.2**. **Exigence chiffrée, valeurs LUES dans le code** :

| Grandeur | Valeur | Projection en Dart | Motif — ⛔ aucun n'est un goût |
|---|---|---|---|
| **Objet animé** | **la disparition d'une échue RETIRÉE**, et **rien d'autre** | `EcheancesGrid` | 🔴 **L'animation est FONCTIONNELLE : elle REMPLACE la modale** *(arbitrage du 2026-08-03 — le geste n'est pas destructif, une modale frictionnerait le geste le plus fréquent au profit d'un acte sans conséquence)*. ⇒ **une seule** animation dans **tout le produit** |
| **Durée** | **200 ms** | `ConcentrationTokens.dureeDisparition` | **Deux bornes, pas une préférence** : en dessous d'**≈ 120 ms** l'œil enregistre une **disparition sèche** *(l'animation cesserait d'être le feedback)* ; au-delà d'**≈ 300 ms** elle **frictionne** le geste le plus fréquent. ⛔ **Ne pas la changer sans rejouer ce raisonnement** |
| **Courbe** | **ACCÉLÉRÉE** *(`Curves.easeIn`)* | `ConcentrationTheme.courbeDisparition` — ⚖️ **dans le THÈME, pas dans les tokens** *(motif mesuré : `concentration_tokens.dart` n'importe **aucune** bibliothèque Flutter, et `Curves` en exige une)* | **une sortie PART.** Une courbe **décélérée** ferait **s'attarder** la tuile — elle dirait *« je m'en vais… ou pas »*. ⛔ **`elastic*` et `bounce*` sont INTERDITS** *(rebond, dépassement — RNF-03)* |
| **Propriétés animées** | **opacité 1 → 0** **et** **échelle 1 → 0,92** | `ConcentrationTokens.echelleDisparition` | ⛔ **AUCUN déplacement, aucune rotation, aucun clignotement** : un glissement suggérerait *« ça va quelque part »*, or l'échéance **reste en gestion** |
| **Recomposition de la grille** | ⛔ **SÈCHE, jamais animée** | — | passer de 5 à 4 tuiles fait passer la grille de 3 à 2 colonnes : **animer cela** ferait bouger **les tuiles voisines**, donc **la surface sous le doigt** |
| **« Animations réduites »** | **durée NULLE**, et ⛔ **AUCUNE enveloppe d'animation montée, À AUCUN INSTANT** | `MediaQuery.disableAnimationsOf` ⇒ `Duration.zero` | 🔴 **MESURÉ à T14, et la nuance est tout l'enjeu** : *« départ immédiat »* veut dire ⛔ **aucune enveloppe**, ⛔ **pas « une animation très courte »** — l'enveloppe n'est montée **que** si le contrôleur a **effectivement démarré** *(`isAnimating`)*, ce qui rend **« aucune animation ne se joue » OBSERVABLE** au lieu d'être déduit d'une opacité |
| 🔴 **ORDRE — c'est une EXIGENCE, pas un détail d'implémentation** | **l'écriture ABOUTIT d'abord, l'animation ENSUITE** | — | ⛔ **Un retrait dont l'écriture ÉCHOUE ne joue AUCUNE animation** *(la tuile est à sa place, avec son nombre et sa couleur ; c'est le **message** qui informe)*. ⛔ **Aucune mise à jour optimiste**, et ⛔ **l'animation n'est JAMAIS la condition du résultat** : aucune attente d'animation sur le chemin d'écriture — sinon un retrait **sans** animation serait un **retrait perdu** |

> ⚠️ **Ce que cette exigence NE lève PAS** : la **fluidité perçue** *(NM-3)* et le **déclenchement
> accidentel réel** *(NM-11)* — ⛔ elles exigent **un appareil** et **un doigt**, et ⛔ **aucune
> assertion de ce document ne les remplace**.

⚠️ **Bornes non levées, rappelées** : **NM-6** *(l'annonce **réelle** d'un lecteur d'écran)* et **NM-7**
*(l'**œil**, et le rendu réel à grande police)* — elles ne se lèveront qu'avec **US-01.3**.

## Dark mode

**Mode sombre de référence FORCÉ** au MVP : `themeMode: ThemeMode.dark`, fond `#1B110C`.
⛔ **Aucune bascule clair/système** *(AC-8)* — et donc **aucun token de thème clair n'est défini** : en
définir serait prétendre qu'un mode clair est supporté.
⚠️ **Conséquence assumée** : si l'appareil est en mode clair, l'application **reste sombre**. C'est un
choix produit *(sobriété, RNF-03)*, à réexaminer quand un mode clair sera réellement demandé.

**Complément 2026-08-06 *(US-01.2)*** : ⛔ **aucun équivalent clair n'est défini pour les 4 tokens
ajoutés** — même motif. 🔴 **Et une conséquence NOUVELLE, qui a un coût réel** : **tout composant natif
de plateforme rendrait un thème CLAIR par défaut** *(`showDatePicker`, `showTimePicker`)*, en plus
d'afficher des **chaînes anglaises** faute de `flutter_localizations` *(que l'ADR-009 interdit
d'ajouter)*. ⇒ **les sélecteurs natifs sont écartés au profit de champs de saisie**
*(`JJ/MM/AAAA`, `hh:mm`)*. **Arbitrage recommandé, non tranché par @UXDesigner** :
[`US-01.2-DESIGN-UX.md` §9.2 et §11.5](US-01.2-DESIGN-UX.md).

**Complément 2026-09-08 *(US-01.4)*** : ⛔ **aucun équivalent clair** pour les tokens de cette US —
**même motif**, ⛔ inchangé. 🔴 **Mais l'anneau de focus bicolore rend ce point PLUS RIGIDE qu'avant,
et il faut le dire avant que quelqu'un ne le découvre** : la **bande intérieure de l'anneau EST
`fondApp`**, c'est-à-dire **la couleur du mode sombre**, et son contraste est calculé **contre le
dégradé**. ⇒ **un mode clair ne se contenterait pas de nouveaux tokens : il obligerait à REJOUER le
calcul de l'anneau sur 101 points**, et rien ne garantit qu'une couleur claire y tiendrait les deux
côtés *(c'est exactement ce qui échoue aujourd'hui pour `moduleActif`)*. ⛔ **À inscrire au jour où un
mode clair sera demandé, pas avant** — et ⛔ **ce n'est PAS une raison de refuser un mode clair** :
c'est le **coût** à connaître.

---

## 📌 Note de cohérence sur ADR-003, portée par @UXDesigner

[ADR-003](../adr/ADR-003-degrade-temporel-espace-colorimetrique.md) présente son choix d'OKLab comme un
« **écart explicite avec la lettre du PRD, qui écrit OKLCH** ». ⚠️ **La formule est trop forte, et la
nuance est consignée ici plutôt que dans l'ADR — un ADR Accepté est IMMUABLE** : le PRD écrit en réalité
« *espace colorimétrique **à définir en design**, ex. OKLCH* ». Le choix d'ADR-003 est donc **dans la
latitude que le PRD délègue**, et l'« écart » porte sur un **exemple**, non sur une prescription.
⛔ **Le raisonnement d'ADR-003 reste entièrement valide** *(l'arc polaire le plus court passe par le rouge,
qu'AC-5 interdit)* — seule sa qualification de « lettre du PRD » est excessive.

### 🔴 SECONDE correction, plus sérieuse, établie par MESURE le 2026-08-01

ADR-003 affirme que le rouge devient **« inatteignable par construction »**. ⛔ **C'est FAUX au sens de la
TEINTE, et c'est un test écrit pour le vérifier qui l'a établi** : le segment cartésien **croise bel et
bien** la direction de teinte rouge — **15 points sur 101**, `p` de **0,37 à ~0,51** — parce qu'il passe
près du neutre, où `b` change de signe **avant** `a`.

**Ce qui est VRAI, et qui est la garantie réelle** :

| | Chroma mesurée |
|---|---|
| Extrémités du dégradé *(orange 50,4° / bleu 257,6°)* | **0,164** et **0,154** |
| **Maximum dans le secteur de teinte rouge** | **0,059** |

✅ **LE MILIEU DÉSATURÉ EST ACCEPTÉ — décision humaine du 2026-08-01, prise APRÈS avoir vu le rendu réel.**
L'application a été lancée et capturée : à `p` intermédiaire la tuile est **franchement mauve**, et elle ne
lit **pas** comme « entre orange et bleu » mais comme *une autre couleur*. **L'humain l'a regardée et l'a
validée.** ⇒ ⛔ **Le sujet est CLOS** : le trajet **OKLab cartésien** reste celui d'ADR-003, et toute
réouverture exigerait un **nouvel ADR** *(trajet polaire préservant la chroma, **avec** une assertion
« aucun rouge » bloquante)* — ⛔ **jamais un ajustement discret dans le code**.
📌 **Ce que cette validation vaut, et pas plus** : elle porte sur l'**effet visuel**, non sur les
contrastes — ceux-là restent tenus par le calcul *(pire cas **4,53:1**, marge **0,03 point**)*.

⇒ la traversée se fait à **moins de la moitié** de la chroma des extrémités : un **gris chaud désaturé**,
**jamais un rouge perceptible**. L'arc polaire le plus court, lui, croiserait la **même teinte à pleine
chroma** — c'est-à-dire un **vrai rouge**. **La décision d'ADR-003 reste donc la bonne ; c'est sa
formulation qui promettait plus que la géométrie ne donne.**

⛔ **L'ADR n'est PAS réécrit** *(immuable)*. Les **assertions** ont été alignées sur la garantie vraie
*(`test/core/color/temporal_gradient_test.dart` : « aucun rouge **saturé** », chroma < ½ de celle des
extrémités)*, et le commentaire de `oklab.dart` porte la même précision.
📌 **Leçon** : une formulation absolue *(« par construction »)* dans un ADR **doit être adossée à une
assertion**, sinon elle survit à sa propre fausseté. Ici l'assertion l'a rattrapée en moins d'une heure.
