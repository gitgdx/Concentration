# Audit de revue de code — US-01.1 — **DELTA, 2ᵉ passage**

> ⛔ Ce fichier **complète** [`code_review.md`](code_review.md) — il ne le remplace pas.
> Le 1ᵉʳ passage garde sa valeur : il portait sur le commit `24fe59a` et son verdict `FAILED`
> **reste vrai à sa date**. On **date**, on ne **repeint** pas.

| Champ | Valeur |
|---|---|
| **Agent** | @CodeReviewer — **contexte frais** |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 (2ᵉ passage) |
| **Commit précédemment audité** | `24fe59a` → **`FAILED`** (2 bloquants, 13 non bloquants) |
| **Commit audité ici** | **`6fe75df720214a9bac74efd9b6f024f7cd561407`** (`6fe75df`) |
| **Diff examiné** | `git diff 24fe59a...HEAD` — 8 fichiers, dont **2 de `lib/`** et **2 de `test/`** |

---

## ✅ VERDICT : **PASSED**

**0 bloquant · 10 non bloquants ouverts** *(dont 9 hérités et inchangés, 1 nouveau mineur)*.
**Résolus au 2ᵉ passage : B-1, B-2, N-4, N-8.**

⚠️ **Ce verdict ne repose sur aucune déclaration du développeur.** La condition de sortie §8 du 1ᵉʳ
rapport a été **rejouée verbatim**, et les deux correctifs ont en outre été soumis à **quatre mutants
supplémentaires que je n'avais pas publiés** — précisément pour qu'ils ne puissent pas avoir été
optimisés à l'avance.

---

## 1. Condition de sortie §8 — rejouée verbatim

### Étape 1 — `python scripts/run_gates.py --all` → **exit 0** ✅

```
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 28 files (0 changed) in 0.62 seconds.
✅ app.format
▶ app.analyze — (.) $ flutter analyze
No issues found! (ran in 11.9s)
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
00:05 +102: All tests passed!
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
  [HAUSSE] 95.24% (380/399) > cliquet 89.4%. Valeur a consigner (arrondie VERS LE BAS) : 95.2
✅ app.test
▶ app.deps_audit ✅   ▶ app.build → √ Built build\web ✅
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

**Attendu : exit 0. Obtenu : exit 0.** *(100 → **102 tests** · 94,1 % → **95,2 %**.)*

### Étape 2 — mutation B-1 → **attendu : ÉCHEC** ✅

Corps de `Oklab.versRgb()` remplacé par `return _depuisLineaire(_versLineaireRgb());`
*(l'écrêtage par canal qu'ADR-003 §4 interdit nommément)*, dans une **copie isolée** dont le
`flutter test` de référence rend `00:07 +102: All tests passed!`.

```
00:00 +12 -1: ... hors gamut : SEULE la chroma bouge — L et TEINTE sont préservées [E]
  Expected: a value less than <0.005>
    Actual: <0.027955360614551616>
  L doit rester constante : un écrêtage par canal la déplacerait de ~0,028 et
  casserait la garantie de contraste (ADR-003 §4)

00:00 +12 -2: ... ⛔ un hors-gamut CHAUD ne revient JAMAIS en rouge saturé [E]
  Expected: not Rgb:<#ff0000>
    Actual: Rgb:<#ff0000>

00:00 +12 -3: ... dernier recours : une L hors [0;1] sort en gris extrême, sans boucler [E]
  Expected: Rgb:<#000000>
    Actual: Rgb:<#5e0000>
```

**Attendu : ≥ 1 test rouge. Obtenu : 3.**
🔴 **Au 1ᵉʳ passage, ce même mutant rendait `00:08 +100: All tests passed!`.** La bascule est nette,
et elle est due à des **seuils serrés sur la mesure** *(`0,005` contre un `ΔL` réel de `0,0002`)*, pas
à un contournement.

📌 **Le 3ᵉ rouge est le plus instructif** : il vient du test qui couvre la **branche de dernier recours**
que j'avais signalée comme morte (N-8). Elle n'était pas seulement non couverte — elle était
**non couvrable par le corpus existant**. La couvrir a produit **un mutant-tueur de plus, gratuitement**.

### Étape 3 — grep B-1/B-2 → **attendu : NON VIDE** ✅

```
$ grep -n "barre de navigation basse" tests/features/US-01.1-affichage-hub-grille.feature
23:    Et les autres commandes de la barre de navigation basse sont non-interactives

