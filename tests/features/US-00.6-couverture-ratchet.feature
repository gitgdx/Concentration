# language: fr
# US-00.6 — Couverture initiale mesurée + cliquet (ratchet) réellement actif
# (valeur plateforme, EPIC_00 — aucune valeur utilisateur final).
#
# ⚠️ PORTÉE EXACTE DE CE FICHIER — À LIRE AVANT DE L'INVOQUER COMME PREUVE.
# Ces scénarios sont DOCUMENTAIRES : ils NE S'EXÉCUTENT PAS. Le projet n'a NI step definitions
# NI runner BDD (vérifié le 2026-07-31 : aucune dépendance de type gherkin/cucumber dans le
# dépôt), et RIEN en intégration continue ne lit `tests/features/**`. Ce fichier est la grille
# de lecture du @QA_Tester et la formulation falsifiable des critères d'acceptation.
# Le NOMBRE de scénarios ne mesure AUCUNE couverture.
#
# ⛔ NE PAS CONFONDRE avec les FIXTURES d'AC-3 (`tests/fixtures/US-00.6/`), qui elles
#    S'EXÉCUTENT RÉELLEMENT et portent la preuve que le cliquet sait ROUGIR.
#
# PÉRIMÈTRE — arbitré par l'humain le 2026-07-31, deux livrables et un interdit :
#   (1) la VALEUR de référence va dans la source unique de configuration (fichier PROTÉGÉ :
#       UNE SEULE ÉDITION, HUMAINE) ;
#   (2) la LOGIQUE va dans le contrôle de couverture (fichier LIBRE) ;
#   (3) ⛔ le script de synchronisation de configuration N'EST PAS TOUCHÉ.
#
# ⛔ PIÈGE CENTRAL — le succès de cette story rend FAUX deux énoncés du corpus :
#   le texte normatif écrit que le cliquet « n'est PAS en vigueur » et que « son activation exige
#   du code dans le script de synchronisation » ; le registre des décisions, IMMUABLE, écrit la
#   même chose. Les deux étaient EXACTS à leur date : ils décrivaient le seul chemin de lecture
#   existant. Les TAIRE est un défaut bloquant — cette story en serait la PRODUCTRICE. On DATE,
#   on ne REPEINT pas ; un texte immuable se rectifie par un NOUVEAU texte, jamais par édition.
#
# ÉTAT D'ENTRÉE CHIFFRÉ (recalculé depuis le rapport de couverture, 2026-07-31) :
#   17 lignes couvertes sur 19 = 89,47 % (affiché 89.5 %), plancher fixe à 80 %.
#   ⇒ perdre UNE ligne couverte (16/19 = 84,21 %) est aujourd'hui VERT. Perdre DEUX est rouge.
#   ⇒ la marge de régression silencieuse passe de 1 ligne à 0 ligne. RIEN DE PLUS.
#
# CONVENTION — un énoncé visé est désigné par son TEXTE, jamais par un numéro de ligne :
# un numéro glisse en silence et la couverture cesse de couvrir sans qu'aucun outil ne le signale.

