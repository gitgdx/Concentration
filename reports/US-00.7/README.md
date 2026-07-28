# Preuves — US-00.7 · Protection de la branche principale : application effective, preuve par l'effet, cohérence du corpus

> 🟡 **INDEX PARTIEL — PHASE 0 SEULEMENT (T1 → T7).** Il sera **complété en T23** (index complet
> T1 → T23 au format `reports/INDEX.md`). Les répertoires `applied_state/` et les fichiers
> `negative_test.md`, `merge_block.md`, `transmissions.md`, `non_regression.md` **n'existent pas
> encore** : ils dépendent du `PUT` (T8), qui est une **action humaine explicite**.

> ⛔ **RIEN DANS CE RÉPERTOIRE N'ATTESTE QUE `main` EST PROTÉGÉE. ELLE NE L'EST PAS.**
> À la date de cet index : `GET …/branches/main/protection` → **404 « Branch not protected »**,
> `GET …/branches/main` → **`"protected": false`**, `python scripts/factory_sync.py --check-remote`
> → **exit 1** avec **7 écarts**. La protection est **disponible** (le dépôt est **public** depuis le
> 2026-07-27) et **non appliquée**.

> 🔴 **Distinction à ne jamais perdre en audit** — deux familles de fichiers, jamais interchangeables :
> * **ÉTAT RÉEL** : `entry_state/**` — réponses brutes d'API, `GET` seuls, horodatées UTC, **sans**
>   préfixe `[SIMULATION]`.
> * **SIMULATIONS** : `nb1_fix.md` et tout `tests/fixtures/US-00.7/**` — **chaque** ligne de sortie de
>   comparateur y porte `[SIMULATION] `. **Jamais** une preuve d'état réel.

| Champ | Valeur |
|---|---|
| Branche | `feat/US-00.7-application-protection-branche` (basée sur `main` = `f4400ca`) |
| Phase couverte | **0 — préalables · AUCUNE écriture distante** |
| Date | **2026-07-27** |
| `origin/main` avant / après la phase 0 | **`f4400ca2edd5a53e8879a7568818650eeb32d0d4`** — **inchangée** |
| Écritures distantes émises | **AUCUNE.** Aucun `PUT` / `POST` / `PATCH` / `DELETE`, aucun `git push`, aucun test négatif |

## État des tâches — phase 0

| Tâche | Description | Statut | Preuve |
|---|---|---|---|
| **T1** | Correctif **NB-1** (3 lignes) + démonstration **avant / après** sur fixtures + **13 chemins d'US-00.4 rejoués** | ✅ | `nb1_fix.md` §2, §4, §5, §6 · `tests/fixtures/US-00.7/**` |
| **T2** | Contrôle compensatoire de **complétude de la cible** (`set(payload) == MAPPED_TOP_KEYS` → `True`) | ✅ | `nb1_fix.md` §7 |
| **T3** | **4 libellés vérifiés caractère par caractère** (points de code, `U+FE0F`, NFC) + `--check` exit 0 | ✅ | `labels_verification.md` |
| **T4** | **État d'entrée archivé** — 5 réponses brutes datées UTC, `GET` seuls | ✅ | `entry_state/` (6 fichiers) |
| **T5** | **Sauvegarde de `main`** (SHA + clone miroir) + **procédure de restauration écrite** | ✅ | `rollback_main.md` |
| **T6** | **Plan de retour arrière** écrit **avant** le `PUT` | ⚠️ **rédigé, NON inséré** | `rollback_plan.md` — *`docs/GIT_PROTECTION.md` hors périmètre autorisé de la phase 0 ; point d'insertion et diff fournis au §7* |
| **T7** | **Balayage inverse** — 2 passes + 1 complémentaire, toutes extensions, **angles morts déclarés** | ✅ | `corpus_sweep.md` |
| **T8** | 🔴 **LE `PUT`** — appliquer la protection | ⛔ **NON EXÉCUTÉ** | **[confirmation humaine explicite]** — un agent ne l'exécute jamais |
| **T9 → T24** | Preuves d'état appliqué · test négatif · PR · cohérence du corpus · clôture | ⛔ **NON EXÉCUTÉES** | interdites avant T8 |

## Fichiers

