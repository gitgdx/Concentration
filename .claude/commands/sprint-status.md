---
description: Synthèse lecture seule de l'état du sprint (SCB + traces + conformité)
---

Rituel de synthèse d'état (LECTURE SEULE — ne modifie aucun fichier) :

1. `python scripts/check_scb_compliance.py` — état de conformité du SCB.
2. `python scripts/validate_trace.py --all` — état de la traçabilité.
3. `python scripts/factory_sync.py --check` — synchro **DOCUMENTAIRE** config ↔ projections
   (`factory_env.sh`, bloc `GIT_PROTECTION.md`, libellés de jobs, seuils). ⚠️ **N'appelle JAMAIS l'API
   GitHub** : un vert ici **n'atteste PAS** que la branche principale est protégée — cette distinction
   reste entière. Pour l'état réel : `python scripts/factory_sync.py --check-remote` (droits admin, hors
   CI). **Depuis le 2026-07-28 la protection est APPLIQUÉE : `exit 0` est l'ÉTAT ATTENDU.**
   Ne rapporter « protection conforme » **que** sur un `exit 0` de `--check-remote` — jamais sur le vert
   de `--check`. Tout **exit ≠ 0** est une **alerte à remonter** : `exit 1` = **dérive** (règle modifiée
   ou supprimée → ré-appliquer depuis la config), `exit 2` = **vérification impossible**, cause à
   **nommer**, jamais un succès. Vérifier aussi que la **visibilité** du dépôt est toujours **publique**
   (un retour en privé rendrait la protection indisponible). Détail : `docs/GIT_PROTECTION.md` ·
   [ADR-007](../../docs/adr/ADR-007-application-protection-branche.md) *(remplace ADR-006)*.
4. Lire `STORY_CERTIFICATION_BOARD.md` et la section "État courant du projet" de `CLAUDE.md`.
5. Lire les 10 dernières lignes du tableau `PROJECT_LOG.md`.

Produis une synthèse :
- US par phase (tableau court : à designer / en dev / en audit / en QA / à déployer / certifiées) ;
- blocages et US en attente d'action (avec l'agent requis) ;
- violations de conformité éventuelles ;
- dettes ouvertes et prochaine action recommandée.
