# US-00.6 · Revue de **DELTA** — badge porté à `62a4fcc`

> **Modèle** : `claude-opus-5[1m]` · **Date** : 2026-08-01 · **HEAD audité** : **`62a4fcc`**
> **Badge précédent** : `9ae8631` · **Delta de code** : `selftest_coverage_ratchet.py` **+41/−2** +
> `tests/fixtures/US-00.6/sous_plancher_15_sur_19.info` *(nouvelle)*
> **Rapports antérieurs, aucun écrasé** : [`code_review.md`](code_review.md) *(FAILED)* ·
> [`code_review_reaudit.md`](code_review_reaudit.md) *(PASSED)* · [`code_review_final.md`](code_review_final.md) *(PASSED)*
> ⛔ **Dépôt non modifié** — `git status --porcelain` **vide**, y compris après le plantage de **mon
> propre** harnais *(§4)*. Mutants sur **copies**, restauration vérifiée : `True`.

---

## ✅ VERDICT : **PASSED** — le badge `✅ 🔍` **porte sur `62a4fcc`**

| | |
|---|---|
| 🔴 Bloquants | **0** |
| 🟠 Non bloquants | **2** *(RD-1, RD-2)* + 3 remarques mineures → **versés en dette à US-00.8**, conformément au gel |
| 🎯 Mutants de ce passage | **9** → **7 tués, 2 survivants**, tous deux de familles **déjà nommées** |
| ✅ Mes 5 survivants du passage précédent | **TOUS TUÉS**, et **chacun par le bon mécanisme** |

---

## 1. Les 5 survivants que j'avais laissés sont **morts** — et par la bonne barrière

| Mutant *(injecté dans le checker, sur copie)* | Avant | **Maintenant** | Tué par |
|---|---|---|---|
| **Q3a** plafond 90 dans `read_ratchet` — *le cas **SILENCIEUX*** | survivait | ✅ **VU** | `ECHEC \| DIFFERENTIEL : la sortie ne porte pas « seuil requis : 95.0% »` |
| **Q3b** plafond 90 dans `main` | survivait | ✅ **VU** | même assertion |
| **Q4** rabot multiplicatif ×0,99 | survivait | ✅ **VU** | l'assertion, **sur les deux branches** *(86 et 95)* |
| **Q6** plancher forcé à `0` — *mon RF-2* | survivait | ✅ **VU** | `ECHEC \| PLANCHER SEUL sous_plancher_15_sur_19.info exit attendu=1 obtenu=0` |
| **Q7** cliquet ignoré au-delà de 90 | survivait | ✅ **VU** | l'assertion |

⇒ **la famille D-4 telle que je l'avais caractérisée** *(toute `f` avec `f(86) ≤ 89,47 < f(95)`)* **est
éteinte**, y compris son membre **silencieux**, celui dont la mesure avait réfuté la prémisse du report.
Et **RF-2 est comblé par le cas qui le devait** : le plancher **décide enfin**.

**La nouvelle fixture est saine, et c'est un point que je vérifie systématiquement** : `sous_plancher_15_sur_19`
déclare `LF:19 / LH:15` — **cohérente** ⇒ elle est refusée **par le plancher**, *pas* par le contrôle des
totaux. Exécuté, clé absente : `seuil requis : 80.0% (plancher contractuel)` puis
`[ERREUR] RÉGRESSION : 78.95% < 80.0% (plancher contractuel)`. **Elle rougit pour la bonne raison** — à la
différence de `zero_ligne_mesurable`, qui rougissait par le pourcentage.

## 2. Pas de faux rouge introduit — vérifié, pas supposé

| Contrôle | Résultat |
|---|---|
| Autotest sous 4 encodages *(non défini / `ascii` / `cp437` / `cp1252`)* | **`EXIT=0`** partout — la chaîne assertionnée est **pure ASCII**, donc insensible au fait que le parent décode en UTF-8 ce que l'enfant écrit en `cp1252` |
| `run_gates --gate test` *(gate REQUIS)* · `factory_sync --check` · `check_scb_compliance` · `validate_trace --all` · `py_compile` | **`EXIT=0`** |
| Autotest complet | **`EXIT=0`** — « **les 9 assertions sont tenues, dont 5 REFUS** » |
| `git diff 9ae8631..HEAD` sur `.github/`, `check_flutter_coverage.py`, `factory.config.json`, README, autres fixtures | **vide** ⇒ **le checker lui-même n'a pas bougé**, ni la CI, ni la source unique |

