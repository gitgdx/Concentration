# Audit sécurité — US-01.1 · **DELTA** `24fe59a` → `6fe75df`

| Champ | Valeur |
|---|---|
| **US** | US-01.1 (EPIC_01, track FULL) |
| **Auditeur** | @CyberSecurity — contexte frais (Constitution Art. 2) |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-08-02 |
| **Commit audité** | **`6fe75df720214a9bac74efd9b6f024f7cd561407`** |
| **Commit du visa précédent** | `24fe59a1120d65960398b3455bcdb847ff57c590` |
| **Périmètre** | `git diff 24fe59a..6fe75df` — 8 fichiers, dont **2 dans `lib/` (+73/−4)** |
| **Rapport principal** | [`security.md`](security.md) — ⛔ **NON ÉCRASÉ**, son verdict reste vrai **à sa date et sur son commit** |

---

## 0. Pourquoi ce rapport existe — le visa précédent **ne tenait pas**

La question posée était : *« ton visa tient-il sur `6fe75df` ? »*. **Non**, et il n'y avait pas
matière à arbitrage.

Un visa de sécurité est une **assertion portant sur un commit**, jamais sur une intention ni sur
une confiance dans la nature d'un changement. `EVT_SECURITY_AUDIT_PASSED` a été émis sur `24fe59a`.
`6fe75df` contient **73 lignes de `lib/` que je n'avais pas vues**. Répondre « c'est du widget,
c'est anodin » aurait été **exactement** la faute qu'US-00.6 a payée sous la formule « *les trois
badges doivent porter sur le MÊME commit* » : un jugement **sur la description** du changement au
lieu du changement.

⚠️ **La taille d'un delta n'est pas une mesure de son risque.** Un seul caractère suffit à ouvrir
une faille ; 73 lignes ne se présument ni dangereuses ni anodines — **elles se lisent**.

**Verdict de ce delta ci-dessous. Il RÉTABLIT le visa, sur `6fe75df` cette fois.**

---

## 1. Verdict : **PASSED** sur `6fe75df` — aucun finding bloquant, aucun finding nouveau

| Critère bloquant | Constat sur le delta |
|---|---|
| Finding SAST HIGH | Aucun — ⚠️ **toujours aucun SAST** (borne inchangée, §5) |
| CVE HIGH/CRITICAL sur dépendance directe | **0 dépendance ajoutée par le delta** — diff `pubspec` **vide** |
| IDOR | Sans objet — le delta n'introduit ni ressource, ni identifiant, ni appartenance |
| Secret en dur | Aucun — `gitleaks` exit 0 sur `6fe75df` |
| Endpoint sans authz | Sans objet — **`dart:io` toujours absent de `lib/`** |

**Les 5 findings non bloquants de `security.md` (NB-1 à NB-5) sont INCHANGÉS** : le delta n'en
aggrave aucun, n'en résout aucun, n'en crée aucun. Détail au §4.

---

## 2. Contenu réel du delta — lu, pas cru

### 2.1 `lib/features/hub/presentation/hub_page.dart` (+54)

Ajout d'un `enum` **privé** `_CommandeBarre` (2 valeurs : `ajout`, `reglages`) et d'un widget
**privé** `_CommandeNonInteractive`, rendu dans la barre basse.

**Analyse de sécurité : aucune capacité nouvelle.** Le widget produit une `Icon` estompée dans un
`Padding`, enveloppée d'un `Semantics(enabled: false, container: true)`. C'est un **rendu inerte**.

Le point qui compte, et il est **vérifié par balayage du delta** et non par lecture de commentaire :

```
$ git diff 24fe59a..6fe75df -- lib/ | grep '^+' | grep -iE "onTap|onPressed|GestureDetector|InkWell|Navigator|dart:io|http|Socket|File\(|Process\.|secret|token|password|apiKey"
+              // grisés : ABSENCE de gestionnaire, jamais un onTap vide.
+/// ⛔ Aucun `IconButton` : il porte un `onPressed` et une ondulation, donc il
+          color: ConcentrationTokens.moduleGrise.couleur,
```

⚠️ **Les trois occurrences sont des COMMENTAIRES** — deux décrivent l'**absence** du mécanisme,
la troisième est le mot « color ». **Aucune ligne de code ajoutée ne porte de gestionnaire de
geste, de navigation, d'E/S, de réseau ni de secret.**

