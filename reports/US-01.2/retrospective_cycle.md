# Rétrospective du cycle US-01.2 — **matière pour `/audit-methodo`**

> ⛔ **CE DOCUMENT N'EST PAS LE RITUEL `/audit-methodo`, et il ne doit jamais être lu comme tel.**
> Le rituel exige un point de contrôle d'enforcement de `main` *(a → f)*, une comparaison avec
> `docs/audit/METRICS.md`, un rapport `docs/audit/AUDIT_METHODOLOGIE_YYYY-MM.md` et une veille.
> **Aucun des quatre n'a été fait ici.** Mesuré : `docs/audit/` **n'existe pas** ⇒ le rituel n'a
> **jamais tourné**, exactement comme le `CLAUDE.md` l'annonce.
> **Ceci est de la MATIÈRE** : les mesures d'un cycle, et ce qu'elles suggèrent. *Une matière n'est pas
> un audit ; c'est ce qu'un audit aurait à lire.*

**Auteur** : @Architect · **Date** : 2026-08-18 · **Périmètre** : US-01.2, de `EVT_STORY_CREATED`
(2026-08-05) à `EVT_QA_PASSED` (2026-08-18) · **Dépôt à** `a2f4f62`.

---

## 0. Comment reproduire chaque chiffre — ⛔ ne recopiez aucun nombre de ce document

Tous les chiffres cités viennent d'**une seule commande**, et ils se **relisent**, ils ne se
recopient pas *(défaut nº 1 du projet : « un nombre dérivé écrit à la main à côté d'une commande »)* :

```
python reports/US-01.2/mesures_cycle.py
python reports/US-01.2/mesures_cycle.py --selftest
```

Le script **ne juge pas** : il n'a ni seuil, ni verdict — un cycle long n'est pour lui ni un succès ni
un échec. Ce qu'il porte à la place est une **garde d'anti-vacuité** sur chaque extraction, parce que
le vrai risque d'un script de mesure est qu'un motif cesse de matcher et rende **`0`**, qui **ressemble
à une réponse**. C'est le défaut `NB-C` déjà relevé sur `check_e2e_persistance.py` *(« le contrôle
racine passe à vide »)*. Le `--selftest` **ne teste pas les chiffres** : il vérifie que les gardes
**mordent** — 3 mutants d'entrée vide + **1 contrôle négatif** *(sans lui, une garde qui lèverait
toujours passerait les trois autres)*.

**Les valeurs ci-dessous sont un instantané daté du 2026-08-18 sur `a2f4f62`** — elles vieilliront, et
c'est voulu : la commande, elle, reste vraie.

---

## 1. Ce que les mesures disent

**Le cycle : 317,8 h** *(13,2 jours calendaires)*, **40 commits sur 7 jours actifs**, **3 tours
d'audit**, **2 cycles de correctif**, **2 verdicts `FAILED`** — les deux côté sécurité.

| Étape | Durée mesurée | Ce qu'elle a produit |
|---|---:|---|
| Conception → Integration Lock | ~25 h | 16 AC, 50 scénarios, 3 ADR |
| Développement `T1 → T15` | 27,2 h | `lib/` + `test/` |
| **1ᵉʳ tour d'audit** | **~3 h 40** | **`B-1` (HIGH)** |
| Cycle correctif 1 | 72,1 h | type scellé + `switch` exhaustif |
| **2ᵉ tour d'audit** | 21,9 h | **`B-2` (HIGH)** |
| Cycle correctif 2 | ~2 h 45 | la **famille** refermée |
| **3ᵉ tour d'audit** | **142,1 h** | **0 bloquant** |
| QA | 22,3 h | 0 AC orphelin |

**Volume** : **10 635 lignes de documentation** contre **8 098 de code + tests** *(ratio **1,31**)*, et
les **rapports d'audit seuls font 2,85 × `lib/`**.

⚠️ **Limite à ne pas franchir en lisant ce tableau** : ce sont des durées **calendaires**, ⛔ **pas du
temps de travail**. Elles incluent les nuits, les attentes et les interruptions. *Un cycle court ne
serait pas meilleur — US-01.2 a livré la première persistance réelle du projet et fermé le risque nº 4
d'EPIC_00.*

---

## 2. Trois constats

### ① Le coût n'est pas dans l'audit, il est dans sa **sérialisation**

