# 📊 Backlog & Analyse des Écarts — Concentration

## 1. Inventaire des EPICs

| EPIC | Nom | Priorité MoSCoW | Statut |
|---|---|---|---|
| EPIC_00 | Fondations (Sprint 0) | Must-Have | ⏳ En cours |

## 2. Détail par EPIC

### EPIC_00 — Fondations (Sprint 0)

> Chantier recommandé avant la première fonctionnalité métier — voir
> `docs/SQUAD_GUIDE.md` §6.3 et le README du kit. Chaque ligne devient une US via `/us-new`.

| US | Titre | Agent(s) | AC résumé |
|---|---|---|---|
| US-INIT-01 | Secrets & scan de dépôt | @DevOps + @CyberSecurity | `.gitleaks.toml` adapté au projet réel ; aucun secret en dur détecté ; rotation documentée si des valeurs de démo ont fuité |
| US-INIT-02 | Qualité statique de référence | @Developer | lint + typecheck + formatter exécutés sans erreur sur le squelette de l'adapter ; 0 règle désactivée sans justification |
| US-INIT-03 | Migrations réversibles | @DataEngineer | premier schéma de données (si applicable) versionné, migration testée upgrade/downgrade |
| US-INIT-04 | CI + protection de branche réelles | @DevOps | `ci.yml` vert sur une PR de test ; `sh scripts/apply_branch_protection.sh` exécuté et vérifié |
| US-INIT-05 | ADR-001 stack + Constitution adaptée | @Architect | `docs/adr/ADR-001-*.md` documentant les choix de stack ; Constitution relue et ajustée si besoin |
| US-INIT-06 | Couverture initiale + ratchet | @QA_Tester | seuils de `factory.config.json` mesurés réellement sur le squelette ; premiers rapports dans `reports/US-INIT-06/` |

## 3. Analyse des écarts

*(à compléter au fil de l'eau — écart entre le backlog et l'état réel du produit, mis à jour par
@ProductOwner à chaque revue de sprint)*
