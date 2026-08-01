# ADR-002 : Moteur de temps restant — unité adaptative, arrondi supérieur et calcul calendaire

- **Date** : 2026-08-01
- **Statut** : Accepté
- **US associée** : US-01.1 (Affichage Hub & grille d'échéances)

## Contexte

Le cœur de la proposition de valeur est un **nombre nu** : une tuile affiche **un entier, sans unité
visible** (RF-01), qui doit se lire d'un regard. Ce nombre exige quatre choses que rien dans Flutter ne
fournit : le **choix de l'unité** *(années → mois → semaines → jours → heures, RF-02)*, l'**arrondi
supérieur** dans cette unité *(RF-03)*, un **calcul calendaire réel** *(RNF-05 : mois de longueurs
variables, années bissextiles — jamais des durées moyennes)*, et une **progression `p ∈ [0;1]`** mesurant
la **proximité du prochain changement de nombre**, qui pilote la couleur *(RF-04, AC-5)*.

Exemples de référence du PRD, qui font contrat : `2 ans 3 mois → 3` · `8 mois 12 jours → 9` ·
`2 semaines 1 heure → 3` · `5 h 10 min → 6`.

⚠️ **Le projet n'a ni SAST ni scanner de CVE** *(`dart pub outdated` mesure l'obsolescence)* : toute
dépendance ajoutée est une **surface non scannée**. Ce constat pèse sur les alternatives.

## Décision

**1 · Moteur pur, sans Flutter, horloge injectée.** `RemainingTimeCalculator` est une fonction
déterministe `(Clock, DateTime cible) → RemainingTime`. ⛔ **Jamais de `DateTime.now()` dans la logique** :
le temps est un paramètre. `RemainingTime` est un **value object immuable** portant `unite`,
`nombreAffiche`, `progression`, `estEchue` et `libelleAccessibilite`.

**2 · Sélection d'unité par seuils, puis `ceil` DANS l'unité retenue** — dans cet ordre, jamais l'inverse.
La bascule **jours → heures se fait exactement à 24 h** de temps restant *(AC-4)*.

**3 · Deux régimes de calcul, et c'est délibéré :**
- **Années et mois : arithmétique CALENDAIRE.** Le nombre de mois entiers est obtenu en **ajoutant des mois
  à l'instant courant** et en comparant à la cible — jamais en divisant une durée par « 30 jours » ou
  « 365,25 jours ». C'est la seule façon de satisfaire RNF-05.
- **Semaines, jours et heures : durée ABSOLUE** (`Duration`), en heure **locale de l'appareil** (RNF-04).

**4 · Contrat de la progression `p`, défini par les DEUX instants qui l'encadrent** — et non par une
fraction d'unité, qui serait ambiguë : soit `t_prev` l'instant où le nombre affiché a **pris sa valeur
actuelle** et `t_next` celui où il **changera**. Alors `p = (now − t_prev) / (t_next − t_prev)`, borné à
`[0;1]`. Donc **`p = 0` juste après un changement** *(loin du prochain → orange)* et **`p → 1` juste
avant** *(imminent → bleu)*, ce qui est exactement le sens exigé par AC-5. ⛔ **`p` ne dépend NI de la
grandeur du nombre, NI de l'urgence de l'échéance.**

**5 · Échéance atteinte (`T ≤ 0`)** : `estEchue = true`, `nombreAffiche = 0`, `p = 1.0`. Aucun nombre
négatif, aucune exception — l'état « à zéro » est un **état d'affichage normal** *(AC-7)*.

**6 · `libelleAccessibilite` porte le temps complet AVEC son unité** *(« 3 ans, préparation du projet »)*
alors que l'unité **n'est jamais rendue visuellement** *(AC-8 vs RF-01)*. C'est le **seul** endroit où
l'unité devient un mot.

**7 · Aucune dépendance ajoutée** : `dart:core` seul.

## Alternatives considérées

- **Un paquet de manipulation de dates** *(type `jiffy`, `timeago`)*. **Écarté** : ils produisent du
  **texte formaté** *(« dans 9 mois »)* alors que le produit exige un **entier nu** plus une
  **progression** — la valeur ajoutée serait quasi nulle, contre une **dépendance non scannée** dans un
  projet sans SAST ni CVE.
- **Durées moyennes** *(mois = 30 j, année = 365,25 j)*. **Écarté** : viole RNF-05 frontalement, et produit
  des sauts visibles au voisinage des frontières de mois.
- **`p` défini comme « fraction de l'unité courante consommée »**. **Écarté** : ambigu dès que l'unité
  n'est pas de longueur constante *(un mois n'a pas la même durée que le suivant)*, alors que la définition
  par `t_prev`/`t_next` reste exacte **dans tous les régimes**, y compris à la bascule d'unité.
- **Tout calculer en calendaire, y compris les heures.** **Écarté** : sans bénéfice mesurable, et
  l'arithmétique calendaire sous-horaire n'a pas de sens plus fin que la durée absolue.

## Conséquences

**Positif** — le moteur est **testable exhaustivement en pur Dart** *(pas d'arbre de widgets)* : exemples
du PRD, frontières exactes de seuil, **29 février**, mois de longueurs différentes, `T ≤ 0`, et `p` à ses
deux bornes. C'est ce qui rend atteignable la **couverture ≥ 89,4 %** exigée par le cliquet, puisque cette
US ajoute massivement du code à `lib/`.

**Négatif, et à ne pas taire**

- ⚠️ **Le changement d'heure (DST) n'est PAS neutralisé pour les jours et les heures.** Un « jour » civil
  peut valoir 23 h ou 25 h, tandis que la bascule jours → heures est posée à **24 h absolues** : sur une
  journée de changement d'heure, le nombre affiché peut donc différer d'une unité de ce qu'un calcul
  purement civil donnerait. **Assumé** : RNF-05 exige le calendaire pour les **ans et mois**, et l'affichage
  d'un compte à rebours à l'heure près n'a pas d'enjeu produit à cette granularité. ⛔ **Ce cas doit être
  couvert par un test qui DOCUMENTE le comportement retenu** — pas laissé implicite.
- ⚠️ **La « certification calendaire fine »** *(frontières exactes, DST)* reste **rattachable à une US
  ultérieure** *(résolution `clarify` nº 1)* **sans changer le contrat d'affichage** : `RemainingTime` est
  stable, seule son implémentation pourrait se raffiner.
- ⚠️ **`p = 1` pour une échéance atteinte** place la tuile échue à l'**extrémité bleue** du dégradé. C'est
  cohérent *(bleu = imminent, et aucune couleur d'urgence n'est permise)*, mais **ce n'est pas une décision
  de design** : si @UXDesigner veut un état visuel distinct pour « à zéro » *(AC-7 le permet)*, il s'appuie
  sur `estEchue`, **jamais** sur la couleur seule.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
