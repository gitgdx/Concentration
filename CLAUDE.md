# CLAUDE.md — Factory Concentration

> **Constitution complète (non-négociable) : [`docs/governance/CONSTITUTION.md`](docs/governance/CONSTITUTION.md)**
> Les règles ci-dessous en sont le résumé opérationnel. Chaque règle est **enforced** par un
> mécanisme automatique (hooks git versionnés, hooks Claude Code, gates CI) — pas seulement déclarée.

## Stack

Voir [`docs/governance/STACK_PROFILE.md`](docs/governance/STACK_PROFILE.md) (déposé par l'adapter
choisi à l'initialisation) : langages, frameworks, ORM/migrations, commandes de build/lint/test.
**Qualité (gates CI bloquants, `ci.yml`)** : seuils et commandes définis dans `factory.config.json`
(`adapter.components.*.gates`), exécutés via `python scripts/run_gates.py`.

## Règles dures (enforced)

1. **Traçabilité** : tout commit de code = ligne **ajoutée** au tableau `PROJECT_LOG.md`
   (`| YYYY-MM-DD | @Agent | Modèle | Action | Statut | Fichiers |`) + trailer `US: US-XX.X`
   dans le message (`type(scope): description`). *Enforced : pre-commit + commit-msg.*
2. **Jamais** `--no-verify`, jamais de commit/push sur la branche principale, jamais d'édition de
   fichier `.env` ou d'enforcement. *Enforced : hooks Claude Code + hooks git + protection de branche.*
3. **Événements** : toute transition de workflow passe par
   `python scripts/trace_append.py --us US-XXX --event EVT_* ...` (catalogue :
   `scripts/events_catalog.json` ; la machine à états rejette les transitions illégales).
4. **SCB** (`STORY_CERTIFICATION_BOARD.md`) : cohérence vérifiée à chaque édition (hook PostToolUse),
   au commit et en CI. `Certifié Prod = 🚀 OUI` exige `Déploiement = 🚀 DEPLOYED` + rituel `/certify`.
5. **Séparation des pouvoirs** : les audits passent par `/audit-us` (subagents à contexte frais) —
   jamais d'auto-certification dans la session qui a produit le code.
6. **Synchro config** : `factory.config.json` est la source unique (branches, seuils, status checks,
   commandes qualité) — `python scripts/factory_sync.py --check` (gate CI `governance`) détecte
   toute dérive entre la config et ses projections (CI, protection de branche, seuils de fichiers).

## Workflow

Squad de 10 agents : subagents natifs dans `.claude/agents/` — **source unique** (périmètres,
outils restreints, normes du rôle, sorties obligatoires). Séquence STANDARD :
`PO → Architect → (UX + Data) → Architect (lock) → Developer → /audit-us → QA → DevOps → /certify`.
Tracks proportionnés au risque (QUICK/STANDARD/FULL) : `docs/governance/TRACKS.md`.

**Rituels** : `/us-new` (créer une US complète — les Story Files rétroactifs sont interdits) ·
`/audit-us` (audits parallèles) · `/certify` (gate scripté) · `/sprint-status` (synthèse) ·
`/audit-methodo` (audit périodique de la factory).

Sous un rôle d'agent : le déclarer (`> Rôle actif : @X`), lire son subagent (`.claude/agents/<agent>.md`), rester dans son périmètre.

## Démarrage de session

Le hook `SessionStart` injecte automatiquement les 5 dernières lignes du PROJECT_LOG et l'état de
conformité SCB. Lire ensuite le Story File de l'US concernée si applicable.

## État courant du projet *(maintenu par @Architect)*

**Chantier actif** : **US-01.2 — Gestion des échéances (CRUD).** Phase **`development_start`**, branche
`feat/US-01.2-design`. ⛔ **Plus aucune US de fondations n'est ouverte.**
*(⚖️ **PÉRIMÉ-2026-08-06** : cette ligne portait **« US-01.1 — le PRODUIT »** — vrai jusqu'au 2026-08-03,
faux depuis que le plan d'EPIC_01 met US-01.2 en ①. **On date, on ne repeint pas.**)*

> 🔒 **US-01.2 : LA PHASE DE DESIGN EST CLOSE (2026-08-06) — `EVT_DESIGN_COMPLETED` émis, @Developer est
> déverrouillé pour T1 → T15.** SCB : `✅ @PO · ✅ @Data · ✅ @UX`, phase **`development_start`**.
> **3 commits sur la branche** *(`4f9383f`, `2f9a57f`, `478c45a`)*. **16 AC actifs** *(AC-9 vacant)* ·
> **48 clauses** · **50 scénarios** — ⛔ **comptés par commande, 0 titre en double.**
>
> 🔬 **CE QUE CE CYCLE A ÉTABLI ET QUI VAUT AU-DELÀ D'US-01.2 — deux acquis de méthode, tous deux payés.**
> **① `parallel_design` A BESOIN DE SON ÉTAPE DE JOINTURE, et c'est MESURÉ, pas supposé** : les deux
> branches ont tourné **en aveugle l'une de l'autre** et leur jointure portait **QUATRE trous dont aucune
> des deux n'était responsable** — la règle **V-1** de @Data **sans surface**, **3 règles data sans AC**,
> l'**échec d'écriture sans AC ni scénario ni surface**, et **U-2**. ⛔ **Sans l'Integration Lock, les
> quatre partaient en développement.**
> **② ⛔ CE QUI DOIT ÊTRE REFUSÉ DOIT D'ABORD POUVOIR ÊTRE SAISI** *(@UXDesigner)* — un contrôle qui
> empêche de produire l'entrée fautive **EFFACE la clause qui protégeait l'utilisateur**. **Trois
> occurrences dans le même design** : `maxLength` tuait le refus du **81ᵉ** caractère · un bouton
> **désactivé** à 9 tuait le refus de la **10ᵉ** échéance · un **formateur de saisie** rendrait
> `31/02/2027` **intapable**, donc le scénario **inobservable**.
>
> 📌 **DEUX FAITS MESURÉS QUE @DEVELOPER DOIT AVOIR AVANT T1, et qu'il ne doit PAS re-découvrir** :
> ⛔ **`DateTime.parse("2026-02-31T23:59")` NE LÈVE PAS** — il rend **`2026-03-03T23:59`** ⇒ **une
> exception n'est PAS une barrière, la barrière est la FORME CANONIQUE** *(règle V-1, AC-16)*. ⚠️ Et
> ⛔ **ne jamais asserter « aucune échéance au 3 mars »** : **la date de dérive dépend de l'année
> bissextile** *(2 mars une bissextile)*.
> ⛔ **`unawaited_futures` est ACTIVÉ** *(`analysis_options.yaml`)* mais **sa portée est PARTIELLE, prouvée
> par mutant dans les deux sens** : il rend le gate requis `analyze` **ROUGE** sur un `await` oublié
> **dans une fonction `async`**, et ⛔ **ne voit RIEN dans un appelant synchrone** *(gate **vert à
> tort**)*. **Le premier mutant a SURVÉCU** — sans lui, le SCB porterait une affirmation **fausse pour la
> moitié des cas**. Le résidu est fermé par le **refus typé du port** *(⛔ jamais `void`, ⛔ jamais de
> mise à jour optimiste)* **et** le test d'AC-17 « Erreur ».
>
> ⛔ **CE QUE LA CLÔTURE DU DESIGN N'ATTESTE PAS** : **0 ligne de `lib/`** · **LE RISQUE Nº 4 D'EPIC_00
> RESTE OUVERT** — le patron de migration **n'a PAS été joué sur le module réel** *(le critère
> `reports/US-01.2/migration_roundtrip_criterion.py` rend **`exit 1` EN LE DISANT** ; il rendra `exit 0`
> à T5)* · **aucun écran n'a été vu** · **NM-6, NM-7, NM-9, NM-10** non levées · et la **borne NM-10**
> *(web exécuté)* ⛔ **ne se lèvera PAS avec US-01.3**, qui vise iOS/Android.
>
> 🔴 **UN CONSTAT D'ADR-009 EST CONTREDIT PAR LA MESURE** *(et l'ADR n'est PAS édité — immuable, sa
> **décision** n'est pas touchée)* : son §*Conséquences* dit l'aller-retour *« exact dans un fuseau
> donné »*, or `--sonde` montre **dans le seul fuseau Paris** que `ALLER_RETOUR_EXACT=false` pour toute
> **seconde** ou **milliseconde** non nulle **et** pour la **2ᵉ occurrence de la bascule d'automne**.
> ⇒ **la garde d'inversibilité est la CONDITION du couple `v1⇄v2`, pas une élégance.**
>
> ⛔ **QUATRIÈME INSTANCE DE LA MÊME FAMILLE STRUCTURELLE** : les AC ont bougé **après**
> `EVT_STORY_READY` et **aucun événement du catalogue ne modélise un changement de périmètre** —
> ⛔ **aucun n'a été détourné** *(précédent : les arbitrages n'émettent rien)*. Le SCB ne sait pas dire
> « QA à refaire », la trace ne sait pas dire « sur quel commit », le workflow ne sait pas dire « non
> déployable », **la trace ne sait pas dire « le périmètre a changé »**.

