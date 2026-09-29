# 🧪 Rapport QA — US-01.4 « Gestes sur la tuile : révélation de la description et retrait d'une échue (RF-06) »

| | |
|---|---|
| **Rôle** | @QA_Tester — **contexte frais** |
| **Modèle** | `claude-opus-5[1m]` (Opus 5, 1M context) |
| **Date** | 2026-09-14 |
| **Branche** | `feat/US-01.4-gestes-tuile` |
| **SHA audité (NB-6)** | **`b92e0a6`** (`b92e0a64bda739548d1327c9bc2dcc9bd4612b55`) |
| **Phase SCB à l'entrée** | `parallel_audit` — visas `✅ @PO · ✅ @Data · ✅ @UX · ✅ @Dev · ✅ 🔍 · ✅ 🛡️`, `QA Status = ⏳` |
| **VERDICT** | ## 🧪 **PASS** |

> ⚖️ **Rappel d'autorité (Constitution Art. 5)** : je délivre `🧪 PASS`. La certification `🚀 OUI`
> appartient au rituel `/certify` (@Architect), **pas à moi**. ⛔ Ce rapport ne certifie rien.

---

## 0. Préconditions du rôle — vérifiées par commande, pas par lecture

```
$ python scripts/validate_trace.py --us US-01.4
Traçabilité conforme.

$ grep -o '"event": "[A-Z_]*"' docs/trace/US-01.4/events.jsonl
 ... 10  "event": "EVT_SECURITY_AUDIT_PASSED"
 ... 11  "event": "EVT_CODE_REVIEW_PASSED"
```

✅ Les **deux** événements requis sont présents. Je suis recevable.

---

## 1. Décomptes exacts — ⛔ aucun chiffre recopié d'un document

### 1.1 Suite de tests — **QUATRE exécutions complètes** (exigé par NB-2)

| Exéc. | Commande | Durée | **Passed** | **Skipped** | **Failed** | Couverture |
|---|---|---|---|---|---|---|
| **1** | `run_gates.py --all` | 5'27 | **562** | **0** | **0** | 98.0 % |
| **2** | `run_gates.py --gate test` | 6'52 | **562** | **0** | **0** | 98.0 % |
| **3** | `run_gates.py --gate test` | 8'29 | **562** | **0** | **0** | 98.0 % |
| **4** | `run_gates.py --gate test` | 3'43 | **562** | **0** | **0** | 98.0 % |

> ## **RATIO : 4 exécutions complètes / 4 VERTES.**

**Comment `skipped` et `failed` sont LUS** — ⛔ pas déduits d'un « All tests passed » :
le rapporteur de `flutter test` préfixe `~N` pour les *skipped* et `-N` pour les *failed*.

```
run 1 : skipped-markers(~)=0   failed-markers(-)=0   final=+562: All tests passed!
run 2 : skipped-markers(~)=0   failed-markers(-)=0   final=+562: All tests passed!
run 3 : skipped-markers(~)=0   failed-markers(-)=0   final=+562: All tests passed!
run 4 : skipped-markers(~)=0   failed-markers(-)=0   final=+562: All tests passed!
```

Contrôle statique concordant : `grep -rn "skip:" test/` → **0 occurrence**.
⇒ **Aucun scénario skipped n'est compté comme vert dans ce rapport, parce qu'il n'y en a aucun.**

### 1.2 Gates bloquants — `python scripts/run_gates.py --all`, **exit 0**

```
✅ app.format      dart format --output=none --set-exit-if-changed lib test
                   Formatted 74 files (0 changed) in 1.77 seconds.
✅ app.analyze     flutter analyze
                   No issues found! (ran in 19.7s)
✅ app.test        Couverture de lignes : 98.0% (1121/1144) — seuil requis : 95.2% (cliquet)
✅ app.deps_audit  (non bloquant)
✅ app.build       flutter build web --release → Built build\web  (100,8s)
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

### 1.3 Couverture

| | Valeur | Source |
|---|---|---|
| Couverture mesurée | **98.0 % (1121/1144)** | sortie du gate `app.test` |
| Cliquet requis | **95.2** | **LU** dans `factory.config.json` → `adapter.components.app.coverage_ratchet.value` |
| Plancher | 80 | `coverage_min` |
| **Marge** | **+2,8 pt** | — |

⚖️ **La marge NULLE du cliquet est levée sur cette US** : elle était de 0 pt en entrée d'US-01.2,
elle est de **+2,8 pt** ici. ⛔ **Cela n'autorise rien** : la couverture de lignes reste
**aveugle à la force des assertions** (acquis établi sur code réel : 380/399 avant **et** après,
pour +526 lignes de test et 6 mutants tués).

### 1.4 Gouvernance

```
$ python scripts/factory_sync.py --check     → exit 0  (vérification DOCUMENTAIRE)
$ python scripts/check_scb_compliance.py     → exit 0  « SCB conforme — Aucune violation détectée. »
```

---

## 2. Les scénarios sont-ils RÉELLEMENT exécutés ? — la question, et sa mesure

### 2.1 Correspondance scénario ↔ test

```
$ python scripts/check_gherkin_mapping.py
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
  tests/features/US-01.2-gestion-echeances.feature     50 scenarios
  test/e2e/gestion_echeances_test.dart                 50 tests
  tests/features/US-01.4-gestes-tuile.feature          41 scenarios
  test/e2e/gestes_tuile_test.dart                      41 tests
