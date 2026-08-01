# ADR-008 : Arbitrages des trois clauses du track FULL, à l'ouverture d'US-01.1

- **Date** : 2026-08-01
- **Statut** : Accepté
- **US associée** : US-01.1 (Affichage Hub & grille d'échéances) — première US **produit** du projet

## Contexte

US-01.1 est la **première US applicative** du projet : EPIC_00 est clos et, à sa clôture, la factory
n'avait **jamais tourné sur du code produit** — `lib/` compte **1 fichier de 63 lignes**, `test/` **1
fichier**, et les **8 fichiers `.feature`** du dépôt n'ont **ni step definition ni runner**, donc
**aucun des 116 scénarios Gherkin écrits n'a jamais été exécuté**.

US-01.1 est en track **FULL** — sélection **non contestée** : les critères de `TRACKS.md` sont
objectivement réunis *(nouvelle EPIC, nouvelle page)*. Or **trois des quatre clauses propres au track
FULL entrent en collision avec l'état réel du dépôt**, et chacune bloquerait l'Integration Lock :

1. **« Scénarios E2E dédiés implémentés (pas seulement des unitaires) avant certification. »**
   La tâche **T12** du Story File prévoit `integration_test/hub_echeances_test.dart`. **Mesuré** : le
   paquet `integration_test` est **absent de `pubspec.yaml`**, le répertoire **n'existe pas**, et la CI
   **n'a aucun appareil** — les gates construisent le **web** seul, sur `ubuntu-latest`. **T12 est donc
   inexécutable en l'état.**
2. **« Revue humaine explicite de la PR (l'approbation GitHub ne peut pas venir d'un agent). »**
   **Aucune barrière machine ne la soutient** : la cible de protection porte
   `required_approving_review_count: 0`, et sur un dépôt à **un seul compte** GitHub **interdit à
   l'auteur d'approuver sa propre PR** ⇒ `reviewDecision` reste **vide**. C'est le **critère 27
   d'US-00.7**, arbitré pour cause de plateforme et **demeuré non levé**. Corollaire déjà payé par une
   violation réelle : **`mergedBy.is_bot` rend `false` même pour une fusion faite par un agent**, qui
   opère avec le jeton de l'humain.
3. **« Design Data ET UX obligatoires (pas de N/A). »**
   US-01.1 **n'a aucune persistance** : elle affiche des **données d'exemple injectées**, et le choix de
   techno **comme** le schéma sont délibérément reportés à **US-01.2**
   *(`STACK_PROFILE.md` §DataEngineer, et ADR-005 qui attend d'y être instancié)*.

Ces trois points sont des **décisions structurantes** : ils fixent ce que « prouvé » voudra dire pour
toute US FULL du projet. D'où cet ADR. ⚠️ **`TRACKS.md` n'a ni numéro de version ni clause de
révision** *(contrairement à la Constitution)* : **rien n'impose** de PR dédiée ni d'attestation pour
l'amender — raison supplémentaire d'inscrire la décision ici, où elle est **immuable**.

## Décision

**1 · Un test qui monte l'application entière VAUT « E2E dédié » pour ce projet.**
Un test de widget qui **monte l'application complète** et agit sur elle *(`pumpWidget` de la racine,
puis interactions et assertions sur le rendu)* satisfait la clause. **Motif** : l'application est
**offline-first, sans backend, sans réseau et sans base au périmètre d'US-01.1** — **il n'existe aucun
« autre bout »** que l'arbre de widgets. Un harnais sur appareil n'ajouterait **aucune couche réelle à
traverser**. Ces tests vivent dans **`test/`** *(et non `integration_test/`)*, sont donc **exécutés par
le gate `flutter test --coverage`** existant.
**Contrainte attachée, non négociable** : la correspondance scénario ↔ test doit être **vérifiée par
machine**, jamais déclarée — **tout titre de scénario d'un `.feature` de track FULL doit apparaître
verbatim dans un nom de test**, et l'écart *(manquant **ou** orphelin)* doit **échouer**.

**2 · La clause « revue humaine explicite » est reformulée en obligation de PROCESS, non enforced.**
Elle exige une **attestation humaine datée** avant fusion, et **rien de plus** — parce que rien de plus
n'est **vrai** aujourd'hui. ⛔ **Cette reformulation ne lève pas le critère 27** et **ne crée aucune
garantie** : elle **cesse de laisser croire** qu'une barrière existe. La **voie de sortie réelle**
— **identité distincte pour les agents** *(2ᵉ compte ou GitHub App)* puis `restrictions`, qui rendrait la
fusion par un agent **impossible** et non seulement interdite — **reste portée par US-00.8**, avec sa
réserve non levée : `restrictions` pourrait être réservé aux dépôts d'organisation.

**3 · Design Data est livré, RÉEL mais BORNÉ — aucun `N/A`.**
@DataEngineer livre **ce qui existe vraiment à ce périmètre** : l'entité **`Echeance` immuable** et ses
**invariants**, l'énumération **`TimeUnit`**, et l'**ordre de tri strict** *(échéance croissante, les
dépassées en tête)*. ⛔ **Aucun schéma persistant, aucune migration** — ils appartiennent à US-01.2, qui
**hérite** de ce modèle au moment de choisir la techno. La clause du track est ainsi satisfaite **à la
lettre, sans fiction**.

## Alternatives considérées

- **Financer un appareil en CI** *(émulateur Android ou chromedriver + `integration_test`)* pour un E2E
  au sens littéral. **Écarté** : coût d'infra CI réel, temps de job, actions tierces supplémentaires
  alors qu'**aucune n'est épinglée** *(dette connue)* — et surtout, ⚠️ **ces E2E rapporteraient `0`
  ligne au gate de couverture**, puisque `flutter test --coverage` ne couvre que `test/`. Ils rendraient
  donc le **cliquet à 89,4 % plus dur à tenir** tout en coûtant davantage. **Le bénéfice mesurable est
  du côté opposé** : les 13 tests montant l'app **comptent** dans la couverture.
- **Requalifier US-01.1 en track STANDARD**, ce qui ferait disparaître les trois clauses. **Écarté** :
  les critères FULL sont **objectivement réunis**, et `/audit-methodo` vérifie **a posteriori** le
  respect des critères de track ⇒ ce serait une **violation signalée**. Choisir un track d'après la
  difficulté de ses obligations, c'est adapter la règle au résultat.
- **Un runner Gherkin** *(`bdd_widget_test` par codegen, ou `flutter_gherkin`)*. **Écarté pour
  US-01.1** : `flutter_gherkin` repose sur `integration_test`/driver, donc sur un appareil ;
  `bdd_widget_test` fonctionnerait sous `flutter test`, mais il ajoute `build_runner` et sa **grosse
  arborescence transitive** dans un projet qui n'a **ni SAST ni scanner de CVE** *(`dart pub outdated`
  mesure l'obsolescence)* ⇒ **surface non scannée**, et il introduit une **dérive
  génération ↔ source** si le codegen n'est pas vérifié en CI — soit exactement le défaut « deux copies
  d'une règle dérivent », **vérifié trois fois dans ce corpus**. **Réexaminable** si le nombre de
  scénarios produit croît fortement ; le contrôle de correspondance survivrait à cette migration.
- **Étendre la voie retenue aux 103 scénarios de gouvernance.** **Sans objet** : ils décrivent l'**état
  de l'API GitHub**, des **gates CI**, une **config `gitleaks`**, un **registre d'ADR** — *« la branche
  principale est déclarée protégée par l'API »* n'est pas un test de widget. **Aucun runner Flutter ne
  peut les exécuter.** Leur vérification **existe déjà** sous forme de sorties d'outils, de selftests et
  de gates ; le défaut est que les DoD les **comptent comme des tests** ⇒ **ré-étiquetage** en
  *spécification*, pas de runner.
- **Amender la clause Design Data** en « obligatoire sauf absence de persistance ». **Écarté** :
  assouplir une exigence pour **toutes** les US FULL futures — y compris celles qui toucheront un schéma
  — sur la base d'**un seul cas**. Le modèle en mémoire satisfait la clause sans l'affaiblir.

## Conséquences

**Positif**

- **T12 devient exécutable** : les scénarios de track FULL tournent dans le gate `test`, qui est un
  **contexte requis** — donc ils tournent **sur chaque PR**, sans infra nouvelle et **sans aucune
  dépendance ajoutée** *(`flutter_test` suffit)*.
- La correspondance scénario ↔ test devient **falsifiable et rejouable**, au lieu d'être une **ligne de
  DoD affirmée** — c'est la doctrine du corpus *(« un critère de sortie se publie comme un script
  exécutable »)*.
