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
# US-00.7 — Protection de la branche principale : application effective, preuve par l'effet,
# et mise en cohérence du corpus (valeur plateforme, EPIC_00).
#
# FAIT NOUVEAU (vérifié le 2026-07-27) : le blocage de plateforme constaté par US-00.4 est LEVÉ.
# Le dépôt a été rendu PUBLIC par décision humaine — c'est la voie (a) des conditions de déblocage
# documentées par US-00.4. La lecture de la protection ne renvoie plus 403 « Upgrade to GitHub Pro »
# mais 404 « Branch not protected » : la protection est DISPONIBLE, simplement NON APPLIQUÉE.
#
# CONSÉQUENCE POUR CES SCÉNARIOS : contrairement à ceux d'US-00.4, ils supposent, exigent et
# démontrent une protection RÉELLEMENT APPLIQUÉE. Les scénarios de refus serveur (7, 8) et de refus
# de fusion (10, 11) sont ceux qu'US-00.4 avait dû RETIRER faute de plateforme ; ils sont ici
# exigibles pour la première fois.
#
# SÉQUENCE IMPOSÉE — contrainte de sûreté portée par les scénarios 3, 9 et 19 :
#   19 (comparateur sécurisé) → 22 (libellés + retour arrière) → 1 (application) → 4 (succès réel)
#   → 7 (refus serveur) → 10 (refus de fusion).
# Exécuter un scénario de refus serveur AVANT que la protection ne soit prouvée active reviendrait
# à modifier la branche principale hors pull request : c'est INTERDIT.
#
# « --no-verify » reste interdit (Constitution Art. 1). Les preuves attendues sont des réponses
# BRUTES et DATÉES de l'API, jamais des artefacts documentaires.

