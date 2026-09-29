# language: fr
# US-01.4 — Gestes sur la tuile : révélation de la description et retrait d'une échue (RF-06)
# EPIC_01, track STANDARD.
#
# Périmètre : la TUILE et la GRILLE. Trois objets fusionnés par décision humaine du 2026-08-21 —
#   ① RF-06 : double appui qui fait DISPARAÎTRE une tuile échue (animation, état ÉCHUE RETIRÉE,
#     signalement en gestion, complément du message de la limite de 9) ;
#   ② révélation de la description au SIMPLE appui, 3 secondes, sur les tuiles ACTIVE ;
#   ③ le nombre est plus GROS et CENTRÉ sur les tuiles ACTIVE.
# Le moteur de temps restant (RF-02/03/04) est livré par US-01.1 et n'est PAS modifié ici.
# La persistance et l'état ÉCHU sont livrés par US-01.2 : US-01.2 introduit l'état, US-01.4 le geste.
#
# ⚖️ GATE CLARIFY FERMÉ LE 2026-08-21 — 10 arbitrages humains. Les deux verdicts à effet structurel :
#   nº 1 — LA RÉVÉLATION NE CONCERNE QUE LES TUILES ACTIVE. Une tuile ACTIVE ne porte que l'appui
#     simple (révélation IMMÉDIATE, aucun délai de discrimination de double appui) ; une tuile ÉCHUE
#     ne porte que le DOUBLE appui (aucun clignotement) et CONSERVE SA DESCRIPTION AFFICHÉE EN
#     PERMANENCE — son « 0 » n'a rien à dire, la description est ce qui l'identifie.
#     ⇒ Le scénario hérité d'US-01.2 « aucun effet d'un appui simple ou prolongé » reste
#       LITTÉRALEMENT VRAI : il n'est PAS amendé, il devient ici observable sous le titre
#       « Un appui simple sur une tuile échue ne retire rien et ne révèle rien ».
#     ⇒ Conséquence appliquée aux titres : les scénarios de repos et de description vide NOMMENT la
#       tuile ACTIVE. Sans cela ils seraient FAUX pour les échues.
#   nº 2 — 3 secondes + ré-appui illimité, et l'ÉCART À WCAG 2.2.1 (« Timing Adjustable », niveau A)
#     est DÉCLARÉ, daté et motivé dans le Story File. ⛔ NE PAS écrire ici ni ailleurs que ce point
#     est conforme : le ré-appui n'est aucune des exceptions littérales du SC.
#
# ⚖️ UN AC AJOUTÉ PAR DÉCISION HUMAINE LE 2026-08-22 — AC-11, ses 4 scénarios sont EN FIN DE FICHIER.
#    Objet : UN RETRAIT DONT L'ÉCRITURE ÉCHOUE. Lacune de SPÉCIFICATION nommée et MESURÉE par
#    @Architect au gate `analyze` (§A-1 / R-6 du Story File), qui a REFUSÉ de l'écrire — c'était le
#    bon geste : c'est une décision de valeur métier. Précédent identique : AC-17 d'US-01.2, né du
#    même refus de la part de @UXDesigner (point U-4).
#    Trois faits mesurés qui la rendaient invisible :
#      - AC-17 d'US-01.2 énumère TROIS actes (création, édition, suppression) ; le retrait est un
#        QUATRIÈME et n'y est pas nommé — seule sa règle générale le couvre : « ce qui est AFFICHÉ
#        correspond TOUJOURS à ce qui est SUR LE DISQUE » ;
#      - `ActeEcriture` ne porte que DEUX textes, alors que son propre motif exige « deux textes, pas
#        un — l'utilisateur doit savoir CE QUI n'a pas eu lieu » (réutiliser un texte reproduirait le
#        bloquant NB-B) ;
#      - le hub n'a AUCUNE surface de message (`MessageValidation` n'est monté que par la page de
#        gestion) ⇒ le geste le plus fréquent de cette US était le seul acte d'écriture du produit
#        sans aucun moyen de dire qu'il a échoué.
#    ⛔ LE TEXTE DU MESSAGE ET SA SURFACE NE SONT PAS ÉCRITS ICI : ils sont dus à @UXDesigner
#      (entrées U-1 et U-2 du Story File), et `parallel_design` n'a pas commencé. Les scénarios
#      assèrent donc QU'UN MESSAGE EST PRÉSENT et CE QU'IL NE FAIT PAS — ⛔ jamais une chaîne
#      inventée, qui serait fausse dès que le vrai texte arrivera.
#    ⚠️ ET CET AC ARRIVE APRÈS `EVT_STORY_READY` (émis le 2026-08-21) : ⛔ aucun événement du
#      catalogue ne modélise un changement de périmètre, ⛔ aucun n'a été détourné. La décision vit
#      dans le corpus durable (Métadonnées, AC-11, DoD). ➡️ /audit-methodo.
#
# ⚠️ CE FICHIER EST NORMATIF. En cas de divergence avec un résumé en prose (Story File, SCB,
#    PROJECT_LOG), c'est LUI qui fait foi. Défaut réel d'US-01.1 : 13 scénarios et 13 lignes de
#    résumé divergeaient par 5 titres.
#
# ⚠️ CORRESPONDANCE 1:1 ET BLOQUANTE. `scripts/check_gherkin_mapping.py` (job requis
#    « 📋 Governance ») exige qu'un test porte VERBATIM le titre de chaque scénario, et signale
#    l'écart dans les DEUX sens. Conséquences assumées :
#      1. un titre est STABLE et UNIQUE — le renommer casse le gate ;
#      2. AUCUN scénario n'est écrit pour une clause non mesurable avec l'outillage actuel : elle
#         serait « scénario sans test » par construction, donc gate ROUGE. Ces clauses sont listées
#         au §« Clauses non mesurables en l'état » du Story File (bornes NM-3, NM-11, NM-12, NM-13),
#         jamais déguisées en scénario ;
#      3. le couple (.feature, fichier de tests) ne s'enregistre dans `COUPLES` qu'une fois les
#         tests écrits — l'enregistrer plus tôt rend le job requis rouge (ordonnancement @Architect).
#
# ⛔ AUCUN TOTAL DE SCÉNARIOS N'EST ÉCRIT DANS CE FICHIER NI DANS LE STORY FILE (défaut ⑤ : en
#    US-01.2, le même nombre dérivé vivait en 23 exemplaires). Il se LIT :
#      grep -c "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature
#      grep    "^  Scénario: " tests/features/US-01.4-gestes-tuile.feature | sort | uniq -d
#    La seconde commande doit rendre une sortie VIDE : un titre en double casse le gate de mapping.
#
# ℹ️ Plusieurs titres portent une apostrophe — côté Dart, utiliser une chaîne à guillemets doubles
#    (`testWidgets("L'échéance retirée …")`). AUCUN titre ne contient de guillemet, précisément pour
#    cela.
#
# Vocabulaire (prolonge celui d'US-01.1 et d'US-01.2, sans en changer un mot) :
#   - ACTIVE         : temps restant > 0, tuile affichant son nombre ;
#   - ÉCHUE          : temps restant <= 0, tuile « à zéro », PRÉSENTE sur la grille ;
#   - ÉCHUE RETIRÉE  : tuile ABSENTE de la grille, échéance CONSERVÉE et consultable en gestion
#                      (état INTRODUIT par cette US) ;
#   - SUPPRIMÉE      : détruite après confirmation explicite — SEUL acte destructif du produit.
#   ⇒ « présentes sur la grille » = ACTIVE + ÉCHUE : c'est CE décompte que borne la limite de 9
#     (RF-15, arbitrage du 2026-08-03). Une ÉCHUE RETIRÉE n'est PAS présente : elle ne compte plus,
#     et c'est ce qui fait de « faire disparaître » une issue RÉELLE à la limite.
#
# ⛔ AUCUNE DATE DE CALENDRIER EN DUR : uniquement des durées relatives et une horloge injectée.
#    Une date en dur devient passée avec le temps et ferait pourrir les tests EN SILENCE (R-13).
# ⛔ LA PÉRIODE DE RAFRAÎCHISSEMENT NE S'ÉCRIT PAS ICI : elle se lit dans
#    `ConcentrationTokens.periodeRafraichissement`. Les scénarios disent « un rafraîchissement se
#    produit », ce qui reste vrai si la période change.
# ⛔ L'UNITÉ DE TEMPS NE S'ÉCRIT JAMAIS VISUELLEMENT (RF-01) : elle n'existe que dans le libellé
#    d'accessibilité.

