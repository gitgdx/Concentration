# EPIC 01 - Module Échéances (MVP)

> **Priorité MoSCoW :** Must-Have
> **Dépendances amont :** EPIC_00 — Fondations (Sprint 0) : socle qualité, CI, protection de branche, stack Flutter.
> **Dépendances aval :** Modules futurs (Respiration, Concentration) — dont l'architecture doit rester extensible (RF-21), mais non développés au MVP.

## 📝 Description de l'Epic

Premier module métier de l'application « Concentration » (PRD §1.3, §3.1) : il matérialise
instantanément, sous forme de tuiles épurées, le temps restant avant chaque échéance importante —
exprimé par **un seul nombre nu** dans l'unité la plus pertinente, avec une **couleur ambiante**
(gradient orange → bleu) traduisant la proximité du prochain changement de nombre. L'objectif est
d'offrir un support de pratique de recentrage à charge cognitive nulle : un coup d'œil suffit pour
ancrer la revue mentale (usage quotidien < 60 s).

**Dans le périmètre (MVP)** : hub de pratiques avec Échéances actif et modules futurs visibles/grisés ;
grille de 1 à 9 tuiles ; moteur de temps restant (unité adaptative + arrondi supérieur) ; gradient
orange → bleu ; état « à zéro » + geste double-tap de disparition ; gestion des événements (CRUD :
description + date + heure optionnelle par défaut 23:59) ; validation (date future) ; stockage local
offline-first ; dark mode ; accessibilité.

**HORS périmètre (MVP)** : comptes utilisateurs, synchronisation cloud, multi-appareils ;
notifications / rappels ; modules Respiration et Concentration (prévus dans l'architecture, non
développés) ; partage social ; widgets d'écran d'accueil OS ; tri manuel des tuiles (candidats V2).

## ⚠️ Critères de performance et sécurité

- **Performance** : affichage des tuiles < 500 ms à l'ouverture (RNF-02, indicateur §8) ; taux de
  crash < 0,5 %.
- **Rafraîchissement** : recalcul des nombres/couleurs à chaque affichage et au minimum toutes les
  minutes lorsque l'écran reste ouvert (RF-05, nécessaire à l'unité « heures »).
- **Calcul** : unités « ans » et « mois » en calendaire réel (mois de longueur variable, années
  bissextiles) ; calculs basés sur le fuseau local ; comportement défini au changement de fuseau
  (RNF-04, RNF-05).
- **Confidentialité / offline** : aucune donnée ne quitte l'appareil au MVP ; toutes les
  fonctionnalités fonctionnent sans connexion ; stockage local (RNF-01, RNF-07).
- **Accessibilité** : contraste WCAG AA sur toute la plage du dégradé ; nombre lisible quelle que
  soit la couleur de fond ; tailles de police système ; lecteur d'écran annonçant le temps restant
  complet avec unité (RNF-06).

## 👥 Rôles identifiés

| Rôle | Description |
|---|---|
| @ProductOwner | Valeur métier, User Stories, critères d'acceptation, priorisation MoSCoW, arbitrages produit (unité non affichée, limite 9, double-tap). |
| @Architect | Architecture modulaire (hub + registre de modules RF-21), modèle de rendu, contrat du moteur de temps restant, découpage des tâches, ADR. |
| @UXDesigner | Design system, placement des entrées de pratique (grille de hub vs barre de nav), dégradé orange → bleu, dark mode, états (vide/à zéro), accessibilité. |
| @DataEngineer | Modèle de données des événements, persistance locale offline-first, migrations réversibles. |
| @Developer | Implémentation Flutter (tuiles, grille, moteur, CRUD, persistance). |
| @QA_Tester | Vérification des scénarios Gherkin, cas limites du moteur, non-régression, couverture. |
| @CyberSecurity | Vérification confidentialité (aucune sortie de données), stockage local. |
| @DevOps | CI, build multi-plateformes iOS/Android, déploiement. |

## 📄 Story Files associés

