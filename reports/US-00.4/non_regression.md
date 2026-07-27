# Non-régression — US-00.4

**Tâche T13** · Horodatage UTC des exécutions : **2026-07-26T19:27:37Z** · Branche
`feat/US-00.4-ci-protection-branche` (tête `90fad83` au moment des captures T2/T3/T4).
Toutes les commandes ci-dessous ont été **réellement exécutées** ; les sorties sont collées
**telles quelles**, avec leur code de sortie.

## Synthèse

| # | Contrôle | Attendu | Obtenu |
|---|---|---|---|
| 1 | `factory_sync.py --check` | exit 0, mention « DOCUMENTAIRE » + avertissement | ✅ exit 0 |
| 2 | `factory_sync.py --emit-branch-protection` | `0` approbation, 4 contextes, `restrictions: null` | ✅ exit 0 |
| 3 | `check_scb_compliance.py` | conforme | ✅ exit 0 |
| 4 | `validate_trace.py --us US-00.4` | conforme | ✅ exit 0 |
| 5 | `grep -rn "check-remote" .github/workflows/` | **aucun résultat** | ✅ aucun (exit 1 de grep) |
| 6 | Aucune méthode d'écriture dans le comparateur | **aucun résultat** | ✅ aucun (2 greps) |
| 7 | Aucun jeton / `Authorization` dans les livrables | **aucun résultat** | ✅ aucun — mais voir §Réserve gitleaks |
| 8 | Aucun fichier d'enforcement modifié | **aucune ligne** | ✅ aucune |
| 9 | `origin/main` inchangée | `801a046` | ✅ `801a046` |
| 10 | `run_gates.py --component app` | 5 gates verts | ✅ exit 0, couverture 89.5 % ≥ 80 % |
| 11 | 4 status checks **rapportés verts** sur la PR | — | ⚠️ **non exécutable à ce stade** — voir §Réserve PR |

---

## 1. Synchro documentaire — reste verte ET reste un gate bloquant (AC-2)

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
  → exit 0
```

Le mot « protection » n'est plus employé comme **fait vérifié** : l'ancien libellé
`Synchro factory conforme (env, protection, workflows, seuils).` a **disparu**. Cette exécution est
postérieure à la réécriture complète de `docs/GIT_PROTECTION.md` (T10) : **le bloc entre
`<!-- FACTORY_SYNC:BEGIN -->` et `<!-- FACTORY_SYNC:END -->` est resté intact**, ce que ce exit 0
prouve (toute édition manuelle du bloc généré ferait échouer `--check`, donc le job CI `governance`).

## 2. Cible armée — générée, jamais dupliquée (AC-4)

```
$ python scripts/factory_sync.py --emit-branch-protection
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "🔐 Secrets scan (gitleaks)",
      "📋 Governance (SCB + traçabilité + synchro)",
      "check-branch-name",
      "📱 App (gates run_gates.py)"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "enforce_admins": true,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false,
  "required_conversation_resolution": true
}
  → exit 0
```

`required_pull_request_reviews` est **présent avec `0`** (AC-4 limite : `0` approbation **≠** pas de
PR exigée), `enforce_admins: true`, `strict: true`, **exactement 4** contextes aux libellés exacts,
`restrictions: null`. Payload directement consommable par `apply_branch_protection.sh --input -`
**le jour du déblocage** — il n'est **pas** exécuté ici.

## 3. Gouvernance

```
$ python scripts/check_scb_compliance.py
Lecture du SCB : C:\Users\guillaume.decroix\MesProjets\Concentration\STORY_CERTIFICATION_BOARD.md
SCB conforme — Aucune violation détectée.
  → exit 0

$ python scripts/validate_trace.py --us US-00.4
Traçabilité conforme.
  → exit 0
```

## 4. Contrôle négatif — le contrôle distant n'est PAS dans la CI (AC-2 limite)

```
$ grep -rn "check-remote" .github/workflows/
(aucune ligne au-dessus = aucun résultat)
  → exit 1
