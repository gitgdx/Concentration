# ADR-013 : L'état d'interaction de la grille — où il vit, et comment un geste devient **observable** et **accessible** ⛔ **sans aucun seam nouveau**

- **Date** : 2026-08-22
- **Statut** : Accepté *(2026-08-22 — @Architect, après relecture des §Décision et **rejeu des sondes** : `flutter test` sur les 3 fichiers de sonde ⇒ **10 tests passés**, dont le mutant `SONDE-5b` **TUÉ**. ⚠️ Un ADR accepté est **IMMUABLE**.)*
- **US associée** : US-01.4 (Gestes sur la tuile — RF-06), EPIC_01, track FULL

> ⚖️ **CE DOCUMENT NE PORTE PAS LE TITRE QUI LUI ÉTAIT RÉSERVÉ, ET C'EST LE POINT LE PLUS IMPORTANT
> QU'IL ÉTABLIT.** Le Story File d'US-01.4 le réservait sous *« … et pourquoi la période de
> rafraîchissement devient injectable »*, sur la base de mon propre constat **§G-11 / R-5** : *« le
> scénario est INOBSERVABLE tel quel »*. **La mesure du 2026-08-22 le RÉFUTE** — le scénario **est
> observable, avec les valeurs de production, sans aucun seam** *(§Contexte 4)*. ⇒ **la décision ③
> attendue est ABANDONNÉE, et l'ADR décide le contraire : ⛔ aucun seam de durée n'est introduit.**
> ⛔ **Le constat §G-11 n'est pas repeint** : il est **daté et corrigé** dans le Story File, avec sa
> mesure. *On date, on ne repeint pas — y compris quand c'est soi qu'on corrige.*

## Contexte

### 1 · Ce que l'US change dans l'arbre, et l'état du code **mesuré**

| Fait | Où il se lit |
|---|---|
| `EcheanceTile` est un **`StatelessWidget`** ; son arbre est `Semantics(label:) > ExcludeSemantics(…)` ; il n'y a **aucun** `GestureDetector`, `InkWell` ni `onTap` | `lib/features/echeances/presentation/widgets/echeance_tile.dart` |
| `EcheancesGrid` est un **`StatefulWidget`** ; `_EcheancesGridState` porte **un** `Timer? _minuterie` `Timer.periodic(ConcentrationTokens.periodeRafraichissement, (_) => setState(() {}))`, annulé dans `dispose` | `lib/features/echeances/presentation/echeances_grid.dart` |
| `periodeRafraichissement = Duration(seconds: 30)` | `lib/core/theme/concentration_tokens.dart` |
| La grille **ne connaît pas le dépôt** : *« elle reçoit une `List<Echeance>` et n'a pas à connaître le dépôt »* | `lib/features/hub/presentation/hub_page.dart` |
| Le test de RF-05 avance `budgetRf05 = Duration(minutes: 1)`, **budget INDÉPENDANT du token**, et le token est borné par une assertion séparée *(`periodeRafraichissement <= budgetRf05`)* | `test/features/echeances/presentation/echeances_grid_test.dart` |

US-01.4 ajoute à cela : **un état de révélation** *(3 s, AC-2)*, **l'exclusivité** *(un seul révélé à la
fois — arbitrage *clarify* nº 7)*, **un geste par tuile** *(`onTap` seul si active, `onDoubleTap` seul si
échue — arbitrage *clarify* nº 1)*, une **animation de disparition** *(AC-8)* et l'**accessibilité** de
tout cela *(AC-9)*.

### 2 · 🔴 `ExcludeSemantics` avalerait la sémantique d'un gestionnaire placé DEDANS — et **le sens de l'aval est mesuré**

`ExcludeSemantics` supprime la sémantique de **tous ses descendants**. Un `InkWell` placé **à
l'intérieur** rendrait la tuile **fonctionnelle mais NON ANNONCÉE** : le geste marcherait, **AC-9
tomberait**, et ⛔ **rien d'autre ne le verrait**.