> ⚖️ **US-01.1 EST ARRÊTÉE À `🧪 PASS` — VALIDÉE TECHNIQUEMENT, ⛔ PAS CERTIFIÉE PROD (2026-08-02).**
> **PR #27 fusionnée** *(`7ba4228`)* puis **PR #28** *(cliquet à 95,2 — `a9619af`)*, les deux **par
> l'humain sans `--admin`**. SCB : `✅ @PO · ✅ @Data · ✅ @UX · ✅ @Dev · ✅ 🔍 · ✅ 🛡️ · 🧪 PASS`,
> phase **`prepare_deployment`**, **Déploiement `⏳`**, **Certifié Prod `⏳`**.
>
> **`/certify` a été EXÉCUTÉ et s'arrête au gate 6** — c'est un **constat d'outils**, pas un renoncement :
> **gates 1→5 ✅** *(SCB, trace, rapports, **DoD 10/10**, `run_gates --all` 5 gates dont
> `flutter build web --release`)*, **gate 6 ❌** car `Déploiement (DevOps)` vaut `⏳`. **Le rituel prescrit
> littéralement cet arrêt** *(« sinon la certification s'arrête à `🧪 PASS` »)*. **Aucun événement de
> déploiement n'est émis**, et `EVT_CERTIFIED_PROD` exige `EVT_DEPLOYMENT_SUCCESS` en précondition.
>
> ⛔ **POURQUOI LE PRÉCÉDENT DE DÉPLOIEMENT NE SE TRANSFÈRE PAS** *(décision humaine du 2026-08-02)* :
> US-00.6 et US-00.7 avaient écrit « **DÉPLOIEMENT = FUSION SUR `main`** » avec un « **STAGING N/A** »
> dont le motif était **borné** — *« US de GOUVERNANCE sans runtime, **0 fichier Dart livré** »*.
> **US-01.1 livre 19 fichiers Dart et une application** ⇒ **la prémisse du motif est FAUSSE pour elle**, et
> le réutiliser serait **adapter le précédent au résultat**. Le déploiement réel est par ailleurs
> **impossible aujourd'hui** : `STACK_PROFILE` §DevOps dit que `flutter build web --release` est un **gate
> de constructibilité** et **« PAS une plateforme cible produit »** *(RNF-08 vise iOS/Android)* — **Android
> sans JDK**, **iOS non scaffoldé**, aucun keystore, aucun compte store. ➡️ **Ce n'est plus « rien à
> déployer » mais « quelque chose à déployer et aucun moyen de le faire ».**
>
> ⛔ **CE QUE `🧪 PASS` N'ATTESTE PAS** : **AC-1 « Limite » (RNF-02, « < 500 ms ») N'EST PAS COUVERT**
> *(arbitrage humain, reporté à US-01.2 ; critère de levée exécutable livré —
> `reports/US-01.1/rnf02_exit_criterion.py`)* · l'**application n'a JAMAIS tourné sur un appareil** ·
> **aucun contraste n'a jamais été vu par un œil**, tous sont **calculés** · **aucun SAST, aucun scan de
> CVE** · **NB-7 est un défaut DÉMONTRÉ non bloquant** *(deux `DecoratedBox` imbriquées et l'assertion lit
> la mauvaise ⇒ la tuile rend toujours orange et **112 tests restent verts** ; correctif d'**une ligne**,
> porté à US-01.2)*.

> 🗺️ **PLAN ARRÊTÉ LE 2026-08-03 (arbitrages humains) — l'ordre est décidé, ne pas le re-litiger.**
> **① US-01.2** *(CRUD + persistance)* — le produit d'abord, **même raisonnement qu'au 2026-08-02, et il a
> payé**. Elle porte le **critère d'entrée transféré par EPIC_00** *(instancier ADR-005 : **première
> migration réellement exécutée du projet** ; **risque nº 4 ouvert jusque-là**)* et rend **NB-1
> atteignable** *(l'invariant `id` est un `assert`, retiré en release — inoffensif sans persistance, plus
> du tout avec)*. ⚠️ **Cliquet à 95,2, marge NULLE ⇒ tests livrés AVEC le code, jamais après.**
> **② US-01.3 — chaîne de déploiement mobile réelle** *(US nouvelle, créée par l'arbitrage)*. ⛔ **Aucun
> critère de clôture d'EPIC_01 n'a été abaissé** : au lieu de reformuler l'exigence `🚀 OUI` sur
> `🧪 PASS`, on rend **`🚀 DEPLOYED` SIGNIFIANT** — JDK, licences SDK, appareil, keystore, build signé,
> distribution interne. **Seul chemin vers `🚀 OUI` pour US-01.1 ET US-01.2**, et elle referme **trois
> trous ouverts depuis le bootstrap** *(l'app n'a **jamais** tourné sur un appareil · **RNF-02** non
> mesuré · « déployé » **sans définition**)*.
> **③ Backport du kit dans ce projet, AVEC `grandfathering_date`** — le champ `commit` des visas *(NB-6)*,
> le gate 3 de `/certify` qui lit **un verdict** et non un nom de fichier, la case DoD sur la couverture
> des AC. La clé morte `governance.grandfathering_date` est **enfin réveillée** pour rendre le backport
> **non cassant** *(la trace existante ne porte aucun `commit`)*.
> **④ US-00.8** *(dette)*, puis **`/audit-methodo`** — qui n'a **jamais tourné** et dont la matière est
> désormais considérable, **défauts des instruments de contrôle inclus**.
> ⛔ **CE QUE CE PLAN NE FAIT PAS** : la certification d'US-01.1 est **DIFFÉRÉE, pas abandonnée** — elle
> reprend à `prepare_deployment` après US-01.3, et **ses visas devront être RAFRAÎCHIS** *(ils portent sur
> `173fb62`)*, application directe de **NB-6**. **EPIC_01 reste ouvert plus longtemps : c'est assumé.**
> 🔬 **Défaut structurel relevé en chemin, à porter à `/audit-methodo`** : `WORKFLOW.yaml` fait dépendre
> `epic_closure` de `Déploiement == 🚀 DEPLOYED` et **aucune phase ne modélise « US validée mais NON
> DÉPLOYABLE »** ⇒ US-01.1 stationne en `prepare_deployment` **toutes préconditions satisfaites**.
> ⛔ **Troisième instance de la même famille** : le SCB ne sait pas dire « QA à refaire », la trace ne sait
> pas dire « sur quel commit », le workflow ne sait pas dire « non déployable ».

✅ **EPIC_00 CLOS le 2026-08-01** *(⚠️ sur la branche `feat/US-00.6-cloture-epic00` — **la clôture n'est
sur `main` qu'après fusion de sa PR**)*. **Tous ses critères sont cochés**, dont **le nº 112 sur sa seule
1ʳᵉ moitié** : sa 2ᵉ exigeait qu'US-01.2 **instancie** la convention d'ADR-005, or **US-01.2 n'existe pas**
et appartient à EPIC_01, alors qu'EPIC_00 doit être clos **avant** le développement d'EPIC_01 — ⛔ **un
DEADLOCK, pas une case difficile**. **Transféré** en **critère d'entrée d'US-01.2**, inscrit dans EPIC_01 ;
⛔ **un transfert n'est pas une levée** : le **risque nº 4 reste OUVERT**, et **aucune migration n'a jamais
été exécutée sur ce projet**. `US-INIT` est **clôturée sans objet propre** *(porteur de bootstrap, trace
arrêtée à `EVT_DESIGN_COMPLETED`, aucun Story File)* — ⛔ **jamais `🚀 OUI`**, ce serait une
auto-certification rétroactive ; le critère 108 **prévoyait ce cas dans sa lettre**, donc **aucune
dérogation**.

🔬 **CE QUE LA CLÔTURE ÉTABLIT SUR L'ÉTAT RÉEL DU PROJET, et qui doit gouverner la suite** : la factory
**n'a jamais tourné sur du code produit**. **Mesuré, pas estimé** : `lib/` = **1 fichier, 63 lignes**
*(19 mesurables)* · `test/` = **1 fichier** · **8 `.feature`** pour **0 step definition et 0 runner** ⇒
⛔ **aucun scénario Gherkin du projet n'a jamais été exécuté**. Les **7 certifications attestent des
INSTRUMENTS** — chacune porte « **0 fichier Dart touché** » — et le cliquet n'a **jamais refusé une
régression réelle**. ➡️ **La preuve que ce socle fonctionne viendra d'US-01.1.** ⚠️ Le premier vrai fichier
Dart fera **bouger la couverture d'un coup** *(grain minimal **5,26 pt** sur 19 lignes)* : c'est là qu'on
saura si le cliquet **protège** ou **paralyse**.

⛔ **PÉRIMÉ-2026-08-02 — le paragraphe ci-dessus décrit l'état AU 1ᵉʳ AOÛT. Il est conservé parce qu'il
posait la QUESTION ; voici la RÉPONSE, mesurée.** `lib/` = **19 fichiers / 399 lignes mesurables**,
`test/` = **11 fichiers / 112 tests verts**, couverture **95,2 %** — et **13 scénarios Gherkin d'US-01.1
sont RÉELLEMENT EXÉCUTÉS**, adossés à des tests Dart par `check_gherkin_mapping.py` *(les 103 scénarios de
gouvernance restent, eux, ré-étiquetés « **spécification NON EXÉCUTÉE** »)*.
🔬 **RÉPONSE À LA QUESTION « protège ou paralyse » : NI L'UN NI L'AUTRE — il n'a rien vu.** ⛔ **La
couverture de lignes est AVEUGLE À LA FORCE DES ASSERTIONS**, et c'est **prouvé sur du code produit réel** :
**380/399 avant, 380/399 après**, pour **+526 lignes de test** et **6 mutants tués**. Le cliquet **n'a vu
NI le défaut NI sa correction**. Ce qui a trouvé les six trous, c'est la **mutation** — pas la couverture.
⛔ **Deuxième acquis, qui inverse une intuition** : **les égalités au token sont TAUTOLOGIQUES** *(les deux
côtés bougent ensemble)* ⇒ **seules les assertions de GRANDEUR tuent un mutant**, et ce sont justement
celles qui **ont l'air de faire doublon — ne jamais les retirer à ce titre**.
⚠️ **Le cliquet vaut désormais `95.2` sur `main`** *(PR #28, `a9619af`)* : la couverture mesurée étant
**95,2381 %**, la **marge est NULLE**. **Toute baisse d'une seule ligne fera rougir un contexte requis** ⇒
**US-01.2 devra livrer ses tests EN MÊME TEMPS que son code, pas après.**

✅ **US-00.6 CERTIFIÉE Prod 🚀 le 2026-08-01** — couverture initiale mesurée + **cliquet en vigueur**.
**PR #20** *(code)* et **PR #21** *(amendement de l'Art. 4, **PR DÉDIÉE**)* fusionnées **par l'humain sans
`--admin`** — `main` = **`f0a7a2b`**, Constitution **`1.2`**. Le gate imprime **littéralement**
`Couverture de lignes : 89.5% (17/19) — seuil requis : 89.4% (cliquet)`, plancher **80,0 %** affiché à
côté ; la référence vit dans `factory.config.json` → `adapter.components.app.coverage_ratchet` et elle est
**LUE**, prouvé **par mutant bidirectionnel** ; **9 assertions dont 5 REFUS** tournent dans le job
**requis** `governance`. Audits **✅ 🔍 ✅ 🛡️** *(les deux relancés sur le **même** commit `62a4fcc`)* ·
**QA 🧪 PASS au 3ᵉ passage**.
⚖️ **ELLE EST CERTIFIÉE À DoD 19/20, PAR DÉROGATION HUMAINE — pas par un gate tout vert, et cela doit
rester lisible** : le **gate 4 a ÉCHOUÉ**, @Architect **s'est arrêté** et a annoncé l'échec **avant** le
gate ; la **case 6** exige un `git diff` **vide** sur `factory_sync.py` là où **T8 du même Story File
prescrit un `+32/−0`** ⇒ **insatisfiable**. `EVT_WAIVER_GRANTED` accordé le 2026-08-01, **portée stricte**
*(ce gate, cette case, cette US)* ; la case reste **décochée et datée**. ⚠️ **Deux bornes portées par la
dérogation elle-même** : `emitter` n'est lu par **aucun script** ⇒ sa qualité **humaine est DÉCLARATIVE**,
et **aucun** des 25 événements ne permet d'**éteindre** une dérogation ⇒ **irrévocable par construction**.
⚠️ **Ce que la certification n'atteste pas** : le cliquet **n'a refusé AUCUNE régression réelle** *(5
fixtures ; **0 fichier Dart** livré ⇒ les 89,5 % attestent une **non-régression**)* · il **ne monte JAMAIS
seul** · **aucune couverture de branches** · **angle mort structurel** tranché **par expérience** :
un fichier Dart **non importé par un test n'entre PAS** au dénominateur ⇒ ⛔ **déplacer du code non couvert
FAIT MONTER la couverture** *(conséquence portée par US-01.1)* · **18 scénarios Gherkin non exécutés** ·
**aucun SAST ni scan de CVE** sur les **~170 lignes de Python ajoutées** · la **duplication du seuil est
AGGRAVÉE (2 → 3)**.
🎓 **L'ACQUIS DE MÉTHODE DE CETTE US PORTE SUR LES CONTRÔLEURS EUX-MÊMES** : **les trois instruments
d'audit se sont pris à leur propre piège** — la QA **5 fois** en 3 passages ; la revue en comparant un
nombre de colonnes **écrit à la main**, puis en **plantant sur `cp1252`** *(la classe de bug **même** que
cette US corrige, qu'elle avait vérifiée **deux fois** chez @Architect)* ; la sécurité en produisant
**N-1** par copie manuelle. ⛔ **Verdict commun : la dette `/audit-methodo` n'est pas celle de
@Architect — c'est une dette de MÉTHODE, et elle atteint LES DEUX CÔTÉS DU CONTRÔLE.**
📌 **Décision de convergence à réutiliser — le GEL** : chaque correctif de @Architect **invalidait le
badge** que le passage précédent venait d'accorder *(régression potentiellement infinie dont il était la
cause)* ⇒ tout finding **non bloquant** postérieur est **versé à US-00.8**, un **bloquant** l'aurait été
quel qu'en soit le coût. **Les deux auditeurs l'ont accepté et s'y sont tenus.**

✅ **US-00.5 CERTIFIÉE Prod 🚀 le 2026-07-31** — ADR-001 (choix de stack) + exactitude de l'Art. 4.
**PR #17** *(ADR-001)* et **PR #18** *(amendement, **PR DÉDIÉE** exigée par la clause de Révision)*
fusionnées **par l'humain** — `main` = **`c62cdcc`**, Constitution **`1.1`**. **DoD 23/23** · **21 critères
exercés → 21 passés** · **6 gates `/certify` verts** · audits **✅ 🔍 ✅ 🛡️** · **QA `🧪 PASS` au 4ᵉ
passage**, après **3 `FAILED`** qui portaient **tous** sur « *les preuves et les instruments, jamais le
produit* ».
⚠️ **Ce que cette certification n'atteste pas** : l'amendement **NE CRÉE AUCUN GATE** — il fait dire à
l'Art. 4 ce qui **est** et **nomme les dettes** *(aucun **SAST** applicatif → US-00.8 · aucun scan de CVE ·
`coverage_ratchet` **non implémenté** → US-00.6)* · l'**attestation humaine de l'amendement est
DÉCLARATIVE**, et **aucune barrière machine ne pourrait la produire** *(`reviewDecision` vide, `reviews = 0`
— même constat que le **critère 27 d'US-00.7**, qui **demeure**)* · **0 fichier Dart** touché *(les gates
attestent une **non-régression**)* · **21 scénarios Gherkin non exécutés**.
🎓 **L'ACQUIS DE MÉTHODE LE PLUS IMPORTANT DU PROJET, et il est né d'un échec** :
[`tension_structurelle.md`](reports/US-00.5/tension_structurelle.md). Cette US a produit **SIX
instruments de contrôle FAUX — trois de chaque côté** *(la QA a retiré son v1, son v2 **et** son v3 ;
@Architect a retiré un détecteur qui **blanchissait** et réparé un contrôle **infalsifiable**)*. **Cause
enfin nommée** : la convention du projet *(« marqueur sur la ligne, on DATE, on ne REPEINT pas »)*
**conserve** le texte fautif et l'explique ⇒ **un correctif qui s'explique produit MÉCANIQUEMENT des
occurrences de ce qu'il corrige** ; or un gate **par mots-clés** ne peut pas distinguer une **assertion**
d'une **citation-dans-sa-réfutation** — **exclure** les lignes marquées **BLANCHIT**, **ne pas exclure**
rend **8 faux positifs sur 8**. **Il n'y a pas de troisième voie lexicale.**
📊 **Mesure falsifiable établie par la QA** : sur ces 6 instruments, un contrôle **portant son mutant** a
été juste **7 fois sur 7** ; un contrôle **purement lexical**, faux **7 fois sur 7**.
⛔ **Le dernier faux vert était celui de la QA, et il portait sur la SIGNATURE HUMAINE** : prouvé par
**mutation de corpus** *(deux corpus identiques à un fichier près — **son propre rapport** — et le verdict
basculait de `ECHEC` à `OK`)*. Elle a **retiré** son gate plutôt que de le réparer. **Ce faux `OK`
autorisait à cocher une signature absente : il n'a PAS été consommé** — l'attestation a été **demandée**
puis **obtenue**. **Le process a tenu là où l'instrument a menti.**

✅ **US-00.7 CERTIFIÉE Prod 🚀 le 2026-07-30** — application de la protection de branche (track STANDARD
+ 3 renforcements). **PR #12, #13, #14 et #15 fusionnées** — `main` = **`e2bd626`** *(PR #15 fusionnée
**par l'humain** à 12:12:35Z, **sans `--admin`** : renforcement **R-c** respecté)*. **DoD 34/34** ·
Audits **✅ 🔍 ✅ 🛡️** · **QA 🧪 PASS au 6ᵉ passage, après 5 `FAIL`** aux motifs réels et **tous
différents** · **25 critères levés / 3 non levés** (20, 21, 27) · **6 gates `/certify` verts** ·
phase **`epic_closure`**. **Health-check réel** : `protected: true` **après** la fusion et
`--check-remote` **exit 0**, 0 dérive — *et la fusion elle-même prouve le mécanisme, n'ayant pu aboutir
que sur 4 checks requis verts*.
⚠️ **CE QUE CETTE CERTIFICATION N'ATTESTE PAS, à ne pas sur-lire** : les critères **20, 21, 27
DEMEURENT NON LEVÉS** *(arbitrés pour cause de **PLATEFORME**, **jamais requalifiés**)* · refus prouvé sur
contextes **`expected`, pas `failing`** · conditions de fusion **3, 4 et 5** restent **déduites** ·
**`--admin` non testé** · **0 fichier Dart** touché *(la couverture de 89,5 % atteste une
**non-régression**, pas le livrable)* · **24 scénarios Gherkin non exécutés** *(ni step definition ni
runner)* · **aucune preuve machine de provenance** · **aucune détection automatique de dérive** ·
⚠️ **tout est conditionnel à la visibilité PUBLIQUE** du dépôt.
📌 **Ce qui a débloqué 5 cycles d'échec, à réutiliser** : le 5ᵉ `FAIL` a publié un **critère de sortie
borné, falsifiable et rejouable** *(une commande de balayage dont la sortie doit être vide)*, et la QA l'a
**exécuté elle-même** au 6ᵉ passage plutôt que de juger sur relecture. **Trois leçons de méthode** en sont
issues, inscrites à [`corpus_sweep.md`](reports/US-00.7/corpus_sweep.md) : ⛔ `~~texte~~` est **invisible à
`grep`** → marqueur **littéral** `PÉRIMÉ-<date>` **sur la ligne même** · ⛔ corriger le **DÉFAUT**, pas le
**RENVOI** *(« un renvoi cite un exemple ; le défaut a une extension »)* · ⛔ **ne jamais désigner une
assertion par son NUMÉRO DE LIGNE** — il glisse en silence et la couverture cesse de couvrir sans qu'aucun
outil ne le signale. 🔍 **L'extension du motif a fermé 4 survivances que les 5 passages QA et les 4 passes
du balayage avaient TOUTES manquées** — dont la plus grave du corpus : une puce du SCB *(visa @DevOps
d'US-00.4)* **niant la protection de `main` et la déclarant impossible**, soit **cinq assertions fausses**
au cœur même de ce que cette US prouve ; elle était **dissimulée par un filtre** que la QA avait oublié de
reporter dans sa commande publiée — **faute qu'elle a reconnue elle-même**, d'où la leçon versée à
US-00.8 : **un critère de sortie se publie comme un script exécutable, jamais recopié à la main**.
⚖️ **Le critère 27 est ARBITRÉ (2026-07-29, voie a)** : son 3ᵉ
volet est **structurellement inatteignable** sur un dépôt à **un seul compte** *(`reviewDecision` vide —
GitHub interdit à l'auteur d'approuver sa propre PR)*. Il **DEMEURE NON LEVÉ** — *« un arbitrage ne lève
jamais un critère »* — **assumé pour cause de PLATEFORME, non de travail**. Levée réelle → **US-00.8**. **`main` EST PROTÉGÉE depuis le
2026-07-28** — voir l'encadré ci-dessous. **US-00.4 CERTIFIÉE Prod 🚀 le 2026-07-27** (PR #10/#11) :
elle a certifié la **valeur, l'honnêteté et la sûreté de l'outillage et du constat**, **pas** la
protection de `main` — c'est **US-00.7 qui l'applique, en prouve l'effet, et qui est certifiée**.
**Reste pour clore EPIC_00** : **US-00.5** (ADR-001 stack + Constitution — périmètre **RÉDUIT**) puis
**US-00.6** (couverture + ratchet). ⚠️ **`strict: true` SÉRIALISE les merges** → les enchaîner **une par
une**, jamais en parallèle : toute fusion périme les autres branches ouvertes. **US-00.8** (dette) n'est
**PAS** requise pour clore EPIC_00 — son report est un **choix assumé** dont le coût est que la fusion par
un agent reste **interdite** sans être **impossible**.
⛔ **PÉRIMÉ-2026-08-02 : ce paragraphe annonçait US-01.1 « en `business_alignment` », « BLOQUÉE » faute
d'`EVT_STORY_READY`, et « Design UX DÛ ». LES TROIS SONT FAUX depuis le 2026-08-01.** *(La ligne traînait
depuis le 2026-07-24 ; on **date**, on ne **repeint** pas.)* ✅ **État RÉEL au 2026-08-02 : US-01.1 est en
`prepare_deployment`, avec `✅ @PO · ✅ @Data · ✅ @UX · ✅ @Dev · ✅ 🔍 · ✅ 🛡️ · 🧪 PASS`** — il ne
reste que **Déploiement** et **Certifié Prod**. `EVT_STORY_READY` a été **émis** le 2026-08-01, les trois
clauses du track FULL sont **arbitrées** *(ADR-008)*, et **le produit existe** : `lib/` = **19 fichiers**,
**112 tests verts**, **couverture 95,2 % (380/399)**.
🔬 **CE QUE CE CYCLE A ÉTABLI ET QUI VAUT AU-DELÀ D'US-01.1** : ⛔ **la couverture de lignes est AVEUGLE À
LA FORCE DES ASSERTIONS** — **prouvé sur du code produit réel** : **380/399 avant, 380/399 après**, pour
**+526 lignes de test** et **6 mutants tués** ⇒ **le cliquet d'US-00.6 n'aurait vu NI le défaut NI sa
correction**. Et ⛔ **les égalités au token sont TAUTOLOGIQUES** *(les deux côtés bougent ensemble)* :
**seules les assertions de GRANDEUR tuent un mutant, et ce sont justement celles qui ont l'air de faire
doublon — ne jamais les retirer à ce titre.** ➡️ **Les deux au dossier `/audit-methodo`.**
⚖️ **ARBITRAGE HUMAIN DU 2026-08-02** : US-01.1 sera certifiée avec **AC-1 « Limite » (RNF-02, « < 500 ms »)
EXPLICITEMENT NON COUVERT**, borné, daté, reporté à US-01.2. ✅ **Aucune dérogation requise — c'est un
CONSTAT** : la DoD de ce Story File est la **liste générique de 10 cases** et **aucune n'exige la couverture
des AC**, donc rien n'est insatisfiable *(différent d'US-00.6, dont la case 6 l'était **littéralement**)*.
🔴 **Mais ce constat EST un défaut de méthode** : *une DoD qui n'exige la couverture d'aucun AC serait
intégralement cochable avec la moitié des AC orphelins.* **Ce qui a rattrapé RNF-02, c'est la QA, pas la
DoD.** ⛔ **Un arbitrage ne lève jamais un critère** *(précédent du critère 27)* : l'AC **reste non
couvert**, et le trou plus large demeure — **l'application n'a JAMAIS tourné sur un appareil**.
⛔ **PÉRIMÉ-2026-08-01 : cette ligne portait « à rebaser sur `main` » — c'est FAUX.** Vérifié :
`feat/US-01.1-affichage-hub-grille` est **ancêtre de `main`** et n'a **0 commit propre** — **rien à
rebaser, la branche est morte**, à supprimer. L'affirmation traînait depuis le **2026-07-25**.

> ✅ **ÉTAT DE L'ENFORCEMENT DE `main` — 2026-07-28, avec ses bornes.** La **règle 2** ci-dessus est
> désormais **VRAIE telle qu'elle est écrite** : la protection de branche est **APPLIQUÉE**. Preuves
> brutes datées : [`reports/US-00.7/applied_state/`](reports/US-00.7/applied_state/).
>
> **Périmètre EXACT de la règle 2 — ce qui est prouvé, et rien de plus** :
> * `GET …/branches/main` → **`"protected": true"`** · `GET …/branches/main/protection` → **200** portant
>   la cible **générée** depuis `factory.config.json` (`protection_applied.json`).
> * **PR obligatoire** · **4 status checks REQUIS** · **`enforce_admins` en vigueur** — l'administrateur
>   est **inclus** (`enforcement_level: "everyone"`).
> * **Effet prouvé par le SERVEUR**, depuis un clone **sans hooks** (`negative_test_server.txt`) : push
>   direct, force-push et suppression **refusés** — `GH006 Protected branch update failed`, « *Changes
>   must be made through a pull request* », « ***4 of 4 required status checks are expected*** ».
> * `python scripts/factory_sync.py --check-remote` → **exit 0 RÉEL** (12 champs alignés, 0 écart, 0
>   champ actif non couvert), **sans** préfixe `[SIMULATION]` — **première observation in vivo**.
>
> **Ce qui n'est PAS prouvé, et ne doit pas être affirmé** :
> * ✅ **Le refus d'une tentative de FUSION EST PROUVÉ — par le SERVEUR — depuis le 2026-07-29T08:49:14Z.**
>   Sur la **PR #14**, `gh api -X PUT …/pulls/14/merge` avec **1/4** contexte vert → **HTTP 405**,
>   *« **3 of 4 required status checks are expected** »*. C'est **l'API REST** qui refuse : `gh` n'est
>   qu'un transport, donc l'hypothèse d'un refus **côté client** est **écartée**. **Administrateur
>   inclus** (`admin: true` + `enforce_admins: true`) · `main` **inchangée** · **aucun `--admin`**.
>   **Les DEUX moitiés d'AC-4 sont prouvées par le serveur** : **refus** à 1/4 (HTTP 405) et
>   **acceptation** à 4/4 (`merged: true`, PR #13). Preuves :
>   [`applied_state/merge_refusal_server_405.txt`](reports/US-00.7/applied_state/merge_refusal_server_405.txt)
>   et [`merge_proof_and_violation.md`](reports/US-00.7/merge_proof_and_violation.md).
>   ⚠️ **Borne maintenue** : le refus porte sur des contextes **`expected`**, **pas `failing`** — la
>   conjonction littérale d'US-00.1 (« `secrets-scan` **rouge** → merge empêché ») **reste non observée**,
>   et ⛔ **on ne cassera pas un gate pour l'obtenir**. `--admin` **non testé**, et ne le sera pas.
> * ⛔ **VIOLATION DE WORKFLOW du 2026-07-29, actée et NON effacée** : à `07:08:59Z`, **un agent a fusionné
>   la PR #13** — enfreint la **case 34** / renforcement **R-c**. **Pas un contournement** (4 gates verts,
>   fusion licite) mais une **violation de PROVENANCE**. `EVT_WORKFLOW_VIOLATION` tracé, **case 34
>   **décochée à l'époque** — ⚠️ **PÉRIMÉ-2026-07-29 : la case 34 est depuis RECOCHÉE**, au titre d'une
>   **attestation humaine datée** *(niveau 1, assumée **déclarative**)* après la fusion de la PR #14 par
>   l'humain. **Elle ne lève pas pour autant le 3ᵉ volet du critère 27** *(`reviewDecision` vide)*.
>   A révélé que **`mergedBy.is_bot` ne prouve rien** — voir la dette « provenance » ci-dessous.
> * `allow_force_pushes: false` et `allow_deletions: false` **ne sont pas isolés** par le test négatif — le
>   **même** `GH006` sort pour le force-push (la règle « PR obligatoire » se déclenche avant), et GitHub
>   refuse la suppression de la **branche par défaut** indépendamment du réglage ; ces deux réglages sont
>   prouvés par l'**état de l'API**, pas par l'effet.
> * Rien n'est prouvé pour un **autre acteur**, un **jeton d'application**, l'**interface web**, une PR
>   issue d'un **fork** ou **réouverte**, ni pour la **persistance** de l'état (aucune détection
>   automatique de dérive — dette ci-dessous).
>
> ⚠️ **CONDITIONNEL** : tout l'édifice dépend de la **visibilité PUBLIQUE** du dépôt. Un retour en privé
> ramènerait le **403**, rendrait la protection **indisponible** et **rouvrirait la dérogation**.
>
> **Ce qui reste de la discipline** : le hook local `pre-push` — **toujours utile** (il refuse avant
> l'aller-retour réseau, et vaudrait encore si la protection était désactivée) et **toujours absent d'un
> clone frais**. Détail : [`docs/GIT_PROTECTION.md`](docs/GIT_PROTECTION.md) ·
> [ADR-007](docs/adr/ADR-007-application-protection-branche.md) *(remplace ADR-006)*.

> 🔕 **Dérogation `EVT_WAIVER_GRANTED` (2026-07-26, US-00.4, Art. 5) — ÉTEINTE / SANS OBJET au
> 2026-07-28.** Elle portait sur « **ni GitHub Pro, ni dépôt public** » ; l'humain a choisi la **voie (a)
> — dépôt public — le 2026-07-27**, et la protection a été appliquée le **2026-07-28**. Son motif
> (impossibilité de plateforme) **n'existe plus**. ⛔ **La trace n'est pas réécrite** (append-only) : on
> **éteint** une dérogation, on ne l'**effface** pas. ⚠️ **L'extinction est DOCUMENTAIRE** : **aucun** des
> **25** événements du catalogue ne permet d'éteindre une dérogation → **dette du système de traçabilité**
> (ci-dessous). **Conditionnel** : un retour du dépôt en privé **rouvrirait la question**.

**Sprint 0 (EPIC_00) : CLOS le 2026-08-01** — US-00.1 → **US-00.7 certifiées 🚀** *(US-00.7 le 2026-07-30,
hors découpage initial : EPIC_00 = US-00.1→US-00.6)*, `US-INIT` **clôturée sans objet propre**, **tous les
critères de clôture cochés** *(le nº 112 sur sa 1ʳᵉ moitié, transfert daté)*, **risques #1, #2, #3, #5
CLOS** et **#4 TRANSFÉRÉ donc encore OUVERT** *(preuves : `reports/US-00.7/applied_state/`,
`reports/US-00.6/`, `python scripts/check_epic00_docs.py` → exit 0)*. ⚠️ **La clôture est sur une BRANCHE
tant que sa PR n'est pas fusionnée** — sur `main`, EPIC_00 est encore ouvert. ⚠️ **La mention « SPRINT 0
COMPLET » du PROJECT_LOG au 2026-07-26 était inexacte** *(rectifiée en fin de tableau)* : elle l'était
parce qu'elle confondait des US livrées avec un EPIC statué. ⛔ **Et « EPIC_00 clos » ne veut pas dire
« socle prouvé »** : voir le bloc *Chantier actif* — **0 fichier Dart** en 7 US, **0 scénario Gherkin
exécuté**, **0 migration jamais exécutée**. **US-00.8** (dette) n'était **pas** requise pour la clôture —
son report reste un **choix assumé**. US-01.1 (EPIC_01, track FULL) **redevient le chantier actif** —
⚠️ **son Integration Lock exige d'abord l'arbitrage `TRACKS.md`** *(ci-dessous)*.
**Dettes ouvertes** :
- 🔴 **SIX DÉFAUTS RELEVÉS LE 2026-08-06 PENDANT LE DESIGN D'US-01.2 — tous `/audit-methodo`, et QUATRE
  visent les INSTRUMENTS DE CONTRÔLE eux-mêmes.**
  - **① La « Sortie obligatoire » de `@UXDesigner` est IMPOSSIBLE avec sa propre dotation d'outils.**
    `.claude/agents/ux-designer.md` déclare `tools: Read, Grep, Glob, Edit, Write` et son §2 exige
    d'**exécuter** `trace_append.py`. **Il a refusé d'écrire la ligne à la main** après avoir vérifié
    **dans le code** les 4 contrôles qu'une écriture manuelle contournerait ; @Architect a émis pour son
    compte. ⚠️ **Même situation pour `@ProductOwner`** *(2 fois : 2026-08-05 et 2026-08-06)*.
    ⛔ **À vérifier sur TOUS les subagents, pas seulement ces deux** — la contradiction est dans la
    **définition du rôle**, pas dans son exécution. Même famille que la dette `emitter` non enforcé.
  - **② `EVT_MIGRATION_SCRIPT_READY` ne sera JAMAIS émis si personne ne le réclame** *(relevé par
    @DataEngineer)* : son `emitter` déclaré est `data-engineer`, sa précondition sera satisfaite par
    **T5 (@Developer)**, et ⛔ **aucune phase de `WORKFLOW.yaml` ne rappelle @DataEngineer après
    `development_start`.**
  - **③ AUCUN OUTIL NE CROISE LA CELLULE DE PHASE DU SCB AVEC LE DERNIER ÉVÉNEMENT TRACÉ.**
    **Mesuré** : la cellule d'US-01.2 affichait `business_alignment` alors qu'`EVT_STORY_READY` **et**
    `EVT_ARCHI_VALIDATED` étaient émis — et `check_scb_compliance.py` rendait *« conforme »*,
    `validate_trace.py` aussi, **chacun de son côté**. ⇒ **l'écart SCB ↔ trace est invisible dans les
    DEUX sens** *(US-01.1 avait payé l'autre : un visa @PO affiché **8 jours** sans son événement)*.
  - **④ RIEN NE DÉTECTE QU'UNE ENTRÉE DU `CLAUDE.md` A ÉTÉ RÉFUTÉE PAR LE CORPUS QU'ELLE RÉSUME.**
    Ses 3 « décisions design à arbitrer » étaient **tranchées depuis le 2026-08-01** — **cinq jours** de
    retard, et **tout agent démarrant une session les aurait rouvertes**. Trouvé par **@UXDesigner allant
    lire le corpus** plutôt que ce résumé. ⚠️ **La même journée a produit une 2ᵉ occurrence** : le
    « Chantier actif » nommait encore US-01.1.
  - **⑤ UN NOMBRE DÉRIVÉ EST ÉCRIT À LA MAIN 23 FOIS.** Le compte de scénarios d'US-01.2 vivait en
    **20 exemplaires dans le Story File** + SCB + BACKLOG + EPIC_01, tous à faire bouger ensemble — ⛔ la
    règle du projet est *« une règle n'existe qu'en un seul exemplaire »*, vérifiée trois fois.
    📌 **Remède proposé par le @PO, non mis en œuvre** : un `scripts/check_story_counts.py` qui **LIT** le
    `.feature` et **refuse tout écart**, avec son autotest de mutation ; variante plus sûre — **supprimer**
    le total du Story File et n'y laisser que **la commande qui le produit**. ⚠️ **Vaut aussi pour
    `N AC / N clauses`**, qui souffre du même mal **sans même avoir de source machine-lisible**.
  - **⑥ LA TABLE ANTI-ORPHELIN NE PEUT PAS VOIR UNE CLAUSE MANQUANTE.** Elle vérifie que les clauses
    **écrites** ont un scénario, ⛔ **jamais qu'une clause MANQUE**. **AC-16 et AC-17 manquaient depuis la
    création du Story File** et **aucun contrôle ne l'a signalé** — ce sont **deux documents de design
    produits en parallèle** qui les ont révélés. ⚠️ **C'est le même angle mort que la DoD** *(qui n'exige
    la couverture d'aucun AC)* : **les instruments vérifient la cohérence de ce qui est là, jamais la
    complétude de ce qui devrait y être.**
- ✅ **RÉSOLU-2026-08-01 — l'Art. 4 dit désormais ce qui EST.** Cette entrée était une **exigence de
  clôture** posée par l'audit de revue *(si la PR dédiée glissait, **rien dans le corpus durable** n'aurait
  signalé la fausseté)* ; elle est **soldée par son propre critère** : l'amendement est **fusionné**
  *(PR #21, Constitution **`1.2`** sur `main`)*. L'article **nomme** maintenant `coverage_ratchet` parmi
  les seuils, décrit l'enforcement **réel** et **porte ses bornes**. ⛔ **Ce qui RESTE VRAI et durable** :
  **ADR-001 §4 porte encore les clauses périmées et NE SERA JAMAIS corrigé** — un ADR est **IMMUABLE**, son
  §*Conséquences* décrivait l'état du monde **à sa date**, et *l'immuabilité existe précisément pour qu'on
  ne repeigne pas l'histoire*. Il est **nommé**, jamais réécrit ; **aucun ADR-008**, la **décision** est
  inchangée — c'est le **constat** qui a vieilli.
- 🔴 **LA COUVERTURE DE LIGNES NE MESURE PAS CE QUE LE PROJET CROIT QU'ELLE MESURE — établi par
  EXPÉRIENCE le 2026-08-02, sur du code produit réel.** **380/399 avant, 380/399 après**, pour **+526
  lignes de test** et **6 mutants tués** ⇒ ⛔ **le cliquet n'a vu NI le défaut NI sa correction**. Ce qui a
  trouvé les six trous, c'est la **mutation**. **L'instrument central d'US-00.6 a donc une borne
  démontrée**, et elle n'est écrite **nulle part dans son propre dossier**. ⚠️ **Ne pas en conclure que le
  cliquet est inutile** — il **interdit la régression du dénominateur**, ce qui reste vrai ; il ne mesure
  simplement **pas la qualité des assertions**. **Aucun gate ne mesure la mutation**, et les 3 campagnes de
  cette US ont toutes été **écrites à la main par des auditeurs**. ➡️ **`/audit-methodo` prioritaire.**
- 🔴 **`/certify` gate 3 vérifie une PRÉSENCE DE FICHIER, pas un VERDICT** *(trouvé le 2026-08-02 **en
  exécutant le rituel**)* : il exige `code_review.md`, `security.md`, `qa.md` — or sur US-01.1
  **`code_review.md` ET `qa.md` portent tous deux un verdict `FAILED`**, les `PASSED` vivant dans
  `*_delta2.md` et `qa_delta.md` que **le gate ne regarde jamais**. ⇒ **le gate 3 serait VERT sur une US
  dont tous les audits ont échoué.** Ce qui porte réellement le verdict est la **chaîne d'événements du
  gate 2**. **Même famille que NB-6** : le corpus **ne modélise pas ce sur quoi un verdict porte**.
- 🟠 **La DoD générique n'exige la couverture d'AUCUN AC** *(constaté le 2026-08-02 en cherchant si une
  dérogation était requise — elle ne l'était pas, **et c'est bien le problème**)* : ses **10 cases** sont
  intégralement cochables **avec la moitié des AC orphelins**, sans qu'aucune ne le signale. Sur US-01.1,
  ce qui a rattrapé **RNF-02**, c'est **la QA — pas la DoD**. **Candidat `/audit-methodo`.**
- 🔴 **UN VISA D'AUDIT N'EST RATTACHABLE À AUCUN COMMIT — donc il PÉRIME EN SILENCE.** Découvert le
  2026-08-02 par l'audit sécurité d'US-01.1 *(NB-6)*, après un incident **réel** : son visa portait sur
  `24fe59a`, la revue sur `6fe75df`, et **73 lignes de `lib/` n'avaient été vues par aucun audit
  sécurité**. **Mesuré** : `trace_append.py` n'a **aucune option `--commit`/`--sha`**, et un événement ne
  porte que `agent, event, evidence, files, model, rationale, session, ts, us`. ⇒ **aucune machine ne peut
  signaler qu'un visa est périmé** — ici, c'est un **humain** *(l'auditeur de revue)* qui a rattrapé le
  décalage. Même famille que l'absence d'événement d'extinction de dérogation et qu'`emitter` non
  enforcé : **le catalogue ne modélise pas ce sur quoi un verdict PORTE**. Mitigation appliquée : SHA
  inscrit dans le champ libre — ⚠️ **convention NON enforcée**, qui réduit le risque sans le supprimer.
  Correctif réel *(champ `commit` validé)* : touche le **schéma de la trace** ⇒ **exige son propre ADR**.
  ➡️ **US-00.8.**
- 🔴 **AUCUN ÉVÉNEMENT DE CLÔTURE D'EPIC dans le catalogue** *(constaté le 2026-08-01 en clôturant
  EPIC_00)* : ses **25** événements n'en comportent **aucun** pour clore un EPIC — **même famille
  structurelle** que l'absence d'extinction de dérogation. ⇒ **la clôture d'un EPIC est un acte
  PUREMENT DOCUMENTAIRE**, invisible de `docs/trace/**` : un audit qui ne lirait que la trace ne pourrait
  **pas savoir** qu'EPIC_00 est clos. ⛔ **`EVT_DOCS_UPDATED` n'a PAS été détourné** *(son `emitter`
  déclaré est `tech-writer`)* et **aucune dérogation n'a été émise pour un acte documentaire** — précédent
  suivi : l'amendement de l'Art. 4. En ajouter un modifierait la **machine à états** → exige son propre
  ADR. **Candidat `/audit-methodo`.**
- 🟠 **`scripts/check_epic00_docs.py` n'est PAS en CI** *(critère de clôture 114 d'EPIC_00)* : il porte son
  **autotest de mutation** *(4 assertions, mutants « fichier supprimé » et « marqueur retiré », verdicts
  comparés en **ensembles**)* et il a été éprouvé sur le **corpus réel** *(Constitution ramenée à `1.1` →
  refus)*, mais **il se lance à la main** — **même dette** que le `selftest` d'US-00.6. ⚠️ **Borne
  intrinsèque** : il atteste la **présence** et la **fraîcheur**, ⛔ **jamais la véracité** — l'Art. 4 a
  prouvé qu'un texte peut être **présent, marqué et faux**.
- 🔴 **CLASSE DE DÉFAUT RÉCURRENTE, SANS AUCUN MÉCANISME — la dette la plus active du projet.**
  *« Une assertion chiffrée ou un emplacement écrit à la main à côté d'une commande, jamais relu dans sa
  sortie. »* **SIX manifestations en trois jours** *(2026-07-29 → 07-31)*, toutes de @Architect, dont
  **une dans le paragraphe qui la dénonçait** et **une DANS UN OUTIL DE CONTRÔLE** — un détecteur dont
  l'exclusion par mots matchait « PÉRIMÉ » **dans la commande elle-même** et **blanchissait** le seul écart
  réel. ⚠️ **Elle atteint aussi les auditeurs** : la QA a **retiré son propre v1** *(sa colonne « écrit »
  était une **transcription de mesure**, pas une **spécification**, donc son critère devenait inatteignable
  dès que le corpus évoluait légitimement)*, et son **v2** code encore **5 emplacements en dur** dans le
  sous-contrôle intitulé *« un numéro glisse en silence »*. **Le projet a la RÈGLE — trois leçons inscrites
  à [`corpus_sweep.md`](reports/US-00.7/corpus_sweep.md) — et AUCUN gate CI ne voit cette classe.**
  📌 **Remèdes établis, à généraliser** : ⛔ ne jamais écrire un résultat **ni un emplacement** à la main à
  côté d'une commande *(le résultat se **lit**, l'emplacement se **désigne par son texte**)* · une valeur
  fausse se **retire**, jamais ne se « met à jour » *(une valeur mise à jour périme au cycle suivant)* ·
  **une règle n'existe qu'en un seul exemplaire** *(deux copies d'un motif, d'une liste de verbes ou d'un
  chiffre **dérivent** — vérifié trois fois)* · **tout script de contrôle porte son autotest de mutation**,
  avec des mutants **jamais tirés du vocabulaire de la règle testée** *(sinon il ne mesure rien)* · un
  **décompte égal n'est pas une preuve d'équivalence** : comparer les **ensembles**, pas les cardinaux.
  ➡️ **Candidat `/audit-methodo` prioritaire** *(B-9 de la QA d'US-00.5)*.
- 🟠 **Findings NON BLOQUANTS de l'audit sécurité d'US-00.7, ouverts et non traités** *(2026-07-28,
  `reports/US-00.7/security.md`)* : **aucun plancher de sécurité** — `enforce_admins: false` en config
  produirait une **CI verte** et un `--check-remote` « **conforme** », avec `0` approbation requise ·
  **NB-1bis confirmé par exécution** mais **NON exploitable par configuration** (les 8 clés sont **en
  dur** dans `emit_branch_protection` : l'amputation exige de modifier le code Python — **moins grave
  qu'annoncé jusqu'ici**) · **actions tierces non épinglées** (`actions/checkout@v4`,
  `gitleaks-action@v2` avec `pull-requests: write`) · **`emitter` non enforcé** — mais ⚠️ **ce n'est pas
  une faille d'autorisation** : agents et humain partagent le **même compte** et les **mêmes droits**,
  donc **aucune implémentation ne le rendrait infranchissable** ; le durcissement utile est la
  **détection**, pas la prévention.
- 🔴 **AUCUN SAST dans la factory** : `run_gates --gate sast` → **exit 1, ce gate n'existe pas**. Et
  `dart pub outdated` mesure l'**obsolescence**, pas la **vulnérabilité** → **aucun verdict de sécurité
  ne peut s'appuyer sur un scan de CVE, il n'y en a pas**. ✅ **Partiellement compensé le 2026-07-28** :
  `actionlint` (épinglé par SHA256) tourne désormais dans le job **requis** « 📋 Governance » — il aurait
  trouvé seul le bloquant B-1, dont son absence était la **cause racine**. Reste à décider pour le code
  applicatif Dart.
- ⚠️ **Nouvelles CONTRAINTES PERMANENTES, actives depuis le 2026-07-28** — à connaître avant de les vivre
  comme une panne : toute branche hors `^feat/US-[0-9]+\.[0-9]+.*$` rend sa PR **définitivement
  infusionnable** (`check-branch-name` est un contexte **requis**) → `chore/`, `docs/`, `hotfix/` sont
  **impossibles à fusionner**, et le **track QUICK** repose sur des noms libres · **toute PR issue d'un
  FORK** dont la branche ne suit pas ce motif est **infusionnable** (dépôt **public** : ouvert en
  proposition, fermé en fusion par sa propre convention) · une PR de fork reçoit un `GITHUB_TOKEN`
  **restreint** alors que le job `secrets-scan` exige `pull-requests: write` · `strict: true`
  **sérialise** les merges (toute fusion périme les autres branches) · `required_conversation_resolution`
  bloque sur **une seule** discussion ouverte. Détail : `docs/GIT_PROTECTION.md` §Conditions de fusion.
- 🔴 **Aucune détection automatique de dérive** config ↔ dépôt réel : `--check-remote` exige des droits
  **admin**, absents du `GITHUB_TOKEN` → contrôle **manuel et hors CI**. Un administrateur peut supprimer
  la règle **sans qu'aucun mécanisme ne le signale**. Seul porteur : `/audit-methodo`, **sans déclencheur
  calendaire** (la dette la plus susceptible de pourrir silencieusement).
- ✅ **RÉSOLU par US-00.4** : `factory_sync.py --check` annonce désormais une vérification
  **DOCUMENTAIRE** et avertit que l'état réel n'est pas vérifié ; `--check-remote` interroge l'API
  (hors CI, droits admin). **Actif sur `main`.**
- 🔴 **NB-1bis — résidu OUVERT du correctif NB-1** *(NB-1 lui-même est **CORRIGÉ** par US-00.7 :
  `_guard_actual` filtre par `MAPPED_TOP_KEYS & set(expected)`, **3 lignes** et non « une »)*. Après
  correctif, une clé absente de la cible dont la valeur réelle est **ACTIVE** est nommée et **interdit
  l'exit 0** ; mais si sa valeur est **NEUTRE** (`{"enabled": false}`) elle est **seulement nommée** et
  l'exit 0 **subsiste**, et si elle est **absente des deux côtés** elle n'est **pas même nommée** — or
  `enforce_admins: false` autorise le bypass admin et `required_pull_request_reviews` absent signifie
  **aucune PR exigée**. **Le correctif est un progrès strict, pas une fermeture.** Correctif complet
  identifié (complétude de la cible dans `_guard_mapping`), **hors périmètre**. **Compensé aujourd'hui** :
  `set(payload) == MAPPED_TOP_KEYS` → `True` (cible **non amputée**).
- 🔴 **Aucun `selftest` en CI** pour `check_branch_protection.py` : ses fixtures versionnées sont lancées
  **à la main**, y compris pour valider le correctif NB-1. Recommandation forte du re-audit d'US-00.4 —
  « c'est lui, pas le hook, qui arrête une régression » de la frontière de couverture. **Contrôle négatif
  maintenu** : `grep -rn "check-remote" .github/workflows/` doit rester **vide**.
- 🔴 **Aucun événement d'extinction de dérogation dans le catalogue** — dette **structurelle du système
  de traçabilité**, révélée par US-00.7 : ses **25** événements (+ 4 alias dépréciés) ne comportent
  **aucun** mécanisme de révocation, extinction ou expiration. Une dérogation y est donc **irrévocable par
  construction** : un audit qui ne lirait que `docs/trace/**` verrait un `EVT_WAIVER_GRANTED` **sans
  contrepartie** et pourrait croire l'exception encore active. Mitigation retenue : consignation
  documentaire (3 emplacements) + mention dans le `rationale` d'`EVT_DOCS_UPDATED` — **convention non
  enforced** (champ libre, non validé par `validate_trace.py`) : elle **réduit** le risque, elle ne le
  supprime pas. En ajouter un modifierait la **machine à états** → exige son propre ADR.
- ⚠️ **Émetteurs d'événements déclarés mais NON enforced** : le champ `emitter` de `events_catalog.json`
  n'est lu par **AUCUN** script ni hook (vérifié le 2026-07-28 : **0** occurrence dans `scripts/*.py` et
  `.claude/hooks/*`) → **un agent peut émettre n'importe quel événement sous n'importe quel rôle, y
  compris `EVT_WAIVER_GRANTED`** dont le catalogue déclare pourtant `emitter: "human"`. Corollaire direct
  de la dette précédente : le système peut **accorder** une dérogation sans humain et ne peut pas
  l'**éteindre**. Même classe de défaut que celle qu'US-00.4 dénonce, dans le système de traçabilité
  lui-même. Candidat `/audit-methodo`.
- 🔴 **PROVENANCE NON PROUVABLE — dette FUSIONNÉE avec celle de `TRACKS.md` ci-dessous, même solution.**
  Établi le 2026-07-29 par une **violation réelle** (`reports/US-00.7/merge_proof_and_violation.md`) :
  **`mergedBy.is_bot` rend `false` même pour une fusion exécutée par un AGENT**, parce que les agents
  opèrent avec **le jeton de l'humain**. Vérifié le même jour : `collaborators` = **`gitgdx` seul**,
  `restrictions` = **absente**, identité `gh` **identique**. ⇒ **Sur ce dépôt, aucune preuve machine de
  provenance n'existe** : « la fusion ne vient pas d'un agent » (case 34, renforcement R-c) est une
  **obligation de process**, désormais attestée de façon **déclarative et assumée** — jamais plus par
  `is_bot`, qui était **faussement rassurant**. **Voie de sortie unique et commune aux deux dettes** :
  une **identité distincte pour les agents** (2ᵉ compte ou GitHub App), puis `restrictions` → la fusion
  par un agent devient **impossible**, pas seulement interdite. ⚠️ Réserve **non levée** : `restrictions`
  pourrait être **réservé aux dépôts d'organisation** — à vérifier. **Porté par US-00.8.**
- ✅ **ARBITRÉ le 2026-08-01 — [ADR-008](docs/adr/ADR-008-arbitrages-track-full.md), les TROIS clauses du
  track FULL** *(et non une seule, comme cette entrée le laissait croire)* : **E2E** *(un test montant
  l'app entière vaut E2E pour une app offline-first sans backend — la tâche T12 d'US-01.1 était
  **inexécutable** : `integration_test` absent, aucun appareil en CI)* · **revue humaine** *(clause
  reformulée en **obligation de process, non enforced** : `TRACKS.md` cesse de laisser croire à une
  barrière — cible à `0` approbation, `reviewDecision` structurellement vide)* · **Design Data** *(livré
  **réel mais borné**, aucun `N/A`)*.
  ⛔ **CE QUE L'ARBITRAGE NE FAIT PAS** : le **critère 27 demeure NON LEVÉ**, la **provenance reste non
  prouvable**, et la clause reformulée est **plus honnête, pas plus contraignante** — elle **abaisse
  l'exigence écrite au niveau du réel**. Voie de sortie réelle *(identité distincte pour les agents puis
  `restrictions`)* : **toujours portée par US-00.8**.
  ⚠️ **RESTE OUVERT, non traité par ADR-008** : `TRACKS.md` dit « Surface auth / sécurité / **admin** /
  paiement » là où la pratique constante du projet lit « surface **applicative** » — ⛔ **délibérément non
  édité** : modifier un **critère de sélection de track** changerait le track de toutes les US futures,
  ce qui exige son propre arbitrage.