```

**Raison documentée** (exigée par le critère #6) : le contrôle distant exige des droits **admin** que
le `GITHUB_TOKEN` de la CI n'a pas → l'y mettre produirait un **faux rouge permanent**, ou la
tentation de le rendre non bloquant, donc **décoratif**. Écrit dans `docs/GIT_PROTECTION.md`
§Vérification (« Pourquoi ce contrôle n'est PAS dans la CI ») **et** dans le docstring de
`scripts/factory_sync.py` (« commande d'administration MANUELLE, jamais exécutée par la CI »).

## 5. Contrôle négatif — lecture seule prouvée (AC-3, critère #11)

```
$ grep -nE "-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)" scripts/check_branch_protection.py
(aucune ligne au-dessus = aucun résultat)
  → exit 1

$ grep -niE '"(PUT|POST|PATCH|DELETE)"|method=.(PUT|POST|PATCH|DELETE)|-X ' scripts/check_branch_protection.py
(aucune ligne au-dessus = aucun résultat)
  → exit 1
```

Le second grep est **élargi** volontairement (au-delà du critère #11) : il vérifie qu'aucune méthode
d'écriture n'apparaît sous **aucune** forme, pas même dans une chaîne ou un paramètre `method=`.
La seule écriture disque du module est l'archive `--raw-out`.

> ⚠️ **Piège documenté, corrigé en cours de route** : ce contrôle est **textuel, pas sémantique** — il
> ne distingue pas un appel d'un commentaire. La première rédaction du docstring contenait la phrase
> « Aucun `-X PUT/POST/PATCH/DELETE` » : le grep la **matchait**, et le critère #11 **tombait en échec
> sur une déclaration d'absence**. Le docstring a été reformulé, et porte désormais l'avertissement
> qu'aucune mention littérale ne doit y être réintroduite.

## 6. Sécurité des preuves (critère #21) — et sa réserve

```
$ grep -rnE 'gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,}|AIza[0-9A-Za-z_-]{35}|AQ\.[A-Za-z0-9_-]{20,}|Authorization: *(Bearer|token) +[A-Za-z0-9]' reports/US-00.4/ tests/fixtures/US-00.4/ scripts/check_branch_protection.py
(aucune ligne au-dessus = aucun résultat)
  → exit 1
```

### ⚠️ Réserve gitleaks — le critère #21 n'est PAS gagé localement *(→ **LEVÉE**, voir §12)*

> ✅ **Cette réserve a été LEVÉE le 2026-07-26** par l'audit Sécurité, qui a retrouvé le binaire hors
> `PATH` et exécuté le scan réellement (`no leaks found`, working tree + 30 commits). L'énoncé
> ci-dessous est **conservé tel quel** : il documente la méthode de substitution employée à défaut
> d'outil, et le fait que l'absence de secret n'était alors **pas** prouvée par l'outil de référence.
> Détail et scans rejoués sur les fichiers du correctif : **§12**.

```
$ command -v gitleaks
gitleaks: introuvable dans le PATH de cette session
```

**`gitleaks` n'est pas installé dans cette session.** Le hook `pre-commit` ne le lance que
**conditionnellement** (`if command -v gitleaks`), il n'a donc **rien scanné** ici. Ce qui précède est
un **grep manuel de substitution** (motifs `ghp_`/`gho_`/`ghu_`/`ghs_`/`ghr_`, `github_pat_`, `AIza`,
`AQ.`, en-tête `Authorization`) — **ce n'est pas gitleaks**. Le critère #21 ne sera **réellement gagé
qu'en CI**, par le job bloquant `🔐 Secrets scan (gitleaks)`. Dit franchement : à ce stade, l'absence
de secret dans `reports/US-00.4/` est **vraisemblable, pas prouvée par l'outil de référence**.

**Contenu non sensible mais à connaître** (signalé plutôt que masqué) :
`reports/US-00.4/branch_main_before.json` embarque, dans la réponse brute, un bloc
`-----BEGIN PGP SIGNATURE-----` — la signature **publique** de vérification du commit de fusion par
GitHub, **pas** une clé privée (la règle gitleaks par défaut vise `PRIVATE KEY`) — ainsi que l'e-mail
**public** du committer. La réponse est archivée **telle quelle, sans troncature** : tronquer une
preuve brute la disqualifierait.

## 7. Périmètre des modifications — aucun fichier d'enforcement touché

État **final**, après T5 et T7→T15 (relevé à **2026-07-26T19:35:25Z**) :

```
$ git status --short
 M .claude/commands/audit-methodo.md
 M docs/GIT_PROTECTION.md
 M docs/stories/US-00.4-ci-protection-branche.md
 M scripts/apply_branch_protection.sh
 M tests/fixtures/US-00.4/README.md
