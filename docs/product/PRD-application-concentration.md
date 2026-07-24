# PRD — Application mobile « Concentration » (nom de code)

**Version :** 0.2
**Auteur :** GDX
**Date :** 19 juillet 2026
**Statut :** Décisions produit actées (v0.2) — prêt pour le découpage en Epics / User Stories

---

## 1. Vision et contexte

### 1.1 Problème adressé

La pratique régulière de revue mentale du temps restant avant des échéances importantes est un exercice de concentration et de recentrage. Aujourd'hui cette pratique est purement mentale : elle exige de recalculer à chaque fois les durées restantes, ce qui détourne l'attention de l'exercice lui-même (la contemplation du temps qui reste) vers un calcul mécanique.

### 1.2 Proposition de valeur

Une application mobile qui matérialise instantanément, sous forme de tuiles épurées, le temps restant avant chaque échéance importante de l'utilisateur — exprimé par **un seul nombre**, dans l'unité la plus pertinente. L'application devient un support de pratique : un coup d'œil suffit pour ancrer la revue mentale, la charge cognitive du calcul disparaît, l'attention se porte entièrement sur l'exercice de concentration.

### 1.3 Vision produit à moyen terme

L'application « Échéances » est le **premier module** d'une application plus large dédiée aux pratiques de concentration et de recentrage. L'architecture (navigation, modèle de données, design system) doit anticiper l'ajout de modules ultérieurs, notamment :

- **Respiration** (exercices guidés : cohérence cardiaque, respiration carrée…)
- **Concentration** (exercices d'attention soutenue, fixation, visualisation…)
- D'autres pratiques à définir (méditation, mémorisation…)

Le module Échéances doit donc être conçu comme une **entrée parmi d'autres** dans un hub de pratiques, et non comme l'application entière.

---

## 2. Utilisateur cible et cas d'usage

### 2.1 Persona principal

Pratiquant régulier d'exercices de concentration, qui utilise la revue mentale des échéances comme mantra / rituel. Utilisation quotidienne, courte (moins d'une minute), souvent en début ou fin de journée. Recherche : sobriété, immédiateté, zéro friction.

### 2.2 Cas d'usage principaux

| ID | Cas d'usage | Fréquence |
|----|-------------|-----------|
| UC-01 | Ouvrir l'application et parcourir les tuiles d'échéances (pratique du mantra) | Quotidienne |
| UC-02 | Ajouter une nouvelle échéance (description + date) | Occasionnelle |
| UC-03 | Modifier ou supprimer une échéance existante | Occasionnelle |
| UC-04 | Percevoir, par la couleur de la tuile, la proximité d'un changement de nombre | Quotidienne (implicite) |
| UC-05 | Accéder à terme aux autres modules de pratique (respiration, concentration…) | Future |

---

## 3. Périmètre

### 3.1 Dans le périmètre (MVP)

- Page d'accueil : hub de pratiques avec le module Échéances actif et les futurs modules visibles (grisés ou masqués selon décision design).
- Écran Échéances : grille de tuiles de comptes à rebours.
- Page de gestion des événements : création, édition, suppression (description + date, et heure optionnelle).
- Moteur de calcul du temps restant avec règle d'unité adaptative et arrondi supérieur.
- Dégradé de couleur orange → bleu indiquant la proximité d'un changement de nombre.
- Stockage local des données (offline-first).

### 3.2 Hors périmètre (MVP)

