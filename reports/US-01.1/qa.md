# Rapport QA — US-01.1 « Affichage Hub & grille d'échéances »

| Champ | Valeur |
|---|---|
| **Agent** | @QA_Tester — contexte frais |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **Commit audité** | **`6fe75df720214a9bac74efd9b6f024f7cd561407`** (`6fe75df`) |
| **Branche** | `feat/US-01.1-dev-presentation` |
| **Story File** | `docs/stories/US-01.1-affichage-hub-grille.md` |
| **Critère de sortie exécutable** | [`reports/US-01.1/qa_exit_criterion.py`](qa_exit_criterion.py) |

---

## ⛔ VERDICT : **FAILED**

**102 passed · 0 skipped · 0 failed · couverture 95,2 % — et pourtant `FAILED`.**

Le produit n'est pas cassé : tout ce que j'ai muté est **correctement implémenté** dans `lib/`.
Ce qui est en défaut, c'est **la capacité de la suite à protéger ces comportements**. Six mutants
qui suppriment un comportement **exigé par un AC ou par une étape Gherkin** laissent la suite à
**102/102 verts**.

⚠️ **Le point qui décide du verdict** : la suite **annonce** une couverture Gherkin de **13 ↔ 13**
(`check_gherkin_mapping.py`, exit 0). C'est **vrai nominalement et faux sémantiquement** pour
**5 étapes**. L'outil l'annonce lui-même dans sa propre sortie :

```
OK : chaque scenario a son test et chaque test son scenario.
Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
```

C'est exactement l'angle mort qui avait laissé passer le bloquant **B-2** du 1ᵉʳ passage de revue.
Je l'ai mesuré au lieu de le supposer.

---

## 1. Pré-conditions — vérifiées, pas admises

```
$ python scripts/validate_trace.py --us US-01.1
Traçabilité conforme.
```

Lecture directe des deux derniers événements de `docs/trace/US-01.1/events.jsonl` :

| Événement | Horodatage | Commit porté dans le champ libre |
|---|---|---|
| `EVT_CODE_REVIEW_PASSED` | `2026-08-02T11:52:29+02:00` | « 2e passage sur **6fe75df** » |
| `EVT_SECURITY_AUDIT_PASSED` | `2026-08-02T12:19:13+02:00` | « RE-AUDIT DE DELTA sur le commit **6fe75df720214…** » |

✅ Les deux visas portent bien sur **`6fe75df`**, qui est **`HEAD`** (`git rev-parse HEAD` →
`6fe75df720214a9bac74efd9b6f024f7cd561407`). Le premier visa sécurité portait sur `24fe59a` et a
été **refait** pour cette raison — le décalage a été rattrapé par un humain, pas par une machine
(finding **NB-6**).

**Dépôt non modifié par cette QA** — `git status --porcelain` rend exactement les 6 entrées
annoncées (`CLAUDE.md`, `PROJECT_LOG.md`, `STORY_CERTIFICATION_BOARD.md`,
`docs/trace/US-01.1/events.jsonl`, + les 2 rapports non suivis). **Aucune ligne de `lib/` ni de
`test/` n'a été touchée** : toutes les mutations ont eu lieu dans une copie temporaire.

---

## 2. Décomptes exacts — lus dans une sortie, jamais écrits à la main

### 2.1 Gate `test`

```
$ python scripts/run_gates.py --gate test
00:11 +102: All tests passed!
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigné le 2026-07-31
  [HAUSSE] 95.24% (380/399) > cliquet 89.4%. Valeur a consigner : 95.2
✅ app.test
Tous les gates bloquants passent (1 exécutés).
```

### 2.2 Décompte `passed / skipped / failed` (Art. 3)

Le rapporteur `expanded` n'affiche qu'un compteur cumulé. J'ai donc relu le **flux JSON**, seul
format qui porte le drapeau `skipped` :

```
$ flutter test --reporter json > test_json.txt
$ python <analyse du flux : events testDone, hors suites 'loading '>
TOTAL testDone (hors 'loading ') : 102
resultats : {'success': 102}
skipped=true : 0
hidden(loading) : 8
done.success : True
nb fichiers de test : 8
```

| Décompte | Valeur |
|---|---|
| **passed** | **102** |
| **skipped** | **0** |
| **failed** | **0** |
| **errors** | **0** |
| Fichiers de test | 8 |

⚠️ **`0 skipped` est un résultat mesuré, pas une absence d'observation** : le drapeau a été lu
dans le flux JSON pour chacun des 102 tests. Aucun scénario n'est vert par défaut.

