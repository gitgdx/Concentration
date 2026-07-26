# Audit Sécurité — US-00.3 · Migrations réversibles

- **Agent** : @CyberSecurity (contexte frais, Constitution Art. 2 & 5)
- **Modèle** : claude-opus-4-8
- **Date** : 2026-07-26
- **Branche auditée** : `feat/US-00.3-migrations-reversibles` — diff `git diff main...HEAD`
- **Nature de l'US** : convention documentaire (migrations de schéma local, agnostique techno).
  Aucun code applicatif, aucun schéma concret, aucun secret, aucune surface réseau/auth/rendu.

## VERDICT : ✅ PASS

Aucun finding bloquant. US strictement documentaire, aucun secret introduit, aucune dépendance
ajoutée. La convention établit une **bonne posture de résilience de la donnée locale** (réversibilité,
non-destructif par défaut, exception destructive réellement encadrée et traçable). Deux points
d'attention LOW à reporter à US-01.2 (non bloquants au Sprint 0).

---

## 1. Outillage — commandes & sorties

### 1.1 Périmètre du diff (attendu : exclusivement documentaire)

```
$ git diff main...HEAD --stat
 PROJECT_LOG.md                                     |   3 +
 STORY_CERTIFICATION_BOARD.md                       |  12 +-
 docs/adr/ADR-005-convention-migrations-reversibles.md   |  60 ++++++++++
 docs/architecture/MIGRATIONS.md                    | 133 +++++++++++++++++++++
 docs/trace/US-00.3/events.jsonl                    |   5 +
 reports/US-00.3/README.md                          |  38 ++++++
 6 files changed, 247 insertions(+), 4 deletions(-)

$ git diff main...HEAD --name-only | grep -i "pubspec|\.dart|\.yaml|\.yml|scripts/|\.github/|\.claude/"
AUCUN fichier code/config/enforcement dans le diff
```

**Résultat** : diff 100 % documentaire (docs/, reports/, trace JSONL, SCB, PROJECT_LOG). **Aucun**
fichier de code applicatif (`.dart`), de manifeste (`pubspec.yaml`), ni d'enforcement
(`factory.config.json`, `scripts/*`, `.github/*`, `.claude/hooks/*`). Conforme à la nature de l'US et
à la contrainte « fichiers d'enforcement intouchables » (Story File §Contraintes / Art. 6).

### 1.2 Secrets — gitleaks 8.30.1

```
$ "$GITLEAKS" git --config .gitleaks.toml --redact .
23 commits scanned.
scanned ~587631 bytes (587.63 KB) in 2.1s
no leaks found
EXIT=0
```

**Résultat** : `no leaks found`. Aucun secret en dur introduit.

### 1.3 SAST

```
$ python scripts/run_gates.py --gate sast
[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).
EXIT=1
```

**Résultat** : aucun gate `sast` n'est défini dans `factory.config.json` (gates du composant `app` :
`format`, `analyze`, `test`, `deps_audit`, `build`). L'analyse statique du projet Flutter est portée
par `flutter analyze` (gate `analyze`). **Sans objet ici** : l'US n'ajoute aucun code compilé — le
canevas Dart de `MIGRATIONS.md §4` est un bloc de code Markdown (jamais un fichier `.dart` compilé),
donc hors périmètre de l'analyse statique. Pas de code = pas de surface SAST.

### 1.4 Dépendances — deps_audit

```
$ python scripts/run_gates.py --gate deps_audit          # (.) $ dart pub outdated --show-all
...
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
Tous les gates bloquants passent (1 exécutés).
EXIT=0
```

**Résultat** : gate PASS. **Aucune nouvelle dépendance** introduite par l'US (aucune modif de
`pubspec.yaml` dans le diff). Aucune CVE HIGH/CRITICAL. (Versions transitives `meta`/`vector_math`/
`matcher`/`test_api` non « latest » mais contraintes par le SDK Flutter — non concernées par l'US,
non bloquant.)

---

## 2. Revue manuelle ciblée

### 2.1 Surface sécurité classique (injection / IDOR / XSS / authz / CSRF / CORS)