Fonctionnalité: Application effective de la protection de la branche principale, preuve de son effet et mise en cohérence du corpus de gouvernance
  En tant que mainteneur du dépôt garant de l'intégrité de la branche principale
  Je veux que la protection soit réellement appliquée depuis la source unique et que son effet soit prouvé par le serveur
  Afin que la règle « jamais de commit ni de push sur la branche principale » passe de déclarée à réellement enforcée

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-1 — Protection appliquée depuis la source unique, prouvée par réponse brute d'API
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La protection est appliquée depuis la source unique et prouvée par une réponse brute de l'API (Nominal — AC-1)
    Étant donné que la protection de branche est redevenue disponible sur ce dépôt
    Et que la cible de protection est décrite par la seule configuration de la factory
    Quand la protection est appliquée en consommant le contenu généré depuis cette configuration
    Alors la branche principale est déclarée protégée par l'API
    Et le bloc de protection retourné porte exactement la cible arbitrée
    Et l'exigence de pull request est conservée bien qu'aucune approbation ne soit requise
    Et la règle vaut aussi pour l'administrateur
    Et les réponses brutes et datées sont archivées comme preuves avec leur commande exacte

  Scénario: Un échec d'application n'autorise aucun contournement manuel (Erreur — AC-1)
    Étant donné une tentative d'application de la protection qui échoue
    Quand je cherche à obtenir malgré tout une protection active
    Alors la saisie manuelle dans l'interface de la plateforme est refusée
    Et l'écriture à la main du contenu de la protection est refusée
    Et l'amputation de la cible pour faire aboutir l'appel est refusée
    Et l'échec est archivé tel quel
    Et les critères qui dépendent de l'application deviennent inatteignables

  Scénario: Une règle existante ne prouve pas encore son effet, et l'état reste révocable (Limite — AC-1)
    Étant donné une branche principale déclarée protégée par l'API
    Quand j'évalue ce que cette déclaration prouve
    Alors elle prouve l'existence de la règle mais pas son effet
    Et l'effet ne sera prouvé que par un refus émis par le serveur
    Et il est écrit qu'un administrateur peut désactiver cette règle à tout moment
    Et il est écrit qu'aucune détection automatique de cette désactivation n'existe
    Et il est écrit que la protection dépend de la visibilité publique du dépôt

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-2 — Vérification de l'état réel : succès observé in vivo, plus seulement simulé
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La vérification de l'état réel rend un succès observé sur le dépôt, et non simulé (Nominal — AC-2)
    Étant donné une protection réellement appliquée depuis la configuration
    Quand j'exécute la vérification de l'état réel contre le dépôt
    Alors elle rend un succès
    Et sa sortie emploie le mot « conforme » sur ce seul chemin
    Et sa sortie ne porte aucune marque de simulation
    Et la sortie est archivée telle quelle avec sa date
    Et il est consigné que ce chemin n'avait jamais été observé autrement que sur donnée simulée

  Scénario: Une sortie simulée ne vaut jamais preuve de l'état réel (Erreur — AC-2)
    Étant donné une vérification exécutée sur une réponse simulée
    Quand cette sortie est proposée comme preuve de l'état réel du dépôt
    Alors elle est refusée comme preuve
    Et une divergence détectée impose de ré-appliquer la protection depuis la configuration
    Et une vérification impossible n'est ni un succès ni une preuve
    Et la cause d'une vérification impossible doit être nommée

  Scénario: Un succès ponctuel n'installe aucune surveillance continue (Limite — AC-2)
    Étant donné un succès de vérification obtenu à un instant donné
    Quand j'évalue la portée de ce succès
    Alors il ne vaut qu'à l'instant de la mesure
    Et la vérification reste manuelle et hors intégration continue
    Et la dette d'absence de détection automatique de dérive reste ouverte
    Et le point de contrôle périodique est conservé et son objet est réorienté

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-3 — L'effet prouvé par le serveur, depuis un clone sans hooks
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Le serveur refuse le push direct, le force-push et la suppression (Nominal — AC-3)
    Étant donné une protection dont l'application et la conformité sont déjà prouvées
    Et un clone jetable dépourvu de tout hook local
    Quand je tente successivement un push direct sur la branche principale, un push forcé puis une suppression de cette branche
    Alors les trois tentatives sont refusées par le serveur
    Et aucune de ces tentatives n'a employé de contournement des hooks
    Et les trois sorties brutes sont archivées
    Et la référence de la branche principale est identique avant et après les tentatives

  Scénario: Un refus émis par le hook local ne prouve rien (Erreur — AC-3)
    Étant donné un clone dans lequel les hooks locaux sont installés
    Quand une tentative de push direct est refusée par le hook local
    Alors ce refus n'est pas accepté comme preuve de la protection
    Et la preuve exige un refus émis par le serveur
    Et si l'une des trois tentatives réussissait, la branche principale serait restaurée
    Et une violation de workflow serait tracée
    Et la protection serait ré-appliquée depuis la configuration

  Scénario: Le test négatif est interdit avant que la protection ne soit prouvée active (Limite — AC-3)
    Étant donné une branche principale dont la protection n'est pas encore prouvée active
    Quand un intervenant envisage d'exécuter le test négatif « pour vérifier »
    Alors l'exécution est interdite
    Et il est écrit que ces commandes réussiraient et modifieraient la branche principale hors pull request
    Et il est écrit que le test ne prouve le refus qu'à sa date et pour l'acteur employé
    Et il est écrit qu'il ne prouve rien pour une action menée depuis l'interface de la plateforme

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-4 — Les quatre gates deviennent bloquants, administrateur inclus
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La fusion est refusée tant qu'un gate requis n'est pas vert, administrateur inclus (Nominal — AC-4)
    Étant donné une pull request ouverte sur un dépôt dont la branche principale est protégée
    Et un status check requis qui n'est pas vert
    Quand le compte administrateur tente de fusionner cette pull request
    Alors la fusion est refusée par le serveur
    Et le motif du refus nomme le status check requis
    Et la sortie brute du refus est archivée
    Et la fusion n'est acceptée qu'une fois les quatre status checks requis verts

  Scénario: Aucune fusion par contournement n'est autorisée (Erreur — AC-4)
    Étant donné une pull request bloquée par un status check requis
    Quand je cherche à la fusionner malgré le blocage
    Alors la fusion en mode administrateur est interdite
    Et la désactivation temporaire de la règle pour fusionner est interdite
    Et le retrait d'un status check de la cible pour débloquer est interdit
    Et une fusion obtenue par contournement invalide le critère et vaut violation de workflow

  Scénario: Un gate requis jamais rapporté produit le même blocage, mais définitif (Limite — AC-4)
    Étant donné un status check requis dont le libellé diverge de celui rapporté par l'intégration continue
    Quand une pull request est ouverte
    Alors la pull request est bloquée exactement comme si le check était en échec
    Et le blocage est définitif car le check ne sera jamais rapporté
    Et la démonstration faite sur une pull request ne prouve rien pour les événements non exercés
    Et l'exigence de branche à jour et de discussions résolues est documentée comme condition supplémentaire de fusion

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-5 — Corpus vivant mis en cohérence, documents datés préservés
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Le document de démarrage n'affirme plus aucune impossibilité (Nominal — AC-5)
    Étant donné un document de démarrage injecté à chaque ouverture de session
    Et qu'il affirmait la protection de branche indisponible sur ce dépôt
    Quand la protection est appliquée et prouvée
    Alors ce document ne porte plus aucune affirmation d'impossibilité
    Et la règle interdisant le push direct sur la branche principale est vraie et son périmètre exact est écrit
    Et le risque de règles déclarées mais non enforcées est déclaré clos avec sa date et sa preuve
    Et le critère de clôture du chantier de fondations devient cochable

  Scénario: Les documents datés et certifiés ne sont jamais réécrits (Erreur — AC-5)
    Étant donné des documents antérieurs qui constataient une impossibilité de plateforme
    Et que ces documents étaient exacts à leur date
    Quand le corpus vivant est mis en cohérence
    Alors les documents datés et certifiés ne sont pas modifiés
    Et ils sont référencés avec la mention de la date à laquelle leur constat a été levé
    Et aucun livrable n'affirme davantage que ce que les preuves établissent

  Scénario: L'exhaustivité du balayage n'est pas revendiquée, et les restes sont transmis nommément (Limite — AC-5)
    Étant donné un balayage du dépôt par motifs et toutes extensions
    Quand ses résultats sont consignés
    Alors la méthode employée est écrite ainsi que ses angles morts
    Et l'exhaustivité n'est pas revendiquée
    Et les affirmations devenues vraies dans les textes normatifs sont signalées comme n'ayant plus besoin de correction
    Et l'affirmation devenue vraie dans une story certifiée est transmise sans que cette story soit éditée

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-6 — La dérogation devient sans objet
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: La dérogation est explicitement déclarée sans objet (Nominal — AC-6)
    Étant donné une dérogation humaine tracée portant sur le refus de deux voies de déblocage
    Et que l'une de ces deux voies a finalement été choisie
    Quand la protection est appliquée
    Alors la dérogation est déclarée sans objet et datée
    Et la consignation renvoie à l'événement de dérogation d'origine
    Et elle figure là où un audit à contexte frais la lira nécessairement

  Scénario: Une dérogation laissée lisible comme active trompe l'audit suivant (Erreur — AC-6)
    Étant donné une dérogation dont le motif a disparu
    Quand aucune mention de son extinction n'est écrite
    Alors un audit ultérieur peut croire qu'une exception de gouvernance couvre encore le trou d'enforcement
    Et cette omission est un défaut bloquant
    Et la suppression ou la réécriture de l'événement d'origine dans la trace reste interdite

  Scénario: L'extinction de la dérogation est conditionnelle à la visibilité du dépôt (Limite — AC-6)
    Étant donné que la disponibilité de la protection dépend de la visibilité publique du dépôt
    Quand j'évalue la portée de l'extinction de la dérogation
    Alors il est écrit qu'un retour du dépôt en privé rendrait la protection à nouveau indisponible
    Et il est écrit que la question de la dérogation redeviendrait alors ouverte
    Et le point de contrôle périodique vérifie désormais la persistance de la protection et la visibilité du dépôt
    Et la condition de retour à une approbation dès un second collaborateur reste valable

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-7 — Le chemin de succès du comparateur est sécurisé avant d'être invoqué
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Le chemin de succès du comparateur est sécurisé avant d'être invoqué comme preuve (Nominal — AC-7)
    Étant donné un comparateur dont le chemin de succès peut ignorer un champ actif lorsque la cible est amputée
    Et que cette US invoque ce succès comme preuve d'un état de sécurité
    Quand le correctif d'une ligne est appliqué
    Alors un champ présent dans la réponse réelle mais absent de la cible est nommé
    Et il interdit le succès
    Et la démonstration avant et après correctif est archivée
    Et le rattachement du correctif à cette US est justifié par l'usage du succès comme preuve

  Scénario: Le correctif ne rend pas l'outil rouge sur une évolution neutre de l'API (Erreur — AC-7)
    Étant donné une réponse portant des champs additionnels neutres
    Quand la vérification est exécutée après le correctif
    Alors les champs neutres sont nommés sans altérer l'issue
    Et l'issue reste un succès
    Et tous les chemins d'exécution déjà couverts sont rejoués sans changement d'issue
    Et un correctif qui casserait un chemin existant est refusé

  Scénario: Le correctif n'est protégé par aucun gate automatique (Limite — AC-7)
    Étant donné que le comparateur n'est couvert par aucun test automatisé en intégration continue
    Et qu'il n'est protégé par aucun garde-fou d'édition
    Quand le correctif est livré
    Alors la preuve de son effet est archivée manuellement
    Et la dette d'absence de test automatisé reste ouverte
    Et la dette d'absence de protection du fichier reste ouverte

  # ────────────────────────────────────────────────────────────────────────────────────────
  #  AC-8 — Risque de verrouillage traité avant l'application, retour arrière écrit
  # ────────────────────────────────────────────────────────────────────────────────────────

  Scénario: Les libellés sont vérifiés et le plan de retour arrière est écrit avant l'application (Nominal — AC-8)
    Étant donné que la règle vaut aussi pour l'administrateur
    Et qu'un libellé de status check divergent d'un seul caractère rendrait toute fusion impossible
    Quand je prépare l'application de la protection
    Alors les quatre libellés sont vérifiés caractère par caractère entre la configuration et les workflows
    Et la preuve de cette vérification est archivée
    Et un plan de retour arrière est écrit avant toute application
    Et ce plan énonce le symptôme, le mécanisme de récupération, les commandes exactes et l'obligation de tracer

  Scénario: Un verrouillage se répare par l'édition tracée de la règle, jamais par un contournement (Erreur — AC-8)
    Étant donné une situation où plus aucune pull request ne peut être fusionnée
    Quand j'engage la récupération
    Alors l'édition de la règle par l'administrateur est autorisée car elle n'est pas un contournement
    Et la correction du libellé se fait dans la source unique
    Et la protection est ensuite ré-appliquée depuis la configuration
    Et l'incident est consigné
    Et aligner la configuration sur l'état constaté est refusé

  Scénario: Un gate requis qui ne se déclenche pas sur certains événements bloque définitivement (Limite — AC-8)
    Étant donné un status check requis porté par un workflow qui ne se déclenche pas sur tous les événements de pull request
    Quand une pull request survient sur un événement non couvert
    Alors le check requis n'est jamais rapporté
    Et la pull request est bloquée définitivement et silencieusement
    Et ce point de vigilance est écrit pour les pull requests futures
    Et le plan de retour arrière est désigné comme le filet de sécurité de ce cas
