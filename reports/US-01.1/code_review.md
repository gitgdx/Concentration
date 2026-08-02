# Audit de revue de code — US-01.1 « Affichage Hub & grille d'échéances »

| Champ | Valeur |
|---|---|
| **Agent** | @CodeReviewer — **contexte frais** (n'a pas participé à la session de production) |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **Branche auditée** | `feat/US-01.1-dev-presentation` |
| **Commit audité** | **`24fe59a1120d65960398b3455bcdb847ff57c590`** (`24fe59a`) |
| **Périmètre** | `git diff main...HEAD` — 50 fichiers, +3913 / −119 |
| **Documents de référence** | Story File US-01.1 · ADR-002 · ADR-003 · ADR-004 · ADR-008 · `DESIGN_SYSTEM.md` · `MODELE_ECHEANCE.md` · `tests/features/US-01.1-*.feature` |

---

## 🔴 VERDICT : **FAILED**

**2 findings bloquants · 13 findings non bloquants.**

Le verdict **ne porte pas sur la qualité générale du livré**, qui est élevée : **tous les gates
statiques sont verts**, la couverture (94,1 %) et le décompte de tests (100) annoncés par la session
sont **exacts et re-mesurés**, et **3 des 4 correctifs revendiqués sont réellement assertionnés**
*(prouvé par mutation)*. Le verdict tient à **deux trous précis et falsifiables** :

1. **La décision d'ADR-003 §4 est du code neuf sans test effectif, et l'assertion censée la couvrir est
   un FAUX VERT** — prouvé par mutation : on peut supprimer la décision, la remplacer par le
   comportement que l'ADR **interdit**, obtenir **du rouge pur `#ff0000`**, et la suite reste
   **100/100 verte**.
2. **Une clause d'AC-2, une décision d'ADR-004 §5, une tâche T10 et une étape Gherkin exigent toutes la
   même chose — les commandes « ajout / réglages » de la barre basse rendues non-interactives — et il
   n'existe ni code ni assertion pour cela.**

---

## 1. Méthode

⚠️ Conformément à la doctrine du projet *(« un contrôle portant son mutant a été juste 7 fois sur 7 ;
un contrôle purement lexical, faux 7 fois sur 7 »,
[`tension_structurelle.md`](../US-00.5/tension_structurelle.md))*, cet audit **ne juge pas sur
relecture**. Chaque affirmation ci-dessous est adossée à une **exécution** dont la sortie est collée.

Les **quatre correctifs** que la session déclare avoir appliqués en cours de route ont été soumis à un
**test de mutation** : chaque correctif a été **retiré**, et la suite relancée. Un correctif dont le
retrait laisse la suite verte **n'est pas assertionné**.

⛔ **Le dépôt n'a PAS été modifié.** Les mutations ont été exécutées dans une **copie isolée**
(`scratchpad/mutants/`, obtenue par `cp pubspec.* analysis_options.yaml lib test`), dont le
`flutter test` de référence rend **100/100 verts**, identique au dépôt.

---

## 2. Sorties d'outils — gates statiques

### `python scripts/run_gates.py --all` → **exit 0**

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 28 files (0 changed) in 0.24 seconds.
✅ app.format
▶ app.analyze — (.) $ flutter analyze
No issues found! (ran in 25.5s)
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:07 +100: All tests passed!
Couverture de lignes : 94.1% (364/387) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigne le 2026-07-31 a US-00.6
  [HAUSSE] 94.06% (364/387) > cliquet 89.4%. Valeur a consigner (arrondie VERS LE BAS) : 94.0
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
✅ app.test
▶ app.deps_audit — (.) $ dart pub outdated --show-all
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

➡️ **0 erreur de lint, 0 erreur d'analyse statique, 0 écart de formatage.** Aucun finding bloquant de
ce côté.

### `python scripts/check_gherkin_mapping.py` → **exit 0**

```
T12b -- correspondance scenario <-> test (racine : ...\Concentration)
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests

OK : chaque scenario a son test et chaque test son scenario.
Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
```

### `python scripts/check_gherkin_mapping.py --selftest` → **exit 0**

```
  [OK] corpus conforme => 0 ecart
  [OK] mutant test retire => refus qui NOMME le scenario
  [OK] mutant test orphelin => refus DISTINCT du manquant
  [OK] mutant titre renomme => manquant ET orphelin
  [OK] un titre a apostrophe est lu correctement
  [OK] les deux motifs sont DISTINCTS

Autotest : 6 assertions, 0 echec(s), 1 couple(s) sous controle.
```

✅ **Ce script est de bonne facture** : il **lit** les `.feature` (aucun titre recopié), compare des
**ensembles**, nomme l'écart **dans les deux sens**, **porte son autotest de mutation**, et il est
branché dans le job **REQUIS** `📋 Governance` (`ci.yml`, T12c — vérifié dans le diff). Il **annonce
lui-même sa borne** *(« correspondance de TITRES — pas de sémantique »)*, ce qui est exactement la
posture attendue. Voir néanmoins **N-5** : cette borne est **atteinte en pratique**.

### `python scripts/check_epic00_docs.py` → **exit 0**

```
OK : 11 livrables presents et porteurs de leur marqueur.
Controle de PRESENCE et de FRAICHEUR -- pas de veracite du contenu.
```

➡️ **Aucune régression documentaire sur EPIC_00.**

---

## 3. Vérification des affirmations de la session

| Affirmation de la session | Vérifiée par | Verdict |
|---|---|---|
| « **100 tests** verts » | `flutter test` → `00:07 +100: All tests passed!` | ✅ **EXACT** |
| « **94,1 % de couverture** » | `check_flutter_coverage.py` → `94.1% (364/387)` ; recompté depuis `coverage/lcov.info` : **387 lignes instrumentées, 23 non couvertes** | ✅ **EXACT** |
| Correctif « **bug de gamut** » assertionné | **mutation M1** | ❌ **FAUX — voir B-1** |
| Correctif « **débordement de tuile** » assertionné | **mutations M2 / M2b** | 🟠 **PARTIEL — voir N-3** |
| Correctif « **grille défilante** » assertionné | **mutation M3** | ✅ **VRAI** |
| Correctif « **débordement de barre basse** » assertionné | **mutation M4** | ✅ **VRAI** |

### Table de mutation — sorties brutes

| # | Mutant appliqué (copie isolée) | Résultat | Sortie |
|---|---|---|---|
| **M1** | `oklab.dart` : la boucle de **réduction de chroma** (ADR-003 §4) remplacée par `return _depuisLineaire(_versLineaireRgb());` — c'est-à-dire l'**écrêtage par canal que l'ADR interdit** | 🔴 **SURVIT** | `00:08 +100: All tests passed!` |
| **M2** | `echeance_tile.dart` : `FittedBox(scaleDown)` retiré, `Expanded` conservé | 🔴 **SURVIT** | `00:05 +100: All tests passed!` |
| **M2b** | `echeance_tile.dart` : `Text` nu (ni `Expanded` ni `FittedBox`) | ✅ **TUÉ** | `00:05 +96 -4: Some tests failed.` · `A RenderFlex overflowed by 27 pixels on the bottom.` |
| **M3** | `echeances_grid.dart` : retour à un `GridView.count` **défilant** (état pré-correctif décrit en T9) | ✅ **TUÉ** | `00:09 +97 -3: Some tests failed.` |
| **M4** | `hub_page.dart` : `Expanded` retiré des entrées de la barre basse (état pré-correctif de `b00eb4c`) | ✅ **TUÉ** | `00:08 +96 -4: Some tests failed.` · `A RenderFlex overflowed by 133 pixels on the right.` · `... by 63 pixels on the right.` |

**Sonde de mesure sur M1** (test jetable, copie isolée, valeur **lue** et non écrite à la main) :

```
### ORIGINAL (réduction de chroma, ADR-003 §4) ###
SONDE rgb=#ca5a1b L=0.5998 chroma=0.1589 deltaL=0.0002
### MUTANT (écrêtage par canal, INTERDIT par l'ADR) ###
SONDE rgb=#ff0000 L=0.6280 chroma=0.2577 deltaL=0.0280
```

---

## 4. Findings BLOQUANTS

### 🔴 B-1 — La décision d'ADR-003 §4 est du code neuf sans test effectif, et son assertion est un FAUX VERT

| | |
|---|---|
| **Fichier** | `lib/core/color/oklab.dart` — méthode `Rgb versRgb()`, la boucle `for (var i = 0; i <= 64; i++)` et son repli `Oklab(l, 0, 0)` *(lignes 71-84 au commit `24fe59a`)* |
| **Assertion concernée** | `test/core/color/temporal_gradient_test.dart` — test intitulé **« une couleur volontairement hors gamut voit sa CHROMA réduite, à L quasi constante »** |
| **AC / ADR** | **ADR-003 §4** : « *Hors gamut : réduction de CHROMA, jamais écrêtage par canal. […] Un écrêtage canal par canal déplacerait la luminance et casserait la garantie de contraste du point 5.* » |

**Problème.** La boucle de réduction de chroma peut être **entièrement supprimée** et remplacée par
l'**écrêtage canal par canal que l'ADR interdit nommément** : la suite complète reste
**`00:08 +100: All tests passed!`**. Le test qui porte le nom de la décision **ne la teste pas** :

- `expect(apres.chroma, lessThan(absurde.chroma))` — vrai aussi pour l'écrêtage (**0,2577 < 1,2728**) ;
- `expect(apres.l, closeTo(absurde.l, 0.06))` — la tolérance de **0,06** absorbe le ΔL de l'écrêtage
  (**0,0280**), c'est-à-dire précisément la dérive de luminance que l'ADR §4 dit vouloir empêcher.

⚠️ **Ce n'est pas une subtilité théorique** : sous le mutant, la couleur rendue pour
`Oklab(0.6, 0.9, 0.9)` est **`#ff0000`, du rouge pur** — là où l'implémentation correcte rend `#ca5a1b`.
Le test **passe sur du rouge pur**, dans une US dont AC-5 « Erreur » pose que « *aucune couleur
d'urgence (rouge) n'est utilisée* ».

📌 **Deux confirmations indépendantes** : `coverage/lcov.info` montre que `oklab.dart:83` — le repli
« chroma nulle », dernière branche de la décision — n'est **jamais exécuté par aucun test** (voir N-8).

⛔ **C'est exactement la classe de défaut que le projet paie le plus cher** : un instrument de contrôle
qui **blanchit**. `DESIGN_SYSTEM.md` inscrit d'ailleurs la leçon jumelle — « *une formulation absolue
dans un ADR doit être adossée à une assertion, sinon elle survit à sa propre fausseté* » — mais
l'assertion écrite pour rattraper la **teinte** a laissé le **§4** sans garde.

**Solution.** Rendre l'assertion **discriminante**, c'est-à-dire capable de distinguer les deux
implémentations. Deux voies, cumulables :
1. **Assener la teinte préservée** : sur une couleur hors gamut, l'écrêtage **change la teinte**
   (`#ca5a1b` ≈ 43° contre `#ff0000` ≈ 29°) alors que la réduction de chroma à `L` constante la
   **conserve** ⇒ `expect(apres.teinteDegres, closeTo(absurde.teinteDegres, 2))` tue le mutant.
2. **Resserrer la tolérance de `L`** à la valeur réellement obtenue (`ΔL = 0,0002`) plutôt qu'à `0,06` :
   `closeTo(absurde.l, 0.002)`.
3. **Couvrir le repli** `Oklab(l, 0, 0)` (`oklab.dart:83`) par un cas qui l'atteint.

⚠️ Et, conformément à la doctrine du projet, **faire porter à ce test son propre mutant** : il doit être
démontré qu'il **rougit** quand la réduction de chroma est retirée.

---

### 🔴 B-2 — Les commandes « ajout / réglages » de la barre basse : exigées par quatre documents, absentes du code ET des tests

| | |
|---|---|
| **Fichier** | `lib/features/hub/presentation/hub_page.dart` — widget `_BarreModules` *(lignes 44-73 au commit `24fe59a`)* |
| **AC** | **AC-2 « Limite »** : « *Les autres commandes de la barre de navigation basse (ajout, réglages) sont **rendues non-interactives** dans le périmètre US-01.1 — leur activation relève d'US ultérieures.* » |
| **ADR** | **ADR-004 §5** : « *Les commandes de la barre de navigation basse (ajout, réglages) sont **rendues non-interactives** au périmètre d'US-01.1, **par le même mécanisme** (absence de gestionnaire).* » |
| **Tâche** | **T10** : « *barre de nav basse aux commandes non-interactives. Tests `testWidgets` : tap simple/long sur un module grisé **ou une commande de nav** ne déclenche aucune navigation ni action.* » |
| **Gherkin** | Scénario « Les modules futurs sont visibles, grisés et non-interactifs », étape : « *Et **les autres commandes de la barre de navigation basse** sont non-interactives* » |

**Problème.** `_BarreModules` ne rend **que les trois entrées du registre**. Il n'existe **aucune**
commande d'ajout ni de réglages, et rien n'en tient lieu — vérifié par exécution :

```
$ grep -rni "reglage\|ajout\|settings\|add_" lib/          # 0 occurrence pertinente
$ grep -rn "Icon\|FloatingActionButton\|IconButton\|BottomNavigationBar" lib/
(aucune sortie)
```

Le test de ce scénario (`test/e2e/hub_echeances_test.dart`) n'assène **que** sur `'Respiration'` :
l'étape Gherkin sur « les autres commandes » **n'est portée par aucune assertion**. Le contrôle T12b
**ne peut pas** le voir — il compare des **titres**, il l'annonce honnêtement — donc le scénario 2 est
compté « couvert » alors qu'une de ses trois étapes ne l'est pas.

**Aucune levée documentée n'existe** : recherche exécutée sur `docs/adr/`, `docs/design/DESIGN_SYSTEM.md`,
le Story File, le `.feature` et `reports/` — les **quatre** occurrences trouvées **exigent** la chose,
**aucune** ne la retire. ⚠️ Le wireframe du `DESIGN_SYSTEM.md` les omet **en silence**, ce qui n'est pas
une décision : c'est une omission, et elle contredit un **ADR Accepté**, donc **immuable**.

**Solution.** Trancher explicitement, puis rendre la décision **vérifiable** — l'un des deux :
- **(a)** rendre les commandes (ajout, réglages) dans `_BarreModules`, **sans gestionnaire** et avec
  `Semantics(enabled: false)`, conformément au mécanisme d'ADR-004 §3/§5, et **étendre l'assertion**
  d'AC-2 à ces commandes *(appui simple, répété, prolongé → aucun effet)* ;
- **(b)** si l'intention est de **ne pas les livrer**, cela **amende AC-2 et ADR-004 §5** : un ADR
  Accepté ne se réécrit pas ⇒ il faut un **nouvel ADR** qui remplace le §5, **retirer l'étape** du
  `.feature`, et **corriger AC-2 « Limite »** avec un marqueur daté. ⛔ Ce qu'il ne faut pas, c'est
  l'état actuel : **quatre documents affirment une chose que le produit ne fait pas**.

---

## 5. Findings NON BLOQUANTS

> Aucun de ces points ne motive à lui seul le `FAILED`. Ils sont **nommés** pour être arbitrés
> par @QA_Tester / `/certify`, ou versés à une US de dette.

| # | Fichier / emplacement | Problème | Solution |
|---|---|---|---|
| **N-1** | `lib/features/hub/presentation/hub_page.dart`, `HubPage.build` | **ADR-004 §4 non implémenté** : « *Le hub demande au module actif son contenu […] Un futur module actif s'insère **sans toucher `hub_page.dart`***. » Or `body: EcheancesGrid(...)` est **câblé en dur**, et `HubPage` **importe** `echeances/domain` et `echeances/presentation`. Preuve : `grep -rn "\.actif\b" lib/` → **0 appel à `registre.actif`** *(la seule occurrence est sa définition)*. RF-21 n'est donc tenu que pour les modules **grisés**. | Soit faire fournir le contenu par le module actif *(fonction/`Widget Function()` portée par le descripteur, ou table `id → constructeur` hors de `hub_page.dart`)*, soit **nouvel ADR** remplaçant §4 et assumant le câblage direct tant qu'il n'y a qu'un module actif. |
| **N-2** | `lib/features/hub/domain/practice_module.dart` | **ADR-004 §1** décrit `PracticeModule` comme portant `id, label, **icone**, statut` ; le champ **`icone` n'existe pas** et `grep -rn "Icon" lib/` ne rend **rien** *(la barre basse n'affiche que des libellés)*. | Ajouter le champ, ou consigner le retrait *(il est **défendable** : aucun AC n'exige d'icône, et un champ inutilisé serait de la modélisation spéculative — mais l'écart avec l'ADR doit être **écrit**)*. |
| **N-3** | `lib/features/echeances/presentation/widgets/echeance_tile.dart` | **Le correctif `FittedBox(scaleDown)` n'est pas assertionné** : mutation **M2** (retrait du `FittedBox`, `Expanded` conservé) → **100/100 verts**. Seul le garde-fou **grossier** existe : `M2b` (`Text` nu) est bien tué par `takeException()`. Autrement dit, on teste « *aucun `RenderFlex` ne déborde* », jamais « *le nombre tient dans sa tuile et reste lisible* » — or sous M2 le nombre **déborde silencieusement** sur la description, sans erreur Flutter. | Assener la **contenance réelle** : comparer `tester.getRect(find.text('<n>'))` à `tester.getRect(find.byType(EcheanceTile))` au gabarit 320×568 à 9 tuiles, et exiger l'inclusion. |
| **N-4** | `test/e2e/hub_echeances_test.dart` | **ADR-008 §1** autorise à tenir un test pour un E2E de track FULL **à la condition** qu'il monte l'application entière — « *`pumpWidget` de la **racine**, puis interactions* ». Or **2 tests sur 13** appellent `lancerApp` *(qui monte `ConcentrationApp`)* ; **11 sur 13** appellent `lancerAvec`, qui monte `MaterialApp(home: HubPage(...))` avec des échéances injectées — **ni la racine, ni `main.dart`, ni `SampleEcheances`**. Comptage exécuté : `grep -c "await lancerApp(tester)"` → **2** ; `grep -c "await lancerAvec(tester"` → **11**. ⚠️ La justification qui a permis d'écarter `integration_test/` n'est donc tenue que pour **2 scénarios sur 13**. | Faire monter la racine à tous les scénarios *(paramétrer `ConcentrationApp` par une liste d'échéances injectable, comme il l'est déjà par `clock`)*, ou **amender ADR-008 §1 par un nouvel ADR** pour dire ce qui est réellement fait. |
| **N-5** | `test/e2e/hub_echeances_test.dart` ↔ `tests/features/US-01.1-*.feature` | **La borne annoncée par T12b est atteinte en pratique** : trois scénarios ont un test dont le **titre** correspond mais dont les **données ne sont pas celles du scénario**. ⛔ Le plus net : scénario « *Le nombre affiché est l'arrondi supérieur dans l'unité adaptative* » spécifie « *atteinte dans **8 mois et 12 jours*** » ⇒ « **9** » ; le test correspondant utilise **5 h 10 min ⇒ « 6 »** — autre unité, autre exemple. Également : « *4 échéances… exactement 4 tuiles* » testé avec **3** ; l'étape « *chaque tuile porte la description de son échéance* » n'est pas assertionnée. *(L'exemple « 8 mois 12 jours → 9 » **est** couvert, mais au niveau unitaire, dans `remaining_time_calculator_test.dart`.)* | Aligner les données des tests sur celles des scénarios — c'est **gratuit** ici, le moteur les traite déjà. Un contrôle de correspondance **de titres** ne peut pas garder cette propriété ; seule la discipline le peut. |
| **N-6** | `lib/features/echeances/domain/echeance.dart`, `Echeance.depuisDonnee` | **Jamais appelée en production** : `grep -rn "depuisDonnee" lib/` → **une seule occurrence, sa définition** ; `SampleEcheances` construit les entités **directement**. L'invariant **I-6** *(« une donnée illisible est IGNORÉE, jamais fatale »)* est donc unitairement testé mais **non câblé**, et le **critère de test nº 9** du Story File *(« Donnée d'échéance invalide dans le jeu injecté → écran non planté, hub toujours affiché », priorité **Haute**)* ainsi que le test T9 « *donnée invalide ignorée* » **n'existent pas**. *(Atténuation réelle : `EcheancesGrid` reçoit une `List<Echeance>` typée — au périmètre livré, une donnée invalide **ne peut pas** l'atteindre.)* | Ajouter le `testWidgets` manquant *(jeu injecté mixte, dont une entrée illisible ⇒ grille rendue, hub debout)*, ou consigner que le critère nº 9 est **sans objet** tant que la source est du Dart typé — et le **transférer explicitement à US-01.2**, où il redevient réel. |
| **N-7** | `lib/features/echeances/domain/remaining_time.dart:37-52` | `operator ==` et `hashCode` : **14 lignes neuves, 0 test, 0 appelant** — soit **14 des 23 lignes non couvertes** du livré. Incohérent avec `Echeance` et `PracticeModule`, dont l'égalité **est** testée. | Tester l'égalité par valeur *(cohérent avec le pattern « value object immuable » imposé)*, ou retirer les surcharges. |
| **N-8** | `lib/core/color/oklab.dart:83` et `:115` | Branches jamais exécutées : le **repli « chroma nulle »** *(dernière ligne de la décision ADR-003 §4 — cf. B-1)* et la **racine cubique d'un négatif**. | Deux cas de test ciblés ; celui de la ligne 83 fait partie du correctif de **B-1**. |
| **N-9** | `lib/features/hub/presentation/hub_page.dart:92` · `lib/features/echeances/presentation/widgets/empty_echeances_placeholder.dart:25-28` | **Valeurs de design en dur dans les widgets**, contre le pattern imposé du Story File *(« aucune couleur/valeur en dur dans les widgets ; tout passe par `concentration_tokens.dart` »)* et contre `DESIGN_SYSTEM.md` *(« aucune couleur ni dimension ne s'écrit dans un widget »)* : `TextStyle(fontFamily: 'Inter', fontSize: 13, …)` et `fontFamily: 'Inter', fontSize: 15` — alors que `ConcentrationTheme.policeTexte` et `ConcentrationTheme.styleDescription` **existent** *(duplication du littéral `'Inter'` en 2 endroits)*. Corollaire : `concentration_tokens.dart` **ne porte aucun token de spacing ni de radius**, que le Contexte technique lui demande explicitement, d'où `EdgeInsets.all(12/16/24)` et `BorderRadius.circular(16)` disséminés. | Remplacer les littéraux par `ConcentrationTheme.policeTexte` / `styleDescription` ; ajouter les tokens d'espacement et de rayon à `DESIGN_SYSTEM.md` **puis** à `concentration_tokens.dart` *(l'autorité est le document, pas le Dart)*. |
| **N-10** | `lib/core/theme/concentration_tokens.dart` | **Constantes mortes** : `tuilesMin` et `contrasteMinTexteLarge` ne sont lues **nulle part** *(ni `lib/` ni `test/`)*. ⚠️ Conséquence de fond : **ADR-003 §5 distingue deux seuils** *(≥ 3:1 pour le **nombre**, ≥ 4,5:1 pour la **description**)* ; le code n'en applique **qu'un**, `foregroundFor` étant toujours appelé avec le défaut 4,5. **Sans risque** *(4,5 est plus strict que 3)*, mais la distinction décidée n'est pas implémentée. | Retirer les constantes mortes, **ou** appliquer réellement les deux seuils. Dans les deux cas, le dire. |
| **N-11** | — | **AC-1 « Limite » (RNF-02, < 500 ms « prêt au regard ») n'est ni mesuré ni testé.** Le Story File le signalait *(« à surveiller en E2E »)*. | Soit une mesure *(`tester.binding` / horodatage du premier `pump`)*, soit le déclarer **non vérifié** au rapport QA — ⛔ pas de case cochée sans mesure. |
| **N-12** | `lib/features/echeances/domain/echeance.dart:16` | L'invariant **I-2** (`id` non vide) repose sur un **`assert`**, **retiré en build release** : `flutter test` tourne en debug, donc le test « *un id vide est refusé* » **ne prouve rien du binaire livré**. | Acceptable pour une US d'affichage à données internes ; à **rouvrir en US-01.2**, où les données viendront du disque — y basculer sur une validation active *(ou passer par `depuisDonnee`, cf. N-6)*. |
| **N-13** | `factory.config.json` | Le gate le signale : `[HAUSSE] 94.06% > cliquet 89.4%. Valeur a consigner : 94.0`. Le cliquet **n'est pas encore relevé**. | ⚠️ **Action HUMAINE** — le fichier est protégé, aucun agent ne l'édite. À faire au moment de la fusion, sinon la protection acquise par cette US est perdue au premier commit suivant. |

