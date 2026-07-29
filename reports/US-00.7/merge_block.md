# T11 — PR #12 : ce que la fusion a prouvé, et **ce qu'elle n'a PAS prouvé**

> ## ⛑️ RECTIFICATION DU 2026-07-29 — **deux énoncés de ce rapport sont FAUX**. Rien n'est supprimé.
>
> *(Relevé par la **re-QA** — finding « critère 27 régressé ». Ce rapport est **nommé par le critère 27** :
> tant qu'il porte une assertion fausse, le critère **n'est pas levé**.)*
>
> **① §3, l. 91-92 — « case 34 : satisfait, et vérifiable par `mergedBy.is_bot = false` » : FAUX.**
> ⛔ **`is_bot` NE PROUVE RIEN.** Les agents opèrent avec **le jeton de l'humain** ; le champ rend
> **`false` même pour une fusion exécutée par un AGENT** — établi le 2026-07-29 par une **violation
> réelle** (`merge_proof_and_violation.md`). Ce n'est **pas** un fait daté qui s'historise, c'est une
> **assertion de méthode qui n'a jamais été vraie**. Elle était exacte **par hasard** sur la PR #12
> — l'humain avait réellement fusionné — et serait sortie **identique** si un agent l'avait fait.
> ⇒ **La case 34 est DÉCOCHÉE**, sa méthode de preuve **refondue** *(attestation humaine datée, assumée
> **déclarative**)*, et la dette de provenance est **fusionnée** avec celle de `TRACKS.md` → **US-00.8**.
>
> **② §« Ce qui n'est PAS prouvé », point 1 — « le refus d'une tentative de fusion » : PÉRIMÉ.**
> ✅ **Il EST prouvé depuis le 2026-07-29T08:49:14Z**, **par le SERVEUR** : sur la **PR #14**, lancé par
> **l'humain** avec **1/4** contexte vert, `gh api -X PUT …/pulls/14/merge` → **HTTP 405**,
> *« **3 of 4 required status checks are expected** »*. `gh api` n'est qu'un **transport HTTP** : le refus
> **n'est pas** un pré-contrôle client. **Administrateur inclus** (`admin: true` + `enforce_admins: true`).
> ⇒ **AC-4 nominal COMPLET**, **cases 13 et 23 cochées**.
> Preuve : [`applied_state/merge_refusal_server_405.txt`](applied_state/merge_refusal_server_405.txt).
>
> **Ce qui reste vrai dans ce rapport, et qui l'était déjà** : la distinction **état calculé** vs **action
> refusée**, l'analyse du `BLOCKED` de la PR #12, le renversement du `CLEAN` d'US-00.4, et la borne
> « contexte **`expected`**, pas **`failing`** » — **toujours valable**, la conjonction littérale d'US-00.1
> n'ayant **jamais** été observée.

