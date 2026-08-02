# Audit de revue de code — US-01.1 — **DELTA 2, 3ᵉ passage**

> ⛔ Ce fichier **complète** [`code_review.md`](code_review.md) *(1ᵉʳ passage, `24fe59a`, **FAILED**)* et
> [`code_review_delta.md`](code_review_delta.md) *(2ᵉ passage, `6fe75df`, **PASSED**)*. Il ne les
> remplace pas et n'en corrige aucune ligne : **on date, on ne repeint pas.**

| Champ | Valeur |
|---|---|
| **SHA AUDITÉ** | **`173fb62348c5ca516505067c1ea29c97fa06b8a8`** (**`173fb62`**) |
| **Agent** | @CodeReviewer — **contexte frais**, sans accès à la conversation ayant produit le code |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 (3ᵉ passage) |
| **Branche** | `feat/US-01.1-dev-presentation` — arbre propre au début de l'audit |
| **Delta examiné** | `git diff 6fe75df..173fb62` — **4 commits**, lus dans la sortie de `git log` et **non** dans l'énumération qui m'a été transmise : `be9cc4a`, `ade583e`, `ddf839e`, `173fb62` *(voir §1 et **P-10**)* |
| **Story File** | `docs/stories/US-01.1-affichage-hub-grille.md` · `.feature` normatif : `tests/features/US-01.1-affichage-hub-grille.feature` |
| **Contexte de saisine** | Le 2ᵉ passage a laissé **N-3 en consultatif** ; la QA a rendu **`🧪 FAIL`** sur le **même** `6fe75df`, **tous gates verts**, avec **6 mutants survivants sur 8** — dont **QA-M3 = mon mutant M2 = N-3**. |

---

## ✅ VERDICT : **PASSED**

**0 bloquant.**

Le delta est **à 100 % du test**. `lib/` est **bit-à-bit identique** : je l'ai mesuré, je ne l'ai pas cru.
Les **7 mutants** du critère de sortie de la QA sont **tués** ; **9 mutants supplémentaires que je n'avais
publiés nulle part** — dont un **contrôle positif** et un **contrôle négatif** — rendent **tous** le verdict
attendu. Aucune assertion existante n'a été **desserrée** ; **aucun nom de test n'a été retiré** *(comparaison
en **ensembles**)*. Les **deux corrections de données de test** vont bien **du test vers le `.feature`**, et
**aucun `.feature` n'a été touché**.

⚠️ **Ce `PASSED` est celui de la REVUE, et il ne préjuge pas de la QA.** **AC-1 « Limite » (RNF-02)**
demeure un **AC orphelin** — c'est mon **N-11**, que j'ai classé **non bloquant aux 1ᵉʳ et 2ᵉ passages** et
que je **ne requalifie pas**. L'arbitrer relève du critère de rôle de @QA_Tester, pas du mien.

---

## 1. Périmètre du delta — mesuré

⚠️ **Le périmètre m'a été annoncé à TROIS commits. Il en compte QUATRE.** Je ne fonde rien sur
l'énumération reçue : **la sortie fait foi.**

```
$ git rev-list --count 6fe75df..173fb62
4
$ git log --oneline 6fe75df..173fb62
173fb62 docs(us-01.1): les 2 visas d audit sont PERIMES — colonnes remises a l attente
ddf839e chore(us-01.1): EVT_CODE_READY sur ade583e — les 6 mutants sont tues
ade583e test(us-01.1): les 6 mutants de la QA sont TUES, sans toucher une ligne de lib/
be9cc4a test(us-01.1): la QA REFUSE alors que TOUS LES GATES sont verts
```

⛔ **Le commit omis, `be9cc4a`, est le SEUL de la plage à apporter du code exécutable** : il introduit
`reports/US-01.1/qa_exit_criterion.py` — **314 lignes de Python**, c'est-à-dire **l'instrument même** que
ce passage doit rejouer. Il entre donc dans mon périmètre **deux fois** : comme instrument *(§2.3)* **et
comme code livré** *(§9 bis)*. Voir **P-10** pour le finding de méthode.

```
$ git diff --name-status 6fe75df..173fb62
M	CLAUDE.md
M	PROJECT_LOG.md
M	STORY_CERTIFICATION_BOARD.md
M	docs/trace/US-01.1/events.jsonl
A	reports/US-01.1/code_review_delta.md
A	reports/US-01.1/qa.md
A	reports/US-01.1/qa_exit_criterion.py
A	reports/US-01.1/security_delta.md
A	test/core/theme/concentration_theme_test.dart
M	test/e2e/hub_echeances_test.dart
M	test/features/echeances/presentation/echeances_grid_test.dart
A	test/features/echeances/presentation/widgets/echeance_tile_test.dart
A	test/features/hub/presentation/hub_page_test.dart
A	test/support/rendu_couleur.dart
```

```
$ git diff --numstat 6fe75df..173fb62 -- lib/ | wc -l
0
$ git diff --name-status 6fe75df..173fb62 -- scripts/
$ git diff --name-status 6fe75df..173fb62 -- pubspec.yaml pubspec.lock analysis_options.yaml factory.config.json
$ git diff --name-status 6fe75df..173fb62 -- '*.feature'
$ git diff --stat ddf839e..173fb62 -- lib/ test/
```
*(les quatre dernières commandes rendent une sortie **vide**)*

➡️ **Aucune ligne de production, aucun script d'outillage, aucune dépendance, aucun `.feature`, aucun
fichier d'enforcement.** Le commit `173fb62` ne touche **ni `lib/` ni `test/`** : il n'agit que sur le SCB
et le PROJECT_LOG.

---

## 2. Les trois affirmations — **MESURÉES, aucune crue**

### 2.1 Affirmation 1 — « `lib/` est intact » → ✅ **VRAIE**

`git diff --numstat 6fe75df..173fb62 -- lib/` rend **0 ligne**. Il ne s'agit pas d'un diff « sans
changement notable » : c'est un diff **vide**.

📌 **Conséquence portante, et c'est elle qui structure tout ce rapport** : **tout finding dont le lieu est
dans `lib/` est INCHANGÉ PAR CONSTRUCTION**, ni résolu ni aggravé. Cela vaut pour **N-1, N-2, N-6, N-7,
N-9, N-10, N-12 et O-1**. Je n'ai donc pas à les « re-vérifier » un à un : le diff vide **est** la preuve.
*(Je les ai malgré tout re-grepés — §10 — parce qu'un raisonnement juste sur une prémisse fausse reste
faux.)*

### 2.2 Affirmation 2 — « `qa_exit_criterion.py` n'a pas été modifié » → ✅ **VRAIE**

