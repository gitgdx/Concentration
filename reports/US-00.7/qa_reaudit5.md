# US-00.7 — Rapport QA, 6ᵉ passage (re-audit 5) — @QA_Tester

| Champ | Valeur |
|---|---|
| **US** | US-00.7 — Protection de la branche principale : application effective, preuve par l'effet, mise en cohérence du corpus |
| **Agent** | @QA_Tester — **même contexte que le 5ᵉ passage**, saisi pour **honorer son propre critère de sortie** |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-07-30 |
| **Branche** | `feat/US-00.7-cloture` — HEAD **`813fad0`** (correctifs du 5ᵉ FAIL), `origin/main` = **`cad24e8`** |
| **Objet** | Vérifier **mon** critère de sortie publié au §9 de `qa_reaudit4.md`, contrôler **à charge** que les corrections sont réelles, statuer sur la **case 29** |
| **Pré-conditions** | `validate_trace.py --us US-00.7` → **exit 0** · `EVT_CODE_REVIEW_PASSED` et `EVT_SECURITY_AUDIT_PASSED` présents |
| **Rapports antérieurs** | `qa.md` · `qa_reaudit.md` · `qa_reaudit2.md` · `qa_reaudit3.md` · `qa_reaudit4.md` — **aucun écrasé** |

---

## 0. VERDICT

# 🧪 PASS

**Mon motif est mort, et je le dis sans détour parce que je m'y étais engagée par écrit.**

Au 5ᵉ passage j'ai publié un critère de sortie unique, machine-vérifiable, avec cette phrase :
« *si elle est vide, ce motif meurt et je n'en cherche pas un autre* ». **Je l'ai exécuté. Il est
satisfait, exactement.** Je ne cherche donc pas un 6ᵉ motif — c'était tout l'objet de le publier.

```
$ <commande du §3.2 de qa_reaudit4.md, VERBATIM, sur HEAD = 813fad0>
STORY_CERTIFICATION_BOARD.md:268:  déblocage et **non exécutées**. Livrables : …

>>> 1 ligne — exactement l'UNIQUE exception que mon §9 admet (entrée datée d'US-00.4,
    qu'il est INTERDIT de réécrire : DoD 19 / critère 23)
```

| Contrôle demandé | Résultat |
|---|---|
| 1. Commande du §3.2, **verbatim** | ✅ **`SCB:268` seule** — critère de sortie **satisfait** |
| 2. `md5` / `git blame` **à charge** sur les corrections déclarées | ✅ **8/8 réellement modifiées** (§3) |
| 3. Aucun artefact **daté** réécrit (DoD 19, critère 23) | ✅ **0 ligne** · contrôle négatif `SCB:268` **byte-identique** |
| 4. `ci.yml` non cassé — YAML + libellés de jobs | ✅ **valide** · **4 libellés identiques point de code par point de code** · diff **100 % commentaires** |
| 5. Gates | ✅ **5/5 exit 0** · gouvernance verte · `gitleaks` **0 fuite** |
| **Grille des 28 critères** | **25 LEVÉS / 3 NON LEVÉS** (20, 21, 27) — **recevables**, position du 5ᵉ passage **inchangée** |
| **DoD** | **32/34** — case **29** *(la mienne)* **non auto-cochée**, case **31** fin de cycle |

**Et je dois d'abord reconnaître une faute qui est la mienne.**

---

## 1. Ma propre faute, établie par @Architect, et je la confirme

> **Action effectuée** : exécuter la commande que j'ai **publiée** au §3.2 de `qa_reaudit4.md`, verbatim,
> sur le commit que j'auditais alors (`dcc198c`).
>
> **Résultat attendu** d'après mon propre §3.2 : **7 lignes**, celles que j'y ai listées.
>
> **Résultat obtenu** : **9 lignes.** Il en manquait **deux** : `SCB:320` et `SCB:497`.