> **US** : US-00.7 · **Tâche** : T11 · **AC** : AC-4 · **Date** : 2026-07-28
> **PR** : [#12](https://github.com/gitgdx/Concentration/pull/12) — `feat/US-00.7-application-protection-branche` → `main`
> **Commit de fusion** : `9fdb7fd4fdecea5f7d102533843a932cb46a8338`

---

## ⛔ EN TÊTE, PARCE QU'ON NE L'ENTERRE PAS : **la preuve du REFUS DE FUSION n'a PAS été obtenue**

**T11(d) — la tentative de fusion réelle refusée, motif brut archivé — n'a pas eu lieu.** La fenêtre
déterministe s'est refermée **avant** que la tentative ne soit lancée. Aucun `gh pr merge` n'a été
refusé ; aucun message de refus n'existe ; `reports/US-00.7/applied_state/merge_refusal_raw.txt`
**n'a jamais été créé**.

**Cause, nommée sans détour** : l'agent a annoncé « une fenêtre de quelques minutes » en extrapolant la
durée **locale** du gate `📱 App` (build Flutter web, > 3 min sur le poste). **En CI, ce même job a duré
1 min 23 s.** La fenêtre réelle a été de **~1 min 20 s**, non de « quelques minutes ». L'humain a reçu
la consigne **après** sa fermeture.

**Conséquence directe** : **l'AC-4 nominal n'est pas satisfait** et la **case 13 de la DoD reste
décochée**. Aucune formulation de ce rapport ne doit laisser croire l'inverse.

---

## Chronologie établie par l'API, à la seconde

| Horodatage UTC | Événement | Source |
|---|---|---|
| 15:25:22 | `check-branch-name` *(événement `push`)* → **success** | `GET …/commits/2686538/check-runs` |
| 15:25:29 | `check-branch-name` *(événement `pull_request`)* → **success** | idem |
| **15:25:30** | **`mergeStateStatus: BLOCKED` capturé et archivé** | `merge_block_pending.json` |
| 15:25:34 | `📋 Governance (SCB + traçabilité + synchro)` → **success** | check-runs |
| 15:25:43 | `🔐 Secrets scan (gitleaks)` → **success** | check-runs |
| **15:26:49** | `📱 App (gates run_gates.py)` → **success** — **fin de la fenêtre** | check-runs |
| 15:34:21 | **Fusion** par `gitgdx` (`is_bot: false`) — **+7 min 32 s après le dernier vert** | `gh pr view 12 --json mergedAt,mergedBy` |

La capture `BLOCKED` de **15:25:30** est **antérieure** à la complétion de **trois** contextes requis
(`Governance` 15:25:34 · `Secrets scan` 15:25:43 · `App` 15:26:49). Elle est donc bien **attribuable à
des contextes requis non encore verts**, et non à un autre motif de blocage.

---

## ✅ Ce qui EST prouvé

### 1. Les libellés **réellement rapportés** correspondent aux contextes requis — le contrôle que T3 ne pouvait pas faire

T3 comparait `factory.config.json` au **fichier de workflow**. Il ne pouvait rien dire du libellé que
GitHub **rapporte** effectivement sur une PR. Comparaison exécutée sur la PR #12 :

```
REQUIS (protection_applied.json) : 4
    'check-branch-name'
    '📋 Governance (SCB + traçabilité + synchro)'
    '📱 App (gates run_gates.py)'
    '🔐 Secrets scan (gitleaks)'
RAPPORTES (gh pr view 12 --json statusCheckRollup) : 4 libellés distincts
    'check-branch-name'
    '📋 Governance (SCB + traçabilité + synchro)'
    '📱 App (gates run_gates.py)'
    '🔐 Secrets scan (gitleaks)'

Requis NON rapportés : AUCUN
Rapportés hors cible : AUCUN
=> IDENTITÉ CARACTÈRE POUR CARACTÈRE : OUI
```

**Aucune divergence** ⇒ le risque **R-1** ne se matérialise pas, le plan de retour arrière n'a pas
lieu d'être déclenché.

> **Détail conservé** : `check-branch-name` est rapporté **deux fois** sur le même SHA (événements
> `push` **et** `pull_request`) → **5 check-runs pour 4 libellés**. Constat déjà établi par US-00.4,
> **reproduit à l'identique**.

### 2. `mergeStateStatus: BLOCKED` — et c'est le renversement exact du constat d'US-00.4

| | US-00.4 · PR #10 *(2026-07-27)* | US-00.7 · PR #12 *(2026-07-28)* |
|---|---|---|
| Protection | **absente** | **appliquée** |
| Checks requis | **aucun** | **4** |
| `mergeStateStatus` avec des checks non verts | **`CLEAN`** | **`BLOCKED`** |
| Lecture | « rien ne bloque » — la PR était **fusionnable en rouge** | un contexte requis non vert **bloque** |

C'est le même dépôt, le même compte, la même commande. **Seule la protection a changé.**

### 3. La fusion n'a eu lieu qu'après les **4 verts**, et elle vient d'un **humain**

`gh pr checks 12` → **4/4 `pass`**, puis fusion à 15:34:21Z par `gitgdx`, `is_bot: false`.
**Première fusion de l'histoire du dépôt dont les gates conditionnaient réellement la recevabilité.**

~~Renforcement de track **R-c** / **case 34 de la DoD** — « l'approbation/fusion ne vient pas d'un
agent » : **satisfait**, et vérifiable par `mergedBy.is_bot = false`.~~
⛑️ **BARRÉ le 2026-07-29 — voir la rectification ① en tête de ce rapport.** `is_bot` **ne prouve rien**
(jeton partagé entre l'humain et les agents) ⇒ **case 34 DÉCOCHÉE**, méthode de preuve **refondue**.

> ⚠️ **Borne** : `reviewDecision` est **vide** et `latestReviews` est un **tableau vide**. Il n'existe
> donc **aucune approbation GitHub formelle** — c'est **attendu** (la cible est à
> `required_approving_review_count: 0`, précisément parce qu'un dépôt à un seul collaborateur ne permet
> pas l'auto-approbation). La revue humaine est **consignée documentairement**, elle **n'est pas
> soutenue par une barrière machine** — c'est la **dette R7 d'US-00.4, maintenue ouverte**.

---

## ⛔ Ce qui n'est PAS prouvé — liste explicite

1. **Le refus d'une tentative de fusion** *(T11(d), AC-4 nominal)*. Un `mergeStateStatus: BLOCKED` est
   un **état calculé par GitHub**, pas une **action refusée**. La distinction est exactement celle déjà
   posée pour `allow_force_pushes` / `allow_deletions` : **prouvés par l'état de l'API, pas par
   l'effet**. Ne pas confondre les deux revient à commettre l'erreur qu'US-00.4 dénonce.
2. **Le refus opposé à un administrateur au moment d'un merge.** `enforce_admins` est en vigueur dans
   l'**état** de l'API, et le test négatif du push direct l'a exercé — **jamais** sur le chemin de
   fusion.
3. Rien n'est établi pour l'**interface web**, une PR issue d'un **fork**, une PR **réouverte**, ni pour
   un **autre acteur**.

---

## Comment cette preuve reste obtenable — sans travail artificiel

Le cycle d'US-00.7 n'est pas terminé : audits, QA puis certification suivent, et le **pattern rodé du
projet** (US-00.1 → US-00.4) impose une **seconde PR** depuis une branche post-fusion
`feat/US-00.7-certif`. **Cette PR franchira les mêmes 4 contextes requis** et rouvrira donc la même
fenêtre.

**Procédure corrigée, à appliquer telle quelle** — l'erreur à ne pas refaire est d'attendre :

1. Ouvrir la PR.
2. **Immédiatement, sans capture préalable**, lancer la tentative de fusion :
   `gh pr merge <n> --merge 2>&1 | Tee-Object reports/US-00.7/merge_refusal_raw.txt`
   La fenêtre utile est de l'ordre de **~80 secondes**, pas de « quelques minutes ».
3. Archiver le refus **brut**, puis seulement ensuite constater les 4 verts et fusionner.

⛔ **Interdits inchangés** : `--admin`, désactivation temporaire de la règle, retrait d'un contexte,
casse volontaire d'un gate pour obtenir un rouge.

> **Pourquoi `expected` et non `failing`** : l'AC-4 nominal accepte **les deux**. On n'a jamais tenté
> d'obtenir un rouge — casser un gate volontairement est explicitement interdit par le Story File.

---

## Fichiers de preuve

| Fichier | Contenu |
|---|---|
| [`applied_state/merge_block_pending.json`](applied_state/merge_block_pending.json) | Réponse brute `gh pr view 12 --json …` à **15:25:30Z** : `mergeStateStatus: BLOCKED`, `mergeable: MERGEABLE`, rollup complet |
| *(absent — assumé)* `applied_state/merge_refusal_raw.txt` | **N'existe pas.** La tentative de fusion refusée n'a pas eu lieu. **Ce vide est la preuve de l'absence de preuve**, il n'est pas comblé par un substitut |
