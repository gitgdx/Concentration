# Audit de revue de code — US-01.2 « Gestion des échéances (CRUD) »

| Champ | Valeur |
|---|---|
| **Verdict** | ✅ **PASSED** |
| **Commit audité** | **`5272ed1`** *(branche `feat/US-01.2-design`)* |
| **Périmètre du verdict** | `git diff main...HEAD` — **57 fichiers, +12257/−107**. Vérifié : `git log --name-only 828aade..HEAD -- lib/ test/ scripts/ pubspec.yaml pubspec.lock tests/` → **sortie VIDE** ⇒ le code déclaré prêt sur `828aade` est **identique** sur `5272ed1` |
| **Auditeur** | @CodeReviewer — contexte **frais**, n'a pas produit ce code |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-08-07 |
| **Findings BLOQUANTS** | **0** |
| **Findings NON BLOQUANTS** | **8** *(NB-A → NB-H)* |
| **Mutants joués par l'auditeur** | **5** — **5 tués**, **0 survivant** ; arbre restauré *(`git status --porcelain` → vide, annexe G)* |

> ⛔ **Ce rapport ne recopie aucun nombre.** Chaque chiffre cité est **lu dans une sortie collée en
> annexe**. Chaque emplacement est désigné **par son texte**, ⛔ jamais par un numéro de ligne
> *(leçon US-00.7)*.

---

## 1. Verdict et son motif

**PASSED.** Aucun critère bloquant n'est atteint :

| Critère bloquant | Constat | Preuve |
|---|---|---|
| Erreur lint / typecheck sur le code de l'US | `dart format` : **0 changed** sur 59 fichiers · `flutter analyze` : **No issues found!** | annexe A |
| Duplication manifeste | **Aucune.** Les deux candidats sérieux ont été **mesurés et réfutés** : le prédicat de canonicité vit en **un exemplaire** *(`date_civile.dart`, consommé par la saisie, le codec et les migrations)* et le test dédié *« elle n'est PAS un second exemplaire de V-1 »* le prouve ; le fichier e2e est **reproduit octet pour octet** par son générateur suivi de `dart format` | §4, annexe E |
| Requête N+1 | **Sans objet mesuré** : aucune base relationnelle, aucune boucle d'accès. Le magasin lit et écrit **le document entier**, une fois — conforme à AC-10 « Limite » *(≤ 9 présentes ⇒ ni pagination, ni index, ni chargement différé)*. Le compteur d'appels de T7 démontre **1 écriture** pour une montée de schéma | annexe D |
| Code nouveau sans test | **Aucun.** **15 fichiers de `lib/` ajoutés**, **13 fichiers de `test/` ajoutés** ; les 2 seules lignes nouvellement non couvertes sont **nommées et motivées** *(les deux fabriques `creerMagasin`, borne NM-8)* | §5 |
| AC non couvert par le code | **Aucun des 16 AC actifs.** 48 clauses : **44 scénarisées et exécutées**, **4 déclarées non scénarisées** *(AC-10 L, AC-14 L, AC-15 L, AC-17 L)* — conformes à la déclaration du Story File | §3 |

**Le critère d'entrée transféré par EPIC_00 est SATISFAIT, et il ne peut pas avoir été plié pour
passer** : `reports/US-01.2/migration_roundtrip_criterion.py` rend **`exit 0`, 8 assertions vertes**, et
`git log --follow` montre qu'il n'a **qu'un seul commit** — **`2f9a57f`**, *« parallel_design clos »*,
**antérieur à la première ligne de `lib/`** *(les commits T1→T15 sont postérieurs)*. ⇒ le critère a été
**écrit avant le code qu'il juge** et **jamais retouché depuis**. C'est la seule configuration dans
laquelle un critère de sortie prouve quelque chose. **Le risque nº 4 d'EPIC_00 est fermé par
exécution**, pas par transfert.

---

## 2. Sorties d'outils — synthèse *(brut en annexe)*

| Commande | Résultat lu dans la sortie |
|---|---|
| `python scripts/run_gates.py --all` | **`Tous les gates bloquants passent (5 exécutés)`** |
| `--gate format` | `Formatted 59 files (0 changed)` |
| `--gate analyze` | `No issues found! (ran in 8.8s)` |
| `--gate test` | `All tests passed!` — **344 tests** · `Couverture de lignes : 97.9% (926/946) — seuil requis : 95.2% (cliquet)` · `[HAUSSE] … Valeur a consigner : 97.8` + `Action HUMAINE : factory.config.json est protege` |
| `--gate build` | `√ Built build\web` **avec `path_provider` au dépôt** |
| `--gate deps_audit` | `You are already using the newest resolvable versions` |
| `python scripts/check_gherkin_mapping.py` | US-01.1 : **13 ↔ 13** · US-01.2 : **50 ↔ 50** · `OK : chaque scenario a son test et chaque test son scenario` |
| `… --selftest` | `Autotest : 6 assertions, 0 echec(s), 2 couple(s) sous controle.` |
| `python scripts/check_e2e_persistance.py` | `[OK ] contrôle « magasin » : 0 écart(s)` · `[OK ] contrôle « racine » : 0 écart(s)` · `CONFORME` |
| `… --selftest` | 8 sources, **8 `[OK ]`**, `Contrôles tués par au moins un mutant : ['magasin', 'racine']` |
| `python reports/US-01.2/migration_roundtrip_criterion.py` | `VERDICT\|OK\|` · `SATISFAIT -- 8 assertions vertes` · **exit 0** |
| `git diff main...HEAD -- reports/US-01.2/migration_roundtrip_criterion.py` | **+902/−0** *(fichier neuf)* ; `git log --follow` → **1 seul commit, `2f9a57f`** *(phase design)* ⇒ **non modifié pour passer** |
| `python scripts/validate_trace.py --us US-01.2` | `Traçabilité conforme.` — `EVT_CODE_READY` présent ⇒ précondition de mon événement satisfaite |
| `python scripts/check_scb_compliance.py` | `SCB conforme — Aucune violation détectée.` |

**Mes propres comptages** *(annexe C — tous lus dans une sortie)* : `grep -c "^  Scénario: "` → **50** ·
`sort | uniq -d | wc -l` → **0** · `grep -c "testWidgets("` → **50** · fichiers `lib/` ajoutés → **15** ·
fichiers `test/` ajoutés → **13** · `grep -rn "dart:io\|path_provider" lib/` → **un seul fichier
importeur, `document_store_io.dart`**, tous les autres résultats sont des **commentaires**.

---

