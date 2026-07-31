# 🧪 Rapport QA — US-00.5 (ADR-001 choix de stack + exactitude de l'Art. 4) — **PR nº 1**

| Champ | Valeur |
|---|---|
| **Agent** | @QA_Tester — **contexte frais** |
| **Modèle réel** | `claude-opus-5[1m]` |
| **Date** | 2026-07-30 |
| **Branche / HEAD** | `feat/US-00.5-adr-stack-constitution` · **`e6d5c1d`** |
| **PR** | **#17** (`OPEN`, `MERGEABLE`, `mergeStateStatus: CLEAN`) |
| **Pré-conditions** | `python scripts/validate_trace.py --us US-00.5` → **exit 0** · trace portant **`EVT_SECURITY_AUDIT_PASSED`** (évt 7) **et** **`EVT_CODE_REVIEW_PASSED`** (évt 9, après un `EVT_CODE_REVIEW_FAILED` en évt 8) — **pré-conditions REMPLIES** |
| **VERDICT** | ## 🔴 **FAILED** |

> **Nature de l'US, actée avant tout décompte** : **0 fichier de code**, **0 fichier Dart**, **0 script
> applicatif modifié** ; `Code (Dev)` = **`N/A` justifié** au SCB. Les gates attestent une
> **non-régression**, **jamais le livrable**, et la couverture de **89,5 %** porte sur le **squelette
> Flutter**. Les **21 scénarios Gherkin sont DOCUMENTAIRES** — comptés **à part**, **jamais comme verts**.

---

## 1. Décomptes exacts — tout est issu d'une EXÉCUTION

### 1.1 Suites de tests et gates de l'adapter

`python scripts/run_gates.py --all` → **exit 0**, **5 gates exécutés** :

| Gate | Commande réellement lancée | Résultat |
|---|---|---|
| `app.format` | `dart format --output=none --set-exit-if-changed lib test` | ✅ *Formatted 2 files (0 changed)* |
| `app.analyze` | `flutter analyze` | ✅ *No issues found! (ran in 23.0s)* |
| `app.test` | `flutter test --coverage && check_flutter_coverage.py --min 80` | ✅ *All tests passed!* |
| `app.deps_audit` | `dart pub outdated --show-all` | ✅ *(non bloquant par config)* |
| `app.build` | `flutter build web --release` | ✅ *Built build\web* (54,5 s) |

**DÉCOMPTE DES TESTS — obligation Art. 3 :**

| | Nombre | Source |
|---|---|---|
| **passed** | **2** | `00:02 +2: All tests passed!` (`affiche le titre du squelette`, `incrémente le compteur au tap`) |
| **skipped** | **0** | aucun `~` ni `+0 -0 ~N` dans la sortie |
| **failed** | **0** | — |
| **Couverture de lignes** | **89,5 % (17/19)** ≥ seuil **80 %** | `check_flutter_coverage.py` |

**Scénarios BDD — comptés à part, et à ZÉRO :**

| | Nombre |
|---|---|
| Scénarios rédigés dans `tests/features/US-00.5-*.feature` | **21** (compté par `grep -cE "^\s*(Scenario\|Scénario\|Plan du scénario):"`) |
| **exécutés** | **0** |
| **passed / skipped / failed** | **0 / 0 / 0** |