$ grep -rn "reglage\|ajout\|Reglages\|Ajouter" lib/features/hub/ test/e2e/
lib/features/hub/presentation/hub_page.dart:90:  ajout('Ajouter une échéance', Icons.add),
lib/features/hub/presentation/hub_page.dart:91:  reglages('Réglages', Icons.settings);
test/e2e/hub_echeances_test.dart:116:      reason: 'commande « ajout » absente',
test/e2e/hub_echeances_test.dart:150:    expect(find.bySemanticsLabel('Ajouter une échéance'), findsOneWidget);
```

**L'étape Gherkin est conservée et le code la réalise** — c'était la **voie (a)** de mon rapport,
et c'est la bonne : ⛔ retirer l'exigence aurait été **adapter la spec au livrable**.

---

## 2. Mutants NON PUBLIÉS — vérification que le correctif B-2 n'est pas décoratif

Passer une condition de sortie connue à l'avance ne prouve pas grand-chose. J'ai donc éprouvé le
correctif B-2 par **trois mutants que je n'avais pas annoncés**.

| # | Mutant (copie isolée) | Attendu | Obtenu |
|---|---|---|---|
| **M5** | Les deux `_CommandeNonInteractive` **retirées** de la barre | ÉCHEC | ✅ **TUÉ** — `Expected: exactly one matching candidate / Actual: Found 0 widgets with icon "IconData(U+0E047)"` |
| **M6** | `Icon` enveloppée dans `GestureDetector(onTap: () {})` — **le faux ami exact qu'ADR-004 §3 interdit** | ÉCHEC | ✅ **TUÉ** — `Expected: no matching candidates` · `une commande hors périmètre ne doit porter AUCUN gestionnaire` |
| **M7** | `Icon` remplacée par `IconButton(onPressed: () {}, …)` | ÉCHEC | ✅ **TUÉ** — même assertion |

⛔ **M6 est le mutant qui compte.** ADR-004 §3 décide que le non-interactif s'obtient par **ABSENCE de
gestionnaire, jamais par un `onTap` vide**, au motif qu'un callback vide est *« révocable par accident »*.
Un test qui se contenterait de taper et de vérifier qu'il ne se passe rien **passerait sous M6** — le
callback vide ne fait rien, par définition. Ici l'assertion vise l'**ancêtre `GestureDetector`** : elle
distingue *« ne fait rien aujourd'hui »* de *« ne peut rien faire »*, ce qui est exactement la décision
de l'ADR. **Le correctif porte son mutant.**

### Regression check — la barre basse s'est chargée de deux widgets de plus

C'était le risque évident : `M4` du 1ᵉʳ passage avait montré que la barre **débordait de 63 px à 390 de
large et de 133 px à 320**. `grille_gabarits_test.dart` monte le **hub complet** sur **5 gabarits**
(320×568 → 1920×1080) et assène `takeException() isNull`. Les 102 tests passent ⇒ **aucune régression**,
et ce n'est pas une absence d'observation : c'est un test qui a **déjà prouvé qu'il rougit** sur ce
défaut précis.

---

## 3. N-4 — traité, et vérifié

| Mesure | 1ᵉʳ passage (`24fe59a`) | 2ᵉ passage (`6fe75df`) |
|---|---|---|
| `testWidgets` dans `test/e2e/` | 13 | 13 |
| montant la **racine** `ConcentrationApp` | **2** | **13** |
| montant `MaterialApp(home: HubPage)` | **11** | **0** *(la seule occurrence résiduelle du littéral est **dans un commentaire**, vérifié)* |

✅ **ADR-008 §1 est désormais tenu à la lettre** — *« `pumpWidget` de la racine, puis interactions »*.
L'autorisation d'écarter `integration_test/` **repose enfin sur sa contrepartie**. Le développeur a traité
ce point **sans y être contraint** ; c'était le bon arbitrage, et je le note comme tel.

`check_gherkin_mapping.py` → **exit 0** (13 ↔ 13) · `--selftest` → **exit 0** (6 assertions).

---

## 4. Couverture — recomptée, pas reprise

```
TOTAL lignes instrumentees : 399     TOTAL lignes non couvertes : 19
  2  lib/core/color/rgb.dart                       -> lignes 59,60
  1  lib/core/theme/concentration_theme.dart       -> lignes 23
  1  lib/core/theme/concentration_tokens.dart      -> lignes 14
  1  lib/features/echeances/data/sample_echeances.dart -> lignes 15
 14  lib/features/echeances/domain/remaining_time.dart -> lignes 37,39-44,46-52