?? reports/US-00.4/

$ git diff --stat
 .claude/commands/audit-methodo.md             |  46 +++++
 docs/GIT_PROTECTION.md                        | 286 +++++++++++++++++++++++---
 docs/stories/US-00.4-ci-protection-branche.md |  20 +-
 scripts/apply_branch_protection.sh            |  10 +-
 tests/fixtures/US-00.4/README.md              |   2 +-
 5 files changed, 326 insertions(+), 38 deletions(-)

$ git diff --stat -- factory.config.json scripts/factory_sync.py scripts/run_gates.py scripts/githooks .claude/hooks .gitleaks.toml .claude/settings.json scripts/install_hooks.sh scripts/factory_env.sh
(aucune ligne au-dessus = aucun fichier d'enforcement touché)
  → exit 0
```

Le diff de `docs/stories/US-00.4-ci-protection-branche.md` est **exclusivement** le cochage des cases
**T5** et **T7→T15** de la §Tâches (10 lignes). **T6 reste décochée** (action humaine due) et
**T16→T19 restent décochées** (reportées et interdites). Ni le §Contexte métier, ni les 8 AC, ni le
Gherkin, ni le SCB, ni `PROJECT_LOG.md`, ni la trace, ni l'ADR n'ont été touchés.

`scripts/factory_sync.py` (T4, **action humaine** Art. 6) a été édité par l'humain et **committé en
`90fad83`** : il n'apparaît donc plus comme modifié, et **aucun agent ne l'a rouvert en écriture**.
`factory.config.json` (T6) **n'a pas été touché** — le nettoyage cosmétique reste dû (voir §Réserves).
`scripts/apply_branch_protection.sh` et `.claude/commands/audit-methodo.md` ne sont **ni** dans
l'Art. 6, **ni** dans la liste réellement appliquée par `.claude/hooks/protect_files.sh` : leur
édition par un agent est licite (vérifié dans le hook lui-même).

## 8. Aucune écriture sur `main`, aucun test négatif (AC-7 limite, critère #18)

```
$ git rev-parse origin/main
801a046e7c2f833a4038c4080e0eb19ca0d28754
```

**Inchangée** — identique à sa valeur avant les travaux. Aucun `git push` vers `main`, aucun
`push --force`, aucun `push --delete`, aucun clone-sonde. **T16→T19 non exécutées** (reportées et
interdites). Toutes les lectures d'API de cette US sont des **GET**.

## 9. Gates applicatifs — non-régression

```
$ python scripts/run_gates.py --component app
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
✅ app.format
▶ app.analyze — (.) $ flutter analyze
✅ app.analyze
▶ app.test — (.) $ flutter test --coverage && python scripts/check_flutter_coverage.py --min 80
Couverture de lignes : 89.5% (17/19) — seuil requis : 80.0%
✅ app.test
▶ app.deps_audit — (.) $ dart pub outdated --show-all
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
  → exit 0
```

**Aucun fichier de code Dart n'a été modifié par cette US** : ces gates servent uniquement de
non-régression, il n'y a pas de couverture à produire.

## ⚠️ Réserves — ce que T13 ne peut PAS attester à ce stade

### Réserve PR — les 4 status checks (R10, critère #20)

```
$ gh pr list --head feat/US-00.4-ci-protection-branche --json number,state
[]
$ git ls-remote origin refs/heads/feat/US-00.4-ci-protection-branche
(aucun résultat)
```

**La branche n'est pas poussée et aucune PR n'existe** : `gh pr checks` n'est **pas exécutable** à ce
stade. Le contrôle « 4 status checks rapportés verts sur la PR » reste donc **à faire après l'ouverture
de la PR**, par @DevOps ou @QA. ⚠️ **Rappel R10** : ces checks ne sont **requis par rien** — un check
rouge **n'empêcherait pas** la fusion. Il faut donc les **lire activement** (`gh pr checks`) au lieu de
compter sur un blocage.

### Réserve gitleaks

Voir §6 : critère #21 gagé **en CI seulement**.

### Réserve T6

`factory.config.json` porte **toujours** la ligne vide à 2 espaces avant `"branch_protection"`
(`grep -nE '^  +$' factory.config.json` → `63:  $`). **Aucun impact fonctionnel** (le JSON parse,
`--check` reste vert) mais le nettoyage cosmétique de T6 est **une action humaine encore due**
(fichier Art. 6).

---

## 10. Revalidation FINALE — après T5 et T7→T15 (2026-07-26T19:35:25Z)

Les captures des §1→§9 datent de **19:27:37Z**, soit **avant** les corrections T14 (C4, C5, C9), la
régénération de `check_remote_exit2.txt` et le cochage des cases du Story File. **Tous les contrôles
sensibles ont donc été rejoués à l'état final :**

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
exit=0

$ python scripts/check_scb_compliance.py
SCB conforme — Aucune violation détectée.
exit=0

$ python scripts/validate_trace.py --us US-00.4
Traçabilité conforme.
exit=0

$ python scripts/run_gates.py --all
✅ app.format · ✅ app.analyze · ✅ app.test (couverture 89.5% ≥ 80%) · ✅ app.deps_audit · ✅ app.build
Tous les gates bloquants passent (5 exécutés).
EXIT=0

$ git rev-parse origin/main
801a046e7c2f833a4038c4080e0eb19ca0d28754
```

Le exit 0 de `--check` à l'état final est le contrôle **le plus important de T10** : il prouve que la
réécriture complète de `docs/GIT_PROTECTION.md` (286 lignes modifiées) **n'a pas altéré d'un octet** le
bloc généré entre `<!-- FACTORY_SYNC:BEGIN -->` et `<!-- FACTORY_SYNC:END -->`.

---

## 11. Non-régression APRÈS correctifs post-audit (T20/T21) — 2026-07-26T20:34:35Z

L'audit Revue a rendu **FAILED** (2 bloquants, reproduits par l'orchestrateur). Correctifs **T20**
(faux vert du comparateur) et **T21** (relecture surestimant son exhaustivité). Tout a été rejoué :

