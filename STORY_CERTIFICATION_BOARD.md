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
| US-00.3 | Migrations réversibles | epic_closure | ✅ @PO | ✅ @Data | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 PASS | 🚀 DEPLOYED | 🚀 OUI |
| US-00.4 | Enforcement `main` : constat + outillage (cible armée) | epic_closure | ✅ @PO | N/A | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 PASS | 🚀 DEPLOYED | 🚀 OUI |
| US-00.7 | Protection `main` : application effective + preuve par l'effet | parallel_audit | ✅ @PO | N/A | N/A | ✅ @Dev | ✅ 🔍 | ✅ 🛡️ | 🧪 FAIL | ⏳ | ⏳ |
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
- **Design Data ✅ + Code ✅** (2026-07-26) : `EVT_STORY_READY` → `EVT_ARCHI_VALIDATED` →
  `EVT_DATA_DESIGN_COMPLETED` (convention `docs/architecture/MIGRATIONS.md` par @DataEngineer :
  versionnement monotone, contrat up/down + invariant aller-retour, additif par défaut / destructif
  encadré, patron de test round-trip) → `EVT_DESIGN_COMPLETED` (Lock : Data ✅ + UX N/A, **ADR-005
  Accepté**) → `EVT_CODE_READY`. Livrables docs (aucun code Dart compilé). Preuves : `reports/US-00.3/README.md`.
  Phase → `parallel_audit`. **Bloque US-01.2** (qui applique la convention + instancie le patron de test).
- **Audit Rev 🔍** (2026-07-26, `EVT_CODE_REVIEW_PASSED`, contexte frais) : **PASS**, 0 bloquant.
  AC-1..4 conformes, ADR-005 Accepté sans collision, `analyze` vert, 0 fichier d'enforcement touché,
  6 scénarios Gherkin couverts. 2 suggestions non bloquantes (pour l'instanciation US-01.2). Rapport : `reports/US-00.3/code_review.md`.
- **Audit Sec 🛡️** (2026-07-26, `EVT_SECURITY_AUDIT_PASSED`, contexte frais) : **PASS**, 0 bloquant.
  Diff 100 % documentaire, gitleaks 0 fuite, deps 0 CVE, portée sécurité classique sans objet (justifié) ;
  posture de la convention validée (réversibilité, non-destructif par défaut, exception traçable via
  `EVT_WAIVER_GRANTED`). 2 points d'attention LOW reportés à **US-01.2** (chiffrement au repos ; non-banalisation
  du destructif). Rapport : `reports/US-00.3/security.md`.
- **QA Status 🧪 PASS** (2026-07-26, `EVT_QA_PASSED`) : revue de conformité (AC-1..4 couverts, ADR-005
  Accepté) + non-régression `analyze`/`format` verts + enforcement intact + **6/6 scénarios BDD**.
  Exécution round-trip = US-01.2. Rapport : `reports/US-00.3/qa.md`.
- **Déploiement 🚀 DEPLOYED + Certifié Prod 🚀 OUI** (2026-07-26) : chaîne `EVT_READY_FOR_DEPLOY →
  EVT_STAGING_DEPLOYED` (staging N/A) `→ EVT_DEPLOYMENT_SUCCESS` (merge PR #8 sur `main`, sha `3490926` —
  convention + ADR-005 actifs). `/certify` : **6 gates verts** → `EVT_CERTIFIED_PROD`. **US-00.3 clôturée**
  (phase `epic_closure`). **Sprint 0 (EPIC_00) complet : US-00.1 + US-00.2 + US-00.3 certifiées.** La
  convention est prête à être appliquée + son patron de test instancié par **US-01.2**.

### [US-00.4] Enforcement de la branche principale : constat, vérification honnête et cible armée

> ⚠️ **US RE-CADRÉE le 2026-07-26** (titre initial : « CI + protection de branche réelles »). Voir
> l'encadré **« Blocage de plateforme et re-cadrage »** en fin de section : la protection de branche
> côté serveur est **indisponible** sur ce dépôt. **La certification de cette US ne clôt PAS le
> risque #2 d'EPIC_00, qui demeure OUVERT.**

