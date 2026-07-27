# ADR-006 : Enforcement de la branche principale — cible armée mais NON appliquée (limite de plan), et vérification honnête en lecture seule

- **Date** : 2026-07-26
- **Statut** : Accepté
- **US associée** : US-00.4

> **Note de révision — réécriture en place, assumée.** Une première version de ce fichier a été rédigée
> le 2026-07-26 sous une prémisse **fausse** (« la protection de branche est applicable sur ce dépôt »)
> et concluait que la règle passait de *déclarée* à *effective*. Elle est **remplacée par le présent
> texte**, au **même numéro** et au **même chemin**. Justification : ce fichier était **untracked**
> (`??` dans `git status`) — jamais commité, jamais audité, jamais référencé par un artefact du dépôt,
> jamais entré en vigueur. La clause d'immuabilité des ADR protège le **registre historique des
> décisions effectives** ; elle ne s'applique pas à un brouillon non versionné. Aucun ADR-007 n'est
> créé : cela aurait inscrit au registre une décision fantôme qui n'a jamais rien gouverné.

## Contexte

`CLAUDE.md` (règle dure 2) déclare que la règle « **jamais** de commit/push sur la branche
principale » est *enforced* par « protection de branche », et la Constitution (Art. 4) déclare les
gates qualité « requis par la protection de branche ». **Ce n'est pas le cas — et ce ne peut pas
l'être sur ce dépôt.**

**Fait 1 — la branche principale n'est pas protégée.** Au **2026-07-26** :
`GET /repos/gitgdx/Concentration/branches/main` → `{"name":"main","protected":false}`. Les 4 status
checks déclarés dans `factory.config.json` (`🔐 Secrets scan (gitleaks)`,
`📋 Governance (SCB + traçabilité + synchro)`, `check-branch-name`, `📱 App (gates run_gates.py)`)
s'exécutent bien sur chaque PR, mais **aucun n'est requis** : rien n'empêche *techniquement* un merge
avec CI rouge, un push direct ou un force-push. C'est le **risque #2 d'EPIC_00** (« règles déclarées
mais non enforced ») **matérialisé**.

**Fait 2 — la cause est une limite de plateforme, pas un défaut de droits ni d'outillage.** Avec un
jeton `gh` authentifié `gitgdx` disposant de `{"admin": true, "maintain": true, "push": true, …}` sur
le dépôt, **les deux** mécanismes d'enforcement de branche sont refusés **à l'identique** :

| Appel | Réponse |
|---|---|
| `GET /repos/gitgdx/Concentration/branches/main/protection` | **403** — `{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"403"}` |
| `GET /repos/gitgdx/Concentration/rulesets` | **403** — `{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.","documentation_url":"https://docs.github.com/rest/repos/rules#get-all-repository-rulesets","status":"403"}` |

Le dépôt est `{"private": true, "visibility": "private"}`, propriété d'un compte
`{"owner_type": "User"}` dont le plan n'inclut pas la protection de branche pour les dépôts privés.
Conséquence directe : `scripts/apply_branch_protection.sh` **échouerait en 403**. Aucune commande,
aucun script, aucun réglage ne peut protéger `main` sur ce dépôt en l'état. Un **403** (plan) n'est ni
un **401** (non authentifié) ni un **404** (branche non protégée *ou* droits insuffisants) : les
confondre ferait diagnostiquer un problème de droits là où il n'en existe aucun.

**Fait 3 — cause racine : la factory déclarait un enforcement structurellement impossible, et son
propre contrôle de dérive était incapable de le voir.** `factory.config.json` porte **depuis
l'origine du dépôt** un bloc `branch_protection` (`enforce_admins: true`, 1 approbation, 4 status
checks requis) que le compte **n'a jamais pu appliquer**. Le défaut n'est donc pas « quelqu'un a
oublié de lancer le script » : c'est une **cible inapplicable déclarée comme acquise**. Et
`python scripts/factory_sync.py --check` — gate CI bloquant — affiche
« Synchro factory conforme (env, **protection**, workflows, seuils) » alors qu'il **ne contacte
jamais l'API GitHub** : il ne compare que des artefacts *documentaires* (`scripts/factory_env.sh`,
bloc entre marqueurs de `docs/GIT_PROTECTION.md`, présence des `name:` de jobs dans les workflows,
seuils de couverture). Un contrôle vert coexistait donc **sans aucune contradiction** avec une branche
principale grande ouverte **et** avec une cible que la plateforme aurait de toute façon refusée. Le
mot « protection » dans une sortie verte était une **fausse confiance produite par la factory
elle-même** — le pire défaut possible pour un dispositif dont l'unique produit est la confiance
(`Certifié Prod = 🚀 OUI`).