⇒ **le delta n'ajoute que du contrôle**, dans un gate requis, **sans toucher au produit contrôlé**. C'est
la forme la moins risquée possible pour ce genre de correctif.

## 3. Les **2 survivants** — familles déjà nommées, versés à **US-00.8**

| # | `[Fichier:Ligne]` | Problème | Solution **mesurée** |
|---|---|---|---|
| **RD-1** | `[scripts/selftest_coverage_ratchet.py:148-156]` | L'assertion lie la sortie à la **référence**, **pas à la DÉCISION**. Mutant `R1` : `if pct < min(required, 90.0)` — la ligne imprimée porte bien `seuil requis : 95.0%` *(assertion satisfaite)* alors que **la comparaison applique 90** ⇒ **survit**. ⚠️ **Théorie du résidu, pour ne pas le sous-décrire** : une transformation qui est **l'identité sur le domaine testé** est **indétectable par construction** — pour attraper un plafond `c`, il faut une référence **> c** **et** une couverture **entre `c` et la référence** | **Une branche de plus au différentiel, sans nouvelle fixture** : `hausse_18_sur_19.info` *(94,74 %)* à **ref 95**, exit attendu **1**. **Mesuré** : `sain=1`, `R1=0` ⇒ **détecté**. *(La branche actuelle, à 89,47 %, ne peut pas le voir : `sain=1`, `R1=1`.)* |
| **RD-2** | `[scripts/check_flutter_coverage.py:166]` · `[selftest:44-50]` | Le **label du seuil violé** *(`(cliquet)` / `(plancher contractuel)`)* reste **non assertionné** : mutant `R4` *(`source = "seuil"`)* **survit**. C'est l'exigence **AC-4** « *le message dit **lequel** est violé, jamais « seuil » * » — tenue par le **code**, **non protégée** par le contrôle | assertionner le label dans **un** cas cliquet et **un** cas plancher *(2 lignes ; les deux cas existent déjà)* |

**Remarques mineures, même sort** *(dette, pas correctif)* :
`[selftest:196]` `total_assertions = len(CAS) + 1 + 2` — le `+ 1 + 2` est un **littéral qui recopie la
structure** : ajouter un 3ᵉ cas « plancher seul » le laisserait périmé *(même classe que RF-4, forme
atténuée ; un compteur incrémenté à chaque assertion serait dérivé pour de bon)* ·
`[selftest:140-156]` l'assertion **présuppose** que les deux références dépassent `PLANCHER` — relever
`PLANCHER` au-dessus de `86.0` produirait un **faux rouge** du contrôle lui-même ·
`[selftest:154-170]` un même défaut peut incrémenter `echecs` **jusqu'à 3 fois** *(cosmétique : le nombre
d'« attentes non tenues » surestime le nombre de causes)*.

⛔ **Aucun de ces cinq points ne peut produire un faux vert dans le code LIVRÉ** — c'est le critère que
j'applique depuis le premier audit, et je ne le change pas maintenant qu'il conclut en faveur du livrable.
**Ton gel est donc compatible avec mon verdict** : je ne demande **aucune** correction.

## 4. Symétrie — ce que **mon** instrument a fait dans ce passage

**Mon harnais de mutation a planté**, à sa première exécution, en imprimant un `U+FFFD` sur une console
`cp1252` : **exactement la classe de bug que cette US a corrigée le 2026-07-31**, et que j'ai vérifiée deux
fois chez toi. Pire, **il n'avait pas de `try/finally`** : le plantage a laissé un **mutant vivant** dans la
copie de travail, et le banc suivant a échoué sur un ancrage introuvable — **un instrument qui ne se
restaure pas est un instrument qui ment au coup d'après**. *(Le **dépôt** est resté intact — vérifié
immédiatement : `git status --porcelain` **vide**.)* J'ai appliqué à mon harnais **les deux** remèdes qu'il
audite : la **garde d'encodage** et la **restauration en `finally`**.
⇒ La conclusion de la QA — *« la dette de méthode atteint les deux côtés du contrôle »* — se vérifie une
fois de plus, et cette fois **de mon côté, dans ce passage-ci**.

## 5. Bornes

