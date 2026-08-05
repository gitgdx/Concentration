# language: fr
# US-01.1 — Affichage Hub & grille d'échéances (EPIC_01)
# Périmètre : affichage / lecture, à partir de données d'exemple injectées.
# US-01.1 embarque le calcul du nombre (unité adaptative : ceil, RF-02/03).
# ⛔ PÉRIMÉ-2026-08-04 : cette ligne portait « Les données réelles et les interactions mutantes
#    (double tap, CRUD) relèvent de US-01.2. » — FAUX depuis le découpage arbitré du 2026-08-03.
#    Exact : les données réelles et le CRUD relèvent d'US-01.2 ; le GESTE DOUBLE TAP relève d'US-01.4.
#
# ⚖️ AMENDEMENT DU 2026-08-04, décision humaine — 1 ÉTAPE bornée, 0 TITRE touché.
#    L'étape « les autres commandes de la barre de navigation basse sont non-interactives » du
#    scénario « Les modules futurs sont visibles, grisés et non-interactifs » est désormais bornée
#    « au périmètre d'US-01.1 » : US-01.2 (AC-1) active la commande « Gérer les échéances ».
#    ⛔ AUCUN titre de scénario n'est modifié : la correspondance 13 ↔ 13 par TITRE de
#    scripts/check_gherkin_mapping.py (job REQUIS Governance) en dépend.
#    ⚠️ Cet amendement PÉRIME le verdict QA d'US-01.1 et ses visas d'audit — c'est écrit et assumé
#    dans docs/stories/US-01.2-gestion-echeances.md, §Effet de bord sur US-01.1.

Fonctionnalité: Affichage du Hub de pratiques et de la grille d'échéances
  En tant que pratiquant régulier d'exercices de recentrage
  Je veux voir immédiatement mes échéances sous forme de tuiles épurées
  Afin d'ancrer ma revue mentale du temps restant d'un seul regard, sans effort de calcul

  Scénario: Le hub affiche le module Échéances actif avec sa grille
    Étant donné que des échéances d'exemple sont injectées dans l'application
    Quand j'ouvre l'application
    Alors le hub de pratiques est affiché en mode sombre de référence
    Et le module "Échéances" est actif et présente sa grille de tuiles

  Scénario: Les modules futurs sont visibles, grisés et non-interactifs
    Étant donné que le hub de pratiques est affiché
    Quand j'observe les entrées de pratique
    Alors les modules "Respiration" et "Concentration" sont visibles mais grisés
    Et toucher un module grisé ne déclenche aucune navigation ni action
    # ⛔ PÉRIMÉ-2026-08-04 — l'étape suivante portait, SANS BORNE : « Et les autres commandes de la
    #    barre de navigation basse sont non-interactives ». AMENDÉE (décision humaine du 2026-08-04),
    #    non repeinte : elle était PLUS ABSOLUE QUE L'AC QU'ELLE SERT — l'AC-2 « Limite » d'US-01.1
    #    dit déjà « leur activation relève d'US ultérieures ». US-01.2 (AC-1) active la commande
    #    « Gérer les échéances », qui ouvre la page de gestion.
    #    ⛔ On corrige le DÉFAUT (une étape non bornée), pas le renvoi : laissée absolue, elle
    #    redeviendrait fausse à chaque US qui active une commande. Leçon US-00.7.
    #    ⚠️ Conséquence assumée : cet amendement PÉRIME le verdict QA d'US-01.1 (voir le Story File
    #    d'US-01.2, §Effet de bord sur US-01.1).
    Et les autres commandes de la barre de navigation basse sont non-interactives au périmètre d'US-01.1

  Scénario: Affichage d'une tuile par échéance active
    Étant donné que 4 échéances actives sont injectées
    Quand la grille d'échéances est affichée
    Alors exactement 4 tuiles sont affichées
    Et chaque tuile porte la description de son échéance

  Scénario: La tuile affiche un nombre nu, sans unité
    Étant donné qu'une échéance active est injectée
    Quand la tuile correspondante est affichée
    Alors la tuile affiche un unique nombre entier en typographie dominante
    Et aucune unité, fraction, signe ni texte parasite n'est affiché sur la tuile

  Scénario: Le nombre affiché est l'arrondi supérieur dans l'unité adaptative
    Étant donné qu'une échéance est atteinte dans 8 mois et 12 jours
    Quand la tuile correspondante est affichée
    Alors le nombre affiché est "9"

  Scénario: Couleur orange quand le nombre vient de changer
    Étant donné qu'une échéance vient de faire changer son nombre affiché
    Et qu'elle est donc loin du prochain changement de nombre
    Quand la tuile correspondante est affichée
    Alors la couleur de fond de la tuile est orange

  Scénario: Couleur bleue quand le prochain changement est imminent
    Étant donné qu'une échéance est proche de son prochain changement de nombre
    Quand la tuile correspondante est affichée
    Alors la couleur de fond de la tuile est bleue

  Scénario: Tri des tuiles par échéance croissante
    Étant donné que plusieurs échéances actives de dates différentes sont injectées
    Quand la grille d'échéances est affichée
    Alors les tuiles sont ordonnées par date d'échéance croissante
    Et l'échéance la plus proche apparaît en premier

  Scénario: Une échéance dépassée remonte en tête de la grille
    Étant donné qu'une échéance est dépassée et que d'autres échéances actives sont injectées
    Quand la grille d'échéances est affichée
    Alors la tuile de l'échéance dépassée apparaît en tête de la grille
    Et les tuiles suivantes restent ordonnées par date d'échéance croissante

  Scénario: Affichage de 9 tuiles embrassable d'un regard
    Étant donné que 9 échéances actives sont injectées
    Quand la grille d'échéances est affichée
    Alors exactement 9 tuiles sont affichées
    Et la disposition reste lisible sans chevauchement ni défilement excessif

  Scénario: Une échéance atteinte reste affichée en état "à zéro"
    Étant donné qu'une échéance a atteint son terme
    Quand la grille d'échéances est affichée
    Alors sa tuile passe en état "à zéro" et n'affiche plus de compte à rebours
    Et la tuile reste présente à l'écran, en attente
    Et aucun geste de disparition n'est traité dans ce périmètre d'affichage

  Scénario: État vide quand aucune tuile n'est à afficher
    Étant donné qu'aucune échéance active n'est injectée
    Quand la grille d'échéances est affichée
    Alors un message sobre invitant à ajouter une échéance est affiché
    Et aucune couleur d'urgence, erreur technique ou élément de gamification n'apparaît

  Scénario: Le nombre reste lisible et le lecteur d'écran annonce le temps complet
    Étant donné qu'une tuile est affichée sur une couleur quelconque du dégradé orange-bleu
    Quand j'active le lecteur d'écran sur cette tuile
    Alors le nombre reste lisible avec un contraste conforme WCAG AA
    Et le lecteur d'écran annonce le temps restant complet avec son unité
