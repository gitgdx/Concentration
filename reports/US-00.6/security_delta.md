# US-00.6 · Audit sécurité **DELTA** — @CyberSecurity (2ᵉ passage)

| Champ | Valeur |
|---|---|
| **US** | US-00.6 — Couverture initiale mesurée + cliquet réellement actif |
| **Agent** | @CyberSecurity — **contexte frais** (Art. 2) · **Modèle** `claude-opus-5[1m]` |
| **Date** | 2026-08-01 |
| **Périmètre** | **`f585e82..62a4fcc`** — delta **depuis mon badge précédent**, pas un ré-audit intégral |
| **Rapport précédent** | [`reports/US-00.6/security.md`](security.md) — ⛔ **NON écrasé**, il reste valide pour `f585e82` |
| **VERDICT** | ✅ **PASSED** sur **`62a4fcc`** — **0 bloquant** · **3 findings de delta** (1 LOW, 2 INFO) · **2 de mes 4 MEDIUM sont CORRIGÉS**, 1 **RECTIFIÉ**, 1 **MAINTENU acceptable** |

> ⛔ **Bornes inchangées et rappelées d'emblée : aucun SAST n'existe dans cette factory, aucun scanner de
> CVE non plus.** Ce `PASS` **ne s'appuie sur aucun des deux**. Détail au §6.

---

## 1. Ce que le delta contient — et ce qu'il ne contient pas

```
$ git diff --numstat f585e82..62a4fcc          (6 commits)
   3	  1	.github/workflows/ci.yml            ← commentaires SEULS (vérifié §3)
  79	 13	scripts/check_flutter_coverage.py   ← recoupement LF/LH + garde DA malformée
  89	  3	scripts/selftest_coverage_ratchet.py ← +2 fixtures, différentiel, plancher seul
  24	  0	tests/fixtures/US-00.6/lf_menteur.info
  24	  0	tests/fixtures/US-00.6/totaux_incoherents.info
  24	  0	tests/fixtures/US-00.6/sous_plancher_15_sur_19.info
  15	  4	tests/fixtures/US-00.6/README.md
  57	 29	docs/stories/US-00.6-couverture-ratchet.md
   … + 9 fichiers documentaires (CLAUDE.md, SCB, PROJECT_LOG, EPIC_00, BACKLOG,
       6 rapports d'audit/QA, docs/trace/US-00.6/events.jsonl)
```

### 🔒 Vérification n° 1 — **les deux fichiers PROTÉGÉS n'ont pas bougé.** *(« Vérifie-le, ne me crois pas. »)*

```
$ git diff --numstat f585e82..62a4fcc -- factory.config.json scripts/factory_sync.py
(sortie VIDE)

$ git diff --stat f585e82..62a4fcc -- scripts/factory_sync.py factory.config.json
(sortie VIDE)
```

✅ **Confirmé, indépendamment.** Mes conclusions du 1ᵉʳ passage restent donc **portantes sans réserve** :
diff appliqué **28/28 lignes exécutables identiques** au diff T8 proposé, ajout pur **32/0**, et
`emit_branch_protection` **octet-identique**. **Aucune 3ᵉ édition humaine n'a eu lieu.**

---

## 2. `gitleaks` — arbre **et** delta

```
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~121770362 bytes (121.77 MB) in 7.45s
INF no leaks found
EXIT=0

$ gitleaks detect --source . --config .gitleaks.toml --log-opts "f585e82..62a4fcc" --redact -v
INF 6 commits scanned.
INF scanned ~311280 bytes (311.28 KB) in 421ms
INF no leaks found
EXIT=0
```

✅ **Propre des deux côtés.** ⛔ **Aucun `grep` de motifs n'a servi à conclure** — le piège documenté du
projet *(un `grep` matche la **documentation** des motifs)* est évité : **`gitleaks` seul fait foi**, et il
a tourné **deux fois**, sur **121,77 Mo** et sur les **6 commits** du delta.

