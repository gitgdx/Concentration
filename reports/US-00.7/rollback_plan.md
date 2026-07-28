# US-00.7 · T6 — **PLAN DE RETOUR ARRIÈRE** : verrouillage du dépôt

> 🔴 **ÉCART DE PÉRIMÈTRE À ARBITRER — lire avant tout le reste.**
> La tâche **T6** du Story File prescrit d'écrire ce plan **dans `docs/GIT_PROTECTION.md`**, et le
> **critère de test n° 9** exige que ce fichier porte la section **dans un commit antérieur** à celui
> qui archive le `PUT` (`git log --oneline -- docs/GIT_PROTECTION.md` doit le prouver).
> **`docs/GIT_PROTECTION.md` n'est pas dans la liste des fichiers que la mission de phase 0
> m'autorise à éditer** (`scripts/check_branch_protection.py`, `tests/fixtures/US-00.7/*`,
> `reports/US-00.7/*`, et les cases T1→T7 du Story File), et cette même mission m'interdit de
> committer.
> **Conséquence** : le plan est écrit **ici**, intégralement, dans sa **forme définitive**, avec au §7
> le **point d'insertion exact** et le diff à appliquer. **Le critère de test n° 9 reste NON LEVÉ**
> tant que (a) la section n'est pas insérée dans `docs/GIT_PROTECTION.md` et (b) le commit
> correspondant n'est pas créé — **avant** le `PUT`. Aucun contenu ne manque : seule l'insertion et le
> commit restent à faire.

| Champ | Valeur |
|---|---|
| Tâche | **T6** — phase 0, aucune écriture distante |
| AC | **AC-8 nominal** · renforcement de track **R-b** · risque **R-1** |
| Critère de test | **9** — *non levé* (cf. encadré ci-dessus) |
| Date | **2026-07-27** |
| Destination | `docs/GIT_PROTECTION.md`, nouvelle section `## 🛟 Plan de retour arrière — verrouillage du dépôt` |

---

## Texte définitif de la section — à insérer tel quel

<!-- DÉBUT DU TEXTE À INSÉRER DANS docs/GIT_PROTECTION.md -->

## 🛟 Plan de retour arrière — verrouillage du dépôt

> **Écrit le 2026-07-27, AVANT toute application de la protection** (US-00.7, AC-8, tâche T6). Ce
> plan existe pour un cas précis et unique : la protection appliquée avec `enforce_admins: true`
> **exige** quatre contextes de status checks ; si **l'un d'eux n'est jamais rapporté** par GitHub,
> **plus aucune pull request n'est fusionnable, administrateur inclus** — y compris celle qui
> voudrait corriger le problème. C'est le risque **R-1** de l'US, de probabilité faible et d'impact
> critique.

### 1. Symptôme — et comment le distinguer d'un échec normal

```sh
gh pr view <n> --json mergeableState,statusCheckRollup
gh pr checks <n>
```

| Observation | Interprétation | Action |
|---|---|---|
| `mergeableState: BLOCKED` **et** un contexte requis en **`EXPECTED`** / **absent** de `gh pr checks` | **VERROUILLAGE** — le contexte n'est **jamais rapporté** (libellé divergent, ou workflow qui ne se déclenche pas sur cet événement). L'attente est **définitive**. | **appliquer ce plan** |
| `mergeableState: BLOCKED` **et** un contexte en **`FAILURE`** | **échec normal d'un gate** : le code ou la gouvernance sont en faute. | **corriger la cause**, pas la règle |
| `mergeableState: BLOCKED` **et** tous les checks verts | autre condition de fusion non satisfaite : `strict: true` (**branche pas à jour**) ou `required_conversation_resolution: true` (**discussion ouverte**). | rebaser / résoudre les discussions |

⚠️ Ne **jamais** confondre les deux premières lignes : `EXPECTED` se répare en administrant la règle,
`FAILURE` se répare en corrigeant le travail. Appliquer ce plan sur un `FAILURE` serait un
contournement de gate.

### 2. Mécanisme de sortie — **éditer ou supprimer ≠ contourner**

`enforce_admins: true` interdit à l'administrateur de **contourner** la règle (*bypass* : fusionner
malgré elle). Il **ne lui interdit pas** de l'**éditer** ni de la **supprimer** :

```sh
# lire l'état courant (toujours en premier)
gh api repos/gitgdx/Concentration/branches/main/protection

# supprimer la règle — porte de sortie du verrouillage
gh api -X DELETE repos/gitgdx/Concentration/branches/main/protection

# ré-appliquer depuis la SOURCE UNIQUE (jamais un JSON écrit à la main)
sh scripts/apply_branch_protection.sh gitgdx/Concentration
```

> **Ce n'est pas un contournement : c'est de l'administration.** La distinction est la clé de ce
> plan. Contourner = fusionner une PR que la règle refuse (`gh pr merge --admin`). Administrer =
> modifier la règle elle-même, de façon **tracée**, puis la remettre en place depuis la
> configuration. La porte de sortie existe toujours, et elle exige des droits admin.

### 3. Séquence imposée — 5 étapes, dans cet ordre

1. **`DELETE` tracé** de la règle : `gh api -X DELETE repos/gitgdx/Concentration/branches/main/protection`
   — sortie **archivée brute** (commande + horodatage UTC) dans `reports/US-00.7/`.
