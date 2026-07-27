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

   **1 bis. Point de contrôle « enforcement de la branche principale » (axe Gouvernance — US-00.4,
   [ADR-006](../../docs/adr/ADR-006-protection-branche-principale.md)) — OBLIGATOIRE, jamais silencieux.**

   Ce point de contrôle est le **porteur de la dette** « `main` n'est pas protégée » : sans lui, le
   constat daté du 2026-07-26 pourrirait sans que personne ne le sache. Il est **manuel et hors CI**
   (droits **admin**, absents du `GITHUB_TOKEN`).

   a. **Exécuter** — exige des droits **admin** sur le dépôt :
      ```
      python scripts/factory_sync.py --check-remote
      ```
      ⚠️ **Prérequis** : `gh` doit être joignable dans le `PATH` de la session (vérifier
      `gh --version` ; sous Windows l'installation standard est `C:\Program Files\GitHub CLI`).
      Sans `gh` **et** sans `GH_TOKEN`/`GITHUB_TOKEN`, la commande rend bien **2**, mais avec la cause
      « `gh` introuvable » **et non** le 403 de plan : **le constat attendu serait manqué**.

   b. **Consigner le code de sortie dans le rapport d'audit** — le code, pas une paraphrase :

      | Code | Lecture | Action obligatoire |
      |---|---|---|
      | **2** | `VERIFICATION IMPOSSIBLE` (403 de plan au 2026-07-26) | **La dette reste OUVERTE** et doit être **SIGNALÉE**. ⛔ Jamais consigné comme un succès, **jamais** utilisé pour clore la dette |
      | **1** | **Dérive** (protection absente ou divergente) | Ré-appliquer **depuis la configuration** : `sh scripts/apply_branch_protection.sh` — jamais à la main dans l'interface |
      | **0** | Signifierait que la protection est applicable **et** appliquée — **issue JAMAIS obtenue sur ce dépôt à ce jour** | Le déblocage a eu lieu → exécuter le **test négatif serveur reporté** (US-00.4 T18 : push direct, force-push, suppression, depuis un clone jetable sans hooks et **sans** `--no-verify`) et revérifier le chemin **404** réel, jamais observé (R3) |

      **Aucune de ces trois issues ne peut rester silencieuse.**

   c. **Réévaluer la condition de déblocage** — la limitation porte sur le **plan** du compte **et**
      la **visibilité** du dépôt, **pas** sur le nombre de contributeurs (ajouter un collaborateur ne
      débloque rien) :
      ```
      gh api repos/gitgdx/Concentration --jq '{private, visibility, owner_type: .owner.type}'
      ```
      Deux voies, et seulement deux : dépôt **public** (coût nul, **exposition irréversible de
      l'historique complet**) ou **GitHub Pro** (dépôt privé conservé, **coût** par utilisateur et par
      mois). Engager l'une ou l'autre exige une **décision humaine explicite et tracée** — hors pouvoir
      d'un agent. Détail : `docs/GIT_PROTECTION.md` §Conditions de déblocage.

   d. **Réévaluer la condition de retour à `1` approbation** — `required_approving_review_count: 0`
      est un réglage **daté et conditionnel** (dépôt mono-collaborateur) :
      ```
      gh api repos/gitgdx/Concentration/collaborators --jq '[.[] | select(.permissions.push) | .login]'
      ```
      Si **≥ 2** comptes en écriture : **ouvrir une US** remettant
      `required_approving_review_count: 1` dans `factory.config.json` (ADR-006, décision 13). En
      dessous, consigner le décompte pour tracer que le contrôle a bien eu lieu.
2. **Comparer** avec `docs/audit/METRICS.md` (série temporelle) et le dernier rapport
   `docs/audit/AUDIT_METHODOLOGIE_*.md`.
3. **Produire** :
   - une nouvelle ligne dans `docs/audit/METRICS.md` ;
   - un rapport `docs/audit/AUDIT_METHODOLOGIE_YYYY-MM.md` : évolution par axe (Sécurité, CI/CD,
     Tests, Gouvernance, Traçabilité), constats nouveaux, recommandations priorisées ;
   - les lignes PROJECT_LOG correspondantes.
4. **Chercher les bonnes pratiques récentes** (WebSearch : spec-driven development, orchestration
   d'agents Claude Code) et signaler ce qui mériterait d'être adopté.