| US ID | Titre | Story File | Statut |
|---|---|---|---|
| US-01.1 | Affichage Hub & grille d'échéances | [`docs/stories/US-01.1-affichage-hub-grille.md`](../stories/US-01.1-affichage-hub-grille.md) | 🧪 **PASS le 2026-08-02 — `prepare_deployment`.** ⛔ **PAS `🚀 OUI`** : `/certify` exécuté, **gates 1→5 verts, gate 6 en échec** *(`Déploiement = ⏳`)*. **Certification DIFFÉRÉE, pas abandonnée** — elle reprend à `prepare_deployment` dès qu'US-01.3 livre la chaîne de déploiement. ⚠️ **Ses visas d'audit devront être RAFRAÎCHIS** à ce moment-là *(ils portent sur `173fb62`)*. ⛔ **PÉRIMÉ-2026-08-02 : cette cellule affichait « ⏳ business_alignment » — faux depuis le 2026-08-01.** |
| US-01.2 | Gestion des événements (CRUD) ⚠️ *le Story File est intitulé « **Gestion des échéances** » — **divergence de vocabulaire NON repeinte** : le PRD §4.2 dit « événements », tout le reste du produit dit « échéances » ; à uniformiser par un arbitrage explicite, **pas** par un renommage silencieux dans un seul document* | [`docs/stories/US-01.2-gestion-echeances.md`](../stories/US-01.2-gestion-echeances.md) | ⏳ **`business_alignment`** — Story File **fonctionnel** créé le **2026-08-03** *(14 AC actifs, 42 clauses, 45 scénarios ; sections techniques **dues** à @Architect)*. ✅ **Gate *clarify* fermé le 2026-08-03** : **11 arbitrages humains**, dont **RF-06 sorti en US-01.4**, **date civile** *(contredit la **lettre** de la note I-5 du modèle — @Architect doit statuer **par ADR**)* et **limite de 9 = actives + échues**. ⛔ **`EVT_STORY_READY` non encore émis.** 📥 **PORTE UN CRITÈRE D'ENTRÉE TRANSFÉRÉ PAR EPIC_00, le 2026-08-01** *(arbitrage humain)* : **la convention de migrations réversibles d'[ADR-005](../adr/ADR-005-convention-migrations-reversibles.md) doit être INSTANCIÉE** — patron de test de migration réversible **exécuté** sur le **premier schéma réel**, interdiction de migration destructive par défaut *(RF-21)* **exercée**. ⚠️ **Origine du transfert** : la 2ᵉ moitié du critère de clôture **nº 112 d'EPIC_00** exigeait cette application, or elle était **structurellement invérifiable là-bas** *(US-01.2 n'existe pas, et EPIC_00 doit être clos AVANT le développement d'EPIC_01 — un deadlock)*. ⛔ **Un transfert n'est pas une levée** : le **risque nº 4 d'EPIC_00 reste OUVERT** jusqu'à cette instanciation, et à ce jour la convention est **documentée et jamais appliquée — aucune migration n'a jamais été exécutée sur ce projet** |

| US-01.3 | Chaîne de déploiement mobile réelle | _(à créer via `/us-new`, **après US-01.2**)_ | ⏳ à venir — 📤 **CRÉÉE PAR ARBITRAGE HUMAIN DU 2026-08-03** *(voir §Critères de clôture)*. **Objet** : rendre `🚀 DEPLOYED` **signifiant** pour ce produit — JDK 17+, licences SDK Android, émulateur ou appareil, keystore, **build signé**, distribution interne *(Play Console internal testing)*, health-check adapté à une app **sans serveur**. ⛔ **Elle est le seul chemin vers `🚀 OUI` pour US-01.1 ET US-01.2**, et elle referme **trois trous ouverts depuis le bootstrap** : « l'application n'a **jamais** tourné sur un appareil » · **RNF-02 non mesuré** *(instrument déjà livré : [`rnf02_exit_criterion.py`](../../reports/US-01.1/rnf02_exit_criterion.py))* · « déployé » **sans définition** pour ce produit |

| US-01.4 | Geste double-tap et historique des échéances échues (RF-06) | _(à créer via `/us-new`, **après US-01.2**)_ | ⏳ à venir — 📤 **CRÉÉE PAR ARBITRAGE HUMAIN DU 2026-08-03**, sur recommandation @ProductOwner : **RF-06 SORT d'US-01.2**. **Motif inscrit** : le cœur d'US-01.2 est le **critère d'entrée transféré par EPIC_00** *(instancier ADR-005 — première migration réellement exécutée du projet)*, et **y adjoindre un geste avec animation dilue l'attention sur la partie la plus risquée** *(45 clauses contre 27 en US-01.1, qui a livré **3 AC orphelins dont 2 faux verts**)*. **Objet** : le **double-tap** qui fait disparaître une tuile échue, son **animation de disparition** *(seul feedback — ⛔ **aucune modale**, le geste n'est **pas destructif**)*, l'état **`ÉCHUE RETIRÉE`** *(tuile absente, échéance **conservée** et consultable en gestion)*, et le **signalement** en gestion des échues **encore présentes sur la grille**. **Porte le risque nº 5 de cet EPIC.** 📥 **Entrées reprises d'US-01.2** *(§AC-9 déplacé)* : **3 clauses**, **6 scénarios**, la borne **NM-3** *(fluidité de l'animation — non mesurable sans appareil)*, et le **complément du message de la limite de 9** *(AC-5 Erreur : US-01.2 n'annonce que « supprimer », faute d'autre issue existante)*. ⛔ **Dépend d'US-01.2** : sans persistance, un retrait ne survivrait pas à la réouverture — **US-01.2 introduit l'état échu, US-01.4 introduit le geste qui l'utilise** |