Un tour d'audit **s'exécute** en ~4 h *(les deux audits en parallèle)*. Trois tours ont coûté
**13 jours**, parce que chaque tour attend le correctif du précédent, qui attend le verdict du
précédent.

**Et la mesure qui tranche** : quand l'arbitrage humain du 2026-08-11 a **élargi le périmètre à la
famille** — *« un chemin d'erreur qui avale »* — le tour suivant a trouvé **0 bloquant**.
**L'élargissement a marché du premier coup.** Or `B-2` était **PRÉ-EXISTANT** *(vérifié :
`git show 5272ed1` porte déjà le même `_mettreDeCoteSansBruit()` suivi d'un `documentNeuf`
inconditionnel)* ⇒ **il était déjà là, et donc déjà élargissable, quand `B-1` a été trouvé.**

### ② Les gates n'ont trouvé **aucun** des deux bloquants ; les mutants les ont trouvés **tous les deux**

`B-1` est entré avec un diff qui **faisait MONTER la couverture à 97,9 %**. `B-2` habitait un `catch`
au **corps vide** — **zéro ligne instrumentable**, donc invisible à `lcov` **par construction**. Et
après correction, `REV-NB-N` mesure que **ni le `return true` ni le `return false` n'ont d'entrée
`DA`** ⇒ **aucune couverture, à aucun seuil, ne dira jamais si ce chemin est exercé.**

Pourtant, sur le **même commit figé**, `run_gates --all` a été rejoué par **@CodeReviewer,
@CyberSecurity, @QA_Tester et @Architect** — **4 exécutions complètes**, dont 4
`flutter build web --release`, pour un résultat **connu d'avance et jamais démenti**.
⚠️ **Ce décompte est une observation de session, ⛔ pas une mesure reproductible** : rien dans le dépôt
n'enregistre les exécutions de gates, et le script le dit.

### ③ Chaque verdict est écrit **quatre fois**

Rapport d'audit → entrée SCB → ligne PROJECT_LOG → message de commit. La règle du projet — *« une règle
n'existe qu'en un seul exemplaire »*, vérifiée trois fois et inscrite au `CLAUDE.md` — **n'est pas
appliquée à sa propre comptabilité**. Mesuré : **799 lignes ajoutées au SCB** pour ce seul cycle, dont
l'essentiel **paraphrase** des rapports qui existent déjà.

---

## 3. Cinq axes, par gain mesuré décroissant

### Axe 1 — Nommer la **famille** au premier bloquant, pas au second
**Mesure qui le fonde** : élargissement au 2ᵉ tour ⇒ **0 bloquant au 3ᵉ**.
**Action** : à la découverte d'un bloquant, l'orchestrateur qualifie son **mécanisme** et le cycle de
correctif couvre **toute la famille**. Le **GEL d'US-00.6** interdit d'*ouvrir* un cycle pour du non
bloquant — ⛔ **il n'interdit pas d'ÉLARGIR un cycle déjà ouvert**, et c'est précisément ce que
l'arbitrage du 11 août a fait.
**Gain mesuré ici** : ~74 h *(cycle correctif 1 + 2ᵉ tour)*.
⛔ **Ce que ça ne résout pas** : une famille mal nommée élargit dans le vide. La qualification doit
venir d'un **mécanisme observé**, jamais d'une intuition.

### Axe 2 — Faire nommer les **familles de risque à l'Integration Lock**
**Mesure** : les chemins d'erreur de la persistance n'ont été identifiés comme famille qu'au **2ᵉ
tour**, alors que le lock savait qu'US-01.2 introduisait **la première persistance du projet**.
**Action** : le lock produit une liste *« ce que les audits doivent balayer exhaustivement »*, et les
prompts d'audit la portent. Le 1ᵉʳ tour serait armé au lieu du 3ᵉ.
⛔ **Ce que ça ne résout pas** : un auditeur ne doit **jamais** se limiter à cette liste — sinon le lock
devient le plafond de l'audit, et un défaut hors liste devient invisible.