Répartition par fichier (lue dans le flux, pas recopiée) :

| Tests | Fichier |
|---:|---|
| 27 | `test/features/echeances/domain/remaining_time_calculator_test.dart` |
| 18 | `test/core/color/temporal_gradient_test.dart` |
| **13** | `test/e2e/hub_echeances_test.dart` |
| 12 | `test/features/echeances/presentation/echeances_grid_test.dart` |
| 11 | `test/features/echeances/domain/echeance_test.dart` |
| 10 | `test/features/echeances/presentation/grille_gabarits_test.dart` |
| 7 | `test/features/hub/domain/practice_module_registry_test.dart` |
| 4 | `test/core/time/clock_test.dart` |

### 2.3 E2E — 13/13 montent bien la racine

Vérifié par comptage, pas à l'œil :

```
$ grep -c "testWidgets(" test/e2e/hub_echeances_test.dart            -> 13
$ grep -c "await lancerApp(tester)\|await lancerAvec(tester" ...      -> 13
$ grep -n "pumpWidget(" test/e2e/hub_echeances_test.dart
29:    await tester.pumpWidget(ConcentrationApp(clock: FakeClock(maintenant)));
40:    await tester.pumpWidget(
$ grep -n "MaterialApp" test/e2e/hub_echeances_test.dart
36:  /// `MaterialApp(home: HubPage)` — or c'est le fait de monter **l'application
```

✅ **13/13.** Il n'existe que **2 sites `pumpWidget`**, tous deux montant `ConcentrationApp`
(la racine), et la seule occurrence résiduelle de `MaterialApp` est **dans un commentaire**.
La contrepartie d'**ADR-008 §1** — la seule chose ayant autorisé à écarter `integration_test/` —
est **tenue**.

---

## 3. Couverture — **recomptée** depuis `lcov.info`, pas reprise

Je n'ai pas repris le « 95,2 % » du gate : j'ai réagrégé les enregistrements `DA:` avec mon propre
compteur.

```
TOTAL DA lignes instrumentees : 399
TOTAL couvertes : 380   NON couvertes : 19
POURCENTAGE RECOMPTE : 95.2381%  -> arrondi VERS LE BAS 1 dec : 95.2
nb fichiers dans lcov : 19
```

✅ **Mon recompte tombe sur la même valeur que le gate : 380/399 = 95,2381 %**, soit **95,2**
arrondi vers le bas. **> cliquet 89,4 %** et **> plancher 80,0 %**. Aucune régression.

**Les 19 lignes non couvertes, par fichier** :

| Non couvertes | Fichier | Lignes |
|---:|---|---|
| 14 | `features/echeances/domain/remaining_time.dart` | 37, 39-44, 46-52 |
| 2 | `core/color/rgb.dart` | 59, 60 |
| 1 | `core/theme/concentration_theme.dart` | 23 |
| 1 | `core/theme/concentration_tokens.dart` | 14 |
| 1 | `features/echeances/data/sample_echeances.dart` | 15 |

✅ `core/color/oklab.dart` est **intégralement couvert** (58/58) — **N-8 confirmé résolu** par ma
propre mesure.
⏳ **N-7 confirmé** : `remaining_time.dart` concentre **14 des 19** lignes non couvertes (74 %), à
**1/15 couvert**.

### ⚠️ Angle mort du dénominateur — confirmé sur du code réel

`lib/` contient **20** fichiers `.dart` ; `lcov.info` n'en liste que **19**. **`lib/main.dart` est
absent du dénominateur** : aucun test ne l'importe, donc il n'entre pas au calcul.

C'est **exactement** l'angle mort structurel tranché par expérience en US-00.6 et consigné dans
`CLAUDE.md` : *« un fichier Dart non importé par un test n'entre PAS au dénominateur ⇒ déplacer du
code non couvert FAIT MONTER la couverture »*. **US-01.1 en porte la conséquence annoncée, et c'est
ici sa première observation sur du code produit.** L'enjeu est modeste (`main.dart` = un `runApp`),
mais **le mécanisme est vérifié** : le point d'entrée réel de l'application n'est ni couvert ni
compté.

---

## 4. Correspondance Gherkin — **nominale : oui · sémantique : NON**

```
$ python scripts/check_gherkin_mapping.py                 -> exit 0  (13 <-> 13)
$ python scripts/check_gherkin_mapping.py --selftest      -> exit 0  (6 assertions)
```

L'outil est **honnête sur sa borne** — il imprime lui-même *« pas de semantique »*. J'ai donc
mesuré la sémantique par **mutation**, méthode établie par le corpus du projet (*« un contrôle
portant son mutant a été juste 7 fois sur 7 ; un contrôle purement lexical, faux 7 fois sur 7 »*).