- **Périmètre Art. 6 déclaré ≠ appliqué** : `.github/workflows/*` et `apply_branch_protection.sh` ne
  sont protégés ni par `protect_files.sh` ni par la Constitution → candidat `/audit-methodo`.
- **`governance.grandfathering_date` est une clé morte** : lue par aucun script, sémantique décalée
  (« US sans trace », pas « commits hors PR »). Laissée à `null` — à implémenter, redocumenter ou
  supprimer du schéma.
- Fichiers EPIC créés **rétroactivement** (EPIC_00, EPIC_01) — `/us-new` ne vérifie pas l'existence
  du fichier EPIC parent ; durcissement du rituel à décider.
- ⛔ **PÉRIMÉ-2026-08-06 — LES TROIS SONT TRANCHÉES DEPUIS LE 2026-08-01, cette entrée avait CINQ JOURS de
  retard sur le corpus du projet.** Relevé par **@UXDesigner** pendant `parallel_design` d'US-01.2, qui est
  **allé lire le corpus au lieu de reprendre cette liste** ; **vérifié par @Architect avant correction**.
  ⛔ **Le CLAUDE.md était en retard sur ce qu'il est censé résumer** — et c'est la classe de défaut nº 1
  sous sa forme la plus coûteuse : *une liste de questions ouvertes dont les réponses existaient déjà*, que
  tout agent démarrant une session aurait rouverte. **Ligne conservée, non repeinte** :
  *Décisions design à arbitrer (@UXDesigner + @PO) : gradient continu OKLCH (PRD) vs 4 paliers
  (maquette) ; endpoint bleu `#3D7DD8` (PRD) vs `#005ab3` (maquette) ; langue mixte fr/en des maquettes.*
  - ✅ **Gradient : CONTINU.** `DESIGN_SYSTEM.md` §*« Les 4 paliers ne sont PAS retenus »* — `#FFB68D` et
    `#AAC7FF` **ne sont pas des tokens de dégradé** ; l'interpolation se fait entre les deux **extrémités**
    et **jamais par un palier**, *« pour rendre l'erreur difficile »*.
  - ✅ **Endpoint : `#3D7DD8`, ET IL EST TRANCHÉ PAR CALCUL, pas par goût** — **4,53:1** contre **3,81:1**
    pour `#005AB3` de la maquette, qui *« passe 3:1 (le nombre) et échoue 4,5:1 (la description) »*.
    **Le code le porte** : `concentration_tokens.dart` → `static final Rgb gradientBleu = Rgb.hex('#3D7DD8')`.
  - ✅ **Langue : FRANÇAIS UNIQUEMENT.** `DESIGN_SYSTEM.md` §*Langue du produit* — *« cette décision clôt
    l'arbitrage langue mixte fr/en des maquettes »*.
  - ⚠️ **Aucune des trois ne bloquait US-01.2** — et aucune n'aurait été rouverte si quiconque avait lu le
    `DESIGN_SYSTEM.md` plutôt que ce résumé. **Candidat `/audit-methodo`** : rien ne détecte qu'une entrée
    du CLAUDE.md a été **réfutée par le corpus** qu'elle prétend résumer.