✅ **Le détecteur n'a pas été desserré** :
`git diff --numstat f585e82..HEAD -- .gitleaks.toml .claude/ scripts/githooks/` → **sortie vide**.
Aucune allowlist élargie, aucun hook touché. Le dépôt est **PUBLIC** *(`visibility: "public"`)* — la
question était donc la bonne, et la réponse est nette.

⚠️ Le delta verse **6 rapports d'audit/QA** (≈ 2 300 lignes de documentation) : ils sont **inclus** dans
les deux passes et **ne portent aucun secret**.

---

## 3. `.github/workflows/ci.yml` — commentaires seuls ? **OUI, vérifié**

Le diff **intégral** du fichier sur le delta :

```diff
@@ -112,7 +112,9 @@ jobs:
-      #    Il prouve par 4 fixtures que check_flutter_coverage.py sait REFUSER — dont le cas
+      #    Il prouve par SES FIXTURES que check_flutter_coverage.py sait REFUSER — dont le cas
+      #    (PERIME-2026-07-31 : ce commentaire disait « 4 fixtures », chiffre RECOPIE et perime des
+      #     l ajout de la suivante. Le nombre exact est DERIVE et imprime par le selftest lui-meme.)
```

**Les 4 lignes touchées commencent toutes par `#`.** ⛔ **Aucun `run:`, aucun `uses:`, aucun `with:`,
aucun `env:`, aucune `permissions:`, aucun `${{ }}` n'est modifié.**

### 🔒 Vérification n° 2 — **aucun `name:` de job modifié** *(un caractère divergent = toute PR infusionnable)*

```
--- f585e82 ---                                    --- 62a4fcc (HEAD) ---
48:  secrets-scan:                                 48:  secrets-scan:
49:    name: 🔐 Secrets scan (gitleaks)            49:    name: 🔐 Secrets scan (gitleaks)
67:  governance:                                   67:  governance:
68:    name: 📋 Governance (SCB + traçabilité…)    68:    name: 📋 Governance (SCB + traçabilité…)
128: app-quality:                                  130: app-quality:
129:   name: 📱 App (gates run_gates.py)           131:   name: 📱 App (gates run_gates.py)
```

✅ **Les 3 `name:` sont octet-pour-octet identiques.** Seuls les **numéros de ligne** ont glissé (+2, effet
mécanique des 2 lignes de commentaire ajoutées). Corroboré côté serveur : les **4 contextes requis** lus
sur l'API sont **exactement** ces libellés *(§5)*.

### `actionlint` 1.7.12 → **0 erreur**

```
$ actionlint -color -verbose .github/workflows/*.yml
verbose: Linting 3 files
verbose: Found total 0 errors in .github/workflows/branch-naming.yml
verbose: Found total 0 errors in .github/workflows/ci.yml
verbose: Found total 0 errors in .github/workflows/e2e.yml
verbose: Found 0 errors in 3 files
EXIT=0
```

