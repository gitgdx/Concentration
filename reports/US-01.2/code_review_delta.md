# Audit de revue de code — **RE-REVUE (delta)** — US-01.2 « Gestion des échéances (CRUD) »

> ⛔ **Ce fichier ne remplace PAS [`code_review.md`](code_review.md).** Le verdict `PASSED` du
> 2026-08-07 portait sur `5272ed1` ; il a été **périmé** par l'audit sécurité parallèle *(application
> de **NB-6**)*. Les deux rapports restent lisibles côte à côte, comme pour US-01.1
> *(`*_delta2.md`, `qa_delta.md`)*.

| Champ | Valeur |
|---|---|
| **Verdict** | ✅ **PASSED** |
| **Visa de code porté sur** | **`2d77778`** *(dernier commit touchant `lib`/`test`/`scripts`/`pubspec*`)* |
| **HEAD audité** | **`c2a5d0d`** — vérifié : `git diff --name-only 2d77778..HEAD -- lib test scripts pubspec.yaml pubspec.lock` rend **0 fichier** *(annexe A)* |
| **Delta examiné en priorité** | `git diff 5272ed1..2d77778` — `ca05128` *(correctif `B-1`)* + `2d77778` *(`NB-B` + `NB-A`)* : **8 fichiers `lib`/`test`, +579/−30** *(annexe A)* |
| **Revue portée** | **tout** le code de l'US *(`git diff main...HEAD`)*, pas seulement le delta |
| **Auditeur** | @CodeReviewer — contexte **frais**, n'a pas produit ce code, ⛔ n'a pas recyclé le rapport précédent |
| **Modèle** | claude-opus-5[1m] |
| **Date** | 2026-08-11 |
| **Findings BLOQUANTS** | **0** |
| **Findings NON BLOQUANTS NOUVEAUX** | **4** — **NB-I** *(HIGH)* · **NB-J** *(LOW)* · **NB-K** *(LOW)* · **NB-L** *(observation)* |
| **Non bloquants du 2026-08-07** | **2 FERMÉS** *(NB-A, NB-B)* · **6 SUBSISTANTS** *(NB-C → NB-H)*, tous **hors du périmètre du delta** — report assumé, précédent du **GEL** d'US-00.6 |
| **Mutants joués par l'auditeur** | **5** — **4 tués**, **🔴 1 SURVIVANT (MR-3)** · **3 sondes** exécutées · arbre restauré *(annexe G)* |

> ⛔ **Aucun nombre et aucun emplacement ne sont écrits à la main ici.** Chaque chiffre est **lu dans
> une sortie collée en annexe** ; chaque emplacement est désigné **par son texte**, ⛔ jamais par un
> numéro de ligne. **Une seule exception assumée et signalée comme telle** : les numéros de ligne de
> `lcov.info` et de la sortie `--- DA:` d'annexe E, qui **sont** la donnée mesurée.

---

## 0. Deux faits de contexte, mesurés, à ne pas dissimuler

1. **Une session d'audit sécurité tournait EN PARALLÈLE de la mienne, sur le MÊME arbre de travail.**
   Constaté par exécution : un fichier non suivi `test/zz_audit_secu_delta_test.dart` est apparu puis a
   disparu pendant ma session, et l'arbre porte désormais `?? reports/US-01.2/security_delta.md`
   *(annexe A)*. ⚠️ **Conséquence méthodologique, et j'ai agi en conséquence** : mes 5 mutants ont été
   joués dans un **`git worktree` isolé** *(détaché sur `c2a5d0d`)*, ⛔ **jamais dans l'arbre partagé** —
   sans quoi mes mutants auraient fait rougir leurs mesures et leur sonde aurait faussé mes décomptes.
   Le worktree est **supprimé** ; `git worktree list` ne rend plus qu'un seul arbre *(annexe G)*.
2. **La trace montre que ce re-audit sécurité a rendu `EVT_SECURITY_AUDIT_FAILED` le
   2026-08-11T17:05:26** *(annexe F, ligne lue dans `docs/trace/US-01.2/events.jsonl`)*.
   ⛔ **Je n'ai PAS lu `security_delta.md`**, et mon verdict a été formé **avant** de lire cette ligne
   de trace. **C'est le dispositif voulu** : deux grilles, deux verdicts indépendants — le précédent
   cycle a déjà produit `revue PASSED` + `sécurité FAILED` sur le même commit. ⚠️ **Ce que cela
   implique pour le lecteur** : mon `PASSED` **n'atteste rien sur la grille sécurité**, et mon finding
   **NB-I** ci-dessous relève **précisément** de cette grille-là *(perte de données silencieuse)*.

---

## 1. Verdict et son motif — les 5 critères bloquants, un par un

| Critère bloquant | Constat | Preuve |
|---|---|---|
| Erreur lint / typecheck sur le code de l'US | `dart format` : **`Formatted 59 files (0 changed)`** · `flutter analyze` : **`No issues found!`** | annexe B |
| Duplication manifeste | **Aucune, et le delta en RETIRE une** : la mise de côté vivait en **deux exemplaires en germe** *(branche `racine == null` et, désormais, branche `DocumentIllisible`)* ; elle est factorisée dans **`_misDeCotePuisEtatVide`**, en **un seul exemplaire**, motif écrit. Les fixtures de `B-1` sont **trois fonctions dans le harnais**, ⛔ pas des littéraux recopiés dans deux fichiers de test. La boucle de réessai du harnais est factorisée dans **`_lireOctets`** | §2, §3 |
| Requête N+1 | **Sans objet mesuré** : aucune base relationnelle, aucune boucle d'accès. Le magasin lit et écrit **le document entier**, une fois. ⚠️ **Le delta n'ajoute AUCUN accès** : `lire()` reste **un** `existsSync` + **un** `readAsString` | §3 |
| Code nouveau sans test | **Aucun fichier nouveau sans test.** Les **5 fichiers de `lib/`** du delta sont tous exercés, et le delta livre **+12 tests** *(`344 → 356`, décompte **lu** en annexe B et recoupé par le diff)*. ⚠️ **Une BRANCHE pré-existante reste non testée** — le `on Object` de `_mettreDeCoteSansBruit`, **mutant MR-3 SURVIVANT** : c'est **NB-I**, non bloquant pour le motif écrit au §5 | §4, §5, annexe G |
| AC non couvert par le code | **Aucun des 16 AC actifs.** Le delta **ne retire aucune assertion** et en **renforce** *(le matcher `estLu` assertionne le **contenu**, là où un `isA<DocumentLu>()` nu passerait sur un magasin rendant n'importe quoi ; l'ancien `expect(await lire(), contenu)` est donc conservé **en force égale, plus le type**)*. `check_gherkin_mapping.py` → **50 ↔ 50 inchangé**, et `git diff --name-only 5272ed1..2d77778 -- test/e2e/ tests/features/` rend **0 fichier** ⇒ ⛔ **aucun décompte dérivé n'a bougé** | §4, annexes C, D |

**Tous les gates bloquants passent : `Tous les gates bloquants passent (5 exécutés)`** *(annexe B)*.
**Le critère d'entrée transféré par EPIC_00 reste satisfait** : `migration_roundtrip_criterion.py` →
`VERDICT|OK|`, **8 assertions vertes**, **exit 0** *(annexe D)* — et il n'a **pas** été retouché par le
delta *(`git diff --name-only 5272ed1..HEAD -- scripts/ reports/US-01.2/generer_e2e.py` rend **0
fichier**, annexe A)*.

---

## 2. Le correctif de `B-1` : le type scellé — les 6 questions, une par une

### ① Le `switch` est-il réellement exhaustif, et **aucun site d'appel n'avale-t-il `DocumentIllisible`** ?

**Exhaustivité : OUI, et elle est doublement verrouillée** — j'ai vérifié les deux barrières, pas une :
* `LectureDocument` est `sealed` ⇒ pour Dart 3 le `switch` **statement** sur un type *always-exhaustive*
  est **vérifié par le compilateur** ;
* **et** le corps déclare `final String texte;` **avant** le `switch`, avec **une seule** branche qui
  l'affecte ⇒ une branche manquante rendrait `texte` *possiblement non affecté*, **deuxième erreur de
  compilation indépendante de la première**. ⚖️ C'est plus robuste que la seule scellure : la garde
  survivrait même si l'exhaustivité des `switch` statements était un jour relâchée.

