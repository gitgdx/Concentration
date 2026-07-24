# 🧱 Stack Profile — Flutter (adapter `flutter`)

> Normes imposées par cet adapter, référencées par les subagents (`docs/governance/STACK_PROFILE.md
> §<Rôle>`). Changer de stack = changer d'adapter, pas les subagents.

## Vue d'ensemble

- **Application** : Flutter (channel stable, SDK `^3.12.2`), Dart null-safety strict. Un seul
  composant (`app`, à la racine du repo) — pas de séparation backend/frontend : l'application est
  **offline-first**, aucune donnée ne quitte l'appareil (cf. PRD § RNF-07).
- **Plateformes matérialisées** : Android et Web. **iOS n'est pas encore scaffoldé** (voir
  « Limitations connues » ci-dessous) alors que le PRD cible bien iOS + Android — à ajouter dès
  qu'un poste macOS (ou un runner CI macOS) est disponible pour le générer et le valider.
- **Qualité** : `dart format` (mise en forme), `flutter analyze` (lint + typage statique — Dart
  n'a pas d'étape « typecheck » séparée, l'analyse couvre les deux), `flutter test --coverage`
  (tests + couverture de lignes via lcov), `flutter build web` (preuve de constructibilité).
- Toutes les commandes sont définies dans `factory.config.json` → `adapter.components.app.gates` et
  s'exécutent via `python scripts/run_gates.py` — ne jamais coder une commande stack en dur ailleurs.

## §Developer

- Un nouvel écran/widget à logique conditionnelle = un test dédié dans `test/` (miroir de `lib/`
  au fil de la croissance du projet — pour l'instant `test/widget_test.dart` teste
  `lib/main.dart`). Utiliser `flutter_test` (`testWidgets`, `WidgetTester`) — pas de mock du
  framework Flutter lui-même.
- Composants organisés par feature à mesure que le hub de pratiques grandit (voir PRD § Vision
  produit à moyen terme) : prévoir une arborescence `lib/features/<module>/` (ex.
  `lib/features/echeances/`) plutôt qu'un `lib/main.dart` monolithique dès la première US de
  contenu réel — l'architecture modulaire est une exigence produit explicite (RF-21).
- `analysis_options.yaml` inclut `package:flutter_lints/flutter.yaml` — ne pas désactiver de règle
  sans justification en commentaire.
- Aucune donnée sensible : pas de `.env`, pas de clé API au MVP (RNF-07). Si une US future
  introduit un module en ligne, documenter le changement de posture ici et en ADR.

## §DataEngineer

- **Pas de backend, pas de schéma de base de données distante.** Le PRD exige un stockage local
  (RF-15, RNF-01 offline-first) pour les échéances (description, date, heure optionnelle).
- Le choix du mécanisme de persistance locale (ex. `sqflite`, `drift`, `isar`, `hive`,
  `shared_preferences` selon la structure des données) est **délibérément non figé par ce
  bootstrap** : c'est une décision d'architecture à prendre en ADR lors de l'US de persistance
  (Epic E2 du PRD, « Gestion des événements »), pas au moment de l'initialisation.
- Modèle de données à concevoir dès cette US : entité Échéance (description, date/heure
  d'échéance, état actif/échu), pensée pour l'extensibilité vers les futurs modules (Respiration,
  Concentration) sans migration destructive (RF-21).

## §Sécurité (@CyberSecurity)

- Pas d'authentification, pas de réseau au MVP (RNF-07) : la surface d'attaque est réduite au
  stockage local de l'appareil. Vérifier qu'aucune donnée d'échéance n'est journalisée en clair
  (logs de debug) au-delà du strict nécessaire au développement.
- **Limitation connue — audit de dépendances** : contrairement à `pip-audit`/`npm audit` utilisés
  par d'autres adapters de ce kit, le SDK Dart de ce projet n'a pas d'équivalent officiel de scan
  de CVE (`dart pub audit` n'existe pas dans cette version du SDK). Le gate `deps_audit` exécute
  `dart pub outdated --show-all` à titre indicatif (obsolescence, pas vulnérabilités) et est
  **non bloquant** (`"blocking": false` dans `factory.config.json`) — ne pas le confondre avec un
  vrai contrôle de sécurité. Dès qu'un scanner fiable est disponible (ex. `osv-scanner`, via
  l'action GitHub `google/osv-scanner-action`), l'ajouter en CI et documenter le changement ici.
- Gates outillés : `flutter analyze` (détecte une partie des anti-patterns), `dart format`
  (cohérence, pas de sécurité). Aucun gate SAST dédié (pas d'équivalent bandit mûr pour Dart à ce
  jour) — à surveiller lors des audits `/audit-us` (revue manuelle du @CyberSecurity).

## §DevOps

- CI : `.github/workflows/ci.yml` (gates qualité via `run_gates.py`), `e2e.yml` (smoke build
  nightly — voir `docs/qa/E2E_RUNBOOK.md`, à enrichir avec `integration_test` dès que l'écran
  principal existe).
- **Pas de health-check HTTP** (pas de serveur) : la preuve de bon fonctionnement du bootstrap est
  `flutter build web --release` (l'application se compile et se bundle). Ce n'est PAS une
  plateforme cible produit (RNF-08 vise iOS/Android) — c'est un gate de constructibilité choisi
  pour tourner sur `ubuntu-latest` sans toolchain mobile.
- **Prérequis avant un vrai build Android/iOS** (non satisfaits par ce bootstrap) :
  - Android : JDK 17+ (`JAVA_HOME`), licences du SDK Android acceptées
    (`flutter doctor --android-licenses`). Sur cette machine de développement au moment du
    bootstrap, le SDK Android est présent mais **aucun JDK n'est installé** — `flutter build apk`
    échouera tant que ce n'est pas corrigé.
  - iOS : un poste macOS avec Xcode (impossible à valider depuis Windows/Linux) — voir
    « Limitations connues ».
  - Signature (keystore Android / certificats iOS) à mettre en place avant toute publication sur
    les stores — jamais committée (voir `.gitignore` / `android/app/.gitignore`).
- Séquence de déploiement mobile (différente du web classique) : build signé → distribution interne
  (Play Console *internal testing* / TestFlight) → validation → publication store. Adapter la
  séquence « staging → validation → production » attendue par `@DevOps_Engineer` à ces étapes.

## Limitations connues du bootstrap (à lever dans des US dédiées, pas silencieusement)

1. **iOS non scaffoldé.** `flutter create --platforms=ios` génère des fichiers Xcode qui, sur ce
   poste Windows, déclenchent une erreur de génération de paquet Swift Package Manager éphémère
   (`PathNotFoundException` sur `ios/Flutter/ephemeral/Packages/...`) dès `flutter analyze` ou
   `flutter test` — un bug d'environnement, pas un problème de code. Comme ni ce poste ni les
   runners CI `ubuntu-latest` ne peuvent de toute façon builder iOS, la plateforme a été omise du
   squelette plutôt que de livrer des fichiers non vérifiables. À ajouter (`flutter create
   --platforms=ios .`) depuis un poste macOS, ou une fois un runner CI macOS disponible.
2. **`deps_audit` non bloquant** (voir §Sécurité) : pas d'équivalent mûr à pip-audit/npm audit
   pour Dart au moment de ce bootstrap.
3. **Build Android réel non validé** : `flutter build apk` n'a pas pu être exécuté pendant
   l'initialisation (JDK absent sur la machine de bootstrap) — le gate `build` utilise
   `flutter build web` comme preuve de constructibilité de repli. À valider dès qu'un JDK 17+ est
   installé (`flutter doctor` doit passer au vert sur la ligne Android toolchain).

## Runtimes

- Flutter **3.44.7** (channel stable), Dart **`^3.12.2`**. `flutter_lints` `^6.0.0`.
- Org d'application : `com.concentration` (placeholder — à revoir avant toute soumission sur les
  stores, avec le nommage définitif du produit).