*(Binaire re-téléchargé, `sha256 6e7241b5…`, identique à celui de mon 1ᵉʳ passage. ⚠️ Mêmes bornes : les
règles `shellcheck` et `pyflakes` sont **désactivées** localement, alors que `shellcheck` **est** présent
sur `ubuntu-latest` ⇒ **l'exécution en CI est PLUS forte que la mienne**.)*

---

## 4. 🎯 Le point que vous m'avez signalé : sous-processus + configurations temporaires

Le `selftest` a grossi de **+89/−3** et ouvre désormais **trois** répertoires temporaires et **neuf**
exécutions du checker. C'est bien là qu'il faut regarder. Résultat de la revue, ligne par ligne :

### 4.1 Exécution de sous-processus — **aucune surface d'injection**

```python
# l. 77 — INCHANGÉE par le delta
proc = subprocess.run(
    [sys.executable, str(CHECKER), "--min", str(PLANCHER), "--lcov", str(lcov), "--config", str(cfg)],
    capture_output=True, text=True, encoding="utf-8", errors="replace",
)
```

| Contrôle | Verdict | Justification |
|---|---|---|
| `shell=True` ? | ⛔ **NON** | forme **LISTE** — aucun interpréteur de commande n'est invoqué, donc **ni `;` ni `&&` ni `|` ni `$()` ne peuvent être interprétés**, quel que soit le contenu des arguments |
| Origine des arguments | **100 % constantes du module** | `sys.executable` · `CHECKER = Path("scripts/check_flutter_coverage.py")` (l. 37) · `PLANCHER = 80.0` (l. 49) · `lcov = FIXTURES / <nom littéral de la liste `CAS`>` · `cfg = Path(tmpN) / <littéral>` |
| Entrée externe atteignant `argv` ? | ⛔ **AUCUNE** | ni `sys.argv`, ni `os.environ`, ni fichier de configuration du dépôt, ni donnée de PR. **Le script ne prend aucun paramètre** |
| Nouveaux appelants du delta | **3**, tous conformes | différentiel (l. 148) et « plancher seul » (l. 182) passent des chemins **dérivés de constantes** |
| Nommage des fichiers temporaires | **sûr** | `("cfg_%s.json" % ref)` avec `ref ∈ {86.0, 95.0}` — **constantes de `CAS_DIFFERENTIEL`** (l. 52). Aucun `..`, aucun séparateur, **aucune traversée de chemin possible** |

### 4.2 Écritures — **tout est dans `tempfile`, les trois fois**

```
$ grep -nE "write_text|tempfile\.|open\(" scripts/selftest_coverage_ratchet.py
104:    with tempfile.TemporaryDirectory() as tmp:     →  106:  cfg.write_text(...)
138:    with tempfile.TemporaryDirectory() as tmp2:    →  142:  cfg2.write_text(...)
175:    with tempfile.TemporaryDirectory() as tmp3:    →  177:  cfg_vide.write_text(...)
```

✅ **Les 3 écritures sont à l'intérieur d'un `with tempfile.TemporaryDirectory()`** — donc dans un
répertoire **créé en `0700`** et **détruit automatiquement** à la sortie du bloc, y compris sur exception.
✅ `scripts/check_flutter_coverage.py` **n'écrit toujours RIEN**, nulle part.
⛔ **Aucune écriture dans le dépôt, aucune dans `$HOME`, aucune dans un chemin absolu.**

### 4.3 Réseau et primitives dangereuses — **néant**

```
$ grep -nE "urllib|requests|socket|urlopen|http|os\.system|shell=True|eval\(|exec\(|pickle|
            yaml\.load|shutil|os\.remove|unlink" scripts/check_flutter_coverage.py \
                                                  scripts/selftest_coverage_ratchet.py
(AUCUNE correspondance)
```

⛔ **Aucun appel réseau.** ⛔ Aucun `eval`/`exec`/`pickle`/`yaml.load` — la configuration temporaire est
produite par `json.dumps` et relue par `json.loads`. ⛔ Aucune suppression de fichier hors du contexte
`tempfile`. **Aucune dépendance ajoutée** : les deux scripts n'importent que la bibliothèque standard
(`json`, `subprocess`, `sys`, `tempfile`, `pathlib`, `argparse`).

### 4.4 Lectures — **fichiers du dépôt uniquement**

`tests/fixtures/US-00.6/*.info` *(7 noms littéraux)* · `scripts/check_flutter_coverage.py` ·
et, côté checker, `--lcov` / `--config` **dont les valeurs sont fournies par le selftest**. Chemins
**relatifs**, aucun `~`, aucune variable d'environnement, aucun chemin absolu.

### 4.5 Exécution réelle → **exit 0, 9 assertions, 5 REFUS**

```
  OK    | regression_16_sur_19.info    exit attendu=1 obtenu=1
  OK    | inchange_17_sur_19.info      exit attendu=0 obtenu=0
  OK    | hausse_18_sur_19.info        exit attendu=0 obtenu=0
  OK    | zero_ligne_mesurable.info    exit attendu=1 obtenu=1
  OK    | totaux_incoherents.info      exit attendu=1 obtenu=1     ← corrige mon N-2
  OK    | lf_menteur.info              exit attendu=1 obtenu=1     ← branche LF exercée
  OK    | DIFFERENTIEL inchange_17_sur_19.info ref 86.0 -> exit 0 | ref 95.0 -> exit 1
  OK    | PLANCHER SEUL regression_16_sur_19.info    exit attendu=0 obtenu=0
  OK    | PLANCHER SEUL sous_plancher_15_sur_19.info exit attendu=1 obtenu=1
 RESULTAT : les 9 assertions sont tenues, dont 5 REFUS.
EXIT=0
```

---

## 5. Les 3 nouvelles fixtures · l'enforcement · la non-régression

### 5.1 Fixtures — **aucune donnée réelle, aucun chemin sensible**

| Fixture | `SF:` déclaré | Contenu | Existe dans `lib/` ? |
|---|---|---|---|
| `lf_menteur.info` | `lib/lf_menteur.dart` | 19 `DA:` + **`LF:100`** (mensonger) / `LH:17` | ⛔ **NON — synthétique** |
| `totaux_incoherents.info` | `lib/incoherent.dart` | 19 `DA:` couvertes + `LF:19` / **`LH:5`** | ⛔ **NON — synthétique** |
| `sous_plancher_15_sur_19.info` | `lib/sous_plancher.dart` | 19 `DA:` + `LF:19` / `LH:15` (78,95 %) | ⛔ **NON — synthétique** |

⛔ **Aucun chemin absolu, aucun nom d'utilisateur, aucun chemin réel du poste, aucune donnée applicative,
aucun secret.** 72 lignes de compteurs synthétiques, scannées par `gitleaks` *(§2)*.

### 5.2 `emit_branch_protection` — **toujours intacte** *(AST, pas lecture)*

```
fonctions main: 9 | HEAD: 9 | ajoutees: [] | supprimees: []
identique  emit_branch_protection      ← LA fonction sensible, octet-pour-octet
identique  render_protection_block · check_workflows · do_check · do_write
identique  main · render_env · replace_block
MODIFIEE   check_thresholds            ← la SEULE (et elle date de f585e82, pas du delta)
```

### 5.3 `main` est-elle toujours protégée ? ✅ **OUI** *(lecture seule, aucun `PUT`/`PATCH`/`POST`)*

```
$ gh api …/branches/main --jq '{protected:.protected}'
{"protected":true}

$ gh api …/branches/main/protection
{"approvals":0,"enforce_admins":true,"strict":true,
 "contexts":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
             "check-branch-name","📱 App (gates run_gates.py)"]}

$ gh api repos/gitgdx/Concentration --jq '{visibility:.visibility}'   →  {"visibility":"public"}
```

✅ **4 contextes requis**, **`enforce_admins` en vigueur**, `strict: true`, **0 dérive**. Les libellés
serveur **correspondent exactement** aux `name:` de `ci.yml` *(§3)* — **aucun risque de verrouillage par
libellé divergent.**

### 5.4 Non-régression de l'outillage → **tous exit 0**

```
$ python scripts/run_gates.py --all         → Tous les gates bloquants passent (5 exécutés).  exit 0
$ python scripts/run_gates.py --gate test   → Couverture : 89.5% (17/19) — seuil requis : 89.4% (cliquet)
                                              ✅ app.test                                      exit 0
$ python scripts/factory_sync.py --check    → exit 0
$ python scripts/validate_trace.py --all    → Traçabilité conforme.                            exit 0
$ python scripts/check_scb_compliance.py    → SCB conforme — Aucune violation détectée.        exit 0
$ python scripts/selftest_coverage_ratchet.py → 9 assertions tenues, dont 5 REFUS.             exit 0
```

⚠️ **Point critique vérifié** : le nouveau recoupement LF/LH **ne produit AUCUN faux rouge sur le rapport
réel** — `run_gates --gate test` reste **VERT**. C'était le risque n° 1 du delta *(un gate requis qui
rougit = verrouillage, administrateur inclus)*.