Le modifier aurait été **adapter la règle au résultat**. Vérifié par **identité de contenu**, pas par
absence de diff *(un diff vide peut aussi vouloir dire qu'on regarde le mauvais chemin)* :

```
$ git log --oneline --follow -- reports/US-01.1/qa_exit_criterion.py
be9cc4a test(us-01.1): la QA REFUSE alors que TOUS LES GATES sont verts

$ git rev-parse be9cc4a:reports/US-01.1/qa_exit_criterion.py
e29d75d938d4aed31800c471e9ce308f8aa4e0f1
$ git rev-parse 173fb62:reports/US-01.1/qa_exit_criterion.py
e29d75d938d4aed31800c471e9ce308f8aa4e0f1
$ git hash-object reports/US-01.1/qa_exit_criterion.py
e29d75d938d4aed31800c471e9ce308f8aa4e0f1
```

**Un seul commit dans son historique — celui de la QA** — et **le même blob** au commit d'origine, au
commit audité **et sur le disque**. L'instrument qui juge n'a pas été touché par le jugé.

### 2.3 Affirmation 3 — « les 7 mutants sont tués » → ✅ **VRAIE**, rejouée moi-même

```
########## qa_exit_criterion.py --selftest ##########
[OK] 0 rouge(s) correctement extrait(s)
[OK] 1 rouge(s) correctement extrait(s)
[OK] 2 rouge(s) correctement extrait(s)
[OK] un motif absent est bien detectable
[OK] les 7 motifs de mutation existent dans le depot
[OK] le controle positif QA-M6 est present

Autotest : 0 echec(s).
EXIT_QA_SELFTEST=0

########## qa_exit_criterion.py (campagne) ##########
Baseline : 112 test(s) verts.

QA-M1   TUE     (attendu TUE) [OK] | 3 rouge(s)
QA-M2b  TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M3   TUE     (attendu TUE) [OK] | 1 rouge(s)
QA-M4   TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M5   TUE     (attendu TUE) [OK] | 3 rouge(s)
QA-M7   TUE     (attendu TUE) [OK] | 2 rouge(s)
QA-M6   TUE     (attendu TUE) [OK] | 4 rouge(s)

CRITERE DE SORTIE ATTEINT -- tous les mutants sont TUES.
EXIT_QA_CAMPAGNE=0
```

**Attendu : exit 0. Obtenu : exit 0.** *(Il rendait `exit 1` / 6 survivants sur `6fe75df`.)*

#### ⚠️ Sur « l'asymétrie QA-M1/QA-M6 a disparu » — **je nuance, en comparant des ENSEMBLES**

L'affirmation qui m'est faite parle de **« 3 rouges / 4 rouges »**. C'est exact, mais le chiffre n'est pas
l'argument. Les **ensembles** de tests rouges le sont :

| Mutant | Ensemble des tests rouges (lu dans la sortie) |
|---|---|
| **QA-M1** *(toujours orange)* | `{ chaque progression rend le dégradé À CE POINT, la clarté DÉCROÎT strictement quand p augmente, Couleur bleue quand le prochain changement est imminent }` |
| **QA-M6** *(toujours bleu)* | les **trois mêmes**, **plus** `{ Couleur orange quand le nombre vient de changer }` |

➡️ **L'asymétrie qui comptait — celle du VERDICT (survivant contre tué) — a bel et bien disparu.** L'écart
résiduel de cardinal est **structurellement nécessaire** : l'ensemble de QA-M1 est **inclus** dans celui de
QA-M6, et l'élément supplémentaire est **exactement** le test de `p = 0`, qu'un mutant « toujours orange »
**ne peut pas** faire rougir puisqu'il rend la bonne couleur en ce point. ⛔ **Ce n'est pas un trou
résiduel ; ce serait une erreur de le lire comme tel.**

---

## 3. Gates statiques — sorties collées

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 32 files (0 changed) in 0.38 seconds.
✅ app.format
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 9.0s)
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:22 +112: All tests passed!
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 89.4%, consigné le 2026-07-31
  [HAUSSE] 95.24% (380/399) > cliquet 89.4%. Valeur a consigner (arrondie VERS LE BAS) : 95.2
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
✅ app.test
▶ app.deps_audit ✅   ▶ app.build → √ Built build\web ✅
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
EXIT_RUN_GATES_ALL=0
```

**lint (`format`) et typecheck (`analyze`) : aucune erreur sur le code de l'US.** *(`run_gates --gate lint`
et `--gate typecheck` n'existent pas sous ces noms dans cet adapter ; les gates correspondants sont
`app.format` et `app.analyze`, exécutés ci-dessus par `--all`.)*

✅ **Ma mesure coïncide avec celle de @Architect** *(112 tests, 95,2 %, 380/399)* — **aucune divergence à
signaler**.

```
########## check_gherkin_mapping.py ##########
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
OK : chaque scenario a son test et chaque test son scenario. Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
EXIT_GHERKIN=0
Autotest : 6 assertions, 0 echec(s), 1 couple(s) sous controle.
EXIT_GHERKIN_SELFTEST=0
```

### « Aucun `testWidgets` ajouté aux 13 scénarios e2e » → ✅ **VRAIE**

```
$ git show 6fe75df:test/e2e/hub_echeances_test.dart | grep -c "testWidgets("   -> 13
$ git show 173fb62:test/e2e/hub_echeances_test.dart | grep -c "testWidgets("   -> 13
$ diff <(titres testWidgets @6fe75df) <(titres testWidgets @173fb62)           -> vide
```

Et **N-4 (résolu au 2ᵉ passage) tient toujours** : `13` appels à `lancerApp`/`lancerAvec`, **2** sites
`pumpWidget` montant tous deux `ConcentrationApp`, et l'unique occurrence de `MaterialApp` dans le fichier
e2e est **dans un commentaire**. La contrepartie d'**ADR-008 §1** reste tenue.

---

## 4. Mutants **NON PUBLIÉS** — 9 de plus, dont 2 contrôles

C'est la partie de mon 2ᵉ passage qui a le plus payé, et le motif est inchangé : **une condition connue à
l'avance ne prouve pas grand-chose.** Le développeur connaissait les 7 motifs de la QA avant d'écrire son
correctif ; les faire passer prouve donc quelque chose de **faible**.

**Stratégie** : la QA a muté par **suppression** ou par valeur **grossière** *(constante, blanc, 1 heure)*.
Un test peut tuer un mutant grossier et rester décoratif. Mes mutants **dégradent sans supprimer**.

Le script est publié — **il ne l'était pas avant son exécution** :
[`code_review_delta2_mutants.py`](code_review_delta2_mutants.py) *(autotest : `--selftest` → **exit 0**, 8
contrôles, comparaison en ensembles, mutant inerte détecté, motif désigné par son **texte** et jamais par un
numéro de ligne, motif introuvable = **échec**)*.

```
Baseline : 112 test(s) verts.

X-0   TUE     (attendu TUE    ) [OK] | 12 rouge(s)
X-1   TUE     (attendu TUE    ) [OK] | 2 rouge(s)
X-2   TUE     (attendu TUE    ) [OK] | 2 rouge(s)
X-3   TUE     (attendu TUE    ) [OK] | 1 rouge(s)
X-4   TUE     (attendu TUE    ) [OK] | 1 rouge(s)
X-5   TUE     (attendu TUE    ) [OK] | 2 rouge(s)
X-6   TUE     (attendu TUE    ) [OK] | 1 rouge(s)
X-7   TUE     (attendu TUE    ) [OK] | 2 rouge(s)
X-8   SURVIT  (attendu SURVIT ) [OK] | 0 rouge(s)

