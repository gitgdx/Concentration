# US-00.7 · T3 — Verification des **4 libelles de status checks, caractere par caractere**

> **Preambule : pourquoi cette tache existe.** Avec `enforce_admins: true`, **un libelle de contexte
> requis qui divergerait d'un seul caractere** (emoji, selecteur de variante `U+FE0F`, espace
> insecable, accent decompose, parenthese non-ASCII) produirait un contexte **jamais rapporte** par
> GitHub, donc `mergeable_state = BLOCKED` **definitif** : **plus aucune PR fusionnable,
> administrateur inclus** — y compris celle de cette US. C'est le risque **R-1**, le risque n° 1 de
> l'US, et cette verification en est la **mitigation prealable et bloquante**.

| Champ | Valeur |
|---|---|
| Tache | **T3** — phase 0, aucune ecriture distante |
| AC | **AC-8 nominal** (prealable bloquant du `PUT`) |
| Criteres de test leves | **7** et **8** (conditionnes AVANT `PUT`) |
| Horodatage UTC | 2026-07-28T07:25:50Z |
| Source unique | `factory.config.json` -> `status_checks[].name` (fichier **Art. 6**, non modifie) |

---

## 1. Methode

Pour chacun des 4 libelles, la sonde imprime : la **liste complete de ses points de code**
(`[hex(ord(c)) for c in name]`), sa **representation en octets UTF-8**, la liste de ses caracteres
**non-ASCII** avec leur nom Unicode officiel, la presence de **`U+FE0F`**, la comparaison
**NFC / NFD** (une decomposition ferait diverger deux chaines visuellement identiques), la presence
d'un **espace double**, d'un **espace insecable ou invisible** (`U+00A0`, `U+2007`, `U+202F`,
`U+2060`, `U+200B`) et d'une **parenthese non-ASCII**. Puis elle localise, dans le fichier de
workflow cite par la config, la ligne qui apparie le libelle — soit un **`name:` de job**, soit
l'**ID de job** lui-meme quand le job n'a pas de `name:` (comportement par defaut de GitHub Actions)
— et compare les **octets** des deux cotes.

---

## 2. Sortie brute de la sonde

