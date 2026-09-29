# 🧪 Stratégie de test — Concentration

> **Ce document ne crée aucune règle et ne fixe aucun seuil.** Il cartographie les instruments qui
> **existent**, dit pour chacun **ce qu'il mesure** et **ce qu'il ne mesure pas**, et renvoie chaque
> valeur à son **exemplaire unique**. ⛔ **Aucun seuil n'est écrit ici** : *une règle n'existe qu'en un
> seul exemplaire — deux copies dérivent*, et ce projet l'a vérifié trois fois. Là où un nombre
> apparaît, il porte **sa date** et **la commande qui le produit**.
>
> 📐 **Mesures de ce document** : prises le **2026-09-08**, au commit **`b151233`**, branche
> `feat/US-01.4-gestes-tuile`. Elles ne sont pas des engagements : elles décrivent l'état à cette date
> et **se rejouent** par les commandes citées. **Relevé précédent : 2026-08-25, commit `5050896`** —
> le document n'était alors **pas versionné**.
>
> ⛔ **Un chiffre de ce document ne se lit pas sans sa date.** Si le relevé a plusieurs tâches de
> retard, **rejouer la commande** plutôt que croire le nombre — *une valeur mise à jour périme au
> cycle suivant*, et c'est précisément pourquoi chaque nombre est accompagné de ce qui le produit.

---

## 1. Le principe : trois questions distinctes, et aucun instrument ne répond à la question du voisin

C'est le seul énoncé de ce document qui mérite d'être retenu par cœur, parce qu'il a été **payé trois
fois** dans ce dépôt.

| Question | Instrument | Ce qu'il répond | ⛔ Ce qu'il ne dit **pas** |
|---|---|---|---|
| Le code se compile-t-il et respecte-t-il ses normes ? | `dart format`, `flutter analyze`, `flutter build web --release` | Le code est **constructible** et **conforme aux lints** | Rien sur le comportement. Un `analyze` vert peut couvrir un produit entièrement faux |
| Le code est-il **traversé** par les tests ? | Couverture de **lignes** — `flutter test --coverage` + [`check_flutter_coverage.py`](../../scripts/check_flutter_coverage.py) | % de lignes de `lib/` **exécutées au moins une fois** | ⛔ Rien sur la **force des assertions**. Une ligne traversée sans être jugée est « couverte » |
| Les tests **jugent-ils** ce qu'ils traversent ? | **Mutation** — à la main, pas de gate | Si une assertion **tombe** quand le produit devient faux | Rien d'automatique : c'est **la seule mesure du projet qui n'a aucun gate** (§6) |
| Les scénarios écrits sont-ils **exécutés** ? | [`check_gherkin_mapping.py`](../../scripts/check_gherkin_mapping.py) | Chaque scénario d'un `.feature` **sous contrôle** a un test qui reprend son titre | ⛔ Il compare des **titres**, jamais la sémantique. Il l'imprime lui-même |
| Un test « e2e » monte-t-il l'**application réelle** ? | [`check_e2e_persistance.py`](../../scripts/check_e2e_persistance.py) | Tout `pumpWidget(` de `test/e2e/**` monte `ConcentrationApp`, et aucun magasin factice n'y vit | Rien sur ce que le scénario éprouve |

🔴 **Les trois preuves internes que ces questions sont bien distinctes** :

1. **US-01.1** — **380/399 avant, 380/399 après**, pour **+526 lignes de test** et **6 mutants tués**.
   La couverture **n'a vu ni le défaut ni sa correction**.
2. **US-01.4 / T4** — le mutant `hub_page` (`echeances` au lieu de `presentes`) portait sur une ligne
   **couverte**, et **431 tests sont restés verts**. Le câblage était juste, et **rien n'aurait signalé
   sa régression** : *une surface sans clause pour l'observer.*
3. **US-00.5** — sur **six** instruments de contrôle faux, un contrôle **portant son mutant** a été
   juste **7 fois sur 7** ; un contrôle **purement lexical**, faux **7 fois sur 7**.

➡️ **Conséquence de méthode, non négociable** : un verdict de qualité s'appuie sur **plusieurs**
instruments, et *« la suite est verte »* n'est jamais à lui seul un argument.

---

## 2. La pyramide réelle, telle qu'elle est — mesurée

| Niveau | Où il vit | Ce qui l'exécute | Volume au 2026-09-08 |
|---|---|---|---|
| Unitaire (domaine, codec, migrations, couleurs) | `test/core/**`, `test/features/**/domain`, `**/data` | `flutter test` | 18 fichiers |
| Widget (`testWidgets`, `WidgetTester`) | `test/features/**/presentation` | `flutter test` | 12 fichiers |
| **E2E in-process** — monte `ConcentrationApp` sur un **disque réel** | `test/e2e/` | `flutter test` + `check_e2e_persistance.py` | 2 fichiers |
| Harnais de test (outillage partagé, testé lui-même) | `test/support/` | `flutter test` | 5 fichiers, dont **1 qui teste un harnais** |
| Analyse statique | — | `dart format`, `flutter analyze` | gate `app.format`, `app.analyze` |
| Constructibilité | — | `flutter build web --release` | gate `app.build` |
| Contrôles de corpus (SCB, trace, mapping, synchro) | `scripts/*.py` | job CI **requis** `governance` | 12 scripts |
| **Critères de sortie exécutables** (§7) | `reports/US-*/**.py` | à la main, sur demande | 9 fichiers |