---

## 6. Findings

### 6.1 🔴 BLOQUANTS — **AUCUN**

| Critère bloquant | Constat sur le delta |
|---|---|
| Finding SAST HIGH | **impossible à produire** — le gate n'existe pas *(§7)* |
| CVE HIGH/CRITICAL, dépendance directe | **impossible à produire** — aucun scanner ; **0 dépendance ajoutée** |
| IDOR · endpoint sans authz | **SANS OBJET** — 0 fichier Dart applicatif, 0 endpoint, 0 ressource |
| Secret en dur | **AUCUN** — `gitleaks` ×2, détecteur non desserré |
| *(spécifique)* Injection dans un job REQUIS | **AUCUNE** — `ci.yml` = commentaires seuls ; `subprocess` en forme liste, 100 % constantes |
| *(spécifique)* Régression de la cible de protection | **AUCUNE** — `emit_branch_protection` octet-identique ; fichiers protégés **non touchés** |
| *(spécifique)* Faux rouge sur un gate requis | **AUCUN** — gate `test` **vert** sur le rapport réel |

### 6.2 ✅ Suivi de mes findings du 1ᵉʳ passage

| # | Sév. initiale | Statut | Preuve d'exécution |
|---|---|---|---|
| **N-2** *(totaux `LF:`/`LH:` non recoupés — AC-3 non implémenté)* | MEDIUM | ✅ **CORRIGÉ** | `totaux_incoherents.info` *(LF:19/LH:5, 19 DA couvertes)* → **exit 1** · `lf_menteur.info` *(LF:100)* → **exit 1**. Les **deux** branches du recoupement sont exercées, chacune par sa fixture |
| **N-3** *(`DA:` malformée → traceback)* | LOW-MED | ✅ **CORRIGÉ** | `DA:5` → exit 1, **`traceback=False`**, message `1 ligne(s) DA: malformee(s) — ligne 7 : 'DA:5'` · `DA:5,PWNED` → idem. **Bonus vérifié** : le format `DA:i,1,<somme de contrôle>` — **lcov réel** — est désormais **correctement parsé** (19/19, vert) au lieu de planter |
| **N-4** *(« une troncature AUGMENTE le pourcentage » — FAUX)* | MEDIUM | ✅ **RECTIFIÉ SUR LA LIGNE** | marqueur `PÉRIMÉ-2026-07-31` en place aux endroits visés, énoncé remplacé par le fait mesuré *(« c'est l'INVERSE … un lcov tronqué est CONSERVATEUR »)*, et **les deux refus sont explicitement redonnés comme légitimes sans cet argument**. ⛔ **On a DATÉ, on n'a pas REPEINT** — conforme à la doctrine du projet |
| **N-1** *(ligne de blancs + indentation trompeuse dans `factory_sync.py`)* | MEDIUM | ⚠️ **MAINTENU — voir §6.4, arbitrage demandé et rendu** | — |
| **N-5** *(job `governance` sans bloc `permissions:`)* | LOW | 🔁 **OUVERT, inchangé** | défaut du dépôt toujours `read` ⇒ jeton en lecture seule *(mesuré au 1ᵉʳ passage)* |
| **N-6** *(seuils en dur dans un artefact exécuté)* | LOW | 🟡 **RÉDUIT, non clos** | ✅ `REF_MUTANT` passe de **`89.4` → `86.0`** : il **cesse de valoir le seuil du projet** *(correctif B-QA-2 — la QA avait mesuré qu'un checker figeant sa valeur **survivait** à l'autotest ; le contrôle **différentiel** ajouté le tue)*. ⚠️ Restent `PLANCHER = 80.0` et `--min 80` dans la commande du gate |
| **N-7** *(`.github/workflows/*` non protégé)* · **N-8** *(0 analyse statique du Python)* · **N-9** *(provenance non prouvable)* · **N-10** *(`factory_sync --help` plante — préexistant)* | LOW / MEDIUM / INFO | 🔁 **OUVERTS, inchangés** | hors périmètre du delta |

