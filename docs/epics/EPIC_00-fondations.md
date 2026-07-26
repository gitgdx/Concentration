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
- Convention de migrations réversibles (aller-retour up/down) établie ; aucune migration destructive
  par défaut, extensibilité des futurs modules préservée (RF-21).

## 👥 Rôles identifiés

| Rôle | Description |
|---|---|
| @DevOps | Secrets & scan de dépôt, CI, protection de branche. |
| @CyberSecurity | Revue des secrets, scan `gitleaks`, rotation. |
| @Developer | Qualité statique de référence (lint, typecheck, formatter). |
| @DataEngineer | Convention de migrations réversibles (versionnement, up/down, patron de test) — agnostique de la techno ; le premier schéma concret et son application relèvent de US-01.2. |
| @Architect | ADR-001 (stack) + relecture/ajustement de la Constitution. |
| @QA_Tester | Couverture initiale + ratchet, premiers rapports. |
| @ProductOwner | Cadrage du Sprint 0 (US-INIT), pas de valeur métier propre. |

## 📄 Story Files associés

> **Convention de nommage** : les chantiers du Sprint 0, initialement listés `US-INIT-01…06`, ont pour
> identifiants réels `US-00.1…US-00.6` (ex. `US-INIT-01` → **US-00.1**). Le SCB, le backlog et les Story
> Files utilisent désormais les IDs `US-00.x` ; le SCB et les Story Files font foi.

| US ID | Titre | Story File | Statut |
|---|---|---|---|
| US-INIT | Initialisation de la factory | _(bootstrap `init_factory.py` — voir SCB)_ | ⏳ development_start |
| US-00.1 (ex US-INIT-01) | Secrets & scan de dépôt | [US-00.1-secrets-scan-depot.md](../stories/US-00.1-secrets-scan-depot.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.2 (ex US-INIT-02) | Qualité statique de référence | [US-00.2-qualite-statique.md](../stories/US-00.2-qualite-statique.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.3 (ex US-INIT-03) | Migrations réversibles | [US-00.3-migrations-reversibles.md](../stories/US-00.3-migrations-reversibles.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.4 (ex US-INIT-04) | Enforcement `main` : constat + outillage (cible armée) — *re-cadrée le 2026-07-26* | [US-00.4-ci-protection-branche.md](../stories/US-00.4-ci-protection-branche.md) | ⏳ development_start (track STANDARD) |
| US-00.5 (ex US-INIT-05) | ADR-001 stack + Constitution adaptée | _(à créer via `/us-new`)_ | ⏳ à venir |
| US-00.6 (ex US-INIT-06) | Couverture initiale + ratchet | _(à créer via `/us-new`)_ | ⏳ à venir |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | Fuite de valeurs de démo dans l'historique lors de l'init. | Exposition de secrets factices/réels. | Scan `gitleaks` + rotation documentée (US-00.1). |
| 2 | Dérive entre `factory.config.json` et ses projections (CI, protection de branche, seuils). | Règles déclarées mais non enforced. | ~~`python scripts/factory_sync.py --check` (gate CI `governance`)~~ → **mitigation prouvée INSUFFISANTE**, voir #5. |
| 5 | **🔴 RISQUE #2 MATÉRIALISÉ *ET NON REFERMABLE SUR CE PLAN* (constaté le 2026-07-26)** : `main` n'est **pas protégée** (`"protected": false`) malgré une règle déclarée *enforced*. Les 4 status checks s'exécutent sans qu'aucun ne soit **requis**. **Double cause racine** : (a) `factory_sync.py --check` ne compare que des artefacts **documentaires** et **n'appelle jamais l'API** — il affichait « conforme (env, *protection*, …) » sur un dépôt grande ouverte ; (b) **la protection est INDISPONIBLE sur ce dépôt** — `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient un **403 « Upgrade to GitHub Pro or make this repository public »** (dépôt privé, jeton admin). `factory.config.json` déclarait donc depuis l'origine un enforcement que le compte **n'a jamais pu appliquer**. | Tous les gates qualité restent contournables par un merge ou un push direct ; la confiance dans `Certifié Prod` repose sur la **seule discipline** des intervenants. | ⚠️ **PARTIELLEMENT mitigé seulement.** **US-00.4 (re-cadrée)** traite la cause (a) — libellé `--check` honnête (*documentaire*), `--check-remote` en lecture seule à 3 issues dont *exit 2 = vérification impossible*, constat daté, cible **armée** non appliquée, conditions de déblocage documentées, point de contrôle `/audit-methodo`. Elle **ne traite PAS** la cause (b) : **dérogation humaine** tracée (`EVT_WAIVER_GRANTED`, Art. 5 — ni GitHub Pro, ni dépôt public). **CE RISQUE RESTE OUVERT.** Déblocage = dépôt public **ou** GitHub Pro, puis T16→T19 d'US-00.4. |
| 3 | Seuils de couverture arbitraires non mesurés sur le code réel. | Ratchet inopérant. | Mesure réelle sur le squelette (US-00.6). |
| 4 | **US-00.3 définit une convention de migrations réversibles alors que la techno de persistance est délibérément reportée à US-01.2** (`STACK_PROFILE.md §DataEngineer`) → aucun schéma concret à migrer au Sprint 0. | Convention potentiellement trop abstraite ou non appliquée ; « migration testée » non exécutable tel quel au Sprint 0. | Cadrer US-00.3 comme **convention/politique agnostique de la techno**, **appliquée** et dont le patron de test est **instancié** par US-01.2 ; interdiction de migration destructive par défaut (RF-21). |

## 🎯 Challenge PO : Un Sprint 0 sans valeur utilisateur mérite-t-il un EPIC ?

Oui — la traçabilité et la gouvernance de la factory exigent que même le bootstrap soit porté par un
EPIC et des US certifiables. EPIC_00 n'apporte pas de valeur *utilisateur final*, mais il apporte la
valeur *plateforme* (confiance, reproductibilité, sécurité) sans laquelle aucune US métier ne peut
être certifiée `Prod`. Décision : EPIC_00 conservé, priorité Must-Have, clôturé avant l'ouverture
d'EPIC_01 en développement.

## Critères de clôture de l'EPIC

- [ ] Toutes les US listées (US-INIT, US-00.1→US-00.6) sont `Certifié Prod = 🚀 OUI` (ou clôturées/justifiées dans le SCB) — *état au 2026-07-26 : **3 sur 6** (US-00.1, US-00.2, US-00.3)*
- [x] `ci.yml` vert sur une PR de test — ✅ démontré (PR #3/#6/#8/#9, CI 4/4 verte)
- [ ] 🔴 **Protection de branche vérifiée — IMPOSSIBLE À COCHER SUR CE PLAN.** Bloqué par un **403** de plateforme sur les deux mécanismes (dépôt privé ; cf. risque #5). **Dérogation humaine tracée** (`EVT_WAIVER_GRANTED`, US-00.4). ⚠️ **EPIC_00 ne peut donc PAS être déclarée complète** tant que ce critère n'est pas soit satisfait (dépôt public ou GitHub Pro → T16→T19 d'US-00.4), soit formellement retiré des critères de clôture par une décision humaine tracée. La certification d'US-00.4 **ne vaut pas** satisfaction de ce critère.
- [ ] ADR-001 (stack) publié et Constitution ajustée si besoin
- [ ] Convention de migrations réversibles documentée (US-00.3) et applicable par la première US de persistance (US-01.2)
- [ ] Seuils de couverture mesurés et ratchet actif
- [ ] Documentation à jour

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