1. **Ce badge porte sur le CODE de `62a4fcc`** *(`*.py`, `*.info`)*. ⛔ **Je n'ai pas re-audité le
   documentaire** — la QA l'a couvert et je ne prends pas son verdict à mon compte.
2. **CI non exécutée** *(`actionlint` absent de ce poste)* : ici sans objet, **`.github/` n'a pas bougé**.
3. **Mutants finis** : **9** ce passage, **32** sur l'US. **Aucune exhaustivité.** Le compte des quatre
   passages reste le meilleur argument contre la confiance : **B-1** trouvé par un mutant que personne
   n'avait écrit · **+3** au re-audit · **+1** par la QA, que j'avais manqué · **+1** *(RF-2)* que personne
   n'avait vu · **+2** ici. **La courbe décroît, elle n'est pas nulle.**
4. **Le produit n'a pas grandi d'une ligne** : `check_flutter_coverage.py` est **inchangé** depuis mon
   avant-dernier badge. **19 lignes, 1 fichier, aucune couverture de branches, marge 1 ligne → 0.** Le
   cliquet **ne monte jamais seul** et **rien ne détecte sa péremption**.
5. **Restent mes deux conditions de certification**, hors de ma main : la **dette de l'amendement de
   l'Art. 4** inscrite dans le corpus **durable**, et l'écart **`verify.sh`**.
6. ✅ **Les deux badges doivent se poser ensemble sur `62a4fcc`** — c'est fait dans le bon ordre, et cela
   referme le trou que la QA avait nommé.

## 6. Rejouabilité

```python
# 9 mutants (sur copie, avec garde d encodage ET restauration en finally) :
A_READ='    try:\n        value = float(node["value"])' ; A_MAIN="    required = max(args.min, ratchet) if ratchet is not None else args.min"
A_CMP ="    if pct < required:"                          ; A_SRC =' source = "cliquet" if (ratchet is not None and ratchet >= args.min) else "plancher contractuel"'
Q3a A_READ -> 'value = min(float(node["value"]), 90.0)'            # VU (assertion de sortie)
Q3b A_MAIN -> "ratchet = min(ratchet, 90.0) ..." + A_MAIN          # VU (assertion)
Q4  A_READ -> 'value = float(node["value"]) * 0.99'                # VU (assertion, 2 branches)
Q6  A_MAIN -> "args.min = 0.0\n" + A_MAIN                          # VU (PLANCHER SEUL) <- RF-2 comble
Q7  A_READ -> 'value = value if value <= 90.0 else 0.0'            # VU (assertion)
R1  A_CMP  -> "    if pct < min(required, 90.0):"                  # SURVIT -> RD-1
R2  A_CMP  -> "    if pct < args.min:"                             # VU
R3  A_MAIN -> "args.min = ... if ratchet is not None else 0.0"     # VU
R4  A_SRC  -> '    source = "seuil"'                               # SURVIT -> RD-2
```

```sh
# efficacite MESUREE du correctif RD-1, avant de le proposer :
#   branche existante (inchange 89,47 %, ref 95) : sain=1 R1=1 -> SURVIT
#   branche proposee  (hausse   94,74 %, ref 95) : sain=1 R1=0 -> DETECTE
# faux rouge : autotest sous PYTHONIOENCODING non defini / ascii / cp437 / cp1252 -> EXIT=0 partout
# coherence des 7 fixtures : LF/LH recalcules ; sous_plancher_15_sur_19 = 15/19, LF:19 LH:15, coherent
```

---

## 7. Décision

**PASSED — le badge `✅ 🔍` porte sur `62a4fcc`.** Les cinq survivants que j'avais laissés sont **tués,
chacun par la barrière prévue**, la famille **D-4 est éteinte y compris dans son membre silencieux**, et
**RF-2 est comblé par un cas qui rougit pour la bonne raison**. **Aucun faux rouge n'est introduit**, et le
**checker n'a pas bougé d'une ligne**. Les **deux survivants restants** appartiennent à des familles déjà
nommées, **ne peuvent pas produire de faux vert dans le code livré**, et sont **versés à US-00.8** —
**je ne demande aucune correction**, ton gel tient.

> ⛔ Ce rapport ne coche aucune case du SCB, ne modifie ni le code, ni le Story File, ni `CLAUDE.md`, et
> n'écrase aucun rapport antérieur.
