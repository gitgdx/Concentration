# ADR-010 : Ce que « prouvé » veut dire **quand une base entre** — clauses du track FULL, note I-5 dépassée, et les invariants qui cessent d'être inatteignables

- **Date** : 2026-08-04
- **Statut** : Accepté
- **US associée** : US-01.2 (Gestion des échéances — CRUD), EPIC_01, track FULL
- **Remplace** : la **décision nº 1** d'**[ADR-008](ADR-008-arbitrages-track-full.md)** — *« Un test qui
  monte l'application entière VAUT "E2E dédié" pour ce projet »* (Accepté le 2026-08-01, US-01.1) —
  **pour toute US postérieure à US-01.1**. ⛔ Les **décisions nº 2 et nº 3** d'ADR-008 **restent en
  vigueur** et ne sont pas touchées.

> **Forme suivie, et elle a un précédent mesuré dans ce dépôt** : ADR-007 porte un champ
> `**Remplace** : ADR-006` et **ADR-006 n'a PAS été édité** pour l'annoncer. Un ADR accepté est
> **immuable** : c'est le **remplaçant** qui nomme ce qu'il remplace. ⛔ **ADR-008 n'est donc pas
> modifié**, et son propre §*Conséquences* avait déjà prévu ce moment : *« Si US-01.2 introduit une
> base, cette décision devra être réexaminée — un E2E sans persistance réelle ne dira plus rien de
> l'app entière. C'est un ADR à remplacer, pas à étendre par habitude. »*

## Contexte

### La tension à traiter, et non à masquer

ADR-008 §*Contexte* annonce que ses trois points « fixent ce que "prouvé" voudra dire pour **toute US
FULL du projet** ». Mais le **motif** de sa décision nº 1 est **borné à une seule US**, dans sa propre
lettre :

> *« l'application est **offline-first, sans backend, sans réseau et sans base au périmètre
> d'US-01.1** — **il n'existe aucun "autre bout"** que l'arbre de widgets. »*

⇒ **La PORTÉE annoncée excédait la PORTÉE du motif.** Ce n'est pas un détail rhétorique : c'est
exactement la classe de défaut que ce projet paie le plus cher — **une affirmation plus large que ce
qui la soutient**. ⛔ **Elle est nommée ici, pas corrigée dans ADR-008** *(immuable)*, et **ce
remplacement en est la conséquence**, non une préférence nouvelle.

**US-01.2 introduit une base** *(document JSON local versionné —
[ADR-009](ADR-009-stockage-local-document-json-versionne.md))*. **Le motif d'ADR-008 §1 cesse donc de
tenir** : il existe désormais un « autre bout » — **des octets sur un disque**.

### Le fait qui rend une conclusion **plus stricte** possible, et il est mesuré

Le mécanisme retenu par ADR-009 est **exerçable pour de vrai sur l'hôte, sans appareil**. Mesuré le
2026-08-04 *(Flutter 3.44.7, Dart 3.12.2, projet jetable hors dépôt)* :

```
######## flutter test (branche IO reelle, hote)
00:00 +1: All tests passed!
OCTETS REELS SUR LE DISQUE: 19 octets
```

et, sur les deux finalistes du choix de stockage, **`up` ET `down` réellement observés** :

```
JOURNAL SQFLITE: [onCreate v1, onUpgrade 1->2, v=2, lignes=1, onDowngrade 2->1, v=1, date brute=2026-11-15T23:59]
JOURNAL JSON:    ROUND-TRIP identique=true / octets identiques=true /
                 apres interruption, fichier intact=true / tronque: FormatException reelle
```

⇒ **La position soumise à cet ADR est CONFIRMÉE PAR MESURE, non par accord** : puisque la persistance
**peut** être traversée réellement sous `flutter test`, un E2E qui monterait l'application sur un **faux
dépôt** ne traverserait **toujours qu'un arbre de widgets** — et la clause du track FULL deviendrait
une **fiction**, au moment précis où le produit acquiert son « autre bout ».