```
$ <commande du §3.2, verbatim, sur dcc198c>
1  docs/GIT_PROTECTION.md:277           5  STORY_CERTIFICATION_BOARD.md:497   ← ABSENTE de mon §3.2
2  .github/workflows/ci.yml:13          6  STORY_CERTIFICATION_BOARD.md:1015
3  STORY_CERTIFICATION_BOARD.md:268     7  STORY_CERTIFICATION_BOARD.md:1016
4  STORY_CERTIFICATION_BOARD.md:320  ←  ABSENTE de mon §3.2
                                     8-9  SCB:1017 · reports/US-00.7/README.md:26
>>> 9 lignes
```

**Cause exacte, sans arrangement** : mon script de travail comportait un filtre supplémentaire
(`grep -v "T16→T19"`) que **je n'ai pas reporté dans la commande publiée**. J'ai donc publié une
commande qui ne produit **pas** le résultat que j'affirmais être le sien.

**C'est précisément la classe de défaut que je sanctionnais** : une vérification publiée dont le
résultat annoncé ne correspond pas à ce que l'outil rend. Je l'ai commise dans le rapport même qui la
dénonçait — comme @Architect l'a commise dans le correctif censé la clore *(marqueur sur la ligne
suivante, §4.3)*. **Deux occurrences symétriques, dans le même cycle.** Elle est d'autant moins
excusable que mon §9 n'admettait **qu'une** exception, et que la lettre — pas l'esprit — est ce qui se
vérifie par outil.

⚠️ **Aggravant, et c'est le pire** : mon filtre silencieux a **dissimulé `SCB:497`**, que @Architect
qualifie de survivance **la plus grave du corpus**. Après vérification, **je confirme ce jugement** :
cinq assertions, dans la puce « *Ce qui n'est PAS déployé* » du visa @DevOps, dont « **`main` n'est
toujours pas protégée et ne peut pas l'être** » — c'est-à-dire **la négation exacte de ce que cette US
prouve**, dans le tableau de bord qui pilote le projet. **Cinq passages QA, dont deux de ma main, et
quatre passes de balayage l'ont manquée.** Mon filtre non publié est ce qui l'a soustraite au 5ᵉ.

**Conséquence méthodologique que je verse à US-00.8** : ⛔ **un critère de sortie doit être publié comme
un script exécutable, pas recopié à la main dans un rapport.** Toute divergence entre l'outil utilisé et
l'outil publié est **invisible par construction**.

---

## 2. Contrôle 1 — mon critère de sortie, exécuté verbatim

```
$ VIVANTS="CLAUDE.md docs/epics/EPIC_00-fondations.md docs/GIT_PROTECTION.md .github/workflows/ci.yml
  scripts/apply_branch_protection.sh scripts/check_branch_protection.py .claude/commands/audit-methodo.md
  .claude/commands/sprint-status.md docs/SQUAD_GUIDE.md tests/fixtures/US-00.4/README.md
  scripts/githooks/pre-push STORY_CERTIFICATION_BOARD.md reports/US-00.7/README.md"
$ MOTIF="pas encore été observ|n'a pas été observ|pas encore prouvé|n'est pas prouvé|n'a pas eu lieu|
  non exécutée|Non exécuté|reste une inférence|n'en est pas la preuve|encore obtenable|
  jamais passés en CI|CHEMIN DE SORTIE|referme \*\*D-1|referme D-1|ciblé sur le seul critère"
$ for f in $VIVANTS; do [ -f "$f" ] && grep -nE "$MOTIF" "$f" | grep -v "PÉRIMÉ-2026-07-29" \
    | sed "s|^|$f:|"; done

STORY_CERTIFICATION_BOARD.md:268:  déblocage et **non exécutées**. Livrables : `scripts/check_branch…`
>>> 1
```

**Sur `dcc198c` : 9 lignes. Sur `813fad0` : 1 — et c'est l'exception admise.**
`SCB:268` est le visa **daté d'US-00.4** (« T16→T19 non exécutées ») : **exact à sa date**, et la
**DoD 19** comme l'**AC-5 *erreur*** m'interdisent d'exiger qu'on le réécrive. **Mon critère de sortie
est satisfait à la lettre.**

**Balayage étendu, de ma propre initiative — 20 documents vivants, 9 familles de motifs** (bien au-delà
du mien : « n'est pas protégée », « ne peut pas l'être », « NON ATTEIGNABLE », « impossible à cocher »,
« DETTE MAJEURE », « 403 de plan », « aucun status check requis », « armé, non appliqué », « risque #2
OUVERT », « case 34/13 décochée », `28/34` → `31/34`, `9fdb7fd`, `US-00.7-certif`, « dérogation
active »…) → **41 lignes, triées une par une.**

