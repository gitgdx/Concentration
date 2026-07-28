# ADR-007 : Protection de la branche principale — déblocage acté (dépôt public), application décidée de la cible inchangée, preuve exigée par l'effet, et extinction de la dérogation

- **Date** : 2026-07-27
- **Statut** : Accepté
- **US associée** : US-00.7
- **Remplace** : **ADR-006** — *Enforcement de la branche principale — cible armée mais NON appliquée
  (limite de plan), et vérification honnête en lecture seule* (Accepté le 2026-07-26, US-00.4)

> **Note de remplacement — pourquoi un ADR-007, et pourquoi ADR-006 n'est PAS touché.**
> ADR-006 est **`Accepté`, commité et certifié** (fusionné par les PR #10 et #11, dans le périmètre
> certifié d'US-00.4) : il est **entré en vigueur** et a effectivement gouverné le dépôt. Il est donc
> **immuable** — `docs/adr/ADR_TEMPLATE.md` est explicite : « *ne jamais éditer un ADR Accepté* ».
> **Aucune ligne d'ADR-006 n'est modifiée par le présent texte, pas même sa ligne `Statut`.**
> Le lien de remplacement est porté **ici**, par l'ADR remplaçant, et par le relibellé des renvois dans
> les documents vivants (voir décision **D11**).
>
> ⚠️ **Distinction à ne pas confondre — et c'est pour l'inscrire que ce paragraphe existe.** ADR-006
> portait lui-même une « note de révision » assumant une **réécriture en place** de sa première version.
> Cette réécriture était licite pour **une seule raison** : le fichier était alors **`untracked`**
> (`??` dans `git status`) — jamais commité, jamais audité, jamais référencé par un artefact du dépôt,
> **jamais entré en vigueur**. La clause d'immuabilité protège le **registre des décisions effectives**,
> pas un brouillon non versionné. **Cette circonstance a disparu.** Un lecteur futur ne doit donc **pas**
> conclure de l'existence de cette note qu'on réécrit les ADR de ce dépôt à volonté : le traitement
> diffère parce que **l'état du fichier diffère**. Un ADR commité se **remplace** ; il ne se corrige pas.

---

## Contexte

### Fait 1 — le blocage de plateforme est LEVÉ : le dépôt est PUBLIC

Décision **humaine** du 2026-07-27 (Constitution Art. 5 — hors pouvoir de tout agent) : le propriétaire
`gitgdx` a rendu le dépôt **public**. C'est la **voie (a)** des deux conditions de déblocage documentées
par ADR-006 décision 12. Constaté par @Architect le **2026-07-27**, en lecture seule :

| Appel | Réponse au **2026-07-26** (ADR-006) | Réponse au **2026-07-27** |
|---|---|---|
| `gh api repos/gitgdx/Concentration` | `{"private": true, "visibility": "private"}` | **`{"private": false, "visibility": "public"}`**, `permissions.admin: true`, `owner_type: User` |
| `GET …/branches/main/protection` | **403** — *Upgrade to GitHub Pro or make this repository public…* | **404** — `Branch not protected` → *disponible, simplement **non appliquée*** |
| `GET …/rulesets` | **403** — même message | **200 `[]`** → *disponible* |
| `python scripts/factory_sync.py --check-remote` | **exit 2** — « VERIFICATION IMPOSSIBLE » | **exit 1** — « DÉRIVE DÉTECTÉE — protection ABSENTE (404 + `protected == false`) », **7 écarts** |

**404 n'est pas 403**, et toute la décision tient dans cet écart : un **403** disait « *la plateforme
refuse* » ; un **404** dit « *la plateforme accepterait, la règle n'existe simplement pas encore* ».
L'outillage d'US-00.4 a **franchi seul** ce basculement, sans une ligne de changement — sa
désambiguïsation 404 (ADR-006 décision 8), déclarée « non observable in vivo » par son risque **R3**, a
produit **exactement** l'issue prévue. **R3 est clos par l'observation.**

### Fait 2 — à la date de rédaction du présent ADR, `main` n'est PAS protégée

Vérifié le **2026-07-27**, immédiatement avant d'écrire ce texte :
`GET …/branches/main` → **`{"name":"main","protected":false}`** · `GET …/branches/main/protection` →
**404** · `--check-remote` → **exit 1**. **Cet ADR décide l'application ; il ne l'atteste pas.**
L'application est la tâche **T8** d'US-00.7, classée **[confirmation humaine explicite]** : un agent ne
l'exécute pas. L'attestation de l'état appliqué ne sera **jamais** ce fichier — elle sera
`reports/US-00.7/applied_state/` (réponses brutes datées) et rien d'autre. Toute phrase du présent texte
portant sur l'état appliqué est donc écrite au **futur conditionné**, délibérément. *(Le titre lui-même
dit « application décidée », non « cible appliquée » : c'est la règle cardinale du projet — ne rien
affirmer qui ne soit pas encore acquis.)*

### Fait 3 — la cible n'a pas à être rediscutée : elle est inchangée, complète, et vérifiée

`factory.config.json` (source unique, **non modifié** par US-00.7) porte exactement la cible arbitrée par
ADR-006 décision 3. Vérifié le 2026-07-27 par `python scripts/factory_sync.py --emit-branch-protection` :
payload de **8 clés**, `set(payload) == MAPPED_TOP_KEYS` → **`True`** ·
`required_pull_request_reviews` **PRÉSENT** avec `required_approving_review_count: 0` ·
`enforce_admins: true` · `required_conversation_resolution: true` · `allow_force_pushes: false` ·
`allow_deletions: false` · `required_linear_history: false` · `restrictions: null` ·
`required_status_checks.strict: true` sur **4** contextes. **Il n'y a donc aucun arbitrage de cible à
reprendre** : ce que le déblocage change n'est pas *quoi* appliquer, c'est *si l'on peut* appliquer.

### Fait 4 — le corpus est redevenu FAUX, en sens inverse, et c'est ce qui rend l'US urgente

ADR-006 a passé une US entière à éliminer un défaut d'une classe précise : **un document de gouvernance
qui affirme un état que l'API contredit**. Le déblocage a réintroduit ce défaut **à l'identique, signe
retourné** : `CLAUDE.md` — injecté à **chaque** démarrage de session, lu par tout agent et tout auditeur
avant de travailler — affirme encore une impossibilité de plateforme ; `docs/epics/EPIC_00-fondations.md`
porte un risque #5 « **NON REFERMABLE SUR CE PLAN** » et un critère de clôture « **IMPOSSIBLE À COCHER
SUR CE PLAN** » ; `docs/GIT_PROTECTION.md`, `.github/workflows/ci.yml`,
`scripts/apply_branch_protection.sh`, `scripts/githooks/pre-push` et 4 autres artefacts vivants disent
« NON APPLICABLE », « NE PAS EXÉCUTER », « 403 de plan ». Le balayage inverse par motif du 2026-07-27
recense **11 artefacts vivants** concernés — dont **trois créés par US-00.4 elle-même**. Une factory dont
le document de démarrage affirme un blocage inexistant produit la **même fausse confiance** qu'une
factory qui affirme un enforcement inexistant, et elle est **plus pernicieuse** : elle décourage
d'appliquer une protection devenue gratuite, et elle **légitime une dérogation dont le motif a disparu**.

