# 🛤️ Tracks scale-adaptive

> Ne pas forcer chaque tâche dans le process lourd — proportionner le workflow au risque.
> Le track est choisi à la création de l'US (`/us-new`), sur critères **objectifs**, et tracé
> `EVT_TRACK_SELECTED` (rationale = critères déclencheurs). En cas de doute entre deux tracks,
> prendre le plus lourd.

## Critères de sélection

| Critère | QUICK | STANDARD | FULL |
|---|---|---|---|
| Fichiers de code impactés (estimés) | ≤ 3 | ≤ 15 | illimité |
| Migration / changement de schéma de données | non | possible | oui |
| Surface auth / sécurité / admin / paiement | non | non | oui |
| Nouvelle API publique ou nouvelle page | non | oui | oui |
| Nouvelle EPIC / refonte transverse | non | non | oui |

## Track QUICK — correction simple

- **Workflow** : @Developer direct → CI complète sur PR → merge.
- **Obligations** : ligne PROJECT_LOG + trailer `US:` (l'US du bug d'origine, ou `US: none — hotfix <desc>`),
  test de non-régression ajouté.
- **Pas de** : Story File dédié, design, audits individuels — un audit **groupé a posteriori**
  (`/audit-us` sur le lot) est déclenché toutes les ~5 corrections QUICK ou avant toute release.

## Track STANDARD — US classique

- **Workflow complet** : PO (Story File + Gherkin) → Architect (validation + Integration Lock) →
  Developer → `/audit-us` (Rev + Sec parallèles, contextes frais) → QA → DevOps → `/certify`.
- Design Data/UX : requis seulement si schéma/UI touchés (sinon `N/A` justifié dans le SCB).

## Track FULL — haut risque

Tout STANDARD **plus** :
- **ADR obligatoire** pour chaque décision structurante (`docs/adr/`).
- Design Data ET UX obligatoires (pas de N/A).
- Scénarios E2E dédiés implémentés (pas seulement des unitaires) avant certification.
- Revue humaine explicite de la PR (l'approbation GitHub ne peut pas venir d'un agent).

## Traçabilité

`EVT_TRACK_SELECTED` doit précéder `EVT_CODE_READY` dans la trace. Le rituel `/audit-methodo`
compte les US par track et vérifie a posteriori que les critères ont été respectés (une US QUICK
qui a touché 12 fichiers est une violation à signaler).