Preuve de l'inexécutabilité (E2E impossible, pas seulement non fait) : `grep -rn "tests/features"
.github/workflows/` → **rc=1, aucune sortie** · aucun répertoire de step definitions
(`ls -d tests/features/step_definitions tests/steps test/features` → **rc=2**) · aucune dépendance
gherkin/cucumber dans `pubspec.yaml`/`pubspec.lock` *(seule correspondance : un hash `sha256` contenant
« bdd », faux positif vérifié)*. **`docs/qa/E2E_RUNBOOK.md` n'existe pas** → aucune stack E2E à lancer.
⇒ **Les 21 scénarios ne comptent pour aucune couverture.**

### 1.2 Gates de gouvernance et sécurité

| Contrôle | Commande | Résultat |
|---|---|---|
| SCB | `python scripts/check_scb_compliance.py` | **exit 0** — *SCB conforme, aucune violation* |
| Traçabilité | `python scripts/validate_trace.py --all` | **exit 0** |
| Traçabilité US | `python scripts/validate_trace.py --us US-00.5` | **exit 0** |
| Synchro | `python scripts/factory_sync.py --check` | **exit 0** *(avec son avertissement : vérification **DOCUMENTAIRE**, l'état réel n'est pas vérifié)* |
| Secrets | `gitleaks detect --source . --config .gitleaks.toml` | **exit 0** — *72 commits scanned, no leaks found* |
| SAST | *(néant — dette connue)* | `run_gates.py --gate sast` → **« aucun gate ne correspond », exit 1** |

**PR #17 — 4 contextes requis, tous verts** (`gh pr view 17 --json statusCheckRollup`) :
`🔐 Secrets scan (gitleaks)` **SUCCESS** · `📋 Governance (SCB + traçabilité + synchro)` **SUCCESS** ·
`📱 App (gates run_gates.py)` **SUCCESS** · `check-branch-name` **SUCCESS**. `reviewDecision` = **vide**
*(limite de plateforme connue — critère 27 d'US-00.7)*.

---

## 2. Les 18 critères de test du Story File — exécutés un par un

**13 applicables à la PR nº 1 : 13 levés, 0 non levé. 5 hors diff (PR nº 2) : ni levés ni échoués.**

| # | Commande exécutée | Attendu | **Obtenu** | Statut |
|---|---|---|---|---|
| **1** | `ls docs/adr/ADR-001-*.md` | 1 fichier | `ADR-001-choix-de-stack.md`, rc=0 | ✅ **levé** |
| **2** | `grep -c "Accepté" docs/adr/ADR-001-*.md` | ≥ 1 | **3** | ✅ **levé** |
| **3** | `git diff --stat origin/main...HEAD -- ADR-005* ADR-006* ADR-007*` | 0 ligne | **0 ligne** | ✅ **levé** |
| **4** | `grep -ciE "iOS\|Android\|deps_audit\|SAST" ADR-001` | ≥ 4 | **15** *(détail : iOS 7 · Android 7 · deps_audit 2 · SAST 4)* | ✅ **levé** |
| **5** | catégorie Art. 4 → gate qui la **réalise** *(script rejoué)* | **1 seul échec : `SAST`** | **1 échec, et c'est `SAST`** | ✅ **levé** |
| **6** | le gate réalisant ne porte pas `"blocking": false` | **1 seul échec : `audit de dépendances`** | **1 échec, et c'est `app.deps_audit`** | ✅ **levé** |
| **7** | `grep -c "branch-naming" CONSTITUTION.md` | ≥ 1 | **0** | ⚪ **hors diff — PR nº 2** |
| **8** | `grep -cE "coverage_ratchet" CONSTITUTION.md` + contexte | « à activer par US-00.6 » | **1**, cité comme **seuil en vigueur** | ⚪ **hors diff — PR nº 2** |
| **9** | `git diff origin/main...HEAD -- docs/governance/CONSTITUTION.md` | 🔴 **VIDE** | **0 octet, 0 ligne** · absent de `--name-only` | ✅ **levé — le point dur d'AC-4** |
| **10** | diff de la PR nº 2 | CONSTITUTION + PROJECT_LOG seuls | *(sans objet)* | ⚪ **hors diff — PR nº 2** |
| **11** | `grep -nE "^\*\*Version" CONSTITUTION.md` | `1.1` + date | **rc=1, aucune sortie** | ⚪ **hors diff — PR nº 2** ⚠️ *voir edge case nº 4* |
| **12** | diff CONSTITUTION `\| grep -cE "^[+-]## Art\. [^4]"` | 0 | **0** *(trivialement, diff vide)* | ⚪ **hors diff — PR nº 2** |
| **13** | 3 écarts hors périmètre nommés **avec destinataire** | 3/3 | **3/3** : SAST Dart → **US-00.8** · `coverage_ratchet` → **US-00.6** · `CONSTITUTION.md` non protégé → **US-00.8** *(+2 lignes en sus : contradiction Art. 4 → **PR nº 2**, iOS/Android → US dédiée)* | ✅ **levé** |
| **14** | `grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md` | ≥ 1 | **5** | ✅ **levé** |
| **15** | `grep -rn "~~" docs/adr/ADR-001-*.md` | rc=1 | **rc=1** | ✅ **levé** |
| **16** | `python scripts/run_gates.py --all` | exit 0 | **exit 0**, 5 gates | ✅ **levé** |
| **17** | `check_scb_compliance.py` · `validate_trace.py --us US-00.5` | exit 0 | **exit 0** · **exit 0** | ✅ **levé** |
| **18** | runner BDD / step definitions | **ABSENT**, 0 exécuté | **absents**, **0 exécuté** | ✅ **levé** |

> ⚠️ **Je conteste le classement « hors diff » des critères 5 et 6** qui m'était transmis : ils portent sur
> `factory.config.json` et sur le **texte actuel** de l'Art. 4, **pas** sur la PR nº 2. Ils sont donc
> **exécutables aujourd'hui**, et je les ai exécutés : ils rendent **exactement** les deux échecs annoncés,
> **et pas un de plus**. Le critère nº 5 **n'est plus falsifié par son propre outil** — le correctif NB-2
> tient. Restent **hors diff** : **7, 8, 10, 11, 12** *(5 critères)*.

**Vérification indépendante des affirmations factuelles d'ADR-001** *(AC-1 « Erreur » : rien qui ne soit
établissable par lecture d'un fichier réel)* — **5 sondages, 5 confirmations** : `lib/` contient
**1 seul fichier** (`lib/main.dart`) · **0** occurrence de `dart:io`/`http`/`shared_preferences`/`sqflite`
dans `lib/` · `pubspec.yaml` → `sdk: ^3.12.2` · `docs/adr/` → **4** ADR (registre **3 → 4** conforme,
002-004 réservés et absents) · `coverage_min = 80`. Les 5 commandes du tableau §Décision sont **verbatim**
identiques à `factory.config.json` *(correctif NB-5 tenu)*.

---

## 3. Les 6 AC — couverture et orphelins

| AC | Contrôles exécutés qui le couvrent | Verdict de couverture |
|---|---|---|
| **AC-1** ADR-001 publié | critères **1, 2, 3** + les **5** sondages factuels du §2 | ✅ **couvert** |
| **AC-2** limitations dites | critère **4** *(détail par motif : les 4 honnêtetés présentes)* | ✅ **couvert** |
| **AC-3** Art. 4 exact | critères **5, 6** *(volet « contrôle de sortie », exécuté)* ; volets **corps** et **Enforcement** = PR nº 2 | 🟠 **partiel** — la moitié livrable est hors PR nº 1 |
| **AC-4** clause de révision | critère **9** *(diff CONSTITUTION **vide** : la lettre « PR dédiée » est tenue)* ; critères 10-12 = PR nº 2 | 🟠 **partiel** — l'ordre de séquence n'est prouvable qu'à la PR nº 2 |
| **AC-5** aucune contradiction nouvelle tue | critères **13, 14, 15** + `sweep_transmissions.sh` | ✅ **couvert**, avec la réserve du §4 |
| **AC-6** preuves outillées + portée des scénarios | critères **16, 17, 18** + existence de `entry_state/` et `conformite_ac.txt` | 🔴 **couvert dans la forme, PERCÉ dans le fond** — voir §4 |

**AC orphelins (aucun test ne les couvre) : 0.**

**Volet d'AC orphelin — 1, et il est causal du FAILED : `AC-6 « Erreur ».** L'énoncé *« un verdict fondé
sur la seule relecture d'un agent, sans sortie d'outil archivée, est invalide »* **n'a AUCUN critère de
test parmi les 18**. Aucun contrôle ne vérifie qu'une **assertion chiffrée** d'un rapport soit **produite
par une commande publiée**. C'est exactement l'espace dans lequel les 7 écarts du §4 ont survécu aux deux
audits. Le re-audit l'avait écrit : *« le projet a la RÈGLE, il n'a AUCUN MÉCANISME »* — le mécanisme
manquant est un **critère de test**, et il n'existe pas.