```
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
exit=0

$ python scripts/factory_sync.py --check-remote
Lecture SEULE de l'API GitHub (GET uniquement) — gitgdx/Concentration:main · GET repos/gitgdx/Concentration/branches/main → 200 · GET repos/gitgdx/Concentration/branches/main/protection → 403
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Code HTTP : 403 — protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut lire ni appliquer la protection en l'état. Message API : 'Upgrade to GitHub Pro or make this repository public to enable this feature.'
exit=2

$ python scripts/check_scb_compliance.py       -> SCB conforme — Aucune violation détectée.   exit=0
$ python scripts/validate_trace.py --us US-00.4 -> Traçabilité conforme.                       exit=0

$ grep -rn "check-remote" .github/workflows/                                                   -> aucun résultat (exit 1)
$ grep -nE "-X (PUT|POST|PATCH|DELETE)|requests\.(put|post|patch|delete)" scripts/check_branch_protection.py -> aucun résultat (exit 1)
$ grep -niE '"(PUT|POST|PATCH|DELETE)"|method=.(PUT|POST|PATCH|DELETE)|-X ' scripts/check_branch_protection.py -> aucun résultat (exit 1)
$ grep -ci "conform" reports/US-00.4/check_remote_exit2.txt                                     -> 0
$ python -m py_compile scripts/check_branch_protection.py                                       -> OK

$ python scripts/run_gates.py --all
✅ app.format · ✅ app.analyze · ✅ app.test (couverture 89.5% ≥ 80%) · ✅ app.deps_audit · ✅ app.build
Tous les gates bloquants passent (5 exécutés).
EXIT=0
```