CAMPAGNE CONCLUANTE -- chaque mutant a rendu le verdict attendu.
EXIT_CAMPAGNE_X=0
```

| # | Mutation (copie isolée) | Version subtile de | Attendu | Obtenu — **test(s) qui rougissent** |
|---|---|---|---|---|
| **X-0** | `'${temps.nombreAffiche}'` → `'${temps.nombreAffiche + 1}'` | **CONTRÔLE POSITIF**, comportemental | TUÉ | ✅ **TUÉ** — 12 rouges. Le harnais détecte réellement. |
| **X-1** | `backgroundFor(temps.progression)` → `backgroundFor(temps.progression * 0.5)` — dégradé **comprimé**, pas figé | QA-M1 | TUÉ | ✅ **TUÉ** — `chaque progression rend le dégradé À CE POINT` · `Couleur bleue…` |
| **X-2** | la description rendue est **toujours la même** (`'Passeport'`, un libellé qui **existe** dans le jeu) | QA-M4 | TUÉ | ✅ **TUÉ** — `la tuile PORTE la description…` · `Affichage d'une tuile par échéance active` |
| **X-3** | `if (description.isNotEmpty)` → `if (description.length > 12)` — rendue **pour certaines** échéances | QA-M4 | TUÉ | ✅ **TUÉ** — `Affichage d'une tuile par échéance active` |
| **X-4** | `fit: BoxFit.scaleDown` → `BoxFit.none` — le `FittedBox` **reste**, seul son comportement change | QA-M3 / **N-3** | TUÉ | ✅ **TUÉ** — `un nombre trop large est MIS À L'ÉCHELLE, jamais rogné` |
| **X-5** | `fondApp` ↔ `texteSurFond` **échangés** — mode **clair à contraste CONSTANT** | QA-M2b | TUÉ | ✅ **TUÉ** — `« sombre » est une GRANDEUR mesurée, pas un nom` |
| **X-6** | `moduleGrise` → `#FFFFFF` : grisé **différent** de l'actif mais **ressortant davantage** | QA-M5 | TUÉ | ✅ **TUÉ** — `« grisé » est une GRANDEUR : moins de contraste que le module actif` |
| **X-7** | `periodeRafraichissement` → **61 s**, soit **une seconde** au-delà du budget | QA-M7 | TUÉ | ✅ **TUÉ** — les **deux** assertions RF-05 |
| **X-8** | rayon d'arrondi de la tuile `16` → `4` | **CONTRÔLE NÉGATIF** | **SURVIT** | ✅ **SURVIT** — 0 rouge |

### 4.1 Pourquoi X-8 (contrôle **négatif**) était nécessaire