### Fait 5 — historique constaté, sans réécriture (relevé de nouveau, pas recopié)

`git log --first-parent --oneline origin/main` au 2026-07-27 : **10 fusions de PR** (#1, #3, #4, #5, #6,
#7, #8, #9, #10, #11) et **exactement 2 commits directs** — les commits de bootstrap `0a2e5ab`
(`chore(init)`) et `6483022` (`chore(governance)`). **Aucun commit direct après le bootstrap** — le
constat d'ADR-006 décision 15 reste **intégralement vrai**, avec deux fusions de plus. *(Nota conservé :
`git log --merges` renvoie davantage d'entrées, dont des fusions internes à des branches de travail —
seule la lecture **first-parent** prouve l'absence de commit direct.)*

### Fait 6 — le dépôt reste mono-collaborateur : la condition de retour à `1` approbation n'est pas atteinte

`GET …/collaborators` au 2026-07-27 → **un seul** compte en écriture (`gitgdx`, `push: true`). Le réglage
`required_approving_review_count: 0` reste donc ce qu'ADR-006 décision 13 en a fait : **daté et
conditionnel**, jamais une norme. **Ajouter un collaborateur ne débloquait rien** (ADR-006 décision 12) —
cet énoncé était exact et le reste ; c'est la **visibilité** qui a débloqué, comme annoncé.

---

## Renversements — ADR-006 énoncé par énoncé

> **Pourquoi cette section existe** : affirmer le nouvel état ne suffit pas. Un audit à contexte frais
> qui lira ADR-006 (immuable, donc toujours lisible tel quel) doit pouvoir mesurer le **delta** sans
> reconstituer l'histoire. Chaque ligne cite ADR-006, date le renversement et nomme ce qui l'établit.
>
> ⚠️ **Colonne « Effectif » — lire impérativement.** Certains renversements sont **acquis par le simple
> constat** du 2026-07-27 ; d'autres ne le seront **qu'après l'application (T8)**, qui **n'a pas encore
> eu lieu**. Confondre les deux serait reproduire, dans le texte censé le corriger, le défaut d'origine.

| # | Énoncé d'ADR-006 (cité) | Établi par ADR-007 | Effectif |
|---|---|---|---|
| 1 | Titre : « cible **armée** mais **NON appliquée** (**limite de plan**) » | La **limite de plan a disparu** ; la cible est **décidée applicable** et sera appliquée à T8 depuis la source unique | ⏳ **T8** pour l'application · ✅ **acquis** pour la disparition de la limite |
| 2 | Fait 2 : « **les deux** mécanismes d'enforcement de branche sont refusés **à l'identique** » (403 sur protection **et** rulesets) | **Aucun** n'est plus refusé : protection → **404** *(non protégée)*, rulesets → **200 `[]`** *(disponibles)* | ✅ **acquis le 2026-07-27** |
| 3 | Fait 2 : « **Aucune** commande, aucun script, aucun réglage ne peut protéger `main` sur ce dépôt **en l'état** » | L'état a changé : **une** commande le peut — `sh scripts/apply_branch_protection.sh gitgdx/Concentration` | ✅ **acquis** (capacité) · ⏳ **T8** (exercice) |
| 4 | Décision 3 : « Elle **n'est pas active** : `apply_branch_protection.sh` **échouerait en 403** ; il est prêt et **conditionné au déblocage**, **jamais “à exécuter”** » | Le script devient la **voie normale de (ré-)application** ; il n'échouerait plus en **403** | ⏳ **T8** — l'appel n'a pas encore été émis |
| 5 | Décision 4 : « **aucun `PUT` n'a jamais été accepté** par la plateforme, donc le **comportement réel** de la règle reste **non démontré** » — « armée » = validation **logique**, **pas fonctionnelle** | La validation **fonctionnelle** est **exigée** : `PUT` accepté (AC-1), **3 refus serveur** (AC-3), **1 refus de fusion administrateur inclus** (AC-4) | ⏳ **T8 → T11** — **rien n'est démontré à ce jour** |
| 6 | Décision 1 : « **Ne pas** souscrire GitHub Pro et **ne pas** rendre le dépôt public » | L'humain a **choisi la voie (a) — dépôt public — le 2026-07-27** (Art. 5). L'encadrement de décision d'ADR-006 est **caduc** | ✅ **acquis le 2026-07-27** |
| 7 | Décision 2 : « La branche principale **reste NON protégée** après cette US » · « Le **risque #2 d'EPIC_00 demeure OUVERT** » · EPIC_00 : « **RISQUE #2 MATÉRIALISÉ *ET NON REFERMABLE SUR CE PLAN*** » | Le risque est **refermable** — il devient **CLOS**, daté et adossé à `reports/US-00.7/`, et le critère de clôture « Protection de branche vérifiée » devient **cochable** | ⏳ **T8/T9** — clos **par la preuve**, pas par le présent texte |
| 8 | Démenti ⛔ : « `main` **n'est pas protégée** — `"protected": false` reste l'état réel » | `"protected": true` deviendra l'état réel, prouvé par réponse brute datée | ⏳ **T9** — `protected` vaut **`false`** à la date de cet ADR |
| 9 | Démenti ⛔ : « les 4 status checks sont **rapportés, pas requis** : une fusion avec CI rouge **reste possible** » | Les 4 contextes deviennent **REQUIS** ; aucune fusion possible sans 4 verts | ⏳ **T8**, démontré **T11** |
| 10 | Démenti ⛔ : « `enforce_admins` **n'est pas en vigueur** ; il n'y a pas de bypass à supprimer puisqu'il n'y a pas de règle » | `enforce_admins: true` entre en vigueur : **l'auteur de la règle ne la contourne pas** | ⏳ **T8**, démontré **T11(d)** |
| 11 | Démenti ⛔ : « **aucun refus serveur n'est démontré**, et **aucun ne sera exigé** par cette US … le **test négatif serveur est reporté** au déblocage » | Le report **s'exécute** : push direct, force-push et suppression **refusés par le serveur**, depuis un clone **sans hooks**, **sans `--no-verify`** | ⏳ **T10** — **strictement interdit avant T9** *(avant, ces commandes **réussiraient**)* |
| 12 | Démenti ⛔ : « Ce qui protège `main` aujourd'hui est un **filet de discipline**, pas une contrainte de plateforme » | Devient : **contrainte de plateforme** (PR obligatoire, 4 checks requis, `enforce_admins`) **+** filet de discipline **résiduel** (hook `pre-push`, toujours utile, **toujours absent d'un clone frais**) | ⏳ **T8** |
| 13 | Conséquences : « `CLAUDE.md` (règle 2) et la Constitution (Art. 4) **restent factuellement faux** … La mise en cohérence du texte est **obligatoire** et relève de **US-00.5** » | Les deux textes deviennent **factuellement VRAIS sans être édités** → la correction transmise « obligatoire » à US-00.5 devient **SANS OBJET**, et le périmètre d'US-00.5 s'en trouve **réduit** | ⏳ **T8** ; consigné **T22** — ⛔ US-00.5 ne doit **pas** « corriger » un texte redevenu exact |
| 14 | Conséquences : « Le niveau de garantie obtenu est “**friction + audit périodique**”, pas “inviolable” » | Devient « **contrainte de plateforme + audit périodique** » — **et toujours pas “inviolable”** : la règle reste **révocable** par un administrateur, **sans détection automatique** | ⏳ **T8** — la **seconde moitié** de l'énoncé reste **vraie et conservée** |
| 15 | Décision 7 : « exit 2 … couvre le **403 de plan** (**l'issue réelle sur ce dépôt** au 2026-07-26) » | L'issue réelle est **exit 1** aujourd'hui, et **exit 0** attendu après T8. Le **403 reste un cas légitime** de l'outil : il **redeviendrait** réel si le dépôt repassait en privé — ⛔ **ne rien retirer du mapping HTTP** | ✅ **acquis** (exit 1 observé) · ⏳ **T9** (exit 0) |
| 16 | Alternatives : « Rendre le dépôt public … **Écarté** : … le bénéfice … **ne justifie pas une exposition définitive** » | Arbitrage **renversé par l'autorité humaine** (Art. 5), qui est la seule compétente. ⚠️ **L'analyse de coût d'ADR-006 n'est pas invalidée pour autant** : l'exposition **est** définitive — voir Conséquences §« Le dépôt est PUBLIC » | ✅ **acquis le 2026-07-27** |
| 17 | Alternatives / découpage : « l'US d'application serait conditionnée à une décision **non prise et sans date**, donc sa ligne SCB resterait en `⏳` **perpétuel** » | La décision **est prise** et **datée** → US-00.7 existe, avec ligne SCB et Story File. Le motif de refus du découpage a disparu ; **le refus lui-même était correct à sa date** | ✅ **acquis le 2026-07-27** |

**Un énoncé d'ADR-006 se renverse à moitié, et il faut le dire ainsi** : sa fragilité n° 1 (« `TRACKS.md`
exige pour le track FULL une revue humaine explicite de la PR qu'**aucune barrière machine** ne
soutient — **ni aujourd'hui** (rien n'est appliqué), **ni après déblocage** (la cible armée est à `0`
approbation) »). La première branche tombe ; **la seconde reste exacte**. Après T8, la revue humaine du
track FULL demeure une obligation **de process, non enforced** — et c'est un **arbitrage toujours dû
avant le lock d'US-01.1**. US-00.7 y répond pour elle-même par un renforcement de track (revue humaine
explicite de sa propre PR, DoD 34) : c'est un **précédent de process**, **pas** une barrière machine.

