# Audit de revue de code — US-01.4 « Gestes sur la tuile » (RF-06)

> **Verdict : ✅ PASSED**
> **Commit audité : `8509f44acfcc532918c53f3d12a5333d55e030b7` — soit `8509f44`** *(NB-6 : un visa
> non rattaché à un commit périme en silence ; l'incident d'US-01.1 — 73 lignes de `lib/` vues par
> aucun audit — vient de là)*.
> Branche `feat/US-01.4-gestes-tuile`, **28 commits** contre `origin/main` *(**LU** :
> `git rev-list --count origin/main..HEAD`)*. Auditeur : **@CodeReviewer**, contexte frais, modèle
> **claude-opus-5[1m]**. Date : **2026-09-11**.
>
> **Findings : 0 BLOQUANT · 2 non bloquants de sévérité HAUTE · 3 suggestions.**
> ⛔ **Aucun finding non bloquant ne fonde ce verdict** *(règle du rôle : seuls lint/typecheck,
> duplication manifeste, N+1, code sans test et AC non couvert justifient un `FAILED`)*.

---

## 0. Convention de désignation — ⛔ pourquoi il n'y a AUCUN numéro de ligne ici

Le gabarit du rôle demande `[Fichier:Ligne]`. **Il n'est pas suivi à la lettre, et c'est délibéré** :
la leçon `corpus_sweep.md` d'US-00.7 est ⛔ *« ne jamais désigner une assertion par son NUMÉRO DE
LIGNE — il glisse en silence et la couverture cesse de couvrir sans qu'aucun outil ne le signale »*.
Chaque finding désigne donc **le fichier et l'ANCRE TEXTUELLE** *(la chaîne exacte à `grep`)*, ce qui
reste vrai après n'importe quel remaniement. **L'écart au gabarit est ici nommé, pas silencieux.**

---

## 1. Périmètre réellement audité

| Élément | Valeur — **LUE**, jamais recopiée |
|---|---|
| Diff | `git diff main...HEAD` — **71 fichiers**, `17441` insertions, `232` suppressions |
| `lib/` touché | 19 fichiers *(`git diff --name-only main...HEAD -- lib/`)* |
| `test/` + `tests/` touchés | 28 fichiers |
| Fichiers d'enforcement touchés | **AUCUN** — `git diff --name-only main...HEAD \| grep -E "^\.github/\|^\.claude/\|\.env\|githooks\|protect_files\|factory\.config\.json"` rend une **sortie vide** |
| `scripts/` touché | `scripts/check_gherkin_mapping.py` **seul** *(inscription du 3ᵉ couple, T15)* |

### Règles dures du projet — vérifiées **par commande**

```
$ for c in $(git rev-list origin/main..HEAD); do \
    git log -1 --format=%B $c | grep -qE "^US: US-01\.4" || echo "SANS: $(git log -1 --format='%h %s' $c)"; done
(sortie vide — les 28 commits portent le trailer)

$ git diff main...HEAD -- PROJECT_LOG.md | grep -c "^+|"
30

$ for c in $(git rev-list origin/main..HEAD); do L=...grep -c "^lib/"; T=...grep -c "^test/"; \
    [ "$L" -gt 0 ] && [ "$T" -eq 0 ] && echo "$c"; done
(sortie vide — AUCUN commit ne touche lib/ sans toucher test/)
```

➡️ **Le « cliquet à marge nulle » a été tenu à la lettre** : *aucun* commit ne livre du code de
production sans ses tests. C'est la contrainte ① des règles d'exécution, et elle est **mesurée**,
pas supposée.

### Ordre contraint des tâches — vérifié **par commande**, ⛔ pas par la lecture des cellules

```
$ git merge-base --is-ancestor <commit T7 : "cleFond"> <commit T8 : "FocusableActionDetector">
exit 0   -> T7 (correctif NB-7) est bien ANCÊTRE de T8 (enveloppe interactive)

$ git merge-base --is-ancestor <commit T14 : creation de test/e2e/gestes_tuile_test.dart> \
                              <commit T15 : inscription du couple dans COUPLES>
exit 0   -> T14 precede T15, le job requis n'a jamais pu etre rouge par construction
```

---

## 2. Gates statiques — sorties RÉELLES

> ⚠️ **`lint` et `typecheck` N'EXISTENT PAS comme noms de gate sur cette stack** — constaté, pas
> supposé : `run_gates.py --gate lint` rend `[ERREUR] aucun gate ne correspond`. `run_gates.py --list`
> nomme les cinq gates réels ; **`flutter analyze` porte à lui seul le lint ET le typage** *(analyseur
> Dart)*, `dart format --set-exit-if-changed` porte le style. **Ce sont eux qui ont été exécutés.**

```
$ python scripts/run_gates.py --gate format
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 74 files (0 changed) in 1.01 seconds.
✅ app.format
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate analyze
Analyzing Concentration...                                      
No issues found! (ran in 24.0s)
✅ app.analyze
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate test   (extrait : fin de sortie)
05:55 +560 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/e2e/gestion_echeances_test.dart: Une suppression qui ne peut pas être écrite laisse l'échéance en place
06:04 +561 -1: Some tests failed.

Failing tests:
  C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le message d'échec du retrait, sur le hub 🔴 AC-11 « Nominal » — l'écriture ÉCHOUE : le message S'AFFICHE, avec le texte DU PORT, et la tuile RESTE
❌ app.test (exit 1)
————————————————————————————————————————
GATES EN ÉCHEC (1) : app.test
```


### 2.1 🔴 Le gate `test` a rendu **UN ROUGE INTERMITTENT** — mesuré, et il est dans ce rapport

La sortie ci-dessus est **celle d'une exécution RÉELLE, non expurgée** : à la **2ᵉ** des quatre
exécutions de la suite complète faites pendant cet audit, `app.test` est passé **rouge**, sur
`hub_message_ecriture_test.dart` / **AC-11 « Nominal »**. ⛔ **Ce n'est pas une contamination de mes
mutants** : `git diff --stat -- lib/ test/ scripts/` rend une **sortie vide** au moment du rouge.

**Taux mesuré sur ce commit, cette machine : 1 rouge sur 4 exécutions de la suite complète.**
Les trois autres rendent `562` tests verts. **Le même fichier, lancé SEUL : 6 verts sur 6.**