✅ **Mesuré dans l'autre sens** *(sonde jetable hors dépôt, Flutter 3.44.7, 2026-08-22)* : un `Semantics`
placé **AU-DESSUS** d'un `ExcludeSemantics` **conserve tout**, et le geste **pointeur** traverse quand
même —

```
SONDE-2 label="a zero, revue annuelle" tap=true dismiss=true button=true
SONDE-2 pointeur double tap -> doubles=1
SONDE-2 AT -> taps=1 dismiss=1
```

⇒ **`ExcludeSemantics` filtre la SÉMANTIQUE, ⛔ pas les tests de contact.** La forme « geste et annonce
au-dessus » est donc **licite et suffisante** — ce n'est plus une précaution, c'est une observation.

### 3 · 🔴 **LE FAIT LE PLUS COÛTEUX DE CET ADR** : `onDoubleTap` seul rend la tuile **FOCUSABLE ET INERTE**, et il n'existe **aucune action sémantique de double appui**

**Deux mesures, dans le SDK puis à l'exécution.**

**① Dans le SDK** *(lecture)* : `SemanticsProperties` expose **17** rappels — `onTap`, `onLongPress`,
`onScroll*`, `onIncrease`, `onDecrease`, `onCopy`, `onCut`, `onPaste`, `onDidGain/LoseAccessibilityFocus`,
`onFocus`, `onDismiss`, `onExpand`, `onCollapse` — et le moteur **26** `SemanticsAction`.
⛔ **AUCUN double appui, ni d'un côté ni de l'autre.**
`InkWell` câble par ailleurs `Semantics(onTap: widget.excludeFromSemantics || widget.onTap == null ? null : simulateTap)`
et `ActivateIntent`/`ButtonActivateIntent` → `simulateTap()` → `handleTap()`, dont le corps est
`if (widget.onTap != null) { … widget.onTap?.call(); }`. ⇒ **avec `onTap == null`, l'activation clavier
n'appelle RIEN et aucune action sémantique n'est publiée** — alors que `isWidgetEnabled` reste **vrai**
*(il compte `onDoubleTap`)*, donc **la tuile reste focusable**.

**② À l'exécution** *(sonde jetable hors dépôt)* :

```
SONDE-1 clavier -> onDoubleTap appele 0 fois
SONDE-1 semantique -> tap=false longPress=false focusable=true button=false
SONDE-1 AT tap -> onDoubleTap appele 0 fois, erreur=aucune
```

🔴 **Conséquences, et elles se cumulent** :
* **AC-9 « atteignable au clavier »** serait **INSATISFIABLE** pour une tuile échue.
* **`focusable=true` avec `tap=false`** est **exactement le « mensonge d'interface » qu'AC-9 « Erreur »
  interdit** : l'utilisateur clavier **atteint** la tuile et **ne peut rien en faire**.
* ⛔ **Rien ne lève** *(`erreur=aucune`)* : le défaut est **totalement silencieux**.
* 🔴 **Et c'est une contrainte que la lettre de `C-3` / `P-4` du Story File PRODUIRAIT** : *« une tuile
  `ÉCHUE` ⛔ ne porte PAS `onTap` »*, appliqué au **nœud sémantique**, rend AC-9 inatteignable. **La
  contrainte doit donc être portée par la COUCHE POINTEUR, et cela doit être écrit.**

### 4 · 🔴 Mon constat **§G-11 / R-5 est FAUX**, et le contre-exemple est exécuté

**Ce que §G-11 affirmait** : *« pour atteindre le tic à 30 s, un test doit traverser les 3 s, donc la
révélation est déjà éteinte ⇒ le scénario est INOBSERVABLE tel quel »*.

**Ce que la mesure montre** — l'erreur était de supposer que le geste se fait **au début** du temps
simulé. Il suffit de **placer l'appui juste avant le tic** : le tic tombe alors **dans** la fenêtre.
Sonde jetable *(reproduction fidèle : `Timer.periodic(30 s)` → `setState`, `Timer(3 s)` → fermeture)* :