**Protocole** : copie isolée du projet (`lib/`, `test/`, `pubspec.*`), baseline vérifiée à
**102 verts**, un mutant à la fois, restauration immédiate. **Le dépôt n'est jamais modifié.**

### 4.1 Résultats

| # | Mutation appliquée | Clause visée | Attendu | **Obtenu** |
|---|---|---|---|---|
| **QA-M1** | la tuile rend `backgroundFor(0)` — **toujours orange**, la progression est ignorée | AC-5 Nominal · Sc.7 *« la couleur de fond de la tuile est bleue »* | ≥ 1 rouge | 🔴 **SURVIT** — `+102 All tests passed!` |
| **QA-M2b** | `scaffoldBackgroundColor` passe au **blanc** | AC-8 Nominal · Sc.1 *« affiché en mode sombre de référence »* | ≥ 1 rouge | 🔴 **SURVIT** |
| **QA-M3** | **`FittedBox` retiré** de la tuile | AC-3 Limite · N-3 / mutant M2 de la revue | ≥ 1 rouge | 🔴 **SURVIT** |
| **QA-M4** | la **description n'est jamais rendue** (`if (false)`) | AC-3 Nominal · Sc.3 *« chaque tuile porte la description de son échéance »* | ≥ 1 rouge | 🔴 **SURVIT** |
| **QA-M5** | **plus rien n'est grisé** : toutes les entrées prennent la couleur du module actif | AC-2 Nominal · Sc.2 *« visibles mais grisés »* | ≥ 1 rouge | 🔴 **SURVIT** |
| **QA-M7** | période de rafraîchissement portée à **1 heure** | AC-4 Limite · RF-05 *« au minimum une fois par minute »* | ≥ 1 rouge | 🔴 **SURVIT** |
| **QA-M6** | la tuile rend `backgroundFor(1)` — **toujours bleu** | **CONTRÔLE POSITIF** | ≥ 1 rouge | ✅ **TUÉ** — 1 rouge : *« Couleur orange quand le nombre vient de changer »* |

### 4.2 Pourquoi **QA-M6** est indispensable

⛔ **Une campagne où tout survit ne prouve rien** — elle peut simplement signifier que le harnais
est cassé. C'est la leçon des **six instruments faux d'US-00.5**. **QA-M6 est mon contrôle
positif** : il meurt, donc mon harnais **détecte réellement** une régression de couleur de tuile.
Les six survivants sont donc des **survivants réels**, pas un artefact de mesure.

📌 **QA-M1 et QA-M6 forment une paire, et leur asymétrie est le résultat le plus net du rapport** :
mutée **toujours en bleu**, la tuile fait rougir 1 test ; mutée **toujours en orange**, elle n'en
fait rougir **aucun**. Autrement dit **seul `p = 0` est vérifié sur le rendu**. La tuile pourrait
**ignorer entièrement `temps.progression`** sans qu'aucun test ne le voie — or *« la couleur reflète
la proximité du prochain changement »* **est** AC-5.

### 4.3 Pourquoi le test de rafraîchissement ne mesure pas ce qu'il annonce (QA-M7)