OK : chaque scenario a son test et chaque test son scenario.
Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
```

✅ **T15 est fait** : le couple d'US-01.4 est **inscrit dans `COUPLES`**, donc **sous contrôle**.

### 2.2 ⛔ La correspondance de titres ne prouve PAS l'exécution — je l'ai donc mesurée à part

Le rapporteur par défaut écrase ses lignes de progression : **on ne peut pas compter les tests
exécutés dans le log d'une suite complète** (ma première tentative rendait **9** titres distincts
sur 41 — un artefact d'affichage, ⛔ pas un résultat). Mesure refaite avec un rapporteur explicite :

```
$ flutter test test/e2e/gestes_tuile_test.dart -r expanded
00:40 +36: Retirer la dernière tuile conduit à l'état vide sobre
00:41 +37: Un retrait qui ne peut pas être écrit est annoncé et la tuile reste
00:41 +38: Un retrait qui ne peut pas être écrit ne joue aucune animation de disparition
00:41 +39: Une échue dont le retrait a échoué compte toujours dans la limite de neuf
00:47 +40: Après un échec de retrait le geste réessayé aboutit
00:48 +41: All tests passed!
```

✅ **41 tests exécutés sur 41 scénarios, 0 skipped, 0 failed.** Les scénarios d'US-01.4 sont
**réellement joués**, ⛔ pas seulement présents.

### 2.3 Densité d'assertions — un test peut s'exécuter sans rien asserter

```
$ grep -c "expect(" test/e2e/gestes_tuile_test.dart        → 193
$ (tests à ZÉRO expect)                                     → 1, et c'est un COMMENTAIRE
```

L'unique correspondance « zéro assertion » est la ligne 97, un commentaire de documentation
(`// check_gherkin_mapping.py capte test( autant que testWidgets(`), ⛔ pas un test.
⇒ **193 assertions pour 41 scénarios (≈ 4,7 par scénario). Aucun test vide.**

### 2.4 Re-mesure du défaut d'instrument daté du 2026-08-21 — ⛔ je ne recopie pas son chiffre

Le SCB (ligne 3098) relève que les couples de `check_gherkin_mapping.py` sont **en dur** et que rien
ne vérifie qu'un `.feature` du dossier y figure — **140 scénarios invisibles** au 2026-08-21.
**Re-mesuré aujourd'hui** :

```
$ grep -h '^  Scénario: ' tests/features/*.feature | wc -l   → 207 sur disque
  vus par le gate : 13 + 50 + 41                             → 104
  invisibles                                                 → 103
```

✅ **Les 103 invisibles sont EXACTEMENT les 103 scénarios de gouvernance** (US-00.1 → US-00.7 :
8+6+6+20+21+18+24), dont l'exclusion est **assumée et documentée**. **L'angle mort qui portait sur
US-01.4 est REFERMÉ.** ⛔ **Le défaut d'instrument, lui, demeure** : rien ne signalerait le prochain
`.feature` oublié. *(`/audit-methodo`.)*

---

## 3. Couverture des AC — AC couverts / AC orphelins

### 3.1 Comptes lus par commande

```
$ grep -c "^### AC-" docs/stories/US-01.4-gestes-tuile.md                      → 11
$ grep -cE "^- \*\*(Nominal|Erreur|Limite)\*\* :" docs/stories/…               → 33
$ grep -c "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature          → 41
$ grep "^  Scénario: " … | sort | uniq -d                                      → (VIDE)
```

✅ **33 clauses = 11 AC × 3** ⇒ **aucun AC amputé d'une clause**.
✅ **0 titre de scénario en double.**