- Comptes utilisateurs, synchronisation cloud, multi-appareils.
- Notifications / rappels.
- Modules Respiration et Concentration (prévus dans l'architecture, non développés).
- Partage social, widgets d'écran d'accueil OS (candidats pour une itération ultérieure — le widget est un candidat fort en V2).

---

## 4. Exigences fonctionnelles

### 4.1 Module Échéances — Écran principal (tuiles)

**RF-01 — Grille de tuiles.** L'écran présente une tuile par échéance active. Chaque tuile affiche :
1. Le **nombre** (élément dominant, typographie très grande) ;
2. La **description** de l'échéance ;
3. Une **couleur de fond** (ou d'accent) reflétant la progression vers le prochain changement de nombre (voir RF-04).

**L'unité n'est pas affichée.** Le nombre est présenté seul : le pratiquant connaît ses échéances, l'ambiguïté volontaire fait partie de l'exercice mental (retrouver l'ordre de grandeur relève de la pratique elle-même). L'unité reste néanmoins exposée à l'accessibilité (lecteur d'écran, cf. RNF-06) et pourra apparaître dans un écran de détail si besoin ultérieur.

**RF-02 — Règle d'unité adaptative (interne).** L'unité de calcul dépend du temps restant `T`. Elle détermine le nombre affiché mais **n'apparaît pas sur la tuile** (RF-01) :

| Condition | Unité de calcul |
|-----------|----------------|
| T > 1 an | Années |
| 1 mois < T ≤ 1 an | Mois |
| 1 semaine < T ≤ 1 mois | Semaines |
| 1 jour < T ≤ 1 semaine | Jours |
| T ≤ 1 jour | Heures |

La bascule jours → heures s'effectue **exactement à 1 jour restant** (24 h).

**RF-03 — Règle d'arrondi supérieur.** Le nombre affiché est le **plafond** (arrondi à l'entier supérieur) du temps restant exprimé dans l'unité de calcul courante.
*Exemple de référence : s'il reste 2 ans et 3 mois, la tuile affiche « 3 » (unité de calcul : années).*
Autres exemples :
- 8 mois et 12 jours → « 9 » (mois)
- 2 semaines et 1 heure → « 3 » (semaines)
- 5 heures et 10 minutes → « 6 » (heures)

Conséquence : le nombre affiché **décrémente** au fil du temps et l'unité de calcul change lorsque le seuil est franchi (ex. « 2 » [mois] → « 1 » [mois] → « 4 » [semaines]). *(Les comportements aux frontières exactes — ex. exactement 1 mois restant — devront être spécifiés en Gherkin/EARS lors du découpage en US.)*

**RF-04 — Dégradé de couleur orange → bleu.** La couleur de la tuile évolue continûment de **orange** (le nombre vient de changer, on est loin du prochain changement) vers **bleu** (le changement de nombre est imminent).
- La progression `p ∈ [0 ; 1]` est calculée sur l'intervalle entre deux changements de nombre consécutifs dans l'unité courante.
- `p = 0` → orange plein ; `p = 1` → bleu plein ; interpolation continue entre les deux (espace colorimétrique à définir en design, ex. OKLCH pour un dégradé perceptuellement uniforme).
- La couleur est un indicateur **ambiant**, sans texte ni pourcentage : elle nourrit la perception intuitive du temps sans polluer la sobriété de la tuile.

**RF-05 — Rafraîchissement.** Les nombres et couleurs sont recalculés à chaque affichage de l'écran, et au minimum toutes les minutes lorsque l'écran reste ouvert (nécessaire pour l'unité « heures »).

**RF-06 — Échéance atteinte (zéro).** Lorsque l'échéance est atteinte, la tuile passe en état « à zéro » : elle n'affiche plus de compte à rebours (affichage « 0 » ou état visuel distinct, à définir en design) et reste présente sur l'écran. **Un double tap sur la tuile la fait disparaître** de l'écran des tuiles. Un feedback visuel (animation de disparition) confirme le geste. L'événement correspondant reste consultable dans la page de gestion (état « échu ») où il peut être supprimé définitivement.

**RF-07 — Ordre des tuiles.** Par défaut, tri par échéance croissante (la plus proche en premier). *(Option de tri manuel : candidate V2.)*

### 4.2 Page de gestion des événements

**RF-10 — Liste des événements.** Vue listant tous les événements (actifs et échus) avec description, date, et temps restant.

**RF-11 — Création.** Formulaire de saisie : description (texte court, obligatoire) + date (obligatoire) + heure (optionnelle). **Si l'heure n'est pas renseignée, la valeur par défaut est 23:59** (fin de journée) : l'échéance couvre ainsi toute la journée indiquée, ce qui gouverne le calcul en unité « heures ».

**RF-12 — Édition.** Modification de la description et de la date/heure d'un événement existant.

**RF-13 — Suppression.** Suppression avec confirmation.

**RF-14 — Validation.** La date doit être dans le futur à la création ; message d'erreur explicite sinon.

**RF-15 — Limite de 9 échéances actives.** Le nombre d'échéances actives est **limité à 9**, un choix produit délibéré : la revue mentale doit rester embrassable d'un regard et tenable comme exercice. À la 10ᵉ tentative de création, un message invite à faire disparaître ou supprimer une échéance existante.

### 4.3 Hub de pratiques (navigation)

**RF-20 — Accueil = hub.** L'écran d'accueil de l'application présente les entrées de pratique : **Échéances** (active au MVP), **Respiration** et **Concentration** (**visibles et grisées** — la vision produit est assumée dès le MVP, sans interaction possible sur ces modules).

**RF-21 — Extensibilité.** L'ajout d'un nouveau module de pratique ne doit pas nécessiter de refonte de la navigation ni du modèle de données (architecture modulaire, registre de modules).

---

## 5. Exigences non fonctionnelles

| ID | Exigence |
|----|----------|
| RNF-01 | **Offline-first** : toutes les fonctionnalités du MVP fonctionnent sans connexion ; stockage local. |
| RNF-02 | **Performance** : affichage des tuiles < 500 ms à l'ouverture ; l'application doit être « prête au regard » immédiatement (c'est un support de pratique). |
| RNF-03 | **Sobriété visuelle** : design minimaliste, sans publicité, sans gamification, sans élément de distraction. |
| RNF-04 | **Fuseaux horaires** : calculs basés sur le fuseau local de l'appareil ; comportement défini en cas de changement de fuseau. |
| RNF-05 | **Calcul calendaire exact** : les unités « ans » et « mois » sont calculées en calendaire réel (mois de longueur variable, années bissextiles), pas en durées moyennes. |
| RNF-06 | **Accessibilité** : contraste suffisant sur toute la plage du dégradé orange → bleu ; le nombre reste lisible quelle que soit la couleur de fond ; support des tailles de police système. L'unité n'étant pas affichée visuellement (RF-01), le lecteur d'écran doit annoncer le temps restant complet (ex. « 3 ans, préparation du convent »). |
| RNF-07 | **Confidentialité** : aucune donnée ne quitte l'appareil au MVP. |
| RNF-08 | **Plateformes & stack** : mobile iOS et Android, développement **cross-platform en Flutter** — choix motivé par la qualité du rendu visuel (dégradés, typographie, animations) et par les besoins des modules futurs (animations fluides et audio pour Respiration). |

---

## 6. Règles métier détaillées — moteur de temps restant

Cette section servira de base aux scénarios Gherkin des US.

1. **Définition du temps restant** : `T = date_échéance − maintenant` (heure d'échéance par défaut : 23:59, cf. RF-11).
2. **Sélection de l'unité de calcul** : selon le tableau RF-02 ; bascule jours → heures exactement à 1 jour restant (24 h).
3. **Nombre affiché** : `ceil(T exprimé dans l'unité courante)` — l'unité n'est pas affichée (RF-01).
4. **Progression couleur** : soit `N` le nombre affiché ; le changement précédent a eu lieu quand `T` valait exactement `N` unités, le prochain aura lieu quand `T` vaudra `N − 1` unités (ou au franchissement du seuil d'unité). `p = (N − T_unité) / 1` où `T_unité` est le temps restant exprimé en unité courante. Couleur = interpolation(orange, bleu, p).
5. **Échéance atteinte** : à `T ≤ 0`, la tuile passe en état « à zéro » et attend le double tap de l'utilisateur pour disparaître (RF-06).
6. **Cas limites à spécifier en US** : T exactement égal à un seuil d'unité ; changement d'heure été/hiver ; mois calendaires de longueurs différentes ; double tap accidentel (délai/geste de confirmation éventuel).

---

## 7. Design — orientations

- **Tuile** : le nombre est le héros (typo ≥ 60 pt), **sans unité affichée** ; la description en soutien discret. Le nombre nu renforce le caractère contemplatif de la tuile.
- **Palette du dégradé** : orange (départ de cycle) → bleu (imminence du changement). Proposition initiale : `#FF8C42` → `#3D7DD8`, interpolation en OKLCH. À affiner avec le design system.
- **Ambiance générale** : calme, contemplative — l'application est un objet de pratique, pas un outil de productivité. Pas de rouge « urgence », pas de badge, pas de compteur anxiogène.
- **Mode sombre** : à prévoir dès le MVP (usage matinal/nocturne probable).

---

## 8. Indicateurs de succès

| Indicateur | Cible MVP |
|------------|-----------|
| Fréquence d'ouverture (proxy de la régularité de la pratique) | ≥ 5 jours / 7 |
| Durée médiane de session | < 60 s (c'est une réussite : la pratique est courte) |
| Taux de crash | < 0,5 % |
| Délai d'affichage des tuiles | < 500 ms |

---

## 9. Découpage pressenti en Epics (base pour la suite du travail)

| Epic | Contenu pressenti |
|------|-------------------|
| **E1 — Socle applicatif & hub de pratiques** | Navigation, architecture modulaire, feature flags des modules futurs, design system de base |
| **E2 — Gestion des événements** | CRUD événements, validation, persistance locale |
| **E3 — Moteur de temps restant** | Règles d'unité, arrondi supérieur, cas limites, tests unitaires exhaustifs |
| **E4 — Tuiles & expérience de pratique** | Grille de tuiles, typographie, dégradé orange → bleu, rafraîchissement, tri |
| **E5 — Cycle de vie des échéances** | État « à zéro », geste double tap de disparition, animation, limite des 9 échéances actives |
| **E6 — Qualité transverse** | Accessibilité, mode sombre, performance, fuseaux horaires |

---

## 10. Décisions produit actées (v0.2)

| # | Sujet | Décision |
|---|-------|----------|
| 1 | Heure par défaut d'une échéance saisie sans heure | **23:59** (fin de journée) |
| 2 | Seuil de bascule jours → heures | **Exactement à 1 jour restant** (24 h) |
| 3 | Modules futurs sur l'accueil (Respiration, Concentration) | **Visibles et grisés** |
| 4 | Échéance atteinte (zéro) | La tuile reste affichée à zéro ; **double tap** de l'utilisateur pour la faire disparaître |
| 5 | Nombre maximal d'échéances actives | **9** |
| 6 | Stack technique | **Cross-platform Flutter** |
| 7 | Affichage de l'unité sur les tuiles | **Non affichée** — le nombre est présenté seul |
