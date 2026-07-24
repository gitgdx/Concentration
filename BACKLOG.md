# 📊 Backlog & Analyse des Écarts — Concentration

## 1. Inventaire des EPICs

| EPIC | Nom | Priorité MoSCoW | Statut | Fichier EPIC |
|---|---|---|---|---|
| EPIC_00 | Fondations (Sprint 0) | Must-Have | ⏳ En cours | [EPIC_00-fondations.md](docs/epics/EPIC_00-fondations.md) |
| EPIC_01 | Module Échéances (MVP) | Must-Have | ⏳ En cours | [EPIC_01-module-echeances.md](docs/epics/EPIC_01-module-echeances.md) |

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

### EPIC_01 — Module Échéances (MVP)

> Premier module métier de l'application (PRD §1.3, §3.1). Matérialise le temps restant avant
> chaque échéance sous forme de tuiles épurées — un seul nombre nu, une couleur ambiante — pour
> ancrer la revue mentale sans charge de calcul. Chaque ligne devient une US via `/us-new`.

| US | Titre | Agent(s) | AC résumé |
|---|---|---|---|
| US-01.1 | Affichage Hub & grille d'échéances | Squad complète (@PO → @Architect → @UX + @Data → @Developer → @QA → @DevOps) — track FULL | Hub avec Échéances active + modules futurs (Respiration/Concentration) visibles mais grisés & non-interactifs (RF-20) ; grille de 1 à 9 tuiles, une par échéance active (RF-01, RF-15) ; nombre nu sans unité = `ceil` du temps restant dans l'unité adaptative interne (RF-02/03) ; couleur de fond sur gradient orange→bleu = proximité du prochain changement de nombre, sens non inversé (RF-04) ; état « à zéro » d'une tuile échue affichée & en attente, sans le geste de disparition (RF-06 partiel) ; tri par échéance croissante (RF-07) ; dark mode de référence & accessibilité (RNF-03/06). Données d'exemple injectées (les données réelles arrivent avec US-01.2). |
| US-01.2 | Gestion des événements (CRUD) | Squad complète (track à définir) | Création/édition/suppression d'une échéance : description obligatoire + date obligatoire + heure optionnelle (défaut 23:59) (RF-11/12/13) ; validation date dans le futur (RF-14) ; limite de 9 échéances actives, message à la 10ᵉ (RF-15) ; geste double-tap qui fait disparaître une tuile échue + animation + état « échu » consultable (RF-06) ; persistance locale offline-first (RNF-01/07). Fournit les données réelles consommées par US-01.1. |

## 3. Analyse des écarts

*(à compléter au fil de l'eau — écart entre le backlog et l'état réel du produit, mis à jour par
@ProductOwner à chaque revue de sprint)*