```
$ flutter test   (execution nº 3 de la suite complete, capture integrale)
05:35 +562: All tests passed
exit=0

$ flutter test   (execution nº 4)
05:38 +562: All tests passed
exit=0

$ for i in 1..6; flutter test test/features/hub/presentation/hub_message_ecriture_test.dart
essai 1 : +9: All tests passed
essai 2 : +9: All tests passed
essai 3 : +9: All tests passed
essai 4 : +9: All tests passed
essai 5 : +9: All tests passed
essai 6 : +9: All tests passed
```


⚖️ **Confondant NOMMÉ, ⛔ pas écarté** : deux autres audits tournaient en parallèle sur la même
machine *(leurs artefacts sont visibles en `?? reports/US-01.4/…`)*, dont un instrument qui écrit des
documents de ~1,4 Mo et **chronomètre des écritures atomiques**. La contention disque est une cause
plausible — ⛔ **elle n'est pas prouvée, et je ne la présente pas comme acquise**.

**Ce que dit le corpus, et qui rend ce rouge NON SURPRENANT** : la docstring de `reglerEcritures`
*(`test/support/magasin_temporaire.dart`)* raconte **ce rouge exact** — *« puis — après un premier
correctif incomplet — sur `hub_message_ecriture_test.dart` (AC-11 « Nominal » : `Expected: true` puis
`Actual: <false>`) »* — et le remède appliqué le 2026-09-08 a été de porter `tours` de **40 à 200**.
➡️ **Ma mesure établit que 200 ne suffit pas sous charge concurrente.** Voir finding **NB-2**.

---

## 3. Audit par MUTATION — ⛔ pas par le chiffre de couverture

**Motif, et il est acquis sur ce projet** : *la couverture de lignes est AVEUGLE à la force des
assertions* — `380/399` avant **et** après, pour `+526` lignes de test et 6 mutants tués (US-01.1).
La couverture de `98,08 %` ci-dessus **n'est donc PAS mon instrument** : elle atteste seulement que le
dénominateur n'a pas régressé.

**19 mutants joués sur le code de PRODUCTION, un par point de conception nommé par le design.**
Protocole : sauvegarde du fichier → substitution d'une chaîne **unique** *(le harnais refuse et
n'exécute rien si le motif apparaît ≠ 1 fois)* → exécution des fichiers de test ciblés → **restauration
systématique en `finally`**. Le nombre de tests rouges est **LU** dans la sortie de `flutter test`.

**Résultat : 19 joués, 19 TUÉS, 0 survivant, 0 mutant non applicable.**
⛔ **Aucun point de conception nommé par le Story File n'est protégé par une assertion faible.**

```
[TUE] M-A  NB-7 rejoue : la tuile rend une couleur CONSTANTE
    cible : lib/features/echeances/presentation/widgets/echeance_tile.dart
    exit=1  tests rouges (LU) = 4
    ligne finale : 00:21 +27 -4: Some tests failed.
      rouge> 00:17 +0 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/support/rendu_couleur_test.dart: ⛔ CONTRÔLE POSITIF — sans seconde boî
      rouge> 00:17 +0 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/support/rendu_couleur_test.dart: 🔴 avec une SECONDE boîte décorée, la 
      rouge> 00:17 +2 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: AC-5 
      rouge> 00:18 +3 -4: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: AC-5 
[TUE] M-B  G-7 : BoxFit.contain au lieu de scaleDown
    cible : lib/features/echeances/presentation/widgets/echeance_tile.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:17 +24 -2: Some tests failed.
      rouge> 00:15 +6 -1: AC-1 (US-01.4) — le nombre en cadran sur les ACTIVE 🔴 CONTRÔLE NÉGATIF — sur une ÉCHUE le nombre reste en HAUT À GAUCHE (R-8) [
      rouge> 00:15 +6 -2: AC-1 (US-01.4) — le nombre en cadran sur les ACTIVE 🔴 la taille PEINTE ne dépend PAS du nombre de chiffres — le mutant BoxFit.c
[TUE] M-C  D-4 : la presence testee par NULLITE et non containsKey
    cible : lib/features/echeances/domain/echeance.dart
    exit=1  tests rouges (LU) = 3
    ligne finale : 00:40 +51 -3: Some tests failed.
      rouge> 00:13 +10 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/echeance_retiree_test.dart: ADR-012 §3 — la
      rouge> 00:14 +18 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/data/echeance_codec_retiree_test.dart: LECTURE — l
      rouge> 00:14 +18 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/data/echeance_codec_retiree_test.dart: LECTURE — l
[TUE] M-D  ADR-012 2.3 : le codec ne RETIRE plus la cle d'origine
    cible : lib/features/echeances/data/echeance_document_codec.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:24 +52 -2: Some tests failed.
      rouge> 00:13 +23 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/data/echeance_codec_retiree_test.dart: ÉCRITURE — 
      rouge> 00:16 +40 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/data/echeance_migration_v3_test.dart: ⚖️ OÙ un `fa
[TUE] M-E  C-7/T1 : le filtre unique cesse de filtrer
    cible : lib/features/echeances/domain/echeance_etat.dart
    exit=1  tests rouges (LU) = 5
    ligne finale : 01:04 +86 -5: Some tests failed.
      rouge> 00:14 +28 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/validation_echeance_test.dart: AC-5 — limit
      rouge> 00:28 +79 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_grille_presentes_test.dart: 🔴 une échéa
      rouge> 00:29 +80 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_grille_presentes_test.dart: ⛔ l’échéanc
      rouge> 00:50 +84 -4: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 01:04 +86 -5: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
[TUE] M-F  C-3 : un appui SIMPLE retire une echue (2 gestes / surface)
    cible : lib/features/echeances/presentation/widgets/echeance_tile.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:16 +62 -2: Some tests failed.
      rouge> 00:14 +11 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
      rouge> 00:14 +20 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
[TUE] M-G  AC-11/C-6 : l'animation part AVANT l'issue de l'ecriture
    cible : lib/features/echeances/presentation/echeances_grid.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:12 +36 -2: Some tests failed.
      rouge> 00:11 +25 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/grille_retrait_test.dart: T10 — l’ani
      rouge> 00:11 +28 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/grille_retrait_test.dart: T10 — l’ani
