# EPIC 01 - Module Échéances (MVP)

> **Priorité MoSCoW :** Must-Have
> **Dépendances amont :** EPIC_00 — Fondations (Sprint 0) : socle qualité, CI, protection de branche, stack Flutter.
> **Dépendances aval :** Modules futurs (Respiration, Concentration) — dont l'architecture doit rester extensible (RF-21), mais non développés au MVP.

## 📝 Description de l'Epic

Premier module métier de l'application « Concentration » (PRD §1.3, §3.1) : il matérialise
instantanément, sous forme de tuiles épurées, le temps restant avant chaque échéance importante —
exprimé par **un seul nombre nu** dans l'unité la plus pertinente, avec une **couleur ambiante**
(gradient orange → bleu) traduisant la proximité du prochain changement de nombre. L'objectif est
d'offrir un support de pratique de recentrage à charge cognitive nulle : un coup d'œil suffit pour
ancrer la revue mentale (usage quotidien < 60 s).

**Dans le périmètre (MVP)** : hub de pratiques avec Échéances actif et modules futurs visibles/grisés ;
grille de 1 à 9 tuiles ; moteur de temps restant (unité adaptative + arrondi supérieur) ; gradient
orange → bleu ; état « à zéro » + geste double-tap de disparition ; gestion des événements (CRUD :
description + date + heure optionnelle par défaut 23:59) ; validation (date future) ; stockage local
offline-first ; dark mode ; accessibilité.

**HORS périmètre (MVP)** : comptes utilisateurs, synchronisation cloud, multi-appareils ;
notifications / rappels ; modules Respiration et Concentration (prévus dans l'architecture, non
développés) ; partage social ; widgets d'écran d'accueil OS ; tri manuel des tuiles (candidats V2).

## ⚠️ Critères de performance et sécurité

- **Performance** : affichage des tuiles < 500 ms à l'ouverture (RNF-02, indicateur §8) ; taux de
  crash < 0,5 %.
- **Rafraîchissement** : recalcul des nombres/couleurs à chaque affichage et au minimum toutes les
  minutes lorsque l'écran reste ouvert (RF-05, nécessaire à l'unité « heures »).
- **Calcul** : unités « ans » et « mois » en calendaire réel (mois de longueur variable, années
  bissextiles) ; calculs basés sur le fuseau local ; comportement défini au changement de fuseau
  (RNF-04, RNF-05).
- **Confidentialité / offline** : aucune donnée ne quitte l'appareil au MVP ; toutes les
  fonctionnalités fonctionnent sans connexion ; stockage local (RNF-01, RNF-07).
- **Accessibilité** : contraste WCAG AA sur toute la plage du dégradé ; nombre lisible quelle que
  soit la couleur de fond ; tailles de police système ; lecteur d'écran annonçant le temps restant
  complet avec unité (RNF-06).

## 👥 Rôles identifiés

| Rôle | Description |
|---|---|
| @ProductOwner | Valeur métier, User Stories, critères d'acceptation, priorisation MoSCoW, arbitrages produit (unité non affichée, limite 9, double-tap). |
| @Architect | Architecture modulaire (hub + registre de modules RF-21), modèle de rendu, contrat du moteur de temps restant, découpage des tâches, ADR. |
| @UXDesigner | Design system, placement des entrées de pratique (grille de hub vs barre de nav), dégradé orange → bleu, dark mode, états (vide/à zéro), accessibilité. |
| @DataEngineer | Modèle de données des événements, persistance locale offline-first, migrations réversibles. |
| @Developer | Implémentation Flutter (tuiles, grille, moteur, CRUD, persistance). |
| @QA_Tester | Vérification des scénarios Gherkin, cas limites du moteur, non-régression, couverture. |
| @CyberSecurity | Vérification confidentialité (aucune sortie de données), stockage local. |
| @DevOps | CI, build multi-plateformes iOS/Android, déploiement. |

## 📄 Story Files associés