### 3.2 Répartition AC → scénarios (relevée dans le `.feature`, pas dans le Story File)

| AC | Scénarios | Exécutés & verts |
|---|---|---|
| AC-1 — tuile au repos | 5 | ✅ |
| AC-2 — appui simple / révélation 3 s | 5 | ✅ |
| AC-3 — active sans description | 3 | ✅ |
| AC-4 — double-tap retire une échue | 6 | ✅ |
| AC-5 — retrait durable | 3 | ✅ |
| AC-6 — place libérée / message de limite | 3 | ✅ |
| AC-7 — échues signalées en gestion | 2 | ✅ |
| AC-8 — animation de disparition | 3 | ✅ |
| AC-9 — accessibilité des gestes | 4 | ✅ |
| AC-10 — non-régression de l'exercice | 3 | ✅ |
| AC-11 — retrait dont l'écriture échoue | 4 | ✅ |
| **TOTAL** | **41** | **41/41** |

### 3.3 ⛔ **AC ORPHELINS : AUCUN — 11 AC sur 11 sont couverts par au moins un scénario exécuté**

**Une seule clause est déclarée NON SCÉNARISÉE, avec son motif** :

| Clause | Statut | Motif déclaré | Réfutation prévue |
|---|---|---|---|
| **AC-11 « Limite »** | **Non scénarisée, DÉCLARÉE** | Clause de **CONCEPTION** (ni réessai automatique, ni file d'attente, ni retrait « en attente » — les trois exigeraient d'écrire, ce qui vient d'échouer) | **Revue d'architecture** — patron suivi à la lettre depuis AC-17 « Limite » d'US-01.2 |

⚖️ **Je l'accepte** : elle est **déclarée**, **motivée**, et sa réfutation est **nommée**. C'est le
patron exact qu'US-01.2 a validé. ⛔ **Ce n'est pas un AC orphelin** — c'est une non-couverture
**déclarée**, ce que la procédure autorise explicitement.

⚠️ **Trois clauses sont couvertes par le scénario d'une clause voisine** — **AC-6 L**, **AC-7 L**,
**AC-10 E** — et **c'est écrit dans leur ligne** de la table anti-orphelin. ⛔ Jamais laissé implicite.

### 3.4 ⛔ Ce que la table anti-orphelin ne peut pas voir, et que je ne prétends pas avoir couvert

La table vérifie que les clauses **écrites** ont un scénario, ⛔ **jamais qu'une clause MANQUE**.
**AC-11 a manqué depuis la création du Story File** et **aucun instrument ne l'a signalé** — ni la
table, ni la DoD, ni `check_gherkin_mapping.py`, ni le contrôle `AC × 3` (**11 × 3 aurait été
« conforme » avec 10 AC**). Il a été trouvé par un **humain relisant les AC**.
➡️ **Mon contrôle `AC × 3` ci-dessus hérite de la même borne : il voit une clause manquante, ⛔ pas
un AC manquant.** *(`/audit-methodo`, défaut ⑥.)*

---

## 4. Edge cases testés — au-delà des cas passants

Relevés **dans le `.feature` exécuté**, ⛔ pas dans une intention de design :

| # | Edge case | Scénario | Verdict |
|---|---|---|---|
| 1 | Description **vide/absente** sur tuile active | *Une tuile active sans description n'annonce aucune révélation* | ✅ |
| 2 | Description vide sur tuile **échue** (le geste doit survivre) | *Une tuile échue sans description reste retirable* | ✅ |
| 3 | **Deux révélations concurrentes** | *Appuyer une seconde tuile referme la première révélation* | ✅ |
| 4 | **Rafraîchissement pendant** la révélation (ni coupée ni prolongée) | *Un rafraîchissement de la grille n'interrompt pas la révélation* | ✅ |
| 5 | **Ré-appui pendant** la fenêtre (redémarrage des 3 s) | *Un nouvel appui pendant la révélation redémarre les trois secondes* | ✅ |
| 6 | **Mauvais geste** : double-tap sur une **active** | *…ne retire rien et n'écrit rien* | ✅ |
| 7 | **Mauvais geste** : appui **simple** sur une **échue** (risque nº 5 : retrait à un seul geste) | *…ne retire rien et ne révèle rien* | ✅ |
| 8 | **Mauvais geste** : appui **prolongé** | *…ne retire aucune tuile et n'écrit rien* | ✅ |
| 9 | **Double geste pendant l'animation** (double retrait) | *Un second double appui pendant l'animation ne retire rien d'autre* | ✅ |
| 10 | **Animations système réduites** (le résultat ne dépend pas du feedback) | *Le retrait aboutit même quand les animations système sont réduites* | ✅ |
| 11 | **Migration v2→v3** : données de la version antérieure | *Les échéances enregistrées par la version antérieure restent présentes* | ✅ |
| 12 | **Persistance** après réouverture | *Une échéance retirée ne revient pas sur la grille après réouverture* | ✅ |
| 13 | **Limite 9/10** avec et sans échue sur la grille (deux messages distincts) | 2 scénarios d'AC-6 « Erreur » | ✅ |
| 14 | **Dernière tuile retirée** → état vide sobre | *Retirer la dernière tuile conduit à l'état vide sobre* | ✅ |
| 15 | **Échec d'écriture** : message, tuile qui RESTE, pas d'animation, comptée dans la limite, **réessai qui aboutit** | 4 scénarios d'AC-11 | ✅ |
| 16 | **Police système ×2** à 9 tuiles (débordement) | *Neuf tuiles au nombre agrandi ne débordent pas…* | ✅ |
| 17 | **Cible tactile 48 dp** à 9 tuiles | *À neuf tuiles chaque cible tactile atteint quarante-huit points* | ✅ |
| 18 | **Clavier + focus visible** | *Chaque tuile est atteignable au clavier avec un focus visible* | ✅ |
| 19 | **Éléments NON interactifs** (modules grisés, Réglages) | *…restent sans gestionnaire de geste* | ✅ |
| 20 | **Non-régression couleur/ordre/rafraîchissement** après geste | 2 scénarios d'AC-10 | ✅ |

⚠️ **Le cas nº 15 est le plus lourd** : c'est le mode de défaillance **inverse** d'AC-17 d'US-01.2
(là-bas une donnée saisie disparaissait ; ici une tuile disparaîtrait sans que rien ne soit écrit).
**Il est couvert par 4 scénarios exécutés.**

---

## 5. Échecs au format « Action → Attendu → Obtenu »

### 5.1 Aucun échec de test

**0 échec** sur **4 exécutions complètes** (4 × 562 = **2 248 exécutions de tests**, 0 rouge).

### 5.2 UN critère de sortie est ROUGE, et c'est **VOULU** — je l'ai rejoué moi-même

> ⚖️ Ce rouge **ne fonde pas un `FAILED`** : c'est un **critère de sortie** livré par l'audit
> sécurité, conçu pour rougir **tant que le défaut existe** et verdir **le jour où il est corrigé**.

| | |
|---|---|
| **Action effectuée** | `flutter test reports/US-01.4/id_collision_retiree_criterion.dart` |
| **Résultat attendu** *(si NB-1 ≡ S-1 était corrigé)* | l'entrée **retirée** survit à la création d'une échéance portant le même `id` |
| **Résultat obtenu** | ❌ `Expected: <1> / Actual: <0>` — **`M1 entrees RETIREES restantes = 0`** : la retirée est **DÉTRUITE**, **sans message**. Document brut relu : `[{"id":"1789120800000000","description":"nouvelle echeance",…}]` — l'entrée retirée a été **écrasée** |
| **Contrôle négatif** | ✅ **VERT** — `CN entrees RETIREES restantes = 1` avec un `id` non colliding ⇒ **l'instrument sait ne PAS accuser**, il ne rougit pas par construction |

**Site du défaut, relu dans le code** — `lib/features/echeances/domain/validation_echeance.dart` :

```dart
id: _idLibre(presentes),          // ← ligne 254 : ne reçoit QUE les présentes
…
String _idLibre(List<Echeance> existantes) {
  final base = clock.now().microsecondsSinceEpoch.toString();
  var candidat = base;
  var rang = 0;
  while (existantes.any((e) => e.id == candidat)) { rang++; candidat = '$base-$rang'; }
  return candidat;
}
```

⇒ **`_idLibre` est aveugle aux retirées.** Confirmé indépendamment par `revue_id_libre_criterion.dart`
(**A1 vert** : l'entrée retirée disparaît ; **A2 contrôle négatif vert** : sans retrait, aucune perte).

**Couverture de test de ce chemin — mesurée** : le seul test d'unicité d'`id`
(`validation_echeance_test.dart` › *« deux créations au MÊME instant produisent deux id distincts »*)
n'exerce que **`presentes`**. ⛔ **Aucun test de `test/` ne garde le chemin « collision avec une
retirée ».** C'est un **edge case NON couvert**, et je le déclare comme tel.

### 5.3 🆕 Ce que J'AJOUTE sur ce défaut, et qui n'est dans aucun des deux rapports d'audit

Le troisième test de l'instrument (**A3 — atteignabilité**) publie les deux nombres qui bornent le
risque. **Je les ai lus dans sa sortie** :

```
A3| repetitions de microsecondsSinceEpoch = 199992 / 200000
A3| plus petit ecart NON NUL (us)          = 999
A3| duree creer->retirer->creer (us)       = 73398
```

**Lecture** : sur cette machine, `microsecondsSinceEpoch` **n'avance pas à la microseconde** — il
avance par paliers d'**≈ 999 µs (1 ms)**, et **199 992 tirages sur 200 000 sont des répétitions**.
La marge n'est donc **pas** « 1 µs contre 73 ms » : elle est **73 398 / 999 ≈ 73×**, c'est-à-dire
*« l'aller-retour créer → retirer → créer dure ~73 paliers d'horloge »*.

🔴 **Et c'est là ma contribution propre : le dénominateur de cette marge est la GRANULARITÉ DE
L'HORLOGE, qui est une propriété de la PLATEFORME — pas du code.** Or :

* cette granularité a été mesurée **sur une seule machine, un seul jour** (Windows, poste de dev) ;
* la **seule cible que ce projet sait construire aujourd'hui** est **`flutter build web --release`**,
  et les navigateurs **grossissent délibérément** la résolution de leurs horloges (atténuation
  Spectre) — ⛔ **cette granularité-là n'a JAMAIS été mesurée** ;
* **rien n'a tourné sur un appareil** (`adb` : `command not found` — vérifié, voir §8.5).

⇒ ⛔ **« marge ×73 » ne doit JAMAIS être transporté comme une constante.** C'est **exactement** la
leçon que ce projet a déjà payée sur le facteur de durée d'écriture atomique (`×1,39 à ×2,71`
**non reproductible**, réfuté au 2ᵉ relevé). **Un rapport se relit ; il ne se recopie pas.**
✅ **Ce qui SURVIT à ma mesure** : la marge est **réelle et confortable sur cette plateforme**, et le
défaut est **inatteignable tant que l'horloge est monotone croissante** (un `id` neuf est toujours
postérieur à celui d'une retirée créée dans le passé). ⛔ **Ce qui ne survit pas** : l'idée que la
marge serait une propriété du **code**.

### 5.4 Pourquoi NB-1 ≡ S-1 ne fonde PAS un `FAILED` de ma part — raisonnement explicite

| Critère | Constat |
|---|---|
| Un AC est-il **falsifié par un scénario exécuté** ? | ❌ **Non** — les 41 scénarios sont verts |
| Le chemin est-il **atteignable** en exploitation ? | ❌ **Non**, sous horloge monotone : un `id` neuf est structurellement **postérieur** à celui d'une retirée. Atteignabilité **mesurée** à ~73 paliers d'écart |
| Le défaut est-il **nommé, mesuré, outillé** ? | ✅ Oui — **deux** contextes frais indépendants ont convergé (NB-1 et S-1), **deux** instruments exécutables sont livrés, avec **contrôle négatif** |
| Est-il **corrigé** ? | ❌ **Non**, et je ne prétends pas le contraire |

⇒ **`PASS`**, avec ce défaut **escaladé au §8** comme **le résidu de plus haute valeur de cette US**.
⚖️ ⛔ **Mon `PASS` ne le referme pas** — *un verdict ne lève jamais un défaut*.

---

## 6. NB-2 — le gate requis `app.test` est INTERMITTENT : **je ne le lève PAS**

La revue de code a mesuré **1 rouge / 4** exécutions complètes sur `8509f44`, contre **6 verts / 6**
en isolement. **Ma mesure sur `b92e0a6` : 4 exécutions complètes, 4 VERTES (0 rouge).**

> ## ⛔ **4/4 VERT NE LÈVE PAS NB-2, ET JE REFUSE DE L'ÉCRIRE COMME SI C'ÉTAIT LE CAS.**
> **Cumul des deux mesures : 1 rouge sur 8 exécutions complètes (≈ 12 %).**
> **On ne prouve pas l'absence d'un défaut intermittent en ne le voyant pas.**

**Donnée nouvelle que ma campagne apporte** — les durées des 4 exécutions sont très dispersées :
**3'43 / 5'27 / 6'52 / 8'29** (facteur **2,3×**). **Et l'exécution la PLUS LENTE (8'29) est VERTE.**
⇒ ⚠️ **Cela n'accuse ni n'innocente l'hypothèse « charge concurrente » de la revue** : si la seule
variable était la durée totale, le run à 8'29 aurait été le plus exposé. ⛔ **Je constate, je
n'explique pas** — la revue disait déjà *« j'ai mesuré un taux, pas établi une cause »*, et je ne
fais pas mieux.

