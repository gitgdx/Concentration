# language: fr
# US-01.2 — Gestion des échéances (CRUD) — EPIC_01, track FULL
#
# Périmètre : page de gestion (création / édition / suppression), validation, limite de 9,
# persistance locale offline-first, migration réversible.
# US-01.2 FOURNIT LES DONNÉES RÉELLES que US-01.1 affichait à partir de données d'exemple.
# Le moteur de temps restant (RF-02/03/04) est livré par US-01.1 et n'est PAS modifié ici.
#
# ⚖️ DÉCOUPAGE ARBITRÉ PAR L'HUMAIN LE 2026-08-03 : RF-06 (geste double-tap, animation de
#    disparition, historique des échues retirées) SORT de cette US et devient US-01.4.
#    Motif inscrit : le cœur d'US-01.2 est le critère d'entrée transféré par EPIC_00 (instancier
#    ADR-005 — première migration réellement exécutée du projet) ; y adjoindre un geste avec
#    animation dilue l'attention sur la partie la plus risquée.
#    ⇒ 5 scénarios (AC-9) + 1 scénario (distinction échue retirée, AC-8) sont PARTIS vers US-01.4.
#    ⛔ Ils ne sont pas supprimés du projet : ils sont DÉPLACÉS, et le Story File le date.
#    Conséquence à connaître ici : en US-01.2, une échéance échue reste sur la grille jusqu'à sa
#    SUPPRESSION — c'est la seule issue disponible pour libérer une place (AC-5).
#
# ⚖️ DEUX AC AJOUTÉS PAR DÉCISION HUMAINE LE 2026-08-06 — AC-16 et AC-17, 5 scénarios (45 → 50).
#    Ils ont été découverts À LA JOINTURE des deux branches de design, qui ont tourné en aveugle
#    l'une de l'autre : @DataEngineer a MESURÉ la chaîne de défaut (règle V-1), @UXDesigner a NOMMÉ
#    la lacune de l'échec d'écriture (§10.5) sans inventer d'AC — ce qui était correct de sa part.
#    ⛔ Les numéros AC-16 et AC-17 SUIVENT AC-15 : AC-9 reste VACANT et rien n'est renuméroté.
#    ⛔ TROIS règles du schéma de stockage restent DÉLIBÉRÉMENT sans AC et sans scénario
#      (document de version FUTURE, `id` en double, `schemaVersion` absent — arbitrage humain du
#      2026-08-06, voie (b)) : contrat interne invisible à l'utilisateur, couvert par des tests
#      unitaires déclarés. ⛔ NE PAS leur écrire de Gherkin.
#
# ⚠️ CE FICHIER EST NORMATIF. En cas de divergence avec un résumé en prose (Story File, SCB,
#    PROJECT_LOG), c'est LUI qui fait foi. Défaut réel d'US-01.1 : 13 scénarios et 13 lignes de
#    résumé divergeaient par 5 titres.
#
# ⚠️ CORRESPONDANCE 1:1 ET BLOQUANTE. `scripts/check_gherkin_mapping.py` (job requis
#    « 📋 Governance ») exige qu'un test porte VERBATIM le titre de chaque scénario, et signale
#    l'écart dans les DEUX sens. Conséquences assumées, à connaître avant d'éditer ce fichier :
#      1. un titre est STABLE et UNIQUE — le renommer casse le gate ;
#      2. AUCUN scénario n'est écrit pour une clause non mesurable avec l'outillage actuel : elle
#         serait « scénario sans test » par construction, donc gate ROUGE. Ces clauses sont listées
#         dans le Story File §« Clauses non mesurables en l'état », jamais déguisées en scénario ;
#      3. le couple (.feature, fichier de tests) ne s'enregistre dans `COUPLES` qu'une fois les
#         tests écrits — l'enregistrer plus tôt rend le job requis rouge (ordonnancement @Architect).
#
# ℹ️ Plusieurs titres portent une apostrophe : côté Dart, utiliser une chaîne à guillemets doubles
#    (`testWidgets("L'édition …")`). Aucun titre ne contient de guillemet, précisément pour cela.
#
# Vocabulaire (cohérent avec US-01.1 et docs/architecture/MODELE_ECHEANCE.md) :
#   - échéance ACTIVE           : temps restant > 0, tuile affichée avec son nombre ;
#   - échéance ÉCHUE            : temps restant <= 0, tuile en état « à zéro », TOUJOURS sur la grille ;
#   - échéance SUPPRIMÉE        : détruite après confirmation explicite (seul acte destructif) ;
#   - « présentes sur la grille » : actives + échues — c'est CE décompte que borne la limite de 9
#                                 (RF-15, arbitrage humain du 2026-08-03, clarify nº 5).
#   ⇒ L'état « ÉCHUE RETIRÉE » (tuile disparue, échéance conservée) N'EXISTE PAS en US-01.2 :
#     il est introduit par US-01.4 avec le geste qui le produit. US-01.2 introduit l'état ÉCHU,
#     US-01.4 introduit le geste qui l'utilise.
#
# ⚖️ MODÈLE DE DATE ARBITRÉ LE 2026-08-03 : une échéance est une DATE CIVILE (« le 15 mars à
#    23:59 »), pas un instant absolu. Le temps restant se calcule contre l'instant LOCAL courant.
#    Une date civile N'A PAS DE FUSEAU, donc un déplacement de fuseau NE PEUT PAS la déplacer.