Fonctionnalité: Gestes sur la tuile — révélation de la description et retrait d'une échéance échue

  Scénario: Au repos la tuile active affiche son nombre seul et centré
    Étant donné qu'une échéance active portant une description est enregistrée
    Quand la grille d'échéances est affichée
    Alors le nombre est le seul élément visible de la tuile
    Et le nombre est centré horizontalement et verticalement dans la tuile
    Et la taille du nombre est strictement supérieure à celle livrée par US-01.1

  Scénario: Au repos la description n'est pas affichée sur la tuile active
    Étant donné qu'une échéance active portant une description est enregistrée
    Quand la grille d'échéances est affichée
    Alors la description n'est pas affichée sur la tuile
    Et aucune unité, fraction, signe ni texte parasite n'est affiché sur la tuile

  Scénario: Une tuile échue conserve sa description affichée en permanence
    Étant donné qu'une échéance est échue depuis deux jours
    Quand la grille d'échéances est affichée
    Alors la tuile échue affiche sa description
    Et aucun geste n'est nécessaire pour lire cette description

  Scénario: Le libellé d'accessibilité de la tuile contient toujours la description
    Étant donné qu'une échéance active portant une description est enregistrée
    Quand la grille d'échéances est affichée
    Alors le libellé annoncé pour la tuile contient le temps restant avec son unité
    Et ce libellé contient la description de l'échéance

  Scénario: Neuf tuiles au nombre agrandi ne débordent pas à deux fois la taille de police système
    Étant donné que neuf échéances actives sont enregistrées
    Et que la taille de police système est doublée
    Quand la grille d'échéances est affichée
    Alors chaque nombre est affiché en entier, sans troncature ni ellipse
    Et aucune tuile ne déborde de la grille

  Scénario: Un appui simple remplace le nombre par la description
    Étant donné qu'une échéance active portant une description est affichée
    Quand j'appuie une fois sur sa tuile
    Alors la description est affichée à la place du nombre
    Et la description est affichée sans attendre

  Scénario: Le nombre revient au bout de trois secondes
    Étant donné que j'ai appuyé une fois sur la tuile d'une échéance active
    Quand trois secondes s'écoulent sans autre geste
    Alors le nombre est de nouveau affiché à la place de la description
    Et le nombre affiché est celui du calcul courant

  Scénario: Appuyer une seconde tuile referme la première révélation
    Étant donné que deux échéances actives portant une description sont affichées
    Et que j'ai appuyé une fois sur la première tuile
    Quand j'appuie une fois sur la seconde tuile
    Alors la seconde tuile affiche sa description
    Et la première tuile affiche de nouveau son nombre

  Scénario: Un rafraîchissement de la grille n'interrompt pas la révélation
    Étant donné que j'ai appuyé une fois sur la tuile d'une échéance active
    Quand un rafraîchissement de la grille se produit pendant la révélation
    Alors la description est toujours affichée
    Et le nombre revient à l'échéance des trois secondes initiales

  Scénario: Un nouvel appui pendant la révélation redémarre les trois secondes
    Étant donné que j'ai appuyé une fois sur la tuile d'une échéance active
    Quand j'appuie de nouveau sur cette tuile avant la fin des trois secondes
    Alors la description est encore affichée trois secondes après ce nouvel appui
    Et le nombre revient ensuite

  Scénario: Une tuile active sans description n'annonce aucune révélation
    Étant donné qu'une échéance active a une description vide
    Quand la grille d'échéances est affichée
    Alors sa tuile affiche son nombre
    Et sa tuile n'est pas annoncée comme révélant une description
    Et sa tuile ne porte aucun gestionnaire d'appui

  Scénario: Un appui sur une tuile active sans description ne fait rien apparaître
    Étant donné qu'une échéance active a une description vide
    Quand j'appuie une fois sur sa tuile
    Alors son nombre reste affiché
    Et aucun texte de substitution n'est affiché sur la tuile

  Scénario: Une tuile échue sans description reste retirable
    Étant donné qu'une échéance échue a une description vide
    Quand je double-appuie sur sa tuile
    Alors la tuile est absente de la grille
    Et l'échéance est conservée dans le stockage local

  Scénario: Un double appui fait disparaître une tuile échue
    Étant donné qu'une échéance est échue depuis deux jours
    Quand je double-appuie sur sa tuile
    Alors une animation de disparition se joue
    Et la tuile est absente de la grille
    Et la grille se recompose sans laisser de trou

  Scénario: L'échéance retirée reste consultable dans la page de gestion
    Étant donné qu'une échéance échue a été retirée de la grille par un double appui
    Quand j'ouvre la page de gestion
    Alors l'échéance est listée dans le groupe des échues
    Et sa description, sa date et son heure sont inchangées

  # ─── ⚖️ TITRE AMENDÉ ET BORNÉ LE 2026-09-08 (@PO) — le scénario, ses TROIS clauses et l'AC qu'il
  # sert (AC-4 « Erreur », 1ʳᵉ phrase) sont INCHANGÉS : seul le TITRE l'est.
  #   PÉRIMÉ-2026-09-08 : « Un double appui sur une tuile active ne produit aucun effet »
  # ⛔ Ancienne formulation conservée ci-dessus en LITTÉRAL, jamais barrée — `~~texte~~` est
  #   invisible à `grep` (leçon d'US-00.7).
  # 🔴 MOTIF MESURÉ, ⛔ pas relu — sonde jetable hors dépôt (patron ADR-010), rejouée :
  #   `ACTIVE_double_appui activations=2`. Sur une tuile ACTIVE, un double appui est reçu comme DEUX
  #   APPUIS SIMPLES (`echeance_tile.dart` porte `onTap: temps.estEchue ? null : activer`, donc
  #   CHAQUE appui appelle `activer`) ⇒ l'effet est DEUX RÉVÉLATIONS, la fenêtre de 3 s redémarrant
  #   au second appui (AC-2 « Limite »). « Aucun effet » affirmait PLUS que le produit ne fait.
  # ✅ POURQUOI CE N'ÉTAIT PAS UN FAUX VERT : les trois clauses portent toutes sur le RETRAIT et
  #   l'ÉCRITURE — la tuile reste, aucune animation, rien d'écrit — elles étaient et restent VRAIES,
  #   et le test apparié les borne déjà (octets identiques, `retiree` faux). SEUL LE TITRE MENTAIT,
  #   comme le `.feature` d'US-01.1 était « plus absolu que l'AC qu'il servait » (amendé pareil, T13).
  # ⚠️ AUCUN GATE NE POUVAIT LE VOIR : `check_gherkin_mapping.py` compare des TITRES, pas de la
  #   sémantique — il l'imprime lui-même. Laissé tel quel, ce faux survivait à la certification.
  Scénario: Un double appui sur une tuile active ne retire rien et n'écrit rien
    Étant donné qu'une échéance active est affichée
    Quand je double-appuie sur sa tuile
    Alors la tuile est toujours affichée
    Et aucune animation de disparition ne se joue
    Et rien n'est écrit dans le stockage local

  Scénario: Un appui simple sur une tuile échue ne retire rien et ne révèle rien
    Étant donné qu'une échéance est échue depuis deux jours
    Quand j'appuie une seule fois sur sa tuile
    Alors la tuile est toujours affichée
    Et aucune description n'est révélée à la place de son nombre
    Et rien n'est écrit dans le stockage local

  # ─── ⚖️ TITRE AMENDÉ ET BORNÉ LE 2026-09-08 (@PO) — 2ᵉ occurrence du MÊME défaut, dans le MÊME
  # fichier et le même jour : les DEUX clauses sont INCHANGÉES, seul le TITRE l'est.
  #   PÉRIMÉ-2026-09-08 : « Un appui prolongé sur une tuile ne produit aucun effet »
  # ⛔ Ancienne formulation conservée ci-dessus en LITTÉRAL, jamais barrée (`~~texte~~` est
  #   invisible à `grep`).
  # 🔴 MOTIF MESURÉ — sonde jetable jouée puis SUPPRIMÉE, suppression VÉRIFIÉE (patron ADR-010,
  #   leçon de T10) : `EcheancesGrid` montée avec UNE SEULE tuile ACTIVE portant une description,
  #   `tester.longPress`, un `pump` ⇒
  #     `SONDE|description_avant=false|description_apres=true|nombre_apres=false`
  #   ⇒ un appui PROLONGÉ sur une ACTIVE RÉVÈLE la description, et le NOMBRE DISPARAÎT.
  #   `TapGestureRecognizer` gagne l'arène au relâchement, et `onTap` est NON NUL sur une ACTIVE
  #   (`onTap: temps.estEchue ? null : activer`) : c'est le MÊME chemin que l'appui simple d'AC-2.
  # ✅ PAS UN FAUX VERT NON PLUS : les deux clauses portent sur le RETRAIT et l'ÉCRITURE — les deux
  #   tuiles restent, rien n'est écrit — et le test apparié n'a JAMAIS prétendu qu'aucune révélation
  #   n'avait lieu (il asserte les octets INCHANGÉS). SEUL LE TITRE MENTAIT.
  # ⚖️ ⛔ CE CAS N'EST PAS CELUI DU DOUBLE APPUI CI-DESSUS, ET LA DIFFÉRENCE COMPTE : là, la clause
  #   EXISTAIT et son libellé était trop ABSOLU (défaut de LIBELLÉ) ; ici la clause MANQUAIT —
  #   AC-4 « Erreur » ne scopait l'appui prolongé qu'aux tuiles ÉCHUE, donc AUCUN AC ne disait ce
  #   qu'un appui long fait sur une ACTIVE, alors que ce titre l'affirmait. LACUNE DE SPÉCIFICATION
  #   (famille d'U-4 en US-01.2 et d'AC-11 ici), ⛔ JAMAIS rangeable dans les « clauses non
  #   mesurables » : elle était mesurable — la sonde vient de la mesurer — c'est la DÉCISION qui
  #   manquait. Tranchée le 2026-09-08 dans AC-4 « Erreur » : la révélation sur appui long est
  #   ACCEPTÉE, ⛔ pas corrigée, et son motif est qu'un appui LENT ne doit pas être puni.
  Scénario: Un appui prolongé ne retire aucune tuile et n'écrit rien
    Étant donné qu'une échéance active et une échéance échue sont affichées
    Quand j'appuie longuement sur chacune des deux tuiles
    Alors les deux tuiles sont toujours affichées
    Et rien n'est écrit dans le stockage local

  Scénario: Le retrait ne demande aucune confirmation
    Étant donné qu'une échéance est échue depuis deux jours
    Quand je double-appuie sur sa tuile
    Alors aucune demande de confirmation n'est affichée
    Et l'échéance n'est pas supprimée du stockage local

  Scénario: Une échéance retirée ne revient pas sur la grille après réouverture
    Étant donné qu'une échéance échue a été retirée de la grille par un double appui
    Quand l'application est rouverte
    Alors sa tuile n'est pas sur la grille
    Et l'échéance est toujours listée dans la page de gestion

  Scénario: Les échéances enregistrées par la version antérieure restent présentes sur la grille
    Étant donné un stockage local écrit par la version antérieure du schéma, contenant deux échéances actives et une échéance échue
    Quand l'application est ouverte
    Alors trois tuiles sont affichées
    Et aucune échéance n'a été retirée de la grille sans geste de l'utilisateur

  Scénario: Une échéance retirée reste supprimable définitivement en gestion
    Étant donné qu'une échéance échue a été retirée de la grille par un double appui
    Quand je la supprime depuis la page de gestion et que je confirme
    Alors elle n'est plus listée dans la page de gestion
    Et elle ne réapparaît pas après réouverture de l'application

  Scénario: Retirer une échue libère une place sur la grille
    Étant donné huit échéances actives et une échéance échue présentes sur la grille
    Et que la création d'une dixième échéance vient d'être refusée
    Quand je retire l'échéance échue par un double appui
    Et que je crée une nouvelle échéance
    Alors la création aboutit
    Et la nouvelle échéance apparaît sur la grille sans redémarrage

  Scénario: Le message de la dixième tentative annonce le retrait quand une échue est sur la grille
    Étant donné neuf échéances présentes sur la grille dont une échue
    Quand je tente de créer une dixième échéance
    Alors la création est refusée
    Et le message nomme la limite de neuf
    Et le message annonce le retrait d'une échue et la suppression
    Et le stockage local contient toujours neuf échéances

  Scénario: Le message de la dixième tentative n'annonce que la suppression sans échue sur la grille
    Étant donné neuf échéances actives présentes sur la grille
    Quand je tente de créer une dixième échéance
    Alors la création est refusée
    Et le message nomme la limite de neuf
    Et le message annonce la suppression comme seule issue
    Et le message n'annonce pas le retrait d'une échue

  Scénario: Une échue encore sur la grille est signalée dans la page de gestion
    Étant donné une échéance échue présente sur la grille et une échéance échue retirée
    Quand j'ouvre la page de gestion
    Alors les deux échéances sont listées dans le groupe des échues
    Et celle qui est encore sur la grille est signalée comme occupant une place
    Et le groupe des échues reste ordonné de la plus récemment échue à la plus ancienne

  Scénario: Le signalement d'une échue ne repose pas sur la couleur seule
    Étant donné une échéance échue présente sur la grille et une échéance échue retirée
    Quand j'ouvre la page de gestion
    Alors le signalement porte un mot ou une forme
    Et le signalement est annoncé par le lecteur d'écran

  Scénario: La disparition passe par une animation avant que la tuile ne quitte la grille
    Étant donné qu'une échéance est échue depuis deux jours
    Quand je double-appuie sur sa tuile
    Alors la tuile est encore présente pendant l'animation
    Et la tuile quitte la grille à la fin de l'animation

  Scénario: Le retrait aboutit même quand les animations système sont réduites
    Étant donné que le système demande de réduire les animations
    Et qu'une échéance est échue depuis deux jours
    Quand je double-appuie sur sa tuile
    Alors la tuile quitte la grille immédiatement
    Et l'échéance est retirée dans le stockage local exactement comme avec l'animation

  Scénario: Un second double appui pendant l'animation ne retire rien d'autre
    Étant donné que l'animation de disparition d'une tuile échue est en cours
    Quand je double-appuie de nouveau au même endroit
    Alors aucune autre échéance n'est retirée
    Et aucune erreur n'est affichée

  Scénario: Une tuile interactive est annoncée actionnable avec son temps restant complet
    Étant donné qu'une échéance active portant une description est enregistrée
    Quand la grille d'échéances est affichée
    Alors la tuile est annoncée comme actionnable
    Et son nom contient le temps restant, son unité et la description
    Et l'action disponible sur la tuile est annoncée

  Scénario: Les modules grisés et Réglages restent sans gestionnaire de geste
    Étant donné que le hub est affiché avec sa grille d'échéances
    Quand j'examine les commandes de la barre de navigation basse et les modules grisés
    Alors les modules Respiration et Concentration ne portent aucun gestionnaire de geste
    Et la commande Réglages ne porte aucun gestionnaire de geste

  Scénario: Chaque tuile est atteignable au clavier avec un focus visible
    Étant donné que trois échéances actives sont affichées
    Quand je parcours l'écran au clavier
    Alors chaque tuile reçoit le focus dans l'ordre de la grille
    Et la tuile focalisée porte un focus visible

  Scénario: À neuf tuiles chaque cible tactile atteint quarante-huit points
    Étant donné neuf échéances présentes sur la grille
    Et un écran de trois cent vingt points de large
    Quand la grille d'échéances est affichée
    Alors chaque tuile mesure au moins quarante-huit points de côté

  Scénario: Un appui simple ne change ni la couleur ni l'ordre des tuiles
    Étant donné que trois échéances actives sont affichées
    Quand j'appuie une fois sur la tuile du milieu
    Alors la couleur de fond de cette tuile est inchangée
    Et l'ordre des tuiles est inchangé

  Scénario: Le rafraîchissement continue après un geste sur une tuile
    Étant donné qu'une échéance active dont le nombre change dans une heure est affichée
    Et que j'ai appuyé une fois sur sa tuile puis que la révélation s'est terminée
    Quand le temps s'écoule jusqu'au changement de nombre
    Alors le nombre affiché est celui du nouveau calcul

  Scénario: Retirer la dernière tuile conduit à l'état vide sobre
    Étant donné une seule échéance, échue, présente sur la grille
    Quand je la retire par un double appui
    Alors l'état vide sobre est affiché
    Et aucune erreur technique n'est affichée

  # ─── AC-11 — un retrait dont l'ÉCRITURE ÉCHOUE (⚖️ ajouté le 2026-08-22).
  # Mode de défaillance INVERSE de celui d'AC-17 d'US-01.2 : là-bas une donnée saisie disparaissait,
  # ici une tuile retirée REVIENT. La règle est la même : l'affiché ÉGALE le disque.
  Scénario: Un retrait qui ne peut pas être écrit est annoncé et la tuile reste
    Étant donné qu'une échéance est échue depuis deux jours
    Et que le stockage local ne peut pas être écrit
    Quand je double-appuie sur sa tuile
    Alors un message indique que le retrait n'a pas eu lieu
    Et la tuile est toujours présente sur la grille, à sa place dans le tri
    Et aucune trace technique ni code d'erreur n'est affiché
    Et l'application reste utilisable

  Scénario: Un retrait qui ne peut pas être écrit ne joue aucune animation de disparition
    Étant donné qu'une échéance est échue depuis deux jours
    Et que le stockage local ne peut pas être écrit
    Quand je double-appuie sur sa tuile
    Alors aucune animation de disparition ne se joue
    Et la tuile ne quitte à aucun moment la grille

  Scénario: Une échue dont le retrait a échoué compte toujours dans la limite de neuf
    Étant donné huit échéances actives et une échéance échue présentes sur la grille
    Et que le stockage local ne peut pas être écrit
    Quand je double-appuie sur la tuile de l'échéance échue
    Et que je tente de créer une nouvelle échéance
    Alors la création est refusée
    Et le stockage local contient toujours neuf échéances

  Scénario: Après un échec de retrait le geste réessayé aboutit
    Étant donné qu'une échéance est échue depuis deux jours
    Et que le stockage local ne peut pas être écrit
    Et que j'ai double-appuyé sur sa tuile sans que le retrait ait lieu
    Quand le stockage local redevient inscriptible
    Et que je double-appuie de nouveau sur sa tuile
    Alors la tuile est absente de la grille
    Et l'échéance est conservée dans le stockage local
