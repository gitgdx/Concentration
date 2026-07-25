# 🔐 Procédure de rotation d'un secret — dépôt Concentration

> **US-00.1 — Secrets & scan de dépôt (AC-4).** Que faire si un secret a fuité (ou risque
> d'avoir fuité) dans le dépôt ou son historique. Cette procédure est **préventive** : à ce
> jour, **aucune rotation n'est requise** (voir §5).

---

## 0. Principe

Un secret exposé dans Git **reste dans l'historique** même après suppression du fichier. La
seule réponse sûre à une fuite est de **révoquer + régénérer** le secret côté fournisseur — la
suppression du dépôt ne « rend » jamais un secret sûr. La réécriture d'historique est un
**dernier recours**, pas la première action.

Ordre d'intervention (du plus urgent au moins urgent) :

**Révoquer → Régénérer → Remplacer → (éventuellement) Nettoyer l'historique.**

---

## 1. Identifier

- Localiser la fuite : sortie `gitleaks` (`reports/US-00.1/`), alerte CI `secrets-scan`, ou
  signalement. Noter **quel** secret, **quel** fichier, **quel** commit.
- Déterminer la portée : le secret est-il seulement dans le working tree (jamais committé) ou
  déjà dans l'historique poussé (donc potentiellement lu par des tiers) ?
- **Traiter tout secret committé et poussé comme compromis**, même supprimé depuis.

## 2. Révoquer côté fournisseur (action prioritaire)

Invalider immédiatement la valeur exposée, **avant** toute autre étape.

| Secret | Où révoquer |
|---|---|
| `STITCH_API_KEY` (clé Google/Stitch) | Console Google Cloud → *APIs & Services → Credentials* → supprimer/désactiver la clé exposée. |
| `GITHUB_MCP_TOKEN` (PAT GitHub) | github.com → *Settings → Developer settings → Personal access tokens* → **Revoke** le token. |
| Futur keystore Android / certificat iOS | Regénérer l'artefact de signature côté store ; considérer l'ancien comme compromis. |

## 3. Régénérer

- Créer une **nouvelle** valeur côté fournisseur (nouvelle clé Google, nouveau PAT au scope
  minimal requis, etc.).
- Ne **jamais** réutiliser l'ancienne valeur.

## 4. Remplacer (sans jamais committer la valeur)

- **En local** : mettre la nouvelle valeur dans `.env` (gitignoré) ou dans le bloc `env` de
  `.claude/settings.local.json` (gitignoré) — jamais dans un fichier suivi par Git. Les gabarits
  suivis (`.env.example`) ne contiennent que des placeholders (`changeme`, `${VAR}`).
- **En CI / plateforme** : mettre la nouvelle valeur dans les *secrets* du dépôt/plateforme
  (GitHub → *Settings → Secrets and variables → Actions*), jamais dans un fichier du dépôt.
- Vérifier que l'allowlist de `.gitleaks.toml` ne masque **que** des placeholders prouvés, jamais
  une vraie valeur.

## 5. État actuel — aucune rotation requise

Au moment de la rédaction (US-00.1), le scan `gitleaks` de l'**historique complet** et du
**working tree** ne détecte **aucun secret réel** : seuls des placeholders prouvés sont présents
(`STITCH_API_KEY=changeme` dans `.env.example`, interpolations `${STITCH_API_KEY}` dans
`.mcp.json`). **Aucune rotation n'est nécessaire à ce jour.** Cette procédure reste disponible
pour tout incident futur.

> Note : la valeur réelle de `STITCH_API_KEY` vit hors dépôt (`.claude/settings.local.json`,
> gitignoré) et `GITHUB_MCP_TOKEN` en variable d'environnement — ni l'une ni l'autre n'est
> committée. Preuves : `reports/US-00.1/`.

## 6. Dernier recours — réécriture d'historique (décision HUMAINE)

Si un secret réel a été committé et poussé, une fois **révoqué + régénéré**, on peut vouloir
**purger** la valeur de l'historique (hygiène, dépôt public) :

- Outils : `git filter-repo` (recommandé) ou BFG Repo-Cleaner.
- ⚠️ Implique un **force-push** et une **coordination d'équipe** (tous les clones doivent être
  refaits) → **décision humaine explicite**, jamais automatique. Le scan `gitleaks` **détecte et
  bloque**, il ne réécrit **pas** l'historique tout seul.
- La révocation côté fournisseur (§2) reste la protection réelle ; la purge d'historique n'est
  qu'un nettoyage complémentaire.

---

## Références

- Story File : [`docs/stories/US-00.1-secrets-scan-depot.md`](../stories/US-00.1-secrets-scan-depot.md)
- Config de scan : `.gitleaks.toml` (racine) · Preuves : [`reports/US-00.1/`](../../reports/US-00.1/)
- Constitution — gestion des secrets : [`docs/governance/CONSTITUTION.md`](../governance/CONSTITUTION.md)