[TUE] M-H  AC-11 N : l'echec d'ecriture redevient SILENCIEUX
    cible : lib/features/hub/presentation/hub_page.dart
    exit=1  tests rouges (LU) = 6
    ligne finale : 00:44 +43 -6: Some tests failed.
      rouge> 00:16 +18 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 00:20 +41 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 00:27 +42 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 00:30 +42 -4: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 00:37 +42 -5: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
      rouge> 00:40 +42 -6: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
[TUE] M-I  C-7/AC-4 : le hub repasse a la liste COMPLETE
    cible : lib/features/hub/presentation/hub_page.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:48 +47 -2: Some tests failed.
      rouge> 00:12 +1 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_grille_presentes_test.dart: 🔴 une échéan
      rouge> 00:34 +44 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/hub/presentation/hub_message_ecriture_test.dart: T19 — le me
[TUE] M-J  AC-6 E : le message de la limite cesse d'etre CONDITIONNEL
    cible : lib/features/echeances/domain/validation_echeance.dart
    exit=1  tests rouges (LU) = 3
    ligne finale : 00:21 +39 -3: Some tests failed.
      rouge> 00:21 +24 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/validation_echeance_test.dart: AC-5 — limit
      rouge> 00:21 +26 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/validation_echeance_test.dart: AC-5 — limit
      rouge> 00:21 +26 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/validation_echeance_test.dart: AC-5 — limit
[TUE] M-K  AC-2 L : un nouvel appui ne REDEMARRE plus la fenetre
    cible : lib/features/echeances/presentation/echeances_grid.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:13 +37 -1: Some tests failed.
      rouge> 00:11 +25 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/echeances_grid_test.dart: T9 — la rév
[TUE] M-L  AC-8 L : la garde « un seul retrait a la fois » disparait
    cible : lib/features/echeances/presentation/echeances_grid.dart
    exit=1  tests rouges (LU) = 2
    ligne finale : 00:18 +36 -2: Some tests failed.
      rouge> 00:17 +27 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/grille_retrait_test.dart: T10 — l’ani
      rouge> 00:17 +27 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/grille_retrait_test.dart: T10 — l’ani
[TUE] M-M  AC-9 N : la tuile cesse d'etre ANNONCEE actionnable
    cible : lib/features/echeances/presentation/widgets/echeance_tile.dart
    exit=1  tests rouges (LU) = 4
    ligne finale : 00:13 +35 -4: Some tests failed.
      rouge> 00:12 +15 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
      rouge> 00:12 +16 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
      rouge> 00:12 +18 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
      rouge> 00:12 +26 -4: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/widgets/echeance_tile_test.dart: T8 —
[TUE] M-N  tear-off : EtapeMigration(3, up, up) => identical(up,down)
    cible : lib/features/echeances/data/echeance_schema_migrations.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:14 +53 -1: Some tests failed.
      rouge> 00:12 +29 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/data/echeance_migration_v3_test.dart: ADR-005 §1 —
[TUE] M-O  I-1 : `retiree` sort de l'egalite par valeur
    cible : lib/features/echeances/domain/echeance.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:27 +91 -1: Some tests failed.
      rouge> 00:11 +1 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/domain/echeance_retiree_test.dart: ADR-012 §1 — le 
[TUE] M-P  §6.2 r2 : l'anneau de focus s'allume AU DOIGT
    cible : lib/features/echeances/presentation/widgets/echeance_tile.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:15 +38 -1: Some tests failed.
      rouge> 00:11 +1 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/accessibilite_grille_test.dart: T11 — 
[TUE] M-Q  AC-2 N : la revelation ne se REFERME plus
    cible : lib/features/echeances/presentation/echeances_grid.dart
    exit=1  tests rouges (LU) = 3
    ligne finale : 00:19 +35 -3: Some tests failed.
      rouge> 00:18 +24 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/echeances_grid_test.dart: T9 — la rév
      rouge> 00:18 +29 -2: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/echeances_grid_test.dart: T9 — la rév
      rouge> 00:18 +31 -3: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/echeances_grid_test.dart: T9 — la rév
[TUE] M-R  AC-8 E : « animations reduites » cesse d'etre honore
    cible : lib/features/echeances/presentation/echeances_grid.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:15 +37 -1: Some tests failed.
      rouge> 00:13 +17 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/grille_retrait_test.dart: T10 — l’ani
[TUE] M-S  AC-7 N : la marque redevient « un mot / rien »
    cible : lib/features/echeances/presentation/widgets/ligne_echeance.dart
    exit=1  tests rouges (LU) = 1
    ligne finale : 00:21 +19 -1: Some tests failed.
      rouge> 00:16 +6 -1: C:/Users/guillaume.decroix/MesProjets/Concentration/test/features/echeances/presentation/marque_gestion_test.dart: T12 — la mar
