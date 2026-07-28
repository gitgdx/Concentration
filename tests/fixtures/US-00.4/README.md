# Fixtures US-00.4 — réponses d'API **SIMULÉES** (2026-07-26)

> ## 🕓 Encadré ajouté le 2026-07-28 par US-00.7 — **historisation ADDITIVE, aucune ligne ci-dessous n'est réécrite**
>
> **Le constat du 2026-07-26 rappelé au paragraphe suivant (« les chemins exit 0 et exit 1 ne sont pas
> observables sur ce dépôt : 403 — *Upgrade to GitHub Pro…* ») était EXACT À SA DATE. Il a été levé.**
> Le dépôt a été rendu **public** le **2026-07-27** (décision humaine, Constitution Art. 5), puis la
> protection de branche a été **appliquée** le **2026-07-28** :
>
> * le chemin **exit 1** a été observé **en réel** le 2026-07-27 (404 « *Branch not protected* » +
>   `protected == false` → dérive) — `reports/US-00.7/entry_state/check_remote_exit1.txt` ;
> * le chemin **exit 0** a été observé **en réel** le 2026-07-28 (12 champs alignés, 0 écart) —
>   `reports/US-00.7/applied_state/check_remote_exit0_reel.txt`.
>
> **Ces fixtures restent NÉCESSAIRES, et le resteront.** Les cas qu'elles exercent ne sont **pas
> reproductibles à volonté** sur le dépôt réel : reproduire un `exit 1` ou un `exit 2` exigerait de
> **dégrader la protection de la branche principale**, et les cas `lock_branch`, `block_creations`, clé
> inconnue active ou clés additives neutres ne dépendent pas de nous. Elles restent aussi le **seul** moyen
> d'exercer ces chemins **sans droits admin** et **sans réseau**.
>
> ⚠️ **Ce que cet encadré ne change pas** : une sortie de fixture reste **préfixée `[SIMULATION]`** et ne
> vaut **jamais** preuve de l'état réel (risque **R1**) ; la dérive de fixture (risque **R4**) reste
> entière ; et **aucun `selftest` en CI** ne les exécute — elles sont toujours lancées **à la main**
> (dette maintenue OUVERTE). Ce fichier est le **matériel de test vivant** d'une US **certifiée** : il est
> **complété**, jamais réécrit. Décision de référence :
> `docs/adr/ADR-007-application-protection-branche.md` *(remplace ADR-006)*.
>
> *(Fixtures ajoutées par US-00.7 pour le correctif **NB-1** : `tests/fixtures/US-00.7/`.)*

Ces 5 fichiers sont des **simulations fabriquées à la main**, au format d'une réponse `GET` de l'API GitHub : ils ne sont **jamais** une preuve de l'état réel du dépôt (les preuves brutes datées vivent dans `reports/US-00.4/`).
Ils existent parce que les chemins **exit 0** et **exit 1** de `scripts/check_branch_protection.py` ne sont **pas observables** sur ce dépôt : `GET …/branches/main/protection` y renvoie **403 — « Upgrade to GitHub Pro… »** (limite de plan, cf. `docs/adr/ADR-006-protection-branche-principale.md`).
Toute exécution consommant `--from-protection` / `--from-branch` préfixe **chaque ligne** de sa sortie par `[SIMULATION] ` et son exit 0 porte « SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt » — mitigation du risque **R1** (une sortie « conforme » archivée ne doit jamais pouvoir être relue comme un constat réel).
`protection_conforme.json` est un **instantané outillé puis GELÉ** — pas une transcription à la main : il a été produit **une seule fois** par un générateur jetable qui lisait `python scripts/factory_sync.py --emit-branch-protection` (pour garantir les 4 libellés de contextes à l'octet près, emoji et accents compris), générateur **délibérément laissé hors du dépôt** pour qu'aucun mécanisme ne puisse le régénérer à l'exécution. Conséquence voulue (risque **R4**) : si `status_checks` ou `branch_protection` évoluent dans `factory.config.json`, le test exit 0 **échouera bruyamment** et la fixture devra être mise à jour à la main — une fixture auto-générée comparerait la config à elle-même et ne prouverait plus rien.
Aucune donnée sensible : aucun jeton, aucun en-tête `Authorization`, propriétaire et dépôt réduits aux placeholders `OWNER/REPO` dans les URL.

| Fichier | Simule | Utilisé pour |
|---|---|---|
| `protection_conforme.json` | `GET …/branches/main/protection` → **200**, strictement aligné sur la cible | critère #7 → **exit 0** |
| `protection_divergente.json` | idem → **200**, **4 écarts** (1 contexte manquant, 1 en trop, `enforce_admins.enabled: false`, `required_approving_review_count: 1`) | critère #8 → **exit 1** |
| `branch_protected_true.json` | `GET …/branches/main` → `"protected": true` | critères #7, #8, #10 |
| `branch_protected_false.json` | `GET …/branches/main` → `"protected": false` | critère #10 → **exit 1** |
| `http_404.json` | corps d'erreur **404** de `GET …/protection` | critère #10 (avec `--from-protection-status 404`) |

## Fixtures du correctif B-2 *(ajoutées le 2026-07-26 après l'audit Revue)*

L'audit Revue à contexte frais a établi que le comparateur pouvait rendre **exit 0 « conforme »** sur une protection matériellement divergente : la garde ne portait que sur la **cible**, jamais sur la **réponse réelle**, si bien que toute clé supplémentaire du `GET` était **ignorée en silence**. Les 4 fixtures ci-dessous verrouillent le correctif — chacune ne diffère de `protection_conforme.json` **que par le champ testé**, pour que l'échec d'un cas désigne sans ambiguïté sa cause.

| Fichier | Simule | Attendu |
|---|---|---|
| `protection_lock_branch_actif.json` | `lock_branch: {"enabled": true}` — branche **entièrement verrouillée en écriture** | **exit 2** « MAPPING INCOMPLET » — *c'est le cas exact du faux vert corrigé* |
| `protection_block_creations_actif.json` | `block_creations: {"enabled": true}` | **exit 2** |
| `protection_cle_inconnue_active.json` | clé inconnue `require_signed_commits_v2: {"enabled": true}` **+** `required_pull_request_reviews.bypass_pull_request_allowances` **non vide** (dispense de PR, dans un **sous-objet mappé**) | **exit 2**, les **2** champs nommés |
| `protection_cles_additives_neutres.json` | 4 champs additifs **neutres** (`{"enabled": false}`, `null`, `[]`, conteneur vide) | **exit 0** — une clé additive neutre ne doit **pas** faire trébucher l'outil (l'API GitHub est additive) |

Ces 4 fixtures sont, elles aussi, des **instantanés outillés puis gelés** : dérivées une seule fois de `protection_conforme.json` par un générateur laissé **hors du dépôt**.
