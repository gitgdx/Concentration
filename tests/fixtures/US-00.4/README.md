# Fixtures US-00.4 — réponses d'API **SIMULÉES** (2026-07-26)

Ces 5 fichiers sont des **simulations fabriquées à la main**, au format d'une réponse `GET` de l'API GitHub : ils ne sont **jamais** une preuve de l'état réel du dépôt (les preuves brutes datées vivent dans `reports/US-00.4/`).
Ils existent parce que les chemins **exit 0** et **exit 1** de `scripts/check_branch_protection.py` ne sont **pas observables** sur ce dépôt : `GET …/branches/main/protection` y renvoie **403 — « Upgrade to GitHub Pro… »** (limite de plan, cf. `docs/adr/ADR-006-protection-branche-principale.md`).
Toute exécution consommant `--from-protection` / `--from-branch` préfixe **chaque ligne** de sa sortie par `[SIMULATION] ` et son exit 0 porte « SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt » — mitigation du risque **R1** (une sortie « conforme » archivée ne doit jamais pouvoir être relue comme un constat réel).
`protection_conforme.json` est un **instantané statique daté** de la cible générée par `python scripts/factory_sync.py --emit-branch-protection` (4 libellés de contextes à l'octet près) : il n'est **pas** régénéré à l'exécution — si `status_checks` ou `branch_protection` évoluent dans `factory.config.json`, le test exit 0 **échouera bruyamment** et la fixture devra être mise à jour (risque **R4**, choix assumé : une fixture auto-générée comparerait la config à elle-même et ne prouverait plus rien).
Aucune donnée sensible : aucun jeton, aucun en-tête `Authorization`, propriétaire et dépôt réduits aux placeholders `OWNER/REPO` dans les URL.

| Fichier | Simule | Utilisé pour |
|---|---|---|
| `protection_conforme.json` | `GET …/branches/main/protection` → **200**, strictement aligné sur la cible | critère #7 → **exit 0** |
| `protection_divergente.json` | idem → **200**, **4 écarts** (1 contexte manquant, 1 en trop, `enforce_admins.enabled: false`, `required_approving_review_count: 1`) | critère #8 → **exit 1** |
| `branch_protected_true.json` | `GET …/branches/main` → `"protected": true` | critères #7, #8, #10 |
| `branch_protected_false.json` | `GET …/branches/main` → `"protected": false` | critère #10 → **exit 1** |
| `http_404.json` | corps d'erreur **404** de `GET …/protection` | critère #10 (avec `--from-protection-status 404`) |
