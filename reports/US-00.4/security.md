# 🔐 Audit sécurité — US-00.4 (Enforcement `main` : constat + outillage, cible armée)

| Champ | Valeur |
|---|---|
| **Agent** | @CyberSecurity — **contexte frais** (Constitution Art. 2 : n'a pas produit ce code) |
| **Modèle** | `claude-opus-5[1m]` |
| **Date** | 2026-07-26 |
| **Branche auditée** | `feat/US-00.4-ci-protection-branche` @ `da6d7d0` |
| **Base** | `main` @ `801a046` (inchangée en fin d'audit — vérifié) |
| **Périmètre** | `git diff main...HEAD` — 36 fichiers, +4123/-54. Livrable de code unique : `scripts/check_branch_protection.py` (818 l.) |
| **VERDICT** | ✅ **PASS** — aucun finding bloquant. 3 MEDIUM + 4 LOW non bloquants, dont 2 dettes de factory préexistantes. |

> **Cadrage assumé.** Cette US porte sur l'**honnêteté des affirmations d'enforcement**, dans un
> contexte où `main` n'est **pas** protégée et **ne peut pas** l'être (403 de plan, dérogation humaine
> tracée `EVT_WAIVER_GRANTED`). Le **risque #2 d'EPIC_00 reste OUVERT** — c'est **tracé et assumé**,
> pas un défaut découvert ici. L'audit a donc porté sur la **posture réelle** et sur la recherche
> d'une **survente résiduelle**, en attaquant les mitigations plutôt qu'en les relisant.

---

## 1. Sorties d'outils (brutes)

### 1.1 `python scripts/run_gates.py --gate sast` — ⚠️ GATE INEXISTANT

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
```

```
$ python scripts/run_gates.py --list
  app.format       [bloquant]      (.) $ dart format --output=none --set-exit-if-changed lib test
  app.analyze      [bloquant]      (.) $ flutter analyze
  app.test         [bloquant]      (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
  app.deps_audit   [non bloquant]  (.) $ dart pub outdated --show-all
  app.build        [bloquant]      (.) $ flutter build web --release

$ grep -rniE "\bsast\b|semgrep|bandit|codeql|snyk|trivy|osv-scanner|dart pub audit" \
      factory.config.json .github/workflows/ scripts/run_gates.py
AUCUN outil SAST / scanner de CVE configure dans la factory
```

**Dit franchement** : le gate `sast` **n'existe pas** dans cette factory — je ne peux donc pas
produire de sortie SAST outillée. Aucun SAST n'est masqué : il n'y en a **aucun**. → finding **M3**.
Le SAST a été remplacé par une **revue manuelle ciblée + tests d'attaque** (§3), dont les sorties sont
collées.

### 1.2 `python scripts/run_gates.py --gate deps_audit` — ✅ PASS (non bloquant)

```
$ python scripts/run_gates.py --gate deps_audit
direct dependencies:
cupertino_icons               1.0.9     1.0.9       1.0.9       1.0.9
flutter                       (sdk)     (sdk)       (sdk)       (sdk)

dev_dependencies:
flutter_lints                 6.0.0     6.0.0       6.0.0       6.0.0
flutter_test                  (sdk)     (sdk)       (sdk)       (sdk)
[… 24 dépendances transitives, toutes à la version résolvable la plus récente …]
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).
```

**Dépendances directes** : `cupertino_icons 1.0.9`, `flutter` (SDK) ; dev : `flutter_lints 6.0.0`.
**Aucune CVE HIGH/CRITICAL connue**, tout est à la dernière version résolvable.
**Zéro dépendance ajoutée par cette US** (§3.3).

⚠️ **Réserve méthodologique explicite (non un PASS de complaisance)** : `dart pub outdated` compare
des **versions**, il ne consulte **aucune base de vulnérabilités**. Ce gate est de plus déclaré
`"blocking": false`. L'absence de CVE HIGH/CRITICAL ci-dessus est donc **inférée** de la fraîcheur des
versions et de la trivialité de la surface (2 dépendances directes, dont une purement iconographique),
**pas prouvée par un scanner**. → finding **M3**.

### 1.3 `gitleaks` — ✅ 0 LEAK — **la réserve du @Developer est LEVÉE**

`gitleaks` était absent du `PATH` ; je l'ai **retrouvé** hors `PATH` (posé par `winget` pour US-00.1)
et exécuté réellement, sur le **working tree** *et* sur l'**historique complet**.

```
$ ls "$LOCALAPPDATA/Microsoft/WinGet/Packages/"Gitleaks*
C:\Users\guillaume.decroix\AppData\Local\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_Microsoft.Winget.Source_8wekyb3d8bbwe\gitleaks.exe
$ gitleaks.exe version
8.30.1
```

**Scan 1 — working tree :**
```
$ gitleaks.exe detect --no-git --source . --config .gitleaks.toml --redact -v
9:54PM INF scanned ~89822454 bytes (89.82 MB) in 4.11s
9:54PM INF no leaks found
EXIT=0
```

**Scan 2 — historique git complet :**
```
$ gitleaks.exe detect --source . --config .gitleaks.toml --redact -v
9:55PM INF 30 commits scanned.
9:55PM INF scanned ~1023075 bytes (1.02 MB) in 1.31s
9:55PM INF no leaks found
EXIT=0
```

**Contrôle anti-suppression** : `.gitleaks.toml` hérite des règles par défaut (`useDefault = true`) ;
son allowlist ne couvre que `.env*`, `.mcp.json`, `.claude/settings.local.json` et
`reports/US-00.1/gitleaks.toml.proposed`. **Aucun fichier d'US-00.4 n'est allowlisté** → le vert
ci-dessus est **significatif**, pas obtenu par exclusion.

> ✅ La réserve écrite par @Developer dans `reports/US-00.4/non_regression.md` §Réserve gitleaks
> (« l'absence de secret est *vraisemblable, pas prouvée par l'outil de référence* ») est **levée par
> cet audit** : elle est désormais **prouvée par l'outil de référence**, sur l'historique en plus du
> working tree. La déclaration honnête de cette lacune par @Developer est notée comme **positive**.

---

## 2. Axe 1 — Fuite de secrets dans les preuves brutes (enjeu principal)

Trois barrières indépendantes, toutes vertes.

**(a) gitleaks** — §1.3 : 0 leak, worktree + historique.

**(b) Grep exhaustif des motifs imposés** sur `reports/` et `tests/fixtures/` :
```
$ grep -rniE "gh[pousr]_[A-Za-z0-9]{6,}|github_pat_|AIza[0-9A-Za-z_-]{10,}|AQ\.[A-Za-z0-9_-]{10,}" \
       reports/ tests/fixtures/
reports/US-00.4/non_regression.md:125  → l'EXPRESSION du grep de @Developer (pas un secret)
reports/US-00.4/non_regression.md:139  → la liste des motifs cherchés (pas un secret)
```
Seules 2 occurrences, **toutes deux des motifs de recherche**, aucun secret. Idem sur le diff complet :
les 6 occurrences (`Story File`, `check_branch_protection.py:95`) sont des **expressions régulières** ou
de la **documentation de rédaction**.

**(c) En-têtes d'autorisation** — aucune valeur réelle. Les 6 occurrences d'`Authorization` dans
`reports/US-00.4/` sont soit la mention « *aucun en-tête Authorization, aucun jeton* », soit le
**placeholder** `Authorization: Bearer <JETON NON ARCHIVÉ>`.

**(d) Preuve empirique que le jeton ne peut PAS fuir dans `--raw-out`** — test exécuté avec un jeton
**factice** forçant le transport `urllib` (`gh` absent du `PATH` de cette session) :
```
$ GH_TOKEN='ghp_ZZZZ…(factice)' python scripts/check_branch_protection.py --raw-out <scratchpad>/raw.txt
Lecture SEULE de l'API GitHub (GET uniquement) — gitgdx/Concentration:main · … → 401 · … → 401
  Réponses brutes archivées (sans jeton ni Authorization) : …\raw.txt
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Code HTTP : 401 — NON AUTHENTIFIÉ (jeton absent, expiré ou invalide) — ce n'est ni un défaut de
  plan, ni une branche non protégée. Message API : 'Bad credentials'
EXIT=2

$ grep -c 'ghp_ZZZZ' <scratchpad>/raw.txt
0                                  ← le jeton n'est JAMAIS écrit
$ grep -n Authorization <scratchpad>/raw.txt
# Commande exacte : GET https://api.github.com/… (urllib.request ; Accept: application/vnd.github+json ;
                     Authorization: Bearer <JETON NON ARCHIVÉ>)
```
✅ **`--raw-out` écrit les corps de réponse SANS en-tête d'autorisation**, comme exigé. Le
`ApiResult.command` du transport `urllib` est construit d'emblée avec le placeholder
(`check_branch_protection.py:299-303`) — le jeton n'entre jamais dans la chaîne archivée. Deuxième
filet : `_redact()` (`:174-175`, `:526-534`).

**Verdict axe 1 : ✅ aucune fuite. Aucun finding.**

---

## 3. Axe 3 — Surface d'attaque de `scripts/check_branch_protection.py`

### 3.1 Lecture seule — ✅ CONFIRMÉ

```
$ grep -nE "\-X|--method|PUT|POST|PATCH|DELETE|\.put\(|\.post\(" scripts/check_branch_protection.py
14, 16, 17, 74, 83, 100, 346, 385, 405, 411, 494   ← 11 occurrences
```
**Les 11 occurrences sont des docstrings/commentaires** décrivant le mapping `PUT → GET` ou
l'interdiction elle-même. **Aucun appel** : aucun `-X`, aucun `--method`, aucun `.put()/.post()`.
Les deux seuls transports sont `subprocess.run([gh_bin, "api", path])` (`:261-263`, GET par défaut,
**aucun drapeau de méthode**) et `urllib.request.Request(..., method="GET")` (`:304-313`).
Le seul écrivain distant reste `scripts/apply_branch_protection.sh`, **non exécuté** par cette US.

### 3.2 Injection de commande — ✅ NON EXPLOITABLE

| Attaque | Commande | Résultat |
|---|---|---|
| Métacaractères shell | `--repo 'a/b; echo INJECTED > /tmp/pwned.txt'` | exit 2, **`/tmp/pwned.txt` non créé** |
| Injection de drapeau | `--repo '--method=PUT'` | rejeté par `argparse` (usage), exit 2 |
| Chemin vide | `--repo '/evil'` | rejeté par la validation `all(candidate.split("/"))` |

```
$ python scripts/check_branch_protection.py --repo 'a/b; echo INJECTED > /tmp/pwned.txt'
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Cause : `gh` introuvable dans le PATH ET aucun jeton GH_TOKEN/GITHUB_TOKEN : …
EXIT=2
$ ls /tmp/pwned.txt   →  OK : aucune injection
```

**Analyse défensive** : tous les `subprocess` sont en **forme liste, sans `shell=True`**
(`:195-197`, `:223-225`, `:261-263`) → aucune interprétation shell. `resolve_repo()` (`:216-235`)
impose `count("/") == 1` et des segments non vides ; le chemin API est **toujours** préfixé
`repos/…` (`:762`) → une valeur `--repo` ne peut **jamais** être lue par `gh` comme un drapeau
(elle n'est jamais en tête d'argument). Le seul `flag` passé à `factory_sync.py` est un **littéral**
du code source.

### 3.3 Zéro dépendance ajoutée — ✅ CONFIRMÉ

```
$ grep -nE "^(import|from) " scripts/check_branch_protection.py
argparse · json · os · re · shutil · subprocess · sys · urllib.error · urllib.request
dataclasses · datetime · pathlib          ← 100 % stdlib
import factory_config                     ← module LOCAL : scripts/factory_config.py (existant)

$ git diff main...HEAD --name-only | grep -iE "requirements|pyproject|Pipfile|setup.py|poetry"
AUCUN fichier de dependance Python touche
```

### 3.4 Findings de l'axe 3

**L1 — Asymétrie de rédaction : `stdout` n'est pas rédigé alors que l'archive l'est.** *(LOW, non bloquant)*
`_get_via_gh()` construit `transport_error` à partir du **stderr brut de `gh`** sans passer par
`_redact()` (`check_branch_protection.py:288-291`) ; `write_raw()` **rédige** cette chaîne (`:533`),
mais `_impossible()` l'imprime **telle quelle sur stdout** (`:549`). Exploitation étroite (il faut que
`gh` échoue *sans statut HTTP exploitable* **et** que son stderr contienne un jeton — cas connu :
`GH_DEBUG=api`, qui dump les en-têtes de requête). Impact réel faible, mais c'est une asymétrie de
défense en profondeur dans le seul module qui manipule un jeton.
→ *Recommandation* : appliquer `_redact()` dans `Reporter.line()` (une ligne, couvre tous les chemins).

**L2 — `--raw-out` est une primitive d'écriture de fichier à chemin arbitraire.** *(LOW, non bloquant)*
`write_raw()` accepte un chemin **absolu** et crée les répertoires parents (`:511-514`). Elle est
atteignable via l'outil Bash, que `.claude/hooks/protect_files.sh` **n'intercepte pas** (ce hook ne
filtre que `tool_input.file_path` des outils `Edit|Write`). Un agent pourrait donc écraser un fichier
d'enforcement (`--raw-out scripts/factory_sync.py`) en contournant le hook. **Impact limité au
clobber/DoS, non à la subversion** : le contenu écrit est un en-tête de commentaires + un corps de
réponse GitHub, non contrôlable en Python valide, et l'écrasement est immédiatement visible en
`git diff`. Classe de défaut **générique** à tout script portant un drapeau de sortie ; pas introduite
par cette US en tant que faiblesse conceptuelle.
→ *Recommandation* : borner `--raw-out` à `reports/` (et/ou étendre `protect_files.sh` aux commandes Bash).

**L4 — `--from-*` : oracle de lecture de fichier limité.** *(LOW, non bloquant)*
`_load_fixture()` (`:570-586`) lit tout chemin, y compris absolu. Un JSON arbitraire verra ses champs
**mappés** réémis sur stdout. Aucun franchissement de frontière de confiance (CLI locale, exécutée par
l'utilisateur avec ses propres droits) ; un fichier non-JSON produit une `UsageError` qui **n'expose
que le chemin, pas le contenu** (`:579`). Mentionné pour exhaustivité.

---

## 4. Axe 4 — Le mode fixture est-il un vecteur de tromperie ? (mitigation R1)

Attaqué, pas relu. **Les quatre garde-fous tiennent.**

**(a) Le préfixe `[SIMULATION] ` est sur 100 % des lignes :**
```
$ python scripts/check_branch_protection.py \
    --from-protection tests/fixtures/US-00.4/protection_conforme.json \
    --from-branch tests/fixtures/US-00.4/branch_protected_true.json > sim0.txt
EXIT=0
$ grep -vn "^\[SIMULATION\] " sim0.txt   →  AUCUNE ligne sans préfixe
$ wc -l sim0.txt ; grep -c "^\[SIMULATION\] " sim0.txt
17 / 17                                   ← 17 lignes, 17 préfixées
$ tail -1 sim0.txt
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
```
Le chemin exit 0 simulé **n'imprime jamais** le message réel : la bascule est
`if rep.prefix:` (`:639-645`), liée au même état que le préfixe — impossible de dissocier les deux.

**(b) Attaque par injection de saut de ligne (forger une ligne NON préfixée) — ÉCHOUE :**
fixture forgée dont un `context` contient `\n` + le message de succès réel, mot pour mot.
```
$ python scripts/check_branch_protection.py --from-protection <evil>.json --from-branch <evil>.json
EXIT=1
$ grep -vn "^\[SIMULATION\] " evil_out.txt   →  AUCUNE — injection de ligne ECHOUE
[SIMULATION]   required_status_checks.contexts (EN TROP) | <absent de la cible générée> |
  "\u0000X\nProtection de gitgdx/Concentration:main — conforme à la cible générée par …"
```
`_j()` passe par `json.dumps` (`:178-185`) → le saut de ligne est **échappé en `\n` littéral** : le
texte forgé reste **sur une seule ligne préfixée**, et l'issue est **exit 1 (dérive)**, pas exit 0.

**(c) `--raw-out` **refusé** en mode fixture — et aucun fichier créé :**
```
$ … --from-protection … --from-branch … --raw-out /tmp/FORGE.txt
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Cause : ERREUR D'USAGE — --raw-out est refusé en mode fixture : archiver une réponse
  SIMULÉE comme une réponse brute de l'API la rendrait relisible comme une preuve d'état réel (R1)
EXIT=2
$ ls /tmp/FORGE.txt  →  OK : aucun fichier cree
```

**(d) Drapeaux non appairés et `--repo` → exit 2** (sorties intégrales exécutées, conformes au contrat).

**(e) Le mode fixture est INATTEIGNABLE depuis le gate** : `main_from_sync()` appelle `run(Options())`
(`:785-788`) — tous les champs `from_*` à `None`. Aucun chemin ne permet à
`factory_sync.py --check-remote` de consommer une fixture. Contrôle négatif CI :
```
$ grep -rn "check-remote\|check_branch_protection" .github/workflows/
OK : AUCUNE reference en CI (hors CI par construction)
```

**Verdict axe 4 : mitigation R1 ✅ solide.** Un unique résidu honnête :

**L3 — Le code de sortie ne porte aucun marqueur de simulation.** *(LOW, non bloquant)*
Une exécution sur fixture conforme renvoie **`0`**, comme une vérification réelle conforme. Tout
consommateur qui ne teste que `$?` (et non stdout) ne peut pas les distinguer. Non atteignable depuis
le gate (point e), et la sortie textuelle est inviolable (points a/b) — mais un futur script qui
appellerait ce module par son exit code seul recréerait le risque R1.
→ *Recommandation* : réserver un code de sortie distinct au mode fixture, ou documenter que l'exit
code seul n'est jamais une preuve.

⚠️ **Limite indépassable, à nommer** : aucun contrôle *dans* l'outil ne peut empêcher un humain ou un
agent d'**éditer après coup** un `.txt` archivé pour en retirer le préfixe. La mitigation R1 protège
l'**émission**, pas l'**archive** — la seule barrière restante est la revue de diff. Ce n'est pas un
défaut de l'US, c'est la frontière réelle de sa promesse ; elle mérite d'être dite ainsi.

---

## 5. Axe 2 — Bloc PGP + e-mail dans `branch_main_before.json` : TRANCHÉ

**Décision : ✅ ACCEPTABLE EN L'ÉTAT — ne PAS expurger.** @Developer a raison, et la démonstration est
matérielle, pas argumentaire.

**Preuve — la signature archivée est déjà, à l'octet près, dans l'objet git de tout clone :**
```
$ git cat-file -p 801a046 | head -8
tree b673ec58076a3339c51fb9f7f66be9ada28aa0da
parent 3490926b82242e60234771dd1b08e2379c3a04a6
parent dd5b9155e0a2ec29f2abbbf7f49f2c520212e5fa
author gitgdx <guillaume.decroix@free.Fr> 1785074843 +0200
committer GitHub <noreply@github.com> 1785074843 +0200
gpgsig -----BEGIN PGP SIGNATURE-----

 wsFcBAABCAAQBQJqZhSbCRC1aQ7uu5UhlAAAe8EQAASMj/mrLO6b6SkWDT4nuAhf   ← identique à l'archive
```
```
$ git log --format='%H %ae %ce' -3 801a046
801a046… guillaume.decroix@free.Fr noreply@github.com
dd5b915… guillaume.decroix@free.Fr guillaume.decroix@free.Fr
3490926… guillaume.decroix@free.Fr noreply@github.com
```

**Raisonnement :**
1. **Ce n'est pas une clé, c'est une signature.** Une signature PGP est un artefact de **vérification**,
   conçu pour être **public** ; elle ne permet aucune récupération de clé privée. La règle gitleaks par
   défaut cible `BEGIN … PRIVATE KEY` — l'absence de détection (§1.3) n'est pas un trou de couverture,
   c'est la bonne classification.
2. **Exposition incrémentale = zéro.** Le bloc `gpgsig` (signature `web-flow` de GitHub sur le commit
   de fusion) et l'e-mail auteur sont **déjà** dans les objets git de **chaque clone** et de chaque
   `git log`. Expurger le fichier de preuve ne retirerait **rien** de l'exposition réelle : ce serait
   du **théâtre de sécurité**, au prix de la **disqualification d'une preuve brute** — précisément ce
   que l'AC-1 interdit.
3. **L'e-mail** `guillaume.decroix@free.Fr` est l'e-mail d'auteur de **tous** les commits de
   l'historique : sa divulgation est un choix de configuration git, **antérieur et extérieur** à cette
   US. Le seul scénario d'aggravation est le **passage du dépôt en public** — et il se ferait via
   l'historique lui-même, pas via ce fichier. AC-5 (a) nomme déjà l'irréversibilité de cette voie.
4. **Signalé plutôt que masqué** : @Developer a documenté ce contenu de sa propre initiative dans
   `non_regression.md`. C'est le comportement attendu.

**Aucun finding.** *(Recommandation optionnelle, hors US : si l'anonymat de l'e-mail devient un
besoin, il se traite au niveau `git config user.email` / `noreply` GitHub pour les commits futurs —
jamais par expurgation de preuves.)*

---

## 6. Axe 5 — Posture réelle de `main`, sans complaisance

### 6.1 Le constat est exact — reproduit indépendamment (lecture seule)

```
$ gh api repos/gitgdx/Concentration/branches/main --jq '{name,protected}'
{"name":"main","protected":false}

$ gh api repos/gitgdx/Concentration/branches/main/protection
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"…/branches/branch-protection#get-branch-protection","status":"403"}