### 6.1 🆕 UNE PREUVE SUPPLÉMENTAIRE DE NON-DÉTERMINISME, QUE PERSONNE N'AVAIT RELEVÉE

En relisant les chiffres des deux audits **pour les recouper, ⛔ pas pour les recopier**, j'ai trouvé
un écart que ni la revue ni la sécurité n'ont vu, parce qu'il n'apparaît **qu'en comparant deux
campagnes** :

| Source | SHA | Couverture | Lignes couvertes |
|---|---|---|---|
| `reports/US-01.4/security.md` (l. 214) | `8509f44` | **98.1 %** | **1122** / 1144 |
| **Mes 4 exécutions** | `b92e0a6` | **98.0 %** | **1121** / 1144 |

**Et le code est IDENTIQUE entre les deux SHA** — ce n'est pas une hypothèse, c'est le `git diff` du
§7.1 : `git diff --name-only 8509f44..HEAD -- lib/ test/` rend **0 fichier**.

> ## 🔴 **MÊME CODE, MÊME DÉNOMINATEUR (1144), NUMÉRATEUR DIFFÉRENT (1122 vs 1121).**
> **La mesure de couverture de ce projet n'est pas déterministe : UNE ligne de `lib/` est couverte
> ou non selon l'exécution.**

⚖️ **Ce que cela vaut, et ce que ça ne vaut pas** :
* ✅ **C'est une corroboration indépendante de NB-2** : une ligne dont la couverture varie d'une
  exécution à l'autre est la **signature d'un chemin dépendant du temps** — exactement la nature
  du défaut que NB-2 décrit. ⇒ **NB-2 n'est pas un accident de machine : il laisse une trace
  MESURABLE dans un artefact tout à fait différent (le `lcov`).**