```


> ⚠️ **Borne de MA campagne, à lire avec elle** : 19 mutants ne sont pas une couverture de mutation.
> Ils échantillonnent **les points que le design a nommés comme dangereux**, pas l'ensemble du diff.
> ⛔ **Un mutant tué ne prouve rien sur ce qui n'a pas été muté.** Et le harnais a été **restauré et
> vérifié** : `git diff --stat -- lib/` rend une sortie **vide** après la campagne.

### 3.1 Ce que la campagne établit, point par point *(les cinq faits que le design exigeait)*

| Point nommé par le design | Mutant | Verdict | Ce que cela prouve |
|---|---|---|---|
| **T1 — le prédicat « est échue » en UN exemplaire** | `M-E` | tué *(5 rouges)* | Le filtre unique est **réellement partagé** par la grille **et** la limite de 9 |
| **NB-7 / T7 avant T8 — la boîte par IDENTITÉ** | `M-A` | tué *(4 rouges)* | Le faux vert historique *(« toujours orange, 112 tests verts »)* **rougit désormais**, y compris dans `rendu_couleur_test.dart` qui le **rejoue à chaque `flutter test`** |
| **⛔ pas `BoxFit.contain`** | `M-B` | tué *(2 rouges)* | L'assertion qui tue est *« la taille PEINTE ne dépend PAS du nombre de chiffres »* — une **assertion de GRANDEUR**, ⛔ pas une égalité au token |
| **Migration `v2 ⇄ v3`** | `M-D`, `M-N` | tués | ⛔ **Revue SANS `grep` sur `retiree`** *(voir §4)* ; le couple est éprouvé par la garde exécutable **et** par des tests Dart |
| **Tear-offs : DEUX fonctions même pour une identité** | `M-N` | tué *(1 rouge)* | ⚖️ **Le Story File est PLUS PESSIMISTE que le fait** : il annonce que seul `A1` du critère d'US-01.2 voit ce mutant. **Mesuré : un test Dart de `echeance_migration_v3_test.dart` le voit aussi.** Le résultat va dans le **bon** sens |
| **`retiree: null` = RÉSIDU, `containsKey` et ⛔ jamais la nullité (D-4)** | `M-C` | tué *(3 rouges)* | La barrière est **du code exécuté en release** à `depuisDonnee`, en **un seul exemplaire**, et elle est **assertée** |
| **`unawaited_futures` à portée partielle** | `M-G`, `M-H` | tués | Le résidu est bien fermé par le **type de retour** *(`Future<RefusValidation?>`, ⛔ jamais `void`)* **et** par les tests d'AC-11, ⛔ pas par le lint |

---

## 4. ⛔ Comment cette migration a été revue — et comment elle ne l'a PAS été

**Le Story File avertit** : `grep -c "retiree" lib/features/echeances/data/echeance_schema_migrations.dart`
rend **5** lignes qui sont **toutes de la PROSE DE COMMENTAIRE**, identiques sur la forme conforme **et**
sur les quatre mutants destructeurs. ⛔ **Ce `grep` n'a donc PAS été utilisé comme couverture.**

Ce qui a été fait à la place, et qui est rejouable :

1. **Lecture du couple `up`/`down`** : les deux sont `Map.from(d)` — **aucune entrée touchée dans
   aucun des deux sens**, conformément à ADR-012 §4, avec **deux déclarations distinctes** pour que
   `identical(up, down)` reste **faux**.
2. **`migration_v3_guard_criterion.py` sur le module RÉEL** → `VERDICT|OK|`, **8 assertions vertes**
   *(sortie §5)*, et son `--selftest` montre **quelles** assertions chaque mutant destructeur fait
   rougir — ⛔ pas seulement *« ça rougit »*.
3. **Mutants joués sur le module de production** : `M-D` *(le codec ne retire plus la clé d'origine)*
   et `M-N` *(tear-off identique)* — **les deux tués par `flutter test`**.
4. **Le danger nommé par le design est vérifié dans le code** : un `down` *« propre »* qui retirerait
   la clé ferait tomber **AC-12 « Erreur » d'US-01.2**, une US en aval **déjà validée**. Le `down`
   livré **ne retire rien** ; `M1_down_retire_la_cle` du `--selftest` fait rougir `B2 B3 B4 B5 B7 B8`.

---

## 5. Instruments et contrôles — sorties RÉELLES

```
$ python scripts/check_gherkin_mapping.py
T12b -- correspondance scenario <-> test (racine : C:\Users\guillaume.decroix\MesProjets\Concentration)
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
  tests/features/US-01.2-gestion-echeances.feature     50 scenarios
  test/e2e/gestion_echeances_test.dart                 50 tests
  tests/features/US-01.4-gestes-tuile.feature          41 scenarios
  test/e2e/gestes_tuile_test.dart                      41 tests

OK : chaque scenario a son test et chaque test son scenario. Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
exit=0

$ python scripts/check_gherkin_mapping.py --selftest
  [OK] corpus conforme => 0 ecart
  [OK] mutant test retire => refus qui NOMME le scenario
  [OK] mutant test orphelin => refus DISTINCT du manquant
  [OK] mutant titre renomme => manquant ET orphelin
  [OK] un titre a apostrophe est lu correctement
  [OK] les deux motifs sont DISTINCTS

Autotest : 6 assertions, 0 echec(s), 3 couple(s) sous controle.

$ python reports/US-01.4/migration_v3_guard_criterion.py   (module REEL)
CONTEXTE|dart=3.12.2|versionCourante=3|etapes=[2, 3]
ASSERTION|B1_up_identite_sur_les_entrees|OK|
ASSERTION|B2_aller_retour_v2_v3_v2|OK|
ASSERTION|B3_aller_retour_v3_v2_v3|OK|
ASSERTION|B4_true_survit_au_down|OK|
ASSERTION|B5_false_laisse_verbatim_par_le_down|OK|
ASSERTION|B6_up_n_ajoute_aucune_cle|OK|
ASSERTION|B7_cle_inconnue_et_residu_survivent|OK|
ASSERTION|B8_chaine_v1_v3_v1|OK|
VERDICT|OK|
SATISFAIT -- 8 assertions vertes. La garde du couple v2 <=> v3 est EXECUTEE sur le module reel.

$ python reports/US-01.4/migration_v3_guard_criterion.py --selftest   (fin)
== AUTOTEST DE MUTATION de la garde v2 <=> v3 (US-01.4) ==
[OK ] M0_conforme                  attendu=aucun
[OK ] M1_down_retire_la_cle        attendu=['B2_aller_retour_v2_v3_v2', 'B3_aller_retour_v3_v2_v3', 'B4_true_survit_au_down', 'B5_false_laisse_verbatim_par_le_down', 'B7_cle_inconnue_et_residu_survivent', 'B8_chaine_v1_v3_v1']
[OK ] M2_down_nettoie_les_false    attendu=['B2_aller_retour_v2_v3_v2', 'B3_aller_retour_v3_v2_v3', 'B5_false_laisse_verbatim_par_le_down']
[OK ] M3_up_ecrit_false_partout    attendu=['B1_up_identite_sur_les_entrees', 'B2_aller_retour_v2_v3_v2', 'B3_aller_retour_v3_v2_v3', 'B4_true_survit_au_down', 'B5_false_laisse_verbatim_par_le_down', 'B6_up_n_ajoute_aucune_cle', 'B7_cle_inconnue_et_residu_survivent', 'B8_chaine_v1_v3_v1']
[OK ] M4_up_nettoie_la_cle         attendu=['B1_up_identite_sur_les_entrees', 'B2_aller_retour_v2_v3_v2', 'B3_aller_retour_v3_v2_v3', 'B7_cle_inconnue_et_residu_survivent', 'B8_chaine_v1_v3_v1']
[OK ] M5_recompose_l_entree        attendu=['B1_up_identite_sur_les_entrees', 'B2_aller_retour_v2_v3_v2', 'B3_aller_retour_v3_v2_v3', 'B4_true_survit_au_down', 'B7_cle_inconnue_et_residu_survivent']
[OK ] M6_une_seule_fonction        attendu=aucun
AUTOTEST OK : la garde sait rougir, et sur les bonnes assertions.