### Le défaut d'application déjà constaté sur US-01.1, et qu'il faut fermer

`lib/app/app.dart` porte lui-même le constat, daté du 2026-08-02 :

> *« La revue de code du 2026-08-02 a relevé que **11 tests sur 13 montaient `MaterialApp(home: HubPage)`**
> et non la racine : le contrat de l'ADR n'était donc pas tenu à la lettre. »*

⇒ ADR-008 §1 exigeait de monter **la racine** et **rien ne le vérifiait**. Le contrôle existant,
`check_gherkin_mapping.py`, **ne pouvait pas le voir** : il **compare des TITRES, pas des étapes** — il
l'imprime lui-même *(« Controle de CORRESPONDANCE DE TITRES -- pas de semantique »)*, et c'est ce trou
qui a laissé passer le **bloquant B-2** d'US-01.1 *(deux commandes exigées par un AC, un ADR, une tâche
et une étape Gherkin, absentes **du code ET des assertions**)*.

## Décision

### 1 · Un test qui monte l'application entière **vaut E2E dédié — À LA CONDITION qu'il traverse la persistance RÉELLE**

**Motif NEUF et PLUS STRICT** *(il ne se déduit plus de l'absence de base, mais de la nature de la base
retenue)* : la persistance d'ADR-009 s'exécute **sur l'hôte, avec le MÊME code que sur l'appareil**,
seul le répertoire différant. ⇒ un harnais sur appareil n'ajouterait, **pour la couche de données**,
aucune couche réelle que `flutter test` ne traverse déjà.

**Ce que la clause exige désormais, cumulativement** :

1. **Monter la RACINE** de l'application *(`ConcentrationApp`)*, ⛔ **jamais un sous-arbre**
   *(`MaterialApp(home: …)` est interdit dans les tests E2E)* — le défaut d'US-01.1 est fermé.
2. **Traverser un magasin RÉEL** : un fichier réel, dans un répertoire temporaire réel, lu et écrit par
   **le code de production**. ⛔ **Aucun faux dépôt, aucun magasin en mémoire, aucun mock de la couche
   de données dans un test E2E.**
3. **Assertion sur l'ÉTAT PERSISTÉ** pour tout scénario qui parle du stockage : les scénarios du
   `.feature` disent « *le stockage local contient exactement 1 échéance* », « *l'enregistrement
   illisible est toujours présent et inchangé* », « *j'examine la valeur persistée* » — ⇒ l'assertion
   **lit les octets**, elle ne se contente pas du rendu. **Un test qui n'observe que des widgets ne
   couvre pas une clause de persistance.**
4. Ces tests vivent dans **`test/`** *(et non `integration_test/`)* et sont donc exécutés par le gate
   requis `test` — **reconduit d'ADR-008 §1**, avec son motif : ils **comptent** dans la couverture,
   là où un `integration_test` rapporterait **0 ligne** au cliquet.

**Contrainte attachée, reconduite ET DURCIE** : la correspondance scénario ↔ test reste **vérifiée par
machine** *(`check_gherkin_mapping.py`, job requis)*, et **deux contrôles greppables s'y ajoutent**,
parce qu'un contrôle de titres ne voit ni la racine ni les mocks :

- **`test/e2e/**` ne contient aucune occurrence de `MaterialApp(`** ⇒ la racine est bien montée ;
- **`test/e2e/**` ne contient aucun magasin factice** *(aucune occurrence de `Fake`/`Mock`/`InMemory`
  appliquée à la couche de données)*.

⛔ **Ces deux contrôles se publient comme des commandes exécutables**, jamais comme une ligne de DoD
affirmée — *« un critère de sortie se publie comme un script exécutable »*.

### 2 · La note **I-5** de `MODELE_ECHEANCE.md` est **DÉPASSÉE**, et son invariant est **remplacé**

