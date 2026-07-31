# 🧪 RE-AUDIT QA — US-00.5, PR nº 1 — 2ᵉ passage

| Champ | Valeur |
|---|---|
| **Agent** | @QA_Tester — **contexte frais** |
| **Modèle réel** | `claude-opus-5[1m]` |
| **Date** | 2026-07-31 |
| **Branche / HEAD** | `feat/US-00.5-adr-stack-constitution` · **`3c48a67`** *(1ᵉʳ passage : `e6d5c1d`)* |
| **PR** | **#17** — `OPEN`, `MERGEABLE`, `mergeStateStatus: CLEAN`, `headRefOid = 3c48a67` |
| **1ᵉʳ passage** | 🔴 `EVT_QA_FAILED` — 7 écarts, `reports/US-00.5/qa.md` *(⛔ non écrasé)* |
| **VERDICT 2ᵉ passage** | ## 🔴 **FAILED** |
| **Case DoD 18** | ⛔ **reste DÉCOCHÉE** |

---

## 1. Ce que je concède d'abord, parce que c'est dû

**Le diagnostic de @Architect sur mon propre instrument est EXACT, et je le retire.**

Mon `qa_assertions_chiffrees.sh` écrivait la colonne `écrit` **en dur** :
`chk "conformite_ac « iOS -> 6 »"   6   "$(grep -ci 'iOS' $ADR)"`. Ce `6` est la **transcription
d'une mesure**, recopiée à la main au moment de l'audit. Une transcription de mesure **périme**.
Conséquence exactement telle qu'il l'écrit : mon `ECART=0` est devenu **inatteignable** quand il a
**retiré** les chiffres de ses rapports **comme je le demandais**. **Mon instrument reproduisait, un
étage au-dessus, le défaut qu'il mesurait.**

> **La distinction qui sauve `verify.sh` et condamne mon v1** — et elle est le cœur de ce re-audit :
> * une valeur attendue qui est une **SPÉCIFICATION** ne périme pas *(« 1 ADR-001 doit exister »,
>   « 0 ADR accepté édité »)* → **légitime en dur** ;
> * une valeur attendue qui est la **TRANSCRIPTION d'une MESURE** périme à coup sûr *(« iOS apparaît
>   6 fois »)* → **jamais en dur**.
>
> **`verify.sh` n'écrit que des spécifications. Mon v1 écrivait des transcriptions.** C'est la
> différence entre un **test** et un **décalque**. `verify.sh` est **bien conçu** ; je le dis sans
> réserve, et c'est la première fois de ce dossier qu'un instrument de cette US l'est.

### 🔴 Et je dois retirer un écart de mon 1ᵉʳ rapport : **E-2 était une charge injuste**

- **Action** : le bloc *Critère 4* de `conformite_ac.txt` annonçait `iOS -> 6` **sans publier sa
  commande**. J'ai **reconstruit** cette commande en `grep -ci` *(insensible à la casse, par analogie
  avec le critère nº 4 du Story File, qui est `grep -ciE`)*.
- **Mesure du jour** : `grep -c 'iOS'` *(sensible)* → **6** · `grep -ci 'iOS'` *(insensible)* → **7**.
  L'ADR **n'a pas changé** *(`git diff --stat e6d5c1d..HEAD -- ADR-001` → 0 ligne)*.
- **Conclusion** : sous une lecture **sensible à la casse**, `-> 6` était **JUSTE**. Mon E-2 imputait
  à @Architect un écart **produit par MA reconstruction d'une commande qu'il n'avait pas publiée**.
  ⇒ **E-2 est retiré.** Le défaut réel sur cette ligne n'était pas *« chiffre faux »* mais
  *« chiffre INVÉRIFIABLE faute de commande publiée »* — une classe voisine, et moins grave.
  ⛔ **`qa.md` n'est pas repeint** : la rectification est ici, datée. **E-3 (`SAST -> 2`) survit aux
  deux lectures** — sensible **3**, insensible **4**, jamais **2**.