```
SONDE-5 a t=28s : tics=0
SONDE-5 apres appui : revele=true
SONDE-5 a t=30s : tics=1 revelation_toujours_visible=true
SONDE-5 a t=32s : revele=false nombre_revenu=true
```

Et — ⛔ **une séquence sans pouvoir de réfutation ne prouve rien** — le **mutant** *(le rafraîchissement
referme la révélation)* est **TUÉ** :

```
SONDE-5b MUTANT : revele_avant_tic=true revele_apres_tic=false (tics=1) -> mutant TUE = true
```

⇒ **le scénario d'AC-2 « Limite » est observable avec `periode = 30 s` et `fenetre = 3 s`, sans toucher
à une seule valeur de production.** La technique est le **PHASAGE**, ⛔ pas un seam.

**Condition d'existence du phasage, et elle doit être ASSERTÉE, pas supposée** : il faut
`fenetre < periode`. **C'est précisément le fait que §G-11 avait à l'envers** ⇒ il devient une
**garde du test**, refutable, et non une hypothèse tacite.

### 5 · Pourquoi cet ADR ne peut pas se contenter d'invoquer ADR-011 §5

[ADR-011](ADR-011-gestion-etat-injection-dependances.md) §5 a **supprimé** le seam
`ConcentrationApp(echeances: List<Echeance>)`, avec ce motif littéral : *« il injectait des données
**déjà chargées**, donc il court-circuiterait la persistance et rendrait la clause E2E décorative »*, et
il ajoute : *« Deux seams, c'est une règle en deux exemplaires — et deux copies dérivent. »*
⇒ **toute proposition de seam nouveau dans cette même US doit être traitée de front.** Elle l'est
ci-dessous — **et elle est refusée**.

## Décision

### 1 · L'état ÉPHÉMÈRE d'interaction vit dans `_EcheancesGridState` — la tuile reste `StatelessWidget`

* `String? _idRevele` — **l'exclusivité est STRUCTURELLE** : un champ nullable **ne peut pas** contenir
  deux `id`, donc *« appuyer une seconde tuile referme la première »* est vrai **par construction**,
  ⛔ pas surveillé.
* `Timer? _revelation` — **UN SEUL**, ⛔ **jamais un par tuile**.
* `Timer? _minuterie` *(existant)* — **distinct**, et le `setState(() {})` périodique ⛔ **ne touche
  aucun des deux** ⇒ la fenêtre n'est **ni coupée ni prolongée** *(AC-2 « Limite »)*.
* `String? _idEnRetrait` — **l'état de la tuile SORTANTE vit au même endroit**, et c'est une nécessité,
  pas un choix de style : une tuile **retirée de la liste** n'existe plus dans l'arbre, donc ⛔ **elle ne
  peut pas s'animer elle-même** *(AC-8)*. La grille la **maintient rendue** le temps de l'animation.
