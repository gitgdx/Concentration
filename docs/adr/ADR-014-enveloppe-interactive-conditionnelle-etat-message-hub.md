# ADR-014 : L'enveloppe interactive de la tuile est **CONDITIONNELLE**, et l'état du message d'échec vit dans le **HUB**

- **Date** : 2026-08-24
- **Statut** : **Accepté** *(2026-08-24 — @Architect, après relecture des §Décision A et B et **vérification indépendante de leurs fondements** : le précédent invoqué existe bien dans `hub_page.dart` *(l'absence de gestionnaire rend l'interdit assertionnable, motif littéral aux lignes 126-127)*, ADR-013 **a bien examiné et écarté** `HubPage` stateful *(L297)* et **désigne** l'objet dédié *(L369)*, et l'autotest de l'instrument de D-8 rend **exit 0** avec ses **6** vérifications toutes tuées. ⚠️ Un ADR accepté est **IMMUABLE**.)*
- **US associée** : US-01.4 (Gestes sur la tuile — RF-06), EPIC_01, track FULL
- **Remplace** : dans **[ADR-013](ADR-013-etat-interaction-grille-observabilite-gestes.md)**, et
  **uniquement** :
  1. **§Décision-3** — l'**inconditionnalité** de l'arbre publié *(« l'arbre est décidé »)*. Il reste
     **en vigueur mot pour mot** pour la tuile `ACTIVE` **avec** description et pour la tuile `ÉCHUE`
     *(les deux seules pour lesquelles il a été mesuré : sa mesure porte littéralement sur « **une tuile
     échue** »)*. ⛔ **Il ne s'applique PAS à la tuile `ACTIVE` sans description.**
  2. **§Décision-2** — la seule phrase *« ⛔ **Une assertion écrite sur le nœud sémantique rendrait AC-9
     insatisfiable** »*, et **pour la seule ligne `ACTIVE` sans description**. Son motif *(une tuile
     échue doit être activable)* est **vrai** ; il **ne transfère pas** à une tuile où il n'y a **rien à
     activer**, où asserter le nœud est au contraire **ce qu'AC-9 exige**.

  ⛔ **Rien d'autre d'ADR-013 n'est touché**, et la liste est explicite : son **§1** *(les trois états
  éphémères dans `_EcheancesGridState`, la tuile `StatelessWidget`, ⛔ rien dans `EcheancesNotifier`)* ·
  la **table des trois régimes de geste** de son §2 *(⛔ **confirmée** par la mesure ci-dessous, pas
  amendée)* · la **forme pointeur de `T-P4` pour la tuile `ÉCHUE`** · les **quatre canaux** de son §3 ·
  son **§4** *(⛔ aucun seam de durée)* · son **§5** *(le critère de licéité d'un seam)* · son **§6**
  *(l'animation est un feedback, jamais une condition)* · son **§7** *(la grille reçoit **un** rappel et
  rien de plus)*.

> **Forme suivie, avec ses précédents mesurés dans ce dépôt** : ADR-007 porte `Remplace : ADR-006` et
> **ADR-006 n'a PAS été édité** ; ADR-012 remplace **une seule puce** d'ADR-010 §2 et **ADR-010 n'a PAS
> été édité**. Un ADR accepté est **immuable** : c'est le **remplaçant** qui nomme ce qu'il remplace.
> ⛔ **ADR-013 n'est donc pas modifié.**

> ⚖️ **LA DÉCISION B N'EST PAS UN REMPLACEMENT — et son motif n'est PAS celui qu'on croit. Il faut
> être exact, parce que la version approximative est une SUR-LECTURE.**
>
> ⛔ **Ce qu'il serait FAUX de dire** : *« ADR-013 §Conséquences réclame un nouvel ADR dès le quatrième
> état éphémère, donc le message le déclenche »*. **Le déclencheur d'ADR-013 est LITTÉRAL** — *« un
> quatrième état éphémère **dans ce `State`** »*, c'est-à-dire **dans `_EcheancesGridState`**. Or la
> décision B consiste **précisément à ne PAS l'y mettre** ⇒ **la grille en garde TROIS, et le seuil
> littéral n'est PAS franchi.** *(@UXDesigner l'a lu comme franchi ; c'est une lecture large, et ce
> dépôt punit les sur-lectures.)*
>
> ✅ **Ce qui justifie réellement l'ADR, et c'est plus fort** :
> 1. **La décision B fait exactement ce qu'une ALTERNATIVE ÉCARTÉE d'ADR-013 décrit** : *« **L'état de
>    révélation dans `HubPage`** — **écarté** : `HubPage` est `StatelessWidget` et devrait devenir
>    *stateful* … »*. Rendre `HubPage` **stateful** est donc une option qu'ADR-013 a **examinée et
>    rejetée** ; la retenir — même pour un **autre** état — doit être écrit **là où le lecteur
>    d'ADR-013 ira le chercher**, avec l'examen des deux motifs du rejet. **C'est fait en B.1.**
> 2. **Le remède que désignait ADR-013** *(« il faut un objet dédié »)* est **examiné et écarté ici,
>    sur motif mesuré** — ⛔ pas ignoré.
> 3. 🔴 **La forme NAÏVE de la décision est RÉFUTÉE PAR LA MESURE** *(§Contexte 6)*, et un fait
>    contre-intuitif qui coûte un défaut d'accessibilité **ne se re-découvre pas deux fois**.

---

## Contexte

### 1 · Ce que la jointure a trouvé, et pourquoi ces deux trous ne peuvent vivre nulle part ailleurs

Les deux branches de `parallel_design` ont rendu. La jointure — **Integration Lock** — a trouvé **six**
trous ; **deux** relèvent de l'architecture, et **c'est ADR-013 qui l'établit dans les deux cas** :

| Trou | Pourquoi il ne peut pas vivre dans le Story File seul |
|---|---|
| **J-1** | Il **contredit la lettre** d'une §Décision d'un ADR **accepté donc immuable**. Une précision de Story File qui dirait le contraire d'un ADR créerait **deux sources en désaccord** — la faute que la clause d'immuabilité existe pour empêcher. **On remplace, on ne contourne pas.** |
| **J-2** | Il **retient une option qu'ADR-013 a EXAMINÉE ET REJETÉE** *(rendre `HubPage` **stateful**)* et **écarte le remède qu'ADR-013 désignait** *(un objet dédié)*. Un Story File qui ferait cela **sans le dire** laisserait le lecteur d'ADR-013 sur une alternative écartée qui, en fait, a été retenue. ⚠️ **Le seuil LITTÉRAL d'ADR-013 n'est PAS franchi** *(voir l'encadré ci-dessus)*. |