**Résultat du tri : aucune faute retenue.** Toutes sont légitimes, et je documente le motif :

| Famille | Nb | Pourquoi c'est légitime — vérifié |
|---|---|---|
| **Blocs explicitement HISTORISÉS** | 12 | `GIT_PROTECTION.md:90` est sous le titre `## 📅 Constat daté du 2026-07-26 — HISTORISÉ (levé le 2026-07-27…)` → `### Les quatre faits du 2026-07-26`. `EPIC_00:52` porte « *Historique de cette ligne : barrée le 2026-07-26* ». `tests/fixtures/US-00.4/README.md:31` est couvert par un **encadré additif en tête** qui **cite sa cible mot pour mot** et la déclare levée — *la bonne forme : greppable, sans renvoi de ligne* |
| **Énoncés CONDITIONNELS, donc VRAIS** | 6 | `ci.yml:28`, `apply_branch_protection.sh:21`, `audit-methodo.md:43`, `GIT_PROTECTION.md:316` : « un retour en privé **ramènerait** le 403 ». Ce sont des **avertissements exacts**, pas des états périmés |
| **Chaînes de CODE / docstrings** | 4 | `check_branch_protection.py:14,78,604,876` — messages du chemin `exit 2` (403), **toujours nécessaires** puisque le cas est conditionnel |
| **NÉGATIONS correctes** | 3 | `GIT_PROTECTION.md:351` et `audit-methodo.md:23` : « *il ne porte **plus** la dette “main n'est pas protégée” (close), mais la surveillance de sa PERSISTANCE* » |
| **Titres de dette + colonne Statut à jour** | 2 | `GIT_PROTECTION.md:571` : intitulé historique en colonne *Dette*, « ✅ **CLOSE le 2026-07-28** » en colonne *Statut*. `EPIC_00:94` : constat du 26 conservé, statut « ✅ **CLOS le 2026-07-28 par US-00.7** » |
| **Visas DATÉS d'US-00.4 / ADR-007 au SCB** | 13 | `SCB:220,231,248,268,270,273,382,561,568` · `ADR-007:39,81,124,131` — enregistrements de cycle, **interdits de réécriture** |
| **Blocs datés d'US-00.7 SOUS marqueur d'en-tête** | 2 | `SCB:732` (« AC-4 nominal NON satisfait, case 13 DÉCOCHÉE ») est **dans** le bloc ouvert l. 726 par « ✅ **PÉRIMÉ-2026-07-29** — *le paragraphe ci-dessous vaut pour la PR #12 et pour cette date seule ; le refus **A ÉTÉ obtenu** depuis* » |
| **Textes NOUVEAUX et EXACTS** | 2 | `SCB:1085` et `README.md:21` — les corrections elles-mêmes |
| 🟡 **1 borne nommée, non retenue comme faute** | 1 | **`SCB:858`** — voir §6.1 |

---

## 3. Contrôle 2 — `md5` / `git blame` **à charge**, comme au 5ᵉ passage

C'est ce contrôle qui a rendu le 5ᵉ FAIL indiscutable *(bloc de sortie du SCB déclaré corrigé,
byte-identique)*. **Je le refais, en sens inverse, contre le correcteur.**

| Assertion | md5 sur `dcc198c` | md5 sur `813fad0` | Verdict |
|---|---|---|---|
| **S1** `ci.yml:12-13` | `ccc05b7c` | `f198bebd` | ✅ **réellement modifiée** |
| **S2** `GIT_PROTECTION.md:276-278` | `6c99f97b` | `e69c39df` | ✅ **réellement modifiée** |
| **S3/S4** bloc de sortie du SCB | **`167ed8fd`** *(le hachage du 5ᵉ FAIL)* | `59bc907c` | ✅ **réellement modifiée** |
| **S5** `reports/US-00.7/README.md:26` | `2c02b0c4` | `041bee56` | ✅ **réellement modifiée** |
| `SCB:320` *(non listée par moi)* | `508db492` | `581b2d91` | ✅ **réellement modifiée** |
| **`SCB:497`** *(la plus grave)* | `f5c93343` | `dd13e34e` | ✅ **réellement modifiée** |
| `SCB:529` *(séparation vrai/périmé)* | `eb9de2db` | `54181c1c` | ✅ **réellement modifiée** |
| `SCB:642` *(renvoi par n° de ligne)* | `8162d421` | `eb05a643` | ✅ **réellement modifiée** |
| 🔒 **Contrôle NÉGATIF — `SCB:268`** | `cb5f93a7` | **`cb5f93a7`** | ✅ **byte-identique — artefact daté NON touché** |

