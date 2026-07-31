# language: fr
# US-00.5 — ADR-001 (choix de stack) + exactitude de l'Art. 4 de la Constitution
# (valeur plateforme, EPIC_00 — aucune valeur utilisateur final).
#
# ⚠️ PORTÉE EXACTE DE CE FICHIER — À LIRE AVANT DE L'INVOQUER COMME PREUVE.
# Ces scénarios sont DOCUMENTAIRES : ils ne s'exécutent pas. Le projet n'a NI step definitions
# NI runner BDD (vérifié le 2026-07-30 : aucune dépendance de type gherkin/cucumber dans le
# dépôt), et RIEN en intégration continue ne lit `tests/features/**`. Ce fichier est la grille
# de lecture du @QA_Tester et la formulation falsifiable des critères d'acceptation.
# Le NOMBRE de scénarios ne mesure AUCUNE couverture.
#
# PÉRIMÈTRE — arbitré par l'humain le 2026-07-30 : « SOCLE SEUL », deux livrables.
#   (1) ADR-001, les choix de stack, jamais rédigés — un numéro RÉSERVÉ depuis le 2026-07-26
#       par deux ADR acceptés, et pourtant VIDE.
#   (2) Le bloc « Enforcement » de l'Art. 4, qui ne nomme qu'UN workflow alors que DEUX portent
#       des contextes requis.
#
# ⛔ PIÈGE CENTRAL — ce qui est devenu VRAI le 2026-07-28 et ne doit PAS être « corrigé » :
#   la règle interdisant le push direct sur la branche principale EST enforcée (la protection est
#   appliquée, le serveur a refusé), et la mention « requis par la protection de branche » EST
#   exacte (les 4 contextes SONT requis). Les toucher rendrait FAUX un énoncé EXACT — le même
#   défaut, en sens inverse, que deux US ont mis trois jours à éliminer.
#   Le seul défaut résiduel est une INCOMPLÉTUDE, jamais une fausseté.
#
# CONVENTION — un énoncé visé est désigné par son TEXTE, jamais par un numéro de ligne :
# un numéro glisse en silence et la couverture cesse de couvrir sans qu'aucun outil ne le signale.