Fonctionnalité: Refus outillé de la régression de couverture, avec une référence lue depuis une source unique et une capacité d'échec prouvée
  En tant que mainteneur de la factory, et tout auditeur à contexte frais qui doit savoir si le chiffre de couverture qu'on lui présente protège quelque chose
  Je veux que la couverture de référence soit mesurée, consignée en un seul endroit, réellement lue, et qu'un contrôle refuse toute régression dans un contexte requis, sa capacité à rougir étant prouvée
  Afin qu'une baisse de couverture cesse de pouvoir passer inaperçue — tout en sachant, et en l'écrivant, que ce mécanisme empêche de reculer sans jamais faire avancer la qualité des tests

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-1 — La couverture initiale est MESURÉE et publiée avec son dénominateur  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La couverture initiale est mesurée et publiée avec son dénominateur (Nominal — AC-1)
    Étant donné un squelette applicatif dont la couverture n'a jamais été mesurée ni consignée
    Quand la mesure est exécutée par une commande rejouable
    Alors la sortie brute et datée de cette commande est archivée avec les preuves de la story
    Et le rapport énonce le pourcentage et son dénominateur explicite, en lignes couvertes sur lignes mesurées
    Et il nomme les lignes non couvertes et la nature de chacune
    Et il nomme les fichiers entrant dans la mesure ainsi que la version de l'outil et du runtime
    Et le contrôle imprime son dénominateur y compris lorsqu'il réussit
    Et si le constat diffère de la valeur attendue par la spécification, c'est le constat qui fait foi

  Scénario: Une mesure recopiée à la main, ou un vert obtenu sur un rapport sans ligne mesurable, est refusée (Erreur — AC-1)
    Étant donné un rapport de conformité qui avancerait un pourcentage de couverture
    Quand ce pourcentage n'est accompagné d'aucun dénominateur, ou qu'il est recopié à la main
    Alors il n'est pas tenu pour une mesure et il est refusé
    Et un succès obtenu sur un rapport ne contenant aucune ligne mesurable est un faux succès, refusé explicitement
    Et un rapport de couverture absent produit un échec qui nomme la commande à lancer
    Et l'absence de rapport ne produit jamais un succès par défaut

  Scénario: Sur dix-neuf lignes, le chiffre n'a aucune valeur statistique (Limite — AC-1)
    Étant donné une mesure portant sur dix-neuf lignes d'un seul fichier de squelette
    Quand j'évalue ce que ce chiffre établit
    Alors il est écrit qu'une seule ligne vaut plus de cinq points de pourcentage
    Et il est écrit qu'aucune valeur de couverture n'existe entre la valeur courante et la valeur immédiatement supérieure
    Et il est écrit qu'aucune fonctionnalité métier n'est couverte, parce qu'il n'en existe aucune
    Et il est écrit que la mesure porte sur les lignes seulement, aucune couverture de branches n'étant produite par l'outil
    Et il est écrit que les seules lignes non couvertes sont le point d'entrée de l'application
    Et la question de savoir si un fichier qu'aucun test n'importe entre au dénominateur est tranchée par expérience, et sa réponse écrite avec sa conséquence pour la première story métier
    Et cette expérience se mène avec un fichier temporaire non livré, le dossier applicatif étant vérifié inchangé en fin de course

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-2 — La référence vit en un seul endroit et elle est RÉELLEMENT LUE  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La référence vit dans la source unique de configuration et le contrôle la lit vraiment (Nominal — AC-2)
    Étant donné une clé de cliquet déclarée au schéma de configuration mais absente de la configuration réelle
    Et que la seule lecture existante de cette clé ne concerne qu'un composant qui n'existe pas dans cet adapter
    Quand la référence est consignée dans la source unique et que le contrôle de couverture la lit
    Alors la preuve que la valeur est lue est faite par mutation : la valeur est modifiée et le verdict change, elle est remise et le verdict revient
    Et une valeur présente dont la modification ne change rien vaut échec
    Et aucun artefact exécuté ne porte le seuil en dur, ni la commande du gate, ni une valeur par défaut de script, ni un workflow
    Et le contrôle de sortie qui l'établit est publié comme une commande rejouable
    Et un document peut citer le seuil à condition de désigner la configuration comme source

  Scénario: Une référence non lue est un échec, et une clé absente ne produit ni plantage ni vert silencieux (Erreur — AC-2)
    Étant donné que le contrôle de couverture est exécuté par un contexte requis pour fusionner
    Quand la clé de référence est absente ou mal formée
    Alors le comportement est explicite et défini
    Et il n'y a jamais de plantage, un plantage verrouillant toutes les pull requests
    Et il n'y a jamais de succès silencieux, ce succès étant le seul état que cette story existe pour supprimer
    Et le message nomme la clé manquante et l'endroit où l'écrire
    Et une référence consignée sans être lue est un échec bloquant, et non une étape
    Et toute livraison qui modifierait le script de synchronisation de configuration est refusée, quel que soit le bénéfice invoqué

  Scénario: La référence ne bouge que par un geste humain, et rien ne détecte sa péremption (Limite — AC-2)
    Étant donné que la source unique de configuration est protégée par un mécanisme réservant son édition à un geste humain
    Quand j'évalue ce que cela implique pour la référence
    Alors toute mise à jour de la référence est une action humaine, sans exception ni automatisation possible
    Et il est écrit qu'aucun mécanisme ne vérifie que la référence corresponde à un état réel du dépôt
    Et il est écrit que cette absence de détection est de la même classe que celle déjà nommée pour la protection de branche, et que cette story ne la ferme pas
    Et il est écrit que le texte normatif annonce une vérification des seuils par le script de synchronisation, laquelle ne vérifie rien pour ce composant et continuera de ne rien vérifier

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-3 — Le cliquet REFUSE la régression, et sa capacité à refuser est PROUVÉE  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Une baisse de couverture rend rouge un contexte requis (Nominal — AC-3)
    Étant donné une référence de couverture consignée et lue
    Quand la couverture mesurée est strictement inférieure à cette référence
    Alors le contrôle échoue
    Et son message nomme la valeur mesurée, la référence, l'écart et le dénominateur
    Et la pull request devient infusionnable, le contrôle étant porté par un contexte requis, administrateur inclus
    Et lorsque la couverture est supérieure ou égale à la référence, le contrôle réussit en imprimant son dénominateur
    Et sur un dépôt inchangé le contrôle ne rougit jamais, la référence étant consignée dans une forme que la mesure du jour satisfait
    Et cette absence de rouge est prouvée par une exécution lancée immédiatement après la consignation de la référence

  Scénario: La capacité d'échouer est prouvée par mutation, et un rapport tronqué ne produit jamais un vert (Erreur — AC-3)
    Étant donné le principe selon lequel un contrôle qui ne peut pas rougir est nul
    Quand la capacité d'échec du cliquet est éprouvée
    Alors elle est prouvée par exécution contre des rapports fixtures versionnés, au nombre de quatre au moins
    Et une fixture portant une ligne couverte en moins rend le contrôle rouge, alors que ce même état est vert avant cette story
    Et une fixture à la référence exacte le rend vert
    Et une fixture au-dessus de la référence le rend vert et signale la hausse
    Et une fixture sans aucune ligne mesurable le rend rouge
    Et aucun test réel n'est cassé pour obtenir ces preuves
    Et un rapport dont les totaux déclarés contredisent les lignes comptées est refusé, un rapport tronqué augmentant mécaniquement le pourcentage puisque les lignes non couvertes sont en tête

  Scénario: Le cliquet n'améliore pas les tests et peut encourager la complaisance (Limite — AC-3)
    Étant donné un cliquet actif sur un squelette de dix-neuf lignes
    Quand j'évalue ce qu'il garantit
    Alors il est écrit qu'il n'authentifie pas le rapport, un rapport cohérent fabriqué à la main passerait
    Et il est écrit qu'il ne mesure que ce que le rapport contient
    Et il est écrit qu'il n'améliore pas la qualité des tests, qu'il interdit de reculer et ne fait jamais avancer
    Et il est écrit qu'il peut encourager des tests de complaisance
    Et le cas concret est nommé d'avance : les seules lignes non couvertes sont le point d'entrée, les couvrir n'apporterait aucune garantie et ne servirait qu'à faire monter un chiffre

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-4 — Plancher contractuel et cliquet coexistent, avec des rôles distincts  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Deux nombres, deux rôles, et le message dit lequel est violé (Nominal — AC-4)
    Étant donné un plancher contractuel déjà déclaré et une référence de cliquet nouvellement consignée
    Quand le contrôle rend son verdict
    Alors le plancher ne peut jamais être franchi, même par un abaissement justifié de la référence
    Et la référence ne peut jamais reculer
    Et le contrôle vérifie que la référence est supérieure ou égale au plancher
    Et le message dit lequel des deux est violé
    Et il est écrit pourquoi le plancher est conservé plutôt que remplacé : il borne l'abaissement volontaire, et le registre des décisions étant immuable, le supprimer contredirait une décision acceptée
    Et la clé de plancher, qu'aucun script ne lisait, est désormais lue

  Scénario: Une référence inférieure au plancher est refusée explicitement (Erreur — AC-4)
    Étant donné une configuration où la référence serait inférieure au plancher contractuel
    Quand le contrôle l'évalue
    Alors cette configuration est déclarée incohérente et refusée explicitement
    Et il n'y a jamais de succès silencieux
    Et le plus strict des deux ne l'emporte jamais en silence
    Et abaisser la référence sous le plancher est impossible, quel que soit le motif invoqué

  Scénario: Deux nombres sur dix-neuf lignes, c'est de la précision affichée (Limite — AC-4)
    Étant donné un plancher et une référence séparés de plus de neuf points de pourcentage
    Quand j'évalue ce que cet écart représente sur dix-neuf lignes
    Alors il est écrit qu'il ne vaut qu'une ligne et demie
    Et il est écrit que deux nombres à une décimale sur dix-neuf lignes relèvent de la précision affichée et non de la précision réelle
    Et il est écrit que le plancher est dormant tant que la référence lui est supérieure, seule la référence bloquant alors

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-5 — Hausse et baisse volontaire sont des gestes explicites et tracés  (Should)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La hausse est signalée sans bloquer, la baisse volontaire est motivée et tracée (Nominal — AC-5)
    Étant donné une couverture mesurée supérieure à la référence consignée
    Quand le contrôle rend son verdict
    Alors il reste vert
    Et il imprime la valeur exacte à consigner ainsi que le fait que seul un humain peut le faire
    Et il ne remonte jamais la référence de lui-même
    Et il ne bloque pas sur une hausse, bloquer rendrait toute amélioration rouge et irréparable dans la même pull request puisque la correction exige une édition humaine
    Et un abaissement volontaire de la référence exige une édition humaine, un motif écrit et une ligne dédiée au journal du projet
    Et un abaissement ne descend jamais sous le plancher contractuel

  Scénario: Un abaissement sans motif est refusé, et un agent ne touche pas la source unique (Erreur — AC-5)
    Étant donné une proposition d'abaissement de la référence
    Quand elle ne porte aucun motif écrit
    Alors elle est refusée en revue
    Et un agent qui tente d'éditer la référence est bloqué par le mécanisme de protection des fichiers
    Et il est écrit que ce blocage est l'une des rares barrières réellement machine de ce dépôt
    Et il est écrit qu'elle bloque l'outil d'édition de l'agent et qu'elle n'authentifie personne

  Scénario: Une référence périmée laisse passer une régression réelle (Limite — AC-5)
    Étant donné qu'aucun mécanisme n'oblige la référence à monter quand la couverture monte
    Quand j'évalue ce que le cliquet protège réellement
    Alors il est écrit que la référence peut rester périmée indéfiniment
    Et il est écrit que si la référence restait au plancher alors que la couverture réelle lui est très supérieure, une régression jusqu'au plancher passerait silencieusement
    Et il est écrit que le cliquet ne protège que le dernier niveau consigné, jamais le niveau atteint
    Et il est écrit qu'aucune détection automatique de cette péremption n'existe, son seul porteur possible étant l'audit périodique de la factory, lequel n'a aucun déclencheur calendaire
    Et cette dette est nommée sans être fermée
    Et il est écrit que le format de configuration ne portant aucun commentaire, le lien entre le nombre et son motif demeure une convention non enforcée si la référence ne porte pas elle-même sa date et son motif

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-6 — Cohérence du corpus et critère de clôture coché avec sa preuve  (Must)
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Le critère de clôture est coché avec sa preuve, et les énoncés rendus faux sont nommés (Nominal — AC-6)
    Étant donné un critère de clôture de l'epic de fondations exigeant des seuils mesurés et un cliquet actif
    Quand la story est livrée
    Alors ce critère est coché avec sa preuve outillée datée et avec ses bornes
    Et tout énoncé du corpus que le succès de cette story rend faux ou incomplet est nommé
    Et chaque énoncé nommé est cité littéralement, jamais par un numéro de ligne
    Et chaque énoncé nommé porte la raison pour laquelle il devient faux et son destinataire, corrigé ici ou versé à une story nommée
    Et le balayage couvre au minimum le texte normatif, le registre des décisions, l'inventaire du backlog, le document de démarrage et le fichier de l'epic

  Scénario: Taire un énoncé rendu faux est bloquant, et aucun texte immuable n'est édité (Erreur — AC-6)
    Étant donné un énoncé du corpus que cette story rend faux
    Quand une livraison le passe sous silence
    Alors le défaut est bloquant, cette story en étant la productrice
    Et l'édition d'une décision acceptée est refusée, sa rectification passant par une nouvelle décision
    Et aucun article du texte normatif autre que celui visé n'est touché
    Et si le texte normatif est amendé, ce l'est dans une pull request dédiée, le mot dédiée se lisant à la lettre
    Et un agent ne se substitue pas à l'attestation humaine et ne la présume pas, aucun message d'agent ne valant approbation
    Et aucun énoncé exact n'est corrigé au titre d'un périmètre plus ancien, ce qui serait une régression documentaire

  Scénario: Un critère coché ne clôt pas l'epic, et ces scénarios ne s'exécutent pas (Limite — AC-6)
    Étant donné un critère de clôture coché et un cliquet actif
    Quand j'évalue ce que cela garantit
    Alors il est écrit que l'epic n'est pas clos pour autant, d'autres critères en étant indépendants
    Et il est écrit qu'un cliquet actif ne garantit ni la qualité des tests ni la couverture du métier, dont il n'existe aucun
    Et il est écrit qu'aucune exhaustivité du balayage de cohérence n'est revendiquée
    Et la méthode employée et ses angles morts sont écrits
    Et le critère de sortie est une commande rejouable dont la sortie est vérifiable, jamais une relecture
    Et il est écrit que les présents scénarios sont documentaires, que le projet n'a ni définition d'étapes ni moteur d'exécution, que rien en intégration continue ne les lit, et que leur nombre ne mesure aucune couverture
    Et il est écrit qu'ils ne doivent pas être confondus avec les fixtures du cliquet, lesquelles s'exécutent réellement
