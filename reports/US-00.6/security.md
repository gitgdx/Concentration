# US-00.6 · Audit sécurité — @CyberSecurity (contexte frais)

| Champ | Valeur |
|---|---|
| **US** | US-00.6 — Couverture initiale mesurée + cliquet (*ratchet*) réellement actif |
| **Agent** | @CyberSecurity — **contexte frais** (Constitution Art. 2) |
| **Modèle réel** | `claude-opus-5[1m]` |
| **Date** | 2026-07-31 |
| **Branche** | `feat/US-00.6-couverture-ratchet` · **HEAD = `f585e82`** · partie de `main` = **`309202a`** |
| **Diff audité** | `git diff main...HEAD` — 18 fichiers, **1573 insertions / 5 suppressions** |
| **VERDICT** | ✅ **PASSED** — **0 finding bloquant** · **10 findings non bloquants** (dont **4 MEDIUM**) |

> ⛔ **Ce verdict ne s'appuie NI sur un SAST, NI sur un scan de CVE : aucun des deux n'existe dans cette
> factory.** Il s'appuie sur `gitleaks`, `actionlint`, une revue manuelle du diff et **23 exécutions
> ciblées** dont les sorties sont collées ci-dessous. Le périmètre exact de ce qui est prouvé — et de ce
> qui ne l'est pas — est écrit au §7. **Ni complaisance, ni refus par prudence.**

---

## 0. Nature de l'US — dit franchement, pas contourné

**0 fichier Dart applicatif** dans le diff. Il n'y a donc **rien à auditer** au titre de :
**injection SQL/NoSQL** *(aucune requête, aucun ORM, aucune base)* · **IDOR** *(aucune ressource, aucun
propriétaire, aucun identifiant)* · **XSS** *(aucun rendu)* · **authz par endpoint** *(aucun endpoint)* ·
**CSRF / CORS** *(aucun cookie de session, aucune origine)* · **hachage de mot de passe** *(aucune
authentification)*. ⛔ **Je ne déguise pas cette absence en « conforme »** : ces contrôles sont **SANS
OBJET**, ce qui n'est pas la même chose que **passés**.

Le risque réel de cette US est ailleurs, et il est **entier** : elle modifie **l'outillage
d'enforcement du dépôt**. Trois surfaces, auditées une par une :

| Surface | Fichier | Portée du risque |
|---|---|---|
| **S-A** | `factory.config.json` *(**protégé**)* | source unique des seuils et de la cible de protection de branche |
| **S-B** | `scripts/factory_sync.py` *(**protégé**)* | génère la cible de protection de `main` |
| **S-C** | `.github/workflows/ci.yml` *(**NON protégé**)* | step ajouté à un job **REQUIS** → un échec rend **toute PR infusionnable, administrateur inclus** |

---

## 1. Sorties d'outils — collées verbatim

### 1.1 `python scripts/run_gates.py --gate sast` → **exit 1**

