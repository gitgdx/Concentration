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
  - *Précision ([ADR-008](../adr/ADR-008-arbitrages-track-full.md), 2026-08-01) : « pas de N/A » **tient**.
    Une US sans persistance livre un **Design Data borné** — entité, invariants, ordre de tri, sans
    schéma ni migration — plutôt qu'un `N/A`. **La clause n'est PAS assouplie.***
- **Scénarios E2E dédiés implémentés** (pas seulement des unitaires) avant certification.
  - *Précision ([ADR-008](../adr/ADR-008-arbitrages-track-full.md), 2026-08-01) : pour une application
    **offline-first sans backend**, un test qui **monte l'application entière** et agit sur elle satisfait
    la clause — **il n'existe aucun « autre bout »** que l'arbre de widgets. Ces tests vivent dans `test/`,
    donc **le gate `flutter test --coverage` les exécute** ; un harnais sur appareil n'ajouterait aucune
    couche réelle à traverser et **ne rapporterait rien à la couverture**. **Contrainte attachée** : la
    correspondance **scénario ↔ test** est **vérifiée par machine** (tout titre de scénario doit apparaître
    **verbatim** dans un nom de test ; manquant **ou** orphelin ⇒ échec), jamais déclarée. ⚠️ **À
    réexaminer dès qu'une persistance réelle existe** (US-01.2) : un E2E sans base ne dira plus rien de
    l'app entière — **ADR à remplacer, pas à étendre par habitude**.*
- **Attestation humaine datée de la revue de la PR, avant fusion** — ⚠️ **obligation de PROCESS, NON
  enforced : aucune barrière machine ne la soutient sur ce dépôt.**
  - ⛔ **PÉRIMÉ-2026-08-01 — la formulation antérieure était « Revue humaine explicite de la PR
    (l'approbation GitHub ne peut pas venir d'un agent) »**, ce qui laissait croire à une barrière
    inexistante. **Mesuré** : la cible de protection porte `required_approving_review_count: 0`, et sur un
    dépôt à **un seul compte** GitHub **interdit à l'auteur d'approuver sa propre PR** ⇒ `reviewDecision`
    **reste vide** ; `mergedBy.is_bot` rend **`false` même pour un agent**. Reformulée par
    [ADR-008](../adr/ADR-008-arbitrages-track-full.md) pour dire **ce qui est tenu**, et rien de plus.
  - ⛔ **Cette reformulation ne lève PAS le critère 27 d'US-00.7** et **ne crée aucune garantie** — elle
    **abaisse l'exigence écrite au niveau du réel**. La voie de sortie *(identité distincte pour les
    agents, puis `restrictions` ⇒ fusion par un agent **impossible** et non seulement interdite)* est
    portée par **US-00.8**, réserve non levée incluse : `restrictions` pourrait être réservé aux dépôts
    d'organisation.

## Traçabilité

`EVT_TRACK_SELECTED` doit précéder `EVT_CODE_READY` dans la trace. Le rituel `/audit-methodo`
compte les US par track et vérifie a posteriori que les critères ont été respectés (une US QUICK
qui a touché 12 fichiers est une violation à signaler).
