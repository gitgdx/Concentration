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

## Dark mode

**Mode sombre de référence FORCÉ** au MVP : `themeMode: ThemeMode.dark`, fond `#1B110C`.
⛔ **Aucune bascule clair/système** *(AC-8)* — et donc **aucun token de thème clair n'est défini** : en
définir serait prétendre qu'un mode clair est supporté.
⚠️ **Conséquence assumée** : si l'appareil est en mode clair, l'application **reste sombre**. C'est un
choix produit *(sobriété, RNF-03)*, à réexaminer quand un mode clair sera réellement demandé.

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