---

## 4. 🔴 MOTIF DU FAILED — par EXTENSION du défaut, pas par liste d'exemples

### 4.1 La classe

> **Défaut** : *une **assertion chiffrée** ou un **emplacement** écrit **à la main** à côté d'une commande,
> jamais relu dans la sortie de cette commande.*

C'est la classe déjà **actée quatre fois en deux jours** par @Architect lui-même
(`reports/US-00.5/correctifs_failed_revue.txt`, FAUTE 1 et FAUTE 2) et déclarée **non éteinte** par le
re-audit. **Je n'en cherchais pas un cinquième exemplaire : j'ai mesuré l'EXTENSION de la classe** sur
l'ensemble des assertions chiffrées de `reports/US-00.5/**`, en **rejouant chaque commande**.

### 4.2 Le balayage, et son décompte outillé

**Critère de sortie publié comme un script exécutable et rejouable — jamais recopié à la main :**

```sh
sh reports/US-00.5/qa_assertions_chiffrees.sh ; echo $?
```

**Résultat de l'exécution du 2026-07-30 sur `e6d5c1d`** :

```
OK=27  ECART=7        (34 assertions rejouées)   EXIT=1
```

| | Nombre |
|---|---|
| Assertions chiffrées présentes dans `reports/US-00.5/*.txt` | **42** *(correctifs 29 · conformite_ac 13 · entry_state 0)* |
| Commandes **publiées** (`$ …`) dans ces mêmes fichiers | **14** |
| Assertions **rejouées** par mon script | **34** |
| ✅ **conformes** (valeur écrite = valeur obtenue) | **27** |
| 🔴 **ÉCARTS** (la commande contredit le chiffre écrit) | **7** |
| Assertions chiffrées **en prose sans commande publiée** dans `correctifs_failed_revue.txt` | **24 pour 4 commandes publiées** |

### 4.3 Les 7 écarts — « Action effectuée → Résultat attendu → Résultat obtenu »

**E-1 · `conformite_ac.txt`, critère 14 — commande PUBLIÉE, chiffre faux.**
- **Action** : `grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md`
- **Attendu** (écrit dans le rapport, sur la ligne même de la commande) : **2**
- **Obtenu** : **5**

**E-2 · `conformite_ac.txt`, critère 4 — décompte des honnêtetés.**
- **Action** : `grep -ci "iOS" docs/adr/ADR-001-choix-de-stack.md`
- **Attendu** (écrit) : **6** — **Obtenu** : **7**

**E-3 · `conformite_ac.txt`, critère 4 (suite).**
- **Action** : `grep -ci "SAST" docs/adr/ADR-001-choix-de-stack.md`
- **Attendu** (écrit) : **2** — **Obtenu** : **4**

**E-4 · `correctifs_failed_revue.txt`, contrôle **RB-4** — le contrôle du marqueur du 3ᵉ faux vert.**
- **Action** : rechercher **une** ligne portant **à la fois** le marqueur et la chaîne
  `LA COMMANDE REND 5` → `grep -c 'PERIME-2026-07-30.*LA COMMANDE REND 5'`
