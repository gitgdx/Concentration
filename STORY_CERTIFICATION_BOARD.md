# 🏁 Story Certification Board (SCB)

> **Légende** : ⏳ (En attente) | ✅ (Validé) | ⚠️ (Avertissement) | ❌ (Bloqué) | 🧪 (Testé) | 🚀 (Prêt) | N/A (Non applicable — justifié dans les Détails des Visas)
>
> **Règle stricte** : `Certifié Prod = 🚀 OUI` est réservé aux US dont `Déploiement = 🚀 DEPLOYED`.
> Vérifié à chaque édition (hook PostToolUse), au commit et en CI
> (`python scripts/check_scb_compliance.py`).

| US ID | Titre de la Story | Phase Workflow | PO Visa | Design Data | Design UX | Code (Dev) | Audit Rev 🔍 | Audit Sec 🛡️ | QA Status | Déploiement (DevOps) | Certifié Prod |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **EPIC_00** | **Fondations** | | | | | | | | | | |
| US-INIT | Initialisation de la factory | development_start | ✅ @PO | N/A (init) | N/A (init) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| US-00.1 | Secrets & scan de dépôt | epic_closure | ✅ @PO | N/A | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 PASS | 🚀 DEPLOYED | 🚀 OUI |
| US-00.2 | Qualité statique de référence | epic_closure | ✅ @PO | N/A | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 PASS | 🚀 DEPLOYED | 🚀 OUI |
| US-00.3 | Migrations réversibles | business_alignment | ✅ @PO | ⏳ | N/A | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| **EPIC_01** | **Module Échéances (MVP)** | | | | | | | | | | |
| US-01.1 | Affichage Hub & grille d'échéances | business_alignment | ✅ @PO | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

## 🛠 Détails des Visas (Preuves de travail)

### [US-INIT] Initialisation de la factory

- **PO Visa** (2026-07-24) : US-INIT créée par `init_factory.py` pour porter le Sprint 0
  (voir `BACKLOG.md` → EPIC_00). Pas de valeur métier propre — US technique de bootstrap.
- **Design Data / UX** : `N/A (init)` — aucun schéma de données ni écran n'est concerné par
  l'initialisation elle-même ; le squelette applicatif de l'adapter n'a pas de design dédié.
- **Prochaine étape** : dérouler `US-INIT-01` → `US-INIT-06` via `/us-new`, qui feront progresser
  cette ligne (ou des lignes dédiées) jusqu'à `Certifié Prod`.

### [US-00.1] Secrets & scan de dépôt

- **PO Visa** (2026-07-24) : Story File créé via `/us-new` — 4 AC (Nominal/Erreur/Limite), 8
  scénarios Gherkin. Valeur : sûreté du dépôt (aucun secret commité, config gitleaks réelle, gate
  CI opérant). Voir `docs/stories/US-00.1-secrets-scan-depot.md`. EPIC :
  `docs/epics/EPIC_00-fondations.md` (chantier ex-« US-INIT-01 »).
- **Track** : STANDARD — config d'outillage sécurité, ≤ ~15 fichiers, pas de surface applicative
  auth/paiement, ni schéma/API/page. ADR non requis.
- **Design Data / UX** : `N/A` justifié — US de configuration/sécurité, sans schéma de données ni
  interface utilisateur.
- **Découverte (gate analyze)** : `.gitleaks.toml` **n'existe pas** au root (dette de fondation) —
  la CI tourne sur les règles par défaut de `gitleaks-action@v2`, le pre-commit référence un fichier
  absent. US-00.1 **crée** ce fichier. ⚠️ `.gitleaks.toml` est verrouillé par `protect_files.sh` →
  création = **action humaine** ; installation locale de gitleaks = action humaine/DevOps.