---

## 6. Ce qui est bon, et qui doit être dit

Un rapport qui ne relève que les manques est trompeur. Sur exécution :

- **ADR-002 est implémenté fidèlement**, y compris ses points délicats : le `p` défini par les **deux
  instants** `t_prev = cible − n unités` / `t_next = cible − (n−1) unités` est **exact** *(vérifié au
  raisonnement **et** par les tests `p = 0` / `p ≈ 1` / `p = 0,5`)*, l'ordre « **seuils puis `ceil`** »
  est respecté, l'arithmétique calendaire **écrête le jour** *(31 janvier + 1 mois → 28/29 février)*, et
  le DST est **documenté par un test** comme l'ADR l'exige, au lieu d'être tu.
- **Le sens du dégradé n'est pas inversé** : `p = 0` rend **exactement** `#FF8C42`, `p = 1`
  exactement `#3D7DD8` — assertionné, et le piège de la maquette est nommé dans trois documents.
- **`foregroundFor` échoue bruyamment** (ADR-003 §5), et **cet échec est testé**
  (`throwsStateError` à seuil 21:1).
- **ADR-004 §3 est tenu et prouvé par l'ABSENCE** : aucun `GestureDetector`/`InkWell` sur une entrée
  grisée, `Semantics(enabled: false)`, appui simple/répété/prolongé sans effet — assertionné.