**US bloquées** : —
**Actions humaines en attente** :
- ✅ **FAIT (2026-08-01)** : **PR #22 fusionnée** *(certification d'US-00.6)* — `main` = **`0126582`**,
  `mergedBy` **`gitgdx`**, `12:13:31Z`, **4 contextes `success`** relevés sur le commit fusionné `ee7f6d4`.
  ⚠️ Provenance **déclarative** *(`is_bot` rend `false` même pour un agent)*.
- 🎯 **PROCHAIN PAS AU 2026-08-06 — @Developer, tâches T1 → T15 d'US-01.2.** Le design est **verrouillé**
  *(`EVT_DESIGN_COMPLETED` émis)*, la branche `feat/US-01.2-design` porte **3 commits**.
  ⚠️ **Chaque tâche = un commit, code ET tests ENSEMBLE** — le cliquet est à **marge NULLE**, budget
  **`U ≤ 0,048·N + 0,152`** *(~1 ligne non couverte pour 21 ajoutées)*. ⛔ **La valeur du cliquet se LIT**
  dans `factory.config.json` → `adapter.components.app.coverage_ratchet.value`, **jamais recopiée**.
  📌 **Une question laissée OUVERTE pour lui, délibérément, à trancher avant T9** : champs textuels **vs**
  sélecteurs natifs *(`flutter_localizations` = **+2 paquets** mesurés — lui-même et `intl`)*. ⛔ **Non
  bloquante : AC-16 protège les deux options** — *un lock ne tranche pas ce qui n'a pas besoin de l'être
  avant sa tâche.*