---

## Ce qui est CONSERVÉ d'ADR-006 — repris, non rediscuté

Les décisions suivantes sont **maintenues en vigueur telles quelles** par le présent ADR. Elles n'ont pas
été affectées par le déblocage, et le remplacement d'ADR-006 ne les abroge **pas** :

1. **Décision 5 — `required_pull_request_reviews` reste PRÉSENT avec `0`.** Jamais supprimé du payload :
   retirer l'objet désactiverait « Require a pull request before merging » — **`0` approbation ≠ pas de
   PR exigée**. `emit_branch_protection()` l'émet toujours ; ⛔ ne jamais « optimiser » son omission
   quand le compteur vaut `0`. Vérifié le 2026-07-27 : présent dans le payload de 8 clés. Le retirer
   ferait tomber **AC-3 et AC-4** d'US-00.7 en même temps que la garantie.
2. **Décision 6 — la protection est *générée* depuis la configuration, jamais saisie à la main**, y
   compris dans un repli `curl` et y compris en cas d'échec. Toute divergence future se corrige en
   **ré-appliquant depuis la config**, **jamais** en alignant la config sur l'état constaté.
3. **Décision 7 — l'outillage de vérification en lecture seule à trois issues honnêtes** :
   **exit 0** = strictement conforme (**seul** chemin où le mot « conforme » est autorisé) · **exit 1** =
   absente ou divergente, un écart par ligne · **exit 2** = « **VERIFICATION IMPOSSIBLE — ce n'est PAS un
   succès** ». La séparation des pouvoirs est conservée : `apply_branch_protection.sh` **écrit** (`PUT`),
   `check_branch_protection.py` **lit** (`GET`) et n'acquiert **aucun** chemin d'écriture.
4. **Décision 8 — désambiguïsation obligatoire du 404** (croisement avec `GET …/branches/{b}` et son
   champ `protected`). C'est le mécanisme qui vient d'être **validé in vivo** ; il est **plus** utile
   après le déblocage, pas moins : c'est lui qui distinguera « protection supprimée » de « droits
   insuffisants ».
5. **Décision 9 — le mapping PUT → GET est explicite** : booléens au `PUT` contre objets
   `{"enabled": bool}` au `GET` ; `restrictions: null` au `PUT` ↔ clé **absente** du `GET`
   (**absence = conforme**). ⛔ Ne rien « ajuster » dans ce mapping pour forcer un vert.
6. **Décision 10 — `--check` reste une vérification DOCUMENTAIRE**, explicitement annoncée comme telle,
   gate CI bloquant, et **ne peut pas** être lue comme une attestation de l'état réel. Sa limite
   demeure : elle compare la config au **fichier de workflow**, jamais au libellé que GitHub **rapporte**.
7. **Décision 11 — le contrôle distant reste HORS CI, par construction.** `GET …/protection` exige des
   droits **admin** que le `GITHUB_TOKEN` de la CI n'a pas ; l'y ajouter produirait un faux rouge
   permanent ou la tentation de le rendre non bloquant — donc décoratif. Reste une **commande
   d'administration manuelle**, vérifiée par un **contrôle négatif** (aucune référence à
   `--check-remote` dans `.github/workflows/`). **Le déblocage ne change rien à cet argument** : la
   contrainte porte sur les **droits du jeton de CI**, pas sur le plan.