- **`grille_gabarits_test.dart` est le meilleur test du lot** : il éprouve **5 gabarits**, assène que
  chaque tuile est **entièrement dans l'écran** et **carrée**, et il **tue deux mutants sur deux**. Il
  corrige à lui seul la faiblesse structurelle qu'il nomme *(« un test qui ne s'exécute qu'à une seule
  taille ne dit rien du responsive »)*.
- **Aucune requête N+1** *(aucune persistance à ce périmètre)*, **aucune duplication de logique**,
  **`Timer` correctement annulé** dans `dispose`, moteurs purs sans `BuildContext` ni `DateTime.now()`.
- Les 7 invariants de `MODELE_ECHEANCE.md` sont **tous** portés par le code, et le **comparateur total**
  *(départage par `id`)* est assertionné dans les **deux sens de saisie** — exactement ce que demandait
  le §Ordre.

---

## 7. Ce que cet audit N'ATTESTE PAS

- ⛔ **Aucun rendu visuel n'a été observé.** Tout est mesuré dans l'arbre de widgets ; « la tuile est
  belle », « le mauve du milieu est acceptable » ne relèvent pas de cet audit *(la validation humaine du
  milieu désaturé est consignée au `DESIGN_SYSTEM.md`, elle n'est pas re-vérifiée ici)*.
- ⛔ **Aucune exécution sur appareil réel ni navigateur** : `flutter build web --release` prouve que ça
  **compile**, pas que ça se comporte.
- ⛔ **Aucun scan de sécurité** — le projet n'a **ni SAST ni scanner de CVE** *(dette connue)* ;
  l'audit `🛡️ @CyberSecurity` reste dû.
- ⛔ **Les 13 scénarios Gherkin d'US-01.1 sont exécutés** *(contrairement aux 103 de gouvernance,
  ré-étiquetés par T12d)*, **mais** voir **N-4** et **N-5** sur ce que cette exécution vaut exactement.
