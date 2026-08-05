# ADR-011 : Gestion d'état et injection de dépendances — **rien au-delà du SDK**, injection par la racine

- **Date** : 2026-08-04
- **Statut** : Accepté
- **US associée** : US-01.2 (Gestion des échéances — CRUD), EPIC_01, track FULL

> **Pourquoi cet ADR existe** : @ProductOwner a nommé cette décision comme **structurante et différée**
> — *« gestion d'état / injection de dépendances, volontairement différée par US-01.1 "à réévaluer quand
> la couche `data` réelle s'ouvrira" »*. Elle s'ouvre **ici** : c'est la première US qui a un état
> **mutable et partagé** *(la liste des échéances, modifiée depuis la page de gestion, observée par la
> grille du hub)*.

## Contexte

- US-01.1 n'avait **aucun état mutable** : `HubPage` recevait une `List<Echeance>` **immuable** par
  constructeur, et `EcheancesGrid` ne se rafraîchissait que sur un `Timer`. Aucun choix n'était requis,
  et **aucun n'a été fait** — délibérément.
- US-01.2 change cela : **AC-6 « Nominal »** et **AC-13 « Limite »** exigent que *« la liste de gestion
  **et** la grille reflètent la nouvelle valeur — nombre et couleur recalculés, **sans redémarrage** »*.
  ⇒ il faut **une source de vérité unique** et **un mécanisme de notification** entre deux écrans.