**`ci.yml` (T21) n'a pas cassé la résolution des status checks** : `factory_sync.py --check` reste
**exit 0**, ce qui prouve que les 4 libellés de `status_checks` correspondent toujours à des jobs
(`secrets-scan`, `governance`, `app-quality`, `check-branch-name`). Seul l'en-tête de commentaires a
changé — aucune ligne de logique.

**Garantie d'import paresseux revérifiée après T20** (le module a beaucoup changé) :

```
$ (module temporairement remplacé par un fichier au contenu syntaxiquement invalide)
$ python scripts/factory_sync.py --check   -> exit 0
$ (module restauré ; py_compile -> OK)
```

Une erreur d'import du comparateur ne peut donc toujours **pas** casser `--check`, qui est un gate CI
bloquant.

**Les 8 chemins du comparateur, rejoués** (`check_remote_simulated.txt`) :

```
 · invocations archivées avec leur code de sortie : 8 (8 attendues)
 · invocations dont le code OBTENU == code ATTENDU : 8 / 8
 · lignes préfixées `[SIMULATION] ` : 137
 · mention « SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt » : 2 (2 attendues : [1/8] et [8/8])
 · issues « MAPPING INCOMPLET » (correctif B-2) : 3 (3 attendues : [5/8], [6/8], [7/8])
 · lignes « IGNORÉ — NEUTRE » (champs additifs nommés, jamais silencieux) : 6
 · lignes d'outil sans préfixe [SIMULATION] : 0
```

## 12. ✅ Réserve gitleaks — LEVÉE

L'audit Sécurité (contexte frais) a **retrouvé le binaire hors `PATH`** et exécuté le scan réellement :
`gitleaks 8.30.1` → **`no leaks found`** sur le working tree (89.82 MB) **et** sur **30 commits**
d'historique. J'ai rejoué le scan **sur les fichiers du correctif** avec le même binaire
(`…\AppData\Local\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_…\gitleaks.exe`) :

```
$ gitleaks version
8.30.1

$ gitleaks detect --no-git --source tests/fixtures/US-00.4 --config .gitleaks.toml --redact
INF scanned ~18289 bytes (18.29 KB) in 282ms
INF no leaks found                                          -> exit 0

$ gitleaks detect --no-git --source reports/US-00.4 --config .gitleaks.toml --redact
INF scanned ~199737 bytes (199.74 KB) in 255ms
INF no leaks found                                          -> exit 0

$ gitleaks detect --no-git --source scripts/check_branch_protection.py --config .gitleaks.toml --redact
INF scanned ~47464 bytes (47.46 KB) in 163ms
INF no leaks found                                          -> exit 0

$ gitleaks detect --no-git --source .github/workflows/ci.yml --config .gitleaks.toml --redact
INF scanned ~2968 bytes (2.97 KB) in 303ms
INF no leaks found                                          -> exit 0
```

Le critère #21 est donc gagé par **l'outil de référence**, y compris sur les 4 nouvelles fixtures. Le
grep de substitution du §6 reste documenté : il décrit la méthode employée **à défaut** d'outil, et
n'est plus la seule preuve.

### Réserve « validation non automatisée »

Il n'existe **aucun gate de couverture Python** dans ce dépôt : la validation de
`scripts/check_branch_protection.py` repose sur les **critères de test sur fixtures** exécutés à la
main (voir `check_remote_simulated.txt`), **pas** sur un test automatisé. Une régression future de ce
module ne serait détectée par **aucun** gate. Dette #9 de `enforcement_gap.md`.