- **Attendu** (écrit) : **1** — **Obtenu** : **0** *(la chaîne est coupée par un retour à la ligne : « … LA »
  puis « COMMANDE REND 5. »)*. Le marqueur **est** bien sur la ligne de l'assertion fautive ; c'est le
  **contrôle** qui est faux, et il porte sur la 1ʳᵉ leçon d'US-00.7.

**E-5 · `correctifs_failed_revue.txt`, **CONTRÔLE NÉGATIF DU PÉRIMÈTRE** — le contrôle qui certifie la
borne que j'étais chargé d'examiner le plus durement.**
- **Action** : rejouer le motif **du script lui-même** (`ASSIGNE`, avec ses 3 filtres `grep -v`) **restreint
  à la section exclue**, bornes **calculées**
- **Attendu** (écrit dans le rapport) : **0**, avec la conclusion *« l'exclusion ne crée AUCUNE zone franche »*
- **Obtenu** : **2** *(deux lignes de la section `### [US-00.5]`)*. Le **0** n'est atteignable qu'avec un
  **filtre supplémentaire non documenté** (exclusion de l'exception nommée `US-00.5 GAGNE`). **La commande
  n'est pas publiée** → le chiffre est **invérifiable en l'état**, et le seul motif publié le contredit.
  Aggravant : ce même contrôle **désigne son périmètre par des numéros de ligne écrits en prose**
  (« 557..766 ») — la **3ᵉ leçon d'US-00.7**, dans le contrôle chargé de prouver la borne. *(Mon test de
  mutation le confirme volatile : une seule ligne insérée porte la borne à 557..767.)*

**E-6 · `correctifs_failed_revue.txt`, classement des 5 occurrences NB-1 — désignation par numéro, DÉRIVÉE.**
- **Action** : `grep -rn "dernier commit seulement\|ne compare que le" …` puis lire la ligne **27** de
  `correctifs_failed_revue.txt`, que le rapport désigne comme la 5ᵉ occurrence
- **Attendu** : la ligne 27 porte l'un des deux motifs
- **Obtenu** : la ligne 27 est *« « un grep de motifs matche la documentation des motifs ». Mon propre
  script en est »* — **elle ne porte aucun des deux motifs**. L'emplacement **réel** est la ligne **44**.
  ⇒ Le rapport contient une **désignation vivante par numéro de ligne**, et elle a **glissé** — alors
  qu'il déclare **deux fois** *« 0 désignation VIVANTE par numéro de ligne »* (bloc RB-2 et bloc ITEM 7).
  Le **fond** du classement est juste *(c'est bien la commande de grep échoïsée)* ; c'est la **désignation**
  qui est fausse, et c'est précisément le défaut que la leçon décrit.

**E-7 · `correctifs_failed_revue.txt`, bloc B-1 — sortie collée non reproductible.**
- **Action** : rejouer `sh reports/US-00.5/sweep_transmissions.sh`, sous lequel une sortie est collée
- **Attendu** : la sortie collée est celle de la commande
- **Obtenu** : la sortie collée porte `SCB:1044` et `=== FIN — … est un DEFAUT NON COUVERT ===` ; le script
  **actuel** rend `SCB:1158`, une **ligne d'en-tête d'exclusion** absente de la capture, et
  `=== FIN — … est a CLASSER … ===`. **Aucun des trois éléments ne concorde.** Et le paragraphe
  immédiatement dessous affirme *« CE BLOC NE DÉCLARE PLUS AUCUN DÉCOMPTE NI AUCUN NUMÉRO DE LIGNE »*
  alors que **2** numéros de ligne subsistent dans ses 12 premières lignes *(mesuré)*.

### 4.4 Pourquoi c'est un FAILED, et pas une remarque

1. **La classe est la même que celle déjà actée quatre fois** — donc le FAILED ne sanctionne pas une
   inattention, il constate que **le correctif n'a pas couvert l'extension du défaut**. C'est *littéralement*
   le motif du `FAILED` rendu par l'audit de revue au 1ᵉʳ passage : **corriger le RENVOI, pas le DÉFAUT**.
2. **Un des sept porte sur le contrôle qui certifie la borne contestée** (E-5) : la seule preuve écrite que
   l'exclusion de section est inoffensive est un **`0` écrit à la main** que le motif du script rend à **2**.
3. **Trois portent sur `conformite_ac.txt`** (E-1 à E-3), qui **EST** la pièce exigée par **AC-6 Nominal**
   *(« revue de conformité AC ↔ livrable, point par point, archivée »)* et par la **DoD 11**. La preuve
   réglementaire de l'US contient **3 chiffres faux sur 13**.
4. **Aucun n'était détectable par les gates** : `run_gates`, `check_scb_compliance`, `validate_trace`,
   `factory_sync`, `gitleaks` sont **tous verts**. Le défaut vit **exactement** là où aucun mécanisme ne
   regarde — d'où le volet d'AC orphelin du §3.

### 4.5 Ce que le FAILED ne dit pas

⛔ **Aucun des 7 écarts n'invalide un livrable.** Vérifié : `docs/adr/ADR-001-choix-de-stack.md` est
**conforme** aux 18 critères applicables, `CONSTITUTION.md` est **absent du diff**, les 4 honnêtetés sont
**présentes**, les 3 écarts hors périmètre sont **nommés avec destinataire**. **Le FAILED porte sur les
PREUVES, pas sur le produit** — et dans un projet où « un verdict sans sortie d'outil archivée est
invalide » (AC-6 Erreur), une preuve fausse n'est pas un détail de forme.

### 4.6 Critère de sortie — rejouable, et c'est lui qui fait foi

```sh
# Le seul énoncé que ce rapport revendique sur ce point :
sh reports/US-00.5/qa_assertions_chiffrees.sh   # ⇒ exige ECART=0 ; rend aujourd'hui ECART=7, exit 1
```

⚠️ **Aveu, parce que la règle vaut aussi pour moi** : au premier jet, **mon propre script est tombé dans le
piège** *« un grep de motifs matche la documentation des motifs »* — en citant le motif NB-1, il faisait
monter le compte de **5 à 8** et j'allais imputer à @Architect un écart **que j'avais créé**. Correction :
mes artefacts sont exclus **nommément** de ce seul contrôle, **jamais par un filtre silencieux**, et le
compte **non exclu** est **affiché à côté par le script lui-même** — ⛔ **je ne le recopie pas ici** : il
monte à chaque phrase que j'écris sur le sujet *(il a déjà bougé entre ma première rédaction et celle-ci,
ce qui est la démonstration la plus courte du piège)*. **Sa valeur du jour est dans la sortie, pas dans ma
prose.** Le piège est **structurel**, pas
individuel — ce qui renforce la conclusion du §4.4 point 4.