| Fichier | Contenu | Nature |
|---|---|---|
| `entry_state/repo_context.json` | `{"private": false, "visibility": "public", "owner_type": "User", "permissions.admin": true}` | **état réel** |
| `entry_state/protection_404.json` | `GET …/branches/main/protection` → **404 « Branch not protected »** *(et non plus 403)* | **état réel** |
| `entry_state/protection_404.stderr.txt` | stderr de `gh` + explication de son **exit 1** *(= la preuve attendue, pas un échec)* | **état réel** |
| `entry_state/rulesets_200_empty.json` | `GET …/rulesets` → **200 `[]`** | **état réel** |
| `entry_state/branch_main_before.json` | `{"name": "main", "protected": false}` | **état réel** |
| `entry_state/check_remote_exit1.txt` | `--check-remote` → **exit 1**, `protection ABSENTE`, **7 écarts**, `gh` vérifié présent (R-10) | **état réel** |
| `nb1_fix.md` | T1 + T2 : diff exact, 4 scénarios avant/après, 13 rejeux, complétude de la cible, **NB-1bis** | **simulations** |
| `labels_verification.md` | T3 : points de code des 4 libellés, appariement config ↔ workflows, limite de `--check` | analyse |
| `rollback_main.md` | T5 : SHA `f4400ca`, chemin du miroir, 3 procédures de restauration, contrôle de garde de T10 | procédure |
| `rollback_plan.md` | T6 : plan de retour arrière en cas de **verrouillage**, + point d'insertion dans `docs/GIT_PROTECTION.md` | procédure |
| `corpus_sweep.md` | T7 : 2 passes + 1, **11 artefacts vivants confirmés** + **3 ledgers** transmis, **10 angles morts déclarés** | inventaire |

## Ce que la phase 0 a établi — et ce qu'elle n'établit pas

**Établi** :

1. Le **faux vert NB-1 est reproduit** (exit 0 sur une cible amputée) puis **réduit** : sur une valeur
   réelle **ACTIVE**, l'issue passe à **exit 2** en nommant la clé. Les **13 chemins** d'US-00.4 sont
   rejoués **sans un seul changement d'issue** — l'outil ne devient pas rouge sur une évolution
   additive neutre de l'API (critère #24 d'US-00.4 **toujours vert**).
2. **NB-1bis** est **ouvert et nommé** : sur un **relâchement** (`{"enabled": false}`) ou une clé
   absente des deux côtés, l'`exit 0` **subsiste**. Le correctif est un **progrès strict, pas une
   fermeture**.
3. Le **risque du jour est neutralisé** par un fait vérifiable en une commande :
   `set(payload) == MAPPED_TOP_KEYS` → **`True`** — la cible **n'est pas amputée**.
4. Les **4 libellés** de contextes sont **identiques à l'octet** entre `factory.config.json` et les
   workflows, **sans `U+FE0F`**, en **NFC**. Le risque de **verrouillage** par divergence de libellé
   est réduit d'autant.
5. L'**état d'entrée est daté et distinct** de celui du 2026-07-26 : **404 ≠ 403**. Le risque **R3**
   d'US-00.4 (« chemin 404 non observable in vivo ») est **CLOS par l'observation**.
6. `main` est **sauvegardée** (`f4400ca` + miroir hors dépôt) et les **3 procédures de restauration**
   sont écrites **avant** que le risque ne soit pris.
7. Le corpus vivant compte **11 artefacts** — confirmé ligne par ligne — **plus 3 ledgers** hors
   périmètre @Developer, transmis nommément. **Zéro** sur-affirmation aujourd'hui.

**Non établi — et à ne pas laisser croire** :

* `main` **n'est pas protégée**. Aucune règle n'existe côté serveur.
* **Aucun effet** n'est prouvé : ni refus serveur de push (AC-3), ni refus de fusion (AC-4).
* Le comparateur **n'a jamais rendu `exit 0` in vivo** : l'écart de preuve n° 3 d'US-00.4 reste
  **ouvert** jusqu'à T9.
* **Dettes maintenues OUVERTES** : aucune détection automatique de dérive · **aucun `selftest` en
  CI** · `check_branch_protection.py` **hors** `protect_files.sh` · périmètre Art. 6 déclaré ≠
  appliqué · **NB-1bis** *(nouveau)* · revue humaine du track FULL sans barrière machine.
* La **dérogation `EVT_WAIVER_GRANTED`** du 2026-07-26 n'est **pas encore éteinte** (T21, après T8).
* Tout l'édifice reste **conditionné à la visibilité publique** du dépôt : un retour en privé
  ramènerait le **403** et **rouvrirait** la question de la dérogation.
