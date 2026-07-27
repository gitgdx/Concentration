---
description: Synthèse lecture seule de l'état du sprint (SCB + traces + conformité)
---

Rituel de synthèse d'état (LECTURE SEULE — ne modifie aucun fichier) :

1. `python scripts/check_scb_compliance.py` — état de conformité du SCB.
2. `python scripts/validate_trace.py --all` — état de la traçabilité.
3. `python scripts/factory_sync.py --check` — synchro **DOCUMENTAIRE** config ↔ projections
   (`factory_env.sh`, bloc `GIT_PROTECTION.md`, libellés de jobs, seuils). ⚠️ **N'appelle JAMAIS l'API
   GitHub** : un vert ici **n'atteste PAS** que la branche principale est protégée. Pour l'état réel :
   `python scripts/factory_sync.py --check-remote` (droits admin, hors CI) — **exit 2 = vérification
   impossible, à signaler, jamais un succès**. Au 2026-07-26 la protection est **indisponible** sur ce
   dépôt (403 de plan, cf. ADR-006) : ne pas rapporter « protection conforme ».
4. Lire `STORY_CERTIFICATION_BOARD.md` et la section "État courant du projet" de `CLAUDE.md`.
5. Lire les 10 dernières lignes du tableau `PROJECT_LOG.md`.

Produis une synthèse :
- US par phase (tableau court : à designer / en dev / en audit / en QA / à déployer / certifiées) ;
- blocages et US en attente d'action (avec l'agent requis) ;
- violations de conformité éventuelles ;
- dettes ouvertes et prochaine action recommandée.