---

## 5. La borne du `sweep_transmissions.sh` — examen demandé, et il est charge par charge

**Question posée** : l'exclusion de la section `### [US-00.5]` est-elle complaisante ?

**Réponse : NON complaisante, mais SUR-AFFIRMÉE, et sa preuve est fausse (E-5). Le vrai trou est ailleurs.**

**Contre-épreuve nº 1 — l'exclusion masque-t-elle une charge éteinte ?** *(même motif, exclusion retirée)*
→ **2 lignes** apparaissent, **et seulement 2**. Les deux sont **ma propre prose citant l'exception nommée**
pour la justifier ; **aucune** n'est une charge éteinte. ⇒ **Aujourd'hui, l'exclusion ne dissimule rien.**
La **justification sémantique** de l'en-tête (« une section ne peut pas se transmettre une charge à
elle-même ») est **recevable**, et le refus de filtrer silencieusement l'exception est **la bonne décision**.

**Contre-épreuve nº 2 — TEST DE MUTATION** *(4 mutants injectés dans une **copie** du SCB)* :

| Mutant | Ligne injectée | Emplacement | Détecté ? |
|---|---|---|---|
| **A** | `S11 transmis à **US-00.5**, @PO tranchera le véhicule.` *(formulation exacte de la charge réelle)* | **dans** la section exclue | 🔴 **NON** |
| **B** | la même | hors section | ✅ oui |
| **C** | `cet écart est à traiter en US-00.5` | hors section | 🔴 **NON** |
| **D** | `correction du texte normatif → US-00.5.` | hors section | 🔴 **NON** |

**Ce que ça établit, et qui est plus grave que la borne contestée** : le **motif** `ASSIGNE` est une
**énumération fermée de 6 formulations littérales**. Il capture **8 des 25** lignes du SCB qui mentionnent
US-00.5. Deux reformulations banales d'une même charge (*« à traiter en »*, *« → »*) **passent au travers
alors qu'elles sont HORS de la zone exclue**. ⇒ **La faiblesse réelle du critère de sortie est son MOTIF,
pas son PÉRIMÈTRE.** On a débattu de la borne pendant que le trou était dans le grep.

**Ce que je conteste précisément** : l'en-tête écrit *« CE QUE CETTE EXCLUSION N'AUTORISE PAS : … elle ne
crée aucune zone franche »*. Le mutant **A** prouve que **si**, au regard du défaut **tel que le script
l'énonce** (« *le SCB assigne encore à US-00.5 une charge ÉTEINTE* » — le SCB **inclut** la section
US-00.5). L'énoncé exact serait : *« aucune zone franche **à condition** qu'un tiers balaye la section »*.
Ce tiers, c'est moi, et **je l'ai fait** *(contre-épreuve nº 1 : 0 charge éteinte dans la section)*. Mais
c'est une **obligation de process**, pas un mécanisme — la même nature que la case 34 d'US-00.7.

---

## 6. DoD — décompte exact, et le contrôle est INERTE

```
grep -c '^- \[x\]' docs/stories/US-00.5-adr-stack-constitution.md  ->  0
grep -c '^- \[ \]' docs/stories/US-00.5-adr-stack-constitution.md  ->  23
```