* **`EcheanceTile` reste un `StatelessWidget`** : la grille le reconstruit **à chaque tic**, donc la
  tuile doit être une **fonction pure de ses entrées** *(`revele`, `estEchue`, l'intention)*.

⛔ **Aucun état d'interaction ne va dans `EcheancesNotifier`** : cet objet est la **source de vérité
adossée au disque**, écoutée **aussi** par la page de gestion. Y mettre une affordance visuelle de
3 secondes ferait **notifier deux écrans** pour un effet local, et la révélation **survivrait à une
navigation** — ce qu'aucun AC ne demande.

### 2 · **Un seul geste POINTEUR par tuile** — et le contrôle structurel porte sur **la couche pointeur**, ⛔ jamais sur le nœud sémantique

| Tuile | Couche **pointeur** | ⛔ Interdit |
|---|---|---|
| `ACTIVE` **avec** description | `onTap` **seul** | ⛔ `onDoubleTap` — il imposerait `kDoubleTapTimeout` *(300 ms)* à la révélation et ferait **clignoter** le 1ᵉʳ appui |
| `ACTIVE` **sans** description | ⛔ **aucun gestionnaire** | ⛔ Un `onTap` vide *(« qui mentirait à l'accessibilité »)* — c'est **l'absence** de gestionnaire qui rend **AC-3** assertable |
| `ÉCHUE` | `onDoubleTap` **seul** | ⛔ `onTap` — un appui simple retirerait la tuile, contre l'arbitrage *clarify* nº 1 |

**Forme de l'assertion structurelle (`T-P4`), et elle est décidée ici parce qu'elle est ambiguë sans
mesure** : elle **lit le widget pointeur**, pas le nœud sémantique —
`tester.widget<GestureDetector>(…).onTap == null` / `.onDoubleTap != null`. **Mesuré** :

```
SONDE-6c echue : pointeur onTap==null ? true / onDoubleTap!=null ? true
```

⛔ **Une assertion écrite sur le nœud sémantique rendrait AC-9 insatisfiable** *(§Contexte 3)* — et une
assertion écrite « sur la tuile » sans dire **quelle couche** serait ambiguë, donc dérivable.

✅ **Conséquence mesurée du verdict *clarify* nº 1, à porter au test** : sur une tuile active, **deux
appuis rapprochés** produisent **deux révélations immédiates** — ⛔ **aucun `kDoubleTapTimeout`** :

```
SONDE-6b active, DEUX appuis rapproches -> revelations=2
```

### 3 · **Une INTENTION par tuile, quatre canaux d'entrée** — l'arbre est décidé, et il est mesuré

```
FocusableActionDetector( actions: { ActivateIntent, ButtonActivateIntent } → intention )
  └ Semantics( label: temps.libelleAccessibilite, button: true, onTap: intention, hint: <@UXDesigner> )
      └ ExcludeSemantics
          └ GestureDetector( excludeFromSemantics: true, onTap | onDoubleTap → intention )
              └ … rendu existant de la tuile …
```

**Ce que l'arbre garantit, MESURÉ sur les quatre canaux d'une tuile échue** :

```
SONDE-6 noeud : label="a zero, revue annuelle" tap=true button=true focusable=true
                noeuds_portant_ce_label=1
SONDE-6 pointeur SIMPLE -> retraits=0 (attendu 0)
SONDE-6 pointeur DOUBLE -> retraits=1 (attendu 1)
SONDE-6 clavier ENTREE  -> retraits=2
SONDE-6 clavier ESPACE  -> retraits=3
SONDE-6 AT tap          -> retraits=4
```

**Quatre décisions que cela fixe** :

1. **`FocusableActionDetector` est le porteur du focus et de l'activation clavier**, ⛔ **pas
   `InkWell`** : `InkWell` lie l'activation clavier à **`onTap`**, donc une tuile échue devrait porter un
   `onTap` **pointeur** — ce que l'arbitrage interdit. **Mesuré** : `FocusableActionDetector` n'insère
   **aucune** `DecoratedBox` *(`SONDE-6c … = 0`)* ⇒ ⛔ **il ne déclenche pas `NB-7`**.
2. **Il y a UNE intention par tuile**, invoquée par **quatre** canaux — ⛔ **ce n'est PAS une règle en
   quatre exemplaires** : c'est **un** rappel, atteint par quatre chemins d'entrée. La règle *« une règle
   n'existe qu'en un seul exemplaire »* est respectée **parce qu'il n'y a qu'un rappel**.
3. **`libelleAccessibilite` n'est PAS retouché** — il porte **déjà** la description *(mesuré :
   `suffixe = ', ${echeance.description}'`, injecté des deux côtés)*, et **P-2** ainsi que les mutants
   **X-2 / X-3** en dépendent. **L'action disponible s'annonce par le FLAG (`button: true`) et le
   HINT** — dont ⛔ **le texte appartient à @UXDesigner**, comme le texte du 3ᵉ acte d'écriture.
4. **Le détecteur intérieur porte `excludeFromSemantics: true`** ⇒ **un seul nœud annoncé**
   *(`noeuds_portant_ce_label=1`)*, ⛔ jamais deux.

⚠️ **Asymétrie ASSUMÉE et nommée** : la tuile échue s'active en **UNE** activation par le clavier et par
l'AT, et en **DEUX** appuis au pointeur. **C'est inévitable** *(il n'existe aucune action sémantique de
double appui — 26 actions, aucune)*, et c'est **la bonne asymétrie** : le double appui est une
**protection contre le geste accidentel du doigt** *(risque nº 5 d'EPIC_01)*, qui n'a pas d'équivalent au
clavier. ⛔ **Personne ne doit « rétablir la symétrie » en ajoutant un `onTap` pointeur.**

### 4 · ⛔ **AUCUN seam de durée n'est introduit** — ni la période, ni la fenêtre

**Le scénario d'AC-2 « Limite » s'observe par PHASAGE** *(§Contexte 4, mesuré et mutant tué)*, selon
cette forme :

1. avancer le temps simulé **jusqu'à juste avant le tic** ⇒ vérifier **qu'aucun tic n'a eu lieu** ;
2. **appuyer** ⇒ la description est révélée ;
3. avancer **jusqu'au-delà du tic, sans sortir de la fenêtre** ⇒ vérifier que **le tic a eu lieu**
   **et** que la révélation est **toujours** visible ;
4. avancer jusqu'à l'expiration ⇒ le **nombre revient**.

**Trois contraintes non négociables sur ce test** :

* ⛔ **Aucun nombre dérivé n'est écrit à la main** *(défaut nº 1 du projet)* : les deux avances se
  **calculent** depuis `ConcentrationTokens.periodeRafraichissement` et la fenêtre d'AC-2. **Écrire
  `28 s` serait une valeur dérivée recopiée**, qui périmerait au premier changement de token.
* ✅ **La garde `fenetre < periode` est ASSERTÉE** dans le test : sans elle, le phasage est impossible et
  le test deviendrait **vert sans rien observer**. **C'est le fait que §G-11 avait à l'envers** — il est
  désormais **vérifié par la machine**, pas cru.
* ⛔ **Le tic doit être OBSERVÉ, pas supposé** : l'étape 1 vérifie `0` tic et l'étape 3 vérifie qu'il y
  en a eu **un**. Sans cela, un test où le tic n'arrive jamais serait **vert** — et il ne prouverait
  **rien**.

**Ce que la décision préserve, et c'est son vrai bénéfice** : le test porte sur **la période réelle de
production**. Un seam à `1 s` aurait fait asserter *« un rafraîchissement d'une seconde n'interrompt pas
la révélation »* — ⛔ **une affirmation sur une configuration qui n'existe pas.**

### 5 · Le critère de licéité d'un seam, énoncé une fois pour toutes

> **Un seam est ILLICITE si, réglé à une valeur de test, il permet à un test de passer sans traverser
> une COUCHE que le scénario prétend exercer.**

* Le seam supprimé par ADR-011 §5 était illicite **par ce critère** : réglé à une liste en mémoire, il
  faisait passer un E2E **sans qu'un octet soit lu ou écrit**.
* `Clock` *(ADR-002)* et `calculateur`, déjà injectés dans ce même widget, sont **licites** : ils ne
  court-circuitent **aucune couche**.
* ⚖️ **Un seam de DURÉE serait licite par ce critère — et il est refusé quand même**, parce qu'un seam
  licite mais **inutile** reste un coût : une entrée publique de plus, une valeur par défaut qui
  **duplique** le token, et une porte qu'un test futur peut régler pour **contourner** ce qu'il devait
  observer. ⛔ **ADR-011 §5 n'est donc PAS remplacé, il est renforcé** : cette US n'ajoute **aucun**
  seam.

### 6 · L'animation est un feedback, ⛔ jamais une condition

L'écriture *(via le rappel de retrait)* et le rechargement sont séquencés **indépendamment** de
l'animation : ⛔ **aucun `await` d'un `AnimationController` sur le chemin d'écriture**. Sous
`MediaQuery.disableAnimationsOf(context)` la tuile part **immédiatement** et **l'état écrit est
EXACTEMENT le même** — *un retrait qui n'aboutirait pas sans animation serait un retrait perdu*.
Pendant l'animation, la grille **ignore un second geste** sur la tuile sortante : ⛔ elle ne retire rien
d'autre et ⛔ ne lève rien *(AC-8)*. ⚠️ **Ce n'est PAS une tuile désactivée** *(pattern 14)* : le geste
est **reçu** et **sans effet**, donc la clause reste **observable**.

### 7 · Ce que la grille reçoit, et ce qu'elle ne reçoit pas

`EcheancesGrid` reçoit **un RAPPEL de retrait** *(et rien de plus)*. ⛔ **Ni le dépôt, ni le notifier** —
ce qui garde vrai le commentaire mesuré d'`hub_page.dart` : *« `EcheancesGrid` … n'a pas à connaître le
dépôt »*, et respecte **ADR-011 §2** *(injection par la racine, par constructeur)*.

## Alternatives considérées

- **Rendre la PÉRIODE de rafraîchissement injectable** *(la décision qui était réservée)* —
  **ÉCARTÉE PAR LA MESURE, ⛔ pas par doctrine.** Son unique motif était que le scénario serait
  inobservable ; **il est observable** *(§Contexte 4, mutant tué)*. Le motif tombé, il ne reste que les
  coûts : une entrée publique, une valeur par défaut **dupliquant** le token *(deux exemplaires d'une
  même valeur — et deux copies dérivent, vérifié trois fois)*, et un test qui asserterait sur **une
  période qui n'existe pas en production**. ⚠️ **Et le garde-fou qu'on aurait dû lui adjoindre est
  lui-même piégé** : *« le défaut vaut le token »* est **auto-référentiel** — le corpus a **mesuré** ce
  piège *(`echeances_grid_test.dart` : une assertion qui pumpait le token lui-même « restait vraie pour
  30 s comme pour 1 HEURE », mutant **`QA-M7`, survivant**)*. **Ne pas créer le seam supprime le
  problème au lieu de le garder.**
- **Rendre la FENÊTRE de 3 secondes injectable** *(seam alternatif : fenêtre longue en test, période
  réelle)* — **écarté** : il rendrait injectable **une valeur produit écrite dans un AC**, et le
  scénario d'AC-2 « Nominal » *(« après 3 secondes, le nombre revient »)* devrait alors utiliser la
  valeur de production tandis que le voisin utiliserait la valeur de test — **deux régimes pour une même
  durée**. Le phasage n'en a pas besoin.
- **Un `Timer` par tuile** *(option (b) du verdict *clarify* nº 7)* — **écarté** : jusqu'à **9 minuteurs
  concurrents**, et l'exclusivité deviendrait **surveillée** au lieu d'être **garantie**. Un champ
  nullable unique **ne peut pas** être en faute.
- **L'état de révélation dans la TUILE** *(`StatefulWidget`)* — **écarté** : la tuile devrait alors
  connaître ses sœurs pour se refermer, ou un coordinateur devrait le faire — c'est-à-dire **remettre
  l'état au-dessus**, par un chemin plus long. Et la tuile serait reconstruite à chaque tic tout en
  portant un état, ce qui **mélange** fonction pure et cycle de vie.
- **L'état de révélation dans `EcheancesNotifier`** — **écarté** : voir §Décision 1 *(source de vérité
  adossée au disque, écoutée par deux écrans, survivrait à la navigation)*.
- **L'état de révélation dans `HubPage`** — **écarté** : `HubPage` est `StatelessWidget` et devrait
  devenir *stateful* pour porter la discipline de `dispose` d'un minuteur — discipline qui existe
  **déjà** dans `_EcheancesGridState`. Et hisser l'état permettrait à un widget **hors de la grille** de
  révéler une tuile.
- **`InkWell(onTap: …, onDoubleTap: …)` sur la tuile échue** *(les deux)* — **écarté par l'arbitrage
  *clarify* nº 1 et par sa conséquence mesurée** : la coexistence impose `kDoubleTapTimeout` **300 ms**
  à `onTap` et fait **clignoter** le premier appui d'un double.
- **`InkWell(onDoubleTap: …)` seul** — **écarté PAR LA MESURE, et c'est le piège central de cet ADR** :
  `SONDE-1` montre `focusable=true` mais `tap=false`, **clavier inopérant**, **AT inopérante**, ⛔ **et
  aucune erreur**. C'est le défaut le plus silencieux du lot.
- **`Semantics(onDismiss:)` comme canal d'activation du retrait** — **écarté comme canal UNIQUE**, bien
  qu'il soit sémantiquement le plus exact *(mesuré fonctionnel : `SONDE-2 … dismiss=1`)*. Deux motifs :
  la documentation du SDK le situe dans le **menu contextuel local** de TalkBack *(donc atteignable
  seulement par qui l'ouvre)*, et ⛔ **il n'a aucune liaison clavier** — AC-9 « atteignable au clavier »
  resterait ouvert. **Il n'est pas ajouté EN PLUS de `onTap`** : ce serait un **second point d'entrée**
  pour une même intention, sans qu'aucun AC ne le demande. **Si @UXDesigner l'estime nécessaire, ce sera
  un nouvel ADR.**
- **`customSemanticsActions`** — **écarté** : elles exigent un **label** *(donc un texte produit que je
  n'ai pas qualité pour inventer — entrée **U-1**)* et sont, comme `dismiss`, **hors du chemin
  d'activation standard** et **sans liaison clavier**.
- **Placer le `GestureDetector` à l'intérieur d'`ExcludeSemantics` sans plus de précaution** —
  **écarté** : tuile **fonctionnelle et NON annoncée**, AC-9 tombe, ⛔ **rien d'autre ne le voit**
  *(risque **R-3**)*.
- **Retoucher `libelleAccessibilite` pour y annoncer l'action** — **écarté** : il porte **déjà** la
  description, **P-2** en dépend, et les mutants **X-2 / X-3** *(ajoutés parce que l'étape appariée était
  « décorative »)* seraient **ressuscités**. Le flag et le hint sont les porteurs prévus.
- **Fondre cette décision dans [ADR-012](ADR-012-etat-echue-retiree-persistance-migration-v3.md)** —
  **écarté** : cause et objet distincts *(là, un fait persistant et sa forme sur le disque ; ici,
  l'observabilité et l'accessibilité d'une interaction)*. Les fondre **dupliquerait le motif** — la
  faute qu'ADR-010 s'interdit explicitement.

## Conséquences

**Positif**

- **L'exclusivité est structurelle** : un champ nullable unique ⇒ *« un seul révélé à la fois »* est vrai
  par construction, ⛔ pas surveillé par un test.
- **`+0` seam, `+0` dépendance, `+0` paquet.** ADR-011 §5 sort **renforcé** : cette US n'ajoute **aucune**
  porte de test, et le scénario le plus difficile est **couvert avec les valeurs de production**.
- **AC-9 devient atteignable, et son chemin est MESURÉ sur quatre canaux** — pointeur simple *(inerte)*,
  pointeur double, clavier `Entrée` **et** `Espace`, action AT — avec **un seul nœud annoncé**.
- **Le défaut le plus silencieux de cette US est fermé AVANT d'être écrit** : une tuile focusable et
  inerte, sans aucune erreur levée. ⛔ **Aucun scénario fonctionnel ne l'aurait vu.**
- **La forme de l'assertion structurelle est décidée**, donc `P-4` cesse d'être ambigu : elle lit la
  **couche pointeur**, jamais le nœud sémantique.
- **`NB-7` n'est pas déclenché par le porteur de focus retenu** *(mesuré : `FocusableActionDetector`
  n'insère aucune `DecoratedBox`)* — ⚠️ ce qui ⛔ **ne dispense pas de `T7`** : l'**anneau** peut, lui, en
  insérer une, et ⛔ cela **se mesure** *(§G-6)*.

**Négatif, et à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve RIEN sur l'application.** Toutes les mesures citées viennent de **sondes
  jetables hors dépôt** reproduisant l'arbre ; **aucune ligne de `lib/` ni de `test/` n'existe pour
  US-01.4**, et **aucun écran n'a été vu**.
- ⚠️ **Le phasage observe le MÉCANISME, pas la FRÉQUENCE.** Il établit qu'un rafraîchissement ne coupe
  pas la révélation ; il ⛔ **n'établit pas** à quelle fréquence cela se produit en usage réel.
- ⚠️ **La séquence de phasage est plus fragile qu'un seam, et il faut le dire** : elle dépend de
  `fenetre < periode`. Si un design futur allongeait la fenêtre au-delà de la période, **le test
  échouerait bruyamment** *(garde assertée)* — ce qui est le comportement voulu, mais **c'est un coût de
  maintenance réel** que le seam n'aurait pas eu.
- ⚠️ **L'asymétrie une-activation / deux-appuis est assumée**, et ⛔ **aucun lecteur d'écran réel ne l'a
  jamais entendue** *(borne **NM-12**)*. Que TalkBack active justement par un double appui est une
  **coïncidence favorable**, ⛔ **pas une mesure**.
- ⚠️ **Le HINT et le texte du 3ᵉ acte d'écriture MANQUENT** *(entrées **U-1** / **U-2**, @UXDesigner)*.
  L'ADR fixe **le porteur** de l'annonce ; il ⛔ **ne fournit pas le mot**, et **inventer un libellé,
  c'est fabriquer une assertion de test que le vrai texte rendra fausse**.
- ⚠️ **La géométrie de l'anneau de focus n'est PAS décidée ici** — seulement son **impossibilité en
  couleur plate** *(mesuré : `moduleActif` rend **1,36:1** sur le dégradé, **101/101 points sous 3:1**)*
  et la **seule combinaison de tokens existants qui tienne** *(bicolore)*. **La forme est à
  @UXDesigner**, et **A-7 doit être amendé et daté**.
- ⚠️ **`_idEnRetrait` ajoute un troisième état éphémère au même `State`.** C'est le coût du choix de
  garder la tuile `StatelessWidget` ; il est **assumé**, et le **seuil de réexamen est nommé** : un
  quatrième état éphémère dans ce `State` signifierait qu'il faut un objet dédié — **ce serait un nouvel
  ADR**.
- ⚠️ **Aucun événement de trace ne porte cette décision** *(le catalogue n'a aucun événement de choix
  technique)*, et **rien ne la rattache à un commit** *(dette **NB-6** : `trace_append.py` n'a aucune
  option `--commit`)*. ⛔ **Aucun événement n'est détourné.** Elle vit dans le **corpus durable**.
- 📌 **Dette nommée, non traitée ici** : `python scripts/check_e2e_persistance.py` — l'instrument des
  deux contrôles d'ADR-010 — **n'est dans AUCUN workflow** *(mesuré : `grep -rn "check_e2e_persistance"
  .github/` ne rend rien)* ⇒ **le garde-fou de l'E2E reste MANUEL**. ⛔ **Non câblé ici** *(`ci.yml` est
  une projection d'un fichier protégé)*. ➡️ **`/audit-methodo`.**

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
