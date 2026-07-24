---
description: Créer une nouvelle US complète (branche, Story File, SCB, Gherkin, trace) — élimine les story files rétroactifs
argument-hint: <EPIC_XX> <titre court de l'US>
---

Rituel de création d'US : $ARGUMENTS

Exécute dans l'ordre, en t'arrêtant à la première erreur :

1. **EPIC parent + ID** : lire `STORY_CERTIFICATION_BOARD.md` et `BACKLOG.md`, trouver le prochain
   numéro libre dans l'EPIC demandée (ex : EPIC_01 → US-01.2).
   **Prérequis EPIC (bloquant)** : vérifier que le fichier `docs/epics/EPIC_XX-*.md` existe. S'il
   manque, STOPPER le rituel et le faire créer par le subagent **product-owner** depuis
   `docs/epics/EPIC_FILE_TEMPLATE.md` (description/périmètre, table des Story Files, risques,
   critères de clôture) + l'ajouter à l'inventaire de `BACKLOG.md`, AVANT de poursuivre. Aucune US
   ne se crée dans une EPIC dépourvue de fichier EPIC.
2. **Track scale-adaptive** (voir `docs/governance/TRACKS.md`) : évaluer les critères objectifs
   (nb de fichiers estimé, migration de schéma ?, surface auth/sécurité/admin ?, nouvelle API ?) et
   proposer QUICK, STANDARD ou FULL. Demander confirmation à l'utilisateur si ambigu.
3. **Branche** : `git checkout -b feat/US-XX.X-description` (adapter le slug ; pattern imposé par branch-naming.yml).
4. **Story File** : créer `docs/stories/US-XX.X-<slug>.md` depuis `docs/stories/STORY_FILE_TEMPLATE.md`
   — déléguer la partie fonctionnelle (contexte métier, AC Nominal/Erreur/Limite, Gherkin) au
   subagent **product-owner**, la partie technique au subagent **architect**.
5. **Gherkin** : `tests/features/US-XX.X-<slug>.feature` (squelette des scénarios issus des AC).
6. **SCB** : ajouter la ligne (phase initiale, tout à ⏳ sauf PO Visa) + entrée "Détails des Visas".
7. **Gates avant développement** :
   - *clarify* : lister les ambiguïtés des AC → les résoudre avec l'utilisateur ;
   - *checklist* : la DoD du Story File est pré-remplie et réaliste ;
   - *analyze* : vérifier la cohérence Story File ↔ ADRs existants ↔ Constitution — signaler tout conflit.
8. **Trace** :
   `python scripts/trace_append.py --us US-XX.X --event EVT_STORY_CREATED --agent product-owner --model <modèle réel> --rationale "<titre>"`
   puis `EVT_TRACK_SELECTED` (agent architect, rationale = track + critères).
9. **PROJECT_LOG** : ajouter la ligne de création.

Termine par un récapitulatif : ID, track, branche, fichiers créés, prochaine étape du workflow.