```text
Source unique : factory.config.json → status_checks (4 entrees)

====================================================================================================
[1/4] libelle config : '🔐 Secrets scan (gitleaks)'
      workflow        : .github/workflows/ci.yml   ·   job_id declare : 'secrets-scan'
      longueur         : 25 points de code · 28 octets UTF-8
      points de code   : U+1F510 U+0020 U+0053 U+0065 U+0063 U+0072 U+0065 U+0074 U+0073 U+0020 U+0073 U+0063 U+0061 U+006E U+0020 U+0028 U+0067 U+0069 U+0074 U+006C U+0065 U+0061 U+006B U+0073 U+0029
      octets UTF-8     : f0 9f 94 90 20 53 65 63 72 65 74 73 20 73 63 61 6e 20 28 67 69 74 6c 65 61 6b 73 29
      non-ASCII        : [('U+1F510', '🔐', 'CLOSED LOCK WITH KEY')]
      U+FE0F (variation selector-16) present ? : NON
      forme NFC ? name == NFC(name) : True   ·   NFC == NFD ? True (False = le libelle contient des caracteres composables)
      len(NFC)=25  len(NFD)=25  → decomposition absente (precompose)
      espace double ? False   ·   espace insecable/invisible ? False   ·   parenthese non-ASCII ? False
      appariement       : `name:` de job, ligne 29
      ligne du YAML     : '    name: 🔐 Secrets scan (gitleaks)'
      libelle du YAML   : '🔐 Secrets scan (gitleaks)'
      octets du YAML    : f0 9f 94 90 20 53 65 63 72 65 74 73 20 73 63 61 6e 20 28 67 69 74 6c 65 61 6b 73 29
      IDENTITE OCTET PAR OCTET config ↔ workflow : ✔ OUI
====================================================================================================
[2/4] libelle config : '📋 Governance (SCB + traçabilité + synchro)'
      workflow        : .github/workflows/ci.yml   ·   job_id declare : 'governance'
      longueur         : 42 points de code · 47 octets UTF-8
      points de code   : U+1F4CB U+0020 U+0047 U+006F U+0076 U+0065 U+0072 U+006E U+0061 U+006E U+0063 U+0065 U+0020 U+0028 U+0053 U+0043 U+0042 U+0020 U+002B U+0020 U+0074 U+0072 U+0061 U+00E7 U+0061 U+0062 U+0069 U+006C U+0069 U+0074 U+00E9 U+0020 U+002B U+0020 U+0073 U+0079 U+006E U+0063 U+0068 U+0072 U+006F U+0029
      octets UTF-8     : f0 9f 93 8b 20 47 6f 76 65 72 6e 61 6e 63 65 20 28 53 43 42 20 2b 20 74 72 61 c3 a7 61 62 69 6c 69 74 c3 a9 20 2b 20 73 79 6e 63 68 72 6f 29
      non-ASCII        : [('U+1F4CB', '📋', 'CLIPBOARD'), ('U+00E7', 'ç', 'LATIN SMALL LETTER C WITH CEDILLA'), ('U+00E9', 'é', 'LATIN SMALL LETTER E WITH ACUTE')]
      U+FE0F (variation selector-16) present ? : NON
      forme NFC ? name == NFC(name) : True   ·   NFC == NFD ? False (False = le libelle contient des caracteres composables)
      len(NFC)=42  len(NFD)=44  → decomposition DETECTEE
      espace double ? False   ·   espace insecable/invisible ? False   ·   parenthese non-ASCII ? False
      appariement       : `name:` de job, ligne 48
      ligne du YAML     : '    name: 📋 Governance (SCB + traçabilité + synchro)'
      libelle du YAML   : '📋 Governance (SCB + traçabilité + synchro)'
      octets du YAML    : f0 9f 93 8b 20 47 6f 76 65 72 6e 61 6e 63 65 20 28 53 43 42 20 2b 20 74 72 61 c3 a7 61 62 69 6c 69 74 c3 a9 20 2b 20 73 79 6e 63 68 72 6f 29
      IDENTITE OCTET PAR OCTET config ↔ workflow : ✔ OUI
====================================================================================================
[3/4] libelle config : 'check-branch-name'
      workflow        : .github/workflows/branch-naming.yml   ·   job_id declare : 'check-branch-name'
      longueur         : 17 points de code · 17 octets UTF-8
      points de code   : U+0063 U+0068 U+0065 U+0063 U+006B U+002D U+0062 U+0072 U+0061 U+006E U+0063 U+0068 U+002D U+006E U+0061 U+006D U+0065
      octets UTF-8     : 63 68 65 63 6b 2d 62 72 61 6e 63 68 2d 6e 61 6d 65
      non-ASCII        : <aucun>
      U+FE0F (variation selector-16) present ? : NON
      forme NFC ? name == NFC(name) : True   ·   NFC == NFD ? True (False = le libelle contient des caracteres composables)
      len(NFC)=17  len(NFD)=17  → decomposition absente (precompose)
      espace double ? False   ·   espace insecable/invisible ? False   ·   parenthese non-ASCII ? False
      appariement       : ID de job (aucun `name:` — GitHub Actions affiche l'ID), ligne 10
      ligne du YAML     : '  check-branch-name:'
      libelle du YAML   : 'check-branch-name'
      octets du YAML    : 63 68 65 63 6b 2d 62 72 61 6e 63 68 2d 6e 61 6d 65
      IDENTITE OCTET PAR OCTET config ↔ workflow : ✔ OUI
====================================================================================================
[4/4] libelle config : '📱 App (gates run_gates.py)'
      workflow        : .github/workflows/ci.yml   ·   job_id declare : 'app-quality'
      longueur         : 26 points de code · 29 octets UTF-8
      points de code   : U+1F4F1 U+0020 U+0041 U+0070 U+0070 U+0020 U+0028 U+0067 U+0061 U+0074 U+0065 U+0073 U+0020 U+0072 U+0075 U+006E U+005F U+0067 U+0061 U+0074 U+0065 U+0073 U+002E U+0070 U+0079 U+0029
      octets UTF-8     : f0 9f 93 b1 20 41 70 70 20 28 67 61 74 65 73 20 72 75 6e 5f 67 61 74 65 73 2e 70 79 29
      non-ASCII        : [('U+1F4F1', '📱', 'MOBILE PHONE')]
      U+FE0F (variation selector-16) present ? : NON
      forme NFC ? name == NFC(name) : True   ·   NFC == NFD ? True (False = le libelle contient des caracteres composables)
      len(NFC)=26  len(NFD)=26  → decomposition absente (precompose)
      espace double ? False   ·   espace insecable/invisible ? False   ·   parenthese non-ASCII ? False
      appariement       : `name:` de job, ligne 65
      ligne du YAML     : '    name: 📱 App (gates run_gates.py)'
      libelle du YAML   : '📱 App (gates run_gates.py)'
      octets du YAML    : f0 9f 93 b1 20 41 70 70 20 28 67 61 74 65 73 20 72 75 6e 5f 67 61 74 65 73 2e 70 79 29
      IDENTITE OCTET PAR OCTET config ↔ workflow : ✔ OUI
====================================================================================================

SYNTHESE
libelle                                          identique  appariement
🔐 Secrets scan (gitleaks)                        OUI        `name:` de job
📋 Governance (SCB + traçabilité + synchro)       OUI        `name:` de job
check-branch-name                                OUI        ID de job (aucun `name:` — GitHub Actions affiche l'ID)
📱 App (gates run_gates.py)                       OUI        `name:` de job

Libelles verifies : 4 · conformes : 4
Aucun U+FE0F : True
Tous en NFC  : True
```

