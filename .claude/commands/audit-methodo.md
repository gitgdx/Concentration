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
2. **Comparer** avec `docs/audit/METRICS.md` (série temporelle) et le dernier rapport
   `docs/audit/AUDIT_METHODOLOGIE_*.md`.
3. **Produire** :
   - une nouvelle ligne dans `docs/audit/METRICS.md` ;
   - un rapport `docs/audit/AUDIT_METHODOLOGIE_YYYY-MM.md` : évolution par axe (Sécurité, CI/CD,
     Tests, Gouvernance, Traçabilité), constats nouveaux, recommandations priorisées ;
   - les lignes PROJECT_LOG correspondantes.
4. **Chercher les bonnes pratiques récentes** (WebSearch : spec-driven development, orchestration
   d'agents Claude Code) et signaler ce qui mériterait d'être adopté.
