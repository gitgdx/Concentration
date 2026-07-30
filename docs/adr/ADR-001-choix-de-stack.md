# ADR-001 : Choix de stack — Flutter/Dart, composant unique, offline-first

- **Date** : 2026-07-30
- **Statut** : **Accepté**
- **US associée** : US-00.5

> ⚠️ **NUMÉRO ATTRIBUÉ RÉTROACTIVEMENT — à lire avant tout le reste.** La décision consignée ici est
> **en vigueur depuis le bootstrap du 2026-07-24** ; elle n'est **tracée** que le **2026-07-30**. Six
> jours et **cinq US certifiées** séparent la décision de son enregistrement. Le statut `Accepté` est
> donc **exact** — on ne « propose » pas une stack déjà livrée, testée et certifiée — mais il ne doit
> **pas** être lu comme un ADR rédigé *avant* de coder. **Cet ADR ne fait pas semblant d'avoir précédé
> la décision.**
>
> **Conséquence sur le registre**, écrite ici pour qu'on n'ait pas à la redécouvrir :
> `docs/adr/` **n'est pas chronologique** — ADR-001 est daté **après** ADR-005, ADR-006 et ADR-007 — et
> il **reste incomplet** : **ADR-002, ADR-003 et ADR-004 sont réservés à US-01.1 et ne sont pas
> écrits**. Le numéro `001` était **réservé nommément** depuis le 2026-07-26 : ADR-005 et ADR-006
> justifient tous deux leur propre numérotation par « *éviter la collision avec ADR-001 (stack,
> US-00.5)* ».

---

## Contexte

La factory Concentration a été instanciée le **2026-07-24** depuis un *factory-starter-kit* qui ne
fournissait qu'un adapter **`fastapi-react`**. Un adapter **`flutter`** a été écrit pour l'occasion, et la
stack qu'il impose a été **appliquée immédiatement** : elle porte depuis **cinq US certifiées Prod**
(US-00.1 → US-00.4 et US-00.7).

> 🔎 **Corroboration de l'adapter d'origine, dans le dépôt lui-même** *(ajoutée le 2026-07-30, finding
> NB-3 de l'audit de revue : l'affirmation était portée **deux fois sans renvoi**, alors que la preuve
> était à portée de `grep`)* : les scripts **génériques** du kit en portent les **résidus non ambigus** —
> `scripts/factory_sync.py` code un composant **`backend`** avec `pytest.ini` / `--cov-fail-under` et un
> composant **`frontend`** avec `vitest.config.ts`, et `scripts/run_gates.py` prend **`--component
> backend`** comme exemple d'usage. **Aucun de ces deux composants n'existe dans l'adapter `flutter`**
> *(composant unique `app`)*.

**Le problème que cet ADR corrige n'est pas un problème de stack — c'est un problème de traçabilité.**
La décision la plus structurante du projet était, au 2026-07-30, **la seule à ne pas figurer au registre
des décisions**. Elle vivait dans [`docs/governance/STACK_PROFILE.md`](../governance/STACK_PROFILE.md),
qui est un **document d'adapter** — il décrit des **normes opposables aux agents**, pas une **décision
avec ses alternatives et son coût**. Un auditeur à contexte frais cherchant « pourquoi Flutter ? » ne
trouvait **aucune** réponse à l'endroit prévu pour cela.

**Contraintes qui pesaient sur le choix**, telles qu'elles existaient au bootstrap :

- Le PRD ([`PRD-application-concentration.md`](../product/PRD-application-concentration.md)) cible une
  application **mobile iOS + Android** (RNF-08), **offline-first** — aucune donnée ne quitte l'appareil
  (RNF-07) — avec une exigence d'**extensibilité** du modèle (RF-21).
- Poste de développement **Windows**, sans accès macOS.
- Runners CI **`ubuntu-latest`**.
- Un projet mené par **un seul compte** humain, assisté d'agents : la stack devait être **outillable en
  ligne de commande** de bout en bout, tout gate devant être exécutable sans interface graphique.

---

## Décision

