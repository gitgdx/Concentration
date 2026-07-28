# US-00.7 · T22 — **Transmissions nommées** : ce qui change de périmètre, ce qui est clos, ce qui reste ouvert

> ⛔ **Rien de ce document n'est « corrigé en silence ».** Une transmission consiste à **nommer** ce qui
> devient l'affaire d'une autre US, d'un autre agent ou d'un humain — jamais à le traiter au détour de
> celle-ci. Symétriquement, **rien n'y est déclaré clos sans sa preuve**.

| Champ | Valeur |
|---|---|
| Tâche | **T22** — phase 3 (cohérence du corpus) |
| AC | **AC-5 limite** (transmissions), **AC-6** (dérogation), **AC-7 limite** (dettes) |
| Critères de test levés | **23** *(partiel : aucun artefact certifié modifié)*, **24** *(dérogation éteinte)* |
| Date | **2026-07-28** |
| Fait générateur | Dépôt rendu **public** le 2026-07-27 (Art. 5) → protection **appliquée** le **2026-07-28** |
| Preuves invoquées | [`applied_state/`](applied_state/) — `protection_applied.json`, `branch_main_after.json`, `check_remote_exit0_reel.txt`, `negative_test_server.txt` |

---

## 0. Le socle de preuve — ce sur quoi les transmissions ci-dessous s'appuient, et rien de plus

**Prouvé** *(chaque item a son fichier)* :

| # | Fait prouvé | Nature de la preuve |
|---|---|---|
| P1 | `"protected": true` sur `main` | lecture d'API (`branch_main_after.json`) |
| P2 | La règle en vigueur est **exactement** la cible générée : `strict: true` · **4** contextes · `required_pull_request_reviews` **présent** avec `0` · `enforce_admins.enabled: true` · `required_conversation_resolution: true` · `allow_force_pushes: false` · `allow_deletions: false` · `required_linear_history: false` · `restrictions` **absente** | lecture d'API (`protection_applied.json`) |
| P3 | L'administrateur est **inclus** — `enforcement_level: "everyone"` | lecture d'API (`branch_main_after.json`) |
| P4 | Comparaison config ↔ dépôt réel **conforme** : **12** champs alignés, **0** écart, **7** champs additionnels neutres nommés, **0** champ actif non couvert · **exit 0 RÉEL** *(ni `[SIMULATION]`, ni « SOURCE SIMULÉE »)* | sortie d'outil réelle (`check_remote_exit0_reel.txt`) |
| P5 | **Effet** : les **3** opérations d'écriture directe sur `main` sont **refusées par le SERVEUR**, depuis un clone **sans hooks** — `GH006 Protected branch update failed`, « *Changes must be made through a pull request* », « ***4 of 4 required status checks are expected*** », `protected branch hook declined` ; suppression → « *refusing to delete the current branch* ». `origin/main` **identique avant/après** (`f4400ca`) | sorties brutes serveur (`negative_test_server.txt`) |

🔴 **NON prouvé isolément — à écrire ainsi partout** :

* **`allow_force_pushes: false`** n'est **pas isolé** par le test négatif : le **même** `GH006` sort pour
  le force-push, la règle « PR obligatoire » se déclenchant **avant** toute évaluation propre au
  force-push. Il est prouvé par l'**état de l'API** (P2), **pas** par l'effet.
* **`allow_deletions: false`** n'est **pas isolé** non plus : GitHub refuse la suppression de la **branche
  par défaut** (« *refusing to delete the current branch* ») **indépendamment** du réglage. Prouvé par
  l'**état de l'API** (P2), **pas** par l'effet.
* Rien n'est prouvé pour un **autre acteur**, un **jeton d'application** (GitHub App), l'**interface
  web**, une PR issue d'un **fork**, une PR **réouverte**, ni pour la **persistance** de l'état.

---

## 1. 🎁 Un résultat inattendu à transmettre : l'inférence d'US-00.4 est **CONFIRMÉE A POSTERIORI**

**C'est le résultat le plus intéressant de la phase 2, et il n'était pas au programme.**

US-00.4 devait établir le fait « **les 4 status checks déclarés ne sont REQUIS par rien** ». L'endpoint qui
l'aurait énoncé (`…/branches/main/protection`) était précisément celui qui renvoyait **403**. Son AC-1
fait **(b)** a donc été établi par **INFÉRENCE** depuis `"protected": false` — et US-00.4 l'a **déclaré
comme telle**, refusant de le présenter comme une lecture d'API (`docs/GIT_PROTECTION.md`, encadré du fait
(b) : « *C'est rigoureux, mais ce n'est pas une lecture d'API — ne jamais le présenter comme telle.* »).