**Texte dépassé** *(I-5, tel qu'il reste écrit)* : *« Aucun fuseau stocké : instants en heure locale de
l'appareil. ⚠️ Dette assumée, à rouvrir en US-01.2 : dès qu'il y aura persistance, un instant devra
être stocké en **UTC** avec son fuseau, sinon un changement de fuseau **déplacera** les échéances. »*

**Invariant qui le remplace, à compter du 2026-08-04** :

> **I-5 (2026-08-04)** — **une échéance est une DATE CIVILE**, pas un instant absolu. La valeur
> persistée exprime une **date et une heure civiles** et **ne porte ni fuseau, ni décalage, ni marque de
> temps universel**. Le temps restant se calcule **contre l'instant local courant**.

**Motif** : une **date civile n'a pas de fuseau**, donc **un déplacement de fuseau ne PEUT PAS déplacer
l'échéance**. La décision **DISSOUT** le problème qu'I-5 voulait **gérer**, au lieu de le gérer. I-5
avait raison **dans son hypothèse** *(échéance = instant absolu)* ; c'est **l'hypothèse** qui est
écartée — par **arbitrage humain du 2026-08-03** *(clarify nº 7 ; AC-14 promu `Should` → `Must`)*.

**Forme retenue pour la correction, et elle est délibérée** : `MODELE_ECHEANCE.md` est un **document de
design**, pas un ADR ⇒ il **est** maintenu. Mais ⛔ **la ligne I-5 n'est PAS repeinte** : le texte
dépassé **reste visible**, **marqué et daté**, et le nouvel invariant est **ajouté** au-dessous. *« On
date, on ne repeint pas »* — et un lecteur d'audit doit pouvoir constater **ce qui était prescrit**
avant de lire **ce qui a été décidé**.
⚠️ **Preuve du dépassement, mesurée** : la **valeur persistée** produite par le mécanisme d'ADR-009 est
`"2026-11-15T23:59"` — ⛔ **ni `Z`, ni décalage** *(cf. les journaux ci-dessus)*.

**Ce qui NE change PAS, et qu'il serait faux d'étendre** :

- **I-3** *(`description` peut être vide)* **reste vrai** : la description obligatoire vit **au point de
  SAISIE** *(AC-2)*, pas dans l'entité. Les confondre casserait **AC-3 « Erreur » d'US-01.1** *(une
  tuile à description vide doit rester rendue)*.
- **I-4** *(`dateEcheance` peut être dans le passé)* **reste vrai** : c'est l'état `ÉCHUE`, **normal**.
  Le refus du passé d'**AC-4** vit **à la saisie et à l'édition**, ⛔ **jamais à la lecture** — sans
  quoi une échue enregistrée serait rejetée au démarrage.
- **I-7** *(aucun champ de persistance dans l'entité)* **reste vrai** : `schemaVersion` est porté par le
  **DOCUMENT**, pas par `Echeance`. ⛔ Ni `createdAt`, ni `dirty`, ni `deletedAt`, ni `version` dans
  l'entité — la modélisation spéculative reste interdite.

### 3 · Un invariant de sécurité ne repose **jamais** sur un `assert` — I-2 devient une validation de frontière

**Fait établi** *(audit sécurité d'US-01.1, **NB-1**, prouvé dans les deux sens par sonde `dart`)* :
l'invariant **I-2** *(`id` non vide)* est porté par un **`assert`**, donc **retiré en release**. Il
était **inatteignable** tant que seules des constantes du dépôt construisaient des `Echeance` ; il
**CESSE de l'être dès qu'on lit des données persistées**.

**Décision** : tout invariant portant sur une donnée **venant du disque** est vérifié par du **code
exécuté en release**, à la **frontière de désérialisation** *(`Echeance.depuisDonnee`, qui rend `null`
et fait **ignorer** l'enregistrement)*. ⛔ **Un `assert` peut rester comme documentation d'un contrat de
programmation interne, mais il ne compte JAMAIS comme barrière** — et **aucune clause d'AC ne doit
s'appuyer sur lui**.
📌 Cela donne enfin un **appelant réel** à `depuisDonnee`, dont le finding **N-6** *(revue de code
d'US-01.1)* relevait qu'elle **n'en avait aucun** ⇒ le comportement « donnée illisible » **n'était pas
exerçable**. Il le devient *(AC-11)*.

## Alternatives considérées

- **Étendre ADR-008 §1 par habitude** *(« un test qui monte l'app suffit, point »)* — **écarté**, et
  c'est ADR-008 lui-même qui l'interdit : *« C'est un ADR à remplacer, pas à étendre par habitude. »*
  Reconduire la conclusion **sans reconduire le motif** aurait produit exactement l'écart
  portée/justification que ce document dénonce au §Contexte.
- **Financer un appareil en CI** *(émulateur Android, ou `chromedriver` + `integration_test`)* pour un
  E2E au sens littéral — **écarté, mêmes motifs qu'ADR-008 et un de plus, mesuré** : ces tests
  rapporteraient **0 ligne** au gate de couverture *(`flutter test --coverage` ne couvre que ce que
  `test/` exerce)* et **durciraient** un cliquet **à marge nulle**, tandis que l'apport réel pour la
  couche de données est **nul** — le **même code** est exécuté sur l'hôte *(ADR-009 : seul le répertoire
  diffère)*. ⚠️ **Ce que cela laisse non prouvé est nommé ci-dessous, pas gommé.**
- **Autoriser un faux dépôt dans les E2E, « le temps de démarrer »** — **écarté**. C'est la seule
  option qui aurait rendu la clause **vide** : monter l'application sur un magasin en mémoire, dans une
  US dont l'objet **est** la persistance, aurait produit **13 tests verts ne traversant aucun octet**.
  Et le projet a déjà **mesuré** ce que coûte un vert qui ne mesure rien *(sept instruments de contrôle
  faux, deux faux verts en US-01.1)*.
- **Exiger que TOUS les tests montent la racine** *(pas seulement les E2E)* — **écarté** : un test
  unitaire de widget doit pouvoir monter **son** widget, sinon chaque test paie le coût de l'arbre
  entier et **perd son pouvoir de localisation** *(un échec ne dirait plus quel composant est fautif)*.
  La contrainte est donc **ciblée sur `test/e2e/**`**, où elle est **vérifiable par grep**.
- **Réécrire la ligne I-5 de `MODELE_ECHEANCE.md`** — **écarté**. Le corpus a **payé cinq fois** la
  suppression d'un texte fautif : *« un correctif qui s'explique produit mécaniquement des occurrences
  de ce qu'il corrige »*, et **effacer** empêche l'audit de vérifier ce qui était prescrit. **Marquage
  daté + invariant ajouté** — la convention du projet, appliquée.
- **Créer un ADR séparé pour la note I-5** — **écarté** : la date civile et la clause E2E ont **la même
  cause** *(l'entrée d'une base)* et **le même objet** *(ce qui est prouvé, et sur quoi)*. Deux ADR
  auraient **dupliqué le motif**, et *« une règle n'existe qu'en un seul exemplaire — deux copies
  dérivent »*, vérifié trois fois dans ce corpus.

## Conséquences

**Positif**

- La clause E2E du track FULL **redevient contraignante** au moment où elle risquait de devenir
  décorative : elle exige **des octets réels**, pas un arbre de widgets.
- Le **défaut d'application d'US-01.1** *(11 tests sur 13 montant un sous-arbre)* est **fermé par deux
  contrôles greppables**, là où le contrôle existant — **de titres** — ne pouvait structurellement rien
  voir. **La même famille de trou que le bloquant B-2.**
- **AC-14 devient prouvable sur le disque** : la valeur persistée ne porte **ni fuseau ni décalage**,
  donc **aucune conversion n'est possible, donc aucun décalage** — la clause passe de « non mesurable »
  à « **structurellement vraie et assertable** ».
- **NB-1 cesse d'être un finding dormant** : l'invariant `id` non vide devient une **barrière exécutée
  en release**, et `depuisDonnee` **acquiert l'appelant** que **N-6** lui reprochait de ne pas avoir.
- **Aucune dépendance, aucun runner, aucune infra** n'est ajouté par cette décision.

**Négatif, et à ne pas sur-lire**

- ⛔ **Cet ADR ne prouve rien sur l'application.** Il fixe ce qui devra être prouvé. **Aucun test
  n'existe à sa date**, **aucun scénario d'US-01.2 n'est exécuté**, et **aucune ligne de `lib/` n'est
  écrite**.
- ⚠️ **« Monter l'app + persistance réelle » n'est toujours PAS « exécuter l'app ».** Ce qui reste
  **non traversé**, et doit rester nommé : le **moteur de rendu réel**, le **cycle de vie de la
  plateforme** *(kill OS, reprise — borne **NM-1**)*, une **mise à jour d'application installée**
  *(borne **NM-4**)*, le **vrai répertoire de documents** de l'appareil *(`path_provider`, borne
  **nouvelle**, introduite par ADR-009)*, et un **changement de fuseau ou une transition heure
  d'été/hiver observés** *(borne **NM-5**, réduite mais non levée)*. **Toutes se lèvent avec US-01.3, pas
  ici.**
- ⚠️ **Les deux contrôles greppables sont SYNTAXIQUES.** Ils voient un `MaterialApp(` et un nom de
  classe factice ; ils **ne voient pas** un faux dépôt nommé autrement, ni une assertion qui **regarde
  un widget** en croyant observer le stockage. ⛔ **Ils réduisent le risque, ils ne le suppriment pas** —
  et **aucune machine ne lit l'intention** *(borne que `check_gherkin_mapping.py` s'impose déjà à
  lui-même)*. La barrière restante est la **revue**.
- ⚠️ **Ce remplacement ne vaut que pour l'avenir.** **US-01.1 reste certifiée sous ADR-008 §1** et sa
  clause **n'est pas rejugée** : ⛔ **ce document n'est pas rétroactif**, et il ne réécrit **aucune
  certification**. Ce qu'elles attestaient — **avec leurs bornes** — est inchangé.
- ⚠️ **Les décisions nº 2 et nº 3 d'ADR-008 restent en vigueur, avec leurs limites intactes** : le
  **critère 27 demeure NON LEVÉ**, la **provenance humaine reste non prouvable** sur ce dépôt
  *(`reviewDecision` vide, `mergedBy.is_bot` faux même pour un agent)*, et la revue humaine reste une
  **obligation de process, non enforced**. ⛔ **Rien ici ne les améliore.** La décision nº 3 change
  seulement de **contenu attendu** : @DataEngineer ne livre plus un modèle « réel mais borné » **en
  mémoire**, mais le **premier schéma persisté du projet**.
- ⚠️ **Aucun événement de trace ne porte cet arbitrage** : le catalogue n'a **aucun** événement
  d'arbitrage, d'amendement documentaire ni de **remplacement d'ADR**, et rien ne rattache un verdict à
  un **commit** *(dette du 2026-08-02, NB-6 : un visa d'audit **périme en silence**)*. Même famille
  structurelle que l'absence d'événement de **clôture d'EPIC** et d'**extinction de dérogation**. La
  décision vit dans le **corpus durable** *(cet ADR, `MODELE_ECHEANCE.md` daté, le Story File)*.
- 📌 **Dette nommée, non traitée ici** : `TRACKS.md` continue de décrire la clause E2E **sans renvoyer
  à cet ADR**, comme il le faisait déjà pour ADR-008 *(qui a dû l'amender pour la seule clause de revue
  humaine)*. ⛔ **Délibérément non édité** : `TRACKS.md` gouverne **toutes** les US, et ADR-008 a établi
  qu'y toucher exige son propre arbitrage. **Candidat `/audit-methodo`.**

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