- ⛔ **PÉRIMÉ-2026-08-06 : les deux entrées suivantes sont FAITES.** La PR de clôture d'EPIC_00 **et** la
  PR d'US-01.1 sont fusionnées *(PR #29, #30, #31 ; `main` = `fe85364`)*, et **US-01.2 a démarré**.
  *(Conservées, non repeintes — elles portaient le motif de l'ordre choisi, qui a payé.)*
- 🎯 **PROCHAIN PAS — fusionner la PR de CLÔTURE d'EPIC_00** *(branche
  `feat/US-00.6-cloture-epic00`)* : **4 contextes requis verts**, puis **fusion PAR L'HUMAIN, sans
  `--admin`** *(renforcement **R-c**)*. ⚠️ **Une par une** : `strict: true` sérialise les merges.
- 🎯 **PUIS — US-01.1, le produit** *(et non US-00.8)*. Ordre recommandé et son motif : la factory
  **n'a jamais tourné sur du code produit** *(`lib/` = 1 fichier de 63 lignes, 0 scénario Gherkin exécuté,
  0 migration exécutée)* ⇒ **écrire plus de gouvernance ne testera jamais la gouvernance**. Deux décisions
  à poser **au démarrage**, pas en route : **(1)** l'**arbitrage `TRACKS.md`** *(ci-dessus, bloque
  l'Integration Lock)* · **(2)** les **8 `.feature` sans runner** — soit un **runner BDD réel** est
  financé, soit les DoD cessent d'écrire « N scénarios Gherkin » comme un livrable et disent
  **« spécification, non exécutée »** ; en l'état chaque DoD porte une ligne qui **ressemble** à un test.