**1. Framework : Flutter (channel `stable`, SDK Dart `^3.12.2`), null-safety strict.**
Cross-platform depuis une base de code unique, ce qui répond à RNF-08 sans doubler l'effort.
**Et — motif que le PRD donne réellement, et qui manquait ici** *(ajouté le 2026-07-30, finding NB-8 :
« le registre répondait à *pourquoi Flutter ?* plus faiblement que le PRD qu'il cite », ce qui est
précisément le trou que cet ADR existe pour combler)* : le PRD **RNF-08** motive Flutter par la **qualité
du rendu visuel** — *dégradés, typographie, animations* — et par les **besoins des modules futurs**,
à savoir **animations fluides et audio** pour le module *Respiration*. Le produit repose sur un
**gradient temporel continu** et des tuiles animées : le rendu **n'est pas un agrément, c'est la
fonctionnalité**.

**2. Un seul composant applicatif : `app`, à la racine du dépôt.**
⛔ **Pas de séparation backend/frontend**, et ce n'est pas une commodité : l'application est
**offline-first** (RNF-07), **aucune donnée ne quitte l'appareil**, donc **il n'y a pas de backend à
séparer**. Un découpage back/front aurait matérialisé un composant vide.
⚠️ **Portée de « aucune donnée ne quitte l'appareil »** *(renvoi ajouté le 2026-07-30, dernière fenêtre
avant l'immuabilité)* : cet énoncé vaut pour la **cible mobile**. La plateforme **Web est matérialisée**,
et un build web s'exécute dans un **navigateur**, avec son propre modèle de stockage et d'origine —
voir la borne détaillée en §*Conséquences → Positives*, et l'honnêteté nº 2 *(le Web est une **preuve de
constructibilité de repli**, pas la cible)*.

**3. Les gates qualité et leurs commandes sont définis en un seul endroit** —
`factory.config.json` → `adapter.components.app.gates` — et exécutés par `python scripts/run_gates.py`.
⛔ **Jamais** de commande de stack codée en dur ailleurs.