**8 corrections déclarées, 8 réellement faites. Aucune sur-affirmation.** Le contrôle négatif tient :
la seule ligne qu'il est **interdit** de toucher n'a pas bougé.

---

## 4. Contrôle 3 — les corrections sont-elles *bonnes*, pas seulement *présentes* ?

### 4.1 Le texte daté est PRÉSERVÉ, non remplacé (DoD 19, critère 23)

```
$ git diff --stat dcc198c..813fad0 -- docs/stories/US-00.4-* reports/US-00.4/ docs/adr/ADR-006-* \
    docs/stories/US-00.1-* tests/features/ reports/US-00.3/ reports/US-00.7/code_review.md \
    reports/US-00.7/security*.md reports/US-00.7/merge_block.md reports/US-00.7/po_arbitrage_s11.md \
    reports/US-00.7/non_regression.md reports/US-00.7/qa*.md
 reports/US-00.7/qa_reaudit4.md | 646 +++++++++++++++++++++    ← mon rapport, AJOUTÉ (646+/0−)
$ git diff --numstat dcc198c..HEAD -- docs/trace/          → 1  0     (append-only)
$ git log --oneline -- reports/US-00.7/qa_reaudit4.md      → 813fad0   (créé, jamais modifié)
$ grep -c "^# 🧪 FAIL" reports/US-00.7/qa_reaudit4.md      → 1        (mon verdict intact)
```

**Aucun artefact daté ou certifié n'est réécrit.** Mon propre rapport a été **ajouté** tel quel
(646 insertions / **0 suppression**) : **il n'a pas été retouché**, et son verdict `🧪 FAIL` est intact.

### 4.2 Le texte daté est cité VERBATIM, une assertion par ligne — `SCB:497`

```
- **Ce qui n'est PAS déployé** *(constat de @DevOps sur US-00.4 — exact à sa date, non réécrit ;
  chaque assertion porte son marqueur sur sa propre ligne, l'assertion étant à la phrase)* :
  - **PÉRIMÉ-2026-07-29** — « `main` n'est toujours pas protégée et ne peut pas l'être (403 de plan) »
  - **PÉRIMÉ-2026-07-29** — « `apply_branch_protection.sh` reste armé, non appliqué »
  - **PÉRIMÉ-2026-07-29** — « aucun status check requis »
  - **PÉRIMÉ-2026-07-29** — « risque #2 d'EPIC_00 OUVERT »
  - **PÉRIMÉ-2026-07-29** — « T16→T19 non exécutées »
  ⚠️ Les CINQ assertions ci-dessus sont FAUSSES depuis le 2026-07-28 … dépôt PUBLIC · `main` protégée
    (`"protected": true`) · 4 status checks REQUIS · risque #2 CLOS · T16→T19 exécutées.
```

**Vérifié ligne par ligne : les 5 portent leur marqueur sur leur propre ligne.** Le texte d'origine est
**conservé, entre guillemets**, et le redressement est écrit. **C'est exactement la forme que réclamait
la leçon 1 du 4ᵉ passage**, et elle est ici tenue — pas approximée.

### 4.3 Le défaut auto-dénoncé par @Architect — je confirme qu'il est corrigé

@Architect déclare que sa **première** annotation de `SCB:497` posait le marqueur sur la ligne
**suivante** — le défaut nommé par le 4ᵉ passage, reproduit dans le correctif censé le clore, et rendu
**par la sortie du balayage, pas par la relecture**. **État final vérifié : une assertion par ligne,
marqueur sur la ligne.** L'auto-dénonciation est exacte et le défaut est clos. **Je la porte au crédit
du correcteur** : c'est la démonstration de sa propre leçon 2, appliquée contre lui-même.