- 🆕 **Créer `US-00.8` (US de dette) via `/us-new`** — décidé par l'**arbitrage @PO du 2026-07-28**
  (`reports/US-00.7/po_arbitrage_s11.md`). ✅ **Le verrou est LEVÉ** : US-00.7 est **certifiée et
  fusionnée**, donc l'interdiction d'éditer `docs/stories/US-00.1-*` « depuis la branche d'US-00.7 »
  *(qui aurait fait tomber son critère 23)* **n'a plus d'objet**. Porte la **requalification tracée
  d'US-00.1** (S11) en **additif daté**, et les dettes déjà identifiées : **NB-1bis** · **`selftest` en
  CI** · **identité distincte pour les agents + `restrictions`** *(seule voie pour rendre la fusion par un
  agent **impossible** et non seulement interdite — fusionnée avec la dette `TRACKS.md`)* · **lacune de la
  grille de test** *(aucun critère de **cohérence temporelle** du corpus vivant — établi deux fois par la
  QA)* · **« un critère de sortie se publie comme un script exécutable »** · et les **findings non
  bloquants** des audits (N-1 traité, **N-2** `pip install` nu, **N-3** forks, actions à tag mutable,
  `emitter` non enforced). ⚠️ **NON requise pour clore EPIC_00** — son report est un choix assumé.