**Décompte rectifié du 1ᵉʳ passage : 6 écarts établis, 1 retiré.** Le verdict FAILED n'en dépendait
pas — E-1 seul, avec sa **commande publiée**, le portait.

---

## 2. Réponse directe : « comment atteindre `ECART=0` sans repeindre un artefact daté ? »

**On ne peut pas, et il ne faut pas essayer. Je retire mon v1 comme critère de sortie.**

⇒ **Le critère de test nº 20 du Story File, qui exige `ECART=0` sur `qa_assertions_chiffrees.sh`, est
MAL POSÉ et doit être remplacé.** Le maintenir installerait un rouge permanent ou pousserait à
repeindre des constats datés — les deux étant pires que le défaut. Mon v1 est **conservé comme
artefact daté** *(il a produit un verdict juste sur un corpus donné)*, **rétrogradé** comme
instrument.

**Mais `assertions_vives.sh` n'est PAS un substitut acceptable — et c'est établi par exécution, non
par lecture.** Voir §3 : il **blanchit** la seule assertion vivante du dossier.

**J'ai donc ré-instrumenté**, au lieu de défendre mon v1 :

```sh
sh reports/US-00.5/qa_detecteur_v2.sh ; echo $?
```

Ses règles de conception, chacune tirée d'une faute constatée de ce dossier :
1. **les deux côtés sont LUS** — la valeur écrite est **extraite** du rapport, jamais recopiée dans
   l'instrument *(correction de MON défaut)* ;