### 4.4 `SCB:529` — la seule correction qui exigeait un *jugement*, et il est juste

Ici il ne fallait **pas** tout périmer : il fallait **séparer**. Vérifié :

* **Conservé comme VRAI** : « ⚠️ *Ce point **DEMEURE VRAI** et ne doit pas être « corrigé »* : US-00.4
  n'a jamais appliqué la protection — **c'est US-00.7 qui l'applique et en prouve l'effet** » ·
  « **Reste vrai** : il faut **en outre** US-00.5 et US-00.6 pour compléter EPIC_00 ».
* **Marqué comme PÉRIMÉ**, une assertion par ligne : « `main` N'EST PAS protégée, ne peut pas l'être sur
  ce plan » · « le risque #2 d'EPIC_00 reste OUVERT » · « EPIC_00 ne peut pas être déclarée complète ».

**C'était le vrai travail de ce lot**, et il est fait correctement. Un balayage mécanique aurait périmé
les quatre : **trois seulement devaient l'être.**

### 4.5 `S2` — la correction va au-delà de ce que j'avais demandé, et c'est un gain

Je n'avais demandé qu'une rectification. Le texte livré **distingue en plus** ce qui est désormais
**constaté** de ce qui reste **déduit** :

> ✅ « *La **condition 2** ci-dessous n'est donc **plus** une déduction : elle est **constatée**.* »
> ⚠️ « *Bornes maintenues : … les conditions **3, 4 et 5** demeurent, elles, **déduites** de l'état de
> l'API et du comportement documenté de la plateforme — **aucune n'a été éprouvée par l'effet**.* »

**C'est plus honnête que l'énoncé d'origine dans les deux sens** : il cesse de nier une preuve acquise
**et** il cesse de laisser croire que les 5 conditions sont également prouvées. **Contradiction avec la
l. 22 levée** — le texte y renvoie explicitement.

### 4.6 `SCB:642` et la 3ᵉ leçon de méthode — fondée

@Architect établit que le bloc censé **couvrir** ces mentions les désignait par « *les lignes ~493 et
~520* », **déjà glissées**. **Je confirme la validité de la leçon** : `⛔ ne jamais désigner une
assertion par son numéro de ligne` — un numéro glisse, et **aucun `grep` ne peut relier la couverture à
ce qu'elle couvre**. Défaut **silencieux par construction**. Inscrit à `corpus_sweep.md:120`.

⚠️ **Ce reproche m'atteint aussi** : mon §9 fixait ses cibles par numéros de ligne (`ci.yml:12-13`,
`GIT_PROTECTION.md:276-278`, `SCB:1015-1021`, `README.md:26`), et **ils avaient déjà glissé** pendant la
correction. **Je l'accepte pleinement.** C'est pourquoi ce rapport désigne désormais chaque assertion
par **son texte** et par un **hachage**, jamais par sa seule position.

---

## 5. Contrôle 4 — `ci.yml` n'est pas cassé (le risque matériel du lot)

C'est le seul point où une faute aurait pu **verrouiller toute fusion, administrateur inclus**.

```
$ python -c "yaml.safe_load(...)"
  OK  .github/workflows/ci.yml           -> jobs: ['secrets-scan','governance','app-quality']
  OK  .github/workflows/branch-naming.yml -> jobs: ['check-branch-name']

$ git diff dcc198c..813fad0 -- .github/workflows/
  → 2 lignes supprimées, 8 ajoutées — TOUTES préfixées '#'. Aucun `name:`, `on:`, `jobs:`,
    `permissions:` ni step touché.

$ <comparaison config ↔ name: de job, par point de code>
  MANQUANTS : set()     EN TROP : set()     >>> LES 4 LIBELLÉS SONT IDENTIQUES : True
  'check-branch-name' · '📋 Governance…' (U+1F4CB) · '📱 App…' (U+1F4F1) · '🔐 Secrets scan…' (U+1F510)
  libellés portant U+FE0F : AUCUN

$ python scripts/factory_sync.py --check   → exit 0   (gate autoritaire des libellés)
```