- ✅ **RÉSOLU-2026-08-01 — l'item Art. 4 relevé par le @PO est soldé** *(entrée conservée parce qu'elle
  était une action en attente, pas effacée)* : le bloc *Enforcement* nommait `ci.yml` **seul** alors que le
  **4ᵉ** contexte requis provient de `branch-naming.yml`. **Vérifié dans le texte, pas de mémoire** :
  l'article **nomme désormais les deux** et son encadré d'amendement **conserve la trace du défaut**
  *(Constitution `1.2`)*.
- ✅ **FAIT** : `gh` CLI installé (2.96.0) et authentifié `gitgdx` avec `admin: true`. Chemin absolu si
  absent du `PATH` d'une session ouverte avant l'install : `C:\Program Files\GitHub CLI\gh.exe`.
- ✅ **FAIT** : `factory.config.json` porte `required_approving_review_count: 0` (`enforce_admins: true`).
- ✅ **FAIT** : T4 (`scripts/factory_sync.py`), T5, T6 et T22 (`scripts/githooks/pre-push` — le hook ne
  se réclame plus de la protection de branche) — toutes les actions humaines d'US-00.4 sont soldées.
- ✅ **FAIT (2026-07-27)** : **déblocage** de la protection de branche — **voie (a), dépôt rendu PUBLIC**
  (Art. 5). ⚠️ **Exposition irréversible** de tout l'historique pour ce qui a été publié ; `gitleaks`
  devient une barrière **critique**. **FAIT (2026-07-28)** : le **`PUT`** d'application (T8 d'US-00.7) et
  le **test négatif serveur** (T10) — les deux seules opérations à confirmation humaine explicite.