8. **Décision 13 — condition vérifiable de retour à `1` approbation** : dès qu'un **2ᵉ collaborateur**
   obtient l'accès en écriture (`GET …/collaborators` ≥ 2 comptes en écriture), une US remet
   `required_approving_review_count: 1`. Vérifié le 2026-07-27 : **1 seul** compte. `0` est un réglage
   **daté et conditionnel**, **pas une norme** — il devient une **anomalie** dès le 2ᵉ collaborateur.
9. **Décision 14 — point de contrôle périodique dans `/audit-methodo`** : **conservé, jamais supprimé**,
   et **réorienté** — son objet n'est plus « porter la dette de l'absence de protection » mais
   **surveiller sa persistance** : `--check-remote` (exit 0 attendu), **visibilité inchangée**,
   correspondance des **4 libellés rapportés**, condition de retour à `1`. Sans porteur périodique, la
   révocation silencieuse ne serait surveillée par personne.
10. **Décision 15 — ni réécriture d'historique, ni `EVT_WORKFLOW_VIOLATION` rétroactif.** Les commits
    `0a2e5ab` et `6483022` sont **antérieurs à tout enforcement** et ont **créé** les règles en
    question : les qualifier de violations serait factuellement inexact. **Cette exemption est reprise
    et portée par le présent texte**, pas par `governance.grandfathering_date` (clé **lue par aucun
    script**, laissée `null` délibérément — la renseigner serait un no-op dont la sémantique documentée
    masquerait la dette US-INIT-01→06).
11. **Décision 16 — les certifications d'US-00.1 / 00.2 / 00.3 / 00.4 restent valides** : elles reposent
    sur des audits à contexte frais, des gates réellement exécutés et des preuves archivées,
    **indépendamment** de la protection de branche. Elles ne sont **pas** rétroactivement renforcées par
    le présent ADR ; en particulier, le test négatif d'US-00.1 n'a **jamais** été exécuté, et cela reste
    vrai.

---

## Décision

### D1 — Appliquer la cible **inchangée**, depuis la source unique, sous confirmation humaine explicite

La cible d'ADR-006 décision 3 est **appliquée telle quelle** : `required_approving_review_count: 0` **+**
`enforce_admins: true`, `required_conversation_resolution: true`, `allow_force_pushes: false`,
`allow_deletions: false`, `required_linear_history: false`, `strict: true` sur les **4** contextes,
`restrictions: null`. **Aucune valeur n'est modifiée** — `factory.config.json` n'est **pas** touché par
US-00.7 : ce serait rouvrir un arbitrage déjà tranché.

**Modalité, non négociable** : application **exclusivement** par
`sh scripts/apply_branch_protection.sh gitgdx/Concentration`, consommant le payload **généré** par
`factory_sync.py --emit-branch-protection`. ⛔ **Interdits, y compris en cas d'échec** : JSON écrit à la
main · `gh api -X PUT --input <fichier bricolé>` · écran *Settings → Branches* · cible **amputée** « pour
faire passer l'appel » · retrait de `required_pull_request_reviews`. **En cas d'échec (403, 422, libellé
refusé)** : réponse archivée **brute**, **aucun contournement**, l'US **s'arrête**, `EVT_DEV_BLOCKER`.
*Mieux vaut une US non livrée qu'une protection appliquée hors de la source unique.*

**État à la date du présent ADR : NON appliquée** (Fait 2). L'application est **T8**, classée
**[confirmation humaine explicite]** : ⛔ **un agent ne l'exécute pas, même sur demande implicite** — il
prépare, vérifie les préalables et archive.

### D2 — La preuve exigée est celle de l'**effet**, pas celle de l'existence

`"protected": true` prouve l'**existence** d'une règle ; il ne prouve **rien** de son effet. Sont donc
exigés, et l'US n'est pas livrable sans eux : **3 refus serveur** (push direct, force-push, suppression)
depuis un **clone jetable sans hooks** et **sans `--no-verify`** (Art. 1), et **1 refus de fusion**
opposé au compte **administrateur** sur la PR d'US-00.7. C'est la **validation fonctionnelle** qu'ADR-006
décision 4 déclarait explicitement hors d'atteinte.

⛔ **Ordre de sûreté imposé, non une préférence de style** : le test négatif est **interdit avant** que
l'état appliqué ne soit prouvé — **avant l'application, ces trois commandes RÉUSSIRAIENT** et
modifieraient `main` hors PR. Séquence : correctif de l'instrument → vérification des libellés + plan de
retour arrière → application → preuves d'état → **puis** preuve par l'effet.

### D3 — La dérogation `EVT_WAIVER_GRANTED` d'US-00.4 est **SANS OBJET** — extinction **documentaire**, et cette modalité est une dette

La dérogation tracée le **2026-07-26** (`EVT_WAIVER_GRANTED`, US-00.4, Constitution Art. 5) portait sur
« **ni upgrade GitHub Pro, ni passage du dépôt en public** », avec pour conséquence assumée que
« la protection de branche côté serveur reste **INAPPLICABLE** ». **L'humain a choisi la voie (a) —
dépôt public — le 2026-07-27.** Son **motif a disparu** : la dérogation est **ÉTEINTE / SANS OBJET**.

