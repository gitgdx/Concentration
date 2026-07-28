# US-00.7 · T5 — Sauvegarde de `main` et **procédure de restauration écrite AVANT tout test négatif**

> ⛔ **Ce document doit exister et être commité AVANT T10.** Il est le **préalable bloquant** du test
> négatif serveur : T10 pointe `git push`, `git push --force` et `git push --delete` vers la branche
> principale. Si l'une de ces trois commandes **réussissait** (protection non effective), `main`
> serait modifiée, réécrite ou supprimée — et il serait trop tard pour écrire la procédure.
>
> ⚠️ **Aucune de ces commandes de restauration n'a été exécutée**, et **aucune écriture distante n'a
> eu lieu** pour produire ce fichier. Il est **préparatoire**.

| Champ | Valeur |
|---|---|
| Tâche | **T5** — phase 0, aucune écriture distante |
| AC | **AC-3 limite** · risque **R-9** (fenêtre de danger du test négatif) |
| Critère de test levé | **10** (conditionné AVANT `PUT`) |
| Date | **2026-07-27** |

---

## 1. État sauvegardé — SHA consignés

| Référence | SHA | Vérifié par |
|---|---|---|
| **`origin/main`** | **`f4400ca2edd5a53e8879a7568818650eeb32d0d4`** | `git rev-parse origin/main` |
| `main` (local) | `f4400ca2edd5a53e8879a7568818650eeb32d0d4` | `git rev-parse main` — **identique**, aucune divergence locale |
| `HEAD` (branche de l'US) | `90fd1a622477e0245624cfb4b868d0ae7f6dd3fe` | `git rev-parse HEAD` |
| Branche courante | `feat/US-00.7-application-protection-branche` | `git branch --show-current` |
| Remote `origin` | `https://github.com/gitgdx/Concentration.git` | `git remote get-url origin` |

Commit de tête de `main` :

```text
f4400ca2edd5a53e8879a7568818650eeb32d0d4
gitgdx <guillaume.decroix@free.Fr>
2026-07-27T17:40:09+02:00
Merge PR #11 — Certification US-00.4 (enforcement main : constat + outillage) → main
```

Cinq derniers premiers-parents de `main` (`git log --first-parent --oneline -5 origin/main`) — c'est
la référence de comparaison en cas de réécriture d'historique :

```text
f4400ca Merge PR #11 — Certification US-00.4 (enforcement main : constat + outillage) → main
15121d8 Merge PR #10 — US-00.4 enforcement main : constat + outillage + cible armee (NON appliquee) → main
801a046 Merge PR #9 — US-00.3 déploiement + certification Prod → main
3490926 Merge PR #8 — US-00.3 convention migrations réversibles → main
f9c19b9 Merge PR #7 — US-00.2 déploiement + certification Prod → main
```

---

## 2. Clone **miroir** de sauvegarde — chemin exact

```sh
git clone --mirror "C:/Users/guillaume.decroix/MesProjets/Concentration" \
                   "C:/Users/guillaume.decroix/MesProjets/_backup_US-00.7/Concentration-main-f4400ca.git"
```

| Champ | Valeur |
|---|---|
| **Chemin du miroir** | `C:\Users\guillaume.decroix\MesProjets\_backup_US-00.7\Concentration-main-f4400ca.git` |
| Emplacement | **hors** du dépôt de travail (répertoire frère) |
| Taille | 2,3 Mio |
| `refs/heads/main` | `f4400ca2edd5a53e8879a7568818650eeb32d0d4` |
| `refs/remotes/origin/main` | `f4400ca2edd5a53e8879a7568818650eeb32d0d4` |
| Objet `f4400ca` présent | **oui** — `git -C <miroir> cat-file -e f4400ca…^{commit}` → succès |

`git -C <miroir> show-ref` au moment de la sauvegarde :

```text
90fd1a622477e0245624cfb4b868d0ae7f6dd3fe refs/heads/feat/US-00.7-application-protection-branche
9d84d2d960179a3f10103a234540b099388baa9a refs/heads/feat/US-01.1-affichage-hub-grille
f4400ca2edd5a53e8879a7568818650eeb32d0d4 refs/heads/main
f4400ca2edd5a53e8879a7568818650eeb32d0d4 refs/remotes/origin/HEAD
9d84d2d960179a3f10103a234540b099388baa9a refs/remotes/origin/feat/US-01.1-affichage-hub-grille
f4400ca2edd5a53e8879a7568818650eeb32d0d4 refs/remotes/origin/main
```

**Le miroir a été cloné depuis le dépôt LOCAL, et non depuis le remote** — délibérément : un
`git clone --mirror <URL>` aurait ouvert une connexion vers GitHub, alors que la phase 0 s'interdit
toute opération distante hors `GET` de lecture. Le dépôt local portait déjà `origin/main = f4400ca`
(identique au distant, vérifié au §1), donc la sauvegarde est **complète** pour l'objet qui compte.

**Limite de durabilité, déclarée** : ce miroir est un répertoire local du poste. Il ne protège ni
d'une perte de disque, ni d'une suppression accidentelle. Il protège de **ce contre quoi T10 doit
protéger** : une commande destructive réussie sur `origin/main`. C'est son seul objet.

---

## 3. Procédure de restauration — **les 3 scénarios d'échec**, dans l'ordre de dangerosité de T10

> **Règle absolue commune aux trois** : si l'une des commandes de T10 **réussit**, la protection
> **n'est pas effective**. Il faut alors, **dans cet ordre** : (i) restaurer `main`, (ii) tracer
> `EVT_WORKFLOW_VIOLATION`, (iii) **ré-appliquer depuis la configuration**, (iv) recommencer le test
> négatif. ⛔ **Jamais** `--no-verify` (Constitution Art. 1). ⛔ **Jamais** de correction silencieuse.

### Scénario A — un **commit indu** est arrivé sur `main` (le `git push` simple a réussi)

Le moins grave : l'historique n'est pas réécrit, le commit est **en trop**. `main` étant la branche
principale, la remise en état passe par une **PR de revert**, jamais par un push direct.

```sh
# 1. Constat : quel commit est en trop ?
git fetch origin
git log --oneline f4400ca2edd5a53e8879a7568818650eeb32d0d4..origin/main

# 2. Revert PAR PR (aucun push direct sur main, même pour réparer)
git switch -c fix/US-00.7-revert-push-indu origin/main
git revert --no-edit <SHA_DU_COMMIT_INDU>
git push -u origin fix/US-00.7-revert-push-indu
gh pr create --base main --head fix/US-00.7-revert-push-indu \
             --title "fix(us-00.7): revert du push direct indu sur main" \
             --body "Incident T10 — voir reports/US-00.7/negative_test.md et PROJECT_LOG.md"
# puis fusion normale, checks verts
```

⚠️ **Ne PAS employer `git push --force` pour « effacer » le commit** : cela transformerait un
incident réversible en réécriture d'historique, et l'US s'interdit explicitement de réécrire
l'historique.

### Scénario B — l'**historique a été réécrit** (le `git push --force` a réussi)

```sh
# 1. Constat
git fetch origin
git rev-parse origin/main            # doit rendre f4400ca… ; s'il rend autre chose : réécriture

# 2. Restauration de la tête de main sur le SHA sauvegardé — depuis le clone de travail
git push --force-with-lease=main:$(git rev-parse origin/main) \
         origin f4400ca2edd5a53e8879a7568818650eeb32d0d4:refs/heads/main

# 2 bis. Repli si les objets manquent localement — restauration depuis le MIROIR
git -C "C:/Users/guillaume.decroix/MesProjets/_backup_US-00.7/Concentration-main-f4400ca.git" \
    push --force https://github.com/gitgdx/Concentration.git \
    f4400ca2edd5a53e8879a7568818650eeb32d0d4:refs/heads/main

# 3. Vérification
git fetch origin && git rev-parse origin/main       # attendu : f4400ca2edd5a53e8879a7568818650eeb32d0d4
git log --first-parent --oneline -5 origin/main      # doit correspondre au §1
```

⚠️ Un `--force` **vers `main`** est ici un acte de **réparation d'incident**, pas une opération de
travail : il n'est légitime **que** dans ce scénario, **que** vers le SHA sauvegardé, et **il doit
être tracé** (§4). Si la protection est active, ce push sera lui-même **refusé** — il faudra alors
**désactiver temporairement la règle** (`DELETE …/protection`, cf. le plan de retour arrière), puis
la **ré-appliquer depuis la config** : c'est de l'**administration**, pas un contournement.

### Scénario C — la **branche principale a été supprimée** (le `git push --delete` a réussi)

```sh
# 1. Constat
gh api repos/gitgdx/Concentration/branches/main        # 404 = branche absente

# 2. Recréation depuis le SHA sauvegardé
git push origin f4400ca2edd5a53e8879a7568818650eeb32d0d4:refs/heads/main

# 2 bis. Repli depuis le MIROIR (si les objets manquent localement)
git -C "C:/Users/guillaume.decroix/MesProjets/_backup_US-00.7/Concentration-main-f4400ca.git" \
    push https://github.com/gitgdx/Concentration.git \
    f4400ca2edd5a53e8879a7568818650eeb32d0d4:refs/heads/main

# 3. Rétablir la branche par défaut du dépôt si elle a été perdue
gh api -X PATCH repos/gitgdx/Concentration -f default_branch=main     # ⚠️ action humaine

# 4. Vérifications
git fetch origin && git rev-parse origin/main          # attendu : f4400ca…
gh api repos/gitgdx/Concentration --jq "{default_branch}"
python scripts/factory_sync.py --check-remote          # ré-appliquer la protection si exit != 0
```

⚠️ La suppression d'une branche **par défaut** est normalement refusée par la plateforme même sans
protection de branche. Si elle réussissait, il faudrait **aussi** vérifier et rétablir
`default_branch` — d'où l'étape 3, qui est une **écriture d'administration** et donc une **action
humaine**.

---

## 4. Obligations de traçabilité en cas d'incident — non négociables

1. `python scripts/trace_append.py --us US-00.7 --event EVT_WORKFLOW_VIOLATION --agent developer …`
   avec, dans le `rationale` : **quelle** commande a réussi, **quel** SHA a été observé, **quelle**
   restauration a été appliquée.
2. Ligne ajoutée à `PROJECT_LOG.md` (tableau) — jamais une correction silencieuse.
3. Sortie **brute** de la commande fautive archivée dans `reports/US-00.7/negative_test.md`, **y
   compris** quand elle a réussi : un test négatif qui échoue est un **résultat**, pas une gêne.
4. `git rev-parse origin/main` relevé **avant** et **après** la restauration, les deux archivés.

---

## 5. Contrôle de garde de T10 — à relire **immédiatement avant chaque** commande

```sh
gh api repos/gitgdx/Concentration/branches/main/protection --jq \
  "{admins:.enforce_admins.enabled, fp:.allow_force_pushes.enabled, del:.allow_deletions.enabled}"
# attendu : {"admins":true,"fp":false,"del":false}
```

⛔ Si ce contrôle ne rend pas exactement ces trois valeurs, **T10 ne doit pas être lancé** : les trois
commandes **réussiraient**. C'est la dette **#12** d'US-00.4, ici **interdiction dure**.

**État à la date de ce fichier** : `GET …/branches/main/protection` → **404 « Branch not protected »**
(cf. `entry_state/protection_404.json`). Le contrôle de garde **échoue donc aujourd'hui**, et c'est
normal : **T10 est interdit avant T9**.

---

## 6. Après usage

* Le **clone jetable** de T10 (créé hors du dépôt de travail, `core.hooksPath` **vide**) doit être
  **supprimé** après le test.
* Le **miroir de sauvegarde** du §2 peut être conservé jusqu'à la certification de l'US, puis
  supprimé. Sa suppression doit être **consignée**, faute de quoi un lecteur ultérieur de ce document
  croirait disposer d'une sauvegarde qui n'existe plus.