**Fait 4 — second défaut, indépendant du 403 : la cible déclarée était de toute façon
auto-verrouillante.** Le dépôt n'a qu'un seul collaborateur, `gitgdx`, administrateur. Or la config
demandait `required_approving_review_count: 1` **et** `enforce_admins: true`. GitHub interdit à
l'auteur d'une PR d'approuver sa propre PR, et `enforce_admins: true` supprime le contournement
administrateur : appliquée telle quelle, cette configuration aurait rendu **tout merge futur
impossible**. La factory vivait donc dans une alternative implicite dont **aucune branche n'était
acceptable** : ne rien appliquer (le trou d'enforcement), ou appliquer et se verrouiller — sans
compter que la plateforme aurait refusé les deux.

**Fait 5 — historique constaté, sans réécriture.** `git log --first-parent --oneline origin/main`
donne la totalité de ce qui a atterri sur `main` : **8 fusions de PR** (#1, #3, #4, #5, #6, #7, #8,
#9) et **exactement 2 commits directs**, les commits de bootstrap `0a2e5ab` (`chore(init)`) et
`6483022` (`chore(governance)`). Aucun commit direct après le bootstrap. *(Nota : `git log --merges`
renvoie 12 entrées, dont 4 fusions internes à des branches de travail — cette commande ne prouve
**pas** l'absence de commit direct sur `main` ; seule la lecture **first-parent** le fait.)*

**Décision humaine d'encadrement (2026-07-26)** : ni passage du dépôt en public, ni upgrade GitHub
Pro. Le présent ADR arbitre donc ce qui est décidable **sans coût et sans exposition**.

## Décision

### A — Ce qui n'est pas acheté et ce qui reste non protégé

1. **Ne pas souscrire GitHub Pro et ne pas rendre le dépôt public.** Les deux voies de déblocage sont
   documentées (décision 8) mais **aucune n'est engagée** : cela relève d'une décision humaine
   explicite et tracée, hors pouvoir de tout agent.
2. **La branche principale reste NON protégée par la plateforme après cette US, et l'US ne le
   prétendra nulle part.** Toute affirmation contraire dans un livrable (Story File, `GIT_PROTECTION.md`,
   rapports, SCB, BACKLOG, EPIC, ADR) est un **défaut bloquant**. Le **risque #2 d'EPIC_00 demeure
   OUVERT** — il est requalifié de « impensé » en « dette datée, étayée et portée », ce qui est un
   progrès de gouvernance, **pas** une fermeture.

### B — La cible : déclarée et ARMÉE, explicitement NON APPLIQUÉE

3. **Cible de protection** (déclarée dans `factory.config.json`, source unique) :
   `required_approving_review_count: **0**` **+** `enforce_admins: **true**` ; clés inchangées —
   `required_conversation_resolution: true`, `allow_force_pushes: false`, `allow_deletions: false`,
   `required_linear_history: false`, `strict: true` sur les **4** contextes. C'est la **seule**
   combinaison à la fois non décorative et opérable par un développeur solo assisté d'agents
   (cf. Alternatives). Elle **n'est pas active** : `apply_branch_protection.sh` échouerait en 403 ; il
   est **prêt et conditionné au déblocage**, jamais « à exécuter ».
4. **« Armée » = applicable en UNE seule commande le jour du déblocage, sans nouvelle décision.**
   `python scripts/factory_sync.py --emit-branch-protection` produit déjà le payload complet et
   consommable ; l'arbitrage `0` approbation, la justification, la condition de retour à `1` et la
   procédure sont **instruits ici**. « Armée » vaut **validation logique** (payload cohérent et
   complet), **pas** validation **fonctionnelle** : aucun `PUT` n'a jamais été accepté par la
   plateforme, donc le comportement réel de la règle reste **non démontré**.
5. **`required_pull_request_reviews` reste PRÉSENT avec `0`** — jamais supprimé du payload. Retirer
   l'objet désactiverait « Require a pull request before merging » : `0` approbation **≠** pas de PR
   exigée. `emit_branch_protection()` émet toujours cet objet ; ne jamais « optimiser » son omission
   quand le compteur vaut `0`.
6. **La protection est générée depuis la configuration, jamais saisie à la main** — y compris dans un
   éventuel repli `curl`. Tout écart futur entre la config et le dépôt se corrige en **ré-appliquant
   depuis la config**, jamais en alignant la config sur l'état constaté.

### C — La vérification : lecture seule, trois issues, hors CI

7. **Outillage de vérification en lecture seule à trois issues honnêtes**
   (`scripts/check_branch_protection.py`, câblé sur `factory_sync.py --check-remote`) :
   - **exit 0** = protection **strictement conforme** à la cible générée. C'est le **seul** chemin où
     le mot « conforme » est autorisé.
   - **exit 1** = protection **absente ou divergente**, avec une ligne par champ
     (`champ | attendu | réel`) et les contextes listés séparément en *manquants* et *en trop*.
   - **exit 2** = **vérification impossible**, message `VERIFICATION IMPOSSIBLE — ce n'est PAS un
     succès`. Couvre le **403 de plan** (l'issue réelle sur ce dépôt au 2026-07-26), l'absence de `gh`
     **et** de jeton, un 401, une erreur réseau, et le **404 ambigu**. **Un exit 2 est un constat à
     signaler — jamais un succès, jamais une preuve de conformité, jamais un motif de clôture de
     dette.**

   Le vérificateur n'a **aucun chemin d'écriture** : `apply_branch_protection.sh` écrit (`PUT`),
   `check_branch_protection.py` lit (`GET`).
8. **Désambiguïsation obligatoire du 404** : `GET …/protection` renvoie 404 aussi bien quand la
   branche n'est pas protégée que quand le jeton manque de droits. Croiser avec
   `GET /repos/{o}/{r}/branches/{b}` (champ `protected`, lisible sans admin) : `protected == false`
   → **exit 1** (dérive réelle) ; protection illisible malgré `protected == true` → **exit 2** (droits
   insuffisants). Sans ce croisement, un défaut de droits serait lu comme une absence de protection —
   inacceptable pour une preuve.
9. **Le mapping de comparaison PUT → GET est explicite** : l'API n'est pas symétrique. Deux pièges
   sont portés par le présent texte parce qu'une comparaison naïve produirait de **fausses dérives** :
   (i) le `PUT` prend des booléens là où le `GET` renvoie des objets `{"enabled": bool}` (`enforce_admins`,
   `allow_force_pushes`, `allow_deletions`, `required_linear_history`,
   `required_conversation_resolution`) ; (ii) `restrictions: null` au `PUT` correspond à une clé
   `restrictions` **absente** de la réponse `GET` → **absence = conforme**, présence = écart.
10. **`--check` annonce explicitement une vérification DOCUMENTAIRE**, énumère ce qu'il compare
    réellement, avertit que l'état réel de la protection sur GitHub n'est **pas** vérifié, et renvoie
    vers `--check-remote`. Son périmètre est **clarifié, pas réduit** : il reste vert et reste un gate
    CI bloquant. Le mot « protection » ne peut plus y figurer comme un **fait vérifié**.
11. **Le contrôle distant reste HORS CI, par construction.** `GET …/branches/{b}/protection` exige des
    droits **admin** que le `GITHUB_TOKEN` de la CI n'a pas. L'y ajouter produirait soit un faux rouge
    permanent, soit la tentation de le rendre non bloquant — donc décoratif : exactement le défaut
    corrigé ici. C'est une **commande d'administration manuelle**, et cette séparation est vérifiée par
    un **contrôle négatif** (aucune référence à `--check-remote` dans `.github/workflows/`).

### D — Conditions de sortie et porteur

12. **Deux — et seulement deux — voies de déblocage**, datées du 2026-07-26 et dépendantes de la
    politique commerciale de la plateforme : (a) **rendre le dépôt public** — coût nul, mais exposition
    publique du code, de toute la gouvernance et de **l'historique complet**, **irréversible** pour ce
    qui a été publié (ce qui fait de `gitleaks` une barrière critique) ; (b) **GitHub Pro** — dépôt
    restant privé, aucune exposition, mais coût par utilisateur et par mois. Dans les deux cas ce qui
    est débloqué est **identique** (protection classique **et** rulesets, status checks requis,
    `enforce_admins` effectif, test négatif serveur devenu exécutable). **Ajouter un collaborateur ne
    débloque rien** : la limitation porte sur le **plan** et la **visibilité**, pas sur le nombre de
    contributeurs.
13. **Condition vérifiable de retour à `1` approbation** : dès qu'un **2ᵉ collaborateur** obtient
    l'accès en écriture. Contrôle : `gh api repos/gitgdx/Concentration/collaborators` → si **≥ 2**
    comptes en écriture, ouvrir une US remettant `required_approving_review_count: 1`.
    `0` approbation est un réglage **daté et conditionnel** (dépôt mono-collaborateur administrateur),
    **pas une norme** : il devient une **anomalie** dès le 2ᵉ collaborateur.
14. **Point de contrôle périodique dans `/audit-methodo`** (axe Gouvernance) : exécuter
    `--check-remote` (droits admin), **consigner le code de sortie**, puis réévaluer la condition de
    **déblocage** (12) et la condition de **retour à `1`** (13). Sans porteur périodique, ces deux
    conditions ne seraient surveillées par personne — c'est le seul mécanisme qui empêche ce constat de
    pourrir silencieusement.

### E — Portée bornée

15. **Ni réécriture d'historique, ni `EVT_WORKFLOW_VIOLATION` rétroactif.** Les commits `0a2e5ab` et
    `6483022` sont **antérieurs à tout enforcement** et ont **créé** les règles en question ; les
    qualifier de violations serait factuellement inexact. Cette **exemption est portée par le présent
    texte** (reprise dans `docs/GIT_PROTECTION.md` et le constat daté), **pas** par
    `governance.grandfathering_date`, **laissée à `null`** : vérification faite, cette clé est **lue
    par aucun script** (elle n'apparaît que dans une *description* de
    `scripts/factory.config.schema.json` et un *docstring* de `scripts/validate_trace.py`). La
    renseigner aurait été un **no-op** dont la sémantique documentée (« *US sans trace tolérées avant
    la date* » — sujet **différent** des commits hors PR) aurait, si un jour implémentée, rendu
    tolérables les US sans trace antérieures et **masqué la dette US-INIT-01→06**.
16. **Les certifications de US-00.1 / US-00.2 / US-00.3 restent valides** : elles reposent sur des
    audits à contexte frais, des gates CI réellement exécutés et des preuves archivées,
    **indépendamment** de la protection de branche.

### ⛔ Ce que cette décision ne fait PAS — démenti explicite

La version précédente de cet ADR affirmait que « la règle de gouvernance passe de *déclarée* à
**effective** », que `"protected": true` serait prouvé par l'API, que les 4 gates deviendraient
« incontournables, administrateur inclus » et que force-push et suppression seraient « refusés par le
serveur ». **Ces quatre affirmations sont fausses et sont ici démenties.** Après cette US :

- `main` **n'est pas protégée** — `"protected": false` reste l'état réel ;
- les 4 status checks sont **rapportés, pas requis** : une fusion avec CI rouge reste possible ;
- `enforce_admins` **n'est pas en vigueur** ; il n'y a pas de bypass à supprimer puisqu'il n'y a pas de
  règle ;
- aucun refus serveur n'est démontré, et **aucun ne sera exigé** par cette US : sans protection, un
  `git push` direct sur `main` **réussirait** — l'exécuter modifierait `main` hors PR pour rien. Le
  **test négatif serveur est reporté** au déblocage.

**Ce qui protège `main` aujourd'hui est un *filet de discipline*, pas une contrainte de plateforme** :
(a) le hook **local** `pre-push` refusant la branche principale (`core.hooksPath = scripts/githooks`,
posé par `scripts/install_hooks.sh`) — **absent d'un clone frais**, contournable depuis un autre poste
ou via l'interface web, et dont l'interdiction de `--no-verify` (Art. 1) est portée par… un hook, donc
par la **même** discipline ; (b) la CI qui **rapporte** 4 checks sans pouvoir bloquer une fusion ;
(c) la discipline de process (8 PR fusionnées, 0 commit direct depuis le bootstrap). Ces trois éléments
sont réels et utiles — ils ne sont **pas** un enforcement de plateforme, et les présenter comme tel est
un défaut bloquant.

## Alternatives considérées

**Sur le déblocage :**

- **Rendre le dépôt public** — gratuit, débloque immédiatement protection **et** rulesets. Écarté :
  publie le code, l'intégralité de la gouvernance (Constitution, PRD, maquettes, rapports d'audit) et
  **tout l'historique** ; **irréversible de fait** pour ce qui a été publié. Le bénéfice (un enforcement
  de branche sur un projet mono-développeur) ne justifie pas une exposition définitive.
- **Souscrire GitHub Pro** (~4 USD/utilisateur/mois) — débloque tout en gardant le dépôt privé, et
  aurait laissé le périmètre initial de l'US intact. Écarté : décision de **ne pas engager de coût**
  récurrent à ce stade. **Explicitement réexaminable** — c'est la voie la moins risquée des deux.
- **Statu quo : ne rien constater, ne rien outiller** — écarté : c'est **précisément le défaut
  dénoncé**. Toute la chaîne de confiance (`Certifié Prod = 🚀 OUI`, audits, gates) reposerait sur la
  seule bonne volonté des intervenants, humains **comme agents**, sans que personne ne puisse le savoir.

**Sur le découpage :**

- **Scinder en deux US** (US-00.4 = constat + outillage ; US-00.4bis = application) — écarté : l'US
  d'application serait conditionnée à une décision **non prise et sans date**, donc sa ligne SCB
  resterait en `⏳` **perpétuel**. C'est exactement l'anti-pattern déjà présent avec US-INIT-01→06
  (listées au backlog, sans ligne SCB ni Story File) ; en créer une occurrence de plus dégraderait le
  SCB comme instrument de mesure. Le report est porté par **ce texte + le point de contrôle
  `/audit-methodo`**, pas par une ligne de tableau qui pourrit.

**Sur le choix de la cible armée** (ce qui sera appliqué le jour du déblocage) :

- **`1` approbation + `enforce_admins: true`** (la configuration d'origine) — écarté : **verrouillage
  total**. L'auteur ne peut pas approuver sa propre PR, l'admin ne peut pas contourner : sur un dépôt à
  un seul collaborateur, aucun merge ne serait plus possible. État de blocage dur, pas exigence de
  rigueur.
- **`1` approbation + `enforce_admins: false`** — écarté : l'administrateur — c'est-à-dire **le seul
  contributeur** — contourne alors *tout*, checks requis inclus. Ce serait remplacer un trou
  d'enforcement par un trou d'enforcement mieux habillé.
- **Ajouter un 2ᵉ compte GitHub (ou un bot) relecteur, puis exiger `1` approbation** — **le plus
  rigoureux** : il satisfait **nativement** l'exigence de « revue humaine explicite de la PR » du track
  FULL (`TRACKS.md`) au lieu de la laisser au process. Écarté pour l'instant : seconde identité à gérer
  (accès, secrets, coût) et action humaine avant chaque merge — et surtout **cela ne débloquerait rien**
  (12). **Explicitement réexaminable** au déblocage.

## Conséquences

**Ce qui est réellement gagné (et c'est modeste) :**

- **Zéro fausse confiance produite par la factory** : `--check` ne peut plus être lu comme une
  attestation de l'état réel ; le mot « conforme » est réservé au seul chemin qui l'a mérité.
- **L'état réel devient interrogeable en une commande**, avec une issue « vérification impossible » qui
  n'est jamais un succès. Cette valeur **survit au déblocage** : une protection appliquée demain
  pourrait être désactivée après-demain — sans ce contrôle, personne ne le saurait.
- **Coût de déblocage réduit à une commande** : cible armée, arbitrages instruits, aucun dossier à
  re-instruire.
- **Le trou d'enforcement cesse d'être un impensé** : daté, étayé par des réponses brutes d'API, porté
  par un point de contrôle périodique, avec ses conditions de sortie et leurs conséquences.

**Ce qui n'est PAS gagné (à dire sans détour) :**

- **`main` n'est pas protégée. Le risque #2 d'EPIC_00 reste OUVERT.** L'US ne le ferme pas et ne peut
  pas le fermer ; elle le rend visible et suivi. EPIC_00 ne peut donc pas se clore sur ce risque.
- **Aucune barrière machine de plateforme n'est ajoutée.** Le niveau de garantie obtenu est
  « **friction + audit périodique** », pas « inviolable ». Un auditeur qui lirait « enforced » comme
  « impossible à contourner » **surestimerait la garantie** : sur ce dépôt, `enforced` signifie
  aujourd'hui « refusé par un hook local présent sur le poste du mainteneur, et rapporté par une CI qui
  ne bloque rien ».
- **`CLAUDE.md` (règle 2) et la Constitution (Art. 4) restent factuellement faux** après cette US : ils
  déclarent la règle *enforced* « par protection de branche ». L'hypothèse initiale (« US-00.4 rendra la
  déclaration vraie, il n'y a rien à corriger ») est tombée. La mise en cohérence du texte est
  **obligatoire** et relève de **US-00.5** — c'est la dernière affirmation fausse restante du corpus de
  gouvernance, et elle doit être transmise comme telle.

**Fragilités structurelles, nommées :**

1. **`TRACKS.md` exige, pour le track FULL, une « revue humaine explicite de la PR » qu'aucune barrière
   machine ne soutient** — ni aujourd'hui (rien n'est appliqué), ni après déblocage (la cible armée est
   à `0` approbation). Or **US-01.1 est en track FULL** et sera la **première US applicative
   concernée**. → **Arbitrage à poser avant le lock de US-01.1** : soit assumer et écrire que cette
   revue est une obligation de process non enforced, soit engager la voie « 2ᵉ compte relecteur », soit
   requalifier l'exigence de `TRACKS.md`. Ne pas trancher laisserait une exigence de gouvernance sans
   porteur ni barrière — la forme de dette qui a produit le présent ADR.
2. **Le niveau réel obtenu est « friction + audit périodique »**, et le vocabulaire de la factory ne
   distingue pas les deux. Tant que `CLAUDE.md` dit « enforced » pour désigner un hook local, la même
   confusion peut se reproduire sur une autre règle.
3. **Les conditions de déblocage (12) et de retour à `1` (13) dépendent d'un rituel manuel sans
   déclencheur calendaire** (`/audit-methodo` est trimestriel « ou à la demande », sans échéance
   opposable). C'est la dette la **plus susceptible de pourrir silencieusement** : entre deux passages,
   **aucune** dérive n'est détectée, et rien ne garantit qu'un passage ait lieu. Cette limite restera
   vraie **après** le déblocage.

**Dettes et vigilance :**

- **Aucune détection automatique de la dérive config ↔ dépôt réel** — contrôle manuel hors CI par
  construction (11). Une protection modifiée à la main dans l'interface GitHub (le jour où elle
  existera) ne serait détectée qu'au prochain contrôle manuel.
- **`governance.grandfathering_date`** : clé lue par aucun script, dont la description de schéma ne
  correspond à aucun comportement implémenté → à **implémenter, redocumenter ou supprimer du schéma**
  dans une US ultérieure. Laissée `null` **délibérément** (15).
- **`scripts/check_branch_protection.py` devient de fait un fichier d'enforcement** (il produit la
  preuve) sans être couvert par `.claude/hooks/protect_files.sh` : un agent pourra l'affaiblir. Son
  ajout à la liste du hook est une **action humaine** (édition de `.claude/hooks/*`), hors périmètre de
  cette US → dette à arbitrer.
- **Périmètre Art. 6 déclaré ≠ appliqué** : la Constitution (Art. 6) liste `scripts/githooks/`,
  `.claude/settings.json`, `.claude/hooks/`, `.gitleaks.toml`, `factory.config.json`,
  `scripts/factory_env.sh`, tandis que `protect_files.sh` protège en plus `scripts/install_hooks.sh`,
  `scripts/factory_sync.py`, `scripts/run_gates.py` et `*.env*` — et **ni l'un ni l'autre** ne couvre
  `.github/workflows/*` ni `scripts/apply_branch_protection.sh`. **Même classe de défaut** que celui
  corrigé ici (déclaration ≠ enforcement) → candidat `/audit-methodo`.
- **Numérotation** : **ADR-006** est conservé pour éviter la collision avec ADR-001 (stack, US-00.5),
  ADR-002..004 (pressentis US-01.1) et ADR-005 (migrations, US-00.3). Aucun ADR n'est déprécié ni
  remplacé par le présent texte (cf. Note de révision).

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables** une fois
acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien.