$ gh api repos/gitgdx/Concentration/rulesets
{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.",
 "documentation_url":"…/repos/rules#get-all-repository-rulesets","status":"403"}

$ gh api repos/gitgdx/Concentration --jq '{private,visibility,permissions}'
{"permissions":{"admin":true,"maintain":true,"pull":true,"push":true,"triage":true},
 "private":true,"visibility":"private"}
```
✅ 403 sur **les deux** mécanismes, message **identique**, avec `admin: true` → l'attribution
« **limite de plan**, ni droits ni configuration » est **exacte**. Ni un 401, ni un 404.

### 6.2 La qualification « filet de discipline » est exacte, et les limites sont nommées

`docs/GIT_PROTECTION.md:65-66` — les limites sont écrites **explicitement**, pas sous-entendues :

> | Hook **local** `pre-push` | Refuse `refs/heads/main` **depuis ce poste** | **Absent d'un clone frais** · contournable **depuis un autre poste ou via l'interface web** · `--no-verify` reste interdit … mais cette interdiction est **elle-même portée par un hook**, donc par la même discipline |
> | CI (`ci.yml`, `branch-naming.yml`) | **Rapporte** 4 status checks | Ces checks ne sont **requis par rien** : une PR peut être fusionnée **avec la CI rouge**. Ils informent, ils ne bloquent pas |

`ADR-006` §« ⛔ Ce que cette décision ne fait PAS — démenti explicite » va plus loin : il **retire
nommément** les quatre affirmations de sa propre version antérieure (« la règle passe de *déclarée* à
**effective** », `"protected": true` prouvé, gates « incontournables », force-push « refusé par le
serveur ») et conclut « **Ces quatre affirmations sont fausses et sont ici démenties.** » L'en-tête de
`GIT_PROTECTION.md` ouvre sur « ⛔ `main` N'EST PAS PROTÉGÉE ». Le lecteur pressé ne peut pas se
tromper.

### 6.3 Survente résiduelle : recherchée activement, **non trouvée**

Sweep **indépendant** (le mien, pas celui du @Developer) sur les 36 fichiers du diff :
```
$ for f in $(git diff main...HEAD --name-only); do
    grep -nHiE "main est protég|branche protégée|protection (est |désormais )?(active|appliquée|en vigueur|effective)|\"protected\": *true" "$f"
  done | grep -viE "n'est pas|pas protég|non protég|NON active|jamais|impossible|ne prétend|…"
