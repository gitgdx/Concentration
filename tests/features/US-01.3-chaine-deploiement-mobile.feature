# language: fr
# US-01.3 — Chaîne de déploiement mobile réelle (Android)
# EPIC_01, track FULL.
#
# Périmètre : rendre « 🚀 DEPLOYED » SIGNIFIANT pour ce produit — une application SANS SERVEUR,
# distribuée par installation directe sur un appareil réel. Aucun écran nouveau, aucune règle
# métier de l'exercice n'est modifiée ici.
#
# ⚖️ ARBITRAGES HUMAINS DU 2026-09-29 (non re-litigables, détail et motifs dans le Story File) :
#   ① ANDROID SEUL. iOS est HORS PÉRIMÈTRE — borne nommée et datée (macOS indisponible, `ios/` non
#     scaffoldé). ⛔ RNF-08 reste PARTIELLEMENT OUVERT : aucun scénario ne l'affirme satisfait.
#   ② Canal de distribution = artefact de release SIGNÉ installé par `adb` sur l'appareil de
#     référence (SM T580, Android 8.1, API 27). ⛔ Ni Play Console, ni Firebase.
#   ③ Signature LOCALE uniquement : clé hors dépôt, sur la machine de l'humain ; la CI ne produit
#     qu'un artefact NON signé. ⛔ Aucun secret sur GitHub (dépôt PUBLIC).
#
# ⚠️ STATUT : SQUELETTE rédigé par @ProductOwner le 2026-09-29, gate clarify OUVERT.
#    ⛔ PÉRIMÉ-2026-09-29 : gate clarify ARBITRÉ par l'humain le même jour (verdicts dans le Story
#    File). Un scénario AC-9 « Limite » a été ajouté par @Architect après le verdict Q5. Mode
#    d'exécution tranché (Q1 (a)) : logique en CI sur sorties d'outils ENREGISTRÉES, exécution réelle
#    sur appareil = preuve datée — ADR-015 §10. ⛔ Le couple n'est PAS encore dans COUPLES.
#    Les titres sont la CLÉ de `check_gherkin_mapping.py` : stables, uniques, sans guillemet.
#    ⛔ Aucun total n'est écrit ici (défaut ⑤) : grep -c "^  Scénario: " sur ce fichier.
#    ⛔ Le seuil de RNF-02 n'est PAS écrit ici : il vit en UN SEUL exemplaire, dans le Story File
#    d'US-01.1, où l'instrument de mesure le lit.
#    ⚠️ Beaucoup de ces scénarios portent sur un APPAREIL : leur mode d'exécution (fixtures rejouées
#    en CI, preuve relevée sur appareil) est une décision de @Architect — Story File, gate clarify.
#    (⛔ PÉRIMÉ-2026-09-29 : décision prise, voir le STATUT ci-dessus.)
#
# ⚖️ ARBITRAGES HUMAINS DU 2026-09-30 (points A-1, A-2, A-5 du gate analyze), intégrés par @ProductOwner :
#   A-1 — « Les sauvegardes doivent rester locales » : AC-13 CRÉÉ, ses scénarios sont EN FIN DE FICHIER.
#     Règle NEUTRE vis-à-vis de la plateforme (R-SAUV) ; seule l'instanciation ANDROID est ici.
#     ⛔ iOS reste HORS PÉRIMÈTRE : transfert BT-1, aucun scénario n'affirme la règle tenue sur iOS.
#     Les deux scénarios de sa Limite s'excluent SELON LA PLATEFORME — ce n'est pas une contradiction.
#   A-2 — seule une EMPREINTE du numéro de série de l'appareil est publiée, jamais sa valeur (donnée C2,
#     dépôt public) : un scénario AC-1 ajouté, une étape ajoutée au premier scénario (titre inchangé).
#   A-5 — instanciation du verdict Q16 : la production est construite depuis un commit ancêtre de
#     origin/main ; deux scénarios AC-9 ajoutés (les deux côtés de la règle).
#   ⛔ Aucun numéro de série, aucune empreinte, aucun nom de compte n'est écrit dans ce fichier.