---

## 3. Resultat

| # | Libelle (config) | Emoji | Points de code notables | `U+FE0F` | NFC | Appariement workflow | Identite octet par octet |
|---|---|---|---|---|---|---|---|
| 1 | `🔐 Secrets scan (gitleaks)` | `U+1F510` CLOSED LOCK WITH KEY | 25 points de code / 28 octets | **NON** | **oui** | `ci.yml:29` — `name:` de job (`secrets-scan`) | **OUI** |
| 2 | `📋 Governance (SCB + traçabilité + synchro)` | `U+1F4CB` CLIPBOARD | `ç` = **`U+00E7`**, `é` = **`U+00E9`** — **precomposes** ; 42 points de code / 47 octets | **NON** | **oui** | `ci.yml:48` — `name:` de job (`governance`) | **OUI** |
| 3 | `check-branch-name` | *aucun* | ASCII pur, 17 points de code / 17 octets | **NON** | **oui** | `branch-naming.yml:10` — **ID de job** (aucun `name:`) | **OUI** |
| 4 | `📱 App (gates run_gates.py)` | `U+1F4F1` MOBILE PHONE | 26 points de code / 29 octets | **NON** | **oui** | `ci.yml:65` — `name:` de job (`app-quality`) | **OUI** |

**4 libelles verifies, 4 conformes.** Aucun `U+FE0F`. Aucun accent decompose : `ç` et `é` sortent en
**forme precomposee NFC** (`U+00E7`, `U+00E9`) — le test `len(NFD) != len(NFC)` sur le libelle n° 2
(42 -> 44) confirme que ces caracteres **sont** decomposables, et que la forme **stockee** est bien
la forme **composee**. Aucun espace double, aucun espace insecable ou invisible, aucune parenthese
non-ASCII. Le constat de @Architect du 2026-07-27 est **reproduit et confirme**.

