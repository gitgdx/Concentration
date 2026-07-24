---
description: Lancer les audits Rev + Sec d'une US en parallèle via des subagents à CONTEXTE FRAIS (séparation des pouvoirs)
argument-hint: <US-ID> (ex US-01.1)
---

Rituel d'audit de l'US : $ARGUMENTS

**Principe (Constitution Art. 2)** : celui qui a produit le code ne le certifie pas. Les audits
tournent dans des subagents à contexte frais, et leurs verdicts s'appuient sur des exécutions d'outils.

1. **Pré-vérification** : `python scripts/validate_trace.py --us $ARGUMENTS` — la trace doit contenir
   `EVT_CODE_READY`. Sinon, STOP : renvoyer vers @Developer.
2. **Lancer EN PARALLÈLE** (un seul message, deux appels Agent) :
   - subagent **code-reviewer** : prompt = "Audite l'US $ARGUMENTS. Story File : docs/stories/$ARGUMENTS-*.md.
     Diff : `git diff main...HEAD`. Produis reports/$ARGUMENTS/code_review.md et trace ton verdict."
   - subagent **cyber-security** : prompt = "Audit sécurité de l'US $ARGUMENTS. Story File : docs/stories/$ARGUMENTS-*.md.
     Diff : `git diff main...HEAD`. Produis reports/$ARGUMENTS/security.md et trace ton verdict."
3. **À la réception des deux verdicts** :
   - vérifier que les rapports existent et contiennent des SORTIES D'OUTILS (pas seulement un avis) —
     un rapport sans sortie d'outil est invalide, relancer l'audit ;
   - vérifier la trace : `python scripts/validate_trace.py --us $ARGUMENTS` ;
   - mettre à jour le SCB : `Audit Rev 🔍` → ✅ 🔍 ou ❌ ; `Audit Sec 🛡️` → ✅ 🛡️ ou ❌ ;
   - ajouter les lignes PROJECT_LOG (une par audit).
4. **Si un audit FAILED** : lister les findings bloquants, repasser la main à @Developer
   (les findings sont dans les rapports), phase SCB inchangée.

Termine par : verdicts, findings bloquants éventuels, chemins des rapports, prochaine étape (QA si double ✅).