C'est le motif « *citation-dans-sa-réfutation* » que ce projet connaît bien
(`reports/US-00.5/tension_structurelle.md`) : un balayage purement lexical aurait ici crié au
gestionnaire de geste. **J'ai lu les occurrences plutôt que compté les correspondances.**

⇒ Le choix `Icon` + `Semantics(enabled: false)` **plutôt qu'`IconButton`** est, accessoirement,
le **meilleur choix de sécurité** : pas de zone tactile, donc pas d'action à désactiver, donc rien
à réactiver par accident. L'interdit est porté par l'**absence**, qui est assertionnable.

### 2.2 `lib/app/app.dart` (+21/−4) — le paramètre `echeances`

```dart
const ConcentrationApp({super.key, this.clock = const SystemClock(), this.echeances});
final List<Echeance>? echeances;
...
home: HubPage(echeances: echeances ?? SampleEcheances.depuis(clock), clock: clock),
```

**Question posée par le coordinateur : élargissement de la surface d'attaque, ou neutre ?**

## → **NEUTRE.** Et voici pourquoi, en quatre points **mesurés**, pas raisonnés en l'air.

**(a) Ce n'est pas une frontière de désérialisation.** Le paramètre est **statiquement typé**
`List<Echeance>?`. Il n'y a **aucun parseur nulle part dans `lib/`** :

```
$ grep -rnE "jsonDecode|jsonEncode|dart:convert|fromJson|toJson|Object\?" lib/
lib/features/echeances/domain/echeance.dart:27:  static Echeance? depuisDonnee(Object? donnee) {
```

Une **seule** occurrence : la frontière `depuisDonnee` de NB-2, qui **conserve zéro appelant dans
`lib/`** (vérifié : sa définition est sa seule occurrence). Le delta **n'y touche pas**.

**(b) Elle n'est atteignable que par du code Dart compilé dans l'application.** Ce n'est pas une
entrée : c'est un argument de constructeur. Pour l'exploiter, il faut **déjà** exécuter du Dart
dans le processus — c'est-à-dire **avoir déjà gagné**. ⚠️ **Un paramètre que seul un attaquant
déjà en exécution peut atteindre n'ajoute AUCUNE surface d'attaque** : il est en aval du
compromis, pas en amont.

**(c) La production ne l'utilise pas** — vérifié, ce n'est pas une supposition :

```
$ grep -rn "ConcentrationApp(" lib/ test/
lib/main.dart:12:                 runApp(const ConcentrationApp());          ← PRODUCTION : sans echeances
test/e2e/hub_echeances_test.dart:29:  ConcentrationApp(clock: FakeClock(...))
test/e2e/hub_echeances_test.dart:41:  ConcentrationApp(clock: ..., echeances: echeances)   ← SEUL appelant
```

Le point d'entrée réel reste `const ConcentrationApp()` : la valeur par défaut `null` fait retomber
sur `SampleEcheances`. **Le chemin injecté n'existe qu'en test.**

**(d) Le delta RÉDUIT un écart d'assurance, il ne l'augmente pas.** Avant, 11 tests sur 13
montaient `MaterialApp(home: HubPage)` — c'est-à-dire **une application reconstituée**, pas la
vraie. La topologie de production (widget racine, forçage du thème sombre, configuration
`MaterialApp`) n'était donc **pas** sous test, alors même qu'ADR-008 §1 en faisait la **condition**
pour écarter `integration_test/`. Le paramètre existe pour tenir cette condition. **Faire monter
aux tests le code réellement livré est un gain de sûreté**, pas un coût.

⚠️ **La seule réserve, et elle est ancienne, pas nouvelle** : un appelant Dart peut injecter une
liste à `id` vides ou dupliqués — c'est la conséquence de **NB-1** (invariant `assert`, retiré en
release), déjà consignée. Mais `HubPage(echeances:)` acceptait **déjà** une `List<Echeance>` avant
le delta : la surface est **identique**, seulement déplacée d'un cran vers la racine. **NB-1 n'est
ni aggravé ni élargi.**

### 2.3 Hors `lib/` — tests et documents