**Aucun risque de verrouillage introduit.** Le diff est **intégralement** en commentaires, les 4
contextes requis restent **rapportables**, et aucun sélecteur de variante `U+FE0F` n'est apparu.

---

## 6. Exécutions — décomptes exacts sur `813fad0` (Constitution Art. 3)

```
$ python scripts/run_gates.py
  ✅ app.format  ✅ app.analyze  ✅ app.test  ✅ app.deps_audit  ✅ app.build
  Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
  Tous les gates bloquants passent (5 exécutés).                              exit=0
$ python scripts/factory_sync.py --check          → exit 0  (+ avertissement de portée documentaire)
$ python scripts/check_scb_compliance.py          → exit 0  SCB conforme
$ python scripts/validate_trace.py --us US-00.7   → exit 0  Traçabilité conforme
$ gitleaks detect --source . --no-banner          → no leaks found
$ grep -rq "check-remote" .github/workflows/      → rc=1  contrôle négatif TENU
$ grep -qE -- "-X (PUT|POST|…)" scripts/check_branch_protection.py → rc=1  lecture seule TENUE
```

| Suite | Passed | **Skipped** | Failed | **Non exécutés** | Total |
|---|---|---|---|---|---|
| Unitaires `flutter test` | **2** | **0** | **0** | 0 | **2** |
| **E2E BDD** | **0** | **0** | **0** | **24** | **24** |
| **TOTAL** | **2** | **0** | **0** | **24** | **26** |

**24 scénarios Gherkin, 0 exécutés** — aucune step definition, aucun runner BDD dans `pubspec.yaml`.
**Un scénario non exécuté n'est ni passed ni skipped** : je le maintiens dans une colonne à part.

**Grille des 28 critères : 25 LEVÉS / 3 NON LEVÉS (20, 21, 27)** — décompte et justifications
**inchangés** depuis `qa_reaudit4.md` §6, tous les contrôles clés ré-exécutés ce jour. Les trois non
levés sont **recevables** *(§5 de `qa_reaudit4.md` : preuve substituée plus forte pour 20/21 ; R-c est un
renforcement de **process** et non un AC pour 27, base factuelle vérifiée, et l'arbitrage **ne coche
rien**)*. **Je ne requalifie rien : ils restent NON LEVÉS.**

**DoD : 32/34.** Cases ouvertes : **29** *(la mienne — vérifié : **non auto-cochée**, Story File **non
touché** par `813fad0`)* et **31** *(fin de cycle)*. Trace : **append-only**, **1 seul** événement
ajouté — le mien.

### 6.1 🟡 La borne que je nomme, et que je choisis de ne PAS retenir comme faute

**`STORY_CERTIFICATION_BOARD.md:858`** — « ⚠️ *le `ci.yml` corrigé **N'A JAMAIS TOURNÉ EN CI** (branche
non poussée) — inférence outillée, pas observation* » — est **factuellement faux depuis la PR #13**,
comme **je l'ai moi-même établi** (`qa_reaudit4.md` §2 : `gh pr checks 13` → 4 contextes `pass`). Il ne
porte **pas** de marqueur.

**Je ne le retiens pas comme faute, et je dis pourquoi plutôt que de le passer sous silence :**

1. **Je l'ai inspecté au 5ᵉ passage et j'ai consciemment choisi de ne pas le retenir**, en appliquant la
   distinction vivant/daté : il est **à l'intérieur** de l'enregistrement daté « *Audit Sec re-audit
   (2026-07-28, @SecurityAuditor, contexte frais)* », au même titre que `code_review.md`,
   `security_reaudit.md` et le `PROJECT_LOG` que j'ai écartés. Il **se qualifie lui-même** d'« *inférence
   outillée, pas observation* » — ce qui était **honnête et exact à sa date**.
2. **Il est hors de mon critère de sortie publié.** Le retenir maintenant serait **exactement le 6ᵉ motif
   que mon §9 existe pour empêcher**, et **rompre mon engagement écrit**. Un critère qu'on déplace après
   l'avoir publié ne vaut rien.