**Commandes de mesure** *(à rejouer plutôt qu'à croire)* :

```bash
find test -name '*_test.dart' | wc -l              # 33 fichiers de test
flutter test | tail -1                             # 521 tests, All tests passed (3:02)
python scripts/run_gates.py --all                  # 5 gates exécutés
```

⚠️ **`test/e2e/` n'est pas `integration_test/`.** Le choix est **arbitré** par
[ADR-008](../adr/ADR-008-arbitrages-track-full.md) : *un test qui monte l'application entière vaut
scénario E2E pour une application offline-first sans backend*. Le motif est **mesuré**, pas
esthétique : `integration_test` était **absent** du projet et **aucun appareil ne tourne en CI**, donc
la tâche qui l'exigeait était **inexécutable**. ⛔ **La contrepartie n'est pas facultative** : ADR-008
attache à cette autorisation la **vérification par machine** de la correspondance scénario ↔ test
(§8) et, depuis ADR-010, celle du **montage de la racine** (`check_e2e_persistance.py`) — parce que
11 tests sur 13 montaient `MaterialApp(home: HubPage)` et qu'**aucun contrôle ne pouvait le voir**.

---

## 3. La couverture : ce que le nombre mesure **exactement**

### 3.1 L'implémentation, ligne à ligne

`flutter test --coverage` produit `coverage/lcov.info`. Le format porte un enregistrement
**`DA:<ligne>,<hits>`** par ligne **instrumentée**, plus deux totaux **déclarés** `LF:` (lignes
instrumentées) et `LH:` (lignes atteintes).

[`check_flutter_coverage.py`](../../scripts/check_flutter_coverage.py) :

1. compte **toutes** les lignes `DA:` → `total` ;
2. compte celles dont **`hits > 0`** → `covered` ;
3. **recoupe** son compte avec les totaux **déclarés** `LF:`/`LH:` — **toute divergence est un échec
   explicite**.

⚖️ **Le point 3 n'est pas du zèle, c'est un correctif de finding (B-1, 2026-07-31).** La version
précédente ignorait `LF:`/`LH:` : un rapport déclarant `LF:19 / LH:5` tout en listant 19 lignes
couvertes rendait **« 100.0 % (19/19) », exit 0**, *et proposait de consigner 100,0* — ce qui aurait
**verrouillé le dépôt**, le gate étant un contexte **requis**. ⛔ **Le mutant qui l'a trouvé n'avait
été écrit par personne : c'est l'auditeur qui l'a fabriqué.**

➡️ **Donc : « couverte » = LIGNE EXÉCUTÉE AU MOINS UNE FOIS.** Ni jugée, ni assertée, ni correcte.

### 3.2 Fail-explicit — la liste des refus, et pourquoi chacun existe

| Situation | Verdict | Motif |
|---|---|---|
| Rapport lcov absent | **échec** | pas de mesure ≠ mesure réussie |
| 0 ligne instrumentée | **échec** | *« un vert par vide est un mensonge »* |
| `LF:`/`LH:` contredisent le compte | **échec** | un rapport qui se contredit n'est pas une mesure |
| `DA:` malformée (`DA:9`, `DA:9,abc`, `DA:9,0,aBcD1234`) | **échec nommé** | ⛔ jamais un traceback : *un plantage sur un contexte requis donne un message inutilisable à qui doit le réparer* |
| Clé `coverage_ratchet` absente | plancher seul + **message explicite** | jamais un seuil anonyme |
| Référence **sous** le plancher contractuel | **échec** | ⛔ jamais résolu en silence par « le plus strict gagne » |

### 3.3 Ce que le dénominateur contient — et ce qu'il **exclut**

```bash
grep -c '^SF:' coverage/lcov.info      # 35 fichiers dans la mesure
find lib -name '*.dart' | wc -l        # 36 fichiers dans lib/
grep '^SF:' coverage/lcov.info | grep -v 'lib[/\\]'   # vide : uniquement lib/
```

🔴 **`lib/main.dart` (31 lignes) n'est PAS dans le dénominateur.** Ce n'est pas une anomalie du
script : c'est l'**angle mort structurel** nommé par la [Constitution Art. 4](../governance/CONSTITUTION.md) —
**un fichier source qu'aucun test n'importe n'entre pas dans la mesure**. Trois conséquences, toutes
contre-intuitives et toutes vraies :

* ajouter du code **non testé** dans un fichier non importé **ne fait pas baisser** la couverture ;
* **déplacer** du code non couvert vers un tel fichier **la fait monter** ;
* ⛔ **on peut donc « améliorer la couverture » sans écrire un seul test.**

État de la mesure au 2026-09-08 — **1122 / 1144**, soit **22 lignes non couvertes**, dont **14 dans un
seul fichier**. ⛔ **La liste se LIT, elle ne se recopie pas** :

```bash
awk '/^SF:/{f=$0} /^DA:/{split(substr($0,4),a,","); if(a[2]==0) print f, a[1]}' coverage/lcov.info
```

| Lignes | Fichier |
|---|---|
| 14 *(37-52)* | [`remaining_time.dart`](../../lib/features/echeances/domain/remaining_time.dart) |
| 2 *(305-306)* | [`echeance_tile.dart`](../../lib/features/echeances/presentation/widgets/echeance_tile.dart) |
| 2 *(59-60)* | [`rgb.dart`](../../lib/core/color/rgb.dart) |
| 1 chacune | `concentration_tokens.dart`, `concentration_theme.dart`, `gestion_echeances_page.dart`, `document_store_stub.dart` |

### 3.4 Les trois choses que la couverture ne mesure pas, et qu'on lui prête souvent

| On croit mesurer | Réalité |
|---|---|
| la couverture de **branches** | ⛔ **aucune** n'est mesurée. `if (a && b)` traversé une fois est « couvert », quelles que soient les combinaisons non jouées |
| la couverture des **AC** | ⛔ **rien** ne la mesure. La DoD générique n'exige la couverture d'**aucun** AC (§12) |
| la **force** des tests | ⛔ voir §1 et §6. C'est la mutation, et elle n'a **aucun gate** |

---

## 4. Le cliquet (*ratchet*) : définition, et ce que le hausser achète

### 4.1 Deux seuils, deux rôles — ils **coexistent**

| | Rôle | Où vit sa valeur |
|---|---|---|
| **Plancher contractuel** (`--min`) | Il **ne borne pas la couverture** : il borne **jusqu'où la référence peut être abaissée**. Nommé par ADR-001, immuable | argument du gate, dans `factory.config.json` → `adapter.components.app.gates.test.cmd` |
| **Cliquet** (`coverage_ratchet`) | Il interdit la **régression sous le dernier niveau CONSIGNÉ** | `factory.config.json` → `adapter.components.app.coverage_ratchet`, sous la forme `{value, date, motif}` |

Le seuil appliqué est **`max(plancher, cliquet)`**, et le gate **imprime toujours lequel des deux
décide** — ⛔ jamais un « seuil » anonyme.

### 4.2 Trois propriétés qui en font un instrument, et non une décoration

1. **La valeur est LUE, jamais écrite.** Prouvé par un contrôle **différentiel** dans
   [`selftest_coverage_ratchet.py`](../../scripts/selftest_coverage_ratchet.py), qui tourne dans le job
   **requis** `governance` : la même fixture est rejouée sous **deux** références et le verdict **doit
   changer** — ce qui **interdit à un checker d'écrire sa valeur au lieu de la lire**.
2. **Il ne monte JAMAIS seul.** Une hausse est **signalée** par le gate, **jamais consignée** sans une
   **édition humaine** : `factory.config.json` est un fichier d'**enforcement**, refusé aux agents par
   [`protect_files.sh`](../../.claude/hooks/protect_files.sh).
3. **La valeur à consigner est arrondie VERS LE BAS.** Consigner l'*affiché* fabriquerait un **rouge
   sur un dépôt inchangé** — la mesure de US-00.6 valait 89,4737 % et s'affichait « 89.5 % ».

### 4.3 Ce que hausser le cliquet achète — et ce que cela ne change pas

Le cliquet ne protège pas *un niveau de qualité* : il protège **le dernier niveau consigné**. Tant
qu'il n'est pas consigné, l'écart entre la mesure du jour et la référence est un **mou** que le
développement suivant peut dépenser **sans qu'aucun gate ne rougisse**.

**La formule, à rejouer plutôt qu'à recopier.** Avec `c` le cliquet (en %), `L` les lignes couvertes
et `T` le total du moment, on peut perdre au plus **`L − ⌈c·T/100⌉`** lignes, et sur `n` lignes
nouvelles on peut en laisser au plus :

```
U ≤ (1 − c/100)·n + (L − c·T/100)
```

Instance **dérivée le 2026-09-08** (`c` **lu** dans la configuration = 95,2 ; `L`/`T` **lus** dans le
lcov = 1122/1144, soit 98,08 %) :

| Référence en vigueur | Lignes perdables **sans rougir** | Budget sur `n` lignes nouvelles |
|---|---|---|
| cliquet **non consigné** *(95,2)* | **32** *(soit 2,8 pt de régression invisible)* | `U ≤ 0,048·n + 32` |
| cliquet **consigné** *(98,0)* | **0** — une seule ligne perdue rend le job requis rouge | `U ≤ 0,020·n` |

⚖️ **Illustration LIVE du point 3 de §4.2, relevée le 2026-09-08** : la mesure vaut **98,0769 %**,
le gate **affiche « 98.1 % »** et propose de consigner **`98.0`** — *arrondi VERS LE BAS*.
⛔ **Consigner l'affiché fabriquerait un rouge sur un dépôt inchangé**, et c'est exactement le
défaut qu'US-00.6 avait payé à 89,4737 %.

➡️ **Voilà tout l'intérêt de la hausse : convertir un acquis mesuré en barrière.** Et voilà son coût,
qu'il faut nommer : une **marge nulle**, donc la discipline *« les tests sont livrés dans le même
commit que le code »* cesse d'être un conseil.

⛔ **Ce que la hausse n'achète pas** : elle interdit une **régression numérique**. Elle ne rend la
suite **pas plus forte d'un iota** (§1, §6).

### 4.4 Comment on hausse — le geste exact

Le gate imprime lui-même la valeur à consigner et **désigne l'action humaine**. Le geste :

1. **PR dédiée**, sur une branche `feat/US-XX.X-...` — ⛔ sinon `check-branch-name`, contexte
   **requis**, la rend **définitivement infusionnable** ;
2. `{value, date, motif}` renseignés — le `motif` **nomme ce qui a produit le niveau** (précédent :
   `PR27`) ;
3. **fusion par l'humain, sans `--admin`** (renforcement R-c) ;
4. ⚠️ `strict: true` **sérialise les merges** : toute fusion **périme** les branches ouvertes, qui
   devront être remises à jour.

---

## 5. Ce qui tourne où, et ce qui bloque quoi

| Gate `app.*` | Commande | Bloquant ? |
|---|---|---|
| `format` | `dart format --output=none --set-exit-if-changed lib test` | oui |
| `analyze` | `flutter analyze` | oui |
| `test` | `flutter test --coverage && python scripts/check_flutter_coverage.py --min <plancher>` | oui |
| `deps_audit` | `dart pub outdated --show-all` | **non** *(`blocking: false`, lu dans la config)* |
| `build` | `flutter build web --release` | oui |

⚠️ **Le gate `build` prouve la CONSTRUCTIBILITÉ, pas la cible produit.** Un vert signifie *« le code
compile pour cette cible »* — la cible de distribution (iOS/Android, RNF-08) est autre chose.

**Quatre contextes REQUIS** par la protection de branche, lus dans `factory.config.json` →
`status_checks` : `secrets-scan` · `governance` · `app-quality` · `check-branch-name`. Les trois
premiers vivent dans [`ci.yml`](../../.github/workflows/ci.yml), le quatrième dans
[`branch-naming.yml`](../../.github/workflows/branch-naming.yml).

Le job **`governance`** est celui qui porte les contrôles de corpus : SCB, trace, synchro de config,
**autotest du cliquet**, **mapping Gherkin et son autotest de mutation**, `actionlint`.
[`e2e.yml`](../../.github/workflows/e2e.yml) rejoue les gates `app` **la nuit** (cron) — c'est un
*smoke* de non-régression, ⛔ pas un parcours utilisateur supplémentaire.

---

## 6. Les mutants : le seul instrument qui mesure la **force** des assertions

### 6.1 Ce qu'un mutant est — et le retournement qu'il opère

Un **mutant** est une version **délibérément fausse** d'un artefact — code de production, harnais de
test, script de contrôle, ou corpus documentaire — introduite **exprès** et dont on **exige** qu'un
instrument la **refuse**.

⚖️ **Le retournement est là, et c'est tout l'intérêt** : un test mesure le **produit** ; un mutant
mesure **l'instrument qui juge le produit**. On n'observe pas si le code est juste, on observe si
**quelque chose s'en apercevrait s'il devenait faux**. Un code juste que personne ne surveille est
**indistinguable** d'un code faux — et c'est exactement ce que ce dépôt a rencontré trois fois.

**Doctrine du projet** : *« un contrôle qui ne peut pas rougir est nul »*.

### 6.2 Les deux verdicts, et lequel est la trouvaille

| Verdict | Ce qu'on observe | Ce que cela veut dire |
|---|---|---|
| **TUÉ** | au moins un test ou un gate **rougit**, et on note **lequel** | l'assertion a un **pouvoir de refus**. C'est le **reçu**, pas la découverte |
| **SURVIVANT** | tout reste **vert** | 🔴 **c'est la trouvaille** : la propriété **n'est surveillée par personne**. Le défaut est **inobservable** |

⛔ **Un mutant survivant n'est pas l'échec de la campagne : c'est son seul résultat utile.** Une
campagne où tout meurt du premier coup n'apprend rien — sauf lorsqu'elle est rejouée **après** un
correctif, pour prouver que le trou est **refermé** (c'est ce qui a été fait sur `hub_page` à T4 :
mutant survivant, correctif, **même mutant rejoué**, test désormais rouge — *mesuré, pas supposé*).

### 6.3 Sept rôles, et ils ne se remplacent pas

| Rôle | On mute… | On exige | Exemple **réel** de ce dépôt |
|---|---|---|---|
| **① Mesurer la force des assertions** | `lib/` | la suite **rougit** | `M-5` : la grille filtre les retirées **elle-même** (second filtre) ⇒ 8 tuiles affichées mais création **refusée** |
| **② Prouver qu'un contrôle SAIT REFUSER** *(autotest)* | la **fixture** donnée au script | le **verdict change** | [`selftest_coverage_ratchet.py`](../../scripts/selftest_coverage_ratchet.py) : même fixture sous **deux** références ⇒ interdit au checker d'**écrire** sa valeur au lieu de la **lire** |
| **③ Vérifier qu'un contrôle regarde au BON ENDROIT** | le **contrôle** lui-même | montrer qu'il serait **vert sur le défaut** — ou **rouge sur le juste** | `M-20` : le contrôle `T-P4` écrit sur le nœud **sémantique** au lieu du détecteur **pointeur** ⇒ **un contrôle qui EXIGE le défaut** |
| **④ Éprouver un HARNAIS de test** | le harnais partagé | il échoue **bruyamment**, ⛔ jamais en silence | `M-18` / **NB-7** : `fondDeLaTuile` sélectionne par `.first` ⇒ la tuile rend **toujours orange** et **112 tests restent verts** |
| **⑤ Cartographier la PORTÉE d'un outil** *(mutant bidirectionnel)* | le **même** défaut, dans **deux** contextes | savoir **où l'outil est aveugle** | `M-7` : `unawaited_futures` rend `analyze` **rouge** dans une fonction `async` et ⛔ **ne voit rien** dans un appelant synchrone |
| **⑥ Savoir si deux instruments sont REDONDANTS** *(`--croise`)* | rien de neuf : on rejoue les mêmes mutants sur **l'autre** critère | comparer les **ensembles** tués | **4 mutants destructeurs** passent le critère d'US-01.2 avec **8 assertions sur 8 vertes**, et un 5ᵉ n'est vu **que par lui** ⇒ ⛔ **non redondants dans les deux sens, on garde les deux** |
| **⑦ Prouver qu'un gate LIT vraiment son corpus** *(mutation de corpus)* | le **corpus** : deux copies **à un fichier près** | le verdict **change** | US-00.5 : le verdict basculait de `ECHEC` à `OK` selon la présence du **rapport de la QA elle-même** ⇒ elle a **retiré son propre gate** au lieu de le réparer |

### 6.4 Mutant **joué** ou mutant **fixé** — la distinction qui décide de sa durée de vie

| | Mutant **joué** *(transitoire)* | Mutant **fixé** *(inscrit)* |
|---|---|---|
| Où il vit | nulle part : on l'écrit, on observe, on **restaure** | dans un test ou un critère **versionné**, comme fixture |
| Quand il rejoue | **jamais**, sauf si quelqu'un refait le geste | **à chaque `flutter test`** |
| Ce qu'il prouve | que l'assertion **jugeait ce jour-là** | que l'assertion **juge encore aujourd'hui** |
| Exemples | les 6 mutants d'US-01.1, les 9 de T5→T7 | la garde de T3 (**4 couples mutants exécutés** + 1 contrôle négatif) · [`rendu_couleur_test.dart`](../../test/support/rendu_couleur_test.dart) (T7), qui rend le **faux vert de NB-7 exécutable** au lieu de raconté |

➡️ **Le fixé est strictement meilleur, et c'est la direction du projet** : un mutant joué à la main
prouve un état, un mutant fixé **interdit** son retour. ⚠️ **Mais un mutant fixé n'est pas gratuit** :
il faut qu'il puisse **réellement** échouer — `M-18` n'est tuable **que si** la tuile testée porte
vraiment **deux** boîtes décorées.

### 6.5 Le protocole, et les quatre règles qui empêchent une campagne de mentir

1. **écrire** le mutant (une inversion, une clé retirée, une liste remplacée par sa voisine) ;
2. **lancer** la suite, **exiger le rouge**, et **noter QUEL** test rougit — *« la suite est rouge »*
   ne dit pas quelle assertion a mordu ;
3. **restaurer** ;
4. **vérifier** le vert **et** que `lib/` est intact (`git diff` vide).

| Règle | Sans elle |
|---|---|
| **Contrôle négatif** : la source mutée doit **différer** de la conforme | un mutant identique **ne mesure rien** — et le cas s'est produit |
| **Contrôle positif** apparié : montrer que l'assertion **peut** être vraie | *« la tuile est absente »* est vrai **sur un hub vide** ⇒ vérité par **vacuité** |
| Comparer des **ENSEMBLES**, ⛔ jamais des cardinaux | *« un décompte égal n'est pas une preuve d'équivalence »* |
| Mutants **jamais tirés du vocabulaire de la règle testée** | le contrôle ne mesure que lui-même |

### 6.6 Deux acquis qui inversent l'intuition, tous deux mesurés

* ⛔ **Les égalités « au token » sont TAUTOLOGIQUES** — les deux côtés bougent ensemble. **Seules les
  assertions de GRANDEUR tuent un mutant**, et ce sont justement celles qui **ont l'air de faire
  doublon**. ➡️ **Ne jamais les retirer à ce titre.**
* ⛔ **Un contrôle purement lexical est faux** *(7 fois sur 7)* ; **un contrôle portant son mutant est
  juste** *(7 fois sur 7)*. D'où la règle : **tout script de contrôle porte son autotest de mutation**.

### 6.7 Ce que les mutants ont réellement trouvé ici — et la dette

| Ce qu'un mutant a trouvé | Ce qu'aucun autre instrument n'avait vu |
|---|---|
| **6 trous** dans les assertions d'US-01.1 | la couverture est restée à **380/399 avant et après** |
| Le faux vert `LF:19 / LH:5` → **« 100 % »** proposé à la consigne | il aurait **verrouillé le dépôt** ; ⛔ **le mutant n'avait été écrit par personne** — c'est l'auditeur qui l'a fabriqué |
| La **portée partielle** d'`unawaited_futures` | le **premier mutant a SURVÉCU** : sans lui, le SCB portait une affirmation **fausse pour la moitié des cas** |
| Le câblage `presentes` du hub *(T4)* | **431 tests verts**, et ⛔ **la couverture ne le voyait pas non plus, la ligne ÉTANT couverte** |
| **9 mutants** joués à T5→T7, **9 tués** | dont *« deux appelants sur trois lisaient la mauvaise liste »* — **AC-6 faux par le bouton**, pas par la règle |

🔴 **La dette est ici, et elle est nommée** : **aucun gate ne mesure la mutation.** Toutes les
campagnes de ce projet ont été **écrites à la main** par un développeur ou un auditeur, et rien ne
signale qu'une US n'en a joué aucune. C'est le premier candidat du rituel `/audit-methodo` sur le
sujet des tests.

---

## 7. Les critères de sortie **exécutables**

**Règle du projet, née d'un échec** : *« un critère de sortie se publie comme un script exécutable,
jamais recopié à la main »*. Le motif est un incident réel — une commande de balayage **recopiée** dans
un rapport avait perdu un filtre, et le contrôle **blanchissait** le pire écart du corpus.

Ce qui existe (`reports/US-*/**.py`, **9 fichiers**) et ce que cela apporte :

| Convention | Effet |
|---|---|
| `exit 1` **en le disant** tant que la lacune est ouverte | un critère non levé est **visible**, pas oublié — ex. la garde de migration `v3` rendait `exit 1` **avant** T3 et `exit 0` après |
| `--selftest` | prouve que le critère **sait refuser** — chaque assertion doit être **tuée par au moins un mutant** |
| `--croise` | rejoue le critère d'**une autre US** sur les mêmes mutants, pour savoir si les deux instruments sont **redondants** |
| ⛔ le critère qui juge ne doit **pas** être touché par ce qu'il juge | contrôle : `git diff <base> HEAD -- reports/` doit rester **vide** |

🔬 **Résultat qui justifie de garder deux instruments plutôt qu'un** : la matrice `--croise` d'US-01.4
montre que **quatre mutants destructeurs** passent le critère d'US-01.2 avec **8 assertions sur 8
vertes** (sa graine ne porte aucune entrée retirée), tandis qu'un cinquième mutant n'est vu **que** par
ce dernier. ⇒ **les deux instruments ne sont pas redondants DANS LES DEUX SENS.**

---

## 8. Gherkin : trois statuts de scénario, et il faut les distinguer

```bash
ls tests/features/*.feature | wc -l                             # 10 fichiers
for f in tests/features/*.feature; do grep -c '^  Scénario: ' $f; done   # 207 scénarios au total
python scripts/check_gherkin_mapping.py                          # exit 0 — 13↔13, 50↔50
python scripts/check_gherkin_mapping.py --selftest               # 6 assertions, 2 couples sous contrôle
```

| Statut | Volume au 2026-09-08 | Ce que cela veut dire |
|---|---|---|
| **Exécuté et sous contrôle** | **63** — US-01.1 (13) + US-01.2 (50) | le couple `(feature, test)` est dans `COUPLES` : chaque scénario a un test qui **reprend son titre**, vérifié **dans les deux sens** |
| **Écrit, hors contrôle** | **41** — US-01.4 | le couple n'est **pas encore** dans `COUPLES` (tâche **T15, en dernier**) : ⛔ l'inscrire avant que le fichier de tests existe rendrait le job requis **rouge** |
| **Spécification NON EXÉCUTÉE** | **103** — les 7 `.feature` de gouvernance | ⛔ **ni step definition ni runner.** Ces scénarios sont un **document**, pas un test — et une DoD qui écrirait « N scénarios Gherkin » comme un livrable **porterait une ligne qui ressemble à un test** |

⛔ **Ce que le mapping n'atteste pas, et il l'imprime lui-même** : *« que le test ÉPROUVE réellement ce
que le scénario décrit : aucune machine ne lit l'intention. C'est un contrôle de CORRESPONDANCE DE
TITRES, pas de sémantique. »* D'où la règle : **titres lus dans le `.feature`**, ⛔ **jamais retapés.**

---

## 9. Les règles d'écriture des tests — chacune payée par un défaut réel

| Règle | Ce qui l'a établie |
|---|---|
| ⛔ **Ce qui doit être refusé doit d'abord pouvoir être SAISI** | `maxLength` tuait le refus du 81ᵉ caractère · un bouton désactivé à 9 tuait le refus de la 10ᵉ échéance · un formateur rendait `31/02/2027` **intapable**, donc le scénario **inobservable** |
| **Tout contrôle porte son CONTRÔLE NÉGATIF** | sans lui, une double boucle est vraie **par vacuité**, et *« la tuile est absente »* est vrai sur un hub vide |
| ⛔ **Jamais un nombre dérivé écrit à la main** | six tests ont dû être adaptés à T3 pour cette seule cause ; `etapesMigration.single` n'était vrai **que par accident** |
| **Désigner par la CLÉ, jamais par le type ni la position** | NB-7 : deux `DecoratedBox` imbriquées, l'assertion lisait la mauvaise ⇒ la tuile rendait **toujours** orange et **112 tests restaient verts** |
| ⛔ **Jamais désigner une assertion par son NUMÉRO DE LIGNE** | il glisse en silence et la couverture cesse de couvrir sans qu'aucun outil ne le signale |
| **Comparer des ENSEMBLES, pas des cardinaux** | un décompte égal n'est pas une preuve d'équivalence |
| **Une valeur fausse se RETIRE, jamais ne se « met à jour »** | une valeur mise à jour périme au cycle suivant |
| ⛔ **Un `skipped` n'est pas un vert** | [Constitution Art. 3](../governance/CONSTITUTION.md) : le rapport QA doit dire **passed/skipped/failed**, jamais « PASS » seul |
| **Une clause sans surface / une surface sans clause** | US-01.2 : 4 trous que **ni l'une ni l'autre** des branches de design ne portait · US-01.4 : le câblage juste dont **aucun test ne verrait la régression** |

---

## 10. Les commandes, en un endroit

```bash
flutter pub get
flutter analyze
flutter test                                    # rapide, sans couverture
flutter test --coverage                         # produit coverage/lcov.info
python scripts/check_flutter_coverage.py --min <plancher>   # verdict couverture (seuil = max(plancher, cliquet))
python scripts/run_gates.py --all               # tous les gates de tous les composants
python scripts/run_gates.py --component app     # ce que fait le job CI app-quality
python scripts/check_gherkin_mapping.py         # correspondance scénarios ↔ tests
python scripts/check_gherkin_mapping.py --selftest
python scripts/check_e2e_persistance.py         # ADR-010 §1 : racine montée, aucun magasin factice
python scripts/selftest_coverage_ratchet.py     # prouve que le checker de couverture sait REFUSER
```

⛔ **Jamais `--no-verify`.** ⛔ Jamais de commit ni de push sur la branche principale.

---

## 11. Où vit chaque valeur — l'exemplaire unique

| Valeur | Son unique exemplaire | ⛔ Ne jamais |
|---|---|---|
| Plancher de couverture | `factory.config.json` → `…app.gates.test.cmd` (`--min`) | l'écrire dans un script |
| **Cliquet** | `factory.config.json` → `…app.coverage_ratchet` | le recopier — il se **lit** |
| Commandes de gates | `factory.config.json` → `…app.gates` | les dupliquer dans un workflow |
| Noms des contextes requis | `factory.config.json` → `status_checks` | renommer un job sans resynchroniser (`factory_sync.py --check`) |
| Normes de code et de test | [`STACK_PROFILE.md`](../governance/STACK_PROFILE.md) §Developer | réinventer une convention par US |
| Règles d'enforcement | [`CONSTITUTION.md`](../governance/CONSTITUTION.md) | les résumer en les déformant |
| Couples `(feature, test)` | `scripts/check_gherkin_mapping.py` → `COUPLES` | annoncer un décompte de scénarios à la main |

---

## 12. Bornes et dettes ouvertes de l'instrumentation — l'honnêteté fait partie du dispositif

**Ce que l'outillage de test NE couvre pas aujourd'hui** :

* 🔴 **Aucune mesure de mutation outillée** — le seul instrument qui juge la force des assertions est
  **manuel** (§6).
* 🔴 **Aucun SAST applicatif** : `run_gates --gate sast` rend **exit 1, ce gate n'existe pas**. Et
  `dart pub outdated` mesure l'**obsolescence**, ⛔ **pas la vulnérabilité** — **aucun scan de CVE**.
* 🔴 **Aucune couverture de branches**, et un **dénominateur amputé** de tout fichier non importé (§3.3).
* 🟠 **La DoD générique n'exige la couverture d'AUCUN AC** : ses 10 cases sont intégralement cochables
  avec la moitié des AC orphelins. Sur US-01.1, ce qui a rattrapé RNF-02, **c'est la QA, pas la DoD**.
* 🟠 **`/certify` gate 3 vérifie une PRÉSENCE DE FICHIER, pas un VERDICT** — il serait **vert** sur une
  US dont tous les audits ont échoué.
* 🟠 **Un visa d'audit n'est rattachable à aucun commit** (NB-6) : `trace_append.py` n'a **aucune**
  option `--commit`, donc **aucune machine ne peut signaler qu'un visa est périmé**.

**Trois écarts mesurés le 2026-08-25 en écrivant ce document — signalés, ⛔ non corrigés ici**
*(corriger un renvoi n'est pas corriger le défaut, et deux d'entre eux demandent un arbitrage)*.
⚠️ **REVÉRIFIÉS UN PAR UN LE 2026-09-08 : les trois TIENNENT** — ⛔ aucun ne s'est refermé tout
seul, et le nº 3 est désormais **daté à la source** *(voir son entrée)*, ce qui ⛔ **ne l'enrichit
pas** :

1. 🔴 [`STACK_PROFILE.md`](../governance/STACK_PROFILE.md) §Developer affirme *« pour l'instant
   `test/widget_test.dart` teste `lib/main.dart` »*. **Mesuré** : `test/widget_test.dart` est
   **ABSENT**, et `grep -rn "main.dart" test/` est **vide** — **personne ne teste `main.dart`**, ce qui
   est exactement pourquoi ses 31 lignes sont hors dénominateur.
2. 🔴 [`magasin_temporaire.dart:11`](../../test/support/magasin_temporaire.dart#L11) affirme que
   `magasin_temporaire_test.dart` *« vérifie que ce harnais échoue si on le fait mentir »*. **Ce fichier
   n'existe pas.** Coûteux ici, puisque le harnais **se réclame de porter son mutant**.
3. ✅ **DATÉ-2026-09-08 — le seul des trois qui a bougé, et par DATATION, pas par correction.**
   [`E2E_RUNBOOK.md`](E2E_RUNBOOK.md) disait du smoke E2E qu'il *« n'exerce aucun parcours
   utilisateur réel »* et qu'il était *« à enrichir dès que l'écran principal existe »*. **Vrai à sa
   date** — mais `test/e2e/` porte depuis deux tests qui montent `ConcentrationApp` sur un **disque
   réel**, et ADR-008 a **arbitré** ce choix. *On date, on ne repeint pas* : la phrase est
   **conservée** et marquée **`PÉRIMÉ-2026-09-08` en LITTÉRAL** — ⛔ jamais barrée, *un texte barré
   est invisible à `grep`*. ⚠️ **Ce qui reste VRAI après datation** : le smoke de
   [`e2e.yml`](../../.github/workflows/e2e.yml) **rejoue les gates**, et ce n'est toujours ⛔ **pas**
   un parcours utilisateur supplémentaire.

**Ce qu'aucun de ces instruments n'a jamais attesté, et qu'il faut cesser de sur-lire** :
l'application **n'a tourné sur un appareil réel qu'une seule fois** (SM T580, 2026-08-21, un fait de
**machine** et non un livrable de la factory) · **aucun contraste n'a jamais été vu par un œil**, tous
sont **calculés** · **RNF-02 (« < 500 ms ») n'est pas couvert** ; son critère de levée est livré et
exécutable.

---

*Document de référence de la **documentation projet** — il décrit l'existant. Toute règle qu'il
énonce vit ailleurs en un seul exemplaire (§11) ; s'il le contredit, **c'est lui qui a tort**.*

*Il est cité par [`E2E_RUNBOOK.md`](E2E_RUNBOOK.md), par
[`STACK_PROFILE.md`](../governance/STACK_PROFILE.md) §Developer et par le `CLAUDE.md` §Stack.
⛔ **Un document que rien ne cite n'est pas de la documentation** — celui-ci l'a été du 2026-08-25
au 2026-09-08 : écrit, non versionné, référencé par aucun fichier du dépôt.*