## 3. Conformité AC par AC — les 16 AC actifs *(AC-9 vacant)*

Colonne « type d'assertion » : **ce sur quoi le test porte réellement**, puisque c'est exactement le trou
qui a laissé passer le bloquant **B-2 d'US-01.1** *(un titre juste, une assertion absente)*.

| AC | État | Type d'assertion constaté — ⛔ ce qui empêche un vert vide |
|---|---|---|
| **AC-1** | ✅ **couvert** | Navigation **depuis la racine** *(le fichier e2e n'a qu'un seul `pumpWidget`, et il monte `ConcentrationApp` — vérifié par machine)* ; la page **liste ce que LE FICHIER contient** *(`persistees().single.description`)* ; `theme.brightness == Brightness.dark` ; « Limite » par **`findsNothing` sur l'ancêtre `GestureDetector`** ⛔ pas par un `tap` sans effet, **plus** `findsNothing` sur l'ancêtre `IconButton` de `Icons.settings` |
| **AC-2** | ✅ **couvert, les deux côtés** | **81 refusé / 80 accepté dans le MÊME test**, et le refus est asserté **sur les octets** *(`harnais.octets(), isNull, reason: '⛔ aucune troncature silencieuse'`)* ; `trim` vérifié **sur la valeur persistée**, pas sur le champ. **Mutant M-A** *(81 accepté)* → **3 tests rouges** |
| **AC-3** | ✅ **couvert** | `expect(persistees().single.dateEcheance.hour, 23)`/`minute, 59` ⛔ ni 00:00 ni l'heure courante *(les deux mutants nommés dans le test)* ; « 08:00 aujourd'hui » ⇒ **`find.text('16')` sous `EcheanceTile`** — la donnée du scénario, pas une autre |
| **AC-4** | ✅ **couvert** | `T = 0` refusé **et** `T = +1 min` accepté ; l'**édition** vers le passé refusée avec **égalité des octets d'origine** ; le message **nomme la règle** |
| **AC-5** | ✅ **couvert** | 9ᵉ acceptée *(`findsNWidgets(9)`)* / 10ᵉ refusée avec `persistees() hasLength(9)` **sur le fichier** ; `find.textContaining('supprimer une échéance')` **et** `find.textContaining('disparaît') → findsNothing` *(le geste d'US-01.4 ne doit pas être promis)* ; une **échue compte** ; la suppression **libère une place sans redémarrage**. **Mutant M-B** *(10ᵉ acceptée)* → **9 tests rouges**. ⚠️ voir **NB-H** |
| **AC-6** | ✅ **couvert** | Grille à jour **sans `pumpWidget` supplémentaire** *(⇒ la notification est réellement testée)* ; « 3 jours » → reporté « 5 jours » avec `findsNothing` sur l'ancien nombre ; édition invalide ⇒ **octets d'origine** ; annulation ⇒ **octets d'origine**. ⚠️ voir **NB-F** |
| **AC-7** | ✅ **couvert** | **Le fichier est INCHANGÉ entre la demande et la confirmation** *(assertion explicite)* ; annulation ⇒ octets inchangés ; après confirmation, **relecture par une INSTANCE NEUVE du dépôt** ⇒ absente ; une **échue** se supprime de la même façon |
| **AC-8** | ✅ **couvert, les deux moitiés** | Deux groupes, **`Échues · 1` / `Actives · 2`**, ordres vérifiés ; description vide **listée et manipulable** ; **unité PRÉSENTE en gestion** *(`find.text('3 jours')`)* **ET ABSENTE sur la tuile** *(boucle `findsNothing` sur `jours/jour/heures/mois/ans` sous `EcheanceTile`)* — ⛔ sans la seconde moitié, « une unité partout » aurait satisfait la règle |
| **AC-10** | ✅ **couvert** *(NM-1, NM-2 déclarées)* | Restitution par une **instance neuve** du dépôt et du notifier sur le même répertoire, **échue en tête** *(`premiere.temps.estEchue`)* ; réseau : **contrôle STATIQUE sur les sources de `lib/`** *(8 motifs interdits)* et le test **écrit lui-même** qu'un test ne peut pas prouver un non-appel réseau — **borne NM-2 nommée dans le test** |
| **AC-11** | ✅ **couvert** | Résidu **réellement écrit sur le disque**, `harnais.octets() == document` **octet pour octet** après ouverture, et `harnais.fichiers() == ['echeances.json']` ⇒ ⛔ ni réécrit, ni mis de côté, ni supprimé ; document entier illisible ⇒ `startsWith('echeances.json.illisible-')` ⛔ **jamais un `delete`** ; **4 libellés techniques interdits** assertés absents |
| **AC-12** | ✅ **couvert** — *c'est le cœur* | Patron `seed@v1 (3 échéances) → up → @v2 → down → @v1` avec **égalité des OCTETS** ; **migration exécutée UNE FOIS** par **compteur d'appels** *(`MagasinCompteur`, ⛔ pas une relecture du code)* ; interruption **RÉELLE** *(le système de fichiers refuse)* ⇒ `harnais.octets() == v1` ; **3 mutants portés par le test** — `down` qui ne restaure pas, `up` qui ne transforme rien, **`up` SANS garde d'inversibilité**. ⚠️ voir **NB-E** |
| **AC-13** | ✅ **couvert** | La grille affiche **exactement** le fichier ; ⛔ **les descriptions du jeu d'exemple sont ÉNUMÉRÉES depuis `EcheancesExemple` et exigées `findsNothing`** — nommées, pas devinées ; installation neuve ⇒ état vide **et `harnais.octets(), isNull`** *(l'ouverture n'écrit rien)* ; création ⇒ 3 tuiles **sans redémarrage** |
| **AC-14** | ✅ **couvert** *(NM-5 déclarée)* | **Assertion ANCRÉE sur le texte persisté** : `matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$')` — ⛔ ni `Z`, ni décalage, ni secondes ne peuvent passer ; relecture littérale par instance neuve *(`hour == 9`, `minute == 5`, `isUtc` faux)* |
| **AC-15** | ✅ **couvert** *(Should ; NM-6, NM-7 déclarées)* | `bySemanticsLabel` par champ **avec son caractère obligatoire/optionnel** dans le libellé ; message en `Semantics(liveRegion: true)` ; ⛔ aucun compteur *(`counterText: ''`)*, aucun badge ; rendu sous **`TextScaler.linear(2)`** ; contrastes par **assertions de GRANDEUR** *(`greaterThanOrEqualTo`)* **plus un groupe de contrôle négatif** *(couples qui doivent rester SOUS le seuil)* |
| **AC-16** | ✅ **couvert, les deux côtés** | **31/02 refusé / 28/02 accepté dans le même test**, année **dérivée de l'horloge** ⇒ le refus **ne peut pas** être imputé à AC-4 ; le message **désigne la date verbatim** ; ⛔ **aucune assertion sur la date de dérive** *(bissextile)* — la falsification passe par `harnais.octets(), isNull` ; l'**édition** est refusée avec **égalité des octets**. **Mutant M-C** *(barrière de forme canonique retirée)* → **9 tests rouges**, dont celui qui prouve que `jourExisteAuCalendrier` **n'est pas un second exemplaire de V-1** |
| **AC-17** | ✅ **couvert** *(NM-10 déclarée)* | Échec provoqué **SANS magasin factice** : un **répertoire** est créé au nom du provisoire `echeances.json.tmp`, donc c'est le `writeAsString` **du code de production** qui échoue par une `FileSystemException` **réelle**. Assertions : message présent, **5 libellés techniques interdits assertés absents**, `LigneEcheance findsNothing`, `EcheanceTile findsNothing`, `harnais.octets(), isNull` ; **saisie conservée ET réutilisable** *(le stockage redevient inscriptible, `enregistrer` aboutit **sans ressaisie**)* ; suppression échouée ⇒ **dialogue non fermé** + `harnais.octets() == octetsAvant`. **Mutant M-D** *(mise à jour optimiste)* → **3 tests rouges** |

**Aucun AC orphelin. Aucune clause dont un test porterait le bon titre sans assertionner l'exigence** —
je l'ai cherché explicitement, AC par AC, sur le modèle du bloquant B-2 d'US-01.1.

---

## 4. Les bornes NM-* — honnêtes, ou déguisées en test vert ?

| Borne | Verdict | Ce que j'ai vérifié |
|---|---|---|
| **NM-1** *(redémarrage réel)* | ✅ **honnête** | Le substitut annoncé — *« une nouvelle lecture par une instance neuve »* — est **exactement** ce que fait `ouvrirApplication` *(nouveau dépôt + nouveau notifier sur le même répertoire)*. Aucun test ne prétend à un cycle de vie OS |
| **NM-2** *(mode avion)* | ✅ **honnête** | Le test **écrit lui-même** *« un test NE PEUT PAS prouver un non-appel réseau (borne NM-2) »* et se limite au **contrôle statique** annoncé |
| **NM-4** *(mise à jour installée)* | ✅ **honnête** | La migration est éprouvée **au niveau du stockage**, jamais présentée comme une mise à jour d'application |
| **NM-5** *(voyage / DST observés)* | ✅ **honnête** | ⛔ **Aucun test de bascule DST n'a été fabriqué.** `date_civile_test.dart` porte un en-tête qui **refuse explicitement** d'en écrire un et dit pourquoi *(sous `TZ=UTC` il serait vrai quoi qu'il arrive — le faux vert d'US-01.1)* |
| **NM-6** *(lecteur d'écran réel)* | ✅ **honnête** | Seuls **présence et contenu** des libellés `Semantics` sont assertés |
| **NM-7** *(l'œil, grande police)* | ✅ **honnête** | Contraste **calculé** *(`Rgb.contrasteAvec`)* + rendu sous `TextScaler.linear(2)`. Et `docs/design/us_01_2_contrastes.py` a bien été **SUPPRIMÉ en T9** comme le design l'exigeait *(`git log --name-status` : `A` en `2f9a57f`, **`D` en `1212ecd`**)* ⇒ la règle ne vit qu'en **un exemplaire**, dans le test du job requis |
| **NM-8** *(vrai répertoire de l'appareil)* | ✅ **honnête, et c'est le point le plus subtil du lot** | `lcov` montre les deux lignes de `creerMagasin` **HIT** — j'ai vérifié pourquoi : le test *« sous la VM, la branche IO est retenue — ⛔ PAS le stub »* appelle `magasinDeLaPlateforme()` et assertionne **que l'appel LÈVE**, **que le rendu n'est pas un `DocumentStoreStub`**, **et que l'exception n'est pas un `UnsupportedError`** *(qui signerait le stub)*. ⇒ ce n'est **pas** une borne déguisée en vert : c'est un **contrôle négatif de l'import conditionnel**, et ce qui reste non mesuré *(le vrai répertoire)* n'est **jamais** asserté |
| **NM-9** *(heure civile inexistante)* | ✅ **honnête** | Le prédicat est éprouvé sur la **date hors calendrier**, reproductible partout, **plus** des formes non canoniques *(secondes, `Z`, date sans heure, `25:70`)*. ⛔ Aucun test ne prétend observer un saut de printemps |
| **NM-10** *(web exécuté)* | ✅ **honnête** | Le stub est éprouvé **par import direct** *(R-15)* : `lire() → null`, `ecrire()` et `mettreDeCote()` → `throwsUnsupportedError`. Le comportement de l'**application web exécutée** n'est asserté nulle part |

⇒ **Aucune borne n'a été silencieusement transformée en test vert.** Dans deux cas *(NM-2, NM-5, NM-8,
NM-9)* la borne est **citée dans le corps du test lui-même**, ce qui est la forme la plus résistante :
elle survit au déplacement du code.

---

## 5. Qualité des deux scripts de contrôle Python

### `scripts/check_e2e_persistance.py` — **créé** *(340 lignes)*

**Ce qu'il fait bien, et c'est mesuré** : recherche **multiligne** *(le piège nº 1 du dépôt)* ·
**commentaires retirés en préservant les positions** *(donc les numéros de ligne restent justes — piège
nº 2)* · mutants **comportementaux** *(ils changent le corpus, pas la règle)* · verdicts comparés **en
ENSEMBLES** · **contrôle négatif** *(un mutant dont la source est identique à la conforme est rejeté
comme « ne mesurant rien »)* · il **nomme les contrôles qu'aucun mutant ne tue** · et il **écrit lui-même
ce qu'il n'atteste pas** *(« il ne dit RIEN de ce que les tests ASSERTENT »)*.

**Mutants tirés d'ailleurs que du vocabulaire de la règle ?** **Oui pour le contrôle « racine »**
*(`MaterialApp(home: HubPage)`, `const SizedBox()` — structurels)*. **Partiellement seulement pour le
contrôle « magasin »**, dont la règle **est** nominale ; le mutant **M4_FakeClock_est_licite** est
cependant un vrai mutant de **discrimination** *(il vérifie que le contrôle ne crie pas sur l'horloge
injectée)*, ce qui est exactement ce qui manquait aux instruments faux du projet.

**Savent-ils rougir ?** **Oui — vérifié deux fois** : par son autotest *(`Contrôles tués par au moins un
mutant : ['magasin', 'racine']`)* **et par ma propre sonde** *(annexe F)*, qui a aussi mesuré ses
**angles morts** ⇒ **NB-C**.

### `scripts/check_gherkin_mapping.py` — **modifié** *(+8 lignes)*

Le couple d'US-01.2 est ajouté **en dernier** *(T14)*, comme R-7 l'exigeait — vérifié dans l'ordre des
commits *(`ffd39a3 … T14 — le couple enregistre, EN DERNIER (R-7)`)*, et le commentaire ajouté dit
**pourquoi** l'inscrire plus tôt aurait rendu le job requis rouge. Son `--selftest` **6 assertions,
0 échec**, dont *« mutant titre renommé ⇒ manquant ET orphelin »* et *« les deux motifs sont
DISTINCTS »*. ⚠️ **Sa borne intrinsèque est imprimée par lui-même** : *« Controle de CORRESPONDANCE DE
TITRES -- pas de semantique »* — c'est pour cela que le §3 ci-dessus existe.

### Comptabilité de couverture — vérifiée, pas supposée

`lcov.info` donne **20 lignes non couvertes** et je les ai toutes listées *(annexe B)* :
`rgb.dart` (2) · `concentration_tokens.dart` (1) · `concentration_theme.dart` (1) ·
`remaining_time.dart` (14 — `operator ==` et `hashCode`) · **`gestion_echeances_page.dart` (1)** ·
**`document_store_stub.dart` (1)**. Les **18 premières appartiennent à US-01.1 et cette US ne touche pas
ces fichiers** ; avec `sample_echeances.dart` sorti de `lib/` *(mesuré par R-1 : 27 couvertes / 28
lignes, donc **1** non couverte)*, l'arithmétique **ferme exactement** : `19 − 1 + 2 = 20`.
⇒ **aucune ligne de `lib/` précédemment couverte n'a perdu sa couverture**, et le passage
**399 → 946 lignes** n'a coûté que **2** lignes non couvertes, toutes deux **nommées**.

---

## 6. Ma propre campagne de mutation — 5 mutants, 5 tués

> Méthode imposée par l'acquis du projet : ⛔ **la couverture de lignes est aveugle à la force des
> assertions** ; le seul instrument qui a été juste **7 fois sur 7** est le **mutant**. Je n'ai **pas**
> rejoué les 6 de @Developer : chacun des 5 ci-dessous porte sur une barrière **qu'il n'avait pas
> mutée**. Sortie brute : **annexe G**. Restauration vérifiée : `git status --porcelain` → **vide**.

| # | Mutant posé *(fichier désigné par son texte)* | Ce qu'il détruit | Résultat |
|---|---|---|---|
| **M-A** | `validation_echeance.dart`, `if (libelle.length > longueurMaxDescription)` → `> longueurMaxDescription + 1` | le refus du **81ᵉ** caractère *(AC-2 « Limite »)* | 🔴 **TUÉ — 3 tests**, dont *« ⛔ jamais de troncature silencieuse : 81 n'est pas ramené à 80 »* |
| **M-B** | `validation_echeance.dart`, `if (presentes.length < maxPresentesSurGrille)` → `<=` | le refus de la **10ᵉ** échéance *(AC-5)* | 🔴 **TUÉ — 9 tests**, dont *« Une échéance échue présente sur la grille compte dans la limite de neuf »* ⇒ la clause « une échue compte » est **réellement falsifiable** |
| **M-C** | `date_civile.dart`, **retrait** de `if (formatCivil(local) != texte) return null;` | **LA barrière de forme canonique** *(règle V-1, AC-16)* — celle dont le Story File dit qu'une exception ne la remplace pas | 🔴 **TUÉ — 9 tests**, dont *« ⛔ elle n'est PAS un second exemplaire de V-1 : le prédicat refuse SEUL »* et *« une date NON CANONIQUE fait de l'entrée un résidu, pas une réparation »* |
| **M-D** | `echeances_notifier.dart` : **mise à jour optimiste** de `_echeances` + `notifyListeners()` **avant** `await _depot.creer(...)` | la garantie *« ce qui est affiché correspond toujours à ce qui est sur le disque »* — **c'est le résidu connu de `unawaited_futures`, aveugle dans un appelant synchrone** | 🔴 **TUÉ — 3 tests**, dont **« Un échec d'écriture est annoncé et rien n'est enregistré »** et *« 🔴 échec d'ÉCRITURE : 0 notification, et l'écran ne MENT pas »*. ⇒ **la thèse du Story File est VÉRIFIÉE par mesure** : le refus typé du port **plus** le test d'AC-17 « Erreur » ferment bien ce que le lint ne voit pas |
| **M-E** | `document_store_io.dart` : `.tmp` + `flush` + `rename` → **écriture en place** | l'**atomicité**, qui rend AC-12 « Erreur » vrai par construction. ⚠️ Mutant choisi **exprès** parce que le harnais bloque l'écriture **en créant un répertoire au nom du provisoire** : si l'atomicité disparaissait, le harnais cesserait de bloquer et les tests d'AC-17 auraient pu **verdir à tort** | 🔴 **TUÉ — 14 tests**. ⇒ **le couplage harnais ↔ implémentation ne produit PAS de faux vert** : il produit un rouge, ce qui est le bon sens de l'échec |

---

## 7. Findings — aucun bloquant

> Format : `[Fichier désigné par son texte] | [Problème] | [Correctif attendu]`

### NB-A · non bloquant · contrat du port contredit par sa seule implémentation

`lib/features/echeances/domain/echeance_repository.dart`, doc de `remplacer` : *« Remplace l'échéance de
**même `id`**. Sans correspondance : **échec**. »* |
`lib/features/echeances/data/echeance_document_repository.dart`, `remplacer`, reconstruit la liste par
`for (final e in liste) if (e.id == echeance.id) echeance else e` : **sans correspondance, la liste est
inchangée, l'écriture réussit et le port rend `ResultatEcriture.reussie()`** — l'échec annoncé par le
contrat **n'existe pas**. Aucun AC n'en dépend et le chemin est inatteignable par l'IHM *(une édition part
toujours d'une échéance listée)*, ce qui explique qu'aucun test ne le voie. |
**Correctif** : soit refuser explicitement l'absence de correspondance, soit **retirer la phrase** du
contrat — ⛔ pas la « mettre à jour » vaguement : *une règle écrite à deux endroits dérive*, et ici les
deux exemplaires **ont déjà divergé**.

### NB-B · non bloquant · le message d'échec peut désigner le mauvais acte

`lib/features/echeances/data/echeance_document_repository.dart`, `_ecrire`, branche
`if (document == null)` : `return const ResultatEcriture.echec(ActeEcriture.enregistrement);` — l'acte est
**codé en dur**, alors que la branche `catch` du même corps utilise correctement `acte`. |
Conséquence : une **suppression** qui échoue sur cette branche annoncerait *« L'échéance n'a pas été
enregistrée. »* au lieu de *« La suppression n'a pas eu lieu. »* — ce qui contredit le motif **écrit dans
le port lui-même** : *« Deux textes, pas un […] l'utilisateur doit savoir **ce qui** n'a pas eu lieu. »*
Actuellement inatteignable par l'IHM *(un document de version future rend une liste vide, donc rien n'est
listé à supprimer)*, d'où l'absence de rouge. |
**Correctif** : `return ResultatEcriture.echec(acte);` — **une ligne**, et le `const` disparaît.

### NB-C · non bloquant · `check_e2e_persistance.py` : deux angles morts MESURÉS

`scripts/check_e2e_persistance.py`, `MOTIFS_FACTICES` *(contrôle 2)* et `controle_racine` *(contrôle 1)*. |
Sonde exécutée sur les fonctions du script *(annexe F, sortie collée)* :
* un magasin factice **nommé hors du vocabulaire** — `class MagasinQuiLeve implements DocumentStore {}` ou
  `class _EcritureImpossible implements EcheanceRepository {}` — rend **`controles en echec : AUCUN`** ;
* un fichier de `test/e2e/**` **sans aucun `pumpWidget`** *(le montage délégué à `test/support/`)* rend
  **`AUCUN`** : le contrôle « racine » passe **à vide**, faute d'exiger **au moins un** montage par fichier.

⚠️ **Ce n'est pas une faille du corpus actuel** *(il est conforme, et le script le dit sans mentir)*, mais
le projet a établi qu'un contrôle **purement lexical** a été **faux 7 fois sur 7**. |
**Correctif** : ajouter **(a)** l'exigence « ≥ 1 montage de racine par fichier de `test/e2e/**` », et
**(b)** un critère **structurel** en complément du nominal — toute déclaration
`implements DocumentStore|EcheanceRepository` dans `test/e2e/**` est un écart **quel que soit son nom** ;
chacun avec **son mutant**, comme les 7 existants.

### NB-D · non bloquant · le générateur du fichier e2e n'est ni portable ni vérifié

`reports/US-01.2/generer_e2e.py`, `RACINE = Path(r"c:/Users/guillaume.decroix/MesProjets/Concentration")`
— chemin absolu **d'un poste**, donc **inexécutable en CI ou sur une autre machine** ; et le script n'a
**aucun mode `--check`**. |
✅ **Ce que j'ai vérifié avant de conclure, parce que je le soupçonnais d'être un second exemplaire des
corps de test** : j'ai **régénéré** le fichier, puis appliqué `dart format`, puis comparé — **identique au
fichier commité, 1398 lignes contre 1398, égalité exacte** *(annexe E)*. ⇒ **la filière est fidèle
aujourd'hui, l'accusation de duplication est RÉFUTÉE par la mesure.** ⚠️ Mais **rien ne le vérifie** :
une retouche à la main du `.dart` serait invisible, et une régénération future **détruirait
silencieusement** l'écart. |
**Correctif** : `RACINE = Path(__file__).resolve().parents[2]`, et un mode `--check` qui génère en
mémoire, formate, compare et **rend `exit 1` en cas d'écart** — c'est le même patron que les autres
critères de sortie du projet.

### NB-E · non bloquant · R-13 dévié dans les fixtures, et une fragilité de fuseau qui reste

`test/e2e/gestion_echeances_test.dart`, fixtures d'AC-11 et d'AC-12 : `"2027-03-15T23:59"`,
`"2027-03-15T22:59:00.000Z"`, `"2027-06-02T07:00:00.000Z"`, `"2027-09-10T21:00:00.000Z"` — des **dates de
calendrier en dur**, là où **R-13** dit *« ⛔ aucune date absolue ; seules valeurs fixes admises : 23:59,
80, 9 »*. |
Le préjudice que R-13 vise *(une date qui devient passée et fait pourrir le test en silence)* est
**neutralisé** : l'horloge est une `FakeClock` **figée**, donc rien ne dérive avec le temps. **Mais un
second risque subsiste, d'une autre nature** : la graine `v1` est un **instant UTC** dont l'aller-retour
est asserté **sur les octets** ; sous un fuseau hôte où cet instant tomberait dans un **trou** ou dans la
**2ᵉ occurrence** d'une bascule d'automne, la **garde d'inversibilité** — correctement implémentée — en
ferait des **résidus**, et `expect(persistees(), hasLength(3))` **rougirait**. La suite n'a tourné que sous
**un seul fuseau** *(le critère l'imprime : `offset_janvier=1:00:00`, `offset_juillet=2:00:00`)*. |
**Correctif** : dériver la graine `v1` de l'horloge injectée, **ou** déclarer le fuseau hôte comme
précondition explicite de ces trois scénarios *(cohérent avec NM-5 / NM-9, déjà déclarées)*.

### NB-F · non bloquant · AC-6 « Limite » n'a qu'un point d'application, et il est dans un widget

`lib/features/echeances/domain/validation_echeance.dart` expose `refusEditionEchue` **hors** de `valider`,
et `lib/features/echeances/presentation/gestion_echeances_page.dart` l'appelle dans le gestionnaire de
l'affordance ✎. `EcheancesNotifier.modifier` appelle `valider(..., original: original)`, qui **ne vérifie
pas** que l'original est échu ⇒ un second appelant de `modifier(...)` avec une date future valide
**réussirait** sur une échue, et **aucun test ne rougirait**. |
⚠️ **Ce n'est pas un AC non couvert** : le seul chemin utilisateur passe par ✎, et le scénario
*« L'édition d'une échéance échue est refusée »* est **exécuté et vert**. C'est un **risque de dérive**,
de la même famille que R-10 *(« deux chemins de validation dérivent »)*, appliqué à une autre règle. |
**Correctif** : appeler `refusEditionEchue` **depuis `valider` quand `original != null`** *(la page
continue de l'appeler pour l'**ancrage** du message)*, et ajouter le test unitaire correspondant sur le
notifier.

### NB-G · non bloquant · une ligne non couverte non nommée

`lib/features/echeances/presentation/gestion_echeances_page.dart`, le `onPressed` du bouton **« Fermer »**
du dialogue de refus d'édition d'une échue : **jamais activé par un test** *(seule ligne non couverte du
fichier — annexe B)*. Les deux autres lignes non couvertes de l'US sont, elles, **nommées et motivées**
*(borne NM-8)*. |
**Correctif** : un `tap` sur « Fermer » dans le test existant de l'édition refusée, **ou** l'inscription
explicite de cette ligne comme non couverte assumée — ⛔ le projet n'admet pas une non-couverture
**silencieuse**.

### NB-H · non bloquant · deux assertions de message tautologiques

`test/e2e/gestion_echeances_test.dart`, scénarios *« La dixième création est refusée avec un message
nommant la limite »* et *« Une échéance échue présente sur la grille compte dans la limite de neuf »* :
`expect(find.textContaining('9'), findsWidgets, reason: 'le message NOMME la limite')`. |
Dans **les deux** tests, le champ « Date » porte une saisie dérivée de `maintenant + 40 jours`, soit un
texte contenant **le caractère `9`** ⇒ cette assertion **resterait verte même sans aucun message de
limite**. C'est exactement l'acquis du projet *« les égalités au token sont tautologiques ; seules les
assertions de grandeur tuent un mutant »*, transposé au texte. |
⚠️ **La clause reste bien couverte** : `find.textContaining('supprimer une échéance')`,
`find.textContaining('disparaît') → findsNothing` et `persistees() hasLength(9)` portent la charge — et mon
**mutant M-B** a tué **les deux** tests. |
**Correctif** : assertionner `'Limite de 9'` *(ou la constante `maxPresentesSurGrille` interpolée)* plutôt
que le caractère nu — ⛔ et ne pas retirer les assertions voisines qui « font doublon » : ce sont elles qui
tuent.

---

## 8. Ce que ce code **n'atteste PAS** — aussi précis que le reste

* ⛔ **L'application n'a jamais tourné sur un appareil.** **NM-1, NM-2, NM-4, NM-6, NM-7, NM-8** restent
  **non levées** ; **NM-10** *(web exécutée)* ⛔ **ne se lèvera PAS avec US-01.3**, qui vise iOS/Android.
* ⛔ **La suite n'a tourné que sous UN fuseau.** Le critère l'imprime lui-même :
  `offset_janvier=1:00:00|offset_juillet=2:00:00`. **NM-5** et **NM-9** demeurent, et **NB-E** en nomme la
  conséquence concrète sur trois scénarios.
* ⛔ **Le refus d'une HEURE civile inexistante n'a jamais été observé** *(saut de printemps)*. Le chemin de
  code existe et est **atteint** par une heure hors plage *(`25:70`)*, ⛔ **jamais par une vraie
  transition**.
* ⛔ **Aucun SAST, aucun scan de CVE.** `path_provider` entre avec **+24 paquets transitifs** et sa seule
  barrière est la **revue humaine** — le gate `deps_audit` mesure l'**obsolescence**, ⛔ pas la
  vulnérabilité.
* ⛔ **Le contraste est CALCULÉ, jamais vu par un œil** ; **aucun test de vision des couleurs**.
* ⛔ **`check_gherkin_mapping.py` compare des TITRES** — *il l'imprime lui-même*. **50 ↔ 50** ne dit rien de
  ce qui est asserté ; c'est le §3 qui le dit, **par lecture humaine**.
* ⛔ **`check_e2e_persistance.py` atteste des conditions NÉCESSAIRES** *(racine montée, magasin réel)*,
  ⛔ **jamais suffisantes** — il l'écrit, et **NB-C** mesure en plus ses deux angles morts.
* ⛔ **Le patron aller-retour est prouvé sur `v1 ⇄ v2` UNIQUEMENT**, sur un `v1` **que personne n'a jamais
  détenu** *(le code le dit : « sur `v1` la portée réelle est nulle »)*. La garde d'inversibilité est
  correcte **et** elle a un coût assumé : une entrée non inversible **devient un résidu** — aucune donnée
  perdue, **une échéance peut disparaître de la grille**.
* ⛔ **Aucune PR n'est ouverte** au moment de cet audit *(case 2 de la DoD)*, et la **branche réelle**
  `feat/US-01.2-design` **n'est pas** celle déclarée dans les métadonnées du Story File
  *(`feat/US-01.2-gestion-echeances`, déjà fusionnée dans `main` — `fe85364`)*. **Constat, hors périmètre
  de ma décision.**
* ⛔ **Je n'ai vu aucun écran.** Mon verdict porte sur du code, des assertions et des sorties d'outils.

---

## 9. Ce qui reste dû à d'autres rôles *(⛔ je ne le tranche pas)*

* La **hausse du cliquet à `97.8`** est **signalée par le gate** et exige une **action humaine** —
  `factory.config.json` est protégé, ⛔ aucun agent ne l'édite. **Je n'y ai pas touché.**
* La **péremption du `🧪 PASS` d'US-01.1** *(§Effet de bord du Story File)* doit être **transmise** à qui
  la certifiera. ✅ **Ce que je peux attester** : **aucun titre de scénario d'US-01.1 n'est modifié**
  *(`git diff main...HEAD` filtré sur `testWidgets(` et `Scénario:` → **sortie vide**)*, et les **4**
  assertions annoncées sont reprises **exactement** comme mesuré — la boucle est **resserrée sur
  `Icons.settings`**, ⛔ pas supprimée.
* **NB-7 est CORRIGÉ** *(et je l'ai vérifié dans le diff, pas de mémoire)* : `test/support/rendu_couleur.dart`,
  `fondDeLaTuile` porte désormais `expect(boites, findsOneWidget, reason: 'NB-7 : plusieurs DecoratedBox …')`
  **avant** sélection. ⇒ le défaut porté d'US-01.1 est **fermé**, et il l'est **avant** T9/T10/T11 comme la
  décision nº 8 du Design UX l'exigeait.
* **Deux fichiers non suivis** *(`test/zz_audit_securite_us012_sonde*.dart`)* et une modification de
  `.claude/settings.json` sont apparus dans l'arbre **pendant** ma session, ⛔ **de mon fait pour aucun des
  deux** ; ils ont disparu avant ma vérification finale *(`git status --porcelain` → **vide**)*. **Signalé,
  pas corrigé.** ⚠️ Mes sorties de gates de l'annexe A ont été produites sur un **arbre propre**, avant leur
  apparition.

---

# Annexes — sorties BRUTES

## Annexe A — `python scripts/run_gates.py`

```
$ python scripts/run_gates.py --gate format
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 0.52 seconds.
✅ app.format
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate analyze
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 8.8s)
✅ app.analyze
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate test        (extrait de fin)
02:00 +343: …/test/e2e/gestion_echeances_test.dart: Après un échec d'écriture la saisie est conservée et la nouvelle tentative aboutit
02:02 +344: All tests passed!
Couverture de lignes : 97.9% (926/946) — seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigné le 2026-08-02 à PR27
  [HAUSSE] 97.89% (926/946) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.8
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
✅ app.test

$ python scripts/run_gates.py --all              (extrait de fin)
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

## Annexe B — lignes non couvertes, extraites de `coverage/lcov.info`

```
lib/core/color/rgb.dart                                          [59, 60]
lib/core/theme/concentration_tokens.dart                         [14]
lib/core/theme/concentration_theme.dart                          [23]
lib/features/echeances/domain/remaining_time.dart                [37, 39, 40, 41, 42, 43, 44, 46, 47, 48, 49, 50, 51, 52]
lib/features/echeances/presentation/gestion_echeances_page.dart  [117]
lib/features/echeances/data/document_store_stub.dart             [38]
TOTAL lignes non couvertes : 20

SF:lib\features\echeances\data\document_store_io.dart      LF:26  LH:26   (DA:83,1  DA:84,1 — `creerMagasin` ATTEINT, cf. §4 NM-8)
SF:lib\features\echeances\data\document_store_stub.dart    LF:7   LH:6    (DA:38,0)
SF:lib\features\echeances\data\document_store_plateforme.dart LF:1 LH:1   (DA:15,2)
```

## Annexe C — mes comptages, tous LUS dans une sortie

```
scenarios .feature US-01.2 : 50
titres en double : 0
testWidgets dans l'e2e : 50
fichiers lib/ ajoutes par l'US : 15
fichiers test/ ajoutes : 13

$ grep -rn "dart:io\|path_provider" lib/ --include=*.dart
lib/features/echeances/data/document_store.dart:3:            (commentaire)
lib/features/echeances/data/document_store_io.dart:1:import 'dart:io';
lib/features/echeances/data/document_store_io.dart:3:import 'package:path_provider/path_provider.dart';
lib/features/echeances/data/document_store_io.dart:12,79:    (commentaires)
lib/features/echeances/data/document_store_plateforme.dart:14: (commentaire)
lib/features/echeances/data/document_store_stub.dart:3:      (commentaire)
lib/features/echeances/data/echeance_document_codec.dart:38:  (commentaire)
lib/features/echeances/data/echeance_document_repository.dart:10: (commentaire)
lib/main.dart:7:                                             (commentaire)
⇒ UN SEUL fichier importeur, et son nom finit par `_io.dart`.

$ git diff main...HEAD -- test/e2e/hub_echeances_test.dart tests/features/US-01.1-*.feature | grep -E "^[+-].*(testWidgets\(|Scénario:)"
(sortie vide = aucun titre d'US-01.1 touché)
```

## Annexe D — contrôles de gouvernance et critère d'entrée

```
$ python scripts/check_gherkin_mapping.py
T12b -- correspondance scenario <-> test
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
  tests/features/US-01.2-gestion-echeances.feature     50 scenarios
  test/e2e/gestion_echeances_test.dart                 50 tests
OK : chaque scenario a son test et chaque test son scenario. Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
EXIT=0

$ python scripts/check_gherkin_mapping.py --selftest
  [OK] corpus conforme => 0 ecart
  [OK] mutant test retire => refus qui NOMME le scenario
  [OK] mutant test orphelin => refus DISTINCT du manquant
  [OK] mutant titre renomme => manquant ET orphelin
  [OK] un titre a apostrophe est lu correctement
  [OK] les deux motifs sont DISTINCTS
Autotest : 6 assertions, 0 echec(s), 2 couple(s) sous controle.
EXIT=0

$ python scripts/check_e2e_persistance.py
== ADR-010 §1 : la racine est montée, le magasin est RÉEL ==
   fichier : test/e2e/gestion_echeances_test.dart
   fichier : test/e2e/hub_echeances_test.dart
[OK ] contrôle « magasin » : 0 écart(s)
[OK ] contrôle « racine » : 0 écart(s)
CONFORME — les deux contrôles d'ADR-010 §1 passent.
EXIT=0

$ python scripts/check_e2e_persistance.py --selftest
== AUTOTEST DE MUTATION de check_e2e_persistance ==
   8 sources (1 conforme + 7 mutants COMPORTEMENTAUX)
   Verdicts comparés en ENSEMBLES, ⛔ jamais en cardinaux.
[OK ] M0_conforme                        attendu=aucun obtenu=aucun
[OK ] M1_sous_arbre_multiligne           attendu=['racine'] obtenu=['racine']
[OK ] M2_motif_seulement_en_commentaire  attendu=aucun obtenu=aucun
[OK ] M3_magasin_factice                 attendu=['magasin'] obtenu=['magasin']
[OK ] M4_FakeClock_est_licite            attendu=aucun obtenu=aucun
[OK ] M5_faux_depot                      attendu=['magasin'] obtenu=['magasin']
[OK ] M6_stub_de_plateforme              attendu=['magasin'] obtenu=['magasin']
[OK ] M7_pumpWidget_sans_argument_connu  attendu=['racine'] obtenu=['racine']
Contrôles tués par au moins un mutant : ['magasin', 'racine']
AUTOTEST OK : les deux contrôles savent rougir, et sur les bons cas.
EXIT=0

$ python reports/US-01.2/migration_roundtrip_criterion.py
== CRITERE DE SORTIE : patron aller-retour ADR-005 sur le module REEL ==
   cible : lib/features/echeances/data/echeance_schema_migrations.dart
CONTEXTE|dart=3.12.2|offset_janvier=1:00:00.000000|offset_juillet=2:00:00.000000|non_inversibles_ici=a4,a6
ASSERTION|A1_contrat_couple|OK|
ASSERTION|A2_montee_transforme|OK|
ASSERTION|A3_aller_retour|OK|
ASSERTION|A4_idempotence|OK|
ASSERTION|A5_cles_inconnues|OK|
DETAIL|A6|a1=convertie a2=convertie a3=convertie a4=verbatim a6=verbatim
ASSERTION|A6_jamais_de_conversion_avec_perte|OK|
ASSERTION|A7_version_non_supportee|OK|
ASSERTION|A8_forme_canonique_civile|OK|
VERDICT|OK|
SATISFAIT -- 8 assertions vertes. Le patron de MIGRATIONS.md section 4
est INSTANCIE ET EXECUTE sur le premier schema reel du projet.
EXIT=0

$ git diff main...HEAD --stat -- reports/US-01.2/migration_roundtrip_criterion.py
 reports/US-01.2/migration_roundtrip_criterion.py | 902 +++++++++++++++++++++++
 1 file changed, 902 insertions(+)
$ git log --oneline --follow -- reports/US-01.2/migration_roundtrip_criterion.py
2f9a57f feat(us-01.2): parallel_design clos — les 2 instruments publies ont ete EXECUTES
⇒ UN SEUL commit, en phase DESIGN, ANTERIEUR a toute ligne de lib/. Jamais retouche.

$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.
```

## Annexe E — le fichier e2e est-il reproduit par son générateur ? *(NB-D)*

```
$ python reports/US-01.2/generer_e2e.py
ECRIT : …\test\e2e\gestion_echeances_test.dart (50 tests)

# comparaison brute générateur vs fichier commité :
COMMITE  : 1398 lignes
REGENERE : 1250 lignes
IDENTIQUES (fins de ligne normalisees) : False      ← soupçon de duplication divergente

# le générateur émet du code NON FORMATÉ. On applique dart format, puis on recompare :
$ dart format <copie du fichier régénéré>
Formatted 1 file (1 changed)
generateur + dart format == fichier commite : True
lignes commite=1398  regenere_formate=1398

⇒ SOUPÇON RÉFUTÉ PAR LA MESURE : la filière est fidèle. Ce qui reste (NB-D) : chemin absolu
   codé en dur, et AUCUN mode --check pour que la fidélité soit vérifiée par machine.
```

## Annexe F — sonde de l'auditeur sur `check_e2e_persistance.py` *(NB-C)*

```
$ python -c "<import du module, appels directs a evaluer()>"
A. magasin factice NOMME hors vocabulaire            -> controles en echec : AUCUN
B. depot factice nomme _EcritureImpossible           -> controles en echec : AUCUN
C. AUCUN pumpWidget (delegue a test/support/)        -> controles en echec : AUCUN
D. reference: MagasinFactice (vocabulaire)           -> controles en echec : ['magasin']
```

## Annexe G — campagne de mutation de l'auditeur, et restauration

```
$ <M-A>  MUTANT M-A pose : le 81e caractere devient ACCEPTE
01:55 +356 -3: Some tests failed.
Failing tests:
  test/e2e/gestion_echeances_test.dart: Une description trop longue est refusée
  test/features/echeances/domain/validation_echeance_test.dart: AC-2 … 80 caractères ACCEPTÉS / 81 REFUSÉS
  test/features/echeances/domain/validation_echeance_test.dart: AC-2 … ⛔ jamais de troncature silencieuse : 81 n’est pas ramené à 80

$ <M-B>  MUTANT M-B pose : la 10e echeance devient ACCEPTEE
01:52 +354 -9: Some tests failed.
Failing tests:
  test/e2e/gestion_echeances_test.dart: La dixième création est refusée avec un message nommant la limite
  test/e2e/gestion_echeances_test.dart: Une échéance échue présente sur la grille compte dans la limite de neuf
  test/features/echeances/domain/validation_echeance_test.dart: AC-5 … la 9ᵉ est ACCEPTÉE / la 10ᵉ est REFUSÉE — les deux côtés
  test/features/echeances/domain/validation_echeance_test.dart: AC-5 … le message NOMME 9 et la SEULE issue disponible : supprimer
  ... and 5 more

$ <M-C>  MUTANT M-C pose : la comparaison a la FORME CANONIQUE est retiree (regle V-1 desarmee)
01:56 +354 -9: Some tests failed.
Failing tests:
  test/features/echeances/data/echeance_document_codec_test.dart: AC-11 … une date NON CANONIQUE fait de l’entrée un résidu, pas une réparation
  test/features/echeances/data/echeance_schema_migrations_test.dart: civilVersInstant refuse ce qui n’est pas un v2 canonique
  test/features/echeances/domain/date_civile_test.dart: ⛔ elle n’est PAS un second exemplaire de V-1 : le prédicat refuse SEUL
  test/features/echeances/domain/date_civile_test.dart: des secondes rendent la forme non canonique
  ... and 5 more

$ <M-D>  MUTANT M-D pose : MISE A JOUR OPTIMISTE avant l ecriture (residu U-6 / unawaited_futures)
01:57 +360 -3: Some tests failed.
Failing tests:
  test/e2e/gestion_echeances_test.dart: Un échec d'écriture est annoncé et rien n'est enregistré
  test/features/echeances/presentation/echeances_notifier_test.dart: creer, modifier, supprimer notifient une fois CHACUNE
  test/features/echeances/presentation/echeances_notifier_test.dart: 🔴 échec d’ÉCRITURE : 0 notification, et l’écran ne MENT pas

$ <M-E>  MUTANT M-E pose : ECRITURE EN PLACE, l atomicite .tmp+rename est retiree
01:58 +349 -14: Some tests failed.
Failing tests:
  test/e2e/gestion_echeances_test.dart: Après un échec d'écriture la saisie est conservée et la nouvelle tentative aboutit
  test/e2e/gestion_echeances_test.dart: Un échec d'écriture est annoncé et rien n'est enregistré
  test/e2e/gestion_echeances_test.dart: Une migration interrompue laisse les données dans leur état antérieur
  test/e2e/gestion_echeances_test.dart: Une suppression qui ne peut pas être écrite laisse l'échéance en place
  ... and 10 more

$ git status --porcelain
(sortie VIDE)
$ git diff --stat -- lib/ test/ scripts/ reports/ pubspec.yaml
(sortie VIDE)
⇒ 5 mutants, 5 TUES, 0 survivant. Arbre RESTAURE a l'identique.
```

---

**Verdict final : ✅ PASSED sur `5272ed1`** — **0 finding bloquant**, **8 non bloquants** *(NB-A → NB-H)*,
à verser au cycle *(NB-B et NB-G sont des correctifs d'une ligne ; NB-C et NB-D touchent des instruments
de contrôle et relèvent d'`/audit-methodo` ou d'US-00.8)*.
