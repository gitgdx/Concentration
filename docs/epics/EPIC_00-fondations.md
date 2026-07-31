# EPIC 00 - Fondations (Sprint 0)

> **Priorité MoSCoW :** Must-Have
> **Dépendances amont :** — (chantier de bootstrap, initialise le dépôt)
> **Dépendances aval :** EPIC_01 — Module Échéances (MVP) et toutes les EPICs métier suivantes.

## 📝 Description de l'Epic

Chantier de fondations exécuté avant la première fonctionnalité métier (voir `docs/SQUAD_GUIDE.md`
§6.3 et le README du kit). Objectif : établir un socle sain et vérifiable — gestion des secrets,
qualité statique de référence, migrations réversibles, CI et protection de branche réelles, ADR de
stack + Constitution adaptée, couverture initiale avec ratchet. À l'issue de cet EPIC, la factory
est opérationnelle et chaque règle de gouvernance dispose d'un mécanisme d'application vérifiable.

> ⚠️ **Formulation bornée, volontairement.** L'objectif ci-dessus ne dit **pas** « toutes les règles sont
> enforced » : plusieurs obligations de la factory restent **de process, sans barrière machine** (revue
> humaine du track FULL, émetteurs d'événements déclarés mais non lus, extinction d'une dérogation
> impossible dans le catalogue). Elles sont **nommées** comme dettes dans `CLAUDE.md` §Dettes ouvertes —
> jamais présentées comme résolues.

