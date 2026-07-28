---
description: Audit trimestriel de la méthodologie — régénère un rapport comparatif des métriques factory
---

Rituel d'audit méthodologie (trimestriel, ou à la demande).

1. **Collecter les métriques courantes** (exécuter réellement) :
   - qualité et couverture : `python scripts/run_gates.py --all` (compter les findings, relever les couvertures) ;
   - conformité : `python scripts/check_scb_compliance.py` + `python scripts/validate_trace.py --all` ;
   - synchro : `python scripts/factory_sync.py --check` ;
   - E2E : décompte passed/skipped du dernier run E2E (CI ou local) ;
   - dette : état des dettes ouvertes dans `BACKLOG.md` ; nb de scénarios Gherkin sans step-defs ;
   - process : nb d'US livrées hors workflow depuis le dernier audit (grep EVT_WORKFLOW_VIOLATION
     et EVT_WAIVER_GRANTED dans docs/trace/*/events.jsonl).

   **1 bis. Point de contrôle « enforcement de la branche principale » (axe Gouvernance — US-00.4 puis
   **US-00.7**, [ADR-007](../../docs/adr/ADR-007-application-protection-branche.md) *(remplace
   ADR-006)*) — OBLIGATOIRE, jamais silencieux.**

   ✅ **La protection est APPLIQUÉE depuis le 2026-07-28** (`"protected": true`, PR obligatoire, 4 status
   checks **REQUIS**, `enforce_admins` en vigueur ; effet prouvé par 3 refus serveur —
   `reports/US-00.7/applied_state/`). **Ce point de contrôle est CONSERVÉ et RÉORIENTÉ** : il ne porte
   plus la dette « `main` n'est pas protégée » (close), mais la **surveillance de sa PERSISTANCE** — qui
   est désormais **la seule barrière** contre une révocation silencieuse. Il est **manuel et hors CI**
   (droits **admin**, absents du `GITHUB_TOKEN`), **sans déclencheur calendaire**, et c'est **la dette la
   plus susceptible de pourrir** : sans lui, personne ne saurait que la protection a disparu.

   a. **Exécuter** — exige des droits **admin** sur le dépôt :
      ```
      python scripts/factory_sync.py --check-remote
      ```
      ⚠️ **Prérequis** : `gh` doit être joignable dans le `PATH` de la session (vérifier
      `gh --version` ; sous Windows l'installation standard est `C:\Program Files\GitHub CLI`).
      Sans `gh` **et** sans `GH_TOKEN`/`GITHUB_TOKEN`, la commande rend bien **2**, mais avec la cause
      « `gh` introuvable » **et non** l'état réel : **le constat attendu serait manqué**.

   b. **Consigner le code de sortie dans le rapport d'audit** — le code, pas une paraphrase :

      | Code | Lecture | Action obligatoire |
      |---|---|---|
      | **0** | ✅ **L'ÉTAT ATTENDU** : protection **conforme** à la cible générée. *(Obtenu en réel pour la première fois le 2026-07-28 — 12 champs alignés, 0 écart.)* | **Consigner le code.** ⚠️ Il vaut **à l'instant de la mesure** : il n'installe **aucune** surveillance continue. Vérifier tout de même **c**, **d** et **e** |
      | **1** | 🔴 **DÉRIVE** — protection absente ou divergente. **C'est une ALERTE** : quelqu'un a modifié ou supprimé la règle | **Ré-appliquer depuis la configuration** : `sh scripts/apply_branch_protection.sh gitgdx/Concentration` — jamais à la main dans l'interface. **Archiver les deux passages** (avant/après), tracer une ligne PROJECT_LOG et un événement |
      | **2** | 🔴 `VERIFICATION IMPOSSIBLE` — **ni un succès, ni un échec** : 403 de plan *(reviendrait si le dépôt repassait en privé)*, 403 de droits, 401, 404 non désambiguïsé, `gh` absent **et** aucun jeton, `MAPPING INCOMPLET` | **À SIGNALER**, cause **NOMMÉE**. ⛔ Jamais consigné comme un succès. ⛔ **Jamais** d'ajustement d'`INERT_GET_KEYS` ni du mapping « pour forcer le vert » |

      **Aucune de ces trois issues ne peut rester silencieuse.**

   c. **Vérifier que la VISIBILITÉ du dépôt n'a PAS changé** — c'est la **condition d'invalidation de
      tout l'édifice** : la protection n'est disponible que parce que le dépôt est **public** (voie (a),
      retenue le 2026-07-27). Un **retour en privé ⇒ retour du 403 ⇒ protection INDISPONIBLE ⇒ la
      dérogation `EVT_WAIVER_GRANTED` (US-00.4), aujourd'hui ÉTEINTE, redeviendrait OUVERTE** :
      ```
      gh api repos/gitgdx/Concentration --jq '{private, visibility, owner_type: .owner.type}'
      ```
      Attendu : **`{"private": false, "visibility": "public"}`**. Toute autre valeur est une **alerte de
      premier ordre** à remonter immédiatement. ⚠️ Rappel : ajouter un collaborateur ne change **rien** à
      cette condition. Détail : `docs/GIT_PROTECTION.md`.

   d. **Vérifier que les 4 LIBELLÉS RAPPORTÉS correspondent toujours aux 4 contextes requis** — un
      libellé divergent d'un seul caractère (emoji, sélecteur `U+FE0F`, espace, parenthèse) produit un
      contexte requis **jamais rapporté**, donc un **VERROUILLAGE** : plus aucune PR fusionnable,
      administrateur inclus.
      ```
      gh api repos/gitgdx/Concentration/branches/main/protection --jq '.required_status_checks.contexts'
      gh pr checks <n>      # sur une PR ouverte : les noms RÉELLEMENT rapportés
      ```
      Les deux listes doivent être **identiques caractère pour caractère**. Divergence ⇒ appliquer
      `docs/GIT_PROTECTION.md` §**Plan de retour arrière**, **sans tenter de fusionner**.

   e. **Réévaluer la condition de retour à `1` approbation** — `required_approving_review_count: 0`
      est un réglage **daté et conditionnel** (dépôt mono-collaborateur), **entièrement valable** :
      ```
      gh api repos/gitgdx/Concentration/collaborators --jq '[.[] | select(.permissions.push) | .login]'
      ```
      Si **≥ 2** comptes en écriture : **ouvrir une US** remettant
      `required_approving_review_count: 1` dans `factory.config.json` (ADR-006 décision 13, **conservée
      par ADR-007**). En dessous, consigner le décompte pour tracer que le contrôle a bien eu lieu.

   f. **Passer en revue les dettes que l'application n'a PAS closes** — elles sont listées dans
      `docs/GIT_PROTECTION.md` §Dettes : **#2** (aucune détection automatique de dérive), **#4**
      (`grandfathering_date`), **#5** (périmètre Art. 6 déclaré ≠ appliqué), **#7** (revue humaine du
      track FULL sans barrière machine), **#8** (ce point de contrôle lui-même, sans déclencheur
      calendaire), **#9** (repli `urllib` jamais exercé), **#10** (`NB-1bis`), **#11** (pas de `selftest`
      CI), **#12** (aucun événement d'extinction de dérogation + champ `emitter` non lu → **un agent peut
      émettre `EVT_WAIVER_GRANTED`**). ⛔ **Aucune ne doit être présentée comme close par effet de bord.**
2. **Comparer** avec `docs/audit/METRICS.md` (série temporelle) et le dernier rapport
   `docs/audit/AUDIT_METHODOLOGIE_*.md`.
3. **Produire** :
   - une nouvelle ligne dans `docs/audit/METRICS.md` ;
   - un rapport `docs/audit/AUDIT_METHODOLOGIE_YYYY-MM.md` : évolution par axe (Sécurité, CI/CD,
     Tests, Gouvernance, Traçabilité), constats nouveaux, recommandations priorisées ;
   - les lignes PROJECT_LOG correspondantes.
4. **Chercher les bonnes pratiques récentes** (WebSearch : spec-driven development, orchestration
   d'agents Claude Code) et signaler ce qui mériterait d'être adopté.