Le corpus impose un contrôle **positif** *(sans lui, « tout survit » peut vouloir dire « harnais cassé »)*.
J'ajoute le **symétrique**, que la campagne de la QA n'avait pas : une suite qui rougirait sur **n'importe
quelle** modification serait **sur-ajustée au rendu courant**, et la mort des huit autres mutants cesserait
d'être informative — elle ne dirait plus « ce comportement est protégé » mais « ce fichier est gelé ».
X-8 touche le **même fichier** que X-0 *(vérifié par l'autotest, pour qu'« il survit » ne puisse pas
s'expliquer par un fichier non compilé)* et porte sur une propriété qu'**aucun AC ni aucune étape Gherkin
d'US-01.1 ne spécifie**. **Il survit. Le filet est serré là où il doit l'être, et lâche ailleurs.**

### 4.2 Les deux résultats qui m'importent le plus

⛔ **X-5 et X-6 démontrent QUELLES assertions portent réellement.** Dans les deux cas, l'assertion
d'**égalité au token** — `theme.scaffoldBackgroundColor == fondApp.couleur`,
`couleurGrisée == moduleGrise.couleur` — reste **VRAIE sous la mutation**, parce que **les deux côtés de
l'égalité bougent ensemble**. Ce n'est pas un défaut : elle protège le **câblage**. Mais elle ne voit
**rien** d'une dérive du token lui-même. Ce sont les **assertions de GRANDEUR** — *« le fond est plus sombre
que son texte »*, *« le grisé ressort MOINS que l'actif »* — qui tuent, **et elles seules**.

📌 **Conséquence à inscrire** : ces deux assertions ont l'air de « faire doublon » avec les égalités. **Les
retirer un jour à ce titre rouvrirait QA-M2b et QA-M5 en silence.** Voir **P-2**.

✅ **X-4 tranche N-3 au-delà de ce que la QA demandait.** Son critère exigeait que le **retrait** du
`FittedBox` rougisse. L'assertion livrée fait mieux : elle porte sur le **comportement** *(le nombre est
posé à la largeur qu'il **demande**, puis le résultat **peint** tient dans la tuile)*, donc elle attrape
aussi une **dégradation** du `fit` à widget inchangé. Et elle porte un **garde-fou** — le test refuse de
conclure si le cas cesse d'être un vrai débordement — qui l'empêche de **cesser de contrôler en silence**.

---

## 5. ⛔ Chasse à l'AFFAIBLISSEMENT — la façon la plus discrète de faire passer un mutant

C'était le risque principal : **desserrer une assertion existante pendant qu'on en ajoute de nouvelles**.
Le décompte global monte *(102 → 112)*, et la suppression passe inaperçue.

### 5.1 Aucun nom de test retiré — comparaison en **ensembles**, pas en cardinaux

```
fichiers de test  6fe75df : 8
fichiers de test  173fb62 : 11

RETIRES (0) -- tout element ici est un AFFAIBLISSEMENT :
   (aucun)

AJOUTES (13) : [4 dans concentration_theme_test] [2 dans echeances_grid_test]
               [5 dans echeance_tile_test] [2 dans hub_page_test]

VERDICT ENSEMBLISTE : aucun nom de test retire
```
*(13 = tests **et** `group`, extraits par le même motif.)*

### 5.2 Aucun test neutralisé

```
$ grep -rn "skip:\|skip :\|@Skip\|@Tags\|solo:\|timeout:" test/
(sortie vide)
```

### 5.3 Les **quatre** assertions supprimées, examinées une par une

`git diff 6fe75df..173fb62 -- test/ | grep "^-"` ne contient que **quatre** `expect` retirés. Aucun n'est un
desserrage :

| Assertion retirée | Remplacée par | Verdict |
|---|---|---|
| `expect(scaffold.backgroundColor ?? ConcentrationTokens.fondApp.couleur, isNotNull)` | égalité au thème effectif **+** `brightness == dark` **+** couleur du `Material` **réellement peint** | ✅ **RENFORCEMENT.** L'ancienne était **tautologique** : le `??` retombait sur une constante jamais nulle. ⛔ Une assertion tautologique ne se **renforce** pas, elle se **remplace** — la retirer est le seul traitement correct. |
| `expect(find.byType(EcheanceTile), findsNWidgets(3))` | `findsNWidgets(jeu.length)` sur une table de **4** entrées | ✅ **NEUTRE en force, CORRIGÉ en donnée** (§6). Le décompte est désormais **lu dans la table** au lieu d'être écrit à la main — le remède exact du corpus. |
| `expect(couleur, ConcentrationTokens.gradientOrange.couleur)` *(scénario 6)* | `expect(fondDeLaTuile(tester), …gradientOrange.couleur)` **+** `expect(find.text('6'), findsOneWidget)` | ✅ **ÉQUIVALENT + AJOUT.** Même matcher, même cible ; la recherche du `DecoratedBox` est simplement factorisée dans le helper. |
| `expect((l − versBleu.l).abs() < (l − versOrange.l).abs(), isTrue)` où `l` venait de `backgroundFor(0.98)` | même comparaison en `lessThan(…)`, mais `l = clarteDe(couleur RENDUE)`, **plus** égalité exacte à `backgroundFor(pAttendu)` | ✅ **RENFORCEMENT MAJEUR.** L'ancienne mesurait une valeur **recalculée à côté** — elle ne regardait **jamais** la tuile. C'est précisément ce qui laissait QA-M1 survivre. |

⛔ **Un seul point mérite d'être nommé plutôt que tu** : `expect((l−bleu).abs() < (l−orange).abs(), isTrue)`
et `expect((l−bleu).abs(), lessThan((l−orange).abs()))` sont **logiquement équivalents** ; le second n'est
pas plus fort, il **rapporte mieux** en cas d'échec. Je ne le compte donc **pas** comme un renforcement — le
renforcement vient de **l'origine de `l`**, pas du matcher.

### 5.4 Rien n'a été desserré ailleurs

`ConcentrationTokens.contrasteMinTexteNormal` *(4,5)* reste le seuil de **toutes** les assertions de
contraste — aucune n'est passée au seuil plus permissif `contrasteMinTexteLarge` *(3,0)*, qui demeure
**inutilisé** *(= N-10, ci-dessous)*. Aucune tolérance numérique n'a été élargie : les seuls `closeTo` du
delta sont **neufs** *(`closeTo(naturelle, 0.5)`)* et **serrés sur la mesure**.

**➡️ Aucun affaiblissement détecté.**

---

## 6. Les **deux corrections de données de test** — triche ou alignement ?

C'est la question la plus légitime du mandat : **corriger la donnée d'un test qui échoue est le geste
tricheur type**. Je l'ai tranchée en dérivant les valeurs **de la spécification**, pas en relisant la
justification du développeur.

### 6.0 Préalable — le `.feature` normatif n'a pas bougé

```
$ git rev-parse 6fe75df:tests/features/US-01.1-affichage-hub-grille.feature
8e69c4bd0814171b4bfad63c362a47850421f79c
$ git rev-parse 173fb62:tests/features/US-01.1-affichage-hub-grille.feature
8e69c4bd0814171b4bfad63c362a47850421f79c
```
**Même blob.** ✅ La référence n'a pas été déplacée pour accueillir le résultat.

### 6.1 Scénario 3 — « 4 échéances » / « exactement 4 tuiles » → ✅ **ALIGNEMENT, pas triche**

Le `.feature`, **verbatim** :
```gherkin
  Scénario: Affichage d'une tuile par échéance active
    Étant donné que 4 échéances actives sont injectées
    ...
    Alors exactement 4 tuiles sont affichées
    Et chaque tuile porte la description de son échéance
```
Le test en injectait **3**. Il en injecte désormais **4**, et l'étape « chaque tuile porte la description »
est assertionnée **par clé de tuile**.

⛔ **Décisif, et c'est un fait vérifiable dans un document antérieur** : cette divergence est **littéralement
mon finding N-5 du 1ᵉʳ passage** — *« Également : “4 échéances… exactement 4 tuiles” testé avec **3** ;
l'étape “chaque tuile porte la description de son échéance” n'est pas assertionnée »*, avec pour solution
recommandée *« Aligner les données des tests sur celles des scénarios »*. **Le correctif fait exactement ce
que la revue demandait avant que la QA n'échoue.** Une donnée déplacée **vers** la norme, sur la foi d'un
document qui la réclamait **la veille**, n'est pas une triche.

**Et il a une valeur de détection mesurée** : mon mutant **X-3** *(description rendue seulement pour les
libellés longs)* est tué par **ce test et lui seul**. Une assertion sur **une** tuile bien choisie l'aurait
laissé passer.

### 6.2 Scénario 7 — « 5 h 59 » → « 5 h 1 » → ✅ **ALIGNEMENT, et l'ancienne donnée CONTREDISAIT le scénario**

Le `.feature`, **verbatim** :
```gherkin
  Scénario: Couleur bleue quand le prochain changement est imminent
    Étant donné qu'une échéance est proche de son prochain changement de nombre
    ...
    Alors la couleur de fond de la tuile est bleue
```

**Dérivation, faite depuis la spécification** *(ADR-002 §4 : `tPrecedent = cible − n unités`,
`tSuivant = cible − (n−1) unités`, `p = écoulé / total`)*, et **confrontée ensuite** au code
(`_progression` dans `remaining_time_calculator.dart`, qui applique bien cette règle) :

| Donnée | Nombre affiché | `tPrecedent` | `tSuivant` | Écoulé / total | **p** | Couleur |
|---|---|---|---|---|---|---|
| **5 h 59** *(ancienne)* | 6 | `maintenant − 1 min` | `maintenant + 59 min` | 1 / 60 | **1/60 ≈ 0,017** | ⛔ **ORANGE** |
| **5 h 1** *(nouvelle)* | 6 | `maintenant − 59 min` | `maintenant + 1 min` | 59 / 60 | **59/60 ≈ 0,983** | ✅ **BLEUE** |

⛔ **L'ancienne donnée contredisait la PRÉMISSE du scénario.** À 5 h 59, le nombre affiché « 6 » vient de
prendre sa valeur ; le prochain changement est à **59 minutes**, soit le plus **LOIN** possible. Le test
s'intitulait *« changement imminent »* et décrivait le cas **exactement inverse**.

⛔ **Et c'est ce qui masquait le trou.** Le test ne regardait **jamais** la couleur rendue : il lisait
l'alpha, puis comparait une clarté **recalculée à côté** par `backgroundFor(0.98)`. Une donnée fausse
**plus** une assertion qui n'observe pas la cible ⇒ vert quoi qu'il arrive. C'est la conjonction, pas la
donnée seule.

📌 **Le `pAttendu = (60 − 1) / 60` est dérivé de la spécification, pas obtenu en appelant le calculateur** —
c'est ce qui empêche l'assertion d'être auto-référentielle. **Preuve que l'assertion mord sur l'entrée** :
mon mutant **X-1**, qui laisse la tuile suivre la progression mais la **comprime**, fait rougir ce test.

**➡️ Je CONFIRME les deux affirmations : les deux corrections alignent le test sur le `.feature`
normatif, et aucun `.feature` n'a été modifié.**

---

## 7. N-11 / RNF-02 (« < 500 ms ») — **aucun vert fabriqué**

C'était le contrôle que je devais faire, et il est **négatif au sens où il devait l'être** :

```
$ grep -rniE "500 ?ms|Stopwatch|elapsedMicro|elapsedMilli|RNF-02|RNF02|performance|budget.*ms" test/ lib/
(sortie vide)

$ ls test/zz_qa_perf_probe_test.dart
No such file or directory

$ git diff --name-status 6fe75df..173fb62 -- docs/
M	docs/trace/US-01.1/events.jsonl        # le Story File n'est PAS modifié
```

✅ **Aucune assertion de temps n'a été introduite** · **la sonde temporaire de la QA n'a pas été laissée
dans le dépôt** · **aucune case du Story File n'a été cochée** *(le fichier n'est pas dans le delta)*.

