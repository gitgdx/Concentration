# language: fr
# US-00.4 — Enforcement de la branche principale : constat, vérification honnête et cible armée
# (valeur plateforme, EPIC_00) — v2, re-cadrée le 2026-07-26.
#
# FAIT NOUVEAU (vérifié) : la protection de branche est INDISPONIBLE sur ce dépôt. Avec un jeton
# authentifié disposant de droits admin, GET .../branches/main/protection ET GET .../rulesets
# renvoient tous deux 403 « Upgrade to GitHub Pro or make this repository public to enable this
# feature. » — le dépôt est privé et le plan du compte n'inclut pas cette fonctionnalité.
#
# CONSÉQUENCE POUR CES SCÉNARIOS : aucun ne suppose, n'exige ni ne démontre une protection
# réellement appliquée. Les scénarios de la v1 portant sur l'application, les status checks
# BLOQUANTS et le test négatif serveur ont été retirés (cf. §Re-cadrage du Story File) : sans
# protection, un push direct sur la branche principale RÉUSSIRAIT — le test négatif est donc
# REPORTÉ au déblocage, jamais exécuté ici.
#
# Les preuves attendues restent des réponses BRUTES et DATÉES de l'API, jamais des artefacts
# documentaires. « --no-verify » reste interdit (Constitution Art. 1).