- **Consignation exigée** aux **trois** emplacements qu'un audit à contexte frais lira nécessairement —
  `CLAUDE.md` (état courant), `docs/GIT_PROTECTION.md`, `docs/epics/EPIC_00-fondations.md` (risque #5) —
  **datée** et avec **renvoi à l'événement d'origine**.
- ⛔ **La trace est append-only** : l'événement du 2026-07-26 n'est **ni supprimé, ni édité, ni
  réécrit**. **On éteint une dérogation ; on ne l'effface pas.**
- ⚠️ **Aucun événement du catalogue ne permet de l'éteindre.** Vérifié le 2026-07-27 :
  `scripts/events_catalog.json` porte **25 événements** (+ 4 alias dépréciés) et **aucun** de
  révocation, extinction ou expiration de dérogation. *(Nota : le Story File d'US-00.7 en annonce 26 —
  décompte inexact, sans conséquence sur la conclusion, qui est l'**absence** d'un tel événement. Signalé
  plutôt que recopié.)*
- **Modalité retenue** : la **consignation documentaire fait foi**, **complétée** par une mention
  explicite de l'extinction dans le `rationale` de l'`EVT_DOCS_UPDATED` d'US-00.7, afin qu'un lecteur de
  la **seule trace** la voie. **En ajouter un au catalogue modifierait la machine à états** — décision
  structurante, qui exigerait son propre ADR : **hors périmètre**.
- 🔴 **Cette absence est nommée comme une DETTE DU SYSTÈME DE TRAÇABILITÉ, et elle est structurelle** :
  une dérogation y est **irrévocable par construction**. Un audit qui ne lirait que la trace verrait un
  `EVT_WAIVER_GRANTED` **sans contrepartie** et pourrait croire l'exception encore active. La mention
  dans un `rationale` est une **convention non enforced** (champ libre, non typé, non validé par
  `validate_trace.py`) : elle **réduit** le risque, elle ne le supprime pas. Candidat `/audit-methodo`,
  **même famille** que « émetteurs d'événements déclarés mais non enforced ».

### D4 — Protection **classique** conservée ; les rulesets sont écartés **par sobriété**, pas par indisponibilité

Les rulesets sont désormais disponibles (**200 `[]`**). Ils **ne sont pas retenus** : la cible, le
générateur (`emit_branch_protection()`), l'applicateur (`apply_branch_protection.sh`), le comparateur
(`check_branch_protection.py`, avec son mapping PUT → GET et ses **9 fixtures** versionnées) sont **déjà
écrits, audités et certifiés** pour la protection classique. Y basculer exigerait de réécrire les quatre
et de refaire les fixtures, **sans aucun gain fonctionnel** sur le périmètre visé. **Réexaminable** si un
besoin apparaît (acteurs de contournement nommés, versionnement des règles, motifs multi-branches) —
et alors par **ADR dédié**, jamais par dérive silencieuse.

### D5 — Tout l'édifice est **conditionné à la visibilité publique**, et c'est écrit partout

Si le dépôt **repassait en privé** sur ce plan : retour du **403**, protection **indisponible**,
**dérogation ROUVERTE**, et le présent ADR devrait être remplacé à son tour. Toute section d'un livrable
qui affirme l'état appliqué **porte cette condition**. Omettre cette conditionnalité remplacerait une
affirmation périmée par une autre — **le défaut exact que cette US corrige**. La surveillance de cette
condition est portée par le point de contrôle réorienté (**conservé** — ADR-006 décision 14).

### D6 — Le correctif NB-1 est un **préalable de la preuve**, et un **progrès strict, pas une fermeture**

L'`exit 0` du comparateur est utilisé par US-00.7 **comme preuve d'un état de sécurité**. Le chemin
`exit 0` doit donc être sûr **avant** d'être invoqué : `_guard_actual` filtre la réponse réelle par la
constante **statique** `MAPPED_TOP_KEYS`, si bien qu'une clé **mappée mais absente de la cible** était
**doublement sautée** — ni comparée, ni signalée → **exit 0 « conforme »**. Correctif imposé et **borné à
3 lignes** (`MAPPED_TOP_KEYS & set(expected)`, plus la signature et le site d'appel — `_guard_actual`
n'a pas accès à `expected`). ⛔ Rien d'autre : pas de garde sur les sous-objets, pas de `selftest`, pas
de nouveau drapeau.

**NB-1bis — résidu OUVERT, mesuré, à ne pas enjoliver.** Après correctif : une clé absente de la cible
dont la valeur réelle est **ACTIVE** est **nommée** et **interdit l'exit 0** (corrigé) ; mais si sa
valeur est **NEUTRE au sens de la doctrine** (`false` / `{"enabled": false}` / absente), elle est
**seulement nommée** `[IGNORÉ — NEUTRE]` et **l'exit 0 subsiste** — et si elle est **absente des deux
côtés**, elle **n'est pas même nommée**. Or ces valeurs-là sont des **relâchements réels** :
`enforce_admins: {"enabled": false}` **autorise le bypass administrateur**, et
`required_pull_request_reviews` **absent** signifie **aucune PR exigée**. **La doctrine de neutralité
assimile à tort « valeur fausse » et « inerte »** : elle est juste pour une clé additive d'API, fausse
pour une clé **dont la permissivité est le défaut**. **Correctif identifié, hors périmètre** : contrôle
de **complétude de la cible** dans `_guard_mapping()` (`MAPPED_TOP_KEYS - set(expected)` non vide →
exit 2 — *une cible incomplète ne peut pas servir de référence*), à porter par une US de dette **avec le
`selftest` CI**. **Contrôle compensatoire qui rend l'`exit 0` fiable aujourd'hui** :
`set(payload) == MAPPED_TOP_KEYS` → **`True`** (8 clés, vérifié le 2026-07-27) — la cible **n'est pas
amputée**, donc le résidu **n'est pas atteignable**. Il le deviendrait dès qu'une clé serait retirée de
`factory.config.json` (fichier **Art. 6**, donc **action humaine**). ⛔ **Ne pas écrire que NB-1 « ferme
le trou ».**

### D7 — Vocabulaire : ce qui pourra être affirmé, et ce qui restera interdit

**Autorisé après T8, et rien de plus** : « **4 gates requis + PR obligatoire + `enforce_admins`, à la
date de la mesure, pour les contextes effectivement rapportés et pour l'acteur employé, révocable par un
administrateur sans détection automatique** ». ⛔ **Interdits dans tout livrable** : « inviolable » ·
« tout est enforced » · « chaîne de confiance désormais sûre » · « impossible à contourner ». Ne sont
**pas** prouvés : le comportement pour un autre acteur, un jeton d'application (GitHub App), une action
via l'interface web, une PR issue d'un **fork**, une PR **réouverte**, ni la **persistance** de l'état.
La **sur-affirmation est le risque n° 1 de rédaction** de cette US : elle reproduirait le défaut
d'ADR-006 **en sens inverse**.

### D8 — Aucune dette n'est close par effet de bord

Sont **CLOS**, chacun avec sa preuve : **R3** d'US-00.4 (chemin 404 réel observé — ✅ déjà acquis) ·
**écart de preuve n° 3** d'US-00.4 (exit 0 observé in vivo — ⏳ T9) · **risques #2 et #5 d'EPIC_00**
(⏳ T8/T9) · dette **#1** de `GIT_PROTECTION.md` · dette **#6** (l'en-tête généré « Status check requis »
devient **exact** — l'édition Art. 6 qu'elle exigeait n'a **plus lieu d'être**). **Tout le reste reste
ouvert** et doit être **re-consigné**, pas silencieusement enterré (voir Conséquences).

### D9 — Portée bornée : aucun artefact daté ou certifié n'est réécrit

Sont **référencés, jamais falsifiés** : Story File et `reports/**` d'US-00.4, Story File d'US-00.1,
`docs/trace/**`, `reports/US-00.3/**`, `PROJECT_LOG.md` — et **ADR-006** (D11). Ils étaient **exacts à
leur date** ; on écrit « constat du 2026-07-26 — **levé le 2026-07-27** », on ne les corrige pas. Seule
exception cadrée : `tests/fixtures/US-00.4/README.md`, **matériel de test vivant** d'une US certifiée →
**historisation strictement ADDITIVE** (encadré daté **en tête**), ⛔ sans réécrire une ligne existante.
La preuve manquante au critère de test #6 d'**US-00.1** sera fournie par le refus de fusion, **sans
éditer US-00.1** : le véhicule de sa mise à jour est un arbitrage @PO — @Architect **recommande la
requalification tracée** plutôt qu'une ré-ouverture de cycle.

### D10 — Le risque de **verrouillage total** est traité **avant** d'être pris

Avec `enforce_admins: true`, un contexte requis **jamais rapporté** (libellé divergent d'un seul
caractère, ou workflow qui ne se déclenche pas) rend **toute PR infusionnable, administrateur inclus**.
**Préalables bloquants** : vérification des **4 libellés caractère par caractère** (points de code
imprimés — vérifié le 2026-07-27 : `U+1F510`, `U+1F4CB`, `U+1F4F1`, **aucun `U+FE0F`**, `ç`/`é`
précomposés **NFC**), **plus** le contrôle des libellés **effectivement rapportés** par GitHub sur la PR
(`gh pr checks`) — ce que `--check` ne peut pas faire —, **plus** un **plan de retour arrière écrit et
commité avant tout `PUT`**. **Mécanisme de sortie, à comprendre une fois pour toutes** :
`enforce_admins: true` interdit le **contournement** (*bypass*), **pas l'administration** — un
administrateur peut **éditer** ou **supprimer** la règle. Ce n'est **pas** un contournement ; c'est la
porte de sortie, et elle existe toujours. Séquence imposée : `DELETE` **tracé** → correction dans la
**source unique** → **ré-application depuis la config** → `--check-remote` **exit 0** → consignation
(PROJECT_LOG + `EVT_DEV_BLOCKER`). ⛔ **Jamais** : `gh pr merge --admin`, retrait d'un contexte pour
débloquer, correction du libellé dans l'interface, alignement de la config sur l'état constaté.

### D11 — ADR-006 n'est pas touché ; le risque de « référence à sens unique » est mitigé par relibellé

⛔ **Aucune édition d'ADR-006, pas même sa ligne `Statut`.** Le lien de remplacement n'étant donc pas
lisible depuis ADR-006, la mitigation est **obligatoire et vérifiable** : **aucun document vivant ne doit
router un lecteur vers ADR-006 comme décision courante**. Chaque renvoi subsistant dans `CLAUDE.md`,
`docs/GIT_PROTECTION.md`, `docs/SQUAD_GUIDE.md`, `.claude/commands/*`, `scripts/*` et
`.github/workflows/*` est **relibellé « ADR-006 *(remplacé par ADR-007)* »** ou redirigé vers ADR-007.
*(C'est le prix de l'immuabilité, et il est assumé : mieux vaut un registre historique intact et un
routage discipliné qu'un registre retouché.)*

---

## Alternatives considérées

- **Ne rien appliquer et rester sur la dérogation (statu quo).** Écarté, et pour un motif dirimant : le
  **motif de la dérogation n'existe plus**. La maintenir consisterait à couvrir par une exception de
  gouvernance un trou d'enforcement désormais **gratuitement** refermable — et le **corpus resterait
  faux** : `CLAUDE.md`, injecté à chaque session, continuerait d'annoncer un **403** que l'API démentit,
  `EPIC_00` resterait bloquée sur un critère déclaré « impossible à cocher » alors qu'il est cochable, et
  la règle 2 resterait fausse **sans nécessité**. C'est **exactement** la classe de défaut qu'ADR-006 a
  été écrit pour éliminer ; la reproduire volontairement, sachant, serait pire que l'avoir subie.
- **Rulesets au lieu de la protection classique.** Désormais **disponibles** (200 `[]`) — l'argument
  d'indisponibilité d'ADR-006 est tombé pour eux aussi. Écarté **par sobriété** : cible, générateur,
  applicateur et comparateur (avec mapping PUT → GET et fixtures) sont **déjà écrits et certifiés** pour
  la protection classique ; migrer coûterait quatre réécritures et un re-audit **sans gain fonctionnel**
  ici. Réexaminable par ADR dédié (D4).
- **Repasser en privé et souscrire GitHub Pro.** Écarté : la publication **a eu lieu** et est
  **irréversible pour ce qui a été publié** — repasser en privé ne « dé-publierait » rien (forks, caches,
  archives et indexations existent déjà) ; on paierait un abonnement **sans annuler l'exposition**, tout
  en rouvrant le 403 pendant la transition. ⚠️ **Reste néanmoins la seule voie** si l'exposition publique
  devenait un jour inacceptable pour un **contenu futur** : ce que la publication a fixé, c'est le
  **passé**, pas l'avenir. À réexaminer **par ADR** si le projet devait accueillir du contenu non
  publiable — pas au détour d'une US.
- **Appliquer une cible allégée pour « limiter le risque de verrouillage »** (par exemple
  `enforce_admins: false`, ou 3 contextes au lieu de 4). Écarté : `enforce_admins: false` rendrait la
  règle contournable par **le seul contributeur du dépôt** — « remplacer un trou d'enforcement par un
  trou d'enforcement mieux habillé » (ADR-006). Retirer un contexte pour se rassurer, c'est aligner la
  cible sur la peur plutôt que sur la décision. Le risque de verrouillage se traite par **vérification
  préalable + plan de retour arrière** (D10), **pas** par affaiblissement.
- **`1` approbation, ou un 2ᵉ compte relecteur.** Non rediscuté : arbitrage d'ADR-006 (décisions 3 et
  13), **conservé**. `0` reste **conditionnel** au caractère mono-collaborateur, vérifié encore le
  2026-07-27, et redevient une **anomalie** dès le 2ᵉ compte en écriture.
- **Ajouter un `EVT_WAIVER_REVOKED` au catalogue d'événements** pour éteindre proprement la dérogation.
  Écarté **ici** : cela modifierait la **machine à états** de la traçabilité — décision structurante qui
  exige son **propre ADR** et son propre cycle. La dette est **nommée** (D3) plutôt que traitée à la
  sauvette dans une US dont l'objet est autre.

---

## Conséquences

### Ce qui est gagné — et c'est substantiel, pour la première fois

> ⚠️ **Lire au futur.** Tout ce paragraphe est **conditionné à l'application (T8)**, qui **n'a pas encore
> eu lieu** à la date de cet ADR. Les verbes au présent y décrivent l'**effet de la décision**, jamais un
> état constaté ; les seules attestations d'état sont les fichiers de `reports/US-00.7/`. Seul le
> **premier acquis** est déjà réel : le chemin **404** observé (R3 clos).

- **La règle dure 2 de `CLAUDE.md` devient VRAIE sans être éditée** (« jamais de commit/push sur la
  branche principale — *enforced : … + protection de branche* »), et avec elle l'**Art. 4** de la
  Constitution (« gates qualité **requis par la protection de branche** »). **La première des six règles
  dures dont l'enforcement était fictif cesse de l'être.** Conséquence directe : le périmètre d'US-00.5
  est **réduit** — ⛔ elle ne doit **pas** « corriger » un texte redevenu exact.
- **Les risques #2 et #5 d'EPIC_00 deviennent CLOS**, et le critère de clôture « Protection de branche
  vérifiée » — écrit « **IMPOSSIBLE À COCHER SUR CE PLAN** » — devient **cochable**. **EPIC_00 redevient
  complétable** (après US-00.5 et US-00.6).
- **L'outillage d'US-00.4 obtient sa validation fonctionnelle** : `exit 0` observé **in vivo** et non
  plus sur fixture (écart de preuve n° 3 refermé), après un chemin **404 réel** déjà observé (R3 clos).
  Un outil de preuve qui n'avait jamais rencontré la réalité l'a rencontrée **deux fois**.
- **La preuve qui manquait au critère de test #6 d'US-00.1** (« job `secrets-scan` rouge → merge
  **empêché par la protection de branche** ») sera fournie — `🔐 Secrets scan (gitleaks)` étant l'un des
  4 contextes requis — **sans éditer une ligne d'US-00.1**.
