# US-00.5 · Attestation humaine de l'amendement constitutionnel — **DoD 14**

**Date** : 2026-07-31 · **Objet** : amendement de l'**Art. 4**, Constitution **1.0 → 1.1**
**Livraison** : **PR #18**, PR **dédiée** *(diff = `CONSTITUTION.md` + `PROJECT_LOG.md`)*, merge commit
**`c62cdcc`**, fusionnée le 2026-07-31T11:00:05Z par **`gitgdx`**, **sans `--admin`**.
**Méthode** : **niveau 1**, **assumée DÉCLARATIVE** *(même régime que la case 34 d'US-00.7)*.

---

## Attestation, reprise VERBATIM

> « **J'ai relu le diff de la PR #18 et j'approuve l'amendement de l'Art. 4, Constitution 1.1.** »
>
> — l'humain (`gitgdx`), **2026-07-31**, en réponse à une demande explicite de @Architect.

---

## Fondement — ce que la clause exige

La clause **Révision** de la Constitution : *« La Constitution s'amende par PR dédiée **approuvée par
l'humain** (jamais en side-effect d'une US), avec ligne PROJECT_LOG et incrément de version. »*
Les trois autres conditions sont **vérifiées par outil** *(PR dédiée : 2 fichiers · ligne de journal
présente · version **LUE** dans le texte : `1.1 2026-07-31`)*. **L'approbation humaine est la seule qui ne
puisse pas l'être** — d'où ce document.

## ⛔ Ce que cette attestation NE PROUVE PAS, et c'est écrit ici même

1. **Aucune barrière machine ne la soutient, et aucune ne pourrait.**
   `required_approving_review_count: 0` · `reviewDecision` **vide** · `reviews = 0` — GitHub **interdit à
   l'auteur d'approuver sa propre PR** sur un dépôt à **un seul collaborateur**. C'est le même
   constat que l'arbitrage du **critère 27 d'US-00.7**, et il **demeure**.
2. **Aucune preuve machine de provenance n'existe sur ce dépôt.** `mergedBy.is_bot` rend `false` **même
   pour une fusion exécutée par un agent**, les agents opérant avec le jeton de l'humain. La levée réelle
   *(identité distincte + `restrictions`)* est portée par **US-00.8**.
3. **Elle atteste un ACTE DÉCLARÉ, pas un acte observé.** Elle enregistre une **phrase**, non une
   relecture vérifiable. La leçon d'US-00.7 s'applique telle quelle : *« "was already merged" atteste un
   ÉTAT, pas un ACTE »*.
4. ⛔ **Elle n'a PAS été produite par un gate — et un gate l'a faussement validée.**
   `qa_exit_v3.sh` rendait `OK | une attestation humaine de l amendement est consignee` **alors qu'aucune
   n'existait** : son contrôle matchait un texte **parlant** d'attestation. **Ce faux `OK` a été refusé et
   n'a jamais été utilisé** ; l'attestation a été **demandée à l'humain** et **obtenue** avant que la case
   ne soit cochée. **Un gate qui valide une approbation humaine absente est pire que pas de gate**, et
   celui-ci portait sur le **seul artefact normatif du projet sans prévention NI détection**.

## Ce qui EST vérifiable, et par quoi

| Condition de la clause | Vérification |
|---|---|
| **PR dédiée** | `git diff --name-only` sur la PR #18 → **2 fichiers**, `0` autre |
| **Ligne PROJECT_LOG** | présente, livrée **dans** la PR dédiée |
| **Incrément de version** | **LU** dans le texte, jamais supposé → `1.1 2026-07-31`, avec **historique des versions** ajouté pour que l'incrément soit vérifiable |
| **Aucun autre article touché** | `0` hunk sur un `## Art.` autre que le 4 |
| **Approuvée par l'humain** | ⚠️ **ce document, et lui seul** — déclaratif, niveau 1 |

---

**Conséquence** : la **case DoD 14 est cochée** au titre de cette attestation, avec sa nature déclarative
**écrite dans la case**. ⛔ Elle **ne lève pas** le constat structurel *(critère 27 d'US-00.7 : une
approbation humaine n'est pas prouvable par la machine sur ce dépôt)*, et **ne dispense d'aucun autre
contrôle**.