$ python reports/US-01.4/cout_ecriture_atomique_criterion.py --selftest   (fin)
== AUTOTEST DE MUTATION de l instrument de mesure (D-8, US-01.4) ==
[OK ] T0_conforme                    attendu=aucun
[OK ] T1_serie_plate                 attendu=['V1_octets_croissent_strictement', 'V6_nombre_de_retirees_conforme']
[OK ] T2_entrees_de_taille_variable  attendu=['V2_cout_par_retiree_constant']
[OK ] T3_ecriture_sautee             attendu=['V3_octets_presents_sur_le_disque']
[OK ] T4_purge_silencieuse           attendu=['V1_octets_croissent_strictement', 'V2_cout_par_retiree_constant', 'V6_nombre_de_retirees_conforme']
[OK ] T5_chrono_hors_sujet           attendu=['V5_chronometre_rend_compte_du_temps']
[OK ] T6_ecriture_ailleurs           attendu=['V3_octets_presents_sur_le_disque']
[OK ] T7_provisoire_abandonne        attendu=['V3_octets_presents_sur_le_disque', 'V4_ecriture_atomique_traversee']
AUTOTEST OK : la mesure sait rougir, et sur les bonnes verifications.

$ python reports/US-01.4/preverif_titres_criterion.py
scenarios lus  : 41
tests lus      : 41
OK : correspondance 1:1 exacte — T15 peut inscrire le couple.
```


---

## 6. Comptes du corpus — **LUS**, jamais recopiés

```
$ grep -c "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature
41

$ grep "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature | sort | uniq -d
(sortie VIDE — aucun titre en double)

$ grep -c "^### AC-" docs/stories/US-01.4-gestes-tuile.md
11

$ grep -cE "^- \*\*(Nominal|Erreur|Limite)\*\* :" docs/stories/US-01.4-gestes-tuile.md
33
  -> 33 = 11 AC x 3 : aucun AC incomplet

$ awk '/^## .. Definition of Done/,/^## .. Liens utiles/' docs/stories/US-01.4-gestes-tuile.md | grep -cE '^- \[x\]'  (puis '^- \[ \]')
19
6

$ grep -rn "estEchue|presentesSurLaGrille" lib/ --include=*.dart | wc -l  puis sites de DEFINITION
lib/features/echeances/domain/echeance_etat.dart:43:bool estEchue(Echeance echeance, DateTime instant) =>
lib/features/echeances/domain/echeance_etat.dart:60:List<Echeance> presentesSurLaGrille(List<Echeance> echeances) =>
  -> UNE seule definition de chacun : T1 tenu
```

```
$ flutter test reports/US-01.4/revue_id_libre_criterion.dart
A1| entrees apres = 1
A1|   id=1789113600000000 desc="la seconde" retiree=false
A2| entrees apres = 2
A2|   id=1789113600000000 desc="la premiere"
A2|   id=1789113600000000-1 desc="la seconde"
A3| repetitions de microsecondsSinceEpoch = 199989 / 200000
A3| plus petit ecart NON NUL (us)          = 996
A3| duree creer->retirer->creer (us)       = 101108
A3| entrees = 2, id distincts = 2
00:02 +3: All tests passed!
```


⚠️ **Un décompte égal n'est pas une preuve d'équivalence.** `check_gherkin_mapping.py` compare bien
des **ENSEMBLES** *(`set(tests) - set(scenarios)` et l'inverse — vérifié dans son code)*, ⛔ pas des
cardinaux. **Et il l'imprime lui-même** : *« Contrôle de CORRESPONDANCE DE TITRES — pas de
sémantique »*. ⛔ **Je ne le lis donc pas comme une preuve que les 41 tests testent les 41 scénarios.**
Ce qui donne confiance sur ce point est ailleurs : les **41** `testWidgets` de `gestes_tuile_test.dart`
portent **193 `expect(`** et **aucun** n'est sans assertion *(mesuré)*, et il n'y a **aucun** `skip:`,
`@Skip`, `// ignore:` ni `ignore_for_file` ajouté dans `lib/` ou `test/` par ce diff *(mesuré, sortie
vide)*.

---

## 7. Revue manuelle — DRY, complexité, N+1, lisibilité

### ✅ DRY — trois extractions **correctes**, ⛔ aucune duplication manifeste

* **`estEchue` / `presentesSurLaGrille`** : **une seule définition de chacune** dans `lib/`
  *(§6)*. Les **quatre** exemplaires annoncés sont bien **consommateurs** et non copies — et la
  transformation est **à comportement constant**, vérifiée algébriquement site par site :
  `!e.dateEcheance.isAfter(t)` ⇔ `estEchue(e,t)` · `e.dateEcheance.isAfter(t)` ⇔ `!estEchue(e,t)`.
  Les quatre sites *(`remaining_time_calculator`, `validation_echeance.refusEditionEchue`, les deux de
  `gestion_echeances_page`)* sont **équivalents ligne à ligne** à leur forme d'origine sur `main`.
* **`MessageEcriture`** : `MessageValidation` a été **déplacé**, ⛔ pas copié —
  `grep -rn "MessageValidation" lib/` ne rend plus que **de la prose de commentaire**, aucune classe.
* **`doubleAppui` / `purgerLeReconnaisseur`** *(`test/support/gestes_tuile.dart`)* : extraits d'une
  fermeture locale, bornes **lues** dans le SDK *(`kDoubleTapMinTime`, `kDoubleTapTimeout`)*, ⛔ pas
  devinées.
* **La 5ᵉ occurrence NON fusionnée est JUSTE** : `validation_echeance` garde son *futur strict d'une
  SAISIE* distinct du prédicat d'état. Les fondre rendrait deux règles **solidaires** — la borne de
  l'une déplacerait l'autre sans qu'aucun AC ne le demande. **Décision correcte, et motivée dans le
  code lui-même.**