* ⛔ **Je n'ai PAS identifié la ligne en cause** — il faudrait diffuser deux `lcov.info` et les
  comparer. **Je nomme le fait, je ne l'explique pas.**
* ⚠️ **Conséquence sur le cliquet, à ne pas dramatiser mais à ne pas taire** : le cliquet est comparé
  à une valeur qui **bouge d'une exécution à l'autre**. Ici la marge est de **+2,8 pt** et une ligne
  vaut **0,09 pt** ⇒ **aucun risque pratique aujourd'hui**. ⛔ **Mais l'US-01.2 tournait à marge
  NULLE** : dans cette configuration-là, **cette variation d'une seule ligne aurait suffi à faire
  rougir un contexte REQUIS sans qu'aucune ligne de code n'ait changé.**
* ➡️ **À porter à `/audit-methodo`** : le projet sait déjà que *« la couverture de lignes est aveugle
  à la force des assertions »*. **Ceci est une seconde borne, distincte et jusqu'ici non écrite :
  elle n'est pas non plus REPRODUCTIBLE à la ligne près.**

**Je confirme la recommandation de la revue, et je n'en invente pas une autre** : remplacer l'attente
à **durée fixe** (`reglerEcritures` sans `jusqua`, `tours = 200`) par une **condition de sortie**
(`jusqua: () => messageVisible(tester)`). ⛔ **NE PAS relever `tours` une 3ᵉ fois** — le 2ᵉ
relèvement (40 → 200) a coûté **+83 % de durée de suite** et a produit un test *« instable en suite,
stable en isolement »*. **Un nombre magique relevé deux fois est un symptôme.**

