# ⛔ SPÉCIFICATION — NON EXÉCUTÉE.
#
# Ce fichier décrit des exigences de GOUVERNANCE (état de l'API GitHub, gates
# CI, configuration gitleaks, registre d'ADR, mesure de couverture). ⛔ Aucun
# runner Flutter ne peut les exécuter : « la branche principale est déclarée
# protégée par l'API » n'est pas un test de widget.
#
# ⚠️ AJOUTÉ LE 2026-08-01 (US-01.1, tâche T12d) parce que le défaut n'était PAS
# que ces scénarios ne tournent pas — c'est que les DoD les COMPTAIENT comme des
# tests. Leur vérification EXISTE, sous une autre forme : sorties d'outils
# archivées dans reports/, selftests, et gates CI de l'US concernée.
#
# ✅ Les scénarios EXÉCUTÉS du projet vivent dans test/ et sont adossés à leur
# .feature par scripts/check_gherkin_mapping.py, qui tourne dans le job REQUIS
# « 📋 Governance » (voir ADR-008).

# language: fr

Fonctionnalité: Sûreté du dépôt — secrets & scan gitleaks
  En tant que mainteneur du dépôt Concentration (garant @DevOps / @CyberSecurity)
  Je veux une configuration gitleaks adaptée et un scan complet historique + working tree
  Afin qu'aucun secret ne soit committé ni exposé, et de pouvoir roter une valeur fuitée.

  # Squelette rédigé par @ProductOwner en phase business_alignment.
  # Les étapes seront outillées (steps) par @QA_Tester ; @Architect précise l'implémentation.

  # --- AC-1 : configuration adaptée au projet réel ---
  Scénario: La configuration gitleaks est présente, versionnée et adaptée à la stack
    Étant donné que le dépôt utilise la stack Flutter/Dart offline-first et la clé MCP Stitch
    Quand on inspecte la racine du dépôt
    Alors un fichier ".gitleaks.toml" existe et est suivi par Git
    Et il couvre les secrets pertinents (clé Stitch, fichiers ".env", artefacts de signature mobile)
    Et chaque règle et chaque entrée d'allowlist porte un commentaire de justification

  # --- AC-2 : scan de l'historique complet ---
  Scénario: Le scan de l'historique Git complet ne détecte aucune fuite
    Étant donné que le dépôt contient l'intégralité de son historique de commits
    Quand on exécute gitleaks sur l'historique complet à profondeur maximale
    Alors aucun secret réel n'est détecté
    Et le scan se termine avec un code de sortie de succès

  # --- AC-2 : scan du working tree / index ---
  Scénario: Le scan du working tree et de l'index ne détecte aucune fuite
    Étant donné que des fichiers sont suivis ou indexés dans le working tree courant
    Quand on exécute gitleaks sur les fichiers suivis et indexés
    Alors aucun secret réel n'est détecté
    Et le scan se termine avec un code de sortie de succès

  # --- AC-1 (erreur) / AC-2 (limite) : allowlist des faux positifs légitimes ---
  Scénario: Les placeholders et fichiers gitignorés légitimes ne sont pas comptés comme fuites
    Étant donné que ".env.example" contient le placeholder "STITCH_API_KEY=changeme"
    Et que ".mcp.json" référence la clé via "${STITCH_API_KEY}"
    Et que ".env" et ".claude/settings.local.json" sont gitignorés et non suivis
    Quand on exécute le scan complet du dépôt
    Alors aucune de ces valeurs n'est signalée comme une fuite
    Et l'exclusion des placeholders légitimes est justifiée par une allowlist commentée

  # --- AC-3 (erreur) : test négatif au pre-commit ---
  Scénario: Un faux secret injecté est bloqué par le hook pre-commit
    Étant donné qu'un fichier suivi contient un faux secret ressemblant à une vraie clé d'API
    Quand un contributeur tente de committer ce fichier
    Alors le hook pre-commit gitleaks détecte le secret
    Et le commit est refusé avec un message d'erreur explicite

  # --- AC-3 (erreur) : test négatif en CI ---
  Scénario: Un faux secret poussé sur une PR fait échouer la CI
    Étant donné qu'une branche contient un commit avec un faux secret
    Quand une Pull Request déclenche le job CI "secrets-scan"
    Alors le job "secrets-scan" échoue
    Et la fusion vers la branche principale est empêchée par la protection de branche

  # --- AC-4 (nominal) : procédure de rotation ---
  Scénario: La procédure de rotation d'un secret fuité est documentée et accessible
    Étant donné que la documentation du dépôt est disponible
    Quand on consulte la procédure de gestion des secrets
    Alors elle décrit comment identifier, révoquer et régénérer un secret fuité
    Et elle traite le cas concret de la clé Stitch "STITCH_API_KEY"
    Et elle mentionne la réécriture d'historique comme dernier recours à décision humaine

  # --- AC-4 (erreur/limite) : aucun secret de démo fuité ---
  Scénario: Aucune valeur de démo fuitée implique aucune rotation requise
    Étant donné que seul le placeholder "changeme" est committé dans ".env.example"
    Et qu'aucune valeur réelle n'a été détectée dans l'historique ni le working tree
    Quand on applique la procédure de gestion des secrets
    Alors elle conclut qu'aucune rotation n'est requise à ce jour
    Et elle reste disponible pour un incident futur