### Axe 3 — Rediriger le budget des auditeurs **des gates vers les mutants**
**Mesure** : 0 bloquant trouvé par les gates, 2 par les mutants, 4 exécutions de gates pour un commit.
**Action** : gates exécutés **une fois** sur le commit figé, sortie publiée ; chaque auditeur en fait un
**contrôle négatif** *(il rejoue **un** gate et vérifie qu'il retrouve le même chiffre)* et dépense le
reste en mutation.
⚠️ **À manier avec précaution** : *« la mesure bat le raisonnement »* est ce qui fait la valeur de ces
audits, et un auditeur qui **lit** un chiffre au lieu de le **produire** en perd une part. Le contrôle
négatif est le compromis honnête ; **le supprimer serait une régression**.

### Axe 4 — Implémenter les **quatre remèdes d'une ligne**, formulés et jamais faits
| Remède | Coût de son absence, mesuré |
|---|---|
| `scripts/check_story_counts.py` *(défaut ⑤, ouvert depuis le 2026-08-06)* | ≥ 3 incidents depuis, dont un **gelé dans une trace append-only** *(« 8 tués » pour 10)* |
| `PYTHONIOENCODING=utf-8` | **`cp1252` a cassé 3 instruments en 2 jours, dans 3 rôles** — dont un lanceur de mutants mort **entre** l'application d'un mutant et sa restauration |
| **Préfixes `REV-` / `SEC-`** sur les findings | La collision a coûté **un finding entier** *(`REV-NB-O`)* et a fait cocher comme **fermés** des findings **ouverts** |
| Restauration de mutant en `finally` | Un `lib/` laissé **muté** dans un arbre d'audit |

### Axe 5 — Alléger la **comptabilité**, jamais la vérification
**Action** : l'entrée SCB **pointe** vers le rapport et ne porte que ce qu'il ne contient pas —
l'**arbitrage**, la **décision**, la **borne**. C'est le seul endroit du corpus où le volume est du
**pur doublon**.
⛔ **Ce que ça ne résout pas** : le SCB doit rester lisible **seul** par un agent en session fraîche.
Le pointeur doit donc porter **le verdict et sa portée**, pas seulement un lien.

---

## 4. ⛔ Ce qu'il ne faut **pas** couper

Les audits à contexte frais ont trouvé **deux bloquants HIGH qu'aucun gate n'a vus**, dont un qui
**détruisait les données du pratiquant sans message, sans copie et sans trace**. La couverture valait
**97,9 %** dans les deux cas. **Couper là serait couper la seule chose qui a fonctionné.**

Et l'**isolation par `git worktree`**, introduite à ce tour, est **validée par l'incident même qu'elle
devait contenir**. Elle a un coût *(un `flutter pub get` par arbre)* : il est **négligeable devant une
contamination croisée entre deux audits mutants**.

---

## 5. Ce que cette rétrospective doit à ses propres erreurs

⛔ **Une part du coût de ce cycle est la mienne, et la taire fausserait la matière** :

* **Deux faux départs d'audit** — les prompts appariés au mauvais rôle, arrêtés avant tout travail.
* **Une assertion fausse écrite en croyant CORRIGER** : *« la branche `feat/US-01.2-gestion-echeances`
  n'a jamais existé »*, alors que la **PR #31** en a été fusionnée. Écrite **sans mesure**, par
  déduction. ⇒ **La règle du projet ne dit pas seulement de mesurer avant d'affirmer : elle dit de
  mesurer AUSSI quand on croit corriger** — une correction se présente avec l'autorité d'une
  vérification qu'elle n'a pas forcément faite.
* **Une sur-lecture d'un refus d'outil** érigée en règle générale, corrigée après lecture du script.

**Trois occurrences de la classe de défaut nº 1 en deux jours, par l'orchestrateur lui-même.** C'est
cohérent avec l'acquis d'US-00.5 : *un correctif qui s'explique produit mécaniquement des occurrences
de ce qu'il corrige.*

---

## 6. ⛔ Ce que cette matière n'établit pas

* Elle **ne compare rien** : c'est **un seul cycle**, sans série temporelle *(`docs/audit/METRICS.md`
  n'existe pas)* ⇒ ⛔ **aucune tendance ne peut en être tirée**.
* Elle **ne mesure aucun temps de travail** — uniquement du **calendaire**.
* Elle **ne dit rien de l'enforcement de `main`** : le point de contrôle *(a → f)* du rituel, qui exige
  des droits admin, **n'a pas été exécuté**.
* Elle **ne dit rien de la qualité du produit** : c'est l'affaire des trois visas, qui sont posés.
* Les axes proposés sont des **hypothèses adossées à une mesure**, ⛔ **pas des remèdes éprouvés** — le
  seul qui l'ait été est l'**Axe 1**, une fois, par l'arbitrage du 2026-08-11.