## ⚠️ Zones d'ombre / Risques identifiés

| # | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| 1 | **Tension gradient PRD ↔ maquette Stitch** : le PRD (RF-04) décrit une **interpolation continue** orange → bleu (proposition OKLCH `#FF8C42` → `#3D7DD8`) ; la maquette `hub_de_pratiques.html` implémente **4 paliers discrets** (`temporal-gradient-1..4`). | Perception du temps (cœur produit) et lisibilité (contraste) potentiellement incohérentes selon l'interprétation. | Arbitrage @UXDesigner + @ProductOwner : trancher continu vs paliers ; si paliers, justifier le nombre de crans ; documenter dans le Design System. |
| 2 | **Divergence d'endpoint bleu** : le PRD propose `#3D7DD8` comme bleu d'imminence ; la maquette utilise `#005ab3` (`temporal-gradient-4`, secondary-container) — teinte plus sombre/saturée. | Rendu final et contraste du nombre sur fond bleu différents des cibles produit. | Fixer une couleur d'endpoint unique dans le Design System (source d'autorité `docs/design/DESIGN_SYSTEM.md`) après test de contraste WCAG AA ; tracer la décision. |
| 3 | **Structure du hub PRD ↔ maquette** : RF-20 décrit un hub à 3 entrées (Échéances active + Respiration/Concentration grisées) ; la maquette fait de la grille Échéances le canvas d'accueil et place les modules futurs comme **icônes de barre de nav basse**, non grisées (`.ghost-entry` inutilisée). | Ambiguïté sur l'emplacement et l'état grisé des modules futurs. | AC US-01.1 formulés au niveau comportemental (visible + grisé + non-cliquable) ; placement délégué à @UXDesigner (résolution clarify #4). |
| 4 | **Frontières exactes du moteur de temps restant** : comportement à un seuil d'unité exact, bascule jours → heures à 24 h, changements d'heure été/hiver, mois calendaires de longueurs différentes (PRD §6). | Nombre affiché incohérent aux transitions (cœur de l'exercice). | US-01.1 embarque le calcul (ceil + unité adaptative) ; certification calendaire fine rattachable à une US ultérieure sans changer le contrat d'affichage (résolution clarify #1). |
| 5 | **Double-tap accidentel** (RF-06 §6.6) : geste de disparition d'une tuile échue potentiellement déclenché par erreur. | Perte de visibilité d'une échéance ; frustration. | ⛔ **PÉRIMÉ-2026-08-03 : cette cellule portait « Rattaché à US-01.2 » — faux depuis le découpage arbitré.** ⚖️ **Rattaché à US-01.4** *(RF-06 y est déplacé)*. ✅ **Mitigation TRANCHÉE le 2026-08-03** *(clarify nº 1 et nº 2 d'US-01.2, recommandations @PO retenues)* : le geste est **NON DESTRUCTIF** — l'échéance reste consultable en gestion à l'état « échu » — donc **le feedback est l'ANIMATION de disparition, ⛔ sans modale de confirmation** *(une modale friction­nerait le geste le plus fréquent au profit d'un acte sans conséquence, contre « zéro friction »)*. ⚠️ **US-01.2 livre l'état échu et sa persistance** ; **US-01.4 livre le geste**. |
| 6 | **Langue & nommage des maquettes** : Hub en `lang="fr"`, gestion en `lang="en"` (« days left ») ; nom de code « Sobriety » dans les `<title>`. | Incohérence de langue produit. | Uniformiser en français ; nombre nu sans unité sur les tuiles (règle produit #7) ; à confirmer pour la page de gestion. |

## 🎯 Challenge PO : La couleur doit-elle encoder la proximité du changement, ou la grandeur du nombre ?

Règle produit (RF-04) : la couleur encode la **proximité du prochain changement de nombre**, PAS la
magnitude du nombre affiché. C'est contre-intuitif et source d'erreur d'implémentation.

```
  Proximité du PROCHAIN changement de nombre  (p ∈ [0 ; 1])
  p = 0                                                  p = 1
  |------------------------------------------------------|
  ORANGE                                                 BLEU
  "le nombre vient de changer"          "le changement est imminent"
  (loin du prochain changement)         (le nombre va décrémenter)

  Conséquence assumée :
   - un "42" peut être ORANGE (vient de passer de 43 à 42)
   - un "3"  peut être BLEU   (va bientôt passer de 3 à 2)
  => la couleur N'EST JAMAIS fonction de la valeur du nombre.
  => aucune couleur d'urgence (rouge) : ambiance calme, contemplative.
```

**Décision MVP** : conserver strictement RF-04 (proximité, non inversé). Pas de rouge, pas de badge,
pas de pourcentage. La couleur est un indicateur ambiant, sans texte. Le sens (orange = loin,
bleu = imminent) est verrouillé dans les AC de US-01.1 (AC-5) pour prévenir l'inversion.

## Critères de clôture de l'EPIC

> ⚖️ **ARBITRAGE HUMAIN DU 2026-08-03 — AUCUN CRITÈRE N'EST ABAISSÉ, UNE US EST AJOUTÉE.**
>
> **Le défaut trouvé** : deux critères ci-dessous étaient **insatisfiables** au 2026-08-02 — le nº 1 exige
> `🚀 OUI`, or US-01.1 est arrêtée à `🧪 PASS` *(gate 6 de `/certify` en échec, `Déploiement = ⏳`)* ; et le
> nº 4 exige un affichage **`< 500 ms` mesuré**, or c'est **RNF-02**, seul AC orphelin d'US-01.1, **non
> mesurable sans appareil sur la plateforme cible**.
>
> 🔬 **La cause est structurelle et dépasse cet EPIC** : `WORKFLOW.yaml` fait dépendre `epic_closure` de
> `Déploiement == 🚀 DEPLOYED`, et **aucune phase ne modélise « US validée mais NON DÉPLOYABLE »**.
> US-01.1 stationne donc en `prepare_deployment` avec **toutes ses préconditions satisfaites**.
> ⛔ **Troisième instance de la même famille de défauts** : le SCB ne sait pas dire « QA à refaire », la
> trace ne sait pas dire « sur quel commit » *(NB-6)*, le workflow ne sait pas dire « non déployable ».
> ➡️ **`/audit-methodo`.**
>
> ⛔ **CE QUI A ÉTÉ REFUSÉ, et pourquoi** : reformuler les critères sur `🧪 PASS` aurait été **abaisser
> l'exigence du PREMIER EPIC produit**, et aurait laissé « déployé » **sans définition** pour toutes les US
> suivantes. C'est la voie qu'a prise EPIC_00 avec son critère 112 *(transfert)* — **elle marche une fois,
> pas deux**. ✅ **Voie retenue** : **US-01.3 rend `🚀 DEPLOYED` signifiant**, et les critères restent
> **inchangés dans leur exigence**. Le nº 1 gagne seulement l'US qui manquait à sa liste.
>
> ⚠️ **Conséquence assumée** : **EPIC_01 reste ouvert plus longtemps**, et la certification d'US-01.1 est
> **différée — pas abandonnée**. Elle reprend à `prepare_deployment` après US-01.3, et **ses visas
> d'audit devront être rafraîchis** *(ils portent sur `173fb62`)* — application directe de **NB-6**.

- [ ] Toutes les US listées (US-01.1, US-01.2, **US-01.3**, **US-01.4**) sont `Certifié Prod = 🚀 OUI`
      — 📌 **US-01.4 ajoutée le 2026-08-03** *(découpage de RF-06 hors d'US-01.2, arbitrage humain)* :
      **une US créée après ce critère doit y être INSCRITE**, sinon il redevient **incomplet en
      silence** — c'est exactement le défaut que l'arbitrage de la veille a corrigé, il n'est pas
      réintroduit ici
- [ ] Aucune régression détectée sur les EPICs dépendants (EPIC_00)
- [ ] Décisions de design tranchées et tracées (gradient continu vs paliers, endpoint bleu) dans `docs/design/DESIGN_SYSTEM.md`
- [ ] Indicateurs de succès mesurés : affichage < 500 ms, taux de crash < 0,5 % (PRD §8)
      — ⚠️ **porté par US-01.3** : non mesurable sans appareil sur la plateforme cible ; l'instrument
      existe déjà et **refuse de conclure** faute de cible *(`exit 2`)*, il ne peut pas rendre un faux vert
- [ ] Documentation à jour (`docs/user-guide/`, `CHANGELOG.md`) — ⚠️ **`docs/user-guide/` n'existe pas** et
      la phase `documentation` de `WORKFLOW.yaml` *(@TechWriter, `EVT_DOCS_UPDATED`)* **n'a jamais tourné**
      sur ce projet : à ouvrir explicitement, pas à cocher par habitude

---
*Document rédigé par @ProductOwner — 2026-07-24*
*Prochaine étape : Validation technique par @Architect*