2. **Corriger le libellé dans la SOURCE UNIQUE** : `factory.config.json` → `status_checks[].name`
   (fichier **Art. 6** → **action humaine**) **ou** le `name:` du job dans
   `.github/workflows/<workflow>.yml`. ⛔ **Jamais** dans l'interface GitHub.
3. **Ré-appliquer depuis la configuration** : `sh scripts/apply_branch_protection.sh gitgdx/Concentration`
   — le script consomme le payload **généré** par `python scripts/factory_sync.py --emit-branch-protection`.
4. **Re-vérifier** : `python scripts/factory_sync.py --check-remote` → **exit 0** attendu. Un `exit 1`
   impose de recommencer à l'étape 2 ; un `exit 2` doit être **nommé** (403, 401, 404, `gh`
   introuvable, `MAPPING INCOMPLET`) et **signalé**.
5. **Consigner** : ligne dans `PROJECT_LOG.md` + événement `EVT_DEV_BLOCKER` +
   `python scripts/factory_sync.py --check` (exit 0) pour prouver que config et workflows sont
   redevenus cohérents.

### 4. Interdits absolus — chacun invalide l'AC-4 et vaut `EVT_WORKFLOW_VIOLATION`

* ⛔ **`gh pr merge --admin`** (ou toute fusion en contournement de la règle).
* ⛔ **Retirer un contexte requis** de la cible « pour débloquer » — y compris temporairement.
* ⛔ **Corriger le libellé dans l'interface web** (*Settings → Branches*) : la correction ne
  remonterait pas dans la source unique, et la prochaine ré-application la perdrait.
* ⛔ **Aligner `factory.config.json` sur l'état constaté** au lieu de l'inverse. La configuration est
  la référence ; le dépôt s'y conforme, jamais le contraire.
* ⛔ **Retirer `required_pull_request_reviews`** du payload : `0` approbation **≠** pas de PR exigée.
  Le supprimer désactiverait « Require a pull request before merging ».
* ⛔ **`--no-verify`** (Constitution Art. 1), en toute circonstance.

### 5. Obligation de tracer — jamais de correction silencieuse

Toute exécution de ce plan produit, **sans exception** : la sortie **brute** du `DELETE` et de la
ré-application, une ligne `PROJECT_LOG.md`, un événement `EVT_DEV_BLOCKER`, et la mention de
l'incident dans le Story File. Un verrouillage réparé **en silence** laisserait croire que le
mécanisme n'a jamais failli — c'est précisément la classe de fausse confiance que cette US existe
pour éliminer.

### 6. Ce que ce plan ne couvre pas

* Il suppose des **droits admin** sur le dépôt. Sans eux, ni le `DELETE` ni la ré-application ne sont
  possibles : la sortie du verrouillage exige alors l'intervention du propriétaire.
* Il suppose que la protection soit **disponible** : si le dépôt repassait en **privé**, la
  protection redeviendrait **indisponible (403)** — le verrouillage disparaîtrait de lui-même, mais
  l'enforcement aussi.
* Il ne prévient pas le verrouillage : il en sort. La prévention est la vérification des libellés
  **avant** application (`reports/US-00.7/labels_verification.md`) et le constat des libellés
  **réellement rapportés** sur la PR (`gh pr checks`, critère 25) **avant** toute tentative de fusion.

<!-- FIN DU TEXTE À INSÉRER DANS docs/GIT_PROTECTION.md -->

---

## 7. Point d'insertion exact dans `docs/GIT_PROTECTION.md`

**Insérer la section ci-dessus entre la fin du § `## 🚨 En cas de violation détectée` et le début du
§ `## 🧾 Dettes ouvertes`** — c'est-à-dire **immédiatement avant** la ligne `## 🧾 Dettes ouvertes`
(ligne **272** dans l'état du fichier au 2026-07-27), séparateur `---` inclus.

* ✅ Cet emplacement est **hors** du bloc généré : les marqueurs
  `<!-- FACTORY_SYNC:BEGIN -->` / `<!-- FACTORY_SYNC:END -->` occupent les lignes **147 → 156**.
  ⛔ **Ne jamais éditer entre ces deux marqueurs.**
* ✅ T6 est **purement additive** : elle **ne touche pas** aux sections d'impossibilité (en-tête
  `⛔ main N'EST PAS PROTÉGÉE`, §*Constat daté du 2026-07-26*, §*Ce qui protège réellement*,
  §*Conditions de déblocage*, §*Cible armée*) — celles-là relèvent de **T14**, **après** le `PUT`.
  Le plan doit exister **avant** que le risque ne soit pris ; le reste du fichier doit rester **vrai**
  jusqu'à ce que la protection soit effectivement appliquée.

Diff à appliquer :

```diff
@@ docs/GIT_PROTECTION.md — avant la ligne « ## 🧾 Dettes ouvertes » @@
   `governance.grandfathering_date` (clé morte, laissée `null`).

 ---

+## 🛟 Plan de retour arrière — verrouillage du dépôt
+
+  … (texte intégral du §« Texte définitif de la section » ci-dessus, de son encadré
+     « Écrit le 2026-07-27, AVANT toute application » jusqu'au §6 inclus) …
+
+---
+
 ## 🧾 Dettes ouvertes
```

**Après insertion**, deux contrôles à exécuter :

```sh
python scripts/factory_sync.py --check          # exit 0 attendu (le bloc FACTORY_SYNC est intact)
git log --oneline -- docs/GIT_PROTECTION.md     # le commit du plan doit PRÉCÉDER celui du PUT
```