Fonctionnalité: Constat du trou d'enforcement de la branche principale, vérification honnête de l'état réel et cible de protection armée
  En tant que mainteneur du dépôt garant de l'intégrité de la branche principale
  Je veux savoir exactement ce qui protège et ce qui ne protège pas la branche principale
  Afin de ne plus jamais confondre une règle déclarée avec une règle réellement enforcée

  Scénario: Le constat daté est étayé par les réponses brutes de l'API (Nominal — AC-1)
    Étant donné que la gouvernance déclare la règle « jamais de push direct sur la branche principale » comme enforcée par la protection de branche
    Quand j'interroge l'état réel du dépôt à la date du constat
    Alors la branche principale est déclarée non protégée
    Et les quatre status checks déclarés s'exécutent sur chaque pull request sans qu'aucun ne soit requis
    Et la lecture de la protection de branche est refusée par la plateforme pour une raison de plan
    Et les réponses brutes et datées sont archivées comme preuves
    Et la contradiction avec le texte de gouvernance est consignée explicitement

  Scénario: La cause racine est une impossibilité de plateforme, non un défaut de droits (Limite — AC-1)
    Étant donné un jeton authentifié disposant de droits d'administration sur le dépôt
    Et un dépôt privé
    Quand j'interroge successivement la protection de branche puis les règles de dépôt
    Alors les deux mécanismes sont refusés à l'identique pour une raison de plan
    Et le refus n'est ni une absence d'authentification ni une absence de droits
    Et le constat porte sa date ainsi que la commande permettant de le re-vérifier

  Scénario: Aucune preuve documentaire ne se substitue à une réponse brute de l'API (Erreur — AC-1)
    Étant donné un document de gouvernance décrivant la protection attendue
    Et une vérification de synchronisation de la factory qui est verte
    Quand ces artefacts sont proposés comme preuves de l'état de la protection
    Alors ils sont refusés comme preuves
    Et seule une réponse brute et datée de l'API est acceptée
    Et tout énoncé laissant entendre que la branche principale est protégée est un défaut bloquant

  Scénario: La vérification de synchronisation annonce explicitement un contrôle documentaire (Nominal — AC-2)
    Étant donné que la vérification de synchronisation ne réalise aucun appel réseau
    Quand je l'exécute
    Alors elle annonce explicitement une vérification documentaire
    Et elle énumère ce qu'elle compare réellement
    Et elle avertit que l'état réel de la protection sur la plateforme n'est pas vérifié
    Et elle renvoie vers la commande dédiée qui interroge cet état réel
    Et elle reste verte et reste un gate bloquant de l'intégration continue

  Scénario: Un contrôle de synchronisation vert n'atteste jamais l'état réel de la plateforme (Erreur — AC-2)
    Étant donné une branche principale non protégée
    Quand la vérification de synchronisation est verte
    Alors sa sortie n'emploie jamais le mot « protection » comme un fait vérifié
    Et aucune de ses formulations ne peut être lue comme « la protection de branche est en place »
    Et le fait qu'un contrôle vert ait coexisté avec une branche ouverte est consigné comme la cause de la survie du défaut

  Scénario: Le contrôle de l'état réel n'entre pas dans l'intégration continue (Limite — AC-2)
    Étant donné que la lecture de la protection exige des droits d'administration
    Et que le jeton de l'intégration continue ne dispose pas de ces droits
    Quand je recherche la commande distante dans les workflows d'intégration continue
    Alors elle n'y figure nulle part
    Et la raison de cette exclusion est documentée
    Et la commande distante est déclarée manuelle et hors intégration continue

  Scénario: Seule une protection strictement conforme peut être annoncée comme un succès (Nominal — AC-3)
    Étant donné une réponse d'état strictement conforme à la cible générée depuis la configuration
    Quand j'exécute la commande de vérification de l'état réel
    Alors elle compare la protection champ par champ avec la cible générée
    Et elle rend un succès uniquement dans ce cas
    Et le mot « conforme » n'est employé sur aucun autre chemin
    Et la commande n'écrit jamais rien sur le dépôt

  Scénario: Une protection absente ou divergente est signalée champ par champ (Erreur — AC-3)
    Étant donné une réponse d'état simulée divergente de la cible
    Quand j'exécute la commande de vérification de l'état réel
    Alors elle signale une dérive
    Et elle liste une ligne par champ divergent avec la valeur attendue et la valeur réelle
    Et elle liste séparément les status checks manquants et ceux en trop
    Et le dépôt réel n'est à aucun moment modifié

  Scénario: Une vérification impossible est un constat signalé, jamais un succès (Limite — AC-3)
    Étant donné que la lecture de la protection est refusée par la plateforme pour une raison de plan
    Quand j'exécute la commande de vérification de l'état réel sur ce dépôt
    Alors elle rend une issue distincte de la conformité et de la dérive
    Et elle annonce explicitement que la vérification est impossible et que ce n'est pas un succès
    Et cette issue couvre aussi l'absence d'outil, l'absence de jeton, l'absence d'authentification et l'erreur réseau
    Et l'ambiguïté entre branche non protégée et droits insuffisants est levée par une seconde lecture non privilégiée
    Et la sortie obtenue sur ce dépôt est archivée telle quelle comme preuve

  Scénario: La cible de protection est applicable en une seule commande le jour du déblocage (Nominal — AC-4)
    Étant donné un dépôt comptant un seul collaborateur, administrateur
    Quand la cible de protection est déclarée dans la configuration de la factory, source unique
    Alors elle porte zéro approbation requise et l'application aux administrateurs
    Et le payload généré depuis la configuration est immédiatement consommable par le script d'application
    Et le jour du déblocage l'application ne demande qu'une seule commande, sans nouvelle décision

  Scénario: Présenter la cible comme active est un défaut bloquant (Erreur — AC-4)
    Étant donné que la cible de protection est déclarée mais non appliquée
    Quand un document, un rapport ou un tableau de suivi la présente comme active, appliquée ou en vigueur
    Alors c'est un défaut bloquant
    Et le script d'application est présenté comme prêt et conditionné au déblocage, jamais comme à exécuter
    Et aucune preuve d'application n'est produite ni exigée par cette US

  Scénario: L'exigence de pull request est conservée alors qu'aucune approbation n'est requise (Limite — AC-4)
    Étant donné une cible exigeant zéro approbation
    Quand le payload de protection est généré depuis la configuration
    Alors l'objet d'exigence de revue de pull request reste présent avec zéro approbation
    Et zéro approbation ne signifie pas qu'aucune pull request n'est exigée
    Et la cible est déclarée valide logiquement mais jamais validée fonctionnellement par la plateforme
    Et le réglage à zéro approbation est déclaré daté et conditionnel au dépôt à un seul collaborateur

  Scénario: Les deux conditions de déblocage sont documentées avec leurs conséquences (Nominal — AC-5)
    Étant donné que la protection est indisponible pour une raison de plan
    Quand les conditions de déblocage sont documentées
    Alors elles énoncent le passage du dépôt en public et l'abonnement payant, et elles seules
    Et le passage en public est assorti de l'exposition publique de l'historique complet et de son irréversibilité
    Et l'abonnement payant est assorti de son coût par utilisateur et du maintien du dépôt en privé
    Et ce qui serait débloqué dans les deux cas est énoncé, y compris le test négatif serveur reporté
    Et engager l'une de ces voies est déclaré hors périmètre et soumis à une décision humaine tracée

  Scénario: Ajouter un collaborateur ne débloque pas la protection de branche (Limite — AC-5)
    Étant donné un dépôt privé sur un plan n'incluant pas la protection de branche
    Quand un second collaborateur obtient l'accès en écriture
    Alors la protection de branche reste indisponible
    Et la limitation est attribuée au plan et à la visibilité du dépôt, non au nombre de contributeurs
    Et les conditions de déblocage portent leur date et dépendent de la politique commerciale de la plateforme

  Scénario: Le point de contrôle périodique réévalue le déblocage et le retour à une approbation (Nominal — AC-6)
    Étant donné un audit méthodologique périodique de la factory
    Quand il déroule son axe Gouvernance
    Alors il exécute la commande de vérification de l'état réel et consigne son code de sortie
    Et il réévalue la condition de déblocage à partir de la visibilité du dépôt et du plan du compte
    Et il réévalue la condition de retour à une approbation requise en listant les comptes en écriture
    Et si au moins deux comptes disposent de l'écriture, une US de remise à une approbation est ouverte

  Scénario: Une vérification impossible au point de contrôle maintient la dette ouverte (Erreur — AC-6)
    Étant donné un point de contrôle périodique qui exécute la vérification de l'état réel
    Quand celle-ci rend une vérification impossible
    Alors la dette d'enforcement reste ouverte
    Et le constat est signalé, jamais consigné comme un succès ni utilisé pour clore la dette
    Et une conformité constatée obligerait à exécuter le test négatif serveur reporté
    Et une dérive constatée obligerait à ré-appliquer la protection depuis la configuration

  Scénario: L'enforcement réellement en place est qualifié de filet de discipline (Nominal — AC-7)
    Étant donné que la branche principale n'est pas protégée par la plateforme
    Quand ce qui tient lieu d'enforcement est documenté
    Alors le refus du push sur la branche principale par le hook local est énoncé
    Et l'intégration continue est décrite comme rapportant quatre status checks sans pouvoir bloquer une fusion
    Et la discipline de process des pull requests systématiques est énoncée
    Et l'ensemble est qualifié de filet de discipline et non de contrainte de plateforme

  Scénario: Présenter le hook local ou l'intégration continue comme une contrainte de plateforme est un défaut (Erreur — AC-7)
    Étant donné un hook local refusant le push sur la branche principale
    Quand il est présenté comme un enforcement de plateforme
    Alors c'est un défaut bloquant
    Et son absence dans un clone frais est énoncée
    Et son contournement possible depuis un autre poste ou par l'interface web est énoncé
    Et le fait qu'aucun status check ne soit requis, donc qu'une fusion reste possible avec une intégration continue rouge, est énoncé
    Et le contournement des hooks reste interdit par la Constitution

  Scénario: Le test négatif serveur est reporté au déblocage, et non exécuté (Limite — AC-7)
    Étant donné qu'aucune protection n'est active sur la branche principale
    Quand un test négatif de push direct est envisagé
    Alors il est reporté au déblocage et n'est pas exécuté
    Et la raison est qu'un push direct réussirait et modifierait la branche principale hors pull request pour rien
    Et aucune preuve de refus par le serveur n'est produite ni exigée
    Et toute vérification conservée est non destructive et se limite à la lecture de l'état
    Et l'absence de démonstration de l'effet est assumée explicitement

  Scénario: Le constat ne réécrit pas l'historique et ne remet pas en cause les certifications antérieures (Limite — AC-8)
    Étant donné que la branche principale n'a jamais été protégée jusqu'à la date du constat
    Et que les pull requests déjà fusionnées l'ont été sans protection active
    Quand cette US constate, outille et documente le trou d'enforcement
    Alors l'historique du dépôt n'est pas réécrit
    Et les certifications des US antérieures restent valides, appuyées sur leurs audits et leurs preuves
    Et les deux commits de bootstrap, antérieurs à toute règle, ne donnent lieu à aucun événement de violation rétroactif
    Et la mise en cohérence du texte de gouvernance qui déclare la règle enforcée est transmise comme obligatoire à une US dédiée