Fonctionnalité: Traçabilité de la décision de stack au registre des décisions et exactitude du texte normatif sur les contextes requis
  En tant que mainteneur de la factory, et tout auditeur à contexte frais qui doit savoir sur quelle stack il travaille et pourquoi sa pull request est bloquée
  Je veux que le choix de stack soit tracé comme une décision datée, avec ses alternatives et ses limitations réelles, et que le texte normatif nomme tous les workflows dont un contexte est requis
  Afin que la décision fondatrice du projet cesse d'être la seule à n'exister que dans un document d'adapter remplaçable, et qu'aucun lecteur du texte normatif ne découvre la barrière qui l'arrête après une fusion devenue impossible

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-1 — La décision de stack entre au registre des décisions  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La décision de stack entre au registre des décisions (Nominal — AC-1)
    Étant donné que le registre des décisions ne contient aucune décision de stack
    Et que le numéro réservé à cette décision est cité par deux décisions déjà acceptées
    Quand la décision de stack est rédigée selon le modèle imposé du registre
    Alors elle porte une date, un statut accepté et l'identifiant de cette story
    Et elle énonce le cadre applicatif retenu, l'unicité du composant et l'absence de séparation entre service et interface
    Et elle énonce le fonctionnement hors ligne et le fait qu'aucune donnée ne quitte l'appareil
    Et elle énonce les contrôles de qualité outillés et le seuil de couverture exigé
    Et elle énonce que toutes les commandes sont définies en un seul endroit et exécutées par un lanceur unique
    Et elle nomme les options écartées avec la raison de leur rejet
    Et chaque affirmation renvoie au document du dépôt qui l'établit

  Scénario: Une affirmation non vérifiable est retirée, et aucune décision acceptée n'est éditée (Erreur — AC-1)
    Étant donné une affirmation sur la stack qu'aucun fichier du dépôt ne permet d'établir
    Quand la décision de stack est rédigée
    Alors cette affirmation est retirée ou explicitement marquée comme non vérifiée
    Et elle n'est jamais présentée comme un fait
    Et l'édition d'une décision déjà acceptée est refusée
    Et il est refusé de décrire la stack souhaitée à la place de la stack en place

  Scénario: Un numéro attribué rétroactivement ne rend le registre ni complet ni chronologique (Limite — AC-1)
    Étant donné une décision prise au démarrage du projet et tracée seulement aujourd'hui
    Quand j'évalue ce que son entrée au registre établit
    Alors la décision écrit elle-même qu'elle est tracée après coup et ne prétend pas avoir précédé son application
    Et il est écrit que le registre n'est pas classé par ordre chronologique
    Et il est écrit que trois numéros restent réservés par une autre story et non écrits
    Et aucune complétude du registre n'est revendiquée
    Et les numéros de version cités sont datés, la source unique restant la configuration de la factory

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-2 — La stack est documentée telle qu'elle est, limitations comprises  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Les limitations de la stack sont nommées avec leur conséquence (Nominal — AC-2)
    Étant donné une stack dont la cible produit vise deux plateformes mobiles
    Quand les conséquences de la décision sont rédigées
    Alors il est écrit que l'une des deux plateformes mobiles n'est pas encore générée, donc que la cible produit n'est pas couverte
    Et il est écrit que la construction mobile réelle n'a jamais été validée et que la preuve de constructibilité est un repli qui n'est pas une plateforme cible
    Et il est écrit que le contrôle des dépendances mesure l'obsolescence et non la vulnérabilité, et qu'il n'est pas bloquant
    Et il est écrit qu'aucune analyse statique de sécurité n'existe dans la factory et que la seule barrière est une revue manuelle
    Et chaque limitation porte sa conséquence pratique et le renvoi vers le document qui la constate déjà

  Scénario: Une décision qui présente la stack comme complète est refusée (Erreur — AC-2)
    Étant donné une rédaction qui passerait une limitation sous silence
    Quand elle est soumise
    Alors présenter la stack comme complète est refusé
    Et qualifier le contrôle des dépendances de contrôle de sécurité est refusé
    Et taire l'absence d'analyse statique de sécurité est refusé
    Et taire l'absence de la plateforme mobile manquante est refusé
    Et ce défaut est bloquant et non cosmétique
    Et faire disparaître une limitation en la retirant du document d'adapter est refusé

  Scénario: Nommer une limitation ne la lève pas (Limite — AC-2)
    Étant donné quatre limitations nommées dans les conséquences de la décision
    Quand j'évalue ce que cette énumération apporte
    Alors elle vaut pour les limitations connues et vérifiables à sa date
    Et aucune exhaustivité des limitations n'est revendiquée
    Et aucune de ces limitations n'est levée par cette story
    Et aucune date d'échéance n'est promise
    Et il est écrit que lever une limitation exigera une nouvelle décision, une décision acceptée étant immuable

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-3 — Le texte normatif nomme les deux workflows porteurs de contextes requis  (Should)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: L'article normatif devient exact — les trois faussetés de son corps sont levées (Nominal — AC-3)
    Étant donné un article du texte normatif qui énumère parmi ses gates bloquants une analyse statique de sécurité
    Et qu'aucun gate d'analyse statique de sécurité n'existe dans la factory
    Et que l'audit de dépendances y est annoncé bloquant alors qu'il est déclaré non bloquant dans la configuration
    Et qu'un seuil de cliquet de couverture y est cité alors que la clé est absente de la configuration
    Et qu'un gate de construction réellement bloquant n'y est pas mentionné
    Quand l'article est amendé
    Alors l'analyse statique de sécurité ne figure plus parmi les gates bloquants
    Et son absence est nommée comme une dette ouverte, avec son destinataire
    Et il est écrit que l'audit de dépendances mesure l'obsolescence et non la vulnérabilité, et qu'aucun scan de vulnérabilités n'existe
    Et le seuil de cliquet est désigné comme restant à activer par une story ultérieure
    Et le gate de construction est nommé
    Et aucune valeur numérique n'est recopiée dans le texte normatif, qui désigne la configuration comme source unique

  Scénario: Le texte normatif nomme les deux workflows porteurs de contextes requis (Nominal — AC-3)
    Étant donné un article du texte normatif dont le bloc d'application ne nomme qu'un seul workflow
    Et que quatre contextes sont requis pour fusionner, dont un porté par un second workflow
    Quand l'article est amendé
    Alors le second workflow et le contexte qu'il porte sont nommés
    Et le lecteur apprend combien de contextes sont requis et lequel vient de quel workflow
    Et un renvoi le conduit au document qui décrit la conséquence pratique d'un nom de branche non conforme
    Et il est écrit que la pull request devient définitivement infusionnable dans ce cas
    Et la liste des contextes n'est pas recopiée dans le texte normatif, qui désigne la configuration comme source unique

  Scénario: Chaque gate nommé par l'article existe, et chaque gate dit bloquant l'est vraiment (Nominal — AC-3)
    Étant donné un article normatif amendé qui nomme une liste de gates
    Quand j'exécute le lanceur de gates pour chacun des noms cités
    Alors chacun existe
    Et pour chaque gate que l'article déclare bloquant, la configuration ne porte pas la valeur « non bloquant »
    Et la sortie brute de ce contrôle est archivée avec les preuves de la story
    Et le contrôle est publié comme une commande rejouable, non comme une affirmation de relecture

  Scénario: Un énoncé devenu vrai n'est pas « corrigé » (Erreur — AC-3)
    Étant donné des énoncés du corpus devenus factuellement vrais depuis l'application de la protection
    Quand un intervenant se propose de les corriger au titre d'un périmètre plus ancien
    Alors la correction du document de démarrage est refusée
    Et la réécriture de la mention selon laquelle les contextes sont requis par la protection est refusée
    Et la correction de l'en-tête généré du document de protection est refusée
    Et il est écrit que corriger un énoncé exact vaut régression documentaire
    Et il est écrit que la règle de synthèse énumérant trois interdits pour trois mécanismes reste exacte, la protection n'adossant que le deuxième
    Et aucun autre article que celui visé n'est modifié

  Scénario: Un texte complet ne crée aucun enforcement (Limite — AC-3)
    Étant donné un article devenu complet sur les contextes requis
    Quand j'évalue ce que cette complétude garantit
    Alors elle ne crée aucun mécanisme d'application
    Et son exactitude est datée et dépend de la configuration et de l'état réel du dépôt
    Et il est écrit qu'aucune détection automatique de dérive n'existe, la vérification exigeant des droits d'administration hors intégration continue
    Et il est écrit qu'un administrateur pourrait retirer un contexte requis sans qu'aucun mécanisme ne le signale
    Et il est écrit qu'un retour du dépôt en visibilité privée rendrait de nouveau faux les énoncés devenus vrais

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-4 — L'amendement respecte la clause de révision du texte normatif  (Should)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: L'amendement est daté, versionné et déclaré (Nominal — AC-4)
    Étant donné un texte normatif qui impose sa propre procédure de révision
    Quand l'article est amendé
    Alors la version du texte normatif est incrémentée et datée
    Et une ligne dédiée est ajoutée au journal du projet
    Et l'amendement renvoie à la story qui le porte
    Et la modification ne porte que sur l'article visé et sur l'en-tête de version

  Scénario: La clause « pull request dédiée » est tenue à la lettre, en deux livraisons (Nominal — AC-4)
    Étant donné une clause de révision qui exige une pull request dédiée et jamais un effet de bord
    Et une story qui livre à la fois un enregistrement de décision et un amendement du texte normatif
    Quand la story est livrée
    Alors une première pull request porte l'enregistrement de décision seul
    Et le différentiel de cette première pull request ne contient pas le texte normatif
    Et la branche de la seconde livraison est rebasée après la fusion de la première, la mise à jour obligatoire sérialisant les fusions
    Et une seconde pull request, dédiée, ne porte que le texte normatif et le journal du projet
    Et il est écrit que lire « dédiée » comme « objet déclaré » aurait été un écart à la lettre de la clause
    Et il est écrit que la fusion de la seconde pull request appartient à l'humain

  Scénario: Un amendement sans version ni trace, ou débordant l'article, est refusé (Erreur — AC-4)
    Étant donné un amendement proposé au texte normatif
    Quand il ne porte pas d'incrément de version ou pas de ligne au journal du projet
    Alors il est refusé
    Et tout autre article modifié dans la même livraison est refusé comme hors périmètre
    Et un agent ne se substitue pas à l'approbation humaine
    Et un agent ne présume pas cette approbation, aucun message d'agent ne valant approbation

  Scénario: L'approbation humaine n'a aucune barrière machine sur ce dépôt (Limite — AC-4)
    Étant donné une clause de révision qui exige une approbation humaine
    Et un dépôt à un seul compte où le nombre d'approbations requises est nul
    Et que la plateforme interdit à l'auteur d'approuver sa propre pull request
    Quand j'évalue ce que cette approbation peut prouver
    Alors elle demeure une obligation de process, attestée de façon déclarative et datée
    Et il est écrit qu'elle n'est jamais prouvée par la plateforme
    Et il est écrit qu'aucune preuve machine de provenance n'existe, les agents opérant avec le jeton de l'humain
    Et l'exigence d'une pull request dédiée reste un point à trancher, cette story portant deux livrables

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-5 — Aucune contradiction nouvelle ; les écarts hors périmètre sont nommés  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Les écarts non traités sont nommés avec leur destinataire (Nominal — AC-5)
    Étant donné une story qui livre à la fois une décision de stack et un amendement du texte normatif
    Quand les deux livrables sont confrontés
    Alors ils ne se contredisent pas
    Et tout écart constaté et non traité est nommé avec son destinataire
    Et l'écart déjà identifié est consigné : le texte normatif énumère parmi les contrôles bloquants une analyse statique de sécurité qui n'existe pas et un contrôle de dépendances qui n'est pas bloquant
    Et il est consigné que le mécanisme de cliquet de couverture cité par l'article est absent de la configuration

  Scénario: Taire un écart est bloquant, le corriger sans arbitrage est un débordement (Erreur — AC-5)
    Étant donné un écart constaté entre le texte normatif et la stack réelle
    Quand une livraison prétend le traiter sans arbitrage préalable
    Alors le passer sous silence est un défaut bloquant, le texte normatif restant en contradiction avec la décision livrée par la même story
    Et le corriger dans la même livraison est refusé comme élargissement de périmètre
    Et la seule issue autorisée est de le porter à la porte de clarification pour y être tranché

  Scénario: Consigner ne résout pas, et le balayage n'est pas exhaustif (Limite — AC-5)
    Étant donné un écart consigné et transmis
    Quand j'évalue ce que la consignation apporte
    Alors elle ne résout pas l'écart
    Et aucune exhaustivité du balayage de cohérence n'est revendiquée
    Et la méthode employée et ses angles morts sont écrits
    Et le critère de sortie est une commande rejouable dont la sortie est vérifiable, jamais une relecture
    Et un texte barré étant invisible à la recherche, une mention périmée porte un marqueur littéral daté sur la ligne même

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-6 — Preuves de revue documentaire et portée exacte des scénarios  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Les preuves sont des sorties d'outils archivées, pas une relecture (Nominal — AC-6)
    Étant donné une story qui ne livre aucun fichier de code applicatif
    Quand ses preuves sont constituées
    Alors une revue de conformité critère par critère est archivée
    Et les sorties brutes et datées établissant l'état d'entrée sont archivées
    Et l'état d'entrée comprend l'absence de la décision de stack au registre, la liste des contextes requis, le workflow portant le quatrième contexte et le texte de l'article avant amendement
    Et l'état de sortie est archivé de la même façon
    Et les contrôles de qualité outillés sont exécutés au titre de la non-régression
    Et il est écrit que la couverture atteste une non-régression et jamais le livrable

  Scénario: Un verdict sans preuve outillée est invalide (Erreur — AC-6)
    Étant donné un verdict fondé sur la seule relecture d'un agent
    Quand il est proposé comme preuve
    Alors il est refusé, aucune sortie d'outil n'étant archivée
    Et un rapport qui désignerait une assertion par son numéro de ligne est refusé
    Et une décision de stack livrée sans revue de conformité archivée n'est pas présentée comme certifiable

  Scénario: Les scénarios de cette story ne s'exécutent pas (Limite — AC-6)
    Étant donné les scénarios rédigés pour cette story
    Quand j'évalue ce qu'ils garantissent
    Alors il est écrit qu'ils sont documentaires
    Et il est écrit que le projet n'a ni définition d'étapes ni moteur d'exécution de scénarios
    Et il est écrit que rien en intégration continue ne lit ces fichiers
    Et il est écrit qu'ils servent de grille de lecture à la qualification et qu'ils ne s'exécutent pas
    Et il est écrit que leur nombre ne mesure aucune couverture
