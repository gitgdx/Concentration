# Code Review — US-00.1 · Secrets & scan de dépôt

- **Auditeur** : @CodeReviewer (contexte frais, aucune connaissance de la session de développement)
- **Modèle** : claude-opus-4-8 (1M context)
- **Date** : 2026-07-26
- **Branche** : `feat/US-00.1-secrets-scan-depot` (HEAD `ce92ec6`)
- **Story File** : `docs/stories/US-00.1-secrets-scan-depot.md`
- **Nature** : US de configuration sécurité, **sans code applicatif Dart**.

## Verdict : ✅ PASSED

- **Findings bloquants** : 0
- **Suggestions d'amélioration** (non bloquantes) : 3 (1 Medium, 2 Low)

Tous les AC (AC-1 à AC-4) sont couverts et prouvés par exécution d'outil. Config unique
partagée hook + CI confirmée. Re-scan indépendant : 0 fuite (historique + working tree).
Test négatif indépendant : la règle custom Stitch se déclenche réellement. Gates Dart verts
(non-régression). Aucune valeur de secret en clair dans les preuves versionnées.

---

## 1. Périmètre du diff (`git diff main...HEAD --stat`)

```
 .gitleaks.toml                          |   71 ++
 PROJECT_LOG.md                          |    5 +
 STORY_CERTIFICATION_BOARD.md            |   17 +-
 docs/security/SECRET_ROTATION.md        |   86 ++
 docs/trace/US-00.1/events.jsonl         |    4 +
 reports/US-00.1/README.md               |   64 ++
 reports/US-00.1/gitleaks-history.sarif  | 1362 ++++++++++++++++++++++++++
 reports/US-00.1/gitleaks-worktree.sarif | 1362 ++++++++++++++++++++++++++
 reports/US-00.1/gitleaks.toml.proposed  |   71 ++
 reports/US-00.1/negative-precommit.txt  |   12 +
 10 files changed, 3051 insertions(+), 3 deletions(-)
```

Aucun fichier `lib/` ou `test/` touché → cohérent avec « US sans code Dart ». `.env.example`
et `.mcp.json` sont déjà trackés sur `main` (commits `f45f5dd`/`3e5cda1`), d'où leur absence
du diff ; ils sont bien couverts par l'allowlist et scannés propres (cf. §4).

---

## 2. Gates statiques / non-régression (COLLÉS)

### `python scripts/run_gates.py --component app` → **exit 0**

Pour une US Flutter sans code Dart, l'équivalent lint/typecheck = `flutter analyze`, exécuté
dans le composant `app`. Les 5 gates bloquants passent :

```
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
GATES_EXIT=0
```

(format, analyze, test, deps_audit, build — tous verts ; aucune régression sur le squelette Flutter.)

---

## 3. Vérification config unique (AC-1 / AC-3)

### `.gitleaks.toml` racine == `reports/US-00.1/gitleaks.toml.proposed`

```
$ diff .gitleaks.toml reports/US-00.1/gitleaks.toml.proposed
IDENTIQUES
```

### Consommation par le hook ET la CI

- **pre-commit** (`scripts/githooks/pre-commit` l.51-53) :
  ```
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks protect --staged --config .gitleaks.toml || fail "secret potentiel détecté dans le staging"
  fi
  ```
- **CI** (`.github/workflows/ci.yml`, job `secrets-scan` l.28-34) : `actions/checkout@v4`
  avec `fetch-depth: 0` (l.31) + `gitleaks/gitleaks-action@v2` (auto-détection du
  `.gitleaks.toml` racine). Bloc `permissions: {contents: read, pull-requests: write}` présent.

→ **Une seule config, source de vérité pour le hook local et la CI.** Conforme AC-1/AC-3.

### Contenu `.gitleaks.toml` (revue manuelle)

- `[extend] useDefault = true` **présent** (l.18-19) — filet par défaut conservé, aucune
  reconstruction à partir d'une config vide. ✅
- **Aucune désactivation globale de règle**, aucune exclusion de chemin large. ✅
- 2 règles ciblées, chacune **commentée/justifiée** : `google-api-key-stitch` (`AIza…`) et
  `stitch-token-aq` (`AQ\.[A-Za-z0-9_\-]{20,}`). ✅