* **Le rayon de surface** est devenu un token : `BorderRadius.circular(16)` a disparu de
  `ligne_echeance.dart` au profit de `ConcentrationTokens.rayonSurface` — une duplication **retirée**
  en passant.

### ✅ N+1 — **aucun**

Pas de base de données. Le chemin d'écriture est **une** mutation du document en mémoire, **une**
écriture atomique, **un** rechargement après succès *(`_appliquer`)* — soit un coût **constant par
geste**, ⛔ pas par entité. `_tuile` calcule le temps **une fois par tuile et par construction**, avec
`tuilesMax` borné à 9. **Aucune boucle imbriquée sur les échéances** dans le diff.

⚠️ **Coût NON borné, connu et DÉCLARÉ** : l'historique des retirées n'a **aucun plafond** *(arbitrage
D-8)*, à **141,0 octets par retirée**. ⛔ **Ce n'est pas un N+1 et ce n'est pas un défaut de ce code** :
c'est une lacune **nommée**, dont l'instrument de mesure est livré et dont le `--selftest` est vert
*(§5)*.

### ✅ Lisibilité

Densité de commentaire très élevée *(ex. `echeance_tile.dart` : **225** lignes de code pour **295** de
commentaire)*, mais ⛔ **ce n'est pas du bruit** : chaque bloc porte **le motif d'une décision et sa
réfutation**, et plusieurs disent explicitement *« ne pas simplifier ceci, voici le mutant »* — dont
un `IgnorePointer` **retiré** parce que le mutant `M-w` a prouvé qu'il **ne pouvait pas rougir**.
C'est exactement ce que le projet a payé deux fois pour apprendre. **Rien à redire.**

### ⚠️ Un point à NE PAS « simplifier » — avertissement au prochain relecteur

Dans `lib/features/echeances/data/echeance_document_codec.dart`, le couple
`if (echeance.retiree) 'retiree': true,` **puis** `if (!echeance.retiree) entree.remove('retiree');`
**a l'air redondant et ne l'est pas** : les clés d'origine sont copiées **avant** les clés explicites,
donc **sans le `remove`** un `retiree: true` **préexistant survivrait** à une entité non retirée et la
tuile resterait absente **pour toujours**. **Mutant `M-D` joué : TUÉ (2 rouges).**
➡️ **Même famille que « les égalités au token sont tautologiques » : ⛔ ne jamais retirer au titre du
doublon ce qui a seulement l'air d'en être un.**

---

## 8. Couverture des AC par le CODE — le critère bloquant

⛔ **Ce contrôle ne se déduit pas de la table de traçabilité du Story File** *(elle relie clause →
scénario, ⛔ pas clause → code)*. Chaque AC a été rattaché à un **site de code** et à un **mutant tué**.

| AC | Site de code *(ancre textuelle)* | Preuve |
|---|---|---|
| **AC-1** nombre seul, centré, agrandi | `echeance_tile.dart` › `crossAxisAlignment: temps.estEchue` · `styleNombrePour(estEchue:` · `fit: BoxFit.scaleDown` | `M-B` tué |
| **AC-2** révélation 3 s | `echeances_grid.dart` › `void _reveler(String id)` · `fenetreRevelation` | `M-K`, `M-Q` tués |
| **AC-3** active sans description | `echeance_tile.dart` › `if (activer == null \|\| (!temps.estEchue && description.isEmpty))` | `M-M` tué ; l'assertion porte sur **l'absence du NŒUD**, ⛔ pas sur `onTap == null` |
| **AC-4** double appui retire | `echeance_tile.dart` › `onDoubleTap: temps.estEchue ? activer : null` · `echeance_document_repository.dart` › `Future<ResultatEcriture> retirer(String id)` | `M-F`, `M-I` tués |
| **AC-5** durable, rien ne disparaît sans geste | `echeance.dart` › `final bool retiree` · `echeance_schema_migrations.dart` › `EtapeMigration(3, _v2VersV3, _v3VersV2)` | `M-C`, `M-D`, `M-N`, `M-O` tués |
| **AC-6** libère une place + message conditionnel | `echeances_notifier.dart` › `get presentes` · `validation_echeance.dart` › `auMoinsUneEchue` | `M-E`, `M-J` tués |
| **AC-7** marque en gestion | `ligne_echeance.dart` › `marqueSurLaGrille` / `marqueRetiree` | `M-S` tué |
| **AC-8** animation, seul feedback | `echeances_grid.dart` › `cleDisparition` · `disableAnimationsOf` · `if (_sortante != null) return;` | `M-G`, `M-L`, `M-R` tués |
| **AC-9** accessibilité, focus visible | `echeance_tile.dart` › `button: true` · `onShowFocusHighlight` · `class _AnneauFocus` | `M-M`, `M-P` tués |
| **AC-10** non-régression de l'exercice | anneau peint **hors** mise en page *(`Positioned` à décalage négatif + `Clip.none`)* · `_minuterie` intouché par les gestes | `M-P` tué *(un anneau allumé au doigt serait un retour d'appui **coloré**)* |
| **AC-11** retrait dont l'écriture échoue | `hub_page.dart` › `setState(() => _messageEcriture = refus?.message)` · `echeances_grid.dart` › `if (refus != null)` | `M-G`, `M-H` tués |

➡️ **Aucun AC n'est orphelin de code. Aucun code nouveau n'arrive sans test.**
⚠️ **Ce que ce tableau N'atteste PAS** : la **force sémantique** de chaque scénario e2e — le gate de
correspondance compare des **titres**, il le dit lui-même. Et **NM-3, NM-11, NM-12, NM-13** restent
**non levées** : j'ai seulement vérifié qu'aucune n'a été **silencieusement transformée en test vert**.

---

## 9. FINDINGS

### 9.1 🚫 BLOQUANTS — **AUCUN** *(0)*