| | Nombre | Détail |
|---|---|---|
| **Cases cochées** | **0 / 23** | — |
| **Cases cochées à TORT** | **0** | *(le seul point positif du décompte : rien de conditionné à la PR nº 2 ou à une action humaine n'est coché — parce que **rien** ne l'est)* |
| **Cases factuellement ACQUISES mais non cochées** | **17** | 1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 16, 17, 20, 21, 22, 23 |
| **Cases NON satisfiables sur la PR nº 1** | **6** | **5** et **6** *(amendement → PR nº 2)* · **14** *(approbation humaine)* · **15** *(fusion par l'humain)* · **18** *(la mienne)* · **19** *(partie « ligne dédiée à l'amendement » → PR nº 2)* |

Vérifications des 17 acquises, par exécution : `git diff origin/main...HEAD -- CLAUDE.md` → **0 ligne**
*(case 7)* · `BACKLOG.md` ligne US-00.5 porte la **note datée du 2026-07-30 avec sa conditionnalité**
*(case 22)* · `EPIC_00` porte le critère *« ADR-001 publié »* **renseigné avec sa preuve** *(case 23)* ·
`PROJECT_LOG.md` **+7 lignes** dont 3 pour US-00.5 *(case 19, partie PR nº 1)* · PR #17 ouverte avec
**4 contextes verts** *(case 13)* · audits **✅ 🔍** et **✅ 🛡️** tracés *(cases 16-17)*.

🔴 **Constat de méthode, en sus du motif principal** : la DoD écrit *« Toutes les cases doivent être
cochées avant de passer la phase `quality_assurance` »*. **Zéro** l'est. Le précédent immédiat du projet
est **US-00.7 avec 32/34 cases tenues à jour** : ici l'instrument de contrôle **n'a pas été utilisé du
tout**, alors que **17 cases sont factuellement acquises**. Ce n'est pas une omission cosmétique — une DoD
à 0/23 ne peut **ni** attester ce qui est fait, **ni** signaler ce qui manque. **Elle est à mettre à jour
avant la reprise de la QA**, avec les cases 5, 6, 14, 15, 19(partie) laissées **explicitement** ouvertes
pour la PR nº 2.

---

## 7. Edge cases testés — au-delà des cas passants

| # | Edge case | Résultat |
|---|---|---|
| **1** | **Test de mutation** du critère de sortie (4 mutants injectés dans une copie du SCB) | **3 mutants sur 4 non détectés** — §5 |
| **2** | **Contre-épreuve** du sweep, exclusion retirée | **2 lignes**, toutes deux légitimes — l'exclusion ne masque rien aujourd'hui |
| **3** | **Auto-alimentation de mon propre outil** (le grep matche sa propre documentation) | **piège reproduit**, détecté, nommé, exclusion **explicite** — §4.6 |
| **4** | **Critère nº 11 falsifié par son propre outil** *(même classe que NB-2)* | `grep -nE "^\*\*Version" CONSTITUTION.md` → **rc=1**. La version vit en **prose dans un bloc de citation** (`> … Version 1.0 — 2026-07-24.`), **jamais** en début de ligne `**Version`. **Le critère nº 11 ne pourra PAS être levé par sa propre commande après la PR nº 2**, sauf restructuration de l'en-tête. → **à corriger dans le Story File avant la PR nº 2**, via @Architect *(je ne l'interprète pas)* |
| **5** | **Faiblesse du critère nº 4** | `grep -ciE "iOS\|Android\|deps_audit\|SAST"` compte des **lignes**, pas des **honnêtetés** : **4 mentions d'« Android » seules le satisferaient**. J'ai donc exécuté le décompte **par motif** — les 4 sont réellement présentes. Le critère est **levé, mais faible** |
| **6** | **Recall du motif du sweep** | **8 lignes capturées sur 25** mentionnant US-00.5 dans le SCB |
| **7** | **Gate `sast` inexistant** *(fondement d'AC-2 nº 4 et d'AC-3)* | `run_gates.py --gate sast` → **« [ERREUR] aucun gate ne correspond », exit 1** — l'affirmation d'ADR-001 est **vraie**, vérifiée par exécution |
| **8** | **Omission résiduelle de l'Art. 4 après la PR nº 2** | Sous la correspondance **publiée** au critère nº 5 (`lint` **et** `typecheck` → `app.analyze`), **DEUX** gates réels restent hors de toute catégorie : `app.build` **et `app.format`**. Or AC-3 ne prescrit de nommer **que `app.build`** → **l'Art. 4 resterait incomplet après la PR nº 2**. Aggravant : `entry_state/art4_vs_gates_reels.txt` mappe `lint` → *« `dart format` (`app.format`) **et** `flutter analyze` »*, ce qui **contredit** la correspondance publiée au Story File. **Contradiction interne à la même livraison** → à trancher par @Architect avant T10 |
| **9** | **Extension du correctif NB-6** *(énumération des motifs de `protect_files.sh`)* | Réel : **9** motifs *(`sed -n '28p' .claude/hooks/protect_files.sh`)*. **ADR-001 dit 9** ✅ *(corrigé)*. Mais **le SCB en énumère 6** et **le Story File R-2 en énumère 6** → le correctif a couvert **1 instance sur 3**. L'affirmation **porteuse** (« pas `docs/governance/**` ») est **vraie partout** ; c'est l'énumération qui reste incomplète. **Même classe que le motif du FAILED de revue** — non bloquant pour le livrable, à solder |
| **10** | **Immuabilité des ADR** | `git diff --stat origin/main...HEAD -- ADR-005* ADR-006* ADR-007*` → **0 ligne**. Aucun ADR accepté édité |
| **11** | **Fichiers protégés / code applicatif** | `factory.config.json` **absent** du diff · **0** fichier `.dart` · **0** `.github/workflows/*` — les trois interdits sont tenus |
| **12** | **Secrets sur un dépôt PUBLIC** | `gitleaks` sur **72 commits** → **no leaks found** |