```

✅ **`lib/core/color/oklab.dart` a DISPARU de la liste** — intégralement couvert. **N-8 est résolu**,
en effet de bord du correctif B-1.
⏳ **N-7 subsiste** et concentre désormais **14 des 19 lignes non couvertes** (74 %).

---

## 5. État des findings du 1ᵉʳ passage

| # | Sévérité (1ᵉʳ passage) | État au `6fe75df` | Preuve |
|---|---|---|---|
| **B-1** | 🔴 Bloquant | ✅ **RÉSOLU** | Mutation §8 → **3 tests rouges** (contre 0) |
| **B-2** | 🔴 Bloquant | ✅ **RÉSOLU** | Code + assertions ; **M5, M6, M7 tués** |
| **N-4** | 🟠 Majeur | ✅ **RÉSOLU** | 13/13 montent la racine |
| **N-8** | 🟡 Mineur | ✅ **RÉSOLU** | `oklab.dart` absent de la liste lcov |
| **N-3** | 🟠 Majeur | ⏳ **OUVERT** | **M2 rejoué au `6fe75df` → `00:03 +102: All tests passed!`** — le retrait du `FittedBox` reste indétecté |
| **N-1** | 🟠 Majeur | ⏳ OUVERT | ADR-004 §4 : `registre.actif` toujours sans appelant dans `lib/` |
| **N-2** | 🟡 Mineur | ⏳ OUVERT — **et plus visible** | `_CommandeBarre` porte désormais un champ `icone`… que `PracticeModule` n'a toujours pas |
| **N-5** | 🟠 Majeur | ⏳ OUVERT | Divergences sémantiques scénario ↔ test (« 8 mois 12 jours → 9 » testé comme « 5 h 10 → 6 ») |
| **N-6** | 🟠 Majeur | ⏳ OUVERT | `depuisDonnee` toujours sans appelant ; critère de test nº 9 absent |
| **N-7** | 🟡 Mineur | ⏳ OUVERT | 14 lignes, 0 test, 0 appelant |
| **N-9 / N-10 / N-11 / N-12** | 🟡 Mineurs | ⏳ OUVERTS | Inchangés |
| **N-13** | ⚠️ Action humaine | ⏳ OUVERT — **valeur changée** | Le cliquet à consigner passe de **94,0** à **95,2** |

### Nouveau finding — non bloquant

| # | Fichier | Problème | Solution |
|---|---|---|---|
| **O-1** | `lib/app/app.dart` — `ConcentrationApp({… this.echeances})` | Paramètre de l'API **de production** dont le **seul appelant est le test** *(en production il vaut toujours `null` ⇒ `SampleEcheances`)*. C'est le prix payé pour tenir ADR-008 §1, et il est **modeste** : même forme que `clock`, déjà accepté. | **Aucune action requise.** À revoir en **US-01.2**, quand la source de données deviendra réelle : `echeances` et `clock` devraient alors devenir une **seule** dépendance injectée, plutôt que deux paramètres facultatifs. |

---

## 6. Réponse à la question posée : « lesquels tiens-tu pour bloquants au second passage ? »

**Aucun. Zéro.** Les dix findings ouverts restent **non bloquants**, exactement au même rang qu'au 1ᵉʳ
passage.

⛔ **Je ne déplace pas mes critères entre deux passages.** Bloquant = erreur lint/typecheck · duplication
manifeste · N+1 · code neuf sans test · AC non couvert par le code. B-1 relevait du **quatrième**
*(la décision d'ADR-003 §4 était supprimable sans qu'aucun test ne rougisse)* et B-2 du **cinquième**.
Aucun des dix restants n'entre dans ces cases — et **requalifier maintenant un finding que j'ai
moi-même classé non bloquant hier reviendrait à adapter la règle au résultat**, ce qu'ADR-008 refuse
explicitement pour le choix de track. La règle vaut aussi pour l'auditeur.

**Priorité recommandée, à titre consultatif — ce n'est pas une condition de fusion :**

1. **N-3** — le seul finding ouvert avec une **preuve de mutation active** *(M2 survit encore)*. Un
   `expect` d'inclusion du rectangle du nombre dans celui de la tuile au gabarit 320×568 coûte ~5 lignes.
2. **N-5** — corriger les données de trois tests pour qu'elles soient celles de leurs scénarios : coût
   quasi nul, et cela **rend vraie** la correspondance que T12b ne peut que supposer.
3. **N-1 et N-6** — les deux vrais sujets d'architecture, **naturellement portés par US-01.2** *(un 2ᵉ
   module actif rendra N-1 concret ; une source de données réelle rendra N-6 concret)*. ⚠️ Les
   **inscrire** au Story File d'US-01.2 plutôt que les traiter ici.
4. **N-7, N-9, N-10, N-11, N-12, O-1** — candidats à une US de dette.

⚠️ **À l'attention de @QA_Tester** : **N-11** *(RNF-02, « prêt au regard » < 500 ms)* n'est **toujours ni
mesuré ni testé**. ⛔ La case correspondante ne doit pas être cochée sur la foi d'une impression.

---

## 7. Ce que ce 2ᵉ passage N'ATTESTE PAS

- ⛔ **Aucun rendu visuel observé** ; toujours aucune exécution sur appareil ou navigateur réel.
- ⛔ **Le périmètre examiné est le DELTA** `24fe59a…6fe75df` *(8 fichiers)*, plus la **réexécution
  intégrale** des gates et du corpus de tests. Je n'ai **pas** re-relu ligne à ligne les 3913 lignes du
  1ᵉʳ passage : leur audit **reste celui de `code_review.md`**.
- ⛔ **`EVT_SECURITY_AUDIT_PASSED` a été émis le 2026-08-02 à 09:05:47** par @CyberSecurity **sur le
  commit `24fe59a`**, donc **avant** les modifications de `6fe75df`. ⚠️ **Ce n'est pas mon rôle de
  l'arbitrer**, mais je le **signale** : deux fichiers de `lib/` ont changé depuis. Les changements sont
  *a priori* sans surface de sécurité *(une icône inerte, un paramètre facultatif, des seuils de test)* —
  **à @CyberSecurity de dire si son visa tient**, pas à moi.
- ✅ **Contrôle d'intégrité effectué** : aucun `EVT_CODE_REVIEW_PASSED` n'a été auto-émis entre les deux
  passages. Les seuls événements ajoutés sont `EVT_SECURITY_AUDIT_PASSED` *(cyber-security)* et mon
  propre `EVT_CODE_REVIEW_FAILED`. **La séparation des pouvoirs a tenu.**
- ⛔ **Le verdict porte sur le commit `6fe75df`.** Toute modification ultérieure exige un nouveau passage.

---

## 8. Condition de sortie — pour un éventuel 3ᵉ passage

Inchangée dans son principe. Le corpus de contrôle s'est enrichi : **les mutants M1, M5, M6, M7 doivent
rester tueurs**, et **M2 doit le devenir** si N-3 est traité.

```bash
python scripts/run_gates.py --all          # attendu : exit 0
python scripts/check_gherkin_mapping.py    # attendu : exit 0
python scripts/check_gherkin_mapping.py --selftest

