# language: fr
# US-00.4 — CI + protection de branche réelles (valeur plateforme, EPIC_00)
# Constat d'entrée (2026-07-26) : l'API GitHub renvoie "protected": false pour la branche principale.
# La règle « jamais de push direct sur la branche principale » est DÉCLARÉE enforced mais ne l'est pas.
# Ces scénarios exigent une preuve issue de l'ÉTAT RÉEL DU DÉPÔT (interrogation de l'API),
# jamais une preuve documentaire. Le test négatif ne doit jamais s'appuyer sur « --no-verify »
# (interdit par la Constitution) : il doit atteindre le serveur autrement.

Fonctionnalité: Protection réelle de la branche principale et status checks bloquants
  En tant que mainteneur du dépôt garant de l'intégrité de la branche principale
  Je veux que la branche principale soit réellement protégée sur la plateforme
  Afin qu'aucun code ne puisse atteindre la branche principale en contournant les gates qualité

  Scénario: La branche principale est réellement protégée, constaté sur l'état du dépôt (Nominal — AC-2)
    Étant donné que la protection de branche a été appliquée depuis la configuration de la factory
    Quand j'interroge l'état réel de la branche principale du dépôt
    Alors la branche principale est déclarée protégée
    Et le détail de la protection retourné est conforme à la cible arbitrée
    Et la réponse brute et datée est archivée comme preuve

  Scénario: Une vérification documentaire verte ne prouve pas la protection réelle (Erreur — AC-2)
    Étant donné que la vérification de synchronisation de la factory est verte
    Et que cette vérification n'interroge jamais l'état réel du dépôt
    Quand j'interroge l'état réel de la branche principale et qu'elle n'est pas protégée
    Alors le critère est en échec malgré la vérification verte
    Et aucune preuve documentaire n'est acceptée comme substitut

  Scénario: Les quatre status checks requis conditionnent la fusion (Nominal — AC-1)
    Étant donné que la protection de la branche principale est active
    Quand je consulte la liste des status checks requis
    Alors elle contient exactement les quatre status checks déclarés dans la configuration de la factory
    Et la branche doit être à jour avec la branche principale avant fusion
    Et aucun status check requis supplémentaire ni manquant n'est constaté

  Scénario: Un status check requis rouge empêche la fusion, administrateur inclus (Erreur — AC-1)
    Étant donné une pull request ouverte vers la branche principale protégée
    Et qu'un des status checks requis est rouge ou en attente
    Quand un administrateur du dépôt tente de fusionner la pull request
    Alors la plateforme refuse la fusion
    Et le refus s'applique aussi aux administrateurs, sans contournement possible

  Scénario: Un push direct sur la branche principale est refusé par le serveur (Erreur — AC-3)
    Étant donné que la protection de la branche principale est active
    Et un poste de travail où les hooks locaux ne sont pas installés
    Quand je tente de pousser un commit jetable directement sur la branche principale
    Alors le serveur refuse le push en invoquant la protection de branche
    Et la sortie du refus est archivée comme preuve
    Et le commit jetable n'est jamais fusionné

  Scénario: Un force-push et une suppression de la branche principale sont refusés (Erreur — AC-3)
    Étant donné que la protection de la branche principale est active
    Quand je tente un push forcé sur la branche principale
    Alors le serveur refuse le push forcé
    Quand je tente de supprimer la branche principale
    Alors le serveur refuse la suppression
    Et les sorties des deux refus sont archivées comme preuves

  Scénario: L'écart d'exigence d'approbation est déclaré en configuration et justifié par un ADR (Nominal — AC-4)
    Étant donné un dépôt comptant un seul collaborateur, administrateur
    Quand la cible de protection est arrêtée à zéro approbation requise avec application aux administrateurs
    Alors cette cible est déclarée dans la configuration de la factory, source unique
    Et un ADR justifie l'écart, ses conséquences et la condition de retour à une approbation
    Et l'ADR rappelle que la revue humaine reste une obligation de process, non enforcée par la plateforme

  Scénario: La configuration initiale verrouillerait toute fusion (Erreur — AC-4)
    Étant donné un dépôt comptant un seul collaborateur, administrateur
    Et une configuration exigeant une approbation et l'application aux administrateurs
    Quand cette configuration est appliquée telle quelle
    Alors aucune fusion n'est plus possible, l'auteur ne pouvant approuver sa propre pull request
    Et la correction passe par la configuration, jamais par la désactivation de l'application aux administrateurs

  Scénario: La protection appliquée est générée depuis la configuration, sans écart (Nominal — AC-5)
    Étant donné que la protection a été appliquée par le script qui la génère depuis la configuration de la factory
    Quand je compare champ par champ la protection émise par la configuration et celle retournée par le dépôt
    Alors aucun écart n'est constaté
    Et la comparaison est archivée comme preuve

  Scénario: Une protection modifiée à la main hors configuration est un écart bloquant (Erreur — AC-5)
    Étant donné que la protection de la branche principale est active
    Quand un réglage de protection est modifié directement dans l'interface de la plateforme
    Alors l'écart avec la configuration de la factory est un défaut bloquant
    Et la résolution consiste à ré-appliquer la protection depuis la configuration
    Et la configuration n'est jamais alignée sur l'état constaté sans décision humaine tracée

  Scénario: Les quatre status checks sont verts sur la pull request de l'US (Nominal — AC-6)
    Étant donné la pull request de cette US ouverte vers la branche principale
    Quand l'intégration continue s'exécute
    Alors les quatre status checks requis sont rapportés sous leur libellé exact attendu
    Et les quatre status checks sont verts
    Et la fusion de cette pull request démontre la protection en conditions réelles

  Scénario: Un status check requis jamais rapporté laisse la pull request bloquée (Limite — AC-6)
    Étant donné un status check requis dont le libellé diverge de celui rapporté par le workflow
    Quand une pull request est ouverte vers la branche principale
    Alors le status check requis reste indéfiniment en attente
    Et la pull request ne peut pas être fusionnée
    Et la correction consiste à réaligner workflow et configuration, jamais à retirer le status check requis

  Scénario: Le trou d'enforcement est constaté et documenté sans réécrire l'historique (Limite — AC-7)
    Étant donné que la branche principale n'était pas protégée jusqu'à la date du constat
    Et que les pull requests déjà fusionnées l'ont été sans protection active
    Quand cette US applique et prouve la protection
    Alors le constat daté est documenté explicitement
    Et l'historique du dépôt n'est pas réécrit
    Et les certifications des US antérieures restent valides, appuyées sur leurs audits et leurs preuves