⚠️ **Conséquence opérationnelle que @DevOps et @Architect doivent avoir** : ce rouge peut faire
échouer un **contexte REQUIS** au moment de la PR. Avec `strict: true` qui **sérialise** les merges,
une PR rouge sur ce seul motif **périme les autres branches** au passage. ➡️ **Prévoir une
re-exécution, ⛔ pas un `--admin`.**

---

## 7. Portée du visa — NB-6, et les deux US dont le `🧪 PASS` est périmé

### 7.1 Les visas d'audit portent sur `8509f44`, moi sur `b92e0a6` — écart MESURÉ

```
$ git log --oneline 8509f44..HEAD
b92e0a6 docs(us-01.4): les 2 cases d'audit de la DoD cochees, NB-6 verifie AVANT
540cad4 docs(us-01.4): double visa d'audit en contexte frais, et UNE CONVERGENCE INDEPENDANTE

$ git diff --name-only 8509f44..HEAD -- lib/ test/ | wc -l
0
```

✅ **Les 2 commits postérieurs aux audits ne touchent AUCUN fichier de `lib/` ni de `test/`**
(uniquement `reports/`, `docs/`, la trace, le SCB et le PROJECT_LOG). ⇒ **le code audité par 🔍 et
🛡️ est identique, octet pour octet, à celui que j'ai testé.** **Les deux visas restent
matériellement valides**, et ce n'est **pas une hypothèse** : c'est un `git diff`.
⚖️ ⛔ **Cela ne répare pas NB-6** — aucune machine ne l'aurait signalé ; j'ai dû le mesurer à la main.