Le test négatif du 2026-07-28 a produit la **lecture directe** qui manquait. Le serveur **énumère
lui-même** les contextes requis :

```text
remote: - 4 of 4 required status checks are expected.
```

**Conclusion, à consigner comme un résultat et non comme une anecdote** : sur une branche non protégée, il
n'y avait effectivement **aucun** check requis ; sur une branche protégée par la même cible, il y en a
**4 sur 4**. Le mécanisme d'inférence d'US-00.4 est **validé a posteriori par l'observation directe** —
**sans qu'une seule ligne de son texte ait eu besoin d'être corrigée**. C'est la deuxième fois que
l'honnêteté méthodologique d'US-00.4 se trouve récompensée par la réalité, après la désambiguïsation du
**404** (risque R3, clos par l'observation le 2026-07-27).

⛔ **Ce que cela n'autorise pas** : rouvrir, éditer ou « améliorer » les artefacts d'US-00.4. La
confirmation est consignée **ici** et dans `docs/GIT_PROTECTION.md` (encadré daté du 2026-07-28 placé
**après** le constat historisé), **jamais** dans les documents d'US-00.4.

---

## 2. (a) **US-00.5 — périmètre RÉDUIT** ⛔ elle ne doit PAS « corriger » un texte redevenu exact

| Item transmis par US-00.4 | Transmission d'origine | **Statut au 2026-07-28** |
|---|---|---|
| **S1** — `CLAUDE.md:20`, règle 2 : « *jamais de commit/push sur la branche principale … enforced : … + protection de branche* » | « correction **OBLIGATOIRE** » (`reports/US-00.4/enforcement_gap.md` §6, dette **#3** de `GIT_PROTECTION.md`) | ✅ **SANS OBJET.** L'énoncé est devenu **factuellement VRAI**, **sans qu'une ligne ne soit éditée** : la protection **est** appliquée. ⛔ **La règle 2 n'a PAS été touchée par US-00.7** (`git diff CLAUDE.md` le prouve : les l. 14-30 sont intactes) |
| **S2** — `CONSTITUTION.md:48-49`, Art. 4 : « **Enforcement** : CI `ci.yml` jobs qualité, **requis par la protection de branche** (`scripts/apply_branch_protection.sh`) » | idem, « correction obligatoire » | ✅ **SANS OBJET.** Les 4 jobs **sont** requis par la protection de branche, appliquée **par ce script même**. L'énoncé est exact **à la lettre**. ⛔ **`CONSTITUTION.md` n'a PAS été édité par US-00.7** |
| **Dette #6** de `GIT_PROTECTION.md` — en-tête généré « **Status check requis** » laissant croire les checks requis ; sa reformulation exigeait d'éditer `scripts/factory_sync.py` (**Art. 6**) | jointe à US-00.5 / action humaine | ✅ **SANS OBJET.** L'en-tête généré est devenu **exact**. **L'édition Art. 6 n'a plus lieu d'être** — une dette se ferme ici **sans une ligne de code**, et il faut le dire simplement : ce n'est pas un mérite, c'est un changement d'état du monde |

### ⚠️ Message explicite à @PO et à qui rédigera US-00.5

> **Ne « corrigez » pas ces trois textes.** Les toucher aujourd'hui reviendrait à **rendre faux un énoncé
> exact** — exactement le défaut, en sens inverse, que US-00.4 et US-00.7 ont passé trois jours à
> éliminer. Si une US-00.5 arrivait avec « corriger la règle 2 de `CLAUDE.md` » dans son périmètre, **ce
> périmètre est périmé** : il datait du 2026-07-26.
>
> **Ce qui RESTE au périmètre d'US-00.5** : **ADR-001 (stack)** — jamais publié — et la relecture de la
> Constitution **pour d'autres motifs** que l'enforcement de branche. Rien d'autre n'a été transféré ici.
>
> ⚠️ **Conditionnel** : si le dépôt repassait en **privé**, S1 et S2 redeviendraient **faux** et la
> correction redeviendrait due. La réduction de périmètre est **datée**, pas définitive.

---

## 3. (b) **US-00.1 — la preuve manquante est fournie ; l'US n'est PAS éditée**

**S11** — critère de test **#6** et tâche **T8** du Story File d'**US-00.1** (`docs/stories/US-00.1-secrets-scan-depot.md`
l. **198** et **215**, et `tests/features/US-00.1-secrets-scan-depot.feature:54`) affirment :

> « job `secrets-scan` rouge → merge **empêché par la protection de branche** »

**C'est désormais VRAI.** `🔐 Secrets scan (gitleaks)` est l'**un des 4 contextes requis** (P2), et le
serveur refuse toute mise à jour de `main` tant que les 4 ne sont pas verts (P5).

⛔ **Aucune ligne d'US-00.1 n'a été touchée** — anti-pattern « *modifier une US certifiée sans re-audit* ».
`git diff --stat` le prouve.

| Point | État |
|---|---|
| **Véhicule de mise à jour** | **Arbitrage @PO**, non tranché ici. **Recommandation @Architect, reprise et soutenue** : **requalification tracée** depuis une autre US, plutôt que **ré-ouverture de cycle** — le critère devient vrai, **aucun code d'US-00.1 n'est en cause**, et un cycle complet pour aligner un libellé serait disproportionné |
| **Ce qui reste vrai et ne doit pas être tu** | Le **test négatif d'US-00.1 n'a JAMAIS été exécuté**. La preuve fournie ici démontre que *les 4 contextes sont requis et bloquants*, **pas** que *`secrets-scan` rouge bloque un merge* : le refus observé porte sur un contexte **`expected`** (non encore rapporté), **pas** sur un contexte **rouge**. ⛔ On ne casse pas volontairement un gate pour obtenir un rouge |
| **Nuance à ne pas escamoter** | La démonstration a eu lieu **hors PR** (push direct refusé), et **non** sur une tentative de fusion. La preuve du refus **de fusion** relève de **T11**, qui **n'est pas exécutée à ce stade** (voir §7) |

---

## 4. (c) **Dettes maintenues explicitement OUVERTES** — aucune n'est close par effet de bord

> ⛔ **Onze dettes restent ouvertes.** Les numéros renvoient à `docs/GIT_PROTECTION.md` §Dettes, dont la
> numérotation a été **conservée** pour que les renvois d'ADR-006, de `reports/US-00.4/**` et des Story
> Files restent valides.

| # | Dette OUVERTE | Pourquoi elle n'est pas close, et ce que l'application y change |
|---|---|---|
| **#2** | **Aucune détection automatique de dérive** config ↔ dépôt réel | `--check-remote` exige des droits **admin**, absents du `GITHUB_TOKEN` → **manuel, hors CI, par construction**. 🔴 **Aggravée** : c'est désormais la **protection elle-même** qui en dépend. Un administrateur peut la révoquer **sans aucun signal** |
| **#4** | **`governance.grandfathering_date`** — clé lue par **aucun** script, sémantique décalée | Inchangé. Laissée `null` **délibérément**. À implémenter, redocumenter ou retirer du schéma |
| **#5** | **Périmètre Art. 6 déclaré ≠ appliqué** — `check_branch_protection.py`, `.github/workflows/*` et `apply_branch_protection.sh` ne sont **pas** couverts par `.claude/hooks/protect_files.sh` | 🔴 **Aggravée** : `.github/workflows/*` porte maintenant les **libellés des contextes REQUIS** (donc le risque de **verrouillage**), et `apply_branch_protection.sh` est le **seul chemin d'écriture** de la protection. **Un agent peut affaiblir l'outil qui produit la preuve.** Traitement = édition de `.claude/hooks/*` → **action humaine**, hors périmètre |
| **#7** | **Revue humaine de PR du track FULL** sans barrière machine | 🔴 **INCHANGÉE — et c'est important de le dire** : la cible est à **`0`** approbation. La moitié « *ni après déblocage* » de l'énoncé d'US-00.4 **reste exacte**. **US-01.1 est en FULL** → **arbitrage dû AVANT son Integration Lock**. Le renforcement **R-c** d'US-00.7 est un **précédent de process**, pas une barrière |
| **#8** | **Point de contrôle sans déclencheur calendaire** (`/audit-methodo`, trimestriel « ou à la demande ») | 🔴 **Devenue la plus critique** : elle **porte** #2. Rien n'oblige un passage. C'est la dette la plus susceptible de **pourrir silencieusement** |
| **#9** | **Repli `urllib` du comparateur jamais exercé** contre l'API réelle | 🟡 **Moitié close** : le **chemin 404 réel** a été observé le 2026-07-27 (**R3 d'US-00.4 CLOS**). **Le repli `urllib` reste NON exercé** — cette moitié demeure **OUVERTE** |
| **#10** | 🆕 **`NB-1bis`** — résidu du correctif NB-1 | Après correctif, une clé absente de la cible dont la valeur réelle est **ACTIVE** est nommée et **interdit l'exit 0** ; mais si sa valeur est **NEUTRE** (`{"enabled": false}`) elle est **seulement nommée** et **l'exit 0 subsiste**, et si elle est **absente des deux côtés** elle n'est **pas même nommée**. Or `enforce_admins: false` **autorise le bypass admin** et `required_pull_request_reviews` absent = **aucune PR exigée**. **NB-1 est un progrès strict, PAS une fermeture.** Correctif identifié : **complétude de la cible** dans `_guard_mapping()`. **Compensé** : `set(payload) == MAPPED_TOP_KEYS` → `True` |
| **#11** | 🆕 **Aucun `selftest` en CI** pour `check_branch_protection.py` | Ses fixtures sont lancées **à la main**, y compris pour valider NB-1 : **le correctif d'un outil de preuve n'est protégé par aucun gate**. Contrôle négatif **maintenu** : `grep -rn "check-remote" .github/workflows/` doit rester **vide**. À porter **dans la même US** que #10 |
| **#12** | 🆕 **Aucun événement d'extinction de dérogation** + **champ `emitter` non lu** | Voir §5 — dette **structurelle** du système de traçabilité |
| **#13** | 🆕 **`TRACKS.md:14`** dit « Surface auth / sécurité / **admin** / paiement » | Voir §6 |
| **#14** | 🆕 **3 faux positifs du hook `block_dangerous_bash.sh`** rencontrés en conditions réelles | Voir §9 |

---

## 5. (c bis) **#12 — la dérogation ne peut pas être ÉTEINTE par la trace : dette structurelle**

### L'extinction elle-même — consignée, datée, aux 3 emplacements exigés

> La dérogation tracée le **2026-07-26** (`EVT_WAIVER_GRANTED`, US-00.4, Constitution Art. 5) portait sur
> « **ni upgrade GitHub Pro, ni passage du dépôt en public** ». **L'humain a choisi la voie (a) — dépôt
> public — le 2026-07-27**, et la protection a été appliquée le **2026-07-28**. Son motif (impossibilité
> de plateforme) **n'existe plus** : la dérogation est **ÉTEINTE / SANS OBJET**.
> ⚠️ **Conditionnel** : un retour du dépôt en **privé** rétablirait le 403 et **rouvrirait la question**.

| Emplacement exigé | Où exactement | Vérifiable |
|---|---|---|
| `CLAUDE.md` (§État courant) | encadré 🔕 après l'encadré d'état de l'enforcement | ✅ daté, avec renvoi à l'événement d'origine |
| `docs/GIT_PROTECTION.md` | encadré 🔕 de l'en-tête | ✅ idem |
| `docs/epics/EPIC_00-fondations.md` | **risque #5**, colonne mitigation | ✅ idem |

⛔ **La trace n'est pas réécrite** : `git diff docs/trace/` ne montre **aucune** modification de l'événement
du 2026-07-26. **On éteint une dérogation ; on ne l'effface pas.**

### 🔴 La dette : le système de traçabilité ne sait pas éteindre ce qu'il accorde

**Vérifié le 2026-07-28** — `scripts/events_catalog.json` (`version: 2.0`) porte **25** événements et
**4** alias dépréciés (`DATA_ENGINEER_COMPLETED`, `UX_DESIGNER_COMPLETED`, `EVT_QA_READY_FOR_PROD`,
`EVT_STORY_READY_FOR_TECH_VALIDATION`). **Aucun** événement de révocation, extinction ou expiration de
dérogation. *(Nota : le Story File d'US-00.7 en annonce 26 — décompte inexact, sans conséquence sur la
conclusion, qui est l'**absence** d'un tel mécanisme. Signalé plutôt que recopié.)*

**Conséquence, à écrire sans l'atténuer** : **une dérogation est irrévocable par construction dans la
trace.** Un audit qui ne lirait que `docs/trace/**` verrait un `EVT_WAIVER_GRANTED` **sans contrepartie**
et pourrait légitimement croire l'exception **encore active** — c'est-à-dire croire qu'une exception de
gouvernance couvre encore un trou d'enforcement qui n'existe plus.

**Modalité retenue** : la **consignation documentaire fait foi**, complétée par une mention explicite de
l'extinction dans le `rationale` de l'`EVT_DOCS_UPDATED` d'US-00.7, pour qu'un lecteur de la **seule
trace** la voie. ⚠️ **C'est une convention NON ENFORCED** : `rationale` est un champ **libre**, non typé,
que `validate_trace.py` **ne valide pas** sur ce point. Elle **réduit** le risque ; elle ne le supprime
pas.

### 🔴 Corollaire — et il rend la dette plus grave que sa formulation initiale

Le champ `emitter` de `events_catalog.json` déclare `"human"` pour `EVT_WAIVER_GRANTED`. **Vérifié le
2026-07-28 : ce champ n'est lu par AUCUN script ni AUCUN hook** —

```text
grep -rn "emitter" scripts/ --include="*.py"   → 0 résultat
grep -rn "emitter" .claude/hooks/              → 0 résultat
```

**Donc : un agent peut émettre `EVT_WAIVER_GRANTED`.** Le système peut **accorder** une dérogation sans
humain, et **ne peut pas l'éteindre**. C'est la **même classe de défaut** que le défaut fondateur d'US-00.4
— *une contrainte déclarée sans mécanisme d'application* — **située dans le système de traçabilité
lui-même**, celui qui sert à prouver tout le reste.

**Transmission** : candidat `/audit-methodo` **prioritaire**. Ajouter un événement d'extinction
modifierait la **machine à états** → décision structurante, qui exige **son propre ADR**. ⛔ Hors périmètre
d'US-00.7, et **surtout pas** à trancher au détour d'une tâche documentaire.

---

## 6. (e) **Amendement `TRACKS.md` suggéré** — ⛔ `TRACKS.md` n'est PAS édité ici

`docs/governance/TRACKS.md` **l. 14** :

```text
| Surface auth / sécurité / admin / paiement | non | non | oui |
```

**Le critère littéral est satisfait par US-00.7 au sens strict** — elle modifie réellement la configuration
d'**administration** du dépôt — et c'est dit franchement plutôt que nié. Ce qui a fait retenir
**STANDARD + 3 renforcements** n'est **pas** la nature de la surface, mais l'**inapplicabilité des
obligations de FULL** : FULL impose « Design Data **ET** UX obligatoires (**pas de N/A**) » et des « E2E
dédiés implémentés », or il n'y a **ni UI, ni schéma, ni code applicatif** → deux exigences **creuses**,
c'est-à-dire une fiction de gouvernance, soit exactement la classe de défaut que cette US solde.

**Amendement suggéré** : « surface **applicative** auth / sécurité / admin / paiement » — c'est
l'interprétation tenue **sans exception sur 4 US certifiées** (US-00.1 → US-00.4) et **inscrite au SCB**.

⛔ **Non édité ici.** À joindre à l'arbitrage `TRACKS.md` **déjà dû avant le lock d'US-01.1** (dette **#7**,
R7 d'US-00.4) — pas à trancher au détour de cette US.

---

## 7. (d) **Dettes et risques CLOS, chacun avec sa preuve**

| Item | Origine | Preuve de clôture |
|---|---|---|
| **R3 d'US-00.4** — « chemin **404** réel non observable in vivo » | Story File US-00.4, §Risques | ✅ **CLOS par l'observation le 2026-07-27** : 404 « *Branch not protected* » + `protected == false` → **exit 1**, jamais exit 2 — exactement l'issue prévue par la désambiguïsation (ADR-006 décision 8). `entry_state/protection_404.json`, `entry_state/check_remote_exit1.txt`. **Sans une ligne de changement.** |
| **Écart de preuve n° 3 d'US-00.4** — « l'`exit 0` n'est démontré que sur **fixture** ; sa preuve est une **simulation**, à lire comme telle en audit » | Story File US-00.4 | ✅ **REFERMÉ le 2026-07-28** : `exit 0` **RÉEL**, première observation **in vivo** — 12 champs alignés, 0 écart, **sans** `[SIMULATION]`, **sans** « SOURCE SIMULÉE ». `applied_state/check_remote_exit0_reel.txt` |
| **Risque #2 d'EPIC_00** — « règles déclarées mais non enforced » | `docs/epics/EPIC_00-fondations.md` | ✅ **CLOS le 2026-07-28**, daté, preuve référencée dans le fichier |
| **Risque #5 d'EPIC_00** — « risque #2 matérialisé **et non refermable sur ce plan** » | idem | ✅ **CLOS le 2026-07-28** — **les deux causes** traitées : (a) par US-00.4, (b) par le passage en public + l'application. Le « **non refermable sur ce plan** » était **exact à sa date** : c'est **le plan qui a changé** |
| **Critère de clôture d'EPIC_00** « Protection de branche vérifiée » | idem | ✅ **COCHABLE et COCHÉ**. → **EPIC_00 redevient complétable** après US-00.5 et US-00.6. ⛔ **EPIC_00 n'est PAS déclarée complète** : d'autres critères restent ouverts (US certifiées, ADR-001, couverture/ratchet, documentation) |
| **Dette #1 de `GIT_PROTECTION.md`** — « enforcement de plateforme absent » | `docs/GIT_PROTECTION.md` §Dettes | ✅ **CLOSE le 2026-07-28**, conditionnée à la visibilité publique |
| **Dette #3 de `GIT_PROTECTION.md`** — S1/S2 factuellement faux | idem | ✅ **SANS OBJET** — voir §2 |
| **Dette #6 de `GIT_PROTECTION.md`** — en-tête généré trompeur | idem | ✅ **SANS OBJET** — l'en-tête est devenu **exact** ; l'édition **Art. 6** qu'elle exigeait n'a plus lieu d'être |
| **NB-1** — faux vert du comparateur sur cible amputée | `CLAUDE.md`, re-audit d'US-00.4 | 🟡 **CORRIGÉ, mais PAS FERMÉ** : le correctif est un **progrès strict**. Résidu **`NB-1bis`** ouvert (#10). ⛔ **Ne pas écrire que NB-1 « ferme le trou »** |

### ⚠️ Ce que la phase 2 n'a **pas** établi — T11 n'est pas exécutée

**Le refus de FUSION (AC-4) n'est pas démontré à la date de ce document.** T11 exige une PR ouverte, le
constat des libellés **réellement rapportés** (`gh pr checks`), une tentative de fusion réelle refusée,
puis une fusion acceptée après passage au vert. **Rien de cela n'a eu lieu** : les critères de test **25 →
27** et les cases de DoD **2**, **13**, **14**, **26** *(moitié CI)*, **34** restent **non levés**, et
relèvent de **@DevOps** + d'une **confirmation humaine**. Ce que P5 démontre est le refus du **push
direct**, ce qui n'est **pas** la même chose qu'un refus de **fusion**.

---

## 8. 🔒 **T20 — action humaine (Art. 6)** : `scripts/githooks/pre-push`

`scripts/githooks/pre-push` est **couvert par `.claude/hooks/protect_files.sh`** : un agent en est
**techniquement bloqué**. Son en-tête, posé par la T22 d'US-00.4, contient **deux affirmations devenues
fausses** :

1. « **CE HOOK EST LE SEUL ENFORCEMENT RÉEL DE CETTE RÈGLE** » → **faux** : il y a désormais **deux**
   barrières, dont une **côté serveur**, et c'est la serveur qui est décisive.
2. « `main` n'est PAS protégée côté GitHub et **ne peut pas l'être sur ce plan** (403…) » → **faux** :
   elle **l'est**.

### 🔴 Deux corrections apportées au diff proposé par le Story File — à ne pas recopier tel quel

Le diff du Story File (T20) a été rédigé le **2026-07-27**, en **anticipant** que le `PUT` aurait lieu ce
jour-là. Il contient donc **deux inexactitudes** qui introduiraient, dans un fichier d'enforcement, le type
même d'affirmation fausse que cette US élimine :

| # | Inexactitude du diff d'origine | Correction |
|---|---|---|
| 1 | « depuis le **2026-07-27** (US-00.7), la protection de branche est APPLIQUÉE » | Le dépôt est devenu **public** le 2026-07-27 ; la protection a été **appliquée le 2026-07-28**. **Deux dates, deux faits.** |
| 2 | renvoi à « `reports/US-00.7/negative_test.md` » | **Ce fichier n'existe pas.** Le chemin réel est **`reports/US-00.7/applied_state/negative_test_server.txt`** *(les noms de fichiers de preuve retenus à l'exécution diffèrent de ceux annoncés par le Story File — cf. `non_regression.md` §Écarts)* |

### Diff EXACT à appliquer — corrigé, à jour au 2026-07-28

```diff
 #!/bin/sh
 # Refuse le push direct vers la branche principale. Le merge passe par une PR.
 #
-# ⚠️ CE HOOK EST LE SEUL ENFORCEMENT RÉEL DE CETTE RÈGLE — et c'est un FILET DE DISCIPLINE
-#    LOCAL, pas une contrainte de plateforme (constat daté du 2026-07-26) : `main` n'est PAS
-#    protégée côté GitHub et ne peut pas l'être sur ce plan (403 « Upgrade to GitHub Pro or
-#    make this repository public to enable this feature. » sur la protection classique ET sur
-#    les rulesets). Limites à connaître : ce hook est ABSENT d'un clone frais (tant que
-#    scripts/install_hooks.sh n'a pas été lancé), contournable depuis un autre poste ou via
-#    l'interface web, et l'interdiction de `--no-verify` (Constitution Art. 1) repose sur la
-#    MÊME discipline. scripts/apply_branch_protection.sh est PRÊT mais NON APPLICABLE — cf.
-#    docs/GIT_PROTECTION.md et docs/adr/ADR-006-protection-branche-principale.md.
+# ⚠️ CE HOOK N'EST PLUS LE SEUL ENFORCEMENT DE CETTE RÈGLE — il y a désormais DEUX barrières,
+#    dont une CÔTÉ SERVEUR, et c'est celle-là qui est décisive. Le dépôt a été rendu PUBLIC le
+#    2026-07-27 (décision humaine, Art. 5) puis la protection de branche a été APPLIQUÉE le
+#    2026-07-28 (US-00.7) : PR obligatoire, 4 status checks REQUIS, enforce_admins en vigueur
+#    (enforcement_level "everyone" — l'administrateur est inclus). Le SERVEUR refuse désormais
+#    le push direct, le force-push et la suppression de la branche principale — refus prouvés et
+#    archivés (reports/US-00.7/applied_state/negative_test_server.txt).
+#    Ce hook garde deux utilités RÉELLES : il refuse le push AVANT l'aller-retour réseau (retour
+#    immédiat), et il vaudrait encore si la protection serveur était un jour désactivée.
+#    Limites INCHANGÉES : il est ABSENT d'un clone frais (tant que scripts/install_hooks.sh n'a
+#    pas été lancé) — c'est d'ailleurs la condition même du test négatif d'US-00.7 —, il reste
+#    contournable depuis un autre poste ou via l'interface web, et l'interdiction des options de
+#    contournement de hook (Constitution Art. 1) repose toujours sur la MÊME discipline locale.
+#    ⚠️ CONDITIONNEL : la protection serveur dépend de la VISIBILITÉ PUBLIQUE du dépôt. Retour en
+#    privé ⇒ retour du 403 ⇒ ce hook redevient le seul enforcement. Vérifier par
+#    `python scripts/factory_sync.py --check-remote` (exit 0 attendu).
+#    Cf. docs/GIT_PROTECTION.md et docs/adr/ADR-007-application-protection-branche.md.
```

⛔ **Ne toucher à AUCUNE ligne de logique** (l. 15-29 du fichier actuel : lecture de `factory_env.sh`,
boucle `while read`, `exit 1` / `exit 0`). Seul le bloc de commentaire l. 4-12 est remplacé.
**Après édition** : `git config --get core.hooksPath` doit toujours rendre `scripts/githooks` — **sans**
exécuter de push réel vers la branche principale pour le vérifier.

---

## 9. #14 — **3 faux positifs du hook `block_dangerous_bash.sh`**, rencontrés en conditions réelles

> ⚠️ **Aucun contournement n'a été employé.** Dans les trois cas : reformulation, puis changement d'outil
> (écriture de fichier au lieu d'une commande shell). Le hook a **fait son travail** ; c'est sa **précision**
> qui est en cause, pas son principe. **Ces trois cas relèvent d'une même famille, déjà rencontrée par
> US-00.4** (son docstring citant un drapeau de méthode d'écriture, et le mot « conforme ») :
> **documenter une interdiction déclenche son détecteur.**

| # | Cas rencontré | Cause exacte, vérifiée dans le hook | Conséquence |
|---|---|---|---|
| **(a)** | Une **LECTURE** de `core.hooksPath` **imbriquée dans une substitution de commande** est **bloquée**, alors que le commentaire du hook (l. 36-37) affirme explicitement l'autoriser : « *Une simple LECTURE … est autorisée* » | La condition d'autorisation (**l. 39**) exige que le motif soit en **fin de commande** : `'git +config +(--get +)?core\.hooksPath *($|[;&|])'`. Imbriquée, la chaîne est suivie d'une **parenthèse fermante**, absente de la classe `$|[;&|]` → la branche « lecture seule » n'est pas prise, puis le `elif` l. 43 bloque faute de trouver `scripts/githooks` dans la commande | 🔴 **Écart déclaré ≠ appliqué DANS UN HOOK D'ENFORCEMENT** : le commentaire promet plus que le code ne fait. Le contrôle de non-régression du clone sans hooks (« `core.hooksPath` vide ») est **impossible à écrire de la façon la plus naturelle** |
| **(b)** | Le **littéral** d'un drapeau de contournement de hook, écrit **pour attester qu'il n'a PAS été employé**, déclenche le blocage | l. 21-23 : `case "$cmd" in *<littéral>*)` — correspondance **textuelle**, sans distinction entre **usage** et **mention** | ⚠️ **Attester le respect d'une règle est bloqué par la règle** : il devient impossible d'écrire dans une commande la preuve qu'on ne l'a pas violée |
| **(c)** | Les **commandes du test négatif (T10)**, citées **dans un fichier de preuve** *(donc en tant que texte)*, déclenchent les gardes « push direct » et « force-push » | l. 25-26 et 28-29 : `grep -qE` sur la chaîne de commande complète, sans distinction entre **exécution** et **citation** | ⚠️ **Archiver une preuve de refus est bloqué par le détecteur de l'opération refusée.** Contourné **légitimement** par l'outil d'écriture de fichier, qui n'est pas inspecté par ce hook |

**Transmission** : candidat `/audit-methodo`. ⛔ **Hors périmètre @Developer** — `.claude/hooks/*` est
**Art. 6**. **Recommandation minimale et bornée** : pour **(a)**, élargir la classe de fin de motif de la
l. 39 pour accepter la parenthèse fermante et la fin de substitution — **ou**, mieux, corriger le
**commentaire** l. 36-37 pour qu'il décrive ce que le code fait réellement. ⚠️ **Ne pas relâcher (b) ni
(c)** : le coût est faible (changer d'outil) et le bénéfice de la garde est élevé ; **un faux positif
gênant vaut mieux qu'un faux négatif silencieux.**

---

## 10. 📒 Les **3 LEDGERS** — hors périmètre @Developer, transmis à @Architect / @PO

> ⛔ **Aucun de ces trois fichiers n'a été touché par US-00.7 phases 3-4** (`git diff --stat` le prouve).
> Ils relèvent de @Architect / @PO. **Voici ce qui y reste à corriger.**

| Ledger | Ce qui reste à corriger | Recommandation |
|---|---|---|
| **`STORY_CERTIFICATION_BOARD.md`** | 🔴 **l. 493 et 520** portent, **au présent**, « `main` **n'est toujours pas protégée** et **ne peut pas l'être** » — dans des **visas datés** d'US-00.4. Un auditeur lisant le SCB **de haut en bas** rencontrerait cette affirmation **sans** rencontrer son démenti. Par ailleurs l'entrée d'US-00.7 (l. ~543-550) **décrit** le problème au futur, et devra être mise à l'état réel | ⛔ **Ne PAS réécrire les visas datés d'US-00.4** (artefacts datés). ✅ **AJOUTER** au bloc d'US-00.7 une mention **datée** de l'état appliqué **et** de l'extinction de la dérogation, avec renvoi à `reports/US-00.7/applied_state/`. *(l. 3 = **faux positif** : légende « N/A Non applicable ».)* Colonnes SCB à mettre à jour à la fin du cycle |
| **`PROJECT_LOG.md`** | 7 occurrences dans des lignes **datées** | ⛔ **Jamais réécrit** — journal append-only par convention. **Ajouter** les lignes de cette US, rien d'autre |
| **`BACKLOG.md`** | l. 22 « cible armée — *re-cadrée le 2026-07-26* » et le libellé d'US-00.4 | ⚠️ **Exact à sa date** : rien à corriger. À **ne pas confondre** avec une affirmation courante. ✅ Ajouter/mettre à jour l'entrée **US-00.7** et signaler que **US-00.5 voit son périmètre réduit** (§2) |

---

## 11. Récapitulatif des transmissions

| Destinataire | Objet | Nature |
|---|---|---|
| **@PO** | Périmètre d'**US-00.5** réduit (S1, S2, dette #6 **sans objet**) ⛔ ne pas « corriger » un texte exact | **décision** |
| **@PO** | **Véhicule** de mise à jour d'**US-00.1** (S11 devenu vrai) — **requalification tracée** recommandée, ⛔ pas de ré-ouverture de cycle | **arbitrage** |
| **@Architect / @PO** | **3 ledgers** : SCB l. 493/520 (ajout daté, jamais réécriture), PROJECT_LOG, BACKLOG | **édition hors périmètre @Developer** |
| **@Architect** | Amendement **`TRACKS.md:14`** (« surface **applicative** ») + arbitrage **revue humaine du track FULL** — **dus avant le lock d'US-01.1** | **arbitrage** |
| **Humain (Art. 6)** | **T20** — `scripts/githooks/pre-push`, diff exact corrigé au §8 | **action humaine** |
| **Humain (Art. 6)** | **#5** — ajouter `check_branch_protection.py`, `.github/workflows/*` et `apply_branch_protection.sh` à `protect_files.sh` | **action humaine** |
| **US de dette (à créer)** | **#10 `NB-1bis`** + **#11 `selftest` CI** — de préférence **ensemble** : le selftest est ce qui empêchera la régression du correctif | **US à ouvrir** |
| **`/audit-methodo`** | **#2**, **#4**, **#7**, **#8**, **#9**, **#12** *(événement d'extinction + `emitter` non lu)*, **#14** *(3 faux positifs de hook)* | **surveillance périodique** |
| **@DevOps + humain** | **T11** — PR, libellés rapportés, refus de fusion, fusion après 4 verts, revue humaine consignée (**R-c**) | **non exécuté à ce jour** |

---

*Rédigé par @Developer — 2026-07-28. Aucune affirmation de ce document ne va au-delà du §0.*