`test/e2e/hub_echeances_test.dart` (+55/−…) et `test/core/color/temporal_gradient_test.dart` (+70/−…)
renforcent des assertions (gamut, commandes de barre). `PROJECT_LOG.md`, `docs/trace/`,
`reports/US-01.1/*.md` : documentaires. **Aucun impact sécurité** — du code de test n'est pas
livré à l'utilisateur.

---

## 3. Contrôles de non-régression sur `6fe75df` (sorties réelles)

### 3.1 Les trois invariants que le coordinateur m'a demandé de **revérifier**

```
$ git diff 24fe59a..6fe75df -- pubspec.yaml pubspec.lock
$ (vide)                                          ⇒ 0 DEPENDANCE AJOUTEE — confirmé

$ git diff 24fe59a..6fe75df --name-only | grep -E "\.github/|factory.config.json|gitleaks|protect_files|githooks|analysis_options"
  AUCUN                                           ⇒ CI et enforcement INTACTS — confirmé

$ git diff main...6fe75df --stat -- .github/ pubspec.yaml pubspec.lock
 .github/workflows/ci.yml | 13 +++++++++++++
 1 file changed, 13 insertions(+)                 ⇒ ci.yml : exactement les 13 lignes DEJA auditees
```

⇒ Les trois affirmations du coordinateur sont **vraies, et vérifiées par exécution**. Le cumul
depuis `main` sur `.github/` est **inchangé** depuis mon premier passage : l'analyse du §2 de
[`security.md`](security.md) (libellés de jobs, permissions, absence d'interpolation dans les
`run:`, absence de `pull_request_target`) **reste valide sans être rejouée**, puisque le fichier
est **bit-à-bit identique**.

### 3.2 `gitleaks` 8.30.1 → **exit 0**

```
INF scanned ~154294673 bytes (154.29 MB) in 4.87s
INF no leaks found
GITLEAKS_EXIT=0
```

### 3.3 `run_gates --all` → **exit 0 (5 gates)** — couverture en **HAUSSE**

```
✅ app.format · ✅ app.analyze · ✅ app.test · ✅ app.deps_audit · ✅ app.build
Couverture de lignes : 95.2% (380/399) — seuil requis : 89.4% (cliquet)
  [HAUSSE] 95.24% (380/399) > cliquet 89.4%
Tous les gates bloquants passent (5 exécutés).
GATES_EXIT=0
```

*(pour mémoire, sur `24fe59a` : 94,1 % — 364/387. Le delta **ajoute** du code couvert.)*

### 3.4 Job REQUIS « 📋 Governance » rejoué → **4/4 exit 0**, + le contrôle T12b

```
check_scb_compliance     -> 0
validate_trace --all     -> 0
factory_sync --check     -> 0
selftest_coverage_ratchet-> 0
check_gherkin_mapping    -> 0   (13 scénarios ↔ 13 tests)
  --selftest             -> 6 assertions, 0 echec(s)
```

### 3.5 Surface Dart — inchangée

```
$ grep -rhn "^import " lib/ | grep "^'dart:\|^'package:" | sort -u
'dart:async' · 'dart:math' as math · 'dart:ui' · 'package:flutter/material.dart'
```

⇒ **`dart:io` reste absent.** Ni réseau, ni disque, ni processus, donc **aucun endpoint** : les
critères IDOR / authz / CSRF / CORS demeurent **sans objet**, structurellement.

### 3.6 Point de robustesse examiné — débordement de la barre basse

Le delta ajoute **deux enfants** à la barre basse, or le commit `b00eb4c` corrigeait justement un
débordement en format téléphone. Vérifié : `grille_gabarits_test.dart` monte bien **`HubPage`**
(donc la barre) et asserte `tester.takeException()`, sur plusieurs gabarits, et les tests
**passent**. ⇒ **Pas de débordement non détecté aux gabarits couverts.** *(Un débordement serait de
toute façon un défaut de rendu, non un défaut de sécurité — je le note pour la QA, pas comme
finding.)*

---

## 4. Findings

### 4.1 Bloquants

**AUCUN.**

### 4.2 Nouveaux non bloquants introduits par le delta

**AUCUN.**

### 4.3 État des findings de `security.md`