| Critère bloquant du rôle | Constat, et la commande qui l'établit |
|---|---|
| Erreur lint / typecheck sur le code de l'US | **Aucune** — `flutter analyze` → `No issues found!` · `dart format --set-exit-if-changed` → `0 changed` |
| Duplication manifeste | **Aucune** — trois extractions correctes, une non-fusion **motivée**, un littéral de rayon **retiré** *(§7)* |
| Requête N+1 | **Aucune** — pas de base de données ; coût **constant par geste**, tuiles bornées à 9 |
| Code nouveau sans test | **Aucun** — **0 commit sur 28** touche `lib/` sans toucher `test/` *(§1)* |
| AC non couvert par le code | **Aucun** — **11 AC sur 11** ont leur site de code **et** leur mutant tué *(§8)* |

### 9.2 ⚠️ NON BLOQUANTS — sévérité HAUTE *(2)*

#### `NB-1` — `_idLibre` a **perdu de vue les retirées** : une échéance retirée peut être **écrasée en silence**

| | |
|---|---|
| **Fichier › ancre** | `lib/features/echeances/presentation/echeances_notifier.dart` › `presentes: presentes,` *(dans `creer`)* — introduit par le commit `b4f2ee4` **(T4)** ; effet dans `lib/features/echeances/domain/validation_echeance.dart` › `id: _idLibre(presentes),` |
| **Problème** | `_idLibre` cherche un `id` libre **dans la liste qu'on lui passe**. Jusqu'à T4 c'était `_echeances` *(la liste COMPLÈTE)* ; depuis T4 c'est `presentes`, dont `presentesSurLaGrille` **EXCLUT les retirées** ⇒ **un `id` déjà porté par une RETIRÉE est vu comme LIBRE**. Or l'écriture porte sur la liste **DU DOCUMENT** : `encoder` construit `{for e in echeances: e.id: e}`, la nouvelle entrée **écrase** la ligne de la retirée, et `_encoderEntree` en **retire la clé `retiree`**. ⇒ **perte de donnée silencieuse, sans refus ni message** — exactement ce que la colonne « réfutée par » d'**AC-4 « Nominal »** nomme : *« l'échéance est **détruite** »*. 🔴 **Cause de fond : UN SEUL paramètre porte DEUX règles** — la limite de 9 a besoin de la liste **filtrée** *(C-7, correct)*, l'unicité d'`id` a besoin de la liste **COMPLÈTE**. Le correctif C-7 était juste ; son **effet de bord** ne l'est pas. |
| **Mesuré, ⛔ pas déduit** | `reports/US-01.4/revue_id_libre_criterion.dart` *(publié par cet audit)*. **A1**, horloge figée : `entrees apres = 1` — la retirée a **disparu**, remplacée par la nouvelle. **A2, CONTRÔLE NÉGATIF**, même scénario **sans le retrait** : `entrees apres = 2` et `id` dépareillés en `…-1` ⇒ **c'est bien le FILTRAGE qui cause la perte**, ⛔ pas le magasin. |
| **Pourquoi NON bloquant — et c'est une MESURE, ⛔ pas une opinion** | **A3, atteignabilité** : granularité observée de `DateTime.now()` sur cette machine = **~996 µs** *(`199 989 / 200 000` répétitions en boucle serrée)*, contre **~101 108 µs** mesurés pour `créer → retirer → créer` sur le chemin **de production** ⇒ **~100× de marge**, et A3 rend `entrees = 2, id distincts = 2` : **aucune perte sur le chemin réel**. **Le défaut n'est pas atteignable par l'IHM.** ⛔ **Mais cette marge est un ACCIDENT DE TIMING, pas une barrière conçue** : elle n'est écrite nulle part, aucun test ne la surveille, et elle rétrécirait si l'`id` cessait d'être horodaté ou si une horloge était injectée en production. |
| **Solution** | Rendre la liste **complète** disponible à `_idLibre`, ⛔ **sans toucher à `presentes`** *(dont C-7 dépend)* : soit un second paramètre `toutes` sur `valider(...)`, soit — plus sûr — **sortir la génération d'`id` de `ValidationEcheance`** et la confier au **dépôt**, seul détenteur de la liste du document. **Livrer avec son test**, en reprenant `A1` / `A2` du critère ci-dessus. |

#### `NB-2` — le gate requis `app.test` est **INTERMITTENT** sur AC-11 « Nominal » *(1 rouge sur 4)*

| | |
|---|---|
| **Fichier › ancre** | `test/features/hub/presentation/hub_message_ecriture_test.dart` › `Future<void> retirerLEchue(WidgetTester tester)` → `await reglerEcritures(tester);` *(appel **SANS** `jusqua`)* ; mécanique dans `test/support/magasin_temporaire.dart` › `Future<void> reglerEcritures(` |
| **Problème** | `reglerEcritures` **sans `jusqua`** est une attente à **durée fixe** *(`tours = 200` cycles de `pump` + délai réel de 10 ms)*, ⛔ pas une attente **conditionnelle**. Sous charge concurrente, la chaîne de **deux** entrées-sorties réelles *(écriture atomique puis rechargement)* peut dépasser la fenêtre ⇒ le test rougit. **Le corpus le sait déjà** : la docstring de `reglerEcritures` raconte **ce rouge exact** *(« AC-11 « Nominal » : `Expected: true` puis `Actual: <false>` »)* et le remède appliqué le 2026-09-08 a été de porter `tours` de **40 à 200**. ➡️ **Ma mesure établit que 200 ne suffit pas non plus** : **1 rouge sur 4** exécutions de la suite complète sur `8509f44`, **6 verts sur 6** pour le même fichier **en isolement**. |
| **Pourquoi NON bloquant** | ⛔ **Ce n'est pas un défaut du PRODUIT** : les mutants `M-G` *(2 rouges)* et `M-H` *(6 rouges)* montrent que la logique d'AC-11 est correcte **et fermement assertée**. Le point fragile est la **fenêtre d'attente du harnais**. ⚖️ Et le confondant est **nommé, ⛔ pas écarté** : deux audits tournaient en parallèle sur la même machine, dont un instrument qui écrit ~1,4 Mo et **chronomètre des écritures atomiques**. ⛔ **Je n'affirme pas que c'est la cause.** |
| **Solution** | Passer une **condition de sortie** à tous les appels dépourvus de `jusqua` — ici `reglerEcritures(tester, jusqua: () => messageVisible(tester))` — ce que la docstring recommande déjà *(« le coût n'est payé que si l'attente est réelle »)*. ⛔ **Ne PAS relever `tours` une troisième fois** : un nombre magique relevé deux fois est un **symptôme**, et le 2ᵉ relèvement a déjà produit un test *« instable en suite, stable en isolement »*. ➡️ **À arbitrer par @QA_Tester** : ce rouge peut faire échouer un **contexte requis** au moment de la PR. |