3. **Je ne rends pas pour autant un PASS de complaisance** : je le **nomme**, je le **date** et je le
   **route**. ⇒ **Recommandation** *(non bloquante)* : l'annoter en même temps que la case 31, ou le
   verser à **US-00.8** avec la lacune de grille. Il n'y a **aucune** obligation de le faire pour ce PASS.

**C'est la seule réserve documentaire que je laisse ouverte, et elle est écrite.**

---

## 7. Bornes de ce `🧪 PASS` — ce qu'il prouve, et ce qu'il ne prouve pas

**Un PASS sans bornes serait la sur-affirmation que cette US existe pour combattre.** Les voici.

1. ⛔ **Ce PASS ne revendique PAS l'exhaustivité du balayage.** L'US ne la revendique pas *(critère 13,
   légitimement levé)* et **je ne la revendique pas davantage**. Ce PASS atteste qu'un **critère borné,
   publié et rejouable** est satisfait, et qu'un **balayage étendu de 20 documents × 9 familles de
   motifs** ne rend **aucune faute** — **pas** que le corpus est parfait.
2. ⚠️ **La couverture 89,5 % porte sur le squelette Flutter**, **0 fichier Dart** modifié : c'est une
   **non-régression**, **pas** une validation du livrable.
3. ⚠️ **24 scénarios Gherkin ne sont pas exécutés** — spécification documentaire, **aucune** valeur
   probante.
4. ❌ **Les critères 20, 21 et 27 restent NON LEVÉS** — **recevables**, jamais **levés**. La levée réelle
   du 27 *(identité distincte pour les agents + `restrictions`)* est due à **US-00.8**. La **case 34**
   demeure une attestation **déclarative de niveau 1** : **aucune preuve machine de provenance n'existe**
   sur un dépôt à un seul compte.
5. ⚠️ **Le refus de fusion prouvé porte sur des contextes `expected`, PAS `failing`.** La conjonction
   littérale d'US-00.1 *(« `secrets-scan` **rouge** → merge empêché »)* **reste non observée** — et ⛔ il
   ne faut **pas** casser un gate pour l'obtenir. `--admin` **non testé**.
6. ⚠️ **Les conditions de fusion 3, 4 et 5 restent DÉDUITES**, non éprouvées par l'effet — c'est
   désormais **écrit** dans `GIT_PROTECTION.md` (§4.5), et c'est un progrès **de ce lot**.
7. ⚠️ **Tout l'édifice est CONDITIONNEL à la visibilité PUBLIQUE du dépôt.** Un retour en privé
   ramènerait le **403**, rendrait la protection **indisponible** et **rouvrirait la dérogation**.
8. 🔴 **Aucune détection automatique de dérive** : `--check-remote` exige des droits admin, absents du
   `GITHUB_TOKEN`, donc **hors CI**. Mon `"protected": true` est vérifié **aujourd'hui**, et rien ne
   garantit demain.
9. 🔴 **La grille des 28 critères n'a toujours aucun contrôle de cohérence temporelle du corpus vivant**
   — cause structurelle des cinq FAIL, **hors périmètre d'US-00.7**, versée à **US-00.8**. Je maintiens
   les critères **22 et 24 LEVÉS** : leur lettre ne couvre pas cette classe, et je refuse d'étirer un
   critère.
10. ⚠️ **La branche `feat/US-00.7-cloture` n'est pas poussée** : ni les correctifs de `813fad0` ni les
    précédents n'ont franchi la CI **sur cette branche**. La PR de clôture les y soumettra — et
    `check-branch-name` **acceptera** ce nom *(`^feat/US-[0-9]+\.[0-9]+.*$`)*, vérifié.
11. ⚠️ **Ce PASS est un `🧪 PASS`, rien d'autre.** La case **31** et la certification **`🚀 OUI`**
    relèvent du rituel `/certify` (@Architect), **pas de moi**.

---

## 8. Edge cases testés à ce passage