2. **AUCUNE exclusion par mot** — rien n'est jamais supprimé en silence ; ce qui n'est pas
   vérifiable est **affiché et compté** comme tel *(correction du défaut d'`assertions_vives.sh`)* ;
3. **il porte son PROPRE test de mutation** (§C) et **échoue** si ses mutants ne sont pas tous
   détectés — ⛔ **un vert non falsifiable est interdit** *(correction du défaut de `verify.sh` §7)* ;
4. **§D vérifie les désignations par numéro de ligne** — sous-contrôle objectif *(la ligne désignée
   ne doit pas être vide)* + sous-contrôle ciblé *(les emplacements du classement NB-1 doivent porter
   son motif)*.

**Critère de sortie : `ECART=0` ET `SANS_MARQUEUR=0` ET `autotest=8/8` ET `MORTES=0` ET
`NB-1-faux=0`.** Aucun de ses seuils n'est une mesure transcrite : ce sont des **spécifications**.

---

## 3. 🔴 LA SIXIÈME MANIFESTATION — elle existe, et le nouveau mécanisme la BLANCHIT

Tu m'as demandé d'en chercher une. Elle est là, et c'est **la plus grave de la série**, parce que ce
n'est plus seulement un chiffre faux : **c'est un chiffre faux recouvert par un contrôle vert**.

### 3.1 Le fait

- **Action** : `grep -nE '\->[[:space:]]*[0-9]+' reports/US-00.5/conformite_ac.txt`
- **Ligne trouvée** (elle **publie** sa commande, contrairement à toutes celles que tu as traitées) :
  `$ grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md -> 2`
- **Résultat attendu** *(écrit dans le rapport)* : **2**
- **Résultat obtenu** *(la commande, rejouée par `qa_detecteur_v2.sh`)* : **5**
- **La ligne ne porte AUCUN marqueur** : `grep -coE 'PERIME-2026-07-3|capture|DATEE|valeur retiree'`
  sur cette ligne → **0**. Ce n'est donc **pas** une capture datée : c'est une **assertion vivante**.

**C'est mon écart E-1 — le seul des sept dont la commande était PUBLIÉE, donc le moins contestable —
et il a survécu intact au correctif.** Le traitement `[valeur retiree — source vive : …]` a été
appliqué aux **critères 4, 15 et 9** de ce même fichier, et **pas** au **critère 14**.

### 3.2 L'aggravation, et c'est elle qui fait le FAILED

`assertions_vives.sh` **ne la voit pas**, et pas par hasard. Son pipeline est :

```
grep -nE '\->[[:space:]]*[0-9]+[[:space:]]*$' <fichier> | grep -viE 'CAPTURE DU|PERIME|PÉRIMÉ|valeur retiree'
```

- **sans** le filtre → la ligne **sort** *(vérifié : elle est le seul match du fichier)* ;
- **avec** le filtre → **rc=1, rien** *(vérifié)*.

**La chaîne `PÉRIMÉ` figure sur cette ligne PARCE QU'ELLE EST LE MOTIF DE LA COMMANDE.** L'exclusion
la supprime, et le détecteur annonce *« aucune assertion chiffrée résiduelle · RÉSIDUS : 0 · exit 0 »*
**par-dessus le défaut**.

> ⇒ **Ce n'est pas un angle mort, c'est un BLANCHIMENT.** Le piège que ce projet a documenté trois
> fois — *« un grep de motifs matche la documentation des motifs »* — revient ici **retourné en FAUX
> NÉGATIF** : jusqu'ici il **gonflait** les comptes, maintenant il **efface** une preuve. Une liste
> d'exclusion par mots, dans un corpus qui **documente ses propres motifs**, est un générateur de
> faux verts. **C'est structurellement le même mécanisme que les cinq fautes précédentes**, mais
> déplacé du rapport vers **l'instrument de contrôle** — l'endroit où il est le plus coûteux.

### 3.3 Test de mutation du détecteur — son « 0 » mesure-t-il quelque chose ?

8 formes d'assertion vive replantées, passées dans **son** pipeline exact :

| Forme | Détectée ? |
|---|---|
| `x -> 99` | ✅ |
| `label    -> 99   ` *(espaces finaux)* | ✅ |
| `x -> 99 occurrences` *(le nombre n'est pas en fin de ligne)* | 🔴 **non** |
| `x : 99` | 🔴 **non** |
| `x => 99` | 🔴 **non** |
| `PERIME x -> 99` | 🔴 **non** — *blanchi par l'exclusion* |
| `\| label \| 99 \|` *(tableau)* | 🔴 **non** |
| `$ grep -c "PÉRIMÉ-2026-07-28" fichier -> 99` **← le cas réel** | 🔴 **non** |

**Recall mesuré : 2 formes sur 8.** ⇒ le `RÉSIDUS : 0` d'`assertions_vives.sh` **n'est pas un
constat, c'est un vide de couverture**.

### 3.4 Son périmètre, également borné sans que ce soit dit

`RAPPORTS="reports/US-00.5/conformite_ac.txt reports/US-00.5/correctifs_failed_revue.txt"` — **2
fichiers**. Ne sont **pas** balayés : `verify.sh`, `verify_output.txt`, `sweep_transmissions.sh`,
`entry_state/**`, `code_review*.md`, `security.md`, **le Story File** *(qui porte désormais des
chiffres en prose : « CINQ faux verts », « 3 motifs sur 4 », « 7 assertions chiffrées »)* et **le
SCB** *(qui porte encore `DoD 23 cases` et l'énumération à 6 motifs de `protect_files.sh`)*.

---

## 4. Sortie de MON détecteur v2 — décompte de l'extension

```
sh reports/US-00.5/qa_detecteur_v2.sh   →   exit 1
VERIFIEES=1  ECART=1  SANS_MARQUEUR=7  captures-datees=0  autotest=8/8
DESIGNATIONS: examinees=12  MORTES=1  classement-NB-1-faux=1
```

| Catégorie | Nb | Nature |
|---|---|---|
| **ÉCART prouvé par ré-exécution** | **1** | `conformite_ac.txt:60` — §3. **Motif suffisant du FAILED.** |
| **Chiffres SANS commande ni marqueur** | **7** | *voir ci-dessous* — invérifiables, non blanchis |
| Captures explicitement datées | **0** | aucune ligne chiffrée ne porte de marqueur de péremption |
| **Désignations par n° de ligne MORTES** | **1** | `correctifs_...:27` → **la ligne 27 est VIDE** |
| **Classement NB-1 devenu faux** | **1** | `conformite_ac.txt:45` **ne porte plus le motif** |
| Autotest de mutation de v2 | **8/8** | son vert est falsifiable |

### 4.1 Les 7 chiffres sans commande — classés, sans les gonfler

Je les vérifie un par un, parce qu'un décompte brut serait malhonnête :

| Emplacement | Assertion | Exacte aujourd'hui ? | Nature du défaut |
|---|---|---|---|
| `conformite_ac:45` | `-> 0 = conforme` | ✅ oui | la **valeur** au-dessus a été remplacée par `[valeur retiree]`, **la conclusion chiffrée est restée** |
| `conformite_ac:57` | `-> 0 = AC-4 TENU` | ✅ oui | idem |
| `conformite_ac:92` | `-> 0 = AC-4 REELLEMENT TENU` | ✅ oui | idem |
| `correctifs:46` | `=> 0 charge ETEINTE non marquee` | ✅ oui *(`verify.sh` §6 → 0)* | conclusion chiffrée sans commande |
| `correctifs:66` | `-> 0 = corrige aux 3 emplacements` | 🔴 **c'est la FAUTE 1 auto-dénoncée** | **le marqueur `PERIME` n'est PAS sur cette ligne** *(vérifié : `grep -c 'PERIME'` sur la ligne → 0)* — la 1ʳᵉ leçon d'US-00.7 exige le marqueur **sur la ligne même** |
| `correctifs:78` | `-> 2 echecs attendus, 2 obtenus` | ✅ oui | conclusion chiffrée sans commande |
| `correctifs:119` | `=> 5 occurrences, 0 ASSERTION VIVANTE` | ✅ oui *au 2026-07-31* | **chiffre volatil** : il a valu 5, puis 8, puis 9, puis 10 selon ce qui s'écrit sur le sujet |

⇒ **6 des 7 sont exactes aujourd'hui.** Ce ne sont donc pas six faux verts : c'est **la même classe,
au stade où elle n'a pas encore produit de faux**. La leçon du dossier est précisément qu'elle en
produit **dès que le corpus bouge** — et le corpus bouge à chaque correction. **Le traitement
`[valeur retiree]` a été appliqué à la LIGNE DE VALEUR et pas à la LIGNE DE CONCLUSION** : c'est,
une fois de plus, **le renvoi corrigé et pas le défaut**.

### 4.2 Deux désignations par numéro de ligne ont **encore** dérivé

**E-6 survit et a dérivé une SECONDE fois** :

- **Action** : lire la ligne que `correctifs_failed_revue.txt:116` désigne (`correctifs_...:27`), puis
  localiser réellement la 5ᵉ occurrence du motif NB-1.
- **Attendu** : la ligne 27 porte la commande de `grep` du contrôle NB-1.
- **Obtenu** : **la ligne 27 est VIDE**. L'emplacement réel était **44** à mon 1ᵉʳ passage, il est
  **65** aujourd'hui. **Le numéro a glissé deux fois en deux jours**, dans le paragraphe qui enseigne
  qu'un numéro glisse.
- Et son voisin : `conformite_ac.txt:45`, classé « MA correction cite ce que j'avais écrit », **ne
  porte plus le motif NB-1** — la ligne 45 est désormais `-> 0 = conforme`.

⇒ **Sur les 5 emplacements du classement NB-1, 2 sont devenus faux.** Le bloc conclut pourtant
*« 5 occurrences, 0 ASSERTION VIVANTE »*. La conclusion reste **vraie** ; sa **traçabilité** ne l'est
plus. **11 désignations par numéro de ligne subsistent** dans les deux rapports.

---

## 5. Tes autres correctifs — ce qui tient, et ce qui ne tient pas

### 5.1 ✅ Ce qui tient, vérifié par exécution

| Correctif | Vérification | Verdict |
|---|---|---|
| `verify.sh` — source unique et vive | `sh reports/US-00.5/verify.sh` → **exit 0**, tous les contrôles bloquants passent | ✅ **et bien conçu** : que des **spécifications**, deux côtés calculés au §5, commande du contrôle négatif **enfin publiée** *(mon écart E-5 : traité)* |
| Critère nº 11 réécrit | `verify.sh` §4bis **LIT** la version : `1.0 2026-07-24`. Il ne suppose plus `^\*\*Version` | ✅ **traité** |
| Contradiction `app.format` | Arbitrée : `lint` couvre `app.format` **et** `app.analyze`, conforme à `entry_state`. **`app.build` est le seul gate non couvert**, et c'est celui qu'AC-3 prescrit de nommer | ✅ **levée**, cohérente |
| Motif du sweep élargi **dans le sweep** | `git diff e6d5c1d..HEAD -- sweep_transmissions.sh` : le motif est **réellement** remplacé dans le script, pas seulement dans `verify.sh` | ✅ **ce n'est PAS un renvoi** |
| DoD | **16 cochées / 7 décochées** *(23)*. Les 7 portent leur motif **dans la case** | ✅ **l'instrument n'est plus inerte** · **0 case cochée à tort** *(vérifié : 5, 6, 14, 15, 19, 23 dépendent bien de la PR nº 2 ou de l'humain ; 18 est la mienne)* |
| Case **19** classée partielle | **Tu as raison et j'avais tort** : la ligne PROJECT_LOG dédiée à l'amendement appartient à la PR nº 2. Mon décompte de **17** acquises était **trop généreux d'une case**. **Ton 16 est exact.** | ✅ **je concède** |
| Non-régression sur `3c48a67` | `run_gates.py --all` **exit 0** — 5 gates · **2 passed / 0 skipped / 0 failed** · couverture **89,5 % (17/19) ≥ 80 %** · `check_scb_compliance` **0** · `validate_trace --all` **0** · `--us US-00.5` **0** · `factory_sync --check` **0** · `gitleaks` **no leaks** · PR #17 **4 contextes requis SUCCESS** | ✅ |
| Orphelin `AC-6 Erreur` | 3 critères ajoutés *(19, 20, 21)* — l'intention est juste et c'était **le** trou | 🟠 **partiel** : voir 5.2 |

### 5.2 🔴 Ce qui ne tient pas — le RECALL du sweep n'est pas mesuré, il est **supposé autrement**

Tu écris : *« Rendu bidirectionnel → 4/4 détectés, et le recall est désormais MESURÉ par `verify.sh`
§7, pas supposé. »* **Les trois affirmations tombent à l'exécution.**

**(a) Les 4 mutants de `verify.sh` §7 sont TIRÉS DU VOCABULAIRE DU MOTIF TESTÉ.**
- **Action** : pour chacun des verbes des 4 mutants, chercher s'il figure dans le motif élargi.
- **Attendu** : des mutants indépendants de la règle testée.
- **Obtenu** : `à traiter` **présent** · `→` **présent** · `incombe` **présent** · `reporté`
  **présent** — **4/4 tautologiques**. Un test dont les cas sont **dérivés de la règle testée** ne
  mesure rien. Le `4/4` est **vrai et vide**.

**(b) Recall réel sur des formulations NOUVELLES : 0 sur 8.**
Aucun de ces mutants ne réemploie un verbe du motif :

| Mutant | Détecté ? |
|---|---|
| « cette charge est **laissée à US-00.5** » | 🔴 non |
| « **US-00.5 hérite** de cette dette » | 🔴 non |
| « item **à la charge d'US-00.5** » | 🔴 non |
| « **US-00.5 devra** amender ce texte » | 🔴 non |
| « point **versé à US-00.5** » | 🔴 non |
| « **US-00.5 prend en charge** la correction » | 🔴 non |
| « S11 **assigné à US-00.5** » | 🔴 non |
| « **US-00.5 : à corriger** » | 🔴 non |

**(c) 🔴 RÉGRESSION : le nouveau motif n'est PAS un sur-ensemble de l'ancien.**
- **Action** : comparer les ensembles de lignes du SCB matchées par l'ancien et le nouveau motif.
- **Attendu** *(d'un « élargissement »)* : ancien ⊆ nouveau.
- **Obtenu** : **2 lignes PERDUES** — celle portant « **transmission US-00.5** » et celle portant
  « **US-00.5 :** » — et **2 gagnées**, toutes deux **à l'intérieur de la zone exclue** *(donc sans
  effet)*. Les deux perdues portent le marqueur `PÉRIMÉ`, **donc l'effet visible est nul aujourd'hui —
  par chance, pas par conception** : non marquées, elles seraient devenues **invisibles**. Le total
  est identique *(8 → 8)*, ce qui **masque** le changement d'ensemble.

⇒ **Le critère de test nº 21 (`4/4 détectés`) est un vert non falsifiable.** Il doit exiger des
mutants **écrits par un tiers** ou **tirés d'un lexique indépendant du motif**, et vérifier la
**monotonie** *(ancien ⊆ nouveau)* à chaque évolution du motif. Ta propre réserve — *« un motif ne
vaudra jamais mieux que sa liste de verbes »* — est **honnête**, et c'est précisément pourquoi le
chiffre `4/4` ne doit pas être présenté comme une mesure de recall.

---

## 6. Les 21 critères de test sur `3c48a67`

| État | Nb | Critères |
|---|---|---|
| ✅ **Levés** | **14** | 1, 2, 3, 4, 5, 6, 9, 13, 14, 15, 16, 17, 18, **19** *(`verify.sh` → exit 0)* |
| 🔴 **NON levés** | **2** | **20** *(`ECART=0` sur mon v1 → rend un `ECART` **non nul et VARIABLE** : voir l'encadré ci-dessous)* · **21** *(`4/4` obtenu mais **tautologique** ; recall réel **0/8** ; **régression** de 2 lignes)* |
| ⚪ **Hors diff (PR nº 2)** | **5** | 7, 8, 10, 11, 12 |

> 🔴 **PREUVE LIVE, obtenue en écrivant ce rapport — et c'est la démonstration la plus courte que le
> critère nº 20 doit disparaître.** Mon v1 rendait `ECART=6` sur `3c48a67` avant que je ne dépose
> `qa_detecteur_v2.sh` et `qa_reaudit.md` dans `reports/US-00.5/` ; il rend **un écart de plus** après,
> **sans qu'une seule ligne du corpus de @Architect ait changé** — parce que mes nouveaux fichiers
> contiennent le motif `NB-1` que son contrôle compte, et que l'exclusion de mon v1 ne nomme que
> **deux** de mes artefacts. ⇒ **son `ECART` n'est pas une propriété du corpus audité, mais du contenu
> du répertoire.** Je ne recopie donc **aucune** de ses valeurs ici : elles sont dans la sortie, et
> elles bougeront encore. **@Architect avait raison sur toute la ligne.**

> ⚠️ **Sur le nº 20, je ne me retranche pas derrière mon script** : il est **mal posé** *(§2)* et
> **je demande son remplacement**, pas sa satisfaction. Le critère juste est
> `sh reports/US-00.5/qa_detecteur_v2.sh` → `exit 0`, qui rend aujourd'hui **exit 1**.

**AC** : **6 couverts, 0 orphelin**. `AC-3` et `AC-4` restent **partiels** *(moitié PR nº 2)*.
`AC-6 « Erreur »` **n'est plus orphelin** mais ses deux nouveaux gardiens sont défaillants : l'un
**blanchit** *(§3)*, l'autre est **tautologique** *(§5.2)*.

**Gherkin** : **21 scénarios, 0 exécutés — 0 passed / 0 skipped / 0 failed.** Inchangé : ni step
definitions, ni runner, ni lecture CI de `tests/features/**`.

---

## 7. Verdict

## 🔴 **FAILED — 2ᵉ passage.** Case DoD **18** : **DÉCOCHÉE.**

**Motif, par extension de la classe** — *« un résultat ou un emplacement écrit à la main à côté d'une
commande, jamais relu dans sa sortie »* :

1. **La 6ᵉ manifestation EXISTE et elle est prouvée par ré-exécution** : `conformite_ac.txt:60`,
   `-> 2` contre **5**, **commande publiée**, **aucun marqueur**. C'est **l'écart E-1 du 1ᵉʳ passage**,
   le seul qui fût indiscutable, **non traité** alors que le même traitement a été appliqué à trois
   autres blocs du même fichier.
2. **Et le nouveau mécanisme la BLANCHIT** : `assertions_vives.sh` rend **0 résidu / exit 0**
   par-dessus, parce que son exclusion par mots matche le **motif de la commande**. **Recall mesuré :
   2 formes sur 8.** ⇒ un contrôle qui **efface** la preuve est plus dangereux que l'absence de
   contrôle, parce qu'il **autorise** le vert.
3. **La 3ᵉ leçon d'US-00.7 est enfreinte à nouveau** : `correctifs_...:27` désigne une **ligne vide**
   *(l'emplacement réel a glissé de 44 à 65 depuis mon 1ᵉʳ passage)*, et `conformite_ac.txt:45` **ne
   porte plus** le motif qu'on lui attribue. **2 des 5 emplacements du classement NB-1 sont faux.**
4. **Le recall du sweep n'est pas mesuré** : mutants **tautologiques** (4/4 vrai et vide), recall réel
   **0/8** sur des formulations nouvelles, et **régression de 2 lignes** non détectée par l'outil qui
   prétend mesurer le recall.

**Critère de sortie, publié et rejouable :**
```sh
sh reports/US-00.5/qa_detecteur_v2.sh   # exige ECART=0 ET SANS_MARQUEUR=0 ET autotest=8/8
                                        #        ET MORTES=0 ET NB-1-faux=0
                                        # rend aujourd'hui : exit 1
```

---

## 8. Ce qui est acquis, et que ce FAILED ne remet pas en cause

**Le progrès du cycle est réel et je ne le minore pas** : `verify.sh` est **le premier instrument
bien conçu de cette US** *(spécifications, pas transcriptions ; deux côtés calculés ; contrôle
négatif enfin publié)* · le motif du sweep est **réellement** modifié dans le sweep, pas dans un
renvoi · la DoD passe de **0/23 inerte** à **16/23 sur preuves, 0 cochée à tort** · les critères 5 et
11 sont **réparés** · la contradiction `app.format` est **arbitrée** · les **24 assertions en prose**
de `correctifs_failed_revue.txt` sont tombées à **0 sur le motif de fin de ligne** · les rapports
datés **n'ont pas été repeints**, ce qui est la bonne décision.

**Et le livrable reste conforme** : ADR-001 tient ses **14 critères applicables levés** ·
`CONSTITUTION.md` **absent du diff** *(critère 9 : 0 octet — la lettre de la clause* Révision *est
tenue)* · **0 fichier de code**, **0 `.dart`**, `factory.config.json` **intact** · les 4 honnêtetés
présentes · les 3 écarts hors périmètre nommés avec destinataire · **gates, SCB, trace, synchro,
gitleaks tous verts** · PR #17 **4 contextes requis SUCCESS**. **Le FAILED porte, pour la deuxième
fois, sur les PREUVES et sur les INSTRUMENTS — pas sur le produit.**

---

## 9. Actions pour un 3ᵉ passage

| # | Action | Porteur |
|---|---|---|
| **B-1** | 🔴 **Traiter `conformite_ac.txt:60`** : soit `[valeur retiree — source vive : verify.sh]` comme aux trois autres blocs, soit un marqueur de péremption **sur la ligne même**. ⛔ **Ne pas la mettre « à jour » avec `5`** : elle repérirait | @Architect |
| **B-2** | 🔴 **`assertions_vives.sh` : SUPPRIMER l'exclusion par mots.** Une liste d'exclusion lexicale dans un corpus qui documente ses motifs est un **générateur de faux négatifs**. Remplacer par : *rien n'est supprimé ; ce qui n'est pas vérifiable est **affiché et compté***. Et **élargir les formes** *(`=> N`, `: N`, `-> N <texte>`, tableaux)* — recall actuel **2/8** | @Architect |
| **B-3** | 🔴 **Rendre le vert falsifiable** : tout script de contrôle de cette US porte son **autotest de mutation** et échoue si un mutant échappe *(modèle : `qa_detecteur_v2.sh` §C)*. ⛔ **Mutants jamais tirés du vocabulaire de la règle testée** | @Architect |
| **B-4** | 🔴 **Critère nº 21 à réécrire** : mutants **indépendants du motif** + contrôle de **monotonie** *(ancien ⊆ nouveau)* à chaque évolution. Et **consigner la régression** des 2 lignes perdues | @Architect |
| **B-5** | 🔴 **Critère nº 20 à remplacer** *(mal posé — je le retire moi-même)* par `sh reports/US-00.5/qa_detecteur_v2.sh` → **exit 0** | @Architect |
| **B-6** | **Traiter les 7 chiffres sans commande** : le traitement `[valeur retiree]` s'est arrêté à la **ligne de valeur** ; il doit couvrir la **ligne de conclusion**. Et poser le marqueur de la **FAUTE 1** *(`correctifs:66`)* **sur la ligne même** | @Architect |
| **B-7** | **Les 11 désignations par numéro de ligne** : les remplacer par leur **texte**. Deux ont déjà dérivé | @Architect |
| **B-8** | **Élargir le périmètre du détecteur** au Story File *(qui chiffre en prose)* et au SCB *(qui porte encore `DoD 23 cases` et l'énumération à **6** motifs de `protect_files.sh` — le réel est **9**, mon edge case 9, non traité)* | @Architect |
| **B-9** | *(hors US — `/audit-methodo`)* **Cette classe est arrivée SIX fois en trois jours, dont deux fois dans son propre correctif et une fois dans son détecteur.** Aucun gate CI ne la voit. Tant qu'elle n'est pas dans le job **`governance`**, elle reviendra | @Architect + @DevOps |

---

## 10. Bornes de ce re-audit

1. ⛔ **Rien n'est attesté de la PR nº 2** : critères **7, 8, 10, 11, 12**, cases DoD **5, 6, 14**,
   volets *corps* et *Enforcement* d'AC-3.
2. ⛔ **Aucune couverture applicative** : **89,5 % (17/19)** sur `lib/main.dart` — **1 fichier**,
   **2 tests**. Non-régression, jamais le livrable.
3. ⛔ **0 scénario Gherkin exécuté** ; **aucune preuve E2E**.
4. ⛔ **Aucun verdict de sécurité applicative** : `run_gates --gate sast` → **exit 1, le gate n'existe
   pas** ; aucun scan de CVE ; `gitleaks` ne couvre que les secrets.
5. ⛔ **Mon balayage n'est pas exhaustif** : `reports/US-00.5/**` + SCB, sur les chiffres **présentés
   comme des résultats**. Mon détecteur v2 **s'exclut lui-même par son nom** *(il cite ses mutants)* —
   exclusion **annoncée en sortie**, jamais silencieuse. Recall de v2 **non mesuré au-delà de ses 8
   formes d'autotest**.
6. ⛔ **Les 6 assertions « exactes aujourd'hui » du §4.1 peuvent devenir fausses demain** sans que
   rien ne le signale : c'est le défaut, pas une réserve de style.
7. ⛔ **Je ne certifie pas.** Art. 5 : je délivre `🧪 PASS` — et **je ne le délivre pas**. `🚀 OUI`
   appartient à `/certify` (@Architect). **Réserve maintenue du 1ᵉʳ passage** : ADR-001 étant
   **immuable**, pas de `🚀 OUI` avant la fusion de la **PR nº 2**, faute de quoi la contradiction
   ADR-001 ↔ Art. 4 est **gelée au registre** sans mécanisme de détection.
8. ⛔ **Écriture QA limitée à `reports/`** : `qa_reaudit.md` et `qa_detecteur_v2.sh`. **`qa.md` n'est
   pas écrasé** ; SCB, `CLAUDE.md`, Story File, ADR-001 et code **intacts**.

---
*@QA_Tester · contexte frais · `claude-opus-5[1m]` · 2026-07-31 · HEAD `3c48a67` · PR #17*
*⛔ Aucun chiffre de ce rapport n'est écrit à la main : tous sont issus des sorties citées.*
*Critère de sortie : `sh reports/US-00.5/qa_detecteur_v2.sh`*