- **L'effet devient démontrable, et non plus déclaré** : c'est la première fois dans l'histoire de ce
  dépôt qu'un refus opposé par le **serveur** pourra être archivé.

### Ce qui est perdu ou contraint — **R-4, contrainte permanente**, à annoncer avant de l'imposer

**À compter de l'application, toute PR vers `main` exige simultanément** : 4 contextes **verts**, branche
**à jour** (`strict: true`), **zéro discussion non résolue**, **nom de branche conforme** — **sans bypass
administrateur**. Concrètement :

- 🔴 **Toute branche hors `^feat/US-[0-9]+\.[0-9]+.*$` rend sa PR DÉFINITIVEMENT infusionnable.**
  `check-branch-name` (`.github/workflows/branch-naming.yml`) sort en `exit 1` → contexte requis
  **rouge**. **`chore/`, `docs/`, `hotfix/` deviennent impossibles à fusionner.** Cela touche
  directement le **track QUICK**, dont les hotfix reposent sur des noms libres, et tout commit de
  gouvernance qu'on aurait porté sur une branche `chore/`. **Conséquence assumée** : la convention de
  nommage cesse d'être une recommandation et devient une **condition de fusion**. À documenter comme une
  **règle**, pas à découvrir comme une panne.
- ⚠️ **Corollaire du dépôt public, à ne pas manquer** : le contrôle porte sur `github.head_ref` — donc
  **une PR issue d'un fork** (désormais possible pour n'importe qui) dont la branche ne suit pas ce
  motif est **structurellement infusionnable**. Le dépôt est ouvert aux contributions **en lecture et en
  proposition**, mais **fermé en fusion** par sa propre convention de nommage. Ce n'est pas un défaut —
  c'est un **choix** qu'il faut assumer explicitement, et qui devra être arbitré si une contribution
  externe se présente.