```
17 occurrences résiduelles, **toutes légitimes** après lecture individuelle : négations (« l'ont
toutes été **sans protection active** »), **citations démenties** (ADR-006 §démenti), tâches
**reportées** (`T16→T19` marquées ⛔ NON EXÉCUTÉES), ou libellés de fixtures/scénarios.
**Aucune affirmation d'une protection active. Aucun finding.**

### 6.4 Ce qui protège réellement `main` aujourd'hui — mon énoncé

**Rien, au sens de la plateforme.** Un `git push` direct sur `main` **réussirait** depuis n'importe
quel clone où `install_hooks.sh` n'a pas été lancé ; l'interface web GitHub permet un commit direct ;
une PR à CI rouge est fusionnable. Les trois éléments en place (hook local, CI qui rapporte,
discipline de process) sont **réels et utiles**, mais ils reposent tous sur la **même** hypothèse :
que l'opérateur coopère. Contre un opérateur négligent — ou un agent mal cadré — ils **ne tiennent
pas**. La formule de l'US est donc exacte, et je n'y trouve **aucune atténuation abusive** : c'est
l'un des rares corpus que j'aie audités où la documentation est **plus dure** avec elle-même que
l'audit n'aurait eu besoin de l'être. **Risque #2 d'EPIC_00 : OUVERT, correctement tracé.**

---

## 7. Axe 6 — Périmètre déclaré ≠ appliqué (gravité)

**Périmètre DÉCLARÉ** — `docs/governance/CONSTITUTION.md:67-69` : `scripts/githooks/`,
`.claude/settings.json`, `.claude/hooks/`, `.gitleaks.toml`, `factory.config.json`,
`scripts/factory_env.sh`.
**Périmètre APPLIQUÉ** — `.claude/hooks/protect_files.sh` : les mêmes **+** `scripts/install_hooks.sh`,
`scripts/factory_sync.py`, `scripts/run_gates.py`, `*.env*`.

→ L'écart va dans le **sens sûr** (l'appliqué **contient** le déclaré) : **aucune fausse promesse de
protection**. Ni l'un ni l'autre ne couvre `.github/workflows/*`, `scripts/apply_branch_protection.sh`
ni `scripts/check_branch_protection.py` — ces fichiers ne sont donc **pas annoncés** comme protégés.
La transparence est acquise : le Story File le dit (note ¹), et `CLAUDE.md` l'inscrit en dette
(« **Périmètre Art. 6 déclaré ≠ appliqué** … candidat `/audit-methodo` »).

**M2 — Le script qui PRODUIT la preuve d'enforcement n'est pas protégé.** *(MEDIUM, non bloquant)*
`scripts/check_branch_protection.py` est éditable par un agent : transformer un `exit 2` en `exit 0`
(ou neutraliser `SIM_PREFIX`) ne rencontre **aucune barrière machine**. Seuls la revue de PR et
`/audit-us` s'y opposent — c'est-à-dire, encore une fois, **le filet de discipline**, sur l'outil censé
mesurer l'enforcement. **Non bloquant** : déclaré, tracé, et sans aggravation par rapport à l'existant.
→ *Recommandation* : ajouter `scripts/check_branch_protection.py` à `protect_files.sh` **et** à
l'Art. 6 dans US-00.5 (l'outil de mesure doit être au moins aussi protégé que ce qu'il mesure).

**M1 — Toute la barrière anti-secrets repose sur un fichier éditable par un agent.** *(MEDIUM, non bloquant)*
Chaîne complète, vérifiée :
```
$ grep -n -A3 "Scan de secrets" scripts/githooks/pre-commit
50: # ── 4. Scan de secrets (si gitleaks installé — la CI le fait de toute façon) ─
51: if command -v gitleaks >/dev/null 2>&1; then
52:   gitleaks protect --staged --config .gitleaks.toml || fail "secret potentiel détecté…"
$ grep -n "workflows" .claude/hooks/protect_files.sh
NON : .github/workflows/* N'EST PAS dans protect_files.sh
```
1. `pre-commit` ne lance gitleaks que **conditionnellement** → sur la session de @Developer (sans
   gitleaks), il n'a **rien scanné** ;
2. la seule barrière restante est le job CI `🔐 Secrets scan (gitleaks)` ;
3. `.github/workflows/ci.yml` est éditable par un agent (ni Art. 6, ni `protect_files.sh`) ;
4. aucun status check n'est **requis** (§6.1) → une PR neutralisant `ci.yml` reste **fusionnable**.
→ Le dispositif anti-secrets est donc, *in fine*, adossé à la même discipline que le reste. C'est la
**manifestation la plus concrète** du risque #2, et elle dépasse le périmètre d'US-00.4.
→ *Recommandation (US-00.5 ou `/audit-methodo`)* : (i) ajouter `.github/workflows/*` à
`protect_files.sh` et à l'Art. 6 ; (ii) rendre gitleaks **inconditionnel** en pre-commit (échouer si
absent, plutôt que passer en silence).

**M3 — Ni SAST, ni scanner de CVE dans la factory.** *(MEDIUM, non bloquant — dette de factory)*
Cf. §1.1 et §1.2 : le gate `sast` **n'existe pas** ; `deps_audit` est **non bloquant** et
`dart pub outdated` **ne consulte aucune base de vulnérabilités**. La factory ne peut donc, en l'état,
ni produire ni faire respecter le critère bloquant « *finding SAST HIGH / CVE HIGH-CRITICAL* » de ma
propre procédure d'audit. **Sans objet pour US-00.4** (818 lignes de Python en lecture seule, 0
dépendance ajoutée, 0 ligne de Dart), mais **bloquant de fait pour toute US applicative future**.
→ *Recommandation* : instruire un gate `sast` (`bandit` pour les scripts Python de gouvernance,
`flutter analyze` déjà présent pour Dart) et un gate CVE (`osv-scanner`, qui couvre pub.dev et PyPI),
puis rendre `deps_audit` bloquant.

---

## 8. Axe 7 — La cible « armée » est-elle sûre ? ✅ OUI

**Test machine du piège critique** (`required_pull_request_reviews` retiré = « PR obligatoire »
silencieusement désactivée) :
```
$ python scripts/factory_sync.py --emit-branch-protection
{
  "required_status_checks": {"strict": true, "contexts": ["🔐 Secrets scan (gitleaks)",
      "📋 Governance (SCB + traçabilité + synchro)", "check-branch-name", "📱 App (gates run_gates.py)"]},
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "enforce_admins": true, "restrictions": null,
  "allow_force_pushes": false, "allow_deletions": false,
  "required_linear_history": false, "required_conversation_resolution": true
}

$ python -c "…assert…"
required_pull_request_reviews present : True
valeur : {"required_approving_review_count": 0}
enforce_admins : True
VERDICT AXE 7 : OK — PR exigee conservee
```
✅ L'objet est **présent avec `0`**. Structurellement garanti : `emit_branch_protection()`
(`scripts/factory_sync.py:62-69`) construit le dict **inconditionnellement** — aucune branche ne peut
omettre la clé quand le compteur vaut `0`, et le défaut de repli est `1` (`bp.get(…, 1)`), donc
**fail-safe**. Le piège est documenté à `ADR-006:109-112` (« Retirer l'objet désactiverait *Require a
pull request before merging* : `0` approbation **≠** pas de PR exigée … ne jamais *optimiser* son
omission »).

**Posture retenue vs alternatives** — les trois options sont instruites dans `ADR-006:240-256`, et
l'arbitrage est **le bon** :
- `1` + `enforce_admins: true` → **verrouillage total** sur un dépôt mono-contributeur (l'auteur ne
  peut pas s'auto-approuver) : blocage dur, pas rigueur.
- `1` + `enforce_admins: false` → **écarté à juste titre** : l'admin étant le **seul** contributeur, il
  contournerait *tout*, checks requis inclus. L'ADR le formule exactement comme je l'aurais fait :
  « remplacer un trou d'enforcement par un trou d'enforcement **mieux habillé** ». C'eût été une
  protection **décorative** — le pire résultat possible pour cette US.
- `0` + `enforce_admins: true` (retenu) → **non décorative** : PR obligatoire, force-push et
  suppression refusés, conversations à résoudre, checks stricts, **sans exemption admin**. La seule
  chose non couverte est la **revue humaine**, honnêtement requalifiée en obligation de **process**.
- Le 2ᵉ compte relecteur est identifié comme « le plus rigoureux » et **explicitement réexaminable**.

**Réserve conservée** : `0` approbation est un réglage **daté et conditionnel** — il devient une
**anomalie dès un 2ᵉ collaborateur en écriture**. La condition de retour à `1` est portée par le point
de contrôle `/audit-methodo` (AC-6). Correctement instrumenté ; **aucun finding**.

---

## 9. Sécurité applicative classique — SANS OBJET (justifié, pas éludé)

| Vecteur | Statut | Justification technique |
|---|---|---|
| **IDOR** | **N/A** | Aucun serveur, aucun endpoint, aucune ressource multi-titulaires, aucun identifiant fourni par un tiers. `--repo` désigne un dépôt, dont l'accès est arbitré **par GitHub** contre le jeton de l'appelant (prouvé : 401 sur jeton factice, 403 sur ressource hors plan). Il n'existe **aucune** frontière d'autorisation implémentée par ce code, donc aucune à contourner. |
| **Injection SQL/NoSQL** | **N/A** | Aucune base, aucun ORM, aucune requête. Aucun `sqlite`/`http` dans le diff. |
| **Injection de commande** | **Testé, non exploitable** | §3.2 — `subprocess` en forme liste, sans `shell=True`. |
| **XSS** | **N/A** | Aucun rendu HTML/template. Seule sortie : stdout texte d'une CLI locale + fichier `.txt`. 0 ligne de Dart dans le diff. |
| **Authz d'endpoint** | **N/A** | Aucun endpoint exposé. L'authz pertinente est celle du jeton côté GitHub, **non implémentée ici**. |
| **Mots de passe / hachage** | **N/A** | Aucune authentification applicative, aucun mot de passe, aucun stockage d'identifiants. Le jeton vient de l'environnement et n'est **jamais** persisté (§2 d). |
| **CSRF** | **N/A** | Aucun cookie de session, aucun formulaire, aucun flux navigateur. |
| **CORS** | **N/A** | Aucun serveur HTTP. |
| **Validation d'entrée** | **Vérifiée** | `resolve_repo()` valide le format (`:219`) ; `_validate_options()` valide l'appairage des drapeaux (`:589-613`) ; `_guard_mapping()` **refuse de comparer** toute clé non mappée plutôt que de l'ignorer (`:379-407`) — un trou silencieux serait précisément le défaut dénoncé par l'US. |

Cette US est une **US de gouvernance de plateforme** : sa surface de risque est la **véracité de ses
affirmations d'enforcement** et la **non-fuite de ses preuves**, traitées aux §2, §4, §6 et §7 — pas
la sécurité applicative. Le track STANDARD (critère « surface auth/sécurité/admin » écarté comme
*applicatif*) est **cohérent** avec ce constat.

---

## 10. Tableau des findings

`[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

| # | Outil | Fichier:Ligne | Sévérité | Finding | Décision |
|---|---|---|---|---|---|
| M1 | Revue manuelle + grep | `scripts/githooks/pre-commit:51` · `.claude/hooks/protect_files.sh:28` | **MEDIUM** | Barrière anti-secrets adossée à `.github/workflows/ci.yml`, éditable par un agent ; gitleaks conditionnel en pre-commit ; aucun check requis | **NON BLOQUANT** — dette de factory préexistante, déclarée en dette dans `CLAUDE.md`. Renvoyée à US-00.5 / `/audit-methodo` |
| M2 | Revue manuelle | `.claude/hooks/protect_files.sh:28` · `CONSTITUTION.md:67-69` | **MEDIUM** | `scripts/check_branch_protection.py` **produit la preuve** d'enforcement mais n'est protégé ni par l'Art. 6 ni par le hook : `exit 2 → exit 0` sans barrière machine | **NON BLOQUANT** — déclaré explicitement (Story File note ¹, `CLAUDE.md`). Recommandation d'ajout au périmètre |
| M3 | `run_gates.py --gate sast` / `--gate deps_audit` | `factory.config.json` (gates) | **MEDIUM** | Aucun gate SAST ; `deps_audit` non bloquant et sans base de CVE (`dart pub outdated` compare des versions) | **NON BLOQUANT pour US-00.4** (0 dép. ajoutée, 0 Dart) — **à instruire avant toute US applicative** |
| L1 | Revue manuelle | `check_branch_protection.py:288-291` → `:549` | **LOW** | `transport_error` (stderr `gh` brut) imprimé sur stdout **sans** `_redact()`, alors que l'archive le rédige (`:533`) | **NON BLOQUANT** — asymétrie de défense en profondeur. Correctif 1 ligne dans `Reporter.line()` |
| L2 | Revue manuelle | `check_branch_protection.py:511-514` | **LOW** | `--raw-out` = écriture à chemin arbitraire (absolu accepté), atteignable via Bash que `protect_files.sh` n'intercepte pas | **NON BLOQUANT** — clobber/DoS uniquement, contenu non subvertissable, visible en `git diff` |
| L3 | Test d'attaque | `check_branch_protection.py:639-646` | **LOW** | Le mode fixture renvoie **exit 0** sans marqueur : un consommateur ne testant que `$?` ne distingue pas simulé/réel | **NON BLOQUANT** — inatteignable depuis le gate (`main_from_sync()` `:785-788`) ; sortie textuelle prouvée inviolable |
| L4 | Test d'attaque | `check_branch_protection.py:570-586` | **LOW** | `--from-*` accepte tout chemin → oracle de lecture limité aux champs mappés | **NON BLOQUANT** — CLI locale, aucune frontière de confiance franchie |
| — | `gitleaks 8.30.1` ×2 | `reports/US-00.4/`, `tests/fixtures/US-00.4/` | — | **0 leak** (worktree 89.82 MB + 30 commits d'historique) | ✅ **PASS** — réserve du @Developer **levée** |
| — | `git cat-file -p 801a046` | `reports/US-00.4/branch_main_before.json:12` | **INFO** | Bloc PGP + e-mail : **byte-identiques** au `gpgsig`/`author` déjà présents dans l'objet git de tout clone | ✅ **ACCEPTABLE — NE PAS EXPURGER** (exposition incrémentale nulle ; expurger disqualifierait la preuve) |
| — | `--emit-branch-protection` | `factory_sync.py:62-69` · `ADR-006:109-112` | — | `required_pull_request_reviews` **présent avec `0`**, émis inconditionnellement, défaut de repli `1` | ✅ **PASS** — piège documenté, fail-safe |
| — | `gh api` ×4 (lecture seule) | — | — | 403 sur protection **et** rulesets avec `admin: true`, `protected: false`, dépôt privé | ✅ Constat **exact**, reproduit indépendamment |
| — | Sweep indépendant (36 fichiers) | diff `main...HEAD` | — | Aucune affirmation d'une protection active/appliquée/effective | ✅ **Aucune survente résiduelle** |

**Aucun critère bloquant déclenché** : 0 finding SAST HIGH · 0 CVE HIGH/CRITICAL sur dépendance
directe · 0 IDOR (sans objet, justifié) · **0 secret en dur** (prouvé par gitleaks ×2 + 3 greps +
test empirique) · 0 endpoint sans authz (aucun endpoint).

---

## 11. Observations hors périmètre sécurité (transmises, non bloquantes)

1. **`CLAUDE.md` a été modifié** alors que le tableau §Fichiers concernés du Story File le range en
   « **NON modifiés (explicite)** ». Le contenu ajouté **augmente** l'honnêteté (encadré 🔴 « À LIRE
   AVANT TOUT AUDIT » démentant la règle 2, dérogation Art. 5, dette Art. 6). **Aucun impact
   sécurité** ; écart de périmètre à arbitrer par @Reviewer/@QA. À noter que **le texte de la règle 2
   lui-même reste faux** — un lecteur ne lisant que la règle 2 sans descendre à l'encadré serait induit
   en erreur ; correction déléguée à US-00.5, ce qui est acceptable **parce que** le démenti est en
   tête de la section d'état.
2. **T6 (nettoyage cosmétique) non fait** : le diff `factory.config.json` **ajoute** la ligne vide à
   2 espaces avant `"branch_protection"` au lieu de la retirer. Purement cosmétique.

---

## 12. Conformité de l'audit aux interdits

| Interdit | Respect |
|---|---|
| `git push`, force-push, suppression | ✅ **aucune** commande d'écriture git exécutée |
| Test négatif sur `main` | ✅ **non exécuté** (il aurait réussi et modifié `main` hors PR) |
| Appel `PUT`/`POST` sur la protection | ✅ **aucun** — seulement 4 `gh api` **GET** |
| `origin/main` inchangé | ✅ `801a046e7c2f833a4038c4080e0eb19ca0d28754` (vérifié en fin d'audit) |
| Fichiers modifiés | ✅ `git status` **propre** ; seul écrit : **ce rapport** + événement de trace. Ni code, ni SCB, ni `PROJECT_LOG.md`, ni Story File touchés. Les fixtures d'attaque ont été écrites dans le **scratchpad**, hors dépôt |

---

## ✅ Verdict final : **PASS**

Aucun finding bloquant. Les trois mitigations centrales ont été **attaquées, pas relues**, et elles
tiennent : le préfixe `[SIMULATION] ` résiste à l'injection de saut de ligne, `--raw-out` est
effectivement refusé en mode fixture (sans création de fichier), le jeton ne peut pas atteindre
l'archive, et le mode lecture seule est structurel. La cible armée est **sûre** (`required_pull_request_reviews`
présent avec `0`, piège documenté). La posture réelle de `main` est décrite **sans complaisance** et
sans survente résiduelle détectable — la documentation est ici **plus dure avec elle-même** que
l'audit n'avait besoin de l'être.

**Le risque #2 d'EPIC_00 reste OUVERT** : ce PASS certifie l'**honnêteté et la sûreté de l'outillage**,
**pas** la protection de `main` — qui n'existe pas. M1 en est le rappel le plus concret : même la
barrière anti-secrets repose, *in fine*, sur le filet de discipline. Les 3 MEDIUM sont renvoyés à
US-00.5 / `/audit-methodo`.

**Rapport** : `reports/US-00.4/security.md`