- Les 13 tests **contribuent à la couverture**, ce qui **aide** à tenir le cliquet sur la première US
  qui ajoute massivement du code à `lib/`.
- `TRACKS.md` **cesse d'affirmer une revue soutenue par une barrière** qui n'existe pas — une
  sous-affirmation de moins dans le corpus, la classe de défaut qu'US-00.7 a payée **cinq fois**.
- Design Data produit un livrable **utile et hérité** par US-01.2, au lieu d'un `N/A` de forme.

**Négatif, et à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve rien sur l'application** : il fixe ce qui devra être prouvé. **Aucun test
  n'existe encore**, et **aucun scénario n'est exécuté à la date de cet ADR**.
- ⛔ **Le critère 27 demeure NON LEVÉ** et la **provenance humaine reste non prouvable** sur ce dépôt.
  La clause reformulée est **plus honnête, pas plus contraignante** — elle **abaisse** l'exigence écrite
  au niveau de ce qui est réellement tenu.
- ⚠️ **« Monter l'app entière » n'est pas « exécuter l'app »** : un test de widget ne traverse ni le
  moteur de rendu réel, ni le cycle de vie de la plateforme, ni la persistance *(absente ici)*. Si
  US-01.2 introduit une base, **cette décision devra être réexaminée** — un E2E sans persistance réelle
  ne dira plus rien de l'app entière. **C'est un ADR à remplacer, pas à étendre par habitude.**
- ⚠️ **Le ré-étiquetage des 103 scénarios de gouvernance rendra visible** que sept US certifiées
  portaient des lignes de DoD comptant des scénarios **jamais exécutés**. C'est une **rectification
  datée**, pas une réécriture : les US restent certifiées, et ce que leurs certifications attestaient
  *(les instruments, avec leurs bornes)* est inchangé.
- ⚠️ **Aucun événement de trace ne porte cet arbitrage** : le catalogue n'a **aucun** événement
  d'arbitrage ou d'amendement documentaire, et `EVT_ARCHI_VALIDATED` **exige `EVT_STORY_READY`**, absent
  de la trace d'US-01.1. Même famille structurelle que l'absence d'événement de **clôture d'EPIC** et
  d'**extinction de dérogation** — dettes déjà nommées. La décision vit donc dans le **corpus durable**
  *(cet ADR, `TRACKS.md`, le Story File, le PROJECT_LOG)*.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