**Sites d'appel : il n'y en a qu'UN, et c'est mesuré** — `grep -rn "lire()" lib/` rend **un seul appel**
*(`switch (await magasin.lire())` dans `echeance_document_repository.dart`)*, les autres occurrences
étant la **déclaration** du port et les **deux** implémentations *(annexe C)*. ⛔ **Aucun `default:`**,
⛔ **aucun `catch` autour du `switch`**. `implements DocumentStore` ne rend que **3** classes : les deux
de `lib/`, et `MagasinCompteur` **qui délègue** *(annexe C)*.

🔴 **MAIS — et c'est ma réponse complète à la question posée — un site AVALE bien l'illisible, non par
son TYPE mais par son EFFET, et je l'ai mesuré.** Voir **NB-I** au §5 : quand la mise de côté
**échoue**, `_mettreDeCoteSansBruit` **avale l'exception** *(`on Object`, corps vide)* et
`_misDeCotePuisEtatVide` **réinitialise quand même** `_document` à un document neuf ⇒ à partir de cet
instant `DocumentIllisible` est **indiscernable de `DocumentAbsent`** *(écriture autorisée)*, et
l'écriture suivante **écrase** le document illisible. **Sonde P1, sortie brute en annexe G.**

### ② Le stub ne rend jamais `DocumentIllisible` : cohérent, ou trou déguisé en décision ?

**Cohérent — mais pour un motif AUTRE que celui écrit dans le code, et l'écart est mesurable.**

* ✅ **La décision est juste, et pour une raison solide** : le stub **ne stocke rien**, donc
  « **absent** » est un énoncé **vrai** sur son support, et c'est bien `v0`. **Aucun trou** : sa moitié
  d'échec vit dans `ecrire()`, qui **lève** — c'est ce qui rend AC-17 observable, et le test l'assertionne
  *(`throwsUnsupportedError`)*, avec `mettreDeCote()` éprouvé de la même façon *(les trois tests du
  groupe R-15, lus dans le fichier)*.
* 🔴 **Le motif écrit, lui, est FAUX — sonde P2** : la doc dit *« annoncer « illisible » ferait tenter un
  `rename` qui lève »*. J'ai construit exactement ce cas *(un magasin qui rend `DocumentIllisible` **et**
  lève sur `mettreDeCote`)* : **`charger()` NE LÈVE PAS** *(`P2 charger() a LEVE ? false`)*, la tentative
  a bien lieu *(`tentatives de mise de cote = 1`)* et elle est **avalée**. ⇒ la conséquence annoncée
  **n'existe pas**, et pire : **l'écriture suivante réussit** *(`P2 creer().estReussi = true ;
  ecritures=1`)*. ➡️ **NB-K**, non bloquant : *une justification qui n'est pas la vraie raison est une
  règle qui dérivera*, et c'est **exactement la classe de `NB-A`** que ce même delta vient de fermer
  ailleurs.

### ③ Le changement de contrat casse-t-il une invariance déjà couverte ? Les 16 AC tiennent-ils par des **assertions sur l'exigence** ?

**Non, rien n'est cassé, et deux points sont RENFORCÉS.** Vérifié assertion par assertion sur le diff :

| Ce que le delta remplace | Force avant | Force après | Verdict |
|---|---|---|---|
| `expect(await lire(), isNull)` | *« pas de fichier »* | `isA<DocumentAbsent>()` | **égale**, plus le type |
| `expect(await lire(), contenu)` | égalité de chaîne | `estLu(contenu)` = `isA<DocumentLu>().having(contenu…)` | **égale + type** ⇒ ⛔ un magasin rendant *n'importe quoi* ne passe plus |
| `octets()` → `readAsStringSync` | décodage UTF-8 strict | `utf8.decode(octetsBruts())` | **égale** ; la boucle de réessai ne couvre plus que la **fenêtre de verrou**, ⛔ pas le décodage — **séparation correcte**, le harnais ne peut plus retenter 40 fois un document qui ne sera jamais décodable |
| *(nouveau)* | — | `octetsBruts()` / `octetsBrutsDe(nom)` | **STRICTEMENT nécessaire** : `octets()` **LÈVE** sur le document de `B-1` ⇒ la clause AC-11 *« ni réécrit ni supprimé »* ⛔ **n'était pas assertable** avant ce delta |

**Le test du stub gagne un contrôle négatif** *(`isNot(isA<DocumentIllisible>())`)* et le harnais **porte
son propre mutant** — que j'ai **joué** : **MR-4**, `poserOctets` qui ré-encoderait ⇒ **6 tests rouges**,
dont *« MUTANT — `poserOctets` qui RÉ-ENCODERAIT : les octets relus diffèrent »* *(annexe G)*.
⇒ **le harnais ne peut pas mentir sans faire rougir la suite**, ce qui est la condition pour que les 4
tests de `B-1` mesurent quelque chose.

**Les octets, précisément comme demandé** : les nouveaux tests **assertionnent bien sur les octets** et
le document fautif est prouvé **inchangé octet pour octet** — `expect(harnais.octetsBruts(), fautif)`
après `lire()`, et `expect(harnais.octetsBrutsDe(misDeCote), fautif)` après `charger()`, avec
`expect(harnais.octetsBruts(), isNull)` pour prouver que **la cible a bougé** *(⛔ pas seulement
« un fichier est présent »)*. **Le contrôle négatif est le même document à un octet près**
*(`documentDecodable()`)*, et **le verdict bascule** — c'est ce qui empêche « tout est illisible » de
passer.

