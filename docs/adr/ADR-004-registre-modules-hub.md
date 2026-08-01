# ADR-004 : Registre de modules extensible du hub de pratiques

- **Date** : 2026-08-01
- **Statut** : Accepté
- **US associée** : US-01.1 (Affichage Hub & grille d'échéances)

## Contexte

« Concentration » est un **hub de pratiques** : Échéances est **actif**, Respiration et Concentration sont
**visibles mais grisés et non-interactifs** dès le MVP — la vision produit est **assumée à l'écran**
*(RF-20, AC-2)*. Et RF-21 pose une exigence d'extensibilité chiffrée : **ajouter un module doit coûter une
entrée**, sans refonte de la navigation.

Deux contraintes encadrent la solution :

- **AC-2 délègue explicitement le PLACEMENT à @UXDesigner** *(résolution `clarify` nº 4)* : tuiles grisées
  dans une grille de hub **ou** icônes de barre de navigation basse — l'US **ne le figera pas**, elle
  n'exige que le **comportement** *(visible + grisé + non-cliquable)*.
- L'« Erreur » d'AC-2 est **testable et sévère** : un appui **simple, répété ou prolongé** sur un module
  grisé ne produit **aucun effet** — ni navigation, ni message, ni plantage.

## Décision

**1 · Le hub itère sur un registre, il ne connaît AUCUN module en dur.** `PracticeModuleRegistry` expose
une **liste ordonnée immuable** de `PracticeModule` — `id`, `label`, `icone`, `statut ∈ {actif, grise}`.
**Ajouter un module = ajouter une entrée**, et rien d'autre *(RF-21)*.

**2 · Le registre est AGNOSTIQUE DU PLACEMENT.** Il porte un **ordre** et un **statut**, ⛔ **jamais une
position, une zone d'écran ni un type de conteneur**. C'est ce qui rend la délégation d'AC-2 tenable : que
@UXDesigner choisisse la grille ou la barre basse, **le registre ne change pas**.

**3 · Le non-interactif est obtenu par ABSENCE de gestionnaire, jamais par un gestionnaire qui ne fait
rien.** Un module `grise` est rendu **sans** `GestureDetector`/`InkWell`/`onTap`, et porte
`Semantics(enabled: false)`.
**Motif** : un `onTap: () {}` *(callback vide)* laisse le widget **annoncé comme actionnable** au lecteur
d'écran, produit un retour visuel d'appui, et surtout **il suffira qu'un jour quelqu'un remplisse ce
callback** pour que l'interdit d'AC-2 tombe **sans que rien ne le signale**. L'absence, elle, est
**vérifiable** : un test qui pompe l'app et tape sur un module grisé peut assener qu'**aucune route n'a été
poussée**.

**4 · Le statut `actif` désigne QUI FOURNIT LE CONTENU, pas quoi afficher.** Le hub demande au module actif
son contenu *(ici la grille d'échéances)* ; il n'embarque **aucune logique** propre à Échéances. Un futur
module actif s'insère **sans toucher `hub_page.dart`**.

**5 · Les commandes de la barre de navigation basse** *(ajout, réglages)* sont rendues **non-interactives**
au périmètre d'US-01.1, **par le même mécanisme** *(absence de gestionnaire)* — leur activation relève d'US
ultérieures *(AC-2 « Limite »)*.

**6 · Aucune dépendance ajoutée**, aucune solution d'injection ni de routage : une liste `const` et un
`enum`. ⛔ **Pas de `go_router`, pas de conteneur de DI** — le produit n'a **qu'un seul écran** à ce stade,
et le projet n'a **ni SAST ni scanner de CVE**.

## Alternatives considérées

- **Modules codés en dur dans `hub_page.dart`**. **Écarté** : viole RF-21 frontalement *(ajouter un module
  = éditer l'écran)* et rend l'exigence d'extensibilité **non testable**.
- **`onTap: () {}` pour neutraliser les modules grisés.** **Écarté** — voir point 3 : c'est un interdit
  **révocable par accident**, et il **mentirait à l'accessibilité**. C'est la différence entre *« ne fait
  rien aujourd'hui »* et *« ne peut rien faire »*.
- **Un système de routage nommé** *(`go_router` ou équivalent)* pour préparer les modules futurs.
  **Écarté** : aucune navigation n'existe au périmètre d'US-01.1 — ce serait de l'**architecture
  spéculative**, avec une dépendance non scannée, pour un besoin **qu'aucun AC ne porte**. Réexaminable
  quand un **deuxième écran réel** existera *(nouvel ADR)*.
- **Un registre porteur du placement** *(zone, index de grille, slot de nav)*. **Écarté** : figerait
  précisément ce qu'AC-2 **délègue au design**, et transformerait chaque arbitrage visuel en modification
  du domaine.
- **Découverte dynamique des modules** *(réflexion, annotations, codegen)*. **Écarté** : sans objet pour
  trois modules connus, et `build_runner` a déjà été écarté par [ADR-008](ADR-008-arbitrages-track-full.md)
  pour la même raison — **surface transitive non scannée** et dérive génération ↔ source.

## Conséquences

**Positif** — RF-21 devient **mesurable** *(un test peut assener que le registre expose trois modules dans
l'ordre attendu avec les bons statuts, et qu'une entrée de plus suffit)* ; le hub reste **ignorant** des
modules ; et la délégation de placement à @UXDesigner **n'a aucun coût architectural**.

**Négatif, et à ne pas sur-lire**

- ⚠️ **« Aucune navigation ne part d'un module grisé » ne sera prouvé que pour les gestes TESTÉS**
  *(appui simple, répété, prolongé — ceux qu'AC-2 nomme)*. Un geste non listé **n'est pas couvert** :
  l'absence de gestionnaire le rend improbable, ⛔ **elle ne le prouve pas**.
- ⚠️ **Le registre est `const`, donc statique** : il ne gère **ni activation dynamique, ni ordre
  configurable par l'utilisateur, ni persistance de préférences**. Aucun AC ne l'exige — mais le jour où
  l'un le fera, **c'est un nouvel ADR**, pas une extension silencieuse.
- ⚠️ **L'absence de routage est un choix DATÉ.** Il est juste tant que le produit n'a qu'un écran ; il
  deviendra faux au **deuxième module actif**, et cet ADR devra alors être **remplacé** — *pas étendu par
  habitude*.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