⛔ **AC-1 « Limite » demeure un AC ORPHELIN.** Le développeur le dit dans son entrée de PROJECT_LOG
*(« RNF-02 reste NON VÉRIFIÉ […] fabriquer un vert dessus aurait été le contraire du travail demandé »)*, et
**la mesure confirme la déclaration** au lieu de s'y fier. **N-11 reste OUVERT, et c'est le bon état.**

---

## 8. Couverture — **recomptée**, pas reprise

Réagrégation indépendante des enregistrements `DA:` de `coverage/lcov.info` :

```
TOTAL lignes instrumentees : 399
TOTAL couvertes            : 380
TOTAL NON couvertes        : 19
POURCENTAGE RECOMPTE       : 95.2381  -> arrondi VERS LE BAS 1 dec : 95.2
nb fichiers dans lcov      : 19
nb .dart dans lib/         : 20
ABSENTS DU DENOMINATEUR    : lib/main.dart

Lignes NON couvertes, par fichier :
   14  lib/features/echeances/domain/remaining_time.dart    -> 37,39,40,41,42,43,44,46,47,48,49,50,51,52
    2  lib/core/color/rgb.dart                              -> 59,60
    1  lib/core/theme/concentration_tokens.dart             -> 14
    1  lib/core/theme/concentration_theme.dart              -> 23
    1  lib/features/echeances/data/sample_echeances.dart    -> 15
```

✅ **Mon recompte tombe sur la valeur du gate** *(380/399 = 95,2381 % → **95,2**)*, au-dessus du cliquet
**89,4** et du plancher **80,0**. ✅ **Confirmation indépendante du finding de la QA** : `lib/main.dart` est
**absent du dénominateur**.

### 🔬 Le fait le plus instructif du delta, et il n'était pas cherché

**La couverture de lignes est STRICTEMENT INCHANGÉE** — mêmes 380/399, **mêmes 19 lignes**, **mêmes 5
fichiers**, à la ligne près — alors que **dix tests ont été ajoutés** et que **six régressions
précédemment indétectables** sont désormais détectées.

⛔ **Autrement dit : le passage de « 6 mutants survivants » à « 0 » a coûté ZÉRO point de couverture, et
en aurait rapporté zéro s'il n'avait pas eu lieu.** C'est la démonstration *in vivo*, **sur du code
produit**, que la couverture de lignes ne mesure **pas** la capacité du filet à détecter — elle mesure
l'exécution. Le projet le supposait ; US-01.1 en fournit la **mesure**. ➡️ **À verser au corpus, candidat
`/audit-methodo`** *(voir P-4)*.

---

## 9. Contrôle d'intégrité — la séparation des pouvoirs a-t-elle tenu ?

Événements de `docs/trace/US-01.1/events.jsonl` ajoutés depuis mon 2ᵉ passage :

| Horodatage | Événement | Agent |
|---|---|---|
| `2026-08-02T12:19:13` | `EVT_SECURITY_AUDIT_PASSED` | cyber-security |
| `2026-08-02T16:30:37` | `EVT_QA_FAILED` | qa-tester |
| `2026-08-02T17:08:08` | `EVT_CODE_READY` | developer |

✅ **Aucun `EVT_CODE_REVIEW_PASSED` n'a été auto-émis.** Le développeur a émis `EVT_CODE_READY` et s'est
arrêté là. ✅ Le SCB a **remis les colonnes `Audit Rev` et `Audit Sec` à ⏳** au motif que les visas
portaient sur `6fe75df` — **le bloc de visa antérieur reste lisible et daté, rien n'est repeint**. C'est le
comportement correct, et il n'est pas le mien à valider : je le **constate**.

---

## 9 bis. `reports/US-01.1/qa_exit_criterion.py` — audité comme **CODE LIVRÉ**

314 lignes de Python entrées par `be9cc4a`. L'**audit sécurité les a déjà couvertes** *(verdict PASSED,
deux findings non bloquants : un `shell=True` inutile et le **code de retour de `flutter pub get` non
lu**)* — ⛔ **je ne refais pas son travail et je ne me les attribue pas.** Ce qui suit est la **qualité**.

### 9 bis.1 Ce que ce script fait BIEN, et qui mérite d'être nommé

- ✅ **Le verdict est tiré du CODE DE RETOUR de `flutter test`, jamais du texte analysé.**
  `obtenu = "TUE" if code != 0 else "SURVIT"` ; la regex `_rouges` ne sert qu'au **diagnostic**. ⇒ si la
  regex cesse un jour de reconnaître le format *(p. ex. une suite de plus de 99 minutes casserait le
  `^\d\d:\d\d`)*, **le verdict reste juste** et seule la liste des rouges s'appauvrit. **C'est la bonne
  hiérarchie**, et c'est rare.
- ✅ **Un motif introuvable est un ÉCHEC**, jamais un silence — le script refuserait de se blanchir le jour
  où le code bouge.
- ✅ **Aucun mutant désigné par un numéro de ligne** ; **contrôle positif** obligatoire ; comparaison en
  **ensembles** dans l'autotest ; **le dépôt n'est jamais modifié** *(vérifié par moi :
  `git status --porcelain` après 16 mutations ne rend que mon propre fichier non suivi)*.
- ✅ **L'état daté dans le docstring est CORRECTEMENT daté** — *« ETAT AU 2026-08-02 SUR 6fe75df : exit 1 »*
  reste **vrai à sa date et à son commit**. ⛔ Il **ne doit pas** être « mis à jour » maintenant qu'il rend
  `exit 0` : une valeur mise à jour périme au cycle suivant.
- ✅ **Le défaut du `for … else`**, trouvé par la QA **dans son propre instrument**, est **corrigé et
  commenté sur place**.

### 9 bis.2 Ce que je relève — **tout non bloquant** *(P-6 à P-9, §11)*

Mesuré, pas lu :

```
$ python -  (analyse AST de selftest())
  attendus   liee ligne 271  -> LUE
  code       liee ligne 271  -> JAMAIS LUE
  sortie     liee ligne 271  -> LUE

$ (gates declares dans factory.config.json)
  app format / analyze / test / deps_audit / build      -> les CINQ sont Dart
$ grep -rniE "ruff|flake8|mypy|pylint|black" .github/workflows/ factory.config.json
  (sortie vide)
```

⇒ **Aucun outil ne regarde le Python de ce dépôt.** La variable `code`, **liée et jamais lue**, en est la
démonstration à coût nul : `ruff` ou `pylint` l'auraient signalée seuls. **P-6.**

### 9 bis.3 ⛔ Un « code neuf sans test » ? — **NON, et je dis pourquoi plutôt que de trancher vite**

C'est mon **quatrième critère bloquant**, donc la question doit être posée franchement.

- Le script **porte son autotest** *(`--selftest` → exit 0)*, qui couvre l'extraction des rouges *(3 cas,
  comparés en **ensembles**)*, la **présence réelle** des 7 motifs dans le dépôt, la détectabilité d'un
  motif absent et la présence du contrôle positif.
- **La lacune est réelle et je la nomme** : `selftest()` **ne couvre pas la ligne qui décide du verdict**.
- **Mais les deux branches de cette ligne ont été OBSERVÉES en vrai, sur deux commits différents** :
  **6 `SURVIT` + 1 `TUE`** relevés par la QA sur `6fe75df`, **7 `TUE`** relevés par moi sur `173fb62`.
  Une validation **empirique bidirectionnelle** vaut mieux qu'un cas de table — c'est même exactement la
  méthode que ce projet impose *(« un contrôle portant son mutant a été juste 7 fois sur 7 »)*.