```
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

🔴 **Le gate `sast` N'EXISTE PAS.** Dette déjà nommée dans `CLAUDE.md`, **confirmée par exécution**.
⇒ **Aucun finding SAST ne peut être produit ni exclu.** Mon `PASS` **ne s'appuie pas** sur un SAST.

### 1.2 `python scripts/run_gates.py --gate deps_audit` → **exit 0**

```
▶ app.deps_audit — (.) $ dart pub outdated --show-all
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name                  Current   Upgradable  Resolvable  Latest
direct dependencies:
cupertino_icons               1.0.9     1.0.9       1.0.9       1.0.9
flutter                       (sdk)     (sdk)       (sdk)       (sdk)
dev_dependencies:
flutter_lints                 6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                  (sdk)     (sdk)       (sdk)       (sdk)
transitive dependencies:
meta                          *1.18.0   *1.18.0     *1.18.0     1.19.0
vector_math                   *2.2.0    *2.2.0      *2.2.0      2.4.2
transitive dev_dependencies:
matcher                       *0.12.19  *0.12.19    *0.12.19    0.12.20
test_api                      *0.7.11   *0.7.11     *0.7.11     0.7.13
(… 22 paquets au total, tous à la dernière version résolvable)
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
Tous les gates bloquants passent (1 exécutés).
EXIT=0
```

⛔ **CE N'EST PAS UN SCAN DE VULNÉRABILITÉ.** `dart pub outdated` mesure l'**obsolescence**. Les
**4 paquets marqués `*`** *(`meta`, `vector_math`, `matcher`, `test_api`)* sont **transitifs** et
**bloqués par le SDK** — aucun n'est une dépendance **directe**. **Aucune information de CVE n'est
produite, donc aucune CVE n'est ni trouvée ni exclue.** ⚠️ Fait aggravant relevé par exécution :
ce gate porte **`blocking = False`** dans `factory.config.json` — le seul gate de dépendances du dépôt
est **non bloquant**.

**Dépendances ajoutées par cette US : ZÉRO** — `pubspec.yaml`, `pubspec.lock` et `requirements.txt` sont
**absents du diff** *(`git diff --numstat main...HEAD -- pubspec.yaml pubspec.lock requirements.txt` →
sortie vide)*. Les deux scripts livrés n'importent que la **bibliothèque standard**
(`argparse`, `json`, `sys`, `pathlib`, `subprocess`, `tempfile`). **Surface de chaîne
d'approvisionnement inchangée.**

### 1.3 `gitleaks` 8.30.1 — **arbre de travail** → **exit 0**

```
$ gitleaks detect --no-git --source . --config .gitleaks.toml --redact -v
INF scanned ~121449638 bytes (121.45 MB) in 7.9s
INF no leaks found
EXIT=0
```

### 1.4 `gitleaks` — **historique de l'US `309202a..f585e82`** → **exit 0**

```
$ gitleaks detect --source . --config .gitleaks.toml --log-opts "309202a..f585e82" --redact -v
INF 2 commits scanned.
INF scanned ~139049 bytes (139.05 KB) in 522ms
INF no leaks found
EXIT=0
```

⚠️ **Le dépôt est PUBLIC depuis le 2026-07-27** *(vérifié : `visibility: "public"`, `private: false`)* —
toute fuite serait **irréversible**. Les **deux** passes sont propres.
⛔ **Aucun `grep` de motifs n'a été employé pour conclure** : le piège documenté du projet *(un `grep`
matche la **documentation** des motifs)* a été évité — **`gitleaks` seul fait foi**, et il a tourné
**deux fois**.
✅ **`.gitleaks.toml` n'est PAS modifié par cette US** *(`git diff --numstat main...HEAD -- .gitleaks.toml
.claude/ scripts/githooks/` → **sortie vide**)* : **aucun élargissement d'allowlist**, aucun hook touché.
Le résultat propre n'est donc pas obtenu en desserrant le détecteur.

### 1.5 `actionlint` 1.7.12 *(même version que celle épinglée en CI)* → **exit 0**

```
$ actionlint -color -verbose .github/workflows/*.yml
verbose: Linting 3 files
verbose: Found 0 parse errors in 4 ms for .github/workflows/ci.yml
verbose: Found 0 parse errors in 3 ms for .github/workflows/branch-naming.yml
verbose: Found 0 parse errors in 0 ms for .github/workflows/e2e.yml
verbose: Rule "shellcheck" was disabled: exec: "shellcheck": executable file not found in %PATH%
verbose: Rule "pyflakes"   was disabled: exec: "pyflakes":   executable file not found in %PATH%
verbose: Found total 0 errors in 3 files
EXIT=0
```

⚠️ **Borne honnête sur cet outil** : les règles **`shellcheck`** et **`pyflakes`** ont été **DÉSACTIVÉES**
localement (binaires absents du poste). `shellcheck` **est** présent sur les runners `ubuntu-latest` ⇒
**l'exécution en CI est PLUS forte que la mienne**, pas moins. Par ailleurs j'ai téléchargé l'archive
**Windows** (`sha256 6e7241b5…`), donc **je n'ai pas revérifié l'empreinte `8aca8db9…` du tarball Linux**
épinglée dans `ci.yml` — je constate seulement qu'elle **est** épinglée.

### 1.6 Non-régression de l'outillage → **tous exit 0**

```
$ python scripts/run_gates.py --all         → Tous les gates bloquants passent (5 exécutés).   exit 0
$ python scripts/run_gates.py --gate test   → Couverture de lignes : 89.5% (17/19) — seuil requis : 89.4% (cliquet)
                                              ✅ app.test                                       exit 0
$ python scripts/factory_sync.py --check    → Synchro factory conforme — vérification DOCUMENTAIRE… exit 0
$ python scripts/validate_trace.py --all    → Traçabilité conforme.                            exit 0
$ python scripts/check_scb_compliance.py    → SCB conforme — Aucune violation détectée.         exit 0
$ python scripts/selftest_coverage_ratchet.py → les 4 attentes sont tenues, dont 2 REFUS.       exit 0
```

---

## 2. S-B — `scripts/factory_sync.py` : le script le plus sensible du dépôt

### 2.1 Ajout pur ? ✅ **OUI — 32 insertions, 0 suppression**

```
$ git diff --numstat main...HEAD -- .github/ scripts/ factory.config.json
15	0	.github/workflows/ci.yml
6	0	factory.config.json
148	5	scripts/check_flutter_coverage.py
32	0	scripts/factory_sync.py
122	0	scripts/selftest_coverage_ratchet.py
```

### 2.2 `emit_branch_protection` intact ? ✅ **OUI — prouvé par AST, pas par lecture**

Comparaison **fonction par fonction** du texte source entre `main:scripts/factory_sync.py` et `HEAD` :

```
fonctions main : 9 | HEAD : 9
ajoutees : []  | supprimees : []
identique  emit_branch_protection      ← LA fonction sensible
identique  render_protection_block
identique  check_workflows
identique  do_check
identique  do_write
identique  main
identique  render_env
identique  replace_block
MODIFIEE   check_thresholds            ← la SEULE, et c'est celle visée par T8
```

**8 des 9 fonctions sont octet-pour-octet identiques à `main`.** Le bloc `frontend` vit dans
`check_thresholds` et son texte est **inchangé** *(le diff est un ajout pur inséré **après** lui)*.

### 2.3 La cible de protection de branche est-elle inchangée ? ✅ **OUI — double preuve**

**Preuve 1 — isolation des entrées.** `emit_branch_protection` ne lit **que** `cfg["branch_protection"]`
et `cfg["status_checks"]` ; elle **ne contient ni `check_thresholds` ni `coverage_ratchet`** *(vérifié par
inspection AST du corps)*. Or le diff de `factory.config.json` n'ajoute **que**
`adapter.components.app.coverage_ratchet` ⇒ **aucune entrée de cette fonction n'est touchée.**

**Preuve 2 — sortie réelle, et elle est conforme à l'état SERVEUR en vigueur.**

```
$ python scripts/factory_sync.py --emit-branch-protection
{ "required_status_checks": { "strict": true, "contexts": [
      "🔐 Secrets scan (gitleaks)", "📋 Governance (SCB + traçabilité + synchro)",
      "check-branch-name", "📱 App (gates run_gates.py)" ] },
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "enforce_admins": true, "restrictions": null,
  "allow_force_pushes": false, "allow_deletions": false,
  "required_linear_history": false, "required_conversation_resolution": true }
```

**4 contextes requis · `enforce_admins: true` · `0` approbation** — identique à la cible appliquée le
2026-07-28 *(`reports/US-00.7/applied_state/`)*.

### 2.4 🔴 Le diff APPLIQUÉ correspond-il au diff PROPOSÉ ? — **le point que personne n'avait vérifié**

Comparaison **mécanique** entre le bloc `diff` de `reports/US-00.6/transmissions_humaines.md` **§T8** et
le hunk réellement appliqué :

```
lignes « + » appliquees = 32   proposees = 34
lignes EXECUTABLES appliquees = 28   proposees = 28
CODE EXECUTABLE IDENTIQUE : True
compile(factory_sync.py) : OK

---- differences NON executables (commentaires / blancs) ----
--- PROPOSE                                       +++ APPLIQUE
+'                        # US-00.6 — cliquet de couverture du composant `app`…'   ← 24 espaces d'indentation
+'    # Le bloc `frontend` ci-dessus ne voit PAS ce composant : la cle y serait IGNOREE.'
+'    '                                            ← LIGNE DE BLANCS INJECTÉE, absente du diff proposé
-'    # US-00.6 — cliquet de couverture du composant `app`…'
-'    # Le bloc `frontend` ci-dessus ne voyait PAS ce composant : la cle y etait donc'
-'    # IGNOREE en silence. Ici on valide sa FORME et sa COHERENCE avec le plancher.'
-"                # Le cliquet n'a d'effet QUE si le gate l'applique : on verifie que la"
-'                # commande du gate `test` passe bien par le script qui le lit.'
```

**Conclusion, sans atténuation et sans dramatisation** : ✅ **les 28 lignes EXÉCUTABLES sont
IDENTIQUES** — il n'y a **aucune divergence fonctionnelle**, et la copie humaine n'a **rien introduit
d'exécutable** qui ne fût pas proposé. ⚠️ Mais la copie **DIVERGE en 6 endroits** sur les commentaires et
les blancs, dont **deux artefacts non intentionnels** *(finding **N-1**)*. **La question posée était
légitime : la réponse est « oui pour le code, non pour le texte ».**

---

## 3. S-C — le step ajouté à un job REQUIS : injection de commande ?

### 3.1 ⛔ **AUCUNE interpolation dans le step ajouté** — c'est la classe exacte du bloquant B-1 d'US-00.7

```yaml
      - name: 🔒 Autotest du cliquet de couverture (US-00.6)
        run: python scripts/selftest_coverage_ratchet.py
```

```
$ grep -n '\${{' .github/workflows/ci.yml
44:  group: ci-${{ github.ref }}                      ← PRÉEXISTANT (concurrency, hors contexte shell)
65:          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} ← PRÉEXISTANT (job secrets-scan)
```

**Le step ajouté ne porte AUCUN `${{ … }}`**, aucune variable d'environnement, aucune donnée issue d'une
PR, aucun titre de branche, aucun `run:` multiligne. **Il n'y a rien à injecter.** Les 2 seules
interpolations du fichier sont **antérieures à cette US** et hors du diff. `actionlint` le confirme
indépendamment *(§1.5, 0 erreur)*.

### 3.2 Le script tourne-t-il avec des droits minimaux ? ✅ **OUI, et c'est mesuré**

```
$ gh api repos/gitgdx/Concentration/actions/permissions/workflow
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}
```

Le job `governance` **ne déclare aucun bloc `permissions:`** *(contrairement à `secrets-scan`,
l. 56-58)* ⇒ il hérite du **défaut du dépôt**, qui est **`read`**, avec
`can_approve_pull_request_reviews: false`. **Le nouveau step tourne donc avec un `GITHUB_TOKEN` en
LECTURE SEULE.** ⚠️ Mais ce n'est vrai que par un **réglage de dépôt**, pas par le fichier —
finding **N-5**.

### 3.3 Réseau, écritures, primitives dangereuses

```
$ grep -nE "urllib|requests|socket|http|urlopen|subprocess|os\.system|eval\(|exec\(|pickle|
            yaml\.load|write_text|shutil|os\.remove|unlink|tempfile"
          scripts/check_flutter_coverage.py scripts/selftest_coverage_ratchet.py
scripts/selftest_coverage_ratchet.py:21:import subprocess
scripts/selftest_coverage_ratchet.py:23:import tempfile
scripts/selftest_coverage_ratchet.py:52:    proc = subprocess.run(
scripts/selftest_coverage_ratchet.py:79:    with tempfile.TemporaryDirectory() as tmp:
scripts/selftest_coverage_ratchet.py:81:        cfg.write_text(
```

| Question du mandat | Réponse | Preuve |
|---|---|---|
| **Appel réseau ?** | ⛔ **AUCUN** | 0 occurrence de `urllib`/`requests`/`socket`/`http`/`urlopen` dans les **deux** scripts |
| **Écriture hors `tempfile` ?** | ⛔ **AUCUNE** | la seule écriture est `cfg.write_text(...)` **à l'intérieur** de `with tempfile.TemporaryDirectory()`. `check_flutter_coverage.py` **n'écrit rien du tout** |
| **Lit-il autre chose que le dépôt ?** | **Non** | `tests/fixtures/US-00.6/*.info`, `scripts/check_flutter_coverage.py`, `factory.config.json` — chemins **relatifs**, aucun chemin absolu, aucun `~`, aucune variable d'environnement |
| **`shell=True` ?** | ⛔ **NON** | `subprocess.run([sys.executable, str(CHECKER), "--min", str(PLANCHER), …])` — **forme LISTE**, et **tous** les arguments viennent de **constantes du module** (`CHECKER`, `PLANCHER`, la liste `CAS` en dur, un chemin de `tempfile`). **Aucune entrée externe n'atteint la ligne de commande** |
| **`eval` / `exec` / `pickle` / `yaml.load` ?** | ⛔ **AUCUN** | la configuration est lue par `json.loads` |

---

## 4. S-A — `factory.config.json` : diff appliqué vs proposé

```diff
         "coverage_min": 80,
+        "coverage_ratchet": {
+          "value": 89.4,
+          "date": "2026-07-31",
+          "motif": "US-00.6 — couverture initiale mesuree 17/19 = 89,4737 %, arrondie VERS LE BAS. …"
+        },
+
         "install": {
```

**6 insertions, 0 suppression.** Valeurs **conformes** au diff T7 proposé *(`89.4`, `2026-07-31`, motif
identique)*. Seule divergence : **une ligne vide surnuméraire** après l'objet — sans effet, JSON valide
*(`json.load` réussit)*. ✅ **Aucun autre nœud de la configuration n'est modifié** : ni
`branch_protection`, ni `status_checks`, ni `git`, ni les `gates` — donc **ni la cible de protection de
branche, ni la liste des contextes requis, ni les commandes de gate**.

**Les deux fichiers sont bien protégés** *(`.claude/hooks/protect_files.sh:28`)* :

```
scripts/githooks/*|.claude/settings.json|.claude/hooks/*|.gitleaks.toml|scripts/install_hooks.sh|
factory.config.json|scripts/factory_env.sh|scripts/factory_sync.py|scripts/run_gates.py)
```

---

## 5. Surface d'attaque du cliquet lui-même — qualification demandée

### 5.1 Le mutant fonctionne dans les DEUX sens, et tous les chemins d'erreur sont explicites

**7 mutations de configuration exécutées** contre la fixture `inchange_17_sur_19.info` :

| Mutation | `exit` | Message obtenu |
|---|---|---|
| cliquet → **95** *(au-dessus de la mesure)* | **1** | `RÉGRESSION : couverture 89.47% < 95.0% (cliquet). Écart 5.53 pt, soit ~1.1 ligne(s) sur 19.` |
| cliquet **remis à 89.4** | **0** | `seuil requis : 89.4% (cliquet)` — ✅ **le verdict revient** |
| clé **absente** | **0** | `cliquet NON CONFIGURÉ (clé … absente) — seul le plancher contractuel s'applique` |
| clé = **chaîne** | **1** | `cliquet MAL FORMÉ : … doit être un objet {value, date, motif}, reçu str` |
| `value` = `"abc"` | **1** | `cliquet MAL FORMÉ : « value » n'est pas un nombre ('abc')` |
| `value` **absente** | **1** | `cliquet MAL FORMÉ : champ « value » absent` |
| cliquet **70 < plancher 80** | **1** | `configuration INCOHÉRENTE : cliquet 70.0% < plancher contractuel 80.0%` |

✅ **La valeur est RÉELLEMENT LUE** *(mutation ⇒ verdict changé ; remise ⇒ verdict revenu)*.
✅ **Aucun faux vert sur aucun des 7 chemins.** ✅ **Aucun plantage** côté configuration.

### 5.2 Régression du bug trouvé par le mutant — **vérifiée sous 3 encodages**

Le correctif est-il réel ? Testé sur le chemin **HAUSSE** *(le seul qui déclenchait le bug)* :

| `PYTHONIOENCODING` | `hausse_18_sur_19` | `regression_16_sur_19` |
|---|---|---|
| `cp1252` | **exit 0** ✅ | **exit 1** ✅ |
| `ascii` *(cas le plus dur)* | **exit 0** ✅ | **exit 1** ✅ |
| `utf-8` | **exit 0** ✅ | **exit 1** ✅ |

Et la revendication *« aucun caractère hors `cp1252` ne subsiste dans les sorties »* est **revérifiée
indépendamment par AST** *(seuls les littéraux d'arguments de `print` et les messages de `raise`, jamais
les commentaires ni les docstrings)* :

```
scripts/check_flutter_coverage.py    : litteraux de print hors cp1252 -> 0
scripts/selftest_coverage_ratchet.py : litteraux de print hors cp1252 -> 0
messages de `raise` hors cp1252      -> 0
```

✅ **Le correctif tient.** La garde `reconfigure(errors="replace")` est un **filet**, pas la seule
défense — voir la borne au §7.

### 5.3 Les 4 fixtures `lcov` : aucune donnée réelle, aucun chemin sensible

| Fixture | Contenu | Chemin déclaré |
|---|---|---|
| `regression_16_sur_19.info` | 19 `DA:` + `LF:19` `LH:16` | `SF:lib/fixture.dart` — **fichier inexistant, synthétique** |
| `inchange_17_sur_19.info` | 19 `DA:` + `LF:19` `LH:17` | `SF:lib/fixture.dart` — idem |
| `hausse_18_sur_19.info` | 19 `DA:` + `LF:19` `LH:18` | `SF:lib/fixture.dart` — idem |
| `zero_ligne_mesurable.info` | `LF:0` `LH:0`, **aucun `DA:`** | `SF:lib/vide.dart` — **fichier inexistant** |

⛔ **Aucun chemin absolu, aucun nom d'utilisateur, aucun chemin réel du poste, aucune donnée applicative,
aucun secret.** Les 4 fixtures totalisent **77 lignes** de compteurs synthétiques. `gitleaks` les a
scannées *(§1.3/1.4)* : rien.

### 5.4 🎯 « Un `lcov` est un fichier de BUILD, non authentifié » — qualification EXPLOITABLE / PAS EXPLOITABLE

**Le constat est exact** : le cliquet atteste une **baisse du chiffre rapporté**, jamais la **réalité**
des tests. Le livrable **le dit lui-même** *(`selftest` : « ne prouve NI l'authenticité du rapport lcov,
NI la qualité des tests »)*. Mais la question posée est : **exploitable, et par qui ?** Réponse mesurée :

| Chemin d'attaque | Exploitable ? | Preuve |
|---|---|---|
| **Committer un `lcov` falsifié** | ⛔ **NON — deux barrières indépendantes** | (1) `git check-ignore -v coverage/lcov.info` → `.gitignore:51:/coverage/` ⇒ il faudrait un `git add -f` ; (2) **surtout**, la commande du gate est `flutter test --coverage && python scripts/check_flutter_coverage.py` — le rapport est **RÉGÉNÉRÉ dans la même commande, juste avant d'être lu**. Un faux serait **écrasé** |
| **Modifier la commande du gate** | **Nécessite d'éditer `factory.config.json`** — fichier protégé (agent bloqué) et Art. 6 | mais ⚠️ **aucune barrière serveur** : pas de `CODEOWNERS`, `0` approbation requise |
| **Supprimer le step d'autotest du workflow** | ⚠️ **OUI, techniquement** — `.github/workflows/*` n'est **pas** protégé | finding **N-7** |
| **Écrire des tests de complaisance** | ⚠️ **OUI** — et le cas est **nommé d'avance** par l'US *(couvrir `void main()`/`runApp(...)` = +10,5 pt sans valeur)* | non mitigé, **assumé et écrit** |

**Qualification finale** : sur **ce** dépôt, l'acteur capable d'exploiter le non-authentification du
`lcov` est exactement celui qui **administre déjà** le dépôt. Vérifié : **un seul collaborateur**,
`gitgdx`, **`admin: true`**, `restrictions` **absente** *(dette de provenance établie par US-00.7 :
`mergedBy.is_bot` ne prouve rien, les agents opèrent avec le jeton de l'humain)*. ⇒ **Le risque n'est pas
un risque d'ÉLÉVATION de privilège : c'est un risque de DISCIPLINE.** Il ne devient un risque
d'**autorisation** que le jour où un second acteur — ou un **fork** — existe. **Ce n'est donc pas
bloquant**, et **ce n'est pas non plus « résolu »**.

### 5.5 🔴 « Une troncature du `lcov` AUGMENTE le pourcentage » — **CETTE AFFIRMATION EST FAUSSE**

Le mandat me la présentait comme un **« fait vérifié à connaître »**, et elle est écrite **quatre fois**
dans le livrable *(Story File AC-3 « Erreur » et risque R-2 · `tests/fixtures/US-00.6/README.md` §« Pourquoi
les lignes non couvertes sont EN TÊTE » · docstring de `check_flutter_coverage.py`)*. **Je l'ai mesurée sur
le rapport RÉEL** `coverage/lcov.info` *(non versionné : `DA:9,0`, `DA:10,0`, puis 17 lignes couvertes)* :

```
prefixe  1 ->  0/1  =  0.00 %       prefixe 10 ->  8/10 = 80.00 %
prefixe  2 ->  0/2  =  0.00 %       prefixe 15 -> 13/15 = 86.67 %
prefixe  3 ->  1/3  = 33.33 %       prefixe 18 -> 16/18 = 88.89 %
prefixe  5 ->  3/5  = 60.00 %       prefixe 19 -> 17/19 = 89.47 %  ← rapport COMPLET
```

**La suite est strictement croissante en `n` ⇒ TOUTE troncature de tête DIMINUE le pourcentage.** Même
résultat sur les fixtures *(troncature à 12 lignes → 8/10 = 80,0 % → **ROUGE**, exit 1, mesuré)*.

**Le raisonnement est un non-sequitur** : « les lignes non couvertes sont **en tête** » implique
exactement l'**INVERSE** de la conclusion tirée. Un `lcov` tronqué **échoue en fermeture** — il est
**conservateur**, précisément *parce que* les lignes non couvertes sont en tête.

⚖️ **Pourquoi ce n'est pas BLOQUANT** : le sens de l'erreur va **vers la sûreté**. Le comportement réel
est **plus sûr** que ce que le livrable annonce, et le refus du cas « 0 ligne mesurable » **reste
légitime par lui-même** *(un ensemble vide n'est pas une mesure — remède 4 d'US-00.5)*. **Aucun trou
n'est ouvert.**
⚠️ **Pourquoi il faut malgré tout l'écrire** : une justification de sécurité présentée comme
**« vérifiée »** et **falsifiée par la première exécution** est **exactement** le défaut qu'US-00.5 a payé
au prix de **six instruments de contrôle faux**. Finding **N-4**.

---

## 6. Tableau des findings — `[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

### 6.1 🔴 BLOQUANTS — **AUCUN**

| Critère bloquant de mon rôle | Constat | Preuve |
|---|---|---|
| Finding SAST **HIGH** | **impossible à produire** — le gate n'existe pas | §1.1 |
| **CVE HIGH/CRITICAL** sur dépendance **directe** | **impossible à produire** — aucun scanner de CVE ; **0 dépendance ajoutée** | §1.2 |
| **IDOR** | **SANS OBJET** — 0 ressource, 0 identifiant, 0 fichier Dart | §0 |
| **Secret en dur** | **AUCUN** — `gitleaks` **×2** (arbre 121 MB + 2 commits), config du détecteur **non modifiée** | §1.3/1.4 |
| **Endpoint sans contrôle d'authz** | **SANS OBJET** — 0 endpoint | §0 |
| *(spécifique à cette US)* **Dérive entre diff proposé et diff appliqué sur un fichier protégé** | **28/28 lignes exécutables IDENTIQUES** — aucune divergence fonctionnelle | §2.4 |
| *(spécifique)* **Injection de commande dans un job REQUIS** | **AUCUNE** — 0 interpolation dans le step ; `actionlint` 0 erreur | §3.1 |
| *(spécifique)* **Régression de la cible de protection de branche** | **AUCUNE** — `emit_branch_protection` octet-identique + entrées isolées | §2.2/2.3 |

### 6.2 🟠 NON BLOQUANTS

| # | Outil | Fichier:Ligne | Sév. | Constat | Décision |
|---|---|---|---|---|---|
| **N-1** | `git diff` + AST + `compile()` | `scripts/factory_sync.py:156-158` et `:187-188` | **MEDIUM** | La copie humaine **diverge** du diff T8 proposé sur **6 éléments non exécutables** : (a) le 1ᵉʳ commentaire est collé à **24 espaces** d'indentation au lieu de 4 — il **paraît appartenir au bloc `frontend`** alors qu'il introduit le bloc `app` ; (b) 1 ligne de commentaire supprimée/reformulée ; (c) 2 lignes de commentaire supprimées *(explication de `test_cmd`)* ; (d) 🔴 **une ligne de blancs `'    '` INJECTÉE après `return errors`**, absente du diff proposé. `compile()` → **OK**, code exécutable **identique** | **ACCEPTÉ, NOMMÉ.** Aucun effet fonctionnel *(Python ignore commentaires et lignes blanches pour l'indentation)*. Mais ce sont **deux artefacts non intentionnels dans le script le plus sensible du dépôt**, et le commentaire mal indenté est un **piège de lecture** pour le prochain auditeur. → **@CodeReviewer** ; **aucun linter Python n'existe pour l'attraper** *(N-8)* |
| **N-2** | exécution (T-B) | `scripts/check_flutter_coverage.py:65-75` | **MEDIUM** | AC-3 « Erreur » exige : *« un rapport dont les **totaux déclarés** contredisent les **lignes comptées** est **refusé** »*. **NON IMPLÉMENTÉ** : le script ne lit **jamais** `LF:`/`LH:`. Mesuré — un `lcov` portant `LF:100 / LH:1` avec **19 `DA:` réelles** → `89.5% (17/19)`, **exit 0, VERT** | **NON BLOQUANT.** Impact réel **faible** : les `DA:` **sont** la donnée de base, la plus fiable ; ignorer un en-tête récapitulatif falsifiable est **défendable**. Mais **l'AC est écrit et n'est pas tenu** → **@CodeReviewer / @QA_Tester** (conformité AC), ou requalifier l'AC |
| **N-3** | exécution (T-C, T-D) | `scripts/check_flutter_coverage.py:72` | **LOW-MED** | Une ligne `DA:` malformée provoque un **`ValueError` non rattrapé** avec *traceback* : `DA:5` → `invalid literal for int() with base 10: ''` · `DA:5,PWNED` → `… : 'PWNED'`. Or le pattern imposé par l'US dit ⛔ *« ni plantage, ni vert silencieux »* et **nomme le cas `lcov`** | **NON BLOQUANT — il échoue en FERMETURE** *(exit 1 = rouge, jamais de faux vert)*. Mais sur un gate **REQUIS**, un *traceback* est un **verrouillage au message inutilisable**. Remède : `try/except` autour de `int(hits)`, message explicite nommant la ligne fautive. → **US-00.8** |
| **N-4** | exécution (§5.5) | `docs/stories/US-00.6-*.md` (AC-3 « Erreur », R-2) · `tests/fixtures/US-00.6/README.md` · `scripts/check_flutter_coverage.py:28-30` | **MEDIUM** *(documentaire)* | L'affirmation **« une troncature du `lcov` AUGMENTE le pourcentage »**, présentée comme **vérifiée** en 4 endroits, est **FAUSSE** — mesurée sur le rapport **réel** et sur les fixtures : la suite `covered(n)/n` est **strictement croissante**, donc **toute troncature DIMINUE** le pourcentage. Le raisonnement est un **non-sequitur** : « non couvertes **en tête** » implique l'**inverse** | **NON BLOQUANT** — le sens de l'erreur va **vers la sûreté** *(un `lcov` tronqué échoue en fermeture)* et le refus du cas « 0 ligne » **reste légitime par lui-même**. Mais **une justification « vérifiée » et falsifiée par la 1ʳᵉ exécution** est le défaut même qu'US-00.5 a payé six fois → **à RECTIFIER par un additif DATÉ** *(« on DATE, on ne REPEINT pas »)*, non à effacer. → **@CodeReviewer / @Architect** |
| **N-5** | `gh api` | `.github/workflows/ci.yml:67-69` | **LOW** | Le job `governance` — qui accueille le nouveau step — **ne déclare aucun bloc `permissions:`**, contrairement à `secrets-scan` (l. 56-58). ✅ Fait atténuant **mesuré** : le défaut du dépôt est **`read`** (`can_approve_pull_request_reviews: false`) ⇒ jeton **en lecture seule** | **NON BLOQUANT** — droits **effectivement minimaux**. Mais ils dépendent d'un **réglage de dépôt** modifiable **sans toucher au code et sans aucune détection** *(même classe que la dette « aucune détection de dérive »)*. Remède : `permissions: contents: read` explicite. → **US-00.8** |
| **N-6** | `grep` + config | `scripts/selftest_coverage_ratchet.py:39-40` · `factory.config.json` (`gates.test.cmd`) | **LOW** | AC-2 exige ⛔ *« aucun artefact exécuté ne porte le seuil en dur : ni la commande du gate, ni une valeur par défaut de script, ni un workflow »*, et §7 annonce *« occurrences dans les artefacts exécutés : **2 → 1** »*. Mesuré : `REF_MUTANT = 89.4` et `PLANCHER = 80.0` **en dur** dans le `selftest` *(qui **est** un artefact exécuté, dans un job **requis**)*, et la commande du gate porte **toujours** `--min 80` | **NON BLOQUANT** *(impact sécurité ~nul : le `selftest` fabrique sa **propre** configuration temporaire, donc un abaissement de la référence réelle ne le fait **pas** rougir — vérifié)*. Mais la propriété « source unique » **revendiquée** n'est pas atteinte et le décompte « 2 → 1 » n'est **pas livré**. → **@CodeReviewer / @QA_Tester** |
| **N-7** | revue + `gh api` | `.github/workflows/ci.yml` · `.claude/hooks/protect_files.sh:28` | **LOW** | **Dette PRÉEXISTANTE déjà nommée** *(« périmètre Art. 6 déclaré ≠ appliqué »)* dont cette US **augmente la valeur** : `.github/workflows/*` n'est protégé **ni** par `protect_files.sh` **ni** par la Constitution, et il porte désormais **un contrôle bloquant de plus**. Une PR *(y compris de fork — sur `pull_request`, le workflow exécuté vient de la réf de fusion)* peut **supprimer le step d'autotest** et rendre son propre `📋 Governance` **vert**. Elle ne peut **pas** changer les **contextes requis** *(état serveur)* ni fusionner seule | **NON BLOQUANT** — la barrière résiduelle est la **revue humaine**. ⚠️ **NON TESTÉ ici** *(je n'ai ouvert aucune PR de fork ; la sémantique « workflow depuis la réf de fusion » est **affirmée d'après la documentation GitHub, non vérifiée sur ce dépôt**)*. → **US-00.8** |
| **N-8** | `grep` + config | *(absence)* | **MEDIUM** | ⛔ **Le livrable de cette US — 307 lignes de Python — n'est couvert par AUCUNE analyse statique.** `app.format` et `app.analyze` ne portent que sur **Dart** (`lib test`). Recherche de `ruff\|flake8\|bandit\|pylint\|mypy\|semgrep\|pip-audit\|safety` dans `.github/workflows/`, `factory.config.json` et `scripts/run_gates.py` → **0 occurrence**. C'est ce vide qui a laissé passer **N-1** *(ligne de blancs, `W293`)* | **NON BLOQUANT** *(dette structurelle, déjà nommée, hors périmètre déclaré de l'US)*. Mais elle est désormais **chiffrable** : la factory ajoute du Python **dans des contextes requis** à chaque US et **n'en lint aucune ligne**. → **US-00.8**, avec le SAST |
| **N-9** | `git log` | commit `f585e82` | **INFO** | Les **deux** éditions « humaines » (T7, T8) sont dans le **MÊME commit** que du code produit par agent — `f585e82 | gitgdx <guillaume.decroix@free.Fr> | fix(us-00.6): le mutant a trouve un bug de production + les 2 editions humaines` | **CONSTAT, pas un reproche.** Sur ce dépôt à **un seul compte**, la provenance humaine de ces deux éditions **n'est PAS prouvable par la machine** *(dette établie par US-00.7)*. Je l'enregistre comme **déclaratif**, jamais comme vérifié. Recommandation *(process)* : **isoler les éditions de fichiers protégés dans leur propre commit** — cela ne prouve rien de plus, mais rend le diff **auditable d'un coup d'œil** |
| **N-10** | exécution | `scripts/factory_sync.py` | **INFO** | `python scripts/factory_sync.py --help` **plante** (`UnicodeEncodeError`, emojis des libellés sous `cp1252`). **Vérifié PRÉEXISTANT** : `exit=1` **identique** sur `main` et sur `HEAD` ⇒ **non introduit par US-00.6**. C'est **la même classe de bug** que celle trouvée par le mutant — et la garde `reconfigure(errors="replace")` ajoutée aux deux scripts de l'US **n'existe pas** dans `factory_sync.py` | **NON BLOQUANT, HORS PÉRIMÈTRE** *(fichier protégé)*. Mais la leçon du livrable *(« un gate ne doit jamais dépendre de l'encodage de la console »)* **n'est pas appliquée au script le plus sensible du dépôt**. → **US-00.8** |

---

## 7. ⛔ Bornes de cet audit — ce sur quoi mon `PASS` ne s'appuie PAS

1. ⛔ **AUCUN SAST n'existe dans cette factory.** `run_gates --gate sast` → **exit 1, ce gate n'existe
   pas** *(§1.1)*. **Aucun finding SAST n'a été produit, donc aucun n'a été exclu.** Mon `PASS` s'appuie
   sur une **revue manuelle** + `gitleaks` + `actionlint`, **jamais** sur un SAST.
2. ⛔ **AUCUN SCANNER DE CVE n'existe.** `deps_audit` = `dart pub outdated` = **obsolescence**, pas
   **vulnérabilité** — et il est **`blocking: false`**. **Aucun verdict de sécurité sur les dépendances
   n'est possible sur ce dépôt**, et l'Art. 4 le dit désormais. *(Circonstance atténuante **factuelle** :
   cette US **n'ajoute aucune dépendance** — surface inchangée.)*
3. ⛔ **Le code applicatif Dart n'est couvert par aucun SAST**, et **le Python non plus** *(N-8)* — or
   **c'est le Python qui est le livrable ici**. Le seul outil statique qui a tourné sur ce diff est
   `actionlint`, et il ne lit **que les workflows**.
4. ⚠️ **`gitleaks` a scanné l'arbre de travail et les 2 commits `309202a..f585e82`** — **PAS l'historique
   complet** du dépôt. Le dépôt étant **public**, une fuite antérieure resterait hors de ce périmètre.
5. ⚠️ **Mon `actionlint` local est PLUS FAIBLE que celui de la CI** : `shellcheck` et `pyflakes` ont été
   **désactivés** (binaires absents). `shellcheck` **est** présent sur `ubuntu-latest`. Et je n'ai **pas**
   revérifié l'empreinte du tarball **Linux** épinglée dans `ci.yml` (j'ai utilisé l'archive Windows).
6. ⚠️ **Je n'ai exécuté AUCUNE écriture** : aucun `PUT`/`PATCH`/`POST`, aucun `git push`, aucun `--admin`.
   L'état de la protection de `main` est **lu**, jamais touché. Aucun fichier du dépôt n'a été modifié
   par moi *(hors ce rapport et la trace)* ; mes fichiers de test vivent dans le **scratchpad**.
7. ⚠️ **NON TESTÉ, et je ne l'affirme pas** : le comportement d'une **PR de fork** *(N-7)* — la sémantique
   « le workflow exécuté vient de la réf de fusion » est **affirmée d'après la documentation GitHub**, pas
   vérifiée ici · le comportement sous un **autre acteur**, un **jeton d'application** ou l'**interface
   web** · la **persistance** de l'état de protection au-delà de la lecture ci-dessous.
8. ⚠️ **La garde d'encodage est un FILET, pas une élimination structurelle.** `reconfigure()` est dans un
   `try/except … pass` : si elle échouait, le chemin **HAUSSE** ferait encore de l'**I/O après que le
   verdict est décidé**, et une erreur d'écriture y transformerait un **vert en rouge** sur un gate
   **requis**. Mesuré : la garde **tient sous `cp1252` ET `ascii`** *(§5.2)* — je constate qu'elle marche,
   je ne conclus pas qu'elle est infaillible.
9. ⚠️ **La provenance humaine des deux éditions de fichiers protégés N'EST PAS PROUVÉE** *(N-9)* — elle
   est **déclarative**, comme toute provenance sur ce dépôt à un seul compte.

### ✅ Contrôle de non-dérive de l'enforcement — **lecture seule**, exécuté ce jour

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{protected:.protected}'
{"protected":true}

$ gh api repos/gitgdx/Concentration/branches/main/protection
{"approvals":0,"contexts":["🔐 Secrets scan (gitleaks)","📋 Governance (SCB + traçabilité + synchro)",
 "check-branch-name","📱 App (gates run_gates.py)"],"conv":true,"deletions":false,
 "enforce_admins":true,"force_push":false,"strict":true}

$ gh api repos/gitgdx/Concentration --jq '{visibility:.visibility,private:.private}'
{"private":false,"visibility":"public"}

$ python scripts/factory_sync.py --check-remote
Lecture SEULE de l'API GitHub (GET uniquement) — GET …/branches/main → 200 · GET …/protection → 200
Comparaison champ par champ — 12 champ(s) alignés, 0 écart(s), 7 champ(s) additionnel(s) neutre(s),
                              0 champ(s) ACTIF(S) non couvert(s).
Protection de gitgdx/Concentration:main — conforme à la cible générée par --emit-branch-protection.
exit=0
```

✅ **`main` EST toujours protégée**, `enforce_admins` **en vigueur**, **4 contextes requis**, **0 dérive**
sur 12 champs — et la cible générée par le code de **HEAD** est **conforme à l'état serveur réel**.
⚠️ Ce contrôle est **manuel et hors CI** *(droits admin absents du `GITHUB_TOKEN`)* : **la dette « aucune
détection automatique de dérive » demeure entière** — cet audit **l'exerce une fois**, il ne la ferme pas.

---

## 8. Verdict

> ## ✅ **PASSED**
>
> **0 finding BLOQUANT.** Aucun secret *(gitleaks ×2, config du détecteur non modifiée)*. Aucune
> injection dans le step CI ajouté à un job requis *(0 interpolation ; `actionlint` 0 erreur)*. La cible
> de protection de branche est **prouvée inchangée** *(`emit_branch_protection` octet-identique par AST +
> entrées isolées + sortie conforme à l'état serveur)*. Le diff appliqué sur les **deux fichiers
> protégés** est **fonctionnellement identique** au diff proposé *(28/28 lignes exécutables)*. Les
> **7 chemins d'erreur** du cliquet sont **explicites, sans aucun faux vert**. Aucune dépendance ajoutée.
> `main` est **toujours protégée, sans dérive**.
>
> **10 findings NON BLOQUANTS**, dont **4 MEDIUM** : **N-1** *(la copie humaine a injecté une ligne de
> blancs et un commentaire mal indenté dans le script le plus sensible du dépôt — sans effet
> fonctionnel)* · **N-2** *(un AC écrit — refuser un `lcov` aux totaux contradictoires — n'est pas
> implémenté)* · **N-4** *(une justification présentée comme « vérifiée » est FAUSSE : une troncature
> **DIMINUE** le pourcentage, elle ne l'augmente pas — l'erreur va vers la sûreté)* · **N-8** *(les
> 307 lignes de Python livrées ne sont couvertes par AUCUNE analyse statique)*.
>
> ⛔ **Ce `PASS` ne s'appuie ni sur un SAST ni sur un scan de CVE : aucun des deux n'existe.** Les
> **9 bornes** du §7 en font partie intégrante et ne doivent pas être détachées de ce verdict.

---

### Annexe — inventaire des exécutions de cet audit

`run_gates --gate sast` · `run_gates --gate deps_audit` · `run_gates --all` · `run_gates --gate test` ·
`gitleaks detect --no-git` · `gitleaks detect --log-opts 309202a..f585e82` · `actionlint` ×1 (3 workflows) ·
`factory_sync --check` · `factory_sync --check-remote` · `factory_sync --emit-branch-protection` ·
`selftest_coverage_ratchet` · `validate_trace --all` · `check_scb_compliance` · comparaison AST
main↔HEAD (9 fonctions) · comparaison mécanique diff proposé↔appliqué · `compile()` ·
`check_flutter_coverage` ×7 mutations de configuration · ×4 mutations de `lcov` (troncature, totaux
faux, `DA:` malformée ×2) · ×6 exécutions sous `cp1252`/`ascii`/`utf-8` · analyse AST des littéraux de
`print`/`raise` ×2 fichiers · `git check-ignore` · `gh api` ×4 (branche, protection, dépôt, permissions
de workflow) · `git log` de provenance · `grep` de seuils en dur · `grep` de linters/SAST.