> ⚠️ **Commandes citées VERBATIM** *(rectifié le 2026-07-30, finding NB-5 de l'audit de revue)*. La
> première rédaction abrégeait deux commandes **en leur retirant leur sémantique**, et pour `format`
> l'abrégé **inversait l'effet** : `dart format` **réécrit** les fichiers, là où le gate réel **vérifie
> sans écrire**. Ce n'est pas un détail dans un document censé décrire un **gate**.

| Gate | Commande *(verbatim, `factory.config.json`)* | Bloquant | Ce qu'il prouve |
|---|---|---|---|
| `app.format` | `dart format --output=none --set-exit-if-changed lib test` | **oui** | mise en forme normalisée — ⚠️ **vérifie sans réécrire**, portée `lib test` |
| `app.analyze` | `flutter analyze` | **oui** | lint **et** typage statique — *Dart n'a pas d'étape « typecheck » séparée* |
| `app.test` | `flutter test --coverage && python scripts/check_flutter_coverage.py --min 80` | **oui** | tests + **couverture de lignes ≥ 80 %** |
| `app.deps_audit` | `dart pub outdated --show-all` | 🔴 **NON** | **obsolescence** — ⛔ **pas** la vulnérabilité *(voir Conséquences)* |
| `app.build` | `flutter build web --release` | **oui** | constructibilité — ⚠️ **preuve de repli**, pas la cible *(voir Conséquences)* |

**4. Seuil de couverture : `coverage_min = 80`**, mesuré par `lcov` via un script dédié
(`scripts/check_flutter_coverage.py`). ⚠️ **`coverage_ratchet` n'est PAS en vigueur** : la clé existe au
schéma de configuration mais est **absente de `factory.config.json`**.
🔴 **Et il ne suffira PAS d'ajouter la clé** *(précision ajoutée le 2026-07-30, finding NB-4 de l'audit de
revue — la première rédaction n'en disait que la moitié, et c'était **la moitié qui sous-estime la charge
d'US-00.6**)* : `scripts/factory_sync.py` ne lit `coverage_ratchet` que sur un composant **`frontend`**,
lequel **n'existe pas** dans l'adapter `flutter` *(composant unique `app`)*. **Ajouter la clé sous `app`
serait purement et simplement ignoré.** Son activation exige donc **du code** dans `factory_sync.py`, pas
une ligne de configuration. → **US-00.6**.

**5. Plateformes matérialisées : Android et Web. iOS n'est pas scaffoldé.** *(voir Conséquences)*

**6. Changer de stack = changer d'adapter**, jamais les subagents : les rôles référencent
`STACK_PROFILE.md §<Rôle>`, ils ne connaissent aucune commande en propre.

> **Statut de ce document vis-à-vis de `STACK_PROFILE.md`** : cet ADR porte la **décision et son coût** ;
> `STACK_PROFILE.md` porte les **normes opposables** ; `factory.config.json` porte les **valeurs** et
> demeure la **source unique**. ⛔ Aucune valeur numérique n'est à recopier depuis cet ADR : les chiffres
> cités ci-dessus sont **datés du 2026-07-30** et pourraient dériver — **la config fait foi**.

---

## Alternatives considérées

| Option écartée | Pourquoi elle a été écartée |
|---|---|
| **React Native** | Écosystème mobile mature et équivalent en cross-platform, mais aurait imposé la chaîne **Node/npm** pour une application **sans backend**, et n'apportait aucun gain sur les contraintes réelles (offline-first, un seul composant). Aucun avantage décisif face au coût d'un second écosystème. |
| **Natif séparé (Kotlin + Swift)** | **Deux** bases de code pour un produit à surface fonctionnelle modeste, sur un projet à **un seul contributeur**. Et Swift **exigeait un poste macOS**, absent — la moitié du produit aurait été non compilable localement. |
| **PWA / web seul** | Le PRD cible explicitement des **applications de stores** (RNF-08). Une PWA aurait affaibli l'exigence **offline-first** et l'intégration système attendue d'une app de concentration. |
| **`fastapi-react`** *(adapter fourni par le kit)* | Aurait imposé un **backend** que l'architecture offline-first (RNF-07) rend **inutile par construction** : le composant serveur aurait été **vide**, et son enforcement CI aurait tourné sur du néant. Écrire un adapter `flutter` a été jugé moins coûteux que porter une architecture non désirée. |
| **Split backend/frontend malgré l'offline-first** | Retenu un temps par symétrie avec le kit, écarté pour la même raison : **on ne matérialise pas un composant sans contenu** — il aurait fallu le maintenir, le tester et le certifier. |

---

## Conséquences

### ✅ Positives

- **Une** base de code pour Android, Web et — à terme — iOS.
- Toute la chaîne qualité est **exécutable en ligne de commande** : les gates tournent en CI **et** en
  local, à l'identique, via `run_gates.py`.
- **⏳ AU 2026-07-30, ET SOUS CETTE DATE UNIQUEMENT** — l'absence de backend **retire** une surface
  entière de risques : ni API publique, ni authentification, ni transport de données — cohérent avec
  RNF-07. Vérifié à cette date : `lib/` ne contient **qu'un seul fichier**, **aucune** dépendance réseau
  ni de persistance, **aucun** usage de `dart:io`. *(C'est aussi la raison pour laquelle les audits de
  sécurité du projet portent, à ce jour, sur l'outillage et la gouvernance plutôt que sur du code
  applicatif exposé.)*

  > 🔴 **BORNE OBLIGATOIRE — cette affirmation est DATÉE, et volontairement** *(ajoutée le 2026-07-30,
  > finding NB-2 de l'audit sécurité, et c'est le finding le plus intéressant du lot)*. La première
  > rédaction disait que l'absence de backend « **supprime** » cette surface, **sans borne de temps**,
  > alors que les **quatre affirmations négatives** de cet ADR sont, elles, **explicitement datées**.
  > ⚠️ **Or un ADR est IMMUABLE** : **US-01.2 (persistance) est déjà planifiée**, et elle aurait
  > transformé cette phrase en **fausse assurance GELÉE**, dont la correction aurait exigé un **ADR
  > entier**. **C'est EXACTEMENT le mécanisme qui a produit la fausse assurance de l'Art. 4** — un énoncé
  > positif non borné, vrai le jour où il est écrit, jamais revisité. Le reproduire dans l'US qui le
  > dénonce aurait été la faute la plus ironique du projet.
  > **Ce qui invalidera cette ligne, et devra alors être tracé ailleurs** : toute persistance locale
  > *(US-01.2)*, toute dépendance réseau, tout export de données. ⚠️ **Nuance jointe, à ne pas escamoter** :
  > la plateforme **Web est matérialisée**, alors que la décision énonce « *aucune donnée ne quitte
  > l'appareil* » — un build web s'exécute dans un **navigateur**, avec son modèle de stockage et
  > d'origine propre. L'énoncé RNF-07 vaut pour la **cible mobile**.
- **Couverture réelle mesurée à 89,5 %** au bootstrap pour un seuil à 80 %. ⚠️ **À ne pas sur-lire** :
  elle porte sur le **squelette** Flutter, non sur une fonctionnalité métier.

### 🔴 Négatives et dettes — les quatre honnêtetés dures

Ces quatre points sont **connus, non résolus, et nommés ici avec leur destinataire**. **Un ADR qui les
tairait serait faux.** Ils sont repris de
[`STACK_PROFILE.md` §*Limitations connues du bootstrap*](../governance/STACK_PROFILE.md), dont ils ne
sont **pas** une paraphrase adoucie.

**1. 🔴 iOS n'est PAS scaffoldé, alors que le PRD (RNF-08) cible iOS et Android.**
`flutter create --platforms=ios` déclenche sur ce poste Windows une erreur de génération de paquet
Swift Package Manager éphémère (`PathNotFoundException`) qui **casse `flutter analyze` et
`flutter test`** — bug d'environnement, pas de code. Ni ce poste ni les runners `ubuntu-latest` ne
peuvent de toute façon builder iOS. La plateforme a donc été **omise plutôt que livrée non
vérifiable** — un choix défendable, mais qui laisse **la moitié de la cible du PRD non matérialisée**.
→ **exige un poste macOS ou un runner CI macOS.** Non planifié à ce jour.

**2. 🔴 Le build Android réel n'est PAS validé.**
`flutter build apk` n'a jamais été exécuté : **aucun JDK** sur la machine de bootstrap. Le gate
`app.build` utilise **`flutter build web --release`** comme **preuve de repli**.
⚠️ **Conséquence à ne pas escamoter** : le gate `build` **vert** signifie « *le code compile pour le
web* », **pas** « *l'application est constructible pour sa cible* ». → **à valider dès qu'un JDK 17+
est installé** (`flutter doctor` au vert sur la ligne *Android toolchain*).

**3. 🔴 `deps_audit` n'est PAS bloquant, et il ne mesure PAS la vulnérabilité.**
`dart pub outdated` mesure l'**obsolescence**. Il n'existait, au bootstrap, **aucun équivalent mûr à
`pip-audit` / `npm audit` pour Dart**, et `dart pub audit` n'existe pas dans cette version du SDK.
⛔ **Conséquence directe, et c'est la plus importante de cet ADR** : **aucun scan de CVE n'existe dans
cette factory**, donc **aucun verdict de sécurité ne peut s'adosser à un audit de dépendances** — il
n'y en a pas. Piste identifiée, non engagée : `osv-scanner` (action `google/osv-scanner-action`).

**4. 🔴 AUCUN SAST n'existe pour le code applicatif.**
`python scripts/run_gates.py --gate sast` rend **« aucun gate ne correspond »** *(vérifié le
2026-07-30, sortie brute : [`reports/US-00.5/entry_state/`](../../reports/US-00.5/entry_state/))*.
✅ **Partiellement compensé depuis US-00.7** : `actionlint`, épinglé par SHA256, tourne dans le job
requis « 📋 Governance » — mais il couvre les **workflows GitHub Actions**, **rien** ne couvre le
**code Dart**. → **arbitrage dû pour le code applicatif.**

### ⚠️ Écarts constatés hors du périmètre de cette US — nommés, non traités

Conformément à l'AC-5 d'US-00.5, ces écarts sont **consignés avec leur destinataire**. ⛔ **Les taire
serait bloquant ; les corriger ici serait un débordement de périmètre.**

| Écart constaté | Destinataire |
|---|---|
| **Aucun SAST pour le code Dart** — la fonction est absente de la factory, pas seulement mal nommée | **US-00.8** *(ou US-00.6 si l'arbitrage la rattache à la qualité)* |
| **`coverage_ratchet` absent de `factory.config.json`** — la clé est au schéma, le seuil n'est pas en vigueur | **US-00.6** *(couverture + ratchet)* |
| 🔴 **`docs/governance/CONSTITUTION.md` n'est PAS protégé par `.claude/hooks/protect_files.sh`** — vérifié le 2026-07-30. Le hook couvre **9 motifs** *(liste complétée le 2026-07-30, finding NB-6 : la première rédaction en omettait **3 sur 9**, ce qui est une prise inutile dans un projet aussi sévère sur les revendications d'exhaustivité)* : `scripts/githooks/*` · **`.claude/settings.json`** · `.claude/hooks/*` · `.gitleaks.toml` · **`scripts/install_hooks.sh`** · `factory.config.json` · **`scripts/factory_env.sh`** · `scripts/factory_sync.py` · `scripts/run_gates.py`. ⛔ **`docs/governance/**` n'y figure pas** — c'est l'affirmation porteuse, et elle est **vraie**. **Le texte suprême du projet est donc éditable par un agent en autonomie**, alors que l'Art. 6 qu'il énonce protège des scripts. ⚠️ **Qualification, reprise de l'audit sécurité** : ce n'est **pas** une faille d'autorisation — agents et humain partagent le **même compte** et les **mêmes droits** —, et le hook étant un `PreToolUse(Edit\|Write)`, **tout l'édifice est un garde-fou d'ACCIDENT**, pas une barrière. Ce qui manque est la **DÉTECTION**, pas la prévention. ⛔ Non corrigeable ici : `protect_files.sh` est **lui-même protégé**, donc l'ajout est une **action humaine** | **US-00.8** |
| 🔴 **Le corps de l'Art. 4 de la Constitution affirme aujourd'hui LE CONTRAIRE des trois lignes ci-dessus** — SAST **bloquant**, audit de dépendances **bloquant**, `coverage_ratchet` **en vigueur** *(ligne ajoutée le 2026-07-30, finding NB-9 : le tableau nommait les **faits** de l'écart mais **jamais la contradiction** ni son destinataire — or un auditeur qui n'ouvrirait que `docs/adr/`, précisément le lecteur que cet ADR existe pour servir, voyait la contradiction **sans la voir nommée**)*. ⚠️ **La contradiction est VIVE et VOULUE jusqu'à la fusion suivante** | **PR nº 2 de CETTE US** *(amendement de l'Art. 4 — la clause **Révision** exigeant une **PR dédiée**)* |
| **iOS non scaffoldé** et **build Android non validé** — dépendent d'un **matériel absent**, pas d'une décision | **US dédiée, non créée** |

### 📌 Portée exacte de cet ADR — ce qu'il ne fait pas

- Il **enregistre** une décision ; il **ne change rien** au code, à la configuration ni aux gates.
  **Zéro fichier applicatif** n'est touché par US-00.5.
- Il **ne lève aucune** des quatre dettes ci-dessus et **ne leur donne aucune échéance** : les nommer
  n'est pas les résoudre.
- Il **ne revendique aucune exhaustivité** : les limitations listées sont celles **connues au
  2026-07-30**. D'autres peuvent exister.
- **Immuabilité** : conformément à la règle des ADR, toute évolution de ces décisions passera par un
  **nouvel ADR** qui remplacera celui-ci — ⛔ **jamais par une édition de ce fichier**. *(Précédent :
  ADR-007 remplace ADR-006.)*

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