### 2 · 🔴 **J-1 — le fait, et il n'est PAS « exactement `SONDE-1` » : c'en est le MIROIR**

**Ce qui est lu dans les fichiers** :
* ADR-013 **§Décision-3** publie l'arbre *(`FocusableActionDetector` > `Semantics(button: true,
  onTap: intention)` > `ExcludeSemantics` > `GestureDetector`)* comme un bloc **sans aucune condition**,
  et sa mesure porte explicitement sur *« les quatre canaux d'**une tuile échue** »*.
* ADR-013 **§Décision-2** interdit **tout gestionnaire pointeur** sur une tuile `ACTIVE` **sans**
  description : *« c'est l'**absence** de gestionnaire qui rend **AC-3** assertable ; un `onTap` vide
  mentirait à l'accessibilité »*.

⇒ **appliqué à la lettre**, cette tuile reçoit **l'enveloppe interactive complète** et **aucun**
gestionnaire pointeur : elle **s'annonce bouton activable avec rien à activer**.

**@UXDesigner l'a nommé « exactement `SONDE-1` » — et c'est imprécis. Les deux défauts sont OPPOSÉS, et
la distinction change l'assertion.** Une sonde jetable *(hors dépôt, `.dart_tool/`, Flutter 3.44.7 /
Dart 3.12.2, 2026-08-24)* met **les deux dans la même sortie** :

```
TRIPLET|R1_rappel_sonde1        |tap=false|boutons=0|focusables=1|actions=[focus]|pointeurs=2|widgets_focus=1
TRIPLET|S1_arbre_adr013_litteral|tap=true |boutons=1|focusables=1|actions=[focus, tap]|pointeurs=0|widgets_focus=1
```

| | `SONDE-1` *(ADR-013)* | **J-1** |
|---|---|---|
| Couche pointeur | **actionnable** *(`pointeurs=2`)* | ⛔ **rien** *(`pointeurs=0`)* |
| Nœud sémantique | `tap=false`, `button=false` | `tap=true`, `button=true` |
| Focus | `focusable=1` | `focusable=1` |
| **Le défaut** | **actionnable et NON ANNONCÉ** | **ANNONCÉ et SANS EFFET** |

Les deux violent **AC-9 « Erreur »** — *le mensonge d'interface* — **par des chemins opposés**.

✅ **Et « sans effet » n'est pas déduit, il est OBSERVÉ** : l'intention est **bien invoquée**, et
**rien ne change à l'écran** :

```
EFFET|S1_arbre_adr013_litteral|voie=action_semantique_tap|invocations_intention=1
                              |texte_avant=7|texte_apres=7|texte_change=false