Fonctionnalité: Gestion des échéances — création, édition, suppression, limite et persistance locale
  En tant que pratiquant régulier d'exercices de recentrage
  Je veux saisir, corriger et supprimer moi-même les échéances de ma revue mentale, sur mon seul appareil
  Afin que la grille reflète mes propres échéances plutôt qu'un jeu d'exemple, sans jamais perdre de donnée

  # ---------------------------------------------------------------------------
  # AC-1 — Accès à la page de gestion depuis le hub (RF-10, RF-20)
  # ---------------------------------------------------------------------------

  Scénario: Ouverture de la page de gestion depuis le hub
    Étant donné que le hub de pratiques est affiché
    Quand j'active la commande de la barre de navigation basse libellée "Gérer les échéances"
    Alors la page de gestion est affichée en mode sombre de référence
    Et elle liste les échéances enregistrées dans le stockage local

  Scénario: La page de gestion sans aucune échéance affiche un état vide sobre
    Étant donné que le stockage local ne contient aucune échéance
    Quand j'ouvre la page de gestion
    Alors un message sobre invitant à créer une échéance est affiché
    Et aucune erreur technique ni couleur d'urgence n'apparaît

  Scénario: Ouvrir la gestion ne rend pas interactifs les modules grisés
    Étant donné que la page de gestion a été ouverte puis refermée
    Quand je touche les modules Respiration puis Concentration sur le hub
    Alors ils restent visibles et grisés
    Et aucune navigation ni action n'est déclenchée
    Et la commande "Réglages" de la barre de navigation basse reste non-interactive

  # ---------------------------------------------------------------------------
  # AC-2 — Création : description obligatoire (RF-11)
  # ---------------------------------------------------------------------------

  Scénario: Une échéance est créée avec une description et une date
    Étant donné que le stockage local ne contient aucune échéance
    Quand je crée une échéance décrite Convent dont la date est dans 3 mois
    Alors l'échéance est listée parmi les échéances actives de la page de gestion
    Et une tuile correspondante est affichée sur la grille
    Et le stockage local contient exactement 1 échéance

  Scénario: Une création sans description est refusée
    Étant donné que le formulaire de création est ouvert
    Quand je valide le formulaire avec une date future valide et une description vide
    Alors la création est refusée par un message explicite désignant la description
    Et le stockage local ne contient aucune échéance

  Scénario: Une description composée uniquement de blancs est refusée
    Étant donné que le formulaire de création est ouvert
    Quand je valide le formulaire avec une date future valide et une description faite de 3 espaces
    Alors la création est refusée par un message explicite désignant la description
    Et le stockage local ne contient aucune échéance

  Scénario: Une description trop longue est refusée
    Étant donné que la longueur maximale d'une description est de 80 caractères
    Quand je valide le formulaire avec une date future valide et une description de 81 caractères
    Alors la création est refusée par un message explicite indiquant la longueur maximale
    Et la même création avec une description de 80 caractères est acceptée

  Scénario: Les espaces de début et de fin de la description sont retirés
    Étant donné que le formulaire de création est ouvert
    Quand je crée une échéance dont la description est entourée d'espaces
    Alors la description enregistrée ne comporte aucun espace de début ni de fin
    Et la tuile de la grille affiche la description sans ces espaces

  # ---------------------------------------------------------------------------
  # AC-3 — Date obligatoire, heure optionnelle par défaut 23:59 (RF-11, décision produit nº 1)
  # ---------------------------------------------------------------------------

  Scénario: Une échéance saisie sans heure est enregistrée à 23h59
    Étant donné que le formulaire de création est ouvert
    Quand je crée une échéance avec une date future et sans renseigner l'heure
    Alors l'heure enregistrée pour cette échéance est 23:59
    Et le temps restant est calculé jusqu'à 23:59 du jour indiqué

  Scénario: Une création sans date est refusée
    Étant donné que le formulaire de création est ouvert
    Quand je valide le formulaire avec une description valide et aucune date
    Alors la création est refusée par un message explicite désignant la date
    Et le stockage local ne contient aucune échéance

  Scénario: Une échéance du jour courant sans heure reste valide avant 23h59
    Étant donné qu'il est 08:00 aujourd'hui
    Quand je crée une échéance à la date du jour sans renseigner l'heure
    Alors la création est acceptée
    Et le nombre affiché sur sa tuile est 16

  # ---------------------------------------------------------------------------
  # AC-4 — L'échéance doit être strictement dans le futur (RF-14)
  # ---------------------------------------------------------------------------

  Scénario: Une échéance placée dans le passé est refusée
    Étant donné que le formulaire de création est ouvert
    Quand je valide le formulaire avec une description valide et la date de la veille
    Alors la création est refusée par un message explicite indiquant que la date doit être dans le futur
    Et le stockage local ne contient aucune échéance

  Scénario: Une échéance dont le temps restant est nul est refusée
    Étant donné qu'il est 08:00 aujourd'hui
    Quand je valide le formulaire avec une date et une heure fixées exactement à 08:00 aujourd'hui
    Alors la création est refusée par un message explicite indiquant que la date doit être dans le futur
    Et le stockage local ne contient aucune échéance

  Scénario: Une édition qui place l'échéance dans le passé est refusée
    Étant donné qu'une échéance active existe
    Quand je modifie sa date pour la date de la veille et que je valide
    Alors la modification est refusée par un message explicite indiquant que la date doit être dans le futur
    Et l'échéance conserve sa date d'origine dans le stockage local

  # ---------------------------------------------------------------------------
  # AC-5 — Limite de 9 échéances présentes sur la grille (RF-15, décision produit nº 5)
  # ---------------------------------------------------------------------------

  Scénario: La neuvième échéance est créée normalement
    Étant donné que 8 échéances sont présentes sur la grille
    Quand je crée une neuvième échéance valide
    Alors la création est acceptée
    Et 9 tuiles sont affichées sur la grille

  Scénario: La dixième création est refusée avec un message nommant la limite
    Étant donné que 9 échéances sont présentes sur la grille
    Quand je tente de créer une dixième échéance valide
    Alors la création est refusée
    Et le message nomme la limite de 9 échéances et invite à supprimer une échéance existante
    Et le stockage local contient toujours 9 échéances

  Scénario: Une échéance échue présente sur la grille compte dans la limite de neuf
    Étant donné que 8 échéances actives et 1 échéance échue sont présentes sur la grille
    Quand je tente de créer une échéance valide
    Alors la création est refusée par le message de limite
    Et le stockage local contient toujours 9 échéances

  Scénario: Supprimer une échéance libère une place
    Étant donné que 9 échéances sont présentes sur la grille dont 1 échue
    Quand je supprime l'échéance échue après confirmation
    Et que je crée ensuite une échéance valide
    Alors la création est acceptée
    Et 9 tuiles sont affichées sur la grille

  # ---------------------------------------------------------------------------
  # AC-6 — Édition d'une échéance (RF-12)
  # ---------------------------------------------------------------------------

  Scénario: La modification de la description est reflétée sur la grille sans redémarrage
    Étant donné qu'une échéance active est affichée sur la grille
    Quand je modifie sa description et que je valide
    Alors la page de gestion affiche la nouvelle description
    Et la tuile correspondante affiche la nouvelle description sans redémarrage de l'application

  Scénario: La modification de la date recalcule le nombre affiché sur la tuile
    Étant donné qu'une échéance dont la date est dans 3 jours affiche le nombre 3
    Quand je reporte sa date à 5 jours
    Alors la tuile affiche le nombre 5

  Scénario: Une édition invalide est refusée et l'échéance conserve ses valeurs d'origine
    Étant donné qu'une échéance active existe avec sa description et sa date
    Quand je vide sa description et que je valide
    Alors la modification est refusée par un message explicite
    Et l'échéance conserve sa description et sa date d'origine dans le stockage local

  Scénario: L'édition d'une échéance échue est refusée
    Étant donné qu'une échéance échue est listée dans la page de gestion
    Quand je tente de modifier cette échéance
    Alors la modification est refusée par un message indiquant qu'une échéance échue se consulte ou se supprime
    Et l'échéance échue reste inchangée dans le stockage local

  Scénario: Annuler une édition laisse l'échéance inchangée
    Étant donné qu'une échéance active est ouverte en édition avec des valeurs modifiées non validées
    Quand j'annule l'édition
    Alors l'échéance conserve ses valeurs d'origine
    Et aucune écriture n'a eu lieu dans le stockage local

  # ---------------------------------------------------------------------------
  # AC-7 — Suppression définitive avec confirmation (RF-13)
  # ---------------------------------------------------------------------------

  Scénario: La suppression demande une confirmation explicite
    Étant donné qu'une échéance active est listée dans la page de gestion
    Quand je demande la suppression de cette échéance
    Alors une confirmation explicite est demandée avant toute suppression
    Quand je confirme la suppression
    Alors l'échéance disparaît de la page de gestion et de la grille

  Scénario: Annuler la confirmation laisse l'échéance en place
    Étant donné qu'une confirmation de suppression est affichée pour une échéance
    Quand j'annule la confirmation
    Alors l'échéance est toujours listée dans la page de gestion
    Et elle est toujours présente sur la grille et dans le stockage local

  Scénario: Une échéance supprimée ne réapparaît pas après réouverture
    Étant donné qu'une échéance a été supprimée après confirmation
    Quand je rouvre l'application
    Alors l'échéance supprimée n'est ni dans la page de gestion ni sur la grille

  Scénario: Une échéance échue est supprimable définitivement
    Étant donné qu'une échéance échue est listée parmi les échues de la page de gestion
    Quand je demande sa suppression et que je confirme
    Alors elle disparaît de la page de gestion, de la grille et du stockage local

  # ---------------------------------------------------------------------------
  # AC-8 — Liste de gestion : actives et échues (RF-10)
  # ---------------------------------------------------------------------------

  Scénario: La page de gestion liste les échéances actives et les échues dans deux groupes
    Étant donné que le stockage local contient 3 échéances actives et 2 échéances échues
    Quand j'ouvre la page de gestion
    Alors les 3 échéances actives sont listées dans un groupe, triées par date d'échéance croissante
    Et les 2 échéances échues sont listées dans un groupe distinct, de la plus récemment échue à la plus ancienne

  Scénario: Une échéance à description vide reste listée et manipulable
    Étant donné que le stockage local contient une échéance dont la description est vide
    Quand j'ouvre la page de gestion
    Alors cette échéance est listée avec sa date
    Et elle peut être éditée ou supprimée comme les autres

  Scénario: La page de gestion affiche le temps restant avec son unité
    Étant donné qu'une échéance active dont la date est dans 3 jours est enregistrée
    Quand j'ouvre la page de gestion
    Alors la liste affiche son temps restant avec son unité, soit 3 jours
    Et la tuile de la grille continue de n'afficher que le nombre nu 3, sans unité

  # ⚖️ 2026-08-03 — DÉPLACÉ VERS US-01.4 avec RF-06 : « Une échéance échue encore présente sur la
  #    grille est signalée comme telle ». Sans le geste de retrait, TOUTE échue est sur la grille :
  #    la distinction « retirée / non retirée » n'a plus d'objet ici. ⛔ Scénario non supprimé du
  #    projet — déplacé, et daté dans le Story File.

  # ---------------------------------------------------------------------------
  # AC-9 — ⚖️ DÉPLACÉ EN ENTIER VERS US-01.4 le 2026-08-03 (RF-06 : double-tap, animation,
  #        historique des retirées, risque nº 5 d'EPIC_01). 5 scénarios sont partis :
  #          - Un double-tap sur une tuile échue la fait disparaître de la grille
  #          - La tuile échue disparaît au terme d'une animation et non instantanément
  #          - L'échéance retirée de la grille reste consultable en gestion à l'état échu
  #          - Un double-tap sur une tuile active n'a aucun effet
  #          - Un appui simple ou prolongé sur une tuile échue n'a aucun effet
  #        ⛔ Le numéro AC-9 reste VACANT : les AC suivants ne sont PAS renumérotés — un
  #        identifiant qui glisse casse en silence toute référence déjà écrite (leçon US-00.7).
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # AC-10 — Persistance locale offline-first (RNF-01, RNF-07)
  # ---------------------------------------------------------------------------

  Scénario: Les échéances et leur état sont restitués à l'identique après réouverture
    Étant donné que le stockage local contient 2 échéances actives et 1 échéance échue
    Quand je rouvre l'application
    Alors les 3 échéances sont affichées sur la grille, l'échue en tête
    Et l'échéance échue est listée dans le groupe des échues de la page de gestion

  Scénario: Aucune donnée ne quitte l'appareil et aucun appel réseau n'est émis
    Étant donné que l'application est utilisée sans aucune connexion
    Quand je crée, modifie puis supprime une échéance
    Alors les trois opérations aboutissent
    Et aucun appel réseau n'est émis par l'application

  # ---------------------------------------------------------------------------
  # AC-11 — Robustesse aux données locales illisibles (lève les chemins N-6 et NB-1)
  # ---------------------------------------------------------------------------

  Scénario: Un enregistrement local illisible est ignoré sans empêcher l'ouverture
    Étant donné que le stockage local contient 2 enregistrements valides et 1 enregistrement illisible
    Quand j'ouvre l'application
    Alors l'application s'ouvre et le hub reste affiché
    Et seules les 2 échéances valides sont affichées sur la grille

  Scénario: Un enregistrement illisible n'est ni réécrit ni supprimé
    Étant donné que le stockage local contient 1 enregistrement illisible
    Quand j'ouvre l'application puis la page de gestion
    Alors l'enregistrement illisible est toujours présent et inchangé dans le stockage local
    Et il n'est listé ni parmi les actives ni parmi les échues

  Scénario: Un stockage entièrement illisible conduit à l'état vide et jamais à une erreur technique
    Étant donné qu'aucun enregistrement du stockage local n'est lisible
    Quand j'ouvre l'application
    Alors la grille affiche l'état vide sobre
    Et aucune erreur technique n'est affichée

  # ---------------------------------------------------------------------------
  # AC-12 — Durabilité lors d'un changement de version du stockage (ADR-005 instancié)
  # ---------------------------------------------------------------------------

  Scénario: Les échéances d'une version antérieure du stockage restent intactes après migration
    Étant donné que le stockage local est dans une version antérieure et contient 3 échéances
    Quand j'ouvre l'application dans sa version courante
    Alors la migration montante est exécutée une seule fois
    Et les 3 échéances sont restituées avec leur description, leur date et leur heure inchangées

  Scénario: Une migration interrompue laisse les données dans leur état antérieur
    Étant donné que le stockage local est dans une version antérieure et contient 3 échéances
    Quand la migration montante échoue en cours d'exécution
    Alors les 3 échéances sont toujours lisibles dans leur état antérieur
    Et aucune donnée n'est perdue ni tronquée

  Scénario: Le retour arrière de migration restitue l'état antérieur sans perte
    Étant donné que la migration montante a été exécutée sur un stockage contenant 3 échéances
    Quand la migration descendante est exécutée
    Alors le stockage revient à sa version antérieure
    Et les 3 échéances sont restituées à l'identique

  # ---------------------------------------------------------------------------
  # AC-13 — La grille consomme les données réelles (fournit à US-01.1)
  # ---------------------------------------------------------------------------

  Scénario: La grille affiche les échéances persistées et non plus les données d'exemple
    Étant donné que le stockage local contient 2 échéances saisies par le pratiquant
    Quand j'ouvre l'application
    Alors la grille affiche exactement ces 2 échéances
    Et aucune échéance d'exemple ne figure sur la grille

  Scénario: Sur une installation neuve la grille affiche l'état vide
    Étant donné que l'application est installée et que son stockage local est vide
    Quand j'ouvre l'application
    Alors la grille affiche l'état vide sobre invitant à ajouter une échéance
    Et aucune échéance d'exemple n'est affichée

  Scénario: Une échéance créée apparaît sur la grille sans redémarrage
    Étant donné que la grille affiche 2 tuiles
    Quand je crée une troisième échéance valide
    Alors la grille affiche 3 tuiles sans redémarrage de l'application

  # ---------------------------------------------------------------------------
  # AC-14 — Une échéance est une DATE CIVILE, pas un instant absolu (RNF-04)
  #         ⚖️ Arbitré le 2026-08-03. Une date civile n'a pas de fuseau : la décision DISSOUT le
  #         problème du changement de fuseau au lieu de le gérer.
  # ---------------------------------------------------------------------------

  Scénario: Une échéance conserve la date et l'heure saisies après relecture
    Étant donné que je crée une échéance à une date et une heure données
    Quand le stockage local est relu
    Alors la date et l'heure restituées sont exactement celles qui ont été saisies
    Et aucune conversion de fuseau ne les a décalées

  Scénario: La date persistée ne porte ni fuseau ni décalage horaire
    Étant donné qu'une échéance est enregistrée dans le stockage local
    Quand j'examine la valeur persistée de sa date d'échéance
    Alors elle exprime une date et une heure civiles
    Et elle ne porte ni fuseau, ni décalage horaire, ni marque de temps universel

  # ---------------------------------------------------------------------------
  # AC-15 — Sobriété et accessibilité de la page de gestion (RNF-03, RNF-06)
  # ---------------------------------------------------------------------------

  Scénario: Les champs du formulaire portent un libellé annoncé par le lecteur d'écran
    Étant donné que le formulaire de création est ouvert
    Quand j'active le lecteur d'écran sur le formulaire
    Alors chaque champ annonce son libellé et son caractère obligatoire ou optionnel
    Et le message de validation affiché est lui aussi annoncé

  Scénario: Un message de validation reste sobre et sans élément anxiogène
    Étant donné qu'une création est refusée parce que la date est passée
    Quand le message de validation est affiché
    Alors il utilise la couleur d'erreur du design system et reste lisible
    Et aucun badge, compteur, alerte animée ni élément de gamification n'apparaît

  # ---------------------------------------------------------------------------
  # AC-16 — Refus d'une date ou d'une heure civile qui n'existe pas (RNF-04 ; règle V-1 de
  #         docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md §6). ⚖️ Créé le 2026-08-06.
  #         FAIT MESURÉ par @DataEngineer, rejoué et confirmé par @Architect :
  #           DateTime.parse("2026-02-31T23:59") NE LÈVE PAS et rend 2026-03-03T23:59.
  #         ⇒ Une exception n'est PAS une barrière ; la barrière est la comparaison à la FORME
  #         CANONIQUE. Sans refus à la SAISIE, l'application écrit une valeur qu'elle refusera de
  #         relire (résidu, AC-11) ⇒ L'ÉCHÉANCE DISPARAÎT SANS MESSAGE. C'est cette conséquence
  #         utilisateur qui fait l'AC, pas la subtilité de l'analyseur syntaxique.
  #         ⛔ AUCUNE DATE DE CALENDRIER EN DUR (R-13) : « le 31 février de l'année prochaine » se
  #         dérive de l'horloge injectée et ne devient jamais passé. Le 31 février VISÉ est dans le
  #         futur ⇒ le refus ne peut pas être imputé à AC-4, et le 28 février de la même année est
  #         l'AUTRE CÔTÉ de la borne — sans lui, la règle serait satisfaite par un refus systématique.
  # ---------------------------------------------------------------------------

  Scénario: Une date qui n'existe pas au calendrier est refusée sans correction silencieuse
    Étant donné que le formulaire de création est ouvert
    Quand je valide le formulaire avec une description valide et la date du 31 février de l'année prochaine
    Alors la création est refusée par un message explicite désignant la date
    Et le stockage local ne contient aucune échéance
    Et la même création avec la date du 28 février de l'année prochaine est acceptée

  Scénario: Une édition vers une date qui n'existe pas au calendrier est refusée
    Étant donné qu'une échéance active existe avec sa date d'origine
    Quand je modifie sa date pour le 31 février de l'année prochaine et que je valide
    Alors la modification est refusée par un message explicite désignant la date
    Et l'échéance conserve sa date d'origine dans le stockage local

  # ⚠️ L'HEURE CIVILE INEXISTANTE du passage à l'heure d'été (02:30 le jour du saut de printemps)
  #    relève de LA MÊME RÈGLE et de la MÊME clause (AC-16 « Limite »), mais elle N'A PAS DE
  #    SCÉNARIO — délibérément : le fuseau du processus Dart n'est pas pilotable depuis un test
  #    (même cause que NM-5) et un hôte sous TZ=UTC N'A AUCUNE transition ⇒ le scénario y serait
  #    VRAI QUOI QU'IL ARRIVE, soit exactement l'un des 2 faux verts d'US-01.1.
  #    ⇒ Borne déclarée NM-9 dans le Story File. Ce qui est mesuré à la place : le MÊME prédicat de
  #    forme canonique, en UN SEUL EXEMPLAIRE (règle V-2), éprouvé en test unitaire de la validation.

  # ---------------------------------------------------------------------------
  # AC-17 — Échec d'écriture dans le stockage local (RNF-01). ⚖️ Créé le 2026-08-06 sur la lacune
  #         NOMMÉE par @UXDesigner (§10.5 du Design UX) : « l'échec d'écriture n'a aucun AC, aucun
  #         scénario, aucune surface ». Il a REFUSÉ d'inventer l'AC — la valeur métier est au @PO.
  #         Le magasin de plateforme non-`dart:io` LÈVE par conception (« jamais un échec
  #         silencieux ») ; un disque plein ou un droit refusé produit la même chose sur l'appareil.
  #         RÈGLE MÉTIER TRANCHÉE : ce qui est AFFICHÉ correspond TOUJOURS à ce qui est SUR LE
  #         DISQUE — ⛔ jamais un écran qui laisse croire à un enregistrement qui n'a pas eu lieu.
  #         ⚠️ Provoquer l'échec dans un E2E doit se faire SANS MAGASIN FACTICE (ADR-010 §1,
  #         contrôlé par check_e2e_persistance.py). Le COMMENT appartient à @Architect ; le @PO ne
  #         prescrit que le comportement observable.
  # ---------------------------------------------------------------------------

  Scénario: Un échec d'écriture est annoncé et rien n'est enregistré
    Étant donné que le stockage local ne peut pas être écrit
    Quand je crée une échéance valide
    Alors un message sobre indique que l'enregistrement n'a pas eu lieu
    Et aucune échéance n'est listée dans la page de gestion ni affichée sur la grille
    Et aucune trace technique ni aucun code d'erreur n'est affiché

  Scénario: Après un échec d'écriture la saisie est conservée et la nouvelle tentative aboutit
    Étant donné qu'une création vient d'échouer parce que le stockage local ne peut pas être écrit
    Alors le formulaire est toujours ouvert et porte encore la description et la date saisies
    Quand le stockage local redevient inscriptible et que je valide de nouveau
    Alors l'échéance est enregistrée sans que j'aie eu à ressaisir la description ni la date

  Scénario: Une suppression qui ne peut pas être écrite laisse l'échéance en place
    Étant donné qu'une échéance est listée et que le stockage local ne peut pas être écrit
    Quand je demande sa suppression et que je confirme
    Alors un message sobre indique que la suppression n'a pas eu lieu
    Et l'échéance est toujours listée, toujours sur la grille et toujours dans le stockage local