---

## 4. Gate de coherence des libelles — `factory_sync.py --check`

```text
$ python scripts/factory_sync.py --check
Synchro factory conforme — vérification DOCUMENTAIRE, aucun appel réseau (env, bloc GIT_PROTECTION.md, libellés de jobs des workflows, seuils).
[AVERTISSEMENT] l'état RÉEL de la protection de branche sur GitHub n'est PAS vérifié ici : lancer `python scripts/factory_sync.py --check-remote` (droits admin requis).
=> code de sortie : 0
```

Ce gate (job CI **`📋 Governance`**, bloquant) exige que **chaque** `status_checks[].name` de la
config existe dans le workflow cite, soit comme `name:` de job, soit comme **ID de job**
(`check_workflows()`, `scripts/factory_sync.py:102-120`). Les 4 libelles sont donc **deja** verifies
coherents `config <-> workflows` **a chaque CI**, et pas seulement aujourd'hui.

### 4.1 Sa limite, ecrite noir sur blanc

> **`--check` compare la configuration au FICHIER de workflow, jamais au libelle que GitHub
> RAPPORTE REELLEMENT.** Il ne lit pas l'API : sa propre sortie le dit (« verification
> **DOCUMENTAIRE**, aucun appel reseau »). Un libelle exact dans le YAML mais rapporte differemment
> par la plateforme — ou un job qui **ne se declenche pas** sur l'evenement de la PR — produirait le
> **meme** `BLOCKED`, sans que `--check` n'y voie rien.

Le controle qui manque est donc **reporte au critere de test n° 25** (`gh pr checks <n>`), a lever
**sur la PR** et **avant toute tentative de fusion**. Toute divergence a ce moment-la = **R-1** :
appliquer le plan de retour arriere, **sans tenter de fusionner**.

---

## 5. Deux points de vigilance qui subsistent malgre ce resultat

1. **`check-branch-name` est apparie par son ID de job, non par un `name:`.** C'est licite (GitHub
   Actions affiche l'ID quand `name:` est absent), mais cela signifie que **renommer le job**
   `check-branch-name:` dans `branch-naming.yml` casserait le contexte requis. A ne jamais faire
   sans re-appliquer la protection depuis la source unique.
2. **Le declenchement du workflow compte autant que le libelle.** Verifie dans
   `.github/workflows/branch-naming.yml` : `on: pull_request: types: [opened, edited, synchronize,
   reopened]` — le contexte **sera** rapporte sur les PR (y compris a la reouverture), et
   `push: branches-ignore: [main]` evite qu'il ne se declenche sur la branche principale. Le point de
   vigilance nomme par l'AC-8 limite est donc **couvert pour ces quatre evenements**, et **non
   couvert** pour ceux qui ne sont pas listes (par exemple `ready_for_review`, ou une PR issue d'un
   **fork** dont le declenchement et les droits diffèrent — cf. dette R-4).

---

## 6. Ce que cette verification NE prouve PAS

* Elle ne prouve **rien** sur les libelles que GitHub rapportera : c'est le critere **25**, sur PR.
* Elle vaut **a sa date** et pour l'etat courant de `factory.config.json` et des deux workflows. Une
  edition ulterieure d'un `name:` de job (fichier **hors** `protect_files.sh` : un agent peut
  l'editer) invaliderait ce constat sans qu'aucune barriere ne s'y oppose, hors le gate `--check` —
  qui **detecterait** la divergence config <-> workflow, mais **seulement** celle-la.
* Elle ne dit rien de la **fusionnabilite** : `strict: true` (branche a jour) et
  `required_conversation_resolution: true` (zero discussion ouverte) ajoutent **deux** conditions
  supplementaires, et le nom de branche doit matcher `^feat/US-[0-9]+\.[0-9]+.*$` (dette **R-4**,
  contrainte **assumee** par arbitrage humain).