- **Clarify résolu** : scan historique + working tree ; secret trouvé → révoquer/roter (réécriture
  d'historique = dernier recours humain) ; allowlist `.env`/`settings.local.json`/placeholders
  (`changeme`, `${...}`) ; couverture Dart `N/A` (pas de code applicatif). Historique vérifié propre.
- **Story Ready + Integration Lock** (2026-07-25) : `EVT_STORY_READY` (@PO) → `EVT_ARCHI_VALIDATED`
  (@Architect : story enrichie, faisabilité OK, track STANDARD, aucun ADR) → `EVT_DESIGN_COMPLETED`
  (Integration Lock : **Design Data N/A** — aucun schéma ; **Design UX N/A** — aucune interface).
  **Codage autorisé** selon T1–T10. Phase SCB → `development_start`, branche
  `feat/US-00.1-secrets-scan-depot` (partie du nouveau `main`).
- **Code (Dev)** (2026-07-25, `EVT_CODE_READY`) : T1–T10 terminées. `.gitleaks.toml` posé par l'humain
  (identique à la proposition auditée) + suivi Git ; gitleaks 8.30.1 installé. **Preuves** (`reports/US-00.1/`) :
  T5 scan historique (11 commits) **0 fuite**, T6 working tree (~89 MB, inclut la vraie clé Stitch locale)
  **0 fuite** → allowlist validée, T7 test négatif pre-commit (faux `AQ.<token>` → `leaks found:1`, exit 1),
  T8 test négatif CI (PR jetable #2 → job `secrets-scan` **failure**, branche supprimée). Procédure de
  rotation : `docs/security/SECRET_ROTATION.md`. Note : `gitleaks protect` reste un alias fonctionnel en
  8.30.1 → hook `pre-commit` OK sans modification.
- **Audit Rev 🔍** (2026-07-26, `EVT_CODE_REVIEW_PASSED`, contexte frais) : **PASS**, 0 finding bloquant.
  Prouvé par outils : config unique confirmée, re-scan gitleaks indépendant (13 commits + working tree → 0 fuite),
  test négatif refait (`leaks found:1`), gates app verts, redaction OK. Rapport : `reports/US-00.1/code_review.md`.
- **Audit Sec 🛡️** (2026-07-26, `EVT_SECURITY_AUDIT_PASSED`, contexte frais) : **PASS**, 0 finding bloquant.
  Contre-test **sans config** → `no leaks found` (l'allowlist ne masque aucun vrai secret) ; `git ls-files` sans
  fichier secret suivi ; `dart pub outdated` sans CVE. Rapport : `reports/US-00.1/security.md`.
- **Suivi non bloquant** (hors périmètre certif US-00.1) : en-tête « PROPOSITION » périmé dans `.gitleaks.toml`
  (fichier verrouillé → correctif humain) ; couverture keystore/cert mobile différée à @DevOps (`.gitignore`,
  hors MVP RNF-07) ; `reports/US-00.1/gitleaks.toml.proposed` duplique la config racine (dérive potentielle).
- **QA Status 🧪 PASS** (2026-07-26, `EVT_QA_PASSED`) : `run_gates.py --component app` → **5 gates verts**
  (0 fail/0 skip, non-régression — aucun code Dart) ; confirmation secrets indépendante (14 commits, 0 fuite) ;
  **8/8 scénarios BDD** couverts par preuves outillées. Rapport : `reports/US-00.1/qa.md`.
- **Déploiement 🚀 DEPLOYED** (2026-07-26, chaîne `EVT_READY_FOR_DEPLOY` → `EVT_STAGING_DEPLOYED` →
  `EVT_DEPLOYMENT_SUCCESS`) : pour cette US de **gouvernance de dépôt**, le déploiement = **merge sur
  `main`** (PR #3, sha `9670c35`) — `.gitleaks.toml` désormais actif sur `main` + enforcement CI
  repo-wide. **Staging N/A justifié** (aucun runtime) ; validation pré-prod équivalente = CI verte sur
  PR #3 + test négatif CI (PR jetable #2). Phase → `deployment_prod`.
- **Certifié Prod 🚀 OUI** (2026-07-26, `EVT_CERTIFIED_PROD`, gate `/certify`) : **6 gates verts** —
  SCB conforme, trace complète, 3 rapports d'audit/QA avec sorties d'outils, DoD cochée,
  `run_gates --all` vert, Déploiement `🚀 DEPLOYED`. **US-00.1 clôturée** (phase `epic_closure`).
  1re US de fondation certifiée : le filet anti-secrets est actif et prouvé sur `main`.

### [US-00.2] Qualité statique de référence

- **PO Visa** (2026-07-24) : Story File créé via `/us-new` — 4 AC (Nominal/Erreur/Limite), 6
  scénarios Gherkin. Valeur : garantir une qualité statique reproductible (`dart format` +
  `flutter analyze` sans erreur, 0 règle désactivée sans justification). Voir
  `docs/stories/US-00.2-qualite-statique.md`. EPIC : `docs/epics/EPIC_00-fondations.md`
  (chantier ex-« US-INIT-02 »).
- **Track** : STANDARD — retenu (défendable QUICK par la taille, mais fondation dont dépend la
  fiabilité de tous les audits aval → audit complet justifié). ADR non requis (validation de
  l'existant `flutter_lints`, pas de durcissement).
- **Design Data / UX** : `N/A` justifié — US de configuration/qualité, sans schéma ni interface.
- **Point de vigilance (gate analyze)** : l'AC-3 (« 0 règle désactivée sans justification ») **n'est
  pas automatisable** par un gate (`flutter analyze` ne signale pas une règle désactivée) → son
  enforcement est une **revue manuelle @CodeReviewer**, pas un script. À porter à la certification.
- **Story Ready + Lock + Code** (2026-07-26) : `EVT_STORY_READY` → `EVT_ARCHI_VALIDATED` →
  `EVT_DESIGN_COMPLETED` (design Data & UX N/A) → `EVT_CODE_READY`. **Validation de l'existant**
  (aucun code modifié) : `analysis_options.yaml` inclut `flutter_lints` et n'a **aucune désactivation
  effective** (2 lignes d'exemple commentées) ; gate `format` exit 0 (0 fichier à reformater) ; gate
  `analyze` `No issues found!` ; **0 directive `// ignore`** dans `lib/`/`test/` (AC-3 par revue).
  Preuves : `reports/US-00.2/README.md`. Phase → `parallel_audit`.
- **Audit Rev 🔍** (2026-07-26, `EVT_CODE_REVIEW_PASSED`, contexte frais) : **PASS**, 0 bloquant.
  Prouvé : format exit 0, analyze « No issues found! », `analysis_options.yaml` 0 désactivation effective,
  0 `// ignore`, non-durcissement confirmé, `run_gates --component app` 5/5 verts. 1 suggestion mineure
  (claim CI dans le README → ressort QA/DevOps). Rapport : `reports/US-00.2/code_review.md`.
- **Audit Sec 🛡️** (2026-07-26, `EVT_SECURITY_AUDIT_PASSED`, contexte frais) : **PASS**, 0 finding.
  Diff 100 % documentaire (0 code/pubspec/analysis_options touché) → portée sécurité classique sans objet
  (justifié) ; gitleaks 0 fuite, `dart pub outdated` 0 CVE, aucun affaiblissement de lint. Rapport : `reports/US-00.2/security.md`.
- **QA Status 🧪 PASS** (2026-07-26, `EVT_QA_PASSED`) : `run_gates --component app` **5 gates verts**,
  gates cœur format (exit 0) + analyze (« No issues found! »), **6/6 scénarios BDD** couverts. Aucune
  régression. Rapport : `reports/US-00.2/qa.md`.
- **Déploiement 🚀 DEPLOYED + Certifié Prod 🚀 OUI** (2026-07-26) : chaîne `EVT_READY_FOR_DEPLOY →
  EVT_STAGING_DEPLOYED` (staging N/A, US sans runtime) `→ EVT_DEPLOYMENT_SUCCESS` (merge PR #6 sur `main`,
  sha `b2de4f2` — référence de qualité statique active + gates enforced en CI). `/certify` : **6 gates verts**
  → `EVT_CERTIFIED_PROD`. **US-00.2 clôturée** (phase `epic_closure`). 2e US de fondation certifiée.

### [US-00.3] Migrations réversibles

- **PO Visa** (2026-07-24) : convention de migrations de schéma local **réversibles** établie avant
  le premier schéma (offline-first, RNF-01/07 ; extensibilité RF-21). Valeur **plateforme** (aucune
  valeur utilisateur propre) — **Règle du "Pourquoi"** : dé-risque toute évolution future du modèle
  de données et conditionne la certification de la première US de persistance (US-01.2). Story File :
  `docs/stories/US-00.3-migrations-reversibles.md` (4 AC en Nominal/Erreur/Limite, 6 scénarios Gherkin).
- **Design Data** : `⏳` — la convention est le livrable @DataEngineer (`docs/architecture/MIGRATIONS.md`,
  produit en phase design). **Aucun schéma concret au Sprint 0** : le choix du mécanisme de
  persistance est délibérément reporté à US-01.2 + ADR (`STACK_PROFILE.md §DataEngineer`).
- **Design UX** : `N/A` — aucune interface utilisateur (US de plateforme / convention documentaire).
- **Track** : `STANDARD` — critères `docs/governance/TRACKS.md` : docs/politique (0 fichier de code),
  aucune migration de schéma concrète, pas de surface auth/sécurité, pas de nouvelle page/API, pas de
  nouvelle EPIC. Doute QUICK↔STANDARD tranché vers STANDARD (US de plateforme certifiable).
- **Prochaine étape** : `EVT_STORY_READY` (visa PO complet) → validation technique @Architect
  (+ ADR de convention à assigner). **Bloque US-01.2** (qui applique la convention et instancie le
  patron de test aller-retour).

### [US-01.1] Affichage Hub & grille d'échéances

- **PO Visa** (2026-07-24) : Story File créé via `/us-new` — contexte métier, User Story, 9 AC
  déclinés Nominal/Erreur/Limite, 13 scénarios Gherkin (dont AC-9 « état vide » et « échéance échue
  en tête » ajoutés après la gate *clarify*). Valeur : cœur du MVP — rendre lisible d'un regard le
  temps restant avant chaque échéance (nombre nu sans unité + gradient temporel).
  Voir `docs/stories/US-01.1-affichage-hub-grille.md`. EPIC : `docs/epics/EPIC_01-module-echeances.md`.
- **Track** : FULL — nouvelle EPIC fondatrice + architecture transverse (moteur de dégradé OKLCH,
  moteur d'unité adaptative, registre de modules extensible du hub). ADR-002/003/004 à rédiger
  avant l'Integration Lock (phase `technical_validation`).
- **Design Data / UX** : ⏳ requis (track FULL — pas de N/A justifiable). Entrée UX = maquettes
  Stitch rapatriées dans `docs/design/stitch/`. ⚠️ Conflit relevé (gate *analyze*) : le gradient
  des maquettes est **inversé** vs RF-04 (orange = imminent chez Stitch, alors que RF-04 dit
  orange = loin du prochain changement) → **le PRD fait foi**, maquettes = référence uniquement.
- **Prochaine étape** : gate *clarify* (7 ambiguïtés PRD ↔ maquette) → `EVT_STORY_READY` →
  validation @Architect (`EVT_ARCHI_VALIDATED`) → design UX + Data → ADR → Integration Lock.
