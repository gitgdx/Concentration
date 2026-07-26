# Audit Sécurité — US-00.1 · Secrets & scan de dépôt

> Audit en **contexte frais** (Constitution Art. 2 / Art. 5). Agent : **@CyberSecurity**.
> Modèle : `claude-opus-4-8`. Date : 2026-07-26. Branche : `feat/US-00.1-secrets-scan-depot`.
> Story File de référence : `docs/stories/US-00.1-secrets-scan-depot.md` (AC-1 → AC-4).
> Outil : gitleaks **8.30.1** (winget). Un rapport sans sortie d'outil est invalide — toutes les
> sorties ci-dessous sont réelles et **redacted**.

## Verdict : ✅ PASS

Aucun secret réel committé (historique complet + working tree, avec **et** sans config).
Allowlist chirurgicale et prouvée (ne masque aucun vrai secret committé). Garde-fou pre-commit + CI
effectivement câblé sur la config unique. Procédure de rotation conforme. Preuves sans secret en clair.
**0 finding bloquant.**

---

## 1. Périmètre du diff (`git diff --name-only main...HEAD`)

Aucun code applicatif Dart, aucun `pubspec.yaml` modifié → SAST (`flutter analyze`) et audit de
dépendances **N/A par non-régression** (justifié, cf. §6). Fichiers touchés :

```
.gitleaks.toml                          (config sécurité — verrouillée protect_files.sh)
PROJECT_LOG.md / STORY_CERTIFICATION_BOARD.md / docs/trace/US-00.1/events.jsonl
docs/security/SECRET_ROTATION.md        (procédure de rotation AC-4)
reports/US-00.1/*                        (preuves : README, 2 SARIF, proposed, negative-precommit)
```

---

## 2. Zéro secret committé — scans indépendants (point critique)

### SCAN 1 — Historique complet, config projet
```
$ gitleaks git --config .gitleaks.toml --redact .
INF 13 commits scanned.
INF scanned ~506092 bytes (506.09 KB) in 1.18s
INF no leaks found
EXIT_CODE=0
```

### SCAN 2 — Working tree (dir-mode), config projet
```
$ gitleaks dir --config .gitleaks.toml --redact .
INF scanned ~89333126 bytes (89.33 MB) in 3.05s
INF no leaks found
EXIT_CODE=0
```

### SCAN 3 — CONTRE-TEST historique **SANS** config (filet par défaut seul)
> Objectif : vérifier que l'allowlist ne « fait pas passer » un vrai secret présent dans l'historique.
```
$ gitleaks git --redact .
INF 13 commits scanned.
INF scanned ~506092 bytes (506.09 KB) in 852ms
INF no leaks found
EXIT_CODE=0
```
**Analyse de l'écart** : identique au SCAN 1 (`no leaks found`). L'historique est propre y compris
sous le filet par défaut brut → **l'allowlist ne masque aucun secret committé**. (Le contre-test
working tree sans config renvoie lui aussi `no leaks found` : les règles par défaut ne contiennent
pas la règle custom `stitch-token-aq`, donc la vraie clé locale — non committée — n'y est de toute
façon pas vue.)

### Aucun fichier secret suivi par Git
```
$ git ls-files | grep -E "settings.local|\.env$"
(vide)
$ git ls-files | grep -E "\.env|\.mcp"
.env.example        # placeholders uniquement (STITCH_API_KEY=changeme, GITHUB_MCP_TOKEN=changeme)
.mcp.json           # interpolations ${STITCH_API_KEY} / ${GITHUB_MCP_TOKEN}, aucun secret en clair
```
La **vraie** clé Stitch vit dans `.claude/settings.local.json` (présent sur disque, format `AQ.<token>`,
**gitignoré et NON suivi** — vérifié). `.gitignore` couvre `.env`, `.env.*`, `*.env` (`!*.env.example`)
et `.claude/settings.local.json`.

---

## 3. Allowlist saine — chaque entrée prouvée

| Entrée `.gitleaks.toml` | Type | Justification vérifiée | Verdict |
|---|---|---|---|
| `changeme` | regex | placeholder de `.env.example` (valeur factice prouvée) | Sain |
| `\$\{[A-Z_]+\}` | regex | interpolation d'env (`${STITCH_API_KEY}`) — pas un secret | Sain |
| `\.env\.example$` | path | gabarit de secrets : placeholders uniquement | Sain |
| `\.mcp\.json$` | path | config MCP, `${VAR}` interpolé | Sain |
| `\.env$` | path | secrets locaux gitignorés, jamais committés | Sain |
| `\.claude/settings\.local\.json$` | path | config locale (vraie clé), gitignorée | Sain |
| `reports/US-00\.1/gitleaks\.toml\.proposed$` | path | fichier de proposition (regexes, pas de secret) | Sain |

Aucune désactivation globale de règle ni exclusion de chemin large. `.gitleaks.toml` committé =
**identique** à `reports/US-00.1/gitleaks.toml.proposed` (`diff` vide → source unique respectée).