➡️ **Ce n'est donc pas « du code neuf sans test ».** ⛔ Le classer bloquant reviendrait à **durcir mon
critère entre deux passages**, ce que ma propre règle interdit **dans les deux sens**. **P-7** en porte la
suggestion : ajouter les deux cas de table **quand même**, parce qu'une preuve empirique **disparaît** dès
que le corpus change, là qu'un cas de table reste.

---

## 10. Statut de mes findings ouverts — **par leur nom, pas par un décompte**

⚠️ **Préalable de méthode, et il porte sur MON propre rapport précédent.** Le 2ᵉ passage annonce **« 10
findings non bloquants ouverts »** ; son tableau §5 en **énumère 12** *(N-1, N-2, N-3, N-5, N-6, N-7, N-9,
N-10, N-11, N-12, N-13, O-1)*. La lecture la plus plausible est que le « 10 » exclut **N-13** *(classé
« action humaine »)* et **O-1** *(classé « nouveau »)* — mais **le rapport ne le dit pas**. ⛔ **C'est un
chiffre écrit à la main à côté d'une énumération : exactement la classe de défaut la plus active du projet,
cette fois dans un rapport d'audit.** Je ne re-litige pas ce décompte ; **je donne l'état de chacun, par son
nom**, et je laisse le lecteur compter dans la colonne.

| # | Sévérité | État au **`173fb62`** | Preuve — **mesurée** |
|---|---|---|---|
| **B-1** | 🔴 Bloquant | ✅ **RÉSOLU** *(2ᵉ passage)* | `lib/` **bit-à-bit identique** ; `temporal_gradient_test.dart` **hors delta** ⇒ inchangé par construction |
| **B-2** | 🔴 Bloquant | ✅ **RÉSOLU** *(2ᵉ passage)* | Code + assertions toujours présents : `hub_page.dart` `ajout`/`reglages`, e2e `find.bySemanticsLabel('Ajouter une échéance')` / `('Réglages')` |
| **N-3** | 🟠 Majeur | ✅ **RÉSOLU** — *et c'est le résultat central de ce passage* | **QA-M3 (= mon M2) TUÉ**, 1 rouge. **Et mon X-4 non publié** *(`BoxFit.none`, widget conservé)* **est tué aussi** ⇒ l'assertion porte sur le **comportement**, pas sur la présence d'un widget |
| **N-4** | 🟠 Majeur | ✅ **RÉSOLU** *(2ᵉ passage)*, **toujours vrai** | 13 `testWidgets` · 13 `lancerApp`/`lancerAvec` · 2 `pumpWidget`, tous sur `ConcentrationApp` · `MaterialApp` **seulement en commentaire** |
| **N-8** | 🟡 Mineur | ✅ **RÉSOLU** *(2ᵉ passage)* | `oklab.dart` **absent** de la liste des lignes non couvertes (§8) |
| **N-5** | 🟠 Majeur | 🟡 **PARTIELLEMENT RÉSOLU — 2 de ses 3 divergences sur 3** | ✅ « 4 échéances / exactement 4 tuiles » : **corrigé** (§6.1) · ✅ « chaque tuile porte la description » : **assertionné** · ⏳ **DEMEURE** : le scénario « *8 mois et 12 jours → 9* » est toujours testé en e2e avec `Duration(hours: 5, minutes: 10)` ⇒ « 6 » |
| **N-1** | 🟠 Majeur | ⏳ **OUVERT** | `hub_page.dart` : `body: EcheancesGrid(echeances: …, clock: …)` **toujours câblé en dur** ; le getter `registre.actif` n'a **aucun appelant dans `lib/`** *(il en a désormais dans `test/`, ce qui ne change rien à ADR-004 §4)* |
| **N-2** | 🟡 Mineur | ⏳ **OUVERT** | `PracticeModule` porte `id`, `libelle`, `statut` — **pas de champ `icone`**, contre ADR-004 §1 |
| **N-6** | 🟠 Majeur | ⏳ **OUVERT** | `grep -rn "depuisDonnee" lib/` → **une seule occurrence, sa définition** |
| **N-7** | 🟡 Mineur | ⏳ **OUVERT — et sa part augmente en proportion** | `remaining_time.dart` concentre **14 des 19** lignes non couvertes |
| **N-9** | 🟡 Mineur | ⏳ **OUVERT** | Lieu dans `lib/` ⇒ inchangé par construction |
| **N-10** | 🟡 Mineur | ⏳ **OUVERT** | `tuilesMin` et `contrasteMinTexteLarge` : **aucune lecture** dans `lib/` ni `test/` — re-grepé au delta, le seuil 3,0 reste inutilisé |
| **N-11** | 🟡 Mineur | ⏳ **OUVERT — et délibérément non « fait passer »** | §7 : **0 occurrence** de mesure de temps, sonde retirée, Story File hors delta |
| **N-12** | 🟡 Mineur | ⏳ **OUVERT** | `echeance.dart` : `assert(id != '', 'I-2 : id non vide')` toujours en place |
| **N-13** | ⚠️ Action **humaine** | ⏳ **OUVERT — valeur INCHANGÉE depuis le 2ᵉ passage** | Le gate imprime `Valeur a consigner (arrondie VERS LE BAS) : 95.2`. `factory.config.json` est **hors delta** et protégé |
| **O-1** | 🟡 Mineur | ⏳ **OUVERT** | `ConcentrationApp({… this.echeances})` inchangé — lieu dans `lib/` |

**Bilan du passage** : **N-3 passe de OUVERT à RÉSOLU** *(le seul finding qui portait encore une preuve de
mutation active)*, **N-5 passe de OUVERT à PARTIEL**. **Tous les autres sont inchangés, et pour la plupart
inchangés par construction.**

⛔ **Je ne requalifie toujours aucun d'eux en bloquant, et je n'en durcis aucun.** Ma règle vaut dans les
deux sens : *« je ne déplace pas mes critères entre deux passages »*. Bloquant = erreur lint/typecheck ·
duplication manifeste · N+1 · code neuf sans test · AC non couvert par le code. Aucun des restants n'y
entre — **et le fait que la QA ait, elle, tenu six d'entre eux pour décisifs ne me fait pas changer les
miens** : elle jugeait selon **son** critère de rôle *(« chaque AC a-t-il un test qui le couvre ? »)*, qui
est **le bon** pour elle et **n'est pas le mien**. Les deux verdicts étaient justes en même temps.

---

## 11. Findings NOUVEAUX de ce passage — **tous non bloquants**

Format : `[Fichier] | [Problème] | [Solution]`