- ✅ **FAIT (2026-07-28) : US-00.7 T20 — `scripts/githooks/pre-push` (Art. 6)**. Son en-tête ne se
  réclame plus d'être « le seul enforcement réel » ni d'une impossibilité de plateforme. **Copie
  humaine** (l'agent en est bloqué par `protect_files.sh`), diff de `reports/US-00.7/transmissions.md`
  **§8** — *et non celui du Story File, rédigé le 27 et rectifié depuis*. Logique **inchangée** (un seul
  hunk) et **exercée sans réseau** : `main` → `exit 1`, `feat/` → `exit 0`. Preuves :
  [`reports/US-00.7/t20_pre_push.md`](reports/US-00.7/t20_pre_push.md). **C'était la dernière action
  humaine Art. 6 d'US-00.7.**
- ✅ **FAIT (2026-07-30)** : **fusion de la PR #15** — la **dernière** action humaine d'US-00.7.
  `main` = **`e2bd626`**, `mergedAt` 12:12:35Z, `mergedBy` **`gitgdx`**, **sans `--admin`** →
  renforcement **R-c respecté**, aucun agent n'a fusionné. ⚠️ **Garantie DÉCLARATIVE** et assumée comme
  telle : `mergedBy.is_bot` rend `false` **même pour un agent**, qui opère avec le jeton de l'humain.
- **Planifier les dettes techniques restantes** : **NB-1bis** (complétude de la cible dans
  `_guard_mapping`) et **`selftest` en CI** — de préférence dans la **même** US de dette.
- Clarifier le statut de `US-INIT` (US à part entière vs simple porteur du Sprint 0).
- Décider la création de US-01.2 (Gestion des événements).
- ✅ **SANS OBJET-2026-08-06** : *« Arbitrages design ci-dessus »* — **les trois étaient déjà tranchés
  depuis le 2026-08-01**, cette action attendait donc une décision **déjà prise**. Voir l'entrée datée
  correspondante dans les dettes ci-dessus.

## Anti-patterns (à ne pas reproduire)

| Anti-pattern | Barrière actuelle |
|---|---|
| Implémenter sans visa @PO | `/us-new` + machine à états (EVT_STORY_READY requis) |
| Modifier une US certifiée sans re-audit | re-ouverture du cycle = nouveaux événements obligatoires |
| Committer sans PROJECT_LOG / `--no-verify` | hooks git + hook Claude Code + CI |
| Certifier sans déployer (`🚀 OUI` + `⏳`) | `check_scb_compliance.py` bloquant partout |
| Auditer son propre code dans la même session | `/audit-us` (contextes frais) |