- ⛔ **Le verdict porte sur le commit `24fe59a`.** Toute correction ultérieure exige un **nouveau
  passage** : ⛔ ne pas re-cocher ce rapport après modification du code.

---

## 8. Condition de sortie — bornée, falsifiable, rejouable

Conformément à la leçon d'US-00.7 *(« un critère de sortie se publie comme un script exécutable, jamais
recopié à la main »)*, voici ce que je rejouerai au prochain passage. **`PASSED` exige que les trois
sortent comme indiqué.**

```bash
# 1) Gates statiques inchangés
python scripts/run_gates.py --all            # attendu : exit 0

# 2) B-1 — la reduction de chroma doit etre TUEE par mutation.
#    Dans une copie isolee de lib/+test/, remplacer le corps de Oklab.versRgb()
#    par :  return _depuisLineaire(_versLineaireRgb());
#    puis :
flutter test                                  # attendu : ECHEC (>= 1 test rouge)
#    Aujourd'hui : "00:08 +100: All tests passed!"  => faux vert, bloquant.

# 3) B-2 — l'etape Gherkin doit etre portee par une assertion.
grep -n "barre de navigation basse" tests/features/US-01.1-affichage-hub-grille.feature
#    Si l'etape existe encore, alors une assertion doit exister cote test :
grep -rn "reglage\|ajout\|Reglages\|Ajouter" lib/features/hub/ test/e2e/
#    attendu : NON VIDE (code + assertion), ou etape retiree du .feature
#    par un ADR remplacant ADR-004 §5.
```

---

## 9. Traçabilité

| Élément | Valeur |
|---|---|
| **Événement émis** | `EVT_CODE_REVIEW_FAILED` |
| **Commandes exécutées** | `run_gates.py --all` → exit 0 · `check_gherkin_mapping.py` → exit 0 · `--selftest` → exit 0 (6/6) · `check_epic00_docs.py` → exit 0 · `flutter test` → 100/100 · 5 mutations en copie isolée → **2 survivants** |
| **Dépôt modifié ?** | **NON** — aucune écriture hors `reports/US-01.1/` et `docs/trace/US-01.1/` |
| **SCB modifié ?** | **NON** — la mise à jour relève du rituel `/audit-us` |