| # | Fichier | Problème | Solution |
|---|---|---|---|
| **P-1** | `test/e2e/hub_echeances_test.dart` *(scénario 2)* ↔ `test/features/hub/presentation/hub_page_test.dart` | **Duplication partielle** du bloc d'assertions « grisé » : les deux itèrent sur `registre.grises` et assertent `== moduleGrise.couleur` puis `isNot(actif)`. | ⛔ **Non bloquant, et j'ai mesuré pourquoi** : le helper `couleurDuLibelle` existe en **un seul exemplaire** *(le vrai risque DRY est déjà traité)* ; les deux blocs **divergent** *(seul l'unitaire porte la propriété de contraste)* ; et **la mesure le prouve** — QA-M5 fait rougir **3** tests, mon X-6 en fait rougir **1 seul**, celui de l'unitaire. Ils ne sont **pas** redondants. La copie e2e est en outre **exigée** par le 13 ↔ 13 : l'étape Gherkin doit être adossée **dans le test de son scénario**. **Aucune action.** |
| **P-2** | `test/core/theme/concentration_theme_test.dart` · `test/features/hub/presentation/hub_page_test.dart` | ⚠️ **Avertissement, pas défaut.** Les assertions d'**égalité au token** sont **tautologiques vis-à-vis du token** : sous X-5 et X-6, **elles ne rougissent pas** — les deux côtés bougent ensemble. Toute la protection contre une dérive de token repose sur les **deux assertions de GRANDEUR** *(« sombre » / « grisé »)*, qui **ont l'air de faire doublon**. | **Ne jamais les retirer au motif de la duplication.** Les marquer comme **porteuses** dans leur commentaire — ⛔ **jamais par un numéro de ligne**, il glisse en silence. À rappeler dans le Story File d'US-01.2. |
| **P-3** | `test/support/rendu_couleur.dart` — `rgbDe(Color)` | **Deuxième implémentation de la frontière colorimétrique**, en sens inverse de `RgbVersColor` qui vit dans `lib/` et s'y déclare *« le **seul** point de contact »*. Aujourd'hui l'aller-retour est exact *(`Color.fromARGB(255, r, g, b)` ↔ `(c.r * 255).round()`)*, mais `rendu_couleur.dart` **n'est pas un `_test.dart`** : il n'a **aucun test propre** et n'entre **pas** au dénominateur de couverture. Si `RgbVersColor` changeait, `rgbDe` **dériverait en silence** et **toutes** les assertions de couleur deviendraient fausses **sans rougir**. | Un test d'**aller-retour** sur les tokens : `expect(rgbDe(token.couleur), token)` pour chaque token de `ConcentrationTokens` — **~3 lignes**, et il transforme une dérive silencieuse en test rouge. |
| **P-4** | *(méthode — pas un fichier)* | **La couverture de lignes est strictement inchangée** *(380/399, mêmes 19 lignes)* alors que **six régressions détectables** ont été ajoutées au filet. La métrique affichée par le gate **n'a pas bougé d'un iota** sur le seul changement qui ait amélioré la capacité de détection de cette US. | ⛔ **Cesser de lire « 95,2 % » comme une mesure de la qualité du filet.** Verser le fait au corpus : *« un cliquet de couverture ne protège pas contre un test décoratif »*. ➡️ **Candidat `/audit-methodo`** — c'est la première observation du phénomène **sur du code produit**. |
| **P-5** | `STORY_CERTIFICATION_BOARD.md` *(bloc de visa d'US-01.1)* | Le texte écrit **« HEAD est `ddf839e` »**. HEAD est **`173fb62`** — le commit **qui a écrit cette phrase**. ⛔ **« HEAD est X » est une assertion qui s'auto-périme** : elle est fausse dès le commit suivant. L'assertion **utile** qu'elle portait *(« les visas portent sur `6fe75df`, qui n'est plus HEAD »)* **reste vraie**, donc **aucune fausseté n'est en circulation** aujourd'hui. | **Désigner le commit sur lequel le visa PORTE, jamais « HEAD ».** Même classe de défaut que NB-6 et que la dette *« un chiffre écrit à la main à côté d'une commande »*. |
| **P-6** | `reports/US-01.1/qa_exit_criterion.py` *(et tout le Python du dépôt)* | **314 lignes de Python livrées, et AUCUN outil ne les regarde.** Mesuré : les **5** gates sont **tous Dart** ; `ruff\|flake8\|mypy\|pylint\|black` → **0 occurrence** dans `.github/workflows/` et `factory.config.json`. Coût **démontré à l'instant** : dans `selftest()`, la variable `code` est **liée et jamais lue** *(relevé par AST, pas à l'œil)*. ⚠️ **Distinct de la dette « aucun SAST »** déjà connue : il s'agit ici de **lint**, pas de sécurité. | Un gate `ruff check scripts/ reports/` — il aurait trouvé la variable morte **seul**. ➡️ **US-00.8** *(la dette « aucun SAST » y est déjà portée ; celle-ci est moins chère et immédiate)*. |
| **P-7** | `reports/US-01.1/qa_exit_criterion.py` — `selftest()` | L'autotest **ne couvre pas la ligne qui décide du verdict** *(`"TUE" if code != 0 else "SURVIT"`)*. ⛔ **Non bloquant** : les **deux** branches ont été **observées en vrai sur deux commits** *(6 SURVIT + 1 TUE sur `6fe75df` ; 7 TUE sur `173fb62`)* — voir §9 bis.3. | Deux cas de table dans `selftest()`. **Motif** : une preuve **empirique** disparaît dès que le corpus change ; un cas de table **reste**. |
| **P-8** | `reports/US-01.1/qa_exit_criterion.py` — `sys.stdout.reconfigure(encoding="ascii", errors="replace")` | La mitigation `cp1252` est **correcte et nécessaire** *(trois instruments d'audit ont planté sur cette classe de bug)*, mais `errors="replace"` **DÉTRUIT l'information** : tous les titres de test accentués sortent en `?` — or **les titres de test SONT la preuve** que le rapport doit citer. | `errors="backslashreplace"` : aussi sûr, et **réversible**. ⚠️ **Mon propre script porte le même défaut, je l'ai copié** — la suggestion vaut pour les deux. |
| **P-9** | `reports/US-01.1/qa_exit_criterion.py` ↔ `reports/US-01.1/code_review_delta2_mutants.py` | **Duplication du harnais de mutation** — mesuré : **7 noms de fonctions communs**, **4 corps STRICTEMENT identiques** *(`_lire`, `_ecrire`, `_flutter_test`, `_rouges`)*. ⛔ **Elle n'est PAS imputable au delta** : au moment de `be9cc4a`, `qa_exit_criterion.py` était le **seul** harnais de mutation *(les 3 scripts de `scripts/` qui copient en `TemporaryDirectory` ne lancent aucun `flutter test`)*. ⛔ **C'est MON script qui a créé la 2ᵉ copie. J'en suis la cause, je ne la facture à personne.** | Un harnais **unique** dans `scripts/` *(copie isolée + mutation + lecture du verdict)*, dont les campagnes ne seraient plus que des **tables de mutants**. ➡️ **`/audit-methodo`** — c'est le motif *« une règle n'existe qu'en un seul exemplaire »* appliqué à l'outil qui fait respecter les règles. |
| **P-10** | *(méthode — saisine de cet audit)* | **Le périmètre du delta m'a été annoncé à 3 commits ; `git rev-list --count 6fe75df..173fb62` rend 4.** Le manquant, **`be9cc4a`**, est le **seul de la plage à apporter du code exécutable** *(314 lignes de Python)*. C'est la **classe de défaut nº 1 du projet** — *« une énumération écrite à la main à côté d'une commande, jamais relue dans sa sortie »*. ⚠️ **Et elle m'a atteint** : mon §1 avait **mesuré** le bon périmètre *(il liste `A reports/US-01.1/qa_exit_criterion.py`)*, mais mon **en-tête recopiait l'énumération reçue** — **la mesure était juste, la prose l'a écrasée**. Relevé par l'audit sécurité, qui a mesuré au lieu de croire ; rectifié ici. | ⛔ **Un périmètre d'audit se transmet comme une COMMANDE, jamais comme une liste** : `git log --oneline <base>..<head>`, et l'auditeur la rejoue. Même remède que pour les critères de sortie *(« se publie comme un script exécutable »)*. ➡️ **`/audit-methodo`.** |

---

## 12. Ce que ce 3ᵉ passage **N'ATTESTE PAS**

- ⛔ **Aucun rendu visuel observé.** L'application n'a **jamais** tourné sur un appareil ni dans un
  navigateur. Toutes les couleurs et tous les contrastes sont **calculés**, **aucun n'a été vu par un œil**.
  La conformité à la maquette **n'est pas vérifiée**.
- ⛔ **Le périmètre examiné est le DELTA `6fe75df..173fb62`**, plus la **réexécution intégrale** des gates,
  du corpus de tests, du critère de sortie de la QA et de ma propre campagne. Je n'ai **pas** re-relu ligne
  à ligne le code du 1ᵉʳ passage : son audit **reste celui de** [`code_review.md`](code_review.md).
- ⛔ **`PASSED` de REVUE ≠ `PASS` de QA.** **AC-1 « Limite » (RNF-02) reste un AC ORPHELIN**, et deux des
  huit clauses que la QA a classées « partielles » *(donnée illisible atteignant la grille — N-6 ; tailles
  de police système)* **ne sont pas traitées par ce delta**. Leur arbitrage appartient à @QA_Tester.
- ⛔ **Aucune couverture de branches** — 95,2 % est une couverture **de lignes**, et §8 montre ce qu'elle
  ne voit pas.
- ⛔ **`lib/main.dart` n'est ni couvert ni compté.**
- ⛔ **Aucun runner BDD.** Les 13 scénarios sont exécutés par des **tests Dart qui reproduisent leurs
  titres** ; `check_gherkin_mapping.py` **annonce lui-même** qu'il compare des **titres, pas de la
  sémantique**.
- ⛔ **Aucun SAST, aucun scan de CVE** — hors de mon périmètre, rappelé pour que ce `PASSED` ne soit pas lu
  comme portant sur la sécurité. ⚠️ **Le visa 🛡️ en vigueur porte sur `6fe75df`, pas sur `173fb62`** ; le
  SCB l'a d'ailleurs remis à ⏳. Le delta étant **100 % `test/` avec 0 dépendance ajoutée**, il n'a
  *a priori* aucune surface de sécurité — mais ⛔ **ce n'est pas à moi de le dire**, et *« un visa est une
  assertion sur un commit, pas sur une intention »*.
- ⛔ **Ce verdict porte sur `173fb62` ET SUR LUI SEUL.** La trace n'ayant **aucun champ `commit`**
  *(**NB-6**)*, le SHA est inscrit dans le **champ libre** de l'événement : **convention NON enforcée**.
  Tout commit ultérieur touchant `lib/` ou `test/` **périme ce verdict en silence**.

---

## 13. Condition de sortie — pour un éventuel 4ᵉ passage

Publiée comme des **scripts exécutables**, jamais recopiée à la main :

```bash
python scripts/run_gates.py --all                                  # attendu : exit 0
python scripts/check_gherkin_mapping.py                            # attendu : exit 0 (13 <-> 13)
python scripts/check_gherkin_mapping.py --selftest                 # attendu : exit 0
python reports/US-01.1/qa_exit_criterion.py --selftest              # attendu : exit 0
python reports/US-01.1/qa_exit_criterion.py                         # attendu : exit 0  (7/7 TUES)
python reports/US-01.1/code_review_delta2_mutants.py --selftest     # attendu : exit 0
python reports/US-01.1/code_review_delta2_mutants.py                # attendu : exit 0  (X-0..X-7 TUES, X-8 SURVIT)
```

⚠️ **Deux avertissements sur cette condition, que je préfère écrire que taire.**

1. ⛔ **Elle est désormais PUBLIÉE — donc elle a perdu ce qui faisait sa force.** Mes neuf mutants valaient
   *parce qu'ils étaient inconnus*. Au 4ᵉ passage, ils ne prouveront plus que la **non-régression**. **Un
   auditeur suivant doit en ajouter des siens, non publiés** — c'est la seule partie du protocole qui ne se
   délègue pas à un script.
2. ⛔ **`X-8` doit continuer à SURVIVRE.** S'il se met à rougir, ce n'est **pas** une bonne nouvelle : c'est
   le signe que la suite est devenue sensible à des détails de rendu que **rien ne spécifie**, et la mort
   des autres mutants cessera d'être informative.

---

## 14. Traçabilité

| Élément | Valeur |
|---|---|
| **Événement émis** | `EVT_CODE_REVIEW_PASSED` |
| **Commit couvert** | **`173fb62348c5ca516505067c1ea29c97fa06b8a8`** — inscrit dans le **champ libre** de l'événement *(NB-6 : la trace n'a aucun champ `commit`)* |
| **Périmètre** | **4 commits** `be9cc4a`, `ade583e`, `ddf839e`, `173fb62` — **lus dans `git log`**, pas dans l'énumération transmise *(P-10)*. `qa_exit_criterion.py` audité **et comme instrument (§2.3) et comme code livré (§9 bis)** |
| **Exécutions** | `git rev-list --count` · `run_gates.py --all` → **exit 0** *(5 gates, 112 tests, 95,2 % — 380/399)* · `check_gherkin_mapping.py` + `--selftest` → exit 0 · `qa_exit_criterion.py --selftest` → exit 0 · `qa_exit_criterion.py` → **exit 0, 7/7 tués** · `code_review_delta2_mutants.py --selftest` → exit 0 · `code_review_delta2_mutants.py` → **exit 0, 9 mutants au verdict attendu** · recompte indépendant de `lcov.info` · comparaison **ensembliste** des noms de tests entre les deux commits · comparaison de **blobs** git *(`.feature`, `qa_exit_criterion.py`)* · greps de statut des findings · **analyse AST** de `qa_exit_criterion.py` *(variable morte, duplication de harnais)* |
| **`PYTHONIOENCODING`** | **`utf-8` forcé** sur toutes les exécutions ; sorties des scripts de mutation en **ASCII** *(les `?` des sorties collées sont ce repli, pas une erreur — trois instruments d'audit d'affilée ont planté en `cp1252` sur ce projet, **dont le mien au 1ᵉʳ passage**)* |
| **Mutations** | **16 au total** en copie isolée *(7 de la QA + 9 de moi)* — **le dépôt n'a jamais été modifié**, `git status --porcelain` ne rend que mon propre script de mutants, non suivi, dans `reports/` |
| **Dépôt modifié ?** | **NON** — écritures confinées à `reports/US-01.1/` et `docs/trace/US-01.1/` |
| **Code / tests modifiés ?** | **NON** — ⛔ aucun octet de `lib/`, `test/`, `scripts/`, `tests/features/` |
| **SCB modifié ?** | **NON** — mise à jour par le rituel `/audit-us`, à partir de ce verdict |