> ✅ **Réserve du 2026-07-26 — LEVÉE le 2026-07-28 par US-00.7.** *(La réserve, ajoutée le 2026-07-26
> après un balayage par motif, était **exacte à sa date** : elle est conservée ici sous forme historisée,
> et non supprimée.)* **Ce qui a changé** : le dépôt a été rendu **PUBLIC** le **2026-07-27** (décision
> humaine, Art. 5 — voie (a) des conditions de déblocage d'ADR-006), et la protection de la branche
> principale a été **APPLIQUÉE le 2026-07-28** depuis la source unique. La règle « jamais de push direct
> sur la branche principale » est désormais **enforced par la plateforme** : `"protected": true`, **PR
> obligatoire**, **4 status checks REQUIS**, `enforce_admins` en vigueur (`enforcement_level: "everyone"`),
> et **3 refus émis par le serveur** depuis un clone sans hooks. Preuves brutes datées :
> [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/) · décision :
> [ADR-007](../adr/ADR-007-application-protection-branche.md) *(remplace
> [ADR-006](../adr/ADR-006-protection-branche-principale.md))*. **EPIC_00 redevient complétable** — il
> reste US-00.5 et US-00.6, plus les critères de clôture non encore satisfaits ci-dessous.
> ⚠️ **Conditionnel** : l'édifice dépend de la **visibilité publique** du dépôt ; un retour en privé
> ramènerait le **403** et rouvrirait cette réserve.

**HORS périmètre** : toute valeur métier utilisateur (matérialisation des échéances, tuiles, CRUD…)
qui relève d'EPIC_01 et suivants. EPIC_00 ne produit pas de fonctionnalité visible par l'utilisateur
final.

## ⚠️ Critères de performance et sécurité

- Aucun secret en dur détecté (`.gitleaks.toml` adapté au projet réel) ; rotation documentée si des
  valeurs de démo ont fuité.
- Lint + typecheck + formatter exécutés sans erreur sur le squelette de l'adapter ; 0 règle
  désactivée sans justification.
- `ci.yml` vert sur une PR de test ✅ *(démontré — PR #3/#6/#8/#9, CI 4/4 verte)*.
- ✅ **Protection de branche appliquée et vérifiée** — appliquée le **2026-07-28** (US-00.7) depuis la
  source unique `factory.config.json`, via `scripts/apply_branch_protection.sh` consommant le payload
  **généré** ; vérifiée par `python scripts/factory_sync.py --check-remote` → **exit 0 réel** (12 champs
  alignés, 0 écart) et par **3 refus serveur** archivés. Preuves :
  [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/).
  *(Historique de cette ligne : barrée le 2026-07-26 comme « NON ATTEIGNABLE » — 403 de plateforme, dépôt
  privé — puis **rétablie le 2026-07-28** après le déblocage par passage du dépôt en public. Les deux
  états étaient exacts à leur date.)*
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
| US-00.4 (ex US-INIT-04) | Enforcement `main` : constat + outillage (cible armée) — *re-cadrée le 2026-07-26* | [US-00.4-ci-protection-branche.md](../stories/US-00.4-ci-protection-branche.md) | 🚀 **Certifiée Prod** (2026-07-27) — *son libellé « cible armée » reste **exact à sa date** : elle a livré l'outillage et le constat, **pas** l'application* |
| US-00.5 (ex US-INIT-05) | **ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution** | [US-00.5-adr-stack-constitution.md](../stories/US-00.5-adr-stack-constitution.md) | 🚀 **Certifiée Prod (2026-07-31)** — **DoD 23/23** · **21 critères exercés → 21 passés** · **6 gates `/certify` verts**. Livrée en **DEUX PR**, la seconde **DÉDIÉE** comme l'exige la clause de *Révision* : **#17** *(ADR-001)* et **#18** *(Art. 4, Constitution **1.0 → 1.1**)*. ⚠️ **Ce qu'elle n'atteste pas** : l'amendement **ne crée aucun gate** — il **nomme** les dettes *(aucun **SAST** applicatif → US-00.8 · aucun scan de CVE · `coverage_ratchet` **non implémenté** pour cet adapter → **US-00.6**)* · l'attestation humaine de l'amendement est **déclarative** · **0 fichier Dart** touché. 🎓 Elle laisse l'acquis de méthode le plus important du projet : [`tension_structurelle.md`](../../reports/US-00.5/tension_structurelle.md) — **six instruments de contrôle faux, trois de chaque côté**, et la cause enfin nommée |
| US-00.6 (ex US-INIT-06) | Couverture initiale + ratchet | _(à créer via `/us-new`)_ | ⏳ à venir |
| **US-00.7** | **Protection de la branche principale : application effective, preuve par l'effet, cohérence du corpus** | [US-00.7-application-protection-branche.md](../stories/US-00.7-application-protection-branche.md) | 🚀 **Certifiée Prod (2026-07-30)** — *(**PÉRIMÉ-2026-07-30** : cette case portait « 🔨 en cours »)*. Track **STANDARD + 3** renforcements ; US **non prévue au découpage initial**, créée le 2026-07-27 après le déblocage. **DoD 34/34** · **QA `🧪 PASS` au 6ᵉ passage, après 5 `FAIL`** · **6 gates `/certify` verts** · PR **#15** et **#16** fusionnées **par l'humain**. ⚠️ **Ce que la certification n'atteste pas** : critères **20, 21, 27** demeurent **NON LEVÉS** *(plateforme, jamais requalifiés)* · refus prouvé sur contextes **`expected`, pas `failing`** · **aucune détection de dérive** · **conditionnel à la visibilité PUBLIQUE** du dépôt |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | Fuite de valeurs de démo dans l'historique lors de l'init. | Exposition de secrets factices/réels. | Scan `gitleaks` + rotation documentée (US-00.1). |
| 2 | Dérive entre `factory.config.json` et ses projections (CI, protection de branche, seuils). | Règles déclarées mais non enforced. | ✅ **CLOS le 2026-07-28 (US-00.7)** — voir #5. La protection déclarée dans `factory.config.json` est désormais **appliquée** et **vérifiée champ par champ** contre l'API (`--check-remote` → **exit 0 réel**, 12 champs alignés, 0 écart) : la projection « protection de branche » n'est plus une déclaration sans effet. *(⚠️ **Ne pas surinterpréter** : la **détection automatique** de dérive reste **absente** — `--check-remote` exige des droits admin, hors CI. Dette maintenue OUVERTE, portée par `/audit-methodo`.)* |
| 5 | **🔴 RISQUE #2 MATÉRIALISÉ *ET NON REFERMABLE SUR CE PLAN* (constaté le 2026-07-26)** : `main` n'est **pas protégée** (`"protected": false`) malgré une règle déclarée *enforced*. Les 4 status checks s'exécutent sans qu'aucun ne soit **requis**. **Double cause racine** : (a) `factory_sync.py --check` ne compare que des artefacts **documentaires** et **n'appelle jamais l'API** — il affichait « conforme (env, *protection*, …) » sur un dépôt grande ouverte ; (b) **la protection est INDISPONIBLE sur ce dépôt** — `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient un **403 « Upgrade to GitHub Pro or make this repository public »** (dépôt privé, jeton admin). `factory.config.json` déclarait donc depuis l'origine un enforcement que le compte **n'a jamais pu appliquer**. | Tous les gates qualité restent contournables par un merge ou un push direct ; la confiance dans `Certifié Prod` repose sur la **seule discipline** des intervenants. | ✅ **CLOS le 2026-07-28 par US-00.7 — les DEUX causes sont traitées.** *(Le constat du 2026-07-26 et l'expression « NON REFERMABLE SUR CE PLAN » étaient **exacts à leur date** : ils sont conservés ci-contre, non réécrits — c'est **le plan qui a changé**.)* **Cause (a)** : traitée par **US-00.4** (certifiée le 2026-07-27) — libellé `--check` honnête (*documentaire*), `--check-remote` en lecture seule à 3 issues, constat daté, conditions de déblocage documentées, point de contrôle `/audit-methodo`. **Cause (b)** : levée le **2026-07-27** par une décision humaine (Art. 5) — **dépôt rendu PUBLIC**, voie (a) → `…/protection` passe de **403** à **404** (« *Branch not protected* » : **disponible**, non appliquée), `…/rulesets` à **200 `[]`** ; puis **protection APPLIQUÉE le 2026-07-28** (`"protected": true`, PR obligatoire, **4 checks REQUIS**, `enforce_admins` → `enforcement_level: "everyone"`), **effet prouvé par 3 refus SERVEUR** depuis un clone sans hooks. Preuves : [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/) · [ADR-007](../adr/ADR-007-application-protection-branche.md) *(remplace ADR-006)*. 🔕 **Dérogation `EVT_WAIVER_GRANTED` (2026-07-26, US-00.4, Art. 5) — ÉTEINTE / SANS OBJET** : elle portait sur « **ni GitHub Pro, ni dépôt public** » ; l'humain a choisi le **dépôt public**, son motif **n'existe plus**. ⛔ La trace reste **append-only** — on **éteint** une dérogation, on ne l'**effface** pas ; l'extinction est **DOCUMENTAIRE**, aucun des 25 événements du catalogue ne permettant de l'éteindre (**dette du système de traçabilité**, nommée dans `CLAUDE.md`). ⚠️ **Conditionnel** : un retour du dépôt **en privé** ramènerait le **403** et **rouvrirait ce risque ET la dérogation**. |
| 3 | Seuils de couverture arbitraires non mesurés sur le code réel. | Ratchet inopérant. | Mesure réelle sur le squelette (US-00.6). |
| 4 | **US-00.3 définit une convention de migrations réversibles alors que la techno de persistance est délibérément reportée à US-01.2** (`STACK_PROFILE.md §DataEngineer`) → aucun schéma concret à migrer au Sprint 0. | Convention potentiellement trop abstraite ou non appliquée ; « migration testée » non exécutable tel quel au Sprint 0. | Cadrer US-00.3 comme **convention/politique agnostique de la techno**, **appliquée** et dont le patron de test est **instancié** par US-01.2 ; interdiction de migration destructive par défaut (RF-21). |

## 🎯 Challenge PO : Un Sprint 0 sans valeur utilisateur mérite-t-il un EPIC ?

Oui — la traçabilité et la gouvernance de la factory exigent que même le bootstrap soit porté par un
EPIC et des US certifiables. EPIC_00 n'apporte pas de valeur *utilisateur final*, mais il apporte la
valeur *plateforme* (confiance, reproductibilité, sécurité) sans laquelle aucune US métier ne peut
être certifiée `Prod`. Décision : EPIC_00 conservé, priorité Must-Have, clôturé avant l'ouverture
d'EPIC_01 en développement.

## Critères de clôture de l'EPIC

- [ ] Toutes les US listées (US-INIT, US-00.1→US-00.6, **US-00.7**) sont `Certifié Prod = 🚀 OUI` (ou clôturées/justifiées dans le SCB) — *(**PÉRIMÉ-2026-07-31** : l'état antérieur disait « **5 sur 7** »)*. **État au 2026-07-31 : 6 sur 7** — US-00.1, US-00.2, US-00.3, US-00.4, **US-00.5 🚀** et **US-00.7 🚀**. ⛔ **NE RESTE QUE US-00.6** *(couverture + ratchet)*, plus le **statut d'`US-INIT` à clarifier*
- [x] `ci.yml` vert sur une PR de test — ✅ démontré (PR #3/#6/#8/#9, CI 4/4 verte)
- [x] ✅ **Protection de branche vérifiée** — **cochée le 2026-07-28 (US-00.7)**. Appliquée depuis la source unique le 2026-07-28 après le déblocage du 2026-07-27 (dépôt **public**, Art. 5) : `"protected": true` · **PR obligatoire** · **4 status checks REQUIS** · `enforce_admins` (`enforcement_level: "everyone"`) · **exit 0 réel** de `--check-remote` (12 champs alignés, 0 écart) · **3 refus SERVEUR** archivés (clone sans hooks). Preuves : [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/) ; décision : [ADR-007](../adr/ADR-007-application-protection-branche.md). *(Ce critère était marqué « IMPOSSIBLE À COCHER SUR CE PLAN » au 2026-07-26 — **exact à sa date**, le plan ayant changé depuis. La certification d'US-00.4 ne valait **pas** satisfaction de ce critère : c'est bien US-00.7 qui le lève.)* ⚠️ **Ce qui n'est pas coché pour autant** : la **détection automatique** de dérive (contrôle **manuel**, hors CI) et la **persistance** de l'état — un administrateur peut révoquer la règle sans qu'aucun mécanisme ne le signale. **Conditionnel à la visibilité publique du dépôt.**
- [x] **ADR-001 (stack) publié ET Constitution ajustée** — ✅ **COCHÉ le 2026-07-31, les DEUX moitiés livrées sur `main`** : **ADR-001** *(PR #17, `488b074`)* et **Constitution `1.0` → `1.1`** *(PR #18, `c62cdcc`, **PR dédiée** exigée par la clause de Révision — diff = 2 fichiers)*. Les deux fusionnées **par l'humain, sans `--admin`**. ⚠️ **Ce que le critère n'atteste pas** : l'amendement **ne crée aucun gate** — il fait dire à l'Art. 4 ce qui **est** et **nomme les dettes** *(aucun SAST applicatif → US-00.8 · aucun scan de CVE · `coverage_ratchet` **non implémenté** pour cet adapter → **US-00.6**)*. ⏳ **US-00.5 n'est pas encore certifiée** : DoD **21/23**, restent l'**attestation humaine de l'amendement** et le **`QA Status 🧪 PASS`** — *état au **2026-07-30** (US-00.5, **PR nº 1**)* : ✅ **`docs/adr/ADR-001-choix-de-stack.md` est PUBLIÉ**, statut `Accepté`, numéro **rétroactif assumé** *(décision du 2026-07-24, tracée le 2026-07-30)*, portant les **4 honnêtetés dures** *(iOS non scaffoldé · build Android non validé · `deps_audit` = obsolescence et non vulnérabilité, non bloquant · **aucun SAST**)*. ⏳ **La seconde moitié reste due** : l'**amendement de l'Art. 4** part en **PR nº 2 DÉDIÉE**, la clause *Révision* de la Constitution exigeant une « **PR dédiée, jamais en side-effect d'une US** ». **Ce critère ne sera cochable qu'après la fusion de cette seconde PR.**
- [ ] Convention de migrations réversibles documentée (US-00.3) et applicable par la première US de persistance (US-01.2)
- [ ] Seuils de couverture mesurés et ratchet actif
- [ ] Documentation à jour

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