### 9.3 💡 Suggestions d'amélioration — ⛔ ne fondent aucun verdict *(3)*

| # | Fichier › ancre | Problème | Solution |
|---|---|---|---|
| `S-1` | `lib/features/echeances/presentation/widgets/echeance_tile.dart` › `Widget build(BuildContext context) {` de `_EcheanceTileState` | ~130 lignes de code et **trois sorties** *(construction de `rendu`, retour non interactif, retour interactif)*. Elle reste lisible grâce à ses commentaires, mais c'est la fonction la plus dense du diff. | Extraire `rendu` dans une méthode privée. ⛔ **Sans toucher à `key: EcheanceTile.cleFond`** : c'est l'**ancre d'identité** de NB-7, et c'est elle que `fondDeLaTuile` sélectionne. |
| `S-2` | `reports/US-01.4/migration_v3_guard_criterion.py` › `RAPPEL : ce script n est PAS un gate CI` | L'instrument **le dit lui-même** : il ne vit dans **aucun workflow** *(§G-5 du Story File)*. Même dette que le `selftest` d'US-00.6 et que `check_epic00_docs.py`. ⛔ **Pas imputable à cette US** : elle **hérite** du défaut et le **nomme** dans sa propre sortie. | Porter au dossier `/audit-methodo`, groupé avec les deux autres — c'est **une seule** dette, pas trois. |
| `S-3` | message du commit `e8a4f82` : `DoD instruite 18/25` | Un **compte dérivé écrit à la main** *(défaut ⑤)* : la lecture rend aujourd'hui **19/25** *(§6)*. ⚠️ ⛔ **Le Story File, lui, n'écrit AUCUN total** — il ne publie que la commande, ce qui est **exactement la bonne forme**. Le nombre périmé ne vit **que** dans un message de commit, **immuable**. | Aucun correctif possible *(un message de commit ne se réécrit pas)*. **Signalé pour qu'il ne soit pas recopié ailleurs.** |

---

## 10. Ce que ce verdict N'atteste PAS — ⛔ à ne pas sur-lire

* **Aucun écran n'a été vu.** Tous les contrastes du diff restent **calculés**, jamais observés.
* **L'application n'a pas tourné sur un appareil** dans le cadre de cet audit : **NM-11** et **NM-13**
  demeurent **non levées**, et le double appui éprouvé est **SYNTHÉTISÉ**.
* **Aucun SAST, aucun scan de CVE** — ce gate **n'existe pas** dans la factory *(dette connue)*, et ce
  n'est pas le périmètre de la revue. L'audit sécurité est **distinct et indépendant**.
* **La sémantique des 41 scénarios e2e n'est pas certifiée** : le gate compare des **TITRES**, et il
  l'imprime. **Les trois faux titres de ce cycle ont été trouvés par des rôles à contexte frais,
  ⛔ aucun par un gate.**
* **19 mutants ne sont pas une couverture de mutation** : ils échantillonnent **les points que le
  design a nommés comme dangereux**. ⛔ **Rien n'est prouvé sur ce qui n'a pas été muté.**
* **`NB-1` n'est PAS corrigé** : il est **mesuré, borné et outillé**. Une marge de ~100× mesurée **un
  jour, sur une machine**, n'est pas une garantie de conception.
* **`NB-2` n'est PAS expliqué** : j'ai mesuré un taux, ⛔ pas établi une cause.
* **Ce visa porte sur `8509f44` et sur rien d'autre.** Tout commit ultérieur le **périme** *(NB-6)*.

---

## 11. Verdict

> ## ✅ **PASSED** — commit `8509f44`
>
> **0 bloquant · 2 non bloquants de sévérité HAUTE (`NB-1`, `NB-2`) · 3 suggestions.**
>
> Les **cinq** critères bloquants du rôle sont satisfaits, et chacun par une **commande**, ⛔ pas par
> une lecture : `flutter analyze` **vert**, `dart format` **vert**, **0 commit sur 28** livrant du
> `lib/` sans `test/`, **11 AC sur 11** rattachés à un site de code **et** à un mutant tué, **aucune**
> duplication manifeste, **aucun** N+1.
>
> **Ce qui emporte la décision n'est PAS la couverture de `98,08 %`** — elle est aveugle à la force
> des assertions, ce projet l'a payé — **mais les 19 mutants joués sur le code de PRODUCTION et les
> 19 tués**, chacun visant un point que le design avait nommé comme dangereux : `NB-7` rejoué, le
> `BoxFit`, le couple `v2 ⇄ v3`, les tear-offs, le `containsKey` de `D-4`, l'ordre
> *écriture → animation*, et le message conditionnel de la limite.
>
> **`NB-1` et `NB-2` sont portés à la connaissance de @QA_Tester et de @Architect, chacun avec son
> critère exécutable.** ⛔ Aucun des deux ne relève des motifs de `FAILED` définis pour ce rôle, et
> ⛔ je ne les requalifie pas pour justifier un verdict : *un arbitrage ne lève jamais un critère, et
> un auditeur ne déplace pas la barre pour son confort.*

---

### Instrument publié par cet audit — rejouable

`reports/US-01.4/revue_id_libre_criterion.dart` — **3 assertions**, dont **1 contrôle négatif** (`A2`)
et **1 mesure d'atteignabilité** (`A3`).
Lancement : `flutter test reports/US-01.4/revue_id_libre_criterion.dart`.

⚠️ **Il asserte le DÉFAUT MESURÉ, ⛔ pas le comportement souhaité** : il **rougira** le jour où `NB-1`
sera corrigé. **C'est voulu** — il est le **témoin** du défaut, ⛔ pas sa spécification ; c'est ce qui
l'empêche d'être un contrôle qui ne peut pas rougir.

✅ **Effet sur les gates vérifié APRÈS écriture, ⛔ pas supposé** : `run_gates --gate analyze` rend
toujours `No issues found!` et `--gate format` `0 changed` *(ce fichier n'est ni dans `lib/` ni dans
`test/`, il n'entre donc pas dans le gate `test`)*.