| US ID | Titre | Story File | Statut |
|---|---|---|---|
| US-01.1 | Affichage Hub & grille d'échéances | [`docs/stories/US-01.1-affichage-hub-grille.md`](../stories/US-01.1-affichage-hub-grille.md) | ⏳ business_alignment |
| US-01.2 | Gestion des événements (CRUD) | _(à créer via `/us-new`)_ | ⏳ à venir |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | **Tension gradient PRD ↔ maquette Stitch** : le PRD (RF-04) décrit une **interpolation continue** orange → bleu (proposition OKLCH `#FF8C42` → `#3D7DD8`) ; la maquette `hub_de_pratiques.html` implémente **4 paliers discrets** (`temporal-gradient-1..4`). | Perception du temps (cœur produit) et lisibilité (contraste) potentiellement incohérentes selon l'interprétation. | Arbitrage @UXDesigner + @ProductOwner : trancher continu vs paliers ; si paliers, justifier le nombre de crans ; documenter dans le Design System. |
| 2 | **Divergence d'endpoint bleu** : le PRD propose `#3D7DD8` comme bleu d'imminence ; la maquette utilise `#005ab3` (`temporal-gradient-4`, secondary-container) — teinte plus sombre/saturée. | Rendu final et contraste du nombre sur fond bleu différents des cibles produit. | Fixer une couleur d'endpoint unique dans le Design System (source d'autorité `docs/design/DESIGN_SYSTEM.md`) après test de contraste WCAG AA ; tracer la décision. |
| 3 | **Structure du hub PRD ↔ maquette** : RF-20 décrit un hub à 3 entrées (Échéances active + Respiration/Concentration grisées) ; la maquette fait de la grille Échéances le canvas d'accueil et place les modules futurs comme **icônes de barre de nav basse**, non grisées (`.ghost-entry` inutilisée). | Ambiguïté sur l'emplacement et l'état grisé des modules futurs. | AC US-01.1 formulés au niveau comportemental (visible + grisé + non-cliquable) ; placement délégué à @UXDesigner (résolution clarify #4). |
| 4 | **Frontières exactes du moteur de temps restant** : comportement à un seuil d'unité exact, bascule jours → heures à 24 h, changements d'heure été/hiver, mois calendaires de longueurs différentes (PRD §6). | Nombre affiché incohérent aux transitions (cœur de l'exercice). | US-01.1 embarque le calcul (ceil + unité adaptative) ; certification calendaire fine rattachable à une US ultérieure sans changer le contrat d'affichage (résolution clarify #1). |
| 5 | **Double-tap accidentel** (RF-06 §6.6) : geste de disparition d'une tuile échue potentiellement déclenché par erreur. | Perte de visibilité d'une échéance ; frustration. | Rattaché à US-01.2 (interaction mutante + persistance) ; prévoir feedback visuel de confirmation ; l'événement reste consultable en gestion (état « échu »). |
| 6 | **Langue & nommage des maquettes** : Hub en `lang="fr"`, gestion en `lang="en"` (« days left ») ; nom de code « Sobriety » dans les `<title>`. | Incohérence de langue produit. | Uniformiser en français ; nombre nu sans unité sur les tuiles (règle produit #7) ; à confirmer pour la page de gestion. |

## 🎯 Challenge PO : La couleur doit-elle encoder la proximité du changement, ou la grandeur du nombre ?

Règle produit (RF-04) : la couleur encode la **proximité du prochain changement de nombre**, PAS la
magnitude du nombre affiché. C'est contre-intuitif et source d'erreur d'implémentation.

```
  Proximité du PROCHAIN changement de nombre  (p ∈ [0 ; 1])
  p = 0                                                  p = 1
  |------------------------------------------------------|
  ORANGE                                                 BLEU
  "le nombre vient de changer"          "le changement est imminent"
  (loin du prochain changement)         (le nombre va décrémenter)

  Conséquence assumée :
   - un "42" peut être ORANGE (vient de passer de 43 à 42)
   - un "3"  peut être BLEU   (va bientôt passer de 3 à 2)
  => la couleur N'EST JAMAIS fonction de la valeur du nombre.
  => aucune couleur d'urgence (rouge) : ambiance calme, contemplative.
```

**Décision MVP** : conserver strictement RF-04 (proximité, non inversé). Pas de rouge, pas de badge,
pas de pourcentage. La couleur est un indicateur ambiant, sans texte. Le sens (orange = loin,
bleu = imminent) est verrouillé dans les AC de US-01.1 (AC-5) pour prévenir l'inversion.

## Critères de clôture de l'EPIC

- [ ] Toutes les US listées (US-01.1, US-01.2) sont `Certifié Prod = 🚀 OUI`
- [ ] Aucune régression détectée sur les EPICs dépendants (EPIC_00)
- [ ] Décisions de design tranchées et tracées (gradient continu vs paliers, endpoint bleu) dans `docs/design/DESIGN_SYSTEM.md`
- [ ] Indicateurs de succès mesurés : affichage < 500 ms, taux de crash < 0,5 % (PRD §8)
- [ ] Documentation à jour (`docs/user-guide/`, `CHANGELOG.md`)

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