# En copie isolée, chacun de ces mutants DOIT rendre la suite rouge :
#  M1 : corps de Oklab.versRgb() -> return _depuisLineaire(_versLineaireRgb());   [3 rouges]
#  M5 : retirer les _CommandeNonInteractive de _BarreModules                       [1 rouge]
#  M6 : envelopper l'Icon d'un GestureDetector(onTap: () {})                       [1 rouge]
#  M7 : remplacer l'Icon par un IconButton(onPressed: () {})                       [1 rouge]
#  M2 : retirer le FittedBox de echeance_tile.dart  -> AUJOURD'HUI VERT (N-3)
```

---

## 9. Traçabilité

| Élément | Valeur |
|---|---|
| **Événement émis** | `EVT_CODE_REVIEW_PASSED` |
| **Commit couvert** | `6fe75df720214a9bac74efd9b6f024f7cd561407` |
| **Exécutions** | `run_gates.py --all` → exit 0 (102 tests, 95,2 %) · `check_gherkin_mapping.py` (+`--selftest`) → exit 0 · **6 mutations** en copie isolée → **5 tuées, 1 survivante (M2 / N-3, non bloquante)** · recompte lcov · greps §8 |
| **Dépôt modifié ?** | **NON** — aucune écriture hors `reports/US-01.1/` et `docs/trace/US-01.1/` |
| **SCB modifié ?** | **NON** — mise à jour par le rituel `/audit-us` |