- ⚠️ **`strict: true` sérialise les merges** : chaque fusion rend « non à jour » toutes les autres
  branches ouvertes, qui doivent se resynchroniser avant de pouvoir fusionner. Sur un dépôt
  mono-développeur, c'est acceptable ; à plusieurs branches parallèles, c'est un coût réel.
- ⚠️ **`required_conversation_resolution: true`** : **un seul** commentaire d'audit non résolu bloque la
  fusion. C'est voulu (les audits ne se perdent pas), et c'est un **motif de blocage supplémentaire** à
  reconnaître pour ce qu'il est.
- ⚠️ **`0` approbation** : **aucune barrière machine** ne soutient l'exigence de « revue humaine
  explicite de la PR » du track FULL. **Dette maintenue** — arbitrage **dû avant le lock d'US-01.1**.

### 🔴 R-1 — risque de VERROUILLAGE TOTAL, et sa porte de sortie

Probabilité **faible** (les 4 libellés sont déjà vérifiés cohérents config ↔ workflows par le gate
`governance`, et leurs points de code ont été inspectés), impact **CRITIQUE** : un contexte requis
**jamais rapporté** produit un `mergeable_state = blocked` **définitif** — **plus aucune PR fusionnable,
administrateur inclus, y compris celle d'US-00.7**. Ce que le gate ne couvre **pas** : il compare la
config au **fichier de workflow**, jamais au libellé **rapporté**. D'où les deux contrôles de D10, et le
**plan de retour arrière écrit avant le `PUT`** (`docs/GIT_PROTECTION.md`), dont le point cardinal est :
**éditer ou supprimer la règle n'est pas un contournement, c'est de l'administration**.

### Le dépôt est devenu PUBLIC — conséquence structurante, à assumer

Ce n'est pas un effet de bord de l'US : c'est **le fait générateur**, et il déborde très largement la
protection de branche.

- **Tout est public, et irréversiblement diffusé** : l'**historique complet**, la Constitution, le
  **PRD**, les **maquettes**, les Story Files, les rapports d'audit, les preuves brutes d'API, le
  PROJECT_LOG. ADR-006 l'avait écrit avant que ce ne soit vrai — « **irréversible de fait** pour ce qui
  a été publié » : forks, caches, indexation et archives tierces échappent à toute reprise. **Repasser
  en privé ne dé-publierait rien.** Cette analyse d'ADR-006 n'est **pas** invalidée par le fait que
  l'humain ait choisi l'autre branche de l'arbitrage : elle en est le **coût**, désormais **payé**.
- **Ce qui dé-risque sérieusement cette exposition** : US-00.1 (certifiée) a prouvé **0 secret** —
  `gitleaks 8.30.1` → `no leaks found` sur le **working tree** *et* sur **30 commits** d'historique ; et
  l'audit sécurité d'US-00.4 (`reports/US-00.4/security.md` §5) a établi que l'**exposition
  incrémentale** du bloc PGP et de l'e-mail committer archivés dans ses preuves était **nulle** — ces
  éléments sont **byte-identiques** au `gpgsig` et à l'`author` déjà présents dans les objets git de
  **tout clone**. Expurger la preuve aurait été du **théâtre de sécurité** au prix de sa disqualification.