```

### 3 · 🔴 **LE FAIT LE PLUS COÛTEUX DE CET ADR : la forme de `T-P4` décidée par ADR-013 §2 est AVEUGLE à J-1**

ADR-013 §2 a **décidé** que l'assertion structurelle *« lit le widget **pointeur**, pas le nœud
sémantique »*. Sur la tuile `ACTIVE` sans description, **le défaut est ENTIÈREMENT dans les couches
sémantique et focus** — la couche pointeur est, elle, **exactement conforme**.

**Mesuré** : l'assertion `A1_aucun_gestionnaire_pointeur` — c'est-à-dire **la forme prescrite par
ADR-013 §2** — est **VERTE sur `S1`**, la source qui **porte le défaut** *(`pointeurs=0`)*.

⇒ ⛔ **Un `T-P4` écrit dans la forme prescrite passerait, et J-1 partirait en développement.** C'est la
raison pour laquelle cet ADR ne peut pas se contenter de dire « pas d'enveloppe » : **il doit dire
COMMENT on l'asserte**, sans quoi la décision est **inobservable**.

### 4 · ⚠️ **Piège de mesure trouvé EN MESURANT, à ne pas re-payer** : `isFocusable` **ne vit PAS sur le nœud du label**

La **première** version de la sonde lisait `isFocusable` sur le nœud rendu par
`find.bySemanticsLabel(…)`. Elle a rendu `focusable=false` sur **toutes** les sources, y compris celles
qui portent un `FocusableActionDetector` — et l'assertion correspondante **n'a JAMAIS rougi**
*(`jamais_tuees=[A4_pas_focusable]`)*.

**Cause mesurée** : le drapeau vit sur le nœud **ANCÊTRE**, celui de `Focus`, que
`find.bySemanticsLabel` **ne rend pas**. ⇒ ⛔ **une assertion écrite sur « le nœud du label » est
aveugle à la focusabilité**, et elle serait **verte à tort**. La sonde lit désormais **l'union des
drapeaux et des actions sur TOUS les nœuds** du sous-arbre.

✅ **Second fait non anticipé, conservé parce qu'il change une assertion** : **un nœud de `Focus`
PUBLIE l'action sémantique `focus`** *(`S3` et `R1` : `actions=[focus]`)*. Une assertion
« aucune action sémantique » est donc violée par **la seule présence d'un nœud de focus** — ce qui la
rend **plus forte** que prévu, et non plus faible. ⛔ **Les deux faits ont été DÉCLARÉS À TORT avant la
mesure, et c'est la mesure qui a tranché** : les attentes de la sonde ont été **corrigées et datées
dans la sonde même**, ⛔ pas la mesure.

### 5 · 🔴 **J-2 — le message d'échec est un QUATRIÈME état éphémère, et il n'a de place NULLE PART**

`MessageEcriture` *(@UXDesigner §5)* : composant **nouveau**, **hauteur réservée en permanence**
*(`Visibility(maintainSize: true)`, motif de **sûreté** : ⛔ zéro reflux, un double appui égaré
retirerait la **mauvaise** échéance, et **un retrait est irréversible**)*, **aucune durée**, ⛔ **aucune
couleur d'erreur sur le hub**, texte **toujours** un `message` du port.

**Les trois places disponibles sont fermées, chacune par un motif écrit** :

| Place | Pourquoi elle est fermée |
|---|---|
| `_EcheancesGridState` | ADR-013 **§7** : la grille reçoit **un rappel et rien de plus**. Et ce serait le **quatrième** état éphémère — **le seuil qu'ADR-013 a nommé**. ⚠️ Ajout décisif : la zone de message est rendue **HORS de la grille** *(dernier enfant du corps du hub, entre la grille et la barre basse)* ⇒ ⛔ **la grille ne peut même pas la peindre.** |
| `EcheancesNotifier` | **Le motif MÊME par lequel ADR-013 §1 a refusé d'y mettre la révélation** : source de vérité **adossée au disque**, écoutée par **deux** écrans ⇒ le message **survivrait à la navigation** et ferait **notifier la page de gestion** pour un effet local. |
| `HubPage` | **`StatelessWidget` [LU]** *(`lib/features/hub/presentation/hub_page.dart`)* ⇒ il **n'a aucun état**. |

### 6 · 🔴 **LE FAIT QUI RÉFUTE LA SOLUTION NAÏVE, et il est mesuré** : `Navigator.push` **ne démonte pas** la route du dessous

L'exigence de design est **ferme** : *« le message ⛔ **ne survit pas** à un aller-retour vers la
gestion »*. Or un `String?` dans le `State` du hub **y survit**, parce que la route du hub **reste
vivante sous** la route poussée. Sonde jetable *(même atelier)* :

```
AVANT  |message=<le message>|initStates=1|disposes=0
PENDANT|hub_encore_dans_l_arbre=0|gestion_visible=1|initStates=1|disposes=0
APRES  |message=<LE MEME>|initStates=1|disposes=0|meme_State=true
VERDICT-1|survit_a_l_aller_retour=true
VERDICT-2|efface_par_le_retour_du_push=true
```

⇒ **`dispose()` n'est JAMAIS appelé** *(`disposes=0`)*, c'est **le même `State`**
*(`meme_State=true`)*, et le message **est encore là**. ⛔ **« L'état vit dans le hub » ne suffit donc
pas : il faut dire QUAND il est effacé, et par quel mécanisme.** La mesure établit aussi **lequel
marche** : **attendre le retour du `push`** *(`VERDICT-2`)*.

⚠️ **Et un piège de test tombe de la même mesure** : pendant que la gestion est au-dessus,
`find.byType(HubPage)` rend **0** *(`skipOffstage: true` par défaut)* ⇒ ⛔ **une assertion
« le message a disparu » écrite pendant la navigation est VIDE DE SENS — vraie sans rien observer.**
Elle doit être écrite **après le `pop`**.

---

## Décision

### Décision A — l'enveloppe interactive est **CONDITIONNELLE**

#### A.1 · L'arbre, par régime de tuile — la tuile `ACTIVE` sans description n'en a **AUCUNE**

**L'arbre d'ADR-013 §3 s'applique à DEUX régimes sur trois. Le troisième garde l'arbre d'US-01.1,
INCHANGÉ.**

| Tuile | Arbre |
|---|---|
| `ACTIVE` **avec** description | **arbre d'ADR-013 §3**, `GestureDetector(onTap:)` |
| `ÉCHUE` *(y compris en cours de retrait)* | **arbre d'ADR-013 §3**, `GestureDetector(onDoubleTap:)` |
| **`ACTIVE` sans description** | 🔴 **`Semantics(label: temps.libelleAccessibilite, container: true)` > `ExcludeSemantics` > rendu.** ⛔ **Rien d'autre** : ni `FocusableActionDetector`, ni `Focus`, ni `button: true`, ni `onTap:`, ni `hint:`, ni `GestureDetector`. **C'est l'arbre d'US-01.1, mot pour mot.** |

⛔ **Ce que la décision NE fait PAS, et c'est la moitié qui compte** : elle **ne retire pas le label**.
`libelleAccessibilite` reste **intégralement** publié — la tuile est **nommée** et **lisible par une
AT**, elle n'est simplement **pas activable**. ⚠️ **Sans cette précision, « aucune enveloppe » se lit
comme « aucune sémantique », et la tuile deviendrait invisible aux lecteurs d'écran** — un défaut
**pire** que celui qu'on corrige.

✅ **Précédent du dépôt, et il n'est pas nouveau** : `hub_page.dart` rend déjà les modules grisés par
`Semantics(enabled: false, container: true)` **sans aucun gestionnaire**, avec ce motif littéral
*« l'ABSENCE de gestionnaire rend l'interdit vérifiable, là où un callback vide le laisserait
révocable »*. **La décision A applique à la tuile la règle que la barre basse applique déjà.**

#### A.2 · La forme de `T-P4` pour cette tuile : elle asserte **l'ABSENCE DU NŒUD**, ⛔ pas `onTap == null`

**Sept assertions, sur le sous-arbre de la tuile.** ⛔ **Aucune n'est redondante : la sonde mesure que
chacune est tuée par au moins une source** *(`jamais_tuees=[]`)*.

| # | Assertion | Ce qu'elle voit, et **quelle source la tue** |
|---|---|---|
| **1** | **0 gestionnaire pointeur** dans le sous-arbre *(`GestureDetector`/`InkWell` portant `onTap`, `onDoubleTap` ou `onLongPress`)* | la forme d'ADR-013 §2, **conservée** — elle tue le **`onTap` vide** *(`S4`)* et ⛔ **elle est aveugle à J-1** |
| **2** | l'ensemble des `SemanticsAction` du sous-arbre est **VIDE** | ⛔ **pas `onTap == null`** : `S2` *(`Semantics(button:, onTap:)` seul)* et `S3` *(focus seul)* |
| **3** | **aucun** nœud ne porte `isButton` | `S1`, `S2` |
| **4** | **aucun** nœud ne porte `isFocusable` — **lu sur le SOUS-ARBRE** *(§Contexte 4)* | `S1`, `S3`, `R1` |
| **5** | **0** widget `Focus` dans le sous-arbre | `S1`, `S3`, `R1` |
| **6** | une **tabulation** laisse le focus primaire **hors** de la tuile *(c'est le mot littéral d'AC-9 : « atteignable au clavier »)* | `S1`, `S3`, `R1` |
| **7** | ✅ **CONTRÔLE** : le label est **présent, unique et égal** à `libelleAccessibilite` | `S5` *(label retiré)* — ⛔ **sans elle, « tout retirer » passerait** |

⚠️ **Borne à ne pas sur-lire, et elle est mesurée** : les assertions **4** et **6** sont tuées par
**exactement les mêmes trois sources** ⇒ ⛔ **leur indépendance n'est PAS démontrée**. Elles sont
gardées toutes les deux parce qu'elles lisent **deux couches distinctes** *(un drapeau déclaré · un
parcours réellement effectué)*, et parce que **6** est la seule qui parle la **langue de l'AC**.

### Décision B — où vit l'état du message d'échec

#### B.1 · Il vit dans **`_HubPageState`** — `HubPage` devient `StatefulWidget`, avec **UN** champ nullable

```
class _HubPageState extends State<HubPage> {
  String? _messageEcriture;   // ⛔ UN SEUL champ. ⛔ aucun Timer. ⛔ aucun AnimationController.
}
```

**Trois propriétés, et elles sont la raison du choix** :

1. ⛔ **Aucun `dispose` à tenir** : le message **n'a AUCUN minuteur** *(décision de design mesurée —
   *« un minuteur serait un quatrième état éphémère »*, et ADR-013 a posé le seuil là)*. **C'est
   précisément le motif par lequel ADR-013 avait écarté `HubPage` pour la RÉVÉLATION**
   *(« devrait devenir *stateful* pour porter la discipline de `dispose` d'un minuteur »)* — et
   ⛔ **ce motif ne transfère pas**, parce qu'il n'y a pas de minuteur.
2. **Le second motif d'ADR-013 ne transfère pas non plus** : *« hisser l'état permettrait à un widget
   hors de la grille de révéler une tuile »*. Le message **n'est pas un état de tuile** — il est
   **rendu hors de la grille**, et le hub est **le seul** widget qui le peigne.
3. **L'état est au même endroit que la surface qui l'affiche.** Le hub **porte déjà** le
   `ListenableBuilder` et la barre basse ; la zone de message est le **dernier enfant de son corps**.
   ⛔ **Aucun nouveau propriétaire n'est créé pour un seul `String?`.**

#### B.2 · Le cycle de vie du message — **trois effacements, et le troisième exige un mécanisme**

| Événement | Mécanisme, et son état de preuve |
|---|---|
| **un retrait RÉUSSIT** | le rappel rend `null` ⇒ `setState(() => _messageEcriture = null)` |
| **un nouvel échec** | le champ est **écrasé** — un champ unique **ne peut pas** contenir deux messages, donc *« remplacé »* est vrai **par construction**, ⛔ pas surveillé. *(Même raisonnement qu'ADR-013 §1 pour `_idRevele`.)* ⚠️ La **ré-annonce** est portée par `liveRegion`, ⛔ pas par cet ADR. |
| **on QUITTE le hub** | 🔴 **`dispose()` NE SUFFIT PAS — mesuré : il n'est JAMAIS appelé** *(§Contexte 6)*. ⇒ **`_HubPageState` ATTEND le retour du `push` vers la gestion et efface**, sous garde `if (!mounted) return;`. **Mesuré : `VERDICT-2|efface_par_le_retour_du_push=true`.** |

🔴 **Le point de code exact, et il est LU — ⛔ pas deviné** : `_CommandeGestion` fait aujourd'hui
`Navigator.of(context).push(…).ignore()` *(**[LU]** dans `hub_page.dart`)*. **C'est précisément ce
`.ignore()` qui doit disparaître** : il **jette** le `Future` qui porte l'information *« on est
revenu »*. ⇒ le `Future` est **remonté** à `_HubPageState`, qui l'attend et efface.
⚠️ **Et le remède au symptôme serait ici un piège** : `.ignore()` existe pour taire
`unawaited_futures`. Le remplacer par un `await` **dans `_CommandeGestion`** *(un
`StatelessWidget`)* rendrait la règle du lint verte **sans** que personne n'apprenne le retour —
**le mensonge serait déplacé, pas supprimé**. Le `Future` doit remonter **jusqu'au porteur de
l'état**.

⛔ **Aucun minuteur, aucun bouton de fermeture, aucun effacement au rafraîchissement de 30 s.**
⛔ **Aucun `RouteObserver`** : il faudrait l'installer sur `MaterialApp`, donc un mécanisme **global**
pour un effet **d'un seul écran**, alors que le `Future` du `push` est **déjà là** et **déjà mesuré**.

#### B.3 · Ce que le rappel de retrait **REND** — ⛔ jamais `void`

ADR-013 §7 dit *« un rappel de retrait (et rien de plus) »* et **ne dit pas son type**. Il en faut un
pour que **B.1** soit **exécutable**, et il est **imposé par le corpus, non inventé** :

```
Future<RefusValidation?> Function(String id)    // null ⇒ succès, sinon le refus à afficher
```

* ✅ **C'est la signature des chemins d'écriture existants** *(`creer`, `modifier`, `supprimer` et
  `_appliquer`, **[LU]** dans `echeances_notifier.dart`, dont le commentaire écrit littéralement
  *« Rend **`null` en cas de succès**, sinon le **refus à afficher** — ⛔ jamais un booléen nu,
  ⛔ jamais `void` »*)* ⇒ ⛔ **aucun pattern nouveau**, **un** seul en vigueur.
* ✅ **Le paramètre est un `id`, ⛔ pas une `Echeance`** : c'est la forme de `supprimer(String id)`
  **[LU]**, et c'est **la même clé** que les états éphémères d'ADR-013 §1 *(`_idRevele`,
  `_idEnRetrait`)*. ⛔ Passer l'entité ferait **deux façons de désigner une échéance** dans le même
  écran.
* ✅ **`RefusValidation.message` est exactement ce que `MessageEcriture` accepte** *(@UXDesigner §5.1)*
  ⇒ le texte reste en **un seul exemplaire**, dans `ActeEcriture`.
* 🔴 **Et ce n'est pas une élégance** : `unawaited_futures` est activé mais sa portée est **partielle
  et prouvée par mutant dans les deux sens** *(vert à tort dans un appelant synchrone)*. **Un retour
  typé non-`void` est ce qui ferme le résidu** — la grille **ne peut pas ignorer** l'issue, donc elle
  ne peut pas laisser une tuile disparue après une écriture échouée.
* ⛔ **`ResultatEcriture` n'est PAS choisi** : c'est le type du **port**, et la présentation n'en
  consomme que le message *via* `RefusValidation`. L'exposer ici ferait **remonter un type de la
  couche données** jusqu'au widget.

⚠️ **Ce que B.3 ne fait pas** : il ⛔ **n'ajoute aucun canal**. La grille reçoit **toujours UN rappel
et rien de plus** — §7 d'ADR-013 est **préservé**, seul son **type** est fixé.

### Ce que cet ADR ⛔ **ne décide pas**

* Le **texte** du `hint`, du message et de la marque de gestion — **@UXDesigner** *(**U-1**)*.
* La **géométrie de l'anneau** de focus, la **hauteur réservée**, les **couleurs** — **@UXDesigner**.
* **J-3** *(le composant à deux tons touche-t-il `formulaire_echeance.dart` ?)*, **J-4** *(où vit
  `courbeDisparition`)*, **J-5**, **J-6** — ⛔ **hors de cet ADR** : ils ne mettent en cause **aucune
  décision d'ADR-013** et n'atteignent **aucun seuil** qu'un ADR accepté a posé. **Ils vivent dans le
  Story File.** *(Ne pas fabriquer un ADR par trou : ce serait diluer la clause d'immuabilité.)*
* **D-8** *(le volume de l'historique)* — ⛔ **aucun plafond n'est posé ici**, et ce n'est pas un
  oubli : l'arbitrage humain du 2026-08-24 dit **« MESURER D'ABORD, BORNER ENSUITE »**. L'instrument
  est livré à part : `reports/US-01.4/cout_ecriture_atomique_criterion.py`.

---

## Alternatives considérées

- **Rendre l'arbre conditionnel dans le Story File, sans ADR** — **écartée** : le Story File dirait
  **le contraire** d'une §Décision d'un ADR accepté ⇒ **deux sources en désaccord**, et la plus faible
  gagnerait par proximité. *« On remplace, on ne contourne pas. »*
- **Garder l'arbre complet avec `onTap: null` sur le `Semantics`** — **écartée PAR LA MESURE** :
  `S3_focus_seul` montre qu'un `FocusableActionDetector` **seul** laisse `focusables=1`,
  `actions=[focus]` et **la tabulation atteint la tuile** ⇒ **le mensonge d'interface subsiste**, sous
  une forme **plus discrète**. ⛔ **Retirer l'action ne retire pas le focus.**
- **Garder l'arbre complet et rendre l'intention inerte** *(un rappel vide)* — **écartée** : c'est le
  `onTap` vide d'ADR-013 §2 **déplacé d'une couche**, et la mesure le montre **pire** : `S1` publie
  `tap=true`, `button=true`, l'intention **est invoquée** et **rien ne se passe**. **AC-3 cesserait
  d'être assertable par une absence**, ce qui était son fondement.
- **Écrire `T-P4` sur la seule couche pointeur** *(la forme prescrite par ADR-013 §2)* — **écartée PAR
  LA MESURE, et c'est le cœur de `A.2`** : cette assertion est **VERTE sur la source
  fautive**.
- **Écrire `T-P4` comme `onTap == null` sur le nœud sémantique** — **écartée** : `S3_focus_seul` la
  rendrait **verte** *(aucun `onTap`, mais un focus)*. Ce n'est pas l'`onTap` qu'il faut asserter,
  **c'est l'absence du NŒUD**.
- **Lire les drapeaux sur le nœud portant le label** — **écartée PAR LA MESURE** : le premier jet de la
  sonde l'a fait et l'assertion **n'a jamais rougi**, parce que `isFocusable` vit sur un nœud
  **ancêtre** *(§Contexte 4)*. ⛔ **Une assertion qu'aucun mutant ne tue est décorative.**
- **Retirer aussi le `Semantics(label:)` de la tuile sans description** — **écartée**, et c'est le rôle
  de l'assertion **7** : la tuile deviendrait **muette pour une AT**. **AC-9 exige qu'elle soit
  nommée**, pas qu'elle soit activable.
- **Un `Semantics(enabled: false)` sur cette tuile** *(comme les modules grisés)* — **écartée** :
  `enabled: false` annonce *« une commande, désactivée »*. Or cette tuile **n'est pas une commande
  désactivée** — elle **n'est pas une commande**. ⚠️ **Et une tuile « désactivée » EFFACERAIT la clause
  qu'AC-3 observe** : c'est la règle que [ADR-013](ADR-013-etat-interaction-grille-observabilite-gestes.md)
  **§Décision-6** énonce pour la tuile en cours de retrait — *« le geste est **reçu** et **sans effet**,
  donc la clause reste **observable** »*. Même famille que *« ce qui doit être refusé doit d'abord
  pouvoir être saisi »*.
  🔴 **Renvoi RETIRÉ, et il faut le dire** : ce raisonnement était d'abord attribué au *« pattern 14 »*
  — **ce renvoi ne résolvait NULLE PART.** Mesuré : `grep -rn "pattern 14" docs/` ne rend
  qu'**ADR-013 §6** *(accepté)* et le **Design UX d'US-01.4** *(deux fois)*, et
  `grep -n "pattern" docs/governance/STACK_PROFILE.md` rend **une seule ligne, sans aucune table
  numérotée**. ⇒ **la citation est remplacée par sa SUBSTANCE et par une ancre résoluble.**
  *(Le renvoi mort lui-même est signalé à la jointure : ⛔ **ce n'est pas à cet ADR de le réparer** —
  ADR-013 est immuable, et le catalogue manquant n'est pas une décision d'architecture.)*
- **L'état du message dans `_EcheancesGridState`** — **écartée** : ADR-013 §7 *(un rappel, rien de
  plus)*, **quatrième état éphémère** *(le seuil nommé)*, et — fait décisif — **la zone de message est
  rendue HORS de la grille**, donc la grille ne peut pas la peindre.
- **L'état du message dans `EcheancesNotifier`** — **écartée** : le **motif même** par lequel ADR-013
  §1 a refusé d'y mettre la révélation *(source de vérité adossée au disque, deux écrans, survit à la
  navigation)*. Ici la conséquence serait **directement observable** : le message reviendrait au retour
  de la gestion, ce que le design **interdit**.
- **Un objet dédié** *(`MessagesHubNotifier`, ou un `ValueNotifier<String?>`)* — **écartée, et c'est
  l'alternative la plus sérieuse** : ADR-013 §Conséquences dit *« il faut un objet dédié »*, mais ce
  motif visait un **quatrième** état dans le `State` **de la grille**. Dans le hub, c'est le
  **PREMIER**. Un notifier dédié exigerait **une création, une destruction et un
  `ListenableBuilder`** — donc **`HubPage` stateful de toute façon**, pour créer et détruire l'objet
  ⇒ **strictement plus de machinerie pour exactement la même durée de vie**. ⛔ Et hissé **au-dessus**
  de la route, il **survivrait à la navigation** — le défaut qu'on cherche à éviter.
- **Un `InheritedWidget` / un conteneur d'injection** — **écartée** : **un seul consommateur**, un seul
  écran. ADR-011 a retenu `ChangeNotifier` + injection **par constructeur**, `+0` paquet ; introduire un
  second mécanisme de diffusion pour un `String?` local serait **deux patterns pour un problème**.
- **Effacer le message dans `dispose()`** — **écartée PAR LA MESURE** : `disposes=0` sur un
  aller-retour. ⛔ **Elle aurait été verte en test unitaire et fausse en usage.**
- **Un `RouteObserver` / `RouteAware`** — **écartée** : mécanisme **global** installé sur `MaterialApp`
  pour un effet **local**, alors que le `Future` du `push` est **déjà disponible** et **mesuré**.
- **Un minuteur d'effacement** — **écartée par le corpus, pas par goût** : **A-11** d'US-01.2 est
  réfutée par *« un message fugace »*, et ici *« manquer le message, c'est croire que le retrait a eu
  lieu »*. **Et ce serait le quatrième état éphémère**, c'est-à-dire **la chose exacte** qu'ADR-013
  désigne comme point de rupture.
- **Fondre ces deux décisions dans deux ADR séparés** — **écartée** : **un seul objet**, l'*enveloppe
  interactive et stateful de la grille*, et **une seule cause**, la jointure du 2026-08-24. Les
  séparer **dupliquerait le §Contexte** — la faute qu'ADR-010 s'interdit explicitement.
- **Ne pas écrire d'ADR pour J-2 et se contenter du Story File** — **écartée, et c'est l'alternative
  qu'il faut peser honnêtement** : le seuil LITTÉRAL d'ADR-013 n'étant **pas** franchi, l'obligation
  n'est pas mécanique. Ce qui la fonde est autre : **ADR-013 a examiné et REJETÉ de rendre `HubPage`
  stateful**, et **désigné un objet dédié** comme remède. Retenir la première et écarter le second
  **dans un Story File** laisserait deux traces durables **en désaccord**, dont la plus autoritaire
  serait la **fausse**. ⛔ C'est le défaut que la clause d'immuabilité existe pour éviter.

---

## Conséquences

**Positif**

- **Le défaut J-1 est fermé AVANT d'être écrit**, comme `SONDE-1` l'avait été — et **son miroir est
  distingué de lui par la mesure**, dans **une seule sortie**.
- 🔴 **Un ANGLE MORT de la forme d'assertion décidée par ADR-013 §2 est NOMMÉ et MESURÉ.** ⛔ **Aucun
  scénario fonctionnel n'aurait vu J-1** : la tuile ne fait rien, et c'est **ce qu'AC-3 demande**. Seul
  un test qui lit **la sémantique et le focus** peut le voir.
- **La décision A ne coûte RIEN** : `+0` widget, `+0` token, `+0` paquet. C'est **l'arbre d'US-01.1**,
  et le précédent des modules grisés existe **déjà dans `hub_page.dart`**.
- **Le dispositif d'ADR-013 a fonctionné — mais PAS comme on le croyait, et la nuance est l'acquis** :
  ce n'est **pas** son *seuil de rupture* qui a déclenché cet ADR *(il n'est PAS franchi)*, c'est son
  **§Alternatives écartées**, qui portait **le motif** du rejet et a donc permis de vérifier, deux US
  plus tard, que **ce motif ne transférait pas**. ⇒ ✅ **écrire le MOTIF d'une alternative écartée vaut
  plus qu'écrire le rejet** — à réutiliser. ⚠️ Et ⛔ **une sur-lecture du seuil a été évitée de peu** :
  la première rédaction de cet ADR l'affirmait franchi.
- **La décision B est la plus petite qui satisfait toutes les contraintes** : `HubPage` stateful,
  **un** champ nullable, **zéro** `dispose` à tenir, **un** pattern d'écriture.
- **Le mécanisme d'effacement à la navigation est MESURÉ dans les deux sens** *(`survit=true` sans lui,
  `efface=true` avec)*, et le **piège d'assertion** *(le hub offstage rend `find.byType` vide)* est
  **écrit avant d'être payé**.

**Négatif, et ⛔ à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve RIEN sur l'application.** Toutes les mesures viennent de **sondes jetables
  hors dépôt** *(`.dart_tool/`, ignoré par git)* reproduisant l'arbre. **Aucune ligne de `lib/` ni de
  `test/` n'existe pour US-01.4**, et **aucun écran n'a été vu**.
- ⚠️ **Les assertions 4 et 6 sont tuées par les MÊMES sources** ⇒ leur indépendance ⛔ **n'est pas
  démontrée**. Elles sont gardées pour deux motifs de couche, ⛔ pas parce qu'une mesure les sépare.
- ⚠️ **Deux attentes de la sonde étaient FAUSSES et c'est la mesure qui a tranché** *(le drapeau sur
  l'ancêtre · `Focus` publie `focus`)*. ⇒ **la lecture de la sémantique Flutter n'est pas
  intuitive**, et ⛔ **une assertion d'accessibilité écrite « de tête » a une chance sérieuse d'être
  verte à tort**. Ce constat vaut **au-delà d'US-01.4**.
- ⚠️ **`HubPage` devient `StatefulWidget`** : c'est le premier état éphémère de cet écran, et
  ⛔ **rien n'empêchera le suivant**. **Le seuil est reposé, dans la même forme qu'ADR-013** : *un
  DEUXIÈME état éphémère dans `_HubPageState`, ou tout état portant un minuteur ou un
  `AnimationController`, exige un objet dédié — et ce serait un nouvel ADR.*
- ⚠️ **L'effacement à la navigation est porté par le `Future` du `push`**, c'est-à-dire par **le point
  d'appel**. ⛔ **Si une US future ouvre la gestion par un AUTRE chemin** *(lien profond, second
  bouton, `pushReplacement`)*, **l'effacement ne sera pas hérité** — c'est une **obligation de code,
  non une barrière**. Le seul remède structurel *(un `RouteObserver`)* est **écarté ci-dessus** ; ce
  compromis est **assumé et daté**.
- ⚠️ **La garde `if (!mounted)` est une DISCIPLINE, ⛔ pas une mesure** : elle est prescrite parce que
  l'`await` traverse une frontière de frame, et ⛔ **aucune sonde de cet ADR ne l'a mise en défaut**.
- ⚠️ **Aucun lecteur d'écran réel n'a rien entendu** *(borne **NM-12**, inchangée)*. Que la tuile sans
  description soit **nommée mais non activable** est mesuré **dans l'arbre sémantique**, ⛔ pas dans
  TalkBack.
- ⚠️ **Aucun événement de trace ne porte cette décision** *(le catalogue n'a aucun événement de choix
  technique)*, et **rien ne la rattache à un commit** *(dette **NB-6** : `trace_append.py` n'a aucune
  option `--commit`)*. ⛔ **Aucun événement n'est détourné.** Elle vit dans le **corpus durable**.
- 📌 **Dette nommée, non traitée ici** : les **sondes de cet ADR sont JETABLES et hors dépôt** ⇒
  ⛔ **aucun gate ne les rejouera**, et un futur remaniement de la tuile pourrait rétablir J-1 **sans
  que rien ne le voie** — jusqu'à ce que **`T-P4` existe dans `test/`**. **C'est `T-P4` qui porte
  la décision `A.2`**, ⛔ pas cet ADR. ➡️ **Tâche du Story File.**

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
