# T20 — `scripts/githooks/pre-push` : édition humaine (Art. 6) et vérification

> **Date** : 2026-07-28 · **US** : US-00.7 · **Tâche** : T20 · **Nature** : action humaine (Art. 6)
> **Diff de référence** : [`transmissions.md` §8](transmissions.md) — version **corrigée au 2026-07-28**,
> et **non** celle du Story File (rédigée le 2026-07-27, elle datait l'application au 27 et renvoyait à
> un fichier de preuve inexistant).

## Pourquoi cette tâche ne pouvait pas être faite par un agent

`scripts/githooks/pre-push` est couvert par `.claude/hooks/protect_files.sh` (motif
`scripts/githooks/*`, l. 28) : l'écriture en est **techniquement bloquée** pour un agent. Le fichier a
donc été **copié en place par l'humain**. Aucun contournement n'a été employé — ni désactivation de
hook, ni écriture par un détour shell.

## Ce qui a changé, et ce qui n'a pas changé

L'en-tête (l. 4-12) portait **deux affirmations devenues fausses** le 2026-07-28 :

1. « CE HOOK EST LE SEUL ENFORCEMENT RÉEL DE CETTE RÈGLE » — il y a désormais **deux** barrières, dont
   une **côté serveur**, et c'est la serveur qui est décisive.
2. « `main` n'est PAS protégée côté GitHub et **ne peut pas l'être sur ce plan** (403…) » — elle **l'est**.

⛔ **Aucune ligne de logique n'a été touchée** (l. 15-29 : lecture de `factory_env.sh`, boucle
`while read`, `exit 1` / `exit 0`).

## Preuves de la vérification

### 1. Le diff ne porte que l'en-tête

`git diff scripts/githooks/pre-push` → **un seul hunk**, `@@ -1,15 +1,23 @@`, **17 insertions /
9 suppressions**, toutes dans le bloc de commentaire. Les lignes de logique n'apparaissent qu'en
contexte, jamais en `+`/`-`.

Preuve d'**identité à l'octet** avec la proposition relue avant copie : le hash du blob du fichier
en place (`d86411a`) est **identique** à celui de la proposition
(`git diff --no-index` avant copie : `index 6472d24..d86411a`). La copie n'a introduit aucune dérive.

### 2. Intégrité du fichier préservée

| Contrôle | Attendu | Constaté |
|---|---|---|
| Fins de ligne | LF pur (imposé par `.gitattributes`) | **CRLF = 0 · LF = 37** |
| BOM | absent | **absent** |
| `git config --get core.hooksPath` | `scripts/githooks` | **`scripts/githooks`** |

> ⚠️ Ce contrôle n'est pas cosmétique : la machine a `core.autocrlf=true`. Un éditeur Windows écrivant
> des CRLF aurait produit un `#!/bin/sh` suivi d'un `\r` — **hook mort**, et `.gitattributes` aurait
> normalisé le commit, masquant la panne côté dépôt.

### 3. La logique tourne encore — prouvé sans réseau

T20 interdit un push réel vers la branche principale comme moyen de vérification. Le hook a donc été
appelé **directement**, en lui fournissant son `stdin` (`<local_ref> <local_sha> <remote_ref> <remote_sha>`) :

```
$ printf 'refs/heads/x AAA refs/heads/main BBB\n' | sh scripts/githooks/pre-push

❌ PUSH BLOQUÉ — push direct vers main interdit.
   Ouvrir une Pull Request depuis la branche feat/US-XX.X-description.

exit=1

$ printf 'refs/heads/x AAA refs/heads/feat/US-00.7-x BBB\n' | sh scripts/githooks/pre-push
exit=0
```

**Les deux branches de la logique sont exercées** : refus + `exit 1` sur la branche principale, silence
+ `exit 0` sinon. C'est une preuve de **fonctionnement**, là où une relecture de diff n'aurait prouvé
qu'une **apparence** d'intégrité.

## Portée de cette preuve — ce qu'elle n'établit pas

- Elle porte sur le fichier **du poste courant**, à sa date. Le hook reste **absent d'un clone frais**
  tant que `scripts/install_hooks.sh` n'a pas été lancé — limite **inchangée**, et c'est d'ailleurs la
  condition même du test négatif serveur d'US-00.7.
- Elle ne dit **rien** de la protection côté serveur, qui est prouvée ailleurs
  (`applied_state/`). Les deux barrières sont indépendantes.

## Effet sur les critères de test

> ### ⛑️ CORRECTION du 2026-07-28 — sur-affirmation relevée par l'audit Rev (finding **m-1**)
>
> **La version initiale de cette section était FAUSSE** et affirmait ceci : « `pre-push` était le
> **dernier** des 11 à porter encore une affirmation d'impossibilité au présent. Le critère devient
> **entièrement levable**. »
>
> **C'est inexact.** `tests/fixtures/US-00.4/README.md:31` porte **toujours** l'affirmation au présent
> (« les chemins exit 0 et exit 1 ne sont pas observables sur ce dépôt ») : sa **réécriture est
> interdite par arbitrage** — le démenti est placé **en amont**, l. 6, en historisation additive.
>
> Le rapport voisin `non_regression.md:466` était **plus juste** et **contredisait** celui-ci :
> « LEVÉ sur **9/11**, avec 2 exceptions documentées ». **Une sur-affirmation dans l'US dont c'est
> précisément la thèse** — et elle n'a pas été attrapée par la session qui l'a écrite, mais par un
> **audit à contexte frais**. C'est la séparation des pouvoirs qui l'a trouvée.

- **Critère #22** (AC-5 nominal — « 0 affirmation d'impossibilité dans les **11** artefacts vivants ») :
  T20 fait passer le décompte de **9/11 à 10/11**. Le critère **n'est PAS entièrement levable** : il
  subsiste **une** exception, `tests/fixtures/US-00.4/README.md`, **arbitrée** en historisation
  additive et **assumée comme telle**.
- **Case 33 de la DoD** : `pre-push` en était le dernier élément non traité — la case, elle, est bien
  **complète**, car son énoncé porte sur le **traitement** des 8 artefacts hors AC-5, non sur
  l'éradication de toute occurrence.

## Artefact temporaire supprimé

`reports/US-00.7/pre-push.proposed` (fichier complet préparé pour la copie) a été **supprimé** après
vérification : il n'est couvert par aucune règle de `.gitattributes` et serait revenu en **CRLF** sur un
clone frais — un piège pour qui l'aurait recopié plus tard. La trace durable du changement est le diff
de `transmissions.md` §8 et le commit lui-même.
