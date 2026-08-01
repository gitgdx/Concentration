# EPIC 00 - Fondations (Sprint 0)

> ## ✅ EPIC CLOS le 2026-08-01
>
> **US-00.1 → US-00.7 sont certifiées `Prod 🚀`** et `US-INIT` est **clôturée sans objet propre**
> *(porteur de bootstrap, périmètre absorbé)*. **Tous les critères de clôture ci-dessous sont cochés**,
> dont **un sur sa seule 1ʳᵉ moitié** — le **nº 112**, à cheval sur EPIC_01, **transféré et daté**.
> **Risques : #1, #2, #3 et #5 CLOS · #4 TRANSFÉRÉ, donc encore OUVERT.**
>
> ⛔ **Aucun décompte n'est écrit dans cet encadré, et c'est délibéré** : la première rédaction annonçait
> « **6 critères** » là où la liste en porte **sept** — soit, **dans le paragraphe même qui clôt l'EPIC**,
> la classe de défaut que `CLAUDE.md` désigne comme **la plus active du projet** *(« une assertion chiffrée
> écrite à la main à côté d'une commande, jamais relue dans sa sortie »)*. Elle a été **retirée, pas mise à
> jour** — *une valeur corrigée périme au cycle suivant ; une liste qu'on énumère, non.* **Le décompte se
> lit dans la liste**, seule source.
>
> ⛔ **CE QUE LA CLÔTURE NE DIT PAS, et qui doit rester lisible** : la factory n'a **jamais tourné sur du
> code produit**. À la clôture, `lib/` compte **1 fichier de 63 lignes** *(19 mesurables)* et `test/` **1
> fichier** ; les **8 fichiers `.feature` n'ont ni step definition ni runner** ⇒ **aucun scénario Gherkin
> du projet n'a jamais été exécuté**. Les **7 certifications attestent des INSTRUMENTS** — chacune porte la
> mention « **0 fichier Dart touché** ». Le cliquet de couverture n'a **jamais refusé une régression
> réelle** *(5 fixtures)*. **La preuve que ce socle fonctionne viendra d'US-01.1, pas d'ici.**
>
> 📌 **Aucun événement de clôture n'est tracé, et c'est un CONSTAT, pas un oubli** : les **25** événements
> du catalogue n'en comportent **aucun** pour clore un EPIC *(même famille structurelle que l'extinction de
> dérogation, déjà nommée comme dette)*. ⛔ **`EVT_DOCS_UPDATED` n'a PAS été détourné** — son `emitter`
> déclaré est `tech-writer` — et **aucune dérogation n'est émise pour un acte documentaire**. Précédent
> suivi : l'amendement de l'Art. 4 du 2026-08-01. La clôture vit donc dans le **corpus durable**
> *(ce fichier, le SCB, le PROJECT_LOG)*.

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
| US-INIT | Initialisation de la factory | _(bootstrap `init_factory.py` — voir SCB)_ | ✅ **CLÔTURÉE SANS OBJET PROPRE le 2026-08-01** — *(**PÉRIMÉ-2026-08-01** : cette case portait « ⏳ development_start »)*. **Arbitrage humain** : `US-INIT` est un **porteur de bootstrap**, ses 6 chantiers `US-INIT-01…06` **sont devenus** US-00.1…US-00.6 *(voir la convention de nommage ci-dessus)*, elle n'a **aucun périmètre résiduel**. **Constat vérifié, non supposé** : **aucun Story File** *(un rétroactif est **interdit** par le rituel `/us-new`)*, et sa trace `docs/trace/US-INIT/events.jsonl` **s'arrête à `EVT_DESIGN_COMPLETED` le 2026-07-24** — ni `EVT_CODE_READY`, ni audit, ni QA. ⛔ **Elle n'est PAS certifiée et ne le sera jamais** : la certifier serait une **auto-certification rétroactive**, l'anti-pattern nº 1 du projet. 📌 **Le critère 108 prévoit ce cas dans sa propre lettre** *(« ou **clôturées/justifiées dans le SCB** »)* ⇒ **aucune dérogation n'est requise** |
| US-00.1 (ex US-INIT-01) | Secrets & scan de dépôt | [US-00.1-secrets-scan-depot.md](../stories/US-00.1-secrets-scan-depot.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.2 (ex US-INIT-02) | Qualité statique de référence | [US-00.2-qualite-statique.md](../stories/US-00.2-qualite-statique.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.3 (ex US-INIT-03) | Migrations réversibles | [US-00.3-migrations-reversibles.md](../stories/US-00.3-migrations-reversibles.md) | 🚀 **Certifiée Prod** (2026-07-26) |
| US-00.4 (ex US-INIT-04) | Enforcement `main` : constat + outillage (cible armée) — *re-cadrée le 2026-07-26* | [US-00.4-ci-protection-branche.md](../stories/US-00.4-ci-protection-branche.md) | 🚀 **Certifiée Prod** (2026-07-27) — *son libellé « cible armée » reste **exact à sa date** : elle a livré l'outillage et le constat, **pas** l'application* |
| US-00.5 (ex US-INIT-05) | **ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution** | [US-00.5-adr-stack-constitution.md](../stories/US-00.5-adr-stack-constitution.md) | 🚀 **Certifiée Prod (2026-07-31)** — **DoD 23/23** · **21 critères exercés → 21 passés** · **6 gates `/certify` verts**. Livrée en **DEUX PR**, la seconde **DÉDIÉE** comme l'exige la clause de *Révision* : **#17** *(ADR-001)* et **#18** *(Art. 4, Constitution **1.0 → 1.1**)*. ⚠️ **Ce qu'elle n'atteste pas** : l'amendement **ne crée aucun gate** — il **nomme** les dettes *(aucun **SAST** applicatif → US-00.8 · aucun scan de CVE · `coverage_ratchet` **non implémenté** pour cet adapter → **US-00.6**)* · l'attestation humaine de l'amendement est **déclarative** · **0 fichier Dart** touché. 🎓 Elle laisse l'acquis de méthode le plus important du projet : [`tension_structurelle.md`](../../reports/US-00.5/tension_structurelle.md) — **six instruments de contrôle faux, trois de chaque côté**, et la cause enfin nommée |
| US-00.6 (ex US-INIT-06) | **Couverture initiale mesurée + cliquet (ratchet) actif** | [US-00.6-couverture-ratchet.md](../stories/US-00.6-couverture-ratchet.md) | 🔨 **en cours** — créée le **2026-07-31** via `/us-new`, track **STANDARD**, **PR #20**. Audits **✅ 🔍 ✅ 🛡️**. **DERNIÈRE US requise pour clore cette EPIC.** ⚠️ **Valeur réelle, modeste et mesurée** : le plancher à 80 % tolérait **exactement une régression d'une ligne** *(`16/19 = 84,2 %` passait **VERT**)* ⇒ l'US achète une marge de **1 ligne → 0 ligne**, rien de plus. ⛔ **Ce qu'elle n'apporte pas** : le cliquet **ne monte jamais seul** *(il protège le dernier niveau **consigné**, jamais **atteint**)*, il **n'améliore pas les tests**, et la complaisance reste possible **nominativement** *(couvrir `main()`/`runApp` ferait **+10,5 pt sans valeur**)*. 🔴 **Dette OUVERTE créée par son succès** : l'**Art. 4** affirme encore **3 choses fausses** → amendement en **PR dédiée** ; **ADR-001 §4** porte les mêmes clauses et **ne sera PAS corrigé** *(immuable)* |
| **US-00.7** | **Protection de la branche principale : application effective, preuve par l'effet, cohérence du corpus** | [US-00.7-application-protection-branche.md](../stories/US-00.7-application-protection-branche.md) | 🚀 **Certifiée Prod (2026-07-30)** — *(**PÉRIMÉ-2026-07-30** : cette case portait « 🔨 en cours »)*. Track **STANDARD + 3** renforcements ; US **non prévue au découpage initial**, créée le 2026-07-27 après le déblocage. **DoD 34/34** · **QA `🧪 PASS` au 6ᵉ passage, après 5 `FAIL`** · **6 gates `/certify` verts** · PR **#15** et **#16** fusionnées **par l'humain**. ⚠️ **Ce que la certification n'atteste pas** : critères **20, 21, 27** demeurent **NON LEVÉS** *(plateforme, jamais requalifiés)* · refus prouvé sur contextes **`expected`, pas `failing`** · **aucune détection de dérive** · **conditionnel à la visibilité PUBLIQUE** du dépôt |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | Fuite de valeurs de démo dans l'historique lors de l'init. | Exposition de secrets factices/réels. | Scan `gitleaks` + rotation documentée (US-00.1). |
| 2 | Dérive entre `factory.config.json` et ses projections (CI, protection de branche, seuils). | Règles déclarées mais non enforced. | ✅ **CLOS le 2026-07-28 (US-00.7)** — voir #5. La protection déclarée dans `factory.config.json` est désormais **appliquée** et **vérifiée champ par champ** contre l'API (`--check-remote` → **exit 0 réel**, 12 champs alignés, 0 écart) : la projection « protection de branche » n'est plus une déclaration sans effet. *(⚠️ **Ne pas surinterpréter** : la **détection automatique** de dérive reste **absente** — `--check-remote` exige des droits admin, hors CI. Dette maintenue OUVERTE, portée par `/audit-methodo`.)* |
| 5 | **🔴 RISQUE #2 MATÉRIALISÉ *ET NON REFERMABLE SUR CE PLAN* (constaté le 2026-07-26)** : `main` n'est **pas protégée** (`"protected": false`) malgré une règle déclarée *enforced*. Les 4 status checks s'exécutent sans qu'aucun ne soit **requis**. **Double cause racine** : (a) `factory_sync.py --check` ne compare que des artefacts **documentaires** et **n'appelle jamais l'API** — il affichait « conforme (env, *protection*, …) » sur un dépôt grande ouverte ; (b) **la protection est INDISPONIBLE sur ce dépôt** — `GET …/branches/main/protection` **et** `GET …/rulesets` renvoient un **403 « Upgrade to GitHub Pro or make this repository public »** (dépôt privé, jeton admin). `factory.config.json` déclarait donc depuis l'origine un enforcement que le compte **n'a jamais pu appliquer**. | Tous les gates qualité restent contournables par un merge ou un push direct ; la confiance dans `Certifié Prod` repose sur la **seule discipline** des intervenants. | ✅ **CLOS le 2026-07-28 par US-00.7 — les DEUX causes sont traitées.** *(Le constat du 2026-07-26 et l'expression « NON REFERMABLE SUR CE PLAN » étaient **exacts à leur date** : ils sont conservés ci-contre, non réécrits — c'est **le plan qui a changé**.)* **Cause (a)** : traitée par **US-00.4** (certifiée le 2026-07-27) — libellé `--check` honnête (*documentaire*), `--check-remote` en lecture seule à 3 issues, constat daté, conditions de déblocage documentées, point de contrôle `/audit-methodo`. **Cause (b)** : levée le **2026-07-27** par une décision humaine (Art. 5) — **dépôt rendu PUBLIC**, voie (a) → `…/protection` passe de **403** à **404** (« *Branch not protected* » : **disponible**, non appliquée), `…/rulesets` à **200 `[]`** ; puis **protection APPLIQUÉE le 2026-07-28** (`"protected": true`, PR obligatoire, **4 checks REQUIS**, `enforce_admins` → `enforcement_level: "everyone"`), **effet prouvé par 3 refus SERVEUR** depuis un clone sans hooks. Preuves : [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/) · [ADR-007](../adr/ADR-007-application-protection-branche.md) *(remplace ADR-006)*. 🔕 **Dérogation `EVT_WAIVER_GRANTED` (2026-07-26, US-00.4, Art. 5) — ÉTEINTE / SANS OBJET** : elle portait sur « **ni GitHub Pro, ni dépôt public** » ; l'humain a choisi le **dépôt public**, son motif **n'existe plus**. ⛔ La trace reste **append-only** — on **éteint** une dérogation, on ne l'**effface** pas ; l'extinction est **DOCUMENTAIRE**, aucun des 25 événements du catalogue ne permettant de l'éteindre (**dette du système de traçabilité**, nommée dans `CLAUDE.md`). ⚠️ **Conditionnel** : un retour du dépôt **en privé** ramènerait le **403** et **rouvrirait ce risque ET la dérogation**. |
| 3 | Seuils de couverture arbitraires non mesurés sur le code réel. | ~~Ratchet inopérant.~~ **✅ RISQUE CLOS le 2026-07-31 (US-00.6)** — le ratchet est **opérant** : mesure réelle **89,4737 % (17/19)**, valeur **`89.4`** consignée dans `factory.config.json` *(arrondie **vers le bas**)*, **lue** par le gate, et **prouvée par un mutant** qui tourne dans le job CI **requis** *(dont un contrôle **différentiel** : la même fixture change de verdict selon la référence)*. | Mesure réelle sur le squelette (US-00.6). ⚠️ **Ce que la clôture n'efface pas** : la mesure porte sur **19 lignes** — grain minimal **5,26 pt**, aucune couverture de **branches** · le cliquet **ne monte jamais seul** · et **angle mort STRUCTUREL tranché par la QA** : un fichier Dart **non importé** n'entre **pas** au dénominateur → **US-01.1**. |
| 4 | **US-00.3 définit une convention de migrations réversibles alors que la techno de persistance est délibérément reportée à US-01.2** (`STACK_PROFILE.md §DataEngineer`) → aucun schéma concret à migrer au Sprint 0. | Convention potentiellement trop abstraite ou non appliquée ; « migration testée » non exécutable tel quel au Sprint 0. | Cadrer US-00.3 comme **convention/politique agnostique de la techno**, **appliquée** et dont le patron de test est **instancié** par US-01.2 ; interdiction de migration destructive par défaut (RF-21). 🟠 **STATUÉ le 2026-08-01 — TRANSFÉRÉ, et un transfert n'est PAS une clôture : ce risque reste OUVERT.** C'est le **seul des 5 risques** qui ne soit pas clos à la clôture de l'EPIC. Il porte la **2ᵉ moitié du critère 112**, structurellement invérifiable ici *(US-01.2 n'existe pas et appartient à EPIC_01)* → devenue **critère d'entrée d'US-01.2**. ⚠️ **Ce qui reste réellement à prouver** : la convention est **documentée** et **jamais instanciée** — aucun schéma réel, **aucune migration jamais exécutée**, patron de test **non exercé**. Tant qu'US-01.2 ne l'a pas appliquée, elle demeure exactement ce que ce risque redoutait : **potentiellement trop abstraite**. |

## 🎯 Challenge PO : Un Sprint 0 sans valeur utilisateur mérite-t-il un EPIC ?

Oui — la traçabilité et la gouvernance de la factory exigent que même le bootstrap soit porté par un
EPIC et des US certifiables. EPIC_00 n'apporte pas de valeur *utilisateur final*, mais il apporte la
valeur *plateforme* (confiance, reproductibilité, sécurité) sans laquelle aucune US métier ne peut
être certifiée `Prod`. Décision : EPIC_00 conservé, priorité Must-Have, clôturé avant l'ouverture
d'EPIC_01 en développement.

## Critères de clôture de l'EPIC

- [x] Toutes les US listées (US-INIT, US-00.1→US-00.6, **US-00.7**) sont `Certifié Prod = 🚀 OUI` (ou clôturées/justifiées dans le SCB) — ✅ **COCHÉ le 2026-08-01** *(**PÉRIMÉ-2026-07-31** : l'état antérieur disait « **5 sur 7** », puis « **6 sur 7**, ne reste que US-00.6 »)*. **État réel : 7 US certifiées `🚀`** — US-00.1, US-00.2, US-00.3, US-00.4, US-00.5, **US-00.6** *(2026-08-01, PR #22 fusionnée par l'humain — `main` = `0126582`)* et US-00.7 ; **`US-INIT` clôturée/justifiée** au titre de la **seconde branche du critère**, celle-là même que sa lettre prévoit. ⚠️ **Ce que la coche n'efface pas** : **US-00.6 est certifiée à DoD 19/20, par DÉROGATION HUMAINE** *(`EVT_WAIVER_GRANTED`, case 6 **insatisfiable**, restée **décochée et datée**)* ⇒ ⛔ **« 7 certifiées » ne veut pas dire « 7 sans réserve »**, et chacune porte ses bornes dans le SCB
- [x] `ci.yml` vert sur une PR de test — ✅ démontré (PR #3/#6/#8/#9, CI 4/4 verte)
- [x] ✅ **Protection de branche vérifiée** — **cochée le 2026-07-28 (US-00.7)**. Appliquée depuis la source unique le 2026-07-28 après le déblocage du 2026-07-27 (dépôt **public**, Art. 5) : `"protected": true` · **PR obligatoire** · **4 status checks REQUIS** · `enforce_admins` (`enforcement_level: "everyone"`) · **exit 0 réel** de `--check-remote` (12 champs alignés, 0 écart) · **3 refus SERVEUR** archivés (clone sans hooks). Preuves : [`reports/US-00.7/applied_state/`](../../reports/US-00.7/applied_state/) ; décision : [ADR-007](../adr/ADR-007-application-protection-branche.md). *(Ce critère était marqué « IMPOSSIBLE À COCHER SUR CE PLAN » au 2026-07-26 — **exact à sa date**, le plan ayant changé depuis. La certification d'US-00.4 ne valait **pas** satisfaction de ce critère : c'est bien US-00.7 qui le lève.)* ⚠️ **Ce qui n'est pas coché pour autant** : la **détection automatique** de dérive (contrôle **manuel**, hors CI) et la **persistance** de l'état — un administrateur peut révoquer la règle sans qu'aucun mécanisme ne le signale. **Conditionnel à la visibilité publique du dépôt.**
- [x] **ADR-001 (stack) publié ET Constitution ajustée** — ✅ **COCHÉ le 2026-07-31, les DEUX moitiés livrées sur `main`** : **ADR-001** *(PR #17, `488b074`)* et **Constitution `1.0` → `1.1`** *(PR #18, `c62cdcc`, **PR dédiée** exigée par la clause de Révision — diff = 2 fichiers)*. Les deux fusionnées **par l'humain, sans `--admin`**. ⚠️ **Ce que le critère n'atteste pas** : l'amendement **ne crée aucun gate** — il fait dire à l'Art. 4 ce qui **est** et **nomme les dettes** *(aucun SAST applicatif → US-00.8 · aucun scan de CVE · `coverage_ratchet` **non implémenté** pour cet adapter → **US-00.6**)*. ⏳ **US-00.5 n'est pas encore certifiée** : DoD **21/23**, restent l'**attestation humaine de l'amendement** et le **`QA Status 🧪 PASS`** — *état au **2026-07-30** (US-00.5, **PR nº 1**)* : ✅ **`docs/adr/ADR-001-choix-de-stack.md` est PUBLIÉ**, statut `Accepté`, numéro **rétroactif assumé** *(décision du 2026-07-24, tracée le 2026-07-30)*, portant les **4 honnêtetés dures** *(iOS non scaffoldé · build Android non validé · `deps_audit` = obsolescence et non vulnérabilité, non bloquant · **aucun SAST**)*. ⏳ **La seconde moitié reste due** : l'**amendement de l'Art. 4** part en **PR nº 2 DÉDIÉE**, la clause *Révision* de la Constitution exigeant une « **PR dédiée, jamais en side-effect d'une US** ». **Ce critère ne sera cochable qu'après la fusion de cette seconde PR.**
- [x] Convention de migrations réversibles documentée (US-00.3) et applicable par la première US de persistance (US-01.2) — 🟠 **COCHÉ SUR SA 1ʳᵉ MOITIÉ SEULEMENT, le 2026-08-01, la 2ᵉ étant TRANSFÉRÉE** *(arbitrage humain ; précédent de forme : la case 12 d'US-00.6, « cochée sur sa 2ᵉ moitié seulement »)*.
      ✅ **1ʳᵉ moitié — VÉRIFIÉE, pas déclarée** : [ADR-005](../adr/ADR-005-convention-migrations-reversibles.md) *(statut **Accepté**, 60 lignes)* + [MIGRATIONS.md](../architecture/MIGRATIONS.md) *(133 lignes)*, livrés par **US-00.3, certifiée le 2026-07-26**.
      ⛔ **2ᵉ moitié — STRUCTURELLEMENT INVÉRIFIABLE ICI, et ce n'est pas un défaut de travail** : « **applicable par US-01.2** » exige une US qui **n'existe pas** *(aucun Story File ; EPIC_01 la dit « à créer via `/us-new` »)*, qui appartient à **EPIC_01**, alors que ce fichier décide *(§Challenge PO)* qu'EPIC_00 est « **clôturé avant l'ouverture d'EPIC_01 en développement** ». ⚠️ **C'est un DEADLOCK, pas une case difficile** : EPIC_00 attendrait une US qu'EPIC_00 doit précéder. ⛔ **Distinct de la case 6 d'US-00.6** *(contradiction INTERNE)* : ce critère est **à cheval sur deux epics**.
      ➡️ **TRANSFERT, donc — et un transfert n'est pas une levée** : l'exigence devient un **critère d'entrée d'US-01.2**, inscrit dans [EPIC_01](EPIC_01-module-echeances.md) *(« la convention d'ADR-005 est **instanciée** — patron de test de migration réversible exécuté sur le premier schéma réel »)*. **Le risque nº 4 le porte** et **reste OUVERT** jusque-là. ⛔ **Aucune 2ᵉ dérogation n'a été émise** : une dérogation est **irrévocable par construction** *(aucun événement d'extinction au catalogue)*, et deux dérogations sur un même corpus feraient une **pratique**, non une exception.
- [x] **Seuils de couverture mesurés et ratchet ACTIF** — ✅ **COCHÉ le 2026-07-31 (US-00.6, PR #20)**, avec sa preuve et ses bornes. **Mesure** : `89,4737 % (17/19)` — dénominateur **19 lignes**, les 2 non couvertes **nommées** *(`lib/main.dart:9-10`, soit `void main()` et `runApp(...)`)*. **Cliquet actif** : valeur **`89.4`** dans `factory.config.json` *(arrondie **VERS LE BAS** : le script **affiche** `89.5`, et consigner l'affiché aurait produit un **rouge sur un dépôt inchangé**, donc le **verrouillage** d'un contexte requis)*, **lue** par `check_flutter_coverage.py`, **validée** par `factory_sync --check`, et **prouvée par un MUTANT qui tourne dans le job CI requis** *(dont un contrôle **différentiel** : la même fixture change de verdict selon la référence, ce qui établit qu'elle est **lue** et non écrite en dur)*. ⚠️ **BORNES, indissociables de la coche** : la couverture porte sur un **squelette** de **19 lignes** — `89,47 %` n'a **aucune valeur statistique**, le grain minimal est **5,26 pt**, et **aucune valeur n'existe entre 89,47 % et 94,74 %** · **aucune couverture de branches** *(ni `BRF:` ni `BRDA:` dans le rapport)* · le cliquet **ne monte jamais seul** · le `lcov` **n'est pas authentifié** · et **angle mort STRUCTUREL tranché par la QA** : un fichier Dart **non importé par un test n'entre PAS au dénominateur**, donc **ajouter 500 lignes non testées ne fait pas baisser la couverture**, et **déplacer du code non couvert vers un fichier non importé la FAIT MONTER** → porté par **US-01.1**
- [x] **Livrables documentaires d'EPIC_00 présents et à jour — critère PUBLIÉ COMME SCRIPT EXÉCUTABLE** : `python scripts/check_epic00_docs.py` → **exit 0** *(et son autotest de mutation `--selftest` → exit 0)*.
      ⛔ **PÉRIMÉ-2026-08-01 — la formulation antérieure était « Documentation à jour », INFALSIFIABLE** : aucune sortie ne pouvait la contredire, donc la cocher relevait de l'**opinion**. Reformulée par **arbitrage humain du 2026-08-01** — ⚠️ **ce n'est pas réécrire une exigence d'après son résultat** *(ce que le projet refuse)* : c'est rendre **mesurable** ce qui ne l'était pas, conformément à la leçon inscrite à [`corpus_sweep.md`](../../reports/US-00.7/corpus_sweep.md) — *« un critère de sortie se publie comme un **script exécutable**, jamais recopié à la main »*.
      ✅ **Résultat LU, non écrit** : **11 livrables** *(Constitution, STACK_PROFILE, TRACKS, WORKFLOW, ADR-001/005/006/007, MIGRATIONS, GIT_PROTECTION, ce fichier)*, chacun contrôlé sur un **marqueur littéral de fraîcheur** — pas sur sa seule existence. ⛔ **Le décompte n'est nulle part écrit à la main** : il vient de `len(LIVRABLES)`, source unique du script.
      ✅ **Le contrôle porte son AUTOTEST DE MUTATION** *(4 assertions, mutants **fichier supprimé** et **marqueur retiré**, verdicts comparés en **ENSEMBLES** et non en cardinaux)*, et il a été **éprouvé sur le corpus RÉEL** : une copie hors dépôt dont la Constitution est ramenée à `1.1` est **refusée** *(motif `MARQUEUR`)*, dépôt **intact**. **Aucun faux vert** sous `ascii`, `cp437`, `cp1252` ni sans `PYTHONIOENCODING`.
      ⚠️ **BORNES, indissociables de la coche** : le contrôle atteste la **PRÉSENCE** et la **FRAÎCHEUR**, ⛔ **jamais la VÉRACITÉ du contenu** — aucune machine ne lit le sens d'un paragraphe, et l'Art. 4 a prouvé qu'un texte peut être **présent, marqué et faux**. **Il n'est PAS en CI** *(lancement manuel — même dette que le `selftest` d'US-00.6, déjà nommée dans `CLAUDE.md`)*.

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