### Règles custom **fonctionnelles** (pas décoratives) — test synthétique isolé (hors dépôt, redacted)
```
# Faux token AQ.<40> :
$ gitleaks dir --config .gitleaks.toml --redact <scratchpad>
WRN leaks found: 1   → RuleID = "stitch-token-aq"   (= format de la VRAIE clé Stitch)

# Faux AIza + 35 car. :
RuleID = "gcp-api-key" (défaut)  +  RuleID = "google-api-key-stitch" (custom)
```
La règle `stitch-token-aq` détecte le format réel `AQ.<token>` → le garde-fou pre-commit est crédible
(cohérent avec le test négatif T7). Les clés Google `AIza…` sont couvertes deux fois (défaut + custom).

---

## 4. Garde-fou effectif (AC-3) — câblage vérifié

- **Pre-commit** (`scripts/githooks/pre-commit:52`) :
  `gitleaks protect --staged --config .gitleaks.toml || fail "secret potentiel détecté…"`
- **CI** (`.github/workflows/ci.yml`, job `secrets-scan`) : `fetch-depth: 0` (l.31) +
  `gitleaks/gitleaks-action@v2` (l.32, auto-détection de `.gitleaks.toml` racine) → **même config** que le hook.
- `.gitleaks.toml` figure dans la liste verrouillée de `.claude/hooks/protect_files.sh` (fichier d'enforcement).
- **Preuve test négatif pre-commit** (`reports/US-00.1/negative-precommit.txt`, redacted) :
  `WRN leaks found: 1` / `exit_code=1` → commit bloqué. Crédible.
- **Preuve test négatif CI** : job `secrets-scan = failure` sur PR jetable #2
  (run 30155284206), branche supprimée, faux secret jamais mergé. Crédible.

---

## 5. Procédure de rotation (AC-4) — `docs/security/SECRET_ROTATION.md`

Couvre l'ordre **Révoquer → Régénérer → Remplacer → (Nettoyer l'historique)** : révocation côté
fournisseur (Google Cloud pour `STITCH_API_KEY`, GitHub PAT pour `GITHUB_MCP_TOKEN`), régénération,
remplacement en `.env`/secret de plateforme (jamais committé), et **réécriture d'historique
(`git filter-repo`/BFG) = dernier recours à décision humaine explicite**. Conclut « aucune rotation
requise à ce jour » (cohérent avec les scans §2). Conforme AC-4.

---

## 6. Audit des dépendances & SAST

- **SAST** : pas de gate `sast` pour Flutter (l'équivalent Dart = `flutter analyze`). Aucun fichier
  `.dart` dans le diff → **N/A par non-régression**.
- **deps_audit** (`dart pub outdated --show-all`, gate non bloquant) : exécuté → `✅ app.deps_audit`,
  « already using the newest resolvable versions ». Aucun CVE. Aucune dépendance ajoutée par cette US
  (pas de `pubspec.yaml` dans le diff) → **N/A justifié**.

---

## 7. Pas de secret dans les preuves (redaction)

- `reports/US-00.1/gitleaks-history.sarif` : `runs=1`, **`results=0`** (aucun finding).
- `reports/US-00.1/gitleaks-worktree.sarif` : `runs=1`, **`results=0`**.
- Recherche de motifs `AIza…{35}` / `AQ\.…{20,}` dans les SARIF et `negative-precommit.txt` :
  **aucune valeur de secret en clair**. `--redact` respecté partout.

---

## 8. Findings

| Outil | Fichier:Ligne | Sévérité | Décision |
|---|---|---|---|
| gitleaks git (config) | historique — 13 commits | — | 0 fuite (exit 0) — PASS |
| gitleaks dir (config) | working tree 89 MB | — | 0 fuite (exit 0) — PASS |
| gitleaks git (SANS config) | historique — contre-test | — | 0 fuite — allowlist ne masque rien — PASS |
| git ls-files | `.env`/`settings.local` | — | non suivis — PASS |
| gitleaks (synthétique) | règle `stitch-token-aq` | INFO | règle fonctionnelle (détecte format réel) — PASS |
| Revue | `.gitleaks.toml:27` `google-api-key-stitch` | INFO | redondante avec `gcp-api-key` par défaut (robustesse voulue) — acceptable |
| Revue | `.gitleaks.toml:64-70` keystore/certificats | LOW (suivi) | note d'ingénierie, pas de règle (barrière = `.gitignore`) — correct, à ré-arbitrer avec @DevOps quand la signature mobile arrivera |
| Revue | `.gitleaks.toml:39` `AQ\.{20,}` | INFO | seuil ≥20 car. commenté « à calibrer par l'humain » — acceptable |
| SARIF / negative-precommit | preuves | — | redacted, `results=0`, aucun secret en clair — PASS |

**Bloquants (HIGH/CRITICAL) : aucun.** IDOR, injection, XSS : sans objet (US sans code applicatif).
Secrets en dur : **aucun**. Mots de passe hachés : sans objet. Endpoint sans authz : sans objet.

---

## Conclusion

**PASS.** Le dépôt est structurellement protégé contre la fuite de secrets : config unique calibrée
et prouvée saine, historique + working tree à 0 fuite (validé y compris sans config), garde-fou
pre-commit + CI câblé sur la même `.gitleaks.toml`, procédure de rotation conforme, preuves redacted.
Suivis non bloquants : ré-arbitrer la couverture keystore/certificats de signature mobile avec
@DevOps quand ce périmètre arrivera (hors MVP).