- **Ce que cela change quand même, et qu'il serait malhonnête de taire** : ce même audit nommait un — et
  un seul — **scénario d'aggravation** : « *le seul scénario d'aggravation est le **passage du dépôt en
  public*** ». **Ce scénario s'est réalisé.** L'e-mail d'auteur de **tous** les commits de l'historique
  est désormais lisible publiquement — donnée **personnelle**, non secret technique, mais la nuance
  n'annule pas le fait. Plus généralement : la **surface d'exposition du projet n'est plus la même** —
  issues et PR publiques, journaux de CI publics, exécutions d'Actions sollicitables depuis des forks.
  **Rien de tout cela n'est traité par la présente US**, et rien ne doit être présenté comme tel.
  → **Transmission explicite** : une **US de sécurité ultérieure** devra raisonner « dépôt public » —
  au minimum sur (i) la politique de confidentialité des e-mails de commit, (ii) le durcissement des
  workflows vis-à-vis des PR issues de forks (permissions des jetons, `pull_request` vs
  `pull_request_target`, approbation d'exécution), (iii) la revue de ce qui est publié par construction
  (PRD, maquettes) au regard de ce que le projet acceptera de publier **demain**. **`gitleaks` devient
  une barrière critique**, et non plus seulement une bonne pratique.

### Dettes MAINTENUES OUVERTES — aucune n'est close par effet de bord

1. **Aucune détection automatique de la dérive config ↔ dépôt réel** : le contrôle est **manuel et hors
   CI** par construction (droits admin absents du `GITHUB_TOKEN`). Une protection désactivée à la main ne
   serait détectée qu'au prochain contrôle manuel.
2. **Révocabilité silencieuse** : un administrateur peut supprimer la règle à tout moment. La garantie
   vaut **à la date de la mesure** — pas au-delà.
3. **Aucun `selftest` en CI** pour le comparateur : ses **9 fixtures** sont exécutées **à la main**. Le
   correctif NB-1 lui-même n'est protégé par **aucun gate automatique**.
4. **`NB-1bis`** (nouveau, D6) : sur une cible amputée, un **relâchement réel** reste en `exit 0`.
   Correctif identifié, compensé mais **non résolu**.
5. **`scripts/check_branch_protection.py` n'est pas couvert par `.claude/hooks/protect_files.sh`** alors
   qu'il **produit la preuve** : **un agent peut l'affaiblir**. Son ajout est une **action humaine**
   (édition de `.claude/hooks/*`), hors périmètre.
6. **Périmètre Art. 6 déclaré ≠ appliqué** : ni `.github/workflows/*` ni
   `scripts/apply_branch_protection.sh` ne sont protégés, alors que l'un porte les **libellés des
   contextes requis** (donc R-1) et l'autre le **seul chemin d'écriture**. **Même classe de défaut** que
   celui qu'ADR-006 corrigeait.
7. **Revue humaine du track FULL sans barrière machine** (`0` approbation) — **arbitrage dû avant le lock
   d'US-01.1**, avec l'amendement suggéré de `TRACKS.md`.
8. **`TRACKS.md:14` dit « Surface auth / sécurité / **admin** / paiement »** là où la pratique constante
   du projet (4 US certifiées, interprétation inscrite au SCB) lit « surface **applicative** ». Le
   critère littéral **est** satisfait par US-00.7 au sens strict, et c'est dit franchement dans son
   arbitrage de track : ce qui a fait retenir STANDARD+3, c'est l'**inapplicabilité** des obligations de
   FULL (design Data **et** UX « sans N/A » et E2E dédiés, sans UI, sans schéma, sans code applicatif —
   deux exigences **creuses**), **pas** la nature de la surface. → `TRACKS.md` devrait dire
   « surface **applicative** … ». ⛔ **Non édité ici** : à joindre à l'arbitrage `TRACKS.md` déjà dû.
9. **Absence d'événement d'extinction de dérogation** (D3) — dette du **système de traçabilité**.
10. **Émetteurs d'événements déclarés mais non enforced** : `scripts/events_catalog.json` porte un champ
    `emitter` (par exemple `"human"` pour `EVT_WAIVER_GRANTED`) qu'**aucun script ne lit** — vérifié le
    2026-07-27 : l'identifiant `emitter` n'apparaît **nulle part** dans `scripts/*.py`, ni dans
    `trace_append.py` ni dans `validate_trace.py`. **Un agent peut donc émettre un événement réservé à
    l'humain**, y compris `EVT_WAIVER_GRANTED`. **Même famille** que la dette précédente, et **même
    classe** que le défaut fondateur : une contrainte **déclarée** sans mécanisme.
11. **`governance.grandfathering_date`** : clé **lue par aucun script**, dont la description de schéma ne
    correspond à aucun comportement — à **implémenter, redocumenter ou supprimer**. Laissée `null`
    **délibérément**.
12. **Point de contrôle sans déclencheur calendaire** : `/audit-methodo` est trimestriel « ou à la
    demande », sans échéance opposable. C'est la dette **la plus susceptible de pourrir silencieusement**,
    et elle porte désormais **la surveillance de la protection elle-même**.
13. **Repli `urllib` du comparateur jamais exercé** contre l'API réelle (seulement avec un jeton factice).

### Fragilités de la présente décision — nommées, parce qu'un désaccord tracé vaut mieux qu'un alignement de façade

1. **Cet ADR est `Accepté` alors que l'acte qu'il décide n'est pas encore posé.** C'est cohérent avec la
   nature d'un ADR (il enregistre une **décision**, pas un **état**), mais le risque de lecture est réel :
   un auditeur pressé pourrait le lire comme une attestation. **Mitigation** : le titre dit « application
   **décidée** », le Fait 2 date l'état réel, et la colonne « Effectif » distingue ligne par ligne
   l'acquis du conditionné. **Si T8 n'était finalement pas exécuté, ce texte deviendrait faux** — et il
   faudrait alors un ADR-008, pas une retouche.
2. **L'extinction de la dérogation repose sur une convention documentaire.** La trace, seule source
   *machine* de la gouvernance, restera porteuse d'un `EVT_WAIVER_GRANTED` **sans contrepartie typée**.
   La mention dans un `rationale` est un champ **libre et non validé**. C'est **la faiblesse la plus
   nette** de cette décision, et elle est **structurelle au système**, pas au présent arbitrage.
3. **La garantie obtenue reste datée et révocable**, surveillée par un **rituel manuel sans déclencheur**.
   « Enforced » signifiera, après T8, « refusé par la plateforme **tant que personne ne désactive la
   règle** ». C'est très supérieur à un hook local — ce n'est pas « inviolable ».
4. **Un ADR dont la validité dépend d'un paramètre externe basculable par un clic a une demi-vie
   courte.** ADR-006 a été rendu partiellement faux **en 24 heures** par une action humaine sur la
   plateforme. Le même sort attend ADR-007 si la visibilité rebascule. La seule mitigation honnête est
   celle appliquée ici : **nommer sa propre condition d'invalidation** (D5).
5. **Le dépôt public est traité, dans cette US, uniquement sous l'angle du déblocage.** Ses
   conséquences de sécurité sont **nommées et transmises**, pas instruites. Tant qu'aucune US ne les
   prend en charge, il subsiste un écart entre « ce que le projet publie » et « ce que le projet a
   décidé de publier ».

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables** une fois
acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien (ne jamais éditer un ADR
Accepté).