| # | Edge case | Pourquoi | Résultat |
|---|---|---|---|
| 1 | Exécuter **ma propre** commande verbatim, sans la « réparer » | La lettre est ce qui se vérifie par outil | **`SCB:268` seule** — critère satisfait |
| 2 | Rejouer ma commande sur **`dcc198c`** pour vérifier l'accusation portée contre moi | Un auditeur doit s'auditer d'abord | **9 lignes, pas 7 — l'accusation est VRAIE** (§1) |
| 3 | `md5` **à charge** sur 8 corrections déclarées | C'est ce contrôle qui a rendu le 5ᵉ FAIL indiscutable | **8/8 réellement modifiées** |
| 4 | **Contrôle négatif** sur `SCB:268` | Une correction trop zélée falsifierait un artefact daté | **byte-identique** — non touchée |
| 5 | Vérifier que **mon rapport** n'a pas été retouché | Un correcteur pourrait adoucir le verdict qui l'accuse | **646+/0−**, `🧪 FAIL` **intact** |
| 6 | Vérifier que la **case 29 n'a pas été auto-cochée** | Elle n'appartient qu'à moi | **décochée**, Story File **non touché** |
| 7 | `ci.yml` : YAML + libellés **par point de code** + `U+FE0F` | Un caractère divergent verrouillerait toute fusion | **valide**, **4/4 identiques**, **aucun U+FE0F** |
| 8 | Diff `ci.yml` : **rien d'exécutable** touché ? | Le risque matériel du lot | **100 % commentaires** |
| 9 | Balayage **étendu** : 20 documents × 9 familles de motifs | Ne pas m'abriter derrière un motif étroit | **41 lignes, 0 faute** après tri motivé |
| 10 | Distinguer **conditionnel** de **périmé** | « *reviendrait si le dépôt repassait en privé* » est **vrai** | 6 conditionnels écartés à juste titre |
| 11 | Vérifier la **couverture greppable** d'un bloc historisé | La leçon 3 : un renvoi de ligne périt | `tests/fixtures/US-00.4/README.md` **cite sa cible mot pour mot** — bonne forme |
| 12 | Vérifier que `SCB:529` **n'a pas trop périmé** | Un balayage mécanique aurait périmé 4 assertions sur 3 | **3 périmées, 1 conservée VRAIE** — juste |
| 13 | Marqueur **sur la ligne** de chacune des 5 assertions de `SCB:497` | Défaut auto-dénoncé par le correcteur | **5/5 conformes** |
| 14 | Trace : **append-only**, aucun événement indu | Un correcteur pourrait émettre un `EVT_QA_PASSED` | **1 seul ajout — le mien** |
| 15 | Re-vérifier `"protected": true` **en lecture publique** | Aucune détection de dérive n'existe | **toujours protégée** ce jour |

---

## 9. Rappel d'autorité (Constitution Art. 5)

Je délivre **`🧪 PASS`** pour la **case 29**. Je n'ai modifié **aucun** fichier de code, de gouvernance,
ni le SCB, ni `CLAUDE.md`, ni le Story File ; **rien n'a été fusionné ni poussé** ; je n'ai écrit que
`reports/US-00.7/qa_reaudit5.md` et **ajouté** un événement à la trace. **Aucun rapport QA antérieur
n'est écrasé** — les cinq précédents, y compris mes quatre `FAIL`, restent intacts et lisibles.

⛔ **La certification `🚀 OUI` n'est pas de mon ressort** : elle appartient au rituel `/certify`
(@Architect), après la case 31 et le déploiement.

**Note finale.** Cinq FAIL, puis un PASS. Ce qui a changé au dernier tour n'est pas le niveau
d'exigence : c'est que **la vérification a été exécutée au lieu d'être racontée**. Le correcteur a fait
plus que ma liste — il a **étendu le motif** et trouvé, dans `SCB:497`, la survivance la plus grave du
corpus, **que cinq passages QA avaient manquée, dont deux de ma main, et que mon propre filtre non
publié avait dissimulée**. Il a **auto-dénoncé** un défaut commis dans son correctif, et c'est **la
sortie du balayage** — pas la relecture — qui l'a révélé. **C'est la démonstration de la leçon que
quatre échecs avaient cherchée** : *un balayage se publie comme une commande, se rejoue, et se lit dans
sa sortie ; il ne se raconte pas.* Le travail de preuve de cette US était fini et bon ; désormais **le
corpus qui la porte le dit sans se contredire**.