- **Contrainte de coût de dépendance, mesurée et non négociable** : le projet n'a **aucun SAST** et
  **aucun scanner de CVE** *(`run_gates --gate sast` n'existe pas ; `dart pub outdated` mesure
  l'obsolescence)* ⇒ **chaque paquet ajouté ne reçoit qu'une revue HUMAINE**.
  [ADR-009](ADR-009-stockage-local-document-json-versionne.md) vient d'écarter `drift` (+49 paquets) sur
  ce motif, après qu'ADR-008 eut écarté `bdd_widget_test` sur le même. **La cohérence l'oblige ici
  aussi.**
- **Contrainte de couverture** : le cliquet est à `adapter.components.app.coverage_ratchet.value` avec
  une **marge nulle** *(mesuré le 2026-08-04 : **380/399 lignes = 95,2381 %**)*. Un appareillage
  d'injection ajoute des lignes de **câblage** difficilement atteignables en test — elles coûtent
  directement du rouge sur un **contexte requis**.

## Décision

**1 · Aucun paquet de gestion d'état ni d'injection de dépendances.** L'état partagé est porté par un
**`ChangeNotifier`** *(`package:flutter/foundation.dart`, **SDK**)* et consommé par
**`ListenableBuilder` / `ValueListenableBuilder`**. **Coût en dépendances : `+0`.**

**2 · Injection par la RACINE, par constructeur** — la convention qu'US-01.1 a déjà établie
*(`ConcentrationApp(clock: …)`)* est **reconduite et étendue** : `main()` est le **seul** point de
composition ; il construit le magasin de plateforme, le dépôt, puis le `ChangeNotifier`, et les passe à
`ConcentrationApp`. ⛔ **Aucun singleton, aucun `service locator`, aucune variable globale mutable,
aucun `GetIt`.**

**3 · Le domaine ne connaît que des PORTS.** `lib/features/echeances/domain/` définit l'interface du
dépôt *(port)* ; `lib/features/echeances/data/` en fournit l'implémentation *(adaptateur)*. ⛔ **Aucun
`import` de `data/` depuis `domain/`**, ⛔ **aucun `import` de Flutter dans `domain/`** *(le domaine
reste du Dart pur, donc testable sans harnais de widgets)*.

**4 · La dépendance au temps reste explicite** : `Clock` est injectée, ⛔ **jamais `DateTime.now()` dans
la logique** *(ADR-002, reconduit)*. C'est ce qui rend testables les cas limites d'AC-3, AC-4 et AC-5.

**5 · Le seam de test est le DÉPÔT, pas l'écran.** Les tests montent la **racine** avec un dépôt réel
adossé à un **fichier temporaire réel** *(exigence d'[ADR-010](ADR-010-clauses-track-full-avec-persistance.md)
§1)*. ⛔ **Le seam `ConcentrationApp(echeances: List<Echeance>)` livré par US-01.1 est SUPPRIMÉ** : il
injectait des données **déjà chargées**, donc il court-circuiterait la persistance et rendrait la clause
E2E décorative.

## Alternatives considérées

*Deltas de paquets **mesurés** le 2026-08-04 dans un projet Flutter jetable (base = 28 paquets) :*

| Option | Δ paquets | Verdict |
|---|---|---|
| **`ChangeNotifier` du SDK** *(retenu)* | **+0** | ✅ |
| `get_it` | +1 | écarté |
| `provider` | +2 | écarté |
| `flutter_bloc` | +4 | écarté |
| `flutter_riverpod` | **+40** | écarté |

- **`provider` (+2)** — **écarté**, et c'était le concurrent le plus sérieux : il coûte peu et il est
  très répandu. Motif du refus : il n'apporte, à ce périmètre, que le **passage implicite par le
  contexte** — or il n'y a **qu'un** état partagé et **deux** écrans, tous deux atteignables par
  constructeur depuis la racine. ⇒ **bénéfice nul, surface non nulle**, dans un projet où la seule
  barrière est une revue humaine. ⚠️ **Réexaminable** dès qu'un troisième module persisté
  *(Respiration, Concentration — RF-21)* rendra le passage par constructeur réellement pénible : ce
  sera **un nouvel ADR**.
- **`flutter_riverpod` (+40)** — **écarté sans hésitation** : **40 paquets** non scannés pour un état
  qui tient dans un `ChangeNotifier`. C'est l'ordre de grandeur de `drift`, déjà écarté pour ce motif.
- **`flutter_bloc` (+4)** — **écarté** : impose un formalisme *(événements, états, transitions)*
  proportionné à des machines à états complexes. Ici, le seul état est **une liste** ; le formalisme
  serait de la **cérémonie**, et chaque ligne de cérémonie **coûte de la couverture**.
- **`get_it` (+1)** — **écarté** : c'est un **service locator**, donc un **état global mutable**. Il
  rend les dépendances **invisibles dans les signatures** et les tests **dépendants d'un ordre
  d'enregistrement**. Un paquet à `+1` reste un mauvais échange contre une régression de conception.
- **`InheritedWidget` écrit à la main** — **écarté** : reproduirait `provider` **en moins bien testé**,
  pour le même bénéfice nul à ce périmètre. `ListenableBuilder` du SDK suffit.
- **Conserver le seam `ConcentrationApp(echeances: …)`** *(en plus du dépôt)* — **écarté, et c'est le
  point le plus important de cet ADR** : ce seam permettrait d'écrire des tests « E2E » **verts sans
  toucher un octet**, exactement ce qu'ADR-010 §1 interdit. **Deux seams, c'est une règle en deux
  exemplaires — et deux copies dérivent** *(vérifié trois fois dans ce corpus)*. ⛔ **Il est supprimé,
  pas laissé « au cas où ».**

## Conséquences

**Positif**

- **`+0` dépendance** : rien de nouveau à faire relire à un humain, rien de nouveau à ne pas scanner.
- Les dépendances restent **visibles dans les signatures** ⇒ un test qui compile est un test dont les
  dépendances sont explicites ; **aucun ordre d'initialisation global** à respecter.
- Le **domaine reste du Dart pur** ⇒ validation *(AC-2 à AC-6)* et migrations *(AC-12)* sont testables
  **sans `WidgetTester`**, donc rapidement et avec des assertions précises — et **elles comptent dans la
  couverture**.
- La suppression du seam de données **aligne le code sur ADR-010** : il devient **impossible** d'écrire
  un E2E qui contourne la persistance **sans ajouter du code pour le faire** — donc **visible en revue**.

**Négatif, et à ne pas sur-lire**

- ⚠️ **Le câblage par constructeur devient verbeux** dès qu'un écran s'ajoute. C'est le **coût assumé**
  du `+0`, et le **seuil de réexamen est nommé** : un troisième module persisté.
- ⚠️ **`ChangeNotifier` n'offre aucune garantie d'immuabilité** : c'est à l'implémentation d'exposer une
  **liste non modifiable** et de recharger depuis le dépôt, ⛔ **jamais de muter une liste partagée en
  place** — sans quoi I-1 *(entité immuable, ordre déterministe)* perdrait son effet.
- ⚠️ **La suppression du seam `echeances:` casse des tests d'US-01.1** *(`lancerAvec` dans
  `test/e2e/hub_echeances_test.dart`)*. **Ce n'est pas un effet de bord : c'est une conséquence
  assumée**, et elle est **inscrite comme tâche dédiée** dans le Story File d'US-01.2, avec le fait
  qu'**US-01.1 est `🧪 PASS` et non encore certifiée** ⇒ **question de séquencement à trancher par
  l'humain**, pas par un agent.
- ⚠️ **Aucun événement de trace ne porte cette décision** *(le catalogue n'a aucun événement de choix
  technique)* — même famille que les dettes déjà nommées. Elle vit dans le **corpus durable**.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