| # | Sév. | État après le delta |
|---|---|---|
| NB-1 | LOW | **Inchangé.** `echeances` déplace le point d'entrée de `HubPage` vers la racine, sans élargir la surface (§2.2). Reste à traiter **avant** la persistance d'US-01.2 |
| NB-2 | LOW | **Inchangé.** `depuisDonnee` conserve **0 appelant dans `lib/`** (vérifié sur `6fe75df`) |
| NB-3 | INFO | **Inchangé.** `temporal_gradient.dart` non modifié par le delta |
| NB-4 | INFO | **Inchangé.** `ci.yml` bit-à-bit identique |
| NB-5 | LOW | **Inchangé.** Aucune action ajoutée |

### 4.4 Finding **de méthode** révélé par cet épisode — à verser aux dettes

| # | Outil | Emplacement | Sév. | Décision |
|---|---|---|---|---|
| **NB-6** | Revue du schéma de trace | `scripts/trace_append.py` · `docs/trace/**/events.jsonl` | **LOW (méthode)** | **À verser à US-00.8** |

**Un visa d'audit n'est rattachable à aucun commit — par construction.** Mesuré :

```
$ python scripts/trace_append.py --help
  options : --us --event --agent --model --rationale --files --report --command --session
            ⇒ AUCUNE option --commit / --sha

$ champs du dernier événement : ['agent','event','evidence','files','model','rationale','session','ts','us']
  un champ de commit/SHA existe-t-il ? False
```

⇒ **Rien, dans le système de traçabilité, ne dit sur QUEL commit un `EVT_SECURITY_AUDIT_PASSED`
porte.** Un visa devient donc **périmé en silence** dès le commit suivant, et **aucune machine ne
peut le signaler**. C'est ce qui s'est produit ici : le décalage a été rattrapé par un
**humain/coordinateur**, pas par un mécanisme — et US-00.6 avait déjà payé la même classe de trou.

**Même famille que deux dettes déjà inscrites** au CLAUDE.md (« aucun événement d'extinction de
dérogation », « `emitter` non enforcé ») : le **système de traçabilité** est le composant le moins
outillé de la factory.

**Mitigation applicable immédiatement, et appliquée par moi** : inscrire le SHA dans le champ libre
`--command`/`--rationale`. ⚠️ **C'est une convention, NON enforcée** (champ libre, non validé par
`validate_trace.py`) — elle **réduit** le risque, elle ne le supprime pas. Le correctif réel est un
champ `commit` **validé**, ce qui touche le schéma de la trace ⇒ **exige son propre ADR**.

---

## 5. Bornes — inchangées et rappelées, jamais tues

- ⛔ **Aucun SAST** : `run_gates --gate sast` → **exit 1, le gate n'existe pas**. Les 73 lignes de
  `lib/` de ce delta n'ont reçu, comme les précédentes, **qu'une revue humaine**.
- ⛔ **Aucun scanner de CVE** : `dart pub outdated` mesure l'obsolescence. Ici la borne est
  **moins mordante que d'ordinaire** puisque le delta ajoute **zéro dépendance** — la surface
  d'approvisionnement est **strictement celle déjà justifiée** dans `security.md` §0/B-2.
- Aucun DAST, aucun fuzzing, aucune revue du code transitif du SDK.

---

## 6. Conclusion

**Le visa précédent ne tenait pas — il est REMPLACÉ, pas prolongé.**

Le delta `24fe59a` → `6fe75df` est **neutre en sécurité** et **positif en assurance** : il ne
touche ni dépendance, ni CI, ni enforcement ; il n'introduit aucune capacité (pas de gestionnaire
de geste, pas de navigation, pas d'E/S, pas de réseau, pas de secret) ; le paramètre `echeances`
n'est **pas** une surface d'attaque au sens utile du terme, et il **corrige** un écart réel entre
ce que les tests montaient et ce que la production exécute.

⚠️ **Ce que ce rapport n'atteste pas** : il porte sur **`6fe75df` et sur lui seul**. Tout commit
ultérieur touchant `lib/`, `.github/`, `pubspec*` ou un fichier d'enforcement **périme ce visa** —
et, comme l'établit **NB-6**, **aucun mécanisme de la factory ne le signalera**.

---

*Rapport produit en contexte frais par @CyberSecurity (`claude-opus-5[1m]`). Toutes les sorties
ci-dessus ont été réellement exécutées le 2026-08-02 sur `6fe75df`. Aucune modification du code,
du SCB ou de l'état GitHub ; `security.md` n'a pas été écrasé.*
