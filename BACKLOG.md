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
| US-00.1 | Secrets & scan de dépôt | @DevOps + @CyberSecurity | `.gitleaks.toml` adapté au projet réel ; aucun secret en dur détecté ; rotation documentée si des valeurs de démo ont fuité |
| US-00.2 | Qualité statique de référence | @Developer | lint + typecheck + formatter exécutés sans erreur sur le squelette de l'adapter ; 0 règle désactivée sans justification |
| US-00.3 | Migrations réversibles | @DataEngineer | convention de migrations **réversibles** (versionnement monotone, contrat up/down, interdiction destructive RF-21, patron de test aller-retour), **agnostique de la techno** ; aucun schéma concret au Sprint 0 (persistance reportée à US-01.2 + ADR) — la convention y est appliquée et testée |
| US-00.4 | Enforcement `main` : constat + outillage (cible armée) — *re-cadrée le 2026-07-26* | @DevOps + @Architect | ⚠️ **AC initial devenu faux** (`apply_branch_protection.sh` exécuté et vérifié) : la protection de branche est **indisponible** sur ce dépôt privé (**403** « Upgrade to GitHub Pro or make this repository public » sur la protection classique **et** sur les rulesets). Périmètre re-cadré, dérogation humaine tracée (`EVT_WAIVER_GRANTED`) : constat daté de la cause racine ; `factory_sync.py --check` requalifié en vérification **DOCUMENTAIRE** ; `--check-remote` en lecture seule à 3 issues (dont *exit 2 = vérification impossible, jamais un succès*) ; cible de protection **déclarée et ARMÉE mais NON APPLIQUÉE** ; conditions de déblocage documentées ; point de contrôle `/audit-methodo`. 🔴 **`main` reste NON protégée — risque #2 d'EPIC_00 OUVERT.** |
| US-00.5 | ADR-001 stack + Constitution adaptée | @Architect | `docs/adr/ADR-001-*.md` documentant les choix de stack ; Constitution relue et ajustée si besoin |
| US-00.6 | Couverture initiale + ratchet | @QA_Tester | seuils de `factory.config.json` mesurés réellement sur le squelette ; premiers rapports dans `reports/US-00.6/` |
| US-00.7 | Protection `main` : application effective, preuve par l'effet, cohérence du corpus — *créée le 2026-07-27 après **déblocage***  | @DevOps + @Architect | **Le dépôt est passé en PUBLIC** → le 403 de plateforme est levé (`…/branches/main/protection` → **404 « Branch not protected »**, `…/rulesets` → **200 `[]`**). Reprend les tâches **T16→T19 d'US-00.4**, écrites pour ce moment : protection **réellement appliquée** depuis la source unique et prouvée par réponse brute (`"protected": true`) ; `--check-remote` → **exit 0 RÉEL** (et non plus simulé) ; **test négatif serveur** enfin exigible (push direct, force-push, suppression refusés **par le serveur**) ; 4 status checks réellement **BLOQUANTS**, admin inclus. Plus la **mise en cohérence du corpus** : 11 documents vivants affirment encore une impossibilité devenue **fausse**. Ferme les **risques #2 et #5 d'EPIC_00** et rend son critère de clôture **cochable**. Inclut la dette **NB-1** (le chemin `exit 0` devient une preuve, il doit être sûr avant). **ADR-007** obligatoire (ADR-006 est immuable et affirme le contraire). |

> **Alignement de nommage** : les IDs réels du Sprint 0 sont `US-00.1…US-00.6` (les libellés
> historiques `US-INIT-01…06` correspondaient aux mêmes chantiers).

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