⚠️ **Un point de minceur, mesuré, à connaître** : la branche `DocumentIllisible` de `charger()` est
tenue par **UNE seule** assertion — **mutant MR-2** *(l'illisible traité comme absent)* → **1 test
rouge**, et c'est un test **unitaire**, ⛔ **aucun scénario e2e**. Motif vérifié et légitime : le
scénario e2e *« Un enregistrement illisible n'est ni réécrit ni supprimé »* pose du **JSON invalide en
UTF-8 valide** *(`poser`)*, donc il emprunte la branche `racine == null`, ⛔ **pas** la branche neuve.
**Ce n'est pas un AC non couvert** *(la clause a son scénario, vert)*, c'est une **surface d'un seul
test** sur la branche neuve.

### ④ `NB-B` est-il réellement fermé, et la branche est-elle atteignable **sans fake** ?

**OUI, et les deux affirmations du @Developer sont vérifiées, ⛔ pas relues.**

* **Le correctif est là** : `return ResultatEcriture.echec(acte);` — le `const` a disparu.
* **Atteignabilité par deux chemins réels, sans aucun fake** : **vérifié dans le code des tests** —
  *(a)* `depotSur(harnais.magasin).supprimer('a')` **sans chargement préalable** *(magasin `io` réel,
  `_document` vaut `null`)* ; *(b)* un document de **version FUTURE** posé sur le disque puis
  **chargé pour de vrai**, ce qui met `_document` à `null` par la branche « version future ». ⛔ Aucun
  accès à l'état privé, aucun mock.
* **Mutant MR-5 = REPLAY du M3 du @Developer** *(acte re-codé en dur)* → **2 tests rouges**, exactement
  ceux qu'il annonce *(annexe G)*. Son chiffre est **confirmé par exécution**.
* ✅ **Le contrôle négatif est réel et il est le bon** : `creer` sur la **même** branche doit **rester**
  `enregistrement`, **et** les deux actes doivent **différer** — `isNot(suppression.acteEchoue)`, une
  **assertion de GRANDEUR** au sens de l'acquis d'US-01.1 *(sans elle, un message unique passerait)*.
  Et le second test **lit le texte dans l'enum** *(`ActeEcriture.suppression.messageEchec`)* au lieu de
  le recopier ⇒ ⛔ pas de second exemplaire.

### ⑤ `NB-A` : « la doc avait tort » — ce raisonnement tient-il **contre les AC réels** ?

**OUI. Vérifié dans le Story File, ⛔ pas de mémoire.**

* **Motif ①** — *aucun AC n'exige ce refus* : **confirmé**. Les 5 clauses d'AC-6 lues dans la table
  anti-orphelin ne parlent que de l'édition d'une échéance **listée** *(description reflétée, date
  recalculée, édition invalide refusée, échue refusée, annulation sans effet)*, et **aucune réfutation**
  d'AC-6 N/E/L ne mentionne l'absence de correspondance d'`id`. Aucun autre AC ne le fait.
* **Motif ②** — *clause sans surface* : **confirmé**, et c'est l'acquis ② du design de cette US, écrit
  dans le CLAUDE.md et dans le Story File. Le chemin est **inatteignable depuis l'IHM**.
* **Motif ③** — *changer le comportement serait un changement de périmètre* : **cohérent** avec le fait,
  déjà inscrit trois fois au corpus, qu'**aucun événement du catalogue ne modélise un changement de
  périmètre**. Sur un design **verrouillé**, en cycle de **correctif d'audit**, c'est la bonne voie.
* ✅ **Et le point qui rend la décision non réversible en silence** : un test **ÉPINGLE** le contrat réel
  *(succès, document réécrit **à l'identique**, `isNot(contains('Fantome'))`, existante intacte)*. ⇒ doc
  et code **ne peuvent plus re-divergér sans rougir**. C'était la seule faiblesse possible du choix
  « corriger la doc » ; elle est fermée.
* ⚠️ **Une borne est écrite dans le port et elle est juste** : ce succès **n'est pas** la garantie qu'une
  édition a modifié quelque chose ; distinguer les deux exigerait un **troisième acte** dans
  `ActeEcriture`. **Aucun appelant n'en dépend aujourd'hui** *(vérifié : `remplacer` n'a qu'un appelant,
  `EcheancesNotifier.modifier`)*.

### ⑥ Les 6 autres non bloquants — lesquels subsistent ?

**Voir §6.** **NB-C** et **NB-H** subsistent, **et je les CONSTATE sans les recompter comme neufs**,
conformément au précédent du **GEL** d'US-00.6. Idem **NB-D, NB-E, NB-F, NB-G**. Chacun est **vérifié
par exécution**, ⛔ pas supposé inchangé.

---

## 3. Qualité du delta — DRY, complexité, lisibilité

* ✅ **Le delta SUPPRIME de la duplication** au lieu d'en créer : `_misDeCotePuisEtatVide` réunit les
  **deux** familles d'illisible *(le document que le magasin n'a pas su rendre ; celui dont la racine ou
  la version est incompréhensible)* en **un seul traitement**, avec le motif écrit — *« deux copies
  auraient dérivé »*. C'est **exactement** la règle du projet appliquée d'elle-même.
* ✅ **Les fixtures de `B-1` vivent en un exemplaire**, et ce sont des **fonctions, pas des constantes**,
  avec le motif écrit *(une liste partagée pourrait être mutée par un test et fausser l'autre)* —
  point de détail qui montre que la règle a été **comprise**, pas récitée.
* ✅ **Le type attrapé est ÉTROIT** *(`on FileSystemException`, ⛔ pas `on Object`)*, motif écrit : un
  `on Object` masquerait les erreurs de programmation, *« exactement la classe de bug que cette garde
  corrige »*. **Vérifié cohérent** : `on Object` n'apparaît dans `lib/` que **3 fois**, toutes dans
  `echeance_document_repository.dart`, et **aucune** dans le nouveau code du magasin *(annexe C)*.
* ✅ **Complexité** : `charger()` gagne **3 branches** et **perd** un `if` ; aucune fonction n'excède
  l'échelle du fichier. `lire()` reste **4 lignes exécutables**.
* ⚠️ **Le ratio commentaire/code du delta est très élevé** *(≈ 84 lignes ajoutées à `document_store.dart`
  pour **4 déclarations**)*. **Ce n'est PAS un finding** : le corpus de ce projet exige que le motif d'un
  choix soit écrit **là où le choix vit**, et ces commentaires sont **falsifiables** *(ils citent des
  mesures)*. ⚠️ Sauf **deux** d'entre eux, qui sont **faux** : **NB-J** et **NB-K**.

---

## 4. Les 16 AC actifs — ce que le delta change, et ce qu'il ne touche pas

**Aucun AC ne perd de couverture.** Je n'ai **pas** re-audité les 16 AC de zéro : le rapport du
2026-08-07 l'a fait, et **le delta ne touche aucun fichier de `test/e2e/**` ni de `tests/features/**`**
*(mesuré, annexe A)*. J'ai donc vérifié **ce qui pouvait bouger** :

| AC | Effet du delta | Vérification |
|---|---|---|
| **AC-11** *(robustesse aux données illisibles)* | 🔴 **C'est l'AC du correctif.** Une **classe entière** de son « Erreur » — *fichier tronqué*, mot **littéral** de la clause — était **hors d'atteinte du harnais** avant ce delta. Elle est désormais exercée par **4 tests** au niveau du magasin et **3** au niveau du dépôt | **MR-1** *(replay de `allowMalformed: true`)* → **5 tests rouges** · **MR-2** → **1 rouge** · ⚠️ **NB-I** : une sous-branche de la clause reste réfutable |
| **AC-13** *(état vide atteignable)* | `DocumentAbsent` remplace `null` — **même sémantique**, désormais **nommée** | test *« aucun fichier ⇒ lire() rend DocumentAbsent (c'est `v0`) »` |
| **AC-17** *(échec d'écriture)* | **`NB-B`** : l'acte annoncé devient l'acte **réel** ⇒ la clause *« l'utilisateur doit savoir CE QUI n'a pas eu lieu »* cesse d'être fausse sur une branche | **MR-5** → **2 rouges**, `Expected: <suppression>` |
| **AC-6** *(édition)* | **`NB-A`** : la doc de `remplacer` dit désormais ce qui **EST** | test *« `remplacer` SANS correspondance d'id … SUCCÈS »* |
| **AC-12** *(migration)* | **inchangé**, et **non régressé** : `migration_roundtrip_criterion.py` **exit 0**, `A1…A8` verts | annexe D |
| **AC-1..5, 7, 8, 10, 14, 15, 16** | **aucun fichier touché** | annexe A |

⚠️ **Ce que je ne re-certifie pas** : les assertions des 12 AC non touchés sont celles auditées le
2026-08-07 ; mon visa les reprend **par constat de non-modification**, ⛔ pas par relecture intégrale.

---

## 5. Findings NOUVEAUX — **0 bloquant**

> Format : `[Fichier désigné par son texte] | [Problème] | [Correctif attendu]`

### 🔴 NB-I · **non bloquant sur MA grille, HIGH — et il relève de la grille SÉCURITÉ** · une mise de côté qui échoue transforme `DocumentIllisible` en `DocumentAbsent`, et l'écriture suivante ÉCRASE le document

`lib/features/echeances/data/echeance_document_repository.dart`, `_mettreDeCoteSansBruit` *(le
`on Object` dont le corps ne contient que des commentaires)* **et** `_misDeCotePuisEtatVide` *(qui
réaffecte `_document` **inconditionnellement**, que la mise de côté ait réussi ou non)*. |

**Trois mesures, aucune relecture** :

1. **Le mutant SURVIT — `MR-3`** : j'ai **désarmé** le `on Object` de `_mettreDeCoteSansBruit`.
   Résultat : **`All tests passed!` — 356/356, 0 rouge** *(annexe G)*. ⇒ ⛔ **aucun test de la suite ne
   fait jamais échouer `mettreDeCote()` à travers le dépôt.** C'est le **seul survivant** de ma campagne.
2. **La couverture ne peut PAS le voir, et c'est structurel** : le corps de ce `catch` ne contient **que
   des commentaires** ⇒ `lcov.info` n'y instrumente **AUCUNE ligne** — mesuré : les lignes instrumentées
   de la zone sont `[157, 158, 159, 163, 165]`, et *« la ligne `} on Object {` et son corps : **NON —
   AUCUNE ligne instrumentee** »* *(annexe E)*. ⇒ **97,9 % de couverture ne dit rien de cette branche,
   et ne le dira jamais.** **Quatrième confirmation de la thèse du projet**, sur du code produit réel.
3. **La conséquence est une perte de données SILENCIEUSE — sonde `P1`, magasin de PRODUCTION, ⛔ aucun
   fake** *(la mise de côté est rendue réellement impossible en plaçant un **répertoire** au nom exact de
   sa destination, celle-ci étant déterministe sous horloge injectée ; `File(dest).existsSync()` rend
   **false** pour un répertoire, donc la boucle anti-écrasement ne le voit pas et le `rename` échoue pour
   de vrai — **même technique que celle du @Developer pour AC-17**) :
   ```
   P1 charger() a rendu 0 echeance(s) sans lever
   P1 octets de la cible INCHANGES apres charger : true
   P1 creer().estReussi = true
   P1 octets de la cible ENCORE ceux du document illisible : false
   P1 la cible contient desormais : {"schemaVersion":2,"echeances":[{"id":"apres",...}]}
   ```
   ⇒ **le document illisible a été ÉCRASÉ.** Or c'est **mot pour mot** la réfutation qu'AC-11 « Erreur »
   inscrit dans sa propre table : *« l'enregistrement fautif est **réécrit ou supprimé** »*. Et cela
   contredit **l'invariant écrit dans `_ecrire` lui-même** : *« Écrire ici ÉCRASERAIT un document qu'on
   n'a pas su lire — le refus est la protection »*. 🔴 **La protection est désarmée exactement quand elle
   est nécessaire.**

⚠️ **Aggravant apporté par CE delta, et il faut le dire précisément** : le mécanisme est
**PRÉ-EXISTANT** *(la branche `racine == null` l'empruntait déjà avant `ca05128`)* — mais avant le
correctif, la famille de `B-1` **levait** et n'atteignait **jamais** ce chemin. Le delta y **route
désormais un document PARFAITEMENT VALIDE porteur des échéances réelles du pratiquant**, à un octet
près. **La sévérité du pire cas augmente ; le mécanisme, non.**

✅ **CE QUE J'AI CHERCHÉ ET N'AI PAS TROUVÉ, et qui pèse dans le classement** : un déclencheur
**réaliste**. J'ai testé l'hypothèse de la **limite de longueur de chemin Windows** — mise de côté à
**270** caractères pendant que la cible en fait **243** — **sonde `P4` : l'hypothèse est RÉFUTÉE sur cet
hôte**, le `rename` **réussit** *(`P4 fichiers apres charger : [echeances.json.illisible-…]`, annexe G)*.
⇒ **ma seule reproduction est FABRIQUÉE.** Les scénarios où la cible est verrouillée **échouent aussi à
l'écriture** *(le `rename` de l'écriture atomique visant le même fichier)*, donc **ne perdent rien**. |

**Pourquoi NON BLOQUANT sur ma grille, et je l'écris pour qu'un humain puisse me contredire
facilement** : *(a)* le mécanisme **précède** le commit que je vise ; *(b)* aucune clause d'AC n'est
**sans test** *(la clause a son scénario, vert)* ; *(c)* **aucun déclencheur réaliste n'est établi** ;
*(d)* ma grille borne le blocage à *lint/typecheck, duplication, N+1, code nouveau sans test, AC non
couvert* — et étirer « code nouveau sans test » jusqu'à un `catch` **inchangé** serait forcer un `FAILED`.
🔴 **Mais ma grille n'est pas la seule** : *« perte de données silencieuse »* est un critère de la grille
**sécurité**, et **NB-I doit lui être transmis**. ⛔ **Je ne le classe pas bas pour l'enterrer : je le
classe hors de MON mandat, en le nommant.** |

**Correctif attendu** *(⛔ pas une ligne, et il ne faut pas le croire trivial)* : faire **remonter
l'issue** de la mise de côté et **ne réinitialiser `_document` que si elle a réussi** — sinon
`_document` **reste `null`**, ce qui **refuse toute écriture** *(le mécanisme de protection existe déjà,
il suffit de ne pas le désarmer)*. Le pratiquant voit alors l'état vide **et** un refus d'écriture
honnête, au lieu de perdre son document. **Avec son test** : un magasin dont `mettreDeCote` lève, et
l'assertion que l'écriture suivante est **refusée** et que **les octets sont intacts** — c'est-à-dire le
test qui aurait **tué MR-3**.

### ⚠️ NB-J · non bloquant · LOW · `charger()` promet « ⛔ NE LÈVE JAMAIS » — et rien ne le garantit

`lib/features/echeances/data/echeance_document_repository.dart`, doc de `charger()` :
*« 🔴 ⛔ NE LÈVE JAMAIS »*. | C'est une **affirmation absolue** qu'**aucun mécanisme n'enforce** — ni
type de retour, ni test, ni gate. Et le même corps contient **`codec.decoderDocument(migrer(racine)!)`**,
que l'audit sécurité a déjà nommé *(N-7)* comme *« de la famille de `B-1` »* : un `!` séparé de sa garde
par une vingtaine de lignes. ✅ **Vérifié sûr AUJOURD'HUI, par lecture des trois chemins** *(version
absente / non entière / `< 1` ; version future ; cible hors bornes — tous gardés en amont, `cible`
valant `versionCourante` par défaut)* **et par sonde `P3`** *(clés de tête inconnues ⇒ ne lève pas)*.
⚠️ **Mais la promesse est plus large que ce qui est prouvé**, et c'est **la classe même de `NB-A`** que
ce delta vient de fermer trois paragraphes plus haut : *un contrat écrit qui n'est pas garanti dérive*. |
**Correctif** : soit borner la phrase *(« ne lève pas pour un document illisible ou absent »)*, soit la
**garantir** — `final migre = migrer(racine); if (migre == null) return _misDeCotePuisEtatVide();`,
correctif que l'audit sécurité a déjà rédigé. ⛔ Ne pas la « préciser vaguement ».

### ⚠️ NB-K · non bloquant · LOW · le motif écrit dans le stub est réfuté par la mesure

`lib/features/echeances/data/document_store_stub.dart`, doc de `lire()` : *« annoncer « illisible »
ferait tenter un `rename` qui lève (voir [mettreDeCote]) »*. | **Sonde `P2` : la conséquence annoncée
n'existe pas** — l'exception est **avalée** par `_mettreDeCoteSansBruit`, `charger()` **ne lève pas**, et
l'écriture suivante **réussit** *(annexe G)*. Le chemin est de plus **inatteignable** aujourd'hui, ce qui
rend le motif **doublement inopérant**. ⚠️ **La décision, elle, est BONNE** — mais pour la raison
**qui n'est pas écrite** : *le stub ne stocke rien, donc « absent » est VRAI*. |
**Correctif** : remplacer le motif par le vrai. ⛔ Ne pas conserver les deux : *une règle n'existe qu'en
un seul exemplaire*, et ici l'exemplaire écrit est **faux**.

### ⚠️ NB-L · non bloquant · **observation, ⛔ pas un finding établi** · une exécution non déterministe

`test/features/echeances/presentation/widgets/formulaire_echeance_test.dart`, test *« AC-7 / AC-17 — le
dialogue de confirmation « Supprimer » écrit, puis le dialogue se ferme »*. | **Observé UNE fois** en
rouge, sous le mutant **MR-2**, puis **vert au second passage du MÊME mutant** — deux exécutions,
verdicts différents, arbre identique. | ⛔ **Je n'établis PAS une instabilité** : sur l'arbre **propre**,
ce fichier passe **5 fois sur 5** *(`run1…run5 : All tests passed!`, annexe G)* et la suite complète est
verte à chacun de mes passages. Les tests de cette US écrivent sur un **vrai disque** sous `runAsync`, et
le harnais **documente déjà** une fenêtre de verrou Windows *(« errno 32 », « une fois sur trois »)*. |
**Recommandation** : le noter au dossier `/audit-methodo` — *un test non déterministe sous mutation rend
toute campagne de mutation ambiguë*, et ce projet dépend de la mutation faute de gate qui la mesure.

---

## 6. Statut des **8** non bloquants du 2026-08-07 — chacun VÉRIFIÉ, ⛔ aucun supposé

| # | Objet | Statut | Comment je l'ai vérifié |
|---|---|---|---|
| **NB-A** | doc de `remplacer` contredite par son implémentation | ✅ **FERMÉ** *(par arbitrage : la doc avait tort)* | Contrat réécrit **et** un test l'épingle ; les 3 motifs tiennent contre les AC réels — §2⑤ |
| **NB-B** | l'acte codé en dur dans `_ecrire` | ✅ **FERMÉ** | `ResultatEcriture.echec(acte)` ; **2 chemins réels sans fake** ; contrôle négatif ; **MR-5 → 2 rouges** — §2④ |
| **NB-C** | `check_e2e_persistance.py` : 2 angles morts mesurés | ⏳ **SUBSISTANT — hors périmètre assumé** | `git diff --name-only 5272ed1..HEAD -- scripts/` → **0 fichier** *(annexe A)*. ⛔ **Constaté, non recompté** *(précédent du GEL)* |
| **NB-D** | générateur e2e : chemin absolu, pas de `--check` | ⏳ **SUBSISTANT — hors périmètre assumé** | `grep -n "RACINE" reports/US-01.2/generer_e2e.py` rend toujours `Path(r"c:/Users/…")` *(annexe C)* ; fichier non modifié |
| **NB-E** | R-13 dévié dans les fixtures + fragilité de fuseau | ⏳ **SUBSISTANT** | `test/e2e/` **non touché** par le delta *(annexe A)* ; le critère imprime toujours **un seul** fuseau *(`offset_janvier=1:00:00`, annexe D)* |
| **NB-F** | AC-6 « Limite » n'a qu'un point d'application, dans un widget | ⏳ **SUBSISTANT** | `grep -rn "refusEditionEchue" lib/` : **un seul appelant**, et c'est **`gestion_echeances_page.dart`** — ⛔ toujours pas `valider` *(annexe C)* |
| **NB-G** | une ligne non couverte non nommée *(bouton « Fermer »)* | ⏳ **SUBSISTANT** | `lcov.info` : `gestion_echeances_page.dart` NON COUVERTES = **[117]**, et la ligne **117** est bien `onPressed: () => Navigator.of(context).pop()` du bouton **« Fermer »** *(annexe E)* |
| **NB-H** | deux assertions de message tautologiques *(`textContaining('9')`)* | ⏳ **SUBSISTANT — hors périmètre assumé** | `grep -rn "textContaining('9')" test/` → toujours **2 occurrences dans l'e2e** *(+2 hors e2e)* *(annexe C)* |

**Bilan : 2 fermés / 6 subsistants**, et **les 6 sont TOUS hors du périmètre des deux commits du delta**.
⚖️ **C'est cohérent avec le précédent du GEL d'US-00.6** : dans un cycle de **correctif d'audit**, un
non bloquant antérieur non traité est **reporté**, pas re-instruit. ⛔ **Aucun des 6 n'est devenu
bloquant** — vérifié un par un.

---

## 7. Ce que ce code **n'atteste PAS** — aussi précis que le reste

* ⛔ **`main()` n'a jamais été exécuté.** Le niveau réellement prouvé pour `B-1` est **`charger()` rend au
  lieu de lever, sur le magasin `io` réel**. Que `runApp` s'exécute ensuite et que le hub se dresse
  **reste non observé** *(borne **NM-8** : `path_provider` absent en test hôte)*. ✅ **Le @Developer
  l'écrit lui-même dans le test**, ⛔ il ne le déguise pas — je l'ai vérifié dans le corps du test.
* ⛔ **La permanence de `B-1` est fermée SOUS CONDITION que la mise de côté RÉUSSISSE** — c'est
  **NB-I**, et c'est la borne la plus importante de ce rapport.
* ⛔ **`DocumentIllisible` n'a jamais été produit par autre chose qu'un défaut d'ENCODAGE.** Le droit
  refusé et la fenêtre TOCTOU sont **annoncés** par le commentaire de `lire()` et **jamais provoqués** —
  ⚠️ ce sont pourtant les deux seules causes **réalistes sur un appareil**, celle d'encodage étant liée
  à une édition manuelle du fichier.
* ⛔ **La suite n'a tourné que sous UN fuseau** *(le critère l'imprime : `offset_janvier=1:00:00`)* et
  **sur un seul système de fichiers** — or **NB-I** dépend précisément du comportement du `rename`.
* ⛔ **Aucun SAST, aucun scan de CVE** ; `deps_audit` mesure l'**obsolescence**.
* ⛔ **`check_gherkin_mapping.py` compare des TITRES** — *il l'imprime lui-même* — et **50 ↔ 50
  inchangé** signifie ici quelque chose de précis : **le delta n'a ajouté AUCUN test e2e**, donc ce
  contrôle **n'a rien vu du correctif**. Ce qui a vu le correctif, ce sont **12 tests unitaires** et
  **mes 5 mutants**.
* ⛔ **Je n'ai vu aucun écran.** Mon verdict porte sur du code, des assertions, des sondes et des sorties
  d'outils.
* ⛔ **Je n'ai pas lu `reports/US-01.2/security_delta.md`** *(cf. §0)*.

---

## 8. Ce qui reste dû à d'autres rôles — ⛔ je ne le tranche pas

* La **hausse du cliquet** est **signalée par le gate** *(`[HAUSSE] 97.91% (938/958) > cliquet 95.2%.
  Valeur a consigner … : 97.9` + `Action HUMAINE : factory.config.json est protege`)*. ⚖️ **Le cliquet
  RESTE à 95,2 par arbitrage humain du 2026-08-07** : ⛔ je ne le re-litige pas et **je n'ai touché à
  aucun fichier de configuration**.
* **NB-I** doit être **transmis à la grille sécurité** *(perte de données silencieuse)* — et si elle le
  retient, il y sera **bloquant**, ce qui est cohérent : *ma grille ne mesure pas ce que la sienne
  mesure.*
* **NB-6 appliqué à mon propre visa** : mon verdict porte sur **`2d77778`** *(code)* et **`c2a5d0d`**
  *(HEAD)*. ⛔ **Aucun champ `--commit` n'existe** dans `trace_append.py` ⇒ les deux SHA sont inscrits
  dans le `--rationale`, **convention non enforcée** qui réduit le risque sans le supprimer.
* **La péremption du visa de revue du 2026-08-07 est une DÉCISION DOCUMENTAIRE** : la borne mesurée par
  @Architect demeure — `EVT_QA_PASSED` n'exige que la **présence** des deux visas, **sans contrainte
  d'ordre** avec `EVT_CODE_READY` ⇒ **rien dans la machine à états ne périme un visa**. ➡️
  `/audit-methodo`.

---

# Annexes — sorties BRUTES

## Annexe A — périmètre, isolation, état de l'arbre

```
$ git log --oneline -6
c2a5d0d docs(us-01.2): peremption des deux visas d audit actee, cellules remises a l attente
cd789d5 chore(us-01.2): EVT_CODE_READY re-emis apres correctif de B-1, NB-B, NB-A
2d77778 fix(echeances): NB-B l'acte reel dans le refus, NB-A la doc dit ce qui EST
ca05128 fix(echeances): B-1 — un document non decodable n'empeche plus le demarrage
eb69b0f docs(us-01.2): /audit-us — revue PASSED, securite FAILED sur B-1
5272ed1 docs(us-01.2): arbitrage humain — le cliquet RESTE a 95,2

$ git rev-parse HEAD
c2a5d0dee0db0693afd58c4a54d4c63f707fc48d

$ git diff --name-only 2d77778..HEAD -- lib test scripts pubspec.yaml pubspec.lock
(fin liste)                      <-- 0 FICHIER : le visa de code porte bien sur 2d77778

$ git diff --stat 5272ed1..2d77778 -- lib test
 lib/features/echeances/data/document_store.dart              |  84 +++++++++-
 lib/features/echeances/data/document_store_io.dart            |  39 ++++-
 lib/features/echeances/data/document_store_stub.dart          |   6 +-
 lib/features/echeances/data/echeance_document_repository.dart |  58 +++++--
 lib/features/echeances/domain/echeance_repository.dart        |  31 +++-
 test/features/echeances/data/document_store_test.dart         | 124 +++++++++++++-
 test/features/echeances/data/echeance_document_repository_test.dart | 179 ++++++++++++-
 test/support/magasin_temporaire.dart                          |  88 +++++++++-
 8 files changed, 579 insertions(+), 30 deletions(-)

$ git diff --name-only 5272ed1..2d77778 -- test/e2e/ tests/features/
(liste vide) = AUCUN test e2e, AUCUN .feature touche par le delta

$ git diff --name-only 5272ed1..HEAD -- scripts/ reports/US-01.2/generer_e2e.py
(fin)                            <-- 0 FICHIER : NB-C et NB-D non traites

$ git status --porcelain         # AVANT mes mutants
?? test/zz_audit_secu_delta_test.dart      <-- sonde d'une AUTRE session (audit securite)

$ git status --porcelain         # APRES suppression de mon worktree
 M docs/trace/US-01.2/events.jsonl
?? reports/US-01.2/security_delta.md       <-- production de l'AUTRE session
                                           ⛔ AUCUN M sur lib/ ni test/ : mon arbre est propre

$ git worktree list
C:/Users/guillaume.decroix/MesProjets/Concentration  c2a5d0d [feat/US-01.2-design]
                                           <-- un seul arbre : mon worktree isole est SUPPRIME
```

## Annexe B — `python scripts/run_gates.py`

```
$ python scripts/run_gates.py --gate format
▶ app.format — (.) $ dart format --output=none --set-exit-if-changed lib test
Formatted 59 files (0 changed) in 0.38 seconds.
✅ app.format
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate analyze
▶ app.analyze — (.) $ flutter analyze
Analyzing Concentration...
No issues found! (ran in 8.2s)
✅ app.analyze
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --gate test        (fin de sortie)
01:51 +355: …/test/e2e/gestion_echeances_test.dart: Une suppression qui ne peut pas être écrite laisse l'échéance en place
01:53 +356: All tests passed!
Couverture de lignes : 97.9% (938/958) - seuil requis : 95.2% (cliquet)
  plancher contractuel : 80.0%  |  cliquet = 95.2%, consigne le 2026-08-02 a PR27
  [HAUSSE] 97.91% (938/958) > cliquet 95.2%. Valeur a consigner (arrondie VERS LE BAS) : 97.9
      Action HUMAINE : factory.config.json est protege, aucun agent ne l'edite.
✅ app.test
————————————————————————————————————————
Tous les gates bloquants passent (1 exécutés).

$ python scripts/run_gates.py --all              (fin de sortie)
You are already using the newest resolvable versions listed in the 'Resolvable' column.
✅ app.deps_audit
▶ app.build — (.) $ flutter build web --release
Compiling lib\main.dart for the Web...
Wasm dry run succeeded. …
Compiling lib\main.dart for the Web...                             49,6s
√ Built build\web
✅ app.build
————————————————————————————————————————
Tous les gates bloquants passent (5 exécutés).
```

⚠️ **`356` tests, et le nombre est RECOUPÉ, pas seulement lu** : `344` au 2026-08-07 **+ 12 tests
ajoutés par le delta** *(4 pour `B-1` au magasin, 2 mutants de harnais, 3 pour `B-1` au dépôt, 2 pour
`NB-B`, 1 pour `NB-A`)* = **356**. ⇒ la sonde de l'autre session **n'a pas** contribué à ce décompte.

## Annexe C — mes comptages et mes greps, tous LUS dans une sortie

```
$ grep -rn "lire()" lib/ --include=*.dart
lib/…/document_store.dart:21:            (commentaire)
lib/…/document_store.dart:97:  Future<LectureDocument> lire();                     <-- LE PORT
lib/…/document_store_io.dart:59:  Future<LectureDocument> lire() async {           <-- impl. IO
lib/…/document_store_stub.dart:29:  Future<LectureDocument> lire() async => …      <-- impl. STUB
lib/…/echeance_document_repository.dart:35:    switch (await magasin.lire()) {     <-- UN SEUL APPELANT

$ grep -rn "implements DocumentStore" lib/ test/ --include=*.dart
lib/…/document_store_io.dart:21:class DocumentStoreFichier implements DocumentStore {
lib/…/document_store_stub.dart:21:class DocumentStoreStub implements DocumentStore {
test/…/echeance_document_repository_test.dart:20:class MagasinCompteur implements DocumentStore {  (DELEGUE tout)

$ grep -rn "catch\|on Object\|default:" lib/ --include=*.dart      (hors commentaires)
lib/…/echeance_document_repository.dart:84:      } on Object {      (echec d'ecriture de MIGRATION)
lib/…/echeance_document_repository.dart:137:    } on Object {       (echec d'ecriture -> refus TYPE)
lib/…/echeance_document_repository.dart:166:    } on Object {       (SWALLOW de la mise de cote -> NB-I)
⇒ AUCUN `default:` — AUCUN `catch` autour du switch — AUCUN `on Object` dans le magasin

$ grep -c "^  Scénario: " tests/features/US-01.2-gestion-echeances.feature   -> 50
$ grep "^  Scénario: " … | sort | uniq -d | wc -l                            -> 0
$ grep -c "testWidgets(" test/e2e/gestion_echeances_test.dart                -> 50
$ git diff --name-status main...HEAD -- lib/ | grep -c "^A"                   -> 15
$ git diff --name-status main...HEAD -- test/ | grep -c "^A"                  -> 13

$ grep -rn "dart:io\|path_provider" lib/ --include=*.dart      (imports seuls)
lib/features/echeances/data/document_store_io.dart:1:import 'dart:io';
lib/features/echeances/data/document_store_io.dart:3:import 'package:path_provider/path_provider.dart';
⇒ UN SEUL fichier importeur, son nom finit par `_io.dart` (ADR-009 §2 respecte)

$ grep -rn "refusEditionEchue" lib/ --include=*.dart                        (NB-F)
lib/…/domain/validation_echeance.dart:86:  RefusValidation? refusEditionEchue(…)  <-- declaration
lib/…/presentation/gestion_echeances_page.dart:104:  … refusEditionEchue(echeance) <-- SEUL appelant
⇒ toujours PAS appele depuis `valider` : NB-F SUBSISTE

$ grep -rn "textContaining('9')" test/ --include=*.dart                     (NB-H)
test/e2e/gestion_echeances_test.dart:489      test/e2e/gestion_echeances_test.dart:523
test/…/gestion_echeances_page_test.dart:208   test/…/formulaire_echeance_test.dart:241
⇒ les 2 occurrences e2e demeurent : NB-H SUBSISTE

$ grep -n "RACINE" reports/US-01.2/generer_e2e.py | head -3                 (NB-D)
13:RACINE = Path(r"c:/Users/guillaume.decroix/MesProjets/Concentration")
⇒ chemin absolu d'un poste, toujours aucun `--check` : NB-D SUBSISTE
```

## Annexe D — contrôles de gouvernance et critère d'entrée

```
$ python scripts/check_gherkin_mapping.py
T12b -- correspondance scenario <-> test (racine : C:\…\Concentration)
  tests/features/US-01.1-affichage-hub-grille.feature  13 scenarios
  test/e2e/hub_echeances_test.dart                     13 tests
  tests/features/US-01.2-gestion-echeances.feature     50 scenarios
  test/e2e/gestion_echeances_test.dart                 50 tests
OK : chaque scenario a son test et chaque test son scenario. Controle de CORRESPONDANCE DE TITRES -- pas de semantique.
EXIT=0

$ python scripts/check_gherkin_mapping.py --selftest
  [OK] corpus conforme => 0 ecart
  [OK] mutant test retire => refus qui NOMME le scenario
  [OK] mutant test orphelin => refus DISTINCT du manquant
  [OK] mutant titre renomme => manquant ET orphelin
  [OK] un titre a apostrophe est lu correctement
  [OK] les deux motifs sont DISTINCTS
Autotest : 6 assertions, 0 echec(s), 2 couple(s) sous controle.
EXIT=0

$ python scripts/check_e2e_persistance.py
== ADR-010 §1 : la racine est montée, le magasin est RÉEL ==
   fichier : test/e2e/gestion_echeances_test.dart
   fichier : test/e2e/hub_echeances_test.dart
[OK ] contrôle « magasin » : 0 écart(s)
[OK ] contrôle « racine » : 0 écart(s)
CONFORME — les deux contrôles d'ADR-010 §1 passent.
EXIT=0

$ python scripts/check_e2e_persistance.py --selftest
== AUTOTEST DE MUTATION de check_e2e_persistance ==
   8 sources (1 conforme + 7 mutants COMPORTEMENTAUX)
   Verdicts comparés en ENSEMBLES, ⛔ jamais en cardinaux.
[OK ] M0_conforme                        attendu=aucun obtenu=aucun
[OK ] M1_sous_arbre_multiligne           attendu=['racine'] obtenu=['racine']
[OK ] M2_motif_seulement_en_commentaire  attendu=aucun obtenu=aucun
[OK ] M3_magasin_factice                 attendu=['magasin'] obtenu=['magasin']
[OK ] M4_FakeClock_est_licite            attendu=aucun obtenu=aucun
[OK ] M5_faux_depot                      attendu=['magasin'] obtenu=['magasin']
[OK ] M6_stub_de_plateforme              attendu=['magasin'] obtenu=['magasin']
[OK ] M7_pumpWidget_sans_argument_connu  attendu=['racine'] obtenu=['racine']
Contrôles tués par au moins un mutant : ['magasin', 'racine']
AUTOTEST OK : les deux contrôles savent rougir, et sur les bons cas.
EXIT=0

$ python reports/US-01.2/migration_roundtrip_criterion.py
== CRITERE DE SORTIE : patron aller-retour ADR-005 sur le module REEL ==
   cible : lib/features/echeances/data/echeance_schema_migrations.dart
CONTEXTE|dart=3.12.2|offset_janvier=1:00:00.000000|offset_juillet=2:00:00.000000|non_inversibles_ici=a4,a6
ASSERTION|A1_contrat_couple|OK|
ASSERTION|A2_montee_transforme|OK|
ASSERTION|A3_aller_retour|OK|
ASSERTION|A4_idempotence|OK|
ASSERTION|A5_cles_inconnues|OK|
DETAIL|A6|a1=convertie a2=convertie a3=convertie a4=verbatim a6=verbatim
ASSERTION|A6_jamais_de_conversion_avec_perte|OK|
ASSERTION|A7_version_non_supportee|OK|
ASSERTION|A8_forme_canonique_civile|OK|
VERDICT|OK|
SATISFAIT -- 8 assertions vertes. …
EXIT=0

$ python scripts/validate_trace.py --us US-01.2
Traçabilité conforme.
EXIT=0

$ python scripts/check_scb_compliance.py
Lecture du SCB : C:\…\STORY_CERTIFICATION_BOARD.md
SCB conforme — Aucune violation détectée.
EXIT=0
```

## Annexe E — couverture : les 20 lignes non couvertes, et l'angle mort de `NB-I`

```
$ python <extraction depuis coverage/lcov.info>
lib/core/theme/concentration_theme.dart                    LF=  12 LH=  11 NON COUVERTES=[23]
lib/core/theme/concentration_tokens.dart                   LF=  14 LH=  13 NON COUVERTES=[14]
lib/core/color/rgb.dart                                    LF=  32 LH=  30 NON COUVERTES=[59, 60]
lib/features/echeances/domain/remaining_time.dart          LF=  15 LH=   1 NON COUVERTES=[37,39,…,52]
lib/features/echeances/presentation/gestion_echeances_page.dart LF= 88 LH= 87 NON COUVERTES=[117]
lib/features/echeances/data/document_store_stub.dart       LF=   7 LH=   6 NON COUVERTES=[42]
TOTAL lignes non couvertes = 20
```

**Lecture** : **même ENSEMBLE qu'au 2026-08-07** *(comparaison d'ensembles, ⛔ pas de cardinaux)*, à un
**déplacement** près : la ligne non couverte de `document_store_stub.dart` passe de **38** à **42** parce
que le delta y ajoute **4 lignes de doc** — c'est **`creerMagasin()`**, **borne NM-8**, ⛔ pas la garde.
`gestion_echeances_page.dart` **[117]** est **`onPressed: () => Navigator.of(context).pop()`** du bouton
**« Fermer »** ⇒ **NB-G subsiste**, à l'identique.

```
$ python <extraction des lignes INSTRUMENTEES de echeance_document_repository.dart>
SF: lib\features\echeances\data\echeance_document_repository.dart
lignes INSTRUMENTEES entre 155 et 172 : [157, 158, 159, 163, 165]
   DA:157,2   DA:158,2   DA:159,6   DA:163,2   DA:165,4
=> la ligne 166 (`} on Object {`) et son corps 167-170 sont-ils instrumentes ?
   NON — AUCUNE ligne instrumentee
```

🔴 **C'est la mesure de `NB-I` point 2** : le corps du `catch` ne contient **que des commentaires**, donc
`lcov` **ne l'instrumente pas** ⇒ **aucune couverture, à aucun seuil, ne pourra jamais signaler que cette
branche n'est pas exercée.** ⛔ *La couverture de lignes est aveugle à la force des assertions — et ici,
elle est aveugle à l'EXISTENCE de la branche.*

## Annexe F — la trace, lue et non recopiée

```
$ python <lecture de docs/trace/US-01.2/events.jsonl, 6 derniers>
2026-08-06T12:12:54+02:00 EVT_DESIGN_COMPLETED       architect
2026-08-07T15:24:06+02:00 EVT_CODE_READY             developer      | … commit 828aade. 15 taches sur 15 …
2026-08-07T17:37:01+02:00 EVT_SECURITY_AUDIT_FAILED  cyber-security | FAILED sur le commit 5272ed1 …
2026-08-07T19:05:30+02:00 EVT_CODE_REVIEW_PASSED     code-reviewer  | VERDICT PASSED sur le commit AUDITE 5272ed1 …
2026-08-10T19:13:49+02:00 EVT_CODE_READY             developer      | RE-EMISSION apres l audit du 2026-08-07 …
2026-08-11T17:05:26+02:00 EVT_SECURITY_AUDIT_FAILED  cyber-security | RE-AUDIT SECURITE US-01.2 en contexte frais …

$ python <lecture de scripts/events_catalog.json>
EVT_CODE_REVIEW_PASSED : emitter=code-reviewer, preconditions=["EVT_CODE_READY"]
⇒ precondition SATISFAITE (EVT_CODE_READY re-emis le 2026-08-10T19:13:49)
```

## Annexe G — mes 5 mutants et mes 3 sondes, dans un `git worktree` ISOLÉ

**Base de comparaison, dans le worktree détaché sur `c2a5d0d`** :
```
$ flutter pub get && flutter test
01:48 +356: All tests passed!            <-- BASE : 356 verts, arbre propre
```

### MR-1 — REPLAY du mutant **M2** du @Developer : `allowMalformed: true` *(le correctif PROSCRIT)*
```
MR-1 pose : allowMalformed: true (REPLAY du M2 du @Developer)
02:11 +351 -5: Some tests failed.
Failing tests:
  test/…/document_store_test.dart: 🔴 B-1 … UN SEUL octet 0x80 AJOUTÉ à un document parfait suffit
  test/…/document_store_test.dart: 🔴 B-1 … un SEUL octet cp1252 ⇒ DocumentIllisible, et lire() NE LÈVE PAS
  test/…/document_store_test.dart: 🔴 B-1 … un document TRONQUÉ en pleine séquence ⇒ DocumentIllisible
  test/…/echeance_document_repository_test.dart: … 🔴 B-1 — la PERMANENCE est FERMÉE …
  test/…/echeance_document_repository_test.dart: … 🔴 B-1 — un document NON DÉCODABLE : charger() REND l’état vide …
🔴 TUÉ — 5 tests. ⇒ le correctif que l'auditeur proscrit est REELLEMENT refuse par la suite.
```

### MR-2 — **NOUVEAU** : `case DocumentIllisible()` traité **comme `DocumentAbsent`** *(pas de mise de côté)*
```
MR-2 pose : DocumentIllisible TRAITE COMME DocumentAbsent
Failing tests:
  test/…/echeance_document_repository_test.dart: … 🔴 B-1 — un document NON DÉCODABLE : charger() REND
       l’état vide, et le fautif est CONSERVÉ OCTET POUR OCTET
  test/…/formulaire_echeance_test.dart: AC-7 / AC-17 — le dialogue … puis le dialogue se ferme   <-- NB-L
02:02 +355 -1: Some tests failed.        (2e passage du MEME mutant : 1 seul rouge)
🔴 TUÉ — mais par UN SEUL test, et il est UNITAIRE : aucun scenario e2e ne rougit (motif au §2③).
```

### MR-3 — **NOUVEAU** : le **SWALLOW** `on Object` de `_mettreDeCoteSansBruit` est **DÉSARMÉ**
```
MR-3 pose : le SWALLOW `on Object` de _mettreDeCoteSansBruit est DESARME
$ flutter analyze
warning - Dead code … echeance_document_repository.dart:165:16 - dead_code   (echafaudage du mutant)
$ flutter test
01:48 +356: All tests passed!
🔴🔴 SURVIVANT — 356/356 VERTS. AUCUN test ne fait jamais echouer `mettreDeCote()` a travers le depot.
   (2 passages, les deux verts)                                                    ==> NB-I
```

### MR-4 — **NOUVEAU** : `poserOctets` **RÉ-ENCODE** *(le harnais ne peut plus fabriquer l'entrée fautive)*
```
MR-4 pose : poserOctets RE-ENCODE
Failing tests:
  test/…/document_store_test.dart: le HARNAIS de test porte SON MUTANT (leçon NB-7)
       MUTANT — `poserOctets` qui RÉ-ENCODERAIT : les octets relus diffèrent
  test/…/document_store_test.dart: 🔴 B-1 … UN SEUL octet 0x80 AJOUTÉ …
  test/…/document_store_test.dart: 🔴 B-1 … un SEUL octet cp1252 ⇒ DocumentIllisible …
  test/…/document_store_test.dart: 🔴 B-1 … un document TRONQUÉ en pleine séquence …
  ... and 2 more
01:33 +350 -6: Some tests failed.
🔴 TUÉ — 6 tests, dont le mutant que le harnais porte LUI-MEME. ⇒ le harnais ne peut pas mentir.
```

### MR-5 — REPLAY du mutant **M3** du @Developer : l'acte **re-codé en dur** *(retour au défaut `NB-B`)*
```
MR-5 pose : REPLAY du M3 -- l'acte est RE-CODE EN DUR
Failing tests:
  test/…/echeance_document_repository_test.dart: … 🔴 NB-B — même refus sur un document de version
       FUTURE : la suppression dit « suppression »
  test/…/echeance_document_repository_test.dart: … 🔴 NB-B — un refus AVANT chargement porte l’acte
       RÉEL, ⛔ pas « enregistrement » en dur
01:34 +354 -2: Some tests failed.
🔴 TUÉ — 2 tests, EXACTEMENT le chiffre annonce par le @Developer. Confirme par execution.
```

### Sondes P1 · P2 · P3 — exécutées dans l'arbre principal **avant** la campagne, fichiers supprimés
```
$ flutter test test/zz_sonde_revue_delta.dart
SONDE P1 — mise de cote REELLEMENT impossible (un REPERTOIRE au nom exact de la destination,
           deterministe sous FakeClock ; magasin de PRODUCTION, AUCUN fake) :
P1 charger() a rendu 0 echeance(s) sans lever
P1 fichiers apres charger : [, echeances.json]
P1 octets de la cible INCHANGES apres charger : true
P1 creer().estReussi = true
P1 octets de la cible ENCORE ceux du document illisible : false
P1 fichiers apres creer : [, echeances.json]
P1 la cible contient desormais : {"schemaVersion":2,"echeances":[{"id":"apres","description":"Reprise",
                                  "dateEcheance":"2027-12-01T23:59"}]}
   ==> LE DOCUMENT ILLISIBLE A ETE ECRASE. AC-11 « Erreur » : « ni reecrit, ni supprime ».   NB-I

SONDE P2 — si le STUB rendait DocumentIllisible, charger() leverait-il ?
P2 charger() a LEVE ? false (capture=null)
P2 rendu = 0
P2 tentatives de mise de cote = 1
P2 creer().estReussi = true ; ecritures=1
   ==> la consequence annoncee dans la doc du stub N'EXISTE PAS.                              NB-K

SONDE P3 — contrat « charger() NE LEVE JAMAIS »
P3 cles inconnues => leve ? false                                                            NB-J
All tests passed!
```

### Sonde P4 — l'hypothèse d'un déclencheur RÉALISTE de `NB-I` est **RÉFUTÉE** sur cet hôte
```
$ flutter test test/zz_sonde_revue_delta2.dart
P4 longueur du chemin du repertoire = 228
P4 longueur du chemin de la cible   = 243
P4 longueur du chemin de la mise de cote = 270      (> 260, la limite MAX_PATH historique)
P4 pose de la cible reussie ? true
P4 charger() -> 0 echeance(s), sans lever
P4 fichiers apres charger : [echeances.json.illisible-1786383824186940]   <-- le rename REUSSIT
P4 creer().estReussi = true
P4 la cible porte-t-elle encore les octets fautifs ? false
All tests passed!
   ==> HYPOTHESE REFUTEE : les chemins longs ne declenchent PAS NB-I ici. Ma seule
       reproduction reste FABRIQUEE — et je le dis, plutot que de sur-vendre le finding.
```

### Contrôle de non-régression de `NB-L` sur l'arbre **propre**
```
$ for i in 1..5 ; flutter test test/…/formulaire_echeance_test.dart
run1 : 00:13 +26: All tests passed!
run2 : 00:12 +26: All tests passed!
run3 : 00:13 +26: All tests passed!
run4 : 00:13 +26: All tests passed!
run5 : 00:13 +26: All tests passed!
   ==> 5/5 VERTS : je n'ETABLIS PAS d'instabilite sur l'arbre propre. NB-L reste une OBSERVATION.
```

### Restauration — vérifiée
```
$ git worktree remove --force <worktree>
$ git worktree list
C:/Users/guillaume.decroix/MesProjets/Concentration  c2a5d0d [feat/US-01.2-design]
$ git status --porcelain
 M docs/trace/US-01.2/events.jsonl          <-- l'AUTRE session (audit securite)
?? reports/US-01.2/security_delta.md        <-- l'AUTRE session
⛔ AUCUN `M` sur lib/, test/, scripts/, pubspec* : mes 5 mutants et mes 4 sondes sont TOUS retires.
```

---

**Verdict final : ✅ PASSED — visa porté sur `2d77778`, HEAD audité `c2a5d0d`.**
**0 finding bloquant** · **4 non bloquants nouveaux** *(NB-I HIGH, NB-J LOW, NB-K LOW, NB-L
observation)* · **NB-A et NB-B FERMÉS** · **NB-C → NB-H SUBSISTANTS**, hors périmètre assumé.
🔴 **NB-I doit être transmis à la grille sécurité** : *mon mandat ne mesure pas la perte de données, le
sien la mesure.*

---

## Post-scriptum — un défaut de MON PROPRE instrument, trouvé en relisant ma sortie

⚠️ **À inscrire au dossier `/audit-methodo`, et il me concerne, pas le @Developer.**

En **relisant la sortie** de mon `trace_append.py` *(et non en la supposant)*, j'ai lu :

```
$ python scripts/trace_append.py --us US-01.2 --event EVT_CODE_REVIEW_PASSED …
/usr/bin/bash: line 1: texte: command not found
[OK] EVT_CODE_REVIEW_PASSED ajouté à docs\trace\US-01.2\events.jsonl
```

**Cause, mesurée** : mon `--rationale` contenait un mot entouré d'**accents graves**, que le shell a
interprété comme une **substitution de commande**. Résultat lu dans l'événement écrit :

```
… (sealed + affectation definie de ), UN SEUL appelant de lire() …
                                  ^ le mot a DISPARU
```

⛔ **La trace est APPEND-ONLY : je ne la réécris pas.** Le `rationale` déposé est donc **amputé d'un
mot**, sans que son sens soit inversé *(2927 caractères, aucun autre accent grave — vérifié par lecture
du JSON écrit)*. **La phrase exacte voulue était** : *« sealed + affectation définie de la variable
`texte` »*.

🔬 **Ce que cet incident établit, et qui vaut au-delà de moi** :
* `trace_append.py` **écrit sans broncher un `rationale` mutilé par le shell** — ⛔ **aucun contrôle** ne
  compare ce qui était voulu à ce qui est écrit, et `validate_trace.py` rend **`Traçabilité conforme.`**
  sur cet événement. **Même famille que `emitter` non enforcé** : le champ est **libre et non validé**.
* ✅ **Ce qui a rattrapé le défaut, c'est la RÈGLE DU PROJET** — *« le résultat se LIT dans la sortie »*.
  Un `[OK]` lu seul aurait masqué le `command not found` **imprimé une ligne au-dessus**.
* 📌 **Remède concret pour tous les agents** : passer les textes longs à `trace_append.py` **sans jamais
  d'accent grave**, ou via un fichier / `stdin` plutôt qu'un argument de shell. ⚠️ **Le corpus du projet
  emploie massivement les accents graves** *(Markdown)* : la collision est donc **structurelle, pas
  accidentelle**, et elle **se reproduira**.
