# 🛡️ Protection de la branche principale sur GitHub

> ✅ **Application automatisée** : exécuter `sh scripts/apply_branch_protection.sh`
> (nécessite `gh` CLI authentifié avec droits admin). Le script génère le JSON de protection
> DEPUIS `factory.config.json` (source unique des status checks — `scripts/factory_sync.py
> --emit-branch-protection`) et l'applique via `gh api`.
> Vérification : `gh api repos/<owner>/<repo>/branches/<branche>/protection`.
>
> ⚠️ Tant que ce script n'a pas été exécuté, ces protections **ne sont PAS actives**.
>
> **Défense en profondeur locale** : les hooks versionnés (`scripts/install_hooks.sh`) bloquent déjà
> commit et push directs sur la branche principale, et le hook Claude Code `block_dangerous_bash.sh`
> interdit à l'agent les commandes `--no-verify` / push direct.

## 📋 Instructions de configuration GitHub (manuel — équivalent du script)

1. Accédez à l'onglet **Settings** de votre dépôt.
2. Dans le menu de gauche, sous **Code and automation**, cliquez sur **Branches**.
3. Cliquez sur **Add branch protection rule** (ou éditez la règle existante).
4. Saisissez le nom de la branche principale (`factory.config.json` → `git.main_branch`).

## 🔒 Règles de protection à activer

### 1. Require a pull request before merging
- **Description** : interdit tout push direct sur la branche principale.
- `Require approvals` coché, `Required number of approvals` réglé selon
  `factory.config.json` → `branch_protection.required_approving_review_count`.

### 2. Require status checks to pass before merging
- `Require branches to be up to date before merging` coché.
- Ajouter les status checks suivants :

<!-- FACTORY_SYNC:BEGIN — généré par scripts/factory_sync.py, ne pas éditer -->

| Status check requis | Workflow |
|---|---|
| `🔐 Secrets scan (gitleaks)` | `ci.yml` |
| `📋 Governance (SCB + traçabilité + synchro)` | `ci.yml` |
| `check-branch-name` | `branch-naming.yml` |
| `📱 App (gates run_gates.py)` | `ci.yml` |

<!-- FACTORY_SYNC:END -->

### 3. Do not allow bypassing the above settings
- Applique les restrictions même aux administrateurs (et aux jetons d'accès privilégiés des agents).

### 4. Restrict who can push to matching branches (optionnel)
- Réserver la fusion finale à l'@Architect ou au release manager désigné.

## 🚨 En cas de violation détectée

Un commit direct sur la branche principale ou une PR fusionnée hors process déclenche un événement
d'incident `EVT_WORKFLOW_VIOLATION` et bloque la certification de production.
