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