### 7.2 🔴 **US-01.1 et US-01.2 : ce que mon verdict couvre, et ce qu'il ne couvre PAS**

**Périmètre réel de cette US, mesuré** :

```
$ git diff --stat origin/main...HEAD -- lib/
19 files changed, 1661 insertions(+), 147 deletions(-)
$ git rev-list --count origin/main..HEAD    → 30 commits
```

**Fichiers du cœur d'US-01.2 modifiés par US-01.4** : `echeance_document_codec.dart` ·
`echeance_document_repository.dart` · `echeance_repository.dart` · `validation_echeance.dart` ·
`echeances_notifier.dart` · `gestion_echeances_page.dart` · `formulaire_echeance.dart`
(+ 3 fichiers de tests d'US-01.2).

| Question | Réponse |
|---|---|
| Les **tests exécutables** d'US-01.1 (13 scénarios) et d'US-01.2 (50 scénarios) sont-ils **re-joués et verts** à `b92e0a6` ? | ✅ **OUI** — ils font partie des **562** tests verts, sur **4 exécutions sur 4**. C'est une **non-régression mesurée**. |
| Mon `🧪 PASS` **re-valide-t-il le `🧪 PASS` d'US-01.1 et d'US-01.2** ? | ⛔ **NON. Explicitement NON.** |

**Pourquoi non** : un `🧪 PASS` d'US porte sur **sa** DoD, **ses** AC, **ses** audits et **son**
commit. Je n'ai instruit **ni** la DoD d'US-01.1, **ni** celle d'US-01.2, et je n'ai **pas** rejoué
leurs audits 🔍/🛡️ sur le code modifié. ⇒ **leurs deux visas `🧪 PASS` demeurent PÉRIMÉS** au sens
de NB-6, et **seul leur propre cycle peut les rafraîchir**.
⚠️ **Rappel de l'enjeu, ⛔ pas une formalité** : `AC-12 « Erreur » d'US-01.2` est précisément l'AC
qu'un mutant *« d'apparence propre »* de cette US ferait tomber. **Une US déjà validée peut être
cassée par une US suivante, et aucune machine de ce projet ne sait le dire.**

---

## 8. ⛔ Ce que ce verdict N'ATTESTE PAS — à lire AVANT le `PASS`

1. ⛔ **NB-1 ≡ S-1 n'est PAS corrigé.** Je l'ai **reproduit** (§5.2) : une entrée **retirée** est
   **détruite sans message**. Il est **inatteignable** sous horloge monotone, **non couvert par le
   moindre test de `test/`**, et sa marge est **une propriété de la plateforme** (§5.3).
2. ⛔ **NB-2 n'est PAS levé** — **1 rouge / 8** exécutions complètes cumulées. **4/4 vert ne prouve rien.**
   🆕 **Et la couverture elle-même n'est pas reproductible à la ligne près** : **1122/1144**
   sur `8509f44` contre **1121/1144** sur `b92e0a6`, à **code identique** (§6.1).
   ⛔ **Le chiffre `98,0 %` de ce rapport ne doit donc pas être transporté comme une constante.**
3. ⛔ **Aucun SAST.** Vérifié, ⛔ pas supposé : `python scripts/run_gates.py --gate sast` → **exit 1
   réel**, *« aucun gate ne correspond »*. **Le gate n'existe pas.** ⛔ **Une absence d'instrument
   n'est pas un résultat négatif, et je ne la compte pas comme un `PASS`.**
4. ⛔ **Aucun scan de CVE.** `deps_audit` mesure l'**obsolescence**, ⛔ pas la **vulnérabilité**.
5. ⛔ **Rien n'a tourné sur un appareil.** Vérifié : `adb` → `command not found`.
   ⇒ **NM-3, NM-11, NM-13 demeurent non levées**, et le double appui éprouvé est **SYNTHÉTISÉ**.
   ⚠️ **NM-13 ne serait que partiellement levable sur un SM T580** : le cas critique est un **petit
   téléphone à 320 dp**.
6. ⛔ **Aucun écran n'a été vu.** Tous les contrastes restent **calculés**, jamais observés par un œil.
7. ⛔ **La sémantique des 41 scénarios n'est pas certifiée** : `check_gherkin_mapping.py` compare des
   **TITRES**, et il l'imprime lui-même. **Les faux titres de ce cycle ont tous été trouvés par des
   rôles à contexte frais, ⛔ aucun par un gate.** J'ai ajouté la **densité d'assertions** (§2.3) —
   ⛔ **ce n'est toujours pas une preuve de sémantique.**
8. ⛔ **98,0 % de couverture de lignes ne mesure PAS la force des assertions** — établi sur code réel
   (380/399 avant **et** après, +526 lignes de test, 6 mutants tués). **Aucun gate ne mesure la
   mutation** ; les campagnes de mutation de cette US ont été **écrites à la main par des auditeurs**.
9. ⛔ **La croissance de l'historique des retirées reste NON BORNÉE** (arbitrage `D-8` : « mesurer
   d'abord, borner ensuite »). **141,0 octets par retirée** (≈ 1,41 Mo à 10 000) — et le coût d'une
   écriture atomique de cette taille **sur un appareil réel n'a jamais été mesuré**.
10. ⛔ **`migration_v3_guard_criterion.py` n'est dans AUCUN workflow** — il se lance à la main. Son
    `--selftest` est **vert** (je l'ai rejoué : *« AUTOTEST OK : la garde sait rougir, et sur les
    bonnes assertions »*), mais **rien ne le rejouera en CI**. Même dette que le `selftest` d'US-00.6
    et `check_epic00_docs.py` — **une seule dette, pas trois**.
11. ⛔ **Aucune clause de la table anti-orphelin ne prouve la COMPLÉTUDE des AC** (§3.4).
12. ⛔ **Je ne certifie rien.** `🚀 OUI` appartient à `/certify`. Et le **déploiement reste
    impossible** : iOS non scaffoldé, aucun keystore, aucun build signé, aucun compte store.

---

## 9. Reproduire ce rapport

```bash
git checkout b92e0a6
python scripts/validate_trace.py --us US-01.4
python scripts/run_gates.py --all                      # 5 gates, exit 0
python scripts/run_gates.py --gate test                # À RÉPÉTER >= 4 fois (NB-2)
python scripts/check_gherkin_mapping.py
python scripts/factory_sync.py --check
python scripts/check_scb_compliance.py
flutter test test/e2e/gestes_tuile_test.dart -r expanded          # 41 tests, comptage FIABLE
flutter test reports/US-01.4/id_collision_retiree_criterion.dart  # ROUGE = NB-1/S-1 présent
flutter test reports/US-01.4/revue_id_libre_criterion.dart        # imprime l'ATTEIGNABILITÉ
python reports/US-01.4/migration_v3_guard_criterion.py --selftest
python scripts/run_gates.py --gate sast                # attendu : exit 1, LE GATE N'EXISTE PAS
```

---

## 10. Verdict

> # 🧪 **PASS** — `b92e0a6`
>
> **562 passed · 0 skipped · 0 failed**, sur **4 exécutions complètes / 4 vertes**.
> **Couverture 98,0 % (1121/1144)** contre un cliquet **LU** à **95,2** ⇒ marge **+2,8 pt**.
> **5 gates bloquants verts.** **41 scénarios sur 41 réellement exécutés** et adossés à des tests.
> **11 AC sur 11 couverts — ⛔ AUCUN AC ORPHELIN** ; **une** clause non scénarisée, **déclarée avec
> son motif** (AC-11 « Limite », clause de conception).
>
> ⛔ **Ce `PASS` est délivré AVEC les douze bornes du §8**, dont **trois** ne doivent jamais être
> lues comme des succès : **NB-1 ≡ S-1 reproduit et non corrigé**, **NB-2 non levé (1 rouge / 8)**,
> et **l'absence totale de SAST et de scan de CVE**.
> ⛔ **Il ne re-valide NI le `🧪 PASS` d'US-01.1 NI celui d'US-01.2**, dont le cœur a été modifié
> (19 fichiers de `lib/`, +1661/−147) : **leurs visas restent périmés** (§7.2).

**— @QA_Tester, contexte frais, `claude-opus-5[1m]`, 2026-09-14**