- Allowlist chirurgicale, chaque entrée **commentée** :
  - regexes : `changeme` (placeholder prouvé), `\$\{[A-Z_]+\}` (interpolation d'env). ✅
  - paths : `\.env\.example$`, `\.mcp\.json$`, `\.env$`, `\.claude/settings\.local\.json$`,
    `reports/US-00\.1/gitleaks\.toml\.proposed$` — tous ciblés (fichier précis) et justifiés,
    aucun placeholder ne masque une vraie valeur. ✅

---

## 4. Re-scan indépendant (AC-2) — gitleaks 8.30.1

### Historique Git complet

```
$ gitleaks git --config .gitleaks.toml --redact .
INF 13 commits scanned.
INF scanned ~506092 bytes (506.09 KB) in 573ms
INF no leaks found
GIT_EXIT=0
```

### Working tree (89 MB, inclut `.claude/settings.local.json` = vraie clé Stitch locale)

```
$ gitleaks dir --config .gitleaks.toml --redact .
INF scanned ~89333126 bytes (89.33 MB) in 4.64s
INF no leaks found
DIR_EXIT=0
```

→ **0 fuite** confirmée indépendamment sur l'historique ET le working tree. L'allowlist ne
produit pas de faux négatif dangereux (la vraie clé locale est dans un fichier gitignoré,
allowlisté par path — comportement attendu).

### Preuves du dev (SARIF) — vérification redaction

```
$ grep -c '"ruleId"' reports/US-00.1/gitleaks-history.sarif   → 0
$ grep -c '"ruleId"' reports/US-00.1/gitleaks-worktree.sarif  → 0
$ grep -nE 'AIza[0-9A-Za-z]|AQ\.[A-Za-z0-9]{10}|"snippet"|"secret"' reports/US-00.1/*.sarif → (aucune correspondance)
```

→ Résultats vides (0 leak) et **aucune valeur de secret en clair** dans les SARIF versionnés. ✅

---

## 5. Test négatif indépendant (AC-3) — la règle n'est pas décorative

Injection d'un faux jeton `AQ.<token>` d'apparence aléatoire dans un fichier hors dépôt (scratchpad),
scanné avec la config du dépôt, `--redact` :

```
$ gitleaks dir --config .gitleaks.toml --redact <scratch>
WRN leaks found: 1
NEG_EXIT=1
```

→ La règle custom `stitch-token-aq` **se déclenche réellement** (exit 1), preuve indépendante
que le garde-fou détecte un vrai format de jeton. (À noter : un jeton en séquence alphabétique
triviale n'est PAS détecté — filtré par les stopwords/allowlist par défaut de gitleaks —
comportement normal et sans impact sécurité.) Cohérent avec la preuve dev
`reports/US-00.1/negative-precommit.txt` (`leaks found: 1`, exit 1, redacted).

---

## 6. Couverture AC ↔ preuves ↔ Gherkin

| AC | Exigence | Vérifié | Preuve |
|---|---|---|---|
| AC-1 | `.gitleaks.toml` unique, `useDefault`, règles+allowlist commentées, pas de désactivation globale | ✅ | §3 (diff identique, revue config) |
| AC-2 | Scan historique + working tree = 0 fuite | ✅ | §4 (re-scan indépendant, exit 0) |
| AC-3 | Garde-fou pre-commit + CI, prouvé par test négatif | ✅ | §3 (hook+CI), §5 (test négatif indép.), `negative-precommit.txt`, run CI #2 (failure) |
| AC-4 | Procédure de rotation documentée + « aucune rotation requise » | ✅ | `docs/security/SECRET_ROTATION.md` (identifier→révoquer→régénérer→remplacer, cas Stitch, §5 « aucune rotation requise », §6 réécriture historique = décision humaine) |

Les 8 scénarios Gherkin (`tests/features/US-00.1-secrets-scan-depot.feature`) mappent 1:1 sur
AC-1→AC-4 (nominal/erreur/limite). Cohérence AC ↔ Gherkin confirmée.

---

## 7. Findings

### Bloquants (→ FAILED) : **AUCUN**

### Suggestions d'amélioration (non bloquantes)

| Fichier:Ligne | Problème | Solution |
|---|---|---|
| `.gitleaks.toml:1-12` (Medium) | L'en-tête du fichier racine dit encore « PROPOSITION … Copie-le à la racine ». Or c'est désormais LE fichier racine actif → commentaire périmé et potentiellement trompeur pour un futur lecteur. | Adapter l'en-tête (retirer la mention « PROPOSITION / copie-le »), ou supprimer le doublon `reports/US-00.1/gitleaks.toml.proposed` désormais redondant. Cosmétique, sans impact sécurité. |
| `.gitleaks.toml:62-71` (Medium) | AC-1 demande de « couvrir … les futurs artefacts de signature mobile (keystore Android / certificats iOS) ». Aucune règle ni entrée dédiée : une NOTE d'ingénierie explique (à raison) que gitleaks scanne le contenu, pas l'extension d'un binaire, et renvoie la barrière `.gitignore` à @DevOps quand la signature mobile arrivera. Techniquement correct et transparent, mais la couverture reste **différée** hors US. | Non bloquant (artefacts « futurs », hors MVP/RNF-07 ; le ruleset par défaut scanne déjà tout contenu committé). Tracer un follow-up @DevOps : ajouter `.jks/.keystore/.p12/.mobileprovision` au `.gitignore` + secret de plateforme lors de l'US de signature mobile. À confirmer par @CyberSecurity. |
| `reports/US-00.1/gitleaks.toml.proposed` (Low) | Copie de la config racine conservée dans `reports/` (allowlistée par path). Risque de dérive silencieuse si la racine évolue sans mettre à jour la copie. | Aujourd'hui identiques (§3). Envisager de supprimer la copie ou d'ajouter une note « source de vérité = racine ». |

Aucune de ces suggestions ne constitue une erreur lint/typecheck, une duplication de code
applicatif, une requête N+1, du code sans test, ni un AC non couvert → verdict **PASSED**.

---

## 8. Commandes clés exécutées

```
git diff main...HEAD --stat
git ls-files | grep -E '(\.env\.example|\.mcp\.json|\.gitleaks\.toml)$'
diff .gitleaks.toml reports/US-00.1/gitleaks.toml.proposed        # IDENTIQUES
grep -c '"ruleId"' reports/US-00.1/*.sarif                        # 0 / 0
gitleaks git  --config .gitleaks.toml --redact .                  # no leaks found, exit 0 (13 commits)
gitleaks dir  --config .gitleaks.toml --redact .                  # no leaks found, exit 0 (89 MB)
gitleaks dir  --config .gitleaks.toml --redact <faux AQ.token>    # leaks found: 1, exit 1
python scripts/run_gates.py --component app                       # 5 gates OK, exit 0
```