Fonctionnalité: Chaîne de déploiement mobile réelle — définir, produire, installer et vérifier une release Android

  # ── AC-1 : définition de « 🚀 DEPLOYED » ─────────────────────────────────────────────────────

  Scénario: Un artefact qui remplit toutes les conditions est déclaré déployé
    Étant donné qu'un artefact de release est signé par la clé de release
    Et que son numéro de version est strictement supérieur à celui du dernier déploiement
    Et qu'il est installé sur l'appareil de référence
    Et que le smoke test sur l'appareil de référence est passé
    Quand le déploiement est évalué
    Alors le déploiement est déclaré réussi
    Et la preuve nomme l'appareil, la version, le commit et l'empreinte de l'artefact
    Et l'appareil y est identifié par l'empreinte de son numéro de série

  # AC-1 « Nominal » — ajouté par @ProductOwner le 2026-09-30, arbitrage humain A-2.
  Scénario: Le numéro de série de l'appareil n'apparaît jamais en clair dans une preuve
    Étant donné qu'une preuve de déploiement a été produite sur l'appareil de référence
    Quand les fichiers versionnés du dépôt sont parcourus
    Alors le numéro de série de l'appareil n'y figure en clair nulle part
    Et deux preuves du même appareil portent la même empreinte de numéro de série

  Scénario: Un artefact auquel manque une seule condition n'est pas déclaré déployé
    Étant donné qu'un artefact de release remplit toutes les conditions sauf le smoke test
    Quand le déploiement est évalué
    Alors le déploiement n'est pas déclaré réussi
    Et la condition manquante est nommée

  Scénario: Une installation de développement ne vaut jamais un déploiement
    Étant donné qu'une version de développement signée par la clé de débogage tourne sur l'appareil de référence
    Quand le déploiement est évalué
    Alors le déploiement n'est pas déclaré réussi

  # ── AC-2 : build de release signé, reproductible localement ──────────────────────────────────

  Scénario: Le build de release signé se construit depuis un commit identifié
    Étant donné que la clé de release est disponible sur la machine de l'humain
    Et que l'arbre de travail est propre sur un commit poussé
    Quand le build de release signé est lancé en suivant la procédure documentée
    Alors un artefact de release signé est produit
    Et la preuve du build nomme le commit, la version et les versions de la chaîne d'outils

  Scénario: Un arbre de travail modifié empêche la construction de l'artefact de release
    Étant donné que l'arbre de travail contient une modification non committée
    Quand le build de release signé est lancé
    Alors le build est refusé avec un message qui nomme la cause
    Et aucun artefact de release n'est produit

  Scénario: Deux constructions du même commit portent la même version et le même certificat
    Étant donné qu'un artefact de release a été construit depuis un commit
    Quand le même commit est reconstruit depuis un clone propre sur la même machine
    Alors les deux artefacts portent la même version
    Et les deux artefacts portent la même empreinte de certificat de signature

  # ── AC-3 : refus explicite sans clé de release ──────────────────────────────────────────────

  Scénario: Sans fichier de propriétés de signature le build de release signé est refusé
    Étant donné que le fichier de propriétés de signature est absent
    Quand le build de release signé est lancé
    Alors le build échoue avec un message qui nomme le fichier manquant
    Et aucun artefact de release n'est produit

  Scénario: Un keystore introuvable ou un mot de passe faux arrête le build avec un message explicite
    Étant donné que le fichier de propriétés de signature désigne un keystore absent ou un mot de passe faux
    Quand le build de release signé est lancé
    Alors le build échoue avec un message qui nomme la cause
    Et aucun artefact de release n'est produit

  Scénario: Aucun artefact de release n'est jamais signé avec la clé de débogage
    Étant donné qu'un artefact de release a été produit par la procédure documentée
    Quand son certificat de signature est lu
    Alors ce certificat n'est pas celui de la clé de débogage

  # ── AC-4 : aucun secret de signature versionné ni publié ────────────────────────────────────

  Scénario: Aucun fichier de signature n'est suivi par le dépôt
    Étant donné que la clé de release et son fichier de propriétés existent sur la machine de l'humain
    Quand la liste des fichiers suivis par le dépôt est lue
    Alors aucun keystore ni fichier de propriétés de signature n'y figure

  Scénario: Un secret de signature ajouté à un commit fait échouer le contrôle de secrets
    Étant donné qu'un commit contient un mot de passe de signature
    Quand le contrôle de secrets du dépôt s'exécute
    Alors le contrôle échoue
    Et la fusion de la branche est empêchée

  Scénario: L'empreinte publique du certificat peut être consignée sans exposer la clé
    Étant donné qu'une preuve de déploiement est rédigée
    Quand elle consigne l'empreinte du certificat de signature
    Alors elle ne contient ni mot de passe ni contenu de keystore

  # ── AC-5 : la CI construit un artefact non signé, non déployable ────────────────────────────

  Scénario: La CI construit un artefact de release Android non signé
    Étant donné qu'une branche est poussée
    Quand la CI s'exécute
    Alors un artefact de release Android est construit
    Et cet artefact ne porte aucune signature

  Scénario: La CI ne dispose d'aucun secret de signature
    Étant donné que la configuration de la CI est lue
    Quand ses secrets et ses variables sont inventoriés
    Alors aucun élément ne concerne la signature de release

  Scénario: L'artefact de la CI ne peut pas être déclaré déployé
    Étant donné qu'un artefact produit par la CI est présenté comme candidat au déploiement
    Quand le déploiement est évalué
    Alors le déploiement n'est pas déclaré réussi
    Et la cause nommée est l'absence de signature de release

  # ── AC-6 : versionnage ──────────────────────────────────────────────────────────────────────

  Scénario: Chaque déploiement porte un numéro de version strictement supérieur au précédent
    Étant donné qu'un déploiement précédent est consigné avec son numéro de version
    Quand un nouvel artefact de release est préparé
    Alors son numéro de version est strictement supérieur au numéro consigné

  Scénario: Un artefact dont le numéro de version n'augmente pas est refusé avant installation
    Étant donné qu'un artefact de release porte un numéro de version égal ou inférieur au dernier déployé
    Quand son déploiement est demandé
    Alors le déploiement est refusé avant toute installation
    Et aucune installation forcée en rétrogradation n'est tentée

  # AC-6 « Erreur » — ajouté par @Architect à l'Integration Lock du 2026-09-30 (J-12, schéma régressif).
  Scénario: Un artefact dont le schéma de document régresse est refusé avant installation
    Étant donné qu'un artefact de release porte un numéro de version supérieur au dernier installé
    Et que son schéma de document est inférieur à celui de la dernière installation réussie
    Quand son déploiement est demandé
    Alors le déploiement est refusé avant toute installation
    Et la cause nommée est le schéma de document régressif

  Scénario: La version installée sur l'appareil se relie au commit qui l'a produite
    Étant donné qu'un artefact de release est installé sur l'appareil de référence
    Quand la version installée est lue sur l'appareil
    Alors elle correspond à la version consignée dans la preuve de déploiement
    Et cette preuve nomme le commit dont l'artefact est issu

  # ── AC-7 : mise à jour sans perte des échéances ─────────────────────────────────────────────

  Scénario: Une mise à jour installée par-dessus la version précédente conserve les échéances
    Étant donné qu'une release est installée sur l'appareil de référence avec des échéances enregistrées
    Quand la release suivante est installée par-dessus
    Et que l'application est rouverte
    Alors les mêmes échéances sont présentes avec leur description, leur date et leur état
    # 🔒 Lock 2026-09-30 (J-11) : « et leur état » ajouté — la clause AC-7 Nominal l'exige ; ⛔ PÉRIMÉ-2026-09-30 : l'étape s'arrêtait à « leur date ».

  Scénario: Une mise à jour signée par une autre clé est refusée sans désinstaller l'application
    Étant donné qu'une release est installée sur l'appareil de référence
    Quand un artefact signé par une autre clé est installé par-dessus
    Alors l'installation est refusée
    Et l'application installée n'est pas désinstallée pour contourner le refus

  Scénario: La première installation de release remplace une installation de développement explicitement
    Étant donné qu'une version de développement est installée sur l'appareil de référence
    Quand la première release signée doit être installée
    Alors la désinstallation préalable est une étape nommée et confirmée par l'humain
    Et cette étape n'est jamais répétée pour les releases suivantes

  # ── AC-8 : smoke test sur l'appareil de référence ───────────────────────────────────────────

  Scénario: L'application de release démarre sur l'appareil de référence et affiche le hub
    Étant donné qu'un artefact de release est installé sur l'appareil de référence
    Quand l'application est lancée à froid
    Alors le hub de pratiques est affiché
    Et le journal du processus de l'application ne contient aucune ligne FATAL

  Scénario: Une ligne FATAL du processus de l'application fait échouer le smoke test
    Étant donné que le journal du processus de l'application contient une ligne FATAL
    Quand le smoke test est évalué
    Alors le smoke test échoue
    Et la ligne en cause est citée dans la preuve

  Scénario: Une capture de journal vide ne prouve pas l'absence de plantage
    Étant donné que la capture du journal de l'application ne contient aucune ligne
    Quand le smoke test est évalué
    Alors le smoke test ne conclut pas
    Et le résultat est distinct d'un succès

  Scénario: Le smoke test de production ne modifie aucune échéance de l'utilisateur
    Étant donné que des échéances sont enregistrées sur l'appareil de référence
    Quand le smoke test de production s'exécute
    Alors les échéances sont identiques avant et après le smoke test

  # ── AC-9 : séquence staging → validation → production ───────────────────────────────────────

  Scénario: Le même artefact passe du staging à la production sans être reconstruit
    Étant donné qu'un artefact de release a passé le staging
    Et que l'humain a validé le staging
    Quand la production est déclarée
    Alors l'empreinte de l'artefact déclaré en production est celle de l'artefact passé en staging

  Scénario: Un artefact dont l'empreinte change entre staging et production est refusé
    Étant donné qu'un artefact a passé le staging
    Quand un artefact d'empreinte différente est présenté pour la production
    Alors la déclaration de production est refusée

  Scénario: Un échec de staging interdit la déclaration de production
    Étant donné que le staging d'un artefact a échoué
    Quand la production de cet artefact est demandée
    Alors la déclaration de production est refusée
    Et l'échec de staging est consigné

  # AC-9 « Erreur » et « Nominal » — ajoutés par @ProductOwner le 2026-09-30 (A-5, instanciation de Q16).
  Scénario: Un artefact construit depuis un commit absent de la branche principale est refusé en production
    Étant donné qu'un artefact de release a réussi son staging
    Et qu'il est construit depuis un commit qui n'est pas ancêtre de la branche principale distante
    Quand la production de cet artefact est demandée
    Alors la déclaration de production est refusée
    Et la cause nommée est le commit absent de la branche principale

  Scénario: Un staging peut porter un artefact construit depuis une branche non fusionnée
    Étant donné qu'un artefact de release est construit depuis le commit d'une branche non fusionnée
    Quand son staging est demandé sur l'appareil de référence
    Alors le staging n'est pas refusé pour ce motif
    Et la preuve de staging indique que cet artefact ne pourra pas être déclaré en production

  # AC-9 « Limite » — ajouté par @Architect le 2026-09-29, après le verdict humain Q5 (a).
  Scénario: Un même déploiement ne vaut que pour les US dont les visas portent sur le code déployé
    Étant donné qu'un artefact de production est construit depuis un commit qui contient le code de plusieurs US
    Et que les visas de l'une de ces US portent sur un autre commit
    Quand le déploiement est évalué pour chacune de ces US
    Alors chaque US dont les visas portent sur le code déployé est déclarée déployée avec une preuve qui renvoie au même artefact
    Et l'US dont un visa porte sur un autre commit n'est pas déclarée déployée
    Et la cause nommée est le visa périmé

  # ── AC-10 : RNF-02 mesuré sur l'appareil de référence ──────────────────────────────────────

  Scénario: Le délai d'affichage est mesuré sur l'appareil de référence et rend un verdict
    Étant donné que l'appareil de référence est connecté et nommé
    Quand le critère de levée de RNF-02 est exécuté en mode mesure sur cet appareil
    Alors il rend un verdict levé ou non levé
    Et la mesure est lue dans le fichier produit par la chaîne d'outils

  Scénario: Un délai au-dessus du seuil est publié comme non levé
    Étant donné qu'une mesure du délai d'affichage dépasse le seuil de RNF-02
    Quand le verdict est publié
    Alors RNF-02 est déclaré non levé
    Et la mesure est publiée telle quelle

  Scénario: Le seuil de RNF-02 est lu dans un seul document
    Étant donné que le critère de levée de RNF-02 est exécuté
    Quand il détermine le seuil
    Alors il lit ce seuil dans le Story File d'US-01.1
    Et il échoue si ce seuil est absent ou présent en plusieurs valeurs

  Scénario: Le délai d'affichage est mesuré à froid avec neuf tuiles présentes
    Étant donné que neuf échéances sont présentes sur la grille de l'appareil de référence
    Quand le délai d'affichage est mesuré à l'ouverture à froid
    Alors chaque mesure de la série est publiée
    Et le verdict porte sur la statistique arrêtée avant la mesure

  # ── AC-11 : sans appareil joignable, aucune conclusion ──────────────────────────────────────

  Scénario: Sans appareil détecté aucune conclusion n'est rendue
    Étant donné qu'aucun appareil n'est détecté
    Quand une vérification sur appareil est demandée
    Alors la vérification ne conclut pas
    Et le résultat est distinct d'un succès et d'un échec du produit

  Scénario: Un outil adb introuvable n'est pas confondu avec une liste vide
    Étant donné que l'outil de pont de débogage est introuvable sur la machine
    Quand une vérification sur appareil est demandée
    Alors la cause nommée est l'outil introuvable
    Et aucune liste d'appareils n'est présentée comme vide

  Scénario: Plusieurs appareils connectés exigent de nommer la cible
    Étant donné que deux appareils sont connectés
    Quand une vérification sur appareil est demandée sans cible nommée
    Alors la vérification est refusée
    Et aucun appareil n'est choisi implicitement

  Scénario: Un émulateur ne vaut pas l'appareil de référence
    Étant donné que seul un émulateur Android est connecté
    Quand le déploiement est évalué
    Alors le déploiement n'est pas déclaré réussi

  # ── AC-12 : aucune permission réseau dans l'artefact de production (RNF-07) ─────────────────

  Scénario: L'artefact de production ne demande aucune permission réseau
    Étant donné qu'un artefact de release est candidat à la production
    Quand ses permissions déclarées sont lues
    Alors aucune permission d'accès au réseau n'y figure

  Scénario: Une permission réseau apparue dans l'artefact de production est signalée
    Étant donné qu'un artefact de release déclare une permission d'accès au réseau
    Quand son déploiement est évalué
    Alors le déploiement est refusé
    Et la permission en cause est nommée

  Scénario: L'artefact de mesure de profil n'est jamais installé comme production
    Étant donné qu'un artefact de profil a servi à mesurer RNF-02
    Quand la production est déclarée
    Alors l'artefact déclaré n'est pas l'artefact de profil

  # ── AC-13 : les sauvegardes restent locales (RNF-07, arbitrage humain A-1 du 2026-09-30) ───────
  # Instanciation ANDROID de la règle R-SAUV. ⛔ iOS : transfert BT-1, hors de ce fichier.

  Scénario: Les données de l'application sont exclues de la sauvegarde du système vers un nuage
    Étant donné qu'un artefact de release Android est candidat à la production
    Quand sa déclaration de sauvegarde est lue dans l'artefact
    Alors toutes les données de l'utilisateur sont exclues de la sauvegarde automatique vers le nuage
    Et cette lecture est consignée dans la preuve de déploiement

  Scénario: Un artefact dont une donnée reste incluse dans la sauvegarde nuage est refusé en production
    Étant donné qu'un artefact de release laisse un fichier de données inclus dans la sauvegarde vers le nuage
    Quand son déploiement est évalué
    Alors le déploiement est refusé
    Et la cause nommée est la sauvegarde nuage non exclue

  Scénario: Une sauvegarde qui reste sur l'appareil demeure admise quand la plateforme la distingue du nuage
    Étant donné que la plateforme distingue une sauvegarde vers le nuage d'un transfert local
    Et que l'artefact exclut les données de la seule sauvegarde vers le nuage
    Quand son déploiement est évalué
    Alors le déploiement n'est pas refusé pour ce motif

  Scénario: Sans distinction possible entre nuage et transfert local aucune donnée ne sort par la sauvegarde
    Étant donné que la plateforme ne distingue pas une sauvegarde vers le nuage d'un transfert local
    Quand la déclaration de sauvegarde de l'artefact est lue
    Alors les données de l'utilisateur sont exclues de tout mécanisme de sauvegarde du système
    Et la preuve de déploiement indique qu'aucune sauvegarde locale n'est disponible