Le test s'intitule `recalcule après avancée de l'horloge (RF-05)` et fait :

```dart
horloge.avancerDe(const Duration(hours: 2));
await tester.pump(ConcentrationTokens.periodeRafraichissement);
```

⛔ Il `pump`e **de la valeur du token lui-même**. L'assertion est donc **auto-référentielle** :
quelle que soit la période — 30 s ou 1 h — le test reste vert. Il prouve que **le recalcul a lieu**
(le nombre passe bien de 6 à 4, c'est réel et c'est bien), **jamais qu'il a lieu au moins une fois
par minute**. Aucune assertion du corpus ne borne cette durée :

```
$ grep -rn "periodeRafraichissement" lib/ test/
lib/core/theme/concentration_tokens.dart:53:  static const Duration periodeRafraichissement = Duration(seconds: 30);
lib/features/echeances/presentation/echeances_grid.dart:42:      ConcentrationTokens.periodeRafraichissement,
test/features/echeances/presentation/echeances_grid_test.dart:200:      await tester.pump(ConcentrationTokens.periodeRafraichissement);
```

C'est **la classe de défaut exacte de B-1** — *« la décision était supprimable sans qu'aucun test ne
rougisse »* — que la revue a tenue pour **bloquante** la veille. Et c'est aussi la leçon versée au
corpus par le développeur lui-même : *« une formulation absolue doit être adossée à une assertion,
sinon elle survit à sa propre fausseté. »*

---

## 5. Échecs au format « Action → Attendu → Obtenu »

**F-1 · AC-4 « Limite » (RF-05) — la périodicité de rafraîchissement est régressible en silence**
- **Action effectuée** : dans une copie isolée, `periodeRafraichissement` portée de `Duration(seconds: 30)` à `Duration(hours: 1)`, puis `flutter test`.
- **Résultat attendu** : au moins un test rouge — l'AC exige *« au minimum une fois par minute, indispensable pour l'unité heures »*.
- **Résultat obtenu** : `00:06 +102: All tests passed!` — **0 rouge**. Une échéance en unité « heures » pourrait n'être rafraîchie qu'une fois par heure, gate vert.

**F-2 · AC-5 « Nominal » — le rendu de la tuile n'est vérifié qu'en `p = 0`**
- **Action effectuée** : `gradient.backgroundFor(temps.progression)` → `gradient.backgroundFor(0)` (la tuile ignore la progression), puis `flutter test`.
- **Résultat attendu** : rouge sur le scénario 7 *« Couleur bleue quand le prochain changement est imminent »*.
- **Résultat obtenu** : `+102 All tests passed!` — **0 rouge**. Contrôle positif inverse (`backgroundFor(1)`) : **1 rouge**. Le scénario 7 n'assertionne rien sur la couleur rendue : il vérifie `alpha == 255` puis compare une valeur **recalculée à part** par `backgroundFor(0.98)`, jamais la couleur de la tuile.

**F-3 · AC-8 « Nominal » — le mode sombre de référence n'est adossé à aucune assertion**
- **Action effectuée** : `scaffoldBackgroundColor: fond` → `const Color(0xFFFFFFFF)` (fond blanc), puis `flutter test`.
- **Résultat attendu** : rouge sur le scénario 1, dont l'étape est *« le hub de pratiques est affiché en mode sombre de référence »*.
- **Résultat obtenu** : `+102 All tests passed!` — **0 rouge**. L'unique assertion visant le fond est `expect(scaffold.backgroundColor ?? ConcentrationTokens.fondApp.couleur, isNotNull)` : l'opérateur `??` retombe sur une constante **jamais nulle**, donc **cette assertion est vraie quoi qu'il arrive**.

**F-4 · AC-3 « Nominal » — l'affichage de la description n'est pas assertionné**
- **Action effectuée** : `if (description.isNotEmpty)` → `if (false)` (description jamais rendue), puis `flutter test`.
- **Résultat attendu** : rouge — l'étape du scénario 3 est *« chaque tuile porte la description de son échéance »*.
- **Résultat obtenu** : `+102 All tests passed!` — **0 rouge**. Le corpus vérifie le **cas vide** (`description VIDE : la tuile reste rendue`) mais **jamais le cas peuplé**.

**F-5 · AC-2 « Nominal » — l'état « grisé » n'est vérifié qu'au niveau du domaine**
- **Action effectuée** : la couleur des entrées de la barre forcée à `moduleActif` pour tous les modules (plus rien n'est estompé), puis `flutter test`.
- **Résultat attendu** : rouge — l'étape est *« les modules Respiration et Concentration sont visibles mais grisés »*.
- **Résultat obtenu** : `+102 All tests passed!` — **0 rouge**. `practice_module_registry_test` assertionne bien le **statut** `grise` **du descripteur**, et la **non-interactivité** est solidement tenue (absence de `GestureDetector`/`InkWell`) ; mais **le rendu estompé lui-même** n'est vérifié nulle part.

**F-6 · AC-3 « Limite » / N-3 — le correctif anti-débordement n'est pas assertionné**
- **Action effectuée** : `FittedBox(fit: scaleDown)` remplacé par `Align`, puis `flutter test`.
- **Résultat attendu** : rouge — ce `FittedBox` est le correctif d'un **défaut réel trouvé par T12a** (le nombre débordait à 9 tuiles).
- **Résultat obtenu** : `+102 All tests passed!` — **0 rouge**. ✅ **Je confirme par ma propre exécution le finding N-3 de la revue** (son mutant M2 survit toujours sur `6fe75df`).

**F-7 · AC-1 « Limite » (RNF-02) — ni mesuré ni testé** → voir §7.

**F-8 · AC-1 / AC-3 « Erreur » — la donnée illisible n'est jamais éprouvée au niveau de l'écran**
- **Action effectuée** : `grep -rn "depuisDonnee" lib/`.
- **Résultat attendu** : au moins un appelant dans la chaîne d'affichage, le critère de test nº 9 du Story File exigeant *« Donnée d'échéance invalide dans le jeu injecté → échéance ignorée, écran non planté »*.
- **Résultat obtenu** : `lib/features/echeances/domain/echeance.dart:27` — **la définition seule, aucun appelant**. La fonction est bien testée en unitaire (6 assertions, `echeance_test.dart`), mais **aucune donnée invalide ne peut atteindre la grille**, donc le comportement d'écran décrit par l'AC **n'est pas exerçable**. *(= N-6 de la revue, confirmé.)*

---

## 6. Couverture des AC — 9 AC × 3 clauses = **27 clauses**

Légende : ✅ couvert · 🟠 partiel · ⛔ **orphelin** (aucune assertion effective) · ➖ sans objet

| AC | Clause | État | Preuve / manque |
|---|---|---|---|
| **AC-1** | Nominal | 🟠 | Structure ✅ (`AppBar` « Concentration », « Échéances », `EcheancesGrid`, tuiles). **Dark mode ⛔ (F-3)**. Conformité à la maquette : **jamais observée** (aucun appareil). |
| | Erreur | 🟠 | Données **absentes** ✅ (placeholder). Données **illisibles** ⛔ (F-8). |
| | **Limite** | ⛔ | **RNF-02 < 500 ms : ni mesuré ni testé** (F-7, §7). |
| **AC-2** | Nominal | 🟠 | Visibles ✅ · non-interactifs ✅ (absence de gestionnaire, mutants M6/M7 de la revue tués). **« Grisés » ⛔ (F-5)**. ⚠️ La boucle de non-interactivité ne porte que sur `Respiration` ; `Concentration` n'est pas vérifié (collision avec le titre de l'app). |
| | Erreur | ✅ | Appui simple, répété, prolongé → `takeException() isNull`, `HubPage` toujours monté. |
| | Limite | ✅ | Les 2 modules restent affichés ; commandes ajout/réglages non-interactives (**B-2 résolu**, `Semantics(enabled: false)`). |
| **AC-3** | Nominal | 🟠 | 1 tuile / échéance ✅ · tuiles **carrées** ✅ (5 gabarits). **Description ⛔ (F-4)**. |
| | Erreur | 🟠 | Description vide ✅. **Donnée invalide ⛔ (F-8)**. |
| | Limite | ✅⚠️ | 9 tuiles ✅, 10ᵉ bornée ✅, non-débordement sur **5 gabarits** (320×568 → 1920×1080) ✅. ⚠️ Réserve : le `FittedBox` n'est pas assertionné (F-6). |
| **AC-4** | Nominal | ✅ | 27 tests unitaires, dont les **4 exemples du PRD** — `8 mois 12 jours -> 9 mois` **présent**. ⚠️ N-5 : le scénario 5 E2E teste `5 h 10 → 6` au lieu de ses propres données. |
| | Erreur | ✅ | Aucune unité / fraction / signe — assertions **bornées à la tuile**. |
| | **Limite** | ⛔ | Recalcul prouvé (6 → 4) mais **périodicité ≥ 1×/min ⛔ (F-1)**. |
| **AC-5** | Nominal | 🟠 | Orange à `p=0` ✅ (tué par QA-M6) · bleu à `p=1` ✅ **au niveau moteur**. **Câblage tuile ↔ progression ⛔ (F-2)**. |
| | Erreur | ✅ | Aucun rouge perceptible — group dédié + « un hors-gamut CHAUD ne revient JAMAIS en rouge saturé ». |
| | Limite | ✅ | Contraste sur **101 points** de `p` ; extrémités exactes assertionnées. |
| **AC-6** | Nominal | ✅ | E2E + grille : ordre par date croissante. |
| | Erreur | ✅ | **Ex æquo départagés par `id`** — comparateur **total**, *« ne doivent JAMAIS échanger leur place »*. |
| | Limite | ✅ | Échue **en tête** (E2E + grille). |
| **AC-7** | Nominal | ✅ | État « à zéro » : affiche `0`, ne disparaît pas. |
| | Erreur | ✅ | Jamais de nombre négatif (`find.textContaining('-')` → `findsNothing`). |
| | Limite | ➖ | Geste de disparition **explicitement hors périmètre** (→ US-01.2). |
| **AC-8** | **Nominal** | ⛔ | **Mode sombre de référence ⛔ (F-3)** — clause centrale de l'AC. Lisibilité du nombre ✅. |
| | Erreur | 🟠 | « Aucun élément anxiogène » ✅ mais **borné au placeholder**, jamais à l'écran complet. |
| | Limite | 🟠 | Contraste WCAG AA ✅ (101 points) · lecteur d'écran ✅ (`3 jours, Visite médicale`). **« Les tailles de police système sont respectées » ⛔** : `grep -rn "textScaler\|textScaleFactor\|MediaQuery" lib/ test/` → **aucune occurrence**. |
| **AC-9** | Nominal | ✅ | Placeholder sobre rendu à 0 échéance. |
| | Erreur | ✅ | Ni erreur technique, ni « ! », ni rouge, ni gamification. |
| | Limite | ✅ | Spécifié et **rendu** dès US-01.1. |

### Bilan

| État | Nombre |
|---|---|
| ✅ Couvert | **15** |
| 🟠 Partiel | **8** |
| ⛔ **Orphelin** | **3** |
| ➖ Sans objet | **1** |
| **Total** | **27** |

### ⛔ AC ORPHELINS (aucune assertion effective)

1. **AC-1 « Limite »** — RNF-02, « prêt au regard » **< 500 ms** : ni mesuré ni testé.
2. **AC-4 « Limite »** — RF-05, recalcul **au minimum une fois par minute** : assertion
   auto-référentielle, mutant survivant (F-1).
3. **AC-8 « Nominal »** — **mode sombre de référence** : mutant survivant (F-3).

*Clauses partielles dont la moitié manquante est prouvée par mutation* : AC-2 Nominal (grisé),
AC-3 Nominal (description), AC-5 Nominal (câblage progression), AC-1 Erreur / AC-3 Erreur (donnée
illisible), AC-8 Limite (tailles de police système).

---

## 7. **RNF-02 (< 500 ms) — réponse explicite au point N-11 que la revue m'adresse**

### ⛔ **Je déclare AC-1 « Limite » NON VÉRIFIÉ.** La case ne doit **pas** être cochée.

J'ai néanmoins **mesuré ce qui est mesurable**, plutôt que de conclure sur une impression. Sonde
écrite **dans la copie isolée uniquement** (jamais dans le dépôt) :

```
$ flutter test test/zz_qa_perf_probe_test.dart      # 10 itérations par cas
RNF02_EXEMPLE_us_min=72629  median=85208  max=952512
RNF02_9TUILES_us_min=43803  median=49527  max=74359
```

| Cas | min | médiane | max |
|---|---:|---:|---:|
| Données d'exemple | **72,6 ms** | **85,2 ms** | **952,5 ms** |
| 9 tuiles (cas limite AC-3) | **43,8 ms** | **49,5 ms** | **74,4 ms** |

**Pourquoi cette mesure ne vaut PAS vérification de RNF-02, et pourquoi je refuse de cocher :**

1. **Elle ne mesure pas la bonne grandeur.** Le harnais `flutter_test` est **headless** : il mesure
   `build + layout` du premier frame. Il **exclut** le démarrage du moteur Flutter, l'init de la VM,
   le chargement des polices, la compilation des shaders et la **rasterisation** — or RNF-02 parle
   de *« l'ouverture »* de l'application. C'est une **borne inférieure**, pas la valeur de l'AC.
2. **Elle n'est pas mesurée sur la cible.** *« L'application n'a JAMAIS été lancée sur un
   appareil »* — aucun émulateur, aucun JDK. La mesure vient d'une machine de développement Windows.
3. ⚠️ **La borne inférieure elle-même dépasse déjà le seuil** dans un cas : **952 ms** au premier
   passage (échauffement JIT). Même en tenant l'échauffement pour un artefact du harnais, je ne peux
   pas écrire que la borne inférieure est confortablement sous 500 ms — **elle ne l'est pas
   systématiquement**.
4. **Aucun gate ne surveille cette grandeur.** Rien dans `factory.config.json` ni dans la CI ne
   mesure un temps de rendu : la valeur ne serait donc **pas protégée** contre une régression, même
   si je la constatais bonne aujourd'hui.

📌 **Ce que je recommande** (à @Architect / @PO, ce n'est pas mon arbitrage) : soit RNF-02 devient
**mesurable dans le harnais** — reformulé en budget de `build + layout` du premier frame, avec un
seuil assertionné, ce qui le rend **protégé par le gate `test`** — soit il est **explicitement
reporté** à une US disposant d'un appareil. ⛔ **En l'état, il ressemble à un critère vérifié et
ne l'est pas.**

---

## 8. Findings ouverts de la revue — ce que ma propre exécution en dit

La revue m'a demandé de dire si **N-3** affecte mon verdict, et laisse **10 findings** ouverts.

- **N-3** — ✅ **confirmé par ma propre exécution** (F-6, `QA-M3` survit). **Il n'est pas à lui seul
  la cause de mon `FAILED`** : pris isolément, c'est un correctif cosmétique non protégé. Mais il
  **cesse d'être isolé** — il est le **sixième** membre d'une même famille que j'ai mesurée. ⛔ **Ce
  n'est plus un finding ponctuel, c'est un motif** : la suite valide **ce qu'elle construit**, pas
  **ce que les AC exigent**. C'est cette généralité qui pèse, pas le `FittedBox`.
- **N-5** — ✅ confirmé. Le scénario 5 (*« 8 mois et 12 jours → 9 »*) est testé en E2E avec
  `5 h 10 → 6`. **Non bloquant en soi** : la règle du PRD **est** couverte en unitaire
  (`8 mois 12 jours -> 9 mois`). Mais c'est le **même mécanisme** que les six mutants — un titre qui
  promet plus que son assertion.
- **N-6** — ✅ confirmé (F-8). `depuisDonnee` : 0 appelant dans `lib/`.
- **N-7** — ✅ confirmé par recompte : 14 des 19 lignes non couvertes.
- **N-8** — ✅ confirmé **résolu** : `oklab.dart` 58/58.
- **N-13** — ⚠️ **action humaine** : le cliquet à consigner passe à **95,2**
  (`factory.config.json` est protégé, **aucun agent ne l'édite**).

⛔ **Je ne requalifie aucun finding de la revue en bloquant** — ce serait déplacer les critères d'un
autre. **Mes six mutants sont des findings QA nouveaux**, issus de ma propre exécution, et ils
relèvent de **mon** critère de rôle : *« chaque AC du Story File a-t-il un test qui le couvre ? »*
Un AC dont le comportement peut être supprimé sans faire rougir la suite **n'est pas couvert par un
test** — il est **accompagné** d'un test.

---

## 9. Edge cases testés — au-delà des cas passants

Éprouvés **et verts** (relevés dans les sorties, pas listés de mémoire) :

- **Temps** : `T ≤ 0` (échue) · `p` aux deux bornes `0` et `1` · balayage de **400 instants**
  (`p ∈ [0;1]` jamais franchi) · frontières exactes de seuil d'unité · bascule jours → heures à
  exactement 24 h · **29 février** · mois de longueurs différentes · écrêtage du jour.
- **Couleur** : **101 points** de contraste · monotonie perceptuelle **à la quantification 8 bits
  près** · hors gamut (**seule la chroma bouge**, `L` et teinte préservées) · **échec bruyant** si
  le seuil est inatteignable · `p` hors bornes **borné, jamais rejeté** · contraste noir/blanc
  = 21:1 · contraste d'une couleur avec elle-même = 1:1.
- **Données** : `id` vide **refusé** · date **passée acceptée** (état normal, AC-7) · description
  absente → chaîne vide et non rejet · `null`, `'pas une map'`, `id` numérique, date `'demain'` →
  `null` **sans lever** · **ex æquo** départagés par `id`.
- **Mise en page** : **5 gabarits** de **320×568** à **1920×1080** · 9 tuiles sans débordement ·
  tuiles **carrées** à chaque gabarit · **10ᵉ tuile bornée** · grille vide → placeholder.
- **Interaction** : appui **simple, répété et prolongé** sur module grisé et sur chaque commande de
  barre · absence de `GestureDetector` / `InkWell` / `IconButton`.
- **Accessibilité** : libellé sémantique portant le temps **complet avec unité** alors que l'écran
  n'affiche que le nombre.

**Edge cases que j'ai cherchés et qui n'existent pas** : mise à l'échelle des polices système
(`textScaler`) · densité de pixels · orientation paysage · locale autre que `fr` · liste de **plus
de 10** échéances au niveau de l'écran · donnée invalide **atteignant la grille**.

---

## 10. Condition de sortie — **publiée comme un script, pas comme de la prose**

Leçon d'US-00.7 : *« un critère de sortie se publie comme un script exécutable, jamais recopié à la
main. »* Je ne décris donc pas la condition, **je la livre** :

```bash
python reports/US-01.1/qa_exit_criterion.py --selftest   # attendu : exit 0
python reports/US-01.1/qa_exit_criterion.py              # attendu : exit 0 pour repasser en QA
```

**État constaté aujourd'hui sur `6fe75df`, lu dans sa sortie** :

```
Baseline : 102 test(s) verts.
QA-M1   SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M2b  SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M3   SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M4   SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M5   SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M7   SURVIT  (attendu TUE) [ECHEC] | 0 rouge(s)
QA-M6   TUE     (attendu TUE) [OK]    | 1 rouge(s)
CRITERE DE SORTIE NON ATTEINT -- 6 mutant(s) au mauvais verdict
```
`exit 1`. **Le script rendra `exit 0` quand les 6 mutants seront tués** — c'est la condition de
reprise, elle est **bornée, falsifiable et rejouable**, et **je l'ai exécutée moi-même** plutôt que
de juger sur relecture.

**Propriétés du script, conformes aux règles du corpus** : le dépôt n'est jamais modifié (copie
temporaire) · aucun mutant n'est désigné par un **numéro de ligne**, chacun l'est par son **texte**,
et un **motif introuvable est un ÉCHEC** et non un silence · il porte son **autotest** (`--selftest`,
6 contrôles, comparaison en **ensembles**) · il embarque un **contrôle positif**.

⚠️ **Deux défauts de mes propres instruments, que je signale plutôt que de les taire** : mon premier
pilote de mutation a **planté en `cp1252`** à l'impression (la classe de bug exacte que ce projet
traque, cette fois dans l'outil de mesure) ; et mon premier mutant « mode sombre »
(`Brightness.light`) tuait **30+ tests** — il était **non discriminant**, car il déclenche une
assertion Flutter d'incohérence `ColorScheme`, sans rien prouver sur l'étape Gherkin. **Il a été
retiré et remplacé** par `QA-M2b`, chirurgical. Un troisième défaut (`for … else` imprimant `[OK]`
inconditionnellement) a été trouvé et corrigé dans l'autotest du script livré.

---

## 11. Ce que ce rapport **n'atteste pas**

- ⛔ **Aucun rendu visuel n'a été observé.** L'application n'a **jamais** été lancée sur un appareil
  ni dans un navigateur. **Tous les contrastes sont calculés, aucun n'a été vu par un œil.** La
  conformité à la maquette `hub_de_pratiques.png` (AC-1 Nominal) est **non vérifiée**.
- ⛔ **Aucun runner BDD n'existe.** Les 13 scénarios d'US-01.1 sont exécutés **par des tests Dart qui
  reproduisent leurs titres**, pas par un moteur Gherkin. Les **103 scénarios de gouvernance**
  restent **« SPÉCIFICATION — NON EXÉCUTÉE »**.
- ⛔ **Aucun SAST, aucun scan de CVE** dans la factory — hors de mon périmètre, rappelé pour que le
  `FAILED` ne soit pas lu comme portant sur la sécurité (visa 🛡️ **PASSED** sur le même commit).
- ⛔ **Aucune couverture de branches** — 95,2 % est une couverture de **lignes**.
- ⛔ **`lib/main.dart` n'est ni couvert ni compté** (§3).
- ⛔ **Ce verdict porte sur `6fe75df` et sur lui seul.** La trace n'ayant **aucun champ `commit`**
  (**NB-6**), le SHA est inscrit dans le champ libre de l'événement : **convention non enforcée**.
  Tout commit ultérieur touchant `lib/` ou `test/` **périme ce verdict en silence**.
- ⛔ **Je ne délivre pas `🚀 OUI`** : la certification appartient au rituel `/certify` (@Architect),
  Constitution Art. 5. Je ne délivre pas non plus `🧪 PASS` ici — je délivre **`FAILED`**.

---

## 12. Traçabilité

| Élément | Valeur |
|---|---|
| **Événement émis** | `EVT_QA_FAILED` |
| **Commit couvert** | `6fe75df720214a9bac74efd9b6f024f7cd561407` |
| **Exécutions** | `validate_trace.py --us US-01.1` → exit 0 · `run_gates.py --gate test` → exit 0 (102 tests, 95,2 %) · `flutter test --reporter json` → 102 passed / **0 skipped** / 0 failed · recompte indépendant de `lcov.info` → 380/399 = 95,2381 % · `check_gherkin_mapping.py` (+ `--selftest`) → exit 0 · **8 mutations** en copie isolée → **1 tuée (contrôle positif), 6 survivantes, 1 retirée pour non-discrimination** · sonde RNF-02 (10 × 2 itérations) · greps de couverture d'AC |
| **Dépôt modifié ?** | **NON** — écritures confinées à `reports/US-01.1/` |
| **SCB modifié ?** | **NON** |
| **Verdict** | ⛔ **FAILED** — 3 AC orphelins, 8 clauses partielles, 6 mutants survivants |
