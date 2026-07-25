# language: fr
# US-00.3 — Migrations réversibles (convention de plateforme, EPIC_00)
# Note : au Sprint 0, aucun schéma concret n'existe (techno de persistance reportée à US-01.2).
# Ces scénarios valident la CONVENTION de migrations réversibles ; leur exécution automatisée
# sur une migration réelle est instanciée par US-01.2.

Fonctionnalité: Convention de migrations de schéma local réversibles
  En tant que membre de la squad garant des données locales de l'utilisateur
  Je veux une convention de migrations réversibles établie avant le premier schéma
  Afin qu'aucune évolution du modèle de données ne provoque de perte ni de blocage irréversible

  Scénario: La convention définit un versionnement monotone avec couple up/down (Nominal — AC-1)
    Étant donné que la convention de migrations est documentée
    Quand un changement de schéma est introduit
    Alors la version de schéma est un entier incrémenté de 1
    Et le changement fournit un couple de migrations « up » (montée) et « down » (descente)

  Scénario: Un aller-retour up puis down restaure l'état de schéma précédent (Nominal — AC-2)
    Étant donné un schéma en version N-1
    Quand la migration « up » vers N est appliquée puis la migration « down » vers N-1
    Alors l'état de schéma restauré est fonctionnellement équivalent à l'état initial N-1
    Et aucune donnée non concernée par la migration n'est corrompue ou perdue

  Scénario: Une migration dont le down ne restaure pas l'état antérieur est rejetée (Erreur — AC-2)
    Étant donné une migration « up » vers N assortie d'un « down »
    Quand l'aller-retour up puis down laisse des structures orphelines ou perd des données au-delà du delta migré
    Alors la migration est déclarée non conforme au contrat de réversibilité
    Et elle est rejetée en revue

  Scénario: Une migration additive est réversible et acceptée (Nominal — AC-3)
    Étant donné une évolution additive du modèle (nouveau champ ou table pour un futur module)
    Quand la migration « up » ajoute la structure et « down » la retire
    Alors la migration est réversible sans perte de donnée utilisateur
    Et elle respecte l'extensibilité attendue (RF-21)

  Scénario: Une migration destructive sans préservation est bloquée (Erreur — AC-3)
    Étant donné une migration supprimant une structure porteuse de données utilisateur
    Quand elle est proposée sans stratégie de préservation documentée ni justification validée
    Alors elle est bloquée en revue
    Et elle ne peut aboutir qu'avec préservation documentée et validation humaine explicite tracée

  Scénario: À défaut de schéma concret au Sprint 0, le patron de test est prêt pour US-01.2 (Limite — AC-4)
    Étant donné qu'aucun mécanisme de persistance n'est encore choisi au Sprint 0
    Quand la convention est livrée
    Alors elle fournit un patron de test aller-retour réutilisable « préparer(N-1) → up → vérifier(N) → down → vérifier(N-1) »
    Et ce patron est prêt à être instancié par la première migration réelle de US-01.2