**Sans objet — justifié.** L'US ne produit aucun code exécutable, aucun endpoint, aucune requête,
aucun rendu, aucun flux authentifié, aucune ressource multi-tenant. Il n'existe donc :
- aucune requête interpolée (pas d'injection possible) ;
- aucune ressource propriétaire à contrôler (pas d'IDOR) ;
- aucun rendu de contenu utilisateur (pas de XSS) ;
- aucun endpoint ni cookie de session (pas d'authz/CSRF/CORS).

L'analyse porte donc sur la **posture de sécurité/robustesse de la convention** (protection de la
donnée locale offline-first), conformément au mandat.

### 2.2 Posture de la convention (protection de la donnée locale)

| Point | Exigence | Constat (`MIGRATIONS.md`) | Verdict |
|---|---|---|---|
| (a) Réversibilité = pas de perte | Invariant aller-retour | §2 : invariant `up→down = état antérieur` non négociable ; rejet des `down` non conformes ; interdiction des pertes « au-delà du delta ». Bonne résilience. | ✅ |
| (b) Non-destructif par défaut | Interdiction par défaut | §3 : additif par défaut (RF-21) ; toute suppression/`DROP` lossy est destructive et **bloquée en revue** par défaut. Bonne posture. | ✅ |
| (c) Exception destructive encadrée | Porte non banalisée | §3 : exception admise **seulement cumulativement** — (1) préservation documentée restituable par `down`, (2) **validation humaine explicite tracée `EVT_WAIVER_GRANTED`**, (3) invariant préservé. L'événement `EVT_WAIVER_GRANTED` **existe réellement** dans `scripts/events_catalog.json` → la porte est **traçable et auditable**, pas un contournement silencieux. | ✅ |
| (d) Pas de secret en clair au schéma | Ne rien encourager | La convention est agnostique et ne suggère jamais de stocker un secret ; §1 mentionne uniquement `PRAGMA user_version` (métadonnée non sensible). | ✅ |

### 2.3 Points d'attention (LOW — non bloquants au Sprint 0, à reporter à US-01.2)

- **PA-1 (LOW) — Chiffrement au repos non abordé.** L'app est offline-first : toutes les données
  vivent sur l'appareil. La convention ne mentionne pas le chiffrement-au-repos des données locales
  sensibles. **Sans objet au Sprint 0** (aucun schéma, entité *Échéance* non manifestement sensible),
  mais **à statuer explicitement en US-01.2** dès qu'un schéma réel existe (et *a fortiori* pour de
  futurs modules Respiration/Concentration si des données personnelles y apparaissent). Recommandation :
  intégrer la décision « chiffrement au repos oui/non + justification » à l'ADR de persistance d'US-01.2.
- **PA-2 (LOW) — Vigilance sur la banalisation du destructif.** La porte d'exception (§3) est
  correctement encadrée aujourd'hui. Veiller, en US-01.2 et au-delà, à ce que chaque recours effectif
  au destructif produise bien son `EVT_WAIVER_GRANTED` + preuve de préservation (ne pas laisser la
  dérogation devenir routinière). Point de gouvernance, déjà signalé dans le Story File §Risques.

---

## 3. Findings

`[Outil] | [Fichier:Ligne] | [Sévérité] | [Décision]`

| Outil | Fichier:Ligne | Sévérité | Décision |
|---|---|---|---|
| git diff --stat | (6 fichiers, docs/reports/trace/SCB/log) | INFO | Périmètre 100 % documentaire — conforme |
| gitleaks 8.30.1 | (23 commits, dépôt entier) | INFO | `no leaks found` — aucun secret |
| run_gates sast | factory.config.json | INFO | Aucun gate SAST défini ; sans objet (aucun code compilé) |
| run_gates deps_audit | pubspec.yaml (inchangé) | INFO | PASS — aucune dép ajoutée, pas de CVE HIGH/CRITICAL |
| Revue posture | docs/architecture/MIGRATIONS.md §2/§3 | INFO | Réversibilité + non-destructif par défaut + exception tracée = bonne posture |
| Revue posture | docs/architecture/MIGRATIONS.md (chiffrement) | LOW | PA-1 : statuer chiffrement au repos en US-01.2 (non bloquant Sprint 0) |
| Revue gouvernance | docs/architecture/MIGRATIONS.md §3 | LOW | PA-2 : surveiller la non-banalisation du destructif (waiver systématique) |

**Bloquants (→ FAILED)** : aucun.
- Finding SAST HIGH : aucun (pas de surface SAST).
- CVE HIGH/CRITICAL sur dépendance directe : aucune (aucune dép ajoutée).
- IDOR / secret en dur / endpoint sans authz : sans objet (aucun code/endpoint) — confirmé par diff + gitleaks.

---

## 4. Conclusion

**PASS.** US-00.3 est strictement documentaire, sans secret ni dépendance, sans surface d'attaque
classique. La convention de migrations réversibles renforce la posture de sécurité des données locales
(résilience par réversibilité, non-destructif par défaut, exception destructive encadrée et réellement
traçable via `EVT_WAIVER_GRANTED`). Deux points d'attention LOW (chiffrement au repos ; non-banalisation
du destructif) sont à traiter en US-01.2, non bloquants au Sprint 0.