### 6.3 🟠 Findings NOUVEAUX du delta — **`[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`**

| # | Outil | Fichier:Ligne | Sév. | Constat | Décision |
|---|---|---|---|---|---|
| **D-1** | exécution ×5 formats | `scripts/check_flutter_coverage.py:96-115` | **LOW** | Le recoupement LF/LH crée une **nouvelle cause de rouge sur un contexte REQUIS**. J'ai éprouvé **5 formes de `lcov` légitimes** : ✅ **multi-fichiers** *(records sommés)* → vert · ✅ **`DA:i,1,<somme de contrôle>`** *(3ᵉ champ, format lcov réel)* → vert · ✅ **`LF: 19 ` avec espaces** → vert · ✅ **`BRDA:`/`BRF:` présents** → vert *(pas de faux appariement avec `DA:`)* · 🔴 **record SANS `LF:`/`LH:`** → **ROUGE** `LF: declare 0 ligne(s) instrumentee(s), 19 comptee(s)`. Or `flutter test --coverage` **les émet** *(vérifié sur `coverage/lcov.info` réel, et le gate est **vert**)* | **ACCEPTÉ.** Risque **étroit, en FERMETURE, auto-révélateur et diagnosticable** *(le message nomme l'écart)*. Il ne se matérialiserait qu'à un **changement de format de l'outillage Dart**. ⚠️ **Effet de bord POSITIF à porter au crédit du correctif** : une troncature retire les `LF:`/`LH:` de fin ⇒ **un `lcov` tronqué est désormais REFUSÉ explicitement**, alors qu'il n'était jusque-là que *conservateur* — le cas discuté dans mon N-4 est **fermé pour de bon**. ⚠️ Nuance de rédaction : « **déclare 0** » se lit mal quand la cause réelle est « **n'a rien déclaré** ». → **US-00.8** |
| **D-2** | lecture | `scripts/selftest_coverage_ratchet.py:196` | **INFO** | Le correctif **RF-4** remplace `len(CAS)` par `total_assertions = len(CAS) + 1 + 2`. Le **`+ 1 + 2` reste écrit à la main** : ajouter un 2ᵉ différentiel ou un 3ᵉ cas « plancher seul » **refera dériver le décompte** — **exactement** le défaut que RF-4 dit tuer. *(Le compte est **juste aujourd'hui** : 9 = 6 + 1 + 2, vérifié à l'exécution.)* | **NON BLOQUANT** — aucun effet sur le verdict *(seul `echecs` décide du code de sortie ; le nombre n'est qu'un affichage)*. **Amélioration réelle mais partielle** : un nombre entièrement recopié est devenu **partiellement** dérivé. → **US-00.8** |
| **D-3** | lecture | `scripts/selftest_coverage_ratchet.py:49,52,159` | **INFO** | Le différentiel assertionne `f"seuil requis : {ref}%"` dans la sortie. Cela **suppose silencieusement `PLANCHER < ref_basse`** *(80,0 < 86,0)* : si `PLANCHER` était un jour relevé au-dessus de `86.0`, `required` deviendrait le **plancher**, la chaîne ne serait plus trouvée, et l'autotest **rougirait dans un job REQUIS** — un **faux rouge**, sur un couplage **qui n'est assertionné nulle part** | **NON BLOQUANT** *(les deux constantes vivent dans le **même fichier**, à **3 lignes** d'écart, et le rouge serait immédiat et lisible)*. Remède à coût nul : `assert PLANCHER < ref_basse` explicite. → **US-00.8** |

### 6.4 ⚖️ **N-1 — l'arbitrage que vous me demandez : JE MAINTIENS QUE C'EST ACCEPTABLE.**

**Rappel du défaut** : la copie humaine du diff T8 avait injecté dans `scripts/factory_sync.py`
**(a)** une ligne de blancs `'    '` après `return errors` et **(b)** un commentaire indenté à
**24 espaces** au lieu de 4.

**Ma position, motivée — ⛔ ne pas solliciter de 3ᵉ édition humaine :**

1. **L'effet est nul, et c'est mesuré, pas supposé.** `compile()` → **OK** ; **28/28 lignes exécutables
   identiques** au diff proposé ; `emit_branch_protection` **octet-identique** ; `factory_sync --check`
   → **exit 0** ; `--check-remote` → **exit 0, 12 champs alignés, 0 écart**. Python ignore commentaires et
   lignes blanches pour l'indentation. **Il n'existe aucun chemin par lequel ce défaut puisse produire un
   comportement.**
2. **Le remède coûterait plus cher que le mal, et du même type.** ⚠️ **Argument décisif : N-1 est né d'une
   copie manuelle sur un fichier protégé.** En solliciter une **troisième** sur le **script le plus
   sensible du dépôt** — celui qui génère la cible de protection de `main` — pour corriger **quatre
   espaces**, c'est **réintroduire volontairement le mécanisme exact qui a produit le défaut**, avec cette
   fois un risque **non nul** de divergence **réelle**. **Le remède est plus dangereux que la maladie.**
3. **Le seul préjudice résiduel est de lisibilité**, et il est **déjà neutralisé par la trace** : le
   commentaire mal indenté peut tromper un lecteur pressé sur son rattachement au bloc `frontend` — mais
   **c'est écrit, daté et localisé** dans deux rapports d'audit versionnés. **Un défaut nommé n'est plus
   un piège.**
4. **Conditions de levée, à porter en dette** : à corriger **par surcroît**, **le jour où
   `scripts/factory_sync.py` sera édité pour une autre raison** *(NB-1bis est déjà attendu sur ce
   fichier)* — **jamais** dans une édition dédiée. → **US-00.8**.

> ⇒ **Réponse nette : NE PAS solliciter l'humain pour N-1.** Aucun bloquant n'en dépend, et je n'en fais
> **pas** une condition de mon `PASSED`.

---

## 7. ⛔ Bornes — ce sur quoi ce `PASS` ne s'appuie PAS

1. ⛔ **AUCUN SAST n'existe dans cette factory.** `run_gates --gate sast` → **exit 1, ce gate n'existe
   pas**. **Aucun finding SAST n'a été produit, donc aucun n'a été exclu.** Ce verdict repose sur une
   **revue manuelle**, `gitleaks` et `actionlint` — **jamais** sur un SAST.
2. ⛔ **AUCUN SCANNER DE CVE n'existe.** `deps_audit` = `dart pub outdated` = **obsolescence**, pas
   vulnérabilité, et il est **`blocking: false`**. **Aucun verdict de sécurité sur les dépendances n'est
   possible** ici. *(Fait atténuant : le delta **n'ajoute aucune dépendance** — les deux scripts
   n'utilisent que la bibliothèque standard. Surface de chaîne d'approvisionnement **inchangée**.)*
3. ⛔ **Les ~170 lignes de Python ajoutées par ce delta ne sont couvertes par AUCUNE analyse statique**
   *(N-8, toujours ouvert)*. `app.format`/`app.analyze` ne portent que sur **Dart**.
4. ⚠️ **`gitleaks` a couvert l'arbre de travail et les 6 commits `f585e82..62a4fcc`** — **PAS l'historique
   complet**. Le dépôt étant **public**, une fuite antérieure resterait hors périmètre.
5. ⚠️ **Mon `actionlint` local est PLUS FAIBLE que celui de la CI** : `shellcheck` et `pyflakes`
   désactivés (binaires absents), alors que `shellcheck` **est** présent sur `ubuntu-latest`. Je n'ai pas
   revérifié l'empreinte du **tarball Linux** épinglée dans `ci.yml` (j'ai employé l'archive Windows).
6. ⚠️ **Aucune écriture exécutée** : aucun `PUT`/`PATCH`/`POST`, aucun `push`, aucun `--admin`. L'état de
   la protection est **lu**. Mes fichiers de test vivent **hors du dépôt** (scratchpad).
7. ⚠️ **NON TESTÉ, et je ne l'affirme pas** : le comportement d'une **PR de fork** *(N-7)* · un **autre
   acteur**, un **jeton d'application**, l'**interface web** · la **persistance** de l'état de protection ·
   le comportement du recoupement LF/LH face à des versions **futures** de l'outillage Dart *(D-1 :
   j'ai éprouvé **5 formats**, je ne revendique **aucune exhaustivité**)*.
8. ⚠️ **La provenance humaine des deux éditions de fichiers protégés reste NON PROUVABLE** *(N-9)* — elle
   est **déclarative**. Le delta n'y change rien : **ces deux fichiers n'ont pas été retouchés**.
9. ⚠️ **Ce rapport couvre le DELTA `f585e82..62a4fcc`**, en s'appuyant sur mon 1ᵉʳ passage pour tout ce que
   le delta ne touche pas. **Il n'est pas un ré-audit intégral** — et je l'ai borné à ce que j'ai
   **effectivement ré-exécuté**, listé en annexe.

---

## 8. Verdict

> ## ✅ **PASSED** sur **`62a4fcc`**
>
> **0 finding BLOQUANT.** `gitleaks` propre sur l'arbre (121,77 Mo) **et** sur les 6 commits du delta,
> détecteur **non desserré**. `ci.yml` = **commentaires seuls**, **3 `name:` de jobs octet-identiques**,
> `actionlint` **0 erreur**. Le nouveau code : **aucun appel réseau**, **aucune écriture hors des 3
> `tempfile.TemporaryDirectory()`**, `subprocess.run` en **forme liste** dont **100 % des arguments sont
> des constantes du module** — **aucune surface d'injection**. Les **3 nouvelles fixtures** sont
> **synthétiques** *(`lib/lf_menteur.dart`, `lib/incoherent.dart`, `lib/sous_plancher.dart` — inexistants)*.
> `emit_branch_protection` **toujours octet-identique**, `factory.config.json` et `factory_sync.py`
> **non touchés depuis mon badge précédent** *(vérifié, non cru)*. `main` **toujours protégée**,
> 4 contextes, `enforce_admins` en vigueur. **Aucun faux rouge** sur le gate requis.
>
> **Sur mes 4 MEDIUM du 1ᵉʳ passage : N-2 CORRIGÉ, N-3 CORRIGÉ, N-4 RECTIFIÉ (daté, non repeint),
> N-1 MAINTENU acceptable — arbitrage rendu au §6.4, ⛔ ne pas solliciter de 3ᵉ édition humaine.**
>
> **3 findings de delta**, tous **NON BLOQUANTS** : **D-1** *(LOW — nouvelle cause de rouge sur un gate
> requis si un `lcov` omet `LF:`/`LH:` ; 4 formats réels sur 5 passent, en fermeture et auto-révélateur ;
> **ferme au passage le cas de la troncature**)* · **D-2** et **D-3** *(INFO)*. **Tous versés à US-00.8**,
> conformément à votre décision de convergence.
>
> ⛔ **Ce `PASS` ne s'appuie ni sur un SAST ni sur un scan de CVE : aucun des deux n'existe.** Les
> **9 bornes du §7** en font partie intégrante.

---

### Annexe — ce que j'ai RÉELLEMENT ré-exécuté sur ce delta

`gitleaks --no-git` (121,77 Mo) · `gitleaks --log-opts f585e82..62a4fcc` (6 commits) · `actionlint 1.7.12`
(3 workflows, binaire re-téléchargé) · `run_gates --all` · `run_gates --gate test` · `factory_sync --check` ·
`validate_trace --all` · `check_scb_compliance` · `selftest_coverage_ratchet` (9 assertions) ·
comparaison **AST** `main`↔`HEAD` des 9 fonctions de `factory_sync.py` · `git diff` des 2 fichiers
protégés `f585e82..HEAD` · comparaison des `name:` de jobs `f585e82`↔`HEAD` · **5 formats de `lcov` réels**
contre le recoupement LF/LH *(multi-records, somme de contrôle, sans LF/LH, espaces, BRDA/BRF)* ·
**3 formes de `DA:` malformée** *(régression de N-3)* · **3 encodages** `cp1252`/`ascii`/`utf-8` sur le
chemin HAUSSE · analyse **AST** des littéraux de `print`/`raise` des 2 scripts · `grep` réseau /
écritures / primitives dangereuses · `gh api` ×3 en **lecture seule** (branche, protection, visibilité).