---

## 8. La contradiction ADR-001 ↔ Art. 4 jusqu'à la PR nº 2 — mon avis, puisqu'il est demandé

**Je la juge ACCEPTABLE**, et les trois conditions qui la rendent acceptable sont **toutes vérifiées par
exécution** :

1. Elle est **nommée dans le livrable lui-même**, avec son destinataire :
   `grep -c "PR nº 2 de CETTE US" docs/adr/ADR-001-*.md` → **1**. La ligne est explicite : *« Le corps de
   l'Art. 4 affirme aujourd'hui LE CONTRAIRE des trois lignes ci-dessus … la contradiction est VIVE et
   VOULUE jusqu'à la fusion suivante »*. **Un auditeur qui n'ouvre que `docs/adr/` la voit nommée** —
   c'était le finding NB-9, et il est tenu.
2. Elle **résulte d'un arbitrage humain daté** (C-1, option a) qui a choisi **la lettre** de la clause
   *Révision*. L'alternative — une PR unique — aurait ouvert un écart lettre/esprit **sur le texte qui
   régit les amendements**. Le coût choisi est le moindre.
3. Elle est **bornée par une séquence de tâches ordonnée** (T9 rebase → T10-T12).

🔴 **Réserve que je verse au dossier, et qu'il ne faut pas perdre** : **ADR-001 est IMMUABLE**. Si la PR nº 2
n'était pas fusionnée, la contradiction serait **gelée dans le registre**, sa correction exigerait un
**ADR entier**, et **aucun mécanisme ne la détecterait** *(il n'existe aucun contrôle de cohérence
`docs/adr/**` ↔ `docs/governance/**` — vérifié : `check_scb_compliance.py`, `validate_trace.py` et
`factory_sync.py --check` n'en font rien)*. ⇒ **US-00.5 ne doit pas recevoir `🚀 OUI` avant la fusion de la
PR nº 2.** Ce n'est **pas** ma décision — elle appartient au rituel `/certify` (@Architect, Art. 5) — mais
c'est un constat que je consigne.

---

## 9. Actions attendues pour repasser en QA

| # | Action | Porteur |
|---|---|---|
| **A-1** | **Traiter les 7 écarts par l'EXTENSION** : rendre le critère de sortie `sh reports/US-00.5/qa_assertions_chiffrees.sh` **vert (`ECART=0`)**. ⛔ **Ne pas corriger 7 chiffres un par un** : la classe est *« un chiffre écrit à la main »*. La correction attendue est que **chaque assertion chiffrée d'un rapport soit LUE dans la sortie d'une commande PUBLIÉE** *(24 assertions en prose pour 4 commandes publiées dans `correctifs_failed_revue.txt` — c'est là le gisement)*. ⛔ **Ne pas effacer** les constats datés : les rectifier sur place, marqueur **littéral sur la ligne même** | @Architect |
| **A-2** | **Publier la commande du CONTRÔLE NÉGATIF DU PÉRIMÈTRE** (E-5) dans `sweep_transmissions.sh` ou un script frère, avec sa borne **calculée** et **jamais écrite en prose**, et **documenter** l'exclusion supplémentaire de l'exception nommée | @Architect |
| **A-3** | **Corriger la désignation dérivée** (E-6) : la 5ᵉ occurrence est **la ligne portant la commande de grep**, à désigner **par son texte**, jamais par `:27` | @Architect |
| **A-4** | **Mettre la DoD à jour** : cocher les **17** cases acquises, laisser **5, 6, 14, 15, 19(partie)** explicitement ouvertes pour la PR nº 2 | @Architect |
| **A-5** | **Trancher l'omission résiduelle de l'Art. 4** (edge case 8) : `app.format` est-il réalisé par la catégorie `lint` (⇒ corriger la correspondance publiée au critère nº 5) ou **non couvert** (⇒ AC-3 doit exiger qu'il soit nommé, comme `app.build`) ? **Contradiction interne à la livraison**, à lever **avant T10** | @Architect |
| **A-6** | **Reformuler le critère de test nº 11** (edge case 4), falsifié par sa propre commande : la version de la Constitution n'est pas en début de ligne. **À faire avant la PR nº 2**, sans quoi le critère sera **inlevable** | @Architect |
| **A-7** | *(non bloquant)* **Étendre le correctif NB-6** au SCB et au Story File (edge case 9) — **6 motifs énumérés contre 9 réels**, à **2** emplacements | @Architect |
| **A-8** | *(non bloquant, à verser à `/audit-methodo` ou US-00.8)* **Le défaut n'a AUCUN mécanisme** : ajouter un contrôle de type `qa_assertions_chiffrees.sh` au **gate `governance`** est la seule sortie durable. Le volet **AC-6 « Erreur »** est **orphelin de critère de test** dans **toutes** les US du projet | @Architect + @DevOps |

---

## 10. Bornes de ce verdict — ce qu'il n'atteste PAS

1. ⛔ **Il n'atteste RIEN du livrable de la PR nº 2.** Les critères **7, 8, 10, 11, 12**, les cases DoD
   **5, 6, 14** et les volets *corps* + *Enforcement* d'**AC-3** sont **hors diff**. Un `🧪 PASS` futur sur
   la PR nº 1 ne vaudra **pas** pour l'amendement constitutionnel.
2. ⛔ **Aucune couverture applicative n'est attestée.** **89,5 % (17/19 lignes)** portent sur le
   **squelette Flutter** (`lib/main.dart`, 1 fichier) : c'est une **non-régression**, pas une mesure du
   livrable. **2 tests** unitaires pour l'ensemble du dépôt.
3. ⛔ **Les 21 scénarios Gherkin ne sont PAS exécutés** — ni passed, ni skipped : **inexistants comme
   tests**. Ni step definitions, ni runner, ni lecture CI de `tests/features/**`. **Aucune preuve E2E.**
4. ⛔ **Aucun verdict de sécurité applicative.** `run_gates --gate sast` → **exit 1, le gate n'existe pas** ;
   `deps_audit` mesure l'**obsolescence**, pas la vulnérabilité. **Aucun scan de CVE n'existe.** `gitleaks`
   ne couvre que les **secrets**.
5. ⛔ **Mon balayage n'est PAS exhaustif** : il porte sur `reports/US-00.5/**` et le **SCB**, sur les
   assertions **chiffrées** dont la commande était **reconstructible** (**34 sur 42**). **8** assertions
   restent non rejouables faute de commande publiée. Le corpus **hors US-00.5** (`docs/`, `CLAUDE.md`,
   `PROJECT_LOG.md`) n'est **pas** couvert par ce contrôle.
6. ⛔ **Rien n'est attesté sur la PERSISTANCE** de l'état vérifié : PR #17 verte **à 2026-07-30T16:07Z**,
   protection de branche **conditionnelle à la visibilité publique** du dépôt, et **aucune détection
   automatique de dérive** (dette ouverte).
7. ⛔ **`factory_sync.py --check` est DOCUMENTAIRE** — son propre avertissement le dit : *« l'état RÉEL de
   la protection de branche sur GitHub n'est PAS vérifié ici »*.
8. ⛔ **Je ne délivre pas de certification.** Constitution **Art. 5** : le `🧪 PASS` est mon seul pouvoir,
   `🚀 OUI` appartient au rituel `/certify` (@Architect). **Ici je ne délivre même pas le `🧪 PASS`.**
9. ⛔ **Aucun fichier hors `reports/` n'a été modifié par la QA.** Le SCB, `CLAUDE.md`, le Story File,
   ADR-001 et le code sont **intacts** — seuls `reports/US-00.5/qa.md` et
   `reports/US-00.5/qa_assertions_chiffrees.sh` sont écrits.

---

## 11. Verdict

## 🔴 **QA Status = FAILED**

**Motif, par extension** : la classe de défaut *« une assertion chiffrée ou un emplacement écrit à la main
à côté d'une commande, jamais relu dans sa sortie »* — **déjà actée quatre fois par @Architect et déclarée
non éteinte par le re-audit** — est **encore présente à 7 exemplaires sur 34 assertions rejouées**, dont
**3 dans `conformite_ac.txt`**, qui **est** la preuve réglementaire exigée par AC-6 et la DoD 11, et **1
dans le contrôle même qui certifie la borne du critère de sortie**. Le décompte est **outillé et
rejouable** : `sh reports/US-00.5/qa_assertions_chiffrees.sh` → **`OK=27 ECART=7`, exit 1**.
**Critère de sortie : `ECART=0`.**

**Ce qui est acquis et n'est pas remis en cause** : **13 critères de test applicables sur 13 levés** ·
**6 AC couverts, 0 orphelin** *(2 partiels par construction — PR nº 2)* · **5 gates verts, exit 0** ·
**2 tests passed / 0 skipped / 0 failed**, couverture **89,5 % ≥ 80 %** · **SCB, trace, synchro, gitleaks
tous exit 0** · **PR #17, 4 contextes requis verts** · **`CONSTITUTION.md` ABSENT du diff — la lettre de
la clause *Révision* est tenue** · **contradiction ADR-001 ↔ Art. 4 jugée ACCEPTABLE**, nommée dans le
livrable avec son destinataire.

**Le FAILED porte sur les PREUVES, pas sur le produit.** Dans un projet dont l'AC-6 écrit qu'*« un verdict
sans sortie d'outil archivée est invalide »*, une preuve fausse ne peut pas être classée cosmétique.

---
*@QA_Tester · contexte frais · `claude-opus-5[1m]` · 2026-07-30 · HEAD `e6d5c1d` · PR #17*
*Tous les chiffres de ce rapport sont issus d'une exécution. Critère de sortie rejouable :*
*`sh reports/US-00.5/qa_assertions_chiffrees.sh`*
