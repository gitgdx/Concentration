# EPIC 00 - Fondations (Sprint 0)

> **Priorité MoSCoW :** Must-Have
> **Dépendances amont :** — (chantier de bootstrap, initialise le dépôt)
> **Dépendances aval :** EPIC_01 — Module Échéances (MVP) et toutes les EPICs métier suivantes.

## 📝 Description de l'Epic

Chantier de fondations exécuté avant la première fonctionnalité métier (voir `docs/SQUAD_GUIDE.md`
§6.3 et le README du kit). Objectif : établir un socle sain et vérifiable — gestion des secrets,
qualité statique de référence, migrations réversibles, CI et protection de branche réelles, ADR de
stack + Constitution adaptée, couverture initiale avec ratchet. À l'issue de cet EPIC, la factory
est opérationnelle et chaque règle de gouvernance est effectivement *enforced*.

**HORS périmètre** : toute valeur métier utilisateur (matérialisation des échéances, tuiles, CRUD…)
qui relève d'EPIC_01 et suivants. EPIC_00 ne produit pas de fonctionnalité visible par l'utilisateur
final.

## ⚠️ Critères de performance et sécurité

- Aucun secret en dur détecté (`.gitleaks.toml` adapté au projet réel) ; rotation documentée si des
  valeurs de démo ont fuité.
- Lint + typecheck + formatter exécutés sans erreur sur le squelette de l'adapter ; 0 règle
  désactivée sans justification.
- `ci.yml` vert sur une PR de test ; protection de branche appliquée et vérifiée.
- Seuils de couverture de `factory.config.json` mesurés réellement sur le squelette (ratchet).

## 👥 Rôles identifiés

| Rôle | Description |
|---|---|
| @DevOps | Secrets & scan de dépôt, CI, protection de branche. |
| @CyberSecurity | Revue des secrets, scan `gitleaks`, rotation. |
| @Developer | Qualité statique de référence (lint, typecheck, formatter). |
| @DataEngineer | Premier schéma de données (si applicable) + migration réversible testée. |
| @Architect | ADR-001 (stack) + relecture/ajustement de la Constitution. |
| @QA_Tester | Couverture initiale + ratchet, premiers rapports. |
| @ProductOwner | Cadrage du Sprint 0 (US-INIT), pas de valeur métier propre. |

## 📄 Story Files associés

| US ID | Titre | Story File | Statut |
|---|---|---|---|
| US-INIT | Initialisation de la factory | _(bootstrap `init_factory.py` — voir SCB)_ | ⏳ development_start |
| US-INIT-01 | Secrets & scan de dépôt | _(à créer via `/us-new`)_ | ⏳ à venir |
| US-00.2 | Qualité statique de référence | [US-00.2-qualite-statique.md](../stories/US-00.2-qualite-statique.md) | ⏳ business_alignment |
| US-INIT-03 | Migrations réversibles | _(à créer via `/us-new`)_ | ⏳ à venir |
| US-INIT-04 | CI + protection de branche réelles | _(à créer via `/us-new`)_ | ⏳ à venir |
| US-INIT-05 | ADR-001 stack + Constitution adaptée | _(à créer via `/us-new`)_ | ⏳ à venir |
| US-INIT-06 | Couverture initiale + ratchet | _(à créer via `/us-new`)_ | ⏳ à venir |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | Fuite de valeurs de démo dans l'historique lors de l'init. | Exposition de secrets factices/réels. | Scan `gitleaks` + rotation documentée (US-INIT-01). |
| 2 | Dérive entre `factory.config.json` et ses projections (CI, protection de branche, seuils). | Règles déclarées mais non enforced. | `python scripts/factory_sync.py --check` (gate CI `governance`). |
| 3 | Seuils de couverture arbitraires non mesurés sur le code réel. | Ratchet inopérant. | Mesure réelle sur le squelette (US-INIT-06). |

## 🎯 Challenge PO : Un Sprint 0 sans valeur utilisateur mérite-t-il un EPIC ?

Oui — la traçabilité et la gouvernance de la factory exigent que même le bootstrap soit porté par un
EPIC et des US certifiables. EPIC_00 n'apporte pas de valeur *utilisateur final*, mais il apporte la
valeur *plateforme* (confiance, reproductibilité, sécurité) sans laquelle aucune US métier ne peut
être certifiée `Prod`. Décision : EPIC_00 conservé, priorité Must-Have, clôturé avant l'ouverture
d'EPIC_01 en développement.

## Critères de clôture de l'EPIC

- [ ] Toutes les US listées (US-INIT, US-INIT-01→06) sont `Certifié Prod = 🚀 OUI` (ou clôturées/justifiées dans le SCB)
- [ ] `ci.yml` vert sur une PR de test + protection de branche vérifiée
- [ ] ADR-001 (stack) publié et Constitution ajustée si besoin
- [ ] Seuils de couverture mesurés et ratchet actif
- [ ] Documentation à jour

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