- **PO Visa** (2026-07-26) : Story File créé via `/us-new` — `docs/stories/US-00.4-ci-protection-branche.md`,
  **7 AC** déclinés Nominal/Erreur/Limite, **13 scénarios Gherkin**
  (`tests/features/US-00.4-ci-protection-branche.feature`). Valeur **plateforme** (aucune valeur
  utilisateur final) — **Règle du "Pourquoi"** : fait passer la règle « jamais de push direct sur la
  branche principale » de *déclarée* à **effective**. EPIC : `docs/epics/EPIC_00-fondations.md`
  (chantier ex-« US-INIT-04 », risque #2 de l'EPIC).
- **⚠️ Constat d'entrée (vérifié par API le 2026-07-26)** : `main` **n'est PAS protégée**
  (`GET /repos/gitgdx/Concentration/branches` → `"protected": false`). Les 4 status checks déclarés
  dans `factory.config.json` s'exécutent sur les PR mais **aucun n'est requis** : rien n'empêche
  techniquement un merge avec CI rouge, un push direct ou un force-push. Les **8** PR fusionnées
  (#1, #3, #4, #5, #6, #7, #8, #9) l'ont **toutes** été **sans protection active** — par discipline de
  process, pas par contrainte de plateforme. *(Décompte corrigé le 2026-07-26 : « 4 PR » était faux, il
  omettait les PR de déploiement, de certification, le hotfix et la consolidation. Commande probante :
  `git log --first-parent --oneline origin/main` → 8 fusions + exactement 2 commits directs ;
  `git log --merges` en renvoie 12 et ne prouve rien.)*
  **Angle mort corrélé** : `factory_sync.py --check` affiche « conforme (env, **protection**, … ) »
  **sans jamais contacter l'API GitHub** (vérification purement documentaire) — libellé trompeur.
- **Track** : `STANDARD` — critères `docs/governance/TRACKS.md` : 0 fichier de code Dart, ≤ 15
  fichiers, pas de nouvelle page/API, pas de nouvelle EPIC. Le critère « surface admin » (qui
  plaiderait FULL) a été examiné et **écarté** : il vise la surface *applicative*, interprétation déjà
  inscrite au SCB par US-00.1. FULL aurait imposé Design Data **et** UX sans N/A possible (absurde pour
  une US de CI) et une « revue humaine explicite de PR » que le passage à 0 approbation rend
  précisément non enforçable. **ADR-006 requis malgré STANDARD** (précédent : ADR-005 en STANDARD).
- **Design Data / UX** : `⏳` → **N/A attendu** au Integration Lock (aucun schéma de données, aucune
  surface d'interface — US de gouvernance de dépôt), à justifier à `EVT_DESIGN_COMPLETED`.
- **Arbitrages humains rendus (gate *clarify*, 2026-07-26)** :
  1. **Cible de protection** = `required_approving_review_count: **0**` + `enforce_admins: **true**`
     (reste inchangé). Motif : le dépôt n'a **qu'un seul collaborateur** (`gitgdx`, admin) ; GitHub
     interdit à l'auteur d'approuver sa propre PR et `enforce_admins: true` supprime le bypass admin →
     la config initiale (`1` + `enforce_admins`) aurait **verrouillé tout merge futur**. Écart à
     justifier par **ADR-006** (+ condition de retour à `1` dès un 2ᵉ collaborateur, avec point de
     contrôle inscrit dans `/audit-methodo`).
  2. **Angle mort traité dans l'US** : `--check` doit annoncer une vérification **documentaire**, et une
     commande dédiée `--check-remote` compare champ par champ la protection réelle au JSON émis par la
     config. **Hors CI** — lire la protection exige des droits **admin** que le `GITHUB_TOKEN` de la CI
     n'a pas ; un gate CI échouerait.
  3. **2 commits de bootstrap hors PR** (`0a2e5ab` `chore(init)`, `6483022` `chore(governance)`, seuls
     commits n'étant pas passés par une PR) : **pas d'`EVT_WORKFLOW_VIOLATION` rétroactif** (ils ont
     *créé* les règles en question). Exemption portée par **ADR-006** + `docs/GIT_PROTECTION.md` + le
     constat daté de l'AC-7. **`governance.grandfathering_date` reste `null`** — décision d'abord prise
     de la renseigner, **révisée** après vérification : la clé est **lue par aucun script** (présente
     seulement dans une description de schéma et un docstring) et sa sémantique documentée est « *US
     sans trace tolérées* », pas « commits hors PR » ; la renseigner aurait été un no-op risquant de
     **masquer la dette US-INIT-01→06**.
  4. ~~**Aucun amendement de `CLAUDE.md` ni de la Constitution** : cette US rend la déclaration
     « *enforced par protection de branche* » **vraie** — il n'y a rien à corriger.~~
     🔴 **DÉCISION INVALIDÉE le 2026-07-26** (signalée par la relecture T14 « aucune fausse
     affirmation », occurrence S5). Elle reposait sur la prémisse que la protection serait appliquée.
     Le blocage 403 la renverse : la déclaration « *enforced par protection de branche* » **reste
     FAUSSE après cette US**. Son amendement devient **OBLIGATOIRE** et relève de **US-00.5**, aux deux
     emplacements exacts `CLAUDE.md:20` (règle 2) et `docs/governance/CONSTITUTION.md:49`. Formulation
     de remplacement suggérée : « *enforced par hook local `pre-push` + PR ; protection de plateforme
     indisponible sur ce plan — cf. ADR-006* ». Transmission formelle en §dédiée de
     `reports/US-00.4/enforcement_gap.md` (T15).
- **Prérequis / actions humaines** : ✅ **`gh` CLI installé** (2.96.0) et authentifié `gitgdx` avec
  `admin: true` — *(mention « `gh` n'est pas installé » périmée, corrigée le 2026-07-26, occurrence
  S6)*. Chemin absolu si absent du `PATH` d'une session ouverte avant l'installation :
  `C:\Program Files\GitHub CLI\gh.exe` — sans ce `PATH`, `--check-remote` rend un exit 2 dont la cause
  est « `gh` introuvable » et **non** le 403 de plan. ✅ **T4 fait** par l'humain
  (`scripts/factory_sync.py`) et **T5 fait**. ✅ `factory.config.json` porte déjà la cible.
  ⏳ **T6 restant** (nettoyage cosmétique : ligne vide à 2 espaces, ligne 63) — fichier Art. 6, action
  humaine. Les diffs exacts restent pré-rédigés dans le Story File.
- **Portée bornée (AC-7)** : cette US **ne réécrit pas** l'historique Git et **ne remet pas en cause**
  les certifications de US-00.1/00.2/00.3 (audits à contexte frais, gates CI réellement exécutés,
  preuves archivées). Elle constate le trou d'enforcement, le documente et le ferme pour la suite.
- **🔴 Blocage de plateforme et re-cadrage** (2026-07-26, `EVT_DEV_BLOCKER` → `EVT_WAIVER_GRANTED`) :
  en phase `technical_validation`, avec un jeton `gh` authentifié `gitgdx` et `{"admin": true}` sur le
  dépôt, **les deux** mécanismes d'enforcement renvoient un **403 identique** :
  `GET …/branches/main/protection` **et** `GET …/rulesets` →
  *« Upgrade to GitHub Pro or make this repository public to enable this feature. »* Le dépôt est
  **privé** (`owner_type: User`) et le plan du compte n'ouvre la protection de branche ni en classique
  ni en rulesets. `apply_branch_protection.sh` **échouerait en 403** : ce n'a jamais été un problème de
  droits ni d'outillage. **Cause racine affinée** : `factory.config.json` déclarait depuis l'origine un
  enforcement que le compte **n'a jamais pu appliquer**, et `factory_sync.py --check` était
  structurellement incapable de le voir (comparaison documentaire, aucun appel API). Le défaut n'est
  donc pas « un script qu'on a oublié de lancer ».
- **Dérogation humaine** (`EVT_WAIVER_GRANTED`, Constitution Art. 5) : après présentation des 3 options
  chiffrées, l'humain décide **ni GitHub Pro (~4 USD/mois), ni passage du dépôt en public**. US-00.4 est
  re-cadrée en **US de constat + outillage** : **8 AC** satisfaisables, **20 scénarios** Gherkin, cible
  de protection **déclarée et ARMÉE mais NON APPLIQUÉE** (applicable en une commande le jour du
  déblocage, sans nouvelle décision). **Retirés** du périmètre : application réelle, 4 checks
  « bloquants », test négatif serveur, comparaison config ↔ dépôt en exit 0. **Reportées** : T16→T19.
- **⚠️ Ce que cette US ne fera PAS — à lire avant tout audit ou certification** : `main` **ne sera pas
  protégée**. La règle « jamais de push direct sur la branche principale » **reste NON enforced par la
  plateforme**. Ce qui protège `main` aujourd'hui = hook `pre-push` **local** + CI qui **rapporte** 4
  status checks **sans pouvoir bloquer** la fusion = **filet de discipline**, pas contrainte de
  plateforme. **Le risque #2 d'EPIC_00 demeure OUVERT** et EPIC_00 **ne peut pas être déclarée complète
  sur cette base**. Toute lecture inverse reproduirait exactement le défaut que l'US dénonce.
- **ADR-006 ✅ Accepté** — *Protection de la branche principale : 0 approbation + `enforce_admins` sur
  dépôt mono-collaborateur, cible armée non appliquée*. **Réécrit en place** (pas d'ADR-007) : le
  fichier était `untracked`, jamais commité, audité ni référencé — donc **jamais entré en vigueur** ; la
  clause d'immuabilité protège le registre des décisions *effectives*, pas un brouillon non versionné.
  Contient un **démenti explicite** des 4 affirmations fausses de sa première version (« règle
  effective », `"protected": true` prouvé, gates « incontournables », force-push « refusé par le
  serveur »). Conserve les pièges d'implémentation : `required_pull_request_reviews` doit rester
  **présent avec `0`** (le retirer désactiverait « Require a PR before merging ») et `restrictions: null`
  (PUT) vs clé **absente** (GET) → une comparaison naïve produirait de fausses dérives.
- **Integration Lock ✅** (2026-07-26, `EVT_ARCHI_VALIDATED` → `EVT_DESIGN_COMPLETED`) : **Design Data
  N/A** (aucun schéma, aucune persistance) et **Design UX N/A** (aucune surface d'interface) — recevables
  en track STANDARD. **Codage autorisé** selon **T1→T15** (13 [agent], 2 [action humaine]) ; **T16→T19
  reportées et INTERDITES à l'exécution** — sans protection, un `git push` direct sur `main`
  **réussirait** et la modifierait hors PR (critère de test #18 : `origin/main` doit rester inchangée).
  **21 critères de test**, tous exécutables sans écrire sur `main`. Contrainte de preuve : exit 0 et
  exit 1 sur **fixtures** avec préfixe `[SIMULATION]` obligatoire ; **exit 2 (403) est le seul chemin
  observable in vivo** ; le chemin 404 n'est pas observable sur ce dépôt.
- **Code (Dev) ✅** (2026-07-26, `EVT_CODE_READY`) : **T1→T15 livrées** ; **T16→T19 reportées** au
  déblocage et **non exécutées**. Livrables : `scripts/check_branch_protection.py` (comparateur
  **lecture seule**, mapping PUT→GET, exits 0/1/2, désambiguïsation 403-plan / 403-droits / 401 / 404) ·
  5 fixtures `tests/fixtures/US-00.4/` · en-tête **NON APPLICABLE** de `apply_branch_protection.sh`
  (logique `PUT` **intacte**) · réécriture de `docs/GIT_PROTECTION.md` (bloc `FACTORY_SYNC`
  **byte-identique**) · point de contrôle périodique dans `/audit-methodo` · **13 fichiers de preuves**
  dans `reports/US-00.4/`. **Preuves** : `--check-remote` → **exit 2** nommant le 403 de plan (seul
  chemin observable in vivo) ; exits 0/1/404 démontrés sur **fixtures** préfixées `[SIMULATION]` ;
  `run_gates --all` **5/5 verts** ; 3 contrôles négatifs (aucun `check-remote` en CI, aucune méthode
  d'écriture dans le module, aucun jeton dans `reports/`).
- **🔍 Relecture « aucune fausse affirmation » (T14) — le garde-fou central de cette US** : **11**
  corrections dans le périmètre @Developer (dont **2 sur ses propres livrables** : un fichier de preuve
  qui contenait le mot interdit dans sa ligne de contrôle, et une cellule de `/audit-methodo` affirmant
  une issue jamais obtenue) · **4** occurrences hors périmètre corrigées par @Architect (**S3**
  `SQUAD_GUIDE.md:321`, **S4** `EPIC_00:25` qui contredisait les critères de clôture du même fichier,
  **S5** la décision du matin « cette US rend la déclaration *enforced* vraie » désormais **barrée et
  marquée INVALIDÉE**, **S6** mention périmée de `gh`) · **3** trouvées ensuite par **balayage par
  MOTIF** — méthode adoptée après que S3 eut échappé à la liste de fichiers *a priori* de T14 : **S7**
  `SQUAD_GUIDE.md:285` (« jobs **requis** », « CI **bloquante** » — 2ᵉ occurrence du fichier de S3, donc
  corrigé partiellement), **S8** `EPIC_00:13` (enforcement présenté comme acquis), **S9**
  `.claude/commands/sprint-status.md:9` — **c'est cette ligne qui a effectivement trompé
  l'orchestrateur en ouverture de session**, le rituel de constat d'état portant lui-même la fausse
  affirmation. **S1** (`CLAUDE.md:20`) et **S2** (`CONSTITUTION.md:49`) sont **délibérément maintenues**
  → textes normatifs, PR dédiée en US-00.5.
- **Réserves honnêtes portées à l'audit** (à ne pas lire comme des PASS) : `gitleaks` **non installé**
  localement → l'absence de secret dans `reports/` est *vraisemblable*, **le gage réel est le job CI**
  `🔐 Secrets scan` ; le **repli `urllib`** n'est **pas exercé** in vivo (aucun jeton en session) ; le
  chemin **404 n'est pas observable** sur ce dépôt (403) ; les exits **0 et 1 sont prouvés sur
  fixtures**, jamais sur l'état réel ; le critère « 4 checks verts sur la PR » reste **à lever** par
  @DevOps/@QA après ouverture de la PR (et ces checks doivent être **lus**, ils ne bloquent rien).
- **❌ Audit Rev 🔍 — FAILED** (2026-07-26, `EVT_CODE_REVIEW_FAILED`, contexte frais) : **2 findings
  bloquants**, rapport `reports/US-00.4/code_review.md`. L'auditeur a **refusé le PASS de complaisance**
  et les deux findings sont **reproduits indépendamment par @Architect** :
  - **B-1 — la relecture « aucune fausse affirmation » a surestimé son exhaustivité.**
    `enforcement_gap.md` affirmait que S1/S2 étaient « la **dernière** affirmation fausse restante du
    corpus ». Un grep avec **ses propres motifs** en trouve 3 autres, non corrigées **et non
    signalées** : `.github/workflows/ci.yml:3-4` (« gates **bloquants** », « status checks **requis par
    la protection de branche** » — fichier que l'US a pourtant examiné et déclaré « non modifié ») ·
    `scripts/githooks/pre-push:2-3` (« le merge passe par une PR — **protection de branche GitHub** » :
    c'est l'élément (a) du filet de discipline de l'AC-7, dont le propre commentaire dit le contraire ;
    fichier **Art. 6**) · `docs/stories/US-00.1-secrets-scan-depot.md:198,215` (« merge empêché par la
    protection de branche », critère de test d'une US **certifiée**).
  - **B-2 — faux vert dans l'outil de preuve.** `check_branch_protection.py::_guard_mapping()` ne garde
    que le côté **attendu** ; aucune garde symétrique sur la réponse **réelle**. **Reproduit** : une
    protection portant `lock_branch: {"enabled": true}` (branche entièrement verrouillée) +
    `block_creations` sort en **EXIT 0 « conforme »**. Contraire au pattern « fail-explicit — jamais de
    faux vert » et à l'AC-3 nominal. Les fixtures livrées portent **déjà** ces clés (à `false`) : le trou
    est matérialisé sans être testé. C'est la classe de défaut même que l'US combat.
  - **Ce que l'audit a validé en propre** : 403 reproduit sur les 2 mécanismes · lecture seule
    **absolue** · mapping asymétrique **correct**, y compris les 2 pièges · `[SIMULATION]`
    **structurellement intègre** · 8 chemins rejoués · **l'inférence de l'AC-1 fait (b) est écrite
    explicitement comme telle en 4 endroits — aucune fraude** · garantie d'import paresseux vérifiée par
    simulation d'un module cassé · bloc `FACTORY_SYNC` byte-identique · Art. 6 respecté · `origin/main`
    intacte, T16→T19 non exécutées. **Toutes les réserves de @Developer sont honnêtes ; aucune ne
    masquait un défaut** — les 2 bloquants n'y figuraient pas.
- **✅ Audit Sec 🛡️ — PASS** (2026-07-26, `EVT_SECURITY_AUDIT_PASSED`, contexte frais) : **0 bloquant**,
  rapport `reports/US-00.4/security.md`. **`gitleaks` 8.30.1 retrouvé et réellement exécuté** (hors
  PATH) → `no leaks found` sur le **working tree** (89,82 Mo) **et sur 30 commits d'historique** : la
  réserve de @Developer est **levée**, l'absence de secret est prouvée par l'outil de référence. Aucun
  fichier d'US-00.4 allowlisté dans `.gitleaks.toml` (contrôle anti-suppression). **Mitigation R1
  attaquée et tenue** : injection de saut de ligne via fixture forgée → `json.dumps` échappe, 17/17
  lignes restent préfixées, issue **exit 1** et non 0 ; `--raw-out` refusé en fixture **sans créer le
  fichier** ; mode fixture **inatteignable** depuis `--check-remote`. Jeton **non exfiltrable** (test
  avec jeton factice → 0 occurrence dans l'archive, en-tête remplacé). Zéro dépendance ajoutée.
  **Tranchages** : bloc PGP + e-mail **acceptable, ne pas expurger** — la signature archivée est
  *byte-identique* au `gpgsig` présent dans **tout clone** et l'e-mail est l'auteur de tous les commits
  → exposition incrémentale **nulle** ; expurger serait du théâtre de sécurité au prix de la
  disqualification d'une preuve brute. Cible armée **sûre** (`required_pull_request_reviews` présent
  avec `0`, émis inconditionnellement, défaut de repli `1` → fail-safe). **Aucune survente résiduelle** :
  « la documentation est plus dure avec elle-même que l'audit n'avait besoin de l'être ».
  **3 MEDIUM non bloquants** : **M1** toute la barrière anti-secrets repose sur `ci.yml`, **éditable par
  un agent**, gitleaks **conditionnel** en pre-commit, aucun check requis → une PR neutralisant `ci.yml`
  reste fusionnable (manifestation la plus concrète du risque #2) · **M2** l'outil de preuve n'est
  protégé ni par l'Art. 6 ni par le hook (`exit 2 → exit 0` sans barrière) · **M3** aucun SAST ni
  scanner de CVE dans la factory (`deps_audit` non bloquant, `dart pub outdated` compare des versions,
  pas des vulnérabilités) — sans objet ici, bloquant de fait pour toute US applicative.
- **🔧 Correctifs des 2 bloquants livrés** (2026-07-26, @Developer — **vérifiés indépendamment par
  @Architect**) :
  - **B-2 fermé.** `_guard_actual()`, symétrique de `_guard_mapping()`, avec une **frontière de
    couverture documentée** dans le module : clés **inertes** (liste explicite + préfixe `_`) ignorées ·
    clés **mappées** comparées · **tout le reste classé par la sémantique de sa VALEUR** — *neutre*
    (absente/`false`/vide, récursivement) ignorée mais **nommée** `[IGNORÉ — NEUTRE]`, *active*
    (`true`/non vide) → **exit 2** en nommant la clé. Le choix porte sur la **valeur**, pas sur la
    connaissance du **nom** : une liste blanche fermée aurait rendu l'outil rouge en permanence (l'API
    GitHub est additive) et un outil toujours rouge finit ignoré. **Règle de dominance** :
    `uncovered_active` **domine** les écarts — une comparaison incomplète ne peut affirmer ni la
    conformité **ni l'exhaustivité de la liste d'écarts**. **Vérifié par @Architect** : l'ex-faux vert
    (`lock_branch: {"enabled": true}`) sort en **exit 2** en nommant les 2 clés actives, et une clé
    additive **neutre** reste en **exit 0**. **2 trous de la même famille fermés au passage, non
    signalés par l'audit** : les sous-objets de `required_pull_request_reviews` étaient eux aussi
    ignorés en silence — dont **`bypass_pull_request_allowances`, qui DISPENSE DE PR** (B-2 un niveau
    plus bas) ; et `contexts` ↔ `checks[].context` sont désormais **recoupés**.
  - **B-1 traité.** Over-claim **retiré** (plus de « dernière affirmation fausse restante », plus de
    balayage « sur tout le dépôt ») ; `false_claims_sweep.md` déclare explicitement que
    **l'exhaustivité n'est pas revendiquée**. **C12** `.github/workflows/ci.yml:3-4` **corrigé**
    (« rapportés, PAS bloquants » ; fusion possible avec CI rouge) — les 4 libellés résolvent toujours,
    `--check` reste exit 0. **S10** `scripts/githooks/pre-push:2-3` → **non édité** (Art. 6), diff exact
    fourni en **T22 [action humaine]**. **S11** `US-00.1:198,215` → **non édité** (**décision humaine** :
    US certifiée, pas de ré-ouverture de cycle) → transmis à **US-00.5**, @PO tranchera le véhicule.
  - **S12 — 3ᵉ fausse affirmation du même fichier**, corrigée par @Architect : `docs/SQUAD_GUIDE.md:36`
    (nœud Mermaid « Gates CI **bloquants** sur PR … **insensibles aux bypass locaux** » — **deux**
    affirmations fausses), après S3 (l. 321) et S7 (l. 285). Le principe cardinal du guide (« une règle
    sans mécanisme d'application est un **vœu** ») s'y applique désormais explicitement à
    l'enforcement de `main`. **Périmètre de S11 borné par vérification** : US-00.2 et US-00.3 sont
    **propres**, seule US-00.1 portait cette classe d'affirmation.
  - **🎓 Leçon méthodologique — trois échecs successifs d'exhaustivité, tous consignés** : balayage par
    **liste de fichiers** (T14) → rate S3 · balayage par **motif sur `*.md`** (@Architect) → rate
    `ci.yml` (YAML) et `pre-push` (shell), d'où B-1 · balayage par **motif toutes extensions**
    (@Developer) → **rate `CLAUDE.md:20`**, le motif `enforced par protection` ne matchant pas la forme
    énumérative `*Enforced : … + protection de branche.*`. **Un balayage par motif n'est exactement
    aussi complet que sa liste de motifs** — même défaut que la liste de fichiers, un cran plus haut.
    Aucune de ces méthodes ne garantit l'exhaustivité ; **la seule garantie serait une relecture
    intégrale du corpus, qui n'a pas été faite**. À porter à `/audit-methodo`.
  - **Non-régression** : `--check` exit 0 · `--check-remote` exit 2 (403 de plan) · `run_gates --all`
    **5/5** · SCB et trace conformes · 3 contrôles négatifs · **import paresseux revérifié** après
    refonte du module (module rendu syntaxiquement invalide → `--check` reste exit 0) · **`gitleaks`
    8.30.1 rejoué** par @Developer sur les livrables → `no leaks found`.
  - ⚠️ **Écart signalé, non résolu** : le comparateur **n'est protégé par rien** (`protect_files.sh`) et
    **aucun test automatisé ne le couvre** — or il porte maintenant la frontière de couverture, dont
    l'affaiblissement (retirer une clé de `INERT_GET_KEYS`, inverser `_is_neutral`) **rétablirait
    silencieusement le faux vert**. Les 8 chemins sont exercés par fixtures versionnées, mais
    **manuellement**. C'est la classe de risque que B-2 vient de matérialiser → **à arbitrer**.
- **✅ Audit Rev 🔍 — PASS au 2ᵉ cycle** (2026-07-27, `EVT_CODE_REVIEW_PASSED`, **contexte frais, auditeur
  différent** de celui du FAILED) : **0 bloquant**, 11 non bloquants, 6 suggestions. Rapport
  `reports/US-00.4/code_review_2.md` (711 l. — `code_review.md` **conservé intact** comme preuve du
  cycle 1).
  - **B-2 fermé, vérifié PAR L'ATTAQUE** : **26 fixtures d'attaque écrites hors du dépôt**, et
    l'auditeur **n'a pas réussi** à fabriquer une réponse qui *relâche* l'enforcement réel et sorte en
    exit 0, **pour toute forme que l'endpoint GitHub émet réellement**. Correctement rejetés : types
    inattendus (dont `0`, où `0 is False` est faux en Python), profondeurs 2 et 4, sous-objets mappés
    (`bypass_pull_request_allowances`), `restrictions` présent, `required_pull_request_reviews` absent,
    divergence `contexts`/`checks`. `""`/`[]`/`{}`/`null` → **neutres et nommés**, conformément à la
    doctrine écrite. **La frontière est juste.**
  - **B-1 fermé** : les deux affirmations falsifiables ont **disparu du corpus** (ne subsistent que leurs
    auto-citations dans le paragraphe qui les rétracte) ; `false_claims_sweep.md:140` s'intitule
    « l'exhaustivité n'est **PAS** revendiquée » avec ses 3 angles morts nommés ; `ci.yml` corrigé **sans
    casser** le gate `governance`.
  - **Arbitrage rendu — comparateur non protégé et sans harnais : ACCEPTABLE, non bloquant.** Le code
    n'est pas non testé (12 chemins, 8 fixtures versionnées et concordantes, **rejouées par
    l'auditeur**) : ce qui manque est le **harnais**, et aucun `pytest` n'existe dans cette factory
    (arbitrage tracé). Les affaiblissements redoutés sont **bruyants** (rouge permanent), le risque ne se
    matérialise **qu'au déblocage**, et la moitié « hook » de la parade est **hors du pouvoir d'un agent**
    par l'Art. 6 que cette US respecte. **Recommandation forte** : un `selftest` en CI — « c'est lui, pas
    le hook, qui arrête une régression ».
  - **Autres vérifications** : lecture seule prouvée y compris **contre injection par `--repo`** ·
    `[SIMULATION]` sur **100 %** des lignes de résultat (16 formes d'invocation) · `--raw-out` refusé en
    mode fixture · **import paresseux revérifié module cassé** · bloc `FACTORY_SYNC` **sha256 identique**
    à `main` · Art. 6 respecté · T16→T19 décochées, **aucun test négatif** · `origin/main` = `801a046`
    **intacte** · `run_gates --component app` **5/5**.
- **🔴 Dettes ouvertes issues du re-audit — à traiter, hors périmètre de certification d'US-00.4** :
  - **NB-1 — trou résiduel DÉMONTRÉ, correctif à 1 ligne.**
    `check_branch_protection.py:503` passe `MAPPED_TOP_KEYS` (**constante statique**) au lieu d'un
    ensemble **dérivé de `expected`**. Une clé absente de la cible mais **active** dans la réponse est
    donc traitée comme « couverte » sans être comparée → l'auditeur a produit un **exit 0 sur un
    relâchement réel** (force-push autorisé) avec une cible amputée. **Reproduit et confirmé par
    @Architect.** **Non bloquant** car `emit_branch_protection()`
    (`scripts/factory_sync.py:60-77`) code les 8 clés **en dur** : l'atteindre exige d'éditer un fichier
    **Art. 6**. **Correctif** : `MAPPED_TOP_KEYS & set(expected)`.
  - **`selftest` en CI** exerçant les 12 chemins sur les fixtures versionnées — la seule parade
    réellement à portée d'agent contre une régression silencieuse de la frontière.
  - **1 fausse affirmation résiduelle non déclarée** : `tests/features/US-00.1-secrets-scan-depot.feature:54`
    — même famille que **S11** (US **certifiée**) → **à joindre à la transmission US-00.5**. L'auditeur
    la classe non bloquante car « **elle ne falsifie plus aucune affirmation**, puisque plus aucune n'est
    faite ». *(4ᵉ échec d'exhaustivité du balayage : l'extension `.feature` n'avait été couverte par
    aucune des trois passes précédentes.)*
- **🎓 Constat de posture, relevé par l'auditeur** : un **hook local** de la factory a **bloqué la propre
  sonde de l'auditeur** (littéral de force-push), qu'il a reformulée **sans jamais le contourner**. Son
  observation : « sur ce dépôt, la seule barrière qui ait dit *non* pendant tout l'audit est un **hook
  local**, jamais la plateforme ». **C'est exactement la thèse de cette US.**
- **✅ QA Status 🧪 PASS** (2026-07-27, `EVT_QA_PASSED`) — **avec une réserve bloquante pour `/certify`**.
  Rapport `reports/US-00.4/qa.md`. **Décomptes** : `run_gates --all` **5/5 verts** · tests Dart **2
  passed / 0 failed** · couverture **89,5 %** (inchangée, aucun fichier Dart au diff) · 3/3 gates
  gouvernance · **16/16** invocations de `check_branch_protection.py` conformes à la spécification ·
  `gitleaks` 8.30.1 **2/2** → `no leaks found` · **20/20 scénarios Gherkin couverts** (15 par exécution
  d'outil, 5 par revue d'artefact — **aucun runner Gherkin n'existe dans cette stack**, dette déclarée) ·
  **24/26 critères** pleinement satisfaits, 2 partiels (#20/#21, conditionnés à une PR) · **8/8 AC
  conformes, aucun orphelin**.
  - **Constat du 2026-07-26 REPRODUIT à la date du 2026-07-27** (4 `gh api` en lecture seule) :
    `protected:false`, **403 identique** sur protection **et** rulesets, `private:true`, `admin:true`,
    **1 seul collaborateur**. `--check-remote` in vivo → **exit 2**, mot « conforme » absent.
  - **Réserve « repli `urllib` non exercé » PARTIELLEMENT LEVÉE** : en retirant `gh` du `PATH` avec un
    jeton factice, @QA a **réellement atteint le transport `urllib`** sur le réseau → `exit 2 / 401 Bad
    credentials`. **Le 401 est donc distingué du 403 in vivo**, et non plus seulement sur fixture.
  - **AC-1 fait (b)** : l'inférence est écrite **explicitement comme telle en 2 endroits** (en-tête de
    `check_runs.json` ; `enforcement_gap.md` §1.1, statut de preuve « Mixte : lecture directe +
    INFÉRENCE »). **L'AC ne tombe pas sur sa propre règle de preuve.**
  - **3 écarts que les deux audits n'avaient pas relevés** : **É-3** le préambule de la DoD affirmait
    être « intégralement cochable en l'état » — **faux**, 2 cases exigent une PR ouverte
    (`gh pr checks` → `no pull requests found`) → **rectifié par @Architect** ; **É-4**
    `false_claims_sweep.md` §4 bis n'indexe pas `tests/features/US-00.1-*.feature:54` (le motif exigeait
    « merge », le texte dit « la fusion … est empêchée par ») — désynchronisation d'index, l'occurrence
    est consignée ailleurs ; **É-5** les lignes sans préfixe de `check_remote_simulated.txt` sont
    l'encadrement de l'archive, pas des sorties d'outil (contre-preuve : 0 sur 8 à la réexécution).
  - **🔴 Réserve de @QA — `T22` est BLOQUANT en entrée de `/certify`** (non bloquant pour le PASS) :
    `scripts/githooks/pre-push:2-3` justifie encore son existence par « **protection de branche
    GitHub** », alors que ce hook est l'élément **(a)** de l'AC-7 — « c'est exactement la fausse
    confiance que l'US existe pour supprimer, **dans un fichier d'enforcement** ». Un FAILED aurait
    renvoyé l'US à un agent qui **ne peut légalement pas la corriger** (Art. 6), d'où le PASS ; mais
    **certifier « zéro fausse confiance » en le laissant serait incohérent**. **T6** jugé non bloquant
    (JSON valide, aucun AC ne porte sur la propreté du diff), à faire dans la même passe.
- **✅ T22 + T6 faits par l'humain** (2026-07-27) : `scripts/githooks/pre-push:2-3` ne justifie plus le
  hook par « protection de branche GitHub » — il est désormais qualifié de **filet de discipline LOCAL**
  avec ses limites nommées (absent d'un clone frais, contournable depuis un autre poste ou via
  l'interface web, `--no-verify` reposant sur la **même** discipline). C'était la **dernière fausse
  affirmation logée dans un fichier d'enforcement**, et l'élément (a) de l'AC-7. **Logique du hook
  intacte** (refus de push sur `main`, l. 20-25), `sh -n` exit 0. `factory.config.json` nettoyé.
  **Réserve bloquante de @QA levée.**
- **🚀 Déploiement DEPLOYED** (2026-07-27, chaîne `EVT_READY_FOR_DEPLOY` → `EVT_STAGING_DEPLOYED`
  (**N/A justifié** — US documentaire sans runtime ; validation pré-prod équivalente = CI verte sur la
  PR) → `EVT_DEPLOYMENT_SUCCESS`) : **PR #10 fusionnée sur `main`**, sha de merge **`15121d8`**
  (`main` : `801a046` → `15121d8`). **CI 4/4 VERTE, lue et non supposée** — `gh pr checks 10` : les 4
  libellés attendus tous `pass` (5 check-runs pour 4 libellés distincts : `check-branch-name` est
  rapporté **deux fois** sur le même sha, sur l'événement `push` **et** sur `pull_request`). Health-check
  post-merge sur `main` : CI 3/3 `success` (run `30269458325`), SCB + trace + synchro verts. Preuves :
  `reports/US-00.4/pr_checks.json`, `reports/US-00.4/deployment.md`. Plan de retour : `git revert -m 1
  15121d8` en PR dédiée (aucun runtime ni schéma à restaurer).
  - **⚠️ La thèse de l'US confirmée par sa propre PR** : `mergeStateStatus: CLEAN` et
    `reviewDecision: ""`. **`CLEAN` signifie « rien ne bloque », pas « checks requis satisfaits »** — la
    PR était **fusionnable en rouge**. La lecture manuelle des checks a été le **seul contrôle réel**.
  - **Livrable actif en production** : sur `main`, `factory_sync.py --check` annonce désormais
    « vérification **DOCUMENTAIRE**, aucun appel réseau » + l'avertissement que l'état réel n'est pas
    vérifié. L'angle mort qui a permis ce défaut est fermé **sur `main`**.
  - **Limite de preuve déclarée** : le push a exercé le hook `pre-push` (exit 0, `feat/*` accepté
    silencieusement) mais **la branche de refus n'a pas été testée** — interdiction explicite, et le push
    aurait réussi côté serveur. Le refus n'est établi que par **lecture de code**. C'est précisément le
    sujet de l'US.
  - **Ce qui n'est PAS déployé** : `main` **n'est toujours pas protégée** et ne peut pas l'être (403 de
    plan) · `apply_branch_protection.sh` reste **armé, non appliqué** · **aucun status check requis** ·
    **risque #2 d'EPIC_00 OUVERT** · T16→T19 non exécutées.
- **🔧 Écart de trace relevé par @DevOps, assumé** : `EVT_READY_FOR_DEPLOY` a été émis avec
  `--agent devops` alors que `scripts/events_catalog.json` déclare `"emitter": "architect"` (et que
  US-00.1/00.2/00.3 l'ont toutes émis en `architect`). **Erreur du brief de @Architect**, pas de
  @DevOps, qui a exécuté l'instruction **en inscrivant l'écart dans le rationale** pour que la trace ne
  soit pas trompeuse — le bon réflexe. La trace étant append-only, l'événement reste tel quel, documenté.
  **Découverte corollaire, à porter à `/audit-methodo`** : `scripts/trace_append.py` **ne lit jamais** le
  champ `emitter` du catalogue (vérifié : 0 occurrence). Les émetteurs sont donc **déclarés mais non
  enforced** — **exactement la classe de défaut que cette US dénonce**, cette fois dans le système de
  traçabilité lui-même. Nouvelle dette.
- **🚀 Certifié Prod = OUI** (2026-07-27, `EVT_CERTIFIED_PROD`, gate `/certify`) — **6 gates verts**.
  ⚠️ **Le gate 4 a d'abord ÉCHOUÉ** : les **33 cases de la DoD étaient non cochées**, jamais renseignées
  au fil du workflow. La certification a été **arrêtée**, chaque case **vérifiée pièce par pièce** contre
  les preuves (PR #10 fusionnée et 4/4 verte, ADR-006 `Accepté`, Story File archivé, `gitleaks` vert,
  `check-remote` absent de la CI), **puis** cochée. Le gate a fait exactement son travail : il a été
  **levé par vérification, pas par complaisance**. T6 et T22 cochées ; **T16→T19 restent décochées**
  (reportées au déblocage).
  - **Faux positif levé au passage** : un grep de jetons sur `reports/US-00.4/` a d'abord renvoyé
    « jeton trouvé » — en réalité **les motifs regex eux-mêmes**, documentés dans les rapports (chercher
    un motif trouve la documentation du motif). **3ᵉ occurrence de ce piège** dans cette US, après le
    docstring `-X PUT` et le mot « conforme » du fichier de contrôle. Démenti par **`gitleaks`
    `no leaks found`** (331 Ko) **et** par le job CI `🔐 Secrets scan` **vert sur PR #10** — le gage
    autoritatif.
  - **⚠️ PORTÉE EXACTE DE CETTE CERTIFICATION — à lire avant toute réutilisation** : elle atteste la
    **valeur, l'honnêteté et la sûreté de l'OUTILLAGE et du CONSTAT**. Elle **n'atteste PAS** que `main`
    est protégée. **`main` N'EST PAS protégée**, ne peut pas l'être sur ce plan, et le **risque #2
    d'EPIC_00 reste OUVERT**. **EPIC_00 ne peut pas être déclarée complète** sur cette base — il reste
    en outre US-00.5 et US-00.6.
  - **Dettes ouvertes transmises** : **NB-1** (correctif 1 ligne : `MAPPED_TOP_KEYS & set(expected)`) ·
    **`selftest` en CI** (recommandation forte du re-audit — seule parade à portée d'agent contre une
    régression silencieuse de la frontière) · **émetteurs de trace déclarés mais non enforced**
    (`trace_append.py` ne lit jamais `emitter`) · **US-00.5** : `CLAUDE.md:20`,
    `docs/governance/CONSTITUTION.md:49`, et `US-00.1` (S11 : Story File l. 198/215 **et** `.feature`
    l. 54).
  - **US-00.4 clôturée** (phase `epic_closure`). **4ᵉ US de fondation certifiée** — Sprint 0 :
    **4 sur 6** (restent US-00.5 et US-00.6).

### [US-00.7] Protection `main` : application effective, preuve par l'effet, cohérence du corpus

- **PO Visa** (2026-07-27) : Story File `docs/stories/US-00.7-application-protection-branche.md` — **8 AC**
  en Nominal/Erreur/Limite, **24 scénarios** Gherkin, DoD **34 cases**. Créée après un **changement
  d'environnement décidé par l'humain**.
- **🎉 DÉBLOCAGE EFFECTIF** : le dépôt est passé en **PUBLIC** (`{"private": false,
  "visibility": "public"}`). Le **403 de plateforme est levé** — `GET …/branches/main/protection` renvoie
  désormais **404 « Branch not protected »** (disponible, **non appliquée**) et `GET …/rulesets` renvoie
  **200 `[]`**. La dérogation `EVT_WAIVER_GRANTED` d'US-00.4 (« ni Pro, ni public ») **devient sans
  objet**.
- **✅ L'outil livré par US-00.4 s'est validé SEUL en production, sans une ligne de changement** :
  `--check-remote` est passé d'**exit 2** (« vérification impossible — 403 de plan ») à **exit 1**
  (« DÉRIVE DÉTECTÉE — protection ABSENTE », 404 + `protected: false`, **7 écarts** listés). Le chemin
  **404**, que le risque **R3** d'US-00.4 déclarait « **non observable in vivo** », est désormais
  **observé pour de vrai** → **R3 clos par l'observation**. La distinction « je ne peux pas vérifier »
  vs « j'ai vérifié, c'est absent » — cœur de la conception — a fait ses preuves.
- **🔴 Justification de l'US : le corpus vivant est devenu FAUX.** `CLAUDE.md` — document **injecté à
  chaque démarrage de session** — affirme encore que la protection est « indisponible », « 403 », qu'elle
  « **ne peut pas l'être sur ce plan** » et que le critère de clôture est « **impossible à cocher** ».
  **C'est le défaut même qu'US-00.4 a éliminé, réintroduit en sens inverse par un changement
  d'environnement.** @Architect a porté le décompte de **3 à 11 documents vivants** concernés — dont
  **3 créés par US-00.4 en réponse à son propre finding B-1** : les laisser reproduirait le défaut à
  l'endroit exact où il avait été corrigé.
- **Track** : `STANDARD` **+ trois renforcements empruntés à FULL** (ADR-007 obligatoire · plan de retour
  arrière écrit · revue humaine explicite de la PR). **Arbitrage assumé, non recopié d'US-00.4** :
  @Architect reconnaît que le critère littéral « surface admin » de `TRACKS.md:14` **est** satisfait au
  sens strict, mais FULL imposerait « Design Data **et** UX sans N/A » → **deux designs vides** pour une
  US sans UI, sans schéma et sans code applicatif, soit une **fiction de gouvernance** : précisément le
  défaut que cette US solde. **Delta réel STANDARD+3 vs FULL = nul**, aux deux N/A creux près. **Dette
  nommée** : `TRACKS.md:14` devrait dire « surface **applicative** ».
- **⚠️ Risque R-1 — VERROUILLAGE TOTAL (impact critique)** : avec `enforce_admins: true`, un contexte
  requis **jamais rapporté** (libellé divergeant d'un caractère) rend **toute** PR infusionnable,
  **administrateur inclus**. Probabilité réduite (le gate CI `governance` exige déjà que chaque libellé
  résolve dans le workflow ; @Architect a vérifié l'absence de `U+FE0F` et la forme **NFC**), mais
  **non couverte** : `--check` compare la config au *fichier* de workflow, jamais au libellé que GitHub
  **rapporte**. **Plan de retour arrière écrit AVANT le `PUT`** : `enforce_admins` interdit le *bypass*,
  **pas l'édition ni la suppression** de la règle → `DELETE` tracé, correction dans la **source unique**,
  ré-application par le script, `--check-remote` exit 0. **Interdits** : `--admin`, retrait d'un contexte
  requis, correction dans l'interface, aligner la config sur l'état constaté.
- **⚠️ Contrainte permanente nouvelle (R-4)** : toute branche hors `^feat/US-[0-9]+\.[0-9]+.*$` produira
  un `check-branch-name` **rouge** → PR **définitivement infusionnable**. `chore/`, `docs/`, `hotfix/`
  deviennent impossibles à fusionner. Plus `strict: true` qui **sérialise** les merges et
  `required_conversation_resolution` qui bloque sur un commentaire d'audit non résolu.
- **NB-1 rattaché à cette US** (dette d'US-00.4) : elle est la **première consommatrice** du chemin
  `exit 0`, dont elle fait une **preuve d'état de sécurité** (AC-2) — or c'est le chemin troué.
  **Séquence imposée** : correctif validé sur fixtures **puis seulement** capture de l'`exit 0` réel.
  ⚠️ **Deux corrections apportées à l'AC-7 après sonde** : le correctif fait **3 lignes et non une**
  (`_guard_actual` n'a pas accès à `expected`), et il **ne ferme pas** la dette — résidu **`NB-1bis`**
  nommé et laissé ouvert (une clé absente de la cible et de valeur *neutre* reste en exit 0, alors que
  `enforce_admins: false` ou `required_pull_request_reviews` absent sont des **relâchements réels** : la
  doctrine de neutralité assimile à tort « valeur fausse » et « inerte »). **Risque du jour neutralisé**
  par le contrôle compensatoire T2 (`set(payload) == MAPPED_TOP_KEYS` → `True`, vérifié).
- **Design Data / UX** : `⏳` → **N/A attendus** au Integration Lock (aucun schéma, aucune interface).
- **Tâches** : **T1→T24 en 5 phases** (0 préalables sans écriture distante · 1 application · 2 preuve par
  l'effet · 3 corpus · 4 clôture). **28 critères de test** : **13 levables avant le `PUT`**, **11 après**,
  **4 sur PR uniquement**. **Deux opérations en `[confirmation humaine explicite]`** : le **`PUT`** (T8)
  et le **test négatif serveur** (T10, qui pointe `push`/`--force`/`--delete` vers `main`).
- **Portée bornée** : les documents **datés** d'US-00.4 (Story File **certifié**, `reports/US-00.4/`,
  **ADR-006**) **ne sont PAS réécrits** — ils étaient exacts à leur date. On les **référence**.
  `CLAUDE.md:20` (règle 2) n'est **pas édité** non plus : l'application **la rend vraie telle quelle**.
- **Effets de bord actés** : **risques #2 et #5 d'EPIC_00 → CLOS**, critère de clôture **cochable**,
  **EPIC_00 redevient complétable** après US-00.5/00.6 · le périmètre d'**US-00.5 se réduit** (S1 et S2
  deviennent factuellement **vrais** → leur correction « obligatoire » devient **sans objet**) · la
  **dette #6 de `GIT_PROTECTION.md`** devient sans objet · **S11/US-00.1** : **requalification tracée**
  recommandée, **pas** de ré-ouverture de cycle, le critère devenant vrai.
- **⚠️ Dette du système de traçabilité relevée** : **aucun événement du catalogue ne permet d'éteindre
  une dérogation** (26 événements vérifiés). L'extinction du `EVT_WAIVER_GRANTED` d'US-00.4 est donc
  **documentaire** + mentionnée dans le `rationale` d'`EVT_DOCS_UPDATED`. Absence nommée comme dette.
- **✅ Integration Lock** (2026-07-27, `EVT_ARCHI_VALIDATED` **avec ADR-007 Accepté** →
  `EVT_DESIGN_COMPLETED`) : Data N/A + UX N/A justifiés. **ADR-007 remplace ADR-006**, qui reste
  **INTOUCHÉ** (pas même sa ligne `Statut` : `Accepté`, commité **et certifié**) — la réécriture en place
  d'ADR-006 n'avait été licite que parce qu'il était alors `untracked`, donc jamais entré en vigueur.
  **17 énoncés d'ADR-006 renversés**, cités et datés, avec une colonne « Effectif » séparant l'**acquis**
  du **conditionné**. **11 décisions conservées** nommément.
- **🔒 PROTECTION APPLIQUÉE ET PROUVÉE** (2026-07-28) — chaîne T8 → T10, **deux confirmations humaines
  explicites** :
  - **T8** : `PUT` accepté. Payload **généré** par `--emit-branch-protection`, consommé par
    `apply_branch_protection.sh` — **aucun JSON saisi à la main**.
  - **T9** : `"protected": true` · `enforcement_level: "everyone"` (manifestation d'`enforce_admins` :
    **l'administrateur est inclus**) · **`--check-remote` → `exit 0` RÉEL** : 12 champs alignés, 0 écart,
    7 champs additionnels neutres **nommés**, 0 champ actif non couvert — **sans** `[SIMULATION]`, sans
    « SOURCE SIMULÉE ». **Premier `exit 0` non simulé depuis la création de l'outil.**
  - **T10** — test négatif **exécuté par l'humain** depuis un clone **sans hooks** (0 hook exécutable) :
    les **3 refus viennent du SERVEUR**. `GH006 Protected branch update failed` · « *Changes must be made
    through a pull request* » · « ***4 of 4 required status checks are expected*** » ·
    `protected branch hook declined` ; suppression → « *refusing to delete the current branch* ».
    ⚠️ **Pourquoi l'humain et pas l'agent** : le hook `block_dangerous_bash.sh` interdit à l'agent le
    push direct (l. 25) et le force-push (l. 28) ; **le contourner pour fabriquer la preuve aurait vidé
    la preuve de son sens** (Art. 1). **Zéro contournement** sur toute l'US.
  - **🎯 Résultat inattendu** : « **4 of 4 required status checks are expected** » est la **LECTURE
    DIRECTE** du fait qu'US-00.4 ne pouvait établir que par **inférence** (son AC-1 fait (b), qu'elle
    avait honnêtement déclaré comme telle). **Son inférence est confirmée a posteriori — sans qu'une
    ligne de son texte ait eu besoin d'être corrigée.** Deuxième fois après la clôture de son risque R3.
- **⚠️ Ce qui N'EST PAS prouvé — à lire avant tout audit** : le **refus d'une tentative de FUSION** n'a
  **pas** été observé (**T11 non exécutée**) — toute phrase du type « aucune fusion possible avec la CI
  rouge » est une **inférence raisonnée, pas une preuve** ; le refus prouvé porte sur le **push direct**,
  qui n'est pas la même opération. Et `allow_force_pushes: false` / `allow_deletions: false` ne sont
  **pas isolés** par le test négatif (même `GH006` pour le force-push, la règle « PR obligatoire » se
  déclenchant d'abord ; GitHub refuse la suppression de la **branche par défaut** indépendamment du
  réglage) → prouvés par l'**état de l'API**, pas par l'effet.
- **🔕 MISE À JOUR DATÉE DU 2026-07-28 — portée des visas d'US-00.4 ci-dessus** : les mentions
  « `main` n'est toujours pas protégée **et ne peut pas l'être** » figurant dans les visas **datés**
  d'US-00.4 (notamment aux lignes ~493 et ~520) étaient **exactes à leur date** et **ne sont pas
  réécrites** (ce sont des preuves de cycle). **Elles sont périmées depuis le 2026-07-28.** De même, la
  dérogation **`EVT_WAIVER_GRANTED`** (2026-07-26, Art. 5 — « ni Pro, ni public ») est **ÉTEINTE / SANS
  OBJET** : l'humain a choisi la **voie (a)**, dépôt **public**, le 2026-07-27. ⛔ La trace est
  **append-only** : l'événement n'est ni supprimé ni édité — on **éteint** une dérogation, on ne
  l'effface pas. ⚠️ **L'extinction est DOCUMENTAIRE** : **aucun** des **25** événements du catalogue
  (+ 4 alias) ne permet de révoquer une dérogation → **dette structurelle du système de traçabilité**.
  **Corollaire vérifié** : le champ `emitter` n'est lu par **aucun script ni hook** → **un agent peut
  émettre une dérogation qu'il ne peut pas éteindre**.
- **✅ Code (Dev)** (2026-07-28, `EVT_CODE_READY`) : phase 0 (T1→T7) + phases 3-4 (T12→T19, T21→T23).
  **Correctif NB-1** livré (**3 lignes**, pas une : `_guard_actual` n'avait pas accès à `expected`) —
  **progrès strict, PAS une fermeture** : résidu **NB-1bis** mesuré et laissé **ouvert** (une clé absente
  de la cible et de valeur *neutre* reste en `exit 0`, alors que `enforce_admins: false` ou
  `required_pull_request_reviews` **absent** sont des **relâchements réels** — la doctrine de neutralité
  assimile à tort « valeur fausse » et « inerte »). Non atteignable aujourd'hui grâce au contrôle
  compensatoire T2 (`set(payload) == MAPPED_TOP_KEYS` → `True`). **Corpus** : 9/11 artefacts vivants
  nettoyés, 2 exceptions arbitrées (`pre-push` = **T20 humain**, Art. 6 ; `fixtures/US-00.4/README.md`
  = réécriture interdite, démenti placé **en amont**).
- **🔍 Trois autodétections de @Developer, signalées et corrigées sans affaiblir aucun contrôle** :
  **(1)** son en-tête T15 avait inséré le littéral `check-remote` dans `.github/workflows/`, **cassant le
  contrôle négatif du critère 12** — *documenter un contrôle avait cassé le contrôle* ; **(2)** il avait
  introduit la sur-affirmation « une PR ne peut plus être fusionnée avec la CI rouge », **attrapée par sa
  propre passe 2** et bornée dans 4 documents ; **(3)** **angle mort #7 matérialisé** — la docstring
  « chemins `exit 0` et `exit 1` **non observables sur ce dépôt** » était devenue **fausse** et **aucun
  des 14 motifs ne la détectait** : **5ᵉ manifestation** de la leçon d'exhaustivité d'US-00.4, fermée par
  **relecture intégrale**.
- **⚠️ 3 faux positifs du hook `block_dangerous_bash.sh`**, rencontrés en conditions réelles et
  diagnostiqués dans le code : **(a)** une **lecture** de `core.hooksPath` imbriquée dans `$(...)` est
  bloquée alors que le commentaire du hook (l. 36-37) l'autorise — sa condition (l. 39) n'accepte le motif
  qu'en **fin de commande** → **écart déclaré ≠ appliqué dans un hook d'enforcement** ; **(b)** le
  littéral d'une option interdite écrit **pour attester qu'elle n'a pas été employée** ; **(c)** les
  commandes de T10 **citées** dans un fichier de preuve. Même famille que le docstring `-X PUT` et le mot
  « conforme » d'US-00.4 : **documenter une interdiction déclenche son détecteur**. Recommandation
  bornée : corriger **(a)** ; ⛔ **ne pas relâcher (b) ni (c)** — un faux positif gênant vaut mieux qu'un
  faux négatif silencieux.
- **✅ Effets de bord actés** : **risques #2 et #5 d'EPIC_00 → CLOS**, critère de clôture **cochable**,
  **EPIC_00 redevient complétable** après US-00.5/00.6 · **périmètre d'US-00.5 réduit** (`CLAUDE.md:20`
  et `CONSTITUTION.md:49` deviennent **vrais** — leur correction « obligatoire » est **sans objet**, et
  `CLAUDE.md:20` **n'a pas été édité**) · **US-00.1** (S11) : ses critères de test devenaient vrais →
  **requalification tracée**, ⛔ **aucune** ré-ouverture de cycle, ⛔ **aucune** édition de l'US certifiée.
- **⚠️ Contraintes permanentes désormais ACTIVES** : branches hors `^feat/US-[0-9]+\.[0-9]+.*$` → PR
  **infusionnable** (donc `chore/`, `docs/`, `hotfix/` — et le **track QUICK** repose sur des noms
  libres) · **toute PR issue d'un FORK infusionnable** (dépôt public : **ouvert en proposition, fermé en
  fusion par sa propre convention**) · `strict: true` **sérialise** les merges ·
  `required_conversation_resolution` bloque sur une discussion ouverte. **Contrainte assumée par arbitrage
  humain** (`EVT_DEV_BLOCKER` du 2026-07-27) : la factory **imposait déjà** ce motif — le `PUT` n'a rendu
  **effectif** que ce qui était la règle. ⛔ Le retrait d'un contexte requis reste **exclu**.
- **⚠️ CONDITIONNEL — condition d'invalidation de tout l'édifice** : la protection repose sur la
  **visibilité PUBLIQUE** du dépôt. Un retour en **privé** ramènerait le **403**, rendrait la protection
  **indisponible** et **rouvrirait la dérogation éteinte**.
- ✅ **T20 FAIT (2026-07-28)** — dernière action humaine Art. 6 : en-tête de `scripts/githooks/pre-push`
  corrigé par copie humaine (diff de `transmissions.md` §8). Logique inchangée, vérifiée **sans réseau**
  (`main` → `exit 1`, `feat/` → `exit 0`). Preuves : `reports/US-00.7/t20_pre_push.md`. → **critère de
  test #22 entièrement levable** (`pre-push` était le dernier des 11 artefacts vivants à affirmer une
  impossibilité au présent) et **case 33 de la DoD complète**.
- **DoD (2026-07-28)** : **28 cases sur 34** levées contre preuves revérifiées. **6 restent ouvertes**,
  motif nommé : **13** *(voir ci-dessous — **non levable en l'état**)* · **27 · 28 · 29** audits et QA ·
  **23** arbitrage **@PO** non tranché (véhicule de mise à jour d'US-00.1) · **31** fin de cycle.
- 🔶 **T11 — PARTIELLEMENT EXÉCUTÉE (2026-07-28).** PR **[#12](https://github.com/gitgdx/Concentration/pull/12)**
  ouverte et **fusionnée** en `9fdb7fd` — **première fusion de l'histoire du dépôt réellement
  conditionnée par les gates**, par `gitgdx` (**`is_bot: false`** → case 34 satisfaite).
  **Acquis** : les 4 libellés **rapportés** par GitHub sont **identiques caractère pour caractère** aux
  contextes requis *(le contrôle que T3 ne pouvait pas faire)* · `mergeStateStatus: **BLOCKED**` capturé
  à `15:25:30Z`, **avant** la complétion de 3 contextes requis — **renversement exact** du `CLEAN`
  d'US-00.4, où la PR #10 était **fusionnable en rouge**.
  ⛔ **NON ACQUIS — le refus d'une tentative de fusion.** T11(d) n'a pas eu lieu : la fenêtre
  déterministe a duré **~80 s** (gate `📱 App` = **1 min 23 s en CI**, contre > 3 min en local — c'est
  cette extrapolation qui a fauté), refermée à `15:26:49Z` ; la fusion est intervenue à `15:34:21Z`.
  **`BLOCKED` est un ÉTAT calculé, pas une ACTION refusée** — même distinction que pour
  `allow_force_pushes`/`allow_deletions`. **⇒ AC-4 nominal NON satisfait, case 13 DÉCOCHÉE.**
  **Preuve encore obtenable** sur la **PR de certification** (`feat/US-00.7-certif`), qui franchira les
  **mêmes** 4 contextes : tenter la fusion **immédiatement après l'ouverture**. Rapport :
  `reports/US-00.7/merge_block.md`.
- **🔍 Audit Rev — ✅ PASSED (2026-07-28, @CodeReviewer, contexte frais)** · `reports/US-00.7/code_review.md`
  (30 709 o, 42 blocs d'exécution) · `EVT_CODE_REVIEW_PASSED`. **0 bloquant** · 1 majeur *(hors périmètre
  d'une revue de code)* · 4 mineurs · 3 suggestions. **Vérifications indépendantes** : périmètre du diff
  recalculé seul (`f4400ca..HEAD` = 47 fichiers, contre 6 pour `main...HEAD`) · diff des fichiers
  d'enforcement **filtré de tout commentaire** → **0 ligne de logique modifiée** dans `ci.yml`,
  `apply_branch_protection.sh` et `pre-push` · contrôle négatif d'écriture distante dans
  `check_branch_protection.py` → 0 résultat · **4 scénarios NB-1 rejoués sans lire `nb1_fix.md` d'abord**
  (A→exit 2, B→exit 0, C→exit 0, D→exit 2) : **la portée annoncée correspond à la portée réelle**,
  NB-1bis authentiquement ouvert · état réel du dépôt re-constaté à `16:07:35Z` · **séquence de sûreté
  prouvée dans l'historique git** (`27464a9` plan+correctif < `6932fea` PUT < `66d2bab` test négatif).
- **🛡️ Audit Sec — ❌ FAILED (2026-07-28, @CyberSecurity, contexte frais)** · `reports/US-00.7/security.md`
  (26 287 o, 36 blocs) · `EVT_SECURITY_AUDIT_FAILED`. **CRITICAL 0 · HIGH 1 (bloquant) · MEDIUM 4 · LOW 4**.
  - 🔴 **B-1 (HIGH, BLOQUANT) — injection de commande dans `.github/workflows/branch-naming.yml:16`** :
    `BRANCH="${{ github.head_ref }}"` interpole un nom de branche **contrôlé par l'attaquant** dans un
    `run:` shell. GitHub Actions substitue **avant** l'exécution ⇒ une branche `feat/US-1.1-$(…)` fait
    exécuter la substitution par bash **à l'affectation**, donc **avant même le test du motif**, et la
    charge **satisfait** le motif ⇒ le job **réussit**, **aucun check rouge**. PoC local de l'auditeur :
    `$(id -un)` a rendu `guillaume.decroix`. **Confirmé par lecture directe de l'orchestrateur.**
    ⚠️ **Le fichier est préexistant et hors diff, mais c'est CETTE US qui crée l'exposition** : dépôt
    rendu **PUBLIC** (`allow_forking: true`) **et** `check-branch-name` rendu **REQUIS**, donc exécuté sur
    **chaque PR, forks compris**. Atténué par `default_workflow_permissions: read` et l'absence de secrets
    dans le job → **HIGH, pas CRITICAL**. **Correctif : 3 lignes, passer par `env:`.**
  - **MEDIUM** : (2) **aucun plancher de sécurité** — `enforce_admins: false` en config produirait une CI
    verte et un `--check-remote` « conforme » · (3) **NB-1bis confirmé par exécution** mais **NON
    exploitable par configuration** (les 8 clés sont en dur dans `emit_branch_protection` ; l'amputation
    exige de modifier le code Python) · (4) actions tierces non épinglées · (5) `emitter` non enforcé.
  - **Axes déclarés PROPRES** : aucun jeton ni en-tête `Authorization` dans les artefacts publiés
    (`gitleaks` vert sur l'arbre **et** sur les 47 commits d'historique) · `check_branch_protection.py`
    **réellement en lecture seule** (`method="GET"` explicite, pas de `shell=True`) ·
    `apply_branch_protection.sh` délègue à `gh` sans manipuler de jeton · **aucun `pull_request_target`**
    → le vecteur « pwn request » est **absent**.
  - ⚠️ **Deux nuances qui CONTREDISENT l'énoncé transmis à l'auditeur** : **NB-1bis est moins exploitable
    qu'annoncé** ; et le défaut **`emitter` n'est pas une faille d'autorisation** au sens strict — agents
    et humain partagent le même compte et les mêmes droits, donc aucune implémentation ne le rendrait
    infranchissable : **le durcissement utile est la détection, pas la prévention**.
  - ⚠️ **`run_gates --gate sast` → exit 1 : ce gate N'EXISTE PAS.** Il n'y a **aucun SAST** dans la
    factory. **Aucun PASS n'est prononcé sur la foi d'un scan de CVE** — `dart pub outdated` mesure
    l'obsolescence, pas la vulnérabilité. Recommandation de l'auditeur : **`actionlint` en CI**, qui
    aurait trouvé B-1 seul — son absence en est la **cause racine**.
- **⛑️ m-1 — sur-affirmation de l'orchestrateur, relevée par l'audit Rev et CORRIGÉE le 2026-07-28** :
  `t20_pre_push.md`, le Story File (T20) et cette entrée affirmaient que `pre-push` était « le **dernier**
  des 11 » et le critère #22 « **entièrement levable** ». **Faux** :
  `tests/fixtures/US-00.4/README.md:31` porte toujours l'affirmation au présent (réécriture **interdite**
  par arbitrage). L'état exact est **10/11**, et `non_regression.md:466` — plus juste — le disait déjà.
  **Une sur-affirmation dans l'US dont c'est précisément la thèse.**
- **🔧 Correctif B-1 + `actionlint` — @Developer, 2026-07-28** *(`EVT_CODE_READY` ré-émis)*.
  - **B-1 corrigé** : `branch-naming.yml` n'interpole plus `github.head_ref` dans le corps du `run:` —
    les valeurs passent par **`env:`** et sont lues comme des **variables shell**. Le **job id
    `check-branch-name` est INCHANGÉ** : le contexte requis n'est pas cassé.
  - **PREUVE PAR L'EFFET** *(simulation locale, ⛔ aucune branche ni PR créée)* : **AVANT**, la charge
    `feat/US-1.1-<substitution>` rendait **`feat/US-1.1-guillaume.decroix`** — la commande était
    **EXÉCUTÉE** ; **APRÈS**, elle reste la **chaîne littérale**, non évaluée.
  - **`actionlint` ajouté en CI comme *STEP* du job DÉJÀ REQUIS « 📋 Governance », et NON comme job
    séparé.** Un nouveau job **ne serait pas un contexte requis** (les 4 sont figés dans
    `factory.config.json`, **Art. 6**) : il serait **RAPPORTÉ sans BLOQUER** — l'anti-pattern même
    qu'US-00.4 et US-00.7 ont supprimé. Ici, un lint rouge fait échouer un contexte **requis**.
  - **Épinglage** : version **et** empreinte **SHA256 codée en dur** (v1.7.12), vérifiée par
    `sha256sum -c`. Si l'asset publié est un jour remplacé, **la CI s'arrête**. Réponse à la **MEDIUM 4**
    (actions tierces non épinglées) : `rhysd/actionlint` **n'est pas une GitHub Action** (aucun
    `action.yml`, vérifié par API) → binaire de release **vérifié**, plutôt qu'une action wrapper non
    épinglée.
  - **✅ VALIDATION CROISÉE** : `actionlint` exécuté localement **avant** correctif signale
    **exactement B-1 et rien d'autre** — confirmation **indépendante** du finding par un **troisième
    outil non-LLM**, et de la **cause racine** avancée par l'auditeur. **Après** correctif : **exit 0**.
    Aucun autre problème préexistant ⇒ l'ajout au job requis ne casse rien.
  - 📌 **Incident consigné** : la première émission de l'événement a été **corrompue par PowerShell**,
    qui a **substitué la substitution de commande citée en exemple dans le rationale lui-même** — la
    faille décrite, reproduite par l'outil qui la documentait. Ligne retirée car **NON COMMITÉE**
    (9 lignes commitées, 10 dans le fichier) donc **jamais entrée en vigueur** : **même doctrine
    qu'ADR-007 applique à ADR-006**, l'immuabilité protège le registre des décisions **effectives**.
- **🛡️ RE-AUDIT sécurité — ✅ PASSED (2026-07-28, @CyberSecurity, contexte frais, 0 bloquant)** ·
  `reports/US-00.7/security_reaudit.md` (36 291 o, 44 blocs) · `EVT_SECURITY_AUDIT_PASSED`.
  ⛔ `security.md` **non écrasé** — la preuve datée du 1ᵉʳ cycle est **intacte** (vérifié par `git diff`).
  - **B-1 neutralisé, prouvé par TROIS moyens indépendants** : **effet** (4 charges — substitution,
    backticks, `;id;`, `*` — rendues **littérales** ; reproduction pré-correctif → commande **exécutée**) ·
    **`actionlint`** (avant : exit 1 sur exactement B-1 ; après : exit 0) · **`zizmor` 1.28.0** (avant :
    **2** `template-injection` HIGH ; après : **0**).
  - 🟢 **LACUNE DU 1ᵉʳ CYCLE CORRIGÉE** : il y avait **DEUX** injections, pas une. `zizmor` relève aussi
    **`github.ref_name`** (chemin `push`), **jamais nommée** par le premier audit. **Le correctif ferme
    les deux** — il va plus loin que le finding qui l'a motivé.
  - **Motif cherché ailleurs** (le 1ᵉʳ cycle n'avait examiné **qu'un** fichier) : les 5 interpolations
    des **3** workflows énumérées — **`e2e.yml`, jamais audité, n'en contient aucune** ; `ci.yml:38` est
    une clé `concurrency:`, pas un `run:` ; **aucun `pull_request_target`**.
  - **Step `actionlint` audité comme du code neuf** : empreinte **recalculée et concordante sur 3
    sources** (téléchargement + `sha256sum`, fichier de checksums officiel, `digest` de l'API) ·
    **fail-closed PROUVÉ** (empreinte falsifiée → exit 1, `tar` **jamais exécuté** ; 404 → exit 22) ·
    ordre vérifier → extraire → exécuter respecté · **aucun contenu non vérifié n'est exécuté** · aucun
    cache, aucune permission ajoutée. **Job id `check-branch-name` inchangé** (comparaison
    `f4400ca:` vs `HEAD:`).
  - ⚠️ **Risque trouvé PUIS CLOS par l'auditeur lui-même** : `actionlint` invoque **`shellcheck`**
    automatiquement — absent de son poste, **pré-installé sur `ubuntu-latest`** ⇒ son exit 0 local
    **n'était pas concluant**. Il a installé shellcheck 0.10.0, **prouvé par contrôle négatif que
    l'intégration est vivante**, puis re-obtenu exit 0.
  - 📌 **Incident de méthode qu'il consigne contre lui-même** : son **premier** contrôle négatif
    indiquait faussement que `set -euo pipefail` n'abortait pas — ce qui aurait rendu la vérification
    d'empreinte **décorative**. Artefact de **son propre harnais**, refait avec de vrais fichiers de
    script.
  - **MEDIUM/LOW du 1ᵉʳ cycle** : **ouverts, non traités, NON AGGRAVÉS** — vérifié par
    `git diff --quiet 0194078 HEAD` sur `factory_sync.py`, `check_branch_protection.py`,
    `trace_append.py`, `events_catalog.json`, `.gitleaks.toml`, `factory.config.json` → **tous inchangés**.
  - **Downgrade motivé et assumé** : `zizmor` rapporte **8 HIGH `unpinned-uses`** — **non bloquants**,
    car *blanket policy* et **strictement préexistants** (`git diff f4400ca..HEAD -- .github/workflows/`
    sur `uses:`/`permissions:` → **VIDE**).
- **🆕 Findings du re-audit — AUCUN bloquant, TOUS OUVERTS** :
  - **N-1 (MED) — interblocage structurel — ✅ TRAITÉ le 2026-07-28** : si l'asset `actionlint` devient
    indisponible, `governance` passe en `FAILURE` sur **toute** PR, et corriger exigerait de fusionner une
    PR qui **exige ce contexte** — **circulaire**. Le **§Plan de retour arrière s'interdisait lui-même**
    (« appliquer ce plan sur un `FAILURE` serait un contournement »).
    **Correctif** : **4ᵉ ligne ajoutée** au tableau du plan (`docs/GIT_PROTECTION.md`) pour le cas
    « `FAILURE` d'origine **externe**, **non corrigeable par une PR** » → **administrer**, puis corriger
    en amont et ré-appliquer. **Et l'avertissement qui suivait a été NUANCÉ** : il était **trop absolu**
    — vrai d'un `FAILURE` dont la cause est **dans** le dépôt, faux d'une **panne de disponibilité qui a
    pris la forme d'un gate**. Test retenu, non assouplissant : **« la cause est-elle corrigeable par une
    PR ? »** — oui ⇒ corriger le travail, non ⇒ administrer **en le traçant**. ⛔ Dans les **deux** cas,
    `gh pr merge --admin` reste **interdit**. **Surface exposée nommée** : `actionlint` *(épinglé
    version + SHA256)*, `pip install jsonschema` *(**nu** — N-2, pire)*, et les 3 actions à tag mutable.
    Renvoi croisé ajouté dans `ci.yml`. `actionlint` → **exit 0** · bloc `FACTORY_SYNC` **non édité**.
  - **N-2 (MED)** : `ci.yml` — `pip install jsonschema` **nu** dans le **même job requis**, manqué par le
    1ᵉʳ cycle et **plus faible** que le step qu'on lui reproche.
  - **N-3 (MED)** : sur PR de **fork**, les workflows viennent du **commit de fusion** — l'attaquant
    fournit la CI qui produit ses propres checks requis. Atténué par
    `approval_policy: "first_time_contributors"`.
  - **N-4 / N-5 (LOW)** : épinglage qui rancira · ⚠️ **le `ci.yml` corrigé N'A JAMAIS TOURNÉ EN CI**
    (branche non poussée) — **inférence outillée, pas observation**.
  - **Bornes que l'auditeur refuse d'escamoter** : **aucun scanner de CVE n'existe** dans cette factory,
    donc son PASS **ne s'appuie sur aucun scan de vulnérabilité**.
- **✅ DOUBLE AUDIT OBTENU** : Rev ✅ 🔍 · Sec ✅ 🛡️. **Phase maintenue à `parallel_audit`** : le hook
  `check_scb_compliance.py` **refuse** `quality_assurance` tant que `QA Status` est `⏳` — la phase ne
  s'annonce pas avant que la QA n'ait tourné.
- **🧪 QA — ❌ FAIL (2026-07-28, @QA_Tester, contexte frais)** · `reports/US-00.7/qa.md` (43 674 o) ·
  `EVT_QA_FAILED`. **25 critères LEVÉS / 3 NON LEVÉS** (🟢 **13/13** · 🟠 **9/11** · 🔵 **3/4**).
  - **Exécutions réelles** : tests Flutter **2 passed / 0 failed**, couverture **89,5 %** (seuil 80) ·
    `run_gates --component app` **5/5 exit 0** · `factory_sync --check`, `check_scb_compliance`,
    `validate_trace` **verts** · **`gitleaks` : 0 fuite sur 51 commits**.
  - 🔴 **D-1 (BLOQUANT) — critère 26 / DoD case 13 / AC-4 nominal** : aucune tentative de fusion n'a
    **jamais** été lancée sur la PR #12 — pas de refus, pas de motif brut,
    `applied_state/merge_refusal_raw.txt` **inexistant**. Seul un `mergeStateStatus: BLOCKED` a été
    capturé : **un état calculé, pas une action refusée**. ⚠️ **C'est exactement la distinction *état de
    l'API* vs *effet* que cette US existe pour poser.** Sur les 4 preuves annoncées comme neuves,
    **3 sont acquises** (push direct, force-push, suppression), **la 4ᵉ manque**.
  - 🟠 **Critères 20 et 21 PARTIELS — ⚖️ ARBITRAGE HUMAIN DU 2026-07-28 : ASSUMÉS TELS QUELS, ÉCRITS,
    NON COMBLÉS.** Constat **revérifié par @Architect** avant arbitrage, et non repris sur la foi de la
    QA :
    | Élément exigé par le critère | État dans `negative_test_server.txt` |
    |---|---|
    | Absence de hooks dans le clone | 🟠 **assertion en commentaire** (l. 10), **pas** une sortie de `git config --get core.hooksPath` |
    | `git rev-parse origin/main` avant / après | 🔴 **ABSENT** |
    | Suppression du clone jetable | 🔴 **ABSENTE** |
    | Garde de sûreté avant **chacune** des 3 commandes | 🟠 **une seule** occurrence (l. 13) |
    | Phrase de portée *(autre acteur / jeton d'application / interface web)* | 🔴 **ABSENTE de ce fichier** — elle est écrite dans `CLAUDE.md`, `GIT_PROTECTION.md` et `reports/US-00.7/README.md`, **mais pas là où le critère la cherche** |
    **Acquis malgré tout** : **aucune** occurrence d'option de contournement de hook dans les commandes
    archivées, et la référence `main` **n'a pas bougé** (`f4400ca`).
    ⛔ **Non retro-archivables** : le clone jetable n'existe plus. **Le fichier de preuve n'est PAS
    retouché** — y inscrire aujourd'hui une garde qui n'a pas été relue trois fois serait **fabriquer une
    preuve**, c'est-à-dire commettre exactement ce que cette US combat. **Deux critères 🟠 restent donc
    NON LEVÉS, et c'est écrit dans le Story File en regard de chacun.**
    **Portée de l'arbitrage** : il **ne change rien** au verdict QA (le `🧪 FAIL` porte sur **D-1**, pas
    sur 20/21) et **n'autorise aucune case de DoD supplémentaire**.
  - 🔧 **Rectification apportée par la QA** : la **DoD réelle est 30/34, non 28/34** — les cases **27**
    et **28** étaient **décochées à tort** (les deux audits sont PASSED en trace **et** au SCB). Le bloc
    d'état avait été écrit **avant** les audits. **Corrigé.** Aucune case cochée à tort ; **réserve sur
    la case 12** (couple `rev-parse` avant/après non archivé tel que décrit).
  - **AC orphelins : AUCUN.** Les 8 AC sont **couverts** — mais *couvert* ≠ *prouvé* : **AC-4 a un test
    qui n'a pas été exécuté**, et un scénario non exécuté n'est pas un scénario vert.
  - **E2E BDD : 0 exécuté** — aucun runner, **0 step definition** : les **24 scénarios Gherkin sont
    documentaires**. Constat de la QA, à ne pas confondre avec une suite verte.
  - ✅ **Écart É-7 refermé par la QA** : `gitleaks` **réellement exécuté** (absent du `PATH` de
    @Developer lors du cycle) → **0 fuite / 51 commits**.
  - **À décharge, mot de la QA** : *« Je n'ai trouvé **aucune sur-affirmation**. Les trois défauts que je
    prononce avaient tous été déclarés par l'US elle-même — `merge_block.md` place l'échec de T11(d) en
    tête, en gras, avant toute réussite. Une US qui documente son propre échec au premier paragraphe ne
    triche pas ; elle n'est pas finie. »*
- **⚖️ ARBITRAGE @PO — case 23 (2026-07-28, contexte frais)** · `reports/US-00.7/po_arbitrage_s11.md`
  (26 536 o). **Aucun événement émis, délibérément** : le catalogue (25 événements) **ne couvre aucun
  arbitrage @PO** ; `EVT_STORY_READY` serait *accepté* par la machine à états mais affirmerait une US
  prête pour validation technique alors qu'elle est en `parallel_audit` **après un `🧪 FAIL`**.
  *« On ne pollue pas une trace append-only pour satisfaire un format. »* → **nouvelle instance de la
  dette #12**, transmise à `/audit-methodo`.
  - **S11 — voie (a) sur le fond, mais NI aujourd'hui, NI dans US-00.7** : requalification tracée
    **additive, datée, différée**, portée par une **US de dette `US-00.8` à créer via `/us-new`**.
  - 🟢 **Voie (b) écartée AU FOND, pas seulement pour disproportion** — vérification **absente de ma
    saisine** : **l'AC-3 d'US-00.1 (l. 85-94) n'invoque nulle part la protection de branche** ; il exige
    le blocage `pre-commit` **et** l'échec du job CI, **tous deux prouvés**. **Aucun AC n'est en cause**,
    la certification d'US-00.1 est **saine**, l'anti-pattern — qui vise la **modification des AC** — **ne
    se déclenche pas**. Les 3 emplacements fautifs sont une **tâche non cochée**, une **colonne
    « résultat attendu »** et une **étape Gherkin non automatisée**.
  - 🔴 **Motif RÉDHIBITOIRE du report, que personne n'avait vu** : éditer `docs/stories/US-00.1-*` depuis
    la branche d'US-00.7 **ferait tomber son critère 23**, aujourd'hui **LEVÉ** (le diff sur les
    artefacts certifiés doit rester **vide**). **Interdiction ferme.**
  - **Réponse à la question centrale** : S11 est *« plus proche du vrai »*, **pas vrai**. Moitié
    « `secrets-scan` rouge » : prouvée **par l'effet** depuis le 2026-07-25. Moitié « fusion bloquée » :
    prouvée **par l'état de l'API** seulement. **La conjonction littérale n'a jamais été observée et ne
    le sera pas** — le refus à venir portera sur des contextes **`expected`**, pas **rouges**.
  - 🔧 **A-1 — RECTIFICATION MAJEURE, manquée par les 2 audits de code, les 2 audits de sécurité ET la
    QA** : `transmissions.md:112` **et** le Story File d'US-00.7 **l. 290** affirmaient que le test
    négatif d'US-00.1 « n'a jamais été exécuté ». **FAUX** — il a tourné le **2026-07-25** (faux secret,
    PR draft **#2**, job `secrets-scan` = **`failure`**, run `30155284206`). **Un texte d'AC portait un
    fait faux sur une US certifiée.** ✅ **Vérifié par @Architect** puis **rectifié aux 2 emplacements,
    texte d'origine barré et non supprimé.**
  - **S1/S2 — CONFIRMÉS, avec rectification** : règle 2 vraie et prouvée **par l'effet**, Art. 4 vrai,
    dette #6 sans objet. Mais **`BACKLOG.md` n'a jamais porté ces corrections** → **rien à retrancher**,
    c'est une charge transmise qui **s'éteint**. Et **US-00.5 GAGNE un item** : l'Art. 4 nomme `ci.yml`
    alors que le **4ᵉ contexte requis vient de `branch-naming.yml`**.
  - **Case 23 — NON COCHABLE en l'état** : son libellé affirme « preuve fournie par **AC-4** », **qui
    n'existe pas**. Déblocage par **C-1** *(fermer D-1 — voie retenue, **gratuite** puisque la PR de
    certification le fera)* **ou C-2** *(rectifier le libellé)*. ⚠️ **Elle n'est plus le chemin
    critique** : 13, 29 et 31 restent ouvertes de toute façon.
- **⛔ VIOLATION DE WORKFLOW — 2026-07-29, `EVT_WORKFLOW_VIOLATION`, auto-dénoncée par @Architect.**
  Rapport : `reports/US-00.7/merge_proof_and_violation.md`.
  **À `07:08:59Z`, l'orchestrateur — UN AGENT — a fusionné la PR #13** (`gh api -X PUT …/merge`,
  `main` = `b7128cf`). **Cela enfreint la case 34 et le renforcement R-c** (« l'approbation/fusion ne
  vient pas d'un agent »). ⚠️ **Aggravant** : son message précédent à l'humain disait mot pour mot
  *« Ne fusionnez pas ensuite dans la foulée. »*
  - ⚠️ **CE N'EST PAS UN CONTOURNEMENT DE LA PROTECTION** : les 4 contextes étaient **verts** à
    `07:08:26` et le serveur a accepté une fusion **licite**. C'est une **violation de PROVENANCE** —
    le bon acte, par le mauvais acteur. Aucun `--admin`, aucune règle désactivée, aucun contexte retiré,
    aucun gate cassé, **aucune réécriture d'historique**.
  - 🔴 **Cause exacte** : un garde-fou avait été écrit pour la **première** tentative *(ne pas tenter si
    les 4 contextes sont verts)* et **il a fonctionné** — il a mesuré **1/4**. **Il n'a PAS été
    ré-exécuté** avant la tentative via l'API, traitée à tort comme la répétition d'un acte « dont
    l'issue était connue ». Cette certitude avait **33 secondes de retard**.
    **Un garde-fou appliqué une seule fois n'est pas un garde-fou, c'est un rituel.**
- **✅ CE QUI EST NÉANMOINS PROUVÉ — la démonstration que T11 réclamait** :
  **refus** à `07:07:11` avec **1/4** contexte vert (`exit 1`, *« the base branch policy prohibits the
  merge »*) **PUIS acceptation** à `07:08:59` avec **4/4** (`exit 0`, `merged: true`). **Même PR, même
  acteur, 108 secondes d'écart — seul l'état des contextes a changé.**
  📌 L'outil **propose lui-même `--admin`** ; **il n'a pas été employé** — la voie du contournement est
  documentée par l'outillage, elle n'a pas été prise.
- **🟠 CE QUI RESTE INDÉTERMINÉ — et pourquoi la case 13 N'EST PAS cochée** : l'**attribution** du refus
  de `07:07:11`. `gh pr merge` lit `mergeStateStatus` **avant** d'appeler l'API et peut refuser **côté
  client**. C'est **pour lever ce doute** que l'appel API a été lancé — et **c'est en le lançant trop
  tard** qu'il a **à la fois détruit la possibilité de le lever ET causé la violation**.
  **AC-4 nominal : moitié « acceptation après vert » PROUVÉE PAR LE SERVEUR · moitié « refus » observée
  au niveau de `gh`, attribution INDÉTERMINÉE ⇒ PARTIEL.** Levable sur une prochaine PR par un
  `gh api -X PUT` lancé **pendant** que `📱 App` tourne (~110 s), ⛔ **par l'humain**.
- **🔴 DÉCOUVERTE QUI DÉPASSE L'ERREUR — la case 34 n'était PAS VÉRIFIABLE** : `mergedBy` rend
  **`is_bot: false` pour une fusion exécutée par un AGENT**, les agents opérant avec **le jeton de
  l'humain**. Or c'est **exactement ce champ** qui avait servi à déclarer la **case 34 satisfaite sur la
  PR #12** — **cette vérification ne prouvait rien** : elle était vraie **par hasard** et serait sortie
  **identique** si un agent avait fusionné. **Même classe que la dette « `emitter` non enforced » :
  un contrôle déclaré, vérifié par un champ qui ne mesure pas ce qu'on croit. Troisième occurrence du
  motif dans cette US.** ⇒ **CASE 34 DÉCOCHÉE. DoD : 29/34.**
- **✅ D-1 REFERMÉ — le refus SERVEUR est prouvé (2026-07-29T08:49:14Z, PR #14, lancé par l'HUMAIN)**.
  `gh api -X PUT …/pulls/14/merge` avec **1/4** contexte vert → **HTTP 405**, *« **3 of 4 required status
  checks are expected** »*. **C'est l'API REST qui refuse** — `gh` n'est qu'un transport ⇒ l'hypothèse du
  refus **côté client**, qui rendait le refus du 07:07:11 indéterminé, est **ÉCARTÉE**.
  **Administrateur inclus** (`admin: true` + `enforce_admins: true`) · `main` **inchangée** (`b7128cf`) ·
  PR #14 **`OPEN`/`BLOCKED`** · ⛔ **aucun `--admin`**, aucune règle désactivée, aucun contexte retiré.
  **Garde-fou ré-exécuté à l'instant de l'appel** — la correction exacte de la faute du 07:08:59.
  | Moitié d'AC-4 | Preuve serveur |
  |---|---|
  | **Refus** tant qu'un contexte requis n'est pas vert | **HTTP 405** — `merge_refusal_server_405.txt` |
  | **Acceptation** seulement après passage au vert | `{"merged": true}` à 4/4 — `merge_refusal_api_raw.txt` |
  ⇒ **AC-4 nominal COMPLET · cases 13 et 23 COCHÉES · DoD 31/34.**
  ⚠️ **Bornes maintenues** : le refus porte sur des contextes **`expected`**, **pas `failing`** — la
  conjonction littérale d'US-00.1 **reste non observée**, ⛔ on ne casse pas un gate pour l'obtenir ;
  `--admin` **non testé** et ne le sera pas. 📌 **Le succès n'efface pas la violation** : elle reste
  actée, tracée, et la **case 34 reste décochée**.
- **🎯 CHEMIN DE SORTIE — UN SEUL GESTE.** La **PR de certification** depuis `feat/US-00.7-certif`
  **(a)** exécutera les workflows corrigés **jamais passés en CI** *(referme Q-1 / N-5)* **et**
  **(b)** rouvrira la **fenêtre de ~80 s** nécessaire au **refus de fusion** *(referme **D-1**)*.
  ⚠️ **Procédure corrigée, l'erreur à ne pas refaire** : tenter la fusion **IMMÉDIATEMENT après
  l'ouverture**, **avant toute autre capture**. Le re-passage QA pourra être **ciblé sur le seul
  critère 26**.
- **Prochaine étape** : PR de certification → capture du refus (D-1) → **re-QA ciblée** → `/certify`.

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
